# Changelog

All notable changes to **Everything** are documented in this file.
This project follows [Semantic Versioning](https://semver.org/).

## [7.35.0] - 2026-05-17

### ✨ Features — 16 new autonomous engines & advisors
- **HabitMomentumService** — cross-habit streak/risk advisor with per-habit micro-interventions and A–F portfolio grading
- **GoalPortfolioOptimizerService** — cross-goal weekly trade-off with greedy knapsack allocation under a weekly hour budget
- **ChronotypeOptimizerService** — circadian rhythm analyzer with per-task-type peak windows
- **StressCascadeEngine** — propagation analyzer and resilience score
- **FocusEntropyEngine** — focus-fragmentation detector
- **HabitCorrelationEngine** — cross-tracker correlation discovery
- **SocialCapitalEngine** — relationship-network health analyzer
- **PersonalRunwayEngine** — financial-resilience calculator
- **LifeBalanceRadarEngine** — multi-dimensional life balance assessment
- **SerendipityEngine** — cross-domain connection discovery
- **DecisionFatigueDetector** — decision-quality monitor with O(n) optimized score pipeline
- **FrictionJournalEngine** — micro-frustration tracker
- **RegretMinimizationEngine** — decision-outcome analysis
- **AttentionDebtTracker** — cognitive-overhead monitor
- **PersonalDriftDetector** — lifestyle-regression early-warning
- **LifeExperimentEngine** — self-experimentation framework
- **MomentumEngine**, **BehavioralFingerprintEngine**, **WillpowerBudgetEngine**

### ⚡ Performance
- Eliminated redundant O(n log n) sorts and O(n) filter passes in DecisionFatigueService
- Hoisted monthlyHistory out of milestones loop — **9× reduction** in repeated work
- Single-pass stats in `QuickCaptureService.getStats` / `getWeeklyReport`
- O(1) date lookups in `DailyReviewService`; single-pass counting in `WeeklyReportService`
- O(F×N) → O(F+N) in `EnergyTrackerService`

### 🐛 Bug Fixes
- Depth-bounded JSON tree analysis + wiki import size limits (security hardening)
- Corrected multi-year lookback in `NetWorthTrackerService.monthlyHistory`

### 🧰 Refactoring
- Extracted shared `StatsUtils` — deduplicated mean/stdDev/variance across services
- Removed unused imports and duplicate helpers across the service layer

### 📚 Documentation
- Comprehensive README + `FEATURES.md` overhaul — **200+** features cataloged
- New docs site pages: Autonomous Intelligence API reference (9 self-monitoring engines), Finance & Budgeting, Games & Recreation
- Dartdoc added to `DigitalDetoxService` and all model classes
- Dartdoc added to `HabitMomentumService` and `GoalPortfolioOptimizerService`
- 6 additional service files received comprehensive dartdoc

### 🧪 Tests & Quality
- +30 tests for `BurnoutDetectorService`
- New test suites: `regret_minimization_test.dart`, `runway_engine_test.dart`, `social_capital_engine_test.dart`, `stress_cascade_engine_test.dart`
- `codecov.yml` added — coverage thresholds enforced in CI

### 🛠 Maintenance
- Trivy vulnerability scanning, SBOM generation and attestation in Docker workflow
- New issue templates: platform regression, widget/UI, accessibility, data/storage
- Auto-labeler for content-based issue triage
- Release automation workflow + `CHANGELOG.md`
- Dependabot bumps: `github/codeql-action` 3→4, `actions/attest-sbom` 2→4, `actions/github-script` 7→9, `aquasecurity/trivy-action` 0.28.0→0.36.0, `cirruslabs/flutter` 3.41.6→3.41.9

### 📊 Scope
- **51 commits** since v7.34.0 • **101 files changed** • **+40,148 / −460** lines

## [1.0.0] - 2026-04-29

### ✨ Features
- Attention Debt Tracker — autonomous cognitive overhead monitor
- Adaptive Ritual Engine — autonomous daily ritual optimizer
- Willpower Budget Engine — autonomous cognitive resource manager
- Behavioral Fingerprint Engine — autonomous behavioral signature analysis
- ContactTrackerService, EnergyTrackerService, DriftDetectorService
- Finance & budgeting module

### ⚡ Performance
- O(log n) binary search in DriftDetectorService
- Eliminate redundant O(F×N) iterations in EnergyTrackerService

### 🐛 Bug Fixes
- Depth-bounded JSON tree analysis + wiki import size limits (security)

### ♻️ Refactoring
- Extract shared IdUtils, remove unused imports and duplicate helpers

### 🔧 Maintenance
- Docker image with Trivy vulnerability scanning, SBOM generation and attestation
- GitHub Actions CI, CodeQL, coverage, Pages deploy
- Auto-labeling with stale bot, PR size labels
