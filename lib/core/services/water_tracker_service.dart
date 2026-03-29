import 'dart:math' as math;

import '../../models/water_entry.dart';

/// Configuration for daily water intake goals.
class HydrationConfig {
  /// Daily goal in ml (default 2500ml / ~84oz).
  final int dailyGoalMl;

  /// Reminder interval in minutes (0 = disabled).
  final int reminderIntervalMinutes;

  /// Wake hour (0-23) for calculating active hydration window.
  final int wakeHour;

  /// Sleep hour (0-23) for calculating active hydration window.
  final int sleepHour;

  const HydrationConfig({
    this.dailyGoalMl = 2500,
    this.reminderIntervalMinutes = 60,
    this.wakeHour = 7,
    this.sleepHour = 23,
  });

  /// Active hours in a day for pacing calculations.
  int get activeHours {
    if (sleepHour > wakeHour) return sleepHour - wakeHour;
    return (24 - wakeHour) + sleepHour;
  }

  /// Ideal ml per active hour.
  double get mlPerHour => dailyGoalMl / activeHours;

  Map<String, dynamic> toJson() => {
        'dailyGoalMl': dailyGoalMl,
        'reminderIntervalMinutes': reminderIntervalMinutes,
        'wakeHour': wakeHour,
        'sleepHour': sleepHour,
      };

  factory HydrationConfig.fromJson(Map<String, dynamic> json) {
    return HydrationConfig(
      dailyGoalMl: json['dailyGoalMl'] as int? ?? 2500,
      reminderIntervalMinutes: json['reminderIntervalMinutes'] as int? ?? 60,
      wakeHour: json['wakeHour'] as int? ?? 7,
      sleepHour: json['sleepHour'] as int? ?? 23,
    );
  }
}

/// Daily hydration summary.
class HydrationDailySummary {
  final DateTime date;
  final int totalMl;
  final double effectiveHydrationMl;
  final int entryCount;
  final int goalMl;
  final Map<DrinkType, int> byDrinkType;
  final Map<int, int> byHour; // hour -> ml

  const HydrationDailySummary({
    required this.date,
    required this.totalMl,
    required this.effectiveHydrationMl,
    required this.entryCount,
    required this.goalMl,
    required this.byDrinkType,
    required this.byHour,
  });

  double get progressPercent =>
      goalMl > 0 ? (totalMl / goalMl * 100).clamp(0, 200) : 0;
  bool get goalMet => totalMl >= goalMl;
  int get remainingMl => (goalMl - totalMl).clamp(0, goalMl);

  String get grade {
    final pct = progressPercent;
    if (pct >= 100) return 'A';
    if (pct >= 80) return 'B';
    if (pct >= 60) return 'C';
    if (pct >= 40) return 'D';
    return 'F';
  }
}

/// Hydration streak information.
class HydrationStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastGoalMetDate;

  const HydrationStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastGoalMetDate,
  });
}

/// Hourly pacing information.
class HydrationPacing {
  final int currentHour;
  final int expectedMlByNow;
  final int actualMlByNow;
  final String status; // 'ahead', 'on_track', 'behind', 'way_behind'
  final int suggestedNextMl;
  final String recommendation;

  const HydrationPacing({
    required this.currentHour,
    required this.expectedMlByNow,
    required this.actualMlByNow,
    required this.status,
    required this.suggestedNextMl,
    required this.recommendation,
  });
}

/// Weekly trend data.
class WeeklyTrend {
  final List<HydrationDailySummary> days;
  final double avgDailyMl;
  final double avgEffectiveHydration;
  final int daysGoalMet;
  final DrinkType mostCommonDrink;
  final int peakHour;
  final double consistency; // 0-100, how evenly distributed intake is

  const WeeklyTrend({
    required this.days,
    required this.avgDailyMl,
    required this.avgEffectiveHydration,
    required this.daysGoalMet,
    required this.mostCommonDrink,
    required this.peakHour,
    required this.consistency,
  });
}

/// Full hydration report.
class HydrationReport {
  final HydrationDailySummary today;
  final HydrationPacing pacing;
  final HydrationStreak streak;
  final WeeklyTrend? weeklyTrend;
  final List<String> tips;

  const HydrationReport({
    required this.today,
    required this.pacing,
    required this.streak,
    this.weeklyTrend,
    required this.tips,
  });

  String toTextSummary() {
    final buf = StringBuffer();
    buf.writeln('💧 Hydration Report');
    buf.writeln('═══════════════════');
    buf.writeln(
        'Today: ${today.totalMl}ml / ${today.goalMl}ml (${today.progressPercent.toStringAsFixed(0)}%) Grade: ${today.grade}');
    buf.writeln(
        'Effective hydration: ${today.effectiveHydrationMl.toStringAsFixed(0)}ml');
    buf.writeln('Entries: ${today.entryCount}');
    buf.writeln('Pacing: ${pacing.status} — ${pacing.recommendation}');
    buf.writeln(
        'Streak: ${streak.currentStreak} days (best: ${streak.longestStreak})');
    if (weeklyTrend != null) {
      buf.writeln(
          'Weekly avg: ${weeklyTrend!.avgDailyMl.toStringAsFixed(0)}ml, ${weeklyTrend!.daysGoalMet}/7 goals met');
    }
    if (tips.isNotEmpty) {
      buf.writeln('Tips:');
      for (final tip in tips) {
        buf.writeln('  • $tip');
      }
    }
    return buf.toString();
  }
}

