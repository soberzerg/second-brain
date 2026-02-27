# Security Audit Report

## A01:2021 - Broken Access Control

### Missing workspace-scoped authorization in WorkspaceUsersController::show (cross-workspace IDOR)

**Finding ID:** `W-001`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-862

**Description:**

WorkspaceUsersController::show relies on WorkspaceUsersIndexRequest::authorize(), but that authorize() does not validate that the requester can access the specific Workspace model bound in the route. It only checks global ability (`workspace-workspace-view`) or `userCanAccessSubject(read, group)` without scoping to the requested workspace. This creates a horizontal access control risk (cross-workspace data exposure).

**Attack Scenario:**

An authenticated user who has access to at least one workspace with read ability calls `GET /workspaces/{workspace}/users?filter[user_id]=<victimId>` (or without filter) for a workspace they should not access. Because authorization is not tied to the `{workspace}` route parameter and only checks generic ability to read groups somewhere, the endpoint may return membership and enriched user information (via AuthRequestService call) for users in that workspace.

**Impact:**

Unauthorized disclosure of workspace membership and user data across tenants/workspaces; enables enumeration of users and roles in other workspaces.

**Evidence:**

- **Location:** `app/Http/Controllers/WorkspaceUsersController.php (lines 1-86)`
  - **Chunk ID:** `method:App\Http\Controllers\WorkspaceUsersController::show`
  - **Details:** Uses route-bound Workspace $workspace to query WorkspaceUser and fetch user data; no explicit authorize() / policy check against $workspace.
- **Location:** `app/Http/Requests/WorkspaceUser/WorkspaceUsersIndexRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/WorkspaceUser/WorkspaceUsersIndexRequest.php`
  - **Details:** authorize() checks system request OR global ability OR generic subject access (not tied to requested workspace).

**Recommendation:**

Scope authorization to the requested Workspace: require that the user has access to that workspace (policy `view` or WorkspaceService::userCanAccessSubject for that workspace/group in that workspace). Prefer `$this->user()->can('view', $this->workspace)` in request authorize() or a controller `authorize('view', $workspace)`.

---

### Potentially unauthenticated external diagnostics endpoint ?

**Finding ID:** `W-005`

**Severity:** minor

**CWE:** CWE-284

**Description:**

External\CheckComponentsController::check appears to have no access control (no FormRequest with authorize(), no middleware visible), making it likely publicly accessible.

**Attack Scenario:**

An unauthenticated attacker (or any authenticated user) calls the external check endpoint with crafted `types` values to enumerate internal component statuses/config-driven checks, aiding reconnaissance.

**Impact:**

Information disclosure about internal components/health; can support further attacks.

**Evidence:**

- **Location:** `app/Http/Controllers/External/CheckComponentsController.php (lines 1-20)`
  - **Chunk ID:** `method:App\Http\Controllers\External\CheckComponentsController::check`
  - **Details:** No auth or ability checks before returning component check results.

**Recommendation:**

Restrict endpoint to system/admin calls via middleware/ability checks, or limit disclosed information and add rate limiting.

---

## A02:2021 - Cryptographic Failures

### Hardcoded secrets and credentials committed to repository (.env.example and Kubernetes ConfigMap)

**Finding ID:** `A02-CRIT-001`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-798

**Description:**

Repository contains numerous plaintext secrets/credentials (application encryption key, JWT secret, database password, RabbitMQ password, S3 access keys) in configuration artifacts. Even if intended for example/staging, these values frequently get reused and enable compromise if leaked. Additionally, Kubernetes ConfigMap is used for secrets (should be Secret), exposing credentials via API, etcd, logs, and anyone with read access to ConfigMaps.

**Attack Scenario:**

An attacker who gains read access to the repository, CI logs/artifacts, or cluster ConfigMaps can retrieve APP_KEY/JWT_SECRET and service credentials. With APP_KEY, attacker may decrypt Laravel-encrypted payloads (cookies, encrypted fields) and potentially forge encrypted values depending on app usage; with JWT_SECRET they can sign arbitrary JWTs; with DB/RabbitMQ/S3 creds they can exfiltrate or alter sensitive data.

