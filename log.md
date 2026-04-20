---
type: note
date: 2026-04-08
tags: [log, wiki-meta]
status: active
---

# Operations Log

> Хронологический лог операций над хранилищем. Append-only.
> Формат: `## [YYYY-MM-DD] <operation> | <Title>` — grep-parseable.
> Операции: ingest, create, update, lint, query.

## [2026-04-20] create | AI Daily Digest — vault-based для фаундера/CTO

- Files created: 500_Research/510_AI_Daily_Digest/2026-04-20 - AI Daily Digest.md
- Files updated: index.md, log.md
- Details: Vault-based digest за 2026-04-16 — 2026-04-20 (без прямого доступа к X/Reddit/web). Секции: Что важно сегодня, Модели/продукты, Open source/инфраструктура, Что это значит для Clario/AGIency, 3 action items. Ключевые темы: harness > model (reverse-engineering Claude Code), vendor lock-in (кейс Anthropic ban), cost management multi-agent (5 часов кредитов / 32 мин), форк Claude Code под GPT/Gemini/DeepSeek, Salesforce Headless 360 (MCP), слухи о параллельных релизах Opus 4.7 и новой Opus-class модели OpenAI. Action items: (1) добавить model-agnostic + cost controls в AGIents Platform Capabilities и шаблон КП, (2) прописать многопровайдерный LLM-слой в Clario v2 RoadMap и Bazis PRD, (3) выложить Threads-тред «harness важнее модели» на базе готового черновика

## [2026-04-20] create | Коммерческое предложение для Krytex

- Files created: 200_Projects/210_AGIency/216_Clients/Krytex/proposal.md
- Files updated: index.md, log.md
- Details: КП на базе PRD — setup 450 000 ₽ (30/40/30 по трём фазам), подписка 5 ₽/запрос без минимума, warranty 30 дней, 6 недель внедрения. CTA — подписать и оплатить аванс 135k до 2026-05-04. Кейсы не использованы (акцент на платформе AGIents), команда без фамилий. TODO: добавить контакты в секции 10

## [2026-04-20] create | PRD Krytex bot + AGIents Platform Capabilities

- Files created: 200_Projects/210_AGIency/216_Clients/Krytex/prd.md, 200_Projects/220_AGIents/Platform Capabilities.md
- Files updated: index.md, log.md
- Details: PRD бота для Krytex на платформе AGIents — Telegram/VK/MAX + маркетплейс-pipeline Ozon/WB, редактор Q&A, лог escalations, 3 фазы по 2 недели. Зафиксированы текущие возможности AGIents (Inbox, Аналитика, Настройки, Пользователи, Сессионная память) отдельным документом для скоупинга клиентских проектов

## [2026-04-19] create | YouTube Summary — I Built My First AI Employee

- Source: <https://youtu.be/zFM5elMy5Do?si=2ncCvgr_Ol2GewKm>
- Files created: 500_Research/530_YouTube/2026-04-19 - I Built My First AI Employee (It Works 24-7).md
- Files updated: index.md, log.md
- Details: Выжимка видео Sandy Coreana о построении AI-команды для контент-автоматизации на Claude Code. Архитектура специализированных агентов (анализ, тренды, сценарии, миниатюры, монтаж, Shorts), outlier video metric, экономика $84–174/мес vs $7–8k/мес на human team, выбор Claude Code vs Claude Cowork, отказ от ChatGPT по этическим причинам, Whisper Flow, стек Google APIs + Descript + Nanobana Pro + OpenRouter

## [2026-04-19] create | YouTube Summary — 5 Anti-Cancer Habits After 50

- Source: <https://youtu.be/he0iwUMQSU0?si=ixxv9Me9NR0SMB77>
- Files created: 500_Research/530_YouTube/2026-04-19 - 5 Anti-Cancer Habits That Cut Your Risk Up To 61% After 50.md
- Files updated: index.md, log.md
- Details: Выжимка видео Dr. William Li о 5 научно обоснованных привычках, снижающих риск рака до 61% у людей старше 50: гидратация, ферментированные продукты, метаболическая ходьба, сульфорафан из крестоцветных, архитектура сна. Ссылки на исследования Harvard, Stanford, UC San Diego, мета-анализ American Cancer Society

## [2026-04-18] create | AgentOS Phase 2 PRD — co-pilot architecture

- Files created: 200_Projects/240_MicroSaaS/245_AgentOS/prd-phase-2.md
- Files updated: index.md, log.md
- Details: PRD Фазы 2 AgentOS — разделение на разговорную часть (OpenAI-compat LLM-loop, конфигурируемая модель) и исполнительную (Claude и прочие воркеры через MCP). Гибрид ack + debounce/batching, Event Bus на Redis Streams, множественные conversations per (user × agent), running summary через дешёвую модель. Build vs buy: go-sdk (MCP) + openai-go + telego + tiktoken-go. 6 этапов за 4 недели

## [2026-04-16] create | CLAUDE.md по принципам Karpathy - Threads тред

