---
name: ingest
description: |
  Обработка входящих материалов из 000_Inbox/ — чтение, анализ, обсуждение с пользователем,
  создание страниц в нужных секциях, обновление index.md и log.md.
  Use when: пользователь хочет обработать материал из Inbox.
  Triggers: "ingest", "обработай инбокс", "процесс inbox", "разбери входящие", "обработай"
---

# Ingest — обработка входящих материалов

Формализованный процесс обработки материалов из `000_Inbox/` по паттерну LLM Wiki.

## When to Use This Skill

- Пользователь просит обработать файл из Inbox
- Пользователь говорит "ingest", "обработай", "разбери inbox"
- Пользователь скинул материал и хочет его интегрировать в хранилище

## Arguments

- `$ARGUMENTS` — имя файла в `000_Inbox/` (опционально). Если не указан — показать список.

## Workflow

### Step 1: Scan Inbox

1. Прочитать содержимое `000_Inbox/` (исключая README.md)
2. Если `$ARGUMENTS` указан — использовать этот файл
3. Если нет — показать список файлов и спросить пользователя какой обработать

### Step 2: Read & Analyze

1. Прочитать source файл полностью
2. Определить:
   - **Тип контента**: article, idea, research, note, transcript, tool-description
   - **Ключевые сущности**: люди, компании, технологии, фреймворки
   - **Ключевые концепции**: паттерны, методики, подходы
   - **Связанные проекты**: AGIency, AGIents, Clario, MicroSaaS (если есть)
   - **Связанные существующие страницы** в vault (проверить через `index.md`)

### Step 3: Discuss with User

Показать пользователю:

```
📄 **Файл:** <filename>
📋 **Тип:** <detected type>
🎯 **Ключевые takeaways:**
1. <takeaway 1>
2. <takeaway 2>
3. <takeaway 3>
4. <takeaway 4>
5. <takeaway 5>

📁 **Предлагаемое место:** <destination path>
🔗 **Связанные страницы:** [[page1]], [[page2]]

Согласен с направлением? Хочешь что-то изменить?
```

Дождаться ответа пользователя перед продолжением.

### Step 4: Determine Destination

Маршрутизация по типу контента:

| Тип контента | Destination | Document type |
|-------------|-------------|---------------|
| Исследование/статья AI | `500_Research/550_AI/` | `research` |
| Исследование бизнес-моделей | `500_Research/560_Business_Models/` | `research` |
| CustDev материал | `500_Research/570_CustDev/` | `research` |
| Веб-исследование | `500_Research/580_Web_Research/` | `research` |
| Анализ/синтез | `500_Research/590_Analysis/` | `analysis` |
| Идея контента | `300_Blog/310_Content_Ideas/` | `content-idea` |
| Проектный документ | `200_Projects/{project}/` | `project-doc` |
| Транскрипция | `500_Research/540_Transcriptions/` | `transcription` |
| YouTube выжимка | `500_Research/530_YouTube/` | `youtube-summary` |
| Общая заметка | по контексту | `note` |

### Step 5: Create Wiki Page

1. Создать файл в destination с правильным именованием (см. `000_Inbox/README.md` для формата)
2. Добавить YAML frontmatter по правилам CLAUDE.md:

```yaml
---
type: <document type из Step 4>
date: <today YYYY-MM-DD>
source: <url если есть>
author: <автор если есть>
project: <проект если есть>
status: active
tags: [<relevant tags>]
---
```

3. Написать содержание:
   - Заголовок h1
   - Краткое описание (1-2 предложения)
   - Основное содержание (структурированная выжимка, не копия)
   - Ключевые выводы / применение к нашим проектам

4. Добавить в конце:

```markdown
---

## Связанные документы

- [[Документ 1]] — пояснение связи
- [[Документ 2]] — пояснение связи
```

### Step 6: Update Entity/Concept Pages (if applicable)

Если source вводит новые сущности или концепции, упомянутые в 3+ файлах vault:
- Создать или обновить dedicated pages в соответствующей секции
- Добавить cross-references

### Step 7: Update index.md

Добавить запись для нового файла в `index.md` в правильной секции:

```markdown
- [[Title]](relative/path.md) — one-line summary на русском
```

### Step 8: Update log.md

Добавить запись в `log.md`:

```markdown
## [YYYY-MM-DD] ingest | <Title>
- Source: 000_Inbox/<filename>
- Destination: <path>
- Files created: <list>
- Files updated: <list>
```

### Step 9: Clean Up Inbox

Спросить пользователя:
- **Удалить** source из `000_Inbox/`?
- **Оставить** (если нужен оригинал)?

### Step 10: Verification

Проверить:
- [ ] Файл создан с правильным frontmatter
- [ ] Секция "Связанные документы" присутствует
- [ ] Запись добавлена в `index.md`
- [ ] Запись добавлена в `log.md`
- [ ] Source обработан (удалён или помечен)
