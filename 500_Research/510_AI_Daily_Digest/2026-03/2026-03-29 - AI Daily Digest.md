---
type: ai-daily-digest
date: 2026-03-29
platforms: [X/Twitter]
period: 2026-03-28 — 2026-03-29
status: completed
tags: [daily-digest, ai-news, auto-generated]
---

# AI Daily Digest — 2026-03-29

**Период:** 2026-03-28 — 2026-03-29
**Платформы:** X/Twitter

> AI-синтезированный анализ через Grok API (X/Twitter) + Firecrawl API (Reddit) + Claude (синтез)

---

## Top Stories

### 1. Claude Mythos (Capybara) — утечка следующего frontier model от Anthropic
**Источник:** X | **Ссылка:** [https://x.com/johniosifov/status/2037822246446596558](https://x.com/johniosifov/status/2037822246446596558)

Утечка информации о Claude Mythos — модели крупнее Opus 4.6, обученной на ~10T токенов, с существенным скачком в reasoning, coding и cybersecurity. Релиз задержан из-за потенциальных рисков в области кибербезопасности. Параллельно OpenAI готовит модель под кодовым именем "Spud".

### 2. ARC-AGI-3 benchmark: AI <1%, люди — 100%
**Источник:** X | **Ссылка:** [https://x.com/shani_singh1/status/2037811812373303427](https://x.com/sh037811812373303427)

Новый benchmark ARC-AGI-3 наглядно демонстрирует текущий gap в general reasoning: люди справляются на 100%, тогда как лучшие AI-модели не преодолевают 1%. Это переосмысляет нарратив об "AGI на пороге" и задаёт новую планку для frontier labs.

### 3. Claude Code эволюционирует: autofix PRs, auto mode, multi-agent
**Источник:** X | **Ссылка:** [https://x.com/felixrieseberg/status/2038038711368384829](https://x.com/felixrieseberg/status/2038038711368384829)

Anthropic расширяет Claude Code функциями autonomous coding: autofix для pull requests и auto mode для полностью автономной работы. Отдельно — Claude Cowork как абстракция над Claude Code с sandboxing для non-technical users ("gives Claude a full developer computer").

### 4. Memory portability между LLM: Gemini импортирует историю из ChatGPT и Claude
**Источник:** X | **Ссылка:** [https://x.com/tisch_eins/status/2037797063736406191](https://x.com/tisch_eins/status/2037797063736406191)

Gemini добавил импорт conversation history и memories из ChatGPT и Claude — первый значимый шаг к снижению switching costs между моделями. В связке с этим: Cohere Transcribe показывает результаты лучше Whisper в ряде задач.

### 5. OpenClaw vs MCP: конкуренция за agent interoperability protocol
**Источник:** X | **Ссылка:** [https://x.com/thomasheimann/status/2037872376130503077](https://x.com/thomasheimann/status/2037872376130503077)

OpenClaw позиционируется как MCP-альтернатива от сообщества — с утечкой system prompts от Claude Code, Cursor и Devin. Обсуждение открывает вопросы о стандартизации agent protocols и security implications при работе с leaked system prompts.

---

## X/Twitter Highlights

- **@shani_singh1** — еженедельный саммари: утечка Claude Mythos, ARC-AGI-3 benchmarks, ускорение LLM release cycle. Фокус на AI Scientist perspective.
- **@johniosifov** (Founder, Ender Turing) — детальный разбор enterprise race: Anthropic $15.2B B2B ARR vs OpenAI, Gemini 3.1 Flash для real-time voice/vision agents, практические workflows с Claude Code.
- **@felixrieseberg** (Anthropic) — инсайдерское объяснение: Claude Cowork — это Claude Code с abstractions и sandboxing. 179 likes.
- **@tom_doerr** — репозиторий для AI video production в Claude Code. 991 likes — высокий engagement на практический tool.
- **@thomasheimann** (Founder, AgentZero) — OpenClaw как community-driven альтернатива MCP, leaked system prompts Claude Code/Cursor/Devin — security-угол для agent ecosystems.
- **@tisch_eins** — memory portability update: Gemini импортирует историю из ChatGPT/Claude, Cohere Transcribe vs Whisper.
- **@farzyness** — 682 likes на тезис: Claude Code для custom software + OpenClaw как personal assistant = новый daily workflow stack.

---

## Reddit Discussions

*Данные за 28–29 марта 2026 недоступны.*

---

## Тренды дня

- **Frontier model leaks** — утечки Claude Mythos и OpenAI Spud формируют ожидания рынка быстрее официальных анонсов
- **Autonomous coding agents** — Claude Code autofix/auto mode, multi-agent workflows переходят из экспериментальных в production-ready
- **Agent protocol wars** — конкуренция MCP vs OpenClaw обозначает борьбу за стандарт interoperability в agent ecosystems
- **Reasoning gap** — ARC-AGI-3 (AI <1%) переключает дискурс от "AGI близко" к "AGI сложнее, чем думали"
- **Memory portability** — Gemini-ход с импортом истории снижает lock-in, давит на OpenAI и Anthropic в сторону открытых стандартов

---

## Релевантность для проектов

### AGIents.pro

- **MCP vs OpenClaw** — прямая тема для платформы: если OpenClaw набирает traction, стоит следить за протоколом и рассмотреть поддержку обоих стандартов в agent integrations
- **Claude Code autofix PRs** — новый autonomous mode открывает возможность для интеграции code-fixing агентов в пайплайны платформы
- **Gemini 3.1 Flash (real-time voice/vision)** — релевантный model choice для real-time agent сценариев; стоит оценить как альтернативу текущему стеку
- **Memory portability** — архитектурный вопрос: как AGIents хранит и переносит agent memory между сессиями и моделями?

### AISobolev Blog

- **ARC-AGI-3 разбор** — сильный материал: "Почему AI набирает <1% там, где человек 100% — и что это значит для AGI-таймлайнов"
- **Claude Mythos leak analysis** — аналитический пост о том, что утечки говорят о направлении развития frontier models и о cybersecurity как новом bottleneck для релизов
- **Сравнение Claude Code vs Cowork** — практический туториал/объяснение для аудитории: чем они отличаются, кому что подходит
- **Memory portability как тренд** — эссе о том, как снижение switching costs меняет конкуренцию между LLM-провайдерами

---

*Auto-generated by ai-daily-digest.sh*
*APIs: Grok API (X/Twitter) + Firecrawl Search (Reddit) + Claude SDK (synthesis)*
