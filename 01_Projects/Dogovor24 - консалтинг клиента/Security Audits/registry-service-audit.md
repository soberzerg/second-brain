# Security Audit Report

## A01:2021 - Broken Access Control

### FilesController download/preview actions do not validate workspaceId parameter against file ownership (IDOR risk)

**Finding ID:** `A01-W3`

**Severity:** major

**CWE:** CWE-639

**Description:**

`FilesController::download(int $workspaceId, RegistryFile $file)` and `preview(int $workspaceId, RegistryFile $file, ...)` accept a `workspaceId` path parameter but do not verify it matches `$file->workspace_id`. Authorization is not enforced in these methods. While `RegistryFile` has a global WorkspaceScope and there are dedicated FormRequests for index/show, the download/preview routes are excluded from `WorkspaceMiddleware` and use a different route file (web routes with `auth.web`). This creates a brittle access control boundary where a misconfiguration of global scopes or route model binding could enable horizontal access to another workspace's file by guessing UUIDs.

**Attack Scenario:**

An authenticated user calls `/api/registry/workspace/{workspaceId}/files/{uuid}/download` with a UUID of a file belonging to a different workspace. Because the controller doesn't check `$file->workspace_id === $workspaceId` or current workspace, it relies on global scopes/middleware to have already constrained the model. If those are bypassed (e.g., scope excluded on these routes), the user can download another tenant's file.

**Impact:**

Cross-tenant file disclosure (horizontal privilege escalation) if scoping/middleware is bypassed or altered. Even if currently protected by global scoping, lack of explicit ownership validation makes this fragile and error-prone.

**Evidence:**

- **Location:** `routes/web.php (lines 1-60)`
  - **Chunk ID:** `file:routes/web.php`
  - **Details:** Download/preview routes are defined under `auth.web` and named `file_content`/`file_preview`.
- **Location:** `app/Http/Middleware/WorkspaceMiddleware.php (lines 1-60)`
  - **Chunk ID:** `file:app/Http/Middleware/WorkspaceMiddleware.php`
  - **Details:** `WorkspaceMiddleware` excludes `file_content` and `file_preview`, meaning global workspace scopes may not be applied for these routes.
- **Location:** `app/Http/Controllers/FilesController.php (lines 1-90)`
  - **Chunk ID:** `file:app/Http/Controllers/FilesController.php`
  - **Details:** `download(int $workspaceId, RegistryFile $file)` and `preview(int $workspaceId, RegistryFile $file, ...)` ignore `$workspaceId` and do not call authorize/ownership checks.

**Recommendation:**

Add explicit authorization/ownership checks in `download` and `preview` (e.g., abort unless `$file->workspace_id === currentWorkspaceId` and userHasAccess; or enforce policy `view`/`download` ability). Remove unused `workspaceId` param if not validated. Prefer injecting `RegistryFileServiceContract` and using middleware that consistently applies workspace scoping.

---

---

## A02:2021 - Cryptographic Failures

### Hardcoded application secrets and credentials committed in repo (K8s ConfigMap, .env.example, docker-compose) +

**Finding ID:** `A02-CRIT-001`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-798

**Description:**

Repository contains multiple hardcoded secrets/credentials (APP_KEY, RabbitMQ password, S3 access keys, file encryption key, DB passwords). If this repo is accessible to unauthorized parties (or leaked via CI artifacts/backups), attackers can directly compromise confidentiality/integrity: decrypt Laravel-encrypted data, access message broker, access S3 buckets, and potentially decrypt stored encrypted files.

**Attack Scenario:**

An attacker who gains read access to the repository (e.g., leaked VCS token, public fork, compromised CI runner artifacts) extracts APP_KEY and FILE_ENCRYPTION_KEY/S3 credentials. They can decrypt Laravel cookies/session/encrypted fields, download/modify stored files from S3, and publish/consume messages from RabbitMQ, enabling data theft and further lateral movement.

**Impact:**

Full compromise of application secrets; potential decryption of sensitive data; unauthorized access to infrastructure services (S3/RabbitMQ/DB); account/session takeover depending on usage of APP_KEY.

**Evidence:**

- **Location:** `automation/k8s/cfg/configmap-registry-service.yaml (lines 1-999)`
  - **Chunk ID:** `file:automation/k8s/cfg/configmap-registry-service.yaml`
  - **Details:** ConfigMap contains APP_KEY, RABBITMQ_PASSWORD, S3 access keys, FILE_ENCRYPTION_KEY/ALGO and other credentials in cleartext.
- **Location:** `.env.example (lines 1-999)`
  - **Chunk ID:** `file:.env.example`
  - **Details:** .env.example contains APP_KEY and multiple default passwords (DB/RabbitMQ/MinIO) and example EGOV_LOG_ENCRYPT_PASSWORD/IV values.
- **Location:** `docker-compose.yml (lines 1-120)`
  - **Chunk ID:** `file:docker-compose.yml`
  - **Details:** docker-compose.yml contains hardcoded DB credentials (POSTGRES_PASSWORD/auth_secret) and passes DB_PASSWORD into the service environment.

**Recommendation:**

Remove hardcoded secrets from version control; rotate all exposed secrets immediately; move secrets to a proper secrets manager (Kubernetes Secrets, Vault, AWS/GCP Secret Manager) and ensure they are injected at runtime only.

---

### Log encryption uses OpenSSL with static IV and no authentication (AES-CBC) +/-

**Finding ID:** `A02-MAJ-001`

**Severity:** major

**CWE:** CWE-329

**Description:**

ESEDO request/response logging uses openssl_encrypt/openssl_decrypt with configurable cipher, password, and IV. The IV is configured as a static value (env EGOV_LOG_ENCRYPT_IV). With CBC mode, IV reuse breaks semantic security and leaks patterns. Additionally, CBC provides no integrity/authentication, making ciphertext malleable (bit-flipping). There is also no explicit key derivation/length enforcement; a low-entropy “password” may be used as key material directly.

**Attack Scenario:**

An attacker with read access to encrypted logs (e.g., compromised log storage) can detect repeated plaintext blocks/prefixes due to IV reuse and potentially recover sensitive metadata. An attacker with write access can tamper with encrypted logs causing controlled plaintext changes after decryption, misleading investigations or triggering parser issues.

**Impact:**

Sensitive data exposure through pattern leakage; tampering with log contents; weakened confidentiality/integrity of logged SOAP envelopes (may include identifiers and personal data).

**Evidence:**

- **Location:** `app/Esedo/Logger.php (lines 1-120)`
  - **Chunk ID:** `file:app/Esedo/Logger.php`
  - **Details:** Uses openssl_encrypt/decrypt with algo/password/iv from config; no random IV generation; no authentication tag handling.
