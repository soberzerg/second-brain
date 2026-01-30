# Внедрение Elastic APM для Distributed Tracing в Dogovor24

## 1. Executive Summary

### 1.1 Контекст

Данный документ является логическим продолжением [PRD-Security-Logging.md](./PRD-Security-Logging.md). Security-логирование обеспечивает аудит событий безопасности, но не решает задачи:

- **Трассировки запросов** между 24 микросервисами
- **Performance мониторинга** и выявления узких мест
- **Корреляции ошибок** в цепочках межсервисных вызовов
- **Анализа latency** на уровне отдельных операций

### 1.2 Почему Elastic APM

| Критерий               | Elastic APM       | Jaeger            | Sentry Performance |
| ---------------------- | ----------------- | ----------------- | ------------------ |
| Elasticsearch уже есть | **Да (7.x)**      | Нет               | Нет                |
| PHP Laravel поддержка  | Отличная          | Хорошая           | Отличная           |
| RabbitMQ tracing       | Да                | Требует настройки | Ограничен          |
| Единый стек с логами   | **Да**            | Нет               | Нет                |
| Стоимость              | Бесплатно (Basic) | Бесплатно         | Платно             |
| Kubernetes интеграция  | Да                | Да                | Да                 |

**Вывод:** Elastic APM оптимален, так как Elasticsearch 7.x уже используется в проекте, что обеспечивает единый стек для логов, метрик и трейсов.

### 1.3 Связь с Security-логированием

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Observability Stack                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌───────────────────────┐    ┌───────────────────────┐                     │
│  │   Security Logging    │    │     Elastic APM       │                     │
│  │   (PRD-Security-      │    │   (Этот документ)     │                     │
│  │    Logging.md)        │    │                       │                     │
│  ├───────────────────────┤    ├───────────────────────┤                     │
│  │ • AUTH_* события      │    │ • Distributed traces  │                     │
│  │ • AUTHZ_* события     │    │ • Spans & transactions│                     │
│  │ • BIZ_* события       │    │ • Performance metrics │                     │
│  │ • Аудит и compliance  │    │ • Error tracking      │                     │
│  └───────────┬───────────┘    └───────────┬───────────┘                     │
│              │                            │                                 │
│              │    ┌───────────────────┐   │                                 │
│              └───►│  Correlation ID   │◄──┘                                 │
│                   │  (request_id)     │                                     │
│                   └─────────┬─────────┘                                     │
│                             │                                               │
│                             ▼                                               │
│                   ┌───────────────────┐                                     │
│                   │   Elasticsearch   │                                     │
│                   │   + Kibana        │                                     │
│                   └───────────────────┘                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Ключевой принцип:** `request_id` из Security Logging = `trace.id` в APM, что позволяет связывать security-события с трейсами производительности.

### 1.4 Ключевые метрики успеха

| Метрика                           | Текущее | Целевое                 |
| --------------------------------- | ------- | ----------------------- |
| Видимость межсервисных вызовов    | 0%      | 100%                    |
| P95 latency visibility            | Нет     | <500ms для 95% запросов |
| Error correlation across services | Нет     | 100%                    |
| MTTR (Mean Time to Resolution)    | ~4 часа | <30 мин                 |
| RabbitMQ event tracing            | Нет     | 100%                    |

---

## 2. Архитектура решения

### 2.1 Компоненты Elastic APM

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Kubernetes Cluster                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │authorization │  │   billing    │  │   explorer   │  │   registry   │     │
│  │   service    │  │   service    │  │   service    │  │   service    │     │
│  │              │  │              │  │              │  │              │     │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │     │
│  │ │ APM Agent│ │  │ │ APM Agent│ │  │ │ APM Agent│ │  │ │ APM Agent│ │     │
│  │ └────┬─────┘ │  │ └────┬─────┘ │  │ └────┬─────┘ │  │ └────┬─────┘ │     │
│  └──────┼───────┘  └──────┼───────┘  └──────┼───────┘  └──────┼───────┘     │
│         │                 │                 │                 │              │
│         └────────────────┬┴─────────────────┴─────────────────┘              │
│                          │                                                   │
│                          ▼                                                   │
│                ┌───────────────────┐                                         │
│                │    APM Server     │ ◄─── Kubernetes Service                 │
│                │   (apm-server)    │      apm-server:8200                    │
│                └─────────┬─────────┘                                         │
│                          │                                                   │
└──────────────────────────┼───────────────────────────────────────────────────┘
                           │
                           ▼
              ┌───────────────────────┐
              │     Elasticsearch     │
              │   (уже существует)    │
              │                       │
              │  Indices:             │
              │  • apm-*-transaction  │
              │  • apm-*-span         │
              │  • apm-*-error        │
              │  • apm-*-metric       │
              └───────────┬───────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │        Kibana         │
              │   (уже существует)    │
              │                       │
              │  • APM UI             │
              │  • Service Map        │
              │  • Trace Explorer     │
              └───────────────────────┘
```

### 2.2 Потоки данных

#### 2.2.1 HTTP запрос (синхронный)

```
Client Request
     │
     ▼
┌────────────────────────────────────────────────────────────────────────────┐
│ authorization-service                                                       │
│ ┌────────────────────────────────────────────────────────────────────────┐ │
│ │ Transaction: POST /api/auth/login                                      │ │
│ │ trace.id: abc123                                                       │ │
│ │                                                                        │ │
│ │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐        │ │
│ │  │ Span: DB Query  │  │ Span: Redis     │  │ Span: HTTP      │        │ │
│ │  │ (user lookup)   │  │ (session)       │  │ (billing-svc)   │        │ │
│ │  │ 15ms            │  │ 2ms             │  │ 45ms            │        │ │
│ │  └─────────────────┘  └─────────────────┘  └────────┬────────┘        │ │
│ └─────────────────────────────────────────────────────┼──────────────────┘ │
└───────────────────────────────────────────────────────┼────────────────────┘
                                                        │
                    ┌───────────────────────────────────┘
                    │ Headers: traceparent, elastic-apm-traceparent
                    ▼
