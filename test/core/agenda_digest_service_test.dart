import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/agenda_digest_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';
import 'package:everything/models/event_checklist.dart';
import 'package:everything/models/recurrence_rule.dart';

void main() {
  late AgendaDigestService service;
  final monday = DateTime(2026, 2, 23); // A Monday

  setUp(() {
    service = AgendaDigestService();
  });

  EventModel _event(
    String id,
    String title,
    DateTime date, {
    EventPriority priority = EventPriority.medium,
    List<EventTag>? tags,
    RecurrenceRule? recurrence,
    EventChecklist? checklist,
  }) {
    return EventModel(
      id: id,
      title: title,
      date: date,
      priority: priority,
      tags: tags,
      recurrence: recurrence,
      checklist: checklist,
    );
  }

  // ─── DigestConfig tests ──────────────────────────────────────────

  group('DigestConfig', () {
    test('has sensible defaults', () {
      const config = DigestConfig();
      expect(config.days, 7);
      expect(config.expandRecurring, true);
      expect(config.includeChecklists, true);
      expect(config.includeTags, true);
      expect(config.groupByPriority, false);
      expect(config.maxEventsPerDay, isNull);
    });

    test('accepts custom values', () {
      const config = DigestConfig(
        days: 14,
        expandRecurring: false,
        includeChecklists: false,
        includeTags: false,
        groupByPriority: true,
        maxEventsPerDay: 5,
      );
      expect(config.days, 14);
      expect(config.expandRecurring, false);
      expect(config.maxEventsPerDay, 5);
    });
  });

  // ─── DayAgenda tests ─────────────────────────────────────────────

  group('DayAgenda', () {
    test('hasEvents returns false when empty', () {
      final day = DayAgenda(date: monday, events: []);
      expect(day.hasEvents, false);
      expect(day.eventCount, 0);
    });

    test('hasEvents returns true with events', () {
      final day = DayAgenda(
        date: monday,
        events: [_event('1', 'Test', monday)],
      );
      expect(day.hasEvents, true);
      expect(day.eventCount, 1);
    });

    test('urgentCount counts urgent and high priority', () {
      final day = DayAgenda(
        date: monday,
        events: [
          _event('1', 'Low', monday, priority: EventPriority.low),
          _event('2', 'Urgent', monday, priority: EventPriority.urgent),
          _event('3', 'High', monday, priority: EventPriority.high),
          _event('4', 'Medium', monday, priority: EventPriority.medium),
        ],
      );
      expect(day.urgentCount, 2);
    });

    test('isPast returns true for past dates', () {
      final past = DayAgenda(date: DateTime(2020, 1, 1), events: []);
      expect(past.isPast, true);
    });

    test('isPast returns false for future dates', () {
      final future = DayAgenda(date: DateTime(2030, 1, 1), events: []);
      expect(future.isPast, false);
    });
  });

  // ─── generate() basic tests ───────────────────────────────────────

  group('generate()', () {
    test('returns empty digest for no events', () {
      final digest = service.generate([], startDate: monday);
      expect(digest.days.length, 7);
      expect(digest.summary.totalEvents, 0);
      expect(digest.summary.busyDays, 0);
      expect(digest.summary.freeDays, 7);
    });

    test('groups single event on correct day', () {
      final events = [_event('1', 'Meeting', monday.add(Duration(hours: 10)))];
      final digest = service.generate(events, startDate: monday);
      expect(digest.days[0].eventCount, 1);
      expect(digest.days[0].events[0].title, 'Meeting');
      expect(digest.days[1].eventCount, 0);
    });

    test('events outside window are excluded', () {
      final events = [
        _event('1', 'Before', monday.subtract(Duration(days: 1))),
        _event('2', 'After', monday.add(Duration(days: 8))),
        _event('3', 'Inside', monday.add(Duration(hours: 9))),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.summary.totalEvents, 1);
    });

    test('events are sorted by time within each day', () {
      final events = [
        _event('1', 'Afternoon', monday.add(Duration(hours: 14))),
        _event('2', 'Morning', monday.add(Duration(hours: 9))),
        _event('3', 'Evening', monday.add(Duration(hours: 19))),
      ];
      final digest = service.generate(events, startDate: monday);
      final titles = digest.days[0].events.map((e) => e.title).toList();
      expect(titles, ['Morning', 'Afternoon', 'Evening']);
    });

    test('uses 7 days by default', () {
      final digest = service.generate([], startDate: monday);
      expect(digest.days.length, 7);
      expect(digest.config.days, 7);
    });

    test('respects custom day count', () {
      final digest = service.generate(
        [],
        startDate: monday,
        config: DigestConfig(days: 3),
      );
      expect(digest.days.length, 3);
    });

    test('startDate defaults to today when not provided', () {
      final digest = service.generate([]);
      final today = DateTime.now();
      expect(digest.startDate.year, today.year);
      expect(digest.startDate.month, today.month);
      expect(digest.startDate.day, today.day);
    });

    test('multiple events on same day', () {
      final events = [
        _event('1', 'First', monday.add(Duration(hours: 9))),
        _event('2', 'Second', monday.add(Duration(hours: 11))),
        _event('3', 'Third', monday.add(Duration(hours: 15))),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.days[0].eventCount, 3);
    });

    test('events spread across multiple days', () {
      final events = [
        _event('1', 'Mon', monday.add(Duration(hours: 9))),
        _event('2', 'Wed', monday.add(Duration(days: 2, hours: 10))),
        _event('3', 'Fri', monday.add(Duration(days: 4, hours: 14))),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.days[0].eventCount, 1);
      expect(digest.days[1].eventCount, 0);
      expect(digest.days[2].eventCount, 1);
      expect(digest.days[3].eventCount, 0);
      expect(digest.days[4].eventCount, 1);
    });
  });

  // ─── Recurring event expansion ────────────────────────────────────

  group('recurring events', () {
    test('expands daily recurring events into window', () {
      final events = [
        _event(
          '1', 'Daily Standup', monday.add(Duration(hours: 9)),
          recurrence: RecurrenceRule(frequency: RecurrenceFrequency.daily),
        ),
      ];
      final digest = service.generate(events, startDate: monday);
      // Should have an occurrence on each day
      expect(digest.summary.totalEvents, greaterThanOrEqualTo(7));
    });

    test('does not expand when expandRecurring is false', () {
      final events = [
        _event(
          '1', 'Daily', monday.add(Duration(hours: 9)),
          recurrence: RecurrenceRule(frequency: RecurrenceFrequency.daily),
        ),
      ];
      final digest = service.generate(
        events,
        startDate: monday,
        config: DigestConfig(expandRecurring: false),
      );
      // Only the original event on monday
      expect(digest.summary.totalEvents, 1);
    });

    test('weekly recurring shows once in 7-day window', () {
      final events = [
        _event(
          '1', 'Weekly Review', monday.add(Duration(hours: 15)),
          recurrence: RecurrenceRule(frequency: RecurrenceFrequency.weekly),
        ),
      ];
      final digest = service.generate(events, startDate: monday);
      // Original is on Monday; next occurrence would be next Monday (day 8, outside window)
      expect(digest.summary.totalEvents, 1);
    });
  });

  // ─── Priority grouping ───────────────────────────────────────────

  group('priority grouping', () {
    test('groupByPriority sorts urgent first', () {
      final events = [
        _event('1', 'Low', monday.add(Duration(hours: 9)),
            priority: EventPriority.low),
        _event('2', 'Urgent', monday.add(Duration(hours: 10)),
            priority: EventPriority.urgent),
        _event('3', 'High', monday.add(Duration(hours: 11)),
            priority: EventPriority.high),
      ];
      final digest = service.generate(
        events,
        startDate: monday,
        config: DigestConfig(groupByPriority: true),
      );
      final priorities =
          digest.days[0].events.map((e) => e.priority).toList();
      expect(priorities, [
        EventPriority.urgent,
        EventPriority.high,
        EventPriority.low,
      ]);
    });

    test('without groupByPriority, events sorted by time', () {
      final events = [
        _event('1', 'Low', monday.add(Duration(hours: 9)),
            priority: EventPriority.low),
        _event('2', 'Urgent', monday.add(Duration(hours: 10)),
            priority: EventPriority.urgent),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.days[0].events[0].title, 'Low');
      expect(digest.days[0].events[1].title, 'Urgent');
    });
  });

  // ─── maxEventsPerDay ──────────────────────────────────────────────

  group('maxEventsPerDay', () {
    test('limits events shown per day', () {
      final events = List.generate(
        10,
        (i) => _event('$i', 'Event $i', monday.add(Duration(hours: i + 8))),
      );
      final digest = service.generate(
        events,
        startDate: monday,
        config: DigestConfig(maxEventsPerDay: 3),
      );
      expect(digest.days[0].eventCount, 3);
    });

    test('no limit when null', () {
      final events = List.generate(
        10,
        (i) => _event('$i', 'Event $i', monday.add(Duration(hours: i + 8))),
      );
      final digest = service.generate(events, startDate: monday);
      expect(digest.days[0].eventCount, 10);
    });

    test('does not limit when fewer events than max', () {
      final events = [
        _event('1', 'One', monday.add(Duration(hours: 9))),
        _event('2', 'Two', monday.add(Duration(hours: 10))),
      ];
      final digest = service.generate(
        events,
        startDate: monday,
        config: DigestConfig(maxEventsPerDay: 5),
      );
      expect(digest.days[0].eventCount, 2);
    });
  });

  // ─── DigestSummary tests ──────────────────────────────────────────

  group('DigestSummary', () {
    test('counts total events across days', () {
      final events = [
        _event('1', 'Mon', monday.add(Duration(hours: 9))),
        _event('2', 'Mon2', monday.add(Duration(hours: 10))),
        _event('3', 'Wed', monday.add(Duration(days: 2, hours: 9))),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.summary.totalEvents, 3);
    });

    test('counts busy and free days', () {
      final events = [
        _event('1', 'Mon', monday.add(Duration(hours: 9))),
        _event('2', 'Wed', monday.add(Duration(days: 2, hours: 9))),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.summary.busyDays, 2);
      expect(digest.summary.freeDays, 5);
    });

    test('counts urgent events', () {
      final events = [
        _event('1', 'Urgent1', monday, priority: EventPriority.urgent),
        _event('2', 'Normal', monday, priority: EventPriority.medium),
        _event('3', 'Urgent2', monday, priority: EventPriority.urgent),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.summary.urgentEvents, 2);
    });

    test('counts high priority events', () {
      final events = [
        _event('1', 'High1', monday, priority: EventPriority.high),
        _event('2', 'Low', monday, priority: EventPriority.low),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.summary.highEvents, 1);
    });

    test('identifies busiest day', () {
      final events = [
        _event('1', 'Mon1', monday.add(Duration(hours: 9))),
        _event('2', 'Wed1', monday.add(Duration(days: 2, hours: 9))),
        _event('3', 'Wed2', monday.add(Duration(days: 2, hours: 11))),
        _event('4', 'Wed3', monday.add(Duration(days: 2, hours: 14))),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.summary.busiestDay, isNotNull);
      expect(digest.summary.busiestDay!.eventCount, 3);
      expect(digest.summary.busiestDay!.date,
          DateTime(2026, 2, 25)); // Wednesday
    });

    test('busiestDay is null when no events', () {
      final digest = service.generate([], startDate: monday);
      expect(digest.summary.busiestDay, isNull);
    });

    test('calculates average events per busy day', () {
      final events = [
        _event('1', 'Mon1', monday.add(Duration(hours: 9))),
        _event('2', 'Mon2', monday.add(Duration(hours: 10))),
        _event('3', 'Wed1', monday.add(Duration(days: 2, hours: 9))),
        _event('4', 'Wed2', monday.add(Duration(days: 2, hours: 10))),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.summary.averageEventsPerBusyDay, 2.0);
    });

    test('average is 0 when no events', () {
      final digest = service.generate([], startDate: monday);
      expect(digest.summary.averageEventsPerBusyDay, 0.0);
    });

    test('totalDays matches config', () {
      final digest = service.generate(
        [],
        startDate: monday,
        config: DigestConfig(days: 14),
      );
      expect(digest.summary.totalDays, 14);
    });
  });

  // ─── formatText() tests ───────────────────────────────────────────

  group('formatText()', () {
    test('contains header', () {
      final digest = service.generate([], startDate: monday);
      final text = service.formatText(digest);
      expect(text, contains('Weekly Agenda Digest'));
    });

    test('shows event count summary', () {
      final events = [
        _event('1', 'Test', monday.add(Duration(hours: 9))),
      ];
      final digest = service.generate(events, startDate: monday);
      final text = service.formatText(digest);
      expect(text, contains('1 events across 1 days'));
    });

    test('shows no events message for empty days', () {
      final digest = service.generate([], startDate: monday);
      final text = service.formatText(digest);
      expect(text, contains('(no events)'));
    });

    test('shows event title and time', () {
      final events = [
        _event('1', 'Team Standup', monday.add(Duration(hours: 10, minutes: 30))),
      ];
      final digest = service.generate(events, startDate: monday);
      final text = service.formatText(digest);
      expect(text, contains('10:30'));
      expect(text, contains('Team Standup'));
    });

    test('shows priority icons', () {
      final events = [
        _event('1', 'Urgent', monday, priority: EventPriority.urgent),
      ];
      final digest = service.generate(events, startDate: monday);
      final text = service.formatText(digest);
      expect(text, contains('🔴'));
    });

    test('shows tags when enabled', () {
      final events = [
        _event('1', 'Meeting', monday,
            tags: [EventTag(name: 'Work', colorIndex: 0)]),
      ];
      final digest = service.generate(events, startDate: monday);
      final text = service.formatText(digest);
      expect(text, contains('[Work]'));
    });

    test('hides tags when disabled', () {
      final events = [
        _event('1', 'Meeting', monday,
            tags: [EventTag(name: 'Work', colorIndex: 0)]),
      ];
      final digest = service.generate(
        events,
        startDate: monday,
        config: DigestConfig(includeTags: false),
      );
      final text = service.formatText(digest);
      expect(text, isNot(contains('[Work]')));
    });

    test('shows recurring indicator', () {
      final events = [
        _event('1', 'Daily', monday,
            recurrence: RecurrenceRule(frequency: RecurrenceFrequency.daily)),
      ];
      final digest = service.generate(
        events,
        startDate: monday,
        config: DigestConfig(expandRecurring: false),
      );
      final text = service.formatText(digest);
      expect(text, contains('🔁'));
    });

    test('shows checklist progress when enabled', () {
      final checklist = EventChecklist(items: [
        ChecklistItem(id: '1', title: 'Done', completed: true),
        ChecklistItem(id: '2', title: 'Pending'),
        ChecklistItem(id: '3', title: 'Pending2'),
      ]);
      final events = [
        _event('1', 'Tasks', monday, checklist: checklist),
      ];
      final digest = service.generate(events, startDate: monday);
      final text = service.formatText(digest);
      expect(text, contains('1/3 tasks'));
    });

    test('hides checklist when disabled', () {
      final checklist = EventChecklist(items: [
        ChecklistItem(id: '1', title: 'Done', completed: true),
      ]);
      final events = [
        _event('1', 'Tasks', monday, checklist: checklist),
      ];
      final digest = service.generate(
        events,
        startDate: monday,
        config: DigestConfig(includeChecklists: false),
      );
      final text = service.formatText(digest);
      expect(text, isNot(contains('tasks')));
    });

    test('shows urgent warning', () {
      final events = [
        _event('1', 'Fire', monday, priority: EventPriority.urgent),
      ];
      final digest = service.generate(events, startDate: monday);
      final text = service.formatText(digest);
      expect(text, contains('⚠'));
      expect(text, contains('1 urgent event'));
    });

    test('shows busiest day in footer', () {
      final events = [
        _event('1', 'A', monday.add(Duration(hours: 9))),
        _event('2', 'B', monday.add(Duration(hours: 10))),
      ];
      final digest = service.generate(events, startDate: monday);
      final text = service.formatText(digest);
      expect(text, contains('Busiest'));
      expect(text, contains('2 events'));
    });

    test('shows day labels with weekday and month', () {
      final digest = service.generate([], startDate: monday);
      final text = service.formatText(digest);
      expect(text, contains('Mon, Feb 23'));
    });
  });

  // ─── formatMarkdown() tests ───────────────────────────────────────

  group('formatMarkdown()', () {
    test('contains markdown header', () {
      final digest = service.generate([], startDate: monday);
      final md = service.formatMarkdown(digest);
      expect(md, contains('# 📅 Weekly Agenda Digest'));
    });

    test('uses markdown bold for event times', () {
      final events = [
        _event('1', 'Test', monday.add(Duration(hours: 14))),
      ];
      final digest = service.generate(events, startDate: monday);
      final md = service.formatMarkdown(digest);
      expect(md, contains('**14:00**'));
    });

    test('uses h2 for day headers', () {
      final digest = service.generate([], startDate: monday);
      final md = service.formatMarkdown(digest);
      expect(md, contains('## Mon, Feb 23'));
    });

    test('shows no events as italic', () {
      final digest = service.generate([], startDate: monday);
      final md = service.formatMarkdown(digest);
      expect(md, contains('*No events scheduled*'));
    });

    test('uses bullet points for events', () {
      final events = [
        _event('1', 'Meeting', monday.add(Duration(hours: 10))),
      ];
      final digest = service.generate(events, startDate: monday);
      final md = service.formatMarkdown(digest);
      expect(md, contains('- **10:00**'));
    });

    test('shows tags as backtick code', () {
      final events = [
        _event('1', 'Work', monday,
            tags: [EventTag(name: 'Office', colorIndex: 0)]),
      ];
      final digest = service.generate(events, startDate: monday);
      final md = service.formatMarkdown(digest);
      expect(md, contains('`Office`'));
    });

    test('shows urgent blockquote warning', () {
      final events = [
        _event('1', 'Fire', monday, priority: EventPriority.urgent),
      ];
      final digest = service.generate(events, startDate: monday);
      final md = service.formatMarkdown(digest);
      expect(md, contains('> ⚠️'));
    });

    test('shows checklist as sub-bullet', () {
      final checklist = EventChecklist(items: [
        ChecklistItem(id: '1', title: 'A', completed: true),
        ChecklistItem(id: '2', title: 'B'),
      ]);
      final events = [
        _event('1', 'Tasks', monday, checklist: checklist),
      ];
      final digest = service.generate(events, startDate: monday);
      final md = service.formatMarkdown(digest);
      expect(md, contains('1/2 tasks'));
    });

    test('footer shows busiest day with separator', () {
      final events = [
        _event('1', 'A', monday.add(Duration(hours: 9))),
      ];
      final digest = service.generate(events, startDate: monday);
      final md = service.formatMarkdown(digest);
      expect(md, contains('---'));
      expect(md, contains('**Busiest day:**'));
    });
  });

  // ─── Edge cases ───────────────────────────────────────────────────

  group('edge cases', () {
    test('events at midnight boundary', () {
      final events = [
        _event('1', 'Midnight', monday), // exactly midnight
        _event('2', 'Late', monday.add(Duration(hours: 23, minutes: 59))),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.days[0].eventCount, 2);
    });

    test('single day window', () {
      final events = [
        _event('1', 'Today', monday.add(Duration(hours: 10))),
        _event('2', 'Tomorrow', monday.add(Duration(days: 1, hours: 10))),
      ];
      final digest = service.generate(
        events,
        startDate: monday,
        config: DigestConfig(days: 1),
      );
      expect(digest.days.length, 1);
      expect(digest.summary.totalEvents, 1);
    });

    test('30-day window', () {
      final digest = service.generate(
        [],
        startDate: monday,
        config: DigestConfig(days: 30),
      );
      expect(digest.days.length, 30);
      expect(digest.summary.totalDays, 30);
    });

    test('duplicate event IDs handled gracefully', () {
      final events = [
        _event('1', 'First', monday.add(Duration(hours: 9))),
        _event('1', 'Duplicate', monday.add(Duration(hours: 10))),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.days[0].eventCount, 2);
    });

    test('event with empty title', () {
      final events = [_event('1', '', monday)];
      final digest = service.generate(events, startDate: monday);
      final text = service.formatText(digest);
      expect(text, isNotEmpty);
    });

    test('event on last day of window is included', () {
      final events = [
        _event('1', 'Last Day', monday.add(Duration(days: 6, hours: 10))),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.days[6].eventCount, 1);
    });

    test('event on day after window is excluded', () {
      final events = [
        _event('1', 'Outside', monday.add(Duration(days: 7))),
      ];
      final digest = service.generate(events, startDate: monday);
      expect(digest.summary.totalEvents, 0);
    });
  });

  // ─── AgendaDigest properties ──────────────────────────────────────

  group('AgendaDigest', () {
    test('has correct start and end dates', () {
      final digest = service.generate(
        [],
        startDate: monday,
        config: DigestConfig(days: 7),
      );
      expect(digest.startDate, DateTime(2026, 2, 23));
      expect(digest.endDate, DateTime(2026, 3, 2));
    });

    test('preserves config', () {
      const config = DigestConfig(days: 14, groupByPriority: true);
      final digest = service.generate([], startDate: monday, config: config);
      expect(digest.config.days, 14);
      expect(digest.config.groupByPriority, true);
    });
  });

  // ─── Priority icon mapping ────────────────────────────────────────

  group('priority icons in output', () {
    test('urgent shows red circle', () {
      final events = [
        _event('1', 'X', monday, priority: EventPriority.urgent),
      ];
      final text = service.formatText(
        service.generate(events, startDate: monday),
      );
      expect(text, contains('🔴'));
    });

    test('high shows orange circle', () {
      final events = [
        _event('1', 'X', monday, priority: EventPriority.high),
      ];
      final text = service.formatText(
        service.generate(events, startDate: monday),
      );
      expect(text, contains('🟠'));
    });

    test('medium shows yellow circle', () {
      final events = [
        _event('1', 'X', monday, priority: EventPriority.medium),
      ];
      final text = service.formatText(
        service.generate(events, startDate: monday),
      );
      expect(text, contains('🟡'));
    });

    test('low shows green circle', () {
      final events = [
        _event('1', 'X', monday, priority: EventPriority.low),
      ];
      final text = service.formatText(
        service.generate(events, startDate: monday),
      );
      expect(text, contains('🟢'));
    });
  });
}
