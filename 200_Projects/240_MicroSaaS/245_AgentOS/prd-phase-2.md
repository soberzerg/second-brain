---
type: project-doc
date: 2026-04-18
project: AgentOS
status: draft
tags: [prd, ai-agents, claude-code, mcp, llm-router, openai-compat, phase-2]
---

# PRD: AgentOS — Фаза 2: Co-pilot архитектура (разговорная + исполнительная части)

## Контекст

Фаза 1 AgentOS (см. [[prd]]) реализована как тонкий маршрутизатор: Telegram-gateway → Agent Manager → `claude -p --resume` subprocess. Синхронный путь: одно входящее сообщение = один subprocess = один ответ.

**Проблема:** Claude — единственный «мозг». Невозможно гибко менять «собеседническую» часть, Claude-subprocess блокирует ответ на время выполнения (минуты на тяжёлых задачах), нет параллельных задач, нет накопления/batching сообщений во время работы воркера.

**Цель Фазы 2:** разделить архитектуру на **разговорную часть** (быстрый LLM-loop, конфигурируемая модель через OpenAI-совместимый endpoint) и **исполнительную часть** (Claude и другие воркеры как MCP-серверы). Разговорная часть — ко-пилот: рассуждает, декомпозирует, делегирует воркерам, агрегирует результаты. Не блокируется на задачах воркеров. Отвечает пачками — накопленные пользовательские сообщения и worker events обрабатываются вместе на следующей итерации.

## Ключевые решения

- **Роль разговорной части:** co-pilot с несколькими воркерами (Claude — один из них через MCP).
- **Логика ответов:** гибрид — быстрый ack на первое сообщение, дальнейшие ответы — пачками по debounce-таймеру (4с по умолчанию).
- **Worker events** — равноправный источник в том же inbox, семантически отличимый от user messages.
- **Модель разговорной части:** OpenAI-совместимый клиент (меняем `base_url`), нативные провайдеры — опция в будущем.
- **Инструменты:** через MCP (разговорная часть = MCP клиент, воркеры = MCP серверы).
- **Делегирование Claude:** гибрид — `delegate_to_claude` возвращает `task_id` мгновенно + worker events через Event Bus, плюс `check_task_status` как fallback polling.
- **Контекст:** скользящее окно + running summary (lazy, фоновой дешёвой моделью).
- **Множественные параллельные conversations** per (user × agent) пара. Уведомления из неактивных conversations — молча, видны при переключении.

## Build vs Buy

| Задача | Берём готовое | Пишем сами |
|---|---|---|
| MCP клиент/сервер | `modelcontextprotocol/go-sdk` v1.5 (stdio + HTTP + `NotifyProgress`) | — |
| LLM клиент | `openai/openai-go` v3.32 (`option.WithBaseURL`) | — |
| Подсчёт токенов | `pkoukk/tiktoken-go` (o200k + cl100k) | — |
| Telegram | `mymmrac/telego` v1.8 (мигрируем с `go-telegram-bot-api`) | — |
| LLM-loop с tool calling | — | ~200 строк Go (нет готовых минималистичных) |
| Running summary | — | Вызов LLM с промптом + фоновая goroutine |
| Conversation Worker, Event Bus, Claude-worker-mcp | — | Основной код Фазы 2 |

## Архитектура

Новые сервисы в существующем Go-Kratos монорепо:

### 1. `conversation-service` (новый)
- LLM-loop per conversation, MCP-клиент multi-server.
- Inbox merges user messages + worker events.
- Хранит full history + running summary в Postgres.
- Стримит ответы в Telegram через `editMessage`.

### 2. `claude-worker-mcp` (новый)
- Single HTTP/Streamable MCP-сервер на хосте.
- Tools: `delegate_to_claude`, `check_task_status`, `cancel_task`, `list_active_tasks`.
- Запускает `claude -p --directory --resume` как subprocess, парсит `--output-format stream-json`, пушит события в Event Bus.
- Лимит: `CLAUDE_WORKER_MAX_CONCURRENT` env (default 4).
- При рестарте: `running → recovering`, попытка resume; `restart_count > 3 → error`.