- **Location:** `config/egov.php (lines 1-80)`
  - **Chunk ID:** `file:config/egov.php`
  - **Details:** Config exposes egov.log.encrypt.iv via env('EGOV_LOG_ENCRYPT_IV') indicating static IV configuration.
- **Location:** `.env.example (lines 1-120)`
  - **Chunk ID:** `file:.env.example`
  - **Details:** Shows example static values for EGOV_LOG_ENCRYPT_PASSWORD and EGOV_LOG_ENCRYPT_IV.

**Recommendation:**

Use an AEAD scheme (AES-256-GCM or ChaCha20-Poly1305) with a fresh random nonce/IV per message and store nonce alongside ciphertext. Derive keys from secrets using HKDF or use a binary key. Add authentication tag verification on decrypt.

---

### Outbound HTTP to crypto/signature services lacks explicit TLS verification hardening; some endpoints default to HTTP +/-

**Finding ID:** `A02-MAJ-002`

**Severity:** major

**CWE:** CWE-523

**Description:**

The system relies on external signature/crypto services (NCANODE and e_signature_url) and uses Guzzle without explicitly pinning/setting CA bundle or verify options. Additionally, config/api.php defaults e_signature_url to plain HTTP. While Guzzle verifies TLS by default for HTTPS, leaving it implicit increases the risk of regressions (e.g., later adding verify=false) and the HTTP default enables cleartext transport of signature material and credentials in some environments.

**Attack Scenario:**

In an environment where E_SIGNATURE_BASE_URL is left as default or misconfigured to HTTP, signature requests/responses (potentially including signed XML, key references, passwords) travel unencrypted and can be intercepted/modified by a network attacker, enabling forgery or data leakage.

**Impact:**

Unprotected transport of sensitive cryptographic operations and possibly secrets; risk of MITM leading to signature validation bypass or data exposure.

**Evidence:**

- **Location:** `config/api.php (lines 1-10)`
  - **Chunk ID:** `file:config/api.php`
  - **Details:** Default e_signature_url uses 'http://139.59.132.160:14579'.
- **Location:** `app/Esedo/SoapClient.php (lines 1-120)`
  - **Chunk ID:** `file:app/Esedo/SoapClient.php`
  - **Details:** Posts to $ncanode/$function via Guzzle without explicit verify/CA settings; depends on configuration and defaults.

**Recommendation:**

Require HTTPS for all crypto/signature service endpoints; remove HTTP defaults; enforce TLS verification and consider mTLS for internal services. Add configuration validation on boot to reject non-HTTPS URLs in non-local environments.

---

### ESEDO SOAP requests and keys/passwords are forwarded to a remote staging endpoint in local mode +/-

**Finding ID:** `A02-MAJ-003`

**Severity:** major

**CWE:** CWE-201

**Description:**

In APP_ENV=local, SoapClient::\_\_doRequest forwards the raw SOAP request plus key/password/wsdl values to a remote HTTPS staging endpoint. This may unintentionally exfiltrate sensitive data and credentials from developer machines/CI environments to an external system.

**Attack Scenario:**

A developer runs the app locally with real EGOV keys/passwords. The client forwards these secrets and full request contents to a remote staging endpoint. If that endpoint is compromised or logs requests, secrets are captured and can be reused.

**Impact:**

Credential and sensitive data exposure; possibility of transport key/password compromise; impacts production integrations if same credentials are reused across environments.

**Evidence:**

- **Location:** `app/Esedo/SoapClient.php (lines 15-55)`
  - **Chunk ID:** `file:app/Esedo/SoapClient.php`
  - **Details:** In env('APP_ENV')==='local' sends 'request','location','action', and also 'key' and 'password' to a remote URL via Guzzle.

**Recommendation:**

Never transmit private keys/passwords off-host for debugging. Replace with local mock service, or ensure only dummy credentials are used in local mode. Gate this behavior behind an explicit feature flag and redact secrets.

---

## A03:2021 - Injection

### SQL Injection via dynamic JSON field name in AutocompleteController +/-

**Finding ID:** `inj-sql-001`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-89

**Description:**

SQL injection risk due to raw SQL construction with untrusted `field_name` interpolated into SQL strings. Although `search` is parameterized, `field_name` is not bound and is inserted into `selectRaw` and `whereRaw` strings.

**Attack Scenario:**

An attacker calls the autocomplete endpoint and sets `field_name` to a crafted value that breaks out of the SQL string context (because it is injected directly into `selectRaw()` and `whereRaw()`), e.g. `field_name=title' FROM cards; --` or uses JSON/SQL operators to change the query. This can lead to SQL injection in PostgreSQL, potentially allowing reading/modifying data depending on DB privileges.

**Impact:**

Potential database compromise (data exfiltration/modification), authentication bypass in downstream logic, and service disruption depending on query and privileges.

**Evidence:**

- **Location:** `app/Http/Controllers/AutocompleteController.php (lines 1-26)`
  - **Chunk ID:** `file:app/Http/Controllers/AutocompleteController.php`
  - **Details:** `selectRaw("DISTINCT fields->>'$fieldName' ...")` and `whereRaw("fields->>'$fieldName' IS NOT NULL")` interpolate `$fieldName` directly into SQL.

**Recommendation:**

Never interpolate user input into SQL identifiers/expressions. Validate `field_name` against a strict allowlist of known JSON field keys (from template definitions), or map allowed API field names to safe SQL expressions. Build JSON selectors using parameter binding where possible (e.g., `fields->>?` in PostgreSQL) and avoid `selectRaw`/`whereRaw` with concatenation.

---

## A04:2021 - Insecure Design

### SOAP server endpoint accepts messages without WS-Security validation (fail-open design) +/-

**Finding ID:** `A04-W3`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-840

**Description:**

The SOAP server explicitly implements a `Security()` handler that does nothing (“pretend we understood wsse:Security”), indicating a fail-open approach to message-level authentication/authorization. The processing logic then routes and executes state/document/file operations based on incoming payload content. This is an insecure design because it implies trust in unauthenticated messages unless compensated by external network controls (not shown in code).

**Attack Scenario:**

An attacker who can reach the SOAP endpoint submits crafted SOAP messages for ESEDO_UNIVERSAL_SERVICE or EDS_TEMP_FILES, triggering internal state transitions, document receipt flows, or file operations. Because WS-Security is not validated, attacker can spoof the sender and inject unauthorized workflow events.

**Impact:**

Unauthorized state transitions, data integrity compromise (fake inbound documents/statuses), and potential data exfiltration or storage abuse via file operations.

**Evidence:**

