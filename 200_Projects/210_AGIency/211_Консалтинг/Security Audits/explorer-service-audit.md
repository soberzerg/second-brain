# Security Audit Report

## A01:2021 - Broken Access Control +

### IDOR in File Download (UUIDFileController)

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-639

**Description:**

The `UUIDFileController::download` method accepts a file UUID and delegates to `UUIDFileService::download` without performing any access control checks. The `File` model binding does not enforce the `accessible` scope by default, and the service assumes access is already granted.

**Attack Scenario:**

An attacker authenticates to the API and discovers the UUID of a sensitive file (e.g., via leaked logs, sequential UUIDs, or brute force). They send a GET request to `/api/explorer/uuid-file/{target_uuid}/download`. The server returns the file content in a ZIP archive without checking if the attacker has permission to access that file.

**Impact:**

Confidentiality breach. Unauthorized users can download any file stored in the system if they know its UUID.

**Evidence:**

- **Location:** `app/Http/Controllers/UUIDFileController.php`
  - **Chunk ID:** `class:App\Http\Controllers\UUIDFileController`
  - **Details:** download method delegates to service without checks.
- **Location:** `app/Services/UUIDFileService.php`
  - **Chunk ID:** `class:App\Services\UUIDFileService`
  - **Details:** download method generates ZIP without access checks.

**Recommendation:**

Apply the `accessible()` scope to the file query in the controller or service, or use `authorize` to verify permissions.

---

### IDOR in File Metadata View (UUIDFileController)

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-639

**Description:**

The `UUIDFileController::show` method exposes file metadata. While it attempts to validate workspace context, it lacks a direct check for user permissions (e.g., ownership, group membership) on the specific file.

**Attack Scenario:**

An attacker sends a GET request to `/api/explorer/uuid-file/{target_uuid}`. The controller performs a check for workspace consistency but fails to verify if the user actually has read access to the file within that workspace. The server returns sensitive file metadata.

**Impact:**

Confidentiality breach. Unauthorized users can view metadata (name, size, owner, etc.) of any file.

**Evidence:**

- **Location:** `app/Http/Controllers/UUIDFileController.php`
  - **Chunk ID:** `class:App\Http\Controllers\UUIDFileController`
  - **Details:** show method lacks explicit user access check.

**Recommendation:**

Ensure the user has read access to the file using `accessible()` scope or `FileAccessService::canRead()`.

## A02:2021 - Cryptographic Failures +

### Use of Weak Cryptographic Primitive (crypt) with Static Salt

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-327

**Description:**

The application uses the `crypt()` function with a hardcoded, static salt (`'d24'`) to "encrypt" parameters for generating "No Auth" links. The `crypt()` function with such a salt is extremely weak (likely DES or MD5-based) and deterministic. The integrity check in `validateHash` relies on this weak encryption, making it bypassable.

**Attack Scenario:**

An attacker who knows the `workspace_id` and `file_signature_id` (which can be enumerated) can generate a valid `encrypted` string using `crypt(..., 'd24')` because the salt is static. They can then calculate the correct SHA-256 hash and construct a valid URL to access the document signing interface without authentication.

**Impact:**

Authentication Bypass. Attackers can generate valid links to access and sign documents on behalf of other users.

**Evidence:**

- **Location:** `app/Services/QR/NoAuth/QrService.php (line 106)`
  - **Chunk ID:** `file:app/Services/QR/NoAuth/QrService.php`
  - **Details:** Usage of crypt() with static salt 'd24'.
- **Location:** `app/Http/Requests/Qr/NoAuth/GenerateNoAuthLinkFormRequest.php (line 110)`
  - **Chunk ID:** `class:App\Http\Requests\Qr\NoAuth\GenerateNoAuthLinkFormRequest`
  - **Details:** Validation logic relies on the weak encrypted value.

**Recommendation:**

Use `encrypt()` (AES-256) instead of `crypt()`. Use `hash_hmac()` with a secret key for integrity checks.

## A03:2021 - Injection +

### SQL Injection in PrepareDownloadMultipleJob

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-89

**Description:**

Critical SQL Injection vulnerability in `app/Jobs/PrepareDownloadMultipleJob.php`. The `file_uuids` array from user input is directly concatenated into a raw SQL query using `implode` without proper validation or parameter binding. The validation rule in `PrepareDownloadMultipleRequest` only checks if `file_uuids` is an array, not if it contains valid UUIDs.

