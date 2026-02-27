# Security Audit Report

## A01:2021 - Broken Access Control

### Unauthenticated notification dispatch endpoint allows arbitrary email sending (public API resource) ?

**Finding ID:** `A01-W01`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-862

**Description:**

The API route for NotifyController is defined outside the authenticated route group, making it callable without the `auth.api` middleware. The corresponding FormRequest (`EventRequest`) explicitly authorizes all callers. This endpoint constructs a notification class name from user-controlled route parameters (`category`, `notification`) and dispatches it to an email address provided by the request body. This is a broken access control issue enabling unauthorized use of the notification system.

**Attack Scenario:**

An attacker calls `POST /api/notify/{category}/{notification}` with `data[email]` set to a victim address and chooses any existing notification class (validated only by `class_exists`). This can be abused to send spam/phishing emails from the service, trigger workflows, or exfiltrate information included in notification templates (if any notification embeds sensitive data based on supplied payload).

**Impact:**

Unauthorized external parties can use the system as an email relay, cause reputation damage, generate costs, and potentially trigger internal notification actions not intended for the public.

**Evidence:**

- **Location:** `routes/api.php`
  - **Chunk ID:** `file:routes/api.php`
  - **Details:** `Route::apiResource('notify/{category}/{notification}', 'NotifyController')->only(['store']);` is declared outside the `middleware => 'auth.api'` group, making it unauthenticated.
- **Location:** `app/Http/Controllers/NotifyController.php`
  - **Chunk ID:** `file:app/Http/Controllers/NotifyController.php`
  - **Details:** `store()` builds a class name from `$request->category` and `$request->notification` and sends to `$request->get('data')['email']` with no access control checks.
- **Location:** `app/Http/Requests/EventRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/EventRequest.php`
  - **Details:** `authorize()` returns true, so no authorization is enforced at request level.

**Recommendation:**

Move the `notify/{category}/{notification}` route inside the authenticated (`auth.api`) group or add explicit authorization (e.g., signed requests/HMAC, IP allowlist, system-to-system token). Additionally, restrict allowed notifications to an explicit allowlist and validate payload structure per notification type.

---

### Document request endpoint uses user-supplied user_id (IDOR-like) without ownership/authorization validation

**Finding ID:** `A01-W02`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-639

**Description:**

`DocumentRequestController@store` accepts `user_id` from the request and emits an event using that value. The `DocumentRequest` FormRequest authorizes all callers and does not bind `user_id` to the authenticated principal. While the route is within the `auth.api` group, this still enables a horizontal authorization bypass where an authenticated user can act on behalf of another user by supplying a different `user_id`.

**Attack Scenario:**

An authenticated attacker submits `POST /api/notification/document-request` with `user_id` set to another user's ID and a file. The system processes the request and triggers the corresponding notification workflow for that other user context, potentially causing misattribution, spam, or processing of attacker-controlled files under another user's identity.

**Impact:**

Unauthorized actions on behalf of other users (horizontal privilege escalation), integrity issues, potential abuse of downstream processing/notifications.

**Evidence:**

- **Location:** `routes/api.php`
  - **Chunk ID:** `file:routes/api.php`
  - **Details:** `document-request` is exposed under `/notification` with `auth.api` middleware, meaning authenticated users can call it.
- **Location:** `app/Http/Controllers/DocumentRequestController.php`
  - **Chunk ID:** `file:app/Http/Controllers/DocumentRequestController.php`
  - **Details:** Uses `$request->user_id` directly when firing `DocumentRequestEvent`.
- **Location:** `app/Http/Requests/DocumentRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/DocumentRequest.php`
  - **Details:** `authorize()` returns true; rules allow arbitrary integer `user_id`.

**Recommendation:**

Do not accept `user_id` from clients for user-scoped actions. Derive it from the authenticated context (e.g., via AuthUserService/`$request->user()->id`) and/or enforce ability checks for acting on other users. If system-to-system calls require specifying `user_id`, gate it behind a system request check and strict authentication.

---

### Webhook endpoint allows dynamic method dispatch without explicit access control validation (relies on unknown contract implementation)

