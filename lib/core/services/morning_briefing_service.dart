/// Morning Briefing service — aggregates signals across trackers to produce
/// a daily briefing with proactive insights and recommendations.
///
/// This is an "inter-system awareness" feature: it correlates data from
/// habits, mood, sleep, water, energy, and focus trackers to surface
/// patterns a single tracker couldn't detect.
import 'dart:math';

class MorningBriefingService {
  /// Generate today's briefing from recent tracker data.
  MorningBriefing generate({
    List<DailySnapshot> recentDays = const [],
  }) {
    final today = DateTime.now();
    final dayOfWeek = today.weekday; // 1=Mon, 7=Sun

    // If no data, generate a starter briefing with defaults
    final snapshots = recentDays.isEmpty ? _generateSampleData(7) : recentDays;
    final latest = snapshots.last;

    final insights = <BriefingInsight>[];
    final recommendations = <String>[];

    // ── Streak Analysis ──
    final habitCompletionRates = snapshots.map((s) => s.habitsCompleted / max(s.habitsTotal, 1)).toList();
    final avgHabitRate = habitCompletionRates.fold<double>(0, (a, b) => a + b) / habitCompletionRates.length;

    if (avgHabitRate >= 0.8) {
      insights.add(BriefingInsight(
        icon: '🔥',
        title: 'Habit streak is strong',
        detail: '${(avgHabitRate * 100).round()}% completion over the last ${snapshots.length} days',
        sentiment: InsightSentiment.positive,
      ));
    } else if (avgHabitRate < 0.5) {
      insights.add(BriefingInsight(
        icon: '⚠️',
        title: 'Habits slipping',
        detail: 'Only ${(avgHabitRate * 100).round()}% completion recently. Pick 1-2 habits to focus on today.',
        sentiment: InsightSentiment.warning,
      ));
      recommendations.add('Start with your easiest habit to build momentum');
    }

    // ── Mood Trend ──
    final moods = snapshots.map((s) => s.moodScore).toList();
    final avgMood = moods.fold<double>(0, (a, b) => a + b) / moods.length;
    final recentMood = moods.length >= 3
        ? moods.sublist(moods.length - 3).fold<double>(0, (a, b) => a + b) / 3
        : avgMood;

    if (recentMood < avgMood - 0.5) {
      insights.add(BriefingInsight(
        icon: '📉',
        title: 'Mood trending down',
        detail: 'Recent average ${recentMood.toStringAsFixed(1)} vs overall ${avgMood.toStringAsFixed(1)}',
        sentiment: InsightSentiment.warning,
      ));
      recommendations.add('Consider a short walk or breathing exercise');
    } else if (recentMood > avgMood + 0.3) {
      insights.add(BriefingInsight(
        icon: '😊',
        title: 'Mood is up!',
        detail: 'You\'ve been feeling better than usual lately',
        sentiment: InsightSentiment.positive,
      ));
    }

    // ── Sleep Quality ──
    final sleepHours = snapshots.map((s) => s.sleepHours).toList();
    final avgSleep = sleepHours.fold<double>(0, (a, b) => a + b) / sleepHours.length;

    if (latest.sleepHours < 6) {
      insights.add(BriefingInsight(
        icon: '😴',
        title: 'Low sleep last night',
        detail: '${latest.sleepHours.toStringAsFixed(1)}h — aim for 7-9h tonight',
        sentiment: InsightSentiment.warning,
      ));
      recommendations.add('Avoid caffeine after 2pm today');
    } else if (latest.sleepHours >= 7 && latest.sleepHours <= 9) {
      insights.add(BriefingInsight(
        icon: '🌙',
        title: 'Great sleep',
        detail: '${latest.sleepHours.toStringAsFixed(1)}h — well within the optimal range',
        sentiment: InsightSentiment.positive,
      ));
    }

    // ── Hydration ──
    final waterAvg = snapshots.map((s) => s.waterGlasses).fold<double>(0, (a, b) => a + b) / snapshots.length;
    if (waterAvg < 6) {
      insights.add(BriefingInsight(
        icon: '💧',
        title: 'Hydration needs attention',
        detail: 'Averaging ${waterAvg.toStringAsFixed(1)} glasses/day — target is 8',
        sentiment: InsightSentiment.warning,
      ));
      recommendations.add('Set a glass-of-water reminder every 2 hours');
    }

    // ── Energy Pattern ──
    final energyLevels = snapshots.map((s) => s.energyLevel).toList();
    final avgEnergy = energyLevels.fold<double>(0, (a, b) => a + b) / energyLevels.length;

    if (avgEnergy < 5) {
      insights.add(BriefingInsight(
        icon: '🔋',
        title: 'Energy running low',
        detail: 'Average ${avgEnergy.toStringAsFixed(1)}/10 this week',
        sentiment: InsightSentiment.warning,
      ));
      recommendations.add('Try a 20-minute power nap or a brisk walk');
    }

    // ── Cross-Signal Correlations ──
    if (latest.sleepHours < 6 && latest.energyLevel < 5) {
      insights.add(BriefingInsight(
        icon: '🔗',
        title: 'Sleep → Energy link detected',
        detail: 'Low sleep is likely affecting your energy today',
        sentiment: InsightSentiment.correlation,
      ));
      recommendations.add('Prioritize your top 3 tasks — save creative work for tomorrow');
    }

    if (avgMood > 7 && avgHabitRate > 0.7) {
      insights.add(BriefingInsight(
        icon: '✨',
        title: 'Positive feedback loop',
        detail: 'Strong habits and good mood are reinforcing each other!',
        sentiment: InsightSentiment.positive,
      ));
    }

    // ── Day-of-Week Pattern ──
    final dayName = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][dayOfWeek];
    if (dayOfWeek == 1) {
      recommendations.add('It\'s Monday — set 3 intentions for the week');
    } else if (dayOfWeek == 5) {
      recommendations.add('It\'s Friday — great day to review your weekly wins');
    } else if (dayOfWeek >= 6) {
      recommendations.add('Weekend mode — rest and recharge are productive too');
    }

