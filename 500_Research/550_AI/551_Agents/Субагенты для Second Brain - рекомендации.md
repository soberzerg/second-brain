---
date: 2026-02-13
tags: [subagents, second-brain, obsidian, knowledge-management, automation]
type: architecture-recommendation
status: active
related: [[Создание субагентов - полное руководство 2026]]
---

# Субагенты для Second Brain - Рекомендации

## Анализ текущих задач

### Что делается в Second Brain (на основе Weekly Synthesis Week 6)

1. **Создание контента:**
   - Посты для блога (4 поста/неделю)
   - Черновики и редактирование
   - YouTube-выжимки (6 видео/неделю)

2. **Управление знаниями:**
   - Структурирование заметок по PARA
   - Связывание материалов между проектами
   - Обработка Inbox (8-10 элементов/неделю)
   - Миграция из OLD_VAULT

3. **Планирование и рефлексия:**
   - Weekly Syntheses (comprehensive)
   - Weekly Plans
   - Daily Reviews
   - Годовой план

4. **Проектная работа:**
   - Документация по 8 активным проектам
   - Исследования (конкуренты, технологии)
   - PRD, спецификации, идеи

5. **Клиентская работа:**
   - Заметки по клиентам (Amaks, Miaclinic, Денис Сорокин)
   - ТЗ, Implementation Details

---

## Рекомендуемая архитектура субагентов

### Вариант 1: Минималистичный (Рекомендуется для старта)

```
Main Orchestrator (Sonnet 4.5)
    │
    ├─→ Content Research Agent (Sonnet 4.5)
    ├─→ Knowledge Organizer Agent (Haiku 4.5)
    └─→ Weekly Synthesis Agent (Opus 4.6)
```

#### 1. Content Research Agent

**Задачи:**
- Веб-исследования (конкуренты, технологии)
- Сбор материалов для постов
- Поиск и анализ YouTube видео
- Извлечение инсайтов из источников

**Инструменты:**
- WebSearch, WebFetch
- Firecrawl (scraping, search, extract)
- Gemini Vision (для анализа видео/скриншотов)
- Read, Grep

**Модель:** Sonnet 4.5 (balanced для research + code analysis)

**Пример использования:**
```yaml
---
name: content-research
description: Специалист по веб-исследованиям и сбору материалов для контента
model: claude-sonnet-4-5
tools: [web_search, web_fetch, firecrawl_search, read, grep, gemini_analyze_video]
system_prompt: |
  Ты эксперт по исследованиям в области ИИ-технологий и стартапов.

  Твои задачи:
  1. Находить релевантные материалы по запросу
  2. Анализировать конкурентов и рынок
  3. Извлекать ключевые инсайты из видео и статей
  4. Структурировать находки для дальнейшего использования

  Формат ответа:
  - Краткий summary (2-3 предложения)
  - Ключевые находки (bullet points)
  - Релевантные цитаты с источниками
  - Рекомендации по использованию
---
```

#### 2. Knowledge Organizer Agent

**Задачи:**
- Обработка Inbox (категоризация, связывание)
- Проверка орфанных заметок
- Предложения по улучшению структуры
- Поиск дубликатов

**Инструменты:**
- Read, Glob, Grep
- Edit (для добавления frontmatter, тегов)
- Bash (для git operations)

**Модель:** Haiku 4.5 (efficiency core для рутинных задач)

**Пример использования:**
```yaml
---
name: knowledge-organizer
description: Организует и структурирует заметки в Second Brain
model: claude-haiku-4-5
tools: [read, glob, grep, edit, bash]
system_prompt: |
  Ты специалист по организации знаний в системе PARA.

  Твои задачи:
  1. Обрабатывать элементы из Inbox:
     - Определять релевантную категорию (Project/Area/Resource)
     - Добавлять frontmatter и теги
     - Создавать связи с существующими заметками

  2. Поддерживать структуру:
     - Находить орфанные заметки (без связей)
     - Обнаруживать дубликаты
     - Предлагать улучшения организации

  3. Метаданные:
     - YAML frontmatter (date, tags, type, status)
     - Внутренние ссылки [[]]
     - Теги #

  Структура:
  - 200_Projects/ - активные проекты с дедлайнами
  - 400_Planning/ - планирование и зоны ответственности
  - 500_Research/ - справочная информация и исследования
  - 300_Blog/ - блог и контент
---
```

#### 3. Weekly Synthesis Agent

