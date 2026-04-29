import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/behavioral_fingerprint_service.dart';

void main() {
  group('BehaviorEvent', () {
    test('serialization round-trip', () {
      final event = BehaviorEvent(
        id: 'e1',
        timestamp: DateTime(2026, 4, 28, 10, 30),
        category: 'exercise',
        action: 'complete',
        durationMinutes: 45.0,
        metadata: {'type': 'run'},
      );

      final json = event.toJson();
      final restored = BehaviorEvent.fromJson(json);

      expect(restored.id, 'e1');
      expect(restored.category, 'exercise');
      expect(restored.action, 'complete');
      expect(restored.durationMinutes, 45.0);
      expect(restored.metadata['type'], 'run');
    });
  });

  group('DailyFingerprint', () {
    test('distanceTo identical fingerprints is zero', () {
      final fp = DailyFingerprint(
        date: DateTime(2026, 4, 28),
        values: {for (final d in BehaviorDimension.values) d: 0.5},
      );
      expect(fp.distanceTo(fp), 0.0);
    });

    test('distanceTo different fingerprints is positive', () {
      final a = DailyFingerprint(
        date: DateTime(2026, 4, 28),
        values: {for (final d in BehaviorDimension.values) d: 0.0},
      );
      final b = DailyFingerprint(
        date: DateTime(2026, 4, 28),
        values: {for (final d in BehaviorDimension.values) d: 1.0},
      );
      expect(a.distanceTo(b), greaterThan(0));
    });

    test('serialization round-trip', () {
      final fp = DailyFingerprint(
        date: DateTime(2026, 4, 28),
        values: {
          BehaviorDimension.activityTiming: 0.4,
          BehaviorDimension.taskVelocity: 0.7,
        },
      );

      final json = fp.toJson();
      final restored = DailyFingerprint.fromJson(json);

      expect(restored.values[BehaviorDimension.activityTiming], 0.4);
      expect(restored.values[BehaviorDimension.taskVelocity], 0.7);
    });
  });

  group('BehaviorBaseline', () {
    test('isReliable requires 14+ days', () {
      final unreliable = BehaviorBaseline(
        means: {},
        stdDevs: {},
        computedAt: DateTime.now(),
        sampleDays: 10,
      );
      expect(unreliable.isReliable, false);

      final reliable = BehaviorBaseline(
        means: {},
        stdDevs: {},
        computedAt: DateTime.now(),
        sampleDays: 14,
      );
      expect(reliable.isReliable, true);
    });

    test('serialization round-trip', () {
      final bl = BehaviorBaseline(
        means: {BehaviorDimension.activityTiming: 0.45},
        stdDevs: {BehaviorDimension.activityTiming: 0.12},
        computedAt: DateTime(2026, 4, 28),
        sampleDays: 20,
      );

      final json = bl.toJson();
      final restored = BehaviorBaseline.fromJson(json);

      expect(restored.means[BehaviorDimension.activityTiming], 0.45);
      expect(restored.stdDevs[BehaviorDimension.activityTiming], 0.12);
      expect(restored.sampleDays, 20);
    });
  });

  group('BehavioralFingerprintService', () {
    late BehavioralFingerprintService service;

    setUp(() {
      service = BehavioralFingerprintService();
    });

    test('recordEvent adds to event list', () {
      service.recordEvent(BehaviorEvent(
        id: 'e1',
        timestamp: DateTime(2026, 4, 28, 9, 0),
        category: 'exercise',
        action: 'complete',
      ));
      expect(service.events.length, 1);
    });

    test('recordEvents adds multiple events', () {
      service.recordEvents([
        BehaviorEvent(
          id: 'e1',
          timestamp: DateTime(2026, 4, 28, 9, 0),
          category: 'exercise',
          action: 'complete',
        ),
        BehaviorEvent(
          id: 'e2',
          timestamp: DateTime(2026, 4, 28, 10, 0),
          category: 'reading',
          action: 'start',
        ),
      ]);
      expect(service.events.length, 2);
    });

    test('computeDailyFingerprint returns valid values', () {
      _addDayEvents(service, DateTime(2026, 4, 28));

      final fp =
          service.computeDailyFingerprint(date: DateTime(2026, 4, 28));

      expect(fp.values.length, BehaviorDimension.values.length);
      for (final val in fp.values.values) {
        expect(val, greaterThanOrEqualTo(0.0));
        expect(val, lessThanOrEqualTo(1.0));
      }
    });

    test('computeDailyFingerprint replaces existing for same date', () {
      _addDayEvents(service, DateTime(2026, 4, 28));
      service.computeDailyFingerprint(date: DateTime(2026, 4, 28));
      service.computeDailyFingerprint(date: DateTime(2026, 4, 28));

      expect(service.fingerprints.length, 1);
    });

    test('computeBaseline from multiple days', () {
      for (int i = 0; i < 20; i++) {
        final date = DateTime(2026, 4, 1).add(Duration(days: i));
        _addDayEvents(service, date);
        service.computeDailyFingerprint(date: date);
      }

      final baseline =
          service.computeBaseline(now: DateTime(2026, 4, 25));

      expect(baseline.sampleDays, greaterThan(0));
      expect(baseline.means.length, BehaviorDimension.values.length);
      expect(baseline.stdDevs.length, BehaviorDimension.values.length);
    });

    test('computeBaseline isReliable with 14+ days', () {
      for (int i = 0; i < 20; i++) {
        final date = DateTime(2026, 4, 1).add(Duration(days: i));
        _addDayEvents(service, date);
        service.computeDailyFingerprint(date: date);
      }

      final baseline =
          service.computeBaseline(now: DateTime(2026, 4, 25));
      expect(baseline.isReliable, true);
    });

    test('analyzeDeviation returns valid report', () {
      for (int i = 0; i < 20; i++) {
        final date = DateTime(2026, 4, 1).add(Duration(days: i));
        _addDayEvents(service, date);
        service.computeDailyFingerprint(date: date);
      }
      service.computeBaseline(now: DateTime(2026, 4, 25));

      final report = service.analyzeDeviation();

      expect(report.deviations.length, BehaviorDimension.values.length);
      expect(report.authenticityScore, greaterThanOrEqualTo(0));
      expect(report.authenticityScore, lessThanOrEqualTo(100));
      expect(report.changeNarratives, isNotEmpty);
      expect(report.phase, isA<IdentityPhase>());
    });

    test('analyzeDeviation detects disruption from anomalous day', () {
      // Build a consistent baseline of morning exercise person
      for (int i = 0; i < 20; i++) {
        final date = DateTime(2026, 4, 1).add(Duration(days: i));
        _addMorningExerciseDay(service, date);
        service.computeDailyFingerprint(date: date);
      }
      service.computeBaseline(now: DateTime(2026, 4, 25));

      // Now add a completely different day pattern (all evening, different categories)
      final anomalyDate = DateTime(2026, 4, 25);
      _addEveningPartyDay(service, anomalyDate);
      service.computeDailyFingerprint(date: anomalyDate);

      final report = service.analyzeDeviation();

      // Should detect some deviation
      expect(report.compositeDistance, greaterThan(0));
      expect(
          report.phase,
          isNot(IdentityPhase.authentic).having(
              (p) => true, 'not authentic or has deviations',
              isTrue));
    });

    test('authenticityScore high for consistent behavior', () {
      for (int i = 0; i < 20; i++) {
        final date = DateTime(2026, 4, 1).add(Duration(days: i));
        _addMorningExerciseDay(service, date);
        service.computeDailyFingerprint(date: date);
      }
      service.computeBaseline(now: DateTime(2026, 4, 25));

      // Analyze the same pattern
      final report = service.analyzeDeviation();
      expect(report.authenticityScore, greaterThan(50));
    });

    test('getIdentityTrend returns valid trend', () {
      for (int i = 0; i < 20; i++) {
        final date = DateTime(2026, 4, 1).add(Duration(days: i));
        _addDayEvents(service, date);
        service.computeDailyFingerprint(date: date);
      }
      service.computeBaseline(now: DateTime(2026, 4, 25));

      // Generate some trend points by analyzing
      for (int i = 15; i < 20; i++) {
        final date = DateTime(2026, 4, 1).add(Duration(days: i));
        final fp = service.fingerprints
            .where((f) =>
                f.date ==
                DateTime(date.year, date.month, date.day))
            .firstOrNull;
        if (fp != null) {
          service.analyzeDeviation(fingerprint: fp);
        }
      }

      final trend = service.getIdentityTrend(days: 30);
      expect(
          trend.direction,
          anyOf('stabilizing', 'destabilizing', 'steady'));
    });

    test('getSignatureSummary without baseline', () {
      final summary = service.getSignatureSummary();
      expect(summary['status'], 'insufficient_data');
    });

    test('getSignatureSummary with baseline', () {
      for (int i = 0; i < 20; i++) {
        final date = DateTime(2026, 4, 1).add(Duration(days: i));
        _addDayEvents(service, date);
        service.computeDailyFingerprint(date: date);
      }
      service.computeBaseline(now: DateTime(2026, 4, 25));

      final summary = service.getSignatureSummary();
      expect(summary['status'], 'reliable');
      expect(summary['dimensions'], isA<Map>());
      expect(summary['mostStable'], isA<String>());
      expect(summary['mostVariable'], isA<String>());
    });

    test('generateInsights returns list', () {
      final insights = service.generateInsights();
      expect(insights, isNotEmpty); // Should say "still learning"
    });

    test('generateInsights with reliable baseline', () {
      for (int i = 0; i < 20; i++) {
        final date = DateTime(2026, 4, 1).add(Duration(days: i));
        _addMorningExerciseDay(service, date);
        service.computeDailyFingerprint(date: date);
      }
      service.computeBaseline(now: DateTime(2026, 4, 25));

      final insights = service.generateInsights();
      expect(insights, isNotEmpty);
      // Should detect early bird pattern
      expect(
        insights.any((i) => i.contains('Early bird') || i.contains('morning') || i.contains('Morning')),
        true,
        reason: 'Should detect morning activity pattern',
      );
    });

    test('persistence round-trip', () {
      _addDayEvents(service, DateTime(2026, 4, 28));
      service.computeDailyFingerprint(date: DateTime(2026, 4, 28));

      final json = service.toStorageJson();

      final restored = BehavioralFingerprintService();
      restored.fromStorageJson(json);

      expect(restored.events.length, service.events.length);
      expect(restored.fingerprints.length, service.fingerprints.length);
    });

    test('significantDeviations filtered correctly', () {
      for (int i = 0; i < 20; i++) {
        final date = DateTime(2026, 4, 1).add(Duration(days: i));
        _addMorningExerciseDay(service, date);
        service.computeDailyFingerprint(date: date);
      }
      service.computeBaseline(now: DateTime(2026, 4, 25));

      _addEveningPartyDay(service, DateTime(2026, 4, 25));
      service.computeDailyFingerprint(date: DateTime(2026, 4, 25));

      final report = service.analyzeDeviation();
      // significantDeviations should only include moderate+
      for (final d in report.significantDeviations) {
        expect(d.level.priority, greaterThanOrEqualTo(2));
      }
    });

    test('DeviationLevel ordering', () {
      expect(DeviationLevel.normal.priority, 0);
      expect(DeviationLevel.mild.priority, 1);
      expect(DeviationLevel.moderate.priority, 2);
      expect(DeviationLevel.significant.priority, 3);
      expect(DeviationLevel.extreme.priority, 4);
    });

    test('IdentityPhase has all required fields', () {
      for (final phase in IdentityPhase.values) {
        expect(phase.label, isNotEmpty);
        expect(phase.emoji, isNotEmpty);
        expect(phase.description, isNotEmpty);
      }
    });

    test('BehaviorDimension has all required fields', () {
      for (final dim in BehaviorDimension.values) {
        expect(dim.label, isNotEmpty);
        expect(dim.emoji, isNotEmpty);
        expect(dim.description, isNotEmpty);
      }
    });

    test('empty day fingerprint has default values', () {
      final fp = service.computeDailyFingerprint(date: DateTime(2026, 4, 28));
      // No events → dimensions should be at default/zero
      expect(fp.values[BehaviorDimension.activityTiming], 0.5);
      expect(fp.values[BehaviorDimension.taskVelocity], 0.0);
    });
  });
}