┌────────────────────────────────────────────────────────────────────────────┐
│ billing-service                                                             │
│ ┌────────────────────────────────────────────────────────────────────────┐ │
│ │ Transaction: GET /api/billing/account/{id}                             │ │
│ │ trace.id: abc123 (inherited)                                           │ │
│ │ parent.id: (span from auth-service)                                    │ │
│ │                                                                        │ │
│ │  ┌─────────────────┐  ┌─────────────────┐                              │ │
│ │  │ Span: DB Query  │  │ Span: Cache     │                              │ │
│ │  │ (account)       │  │ (balance)       │                              │ │
│ │  │ 8ms             │  │ 1ms             │                              │ │
│ │  └─────────────────┘  └─────────────────┘                              │ │
│ └────────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────┘
```

#### 2.2.2 RabbitMQ событие (асинхронный)

```
┌────────────────────────────────────────────────────────────────────────────┐
│ authorization-service                                                       │
│ ┌────────────────────────────────────────────────────────────────────────┐ │
│ │ Transaction: UserActivated Event                                       │ │
│ │ trace.id: def456                                                       │ │
│ │                                                                        │ │
│ │  ┌────────────────────┐                                                │ │
│ │  │ Span: RabbitMQ     │───────┐                                        │ │
│ │  │ (publish)          │       │                                        │ │
│ │  │ 3ms                │       │                                        │ │
│ │  └────────────────────┘       │                                        │ │
│ └───────────────────────────────┼────────────────────────────────────────┘ │
└─────────────────────────────────┼──────────────────────────────────────────┘
                                  │
                                  │ Message Headers:
                                  │ • elastic-apm-traceparent
                                  │ • trace.id: def456
                                  ▼
                         ┌─────────────────┐
                         │    RabbitMQ     │
                         └────────┬────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
          ▼                       ▼                       ▼
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ billing-service  │   │ explorer-service │   │notification-svc  │
│                  │   │                  │   │                  │
│ Transaction:     │   │ Transaction:     │   │ Transaction:     │
│ UserActivated    │   │ UserActivated    │   │ UserActivated    │
│ Listener         │   │ Listener         │   │ Listener         │
│                  │   │                  │   │                  │
│ trace.id: def456 │   │ trace.id: def456 │   │ trace.id: def456 │
│ (inherited)      │   │ (inherited)      │   │ (inherited)      │
└──────────────────┘   └──────────────────┘   └──────────────────┘
```

### 2.3 Терминология APM

| Термин          | Описание                       | Пример в Dogovor24                               |
| --------------- | ------------------------------ | ------------------------------------------------ |
| **Transaction** | Входящий запрос или событие    | `POST /api/auth/login`, `UserActivated listener` |
| **Span**        | Операция внутри transaction    | DB query, Redis call, HTTP request               |
| **Trace**       | Цепочка связанных transactions | Полный путь запроса через все сервисы            |
| **trace.id**    | Уникальный ID всего trace      | = `request_id` из Security Logging               |
| **parent.id**   | ID родительского span          | Связь между сервисами                            |
| **Service**     | Микросервис                    | `authorization-service`, `billing-service`       |

---

## 3. Требования к внедрению

### 3.1 Инфраструктурные компоненты

#### 3.1.1 APM Server

**Kubernetes Deployment:**

```yaml
# automation/k8s/apm-server/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apm-server
  namespace: monitoring
  labels:
    app: apm-server
spec:
  replicas: 2
  selector:
    matchLabels:
      app: apm-server
  template:
    metadata:
      labels:
        app: apm-server
    spec:
      containers:
        - name: apm-server
          image: docker.elastic.co/apm/apm-server:7.17.0
          ports:
            - containerPort: 8200
              name: http
          env:
            - name: ELASTICSEARCH_HOSTS
              value: "http://elasticsearch.logging.svc.cluster.local:9200"
            - name: ELASTICSEARCH_USERNAME
              valueFrom:
                secretKeyRef:
                  name: elasticsearch-credentials
                  key: username
            - name: ELASTICSEARCH_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: elasticsearch-credentials
                  key: password
          resources:
            requests:
              memory: "512Mi"
              cpu: "200m"
            limits:
              memory: "1Gi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /
              port: 8200
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 8200
            initialDelaySeconds: 5
            periodSeconds: 5
          volumeMounts:
            - name: config
              mountPath: /usr/share/apm-server/apm-server.yml
              subPath: apm-server.yml
      volumes:
        - name: config
          configMap:
            name: apm-server-config
---
apiVersion: v1
kind: Service
metadata:
  name: apm-server
  namespace: monitoring
spec:
  selector:
    app: apm-server
  ports:
    - port: 8200
      targetPort: 8200
      name: http
  type: ClusterIP
```

**ConfigMap:**

```yaml
# automation/k8s/apm-server/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: apm-server-config
  namespace: monitoring
data:
  apm-server.yml: |
    apm-server:
      host: "0.0.0.0:8200"

      # Rate limiting
      max_event_size: 307200  # 300KB
      max_connections: 1000

      # Auth (опционально)
      auth:
        anonymous:
          enabled: true
          allow_agent: ["php"]
          allow_service: ["*"]

      # Sampling
      sampling:
        keep_unsampled: false
        tail:
          enabled: true
          interval: 1m
          policies:
            - sample_rate: 1.0  # Всегда сэмплировать ошибки
              type: errors
            - sample_rate: 0.1  # 10% для успешных
              type: transactions

      # RUM (если нужен frontend tracing)
      rum:
        enabled: true
        allow_origins: ["https://dogovor24.kz", "https://dogovor24.ru"]

    output.elasticsearch:
      hosts: ["${ELASTICSEARCH_HOSTS}"]
      username: "${ELASTICSEARCH_USERNAME}"
      password: "${ELASTICSEARCH_PASSWORD}"

      # ILM для управления retention
      ilm.enabled: true
      ilm.rollover_alias: "apm"
      ilm.pattern: "{now/d}-000001"

    # Kibana для создания дашбордов
    kibana:
      enabled: true
      host: "http://kibana.logging.svc.cluster.local:5601"
