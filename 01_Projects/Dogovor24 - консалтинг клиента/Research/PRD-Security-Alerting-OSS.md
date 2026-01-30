# Система алертов на подозрительную активность Dogovor24

! _Все правила, конфигурации и примеры кода в файле составлены при помощи AI Claude, СТРОГО РЕКОМЕНДУЕТСЯ к применению только специалистам, с обязательной проверкой и доработкой под реалии проекта_

## 1. Executive Summary

### 1.1 Проблема

По результатам security-аудитов выявлено отсутствие системы обнаружения и оповещения о подозрительной активности:

| Проблема                          | Риск                          | Текущее состояние                 |
| --------------------------------- | ----------------------------- | --------------------------------- |
| Brute-force атаки                 | Компрометация учётных записей | Только Redis-счётчик, нет алертов |
| Credential stuffing               | Массовый захват аккаунтов     | Не детектируется                  |
| IDOR/Enumeration                  | Утечка данных                 | Не детектируется                  |
| Аномальный доступ к файлам        | Exfiltration                  | Не детектируется                  |
| Подозрительные платёжные операции | Fraud                         | Не детектируется                  |
| Privilege escalation              | Захват системы                | Не детектируется                  |
| SMS/Email bombing                 | Финансовые потери, репутация  | Не детектируется                  |

### 1.2 Цель

Внедрить систему обнаружения угроз и оповещения на базе **opensource компонентов** для:

- **Обнаружения атак в реальном времени** (MTTD <5 мин для критических)
- **Автоматического реагирования** на определённые типы угроз
- **Эскалации** критических инцидентов в Security Team
- **Снижения false positives** через threshold tuning и контекстный анализ

### 1.3 Ограничения стека

Используется **бесплатная версия Elasticsearch** (Basic/OSS), поэтому:

| Компонент              | Статус | Альтернатива                  |
| ---------------------- | ------ | ----------------------------- |
| Elasticsearch Watcher  | ❌     | ElastAlert 2                  |
| Elasticsearch ML       | ❌     | Python детекторы + thresholds |
| Kibana Alerting        | ❌     | ElastAlert 2                  |
| SIEM App               | ❌     | Custom Kibana dashboards      |
| Basic Security (RBAC)  | ✅     | Доступно с ES 7.1+            |
| Index Lifecycle Mgmt   | ✅     | Доступно                      |
| Kibana (визуализация)  | ✅     | Доступно                      |

### 1.4 Ключевые метрики успеха

| Метрика                               | Текущее | Целевое                   |
| ------------------------------------- | ------- | ------------------------- |
| Mean Time to Detect (MTTD) — Critical | N/A     | <5 мин                    |
| Mean Time to Detect (MTTD) — High     | N/A     | <15 мин                   |
| False Positive Rate                   | N/A     | <10%                      |
| Alert Coverage                        | 0%      | >80% атак из OWASP Top 10 |
| Auto-remediation Rate                 | 0%      | >30% для P0 алертов       |

---

## 2. Архитектура системы алертов

### 2.1 Общая схема (OSS Stack)

```txt
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              DATA SOURCES                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  ┌──────────────┐        │
│  │ Security     │  │ Application  │  │ Infrastructure│  │ Nginx        │        │
│  │ Logs         │  │ Logs         │  │ Logs          │  │ Access Logs  │        │
│  └──────┬───────┘  └──────┬───────┘  └──────┬────────┘  └──────┬───────┘        │
│         │                 │                 │                  │                │
└─────────┼─────────────────┼─────────────────┼──────────────────┼────────────────┘
          │                 │                 │                  │
          ▼                 ▼                 ▼                  ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         LOG AGGREGATION LAYER                                   │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                    Elasticsearch (Basic/OSS)                            │    │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐                │    │
│  │  │ security-*    │  │ app-*         │  │ nginx-*       │                │    │
│  │  │ (ILM: 7 days) │  │ (ILM: 30 days)│  │ (ILM: 14 days)│                │    │
│  │  └───────────────┘  └───────────────┘  └───────────────┘                │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         DETECTION ENGINE (OSS)                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                                                                         │    │
│  │  ┌───────────────────────┐       ┌───────────────────────┐              │    │
│  │  │   ElastAlert 2        │       │  Python Detectors     │              │    │
│  │  │   ─────────────────   │       │  ───────────────────  │              │    │
│  │  │   • Frequency rules   │       │  • Threshold-based    │              │    │
│  │  │   • Spike rules       │       │  • Statistical (std)  │              │    │
│  │  │   • Flatline rules    │       │  • Pattern matching   │              │    │
│  │  │   • Blacklist rules   │       │  • Geo-velocity       │              │    │
│  │  │   • Whitelist rules   │       │  • Baseline compare   │              │    │
│  │  │   • Change rules      │       │                       │              │    │
│  │  └───────────┬───────────┘       └───────────┬───────────┘              │    │
│  │              │                               │                          │    │
│  │              └───────────────┬───────────────┘                          │    │
│  │                              ▼                                          │    │
│  │                   ┌─────────────────────┐                               │    │
│  │                   │  Alert Aggregator   │                               │    │
│  │                   │  (Dedup & Enrich)   │                               │    │
│  │                   └──────────┬──────────┘                               │    │
│  │                              │                                          │    │
│  └──────────────────────────────┼──────────────────────────────────────────┘    │
└─────────────────────────────────┼───────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         RESPONSE LAYER                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                     Auto-Response Service (PHP)                         │    │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐                │    │
│  │  │ IP Blocker    │  │ User          │  │ Rate Limit    │                │    │
│  │  │ (Redis)       │  │ Suspender     │  │ Adjuster      │                │    │
│  │  └───────────────┘  └───────────────┘  └───────────────┘                │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
│                                      │                                          │
│         ┌────────────────────────────┼────────────────────────────┐             │
│         ▼                            ▼                            ▼             │
│  ┌──────────────┐           ┌──────────────┐           ┌──────────────┐         │
│  │ Telegram Bot │           │ Discord      │           │ Email        │         │
│  │ (Critical)   │           │ (High/Med)   │           │ (Low/Info)   │         │
│  └──────────────┘           └──────────────┘           └──────────────┘         │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Компоненты системы

| Компонент            | Технология                   | Назначение                           |
| -------------------- | ---------------------------- | ------------------------------------ |
| Log Storage          | Elasticsearch 7.x (Basic)    | Хранение и индексация событий        |
| **Rule Engine**      | **ElastAlert 2**             | Основной detection engine            |
| **Anomaly Detection**| **Python + Cron**            | Статистические детекторы             |
| Alert Aggregator     | Custom PHP service           | Deduplication, enrichment            |
| Notification         | Telegram Bot, Discord, Email | Оповещения по каналам                |
| Auto-Response        | Custom PHP + Redis           | Блокировки, rate limiting            |
| Visualization        | Kibana (OSS)                 | Dashboards и investigation           |

### 2.3 Почему ElastAlert 2?

ElastAlert 2 — это **форк оригинального ElastAlert от Yelp**, активно поддерживаемый сообществом:

- ✅ Полностью opensource (Apache 2.0)
- ✅ Совместим с Elasticsearch 7.x/8.x
- ✅ Не требует платных фич Elasticsearch
- ✅ Поддержка множества типов правил
- ✅ Интеграция с Telegram, Discord, PagerDuty, webhooks
- ✅ Python-based — легко расширять

**Типы правил ElastAlert 2:**

| Тип правила     | Описание                                              | Применение                    |
| --------------- | ----------------------------------------------------- | ----------------------------- |
| `frequency`     | Срабатывает при N событий за период                   | Brute force, rate limiting    |
| `spike`         | Срабатывает при резком росте/падении                  | DDoS, traffic anomalies       |
| `flatline`      | Срабатывает при отсутствии событий                    | Service health, heartbeat     |
| `blacklist`     | Срабатывает при появлении значения из списка          | Known bad IPs, banned users   |
| `whitelist`     | Срабатывает при отсутствии значения в списке          | Unexpected access             |
| `change`        | Срабатывает при изменении значения поля               | Config changes, role changes  |
| `new_term`      | Срабатывает при появлении нового значения             | New user agents, new IPs      |
| `cardinality`   | Срабатывает при превышении уникальных значений        | Credential stuffing           |
| `metric_aggregation` | Срабатывает при превышении агрегированной метрики | High error rate               |
| `percentage_match`   | Срабатывает при превышении процента совпадений    | Success/failure ratio         |

---

## 3. Категории алертов

### 3.1 Матрица приоритетов

| Priority | Severity | Response Time | Auto-Response   | Notification          |
| -------- | -------- | ------------- | --------------- | --------------------- |
| **P0**   | CRITICAL | <5 мин        | Да (блокировка) | Telegram + SMS        |
| **P1**   | HIGH     | <15 мин       | Опционально     | Telegram + Discord    |
| **P2**   | MEDIUM   | <1 час        | Нет             | Discord + Email       |
| **P3**   | LOW      | <24 часа      | Нет             | Email only            |
| **P4**   | INFO     | Best effort   | Нет             | Dashboard only        |

### 3.2 Каталог алертов (OSS-совместимые)

| ID              | Name                          | Priority | Тип правила       | Auto-Response |
| --------------- | ----------------------------- | -------- | ----------------- | ------------- |
| ALERT-AUTH-001  | Brute Force Attack            | P0       | frequency         | IP Block      |
| ALERT-AUTH-002  | Credential Stuffing           | P0       | cardinality       | IP Block 24h  |
| ALERT-AUTH-003  | 2FA Bypass Attempt            | P1       | frequency         | 2FA Lock      |
| ALERT-AUTH-004  | Password Spray                | P0       | cardinality       | Rate Limit    |
| ALERT-AUTH-005  | Success After Failures        | P1       | frequency + query | Session Flag  |
| ALERT-AUTH-006  | New Login Location            | P2       | new_term          | Notify User   |
| ALERT-AUTH-007  | After-Hours Admin Access      | P2       | frequency + query | —             |
| ALERT-AUTHZ-001 | Mass Access Denied (IDOR)     | P1       | frequency         | Rate Limit    |
| ALERT-AUTHZ-002 | Privilege Escalation          | P0       | change            | User Suspend  |
| ALERT-AUTHZ-003 | Cross-Workspace Access        | P1       | frequency         | —             |
| ALERT-DATA-001  | Bulk File Download            | P1       | frequency + spike | —             |
| ALERT-DATA-002  | Large Data Export             | P2       | metric_aggregation| —             |
| ALERT-BIZ-001   | Suspicious Payment            | P0       | frequency         | —             |
| ALERT-BIZ-002   | Refund Anomaly                | P1       | spike             | —             |
| ALERT-INT-001   | API Rate Limit Exceeded       | P2       | frequency         | —             |
| ALERT-INT-002   | SMS/Email Bombing             | P0       | frequency         | Block         |
| ALERT-WF-001    | Unauthorized ESEDO Action     | P0       | blacklist/query   | —             |
| ALERT-SYS-001   | Service Error Rate Spike      | P1       | percentage_match  | —             |
| ALERT-SYS-002   | Service Heartbeat Missing     | P0       | flatline          | —             |

---

## 4. Детальные правила ElastAlert 2

### 4.1 Структура конфигурации

```txt
/etc/elastalert2/
├── config.yaml                    # Основная конфигурация
├── rules/
│   ├── auth/
│   │   ├── brute_force.yaml
│   │   ├── credential_stuffing.yaml
│   │   ├── 2fa_bypass.yaml
│   │   ├── password_spray.yaml
│   │   ├── success_after_failures.yaml
│   │   ├── new_login_location.yaml
│   │   └── after_hours_access.yaml
│   ├── authz/
│   │   ├── mass_access_denied.yaml
│   │   ├── privilege_escalation.yaml
│   │   └── cross_workspace.yaml
│   ├── data/
│   │   ├── bulk_download.yaml
│   │   └── large_export.yaml
│   ├── business/
│   │   ├── suspicious_payment.yaml
│   │   └── refund_anomaly.yaml
│   ├── integration/
│   │   ├── rate_limit_exceeded.yaml
│   │   └── notification_bombing.yaml
│   └── system/
│       ├── error_rate_spike.yaml
│       └── service_heartbeat.yaml
└── scripts/
    └── auto_response.py           # Webhook handler для auto-response
