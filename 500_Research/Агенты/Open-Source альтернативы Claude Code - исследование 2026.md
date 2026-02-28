# Open-Source альтернативы Claude Code для "Second Brain" сервиса

**Дата исследования:** 13 февраля 2026
**Цель:** Найти open-source инструменты для построения сервиса "Second Brain" на базе открытых моделей (DeepSeek, Qwen, GLM-5, Kimi 2.5)

---

## TL;DR — Рекомендации

| Задача | Лучший выбор | Почему |
|--------|-------------|--------|
| Замена Claude Code (кодинг) | **OpenCode** | 100K+ stars, Go, 75+ провайдеров, MCP, Ollama |
| Second Brain (знания + агенты) | **Khoj** | Создан именно для этого, Obsidian-плагин, self-hosted |
| Универсальный агент + MCP | **Goose (Block)** | Linux Foundation, MCP-native, рецепты, scheduler |
| Desktop AI-ассистент | **PyGPT** | Все-в-одном, MCP, Ollama, RAG, агенты |
| Корпоративная база знаний | **Casibase** | MCP + A2A, админка, SSO, multi-model |

---

## 1. OpenCode

**URL:** https://opencode.ai | [GitHub](https://github.com/opencode-ai/opencode)
**Что это:** Терминальный AI-кодинг агент, прямой open-source аналог Claude Code
**Язык:** Go | **Лицензия:** Open Source
**GitHub Stars:** ~100K+ | **Контрибьюторы:** 700+ | **Коммиты:** 9000+

### Ключевые возможности
- Нативный TUI (Terminal User Interface) на Bubble Tea
- 75+ AI-провайдеров (OpenAI, Anthropic, Gemini, Groq, Azure, OpenRouter, Ollama)
- Два встроенных агента: **build** (полный доступ) и **plan** (read-only анализ)
- LSP-интеграция (Rust, Swift, TypeScript, Python, Terraform и др.)
- Мульти-сессионность с сохранением
- Выполнение команд, поиск файлов, модификация кода
- Client/Server архитектура (можно запускать в Docker удалённо)
- "Workspaces" — сессии, которые живут даже после закрытия терминала

### Поддержка open-source моделей
- **Ollama**: полная интеграция (Qwen3, Llama, DeepSeek, GLM)
- **DeepSeek**: прямая поддержка через API и через Ollama
- **Qwen**: через Ollama и OpenAI-совместимые endpoints
- **Любая OpenAI-совместимая модель**: через настройку провайдера

### MCP поддержка
Да, реализован Model Context Protocol. Расширяемость через внешние MCP-серверы. Экосистема плагинов (oh-my-opencode с 25+ инструментами, 11 специализированными агентами).

### Self-hosting
Полный self-hosting. Написан на Go — один бинарник. Можно запускать в Docker-контейнерах.

### Плюсы для "Second Brain"
- Самый зрелый open-source аналог Claude Code
- Огромное сообщество (100K+ stars, 2.5M пользователей в месяц)
- MCP позволяет подключить Obsidian, YouGile, любые внешние сервисы
- Работает полностью локально с Ollama
- Go-бинарник легко деплоить на VDS

### Минусы для "Second Brain"
- Фокус на кодинге, а не на управлении знаниями
- Нет встроенного RAG/knowledge base
- Нужно самому строить "мозг" через MCP-серверы
- Для полноценного Second Brain нужна доработка

### Уровень зрелости: **Высокий** (production-ready)

---

## 2. Goose (Block / Linux Foundation)

**URL:** https://block.github.io/goose/ | [GitHub](https://github.com/block/goose)
**Что это:** Open-source AI-агент от Block (Square), передан в Linux Foundation
**Лицензия:** Open Source (Linux Foundation AAIF)
**GitHub Stars:** ~27K+

### Ключевые возможности
- CLI + Desktop приложение
- 26+ LLM-провайдеров
- **MCP-native архитектура** — 3000+ MCP серверов в экосистеме
- **Recipes** — переиспользуемые шаблоны поведения агента
- **Scheduler** — автоматизация задач по расписанию
- **Memory** — долгосрочная память между сессиями
- Автономное выполнение: планирование, кодинг, тестирование
- Agent loop (plan -> execute -> iterate)

