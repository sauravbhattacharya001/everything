import 'dart:math';
import '../../models/energy_entry.dart';
import '../../models/sleep_entry.dart';

// ─── Data Classes ───────────────────────────────────────────────

/// Average energy level for a time slot with sample count.
class TimeSlotAverage {
  final TimeSlot slot;
  final double average;
  final int count;

  const TimeSlotAverage({
    required this.slot,
    required this.average,
    required this.count,
  });

  String get label =>
      '${slot.emoji} ${slot.label}: ${average.toStringAsFixed(1)}/5 ($count entries)';
}

/// Impact of a factor on energy level relative to baseline.
class FactorImpact {
  final EnergyFactor factor;
  final double avgWithFactor;
  final double avgWithout;
  final double delta;
  final int occurrences;

  const FactorImpact({
    required this.factor,
    required this.avgWithFactor,
    required this.avgWithout,
    required this.delta,
    required this.occurrences,
  });

  /// Whether this factor appears to boost energy.
  bool get isPositive => delta > 0;

  String get label {
    final sign = delta >= 0 ? '+' : '';
    return '${factor.emoji} ${factor.label}: $sign${delta.toStringAsFixed(2)} '
        '(${avgWithFactor.toStringAsFixed(1)} vs ${avgWithout.toStringAsFixed(1)}, '
        '$occurrences×)';
  }
}

/// Energy statistics for a single day.
class DailyEnergySummary {
  final DateTime date;
  final double average;
  final int peakValue;
  final int troughValue;
  final TimeSlot? peakSlot;
  final TimeSlot? troughSlot;
  final int entryCount;
  final List<EnergyFactor> topFactors;

  const DailyEnergySummary({
    required this.date,
    required this.average,
    required this.peakValue,
    required this.troughValue,
    this.peakSlot,
    this.troughSlot,
    required this.entryCount,
    this.topFactors = const [],
  });

  /// Energy range (peak - trough); higher = more volatile day.
  int get range => peakValue - troughValue;

  String get dateLabel =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// A streak of consecutive days with energy logging.
class EnergyStreak {
  final DateTime startDate;
  final DateTime endDate;
  final int days;

  const EnergyStreak({
    required this.startDate,
    required this.endDate,
    required this.days,
  });
}

/// An energy trend over a period.
class EnergyTrend {
  final double slope;
  final String direction;
  final double startAvg;
  final double endAvg;
  final int days;

  const EnergyTrend({
    required this.slope,
    required this.direction,
    required this.startAvg,
    required this.endAvg,
    required this.days,
  });
}

/// Recommendation based on energy analysis.
class EnergyRecommendation {
  final String title;
  final String description;
  final String category; // 'timing', 'factor', 'habit', 'warning'

  const EnergyRecommendation({
    required this.title,
    required this.description,
    required this.category,
  });
}

/// Full energy analysis report.
class EnergyReport {
  final double overallAverage;
  final int totalEntries;
  final int totalDays;
  final List<TimeSlotAverage> slotAverages;
  final List<FactorImpact> factorImpacts;
  final List<DailyEnergySummary> dailySummaries;
  final EnergyStreak? currentStreak;
  final EnergyStreak? longestStreak;
  final EnergyTrend? trend;
  final List<EnergyRecommendation> recommendations;
  final TimeSlot? peakSlot;
  final TimeSlot? troughSlot;

  const EnergyReport({
    required this.overallAverage,
    required this.totalEntries,
    required this.totalDays,
    required this.slotAverages,
    required this.factorImpacts,
    required this.dailySummaries,
    required this.currentStreak,
    required this.longestStreak,
    this.trend,
    required this.recommendations,
    this.peakSlot,
    this.troughSlot,
  });
}

// ─── Service ────────────────────────────────────────────────────

/// Tracks personal energy levels throughout the day and analyzes
/// patterns to identify peak productivity windows, energy-draining
/// factors, and optimization opportunities.
///
/// Distinct from mood (emotional state) and sleep (rest quality).
/// Energy represents cognitive/physical capacity for productive work.
class EnergyTrackerService {
  /// Compute the average energy for each time slot across all entries.
  List<TimeSlotAverage> timeSlotAverages(List<EnergyEntry> entries) {
    if (entries.isEmpty) return [];

    final slotEntries = <TimeSlot, List<int>>{};
    for (final entry in entries) {
      final slot = entry.timeSlot;
      slotEntries.putIfAbsent(slot, () => []);
      slotEntries[slot]!.add(entry.level.value);
    }

    final result = <TimeSlotAverage>[];
    for (final slot in TimeSlot.values) {
      final values = slotEntries[slot];
      if (values != null && values.isNotEmpty) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        result.add(TimeSlotAverage(slot: slot, average: avg, count: values.length));
      }
    }
    return result;
  }

