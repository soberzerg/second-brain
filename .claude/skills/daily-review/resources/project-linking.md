# Project Linking Guide

## Purpose

Связывание daily review с project notes помогает:
- Отслеживать прогресс по проектам
- Создавать timeline развития
- Видеть паттерны работы
- Находить связанные заметки быстро

## Active Projects from CLAUDE.md

При создании daily review всегда проверяй эти активные проекты:

### Priority Projects

1. **[[AGIents.pro]]** - B2B no-code платформа для ИИ-агентов
   - Path: `01_Projects/AGIents.pro/`
   - Key areas: API Development, MVP, Client Integration

2. **[[Clario]]** - B2B ИИ-аналитика продаж
   - Path: `01_Projects/Clario/`
   - Key areas: Analytics Module, Team Coordination, Architecture

3. **[[AGIency.pro]]** - Агентство ИИ-автоматизации
   - Path: `01_Projects/AGIency.pro/`
   - Key areas: Client Projects (Amaks), Automation Implementations

4. **[[AI-код-ревью система]]** - Кастомная система код-ревью
   - Path: `01_Projects/AI-код-ревью система/`
   - Key areas: PHP Review, System Improvements, Dogovor24 Integration

5. **[[AISobolev - блог buildinpublic]]** - Личный блог
   - Path: `01_Projects/AISobolev - блог buildinpublic/`
   - Key areas: Draft Posts, Published Posts, Content Ideas

6. **[[Express Security Audit]]** - Продуктизация AI-код-ревью
   - Path: `01_Projects/Express Security Audit/`
   - Key areas: Landing Page, Validation, Marketing

7. **[[TG Claude Code Assistant]]** - Telegram бот для Claude Code
   - Path: `01_Projects/TG Claude Code Assistant/`
   - Key areas: Architecture, MVP Development, Integration

## Linking Strategy

### 1. Project Detection

При анализе отчёта, ищи упоминания:
- Прямые: "AGIents", "Clario", "TG Bot"
- Косвенные: "no-code платформа", "analytics модуль", "telegram бот"
- По клиентам: "Amaks", "Dogovor24"
- По технологиям: "go-kratos", "FastAPI", "Claude Code CLI"

### 2. Automatic Linking

Для каждого упомянутого проекта:

```markdown
### [[Project Name]]

- [What was done today]
- [Current state → Next step]
- [Link to related daily note if needed]
```

### 3. Bidirectional Links

**In Daily Review:**
```markdown
## 🔗 Related Notes

- [[AGIents.pro - API Development]]
- [[TG Claude Code Assistant - Masterplan]]
```

**In Project Notes:**
Можно добавить backlink в project note:
```markdown
## Recent Daily Reviews

- [[2026-02-06 Daily Review]] - Completed API endpoints
- [[2026-02-05 Daily Review]] - Started unit tests
```

## Project-Specific Patterns

### AGIents.pro

**Key areas to track:**
- API Development progress
- MVP features completion
- Client integration status
- Technical decisions

**Example linking:**
```markdown
### [[AGIents.pro]]

- API endpoints: 3 new completed → 70% MVP coverage
- Next: JSON validation schema
- Related: [[AGIents API Architecture Decision]]
```

### Clario

**Key areas to track:**
- Team coordination (code reviews, discussions)
- Analytics module development
- Architecture decisions

**Example linking:**
```markdown
### [[Clario]]

- Code review: PR #234 auth refactoring approved
- Analytics module: base models implemented
- Related: [[Clario Analytics Architecture]]
```

### AISobolev Blog

**Key areas to track:**
- Posts published
- Engagement metrics
- Content ideas discovered

**Example linking:**
```markdown
### [[AISobolev Blog]]

- Published: "Claude Code на мобильном" → 50+ reactions
- Discovered: FAQ requests about Android setup
- Related: [[2026-02-06 Claude Code Mobile Post]]
```

### TG Claude Code Assistant

**Key areas to track:**
- Architecture decisions
- Implementation progress
- Integration challenges

**Example linking:**
```markdown
### [[TG Claude Code Assistant]]

- Created masterplan document
- Research: headless Claude Code authentication
- Related: [[TG Bot Masterplan]]
```

## Finding Related Notes

### By Project

```bash
# Find all notes in project directory
ls -la "01_Projects/[Project Name]/"

# Search for mentions in project notes
grep -r "keyword" "01_Projects/[Project Name]/"
```

### By Date

```bash
# Find notes modified today
find . -name "*.md" -mtime -1

# Find notes modified this week
find . -name "*.md" -mtime -7
```

### By Content

Use Obsidian search or Grep tool:
```
pattern: "API endpoints"
path: 01_Projects/AGIents.pro/
```

## Frontmatter Integration

Add project tags to frontmatter:

```yaml
---
date: 2026-02-06
type: daily-review
projects:
  - AGIents.pro
  - Clario
  - AISobolev Blog
tags:
  - api-development
  - code-review
  - content-creation
status: ✅ productive
---
```

This allows:
- Filtering daily reviews by project
- Seeing project timelines
- Dataview queries (if using Obsidian plugin)

## Review Aggregation

### Weekly Summary

When creating weekly synthesis, aggregate by project:

```markdown
## AGIents.pro Progress This Week

- Mon: Started API endpoints
- Tue: Completed 3 endpoints
- Wed: Unit tests added
- Thu: JSON validation research
- Fri: Integration tests

**Overall:** API MVP 70% → 95% this week
```

### Project Status Update

Use daily reviews to update project README:

```markdown
# AGIents.pro

## Recent Progress (from daily reviews)

- 2026-02-06: API endpoints 70% complete
- 2026-02-05: Unit tests added
- 2026-02-04: Architecture refactoring
```

## Best Practices

1. **Always link to project root**: `[[AGIents.pro]]` not just "AGIents"
2. **Be specific**: Link to specific project notes when relevant
3. **Track progression**: "30% → 70%" shows movement
4. **Note blockers**: If project stuck, note why
5. **Cross-reference**: Link to related decisions, meetings, documents

## Example: Full Daily Review with Rich Linking

```markdown
---
date: 2026-02-06
type: daily-review
projects: [AGIents.pro, Clario, AISobolev Blog]
status: ✅ productive
---

# Daily Review - Thursday, 2026-02-06

## 🚀 Progress Made

### [[AGIents.pro]]

- API для создания агентов 70% готово → осталось валидация
- Unit тесты покрывают основные сценарии
- Следующий шаг: интеграционные тесты с БД
- Related: [[AGIents API Architecture]], [[AGIents MVP Roadmap]]

### [[Clario]]

- Код-ревью PR #234 (auth module) → approved
- Архитектура analytics модуля утверждена
- Следующий шаг: API endpoints для дашборда
- Related: [[Clario Analytics Architecture]], [[Team Meeting 2026-02-06]]

### [[AISobolev Blog]]

- Опубликовал [[2026-02-06 Claude Code Mobile Post]]
- 50+ реакций за 2 часа, несколько вопросов про Android
- Идея для follow-up: FAQ по настройке
- Related: [[Content Ideas - Claude Code Series]]

## 🔗 Related Notes

- [[AGIents.pro - API Development]]
- [[AGIents MVP Roadmap]]
- [[Clario Analytics Architecture]]
- [[TG Claude Code Assistant - Masterplan]]
- [[2026-02-06 Claude Code Mobile Post]]
```
