# Metrics & Tracking - AGIents.pro

**Дата создания:** 2026-01-02
**Статус:** 🟡 В разработке
**Обновление:** Еженедельно по понедельникам

---

## North Star Metric ⭐

**Time-to-first-working-agent < 8 часов**

**Почему это важно:**
- Фокусирует на главной ценности: скорость создания агента
- Измеримо на каждом этапе
- Влияет на retention и satisfaction
- Приводит к конкретным улучшениям продукта

**Текущее значение:** _TBD (измерить в Q1)_

**Target по кварталам:**
- Q1 2026: < 8 часов (beta users, с помощью)
- Q2 2026: < 4 часа (onboarding improvements)
- Q3 2026: < 2 часа (templates + AI assistance)
- Q4 2026: < 1 час (fully optimized)

---

## Metrics Tree

```
North Star: Time-to-first-agent < 8ч
    ↓
├─ Setup Time
│   ├─ Регистрация → email confirm (target: < 2 мин)
│   ├─ Onboarding wizard (target: < 5 мин)
│   └─ First login → dashboard (target: < 1 мин)
│
├─ Building Time ⭐ (main bottleneck)
│   ├─ Choose template / start from scratch
│   ├─ Configure agent (blocks, connections)
│   ├─ Setup integrations
│   └─ Configure knowledge base (RAG)
│
├─ Testing Time
│   ├─ Test mode activation
│   ├─ Run test scenarios
│   ├─ Debug errors
│   └─ Validate results
│
└─ Publishing Time
    ├─ Review configuration
    ├─ Deploy to production
    └─ Get endpoint/webhook

Supporting Metrics:
├─ Feature adoption rate (% using templates, RAG, etc.)
├─ Error rate during creation (bugs, failed API calls)
├─ Support requests per user
└─ Template usage % vs from-scratch
```

---

## Q1 2026 Metrics (ЯНВАРЬ-МАРТ)

### Product Metrics

#### 1. North Star & Related

| Metric | Target Q1 | Measurement | Frequency |
|--------|-----------|-------------|-----------|
| **Time-to-first-agent** | < 8h | User sessions tracking | Weekly |
| Setup time | < 10 min | Analytics | Weekly |
| Building time | < 6h | Session duration | Weekly |
| Testing time | < 1h | Test mode usage | Weekly |
| Publishing time | < 30 min | Deploy events | Weekly |

#### 2. Engagement

| Metric | Target Q1 | Measurement | Frequency |
|--------|-----------|-------------|-----------|
| Completion rate | > 70% | Started vs completed agents | Weekly |
| Template usage | > 50% | Template vs scratch ratio | Weekly |
| Active users (WAU) | 10-20 | Weekly active | Weekly |
| Feature adoption | Varies | Per-feature tracking | Bi-weekly |

#### 3. Quality

| Metric | Target Q1 | Measurement | Frequency |
|--------|-----------|-------------|-----------|
| Test success rate | > 80% | Tests passed / total tests | Daily |
| Agent uptime | > 95% | Monitoring | Real-time |
| Error rate | < 5% | Error logs | Daily |
| Bug count (critical) | < 10 | Issue tracker | Weekly |

#### 4. User Satisfaction

| Metric | Target Q1 | Measurement | Frequency |
|--------|-----------|-------------|-----------|
| NPS | > 40 | Surveys | Bi-weekly |
| CSAT | > 4/5 | Post-interaction | After key events |
| Support tickets/user | < 2 | Support system | Weekly |
| Beta retention | > 60% | Active beta users | Weekly |

### Business Metrics (Pre-monetization)

| Metric | Target Q1 | Measurement | Frequency |
|--------|-----------|-------------|-----------|
| Beta signups | 20-30 | Signup form | Daily |
| Beta users active | 3-5 | Active in last week | Weekly |
| Email list growth | 100-200 | Email platform | Weekly |
| Blog traffic | 500-1K/mo | Analytics | Weekly |
| Leads generated | 10-20 | CRM | Weekly |

---

## Q2 2026 Metrics (АПРЕЛЬ-ИЮНЬ) - Monetization

### Revenue Metrics

| Metric | Target Q2 | Measurement | Frequency |
|--------|-----------|-------------|-----------|
| **MRR** | $2K-5K | Billing system | Daily |
| New MRR | Growth % | New subscriptions | Weekly |
| Expansion MRR | From upgrades | Upgrade events | Weekly |
| Churned MRR | Lost revenue | Cancellations | Weekly |
| ARPU | $50-125 | MRR / customers | Weekly |

### Customer Metrics

| Metric | Target Q2 | Measurement | Frequency |
|--------|-----------|-------------|-----------|
| Total customers | 20-40 | Active subscriptions | Daily |
| Trial signups | 50-100 | Trial starts | Daily |
| Trial→Paid conversion | > 15% | Conversions / trials | Weekly |
| Monthly churn | < 10% | Cancellations / total | Monthly |
| NPS | > 50 | Surveys | Bi-weekly |

### Unit Economics

