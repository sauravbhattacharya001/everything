# Changelog

All notable changes to the Everything App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [7.31.0] - 2026-04-23

### Added
- **Smart Digital Detox Planner** — Autonomous screen time analysis with 4-tab dashboard: health score gauge with streak tracking, hour-of-day usage heatmap and day-of-week patterns, auto-generated detox schedule with adjustable reduction targets and predicted outcomes, and session history with success/fail tracking
- **Smart Burnout Detector** — Multi-signal burnout risk analysis monitoring 12 wellness signals across sleep, mood, energy, activity, social, and nutrition. Weighted risk scoring, 6 warning pattern detectors, resilience scoring, and phased recovery plans
- **Smart Energy Optimizer** — Autonomous energy prediction with circadian modeling, caffeine half-life decay, cross-tracker correlation, and proactive work/rest window recommendations. 4 energy profiles, 24-hour energy curves, and automatic deep work / creative / rest window detection
- **Smart Accountability Partner** — Cross-tracker commitment monitoring with proactive nudge engine, at-risk prediction, weekly trend charts, category breakdown, and one-tap completion

### Changed
- **ExpenseForecastService:** Single shared byCategory map eliminates 3× O(N) grouping passes; single-pass monthly totals replace O(months×N) filtering
- **SubscriptionTrackerService:** Single-pass `getSummary()` replaces ~10 separate linear scans
- **PasswordStrengthService:** Pre-compiled RegExp patterns, O(n) repeated-pattern check replaces O(n²) string concatenation
- **AppDateUtils:** Deduplicated `_sameDay` from 4 services into shared `isSameDay`

### Tests & Docs
- 56 new tests for CipherToolService and BaseConverterService
- Comprehensive docstrings for GameOfLifeService and AgeCalculatorService

## [7.30.0] - 2026-04-22

### Added
- **Expense Forecaster** — Autonomous spending prediction engine analyzing transaction history to forecast expenses, detect anomalies, and project budget burn rates
- **Smart Pattern Detector** — Cross-tracker correlation discovery using statistical analysis to find relationships between habits, goals, moods, and other tracked data
- **Daily Challenge Generator** — Gamified daily challenges with streak tracking, difficulty scaling, completion stats, and challenge history
- **Smart Streak Guardian** — Autonomous streak risk monitoring with configurable warning thresholds and recovery suggestions

## [7.29.0] - 2026-04-21

### Added
- **Goal Autopilot** — Autonomous goal monitoring with completion prediction, deadline tracking, and proactive alerts
- **Smart Habit Insights** — Autonomous habit pattern analysis with streak detection, consistency scoring, and personalized recommendations

### Changed
- **RoutineBuilderService:** Single-pass analytics with shared streak computation and indexed daily summary
- **DateStreakCalculator:** Extracted shared streak logic, deduplicated from 4 services (HabitTracker, GoalTracker, RoutineBuilder, WorkoutLog)

### Tests
- 56 tests for mortgage_calculator, tip_calculator, bmi_calculator, and roman_numeral services

### CI/CD
- Bump actions/deploy-pages from 4 to 5
- Bump actions/upload-pages-artifact from 4 to 5

<!-- Releases v3.1.0 through v7.28.0 were tracked via GitHub Releases but not recorded in this file. See https://github.com/sauravbhattacharya001/everything/releases for full history. -->

## [3.0.0] - 2026-03-07

### Added
- **Subscription Tracker Screen** — 4-tab UI for managing recurring subscriptions:
  - *Active tab:* Searchable list with category/status filters, detail bottom sheets, pause/resume/cancel
  - *Calendar tab:* 60-day renewal timeline with expiring trial alerts and urgency badges
  - *Insights tab:* Cost breakdown (daily/monthly/annual), category progress bars, duplicate/overlap detection
  - *Optimize tab:* Actionable savings suggestions (annual billing, high-cost review, trial decisions)
  - Includes add/edit dialog with sample data for immediate demo
- **Gratitude Journal Screen** — 4-tab journaling experience:
  - *Log tab:* Gratitude prompt cards, text + note input, category chips, intensity slider, daily stats
  - *Journal tab:* Chronological entries with search and category filtering
  - *Favorites tab:* Starred entries collection
  - *Insights tab:* 6 stat cards, category breakdowns, top tags, AI-generated insights
- **Skill Tracker Screen** — 4-tab learning progress UI:
  - *Skills tab:* View/filter/manage active & archived skills with category badges and level progress bars
  - *Practice tab:* Log sessions with duration, topic, notes, quality rating; quick stats panel
  - *Milestones tab:* Per-skill milestone management with completion tracking and reorderable lists
  - *Portfolio tab:* Learning overview with streak tracking, category breakdowns, letter grades

### Security
- Added import size limits to 5 services that were missing bounds checks:
  `AchievementService` (50K), `ReadingListService` (50K), `WorkoutTrackerService` (100K),
  `MeditationTrackerService` (100K), `MealTrackerService` (100K) — prevents memory
  exhaustion from maliciously crafted JSON payloads (CWE-400)
- `AchievementService.loadFromJson` now parses into a temporary map before clearing
  existing data, preventing data loss on malformed imports

## [2.0.0] - 2026-03-07

Major release adding 15+ tracker services, full UI screens, and comprehensive
wellness/productivity features.

