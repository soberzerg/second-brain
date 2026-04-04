---
name: social-research
description: Поиск и анализ контента из X/Twitter и Reddit - мнения, обсуждения, тренды по теме. Использует x-search MCP server для X и OpenAI web_search для Reddit. Triggers: "search X", "get post from X", "search Reddit", "get post from Reddit", "social research on [topic]".
---

# Social Research Skill

## Workflow

### 1. **Определение параметров поиска**

Из сообщения пользователя определить:

- **Платформа**: X/Twitter, Reddit, или обе
- **Тип поиска**: по теме или по аккаунтам/сабреддитам
- **Период**: default 7 дней
- **Конкретные аккаунты/сабреддиты**: если указаны

Если критическая информация отсутствует (тема не понятна) — задать один уточняющий вопрос. Иначе использовать smart defaults.

### 2. **Выполнение поиска**

- X/Twitter: вызвать `mcp__x-search__x_search` или `mcp__x-search__x_get_post` MCP tool
- Reddit: curl к OpenAI API с `web_search_preview` tool (через Bash)
- При параллельном поиске по обеим платформам — запускать оба запроса

### 3. **Обработка результатов**

- X/Twitter: MCP tool возвращает готовый markdown с текстом и источниками
- Reddit: извлечь текст и цитаты из JSON ответов через jq
- Если одна платформа вернула ошибку — продолжить с другой

### 5. **Сохранение в vault**

- Сформировать markdown по шаблону из `resources/social-research-template.md`
- Сохранить в правильную директорию

### 6. **Подтверждение**

- Показать краткое резюме, количество источников
- Предложить следующие шаги

## Instructions

### Core Principles

- **x-search MCP server** для X/Twitter — нативные tools `mcp__x-search__x_search` и `mcp__x-search__x_get_post`
- **OpenAI API** для Reddit — через `curl` к `https://api.openai.com/v1/responses`
- API ключи: `XAI_API_KEY` в `.mcp.json`, `$OPENAI_API_KEY` (environment variable)
- Оба API возвращают **AI-синтезированные саммари** с цитатами, НЕ сырые посты
- Всегда указывать в файле что это AI-синтезированный анализ
- Результаты на русском, технические термины на английском

### Platform Selection

| Платформа | Когда использовать                                                     |
| --------- | ---------------------------------------------------------------------- |
| X/Twitter | Мнения экспертов, тренды, быстрые реакции, конкретные аккаунты         |
| Reddit    | Глубокие обсуждения, сравнения, практический опыт, community consensus |
| Обе       | Комплексный анализ мнений по теме (default)                            |

### Smart Defaults

- Период: последние 7 дней
- Платформа: обе (если не указано иное)
- Язык поиска: английский (больше контента)
- Язык вывода: русский
- Сохранение: `500_Research/520_Social_Research/`

### API Call Execution

#### X/Twitter — x-search MCP server

**Поиск по теме:**

Использовать `mcp__x-search__x_search` с параметрами:
- `query` (required) — тема поиска
- `from_date` / `to_date` (optional) — период в формате YYYY-MM-DD (default: последние 7 дней)
- `allowed_handles` (optional) — список аккаунтов без @ (max 10)
- `excluded_handles` (optional) — исключить аккаунтов без @ (max 10)

**Получить конкретный пост:**

Использовать `mcp__x-search__x_get_post` с параметром:
- `url` (required) — полный URL поста (например `https://x.com/username/status/123`)

**Преимущества перед curl:**
- Нет необходимости в bash/jq парсинге
- Автоматические date defaults (последние 7 дней)
- Структурированный markdown ответ с источниками
- Встроенная обработка ошибок (401, 429, 5xx)

#### Reddit — OpenAI API

**Поиск по теме:**

```bash
curl -s -X POST "https://api.openai.com/v1/responses" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  --max-time 60 \
  -d '{
    "model": "gpt-4o-mini",
    "tools": [{
      "type": "web_search_preview",
      "search_context_size": "medium"
    }],
    "include": ["web_search_call.action.sources"],
    "input": "[SEARCH_PROMPT]"
  }'
```

**Промпт-шаблон для Reddit:**