**Задачи:**
- Анализ изменений за неделю (git log, file changes)
- Выявление паттернов и инсайтов
- Генерация Weekly Synthesis
- Связывание событий между проектами

**Инструменты:**
- Read, Grep, Bash (git)
- WebSearch (для контекста внешних событий)

**Модель:** Opus 4.6 (performance core для deep reasoning)

**Пример использования:**
```yaml
---
name: weekly-synthesis
description: Создаёт глубокий анализ недели и выявляет инсайты
model: claude-opus-4-6
tools: [read, grep, bash, web_search]
system_prompt: |
  Ты аналитик высокого уровня, специализирующийся на выявлении паттернов
  и стратегических инсайтов из повседневной работы.

  Твоя задача: создать Weekly Synthesis по формату:

  1. **Неделя в цифрах** (метрики активности)
  2. **Активные проекты** (что продвинулось)
  3. **Ключевые темы недели** (2-4 темы с глубоким анализом)
  4. **Главные инсайты** (стратегические выводы)
  5. **Прогресс по проектам** (детально по каждому)
  6. **Вопросы для размышления** (открытые вопросы)
  7. **Аудит энергии** (что давало/забирало энергию)
  8. **Связи между проектами** (обнаруженные пересечения)
  9. **Намерения на следующую неделю**

  Особенности анализа:
  - Ищи пересечения между проектами
  - Выявляй emerging patterns
  - Отмечай shift в приоритетах
  - Предлагай strategic pivots

  Стиль: глубокий, рефлексивный, стратегический.
---
```

---

### Вариант 2: Расширенный (Для scaling)

```
Main Orchestrator (Sonnet 4.5)
    │
    ├─→ Content Research Agent (Sonnet 4.5)
    ├─→ Content Writer Agent (Opus 4.6)
    ├─→ Knowledge Organizer Agent (Haiku 4.5)
    ├─→ Project Tracker Agent (Haiku 4.5)
    └─→ Weekly Synthesis Agent (Opus 4.6)
```

Добавляются 2 агента:

#### 4. Content Writer Agent

**Задачи:**
- Генерация черновиков постов
- Применение копирайтинг-техник (AIDA, storytelling)
- Адаптация tone of voice для разных платформ
- Рефакторинг draft → published

**Инструменты:**
- Read, Edit, Write
- post-writing skill (из ваших скиллов)

**Модель:** Opus 4.6 (creative writing требует complex reasoning)

#### 5. Project Tracker Agent

**Задачи:**
- Синхронизация с YouGile (через MCP)
- Обновление статусов в проектных README
- Tracking метрик (часы/неделю, прогресс)
- Генерация project status reports

**Инструменты:**
- YouGile MCP tools
- Read, Edit
- Bash (git для коммитов)

**Модель:** Haiku 4.5 (рутинная работа с API)

---

## Workflow примеры

### Workflow 1: Обработка Inbox

```
1. User: "Обработай Inbox"
   ↓
2. Main Orchestrator → Knowledge Organizer Agent
   ↓
3. Knowledge Organizer:
   - Читает /000_Inbox/
   - Для каждого элемента:
     * Определяет категорию (Project/Area/Resource)
     * Добавляет frontmatter + tags
     * Создаёт связи [[]] с существующими заметками
     * Перемещает в правильную папку
   ↓
4. Knowledge Organizer → Main Orchestrator:
   "Обработано 8 элементов:
    - 3 → Projects (AGIents идеи)
    - 2 → Resources (ИИ-технологии)
    - 3 → Areas (Planning)"
   ↓
5. Main Orchestrator → User: Summary + git commit
```

### Workflow 2: Создание Weekly Synthesis

```
1. User: "Создай Weekly Synthesis за текущую неделю"
   ↓
2. Main Orchestrator:
   - Определяет даты (Feb 10-16, 2026)
   - Делегирует Weekly Synthesis Agent
   ↓
3. Weekly Synthesis Agent:
   a) Собирает данные:
      git log --since="2026-02-10" --until="2026-02-16" --stat

   b) Анализирует изменения:
      - Какие проекты были активны?
      - Какие файлы создавались/менялись?
      - Сколько постов опубликовано?

   c) Читает ключевые заметки:
      - README проектов (изменения за неделю)
      - Draft Posts → Published Posts (контент-активность)
      - Клиентские заметки (взаимодействия)

   d) Выявляет паттерны:
      - Emerging themes (что повторяется?)
      - Cross-project connections
      - Energy audit (энергетика задач)

   e) Генерирует структурированный синтез
   ↓
4. Weekly Synthesis Agent → Main Orchestrator:
   "Создан Weekly Synthesis - Week 7 (Feb 10-16, 2026).md"
   ↓
5. Main Orchestrator → User:
   "✅ Weekly Synthesis готов. Ключевые темы:
    1. Масштабирование через делегирование (ассистент)
    2. AGIents дедупликация (техдолг закрыт)
    3. Новый клиент (стоматология)"
```