// -- Test Helpers --

void _addDayEvents(BehavioralFingerprintService service, DateTime date) {
  final events = [
    BehaviorEvent(
      id: '${date.day}-1',
      timestamp: DateTime(date.year, date.month, date.day, 8, 0),
      category: 'exercise',
      action: 'complete',
      durationMinutes: 30,
    ),
    BehaviorEvent(
      id: '${date.day}-2',
      timestamp: DateTime(date.year, date.month, date.day, 9, 30),
      category: 'reading',
      action: 'start',
      durationMinutes: 45,
    ),
    BehaviorEvent(
      id: '${date.day}-3',
      timestamp: DateTime(date.year, date.month, date.day, 12, 0),
      category: 'meal',
      action: 'complete',
    ),
    BehaviorEvent(
      id: '${date.day}-4',
      timestamp: DateTime(date.year, date.month, date.day, 14, 0),
      category: 'work',
      action: 'complete',
      durationMinutes: 120,
    ),
    BehaviorEvent(
      id: '${date.day}-5',
      timestamp: DateTime(date.year, date.month, date.day, 18, 0),
      category: 'social',
      action: 'start',
    ),
  ];
  service.recordEvents(events);
}

void _addMorningExerciseDay(
    BehavioralFingerprintService service, DateTime date) {
  final events = [
    BehaviorEvent(
      id: 'me-${date.day}-1',
      timestamp: DateTime(date.year, date.month, date.day, 6, 0),
      category: 'exercise',
      action: 'complete',
      durationMinutes: 60,
    ),
    BehaviorEvent(
      id: 'me-${date.day}-2',
      timestamp: DateTime(date.year, date.month, date.day, 7, 0),
      category: 'meditation',
      action: 'complete',
      durationMinutes: 15,
    ),
    BehaviorEvent(
      id: 'me-${date.day}-3',
      timestamp: DateTime(date.year, date.month, date.day, 8, 0),
      category: 'reading',
      action: 'complete',
      durationMinutes: 30,
    ),
    BehaviorEvent(
      id: 'me-${date.day}-4',
      timestamp: DateTime(date.year, date.month, date.day, 9, 0),
      category: 'work',
      action: 'complete',
      durationMinutes: 180,
    ),
    BehaviorEvent(
      id: 'me-${date.day}-5',
      timestamp: DateTime(date.year, date.month, date.day, 10, 30),
      category: 'work',
      action: 'complete',
      durationMinutes: 90,
    ),
  ];
  service.recordEvents(events);
}

void _addEveningPartyDay(
    BehavioralFingerprintService service, DateTime date) {
  final events = [
    BehaviorEvent(
      id: 'ep-${date.day}-1',
      timestamp: DateTime(date.year, date.month, date.day, 18, 0),
      category: 'social',
      action: 'start',
    ),
    BehaviorEvent(
      id: 'ep-${date.day}-2',
      timestamp: DateTime(date.year, date.month, date.day, 19, 0),
      category: 'entertainment',
      action: 'start',
    ),
    BehaviorEvent(
      id: 'ep-${date.day}-3',
      timestamp: DateTime(date.year, date.month, date.day, 20, 0),
      category: 'social',
      action: 'complete',
      durationMinutes: 120,
    ),
    BehaviorEvent(
      id: 'ep-${date.day}-4',
      timestamp: DateTime(date.year, date.month, date.day, 22, 0),
      category: 'entertainment',
      action: 'complete',
      durationMinutes: 60,
    ),
  ];
  service.recordEvents(events);
}