```

#### 3.1.2 Elasticsearch ILM Policy

```json
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_size": "50gb",
            "max_age": "1d"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "shrink": {
            "number_of_shards": 1
          },
          "forcemerge": {
            "max_num_segments": 1
          },
          "set_priority": {
            "priority": 50
          }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "set_priority": {
            "priority": 0
          },
          "freeze": {}
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

### 3.2 PHP APM Agent

#### 3.2.1 Установка

```bash
# Для каждого backend сервиса
composer require elastic/apm-agent-php
```

#### 3.2.2 Системные требования

| Требование      | Минимум | Рекомендуется |
| --------------- | ------- | ------------- |
| PHP версия      | 7.2+    | 7.4+          |
| ext-curl        | Да      | Да            |
| ext-json        | Да      | Да            |
| Memory overhead | ~5MB    | ~10MB         |

### 3.3 Shared Package: `dogovor24/apm-package`

#### 3.3.1 Структура пакета

```
vendor/dogovor24/apm-package/
├── src/
│   ├── ApmServiceProvider.php         # Laravel Service Provider
│   ├── ApmService.php                  # Основной сервис
│   ├── Middleware/
│   │   ├── ApmTransactionMiddleware.php   # HTTP transactions
│   │   └── ApmCorrelationMiddleware.php   # Связь с Security Logging
│   ├── Listeners/
│   │   └── ApmQueueListener.php        # RabbitMQ tracing
│   ├── Http/
│   │   └── ApmGuzzleMiddleware.php     # Исходящие HTTP
│   ├── Database/
│   │   └── ApmQuerySubscriber.php      # DB queries tracing
│   ├── Integrations/
│   │   ├── AuthRequestServiceIntegration.php
│   │   ├── RabbitMQIntegration.php
│   │   └── RedisIntegration.php
│   └── Context/
│       └── TraceContext.php            # Хранение trace context
├── config/
│   └── apm.php
└── tests/
```

---

## 4. Техническая реализация

### 4.1 Конфигурация

```php
<?php
// config/apm.php

return [
    /*
    |--------------------------------------------------------------------------
    | APM Enabled
    |--------------------------------------------------------------------------
    */
    'enabled' => env('APM_ENABLED', true),

    /*
    |--------------------------------------------------------------------------
    | APM Server
    |--------------------------------------------------------------------------
    */
    'server_url' => env('APM_SERVER_URL', 'http://apm-server.monitoring.svc.cluster.local:8200'),

    /*
    |--------------------------------------------------------------------------
    | Service Configuration
    |--------------------------------------------------------------------------
    */
    'service' => [
        'name' => env('APM_SERVICE_NAME', env('SERVICE_NAME', 'unknown-service')),
        'version' => env('APM_SERVICE_VERSION', env('SERVICE_VERSION', '1.0.0')),
        'environment' => env('APM_ENVIRONMENT', env('APP_ENV', 'production')),
    ],

    /*
    |--------------------------------------------------------------------------
    | Sampling
    |--------------------------------------------------------------------------
    | Процент транзакций для трейсинга (0.0 - 1.0)
    */
    'transaction_sample_rate' => env('APM_SAMPLE_RATE', 0.1), // 10%

    /*
    |--------------------------------------------------------------------------
    | Spans Configuration
    |--------------------------------------------------------------------------
    */
    'spans' => [
        'db' => [
            'enabled' => true,
            'threshold_ms' => 5,  // Логировать queries > 5ms
        ],
        'http' => [
            'enabled' => true,
        ],
        'redis' => [
            'enabled' => true,
        ],
        'rabbitmq' => [
            'enabled' => true,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Context Propagation
    |--------------------------------------------------------------------------
    */
    'propagation' => [
        // W3C Trace Context headers
        'headers' => [
            'traceparent',
            'tracestate',
            'elastic-apm-traceparent',  // Legacy
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Labels (Custom Fields)
    |--------------------------------------------------------------------------
    */
    'labels' => [
        'region' => env('REGION', 'kz'),
        'cluster' => env('CLUSTER_NAME', 'unknown'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Sensitive Data Filtering
    |--------------------------------------------------------------------------
    */
    'sanitize_field_names' => [
        'password',
        'passwd',
        'pwd',
        'secret',
        'token',
        'api_key',
        'apikey',
        'credit_card',
        'card_number',
        'iin',
        'authorization',
        'cookie',
        'session',
    ],

    /*
    |--------------------------------------------------------------------------
    | Stack Trace Configuration
    |--------------------------------------------------------------------------
    */
    'stack_trace' => [
        'spans' => true,
        'errors' => true,
        'limit' => 50,
    ],

    /*
    |--------------------------------------------------------------------------
    | Performance
    |--------------------------------------------------------------------------
    */
    'performance' => [
        'flush_interval' => 10,  // seconds
        'max_queue_size' => 500,
        'api_request_time' => 25000,  // ms timeout для APM server
    ],
];
```

### 4.2 Service Provider

```php
<?php

namespace Dogovor24\Apm;

use Elastic\Apm\ElasticApm;
use Illuminate\Support\ServiceProvider;
use Illuminate\Contracts\Http\Kernel;

class ApmServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__ . '/../config/apm.php', 'apm');

        $this->app->singleton(ApmService::class, function ($app) {
            return new ApmService(config('apm'));
        });
    }

    public function boot(): void
    {
        if (!config('apm.enabled')) {
            return;
        }

        $this->publishes([
            __DIR__ . '/../config/apm.php' => config_path('apm.php'),
        ], 'config');

        // Регистрация middleware
        $kernel = $this->app->make(Kernel::class);
        $kernel->prependMiddleware(Middleware\ApmTransactionMiddleware::class);
        $kernel->pushMiddleware(Middleware\ApmCorrelationMiddleware::class);

        // DB Query tracing
        if (config('apm.spans.db.enabled')) {
            $this->app->make('db')->listen(function ($query) {
                $this->app->make(ApmService::class)->recordDbQuery($query);
            });
        }

        // Queue listener для RabbitMQ
        if (config('apm.spans.rabbitmq.enabled')) {
            $this->app['events']->listen(
                'Illuminate\Queue\Events\JobProcessing',
                Listeners\ApmQueueListener::class . '@onJobProcessing'
            );
            $this->app['events']->listen(
                'Illuminate\Queue\Events\JobProcessed',
                Listeners\ApmQueueListener::class . '@onJobProcessed'
            );
            $this->app['events']->listen(
                'Illuminate\Queue\Events\JobFailed',
                Listeners\ApmQueueListener::class . '@onJobFailed'
            );
        }
    }
}
```