- Source: 500_Research/520_Social_Research/2026-04-13 - Google Engineer Automates 80% with Claude Code.md (Part 1)
- Files created: 300_Blog/350_Draft_Posts/351_RU/2026-04-16 CLAUDE.md по принципам Karpathy - Threads.md
- Files updated: index.md, log.md
- Details: Тред из 7 постов для Threads: CLAUDE.md по принципам Karpathy — один файл с правилами снижает ошибки ИИ с 40% до 3%, четыре принципа, 15K звёзд за неделю, ИИ может сам сгенерировать правила под проект

## [2026-04-16] ingest | Krytex Discovery Call

- Source: 000_Inbox/krytex-call-ts.md
- Destination: 200_Projects/210_AGIency/216_Clients/Krytex/Discovery Call 2026-04-16.md
- Files created: 200_Projects/210_AGIency/216_Clients/Krytex/Discovery Call 2026-04-16.md
- Files updated: index.md, log.md
- Details: Транскрипт discovery/демо-звонка с Krytex (автохимия). AI чат-бот на таблице Q&A, обсуждение расширения базы знаний, каналов (Telegram/VK/Instagram/сайт), интеграции с маркетплейсами (Ozon/WB), стоимости. Следующий шаг — КП.

## [2026-04-16] create | AgentOS PRD

- Files created: 200_Projects/240_MicroSaaS/245_AgentOS/prd.md
- Files updated: index.md, log.md
- Details: PRD для MVP AgentOS — серверная платформа оркестрации AI-агентов на Claude Code CLI (subprocess + --resume), Go Kratos + Ent + PG + NATS + Redis, Telegram-боты для управления + React-дашборд для конфигурации, модель доступа для команды

## [2026-04-16] create | ClaudeClaw The Sequel - Build Your AI Assistant

- Files created: 500_Research/530_YouTube/2026-04-16 - ClaudeClaw The Sequel - Build Your AI As....md
- Files updated: index.md, log.md
- Details: Выжимка YouTube-видео: ClaudeClaw — персональная ОС для AI-агентов на Anthropic Agent SDK, War Room (голосовой совет 5 агентов), Hive Mind (коллективная память), многослойная безопасность, PipeCat для голосового I/O

## [2026-04-16] create | OpenClaw - обзор платформы

- Files created: 500_Research/550_AI/551_Agents/OpenClaw - обзор платформы.md
- Files updated: index.md, log.md
- Details: Полный обзор OpenClaw: что это, пятислойная архитектура agent harness, возможности (браузер, система, скиллы, память, каналы), бенчмарки (79.6% с Sonnet 4.6), конкурентный ландшафт, ограничения

## [2026-04-16] create | What Is OpenClaw - The AI That Actually Does Things

- Files created: 500_Research/530_YouTube/2026-04-16 - What Is OpenClaw - The AI That Actually Does Things.md
- Files updated: index.md, log.md
- Details: Выжимка YouTube-видео: OpenClaw — self-hosted open-source AI-ассистент с навыками (Skills), заданиями (Cron Jobs), автономной работой 24/7, VPS-развёртыванием и рисками безопасности вредоносных навыков

## [2026-04-16] create | Harness важнее модели - Threads тред

- Files created: 300_Blog/350_Draft_Posts/351_RU/2026-04-16 Harness важнее модели - Threads.md
- Files updated: index.md, log.md
- Details: Тред из 7 постов для Threads: концепция harness из OpenClaw (Anthropic) применена в Clario — ИИ-ассистент РОПа перешёл от рекомендаций к замкнутому циклу контроля менеджеров

## [2026-04-16] create | Lead Magnets are Dead - MicroMagnets

- Files created: 500_Research/530_YouTube/2026-04-16 - Lead Magnets are Dead - MicroMagnets.md
- Files updated: index.md, log.md
- Details: Выжимка YouTube-видео: микро-магниты вместо традиционных лид-магнитов — матрица Hot/Safe, трёхэтапное создание (занозы → название-инструмент → чит-код), формула Leo Burnett, воронка "лёгких да"

## [2026-04-16] create | How I went PRO with content

- Files created: 500_Research/530_YouTube/2026-04-16 - How I went PRO with content.md
- Files updated: index.md, log.md
- Details: Выжимка YouTube-видео: Influential vs Influencer контент-стратегия — 3P-фреймворк (Problem/Proof/Position), цикл See-Connect-Say, продуктивность + опасность = доход

## [2026-04-16] create | How We Sign a New High-Ticket Client Every 16 Hours

- Files created: 500_Research/530_YouTube/2026-04-16 - How We Sign a New High-Ticket Client Every 16 Hours.md
- Files updated: index.md, log.md
- Details: Выжимка YouTube-видео: продажа high-ticket коучинга без sales calls — Offer Doc + Sold Out Sequence + Brandwidth контент-стратегия

## [2026-04-15] ingest | Google Engineer Automates 80% with Claude Code

- Files created: 500_Research/520_Social_Research/2026-04-13 - Google Engineer Automates 80% with Claude Code.md
- Files updated: index.md, log.md
- Details: Сохранён вирусный пост X (@noisyb0y1, ~3M просмотров): Google-инженер автоматизировал 80% работы с Claude Code, CLAUDE.md (15K звёзд), Everything Claude Code (153K звёзд), экономия $3-12K/мес

