# Презентация: Переход от вайбкодинга к Agentic Engineering

**Для:** Команда Dogovor24 (Занятие 1 курса AI Coding Training)
**Автор:** Сергей Соболев
**Дата:** Февраль 2026
**Источник:** [Andrej Karpathy, X/Twitter, 4 февраля 2026](https://x.com/karpathy/status/2019137879310836075)

---

## Слайд 1: Титульный

**Переход от Vibe Coding к Agentic Engineering**

_Как за один год изменился подход к разработке с ИИ_

Сергей Соболев | AI Coding Training | Февраль 2026

> "The goal is to claim the leverage from the use of agents but without any compromise on the quality of the software."
> — Andrej Karpathy, 4 февраля 2026

---

## Слайд 2: Один твит — и всё началось

**3 февраля 2025 — Karpathy вводит термин "Vibe Coding"**

> "There's a new kind of coding I call 'vibe coding', where you fully give in to the vibes, embrace exponentials, and forget that the code even exists."

- 6.7 миллионов просмотров
- Collins Dictionary — Word of the Year 2025
- 25% стартапов Y Combinator W25 — кодовая база на 95% написана ИИ

**Что случилось:** Karpathy случайно дал имя тому, что чувствовали миллионы разработчиков одновременно.

---

## Слайд 3: Что такое Vibe Coding?

**Описать → Сгенерировать → Принять → Надеяться на лучшее**

- Ты говоришь ИИ что хочешь на естественном языке
- ИИ генерирует код
- Ты нажимаешь Accept All
- Если работает — отлично. Если нет — кидаешь ошибку обратно в чат

**Идеально для:**
- Прототипы за вечер
- Демо для коллег
- Weekend side projects

**Проблема:**
- Security-уязвимости (+40% vs. ручная разработка, данные METR)
- Архитектурные решения, которые ломаются при масштабировании
- Edge cases, которые модель не рассматривала
- Технический долг, который растёт с каждой итерацией

**"It was good fun and it almost worked."** — Karpathy

---

## Слайд 4: Год спустя — что изменилось

**4 февраля 2026 — Karpathy предлагает новый термин**

| Было (2025) | Стало (2026) |
|---|---|
| LLM "почти работали" | LLM стали значительно умнее |
| Fun throwaway projects | Default workflow для профессионалов |
| "Забудь что код существует" | Oversight и scrutiny обязательны |
| Vibe Coding | **Agentic Engineering** |

> "Programming via LLM agents is increasingly becoming a default workflow for professionals, except with more oversight and scrutiny."

**Ключевое:** разрыв между "почти работает" и "работает в продакшене" — это и есть разница между vibe coding и agentic engineering.

---

## Слайд 5: Что такое Agentic Engineering?

Karpathy разбивает термин на две части:

**Agentic** (агентный)
- 99% времени вы НЕ пишете код напрямую
- Вы оркестрируете агентов, которые пишут код
- Вы выступаете как oversight — контроль и ревью

**Engineering** (инженерия)
- Это наука и искусство, а не магия
- Этому можно научиться и стать лучше
- Есть своя глубина, "of a different kind"

**Формула:**
```
Определить цель → Обсудить план с агентом → Подтвердить направление →
ИИ-команда выполняет → Ревью архитектуры и результатов → Merge
```

---

## Слайд 6: Три эволюции AI-кодинга

**2021 — Autocomplete (Copilot)**
- ИИ предсказывает следующую строку
- Разработчик пишет, ИИ ускоряет
- Как автозамена в телефоне

**2023-2025 — Chat & Vibe Coding (Cursor, ChatGPT)**
- Описываешь фичу → ИИ генерирует код
- Copy-paste, Accept All
- Быстро, весело, хрупко

**2025-2026 — Agentic Engineering (Claude Code, Codex)**
- Говоришь: "Хочу авторизацию через Google"
- Агент планирует → пишет → тестирует → находит баг → чинит → тестирует снова
- Автономный цикл: reason → act → observe → reason again
- Разработчик = менеджер ИИ-команды

---

## Слайд 7: Vibe Coding vs Agentic Engineering — сравнение

| Аспект | Vibe Coding | Agentic Engineering |
|---|---|---|
| **Цель** | Сделать чтобы работало | Продакшен-качество без компромиссов |
| **Кейсы** | Демо, прототипы | Production, enterprise |
| **Workflow** | Describe → Generate → Accept | Architect → Orchestrate → Test → Review |
| **Планка качества** | "Почти работает" | "Соответствует стандартам" |
| **Роль инженера** | Prompt writer + patcher | Архитектор + оркестратор + ревьюер |
| **Security** | +40% уязвимостей | Системный ревью + автосканирование |
| **Обучаемость** | Низкий порог входа | Требует экспертизы и опыта |

---

## Слайд 8: Эволюция разработчика сейчас

**Уровни использования ИИ:**

**Level 1: Стажёр** — для обучения

- Изучение незнакомых библиотек, паттернов, объяснение кода
- Сhat mode
- Понимание legacy кода

**Level 2: AI-Powered** — для небольших задач

- Prompt Engineering
- Генерация boilerplate, schemas, тестов
- Chat/Agent mode
- Генерация методов, классов - окруженных контекстом, максимум конкретики, что нужно делать

**Level 3: Менеджер AI-агентов** — для сложных задач

- Context engineering
- Spec-first подход: spec.md → plan → реализация по частям
- Тесты, как часть работы и самопроверки агента
- Ручной AI-код-ревью перед загрузкой коммитов
- Security review обязателен

**Level 4: Архитектор AI-системы** — для стабильного воспроизведения результата

Создание окружения, для работы всей команды с ИИ-агентами:

- Инструкции для агентов (CLAUDE.md, AGENTS.md, и тд)
- Навыки агентов (плагины, команды, субагенты и тд)
- Описанный и поставленный процесс улучшения окружения (инструкций, навыков), за счёт обратной связи от разработчиков
- AI-код-ревью на каждом PR - как часть CI/CD
- Создание сложных фичей (несколько микросервисов, или бэк+фронт) "с одного промта"

**Workflow для каждой фичи:**
```
spec.md → project plan → test-first → итерации (commit каждый chunk) →
AI code review → security check → merge
```

---

## Слайд 9: Навыки Agentic Engineer

**Из "пишу код" → "управляю ИИ-командой"**

1. **Prompt Engineering → Solution Architecture**
   - Не "напиши функцию", а "спроектируй систему уведомлений"
   - Чёткость требований = качество результата

2. **Написание кода → Code Review at Scale**
   - Распознавание паттернов в AI-коде
   - Знание типичных ошибок моделей
   - Отлов архитектурного дрейфа

3. **Отладка → Дизайн Feedback Loop**
   - Не "это неправильно", а "вот почему этот подход не масштабируется, попробуй такой паттерн"
   - Обновление инструкций, навыков агентов, когда видишь, где они "застревают" или ломаются

4. **Тестирование → Continuous Validation**
   - Unit, integration, E2E — автоматизация
   - Pre-commit hooks, CI/CD pipeline
   - Quality gates, которые ловят ошибки агентов

**Правило: Never commit code you can't explain**

---

## Слайд 10: Что дальше?

**Karpathy:**
> "In 2026, we're likely to see continued improvements on both the model layer and the new agent layer. I feel excited about the product of the two and another year of progress."

**Прогресс компоундится:**
- Модели становятся умнее → длиннее автономные сессии, меньше ошибок
- Инструменты оркестрации улучшаются → мультиагентность, специализация
- Вместе → экспоненциальный рост возможностей

**Для нас с вами:**
- Vibe coding — это прошлое. Весело, но непригодно для продакшена
- Agentic Engineering — настоящее. Leverage без компромиссов
- Тот кто освоит этот подход — будет строить системы, которые раньше требовали целых команд

**Вопрос не в том, использовать ли ИИ. Вопрос — научитесь ли вы делать это правильно.**

---

## Источники

1. [Andrej Karpathy — Vibe Coding retrospective (4 февраля 2026)](https://x.com/karpathy/status/2019137879310836075)
2. [Andrej Karpathy — original Vibe Coding tweet (3 февраля 2025)](https://x.com/karpathy/status/1886192184808149383)
3. [The New Stack — "Vibe coding is passé"](https://thenewstack.io/vibe-coding-is-passe/)
4. [TeamDay — "From Vibe Coding to Agentic Engineering"](https://www.teamday.ai/blog/vibe-coding-to-agentic-engineering)
5. [WenHao Yu — "Agentic Coding: One Year from Vibes to Agentic Engineering"](https://yu-wenhao.com/en/blog/agentic-coding/)
6. [Business Insider — "Agentic Engineering" coined by Karpathy](https://www.businessinsider.com/agentic-engineering-andrej-karpathy-vibe-coding-2026-2)
7. METR — исследование безопасности AI-кода