### 4.3 ApmService

```php
<?php

namespace Dogovor24\Apm;

use Elastic\Apm\ElasticApm;
use Elastic\Apm\TransactionInterface;
use Elastic\Apm\SpanInterface;

class ApmService
{
    private array $config;
    private ?TransactionInterface $currentTransaction = null;
    private array $spans = [];

    public function __construct(array $config)
    {
        $this->config = $config;
        $this->initializeAgent();
    }

    private function initializeAgent(): void
    {
        if (!$this->config['enabled']) {
            return;
        }

        // Конфигурация агента через environment variables
        putenv('ELASTIC_APM_SERVICE_NAME=' . $this->config['service']['name']);
        putenv('ELASTIC_APM_SERVICE_VERSION=' . $this->config['service']['version']);
        putenv('ELASTIC_APM_ENVIRONMENT=' . $this->config['service']['environment']);
        putenv('ELASTIC_APM_SERVER_URL=' . $this->config['server_url']);
        putenv('ELASTIC_APM_TRANSACTION_SAMPLE_RATE=' . $this->config['transaction_sample_rate']);
        putenv('ELASTIC_APM_SANITIZE_FIELD_NAMES=' . implode(',', $this->config['sanitize_field_names']));
    }

    /**
     * Начать транзакцию для HTTP запроса
     */
    public function beginHttpTransaction(string $name, string $type = 'request'): TransactionInterface
    {
        $this->currentTransaction = ElasticApm::beginCurrentTransaction($name, $type);

        // Добавить labels
        foreach ($this->config['labels'] as $key => $value) {
            $this->currentTransaction->context()->setLabel($key, $value);
        }

        return $this->currentTransaction;
    }

    /**
     * Начать транзакцию для Queue job
     */
    public function beginQueueTransaction(string $jobName, array $messageHeaders = []): TransactionInterface
    {
        // Извлечь trace context из headers сообщения
        $distributedTracingData = null;
        foreach ($this->config['propagation']['headers'] as $header) {
            if (isset($messageHeaders[$header])) {
                $distributedTracingData = $messageHeaders[$header];
                break;
            }
        }

        if ($distributedTracingData) {
            $this->currentTransaction = ElasticApm::newTransaction($jobName, 'messaging')
                ->asCurrent()
                ->distributedTracingHeaderExtractor(fn() => $distributedTracingData)
                ->begin();
        } else {
            $this->currentTransaction = ElasticApm::beginCurrentTransaction($jobName, 'messaging');
        }

        return $this->currentTransaction;
    }

    /**
     * Завершить текущую транзакцию
     */
    public function endTransaction(?string $result = null): void
    {
        if ($this->currentTransaction) {
            if ($result) {
                $this->currentTransaction->setResult($result);
            }
            $this->currentTransaction->end();
            $this->currentTransaction = null;
        }
    }

    /**
     * Начать span для операции
     */
    public function beginSpan(string $name, string $type, ?string $subtype = null): SpanInterface
    {
        $span = ElasticApm::getCurrentTransaction()?->beginChildSpan($name, $type, $subtype);

        if ($span) {
            $this->spans[$name] = $span;
        }

        return $span;
    }

    /**
     * Завершить span
     */
    public function endSpan(string $name): void
    {
        if (isset($this->spans[$name])) {
            $this->spans[$name]->end();
            unset($this->spans[$name]);
        }
    }

    /**
     * Записать DB query как span
     */
    public function recordDbQuery($query): void
    {
        $threshold = $this->config['spans']['db']['threshold_ms'] ?? 0;

        if ($query->time >= $threshold) {
            $span = $this->beginSpan('DB Query', 'db', 'postgresql');

            if ($span) {
                $span->context()->db()->setStatement($query->sql);
                $span->context()->db()->setType('postgresql');
                $span->end($query->time);
            }
        }
    }

    /**
     * Записать исходящий HTTP запрос как span
     */
    public function recordHttpRequest(string $method, string $url, float $duration, int $statusCode): SpanInterface
    {
        $span = $this->beginSpan("$method $url", 'external', 'http');

        if ($span) {
            $span->context()->http()->setMethod($method);
            $span->context()->http()->setUrl($url);
            $span->context()->http()->setStatusCode($statusCode);
            $span->end($duration);
        }

        return $span;
    }

    /**
     * Записать ошибку
     */
    public function captureError(\Throwable $exception): void
    {
        ElasticApm::captureCurrentTransaction()
            ?->createError($exception)
            ->send();
    }

    /**
     * Получить headers для propagation в исходящий запрос
     */
    public function getDistributedTracingHeaders(): array
    {
        $headers = [];

        $transaction = ElasticApm::getCurrentTransaction();
        if ($transaction) {
            $headers['elastic-apm-traceparent'] = $transaction->getDistributedTracingDataForRequest();
            $headers['traceparent'] = $transaction->getDistributedTracingDataForRequest();
        }

        return $headers;
    }

    /**
     * Получить текущий trace ID (для связи с Security Logging)
     */
    public function getTraceId(): ?string
    {
        return ElasticApm::getCurrentTransaction()?->getTraceId();
    }

    /**
     * Установить user context
     */
    public function setUserContext(?int $userId, ?string $email = null): void
    {
        $transaction = ElasticApm::getCurrentTransaction();

        if ($transaction && $userId) {
            $transaction->context()->user()->setId((string)$userId);
            if ($email) {
                // Маскируем email для privacy
                $transaction->context()->user()->setEmail($this->maskEmail($email));
            }
        }
    }

    /**
     * Добавить custom label
     */
    public function setLabel(string $key, $value): void
    {
        ElasticApm::getCurrentTransaction()?->context()->setLabel($key, $value);
    }

    private function maskEmail(string $email): string
    {
        $parts = explode('@', $email);
        if (count($parts) === 2) {
            return substr($parts[0], 0, 1) . '***@' . $parts[1];
        }
        return '***';
    }
}
```