**Finding ID:** `A01-W03`

**Severity:** major

**CWE:** CWE-284

**Description:**

`WebhookController@webhooks` dynamically invokes `$webhook->$method(...)` where `$method` is taken from the route. Although a route regex limits `method` to a small set, there is no visible access control in the controller, and the FormRequest contract types shown (`EventSmsRequest`, `EventEmailRequest`, etc.) all `authorize()` to true. If the only protection is the `{hash}` parameter, it must be validated inside the injected `WebhookContract` implementation; otherwise, the endpoint can be invoked by anyone.

**Attack Scenario:**

An attacker calls `/api/notification/webhook/event_sms/.../...` and submits crafted payloads to trigger internal events/notifications if hash verification is missing/weak. Even with method restriction, unauthenticated callers may be able to submit fake delivery/analytics events.

**Impact:**

Unauthorized triggering of internal webhook processing; potential spam, incorrect status updates, or workflow manipulation depending on downstream handlers.

**Evidence:**

- **Location:** `routes/api.php`
  - **Chunk ID:** `file:routes/api.php`
  - **Details:** `Route::any('notification/webhook/{method}/{source}/{hash}', 'WebhookController@webhooks')->where('method', 'event_sms|event_call|event_email|event_analytics');` is not under `auth.api` and is publicly reachable.
- **Location:** `app/Http/Controllers/WebhookController.php`
  - **Chunk ID:** `file:app/Http/Controllers/WebhookController.php`
  - **Details:** Performs `$webhook->$method($request->all())` with no explicit authorization check in controller.
- **Location:** `app/Http/Requests/Webhook/EventSmsRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/Webhook/EventSmsRequest.php`
  - **Details:** Webhook FormRequests `authorize()` return true (no request-level authorization).

**Recommendation:**

Enforce authentication/authorization at the route layer (e.g., middleware verifying HMAC signature, basic auth, or allowlisted IPs) and explicitly validate `{hash}` (constant-time comparison, rotation, per-source secrets). Avoid dynamic dispatch where possible; map allowed methods to explicit controller actions.

---

### Template management endpoints lack object-level authorization (potential IDOR) despite ability-gated requests

**Finding ID:** `A01-W05`

**Severity:** major

**CWE:** CWE-863

**Description:**

Template operations are guarded via FormRequest abilities (`notification-template-view`), but the controller actions `update(Template $template)` and `destroy(Template $template)` rely on route model binding without any per-object authorization/ownership or scope checks. If templates are meant to be tenant/workspace-scoped, any user with the broad ability may modify/delete any template by ID (horizontal access issue).

**Attack Scenario:**

A user with the `notification-template-view` ability enumerates template IDs and calls `DELETE /api/notification/templates/{id}` or `PUT /api/notification/templates/{id}` to modify or delete templates created by other teams/workspaces (if not globally shared).

**Impact:**

Unauthorized modification/deletion of templates; cross-tenant data integrity issues.

**Evidence:**

- **Location:** `routes/api.php`
  - **Chunk ID:** `file:routes/api.php`
  - **Details:** `Route::apiResource('templates', 'TemplatesController');` exposes update/destroy endpoints.
- **Location:** `app/Http/Controllers/TemplatesController.php`
  - **Chunk ID:** `file:app/Http/Controllers/TemplatesController.php`
  - **Details:** `update(UpdateTemplateRequest $request, Template $template)` and `destroy(Template $template)` do not call `$this->authorize(...)` or otherwise validate access to the specific `$template` instance.
- **Location:** `app/Http/Requests/UpdateTemplateRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/UpdateTemplateRequest.php`
  - **Details:** Authorization is ability-based only; no per-template ownership validation is performed.

**Recommendation:**

Implement object-level authorization: scope queries by tenant/workspace, use Laravel Policies (`$this->authorize('update', $template)` / `can:update,template` middleware), or validate workspace ownership in the FormRequest/controller.

---

---

## A02:2021 - Cryptographic Failures

### Hardcoded secrets and credentials committed in Kubernetes ConfigMap (.yaml)