### 3. `telegram-gateway` (рефакторинг Фазы 1)
- Только маршрутизация, больше не запускает Claude.
- Миграция с `go-telegram-bot-api` на `telego`.
- Команды: `/new`, `/conversations`, `/switch`.

### 4. Event Bus — Redis Streams
- Key: `conv:{conversation_id}:events`.
- Типы: `user.message`, `worker.event.{kind}`, `system.tick`.
- Consumer groups для горизонтального масштабирования.

### 5. Существующие (без изменений)
`api-service`, PostgreSQL + Ent, Redis, Caddy.

```
┌──────────────┐     ┌──────────────┐
│  Telegram    │     │   Web App    │
└──────┬───────┘     └──────┬───────┘
       │                    │
       ▼                    ▼
┌──────────────┐     ┌──────────────┐
│  telegram-   │     │ api-service  │
│  gateway     │     │ (dashboard)  │
└──────┬───────┘     └──────────────┘
       │ gRPC + Event Bus
       ▼
┌──────────────────────────────┐
│   conversation-service       │
│                              │
│  Worker Loop per conversation│
│  (idle / debouncing /        │
│   generating)                │
│                              │
│  ┌──────────┐  ┌──────────┐  │
│  │  LLM     │  │  MCP     │  │
│  │  client  │  │  client  │  │
│  │  (OpenAI-│  │  multi-  │  │
│  │   compat)│  │  server  │  │
│  └─────┬────┘  └─────┬────┘  │
└────────┼─────────────┼───────┘
         │             │
         ▼             ▼
  ┌────────────┐ ┌─────────────────┐
  │  LLM       │ │ claude-worker-  │
  │  provider  │ │ mcp (HTTP MCP)  │
  │  (any)     │ │                 │
  └────────────┘ │ claude CLI      │
                 │ subprocess pool │
                 └─────┬───────────┘
                       │
            Event Bus  │
      (Redis Streams)  ▼
              conv:{id}:events
```

## Поток сообщений

Conversation Worker Loop (goroutine per active conversation):

1. Читает из Redis Stream с блокировкой до `DEBOUNCE_WINDOW` (default 4s).
2. `idle + user.message` → если первый в серии — короткий LLM-вызов "quick_ack?" (возвращает текст или null). Переход в `debouncing`.
3. `debouncing` → при новом событии сбрасывает deadline. Когда deadline истекает — `generating`.
4. `generating` → полный LLM-loop с tools. Новые события во время генерации накапливаются и учитываются на следующем цикле.
5. Ответ шлётся в Telegram через `editMessage` стримом (пачки ~1s).

**Семантика в prompt:**
- `user.message` → role=user, префикс `[User]`.
- `worker.event` → role=tool (если есть tool_call_id) или role=user с префиксом `[Worker: claude / task=X / kind=result]`.
- `system prompt` инструктирует: user — главный сигнал, worker events — фон.

## LLM Loop

**Сборка prompt:**
1. `system` — агентский промпт + инструкции по семантике + tools.
2. `system` — running summary (если есть).
3. Последние N сообщений до `CTX_RECENT_BUDGET` (default 30k tokens из 32k общего бюджета).
4. Pending events из текущей пачки.

**Tool calling loop:**
- `openai-go` stream=true, parallel tool calls через `errgroup`.
- `delegate_to_claude` возвращает `{task_id, status:"started"}` мгновенно — loop продолжает.
- При `finish_reason=stop` — финальный ответ пользователю.

**Running summary:**
- Порог: непокрытые токены > 0.7 × `CTX_RECENT_BUDGET`.
- Фоновая goroutine, отдельная дешёвая модель (`summarizer_model` per agent).
- Оставляем последние ~20 сообщений нетронутыми, остальное сжимаем в новую `ConversationSummary`.

## Множественные conversations