  /// Find the time slot with the highest average energy.
  TimeSlot? peakTimeSlot(List<EnergyEntry> entries) {
    final averages = timeSlotAverages(entries);
    if (averages.isEmpty) return null;
    averages.sort((a, b) => b.average.compareTo(a.average));
    return averages.first.slot;
  }

  /// Find the time slot with the lowest average energy.
  TimeSlot? troughTimeSlot(List<EnergyEntry> entries) {
    final averages = timeSlotAverages(entries);
    if (averages.isEmpty) return null;
    averages.sort((a, b) => a.average.compareTo(b.average));
    return averages.first.slot;
  }

  /// Compute the impact of each factor on energy level relative to
  /// entries without that factor.
  List<FactorImpact> factorAnalysis(List<EnergyEntry> entries) {
    if (entries.isEmpty) return [];

    final overallSum = entries.fold<int>(0, (sum, e) => sum + e.level.value);
    final overallAvg = overallSum / entries.length;
    final impacts = <FactorImpact>[];

    for (final factor in EnergyFactor.values) {
      final withFactor = entries.where((e) => e.factors.contains(factor)).toList();
      final withoutFactor = entries.where((e) => !e.factors.contains(factor)).toList();

      if (withFactor.isEmpty || withoutFactor.isEmpty) continue;

      final avgWith =
          withFactor.fold<int>(0, (s, e) => s + e.level.value) / withFactor.length;
      final avgWithout =
          withoutFactor.fold<int>(0, (s, e) => s + e.level.value) / withoutFactor.length;

      impacts.add(FactorImpact(
        factor: factor,
        avgWithFactor: avgWith,
        avgWithout: avgWithout,
        delta: avgWith - avgWithout,
        occurrences: withFactor.length,
      ));
    }

    impacts.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    return impacts;
  }

  /// Get factors sorted by positive impact (energy boosters).
  List<FactorImpact> energyBoosters(List<EnergyEntry> entries) {
    return factorAnalysis(entries).where((f) => f.delta > 0).toList()
      ..sort((a, b) => b.delta.compareTo(a.delta));
  }

  /// Get factors sorted by negative impact (energy drainers).
  List<FactorImpact> energyDrainers(List<EnergyEntry> entries) {
    return factorAnalysis(entries).where((f) => f.delta < 0).toList()
      ..sort((a, b) => a.delta.compareTo(b.delta));
  }

  /// Generate daily summaries for each day with entries.
  List<DailyEnergySummary> dailySummaries(List<EnergyEntry> entries) {
    if (entries.isEmpty) return [];

    final grouped = <String, List<EnergyEntry>>{};
    for (final entry in entries) {
      final key =
          '${entry.timestamp.year}-${entry.timestamp.month}-${entry.timestamp.day}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(entry);
    }

    final summaries = <DailyEnergySummary>[];
    for (final dayEntries in grouped.values) {
      final date = DateTime(
        dayEntries.first.timestamp.year,
        dayEntries.first.timestamp.month,
        dayEntries.first.timestamp.day,
      );
      final values = dayEntries.map((e) => e.level.value).toList();
      final avg = values.reduce((a, b) => a + b) / values.length;
      final peakVal = values.reduce(max);
      final troughVal = values.reduce(min);

      final peakEntry = dayEntries.firstWhere((e) => e.level.value == peakVal);
      final troughEntry = dayEntries.firstWhere((e) => e.level.value == troughVal);

      // Collect all factors from the day, count occurrences
      final factorCounts = <EnergyFactor, int>{};
      for (final entry in dayEntries) {
        for (final factor in entry.factors) {
          factorCounts[factor] = (factorCounts[factor] ?? 0) + 1;
        }
      }
      final topFactors = factorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      summaries.add(DailyEnergySummary(
        date: date,
        average: avg,
        peakValue: peakVal,
        troughValue: troughVal,
        peakSlot: peakEntry.timeSlot,
        troughSlot: troughEntry.timeSlot,
        entryCount: dayEntries.length,
        topFactors: topFactors.take(3).map((e) => e.key).toList(),
      ));
    }

    summaries.sort((a, b) => a.date.compareTo(b.date));
    return summaries;
  }

