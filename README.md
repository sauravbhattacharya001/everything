<div align="center">

# 📱 Everything App

### A unified productivity hub — events, calendars, analytics, and 220+ tools in one Flutter app

[![CI](https://github.com/sauravbhattacharya001/everything/actions/workflows/ci.yml/badge.svg)](https://github.com/sauravbhattacharya001/everything/actions/workflows/ci.yml)
[![CodeQL](https://github.com/sauravbhattacharya001/everything/actions/workflows/codeql.yml/badge.svg)](https://github.com/sauravbhattacharya001/everything/actions/workflows/codeql.yml)
[![Coverage](https://codecov.io/gh/sauravbhattacharya001/everything/graph/badge.svg)](https://codecov.io/gh/sauravbhattacharya001/everything)
[![Docker](https://github.com/sauravbhattacharya001/everything/actions/workflows/docker.yml/badge.svg)](https://github.com/sauravbhattacharya001/everything/actions/workflows/docker.yml)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.0-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.10-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

<br />

[Getting Started](#-quick-start) · [Features](#-what-you-get) · [Architecture](#-architecture) · [API Docs](#-api-reference) · [Contributing](#-contributing) · [Full Feature Catalog](FEATURES.md)

</div>

---

## 🎯 What You Get

**Everything App** is a Flutter-based productivity suite that grows with you. At its core: event management with priority tracking, Firebase auth, Microsoft Graph calendar sync, and an analytics dashboard. Around that core: **220+ built-in tools** spanning health, finance, lifestyle, games, intelligence, and developer utilities — all in **190K+ lines of Dart** with **4,600+ unit tests** across 133 test files.

### Core Features

| Feature | What it does |
|---------|-------------|
| 📅 **Event Management** | Create, edit, delete events with priority levels (Low → Urgent) |
| 🔐 **Firebase Auth** | Email/password login with typed error handling and secure credential storage |
| 📊 **Analytics Dashboard** | Priority distribution, busiest weekday analysis, monthly timeline, smart insights |
| 🔍 **Search & Filter** | Full-text search, priority filter chips, multi-criteria sorting |
| 📆 **Microsoft Graph Sync** | Fetch Outlook/M365 calendar events with paginated API requests |

### 220+ Built-in Tools

The app includes a full feature catalog organized into 11 categories — planning, productivity, health & wellness, finance, lifestyle, organization, tracking, games & puzzles, developer utilities, autonomous intelligence, and infrastructure services. Every feature has its own screen, service, and local persistence.

👉 **[See the full Feature Catalog →](FEATURES.md)**

### Autonomous Intelligence (30+ engines)

What sets Everything apart is its **autonomous intelligence layer** — services that don't just store data, they actively monitor patterns, detect risks, and surface insights:

| Engine | What it watches |
|--------|----------------|
| 🧠 **Context Switcher** | Detects life context (work/personal/fitness) and suggests relevant tools |
| 🔥 **Burnout Detector** | Multi-signal burnout risk detection with proactive wellness suggestions |
| 📊 **Habit Correlation** | Discovers hidden connections between habits, mood, sleep, and energy |
| 🎯 **Momentum Engine** | Tracks completion velocity across all features to detect slowdowns |
| ⚡ **Attention Debt** | Models deferred decisions as cognitive debt that accrues interest |
| 🔮 **Drift Detector** | Early warning for gradual lifestyle regressions humans miss |
| 💪 **Willpower Budget** | Models daily willpower as a depletable resource with spending forecasts |
| 🌀 **Serendipity Engine** | Surfaces unexpected connections between disparate life areas |
| 🎭 **Behavioral Fingerprint** | Builds behavioral signatures to detect anomalies and identity shifts |
| ⚖️ **Balance Radar** | Multi-dimensional life balance assessment across 8 dimensions |

### Security Built In

- **SSRF Prevention** — URL scheme validation and trusted-host allowlists on all outbound HTTP, including pagination links
- **Encrypted Storage** — Tokens via iOS Keychain / Android EncryptedSharedPreferences (never plaintext)
- **Error Masking** — Internal errors logged but never exposed to users
- **Automated Scanning** — CodeQL + Dependabot on every push

## 🚀 Quick Start

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter SDK | ≥ 3.10 | [flutter.dev/install](https://docs.flutter.dev/get-started/install) |
| Firebase project | — | [firebase.google.com/setup](https://firebase.google.com/docs/flutter/setup) |
| Android Studio or VS Code | — | With Flutter/Dart plugins |

### Run Locally

```bash
git clone https://github.com/sauravbhattacharya001/everything.git
cd everything
flutter pub get
flutter run
```

### Configure Secrets

Pass API keys at build time — never hardcode them:

```bash
flutter run --dart-define=GOOGLE_API_KEY=your_key_here
```

### Run with Docker (Web)

```bash
docker build -t everything-app .
docker run -p 8080:80 everything-app
# → http://localhost:8080
```

## 🛠️ Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| **Framework** | Flutter ≥ 3.10 | Cross-platform UI (Android + Web) |
| **Language** | Dart ≥ 3.0 | Type-safe, null-safe, fast |
| **State (Simple)** | Provider 6.x | Reactive state for events & user |
| **State (Complex)** | flutter_bloc 8.x | BLoC pattern for complex flows |
| **Auth** | Firebase Auth | Email/password authentication |
| **Local DB** | sqflite 2.x | SQLite event persistence |
| **Secure Storage** | flutter_secure_storage 9.x | Platform keychain/keystore |
| **HTTP** | http 1.x | REST calls with SSRF protection |
| **Calendar** | Microsoft Graph | Outlook calendar integration |

## 📊 By the Numbers

| Metric | Count |
|--------|-------|
| **Features** | 220+ self-contained tools |
| **Services** | 227 business-logic modules |
| **Screens** | 210 dedicated UI views |
| **Models** | 81 data classes |
| **Tests** | 4,600+ unit tests (133 files) |
| **Source Lines** | 190,000+ lines of Dart |
| **Source Files** | 546 in lib |

## 📁 Architecture

```
lib/                             # 546 files · 190K+ lines
├── main.dart                    # Entry point, Firebase init, routes
├── core/
│   ├── constants/               # API URLs, security allowlists
│   ├── data/                    # Sample data generators
│   ├── services/                # 227 business-logic modules
│   └── utils/                   # Feature registry, date/format helpers
├── data/
│   ├── local_storage.dart       # SharedPreferences wrapper
│   └── repositories/            # Event & user CRUD over SQLite
├── models/                      # 81 immutable data classes with JSON
├── state/
│   ├── blocs/                   # Cubit-based event state (BLoC)
│   └── providers/               # Provider with O(1) index lookup
└── views/
    ├── home/                    # 210 feature screens
    ├── login/                   # Auth screens
    └── widgets/                 # Reusable UI components
```

### Design Principles

| Principle | How |
|-----------|-----|
| **Service Layer** | `EventService` coordinates in-memory state (Provider) with disk (Repository) — screens never talk to SQLite directly |
| **O(1) Lookups** | `EventProvider` maintains an ID → index map, no linear scans |
| **Fail-Safe Persistence** | UI updates first, disk writes fire-and-forget with error logging — always responsive |
| **Security by Default** | All HTTP goes through `HttpUtils` with scheme/host validation; pagination links checked against trusted-host allowlist |
| **One Feature, One Service** | Every feature is a self-contained service — no god objects. Adding a feature requires only a `FeatureEntry` registration |
| **Autonomous Intelligence** | 30+ agentic services monitor data and act proactively — burnout detection, drift warnings, habit correlations, and more |

## 📚 API Reference

<details>
<summary><strong>EventService</strong> — central coordination layer</summary>

```dart
final service = EventService(provider: context.read<EventProvider>());

await service.loadEvents();           // SQLite → Provider
await service.addEvent(event);        // Both in-memory + disk
await service.updateEvent(modified);
await service.deleteEvent(eventId);
```
</details>

<details>
<summary><strong>EventModel</strong> — immutable event data</summary>

```dart
final event = EventModel(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  title: 'Team Standup',
  description: 'Daily sync',
  date: DateTime(2026, 3, 1, 9, 30),
  priority: EventPriority.high,
);

final json = event.toJson();
final restored = EventModel.fromJson(json);
final rescheduled = event.copyWith(date: DateTime(2026, 3, 2, 10, 0));
```
</details>

<details>
<summary><strong>AuthService</strong> — Firebase authentication</summary>

```dart
final auth = AuthService();

final user = await auth.loginWithEmail('user@example.com', 'password');
final newUser = await auth.signUpWithEmail('user@example.com', 'password');
auth.authStateChanges.listen((user) => /* handle state */);
await auth.logout();
```
</details>

<details>
<summary><strong>GraphService</strong> — Microsoft calendar sync</summary>

```dart
final graph = GraphService(accessToken);
final events = await graph.fetchCalendarEvents();
// Auto-paginates with SSRF-safe link validation
```
</details>

## 🧪 Testing

```bash
flutter test                              # All tests
flutter test --coverage                   # With coverage report
flutter test test/models/event_model_test.dart  # Single file
```

**Test coverage includes:** models (serialization, equality), providers (CRUD, index consistency), BLoC (state transitions), HTTP utils (URL validation, SSRF blocking), security (scheme enforcement, trusted hosts), and all 30+ autonomous intelligence engines.

## 🔧 Troubleshooting

<details>
<summary>Common issues and fixes</summary>

| Problem | Solution |
|---------|----------|
| `flutter pub get` fails | Verify Flutter ≥ 3.10: `flutter --version` |
| Firebase crash on startup | Check `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) |
| `sqflite` not found on web | sqflite doesn't support web — use `flutter run -d chrome` for UI testing only |
| Graph API returns 401 | Access token expired — obtain a new one via OAuth2 |
| Tests fail with "no Firebase app" | Tests mock Firebase; ensure init for integration tests |
| Docker build OOM | Increase Docker memory to ≥ 4 GB |

</details>

## 🗺️ Roadmap

- [ ] Auth state restoration — auto-login returning users ([#17](https://github.com/sauravbhattacharya001/everything/issues/17))
- [ ] In-app Microsoft Graph OAuth flow (currently requires external token)
- [ ] Recurring events — daily, weekly, monthly patterns
- [ ] Push notifications via Firebase Cloud Messaging
- [ ] iOS support (currently Android + Web)
- [ ] Offline-first sync — queue mutations, sync when online
- [ ] Dark mode with system-aware switching
- [ ] Plugin system for community-contributed features
- [ ] Cross-device sync with end-to-end encryption

## 🤝 Contributing

Contributions welcome! See the [Contributing Guide](CONTRIBUTING.md) for full details.

```bash
# Fork → clone → branch → commit → PR
git checkout -b feature/amazing-feature
git commit -m 'Add amazing feature'
git push origin feature/amazing-feature
```

**Requirements:** tests pass (`flutter test`), follows existing patterns, no secrets in source code.

## 📄 License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

**[📖 Docs](https://sauravbhattacharya001.github.io/everything/)** · **[🐛 Issues](https://github.com/sauravbhattacharya001/everything/issues)** · **[📋 Feature Catalog](FEATURES.md)** · **[🔒 Security Policy](SECURITY.md)**

Built by [Saurav Bhattacharya](https://github.com/sauravbhattacharya001)

</div>