**Impact:**

Full compromise of authentication/authorization tokens, decryption of protected data, unauthorized access to databases/queues/object storage, and potential lateral movement in infrastructure.

**Evidence:**

- **Location:** `.env.example (lines 1-45)`
  - **Chunk ID:** `file:.env.example`
  - **Details:** Contains APP_KEY, JWT_SECRET, DB_PASSWORD, RABBITMQ_PASSWORD, and S3_LOCAL_AWS_SECRET_ACCESS_KEY in plaintext.
- **Location:** `automation/k8s/cfg/configmap-workspace-service.yaml (lines 1-45)`
  - **Chunk ID:** `file:automation/k8s/cfg/configmap-workspace-service.yaml`
  - **Details:** Stores DB_PASSWORD, RABBITMQ_PASSWORD, S3 access/secret keys, and APP_KEY inside a ConfigMap (not Secret).

**Recommendation:**

Remove secrets from version control; rotate all exposed values; store secrets in Kubernetes Secret (or external secret manager) and inject via env vars; ensure example files contain placeholders only. Implement secret scanning in CI.

---

### Kubernetes ConfigMap used to distribute secrets (improper key management)

**Finding ID:** `A02-MAJ-001`

**Severity:** major

**CWE:** CWE-522

**Description:**

Sensitive values are placed into a Kubernetes ConfigMap. ConfigMaps are not designed for secret material and are commonly readable by broader principals than Secrets; they may also be exposed in manifests, Helm releases, backups, or logs. This is a key-management failure even if secrets are rotated periodically.

**Attack Scenario:**

A developer/support account with read access to ConfigMaps (but not Secrets) retrieves cloud storage keys and service passwords and uses them to access production-like resources. Attack can be purely insider or via compromised RBAC identity.

**Impact:**

Unauthorized access to infrastructure components and sensitive data stores; elevated blast radius via credential reuse.

**Evidence:**

- **Location:** `automation/k8s/cfg/configmap-workspace-service.yaml (lines 1-45)`
  - **Chunk ID:** `file:automation/k8s/cfg/configmap-workspace-service.yaml`
  - **Details:** ConfigMap 'workspace-service-config' includes DB_PASSWORD, RABBITMQ_PASSWORD, S3 secret key, APP_KEY.

**Recommendation:**

Move all credentials/keys to Kubernetes Secrets (or external secret manager like Vault/ExternalSecrets); tighten RBAC; enable encryption at rest for etcd; rotate credentials after migration.

---

### Sensitive configuration written to filesystem .env during container startup (risk of secret exposure)

**Finding ID:** `A02-MIN-001`

**Severity:** minor

**CWE:** CWE-532

**Description:**

Entrypoint script writes many environment variables (including DB_PASSWORD, RABBITMQ_PASSWORD, S3 secret keys, APP_KEY) into /var/www/workspace-service/.env. This increases exposure via image layers (if baked), file permissions, accidental inclusion in support bundles, debug endpoints, or container exec by attackers. It also risks leakage through backups/volume mounts.

**Attack Scenario:**

An attacker with limited container read access (e.g., SSRF->RCE chain, or compromised sidecar) reads the generated .env file and harvests credentials/keys.

**Impact:**

Credential exposure and subsequent compromise of dependent systems.

**Evidence:**

- **Location:** `build/entrypoint.sh (lines 1-60)`
  - **Chunk ID:** `file:build/entrypoint.sh`
  - **Details:** Writes DB_PASSWORD/RABBITMQ_PASSWORD/APP_KEY/S3 secrets into /var/www/workspace-service/.env using echo >>.

**Recommendation:**

Avoid writing secrets to disk; pass secrets via environment variables or mounted Secret volumes with strict permissions; ensure .env is not world-readable and is excluded from logs/debug dumps.

---

## A04:2021 - Insecure Design

### Public invitation/confirmation workflow endpoint lacks anti-automation and replay/abuse controls

