# Week 1 Action Checklist (6-12 января 2026)

**Статус:** 🟡 В процессе
**Цель недели:** Foundation setup - запустить tracking, начать research, опубликовать первый пост

---

## ✅ Завершено

- [x] Создать годовой план 2026
- [x] Создать структуру папок в second-brain
- [x] Мигрировать ключевые материалы из OLD_VAULT
- [x] Определить метрики и North Star Metric
- [x] Создать Setup Tracking план
- [x] Создать Professional справку для B2B
- [x] Создать Google Sheet template
- [x] **Конкурентный анализ завершен** (16 платформ, Confidence 7/10)
- [x] **Google Sheet "AGIents Metrics Q1" настроен**
- [x] **Первый пост в блоге опубликован**
- [x] **Weekly Review Week 1 внесен в Google Sheet**

---

## 🎯 СЕГОДНЯ (3-4 января) - Priority 1

### 1. Setup Google Sheet для tracking (15-20 минут)

**Что делать:**
1. Открыть Google Sheets: https://sheets.google.com
2. Создать новый файл: "AGIents Metrics Q1 2026"
3. Скопировать структуру из файла `Google Sheet Template - AGIents Metrics Q1 2026.md`
4. Создать 4 листа (tabs):
   - Weekly Summary
   - User Details
   - Confidence Meter
   - OKRs Tracking
5. Внести первую запись для Week 1
6. Добавить в закладки браузера
7. Поделиться ссылкой (можно в Notes где-то сохранить)

**Результат:** Готовая таблица для еженедельного tracking

**Файл-источник:** `Google Sheet Template - AGIents Metrics Q1 2026.md`

---

### 2. Setup Google Calendar Reminder (2 минуты)

**Что делать:**
1. Открыть Google Calendar
2. Создать recurring event:
   - **Название:** "AGIents Metrics Weekly Review"
   - **Когда:** Каждый понедельник 9:00
   - **Повтор:** Еженедельно
   - **Описание:**
     ```
     1. Открыть Google Sheet "AGIents Metrics Q1 2026"
     2. Обновить Weekly Summary
     3. Проверить OKRs progress
     4. Записать insights

     Link: [вставить ссылку на Sheet]
     ```
3. Добавить напоминание за 10 минут

**Результат:** Автоматический reminder каждый понедельник

---

### 3. Внести первую запись в Sheet (5 минут)

**Данные для Week 1 (06.01-12.01):**

**Weekly Summary:**
- Beta Users: 0
- Agents Created: 0
- Completion %: -
- Email List: 0
- Blog Traffic: 0
- Notes: "План создан, справка готова, tracking setup, начат competitive analysis"

**Confidence Meter:** (уже есть в template)
- Templates-first: 2/10
- < 8h achievable: 3/10
- RAG essential: 7/10

**OKRs:** Все на 0% - это нормально для Week 1

**Результат:** Baseline для отслеживания прогресса

---

## 📅 ЭТА НЕДЕЛЯ (6-12 января) - Priority 2

### 4. Начать конкурентный анализ (3-4 часа)

**Шаг 1: Использовать Niche Navigator промпт (1 час)**

1. Открыть `/500_Research/560_Business_Models/StartUP.md`
2. Найти промпт "Niche Navigator"
3. Запустить с вашими навыками:
   ```
   Act as a business coach

   My skills are: Go, Python, ИИ-агенты, RAG-системы, микросервисы,
   B2B SaaS, no-code платформы, self-hosted решения

   Generate a list of business niches that combine some or all of these skills.

   For each niche find the market sizing and perform a market competition
   analysis - provide a x/100 index for competition
   ```
4. Сохранить результат в `Research/Competitive Analysis.md`

**Шаг 2: Глубокий анализ конкурентов (2-3 часа)**

Проанализировать каждого из списка в `Research/Competitive Analysis.md`:
- n8n.io
- Make (Integromat)
- Zapier AI
- Voiceflow
- Botpress
- Landbot
- Chatfuel
- ManyChat

**Что анализировать:**
1. Pricing (сколько стоит, какие планы)
2. Key Features (что умеют, что не умеют)
3. Target Audience (кому продают)
4. Differentiators (чем выделяются)
5. Weaknesses (где слабые места)

**Обновить файл:** `Research/Competitive Analysis.md`

**Результат:** Понимание конкурентного ландшафта

---

### 5. Setup Plausible для блога (10-15 минут)

**Prerequisite:** Нужен URL блога

**Что делать:**
1. Зарегистрироваться на https://plausible.io
2. Добавить сайт блога
3. Получить tracking script
4. Добавить в `<head>` блога:
   ```html
   <script defer data-domain="yourdomain.com"
           src="https://plausible.io/js/script.js"></script>
   ```
