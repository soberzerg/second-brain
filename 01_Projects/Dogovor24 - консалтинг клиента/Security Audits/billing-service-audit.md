# Security Audit Report

## A01:2021 - Broken Access Control

### Staging maintenance endpoints modify production data without authentication/authorization -/+

**Finding ID:** `A01-CRIT-001`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-862

**Description:**

Multiple staging endpoints are exposed under routes/web.php with only the `stage.env` middleware and no `auth.api` (or any explicit authorization). These endpoints perform direct database updates/deletes on billing profiles, workspaces, and user payload fields (IIN/BIN) and can corrupt or alter sensitive records. If `stage.env` is misconfigured, bypassable, or accidentally enabled in a non-staging environment, an unauthenticated attacker could trigger these actions.

**Attack Scenario:**

An attacker discovers `/api/billing/staging/clear-test-iin/{iin}` and calls it repeatedly with various values. Because no authentication is required, the attacker can force updates on `workspaces`, `billing_profile`, and `users` tables, potentially breaking tenant data integrity, detaching identifiers, or causing denial of service. Similarly, `/clear-test-bin` updates BIN references across tables.

**Impact:**

Unauthorized modification of billing identity data (IIN/BIN), workspace metadata and user payload, leading to data integrity loss, account/tenant confusion, and service disruption. In worst case, can facilitate further privilege/ownership confusion across the billing system.

**Evidence:**

- **Location:** `routes/web.php (line 1)`
  - **Chunk ID:** `file:routes/web.php`
  - **Details:** Staging routes group exposes StagingController endpoints with only `stage.env` middleware (no auth).
- **Location:** `app/Http/Controllers/Staging/StagingController.php`
  - **Chunk ID:** `class:App\Http\Controllers\Staging\StagingController`
  - **Details:** Controller methods perform direct DB updates to workspaces/billing_profile/users without any auth checks.
- **Location:** `app/Http/Controllers/Staging/StagingController.php`
  - **Chunk ID:** `method:App\Http\Controllers\Staging\StagingController::replaceTestIin`
  - **Details:** Updates workspaces and users tables based on attacker-controlled `{iin}` parameter (DB::table()->where(...)->update()).
- **Location:** `app/Http/Controllers/Staging/StagingController.php`
  - **Chunk ID:** `method:App\Http\Controllers\Staging\StagingController::replaceTestBin`
  - **Details:** Updates billing_profile and workspaces records for TEST_BIN without auth checks.
- **Location:** `app/Http/Controllers/Staging/StagingController.php`
  - **Chunk ID:** `method:App\Http\Controllers\Staging\StagingController::changeTestIin`
  - **Details:** Changes profile BIN and updates workspace/user fields based on the IIN parameter without auth checks.

**Recommendation:**

Require strong authentication and admin-only authorization for any staging/maintenance endpoints, or remove them from deployed builds. Ensure `stage.env` cannot be enabled in production and is not bypassable.

---

### File upload path uses user-controlled components; missing server-side ownership/tenant validation (possible horizontal access + path abuse) +/-

**Finding ID:** `A01-MAJ-002`

**Severity:** major

**CWE:** CWE-284

**Description:**

`FileController::store` builds a storage path using user-provided `fileable_type` and `fileable_id` (e.g., `"/{$request->fileable_type}/{$request->fileable_id}"`) and stores the uploaded file there. Although `StoreFileRequest` whitelists `fileable_type` values, there is no demonstrated authorization check that the current user owns/has access to the referenced `fileable_id` resource (tenant/ownership validation). This can enable horizontal access where a user uploads files under another tenant’s resource folder, potentially confusing downstream logic that associates files with resources. Additionally, using original filenames can cause overwrites within the same folder.

**Attack Scenario:**

A low-privileged authenticated user with `billing-files-upload` ability uploads a file with `fileable_type=BillingProfile` and `fileable_id` of another user’s billing profile. The file is stored under that other entity’s folder and a DB record is created linking to that fileable, potentially making it available to others or altering business workflows.

