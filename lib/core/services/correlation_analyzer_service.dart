import 'dart:math';
import '../../models/mood_entry.dart';
import '../../models/sleep_entry.dart';
import '../../models/habit.dart';
import '../../models/event_model.dart';

/// A single correlation between two variables.
class Correlation {
  /// Name of the first variable (e.g., "sleep_duration").
  final String variableA;

  /// Name of the second variable (e.g., "mood_score").
  final String variableB;

  /// Pearson correlation coefficient (-1.0 to 1.0).
  final double coefficient;

  /// Number of data points used.
  final int sampleSize;

  /// Human-readable insight text.
  final String insight;

  /// Strength category based on |coefficient|.
  final CorrelationStrength strength;

  const Correlation({
    required this.variableA,
    required this.variableB,
    required this.coefficient,
    required this.sampleSize,
    required this.insight,
    required this.strength,
  });
}

/// Strength categories for correlations.
enum CorrelationStrength {
  none,
  weak,
  moderate,
  strong,
  veryStrong;

  String get label {
    switch (this) {
      case CorrelationStrength.none:
        return 'None';
      case CorrelationStrength.weak:
        return 'Weak';
      case CorrelationStrength.moderate:
        return 'Moderate';
      case CorrelationStrength.strong:
        return 'Strong';
      case CorrelationStrength.veryStrong:
        return 'Very Strong';
    }
  }
}

/// A daily snapshot merging data from all tracking domains.
class DailySnapshot {
  final DateTime date;
  final double? sleepHours;
  final int? sleepQuality; // 1-5
  final int? awakenings;
  final int? moodScore; // 1-5
  final List<MoodActivity> moodActivities;
  final List<SleepFactor> sleepFactors;
  final int habitsDue;
  final int habitsCompleted;
  final int eventCount;
  final double eventHours;

  const DailySnapshot({
    required this.date,
    this.sleepHours,
    this.sleepQuality,
    this.awakenings,
    this.moodScore,
    this.moodActivities = const [],
    this.sleepFactors = const [],
    this.habitsDue = 0,
    this.habitsCompleted = 0,
    this.eventCount = 0,
    this.eventHours = 0,
  });

  /// Habit completion rate (0.0 to 1.0), null if no habits due.
  double? get habitCompletionRate =>
      habitsDue > 0 ? habitsCompleted / habitsDue : null;
}

/// Summary statistics for a variable.
class VariableStats {
  final String name;
  final double mean;
  final double stdDev;
  final double min;
  final double max;
  final int count;

  const VariableStats({
    required this.name,
    required this.mean,
    required this.stdDev,
    required this.min,
    required this.max,
    required this.count,
  });
}

/// Full correlation analysis report.
class CorrelationReport {
  final List<Correlation> correlations;
  final List<DailySnapshot> snapshots;
  final Map<String, VariableStats> variableStats;
  final List<String> topInsights;
  final int totalDays;

  const CorrelationReport({
    required this.correlations,
    required this.snapshots,
    required this.variableStats,
    required this.topInsights,
    required this.totalDays,
  });
}

/// Analyzes correlations between sleep, mood, habits, and events.
///
/// Merges data from all tracking domains into daily snapshots, then
/// computes Pearson correlations between numeric variables and
/// generates human-readable insights.
class CorrelationAnalyzerService {
  /// Minimum data points required to compute a meaningful correlation.
  final int minSampleSize;

  const CorrelationAnalyzerService({this.minSampleSize = 7});

  // ── Snapshot Building ────────────────────────────────────────────

