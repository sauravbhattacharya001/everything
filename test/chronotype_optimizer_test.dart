import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/chronotype_optimizer_service.dart';

void main() {
  group('ChronotypeOptimizerService', () {
    late ChronotypeOptimizerService service;

    setUp(() {
      service = ChronotypeOptimizerService();
    });

    // ── Activity logging ──────────────────────────────────────────────

    test('starts with empty activities', () {
      expect(service.activities, isEmpty);
    });

    test('addActivity stores entry', () {
      service.addActivity(ActivityClockEntry(
        id: 'test1',
        timestamp: DateTime(2026, 1, 15, 9, 30),
        taskType: TaskType.deepWork,
      ));
      expect(service.activities, hasLength(1));
      expect(service.activities.first.id, 'test1');
    });

    test('clear removes all activities', () {
      service.addActivity(ActivityClockEntry(
        id: 'a',
        timestamp: DateTime(2026, 1, 15, 10, 0),
        taskType: TaskType.routine,
      ));
      service.clear();
      expect(service.activities, isEmpty);
    });

    test('activities list is unmodifiable', () {
      service.addActivity(ActivityClockEntry(
        id: 'x',
        timestamp: DateTime(2026, 1, 15, 10, 0),
        taskType: TaskType.routine,
      ));
      expect(() => service.activities.add(ActivityClockEntry(
            id: 'y',
            timestamp: DateTime.now(),
            taskType: TaskType.creative,
          )), throwsUnsupportedError);
    });

    // ── Sample data ───────────────────────────────────────────────────

    test('loadSampleData populates activities', () {
      service.loadSampleData();
      expect(service.activities.length, greaterThan(100));
    });

    test('loadSampleData is idempotent (clears first)', () {
      service.loadSampleData();
      final count1 = service.activities.length;
      service.loadSampleData();
      expect(service.activities.length, count1);
    });

    test('sample data covers multiple task types', () {
      service.loadSampleData();
      final types = service.activities.map((a) => a.taskType).toSet();
      expect(types, containsAll(TaskType.values));
    });

    // ── ActivityClockEntry ────────────────────────────────────────────

    test('fractionalHour computes correctly', () {
      final entry = ActivityClockEntry(
        id: 'fh',
        timestamp: DateTime(2026, 1, 15, 14, 30),
        taskType: TaskType.creative,
      );
      expect(entry.fractionalHour, closeTo(14.5, 0.01));
    });

    test('toJson / fromJson round-trip', () {
      final entry = ActivityClockEntry(
        id: 'rt',
        timestamp: DateTime(2026, 3, 10, 8, 45),
        taskType: TaskType.physical,
        durationMinutes: 60,
        performanceScore: 0.9,
      );
      final json = entry.toJson();
      final restored = ActivityClockEntry.fromJson(json);
      expect(restored.id, entry.id);
      expect(restored.taskType, entry.taskType);
      expect(restored.durationMinutes, 60);
      expect(restored.performanceScore, closeTo(0.9, 0.001));
    });

    // ── Empty report ─────────────────────────────────────────────────

    test('generateReport on empty data returns dolphin + chaotic', () {
      final report = service.generateReport();
      expect(report.chronotype, Chronotype.dolphin);
      expect(report.alignmentGrade, AlignmentGrade.chaotic);
      expect(report.totalActivities, 0);
      expect(report.insights, isNotEmpty);
    });

    // ── Full report from sample data ─────────────────────────────────

    group('with sample data', () {
      late ChronotypeReport report;

      setUp(() {
        service.loadSampleData();
        report = service.generateReport();
      });

      test('report has a valid chronotype', () {
        expect(Chronotype.values, contains(report.chronotype));
      });

      test('report totalActivities matches service count', () {
        expect(report.totalActivities, service.activities.length);
      });

      // ── Circadian Profile (Engine 2) ────────────────────────────

      test('energy curve has 24 entries', () {
        expect(report.profile.hourlyEnergy, hasLength(24));
      });

      test('energy values are normalized 0-1', () {
        for (final e in report.profile.hourlyEnergy) {
          expect(e, greaterThanOrEqualTo(0.0));
          expect(e, lessThanOrEqualTo(1.0));
        }
      });

      test('at least one hour has energy = 1.0 (the peak)', () {
        expect(report.profile.hourlyEnergy, contains(1.0));
      });

      test('peak hour is between 0-23', () {
        expect(report.profile.peakHour, greaterThanOrEqualTo(0));
        expect(report.profile.peakHour, lessThan(24));
      });

      test('trough hour differs from peak hour', () {
        expect(report.profile.troughHour, isNot(report.profile.peakHour));
      });

      test('timing variability is non-negative', () {
        expect(report.profile.timingVariability, greaterThanOrEqualTo(0));
      });

      // ── Chronotype Classification (Engine 3) ───────────────────

      test('sample data classifies as Bear or Lion (morning-heavy)', () {
        // Sample data has main activities 7-14, so Bear or Lion expected.
        expect(
          [Chronotype.lion, Chronotype.bear],
          contains(report.chronotype),
        );
      });

      // ── Peak Windows (Engine 4) ─────────────────────────────────

      test('peak windows covers multiple task types', () {
        expect(report.peakWindows, isNotEmpty);
        final types = report.peakWindows.map((pw) => pw.taskType).toSet();
        expect(types.length, greaterThan(1));
      });

      test('peak window confidence is 0-1', () {
        for (final pw in report.peakWindows) {
          expect(pw.confidenceScore, greaterThanOrEqualTo(0.0));
          expect(pw.confidenceScore, lessThanOrEqualTo(1.0));
        }
      });

      test('peak window hours are 0-23', () {
        for (final pw in report.peakWindows) {
          expect(pw.startHour, greaterThanOrEqualTo(0));
          expect(pw.startHour, lessThan(24));
        }
      });

      test('peak window timeRange is formatted correctly', () {
        for (final pw in report.peakWindows) {
          expect(pw.timeRange, contains('–'));
          expect(pw.timeRange, contains('AM'));
        }
      });

      // ── Alignment Score (Engine 5) ──────────────────────────────

      test('alignment score is 0-100', () {
        expect(report.alignmentScore, greaterThanOrEqualTo(0));
        expect(report.alignmentScore, lessThanOrEqualTo(100));
      });

      test('alignment grade matches score range', () {
        final s = report.alignmentScore;
        if (s >= 80) {
          expect(report.alignmentGrade, AlignmentGrade.optimal);
        } else if (s >= 65) {
          expect(report.alignmentGrade, AlignmentGrade.good);
        } else if (s >= 45) {
          expect(report.alignmentGrade, AlignmentGrade.fair);
        } else if (s >= 25) {
          expect(report.alignmentGrade, AlignmentGrade.misaligned);
        } else {
          expect(report.alignmentGrade, AlignmentGrade.chaotic);
        }
      });

      // ── Drift Detector (Engine 6) ───────────────────────────────

      test('drift type is valid', () {
        expect(DriftType.values, contains(report.currentDrift));
      });

      test('weekly centroids are ordered', () {
        for (int i = 1; i < report.weeklyCentroids.length; i++) {
          expect(
            report.weeklyCentroids[i].weekStart.isAfter(
              report.weeklyCentroids[i - 1].weekStart,
            ),
            isTrue,
          );
        }
      });

      test('weekly centroid hours are in 0-24 range', () {
        for (final c in report.weeklyCentroids) {
          expect(c.centroidHour, greaterThanOrEqualTo(0));
          expect(c.centroidHour, lessThan(24));
        }
      });

      test('sample data detects weekend shift', () {
        // Sample data has 1.5h weekend shift.
        final hasWeekendDrift = report.driftEvents
            .any((e) => e.type == DriftType.weekendShift);
        expect(hasWeekendDrift, isTrue);
      });

      // ── Insight Generator (Engine 7) ────────────────────────────

      test('insights are non-empty', () {
        expect(report.insights, isNotEmpty);
      });

      test('insights are sorted by severity (high first)', () {
        for (int i = 1; i < report.insights.length; i++) {
          expect(
            report.insights[i].severity.index,
            greaterThanOrEqualTo(report.insights[i - 1].severity.index),
          );
        }
      });

      test('insights have non-empty fields', () {
        for (final insight in report.insights) {
          expect(insight.title, isNotEmpty);
          expect(insight.body, isNotEmpty);
          expect(insight.recommendation, isNotEmpty);
        }
      });

      test('insights include chronotype description', () {
        final hasChronotypeInsight = report.insights.any(
          (i) => i.title.contains(report.chronotype.label),
        );
        expect(hasChronotypeInsight, isTrue);
      });

      test('insights include trough avoidance', () {
        final hasTroughInsight = report.insights.any(
          (i) => i.title.contains('Trough'),
        );
        expect(hasTroughInsight, isTrue);
      });
    });

    // ── Chronotype classification edge cases ─────────────────────────

    test('classifies Lion for very early activities', () {
      for (int day = 0; day < 14; day++) {
        service.addActivity(ActivityClockEntry(
          id: 'lion_$day',
          timestamp: DateTime(2026, 1, 15 + day, 5, 30),
          taskType: TaskType.deepWork,
          performanceScore: 0.9,
        ));
        service.addActivity(ActivityClockEntry(
          id: 'lion2_$day',
          timestamp: DateTime(2026, 1, 15 + day, 6, 0),
          taskType: TaskType.creative,
          performanceScore: 0.85,
        ));
      }
      final report = service.generateReport();
      expect(report.chronotype, Chronotype.lion);
    });

    test('classifies Wolf for evening activities', () {
      service.clear();
      for (int day = 0; day < 14; day++) {
        service.addActivity(ActivityClockEntry(
          id: 'wolf_$day',
          timestamp: DateTime(2026, 1, 15 + day, 20, 0),
          taskType: TaskType.deepWork,
          performanceScore: 0.9,
        ));
        service.addActivity(ActivityClockEntry(
          id: 'wolf2_$day',
          timestamp: DateTime(2026, 1, 15 + day, 21, 30),
          taskType: TaskType.creative,
          performanceScore: 0.85,
        ));
      }
      final report = service.generateReport();
      expect(report.chronotype, Chronotype.wolf);
    });

    test('classifies Bear for midday activities', () {
      service.clear();
      for (int day = 0; day < 14; day++) {
        service.addActivity(ActivityClockEntry(
          id: 'bear_$day',
          timestamp: DateTime(2026, 1, 15 + day, 10, 0),
          taskType: TaskType.deepWork,
          performanceScore: 0.9,
        ));
        service.addActivity(ActivityClockEntry(
          id: 'bear2_$day',
          timestamp: DateTime(2026, 1, 15 + day, 11, 0),
          taskType: TaskType.routine,
          performanceScore: 0.8,
        ));
      }
      final report = service.generateReport();
      expect(report.chronotype, Chronotype.bear);
    });

    // ── Single entry edge case ───────────────────────────────────────

    test('single entry produces valid report', () {
      service.addActivity(ActivityClockEntry(
        id: 'solo',
        timestamp: DateTime(2026, 3, 10, 14, 0),
        taskType: TaskType.creative,
      ));
      final report = service.generateReport();
      expect(report.totalActivities, 1);
      expect(report.profile.hourlyEnergy, hasLength(24));
      expect(report.alignmentScore, greaterThanOrEqualTo(0));
    });

    // ── Enum labels and emojis ───────────────────────────────────────

    test('TaskType enums have labels and emojis', () {
      for (final t in TaskType.values) {
        expect(t.label, isNotEmpty);
        expect(t.emoji, isNotEmpty);
        expect(t.description, isNotEmpty);
      }
    });

    test('Chronotype enums have labels, emojis, descriptions', () {
      for (final c in Chronotype.values) {
        expect(c.label, isNotEmpty);
        expect(c.emoji, isNotEmpty);
        expect(c.description, isNotEmpty);
        expect(c.colorHex, isNonZero);
      }
    });

    test('AlignmentGrade enums have labels, emojis, descriptions', () {
      for (final g in AlignmentGrade.values) {
        expect(g.label, isNotEmpty);
        expect(g.emoji, isNotEmpty);
        expect(g.description, isNotEmpty);
      }
    });

    test('DriftType enums have labels, emojis, descriptions', () {
      for (final d in DriftType.values) {
        expect(d.label, isNotEmpty);
        expect(d.emoji, isNotEmpty);
        expect(d.description, isNotEmpty);
      }
    });

    test('InsightSeverity enums have emojis', () {
      for (final s in InsightSeverity.values) {
        expect(s.emoji, isNotEmpty);
      }
    });

    // ── PeakWindow formatting ─────────────────────────────────────────

    test('PeakWindow formatHour handles midnight', () {
      final pw = PeakWindow(
        taskType: TaskType.routine,
        startHour: 0,
        endHour: 3,
        confidenceScore: 0.5,
      );
      expect(pw.timeRange, contains('12 AM'));
    });

    test('PeakWindow formatHour handles noon', () {
      final pw = PeakWindow(
        taskType: TaskType.social,
        startHour: 12,
        endHour: 15,
        confidenceScore: 0.6,
      );
      expect(pw.timeRange, contains('12 PM'));
    });
  });
}
