/// Smart Streak Guardian Service — autonomous streak risk monitoring
/// across all app trackers with proactive warnings, rescue strategies,
/// and streak health scoring.
///
/// Aggregates streak data from habits, workouts, meditation, water,
/// sleep, and event activity to detect at-risk streaks before they break.


/// Risk level for a tracked streak.
enum StreakRisk {
  safe,
  watch,
  danger,
  critical,
  broken;

  String get label {
    switch (this) {
      case StreakRisk.safe:
        return 'Safe';
      case StreakRisk.watch:
        return 'Watch';
      case StreakRisk.danger:
        return 'Danger';
      case StreakRisk.critical:
        return 'Critical';
      case StreakRisk.broken:
        return 'Broken';
    }
  }

  String get emoji {
    switch (this) {
      case StreakRisk.safe:
        return '🛡️';
      case StreakRisk.watch:
        return '👀';
      case StreakRisk.danger:
        return '⚠️';
      case StreakRisk.critical:
        return '🚨';
      case StreakRisk.broken:
        return '💔';
    }
  }
}

/// A rescue strategy suggestion for protecting a streak.
class RescueStrategy {
  final String title;
  final String description;
  final String emoji;
  final int effortMinutes;

  const RescueStrategy({
    required this.title,
    required this.description,
    required this.emoji,
    required this.effortMinutes,
  });
}

/// Analysis of a single tracked streak.
class StreakAnalysis {
  final String trackerName;
  final String trackerEmoji;
  final int currentStreak;
  final int longestStreak;
  final StreakRisk risk;
  final double healthScore; // 0-100
  final String timeRemaining; // e.g. "6h 30m left today"
  final List<RescueStrategy> rescueStrategies;
  final List<String> insights;
  final bool completedToday;
  final double weeklyConsistency; // 0-1
  final int? predictedBreakDay; // days until likely break, null = stable

  const StreakAnalysis({
    required this.trackerName,
    required this.trackerEmoji,
    required this.currentStreak,
    required this.longestStreak,
    required this.risk,
    required this.healthScore,
    required this.timeRemaining,
    required this.rescueStrategies,
    required this.insights,
    required this.completedToday,
    required this.weeklyConsistency,
    this.predictedBreakDay,
  });
}

/// Fleet-level streak health summary.
class StreakFleetSummary {
  final int totalTracked;
  final int safe;
  final int watching;
  final int inDanger;
  final int critical;
  final int broken;
  final double overallHealth; // 0-100
  final int activeStreaks;
  final int totalStreakDays;
  final List<String> topActions;
  final String guardianVerdict;

  const StreakFleetSummary({
    required this.totalTracked,
    required this.safe,
    required this.watching,
    required this.inDanger,
    required this.critical,
    required this.broken,
    required this.overallHealth,
    required this.activeStreaks,
    required this.totalStreakDays,
    required this.topActions,
    required this.guardianVerdict,
  });
}

/// Service that monitors all trackable streaks and provides proactive
/// risk assessment and rescue strategies.
class StreakGuardianService {
  final DateTime? _referenceTime;

  StreakGuardianService({DateTime? referenceTime})
      : _referenceTime = referenceTime;

  DateTime get _now => _referenceTime ?? DateTime.now();

