---
date: 2026-02-13
tags: [agent-teams, subagents, collaboration, orchestration, claude-code]
type: comparison-guide
status: active
related: [[Создание субагентов - полное руководство 2026]], [[Субагенты для Second Brain - рекомендации]]
---

# Agent Teams vs Subagents - когда использовать что

## 🆕 Agent Teams - новая фича Claude Code (Feb 5, 2026)

**Agent Teams** — это экспериментальная фича, выпущенная вместе с Claude Opus 4.6, позволяющая агентам **напрямую общаться друг с другом** (peer-to-peer messaging).

### Ключевое отличие от субагентов

```
SUBAGENTS (Hub-and-Spoke):
Main Agent
    ├─→ Subagent A → returns result → Main Agent
    ├─→ Subagent B → returns result → Main Agent
    └─→ Subagent C → returns result → Main Agent

(субагенты НЕ общаются друг с другом)

AGENT TEAMS (Peer-to-Peer):
Team Lead
    ├─→ Teammate A ←→ Teammate B
    ├─→ Teammate B ←→ Teammate C
    └─→ Teammate C ←→ Teammate A

(teammates общаются напрямую через mailbox system)
```

---

## Сравнительная таблица

| Характеристика | **Subagents** | **Agent Teams** |
|----------------|---------------|-----------------|
| **Паттерн коммуникации** | Hub-and-Spoke (только через parent) | Peer-to-Peer (напрямую друг с другом) |
| **Mailbox System** | ❌ Нет | ✅ Есть (SendMessage tool) |
| **Shared Task List** | ❌ Нет | ✅ Есть (все видят статусы задач) |
| **Self-Coordination** | ❌ Нет (только parent координирует) | ✅ Есть (teammates сами решают кто что делает) |
| **Context Persistence** | ❌ Terminate после задачи | ✅ Maintain state across turns |
| **Multi-Round Conversations** | ❌ Нет | ✅ Есть (teammates могут дискутировать) |
| **Cost** | 1.5-2x single session | ~5-7x single session (каждый teammate = full instance) |
| **Complexity** | Низкая | Высокая |
| **Best For** | Независимые параллельные задачи | Задачи требующие координации |
| **Status** | Stable (v1.0+) | Experimental (flag required) |

---

## Когда использовать Subagents

### ✅ Используйте субагенты для:

1. **Truly Independent Tasks** — задачи не требуют взаимодействия
   ```
   Примеры:
   - Параллельные тесты в разных модулях
   - Поиск паттернов в 5 разных директориях
   - Генерация документации для отдельных компонентов
   - Обработка Inbox (каждый файл независим)
   ```

2. **Simple Delegation** — делегировать и получить результат
   ```
   Workflow:
   1. Parent: "Research topic X"
   2. Subagent: [executes research]
   3. Subagent → Parent: "Here are findings"
   4. Subagent: [terminates]
   ```

3. **Cost Optimization** — когда бюджет ограничен
   ```
   Cost: 1.5-2x single session
   vs Agent Teams: 5-7x single session
   ```

4. **Context Isolation** — предотвращение context bloat
   ```
   Problem: Main agent контекст 80K/200K tokens
   Solution: Subagent работает в отдельном контексте
   ```

### Примеры из Second Brain (субагенты)

- ✅ **Knowledge Organizer** — обработка Inbox (файлы независимы)
- ✅ **Content Research** — поиск материалов для поста (одна тема)
- ✅ **Weekly Synthesis** — анализ недели (изолированная задача)

---

## Когда использовать Agent Teams

### ✅ Используйте Agent Teams для:

1. **Coordinated Work** — teammates должны взаимодействовать
   ```
   Примеры:
   - Multi-module feature: Backend Agent ←→ Frontend Agent ←→ Test Agent
   - Debugging: Agent A (hypothesis 1) ←→ Agent B (hypothesis 2) → argue
   - Code review: Security Agent ←→ Performance Agent ←→ Testing Agent
   ```

2. **Building on Each Other's Work** — results влияют на друг друга
   ```
   Workflow:
   1. Backend Agent: "I created API endpoint /api/users"
   2. Frontend Agent (reads message): "I'll create UsersList component"
   3. Test Agent (reads both): "I'll write integration test for this flow"
   ```

3. **Multi-Round Discussions** — агенты дискутируют решения
   ```
   Example: Debugging Session
   Agent A: "I think bug is in database query"
   Agent B: "Actually, I see race condition in async code"
   Agent C: "Both theories have merit, let me test..."
   Team Lead: "Agent C found it - race condition confirmed"
   ```

