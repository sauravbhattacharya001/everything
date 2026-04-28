import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/momentum_engine_service.dart';

void main() {
  group('MomentumEngineService', () {
    late MomentumEngineService service;

    setUp(() {
      service = MomentumEngineService();
    });

    group('logCompletion', () {
      test('adds event to list', () {
        service.logCompletion(
          category: CompletionCategory.habit,
          label: 'Exercise',
        );
        expect(service.events.length, 1);
        expect(service.events.first.category, CompletionCategory.habit);
        expect(service.events.first.label, 'Exercise');
      });

      test('supports custom weight and timestamp', () {
        final ts = DateTime(2026, 4, 20, 10, 0);
        service.logCompletion(
          category: CompletionCategory.goal,
          label: 'Ship feature',
          weight: 3.0,
          timestamp: ts,
        );
        expect(service.events.first.weight, 3.0);
        expect(service.events.first.timestamp, ts);
      });
    });

    group('phase classification', () {
      test('crashed when no activity for 5+ days', () {
        final now = DateTime(2026, 4, 28);
        service.logCompletion(
          category: CompletionCategory.task,
          label: 'Old task',
          timestamp: now.subtract(const Duration(days: 6)),
        );
        final phase = service.currentPhase(asOf: now);
        expect(phase, MomentumPhase.crashed);
      });

      test('stalling when no activity for 3-4 days', () {
        final now = DateTime(2026, 4, 28);
        service.logCompletion(
          category: CompletionCategory.task,
          label: 'Task',
          timestamp: now.subtract(const Duration(days: 4)),
        );
        final phase = service.currentPhase(asOf: now);
        expect(phase, MomentumPhase.stalling);
      });

      test('igniting when insufficient baseline data', () {
        final now = DateTime(2026, 4, 28);
        // Only 3 events in recent window
        for (int i = 0; i < 3; i++) {
          service.logCompletion(
            category: CompletionCategory.habit,
            label: 'Habit $i',
            timestamp: now.subtract(Duration(days: i)),
          );
        }
        final phase = service.currentPhase(asOf: now);
        expect(phase, MomentumPhase.igniting);
      });

      test('accelerating with strong recent velocity', () {
        final now = DateTime(2026, 4, 28);
        // Sparse baseline (long window)
        for (int i = 13; i >= 4; i--) {
          service.logCompletion(
            category: CompletionCategory.habit,
            label: 'H',
            timestamp: now.subtract(Duration(days: i)),
          );
        }
        // Dense recent (short window) - much higher than baseline
        for (int i = 2; i >= 0; i--) {
          for (int j = 0; j < 5; j++) {
            service.logCompletion(
              category: CompletionCategory.task,
              label: 'T$j',
              timestamp: now.subtract(Duration(days: i)),
            );
          }
        }
        final phase = service.currentPhase(asOf: now);
        expect(phase, MomentumPhase.accelerating);
      });

      test('coasting with declining velocity', () {
        final now = DateTime(2026, 4, 28);
        // Strong baseline in older period
        for (int i = 13; i >= 4; i--) {
          for (int j = 0; j < 4; j++) {
            service.logCompletion(
              category: CompletionCategory.habit,
              label: 'H$j',
              timestamp: now.subtract(Duration(days: i)),
            );
          }
        }
        // Weak recent
        for (int i = 2; i >= 0; i--) {
          service.logCompletion(
            category: CompletionCategory.habit,
            label: 'H',
            timestamp: now.subtract(Duration(days: i)),
          );
        }
        final phase = service.currentPhase(asOf: now);
        expect(phase, MomentumPhase.coasting);
      });
    });

    group('analyze', () {
      test('produces complete report', () {
        final now = DateTime(2026, 4, 28);
        for (int i = 13; i >= 0; i--) {
          service.logCompletion(
            category: CompletionCategory.habit,
            label: 'Daily',
            timestamp: now.subtract(Duration(days: i)),
          );
        }
        final report = service.analyze(asOf: now);
        expect(report.phase, isNotNull);
        expect(report.currentVelocity, greaterThan(0));
        expect(report.momentumScore, greaterThanOrEqualTo(0));
        expect(report.momentumScore, lessThanOrEqualTo(100));
        expect(report.nudges, isNotEmpty);
        expect(report.generatedAt, now);
      });

      test('momentum score is 0-100', () {
        final now = DateTime(2026, 4, 28);
        for (int i = 0; i < 20; i++) {
          service.logCompletion(
            category: CompletionCategory.task,
            label: 'T$i',
            timestamp: now.subtract(Duration(days: i % 14)),
          );
        }
        final report = service.analyze(asOf: now);
        expect(report.momentumScore, greaterThanOrEqualTo(0));
        expect(report.momentumScore, lessThanOrEqualTo(100));
      });

      test('stores blockers and nudges in history', () {
        final now = DateTime(2026, 4, 28);
        service.logCompletion(
          category: CompletionCategory.habit,
          label: 'H',
          timestamp: now.subtract(const Duration(days: 6)),
        );
        service.analyze(asOf: now);
        // Should have at least one nudge in history after crashed state
        expect(service.nudgeHistory, isNotEmpty);
      });
    });

    group('dailyTrend', () {
      test('returns correct daily counts', () {
        final now = DateTime(2026, 4, 28);
        service.logCompletion(
          category: CompletionCategory.habit,
          label: 'A',
          timestamp: now,
        );
        service.logCompletion(
          category: CompletionCategory.task,
          label: 'B',
          timestamp: now,
        );
        service.logCompletion(
          category: CompletionCategory.habit,
          label: 'C',
          timestamp: now.subtract(const Duration(days: 1)),
        );

        final trend = service.dailyTrend(days: 3, asOf: now);
        expect(trend.length, 3);
        expect(trend[2], 2); // today
        expect(trend[1], 1); // yesterday
        expect(trend[0], 0); // day before
      });
    });

    group('categoryBreakdown', () {
      test('counts by category within window', () {
        final now = DateTime(2026, 4, 28);
        service.logCompletion(
          category: CompletionCategory.habit,
          label: 'H1',
          timestamp: now.subtract(const Duration(days: 1)),
        );
        service.logCompletion(
          category: CompletionCategory.habit,
          label: 'H2',
          timestamp: now.subtract(const Duration(days: 2)),
        );
        service.logCompletion(
          category: CompletionCategory.task,
          label: 'T1',
          timestamp: now.subtract(const Duration(days: 1)),
        );
        service.logCompletion(
          category: CompletionCategory.goal,
          label: 'G1',
          timestamp: now.subtract(const Duration(days: 10)),
        );

        final breakdown = service.categoryBreakdown(days: 7, asOf: now);
        expect(breakdown[CompletionCategory.habit], 2);
        expect(breakdown[CompletionCategory.task], 1);
        expect(breakdown[CompletionCategory.goal], isNull); // outside 7-day window
      });
    });

    group('blocker detection', () {
      test('detects category abandonment', () {
        final now = DateTime(2026, 4, 28);
        // Active category in older window
        for (int i = 10; i >= 8; i--) {
          service.logCompletion(
            category: CompletionCategory.goal,
            label: 'Goal',
            timestamp: now.subtract(Duration(days: i)),
          );
        }
        // Recent activity only in habits
        for (int i = 6; i >= 0; i--) {
          service.logCompletion(
            category: CompletionCategory.habit,
            label: 'Habit',
            timestamp: now.subtract(Duration(days: i)),
          );
        }

        final report = service.analyze(asOf: now);
        final abandonBlockers = report.blockers
            .where((b) => b.type == BlockerType.categoryAbandonment);
        expect(abandonBlockers, isNotEmpty);
      });

      test('detects consistency drop', () {
        final now = DateTime(2026, 4, 28);
        // Strong baseline
        for (int i = 6; i >= 4; i--) {
          for (int j = 0; j < 5; j++) {
            service.logCompletion(
              category: CompletionCategory.task,
              label: 'T$j',
              timestamp: now.subtract(Duration(days: i)),
            );
          }
        }
        // Very weak recent
        service.logCompletion(
          category: CompletionCategory.task,
          label: 'T',
          timestamp: now.subtract(const Duration(days: 1)),
        );

        final report = service.analyze(asOf: now);
        final consistencyBlockers = report.blockers
            .where((b) => b.type == BlockerType.consistencyDrop);
        expect(consistencyBlockers, isNotEmpty);
      });
    });

    group('nudge generation', () {
      test('generates critical nudge for crashed state', () {
        final now = DateTime(2026, 4, 28);
        service.logCompletion(
          category: CompletionCategory.habit,
          label: 'Old',
          timestamp: now.subtract(const Duration(days: 7)),
        );
        final report = service.analyze(asOf: now);
        expect(report.phase, MomentumPhase.crashed);
        expect(
          report.nudges.any((n) => n.urgency == NudgeUrgency.critical),
          isTrue,
        );
      });

      test('generates encouraging nudge for igniting state', () {
        final now = DateTime(2026, 4, 28);
        for (int i = 0; i < 3; i++) {
          service.logCompletion(
            category: CompletionCategory.habit,
            label: 'H$i',
            timestamp: now.subtract(Duration(days: i)),
          );
        }
        final report = service.analyze(asOf: now);
        expect(report.phase, MomentumPhase.igniting);
        expect(
          report.nudges.any((n) => n.urgency == NudgeUrgency.encouraging),
          isTrue,
        );
      });
    });

    group('persistence', () {
      test('serializes and deserializes correctly', () {
        service.logCompletion(
          category: CompletionCategory.habit,
          label: 'Test',
          weight: 2.0,
          timestamp: DateTime(2026, 4, 20),
        );

        final json = service.toStorageJson();
        final restored = MomentumEngineService();
        restored.fromStorageJson(json);

        expect(restored.events.length, 1);
        expect(restored.events.first.label, 'Test');
        expect(restored.events.first.weight, 2.0);
        expect(restored.events.first.category, CompletionCategory.habit);
      });
    });

    group('topCategory', () {
      test('returns most active category', () {
        final now = DateTime(2026, 4, 28);
        service.logCompletion(
          category: CompletionCategory.habit,
          label: 'H',
          timestamp: now,
        );
        service.logCompletion(
          category: CompletionCategory.task,
          label: 'T1',
          timestamp: now,
        );
        service.logCompletion(
          category: CompletionCategory.task,
          label: 'T2',
          timestamp: now,
        );
        expect(service.topCategory(asOf: now), CompletionCategory.task);
      });

      test('returns null when no events', () {
        expect(service.topCategory(), isNull);
      });
    });

    group('reset', () {
      test('clears all data', () {
        service.logCompletion(
          category: CompletionCategory.habit,
          label: 'H',
        );
        service.analyze();
        service.reset();
        expect(service.events, isEmpty);
        expect(service.blockerHistory, isEmpty);
        expect(service.nudgeHistory, isEmpty);
      });
    });

    group('MomentumPhase properties', () {
      test('all phases have labels', () {
        for (final phase in MomentumPhase.values) {
          expect(phase.label, isNotEmpty);
          expect(phase.emoji, isNotEmpty);
          expect(phase.energyLevel, greaterThanOrEqualTo(0));
          expect(phase.energyLevel, lessThanOrEqualTo(100));
        }
      });

      test('healthy phases are correct', () {
        expect(MomentumPhase.igniting.isHealthy, isTrue);
        expect(MomentumPhase.accelerating.isHealthy, isTrue);
        expect(MomentumPhase.cruising.isHealthy, isTrue);
        expect(MomentumPhase.coasting.isHealthy, isFalse);
        expect(MomentumPhase.stalling.isHealthy, isFalse);
        expect(MomentumPhase.crashed.isHealthy, isFalse);
      });
    });

    group('CompletionEvent serialization', () {
      test('round-trips through JSON', () {
        final event = CompletionEvent(
          timestamp: DateTime(2026, 4, 25, 14, 30),
          category: CompletionCategory.milestone,
          label: 'Ship v2',
          weight: 5.0,
        );
        final json = event.toJson();
        final restored = CompletionEvent.fromJson(json);
        expect(restored.timestamp, event.timestamp);
        expect(restored.category, event.category);
        expect(restored.label, event.label);
        expect(restored.weight, event.weight);
      });
    });

    group('MomentumBlocker serialization', () {
      test('round-trips through JSON', () {
        final blocker = MomentumBlocker(
          type: BlockerType.overcommitment,
          confidence: 0.85,
          evidence: 'Too many items',
          detectedAt: DateTime(2026, 4, 28),
        );
        final json = blocker.toJson();
        final restored = MomentumBlocker.fromJson(json);
        expect(restored.type, blocker.type);
        expect(restored.confidence, blocker.confidence);
        expect(restored.evidence, blocker.evidence);
      });
    });

    group('MicroNudge serialization', () {
      test('round-trips through JSON', () {
        final nudge = MicroNudge(
          message: 'Test nudge',
          urgency: NudgeUrgency.urgent,
          targetCategory: CompletionCategory.habit,
          suggestedAction: 'Do something',
          generatedAt: DateTime(2026, 4, 28),
        );
        final json = nudge.toJson();
        final restored = MicroNudge.fromJson(json);
        expect(restored.message, nudge.message);
        expect(restored.urgency, nudge.urgency);
        expect(restored.targetCategory, nudge.targetCategory);
        expect(restored.suggestedAction, nudge.suggestedAction);
      });
    });
  });
}
