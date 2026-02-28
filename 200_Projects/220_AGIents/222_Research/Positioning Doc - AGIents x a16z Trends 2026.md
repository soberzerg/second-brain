---
created: 2026-02-17
type: positioning
status: draft
tags:
  - agients
  - positioning
  - a16z
  - strategy
based_on:
  - "[[a16z Big Ideas 2026 - Andreessen Horowitz Predictions]]"
  - "[[Competitive Analysis - Synthesis]]"
---

# AGIents.pro Positioning Doc
## Agentic Infrastructure for the Post-AI Era

**Версия:** 1.0 | **Дата:** 17 февраля 2026

---

## TL;DR

a16z назвал 2026 годом agentic infrastructure, multi-agent orchestration и enterprise data cleanup. AGIents.pro находится в эпицентре всех трёх трендов. Этот документ фиксирует позиционирование платформы на стыке подтверждённых рыночных сдвигов и выявленных конкурентных gap'ов.

---

## 1. Рыночный контекст: что говорит a16z

### Три мегатренда, которые определяют наш рынок

| # | Тренд a16z | Суть | Релевантность |
|---|-----------|------|---------------|
| 3 | Инфраструктура под агентов | Legacy = DDoS от 1 агента с 5000 подзадачами. Нужна agentic-native архитектура | КРИТИЧНО |
| 6 | Мультиплеер-AI | Агенты взаимодействуют друг с другом. Юрист-AI + CFO-AI = сетевые эффекты | КРИТИЧНО |
| 1 | Хаос корпоративных данных | 80% знаний неструктурировано. RAG галлюцинирует. Кто очистит данные = получит enterprise | КРИТИЧНО |

### Поддерживающие тренды

| # | Тренд | Как усиливает AGIents |
|---|-------|----------------------|
| 5 | AI-нативный стек данных | Векторные БД, семантические слои = must-have для agent platform |
| 7 | Интерфейсы для агентов, не людей | API-first > красивый UI. Агенты должны быть consumable другими агентами |
| 8 | Конец screen time | Метрика = business outcomes, не вовлечённость |
| 11 | Персонализация | Каждый агент адаптируется под клиента |

---

## 2. Positioning Statement

### Основной

> **AGIents.pro — agentic-native платформа для создания, оркестрации и self-hosting ИИ-агентов. Единственное решение, объединяющее workflow automation, conversational AI и multi-agent orchestration в одном продукте — по доступной цене и с возможностью развёртывания на своих серверах.**

### Короткий (для pitch)

> **"Agentic infrastructure для тех, кто не может позволить себе ждать, пока Make добавит агентов, а Stack AI снизит цены."**

### Для российского рынка

> **"Первая российская платформа для создания ИИ-агентов: no-code, self-hosted, с интеграцией в Telegram, AmoCRM и Битрикс24."**

---

## 3. Почему именно сейчас

### Окно возможностей (по a16z)

```
2024          2025            2026            2027
│             │               │               │
├─ ChatGPT    ├─ RAG hype     ├─ AGENTIC ERA  ├─ Multi-agent
│  hype       │  peak         │  ★ WE ARE     │  mainstream
│             │               │    HERE        │
├─ Single     ├─ AI wrappers  ├─ Infra shift  ├─ Consolidation
│  model      │  everywhere   │  Legacy fails  │
│  focus      │               │               │
```

**Ключевой сигнал:** Вертикальные AI-компании уже на $100M+ ARR (Hebbia, EliseAI, Basis). Следующая волна — платформы для оркестрации, а не одиночные агенты.

### Почему legacy не справляется

a16z прямо говорит: один AI-агент генерирует 5000 подзадач за миллисекунды. Для старых систем это DDoS.

**AGIents построен agentic-native:**
- go-kratos + NATS = высокий параллелизм из коробки
- Не адаптация legacy, а архитектура с нуля под agentic workloads
- Self-hosted = контроль над инфраструктурой

---

## 4. Конкурентный ландшафт через призму a16z

### Матрица: кто готов к agentic era

