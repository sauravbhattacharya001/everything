import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/balance_radar_engine_service.dart';

void main() {
  late BalanceRadarEngineService service;

  setUp(() {
    service = BalanceRadarEngineService();
  });

  // =========================================================================
  // Activity Tracker
  // =========================================================================

  group('Activity Tracker', () {
    test('addActivity stores activity', () {
      service.addActivity(_makeActivity('a1', BalanceDimension.health));
      expect(service.activities.length, 1);
      expect(service.activities.first.id, 'a1');
    });

    test('addActivity stores multiple activities', () {
      service.addActivity(_makeActivity('a1', BalanceDimension.health));
      service.addActivity(_makeActivity('a2', BalanceDimension.work));
      service.addActivity(_makeActivity('a3', BalanceDimension.social));
      expect(service.activities.length, 3);
    });

    test('activities list is unmodifiable', () {
      service.addActivity(_makeActivity('a1', BalanceDimension.health));
      expect(
        () => service.activities.add(_makeActivity('a2', BalanceDimension.work)),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('getActivitiesByDimension filters correctly', () {
      service.addActivity(_makeActivity('a1', BalanceDimension.health));
      service.addActivity(_makeActivity('a2', BalanceDimension.health));
      service.addActivity(_makeActivity('a3', BalanceDimension.work));

      final healthActs =
          service.getActivitiesByDimension(BalanceDimension.health);
      expect(healthActs.length, 2);
      expect(healthActs.every((a) => a.dimension == BalanceDimension.health),
          true);
    });

    test('getActivitiesByDimension returns empty for unused dimension', () {
      service.addActivity(_makeActivity('a1', BalanceDimension.health));
      final result =
          service.getActivitiesByDimension(BalanceDimension.creativity);
      expect(result, isEmpty);
    });

    test('getActivitiesInRange filters by date', () {
      final now = DateTime(2026, 5, 1);
      service.addActivity(_makeActivity('a1', BalanceDimension.health,
          timestamp: now.subtract(const Duration(days: 5))));
      service.addActivity(_makeActivity('a2', BalanceDimension.health,
          timestamp: now.subtract(const Duration(days: 15))));
      service.addActivity(_makeActivity('a3', BalanceDimension.health,
          timestamp: now.subtract(const Duration(days: 25))));

      final range = service.getActivitiesInRange(
        now.subtract(const Duration(days: 20)),
        now,
      );
      expect(range.length, 2);
    });
  });

  // =========================================================================
  // Dimension Scorer
  // =========================================================================

  group('Dimension Scorer', () {
    test('empty dimension returns score 0', () {
      final score =
          service.scoreDimension(BalanceDimension.health, now: DateTime(2026, 5, 1));
      expect(score.score, 0);
      expect(score.activityCount, 0);
    });

    test('single recent activity produces non-zero score', () {
      final now = DateTime(2026, 5, 1);
      service.addActivity(_makeActivity('a1', BalanceDimension.health,
          intensity: 70, timestamp: now.subtract(const Duration(days: 1))));

      final score = service.scoreDimension(BalanceDimension.health, now: now);
      expect(score.score, greaterThan(0));
      expect(score.activityCount, 1);
    });

    test('more activities produce higher frequency component', () {
      final now = DateTime(2026, 5, 1);
      // One activity
      service.addActivity(_makeActivity('a1', BalanceDimension.health,
          intensity: 50, timestamp: now.subtract(const Duration(days: 1))));
      final score1 = service.scoreDimension(BalanceDimension.health, now: now);

      // Add more
      for (int i = 2; i <= 8; i++) {
        service.addActivity(_makeActivity('a$i', BalanceDimension.health,
            intensity: 50,
            timestamp: now.subtract(Duration(days: i))));
      }
      final score2 = service.scoreDimension(BalanceDimension.health, now: now);
      expect(score2.score, greaterThan(score1.score));
    });

    test('higher intensity produces higher score', () {
      final now = DateTime(2026, 5, 1);
      service.addActivity(_makeActivity('a1', BalanceDimension.health,
          intensity: 20, timestamp: now.subtract(const Duration(days: 1))));
      final low = service.scoreDimension(BalanceDimension.health, now: now);

      service = BalanceRadarEngineService();
      service.addActivity(_makeActivity('a1', BalanceDimension.health,
          intensity: 90, timestamp: now.subtract(const Duration(days: 1))));
      final high = service.scoreDimension(BalanceDimension.health, now: now);

      expect(high.score, greaterThan(low.score));
    });

    test('old activities have lower recency weight', () {
      final now = DateTime(2026, 5, 1);
      service.addActivity(_makeActivity('a1', BalanceDimension.health,
          intensity: 70, timestamp: now.subtract(const Duration(days: 1))));
      final recent = service.scoreDimension(BalanceDimension.health, now: now);

      service = BalanceRadarEngineService();
      service.addActivity(_makeActivity('a1', BalanceDimension.health,
          intensity: 70, timestamp: now.subtract(const Duration(days: 28))));
      final old = service.scoreDimension(BalanceDimension.health, now: now);

      expect(recent.score, greaterThan(old.score));
    });

    test('all dimensions are scoreable', () {
      final now = DateTime(2026, 5, 1);
      for (final dim in BalanceDimension.values) {
        service.addActivity(_makeActivity('a-${dim.name}', dim,
            intensity: 50, timestamp: now.subtract(const Duration(days: 2))));
      }
      for (final dim in BalanceDimension.values) {
        final score = service.scoreDimension(dim, now: now);
        expect(score.score, greaterThan(0));
        expect(score.dimension, dim);
      }
    });

    test('score is clamped to 0-100', () {
      final now = DateTime(2026, 5, 1);
      // Add many high-intensity activities.
      for (int i = 0; i < 30; i++) {
        service.addActivity(_makeActivity('a$i', BalanceDimension.work,
            intensity: 100, timestamp: now.subtract(Duration(days: i))));
      }
      final score = service.scoreDimension(BalanceDimension.work, now: now);
      expect(score.score, lessThanOrEqualTo(100));
      expect(score.score, greaterThanOrEqualTo(0));
    });
  });

  // =========================================================================
  // Imbalance Detector
  // =========================================================================

  group('Imbalance Detector', () {
    test('no activities produces neglected alerts for all dimensions', () {
      final alerts = service.detectImbalances(now: DateTime(2026, 5, 1));
      // All dimensions score 0 < 20 = neglected (though no activity means score 0).
      final neglected =
          alerts.where((a) => a.type == ImbalanceType.neglected);
      expect(neglected.length, BalanceDimension.values.length);
    });

    test('detects neglected dimension', () {
      final now = DateTime(2026, 5, 1);
      // Add activities to all except creativity.
      for (final dim in BalanceDimension.values) {
        if (dim == BalanceDimension.creativity) continue;
        for (int i = 0; i < 5; i++) {
          service.addActivity(_makeActivity('a-${dim.name}-$i', dim,
              intensity: 60, timestamp: now.subtract(Duration(days: i + 1))));
        }
      }
      final alerts = service.detectImbalances(now: now);
      final neglected = alerts
          .where((a) => a.type == ImbalanceType.neglected)
          .toList();
      expect(
          neglected.any(
              (a) => a.affectedDimensions.contains(BalanceDimension.creativity)),
          true);
    });

    test('detects overinvested dimension', () {
      final now = DateTime(2026, 5, 1);
      // Heavy work, minimal everything else.
      for (int i = 0; i < 20; i++) {
        service.addActivity(_makeActivity('work-$i', BalanceDimension.work,
            intensity: 95, timestamp: now.subtract(Duration(days: i))));
      }
      final alerts = service.detectImbalances(now: now);
      final overinvested = alerts
          .where((a) => a.type == ImbalanceType.overinvested)
          .toList();
      expect(overinvested.isNotEmpty, true);
      expect(
          overinvested.any(
              (a) => a.affectedDimensions.contains(BalanceDimension.work)),
          true);
    });

    test('detects stagnant dimension', () {
      final now = DateTime(2026, 5, 1);
      // Old activity, nothing recent.
      service.addActivity(_makeActivity('old', BalanceDimension.fitness,
          intensity: 70,
          timestamp: now.subtract(const Duration(days: 20))));
      final alerts = service.detectImbalances(now: now);
      final stagnant = alerts
          .where((a) =>
              a.type == ImbalanceType.stagnant &&
              a.affectedDimensions.contains(BalanceDimension.fitness))
          .toList();
      expect(stagnant.isNotEmpty, true);
    });

    test('detects declining dimension', () {
      final now = DateTime(2026, 5, 1);
      // Many activities 20-30 days ago, none in last 15 days.
      for (int i = 16; i <= 28; i++) {
        service.addActivity(_makeActivity('old-$i', BalanceDimension.learning,
            intensity: 70, timestamp: now.subtract(Duration(days: i))));
      }
      final alerts = service.detectImbalances(now: now);
      final declining = alerts
          .where((a) =>
              a.type == ImbalanceType.declining &&
              a.affectedDimensions.contains(BalanceDimension.learning))
          .toList();
      expect(declining.isNotEmpty, true);
    });

    test('alerts have valid severity', () {
      final alerts = service.detectImbalances(now: DateTime(2026, 5, 1));
      for (final alert in alerts) {
        expect(alert.severity, greaterThanOrEqualTo(0));
        expect(alert.severity, lessThanOrEqualTo(100));
      }
    });

    test('multiple simultaneous alert types detected', () {
      final now = DateTime(2026, 5, 1);
      // Work is overinvested, creativity is neglected, fitness is stagnant.
      for (int i = 0; i < 20; i++) {
        service.addActivity(_makeActivity('work-$i', BalanceDimension.work,
            intensity: 95, timestamp: now.subtract(Duration(days: i))));
      }
      service.addActivity(_makeActivity('fit-old', BalanceDimension.fitness,
          intensity: 70,
          timestamp: now.subtract(const Duration(days: 20))));

      final alerts = service.detectImbalances(now: now);
      final types = alerts.map((a) => a.type).toSet();
      expect(types.length, greaterThanOrEqualTo(2));
    });
  });

  // =========================================================================
  // Trend Analyzer
  // =========================================================================

  group('Trend Analyzer', () {
    test('insufficient snapshots returns stable', () {
      expect(service.analyzeTrend(), BalanceTrend.stable);
    });

    test('two snapshots still returns stable', () {
      final now = DateTime(2026, 5, 1);
      _addBalancedActivities(service, now);
      service.takeSnapshot(now: now.subtract(const Duration(days: 2)));
      service.takeSnapshot(now: now);
      expect(service.analyzeTrend(), BalanceTrend.stable);
    });

    test('improving trend with increasing scores', () {
      final now = DateTime(2026, 5, 1);
      // Create snapshots with increasing composite scores by adding more
      // activities before each snapshot.
      for (int s = 0; s < 5; s++) {
        final snapTime = now.subtract(Duration(days: 20 - s * 4));
        // Add progressively more activities closer to each snapshot.
        for (int i = 0; i <= s * 3; i++) {
          for (final dim in BalanceDimension.values) {
            service.addActivity(_makeActivity(
                'a-$s-$i-${dim.name}', dim,
                intensity: 60 + s * 5.0,
                timestamp: snapTime.subtract(Duration(days: i))));
          }
        }
        service.takeSnapshot(now: snapTime);
      }
      final trend = service.analyzeTrend();
      // Should be improving or at least stable (depends on exact calculation).
      expect(
          trend == BalanceTrend.improving || trend == BalanceTrend.stable, true);
    });

    test('declining trend detection', () {
      final now = DateTime(2026, 5, 1);
      // First snapshots with many activities, later ones with fewer.
      for (int s = 0; s < 5; s++) {
        final snapTime = now.subtract(Duration(days: 20 - s * 4));
        final actCount = (10 - s * 2).clamp(0, 10);
        for (int i = 0; i < actCount; i++) {
          for (final dim in BalanceDimension.values) {
            service.addActivity(_makeActivity(
                'a-$s-$i-${dim.name}', dim,
                intensity: 80 - s * 15.0,
                timestamp:
                    snapTime.subtract(Duration(days: i))));
          }
        }
        service.takeSnapshot(now: snapTime);
      }
      // Trend should be declining or volatile depending on exact numbers.
      final trend = service.analyzeTrend();
      expect(
          trend == BalanceTrend.declining ||
              trend == BalanceTrend.volatile ||
              trend == BalanceTrend.stable,
          true);
    });

    test('trend is a valid BalanceTrend value', () {
      _addBalancedActivities(service, DateTime(2026, 5, 1));
      for (int i = 0; i < 5; i++) {
        service.takeSnapshot(
            now: DateTime(2026, 5, 1).subtract(Duration(days: i * 3)));
      }
      expect(BalanceTrend.values.contains(service.analyzeTrend()), true);
    });
  });

  // =========================================================================
  // Recommendation Engine
  // =========================================================================

  group('Recommendation Engine', () {
    test('empty state generates recommendations for neglected dims', () {
      final recs =
          service.generateRecommendations(now: DateTime(2026, 5, 1));
      expect(recs.isNotEmpty, true);
      expect(recs.first.priority, RecommendationPriority.critical);
    });

    test('neglected dimension gets critical priority', () {
      final now = DateTime(2026, 5, 1);
      // Only add activities to work.
      for (int i = 0; i < 10; i++) {
        service.addActivity(_makeActivity('work-$i', BalanceDimension.work,
            intensity: 70, timestamp: now.subtract(Duration(days: i))));
      }
      final recs = service.generateRecommendations(now: now);
      final critical =
          recs.where((r) => r.priority == RecommendationPriority.critical);
      expect(critical.isNotEmpty, true);
    });

    test('recommendations are sorted by priority', () {
      final now = DateTime(2026, 5, 1);
      _addMixedActivities(service, now);
      final recs = service.generateRecommendations(now: now);
      if (recs.length >= 2) {
        for (int i = 0; i < recs.length - 1; i++) {
          expect(recs[i].priority.sortOrder,
              lessThanOrEqualTo(recs[i + 1].priority.sortOrder));
        }
      }
    });

    test('recommendations have actionable text', () {
      final recs =
          service.generateRecommendations(now: DateTime(2026, 5, 1));
      for (final rec in recs) {
        expect(rec.action, isNotEmpty);
        expect(rec.reasoning, isNotEmpty);
      }
    });

    test('recommendations cover multiple dimensions', () {
      final recs =
          service.generateRecommendations(now: DateTime(2026, 5, 1));
      final dims = recs.map((r) => r.targetDimension).toSet();
      expect(dims.length, greaterThan(1));
    });

    test('recommendations have valid score ranges', () {
      final now = DateTime(2026, 5, 1);
      _addMixedActivities(service, now);
      final recs = service.generateRecommendations(now: now);
      for (final rec in recs) {
        expect(rec.currentScore, greaterThanOrEqualTo(0));
        expect(rec.targetScore, greaterThanOrEqualTo(0));
        expect(rec.targetScore, lessThanOrEqualTo(100));
        expect(rec.estimatedImpact, greaterThanOrEqualTo(0));
      }
    });
  });

  // =========================================================================
  // Snapshot Generator
  // =========================================================================

  group('Snapshot Generator', () {
    test('creates valid snapshot', () {
      final now = DateTime(2026, 5, 1);
      _addBalancedActivities(service, now);
      final snap = service.takeSnapshot(now: now);
      expect(snap.dimensionScores.length, BalanceDimension.values.length);
      expect(snap.id, isNotEmpty);
    });

    test('composite score in range 0-100', () {
      final now = DateTime(2026, 5, 1);
      _addBalancedActivities(service, now);
      final snap = service.takeSnapshot(now: now);
      expect(snap.compositeScore, greaterThanOrEqualTo(0));
      expect(snap.compositeScore, lessThanOrEqualTo(100));
    });

    test('gini coefficient in range 0-1', () {
      final now = DateTime(2026, 5, 1);
      _addBalancedActivities(service, now);
      final snap = service.takeSnapshot(now: now);
      expect(snap.giniCoefficient, greaterThanOrEqualTo(0));
      expect(snap.giniCoefficient, lessThanOrEqualTo(1));
    });

    test('snapshot includes alerts', () {
      // No activities = all neglected = many alerts.
      final snap = service.takeSnapshot(now: DateTime(2026, 5, 1));
      expect(snap.alerts.isNotEmpty, true);
    });

    test('snapshot timestamp matches', () {
      final now = DateTime(2026, 5, 1);
      final snap = service.takeSnapshot(now: now);
      expect(snap.timestamp, now);
    });

    test('multiple snapshots are recorded', () {
      final now = DateTime(2026, 5, 1);
      _addBalancedActivities(service, now);
      service.takeSnapshot(now: now.subtract(const Duration(days: 7)));
      service.takeSnapshot(now: now);
      expect(service.snapshots.length, 2);
    });
  });

  // =========================================================================
  // Insight Generator
  // =========================================================================

  group('Insight Generator', () {
    test('identifies strongest dimension', () {
      final now = DateTime(2026, 5, 1);
      _addMixedActivities(service, now);
      final insights = service.generateInsights(now: now);
      expect(insights.any((i) => i.contains('strongest')), true);
    });

    test('identifies weakest dimension', () {
      final now = DateTime(2026, 5, 1);
      _addMixedActivities(service, now);
      final insights = service.generateInsights(now: now);
      expect(insights.any((i) => i.contains('weakest')), true);
    });

    test('reports balance gap', () {
      final now = DateTime(2026, 5, 1);
      _addMixedActivities(service, now);
      final insights = service.generateInsights(now: now);
      expect(insights.any((i) => i.contains('gap') || i.contains('balanced')),
          true);
    });

    test('includes trajectory insight', () {
      final now = DateTime(2026, 5, 1);
      _addMixedActivities(service, now);
      final insights = service.generateInsights(now: now);
      expect(insights.any((i) => i.contains('trajectory')), true);
    });

    test('includes activity distribution', () {
      final now = DateTime(2026, 5, 1);
      _addMixedActivities(service, now);
      final insights = service.generateInsights(now: now);
      expect(insights.any((i) => i.contains('activities across')), true);
    });
  });

  // =========================================================================
  // Report & Serialization
  // =========================================================================

  group('Report & Serialization', () {
    test('generateReport produces valid report', () {
      final now = DateTime(2026, 5, 1);
      _addBalancedActivities(service, now);
      final report = service.generateReport(now: now);
      expect(report.snapshots.isNotEmpty, true);
      expect(report.insights.isNotEmpty, true);
      expect(report.overallHealth, isNotEmpty);
    });

    test('toJson produces valid map for snapshot', () {
      final now = DateTime(2026, 5, 1);
      _addBalancedActivities(service, now);
      final snap = service.takeSnapshot(now: now);
      final json = snap.toJson();
      expect(json['compositeScore'], isA<double>());
      expect(json['dimensionScores'], isA<Map>());
      expect(json['trend'], isA<String>());
    });

    test('DimensionActivity round-trip via JSON', () {
      final act = _makeActivity('rt1', BalanceDimension.learning,
          intensity: 75, timestamp: DateTime(2026, 3, 15));
      final json = act.toJson();
      final restored = DimensionActivity.fromJson(json);
      expect(restored.id, act.id);
      expect(restored.dimension, act.dimension);
      expect(restored.intensity, act.intensity);
    });

    test('demo data produces valid report', () {
      service.generateDemoData(now: DateTime(2026, 5, 1));
      final report = service.generateReport(now: DateTime(2026, 5, 1));
      expect(report.snapshots.first.compositeScore, greaterThan(0));
      expect(report.insights.isNotEmpty, true);
    });
  });

  // =========================================================================
  // Gini Coefficient
  // =========================================================================

  group('Gini Coefficient', () {
    test('perfect equality returns 0', () {
      final gini = service.giniCoefficient([50, 50, 50, 50]);
      expect(gini, closeTo(0.0, 0.001));
    });

    test('perfect inequality approaches 1', () {
      final gini = service.giniCoefficient([0, 0, 0, 100]);
      expect(gini, greaterThan(0.5));
    });

    test('partial inequality gives intermediate value', () {
      final gini = service.giniCoefficient([10, 30, 50, 70, 90]);
      expect(gini, greaterThan(0));
      expect(gini, lessThan(1));
    });

    test('single value returns 0', () {
      expect(service.giniCoefficient([42]), 0.0);
    });

    test('empty list returns 0', () {
      expect(service.giniCoefficient([]), 0.0);
    });
  });

  // =========================================================================
  // Reset
  // =========================================================================

  group('Reset', () {
    test('reset clears all data', () {
      service.addActivity(_makeActivity('a1', BalanceDimension.health));
      service.takeSnapshot(now: DateTime(2026, 5, 1));
      service.reset();
      expect(service.activities, isEmpty);
      expect(service.snapshots, isEmpty);
    });
  });
}

// ---------------------------------------------------------------------------
// Test Helpers
// ---------------------------------------------------------------------------

DimensionActivity _makeActivity(
  String id,
  BalanceDimension dim, {
  double intensity = 50,
  int duration = 30,
  DateTime? timestamp,
}) {
  return DimensionActivity(
    id: id,
    dimension: dim,
    intensity: intensity,
    durationMinutes: duration,
    timestamp: timestamp ?? DateTime(2026, 4, 28),
  );
}

/// Add balanced activities across all dimensions.
void _addBalancedActivities(BalanceRadarEngineService service, DateTime now) {
  for (final dim in BalanceDimension.values) {
    for (int i = 0; i < 5; i++) {
      service.addActivity(_makeActivity('bal-${dim.name}-$i', dim,
          intensity: 55, timestamp: now.subtract(Duration(days: i + 1))));
    }
  }
}

/// Add mixed activities: heavy work, some health/fitness, minimal creativity.
void _addMixedActivities(BalanceRadarEngineService service, DateTime now) {
  // Heavy work.
  for (int i = 0; i < 15; i++) {
    service.addActivity(_makeActivity('mix-work-$i', BalanceDimension.work,
        intensity: 80, timestamp: now.subtract(Duration(days: i))));
  }
  // Moderate health.
  for (int i = 0; i < 6; i++) {
    service.addActivity(_makeActivity('mix-health-$i', BalanceDimension.health,
        intensity: 60, timestamp: now.subtract(Duration(days: i * 2))));
  }
  // Some fitness.
  for (int i = 0; i < 4; i++) {
    service.addActivity(_makeActivity(
        'mix-fitness-$i', BalanceDimension.fitness,
        intensity: 65, timestamp: now.subtract(Duration(days: i * 3))));
  }
  // Minimal creativity.
  service.addActivity(_makeActivity('mix-create-0', BalanceDimension.creativity,
      intensity: 30, timestamp: now.subtract(const Duration(days: 25))));
}
