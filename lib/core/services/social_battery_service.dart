
// ─── Enums ──────────────────────────────────────────────────────

enum SocialContext {
  work('Work', '💼'),
  family('Family', '👨‍👩‍👧'),
  friends('Friends', '🎉'),
  strangers('Strangers', '👥'),
  online('Online', '💬'),
  alone('Alone', '🧘');

  final String label;
  final String emoji;
  const SocialContext(this.label, this.emoji);
}

enum SocialActivity {
  meeting('Meeting', '📋'),
  party('Party', '🎊'),
  call('Phone Call', '📞'),
  chat('Chat', '💭'),
  meal('Meal', '🍽️'),
  shopping('Shopping', '🛒'),
  commute('Commute', '🚌'),
  exercise('Exercise', '🏃'),
  reading('Reading', '📖'),
  gaming('Gaming', '🎮'),
  other('Other', '📌');

  final String label;
  final String emoji;
  const SocialActivity(this.label, this.emoji);
}

enum InsightType { drain, recharge, warning, tip }

// ─── Data Classes ───────────────────────────────────────────────

class SocialBatteryEntry {
  final DateTime timestamp;
  final int level; // 0-100
  final SocialContext context;
  final SocialActivity activity;
  final int durationMinutes;
  final String? note;

  const SocialBatteryEntry({
    required this.timestamp,
    required this.level,
    required this.context,
    required this.activity,
    required this.durationMinutes,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level,
        'context': context.index,
        'activity': activity.index,
        'durationMinutes': durationMinutes,
        'note': note,
      };

  factory SocialBatteryEntry.fromJson(Map<String, dynamic> j) =>
      SocialBatteryEntry(
        timestamp: DateTime.parse(j['timestamp'] as String),
        level: j['level'] as int,
        context: SocialContext.values[j['context'] as int],
        activity: SocialActivity.values[j['activity'] as int],
        durationMinutes: j['durationMinutes'] as int,
        note: j['note'] as String?,
      );

  String get levelEmoji {
    if (level >= 80) return '🔋';
    if (level >= 60) return '🟢';
    if (level >= 40) return '🟡';
    if (level >= 20) return '🟠';
    return '🔴';
  }
}

class SocialInsight {
  final String emoji;
  final String title;
  final String description;
  final InsightType type;

  const SocialInsight({
    required this.emoji,
    required this.title,
    required this.description,
    required this.type,
  });
}

// ─── Service ────────────────────────────────────────────────────

class SocialBatteryService {
  SocialBatteryService._();

  /// Average level across entries.
  static double averageLevel(List<SocialBatteryEntry> entries) {
    if (entries.isEmpty) return 50;
    return entries.map((e) => e.level).reduce((a, b) => a + b) /
        entries.length;
  }

  /// Average level per context.
  static Map<SocialContext, double> averageByContext(
      List<SocialBatteryEntry> entries) {
    final map = <SocialContext, List<int>>{};
    for (final e in entries) {
      map.putIfAbsent(e.context, () => []).add(e.level);
    }
    return map.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }

  /// Average level per activity.
  static Map<SocialActivity, double> averageByActivity(
      List<SocialBatteryEntry> entries) {
    final map = <SocialActivity, List<int>>{};
    for (final e in entries) {
      map.putIfAbsent(e.activity, () => []).add(e.level);
    }
    return map.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }

  /// Top drains (lowest average contexts).
  static List<MapEntry<SocialContext, double>> topDrains(
      List<SocialBatteryEntry> entries,
      {int count = 3}) {
    final avg = averageByContext(entries);
    final sorted = avg.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.take(count).toList();
  }

  /// Top rechargers (highest average contexts).
  static List<MapEntry<SocialContext, double>> topRechargers(
      List<SocialBatteryEntry> entries,
      {int count = 3}) {
    final avg = averageByContext(entries);
    final sorted = avg.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).toList();
  }