- **Location:** `app/Esedo/SoapServer.php (lines 1-120)`
  - **Chunk ID:** `file:app/Esedo/SoapServer.php`
  - **Details:** Security($data) method intentionally does nothing; SendMessage proceeds with request handling.

**Recommendation:**

Implement strict message authentication for SOAP: validate WS-Security signatures/timestamps and expected certificates, enforce allowlists of service IDs, and add replay protection and request size limits. If this endpoint must be publicly reachable, add additional network-layer controls (mTLS, IP allowlist) and robust auditing.

---

### Critical document workflow endpoints frequently authorize() == true at request layer (missing explicit business access validation) +/-

**Finding ID:** `A04-W4`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-841

**Description:**

Multiple FormRequest classes for critical ESEDO workflow steps (get-data-to-approve/review/register/send, approve/review/register/send, draft, etc.) return `authorize(): true`. This design relies on other layers (route middleware/policies) for access control, but the controller itself does not call `$this->authorize()`/`authorizeResource()` and the request objects do not enforce user/workspace access. This creates a brittle security design: a routing/middleware misconfiguration can expose critical operations without any defense-in-depth checks at the request/service boundary.

**Attack Scenario:**

A misconfigured route group or middleware bypass allows authenticated-but-unauthorized users (or system-to-system callers) to call ESEDO actions on arbitrary Card IDs. Since requests authorize universally, the endpoint may execute approve/register/send actions, effectively bypassing intended workflow permissions.

**Impact:**

Unauthorized document approvals/sends/registrations; business process manipulation; legal/compliance impact due to forged workflow actions.

**Evidence:**

- **Location:** `app/Http/Controllers/EsedoController.php`
  - **Chunk ID:** `file:app/Http/Controllers/EsedoController.php`
  - **Details:** Critical workflow methods approve/review/register/send/etc. execute service calls without explicit controller authorization calls.
- **Location:** `app/Http/Requests/Esedo/GetDataToApproveRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/Esedo/GetDataToApproveRequest.php`
  - **Details:** authorize() returns true for a sensitive workflow data-prep step.
- **Location:** `app/Http/Requests/Esedo/GetDataToRegisterRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/Esedo/GetDataToRegisterRequest.php`
  - **Details:** authorize() returns true; rules empty; relies on other layers.
- **Location:** `app/Http/Requests/Esedo/GetDataToSendRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/Esedo/GetDataToSendRequest.php`
  - **Details:** authorize() returns true for send preparation endpoint.
- **Location:** `app/Http/Requests/Esedo/DraftRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/Esedo/DraftRequest.php`
  - **Details:** authorize() returns true for draft action request.

**Recommendation:**

Add defense-in-depth authorization: enforce per-card/workspace permissions in FormRequest authorize() (using WorkspaceContract/user abilities) and/or call `$this->authorize()` in controller methods. For workflow actions, also validate state transitions (only allow action when card is in expected prior state) and make actions idempotent.

---

### Security event logging is inconsistent for critical workflows (insufficient monitoring/audit design) +

**Finding ID:** `A04-W5`

**Severity:** major

**CWE:** CWE-778

**Description:**

Critical operations (document workflow transitions in EsedoController, file upload endpoints) do not consistently produce structured security/audit logs. There is a single `logger('registerEsedoRequestData', $request->all())` call, but it is not a security log pattern, and may log sensitive payloads without a clear audit strategy. Without consistent audit events (who did what, on which resource, from which IP), detecting abuse and supporting investigations is difficult.

**Attack Scenario:**

An insider or attacker performs unauthorized or suspicious workflow actions (approve/send/reject) or abuses uploads. Without audit trails and alerts, the activity goes undetected and forensic reconstruction is incomplete.

**Impact:**

Delayed detection, inability to investigate incidents, and compliance/audit gaps for business-critical document workflows.

**Evidence:**

- **Location:** `app/Http/Controllers/EsedoController.php`
  - **Chunk ID:** `file:app/Http/Controllers/EsedoController.php`
  - **Details:** Only ad-hoc `logger('registerEsedoRequestData', ...)` is present; other actions have no audit logs.
- **Location:** `app/Http/Requests/StoreRegistryFileRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/StoreRegistryFileRequest.php`
  - **Details:** Logs only on exception via Log::error; no success/failure audit events for uploads.
- **Location:** `app/Http/Controllers/StagingController.php`
  - **Chunk ID:** `file:app/Http/Controllers/StagingController.php`
  - **Details:** No logging/monitoring around upload or SOAP proxy calls.

**Recommendation:**

Design an audit logging strategy: for each critical workflow transition and file operation, emit structured logs (userId/workspaceId/cardId/action/result/ip/user-agent/correlationId). Centralize via an AuditService and send to SIEM. Avoid logging full signatures or sensitive document content.

---

### Download/preview file endpoints instantiate service directly (bypassing DI/policies; brittle security design) +/-

**Finding ID:** `A04-W7`

**Severity:** major

**CWE:** CWE-693

**Description:**

FilesController uses DI for `store()` but for `download()` and `preview()` it directly instantiates `new RegistryFileService()` rather than using the injected contract or a controller-level authorization guard. This design increases the risk that cross-cutting concerns (authorization, logging, throttling, content disposition controls) implemented in a decorated service or middleware are bypassed unintentionally.

**Attack Scenario:**

A future change adds authorization checks/logging into the DI-bound RegistryFileServiceContract implementation, but download/preview keep using a raw instance and therefore bypass checks. Attackers may then access or preview files without intended controls.

**Impact:**

Potential unauthorized file access (IDOR-like outcomes) and missing audit logs for downloads/previews.

**Evidence:**

- **Location:** `app/Http/Controllers/FilesController.php`
  - **Chunk ID:** `file:app/Http/Controllers/FilesController.php`
  - **Details:** download() and preview() use `return (new RegistryFileService())->...` instead of injected contract/service.

**Recommendation:**

Use consistent dependency injection for all file operations and enforce authorization (policy/voter) for view/download/preview at controller boundary. Add download rate limits and response size safeguards for previews.

---

## A05:2021 - Security Misconfiguration

### Debug mode enabled in staging/local deployments (APP_DEBUG=true) +

**Finding ID:** `A05-MISCONF-001`

**Severity:** major

**CWE:** CWE-489

**Description:**

Multiple deployment artifacts set Laravel's APP_DEBUG to true. In Laravel, debug mode renders detailed exception pages/JSON including stack traces, environment info, file paths and can reveal sensitive configuration context, increasing the blast radius of otherwise minor errors.

**Attack Scenario:**

