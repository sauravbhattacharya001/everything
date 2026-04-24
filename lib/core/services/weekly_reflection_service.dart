import 'dart:math' as math;

/// Represents one day's aggregated cross-tracker snapshot.
class DaySnapshot {
  final DateTime date;
  final double? moodScore;
  final int habitsCompleted;
  final int habitsTotal;
  final double? energyLevel;
  final double? productivityScore;
  final double? sleepHours;
  final double? exerciseMinutes;
  final double? spendingAmount;
  final int journalEntries;
  final double? stressLevel;
  final double? socialBattery;

  DaySnapshot({
    required this.date,
    this.moodScore,
    this.habitsCompleted = 0,
    this.habitsTotal = 0,
    this.energyLevel,
    this.productivityScore,
    this.sleepHours,
    this.exerciseMinutes,
    this.spendingAmount,
    this.journalEntries = 0,
    this.stressLevel,
    this.socialBattery,
  });

  double get habitCompletionRate =>
      habitsTotal > 0 ? habitsCompleted / habitsTotal : 0;
}

/// A detected weekly pattern or insight.
class WeeklyInsight {
  final String title;
  final String description;
  final InsightType type;
  final double confidence;
  final String emoji;

  WeeklyInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.confidence,
    required this.emoji,
  });
}

enum InsightType { win, concern, pattern, recommendation, milestone }

/// Auto-generated goal suggestion for next week.
class GoalSuggestion {
  final String title;
  final String rationale;
  final String metric;
  final double targetValue;
  final GoalDifficulty difficulty;

  GoalSuggestion({
    required this.title,
    required this.rationale,
    required this.metric,
    required this.targetValue,
    required this.difficulty,
  });
}

enum GoalDifficulty { easy, moderate, stretch }

/// Complete weekly reflection report.
class WeeklyReflection {
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<DaySnapshot> days;
  final double overallScore;
  final String overallVerdict;
  final String verdictEmoji;
  final List<WeeklyInsight> insights;
  final List<GoalSuggestion> suggestedGoals;
  final Map<String, double> dimensionScores;
  final String weekSummary;
  final String bestDay;
  final String toughestDay;

  WeeklyReflection({
    required this.weekStart,
    required this.weekEnd,
    required this.days,
    required this.overallScore,
    required this.overallVerdict,
    required this.verdictEmoji,
    required this.insights,
    required this.suggestedGoals,
    required this.dimensionScores,
    required this.weekSummary,
    required this.bestDay,
    required this.toughestDay,
  });
}

/// Generates autonomous weekly reflections by analyzing cross-tracker data.
class WeeklyReflectionService {
  WeeklyReflectionService._();

  static WeeklyReflection generateReflection(List<DaySnapshot> days) {
    if (days.isEmpty) {
      return WeeklyReflection(
        weekStart: DateTime.now().subtract(const Duration(days: 6)),
        weekEnd: DateTime.now(),
        days: [],
        overallScore: 0,
        overallVerdict: 'No Data',
        verdictEmoji: '📭',
        insights: [
          WeeklyInsight(
            title: 'No Data Available',
            description: 'Start tracking to get weekly reflections!',
            type: InsightType.recommendation,
            confidence: 1.0,
            emoji: '📊',
          ),
        ],
        suggestedGoals: [],
        dimensionScores: {},
        weekSummary: 'No tracking data found for this week.',
        bestDay: '-',
        toughestDay: '-',
      );
    }

    final sorted = List<DaySnapshot>.from(days)
      ..sort((a, b) => a.date.compareTo(b.date));
    final weekStart = sorted.first.date;
    final weekEnd = sorted.last.date;
    final dimensions = _calculateDimensions(sorted);
    final overallScore = _calculateOverallScore(dimensions);
    final insights = _detectInsights(sorted, dimensions);
    final goals = _generateGoals(dimensions);
    final bestDay = _findBestDay(sorted);
    final toughestDay = _findToughestDay(sorted);
    final verdict = _generateVerdict(overallScore);
    final summary = _generateSummary(sorted, dimensions, insights);

    return WeeklyReflection(
      weekStart: weekStart,
      weekEnd: weekEnd,
      days: sorted,
      overallScore: overallScore,
      overallVerdict: verdict.$1,
      verdictEmoji: verdict.$2,
      insights: insights,
      suggestedGoals: goals,
      dimensionScores: dimensions,
      weekSummary: summary,
      bestDay: bestDay,
      toughestDay: toughestDay,
    );
  }

