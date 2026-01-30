# Внедрение Security-логирования в Dogovor24

## 1. Executive Summary

### 1.1 Проблема

По результатам security-аудитов 6 ключевых сервисов Dogovor24 выявлены критические пробелы в логировании событий безопасности:

| Сервис                | Finding ID               | Severity | Проблема                                                  |
| --------------------- | ------------------------ | -------- | --------------------------------------------------------- |
| authorization-service | A09-W-001                | CRITICAL | Отсутствие логирования неудачных попыток аутентификации   |
| billing-service       | LM-MAJ-001               | MAJOR    | Отсутствие аудита критических бизнес-операций             |
| explorer-service      | A09-LOG-001              | CRITICAL | Не логируются отказы в авторизации                        |
| notification-service  | A09-LOG-MAJ-002/003      | MAJOR    | Логирование чувствительных данных, отсутствие контекста   |
| registry-service      | A04-W5, A09-LOG-002..006 | MAJOR    | Отсутствие аудита workflow, чувствительные данные в логах |
| workspace-service     | ID-A04-006               | MINOR    | Отсутствие логирования изменений прав и членства          |

### 1.2 Цель

Внедрить унифицированную систему security-логирования для:

- Обнаружения атак и подозрительной активности
- Расследования инцидентов безопасности
- Соответствия требованиям compliance (PCI DSS, SOC 2)
- Корреляции событий между микросервисами

### 1.3 Ключевые метрики успеха

| Метрика                    | Текущее | Целевое           |
| -------------------------- | ------- | ----------------- |
| Покрытие security-событий  | ~10%    | >95%              |
| Mean Time to Detect (MTTD) | N/A     | <15 мин           |
| Корреляция между сервисами | Нет     | 100% (request_id) |
| Retention period           | 7 дней  | 90+ дней          |

---

## 2. Scope и приоритеты

### 2.1 Фазы внедрения