An attacker triggers an unhandled exception (e.g., by sending malformed payloads to an API endpoint). With APP_DEBUG=true, the response includes stack trace and full file paths, framework versions, and possibly snippets of configuration. This information is then used to tailor further exploitation (target known vulnerable packages/versions, identify internal services/hosts, discover secrets in error context).

**Impact:**

Information disclosure (paths, code structure, versions), easier exploitation and recon; in some cases may leak credentials/tokens included in exception context.

**Evidence:**

- **Location:** `.env.example (lines 1-5)`
  - **Chunk ID:** `file:.env.example`
  - **Details:** Example environment file enables debug mode: APP_DEBUG=true.
- **Location:** `automation/k8s/cfg/configmap-registry-service.yaml (lines 1-20)`
  - **Chunk ID:** `file:automation/k8s/cfg/configmap-registry-service.yaml`
  - **Details:** Kubernetes ConfigMap sets APP_ENV=staging and APP_DEBUG="true".
- **Location:** `docker-compose.yml (lines 1-35)`
  - **Chunk ID:** `file:docker-compose.yml`
  - **Details:** docker-compose sets APP_ENV: stage and APP_DEBUG: "true" for the registry service.
- **Location:** `config/app.php (lines 20-55)`
  - **Chunk ID:** `file:config/app.php`
  - **Details:** Application debug flag is driven by env('APP_DEBUG', false), so enabling APP_DEBUG directly affects error verbosity.

**Recommendation:**

Ensure APP_DEBUG is false for any non-development environment (staging/prod). Enforce via CI/CD policy and Kubernetes manifests; validate at startup and fail fast if APP_ENV != local and APP_DEBUG=true.

---

### Hardcoded secrets and credentials committed in deployment/config templates +

**Finding ID:** `A05-MISCONF-002`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-260

**Description:**

Repository contains hardcoded credentials/secrets in configuration artifacts, including database password, RabbitMQ credentials, S3 access keys, Sentry DSN, and a static APP_KEY value in templates/manifests. Even if intended for staging, committing secrets makes them broadly accessible to anyone with repo access and encourages reuse across environments.

**Attack Scenario:**

An attacker obtains read access to the repository (leaked CI logs, exposed VCS, compromised developer account). They use the committed credentials (e.g., S3 keys or RabbitMQ password) to access message queues, stored documents, or internal services, potentially exfiltrating sensitive data or injecting malicious jobs/messages.

**Impact:**

Credential compromise leading to data exfiltration, unauthorized access to infrastructure services (DB/queue/object storage), lateral movement, and potential full environment compromise.

**Evidence:**

- **Location:** `automation/k8s/cfg/configmap-registry-service.yaml (lines 1-80)`
  - **Chunk ID:** `file:automation/k8s/cfg/configmap-registry-service.yaml`
  - **Details:** ConfigMap includes DB_PASSWORD, RABBITMQ_PASSWORD, S3 access key/secret, Sentry DSN, FILE_ENCRYPTION_KEY, and a fixed APP_KEY value.
- **Location:** `docker-compose.yml (lines 1-30)`
  - **Chunk ID:** `file:docker-compose.yml`
  - **Details:** docker-compose includes POSTGRES_PASSWORD and app DB_PASSWORD as 'auth_secret'.
- **Location:** `.env.example (lines 1-80)`
  - **Chunk ID:** `file:.env.example`
  - **Details:** .env.example includes DB_PASSWORD, RabbitMQ default credentials (admin/password), and MinIO default credentials (minio/minio123) plus a fixed APP_KEY base64 value.

**Recommendation:**

Remove all secrets from the repository. Use a secrets manager (Kubernetes Secrets/ExternalSecrets/Vault/SOPS) and inject at runtime. Rotate any exposed credentials immediately (DB, RabbitMQ, S3, APP_KEY). Add secret-scanning in CI to prevent reintroduction.

---

### Overly permissive file permissions in container build (chmod 0777 on storage and cache) +

**Finding ID:** `A05-MISCONF-003`

**Severity:** major

**CWE:** CWE-276

**Description:**

The Dockerfile sets world-writable permissions (0777) recursively on Laravel storage and bootstrap/cache directories. This is unnecessarily permissive and increases the risk of file tampering if an attacker gains any code execution within the container, or if multiple users/processes share the filesystem.

**Attack Scenario:**

If an attacker gains the ability to write files as an unprivileged process inside the container (via SSRF-to-RCE chain, compromised worker, or malicious dependency), world-writable directories allow them to modify cached configuration/routes/views or write arbitrary files in storage that may later be executed or served, enabling persistence or privilege escalation within the app context.

**Impact:**

Tampering/persistence within container; potential code execution via poisoned cache files; risk increases in shared hosting or multi-process scenarios.

**Evidence:**

- **Location:** `Dockerfile (lines 55-120)`
  - **Chunk ID:** `file:Dockerfile`
  - **Details:** Dockerfile applies chmod -Rf 0777 to /var/www/registry-service/storage and /var/www/registry-service/bootstrap/cache (also chmod 777 later).

**Recommendation:**

Use least-privilege permissions (typically 0750/0755 directories; 0640/0644 files) with correct ownership (www-data). Prefer setting writable directories explicitly rather than recursive 0777; consider using a dedicated group and umask. Ensure only necessary paths are writable.

---

### PHP-FPM status and ping endpoints exposed by Nginx config +

**Finding ID:** `A05-MISCONF-004`

**Severity:** major

**CWE:** CWE-16

**Description:**

Nginx configuration exposes PHP-FPM status and ping endpoints at /status and /ping. These endpoints can leak operational information (pool status, request metrics) and are commonly used for reconnaissance. No access control is shown in the server block.

**Attack Scenario:**

An attacker probes /status or /ping on the service. If accessible externally, they learn PHP-FPM pool information (active processes, requests, potentially script names depending on config), aiding capacity-based DoS planning or discovery of internal behaviors.

**Impact:**

Information disclosure and improved attacker reconnaissance; potential to assist DoS.

**Evidence:**

- **Location:** `build/auth.conf (lines 1-40)`
  - **Chunk ID:** `file:build/auth.conf`
  - **Details:** Nginx location exposes ^/(status|ping)$ forwarding to php-fpm without access restrictions.
- **Location:** `build/entrypoint.sh (lines 1-30)`
  - **Chunk ID:** `file:build/entrypoint.sh`
  - **Details:** Entrypoint explicitly configures pm.status_path=/status and ping.path=/ping in php-fpm pool config.

**Recommendation:**

Restrict /status and /ping to localhost or trusted monitoring IPs (allow/deny), or disable entirely in production. Consider separate listener/port for metrics endpoints not exposed publicly.

---

### Missing common security headers (CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy) +

**Finding ID:** `A05-MISCONF-005`