**Impact:**

Horizontal access control bypass (cross-tenant/resource file injection), potential data integrity issues, and possible file overwrite within a resource directory.

**Evidence:**

- **Location:** `app/Http/Controllers/FileController.php`
  - **Chunk ID:** `file:app/Http/Controllers/FileController.php`
  - **Details:** Stores file using Storage::putFileAs("/{$request->fileable_type}/{$request->fileable_id}", $file, $data['filename']).
- **Location:** `app/Http/Requests/StoreFileRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/StoreFileRequest.php`
  - **Details:** Validates fileable_type via allowlist and fileable_id as int, but does not validate ownership/access to fileable_id.
- **Location:** `routes/api.php`
  - **Chunk ID:** `file:routes/api.php`
  - **Details:** File endpoints are under `auth.api`, but ability check alone is coarse-grained and not resource-specific.

**Recommendation:**

Add ownership/tenant authorization at the controller (e.g., policies) to verify the user can attach files to the specified `fileable_type` + `fileable_id`. Avoid using user-supplied original filenames as storage names; generate random names and store original name separately. Consider canonicalizing/normalizing path components and disallowing any unexpected characters defensively, even with an allowlist.

---

## A02:2021 - Cryptographic Failures

### Legacy custom RSA signing helper contains risky/buggy error handling and unspecified algorithms -/+

**Finding ID:** `A02-CRYPTO-003`

**Severity:** minor

**CWE:** CWE-327

**Description:**

The legacy Halyk processing helper (2006) performs RSA signing/verification via OpenSSL without explicitly setting the digest algorithm and contains a logic bug in parse_errors(): `if ($this->ecode = 0)` uses assignment, not comparison, which can overwrite error state. The helper also includes a non-standard 'invert' (reverse) operation on signatures, which is unusual and can cause brittle verification/integration issues.

**Attack Scenario:**

Operationally, signature failures may be misdetected/ignored due to broken error tracking, leading to accepting invalid responses (depending on calling code). Attackers could exploit misconfiguration or error masking to cause payment status handling to malfunction or bypass checks if upstream logic treats errors as success.

**Impact:**

Integrity risk in payment message signing/verification; increased chance of mis-verifying bank responses; harder incident detection due to masked crypto errors.

**Evidence:**

- **Location:** `app/Helpers/processing/halyk/kkb.utils.php (lines 1-220)`
  - **Chunk ID:** `file:app/Helpers/processing/halyk/kkb.utils.php`
  - **Details:** Uses openssl_sign/openssl_verify without specifying algorithm; has assignment bug in parse_errors(): `if ($this->ecode = 0)`; includes invert()/reverse() on signature bytes.

**Recommendation:**

Replace/upgrade the legacy helper with a maintained library/vendor SDK. Explicitly specify modern algorithms (e.g., SHA-256 with RSA: OPENSSL_ALGO_SHA256) and fix error handling (`==`/`===`). Add strict verification behavior (fail closed) and tests.

---

---

## A04:2021 - Insecure Design

### High API pagination ceiling may enable data/resource exhaustion (max_results=5000) +/-

**Finding ID:** `A04-W03`

**Severity:** major

**CWE:** CWE-770

**Description:**

The project uses JSON API pagination (jsonPaginate) across list endpoints (accounts, files, orders, transactions, etc.), which is a good pattern, but the configured maximum page size/results is very high (5000). This creates a design-level risk of expensive queries and large responses that can degrade service availability, especially when combined with allowedIncludes and complex filters.

**Attack Scenario:**

An attacker repeatedly calls list endpoints with page[size]=5000 (or equivalent) and expensive include graphs/filters, causing heavy DB load and large payload generation. Even with general throttling, this can impact performance and availability.

**Impact:**

Increased DB and CPU utilization, slow responses for legitimate users, possible cascading timeouts and denial of service.