4. **Self-Coordination** — автоматическое распределение работы
   ```
   Shared Task List:
   [ ] Task 1: Implement backend endpoint
   [ ] Task 2: Create frontend component
   [ ] Task 3: Write tests

   Teammate A: [claims Task 1]
   Teammate B: [claims Task 2]
   Teammate C: [claims Task 3]
   (без явных инструкций от Team Lead)
   ```

### 🏆 Легендарный кейс: C Compiler (Anthropic)

**Задача:** Написать полноценный C compiler на Rust

**Setup:**
- 16 Agent Team
- Team Lead (Opus 4.6) + 15 Teammates

**Результат:**
- 100,000 строк Rust кода
- Компилирует Linux 6.9 kernel
- Cost: ~$20,000
- Proof: Agent Teams работают для extreme scale

---

## Agent Teams для Second Brain?

### ❌ НЕ рекомендуется (пока)

**Почему:**

1. **Задачи в Second Brain преимущественно независимы**
   ```
   - Обработка Inbox: каждый файл отдельно
   - Research: одна тема за раз
   - Weekly Synthesis: изолированный анализ
   - YouTube выжимки: независимые видео
   ```
   → **Subagents достаточно**

2. **Cost: 5-7x дороже vs 1.5-2x субагентов**
   ```
   Subagents (3 агента): ~$9.40/week
   Agent Teams (3 teammates): ~$47-65/week

   ROI сомнителен для Second Brain use case
   ```

3. **Complexity overhead**
   ```
   Agent Teams требуют:
   - Настройку mailbox system
   - Координацию через shared task list
   - Мониторинг peer-to-peer messages
   - Debugging inter-agent communication

   Overkill для организации заметок
   ```

4. **Experimental status**
   ```
   - Требует флаг: CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
   - Может быть нестабильно
   - API может измениться
   ```

### ✅ Исключение: Content Creation Pipeline

**Единственный кейс где Agent Teams могут быть полезны:**

```
Content Creation Agent Team:
Team Lead: Content Strategist (Opus 4.6)
    │
    ├─→ Research Teammate (Sonnet 4.5)
    ├─→ Writer Teammate (Opus 4.6)
    ├─→ Editor Teammate (Sonnet 4.5)
    └─→ SEO Optimizer Teammate (Haiku 4.5)
```

**Workflow:**
1. **Research Teammate:** "I found 5 key trends on AI agents 2026"
2. **Writer Teammate:** "Based on your research, I'll focus on orchestration patterns"
3. **Editor Teammate:** "Writer, your hook is weak. Try AIDA framework"
4. **Writer:** "Updated. Editor, review again?"
5. **Editor:** "Approved. SEO, optimize now"
6. **SEO Optimizer:** "Added keywords, meta description, internal links"
7. **Team Lead → User:** "Post ready: AI Agent Orchestration Patterns 2026"

**Но даже здесь:**
- Стоимость: ~$15-20 на пост
- vs Sequential субагенты: ~$5-7 на пост
- Выигрыш: более согласованный контент, peer review

**Verdict:** Попробовать на 1-2 постах, оценить ROI

---

## Технические детали Agent Teams

### Mailbox System (Peer-to-Peer Messaging)

**Как работает:**

1. **SendMessage tool:**
   ```typescript
   SendMessage({
     recipient: "Backend Engineer",  // имя teammate
     message: "API endpoint created at /api/users"
   })
   ```

2. **Broadcast к всем:**
   ```typescript
   SendMessage({
     recipient: "ALL",
     message: "Sprint planning: new tasks in shared list"
   })
   ```

3. **Automatic delivery:**
   - Сообщения доставляются автоматически
   - Team Lead НЕ нужно poll updates
   - Idle teammates получают notification

### Shared Task List

**Формат:**
```yaml
tasks:
  - id: 1
    title: "Implement backend endpoint"
    status: in_progress
    assigned_to: "Backend Engineer"

  - id: 2
    title: "Create frontend component"
    status: pending
    assigned_to: null

  - id: 3
    title: "Write integration tests"
    status: pending
    assigned_to: null
```

**Self-Coordination:**
- Teammate видит task #2 pending
- Teammate: "I'll take task #2"
- Task list автоматически обновляется: `assigned_to: "Frontend Engineer"`

### TeammateTool API

**Создание team:**
```python
# Концептуальный пример (API может отличаться)
team = spawnTeam(
    name="Content Pipeline Team",
    lead_model="claude-opus-4-6",
    teammates=[
        {
            "name": "Research Teammate",
            "model": "claude-sonnet-4-5",
            "tools": ["web_search", "web_fetch", "read"],
            "system_prompt": "You are research specialist..."
        },
        {
            "name": "Writer Teammate",
            "model": "claude-opus-4-6",
            "tools": ["read", "write", "edit"],
            "system_prompt": "You are content writer..."
        }
    ]
)
```