### Поддержка open-source моделей
- **Ollama**: полная поддержка (есть специальные модели для Goose)
- **DeepSeek**: поддержка через API + специальная Ollama-модель `michaelneale/deepseek-r1-goose` с tool calling
- **26 провайдеров**: Anthropic, Azure, DeepSeek, Google, Groq, Mistral, OpenAI и др.

### MCP поддержка
**Лучшая в классе.** Goose + MCP + AGENTS.md переданы в Linux Foundation Agentic AI Foundation. MCP — ключевой механизм расширения. Поддержка 3000+ готовых MCP-серверов.

### Self-hosting
Полный self-hosting. Работает на локальной машине, VPS, Raspberry Pi.

### Плюсы для "Second Brain"
- **Memory** — помнит контекст между сессиями (критично для Second Brain)
- **Scheduler** — автоматические задачи (обзоры, напоминания, синхронизация)
- **Recipes** — можно создать рецепты для типовых задач Second Brain
- MCP-native — легко подключить Obsidian, Telegram, YouGile
- Linux Foundation — гарантия долгосрочной поддержки
- Desktop + CLI — гибкость использования

### Минусы для "Second Brain"
- Менее зрелый чем OpenCode (меньше stars/коммитов)
- DeepSeek R1 требует специальной модели для tool calling
- Фокус на кодинге, хотя архитектура универсальная

### Уровень зрелости: **Высокий** (поддержка Linux Foundation)

---

## 3. Khoj

**URL:** https://khoj.dev | [GitHub](https://github.com/khoj-ai/khoj)
**Что это:** AI "Second Brain" — именно то, что нужно. Self-hosted персональный AI-ассистент
**Лицензия:** Open Source

### Ключевые возможности
- **Именно "Second Brain"** — создан как AI второй мозг
- Ответы из веба и ваших документов (PDF, markdown, org-mode, Word, Notion)
- **Кастомные агенты** с настраиваемой личностью, инструментами и базами знаний
- Deep research — глубокий анализ тем
- Автоматизации по расписанию
- Персональные рассылки и умные уведомления
- Чтение/запись файлов, выполнение кода в sandbox, браузер
- Доступ через Browser, **Obsidian**, Emacs, Desktop, Phone, WhatsApp

### Поддержка open-source моделей
- **Ollama**: полная поддержка
- **vLLM**: поддержка
- **llama-cpp-server**: поддержка
- Любые OpenAI API-совместимые модели
- GPT, Claude, Gemini, **Llama, Qwen, Mistral** — все поддерживаются

### MCP поддержка
Да. Интеграция с Jira, Linear, Slack и др. через MCP. AI co-worker может использовать MCP-инструменты.

### Self-hosting
**Полный self-hosting.** Docker, bare metal, Raspberry Pi. Не требует облачных сервисов.

### Плюсы для "Second Brain"
- **Единственный инструмент, который СОЗДАН как Second Brain**
- Obsidian плагин — прямая интеграция
- Кастомные агенты — можно создать агентов под разные задачи
- Автоматизации — автоматическая обработка, суммаризация, напоминания
- RAG из коробки — работает с вашими документами
- WhatsApp/Telegram доступ — мобильный интерфейс
- Deep research — глубокий анализ любой темы

### Минусы для "Second Brain"
- Менее мощный для кодинга чем OpenCode/Goose
- Меньше сообщество чем у OpenCode
- Python-based (менее производительный чем Go)
- Не терминальный агент — больше веб-интерфейс

### Уровень зрелости: **Средне-высокий** (активная разработка, стабильный продукт)

---

## 4. OpenHands

**URL:** https://openhands.dev | [GitHub](https://github.com/OpenHands/OpenHands)
**Что это:** Open-source платформа для AI-driven разработки с автономными агентами
**Лицензия:** MIT

### Ключевые возможности
- Автономные кодинг-агенты
- Масштабирование от одной задачи до тысяч параллельных операций
- Software Agent SDK (Python + REST API)
- Ephemeral workspaces в Docker/Kubernetes
- Event-sourced state model с deterministic replay
- Typed tool system с MCP-интеграцией
- Bash, файловые операции, веб-браузинг

### Поддержка open-source моделей
- **Qwen**: явно упоминается как поддерживаемая
- **Devstral**: явно упоминается
- Любые LLM через конфигурацию (проприетарные + open-source)

### MCP поддержка
Да. Typed tool system с MCP-интеграцией в SDK.

### Self-hosting
Полный self-hosting в Docker или Kubernetes с контролем доступа и аудитом.