  /// Weekly average for the last 7 days.
  static double weeklyAverage(List<SocialBatteryEntry> entries) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
    return averageLevel(recent);
  }

  /// Daily averages for the last N days.
  static Map<String, double> dailyAverages(List<SocialBatteryEntry> entries,
      {int days = 7}) {
    final result = <String, double>{};
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final day = now.subtract(Duration(days: i));
      final key =
          '${day.month.toString().padLeft(2, '0')}/${day.day.toString().padLeft(2, '0')}';
      final dayEntries = entries.where((e) =>
          e.timestamp.year == day.year &&
          e.timestamp.month == day.month &&
          e.timestamp.day == day.day);
      if (dayEntries.isNotEmpty) {
        result[key] = dayEntries.map((e) => e.level).reduce((a, b) => a + b) /
            dayEntries.length;
      }
    }
    return result;
  }

  /// Burnout risk score 0.0-1.0 based on recent low entries.
  static double burnoutRisk(List<SocialBatteryEntry> entries) {
    final cutoff = DateTime.now().subtract(const Duration(days: 3));
    final recent = entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
    if (recent.isEmpty) return 0.0;
    final lowCount = recent.where((e) => e.level < 30).length;
    return (lowCount / recent.length).clamp(0.0, 1.0);
  }

  /// Generate proactive insights from entry history.
  static List<SocialInsight> generateInsights(
      List<SocialBatteryEntry> entries) {
    final insights = <SocialInsight>[];
    if (entries.length < 3) {
      insights.add(const SocialInsight(
        emoji: '📝',
        title: 'Keep Logging',
        description:
            'Log at least 5 entries to unlock personalized insights about your social energy patterns.',
        type: InsightType.tip,
      ));
      return insights;
    }

    // 1. Burnout warning
    final risk = burnoutRisk(entries);
    if (risk > 0.6) {
      insights.add(const SocialInsight(
        emoji: '🚨',
        title: 'Burnout Risk Detected',
        description:
            'Your social battery has been consistently low recently. Consider scheduling alone time to recharge.',
        type: InsightType.warning,
      ));
    }

    // 2. Top drain context
    final drains = topDrains(entries);
    if (drains.isNotEmpty && drains.first.value < 40) {
      final ctx = drains.first.key;
      insights.add(SocialInsight(
        emoji: '⚡',
        title: '${ctx.emoji} ${ctx.label} Drains You Most',
        description:
            'Your average level during ${ctx.label.toLowerCase()} interactions is ${drains.first.value.toStringAsFixed(0)}%. Try shorter sessions or breaks.',
        type: InsightType.drain,
      ));
    }

    // 3. Top recharger
    final rechargers = topRechargers(entries);
    if (rechargers.isNotEmpty && rechargers.first.value > 60) {
      final ctx = rechargers.first.key;
      insights.add(SocialInsight(
        emoji: '✨',
        title: '${ctx.emoji} ${ctx.label} Recharges You',
        description:
            'You tend to feel most energized during ${ctx.label.toLowerCase()} time (avg ${rechargers.first.value.toStringAsFixed(0)}%). Schedule more of it!',
        type: InsightType.recharge,
      ));
    }

    // 4. Long interaction warning
    final longOnes =
        entries.where((e) => e.durationMinutes > 120 && e.level < 40);
    if (longOnes.length >= 2) {
      insights.add(const SocialInsight(
        emoji: '⏰',
        title: 'Long Sessions Drain You',
        description:
            'You tend to crash after 2+ hour social interactions. Consider breaking them up with solo breaks.',
        type: InsightType.warning,
      ));
    }

    // 5. Meeting fatigue
    final meetings =
        entries.where((e) => e.activity == SocialActivity.meeting).toList();
    if (meetings.length >= 3) {
      final meetingAvg = averageLevel(meetings);
      if (meetingAvg < 45) {
        insights.add(SocialInsight(
          emoji: '📋',
          title: 'Meeting Fatigue',
          description:
              'Your average energy during meetings is ${meetingAvg.toStringAsFixed(0)}%. Try no-meeting blocks or walking meetings.',
          type: InsightType.drain,
        ));
      }
    }

    // 6. Weekend vs weekday pattern
    final weekday =
        entries.where((e) => e.timestamp.weekday <= 5).toList();
    final weekend =
        entries.where((e) => e.timestamp.weekday > 5).toList();
    if (weekday.length >= 3 && weekend.length >= 2) {
      final wdAvg = averageLevel(weekday);
      final weAvg = averageLevel(weekend);
      if (weAvg - wdAvg > 15) {
        insights.add(SocialInsight(
          emoji: '📅',
          title: 'Weekday Drain Pattern',
          description:
              'Your weekend average (${weAvg.toStringAsFixed(0)}%) is much higher than weekday (${wdAvg.toStringAsFixed(0)}%). Work social demands may be too high.',
          type: InsightType.tip,
        ));
      }
    }

    // 7. Online vs in-person
    final online =
        entries.where((e) => e.context == SocialContext.online).toList();
    final inPerson = entries
        .where((e) =>
            e.context != SocialContext.online &&
            e.context != SocialContext.alone)
        .toList();
    if (online.length >= 2 && inPerson.length >= 2) {
      final onAvg = averageLevel(online);
      final ipAvg = averageLevel(inPerson);
      if ((onAvg - ipAvg).abs() > 15) {
        final better = onAvg > ipAvg ? 'online' : 'in-person';
        insights.add(SocialInsight(
          emoji: '🌐',
          title: 'You Prefer ${better[0].toUpperCase()}${better.substring(1)}',
          description:
              'Online avg: ${onAvg.toStringAsFixed(0)}% vs in-person avg: ${ipAvg.toStringAsFixed(0)}%. Lean into what works.',
          type: InsightType.tip,
        ));
      }
    }

    // 8. Streak detection
    final sorted = List.of(entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    int lowStreak = 0;
    for (final e in sorted) {
      if (e.level < 30) {
        lowStreak++;
      } else {
        break;
      }
    }
    if (lowStreak >= 3) {
      insights.add(SocialInsight(
        emoji: '📉',
        title: '$lowStreak-Entry Low Streak',
        description:
            'Your last $lowStreak logs were all below 30%. Time for a social detox — cancel something today.',
        type: InsightType.warning,
      ));
    }

    // 9. Positive momentum
    if (sorted.length >= 3 &&
        sorted[0].level > sorted[1].level &&
        sorted[1].level > sorted[2].level &&
        sorted[0].level >= 60) {
      insights.add(const SocialInsight(
        emoji: '🚀',
        title: 'Positive Momentum',
        description:
            'Your social battery has been trending up! Keep doing what you\'re doing.',
        type: InsightType.recharge,
      ));
    }

    // 10. Optimal socializing time (morning vs afternoon vs evening)
    final morning =
        entries.where((e) => e.timestamp.hour >= 6 && e.timestamp.hour < 12);
    final afternoon =
        entries.where((e) => e.timestamp.hour >= 12 && e.timestamp.hour < 18);
    final evening =
        entries.where((e) => e.timestamp.hour >= 18 || e.timestamp.hour < 6);
    final slots = <String, double>{};
    if (morning.length >= 2) slots['morning'] = averageLevel(morning.toList());
    if (afternoon.length >= 2) {
      slots['afternoon'] = averageLevel(afternoon.toList());
    }
    if (evening.length >= 2) slots['evening'] = averageLevel(evening.toList());
    if (slots.length >= 2) {
      final best = slots.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (best.value > 55) {
        insights.add(SocialInsight(
          emoji: '🕐',
          title: 'Best Social Time: ${best.key[0].toUpperCase()}${best.key.substring(1)}',
          description:
              'You have the most social energy in the ${best.key} (avg ${best.value.toStringAsFixed(0)}%). Schedule social events then.',
          type: InsightType.tip,
        ));
      }
    }

    return insights;
  }
}
