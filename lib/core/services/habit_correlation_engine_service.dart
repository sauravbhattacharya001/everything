import 'dart:math';

/// Habit Correlation Engine — autonomous cross-tracker correlation discovery.
///
/// Finds hidden connections between habits, mood, sleep, energy, and other
/// tracked metrics using Pearson correlation, lagged analysis, synergy
/// detection, anti-pattern discovery, and day-of-week timing optimization.
///
/// 7 engines:
/// 1. **Signal Extractor** — converts tracker data to daily numeric signals
/// 2. **Correlation Computer** — Pearson r with same-day and lagged analysis
/// 3. **Causal Hypothesis Generator** — directional hypotheses for strong correlations
/// 4. **Habit Synergy Detector** — finds habit combos that boost outcomes
/// 5. **Anti-Pattern Detector** — surfaces counterintuitive negative correlations
/// 6. **Optimal Timing Analyzer** — day-of-week pattern analysis
/// 7. **Insight Generator** — synthesizes ranked actionable insights

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Strength classification of a Pearson correlation.
enum CorrelationStrength {
  strong,
  moderate,
  weak,
  negligible;

  String get label {
    switch (this) {
      case CorrelationStrength.strong:
        return 'Strong';
      case CorrelationStrength.moderate:
        return 'Moderate';
      case CorrelationStrength.weak:
        return 'Weak';
      case CorrelationStrength.negligible:
        return 'Negligible';
    }
  }

  String get emoji {
    switch (this) {
      case CorrelationStrength.strong:
        return '🔗';
      case CorrelationStrength.moderate:
        return '🔀';
      case CorrelationStrength.weak:
        return '〰️';
      case CorrelationStrength.negligible:
        return '·';
    }
  }
}

/// Categories of generated insights.
enum InsightCategory {
  discovery,
  warning,
  recommendation,
  synergy,
  timing;

  String get label {
    switch (this) {
      case InsightCategory.discovery:
        return 'Discovery';
      case InsightCategory.warning:
        return 'Warning';
      case InsightCategory.recommendation:
        return 'Recommendation';
      case InsightCategory.synergy:
        return 'Synergy';
      case InsightCategory.timing:
        return 'Timing';
    }
  }

  String get emoji {
    switch (this) {
      case InsightCategory.discovery:
        return '🔬';
      case InsightCategory.warning:
        return '⚠️';
      case InsightCategory.recommendation:
        return '💡';
      case InsightCategory.synergy:
        return '🤝';
      case InsightCategory.timing:
        return '⏰';
    }
  }
}

/// Priority of a generated insight.
enum InsightPriority {
  critical,
  high,
  medium,
  low;