### Плюсы для "Second Brain"
- SDK для создания собственных агентов
- Docker/K8s изоляция — безопасность
- Event sourcing — полная история действий
- Параллельные агенты — масштабирование

### Минусы для "Second Brain"
- Фокус на software engineering, не на knowledge management
- Более сложная настройка (Docker/K8s)
- Нет встроенного RAG
- Оverkill для персонального Second Brain

### Уровень зрелости: **Высокий** (MIT лицензия, активная разработка)

---

## 5. Aider

**URL:** https://aider.chat | [GitHub](https://github.com/paul-gauthier/aider)
**Что это:** Самый зрелый open-source терминальный AI-кодинг ассистент с Git-интеграцией
**Язык:** Python

### Ключевые возможности
- Терминальный AI pair programmer
- **Git-aware** — понимает структуру репозитория, делает коммиты
- Прямое редактирование файлов
- Поддержка множества моделей
- Бенчмарки кодинга (свои тесты качества моделей)
- Repository map для понимания кодовой базы

### Поддержка open-source моделей
- **DeepSeek R1 & Chat V3**: одни из лучших результатов на бенчмарках Aider
- Ollama для локальных моделей
- Любые OpenAI-совместимые API
- Поддержка десятков моделей

### MCP поддержка
Нет явной MCP-поддержки. Расширяемость через модели и конфигурацию, но не через MCP-протокол.

### Self-hosting
Да. Python-приложение, работает локально. Ollama для полностью офлайн работы.

### Плюсы для "Second Brain"
- Очень зрелый проект (один из первых)
- Отличные бенчмарки с DeepSeek
- Git-интеграция — отслеживание изменений в знаниях
- Простота использования

### Минусы для "Second Brain"
- **Нет MCP** — ограниченная расширяемость
- Только кодинг — нет knowledge management
- Нет агентов, рецептов, автоматизации
- Нет памяти между сессиями

### Уровень зрелости: **Высокий** (один из старейших проектов в категории)

---

## 6. Cline

**URL:** https://cline.bot | [GitHub](https://github.com/cline/cline)
**Что это:** Open-source автономный кодинг-агент для VS Code и CLI
**Установки:** 4M+ | **Лицензия:** Open Source

### Ключевые возможности
- VS Code расширение + CLI
- Plan/Act режимы (планирование и выполнение)
- MCP-интеграция — агент может создавать свои MCP-серверы
- Создание/редактирование файлов, выполнение команд, браузер
- Approval-based workflow (подтверждение каждого действия)
- Полный audit trail

### Поддержка open-source моделей
- Ollama для локальных моделей
- Любой OpenAI-совместимый endpoint
- LM Studio
- Работа офлайн

### MCP поддержка
**Отличная.** Cline может не только использовать MCP-серверы, но и создавать новые. Скажи "add a tool" — и Cline создаст MCP-сервер.

### Self-hosting
Да. VS Code extension + CLI работают локально. Модели через Ollama.

### Плюсы для "Second Brain"
- MCP-интеграция — подключение Obsidian, YouGile и др.
- Plan Mode — стратегическое планирование
- Audit trail — отслеживание всех действий
- IDE-интеграция — удобно для разработки

### Минусы для "Second Brain"
- Привязка к VS Code (основной режим)
- CLI менее зрелый чем VS Code extension
- Фокус на кодинге
- Нет RAG, knowledge base, автоматизаций

### Уровень зрелости: **Высокий** (4M+ установок, активное сообщество)

---

## 7. Gemini CLI (Google)

**URL:** https://github.com/google-gemini/gemini-cli
**Что это:** Open-source CLI AI-агент от Google
**Лицензия:** Apache 2.0

### Ключевые возможности
- Терминальный AI-агент от Google
- ReAct loop (reason + act)
- MCP-серверы (локальные и удалённые)
- FastMCP интеграция для Python MCP-серверов
- Баг-фиксинг, создание фич, тестирование

### Поддержка open-source моделей
- Привязан к **Google Gemini** моделям
- **Ограниченная поддержка** open-source моделей

### MCP поддержка
**Да, отличная.** Встроенная поддержка MCP. FastMCP интеграция. Локальные и удалённые MCP-серверы.

### Self-hosting
CLI работает локально, но модели — через Google API. Не полностью self-hosted.

### Плюсы для "Second Brain"
- Apache 2.0 — можно модифицировать
- Отличная MCP-поддержка
- Google-экосистема