  static Map<String, double> _calculateDimensions(List<DaySnapshot> days) {
    final dims = <String, double>{};

    final moods = days
        .where((d) => d.moodScore != null)
        .map((d) => d.moodScore!)
        .toList();
    if (moods.isNotEmpty) {
      dims['Mood'] = moods.reduce((a, b) => a + b) / moods.length;
    }

    final habitRates = days
        .where((d) => d.habitsTotal > 0)
        .map((d) => d.habitCompletionRate * 100)
        .toList();
    if (habitRates.isNotEmpty) {
      dims['Habits'] = habitRates.reduce((a, b) => a + b) / habitRates.length;
    }

    final energies = days
        .where((d) => d.energyLevel != null)
        .map((d) => d.energyLevel!)
        .toList();
    if (energies.isNotEmpty) {
      dims['Energy'] = energies.reduce((a, b) => a + b) / energies.length;
    }

    final prods = days
        .where((d) => d.productivityScore != null)
        .map((d) => d.productivityScore!)
        .toList();
    if (prods.isNotEmpty) {
      dims['Productivity'] = prods.reduce((a, b) => a + b) / prods.length;
    }

    final sleeps = days
        .where((d) => d.sleepHours != null)
        .map((d) => d.sleepHours!)
        .toList();
    if (sleeps.isNotEmpty) {
      final avgSleep = sleeps.reduce((a, b) => a + b) / sleeps.length;
      dims['Sleep'] = (avgSleep / 8.0 * 100).clamp(0, 100);
    }

    final exercises = days
        .where((d) => d.exerciseMinutes != null)
        .map((d) => d.exerciseMinutes!)
        .toList();
    if (exercises.isNotEmpty) {
      final avgExercise = exercises.reduce((a, b) => a + b) / exercises.length;
      dims['Exercise'] = (avgExercise / 60.0 * 100).clamp(0, 100);
    }

    final stresses = days
        .where((d) => d.stressLevel != null)
        .map((d) => d.stressLevel!)
        .toList();
    if (stresses.isNotEmpty) {
      dims['Calm'] =
          100 - (stresses.reduce((a, b) => a + b) / stresses.length);
    }

    final socials = days
        .where((d) => d.socialBattery != null)
        .map((d) => d.socialBattery!)
        .toList();
    if (socials.isNotEmpty) {
      dims['Social'] = socials.reduce((a, b) => a + b) / socials.length;
    }

    return dims;
  }

  static double _calculateOverallScore(Map<String, double> dims) {
    if (dims.isEmpty) return 0;
    const weights = {
      'Mood': 1.5,
      'Habits': 1.2,
      'Energy': 1.0,
      'Productivity': 1.3,
      'Sleep': 1.4,
      'Exercise': 0.8,
      'Calm': 1.1,
      'Social': 0.7,
    };
    double totalWeight = 0;
    double weightedSum = 0;
    for (final entry in dims.entries) {
      final w = weights[entry.key] ?? 1.0;
      weightedSum += entry.value * w;
      totalWeight += w;
    }
    return totalWeight > 0 ? (weightedSum / totalWeight).clamp(0, 100) : 0;
  }