**Finding ID:** `A02-W1`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-798

**Description:**

Kubernetes ConfigMap contains numerous high-value secrets (DB password, JWT secret, Mailgun secret, Pusher secret, S3 keys, Telegram token, OpenAI/GPT API key, etc.). ConfigMaps are not intended for secrets; they are commonly readable by any principal with configmap read permissions and are often stored in git, CI logs, and cluster state unencrypted.

**Attack Scenario:**

An attacker (or insider) with read access to the repository, CI artifacts, or Kubernetes API access to ConfigMaps can exfiltrate these credentials and: (1) mint/validate JWTs using JWT_SECRET to impersonate users/services, (2) access databases with DB_PASSWORD, (3) access object storage with S3 keys, (4) send emails/SMS/WhatsApp/Telegram messages, (5) access third-party APIs (Mailgun/OpenAI) and incur cost or data exfiltration.

**Impact:**

Full compromise of authentication tokens and backend services; data breach (DB/object storage), account takeover (JWT forgery), and abuse of third-party integrations (spam, fraud, billing impact).

**Evidence:**

- **Location:** `automation/k8s/cfg/configmap-notification-service.yaml`
  - **Chunk ID:** `file:automation/k8s/cfg/configmap-notification-service.yaml`
  - **Details:** ConfigMap includes DB_PASSWORD, APP_KEY, MAIL_PASSWORD, MAILGUN_SECRET, JWT_SECRET, PUSHER_APP_SECRET, S3 keys, TELEGRAM_TOKEN, GPT_API_KEY, etc. (secrets embedded directly in config).

**Recommendation:**

Move all secrets from ConfigMaps to Kubernetes Secrets or an external secrets manager (Vault/AWS Secrets Manager/GCP Secret Manager) with encryption-at-rest, least-privilege RBAC, and rotation. Ensure secrets are not committed to VCS; revoke/rotate all exposed credentials immediately.

---

### Hardcoded secrets and default credentials in .env.example (risk of reuse in real deployments)

**Finding ID:** `A02-W2`

**Severity:** major

**CWE:** CWE-259

**Description:**

.env.example contains concrete secret-like values and passwords (e.g., APP_KEY, DB_PASSWORD, JWT_SECRET, RabbitMQ password, MinIO secret). Even if intended as an example, these are frequently copied into real .env files during deployments, leading to shared secrets across environments and predictable credentials.

**Attack Scenario:**

A developer or operator copies .env.example into production/staging without rotating values. An attacker who gains access to the repository or knows the example defaults can authenticate to backing services (DB/RabbitMQ/MinIO) or forge application tokens where shared secrets are used.

**Impact:**

Unauthorized access to infrastructure services and token forgery if defaults are reused; lateral movement and data exposure.

**Evidence:**

- **Location:** `.env.example`
  - **Chunk ID:** `file:.env.example`
  - **Details:** Contains APP_KEY base64 value, DB_PASSWORD, JWT_SECRET=some-secret, RABBITMQ_PASSWORD=password, S3_LOCAL_AWS_SECRET_ACCESS_KEY=minio123, etc.

**Recommendation:**

Replace all example secrets with clearly non-functional placeholders (e.g., DB_PASSWORD=, JWT_SECRET=, APP_KEY=) and document secure generation steps. Add CI checks to prevent committing real secrets. Ensure production uses unique, rotated secrets per environment.

---

### Potential secret exposure via generated .env file inside container filesystem

**Finding ID:** `A02-W3`

**Severity:** minor

**CWE:** CWE-522

**Description:**

Container entrypoint writes many sensitive environment variables into /var/www/notification-service/.env at runtime. This increases the number of locations where secrets exist (filesystem as well as environment), and they may be captured in container snapshots, backups, debug shells, or accidentally exposed via misconfiguration (e.g., serving dotfiles).

**Attack Scenario:**

If an attacker gains read access to the container filesystem (via RCE, SSRF-to-file-read, misconfigured web server serving dotfiles, or container debug access), they can retrieve the .env file with all secrets. Additionally, secrets may persist in layers/snapshots depending on runtime and tooling.

