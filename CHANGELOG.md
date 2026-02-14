# Changelog

All notable changes to the Everything App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-02-14

### Added
- **Authentication:** Firebase Auth email/password login with typed `AuthException` error handling
- **Event management:** Create, list, and delete events with reactive UI updates
- **State management:** Dual approach — `Provider` for simple state, `flutter_bloc` for complex flows
- **Local storage:** SQLite persistence via `sqflite` with singleton database connection
- **Secure storage:** `flutter_secure_storage` for tokens and credentials (Keychain/Keystore)
- **Microsoft Graph integration:** Calendar event fetching with pagination and SSRF prevention
- **HTTP layer:** Secure `HttpUtils` with URL validation, timeouts, and trusted-host enforcement
- **Date utilities:** ISO-8601 formatting, relative time descriptions ("2 hours ago")
- **Models:** Immutable `EventModel` with `copyWith`, equality, and JSON serialization
- **UI:** Login screen with validation, Home screen with event list, reusable `EventCard` widget
- **CI/CD:** GitHub Actions workflows for CI, CodeQL, Dependabot, and GitHub Pages deployment
- **Docker:** Multi-stage Dockerfile for Flutter Web → nginx production builds
- **Tests:** Unit tests for models, BLoC, providers, HTTP utilities, and security constraints
- **Documentation:** GitHub Pages documentation site

### Security
- SSRF prevention on HTTP requests and pagination link following
- Sensitive error details hidden from UI (generic user-facing messages)
- Secure storage for tokens instead of SharedPreferences
- URL scheme validation (HTTPS-only)
- Trusted API host allowlist for pagination links