- **`AgentBinding`** (замена `Session` из Фазы 1): долгоживущая пара (user × agent).
- **`Conversation`**: один конкретный разговор, имеет свой `claude_session_id`.
- Команды: `/new` (создать), `/conversations` (список с inline keyboard), `/switch` (переключить active).
- Worker events из неактивных conversations пишутся в БД и Stream молча — видны при переключении.

## Модель данных

**Изменения:**
- `Session` → `AgentBinding` (добавляется `active_conversation_id`, убирается `claude_session_id`).
- `Agent` расширяется: `system_prompt`, `conversation_model_config` (jsonb), `summarizer_model_config` (jsonb), `mcp_servers` (jsonb), `ctx_budget_tokens`, `debounce_window_ms`.

**Новые таблицы:**
- `Conversation`: `id`, `binding_id`, `title`, `status`, `claude_session_id`, `last_summary_id`, timestamps.
- `ConversationMessage`: `id`, `conversation_id`, `seq` (monotonic), `role`, `content` (jsonb), `tokens`, `created_at`. Unique(`conversation_id`, `seq`).
- `ConversationSummary`: `id`, `conversation_id`, `up_to_seq`, `summary_text`, `tokens`, `created_at`.
- `WorkerTask`: `id` (=`task_id`), `conversation_id`, `tool_name`, `claude_session_id`, `status` (`queued`/`running`/`recovering`/`completed`/`cancelled`/`error`), `task_prompt`, timestamps, `input_tokens`, `output_tokens`, `cost_usd`, `error_text`, `restart_count`.

**Миграция:** `MessageLog` остаётся read-only для истории Фазы 1. Новые записи — в `ConversationMessage` + `WorkerTask`.

**Индексы:**
- `ConversationMessage(conversation_id, seq DESC)`.
- `WorkerTask(conversation_id, status)` + partial index `WHERE status IN ('queued','running','recovering')`.
- `Conversation(binding_id, status, last_message_at DESC)`.

## Конфиг per agent

```jsonc
conversation_model_config: {
  base_url: "https://openrouter.ai/api/v1",
  model: "anthropic/claude-sonnet-4.6",
  api_key_ref: "env:OPENROUTER_API_KEY",
  temperature: 0.7
}
summarizer_model_config: {
  base_url: "https://api.openai.com/v1",
  model: "gpt-4o-mini",
  api_key_ref: "env:OPENAI_API_KEY"
}
mcp_servers: [
  { name: "claude", transport: "http",
    url: "http://claude-worker-mcp:8080/mcp",
    auth_header_ref: "env:CLAUDE_WORKER_TOKEN" }
]
ctx_budget_tokens: 32000
debounce_window_ms: 4000
```

## Наблюдаемость (минимальный набор)

Prometheus метрики:
- `conversation_messages_total{agent, role}`
- `worker_tasks_total{agent, status}`
- `claude_concurrent_running` (gauge)
- `conversation_llm_latency_seconds{agent, model}` (histogram)

Логирование: `slog` JSON, `correlation_id` = `conversation_id`.

## Безопасность

- API-ключи LLM — через env / secret manager, в БД только `env:VAR_NAME` refs.
- MCP stdio-серверы — только из whitelisted директорий.
- MCP HTTP — bearer-token auth.
- Rate limiting per user (Redis) — наследуем из Фазы 1.

## Этапы реализации

### Этап 2.0 — Фундамент данных (неделя 1)
- Ent-схемы: `AgentBinding`, `Conversation`, `ConversationMessage`, `ConversationSummary`, `WorkerTask`.
- Расширение `Agent`.
- Миграции + data migration (старые `Session` → `AgentBinding` + `Conversation`).
- Unit тесты на схемы, hooks, seq монотонность.

### Этап 2.1 — Event Bus + LLM клиент (неделя 1)
- `internal/eventbus/` — Redis Streams продьюсер/консюмер с consumer groups.
- `internal/llm/` — OpenAI-compat клиент на `openai-go`, tool calling loop, streaming.
- Token counting через `tiktoken-go`.
- Unit тесты (fake LLM через httptest).