  String get label {
    switch (this) {
      case InsightPriority.critical:
        return 'Critical';
      case InsightPriority.high:
        return 'High';
      case InsightPriority.medium:
        return 'Medium';
      case InsightPriority.low:
        return 'Low';
    }
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// A single daily numeric signal extracted from a tracker.
class DailySignal {
  final String name;
  final DateTime date;
  final double value;

  const DailySignal({
    required this.name,
    required this.date,
    required this.value,
  });
}

/// Result of a Pearson correlation between two signals.
class CorrelationResult {
  final String signalA;
  final String signalB;
  final double r;
  final double pValue;
  final CorrelationStrength strength;
  final int lagDays;
  final String interpretation;

  const CorrelationResult({
    required this.signalA,
    required this.signalB,
    required this.r,
    required this.pValue,
    required this.strength,
    required this.lagDays,
    required this.interpretation,
  });
}

/// A directional causal hypothesis derived from lagged correlation.
class CausalHypothesis {
  final String cause;
  final String effect;
  final double confidence;
  final int lagDays;
  final String experiment;

  const CausalHypothesis({
    required this.cause,
    required this.effect,
    required this.confidence,
    required this.lagDays,
    required this.experiment,
  });
}

/// Result of habit synergy analysis.
class SynergyResult {
  final List<String> habits;
  final String outcome;
  final double synergyScore;
  final double combinedEffect;
  final double individualSum;

  const SynergyResult({
    required this.habits,
    required this.outcome,
    required this.synergyScore,
    required this.combinedEffect,
    required this.individualSum,
  });
}

/// A negative or counterintuitive correlation pattern.
class AntiPattern {
  final String habit;
  final String outcome;
  final double r;
  final String explanation;
  final String recommendation;

  const AntiPattern({
    required this.habit,
    required this.outcome,
    required this.r,
    required this.explanation,
    required this.recommendation,
  });
}

/// Day-of-week timing insight for a habit-outcome pair.
class TimingInsight {
  final String habit;
  final String outcome;
  final int bestDayOfWeek;
  final double bestDayEffect;
  final int worstDayOfWeek;
  final double worstDayEffect;

  const TimingInsight({
    required this.habit,
    required this.outcome,
    required this.bestDayOfWeek,
    required this.bestDayEffect,
    required this.worstDayOfWeek,
    required this.worstDayEffect,
  });

  static const List<String> dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get bestDayName => dayNames[bestDayOfWeek - 1];
  String get worstDayName => dayNames[worstDayOfWeek - 1];
}

/// A ranked actionable insight generated by the engine.
class CorrelationInsight {
  final InsightCategory category;
  final InsightPriority priority;
  final String title;
  final String description;
  final String actionItem;
  final double confidence;

  const CorrelationInsight({
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    required this.actionItem,
    required this.confidence,
  });
}

/// Complete correlation analysis report.
class CorrelationReport {
  final double networkHealth;
  final int daysAnalyzed;
  final int totalSignals;
  final List<CorrelationResult> correlations;
  final List<CausalHypothesis> hypotheses;
  final List<SynergyResult> synergies;
  final List<AntiPattern> antiPatterns;
  final List<TimingInsight> timingInsights;
  final List<CorrelationInsight> insights;

  const CorrelationReport({
    required this.networkHealth,
    required this.daysAnalyzed,
    required this.totalSignals,
    required this.correlations,
    required this.hypotheses,
    required this.synergies,
    required this.antiPatterns,
    required this.timingInsights,
    required this.insights,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Autonomous habit correlation engine service.
class HabitCorrelationEngineService {
  final Map<String, List<DailySignal>> _signals = {};
  final Random _rng = Random(42);

  // ── Engine 1: Signal Extractor ──

  /// Load 90 days of realistic sample data with built-in correlations.
  void loadSampleData() {
    _signals.clear();
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 89));
    const habits = ['Exercise', 'Meditation', 'Reading', 'Journaling', 'Caffeine'];
    const outcomes = ['Mood', 'Sleep', 'Energy'];

    // Initialize signal lists.
    for (final name in [...habits, ...outcomes]) {
      _signals[name] = [];
    }

    for (int d = 0; d < 90; d++) {
      final date = DateTime(start.year, start.month, start.day + d);
      final weekday = date.weekday; // 1=Mon, 7=Sun

      // Habits: 0 or 1 with varying base probabilities.
      final exercise = (_rng.nextDouble() < (weekday <= 5 ? 0.7 : 0.4)) ? 1.0 : 0.0;
      final meditation = (_rng.nextDouble() < 0.55) ? 1.0 : 0.0;
      final reading = (_rng.nextDouble() < (weekday >= 6 ? 0.8 : 0.5)) ? 1.0 : 0.0;
      final journaling = (_rng.nextDouble() < 0.45) ? 1.0 : 0.0;
      final caffeine = (_rng.nextDouble() < 0.65) ? 1.0 : 0.0;

      _signals['Exercise']!.add(DailySignal(name: 'Exercise', date: date, value: exercise));
      _signals['Meditation']!.add(DailySignal(name: 'Meditation', date: date, value: meditation));
      _signals['Reading']!.add(DailySignal(name: 'Reading', date: date, value: reading));
      _signals['Journaling']!.add(DailySignal(name: 'Journaling', date: date, value: journaling));
      _signals['Caffeine']!.add(DailySignal(name: 'Caffeine', date: date, value: caffeine));

      // Outcomes: 1-5 scale, influenced by habits with noise.
      // Exercise → better sleep (lagged by 1 day) and better energy (same day).
      final prevExercise = d > 0 ? _signals['Exercise']![d - 1].value : 0.0;
      final prevCaffeine = d > 0 ? _signals['Caffeine']![d - 1].value : 0.0;

      final sleepBase = 3.0 + prevExercise * 0.8 - prevCaffeine * 0.6 + meditation * 0.3;
      final sleep = (sleepBase + (_rng.nextDouble() - 0.5) * 1.5).clamp(1.0, 5.0);

      final moodBase = 3.0 + meditation * 0.7 + exercise * 0.4 + journaling * 0.3;
      final mood = (moodBase + (_rng.nextDouble() - 0.5) * 1.5).clamp(1.0, 5.0);

      final energyBase = 2.5 + exercise * 0.8 + sleep * 0.3 - caffeine * 0.1;
      final energy = (energyBase + (_rng.nextDouble() - 0.5) * 1.2).clamp(1.0, 5.0);

      _signals['Sleep']!.add(DailySignal(name: 'Sleep', date: date, value: sleep));
      _signals['Mood']!.add(DailySignal(name: 'Mood', date: date, value: mood));
      _signals['Energy']!.add(DailySignal(name: 'Energy', date: date, value: energy));
    }
  }

  /// Add custom signal data (for integration with real tracker data).
  void addSignals(String name, List<DailySignal> signals) {
    _signals[name] = signals;
  }

  /// Get all signal names currently loaded.
  List<String> get signalNames => _signals.keys.toList();

  /// Get signals for a given name.
  List<DailySignal> getSignals(String name) => _signals[name] ?? [];

  /// Number of days of data available (minimum across all signals).
  int get daysAvailable {
    if (_signals.isEmpty) return 0;
    return _signals.values.map((s) => s.length).reduce(min);
  }

  // ── Engine 2: Correlation Computer ──

  /// Compute Pearson correlation between two signal arrays.
  static double pearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 3) return 0.0;
    final n = x.length;
    final mx = x.reduce((a, b) => a + b) / n;
    final my = y.reduce((a, b) => a + b) / n;

    double sumXY = 0, sumX2 = 0, sumY2 = 0;
    for (int i = 0; i < n; i++) {
      final dx = x[i] - mx;
      final dy = y[i] - my;
      sumXY += dx * dy;
      sumX2 += dx * dx;
      sumY2 += dy * dy;
    }
    final denom = sqrt(sumX2) * sqrt(sumY2);
    return denom == 0 ? 0.0 : sumXY / denom;
  }

  /// Approximate p-value for a Pearson r using t-distribution.
  static double approximatePValue(double r, int n) {
    if (n < 4 || r.abs() >= 1.0) return r.abs() >= 1.0 ? 0.0 : 1.0;
    final t = r * sqrt((n - 2) / (1 - r * r));
    final df = n - 2;
    // Approximation using the incomplete beta regularized function.
    // For simplicity, use a t-to-p approximation for large df.
    final x = df / (df + t * t);
    // Simple approximation: use normal CDF for large samples.
    final z = t.abs();
    // Abramowitz & Stegun approximation of the normal CDF complement.
    final p = _normalCdfComplement(z);
    return (2 * p).clamp(0.0, 1.0); // two-tailed
  }

  static double _normalCdfComplement(double z) {
    // Abramowitz & Stegun formula 26.2.17
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;
    final t = 1.0 / (1.0 + p * z.abs());
    final poly = ((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t;
    final cdf = poly * exp(-z * z / 2);
    return z >= 0 ? cdf : 1.0 - cdf;
  }

  /// Classify correlation strength.
  static CorrelationStrength classifyStrength(double r) {
    final abs = r.abs();
    if (abs >= 0.6) return CorrelationStrength.strong;
    if (abs >= 0.4) return CorrelationStrength.moderate;
    if (abs >= 0.2) return CorrelationStrength.weak;
    return CorrelationStrength.negligible;
  }

  /// Compute all pairwise correlations with optional lag.
  List<CorrelationResult> computeCorrelations({int maxLag = 2}) {
    final results = <CorrelationResult>[];
    final names = signalNames;

    for (int i = 0; i < names.length; i++) {
      for (int j = i + 1; j < names.length; j++) {
        final a = _signals[names[i]]!;
        final b = _signals[names[j]]!;

        for (int lag = 0; lag <= maxLag; lag++) {
          if (a.length <= lag || b.length <= lag) continue;

          List<double> xVals, yVals;
          String interpretation;

          if (lag == 0) {
            final len = min(a.length, b.length);
            xVals = a.sublist(0, len).map((s) => s.value).toList();
            yVals = b.sublist(0, len).map((s) => s.value).toList();
          } else {
            // a leads b by `lag` days.
            final len = min(a.length - lag, b.length);
            xVals = a.sublist(0, len).map((s) => s.value).toList();
            yVals = b.sublist(lag, lag + len).map((s) => s.value).toList();
          }

          final r = pearsonCorrelation(xVals, yVals);
          final pVal = approximatePValue(r, xVals.length);
          final strength = classifyStrength(r);

          if (strength == CorrelationStrength.negligible) continue;

          if (lag == 0) {
            final dir = r > 0 ? 'positively' : 'negatively';
            interpretation = '${names[i]} and ${names[j]} are $dir correlated on the same day';
          } else {
            final dir = r > 0 ? 'better' : 'worse';
            interpretation = '${names[i]} correlates with $dir ${names[j]} $lag day(s) later';
          }

          results.add(CorrelationResult(
            signalA: names[i],
            signalB: names[j],
            r: r,
            pValue: pVal,
            strength: strength,
            lagDays: lag,
            interpretation: interpretation,
          ));

          // Also check reverse lag (b leads a).
          if (lag > 0) {
            final rLen = min(b.length - lag, a.length);
            final rxVals = b.sublist(0, rLen).map((s) => s.value).toList();
            final ryVals = a.sublist(lag, lag + rLen).map((s) => s.value).toList();
            final rr = pearsonCorrelation(rxVals, ryVals);
            final rpVal = approximatePValue(rr, rxVals.length);
            final rStrength = classifyStrength(rr);
            if (rStrength != CorrelationStrength.negligible) {
              final rDir = rr > 0 ? 'better' : 'worse';
              results.add(CorrelationResult(
                signalA: names[j],
                signalB: names[i],
                r: rr,
                pValue: rpVal,
                strength: rStrength,
                lagDays: lag,
                interpretation:
                    '${names[j]} correlates with $rDir ${names[i]} $lag day(s) later',
              ));
            }
          }
        }
      }
    }

    results.sort((a, b) => b.r.abs().compareTo(a.r.abs()));
    return results;
  }

  // ── Engine 3: Causal Hypothesis Generator ──

  /// Generate causal hypotheses for strong lagged correlations.
  List<CausalHypothesis> generateHypotheses(List<CorrelationResult> correlations) {
    final hypotheses = <CausalHypothesis>[];

    for (final c in correlations) {
      if (c.lagDays == 0) continue;
      if (c.r.abs() < 0.3) continue;

      final direction = c.r > 0 ? 'improves' : 'worsens';
      final confidence = c.r.abs();
      final experiment =
          'Try ${c.r > 0 ? "consistently doing" : "skipping"} ${c.signalA} for 2 weeks and track ${c.signalB}';

      hypotheses.add(CausalHypothesis(
        cause: c.signalA,
        effect: c.signalB,
        confidence: confidence,
        lagDays: c.lagDays,
        experiment:
            '${c.signalA} $direction ${c.signalB} after ${c.lagDays} day(s). $experiment.',
      ));
    }

    hypotheses.sort((a, b) => b.confidence.compareTo(a.confidence));
    return hypotheses;
  }

  // ── Engine 4: Habit Synergy Detector ──

  /// Find habit combinations that produce better outcomes than individually.
  List<SynergyResult> detectSynergies() {
    final synergies = <SynergyResult>[];
    const habitNames = ['Exercise', 'Meditation', 'Reading', 'Journaling'];
    const outcomeNames = ['Mood', 'Sleep', 'Energy'];

    for (final outcome in outcomeNames) {
      final outcomeSignals = _signals[outcome];
      if (outcomeSignals == null) continue;

      for (int i = 0; i < habitNames.length; i++) {
        final habitA = _signals[habitNames[i]];
        if (habitA == null) continue;

        for (int j = i + 1; j < habitNames.length; j++) {
          final habitB = _signals[habitNames[j]];
          if (habitB == null) continue;

          final len =
              [habitA.length, habitB.length, outcomeSignals.length].reduce(min);

          // Collect outcome values for different habit combinations.
          final bothDone = <double>[];
          final onlyA = <double>[];
          final onlyB = <double>[];
          final neither = <double>[];

          for (int d = 0; d < len; d++) {
            final a = habitA[d].value > 0.5;
            final b = habitB[d].value > 0.5;
            final o = outcomeSignals[d].value;

            if (a && b) {
              bothDone.add(o);
            } else if (a) {
              onlyA.add(o);
            } else if (b) {
              onlyB.add(o);
            } else {
              neither.add(o);
            }
          }

          if (bothDone.length < 3 || onlyA.isEmpty || onlyB.isEmpty || neither.isEmpty) {
            continue;
          }

          final avgBoth = bothDone.reduce((a, b) => a + b) / bothDone.length;
          final avgA = onlyA.reduce((a, b) => a + b) / onlyA.length;
          final avgB = onlyB.reduce((a, b) => a + b) / onlyB.length;
          final avgNeither = neither.reduce((a, b) => a + b) / neither.length;

          final effectA = avgA - avgNeither;
          final effectB = avgB - avgNeither;
          final combinedEffect = avgBoth - avgNeither;
          final individualSum = effectA + effectB;
          final synergyScore =
              individualSum != 0 ? combinedEffect / individualSum : 0.0;

          if (synergyScore > 1.05) {
            // Meaningful synergy (>5% boost).
            synergies.add(SynergyResult(
              habits: [habitNames[i], habitNames[j]],
              outcome: outcome,
              synergyScore: synergyScore,
              combinedEffect: combinedEffect,
              individualSum: individualSum,
            ));
          }
        }
      }
    }

    synergies.sort((a, b) => b.synergyScore.compareTo(a.synergyScore));
    return synergies;
  }

  // ── Engine 5: Anti-Pattern Detector ──

  /// Find habits that negatively correlate with outcomes.
  List<AntiPattern> detectAntiPatterns(List<CorrelationResult> correlations) {
    final antiPatterns = <AntiPattern>[];
    const outcomeNames = {'Mood', 'Sleep', 'Energy'};

    for (final c in correlations) {
      if (c.r >= 0) continue; // Only negative correlations.
      // One of the pair must be an outcome.
      String? habit, outcome;
      if (outcomeNames.contains(c.signalB)) {
        habit = c.signalA;
        outcome = c.signalB;
      } else if (outcomeNames.contains(c.signalA)) {
        habit = c.signalB;
        outcome = c.signalA;
      } else {
        continue;
      }

      if (c.r.abs() < 0.2) continue;

      final lagNote = c.lagDays > 0 ? ' (${c.lagDays}-day lag)' : '';
      antiPatterns.add(AntiPattern(
        habit: habit,
        outcome: outcome,
        r: c.r,
        explanation:
            '$habit is negatively correlated with $outcome$lagNote (r=${c.r.toStringAsFixed(2)})',
        recommendation:
            'Consider reducing or rescheduling $habit to see if $outcome improves',
      ));
    }

    antiPatterns.sort((a, b) => a.r.compareTo(b.r)); // most negative first
    return antiPatterns;
  }

  // ── Engine 6: Optimal Timing Analyzer ──

  /// Analyze day-of-week patterns for habit-outcome pairs.
  List<TimingInsight> analyzeTimings() {
    final insights = <TimingInsight>[];
    const habitNames = ['Exercise', 'Meditation', 'Reading', 'Journaling'];
    const outcomeNames = ['Mood', 'Sleep', 'Energy'];

    for (final habitName in habitNames) {
      final habit = _signals[habitName];
      if (habit == null) continue;

      for (final outcomeName in outcomeNames) {
        final outcome = _signals[outcomeName];
        if (outcome == null) continue;

        final len = min(habit.length, outcome.length);
        // Group outcome values by day-of-week when habit is done.
        final dayOutcomes = List.generate(7, (_) => <double>[]);

        for (int d = 0; d < len; d++) {
          if (habit[d].value > 0.5) {
            final dow = habit[d].date.weekday; // 1-7
            dayOutcomes[dow - 1].add(outcome[d].value);
          }
        }

        double bestAvg = -1, worstAvg = 6;
        int bestDay = 1, worstDay = 1;

        for (int dow = 0; dow < 7; dow++) {
          if (dayOutcomes[dow].length < 2) continue;
          final avg =
              dayOutcomes[dow].reduce((a, b) => a + b) / dayOutcomes[dow].length;
          if (avg > bestAvg) {
            bestAvg = avg;
            bestDay = dow + 1;
          }
          if (avg < worstAvg) {
            worstAvg = avg;
            worstDay = dow + 1;
          }
        }

        if (bestAvg > worstAvg && (bestAvg - worstAvg) > 0.3) {
          insights.add(TimingInsight(
            habit: habitName,
            outcome: outcomeName,
            bestDayOfWeek: bestDay,
            bestDayEffect: bestAvg,
            worstDayOfWeek: worstDay,
            worstDayEffect: worstAvg,
          ));
        }
      }
    }

    insights.sort(
        (a, b) => (b.bestDayEffect - b.worstDayEffect).compareTo(a.bestDayEffect - a.worstDayEffect));
    return insights;
  }

  // ── Engine 7: Insight Generator ──

  /// Synthesize all engine findings into ranked actionable insights.
  List<CorrelationInsight> generateInsights({
    required List<CorrelationResult> correlations,
    required List<CausalHypothesis> hypotheses,
    required List<SynergyResult> synergies,
    required List<AntiPattern> antiPatterns,
    required List<TimingInsight> timingInsights,
  }) {
    final insights = <CorrelationInsight>[];

    // Insight from top correlations.
    for (final c in correlations.take(5)) {
      if (c.strength == CorrelationStrength.strong ||
          c.strength == CorrelationStrength.moderate) {
        insights.add(CorrelationInsight(
          category: InsightCategory.discovery,
          priority: c.strength == CorrelationStrength.strong
              ? InsightPriority.high
              : InsightPriority.medium,
          title: '${c.signalA} ↔ ${c.signalB}',
          description: c.interpretation,
          actionItem: c.r > 0
              ? 'Keep doing ${c.signalA} — it boosts ${c.signalB}'
              : 'Watch out: ${c.signalA} may hurt ${c.signalB}',
          confidence: c.r.abs(),
        ));
      }
    }

    // Insights from causal hypotheses.
    for (final h in hypotheses.take(3)) {
      insights.add(CorrelationInsight(
        category: InsightCategory.recommendation,
        priority:
            h.confidence > 0.5 ? InsightPriority.high : InsightPriority.medium,
        title: '${h.cause} → ${h.effect}',
        description:
            '${h.cause} appears to affect ${h.effect} after ${h.lagDays} day(s)',
        actionItem: h.experiment,
        confidence: h.confidence,
      ));
    }

    // Insights from synergies.
    for (final s in synergies.take(3)) {
      insights.add(CorrelationInsight(
        category: InsightCategory.synergy,
        priority:
            s.synergyScore > 1.3 ? InsightPriority.high : InsightPriority.medium,
        title: '${s.habits.join(" + ")} → ${s.outcome}',
        description:
            'Doing ${s.habits.join(" and ")} together boosts ${s.outcome} by ${((s.synergyScore - 1) * 100).toStringAsFixed(0)}% more than individually',
        actionItem:
            'Stack ${s.habits.join(" and ")} on the same day for maximum ${s.outcome.toLowerCase()} benefit',
        confidence: (s.synergyScore - 1).clamp(0.0, 1.0),
      ));
    }

    // Insights from anti-patterns.
    for (final a in antiPatterns.take(3)) {
      insights.add(CorrelationInsight(
        category: InsightCategory.warning,
        priority:
            a.r.abs() > 0.4 ? InsightPriority.critical : InsightPriority.high,
        title: '⚠️ ${a.habit} hurts ${a.outcome}',
        description: a.explanation,
        actionItem: a.recommendation,
        confidence: a.r.abs(),
      ));
    }

    // Insights from timing analysis.
    for (final t in timingInsights.take(3)) {
      insights.add(CorrelationInsight(
        category: InsightCategory.timing,
        priority: InsightPriority.medium,
        title: 'Best day for ${t.habit}: ${t.bestDayName}',
        description:
            '${t.habit} on ${t.bestDayName} correlates with ${t.outcome} of ${t.bestDayEffect.toStringAsFixed(1)} vs ${t.worstDayEffect.toStringAsFixed(1)} on ${t.worstDayName}',
        actionItem:
            'Schedule ${t.habit} on ${t.bestDayName} for best ${t.outcome.toLowerCase()} results',
        confidence: ((t.bestDayEffect - t.worstDayEffect) / 4.0).clamp(0.0, 1.0),
      ));
    }

    // Sort by priority then confidence.
    insights.sort((a, b) {
      final pc = a.priority.index.compareTo(b.priority.index);
      return pc != 0 ? pc : b.confidence.compareTo(a.confidence);
    });

    return insights;
  }

  // ── Network Health Score ──

  /// Compute overall network health 0-100.
  double computeNetworkHealth(List<CorrelationResult> correlations,
      List<AntiPattern> antiPatterns) {
    if (correlations.isEmpty) return 0.0;

    // Factor 1: Proportion of strong positive correlations (0-40 pts).
    final strongPositive = correlations
        .where((c) =>
            c.r > 0 &&
            (c.strength == CorrelationStrength.strong ||
                c.strength == CorrelationStrength.moderate))
        .length;
    final posRatio = strongPositive / correlations.length;
    final posPts = posRatio * 40;

    // Factor 2: Absence of anti-patterns (0-30 pts).
    final antiPts = max(0.0, 30.0 - antiPatterns.length * 10.0);

    // Factor 3: Data completeness (0-30 pts).
    final daysPts = min(30.0, daysAvailable / 90.0 * 30.0);

    return (posPts + antiPts + daysPts).clamp(0.0, 100.0);
  }

  // ── Report Generation ──

  /// Run all 7 engines and produce a complete report.
  CorrelationReport generateReport() {
    final correlations = computeCorrelations();
    final hypotheses = generateHypotheses(correlations);
    final synergies = detectSynergies();
    final antiPatterns = detectAntiPatterns(correlations);
    final timingInsights = analyzeTimings();
    final insights = generateInsights(
      correlations: correlations,
      hypotheses: hypotheses,
      synergies: synergies,
      antiPatterns: antiPatterns,
      timingInsights: timingInsights,
    );
    final health = computeNetworkHealth(correlations, antiPatterns);

    return CorrelationReport(
      networkHealth: health,
      daysAnalyzed: daysAvailable,
      totalSignals: signalNames.length,
      correlations: correlations,
      hypotheses: hypotheses,
      synergies: synergies,
      antiPatterns: antiPatterns,
      timingInsights: timingInsights,
      insights: insights,
    );
  }
}