  /// Build daily snapshots by merging data from all domains.
  List<DailySnapshot> buildSnapshots({
    required List<SleepEntry> sleepEntries,
    required List<MoodEntry> moodEntries,
    required List<Habit> habits,
    required List<HabitCompletion> completions,
    required List<EventModel> events,
  }) {
    // Collect all dates with any data.
    // Uses integer date keys (YYYYMMDD) instead of formatted strings
    // to avoid per-entry string allocations and speed up hashing.
    final dateSet = <int>{};

    for (final s in sleepEntries) {
      dateSet.add(_dateKeyInt(s.date));
    }
    for (final m in moodEntries) {
      dateSet.add(_dateKeyInt(m.timestamp));
    }
    for (final c in completions) {
      dateSet.add(_dateKeyInt(c.date));
    }
    for (final e in events) {
      dateSet.add(_dateKeyInt(e.date));
    }

    if (dateSet.isEmpty) return [];

    // Index data by date.
    final sleepByDate = <int, List<SleepEntry>>{};
    for (final s in sleepEntries) {
      final key = _dateKeyInt(s.date);
      sleepByDate.putIfAbsent(key, () => []).add(s);
    }

    final moodByDate = <int, List<MoodEntry>>{};
    for (final m in moodEntries) {
      final key = _dateKeyInt(m.timestamp);
      moodByDate.putIfAbsent(key, () => []).add(m);
    }

    final completionsByDate = <int, List<HabitCompletion>>{};
    for (final c in completions) {
      final key = _dateKeyInt(c.date);
      completionsByDate.putIfAbsent(key, () => []).add(c);
    }

    final eventsByDate = <int, List<EventModel>>{};
    for (final e in events) {
      final key = _dateKeyInt(e.date);
      eventsByDate.putIfAbsent(key, () => []).add(e);
    }

    final activeHabits = habits.where((h) => h.isActive).toList();

    // Build snapshots sorted by date.
    final dates = dateSet.toList()..sort();
    final snapshots = <DailySnapshot>[];

    for (final dateInt in dates) {
      final year = dateInt ~/ 10000;
      final month = (dateInt ~/ 100) % 100;
      final day = dateInt % 100;
      final date = DateTime(year, month, day);
      final weekday = date.weekday;

      // Sleep: average if multiple entries.
      final sleepList = sleepByDate[dateInt] ?? [];
      double? sleepHours;
      int? sleepQuality;
      int? awakenings;
      final allSleepFactors = <SleepFactor>[];

      if (sleepList.isNotEmpty) {
        sleepHours = sleepList.map((s) => s.durationHours).reduce((a, b) => a + b) /
            sleepList.length;
        sleepQuality = (sleepList.map((s) => s.quality.value).reduce((a, b) => a + b) /
                sleepList.length)
            .round();
        final aw = sleepList.where((s) => s.awakenings != null).toList();
        if (aw.isNotEmpty) {
          awakenings = (aw.map((s) => s.awakenings!).reduce((a, b) => a + b) /
                  aw.length)
              .round();
        }
        for (final s in sleepList) {
          allSleepFactors.addAll(s.factors);
        }
      }

      // Mood: average if multiple entries.
      final moodList = moodByDate[dateInt] ?? [];
      int? moodScore;
      final allMoodActivities = <MoodActivity>[];

      if (moodList.isNotEmpty) {
        moodScore = (moodList.map((m) => m.mood.value).reduce((a, b) => a + b) /
                moodList.length)
            .round();
        for (final m in moodList) {
          allMoodActivities.addAll(m.activities);
        }
      }

      // Habits: count due and completed.
      final due = activeHabits.where((h) => h.isScheduledFor(weekday)).length;
      final dayCompletions = completionsByDate[dateInt] ?? [];
      final completedIds = dayCompletions.map((c) => c.habitId).toSet();
      final completed = activeHabits
          .where((h) => h.isScheduledFor(weekday) && completedIds.contains(h.id))
          .length;

      // Events: count and total hours.
      final dayEvents = eventsByDate[dateInt] ?? [];
      final eventCount = dayEvents.length;
      double eventHours = 0;
      for (final e in dayEvents) {
        eventHours += (e.endDate ?? e.date).difference(e.date).inMinutes / 60.0;
      }

      snapshots.add(DailySnapshot(
        date: date,
        sleepHours: sleepHours,
        sleepQuality: sleepQuality,
        awakenings: awakenings,
        moodScore: moodScore,
        moodActivities: allMoodActivities.toSet().toList(),
        sleepFactors: allSleepFactors.toSet().toList(),
        habitsDue: due,
        habitsCompleted: completed,
        eventCount: eventCount,
        eventHours: eventHours,
      ));
    }

    return snapshots;
  }

