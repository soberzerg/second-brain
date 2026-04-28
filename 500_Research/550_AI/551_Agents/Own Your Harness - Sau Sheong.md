---
type: research
date: 2026-04-28
source: https://sausheong.com/own-your-harness-2f5299a855a7
author: Sau Sheong
project: AGIents
status: active
tags: [agent-harness, compaction, claude-code, openclaw, agent-infrastructure, memory, summarisation]
---

# Own Your Harness — что compaction в Claude Code и OpenClaw говорит об инфраструктуре агентов

> Sau Sheong, Medium, апрель 2026 (~17 мин). Глубокий разбор стратегий compaction в Claude Code и OpenClaw как иллюстрация того, почему harness — это не "тонкая обёртка над моделью", а ключевой дифференциатор продукта.

## Контекст: почему harness — новая поляна

Все крупные игроки сместили фокус с моделей на harness:

- **OpenAI** — workspace agents, Agents SDK, Frontier для оркестрации at scale.
- **Anthropic** — domain-specific harness'ы: Claude Code, Claude Cowork, Claude Design (одна модель, разные среды).
- **Microsoft** — Agent 365: identity, governance, lifecycle — агенты как first-class entities.
- **Google** — Gemini Enterprise Agent Platform на Cloud Next 2026.
- **xAI** — покупает Cursor, чтобы получить workflow и developer execution loop.

> "Модель — это двигатель, harness — это автомобиль. Оба важны, но если у тебя нет миллиардов на свою модель, тогда хотя бы владей harness'ом. Иначе ты пассажир." (Shangru, парафраз)

**Ирония:** Boris Cherny (создатель Claude Code) на Latent Space podcast в мае 2025 назвал Claude Code "the thinnest possible wrapper over the model". При этом в реальности там 8 механизмов compaction, sandboxed forked subagents, beta API features, prompt tuning по телеметрии миллионов сессий.

## Что такое compaction

Каждый turn агент шлёт назад весь контекст: tool calls, file reads, errors, model output. Контекст-окно — 200K (или 1M за деньги). **Compaction = весь стек приёмов**, чтобы не упереться в стену:

- дёшево: drop old tool results, trim bash logs
- дорого: позвать модель, чтобы она сделала summary
- предиктивно (до проблемы) или реактивно (когда уже почти стена)
- заменить историю summary'ем или записать факты в persistent memory
- реальные агенты делают **несколько вещей сразу**, и порядок/треshholds/prompts/взаимодействие с prompt cache — всё это design space с десятками решений

## Две противоположные стратегии: когда compactить

### Claude Code — реактивная

- Логика в `autoCompact.ts`.
- Auto-compaction срабатывает, когда running token count в пределах **13K от effective context window**.
- Manual `/compact` — блокирует на **3K**.
- Reactive fallback ловит API'шный `prompt_too_long` 413, если всё остальное промахнулось.
- **Доверяет модели идти до самой стены.**

### OpenClaw — превентивная

- Перед **каждым** LLM-вызовом оценивает токены, умножает на **1.2 safety margin**, спрашивает "влезет ли?".
- Если нет — выбирает дешёвую стратегию: `truncate_tool_results_only` → `compact_only` → `compact_then_truncate`.
- `transformContext` guard кидает "Context overflow", если запрос >**90% окна**.

**Никто не "правильнее":** reactive проще и быстрее на happy path, preemptive — defensiveнее, лучше работает на сюрпризах (длинные tool results подряд, бесконтрольно раздувшийся file read).

## Дешёвые трюки каждый турн (без LLM)

### Claude Code — `cache_edits` (читерский козырь)

Beta-фича API: клиент говорит серверу "удали вот эти tool results из закешированного prefix'а". Локальный список сообщений целый, но кеш-prefix хирургически правится — **eviction без cache miss**. Для 200K-токен prefix invalidation = реальные деньги на следующем turn.

- Запускается **каждый турн** для tools на whitelist'е (Read, Bash, Grep, Glob, Edit, Write, WebSearch, WebFetch).
- "Cached microcompact" в коде.
- Time-based вариант: после 60+ мин idle (server-side cache всё равно холодный).
- **Доступно только потому, что Anthropic владеет своим API.**

### OpenClaw — generic guards