**Finding ID:** `ID-A04-002`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-799

**Description:**

The workspace invitation confirmation endpoint is publicly accessible (not behind auth.api) and accepts a token to confirm invitations. While token-based confirmation is expected, there are no visible design controls for rate limiting, token TTL/expiry enforcement, single-use constraints beyond confirmed_at null check, or monitoring/auditing of repeated invalid token attempts.

**Attack Scenario:**

An attacker scripts high-volume requests with random tokens to the confirm endpoint, causing database load (token lookups, updates) and potential enumeration via response differences (404 vs 200). If tokens are weak/guessable or leaked, the attacker can confirm invitations without additional verification, accelerating unauthorized access to workspaces.

**Impact:**

DoS risk via token brute forcing; potential unauthorized invitation acceptance if tokens are compromised; weak auditability of confirmation abuse.

**Evidence:**

- **Location:** `routes/api.php (lines 1-70)`
  - **Chunk ID:** `file:routes/api.php`
  - **Details:** Route::apiResource('confirm', WorkspaceConfirmController::class)->only(['index']) is outside the auth.api middleware group (public endpoint).
- **Location:** `app/Http/Controllers/WorkspaceConfirmController.php (lines 1-46)`
  - **Chunk ID:** `file:app/Http/Controllers/WorkspaceConfirmController.php`
  - **Details:** Confirms by token and updates all related WorkspaceUser records; no rate limit, token expiry check, or logging on failures.

**Recommendation:**

Add rate limiting per IP and per token prefix, enforce token expiry (issued_at + TTL), ensure tokens are cryptographically strong and single-use, and log suspicious confirmation failures (invalid token bursts, repeated attempts). Consider additional confirmation step for sensitive workspaces (e.g., email-bound confirmation).

---

### Potentially unbounded aggregation endpoint loads all workspace users for ability appointments

**Finding ID:** `ID-A04-005`

**Severity:** major

**CWE:** CWE-770

**Description:**

WorkspaceModulesAbilitiesAppointmentService::index() performs WorkspaceUser::...->get() for a workspace and then maps each user to abilities. There is no pagination or cap, and it performs per-user ability resolution which can be expensive as membership grows.

**Attack Scenario:**

An attacker with access repeatedly queries the endpoint for a large workspace, causing heavy DB load and CPU due to per-user ability computations, potentially leading to service degradation.

**Impact:**

DoS/performance degradation; increased database load.

**Evidence:**

- **Location:** `app/Services/WorkspaceModulesAbilitiesAppointmentService.php (lines 1-22)`
  - **Chunk ID:** `file:app/Services/WorkspaceModulesAbilitiesAppointmentService.php`
  - **Details:** index() uses ->get()->map(...) with per-user ability computation; no pagination/caps.
- **Location:** `app/Http/Controllers/WorkspaceModulesAbilitiesAppointmentController.php (lines 1-33)`
  - **Chunk ID:** `file:app/Http/Controllers/WorkspaceModulesAbilitiesAppointmentController.php`
  - **Details:** Controller directly returns collection from service without pagination controls.

**Recommendation:**

Paginate/limit users processed per request, cache computed ability sets where appropriate, and consider asynchronous export for large datasets. Add rate limiting to this endpoint.

---

### Insufficient security event logging/monitoring for critical membership and permission changes

**Finding ID:** `ID-A04-006`

**Severity:** minor

**CWE:** CWE-778

**Description:**

Key workflows (invite user, confirm invitation, change group, delete workspace module) rely on DB writes and async jobs but lack explicit security/audit logging at controller/service boundaries (who changed what, from where). Some code logs errors, but not security-relevant events (invites, role/group changes, confirmation).

**Attack Scenario:**

A malicious insider or compromised account changes group memberships/abilities and later repudiates actions. Without an immutable audit trail and contextual logs (actor, target, workspace, IP), investigations and alerting are hindered.

**Impact:**

Reduced detection/response, weak non-repudiation for administrative actions, compliance/audit gaps.

**Evidence:**