**Evidence:**

- **Location:** `config/json-api-paginate.php (lines 1-30)`
  - **Chunk ID:** `file:config/json-api-paginate.php`
  - **Details:** JSON API paginate configuration sets max_results to 5000, enabling very large responses per request.
- **Location:** `app/Http/Controllers/Order/OrderController.php (lines 1-110)`
  - **Chunk ID:** `file:app/Http/Controllers/Order/OrderController.php`
  - **Details:** Order index allows many includes/filters and returns jsonPaginate(); large max_results amplifies query/response cost.

**Recommendation:**

Lower max page size to a defensible value (e.g., 100–500 depending on use case), enforce upper bounds per endpoint (especially with includes), and consider separate async export jobs for large datasets instead of huge API pages.

---

### Payment callback/request workflow permits unauthenticated access with weak fail-safe behavior and limited security event logging +/-

**Finding ID:** `A04-W04`

**Severity:** major

**CWE:** CWE-841

**Description:**

The payment callback form request for card payments (`StorePaymentCard`) is authorized for everyone (`authorize() => true`) and uses `die()` codes for failure handling. While bank status is checked, the overall workflow is fail-unsafe and lacks structured security logging/monitoring for suspicious callbacks (replay/invalid attempts). This is an insecure design for a critical financial workflow because it reduces observability and may allow automated abuse attempts at scale.

**Attack Scenario:**

An attacker floods the payment callback endpoint with crafted payloads, triggering repeated bank status checks and background retry jobs (CardRetryPaymentJob) or causing noisy failures that are hard to trace due to `die()` usage and missing structured logging. Even if fraud is prevented, the system can be degraded and incident response hampered.

**Impact:**

Operational DoS against payment processing, increased third-party API calls (bank status checks), delayed order confirmations, and insufficient forensic/audit data during fraud investigations.

**Evidence:**

- **Location:** `routes/api.php (lines 1-120)`
  - **Chunk ID:** `file:routes/api.php`
  - **Details:** Payment routes under /billing/payment are not in the auth.api group; comment indicates throttling concerns are TODO.
- **Location:** `app/Http/Requests/Payment/StorePaymentCard.php (lines 1-200)`
  - **Chunk ID:** `file:app/Http/Requests/Payment/StorePaymentCard.php`
  - **Details:** authorize() returns true and multiple failure branches use die(); limited logging and monitoring hooks in this critical workflow.
- **Location:** `app/Http/Controllers/Payment/PaymentController.php (lines 1-60)`
  - **Chunk ID:** `file:app/Http/Controllers/Payment/PaymentController.php`
  - **Details:** Payment controller processes payments and may enroll to neutral balance; no explicit mention of anti-automation or security logging here.

**Recommendation:**

Harden payment callback design: require strong request authentication (HMAC signature verification / mTLS / IP allow-list where applicable), replace `die()` with proper exceptions and consistent HTTP responses, add idempotency keys and replay protection, and emit structured security/audit logs for invalid/suspicious callbacks including correlation IDs.

---

---

## A06:2021 - Vulnerable and Outdated Components

### Unmaintained/abandoned packages in use (swiftmailer, barryvdh/laravel-cors, guzzle ringphp/streams, zendframework/zend-diactoros, fzaninotto/faker, symfony/debug) +

**Finding ID:** `A06-W4`

**Severity:** major

**CWE:** CWE-1104

**Description:**

composer.lock indicates multiple packages are marked abandoned or replaced. Continuing to rely on abandoned components increases the likelihood of known vulnerabilities remaining unpatched and complicates future upgrades.

**Attack Scenario:**

A vulnerability is discovered in an abandoned library (e.g., mailer stack, HTTP stack). Attackers exploit it knowing no security patches will be released, leading to data exposure or code execution depending on the component’s role.

**Impact:**

Higher long-term security risk and upgrade blockage; potential exposure to unpatched known CVEs.