- `tool-result-context-guard` — режет любой tool result >50% окна, кидает overflow на >90%.
- "Tool-pair repair" — удаляет orphan'ы `tool_result` после прунинга (Anthropic API ругается, если matching `tool_use` уже выпал). Claude Code в этом не нуждается, т.к. cache_edits бьёт прицельно.

### Sliding window (оба)

- Claude Code: "snip"
- OpenClaw: `limitHistoryTurns` + `pruneHistoryForContextShare` (роняет старейшее, пока контекст не <= половины окна)

**Takeaway:** значимая часть compaction'а происходит **до** LLM-summarisation. Чем умнее дешёвый слой — тем дальше отодвигается дорогой вызов. Claude Code отодвигает максимально, потому что у него API-features, которых нет ни у кого.

## Когда eviction не хватает: summarisation

### Claude Code

- **Один LLM-вызов** на всю историю.
- Images/documents — placeholder'ы, чтобы экономить токены summariser'а.
- Вывод капается на **20K токенов** (p99.99 historical = ~17,387, по комментарию в коде).
- **Streaming** — пользователь видит summary по мере генерации.
- Summariser крутится через `runForkedAgent` → **наследует prompt cache prefix родителя**, поэтому вызов в основном cache hit. Без этого — "98% cache miss, costs ~0.76% of fleet cache_creation (~38B tok/day)".

### OpenClaw

- Делегирует в pi-coding-agent SDK, можно использовать **отдельную дешёвую модель** (`agents.defaults.compaction.model`).
- Если разговор не влезает в один shot — **chunking по tool-call boundaries** (assistant tool_use + matching tool_result всегда вместе), summarise каждого chunk'а отдельно, потом **merge call**.
- Merge prompt (стоит привести):

```
Merge these partial summaries into a single cohesive summary.

MUST PRESERVE:
- Active tasks and their current status (in-progress, blocked, pending)
- Batch operation progress (e.g., '5/17 items completed')
- The last thing the user requested and what was being done about it
- Decisions made and their rationale
- TODOs, open questions, and constraints
- Any commitments or follow-up promised

PRIORITIZE recent context over older history. The agent needs to know
what it was doing, not just what was discussed.
```

> **Закрывающая фраза — суть compaction'а в одном предложении:** "The agent needs to know what it was doing, not just what was discussed."

### `auditSummaryQuality` — то, чего нет у Claude Code

OpenClaw делает **детерминированный аудит** после генерации:

- проверяет, что все 5 required headings присутствуют в нужном порядке
- что каждый identifier из последних 10 сообщений выжил в тексте summary
- что последний user ask имеет token-overlap с summary

Если что-то fail — re-generate с structured feedback (`missing_section: ## Decisions`, `missing_identifiers: abc123`). Агент сам себя проверяет и пересдаёт.

Claude Code этого не имеет — доверяет модели следовать схеме с первого раза.

## Prompts рассказывают всю историю

### Claude Code — narrative handoff

`BASE_COMPACT_PROMPT` (`src/services/compact/prompt.ts`) требует **9-секционный narrative summary**: primary request and intent, key technical concepts, files and code sections, errors and fixes, problem solving, **all user messages**, pending tasks, current work, optional next step.

**Хитрость для next step:** требует **direct verbatim quotes** из последнего разговора — защита от model drift при пост-compaction интерпретации задачи.

**Aggressive no-tools preamble** в начале prompt'а появился после того, как Sonnet 4.6 с adaptive thinking начал звать tools во время compaction в **2.79%** случаев (vs **0.01%** на Sonnet 4.5). Cache-sharing fork наследует toolset родителя (иначе cache key меняется), поэтому пришлось крикнуть "Tool calls will be REJECTED and will waste your only turn".

### OpenClaw — contract spec

5 терсе headings: Decisions, Open TODOs, Constraints/Rules, Pending user asks, Exact identifiers. Отдельная инструкция "preserve all opaque identifiers exactly as written" (UUIDs, hashes, IDs, hostnames, IPs, ports, URLs, file names) — со strict/off/custom policy modes. **Audit step реально это проверяет.**

**Стилевая разница:**

- Claude Code = senior engineer, пишет careful handoff note (второе лицо, prose: "Pay special attention to specific user feedback")
- OpenClaw = contract spec, imperative blocks ("MUST PRESERVE … PRIORITIZE recent context")

