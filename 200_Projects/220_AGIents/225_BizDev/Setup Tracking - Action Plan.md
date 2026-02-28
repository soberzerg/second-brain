# Setup Tracking - Action Plan

**Дата:** 2026-01-02
**Статус:** 🟡 В процессе
**Фаза:** MVP (Q1 2026)

---

## Философия tracking для MVP

> "Track as little as possible, but enough to make data-driven decisions"

**Принципы:**
- ✅ Простота > Сложность (Q1)
- ✅ Manual > Automated (пока нет users)
- ✅ Free/Cheap > Expensive
- ✅ Privacy-friendly
- ✅ Self-hosted где возможно

---

## Phase 1: Immediate Setup (Week 1) - СЕЙЧАС

**Цель:** Начать tracking сегодня, даже без кода

### Action 1: Google Sheets для manual tracking

**Что:** Простая таблица для записи метрик

**Setup (15 минут):**

1. **Создать Google Sheet: "AGIents Metrics Q1 2026"**

2. **Структура:**

**Sheet 1: Weekly Summary**
```
| Week | Dates | Beta Users | Agents Created | Completion % | Email List | Blog Traffic | Notes |
|------|-------|------------|----------------|--------------|------------|--------------|-------|
| 1    |       |            |                |              |            |              |       |
| 2    |       |            |                |              |            |              |       |
```

**Sheet 2: User Details**
```
| User ID | Name | Email | Signup Date | First Agent Date | Time-to-first | Status | NPS |
|---------|------|-------|-------------|------------------|---------------|--------|-----|
```

**Sheet 3: Confidence Meter**
```
| Hypothesis | Evidence | Confidence (0-10) | Date | Next Action |
|------------|----------|-------------------|------|-------------|
| Templates-first works | 0 interviews | 2 | 2026-01-02 | Do 10 interviews |
| < 8h achievable | Assumption | 3 | 2026-01-02 | Person behind curtain test |
```

**Sheet 4: OKRs Tracking**
```
| Objective | Key Result | Target | Current | % | Status |
|-----------|------------|--------|---------|---|--------|
| PMF Validation | 3-5 active beta users | 3-5 | 0 | 0% | 🔴 |
```

3. **Добавить в закладки**

4. **Weekly ritual:** Каждый понедельник 9:00 - обновить

**Cost:** $0

### Action 2: Blog Analytics

**Что:** Отслеживание трафика блога AISobolev

**Options:**

**Option A: Plausible Analytics** (Recommended)
- Privacy-friendly
- Simple dashboard
- GDPR compliant
- $9/month

**Option B: Simple Analytics**
- Похожи на Plausible
- $9/month

**Option C: Cloudflare Analytics**
- Бесплатно
- Базовые метрики
- Если используете Cloudflare

**Setup Plausible (10 минут):**

1. Зарегистрироваться на plausible.io
2. Добавить сайт блога
3. Скопировать tracking script
4. Добавить в `<head>` блога:
```html
<script defer data-domain="yourdomain.com" src="https://plausible.io/js/script.js"></script>
```
5. Настроить Goals:
   - Email signup
   - AGIents beta signup
   - Post read (scroll depth)

**Cost:** $9/month

### Action 3: Email List Tracking

**Что:** Отслеживание роста email базы

**Options:**

**Option A: ConvertKit** (для creators)
- Email marketing + automation
- Landing pages
- Forms
- Free до 1,000 subscribers

**Option B: Loops** (для SaaS)
- Modern email tool
- Transactional + marketing
- $30/month

**Option C: Mailchimp**
- Популярен
- Free tier
- Но сложный

**Recommendation для Q1:** ConvertKit (бесплатно пока < 1K)

**Setup ConvertKit (20 минут):**

1. Зарегистрироваться
2. Создать форму signup
3. Создать Landing page для lead magnet
4. Настроить автоматизацию:
   - Welcome email
   - 5-email sequence про AGIents
5. Интеграция с блогом
6. Tracking: ConvertKit показывает growth автоматически

**Cost:** $0 (пока < 1K subscribers)

---

## Phase 2: Product Analytics (Week 2-3)

**Цель:** Отслеживание user behavior когда MVP готов

### Action 4: PostHog Setup

**Что:** Open-source product analytics