5. Настроить Goals:
   - Email signup
   - AGIents beta signup
   - Post read (scroll depth)
6. Проверить что tracking работает

**Cost:** $9/month (или 30-day trial)

**Результат:** Можно отслеживать Blog Traffic в Google Sheet

**Связанный файл:** `Setup Tracking - Action Plan.md` (Action 2)

---

### 6. Setup ConvertKit для email (20-30 минут)

**Что делать:**
1. Зарегистрироваться на https://convertkit.com
2. Создать signup форму
3. Создать Landing page для lead magnet (или позже)
4. Настроить email автоматизацию:
   - Welcome email
   - 5-email sequence про AGIents (можно написать позже)
5. Интеграция signup формы с блогом
6. Тест: подписаться самому, проверить что работает

**Cost:** $0 (free до 1,000 subscribers)

**Результат:** Можно отслеживать Email List в Google Sheet

**Связанный файл:** `Setup Tracking - Action Plan.md` (Action 3)

---

### 7. Опубликовать первый пост блога (1-2 часа)

**Что делать:**
1. Пост "Claudesidian" уже готов в Draft Posts
2. Финальная вычитка
3. Добавить:
   - Meta description
   - Tags/Categories
   - Call-to-action (подписаться на email)
4. Опубликовать
5. Анонсировать в Telegram канале (если есть)

**Результат:** Первый контент опубликован, начинается тестирование Blog Traffic tracking

**Файл:** `/300_Blog/350_Draft_Posts/2026-01-02 Claudesidian - Claude Code + Obsidian.md`

---

## 📋 Опционально (если успеешь)

### 8. Customer Interviews - подготовка

**Что делать:**
1. Составить список 20 потенциальных респондентов:
   - Существующие клиенты AGIency (Amaks contacts)
   - Знакомые технические директора
   - Community контакты
2. Подготовить interview script (15-20 вопросов):
   - Как сейчас создают/используют ботов/агентов?
   - Какие боли?
   - Что хотели бы улучшить?
   - Готовы ли платить за платформу?
3. Начать outreach (цель: 10 интервью в январе)

**Связанный файл:** `/500_Research/560_Business_Models/Применение GIST к AGIents.md` (Week 1 Tasks)

---

### 9. Второй пост блога (2-3 часа)

**Идея:** "Обо мне" пост уже в Draft Posts

**Что делать:**
1. Финальная вычитка
2. Возможно добавить:
   - Фото (если нужно)
   - Ссылки на проекты
3. Опубликовать
4. Анонс

**Цель Q1:** 2 поста/неделю

**Файл:** `/300_Blog/350_Draft_Posts/2026-01-02 Обо мне.md`

---

## 📊 Success Metrics для Week 1

**Минимальный success:**
- ✅ Google Sheet создан и первая запись внесена
- ✅ Weekly review reminder настроен
- ✅ Начат competitive analysis (хотя бы список конкурентов)
- ✅ 1 пост опубликован (Claudesidian)

**Отличный success:**
- ✅ Все вышеперечисленное +
- ✅ Plausible setup готов
- ✅ ConvertKit setup готов
- ✅ Competitive analysis завершен
- ✅ 2 поста опубликовано
- ✅ Начаты customer interviews outreach

---

## ⏱️ Оценка времени

**Priority 1 (сегодня):**
- Google Sheet: 15-20 мин
- Calendar reminder: 2 мин
- Первая запись: 5 мин
- **Итого: ~30 минут**

**Priority 2 (эта неделя):**
- Competitive analysis: 3-4 часа
- Plausible setup: 10-15 мин
- ConvertKit setup: 20-30 мин
- Первый пост: 1-2 часа
- **Итого: ~5-7 часов**

**Опционально:**
- Customer interviews prep: 2-3 часа
- Второй пост: 2-3 часа
- **Итого: ~4-6 часов**

**Total Week 1:** 10-15 часов (укладывается в плановые 10-15ч/нед для AGIents)

---

## 🔗 Связанные материалы

- [[Годовой план 2026]] - общий контекст Week 1
- [[Setup Tracking - Action Plan]] - детали tracking setup
- [[Google Sheet Template - AGIents Metrics Q1 2026]] - template для копирования
- [[Research/Competitive Analysis]] - куда вносить анализ
- [[Research/MVP Specification]] - GIST Framework применение
- [[Применение GIST к AGIents]] - детали validation плана

---

## 📝 Notes & Learnings

_Записывать сюда инсайты и заметки по ходу выполнения Week 1 tasks_

**2 января:**
- План создан
- Tracking setup определен
- Готовы к старту

---

*Создано: 2 января 2026*
*Обновлено: -*
*Следующий review: 13 января 2026 (Week 2)*