**Impact:**

Broader blast radius and easier exfiltration of credentials and cryptographic keys from runtime environment.

**Evidence:**

- **Location:** `build/entrypoint.sh`
  - **Chunk ID:** `file:build/entrypoint.sh`
  - **Details:** Entrypoint echoes DB_PASSWORD, JWT_SECRET, PUSHER_APP_SECRET, MAILGUN_SECRET, TELEGRAM_TOKEN, GPT_API_KEY, S3 keys, etc. into /var/www/notification-service/.env.

**Recommendation:**

Avoid writing secrets to a plaintext .env file; prefer injecting via environment variables or mounted secret volumes (K8s Secret volumes) with strict permissions. Ensure web server denies access to dotfiles and sensitive paths. Use least-privilege file permissions if writing is unavoidable.

---

---

## A04:2021 - Insecure Design

### Unauthenticated notification dispatch endpoint enables email/SMS spam and automation abuse +/-

**Finding ID:** `A04-W1`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-306

**Description:**

The service exposes a public API endpoint that triggers arbitrary notification classes based on URL parameters. The request authorization always returns true, and the route is not protected by the authenticated API group. This is an insecure workflow design: an attacker can automate requests to send large volumes of emails (and potentially SMS/WhatsApp depending on notification class behavior) to arbitrary recipients, using the system as an open notification relay.

**Attack Scenario:**

An attacker scripts POST requests to /api/notify/User/UserRegisteredEmailNotification (or other existing notification class names) with data.email set to victim lists. This results in bulk email delivery through your infrastructure, leading to reputational damage, mail provider blacklisting, cost increase (SMS), and potential abuse of downstream systems (queues).

**Impact:**

High-volume spam relay, operational cost increase, provider blacklisting, and potential denial of service via queue backlogs; may also leak internal notification templates/behavior by probing class existence.

**Evidence:**

- **Location:** `routes/api.php`
  - **Chunk ID:** `file:routes/api.php`
  - **Details:** Public route without auth middleware: Route::apiResource('notify/{category}/{notification}', 'NotifyController')->only(['store']);
- **Location:** `app/Http/Controllers/NotifyController.php`
  - **Chunk ID:** `file:app/Http/Controllers/NotifyController.php`
  - **Details:** Builds class name from request path parameters and sends notification to arbitrary email; no auth check in controller.
- **Location:** `app/Http/Requests/EventRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/EventRequest.php`
  - **Details:** authorize() returns true; only validates email/username and checks class_exists() (does not restrict to allowlist).

**Recommendation:**

Move this endpoint behind strong authentication and authorization (service-to-service auth), restrict allowed notification types to a strict allowlist mapped from safe identifiers, and apply anti-automation controls (rate limits per IP/service key) plus security logging for notification dispatch attempts.

---

### Webhook endpoint design lacks visible authentication/verification and allows high-frequency event submission

**Finding ID:** `A04-W2`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-306

**Description:**

The webhook endpoint accepts requests at /notification/webhook/{method}/{source}/{hash} and dynamically dispatches to a method on a service resolved by route parameters. The controller itself does not verify the {hash} nor authenticate callers. The FormRequest implementations also authorize() unconditionally. Without strong verification (HMAC/signature, IP allowlist, replay protection) and rate limiting tuned for webhooks, this design risks accepting forged events and being abused for automation/DoS.

**Attack Scenario:**

An attacker calls /api/notification/webhook/event_sms/anything/anyhash with valid-looking payload repeatedly. If downstream webhook services process/store logs or trigger side effects (status updates, fallbacks), attacker can poison logs, trigger unwanted workflows, or exhaust resources by generating massive event volume.

**Impact:**

Forged webhook events, workflow manipulation (e.g., WhatsApp/SMS status changes), log/DB growth, queue overload, and service degradation.

**Evidence:**

- **Location:** `routes/api.php`
  - **Chunk ID:** `file:routes/api.php`
  - **Details:** Public webhook route: Route::any('notification/webhook/{method}/{source}/{hash}', 'WebhookController@webhooks') ...
