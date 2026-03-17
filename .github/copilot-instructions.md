# Everything - Copilot Instructions

## Project Overview
Everything is a Flutter-based all-in-one productivity app. It manages calendars, events, habits, goals, finances, health tracking, and dozens of other life-management features through a unified interface.

## Architecture
- **State management:** Provider + flutter_bloc (BLoC pattern for events)
- **Storage:** SQLite via sqflite for local persistence; SharedPreferences for settings
- **Auth:** Firebase Auth + Firebase Core
- **Structure:**
  - `lib/models/` — Data models (immutable where possible, with `toMap()`/`fromMap()` serialization)
  - `lib/core/services/` — Business logic services (one per feature, stateful via ChangeNotifier)
  - `lib/core/utils/` — Shared utilities (date formatting, feature registry)
  - `lib/state/` — BLoC and Provider state management
  - `lib/views/home/` — Feature screens (one per tracker/tool)
  - `lib/views/widgets/` — Shared UI components
  - `test/` — Unit and widget tests

## Conventions
- Services extend `ChangeNotifier` and use a `PersistentStateMixin` for local storage
- Each feature screen is self-contained in its own file under `views/home/`
- Models use `Map<String, dynamic>` serialization (toMap/fromMap pattern)
- Tests mirror the source structure; service tests are in `test/core/`
- Dart SDK >=3.0.0, Flutter >=3.10.0

## Testing
```bash
flutter test                    # Run all tests
flutter test test/core/         # Run service tests only
flutter test --coverage         # With coverage
```

## Key Dependencies
- `provider` ^6.1.0, `flutter_bloc` ^8.1.0 — state management
- `sqflite` ^2.3.0 — local database
- `firebase_auth` ^4.16.0, `firebase_core` ^2.25.0 — authentication
- `intl` ^0.20.2 — date/number formatting
- `share_plus` ^12.0.1 — share functionality

## Notes
- No web or desktop targets currently — mobile (Android/iOS) focus
- The `feature_registry.dart` in utils maps feature names to screens
- Many services follow identical patterns — use existing services as templates when adding new features