```txt
┌─────────────────────────────────────────────────────────────────────────┐
│  Phase 1 (Critical)     │  Phase 2 (Major)      │  Phase 3 (Hardening)  │
│  ────────────────────   │  ──────────────────   │  ──────────────────── │
│  • Auth failures        │  • Business audit     │  • Anomaly detection  │
│  • Auth successes       │  • Data access logs   │  • Real-time alerts   │
│  • Authorization deny   │  • Admin actions      │  • Log integrity      │
│  • Request correlation  │  • Webhook events     │  • SIEM integration   │
│                         │  • Workflow changes   │  • Compliance reports │
│  Срок: 2-3 недели       │  Срок: 3-4 недели     │  Срок: 4-6 недель     │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Сервисы по приоритету

**P0 (Критический):**

- `authorization-service` — центр аутентификации
- `explorer-service` — доступ к файлам и ЭЦП

**P1 (Высокий):**

- `billing-service` — финансовые операции
- `registry-service` — ЕСЭДО workflow

**P2 (Средний):**

- `notification-service` — webhook и уведомления
- `workspace-service` — права и членство

---

## 3. Требования к событиям безопасности

### 3.1 Категории событий

#### 3.1.1 Authentication Events (AUTH)

| Event Type                      | Trigger                    | Severity | Сервис        |
| ------------------------------- | -------------------------- | -------- | ------------- |
| `AUTH_LOGIN_SUCCESS`            | Успешный вход              | INFO     | authorization |
| `AUTH_LOGIN_FAILED`             | Неудачная попытка входа    | WARNING  | authorization |
| `AUTH_LOGIN_BLOCKED`            | Блокировка после N попыток | WARNING  | authorization |
| `AUTH_LOGOUT`                   | Выход из системы           | INFO     | authorization |
| `AUTH_2FA_REQUESTED`            | Запрос 2FA кода            | INFO     | authorization |
| `AUTH_2FA_SUCCESS`              | Успешная верификация 2FA   | INFO     | authorization |
| `AUTH_2FA_FAILED`               | Неудачная верификация 2FA  | WARNING  | authorization |
| `AUTH_PASSWORD_RESET_REQUESTED` | Запрос сброса пароля       | INFO     | authorization |
| `AUTH_PASSWORD_CHANGED`         | Смена пароля               | INFO     | authorization |
| `AUTH_TOKEN_ISSUED`             | Выдача JWT токена          | INFO     | authorization |
| `AUTH_TOKEN_REVOKED`            | Отзыв токена               | INFO     | authorization |
| `AUTH_SESSION_EXPIRED`          | Истечение сессии           | INFO     | authorization |

**Источник требования:** `authorization-service-audit.md`, Finding A09-W-001

#### 3.1.2 Authorization Events (AUTHZ)

| Event Type                 | Trigger                | Severity | Сервис        |
| -------------------------- | ---------------------- | -------- | ------------- |
| `AUTHZ_ACCESS_DENIED`      | Отказ в доступе (403)  | WARNING  | все           |
| `AUTHZ_RESOURCE_NOT_FOUND` | Ресурс не найден (404) | INFO     | все           |
| `AUTHZ_PERMISSION_GRANTED` | Выдача прав            | INFO     | workspace     |
| `AUTHZ_PERMISSION_REVOKED` | Отзыв прав             | INFO     | workspace     |
| `AUTHZ_ROLE_ASSIGNED`      | Назначение роли        | INFO     | authorization |
| `AUTHZ_ROLE_REMOVED`       | Удаление роли          | INFO     | authorization |

**Источник требования:** `explorer-service-audit.md`, Finding A09-LOG-001

#### 3.1.3 Data Access Events (DATA)

| Event Type               | Trigger              | Severity | Сервис   |
| ------------------------ | -------------------- | -------- | -------- |
| `DATA_FILE_DOWNLOADED`   | Скачивание файла     | INFO     | explorer |
| `DATA_FILE_UPLOADED`     | Загрузка файла       | INFO     | explorer |
| `DATA_FILE_DELETED`      | Удаление файла       | INFO     | explorer |
| `DATA_FILE_SIGNED`       | Подписание файла ЭЦП | INFO     | explorer |
| `DATA_DOCUMENT_VIEWED`   | Просмотр документа   | INFO     | document |
| `DATA_DOCUMENT_EXPORTED` | Экспорт документа    | INFO     | document |
| `DATA_BULK_DOWNLOAD`     | Массовое скачивание  | WARNING  | explorer |

**Источник требования:** `explorer-service-audit.md`, IDOR findings

#### 3.1.4 Business Operation Events (BIZ)

| Event Type                  | Trigger                 | Severity | Сервис       |
| --------------------------- | ----------------------- | -------- | ------------ |
| `BIZ_PAYMENT_INITIATED`     | Инициация платежа       | INFO     | billing      |
| `BIZ_PAYMENT_COMPLETED`     | Успешный платеж         | INFO     | billing      |
| `BIZ_PAYMENT_FAILED`        | Неудачный платеж        | WARNING  | billing      |
| `BIZ_REFUND_REQUESTED`      | Запрос возврата         | INFO     | billing      |
| `BIZ_REFUND_PROCESSED`      | Обработка возврата      | INFO     | billing      |
| `BIZ_INVOICE_CREATED`       | Создание счёта          | INFO     | billing      |
| `BIZ_INVOICE_STATE_CHANGED` | Изменение статуса счёта | INFO     | billing      |
| `BIZ_ORDER_CREATED`         | Создание заказа         | INFO     | billing      |
| `BIZ_SUBSCRIPTION_CHANGED`  | Изменение подписки      | INFO     | subscription |

**Источник требования:** `billing-service-audit.md`, Finding LM-MAJ-001

#### 3.1.5 Workflow Events (WF)

| Event Type                   | Trigger                      | Severity | Сервис   |
| ---------------------------- | ---------------------------- | -------- | -------- |
| `WF_ESEDO_DOCUMENT_SENT`     | Отправка документа в ЕСЭДО   | INFO     | registry |
| `WF_ESEDO_DOCUMENT_RECEIVED` | Получение документа из ЕСЭДО | INFO     | registry |
| `WF_ESEDO_STATUS_CHANGED`    | Изменение статуса в ЕСЭДО    | INFO     | registry |
| `WF_CARD_APPROVED`           | Утверждение карточки         | INFO     | registry |
| `WF_CARD_REJECTED`           | Отклонение карточки          | INFO     | registry |
| `WF_CARD_REGISTERED`         | Регистрация карточки         | INFO     | registry |

**Источник требования:** `registry-service-audit.md`, Finding A04-W5

#### 3.1.6 Administrative Events (ADMIN)

| Event Type                | Trigger                 | Severity | Сервис        |
| ------------------------- | ----------------------- | -------- | ------------- |
| `ADMIN_USER_CREATED`      | Создание пользователя   | INFO     | authorization |
| `ADMIN_USER_DELETED`      | Удаление пользователя   | WARNING  | authorization |
| `ADMIN_USER_SUSPENDED`    | Блокировка пользователя | WARNING  | authorization |
| `ADMIN_WORKSPACE_CREATED` | Создание workspace      | INFO     | workspace     |
| `ADMIN_WORKSPACE_DELETED` | Удаление workspace      | WARNING  | workspace     |
| `ADMIN_CONFIG_CHANGED`    | Изменение конфигурации  | WARNING  | все           |
| `ADMIN_MODULE_ENABLED`    | Включение модуля        | INFO     | workspace     |
| `ADMIN_MODULE_DISABLED`   | Выключение модуля       | INFO     | workspace     |

**Источник требования:** `workspace-service-audit.md`, Finding ID-A04-006

#### 3.1.7 Integration Events (INT)

| Event Type              | Trigger             | Severity | Сервис       |
| ----------------------- | ------------------- | -------- | ------------ |
| `INT_WEBHOOK_RECEIVED`  | Входящий webhook    | INFO     | notification |
| `INT_WEBHOOK_SENT`      | Исходящий webhook   | INFO     | notification |
| `INT_WEBHOOK_FAILED`    | Ошибка webhook      | WARNING  | notification |
| `INT_API_CALL_EXTERNAL` | Внешний API вызов   | INFO     | все          |
| `INT_API_CALL_FAILED`   | Ошибка внешнего API | WARNING  | все          |

**Источник требования:** `notification-service-audit.md`, Findings A09-LOG-MAJ-002/003

#### 3.1.8 Security Events (SEC)

| Event Type                   | Trigger                   | Severity | Сервис   |
| ---------------------------- | ------------------------- | -------- | -------- |
| `SEC_RATE_LIMIT_EXCEEDED`    | Превышение rate limit     | WARNING  | все      |
| `SEC_CSRF_VALIDATION_FAILED` | Ошибка CSRF               | WARNING  | все      |
| `SEC_SIGNATURE_INVALID`      | Неверная ЭЦП              | WARNING  | explorer |
| `SEC_IP_BLOCKED`             | Блокировка IP             | WARNING  | все      |
| `SEC_SUSPICIOUS_ACTIVITY`    | Подозрительная активность | WARNING  | все      |

### 3.2 Обязательные поля событий

```json
{
  "timestamp": "2026-01-27T10:30:00.123Z",
  "level": "INFO|WARNING|ERROR",
  "event_type": "AUTH_LOGIN_FAILED",
  "service": "authorization-service",
  "version": "1.0",

  "request": {
    "request_id": "uuid-v4",
    "correlation_id": "uuid-v4",
    "method": "POST",
    "path": "/api/auth/login",
    "ip": "192.168.1.100",
    "user_agent": "Mozilla/5.0...",
    "referer": "https://dogovor24.kz/login"
  },

  "actor": {
    "user_id": 12345,
    "user_id_hash": "sha256:abc...",
    "workspace_id": 67890,
    "session_id": "sess_abc123",
    "is_system": false
  },

  "target": {
    "resource_type": "user",
    "resource_id": "12345",
    "resource_uuid": "uuid-v4"
  },

  "result": {
    "status": "success|failure|blocked",
    "reason": "invalid_credentials",
    "error_code": "AUTH001"
  },

  "context": {
    "attempt_count": 3,
    "custom_field": "value"
  },

  "metadata": {
    "region": "kz",
    "environment": "production",
    "hostname": "auth-service-pod-xyz"
  }
}
```

### 3.3 Правила редактирования чувствительных данных

**ОБЯЗАТЕЛЬНО редактировать:**

| Поле          | Метод                | Пример                           |
| ------------- | -------------------- | -------------------------------- |
| `email`       | Частичная маскировка | `s***@example.com`               |
| `phone`       | Частичная маскировка | `+7***1234`                      |
| `iin`         | Частичная маскировка | `****5678**`                     |
| `password`    | Полное удаление      | `[REDACTED]`                     |
| `token`       | Частичная маскировка | `eyJ...***` (первые 10 символов) |
| `credit_card` | Полное удаление      | `[REDACTED]`                     |
| `api_key`     | Частичная маскировка | `sk_***xyz`                      |

**Источник требования:** `notification-service-audit.md`, Finding A09-LOG-MAJ-002

---

## 4. Техническая архитектура

### 4.1 Общая схема

```txt
┌────────────────────────────────────────────────────────────────────────────┐
│                              Microservices                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ authorization│  │   billing    │  │   explorer   │  │   registry   │    │
│  │   service    │  │   service    │  │   service    │  │   service    │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                 │                 │                 │            │
│         ▼                 ▼                 ▼                 ▼            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    SecurityLoggerService (Shared Package)           │   │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐            │   │
│  │  │ EventBuilder  │  │  Redactor     │  │  Formatter    │            │   │
│  │  └───────────────┘  └───────────────┘  └───────────────┘            │   │
│  └─────────────────────────────────────────┬───────────────────────────┘   │
│                                            │                               │
└────────────────────────────────────────────┼───────────────────────────────┘
                                             │
                                             ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                           Log Transport Layer                              │
