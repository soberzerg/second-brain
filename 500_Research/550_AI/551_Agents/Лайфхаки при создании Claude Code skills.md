---
type: research
date: 2026-04-28
source: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
project: AGIents
status: active
tags: [claude-code, skills, prompt-engineering, agent-design, best-practices, anthropic]
---

# 20 лайфхаков при создании Claude Code skills

> Конденсированный чеклист по созданию качественных Agent Skills, основанный на официальной документации Anthropic (Skill authoring best practices + Agent Skills overview). Применимо к Claude Code, Claude.ai, Claude API.

## Зачем skills вообще

Skill = модульная capability, упаковывающая инструкции, metadata и optional resources для конкретной задачи. Дают **domain-specific workflows**, контекст и best practices, не заменяют system prompt. Загружаются по триггеру через `name` + `description`.

**Архитектура трёх уровней:**

1. **Metadata** (frontmatter) — загружается всегда
2. **`SKILL.md`** — загружается, когда skill сработал
3. **Reference files / scripts** — загружаются по необходимости

## 20 правил

### 1. Skill короткий — не пиши то, что модель и так знает

После загрузки skill **каждый токен конкурирует** с историей диалога. Не объясняй "что такое PDF", "что такое JSON", "как работает API".

❌ "PDF — это формат документов..."
✅ "Use pdfplumber for text extraction. For scanned PDFs, use OCR fallback."

### 2. `description` = "что делает" + "когда использовать"

Главный механизм выбора skill из набора. Anthropic явно требует включать **триггеры применения**.

```yaml
---
name: generating-client-proposals
description: Creates structured commercial proposals for AI automation projects. Use when the user asks to prepare, rewrite, price, or structure a client proposal, КП, estimate, or scope of work.
---
```

### 3. Имена конкретные, без `helper/utils/documents`

Naming conventions: gerund-form (`processing-pdfs`, `analyzing-spreadsheets`, `testing-code`) или action-oriented.

❌ `helper`, `utils`, `tools`, `documents`, `data`, `files`
✅ `writing-client-proposals`

### 4. Один skill — один повторяемый workflow

Не "всё подряд".

❌ `business-automation`
✅ `qualifying-hotel-ai-assistant-leads`, `writing-ai-automation-proposals`, `moderating-hotel-knowledge-base`

### 5. Progressive disclosure: SKILL.md как оглавление, детали — в reference

```text
hotel-kb-moderation/
├── SKILL.md
├── references/
│   ├── room-rules.md
│   ├── treatment-programs.md
│   └── escalation-rules.md
└── scripts/
    └── validate_kb.py
```

### 6. Глубина ссылок — один уровень от SKILL.md

Если reference ссылается на reference, Claude может **не дочитать**.

❌ `SKILL.md → advanced.md → details.md`
✅ `SKILL.md → advanced.md`, `SKILL.md → details.md`, `SKILL.md → examples.md`

### 7. Workflow по шагам, не абстракция

OpenAI и Anthropic сходятся: smaller, clearer steps снижают неоднозначность.

❌ "Prepare a good client proposal."

✅
```md
1. Identify client context and business goal.
2. Extract required integrations.
3. Split scope into phases.
4. Mark assumptions and dependencies.
5. Prepare price justification.
6. End with next steps.
```

### 8. Степень свободы — под риск задачи

Три режима:

- **Высокая свобода** — творческие/контекстные задачи (написание поста)
- **Средняя** — есть предпочтительный паттерн
- **Низкая** — операция хрупкая (миграция БД)

Для критичного — точные команды, скрипты, запреты.

```bash
python scripts/migrate.py --verify --backup
```
> Do not modify the command or add flags.

### 9. Feedback loop: validate → fix → validate

Common pattern. Особенно полезно для skills, генерирующих документы, код, JSON, KB.

```md
1. Generate output.
2. Validate against checklist.
3. If issues are found, fix them.
4. Run validation again.
5. Only finalize when validation passes.
```

### 10. Output template для строгого формата

Снижает разброс результата. Особенно для API responses, отчётов, КП, JSON, таблиц.

```md
## Output format

# Коммерческое предложение

## Задача клиента
...

## Предлагаемое решение
...

## Этапы работ
...
```

### 11. Concrete examples, не абстракции

Для skills, где качество зависит от стиля/формата — input/output пары.

```md
## Examples

Input:
"Нужно КП для салона красоты на WhatsApp-ассистента"

Output:
[пример структуры КП]
```

### 12. Не клади time-sensitive информацию в основное тело

Старые подходы — в отдельный блок `Old patterns`.

