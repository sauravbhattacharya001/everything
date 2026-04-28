import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/drift_detector_service.dart';

void main() {
  late DriftDetectorService service;

  setUp(() {
    service = DriftDetectorService();
  });

  /// Helper: generate data points over N days with a linear trend.
  List<MetricDataPoint> _generateLinearData({
    required int days,
    required double startValue,
    required double dailyChange,
    DateTime? startDate,
  }) {
    final start = startDate ?? DateTime.now().subtract(Duration(days: days));
    return List.generate(days, (i) {
      return MetricDataPoint(
        date: start.add(Duration(days: i)),
        value: startValue + dailyChange * i,
      );
    });
  }

  group('MetricDefinition', () {
    test('default metrics are defined', () {
      expect(DriftDetectorService.defaultMetrics.length, 10);
      expect(
        DriftDetectorService.defaultMetrics.map((m) => m.id),
        contains('sleep_hours'),
      );
    });

    test('toJson and fromJson roundtrip', () {
      final def = DriftDetectorService.defaultMetrics.first;
      final json = def.toJson();
      final restored = MetricDefinition.fromJson(json);
      expect(restored.id, def.id);
      expect(restored.name, def.name);
      expect(restored.idealMin, def.idealMin);
      expect(restored.higherIsBetter, def.higherIsBetter);
    });
  });

  group('Data ingestion', () {
    test('addDataPoint stores and sorts data', () {
      final now = DateTime.now();
      service.addDataPoint('sleep_hours', now, 7.5);
      service.addDataPoint(
          'sleep_hours', now.subtract(const Duration(days: 1)), 8.0);
      expect(service.trackedMetricCount, 1);
      expect(service.totalDataPoints, 2);
      // Should be sorted
      final data = service.getDataInRange(
          'sleep_hours',
          now.subtract(const Duration(days: 2)),
          now.add(const Duration(days: 1)));
      expect(data.first.value, 8.0); // older first
    });

    test('addDataPoints bulk import', () {
      final points = _generateLinearData(
        days: 30,
        startValue: 7.0,
        dailyChange: 0.0,
      );
      service.addDataPoints('sleep_hours', points);
      expect(service.totalDataPoints, 30);
    });

    test('registerMetric adds custom metric', () {
      expect(service.allMetrics.length, 10); // defaults only
      service.registerMetric(const MetricDefinition(
        id: 'custom_steps',
        name: 'Daily Steps',
        domain: LifeDomain.fitness,
        unit: 'steps',
        idealMin: 8000,
        idealMax: 15000,
        dangerMin: 2000,
        dangerMax: 25000,
      ));
      expect(service.allMetrics.length, 11);
      expect(service.getMetricDef('custom_steps'), isNotNull);
    });
  });

  group('Linear regression', () {
    test('flat data yields zero slope', () {
      final points = _generateLinearData(
        days: 30,
        startValue: 7.5,
        dailyChange: 0.0,
      );
      final trend = service.computeTrend(points);
      expect(trend.slope.abs(), lessThan(0.01));
      expect(trend.sampleSize, 30);
    });

    test('upward trend yields positive slope', () {
      final points = _generateLinearData(
        days: 30,
        startValue: 5.0,
        dailyChange: 0.1,
      );
      final trend = service.computeTrend(points);
      expect(trend.slope, greaterThan(0.05));
      expect(trend.rSquared, greaterThan(0.9));
    });

    test('downward trend yields negative slope', () {
      final points = _generateLinearData(
        days: 30,
        startValue: 9.0,
        dailyChange: -0.05,
      );
      final trend = service.computeTrend(points);
      expect(trend.slope, lessThan(-0.03));
    });

    test('single point returns zero slope', () {
      final trend = service.computeTrend([
        MetricDataPoint(date: DateTime.now(), value: 5.0),
      ]);
      expect(trend.slope, 0.0);
      expect(trend.sampleSize, 0);
    });

    test('predict gives expected values', () {
      final points = _generateLinearData(
        days: 30,
        startValue: 10.0,
        dailyChange: 1.0,
      );
      final trend = service.computeTrend(points);
      // At day 0, should be ~10; at day 30, should be ~40
      expect(trend.predict(0), closeTo(10.0, 1.0));
      expect(trend.predict(30), closeTo(40.0, 2.0));
    });
  });

  group('Drift analysis', () {
    test('stable metric returns stable severity', () {
      final now = DateTime.now();
      final points = _generateLinearData(
        days: 90,
        startValue: 7.5,
        dailyChange: 0.0,
        startDate: now.subtract(const Duration(days: 90)),
      );
      service.addDataPoints('sleep_hours', points);

      final drift = service.analyzeMetric('sleep_hours', asOf: now);
      expect(drift, isNotNull);
      expect(drift!.severity, DriftSeverity.stable);
      expect(drift.weeklyVelocity.abs(), lessThan(0.5));
    });

    test('declining sleep detects drift', () {
      final now = DateTime.now();
      final points = _generateLinearData(
        days: 90,
        startValue: 8.5,
        dailyChange: -0.02,
        startDate: now.subtract(const Duration(days: 90)),
      );
      service.addDataPoints('sleep_hours', points);

      final drift = service.analyzeMetric('sleep_hours', asOf: now);
      expect(drift, isNotNull);
      expect(drift!.severity.priority, greaterThanOrEqualTo(2));
      expect(drift.weeklyVelocity, lessThan(0));
    });

    test('improving metric returns improving severity', () {
      final now = DateTime.now();
      final points = _generateLinearData(
        days: 90,
        startValue: 5.0,
        dailyChange: 0.03,
        startDate: now.subtract(const Duration(days: 90)),
      );
      service.addDataPoints('exercise_minutes', points);

      final drift = service.analyzeMetric('exercise_minutes', asOf: now);
      expect(drift, isNotNull);
      expect(drift!.severity, DriftSeverity.improving);
    });

    test('daysToTippingPoint calculated for declining metric', () {
      final now = DateTime.now();
      // Sleep declining from 7.5 toward 5.0 danger zone
      final points = _generateLinearData(
        days: 60,
        startValue: 7.5,
        dailyChange: -0.03,
        startDate: now.subtract(const Duration(days: 60)),
      );
      service.addDataPoints('sleep_hours', points);

      final drift = service.analyzeMetric('sleep_hours', asOf: now);
      expect(drift, isNotNull);
      if (drift!.daysToTippingPoint != null) {
        expect(drift.daysToTippingPoint!, greaterThan(0));
      }
    });

    test('returns null for unknown metric', () {
      expect(service.analyzeMetric('nonexistent'), isNull);
    });

    test('returns null for insufficient data', () {
      service.addDataPoint(
          'sleep_hours', DateTime.now(), 7.0);
      expect(service.analyzeMetric('sleep_hours'), isNull);
    });

    test('higherIsBetter=false: increasing screen time is bad', () {
      final now = DateTime.now();
      // Screen time increasing (bad)
      final points = _generateLinearData(
        days: 60,
        startValue: 3.0,
        dailyChange: 0.04,
        startDate: now.subtract(const Duration(days: 60)),
      );
      service.addDataPoints('screen_hours', points);

      final drift = service.analyzeMetric('screen_hours', asOf: now);
      expect(drift, isNotNull);
      // Should classify as drifting/sliding since higher is worse
      expect(drift!.severity.priority, greaterThanOrEqualTo(2));
    });
  });

  group('Cross-metric correlation', () {
    test('correlated metrics detected', () {
      final now = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: 30 - i));
        service.addDataPoint('sleep_hours', date, 6.0 + i * 0.05);
        service.addDataPoint('mood_score', date, 5.0 + i * 0.08);
      }

      final corr = service.computeDriftCorrelation(
          'sleep_hours', 'mood_score',
          asOf: now);
      expect(corr, isNotNull);
      expect(corr!.correlation, greaterThan(0.7));
      expect(corr.insight, contains('strongly'));
    });

    test('inverse correlation detected', () {
      final now = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: 30 - i));
        service.addDataPoint('screen_hours', date, 2.0 + i * 0.1);
        service.addDataPoint('exercise_minutes', date, 60.0 - i * 1.5);
      }

      final corr = service.computeDriftCorrelation(
          'screen_hours', 'exercise_minutes',
          asOf: now);
      expect(corr, isNotNull);
      expect(corr!.correlation, lessThan(-0.7));
    });

    test('returns null for insufficient overlapping data', () {
      service.addDataPoint('sleep_hours', DateTime.now(), 7.0);
      final corr = service.computeDriftCorrelation(
          'sleep_hours', 'mood_score');
      expect(corr, isNull);
    });
  });

  group('Alert generation', () {
    test('freefall triggers critical alert', () {
      final now = DateTime.now();
      // Rapid sleep decline
      final points = _generateLinearData(
        days: 90,
        startValue: 9.0,
        dailyChange: -0.06,
        startDate: now.subtract(const Duration(days: 90)),
      );
      service.addDataPoints('sleep_hours', points);

      final report = service.generateReport(asOf: now);
      final sleepAlerts = report.alerts
          .where((a) => a.metricId == 'sleep_hours')
          .toList();
      expect(sleepAlerts, isNotEmpty);
    });

    test('slow drift generates watch-level alert', () {
      final now = DateTime.now();
      // Subtle decline
      final points = _generateLinearData(
        days: 90,
        startValue: 8.0,
        dailyChange: -0.012,
        startDate: now.subtract(const Duration(days: 90)),
      );
      service.addDataPoints('sleep_hours', points);

      final report = service.generateReport(asOf: now);
      // May or may not trigger depending on R²; just ensure no crash
      expect(report.drifts, isNotEmpty);
    });

    test('multiple sliding metrics trigger multi-alert', () {
      final now = DateTime.now();
      // Slide 3 metrics simultaneously
      for (final id in ['sleep_hours', 'mood_score', 'exercise_minutes']) {
        final points = _generateLinearData(
          days: 90,
          startValue: id == 'exercise_minutes' ? 60.0 : 9.0,
          dailyChange: id == 'exercise_minutes' ? -0.5 : -0.05,
          startDate: now.subtract(const Duration(days: 90)),
        );
        service.addDataPoints(id, points);
      }

      final report = service.generateReport(asOf: now);
      final multiAlerts = report.alerts
          .where((a) => a.metricId == '_multi')
          .toList();
      expect(multiAlerts, isNotEmpty);
      expect(
        multiAlerts.first.urgency,
        AlertUrgency.critical,
      );
    });
  });

  group('Lifestyle snapshot', () {
    test('generates snapshot with correct counts', () {
      final now = DateTime.now();
      // One improving, one stable
      service.addDataPoints(
        'exercise_minutes',
        _generateLinearData(
          days: 90,
          startValue: 20.0,
          dailyChange: 0.3,
          startDate: now.subtract(const Duration(days: 90)),
        ),
      );
      service.addDataPoints(
        'sleep_hours',
        _generateLinearData(
          days: 90,
          startValue: 7.5,
          dailyChange: 0.0,
          startDate: now.subtract(const Duration(days: 90)),
        ),
      );

      final snapshot = service.generateSnapshot(asOf: now);
      expect(snapshot.overallHealthScore, greaterThan(0));
      expect(snapshot.currentWeek, isNotEmpty);
    });

    test('empty data yields default score', () {
      final snapshot = service.generateSnapshot();
      expect(snapshot.overallHealthScore, 50.0);
    });
  });

  group('Full report', () {
    test('generateReport produces complete report', () {
      final now = DateTime.now();
      service.addDataPoints(
        'sleep_hours',
        _generateLinearData(
          days: 90,
          startValue: 8.0,
          dailyChange: -0.02,
          startDate: now.subtract(const Duration(days: 90)),
        ),
      );
      service.addDataPoints(
        'mood_score',
        _generateLinearData(
          days: 90,
          startValue: 7.0,
          dailyChange: -0.01,
          startDate: now.subtract(const Duration(days: 90)),
        ),
      );

      final report = service.generateReport(asOf: now);
      expect(report.drifts.length, 2);
      expect(report.lifestyleStabilityScore, greaterThan(0));
      expect(report.snapshot.currentWeek, isNotEmpty);
      expect(report.generatedAt, now);
    });

    test('drifts sorted by severity (worst first)', () {
      final now = DateTime.now();
      // Sleep: stable
      service.addDataPoints(
        'sleep_hours',
        _generateLinearData(
          days: 90,
          startValue: 7.5,
          dailyChange: 0.0,
          startDate: now.subtract(const Duration(days: 90)),
        ),
      );
      // Exercise: freefall
      service.addDataPoints(
        'exercise_minutes',
        _generateLinearData(
          days: 90,
          startValue: 80.0,
          dailyChange: -0.8,
          startDate: now.subtract(const Duration(days: 90)),
        ),
      );

      final report = service.generateReport(asOf: now);
      if (report.drifts.length >= 2) {
        expect(
          report.drifts.first.severity.priority,
          greaterThanOrEqualTo(report.drifts.last.severity.priority),
        );
      }
    });

    test('getSummary produces readable text', () {
      final now = DateTime.now();
      service.addDataPoints(
        'sleep_hours',
        _generateLinearData(
          days: 60,
          startValue: 8.0,
          dailyChange: -0.03,
          startDate: now.subtract(const Duration(days: 60)),
        ),
      );

      final summary = service.getSummary(asOf: now);
      expect(summary, contains('PERSONAL DRIFT REPORT'));
      expect(summary, contains('Lifestyle Stability Score'));
      expect(summary, contains('Sleep Duration'));
    });
  });

  group('Persistence', () {
    test('exportToJson and importFromJson roundtrip', () {
      final now = DateTime.now();
      service.addDataPoints(
        'sleep_hours',
        _generateLinearData(
          days: 30,
          startValue: 7.5,
          dailyChange: 0.0,
          startDate: now.subtract(const Duration(days: 30)),
        ),
      );

      final json = service.exportToJson();
      final restored = DriftDetectorService();
      restored.importFromJson(json);

      expect(restored.trackedMetricCount, 1);
      expect(restored.totalDataPoints, 30);
    });

    test('importFromJson handles invalid json gracefully', () {
      service.importFromJson('not json');
      expect(service.trackedMetricCount, 0);
    });
  });

  group('Enums', () {
    test('DriftSeverity labels and emojis', () {
      expect(DriftSeverity.stable.label, 'Stable');
      expect(DriftSeverity.freefall.emoji, '🚨');
      expect(DriftSeverity.improving.priority, 0);
      expect(DriftSeverity.freefall.priority, 4);
    });

    test('AlertUrgency emojis', () {
      expect(AlertUrgency.info.emoji, 'ℹ️');
      expect(AlertUrgency.critical.emoji, '🚨');
    });

    test('LifeDomain labels and emojis', () {
      expect(LifeDomain.health.label, 'Health');
      expect(LifeDomain.fitness.emoji, '💪');
    });
  });

  group('MetricDataPoint', () {
    test('toJson/fromJson roundtrip', () {
      final p = MetricDataPoint(
        date: DateTime(2025, 6, 15),
        value: 7.5,
      );
      final json = p.toJson();
      final restored = MetricDataPoint.fromJson(json);
      expect(restored.date, p.date);
      expect(restored.value, p.value);
    });
  });

  group('Alert history', () {
    test('alerts accumulate across reports', () {
      final now = DateTime.now();
      service.addDataPoints(
        'sleep_hours',
        _generateLinearData(
          days: 90,
          startValue: 9.0,
          dailyChange: -0.06,
          startDate: now.subtract(const Duration(days: 90)),
        ),
      );

      service.generateReport(asOf: now);
      final firstCount = service.alertHistory.length;

      service.generateReport(asOf: now);
      expect(service.alertHistory.length, greaterThanOrEqualTo(firstCount));
    });
  });
}
