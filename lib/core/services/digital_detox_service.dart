import 'dart:math';

// ─── MODELS ────────────────────────────────────────────────────────────────

/// A completed or in-progress digital detox session.
///
/// Tracks the user's attempt to stay screen-free for [targetMinutes],
/// recording [actualMinutes] achieved and any [distractions] encountered.
/// [adherenceRate] computes how well the user stuck to the target,
/// clamped to 150% to allow credit for exceeding the goal without
/// inflating aggregated statistics.
class DetoxSession {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final int targetMinutes;
  final int actualMinutes;
  final List<String> distractions;
  final bool completed;

  const DetoxSession({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.targetMinutes,
    required this.actualMinutes,
    this.distractions = const [],
    required this.completed,
  });

  double get adherenceRate =>
      targetMinutes > 0 ? (actualMinutes / targetMinutes).clamp(0.0, 1.5) : 0;
}

/// A single cell in the weekly screen-time heatmap.
///
/// Represents observed screen usage (in [minutes]) for a given
/// [dayOfWeek] (1=Mon..7=Sun) and [hour] (0-23). Used by the
/// service to build the 7×24 usage grid that powers insights
/// and plan generation.
class UsageSlot {
  final int dayOfWeek; // 1=Mon .. 7=Sun
  final int hour; // 0-23
  final int minutes; // usage minutes in that hour

  const UsageSlot(this.dayOfWeek, this.hour, this.minutes);
}

/// An actionable observation derived from the user's detox history
/// and usage patterns.
///
/// Each insight carries an [icon] for display, a short [title],
/// a descriptive [body], and a [severity] level that the UI can
/// use to color-code or prioritize the card.
class DetoxInsight {
  final String icon;
  final String title;
  final String body;
  final InsightSeverity severity;

  const DetoxInsight(this.icon, this.title, this.body, this.severity);
}

/// Severity tiers for [DetoxInsight], ranging from [positive]
/// (encouraging) through [critical] (needs immediate attention).
enum InsightSeverity { positive, neutral, warning, critical }

/// A single screen-free time block within a [DetoxPlan].
///
/// Placed on [dayOfWeek] (1=Mon..7=Sun) starting at [startHour]
/// for [durationMinutes]. The [label] provides a human-friendly
/// name (e.g. "Peak Detox", "Mindful Break").
class DetoxPlanBlock {
  final String label;
  final int dayOfWeek;
  final int startHour;
  final int durationMinutes;

  const DetoxPlanBlock(this.label, this.dayOfWeek, this.startHour, this.durationMinutes);
}

/// A generated weekly detox schedule optimized for the user's
/// usage patterns.
///
/// Contains a list of [blocks] spread across the week, a
/// [weeklyTargetMinutes] budget, the [predictedReduction] as a
/// percentage of current screen time, and a natural-language
/// [strategy] description.
class DetoxPlan {
  final List<DetoxPlanBlock> blocks;
  final int weeklyTargetMinutes;
  final double predictedReduction;
  final String strategy;

  const DetoxPlan(this.blocks, this.weeklyTargetMinutes, this.predictedReduction, this.strategy);
}

/// Streak and success-rate statistics for the user's detox sessions.
///
/// [current] is the active consecutive-day streak, [longest] the
/// all-time record, and [successRate] the ratio of sessions where
/// the user hit ≥ 80% of their target duration.
class StreakInfo {
  final int current;
  final int longest;
  final int totalSessions;
  final int successfulSessions;

  /// Fraction of sessions completed successfully (0.0–1.0).
  double get successRate =>
      totalSessions > 0 ? successfulSessions / totalSessions : 0;

  const StreakInfo(this.current, this.longest, this.totalSessions, this.successfulSessions);
}

// ─── SERVICE ───────────────────────────────────────────────────────────────

/// Service that analyzes screen-time usage, runs detox sessions,
/// and generates personalized insights and reduction plans.
///
/// Maintains a 7×24 [usageGrid] (minutes per hour per weekday) and
/// a history of [sessions]. Provides:
/// - [getStreakInfo]: consecutive-day streak and success statistics
/// - [getProactiveInsights]: contextual tips based on patterns
/// - [getHealthScore]: 0–100 composite digital-wellness score
/// - [generatePlan]: weekly detox schedule targeting a given
///   percentage reduction in screen time
class DigitalDetoxService {
  late final List<DetoxSession> sessions;
  late final List<List<int>> _usageGrid; // [dayOfWeek 0-6][hour 0-23] = minutes

