---
type: social-research
date: 2026-04-29
source: https://www.reddit.com/r/artificial/comments/1so03op/agentic_os_an_governed_multiagent_execution/
author: u/ramirez_tn
project: AGIents
status: active
tags: [reddit, agentic-os, multi-agent, governance, hitl, mcp, prioritization]
---

# Agentic OS — приоритизация фич сообществом

Выжимка из поста u/ramirez_tn в r/artificial и анализ комментариев для приоритизации фич, релевантных для платформы [[AGIents]].

## Метаданные поста

- **Источник:** [Reddit r/artificial](https://www.reddit.com/r/artificial/comments/1so03op/agentic_os_an_governed_multiagent_execution/)
- **Автор:** u/ramirez_tn
- **Score:** 0 · **Upvote ratio:** 0.44 · **Комментариев:** 13 (12 валидных)
- **Демо:** agenticompanies.com (требует invitation code + свой Anthropic/OpenAI API key)

> ⚠️ **Сигнал по приёму поста:** ratio 0.44 + score 0 — даунвоутов примерно столько же, сколько апвоутов. Положительные комментарии есть, но silent-аудитория голосует против. Возможные причины: воспринят как self-promo (ссылка на платформу), слишком абстрактно без визуального демо. **Учитывать при интерпретации:** «лайки идеям» в комментариях ≠ полная валидация рынка.

## Что предлагает автор

Платформа, где упор не на самих агентов, а на **governance & execution layer** вокруг них.

### Ключевые фичи

- **MCP-gateway** — единственный путь к инструментам, per-role RBAC + audit log
- **Zero shared mutable state** — агенты обмениваются через structured handoffs
- **Policy engine** — proceed / block / timeout-with-default
- **Append-only task versioning** — автор + причина каждого изменения
- **Evaluation engine** — quality, iterations, latency, cost, policy compliance
- **Agent reputation scoring** — QA pass rate, iteration efficiency, latency, cost, reliability

### Архитектура (5 строгих слоёв)

1. Frontend (только визуализация)
2. API gateway (auth/RBAC)
3. Orchestration engine (24 модуля)
4. Agent runtime (без прямого доступа к tools)
5. MCP gateway (единственный путь к tools)

### Стек

React + TypeScript, FastAPI, SQLite WAL, pluggable LLM (OpenAI / Anthropic / Azure), MCP protocol.

### Конфигурация

Team presets (software / marketing / custom), operating models с разными governance-правилами, pluggable LLM backends, reusable skills, MCP-backed integrations.

## Анализ комментариев (12 валидных)

| Голос | Кто | Score | Суть |
|---|---|---|---|
| 👍 | Due_Importance291 | 2 | «Пошёл в full infra mode. Governance + audit logs — настоящий unlock» |
| ❓ | ExplanationNormal339 | 2 | «Как именно state между агентами — structured output или raw text?» |
| 👍 | Routine_Plastic4311 | 2 | «Zero shared state + structured handoffs — настоящие MVP, держат хаос в узде» |
| 👍 | Artistic-Big-9472 | 2 | «Очень продуманная архитектура» |
| 🤝 | pab_guy | 1 | Делает похожее. Нужен **UI для human-operator: системный state + очередь HITL-аппрувов с RBAC-scoped monitoring**. Ключевая фича. |
| 👍 | Fajan_ | 1 | «Большинство систем гонятся за автономией, ты — за контролем. Debug/audit радикально проще» |
| ⚠️ | Low_Blueberry_6711 | 1 | **«Escalation logic — что реально триггерит human approval vs автономию координатора?** Это порог, где системы оказываются слишком осторожны или слишком либеральны на практике» |

Ответы автора в треде:
- На вопрос про state: «Neither raw output nor unstructured state — система использует MCP-mediated structured handoffs»
- На запрос HITL-UI: «User получит нотификацию, операция паузится если у агентов вопрос. Даёшь агентам task, strategy, instructions/directives»

**Доминантный нарратив:** governance > autonomy. Аудит и predictability — главная ценность. Никаких прямых возражений против архитектуры; все вопросы про конкретику реализации.

## Приоритизация фич для AgentOS

Сортировка по силе валидации = (явная похвала + конкретные просьбы дополнить + повторяемость темы).

### 🔥 P0 — подтверждённое ядро ценности

**4 независимых положительных голоса** + ноль возражений.

1. **Zero shared mutable state + structured handoffs через MCP** — самая хвалимая фича (Routine_Plastic, Fajan_, ExplanationNormal, Akira9453). Это и есть «продукт».
2. **Governance layer: per-role RBAC + audit log на каждый tool call** — Due_Importance291, Fajan_ называют это «real unlock».

### 🟠 P1 — конкретные просьбы расширить

Есть запрос от пользователей, но реализация в посте описана недостаточно.

3. **HITL-консоль для оператора с RBAC-scoped monitoring + approval queue** — единственная конкретная feature-просьба от потенциального конкурента/строителя похожего (pab_guy). Автор ответил, что нотификации и паузы есть, но **отдельного UI-обзора системного state и очереди аппрувов в посте не описано** — это gap. Высокая ценность для enterprise-пользователей.
4. **Прозрачная и настраиваемая escalation policy** — Low_Blueberry_6711 указывает на **самое уязвимое место**: где порог между «координатор решает сам» и «эскалация человеку». Нужен явный язык политик (по типу задачи / стоимости / уверенности / impact) + наблюдаемость срабатываний. Это превращает policy engine из чек-бокса в реальный продукт.

### 🟡 P2 — упомянуто автором, но не отрефлексировано сообществом

Нужна дополнительная валидация — никто из комментаторов не зацепился.

5. **Agent reputation scoring** — звучит круто, но риск over-engineering до того, как пользователи попросят. Отложить до первых реальных команд агентов.
6. **Append-only task versioning** — полезно для аудита, но не драйвер adoption.
7. **Evaluation engine (quality/iterations/latency/cost/policy)** — ценно внутри, но как user-facing фича пока не валидирована.

### ⚪ P3 — структурное, не «фича» в смысле демонстрации

8. **Team presets (software/marketing/custom) + pluggable LLM** — стандартное ожидание, не дифференциатор.
9. **5-слойная архитектура** — это «как», а не «что» для пользователя.

## Рекомендации по next moves

- **Удвоить фокус на P0 + P1.** Демо/landing должны показывать (а) audit-trail tool calls в реальном времени, (б) operator console с очередью HITL. Текущий ratio 0.44 = аудитория не «увидела» продукт из-за отсутствия визуального/осязаемого демо в посте.
- **Опубликовать конкретный язык escalation policy** (DSL/YAML примеры) — закрыть возражение Low_Blueberry_6711 публично, превратить слабое место в маркетинговый актив.
- **Reputation scoring и evaluation engine** — оставить в roadmap, но не выводить вперёд, пока на P0+P1 не появятся первые сильные кейсы.

---

## Связанные документы

- [[2026-02-16 - AI Agents Future - Social Research]] — общие настроения сообщества по будущему агентов
- [[AGIents]] — проект-цель приоритизации