    // ── Focus Score ──
    final focusAvg = snapshots.map((s) => s.focusMinutes).fold<double>(0, (a, b) => a + b) / snapshots.length;
    if (focusAvg > 0) {
      insights.add(BriefingInsight(
        icon: '🎯',
        title: 'Focus time',
        detail: '${focusAvg.round()} min/day average — ${focusAvg >= 120 ? "excellent deep work!" : "try for 2+ hours today"}',
        sentiment: focusAvg >= 120 ? InsightSentiment.positive : InsightSentiment.neutral,
      ));
    }

    // Overall score (0-100)
    final overallScore = _computeOverallScore(latest, avgHabitRate, avgMood, avgSleep, avgEnergy);

    return MorningBriefing(
      date: today,
      dayName: dayName,
      overallScore: overallScore,
      greeting: _greeting(today),
      insights: insights,
      recommendations: recommendations,
      snapshot: latest,
    );
  }

  String _greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  double _computeOverallScore(DailySnapshot s, double habitRate, double avgMood, double avgSleep, double avgEnergy) {
    // Weighted composite: habits 25%, mood 25%, sleep 25%, energy 15%, water 10%
    final habitScore = habitRate * 100;
    final moodScore = (avgMood / 10) * 100;
    final sleepScore = (avgSleep.clamp(0, 9) / 9) * 100;
    final energyScore = (avgEnergy / 10) * 100;
    final waterScore = (s.waterGlasses.clamp(0, 10) / 10) * 100;

    return (habitScore * 0.25 + moodScore * 0.25 + sleepScore * 0.25 + energyScore * 0.15 + waterScore * 0.10).clamp(0, 100);
  }

  List<DailySnapshot> _generateSampleData(int days) {
    final rng = Random(DateTime.now().day);
    return List.generate(days, (i) {
      final base = 5 + rng.nextInt(4);
      return DailySnapshot(
        date: DateTime.now().subtract(Duration(days: days - 1 - i)),
        habitsCompleted: 2 + rng.nextInt(4),
        habitsTotal: 5,
        moodScore: 4.0 + rng.nextDouble() * 5,
        sleepHours: 5.5 + rng.nextDouble() * 3.5,
        waterGlasses: 3 + rng.nextInt(7),
        energyLevel: 3.0 + rng.nextDouble() * 6,
        focusMinutes: 30 + rng.nextInt(150),
      );
    });
  }
}

class MorningBriefing {
  final DateTime date;
  final String dayName;
  final double overallScore;
  final String greeting;
  final List<BriefingInsight> insights;
  final List<String> recommendations;
  final DailySnapshot snapshot;

  MorningBriefing({
    required this.date,
    required this.dayName,
    required this.overallScore,
    required this.greeting,
    required this.insights,
    required this.recommendations,
    required this.snapshot,
  });
}

class BriefingInsight {
  final String icon;
  final String title;
  final String detail;
  final InsightSentiment sentiment;

  BriefingInsight({
    required this.icon,
    required this.title,
    required this.detail,
    required this.sentiment,
  });
}

enum InsightSentiment { positive, warning, neutral, correlation }

class DailySnapshot {
  final DateTime date;
  final int habitsCompleted;
  final int habitsTotal;
  final double moodScore; // 0-10
  final double sleepHours;
  final int waterGlasses;
  final double energyLevel; // 0-10
  final int focusMinutes;

  DailySnapshot({
    required this.date,
    required this.habitsCompleted,
    required this.habitsTotal,
    required this.moodScore,
    required this.sleepHours,
    required this.waterGlasses,
    required this.energyLevel,
    required this.focusMinutes,
  });
}