**Evidence:**

- **Location:** `composer.lock (lines 1-260)`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** swiftmailer/swiftmailer is marked abandoned (symfony/mailer).
- **Location:** `composer.lock (lines 1-200)`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** barryvdh/laravel-cors is marked abandoned.
- **Location:** `composer.lock (lines 1-260)`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** guzzlehttp/ringphp and guzzlehttp/streams are marked abandoned.
- **Location:** `composer.lock (lines 1-260)`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** zendframework/zend-diactoros is marked abandoned (laminas/laminas-diactoros).
- **Location:** `composer.lock (lines 1-260)`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** fzaninotto/faker (dev) is marked abandoned.
- **Location:** `composer.lock (lines 1-260)`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** symfony/debug is marked abandoned (symfony/error-handler).

**Recommendation:**

Replace abandoned packages with maintained alternatives (e.g., swiftmailer/swiftmailer -> symfony/mailer; barryvdh/laravel-cors -> fruitcake/laravel-cors successor already in lock but ensure maintained path; zendframework/zend-diactoros -> laminas/laminas-diactoros; remove guzzlehttp/ringphp and streams by upgrading elasticsearch client and HTTP stack; replace fzaninotto/faker with fakerphp/faker; symfony/debug -> symfony/error-handler).

---

### Insecure version constraints and dev stability (minimum-stability=dev, dev-master dependencies, wildcard constraints) +/-

**Finding ID:** `A06-W5`

**Severity:** major

**CWE:** CWE-937

**Description:**

composer.json sets minimum-stability to dev and uses dev-master and wildcard constraints (e.g., gurmanalexander/scout-elasticsearch-driver: dev-master; dogovor24/_ packages: 1.2._, 1.1.\*, etc.). This increases the chance of pulling unstable/unreviewed changes and makes dependency updates less predictable.

**Attack Scenario:**

A malicious or compromised upstream VCS dependency introduces a backdoor on the dev branch. Because dev stability is allowed and dev-master is used, the project may fetch the compromised commit during an update/build.

**Impact:**

Supply-chain risk; unpredictable builds; higher probability of introducing vulnerable versions.

**Evidence:**

- **Location:** `composer.json (lines 1-120)`
  - **Chunk ID:** `file:composer.json`
  - **Details:** minimum-stability set to dev; prefer-stable true.
- **Location:** `composer.json (lines 1-80)`
  - **Chunk ID:** `file:composer.json`
  - **Details:** gurmanalexander/scout-elasticsearch-driver required as dev-master.
- **Location:** `composer.lock (lines 1-220)`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** gurmanalexander/scout-elasticsearch-driver is installed as dev-master with old timestamp (2018) and VCS source.

**Recommendation:**

Set minimum-stability to stable (or omit it) and avoid dev-master. Pin VCS dependencies to tagged releases or immutable commit hashes and use conservative constraints (e.g., ^1.2.21). Review internal packages that require wildcards or \* and tighten their constraints too.

---

## A08:2021 - Software and Data Integrity Failures

### Jenkins deployment disables SSH host key checking (MITM risk for deployment channel) -/+

**Finding ID:** `A08-W4`

**Severity:** major

**CWE:** CWE-295

**Description:**

Jenkinsfile uses 'StrictHostKeyChecking=no' when SSH'ing to the deployment host. This disables server identity verification and enables man-in-the-middle attacks during deployment, potentially allowing an attacker to inject commands or redirect to a malicious host.

**Attack Scenario:**

An attacker positioned on the network (or via DNS poisoning) intercepts the SSH connection and presents a rogue host. Because host key checking is disabled, Jenkins executes the deployment commands on the attacker's host, leaking code/secrets or causing a malicious deployment.

**Impact:**

Compromised deployment process, code/secret exfiltration, execution of attacker-controlled commands in CI context.

**Evidence:**