- **Location:** `app/Http/Controllers/WebhookController.php`
  - **Chunk ID:** `file:app/Http/Controllers/WebhookController.php`
  - **Details:** Controller calls $webhook->$method($request->all()) and returns hash/result; does not validate hash or authenticate.
- **Location:** `app/Providers/AppServiceProvider.php`
  - **Chunk ID:** `file:app/Providers/AppServiceProvider.php`
  - **Details:** Dynamically resolves WebhookContract and WebhookFormRequestContract from route params; no signature validation shown in binding logic.
- **Location:** `app/Http/Requests/Webhook/EventSmsRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/Webhook/EventSmsRequest.php`
  - **Details:** authorize() returns true; only validates fields, no auth/signature checks.

**Recommendation:**

Implement webhook authentication: verify {hash} (e.g., HMAC of payload+timestamp using shared secret per source), enforce strict source allowlist, add replay protection, and apply dedicated rate limits. Ensure invalid signatures are logged with sufficient context.

---

## A07:2021 - Identification and Authentication Failures

### Unverified one-click/"magic" login link flow (token properties not visible in this service) -/+

**Finding ID:** `A07-MAJ-002`

**Severity:** major

**CWE:** CWE-640

**Description:**

The notification service constructs and emails a login link containing a hash (cabinet/login-link/{hash}) and optionally a back_url query parameter. This repository does not contain the consuming endpoint, so it is not possible to verify critical security properties of this authentication mechanism (single-use, expiry, binding to device/IP, hashing at rest, and safe back_url handling). Absent these controls, magic links are a common source of account takeover and open redirect issues.

**Attack Scenario:**

If the login-link hash is long-lived or reusable, an attacker who obtains the link from email compromise, logs, referrers, or forwarded messages can authenticate as the victim. If back_url is not validated by the consuming service, attacker can craft a link that logs the victim in then redirects them to a phishing site.

**Impact:**

Potential account takeover and/or post-authentication phishing via open redirect, depending on the implementation in the auth/cabinet service.

**Evidence:**

- **Location:** `app/Notifications/User/UserLoginLinkNotification.php (lines 1-70)`
  - **Chunk ID:** `file:app/Notifications/User/UserLoginLinkNotification.php`
  - **Details:** Builds action URL: url('cabinet/login-link/' . $this->data->hash) and appends back_url query parameter.
- **Location:** `app/Listeners/NotificationUserLoginLinkListener.php (lines 1-30)`
  - **Chunk ID:** `file:app/Listeners/NotificationUserLoginLinkListener.php`
  - **Details:** Sends UserLoginLinkNotification containing event payload with hash/back_url to user's email.
- **Location:** `resources/views/email/auth.blade.php (lines 1-7)`
  - **Chunk ID:** `file:resources/views/email/auth.blade.php`
  - **Details:** Email template includes login link with $hash in URL.

**Recommendation:**

In the service that consumes /cabinet/login-link/{hash}: enforce short expiry (e.g., 10–15 min), single-use tokens, server-side storage of a hashed token, device binding if feasible, and strict allowlist validation for back_url (or remove it). Avoid putting sensitive tokens in URLs where possible.

---

---

## A09:2021 - Security Logging and Monitoring Failures

### Potential sensitive data exposure by logging full webhook responses

**Finding ID:** `A09-LOG-MAJ-002`

**Severity:** major

**CWE:** CWE-532

**Description:**

Webhook responses are logged verbatim. Webhook endpoints and responses often contain sensitive data (tokens, identifiers, PII, status payloads). Logging the full decoded response without redaction can leak sensitive information into centralized logs, which may be accessible to broader internal audiences or third parties.

**Attack Scenario:**

A webhook target responds with sensitive data (e.g., echoes Authorization headers, includes customer data, or returns debug info). The service logs the entire response. An attacker with access to logs (or a compromised logging backend) can retrieve secrets/PII and pivot further.

**Impact:**

Information exposure via log files; potential credential/token leakage; privacy/compliance exposure.

**Evidence:**

