# Применение GIST Framework к AGIents.pro

**Источники:**
- [[Product development framework]] - GIST Framework
- [[StartUP]] - бизнес-промпты

**Дата:** 2026-01-02

---

## GIST Framework Overview

**GIST** = Goals + Ideas + Steps + Tasks

Это product development framework из Google, который помогает:
- Фокусироваться на **outcomes** (не outputs)
- Валидировать гипотезы **перед** написанием кода
- Принимать решения на основе **данных** (не мнений)

---

## Goals - Цели для AGIents

### North Star Metric

**"Time-to-first-working-agent < 8 часов"**

**Почему это важно:**
- Измеримо
- Фокусирует на user value
- Приводит к конкретным улучшениям

### OKRs для Q1 2026

#### Objective 1: Подтвердить Product-Market Fit

**Key Results:**
1. 3-5 beta-клиентов активно используют платформу
2. NPS > 40
3. Retention > 60%
4. 80%+ готовы платить

#### Objective 2: MVP готов к публичному запуску

**Key Results:**
1. MVP с базовым функционалом завершен
2. 5-10 базовых блоков/действий работают
3. Bug count < 10 critical
4. Performance: API < 200ms, Uptime > 95%

### Metrics Tree для AGIents

```
North Star: Time-to-first-agent < 8ч
    ↓
├─ Setup time: регистрация → начало работы
├─ Building time: начало → первая версия агента
├─ Testing time: тестирование → success
└─ Publishing time: success → production

Supporting metrics:
├─ Feature adoption rate
├─ Error rate during creation
├─ Support requests per user
└─ Template usage %
```

---

## Ideas - Подходы для валидации

### Idea 1: Visual Workflow Builder

**Impact:** 9/10 (no-code - главная ценность)
**Confidence:** 5/10 (нужно тестирование)
**Ease:** 4/10 (сложная разработка)
**ICE Score:** 1.8

**Steps для валидации:**
1. Customer interviews (10+): хотят ли visual builder?
2. Fake button test: макет интерфейса
3. Clickable prototype: Figma
4. Person behind the curtain: вручную создать агента
5. Working prototype
6. Beta test

### Idea 2: Template-based Approach

**Impact:** 7/10 (быстро для юзера, но менее гибко)
**Confidence:** 7/10 (знаем что шаблоны нужны из Amaks)
**Ease:** 8/10 (проще чем visual builder)
**ICE Score:** 7.8

**Steps для валидации:**
1. Создать 3-5 шаблонов на основе Amaks
2. Landing page с шаблонами
3. A/B test: шаблоны vs пустой редактор
4. Measure: time-to-first-agent, success rate

### Idea 3: Conversational Builder (AI создает агента через диалог)

**Impact:** 8/10 (самый простой для пользователя)
**Confidence:** 3/10 (не уверены что LLM справится)
**Ease:** 6/10 (требует хорошего промптинга)
**ICE Score:** 1.6

**Steps для валидации:**
1. Wizard of Oz: человек играет роль AI
2. User testing: насколько удобно?
3. Prototype с LLM
4. Compare с Idea 1 и 2

### Приоритизация через ICE

| Idea | Impact | Confidence | Ease | ICE | Priority |
|------|--------|------------|------|-----|----------|
| Templates | 7 | 7 | 8 | 7.8 | **1** ✅ |
| Visual Builder | 9 | 5 | 4 | 1.8 | 2 |
| Conversational | 8 | 3 | 6 | 1.6 | 3 |

**Вывод:** Начать с **Templates**, потом добавить Visual Builder!

---

## Steps - Validation Pipeline

### Wide Spectrum Validation

**Философия:** Тестировать дешево → дорого, быстро → медленно

```
Low-fidelity ────────────────────────────→ High-fidelity
(быстро, дешево)                         (медленно, дорого)

1. Customer interviews (1-2 дня)
2. Fake button test (макеты) (1 день)
3. Landing page + email signup (3 дня)
4. Clickable prototype (1 неделя)
5. Person behind the curtain (1-2 недели)
6. Working prototype (2-4 недели)
7. Beta with real users (4-8 недель)
```