### 4.4 HTTP Transaction Middleware

```php
<?php

namespace Dogovor24\Apm\Middleware;

use Closure;
use Illuminate\Http\Request;
use Dogovor24\Apm\ApmService;

class ApmTransactionMiddleware
{
    private ApmService $apm;

    public function __construct(ApmService $apm)
    {
        $this->apm = $apm;
    }

    public function handle(Request $request, Closure $next)
    {
        if (!config('apm.enabled')) {
            return $next($request);
        }

        // Начать транзакцию
        $transactionName = $request->method() . ' ' . $this->getRouteName($request);
        $transaction = $this->apm->beginHttpTransaction($transactionName);

        // Установить context
        $transaction->context()->request()->setMethod($request->method());
        $transaction->context()->request()->setUrl([
            'full' => $request->fullUrl(),
            'path' => $request->path(),
            'query' => $request->query(),
        ]);

        // Добавить custom labels
        if ($workspaceId = $request->header('X-Workspace-ID')) {
            $this->apm->setLabel('workspace_id', $workspaceId);
        }

        if ($region = $request->header('X-Region')) {
            $this->apm->setLabel('region', $region);
        }

        try {
            $response = $next($request);

            // Записать результат
            $statusCode = $response->getStatusCode();
            $transaction->setResult($this->getResultFromStatusCode($statusCode));
            $transaction->context()->response()->setStatusCode($statusCode);

            return $response;
        } catch (\Throwable $e) {
            // Записать ошибку
            $this->apm->captureError($e);
            $transaction->setResult('error');
            throw $e;
        } finally {
            $this->apm->endTransaction();
        }
    }

    private function getRouteName(Request $request): string
    {
        $route = $request->route();

        if ($route) {
            // Использовать route pattern вместо конкретных значений
            // Например: /api/users/{id} вместо /api/users/123
            return $route->uri() ?? $request->path();
        }

        return $request->path();
    }

    private function getResultFromStatusCode(int $statusCode): string
    {
        if ($statusCode >= 200 && $statusCode < 300) {
            return 'success';
        }
        if ($statusCode >= 400 && $statusCode < 500) {
            return 'client_error';
        }
        if ($statusCode >= 500) {
            return 'server_error';
        }
        return 'unknown';
    }
}
```

### 4.5 Корреляция с Security Logging

```php
<?php

namespace Dogovor24\Apm\Middleware;

use Closure;
use Illuminate\Http\Request;
use Dogovor24\Apm\ApmService;
use Illuminate\Support\Facades\Log;

class ApmCorrelationMiddleware
{
    private ApmService $apm;

    public function __construct(ApmService $apm)
    {
        $this->apm = $apm;
    }

    public function handle(Request $request, Closure $next)
    {
        // Получить trace.id из APM
        $traceId = $this->apm->getTraceId();

        if ($traceId) {
            // Использовать trace.id как request_id для Security Logging
            $request->attributes->set('request_id', $traceId);
            $request->attributes->set('trace_id', $traceId);

            // Добавить в контекст всех логов
            Log::withContext([
                'trace_id' => $traceId,
                'request_id' => $traceId,  // Совместимость с Security Logging
            ]);
        }

        $response = $next($request);

        // Добавить trace_id в response headers для отладки
        if ($traceId) {
            $response->headers->set('X-Trace-ID', $traceId);
        }

        return $response;
    }
}
```

### 4.6 Интеграция с AuthRequestService

```php
<?php

namespace Dogovor24\Apm\Integrations;

use Dogovor24\Apm\ApmService;
use GuzzleHttp\Client;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Middleware;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

class AuthRequestServiceIntegration
{
    private ApmService $apm;

    public function __construct(ApmService $apm)
    {
        $this->apm = $apm;
    }

    /**
     * Создать Guzzle middleware для трейсинга
     */
    public function createGuzzleMiddleware(): callable
    {
        return function (callable $handler) {
            return function (RequestInterface $request, array $options) use ($handler) {
                // Добавить trace headers
                $tracingHeaders = $this->apm->getDistributedTracingHeaders();
                foreach ($tracingHeaders as $name => $value) {
                    $request = $request->withHeader($name, $value);
                }

                // Начать span
                $spanName = $request->getMethod() . ' ' . $request->getUri()->getHost();
                $span = $this->apm->beginSpan($spanName, 'external', 'http');

                $startTime = microtime(true);

                return $handler($request, $options)->then(
                    function (ResponseInterface $response) use ($span, $request, $startTime) {
                        $duration = (microtime(true) - $startTime) * 1000;

                        if ($span) {
                            $span->context()->http()->setMethod($request->getMethod());
                            $span->context()->http()->setUrl((string)$request->getUri());
                            $span->context()->http()->setStatusCode($response->getStatusCode());
                            $span->end($duration);
                        }

                        return $response;
                    },
                    function (\Exception $e) use ($span) {
                        if ($span) {
                            $span->end();
                        }
                        $this->apm->captureError($e);
                        throw $e;
                    }
                );
            };
        };
    }
}
```

**Модификация AuthRequestService:**