### Этап 2.2 — Claude Worker MCP (неделя 2)
- `services/claude-worker-mcp/` — MCP server на `go-sdk`.
- Tools: `delegate_to_claude`, `check_task_status`, `cancel_task`, `list_active_tasks`.
- Parser `stream-json` → worker events в Event Bus.
- Лимит параллелизма + recovery при рестарте.
- Integration тесты с fake Claude CLI (shell-скрипт фикстура).

### Этап 2.3 — Conversation Service (неделя 2-3)
- `services/conversation-service/` — Kratos сервис.
- Conversation Worker Loop (state machine: `idle`/`debouncing`/`generating`).
- Prompt builder + sliding window.
- Фоновая суммаризация.
- MCP клиент с per-conversation server-pool.
- Integration тесты full-loop (mock LLM + mock MCP + real Redis).

### Этап 2.4 — Telegram Gateway рефакторинг (неделя 3)
- Миграция с `go-telegram-bot-api` на `telego`.
- Команды `/new`, `/conversations`, `/switch`.
- Streaming ответов через `editMessage`.
- Удаление прямого запуска Claude — передача в `conversation-service` через gRPC + Event Bus.

### Этап 2.5 — Дашборд (неделя 3-4)
- Страница Agents: вкладки `Conversational Model`, `Summarizer Model`, `MCP Servers`, `System Prompt`.
- Страница `Conversations` per agent + детальный вид.
- Страница `Worker Tasks` с фильтрами и cancel-кнопкой.
- WebSocket real-time обновления.

### Этап 2.6 — Интеграция и rollout (неделя 4)
- Feature flag `USE_CONVERSATION_SERVICE` per-agent.
- E2E тесты в Docker Compose.
- Поэтапное включение: личный агент → остальные.
- Через 1-2 недели — удаление старого синхронного пути.

## Verification

**Unit (80%+ coverage):**
- Conversation Worker state machine (фейковые inbox / LLM / MCP).
- Prompt builder (учёт токенов, включение summary, граница окна).
- Parser `stream-json` Claude.
- Recovery logic (restart_count).

**Integration:**
- Full loop: `mock_telegram → conversation-service → mock_llm → mock_mcp → back` через real Redis.
- Миграции up/down, транзакционный seq.
- MCP клиент подключение / tools discovery.

**E2E (Docker Compose):**
1. user message → ответ без воркера.
2. user message → `delegate_to_claude` → progress → result → ответ.
3. серия быстрых сообщений → debounce + batch.
4. параллельные conversations в одном `AgentBinding`.
5. `/switch` между conversations.
6. рестарт `claude-worker-mcp` во время running task → recovery.
7. провайдер LLM: OpenAI → OpenRouter → локальный Ollama (смена `base_url`).

**Production smoke:**
- Включить Фазу 2 на личном агенте (Second Brain), проверить:
  - Ответы не блокируются Claude-subprocess.
  - Быстрые серии сообщений не создают race conditions.
  - Параллельные conversations с разными Claude-сессиями работают независимо.
  - Метрики `worker_tasks_total` и `conversation_llm_latency_seconds` собираются в Prometheus.

## Что намеренно НЕ делаем в этой фазе (YAGNI)

- Multi-tenant разделение (один deployment = одна организация).
- Шифрование истории разговоров в БД (только at-rest через Postgres).
- NATS JetStream (Redis Streams достаточно на старте).
- Голосовой канал, WhatsApp, другие мессенджеры.
- Multi-agent War Room — отдельный проект.

---

## Связанные документы

- [[prd]] — исходный PRD AgentOS (Фаза 1, синхронный путь)
- [[masterplan]](200_Projects/240_MicroSaaS/242_TG_Claude_Code_Assistant/masterplan.md) — предыдущая версия идеи: TG Claude Code Assistant
- [[2026-04-16 - ClaudeClaw The Sequel - Build Your AI As...]] — вдохновение архитектуры
- [[OpenClaw - обзор платформы]] — концепция agent harness