│  ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐       │
│  │    stdout/stderr  │  │                   │  │                   │       │
│  │    (JSON format)  │→→│   Logstash        │→→│   Elasticsearch   │       │
│  └───────────────────┘  └───────────────────┘  └───────────────────┘       │
│                                                         │                  │
│                                                         ▼                  │
│                                              ┌───────────────────┐         │
│                                              │       Kibana      │         │
│                                              │   (Dashboards &   │         │
│                                              │       Alerts)     │         │
│                                              └───────────────────┘         │
└────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Shared Package: `dogovor24/security-logging-package`

```txt
vendor/dogovor24/security-logging-package/
├── src/
│   ├── SecurityLoggerService.php      # Основной сервис
│   ├── Events/
│   │   ├── SecurityEvent.php          # Base event class
│   │   ├── AuthEvent.php              # AUTH_* events
│   │   ├── AuthzEvent.php             # AUTHZ_* events
│   │   ├── DataAccessEvent.php        # DATA_* events
│   │   ├── BusinessEvent.php          # BIZ_* events
│   │   ├── WorkflowEvent.php          # WF_* events
│   │   ├── AdminEvent.php             # ADMIN_* events
│   │   ├── IntegrationEvent.php       # INT_* events
│   │   └── SecurityIncidentEvent.php  # SEC_* events
│   ├── Middleware/
│   │   ├── RequestIdMiddleware.php    # Генерация request_id
│   │   └── SecurityLoggingMiddleware.php
│   ├── Formatters/
│   │   ├── JsonSecurityFormatter.php  # JSON формат для SIEM
│   │   └── TextSecurityFormatter.php  # Human-readable для dev
│   ├── Redactors/
│   │   ├── RedactorInterface.php
│   │   ├── EmailRedactor.php
│   │   ├── PhoneRedactor.php
│   │   ├── IinRedactor.php
│   │   └── TokenRedactor.php
│   ├── Handlers/
│   │   └── SecurityLogHandler.php     # Monolog handler
│   ├── Traits/
│   │   └── LogsSecurityEvents.php     # Trait для контроллеров
│   └── Providers/
│       └── SecurityLoggingServiceProvider.php
├── config/
│   └── security-logging.php           # Конфигурация
└── tests/
    └── ...
```

### 4.3 Ключевые классы

#### SecurityLoggerService.php