```php
<?php
// vendor/dogovor24/authorization-package/src/Services/AuthRequestService.php

namespace Dogovor24\Authorization\Services;

use Dogovor24\Apm\ApmService;
use Dogovor24\Apm\Integrations\AuthRequestServiceIntegration;
use GuzzleHttp\Client;
use GuzzleHttp\HandlerStack;

class AuthRequestService
{
    private ?ApmService $apm = null;

    public function getHttpClient($token = false, $systemUuid = false)
    {
        $stack = HandlerStack::create();

        // Добавить APM middleware если доступен
        if (app()->bound(ApmService::class)) {
            $this->apm = app(ApmService::class);
            $integration = new AuthRequestServiceIntegration($this->apm);
            $stack->push($integration->createGuzzleMiddleware(), 'apm');
        }

        $options = [
            'handler' => $stack,
            'headers' => $this->buildHeaders($token, $systemUuid),
            'timeout' => 30,
        ];

        return new Client($options);
    }

    private function buildHeaders($token, $systemUuid): array
    {
        $headers = [];

        if ($token) {
            $headers['Authorization'] = 'Bearer ' . $this->getToken();
        }

        // Добавить trace headers
        if ($this->apm) {
            $headers = array_merge($headers, $this->apm->getDistributedTracingHeaders());
        }

        // Добавить correlation headers
        if ($requestId = request()?->attributes?->get('request_id')) {
            $headers['X-Request-ID'] = $requestId;
            $headers['X-Correlation-ID'] = $requestId;
        }

        return $headers;
    }
}
```

### 4.7 RabbitMQ Integration

```php
<?php

namespace Dogovor24\Apm\Listeners;

use Dogovor24\Apm\ApmService;
use Illuminate\Queue\Events\JobProcessing;
use Illuminate\Queue\Events\JobProcessed;
use Illuminate\Queue\Events\JobFailed;

class ApmQueueListener
{
    private ApmService $apm;

    public function __construct(ApmService $apm)
    {
        $this->apm = $apm;
    }

    public function onJobProcessing(JobProcessing $event): void
    {
        $job = $event->job;
        $payload = $job->payload();

        // Извлечь trace context из payload
        $messageHeaders = $payload['_apm_trace'] ?? [];

        // Начать транзакцию с наследованием trace context
        $this->apm->beginQueueTransaction(
            $payload['displayName'] ?? get_class($job),
            $messageHeaders
        );

        // Добавить context
        $this->apm->setLabel('queue', $job->getQueue());
        $this->apm->setLabel('connection', $job->getConnectionName());
    }

    public function onJobProcessed(JobProcessed $event): void
    {
        $this->apm->endTransaction('success');
    }

    public function onJobFailed(JobFailed $event): void
    {
        if ($event->exception) {
            $this->apm->captureError($event->exception);
        }
        $this->apm->endTransaction('failure');
    }
}
```

**Модификация queue-package для добавления trace context:**

```php
<?php
// vendor/dogovor24/queue-package/src/Events/BaseEvent.php

namespace Dogovor24\Queue\Events;

use Dogovor24\Apm\ApmService;

abstract class BaseEvent
{
    protected array $payload = [];

    public function broadcast(): void
    {
        // Добавить APM trace context в payload
        if (app()->bound(ApmService::class)) {
            $apm = app(ApmService::class);
            $this->payload['_apm_trace'] = $apm->getDistributedTracingHeaders();
        }

        // Существующая логика публикации
        $this->publish();
    }

    // ...
}
```

---

## 5. Рекомендации по внедрению

### 5.1 Фазы внедрения

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Phase 1 (Infra)        │  Phase 2 (Core)         │  Phase 3 (Advanced)     │
│  ────────────────────   │  ──────────────────     │  ────────────────────── │
│  • APM Server в K8s     │  • authorization-svc    │  • Все остальные сервисы│
│  • apm-package          │  • billing-service      │  • Frontend RUM         │
│  • Базовая интеграция   │  • explorer-service     │  • Custom dashboards    │
│  • Kibana APM UI        │  • RabbitMQ tracing     │  • Alerting rules       │
│                         │  • AuthRequestService   │  • Service Map          │
│                         │    integration          │  • ML Anomaly Detection │
│                         │                         │                         │
│  Срок: 1-2 недели       │  Срок: 2-3 недели       │  Срок: 2-3 недели       │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Phase 1: Инфраструктура

#### Задачи:

| #   | Задача                | Описание                                    | Ответственный |
| --- | --------------------- | ------------------------------------------- | ------------- |
| 1.1 | Развернуть APM Server | Kubernetes deployment + ConfigMap           | DevOps        |
| 1.2 | Настроить ILM         | Index Lifecycle Management для APM индексов | DevOps        |
| 1.3 | Создать apm-package   | Shared package с базовой интеграцией        | Backend       |
| 1.4 | Настроить Kibana APM  | Включить APM UI в Kibana                    | DevOps        |
| 1.5 | Тесты инфраструктуры  | Проверить connectivity и sampling           | QA            |

#### Чеклист готовности:

- [ ] APM Server доступен по `http://apm-server.monitoring:8200`
- [ ] APM индексы создаются в Elasticsearch
- [ ] Kibana APM UI показывает тестовые данные
- [ ] ILM policy применён
- [ ] apm-package установлен в тестовый сервис

### 5.3 Phase 2: Core Services

#### 5.3.1 authorization-service

**Точки интеграции:**

| Компонент                      | Тип                 | Приоритет |
| ------------------------------ | ------------------- | --------- |
| `AuthController::login`        | Transaction         | P0        |
| `AuthController::logout`       | Transaction         | P1        |
| `TwoFAController`              | Transaction + Spans | P0        |
| `PasswordResetEmailController` | Transaction         | P1        |
| DB queries                     | Spans               | P0        |
| Redis calls                    | Spans               | P1        |
| HTTP к billing-service         | Spans               | P0        |

**Изменения в Kernel.php:**

```php
<?php

namespace App\Http;

use Illuminate\Foundation\Http\Kernel as HttpKernel;

class Kernel extends HttpKernel
{
    protected $middleware = [
        // APM должен быть первым
        \Dogovor24\Apm\Middleware\ApmTransactionMiddleware::class,

        // ... существующие middleware

        // Корреляция с Security Logging
        \Dogovor24\Apm\Middleware\ApmCorrelationMiddleware::class,
        \Dogovor24\SecurityLogging\Middleware\RequestIdMiddleware::class,
    ];
}
```