## [2026-04-13] create | Dogovor24 AI Document Estimate

- Files created: 200_Projects/230_Clario/233_PRDs/Dogovor24-AI-Document-Estimate.md
- Files updated: index.md, log.md
- Details: Оценка трудозатрат документ-ассистента — 1684 часа (Phase 1: 768ч, Phase 2: 616ч, Phase 3: 300ч), команда 4 чел. (Backend Go + AI/ML + Frontend React + DevOps)

## [2026-04-13] create | Dogovor24 AI Document Assistant PRD

- Files created: 200_Projects/230_Clario/233_PRDs/Dogovor24-AI-Document-Assistant-PRD.md
- Files updated: index.md, log.md
- Details: PRD для КП клиенту Dogovor24 — AI-ассистент по созданию юридических документов: чат-интерфейс по типу ChatGPT, графовая БД шаблонов/клауз/рисков из конструктора D24, Dialogue Agent + Graph Query Engine + Document Composer, интеграция с AI Legal Gateway (проверка рисков) и ЭДО D24 (подписание ЭЦП), стек Go Kratos + Ent

## [2026-04-12] create | Dogovor24 AI Legal Assistant PRD

- Files created: 200_Projects/230_Clario/233_PRDs/Dogovor24-AI-Legal-Assistant-PRD.md
- Files updated: index.md, log.md
- Details: PRD для КП клиенту Dogovor24 — мультиагентная AI-система юридических консультаций: Router Agent + специализированные агенты по областям права + RAG по НПА РК + интеграция с amicus-service + workflow модерации + 3-фазный переход к автоматизации

## [2026-04-09] create | Bazis Call Center Automation PRD

- Files created: 200_Projects/230_Clario/233_PRDs/Bazis-Call-Center-Automation-PRD.md
- Files updated: index.md, log.md
- Details: PRD для КП клиенту Базис — автоматизация колл-центра: голосовой ИИ-ассистент, чат-боты WhatsApp+Telegram, CRM-интеграция, гибрид Phase 1 → полная автоматизация Phase 3

## [2026-04-09] ingest | Discovery Bazis Call Center

- Source: 000_Inbox/-Orchid-lab-Bazis-3b30f7b5-bd6c.md
- Destination: 200_Projects/230_Clario/234_Chats/2026-04-08-Discovery-Bazis-Call-Center.md
- Files created: 2026-04-08-Discovery-Bazis-Call-Center.md
- Files updated: index.md, log.md
- Details: Транскрипт discovery-звонка с Никитой Сложеникиным (CMO Базис) — автоматизация колл-центра застройщика, ~200 звонков/день, запрос на единую систему голосовых и чат-ботов

## [2026-04-08] create | Wiki Infrastructure

- Files created: log.md, index.md
- Details: Инициализация LLM Wiki инфраструктуры — навигационный индекс и операционный лог

## [2026-04-08] update | CLAUDE.md — LLM Wiki workflows

- Files updated: CLAUDE.md
- Details: Добавлены index.md/log.md в структуру, workflow обновления, session start, analysis workflow, тип analysis

## [2026-04-08] create | Skills: /ingest, /wiki-lint

- Files created: .claude/skills/ingest/SKILL.md, .claude/skills/wiki-lint/SKILL.md
- Details: Два новых skill — обработка Inbox и health check хранилища

## [2026-04-08] update | Existing skills — wiki bookkeeping

- Files updated: ai-digest, daily-review, youtube-summary, social-research, web-research SKILL.md
- Details: Добавлен финальный шаг Wiki Bookkeeping (обновление index.md и log.md)

## [2026-04-08] update | Commands: inbox-processor, weekly-synthesis

- Files updated: .claude/commands/inbox-processor.md, .claude/commands/weekly-synthesis.md
- Details: inbox-processor → lightweight scan + redirect на /ingest; weekly-synthesis → lint шаг #2

## [2026-04-08] create | 590_Analysis directory

- Files created: 500_Research/590_Analysis/README.md
- Details: Новая директория для внутренне-производного анализа и синтеза

## [2026-04-08] ingest | LLM Wiki — паттерн персональной базы знаний

- Source: 000_Inbox/llm-wiki.md
- Destination: 500_Research/550_AI/LLM Wiki - паттерн персональной базы знаний.md
- Files created: 500_Research/550_AI/LLM Wiki - паттерн персональной базы знаний.md
- Files updated: index.md
- Details: Первый ingest через новый workflow. Структурированная выжимка паттерна LLM Wiki с маппингом на наш Second Brain

## [2026-04-19] query | Jensen Huang 5-layer AI cake — материал для статьи

- Files created: 500_Research/590_Analysis/Jensen Huang 5-layer AI cake - материал для статьи.md
- Files updated: index.md
- Details: Собран полный текст поста @r0ck3t23 (298k views), оригинальные цитаты Jensen Huang из NVIDIA Blog / Davos 2026 / Dwarkesh podcast, экспертные реакции (StockSavvyShay, Cassie Kozyrkov, Aakash Gupta), 6 готовых углов для статьи и ключевые цитаты ready-to-paste