- **Location:** `app/Http/Controllers/WorkspaceGroupWorkspaceUserController.php (lines 47-108)`
  - **Chunk ID:** `file:app/Http/Controllers/WorkspaceGroupWorkspaceUserController.php`
  - **Details:** Creates/deletes workspace users and triggers jobs; no explicit audit logging of the action.
- **Location:** `app/Http/Controllers/WorkspaceGroupWorkspaceUserChangeGroupController.php (lines 1-41)`
  - **Chunk ID:** `file:app/Http/Controllers/WorkspaceGroupWorkspaceUserChangeGroupController.php`
  - **Details:** Changes user's group by delete+create; no explicit audit logging.
- **Location:** `app/Http/Controllers/WorkspaceConfirmController.php (lines 1-46)`
  - **Chunk ID:** `file:app/Http/Controllers/WorkspaceConfirmController.php`
  - **Details:** Confirmation by token updates records; no success/failure security logging.

**Recommendation:**

Add structured security/audit logs for membership lifecycle events (invite sent, invite confirmed, group changed, ability changed, workspace/module deletion), including actor id, target id, workspace id, request id, IP, and user agent. Forward to SIEM and create anomaly alerts.

---

---

## A05:2021 - Security Misconfiguration

### Hardcoded secrets and credentials committed to repository (example env + k8s ConfigMap)

**Finding ID:** `A05-CRIT-002`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-260

**Description:**

Sensitive values (APP_KEY, DB credentials, RabbitMQ credentials, JWT secret, S3 access keys) are present in repository-tracked configuration files. Even if some are for local/dev/staging, committing them is high risk because repositories are commonly accessible to more people/systems than runtime secrets stores, and secrets are hard to fully remove from history.

**Attack Scenario:**

A developer account or CI system with repo read access is compromised, or the repository is leaked. The attacker extracts DB/RabbitMQ/S3 credentials and application encryption keys to access infrastructure, decrypt data, forge tokens, or pivot to other services.

**Impact:**

Full compromise of confidentiality/integrity of application data and connected infrastructure (database, queues, object storage). Potential token forgery if encryption/JWT secrets are reused across environments.

**Evidence:**

- **Location:** `.env.example (lines 1-80)`
  - **Chunk ID:** `file:.env.example`
  - **Details:** Contains APP_KEY, DB_USERNAME/DB_PASSWORD, JWT_SECRET=some-secret, RabbitMQ default-ish creds (admin/password), MinIO keys (minio/minio123).
- **Location:** `automation/k8s/cfg/configmap-workspace-service.yaml (lines 1-80)`
  - **Chunk ID:** `file:automation/k8s/cfg/configmap-workspace-service.yaml`
  - **Details:** ConfigMap includes DB_PASSWORD, APP_KEY, RabbitMQ password, and S3 access/secret keys in plain text.

**Recommendation:**

Remove secrets from version control and rotate all exposed credentials immediately. Store secrets in a dedicated secret manager (Kubernetes Secrets/External Secrets/Vault) and inject via environment variables at runtime. Keep only non-secret templates (.env.example) with placeholders.

---

### Overly permissive filesystem permissions in Docker image (chmod 0777)

**Finding ID:** `A05-MAJ-001`

**Severity:** major

**CWE:** CWE-276

**Description:**

The Dockerfile applies recursive 0777 permissions to storage/ and bootstrap/cache. World-writable permissions increase the blast radius of any compromise (including SSRF/RCE in any container process) and can enable file tampering, log poisoning, or persistence.

**Attack Scenario:**

If an attacker gains limited code execution within the container (via another vulnerability), world-writable directories make it easier to plant/modify files used by the application (cached config/routes/views, session files, logs), potentially escalating impact or persisting across requests.

**Impact:**

Integrity compromise of cached files/logs/sessions; easier persistence and potential privilege escalation within the container context.

**Evidence:**

- **Location:** `Dockerfile (lines 1-120)`
  - **Chunk ID:** `file:Dockerfile`
  - **Details:** Applies chmod -Rf 0777 to /var/www/workspace-service/storage and /var/www/workspace-service/bootstrap/cache.