#### 5.3.2 billing-service

**Точки интеграции:**

| Компонент             | Тип         | Приоритет |
| --------------------- | ----------- | --------- |
| `PaymentController`   | Transaction | P0        |
| `InvoiceController`   | Transaction | P0        |
| Halyk/Epay HTTP calls | Spans       | P0        |
| RabbitMQ events       | Spans       | P0        |
| DB queries            | Spans       | P0        |

#### 5.3.3 explorer-service

**Точки интеграции:**

| Компонент                 | Тип         | Приоритет |
| ------------------------- | ----------- | --------- |
| `UUIDFileController`      | Transaction | P0        |
| `FileSignatureController` | Transaction | P0        |
| e-signature HTTP calls    | Spans       | P0        |
| MinIO/S3 operations       | Spans       | P0        |
| RabbitMQ events           | Spans       | P0        |

### 5.4 Phase 3: Advanced

#### 5.4.1 Frontend RUM (Real User Monitoring)

```javascript
// frontend/dogovor24/plugins/apm.js
import { init as initApm } from "@elastic/apm-rum";

const apm = initApm({
  serviceName: "dogovor24-frontend",
  serverUrl: process.env.APM_SERVER_URL || "https://apm.dogovor24.kz",
  serviceVersion: process.env.npm_package_version,
  environment: process.env.NODE_ENV,

  // Distributed tracing
  distributedTracingOrigins: [
    "https://dogovor24.kz",
    "https://dogovor24.ru",
    /https:\/\/.*\.dogovor24\.(kz|ru)/,
  ],

  // Page load tracing
  pageLoadTraceId: window.__APM_TRACE_ID__,
  pageLoadSpanId: window.__APM_SPAN_ID__,
});

export default apm;
```

#### 5.4.2 Alerting Rules

```yaml
# Kibana Alert Rules

# Высокая latency
- name: "High Transaction Latency"
  condition:
    type: threshold
    metric: transaction.duration.us
    percentile: 95
    threshold: 5000000 # 5 секунд
    window: 5m
  actions:
    - slack:
        channel: "#alerts-apm"
        message: "P95 latency > 5s for {{ service.name }}"

# Высокий error rate
- name: "High Error Rate"
  condition:
    type: threshold
    metric: error_rate
    threshold: 0.05 # 5%
    window: 5m
  actions:
    - pagerduty:
        severity: high

# Аномалия в RabbitMQ
- name: "Queue Processing Slow"
  condition:
    type: threshold
    metric: transaction.duration.us
    filter: transaction.type:messaging
    percentile: 95
    threshold: 10000000 # 10 секунд
    window: 5m
  actions:
    - slack:
        channel: "#alerts-apm"
```

---

## 6. Dashboards и Visualizations

### 6.1 Service Overview Dashboard

| Panel                   | Visualization | Metric                                  |
| ----------------------- | ------------- | --------------------------------------- |
| Transactions per minute | Line chart    | `transaction.count`                     |
| P95 Latency             | Line chart    | `transaction.duration.us` percentile 95 |
| Error Rate              | Line chart    | `error_rate`                            |
| Throughput by service   | Bar chart     | `transaction.count` by `service.name`   |
| Top slow transactions   | Table         | Top 10 by `transaction.duration.us`     |
| Service Map             | Service Map   | Auto-generated                          |

### 6.2 Trace Explorer Queries

**Найти медленные транзакции:**

```
service.name: "authorization-service" AND transaction.duration.us > 3000000
```

**Найти транзакции с ошибками:**

```
service.name: "billing-service" AND transaction.result: "error"
```

**Корреляция с Security Logging:**

```
trace.id: "abc123-def456-..."
```

### 6.3 Service Map

APM автоматически строит карту зависимостей между сервисами на основе distributed tracing. Ожидаемая топология:

```
                    ┌─────────────────┐
                    │    Frontend     │
                    │  (dogovor24)    │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  authorization  │
                    │    service      │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│    billing    │   │   explorer    │   │   workspace   │
│   service     │   │   service     │   │   service     │
└───────┬───────┘   └───────┬───────┘   └───────────────┘
        │                   │
        ▼                   ▼
┌───────────────┐   ┌───────────────┐
│  Halyk/Epay   │   │  e-signature  │
│   (external)  │   │   (NCANode)   │
└───────────────┘   └───────────────┘
```

---

## 7. Performance Considerations

### 7.1 Overhead

| Метрика            | Без APM  | С APM             | Overhead   |
| ------------------ | -------- | ----------------- | ---------- |
| Memory per request | Baseline | +5-10 MB          | ~5%        |
| CPU per request    | Baseline | +1-2%             | Minimal    |
| Network (APM data) | 0        | ~1 KB/transaction | Minimal    |
| Latency added      | 0        | <1 ms             | Negligible |

### 7.2 Sampling Strategy

```php
// Рекомендуемые настройки sampling

// Production
'transaction_sample_rate' => 0.1,  // 10% транзакций

// Staging
'transaction_sample_rate' => 0.5,  // 50% транзакций

// Development
'transaction_sample_rate' => 1.0,  // 100% транзакций
```

### 7.3 Оптимизация

| Оптимизация         | Описание                             | Применение            |
| ------------------- | ------------------------------------ | --------------------- |
| Tail-based sampling | Сохранять только "интересные" traces | APM Server config     |
| Span filtering      | Не записывать trivial spans (<1ms)   | Agent config          |
| Batch sending       | Отправлять данные пачками            | Agent config          |
| Async transport     | Не блокировать request               | Включено по умолчанию |

---

## 8. Security Considerations

### 8.1 Sensitive Data

| Данные       | Обработка                 | Настройка              |
| ------------ | ------------------------- | ---------------------- |
| Passwords    | Автоматическая фильтрация | `sanitize_field_names` |
| Tokens       | Автоматическая фильтрация | `sanitize_field_names` |
| Credit cards | Автоматическая фильтрация | `sanitize_field_names` |
| IIN          | Добавить в фильтр         | Кастомная настройка    |
| Email        | Маскировка                | `setUserContext`       |
| Request body | Не записывается           | По умолчанию           |