  static List<WeeklyInsight> _detectInsights(
      List<DaySnapshot> days, Map<String, double> dims) {
    final insights = <WeeklyInsight>[];

    // Win: High habit completion
    final habitRates = days
        .where((d) => d.habitsTotal > 0)
        .map((d) => d.habitCompletionRate)
        .toList();
    if (habitRates.isNotEmpty) {
      final avg = habitRates.reduce((a, b) => a + b) / habitRates.length;
      if (avg >= 0.8) {
        insights.add(WeeklyInsight(
          title: 'Habit Champion',
          description:
              'You completed ${(avg * 100).round()}% of your habits this week. Consistency is your superpower!',
          type: InsightType.win,
          confidence: 0.95,
          emoji: '🏆',
        ));
      }
    }

    // Pattern: Mood trend
    final moods =
        days.where((d) => d.moodScore != null).toList();
    if (moods.length >= 3) {
      final firstHalf = moods.sublist(0, moods.length ~/ 2);
      final secondHalf = moods.sublist(moods.length ~/ 2);
      final avgFirst = firstHalf
              .map((d) => d.moodScore!)
              .reduce((a, b) => a + b) /
          firstHalf.length;
      final avgSecond = secondHalf
              .map((d) => d.moodScore!)
              .reduce((a, b) => a + b) /
          secondHalf.length;
      if (avgSecond - avgFirst > 10) {
        insights.add(WeeklyInsight(
          title: 'Rising Spirits',
          description:
              'Your mood improved as the week progressed. Something is working!',
          type: InsightType.pattern,
          confidence: 0.8,
          emoji: '📈',
        ));
      } else if (avgFirst - avgSecond > 10) {
        insights.add(WeeklyInsight(
          title: 'Mood Dip Detected',
          description:
              'Your mood declined toward the end of the week. Consider what drained you.',
          type: InsightType.concern,
          confidence: 0.8,
          emoji: '📉',
        ));
      }
    }

    // Concern: Low sleep
    final sleeps = days
        .where((d) => d.sleepHours != null)
        .map((d) => d.sleepHours!)
        .toList();
    if (sleeps.isNotEmpty) {
      final avg = sleeps.reduce((a, b) => a + b) / sleeps.length;
      if (avg < 6) {
        insights.add(WeeklyInsight(
          title: 'Sleep Deficit',
          description:
              'You averaged ${avg.toStringAsFixed(1)}h of sleep. Your body needs more rest.',
          type: InsightType.concern,
          confidence: 0.9,
          emoji: '😴',
        ));
      } else if (avg >= 7.5) {
        insights.add(WeeklyInsight(
          title: 'Well Rested',
          description:
              'Great sleep averaging ${avg.toStringAsFixed(1)}h per night!',
          type: InsightType.win,
          confidence: 0.9,
          emoji: '🌙',
        ));
      }
    }

    // Pattern: Exercise consistency
    final exerciseDays = days
        .where(
            (d) => d.exerciseMinutes != null && d.exerciseMinutes! > 0)
        .length;
    if (days.length >= 5 && exerciseDays >= 5) {
      insights.add(WeeklyInsight(
        title: 'Active Lifestyle',
        description:
            'You exercised $exerciseDays out of ${days.length} days!',
        type: InsightType.win,
        confidence: 0.85,
        emoji: '💪',
      ));
    } else if (days.length >= 5 && exerciseDays <= 1) {
      insights.add(WeeklyInsight(
        title: 'Movement Gap',
        description:
            'Only $exerciseDays day(s) with exercise. Even short walks help.',
        type: InsightType.recommendation,
        confidence: 0.85,
        emoji: '🚶',
      ));
    }

    // Stress-productivity correlation
    final stressProds = days
        .where(
            (d) => d.stressLevel != null && d.productivityScore != null)
        .toList();
    if (stressProds.length >= 3) {
      final highStress =
          stressProds.where((d) => d.stressLevel! > 60).toList();
      final lowStress =
          stressProds.where((d) => d.stressLevel! <= 40).toList();
      if (highStress.isNotEmpty && lowStress.isNotEmpty) {
        final hsProd = highStress
                .map((d) => d.productivityScore!)
                .reduce((a, b) => a + b) /
            highStress.length;
        final lsProd = lowStress
                .map((d) => d.productivityScore!)
                .reduce((a, b) => a + b) /
            lowStress.length;
        if (lsProd - hsProd > 15) {
          insights.add(WeeklyInsight(
            title: 'Calm = Productive',
            description:
                'You were ${(lsProd - hsProd).round()}% more productive on low-stress days.',
            type: InsightType.pattern,
            confidence: 0.75,
            emoji: '🧘',
          ));
        }
      }
    }

    // Milestone: Journal streak
    final journalDays =
        days.where((d) => d.journalEntries > 0).length;
    if (journalDays == days.length && days.length >= 5) {
      insights.add(WeeklyInsight(
        title: 'Daily Reflection Streak',
        description: 'You journaled every day this week!',
        type: InsightType.milestone,
        confidence: 1.0,
        emoji: '📝',
      ));
    }

    // Balance recommendation
    if (dims.length >= 3) {
      final scores = dims.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final lowest = scores.first;
      final highest = scores.last;
      if (highest.value - lowest.value > 30) {
        insights.add(WeeklyInsight(
          title: 'Balance Opportunity',
          description:
              '${lowest.key} (${lowest.value.round()}) lags behind ${highest.key} (${highest.value.round()}).',
          type: InsightType.recommendation,
          confidence: 0.7,
          emoji: '⚖️',
        ));
      }
    }

    // Social battery
    final socials = days
        .where((d) => d.socialBattery != null)
        .map((d) => d.socialBattery!)
        .toList();
    if (socials.length >= 3) {
      final avg = socials.reduce((a, b) => a + b) / socials.length;
      if (avg < 30) {
        insights.add(WeeklyInsight(
          title: 'Social Energy Low',
          description:
              'Social battery averaged ${avg.round()}%. Schedule recharge time.',
          type: InsightType.concern,
          confidence: 0.8,
          emoji: '🔋',
        ));
      }
    }

    return insights;
  }

