---
name: wiki-lint
description: |
  Проверка здоровья wiki — orphan pages, missing frontmatter, broken links, stale inbox, index drift.
  Use when: пользователь хочет проверить состояние хранилища.
  Triggers: "lint", "wiki-lint", "проверь хранилище", "здоровье wiki", "health check"
---

# Wiki Lint — проверка здоровья хранилища

Автоматическая проверка целостности и качества Second Brain vault.

## When to Use This Skill

- Пользователь просит проверить хранилище
- После массового ingest (обработка нескольких файлов)
- В рамках weekly-synthesis (автоматический шаг)
- При подозрении на bitrot (устаревшие данные, сломанные ссылки)

## Arguments

- `--save` — сохранить отчёт в `400_Planning/430_Daily_Notes/YYYY-MM-DD Wiki Lint Report.md`
- Без аргументов — показать отчёт в сессии

## Workflow

### Step 1: Scan All Files

Собрать список всех `.md` файлов в vault:
- Исключить: `README.md`, `node_modules/`, `.obsidian/`, `.claude/`, `slidev/`, `generated_imgs/`
- Включить: `index.md`, `log.md`, `CLAUDE.md`, `USER.md` и все файлы в 000-500 директориях

### Step 2: Check Missing Frontmatter

Для каждого файла (кроме README.md, index.md, log.md, CLAUDE.md, USER.md):
1. Проверить наличие YAML frontmatter (`---` в начале файла)
2. Проверить обязательные поля: `type`, `date`
3. Записать файлы с отсутствующим или неполным frontmatter

### Step 3: Check Missing Related Documents

Для каждого файла (кроме README.md, index.md, log.md, CLAUDE.md, USER.md):
1. Проверить наличие секции `## Связанные документы` в конце файла
2. Записать файлы без этой секции

### Step 4: Check Stale Inbox

1. Прочитать файлы в `000_Inbox/` (кроме README.md)
2. Для каждого файла проверить дату в frontmatter или modification time
3. Пометить файлы старше 7 дней как stale

### Step 5: Find Orphan Pages

1. Собрать все `[[wiki-links]]` из всех файлов vault
2. Построить граф входящих ссылок
3. Найти страницы с 0 входящих ссылок
4. Исключить из orphans: README.md, index.md, log.md, CLAUDE.md, USER.md, Daily Notes, AI Digests

### Step 6: Find Broken Wiki-Links

1. Собрать все `[[wiki-links]]` из всех файлов
2. Для каждой ссылки проверить, существует ли целевой файл
3. Записать сломанные ссылки с указанием source файла

### Step 7: Check Index Drift

1. Собрать все файлы, перечисленные в `index.md`
2. Сравнить со списком реальных файлов vault
3. Найти:
   - Файлы, отсутствующие в index (но существующие на диске)
   - Записи в index, указывающие на несуществующие файлы

### Step 8: Generate Report

Формат отчёта:

```markdown
# Wiki Lint Report — YYYY-MM-DD

## Summary
- Total files scanned: X
- Issues found: Y
- Critical: Z (missing frontmatter, broken links)
- Warnings: W (orphans, stale inbox, index drift)

## Missing Frontmatter (N files)
- `path/to/file.md` — missing: type, date

## Missing Related Documents (N files)
- `path/to/file.md`

## Stale Inbox Items (N files)
- `000_Inbox/file.md` — age: X days

## Orphan Pages (N pages)
- `path/to/orphan.md` — 0 inbound links

## Broken Wiki-Links (N links)
- In `path/to/file.md`: [[Non Existent Page]]

## Index Drift
- Missing from index: `path/to/new-file.md`
- Stale index entry: `path/to/deleted-file.md`

## Recommendations
- <actionable suggestions based on findings>
```

### Step 9: Save or Display

- Без `--save`: показать отчёт в сессии
- С `--save`: создать файл `400_Planning/430_Daily_Notes/YYYY-MM-DD Wiki Lint Report.md` с frontmatter:

```yaml
---
type: daily-note
date: YYYY-MM-DD
tags: [wiki-lint, health-check]
status: done
---
```

### Step 10: Update log.md

Добавить запись:

```markdown
## [YYYY-MM-DD] lint | Wiki Health Check
- Issues found: X (Y critical, Z warnings)
- Report: displayed / saved to <path>
```