  /// Compute the daily energy average for the last N days, returning
  /// a list of (date, average) pairs. Days with no entries are excluded.
  List<MapEntry<DateTime, double>> dailyAverages(
    List<EnergyEntry> entries, {
    int days = 14,
    DateTime? relativeTo,
  }) {
    final now = relativeTo ?? DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days));
    final recent = entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
    final summaries = dailySummaries(recent);
    return summaries.map((s) => MapEntry(s.date, s.average)).toList();
  }

  /// Calculate the current and longest streaks of consecutive days with
  /// at least one energy entry.
  Map<String, EnergyStreak?> streaks(
    List<EnergyEntry> entries, {
    DateTime? relativeTo,
  }) {
    if (entries.isEmpty) return {'current': null, 'longest': null};

    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Collect unique dates
    final dates = <DateTime>{};
    for (final entry in entries) {
      dates.add(DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      ));
    }
    final sorted = dates.toList()..sort();

    // Find all streaks
    final streaks = <EnergyStreak>[];
    var streakStart = sorted.first;
    var prevDate = sorted.first;

    for (var i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(prevDate).inDays;
      if (diff > 1) {
        streaks.add(EnergyStreak(
          startDate: streakStart,
          endDate: prevDate,
          days: prevDate.difference(streakStart).inDays + 1,
        ));
        streakStart = sorted[i];
      }
      prevDate = sorted[i];
    }
    // Final streak
    streaks.add(EnergyStreak(
      startDate: streakStart,
      endDate: prevDate,
      days: prevDate.difference(streakStart).inDays + 1,
    ));

    // Longest
    final longest = streaks.reduce(
      (a, b) => a.days >= b.days ? a : b,
    );

    // Current: last streak must include today or yesterday
    final lastStreak = streaks.last;
    final daysSinceLast = today.difference(lastStreak.endDate).inDays;
    final current = daysSinceLast <= 1 ? lastStreak : null;

    return {'current': current, 'longest': longest};
  }

  /// Compute the energy trend (slope) over the given entries' daily averages.
  /// Positive slope = energy improving. Negative = declining.
  EnergyTrend? trend(List<EnergyEntry> entries, {int minDays = 3}) {
    final avgs = dailySummaries(entries);
    if (avgs.length < minDays) return null;

    // Simple linear regression on daily averages
    final n = avgs.length;
    final xMean = (n - 1) / 2.0;
    final yMean = avgs.fold<double>(0, (s, d) => s + d.average) / n;

    var numerator = 0.0;
    var denominator = 0.0;
    for (var i = 0; i < n; i++) {
      numerator += (i - xMean) * (avgs[i].average - yMean);
      denominator += (i - xMean) * (i - xMean);
    }
    if (denominator == 0) return null;

    final slope = numerator / denominator;
    final direction = slope > 0.05
        ? 'improving'
        : slope < -0.05
            ? 'declining'
            : 'stable';

    return EnergyTrend(
      slope: slope,
      direction: direction,
      startAvg: avgs.first.average,
      endAvg: avgs.last.average,
      days: n,
    );
  }

  /// Correlate energy levels with sleep quality from the same day.
  /// Returns the average energy for each sleep quality level.
  Map<int, double> sleepEnergyCorrelation(
    List<EnergyEntry> energyEntries,
    List<SleepEntry> sleepEntries,
  ) {
    if (energyEntries.isEmpty || sleepEntries.isEmpty) return {};

    // Build sleep quality by date (SleepEntry.date is derived from wakeTime)
    final sleepByDate = <String, int>{};
    for (final sleep in sleepEntries) {
      final key =
          '${sleep.date.year}-${sleep.date.month}-${sleep.date.day}';
      sleepByDate[key] = sleep.quality.value;
    }

    // Group energy by quality
    final qualityEnergy = <int, List<int>>{};
    for (final entry in energyEntries) {
      final key =
          '${entry.timestamp.year}-${entry.timestamp.month}-${entry.timestamp.day}';
      final quality = sleepByDate[key];
      if (quality != null) {
        qualityEnergy.putIfAbsent(quality, () => []);
        qualityEnergy[quality]!.add(entry.level.value);
      }
    }

    return qualityEnergy.map(
      (quality, values) => MapEntry(
        quality,
        values.reduce((a, b) => a + b) / values.length,
      ),
    );
  }

  /// Generate actionable recommendations based on energy patterns.
  List<EnergyRecommendation> recommendations(List<EnergyEntry> entries) {
    if (entries.isEmpty) return [];

    final recs = <EnergyRecommendation>[];
    final boosters = energyBoosters(entries);
    final drainers = energyDrainers(entries);
    final peak = peakTimeSlot(entries);
    final trough = troughTimeSlot(entries);
    final slotAvgs = timeSlotAverages(entries);

    // Peak time recommendation
    if (peak != null) {
      recs.add(EnergyRecommendation(
        title: 'Schedule deep work during ${peak.label}',
        description:
            'Your energy tends to peak during ${peak.label}. '
            'Schedule your most demanding tasks in this window.',
        category: 'timing',
      ));
    }

    // Trough warning
    if (trough != null && peak != trough) {
      recs.add(EnergyRecommendation(
        title: 'Avoid demanding tasks during ${trough.label}',
        description:
            'Your energy dips during ${trough.label}. '
            'Schedule lighter tasks, breaks, or walks here.',
        category: 'timing',
      ));
    }

    // Top boosters
    for (final booster in boosters.take(2)) {
      if (booster.delta > 0.3) {
        recs.add(EnergyRecommendation(
          title: '${booster.factor.emoji} ${booster.factor.label} boosts your energy',
          description:
              'When you log ${booster.factor.label.toLowerCase()}, your energy '
              'averages ${booster.avgWithFactor.toStringAsFixed(1)} vs '
              '${booster.avgWithout.toStringAsFixed(1)} without it '
              '(+${booster.delta.toStringAsFixed(1)}).',
          category: 'factor',
        ));
      }
    }

    // Top drainers
    for (final drainer in drainers.take(2)) {
      if (drainer.delta < -0.3) {
        recs.add(EnergyRecommendation(
          title: '${drainer.factor.emoji} ${drainer.factor.label} drains your energy',
          description:
              'When you log ${drainer.factor.label.toLowerCase()}, your energy '
              'drops to ${drainer.avgWithFactor.toStringAsFixed(1)} vs '
              '${drainer.avgWithout.toStringAsFixed(1)} without it '
              '(${drainer.delta.toStringAsFixed(1)}).',
          category: 'factor',
        ));
      }
    }

    // Low overall average warning
    final overallAvg =
        entries.fold<int>(0, (s, e) => s + e.level.value) / entries.length;
    if (overallAvg < 2.5) {
      recs.add(const EnergyRecommendation(
        title: '⚠️ Consistently low energy',
        description:
            'Your average energy is below 2.5/5. Consider reviewing your '
            'sleep, hydration, and activity levels. Consult a healthcare '
            'provider if fatigue persists.',
        category: 'warning',
      ));
    }

    // Afternoon slump detection
    final afternoonAvg = slotAvgs
        .where((s) => s.slot == TimeSlot.afternoon)
        .toList();
    final morningAvg = slotAvgs
        .where((s) => s.slot == TimeSlot.morning)
        .toList();
    if (afternoonAvg.isNotEmpty &&
        morningAvg.isNotEmpty &&
        morningAvg.first.average - afternoonAvg.first.average > 1.0) {
      recs.add(const EnergyRecommendation(
        title: '📉 Afternoon energy crash detected',
        description:
            'Your energy drops significantly from morning to afternoon. '
            'Try a short walk, healthy snack, or power nap after lunch.',
        category: 'habit',
      ));
    }

    // Logging consistency
    final summaries = dailySummaries(entries);
    final daysWithFewEntries = summaries.where((s) => s.entryCount < 2).length;
    if (summaries.isNotEmpty && daysWithFewEntries > summaries.length * 0.5) {
      recs.add(const EnergyRecommendation(
        title: '📝 Log more frequently',
        description:
            'Over half your days have only 1 entry. Logging 3-4 times '
            'per day gives much better pattern detection.',
        category: 'habit',
      ));
    }

    return recs;
  }

  /// Filter entries to a date range.
  List<EnergyEntry> filterByDateRange(
    List<EnergyEntry> entries,
    DateTime start,
    DateTime end,
  ) {
    return entries
        .where((e) =>
            !e.timestamp.isBefore(start) && e.timestamp.isBefore(end))
        .toList();
  }

  /// Filter entries to a specific time slot.
  List<EnergyEntry> filterByTimeSlot(
    List<EnergyEntry> entries,
    TimeSlot slot,
  ) {
    return entries.where((e) => e.timeSlot == slot).toList();
  }

  /// Compute the overall average energy level.
  double overallAverage(List<EnergyEntry> entries) {
    if (entries.isEmpty) return 0.0;
    return entries.fold<int>(0, (s, e) => s + e.level.value) / entries.length;
  }

  /// Energy stability: standard deviation of daily averages.
  /// Lower = more consistent. Higher = more volatile.
  double stability(List<EnergyEntry> entries) {
    final avgs = dailySummaries(entries);
    if (avgs.length < 2) return 0.0;

    final mean = avgs.fold<double>(0, (s, d) => s + d.average) / avgs.length;
    final variance = avgs.fold<double>(
            0, (s, d) => s + (d.average - mean) * (d.average - mean)) /
        avgs.length;
    return sqrt(variance);
  }

  /// Generate a comprehensive energy report.
  EnergyReport generateReport(
    List<EnergyEntry> entries, {
    List<SleepEntry>? sleepEntries,
  }) {
    final summaries = dailySummaries(entries);
    final streakData = streaks(entries);
    final slotAvgs = timeSlotAverages(entries);
    final factors = factorAnalysis(entries);

    return EnergyReport(
      overallAverage: overallAverage(entries),
      totalEntries: entries.length,
      totalDays: summaries.length,
      slotAverages: slotAvgs,
      factorImpacts: factors,
      dailySummaries: summaries,
      currentStreak: streakData['current'],
      longestStreak: streakData['longest'],
      trend: trend(entries),
      recommendations: recommendations(entries),
      peakSlot: peakTimeSlot(entries),
      troughSlot: troughTimeSlot(entries),
    );
  }

  /// Generate a text summary of energy patterns.
  String textSummary(List<EnergyEntry> entries) {
    if (entries.isEmpty) return 'No energy entries recorded yet.';

    final report = generateReport(entries);
    final lines = <String>[
      '⚡ Energy Report',
      '═══════════════════════════════════════',
      'Overall average: ${report.overallAverage.toStringAsFixed(1)}/5',
      'Total entries: ${report.totalEntries} across ${report.totalDays} days',
      '',
    ];

    if (report.peakSlot != null) {
      lines.add(
          '🔋 Peak time: ${report.peakSlot!.emoji} ${report.peakSlot!.label}');
    }
    if (report.troughSlot != null) {
      lines.add(
          '🪫 Low time: ${report.troughSlot!.emoji} ${report.troughSlot!.label}');
    }
    lines.add('');

    if (report.slotAverages.isNotEmpty) {
      lines.add('Time-of-Day Breakdown:');
      for (final avg in report.slotAverages) {
        lines.add('  ${avg.label}');
      }
      lines.add('');
    }

    final boosters = report.factorImpacts.where((f) => f.delta > 0).take(3);
    if (boosters.isNotEmpty) {
      lines.add('Energy Boosters:');
      for (final b in boosters) {
        lines.add('  ${b.label}');
      }
      lines.add('');
    }

    final drainers = report.factorImpacts.where((f) => f.delta < 0).take(3);
    if (drainers.isNotEmpty) {
      lines.add('Energy Drainers:');
      for (final d in drainers) {
        lines.add('  ${d.label}');
      }
      lines.add('');
    }

    if (report.trend != null) {
      lines.add(
          'Trend: ${report.trend!.direction} (${report.trend!.slope >= 0 ? "+" : ""}${report.trend!.slope.toStringAsFixed(3)}/day over ${report.trend!.days} days)');
      lines.add('');
    }

    if (report.currentStreak != null) {
      lines.add('🔥 Current streak: ${report.currentStreak!.days} days');
    }
    if (report.longestStreak != null) {
      lines.add('🏆 Longest streak: ${report.longestStreak!.days} days');
    }

    if (report.recommendations.isNotEmpty) {
      lines.add('');
      lines.add('Recommendations:');
      for (final rec in report.recommendations) {
        lines.add('  • ${rec.title}');
      }
    }

    return lines.join('\n');
  }
}
