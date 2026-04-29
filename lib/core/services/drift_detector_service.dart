import 'dart:convert';
import 'dart:math';

/// Personal Drift Detector Service — autonomous lifestyle regression
/// early warning system that monitors gradual negative changes humans
/// don't notice (the "boiling frog" problem).
///
/// Tracks rolling windows of life metrics, detects slow drift via
/// linear regression, predicts tipping points, correlates cross-metric
/// slides, and generates proactive recovery nudges.

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// How fast a metric is changing.
enum DriftSeverity {
  stable,
  improving,
  drifting,
  sliding,
  freefall;

  String get label {
    switch (this) {
      case DriftSeverity.stable:
        return 'Stable';
      case DriftSeverity.improving:
        return 'Improving';
      case DriftSeverity.drifting:
        return 'Drifting';
      case DriftSeverity.sliding:
        return 'Sliding';
      case DriftSeverity.freefall:
        return 'Freefall';
    }
  }

  String get emoji {
    switch (this) {
      case DriftSeverity.stable:
        return '✅';
      case DriftSeverity.improving:
        return '📈';
      case DriftSeverity.drifting:
        return '⚠️';
      case DriftSeverity.sliding:
        return '🔻';
      case DriftSeverity.freefall:
        return '🚨';
    }
  }

  /// Numeric priority (higher = worse).
  int get priority {
    switch (this) {
      case DriftSeverity.improving:
        return 0;
      case DriftSeverity.stable:
        return 1;
      case DriftSeverity.drifting:
        return 2;
      case DriftSeverity.sliding:
        return 3;
      case DriftSeverity.freefall:
        return 4;
    }
  }
}

/// Alert urgency level.
enum AlertUrgency {
  info,
  watch,
  warning,
  urgent,
  critical;

  String get emoji {
    switch (this) {
      case AlertUrgency.info:
        return 'ℹ️';
      case AlertUrgency.watch:
        return '👀';
      case AlertUrgency.warning:
        return '⚠️';
      case AlertUrgency.urgent:
        return '🔴';
      case AlertUrgency.critical:
        return '🚨';
    }
  }
}

/// Life domain categories.
enum LifeDomain {
  health,
  fitness,
  mental,
  financial,
  productivity,
  social,
  nutrition;

  String get label {
    switch (this) {
      case LifeDomain.health:
        return 'Health';
      case LifeDomain.fitness:
        return 'Fitness';
      case LifeDomain.mental:
        return 'Mental';
      case LifeDomain.financial:
        return 'Financial';
      case LifeDomain.productivity:
        return 'Productivity';
      case LifeDomain.social:
        return 'Social';
      case LifeDomain.nutrition:
        return 'Nutrition';
    }
  }

  String get emoji {
    switch (this) {
      case LifeDomain.health:
        return '❤️';
      case LifeDomain.fitness:
        return '💪';
      case LifeDomain.mental:
        return '🧠';
      case LifeDomain.financial:
        return '💰';
      case LifeDomain.productivity:
        return '⚡';
      case LifeDomain.social:
        return '👥';
      case LifeDomain.nutrition:
        return '🥗';
    }
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// A single metric data point.
class MetricDataPoint {
  final DateTime date;
  final double value;

  const MetricDataPoint({required this.date, required this.value});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'value': value,
      };

  factory MetricDataPoint.fromJson(Map<String, dynamic> json) =>
      MetricDataPoint(
        date: DateTime.parse(json['date'] as String),
        value: (json['value'] as num).toDouble(),
      );
}

/// Definition of a trackable life metric.
class MetricDefinition {
  final String id;
  final String name;
  final LifeDomain domain;
  final String unit;
  final double idealMin;
  final double idealMax;
  final double dangerMin;
  final double dangerMax;
  /// Whether higher values are better (true) or worse (false).
  final bool higherIsBetter;

  const MetricDefinition({
    required this.id,
    required this.name,
    required this.domain,
    required this.unit,
    required this.idealMin,
    required this.idealMax,
    required this.dangerMin,
    required this.dangerMax,
    this.higherIsBetter = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'domain': domain.name,
        'unit': unit,
        'idealMin': idealMin,
        'idealMax': idealMax,
        'dangerMin': dangerMin,
        'dangerMax': dangerMax,
        'higherIsBetter': higherIsBetter,
      };

  factory MetricDefinition.fromJson(Map<String, dynamic> json) =>
      MetricDefinition(
        id: json['id'] as String,
        name: json['name'] as String,
        domain: LifeDomain.values.firstWhere(
            (d) => d.name == json['domain'],
            orElse: () => LifeDomain.health),
        unit: json['unit'] as String,
        idealMin: (json['idealMin'] as num).toDouble(),
        idealMax: (json['idealMax'] as num).toDouble(),
        dangerMin: (json['dangerMin'] as num).toDouble(),
        dangerMax: (json['dangerMax'] as num).toDouble(),
        higherIsBetter: json['higherIsBetter'] as bool? ?? true,
      );
}

/// Result of linear regression on a metric's time series.
class TrendLine {
  final double slope;
  final double intercept;
  final double rSquared;
  final int sampleSize;

