import 'dart:math';
import 'habit_tracker_service.dart';

// ─── Enums ───────────────────────────────────────────────────────────

enum InsightType { correlation, streakForecast, optimalTiming, risk, celebration, suggestion }

enum InsightPriority { critical, high, medium, low }

// ─── Data classes ────────────────────────────────────────────────────

class HabitInsight {
  final int id;
  final InsightType type;
  final InsightPriority priority;
  final String title;
  final String description;
  final String emoji;
  final List<String> relatedHabits;
  final double confidence;
  final bool actionable;
  final String? action;

  const HabitInsight({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.emoji,
    this.relatedHabits = const [],
    this.confidence = 0.7,
    this.actionable = false,
    this.action,
  });
}

class HabitCorrelation {
  final String habitA;
  final String habitB;
  final double correlationScore;
  final String description;
  final String direction; // positive, negative, neutral

  const HabitCorrelation({
    required this.habitA,
    required this.habitB,
    required this.correlationScore,
    required this.description,
    required this.direction,
  });
}

class StreakForecast {
  final String habitName;
  final String emoji;
  final int currentStreak;
  final int predictedDays;
  final double confidence;
  final List<String> riskFactors;

  const StreakForecast({
    required this.habitName,
    required this.emoji,
    required this.currentStreak,
    required this.predictedDays,
    required this.confidence,
    this.riskFactors = const [],
  });
}

class TimingProfile {
  final String habitName;
  final String emoji;
  final String bestDayOfWeek;
  final String worstDayOfWeek;
  final Map<String, double> completionByDay;
  final double averageRate;

  const TimingProfile({
    required this.habitName,
    required this.emoji,
    required this.bestDayOfWeek,
    required this.worstDayOfWeek,
    required this.completionByDay,
    required this.averageRate,
  });
}

class HabitHealthScore {
  final String habitName;
  final String emoji;
  final int score;
  final String trend; // up, down, stable
  final List<String> factors;

  const HabitHealthScore({
    required this.habitName,
    required this.emoji,
    required this.score,
    required this.trend,
    this.factors = const [],
  });
}

class InsightsSummary {
  final int totalHabits;
  final double avgCompletionRate;
  final String strongestHabit;
  final String weakestHabit;
  final int totalInsights;
  final String healthGrade;

  const InsightsSummary({
    required this.totalHabits,
    required this.avgCompletionRate,
    required this.strongestHabit,
    required this.weakestHabit,
    required this.totalInsights,
    required this.healthGrade,
  });
}

// ─── Service ─────────────────────────────────────────────────────────

class HabitInsightsService {
  final _rng = Random(42);

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Generate demo habits with 60 days of synthetic completion data.
  List<Habit> getDemoHabits() {
    final today = _dateOnly(DateTime.now());
    // (name, emoji, base completion probability, weekend modifier)
    final specs = <(String, String, double, double)>[
      ('Exercise', '🏃', 0.72, 0.85),
      ('Read', '📚', 0.80, 0.90),
      ('Meditate', '🧘', 0.65, 0.55),
      ('Drink Water', '💧', 0.88, 0.80),
      ('Journal', '✍️', 0.58, 0.40),
      ('Sleep 8h', '😴', 0.60, 0.75),
      ('No Junk Food', '🥗', 0.50, 0.35),
      ('Walk 10k Steps', '🚶', 0.68, 0.78),
    ];

    return specs.map((s) {
      final dates = <DateTime>{};
      for (int d = 0; d < 60; d++) {
        final date = today.subtract(Duration(days: d));
        final isWeekend = date.weekday >= 6;
        final prob = isWeekend ? s.$4 : s.$3;
        // Add streak momentum: recent days slightly more likely
        final recencyBoost = d < 7 ? 0.05 : 0.0;
        if (_rng.nextDouble() < prob + recencyBoost) {
          dates.add(date);
        }
      }
      return Habit(
        name: s.$1,
        emoji: s.$2,
        completedDates: dates,
        createdAt: today.subtract(const Duration(days: 60)),
      );
    }).toList();
  }