**Severity:** major

**CWE:** CWE-16

**Description:**

No configuration was found that sets standard browser security headers at the application or Nginx layer. Current Nginx configs only add X-Real-IP and disable server_tokens. Missing headers increase exposure to clickjacking, MIME sniffing, and reduce defense-in-depth against XSS.

**Attack Scenario:**

An attacker frames the site (clickjacking) due to missing X-Frame-Options/frame-ancestors, or leverages MIME sniffing if content types are misconfigured. Without CSP, successful injection bugs have higher impact and fewer client-side mitigations.

**Impact:**

Reduced browser-side protections; increased likelihood/impact of XSS and clickjacking; weaker transport security posture without HSTS.

**Evidence:**

- **Location:** `build/auth.conf (lines 1-25)`
  - **Chunk ID:** `file:build/auth.conf`
  - **Details:** Nginx server block includes only 'add_header X-Real-IP' and no security headers.
- **Location:** `build-local/nginx/service.conf (lines 1-20)`
  - **Chunk ID:** `file:build-local/nginx/service.conf`
  - **Details:** Local Nginx server block includes only 'add_header X-Real-IP' and no security headers.
- **Location:** `app/Http/Kernel.php (lines 1-60)`
  - **Chunk ID:** `file:app/Http/Kernel.php`
  - **Details:** Kernel registers CORS and metrics middleware but no explicit security-headers middleware.

**Recommendation:**

Add a baseline header set in Nginx (or Laravel middleware) including: Strict-Transport-Security (if HTTPS), Content-Security-Policy (tailored), X-Frame-Options or frame-ancestors in CSP, X-Content-Type-Options: nosniff, Referrer-Policy, Permissions-Policy. Validate via automated security header tests.

---

### Use of outdated runtime and dependencies (PHP 7.2, Laravel 5.7, Composer 1) +

**Finding ID:** `A05-MISCONF-006`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-937

**Description:**

The project targets legacy, end-of-life components: PHP ^7.2, Laravel/framework ^5.7, and Composer self-update 1.10.16 in the Dockerfile. EOL components stop receiving security updates and commonly have known vulnerabilities; this is a misconfiguration/maintenance issue that materially increases risk.

**Attack Scenario:**

An attacker leverages a publicly known vulnerability in an outdated framework or dependency chain. Because the runtime is EOL, patches are unavailable or not applied, making exploitation easier and more reliable.

**Impact:**

Higher likelihood of compromise due to known vulnerabilities; inability to receive security patches; compliance issues.

**Evidence:**

- **Location:** `composer.json (lines 1-40)`
  - **Chunk ID:** `file:composer.json`
  - **Details:** composer.json requires php ^7.2 and laravel/framework ^5.7 (both EOL).
- **Location:** `Dockerfile (lines 1-20)`
  - **Chunk ID:** `file:Dockerfile`
  - **Details:** Dockerfile installs php7.2 packages and pins Composer to 1.10.16.

**Recommendation:**

Plan and execute an upgrade path: PHP to a currently supported version (e.g., 8.2/8.3), Laravel to a supported LTS, and Composer to v2. Add automated dependency vulnerability scanning (composer audit) in CI and a patch cadence.

---

---

## A06:2021 - Vulnerable and Outdated Components

### End-of-Life PHP 7.2 used (composer + Docker) +

**Finding ID:** `A06-W01`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-1104

**Description:**

The application targets PHP ^7.2 and the Docker build installs PHP 7.2 packages (php7.2-\*). PHP 7.2 is End-of-Life and no longer receives security fixes, increasing exposure to known vulnerabilities in the runtime and bundled extensions.

**Attack Scenario:**

An attacker leverages a known PHP 7.2 runtime vulnerability (or a vulnerable PHP 7.2 extension) to crash the application or execute arbitrary code. Because the runtime is EOL, the vulnerability remains unpatched in production images.

**Impact:**

Using an EOL PHP runtime can allow attackers to exploit publicly known PHP engine or extension vulnerabilities, potentially leading to remote code execution, information disclosure, or denial of service. It also blocks upgrading dependencies that require supported PHP versions.

**Evidence:**

- **Location:** `composer.json (lines 1-80)`
  - **Chunk ID:** `file:composer.json`
  - **Details:** Composer requires PHP ^7.2.
- **Location:** `Dockerfile (lines 1-120)`
  - **Chunk ID:** `file:Dockerfile`
  - **Details:** Dockerfile installs php7.2-_ packages and configures /etc/php/7.2/fpm/_.

**Recommendation:**

Upgrade the runtime to a supported PHP version (>=8.1, ideally 8.2+) and update composer constraints accordingly. Rebuild and redeploy images after upgrading.

---

### Outdated/EOL Laravel 5.x framework locked (laravel/framework v5.8.38) +

**Finding ID:** `A06-W02`

**Severity:** major

**CWE:** CWE-937

**Description:**

The project depends on Laravel 5.x (composer.json allows ^5.7) and composer.lock locks laravel/framework to v5.8.38 (released 2020). Laravel 5.8 is past end-of-security-support, meaning framework-level security issues will not be patched in that branch.

**Attack Scenario:**

An attacker exploits a known Laravel 5.8 vulnerability affecting request parsing or deserialization. Since the framework line is no longer supported, the application cannot receive security fixes without upgrading.

**Impact:**

Unpatched framework vulnerabilities (routing, request handling, serialization, cookie/session handling, etc.) may be exploitable, potentially enabling RCE, auth bypass, SSRF, IDOR, or data exposure depending on the specific advisory.

**Evidence:**

- **Location:** `composer.json (lines 1-80)`
  - **Chunk ID:** `file:composer.json`
  - **Details:** composer.json requires laravel/framework ^5.7.
- **Location:** `composer.lock (lines 1-260)`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** composer.lock locks laravel/framework to v5.8.38 (time 2020-04-14).

**Recommendation:**

Plan and execute a framework upgrade to a supported Laravel LTS (e.g., Laravel 10/11 depending on PHP target). Update dependent packages accordingly and run regression/security testing.

---

### Insecure/unstable dependency policy: minimum-stability=dev and multiple dev constraints +

**Finding ID:** `A06-W03`

**Severity:** major

**CWE:** CWE-937

**Description:**

composer.json sets "minimum-stability": "dev" (even with prefer-stable true). Additionally, dependencies include wildcard constraints (e.g., kalnoy/nestedset "_" and dogovor24/_ "1.x._") and composer.lock includes a dev-master package (laravel-foundation/bus dev-master) and dependencies requiring @dev (enqueue/_). This increases the chance of pulling unstable or unexpected versions and complicates vulnerability management/reproducibility.