  // ── Correlation Analysis ─────────────────────────────────────────

  /// Compute all cross-domain correlations from snapshots.
  CorrelationReport analyze(List<DailySnapshot> snapshots) {
    if (snapshots.isEmpty) {
      return CorrelationReport(
        correlations: [],
        snapshots: [],
        variableStats: {},
        topInsights: ['Not enough data. Keep tracking!'],
        totalDays: 0,
      );
    }

    final correlations = <Correlation>[];

    // Define variable extractors.
    final variables = <String, double? Function(DailySnapshot)>{
      'sleep_hours': (s) => s.sleepHours,
      'sleep_quality': (s) => s.sleepQuality?.toDouble(),
      'awakenings': (s) => s.awakenings?.toDouble(),
      'mood_score': (s) => s.moodScore?.toDouble(),
      'habit_completion': (s) => s.habitCompletionRate != null
          ? s.habitCompletionRate! * 100
          : null,
      'event_count': (s) => s.eventCount.toDouble(),
      'event_hours': (s) => s.eventHours,
    };

    final varNames = variables.keys.toList();
    final stats = <String, VariableStats>{};

    // Pre-extract all variable values in a single pass over the
    // snapshots.  This avoids calling every extractor per variable-pair
    // (previously 21 separate iterations through snapshots for 7
    // variables).  The resulting map stores a list of nullable doubles
    // aligned by snapshot index so that paired-value lookup below is
    // a simple index comparison.
    final preExtracted = <String, List<double?>>{};
    for (final name in varNames) {
      final extractor = variables[name]!;
      preExtracted[name] = snapshots.map(extractor).toList();
    }

    // Compute stats for each variable.
    for (final name in varNames) {
      final values = preExtracted[name]!
          .where((v) => v != null)
          .map((v) => v!)
          .toList();
      if (values.length >= 2) {
        stats[name] = _computeStats(name, values);
      }
    }

    // Compute pairwise correlations using the pre-extracted values.
    for (int i = 0; i < varNames.length; i++) {
      for (int j = i + 1; j < varNames.length; j++) {
        final nameA = varNames[i];
        final nameB = varNames[j];
        final valsA = preExtracted[nameA]!;
        final valsB = preExtracted[nameB]!;

        // Collect paired data points where both have values.
        final pairsA = <double>[];
        final pairsB = <double>[];

        for (int k = 0; k < snapshots.length; k++) {
          final a = valsA[k];
          final b = valsB[k];
          if (a != null && b != null) {
            pairsA.add(a);
            pairsB.add(b);
          }
        }

        if (pairsA.length < minSampleSize) continue;

        final coeff = _pearson(pairsA, pairsB);
        if (coeff.isNaN) continue;

        final strength = _classifyStrength(coeff);
        final insight = _generateInsight(nameA, nameB, coeff, strength);

        correlations.add(Correlation(
          variableA: nameA,
          variableB: nameB,
          coefficient: coeff,
          sampleSize: pairsA.length,
          insight: insight,
          strength: strength,
        ));
      }
    }

    // Sort by absolute strength (strongest first).
    correlations.sort((a, b) =>
        b.coefficient.abs().compareTo(a.coefficient.abs()));

    // Generate top insights (skip "none" strength).
    final topInsights = correlations
        .where((c) => c.strength != CorrelationStrength.none)
        .take(5)
        .map((c) => c.insight)
        .toList();

    if (topInsights.isEmpty) {
      topInsights.add('No significant correlations found yet. Keep tracking!');
    }

    return CorrelationReport(
      correlations: correlations,
      snapshots: snapshots,
      variableStats: stats,
      topInsights: topInsights,
      totalDays: snapshots.length,
    );
  }

