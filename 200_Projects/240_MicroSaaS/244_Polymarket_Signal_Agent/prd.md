---
type: project-doc
date: 2026-04-04
project: MicroSaaS
status: draft
tags: [polymarket, prediction-markets, ai-agent, trading-signals, claude-api]
---

# PRD: PolySignal — AI Prediction Market Research Agent

## Обзор приложения

PolySignal — автономный AI-агент, который мониторит prediction markets на Polymarket, находит mispriced рынки через двухэтапную фильтрацию (математический скан + Claude reasoning), и отправляет торговые сигналы с обоснованием в Telegram. Человек принимает решение о торговле вручную.

**Вдохновение:** кошелёк "sovereign2013" на Polymarket — ~$3.3M прибыли за 8 месяцев, 37K сделок, 71% win rate через HF arbitrage/market-making. Мы берём research-часть этого подхода, убирая автоматическое исполнение.

**Ключевая идея:** не торговый бот, а research assistant — снижает риск и правовые вопросы, при этом даёт информационное преимущество.

## Цели и задачи

- Автоматический мониторинг Polymarket рынков каждые 15 минут
- Обнаружение mispriced markets через математический анализ + AI reasoning
- Доставка actionable сигналов в Telegram с обоснованием
- Валидация концепции при минимальном капитале ($50-500)
- Трекинг качества сигналов (hit rate, P&L)

## Целевая аудитория

**Основной сегмент:** Индивидуальный трейдер prediction markets (я сам — dogfooding)

**User Persona:**
- Технически грамотный, понимает prediction markets и crypto
- Торгует на Polymarket вручную, но не успевает мониторить все рынки
- Хочет получать готовые сигналы с обоснованием для принятия решений
- Капитал $50-500, цель — проверить стратегию, не разбогатеть

## Основные фичи

### MVP (Фаза 1)

1. **Market Scanner** — cron job каждые 15 мин, забирает данные всех активных рынков с Polymarket API (цены, объёмы, ликвидность)
2. **Math Filter** — первый этап: находит математические аномалии (Yes+No != $1.00, резкие изменения цены, низкая ликвидность = потенциальный edge)
3. **Claude Analyzer** — второй этап: Claude API анализирует кандидатов, ищет новости/контекст через Perplexity, оценивает реальный edge, генерирует reasoning
4. **Telegram Alerter** — отправка сигнала в Telegram: рынок, цена, рекомендация, confidence, обоснование, estimated edge %
5. **Category Filter** — настраиваемый конфиг категорий (дефолт: crypto + politics)
6. **Signal Log** — SQLite лог всех сигналов для последующего анализа quality

### Фаза 2 (после валидации)

1. **Sentiment Scanner** — интеграция Grok API (X/Twitter) для sentiment analysis по теме рынка
2. **Performance Tracker** — автоматический трекинг P&L по сигналам (сравнение цены на момент сигнала vs resolution)
3. **Confidence Calibration** — анализ исторических сигналов, калибровка confidence score
4. **Multi-market Correlation** — поиск связанных рынков для cross-market arbitrage
5. **Web Dashboard** — простой UI для просмотра истории сигналов и performance

### Будущее развитие

- Semi-automated execution (подтверждение в Telegram → автоматический trade)
- Поддержка других prediction markets (Kalshi, Metaculus)
- Публичный Telegram канал с сигналами (монетизация)
- Portfolio management и position sizing рекомендации

## Технический стек

| Компонент | Рекомендация | Альтернативы | Обоснование |
|-----------|-------------|--------------|-------------|
| Runtime | Python 3.12 | — | Лучшая экосистема для data/API работы |
| AI Reasoning | Claude API (Sonnet) | GPT-4o | Лучший reasoning, tool use, structured output |
| Market Data | Polymarket CLOB API | TheGraph subgraph | REST API проще, real-time не нужен для cron |
| News Research | Perplexity API | Tavily, Exa | Лучший для актуальных новостей с источниками |
| Sentiment (Ф2) | Grok API (x_search) | — | Прямой доступ к X/Twitter данным |
| Alerts | Telegram Bot API | Discord | Telegram привычнее, мгновенные пуши |
| Storage | SQLite | PostgreSQL | Для MVP достаточно, zero config |
| Cache | Redis | File cache | Кэш рыночных данных между runs |
| Deploy | Docker + VPS | Lambda | $5/мес Hetzner, предсказуемо |
| Scheduler | cron (systemd timer) | APScheduler | Проще, надёжнее для single job |