  /// Get sample tracker data for demo mode.
  List<Map<String, dynamic>> getSampleTrackers() {
    final now = _now;
    final today = DateTime(now.year, now.month, now.day);
    return [
      {
        'name': 'Daily Exercise',
        'emoji': '🏋️',
        'currentStreak': 23,
        'longestStreak': 45,
        'completedToday': false,
        'lastCompletedDays': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
          14, 15, 16, 17, 18, 19, 20, 21, 22],
        'weeklyCompletions': 6,
        'typicalTime': 'morning',
      },
      {
        'name': 'Meditation',
        'emoji': '🧘',
        'currentStreak': 12,
        'longestStreak': 30,
        'completedToday': true,
        'lastCompletedDays': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
        'weeklyCompletions': 7,
        'typicalTime': 'morning',
      },
      {
        'name': 'Water Intake',
        'emoji': '💧',
        'currentStreak': 5,
        'longestStreak': 18,
        'completedToday': false,
        'lastCompletedDays': [0, 1, 2, 3, 4],
        'weeklyCompletions': 5,
        'typicalTime': 'throughout',
      },
      {
        'name': 'Reading',
        'emoji': '📚',
        'currentStreak': 0,
        'longestStreak': 14,
        'completedToday': false,
        'lastCompletedDays': <int>[],
        'weeklyCompletions': 2,
        'typicalTime': 'evening',
      },
      {
        'name': 'Sleep 7+ Hours',
        'emoji': '😴',
        'currentStreak': 8,
        'longestStreak': 21,
        'completedToday': true,
        'lastCompletedDays': [0, 1, 2, 3, 4, 5, 6, 7],
        'weeklyCompletions': 7,
        'typicalTime': 'night',
      },
      {
        'name': 'Journaling',
        'emoji': '📝',
        'currentStreak': 3,
        'longestStreak': 10,
        'completedToday': false,
        'lastCompletedDays': [0, 1, 2],
        'weeklyCompletions': 4,
        'typicalTime': 'evening',
      },
      {
        'name': 'No Sugar',
        'emoji': '🚫🍬',
        'currentStreak': 15,
        'longestStreak': 15,
        'completedToday': true,
        'lastCompletedDays': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
        'weeklyCompletions': 7,
        'typicalTime': 'daily',
      },
      {
        'name': 'Coding Practice',
        'emoji': '💻',
        'currentStreak': 41,
        'longestStreak': 41,
        'completedToday': false,
        'lastCompletedDays': List.generate(41, (i) => i),
        'weeklyCompletions': 5,
        'typicalTime': 'afternoon',
      },
    ];
  }

  /// Analyze a single tracker's streak health.
  StreakAnalysis analyzeTracker(Map<String, dynamic> tracker) {
    final name = tracker['name'] as String;
    final emoji = tracker['emoji'] as String;
    final current = tracker['currentStreak'] as int;
    final longest = tracker['longestStreak'] as int;
    final completedToday = tracker['completedToday'] as bool;
    final weeklyCompletions = tracker['weeklyCompletions'] as int;
    final typicalTime = tracker['typicalTime'] as String;

    final now = _now;
    final hour = now.hour;
    final hoursLeft = 24 - hour;
    final minutesLeft = 60 - now.minute;

    final timeRemaining = hoursLeft > 0
        ? '${hoursLeft}h ${minutesLeft}m left today'
        : 'Day ending soon!';

    final weeklyConsistency = weeklyCompletions / 7.0;

    // Determine risk
    StreakRisk risk;
    if (current == 0) {
      risk = StreakRisk.broken;
    } else if (completedToday) {
      risk = StreakRisk.safe;
    } else if (hoursLeft <= 2) {
      risk = StreakRisk.critical;
    } else if (hoursLeft <= 6) {
      risk = weeklyConsistency < 0.5 ? StreakRisk.critical : StreakRisk.danger;
    } else if (hoursLeft <= 12) {
      risk = weeklyConsistency < 0.4 ? StreakRisk.danger : StreakRisk.watch;
    } else {
      risk = StreakRisk.safe;
    }

    // Boost risk for long/record streaks (more to lose)
    if (!completedToday && current >= 20 && risk == StreakRisk.watch) {
      risk = StreakRisk.danger;
    }
    if (!completedToday && current == longest && current >= 10 && risk.index < StreakRisk.danger.index) {
      risk = StreakRisk.danger; // personal record at stake
    }

    // Health score
    double health = 100.0;
    if (!completedToday) health -= (24 - hoursLeft) * 2.5;
    if (weeklyConsistency < 0.7) health -= (0.7 - weeklyConsistency) * 40;
    if (current == 0) health = 0;
    health = health.clamp(0, 100);

    // Predict break day
    int? predictedBreak;
    if (weeklyConsistency < 0.5 && current > 0) {
      predictedBreak = (current * weeklyConsistency / (1 - weeklyConsistency)).round().clamp(1, 30);
    }

    // Rescue strategies
    final rescues = <RescueStrategy>[];
    if (!completedToday && current > 0) {
      rescues.addAll(_getRescueStrategies(name, typicalTime, current, hoursLeft));
    }

    // Insights
    final insights = <String>[];
    if (current == longest && current > 0) {
      insights.add('🏆 This is your all-time record! Protect it!');
    }
    if (current > 0 && current % 7 == 0) {
      insights.add('📅 Full week milestone at $current days!');
    }
    if (current >= 30) {
      insights.add('🌟 Monthly milestone! Incredible consistency.');
    }
    if (weeklyConsistency >= 1.0) {
      insights.add('💯 Perfect week — 7/7 completions!');
    } else if (weeklyConsistency < 0.4) {
      insights.add('📉 Weekly consistency is low — try anchoring to a routine.');
    }
    if (!completedToday && hoursLeft <= 4 && current > 7) {
      insights.add('⏰ Clock is ticking on a ${current}-day streak!');
    }

    return StreakAnalysis(
      trackerName: name,
      trackerEmoji: emoji,
      currentStreak: current,
      longestStreak: longest,
      risk: risk,
      healthScore: health,
      timeRemaining: timeRemaining,
      rescueStrategies: rescues,
      insights: insights,
      completedToday: completedToday,
      weeklyConsistency: weeklyConsistency,
      predictedBreakDay: predictedBreak,
    );
  }

  List<RescueStrategy> _getRescueStrategies(
    String trackerName,
    String typicalTime,
    int streakLength,
    int hoursLeft,
  ) {
    final strategies = <RescueStrategy>[];
    final name = trackerName.toLowerCase();

    // Quick-win strategy
    strategies.add(RescueStrategy(
      title: 'Minimum Viable Completion',
      description: 'Do the absolute minimum to count — even 1 minute counts for keeping the streak alive.',
      emoji: '⚡',
      effortMinutes: 1,
    ));

    // Time-specific strategies
    if (hoursLeft <= 4) {
      strategies.add(const RescueStrategy(
        title: 'Set a Timer Now',
        description: 'Set a 5-minute timer and start immediately. Don\'t overthink it.',
        emoji: '⏱️',
        effortMinutes: 5,
      ));
    }

    // Category-specific
    if (name.contains('exercise') || name.contains('workout')) {
      strategies.add(const RescueStrategy(
        title: 'Quick Body Weight Set',
        description: '10 pushups + 10 squats + 30s plank. Done in under 5 minutes.',
        emoji: '💪',
        effortMinutes: 5,
      ));
    } else if (name.contains('meditat')) {
      strategies.add(const RescueStrategy(
        title: 'Box Breathing',
        description: '4 cycles of box breathing (4-4-4-4). Counts as mindfulness.',
        emoji: '🫁',
        effortMinutes: 2,
      ));
    } else if (name.contains('water')) {
      strategies.add(const RescueStrategy(
        title: 'Drink Right Now',
        description: 'Fill a glass and drink it while reading this. Streak saved.',
        emoji: '🥤',
        effortMinutes: 1,
      ));
    } else if (name.contains('read')) {
      strategies.add(const RescueStrategy(
        title: 'Read One Page',
        description: 'Open your book/article and read just one page. Usually leads to more.',
        emoji: '📖',
        effortMinutes: 2,
      ));
    } else if (name.contains('journal') || name.contains('writing')) {
      strategies.add(const RescueStrategy(
        title: 'Three Sentences',
        description: 'Write just 3 sentences about your day. Quality doesn\'t matter.',
        emoji: '✍️',
        effortMinutes: 2,
      ));
    } else if (name.contains('coding') || name.contains('practice')) {
      strategies.add(const RescueStrategy(
        title: 'Solve One Easy Problem',
        description: 'Pick the easiest challenge available. Ship something small.',
        emoji: '🧩',
        effortMinutes: 10,
      ));
    }

    // High-streak protection
    if (streakLength >= 14) {
      strategies.add(RescueStrategy(
        title: 'Streak Insurance',
        description: 'Your $streakLength-day streak represents real effort. Even a token action preserves weeks of momentum.',
        emoji: '🛡️',
        effortMinutes: 1,
      ));
    }

    return strategies;
  }

  /// Analyze all trackers and produce fleet summary.
  StreakFleetSummary analyzeFleet(List<Map<String, dynamic>> trackers) {
    final analyses = trackers.map(analyzeTracker).toList();

    int safe = 0, watching = 0, danger = 0, critical = 0, broken = 0;
    int activeStreaks = 0, totalDays = 0;
    double healthSum = 0;

    for (final a in analyses) {
      switch (a.risk) {
        case StreakRisk.safe:
          safe++;
          break;
        case StreakRisk.watch:
          watching++;
          break;
        case StreakRisk.danger:
          danger++;
          break;
        case StreakRisk.critical:
          critical++;
          break;
        case StreakRisk.broken:
          broken++;
          break;
      }
      if (a.currentStreak > 0) {
        activeStreaks++;
        totalDays += a.currentStreak;
      }
      healthSum += a.healthScore;
    }

    final avgHealth = analyses.isEmpty ? 0.0 : healthSum / analyses.length;

    // Top actions
    final actions = <String>[];
    final criticals = analyses.where((a) => a.risk == StreakRisk.critical).toList();
    final dangers = analyses.where((a) => a.risk == StreakRisk.danger).toList();

    for (final c in criticals) {
      actions.add('🚨 Complete ${c.trackerName} NOW — streak at risk!');
    }
    for (final d in dangers) {
      actions.add('⚠️ ${d.trackerName} needs attention today');
    }
    if (actions.isEmpty && broken > 0) {
      actions.add('💔 ${broken} streak(s) broken — start rebuilding today');
    }
    if (actions.isEmpty) {
      actions.add('✅ All streaks safe — keep up the great work!');
    }

    // Guardian verdict
    String verdict;
    if (critical > 0) {
      verdict = '🚨 ALERT: $critical streak(s) in critical danger!';
    } else if (danger > 0) {
      verdict = '⚠️ CAUTION: $danger streak(s) need attention today.';
    } else if (watching > 0) {
      verdict = '👀 MONITORING: $watching streak(s) on watch.';
    } else if (broken > 0 && safe > 0) {
      verdict = '🔄 MIXED: $safe safe, $broken need rebuilding.';
    } else if (activeStreaks == 0) {
      verdict = '🌱 START: No active streaks — today is day one!';
    } else {
      verdict = '🛡️ ALL CLEAR: All $activeStreaks streaks are protected.';
    }

    return StreakFleetSummary(
      totalTracked: analyses.length,
      safe: safe,
      watching: watching,
      inDanger: danger,
      critical: critical,
      broken: broken,
      overallHealth: avgHealth,
      activeStreaks: activeStreaks,
      totalStreakDays: totalDays,
      topActions: actions,
      guardianVerdict: verdict,
    );
  }
}