Prompt schema напрямую мапится на verification: warm prose → нет programmatic safety net; strict schema → есть audit loop.

## Memory как комплемент compaction

### Claude Code — memory **заменяет** summary

- Один markdown с **10 фиксированными секциями**: Session Title, Current State, Task spec, Files and Functions, Workflow, Errors & Corrections, Codebase docs, Learnings, Key results, Worklog.
- Обновляется инкрементально **forked subagent'ом** с правами "Edit only this one file".
- Триггеры: 10K токенов (init), 5K между апдейтами, 3 tool calls между апдейтами.
- При compaction — **если файл существует и не пуст, он становится post-compact summary'ем. LLM-summarisation не вызывается вообще.**

### OpenClaw — memory **дополняет** summary

- Append-only журнал markdown-файлов, индексирован в **SQLite + FTS5 + embeddings**.
- Запись в "memory flush" turn перед compaction (subagent с правами только append-write в один путь).
- После compaction memory **не инжектится автоматически** — следующий run получает refresh prompt со ссылкой на workspace, контент возвращается лениво через memory search tool.

**Структурный контраст:**

| | Claude Code | OpenClaw |
|---|---|---|
| Schema | fixed 10-section markdown | append-only journal + FTS5 + embeddings |
| Когда обновляется | continuously (каждые 5K токенов / 3 calls) | bursts перед compaction |
| Роль | substitute для summary | preamble для compaction |
| Доступ после compact | inject as user message | lazy retrieval через search tool |

## Когда всё ломается

### Claude Code — circuit breaker + lossy fallback

- `MAX_COMPACT_STREAMING_RETRIES = 2` (transient streaming).
- `MAX_PTL_RETRIES = 3` (если сам compaction request тригерит prompt_too_long). `truncateHeadForPTLRetry` дропает старейшие message groups, добавляет `[earlier conversation truncated for compaction retry]`. **Intentionally lossy** — комментарий: "the dumb-but-safe fallback for the proactive/manual path".
- `MAX_CONSECUTIVE_AUTOCOMPACT_FAILURES = 3`. Обоснование в коде:

> **"1,279 sessions had 50+ consecutive failures (up to 3,272) in a single session, wasting ~250K API calls/day globally."**

Circuit breaker появился потому, что кто-то в Anthropic посмотрел в логи и увидел деньги, горящие в loop'е застрявших агентов.

### OpenClaw — snapshot и cancel

- Перед `session.compact()` копирует session-файл в `.checkpoint.<uuid>.jsonl` sibling. Success → checkpoint остаётся (можно откатиться). Failure → cleanup.
- Если safeguard не может произвести clean summary — возвращает `{ cancel: true }`, SDK продолжает с unmodified transcript.
- **Progressive fallback chain:** `summarizeWithFallback` сначала пробует full summarisation, потом "summarise только small messages, large — пометить", потом "просто пометить, что там было". Один OOM chunk не убивает всю compaction.

**Что они оптимизируют:**

- Claude Code — **fast user feedback**: retry молча, fallback to lossy, give up чтобы не жечь API. Хороший выбор когда агент = primary tool пользователя и unblocking важнее fidelity.
- OpenClaw — **transcript preservation**: если нельзя сделать безопасно — не делать вообще, оставить оригинал. Хороший выбор когда conversation history = ценный артефакт.

## Cost & latency

### Cost

- **Claude Code дешевле на hot path.** 3 из 4 механизмов (cachedMicrocompact, time-based MC, API-side context management) = zero-LLM. Full compact — cache-warm prefix через forked-agent трюк. Нет cheap-model option.
- **OpenClaw дороже.** Chunked summarisation = N+1 LLM calls (per chunk + merge), каждый с разным user message → prefix cache reuse ≈ 0. Компенсирует это через возможность отдельной дешёвой модели.

### Latency

- **Claude Code streams.** Output появляется инкрементально, нет explicit upper-bound timeout.
- **OpenClaw sequential.** Чанки идут один за другим через plain `await` (нет `Promise.all`), 4-chunk compaction ≈ 4× per-chunk + merge. Hard 15-минутный safety timeout.

**Архитектурный итог:** Claude Code дешевле и быстрее, потому что владеет inference layer'ом и API features, недоступными другим. OpenClaw — defensiveнее, верифицируемее, портативнее, потому что должен работать с провайдерами, которыми не владеет.

