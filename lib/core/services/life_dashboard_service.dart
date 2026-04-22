import '../../models/water_entry.dart';
import '../../models/sleep_entry.dart';
import '../../models/energy_entry.dart';
import '../../models/mood_entry.dart';
import '../../models/workout_entry.dart';
import '../../models/meal_entry.dart';
import '../../models/meditation_entry.dart';
import '../../models/habit.dart';
import '../../models/expense_entry.dart';
import '../../models/screen_time_entry.dart';

/// Aggregated score for a single wellness dimension.
class DimensionScore {
  final String name;
  final String emoji;
  final double score; // 0.0 – 100.0
  final String label; // e.g. "Great", "Needs Work"
  final String detail; // e.g. "7.5h sleep, 92% quality"

  const DimensionScore({
    required this.name,
    required this.emoji,
    required this.score,
    required this.label,
    required this.detail,
  });
}

/// Trend direction for a dimension over time.
enum Trend { rising, stable, falling }

/// A single day's aggregated life score snapshot.
class DailySnapshot {
  final DateTime date;
  final double overallScore;
  final Map<String, double> dimensionScores;

  const DailySnapshot({
    required this.date,
    required this.overallScore,
    required this.dimensionScores,
  });
}

/// Full dashboard result with all computed data.
class LifeDashboardData {
  final double overallScore;
  final String overallLabel;
  final List<DimensionScore> dimensions;
  final Map<String, Trend> trends;
  final List<DailySnapshot> history;
  final List<String> insights;
  final Map<String, int> streaks;
  final DateTime computedAt;

  const LifeDashboardData({
    required this.overallScore,
    required this.overallLabel,
    required this.dimensions,
    required this.trends,
    required this.history,
    required this.insights,
    required this.streaks,
    required this.computedAt,
  });
}

/// Service that aggregates data from all trackers into a unified
/// life/wellness dashboard with a composite score.
///
/// Each dimension (sleep, hydration, energy, mood, etc.) is scored 0–100
/// and combined with configurable weights into an overall "Life Score."
class LifeDashboardService {
  const LifeDashboardService();

  // ── Dimension weight configuration ──────────────────────────

  static const Map<String, double> _weights = {
    'sleep': 0.20,
    'hydration': 0.10,
    'energy': 0.12,
    'mood': 0.15,
    'exercise': 0.13,
    'nutrition': 0.10,
    'mindfulness': 0.08,
    'habits': 0.07,
    'finances': 0.03,
    'screen_time': 0.02,
  };

  // ── Main computation ────────────────────────────────────────