**Why PostHog:**
- ✅ Self-hosted (data privacy)
- ✅ Event tracking
- ✅ Session recordings
- ✅ Feature flags
- ✅ Funnels, retention, cohorts
- ✅ Free (self-hosted) или $0.000225/event (cloud)

**Setup Options:**

**Option A: Self-hosted (Docker)**

1. **Server requirements:**
   - VDS с 4GB RAM minimum
   - 20GB disk
   - Docker + docker-compose

2. **Installation:**
```bash
# Clone repo
git clone https://github.com/PostHog/posthog.git
cd posthog

# Start with docker-compose
docker-compose up -d

# Access at http://your-server:8000
```

3. **Configure:**
   - Create organization
   - Get API key
   - Setup reverse proxy (nginx)

**Option B: Cloud (проще, $0 до 1M events)**

1. Signup на posthog.com
2. Create project
3. Get API key

**Recommendation для MVP:** Cloud (проще), позже migrate to self-hosted

**Frontend Integration (React):**

```bash
npm install posthog-js
```

```javascript
// src/analytics.js
import posthog from 'posthog-js'

export const initAnalytics = () => {
  posthog.init('YOUR_API_KEY', {
    api_host: 'https://app.posthog.com',
    autocapture: false, // manual events only
    capture_pageview: true
  })
}

// Track events
export const track = (event, properties = {}) => {
  posthog.capture(event, properties)
}
```

```javascript
// App.js
import { initAnalytics, track } from './analytics'

useEffect(() => {
  initAnalytics()
}, [])

// Use in components
track('agent_creation_started', {
  method: 'template',
  template_id: 'hotel-booking'
})
```

**Backend Integration (Go):**

```go
// pkg/analytics/posthog.go
package analytics

import "github.com/posthog/posthog-go"

var client posthog.Client

func Init() {
    client, _ = posthog.NewWithConfig(
        "YOUR_API_KEY",
        posthog.Config{
            Endpoint: "https://app.posthog.com",
        },
    )
}

func Track(userId, event string, properties map[string]interface{}) {
    client.Enqueue(posthog.Capture{
        DistinctId: userId,
        Event:      event,
        Properties: properties,
    })
}
```

**Key Events to Instrument:**

```javascript
// См. полный список в Metrics & Tracking.md

// Must-have события для Q1:
track('user_signed_up')
track('agent_creation_started')
track('agent_published', {
  time_to_first_agent_hours: 7.5
})
track('agent_test_completed', {
  success: true
})
```

**Cost:** $0 (до 1M events/month)

---

## Phase 3: Advanced Tracking (Month 2+)

### Action 5: Session Recordings

**Что:** Смотреть как users используют платформу

**PostHog Session Recordings:**

```javascript
posthog.init('YOUR_API_KEY', {
  session_recording: {
    enabled: true,
    maskAllInputs: true, // privacy
    recordCrossOriginIframes: false
  }
})
```

**Use cases:**
- Где users застревают
- Какие ошибки видят
- Как используют features

**Privacy:**
- Mask sensitive data (credit cards, passwords)
- Don't record certain pages (настройки, billing)

### Action 6: Error Tracking

**Что:** Отслеживание ошибок и exceptions

**Options:**

**Option A: Sentry**
- Industry standard
- Great error tracking
- Performance monitoring
- Free tier: 5K errors/month

**Option B: PostHog (есть error tracking)**
- Integrated с analytics
- Проще setup

**Recommendation:** Sentry для production

**Setup Sentry (Frontend):**

```bash
npm install @sentry/react
```

```javascript
import * as Sentry from "@sentry/react";

Sentry.init({
  dsn: "YOUR_DSN",
  environment: "production",
  integrations: [
    new Sentry.BrowserTracing(),
    new Sentry.Replay()
  ],
  tracesSampleRate: 1.0,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
});
```

**Setup Sentry (Backend - Go):**

```go
import "github.com/getsentry/sentry-go"

sentry.Init(sentry.ClientOptions{
    Dsn: "YOUR_DSN",
    Environment: "production",
})
```

**Cost:** $0 (free tier) → $26/month (team plan)

---

## Phase 4: Business Metrics (Q2 - Monetization)

### Action 7: Stripe Analytics

**Когда:** Q2, при запуске монетизации

**Что отслеживать:**
- MRR
- Churn
- New customers
- Revenue by plan