  const TrendLine({
    required this.slope,
    required this.intercept,
    required this.rSquared,
    required this.sampleSize,
  });

  /// Predicted value at [daysFromStart].
  double predict(double daysFromStart) => intercept + slope * daysFromStart;
}

/// Drift analysis for a single metric.
class MetricDrift {
  final MetricDefinition definition;
  final TrendLine trend7d;
  final TrendLine trend30d;
  final TrendLine trend90d;
  final double currentAvg;
  final double weekAgoAvg;
  final double monthAgoAvg;
  final DriftSeverity severity;
  /// Change per week based on 30-day trend.
  final double weeklyVelocity;
  /// Days until metric hits danger zone at current rate (null = not drifting).
  final int? daysToTippingPoint;
  /// Percentage change over 30 days.
  final double monthlyChangePercent;

  const MetricDrift({
    required this.definition,
    required this.trend7d,
    required this.trend30d,
    required this.trend90d,
    required this.currentAvg,
    required this.weekAgoAvg,
    required this.monthAgoAvg,
    required this.severity,
    required this.weeklyVelocity,
    required this.daysToTippingPoint,
    required this.monthlyChangePercent,
  });
}

/// A pair of metrics drifting together.
class DriftCorrelation {
  final String metricA;
  final String metricB;
  final double correlation;
  final String insight;

  const DriftCorrelation({
    required this.metricA,
    required this.metricB,
    required this.correlation,
    required this.insight,
  });
}

/// Proactive drift alert.
class DriftAlert {
  final String metricId;
  final String title;
  final String message;
  final AlertUrgency urgency;
  final String suggestion;
  final DateTime generated;

  const DriftAlert({
    required this.metricId,
    required this.title,
    required this.message,
    required this.urgency,
    required this.suggestion,
    required this.generated,
  });

  Map<String, dynamic> toJson() => {
        'metricId': metricId,
        'title': title,
        'message': message,
        'urgency': urgency.name,
        'suggestion': suggestion,
        'generated': generated.toIso8601String(),
      };
}

/// Snapshot comparing current vs historical averages.
class LifestyleSnapshot {
  final Map<String, double> currentWeek;
  final Map<String, double> lastWeek;
  final Map<String, double> lastMonth;
  final Map<String, double> threeMonthsAgo;
  final double overallHealthScore;
  final int metricsImproving;
  final int metricsStable;
  final int metricsDrifting;

  const LifestyleSnapshot({
    required this.currentWeek,
    required this.lastWeek,
    required this.lastMonth,
    required this.threeMonthsAgo,
    required this.overallHealthScore,
    required this.metricsImproving,
    required this.metricsStable,
    required this.metricsDrifting,
  });
}

/// Full drift analysis report.
class DriftReport {
  final DateTime generatedAt;
  final List<MetricDrift> drifts;
  final List<DriftCorrelation> correlations;
  final List<DriftAlert> alerts;
  final LifestyleSnapshot snapshot;
  final double lifestyleStabilityScore;