❌ "До августа 2025 используй старый API, после — новый."

✅
```md
## Current method
Use v2 API.

## Old patterns
Legacy v1 API, deprecated 2025-08.
```

### 13. Одна терминология внутри skill

Не смешивай `API endpoint / URL / route / path` для одного и того же. Не смешивай `эскалация / handoff / перевод менеджеру / передача оператору`.

Выбери один термин — используй его везде.

### 14. Детерминированные операции — в scripts

Не "пусть Claude сгенерирует код каждый раз". Scripts надёжнее, экономят токены, ускоряют, обеспечивают консистентность.

```md
Run:
python scripts/validate_kb.py kb.json

Expected output:
OK
```

### 15. Scripts сами обрабатывают ошибки ("Solve, don't punt")

Не падать и перекладывать на модель.

❌
```python
return open(path).read()
```

✅
```python
try:
    return open(path).read()
except FileNotFoundError:
    print("File not found")
    return ""
```

### 16. Dependencies указывать явно

В Claude API нет network access и runtime install. Возможности claude.ai отличаются.

```md
Required package: pypdf

If unavailable, stop and report missing dependency.
```

### 17. Unix-style paths даже на Windows

❌ `scripts\helper.py`
✅ `scripts/helper.py`

### 18. Тесты на реальных сценариях, не только happy path

Минимум — три evaluations.

```text
1. Типовой запрос
2. Запрос с неполными данными
3. Запрос с edge case / конфликтом правил
```

Тестировать с теми моделями, на которых будет использование.

### 19. Iterative process: вручную → паттерн → skill

```text
1. Один раз вручную сделать задачу.
2. Выписать повторяемую структуру.
3. Вынести правила и стиль в skill.
4. Проверить на похожей задаче.
5. Доработать места, где агент ошибся.
```

### 20. Не давать слишком много альтернатив

Один **default** + **escape hatch** для специфики.

❌ "Use pypdf, pdfplumber, PyMuPDF, pdf2image, or another library."
✅ "Use pdfplumber for text extraction. For scanned PDFs requiring OCR, use pdf2image with pytesseract."

## Короткий чеклист хорошего skill

1. Название конкретное, без `helper/utils`.
2. `description` содержит: что делает + когда использовать.
3. `SKILL.md` короткий, без общеизвестных объяснений.
4. Сложные детали вынесены в reference-файлы.
5. Все reference-файлы доступны напрямую из `SKILL.md`.
6. Workflow разбит на шаги.
7. Есть output template.
8. Есть concrete examples.
9. Есть edge cases и validation loop.
10. Детерминированные операции вынесены в scripts.
11. Dependencies явно указаны.
12. Skill протестирован на 3+ реальных сценариях.

## Применение к моим проектам

### Аудит существующих skills

В моём global setup много custom skills (`ingest`, `inbox-processor`, `ai-digest`, `proposal`, `entity-scaffold`, `slidev-carousel`, `tiktok-carousel`, `social-content` и др.). Чеклист = повод для quick stocktake:

- [ ] У всех ли `description` содержит триггеры (правило #2)?
- [ ] Есть ли skills с общими именами типа `helper` (правило #3)?
- [ ] Есть ли цепочки reference-файлов глубже одного уровня (правило #6)?
- [ ] Где детерминированные операции до сих пор делаются через Claude вместо script'а (правило #14)?
- [ ] Какие skills НЕ протестированы на 3+ сценариях (правило #18)?

### AGIency / Dogovor24 AI Coding Training

Чеклист — готовый материал для обучения клиентов созданию своих skills. Прямо встраивается в курс "AI Coding Training" (см. `200_Projects/210_AGIency/211_Консалтинг/AI Coding Training/`).

### Блог

Кандидат на:

- **Threads-лонгрид** (тред 20+1) — практичный гайд для аудитории фаундеров/девов на Claude Code
- **Telegram-пост** длинной формы
- **Карусель для Slidev/IG** — топ-10 правил с примерами

---

## Связанные документы

- [[Создание субагентов - полное руководство 2026]] — смежная тема: skills vs subagents, когда что использовать
- [[Boris Cherny - Claude Code Development Workflow]] — workflow создателя Claude Code, контекст экосистемы
- [[Own Your Harness - Sau Sheong]] — skills как часть own-your-harness философии
- [[Субагенты для Second Brain - рекомендации]] — рекомендации по архитектуре Second Brain через subagents/skills
- [[Open-Source альтернативы Claude Code - исследование 2026]] — обзор альтернативных harness'ов