**Attack Scenario:**

A newly tagged (or VCS) dev version introduces a security regression. A deployment update resolves to a different commit than previously tested, exposing a vulnerability in production.

**Impact:**

Unstable or moving-target dependencies can introduce regressions or vulnerabilities unexpectedly, reduce determinism between environments, and make it harder to ensure timely patched versions are used.

**Evidence:**

- **Location:** `composer.json (lines 1-140)`
  - **Chunk ID:** `file:composer.json`
  - **Details:** minimum-stability set to dev; wildcard constraints used (e.g., kalnoy/nestedset "\*").
- **Location:** `composer.lock (lines 1-420)`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** laravel-foundation/bus is locked to dev-master; enqueue packages use @dev requirements in their metadata.

**Recommendation:**

Set minimum-stability to "stable" where possible; avoid wildcard constraints; pin or use caret/tilde constraints; remove dev-master dependencies and upgrade packages to stable releases. Consider using private VCS repos with tagged releases.

---

### Known unmaintained/abandoned packages present (swiftmailer, barryvdh/laravel-cors, etc.) +/-

**Finding ID:** `A06-W04`

**Severity:** major

**CWE:** CWE-1104

**Description:**

composer.lock marks several dependencies as abandoned/unmaintained, including swiftmailer/swiftmailer (abandoned; replacement symfony/mailer), barryvdh/laravel-cors (abandoned), guzzlehttp/ringphp (abandoned), guzzlehttp/streams (abandoned), and fzaninotto/faker (abandoned). Abandoned packages are less likely to receive security fixes.

**Attack Scenario:**

A vulnerability is found in an abandoned mailer/CORS middleware library; attackers exploit it to inject headers or manipulate outbound emails. No upstream patch is available, leaving only upgrade/migration as remediation.

**Impact:**

If vulnerabilities are discovered in these libraries, fixes may not be provided. Continued use can lead to long-lived, publicly known vulnerabilities in production components (e.g., mail handling, CORS middleware, HTTP stacks).

**Evidence:**

- **Location:** `composer.lock (barryvdh/laravel-cors lines 1-520, ringphp/streams ~1900+, swiftmailer ~5950+, faker ~9210+)`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** barryvdh/laravel-cors marked abandoned=true; swiftmailer/swiftmailer marked abandoned="symfony/mailer"; guzzlehttp/ringphp and guzzlehttp/streams marked abandoned=true; fzaninotto/faker abandoned=true.

**Recommendation:**

Replace abandoned packages with maintained alternatives: migrate Swiftmailer to symfony/mailer (or Laravel Mail drivers compatible with newer Laravel), replace barryvdh/laravel-cors with fruitcake/laravel-cors or native Laravel CORS handling, and remove deprecated guzzle ring/streams usage by upgrading elasticsearch client and related dependencies.

---

### Outdated dependency with known security advisories risk: guzzlehttp/guzzle 6.5.5 (<6.5.8) -

**Finding ID:** `A06-W05`

**Severity:** major

**CWE:** CWE-1395

**Description:**

composer.lock pins guzzlehttp/guzzle to 6.5.5. Guzzle 6.5.8 includes security fixes; using versions below 6.5.8 is commonly flagged by advisories tooling. This project also uses Guzzle widely via internal packages.

**Attack Scenario:**

Attacker supplies a crafted URL/headers to an endpoint that proxies outbound requests using Guzzle. A vulnerability in older Guzzle versions allows bypassing restrictions and accessing internal metadata services.

**Impact:**

Depending on the specific advisory, vulnerable HTTP client behavior can enable SSRF bypasses, header injection, or other request-smuggling style issues, impacting downstream services and internal network access.

**Evidence:**

- **Location:** `composer.lock (lines 1-380)`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** guzzlehttp/guzzle locked to 6.5.5 (time 2020-06-16).

**Recommendation:**

Upgrade guzzlehttp/guzzle to at least 6.5.8 (or migrate to 7.x) and ensure all internal packages (dogovor24/\*) accept the newer version. Run integration tests for HTTP interactions.

---

### Supply chain risk: VCS repositories include embedded GitHub access token and SSH-based sources +

**Finding ID:** `A06-W06`

**Severity:** major

**CWE:** CWE-1395

**Description:**

composer.json defines VCS repositories, including a GitHub URL containing what appears to be an embedded access token, and multiple Bitbucket SSH URLs. Embedding long-lived tokens in dependency URLs risks credential leakage via repo exposure, logs, or build output.

**Attack Scenario:**

An attacker obtains the repository or CI logs containing the tokenized URL, uses it to access the private repo, and pushes a backdoored commit/tag. Subsequent builds install the compromised dependency.

**Impact:**

If leaked, attackers could gain read/write access to private repositories, inject malicious code into dependencies, or access other organizational resources, leading to supply-chain compromise.

**Evidence:**

- **Location:** `composer.json (lines 1-40)`
  - **Chunk ID:** `file:composer.json`
  - **Details:** VCS repository URL contains an embedded GitHub token-like string; other repos use git@bitbucket.org SSH URLs.

**Recommendation:**

Remove credentials from composer.json; use Composer auth.json/CI secret store (COMPOSER_AUTH) for tokens; enforce read-only, short-lived tokens; prefer signed tags/releases; restrict VCS access and enable dependency integrity checks and review process.

---

---

## A07:2021 - Identification and Authentication Failures

### Session cookies not encrypted at rest in session store (if file/redis compromised) +/-

**Finding ID:** `A07-006`

**Severity:** minor

**CWE:** CWE-315

**Description:**

Laravel session encryption is disabled (`encrypt` => false). If an attacker gains read access to the session storage (e.g., file session directory, Redis), session contents may be readable (though cookie is HttpOnly).

**Attack Scenario:**

An attacker with local/file-system access (or misconfigured Redis exposure) reads session storage and extracts sensitive session data.

**Impact:**

Disclosure of session-associated data; potential elevation if sensitive tokens/PII are stored in session.

**Evidence:**

- **Location:** `config/session.php`
  - **Chunk ID:** `file:config/session.php`
  - **Details:** `'encrypt' => false`.

**Recommendation:**

Consider enabling session encryption and/or ensuring session store is strongly protected (permissions, network isolation for Redis). Avoid storing sensitive secrets in sessions.

---

---

## A08:2021 - Software and Data Integrity Failures

### Insecure service call in init script (HTTP, no integrity/auth verification) +/-

**Finding ID:** `A08-W1`

**Severity:** major

**CWE:** CWE-345

**Description:**

Deployment/init script performs HTTP requests over cleartext (no TLS) and makes control-flow decisions based on the returned JSON without authenticity/integrity guarantees.