```
site:reddit.com [TOPIC]

Search Reddit for the most upvoted and insightful discussions about [TOPIC].

For each discussion include:
- Subreddit name (r/...)
- Post title
- Summary of the post and top comments
- Key practical advice or consensus
- Link to the post

Focus on practical advice, real experiences, and highly upvoted responses.
Summarize in Russian. Keep technical terms in English.
```

**Для конкретных сабреддитов:**

```
site:reddit.com/r/[SUBREDDIT] [TOPIC]
```

**jq парсинг ответа:**

```bash
# Текст ответа
... | jq -r '.output[] | select(.type == "message") | .content[] | select(.type == "output_text") | .text'

# URL цитаты
... | jq -r '.output[] | select(.type == "message") | .content[] | .annotations[]? | select(.type == "url_citation") | .url'
```

### Save Paths

Определять по контексту темы:

- **AGIents.pro** (AI agents, no-code, платформы) → `200_Projects/220_AGIents/Research/`
- **Clario** (аналитика продаж, B2B analytics) → `200_Projects/230_Clario/Research/`
- **AISobolev блог** (материал для поста) → `300_Blog/330_Research/`
- **Общее** → `500_Research/520_Social_Research/`

### File Naming

- Обе платформы: `YYYY-MM-DD - [Topic] - Social Research.md`
- Только X: `YYYY-MM-DD - [Topic] - X Research.md`
- Только Reddit: `YYYY-MM-DD - [Topic] - Reddit Research.md`

### Response Formatting

#### В процессе

```markdown
🔍 Ищу в X/Twitter и Reddit по теме "[тема]"...
⏳ Период: [from] — [to]
```

#### Успешное завершение

```markdown
✅ Social Research завершён!

**"[Тема]"**
📁 Файл: [путь к файлу](путь к файлу)
🐦 X/Twitter: [X] источников
🤖 Reddit: [Y] обсуждений
📅 Период: [from] — [to]

## Ключевые находки

1. [Находка 1]
2. [Находка 2]
3. [Находка 3]

Хочешь написать пост на основе этих данных? Или углубиться в конкретную тему?
```

#### Частичный успех

```markdown
⚠️ Частичные результаты

✅ X/Twitter: найдено [X] источников
❌ Reddit: [описание ошибки]

📁 Файл: [путь](путь)

Результаты X/Twitter сохранены. Reddit можно попробовать позже.
```

### Edge Cases

#### API ключ отсутствует

```markdown
❌ API ключ не найден

$XAI_API_KEY не установлен. Для поиска в X/Twitter нужен ключ от x.ai.
$OPENAI_API_KEY не установлен. Для поиска в Reddit нужен ключ от OpenAI.

Установи через: export XAI_API_KEY="your-key"

Могу продолжить с [другая платформа] или использовать web-research skill через Firecrawl.
```

#### Пустые результаты

```markdown
🤷 Не найдено обсуждений по "[тема]" на [платформа]

Попробуй:

1. Расширить временной период (30 дней вместо 7)
2. Использовать другие ключевые слова
3. Поискать на английском
4. Убрать фильтр по аккаунтам/сабреддитам
```

#### Rate Limit

```markdown
⏳ Rate limit от [платформа] API

Подожду и попробую снова через минуту...
```

#### Оба API недоступны

```markdown
❌ Оба API недоступны

Альтернатива: могу использовать web-research skill (Firecrawl) для поиска обсуждений через веб.
```

### Tone & Style

- **Автоматизм**: Минимум вопросов, сразу к делу
- **Прозрачность**: Показывать что делаешь в процессе
- **Проактивность**: Предлагать следующие шаги (написать пост, углубиться)
- **Честность**: Всегда указывать что это AI-синтезированный анализ

**Избегать:**

- ❌ "Какую платформу использовать?" (определи сам из контекста)
- ❌ Показывать raw JSON или технические детали curl
- ❌ Спрашивать куда сохранить если контекст очевиден

**Предпочитать:**

- ✅ "🔍 Ищу в X и Reddit..." (сразу к делу)
- ✅ "✅ Найдено 8 источников" (конкретно)
- ✅ "Написать пост на основе этих данных?" (проактивно)

## Resources

- [Social Research Template](resources/social-research-template.md) — шаблон для сохранения
- [API Reference](resources/api-reference.md) — curl команды и jq парсинг

## Integration with other skills