```

### 4.2 Основная конфигурация

```yaml
# /etc/elastalert2/config.yaml

# Elasticsearch connection
es_host: elasticsearch.logging.svc.cluster.local
es_port: 9200
es_username: elastalert
es_password: ${ES_ELASTALERT_PASSWORD}

# ElastAlert settings
rules_folder: /etc/elastalert2/rules
run_every:
  minutes: 1
buffer_time:
  minutes: 15

# Writeback index for ElastAlert status
writeback_index: elastalert_status
writeback_alias: elastalert_status_alias

# Alert time limit
alert_time_limit:
  days: 2

# Logging
logging:
  version: 1
  handlers:
    file:
      class: logging.FileHandler
      filename: /var/log/elastalert2/elastalert.log
    console:
      class: logging.StreamHandler
  root:
    level: INFO
    handlers: [file, console]
```

### 4.3 Правила Authentication

#### ALERT-AUTH-001: Brute Force Attack

```yaml
# /etc/elastalert2/rules/auth/brute_force.yaml

name: "ALERT-AUTH-001: Brute Force Attack"
type: frequency

# Data source
index: security-*
timestamp_field: "@timestamp"

# Detection: 10+ failed logins from same IP in 5 minutes
num_events: 10
timeframe:
  minutes: 5

# Group by source IP
query_key: request.ip

# Filter
filter:
  - term:
      event_type.keyword: "AUTH_LOGIN_FAILED"

# Don't alert again for same IP within 1 hour
realert:
  hours: 1

# Exponential backoff for persistent attackers
exponential_realert:
  hours: 24

# Include these fields in alert
include:
  - request.ip
  - request.user_agent
  - context.login
  - "@timestamp"

# Aggregation - collect all events
aggregation:
  minutes: 2

# Alert configuration
alert:
  - telegram
  - command

# Telegram settings
telegram_bot_token: "${TELEGRAM_BOT_TOKEN}"
telegram_room_id: "${TELEGRAM_SECURITY_CRITICAL}"
telegram_parse_mode: "markdown"

