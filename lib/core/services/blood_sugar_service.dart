import 'dart:math' as math;

import '../../models/blood_sugar_entry.dart';

/// Summary statistics for blood sugar readings.
class BSSummary {
  final int avgGlucose;
  final int minGlucose;
  final int maxGlucose;
  final int readingCount;
  final BSCategory overallCategory;
  final Map<BSCategory, int> categoryBreakdown;

  const BSSummary({
    required this.avgGlucose,
    required this.minGlucose,
    required this.maxGlucose,
    required this.readingCount,
    required this.overallCategory,
    required this.categoryBreakdown,
  });
}

/// Trend direction for blood sugar over time.
enum BSTrend { improving, stable, worsening, insufficient }

/// Blood sugar tracking service with statistics, trends, and insights.
class BloodSugarService {
  const BloodSugarService();

  // ── Summary ──

  BSSummary summarize(List<BloodSugarEntry> entries) {
    if (entries.isEmpty) {
      return const BSSummary(
        avgGlucose: 0,
        minGlucose: 0,
        maxGlucose: 0,
        readingCount: 0,
        overallCategory: BSCategory.normal,
        categoryBreakdown: {},
      );
    }

    int total = 0, minG = 999, maxG = 0;
    final catCount = <BSCategory, int>{};

    for (final e in entries) {
      total += e.glucoseMgDl;
      if (e.glucoseMgDl < minG) minG = e.glucoseMgDl;
      if (e.glucoseMgDl > maxG) maxG = e.glucoseMgDl;
      catCount[e.category] = (catCount[e.category] ?? 0) + 1;
    }

    final avg = total ~/ entries.length;
    // Overall category from average (treat as fasting for simplicity)
    BSCategory overall;
    if (avg < 70) {
      overall = BSCategory.low;
    } else if (avg <= 99) {
      overall = BSCategory.normal;
    } else if (avg <= 125) {
      overall = BSCategory.prediabetic;
    } else if (avg <= 300) {
      overall = BSCategory.diabetic;
    } else {
      overall = BSCategory.dangerouslyHigh;
    }

    return BSSummary(
      avgGlucose: avg,
      minGlucose: minG,
      maxGlucose: maxG,
      readingCount: entries.length,
      overallCategory: overall,
      categoryBreakdown: catCount,
    );
  }

  // ── Trends ──

  BSTrend trend(List<BloodSugarEntry> entries) {
    if (entries.length < 4) return BSTrend.insufficient;

    final sorted = [...entries]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final half = sorted.length ~/ 2;
    final olderAvg =
        sorted.sublist(0, half).fold<int>(0, (s, e) => s + e.glucoseMgDl) ~/ half;
    final newerAvg =
        sorted.sublist(half).fold<int>(0, (s, e) => s + e.glucoseMgDl) ~/
            (sorted.length - half);

    final diff = newerAvg - olderAvg;
    if (diff < -5) return BSTrend.improving;
    if (diff > 5) return BSTrend.worsening;
    return BSTrend.stable;
  }

  /// Estimated HbA1c from average glucose (eAG formula).
  double estimatedA1c(List<BloodSugarEntry> entries) {
    if (entries.isEmpty) return 0;
    final avg =
        entries.fold<int>(0, (s, e) => s + e.glucoseMgDl) / entries.length;
    // eAG (mg/dL) = 28.7 × A1C − 46.7  →  A1C = (eAG + 46.7) / 28.7
    return (avg + 46.7) / 28.7;
  }

  /// Time-in-range percentage (70-180 mg/dL).
  double timeInRange(List<BloodSugarEntry> entries) {
    if (entries.isEmpty) return 0;
    final inRange =
        entries.where((e) => e.glucoseMgDl >= 70 && e.glucoseMgDl <= 180).length;
    return inRange / entries.length * 100;
  }

  /// Glucose variability (standard deviation).
  double variability(List<BloodSugarEntry> entries) {
    if (entries.length < 2) return 0;
    final avg =
        entries.fold<int>(0, (s, e) => s + e.glucoseMgDl) / entries.length;
    final sumSquares = entries.fold<double>(
      0,
      (s, e) => s + (e.glucoseMgDl - avg) * (e.glucoseMgDl - avg),
    );
    return math.sqrt(sumSquares / (entries.length - 1));
  }
}
