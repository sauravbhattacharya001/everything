# Everything App — Copilot Instructions

## Project Overview

**Everything** is a Flutter-based productivity app for managing communications, calendars, and events. It uses Firebase for auth and targets web (primary), Android, and iOS.

## Architecture

```
lib/
├── main.dart               # App entry point; initializes Firebase, sets up MultiProvider
├── core/
│   ├── constants/          # App-wide config (AppConstants)
│   ├── services/           # External integrations
│   │   ├── auth_service.dart          # Firebase Auth wrapper
│   │   ├── graph_service.dart         # Microsoft Graph API client
│   │   ├── secure_storage_service.dart # flutter_secure_storage wrapper
│   │   └── storage_service.dart       # SharedPreferences wrapper
│   └── utils/
│       ├── date_utils.dart            # Date formatting helpers
│       └── http_utils.dart            # HTTP client with retry, timeout, auth headers
├── data/
│   ├── local_storage.dart             # SQLite via sqflite
│   └── repositories/
│       ├── event_repository.dart      # CRUD for events
│       └── user_repository.dart       # CRUD for users
├── models/
│   ├── event_model.dart               # Event data class with JSON serialization
│   └── user_model.dart                # User data class with JSON serialization
├── state/
│   ├── blocs/
│   │   └── event_bloc.dart            # BLoC pattern for events (flutter_bloc)
│   └── providers/
│       ├── event_provider.dart        # ChangeNotifier for events
│       └── user_provider.dart         # ChangeNotifier for user state
└── views/
    ├── home/home_screen.dart          # Main dashboard with event list
    ├── login/login_screen.dart        # Email/password login
    └── widgets/
        ├── event_card.dart            # Event display card
        └── user_avatar.dart           # User avatar widget
```

## Key Patterns

- **State management:** Dual approach — `Provider` (ChangeNotifier) for simple state, `flutter_bloc` for complex event flows. Both are wired in `main.dart` via `MultiProvider`.
- **Services:** Thin wrappers around Firebase Auth, secure storage, and HTTP APIs. Services are stateless and can be injected.
- **Models:** Immutable-style data classes with `fromJson`/`toJson` factory constructors.
- **Repositories:** Abstract data access layer between services and state management.

## Conventions

- **Dart formatting:** Use `dart format .` — CI enforces it.
- **Analysis:** `flutter analyze --no-pub --fatal-infos` must pass. Treat all infos as errors.
- **Test naming:** Test files mirror source: `lib/models/event_model.dart` → `test/models/event_model_test.dart`.
- **Imports:** Use relative imports within `lib/`. Avoid `package:` imports for local files.
- **Flutter version:** Targets 3.22.0 stable. SDK constraint: `>=3.0.0 <4.0.0`.

## How to Test

```bash
# Run all tests
flutter test --reporter expanded

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/models/event_model_test.dart

# Analyze code
flutter analyze --no-pub --fatal-infos

# Check formatting
dart format --set-exit-if-changed .
```

## How to Build

```bash
# Web (primary target)
flutter build web --release --web-renderer canvaskit

# Android
flutter build apk --release

# Run locally
flutter run -d chrome
```

## Dependencies

- `provider` / `flutter_bloc` — state management
- `firebase_auth` / `firebase_core` — authentication
- `sqflite` — local SQLite database
- `http` — HTTP client
- `flutter_secure_storage` — encrypted key-value storage
- `shared_preferences` — simple persistent storage
- `intl` — date/number formatting

## Notes for Agents

- Firebase initialization may fail in CI (no Firebase config). The app handles this gracefully — non-Firebase features still work.
- The `graph_service.dart` integrates with Microsoft Graph API but is currently stubbed.
- When adding new features, follow the existing pattern: model → repository → provider/bloc → view.
- All new code must pass `flutter analyze` and `dart format` checks.
