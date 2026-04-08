---
type: research
date: 2026-04-08
source: https://github.com/tobi/llm-wiki
author: Tobi Lütke
status: active
tags: [llm-wiki, knowledge-base, obsidian, second-brain, rag-alternative]
---

# LLM Wiki — паттерн персональной базы знаний

Паттерн построения персональных вики с помощью LLM: инкрементальная компиляция знаний вместо RAG.

## Ключевая идея

Вместо RAG (retrieve → generate на каждый запрос) LLM **инкрементально строит и поддерживает persistent wiki** — структурированную коллекцию markdown-файлов. Знания компилируются один раз и обновляются при поступлении новых источников, а не пересоздаются при каждом запросе.

> "The wiki is a persistent, compounding artifact. The cross-references are already there. The contradictions have already been flagged."

## Архитектура (3 слоя)

| Слой | Назначение | Кто владеет | У нас |
| ---- | ---------- | ----------- | ----- |
| **Raw Sources** | Исходные документы (immutable) | Человек | `000_Inbox/`, клипы, транскрипции |
| **Wiki** | Структурированные markdown-страницы | LLM | `100-500_*` директории |
| **Schema** | Конвенции, workflows, структура | Человек + LLM | `CLAUDE.md` |

## Операции

### Ingest
Новый источник → LLM читает → обсуждает → создаёт summary → обновляет entity/concept pages → обновляет index → пишет в log. Один источник может затронуть 10-15 страниц wiki.

### Query → Wiki
Ответы на запросы не исчезают в чат-историю — ценные анализы сохраняются обратно в wiki как новые страницы. Исследования компаундятся.

### Lint
Периодическая проверка здоровья: противоречия, устаревшие данные, orphan pages, missing cross-references, пробелы в знаниях.

## Навигация

- **index.md** — content-oriented каталог всех страниц с one-line summary. LLM читает его первым для ориентации.
- **log.md** — хронологический append-only лог операций. Grep-parseable формат.

## Почему это работает

Люди бросают вики, потому что **maintenance burden растёт быстрее value**. LLM не устаёт, не забывает обновить cross-reference и может затронуть 15 файлов за один проход. Стоимость maintenance → ~0.

Человек отвечает за: curation источников, направление анализа, правильные вопросы, осмысление.
LLM отвечает за: summarizing, cross-referencing, filing, bookkeeping.

## Применение к нашему Second Brain

Мы реализовали этот паттерн 2026-04-08:

- `index.md` — навигационный индекс (~200 записей)
- `log.md` — операционный лог
- `/ingest` skill — формализованный процесс обработки Inbox
- `/wiki-lint` skill — health check хранилища
- `590_Analysis/` — сохранение результатов анализа из сессий
- Wiki Bookkeeping — финальный шаг во всех content-creating skills

---

## Связанные документы

- [[Claude Code as Embedded OS - Gur Sannikov]] — концепция Claude Code как операционной системы
- [[Субагенты для Second Brain - рекомендации]] — архитектура субагентов для Obsidian vault
- [[Как построить Второй мозг с ИИ в 2026 году]] — YouTube выжимка на тему Second Brain с ИИ
