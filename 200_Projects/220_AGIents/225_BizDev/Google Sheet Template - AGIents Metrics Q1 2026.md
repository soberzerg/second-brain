# Google Sheet Template: AGIents Metrics Q1 2026

**Назначение:** Ручное отслеживание метрик для быстрого старта
**Обновление:** Каждый понедельник 9:00
**Создано:** 2 января 2026

---

## Инструкция по созданию

1. Создать новый Google Sheet: "AGIents Metrics Q1 2026"
2. Создать 4 листа (tabs) с названиями ниже
3. Скопировать структуру таблиц
4. Добавить в закладки браузера
5. Настроить Google Calendar reminder: каждый понедельник 9:00

---

## Sheet 1: Weekly Summary

**Колонки:**

| Week | Dates | Beta Users | Agents Created | Completion % | Email List | Blog Traffic | Notes |
|------|-------|------------|----------------|--------------|------------|--------------|-------|
| 1 | 06.01-12.01 | 0 | 0 | - | 0 | 0 | План создан, tracking setup |
| 2 | 13.01-19.01 | | | | | | |
| 3 | 20.01-26.01 | | | | | | |
| 4 | 27.01-02.02 | | | | | | |
| 5 | 03.02-09.02 | | | | | | |
| 6 | 10.02-16.02 | | | | | | |
| 7 | 17.02-23.02 | | | | | | |
| 8 | 24.02-02.03 | | | | | | |
| 9 | 03.03-09.03 | | | | | | |
| 10 | 10.03-16.03 | | | | | | |
| 11 | 17.03-23.03 | | | | | | |
| 12 | 24.03-30.03 | | | | | | |
| 13 | 31.03 | | | | | | Q1 ЗАВЕРШЕН |

**Формулы для добавления:**
- В столбце "Week" можно добавить условное форматирование: текущая неделя = зеленый
- Для роста: `=B3-B2` (разница с прошлой неделей)

---

## Sheet 2: User Details

**Колонки:**

| User ID | Name | Email | Signup Date | First Agent Date | Time-to-first (hours) | Status | NPS | Notes |
|---------|------|-------|-------------|------------------|-----------------------|--------|-----|-------|
| - | - | - | - | - | - | - | - | Пока нет beta users |
| | | | | | | | | |

**Пример заполнения:**
```
| U001 | Иван Петров | ivan@example.com | 15.02.2026 | 16.02.2026 | 8.5 | Active | 9 | Amaks 5-й санаторий |
```

**Формула для Time-to-first:**
```
=ROUND((E2-D2)*24, 1)
```
(где E2 = First Agent Date, D2 = Signup Date)

**Статусы:**
- Active - активно использует
- Inactive - не заходил >7 дней
- Churned - прекратил использование
- Completed - завершил создание агента

---

## Sheet 3: Confidence Meter

**Колонки:**

| Hypothesis | Evidence | Confidence (0-10) | Date | Next Action |
|------------|----------|-------------------|------|-------------|
| Templates-first works | 0 interviews, GIST analysis показывает ICE 7.8 | 2 | 02.01.2026 | Do 10 customer interviews |
| < 8h achievable | Assumption based on Amaks experience | 3 | 02.01.2026 | Person behind curtain test |
| Visual builder needed | GIST analysis shows lower ICE (1.8) | 2 | 02.01.2026 | Wait until templates validated |
| RAG essential for agents | Amaks case proves value | 7 | 02.01.2026 | Include in MVP |
| Self-hosted viable | Current AGIency runs self-hosted | 6 | 02.01.2026 | Cost analysis |

**Правила обновления Confidence:**
- **0-1:** Leadership opinion, thematic alignment
- **2-3:** Customer interviews, surveys
- **4-5:** Fake tests, prototypes, user testing
- **6-7:** Person behind curtain, wizard of oz
- **8-9:** Working prototype, closed beta
- **10:** Production A/B test, real usage data

**НЕ писать production код пока Confidence < 5!**

---

