# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do not** open a public GitHub issue
2. Email the maintainer directly or use [GitHub Security Advisories](https://github.com/sauravbhattacharya001/everything/security/advisories/new)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

You can expect an initial response within 72 hours.

## Security Measures

This project implements several security controls:

### SSRF Prevention
All outbound HTTP requests go through `HttpUtils` which validates URL schemes (HTTPS only) and checks hosts against a trusted allowlist. Pagination links from external APIs (e.g., Microsoft Graph `@odata.nextLink`) are also validated to prevent open-redirect SSRF attacks.

### Secure Credential Storage
Sensitive data (tokens, passwords) are stored using `flutter_secure_storage`, which uses:
- **iOS**: Keychain Services
- **Android**: EncryptedSharedPreferences (AES-256)

Credentials are never stored in plaintext, SharedPreferences, or logged.

### Error Masking
Internal errors (stack traces, database errors, API responses) are caught and logged locally but never exposed to end users. Generic error messages prevent information leakage.

### Input Validation
- Event fields are validated before persistence
- Authentication inputs are validated client-side before Firebase calls
- API responses are parsed with null-safety checks

### Dependencies
- Dependabot is enabled for automated dependency updates
- CodeQL runs weekly for static analysis
- CI runs on every PR to catch regressions
