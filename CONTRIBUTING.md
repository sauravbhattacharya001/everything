# Contributing to Everything App

Thank you for considering contributing to Everything! This guide will help you get started.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Architecture Overview](#architecture-overview)
- [Making Changes](#making-changes)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Reporting Bugs](#reporting-bugs)
- [Requesting Features](#requesting-features)

## Code of Conduct

By participating in this project, you agree to treat all contributors with respect. Be constructive in discussions, welcome newcomers, and keep feedback focused on the code, not the person.

## Getting Started

### Prerequisites

| Tool | Version | Installation |
|------|---------|-------------|
| Flutter SDK | ≥3.10 | [flutter.dev/get-started](https://docs.flutter.dev/get-started/install) |
| Dart SDK | ≥3.0 | Included with Flutter |
| Android Studio / VS Code | Latest | With Flutter & Dart plugins |
| Git | Latest | [git-scm.com](https://git-scm.com) |

### Fork & Clone

```bash
# Fork via GitHub UI, then:
git clone https://github.com/<your-username>/everything.git
cd everything
git remote add upstream https://github.com/sauravbhattacharya001/everything.git
```

## Development Setup

```bash
# Install dependencies
flutter pub get

# Verify your environment
flutter doctor

# Run the app
flutter run

# Run tests to confirm everything works
flutter test
```

### Firebase Configuration

The app requires a Firebase project for authentication. See [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup) for instructions. Never commit Firebase config files or API keys to the repository.

Pass secrets at build time:

```bash
flutter run --dart-define=GOOGLE_API_KEY=your_key_here
```

## Architecture Overview

Everything follows a **layered architecture** with clear separation of concerns:

```
Views → Services → Providers/BLoC → Repositories → SQLite
                 ↘ External APIs (Graph, Firebase)
```

### Key Patterns

- **Service Layer** — `EventService` coordinates state (Provider) with persistence (Repository). Always use services from views; never call repositories directly.
- **O(1) Lookups** — `EventProvider` maintains an ID→index map. Preserve this invariant when modifying event state.
- **Security by Default** — All HTTP requests go through `HttpUtils` with URL validation and trusted-host allowlists. Never bypass this for outbound requests.
- **Fail-Safe Persistence** — UI state updates first, disk writes are fire-and-forget. Don't block the UI on I/O.
- **Typed Exceptions** — Auth errors use typed exception classes, not generic catches. Follow this pattern for new error-prone code.

### Directory Structure

| Directory | Purpose |
|-----------|---------|
| `lib/core/services/` | Business logic, API integration, coordination |
| `lib/core/utils/` | Shared utilities (dates, HTTP, validation) |
| `lib/data/` | SQLite database, repositories (data access) |
| `lib/models/` | Immutable data models with JSON serialization |
| `lib/state/` | Provider and BLoC state management |
| `lib/views/` | UI screens and reusable widgets |
| `test/` | Unit and widget tests, mirroring `lib/` structure |

## Making Changes

### Branch Naming

Create a descriptive branch from `master`:

```bash
git checkout master
git pull upstream master
git checkout -b <type>/<short-description>
```

Branch types:
- `feature/` — New functionality
- `fix/` — Bug fixes
- `refactor/` — Code restructuring (no behavior change)
- `docs/` — Documentation only
- `test/` — Adding or improving tests
- `perf/` — Performance improvements

Examples: `feature/recurring-events`, `fix/auth-state-restore`, `refactor/event-bloc-cleanup`

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `perf`, `ci`, `chore`

Examples:
```
feat(events): add recurring event support with daily/weekly patterns
fix(auth): handle Firebase network timeout with retry logic
test(models): add edge cases for EventModel.copyWith
```

### Keeping Your Fork Updated

```bash
git fetch upstream
git rebase upstream/master
# Resolve conflicts if any, then:
git push --force-with-lease origin <your-branch>
```

## Coding Standards

### Dart Style

- Follow the [Dart style guide](https://dart.dev/effective-dart/style) and [Flutter conventions](https://docs.flutter.dev/perf/best-practices)
- Run `flutter analyze` before committing — zero warnings required
- Use `flutter_lints` rules (already configured in the project)

### Specific Guidelines

1. **Null safety** — Use `required` parameters, avoid `!` (bang operator) unless the null case is truly impossible. Prefer `??`, `?.`, and pattern matching.

2. **Immutable models** — All model classes should be immutable with `copyWith` methods. Use `@immutable` annotation.

3. **No hardcoded secrets** — API keys, tokens, and credentials must be passed via `--dart-define` or `flutter_secure_storage`. Never commit secrets.

4. **HTTP security** — All outbound HTTP requests must use `HttpUtils` for URL validation. Never construct raw `http.get/post` calls without validation.

5. **Error handling** — Use typed exceptions for recoverable errors. Log internal details but surface user-friendly messages. Never expose stack traces to the UI.

6. **State management** — Use `Provider` for simple reactive state, `flutter_bloc` (Cubit) for complex flows with multiple transitions. Don't mix patterns within a single feature.

### File Organization

- One class per file (except small helper classes)
- Mirror `lib/` structure in `test/`
- Keep widget files in `views/widgets/`, screens in `views/<feature>/`

## Testing

### Running Tests

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Specific file
flutter test test/models/event_model_test.dart

# Specific test by name
flutter test --name "should serialize to JSON"
```

### Test Requirements

- **All PRs must include tests** for new or changed functionality
- **Minimum coverage** — Don't decrease overall coverage. New code should have ≥80% coverage.
- **Test structure** — Mirror `lib/` paths in `test/`. Use descriptive `group()` and `test()` names.

### What to Test

| Layer | What to Test | Example |
|-------|-------------|---------|
| Models | Serialization, copyWith, equality, edge cases | `event_model_test.dart` |
| Providers | State transitions, add/remove/update consistency | `event_provider_test.dart` |
| BLoC | Cubit state emissions, event handling | `event_bloc_test.dart` |
| Services | Coordination logic, error paths | `event_service_test.dart` |
| Utils | Validation, security constraints, edge cases | `http_utils_test.dart` |

### Test Naming Convention

```dart
group('EventModel', () {
  test('should create with required fields', () { ... });
  test('should serialize to JSON and back', () { ... });
  test('should handle null description gracefully', () { ... });
});
```

## Submitting a Pull Request

1. **Ensure tests pass** — `flutter test` must exit cleanly
2. **Run analysis** — `flutter analyze` with zero issues
3. **Push your branch** — `git push origin <your-branch>`
4. **Open a PR** on GitHub against `master`
5. **Fill out the PR template** — Description, type of change, testing, screenshots if UI
6. **Wait for CI** — All checks must pass (lint, tests, CodeQL, coverage)
7. **Address review feedback** — Push additional commits or amend as needed

### PR Tips

- Keep PRs focused — one feature or fix per PR
- Link related issues (`Fixes #123`)
- Add screenshots/recordings for UI changes
- If the PR is large, break it into smaller reviewable chunks
- Draft PRs are welcome for early feedback

## Reporting Bugs

Use the [Bug Report template](https://github.com/sauravbhattacharya001/everything/issues/new?template=bug_report.yml) on GitHub Issues. Include:

- Steps to reproduce
- Expected vs actual behavior
- Device/OS/Flutter version
- Screenshots or logs if applicable

## Requesting Features

Use the [Feature Request template](https://github.com/sauravbhattacharya001/everything/issues/new?template=feature_request.yml). Describe the problem you're solving, not just the solution you want.

## Questions?

Open a [Discussion](https://github.com/sauravbhattacharya001/everything/discussions) or file an issue tagged with `question`.

---

Thank you for helping make Everything better! 🎉