telegram_text: |
  🚨 *ALERT-AUTH-001: Brute Force Attack*

  *Severity:* CRITICAL
  *Time:* {{ '@timestamp' }}

  *Details:*
  • Source IP: `{{ request.ip }}`
  • Failed attempts: {{ num_matches }}
  • User Agent: {{ request.user_agent }}

  *Auto-Response:*
  ✅ IP will be blocked for 1 hour

  [Investigate in Kibana](https://kibana.dogovor24.kz/app/discover#/?_g=(time:(from:now-1h,to:now))&_a=(query:(query_string:(query:'request.ip:"{{ request.ip }}"'))))

# Auto-response command
command:
  - "/opt/security/bin/auto_response.sh"
  - "block_ip"
  - "%(request.ip)s"
  - "3600"
  - "ALERT-AUTH-001"
  - "brute_force"
```

#### ALERT-AUTH-002: Credential Stuffing

```yaml
# /etc/elastalert2/rules/auth/credential_stuffing.yaml

name: "ALERT-AUTH-002: Credential Stuffing Attack"
type: cardinality

index: security-*
timestamp_field: "@timestamp"

# Detection: 50+ unique logins attempted from same IP in 10 minutes
cardinality_field: context.login
max_cardinality: 50
timeframe:
  minutes: 10

query_key: request.ip

filter:
  - term:
      event_type.keyword: "AUTH_LOGIN_FAILED"

realert:
  hours: 24

include:
  - request.ip
  - request.user_agent
  - "@timestamp"

alert:
  - telegram
  - command

telegram_bot_token: "${TELEGRAM_BOT_TOKEN}"
telegram_room_id: "${TELEGRAM_SECURITY_CRITICAL}"
telegram_parse_mode: "markdown"

telegram_text: |
  🚨 *ALERT-AUTH-002: Credential Stuffing Attack*

  *Severity:* CRITICAL
  *Time:* {{ '@timestamp' }}

  *Details:*
  • Source IP: `{{ request.ip }}`
  • Unique logins attempted: {{ cardinality }}
  • Timeframe: 10 minutes

  *Auto-Response:*
  ✅ IP will be blocked for 24 hours

  *Investigation:*
  This indicates use of leaked credential database.
  Check if any logins were successful.

command:
  - "/opt/security/bin/auto_response.sh"
  - "block_ip"
  - "%(request.ip)s"
  - "86400"
  - "ALERT-AUTH-002"
  - "credential_stuffing"
```

#### ALERT-AUTH-003: 2FA Bypass Attempt

```yaml
# /etc/elastalert2/rules/auth/2fa_bypass.yaml

name: "ALERT-AUTH-003: 2FA Bypass Attempt"
type: frequency

index: security-*
timestamp_field: "@timestamp"

# 5+ failed 2FA attempts for same user in 10 minutes
num_events: 5
timeframe:
  minutes: 10

query_key: actor.user_id

filter:
  - term:
      event_type.keyword: "AUTH_2FA_FAILED"

realert:
  hours: 1

include:
  - actor.user_id
  - actor.email
  - request.ip
  - "@timestamp"

alert:
  - telegram
  - command

telegram_bot_token: "${TELEGRAM_BOT_TOKEN}"
telegram_room_id: "${TELEGRAM_SECURITY_HIGH}"
telegram_parse_mode: "markdown"

telegram_text: |
  ⚠️ *ALERT-AUTH-003: 2FA Bypass Attempt*

  *Severity:* HIGH
  *Time:* {{ '@timestamp' }}

  *Details:*
  • User ID: `{{ actor.user_id }}`
  • Email: {{ actor.email }}
  • Source IP: `{{ request.ip }}`
  • Failed 2FA attempts: {{ num_matches }}

  *Auto-Response:*
  ✅ 2FA temporarily locked for this user

# Discord webhook (for P1/P2 alerts)
# - discord_webhook_url: "${DISCORD_SECURITY_WEBHOOK}"

command:
  - "/opt/security/bin/auto_response.sh"
  - "lock_2fa"
  - "%(actor.user_id)s"
  - "1800"
  - "ALERT-AUTH-003"
```

#### ALERT-AUTH-004: Password Spray Attack

```yaml
# /etc/elastalert2/rules/auth/password_spray.yaml

name: "ALERT-AUTH-004: Password Spray Attack"
type: cardinality

index: security-*
timestamp_field: "@timestamp"

# Many IPs trying the same few passwords across many accounts
# Detection: 10+ unique IPs with failed logins in 30 minutes
cardinality_field: request.ip
max_cardinality: 10
timeframe:
  minutes: 30

# Only trigger if many unique logins are also targeted
filter:
  - term:
      event_type.keyword: "AUTH_LOGIN_FAILED"

# Additional check via raw query
raw_count_keys:
  - context.login

realert:
  hours: 1

include:
  - request.ip
  - context.login
  - "@timestamp"

aggregation:
  minutes: 5

alert:
  - telegram

telegram_bot_token: "${TELEGRAM_BOT_TOKEN}"
telegram_room_id: "${TELEGRAM_SECURITY_CRITICAL}"
telegram_parse_mode: "markdown"

telegram_text: |
  🚨 *ALERT-AUTH-004: Password Spray Attack*

  *Severity:* CRITICAL
  *Time:* {{ '@timestamp' }}

  *Details:*
  • Unique attacking IPs: {{ cardinality }}
  • Timeframe: 30 minutes

  *Pattern:*
  Distributed attack - many IPs trying common passwords.

  *Action Required:*
  1. Check if any logins succeeded
  2. Consider enabling enhanced rate limiting
  3. Review password policy
```

#### ALERT-AUTH-005: Successful Login After Multiple Failures

```yaml
# /etc/elastalert2/rules/auth/success_after_failures.yaml

name: "ALERT-AUTH-005: Successful Login After Attack Pattern"
type: frequency

index: security-*
timestamp_field: "@timestamp"

# First, we need a custom query to find this pattern
# This rule triggers on successful login
num_events: 1
timeframe:
  minutes: 1

filter:
  - term:
      event_type.keyword: "AUTH_LOGIN_SUCCESS"

# We'll use a more complex approach with aggregation_key
query_key: context.login

# Custom filter using query_string to check for prior failures
# This requires a two-stage check which we'll handle in the alert
use_count_query: true
doc_type: _doc

realert:
  minutes: 30

include:
  - actor.user_id
  - context.login
  - request.ip
  - request.user_agent
  - "@timestamp"

# Use webhook to check for prior failures
alert:
  - command

# The command will verify if there were 5+ failures before this success
command:
  - "/opt/security/bin/check_prior_failures.sh"
  - "%(context.login)s"
  - "%(request.ip)s"
  - "%(actor.user_id)s"
```

#### ALERT-AUTH-006: Login from New Location

```yaml
# /etc/elastalert2/rules/auth/new_login_location.yaml

name: "ALERT-AUTH-006: Login from New Location"
type: new_term

index: security-*
timestamp_field: "@timestamp"

# Alert when user logs in from a new country
fields:
  - actor.user_id
  - geo.country_iso_code

# Look back 30 days for baseline
terms_window_size:
  days: 30

filter:
  - term:
      event_type.keyword: "AUTH_LOGIN_SUCCESS"

# Only alert for non-KZ/RU countries (our main regions)
filter:
  - bool:
      must:
        - term:
            event_type.keyword: "AUTH_LOGIN_SUCCESS"
      must_not:
        - terms:
            geo.country_iso_code: ["KZ", "RU"]

realert:
  days: 1

include:
  - actor.user_id
  - actor.email
  - request.ip
  - geo.country_iso_code
  - geo.city_name
  - "@timestamp"

alert:
  - telegram

telegram_bot_token: "${TELEGRAM_BOT_TOKEN}"
telegram_room_id: "${TELEGRAM_SECURITY_MEDIUM}"
telegram_parse_mode: "markdown"

telegram_text: |
  📢 *ALERT-AUTH-006: Login from New Location*

  *Severity:* MEDIUM
  *Time:* {{ '@timestamp' }}

  *Details:*
  • User: {{ actor.email }}
  • New Country: {{ geo.country_iso_code }}
  • City: {{ geo.city_name }}
  • IP: `{{ request.ip }}`

  *Action:*
  Verify this is legitimate user activity.
```

### 4.4 Правила Authorization

#### ALERT-AUTHZ-001: Mass Access Denied (IDOR Probing)

```yaml
# /etc/elastalert2/rules/authz/mass_access_denied.yaml

name: "ALERT-AUTHZ-001: Mass Access Denied (IDOR Probing)"
type: frequency

index: security-*
timestamp_field: "@timestamp"

# 20+ access denied events per user in 5 minutes
num_events: 20
timeframe:
  minutes: 5

query_key: actor.user_id

filter:
  - term:
      event_type.keyword: "AUTHZ_ACCESS_DENIED"

realert:
  minutes: 30

include:
  - actor.user_id
  - actor.email
  - request.ip
  - target.resource_type
  - "@timestamp"

alert:
  - telegram
  - command

telegram_bot_token: "${TELEGRAM_BOT_TOKEN}"
telegram_room_id: "${TELEGRAM_SECURITY_HIGH}"
telegram_parse_mode: "markdown"

telegram_text: |
  ⚠️ *ALERT-AUTHZ-001: IDOR Probing Detected*

  *Severity:* HIGH
  *Time:* {{ '@timestamp' }}

  *Details:*
  • User ID: `{{ actor.user_id }}`
  • Email: {{ actor.email }}
  • Access denied count: {{ num_matches }}
  • Resource type: {{ target.resource_type }}

  *Pattern:*
  User is attempting to access many resources they don't own.
  Possible IDOR enumeration attack.

  *Auto-Response:*
  ✅ Rate limit reduced for this user

command:
  - "/opt/security/bin/auto_response.sh"
  - "reduce_rate_limit"
  - "%(actor.user_id)s"
  - "1800"
  - "ALERT-AUTHZ-001"
```

#### ALERT-AUTHZ-002: Privilege Escalation

```yaml
# /etc/elastalert2/rules/authz/privilege_escalation.yaml

name: "ALERT-AUTHZ-002: Privilege Escalation Detected"
type: any

index: security-*
timestamp_field: "@timestamp"

filter:
  - bool:
      must:
        - term:
            event_type.keyword: "AUTHZ_ROLE_ASSIGNED"
        - terms:
            context.new_role.keyword: ["admin", "super-admin", "operator"]
      must_not:
        - term:
            actor.is_system: true
        - terms:
            actor.role.keyword: ["admin", "super-admin"]

realert:
  minutes: 5

include:
  - actor.user_id
  - actor.email
  - actor.role
  - target.user_id
  - context.new_role
  - "@timestamp"

alert:
  - telegram
  - command

telegram_bot_token: "${TELEGRAM_BOT_TOKEN}"
telegram_room_id: "${TELEGRAM_SECURITY_CRITICAL}"
telegram_parse_mode: "markdown"

telegram_text: |
  🚨 *ALERT-AUTHZ-002: Privilege Escalation*

  *Severity:* CRITICAL
  *Time:* {{ '@timestamp' }}

  *Details:*
  • Actor: {{ actor.email }} (role: {{ actor.role }})
  • Target User: {{ target.user_id }}
  • New Role Assigned: *{{ context.new_role }}*

  ⚠️ Non-admin user assigned admin privileges!

  *Auto-Response:*
  ✅ Target user session invalidated

command:
  - "/opt/security/bin/auto_response.sh"
  - "suspend_user"
  - "%(target.user_id)s"
  - "0"
  - "ALERT-AUTHZ-002"
  - "privilege_escalation"
```

### 4.5 Правила Data Access

#### ALERT-DATA-001: Bulk File Download

```yaml
# /etc/elastalert2/rules/data/bulk_download.yaml

name: "ALERT-DATA-001: Bulk File Download"
type: frequency

index: security-*
timestamp_field: "@timestamp"

# 50+ file downloads per user in 1 hour
num_events: 50
timeframe:
  hours: 1

query_key: actor.user_id

filter:
  - term:
      event_type.keyword: "DATA_FILE_DOWNLOADED"

realert:
  hours: 2

include:
  - actor.user_id
  - actor.email
  - request.ip
  - "@timestamp"

# Add spike detection as secondary check
alert:
  - telegram

telegram_bot_token: "${TELEGRAM_BOT_TOKEN}"
telegram_room_id: "${TELEGRAM_SECURITY_HIGH}"
telegram_parse_mode: "markdown"

telegram_text: |
  ⚠️ *ALERT-DATA-001: Bulk File Download*

  *Severity:* HIGH
  *Time:* {{ '@timestamp' }}

  *Details:*
  • User: {{ actor.email }}
  • Files downloaded: {{ num_matches }}
  • Timeframe: 1 hour
  • IP: `{{ request.ip }}`

  *Action:*
  1. Verify user identity
  2. Check if this is expected behavior
  3. Review downloaded file types
```

### 4.5.1 Discord Webhook Configuration

Для P1/P2 алертов используем Discord через webhook:

```yaml
# Пример Discord alerter в правиле ElastAlert 2
alert:
  - post

http_post_url: "${DISCORD_SECURITY_WEBHOOK}"
http_post_static_payload:
  username: "Security Bot"
  avatar_url: "https://dogovor24.kz/security-bot.png"

http_post_payload:
  embeds:
    - title: "{{ rule.name }}"
      color: 15158332  # Red color
      fields:
        - name: "Severity"
          value: "{{ rule.severity | default('HIGH') }}"
          inline: true
        - name: "Time"
          value: "{{ '@timestamp' }}"
          inline: true
        - name: "Details"
          value: "IP: `{{ request.ip }}`\nUser: {{ actor.email | default('N/A') }}"
      footer:
        text: "Dogovor24 Security"
```

### 4.6 Правила Integration

#### ALERT-INT-002: SMS/Email Bombing

```yaml
# /etc/elastalert2/rules/integration/notification_bombing.yaml

name: "ALERT-INT-002: Notification Bombing"
type: frequency

index: security-*
timestamp_field: "@timestamp"

# 5+ SMS/2FA requests to same phone in 10 minutes
num_events: 5
timeframe:
  minutes: 10

query_key: context.phone_number

filter:
  - bool:
      should:
        - term:
            event_type.keyword: "AUTH_2FA_REQUESTED"
        - term:
            event_type.keyword: "AUTH_PASSWORD_RESET_REQUESTED"
      minimum_should_match: 1

realert:
  hours: 1

include:
  - context.phone_number
  - context.email
  - request.ip
  - "@timestamp"

alert:
  - telegram
  - command

telegram_bot_token: "${TELEGRAM_BOT_TOKEN}"
telegram_room_id: "${TELEGRAM_SECURITY_CRITICAL}"
telegram_parse_mode: "markdown"

telegram_text: |
  🚨 *ALERT-INT-002: SMS/Email Bombing*

  *Severity:* CRITICAL
  *Time:* {{ '@timestamp' }}

  *Details:*
  • Phone/Email: {{ context.phone_number }}{{ context.email }}
  • Requests: {{ num_matches }}
  • Timeframe: 10 minutes
  • Source IP: `{{ request.ip }}`

  *Impact:*
  • SMS costs accumulating
  • User harassment

  *Auto-Response:*
  ✅ Notifications blocked for this recipient

command:
  - "/opt/security/bin/auto_response.sh"
  - "block_notifications"
  - "%(context.phone_number)s"
  - "3600"
  - "ALERT-INT-002"
```

### 4.7 Правила System

#### ALERT-SYS-001: Service Error Rate Spike

```yaml
# /etc/elastalert2/rules/system/error_rate_spike.yaml

name: "ALERT-SYS-001: Service Error Rate Spike"
type: spike

index: app-*
timestamp_field: "@timestamp"

# Spike detection: current period vs reference
spike_height: 3
spike_type: "up"
timeframe:
  minutes: 5

# Only count errors
filter:
  - range:
      response.status:
        gte: 500

# Group by service
query_key: service.name

realert:
  minutes: 15

include:
  - service.name
  - response.status
  - "@timestamp"

alert:
  - telegram

telegram_bot_token: "${TELEGRAM_BOT_TOKEN}"
telegram_room_id: "${TELEGRAM_SECURITY_HIGH}"
telegram_parse_mode: "markdown"

telegram_text: |
  ⚠️ *ALERT-SYS-001: Error Rate Spike*

  *Severity:* HIGH
  *Time:* {{ '@timestamp' }}

  *Details:*
  • Service: {{ service.name }}
  • Error spike: {{ spike_height }}x normal rate

  *Possible causes:*
  • Deployment issue
  • Infrastructure problem
  • DDoS attack
```

#### ALERT-SYS-002: Service Heartbeat Missing

```yaml
# /etc/elastalert2/rules/system/service_heartbeat.yaml

name: "ALERT-SYS-002: Service Heartbeat Missing"
type: flatline

index: heartbeat-*
timestamp_field: "@timestamp"

# Alert if no heartbeat for 5 minutes
threshold: 1
timeframe:
  minutes: 5

query_key: service.name

filter:
  - term:
      event_type.keyword: "HEARTBEAT"

realert:
  minutes: 10

include:
  - service.name
  - "@timestamp"

alert:
  - telegram

telegram_bot_token: "${TELEGRAM_BOT_TOKEN}"
telegram_room_id: "${TELEGRAM_SECURITY_CRITICAL}"
telegram_parse_mode: "markdown"

telegram_text: |
  🚨 *ALERT-SYS-002: Service Down*

  *Severity:* CRITICAL
  *Time:* {{ '@timestamp' }}

  *Details:*
  • Service: {{ service.name }}
  • No heartbeat for: 5+ minutes

  *Immediate action required!*
```

---

## 5. Python-based Detectors (замена ML)

Для сценариев, которые сложно реализовать через ElastAlert, используем Python-скрипты запускаемые по cron.

### 5.1 Geo-Velocity Detector (Impossible Travel)

**Назначение:** Детектор "невозможных путешествий" выявляет ситуации, когда пользователь входит в систему из географически удалённых мест за слишком короткий промежуток времени (быстрее, чем физически возможно переместиться).

**Периодичность запуска:** Каждые 5 минут через cron/CronJob.

**Расположение:** `/opt/security/detectors/geo_velocity.py`

#### Конфигурационные параметры

| Параметр | Значение | Описание |
|----------|----------|----------|
| `MAX_SPEED_KMH` | 1000 км/ч | Максимальная реалистичная скорость перемещения (скоростной самолёт) |
| `LOOKBACK_HOURS` | 2 часа | Глубина анализа логинов |
| `MIN_DISTANCE_KM` | 500 км | Минимальное расстояние для срабатывания (игнорируем близкие локации) |

#### Алгоритм работы

1. **Сбор данных:**
   - Получить из Elasticsearch все успешные логины (`AUTH_LOGIN_SUCCESS`) за последние `LOOKBACK_HOURS` часов
   - Отфильтровать только записи с geo-данными (`geo.location` существует)
   - Извлечь поля: `actor.user_id`, `actor.email`, `request.ip`, `geo.location`, `geo.country_iso_code`, `geo.city_name`, `@timestamp`

2. **Группировка:**
   - Сгруппировать все логины по `user_id`
   - Пропустить пользователей с менее чем 2 логинами за период

3. **Анализ для каждого пользователя:**
   - Отсортировать логины по времени
   - Для каждой пары последовательных логинов:
     - Извлечь координаты (lat/lon) из обоих логинов
     - Рассчитать географическое расстояние между точками (geodesic distance)
     - Если расстояние < `MIN_DISTANCE_KM` — пропустить
     - Рассчитать разницу во времени между логинами
     - Рассчитать требуемую скорость: `расстояние / время`
     - Если требуемая скорость > `MAX_SPEED_KMH` — зафиксировать аномалию

4. **Формирование алерта:**
   - ID алерта: `ALERT-AUTH-TRAVEL`
   - Severity: `HIGH`
   - Включить данные:
     - User ID и Email пользователя
     - Точка "откуда": IP, страна, город, время
     - Точка "куда": IP, страна, город, время
     - Расстояние в км
     - Разница во времени в минутах
     - Вычисленная скорость в км/ч

5. **Отправка уведомления:**
   - Канал: Telegram (`TELEGRAM_SECURITY_MEDIUM`)
   - Формат: Markdown с эмодзи ⚠️
   - Включить рекомендацию: "Verify user identity - possible account compromise"

#### Выходные данные алерта

```
Поля алерта:
- alert_id: "ALERT-AUTH-TRAVEL"
- severity: "high"
- user_id: ID пользователя
- email: Email пользователя
- from_location: { ip, country, city, time }
- to_location: { ip, country, city, time }
- distance_km: расстояние в километрах
- time_diff_minutes: разница во времени в минутах
- required_speed_kmh: вычисленная скорость перемещения
```

### 5.2 Baseline Deviation Detector

**Назначение:** Детектор отклонений от baseline выявляет аномальную активность пользователей путём сравнения текущего поведения с историческим профилем. Использует простую статистику (среднее + стандартное отклонение) вместо ML.

**Периодичность запуска:** Каждые 15 минут через cron/CronJob.

**Расположение:** `/opt/security/detectors/baseline_deviation.py`

#### Конфигурационные параметры

| Параметр | Значение | Описание |
|----------|----------|----------|
| `BASELINE_DAYS` | 30 дней | Период для расчёта baseline (исключая текущий день) |
| `STD_THRESHOLD` | 3 | Порог Z-score для срабатывания (3 стандартных отклонения) |
| `MIN_DOWNLOADS` | 10 | Минимальное количество скачиваний для алерта |
| `MIN_LOGINS` | 5 | Минимальное количество логинов для алерта |

#### Отслеживаемые метрики

| Метрика | Тип события | Описание |
|---------|-------------|----------|
| **File Downloads** | `DATA_FILE_DOWNLOADED` | Количество скачанных файлов за день |
| **Logins** | `AUTH_LOGIN_SUCCESS` | Количество успешных входов за день |

#### Алгоритм работы

1. **Определение активных пользователей:**
   - Получить из Elasticsearch список уникальных `user_id` за последний час
   - Ограничение: до 1000 пользователей за один запуск

2. **Расчёт baseline для каждого пользователя:**
   - Период: последние `BASELINE_DAYS` дней, исключая сегодняшний день
   - Агрегировать данные по дням (date histogram)
   - Для каждой метрики подсчитать количество событий по дням
   - Рассчитать:
     - **mean** — среднее значение за период
     - **std** — стандартное отклонение

3. **Получение текущей активности:**
   - Подсчитать количество событий каждого типа за текущий день (`now/d`)

4. **Проверка отклонений:**
   - Для каждой метрики рассчитать Z-score:
     ```
     Z-score = (today_value - mean) / std
     ```
   - Особый случай: если `std = 0` (нет вариации в baseline):
     - Использовать простой порог: алерт если `today > mean * 5`
   - Срабатывание: `Z-score > STD_THRESHOLD`

5. **Условия генерации алерта:**
   - Z-score превышает порог **И**
   - Абсолютное значение превышает минимальный порог:
     - Для downloads: `today_downloads > 10`
     - Для logins: `today_logins > 5`

6. **Формирование алерта:**
   - ID алерта: `ALERT-BASELINE`
   - Severity: `MEDIUM`
   - Включить данные:
     - User ID
     - Название метрики (file downloads / logins)
     - Текущее значение
     - Baseline mean и std
     - Вычисленный Z-score

7. **Отправка уведомления:**
   - Канал: Telegram (`TELEGRAM_SECURITY_MEDIUM`)
   - Формат: Markdown с эмодзи 📊
   - Рекомендация: "Review user's recent activity for potential data exfiltration or account compromise"

#### Выходные данные алерта

```
Поля алерта:
- alert_id: "ALERT-BASELINE"
- severity: "medium"
- user_id: ID пользователя
- metric: название метрики ("file downloads" или "logins")
- today_value: текущее значение
- baseline_mean: среднее за период
- baseline_std: стандартное отклонение
- z_score: вычисленный Z-score
```

#### Пример сценария срабатывания

| Показатель | Значение |
|------------|----------|
| Пользователь | user_123 |
| Метрика | file downloads |
| Baseline mean | 5 файлов/день |
| Baseline std | 2 файла |
| Сегодня | 25 файлов |
| Z-score | (25-5)/2 = 10 |
| Результат | Алерт (Z-score 10 > порог 3, значение 25 > минимум 10) |

### 5.3 Cron Configuration

```bash
# /etc/cron.d/security-detectors

# Geo-velocity (impossible travel) - every 5 minutes
*/5 * * * * security /opt/security/detectors/geo_velocity.py >> /var/log/security/geo_velocity.log 2>&1

# Baseline deviation - every 15 minutes
*/15 * * * * security /opt/security/detectors/baseline_deviation.py >> /var/log/security/baseline.log 2>&1

# Daily statistics report - every day at 9:00
0 9 * * * security /opt/security/reports/daily_report.py >> /var/log/security/reports.log 2>&1
```

---

## 6. Auto-Response Service

### 6.1 Shell Script для ElastAlert Commands

**Назначение:** Shell-скрипт выполняет автоматические защитные действия, вызываемые из ElastAlert при срабатывании алертов. Обеспечивает оперативную реакцию на угрозы без участия оператора.

**Расположение:** `/opt/security/bin/auto_response.sh`

**Вызов:** `auto_response.sh <action> <target> <duration> <alert_id> [reason]`

#### Входные параметры

| Параметр | Позиция | Обязательный | Описание |
|----------|---------|--------------|----------|
| `action` | 1 | Да | Тип действия (см. таблицу действий) |
| `target` | 2 | Да | Цель действия (IP-адрес, user_id, телефон/email) |
| `duration` | 3 | Нет | Длительность в секундах (по умолчанию: 3600) |
| `alert_id` | 4 | Нет | ID алерта для аудита (по умолчанию: "unknown") |
| `reason` | 5 | Нет | Причина действия (по умолчанию: "auto_response") |

#### Конфигурация окружения

| Переменная | Значение по умолчанию | Описание |
|------------|----------------------|----------|
| `REDIS_HOST` | `redis.default.svc.cluster.local` | Хост Redis |
| `REDIS_PORT` | `6379` | Порт Redis |
| `API_BASE` | `http://authorization-service:8013` | URL authorization-service |
| `SYSTEM_TOKEN` | — | Системный токен для API-вызовов |
| `LOG_FILE` | `/var/log/security/auto_response.log` | Файл логов |

#### Каталог действий

| Action | Target | Описание | Redis Key | TTL |
|--------|--------|----------|-----------|-----|
| `block_ip` | IP-адрес | Блокировка IP | `blocked_ip:{ip}` | duration |
| `unblock_ip` | IP-адрес | Снятие блокировки IP | Удаление `blocked_ip:{ip}` | — |
| `suspend_user` | user_id | Приостановка аккаунта | `suspended_user:{user_id}` | duration (0 = permanent) |
| `invalidate_sessions` | user_id | Инвалидация сессий | — (API вызов) | — |
| `lock_2fa` | user_id | Блокировка 2FA | `2fa_locked:{user_id}` | duration |
| `reduce_rate_limit` | user_id | Снижение rate limit | `rate_limit_reduced:{user_id}` | duration |
| `block_notifications` | phone/email | Блокировка уведомлений | `notification_blocked:{target}` | duration |

#### Логика действий

**1. block_ip**
- Записать в Redis ключ `blocked_ip:{ip}` с TTL = duration
- Значение: JSON с полями `reason`, `alert_id`, `blocked_at`
- Отправить событие `SEC_IP_BLOCKED` в authorization-service API
- Записать в лог

**2. unblock_ip**
- Удалить ключ `blocked_ip:{ip}` из Redis
- Записать в лог

**3. suspend_user**
- Если duration > 0: записать `suspended_user:{user_id}` с TTL
- Если duration = 0: записать без TTL (перманентная блокировка, флаг `permanent: true`)
- Вызвать `invalidate_sessions` для этого пользователя
- Записать в лог

**4. invalidate_sessions**
- Отправить POST запрос на `{API_BASE}/api/auth/sessions/invalidate`
- Заголовки: `Content-Type: application/json`, `X-System-Token`
- Body: `{"user_id": "{user_id}"}`
- Записать в лог

**5. lock_2fa**
- Записать в Redis ключ `2fa_locked:{user_id}` с TTL = duration
- Значение: JSON с полем `alert_id`
- Записать в лог

**6. reduce_rate_limit**
- Записать в Redis ключ `rate_limit_reduced:{user_id}` с TTL = duration
- Значение: `10` (сниженный лимит запросов в минуту)
- Записать в лог

**7. block_notifications**
- Записать в Redis ключ `notification_blocked:{target}` с TTL = duration
- Значение: JSON с полем `alert_id`
- Записать в лог

#### Формат записи в Redis

```
Ключи блокировок:
- blocked_ip:{ip}           → {"reason": "...", "alert_id": "...", "blocked_at": "ISO8601"}
- suspended_user:{user_id}  → {"alert_id": "...", "suspended_at": "ISO8601", "permanent": bool}
- 2fa_locked:{user_id}      → {"alert_id": "..."}
- rate_limit_reduced:{user_id} → "10"
- notification_blocked:{target} → {"alert_id": "..."}
```

#### Формат лога

```
[ISO8601_TIMESTAMP] ACTION: {action} {params} ALERT={alert_id}
[ISO8601_TIMESTAMP] SUCCESS: {description}
[ISO8601_TIMESTAMP] ERROR: {error_message}
```

#### Обработка ошибок

- Неизвестный action → запись в лог `ERROR: Unknown action`, exit code 1
- Ошибки Redis/API → игнорируются (|| true), но логируются
- Скрипт использует `set -euo pipefail` для строгого режима

### 6.2 Middleware для проверки блокировок (Laravel)

**Назначение:** Laravel middleware перехватывает все входящие HTTP-запросы и проверяет, не заблокирован ли IP-адрес или пользователь системой автоматического реагирования. Обеспечивает enforcement блокировок, установленных через auto_response.sh.

**Расположение:** `app/Http/Middleware/SecurityBlocklistMiddleware.php`

**Класс:** `App\Http\Middleware\SecurityBlocklistMiddleware`

#### Зависимости

| Компонент | Назначение |
|-----------|------------|
| `Illuminate\Support\Facades\Redis` | Доступ к Redis для чтения ключей блокировок |
| `Illuminate\Support\Facades\Log` | Логирование попыток доступа заблокированных сущностей |
| `Illuminate\Http\Request` | Получение IP-адреса и данных пользователя |

#### Алгоритм работы

**1. Проверка блокировки IP-адреса**

- Получить IP-адрес из запроса: `$request->ip()`
- Проверить наличие ключа `blocked_ip:{ip}` в Redis
- Если ключ существует:
  - Распарсить JSON-значение
  - Записать warning в security лог с данными: `ip`, `reason`, `alert_id`
  - Вернуть HTTP 403 с JSON-ответом:
    ```json
    {
      "error": "access_denied",
      "message": "Your IP has been temporarily blocked due to suspicious activity.",
      "retry_after": <TTL ключа в секундах>
    }
    ```

**2. Проверка приостановки пользователя (для аутентифицированных запросов)**

- Получить текущего пользователя: `$request->user()`
- Если пользователь аутентифицирован:
  - Проверить наличие ключа `suspended_user:{user_id}` в Redis
  - Если ключ существует:
    - Распарсить JSON-значение
    - Записать warning в security лог с данными: `user_id`, `alert_id`
    - Вернуть HTTP 403 с JSON-ответом:
      ```json
      {
        "error": "account_suspended",
        "message": "Your account has been suspended. Please contact support."
      }
      ```

**3. Проверка сниженного rate limit**

- Если пользователь аутентифицирован:
  - Проверить наличие ключа `rate_limit_reduced:{user_id}` в Redis
  - Если ключ существует:
    - Установить атрибут запроса `rate_limit` со значением из Redis
    - Этот атрибут используется последующим rate limiting middleware

**4. Пропуск запроса**

- Если ни одна блокировка не сработала — передать запрос следующему middleware: `$next($request)`

#### Проверяемые Redis-ключи

| Ключ | Тип проверки | Результат при наличии |
|------|--------------|----------------------|
| `blocked_ip:{ip}` | Блокировка IP | HTTP 403 `access_denied` |
| `suspended_user:{user_id}` | Приостановка аккаунта | HTTP 403 `account_suspended` |
| `rate_limit_reduced:{user_id}` | Сниженный лимит | Установка атрибута `rate_limit` |

#### Формат ответов об ошибке

**Заблокированный IP:**
```
HTTP 403 Forbidden
Content-Type: application/json

{
  "error": "access_denied",
  "message": "Your IP has been temporarily blocked due to suspicious activity.",
  "retry_after": 3542
}
```

**Приостановленный аккаунт:**
```
HTTP 403 Forbidden
Content-Type: application/json

{
  "error": "account_suspended",
  "message": "Your account has been suspended. Please contact support."
}
```

#### Логирование

| Событие | Уровень | Канал | Поля |
|---------|---------|-------|------|
| Попытка доступа с заблокированного IP | WARNING | security | `ip`, `reason`, `alert_id` |
| Попытка доступа приостановленного пользователя | WARNING | security | `user_id`, `alert_id` |

#### Регистрация middleware

Middleware должен быть зарегистрирован в `app/Http/Kernel.php`:
- В группе `api` — для защиты всех API-эндпоинтов
- Порядок: после аутентификации, перед rate limiting

---

## 7. Kibana Dashboards

### 7.1 Security Overview Dashboard

**Назначение:** Главный дашборд безопасности для мониторинга угроз и инцидентов в реальном времени. Предоставляет SOC-команде единую точку обзора всех security-событий.

**Название:** `Security Overview (OSS)`

**Описание:** Security monitoring dashboard for Dogovor24

#### Настройки дашборда

| Параметр | Значение | Описание |
|----------|----------|----------|
| `timeRestore` | true | Сохранять выбранный временной диапазон |
| `timeFrom` | now-24h | Начало временного окна по умолчанию |
| `timeTo` | now | Конец временного окна |
| `refreshInterval` | 60000 ms (1 мин) | Интервал автообновления |

#### Панели дашборда

| # | Название панели | Тип визуализации | Позиция (x,y) | Размер (w×h) | Источник данных |
|---|-----------------|------------------|---------------|--------------|-----------------|
| 1 | Security Events (Last 24h) | metric | 0, 0 | 8×6 | `security-events-count` |
| 2 | Failed Logins (Last 24h) | metric | 8, 0 | 8×6 | `failed-logins-count` |
| 3 | Blocked IPs (Active) | metric | 16, 0 | 8×6 | `blocked-ips-count` |
| 4 | Events by Type | pie | 0, 6 | 12×10 | `events-by-type-pie` |
| 5 | Events Timeline | line | 12, 6 | 12×10 | `events-timeline` |
| 6 | Top Attacking IPs | data_table | 0, 16 | 12×10 | `top-attacking-ips` |
| 7 | Geographic Distribution | coordinate_map | 12, 16 | 12×10 | `geo-map` |
| 8 | Recent Security Alerts | search | 0, 26 | 24×12 | `recent-security-alerts` |

#### Описание панелей

**Ряд 1 — Ключевые метрики (KPI):**
- **Security Events** — общее количество security-событий за 24 часа
- **Failed Logins** — количество неудачных попыток входа
- **Blocked IPs** — количество активных блокировок IP

**Ряд 2 — Аналитика:**
- **Events by Type** — круговая диаграмма распределения событий по типам
- **Events Timeline** — временной график событий для выявления аномалий

**Ряд 3 — Детализация:**
- **Top Attacking IPs** — таблица IP-адресов с наибольшим количеством подозрительных действий
- **Geographic Distribution** — карта географического распределения источников событий

**Ряд 4 — Лента событий:**
- **Recent Security Alerts** — последние security-алерты с возможностью drill-down

### 7.2 Saved Searches

**Назначение:** Предопределённые поисковые запросы для быстрого анализа security-событий. Используются как источники данных для панелей дашборда и для ручного расследования инцидентов.

#### Каталог сохранённых поисков

| ID | Название | Назначение | Lucene Query |
|----|----------|------------|--------------|
| `failed-logins-by-ip` | Failed Logins by IP | Топ IP с неудачными попытками входа | `event_type:AUTH_LOGIN_FAILED` |
| `access-denied-events` | Access Denied Events | Отказы в авторизации (потенциальный IDOR) | `event_type:AUTHZ_ACCESS_DENIED` |
| `privilege-changes` | Privilege Changes | Изменения ролей и привилегий | `event_type:(AUTHZ_ROLE_ASSIGNED OR AUTHZ_PERMISSION_GRANTED)` |

#### Детальное описание поисков

**1. Failed Logins by IP**

| Параметр | Значение |
|----------|----------|
| ID | `failed-logins-by-ip` |
| Описание | Top IPs with failed login attempts |
| Query Language | Lucene |
| Query | `event_type:AUTH_LOGIN_FAILED` |
| Отображаемые колонки | `@timestamp`, `request.ip`, `context.login`, `request.user_agent` |
| Применение | Выявление brute-force атак, credential stuffing |

**2. Access Denied Events**

| Параметр | Значение |
|----------|----------|
| ID | `access-denied-events` |
| Описание | Authorization failures - potential IDOR |
| Query Language | Lucene |
| Query | `event_type:AUTHZ_ACCESS_DENIED` |
| Отображаемые колонки | `@timestamp`, `actor.user_id`, `target.resource_type`, `target.resource_id` |
| Применение | Выявление попыток IDOR, enumeration атак |

**3. Privilege Changes**

| Параметр | Значение |
|----------|----------|
| ID | `privilege-changes` |
| Описание | Role and permission changes |
| Query Language | Lucene |
| Query | `event_type:(AUTHZ_ROLE_ASSIGNED OR AUTHZ_PERMISSION_GRANTED)` |
| Отображаемые колонки | `@timestamp`, `actor.email`, `target.user_id`, `context.new_role` |
| Применение | Мониторинг изменений привилегий, выявление privilege escalation |

---

## 8. Deployment

### 8.1 ElastAlert 2 Kubernetes Deployment

**Назначение:** Развёртывание ElastAlert 2 в Kubernetes для непрерывного мониторинга security-событий и генерации алертов.

**Файл манифеста:** `elastalert2-deployment.yaml`

#### Deployment: elastalert2

| Параметр | Значение | Описание |
|----------|----------|----------|
| **name** | `elastalert2` | Имя деплоймента |
| **namespace** | `logging` | Namespace для security-компонентов |
| **replicas** | 1 | Количество реплик (singleton для избежания дублирования алертов) |
| **image** | `jertel/elastalert2:2.17.0` | Docker-образ ElastAlert 2 |

#### Ресурсы контейнера

| Тип | CPU | Memory |
|-----|-----|--------|
| requests | 100m | 256Mi |
| limits | 500m | 512Mi |

#### Volume Mounts

| Volume | Mount Path | Источник | Описание |
|--------|------------|----------|----------|
| `config` | `/opt/elastalert/config.yaml` | ConfigMap `elastalert2-config` | Основная конфигурация (subPath: config.yaml) |
| `rules` | `/opt/elastalert/rules` | ConfigMap `elastalert2-rules` | Директория с правилами алертов |
| `scripts` | `/opt/security/bin` | ConfigMap `security-scripts` | Скрипты auto-response (mode: 0755) |

#### Переменные окружения

| Переменная | Источник | Secret/ConfigMap | Key |
|------------|----------|------------------|-----|
| `ES_ELASTALERT_PASSWORD` | Secret | `elasticsearch-credentials` | `elastalert-password` |
| `TELEGRAM_BOT_TOKEN` | Secret | `security-alerts` | `telegram-bot-token` |
| `TELEGRAM_SECURITY_CRITICAL` | ConfigMap | `security-config` | `telegram-critical-channel` |
| `TELEGRAM_SECURITY_HIGH` | ConfigMap | `security-config` | `telegram-high-channel` |
| `TELEGRAM_SECURITY_MEDIUM` | ConfigMap | `security-config` | `telegram-medium-channel` |
| `DISCORD_SECURITY_WEBHOOK` | Secret | `security-alerts` | `discord-webhook-url` |

#### ConfigMap: security-config

| Key | Описание | Пример значения |
|-----|----------|-----------------|
| `telegram-critical-channel` | Chat ID для P0 алертов | `-1001234567890` |
| `telegram-high-channel` | Chat ID для P1 алертов | `-1001234567891` |
| `telegram-medium-channel` | Chat ID для P2 алертов | `-1001234567892` |

#### Требуемые Kubernetes ресурсы

| Ресурс | Название | Назначение |
|--------|----------|------------|
| Secret | `elasticsearch-credentials` | Пароль для подключения к ES |
| Secret | `security-alerts` | Токены Telegram/Discord |
| ConfigMap | `security-config` | Конфигурация каналов уведомлений |
| ConfigMap | `elastalert2-config` | Основной config.yaml |
| ConfigMap | `elastalert2-rules` | YAML-файлы правил алертов |
| ConfigMap | `security-scripts` | Shell-скрипты auto-response |

### 8.2 Python Detectors Deployment

**Назначение:** Развёртывание Python-детекторов аномалий как Kubernetes CronJob для периодического анализа данных.

**Файл манифеста:** `security-detectors-cronjob.yaml`

#### CronJob 1: geo-velocity-detector

| Параметр | Значение |
|----------|----------|
| **name** | `geo-velocity-detector` |
| **namespace** | `logging` |
| **schedule** | `*/5 * * * *` (каждые 5 минут) |
| **image** | `python:3.11-slim` |
| **command** | `python /opt/security/detectors/geo_velocity.py` |
| **restartPolicy** | `OnFailure` |

**Переменные окружения:**

| Переменная | Источник | Значение/Key |
|------------|----------|--------------|
| `ES_HOST` | Literal | `elasticsearch.logging.svc.cluster.local` |
| `TELEGRAM_BOT_TOKEN` | Secret `security-alerts` | `telegram-bot-token` |

**Volume Mounts:**

| Volume | Mount Path | Источник |
|--------|------------|----------|
| `detectors` | `/opt/security/detectors` | ConfigMap `security-detectors` |

#### CronJob 2: baseline-detector

| Параметр | Значение |
|----------|----------|
| **name** | `baseline-detector` |
| **namespace** | `logging` |
| **schedule** | `*/15 * * * *` (каждые 15 минут) |
| **image** | `python:3.11-slim` |
| **command** | `python /opt/security/detectors/baseline_deviation.py` |
| **restartPolicy** | `OnFailure` |

**Переменные окружения:**

| Переменная | Источник | Значение |
|------------|----------|----------|
| `ES_HOST` | Literal | `elasticsearch.logging.svc.cluster.local` |

**Volume Mounts:**

| Volume | Mount Path | Источник |
|--------|------------|----------|
| `detectors` | `/opt/security/detectors` | ConfigMap `security-detectors` |

#### Требуемые Kubernetes ресурсы

| Ресурс | Название | Содержимое |
|--------|----------|------------|
| ConfigMap | `security-detectors` | Python-скрипты: `geo_velocity.py`, `baseline_deviation.py` |
| Secret | `security-alerts` | Токен Telegram Bot |

#### Рекомендации по деплою

1. **Порядок создания ресурсов:**
   - Secrets (`elasticsearch-credentials`, `security-alerts`)
   - ConfigMaps (`security-config`, `elastalert2-config`, `elastalert2-rules`, `security-scripts`, `security-detectors`)
   - Deployment (`elastalert2`)
   - CronJobs (`geo-velocity-detector`, `baseline-detector`)

2. **Мониторинг CronJob:**
   - Проверять логи: `kubectl logs -n logging job/geo-velocity-detector-<id>`
   - Следить за `successfulJobsHistoryLimit` и `failedJobsHistoryLimit`

3. **Масштабирование:**
   - ElastAlert 2: только 1 реплика (избежание дублирования алертов)
   - CronJobs: concurrencyPolicy = Forbid (по умолчанию)

---

## 9. Rollout Plan

### 9.1 Фазы внедрения

│ Phase 1: Foundation (Week 1-2) │ Phase 2: Core Alerts (Week 3-4) │ Phase 3: Tuning (Week 5-6) │
| ------------------------------ | ------------------------------- | -------------------------- |
│ - ElastAlert 2 deploy          │ - AUTH-001..005                 │ - Threshold tuning         │
│ - Config & rules setup         │ - AUTHZ-001..003                │ - False positive fix       │
│ - Telegram integration         │ - DATA-001                      │ - Python detectors         │
│ - Auto-response scripts        │ - INT-002 (bombing)             │ - Baseline detector        │
│ - Basic dashboard              │ - SYS-001..002                  │ - Geo-velocity             │
│ - Testing framework            │ - Auto-response                 │ - Advanced dashboards      │

### 9.2 Ресурсы

| Role              | Allocation | Duration |
| ----------------- | ---------- | -------- |
| DevOps Engineer   | 0.5 FTE    | 6 weeks  |
| Backend Developer | 0.25 FTE   | 4 weeks  |
| QA Engineer       | 0.25 FTE   | 2 weeks  |

### 9.3 Зависимости

- ✅ Elasticsearch 7.x (уже есть)
- ✅ Redis (уже есть)
- ✅ Security logging (реализовано в PRD-Security-Logging)
- ⬜ Telegram Bot
- ⬜ Kibana dashboards

---

## 10. Appendix

### A. Notification Channels

**Telegram** (для P0 критических):

```txt
#security-alerts-critical  → P0 only, 24/7 notifications
```

**Discord** (для P1-P3):

```txt
#security-alerts-high      → P1 alerts
#security-alerts-medium    → P2 alerts
#security-alerts-info      → P3-P4 alerts
```

### B. Useful Kibana Queries

```txt
# Failed logins last hour
event_type:AUTH_LOGIN_FAILED AND @timestamp:[now-1h TO now]

# Blocked IPs
event_type:SEC_IP_BLOCKED AND @timestamp:[now-24h TO now]

# Privilege escalations
event_type:AUTHZ_ROLE_ASSIGNED AND context.new_role:(admin OR super-admin)

# Large file downloads
event_type:DATA_FILE_DOWNLOADED AND context.file_size:>10485760

# Cross-workspace access
event_type:AUTHZ_ACCESS_DENIED AND target.workspace_id:*
```

### C. Comparison: Watcher vs ElastAlert 2

| Feature               | Elasticsearch Watcher | ElastAlert 2         |
| --------------------- | --------------------- | -------------------- |
| License               | Paid (Gold+)          | Apache 2.0 (Free)    |
| Rule types            | Limited               | 10+ types            |
| Custom actions        | Webhook only          | Python extensible    |
| Telegram support      | Via webhook           | Native               |
| Discord support       | Via webhook           | Via webhook          |
| Aggregation           | Basic                 | Advanced             |
| Realert/dedup         | Basic                 | Advanced             |
| Community             | Elastic only          | Active OSS community |

### D. ElastAlert 2 Resources

- GitHub: https://github.com/jertel/elastalert2
- Documentation: https://elastalert2.readthedocs.io/
- Docker Image: jertel/elastalert2