- **Location:** `Jenkinsfile (lines 1-11)`
  - **Chunk ID:** `file:Jenkinsfile`
  - **Details:** SSH command uses -o StrictHostKeyChecking=no to run deployment remotely.

**Recommendation:**

Enable host key verification (known_hosts management), pin host keys, and use a safer deployment mechanism (deploy agent, VPN, or pipeline runner inside the target network) with audited scripts.

---

## A09:2021 - Security Logging and Monitoring Failures

### Insufficient audit logging for critical business operations (invoice/order state changes, refunds, admin actions) +

**Finding ID:** `LM-MAJ-001`

**Severity:** major

**CWE:** CWE-778

**Description:**

Some batch invoice operations log basic information, but critical operations performed via HTTP controllers/services (e.g., invoice state changes) do not create an explicit audit trail (who did what, when, from where). This limits accountability and forensic reconstruction for financial operations.

**Attack Scenario:**

A malicious insider (or compromised account) changes invoice states via an endpoint. Without an audit log containing actor identity, IP, and before/after state, the organization cannot reliably attribute or roll back fraudulent actions.

**Impact:**

Weak non-repudiation and forensic capability for financial/administrative actions; compliance risk.

**Evidence:**

- **Location:** `app/Http/Controllers/Staging/StagingInvoiceController.php (lines 33-41)`
  - **Chunk ID:** `file:app/Http/Controllers/Staging/StagingInvoiceController.php`
  - **Details:** setState updates invoice state without any audit log of actor, old/new state, or source IP.
- **Location:** `app/Console/Commands/Invoice/AbstractInvoicesCommand.php (lines 1-72)`
  - **Chunk ID:** `file:app/Console/Commands/Invoice/AbstractInvoicesCommand.php`
  - **Details:** Batch processing logs invoice ID/date/amount but not actor/correlation; errors are logged generically (Log::error($ex)).

**Recommendation:**

Implement an audit logging layer for critical state transitions (invoice/order status changes, write-offs, refunds, configuration changes). Include actor user_id/service account, request id, IP, resource id, old/new values.

---

### Log configuration uses debug level broadly and short retention; lacks integrity/centralization controls -/+

**Finding ID:** `LM-MIN-001`

**Severity:** minor

**CWE:** CWE-778

**Description:**

Logging channels default to debug level (including stdout) and daily retention is only 7 days. There is no evidence in the codebase of log integrity protection (append-only storage/signing) or explicit centralized log shipping/SIEM integration beyond stdout/syslog options.

**Attack Scenario:**

An attacker performs low-and-slow probing over weeks. With only 7 days retention and no centralized immutable store, evidence is lost before detection; debug logs may also increase the chance of sensitive data being logged elsewhere.

**Impact:**

Reduced ability to detect long-running attacks; potential confidentiality risk if debug logs capture sensitive context; operational instability due to verbose logging.

**Evidence:**

- **Location:** `config/logging.php (lines 1-95)`
  - **Chunk ID:** `file:config/logging.php`
  - **Details:** Channels use level 'debug' for single/daily/stdout; daily retention set to 7 days; stack channel uses stdout.

**Recommendation:**

Set production log level to info/warning; increase retention per policy (e.g., 30–90+ days) and ship logs to centralized SIEM/ELK/Splunk with access controls. Add integrity/immutability controls where required.

---

---

## A10:2021 - Server-Side Request Forgery (SSRF)

### SSRF via configurable bank OAuth/token URL (Guzzle) in EpayHelper -/+

**Finding ID:** `SSRF-01`

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-918

**Description:**

The application makes outbound HTTP requests using Guzzle to a URL taken directly from environment/config (EPAY_POST_AUTH_TOKEN_URL / EPAY_GET_TRANSACTION_STATUS) without any URL validation/allowlisting. If an attacker can influence runtime environment variables/config (e.g., via CI/CD, misconfigured k8s ConfigMap/Secret permissions, or admin panel that edits env), they can redirect these requests to internal network resources (localhost, private IPs, cloud metadata), resulting in SSRF.

