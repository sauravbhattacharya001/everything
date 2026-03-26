<div align="center">

# 📱 Everything App

**A unified productivity hub for managing events, calendars, and communications — built with Flutter**

[![CI](https://github.com/sauravbhattacharya001/everything/actions/workflows/ci.yml/badge.svg)](https://github.com/sauravbhattacharya001/everything/actions/workflows/ci.yml)
[![CodeQL](https://github.com/sauravbhattacharya001/everything/actions/workflows/codeql.yml/badge.svg)](https://github.com/sauravbhattacharya001/everything/actions/workflows/codeql.yml)
[![Coverage](https://codecov.io/gh/sauravbhattacharya001/everything/graph/badge.svg)](https://codecov.io/gh/sauravbhattacharya001/everything)
[![Docker](https://github.com/sauravbhattacharya001/everything/actions/workflows/docker.yml/badge.svg)](https://github.com/sauravbhattacharya001/everything/actions/workflows/docker.yml)
[![Pages](https://github.com/sauravbhattacharya001/everything/actions/workflows/pages.yml/badge.svg)](https://sauravbhattacharya001.github.io/everything/)
[![Dependabot](https://img.shields.io/badge/Dependabot-enabled-025e8c?logo=dependabot&logoColor=white)](https://github.com/sauravbhattacharya001/everything/blob/master/.github/dependabot.yml)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.0-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.10-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-brightgreen?logo=android&logoColor=white)](https://flutter.dev/multi-platform)
[![Firebase](https://img.shields.io/badge/Firebase-Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/sauravbhattacharya001/everything?include_prereleases)](https://github.com/sauravbhattacharya001/everything/releases)
[![GitHub issues](https://img.shields.io/github/issues/sauravbhattacharya001/everything)](https://github.com/sauravbhattacharya001/everything/issues)
[![GitHub last commit](https://img.shields.io/github/last-commit/sauravbhattacharya001/everything)](https://github.com/sauravbhattacharya001/everything/commits/master)
[![GitHub repo size](https://img.shields.io/github/repo-size/sauravbhattacharya001/everything)](https://github.com/sauravbhattacharya001/everything)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/sauravbhattacharya001/everything/blob/master/CONTRIBUTING.md)

<br />

Everything you need in one app — events with priority tracking, Microsoft Graph calendar sync,
analytics dashboard, and Firebase authentication, all wrapped in a clean Material Design UI.

[Getting Started](#-getting-started) · [Features](#-features) · [Architecture](#-architecture) · [API Reference](#-api-reference) · [Contributing](#-contributing)

</div>

---

## ✨ Features

### Core
- **📅 Event Management** — Create, edit, and delete events with title, description, date/time, and priority levels (Low → Urgent)
- **🔐 Firebase Authentication** — Email/password login with typed error handling and secure credential storage
- **📊 Analytics Dashboard** — Overview cards, priority distribution charts, busiest weekday analysis, monthly timeline, and smart insights
- **🔍 Search & Filter** — Full-text search across events with priority filter chips and multi-criteria sorting (date, priority, title)
- **📆 Microsoft Graph Sync** — Fetch calendar events from Outlook/Microsoft 365 with paginated API requests

### Security
- **🛡️ SSRF Prevention** — URL scheme validation and trusted-host allowlists on all outbound HTTP requests, including pagination links
- **🔒 Secure Storage** — Tokens and credentials stored via iOS Keychain / Android EncryptedSharedPreferences (never plaintext)
- **🚫 Error Masking** — Internal errors are logged but never exposed to the user; generic messages prevent information leakage

### Developer Experience
- **🧪 Unit Tests** — Coverage for models, BLoC, providers, HTTP utilities, and security constraints
- **⚙️ CI/CD** — GitHub Actions for build/test, CodeQL security scanning, Dependabot, and automated Docker builds
- **🐳 Docker** — Multi-stage Dockerfile for Flutter Web → nginx production builds
- **📖 Documentation** — [GitHub Pages docs site](https://sauravbhattacharya001.github.io/everything/)

> **📱 100+ built-in features** across productivity, health, finance, lifestyle, and more — see the full **[Feature Catalog](FEATURES.md)** for details.

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Framework** | [Flutter](https://flutter.dev) ≥3.10 | Cross-platform UI |
| **Language** | [Dart](https://dart.dev) ≥3.0 | Type-safe, null-safe |
| **State (Simple)** | [Provider](https://pub.dev/packages/provider) 6.x | Reactive state for events & user |
| **State (Complex)** | [flutter_bloc](https://pub.dev/packages/flutter_bloc) 8.x | BLoC pattern for complex flows |
| **Auth** | [Firebase Auth](https://firebase.google.com/docs/auth) | Email/password authentication |
| **Local DB** | [sqflite](https://pub.dev/packages/sqflite) 2.x | SQLite event persistence |
| **Secure Storage** | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) 9.x | Keychain / Keystore for secrets |
| **HTTP** | [http](https://pub.dev/packages/http) 1.x | REST API calls with security layer |
| **Calendar API** | [Microsoft Graph](https://learn.microsoft.com/en-us/graph/) | Outlook calendar integration |

## 📁 Architecture

```
lib/
├── main.dart                    # App entry point, Firebase init, route config
├── core/
│   ├── constants/
│   │   └── app_constants.dart   # API URLs, security allowlists, config
│   ├── services/
│   │   ├── auth_service.dart    # Firebase Auth wrapper with typed exceptions
│   │   ├── event_service.dart   # Coordinates provider ↔ repository sync
│   │   ├── graph_service.dart   # Microsoft Graph API with SSRF protection
│   │   ├── secure_storage_service.dart  # Encrypted key-value store
│   │   └── storage_service.dart # SharedPreferences for non-sensitive data
│   └── utils/
│       ├── date_utils.dart      # Formatting, relative time ("2 hours ago")
│       └── http_utils.dart      # URL validation, timeouts, trusted hosts
├── data/
│   ├── local_storage.dart       # Singleton SQLite database manager
│   └── repositories/
│       ├── event_repository.dart # Event CRUD over SQLite
│       └── user_repository.dart  # User profile persistence
├── models/
│   ├── event_model.dart         # Immutable event with priority enum
│   └── user_model.dart          # User profile with JSON serialization
├── state/
│   ├── blocs/
│   │   └── event_bloc.dart      # Cubit-based event state (alternative)
│   └── providers/
│       ├── event_provider.dart  # Provider with O(1) index lookup
│       └── user_provider.dart   # Current user state
└── views/
    ├── home/
    │   ├── home_screen.dart     # Event list with search/filter/sort
    │   ├── event_detail_screen.dart  # Full event detail view
    │   └── stats_screen.dart    # Analytics dashboard
    ├── login/
    │   └── login_screen.dart    # Email/password login with validation
    └── widgets/
        ├── event_card.dart      # List item with priority color strip
        ├── event_form_dialog.dart  # Create/edit bottom sheet form
        └── user_avatar.dart     # Network image with initials fallback
```

### Design Principles

- **Service Layer Pattern** — `EventService` coordinates in-memory state (Provider) with disk persistence (Repository), ensuring consistency without duplicating logic across screens
- **O(1) Lookups** — `EventProvider` maintains an ID → index map, avoiding linear scans for updates/deletes on large lists
- **Fail-Safe Persistence** — UI state updates first, disk writes are fire-and-forget with error logging — the app stays responsive even if SQLite I/O fails
- **Security by Default** — All HTTP requests go through `HttpUtils` with scheme/host validation; pagination links are checked against a trusted-host allowlist to prevent SSRF

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** ≥3.10 — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Firebase project** — [Set up Firebase](https://firebase.google.com/docs/flutter/setup)
- **Android Studio** or **VS Code** with Flutter/Dart plugins

### Installation

```bash
# Clone the repository
git clone https://github.com/sauravbhattacharya001/everything.git
cd everything

# Install dependencies
flutter pub get

# Configure Firebase (replace with your project)
# See: https://firebase.google.com/docs/flutter/setup

# Run on connected device
flutter run
```

### Configuration

Set API keys via environment variables at build time (never hardcode secrets):

```bash
flutter run --dart-define=GOOGLE_API_KEY=your_key_here
```

For Microsoft Graph integration, provide an OAuth2 access token to `GraphService`:

```dart
final graphService = GraphService(accessToken);
final events = await graphService.fetchCalendarEvents();
```

### Docker (Web Build)

```bash
# Build and run as a web app in Docker
docker build -t everything-app .
docker run -p 8080:80 everything-app

# Open http://localhost:8080
```

## 📚 API Reference

### EventService

The central coordination layer — always use this instead of directly calling `EventProvider` or `EventRepository`:

```dart
final service = EventService(
  provider: context.read<EventProvider>(),
);

// Load persisted events from SQLite into Provider
await service.loadEvents();

// CRUD — updates both in-memory state and SQLite atomically
await service.addEvent(event);
await service.updateEvent(modifiedEvent);
await service.deleteEvent(eventId);
```

### EventModel

```dart
// Create
final event = EventModel(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  title: 'Team Standup',
  description: 'Daily sync with the engineering team',
  date: DateTime(2026, 3, 1, 9, 30),
  priority: EventPriority.high,
);

// Serialize
final json = event.toJson();
final restored = EventModel.fromJson(json);

// Immutable update
final rescheduled = event.copyWith(
  date: DateTime(2026, 3, 2, 10, 0),
  priority: EventPriority.urgent,
);
```

### AuthService

```dart
final auth = AuthService();

// Login
final user = await auth.loginWithEmail('user@example.com', 'password');

// Sign up
final newUser = await auth.signUpWithEmail('user@example.com', 'password');

// Listen to auth state changes
auth.authStateChanges.listen((user) {
  if (user != null) { /* logged in */ }
});

// Logout
await auth.logout();
```

### GraphService

```dart
final graph = GraphService(accessToken);

// Fetches all calendar events with automatic pagination
// Validates pagination links against trusted hosts (SSRF prevention)
final events = await graph.fetchCalendarEvents();
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run a specific test file
flutter test test/models/event_model_test.dart
```

Tests cover:
- **Models** — JSON serialization/deserialization, `copyWith`, equality
- **Providers** — Add/remove/update events, index consistency
- **BLoC** — State transitions, event handling
- **HTTP Utils** — URL validation, SSRF blocking, timeout behavior
- **Security** — Scheme enforcement, trusted-host verification

## 🔒 Security

This project takes security seriously. See [SECURITY.md](SECURITY.md) for the full security policy, including how to report vulnerabilities.

Key protections: SSRF prevention on all outbound HTTP, encrypted credential storage via platform keychains, error masking, and automated scanning (CodeQL + Dependabot).

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| `flutter pub get` fails | Ensure Flutter SDK ≥3.10: `flutter --version` |
| Firebase init crash on startup | Verify `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in place |
| `sqflite` not found on web | sqflite doesn't support web — use `flutter run -d chrome` only for UI testing |
| Microsoft Graph returns 401 | Access token expired — obtain a new one via OAuth2 flow |
| Tests fail with "no Firebase app" | Tests mock Firebase; ensure Firebase is initialized for integration tests |
| Docker build OOM | Increase Docker memory limit to ≥4GB (Flutter web build is memory-intensive) |

## 🗺️ Roadmap

- [ ] **Auth state restoration** — Auto-login returning users via `authStateChanges` ([#17](https://github.com/sauravbhattacharya001/everything/issues/17))
- [ ] **Microsoft Graph OAuth flow** — In-app token acquisition (currently requires external token)
- [ ] **Recurring events** — Daily, weekly, monthly repeat patterns
- [ ] **Push notifications** — Event reminders via Firebase Cloud Messaging
- [ ] **iOS support** — Currently Android-focused, expand to iOS
- [ ] **Offline sync** — Queue mutations when offline, sync when back online
- [ ] **Dark mode** — System-aware theme switching

## 🤝 Contributing

Contributions are welcome! See the [Contributing Guide](CONTRIBUTING.md) for details.

1. **Fork** the repository
2. **Create a branch** — `git checkout -b feature/amazing-feature`
3. **Commit changes** — `git commit -m 'Add amazing feature'`
4. **Push** — `git push origin feature/amazing-feature`
5. **Open a Pull Request**

Please ensure:
- All tests pass (`flutter test`)
- Code follows existing patterns (service layer, typed exceptions)
- New features include tests
- No secrets in source code (use `--dart-define`)

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

---

<div align="center">

**Built by [Saurav Bhattacharya](https://github.com/sauravbhattacharya001)**

</div>
