# Product Roadmap AGIents.pro

**Дата создания:** 2026-01-02
**Статус:** 🔴 Не начато
**Тип:** Outcome-based Roadmap (не feature factory!)

---

## Roadmap Philosophy

> "We build outcomes, not outputs"

Этот roadmap фокусируется на **проблемах пользователей** и **метриках**, а не на списке фич.

Согласно GIST Framework:
- Goals определяют направление
- Ideas меняются по мере обучения
- Steps валидируют гипотезы
- Tasks - конкретная реализация

---

## North Star Metric

**Time-to-first-working-agent < 8 часов**

### Metrics Tree

```
North Star: Time-to-first-agent < 8ч
    ↓
├─ Setup time (регистрация → старт работы)
├─ Building time (старт → первая версия агента)
├─ Testing time (тестирование → success)
└─ Publishing time (success → production)
```

---

## Q1 2026: Foundation (ЯНВАРЬ-МАРТ)

### Goal 1: Product-Market Fit Validation

**Objective:** Подтвердить что бизнесы хотят и могут создавать ИИ-агентов на нашей платформе

**Key Results:**
- 3-5 beta-клиентов активно используют платформу
- NPS > 40
- Retention > 60%
- 80%+ beta-клиентов готовы платить

**Ideas для тестирования:**
- Visual workflow builder
- Template-based approach
- Conversational builder
- Hybrid approach

**Метрики:**
- Time-to-first-agent
- Completion rate
- Test success rate
- User satisfaction

### Goal 2: MVP Launch

**Objective:** Запустить минимальный жизнеспособный продукт для beta-тестирования

**Key Results:**
- MVP с базовым функционалом готов
- 5-10 базовых блоков/действий работают
- 2-3 ключевые интеграции реализованы
- Система тестирования функционирует

**Метрики:**
- Feature completeness
- Bug count < 10 critical
- Performance: API < 200ms
- Uptime > 95%

---

## Q2 2026: Launch & Monetization (АПРЕЛЬ-ИЮНЬ)

### Goal 1: Первые платящие клиенты

**Objective:** Конвертировать beta-пользователей и новых клиентов в платящих

**Key Results:**
- 20-40 платящих клиентов
- MRR $2,000-5,000
- Trial-to-paid conversion > 15%
- Monthly churn < 10%

**Ideas:**
- Pricing optimization (A/B testing)
- Onboarding improvements
- Value demonstration (tutorials, case studies)

**Метрики:**
- MRR
- ARPU (Average Revenue Per User)
- CAC (Customer Acquisition Cost)
- LTV (Lifetime Value)

### Goal 2: Product-Market Fit доказан

**Objective:** Достичь стабильного Product-Market Fit

**Key Results:**
- NPS > 50
- Retention > 90%
- Organic growth началсядочка (word of mouth)
- Template marketplace: 10-15 шаблонов

**Метрики:**
- NPS tracking
- Cohort retention
- Viral coefficient
- Template usage

---

## Q3 2026: Growth & Scale (ИЮЛЬ-СЕНТЯБРЬ)

### Goal 1: Масштабирование до $10K MRR

**Objective:** Достичь $10,000-15,000 MRR через рост клиентской базы

**Key Results:**
- 80-120 платящих клиентов
- MRR $10,000-15,000
- CAC < $200
- LTV:CAC > 3:1

**Ideas:**
- Платная реклама (Google, LinkedIn)
- Партнерства
- Affiliate программа (20%)
- Enterprise features

**Метрики:**
- New MRR
- Expansion MRR
- CAC payback period
- Customer concentration

### Goal 2: Retention & Expansion

**Objective:** Увеличить ценность для существующих клиентов

**Key Results:**
- Monthly churn < 8%
- Upgrade rate > 10% (Starter → Pro)
- Annual plan adoption > 20%
- Community активна (100+ участников)

**Ideas:**
- Customer success программа
- Educational content
- Feature adoption campaigns
- Community building

**Метрики:**
- Net revenue retention
- Feature adoption rate
- Community engagement
- Support satisfaction

---

## Q4 2026: Enterprise & Scale (ОКТЯБРЬ-ДЕКАБРЬ)

### Goal 1: Enterprise клиенты

**Objective:** Привлечь первых enterprise клиентов

**Key Results:**
- 5-10 enterprise клиентов
- Enterprise MRR > $5,000
- Sales cycle < 60 дней
- Enterprise NPS > 60

**Ideas:**
- Enterprise features (API, SSO, SLA)
- Dedicated account management
- Custom integrations
- White-label опция (?)

