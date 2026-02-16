# API Reference: Social Research Skill

## Grok API (X/Twitter)

### Endpoint

```
POST https://api.x.ai/v1/responses
```

### Auth

```
Authorization: Bearer $XAI_API_KEY
```

### Model

`grok-4-1-fast` — $0.20/1M input, $0.50/1M output, $0.005 per x_search call

### Поиск по теме

```bash
curl -s -X POST "https://api.x.ai/v1/responses" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $XAI_API_KEY" \
  -d '{
    "model": "grok-4-1-fast",
    "tools": [{
      "type": "x_search",
      "x_search": {
        "from_date": "2026-02-08",
        "to_date": "2026-02-15"
      }
    }],
    "input": [{"role": "user", "content": "PROMPT_HERE"}]
  }'
```

### Поиск по конкретным аккаунтам

```bash
curl -s -X POST "https://api.x.ai/v1/responses" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $XAI_API_KEY" \
  -d '{
    "model": "grok-4-1-fast",
    "tools": [{
      "type": "x_search",
      "x_search": {
        "allowed_x_handles": ["handle1", "handle2"],
        "from_date": "2026-02-08",
        "to_date": "2026-02-15"
      }
    }],
    "input": [{"role": "user", "content": "PROMPT_HERE"}]
  }'
```

### x_search параметры

| Параметр | Тип | Описание | Лимит |
|----------|-----|----------|-------|
| `allowed_x_handles` | array | Только эти аккаунты | Max 10 |
| `excluded_x_handles` | array | Исключить аккаунты | Max 10 |
| `from_date` | string | Начало периода (ISO8601: `YYYY-MM-DD`) | - |
| `to_date` | string | Конец периода (ISO8601: `YYYY-MM-DD`) | Включительно |

### jq парсинг ответа Grok

```bash
# Извлечь текст ответа
... | jq -r '.output[] | select(.type == "message") | .content[] | select(.type == "text") | .text'

# Извлечь URL цитаты
... | jq -r '.output[] | select(.type == "message") | .content[] | select(.type == "text") | .annotations[]? | select(.type == "url_citation") | .url'
```

### Rate Limits

- grok-4-1-fast: 4M tokens/min throughput
- Context window: 2M tokens

---

## OpenAI API (Reddit)

### Endpoint

```
POST https://api.openai.com/v1/responses
```

### Auth

```
Authorization: Bearer $OPENAI_API_KEY
```

### Model

`gpt-4o-mini` — $0.15/1M input, $0.60/1M output, $0.01 per web_search call

### Поиск по теме на Reddit

```bash
curl -s -X POST "https://api.openai.com/v1/responses" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "gpt-4o-mini",
    "tools": [{
      "type": "web_search_preview",
      "search_context_size": "medium"
    }],
    "include": ["web_search_call.action.sources"],
    "input": "PROMPT_HERE"
  }'
```

### web_search_preview параметры

| Параметр | Описание |
|----------|----------|
| `search_context_size` | `"low"` / `"medium"` (default) / `"high"` |
| `user_location.country` | ISO 2-letter код страны |

### Таргетирование Reddit

Фильтрация через промпт: добавлять `site:reddit.com` в запрос.

Для конкретных сабреддитов: `site:reddit.com/r/subreddit_name`

### jq парсинг ответа OpenAI

```bash
# Извлечь текст ответа
... | jq -r '.output[] | select(.type == "message") | .content[] | select(.type == "output_text") | .text'

# Извлечь URL цитаты
... | jq -r '.output[] | select(.type == "message") | .content[] | .annotations[]? | select(.type == "url_citation") | .url'
```

---

## Промпт-шаблоны

### Для X/Twitter (тема)

```
Search X/Twitter for posts about [TOPIC] from the last [PERIOD]. Find the most insightful, popular, and relevant posts.

For each notable post include:
- Author handle (@username)
- Key quote or summary of the post
- Why it's notable (engagement, expertise, unique perspective)

Focus on:
- Expert opinions and practitioners
- Substantial discussions, not promotional content
- Diverse viewpoints

Summarize in Russian. Keep technical terms in English.
Provide links to the most important posts.
```

### Для X/Twitter (аккаунты)

```
Find and summarize recent posts from the following X/Twitter accounts: [HANDLES].

For each account:
- List their key posts from the last [PERIOD]
- Summarize main themes and positions
- Highlight the most engaging posts

Summarize in Russian. Keep technical terms in English.
```

### Для Reddit (тема)

```
site:reddit.com [TOPIC]

Search Reddit for the most upvoted and insightful discussions about [TOPIC].

For each discussion include:
- Subreddit name (r/...)
- Post title
- Summary of the post and top comments
- Key practical advice or consensus
- Link to the post

Focus on:
- Practical advice and real experiences
- Highly upvoted responses
- Expert opinions in comments

Summarize in Russian. Keep technical terms in English.
```

### Для Reddit (сабреддиты)

```
site:reddit.com/r/[SUBREDDIT] [TOPIC]

Search r/[SUBREDDIT] for recent discussions about [TOPIC].

For each post:
- Title and link
- Summary of post content
- Top 2-3 comments with practical value
- Community consensus

Summarize in Russian. Keep technical terms in English.
```

---

## Обработка ошибок

| HTTP код | Причина | Действие |
|----------|---------|----------|
| 401 | Невалидный API ключ | Сообщить, перейти к другой платформе |
| 429 | Rate limit | Подождать 60 сек, retry |
| 500/502/503 | Ошибка сервера | Retry 1 раз |
| Timeout | Сервер не отвечает | `--max-time 60` в curl |

## Стоимость за вызов

| Платформа | Search call | Tokens (input) | Tokens (output) | ~Стоимость за запрос |
|-----------|------------|-----------------|------------------|---------------------|
| X (Grok) | $0.005 | $0.20/1M | $0.50/1M | ~$0.01-0.02 |
| Reddit (OpenAI) | $0.01 | $0.15/1M | $0.60/1M | ~$0.01-0.03 |