  DigitalDetoxService() {
    _usageGrid = _generateUsageGrid();
    sessions = _generateDemoSessions();
  }

  // ── Usage grid (simulated screen‐time per hour per weekday) ──

  /// Builds a 7×24 usage grid with realistic circadian patterns.
  ///
  /// Night hours (0-5) are near-zero, mornings ramp up, lunch and
  /// evening are peak, and weekends get a 20% boost.
  List<List<int>> _generateUsageGrid() {
    final rng = Random(42);
    return List.generate(7, (d) {
      return List.generate(24, (h) {
        // baseline: low at night, medium morning, high afternoon/evening
        int base;
        if (h < 6) {
          base = rng.nextInt(5); // 0-4 min
        } else if (h < 9) {
          base = 10 + rng.nextInt(15); // morning scroll
        } else if (h < 12) {
          base = 15 + rng.nextInt(20); // work hours
        } else if (h < 14) {
          base = 25 + rng.nextInt(20); // lunch peak
        } else if (h < 17) {
          base = 10 + rng.nextInt(15); // afternoon
        } else if (h < 21) {
          base = 30 + rng.nextInt(25); // evening peak
        } else {
          base = 15 + rng.nextInt(15); // wind-down
        }
        // weekends: +20 %
        if (d >= 5) base = (base * 1.2).round();
        return base;
      });
    });
  }

  List<List<int>> get usageGrid => _usageGrid;

  /// Average daily screen time in minutes, computed across all
  /// seven weekdays of the usage grid.
  int get totalDailyAverage {
    int sum = 0;
    for (final day in _usageGrid) {
      for (final m in day) {
        sum += m;
      }
    }
    return sum ~/ 7;
  }

  // ── Demo sessions ──

  /// Creates 14 days of realistic demo sessions with varied
  /// targets, completion rates, and distractions for UI preview.
  List<DetoxSession> _generateDemoSessions() {
    final rng = Random(99);
    final now = DateTime.now();
    final List<DetoxSession> result = [];
    final names = [
      'Morning Calm', 'Deep Work', 'Lunch Break Reset', 'Evening Unplug',
      'Weekend Recharge', 'Focus Sprint', 'Mindful Hour', 'Screen-Free Walk',
    ];
    final distractionPool = [
      'Social media', 'News app', 'Email', 'Chat notification',
      'Game', 'Shopping app', 'YouTube', 'Reddit',
    ];

    for (int d = 13; d >= 0; d--) {
      final day = now.subtract(Duration(days: d));
      final sessionsToday = 1 + rng.nextInt(2);
      for (int s = 0; s < sessionsToday; s++) {
        final hour = 7 + rng.nextInt(14);
        final target = [30, 45, 60, 90][rng.nextInt(4)];
        final actual = (target * (0.6 + rng.nextDouble() * 0.6)).round();
        final numDistractions = rng.nextInt(4);
        final distractions = List.generate(
          numDistractions,
          (_) => distractionPool[rng.nextInt(distractionPool.length)],
        ).toSet().toList();
        result.add(DetoxSession(
          id: 'ds_${d}_$s',
          name: names[rng.nextInt(names.length)],
          startTime: DateTime(day.year, day.month, day.day, hour),
          endTime: DateTime(day.year, day.month, day.day, hour).add(Duration(minutes: target)),
          targetMinutes: target,
          actualMinutes: actual,
          distractions: distractions,
          completed: actual >= target * 0.8,
        ));
      }
    }
    return result;
  }

  // ── Analysis ──

  /// Computes the current and longest consecutive-day streaks,
  /// total session count, and successful-session count.
  ///
  /// A day counts toward the streak if at least one session on
  /// that day was [DetoxSession.completed] (≥ 80% adherence).
  StreakInfo getStreakInfo() {
    if (sessions.isEmpty) return const StreakInfo(0, 0, 0, 0);
    final sorted = [...sessions]..sort((a, b) => b.startTime.compareTo(a.startTime));
    int current = 0;
    int longest = 0;
    int streak = 0;
    int successful = sorted.where((s) => s.completed).length;

    // group by date
    final Map<String, List<DetoxSession>> byDate = {};
    for (final s in sorted) {
      final key = '${s.startTime.year}-${s.startTime.month}-${s.startTime.day}';
      byDate.putIfAbsent(key, () => []).add(s);
    }
    final dates = byDate.keys.toList();
    for (final date in dates) {
      final daySessions = byDate[date]!;
      if (daySessions.any((s) => s.completed)) {
        streak++;
        if (streak > longest) longest = streak;
      } else {
        if (current == 0) current = streak;
        streak = 0;
      }
    }
    if (current == 0) current = streak;
    return StreakInfo(current, longest, sessions.length, successful);
  }