**КРИТИЧНО:** НЕ прыгать сразу на step 6-7!

### Confidence Meter

**Шкала 0-10:**
- **0-1:** Leadership opinion, thematic alignment
- **2-3:** Customer interviews, surveys
- **4-5:** Fake tests, prototypes, user testing
- **6-7:** Person behind curtain, wizard of oz
- **8-9:** Working prototype, closed beta
- **10:** Production A/B test, real usage data

**Правило:** НЕ писать production код пока Confidence < 5!

### AGIents Validation Plan (Q1)

#### Week 1-2: Low-fidelity (Target: Confidence 3)

- [x] Изучить GIST Framework
- [ ] 10+ customer interviews
  - Вопросы: Как сейчас создают агентов? Что сложно? Что хотят?
- [ ] Конкурентный анализ ([[Competitive Analysis]])
- [ ] Fake button test: показать 3 подхода (templates, visual, conversational)
- [ ] Landing page для email capture

**Exit criteria:** Confidence > 3, понимаем что users хотят

#### Week 3-4: Medium-fidelity (Target: Confidence 5)

- [ ] Clickable prototype (Figma) лучшего подхода
- [ ] User testing с 5-10 людьми
- [ ] Person behind curtain: вручную создать агента для Amaks 5-го санатория
- [ ] Measure: time-to-first-agent вручную

**Exit criteria:** Confidence > 5, готовы писать код

#### Week 5-8: High-fidelity (Target: Confidence 7)

- [ ] Working prototype (базовый функционал)
- [ ] Beta test с 3-5 клиентами
- [ ] Measure: реальные метрики (time, success rate, NPS)
- [ ] Iterations на основе фидбэка

**Exit criteria:** Confidence > 7, PMF валидирован

---

## Tasks - Конкретная реализация

### Week 1: Customer Development

**Tasks:**
1. Составить список из 20 потенциальных респондентов
2. Подготовить interview script (15-20 вопросов)
3. Провести 10 интервью (по 30-45 мин)
4. Анализ: паттерны, боли, желаемые features
5. Update Ideas на основе инсайтов

### Week 2: Fake Tests + Landing

**Tasks:**
1. Создать макеты 3 подходов (Figma)
2. Fake button test: показать 10 людям, собрать feedback
3. Landing page с описанием AGIents
4. Email capture форма + lead magnet
5. Ads для привлечения трафика ($100-200)

### Week 3: Prototyping

**Tasks:**
1. Clickable prototype в Figma (лучший подход)
2. User testing с 5 людьми
3. Итерации на основе фидбэка
4. Финализация концепции

### Week 4: Person Behind Curtain

**Tasks:**
1. Договориться с Amaks о 5-м санатории
2. Собрать требования
3. Вручную создать агента (как если бы платформа работала)
4. Measure: сколько времени заняло? Что сложно?
5. Анализ: что нужно автоматизировать?

---

## Применение StartUP промптов

### 1. Niche Navigator (Конкурентный анализ)

**Prompt:**
```
Act as a business coach

My skills are: Go, Python, ИИ-агенты, RAG, микросервисы, B2B SaaS, no-code платформы

Generate a list of business niches that combine some or all of these skills.

For each niche find the market sizing and perform a market competition analysis - provide a x/100 index for competition
```

**Применение:** Для [[Competitive Analysis]]

### 2. Business Strategist (BATON Framework)

**BATON для AGIents:**

- **Business:** No-code платформа для создания ИИ-агентов (B2B)
- **Audience:** Технические директора, product managers, соло-предприниматели
- **Tribe:** Email рассылка, community (Telegram), блог buildinpublic
- **Offer:**
  - Lead magnet: "Чек-лист запуска ИИ-агента за 1 день"
  - Tripwire: Starter план $49/мес
  - Core: Pro план $199/мес
  - Premium: Enterprise custom pricing
- **Network:** Scaling через partners (agency программа)

### 3. Sales Funnel