## Концептуальная модель данных

### Основные сущности

- **Market** — рынок Polymarket: `id`, `question`, `category`, `end_date`, `yes_price`, `no_price`, `volume_24h`, `liquidity`, `last_updated`
- **Signal** — сгенерированный сигнал: `id`, `market_id`, `signal_type` (buy_yes/buy_no/arb), `confidence` (0-100), `estimated_edge_pct`, `reasoning`, `sources[]`, `created_at`
- **SignalOutcome** — результат сигнала: `signal_id`, `entry_price`, `resolution_price`, `pnl_pct`, `resolved_at`
- **ScanRun** — лог запуска: `id`, `started_at`, `markets_scanned`, `candidates_found`, `signals_generated`, `api_cost_usd`

### Ключевые связи

- Market → Signal: 1:N (один рынок может генерировать несколько сигналов в разное время)
- Signal → SignalOutcome: 1:1 (каждый сигнал имеет один исход после resolution)
- ScanRun → Signal: 1:N (один запуск может породить несколько сигналов)

## Архитектура Pipeline

```
[Cron 15min]
    │
    ▼
[Market Scanner] ── Polymarket API ──→ fetch all active markets
    │
    ▼
[Category Filter] ── config.yaml ──→ filter by selected categories
    │
    ▼
[Math Filter] ──→ detect anomalies:
    │   • Yes + No price deviation from $1.00
    │   • Price change > X% in last hour
    │   • Volume spike vs average
    │   • Low liquidity markets (easier to misprice)
    │
    ▼ (candidates: ~5-20 markets per run)
    │
[Claude Analyzer] ── Claude API + Perplexity ──→ deep analysis:
    │   • Fetch relevant news via Perplexity
    │   • Assess if price reflects current information
    │   • Estimate real probability vs market price
    │   • Calculate edge and confidence
    │   • Generate human-readable reasoning
    │
    ▼ (signals: 0-3 per run)
    │
[Telegram Alerter] ──→ send formatted signal
    │
    ▼
[Signal Logger] ──→ SQLite: log signal + scan metadata
```

## Формат Telegram сигнала

```
🔔 PolySignal Alert

📊 Market: "Will BTC exceed $150K by June 2026?"
🏷 Category: Crypto
💰 Current: Yes $0.35 | No $0.65

📈 Signal: BUY YES
🎯 Confidence: 78/100
📐 Estimated Edge: +12%

💡 Reasoning:
Bitcoin уже на $142K, momentum сильный после ETF inflows.
Perplexity: 3 источника подтверждают institutional buying.
Рынок отстаёт от реальной вероятности на ~12%.

🔗 https://polymarket.com/event/...
⏰ 2026-04-04 14:30 UTC
```

## Аутентификация и безопасность

- **Аутентификация:** не требуется (single user, self-hosted)
- **API ключи:** environment variables в `.env`, не в коде
- **Telegram:** private chat с ботом, chat_id в конфиге
- **Защита:** rate limiting на API calls, circuit breaker при ошибках
- **Финансовые данные:** сигналы не содержат wallet keys или private data

## Конфигурация (config.yaml)

```yaml
# Scan settings
scan_interval_minutes: 15
categories: ["crypto", "politics"]
min_liquidity_usd: 1000
min_volume_24h_usd: 500

# Math filter thresholds
price_deviation_threshold: 0.02  # Yes+No отклонение от $1
price_change_threshold_pct: 10   # % изменение за час
volume_spike_multiplier: 3       # X раз больше среднего

# Claude analyzer
claude_model: "claude-sonnet-4-6-20250514"
max_candidates_per_run: 10
min_confidence_to_alert: 60

# Alerts
telegram_chat_id: "123456789"

# Budget
max_daily_api_cost_usd: 5.0
```