### Workflow 3: Исследование для поста

```
1. User: "Исследуй тему 'AI agents in production 2026'"
   ↓
2. Main Orchestrator → Content Research Agent
   ↓
3. Content Research Agent:
   a) WebSearch: "AI agents production 2026 trends"
   b) Firecrawl: Top 5 результатов (scrape + extract)
   c) Анализ видео: YouTube "AI agents production" (Gemini Vision)
   d) Grep: Существующие заметки в Resources/

   e) Структурирует findings:
      ## AI Agents in Production - Research (2026-02-13)

      ### Key Trends
      - Multi-agent orchestration становится standard
      - 40% enterprise apps будут иметь AI agents к концу 2026
      - Shift от RAG к agentic workflows

      ### Key Players
      - LangChain Deep Agents
      - Microsoft Azure AI Foundry
      - Anthropic Claude Code

      ### Sources
      - [Article 1](url)
      - [Video: Matt from Futuretools](url)

      ### Recommended Angle for Post
      - Focus on orchestration patterns (ваш опыт AGIents)
      - Contrast no-code vs coded approaches
      - Real production metrics (90.2% improvement)
   ↓
4. Content Research Agent → Main Orchestrator:
   "Research complete. Created: 500_Research/550_AI/AI Agents in Production - Research 2026.md"
   ↓
5. Main Orchestrator → User:
   "✅ Исследование готово.
    Найдено: 3 key trends, 5 sources, 1 video analysis.
    Recommended angle: Orchestration patterns + AGIents case study."
```

---

## Интеграция с существующими skills

### Используйте существующие skills как building blocks

Ваши субагенты могут вызывать skills:

**Content Writer Agent + post-writing skill:**
```yaml
# В system_prompt Content Writer Agent
Для написания постов используй skill "post-writing":
- Применяй AIDA, storytelling, slippery slide
- Адаптируй tone of voice (LinkedIn профессиональный, Telegram более casual)
```

**Weekly Synthesis Agent + weekly-synthesis skill:**
```yaml
# Weekly Synthesis Agent может вызывать skill
При создании Weekly Synthesis используй существующий /weekly-synthesis skill
для соблюдения структуры и формата.
```

**Research Agent + web-research skill:**
```yaml
# Content Research Agent + web-research skill
Для комплексных исследований используй skill "web-research":
- Парсинг, поиск, анализ конкурентов, сбор данных
```

---

## Cost Optimization Dashboard

### Прогноз затрат (на основе вашей активности Week 6)

**Допущения:**
- 43 заметки создано/изменено за неделю
- 6 YouTube-выжимок
- 4 поста опубликовано
- 1 Weekly Synthesis
- 8 Inbox items обработано

**Распределение нагрузки:**

| Agent | Tasks/Week | Tokens/Task | Model | Cost/Week (est.) |
|-------|-----------|-------------|-------|------------------|
| **Main Orchestrator** | 50 queries | 5K avg | Sonnet 4.5 | $3.50 |
| **Content Research** | 10 researches | 20K avg | Sonnet 4.5 | $3.00 |
| **Knowledge Organizer** | 43 notes + 8 inbox | 2K avg | Haiku 4.5 | $0.40 |
| **Weekly Synthesis** | 1 synthesis | 50K | Opus 4.6 | $2.50 |
| **Total (Minimal)** | — | — | — | **~$9.40/week** |

**Расширенная версия:**

| Agent | Tasks/Week | Tokens/Task | Model | Cost/Week (est.) |
|-------|-----------|-------------|-------|------------------|
| **Content Writer** | 4 posts | 15K avg | Opus 4.6 | $3.00 |
| **Project Tracker** | 8 projects sync | 3K avg | Haiku 4.5 | $0.30 |
| **Total (Extended)** | — | — | — | **~$12.70/week** |

### Optimization рекомендации

1. **Knowledge Organizer на Haiku** — правильное решение (рутинная работа)
2. **Weekly Synthesis на Opus** — оправдано (deep reasoning)
3. **Content Research на Sonnet** — оптимально (balance)