**Attack Scenario:**

An attacker (or a compromised internal network segment) can tamper with HTTP traffic between the container and Elasticsearch by intercepting/modifying the response to the unauthenticated `_count` query. By forcing the script to believe the index is missing/empty, they can trigger reindex/import operations (availability impact) or influence subsequent automation steps. If the same pattern is reused for more sensitive endpoints, it may lead to pulling/using attacker-controlled data without authenticity guarantees.

**Impact:**

Integrity/availability risk: control flow in deployment/init can be influenced by network attackers; may cause repeated reindexing, unexpected initialization behavior, or data consistency issues.

**Evidence:**

- **Location:** `build/prepare.sh`
  - **Chunk ID:** `file:build/prepare.sh`
  - **Details:** Uses `http://` and `curl $url` to query Elasticsearch `_count` and branches based on result (null/empty/0).

**Recommendation:**

Use HTTPS/TLS for service-to-service calls and verify certificates. Prefer authenticated Elasticsearch endpoints (API key/basic auth) and fail closed on unexpected responses. Consider pinning CA/cert or using internal service mesh mTLS. Validate JSON schema and enforce strict checks before acting (e.g., numeric count only).

---

### Hardcoded CI/CD secrets enable artifact tampering (supply-chain compromise) +

**Finding ID:** `A08-W2`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-798

**Description:**

CI/CD pipeline file contains hardcoded Artifactory username/password and an API key within pipeline configuration, enabling unauthorized artifact publishing and tampering if exposed.

**Attack Scenario:**

If an attacker gains access to the repository (or a developer accidentally publishes it), the hardcoded Artifactory credentials/API key can be reused to push malicious images/artifacts, overwrite existing tags (like `latest`), or pull private images. That enables supply-chain compromise: downstream deployments may run attacker-controlled code.

**Impact:**

Critical supply-chain risk: credential leakage enables publishing/tampering with Docker images and build artifacts, potentially leading to remote code execution in all environments consuming these artifacts.

**Evidence:**

- **Location:** `bitbucket-pipelines.yml`
  - **Chunk ID:** `file:bitbucket-pipelines.yml`
  - **Details:** Contains `docker login -u pipeline -p ...` and `ARTIFACTORY_PASSWORD` plus `--apikey ...` in `EXTRA_ARGS`.

**Recommendation:**

Move all secrets (Artifactory password/API key, kube config auth headers) to Bitbucket secured variables/secret storage; rotate compromised credentials; scope credentials to least privilege (publish only to specific repos/tags). Enable artifact immutability and require signed images (cosign) and signature verification at deploy time.

---

## A09:2021 - Security Logging and Monitoring Failures

### Audit trail stores full before/after card data (likely PII/sensitive fields) without redaction or retention controls +

**Finding ID:** `A09-LOG-002`

**Severity:** major

**CWE:** CWE-532

**Description:**

UpdateCardRequest writes an audit record to card_logs containing the entire model attributes before update and the entire request payload after update (including values/meta). This is an audit trail strength, but implemented in a way that can result in excessive sensitive data being stored and potentially exposed (e.g., personal data in card values, file identifiers, metadata, internal flags). It also stores the request 'values' as a JSON-encoded string inside 'after_update', mixing types and making downstream redaction harder.

**Attack Scenario:**

An attacker with read access to the database (SQLi, stolen backup, overly broad admin, compromised support account) queries card_logs and retrieves historical snapshots containing sensitive document contents or personal data. Because the log is comprehensive and unredacted, impact of data exposure is amplified.

**Impact:**

Sensitive data exposure via audit log storage; increased breach impact and compliance risk; larger blast radius if logs/backups leak.

**Evidence:**

- **Location:** `app/Http/Requests/UpdateCardRequest.php (lines 1-260)`
  - **Chunk ID:** `file:app/Http/Requests/UpdateCardRequest.php`
  - **Details:** saveUpdateToLogs() stores full $oldCard attributes and full request payload $newCard (after_update), including values/meta.
- **Location:** `app/Models/CardLog.php (lines 1-20)`
  - **Chunk ID:** `file:app/Models/CardLog.php`
  - **Details:** CardLog model defines fillable before_update/after_update JSON fields (no redaction/guards).
- **Location:** `database/migrations/2022_10_14_065206_create_card_logs_table.php (lines 1-33)`
  - **Chunk ID:** `file:database/migrations/2022_10_14_065206_create_card_logs_table.php`
  - **Details:** card_logs table stores before_update and after_update as jsonb.

**Recommendation:**

Implement field-level allowlist/redaction for before_update/after_update. Store only changed fields (diff), or exclude high-risk keys (PII, secrets, tokens, file contents). Apply retention (e.g., 30/90 days) and access controls; consider encrypting JSON fields at rest or moving to dedicated audit storage with strict permissions.

---

### Potential sensitive data leakage and log injection risk in IpMiddleware debug logging +/-

**Finding ID:** `A09-LOG-003`

**Severity:** major

**CWE:** CWE-117

**Description:**

IpMiddleware logs debug context taken directly from $\_SERVER['HTTP_X_REAL_IP'] without validation/normalization. In environments where this header can be influenced, attackers could inject unexpected content into logs (e.g., newline/control characters) or poison log-based detection. Additionally, logging raw server headers can inadvertently capture sensitive routing information in some deployments.

**Attack Scenario:**

An attacker sends crafted X-Real-IP headers containing newline characters and fake log lines. If logs are ingested into SIEM, this may confuse parsing, hide malicious activity, or trigger false alerts. Alternatively, spoofed IPs reduce usefulness of log evidence.

**Impact:**

Log integrity degradation, unreliable forensic evidence, possible downstream parser issues in centralized logging.

**Evidence:**

- **Location:** `app/Http/Middleware/IpMiddleware.php (lines 1-27)`
  - **Chunk ID:** `file:app/Http/Middleware/IpMiddleware.php`
  - **Details:** Logs Arr::only($\_SERVER,'HTTP_X_REAL_IP') at debug and enforces allowlist using $\_SERVER['HTTP_X_REAL_IP'] directly.

**Recommendation:**

Use $request->ip() with TrustProxies configured; validate IP format; sanitize log fields (strip control chars) before logging; log at info/warning only when access is denied, not every request at debug. Include correlation ID.

---

### Authorization/access-denied events not explicitly logged (403/401/CSRF bypass paths) +

**Finding ID:** `A09-LOG-004`

**Severity:** major

**CWE:** CWE-778

**Description:**

The codebase shows multiple security enforcement points returning 401/403 (SystemRequestMiddleware abort_unless, IpMiddleware abort_unless, CSRF exclusions for multiple endpoints), but no evidence of consistent logging for access-denied events or CSRF validation failures/bypasses. Denied access attempts and hits to sensitive endpoints should be logged for detection and investigation.