**Attack Scenario:**

An attacker sends a POST request to `/api/download-multiple` (or similar endpoint using `PrepareDownloadMultipleRequest`) with a payload like `{"file_uuids": ["') UNION SELECT password FROM users --"], "mode": "zip"}`. The `PrepareDownloadMultipleJob` executes a query like `... AND uuid in ('') UNION SELECT password FROM users --') ...`, allowing the attacker to retrieve sensitive data or manipulate the database.

**Impact:**

Full database compromise, data exfiltration, or data manipulation.

**Evidence:**

- **Location:** `app/Jobs/PrepareDownloadMultipleJob.php`
  - **Chunk ID:** `file:app/Jobs/PrepareDownloadMultipleJob.php`
  - **Details:** Vulnerable SQL query construction using implode on user input
- **Location:** `app/Http/Requests/PrepareDownloadMultipleRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/PrepareDownloadMultipleRequest.php`
  - **Details:** Insufficient validation of file_uuids array

**Recommendation:**

Validate `file_uuids` elements as UUIDs in the request class and use parameter binding in the SQL query.

## A04:2021 - Insecure Design +

### Memory Exhaustion in File Size Check

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-770

**Description:**

The `AttachDocumentRequest` class calculates file size by loading the entire file content into memory using `strlen(EncryptedStorageService::get($path))`. This is unsafe for large files and leads to memory exhaustion.

**Attack Scenario:**

An attacker uploads a large file (e.g., 1GB) to the `attach-document` endpoint. The application attempts to load the entire file string into memory to calculate its length, causing the PHP process to run out of memory and crash. Repeated requests can take down the service.

**Impact:**

Denial of Service (DoS)

**Evidence:**

- **Location:** `app/Http/Requests/AttachDocumentRequest.php`
  - **Chunk ID:** `file:app/Http/Requests/AttachDocumentRequest.php`
  - **Details:** Insecure file size calculation using strlen() on file content

**Recommendation:**

Use a method that retrieves file size from filesystem metadata (e.g., `EncryptedStorageService::size()`) without loading the content.

## A05:2021 - Security Misconfiguration

### Unrestricted File Upload

**Severity:** 🚨 **MEDIUM**

**CWE:** CWE-434

**Description:**

The StoreFileRequest and StoreFile1cRequest classes validate the file size but fail to validate the file MIME type or extension. This allows any file type to be uploaded.

**Attack Scenario:**

An attacker can upload a file with a malicious extension (e.g., .php) because the application does not validate the file type. If the server is configured to execute PHP files in the upload directory, the attacker can achieve Remote Code Execution (RCE).

**Impact:**

Remote Code Execution (RCE), System Compromise

**Evidence:**

- **Location:** `app/Http/Requests/StoreFileRequest.php (line 58)`
  - **Chunk ID:** `file:app/Http/Requests/StoreFileRequest.php`
  - **Details:** Validation rules allow any file type: 'file' => 'file|max:20480'.
- **Location:** `app/Http/Requests/File1C/StoreFile1cRequest.php (line 29)`
  - **Chunk ID:** `file:app/Http/Requests/File1C/StoreFile1cRequest.php`
  - **Details:** Validation rules allow any file type: 'file' => 'required|file|max:20480'.

**Recommendation:**

Add strict MIME type and extension validation to the request classes.

---

### Hardcoded Encryption Key

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-321

**Description:**

The .env.example file contains a hardcoded FILE_ENCRYPTION_KEY. Developers might mistakenly use this key in production, or it might be exposed if the file is accessible.

**Attack Scenario:**

An attacker who gains access to the source code or the .env.example file can find the hardcoded encryption key. They can then use this key to decrypt sensitive files stored by the application.

**Impact:**

Data Breach, Loss of Confidentiality

**Evidence:**

- **Location:** `.env.example (line 56)`
  - **Chunk ID:** `file:.env.example`
  - **Details:** Hardcoded FILE_ENCRYPTION_KEY=w9VDvenKYpdcRAfrAh0IKSmRJW1JYii4

**Recommendation:**

Remove the key from .env.example and ensure it is generated securely and stored in the environment variables only.

## A06:2021 - Vulnerable and Outdated Components

### Known Vulnerabilities in Dependencies

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-347

**Description:**

`lcobucci/jwt` version `3.4.4` is installed. Versions < 3.4.6 are vulnerable to improper signature verification (CVE-2021-21245). `guzzlehttp/guzzle` 6.5.5 is also vulnerable to CVE-2022-31090.

