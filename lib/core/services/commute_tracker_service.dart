import '../../models/commute_entry.dart';

/// Service for commute tracking analytics and summaries.
class CommuteTrackerService {
  const CommuteTrackerService();

  /// Get entries for a specific date.
  List<CommuteEntry> entriesForDate(List<CommuteEntry> entries, DateTime date) {
    return entries
        .where((e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get entries for a date range.
  List<CommuteEntry> entriesInRange(
      List<CommuteEntry> entries, DateTime start, DateTime end) {
    return entries
        .where((e) =>
            !e.date.isBefore(start) &&
            e.date.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get entries for current month.
  List<CommuteEntry> currentMonthEntries(List<CommuteEntry> entries) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return entriesInRange(entries, start, end);
  }

  /// Compute weekly summary.
  CommuteWeeklySummary weeklySummary(
      List<CommuteEntry> entries, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekEntries = entriesInRange(entries, weekStart, weekEnd);

    final modeBreakdown = <CommuteMode, int>{};
    int totalMin = 0;
    double totalDist = 0;
    double totalCost = 0;
    double totalCo2 = 0;
    double comfortSum = 0;
    int comfortCount = 0;

    for (final e in weekEntries) {
      modeBreakdown[e.mode] = (modeBreakdown[e.mode] ?? 0) + 1;
      totalMin += e.durationMinutes;
      totalDist += e.distanceKm ?? 0;
      totalCost += e.cost ?? 0;
      totalCo2 += e.co2Kg;
      if (e.comfort != null) {
        comfortSum += e.comfort!.value;
        comfortCount++;
      }
    }

    return CommuteWeeklySummary(
      weekStart: weekStart,
      totalTrips: weekEntries.length,
      totalMinutes: totalMin,
      totalDistanceKm: totalDist,
      totalCost: totalCost,
      totalCo2Kg: totalCo2,
      modeBreakdown: modeBreakdown,
      avgComfort: comfortCount > 0 ? comfortSum / comfortCount : 0,
    );
  }

  /// Compute mode distribution as percentages.
  Map<CommuteMode, double> modeDistribution(List<CommuteEntry> entries) {
    if (entries.isEmpty) return {};
    final counts = <CommuteMode, int>{};
    for (final e in entries) {
      counts[e.mode] = (counts[e.mode] ?? 0) + 1;
    }
    return counts.map((k, v) => MapEntry(k, v / entries.length * 100));
  }

  /// Total cost for entries.
  double totalCost(List<CommuteEntry> entries) {
    return entries.fold(0.0, (sum, e) => sum + (e.cost ?? 0));
  }

  /// Total CO₂ for entries in kg.
  double totalCo2(List<CommuteEntry> entries) {
    return entries.fold(0.0, (sum, e) => sum + e.co2Kg);
  }

  /// Total minutes for entries.
  int totalMinutes(List<CommuteEntry> entries) {
    return entries.fold(0, (sum, e) => sum + e.durationMinutes);
  }

  /// Average comfort rating.
  double avgComfort(List<CommuteEntry> entries) {
    final rated = entries.where((e) => e.comfort != null).toList();
    if (rated.isEmpty) return 0;
    return rated.fold(0.0, (sum, e) => sum + e.comfort!.value) / rated.length;
  }

  /// Get the most used mode.
  CommuteMode? topMode(List<CommuteEntry> entries) {
    if (entries.isEmpty) return null;
    final counts = <CommuteMode, int>{};
    for (final e in entries) {
      counts[e.mode] = (counts[e.mode] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Green commute percentage (zero-emission modes).
  double greenPercentage(List<CommuteEntry> entries) {
    if (entries.isEmpty) return 0;
    final green =
        entries.where((e) => e.mode.co2PerKm == 0).length;
    return green / entries.length * 100;
  }

  /// Average commute duration.
  double avgDurationMinutes(List<CommuteEntry> entries) {
    if (entries.isEmpty) return 0;
    return totalMinutes(entries) / entries.length;
  }

  /// Generate monthly insights.
  List<CommuteMonthlyInsight> monthlyInsights(List<CommuteEntry> entries) {
    final monthly = currentMonthEntries(entries);
    if (monthly.isEmpty) {
      return [
        const CommuteMonthlyInsight(
          label: 'No Data',
          value: 'Start logging commutes!',
          emoji: '📝',
        ),
      ];
    }

    final insights = <CommuteMonthlyInsight>[];

    insights.add(CommuteMonthlyInsight(
      label: 'Total Trips',
      value: '${monthly.length}',
      emoji: '🧭',
    ));

    final cost = totalCost(monthly);
    insights.add(CommuteMonthlyInsight(
      label: 'Monthly Cost',
      value: '\$${cost.toStringAsFixed(2)}',
      emoji: '💰',
    ));

    final co2 = totalCo2(monthly);
    insights.add(CommuteMonthlyInsight(
      label: 'CO₂ Emissions',
      value: '${co2.toStringAsFixed(1)} kg',
      emoji: '🌿',
    ));

    final green = greenPercentage(monthly);
    insights.add(CommuteMonthlyInsight(
      label: 'Green Trips',
      value: '${green.toStringAsFixed(0)}%',
      emoji: '♻️',
    ));

    final avgDur = avgDurationMinutes(monthly);
    insights.add(CommuteMonthlyInsight(
      label: 'Avg Duration',
      value: '${avgDur.toStringAsFixed(0)} min',
      emoji: '⏱️',
    ));

    final top = topMode(monthly);
    if (top != null) {
      insights.add(CommuteMonthlyInsight(
        label: 'Top Mode',
        value: '${top.emoji} ${top.label}',
        emoji: '🏆',
      ));
    }

    return insights;
  }

  /// Streak of consecutive days with commutes.
  int currentStreak(List<CommuteEntry> entries) {
    if (entries.isEmpty) return 0;
    final dates = entries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i - 1].difference(dates[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