/// Water intake tracking service with daily goals, pacing, streaks, and trends.
class WaterTrackerService {
  final HydrationConfig config;

  const WaterTrackerService({this.config = const HydrationConfig()});

  // ── Daily Summary ──

  HydrationDailySummary getDailySummary(List<WaterEntry> entries, DateTime date) {
    final dayEntries = _entriesForDate(entries, date);
    final byType = <DrinkType, int>{};
    final byHour = <int, int>{};
    int total = 0;
    double effective = 0;

    for (final e in dayEntries) {
      total += e.amountMl;
      effective += e.effectiveHydrationMl;
      byType[e.drinkType] = (byType[e.drinkType] ?? 0) + e.amountMl;
      byHour[e.timestamp.hour] =
          (byHour[e.timestamp.hour] ?? 0) + e.amountMl;
    }

    return HydrationDailySummary(
      date: date,
      totalMl: total,
      effectiveHydrationMl: effective,
      entryCount: dayEntries.length,
      goalMl: config.dailyGoalMl,
      byDrinkType: byType,
      byHour: byHour,
    );
  }

  // ── Pacing ──

  HydrationPacing pacing(List<WaterEntry> entries, DateTime now) {
    final summary = getDailySummary(entries, now);
    final currentHour = now.hour;

    // Hours elapsed since wake
    int hoursElapsed;
    if (currentHour >= config.wakeHour && currentHour < config.sleepHour) {
      hoursElapsed = currentHour - config.wakeHour;
    } else if (currentHour < config.wakeHour) {
      hoursElapsed = 0;
    } else {
      hoursElapsed = config.activeHours;
    }

    final expectedMl = (config.mlPerHour * hoursElapsed).round();
    final actual = summary.totalMl;
    final diff = actual - expectedMl;
    final ratio = expectedMl > 0 ? actual / expectedMl : 1.0;

    String status;
    String recommendation;
    int suggestedNext;

    if (ratio >= 1.1) {
      status = 'ahead';
      recommendation = 'Great pace! Keep it steady.';
      suggestedNext = (config.mlPerHour * 0.8).round();
    } else if (ratio >= 0.85) {
      status = 'on_track';
      recommendation = 'Right on track. Have a glass soon.';
      suggestedNext = config.mlPerHour.round();
    } else if (ratio >= 0.5) {
      status = 'behind';
      final remaining = config.dailyGoalMl - actual;
      final hoursLeft = config.activeHours - hoursElapsed;
      suggestedNext =
          hoursLeft > 0 ? (remaining / hoursLeft).round() : remaining;
      recommendation =
          'Falling behind. Try ${suggestedNext}ml in the next hour.';
    } else {
      status = 'way_behind';
      final remaining = config.dailyGoalMl - actual;
      final hoursLeft = config.activeHours - hoursElapsed;
      suggestedNext = hoursLeft > 0
          ? (remaining / hoursLeft * 1.2).round()
          : remaining;
      recommendation =
          'Way behind! Drink ${suggestedNext}ml soon to catch up.';
    }

    return HydrationPacing(
      currentHour: currentHour,
      expectedMlByNow: expectedMl,
      actualMlByNow: actual,
      status: status,
      suggestedNextMl: suggestedNext,
      recommendation: recommendation,
    );
  }

  // ── Streaks ──