  const DriftReport({
    required this.generatedAt,
    required this.drifts,
    required this.correlations,
    required this.alerts,
    required this.snapshot,
    required this.lifestyleStabilityScore,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class DriftDetectorService {
  /// Metric definitions — these are the default trackable metrics.
  static const List<MetricDefinition> defaultMetrics = [
    MetricDefinition(
      id: 'sleep_hours',
      name: 'Sleep Duration',
      domain: LifeDomain.health,
      unit: 'hours',
      idealMin: 7.0,
      idealMax: 9.0,
      dangerMin: 5.0,
      dangerMax: 11.0,
    ),
    MetricDefinition(
      id: 'mood_score',
      name: 'Mood Score',
      domain: LifeDomain.mental,
      unit: 'score',
      idealMin: 6.0,
      idealMax: 10.0,
      dangerMin: 3.0,
      dangerMax: 10.0,
    ),
    MetricDefinition(
      id: 'exercise_minutes',
      name: 'Exercise',
      domain: LifeDomain.fitness,
      unit: 'min/day',
      idealMin: 30.0,
      idealMax: 120.0,
      dangerMin: 0.0,
      dangerMax: 180.0,
    ),
    MetricDefinition(
      id: 'water_ml',
      name: 'Water Intake',
      domain: LifeDomain.nutrition,
      unit: 'ml',
      idealMin: 2000.0,
      idealMax: 3500.0,
      dangerMin: 1000.0,
      dangerMax: 5000.0,
    ),
    MetricDefinition(
      id: 'screen_hours',
      name: 'Screen Time',
      domain: LifeDomain.health,
      unit: 'hours',
      idealMin: 0.0,
      idealMax: 4.0,
      dangerMin: 0.0,
      dangerMax: 10.0,
      higherIsBetter: false,
    ),
    MetricDefinition(
      id: 'spending',
      name: 'Daily Spending',
      domain: LifeDomain.financial,
      unit: '\$',
      idealMin: 0.0,
      idealMax: 50.0,
      dangerMin: 0.0,
      dangerMax: 200.0,
      higherIsBetter: false,
    ),
    MetricDefinition(
      id: 'social_interactions',
      name: 'Social Interactions',
      domain: LifeDomain.social,
      unit: 'count',
      idealMin: 2.0,
      idealMax: 10.0,
      dangerMin: 0.0,
      dangerMax: 20.0,
    ),
    MetricDefinition(
      id: 'productive_hours',
      name: 'Productive Hours',
      domain: LifeDomain.productivity,
      unit: 'hours',
      idealMin: 4.0,
      idealMax: 8.0,
      dangerMin: 1.0,
      dangerMax: 12.0,
    ),
    MetricDefinition(
      id: 'calories',
      name: 'Calorie Intake',
      domain: LifeDomain.nutrition,
      unit: 'kcal',
      idealMin: 1800.0,
      idealMax: 2500.0,
      dangerMin: 1200.0,
      dangerMax: 3500.0,
    ),
    MetricDefinition(
      id: 'meditation_minutes',
      name: 'Meditation',
      domain: LifeDomain.mental,
      unit: 'min',
      idealMin: 10.0,
      idealMax: 60.0,
      dangerMin: 0.0,
      dangerMax: 120.0,
    ),
  ];

  /// Data store: metricId → sorted list of data points.
  final Map<String, List<MetricDataPoint>> _data = {};

  /// Custom metric definitions (beyond defaults).
  final List<MetricDefinition> _customMetrics = [];

  /// History of generated alerts.
  final List<DriftAlert> _alertHistory = [];

  // -------------------------------------------------------------------------
  // Data ingestion
  // -------------------------------------------------------------------------

  /// Add a data point for a metric.
  ///
  /// Uses binary search to insert at the correct sorted position
  /// instead of appending and re-sorting the entire list (O(log n)
  /// search + O(n) shift vs O(n log n) sort).
  void addDataPoint(String metricId, DateTime date, double value) {
    final list = _data.putIfAbsent(metricId, () => []);
    final point = MetricDataPoint(date: date, value: value);
    final idx = _lowerBound(list, date);
    list.insert(idx, point);
  }

  /// Bulk import data points.
  void addDataPoints(String metricId, List<MetricDataPoint> points) {
    _data.putIfAbsent(metricId, () => []);
    _data[metricId]!.addAll(points);
    _data[metricId]!.sort((a, b) => a.date.compareTo(b.date));
  }

  /// Register a custom metric definition.
  void registerMetric(MetricDefinition definition) {
    _customMetrics.removeWhere((d) => d.id == definition.id);
    _customMetrics.add(definition);
  }

  /// Get all known metric definitions.
  List<MetricDefinition> get allMetrics => [
        ...defaultMetrics,
        ..._customMetrics,
      ];

  /// Find metric definition by id.
  MetricDefinition? getMetricDef(String id) {
    for (final m in allMetrics) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Get data for a metric within a date range.
  ///
  /// Uses binary search on the sorted data to find the start index,
  /// then scans forward — O(log n + k) where k is the result count,
  /// instead of the previous O(n) full scan.
  List<MetricDataPoint> getDataInRange(
      String metricId, DateTime start, DateTime end) {
    final points = _data[metricId] ?? [];
    if (points.isEmpty) return [];
    final lo = _lowerBound(points, start);
    final result = <MetricDataPoint>[];
    for (int i = lo; i < points.length; i++) {
      if (points[i].date.isAfter(end)) break;
      result.add(points[i]);
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Linear regression
  // -------------------------------------------------------------------------

  /// Compute least-squares linear regression on data points.
  /// x = days since first data point, y = value.
  TrendLine computeTrend(List<MetricDataPoint> points) {
    if (points.length < 2) {
      return const TrendLine(
          slope: 0, intercept: 0, rSquared: 0, sampleSize: 0);
    }

    final origin = points.first.date;
    final n = points.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;

    for (final p in points) {
      final x = p.date.difference(origin).inHours / 24.0;
      final y = p.value;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
      sumY2 += y * y;
    }

    final denom = n * sumX2 - sumX * sumX;
    if (denom.abs() < 1e-10) {
      return TrendLine(
        slope: 0,
        intercept: sumY / n,
        rSquared: 0,
        sampleSize: n,
      );
    }

    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;

    // R-squared
    final meanY = sumY / n;
    double ssRes = 0, ssTot = 0;
    for (final p in points) {
      final x = p.date.difference(origin).inHours / 24.0;
      final predicted = intercept + slope * x;
      ssRes += (p.value - predicted) * (p.value - predicted);
      ssTot += (p.value - meanY) * (p.value - meanY);
    }
    final rSquared = ssTot > 0 ? 1.0 - (ssRes / ssTot) : 0.0;

    return TrendLine(
      slope: slope,
      intercept: intercept,
      rSquared: rSquared,
      sampleSize: n,
    );
  }

  // -------------------------------------------------------------------------
  // Drift analysis
  // -------------------------------------------------------------------------

  /// Compute rolling average for data in a window.
  ///
  /// Uses binary search to find the first element >= windowStart,
  /// then sums forward until past windowEnd — O(log n + k) where
  /// k is the window size, instead of the previous O(n) full scan.
  /// Also accumulates sum in a single pass without allocating a
  /// filtered sub-list.
  double _windowAverage(List<MetricDataPoint> allPoints, DateTime windowStart,
      DateTime windowEnd) {
    if (allPoints.isEmpty) return double.nan;
    final lo = _lowerBound(allPoints, windowStart);
    double sum = 0;
    int count = 0;
    for (int i = lo; i < allPoints.length; i++) {
      if (allPoints[i].date.isAfter(windowEnd)) break;
      sum += allPoints[i].value;
      count++;
    }
    return count == 0 ? double.nan : sum / count;
  }

  /// Classify drift severity based on weekly velocity and metric definition.
  DriftSeverity _classifySeverity(
      MetricDefinition def, double weeklyVelocity, double currentAvg) {
    final range = def.idealMax - def.idealMin;
    if (range <= 0) return DriftSeverity.stable;

    // Normalize velocity to percentage of ideal range per week
    final normalizedVelocity = weeklyVelocity.abs() / range;

    // Determine if moving in bad direction
    final bool movingBadDirection;
    if (def.higherIsBetter) {
      movingBadDirection = weeklyVelocity < 0;
    } else {
      movingBadDirection = weeklyVelocity > 0;
    }

    if (!movingBadDirection) {
      if (normalizedVelocity < 0.02) return DriftSeverity.stable;
      return DriftSeverity.improving;
    }

    // Bad direction — classify by speed
    if (normalizedVelocity < 0.03) return DriftSeverity.stable;
    if (normalizedVelocity < 0.08) return DriftSeverity.drifting;
    if (normalizedVelocity < 0.15) return DriftSeverity.sliding;
    return DriftSeverity.freefall;
  }

  /// Calculate days until metric hits danger zone at current drift rate.
  int? _daysToTippingPoint(
      MetricDefinition def, double currentAvg, double dailySlope) {
    if (dailySlope.abs() < 1e-6) return null;

    final bool driftingToDanger;
    final double dangerBoundary;

    if (def.higherIsBetter) {
      driftingToDanger = dailySlope < 0;
      dangerBoundary = def.dangerMin;
    } else {
      driftingToDanger = dailySlope > 0;
      dangerBoundary = def.dangerMax;
    }

    if (!driftingToDanger) return null;

    // Already past danger?
    if (def.higherIsBetter && currentAvg <= dangerBoundary) return 0;
    if (!def.higherIsBetter && currentAvg >= dangerBoundary) return 0;

    final daysRemaining =
        ((dangerBoundary - currentAvg) / dailySlope).abs();
    return daysRemaining.ceil();
  }

  /// Analyze drift for a single metric.
  MetricDrift? analyzeMetric(String metricId, {DateTime? asOf}) {
    final def = getMetricDef(metricId);
    if (def == null) return null;

    final allPoints = _data[metricId] ?? [];
    if (allPoints.length < 3) return null;

    final now = asOf ?? DateTime.now();

    // Compute windows
    final d7 = now.subtract(const Duration(days: 7));
    final d14 = now.subtract(const Duration(days: 14));
    final d30 = now.subtract(const Duration(days: 30));
    final d60 = now.subtract(const Duration(days: 60));
    final d90 = now.subtract(const Duration(days: 90));

    final points7d = getDataInRange(metricId, d7, now);
    final points30d = getDataInRange(metricId, d30, now);
    final points90d = getDataInRange(metricId, d90, now);

    final trend7d = computeTrend(points7d);
    final trend30d = computeTrend(points30d);
    final trend90d = computeTrend(points90d);

    final currentAvg = _windowAverage(allPoints, d7, now);
    final weekAgoAvg = _windowAverage(allPoints, d14, d7);
    final monthAgoAvg = _windowAverage(allPoints, d60, d30);

    if (currentAvg.isNaN) return null;

    // Weekly velocity from 30-day trend
    final weeklyVelocity = trend30d.slope * 7.0;

    // Monthly change percent
    final monthlyChangePercent = monthAgoAvg.isNaN || monthAgoAvg.abs() < 0.01
        ? 0.0
        : ((currentAvg - monthAgoAvg) / monthAgoAvg) * 100.0;

    final severity = _classifySeverity(def, weeklyVelocity, currentAvg);
    final tippingPoint =
        _daysToTippingPoint(def, currentAvg, trend30d.slope);

    return MetricDrift(
      definition: def,
      trend7d: trend7d,
      trend30d: trend30d,
      trend90d: trend90d,
      currentAvg: currentAvg,
      weekAgoAvg: weekAgoAvg.isNaN ? currentAvg : weekAgoAvg,
      monthAgoAvg: monthAgoAvg.isNaN ? currentAvg : monthAgoAvg,
      severity: severity,
      weeklyVelocity: weeklyVelocity,
      daysToTippingPoint: tippingPoint,
      monthlyChangePercent: monthlyChangePercent,
    );
  }

  // -------------------------------------------------------------------------
  // Cross-metric correlation
  // -------------------------------------------------------------------------

  /// Compute Pearson correlation between two metrics' daily values.
  ///
  /// Uses integer date keys (YYYYMMDD) for same-day alignment instead
  /// of formatted strings — avoids per-point string allocations and
  /// is consistent with HeatmapService / CorrelationAnalyzerService.
  DriftCorrelation? computeDriftCorrelation(
      String metricA, String metricB, {DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final pointsA = getDataInRange(metricA, start, now);
    final pointsB = getDataInRange(metricB, start, now);

    // Align by date (same-day matching) using integer keys
    final mapA = <int, double>{};
    for (final p in pointsA) {
      mapA[_dateKeyInt(p.date)] = p.value;
    }

    final List<double> valsA = [], valsB = [];
    for (final p in pointsB) {
      final key = _dateKeyInt(p.date);
      final valA = mapA[key];
      if (valA != null) {
        valsA.add(valA);
        valsB.add(p.value);
      }
    }

    if (valsA.length < 5) return null;

    final n = valsA.length;
    final meanA = valsA.reduce((a, b) => a + b) / n;
    final meanB = valsB.reduce((a, b) => a + b) / n;

    double cov = 0, varA = 0, varB = 0;
    for (int i = 0; i < n; i++) {
      final da = valsA[i] - meanA;
      final db = valsB[i] - meanB;
      cov += da * db;
      varA += da * da;
      varB += db * db;
    }

    if (varA < 1e-10 || varB < 1e-10) return null;
    final r = cov / (sqrt(varA) * sqrt(varB));

    if (r.abs() < 0.3) return null;

    final defA = getMetricDef(metricA);
    final defB = getMetricDef(metricB);
    final nameA = defA?.name ?? metricA;
    final nameB = defB?.name ?? metricB;

    String insight;
    if (r > 0.7) {
      insight = '$nameA and $nameB are strongly moving together — '
          'improving one may help the other.';
    } else if (r > 0.3) {
      insight = '$nameA and $nameB show moderate co-movement.';
    } else if (r < -0.7) {
      insight = '$nameA and $nameB are inversely linked — '
          'as one rises, the other falls.';
    } else {
      insight = '$nameA and $nameB show moderate inverse correlation.';
    }

    return DriftCorrelation(
      metricA: metricA,
      metricB: metricB,
      correlation: r,
      insight: insight,
    );
  }

  // -------------------------------------------------------------------------
  // Alert generation
  // -------------------------------------------------------------------------

  /// Generate alerts from drift analysis.
  List<DriftAlert> _generateAlerts(List<MetricDrift> drifts) {
    final alerts = <DriftAlert>[];
    final now = DateTime.now();

    for (final drift in drifts) {
      // Tipping point warning
      if (drift.daysToTippingPoint != null &&
          drift.daysToTippingPoint! <= 30) {
        final urgency = drift.daysToTippingPoint! <= 7
            ? AlertUrgency.critical
            : drift.daysToTippingPoint! <= 14
                ? AlertUrgency.urgent
                : AlertUrgency.warning;

        alerts.add(DriftAlert(
          metricId: drift.definition.id,
          title: '${drift.definition.name} approaching danger zone',
          message:
              'At the current rate of ${drift.weeklyVelocity.toStringAsFixed(1)} '
              '${drift.definition.unit}/week, ${drift.definition.name} will hit '
              'dangerous levels in ~${drift.daysToTippingPoint} days.',
          urgency: urgency,
          suggestion: _getRecoverySuggestion(drift),
          generated: now,
        ));
      }

      // Severity-based alerts
      if (drift.severity == DriftSeverity.sliding ||
          drift.severity == DriftSeverity.freefall) {
        alerts.add(DriftAlert(
          metricId: drift.definition.id,
          title:
              '${drift.severity.emoji} ${drift.definition.name} is ${drift.severity.label.toLowerCase()}',
          message:
              '${drift.definition.name} has changed ${drift.monthlyChangePercent.toStringAsFixed(1)}% '
              'over the past month (current avg: ${drift.currentAvg.toStringAsFixed(1)} '
              '${drift.definition.unit}).',
          urgency: drift.severity == DriftSeverity.freefall
              ? AlertUrgency.critical
              : AlertUrgency.urgent,
          suggestion: _getRecoverySuggestion(drift),
          generated: now,
        ));
      }

      // Subtle drift alert (the whole point — catching slow changes)
      if (drift.severity == DriftSeverity.drifting &&
          drift.trend30d.rSquared > 0.3) {
        alerts.add(DriftAlert(
          metricId: drift.definition.id,
          title:
              '👀 Slow drift detected in ${drift.definition.name}',
          message:
              '${drift.definition.name} is gradually shifting at '
              '${drift.weeklyVelocity.toStringAsFixed(2)} ${drift.definition.unit}/week. '
              'You might not notice yet, but the trend is consistent '
              '(R²=${drift.trend30d.rSquared.toStringAsFixed(2)}).',
          urgency: AlertUrgency.watch,
          suggestion: _getRecoverySuggestion(drift),
          generated: now,
        ));
      }
    }

    // Multi-metric slide alert
    final slidingCount =
        drifts.where((d) => d.severity.priority >= 3).length;
    if (slidingCount >= 3) {
      final names = drifts
          .where((d) => d.severity.priority >= 3)
          .map((d) => d.definition.name)
          .join(', ');
      alerts.add(DriftAlert(
        metricId: '_multi',
        title: '🚨 Multiple lifestyle areas declining',
        message:
            '$slidingCount metrics are sliding simultaneously: $names. '
            'This pattern often indicates burnout or a major life disruption.',
        urgency: AlertUrgency.critical,
        suggestion:
            'Focus on the basics: sleep, nutrition, and one social connection. '
            'Don\'t try to fix everything at once. Pick the metric that\'s '
            'easiest to improve and start there.',
        generated: now,
      ));
    }

    return alerts;
  }

  /// Get a recovery suggestion based on the drifting metric.
  String _getRecoverySuggestion(MetricDrift drift) {
    switch (drift.definition.id) {
      case 'sleep_hours':
        return 'Try setting a consistent bedtime alarm. Even 15 minutes '
            'earlier each night can reverse the drift within a week.';
      case 'mood_score':
        return 'Small mood drifts often trace back to sleep or social '
            'isolation. Check those metrics too. A 10-minute walk or '
            'calling a friend can shift the trajectory.';
      case 'exercise_minutes':
        return 'Start with just 10 minutes. The hardest part is starting. '
            'Pair exercise with something you enjoy (podcast, music, friend).';
      case 'water_ml':
        return 'Keep a water bottle visible at your desk. Set 3 reminder '
            'checkpoints: morning, after lunch, mid-afternoon.';
      case 'screen_hours':
        return 'Try the 20-20-20 rule: every 20 minutes, look at something '
            '20 feet away for 20 seconds. Set a daily screen budget.';
      case 'spending':
        return 'Review your last 7 days of purchases. Often one category '
            '(dining out, subscriptions, impulse buys) drives most drift.';
      case 'social_interactions':
        return 'Social drift is sneaky. Schedule one recurring social '
            'commitment this week — even a brief coffee chat counts.';
      case 'productive_hours':
        return 'Block 2 hours of deep work on your calendar tomorrow. '
            'Protect it like a meeting. Eliminate one distraction source.';
      case 'calories':
        return 'Track just one meal a day to rebuild awareness. '
            'Meal prep can help normalize intake when things drift.';
      case 'meditation_minutes':
        return 'Even 5 minutes counts. Attach meditation to an existing '
            'habit (after brushing teeth, before bed) to rebuild the streak.';
      default:
        return 'Review the trend and set a small, specific goal for this '
            'week. Consistency beats intensity for reversing drift.';
    }
  }

  // -------------------------------------------------------------------------
  // Lifestyle snapshot
  // -------------------------------------------------------------------------

  /// Generate a comparative lifestyle snapshot.
  LifestyleSnapshot generateSnapshot({DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final currentWeek = <String, double>{};
    final lastWeek = <String, double>{};
    final lastMonth = <String, double>{};
    final threeMonthsAgo = <String, double>{};

    int improving = 0, stable = 0, drifting = 0;

    for (final metricId in _data.keys) {
      final allPoints = _data[metricId]!;
      if (allPoints.isEmpty) continue;

      final cw = _windowAverage(
          allPoints, now.subtract(const Duration(days: 7)), now);
      final lw = _windowAverage(allPoints,
          now.subtract(const Duration(days: 14)),
          now.subtract(const Duration(days: 7)));
      final lm = _windowAverage(allPoints,
          now.subtract(const Duration(days: 60)),
          now.subtract(const Duration(days: 30)));
      final tm = _windowAverage(allPoints,
          now.subtract(const Duration(days: 97)),
          now.subtract(const Duration(days: 83)));

      if (!cw.isNaN) currentWeek[metricId] = cw;
      if (!lw.isNaN) lastWeek[metricId] = lw;
      if (!lm.isNaN) lastMonth[metricId] = lm;
      if (!tm.isNaN) threeMonthsAgo[metricId] = tm;

      // Classify direction
      final def = getMetricDef(metricId);
      if (def != null && !cw.isNaN && !lm.isNaN) {
        final change = cw - lm;
        final goodDirection =
            def.higherIsBetter ? change > 0 : change < 0;
        final range = def.idealMax - def.idealMin;
        final normalized = range > 0 ? change.abs() / range : 0.0;

        if (normalized < 0.05) {
          stable++;
        } else if (goodDirection) {
          improving++;
        } else {
          drifting++;
        }
      }
    }

    // Overall health score: 0–100
    final total = improving + stable + drifting;
    final score = total > 0
        ? ((improving * 100.0 + stable * 70.0 + drifting * 20.0) / total)
            .clamp(0.0, 100.0)
        : 50.0;

    return LifestyleSnapshot(
      currentWeek: currentWeek,
      lastWeek: lastWeek,
      lastMonth: lastMonth,
      threeMonthsAgo: threeMonthsAgo,
      overallHealthScore: score,
      metricsImproving: improving,
      metricsStable: stable,
      metricsDrifting: drifting,
    );
  }

  // -------------------------------------------------------------------------
  // Full report
  // -------------------------------------------------------------------------

  /// Run full drift analysis across all tracked metrics.
  DriftReport generateReport({DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final drifts = <MetricDrift>[];

    for (final metricId in _data.keys) {
      final drift = analyzeMetric(metricId, asOf: now);
      if (drift != null) drifts.add(drift);
    }

    // Sort: worst drift first
    drifts.sort((a, b) => b.severity.priority.compareTo(a.severity.priority));

    // Cross-metric correlations (only between drifting metrics)
    final driftingIds = drifts
        .where((d) => d.severity.priority >= 2)
        .map((d) => d.definition.id)
        .toList();
    final correlations = <DriftCorrelation>[];
    for (int i = 0; i < driftingIds.length; i++) {
      for (int j = i + 1; j < driftingIds.length; j++) {
        final corr = computeDriftCorrelation(
            driftingIds[i], driftingIds[j],
            asOf: now);
        if (corr != null) correlations.add(corr);
      }
    }

    correlations
        .sort((a, b) => b.correlation.abs().compareTo(a.correlation.abs()));

    final alerts = _generateAlerts(drifts);
    _alertHistory.addAll(alerts);

    final snapshot = generateSnapshot(asOf: now);

    // Stability score: inverse of average drift severity
    final stabilityScore = drifts.isEmpty
        ? 100.0
        : (100.0 -
                (drifts.map((d) => d.severity.priority).reduce((a, b) => a + b) /
                    drifts.length *
                    25.0))
            .clamp(0.0, 100.0);

    return DriftReport(
      generatedAt: now,
      drifts: drifts,
      correlations: correlations,
      alerts: alerts,
      snapshot: snapshot,
      lifestyleStabilityScore: stabilityScore,
    );
  }

  // -------------------------------------------------------------------------
  // Persistence
  // -------------------------------------------------------------------------

  /// Export all data to JSON.
  String exportToJson() {
    final dataMap = <String, dynamic>{};
    for (final entry in _data.entries) {
      dataMap[entry.key] =
          entry.value.map((p) => p.toJson()).toList();
    }
    return jsonEncode({
      'data': dataMap,
      'customMetrics': _customMetrics.map((m) => m.toJson()).toList(),
      'alertHistory': _alertHistory.map((a) => a.toJson()).toList(),
    });
  }

  /// Import data from JSON.
  void importFromJson(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;

      _data.clear();
      final dataMap = map['data'] as Map<String, dynamic>? ?? {};
      for (final entry in dataMap.entries) {
        _data[entry.key] = (entry.value as List)
            .map((p) =>
                MetricDataPoint.fromJson(p as Map<String, dynamic>))
            .toList();
      }

      _customMetrics.clear();
      final customs = map['customMetrics'] as List? ?? [];
      for (final c in customs) {
        _customMetrics
            .add(MetricDefinition.fromJson(c as Map<String, dynamic>));
      }
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // Summary
  // -------------------------------------------------------------------------

  /// Get a human-readable summary of current drift status.
  String getSummary({DateTime? asOf}) {
    final report = generateReport(asOf: asOf);
    final buf = StringBuffer();

    buf.writeln('🔍 PERSONAL DRIFT REPORT');
    buf.writeln('═══════════════════════════════════════');
    buf.writeln(
        'Lifestyle Stability Score: ${report.lifestyleStabilityScore.toStringAsFixed(0)}/100');
    buf.writeln(
        'Snapshot: ${report.snapshot.metricsImproving}↑ improving, '
        '${report.snapshot.metricsStable}→ stable, '
        '${report.snapshot.metricsDrifting}↓ drifting');
    buf.writeln();

    if (report.alerts.isNotEmpty) {
      buf.writeln('⚡ ALERTS (${report.alerts.length})');
      buf.writeln('───────────────────────────────────────');
      for (final alert in report.alerts) {
        buf.writeln('${alert.urgency.emoji} ${alert.title}');
        buf.writeln('  ${alert.message}');
        buf.writeln('  💡 ${alert.suggestion}');
        buf.writeln();
      }
    }

    buf.writeln('📊 METRIC DRIFT STATUS');
    buf.writeln('───────────────────────────────────────');
    for (final drift in report.drifts) {
      final tp = drift.daysToTippingPoint != null
          ? ' (danger in ~${drift.daysToTippingPoint}d)'
          : '';
      buf.writeln(
          '${drift.severity.emoji} ${drift.definition.name}: '
          '${drift.currentAvg.toStringAsFixed(1)} ${drift.definition.unit} '
          '[${drift.weeklyVelocity >= 0 ? "+" : ""}${drift.weeklyVelocity.toStringAsFixed(2)}/wk]'
          '$tp');
    }

    if (report.correlations.isNotEmpty) {
      buf.writeln();
      buf.writeln('🔗 DRIFT CORRELATIONS');
      buf.writeln('───────────────────────────────────────');
      for (final corr in report.correlations) {
        buf.writeln(
            '  ${corr.metricA} ↔ ${corr.metricB}: '
            'r=${corr.correlation.toStringAsFixed(2)}');
        buf.writeln('  ${corr.insight}');
      }
    }

    return buf.toString();
  }

  /// Number of metrics currently being tracked.
  int get trackedMetricCount => _data.length;

  /// Number of total data points.
  int get totalDataPoints =>
      _data.values.fold(0, (sum, pts) => sum + pts.length);

  /// Get alert history.
  List<DriftAlert> get alertHistory => List.unmodifiable(_alertHistory);

  // -------------------------------------------------------------------------
  // Binary search helpers
  // -------------------------------------------------------------------------

  /// Integer date key (YYYYMMDD) — avoids string allocation for hashing.
  static int _dateKeyInt(DateTime dt) =>
      dt.year * 10000 + dt.month * 100 + dt.day;

  /// Returns the index of the first element whose date is >= [target].
  ///
  /// Runs in O(log n) on the already-sorted data list, replacing the
  /// previous O(n) linear scans in [getDataInRange], [_windowAverage],
  /// and the O(n log n) re-sort in [addDataPoint].
  static int _lowerBound(List<MetricDataPoint> points, DateTime target) {
    int lo = 0, hi = points.length;
    while (lo < hi) {
      final mid = (lo + hi) >>> 1;
      if (points[mid].date.isBefore(target)) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}
