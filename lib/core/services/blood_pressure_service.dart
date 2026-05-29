import '../../models/blood_pressure_entry.dart';
import '../utils/date_utils.dart';

/// Summary statistics for a collection of BP readings.
class BPSummary {
  final int avgSystolic;
  final int avgDiastolic;
  final int? avgPulse;
  final int minSystolic;
  final int maxSystolic;
  final int minDiastolic;
  final int maxDiastolic;
  final int readingCount;
  final BPCategory overallCategory;
  final Map<BPCategory, int> categoryBreakdown;

  const BPSummary({
    required this.avgSystolic,
    required this.avgDiastolic,
    this.avgPulse,
    required this.minSystolic,
    required this.maxSystolic,
    required this.minDiastolic,
    required this.maxDiastolic,
    required this.readingCount,
    required this.overallCategory,
    required this.categoryBreakdown,
  });
}

/// Trend direction for blood pressure over time.
enum BPTrend { improving, stable, worsening, insufficient }

/// Blood pressure tracking service with statistics, trends, and insights.
class BloodPressureService {
  const BloodPressureService();

  // ── Summary ──

  /// Computes aggregate statistics across all [entries].
  ///
  /// Returns a [BPSummary] with averages, min/max ranges, reading count,
  /// an overall BP category derived from the mean systolic/diastolic, and
  /// a breakdown of how many readings fall into each [BPCategory].
  /// Returns zeroed values when [entries] is empty.
  BPSummary summarize(List<BloodPressureEntry> entries) {
    if (entries.isEmpty) {
      return const BPSummary(
        avgSystolic: 0,
        avgDiastolic: 0,
        minSystolic: 0,
        maxSystolic: 0,
        minDiastolic: 0,
        maxDiastolic: 0,
        readingCount: 0,
        overallCategory: BPCategory.normal,
        categoryBreakdown: {},
      );
    }

    int totalSys = 0, totalDia = 0, totalPulse = 0, pulseCount = 0;
    int minSys = 999, maxSys = 0, minDia = 999, maxDia = 0;
    final catCount = <BPCategory, int>{};

    for (final e in entries) {
      totalSys += e.systolic;
      totalDia += e.diastolic;
      if (e.pulse != null) {
        totalPulse += e.pulse!;
        pulseCount++;
      }
      if (e.systolic < minSys) minSys = e.systolic;
      if (e.systolic > maxSys) maxSys = e.systolic;
      if (e.diastolic < minDia) minDia = e.diastolic;
      if (e.diastolic > maxDia) maxDia = e.diastolic;
      catCount[e.category] = (catCount[e.category] ?? 0) + 1;
    }

    final avgSys = (totalSys / entries.length).round();
    final avgDia = (totalDia / entries.length).round();

    // Overall category from averages
    final avgEntry = BloodPressureEntry(
      id: '',
      timestamp: DateTime.now(),
      systolic: avgSys,
      diastolic: avgDia,
    );

    return BPSummary(
      avgSystolic: avgSys,
      avgDiastolic: avgDia,
      avgPulse: pulseCount > 0 ? (totalPulse / pulseCount).round() : null,
      minSystolic: minSys,
      maxSystolic: maxSys,
      minDiastolic: minDia,
      maxDiastolic: maxDia,
      readingCount: entries.length,
      overallCategory: avgEntry.category,
      categoryBreakdown: catCount,
    );
  }

  // ── Trend ──

  /// Determines the systolic blood pressure trend over time.
  ///
  /// Splits [entries] into chronological halves and compares mean systolic
  /// values.  A drop of ≥5 mmHg indicates [BPTrend.improving]; a rise of
  /// ≥5 mmHg indicates [BPTrend.worsening]; otherwise [BPTrend.stable].
  /// Returns [BPTrend.insufficient] when fewer than 4 readings are available.
  BPTrend trend(List<BloodPressureEntry> entries) {
    if (entries.length < 4) return BPTrend.insufficient;

    final sorted = List<BloodPressureEntry>.from(entries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final half = sorted.length ~/ 2;
    final firstHalf = sorted.sublist(0, half);
    final secondHalf = sorted.sublist(half);

    final firstAvg = firstHalf.fold<int>(0, (s, e) => s + e.systolic) / firstHalf.length;
    final secondAvg = secondHalf.fold<int>(0, (s, e) => s + e.systolic) / secondHalf.length;
    final diff = secondAvg - firstAvg;

    if (diff <= -5) return BPTrend.improving;
    if (diff >= 5) return BPTrend.worsening;
    return BPTrend.stable;
  }

  /// Returns a human-readable emoji + text label for the given [BPTrend].
  String trendLabel(BPTrend t) {
    switch (t) {
      case BPTrend.improving:
        return '📉 Improving';
      case BPTrend.stable:
        return '➡️ Stable';
      case BPTrend.worsening:
        return '📈 Worsening';
      case BPTrend.insufficient:
        return '📊 Need more readings';
    }
  }

  // ── Entries for date range ──

  /// Filters [entries] to those recorded strictly between [start] and [end].
  List<BloodPressureEntry> entriesInRange(
    List<BloodPressureEntry> entries,
    DateTime start,
    DateTime end,
  ) {
    return entries
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .toList();
  }

  /// Filters [entries] to those recorded on the same calendar day as [date].
  List<BloodPressureEntry> entriesForDate(
    List<BloodPressureEntry> entries,
    DateTime date,
  ) {
    return entries
        .where((e) => AppDateUtils.isSameDay(e.timestamp, date))
        .toList();
  }

  // ── Insights ──

  /// Generates a list of human-readable insight strings from [entries].
  ///
  /// Includes the overall average with category, pulse average (if tracked),
  /// trend direction, variability warnings, time-of-day analysis (morning vs
  /// at-rest comparison for potential white-coat effect), and lifestyle advice
  /// based on the overall category.  Returns an empty list for empty input.
  List<String> generateInsights(List<BloodPressureEntry> entries) {
    final insights = <String>[];
    if (entries.isEmpty) return insights;

    final summary = summarize(entries);
    final t = trend(entries);

    insights.add(
        '${summary.overallCategory.emoji} Average: ${summary.avgSystolic}/${summary.avgDiastolic} mmHg — ${summary.overallCategory.label}');

    if (summary.avgPulse != null) {
      insights.add('💓 Average pulse: ${summary.avgPulse} bpm');
    }

    insights.add(trendLabel(t));

    if (summary.maxSystolic - summary.minSystolic > 30) {
      insights.add(
          '⚠️ High variability: systolic ranges ${summary.minSystolic}–${summary.maxSystolic}');
    }

    // Check for white-coat effect (higher in certain contexts)
    final morningEntries =
        entries.where((e) => e.context == ReadingContext.morning).toList();
    final restEntries =
        entries.where((e) => e.context == ReadingContext.atRest).toList();
    if (morningEntries.length >= 3 && restEntries.length >= 3) {
      final morningAvg =
          morningEntries.fold<int>(0, (s, e) => s + e.systolic) /
              morningEntries.length;
      final restAvg =
          restEntries.fold<int>(0, (s, e) => s + e.systolic) /
              restEntries.length;
      if (morningAvg - restAvg > 10) {
        insights.add('🌅 Morning readings tend to be higher than at-rest readings.');
      }
    }

    insights.add(summary.overallCategory.advice);

    return insights;
  }
}