  /// Pairwise co-occurrence correlation (phi coefficient approximation).
  List<HabitCorrelation> analyzeCorrelations(List<Habit> habits) {
    final today = _dateOnly(DateTime.now());
    const days = 60;
    final results = <HabitCorrelation>[];

    for (int i = 0; i < habits.length; i++) {
      for (int j = i + 1; j < habits.length; j++) {
        final a = habits[i];
        final b = habits[j];
        int both = 0, onlyA = 0, onlyB = 0, neither = 0;
        for (int d = 0; d < days; d++) {
          final date = today.subtract(Duration(days: d));
          final hasA = a.completedDates.contains(date);
          final hasB = b.completedDates.contains(date);
          if (hasA && hasB) {
            both++;
          } else if (hasA) {
            onlyA++;
          } else if (hasB) {
            onlyB++;
          } else {
            neither++;
          }
        }
        // Phi coefficient
        final n = both + onlyA + onlyB + neither;
        final denom = sqrt((both + onlyA) * (both + onlyB) * (onlyA + neither) * (onlyB + neither));
        final phi = denom == 0 ? 0.0 : (both * neither - onlyA * onlyB) / denom;

        final dir = phi > 0.15 ? 'positive' : phi < -0.15 ? 'negative' : 'neutral';
        final desc = dir == 'positive'
            ? '${a.name} and ${b.name} tend to be completed together'
            : dir == 'negative'
                ? 'Completing ${a.name} seems to reduce ${b.name} completion'
                : '${a.name} and ${b.name} are independent';

        results.add(HabitCorrelation(
          habitA: '${a.emoji} ${a.name}',
          habitB: '${b.emoji} ${b.name}',
          correlationScore: phi,
          description: desc,
          direction: dir,
        ));
      }
    }
    results.sort((a, b) => b.correlationScore.abs().compareTo(a.correlationScore.abs()));
    return results;
  }

  /// Predict streak continuation based on completion rate + momentum.
  List<StreakForecast> forecastStreaks(List<Habit> habits) {
    final svc = HabitTrackerService();
    return habits.map((h) {
      final streak = svc.currentStreak(h);
      final rate30 = svc.completionRate(h, days: 30);
      final rate7 = svc.completionRate(h, days: 7);
      final momentum = rate7 - rate30;

      // Simple geometric model: each future day has P(continue) = adjustedRate
      final adjustedRate = (rate7 + momentum * 0.5).clamp(0.05, 0.99);
      // Expected additional days = adjustedRate / (1 - adjustedRate) capped
      final predicted = (adjustedRate / (1 - adjustedRate)).clamp(0, 30).round();
      final confidence = (rate7 * 0.6 + rate30 * 0.4).clamp(0.0, 1.0);

      final risks = <String>[];
      if (momentum < -0.1) risks.add('Declining momentum (${(momentum * 100).toStringAsFixed(0)}%)');
      if (rate30 < 0.5) risks.add('Low 30-day completion rate (${(rate30 * 100).toStringAsFixed(0)}%)');
      if (streak == 0) risks.add('No active streak');
      final today = _dateOnly(DateTime.now());
      final weekday = today.weekday;
      final dayProfile = _dayRate(h, weekday);
      if (dayProfile < 0.4) risks.add('Tomorrow is a historically weak day');

      return StreakForecast(
        habitName: h.name,
        emoji: h.emoji,
        currentStreak: streak,
        predictedDays: predicted,
        confidence: confidence,
        riskFactors: risks,
      );
    }).toList()
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
  }

  /// Day-of-week completion patterns.
  List<TimingProfile> analyzeTimingPatterns(List<Habit> habits) {
    return habits.map((h) {
      final byDay = <String, double>{};
      for (int wd = 1; wd <= 7; wd++) {
        byDay[_dayNames[wd - 1]] = _dayRate(h, wd);
      }
      final sorted = byDay.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final avg = byDay.values.fold(0.0, (s, v) => s + v) / 7;
      return TimingProfile(
        habitName: h.name,
        emoji: h.emoji,
        bestDayOfWeek: sorted.first.key,
        worstDayOfWeek: sorted.last.key,
        completionByDay: byDay,
        averageRate: avg,
      );
    }).toList();
  }