```php
<?php

namespace Dogovor24\SecurityLogging;

use Dogovor24\SecurityLogging\Events\SecurityEvent;
use Illuminate\Support\Facades\Log;
use Monolog\Logger;

class SecurityLoggerService
{
    private Logger $logger;
    private array $redactors;
    private array $config;

    public function __construct(array $config = [])
    {
        $this->config = $config;
        $this->initializeLogger();
        $this->initializeRedactors();
    }

    /**
     * Log a security event
     */
    public function log(SecurityEvent $event): void
    {
        $payload = $event->toArray();
        $payload = $this->redact($payload);

        $level = $this->mapSeverityToLevel($event->getSeverity());

        $this->logger->log($level, $event->getEventType(), $payload);
    }

    /**
     * Log authentication success
     */
    public function authSuccess(
        int $userId,
        string $method = 'password',
        array $context = []
    ): void {
        $event = new AuthEvent(
            'AUTH_LOGIN_SUCCESS',
            SecurityEvent::SEVERITY_INFO,
            [
                'user_id' => $userId,
                'auth_method' => $method,
                ...$context
            ]
        );
        $this->log($event);
    }

    /**
     * Log authentication failure
     */
    public function authFailure(
        ?string $login,
        string $reason,
        array $context = []
    ): void {
        $event = new AuthEvent(
            'AUTH_LOGIN_FAILED',
            SecurityEvent::SEVERITY_WARNING,
            [
                'login' => $login,
                'failure_reason' => $reason,
                ...$context
            ]
        );
        $this->log($event);
    }

    /**
     * Log authorization denial
     */
    public function accessDenied(
        ?int $userId,
        string $resource,
        string $action,
        array $context = []
    ): void {
        $event = new AuthzEvent(
            'AUTHZ_ACCESS_DENIED',
            SecurityEvent::SEVERITY_WARNING,
            [
                'user_id' => $userId,
                'resource' => $resource,
                'action' => $action,
                ...$context
            ]
        );
        $this->log($event);
    }

    /**
     * Log business operation
     */
    public function businessOperation(
        string $operation,
        int $userId,
        array $target,
        string $result,
        array $context = []
    ): void {
        $event = new BusinessEvent(
            $operation,
            $result === 'success'
                ? SecurityEvent::SEVERITY_INFO
                : SecurityEvent::SEVERITY_WARNING,
            [
                'user_id' => $userId,
                'target' => $target,
                'result' => $result,
                ...$context
            ]
        );
        $this->log($event);
    }

    // ... дополнительные методы

    private function redact(array $payload): array
    {
        foreach ($this->redactors as $redactor) {
            $payload = $redactor->redact($payload);
        }
        return $payload;
    }

    private function mapSeverityToLevel(string $severity): int
    {
        return match ($severity) {
            SecurityEvent::SEVERITY_INFO => Logger::INFO,
            SecurityEvent::SEVERITY_WARNING => Logger::WARNING,
            SecurityEvent::SEVERITY_ERROR => Logger::ERROR,
            SecurityEvent::SEVERITY_CRITICAL => Logger::CRITICAL,
            default => Logger::INFO,
        };
    }
}
```

#### RequestIdMiddleware.php

```php
<?php

namespace Dogovor24\SecurityLogging\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;

class RequestIdMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        // Получаем или генерируем request_id
        $requestId = $request->header('X-Request-ID') ?? Str::uuid()->toString();

        // Получаем или наследуем correlation_id (для трассировки между сервисами)
        $correlationId = $request->header('X-Correlation-ID') ?? $requestId;

        // Добавляем в request для использования в коде
        $request->attributes->set('request_id', $requestId);
        $request->attributes->set('correlation_id', $correlationId);

        // Добавляем в контекст всех логов этого request
        Log::withContext([
            'request_id' => $requestId,
            'correlation_id' => $correlationId,
            'ip' => $request->ip(),
            'user_agent' => $request->userAgent(),
            'method' => $request->method(),
            'path' => $request->path(),
        ]);

        $response = $next($request);

        // Добавляем request_id в response headers для отладки
        $response->headers->set('X-Request-ID', $requestId);

        return $response;
    }
}
```

### 4.4 Конфигурация