**Attack Scenario:**

An attacker probes internal/system-only endpoints or ESEDO endpoints from unauthorized networks. The app returns 401/403 but does not log attempts (who/where), so scanning and repeated unauthorized attempts are not visible to monitoring.

**Impact:**

Reduced detection of reconnaissance and repeated unauthorized attempts; weaker audit trail for security enforcement actions.

**Evidence:**

- **Location:** `app/Http/Middleware/IpMiddleware.php (lines 1-27)`
  - **Chunk ID:** `file:app/Http/Middleware/IpMiddleware.php`
  - **Details:** Access control via IP allowlist uses abort_unless(..., 403) without logging deny outcome.
- **Location:** `app/Http/Middleware/VerifyCsrfToken.php (lines 1-25)`
  - **Chunk ID:** `file:app/Http/Middleware/VerifyCsrfToken.php`
  - **Details:** CSRF protection excludes several API paths (including ESEDO endpoint). No logging shown for requests to these excluded routes.

**Recommendation:**

Add centralized logging for authorization failures: catch AuthorizationException/AccessDeniedHttpException and log with userId/anonymous, IP, route, method, and reason. Specifically log deny events in SystemRequestMiddleware/IpMiddleware. Review CSRF exclusions; log requests to excluded routes with strong context and consider alternate protections (HMAC signatures, mTLS).

---

### Log channel configuration likely drops informational security events (stdout level=warning) +

**Finding ID:** `A09-LOG-005`

**Severity:** minor

**CWE:** CWE-778

**Description:**

The default logging stack routes to the 'stdout' channel. The stdout handler is configured with level 'warning'. This means security-relevant events logged at info (e.g., login success, config changes) would be dropped unless logged at warning+. While this reduces noise, it can cause missing auditability if the application relies on info-level security events.

**Attack Scenario:**

Developers add login success logging at info, but in production the default channel drops it, leaving only warnings/errors. Attackers who successfully authenticate leave minimal traces.

**Impact:**

Reduced visibility/audit trail due to log level filtering in the default channel.

**Evidence:**

- **Location:** `config/logging.php (lines 1-90)`
  - **Chunk ID:** `file:config/logging.php`
  - **Details:** Default channel stack -> ['stdout']; stdout handler configured with level warning.

**Recommendation:**

Create a dedicated 'security' log channel (JSON formatter) at info level and include it in the stack; or raise stdout to info for security events only. Ensure logs are shipped to centralized storage and protected from tampering.

---

### Custom exceptions report at debug level without context (may hinder monitoring/alerting) +/-

**Finding ID:** `A09-LOG-006`

**Severity:** minor

**CWE:** CWE-223

**Description:**

DocumentNotFoundException and WorkspaceNotFoundException override report() and log only a generic debug message with no identifiers (document/workspace/user) and at a low severity level. In many deployments debug logs are suppressed, so these events may be lost; lack of context reduces forensic value.

**Attack Scenario:**

An attacker enumerates document/workspace IDs causing repeated 'not found' conditions (possible IDOR probing). Because logs are debug and context-free, the probing is not detectable or attributable.

**Impact:**

Missing/low-quality logging for potentially security-relevant resource enumeration and error conditions.

**Evidence:**

- **Location:** `app/Exceptions/DocumentNotFoundException.php (lines 1-14)`
  - **Chunk ID:** `file:app/Exceptions/DocumentNotFoundException.php`
  - **Details:** report() logs only 'Document not found.' at debug.
- **Location:** `app/Exceptions/WorkspaceNotFoundException.php (lines 1-14)`
  - **Chunk ID:** `file:app/Exceptions/WorkspaceNotFoundException.php`
  - **Details:** report() logs only 'Workspace not found.' at debug.

**Recommendation:**

Log these exceptions at info/warning with relevant safe context (requested id/cuid, user id, workspace id, route) and correlation ID. Avoid logging sensitive payloads.

---

---

## A10:2021 - Server-Side Request Forgery (SSRF)

### XML parsing uses simplexml_load_string without explicit XXE hardening (potential SSRF/XXE depending on libxml configuration) +

**Finding ID:** `SSRF-003`

**Severity:** major

**CWE:** CWE-611

**Description:**

Multiple components parse XML using `simplexml_load_string` / `DOMDocument->loadXML` without explicitly disabling external entity expansion and network access (e.g., `LIBXML_NONET`, disabling entity loader, avoiding DTD). If attacker-controlled XML is ever parsed (e.g., via file import), this can enable XXE which can be used for SSRF (fetching internal URLs) and potentially local file disclosure depending on PHP/libxml version and options.

**Attack Scenario:**

An attacker uploads or submits an XML file that includes an external entity: `<!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://169.254.169.254/latest/meta-data/">]> <root>&xxe;</root>`. When parsed by `simplexml_load_string`, the parser may attempt to resolve the external entity over the network, causing SSRF to metadata or internal services. In some configurations it can also read local files via `file:///etc/passwd`.

**Impact:**

SSRF to internal/metadata services and/or sensitive file disclosure, depending on runtime libxml settings and PHP version; potential denial of service via entity expansion.

**Evidence:**

- **Location:** `app/Imports/XmlImportParser.php (lines 1-999)`
  - **Chunk ID:** `file:app/Imports/XmlImportParser.php`
  - **Details:** Parses XML with `simplexml_load_string($content)` without safe flags/XXE protections.
- **Location:** `app/Esedo/LoggerContext.php (lines 1-999)`
  - **Chunk ID:** `file:app/Esedo/LoggerContext.php`
  - **Details:** Parses SOAP XML via `simplexml_load_string($soapMessage)`; while typically from trusted counterparties, no explicit XXE hardening is present.
- **Location:** `app/Esedo/SoapServer.php (lines 1-999)`
  - **Chunk ID:** `file:app/Esedo/SoapServer.php`
  - **Details:** Parses current request content with `simplexml_load_string` to determine request type; no explicit XXE hardening.
- **Location:** `app/Esutd/Gateway.php (lines 1-999)`
  - **Chunk ID:** `file:app/Esutd/Gateway.php`
  - **Details:** Uses `DOMDocument->loadXML($xmlString)` without `LIBXML_NONET` or explicit entity restrictions.

**Recommendation:**

Harden XML parsing: reject DTDs, use `LIBXML_NONET`, set appropriate libxml flags, and/or use safe XML parsers. For untrusted XML, consider using `XMLReader` with secure settings, or strip DOCTYPE before parsing. Add tests ensuring XXE is not possible.

---
