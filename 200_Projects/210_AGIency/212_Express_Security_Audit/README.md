# Express Security Audit

**Тип:** Продуктовый эксперимент (Lean Validation)
**Статус:** 🟡 Validation Phase
**Создано:** 24 января 2026
**Приоритет:** Low (side experiment)

---

## Гипотеза

**Value Proposition:**
> Экспресс-аудит безопасности вашего кода за $200. AI находит критические уязвимости за 24-48 часов.

**Модель:** Разовая услуга (one-time service)

**Цена:** $200 (~20,000 ₽)

**Target Customer:**
- Стартапы на PHP/Laravel
- Небольшие dev-команды (5-15 человек)
- Компании перед запуском / привлечением инвестиций
- Фрилансеры с клиентскими проектами

---

## Эксперимент: Lean Validation

### Цель
Проверить спрос "малой кровью" до инвестиций в полноценный продукт.

### План

| Этап | Задача | Бюджет | Метрика успеха |
|------|--------|--------|----------------|
| 1 | Лендинг (1 страница) | 0-$50 | Готов за 1-2 дня |
| 2 | Трафик (ads/posts) | $100-200 | 500+ визитов |
| 3 | Конверсия | - | 2-3% → 10-15 лидов |
| 4 | Закрытие | - | 2-3 продажи |

### Success Criteria

**Minimum Viable Success:**
- 2+ оплаченных заказа за первый месяц
- Positive unit economics ($200 > cost of delivery)

**Strong Signal:**
- 5+ заказов
- Repeat customers / referrals
- Запросы на subscription модель

**Kill Criteria:**
- 0 заказов при 1000+ визитах
- Negative feedback от первых клиентов
- Delivery cost > $200

---

## Deliverable (что получает клиент)

1. **PDF отчёт** (10-20 страниц)
   - Executive Summary (для менеджмента)
   - Критические уязвимости с severity
   - Пошаговые рекомендации по исправлению
   - Code snippets с примерами фиксов

2. **Checklist** исправлений (приоритизированный)

3. **30-минутный созвон** (опционально, +$50)
   - Разбор отчёта
   - Ответы на вопросы
   - Рекомендации по процессам

---

## Scope аудита (за $200)

**Включено:**
- 1 репозиторий (до 50K LOC)
- OWASP Top 10 проверки
- Laravel/PHP специфичные уязвимости
- Hardcoded secrets detection
- SQL Injection, XSS, CSRF
- Authentication/Authorization issues
- Rate limiting check

**Не включено:**
- Infrastructure audit (servers, k8s)
- Penetration testing
- Compliance certification
- Continuous monitoring

---

## Лендинг: Структура

### Hero Section
```
🔒 Express Security Audit

Найдём критические уязвимости в вашем коде за 48 часов.
AI-анализ + экспертная проверка.

[Цена: $200] [Заказать аудит →]
```

### Секции
1. **Проблема** — "Вы не знаете, что пропустили"
2. **Решение** — Что включено в аудит
3. **Процесс** — 3 шага: Доступ → Анализ → Отчёт
4. **Пример отчёта** — Скриншот/PDF preview
5. **FAQ** — Типичные вопросы
6. **CTA** — Форма заказа

### Tech Stack для лендинга
- Framer / Carrd / Tilda (быстро)
- Stripe / ЮKassa для оплаты
- Calendly для созвонов

---

## Каналы трафика (тест)

| Канал | Бюджет | Ожидаемый результат |
|-------|--------|---------------------|
| LinkedIn posts | $0 | 100-300 views |
| Telegram (dev чаты) | $0 | 50-100 clicks |
| Google Ads (PHP security) | $100 | 200-300 clicks |
| Reddit r/webdev, r/PHP | $0 | 50-100 clicks |

**Total test budget:** $100-200

---

## Связь с другими проектами

### AI-код-ревью система
- Базовый инструмент для анализа
- ESA = продуктизация существующей системы

### Dogovor24
- Proof of concept (2 успешных аудита)
- Паттерны уязвимостей → checklist для ESA

### AGIents.pro (будущее)
- Security Audit Agent как template
- Демо возможностей платформы

### AISobolev блог
- Кейсы → посты
- "Как мы нашли RCE за 2 часа"

---

## Риски

| Риск | Вероятность | Mitigation |
|------|-------------|------------|
| Нет спроса | Medium | Kill fast, pivot to B2B |
| Delivery слишком долгий | Low | Стандартизировать процесс |
| Клиент недоволен глубиной | Medium | Чёткий scope на лендинге |
| Конкуренты дешевле | Low | AI + expertise = premium |

---

## Timeline

| Неделя | Задача |
|--------|--------|
| W4 Jan | Лендинг готов |
| W5 Jan | Запуск трафика |
| W1-2 Feb | Сбор данных |
| W3 Feb | Decision: scale / pivot / kill |

---

## Метрики для отслеживания

- [ ] Visitors (лендинг)
- [ ] Conversion to lead (форма)
- [ ] Conversion to paid
- [ ] Delivery time (часы)
- [ ] Customer satisfaction (NPS)
- [ ] Referrals

---

## Заметки

*Пространство для записей по ходу эксперимента*

### 24 января 2026
- Идея зафиксирована
- Источник: research в 100_tasks + опыт Dogovor24
- Оценка opportunity: 25/30 (из Task 2 Evaluation)

---

## Связанные документы

- [[100_tasks/01_Task/Problems_Brainstorm]] — источник идеи
- [[100_tasks/02_Task/Task_2_Evaluation]] — оценка проблемы #7
- [[200_Projects/240_MicroSaaS/241_AI_code_review/README]] — базовый инструмент
- [[200_Projects/210_AGIency/211_Консалтинг/README]] — proof of concept

---

*Создано: 24 января 2026*
*Обновлено: 24 января 2026*
*Статус: Validation — лендинг в работе*