```php
<?php
// config/security-logging.php

return [
    /*
    |--------------------------------------------------------------------------
    | Security Logging Enabled
    |--------------------------------------------------------------------------
    */
    'enabled' => env('SECURITY_LOGGING_ENABLED', true),

    /*
    |--------------------------------------------------------------------------
    | Log Channel
    |--------------------------------------------------------------------------
    */
    'channel' => env('SECURITY_LOG_CHANNEL', 'security'),

    /*
    |--------------------------------------------------------------------------
    | Minimum Log Level
    |--------------------------------------------------------------------------
    */
    'level' => env('SECURITY_LOG_LEVEL', 'info'),

    /*
    |--------------------------------------------------------------------------
    | Service Identification
    |--------------------------------------------------------------------------
    */
    'service' => [
        'name' => env('SERVICE_NAME', 'unknown-service'),
        'version' => env('SERVICE_VERSION', '1.0.0'),
        'environment' => env('APP_ENV', 'production'),
        'region' => env('REGION', 'kz'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Redaction Settings
    |--------------------------------------------------------------------------
    */
    'redaction' => [
        'enabled' => true,
        'fields' => [
            'password' => 'full',        // Полное удаление
            'token' => 'partial:10',     // Показывать первые 10 символов
            'email' => 'email',          // Специальный формат для email
            'phone' => 'phone',          // Специальный формат для телефона
            'iin' => 'iin',              // Специальный формат для ИИН
            'credit_card' => 'full',
            'api_key' => 'partial:6',
            'secret' => 'full',
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Events Configuration
    |--------------------------------------------------------------------------
    */
    'events' => [
        'auth' => [
            'log_success' => true,
            'log_failure' => true,
            'include_user_agent' => true,
            'include_ip' => true,
        ],
        'authz' => [
            'log_denied' => true,
            'log_not_found' => false,  // INFO level, может быть шумным
        ],
        'data_access' => [
            'log_downloads' => true,
            'log_uploads' => true,
            'log_deletes' => true,
            'bulk_threshold' => 10,  // Логировать как WARNING если > N файлов
        ],
        'business' => [
            'log_payments' => true,
            'log_invoices' => true,
            'log_state_changes' => true,
        ],
        'webhook' => [
            'log_incoming' => true,
            'log_outgoing' => true,
            'log_failures' => true,
            'redact_payload' => true,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Rate Limiting for Logging
    |--------------------------------------------------------------------------
    | Prevent log flooding for repeated events
    */
    'rate_limiting' => [
        'enabled' => true,
        'per_minute' => [
            'AUTH_LOGIN_FAILED' => 100,    // Max 100 failed logins per minute per IP
            'AUTHZ_ACCESS_DENIED' => 50,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Output Format
    |--------------------------------------------------------------------------
    */
    'format' => [
        'type' => 'json',  // json, text
        'include_stack_trace' => env('APP_DEBUG', false),
        'timestamp_format' => 'c',  // ISO 8601
    ],
];
```

### 4.5 Интеграция в config/logging.php

```php
<?php
// Добавить в config/logging.php

'channels' => [
    // ... существующие каналы

    'security' => [
        'driver' => 'custom',
        'via' => \Dogovor24\SecurityLogging\Handlers\SecurityLogHandler::class,
        'level' => env('SECURITY_LOG_LEVEL', 'info'),
        'formatter' => \Dogovor24\SecurityLogging\Formatters\JsonSecurityFormatter::class,
    ],

    // Альтернатива: отдельный файл для security логов
    'security_file' => [
        'driver' => 'daily',
        'path' => storage_path('logs/security.log'),
        'level' => 'info',
        'days' => 90,  // Увеличенный retention
        'formatter' => \Monolog\Formatter\JsonFormatter::class,
    ],
],
```

---

## 5. Рекомендации по внедрению

### 5.1 Phase 1: Базовое логирование (2-3 недели)

#### 5.1.1 authorization-service

**Файлы для модификации:**

```txt
app/Http/Controllers/AuthController.php
app/Http/Controllers/TwoFAController.php
app/Http/Controllers/PasswordResetEmailController.php
app/Http/Controllers/PasswordResetMobileController.php
app/Http/Requests/StoreLoginRequest.php
app/Exceptions/Handler.php
```

**Изменения в AuthController.php:**

```php
<?php

namespace App\Http\Controllers;

use Dogovor24\SecurityLogging\SecurityLoggerService;
use Dogovor24\SecurityLogging\Traits\LogsSecurityEvents;

class AuthController extends Controller
{
    use LogsSecurityEvents;

    private SecurityLoggerService $securityLogger;

    public function __construct(SecurityLoggerService $securityLogger)
    {
        $this->securityLogger = $securityLogger;
    }

    public function login(StoreLoginRequest $request)
    {
        $credentials = $request->validated();

        try {
            // ... существующая логика аутентификации

            if ($authFailed) {
                // НОВОЕ: Логирование неудачной попытки
                $this->securityLogger->authFailure(
                    login: $credentials['email'] ?? $credentials['phone'] ?? null,
                    reason: 'invalid_credentials',
                    context: [
                        'attempt_count' => $this->getAttemptCount($credentials),
                    ]
                );

                return response()->json(['error' => 'Invalid credentials'], 422);
            }

            // НОВОЕ: Логирование успешного входа
            $this->securityLogger->authSuccess(
                userId: $user->id,
                method: 'password',
                context: [
                    'workspace_id' => $user->default_workspace_id,
                ]
            );

            return $this->issueToken($user);

        } catch (\Exception $e) {
            // НОВОЕ: Логирование ошибки аутентификации
            $this->securityLogger->log(new AuthEvent(
                'AUTH_ERROR',
                SecurityEvent::SEVERITY_ERROR,
                [
                    'login' => $credentials['email'] ?? null,
                    'error' => $e->getMessage(),
                ]
            ));
            throw $e;
        }
    }
}
```

**Изменения в Handler.php для логирования 403/401:**

```php
<?php

namespace App\Exceptions;

use Dogovor24\SecurityLogging\SecurityLoggerService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;

class Handler extends ExceptionHandler
{
    public function report(\Throwable $e)
    {
        // НОВОЕ: Логирование отказов в авторизации
        if ($e instanceof AuthorizationException) {
            app(SecurityLoggerService::class)->accessDenied(
                userId: auth()->id(),
                resource: request()->path(),
                action: request()->method(),
                context: [
                    'exception' => get_class($e),
                    'message' => $e->getMessage(),
                ]
            );
        }

        // НОВОЕ: Логирование ошибок аутентификации
        if ($e instanceof AuthenticationException) {
            app(SecurityLoggerService::class)->log(new AuthEvent(
                'AUTH_UNAUTHENTICATED',
                SecurityEvent::SEVERITY_WARNING,
                [
                    'path' => request()->path(),
                    'method' => request()->method(),
                ]
            ));
        }

        parent::report($e);
    }
}
```