**Attack Scenario:**

An attacker could bypass signature verification on JWT tokens if the application uses the vulnerable `lcobucci/jwt` library (CVE-2021-21245), allowing them to forge tokens and impersonate users.

**Impact:**

Authentication Bypass (JWT) and Information Disclosure (Guzzle).

**Evidence:**

- **Location:** `composer.lock`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** "name": "lcobucci/jwt", "version": "3.4.4"
- **Location:** `composer.lock`
  - **Chunk ID:** `file:composer.lock`
  - **Details:** "name": "guzzlehttp/guzzle", "version": "6.5.5"

**Recommendation:**

Update `lcobucci/jwt` to >= 3.4.6 and `guzzlehttp/guzzle` to >= 6.5.8.

## A07:2021 - Identification and Authentication Failures

## A08:2021 - Software and Data Integrity Failures

### Insecure Dependency Update in Production

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-494

**Description:**

The `deploy.sh` script executes `composer update`, which ignores the lock file and updates all dependencies to the latest matching versions. This undermines the integrity guarantees provided by `composer.lock` and exposes the production environment to untested code and supply chain attacks.

**Attack Scenario:**

During a deployment, `composer update` runs. A dependency used by the project has recently released a malicious version (e.g., via a compromised maintainer account) or a breaking change. The deployment script pulls this new version instead of the tested version in `composer.lock`, compromising the production environment or causing a denial of service.

**Impact:**

High. Risk of introducing vulnerabilities, malware, or breaking changes directly into production.

**Evidence:**

- **Location:** `deploy.sh`
  - **Chunk ID:** `file:deploy.sh`
  - **Details:** composer update

**Recommendation:**

Replace `composer update` with `composer install --no-dev --optimize-autoloader` in the deployment script.

## A09:2021 - Security Logging and Monitoring Failures +

### Missing Logging of Authorization Failures

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-778

**Description:**

The application uses Laravel's default exception handling which typically excludes `AuthorizationException` (403) and `ModelNotFoundException` (404) from logs. This means access denied events are not recorded, creating a blind spot for security monitoring.

**Attack Scenario:**

An attacker attempts to access resources they are not authorized for (e.g., another user's files). The application denies access (403), but because this event is not logged, the security team is unaware of the brute-force or probing attempt.

**Impact:**

Inability to detect and respond to unauthorized access attempts, privilege escalation probing, or IDOR exploitation attempts.

**Evidence:**

- **Location:** `app/Exceptions/Handler.php`
  - **Chunk ID:** `file:app/Exceptions/Handler.php`
  - **Details:** Handler::report calls parent::report which filters out AuthorizationException by default.

**Recommendation:**

Override `report` in `Handler.php` to explicitly log `AuthorizationException` with user context.

## A10:2021 - Server-Side Request Forgery (SSRF)

### XML External Entity (XXE) Injection

**Severity:** 🚨 **CRITICAL**

**CWE:** CWE-611

**Description:**

The application uses `SimpleXMLElement` to parse user-provided XML data without disabling external entity loading. This occurs in `FileSignatureController::update` when handling signature updates and in `UUIDFileService::getSignatureContent` when processing stored signatures. This is a classic XXE vulnerability.

**Attack Scenario:**

An attacker submits a file signature containing a malicious XML payload (e.g., `<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]><root>&xxe;</root>`). When the application processes this signature in `FileSignatureController::update` or `UUIDFileService::getSignatureContent`, it parses the XML and resolves the external entity, allowing the attacker to read local files or make HTTP requests to internal systems.

**Impact:**

High. Can lead to Local File Disclosure (LFD), Server-Side Request Forgery (SSRF), and Denial of Service (DoS).

**Evidence:**

- **Location:** `app/Http/Controllers/FileSignatureController.php (line 350)`
  - **Chunk ID:** `file:app/Http/Controllers/FileSignatureController.php`
  - **Details:** Direct instantiation of SimpleXMLElement with user input $updateFileSignatureRequest->signature without disabling entities.
- **Location:** `app/Services/UUIDFileService.php (line 120)`
  - **Chunk ID:** `file:app/Services/UUIDFileService.php`
  - **Details:** Direct instantiation of SimpleXMLElement with stored signature data.

**Recommendation:**

Disable external entity loading using `libxml_disable_entity_loader(true)` before parsing XML.