## Главный аргумент: "Own your harness"

Compaction = **один срез** harness'а. На нём одном два самых популярных coding agent'а планеты построили **противоположные стеки на каждом уровне**:

| Решение | Claude Code | OpenClaw |
|---|---|---|
| Триггер | reactive | preemptive |
| Schema summary | narrative | structural |
| Memory роль | заменяет summary | дополняет summary |
| Recovery | lossy + circuit breaker | snapshot + cancel |

Оба работают, оба отгружаются реальным пользователям. **Нет "правильного" ответа под капотом.**

### Что значит "купить harness off the shelf"

Ты наследуешь чужие невидимые решения:

- горячий контекст vs estimate каждый turn
- какая schema у summary
- unblocking vs preservation
- threshold values, retry budgets, fallback chains

**Ничего из этого не задокументировано в README** — это не features, это invisible scaffolding, определяющее, работает ли твой агент **для твоих пользователей в твоей доменной области**.

### Калибровка по чужой телеметрии

Цифра "1,279 сессий с 50+ failures, ~250K API calls/день" пришла **не из architectural review** — из production logs. Цифра "2.79% vs 0.01% tool calls" — тоже из telemetry, и она привела к переписыванию no-tools preamble.

Если кто-то другой владеет твоим harness'ом — он владеет и твоей телеметрией. Оптимизации будут под их fleet, не твой. **Ты всегда будешь пассажиром на чужом roadmap'е.**

### Compaction — только видимая часть

Ту же design depth имеют: tool routing, subagent orchestration, streaming protocol, error classification, cache management, plan persistence, cost accounting. Каждый слой — два разумных инженера будут спорить, и правильный ответ зависит от твоей модели/пользователей/latency budget/failure tolerance.

**Купив harness, ты не отказываешься от этих решений — ты отказываешься от того, чтобы их принимать.** Это разные и сильно худшие вещи.

### Прагматичный nuance

Не надо писать harness с нуля в day one. Reuse как у OpenClaw (обёртка над pi-coding-agent + host glue) — разумный старт. **Но в момент, когда упрётся в weird production behaviour, latency profile разойдётся с upstream defaults, или пользователи начнут хотеть того, что upstream не оптимизировал** — придётся читать чужой код и жалеть, что границы не нарисованы в твою пользу. Чем раньше нарисуешь — тем дешевле.

## Применение к моим проектам

### AGIents / orchestrator

Готовый чеклист дизайн-решений для собственного harness'а. Прямая связь с текущей работой над goalrunner/scheduler:

- **Триггер compaction:** reactive проще для MVP, но preemptive ловит сюрпризы. Стоит сразу заложить token estimation перед каждым LLM call.
- **Memory:** какую модель выбрать — Claude Code (markdown с фиксированной schema, заменяет summary) или OpenClaw (append-only journal + FTS5)? Зависит от того, как долго длятся сессии и сколько агентов параллельно.
- **Recovery:** circuit breaker на consecutive failures с самого начала — иначе будем жечь токены, как 1,279 сессий Anthropic.
- **Telemetry:** надо логировать всё, что может вылиться в empirical prompt engineering. Без своих метрик — будем чинить по vibes.

### Блог

Сильный пост-кандидат: **"Почему свой harness важнее модели — на примере compaction в Claude Code и OpenClaw"** (RU). Цифры из статьи + перекличка с твоим текущим проектом orchestrator. Можно сделать карусель: 2 стратегии compaction рядом, контрастные таблицы.

---

## Связанные документы

- [[OpenClaw - обзор платформы]] — детальный разбор архитектуры OpenClaw, продолжение темы harness
- [[Open-Source альтернативы Claude Code - исследование 2026]] — обзор open-source harness'ов
- [[Boris Cherny - Claude Code Development Workflow]] — Boris Cherny упоминается в статье ("thinnest possible wrapper")
- [[Claude Code as Embedded OS - Gur Sannikov]] — другая перспектива на Claude Code как платформу
- [[2026-04-25 Память для агентов и Ralph Loop]] — пост о памяти для агентов, тема перекликается
- [[Создание субагентов - полное руководство 2026]] — forked subagents упоминаются как механизм memory updates