**Recommendation:**

Use least-privilege permissions (e.g., 0750/0770 with correct owner/group). Ensure only the web user (www-data) and necessary group can write. Prefer immutable containers; use tmpfs/volumes with correct permissions.

---

### Internal PHP-FPM status and ping endpoints exposed without access restrictions

**Finding ID:** `A05-MAJ-002`

**Severity:** major

**CWE:** CWE-16

**Description:**

Nginx configuration exposes /status and /ping routed to PHP-FPM. These endpoints are typically intended for internal monitoring and may reveal operational details (e.g., pool status, performance metrics). There is no IP allowlist/authentication in the server block.

**Attack Scenario:**

An external user accesses /status (or automated scanners find it) and obtains runtime/process metrics. This can assist attackers in tuning DoS attacks, fingerprinting versions, and inferring traffic patterns. In some configurations, status pages can expose sensitive request info.

**Impact:**

Information disclosure and increased attack surface; potential operational security risk.

**Evidence:**

- **Location:** `build/auth.conf (lines 1-40)`
  - **Chunk ID:** `file:build/auth.conf`
  - **Details:** location ~ ^/(status|ping)$ is configured and forwarded to php-fpm with no allow/deny restrictions.
- **Location:** `build/entrypoint.sh (lines 1-70)`
  - **Chunk ID:** `file:build/entrypoint.sh`
  - **Details:** Entrypoint appends pm.status_path=/status and ping.path=/ping to PHP-FPM pool config.

**Recommendation:**

Restrict /status and /ping to internal networks (allow/deny), require auth, or bind them to a separate internal-only listener/virtual host. Disable status endpoints entirely if not required.

---

### Missing common HTTP security headers in Nginx configuration

**Finding ID:** `A05-MIN-001`

**Severity:** minor

**CWE:** CWE-16

**Description:**

The Nginx server configuration sets only `server_tokens off` (good) and adds `X-Real-IP`, but does not configure common security headers such as Content-Security-Policy (CSP), Strict-Transport-Security (HSTS), X-Frame-Options, X-Content-Type-Options, Referrer-Policy, and Permissions-Policy. While some headers may be set at an upstream gateway, no evidence exists in this repo that they are applied.

**Attack Scenario:**

In a browser context, absence of headers can increase the impact of XSS (no CSP), enable clickjacking (no X-Frame-Options/frame-ancestors), allow MIME sniffing (no nosniff), and reduce transport security guarantees (no HSTS).

**Impact:**

Reduced defense-in-depth for browser-based attacks and downgrade/mitm resilience.

**Evidence:**

- **Location:** `build/auth.conf (lines 1-45)`
  - **Chunk ID:** `file:build/auth.conf`
  - **Details:** Nginx server block lacks CSP/HSTS/XFO/nosniff/Referrer-Policy headers; only adds X-Real-IP and server_tokens off.
- **Location:** `build-local/nginx/service.conf (lines 1-35)`
  - **Chunk ID:** `file:build-local/nginx/service.conf`
  - **Details:** Local Nginx config similarly lacks standard security headers.

**Recommendation:**

Set security headers at the edge (Ingress/controller) or in Nginx: CSP (at least a baseline), HSTS (if HTTPS-only), X-Frame-Options or CSP frame-ancestors, X-Content-Type-Options=nosniff, Referrer-Policy, Permissions-Policy. Ensure headers are applied consistently (including error responses) and validated with automated tests.

---

---

## A06:2021 - Vulnerable and Outdated Components

### End-of-Life PHP version requirement (PHP 7.2) in composer.json and Docker image

**Finding ID:** `A06-W-001`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-1104

**Description:**

The application targets PHP 7.2 (via composer.json constraint and Dockerfile packages). PHP 7.2 is End-of-Life and no longer receives security updates, leaving the runtime exposed to publicly known vulnerabilities in the interpreter and bundled extensions.

**Attack Scenario:**

