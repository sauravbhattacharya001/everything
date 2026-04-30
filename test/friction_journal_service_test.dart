import 'package:test/test.dart';
import '../lib/core/services/friction_journal_service.dart';

void main() {
  late FrictionJournalService service;

  setUp(() {
    service = FrictionJournalService();
  });

  group('FrictionCategory', () {
    test('all categories have labels and emojis', () {
      for (final cat in FrictionCategory.values) {
        expect(cat.label, isNotEmpty);
        expect(cat.emoji, isNotEmpty);
        expect(cat.typicalEffort, greaterThan(0));
        expect(cat.toleranceDecayRate, greaterThan(0));
        expect(cat.toleranceDecayRate, lessThan(1));
      }
    });
  });

  group('FrictionSeverity', () {
    test('weights increase with severity', () {
      expect(FrictionSeverity.minor.weight, lessThan(FrictionSeverity.moderate.weight));
      expect(FrictionSeverity.moderate.weight, lessThan(FrictionSeverity.major.weight));
      expect(FrictionSeverity.major.weight, lessThan(FrictionSeverity.critical.weight));
    });
  });

  group('FrictionEntry', () {
    test('impactScore increases with prior occurrences', () {
      final entry = FrictionEntry(
        id: 'test1',
        timestamp: DateTime.now(),
        category: FrictionCategory.technology,
        severity: FrictionSeverity.moderate,
        timeSlot: FrictionTimeSlot.morning,
        description: 'Slow build',
      );
      final score0 = entry.impactScore(0);
      final score5 = entry.impactScore(5);
      final score10 = entry.impactScore(10);
      expect(score5, greaterThan(score0));
      expect(score10, greaterThan(score5));
    });

    test('toJson contains all fields', () {
      final entry = FrictionEntry(
        id: 'test1',
        timestamp: DateTime(2026, 4, 30, 10, 0),
        category: FrictionCategory.commute,
        severity: FrictionSeverity.major,
        timeSlot: FrictionTimeSlot.earlyMorning,
        description: 'Traffic jam',
        trigger: 'Construction',
        location: 'Highway 99',
        activity: 'Driving to work',
        durationLost: Duration(minutes: 25),
      );
      final json = entry.toJson();
      expect(json['id'], 'test1');
      expect(json['category'], 'commute');
      expect(json['severity'], 'major');
      expect(json['trigger'], 'Construction');
      expect(json['durationLostMinutes'], 25);
    });
  });

  group('Logging friction', () {
    test('logFriction adds entry', () {
      service.logFriction(
        category: FrictionCategory.technology,
        severity: FrictionSeverity.moderate,
        timeSlot: FrictionTimeSlot.morning,
        description: 'IDE crashed',
        trigger: 'Memory leak',
      );
      expect(service.entries.length, 1);
      expect(service.entries.first.description, 'IDE crashed');
    });

    test('logFriction generates unique ids', () {
      service.logFriction(
        category: FrictionCategory.work,
        severity: FrictionSeverity.minor,
        timeSlot: FrictionTimeSlot.afternoon,
        description: 'Annoying meeting',
      );
      service.logFriction(
        category: FrictionCategory.work,
        severity: FrictionSeverity.minor,
        timeSlot: FrictionTimeSlot.afternoon,
        description: 'Another meeting',
      );
      expect(service.entries[0].id, isNot(service.entries[1].id));
    });

    test('logFriction accepts custom timestamp', () {
      final customTime = DateTime(2026, 1, 15, 9, 30);
      service.logFriction(
        category: FrictionCategory.health,
        severity: FrictionSeverity.moderate,
        timeSlot: FrictionTimeSlot.morning,
        description: 'Bad sleep',
        timestamp: customTime,
      );
      expect(service.entries.first.timestamp, customTime);
    });
  });

  group('Resolve entry', () {
    test('resolveEntry marks entry as resolved', () {
      service.logFriction(
        category: FrictionCategory.home,
        severity: FrictionSeverity.minor,
        timeSlot: FrictionTimeSlot.evening,
        description: 'Leaky faucet',
        trigger: 'Old washer',
      );
      final id = service.entries.first.id;
      service.resolveEntry(id, 'Replaced the washer');
      expect(service.entries.first.resolved, isTrue);
      expect(service.entries.first.resolution, 'Replaced the washer');
    });

    test('resolveEntry with invalid id does nothing', () {
      service.logFriction(
        category: FrictionCategory.finance,
        severity: FrictionSeverity.moderate,
        timeSlot: FrictionTimeSlot.afternoon,
        description: 'Fee charged',
      );
      service.resolveEntry('nonexistent', 'N/A');
      expect(service.entries.first.resolved, isFalse);
    });
  });

  group('Pattern detection', () {
    test('detects pattern after 2+ entries with same trigger', () {
      for (int i = 0; i < 3; i++) {
        service.logFriction(
          category: FrictionCategory.technology,
          severity: FrictionSeverity.moderate,
          timeSlot: FrictionTimeSlot.morning,
          description: 'Slow compile $i',
          trigger: 'Webpack',
        );
      }
      expect(service.patterns.length, 1);
      expect(service.patterns.first.commonTrigger, 'Webpack');
      expect(service.patterns.first.confidence, PatternConfidence.emerging);
    });

    test('confidence upgrades with more entries', () {
      for (int i = 0; i < 5; i++) {
        service.logFriction(
          category: FrictionCategory.commute,
          severity: FrictionSeverity.moderate,
          timeSlot: FrictionTimeSlot.earlyMorning,
          description: 'Traffic $i',
          trigger: 'Rush hour',
        );
      }
      expect(service.patterns.first.confidence, PatternConfidence.probable);

      for (int i = 0; i < 3; i++) {
        service.logFriction(
          category: FrictionCategory.commute,
          severity: FrictionSeverity.moderate,
          timeSlot: FrictionTimeSlot.earlyMorning,
          description: 'More traffic $i',
          trigger: 'Rush hour',
        );
      }
      expect(service.patterns.first.confidence, PatternConfidence.confirmed);
    });

    test('chronic pattern detected at 11+ entries', () {
      for (int i = 0; i < 12; i++) {
        service.logFriction(
          category: FrictionCategory.bureaucracy,
          severity: FrictionSeverity.minor,
          timeSlot: FrictionTimeSlot.afternoon,
          description: 'Form $i',
          trigger: 'Expense reports',
        );
      }
      expect(service.patterns.first.confidence, PatternConfidence.chronic);
    });

    test('patterns sorted by urgency', () {
      // Low urgency: few minor entries
      for (int i = 0; i < 3; i++) {
        service.logFriction(
          category: FrictionCategory.home,
          severity: FrictionSeverity.minor,
          timeSlot: FrictionTimeSlot.evening,
          description: 'Clutter $i',
          trigger: 'Mail pile',
        );
      }
      // High urgency: many critical entries
      for (int i = 0; i < 8; i++) {
        service.logFriction(
          category: FrictionCategory.technology,
          severity: FrictionSeverity.critical,
          timeSlot: FrictionTimeSlot.morning,
          description: 'Crash $i',
          trigger: 'Memory leak',
        );
      }
      expect(service.patterns.first.commonTrigger, 'Memory leak');
    });

    test('tolerance decays with occurrences', () {
      for (int i = 0; i < 5; i++) {
        service.logFriction(
          category: FrictionCategory.technology,
          severity: FrictionSeverity.moderate,
          timeSlot: FrictionTimeSlot.morning,
          description: 'Bug $i',
          trigger: 'Flaky test',
        );
      }
      final tolerance = service.patterns.first.toleranceRemaining;
      expect(tolerance, lessThan(0.5));
    });

    test('suggests strategies based on category', () {
      for (int i = 0; i < 3; i++) {
        service.logFriction(
          category: FrictionCategory.bureaucracy,
          severity: FrictionSeverity.moderate,
          timeSlot: FrictionTimeSlot.afternoon,
          description: 'Paperwork $i',
          trigger: 'Tax forms',
        );
      }
      final strategies = service.patterns.first.suggestedStrategies;
      expect(strategies, contains(EliminationStrategy.batch));
    });
  });

  group('Elimination planning', () {
    test('generatePlan creates actionable plan', () {
      for (int i = 0; i < 4; i++) {
        service.logFriction(
          category: FrictionCategory.technology,
          severity: FrictionSeverity.moderate,
          timeSlot: FrictionTimeSlot.morning,
          description: 'Deploy $i',
          trigger: 'Manual deployment',
        );
      }
      final plan = service.generatePlan(service.patterns.first.id);
      expect(plan.strategy, EliminationStrategy.automate);
      expect(plan.steps, isNotEmpty);
      expect(plan.estimatedEffortHours, greaterThan(0));
      expect(plan.expectedReduction, greaterThan(0));
      expect(plan.roi, greaterThan(0));
    });

    test('plan ROI calculated correctly', () {
      for (int i = 0; i < 3; i++) {
        service.logFriction(
          category: FrictionCategory.home,
          severity: FrictionSeverity.minor,
          timeSlot: FrictionTimeSlot.evening,
          description: 'Dish $i',
          trigger: 'Dirty dishes',
        );
      }
      final plan = service.generatePlan(service.patterns.first.id);
      expect(plan.roi, plan.expectedReduction / plan.estimatedEffortHours);
    });
  });

  group('Daily scoring', () {
    test('empty day scores 0', () {
      expect(service.calculateDailyScore(DateTime(2026, 4, 30)), 0.0);
    });

    test('single minor entry scores low', () {
      service.logFriction(
        category: FrictionCategory.home,
        severity: FrictionSeverity.minor,
        timeSlot: FrictionTimeSlot.morning,
        description: 'Stubbed toe',
        timestamp: DateTime(2026, 4, 30, 10, 0),
      );
      final score = service.calculateDailyScore(DateTime(2026, 4, 30));
      expect(score, lessThan(10));
      expect(score, greaterThan(0));
    });

    test('multiple critical entries score high', () {
      for (int i = 0; i < 5; i++) {
        service.logFriction(
          category: FrictionCategory.work,
          severity: FrictionSeverity.critical,
          timeSlot: FrictionTimeSlot.afternoon,
          description: 'Crisis $i',
          trigger: 'Server down',
          timestamp: DateTime(2026, 4, 30, 14, i),
        );
      }
      final score = service.calculateDailyScore(DateTime(2026, 4, 30));
      expect(score, greaterThan(50));
    });

    test('score capped at 100', () {
      for (int i = 0; i < 20; i++) {
        service.logFriction(
          category: FrictionCategory.work,
          severity: FrictionSeverity.critical,
          timeSlot: FrictionTimeSlot.afternoon,
          description: 'Disaster $i',
          trigger: 'Everything broken',
          timestamp: DateTime(2026, 4, 30, 14, i),
        );
      }
      final score = service.calculateDailyScore(DateTime(2026, 4, 30));
      expect(score, 100.0);
    });
  });

  group('Daily report', () {
    test('generates report with insights', () {
      service.logFriction(
        category: FrictionCategory.technology,
        severity: FrictionSeverity.critical,
        timeSlot: FrictionTimeSlot.morning,
        description: 'Build failed',
        trigger: 'Dependency conflict',
        durationLost: Duration(minutes: 45),
        timestamp: DateTime(2026, 4, 30, 9, 0),
      );
      service.logFriction(
        category: FrictionCategory.social,
        severity: FrictionSeverity.moderate,
        timeSlot: FrictionTimeSlot.afternoon,
        description: 'Pointless meeting',
        durationLost: Duration(minutes: 30),
        timestamp: DateTime(2026, 4, 30, 14, 0),
      );

      final report = service.generateDailyReport(DateTime(2026, 4, 30));
      expect(report.entries.length, 2);
      expect(report.frictionScore, greaterThan(0));
      expect(report.totalTimeLost.inMinutes, 75);
      expect(report.insights, isNotEmpty);
    });

    test('empty day report has celebration insight', () {
      final report = service.generateDailyReport(DateTime(2026, 5, 1));
      expect(report.entries, isEmpty);
      expect(report.insights.first, contains('Friction-free'));
    });
  });

  group('Velocity calculation', () {
    test('insufficient data returns stable', () {
      service.logFriction(
        category: FrictionCategory.work,
        severity: FrictionSeverity.minor,
        timeSlot: FrictionTimeSlot.morning,
        description: 'Minor thing',
      );
      final velocity = service.calculateVelocity();
      expect(velocity.phase, FrictionVelocityPhase.stable);
      expect(velocity.forecast, contains('Insufficient data'));
    });

    test('velocity computed with sufficient entries', () {
      final now = DateTime.now();
      for (int i = 0; i < 10; i++) {
        service.logFriction(
          category: FrictionCategory.work,
          severity: FrictionSeverity.minor,
          timeSlot: FrictionTimeSlot.morning,
          description: 'Entry $i',
          trigger: 'Daily standup',
          timestamp: now.subtract(Duration(days: i)),
        );
      }
      final velocity = service.calculateVelocity();
      expect(velocity.weeklyRate, greaterThan(0));
    });
  });

  group('Category analysis', () {
    test('analyzeCategoriesBreakdown returns correct counts', () {
      service.logFriction(
        category: FrictionCategory.technology,
        severity: FrictionSeverity.moderate,
        timeSlot: FrictionTimeSlot.morning,
        description: 'Bug 1',
      );
      service.logFriction(
        category: FrictionCategory.technology,
        severity: FrictionSeverity.major,
        timeSlot: FrictionTimeSlot.afternoon,
        description: 'Bug 2',
      );
      service.logFriction(
        category: FrictionCategory.home,
        severity: FrictionSeverity.minor,
        timeSlot: FrictionTimeSlot.evening,
        description: 'Mess',
      );

      final breakdown = service.analyzeCategoriesBreakdown();
      expect(breakdown[FrictionCategory.technology]!.entryCount, 2);
      expect(breakdown[FrictionCategory.home]!.entryCount, 1);
      expect(breakdown.containsKey(FrictionCategory.finance), isFalse);
    });
  });

  group('Top priorities', () {
    test('getTopPriorities returns highest urgency patterns', () {
      for (int i = 0; i < 5; i++) {
        service.logFriction(
          category: FrictionCategory.technology,
          severity: FrictionSeverity.critical,
          timeSlot: FrictionTimeSlot.morning,
          description: 'Critical $i',
          trigger: 'Production bug',
        );
      }
      for (int i = 0; i < 3; i++) {
        service.logFriction(
          category: FrictionCategory.home,
          severity: FrictionSeverity.minor,
          timeSlot: FrictionTimeSlot.evening,
          description: 'Minor $i',
          trigger: 'Dirty dishes',
        );
      }
      final priorities = service.getTopPriorities(count: 2);
      expect(priorities.length, 2);
      expect(priorities.first.commonTrigger, 'Production bug');
    });
  });

  group('Unresolved entries', () {
    test('getUnresolved returns only unresolved', () {
      service.logFriction(
        category: FrictionCategory.work,
        severity: FrictionSeverity.moderate,
        timeSlot: FrictionTimeSlot.morning,
        description: 'Issue 1',
      );
      service.logFriction(
        category: FrictionCategory.work,
        severity: FrictionSeverity.minor,
        timeSlot: FrictionTimeSlot.afternoon,
        description: 'Issue 2',
      );
      service.resolveEntry(service.entries.first.id, 'Fixed');
      expect(service.getUnresolved().length, 1);
      expect(service.getUnresolved().first.description, 'Issue 2');
    });
  });

  group('Autonomous insights', () {
    test('empty state suggests logging', () {
      final insights = service.generateAutonomousInsights();
      expect(insights.first, contains('Start logging'));
    });

    test('generates insights with data', () {
      for (int i = 0; i < 12; i++) {
        service.logFriction(
          category: FrictionCategory.technology,
          severity: FrictionSeverity.moderate,
          timeSlot: FrictionTimeSlot.morning,
          description: 'Slow build $i',
          trigger: 'Webpack',
          timestamp: DateTime.now().subtract(Duration(days: i)),
        );
      }
      final insights = service.generateAutonomousInsights();
      expect(insights.length, greaterThan(1));
      expect(insights.any((i) => i.contains('CHRONIC')), isTrue);
    });

    test('insights include velocity forecast', () {
      for (int i = 0; i < 10; i++) {
        service.logFriction(
          category: FrictionCategory.work,
          severity: FrictionSeverity.minor,
          timeSlot: FrictionTimeSlot.afternoon,
          description: 'Meeting $i',
          trigger: 'Standup',
          timestamp: DateTime.now().subtract(Duration(days: i)),
        );
      }
      final insights = service.generateAutonomousInsights();
      expect(insights.any((i) => i.contains('Velocity') || i.contains('week')), isTrue);
    });
  });

  group('EliminationStrategy', () {
    test('all strategies have descriptions', () {
      for (final s in EliminationStrategy.values) {
        expect(s.label, isNotEmpty);
        expect(s.emoji, isNotEmpty);
        expect(s.description, isNotEmpty);
      }
    });
  });

  group('FrictionTimeSlot', () {
    test('all time slots have ranges', () {
      for (final t in FrictionTimeSlot.values) {
        expect(t.label, isNotEmpty);
        expect(t.timeRange, contains('–') );
      }
    });
  });

  group('Date range queries', () {
    test('getEntriesInRange filters correctly', () {
      service.logFriction(
        category: FrictionCategory.work,
        severity: FrictionSeverity.minor,
        timeSlot: FrictionTimeSlot.morning,
        description: 'Old entry',
        timestamp: DateTime(2026, 1, 1),
      );
      service.logFriction(
        category: FrictionCategory.work,
        severity: FrictionSeverity.moderate,
        timeSlot: FrictionTimeSlot.afternoon,
        description: 'Recent entry',
        timestamp: DateTime(2026, 4, 15),
      );
      final range = service.getEntriesInRange(
        DateTime(2026, 4, 1),
        DateTime(2026, 4, 30),
      );
      expect(range.length, 1);
      expect(range.first.description, 'Recent entry');
    });
  });
}