### Added — Tracker Services & Screens
- **Meal/Nutrition Tracker** — 6 meal types, 9 food categories, macros tracking, daily summaries with A-F grading, weekly trends, smart insights engine
- **Water Intake Tracker** — 9 drink types with hydration factors, hourly pacing, streak tracking, weekly trends, smart tips
- **Workout Tracker** — exercise logging, personal records (PRs), streaks, muscle balance analysis
- **Reading List/Book Tracker** — library management, reading stats, challenge mode, recommendations
- **Meditation Tracker** — session logging, mood analysis, streaks, technique insights
- **Expense Tracker** — expense logging, monthly budget summaries, category analytics
- **Subscription Tracker** — billing management, renewal calendar, duplicate detection, price increase analysis, optimization suggestions (55 tests)
- **Contact/People Tracker** — interaction logging, follow-up tracking, network health scoring
- **Sleep Tracker** — logging, history, insights
- **Mood Journal** — mood logging, history, pattern analysis
- **Gratitude Journal** — categories, intensity, weekly reports, writing prompts
- **Energy Level Tracker** — time-of-day patterns, factor analysis
- **Learning/Skill Tracker** — skill progress tracking
- **Decision Journal** — track decisions, outcomes, confidence calibration
- **Screen Time Tracker** — usage monitoring service
- **Daily Routine Builder** — step tracking and analytics

### Added — Productivity Tools
- **Pomodoro Timer** screen with circular countdown, phase transitions, daily stats
- **Eisenhower Matrix** — urgency/importance prioritization service
- **Productivity Score Service** — 6-dimension composite scoring
- **Focus Time Service** — deep work block analysis, schedule fragmentation scoring
- **Free Slot Finder** — discover available calendar time slots
- **Time Audit Service** — deep time allocation analysis
- **Weekly Planner** — structured week planning service
- **Event Pattern Recognizer** — detect recurring scheduling patterns
- **Cross-Domain Correlation Analyzer** — connect patterns across services
- **Achievement System** — gamification across all trackers

### Added — Core Features
- **Calendar View** — month-grid with event dots and day detail
- **Daily Agenda Timeline** — hour markers, now indicator, day navigation
- **Event Countdown Screen** — live timers for upcoming events
- **Weekly Report Screen** — visual charts with week navigation
- **Daily Review Screen** — mood/energy tracking, day comparison
- **Habit Tracker Screen** — daily checklist, progress ring, stats
- **Next Up Countdown Banner** on home screen
- **Event Templates** — pre-defined and custom templates for quick creation
- **Event Reminders** — configurable notification timing
- **ICS/iCal Export** for calendar app interop
- **Event Checklist (subtasks)** for task tracking within events
- **Event Attachments** — file/photo/link support
- **Recurring Events** — daily/weekly/monthly/yearly recurrence rules
- **Event Location** with travel time estimation
- **Event Tags/Categories** for organizing events
- **Event Search Service** — full-text search, filters, suggestions
- **Event Dependency Tracker** — link events as blockers/dependencies
- **Event Deduplication Service** — detect and merge duplicate events
- **Snooze Service** — event postponement with history tracking
- **Event Sharing** — plain text, markdown, Google Calendar & Outlook URLs
- **Time Budget Service** — allocation analysis across tags and priorities
- **Activity Heatmap** — year-at-a-glance event density
- **Weekly Agenda Digest** — formatted summaries for upcoming days
- **Streak Tracker** — consecutive-day activity analysis with motivational messages
- **Conflict Detector** — scheduling proximity analysis with suggestions
- **Weekly Report Service** — productivity summaries
- **Event Analytics Dashboard** — stats, charts, insights

### Fixed
- `setState()` after `await` without mounted guards (#40)
- Multi-day events not split across calendar days
- Negative durations in time calculations
- Streak calculation for non-daily routine schedules
- `DateTime.parse` crash on corrupted data (replaced with `tryParse`)
- `isSameDay` / `dateOnly` extracted to shared `AppDateUtils`
- `ConflictDetector` ignoring `endDate` causing missed overlaps
- ICS line folding now counts UTF-8 octets, not characters (#19)
- URI scheme validation on link attachments
- `getLoggingStreak` anchored to today/yesterday (#38)
- `timeAgo` shows weeks/months/years instead of raw day counts
- Missing `_pairKey` method in `EventDeduplicationService` (#36)
- Dead code in `SnoozeSummary.totalDelay` removed
- Data loss on malformed imports + missing DB columns
- Stray submodule reference removed

### Changed
- Extracted routine models into dedicated `models/routine.dart`
- Extracted `EventService` to eliminate duplicated persistence logic
- Extracted shared formatting utilities into `FormattingUtils`
- Extracted sample data from `DailyReviewScreen` into dedicated file
- Replaced `try/firstWhere/catch` with idiomatic patterns
- Token-based Jaccard similarity for long descriptions
- Removed 317 lines of dead code

### Security
- Hardened auth error messages (no user enumeration)
- Bounded import sizes to prevent memory abuse
- Table name whitelist in `LocalStorage`
- Validated `EventLocation` coordinates
- Hardened ICS filenames (no path traversal)

### Performance
- O(1) event lookup index with cached filtered results
- Pre-extracted variable values to eliminate sublist allocations
- Optimized `EventSearchService` filter and sort hot paths
- Optimized `EventDeduplicationService` hot paths
- Adjacency index maps for `EventDependencyTracker`


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