| Платформа | Agentic Infra (#3) | Multi-Agent (#6) | Data Cleanup (#1) | Self-hosted | Цена |
|-----------|:-------------------:|:----------------:|:------------------:|:-----------:|:----:|
| **AGIents.pro** | ✅ Native | ✅ Roadmap Q1 | ✅ Planned | ✅ | $$ |
| Make | ❌ Workflow only | ❌ | ❌ | ❌ | $ |
| n8n | ⚠️ Adapted | ❌ | ❌ | ✅ | $-$$$ |
| Voiceflow | ⚠️ Chat only | ❌ | ⚠️ KB only | ❌ | $$-$$$ |
| Stack AI | ✅ | ⚠️ Limited | ✅ | ❌ | $$$$ |
| Botpress | ⚠️ | ❌ | ⚠️ | ⚠️ Enterprise | $$$ |
| Dify.ai | ✅ | ⚠️ | ⚠️ | ✅ | $-$$ |

**Вывод:** Ни один конкурент не закрывает все три мегатренда a16z одновременно, оставаясь доступным и self-hosted.

### Главный конкурент для отслеживания: Dify.ai

- Open-source, production-ready, agentic workflows
- Но: нет conversational UI focus, нет российского рынка, community-driven (не product-led)
- Наш ответ: industry templates + русский рынок + unified platform (workflow + chat + agents)

---

## 5. Четыре столпа позиционирования

### Столп 1: Agentic-Native Infrastructure

**Что это значит:**
- Архитектура спроектирована для агентов, а не адаптирована из workflow engine
- 5000+ параллельных задач от одного агента — штатная работа, не DDoS
- go-kratos + NATS = горизонтальное масштабирование

**Proof points:**
- [ ] Нагрузочный тест: 5000 параллельных задач, <2s latency
- [ ] Whitepaper: "Why Legacy Systems Fail at Agentic Workloads"
- Amaks: 4 санатория, real-time бронирование через агента

**Против конкурентов:**
- Make/Zapier: workflow engine, не agent runtime
- n8n: execution model 1-запрос-1-процесс

---

### Столп 2: Multi-Agent Orchestration

**Что это значит:**
- Агенты взаимодействуют друг с другом через стандартный протокол
- Юрист-AI + CFO-AI + Sales-AI = экосистема, не набор чатботов
- Marketplace агентов с возможностью коллаборации

**Roadmap:**
1. Q1 2026: Agent-to-agent communication protocol
2. Q2 2026: Marketplace агентов
3. Q3 2026: Cross-company agent collaboration

**Против конкурентов:**
- Voiceflow/Botpress: один бот на один use case
- Stack AI: multi-agent, но $2000+/мес
- AGIents: multi-agent для SMB по $50-200/мес

---

### Столп 3: Data-Ready Platform

**Что это значит:**
- Встроенные инструменты для очистки и структурирования данных клиента
- Векторные БД как first-class citizens (не add-on)
- RAG, который не галлюцинирует (data quality > model quality)

**Подход:**
- Data ingestion pipeline: PDF, видео, логи, скриншоты -> структурированные данные
- Quality scoring: агент показывает уверенность в ответе
- Data audit: клиент видит, какие данные "грязные" и что нужно исправить

**Против конкурентов:**
- Make/n8n: нет RAG, нет data layer
- Voiceflow: Knowledge Base, но без data cleaning
- Stack AI: enterprise data integration, но $2000+

---

### Столп 4: Self-Hosted & Sovereign

**Что это значит:**
- Docker Compose setup за 5 минут — не только для enterprise
- Data sovereignty: данные клиента никуда не уходят
- Обход санкционных ограничений для российского рынка
- No vendor lock-in

**Pricing:**
- Cloud: $49-199/мес (для тех, кому удобнее)
- Self-hosted: free community edition + $99/мес Pro license
- Enterprise: custom pricing, SLA, white-label

**Против конкурентов:**
- Make/Zapier/Voiceflow: cloud-only
- n8n: self-hosted есть, но сложно + дорогой cloud
- Stack AI: self-hosted только enterprise tier

---

## 6. Целевые сегменты (обновлённые)

### Primary: Российские B2B компании

**Почему (a16z lens):**
- Нулевая конкуренция в agentic platforms
- Санкции = спрос на self-hosted
- Тренд #11 (персонализация): российские компании хотят агентов "под себя"

**ICP (Ideal Customer Profile):**
- 50-500 сотрудников
- Есть рутинные процессы с клиентами (бронирование, консультации, support)
- IT-бюджет 50-200K RUB/мес на автоматизацию
- Примеры: сети отелей, клиники, юрфирмы, e-commerce

### Secondary: Privacy-Conscious Technical Teams (Global)

**Почему (a16z lens):**
- Тренд #3: им нужна agentic infra, а не ещё один SaaS
- Тренд #7: API-first, machine-readable agents
- Self-hosted = их язык

**ICP:**
- Стартапы и mid-market (50-200 employees)
- Есть DevOps/инфра-команда
- Работают с sensitive data (fintech, healthtech, legal)
- Frustration с Zapier pricing или n8n complexity

### Tertiary: AI Agencies & Consultants

**Почему:**
- AGIency.pro = proof of concept
- White-label потенциал
- Каждый agency = канал дистрибуции

---

## 7. Messaging Framework

### Для лендинга / homepage

**Headline:** Создавайте ИИ-агентов, которые работают вместе

**Subheadline:** No-code платформа для оркестрации AI-агентов. Workflow automation + Conversational AI + Multi-agent collaboration. Self-hosted или облако.

**CTA:** Запустить первого агента бесплатно

### Для инвесторов / pitch

**Проблема:** a16z прогнозирует, что legacy-системы не справятся с agentic workloads. Один агент = 5000 параллельных задач. Рынок enterprise AI agents растёт, но решения либо слишком дорогие ($2000+/мес), либо слишком простые (чатбот != агент).

**Решение:** AGIents.pro — agentic-native платформа, которая объединяет workflow, conversational AI и multi-agent orchestration. Self-hosted. Доступная цена. Русский рынок с нулевой конкуренцией.

**Traction:** 4 санатория Amaks на платформе. Active leads от enterprise-клиентов.

**Ask:** [TBD]

### Для технического блога (AISobolev)

**Angle:** "a16z вложил миллиарды в agentic infrastructure. Вот почему я строю AGIents.pro именно сейчас."

**Ключевые тезисы:**
1. Legacy-системы ломаются от агентов — я видел это у клиентов
2. Multi-agent — это не фантастика, это уже происходит (Hebbia $100M ARR)
3. Почему go-kratos + NATS, а не Python + Redis
4. Self-hosted — не прихоть, а необходимость (особенно в РФ)

---

## 8. Competitive Battlecards (обновлённые через a16z)

### AGIents vs Make

| | Make | AGIents |
|---|---|---|
| **Категория** | Workflow automation | Agentic platform |
| **a16z Readiness** | ❌ Не готов к agentic era | ✅ Agentic-native |
| **Multi-agent** | ❌ Нет | ✅ Протокол + marketplace |
| **AI Agents** | ⚠️ Через HTTP nodes | ✅ Native, с RAG |
| **Self-hosted** | ❌ | ✅ |
| **Когда выбирать Make** | Простые автоматизации без AI |
| **Когда выбирать AGIents** | Нужны агенты, не просто workflow |

### AGIents vs n8n

| | n8n | AGIents |
|---|---|---|
| **Категория** | Developer-first automation | Agentic platform for everyone |
| **a16z Readiness** | ⚠️ Адаптируется | ✅ Agentic-native |
| **Сложность** | Высокая (код) | Низкая (templates + visual) |
| **Conversational AI** | ❌ Нет | ✅ Native |
| **Цена self-hosted** | Бесплатно (community) | Free community + $99 Pro |
| **Когда выбирать n8n** | Devops-команда, нужна max гибкость |
| **Когда выбирать AGIents** | Нужны агенты без программирования |

### AGIents vs Stack AI

| | Stack AI | AGIents |
|---|---|---|
| **Категория** | Enterprise AI agents | SMB-friendly agentic platform |
| **Цена** | $2000+/мес | $49-199/мес |
| **Self-hosted** | Enterprise only | Все планы |
| **Рынок** | Fortune 500 | SMB + Mid-market |
| **Когда выбирать Stack AI** | Enterprise с бюджетом, нужен SOC2/HIPAA |
| **Когда выбирать AGIents** | SMB, нужно быстро и доступно |

---

## 9. Action Plan

### Неделя 1-2 (февраль 2026)

- [ ] Нагрузочный тест: 5000 параллельных задач через NATS
- [ ] Драфт whitepaper: "Agentic Infrastructure vs Legacy Systems"
- [ ] Пост в блог AISobolev: "a16z и почему я строю AGIents"
- [ ] Обновить лендинг AGIents.pro с новым positioning

### Месяц 1 (март 2026)

- [ ] MVP agent-to-agent communication protocol
- [ ] Data ingestion pipeline: PDF -> structured data
- [ ] 3 industry templates (отели, клиники, support)
- [ ] Pitch deck с a16z validation

### Q1 2026 (до конца марта)

- [ ] Публичный whitepaper
- [ ] 5+ клиентов на новом positioning
- [ ] Multi-agent demo: 2 агента коллаборируют
- [ ] Векторная БД интеграция (Qdrant)

---

## 10. Метрики успеха positioning

| Метрика | Текущее | Цель Q1 | Цель Q2 |
|---------|---------|---------|---------|
| MRR | ~$1K | $5K | $15K |
| Клиенты | 1 (Amaks) | 5-10 | 20-30 |
| Whitepaper downloads | 0 | 100 | 500 |
| "Agentic platform" mentions (SEO) | 0 | 10 | 50 |
| Self-hosted installations | 0 | 20 | 100 |

---

## Связанные заметки

- [[a16z Big Ideas 2026 - Andreessen Horowitz Predictions]]
- [[Competitive Analysis - Synthesis]]
- [[MVP Specification]]
- [[Product Roadmap]]

---

*Документ создан: 17 февраля 2026*
*Следующий review: после нагрузочного теста и whitepaper драфта*
