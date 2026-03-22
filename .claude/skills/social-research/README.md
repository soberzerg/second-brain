# Social Research Skill

Поиск и анализ контента из X/Twitter и Reddit: мнения экспертов, обсуждения, тренды.

## Возможности

- 🐦 **X/Twitter поиск** — посты по теме или от конкретных аккаунтов (Grok API)
- 🤖 **Reddit поиск** — обсуждения по теме или в конкретных сабреддитах (OpenAI API)
- 🔄 **Кросс-платформенный анализ** — сравнение мнений на обеих платформах
- 💾 **Сохранение в vault** — структурированные markdown заметки

## Быстрый старт

### Поиск по теме

```text
Что говорят про AI agents в X и Reddit?
```

### Поиск по аккаунтам

```text
Что пишет @AnthropicAI в X за последний месяц?
```

### Поиск на Reddit

```text
Посмотри r/artificial про no-code AI platforms
```

### Для блога

```text
Социальный ресерч по теме "Claude Code" для поста
```

## Используемые API

### Grok API (X/Twitter)

- **Endpoint:** `https://api.x.ai/v1/responses`
- **Model:** `grok-4-1-fast`
- **Tool:** `x_search`
- **Auth:** `$XAI_API_KEY`
- **Стоимость:** ~$0.01-0.02 за запрос

### OpenAI API (Reddit)

- **Endpoint:** `https://api.openai.com/v1/responses`
- **Model:** `gpt-4o-mini`
- **Tool:** `web_search_preview` (domain filter: reddit.com)
- **Auth:** `$OPENAI_API_KEY`
- **Стоимость:** ~$0.01-0.03 за запрос

## Паттерны активации

Навык активируется автоматически при:

- "Что пишут в твиттере про ..."
- "Найди в X посты про ..."
- "Что обсуждают на реддите ..."
- "Посмотри r/... про ..."
- "Что пишет @... в X"
- "Социальный ресерч по ..."

## Сохранение результатов

### Пути

- **По умолчанию:** `500_Research/520_Social_Research/`
- **Проектные:** `200_Projects/[Проект]/Research/`

### Naming Convention

```text
YYYY-MM-DD - [Topic] - Social Research.md    # обе платформы
YYYY-MM-DD - [Topic] - X Research.md          # только X
YYYY-MM-DD - [Topic] - Reddit Research.md     # только Reddit
```

## Требования

- `$XAI_API_KEY` — API ключ от x.ai (для X/Twitter)
- `$OPENAI_API_KEY` — API ключ от OpenAI (для Reddit)
- `jq` — для парсинга JSON ответов
- Permission: `Bash(curl -s:*)` в settings.local.json

## Интеграция с другими навыками

- **post-writing** — создать пост на основе ресерча
- **brainstorming** — обсудить найденные тренды
- **web-research** — дополнить глубоким веб-исследованием
- **daily-review** — включить ресерчи в обзор дня

## Структура файлов

```text
.claude/skills/social-research/
├── SKILL.md                          # Основная конфигурация
├── README.md                         # Этот файл
└── resources/
    ├── api-reference.md              # curl шаблоны и jq парсинг
    └── social-research-template.md   # Шаблон сохранения
```

## FAQ

### Какие данные возвращают API?

Оба API возвращают AI-синтезированные саммари с цитатами (ссылками на оригиналы), а не raw посты. Это означает что контент обработан моделью и может быть неточным.

### Можно ли фильтровать по дате?

- **X/Twitter:** да, через `from_date` / `to_date` (ISO8601)
- **Reddit:** через промпт (менее точно)

### Что если один API недоступен?

Навык продолжит работу с другой платформой и сообщит об ошибке.

---

**Создано:** 2026-02-15
**Версия:** 1.0.0
**Инструменты:** Grok API + OpenAI Responses API