- **Location:** `app/Services/WebHookService.php (lines 33-65)`
  - **Chunk ID:** `file:app/Services/WebHookService.php`
  - **Details:** Logs webhook response payload verbatim: `Log::info('WebHookNotification:', Arr::wrap($response));`

**Recommendation:**

Log only minimal necessary metadata (status code, endpoint host, correlation ID) and/or redact known sensitive keys (token, Authorization, email, phone, document identifiers). Prefer structured logs with an allowlist of fields.

---

### Exception message returned to client and logged with limited context for WhatsApp webhook errors

**Finding ID:** `A09-LOG-MAJ-003`

**Severity:** major

**CWE:** CWE-209

**Description:**

On WhatsApp webhook processing errors, the controller returns the raw exception message in the HTTP JSON response and logs only a subset of metadata. Returning internal exception messages can reveal implementation details and makes it easier to probe validation rules and failure states. Additionally, the log entry does not include request identifiers, source IP, signature/authorization validation outcome, or full classification of error types.

**Attack Scenario:**

An attacker sends malformed or intentionally crafted webhook payloads to enumerate validation and parsing behavior. The endpoint responds with detailed exception messages, enabling iterative probing. Simultaneously, logs lack sufficient context to correlate or investigate the requests (e.g., IP/correlation ID).

**Impact:**

Information disclosure to external callers; reduced forensic value of logs; harder detection of repeated attacks against webhook endpoint.

**Evidence:**

- **Location:** `app/Http/Controllers/WhatsAppController.php (lines 21-49)`
  - **Chunk ID:** `file:app/Http/Controllers/WhatsAppController.php`
  - **Details:** Logs error and returns exception message to client: `logger()->error('WhatsApp webhook error: ' . $exception->getMessage(), ...)` and response includes `'error' => $exception->getMessage()`.

**Recommendation:**

Return a generic error message to clients (keep HTTP status appropriate, e.g., 400/401/500) while logging detailed error server-side with safe structured context (request_id, remote_ip, typeWebhook, idMessage, validation step, exception class). Avoid echoing raw exception messages.

---

### Logging level defaults set to debug in multiple channels (risk of excessive logging in production) +/-

**Finding ID:** `A09-LOG-MIN-004`

**Severity:** minor

**CWE:** CWE-779

**Description:**

Several log channels are configured with `level` set to `debug` (including stdout and file-based channels). If used in production, this increases the likelihood of verbose logs containing sensitive operational details and makes signal-to-noise worse for security monitoring.

**Attack Scenario:**

In production, debug-level logs may include stack traces, payload fragments, or third-party library debug output. An attacker gaining access to logs can glean operational insights. Operations teams may also miss security-relevant warnings due to excessive noise.

**Impact:**

Higher chance of sensitive data appearing in logs; reduced monitoring effectiveness due to noise.

**Evidence:**

- **Location:** `config/logging.php (lines 1-78)`
  - **Chunk ID:** `file:config/logging.php`
  - **Details:** Channels `single`, `daily`, and `stdout` use `level => 'debug'`.

**Recommendation:**

Set production log level to `info` or `warning` by default and increase only temporarily during controlled troubleshooting. Use environment-specific configuration and ensure debug is disabled in production.

---

### No evidence of correlation/request IDs and structured security log context

**Finding ID:** `A09-LOG-MIN-005`

**Severity:** minor

**CWE:** CWE-223

**Description:**

Searches did not find correlation ID propagation (e.g., X-Request-Id) or consistent structured context (user_id, ip, user-agent, request_id) added to logs. Without this, correlating events across distributed services (auth, workspace, notification) is difficult.

**Attack Scenario:**

During an incident, responders need to trace a user's actions across microservices. Without a shared request ID and consistent context, linking this service's log entries to upstream/downstream calls is slow and error-prone.

**Impact:**

Slower incident response and reduced forensic quality; harder anomaly detection in SIEM.

**Evidence:**

- **Location:** `app/Http/Kernel.php`
  - **Chunk ID:** `file:app/Http/Kernel.php`
  - **Details:** HTTP kernel is present but there is no visible middleware in this codebase for request ID/correlation logging (no matches for common request-id patterns).