**Potential savings:**
- Если Content Writer использовать Sonnet вместо Opus: -$1.50/week
- Но: качество creative writing может снизиться

---

## Roadmap внедрения

### Фаза 1: Validation (1-2 недели)

- [ ] **Создать Knowledge Organizer Agent**
  - Тестировать на Inbox (8-10 элементов)
  - Валидировать качество категоризации
  - Измерить: время экономии vs manual

**Success criteria:**
- 90%+ правильная категоризация
- Все frontmatter добавлены корректно
- Связи [[]] релевантные

### Фаза 2: Content Support (2-3 недели)

- [ ] **Создать Content Research Agent**
  - Тестировать на 2-3 темах для постов
  - Валидировать качество research
  - Измерить: глубина insights vs manual

**Success criteria:**
- Research сокращает время на пост на 30%+
- Минимум 3 quality sources на topic
- Рекомендации по angle релевантны

### Фаза 3: Deep Analysis (3-4 недели)

- [ ] **Создать Weekly Synthesis Agent**
  - Сгенерировать 1 Weekly Synthesis
  - Сравнить с manual synthesis
  - Валидировать: глубина инсайтов, связи между проектами

**Success criteria:**
- Quality сопоставимо с manual
- Обнаруживает 2-3 non-obvious connections
- Экономит 2+ часа на synthesis

### Фаза 4: Scale (опционально)

- [ ] **Добавить Content Writer Agent**
- [ ] **Добавить Project Tracker Agent**

---

## Альтернативный подход: Task-Based (без постоянных субагентов)

Вместо постоянных субагентов — создавать ad-hoc на каждую задачу.

**Пример:**
```bash
# Вместо pre-configured Knowledge Organizer Agent
# Создаёшь субагента on-the-fly:

/agents create
Name: inbox-processor-2026-02-13
Type: single-use
Model: haiku-4-5
Task: Process /000_Inbox/ - categorize, add frontmatter, create links
```

**Преимущества:**
- ✅ Гибкость (каждый раз уникальная настройка)
- ✅ Нет overhead на поддержку агентов
- ✅ Можно экспериментировать с промптами

**Недостатки:**
- ❌ Нет consistency (каждый раз "с нуля")
- ❌ Нет learning curve (агент не "запоминает" паттерны)
- ❌ Дольше setup на каждую задачу

**Рекомендация:** Используйте task-based для экспериментов (Фаза 1), затем переходите на persistent agents (Фазы 2-3).

---

## Ключевые выводы

### ✅ Рекомендуется (Minimal Setup)

**3 субагента:**
1. **Content Research Agent** (Sonnet 4.5) → исследования
2. **Knowledge Organizer Agent** (Haiku 4.5) → организация
3. **Weekly Synthesis Agent** (Opus 4.6) → глубокий анализ

**Почему:**
- Покрывает 80% задач Second Brain
- Cost-effective (~$9/week)
- Простая координация (3 агента < порог сложности)
- Каждый агент решает чёткую проблему

### 🎯 Следующие шаги

1. **Week 1:** Создать и протестировать Knowledge Organizer Agent
2. **Week 2:** Добавить Content Research Agent
3. **Week 3:** Добавить Weekly Synthesis Agent
4. **Week 4:** Evaluate результаты, decide on scaling

### 📊 Success Metrics

**Что измерять:**
- ⏱️ **Time saved** — сколько часов экономится/неделю
- 🎯 **Quality** — quality of outputs vs manual (1-5 scale)
- 💰 **Cost** — фактические затраты vs прогноз
- 🔄 **Reusability** — сколько раз агент переиспользуется

**Цели после 4 недель:**
- 5+ часов экономии/неделю
- Quality score 4+/5
- ROI 10x+ (время * hourly rate > cost)

---

## Связанные материалы

- [[Создание субагентов - полное руководство 2026]] — full guide
- [[Claude Code as Embedded OS - Gur Sannikov]] — per-model routing
- [[CLAUDE.md]] — конфигурация Second Brain
- `/skills/weekly-synthesis` — existing skill для интеграции
- `/skills/post-writing` — existing skill для интеграции
- `/skills/web-research` — existing skill для интеграции

---

*Создано: 2026-02-13*
*Статус: Active Recommendation*
*Для проекта: Second Brain (Obsidian + Claude Code)*

#subagents #second-brain #knowledge-management #automation #para