- **post-writing**: Создать пост на основе социального ресерча
- **brainstorming**: Обсудить тренды и мнения из соцсетей
- **web-research**: Дополнить глубоким веб-исследованием
- **daily-review**: Включить проведённые ресерчи в обзор дня
- **content-strategy**: Использовать инсайты для планирования контента

## Examples

### Example 1: Поиск по теме в обеих платформах

**User:**

```text
Что говорят про AI agents в X и Reddit?
```

**Claude Response:**

```markdown
🔍 Ищу в X/Twitter и Reddit по теме "AI agents"...
⏳ Период: 2026-02-08 — 2026-02-15

[... выполнение curl запросов ...]

✅ Social Research завершён!

**"AI Agents"**
📁 Файл: [500_Research/520_Social_Research/2026-02-15 - AI Agents - Social Research.md](500_Research/520_Social_Research/2026-02-15 - AI Agents - Social Research.md)
🐦 X/Twitter: 6 источников
🤖 Reddit: 4 обсуждения
📅 Период: 2026-02-08 — 2026-02-15

## Ключевые находки

1. Тренд на multi-agent системы — обсуждается и в X и на Reddit
2. MCP protocol становится стандартом для интеграций
3. Reddit отмечает проблемы с production deployment

Написать пост на основе этих данных?
```

### Example 2: Поиск по конкретным аккаунтам в X

**User:**

```text
Что пишет @AnthropicAI и @OpenAI в X за последний месяц?
```

**Claude Response:**

```markdown
🔍 Ищу посты @AnthropicAI и @OpenAI в X...
⏳ Период: 2026-01-15 — 2026-02-15

[... curl с allowed_x_handles ...]

✅ X Research завершён!

**"Anthropic & OpenAI Updates"**
📁 Файл: [500_Research/520_Social_Research/2026-02-15 - Anthropic & OpenAI Updates - X Research.md](...)
🐦 Источников: 12

## Ключевые находки

1. @AnthropicAI: фокус на Claude MCP и safety research
2. @OpenAI: анонсы GPT-4.1 и Responses API
3. Общий тренд: оба фокусируются на tool use и agents

Углубиться в какую-то из тем?
```

### Example 3: Поиск на Reddit по сабреддиту

**User:**

```text
Посмотри что обсуждают на r/artificial про no-code AI platforms
```

**Claude Response:**

```markdown
🔍 Ищу на r/artificial обсуждения "no-code AI platforms"...

[... curl к OpenAI с site:reddit.com/r/artificial ...]

✅ Reddit Research завершён!

**"No-code AI Platforms"**
📁 Файл: [200_Projects/220_AGIents/Research/2026-02-15 - No-code AI Platforms - Reddit Research.md](...)
🤖 Обсуждений: 5

## Ключевые находки

1. Наиболее обсуждаемые: Flowise, Relevance AI, n8n
2. Основная критика: ограниченная кастомизация
3. Запрос от сообщества: self-hosted решения

Это релевантно для AGIents.pro — хочешь обсудить позиционирование?
```

### Example 4: Комбинированный запрос для блога

**User:**

```text
Социальный ресерч по теме "Claude Code" для поста в блог
```

**Claude Response:**

```markdown
🔍 Ищу в X/Twitter и Reddit по теме "Claude Code"...
⏳ Период: 2026-02-08 — 2026-02-15

[... оба API запроса ...]

✅ Social Research завершён!

**"Claude Code"**
📁 Файл: [300_Blog/330_Research/2026-02-15 - Claude Code - Social Research.md](...)
🐦 X/Twitter: 8 источников
🤖 Reddit: 3 обсуждения

## Ключевые находки

1. X: разработчики делятся workflows и хаками
2. Reddit: сравнения с Cursor и Copilot
3. Общий тон: восторженный, но с нюансами по pricing

Написать пост на основе этих данных?
```

---

## Notes

- X/Twitter: используется `mcp__x-search` MCP server — curl не требуется
- Reddit: используется `curl` через Bash tool — нужен permission `Bash(curl -s:*)`
- Стоимость: ~$0.01-0.03 за запрос к каждой платформе
- API возвращают AI-саммари, не raw данные — всегда указывать это в выходном файле
- Модели: `grok-4-1-fast` (X) и `gpt-4o-mini` (Reddit) — оптимальные по цене/качеству
- При недоступности одной платформы — продолжать с другой
