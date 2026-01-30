# Руководство по безопасной разработке Dogovor24

> Практические рекомендации для команды разработки на основе результатов аудитов безопасности

## Содержание

1. [Введение](#введение)
2. [Критические правила](#критические-правила)
3. [Контроль доступа (A01)](#a01-контроль-доступа)
4. [Криптография (A02)](#a02-криптография)
5. [Инъекции (A03)](#a03-инъекции)
6. [Безопасный дизайн (A04)](#a04-безопасный-дизайн)
7. [Конфигурация (A05)](#a05-конфигурация)
8. [Зависимости (A06)](#a06-зависимости)
9. [Аутентификация (A07)](#a07-аутентификация)
10. [Целостность данных (A08)](#a08-целостность-данных)
11. [Логирование (A09)](#a09-логирование)
12. [SSRF и XXE (A10)](#a10-ssrf-и-xxe)
13. [Чеклист для Code Review](#чеклист-для-code-review)

---

## Введение

Данное руководство основано на результатах аудитов безопасности сервисов:
- authorization-service
- billing-service
- explorer-service
- notification-service
- registry-service
- workspace-service

Классификация по OWASP Top 10 2021.

### Уровни критичности

| Уровень | Описание | Действие |
|---------|----------|----------|
| 🚨 CRITICAL | Критическая уязвимость | Исправить немедленно |
| major | Серьёзная уязвимость | Исправить в текущем спринте |
| minor | Незначительная уязвимость | Запланировать исправление |

---

## Критические правила

### ❌ НИКОГДА не делайте

```php
// 1. Не храните секреты в коде/репозитории
$key = 'w9VDvenKYpdcRAfrAh0IKSmRJW1JYii4'; // ПЛОХО

// 2. Не используйте crypt() со статической солью
$encrypted = crypt($data, 'd24'); // ПЛОХО

// 3. Не вставляйте user input в SQL напрямую
$query = "SELECT * FROM files WHERE uuid IN ('" . implode("','", $uuids) . "')"; // ПЛОХО

// 4. Не парсите XML без защиты от XXE
$xml = new SimpleXMLElement($userInput); // ПЛОХО

// 5. Не доверяйте user_id из запроса
$userId = $request->user_id; // ПЛОХО для действий от имени пользователя

// 6. Не отключайте проверку TLS
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0); // ПЛОХО

// 7. Не возвращайте authorize() => true без проверок
public function authorize() { return true; } // ПЛОХО для sensitive endpoints
```

### ✅ ВСЕГДА делайте

```php
// 1. Используйте environment variables для секретов
$key = env('FILE_ENCRYPTION_KEY');

// 2. Используйте Laravel encrypt() или sodium
$encrypted = encrypt($data);

// 3. Используйте parameter binding
$files = File::whereIn('uuid', $uuids)->get();

// 4. Отключайте external entities при парсинге XML
libxml_disable_entity_loader(true);
$xml = simplexml_load_string($data, 'SimpleXMLElement', LIBXML_NONET | LIBXML_NOENT);

// 5. Получайте user_id из auth context
$userId = auth()->id();

// 6. Включайте проверку TLS
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);

// 7. Проверяйте авторизацию явно
public function authorize() {
    return $this->user()->can('view', $this->route('workspace'));
}
```

---

## A01: Контроль доступа

### Проблема: IDOR (Insecure Direct Object Reference)

**Выявлено в:** explorer-service, notification-service, registry-service, workspace-service

#### Плохой пример

```php
// UUIDFileController - файл доступен по UUID без проверки прав
public function download(File $file)
{
    return $this->fileService->download($file); // Нет проверки доступа!
}
```

#### Правильный пример

```php
public function download(File $file)
{
    // Вариант 1: Использовать scope
    $file = File::accessible()->findOrFail($file->id);

    // Вариант 2: Использовать Policy
    $this->authorize('download', $file);

    // Вариант 3: Проверить владельца/workspace
    abort_unless(
        $file->workspace_id === auth()->user()->current_workspace_id,
        403,
        'Access denied'
    );

    return $this->fileService->download($file);
}
```

### Правила для контроля доступа

1. **Всегда проверяйте ownership** - объект должен принадлежать текущему workspace/user

```php
// В FormRequest
public function authorize(): bool
{
    $workspace = $this->route('workspace');
    return $this->user()->workspaces->contains($workspace);
}
```

2. **Используйте Global Scopes для multi-tenancy**

```php
// В модели
protected static function booted()
{
    static::addGlobalScope('workspace', function ($query) {
        if ($workspaceId = WorkspaceService::getCurrentWorkspaceId()) {
            $query->where('workspace_id', $workspaceId);
        }
    });
}
```

3. **Не доверяйте user_id из request body**

```php
// ПЛОХО
$event = new DocumentRequestEvent($request->user_id, $data);

// ХОРОШО
$event = new DocumentRequestEvent(auth()->id(), $data);
```

4. **Проверяйте workspace при route model binding**

```php
public function download(int $workspaceId, RegistryFile $file)
{
    // Обязательно проверить соответствие
    abort_unless($file->workspace_id === $workspaceId, 403);

    // Или использовать scoped binding в RouteServiceProvider
}
```

---

## A02: Криптография

### Проблема: Хранение секретов в репозитории

**Выявлено во ВСЕХ сервисах**

#### Что нельзя хранить в репозитории

- APP_KEY
- JWT_SECRET
- DB_PASSWORD
- RABBITMQ_PASSWORD
- S3 credentials
- API ключи (OpenAI, Mailgun, Telegram и т.д.)
- FILE_ENCRYPTION_KEY

#### Правильное управление секретами

```yaml
# Kubernetes Secret (не ConfigMap!)
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  APP_KEY: "" # Inject from external secrets manager
  DB_PASSWORD: ""
```

```php
// .env.example - только плейсхолдеры
APP_KEY=
DB_PASSWORD=
JWT_SECRET=
```

### Проблема: Слабая криптография

```php
// ПЛОХО - crypt() со статической солью
$encrypted = crypt($workspaceId . $fileSignatureId, 'd24');

// ХОРОШО - Laravel encrypt() (AES-256-CBC)
$encrypted = encrypt(['workspace_id' => $workspaceId, 'file_signature_id' => $fileSignatureId]);

// ХОРОШО - HMAC для integrity check
$hash = hash_hmac('sha256', $data, config('app.key'));
```

### Проблема: Статический IV для шифрования

```php
// ПЛОХО - статический IV
openssl_encrypt($data, 'aes-256-cbc', $key, 0, config('egov.log.encrypt.iv'));

// ХОРОШО - случайный IV для каждого сообщения
$iv = random_bytes(16);
$encrypted = openssl_encrypt($data, 'aes-256-gcm', $key, 0, $iv, $tag);
$result = base64_encode($iv . $tag . $encrypted);
```

---

## A03: Инъекции

### SQL Injection

**Выявлено в:** explorer-service, registry-service

```php
// ПЛОХО - конкатенация в SQL
$uuids = implode("','", $request->file_uuids);
DB::select("SELECT * FROM files WHERE uuid IN ('$uuids')");

// ПЛОХО - интерполяция в selectRaw/whereRaw
$query->selectRaw("DISTINCT fields->>'$fieldName' as value");

// ХОРОШО - parameter binding
File::whereIn('uuid', $request->file_uuids)->get();

// ХОРОШО - whitelist для динамических полей
$allowedFields = ['title', 'description', 'status'];
abort_unless(in_array($fieldName, $allowedFields), 400);
$query->selectRaw("DISTINCT fields->>? as value", [$fieldName]);
```

### Валидация UUID

```php
// В FormRequest
public function rules(): array
{
    return [
        'file_uuids' => 'required|array',
        'file_uuids.*' => 'required|uuid', // Валидируем каждый элемент!
    ];
}
```

---

## A04: Безопасный дизайн

### Проблема: Публичные endpoints без аутентификации

**Выявлено в:** notification-service

```php
// ПЛОХО - уведомления без аутентификации
Route::apiResource('notify/{category}/{notification}', 'NotifyController');

// ХОРОШО - за middleware
Route::middleware('auth.api')->group(function () {
    Route::apiResource('notify/{category}/{notification}', 'NotifyController');
});

// Или системный токен для service-to-service
Route::middleware('auth.system')->group(function () {
    // ...
});
```

### Проблема: Webhook без верификации

```php
// ПЛОХО - webhook без проверки подписи
public function webhooks(Request $request, $method, $source, $hash)
{
    return $this->webhook->$method($request->all());
}

// ХОРОШО - проверка HMAC
public function webhooks(Request $request, $method, $source, $hash)
{
    $secret = config("webhooks.secrets.$source");
    $expectedHash = hash_hmac('sha256', $request->getContent(), $secret);

    abort_unless(hash_equals($expectedHash, $hash), 401, 'Invalid signature');

    return $this->webhook->$method($request->all());
}
```

### Проблема: Memory exhaustion

```php
// ПЛОХО - загрузка файла в память для проверки размера
$size = strlen(EncryptedStorageService::get($path));

// ХОРОШО - получение размера из метаданных
$size = Storage::size($path);
// или
$size = EncryptedStorageService::size($path);
```

### Проблема: FormRequest с authorize() => true

```php
// ПЛОХО
public function authorize(): bool
{
    return true; // Для критических операций это опасно!
}

// ХОРОШО - явная проверка
public function authorize(): bool
{
    // Системный запрос
    if ($this->isSystemRequest()) {
        return true;
    }

    // Проверка ability
    return $this->user()->can('esedo-approve');
}
```

---

## A05: Конфигурация

### APP_DEBUG в production

```php
// config/app.php - проверка на старте
if (app()->environment('production') && config('app.debug')) {
    throw new RuntimeException('APP_DEBUG must be false in production!');
}
```

### File permissions в Docker

```dockerfile
# ПЛОХО
RUN chmod -Rf 0777 /var/www/app/storage

# ХОРОШО
RUN chown -R www-data:www-data /var/www/app/storage \
    && chmod -R 0750 /var/www/app/storage
```

### Security headers

```nginx
# В nginx.conf
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'" always;
```

Или в Laravel middleware:

```php
// app/Http/Middleware/SecurityHeaders.php
public function handle($request, $next)
{
    $response = $next($request);

    $response->headers->set('X-Frame-Options', 'SAMEORIGIN');
    $response->headers->set('X-Content-Type-Options', 'nosniff');
    $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');

    return $response;
}
```

### PHP-FPM status endpoint

```nginx
# ПЛОХО - публичный доступ
location ~ ^/(status|ping)$ {
    fastcgi_pass php-fpm:9000;
}

# ХОРОШО - ограничение по IP
location ~ ^/(status|ping)$ {
    allow 127.0.0.1;
    allow 10.0.0.0/8;
    deny all;
    fastcgi_pass php-fpm:9000;
}
```

---

## A06: Зависимости

### Критические обновления

| Компонент | Текущая версия | Требуется | Причина |
|-----------|----------------|-----------|---------|
| PHP | 7.2 | >=8.1 | EOL, CVEs |
| Laravel | 5.7/5.8 | >=10 | EOL, security fixes |
| lcobucci/jwt | 3.4.4 | >=3.4.6 | CVE-2021-21245 |
| guzzlehttp/guzzle | 6.5.5 | >=6.5.8 | CVE-2022-31090 |
| swiftmailer | abandoned | symfony/mailer | Unmaintained |

### composer.json best practices

```json
{
    "minimum-stability": "stable",
    "prefer-stable": true,
    "require": {
        "php": "^8.1",
        "laravel/framework": "^10.0",
        "guzzlehttp/guzzle": "^7.0"
    }
}
```

### CI/CD проверка уязвимостей

```yaml
# bitbucket-pipelines.yml
- step:
    name: Security Audit
    script:
      - composer audit
      - npm audit
```

### Запрет dev-master в production

```json
// composer.json - НЕ ИСПОЛЬЗУЙТЕ
{
    "require": {
        "some/package": "dev-master"  // ПЛОХО
    }
}

// ХОРОШО - только теги
{
    "require": {
        "some/package": "^1.0"
    }
}
```

---

## A07: Аутентификация

### Magic links (one-click login)

```php
// Требования к токенам
class LoginLinkService
{
    public function generate(User $user): string
    {
        $token = Str::random(64);

        Cache::put("login_link:$token", [
            'user_id' => $user->id,
            'created_at' => now(),
        ], now()->addMinutes(15)); // Короткий TTL

        return $token;
    }

    public function verify(string $token): ?User
    {
        $data = Cache::pull("login_link:$token"); // Single-use

        if (!$data) {
            return null;
        }

        // Проверка TTL
        if (Carbon::parse($data['created_at'])->addMinutes(15)->isPast()) {
            return null;
        }

        return User::find($data['user_id']);
    }
}
```

### Валидация back_url

```php
// ПЛОХО - open redirect
$backUrl = $request->back_url;
return redirect($backUrl);

// ХОРОШО - whitelist
$allowedHosts = ['dogovor24.kz', 'dogovor24.ru'];
$parsed = parse_url($request->back_url);

if (!in_array($parsed['host'] ?? '', $allowedHosts)) {
    $backUrl = '/dashboard';
}
```

---

## A08: Целостность данных

### Deploy script

```bash
# ПЛОХО - composer update в production
composer update

# ХОРОШО - только установка из lock-файла
composer install --no-dev --optimize-autoloader --no-interaction
```

### CI/CD secrets

```yaml
# ПЛОХО - hardcoded в pipeline
docker login -u pipeline -p hardcoded_password

# ХОРОШО - secured variables
docker login -u $DOCKER_USER -p $DOCKER_PASSWORD
```

### HTTP вызовы в init scripts

```bash
# ПЛОХО - HTTP без TLS
curl http://elasticsearch:9200/_count

# ХОРОШО - HTTPS + проверка сертификата
curl --fail https://elasticsearch:9200/_count
```

---

## A09: Логирование

### Что логировать (Security Events)

```php
// app/Services/SecurityLogger.php
class SecurityLogger
{
    public static function log(string $event, array $context = []): void
    {
        Log::channel('security')->info($event, array_merge([
            'user_id' => auth()->id(),
            'workspace_id' => WorkspaceService::getCurrentWorkspaceId(),
            'ip' => request()->ip(),
            'user_agent' => request()->userAgent(),
            'request_id' => request()->header('X-Request-ID'),
            'timestamp' => now()->toIso8601String(),
        ], $context));
    }
}

// Использование
SecurityLogger::log('user.login.success', ['method' => 'password']);
SecurityLogger::log('file.download', ['file_id' => $file->id]);
SecurityLogger::log('permission.denied', ['resource' => 'file', 'action' => 'download']);
```

### Логирование ошибок авторизации

```php
// app/Exceptions/Handler.php
public function report(Throwable $e)
{
    if ($e instanceof AuthorizationException) {
        SecurityLogger::log('authorization.denied', [
            'exception' => get_class($e),
            'message' => $e->getMessage(),
            'route' => request()->route()?->getName(),
        ]);
    }

    parent::report($e);
}
```

### Чего НЕ логировать

```php
// ПЛОХО - полный payload
Log::info('Webhook response:', $response->json());

// ХОРОШО - только метаданные
Log::info('Webhook response received', [
    'status' => $response->status(),
    'correlation_id' => $correlationId,
]);
```

### Уровни логирования в production

```php
// config/logging.php
'channels' => [
    'stack' => [
        'driver' => 'stack',
        'channels' => ['daily', 'security'],
    ],
    'daily' => [
        'driver' => 'daily',
        'level' => env('LOG_LEVEL', 'warning'), // Не debug в prod!
    ],
    'security' => [
        'driver' => 'daily',
        'path' => storage_path('logs/security.log'),
        'level' => 'info', // Security events всегда логируем
    ],
],
```

### Correlation ID

```php
// app/Http/Middleware/RequestId.php
public function handle($request, $next)
{
    $requestId = $request->header('X-Request-ID') ?? Str::uuid()->toString();

    $request->headers->set('X-Request-ID', $requestId);

    Log::withContext(['request_id' => $requestId]);

    $response = $next($request);
    $response->headers->set('X-Request-ID', $requestId);

    return $response;
}
```

---

## A10: SSRF и XXE

### SSRF Prevention

```php
// ПЛОХО - user-controlled URL без валидации
$client->get($workspaceSettings['webhook_url']);

// ХОРОШО - валидация URL
class WebhookUrlValidator
{
    private array $blockedRanges = [
        '127.0.0.0/8',
        '10.0.0.0/8',
        '172.16.0.0/12',
        '192.168.0.0/16',
        '169.254.0.0/16',
    ];

    public function validate(string $url): bool
    {
        $parsed = parse_url($url);

        // Только HTTPS
        if (($parsed['scheme'] ?? '') !== 'https') {
            return false;
        }

        // Проверка IP
        $ip = gethostbyname($parsed['host']);
        foreach ($this->blockedRanges as $range) {
            if ($this->ipInRange($ip, $range)) {
                return false;
            }
        }

        return true;
    }
}
```

### XXE Prevention

```php
// ПЛОХО
$xml = new SimpleXMLElement($userInput);

// ХОРОШО - отключаем external entities
libxml_disable_entity_loader(true); // PHP < 8.0
$xml = simplexml_load_string(
    $userInput,
    'SimpleXMLElement',
    LIBXML_NONET | LIBXML_NOENT | LIBXML_DTDLOAD
);

// Для DOMDocument
$dom = new DOMDocument();
$dom->loadXML($xml, LIBXML_NONET | LIBXML_NOENT);
```

### File upload validation

```php
// FormRequest rules
public function rules(): array
{
    return [
        'file' => [
            'required',
            'file',
            'max:20480', // 20MB
            'mimes:pdf,doc,docx,xls,xlsx,png,jpg,jpeg', // Whitelist!
        ],
    ];
}
```

---

## Чеклист для Code Review

### Контроль доступа

- [ ] Есть ли проверка ownership/workspace для CRUD операций?
- [ ] Используется ли `authorize()` в FormRequest или Policy?
- [ ] user_id берётся из auth context, а не из request body?
- [ ] Route model binding ограничен scope'ом?

### Криптография

- [ ] Нет hardcoded секретов в коде?
- [ ] Используется Laravel `encrypt()` вместо `crypt()`?
- [ ] IV генерируется случайно для каждого шифрования?
- [ ] TLS включён для всех внешних вызовов?

### Инъекции

- [ ] Используется parameter binding для SQL?
- [ ] Динамические поля проверяются по whitelist?
- [ ] User input валидируется в FormRequest?
- [ ] UUID валидируются как UUID?

### Конфигурация

- [ ] APP_DEBUG=false для non-dev environments?
- [ ] Секреты в Kubernetes Secrets (не ConfigMap)?
- [ ] File permissions не 0777?
- [ ] Security headers настроены?

### Логирование

- [ ] Security events логируются?
- [ ] Чувствительные данные не попадают в логи?
- [ ] Есть correlation ID для трассировки?
- [ ] Ошибки авторизации логируются?

### Внешние вызовы

- [ ] Webhook URLs валидируются (SSRF protection)?
- [ ] XML парсится с LIBXML_NONET?
- [ ] Файлы проверяются по MIME type whitelist?