**Attack Scenario:**

An attacker with access to modify deployment environment variables (or a compromised CI pipeline) sets EPAY_POST_AUTH_TOKEN_URL to http://169.254.169.254/latest/meta-data/iam/security-credentials/ or http://127.0.0.1:2375/. When billing triggers EpayHelper::getAuth(), the server performs the request and returns/uses the response body, enabling credential theft or internal service interaction.

**Impact:**

Potential access to internal services and sensitive cloud metadata (credentials/tokens), internal port scanning, and data exfiltration. Impact escalates if the response body is logged or returned to clients.

**Evidence:**

- **Location:** `app/Helpers/EpayHelper.php (lines 1-120)`
  - **Chunk ID:** `file:app/Helpers/EpayHelper.php`
  - **Details:** Uses env('EPAY_POST_AUTH_TOKEN_URL') and env('EPAY_GET_TRANSACTION_STATUS') to build request URL and performs Guzzle post/get without validation/allowlist.
- **Location:** `build/entrypoint.sh (lines 1-80)`
  - **Chunk ID:** `file:build/entrypoint.sh`
  - **Details:** Entrypoint writes EPAY_POST_AUTH_TOKEN_URL and EPAY_GET_TRANSACTION_STATUS into runtime .env from environment variables, making URL configurable at deploy time.
- **Location:** `automation/k8s/cfg/configmap-billing-service.yaml (lines 1-80)`
  - **Chunk ID:** `file:automation/k8s/cfg/configmap-billing-service.yaml`
  - **Details:** Kubernetes ConfigMap defines EPAY_POST_AUTH_TOKEN_URL and EPAY_GET_TRANSACTION_STATUS values (deployment-time configurable).

**Recommendation:**

Implement strict allowlisting for all outbound targets read from configuration. Validate scheme (https only), host allowlist (e.g., \*.homebank.kz, epay.kkb.kz), and block private/link-local/localhost IP ranges after DNS resolution. Prefer pinning to known hosts in code/config and disallow runtime overrides in lower-trust environments.

---

### SSRF risk from hardcoded external GET with unbounded behavior in PaymentProcessController (bank control endpoint) -/+

**Finding ID:** `SSRF-02`

**Severity:** major

**CWE:** CWE-918

**Description:**

PaymentProcessController performs an outbound GET request with Guzzle to a fixed remote endpoint (https://epay.kkb.kz/jsp/remote/control.jsp) with query content built from bank response data. While the host is fixed (mitigating classic user-controlled SSRF), there are no explicit HTTP client safety controls visible (timeouts, redirect policy). If the HTTP client follows redirects by default or the remote endpoint is compromised/misconfigured, it could be leveraged to pivot traffic. Additionally, the request is executed in a public controller action, so it can be abused for DoS by causing many outbound calls.

**Attack Scenario:**

An attacker repeatedly posts to /payment/process with crafted or replayed 'response' values, forcing the server to call the bank endpoint many times (resource exhaustion). If redirects are followed and an attacker can influence the endpoint behavior (or compromise DNS/TLS in some environments), outbound calls could be redirected to internal resources.

**Impact:**

Increased attack surface for SSRF pivoting via redirects and potential denial of service due to uncontrolled outbound calls from a web endpoint.

**Evidence:**

- **Location:** `app/Http/Controllers/Payment/PaymentProcessController.php (lines 1-95)`
  - **Chunk ID:** `file:app/Http/Controllers/Payment/PaymentProcessController.php`
  - **Details:** Creates new Guzzle Client and issues GET to https://epay.kkb.kz/... without explicit timeout/redirect controls.

**Recommendation:**

Set conservative HTTP client options: short connect/read timeouts, disable redirects (or validate redirect targets against allowlist), limit response size, and add rate limiting/authentication on the controller endpoint. Consider queuing the bank approval call asynchronously.

---
