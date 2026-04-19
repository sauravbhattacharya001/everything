import 'dart:math' show pow;
import '../../models/caffeine_entry.dart';
import '../utils/date_utils.dart';

/// Configuration for caffeine tracking.
class CaffeineConfig {
  /// Recommended daily maximum in mg (FDA guideline: 400mg).
  final int dailyLimitMg;

  /// Hour after which caffeine should be avoided for sleep quality.
  final int cutoffHour;

  const CaffeineConfig({
    this.dailyLimitMg = 400,
    this.cutoffHour = 14,
  });

  Map<String, dynamic> toJson() => {
        'dailyLimitMg': dailyLimitMg,
        'cutoffHour': cutoffHour,
      };

  factory CaffeineConfig.fromJson(Map<String, dynamic> json) {
    return CaffeineConfig(
      dailyLimitMg: json['dailyLimitMg'] as int? ?? 400,
      cutoffHour: json['cutoffHour'] as int? ?? 14,
    );
  }
}

/// Daily caffeine summary.
class CaffeineDailySummary {
  final DateTime date;
  final int totalMg;
  final int entryCount;
  final int limitMg;
  final Map<CaffeineSource, int> bySource;
  final bool hadCaffeineAfterCutoff;

  const CaffeineDailySummary({
    required this.date,
    required this.totalMg,
    required this.entryCount,
    required this.limitMg,
    required this.bySource,
    required this.hadCaffeineAfterCutoff,
  });

  double get percentOfLimit =>
      limitMg > 0 ? (totalMg / limitMg).clamp(0.0, 2.0) : 0.0;

  bool get overLimit => totalMg > limitMg;
}

/// Service for caffeine tracking calculations.
class CaffeineTrackerService {
  final CaffeineConfig config;

  const CaffeineTrackerService({this.config = const CaffeineConfig()});

  /// Total caffeine still active in the body at [atTime].
  double activeSystemCaffeine(List<CaffeineEntry> entries, DateTime atTime) {
    double total = 0;
    for (final e in entries) {
      total += e.remainingMgAt(atTime);
    }
    return total;
  }

  /// Get entries for a specific date.
  List<CaffeineEntry> entriesForDate(
      List<CaffeineEntry> entries, DateTime date) {
    return entries
        .where((e) => AppDateUtils.isSameDay(e.timestamp, date))
        .toList();
  }

  /// Compute daily summary for a given date.
  CaffeineDailySummary dailySummary(
      List<CaffeineEntry> entries, DateTime date) {
    final dayEntries = entriesForDate(entries, date);
    final bySource = <CaffeineSource, int>{};
    int total = 0;
    bool afterCutoff = false;

    for (final e in dayEntries) {
      total += e.caffeineMg;
      bySource[e.source] = (bySource[e.source] ?? 0) + e.caffeineMg;
      if (e.timestamp.hour >= config.cutoffHour) {
        afterCutoff = true;
      }
    }

    return CaffeineDailySummary(
      date: date,
      totalMg: total,
      entryCount: dayEntries.length,
      limitMg: config.dailyLimitMg,
      bySource: bySource,
      hadCaffeineAfterCutoff: afterCutoff,
    );
  }

  /// Weekly totals for the last 7 days.
  List<CaffeineDailySummary> weeklyHistory(
      List<CaffeineEntry> entries, DateTime today) {
    return List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      return dailySummary(entries, date);
    });
  }

  /// Estimate hours until caffeine drops below threshold (default 50mg).
  double hoursUntilBelow(
      List<CaffeineEntry> entries, DateTime now, {double threshold = 50}) {
    final current = activeSystemCaffeine(entries, now);
    if (current <= threshold) return 0;
    // Binary search for the time
    double lo = 0, hi = 48;
    for (int i = 0; i < 50; i++) {
      final mid = (lo + hi) / 2;
      final future = now.add(Duration(minutes: (mid * 60).round()));
      if (activeSystemCaffeine(entries, future) > threshold) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return hi;
  }
}