### Минусы для "Second Brain"
- **Привязка к Gemini моделям** — не работает с DeepSeek/Qwen/GLM
- Зависимость от Google API
- Не полностью self-hosted
- Менее гибкий чем OpenCode

### Уровень зрелости: **Средний** (Google backing, но ограниченная гибкость)

---

## 8. PyGPT

**URL:** https://pygpt.net | [GitHub](https://github.com/szczyglis-dev/py-gpt)
**Что это:** Десктопный AI-ассистент "все-в-одном"
**Версия:** 2.7.12 (6 февраля 2026) | **Платформы:** Windows, macOS, Linux

### Ключевые возможности
- **11 режимов**: Chat, Chat with Files, Realtime + audio, Research, Completion, Image/Video generation, Assistants, Experts, Computer use, Agents, Autonomous Mode
- MCP-поддержка (встроенная)
- RAG через LlamaIndex
- Плагины: Files I/O, Code Interpreter, Web Search, Google, Slack, Telegram, GitHub, MCP
- Голосовое управление (speech synthesis + recognition)
- Локальное хранение данных

### Поддержка open-source моделей
- **Ollama**: Llama 3, Mistral, DeepSeek V3/R1, и др.
- HuggingFace модели
- Любые OpenAI-совместимые
- GPT, Claude, Gemini, Grok, Perplexity

### MCP поддержка
Да. Встроенная MCP-поддержка. Remote MCP для xAI и Anthropic.

### Self-hosting
Полный self-hosting. Десктопное приложение. Локальные модели не требуют API ключей.

### Плюсы для "Second Brain"
- **Все-в-одном**: чат, файлы, RAG, агенты, голос, MCP
- Autonomous Mode — агент работает самостоятельно
- Files I/O — работа с файлами (Obsidian vault)
- Telegram плагин — мобильный доступ
- Research mode — исследования
- Локальные модели без API

### Минусы для "Second Brain"
- Desktop-only (нет серверного режима)
- Python — менее производительный
- UI может быть перегруженным
- Не терминальный инструмент
- Один разработчик (risk factor)

### Уровень зрелости: **Средний** (активная разработка, но solo-проект)

---

## 9. Casibase

**URL:** https://www.casibase.org | [GitHub](https://github.com/casibase/casibase)
**Что это:** Enterprise-level AI база знаний + MCP/A2A платформа
**Язык:** Go + React

### Ключевые возможности
- AI Knowledge Base с admin UI
- **MCP (Model Context Protocol)** менеджмент
- **A2A (Agent-to-Agent)** взаимодействие
- SSO и управление пользователями
- Чат-бот интерфейс
- Multi-model поддержка

### Поддержка open-source моделей
- ChatGPT, Claude, **Llama, Ollama**, HuggingFace, **DeepSeek R1**

### MCP поддержка
**Да, центральная фича.** MCP + A2A management platform. StreamableHTTP transport для MCP.

### Self-hosting
Да. Go + React приложение, self-hosted.

### Плюсы для "Second Brain"
- **MCP + A2A менеджмент** — управление агентами и инструментами
- Enterprise-уровень — SSO, пользователи, аудит
- Go backend — производительность
- Можно строить корпоративный Second Brain

### Минусы для "Second Brain"
- Enterprise-фокус (может быть overkill для персонального использования)
- Менее известный проект
- Нет терминального интерфейса
- Требует настройки

### Уровень зрелости: **Средний** (активная разработка, нишевый продукт)

---

## Сравнительная таблица

| Критерий | OpenCode | Goose | Khoj | OpenHands | Aider | Cline | Gemini CLI | PyGPT | Casibase |
|----------|----------|-------|------|-----------|-------|-------|------------|-------|---------|
| **GitHub Stars** | 100K+ | 27K+ | 25K+ | 50K+ | 25K+ | 30K+ | 50K+ | 5K+ | 3K+ |
| **Язык** | Go | Rust | Python | Python | Python | TS | TS | Python | Go+React |
| **MCP** | Да | Отлично | Да | Да | Нет | Отлично | Отлично | Да | Отлично |
| **Ollama** | Да | Да | Да | Частично | Да | Да | Нет | Да | Да |
| **DeepSeek** | Да | Да* | Да | Да | Да | Да | Нет | Да | Да |
| **Qwen** | Да | Да | Да | Да | Да | Да | Нет | Да | Да |
| **Self-hosted** | Да | Да | Да | Да | Да | Да | Частично | Да | Да |
| **RAG** | Нет | Нет | Да | Нет | Нет | Нет | Нет | Да | Да |
| **Knowledge Mgmt** | Нет | Частично | Да | Нет | Нет | Нет | Нет | Частично | Да |
| **Scheduler** | Нет | Да | Да | Нет | Нет | Нет | Нет | Нет | Нет |
| **Memory** | Сессии | Да | Да | Events | Нет | Нет | Нет | Да | Да |
| **Терминал** | Да | Да | Нет | Да | Да | CLI+IDE | Да | Нет | Нет |
| **Desktop** | Нет | Да | Web | Нет | Нет | VS Code | Нет | Да | Web |