#### 5.1.2 explorer-service

**Файлы для модификации:**

```txt
app/Http/Controllers/UUIDFileController.php
app/Http/Controllers/FileSignatureController.php
app/Services/UUIDFileService.php
app/Exceptions/Handler.php
```

**Пример для UUIDFileController.php:**

```php
<?php

namespace App\Http\Controllers;

use Dogovor24\SecurityLogging\SecurityLoggerService;

class UUIDFileController extends Controller
{
    private SecurityLoggerService $securityLogger;

    public function download(File $file)
    {
        // ... существующая логика

        // НОВОЕ: Логирование скачивания файла
        $this->securityLogger->log(new DataAccessEvent(
            'DATA_FILE_DOWNLOADED',
            SecurityEvent::SEVERITY_INFO,
            [
                'file_id' => $file->id,
                'file_uuid' => $file->uuid,
                'file_name' => $file->name,
                'file_size' => $file->size,
                'workspace_id' => $file->workspace_id,
            ]
        ));

        return $response;
    }

    public function show(File $file)
    {
        // ... существующая логика

        // НОВОЕ: Логирование просмотра метаданных файла
        $this->securityLogger->log(new DataAccessEvent(
            'DATA_FILE_METADATA_VIEWED',
            SecurityEvent::SEVERITY_INFO,
            [
                'file_id' => $file->id,
                'file_uuid' => $file->uuid,
            ]
        ));

        return new FileResource($file);
    }
}
```

#### 5.1.3 Middleware для всех сервисов

**Добавить в Kernel.php каждого сервиса:**

```php
protected $middleware = [
    // ... существующие middleware
    \Dogovor24\SecurityLogging\Middleware\RequestIdMiddleware::class,
];
```

### 5.2 Phase 2: Бизнес-аудит (3-4 недели)

#### 5.2.1 billing-service

**Критические точки логирования:**

| Контроллер/Сервис                    | Событие                        | Приоритет |
| ------------------------------------ | ------------------------------ | --------- |
| `PaymentController::store`           | `BIZ_PAYMENT_INITIATED`        | P0        |
| `PaymentProcessController::process`  | `BIZ_PAYMENT_COMPLETED/FAILED` | P0        |
| `InvoiceController::store`           | `BIZ_INVOICE_CREATED`          | P1        |
| `StagingInvoiceController::setState` | `BIZ_INVOICE_STATE_CHANGED`    | P0        |
| `OrderController`                    | `BIZ_ORDER_*`                  | P1        |

#### 5.2.2 registry-service

**Критические точки логирования:**

| Контроллер/Сервис           | Событие                      | Приоритет |
| --------------------------- | ---------------------------- | --------- |
| `EsedoController::approve`  | `WF_CARD_APPROVED`           | P0        |
| `EsedoController::reject`   | `WF_CARD_REJECTED`           | P0        |
| `EsedoController::register` | `WF_CARD_REGISTERED`         | P0        |
| `EsedoController::send`     | `WF_ESEDO_DOCUMENT_SENT`     | P0        |
| `SoapServer::SendMessage`   | `WF_ESEDO_DOCUMENT_RECEIVED` | P0        |

#### 5.2.3 workspace-service

**Критические точки логирования:**

| Контроллер/Сервис                                         | Событие                      | Приоритет |
| --------------------------------------------------------- | ---------------------------- | --------- |
| `WorkspaceGroupWorkspaceUserController::store`            | `ADMIN_USER_INVITED`         | P1        |
| `WorkspaceConfirmController::index`                       | `ADMIN_INVITATION_CONFIRMED` | P1        |
| `WorkspaceGroupWorkspaceUserChangeGroupController::store` | `ADMIN_GROUP_CHANGED`        | P1        |
| `WorkspaceModulesController::store/destroy`               | `ADMIN_MODULE_*`             | P1        |

### 5.3 Phase 3: Hardening (4-6 недель)

#### 5.3.1 Настройка SIEM интеграции

**Fluentd конфигурация:**

```yaml
# fluent.conf
<source>
@type tail
path /var/log/containers/*security*.log
pos_file /var/log/fluentd-security.pos
tag security.*
<parse>
@type json
time_key timestamp
time_format %Y-%m-%dT%H:%M:%S.%L%z
</parse>
</source>

<filter security.**>
@type record_transformer
<record>
cluster "#{ENV['CLUSTER_NAME']}"
namespace "#{ENV['NAMESPACE']}"
</record>
</filter>

<match security.**>
@type elasticsearch
host elasticsearch.logging.svc.cluster.local
port 9200
index_name security-logs
type_name _doc
logstash_format true
logstash_prefix security
<buffer>
@type file
path /var/log/fluentd-buffers/security
flush_mode interval
flush_interval 5s
retry_type exponential_backoff
</buffer>
</match>
```

#### 5.3.2 Alerting Rules

**Elasticsearch Watcher / Alert Rules:**