| Metric | Target Q2 | Measurement | Frequency |
|--------|-----------|-------------|-----------|
| CAC | < $200 | Marketing spend / new customers | Monthly |
| LTV | > $600 | ARPU × avg lifetime | Monthly |
| LTV:CAC ratio | > 3:1 | LTV / CAC | Monthly |
| Payback period | < 6 months | CAC / monthly profit | Monthly |
| Gross margin | > 70% | Revenue - COGS | Monthly |

---

## Q3-Q4 Metrics (Growth Phase)

### Scaling Metrics

| Metric | Q3 Target | Q4 Target | Measurement |
|--------|-----------|-----------|-------------|
| MRR | $10K-15K | $20K-30K | Billing |
| Total customers | 80-120 | 200-300 | Subscriptions |
| Monthly growth | 20%+ | 20%+ | MoM growth |
| Churn | < 8% | < 5% | Monthly |
| NPS | > 60 | > 70 | Surveys |
| CAC | < $150 | < $100 | Marketing |
| LTV:CAC | > 4:1 | > 5:1 | Calculation |

---

## Tracking System Architecture

### Analytics Stack

#### Phase 1: MVP (Q1) - Minimal Setup

**Tools:**
- **Plausible / Simple Analytics** - privacy-friendly web analytics
  - Page views, unique visitors
  - Traffic sources
  - Goal conversions (signups, completions)

- **Google Sheets** - manual tracking
  - Weekly metrics snapshot
  - User interviews notes
  - Beta feedback

- **Notion / Obsidian** - qualitative data
  - User stories
  - Feature requests
  - Bug reports

**Cost:** ~$10/month

#### Phase 2: Launch (Q2) - Product Analytics

**Tools:**
- **PostHog** (self-hosted или cloud)
  - Event tracking
  - Feature flags
  - Session recordings
  - Funnels

- **Stripe** - billing & revenue
  - MRR tracking
  - Churn analytics
  - Revenue cohorts

- **Customer.io / Loops** - email & metrics
  - Email campaigns
  - User segments
  - Engagement tracking

**Cost:** ~$100-200/month

#### Phase 3: Scale (Q3+) - Advanced Analytics

**Additional tools:**
- **Metabase / Redash** - custom dashboards
- **Amplitude / Mixpanel** - advanced product analytics
- **ChartMogul** - SaaS metrics
- **Sentry** - error tracking

**Cost:** ~$300-500/month

---

## Events to Track

### User Lifecycle Events

```javascript
// Registration & Onboarding
track('user_signed_up', {
  source: 'blog' | 'direct' | 'referral',
  plan: 'trial' | 'starter' | 'pro'
})

track('onboarding_started')
track('onboarding_completed', {
  duration_seconds: 300
})

// Agent Creation
track('agent_creation_started', {
  method: 'template' | 'scratch',
  template_id: 'hotel-booking' (if template)
})

track('agent_block_added', {
  block_type: 'http_request' | 'condition' | 'llm_call'
})

track('agent_integration_configured', {
  integration_type: 'pms' | 'crm' | 'email'
})

track('agent_knowledge_base_uploaded', {
  documents_count: 10,
  total_size_mb: 5.2
})

track('agent_test_started')
track('agent_test_completed', {
  success: true | false,
  duration_seconds: 120
})

track('agent_published', {
  time_to_first_agent_hours: 7.5,
  blocks_count: 8,
  integrations_count: 2
})

// Usage
track('agent_executed', {
  agent_id: 'abc123',
  success: true | false,
  execution_time_ms: 1500
})

// Monetization
track('trial_started')
track('subscription_created', {
  plan: 'starter' | 'pro' | 'enterprise',
  mrr: 49
})
track('subscription_upgraded', {
  from_plan: 'starter',
  to_plan: 'pro',
  mrr_change: 150
})
track('subscription_cancelled', {
  reason: 'too_expensive' | 'not_needed' | 'missing_features'
})
```

### Feature Adoption Events

```javascript
track('feature_used', {
  feature: 'templates' | 'rag' | 'visual_builder' | 'ai_assistant',
  first_time: true | false
})
```

---

## Dashboards

### Dashboard 1: Executive Summary (Daily Check)

**Metrics:**
- MRR (current, growth %)
- Active users (today, this week)
- Trial conversions (this week)
- Churn (this month)
- North Star Metric (current avg)

**Format:** Single page, 5 key numbers

**Access:** Notion page или Google Sheets

### Dashboard 2: Product Health (Weekly Review)

**Metrics:**
- Time-to-first-agent (p50, p90, p99)
- Completion rate
- Feature adoption rates
- Error rate & critical bugs
- NPS & CSAT trends

**Format:** PostHog dashboard

**Review:** Every Monday morning

### Dashboard 3: Business Metrics (Monthly Review)

**Metrics:**
- Revenue (MRR, growth, churn)
- Customers (new, churned, net growth)
- Unit economics (CAC, LTV, payback)
- Funnel conversion (visitors → trials → paid)
- Cohort retention