## Sheet 4: OKRs Tracking

**Objective 1: PMF Validation**

| Key Result | Target | Week 1 | Week 2 | Week 3 | Week 4 | ... | Week 13 | % Complete | Status |
|------------|--------|--------|--------|--------|--------|-----|---------|------------|--------|
| 3-5 active beta users | 3-5 | 0 | | | | | | 0% | 🔴 Not Started |
| NPS > 40 | >40 | - | | | | | | -% | 🔴 Not Started |
| Retention > 60% | >60% | - | | | | | | -% | 🔴 Not Started |
| 80%+ готовы платить | >80% | - | | | | | | -% | 🔴 Not Started |

**Objective 2: MVP Launch Ready**

| Key Result | Target | Week 1 | Week 2 | Week 3 | Week 4 | ... | Week 13 | % Complete | Status |
|------------|--------|--------|--------|--------|--------|-----|---------|------------|--------|
| MVP функционал | 100% must-haves | 0% | | | | | | 0% | 🔴 Not Started |
| Critical bugs | <10 | 0 | | | | | | - | 🟢 On Track |
| API response time | p95 <200ms | - | | | | | | -% | 🔴 Not Started |
| Uptime | >95% | - | | | | | | -% | 🔴 Not Started |

**Статусы:**
- 🟢 On Track
- 🟡 At Risk
- 🔴 Off Track / Not Started

---

## Дополнительные листы (опционально)

### Sheet 5: Blog Performance

| Week | Posts Published | Total Posts | Visitors | New Subscribers | Engagement | Top Post |
|------|-----------------|-------------|----------|-----------------|------------|----------|
| 1 | 1 | 1 | | | | Claudesidian |
| 2 | 2 | 3 | | | | |

### Sheet 6: AGIency Projects

| Client | Project | Status | Revenue | AGIents Usage | Notes |
|--------|---------|--------|---------|---------------|-------|
| Amaks | ИИ-консультант | Active | - | Planning 5th санаторий | Beta for AGIents |

---

## Weekly Review Checklist

**Каждый понедельник 9:00:**

- [ ] Открыть Google Sheet
- [ ] Обновить Weekly Summary:
  - [ ] Beta users count (active this week)
  - [ ] Agents created (total)
  - [ ] Completion rate (если есть данные)
  - [ ] Email list size (из ConvertKit)
  - [ ] Blog traffic (из Plausible)
- [ ] Добавить Notes: что произошло за неделю
- [ ] Обновить User Details (если новые beta)
- [ ] Обновить Confidence Meter (если новые evidence)
- [ ] Проверить OKRs progress
- [ ] Записать insights и next actions

**Время:** 10-15 минут

---

## Первая запись (Week 1 - текущая неделя)

**Данные для внесения СЕГОДНЯ:**

```
Sheet 1: Weekly Summary
Week 1 | 06.01-12.01 | 0 | 0 | - | 0 | 0 | План создан, справка готова, tracking setup начат

Sheet 3: Confidence Meter
(уже заполнено выше)

Sheet 4: OKRs
(все 0% / Not Started - это нормально для Week 1)
```

---

## Связанные материалы

- [[Setup Tracking - Action Plan]] - полный план настройки tracking
- [[Metrics & Tracking]] - определения всех метрик
- [[Weekly Metrics Template]] - шаблон для подробных отчетов
- [[Годовой план 2026]] - общая стратегия

---

## Next Steps

### Сегодня (2 января)
1. ✅ Создать этот template
2. ✅ Создать Google Sheet по этому шаблону (15 минут)
3. ✅ Внести первую запись (Week 1)
4. ✅ Добавить в закладки
5. ✅ Setup reminder в Calendar

### Эта неделя
1. [ ] Setup Plausible для блога (тогда появятся данные для Blog Traffic)
2. [ ] Setup ConvertKit (тогда появятся данные для Email List)

---

*Создано: 2 января 2026*
*Статус: Ready to copy to Google Sheets*
*Estimated setup time: 15-20 минут*