### 8.2 Network Security

```yaml
# APM Server должен быть доступен только внутри кластера
apiVersion: v1
kind: Service
metadata:
  name: apm-server
spec:
  type: ClusterIP # Не NodePort, не LoadBalancer
```

### 8.3 Authentication

```yaml
# apm-server.yml
apm-server:
  auth:
    secret_token: "${APM_SECRET_TOKEN}" # Секретный токен
```

---

## 9. Troubleshooting

### 9.1 Common Issues

| Проблема         | Симптомы                          | Решение                             |
| ---------------- | --------------------------------- | ----------------------------------- |
| Нет данных в APM | Пустой APM UI                     | Проверить connectivity к APM Server |
| Обрывы traces    | Traces не связаны между сервисами | Проверить propagation headers       |
| Высокий overhead | Увеличение latency                | Уменьшить sample rate               |
| Missing spans    | Не все операции видны             | Проверить threshold настройки       |

### 9.2 Debugging

```php
// Включить debug logging для APM agent
putenv('ELASTIC_APM_LOG_LEVEL=debug');
putenv('ELASTIC_APM_LOG_LEVEL_STDERR=debug');
```

### 9.3 Health Checks

```bash
# Проверить APM Server
curl -X GET "http://apm-server:8200/"

# Проверить APM индексы в Elasticsearch
curl -X GET "http://elasticsearch:9200/_cat/indices/apm-*?v"

# Проверить количество транзакций
curl -X GET "http://elasticsearch:9200/apm-*-transaction/_count"
```

---

## 10. Связь с существующей инфраструктурой

### 10.1 Интеграция с Sentry

Sentry продолжает использоваться для error tracking. APM дополняет его:

| Функция                | Sentry        | Elastic APM         |
| ---------------------- | ------------- | ------------------- |
| Error tracking         | Да (основной) | Да (дополнительный) |
| Stack traces           | Да            | Да                  |
| Performance monitoring | Ограничен     | Полный              |
| Distributed tracing    | Нет           | Да                  |
| Service map            | Нет           | Да                  |
| RabbitMQ tracing       | Нет           | Да                  |

### 10.2 Интеграция с Security Logging

Ключевая связь — через `request_id` / `trace.id`:

```php
// Security Logging запись
{
  "request_id": "abc123-def456",  // = trace.id из APM
  "event_type": "AUTH_LOGIN_FAILED",
  ...
}

// APM Transaction
{
  "trace.id": "abc123-def456",
  "transaction.name": "POST /api/auth/login",
  ...
}
```

Это позволяет:

1. Найти security event в Security Logging
2. Использовать `request_id` для поиска trace в APM
3. Увидеть полную картину: что произошло и как долго

### 10.3 Интеграция с существующими логами

```php
// Все логи содержат trace_id
Log::info('User logged in', [
    'user_id' => $userId,
    'trace_id' => app(ApmService::class)->getTraceId(),  // Автоматически добавляется через middleware
]);
```

---

## 11. Метрики успеха и KPIs

### 11.1 Технические метрики

| Метрика                | Baseline | Target        | Измерение                |
| ---------------------- | -------- | ------------- | ------------------------ |
| APM coverage           | 0%       | 100% services | Kibana Service Map       |
| Trace completeness     | N/A      | >95%          | Sampling verification    |
| P95 latency visibility | None     | <500ms        | APM Dashboard            |
| Error detection        | ~60%     | >99%          | APM + Sentry correlation |

### 11.2 Операционные метрики

| Метрика                   | Baseline | Target    | Измерение          |
| ------------------------- | -------- | --------- | ------------------ |
| MTTR                      | ~4 часа  | <30 мин   | Incident tracking  |
| Root cause identification | Manual   | Automated | Trace analysis     |
| Cross-service debugging   | Hours    | Minutes   | Developer feedback |

---

## 12. Timeline и Resources

### 12.1 Timeline

```
Week 1:     APM Server deployment + apm-package skeleton
Week 2:     authorization-service integration + testing
Week 3:     billing-service + explorer-service integration
Week 4:     RabbitMQ tracing + AuthRequestService integration
Week 5:     Remaining services + Frontend RUM
Week 6:     Dashboards + Alerting + Documentation
Week 7:     Production rollout + Monitoring
```

### 12.2 Resources

| Role               | Allocation | Duration |
| ------------------ | ---------- | -------- |
| DevOps Engineer    | 0.5 FTE    | 3 weeks  |
| Backend Developer  | 1 FTE      | 5 weeks  |
| Frontend Developer | 0.25 FTE   | 2 weeks  |
| QA Engineer        | 0.5 FTE    | 3 weeks  |

---

## 13. Appendix

### A. Environment Variables

```bash
# APM Agent Configuration
APM_ENABLED=true
APM_SERVER_URL=http://apm-server.monitoring.svc.cluster.local:8200
APM_SERVICE_NAME=authorization-service
APM_SERVICE_VERSION=1.0.0
APM_ENVIRONMENT=production
APM_SAMPLE_RATE=0.1
APM_SECRET_TOKEN=<secret>

# Labels
REGION=kz
CLUSTER_NAME=agr-24-prod
```

### B. Kubernetes Labels

```yaml
metadata:
  labels:
    app: authorization-service
    apm.elastic.co/service-name: authorization-service
    apm.elastic.co/service-version: "1.0.0"
```

### C. Полезные ссылки

- [Elastic APM PHP Agent](https://www.elastic.co/guide/en/apm/agent/php/current/index.html)
- [Elastic APM Server](https://www.elastic.co/guide/en/apm/server/current/index.html)
- [Distributed Tracing](https://www.elastic.co/guide/en/apm/guide/current/apm-distributed-tracing.html)
- [W3C Trace Context](https://www.w3.org/TR/trace-context/)

---

_Последнее обновление: Январь 2026_
