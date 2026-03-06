import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/time_audit_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';

void main() {
  late TimeAuditService service;

  setUp(() {
    service = TimeAuditService();
  });

  // ── Helper ──────────────────────────────────────────────────────

  EventModel _event({
    String id = 'e1',
    String title = 'Test',
    required DateTime start,
    DateTime? end,
    EventPriority priority = EventPriority.medium,
    List<EventTag>? tags,
  }) {
    return EventModel(
      id: id,
      title: title,
      date: start,
      endDate: end,
      priority: priority,
      tags: tags,
    );
  }

  DateTime _d(int year, int month, int day, [int hour = 9, int minute = 0]) =>
      DateTime(year, month, day, hour, minute);

  // ── Constructor ─────────────────────────────────────────────────

  group('constructor', () {
    test('defaults to 8-18 working hours', () {
      final s = TimeAuditService();
      expect(s.workDayStartHour, 8);
      expect(s.workDayEndHour, 18);
      expect(s.minEventMinutes, 0);
    });

    test('accepts custom working hours', () {
      final s = TimeAuditService(
          workDayStartHour: 6, workDayEndHour: 22, minEventMinutes: 5);
      expect(s.workDayStartHour, 6);
      expect(s.workDayEndHour, 22);
      expect(s.minEventMinutes, 5);
    });

    test('asserts start < end hour', () {
      expect(
          () => TimeAuditService(workDayStartHour: 18, workDayEndHour: 8),
          throwsA(isA<AssertionError>()));
    });

    test('asserts non-negative minEventMinutes', () {
      expect(
          () => TimeAuditService(minEventMinutes: -1),
          throwsA(isA<AssertionError>()));
    });
  });

  // ── Empty input ─────────────────────────────────────────────────

  group('empty input', () {
    test('returns zeroed report for no events', () {
      final report = service.audit(
        [],
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 7),
      );
      expect(report.totalEvents, 0);
      expect(report.totalScheduledMinutes, 0);
      expect(report.overallUtilization, 0);
      expect(report.categoryBreakdown, isEmpty);
      expect(report.dailySummaries.length, 7);
      expect(report.avgEventDuration, 0);
      expect(report.medianEventDuration, 0);
      expect(report.longestEventDuration, 0);
      expect(report.pointEvents, 0);
    });

    test('single day range returns 1 day summary', () {
      final report = service.audit(
        [],
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.totalDays, 1);
      expect(report.dailySummaries.length, 1);
    });
  });

  // ── Basic audit ─────────────────────────────────────────────────

  group('basic audit', () {
    test('counts timed and point events separately', () {
      final events = [
        _event(id: 'e1', start: _d(2026, 3, 1, 9), end: _d(2026, 3, 1, 10)),
        _event(id: 'e2', start: _d(2026, 3, 1, 11)), // no end — point event
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.totalEvents, 2);
      expect(report.pointEvents, 1);
      expect(report.totalScheduledMinutes, 60); // only timed event
    });

    test('calculates total scheduled minutes', () {
      final events = [
        _event(id: 'e1', start: _d(2026, 3, 1, 9), end: _d(2026, 3, 1, 10)),
        _event(
            id: 'e2', start: _d(2026, 3, 1, 14), end: _d(2026, 3, 1, 15, 30)),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.totalScheduledMinutes, 150); // 60 + 90
    });

    test('calculates utilization rate', () {
      // 1 day × 10 hours = 600 minutes available
      final events = [
        _event(id: 'e1', start: _d(2026, 3, 1, 9), end: _d(2026, 3, 1, 12)),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.totalAvailableMinutes, 600);
      expect(report.totalScheduledMinutes, 180);
      expect(report.overallUtilization, closeTo(0.3, 0.01));
    });

    test('computes avg and median duration', () {
      final events = [
        _event(id: 'e1', start: _d(2026, 3, 1, 9), end: _d(2026, 3, 1, 10)),
        _event(
            id: 'e2', start: _d(2026, 3, 1, 11), end: _d(2026, 3, 1, 13)), // 120 min
        _event(
            id: 'e3', start: _d(2026, 3, 1, 14), end: _d(2026, 3, 1, 15)), // 60 min
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.avgEventDuration, 80); // (60+120+60)/3
      expect(report.medianEventDuration, 60); // sorted: 60,60,120 → middle
      expect(report.longestEventDuration, 120);
    });
  });

  // ── Category breakdown ──────────────────────────────────────────

  group('category breakdown', () {
    test('groups time by tag name', () {
      final events = [
        _event(
          id: 'e1',
          start: _d(2026, 3, 1, 9),
          end: _d(2026, 3, 1, 10),
          tags: [const EventTag(name: 'Work')],
        ),
        _event(
          id: 'e2',
          start: _d(2026, 3, 1, 11),
          end: _d(2026, 3, 1, 12),
          tags: [const EventTag(name: 'Work')],
        ),
        _event(
          id: 'e3',
          start: _d(2026, 3, 1, 14),
          end: _d(2026, 3, 1, 15),
          tags: [const EventTag(name: 'Personal')],
        ),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.categoryBreakdown.length, 2);
      // Sorted by totalMinutes desc — Work first
      expect(report.categoryBreakdown[0].category, 'Work');
      expect(report.categoryBreakdown[0].totalMinutes, 120);
      expect(report.categoryBreakdown[0].eventCount, 2);
      expect(report.categoryBreakdown[1].category, 'Personal');
      expect(report.categoryBreakdown[1].totalMinutes, 60);
    });

    test('untagged events go to "Untagged" category', () {
      final events = [
        _event(id: 'e1', start: _d(2026, 3, 1, 9), end: _d(2026, 3, 1, 10)),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.categoryBreakdown.length, 1);
      expect(report.categoryBreakdown[0].category, 'Untagged');
    });

    test('multi-tagged event splits time equally', () {
      final events = [
        _event(
          id: 'e1',
          start: _d(2026, 3, 1, 9),
          end: _d(2026, 3, 1, 11), // 120 min
          tags: [
            const EventTag(name: 'Work'),
            const EventTag(name: 'Learning'),
          ],
        ),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.categoryBreakdown.length, 2);
      // Each gets 60 min
      for (final cat in report.categoryBreakdown) {
        expect(cat.totalMinutes, 60);
      }
    });

    test('percentages sum to ~100%', () {
      final events = [
        _event(
          id: 'e1',
          start: _d(2026, 3, 1, 9),
          end: _d(2026, 3, 1, 10),
          tags: [const EventTag(name: 'A')],
        ),
        _event(
          id: 'e2',
          start: _d(2026, 3, 1, 11),
          end: _d(2026, 3, 1, 12),
          tags: [const EventTag(name: 'B')],
        ),
        _event(
          id: 'e3',
          start: _d(2026, 3, 1, 14),
          end: _d(2026, 3, 1, 15),
          tags: [const EventTag(name: 'C')],
        ),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      final totalPct = report.categoryBreakdown
          .map((c) => c.percentage)
          .fold(0.0, (s, p) => s + p);
      expect(totalPct, closeTo(100.0, 0.1));
    });
  });

  // ── Daily summaries ─────────────────────────────────────────────

  group('daily summaries', () {
    test('creates one summary per day in range', () {
      final report = service.audit(
        [],
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 5),
      );
      expect(report.dailySummaries.length, 5);
    });

    test('assigns events to correct days', () {
      final events = [
        _event(id: 'e1', start: _d(2026, 3, 1, 9), end: _d(2026, 3, 1, 10)),
        _event(id: 'e2', start: _d(2026, 3, 3, 14), end: _d(2026, 3, 3, 16)),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 5),
      );
      expect(report.dailySummaries[0].eventCount, 1); // Mar 1
      expect(report.dailySummaries[0].scheduledMinutes, 60);
      expect(report.dailySummaries[1].eventCount, 0); // Mar 2
      expect(report.dailySummaries[2].eventCount, 1); // Mar 3
      expect(report.dailySummaries[2].scheduledMinutes, 120);
    });

    test('computes free minutes correctly', () {
      final events = [
        _event(id: 'e1', start: _d(2026, 3, 1, 9), end: _d(2026, 3, 1, 12)),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.dailySummaries[0].scheduledMinutes, 180);
      expect(report.dailySummaries[0].availableMinutes, 600);
      expect(report.dailySummaries[0].freeMinutes, 420);
    });

    test('counts context switches', () {
      final events = [
        _event(id: 'e1', start: _d(2026, 3, 1, 9), end: _d(2026, 3, 1, 10)),
        _event(id: 'e2', start: _d(2026, 3, 1, 10), end: _d(2026, 3, 1, 11)),
        _event(id: 'e3', start: _d(2026, 3, 1, 14), end: _d(2026, 3, 1, 15)),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      // 3 events → 2 context switches
      expect(report.dailySummaries[0].contextSwitches, 2);
    });

    test('utilization capped at 1.0', () {
      // Over-scheduled: 12 hours in a 10-hour workday
      final events = [
        _event(id: 'e1', start: _d(2026, 3, 1, 6), end: _d(2026, 3, 1, 18)),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.dailySummaries[0].utilizationRate, 1.0);
    });
  });

  // ── Peak hours ──────────────────────────────────────────────────

  group('peak hours', () {
    test('identifies busiest hour', () {
      final events = [
        _event(id: 'e1', start: _d(2026, 3, 1, 9), end: _d(2026, 3, 1, 10)),
        _event(id: 'e2', start: _d(2026, 3, 1, 9, 30), end: _d(2026, 3, 1, 10, 30)),
        _event(id: 'e3', start: _d(2026, 3, 1, 14), end: _d(2026, 3, 1, 15)),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.peakHours.busiestHour, 9);
      expect(report.peakHours.hourlyDistribution[9], 2);
    });

    test('computes morning/afternoon/evening split', () {
      final events = [
        _event(
            id: 'e1',
            start: _d(2026, 3, 1, 8),
            end: _d(2026, 3, 1, 10)), // morning: 120 min
        _event(
            id: 'e2',
            start: _d(2026, 3, 1, 14),
            end: _d(2026, 3, 1, 16)), // afternoon: 120 min
        _event(
            id: 'e3',
            start: _d(2026, 3, 1, 19),
            end: _d(2026, 3, 1, 20)), // evening: 60 min
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.peakHours.morningMinutes, 120);
      expect(report.peakHours.afternoonMinutes, 120);
      expect(report.peakHours.eveningMinutes, 60);
    });
  });

  // ── Priority breakdown ──────────────────────────────────────────

  group('priority breakdown', () {
    test('groups minutes by priority', () {
      final events = [
        _event(
          id: 'e1',
          start: _d(2026, 3, 1, 9),
          end: _d(2026, 3, 1, 10),
          priority: EventPriority.high,
        ),
        _event(
          id: 'e2',
          start: _d(2026, 3, 1, 11),
          end: _d(2026, 3, 1, 13),
          priority: EventPriority.low,
        ),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.priorityMinutes[EventPriority.high], 60);
      expect(report.priorityMinutes[EventPriority.low], 120);
      expect(report.priorityMinutes[EventPriority.medium], 0);
      expect(report.priorityMinutes[EventPriority.urgent], 0);
    });
  });

  // ── Event filtering ─────────────────────────────────────────────

  group('event filtering', () {
    test('excludes events outside date range', () {
      final events = [
        _event(
            id: 'inside',
            start: _d(2026, 3, 3, 9),
            end: _d(2026, 3, 3, 10)),
        _event(
            id: 'before',
            start: _d(2026, 2, 28, 9),
            end: _d(2026, 2, 28, 10)),
        _event(
            id: 'after',
            start: _d(2026, 3, 10, 9),
            end: _d(2026, 3, 10, 10)),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 7),
      );
      expect(report.totalEvents, 1);
      expect(report.totalScheduledMinutes, 60);
    });

    test('respects minEventMinutes filter', () {
      final s = TimeAuditService(minEventMinutes: 30);
      final events = [
        _event(
            id: 'short',
            start: _d(2026, 3, 1, 9),
            end: _d(2026, 3, 1, 9, 15)), // 15 min — below threshold
        _event(
            id: 'long',
            start: _d(2026, 3, 1, 10),
            end: _d(2026, 3, 1, 11)), // 60 min — above
      ];
      final report = s.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      // totalScheduledMinutes should only count the long event
      expect(report.totalScheduledMinutes, 60);
    });
  });

  // ── Recommendations ─────────────────────────────────────────────

  group('recommendations', () {
    test('recommends buffer time when over 85% utilized', () {
      // 600 min available; schedule 540 min (90%)
      final events = [
        _event(
            id: 'e1',
            start: _d(2026, 3, 1, 8),
            end: _d(2026, 3, 1, 17)),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.recommendations,
          contains(predicate<String>((s) => s.contains('very full'))));
    });

    test('recommends scheduling when under 30% utilized', () {
      final events = [
        _event(
            id: 'e1',
            start: _d(2026, 3, 1, 9),
            end: _d(2026, 3, 1, 10)), // 60/600 = 10%
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.recommendations,
          contains(predicate<String>((s) => s.contains('Low schedule'))));
    });

    test('recommends rebalancing when one category dominates', () {
      final events = [
        _event(
          id: 'e1',
          start: _d(2026, 3, 1, 9),
          end: _d(2026, 3, 1, 14), // 300 min
          tags: [const EventTag(name: 'Meetings')],
        ),
        _event(
          id: 'e2',
          start: _d(2026, 3, 1, 14),
          end: _d(2026, 3, 1, 15), // 60 min
          tags: [const EventTag(name: 'Coding')],
        ),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.recommendations,
          contains(predicate<String>((s) => s.contains('dominates'))));
    });

    test('warns about too many point events', () {
      final events = List.generate(
        10,
        (i) => _event(
            id: 'e$i', start: _d(2026, 3, 1, 9 + i)),
      );
      // Add 2 timed events
      events.add(_event(
          id: 'timed1', start: _d(2026, 3, 1, 8), end: _d(2026, 3, 1, 9)));
      events.add(_event(
          id: 'timed2', start: _d(2026, 3, 1, 20), end: _d(2026, 3, 1, 21)));

      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.recommendations,
          contains(predicate<String>((s) => s.contains('no end time'))));
    });

    test('returns empty recommendations for balanced schedule', () {
      // Moderate utilization, varied categories, reasonable duration
      final events = [
        _event(
          id: 'e1',
          start: _d(2026, 3, 1, 9),
          end: _d(2026, 3, 1, 11),
          tags: [const EventTag(name: 'Work')],
        ),
        _event(
          id: 'e2',
          start: _d(2026, 3, 1, 13),
          end: _d(2026, 3, 1, 15),
          tags: [const EventTag(name: 'Personal')],
        ),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      // Should have few or no recommendations for a balanced day
      expect(report.recommendations.length, lessThanOrEqualTo(2));
    });
  });

  // ── Multi-day audit ─────────────────────────────────────────────

  group('multi-day audit', () {
    test('computes avg daily scheduled minutes', () {
      final events = [
        _event(
            id: 'e1',
            start: _d(2026, 3, 1, 9),
            end: _d(2026, 3, 1, 12)), // 180 min
        _event(
            id: 'e2',
            start: _d(2026, 3, 2, 10),
            end: _d(2026, 3, 2, 11)), // 60 min
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 2),
      );
      expect(report.totalDays, 2);
      expect(report.avgDailyScheduledMinutes, 120); // 240/2
    });

    test('total available scales with days', () {
      final report = service.audit(
        [],
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 7),
      );
      // 7 days × 10 hours × 60 min = 4200
      expect(report.totalAvailableMinutes, 4200);
    });
  });

  // ── Custom working hours ────────────────────────────────────────

  group('custom working hours', () {
    test('uses custom hours for availability', () {
      final s =
          TimeAuditService(workDayStartHour: 6, workDayEndHour: 22);
      final report = s.audit(
        [],
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      // 16 hours × 60 = 960
      expect(report.totalAvailableMinutes, 960);
    });
  });

  // ── Report period ───────────────────────────────────────────────

  group('report metadata', () {
    test('captures period start and end', () {
      final start = _d(2026, 3, 1);
      final end = _d(2026, 3, 7);
      final report = service.audit([], start: start, end: end);
      expect(report.periodStart, start);
      expect(report.periodEnd, end);
    });

    test('asserts end is not before start', () {
      expect(
        () => service.audit(
          [],
          start: _d(2026, 3, 7),
          end: _d(2026, 3, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────

  group('edge cases', () {
    test('handles same start and end date', () {
      final events = [
        _event(
            id: 'e1',
            start: _d(2026, 3, 1, 9),
            end: _d(2026, 3, 1, 10)),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.totalDays, 1);
      expect(report.totalEvents, 1);
    });

    test('handles all point events (no durations)', () {
      final events = List.generate(
        5,
        (i) => _event(id: 'e$i', start: _d(2026, 3, 1, 9 + i)),
      );
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.totalEvents, 5);
      expect(report.pointEvents, 5);
      expect(report.totalScheduledMinutes, 0);
      expect(report.avgEventDuration, 0);
    });

    test('median with even number of events', () {
      final events = [
        _event(
            id: 'e1',
            start: _d(2026, 3, 1, 9),
            end: _d(2026, 3, 1, 10)), // 60
        _event(
            id: 'e2',
            start: _d(2026, 3, 1, 11),
            end: _d(2026, 3, 1, 13)), // 120
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.medianEventDuration, 90); // (60+120)/2
    });

    test('single timed event median equals its duration', () {
      final events = [
        _event(
            id: 'e1',
            start: _d(2026, 3, 1, 9),
            end: _d(2026, 3, 1, 10, 30)),
      ];
      final report = service.audit(
        events,
        start: _d(2026, 3, 1),
        end: _d(2026, 3, 1),
      );
      expect(report.medianEventDuration, 90);
      expect(report.avgEventDuration, 90);
    });
  });
}
