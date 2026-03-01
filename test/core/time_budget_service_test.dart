import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/time_budget_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';

/// Helper to create test events with duration.
EventModel _event({
  String id = '1',
  String title = 'Test',
  required DateTime date,
  required DateTime endDate,
  EventPriority priority = EventPriority.medium,
  List<EventTag> tags = const [],
}) {
  return EventModel(
    id: id,
    title: title,
    date: date,
    endDate: endDate,
    priority: priority,
    tags: tags,
  );
}

/// Helper to create a point-in-time event (no duration).
EventModel _pointEvent({
  String id = 'p1',
  String title = 'Point Event',
  required DateTime date,
  EventPriority priority = EventPriority.medium,
  List<EventTag> tags = const [],
}) {
  return EventModel(
    id: id,
    title: title,
    date: date,
    priority: priority,
    tags: tags,
  );
}

void main() {
  final refDate = DateTime(2026, 3, 1);
  final workTag = const EventTag(name: 'Work', colorIndex: 0);
  final personalTag = const EventTag(name: 'Personal', colorIndex: 1);
  final healthTag = const EventTag(name: 'Health', colorIndex: 4);

  group('TimeBudgetService — empty events', () {
    test('analyze returns zero report for empty list', () {
      final service = TimeBudgetService(referenceDate: refDate);
      final report = service.analyze([]);
      expect(report.totalTrackedHours, 0.0);
      expect(report.analyzedEvents, 0);
      expect(report.skippedEvents, 0);
      expect(report.byTag, isEmpty);
      expect(report.byPriority, isEmpty);
      expect(report.overloadedDays, isEmpty);
      expect(report.topTag, isNull);
      expect(report.topPriority, isNull);
    });

    test('analyze handles only point events (all skipped)', () {
      final events = [
        _pointEvent(id: '1', date: DateTime(2026, 2, 15)),
        _pointEvent(id: '2', date: DateTime(2026, 2, 20)),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final report = service.analyze(events);
      expect(report.analyzedEvents, 0);
      expect(report.skippedEvents, 2);
      expect(report.totalTrackedHours, 0.0);
    });
  });

  group('TimeBudgetService — tag breakdown', () {
    test('allocates hours by tag correctly', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 11, 0), // 2h
          tags: [workTag],
        ),
        _event(
          id: '2',
          date: DateTime(2026, 2, 16, 14, 0),
          endDate: DateTime(2026, 2, 16, 15, 0), // 1h
          tags: [personalTag],
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(report.totalTrackedHours, 3.0);
      expect(report.analyzedEvents, 2);
      expect(report.byTag.length, 2);

      final work = report.byTag.firstWhere((a) => a.category == 'Work');
      expect(work.totalHours, 2.0);
      expect(work.eventCount, 1);
      expect(work.avgDurationMinutes, 120.0);
      expect(work.percentage, closeTo(66.7, 0.1));

      final personal =
          report.byTag.firstWhere((a) => a.category == 'Personal');
      expect(personal.totalHours, 1.0);
      expect(personal.eventCount, 1);
      expect(personal.percentage, closeTo(33.3, 0.1));
    });

    test('groups untagged events as (untagged)', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 10, 0),
          tags: [],
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(report.byTag.length, 1);
      expect(report.byTag.first.category, '(untagged)');
      expect(report.byTag.first.totalHours, 1.0);
    });

    test('event with multiple tags counted in each', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 10, 0), // 1h
          tags: [workTag, healthTag],
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      // Both tags should get 1h each
      expect(report.byTag.length, 2);
      final work = report.byTag.firstWhere((a) => a.category == 'Work');
      expect(work.totalHours, 1.0);
      final health = report.byTag.firstWhere((a) => a.category == 'Health');
      expect(health.totalHours, 1.0);
    });
  });

  group('TimeBudgetService — priority breakdown', () {
    test('allocates hours by priority correctly', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 12, 0), // 3h
          priority: EventPriority.high,
        ),
        _event(
          id: '2',
          date: DateTime(2026, 2, 16, 14, 0),
          endDate: DateTime(2026, 2, 16, 15, 0), // 1h
          priority: EventPriority.low,
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(report.byPriority.length, 2);

      final high =
          report.byPriority.firstWhere((a) => a.category == 'High');
      expect(high.totalHours, 3.0);
      expect(high.percentage, 75.0);

      final low =
          report.byPriority.firstWhere((a) => a.category == 'Low');
      expect(low.totalHours, 1.0);
      expect(low.percentage, 25.0);
    });

    test('sorted by total hours descending', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 10, 0),
          priority: EventPriority.low,
        ),
        _event(
          id: '2',
          date: DateTime(2026, 2, 16, 9, 0),
          endDate: DateTime(2026, 2, 16, 14, 0), // 5h
          priority: EventPriority.urgent,
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(report.byPriority.first.category, 'Urgent');
    });
  });

  group('TimeBudgetService — budget tracking', () {
    test('reports budget utilization when budget is set', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 11, 0), // 2h
          tags: [workTag],
        ),
      ];
      final service = TimeBudgetService(
        budgets: [
          const TimeBudget(category: 'Work', targetHoursPerWeek: 40),
        ],
        referenceDate: refDate,
      );
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      final work = report.byTag.firstWhere((a) => a.category == 'Work');
      expect(work.budgetHoursPerWeek, 40);
      expect(work.isOverBudget, false);
      expect(work.budgetUtilization, isNotNull);
      expect(work.budgetUtilization!, lessThan(100));
    });

    test('detects over-budget categories', () {
      // 4 weeks, 50h of work = 12.5h/week, budget is 10h/week
      final events = List.generate(50, (i) => _event(
        id: 'w$i',
        date: DateTime(2026, 2, 1 + (i % 28), 9, 0),
        endDate: DateTime(2026, 2, 1 + (i % 28), 10, 0), // 1h each
        tags: [workTag],
      ));
      final service = TimeBudgetService(
        budgets: [
          const TimeBudget(category: 'Work', targetHoursPerWeek: 10),
        ],
        referenceDate: refDate,
      );
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      final work = report.byTag.firstWhere((a) => a.category == 'Work');
      expect(work.isOverBudget, true);
      expect(report.overBudgetCategories, isNotEmpty);
    });

    test('no budget returns null for budget fields', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 10, 0),
          tags: [workTag],
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      final work = report.byTag.first;
      expect(work.budgetHoursPerWeek, isNull);
      expect(work.isOverBudget, isNull);
      expect(work.budgetUtilization, isNull);
    });

    test('budget comparison returns only budgeted categories', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 10, 0),
          tags: [workTag],
        ),
        _event(
          id: '2',
          date: DateTime(2026, 2, 16, 9, 0),
          endDate: DateTime(2026, 2, 16, 10, 0),
          tags: [personalTag],
        ),
      ];
      final service = TimeBudgetService(
        budgets: [
          const TimeBudget(category: 'Work', targetHoursPerWeek: 40),
        ],
        referenceDate: refDate,
      );
      final comparison = service.getBudgetComparison(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(comparison.length, 1);
      expect(comparison.first.category, 'Work');
    });
  });

  group('TimeBudgetService — overload detection', () {
    test('detects overloaded days', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 8, 0),
          endDate: DateTime(2026, 2, 15, 14, 0), // 6h
        ),
        _event(
          id: '2',
          date: DateTime(2026, 2, 15, 14, 0),
          endDate: DateTime(2026, 2, 15, 18, 0), // 4h → total 10h
        ),
      ];
      final service = TimeBudgetService(
        overloadThresholdHours: 8.0,
        referenceDate: refDate,
      );
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(report.overloadedDays.length, 1);
      expect(report.overloadedDays.first.totalHours, 10.0);
      expect(report.overloadedDays.first.excessHours, 2.0);
      expect(report.overloadedDays.first.eventCount, 2);
    });

    test('no overload when under threshold', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 12, 0), // 3h
        ),
      ];
      final service = TimeBudgetService(
        overloadThresholdHours: 8.0,
        referenceDate: refDate,
      );
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(report.overloadedDays, isEmpty);
    });

    test('custom threshold works', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 12, 0), // 3h
        ),
      ];
      final service = TimeBudgetService(
        overloadThresholdHours: 2.0, // low threshold
        referenceDate: refDate,
      );
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(report.overloadedDays.length, 1);
    });
  });

  group('TimeBudgetService — weekday distribution', () {
    test('computes weekday hours', () {
      // Feb 15 2026 is a Sunday (weekday 7 → index 6)
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0), // Sunday
          endDate: DateTime(2026, 2, 15, 11, 0), // 2h
        ),
        _event(
          id: '2',
          date: DateTime(2026, 2, 16, 9, 0), // Monday
          endDate: DateTime(2026, 2, 16, 12, 0), // 3h
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(report.weekdayHours[0], 3.0); // Monday
      expect(report.weekdayHours[6], 2.0); // Sunday
    });

    test('busiest and lightest weekday', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 16, 9, 0), // Monday
          endDate: DateTime(2026, 2, 16, 17, 0), // 8h
        ),
        _event(
          id: '2',
          date: DateTime(2026, 2, 18, 9, 0), // Wednesday
          endDate: DateTime(2026, 2, 18, 10, 0), // 1h
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(report.busiestWeekday, 'Monday');
      expect(report.lightestWeekday, 'Wednesday');
    });
  });

  group('TimeBudgetService — period filtering', () {
    test('filters events to analysis period', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 1, 10, 9, 0), // outside period
          endDate: DateTime(2026, 1, 10, 10, 0),
        ),
        _event(
          id: '2',
          date: DateTime(2026, 2, 15, 9, 0), // inside period
          endDate: DateTime(2026, 2, 15, 10, 0),
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(report.analyzedEvents, 1);
      expect(report.totalTrackedHours, 1.0);
    });

    test('defaults to 30-day lookback', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 1, 10, 9, 0), // >30 days before Mar 1
          endDate: DateTime(2026, 1, 10, 10, 0),
        ),
        _event(
          id: '2',
          date: DateTime(2026, 2, 15, 9, 0), // within 30 days
          endDate: DateTime(2026, 2, 15, 10, 0),
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final report = service.analyze(events);
      expect(report.analyzedEvents, 1);
    });
  });

  group('TimeBudgetService — getAllocationForTag', () {
    test('returns allocation for specific tag', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 11, 0),
          tags: [workTag],
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final alloc = service.getAllocationForTag(events, 'Work',
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(alloc, isNotNull);
      expect(alloc!.totalHours, 2.0);
    });

    test('returns null for nonexistent tag', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 10, 0),
          tags: [workTag],
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final alloc = service.getAllocationForTag(events, 'Travel',
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(alloc, isNull);
    });

    test('case-insensitive tag lookup', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 10, 0),
          tags: [workTag],
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final alloc = service.getAllocationForTag(events, 'work',
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(alloc, isNotNull);
    });
  });

  group('TimeBudgetService — report summary', () {
    test('generates readable summary', () {
      final events = [
        _event(
          id: '1',
          date: DateTime(2026, 2, 15, 9, 0),
          endDate: DateTime(2026, 2, 15, 11, 0),
          tags: [workTag],
          priority: EventPriority.high,
        ),
      ];
      final service = TimeBudgetService(referenceDate: refDate);
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      final summary = report.summary;
      expect(summary, contains('Time Budget Report'));
      expect(summary, contains('By Tag'));
      expect(summary, contains('Work'));
      expect(summary, contains('By Priority'));
      expect(summary, contains('High'));
    });

    test('summary includes over-budget warnings', () {
      final events = List.generate(20, (i) => _event(
        id: 'w$i',
        date: DateTime(2026, 2, 1 + (i % 28), 9, 0),
        endDate: DateTime(2026, 2, 1 + (i % 28), 11, 0), // 2h each = 40h
        tags: [workTag],
      ));
      final service = TimeBudgetService(
        budgets: [
          const TimeBudget(category: 'Work', targetHoursPerWeek: 5),
        ],
        referenceDate: refDate,
      );
      final report = service.analyze(events,
          since: DateTime(2026, 2, 1), until: DateTime(2026, 2, 28));
      expect(report.summary, contains('Over Budget'));
    });
  });

  group('TimeBudget model', () {
    test('equality', () {
      const a = TimeBudget(category: 'Work', targetHoursPerWeek: 40);
      const b = TimeBudget(category: 'Work', targetHoursPerWeek: 40);
      const c = TimeBudget(category: 'Play', targetHoursPerWeek: 10);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toString', () {
      const b = TimeBudget(category: 'Work', targetHoursPerWeek: 40);
      expect(b.toString(), contains('Work'));
      expect(b.toString(), contains('40'));
    });
  });

  group('TimeAllocation model', () {
    test('isOverBudget null when no budget', () {
      const a = TimeAllocation(
        category: 'X',
        totalHours: 10,
        eventCount: 5,
        avgDurationMinutes: 120,
        percentage: 50,
        actualHoursPerWeek: 5,
      );
      expect(a.isOverBudget, isNull);
      expect(a.budgetUtilization, isNull);
    });

    test('budgetUtilization calculation', () {
      const a = TimeAllocation(
        category: 'X',
        totalHours: 10,
        eventCount: 5,
        avgDurationMinutes: 120,
        percentage: 50,
        budgetHoursPerWeek: 20,
        actualHoursPerWeek: 10,
      );
      expect(a.budgetUtilization, 50.0);
      expect(a.isOverBudget, false);
    });
  });

  group('OverloadedDay model', () {
    test('toString', () {
      final o = OverloadedDay(
        date: DateTime(2026, 2, 15),
        totalHours: 12,
        eventCount: 5,
        excessHours: 4,
      );
      expect(o.toString(), contains('12.0'));
      expect(o.toString(), contains('4.0'));
    });
  });

  group('TimeBudgetReport model', () {
    test('topTag returns highest-hours tag', () {
      final report = TimeBudgetReport(
        totalTrackedHours: 10,
        analyzedEvents: 3,
        skippedEvents: 0,
        weeksInPeriod: 1,
        byTag: const [
          TimeAllocation(category: 'Work', totalHours: 8, eventCount: 2,
              avgDurationMinutes: 240, percentage: 80, actualHoursPerWeek: 8),
          TimeAllocation(category: 'Play', totalHours: 2, eventCount: 1,
              avgDurationMinutes: 120, percentage: 20, actualHoursPerWeek: 2),
        ],
        byPriority: const [],
        avgHoursPerDay: 1.4,
        overloadedDays: const [],
        weekdayHours: const {},
      );
      expect(report.topTag!.category, 'Work');
    });

    test('toString', () {
      final report = TimeBudgetReport(
        totalTrackedHours: 10,
        analyzedEvents: 3,
        skippedEvents: 1,
        weeksInPeriod: 1,
        byTag: const [],
        byPriority: const [],
        avgHoursPerDay: 1.4,
        overloadedDays: const [],
        weekdayHours: const {},
      );
      expect(report.toString(), contains('10.0'));
      expect(report.toString(), contains('3 events'));
    });
  });
}