**Format:** ChartMogul / Stripe dashboard

**Review:** First Monday of month

### Dashboard 4: User Feedback (Continuous)

**Sources:**
- NPS survey responses
- Support tickets
- Feature requests (voting board)
- User interview notes

**Format:** Notion database

**Review:** Weekly + ad-hoc

---

## Metrics Collection Process

### Week 1 (Q1): Manual Collection

**Monday morning routine:**
1. Open Google Sheet "AGIents Metrics Q1"
2. Record:
   - Beta users count
   - Active this week
   - Agents created (total)
   - Time-to-first-agent (from session notes)
   - Email list size
   - Blog traffic (Plausible)
3. Add qualitative notes
4. Review trends

**Time:** 15-30 minutes

### Week 2+ (Q1): Semi-automated

**Setup:**
- PostHog events for key actions
- Webhook from signup form → Sheet
- Weekly automated email with metrics

**Monday routine:**
- Review automated dashboard
- Add qualitative notes
- Update Confidence Meter for key hypotheses

**Time:** 10-15 minutes

### Q2+: Fully Automated

**Setup:**
- All events tracked automatically
- Dashboards auto-update
- Weekly email report

**Monday routine:**
- Review dashboards (5 min)
- Deep dive on anomalies (15 min)
- Update strategy if needed

---

## OKRs & Metrics Alignment

### Q1 Objective 1: Product-Market Fit Validation

**Key Results:**
1. **3-5 beta users actively use platform**
   - Metric: Weekly active beta users
   - Target: 3-5
   - Current: _TBD_

2. **NPS > 40**
   - Metric: Net Promoter Score
   - Target: > 40
   - Current: _TBD_

3. **Retention > 60%**
   - Metric: Beta users active week-over-week
   - Target: > 60%
   - Current: _TBD_

4. **80%+ готовы платить**
   - Metric: Survey question "Would you pay for this?"
   - Target: > 80% yes
   - Current: _TBD_

### Q1 Objective 2: MVP Launch Ready

**Key Results:**
1. **MVP функционал завершен**
   - Metric: Feature completion %
   - Target: 100% of must-haves
   - Current: 0% (just starting)

2. **< 10 critical bugs**
   - Metric: Issue tracker
   - Target: < 10 P0 bugs
   - Current: 0 (no code yet)

3. **Performance: API < 200ms, Uptime > 95%**
   - Metrics: Response time, uptime monitoring
   - Targets: p95 < 200ms, uptime > 95%
   - Current: _TBD_

---

## Weekly Metrics Template

### Week of [Date]

#### North Star
- Time-to-first-agent: _X hours_ (↑/↓ vs last week)

#### Engagement
- Beta users active: _X_
- Agents created: _X_
- Completion rate: _X%_

#### Quality
- Test success rate: _X%_
- Critical bugs: _X_
- Support tickets: _X_

#### Growth
- Email signups: +_X_
- Blog traffic: _X_ visits
- Leads generated: _X_

#### Insights & Actions
- What worked well:
- What needs improvement:
- Actions for next week:

---

## Confidence Meter Tracking

**Для ключевых гипотез отслеживаем Confidence Level:**

### Hypothesis 1: Templates-first approach is right

**Current Confidence:** _TBD_

**Evidence:**
- Customer interviews: _X/10 prefer templates_
- Fake button test: _X% clicked templates_
- Beta usage: _X% use templates vs scratch_

**Next step to increase confidence:**
- _Действие для повышения confidence_

### Hypothesis 2: Users can create agent in < 8h

**Current Confidence:** _TBD_

**Evidence:**
- Person behind curtain: took _X hours_
- Beta user 1: _X hours_
- Beta user 2: _X hours_

**Target Confidence:** 7+ (before scaling)

---

## Alerts & Thresholds

### Critical Alerts (Immediate Action)

- Uptime < 90%
- Error rate > 10%
- Churn > 20% (when monetized)
- NPS drops below 30

### Warning Alerts (Review This Week)

- Time-to-first-agent > 10h
- Completion rate < 60%
- Trial conversion < 10%
- CAC > $250

---

## Next Steps

### This Week (Week 1)
- [x] Определить метрики
- [ ] Setup Google Sheet для manual tracking
- [ ] Setup Plausible для website analytics
- [ ] Создать template для weekly metrics

### Week 2
- [ ] Install PostHog (self-hosted)
- [ ] Instrument key events в код
- [ ] Создать first dashboard

### Month 2
- [ ] Review metrics weekly
- [ ] Adjust based on learnings
- [ ] Prepare for Q2 monetization tracking

---

## Связанные материалы

- [[Годовой план 2026]] - OKRs по кварталам
- [[MVP Specification]] - какие метрики нужны для MVP
- [[Product Roadmap]] - Goals и Key Results
- [[Применение GIST к AGIents]] - Confidence Meter, ICE scoring

---

*Создано: 2026-01-02*
*Обновление: Еженедельно*
*Следующий review: 13 января 2026*