**Built-in Stripe dashboard** показывает:
- Revenue trends
- Customer lifetime value
- Failed payments
- Cancellations

**Advanced: ChartMogul**
- Подключается к Stripe
- SaaS-specific metrics
- Cohort analysis
- $100/month (later, когда revenue позволяет)

### Action 8: Customer Feedback

**Tools:**

**NPS Surveys:**
- PostHog Surveys (встроено)
- Или: Typeform, Google Forms

**In-app Feedback:**
- Простой thumbs up/down на features
- Text feedback box

**User Interviews:**
- Calendly для booking
- Zoom/Google Meet
- Notion для notes

---

## Monitoring & Alerts

### Uptime Monitoring

**Tools:**
- **UptimeRobot** (free, 50 monitors)
- **Pingdom**
- **BetterUptime**

**Setup (5 минут):**
1. Add URL to monitor
2. Set check interval (5 min)
3. Add alert contacts (email, Telegram)

### Performance Monitoring

**Backend (Go):**
- Prometheus + Grafana (self-hosted)
- Or: DataDog, New Relic (paid)

**Frontend:**
- PostHog performance
- Или: Vercel Analytics (если на Vercel)

**Для Q1:** Базовый uptime monitoring достаточно

---

## Privacy & GDPR

### Важно для EU users

**Requirements:**
- ✅ Cookie consent banner
- ✅ Privacy policy (упоминание analytics)
- ✅ Opt-out option
- ✅ Data retention policy

**Tools:**
- CookieYes (consent banner)
- Termly (privacy policy generator)

**PostHog:**
- Self-hosted = полный контроль данных
- Cloud = GDPR compliant, но в США

---

## Setup Checklist

### Week 1 (Immediate) - СДЕЛАТЬ СЕЙЧАС

- [ ] Создать Google Sheet "AGIents Metrics Q1"
- [ ] Setup Plausible для блога
- [ ] Setup ConvertKit для email
- [ ] Добавить первую запись в sheet
- [ ] Настроить weekly reminder (Monday 9am)

**Time:** ~1 час
**Cost:** $9/month (Plausible)

### Week 2 (MVP начинается)

- [ ] Setup PostHog (cloud)
- [ ] Instrument key events (frontend)
- [ ] Instrument key events (backend)
- [ ] Test event tracking
- [ ] Create first dashboard в PostHog

**Time:** 2-3 hours
**Cost:** $0

### Week 3-4 (Refinement)

- [ ] Add session recordings
- [ ] Setup Sentry для errors
- [ ] Create monitoring alerts
- [ ] Weekly metrics review process

**Time:** 2 hours
**Cost:** +$0-26/month (Sentry free tier)

### Month 2 (Optimization)

- [ ] Review tracked events
- [ ] Optimize dashboards
- [ ] Setup automated reports
- [ ] Document tracking для team

---

## Budget Summary

### Q1 (Minimal)
- Plausible: $9/mo
- ConvertKit: $0 (free tier)
- PostHog: $0 (free tier)
- Sentry: $0 (free tier)
- **Total: ~$9/month**

### Q2 (Growth)
- Plausible: $9/mo
- ConvertKit: $0-29/mo (зависит от роста)
- PostHog: $0-50/mo
- Sentry: $26/mo
- Stripe: included
- **Total: ~$50-100/month**

### Q3-Q4 (Scale)
- All above: ~$100/mo
- ChartMogul: $100/mo
- Advanced tools: $100-200/mo
- **Total: ~$300-500/month**

---

## Next Actions

### Today (2026-01-02)

1. [ ] Create Google Sheet
2. [ ] Record first entry (even with zeros)
3. [ ] Setup Plausible trial
4. [ ] Add to blog

**Time:** 30 минут

### This Week

1. [ ] Setup ConvertKit
2. [ ] Create lead magnet landing
3. [ ] Weekly review calendar event

### Next Week

1. [ ] Setup PostHog (когда MVP код начнется)
2. [ ] Instrument events

---

## Связанные материалы

- [[Metrics & Tracking]] - все метрики и их определения
- [[Weekly Metrics Template]] - шаблон для отчетов
- [[MVP Specification]] - какие события трекать
- [[Годовой план 2026]] - OKRs и цели

---

*Создано: 2026-01-02*
*Статус: Ready to implement*
*Первый weekly review: 13 января 2026*