---

## Cost Breakdown: Agent Teams vs Subagents

### Scenario: Создание 1 поста для блога

#### Subagents (Sequential):
```
1. Research Subagent (Sonnet 4.5): $2.50
2. Writer Subagent (Opus 4.6): $3.50
3. Editor Subagent (Sonnet 4.5): $1.20
---
Total: $7.20 per post
```

#### Agent Teams (Collaborative):
```
Team Lead (Opus 4.6): $4.00
Research Teammate (Sonnet 4.5): $3.00 (longer context, messages)
Writer Teammate (Opus 4.6): $5.00 (revisions based on Editor feedback)
Editor Teammate (Sonnet 4.5): $2.50 (multiple review rounds)
SEO Teammate (Haiku 4.5): $0.50
---
Total: $15.00 per post
```

**Разница:** $7.80 extra per post (~2x дороже)

**Вопрос ROI:** Стоит ли collaborative workflow этих денег?

---

## Как включить Agent Teams (Experimental)

### 1. Enable Feature Flag

**Settings > Experimental Features:**
```bash
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=true
```

### 2. Создание команды

**Через UI:**
```bash
/agents team
```

**Через код:**
```python
# Используется внутренний API (может измениться)
# Проверяйте актуальную документацию
```

### 3. Keyboard Shortcuts

- **Shift+Up/Down:** Выбрать teammate для direct message
- **Ctrl+T:** Открыть shared task list
- **Ctrl+M:** Открыть mailbox (входящие сообщения)

---

## Best Practices для Agent Teams

### 1. Clear Role Definition

**Плохо:**
```yaml
teammates:
  - name: "Agent 1"  # непонятная роль
  - name: "Agent 2"
```

**Хорошо:**
```yaml
teammates:
  - name: "Backend Engineer"     # чёткая роль
  - name: "Frontend Engineer"
  - name: "QA Engineer"
```

### 2. Explicit Communication Protocols

**Добавить в system prompts:**
```
Communication Protocol:
- Always @mention recipient when responding
- Use format: "Status: [DONE/BLOCKED/IN_PROGRESS]"
- Notify Team Lead when task complete
- Ask for clarification if requirements unclear
```

### 3. Task Granularity

**Плохо:**
```yaml
tasks:
  - "Build entire feature"  # слишком крупная задача
```

**Хорошо:**
```yaml
tasks:
  - "Create database migration for users table"
  - "Implement /api/users endpoint"
  - "Create UsersList React component"
  - "Write integration tests for user flow"
```

### 4. Monitor Token Usage

**Tracking:**
```yaml
team_metrics:
  team_lead: 15K tokens
  teammate_a: 22K tokens (много messages)
  teammate_b: 8K tokens
  teammate_c: 18K tokens
  ---
  total: 63K tokens (vs 25K для sequential subagents)
```

**Optimization:**
- Если teammate использует >30K tokens → задача слишком сложная?
- Если много messages между teammates → нужна ли координация?

---

## Эволюция паттернов координации (2024-2026)

```
2024: Single Agent
  └─→ Всё делает один агент
      ❌ Context overflow
      ❌ Slow на больших задачах

2025: Subagents (Hub-and-Spoke)
  └─→ Parent агент делегирует субагентам
      ✅ Параллелизация
      ✅ Context isolation
      ❌ Нет координации между субагентами

2026: Agent Teams (Peer-to-Peer)
  └─→ Teammates общаются напрямую
      ✅ Параллелизация
      ✅ Context isolation
      ✅ Self-coordination
      ⚠️ Дороже (5-7x cost)
      ⚠️ Сложнее в настройке
```

---

## Альтернативы Agent Teams

### 1. Sequential Subagents с Artifact Passing

**Идея:** Субагенты работают последовательно, передавая артефакты

```
Research Subagent
    ↓ (saves findings.md)
Writer Subagent (reads findings.md)
    ↓ (saves draft.md)
Editor Subagent (reads draft.md)
    ↓ (saves final.md)
```

**Плюсы:**
- ✅ Дешевле (1.5-2x vs 5-7x)
- ✅ Проще в отладке
- ✅ Тот же результат для многих кейсов

**Минусы:**
- ❌ Нет real-time feedback между агентами
- ❌ Если Editor находит проблему → нужно перезапускать Writer

### 2. Hierarchical Subagents