## Оценка стоимости

| Компонент | Стоимость/мес | Расчёт |
|-----------|--------------|--------|
| Hetzner VPS (CX22) | $5 | 2 vCPU, 4GB RAM |
| Claude API (Sonnet) | ~$10-20 | ~100 signals/day × ~2K tokens |
| Perplexity API | ~$5 | ~100 queries/day |
| Telegram Bot | $0 | бесплатно |
| Redis (на VPS) | $0 | включён |
| **Итого** | **~$20-30/мес** | |

## Этапы разработки

### Этап 1: MVP Core (1 неделя)

- [ ] Scaffold проекта: Docker, config, env
- [ ] Polymarket API client: fetch markets, prices, volumes
- [ ] Math Filter: базовые аномалии (price deviation, volume spike)
- [ ] Claude Analyzer: prompt engineering, structured output
- [ ] Perplexity integration: news search по теме рынка
- [ ] Telegram Bot: форматированные алерты
- [ ] Signal Logger: SQLite schema + запись
- [ ] Cron setup: systemd timer / Docker cron
- [ ] Deploy на Hetzner

### Этап 2: Качество сигналов (1 неделя)

- [ ] Калибровка порогов Math Filter на реальных данных
- [ ] Улучшение Claude prompt на основе первых сигналов
- [ ] Category filter с конфигом
- [ ] Cost tracking (API расходы за run)
- [ ] Basic health monitoring (Telegram alert если сканер упал)

### Этап 3: Performance Tracking (1 неделя)

- [ ] SignalOutcome tracking: автоматический check resolved markets
- [ ] P&L расчёт по сигналам
- [ ] Weekly summary в Telegram: hit rate, total edge, best/worst
- [ ] Sentiment scanner (Grok API) — Фаза 2

### Этап 4: Масштабирование

- [ ] Web dashboard (если сигналы прибыльные)
- [ ] Multi-market correlation
- [ ] Публичный канал
- [ ] Semi-automated execution

## Потенциальные вызовы и решения

| Вызов | Влияние | Предложенное решение |
|-------|---------|---------------------|
| Polymarket API rate limits | Пропуск данных | Кэширование в Redis, incremental updates |
| Claude hallucinations в reasoning | Ложные сигналы | Structured output + fact-checking через Perplexity |
| Математический арбитраж (Yes+No>$1) исчезает за секунды | Нет edge для ручной торговли | Фокус на информационный edge (новости), не чистый арбитраж |
| Стоимость Claude API при частых запросах | Бюджет > $30/мес | Budget cap в конфиге, Haiku для pre-screening |
| Polymarket может заблокировать API | Сервис не работает | Fallback на TheGraph subgraph |
| Prediction market регуляция | Юридические риски | Только research/signals, НЕ automated trading |
| Edge erosion (другие боты) | Сигналы теряют ценность | Фокус на нишевых/малоликвидных рынках |
| Ложноположительные сигналы | Потеря капитала | Начать с paper trading, min confidence threshold |

## Метрики успеха

| Метрика | Target (Месяц 1) | Target (Месяц 3) |
|---------|------------------|------------------|
| Signal hit rate | >55% | >60% |
| Average edge per signal | >5% | >8% |
| Signals per day | 3-10 | 5-15 |
| False positive rate | <40% | <30% |
| Monthly API cost | <$30 | <$50 |
| Uptime | >95% | >99% |

## Будущие возможности

- **Semi-auto execution:** подтверждение сигнала в Telegram → автоматический trade через Polymarket smart contracts
- **Multi-platform:** Kalshi (regulated US), Metaculus (non-monetary), Manifold Markets
- **Social signal channel:** публичный Telegram с delayed signals (монетизация через подписку)
- **Backtesting engine:** проверка стратегий на исторических данных
- **Portfolio optimizer:** Kelly criterion position sizing с учётом корреляций
- **Copy-trading:** другие пользователи копируют сигналы (SaaS модель)

---

## Связанные документы

- [[2026-04-04 - AI Daily Digest]] — исходный пост @RoundtableSpace про Polymarket arbitrage бота