  /// Full analysis pipeline: build snapshots then analyze.
  CorrelationReport fullAnalysis({
    required List<SleepEntry> sleepEntries,
    required List<MoodEntry> moodEntries,
    required List<Habit> habits,
    required List<HabitCompletion> completions,
    required List<EventModel> events,
  }) {
    final snapshots = buildSnapshots(
      sleepEntries: sleepEntries,
      moodEntries: moodEntries,
      habits: habits,
      completions: completions,
      events: events,
    );
    return analyze(snapshots);
  }

  // ── Activity/Factor Impact Analysis ──────────────────────────────

  /// Compute mood impact of each activity.
  ///
  /// Returns a map of activity → average mood delta vs non-activity days.
  /// Single-pass implementation: accumulates per-activity mood sums and
  /// counts in one traversal instead of iterating snapshots per activity.
  Map<MoodActivity, double> activityMoodImpact(List<DailySnapshot> snapshots) {
    final activitySums = <MoodActivity, double>{};
    final activityCounts = <MoodActivity, int>{};
    double totalMood = 0;
    int totalCount = 0;

    for (final s in snapshots) {
      if (s.moodScore == null) continue;
      final score = s.moodScore!.toDouble();
      totalMood += score;
      totalCount++;
      for (final activity in s.moodActivities) {
        activitySums[activity] = (activitySums[activity] ?? 0) + score;
        activityCounts[activity] = (activityCounts[activity] ?? 0) + 1;
      }
    }

    if (totalCount < minSampleSize) return {};
    final overallMean = totalMood / totalCount;

    final impact = <MoodActivity, double>{};
    for (final activity in activitySums.keys) {
      final count = activityCounts[activity]!;
      if (count < 2) continue;
      impact[activity] = activitySums[activity]! / count - overallMean;
    }

    return impact;
  }

  /// Compute sleep quality impact of each sleep factor.
  /// Single-pass implementation: accumulates per-factor quality sums and
  /// counts in one traversal instead of iterating snapshots per factor.
  Map<SleepFactor, double> factorSleepImpact(List<DailySnapshot> snapshots) {
    final factorSums = <SleepFactor, double>{};
    final factorCounts = <SleepFactor, int>{};
    double totalQuality = 0;
    int totalCount = 0;

    for (final s in snapshots) {
      if (s.sleepQuality == null) continue;
      final quality = s.sleepQuality!.toDouble();
      totalQuality += quality;
      totalCount++;
      for (final factor in s.sleepFactors) {
        factorSums[factor] = (factorSums[factor] ?? 0) + quality;
        factorCounts[factor] = (factorCounts[factor] ?? 0) + 1;
      }
    }

    if (totalCount < minSampleSize) return {};
    final overallMean = totalQuality / totalCount;

    final impact = <SleepFactor, double>{};
    for (final factor in factorSums.keys) {
      final count = factorCounts[factor]!;
      if (count < 2) continue;
      impact[factor] = factorSums[factor]! / count - overallMean;
    }

    return impact;
  }

  // ── Moving Correlation ───────────────────────────────────────────

  /// Compute a rolling correlation between two variables over a window.
  ///
  /// Returns list of (date, coefficient) pairs.
  /// Uses index-based iteration instead of sublist allocation to
  /// avoid creating windowSize-length lists at every position.
  List<MapEntry<DateTime, double>> rollingCorrelation({
    required List<DailySnapshot> snapshots,
    required double? Function(DailySnapshot) extractA,
    required double? Function(DailySnapshot) extractB,
    int windowSize = 14,
  }) {
    if (snapshots.length < windowSize) return [];

    final results = <MapEntry<DateTime, double>>[];

    for (int i = windowSize - 1; i < snapshots.length; i++) {
      final valsA = <double>[];
      final valsB = <double>[];

      for (int j = i - windowSize + 1; j <= i; j++) {
        final a = extractA(snapshots[j]);
        final b = extractB(snapshots[j]);
        if (a != null && b != null) {
          valsA.add(a);
          valsB.add(b);
        }
      }

      if (valsA.length >= minSampleSize) {
        final coeff = _pearson(valsA, valsB);
        if (!coeff.isNaN) {
          results.add(MapEntry(snapshots[i].date, coeff));
        }
      }
    }

    return results;
  }