**Идея:** Субагенты могут создавать своих субагентов

```
Main Agent
    ├─→ Research Subagent
    │       ├─→ Web Search Sub-Subagent
    │       └─→ YouTube Analysis Sub-Subagent
    └─→ Writer Subagent
            ├─→ Hook Writer Sub-Subagent
            └─→ SEO Optimizer Sub-Subagent
```

**Плюсы:**
- ✅ Глубокая специализация
- ✅ Context isolation на каждом уровне

**Минусы:**
- ❌ Сложная координация (3 уровня)
- ❌ Debugging кошмар

---

## Рекомендации для Second Brain

### Phase 1 (Текущий этап): Subagents

**Что делать:**
- ✅ Реализовать 3 субагента (Research, Organizer, Synthesis)
- ✅ Использовать Sequential Subagents с Artifact Passing
- ✅ Мониторить ROI (время экономии vs cost)

**Не делать:**
- ❌ Не пробовать Agent Teams (overkill для current use cases)
- ❌ Не усложнять архитектуру без необходимости

### Phase 2 (Future, если нужно): Experiment с Agent Teams

**Кандидат для эксперимента:**
```
Content Creation Pipeline:
- 1 пост/неделю через Agent Team
- Track: качество vs sequential, cost, время
- Evaluate: стоит ли collaborative workflow +$7-10 per post?
```

**Success criteria для перехода на Agent Teams:**
- Quality улучшается на 30%+
- Time to publish сокращается на 50%+
- User satisfaction with content повышается
- ROI положительный (hourly rate * time saved > extra cost)

### Phase 3 (Advanced): Hybrid Approach

**Идея:** Разные паттерны для разных задач

```yaml
workflows:
  inbox_processing:
    pattern: subagents  # независимые задачи
    agents: [Knowledge Organizer]

  content_creation:
    pattern: agent_teams  # collaborative work
    agents: [Research, Writer, Editor, SEO]

  weekly_synthesis:
    pattern: single_agent  # deep reasoning
    agents: [Weekly Synthesis Agent]
```

---

## Ключевые выводы

### Agent Teams vs Subagents: Decision Matrix

| Фактор | Subagents | Agent Teams |
|--------|-----------|-------------|
| **Независимые задачи** | ✅ Оптимально | ❌ Overkill |
| **Координация требуется** | ❌ Не подходит | ✅ Оптимально |
| **Бюджет ограничен** | ✅ 1.5-2x cost | ❌ 5-7x cost |
| **Простота** | ✅ Просто | ❌ Сложно |
| **Experimental риски** | ✅ Stable | ⚠️ Experimental |
| **Second Brain use cases** | ✅ Подходит | ❌ Не нужно (пока) |

### Золотое правило

> **"Use the simplest pattern that solves your problem"**

Для Second Brain это **Subagents** в 95% случаев.

Agent Teams — это мощный инструмент, но **не для всех задач**. Как microservices: иногда monolith лучше.

---

## Источники и дальнейшее изучение

### Официальная документация

- [Orchestrate teams of Claude Code sessions](https://code.claude.com/docs/en/agent-teams) - Official docs
- [Claude 4.6 Agent Teams: The Complete Guide](https://blog.laozhang.ai/en/posts/claude-4-6-agent-teams) - Comprehensive guide

### Practical Guides

- [From Tasks to Swarms: Agent Teams in Claude Code](https://alexop.dev/posts/from-tasks-to-swarms-agent-teams-in-claude-code/) - Evolution of patterns
- [How to Set Up and Use Claude Code Agent Teams](https://darasoba.medium.com/how-to-set-up-and-use-claude-code-agent-teams-and-actually-get-great-results-9a34f8648f6d) - Practical setup
- [Claude Code Agent Teams Workflows for Large Projects](https://www.geeky-gadgets.com/claude-code-agent-team-guide/) - Large-scale use cases

### Case Studies

- [C Compiler with 16 Agents](https://code.claude.com/docs/en/agent-teams#case-study) - Anthropic's legendary example
- [VS Code Multi-Agent Development](https://code.visualstudio.com/blogs/2026/02/05/multi-agent-development) - Microsoft's perspective

### Внутренние материалы

- [[Создание субагентов - полное руководство 2026]] - Full subagent guide
- [[Субагенты для Second Brain - рекомендации]] - Specific recommendations
- [[Claude Code as Embedded OS - Gur Sannikov]] - Per-model routing philosophy

---

*Создано: 2026-02-13*
*Обновлено: 2026-02-13*
*Статус: Active Comparison Guide*

#agent-teams #subagents #comparison #orchestration #claude-code #decision-making