```json
{
  "trigger": {
    "schedule": { "interval": "1m" }
  },
  "input": {
    "search": {
      "request": {
        "indices": ["security-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                { "term": { "event_type": "AUTH_LOGIN_FAILED" } },
                { "range": { "@timestamp": { "gte": "now-5m" } } }
              ]
            }
          },
          "aggs": {
            "by_ip": {
              "terms": { "field": "request.ip", "min_doc_count": 10 }
            }
          }
        }
      }
    }
  },
  "condition": {
    "compare": {
      "ctx.payload.aggregations.by_ip.buckets.0.doc_count": { "gte": 10 }
    }
  },
  "actions": {
    "notify_security": {
      "webhook": {
        "method": "POST",
        "url": "https://alerts.dogovor24.kz/webhook/brute-force",
        "body": "{{#toJson}}ctx.payload{{/toJson}}"
      }
    }
  }
}
```

**Рекомендуемые alert rules:**

| Rule                      | Condition                                                      | Severity |
| ------------------------- | -------------------------------------------------------------- | -------- |
| Brute Force Detection     | >10 AUTH_LOGIN_FAILED с одного IP за 5 мин                     | CRITICAL |
| Credential Stuffing       | >50 AUTH_LOGIN_FAILED на разные accounts с одного IP за 10 мин | CRITICAL |
| Privilege Escalation      | AUTHZ_ROLE_ASSIGNED для admin/operator ролей                   | HIGH     |
| Bulk Download             | DATA_BULK_DOWNLOAD >50 файлов                                  | MEDIUM   |
| After-hours Access        | AUTH_LOGIN_SUCCESS вне рабочих часов для non-admin             | LOW      |
| Multiple Workspace Access | >5 разных workspace_id от одного user за 1 час                 | MEDIUM   |

#### 5.3.3 Log Integrity

**Рекомендации:**

1. **Immutable Storage**: Использовать Write-Once storage (S3 Object Lock, Azure Immutable Blob)
2. **Log Signing**: Добавить HMAC подпись для каждой записи
3. **Chain Verification**: Включить hash предыдущей записи в каждую новую

---

## 6. Тестирование

### 6.1 Unit Tests

```php
<?php

namespace Tests\Unit\SecurityLogging;

use Dogovor24\SecurityLogging\SecurityLoggerService;
use Dogovor24\SecurityLogging\Events\AuthEvent;
use Tests\TestCase;

class SecurityLoggerServiceTest extends TestCase
{
    /** @test */
    public function it_logs_auth_success_with_required_fields()
    {
        $logger = $this->mock(SecurityLoggerService::class);

        $logger->shouldReceive('authSuccess')
            ->once()
            ->with(
                \Mockery::on(fn($userId) => is_int($userId)),
                \Mockery::type('string'),
                \Mockery::type('array')
            );

        $logger->authSuccess(123, 'password', ['workspace_id' => 456]);
    }

    /** @test */
    public function it_redacts_sensitive_data()
    {
        $logger = new SecurityLoggerService([
            'redaction' => ['enabled' => true, 'fields' => ['email' => 'email']]
        ]);

        $event = new AuthEvent('AUTH_LOGIN_FAILED', 'warning', [
            'email' => 'user@example.com'
        ]);

        $payload = $logger->redact($event->toArray());

        $this->assertEquals('u***@example.com', $payload['context']['email']);
    }

    /** @test */
    public function it_includes_request_id_in_all_events()
    {
        // ... test implementation
    }
}
```

### 6.2 Integration Tests

```php
<?php

namespace Tests\Feature\SecurityLogging;

use Tests\TestCase;

class AuthSecurityLoggingTest extends TestCase
{
    /** @test */
    public function failed_login_is_logged()
    {
        $this->postJson('/api/auth/login', [
            'email' => 'test@example.com',
            'password' => 'wrong_password'
        ]);

        $this->assertSecurityLogContains([
            'event_type' => 'AUTH_LOGIN_FAILED',
            'context.login' => 't***@example.com',
            'result.reason' => 'invalid_credentials'
        ]);
    }

    /** @test */
    public function successful_login_is_logged()
    {
        $user = factory(User::class)->create();

        $this->postJson('/api/auth/login', [
            'email' => $user->email,
            'password' => 'password'
        ]);

        $this->assertSecurityLogContains([
            'event_type' => 'AUTH_LOGIN_SUCCESS',
            'actor.user_id' => $user->id
        ]);
    }

    /** @test */
    public function access_denied_is_logged()
    {
        $user = factory(User::class)->create();

        $this->actingAs($user)
            ->getJson('/api/admin/users')
            ->assertStatus(403);

        $this->assertSecurityLogContains([
            'event_type' => 'AUTHZ_ACCESS_DENIED',
            'actor.user_id' => $user->id,
            'target.resource' => 'api/admin/users'
        ]);
    }
}
```

### 6.3 Security Tests

```php
<?php

namespace Tests\Security;

class LogInjectionTest extends TestCase
{
    /** @test */
    public function it_sanitizes_newlines_in_log_fields()
    {
        $this->postJson('/api/auth/login', [
            'email' => "test@example.com\n{\"event_type\":\"FAKE\"}",
            'password' => 'password'
        ]);

        // Verify no log injection occurred
        $this->assertSecurityLogDoesNotContain(['event_type' => 'FAKE']);
    }

    /** @test */
    public function it_does_not_log_passwords()
    {
        $this->postJson('/api/auth/login', [
            'email' => 'test@example.com',
            'password' => 'secret_password_123'
        ]);

        $this->assertSecurityLogDoesNotContain(['secret_password_123']);
    }
}
```

---

## 7. Метрики и Dashboards

### 7.1 Kibana Dashboards

**Security Overview Dashboard:**