*Goose + DeepSeek требует специальной Ollama-модели для tool calling

---

## Рекомендуемая архитектура для "Second Brain" сервиса

### Вариант 1: Минимальный (быстрый старт)
```
Khoj + Ollama (DeepSeek/Qwen) + Obsidian
```
- Khoj как ядро Second Brain
- Ollama для self-hosted моделей
- Obsidian для заметок (есть плагин)
- Минимальная настройка, максимум из коробки

### Вариант 2: Для разработчиков
```
OpenCode + MCP-серверы (Obsidian, YouGile) + Ollama
```
- OpenCode как основной интерфейс
- MCP-серверы для подключения внешних сервисов
- Obsidian MCP Server для управления заметками
- Ollama для self-hosted моделей

### Вариант 3: Максимальный (enterprise)
```
Goose + Khoj + Casibase + Ollama + MCP
```
- Goose как агент-оркестратор (scheduler, recipes, memory)
- Khoj как knowledge base + RAG
- Casibase как MCP/A2A management platform
- Ollama для self-hosted моделей
- MCP для связи всех компонентов

### Вариант 4: Для сервиса клиентам (AGIency.pro)
```
OpenCode/Goose (агент) + Khoj (знания) + n8n (автоматизация) + Ollama
```
- OpenCode или Goose как интерфейс агента
- Khoj для базы знаний каждого клиента
- n8n для автоматизаций и интеграций
- Ollama для self-hosted моделей
- Можно упаковать как услугу

---

## Ключевые выводы

1. **OpenCode — лидер** среди open-source аналогов Claude Code (100K+ stars, Go, 75+ провайдеров)
2. **Khoj — единственный**, кто создан именно как "Second Brain" с AI
3. **Goose — лучший для автоматизации** (scheduler, recipes, memory, Linux Foundation)
4. **MCP — стандарт расширяемости**, поддерживается почти всеми (кроме Aider)
5. **Ollama — ключевой компонент** для self-hosted моделей (DeepSeek, Qwen, GLM-5, Kimi 2.5)
6. **Для AGIents.pro / AGIency.pro** оптимально комбинировать несколько инструментов через MCP

---

## Источники

- [OpenCode](https://opencode.ai/) | [GitHub](https://github.com/opencode-ai/opencode)
- [Goose (Block)](https://block.github.io/goose/) | [GitHub](https://github.com/block/goose)
- [Khoj](https://khoj.dev/) | [GitHub](https://github.com/khoj-ai/khoj)
- [OpenHands](https://openhands.dev/) | [GitHub](https://github.com/OpenHands/OpenHands)
- [Aider](https://aider.chat/)
- [Cline](https://cline.bot/) | [GitHub](https://github.com/cline/cline)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- [PyGPT](https://pygpt.net/) | [GitHub](https://github.com/szczyglis-dev/py-gpt)
- [Casibase](https://www.casibase.org/) | [GitHub](https://github.com/casibase/casibase)
- [Ollama](https://github.com/ollama/ollama)
- [MCP-Obsidian](https://mcp-obsidian.org/)
- [Linux Foundation AAIF](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation)
- [DigitalOcean: Claude Code Alternatives](https://www.digitalocean.com/resources/articles/claude-code-alternatives)
- [InfoQ: OpenCode](https://www.infoq.com/news/2026/02/opencode-coding-agent/)
- [OpenCode vs Claude Code (Builder.io)](https://www.builder.io/blog/opencode-vs-claude-code)
- [OpenCode vs Claude Code (Daniel Miessler)](https://danielmiessler.com/blog/opencode-vs-claude-code)
