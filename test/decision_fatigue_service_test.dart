import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/decision_fatigue_service.dart';

void main() {
  group('DecisionFatigueService', () {
    late DecisionFatigueService service;
    final now = DateTime(2026, 4, 30, 14, 0); // 2pm

    setUp(() {
      service = DecisionFatigueService(maxDailyCapacity: 100.0);
    });

    // -----------------------------------------------------------------------
    // Basic Recording
    // -----------------------------------------------------------------------

    group('Event Recording', () {
      test('records decision events', () {
        service.recordDecision(DecisionEvent(
          id: '1',
          timestamp: now.subtract(const Duration(hours: 1)),
          description: 'Choose lunch restaurant',
          weight: DecisionWeight.minor,
          category: DecisionCategory.dietary,
        ));
        expect(service.events.length, 1);
      });

      test('getTodayEvents filters by day', () {
        service.recordDecision(DecisionEvent(
          id: '1',
          timestamp: now.subtract(const Duration(hours: 2)),
          description: 'Today decision',
          weight: DecisionWeight.trivial,
          category: DecisionCategory.dietary,
        ));
        service.recordDecision(DecisionEvent(
          id: '2',
          timestamp: now.subtract(const Duration(days: 2)),
          description: 'Yesterday decision',
          weight: DecisionWeight.trivial,
          category: DecisionCategory.dietary,
        ));
        expect(service.getTodayEvents(now: now).length, 1);
      });

      test('pending decisions can be added and cleared', () {
        service.addPendingDecision(
          description: 'Buy groceries',
          category: DecisionCategory.purchasing,
          weight: DecisionWeight.minor,
        );
        service.addPendingDecision(
          description: 'Buy shoes',
          category: DecisionCategory.purchasing,
          weight: DecisionWeight.moderate,
        );
        expect(service.generateBatchSuggestions().length, 1);
        service.clearPendingDecisions();
        expect(service.generateBatchSuggestions().length, 0);
      });
    });

    // -----------------------------------------------------------------------
    // Capacity Analysis
    // -----------------------------------------------------------------------

    group('Capacity State', () {
      test('starts at full capacity with no decisions', () {
        final state = service.getCapacityState(now: now);
        expect(state.currentCapacity, 100.0);
        expect(state.fatigueLevel, FatigueLevel.fresh);
        expect(state.decisionsToday, 0);
      });

      test('capacity decreases with decisions', () {
        // Add moderate decisions (cost = 5.0 each)
        for (int i = 0; i < 5; i++) {
          service.recordDecision(DecisionEvent(
            id: 'mod_$i',
            timestamp: now.subtract(Duration(minutes: 60 - i * 10)),
            description: 'Decision $i',
            weight: DecisionWeight.moderate,
            category: DecisionCategory.professional,
          ));
        }
        final state = service.getCapacityState(now: now);
        // 5 * 5.0 = 25 cost, capacity = 75
        expect(state.currentCapacity, 75.0);
        expect(state.totalCostToday, 25.0);
        expect(state.decisionsToday, 5);
      });

      test('fatigue level classified correctly', () {
        // Add enough to drop to 15% capacity
        // 17 * 5 = 85 cost => 15 capacity => fatigued
        for (int i = 0; i < 17; i++) {
          service.recordDecision(DecisionEvent(
            id: 'heavy_$i',
            timestamp: now.subtract(Duration(minutes: 60 - i * 3)),
            description: 'Decision $i',
            weight: DecisionWeight.moderate,
            category: DecisionCategory.professional,
          ));
        }
        final state = service.getCapacityState(now: now);
        expect(state.fatigueLevel, FatigueLevel.fatigued);
      });

      test('critical decisions drain capacity faster', () {
        service.recordDecision(DecisionEvent(
          id: 'crit_1',
          timestamp: now.subtract(const Duration(minutes: 30)),
          description: 'Major career decision',
          weight: DecisionWeight.critical,
          category: DecisionCategory.professional,
        ));
        final state = service.getCapacityState(now: now);
        // cost 20 => capacity 80
        expect(state.currentCapacity, 80.0);
      });

      test('quality estimate degrades with capacity', () {
        final freshState = service.getCapacityState(now: now);

        // Drain heavily
        for (int i = 0; i < 18; i++) {
          service.recordDecision(DecisionEvent(
            id: 'drain_$i',
            timestamp: now.subtract(Duration(minutes: 55 - i * 3)),
            description: 'Decision $i',
            weight: DecisionWeight.moderate,
            category: DecisionCategory.scheduling,
          ));
        }
        final tiredState = service.getCapacityState(now: now);
        expect(tiredState.qualityEstimate, lessThan(freshState.qualityEstimate));
      });
    });

    // -----------------------------------------------------------------------
    // Fatigue Signal Detection
    // -----------------------------------------------------------------------

    group('Fatigue Signals', () {
      test('no signals with few events', () {
        service.recordDecision(DecisionEvent(
          id: '1',
          timestamp: now.subtract(const Duration(minutes: 10)),
          description: 'Simple decision',
          weight: DecisionWeight.trivial,
          category: DecisionCategory.dietary,
        ));
        expect(service.detectFatigueSignals(now: now), isEmpty);
      });

      test('detects decision speed drop', () {
        // First 4 decisions: fast (10s)
        for (int i = 0; i < 4; i++) {
          service.recordDecision(DecisionEvent(
            id: 'fast_$i',
            timestamp: now.subtract(Duration(minutes: 60 - i * 5)),
            description: 'Fast decision $i',
            weight: DecisionWeight.minor,
            category: DecisionCategory.scheduling,
            deliberationTime: const Duration(seconds: 10),
          ));
        }
        // Last 4 decisions: slow (30s — 3x slower, > 1.6x threshold)
        for (int i = 0; i < 4; i++) {
          service.recordDecision(DecisionEvent(
            id: 'slow_$i',
            timestamp: now.subtract(Duration(minutes: 30 - i * 5)),
            description: 'Slow decision $i',
            weight: DecisionWeight.minor,
            category: DecisionCategory.scheduling,
            deliberationTime: const Duration(seconds: 30),
          ));
        }
        final signals = service.detectFatigueSignals(now: now);
        expect(
            signals.any((s) => s.type == FatigueSignalType.decisionSpeedDrop),
            isTrue);
      });

      test('detects choice avoidance', () {
        for (int i = 0; i < 5; i++) {
          service.recordDecision(DecisionEvent(
            id: 'avoid_$i',
            timestamp: now.subtract(Duration(minutes: 50 - i * 10)),
            description: 'Deferred decision $i',
            weight: DecisionWeight.moderate,
            category: DecisionCategory.professional,
            wasDeferred: i < 3, // 3/5 = 60% deferral
          ));
        }
        final signals = service.detectFatigueSignals(now: now);
        expect(
            signals.any((s) => s.type == FatigueSignalType.choiceAvoidance),
            isTrue);
      });

      test('detects default bias', () {
        for (int i = 0; i < 5; i++) {
          service.recordDecision(DecisionEvent(
            id: 'def_$i',
            timestamp: now.subtract(Duration(minutes: 50 - i * 10)),
            description: 'Default decision $i',
            weight: DecisionWeight.minor,
            category: DecisionCategory.dietary,
            usedDefault: i < 4, // 4/5 = 80%
          ));
        }
        final signals = service.detectFatigueSignals(now: now);
        expect(
            signals.any((s) => s.type == FatigueSignalType.defaultBias),
            isTrue);
      });

      test('detects impulsive choice on significant decisions', () {
        for (int i = 0; i < 4; i++) {
          service.recordDecision(DecisionEvent(
            id: 'imp_$i',
            timestamp: now.subtract(Duration(minutes: 40 - i * 10)),
            description: 'Quick significant decision $i',
            weight: DecisionWeight.significant,
            category: DecisionCategory.financial,
            deliberationTime: const Duration(seconds: 5), // < 10s
          ));
        }
        final signals = service.detectFatigueSignals(now: now);
        expect(
            signals.any((s) => s.type == FatigueSignalType.impulsiveChoice),
            isTrue);
      });

      test('detects reversal frequency', () {
        for (int i = 0; i < 5; i++) {
          service.recordDecision(DecisionEvent(
            id: 'rev_$i',
            timestamp: now.subtract(Duration(minutes: 50 - i * 10)),
            description: 'Reversed decision $i',
            weight: DecisionWeight.minor,
            category: DecisionCategory.scheduling,
            wasReversed: i < 3, // 3/5 = 60%
          ));
        }
        final signals = service.detectFatigueSignals(now: now);
        expect(
            signals.any((s) => s.type == FatigueSignalType.reversalFrequency),
            isTrue);
      });

      test('detects deliberation collapse', () {
        // First 4: many options considered
        for (int i = 0; i < 4; i++) {
          service.recordDecision(DecisionEvent(
            id: 'rich_$i',
            timestamp: now.subtract(Duration(minutes: 60 - i * 5)),
            description: 'Rich deliberation $i',
            weight: DecisionWeight.moderate,
            category: DecisionCategory.purchasing,
            optionsConsidered: 5,
          ));
        }
        // Last 4: barely considering options
        for (int i = 0; i < 4; i++) {
          service.recordDecision(DecisionEvent(
            id: 'poor_$i',
            timestamp: now.subtract(Duration(minutes: 30 - i * 5)),
            description: 'Collapsed deliberation $i',
            weight: DecisionWeight.moderate,
            category: DecisionCategory.purchasing,
            optionsConsidered: 1,
          ));
        }
        final signals = service.detectFatigueSignals(now: now);
        expect(
            signals.any(
                (s) => s.type == FatigueSignalType.deliberationCollapse),
            isTrue);
      });

      test('detects category switching', () {
        final categories = [
          DecisionCategory.scheduling,
          DecisionCategory.financial,
          DecisionCategory.social,
          DecisionCategory.dietary,
          DecisionCategory.health,
          DecisionCategory.logistics,
        ];
        for (int i = 0; i < 6; i++) {
          service.recordDecision(DecisionEvent(
            id: 'switch_$i',
            timestamp: now.subtract(Duration(minutes: 60 - i * 10)),
            description: 'Category switch $i',
            weight: DecisionWeight.minor,
            category: categories[i],
          ));
        }
        final signals = service.detectFatigueSignals(now: now);
        expect(
            signals.any((s) => s.type == FatigueSignalType.categorySwitch),
            isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Peak Windows
    // -----------------------------------------------------------------------

    group('Peak Windows', () {
      test('returns empty with insufficient data', () {
        expect(service.identifyPeakWindows(), isEmpty);
      });

      test('identifies peak windows from historical data', () {
        // Simulate good morning decisions over multiple days
        for (int day = 0; day < 5; day++) {
          for (int hour = 8; hour < 12; hour++) {
            service.recordDecision(DecisionEvent(
              id: 'peak_d${day}_h$hour',
              timestamp: now.subtract(Duration(days: day, hours: now.hour - hour)),
              description: 'Morning decision',
              weight: DecisionWeight.moderate,
              category: DecisionCategory.professional,
              satisfactionScore: 8.0,
              optionsConsidered: 4,
            ));
          }
          // Afternoon: lower quality
          for (int hour = 14; hour < 17; hour++) {
            service.recordDecision(DecisionEvent(
              id: 'low_d${day}_h$hour',
              timestamp: now.subtract(Duration(days: day, hours: now.hour - hour)),
              description: 'Afternoon decision',
              weight: DecisionWeight.moderate,
              category: DecisionCategory.professional,
              satisfactionScore: 4.0,
              wasReversed: true,
            ));
          }
        }
        final peaks = service.identifyPeakWindows();
        expect(peaks, isNotEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // Batch Suggestions
    // -----------------------------------------------------------------------

    group('Batch Suggestions', () {
      test('no suggestions with no pending decisions', () {
        expect(service.generateBatchSuggestions(), isEmpty);
      });

      test('groups similar pending decisions', () {
        service.addPendingDecision(
          description: 'Buy groceries',
          category: DecisionCategory.purchasing,
          weight: DecisionWeight.minor,
        );
        service.addPendingDecision(
          description: 'Buy birthday gift',
          category: DecisionCategory.purchasing,
          weight: DecisionWeight.moderate,
        );
        service.addPendingDecision(
          description: 'Schedule dentist',
          category: DecisionCategory.health,
          weight: DecisionWeight.minor,
        );
        final suggestions = service.generateBatchSuggestions();
        expect(suggestions.length, 1); // only purchasing has 2+
        expect(suggestions.first.category, DecisionCategory.purchasing);
        expect(suggestions.first.pendingDecisions.length, 2);
      });

      test('estimates time savings for batches', () {
        for (int i = 0; i < 4; i++) {
          service.addPendingDecision(
            description: 'Financial decision $i',
            category: DecisionCategory.financial,
            weight: DecisionWeight.moderate,
          );
        }
        final suggestions = service.generateBatchSuggestions();
        expect(suggestions.first.estimatedTimeSavedMinutes, 10.0); // 4 * 2.5
      });
    });

    // -----------------------------------------------------------------------
    // Recommendations
    // -----------------------------------------------------------------------

    group('Recommendations', () {
      test('recommends deferral when fatigued', () {
        // Drain to fatigued level
        for (int i = 0; i < 17; i++) {
          service.recordDecision(DecisionEvent(
            id: 'drain_$i',
            timestamp: now.subtract(Duration(minutes: 60 - i * 3)),
            description: 'Draining decision $i',
            weight: DecisionWeight.moderate,
            category: DecisionCategory.professional,
          ));
        }
        final recs = service.generateRecommendations(now: now);
        expect(
            recs.any((r) => r.type == RecommendationType.deferHeavy), isTrue);
      });

      test('recommends option elimination when mildly tired', () {
        // Drain to mildlyTired (40-60% capacity)
        // 8 * 5 = 40 cost => 60% capacity border
        for (int i = 0; i < 9; i++) {
          service.recordDecision(DecisionEvent(
            id: 'mild_$i',
            timestamp: now.subtract(Duration(minutes: 60 - i * 5)),
            description: 'Decision $i',
            weight: DecisionWeight.moderate,
            category: DecisionCategory.professional,
          ));
        }
        final recs = service.generateRecommendations(now: now);
        expect(
            recs.any((r) => r.type == RecommendationType.eliminateOptions),
            isTrue);
      });

      test('recommendations sorted by urgency', () {
        for (int i = 0; i < 17; i++) {
          service.recordDecision(DecisionEvent(
            id: 'urg_$i',
            timestamp: now.subtract(Duration(minutes: 55 - i * 3)),
            description: 'Decision $i',
            weight: DecisionWeight.moderate,
            category: DecisionCategory.professional,
          ));
        }
        final recs = service.generateRecommendations(now: now);
        if (recs.length >= 2) {
          expect(recs.first.urgency, greaterThanOrEqualTo(recs.last.urgency));
        }
      });
    });

    // -----------------------------------------------------------------------
    // Insights
    // -----------------------------------------------------------------------

    group('Insights', () {
      test('generates insight about no decisions', () {
        final insights = service.generateInsights(now: now);
        expect(insights.any((i) => i.contains('No decisions recorded')), isTrue);
      });

      test('identifies most active category', () {
        for (int i = 0; i < 4; i++) {
          service.recordDecision(DecisionEvent(
            id: 'cat_$i',
            timestamp: now.subtract(Duration(minutes: 40 - i * 10)),
            description: 'Financial $i',
            weight: DecisionWeight.minor,
            category: DecisionCategory.financial,
          ));
        }
        service.recordDecision(DecisionEvent(
          id: 'other',
          timestamp: now.subtract(const Duration(minutes: 5)),
          description: 'Other',
          weight: DecisionWeight.trivial,
          category: DecisionCategory.dietary,
        ));
        final insights = service.generateInsights(now: now);
        expect(insights.any((i) => i.contains('Financial')), isTrue);
      });

      test('reports decision pace', () {
        for (int i = 0; i < 5; i++) {
          service.recordDecision(DecisionEvent(
            id: 'pace_$i',
            timestamp: now.subtract(Duration(minutes: 50 - i * 10)),
            description: 'Paced $i',
            weight: DecisionWeight.trivial,
            category: DecisionCategory.scheduling,
          ));
        }
        final insights = service.generateInsights(now: now);
        expect(insights.any((i) => i.contains('decisions/hour')), isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Full Report
    // -----------------------------------------------------------------------

    group('Full Report', () {
      test('generates comprehensive report', () {
        for (int i = 0; i < 10; i++) {
          service.recordDecision(DecisionEvent(
            id: 'report_$i',
            timestamp: now.subtract(Duration(minutes: 100 - i * 10)),
            description: 'Decision $i',
            weight: i < 3
                ? DecisionWeight.significant
                : DecisionWeight.moderate,
            category: DecisionCategory.values[i % DecisionCategory.values.length],
            satisfactionScore: 7.0 - (i * 0.5),
          ));
        }
        final report = service.generateReport(now: now);
        expect(report.capacity, isNotNull);
        expect(report.overallFatigueScore, greaterThanOrEqualTo(0));
        expect(report.overallFatigueScore, lessThanOrEqualTo(100));
        expect(report.insights, isNotEmpty);
        expect(report.generatedAt, now);
      });

      test('fatigue score increases with signals and low capacity', () {
        // Fresh state
        final freshReport = service.generateReport(now: now);

        // Heavy usage
        for (int i = 0; i < 15; i++) {
          service.recordDecision(DecisionEvent(
            id: 'heavy_$i',
            timestamp: now.subtract(Duration(minutes: 55 - i * 3)),
            description: 'Heavy decision $i',
            weight: DecisionWeight.moderate,
            category: DecisionCategory.professional,
            wasReversed: i > 10,
          ));
        }
        final tiredReport = service.generateReport(now: now);
        expect(tiredReport.overallFatigueScore,
            greaterThan(freshReport.overallFatigueScore));
      });
    });

    // -----------------------------------------------------------------------
    // Serialization
    // -----------------------------------------------------------------------

    group('Serialization', () {
      test('round-trips through JSON', () {
        service.recordDecision(DecisionEvent(
          id: 'ser_1',
          timestamp: now.subtract(const Duration(minutes: 30)),
          description: 'Test decision',
          weight: DecisionWeight.significant,
          category: DecisionCategory.financial,
          optionsConsidered: 4,
          deliberationTime: const Duration(seconds: 90),
          wasReversed: true,
          satisfactionScore: 6.5,
        ));
        service.addPendingDecision(
          description: 'Pending thing',
          category: DecisionCategory.purchasing,
          weight: DecisionWeight.minor,
        );

        final json = service.export();
        final restored = DecisionFatigueService.import(json);

        expect(restored.events.length, 1);
        expect(restored.events.first.id, 'ser_1');
        expect(restored.events.first.weight, DecisionWeight.significant);
        expect(restored.events.first.wasReversed, isTrue);
        expect(restored.events.first.satisfactionScore, 6.5);
      });

      test('toJson produces valid structure', () {
        service.recordDecision(DecisionEvent(
          id: 'json_1',
          timestamp: now,
          description: 'Test',
          weight: DecisionWeight.trivial,
          category: DecisionCategory.dietary,
        ));
        final map = service.toJson();
        expect(map.containsKey('events'), isTrue);
        expect(map.containsKey('maxDailyCapacity'), isTrue);
        expect(map['maxDailyCapacity'], 100.0);
      });
    });

    // -----------------------------------------------------------------------
    // Enums
    // -----------------------------------------------------------------------

    group('Enums', () {
      test('DecisionWeight costs are ordered', () {
        expect(DecisionWeight.trivial.cost, lessThan(DecisionWeight.minor.cost));
        expect(DecisionWeight.minor.cost, lessThan(DecisionWeight.moderate.cost));
        expect(
            DecisionWeight.moderate.cost, lessThan(DecisionWeight.significant.cost));
        expect(DecisionWeight.significant.cost,
            lessThan(DecisionWeight.critical.cost));
      });

      test('FatigueLevel thresholds are descending', () {
        expect(FatigueLevel.fresh.capacityThreshold,
            greaterThan(FatigueLevel.alert.capacityThreshold));
        expect(FatigueLevel.alert.capacityThreshold,
            greaterThan(FatigueLevel.mildlyTired.capacityThreshold));
      });

      test('all enums have labels', () {
        for (final w in DecisionWeight.values) {
          expect(w.label, isNotEmpty);
        }
        for (final c in DecisionCategory.values) {
          expect(c.label, isNotEmpty);
          expect(c.emoji, isNotEmpty);
        }
        for (final f in FatigueLevel.values) {
          expect(f.label, isNotEmpty);
        }
        for (final s in FatigueSignalType.values) {
          expect(s.label, isNotEmpty);
          expect(s.description, isNotEmpty);
        }
        for (final r in RecommendationType.values) {
          expect(r.label, isNotEmpty);
          expect(r.emoji, isNotEmpty);
        }
      });
    });

    // -----------------------------------------------------------------------
    // Edge Cases
    // -----------------------------------------------------------------------

    group('Edge Cases', () {
      test('handles empty events gracefully', () {
        final state = service.getCapacityState(now: now);
        expect(state.decisionsToday, 0);
        expect(state.fatigueLevel, FatigueLevel.fresh);

        final report = service.generateReport(now: now);
        expect(report.overallFatigueScore, 0.0);
      });

      test('capacity never goes negative', () {
        for (int i = 0; i < 10; i++) {
          service.recordDecision(DecisionEvent(
            id: 'over_$i',
            timestamp: now.subtract(Duration(minutes: 30 - i * 3)),
            description: 'Critical $i',
            weight: DecisionWeight.critical, // 20 each = 200 total
            category: DecisionCategory.professional,
          ));
        }
        final state = service.getCapacityState(now: now);
        expect(state.currentCapacity, greaterThanOrEqualTo(0));
        expect(state.capacityPercent, greaterThanOrEqualTo(0));
      });

      test('single event does not trigger signals', () {
        service.recordDecision(DecisionEvent(
          id: 'single',
          timestamp: now.subtract(const Duration(minutes: 5)),
          description: 'One decision',
          weight: DecisionWeight.critical,
          category: DecisionCategory.financial,
          wasReversed: true,
          wasDeferred: true,
          usedDefault: true,
        ));
        expect(service.detectFatigueSignals(now: now), isEmpty);
      });
    });
  });
}