| Panel               | Visualization | Query                                                                      |
| ------------------- | ------------- | -------------------------------------------------------------------------- | ------------------------ |
| Auth Success Rate   | Gauge         | `event_type:AUTH_LOGIN_SUCCESS / (AUTH_LOGIN_SUCCESS + AUTH_LOGIN_FAILED)` |
| Failed Logins by IP | Data Table    | `event_type:AUTH_LOGIN_FAILED                                              | top 10 request.ip`       |
| Access Denied Trend | Line Chart    | `event_type:AUTHZ_ACCESS_DENIED                                            | histogram by @timestamp` |
| File Downloads      | Metric        | `event_type:DATA_FILE_DOWNLOADED                                           | count`                   |
| Payment Operations  | Pie Chart     | `event*type:BIZ_PAYMENT*\*                                                 | terms result.status`     |

### 7.2 Prometheus Metrics

```php
<?php
// Экспорт метрик для Prometheus

// security_auth_total{result="success|failure",method="password|2fa|sso"}
// security_authz_denied_total{resource="...",action="..."}
// security_file_access_total{operation="download|upload|delete"}
// security_business_operations_total{type="payment|invoice",result="success|failure"}
```

---

## 8. Compliance Mapping

### 8.1 PCI DSS 4.0

| Requirement | Security Logging Coverage                   |
| ----------- | ------------------------------------------- |
| 10.2.1.1    | `AUTH_LOGIN_SUCCESS`, `AUTH_LOGIN_FAILED`   |
| 10.2.1.2    | `AUTHZ_ACCESS_DENIED`, `AUTHZ_PERMISSION_*` |
| 10.2.1.3    | `DATA_FILE_*`, `BIZ_*`                      |
| 10.2.1.4    | `SEC_*`                                     |
| 10.2.1.5    | `ADMIN_*`                                   |
| 10.2.1.6    | `AUTH_*` (initialization, start, stop)      |
| 10.2.1.7    | `DATA_*` (creation, deletion, modification) |

### 8.2 SOC 2

| Trust Service Criteria | Security Logging Coverage       |
| ---------------------- | ------------------------------- |
| CC6.1 (Logical Access) | `AUTH_*`, `AUTHZ_*`             |
| CC6.2 (Authentication) | `AUTH_*`, `AUTH_2FA_*`          |
| CC6.3 (Authorization)  | `AUTHZ_*`, `ADMIN_PERMISSION_*` |
| CC7.2 (Monitoring)     | Все события + alerting          |

---

## 9. Риски и Mitigation

| Риск                    | Impact | Probability | Mitigation                        |
| ----------------------- | ------ | ----------- | --------------------------------- |
| Performance degradation | HIGH   | MEDIUM      | Async logging, rate limiting      |
| Log storage overflow    | MEDIUM | MEDIUM      | Retention policies, log rotation  |
| Sensitive data leakage  | HIGH   | LOW         | Redaction, code review            |
| Log injection attacks   | MEDIUM | LOW         | Input sanitization, JSON encoding |
| Missing events          | MEDIUM | MEDIUM      | Integration tests, monitoring     |

---

## 10. Timeline и Resources

### 10.1 Timeline

```txt
Week 1-2:   Package development + authorization-service
Week 3:     explorer-service + billing-service (payments)
Week 4:     billing-service (invoices) + registry-service
Week 5:     workspace-service + notification-service
Week 6:     Integration testing + SIEM setup
Week 7-8:   Alerting rules + Dashboards
Week 9-10:  Production rollout + Monitoring
```

### 10.2 Resources

| Role              | Allocation | Duration |
| ----------------- | ---------- | -------- |
| Backend Developer | 1 FTE      | 6 weeks  |
| DevOps Engineer   | 0.5 FTE    | 4 weeks  |
| Security Engineer | 0.25 FTE   | 10 weeks |
| QA Engineer       | 0.5 FTE    | 4 weeks  |

---

## 11. Appendix

### A. Полный список событий из аудитов

| Сервис        | Finding         | Требуемое логирование                           |
| ------------- | --------------- | ----------------------------------------------- |
| authorization | A09-W-001       | Auth failures/successes                         |
| authorization | A04-W1, A04-W2  | Rate limit events, SMS/email triggers           |
| billing       | LM-MAJ-001      | Invoice/order state changes, refunds            |
| billing       | A04-W04         | Payment callback events                         |
| explorer      | A09-LOG-001     | Authorization failures (403)                    |
| explorer      | IDOR findings   | File access events                              |
| notification  | A09-LOG-MAJ-002 | Webhook events (redacted)                       |
| notification  | A09-LOG-MAJ-003 | Error handling (no exception details to client) |
| notification  | A09-LOG-MIN-005 | Request correlation                             |
| registry      | A04-W5          | ESEDO workflow events                           |
| registry      | A09-LOG-002     | Audit trail (redacted)                          |
| registry      | A09-LOG-003     | IP logging sanitization                         |
| registry      | A09-LOG-004     | Authorization denied events                     |
| workspace     | ID-A04-006      | Membership/permission changes                   |

### B. Glossary

| Term           | Definition                                                      |
| -------------- | --------------------------------------------------------------- |
| MTTD           | Mean Time to Detect — среднее время обнаружения инцидента       |
| SIEM           | Security Information and Event Management                       |
| Correlation ID | Уникальный идентификатор для связывания событий между сервисами |
| Request ID     | Уникальный идентификатор HTTP запроса                           |
| Redaction      | Маскирование чувствительных данных в логах                      |
| IDOR           | Insecure Direct Object Reference                                |