**AGIents Funnel:**

```
AWARENESS (Блог, Twitter, LinkedIn)
    ↓
INTEREST (Lead magnet: чек-лист)
    ↓
EMAIL CAPTURE (Tribe)
    ↓
EDUCATION (Email серия: 5 писем)
    ↓
TRIAL (14 дней бесплатно)
    ↓
TRIPWIRE (Starter $49 - 30% off для early)
    ↓
CORE (Pro $199 - upsell)
    ↓
PREMIUM (Enterprise - sales call)
```

### 4. Content Plan

**3 Content Pillars для блога:**

1. **Технические разборы** (40%)
   - Self-hosted ИИ
   - Go + Python архитектура
   - RAG системы
   - Агенты from scratch

2. **Бизнес-кейсы** (30%)
   - Кейс Amaks
   - Результаты клиентов
   - ROI от ИИ-автоматизации

3. **BuildInPublic** (30%)
   - Прогресс AGIents
   - Метрики роста
   - Lessons learned
   - Процессы

---

## Decision Framework

### Когда сомневаешься:

**Вопрос 1:** Какой Confidence level?
- Если < 3 → больше research
- Если 3-5 → prototyping и testing
- Если 5-7 → можно писать код
- Если 7-10 → scale и optimize

**Вопрос 2:** Как приоритизировать?
- ICE scoring (Impact × Confidence × Ease)
- Выбирать высокий ICE score
- Confidence важнее Impact (не билдим без уверенности)

**Вопрос 3:** Тратить ли время на feature X?
- Влияет ли на North Star Metric?
- Да → ICE scoring
- Нет → backlog (может later)

---

## Anti-Patterns (чего НЕ делать)

### ❌ Feature Factory

**Проблема:** Билдим features потому что "звучит круто"

**Решение:** Фокус на Goals и Metrics, не на features

### ❌ Building without Validation

**Проблема:** "Я знаю что users хотят" → 6 месяцев разработки → никто не использует

**Решение:** Wide Spectrum Validation, Confidence Meter

### ❌ Opinion-based Decisions

**Проблема:** "Мне кажется это хорошая идея"

**Решение:** Data-driven через Steps, измерение Confidence

### ❌ Premature Optimization

**Проблема:** Билдим scalable architecture до PMF

**Решение:** MVP сначала, scale потом

---

## Success Criteria для Q1

### Validation Success

- [x] GIST Framework изучен
- [ ] Confidence > 5 для выбранного подхода
- [ ] 3-5 beta клиентов используют MVP
- [ ] NPS > 40, Retention > 60%

### Business Success

- [ ] Готовы к публичному запуску (Q2)
- [ ] Pricing определен и протестирован
- [ ] Sales funnel работает
- [ ] Первые лиды из блога

### Learning Success

- [ ] Знаем что users реально хотят
- [ ] Понимаем product-market fit
- [ ] Можем предсказать unit economics
- [ ] Roadmap на Q2-Q3 ясен

---

## Quarterly Review Template

**End of Q1 Checkpoint (31 марта):**

### 1. Goals Review
- Достигли ли Key Results?
- North Star Metric: текущее значение?
- Что помешало? Что помогло?

### 2. Ideas Review
- Какие Ideas валидировали?
- ICE scores актуальны?
- Новые Ideas на основе learnings?

### 3. Confidence Review
- Confidence level по ключевым гипотезам?
- Где нужно больше evidence?
- Готовы ли к Q2?

### 4. Adaptation
- Что менять в Q2 стратегии?
- Pivot нужен?
- Scaling готовы или еще рано?

---

## Связанные материалы

- [[Product development framework]] - полный GIST
- [[StartUP]] - промпты для бизнеса
- [[MVP Specification]] - применение GIST
- [[Product Roadmap]] - Goals по кварталам
- [[Competitive Analysis]] - использование Niche Navigator
- [[Годовой план 2026]] - общая стратегия

---

*Создано: 2026-01-02*
*Статус: Framework готов к применению*

**Next:** Начать Week 1 validation tasks!
