import '../../models/spo2_entry.dart';

/// Summary statistics for SpO2 readings.
class SpO2Summary {
  final int avgSpO2;
  final int minSpO2;
  final int maxSpO2;
  final int? avgHeartRate;
  final int readingCount;
  final SpO2Category overallCategory;
  final Map<SpO2Category, int> categoryBreakdown;

  const SpO2Summary({
    required this.avgSpO2,
    required this.minSpO2,
    required this.maxSpO2,
    this.avgHeartRate,
    required this.readingCount,
    required this.overallCategory,
    required this.categoryBreakdown,
  });
}

/// Trend direction for SpO2 over time.
enum SpO2Trend { improving, stable, worsening, insufficient }

/// Blood oxygen tracking service with statistics, trends, and insights.
class SpO2Service {
  const SpO2Service();

  SpO2Summary summarize(List<SpO2Entry> entries) {
    if (entries.isEmpty) {
      return const SpO2Summary(
        avgSpO2: 0,
        minSpO2: 0,
        maxSpO2: 0,
        readingCount: 0,
        overallCategory: SpO2Category.normal,
        categoryBreakdown: {},
      );
    }

    int total = 0, totalHR = 0, hrCount = 0;
    int minVal = 101, maxVal = 0;
    final catCount = <SpO2Category, int>{};

    for (final e in entries) {
      total += e.spo2;
      if (e.heartRate != null) {
        totalHR += e.heartRate!;
        hrCount++;
      }
      if (e.spo2 < minVal) minVal = e.spo2;
      if (e.spo2 > maxVal) maxVal = e.spo2;
      catCount[e.category] = (catCount[e.category] ?? 0) + 1;
    }

    final avg = (total / entries.length).round();
    final avgEntry = SpO2Entry(
      id: '',
      timestamp: DateTime.now(),
      spo2: avg,
    );

    return SpO2Summary(
      avgSpO2: avg,
      minSpO2: minVal,
      maxSpO2: maxVal,
      avgHeartRate: hrCount > 0 ? (totalHR / hrCount).round() : null,
      readingCount: entries.length,
      overallCategory: avgEntry.category,
      categoryBreakdown: catCount,
    );
  }

  /// Determine trend by comparing first half vs second half averages.
  SpO2Trend analyzeTrend(List<SpO2Entry> entries) {
    if (entries.length < 4) return SpO2Trend.insufficient;
    final sorted = [...entries]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final mid = sorted.length ~/ 2;
    final firstHalf = sorted.sublist(0, mid);
    final secondHalf = sorted.sublist(mid);

    final firstAvg =
        firstHalf.fold<int>(0, (s, e) => s + e.spo2) / firstHalf.length;
    final secondAvg =
        secondHalf.fold<int>(0, (s, e) => s + e.spo2) / secondHalf.length;

    final diff = secondAvg - firstAvg;
    if (diff > 1.0) return SpO2Trend.improving;
    if (diff < -1.0) return SpO2Trend.worsening;
    return SpO2Trend.stable;
  }

  /// Generate human-readable insights.
  List<String> generateInsights(List<SpO2Entry> entries) {
    if (entries.isEmpty) return ['No readings yet. Add your first SpO2 reading!'];

    final insights = <String>[];
    final summary = summarize(entries);
    final trend = analyzeTrend(entries);

    // Overall status
    insights.add(
        '${summary.overallCategory.emoji} Average SpO2: ${summary.avgSpO2}% — ${summary.overallCategory.label}');

    // Range
    insights
        .add('📊 Range: ${summary.minSpO2}% – ${summary.maxSpO2}%');

    // Trend
    switch (trend) {
      case SpO2Trend.improving:
        insights.add('📈 Your oxygen levels are trending upward. Great!');
        break;
      case SpO2Trend.stable:
        insights.add('➡️ Your oxygen levels are stable.');
        break;
      case SpO2Trend.worsening:
        insights.add('📉 Your oxygen levels are trending downward. Monitor closely.');
        break;
      case SpO2Trend.insufficient:
        insights.add('📝 Add more readings to see trend analysis.');
        break;
    }

    // Heart rate
    if (summary.avgHeartRate != null) {
      insights.add('❤️ Average heart rate: ${summary.avgHeartRate} bpm');
    }

    // Low readings warning
    final lowCount = entries.where((e) => e.spo2 < 95).length;
    if (lowCount > 0) {
      insights.add(
          '⚠️ $lowCount reading${lowCount == 1 ? '' : 's'} below 95%. Consider consulting your doctor.');
    }

    // Context breakdown
    final contextCounts = <SpO2Context, int>{};
    for (final e in entries) {
      contextCounts[e.context] = (contextCounts[e.context] ?? 0) + 1;
    }
    if (contextCounts.length > 1) {
      final topContext = contextCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      insights.add(
          '🏷️ Most readings taken: ${topContext.key.label} (${topContext.value}x)');
    }

    return insights;
  }
}
