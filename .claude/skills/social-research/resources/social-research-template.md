# Social Research Template

Шаблон для сохранения результатов social research в vault.

## Frontmatter

```yaml
---
type: social-research
date: YYYY-MM-DD
topic: "[Тема поиска]"
platforms: [x-twitter, reddit]
search_params:
  x_handles: [handle1, handle2]
  subreddits: [sub1, sub2]
  from_date: YYYY-MM-DD
  to_date: YYYY-MM-DD
tags: [social-research, тег1, тег2]
projects: [[связанный проект]]
---
```

## Шаблон документа

```markdown
# Social Research: [Topic]

**Дата исследования:** YYYY-MM-DD
**Платформы:** X/Twitter, Reddit
**Период:** [from_date] — [to_date]

## Краткое резюме

[2-3 предложения: что обсуждают, общий тон, ключевые точки зрения]

---

## X/Twitter

### Ключевые голоса

1. **@handle1** — [краткое резюме позиции]
   > [Notable quote or paraphrase]

2. **@handle2** — [краткое резюме позиции]
   > [Notable quote or paraphrase]

### Основные темы обсуждения

- **Тема 1** — [описание с конкретикой]
- **Тема 2** — [описание с конкретикой]

### Тональность

[Общее настроение: позитивное/негативное/смешанное, с примерами]

### Источники X

- [Описание поста](URL1)
- [Описание поста](URL2)

---

## Reddit

### Топ обсуждения

#### 1. [Название поста] (r/subreddit)

**Суть:** [о чём пост]
**Consensus:** [мнение большинства]
**Лучший комментарий:** [резюме самого полезного комментария]

#### 2. [Название поста] (r/subreddit)

**Суть:** [о чём пост]
**Consensus:** [мнение большинства]
**Лучший комментарий:** [резюме]

### Практические советы из обсуждений

- [Совет 1 с контекстом]
- [Совет 2 с контекстом]
- [Совет 3 с контекстом]

### Источники Reddit

- [Название обсуждения](URL1)
- [Название обсуждения](URL2)

---

## Кросс-платформенный анализ

### Общие паттерны

1. **[Паттерн 1]** — встречается на обеих платформах
2. **[Паттерн 2]** — встречается на обеих платформах

### Разногласия

- **X говорит:** [позиция]
- **Reddit говорит:** [позиция]

---

## Применимость

**Для проектов:**
- [[Project 1]] — [как применить инсайты]
- [[Project 2]] — [как применить инсайты]

---

## Заметки

[Личные мысли, идеи, вопросы для дальнейшего изучения]

---

*Исследование: social-research skill*
*Источники: Grok API (X/Twitter) + OpenAI web_search (Reddit)*
*AI-синтезированный анализ, не прямые цитаты*
```

## Шаблон для одной платформы (X only)

```markdown
# X Research: [Topic]

**Дата:** YYYY-MM-DD
**Период:** [from_date] — [to_date]
**Аккаунты:** [если указаны]

## Краткое резюме

[2-3 предложения]

## Ключевые голоса

[см. секцию X/Twitter выше]

## Основные темы

[темы]

## Источники

[ссылки]

---

*Источник: Grok API (x_search)*
```

## Шаблон для одной платформы (Reddit only)

```markdown
# Reddit Research: [Topic]

**Дата:** YYYY-MM-DD
**Сабреддиты:** [если указаны]

## Краткое резюме

[2-3 предложения]

## Топ обсуждения

[см. секцию Reddit выше]

## Практические советы

[советы]

## Источники

[ссылки]

---

*Источник: OpenAI web_search (reddit.com)*
```

## Naming Convention

- Обе платформы: `YYYY-MM-DD - [Topic] - Social Research.md`
- Только X: `YYYY-MM-DD - [Topic] - X Research.md`
- Только Reddit: `YYYY-MM-DD - [Topic] - Reddit Research.md`

## Save Paths

- По умолчанию: `03_Resources/Social Research/`
- AGIents.pro: `01_Projects/AGIents.pro - ИИ-агенты платформа/Research/`
- Clario: `01_Projects/Clario - ИИ-аналитика продаж/Research/`
- AISobolev блог: `01_Projects/AISobolev - блог buildinpublic/Research/`
- Общее: `03_Resources/Social Research/`