  /// Compute the full dashboard from raw tracker data.
  LifeDashboardData compute({
    List<SleepEntry> sleepEntries = const [],
    List<WaterEntry> waterEntries = const [],
    List<EnergyEntry> energyEntries = const [],
    List<MoodEntry> moodEntries = const [],
    List<WorkoutEntry> workoutEntries = const [],
    List<MealEntry> mealEntries = const [],
    List<MeditationEntry> meditationEntries = const [],
    List<Habit> habits = const [],
    List<HabitCompletion> completions = const [],
    List<ExpenseEntry> expenseEntries = const [],
    List<ScreenTimeEntry> screenTimeEntries = const [],
    int lookbackDays = 7,
  }) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: lookbackDays));

    // Score each dimension
    final dimensions = <DimensionScore>[
      _scoreSleep(sleepEntries, cutoff),
      _scoreHydration(waterEntries, cutoff),
      _scoreEnergy(energyEntries, cutoff),
      _scoreMood(moodEntries, cutoff),
      _scoreExercise(workoutEntries, cutoff),
      _scoreNutrition(mealEntries, cutoff),
      _scoreMindfulness(meditationEntries, cutoff),
      _scoreHabits(habits, completions, cutoff, lookbackDays),
      _scoreFinances(expenseEntries, cutoff),
      _scoreScreenTime(screenTimeEntries, cutoff),
    ];

    // Weighted overall score
    double overall = 0;
    for (final d in dimensions) {
      final key = d.name.toLowerCase().replaceAll(' ', '_');
      final w = _weights[key] ?? 0.05;
      overall += d.score * w;
    }
    overall = overall.clamp(0, 100);

    // Compute 7-day history
    final history = _computeHistory(
      sleepEntries: sleepEntries,
      waterEntries: waterEntries,
      energyEntries: energyEntries,
      moodEntries: moodEntries,
      workoutEntries: workoutEntries,
      mealEntries: mealEntries,
      days: lookbackDays,
    );

    // Compute trends
    final trends = _computeTrends(history);

    // Generate insights
    final insights = _generateInsights(dimensions, trends, history);

    // Compute streaks
    final streaks = _computeStreaks(
      sleepEntries: sleepEntries,
      waterEntries: waterEntries,
      workoutEntries: workoutEntries,
      meditationEntries: meditationEntries,
    );

    return LifeDashboardData(
      overallScore: _round(overall),
      overallLabel: _label(overall),
      dimensions: dimensions,
      trends: trends,
      history: history,
      insights: insights,
      streaks: streaks,
      computedAt: now,
    );
  }

  // ── Dimension scorers ───────────────────────────────────────

  DimensionScore _scoreSleep(List<SleepEntry> entries, DateTime cutoff) {
    final recent = entries.where((e) => e.bedtime.isAfter(cutoff)).toList();
    if (recent.isEmpty) return _noData('Sleep', '😴');

    double totalHours = 0;
    double totalQuality = 0;
    for (final e in recent) {
      totalHours += e.wakeTime.difference(e.bedtime).inMinutes / 60.0;
      totalQuality += e.quality.index; // SleepQuality: terrible=0..excellent=4
    }
    final avgHours = totalHours / recent.length;
    final avgQuality = totalQuality / recent.length;

    // Score: best at 7.5–8.5h, quality out of 4
    double hourScore = 100 - ((avgHours - 8.0).abs() * 20).clamp(0, 60);
    double qualityScore = (avgQuality / 4.0) * 100;
    double score = (hourScore * 0.6 + qualityScore * 0.4).clamp(0, 100);

    return DimensionScore(
      name: 'Sleep',
      emoji: '😴',
      score: _round(score),
      label: _label(score),
      detail:
          '${avgHours.toStringAsFixed(1)}h avg, ${_sleepQualityLabel(avgQuality)}',
    );
  }

  DimensionScore _scoreHydration(List<WaterEntry> entries, DateTime cutoff) {
    final recent = entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
    if (recent.isEmpty) return _noData('Hydration', '💧');

    final byDay = <String, int>{};
    for (final e in recent) {
      final key = _dayKey(e.timestamp);
      byDay[key] = (byDay[key] ?? 0) + e.amountMl;
    }
    final avgMl = byDay.values.fold<int>(0, (s, v) => s + v) / byDay.length;
    double score = ((avgMl / 2000) * 100).clamp(0, 100);

    return DimensionScore(
      name: 'Hydration',
      emoji: '💧',
      score: _round(score),
      label: _label(score),
      detail: '${avgMl.round()}ml/day avg',
    );
  }

  DimensionScore _scoreEnergy(List<EnergyEntry> entries, DateTime cutoff) {
    final recent = entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
    if (recent.isEmpty) return _noData('Energy', '⚡');

    // EnergyLevel: exhausted=0, low=1, moderate=2, high=3, peak=4
    final avgLevel =
        recent.fold<double>(0, (s, e) => s + e.level.index) / recent.length;
    double score = (avgLevel / 4.0 * 100).clamp(0, 100);

    return DimensionScore(
      name: 'Energy',
      emoji: '⚡',
      score: _round(score),
      label: _label(score),
      detail: '${_energyLabel(avgLevel)} avg (${recent.length} readings)',
    );
  }

  DimensionScore _scoreMood(List<MoodEntry> entries, DateTime cutoff) {
    final recent = entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
    if (recent.isEmpty) return _noData('Mood', '🧠');

    // MoodLevel enum: index 0–4
    final avgMood =
        recent.fold<double>(0, (s, e) => s + e.mood.index) / recent.length;
    double score = (avgMood / 4.0 * 100).clamp(0, 100);

    return DimensionScore(
      name: 'Mood',
      emoji: '🧠',
      score: _round(score),
      label: _label(score),
      detail: '${recent.length} entries, avg ${_moodLabel(avgMood)}',
    );
  }

  DimensionScore _scoreExercise(
      List<WorkoutEntry> entries, DateTime cutoff) {
    final recent = entries.where((e) => e.startTime.isAfter(cutoff)).toList();
    if (recent.isEmpty) return _noData('Exercise', '🏋️');

    final days =
        DateTime.now().difference(cutoff).inDays.clamp(1, 365);
    final sessionsPerWeek = (recent.length / days) * 7;
    double freqScore = (sessionsPerWeek / 4.0 * 100).clamp(0, 100);

    // Duration from startTime/endTime or sum of set durations
    int totalSec = 0;
    int countWithDuration = 0;
    for (final e in recent) {
      if (e.endTime != null) {
        totalSec += e.endTime!.difference(e.startTime).inSeconds;
        countWithDuration++;
      }
    }
    double durScore = 50; // neutral if no duration data
    if (countWithDuration > 0) {
      final avgMin = (totalSec / countWithDuration) / 60;
      durScore = (avgMin / 45.0 * 100).clamp(0, 100); // 45 min target
    }
    double score = (freqScore * 0.6 + durScore * 0.4).clamp(0, 100);

    return DimensionScore(
      name: 'Exercise',
      emoji: '🏋️',
      score: _round(score),
      label: _label(score),
      detail:
          '${recent.length} sessions, ${sessionsPerWeek.toStringAsFixed(1)}/week',
    );
  }

  DimensionScore _scoreNutrition(List<MealEntry> entries, DateTime cutoff) {
    final recent = entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
    if (recent.isEmpty) return _noData('Nutrition', '🥗');

    final byDay = <String, int>{};
    for (final e in recent) {
      final key = _dayKey(e.timestamp);
      byDay[key] = (byDay[key] ?? 0) + 1;
    }
    final avgMeals =
        byDay.values.fold<int>(0, (s, v) => s + v) / byDay.length;
    double score = (avgMeals / 3.0 * 100).clamp(0, 100);

    return DimensionScore(
      name: 'Nutrition',
      emoji: '🥗',
      score: _round(score),
      label: _label(score),
      detail: '${avgMeals.toStringAsFixed(1)} meals/day avg',
    );
  }

  DimensionScore _scoreMindfulness(
      List<MeditationEntry> entries, DateTime cutoff) {
    final recent =
        entries.where((e) => e.dateTime.isAfter(cutoff)).toList();
    if (recent.isEmpty) return _noData('Mindfulness', '🧘');

    final days =
        DateTime.now().difference(cutoff).inDays.clamp(1, 365);
    final sessionsPerWeek = (recent.length / days) * 7;
    final totalMin =
        recent.fold<int>(0, (s, e) => s + e.durationMinutes);
    final avgMin = totalMin / recent.length;

    double freqScore = (sessionsPerWeek / 3.0 * 100).clamp(0, 100);
    double durScore = (avgMin / 10.0 * 100).clamp(0, 100);
    double score = (freqScore * 0.5 + durScore * 0.5).clamp(0, 100);

    return DimensionScore(
      name: 'Mindfulness',
      emoji: '🧘',
      score: _round(score),
      label: _label(score),
      detail: '${recent.length} sessions, ${avgMin.round()}min avg',
    );
  }

  DimensionScore _scoreHabits(
    List<Habit> habits,
    List<HabitCompletion> completions,
    DateTime cutoff,
    int lookbackDays,
  ) {
    final active = habits.where((h) => h.isActive).toList();
    if (active.isEmpty) return _noData('Habits', '✅');

    final recentCompletions =
        completions.where((c) => c.date.isAfter(cutoff)).toList();
    if (recentCompletions.isEmpty) {
      return DimensionScore(
        name: 'Habits',
        emoji: '✅',
        score: 0,
        label: _label(0),
        detail: '${active.length} active, no completions logged',
      );
    }

    // Rate = days with any completion / total days
    final completedDays = <String>{};
    for (final c in recentCompletions) {
      completedDays.add(_dayKey(c.date));
    }
    double rate = completedDays.length / lookbackDays.clamp(1, 365);
    double score = (rate * 100).clamp(0, 100);

    return DimensionScore(
      name: 'Habits',
      emoji: '✅',
      score: _round(score),
      label: _label(score),
      detail:
          '${active.length} active, ${completedDays.length}/$lookbackDays days tracked',
    );
  }

  DimensionScore _scoreFinances(
      List<ExpenseEntry> entries, DateTime cutoff) {
    final recent = entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
    if (recent.isEmpty) return _noData('Finances', '💰');

    final byDay = <String, bool>{};
    for (final e in recent) {
      byDay[_dayKey(e.timestamp)] = true;
    }
    final days =
        DateTime.now().difference(cutoff).inDays.clamp(1, 365);
    double trackingRate = byDay.length / days;
    double score = (trackingRate * 100).clamp(0, 100);

    final totalSpent = recent.fold<double>(0, (s, e) => s + e.amount);

    return DimensionScore(
      name: 'Finances',
      emoji: '💰',
      score: _round(score),
      label: _label(score),
      detail:
          '\$${totalSpent.toStringAsFixed(0)} tracked, ${byDay.length}/$days days',
    );
  }

  DimensionScore _scoreScreenTime(
      List<ScreenTimeEntry> entries, DateTime cutoff) {
    final recent = entries.where((e) => e.date.isAfter(cutoff)).toList();
    if (recent.isEmpty) return _noData('Screen Time', '📱');

    final byDay = <String, int>{};
    for (final e in recent) {
      final key = _dayKey(e.date);
      byDay[key] = (byDay[key] ?? 0) + e.durationMinutes;
    }
    final avgMin =
        byDay.values.fold<int>(0, (s, v) => s + v) / byDay.length;
    // Lower is better: 0min → 100, 240min(4h) → 50, 480min(8h) → 0
    double score = (100 - (avgMin / 4.8)).clamp(0, 100);

    return DimensionScore(
      name: 'Screen Time',
      emoji: '📱',
      score: _round(score),
      label: _label(score),
      detail: '${(avgMin / 60).toStringAsFixed(1)}h/day avg',
    );
  }

  // ── History & trends ────────────────────────────────────────

  List<DailySnapshot> _computeHistory({
    required List<SleepEntry> sleepEntries,
    required List<WaterEntry> waterEntries,
    required List<EnergyEntry> energyEntries,
    required List<MoodEntry> moodEntries,
    required List<WorkoutEntry> workoutEntries,
    required List<MealEntry> mealEntries,
    required int days,
  }) {
    final now = DateTime.now();
    final snapshots = <DailySnapshot>[];

    // Pre-index all entry types by day key (year*10000+month*100+day)
    // to avoid O(days × entries) rescanning per dimension.  For 30 days
    // with 1000 entries this reduces from 180 linear scans to 6 single
    // passes (one per entry type) plus O(1) lookups per day.
    int _dayKey(DateTime dt) => dt.year * 10000 + dt.month * 100 + dt.day;

    final sleepByDay = <int, List<SleepEntry>>{};
    for (final e in sleepEntries) {
      sleepByDay.putIfAbsent(_dayKey(e.bedtime), () => []).add(e);
    }
    final waterByDay = <int, List<WaterEntry>>{};
    for (final e in waterEntries) {
      waterByDay.putIfAbsent(_dayKey(e.timestamp), () => []).add(e);
    }
    final energyByDay = <int, List<EnergyEntry>>{};
    for (final e in energyEntries) {
      energyByDay.putIfAbsent(_dayKey(e.timestamp), () => []).add(e);
    }
    final moodByDay = <int, List<MoodEntry>>{};
    for (final e in moodEntries) {
      moodByDay.putIfAbsent(_dayKey(e.timestamp), () => []).add(e);
    }
    final workoutByDay = <int, List<WorkoutEntry>>{};
    for (final e in workoutEntries) {
      workoutByDay.putIfAbsent(_dayKey(e.startTime), () => []).add(e);
    }
    final mealByDay = <int, List<MealEntry>>{};
    for (final e in mealEntries) {
      mealByDay.putIfAbsent(_dayKey(e.timestamp), () => []).add(e);
    }

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final key = _dayKey(dayStart);

      final scores = <String, double>{};

      // Sleep
      final daySleep = sleepByDay[key] ?? const [];
      if (daySleep.isEmpty) {
        scores['sleep'] = 50.0;
      } else {
        double hours = 0;
        double quality = 0;
        for (final e in daySleep) {
          hours += e.wakeTime.difference(e.bedtime).inMinutes / 60.0;
          quality += e.quality.index;
        }
        hours /= daySleep.length;
        quality /= daySleep.length;
        double hs = 100 - ((hours - 8.0).abs() * 20).clamp(0, 60);
        double qs = (quality / 4.0) * 100;
        scores['sleep'] = (hs * 0.6 + qs * 0.4).clamp(0, 100);
      }

      // Water
      final dayWater = waterByDay[key] ?? const [];
      final waterMl = dayWater.fold<int>(0, (s, e) => s + e.amountMl);
      scores['hydration'] = (waterMl / 2000 * 100).clamp(0, 100);

      // Energy
      final dayEnergy = energyByDay[key] ?? const [];
      scores['energy'] = dayEnergy.isEmpty
          ? 50.0
          : (dayEnergy.fold<double>(0, (s, e) => s + e.level.index) /
                  dayEnergy.length /
                  4.0 *
                  100)
              .clamp(0, 100);

      // Mood
      final dayMood = moodByDay[key] ?? const [];
      scores['mood'] = dayMood.isEmpty
          ? 50.0
          : (dayMood.fold<double>(0, (s, e) => s + e.mood.index) /
                  dayMood.length /
                  4.0 *
                  100)
              .clamp(0, 100);

      // Exercise
      final dayWorkouts = workoutByDay[key] ?? const [];
      scores['exercise'] = dayWorkouts.isEmpty ? 0.0 : 100.0;

      // Nutrition
      final dayMeals = mealByDay[key] ?? const [];
      scores['nutrition'] =
          (dayMeals.length / 3.0 * 100).clamp(0.0, 100.0);

      // Weighted overall
      double overall = 0;
      for (final entry in scores.entries) {
        overall += entry.value * (_weights[entry.key] ?? 0.05);
      }

      snapshots.add(DailySnapshot(
        date: dayStart,
        overallScore: _round(overall.clamp(0, 100)),
        dimensionScores: scores,
      ));
    }

    return snapshots;
  }

  Map<String, Trend> _computeTrends(List<DailySnapshot> history) {
    final trends = <String, Trend>{};
    if (history.length < 3) return trends;

    final mid = history.length ~/ 2;
    final firstHalf = history.sublist(0, mid);
    final secondHalf = history.sublist(mid);

    // Overall trend
    final firstAvg =
        firstHalf.fold<double>(0, (s, h) => s + h.overallScore) /
            firstHalf.length;
    final secondAvg =
        secondHalf.fold<double>(0, (s, h) => s + h.overallScore) /
            secondHalf.length;
    trends['overall'] = _trendFromDelta(secondAvg - firstAvg);

    // Per-dimension trends
    if (history.first.dimensionScores.isNotEmpty) {
      for (final dim in history.first.dimensionScores.keys) {
        final fAvg = firstHalf.fold<double>(
                0, (s, h) => s + (h.dimensionScores[dim] ?? 50)) /
            firstHalf.length;
        final sAvg = secondHalf.fold<double>(
                0, (s, h) => s + (h.dimensionScores[dim] ?? 50)) /
            secondHalf.length;
        trends[dim] = _trendFromDelta(sAvg - fAvg);
      }
    }

    return trends;
  }

  List<String> _generateInsights(
    List<DimensionScore> dimensions,
    Map<String, Trend> trends,
    List<DailySnapshot> history,
  ) {
    final insights = <String>[];

    // Best and worst dimensions
    final sorted = [...dimensions]..sort((a, b) => b.score.compareTo(a.score));
    if (sorted.isNotEmpty) {
      final best = sorted.first;
      insights.add(
          '${best.emoji} ${best.name} is your strongest area at ${best.score.round()}%');
    }
    if (sorted.length > 1) {
      final worst = sorted.last;
      if (worst.score < 50) {
        insights.add(
            '${worst.emoji} ${worst.name} needs attention — only ${worst.score.round()}%');
      }
    }

    // Trending insights
    for (final entry in trends.entries) {
      if (entry.key == 'overall') continue;
      if (entry.value == Trend.rising) {
        insights
            .add('📈 ${_capitalize(entry.key)} is trending up — keep going!');
      } else if (entry.value == Trend.falling) {
        insights.add(
            '📉 ${_capitalize(entry.key)} is declining — consider refocusing');
      }
    }

    // Overall trajectory
    if (trends['overall'] == Trend.rising) {
      insights.add('🎯 Your overall wellness is improving — great trajectory!');
    } else if (trends['overall'] == Trend.falling) {
      insights.add(
          '⚠️ Overall wellness is trending down — small changes compound');
    }

    // Consistency check
    if (history.isNotEmpty) {
      final scores = history.map((h) => h.overallScore).toList();
      final mean = scores.fold<double>(0, (s, v) => s + v) / scores.length;
      double variance = 0;
      for (final s in scores) {
        variance += (s - mean) * (s - mean);
      }
      variance /= scores.length;
      if (variance > 400) {
        insights.add(
            '🎢 Your scores vary a lot day-to-day — consistency builds momentum');
      } else if (variance < 25 && mean > 60) {
        insights.add(
            '🏆 Very consistent performance — you\'ve built solid routines!');
      }
    }

    return insights;
  }

  Map<String, int> _computeStreaks({
    required List<SleepEntry> sleepEntries,
    required List<WaterEntry> waterEntries,
    required List<WorkoutEntry> workoutEntries,
    required List<MeditationEntry> meditationEntries,
  }) {
    return {
      'sleep': _currentStreak(sleepEntries.map((e) => e.bedtime).toList()),
      'hydration':
          _currentStreak(waterEntries.map((e) => e.timestamp).toList()),
      'exercise':
          _currentStreak(workoutEntries.map((e) => e.startTime).toList()),
      'mindfulness':
          _currentStreak(meditationEntries.map((e) => e.dateTime).toList()),
    };
  }

  int _currentStreak(List<DateTime> timestamps) {
    if (timestamps.isEmpty) return 0;

    final days = <String>{};
    for (final t in timestamps) {
      days.add(_dayKey(t));
    }

    int streak = 0;
    var day = DateTime.now();
    if (!days.contains(_dayKey(day))) {
      day = day.subtract(const Duration(days: 1));
      if (!days.contains(_dayKey(day))) return 0;
    }

    while (days.contains(_dayKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ── Utilities ───────────────────────────────────────────────

  static DimensionScore _noData(String name, String emoji) {
    return DimensionScore(
      name: name,
      emoji: emoji,
      score: 50.0,
      label: 'No Data',
      detail: 'Start logging to see your score',
    );
  }

  static String _label(double score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Great';
    if (score >= 55) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 25) return 'Needs Work';
    return 'Critical';
  }

  static double _round(double v) =>
      (v * 10).roundToDouble() / 10;

  static String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static Trend _trendFromDelta(double delta) {
    if (delta > 5) return Trend.rising;
    if (delta < -5) return Trend.falling;
    return Trend.stable;
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }

  static String _sleepQualityLabel(double avg) {
    if (avg >= 3.5) return 'Excellent';
    if (avg >= 2.5) return 'Good';
    if (avg >= 1.5) return 'Fair';
    if (avg >= 0.5) return 'Poor';
    return 'Terrible';
  }

  static String _energyLabel(double avg) {
    if (avg >= 3.5) return 'Peak';
    if (avg >= 2.5) return 'High';
    if (avg >= 1.5) return 'Moderate';
    if (avg >= 0.5) return 'Low';
    return 'Exhausted';
  }

  static String _moodLabel(double avg) {
    if (avg >= 3.5) return 'Great';
    if (avg >= 2.5) return 'Good';
    if (avg >= 1.5) return 'Okay';
    if (avg >= 0.5) return 'Low';
    return 'Very Low';
  }
}