  /// Per-habit health scoring (0-100).
  List<HabitHealthScore> calculateHealthScores(List<Habit> habits) {
    final svc = HabitTrackerService();
    return habits.map((h) {
      final rate30 = svc.completionRate(h, days: 30);
      final rate7 = svc.completionRate(h, days: 7);
      final streak = svc.currentStreak(h);
      final best = svc.bestStreak(h);

      // Consistency: std-dev of weekly completion rates
      final weeklyRates = <double>[];
      final today = _dateOnly(DateTime.now());
      for (int w = 0; w < 4; w++) {
        int count = 0;
        for (int d = 0; d < 7; d++) {
          if (h.completedDates.contains(today.subtract(Duration(days: w * 7 + d)))) count++;
        }
        weeklyRates.add(count / 7);
      }
      final mean = weeklyRates.fold(0.0, (s, v) => s + v) / weeklyRates.length;
      final variance = weeklyRates.fold(0.0, (s, v) => s + (v - mean) * (v - mean)) / weeklyRates.length;
      final consistency = 1.0 - sqrt(variance); // 0-1, higher = more consistent

      final score = ((rate30 * 35 + rate7 * 25 + (streak / max(best, 1)) * 20 + consistency * 20) * 100 / 100).round().clamp(0, 100);

      final trend = rate7 > rate30 + 0.05 ? 'up' : rate7 < rate30 - 0.05 ? 'down' : 'stable';

      final factors = <String>[];
      if (rate30 > 0.8) factors.add('Strong 30-day rate');
      if (rate30 < 0.5) factors.add('Low completion rate');
      if (streak > 5) factors.add('Active streak of $streak days');
      if (streak == 0) factors.add('No active streak');
      if (consistency > 0.8) factors.add('Very consistent');
      if (consistency < 0.5) factors.add('Inconsistent week-to-week');
      if (trend == 'up') factors.add('Improving trend');
      if (trend == 'down') factors.add('Declining trend');

      return HabitHealthScore(habitName: h.name, emoji: h.emoji, score: score, trend: trend, factors: factors);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  /// Generate prioritized insights.
  List<HabitInsight> generateInsights(List<Habit> habits) {
    final svc = HabitTrackerService();
    final insights = <HabitInsight>[];
    int id = 0;

    final correlations = analyzeCorrelations(habits);
    final forecasts = forecastStreaks(habits);
    final health = calculateHealthScores(habits);
    final timing = analyzeTimingPatterns(habits);

    // Correlation insights
    for (final c in correlations.take(3)) {
      if (c.direction == 'neutral') continue;
      insights.add(HabitInsight(
        id: id++,
        type: InsightType.correlation,
        priority: c.correlationScore.abs() > 0.3 ? InsightPriority.high : InsightPriority.medium,
        title: c.direction == 'positive' ? 'Power Pair Detected' : 'Competing Habits',
        description: c.description,
        emoji: c.direction == 'positive' ? '🔗' : '⚔️',
        relatedHabits: [c.habitA, c.habitB],
        confidence: c.correlationScore.abs().clamp(0.0, 1.0),
      ));
    }

    // Streak celebrations & risks
    for (final f in forecasts) {
      if (f.currentStreak >= 7) {
        insights.add(HabitInsight(
          id: id++,
          type: InsightType.celebration,
          priority: f.currentStreak >= 21 ? InsightPriority.high : InsightPriority.medium,
          title: '${f.emoji} ${f.habitName}: ${f.currentStreak}-day streak!',
          description: 'Predicted to continue ~${f.predictedDays} more days. Keep it up!',
          emoji: '🔥',
          relatedHabits: [f.habitName],
          confidence: f.confidence,
        ));
      }
      if (f.riskFactors.isNotEmpty && f.currentStreak > 0) {
        insights.add(HabitInsight(
          id: id++,
          type: InsightType.risk,
          priority: f.riskFactors.length >= 2 ? InsightPriority.high : InsightPriority.medium,
          title: '${f.emoji} ${f.habitName} streak at risk',
          description: f.riskFactors.join('. '),
          emoji: '⚠️',
          relatedHabits: [f.habitName],
          confidence: 1.0 - f.confidence,
          actionable: true,
          action: 'Complete ${f.habitName} today to protect your streak',
        ));
      }
    }

    // Timing suggestions
    for (final t in timing) {
      final worst = t.completionByDay[t.worstDayOfWeek] ?? 0;
      if (worst < 0.4) {
        insights.add(HabitInsight(
          id: id++,
          type: InsightType.optimalTiming,
          priority: InsightPriority.low,
          title: '${t.emoji} ${t.habitName}: ${t.worstDayOfWeek} is your weak spot',
          description: 'Only ${(worst * 100).toStringAsFixed(0)}% completion on ${t.worstDayOfWeek}s vs ${(t.completionByDay[t.bestDayOfWeek]! * 100).toStringAsFixed(0)}% on ${t.bestDayOfWeek}s.',
          emoji: '📅',
          relatedHabits: [t.habitName],
          confidence: 0.75,
          actionable: true,
          action: 'Set a ${t.worstDayOfWeek} reminder for ${t.habitName}',
        ));
      }
    }

    // Health warnings
    for (final h in health) {
      if (h.score < 40) {
        insights.add(HabitInsight(
          id: id++,
          type: InsightType.risk,
          priority: InsightPriority.critical,
          title: '${h.emoji} ${h.habitName} needs attention (score: ${h.score})',
          description: h.factors.join('. '),
          emoji: '🏥',
          relatedHabits: [h.habitName],
          confidence: 0.85,
          actionable: true,
          action: 'Consider reducing ${h.habitName} frequency or pairing it with a stronger habit',
        ));
      }
    }

    // General suggestions
    final avgRate = habits.fold(0.0, (s, h) => s + svc.completionRate(h)) / habits.length;
    if (avgRate > 0.7) {
      insights.add(HabitInsight(
        id: id++,
        type: InsightType.suggestion,
        priority: InsightPriority.low,
        title: 'Ready for a new habit?',
        description: 'Your average completion is ${(avgRate * 100).toStringAsFixed(0)}%. You have capacity to add one more habit.',
        emoji: '🌱',
        confidence: 0.6,
        actionable: true,
        action: 'Browse habit suggestions',
      ));
    }

    insights.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return insights;
  }

  /// Overall summary.
  InsightsSummary getSummary(List<Habit> habits) {
    final svc = HabitTrackerService();
    final rates = habits.map((h) => svc.completionRate(h)).toList();
    final avg = rates.fold(0.0, (s, v) => s + v) / rates.length;
    final sorted = List.of(habits)..sort((a, b) => svc.completionRate(b).compareTo(svc.completionRate(a)));
    final grade = avg >= 0.85 ? 'A' : avg >= 0.70 ? 'B' : avg >= 0.55 ? 'C' : avg >= 0.40 ? 'D' : 'F';
    return InsightsSummary(
      totalHabits: habits.length,
      avgCompletionRate: avg,
      strongestHabit: '${sorted.first.emoji} ${sorted.first.name}',
      weakestHabit: '${sorted.last.emoji} ${sorted.last.name}',
      totalInsights: generateInsights(habits).length,
      healthGrade: grade,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  double _dayRate(Habit h, int weekday) {
    final today = _dateOnly(DateTime.now());
    int total = 0, completed = 0;
    for (int d = 0; d < 60; d++) {
      final date = today.subtract(Duration(days: d));
      if (date.weekday == weekday) {
        total++;
        if (h.completedDates.contains(date)) completed++;
      }
    }
    return total == 0 ? 0 : completed / total;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