  /// Returns the hour (0-23) with the highest aggregate usage
  /// across all weekdays.
  int _peakHour() {
    int maxMin = 0, peakH = 0;
    for (int h = 0; h < 24; h++) {
      int total = 0;
      for (int d = 0; d < 7; d++) {
        total += _usageGrid[d][h];
      }
      if (total > maxMin) {
        maxMin = total;
        peakH = h;
      }
    }
    return peakH;
  }

  /// Returns the waking hour (6-22) with the lowest aggregate
  /// usage — the best candidate for a new detox block.
  int _quietHour() {
    int minMin = 999999, quietH = 6;
    for (int h = 6; h < 23; h++) {
      // only waking hours
      int total = 0;
      for (int d = 0; d < 7; d++) {
        total += _usageGrid[d][h];
      }
      if (total < minMin) {
        minMin = total;
        quietH = h;
      }
    }
    return quietH;
  }

  /// Formats an hour index (0-23) as a 12-hour AM/PM label.
  String _hourLabel(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }

  /// Formats a weekday index (0=Mon..6=Sun) as a 3-letter label.
  String _dayLabel(int d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d];

  /// Returns the weekday index (0=Mon..6=Sun) with the highest
  /// total screen time.
  int _busiestDay() {
    int maxMin = 0, busyD = 0;
    for (int d = 0; d < 7; d++) {
      final total = _usageGrid[d].reduce((a, b) => a + b);
      if (total > maxMin) {
        maxMin = total;
        busyD = d;
      }
    }
    return busyD;
  }

  /// Generates a list of contextual [DetoxInsight]s based on
  /// peak/quiet hours, busiest day, streak status, success rate,
  /// and most frequent distractions.
  List<DetoxInsight> getProactiveInsights() {
    final insights = <DetoxInsight>[];
    final streak = getStreakInfo();
    final peak = _peakHour();
    final quiet = _quietHour();
    final busyDay = _busiestDay();

    // Peak usage warning
    insights.add(DetoxInsight(
      '📱',
      'Peak Screen Time',
      'Your highest usage is around ${_hourLabel(peak)}. Consider scheduling a detox block here.',
      InsightSeverity.warning,
    ));

    // Best detox window
    insights.add(DetoxInsight(
      '🧘',
      'Best Detox Window',
      '${_hourLabel(quiet)} is your lowest-usage waking hour — ideal for a screen-free block.',
      InsightSeverity.positive,
    ));

    // Busiest day
    insights.add(DetoxInsight(
      '📅',
      'Heaviest Day',
      '${_dayLabel(busyDay)} is your busiest screen day. Plan extra detox time.',
      InsightSeverity.neutral,
    ));

    // Streak feedback
    if (streak.current >= 5) {
      insights.add(DetoxInsight(
        '🔥',
        'Hot Streak!',
        '${streak.current}-day detox streak — you\'re building a strong digital boundary.',
        InsightSeverity.positive,
      ));
    } else if (streak.current == 0) {
      insights.add(DetoxInsight(
        '⚡',
        'Restart Your Streak',
        'No active streak. Even a 15-minute session today restarts momentum.',
        InsightSeverity.critical,
      ));
    }

    // Success rate
    if (streak.successRate < 0.5) {
      insights.add(DetoxInsight(
        '🎯',
        'Lower Your Targets',
        'Success rate is ${(streak.successRate * 100).round()}%. Try shorter sessions to build consistency first.',
        InsightSeverity.warning,
      ));
    } else if (streak.successRate > 0.8) {
      insights.add(DetoxInsight(
        '🏆',
        'High Achiever',
        '${(streak.successRate * 100).round()}% success rate — consider increasing session length for more benefit.',
        InsightSeverity.positive,
      ));
    }

    // Distraction analysis
    final distractionCount = <String, int>{};
    for (final s in sessions) {
      for (final d in s.distractions) {
        distractionCount[d] = (distractionCount[d] ?? 0) + 1;
      }
    }
    if (distractionCount.isNotEmpty) {
      final topDistraction = distractionCount.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add(DetoxInsight(
        '🚨',
        'Top Distraction: ${topDistraction.key}',
        'Appeared in ${topDistraction.value} sessions. Consider muting or removing it during detox.',
        InsightSeverity.warning,
      ));
    }

    return insights;
  }

