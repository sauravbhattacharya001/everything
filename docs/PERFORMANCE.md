# Performance Engineering Guide

> How **Everything** stays fast at 199K+ lines, 230+ services, and a long
> history of incremental hot-path work.

This document is for contributors working in `lib/core/services/` or anywhere
else that runs analytics over user-tracked data. It captures the patterns the
codebase has settled on, the foot-guns the changelog already paid for, and the
non-negotiable rules every PR is held to.

If you're adding a new engine, read this **before** writing the compute loop.

---

## 1. Why this matters

The intelligence layer (see [`AUTONOMOUS_INTELLIGENCE.md`](AUTONOMOUS_INTELLIGENCE.md))
recomputes summaries, correlations, baselines and recommendations every time
the user opens a screen, every time a new signal lands, and — for some engines
— on a background timer. A single naive `O(n²)` loop over a year of daily
signals (~365 points) is invisible. Over five years of multi-tracker history
across 20 engines, the same pattern adds up to hundreds of ms of jank on every
foreground.

The historical changelog has multiple lines that boil down to "fixed N²-ish
loop, 9× speedup": those wins came from the same handful of patterns described
below. Internalize them and you won't have to be the next person to file one.

---

## 2. The complexity rules

The bar is simple:

| Recompute frequency | Allowed complexity |
|---|---|
| Per keystroke / per scroll frame | **O(1)** or **O(log n)** |
| Per signal recorded | **O(n)** in the affected series |
| Per screen open / per minute timer | **O(n)** in the relevant history window |
| Per-day batch / background sync | **O(n log n)** acceptable |
| Anything user-blocking | Never **O(n²)** over user history |

Anything worse than the row it lives in is a regression and will block review.

### Why "in the relevant series", not "in everything"

Most engines only care about a bounded window — the last 30, 90, or 365 days.
Slice once at the top of the compute function and pass the slice down; never
let downstream helpers re-filter the full history. This is the single most
common defect class in older code, and the single largest source of cleanup
wins in the changelog.

---

## 3. The shared statistics layer

`lib/core/utils/stats_utils.dart` is the canonical home for mean / variance /
standard deviation / pooled standard deviation. **Use it.**

- `StatsUtils.mean(values)`
- `StatsUtils.stdDev(values, [precomputedMean])` — sample (n − 1)
- `StatsUtils.populationVariance(values)` — population (n)
- `StatsUtils.pooledStdDev(s1, n1, s2, n2)` — Welch-style pooling
- `StatsUtils.sqrtSafe(value)` — safe square root, returns 0 for ≤ 0

Notes that matter:

1. **Pass the mean in once.** Several engines used to compute the mean inside
   `stdDev` after already computing it for display. `stdDev(values, mean)`
   exists exactly to avoid that second pass.
2. **Sample vs. population.** Most user-facing variability metrics want
   sample (n − 1). Sleep-schedule "consistency" intentionally uses population
   variance — that's why both exist.
3. **Don't re-derive primitives in your engine.** If you find yourself
   writing `_mean(values)` privately, lift it into `StatsUtils` instead.

---

## 4. Patterns and anti-patterns

The table below maps the recurring footgun (left) to the pattern that
replaces it (right). All of these have shown up in the codebase at least once
and have been cleaned up in prior performance passes.

| Anti-pattern | Replacement |
|---|---|
| `values.where(...).length` inside a loop body | Bucket once into a `Map<Key, int>` outside the loop |
| `values.sort()` inside a loop body | Sort once before the loop, or maintain a sorted index |
| `for (d in days) values.where((v) => sameDay(v, d))` — O(F × N) | Group `values` by day into a map first, then look up in O(1) — see `EnergyTrackerService` history (O(F×N) → O(F+N)) |
| Linear scan of a sorted history to find a window edge | Binary search (`dart:collection` or hand-rolled) — see `DriftDetectorService` (O(n) → O(log n)) |
| Repeated `DateTime` construction for "today" inside a loop | Hoist `final today = DateTime.now()` and pass it down |
| Walking the same list once per metric for stats | One pass that updates running sums for every metric simultaneously |
| Recomputing the same monthly history for each milestone | Hoist out of the milestone loop — this was the 9× win cited in v7.35 |
| Calling `someAsyncStore.read()` inside a tight loop | Read once, iterate over the in-memory copy |

---

## 5. The single-pass principle

If you find yourself writing two `.where(...)` calls or `.fold(...)` calls
over the same list back-to-back, fold them into one pass. Example:

```dart
// ❌ Three passes over the same list
final total = entries.fold<double>(0, (a, e) => a + e.value);
final count = entries.where((e) => e.value > 0).length;
final max   = entries.map((e) => e.value).fold<double>(0, math.max);

// ✅ One pass, three accumulators
double total = 0, max = 0;
int positive = 0;
for (final e in entries) {
  total += e.value;
  if (e.value > 0) positive++;
  if (e.value > max) max = e.value;
}
```

This pattern is what powers the "single-pass stats" notes in the v7.35 perf
section — `QuickCaptureService.getStats`, `getWeeklyReport`, and the
`WeeklyReportService` counting loop were all rewritten this way.

---

## 6. Date lookups

Date-keyed lookups are the single most common hot path. The cheap-and-correct
recipe is:

```dart
// Build once
final byDay = <DateTime, MyEntry>{};
for (final e in entries) {
  final key = DateUtils.dateOnly(e.timestamp); // normalize to midnight local
  byDay[key] = e;
}

// Look up in O(1)
final today = DateUtils.dateOnly(DateTime.now());
final entry = byDay[today];
```

Three things to watch for:

1. **Always normalize the key.** Two `DateTime`s that look the same to a human
   can differ by milliseconds, time zone, or DST offset. Use the helpers in
   `lib/core/utils/date_utils.dart` to collapse to a canonical day.
2. **DST.** Several streak calculators have been bitten by spring-forward — see
   `lib/core/utils/date_streak_calculator.dart` and issue history. If you're
   doing day arithmetic, go through that calculator or `DateUtils`, never
   `Duration(days: 1)`.
3. **Year-boundary cardinality.** `byDay` over five years of daily signals is
   ~1825 entries — fine. The same pattern over per-minute timer data is 2.6M
   entries — not fine. Aggregate timer data to days first.

---

## 7. Persistence is not free

`persistent_state_mixin.dart` makes saving state one line of code, but that
write goes through `SharedPreferences` (or `flutter_secure_storage` for
sensitive data) and serializes JSON. Rules:

- **Don't persist on every signal in a tight loop.** Batch the writes — accept
  the signals into in-memory state, then `_persist()` once at the end of the
  user action.
- **Don't persist derived state.** Re-derive on hydration. Persisting both
  raw signals and computed summaries means they can drift out of sync.
- **Sensitive data uses `flutter_secure_storage`.** That's slower than
  `SharedPreferences`. If a service mixes sensitive and non-sensitive fields,
  split them so the hot path stays on the fast backend.

---

## 8. Allocation pressure

Dart's GC handles short-lived garbage well, but the analytics layer can still
produce enough churn to show up as jank on lower-end devices.

- Prefer `for` loops over chained `.map().where().toList()` for hot paths.
  Chained iterables allocate intermediate `Iterable` objects on every link.
- Reuse `List<double>` / `Map<DateTime, double>` accumulators if a method is
  called repeatedly — but only when measurement shows it matters. Don't
  pre-optimize.
- For very large numeric series, consider `Float64List` over `List<double>` —
  it skips boxing and is roughly 2× faster to iterate.

---

## 9. Measuring

Before "optimizing" anything, measure. Dart and Flutter give you the tools:

```dart
final sw = Stopwatch()..start();
final result = engine.computeSummary();
sw.stop();
debugPrint('computeSummary took ${sw.elapsedMicroseconds}μs');
```

For more serious work, use Flutter DevTools' CPU profiler. The relevant
target: a cold compute on a year of history should finish in **under 16 ms**
on a mid-range device (one frame at 60 Hz). If it doesn't, the recompute is
either in the wrong place (move it off the build thread / cache it) or has
one of the anti-patterns from section 4.

For engines that scale with history, every test file should also contain a
**performance smoke test** that runs the main path with N = 10 000 and
asserts a wall-clock budget. Examples exist under `test/core/`.

---

## 10. Pre-PR checklist

Before opening a PR that touches an engine, a service compute path, or any
loop over user data:

- [ ] No method on a hot path is worse than the row in section 2 allows.
- [ ] No copy-pasted `_mean` / `_variance` — used `StatsUtils` instead.
- [ ] No `Iterable.where(...).length` or `.toList()` inside a per-day loop.
- [ ] Date keys go through `DateUtils` / `DateStreakCalculator`, not raw
      `Duration(days: 1)` arithmetic.
- [ ] Persistence is batched, not per-signal.
- [ ] If the change is performance-motivated, a micro-benchmark or smoke test
      pins the new behaviour and would catch a future regression.
- [ ] The PR description names the before/after complexity in a single line
      so reviewers don't have to reverse-engineer the win.

Stay honest about regressions: if a change makes one thing faster and another
slower, say so in the PR. Honest "I broke this on purpose, here's why"
beats silent regressions every time.
