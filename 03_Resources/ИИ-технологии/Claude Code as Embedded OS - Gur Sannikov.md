---
source: https://www.linkedin.com/posts/gursannikov_claudecode-embeddedengineering-aiagents-activity-7423851983331328001-DrFb
date: 2026-02-06
tags: [claude-code, architecture, embedded-systems, ai-agents, workflow]
type: article-summary
author: Gur Sannikov
---

# Claude Code as Embedded OS - Gur Sannikov

## Основная идея

Gur Sannikov проводит параллель между Claude Code и embedded операционной системой, используя концепции из архитектуры процессоров для описания возможностей инструмента.

## Ключевые концепции

### 11 нативных возможностей Claude Code

1. **Hooks** - pre/post tool-use хуки для автоматизации
2. **Background agents** - фоновые агенты для параллельной работы
3. **Subagents** - `/explore` и `/plan` для специализированных задач
4. **Task batching** - пакетная обработка задач
5. **Agent swarms** - координация множества агентов
6. **Per-task model selection** - выбор модели под задачу

### Аналогия с ARM big.LITTLE

**Маппинг моделей Claude на архитектуру процессора:**

| Claude Model | Processor Core Type | Use Case |
|--------------|-------------------|----------|
| **Opus** | Performance cores | Сложные рассуждения (complex reasoning) |
| **Sonnet** | Balanced cores | Генерация кода (code generation) |
| **Haiku** | Efficiency cores | Валидация (validation) |

**Смысл:** Каждая модель оптимизирована для своего типа задач, как разные ядра процессора.

### Практический workflow

```
1. Написать ADR (Architecture Decision Records) на обычном английском
   ↓
2. Передать в "implement-adr" skill
   ↓
3. Skill автоматически маппит требования на нативные возможности Claude Code
   ↓
4. Результат: работающее решение без внешних фреймворков
```

**ADR** (Architecture Decision Records) - документация архитектурных решений в plain text формате.

### Экосистема и альтернативы

**Конкуренты:**
- **GitHub Copilot CLI** - похожие фичи, но другая экосистема
- **OpenCode** - альтернативный подход

**Продвинутые orchestrators:**
- **oh-my-claudecode** - расширенная оркестрация
- **claude-flow v3** - workflow автоматизация

**Вывод Gur:** Claude Code 2.1+ покрывает 80% функциональности с минимальной настройкой, что делает сторонние orchestrators избыточными для большинства кейсов.

## Технические детали

### 8-фазный workflow с gates

Упоминается workflow из 8 фаз с completion gates (контрольными точками), что позволяет:
- Отслеживать прогресс
- Гарантировать качество на каждом этапе
- Автоматически переходить к следующей фазе

### Git интеграция для параллельной разработки

Claude Code нативно интегрирован с Git для:
- Параллельной работы над разными фичами
- Автоматических коммитов на контрольных точках
- Создания PR с описанием изменений

## Применимость для embedded engineering

**Как Claude Code ускоряет разработку embedded систем:**

1. **Intelligent workflow automation** - автоматизация рутинных задач
2. **Capability routing** - маршрутизация задач на правильные модели
3. **Plain English requirements** - требования на естественном языке → код
4. **Multi-model orchestration** - оркестрация разных моделей для оптимальной производительности

## Инсайты для моих проектов

### AGIents.pro

✅ **Что перенять:**
- Концепция "per-task model selection" - выбор модели под задачу клиента
- Workflow с completion gates для отслеживания прогресса агента
- ADR → Implementation pipeline для бизнес-требований

### TG Claude Code Assistant

✅ **Применимо:**
- Использование разных моделей для разных типов запросов:
  - Haiku для быстрых команд (список задач, краткие ответы)
  - Sonnet для основных задач (текущий выбор)
  - Opus для сложного анализа (когда нужен глубокий reasoning)

### Общий вывод

**Философия "минимум внешних зависимостей":**
- Claude Code 2.1+ покрывает 80% потребностей
- Сторонние orchestrators нужны только для edge cases
- Native capabilities достаточно мощные для production use

**Параллель с подходом Boris Cherny:**
- Оба: минимум кода вокруг модели
- Оба: используй нативные возможности вместо scaffolding
- Оба: простота > сложность

## Связанные материалы

- [[03_Resources/ИИ-технологии/Boris Cherny - Claude Code Development Workflow.md]] - та же философия минимализма
- [[01_Projects/TG Claude Code Assistant/masterplan.md]] - применить per-model routing
- [[01_Projects/AGIents.pro - ИИ-агенты платформа/README.md]] - концепция task-to-model маппинга

---

## Источник

LinkedIn post: https://www.linkedin.com/posts/gursannikov_claudecode-embeddedengineering-aiagents-activity-7423851983331328001-DrFb

*Создано: 2026-02-10*