  static List<GoalSuggestion> _generateGoals(Map<String, double> dims) {
    final goals = <GoalSuggestion>[];

    if (dims.containsKey('Habits') && dims['Habits']! < 80) {
      goals.add(GoalSuggestion(
        title: 'Boost Habit Consistency',
        rationale: 'Currently at ${dims['Habits']!.round()}% — push higher.',
        metric: 'Habit completion rate',
        targetValue: math.min(dims['Habits']! + 10, 100),
        difficulty:
            dims['Habits']! < 50 ? GoalDifficulty.moderate : GoalDifficulty.easy,
      ));
    }

    if (dims.containsKey('Sleep') && dims['Sleep']! < 85) {
      goals.add(GoalSuggestion(
        title: 'Improve Sleep Quality',
        rationale: 'Better sleep improves mood, energy, and productivity.',
        metric: 'Average sleep hours',
        targetValue: 7.5,
        difficulty: GoalDifficulty.moderate,
      ));
    }

    if (dims.containsKey('Exercise') && dims['Exercise']! < 60) {
      goals.add(GoalSuggestion(
        title: 'Move More',
        rationale: 'Exercise is the most underrated productivity hack.',
        metric: 'Active days this week',
        targetValue: 4,
        difficulty: GoalDifficulty.easy,
      ));
    }

    if (dims.containsKey('Calm') && dims['Calm']! < 60) {
      goals.add(GoalSuggestion(
        title: 'Reduce Stress',
        rationale: 'High stress is hurting other areas. Try breathing exercises.',
        metric: 'Average stress level',
        targetValue: 40,
        difficulty: GoalDifficulty.stretch,
      ));
    }

    if (dims.containsKey('Productivity') && dims['Productivity']! < 70) {
      goals.add(GoalSuggestion(
        title: 'Productivity Push',
        rationale: 'Small focus improvements compound into big results.',
        metric: 'Productivity score',
        targetValue: math.min(dims['Productivity']! + 15, 100),
        difficulty: GoalDifficulty.moderate,
      ));
    }

    if (goals.length > 3) goals.removeRange(3, goals.length);
    return goals;
  }

  static String _findBestDay(List<DaySnapshot> days) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    DaySnapshot? best;
    double bestScore = -1;
    for (final d in days) {
      double s = 0;
      int c = 0;
      if (d.moodScore != null) { s += d.moodScore!; c++; }
      if (d.energyLevel != null) { s += d.energyLevel!; c++; }
      if (d.productivityScore != null) { s += d.productivityScore!; c++; }
      if (d.habitsTotal > 0) { s += d.habitCompletionRate * 100; c++; }
      if (c > 0 && s / c > bestScore) {
        bestScore = s / c;
        best = d;
      }
    }
    if (best == null) return '-';
    return '${dayNames[best.date.weekday - 1]} ${best.date.month}/${best.date.day}';
  }

  static String _findToughestDay(List<DaySnapshot> days) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    DaySnapshot? worst;
    double worstScore = 101;
    for (final d in days) {
      double s = 0;
      int c = 0;
      if (d.moodScore != null) { s += d.moodScore!; c++; }
      if (d.energyLevel != null) { s += d.energyLevel!; c++; }
      if (d.productivityScore != null) { s += d.productivityScore!; c++; }
      if (d.habitsTotal > 0) { s += d.habitCompletionRate * 100; c++; }
      if (c > 0 && s / c < worstScore) {
        worstScore = s / c;
        worst = d;
      }
    }
    if (worst == null) return '-';
    return '${dayNames[worst.date.weekday - 1]} ${worst.date.month}/${worst.date.day}';
  }

  static (String, String) _generateVerdict(double score) {
    if (score >= 85) return ('Outstanding Week', '🌟');
    if (score >= 70) return ('Great Week', '😊');
    if (score >= 55) return ('Solid Week', '👍');
    if (score >= 40) return ('Mixed Week', '🤷');
    if (score >= 25) return ('Tough Week', '😔');
    return ('Recovery Needed', '🫂');
  }

  static String _generateSummary(List<DaySnapshot> days,
      Map<String, double> dims, List<WeeklyInsight> insights) {
    final parts = <String>[];
    final wins = insights.where((i) => i.type == InsightType.win).length;
    final concerns =
        insights.where((i) => i.type == InsightType.concern).length;

    if (dims.isNotEmpty) {
      final best = (dims.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .first;
      parts.add(
          'Your strongest dimension was ${best.key} at ${best.value.round()}%.');
    }
    if (wins > 0) {
      parts.add('$wins win${wins > 1 ? 's' : ''} detected this week!');
    }
    if (concerns > 0) {
      parts.add(
          '$concerns area${concerns > 1 ? 's' : ''} need${concerns == 1 ? 's' : ''} attention.');
    }
    parts.add('${days.length} days of data analyzed.');
    return parts.join(' ');
  }
}