  /// Computes a 0–100 composite digital-wellness score.
  ///
  /// Weighted components:
  /// - **Adherence (40%):** session success rate
  /// - **Streak (30%):** current streak relative to 14 days
  /// - **Trend (30%):** improvement in success rate from the
  ///   prior 7-day window to the most recent 7 days
  int getHealthScore() {
    final streak = getStreakInfo();
    // Components: adherence (40%), streak (30%), trend (30%)
    double adherenceScore = streak.successRate * 40;
    double streakScore = (streak.current / 14).clamp(0.0, 1.0) * 30;

    // Trend: compare last 7 days sessions success vs prior 7
    final now = DateTime.now();
    final recent = sessions.where((s) => now.difference(s.startTime).inDays < 7);
    final prior = sessions.where((s) {
      final days = now.difference(s.startTime).inDays;
      return days >= 7 && days < 14;
    });
    double recentRate = recent.isEmpty
        ? 0
        : recent.where((s) => s.completed).length / recent.length;
    double priorRate = prior.isEmpty
        ? 0
        : prior.where((s) => s.completed).length / prior.length;
    double trendScore = ((recentRate - priorRate + 1) / 2).clamp(0.0, 1.0) * 30;

    return (adherenceScore + streakScore + trendScore).round().clamp(0, 100);
  }

  /// Creates a [DetoxPlan] targeting a [targetReductionPercent]
  /// decrease (clamped to 10–50%) in weekly screen time.
  ///
  /// Schedules [DetoxPlanBlock]s during the highest-usage waking
  /// hours on the busiest weekdays, greedily filling the weekly
  /// budget. Returns a strategy description scaled to the
  /// aggressiveness of the reduction target.
  DetoxPlan generatePlan(int targetReductionPercent) {
    final reduction = targetReductionPercent.clamp(10, 50);
    final dailyAvg = totalDailyAverage;
    final targetCut = (dailyAvg * reduction / 100).round();
    final weeklyTarget = targetCut * 7;

    // Find the highest-usage hours and schedule detox blocks there
    final hourTotals = List.generate(24, (h) {
      int sum = 0;
      for (int d = 0; d < 7; d++) sum += _usageGrid[d][h];
      return MapEntry(h, sum);
    })..sort((a, b) => b.value.compareTo(a.value));

    final blocks = <DetoxPlanBlock>[];
    int scheduled = 0;
    final blockNames = [
      'Peak Detox', 'Focus Block', 'Mindful Break', 'Screen-Free Zone',
      'Digital Pause', 'Quiet Time', 'Recharge Block',
    ];
    int nameIdx = 0;

    for (final entry in hourTotals) {
      if (scheduled >= weeklyTarget) break;
      if (entry.key < 6 || entry.key > 22) continue; // skip sleep hours
      // Schedule on the 3 busiest days for this hour
      final dayUsage = List.generate(7, (d) => MapEntry(d, _usageGrid[d][entry.key]))
        ..sort((a, b) => b.value.compareTo(a.value));
      for (int i = 0; i < 3 && scheduled < weeklyTarget; i++) {
        final duration = min(60, weeklyTarget - scheduled);
        blocks.add(DetoxPlanBlock(
          blockNames[nameIdx % blockNames.length],
          dayUsage[i].key + 1, // 1-indexed
          entry.key,
          duration > 15 ? duration : 30,
        ));
        scheduled += duration > 15 ? duration : 30;
        nameIdx++;
      }
    }

    final predictedReduction = scheduled > 0 ? (scheduled / (dailyAvg * 7) * 100) : 0.0;
    final strategy = reduction <= 20
        ? 'Gentle reduction: short blocks during peak hours to build habit.'
        : reduction <= 35
            ? 'Moderate reduction: multiple daily blocks targeting your heaviest usage periods.'
            : 'Aggressive reduction: extended screen-free zones during all peak hours.';

    return DetoxPlan(blocks, weeklyTarget, predictedReduction, strategy);
  }

  /// Total screen-time minutes per weekday (Mon..Sun) for charts.
  List<int> get dayTotals => List.generate(7, (d) => _usageGrid[d].reduce((a, b) => a + b));

  /// Public alias for [_dayLabel] — returns 3-letter weekday name.
  String dayName(int d) => _dayLabel(d);

  /// Public alias for [_hourLabel] — returns 12-hour AM/PM label.
  String hourName(int h) => _hourLabel(h);
}