  // ── Private Helpers ──────────────────────────────────────────────

  /// Compute Pearson correlation coefficient.
  double _pearson(List<double> x, List<double> y) {
    assert(x.length == y.length);
    final n = x.length;
    if (n < 2) return double.nan;

    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;

    double sumXY = 0, sumX2 = 0, sumY2 = 0;
    for (int i = 0; i < n; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      sumXY += dx * dy;
      sumX2 += dx * dx;
      sumY2 += dy * dy;
    }

    final denom = sqrt(sumX2 * sumY2);
    if (denom == 0) return 0.0;

    return sumXY / denom;
  }

  /// Classify correlation strength.
  CorrelationStrength _classifyStrength(double coeff) {
    final abs = coeff.abs();
    if (abs >= 0.8) return CorrelationStrength.veryStrong;
    if (abs >= 0.6) return CorrelationStrength.strong;
    if (abs >= 0.4) return CorrelationStrength.moderate;
    if (abs >= 0.2) return CorrelationStrength.weak;
    return CorrelationStrength.none;
  }

  /// Human-readable variable name.
  String _prettyName(String variable) {
    switch (variable) {
      case 'sleep_hours':
        return 'sleep duration';
      case 'sleep_quality':
        return 'sleep quality';
      case 'awakenings':
        return 'night awakenings';
      case 'mood_score':
        return 'mood';
      case 'habit_completion':
        return 'habit completion rate';
      case 'event_count':
        return 'number of events';
      case 'event_hours':
        return 'time in events';
      default:
        return variable.replaceAll('_', ' ');
    }
  }

  /// Generate a human-readable insight for a correlation.
  String _generateInsight(
      String varA, String varB, double coeff, CorrelationStrength strength) {
    final nameA = _prettyName(varA);
    final nameB = _prettyName(varB);
    final direction = coeff > 0 ? 'positively' : 'negatively';
    final pct = (coeff.abs() * 100).round();

    if (strength == CorrelationStrength.none) {
      return 'No meaningful connection between $nameA and $nameB.';
    }

    final strengthLabel = strength.label.toLowerCase();

    if (coeff > 0) {
      return 'Your $nameA and $nameB have a $strengthLabel positive connection ($pct%). '
          'Days with higher $nameA tend to have higher $nameB.';
    } else {
      return 'Your $nameA and $nameB have a $strengthLabel negative connection ($pct%). '
          'Days with higher $nameA tend to have lower $nameB.';
    }
  }

  /// Compute summary statistics for a list of values.
  VariableStats _computeStats(String name, List<double> values) {
    final n = values.length;
    final mean = values.reduce((a, b) => a + b) / n;
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);

    double sumSqDev = 0;
    for (final v in values) {
      sumSqDev += (v - mean) * (v - mean);
    }
    final stdDev = n > 1 ? sqrt(sumSqDev / (n - 1)) : 0.0;

    return VariableStats(
      name: name,
      mean: mean,
      stdDev: stdDev,
      min: minVal,
      max: maxVal,
      count: n,
    );
  }

  /// Integer date key for indexing (YYYYMMDD).
  ///
  /// Uses integer encoding instead of string formatting to avoid
  /// per-entry string allocations. Consistent with HeatmapService.
  int _dateKeyInt(DateTime dt) => dt.year * 10000 + dt.month * 100 + dt.day;
}