  HydrationStreak streak(List<WaterEntry> entries, DateTime today) {
    // Build daily totals map
    final dailyTotals = <String, int>{};
    for (final e in entries) {
      final key = _dateKey(e.timestamp);
      dailyTotals[key] = (dailyTotals[key] ?? 0) + e.amountMl;
    }

    int current = 0;
    int longest = 0;
    DateTime? lastGoalMet;

    // Walk backwards from today
    var day = DateTime(today.year, today.month, today.day);
    while (true) {
      final key = _dateKey(day);
      final total = dailyTotals[key] ?? 0;
      if (total >= config.dailyGoalMl) {
        current++;
        lastGoalMet ??= day;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // Find longest streak
    final sortedDays = dailyTotals.keys.toList()..sort();
    int run = 0;
    for (final key in sortedDays) {
      if ((dailyTotals[key] ?? 0) >= config.dailyGoalMl) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 0;
      }
    }
    if (current > longest) longest = current;

    return HydrationStreak(
      currentStreak: current,
      longestStreak: longest,
      lastGoalMetDate: lastGoalMet,
    );
  }

  // ── Weekly Trend ──

  WeeklyTrend weeklyTrend(List<WaterEntry> entries, DateTime endDate) {
    final days = <HydrationDailySummary>[];
    for (int i = 6; i >= 0; i--) {
      final day = endDate.subtract(Duration(days: i));
      days.add(getDailySummary(entries, day));
    }

    final totalMl =
        days.fold<int>(0, (sum, d) => sum + d.totalMl);
    final totalEffective =
        days.fold<double>(0, (sum, d) => sum + d.effectiveHydrationMl);
    final daysGoalMet = days.where((d) => d.goalMet).length;

    // Most common drink type across week
    final drinkTotals = <DrinkType, int>{};
    for (final d in days) {
      d.byDrinkType.forEach((type, ml) {
        drinkTotals[type] = (drinkTotals[type] ?? 0) + ml;
      });
    }
    DrinkType mostCommon = DrinkType.water;
    int maxDrinkMl = 0;
    drinkTotals.forEach((type, ml) {
      if (ml > maxDrinkMl) {
        maxDrinkMl = ml;
        mostCommon = type;
      }
    });

    // Peak hour
    final hourTotals = <int, int>{};
    for (final d in days) {
      d.byHour.forEach((hour, ml) {
        hourTotals[hour] = (hourTotals[hour] ?? 0) + ml;
      });
    }
    int peakHour = 12;
    int maxHourMl = 0;
    hourTotals.forEach((hour, ml) {
      if (ml > maxHourMl) {
        maxHourMl = ml;
        peakHour = hour;
      }
    });

    // Consistency: CV of daily totals (lower = more consistent)
    final avgMl = totalMl / 7.0;
    final variance = days.fold<double>(
            0, (sum, d) => sum + (d.totalMl - avgMl) * (d.totalMl - avgMl)) /
        7;
    final stdDev = variance > 0 ? math.sqrt(variance) : 0.0;
    final cv = avgMl > 0 ? stdDev / avgMl : 1.0;
    final consistency = ((1 - cv) * 100).clamp(0, 100).toDouble();

    return WeeklyTrend(
      days: days,
      avgDailyMl: avgMl,
      avgEffectiveHydration: totalEffective / 7,
      daysGoalMet: daysGoalMet,
      mostCommonDrink: mostCommon,
      peakHour: peakHour,
      consistency: consistency,
    );
  }

  // ── Tips ──

  List<String> generateTips(HydrationDailySummary summary, HydrationPacing pace) {
    final tips = <String>[];

    if (pace.status == 'behind' || pace.status == 'way_behind') {
      tips.add('Set a timer to remind yourself to drink every hour.');
    }

    if (summary.byDrinkType.containsKey(DrinkType.coffee) &&
        (summary.byDrinkType[DrinkType.coffee] ?? 0) > 500) {
      tips.add('High coffee intake — balance with extra water.');
    }

    if (summary.byDrinkType.containsKey(DrinkType.soda) &&
        (summary.byDrinkType[DrinkType.soda] ?? 0) > 300) {
      tips.add('Try replacing soda with sparkling water.');
    }

    final morning = summary.byHour.entries
        .where((e) => e.key >= 6 && e.key < 10)
        .fold<int>(0, (s, e) => s + e.value);
    if (morning == 0 && summary.entryCount > 0) {
      tips.add('Try drinking a glass of water first thing in the morning.');
    }

    if (summary.entryCount > 0 && summary.totalMl / summary.entryCount > 500) {
      tips.add(
          'Large infrequent drinks — try smaller, more frequent sips instead.');
    }

    if (summary.goalMet) {
      tips.add('🎉 Goal reached! Keep up the great hydration habits.');
    }

    return tips;
  }

  // ── Full Report ──

  HydrationReport report(List<WaterEntry> entries, DateTime now) {
    final todaySummary = getDailySummary(entries, now);
    final todayPacing = pacing(entries, now);
    final todayStreak = streak(entries, now);
    final trend = weeklyTrend(entries, now);
    final tips = generateTips(todaySummary, todayPacing);

    return HydrationReport(
      today: todaySummary,
      pacing: todayPacing,
      streak: todayStreak,
      weeklyTrend: trend,
      tips: tips,
    );
  }

  // ── Drink type breakdown ──

  Map<DrinkType, double> drinkTypePercentages(List<WaterEntry> entries) {
    final totals = <DrinkType, int>{};
    int grandTotal = 0;
    for (final e in entries) {
      totals[e.drinkType] = (totals[e.drinkType] ?? 0) + e.amountMl;
      grandTotal += e.amountMl;
    }
    if (grandTotal == 0) return {};
    return totals.map((k, v) => MapEntry(k, v / grandTotal * 100));
  }

  // ── Helpers ──

  List<WaterEntry> _entriesForDate(List<WaterEntry> entries, DateTime date) {
    return entries
        .where((e) =>
            e.timestamp.year == date.year &&
            e.timestamp.month == date.month &&
            e.timestamp.day == date.day)
        .toList();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