**Recommendation:**

Introduce middleware to generate/propagate a request ID and add it (and remote IP/user agent where relevant) into log context (Monolog processors / Laravel Log::withContext). Emit JSON logs for easier SIEM parsing.

---

## A10:2021 - Server-Side Request Forgery (SSRF)

### User-controlled webhook URL used in outbound HTTP request (SSRF)

**Finding ID:** `SSRF-001`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-918

**Description:**

Workspace-configured webhook URLs are read from workspace settings and used directly in an outbound Guzzle request without URL validation, host allowlisting, or private-IP/link-local blocking. Because workspace settings are typically user- or tenant-controlled, an attacker can point the webhook at internal services (localhost, RFC1918 ranges) or cloud metadata endpoints (e.g., 169.254.169.254) and exfiltrate responses via timing/logging or side effects.

**Attack Scenario:**

An attacker with the ability to edit workspace settings sets settings.api.file_created (or other action URL) to http://169.254.169.254/latest/meta-data/iam/security-credentials/ or http://127.0.0.1:8000/admin. When any event triggers a webhook (file_created/signed/refused/invitation), the server performs the request, allowing internal network probing and potential credential theft from cloud metadata. If redirects are followed by the HTTP client (Guzzle default depends on options), attacker can also leverage redirect chains.

**Impact:**

Server-side request forgery enabling access to internal network resources and cloud metadata; potential data exposure (CWE-200), internal service interaction, and pivoting into internal network.

**Evidence:**

- **Location:** `app/Services/WebHookService.php (lines 1-78)`
  - **Chunk ID:** `file:app/Services/WebHookService.php`
  - **Details:** Webhook URL is pulled from workspace settings and used directly in Guzzle request(). No validation/allowlist/private-IP blocking.

**Recommendation:**

Implement strict URL validation before sending webhooks: allowlist scheme (https only), enforce an allowlist of domains, block IP literals and private/reserved/link-local ranges (127.0.0.0/8, 10/8, 172.16/12, 192.168/16, 169.254/16, ::1, fc00::/7, fe80::/10), resolve DNS and re-check resolved IPs (DNS rebinding protection), and disable/limit redirects. Consider storing only webhook IDs referencing pre-approved endpoints rather than raw URLs.

---

### cURL requests disable TLS verification (MITM risk for outbound calls)

**Finding ID:** `SSRF-002`

**Severity:** major

**CWE:** CWE-295

**Description:**

Outbound cURL calls disable TLS certificate verification (CURLOPT_SSL_VERIFYPEER=0 and/or CURLOPT_SSL_VERIFYHOST=0). While not SSRF by itself, this weakens protections around outbound requests and could facilitate SSRF chaining (e.g., attacker-controlled redirect/endpoint with forged cert) and allows man-in-the-middle interception of sensitive responses.

**Attack Scenario:**

If an attacker can influence routing/DNS or is on-path, they can intercept HTTPS requests to Mailgun/SMSC endpoints and return crafted responses. In environments where webhook URLs are attacker-controlled, disabling TLS verification can allow interception even for HTTPS endpoints.

**Impact:**

Potential interception/modification of outbound traffic, exposure of credentials/tokens, and integrity compromise of external service interactions.

**Evidence:**

- **Location:** `app/Http/Controllers/External/CheckComponentsController.php (lines 1-52)`
  - **Chunk ID:** `file:app/Http/Controllers/External/CheckComponentsController.php`
  - **Details:** checkMailgun() disables SSL peer and host verification.
- **Location:** `app/Services/SMS/SmscSMSService.php (lines 1-260)`
  - **Chunk ID:** `file:app/Services/SMS/SmscSMSService.php`
  - **Details:** \_smsc_read_url() sets CURLOPT_SSL_VERIFYPEER=0 for SMSC API calls.

**Recommendation:**

Enable TLS verification: set CURLOPT_SSL_VERIFYPEER=true and CURLOPT_SSL_VERIFYHOST=2. Pin CA bundle if necessary. Ensure timeouts and redirect policies are explicitly set.

---
