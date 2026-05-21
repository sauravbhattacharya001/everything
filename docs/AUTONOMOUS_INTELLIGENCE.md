# Autonomous Intelligence Layer

> Technical reference for the **autonomous intelligence** services that live in
> `lib/core/services/`. These are the engines that don't just store data — they
> actively analyze patterns, surface risks, and recommend interventions.

This document is aimed at contributors who want to:

- Understand how the engines are organized and what each one is responsible for.
- Wire a new engine into the app correctly (persistence, lifecycle, testing).
- Reuse the building blocks (Pearson correlation, exponential decay, EWMA,
  capacity budgets, etc.) without re-inventing them.

If you're looking for the **end-user** view of these features, see
[`FEATURES.md`](../FEATURES.md). If you want the high-level project README,
see [`README.md`](../README.md).

---

## 1. What counts as "autonomous"?

A regular tracker service answers questions the user asks ("what did I eat
today?"). An **autonomous** service answers questions the user *didn't ask but
should have* ("your decision quality has dropped 22% this week — defer the
contract review until tomorrow morning"). Concretely, an engine in this layer:

1. **Ingests passive signals** from one or more domains (habits, sleep, mood,
   calendar, finance, etc.).
2. **Maintains derived state** (e.g. rolling baselines, correlation matrices,
   resilience scores) on top of the raw user data.
3. **Detects events**: anomalies, thresholds crossed, patterns matched.
4. **Emits recommendations**: nudges, deferrals, batching suggestions,
   rebalancing plans — phrased as actionable advice, not raw numbers.

The engines never write back into other services' storage. They only read and
recommend. This keeps responsibility boundaries clean and makes each engine
independently testable.

---

## 2. Engine catalog

The intelligence layer currently contains **24 engines/detectors**, grouped
below by the kind of question they answer. Each entry links to the source file
so you can jump straight to the doc comments.

### 2.1 Cognitive load & attention

| Engine | File | What it watches |
|---|---|---|
| Decision Fatigue Detector | [`decision_fatigue_service.dart`](../lib/core/services/decision_fatigue_service.dart) | Decision count, weight, and quality across the day; flags fatigue and recommends batching/deferral. |
| Attention Debt Tracker | [`attention_debt_service.dart`](../lib/core/services/attention_debt_service.dart) | Deferred decisions and postponed tasks; models them as cognitive debt that accrues "interest". |
| Willpower Budget Engine | [`willpower_budget_service.dart`](../lib/core/services/willpower_budget_service.dart) | Cumulative cognitive demand vs. a depletable daily budget (ego-depletion model). |
| Context Switcher | [`context_switcher_service.dart`](../lib/core/services/context_switcher_service.dart) | Detects current life context (work / personal / fitness) and re-ranks tools. |
| Focus Entropy Engine | [`focus_entropy_engine_service.dart`](../lib/core/services/focus_entropy_engine_service.dart) | Shannon entropy of attention across domains; identifies deep-work blocks vs. scattered days. |

### 2.2 Behavior & habits

| Engine | File | What it watches |
|---|---|---|
| Behavioral Fingerprint | [`behavioral_fingerprint_service.dart`](../lib/core/services/behavioral_fingerprint_service.dart) | Multi-dimensional baseline of "what a normal day looks like for you"; flags deviations. |
| Habit Momentum | [`habit_momentum_service.dart`](../lib/core/services/habit_momentum_service.dart) | Cross-habit streaks and risk, with portfolio grading (A–F) and per-habit micro-interventions. |
| Habit Correlation Engine | [`habit_correlation_engine_service.dart`](../lib/core/services/habit_correlation_engine_service.dart) | Pearson + lagged correlations across habits, mood, sleep, energy. |
| Pattern Detector | [`pattern_detector_service.dart`](../lib/core/services/pattern_detector_service.dart) | Generic strong-correlation discovery across any tracked metric. |
| Momentum Engine | [`momentum_engine_service.dart`](../lib/core/services/momentum_engine_service.dart) | Completion velocity across tasks/habits/goals; classifies momentum state and emits nudges. |
| Adaptive Ritual Engine | [`ritual_engine_service.dart`](../lib/core/services/ritual_engine_service.dart) | Routine adherence, optimal timing windows, micro-adjustments. |

### 2.3 Wellness & resilience

| Engine | File | What it watches |
|---|---|---|
| Smart Burnout Detector | [`burnout_detector_service.dart`](../lib/core/services/burnout_detector_service.dart) | Multi-signal burnout risk + proactive recovery recommendations. |
| Stress Cascade Engine | [`stress_cascade_engine_service.dart`](../lib/core/services/stress_cascade_engine_service.dart) | Models how stress in one domain propagates to others; tracks resilience buffers. |
| Personal Drift Detector | [`drift_detector_service.dart`](../lib/core/services/drift_detector_service.dart) | "Boiling frog" early warning for gradual lifestyle regressions. |
| Chronotype Optimizer | [`chronotype_optimizer_service.dart`](../lib/core/services/chronotype_optimizer_service.dart) | Circadian peak windows per task type. |
| Friction Journal | [`friction_journal_service.dart`](../lib/core/services/friction_journal_service.dart) | Recurring micro-frustration tracking with elimination strategies. |

### 2.4 Decisions, goals, and life balance

| Engine | File | What it watches |
|---|---|---|
| Regret Minimization | [`regret_minimization_service.dart`](../lib/core/services/regret_minimization_service.dart) | Post-hoc decision-outcome analysis and bias detection. |
| Life Experiment Engine | [`experiment_engine_service.dart`](../lib/core/services/experiment_engine_service.dart) | Baseline vs. intervention experiments with significance scoring. |
| Goal Portfolio Optimizer | [`goal_portfolio_optimizer_service.dart`](../lib/core/services/goal_portfolio_optimizer_service.dart) | Weekly hour-budget greedy knapsack across competing goals. |
| Life Balance Radar | [`balance_radar_engine_service.dart`](../lib/core/services/balance_radar_engine_service.dart) | Variance/threshold analysis across 8 life dimensions. |
| Serendipity Engine | [`serendipity_engine_service.dart`](../lib/core/services/serendipity_engine_service.dart) | Mines cross-domain signals for unexpected, actionable connections. |

### 2.5 Social & financial

| Engine | File | What it watches |
|---|---|---|
| Social Capital Engine | [`social_capital_engine_service.dart`](../lib/core/services/social_capital_engine_service.dart) | Relationship strength with exponential decay, decay prediction, clustering. |
| Personal Runway Engine | [`runway_engine_service.dart`](../lib/core/services/runway_engine_service.dart) | "How long can I sustain my lifestyle if income stops?" with sensitivity analysis. |

---

## 3. Common building blocks

Most engines compose the same handful of statistical primitives. **Use the
shared helpers** in `lib/core/utils/` rather than re-implementing them — that's
what they exist for, and re-implementations have been a recurring source of
subtle bugs (off-by-one windows, sample vs. population variance, etc.).

| Primitive | Helper | When to use it |
|---|---|---|
| Mean / variance / stdDev | `lib/core/utils/stats_utils.dart` (`StatsUtils.mean`, `variance`, `stdDev`) | Anywhere you need summary statistics over a series. |
| Date utilities | `lib/core/utils/date_utils.dart` | Day-of-year math, week buckets, calendar normalisation. |
| Streak math | `lib/core/utils/date_streak_calculator.dart` | Any engine that exposes "current streak / best streak" semantics. |
| Collection helpers | `lib/core/utils/collection_utils.dart` | Grouping, windowing, top-N selection. |
| ID generation | `lib/core/utils/id_utils.dart` | Stable IDs for derived entities (recommendations, experiments, etc.). |

Engine-specific conventions:

- **Exponential decay** — when modelling decay-over-time (relationship
  strength, attention debt interest), pick a half-life in days and convert
  to `decay = exp(-ln(2) * elapsedDays / halfLifeDays)`. See
  `SocialCapitalEngine` for the canonical implementation.
- **EWMA / rolling baselines** — for "what's normal for this user", maintain
  an exponentially weighted moving average with a configurable α (default
  0.15 ≈ ~13-day half-life). `BehavioralFingerprint` is the reference.
- **Pearson correlation** — pairwise correlation lives inside
  `HabitCorrelationEngine`; if you need it elsewhere, **lift it into
  `StatsUtils`** rather than copy-pasting.
- **Capacity budgets** — when a service models a depletable daily resource
  (willpower, decision capacity), keep the budget calculation and the
  recommendation policy in separate methods so tests can pin them
  independently.

---

## 4. Anatomy of an engine

Every well-formed engine follows the same skeleton. You can use this as a
template when adding a new one.

```dart
class MyEngineService {
  // 1. State (in-memory). Persisted via persistent_state_mixin if needed.
  final List<MySignal> _signals = [];
  final Map<String, double> _baselines = {};

  // 2. Ingestion. Called by feature screens or by other services.
  void recordSignal(MySignal s) { _signals.add(s); _persist(); }

  // 3. Derived analytics. Pure functions over current state — no I/O,
  //    no side effects, easy to unit-test.
  MyEngineSummary computeSummary({DateTime? asOf}) { ... }

  // 4. Detection. Emits typed events (anomalies, thresholds crossed).
  List<MyEvent> detectEvents() { ... }

  // 5. Recommendations. Phrased as actionable advice with a confidence
  //    score and a rationale string the UI can render verbatim.
  List<MyRecommendation> recommend() { ... }
}
```

Rules of thumb:

- **Analytics methods must be pure.** That makes them trivially testable, and
  it's why every engine has 30–80 unit tests instead of integration tests.
- **No cross-engine writes.** Engines may read other services through
  constructor injection (see `EnergyBudgetPlannerService` for the pattern),
  but never mutate them.
- **Recommendations carry a rationale.** Never emit a bare score. Pair every
  recommendation with a short user-facing string explaining *why*.
- **Persist via the mixin.** Use `persistent_state_mixin.dart` so persistence,
  hydration, and crash-safety are uniform across engines.

---

## 5. Adding a new engine — checklist

When you propose a new autonomous engine, the PR should tick every box below.
Reviewers will check.

- [ ] Lives at `lib/core/services/<name>_engine_service.dart` (or
      `<name>_detector_service.dart` for pure detection).
- [ ] Class-level dartdoc comment explains: what signals it ingests,
      what it computes, what it recommends, and **what it does not do**.
- [ ] Uses `StatsUtils` / `DateUtils` / `DateStreakCalculator` rather than
      ad-hoc math.
- [ ] Persistence wired through `persistent_state_mixin`.
- [ ] **Unit tests** under `test/` covering: empty state, single-point input,
      synthetic happy path, edge cases (DST, leap years, very large N).
- [ ] Performance: any per-recompute work is **O(n)** in the relevant series
      length (no nested filter passes, no repeated sorts — see
      [PERFORMANCE.md](PERFORMANCE.md)).
- [ ] Registered in `lib/core/utils/feature_registry.dart` if it has a screen.
- [ ] Added to the table in section 2 of this document.

---

## 6. Testing strategy

Each engine has its own test file (e.g. `test/momentum_engine_test.dart`).
Tests fall into four buckets:

1. **Empty / boundary** — does the engine behave sanely with zero signals,
   one signal, or signals all on the same day?
2. **Deterministic synthetic** — given a hand-crafted series, do detection and
   recommendation outputs match what we computed by hand?
3. **Regression** — every time a bug is fixed in an engine, a test is added
   pinning the broken case. Don't delete these even if the code looks
   redundant.
4. **Performance smoke** — for engines that scale with signal history,
   include a test that runs the main compute path with N = 10 000 and
   asserts it stays under a generous wall-clock budget (often 100 ms).

Run the full suite with:

```bash
flutter test
```

To target one engine:

```bash
flutter test test/<engine>_test.dart
```

---

## 7. Where this is going

The intelligence layer is intentionally additive: existing engines stay stable,
and new ones plug in without coordinating with each other. Future work
generally falls into one of three buckets:

- **Cross-engine synthesis** — a meta-engine that consumes recommendations
  from multiple engines and prioritizes them ("of the 17 suggestions today,
  which 3 should the user actually see?").
- **Confidence calibration** — replacing hand-tuned thresholds with
  per-user calibrated baselines learned from history.
- **Explainability** — every recommendation already carries a rationale
  string; the next step is structured rationales (signal chains) the UI can
  render as an expandable "why?" panel.

Contributions in any of those directions are welcome — open an issue first
so we can sketch the contract before code lands.