An attacker probes the public service and exploits a known vulnerability in PHP 7.2 (or a bundled extension like php7.2-zip/gd) to gain code execution or read sensitive data. Because the runtime is EOL, fixes are not available through normal patching channels, so the exploit remains viable.

**Impact:**

High likelihood of compromise due to unpatched PHP runtime vulnerabilities; may enable RCE, memory corruption issues, or sandbox escapes depending on the PHP/Ecosystem CVEs affecting 7.2.x and its extensions.

**Evidence:**

- **Location:** `composer.json (lines 1-120)`
  - **Chunk ID:** `file:composer.json`
  - **Details:** composer.json requires PHP ^7.2
- **Location:** `Dockerfile (lines 1-120)`
  - **Chunk ID:** `file:Dockerfile`
  - **Details:** Dockerfile installs/uses PHP 7.2 packages and edits /etc/php/7.2 paths

**Recommendation:**

Upgrade the runtime to a supported PHP version (>=8.1; preferably 8.2/8.3) and update dependencies accordingly (Laravel 5.7 will likely require a framework upgrade). Also update the Docker base image and installed php7.2-\* packages.

---

### Outdated and unsupported Laravel framework version (laravel/framework 5.7.x)

**Finding ID:** `A06-W-002`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-1104

**Description:**

The project pins laravel/framework to 5.7.\* and composer.lock shows v5.7.29. Laravel 5.7 has been out of support for years; security vulnerabilities discovered after end-of-support will not be fixed, and many dependencies are correspondingly old.

**Attack Scenario:**

An attacker targets known issues affecting older Laravel/Illuminate components (e.g., request parsing, cookie/session mechanisms, debug components) and achieves authentication bypass, information disclosure, or remote code execution via gadget chains, depending on the vulnerable area.

**Impact:**

Known and future vulnerabilities in the framework (routing, request handling, session/cookie handling, deserialization, etc.) can be exploited; ecosystem upgrades are blocked, increasing overall attack surface.

**Evidence:**

- **Location:** `composer.json (lines 1-120)`
  - **Chunk ID:** `file:composer.json`
  - **Details:** composer.json requires laravel/framework 5.7.\*
- **Location:** `composer.lock (lines 1-250)`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** composer.lock locks laravel/framework to v5.7.29 (time 2020-04-14)

**Recommendation:**

Upgrade Laravel to a currently supported LTS (Laravel 10/11) via a planned migration: bump PHP requirement, update packages, refactor breaking changes, and re-lock dependencies. Maintain an upgrade cadence aligned with Laravel support windows.

---

### Insecure/unstable dependency constraints: minimum-stability=dev and dev-master dependency

**Finding ID:** `A06-W-004`

**Severity:** major

**CWE:** CWE-937

**Description:**

composer.json sets "minimum-stability": "dev" (even though prefer-stable is true), and composer.lock includes a production dependency pinned to a floating development branch (laravel-foundation/bus: dev-master). Additionally, internal packages use wildcard constraints (e.g., 1.2.\*), which can unintentionally pull in incompatible or vulnerable updates.

**Attack Scenario:**

A malicious or compromised upstream branch/tag is updated and, due to dev constraints or wildcards, is pulled into a build. The attacker’s code executes in production (supply-chain compromise).

**Impact:**

Higher chance of pulling unreviewed, unstable, or compromised code; reduced reproducibility/security posture; accidental introduction of vulnerable versions.

**Evidence:**

- **Location:** `composer.json (lines 1-120)`
  - **Chunk ID:** `file:composer.json`
  - **Details:** composer.json sets minimum-stability to dev and uses wildcard constraints like 1.2._ / 5.7._
- **Location:** `composer.lock (lines 1-260)`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** composer.lock includes laravel-foundation/bus at dev-master and enqueue/\* with @dev requirements

**Recommendation:**

Set minimum-stability to "stable" (or omit it) and avoid dev-master/@dev constraints in production. Pin internal VCS packages to immutable tags/versions or commit hashes. Replace wildcard constraints with caret/tilde ranges that reflect tested compatibility and security update strategy.

---
