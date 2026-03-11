---
name: security-privacy-guard
description: Enforce security and privacy best practices in Claude Code sessions. Use this skill on every task to prevent accidental secret leakage, unsafe code patterns, data exposure, and supply chain risks. Covers secrets management, input validation, dependency security, logging hygiene, auth patterns, and privacy-by-design principles.
---

# Security & Privacy Guard

**Apply this skill to EVERY task.** Security is not optional.

> **Note:** The security scan script referenced below is in the same directory as this SKILL.md. Use the resolved path of this skill to construct absolute paths to co-located scripts.

## Core Rules

### 1. Secrets & Credentials — NEVER Hardcode
- **NEVER** write API keys, tokens, passwords, or connection strings in code/config/comments.
- **NEVER** echo, print, or log secrets — not even for debugging.
- **NEVER** commit `.env`, `credentials.json`, `serviceAccountKey.json`, or similar.
- **ALWAYS** use environment variables, secret managers, or vault services.
- **ALWAYS** ensure `.gitignore` includes secret/config files before `git add`.

### 2. Input Validation & Injection Prevention
- **NEVER** use string concatenation for SQL queries, shell commands, or HTML output.
- **ALWAYS** use parameterized queries, prepared statements, or ORM methods.
- **ALWAYS** sanitize and validate all user input (type, length, format, allowed chars).
- **ALWAYS** use allowlists over denylists.

### 3. Authentication & Authorization
- **NEVER** implement custom password hashing — use bcrypt, scrypt, or argon2.
- **NEVER** store passwords in plaintext or reversible encryption.
- **NEVER** put auth tokens in URLs or query parameters.
- **ALWAYS** validate JWT signatures and expiration server-side.
- **ALWAYS** enforce auth checks on every protected endpoint (server-side, not just frontend).

### 4. Dependencies & Supply Chain
- **NEVER** install packages without checking them first (typosquatting is real).
- **ALWAYS** pin dependency versions; use lockfiles (`npm ci`, not `npm install`).
- **ALWAYS** prefer well-known, actively maintained packages.

### 5. Logging & Error Handling
- **NEVER** log sensitive data: passwords, tokens, PII, session IDs.
- **NEVER** expose stack traces or internal errors to end users.
- **ALWAYS** return generic error messages to users; log details server-side.

### 6. Data Privacy
- **NEVER** collect more data than strictly necessary.
- **ALWAYS** anonymize data in dev/staging environments.
- **ALWAYS** encrypt sensitive data at rest and in transit (HTTPS).
- **NEVER** use `Access-Control-Allow-Origin: *` with credentials.

### 7. File & Path Security
- **NEVER** use user input directly in file paths (path traversal).
- **ALWAYS** validate filenames; verify resolved paths stay within allowed directories.

### 8. Network & API Security
- **NEVER** disable SSL/TLS verification (`verify=False`).
- **ALWAYS** implement rate limiting on public APIs.
- **ALWAYS** set security headers: CSP, X-Content-Type-Options, HSTS.

### 9. Docker & Infrastructure
- **NEVER** run containers as root unless necessary.
- **NEVER** use `latest` tags in production Dockerfiles.
- **NEVER** copy secrets into Docker images — use runtime env vars.

## Pre-Commit Security Checklist

Before completing ANY task, verify:

- [ ] No hardcoded secrets in any file
- [ ] `.gitignore` includes `.env`, `*.pem`, `*.key`, credential files
- [ ] No SQL/command injection — all queries parameterized
- [ ] Input validation on all user-facing inputs
- [ ] Error messages don't leak internals
- [ ] Logs don't contain PII or secrets
- [ ] Dependencies from trusted sources, versions pinned
- [ ] HTTPS for all external communication
- [ ] Auth checks on all protected routes (server-side)

### Automated Scan

Run the security scan script:

```bash
bash <skill-dir>/scan.sh
```

Checks for hardcoded secrets, dangerous patterns (`shell=True`, `eval`, `innerHTML`), tracked sensitive files, and private key material. Read the script for details.