**Метрики:**
- Enterprise revenue %
- Average deal size
- Sales cycle length
- Enterprise retention

### Goal 2: $20K+ MRR

**Objective:** Достичь $20,000-30,000 MRR

**Key Results:**
- 200-300 total customers
- MRR $20,000-30,000
- Churn < 5%
- Team 2-5 человек

**Метрики:**
- Total MRR
- MRR growth rate
- Rule of 40 (Growth + Profit margin)
- Burn multiple

---

## Feature Ideas Backlog (приоритизировать через ICE)

### Agent Builder

- [ ] Visual workflow editor
- [ ] Template marketplace
- [ ] AI assistant для создания
- [ ] Version control для агентов
- [ ] Collaboration (team editing)
- [ ] Import/export agents

### Integrations

- [ ] Webhook management
- [ ] Email (SMTP, providers)
- [ ] Messaging (Telegram, WhatsApp, Slack)
- [ ] CRM (Salesforce, HubSpot)
- [ ] Databases (Postgres, MySQL, MongoDB)
- [ ] APIs (REST, GraphQL, SOAP)
- [ ] Cloud storage (S3, Google Drive, Dropbox)

### Execution & Monitoring

- [ ] Real-time logs
- [ ] Advanced debugging
- [ ] Performance analytics
- [ ] Error handling & retry logic
- [ ] Scheduling (cron)
- [ ] Conditional workflows

### Enterprise

- [ ] SSO (SAML, OAuth)
- [ ] Role-based access control
- [ ] Audit logs
- [ ] SLA guarantees
- [ ] Dedicated infrastructure
- [ ] API для разработчиков
- [ ] White-label

### Platform

- [ ] Multi-language support
- [ ] Mobile app (iOS, Android)
- [ ] Plugin system
- [ ] Marketplace для third-party блоков
- [ ] Self-hosted option

---

## Приоритизация Features (ICE Framework)

**После каждого квартала обновлять приоритеты!**

| Feature | Impact (1-10) | Confidence (0-10) | Ease (1-10) | ICE Score | Quarter |
|---------|---------------|-------------------|-------------|-----------|---------|
| _TBD_ | | | | | |

---

## Validation Pipeline (каждая Idea проходит)

```
Idea → Customer Interviews → Fake Button Test → Prototype → Beta → Production
  ↓         ↓                    ↓                 ↓          ↓        ↓
Conf: 0   Conf: 1-2           Conf: 3-4        Conf: 5-7  Conf: 8-9  Conf: 10
```

**Confidence Meter:** не билдим production пока Confidence < 5!

---

## Dependencies & Risks

### Dependencies

- [[MVP Specification]] → Q1 features
- [[Competitive Analysis]] → Positioning strategy
- Customer interviews → Ideas validation
- Beta feedback → Q2 priorities

### Risks

**Q1 Risks:**
- MVP слишком сложный → упростить scope
- Не найдем beta-клиентов → использовать AGIency клиентов
- Technical challenges → prototype быстрее, production позже

**Q2 Risks:**
- Low conversion → улучшить onboarding, ценность
- High churn → customer development, фикс проблем
- Slow growth → больше marketing

**Q3 Risks:**
- CAC слишком высокий → optimize channels
- Retention падает → customer success focus
- Конкуренты → differentiation, speed

**Q4 Risks:**
- Enterprise сложнее чем ожидалось → focus на SMB
- Not hitting $20K MRR → extend timeline, pivot
- Team bottleneck → hire earlier

---

## Quarterly Review Process

### End of Quarter Checkpoint

1. **Review Metrics:** Достигли ли Key Results?
2. **Customer Feedback:** Что говорят пользователи?
3. **Competitive Landscape:** Что изменилось?
4. **Team Capacity:** Можем ли масштабировать?
5. **Financial:** MRR, runway, unit economics
6. **Update Roadmap:** Следующий квартал приоритеты

### Adaptation Triggers

- **Slow growth:** < 10% MoM → пересмотр стратегии
- **High churn:** > 15% → product improvements
- **Low conversion:** < 10% → onboarding/value prop
- **Negative NPS:** < 30 → customer development

---

## Связанные материалы

- [[Годовой план 2026]] - общая стратегия
- [[MVP Specification]] - детали MVP
- [[Competitive Analysis]] - конкуренты
- [[Product development framework]] - GIST Framework
- [[Кейс Amaks]] - reference клиент

---

*Создано: 2026-01-02*
*Обновлено: 2026-01-02*

**Next review:** 31 марта 2026 (Q1 checkpoint)
