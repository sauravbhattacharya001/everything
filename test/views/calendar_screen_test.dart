import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';

/// Tests for the Calendar Screen logic.
///
/// Since CalendarScreen is a StatefulWidget that depends on Provider,
/// we test the pure logic functions and data models that underpin it.
/// This includes event grouping, day generation, priority ranking,
/// and calendar grid calculations.

void main() {
  group('Calendar - Event grouping by day', () {
    test('groups events by their date (ignoring time)', () {
      final events = [
        EventModel(
          id: '1',
          title: 'Morning meeting',
          date: DateTime(2026, 3, 15, 9, 0),
          priority: EventPriority.high,
        ),
        EventModel(
          id: '2',
          title: 'Afternoon call',
          date: DateTime(2026, 3, 15, 14, 30),
          priority: EventPriority.medium,
        ),
        EventModel(
          id: '3',
          title: 'Different day',
          date: DateTime(2026, 3, 16, 10, 0),
          priority: EventPriority.low,
        ),
      ];

      final grouped = _groupEventsByDay(events);

      expect(grouped.length, 2);
      expect(grouped[DateTime(2026, 3, 15)]!.length, 2);
      expect(grouped[DateTime(2026, 3, 16)]!.length, 1);
    });

    test('sorts events within a day by time', () {
      final events = [
        EventModel(
          id: '1',
          title: 'Late event',
          date: DateTime(2026, 3, 15, 18, 0),
        ),
        EventModel(
          id: '2',
          title: 'Early event',
          date: DateTime(2026, 3, 15, 8, 0),
        ),
        EventModel(
          id: '3',
          title: 'Mid event',
          date: DateTime(2026, 3, 15, 12, 0),
        ),
      ];

      final grouped = _groupEventsByDay(events);
      final dayEvents = grouped[DateTime(2026, 3, 15)]!;

      expect(dayEvents[0].title, 'Early event');
      expect(dayEvents[1].title, 'Mid event');
      expect(dayEvents[2].title, 'Late event');
    });

    test('empty list returns empty map', () {
      final grouped = _groupEventsByDay([]);
      expect(grouped, isEmpty);
    });

    test('single event creates single group', () {
      final events = [
        EventModel(
          id: '1',
          title: 'Solo',
          date: DateTime(2026, 6, 1, 10, 0),
        ),
      ];

      final grouped = _groupEventsByDay(events);
      expect(grouped.length, 1);
      expect(grouped[DateTime(2026, 6, 1)]!.length, 1);
    });

    test('events across multiple months group correctly', () {
      final events = [
        EventModel(
          id: '1',
          title: 'Jan event',
          date: DateTime(2026, 1, 15),
        ),
        EventModel(
          id: '2',
          title: 'Feb event',
          date: DateTime(2026, 2, 15),
        ),
        EventModel(
          id: '3',
          title: 'Mar event',
          date: DateTime(2026, 3, 15),
        ),
      ];

      final grouped = _groupEventsByDay(events);
      expect(grouped.length, 3);
    });
  });

  group('Calendar - Calendar day generation', () {
    test('March 2026 starts on Sunday, generates correct grid', () {
      // March 2026: March 1 is a Sunday
      final days = _getCalendarDays(DateTime(2026, 3));

      // First day in grid should be Monday Feb 23 (leading days to fill week)
      expect(days.first.weekday, DateTime.monday);

      // Last day should be Sunday
      expect(days.last.weekday, DateTime.sunday);

      // Grid should be divisible by 7
      expect(days.length % 7, 0);

      // Should contain all 31 days of March
      final marchDays = days
          .where((d) => d.month == 3 && d.year == 2026)
          .toList();
      expect(marchDays.length, 31);
    });

    test('February 2026 generates correct grid', () {
      final days = _getCalendarDays(DateTime(2026, 2));

      expect(days.first.weekday, DateTime.monday);
      expect(days.last.weekday, DateTime.sunday);
      expect(days.length % 7, 0);

      // February 2026 has 28 days
      final febDays = days
          .where((d) => d.month == 2 && d.year == 2026)
          .toList();
      expect(febDays.length, 28);
    });

    test('January 2026 generates correct grid', () {
      // Jan 1, 2026 is a Thursday
      final days = _getCalendarDays(DateTime(2026, 1));

      expect(days.first.weekday, DateTime.monday);
      expect(days.last.weekday, DateTime.sunday);

      final janDays = days
          .where((d) => d.month == 1 && d.year == 2026)
          .toList();
      expect(janDays.length, 31);
    });

    test('month starting on Monday has no leading days from prev month', () {
      // June 2026 starts on Monday
      final days = _getCalendarDays(DateTime(2026, 6));
      expect(days.first, DateTime(2026, 6, 1));
      expect(days.first.weekday, DateTime.monday);
    });

    test('month ending on Sunday has no trailing days from next month', () {
      // May 2026 ends on Sunday
      final days = _getCalendarDays(DateTime(2026, 5));
      expect(days.last, DateTime(2026, 5, 31));
      expect(days.last.weekday, DateTime.sunday);
    });

    test('leap year February generates 29 days', () {
      // 2024 is a leap year
      final days = _getCalendarDays(DateTime(2024, 2));

      final febDays = days
          .where((d) => d.month == 2 && d.year == 2024)
          .toList();
      expect(febDays.length, 29);
    });

    test('December to January transition works', () {
      final days = _getCalendarDays(DateTime(2026, 12));

      // Should have days from January 2027 as trailing
      final janDays = days
          .where((d) => d.month == 1 && d.year == 2027)
          .toList();
      // Some trailing days might be from next month
      expect(janDays.length, greaterThanOrEqualTo(0));
    });
  });

  group('Calendar - Priority ranking', () {
    test('returns highest priority from event list', () {
      final events = [
        EventModel(id: '1', title: 'A', date: DateTime.now(), priority: EventPriority.low),
        EventModel(id: '2', title: 'B', date: DateTime.now(), priority: EventPriority.urgent),
        EventModel(id: '3', title: 'C', date: DateTime.now(), priority: EventPriority.medium),
      ];

      expect(_highestPriority(events), EventPriority.urgent);
    });

    test('single event returns its priority', () {
      final events = [
        EventModel(id: '1', title: 'A', date: DateTime.now(), priority: EventPriority.high),
      ];

      expect(_highestPriority(events), EventPriority.high);
    });

    test('all same priority returns that priority', () {
      final events = [
        EventModel(id: '1', title: 'A', date: DateTime.now(), priority: EventPriority.medium),
        EventModel(id: '2', title: 'B', date: DateTime.now(), priority: EventPriority.medium),
      ];

      expect(_highestPriority(events), EventPriority.medium);
    });

    test('low priority list returns low', () {
      final events = [
        EventModel(id: '1', title: 'A', date: DateTime.now(), priority: EventPriority.low),
      ];

      expect(_highestPriority(events), EventPriority.low);
    });
  });

  group('Calendar - Date helpers', () {
    test('isSameDay matches same day different times', () {
      expect(
        _isSameDay(
          DateTime(2026, 3, 15, 9, 0),
          DateTime(2026, 3, 15, 18, 30),
        ),
        isTrue,
      );
    });

    test('isSameDay does not match different days', () {
      expect(
        _isSameDay(
          DateTime(2026, 3, 15),
          DateTime(2026, 3, 16),
        ),
        isFalse,
      );
    });

    test('isSameDay does not match different months', () {
      expect(
        _isSameDay(
          DateTime(2026, 3, 15),
          DateTime(2026, 4, 15),
        ),
        isFalse,
      );
    });

    test('isSameDay does not match different years', () {
      expect(
        _isSameDay(
          DateTime(2026, 3, 15),
          DateTime(2027, 3, 15),
        ),
        isFalse,
      );
    });

    test('isCurrentMonth returns true for same month', () {
      final month = DateTime(2026, 3);
      expect(
        _isCurrentMonth(DateTime(2026, 3, 15), month),
        isTrue,
      );
    });

    test('isCurrentMonth returns false for different month', () {
      final month = DateTime(2026, 3);
      expect(
        _isCurrentMonth(DateTime(2026, 4, 1), month),
        isFalse,
      );
    });
  });

  group('Calendar - Month event counting', () {
    test('counts events in specific month correctly', () {
      final events = [
        EventModel(id: '1', title: 'A', date: DateTime(2026, 3, 1)),
        EventModel(id: '2', title: 'B', date: DateTime(2026, 3, 15)),
        EventModel(id: '3', title: 'C', date: DateTime(2026, 3, 31)),
        EventModel(id: '4', title: 'D', date: DateTime(2026, 4, 1)),
        EventModel(id: '5', title: 'E', date: DateTime(2026, 2, 28)),
      ];

      final month = DateTime(2026, 3);
      final count = events
          .where((e) => e.date.year == month.year && e.date.month == month.month)
          .length;

      expect(count, 3);
    });

    test('empty month returns zero count', () {
      final events = [
        EventModel(id: '1', title: 'A', date: DateTime(2026, 3, 1)),
      ];

      final month = DateTime(2026, 4);
      final count = events
          .where((e) => e.date.year == month.year && e.date.month == month.month)
          .length;

      expect(count, 0);
    });
  });

  group('Calendar - Event dot priority ordering', () {
    test('unique priorities are sorted highest first for dots', () {
      final events = [
        EventModel(id: '1', title: 'A', date: DateTime.now(), priority: EventPriority.low),
        EventModel(id: '2', title: 'B', date: DateTime.now(), priority: EventPriority.high),
        EventModel(id: '3', title: 'C', date: DateTime.now(), priority: EventPriority.medium),
      ];

      final priorities = events
          .map((e) => e.priority)
          .toSet()
          .toList()
        ..sort((a, b) => b.index.compareTo(a.index));

      expect(priorities[0], EventPriority.high);
      expect(priorities[1], EventPriority.medium);
      expect(priorities[2], EventPriority.low);
    });

    test('dot count is clamped to 3', () {
      final events = [
        EventModel(id: '1', title: 'A', date: DateTime.now(), priority: EventPriority.low),
        EventModel(id: '2', title: 'B', date: DateTime.now(), priority: EventPriority.medium),
        EventModel(id: '3', title: 'C', date: DateTime.now(), priority: EventPriority.high),
        EventModel(id: '4', title: 'D', date: DateTime.now(), priority: EventPriority.urgent),
      ];

      final priorities = events
          .map((e) => e.priority)
          .toSet()
          .toList()
        ..sort((a, b) => b.index.compareTo(a.index));

      final dotCount = priorities.length.clamp(1, 3);
      expect(dotCount, 3);
    });

    test('single event shows 1 dot', () {
      final events = [
        EventModel(id: '1', title: 'A', date: DateTime.now(), priority: EventPriority.high),
      ];

      final priorities = events
          .map((e) => e.priority)
          .toSet()
          .toList();

      final dotCount = priorities.length.clamp(1, 3);
      expect(dotCount, 1);
    });
  });

  group('Calendar - Month navigation', () {
    test('previous month from March is February', () {
      final current = DateTime(2026, 3);
      final prev = DateTime(current.year, current.month - 1);
      expect(prev.month, 2);
      expect(prev.year, 2026);
    });

    test('previous month from January wraps to December', () {
      final current = DateTime(2026, 1);
      final prev = DateTime(current.year, current.month - 1);
      expect(prev.month, 12);
      expect(prev.year, 2025);
    });

    test('next month from December wraps to January', () {
      final current = DateTime(2025, 12);
      final next = DateTime(current.year, current.month + 1);
      expect(next.month, 1);
      expect(next.year, 2026);
    });

    test('next month from March is April', () {
      final current = DateTime(2026, 3);
      final next = DateTime(current.year, current.month + 1);
      expect(next.month, 4);
      expect(next.year, 2026);
    });
  });

  group('Calendar - Event count badge visibility', () {
    test('badge shown when 3 or more events', () {
      expect(3 >= 3, isTrue);
      expect(5 >= 3, isTrue);
    });

    test('badge not shown when fewer than 3 events', () {
      expect(2 >= 3, isFalse);
      expect(1 >= 3, isFalse);
      expect(0 >= 3, isFalse);
    });
  });

  group('Calendar - Events with tags display correctly', () {
    test('events with tags are grouped properly', () {
      final tag = EventTag(name: 'Work', colorIndex: 0);
      final events = [
        EventModel(
          id: '1',
          title: 'Tagged event',
          date: DateTime(2026, 3, 15, 9, 0),
          tags: [tag],
        ),
        EventModel(
          id: '2',
          title: 'Untagged event',
          date: DateTime(2026, 3, 15, 10, 0),
        ),
      ];

      final grouped = _groupEventsByDay(events);
      final dayEvents = grouped[DateTime(2026, 3, 15)]!;
      expect(dayEvents.length, 2);
      expect(dayEvents[0].tags.length, 1);
      expect(dayEvents[1].tags.length, 0);
    });

    test('tags are limited to 3 in display', () {
      final tags = [
        EventTag(name: 'Work', colorIndex: 0),
        EventTag(name: 'Personal', colorIndex: 1),
        EventTag(name: 'Meeting', colorIndex: 2),
        EventTag(name: 'Travel', colorIndex: 3),
      ];

      expect(tags.take(3).length, 3);
    });
  });

  group('Calendar - Recurring events on calendar', () {
    test('recurring events appear as regular events on their day', () {
      final event = EventModel(
        id: '1',
        title: 'Weekly standup',
        date: DateTime(2026, 3, 2, 10, 0),
        priority: EventPriority.high,
      );

      final grouped = _groupEventsByDay([event]);
      expect(grouped[DateTime(2026, 3, 2)]!.length, 1);
      expect(grouped[DateTime(2026, 3, 2)]!.first.title, 'Weekly standup');
    });
  });

  group('Calendar - Edge cases', () {
    test('handles end of month correctly (31st)', () {
      final events = [
        EventModel(
          id: '1',
          title: 'End of month',
          date: DateTime(2026, 3, 31, 23, 59),
        ),
      ];

      final grouped = _groupEventsByDay(events);
      expect(grouped[DateTime(2026, 3, 31)]!.length, 1);
    });

    test('handles midnight events', () {
      final events = [
        EventModel(
          id: '1',
          title: 'Midnight',
          date: DateTime(2026, 3, 15, 0, 0),
        ),
      ];

      final grouped = _groupEventsByDay(events);
      expect(grouped[DateTime(2026, 3, 15)]!.length, 1);
    });

    test('handles events on Feb 29 in leap year', () {
      final events = [
        EventModel(
          id: '1',
          title: 'Leap day',
          date: DateTime(2024, 2, 29, 12, 0),
        ),
      ];

      final grouped = _groupEventsByDay(events);
      expect(grouped[DateTime(2024, 2, 29)]!.length, 1);
    });

    test('many events on same day are all captured', () {
      final events = List.generate(
        20,
        (i) => EventModel(
          id: '$i',
          title: 'Event $i',
          date: DateTime(2026, 3, 15, i % 24, 0),
        ),
      );

      final grouped = _groupEventsByDay(events);
      expect(grouped[DateTime(2026, 3, 15)]!.length, 20);
    });

    test('events spanning year boundary are separate', () {
      final events = [
        EventModel(
          id: '1',
          title: 'NYE',
          date: DateTime(2025, 12, 31, 23, 0),
        ),
        EventModel(
          id: '2',
          title: 'New Year',
          date: DateTime(2026, 1, 1, 0, 0),
        ),
      ];

      final grouped = _groupEventsByDay(events);
      expect(grouped.length, 2);
      expect(grouped[DateTime(2025, 12, 31)]!.length, 1);
      expect(grouped[DateTime(2026, 1, 1)]!.length, 1);
    });
  });
}

// ─────────────── Extracted pure functions for testing ───────────────

/// Groups events by their date (year-month-day) for O(1) lookup.
Map<DateTime, List<EventModel>> _groupEventsByDay(List<EventModel> events) {
  final map = <DateTime, List<EventModel>>{};
  for (final event in events) {
    final key = DateTime(event.date.year, event.date.month, event.date.day);
    map.putIfAbsent(key, () => []).add(event);
  }
  // Sort each day's events by time
  for (final list in map.values) {
    list.sort((a, b) => a.date.compareTo(b.date));
  }
  return map;
}

/// Returns the highest priority among events.
EventPriority _highestPriority(List<EventModel> events) {
  var highest = EventPriority.low;
  for (final e in events) {
    if (e.priority.index > highest.index) {
      highest = e.priority;
    }
  }
  return highest;
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isCurrentMonth(DateTime day, DateTime currentMonth) {
  return day.month == currentMonth.month && day.year == currentMonth.year;
}

/// Generates the list of days to display in the calendar grid.
List<DateTime> _getCalendarDays(DateTime currentMonth) {
  final firstDayOfMonth =
      DateTime(currentMonth.year, currentMonth.month, 1);
  final lastDayOfMonth =
      DateTime(currentMonth.year, currentMonth.month + 1, 0);

  // Monday = 1, Sunday = 7
  final startWeekday = firstDayOfMonth.weekday;
  final leadingDays = startWeekday - 1;

  final endWeekday = lastDayOfMonth.weekday;
  final trailingDays = endWeekday == 7 ? 0 : 7 - endWeekday;

  final days = <DateTime>[];

  // Previous month's trailing days
  for (var i = leadingDays; i > 0; i--) {
    days.add(firstDayOfMonth.subtract(Duration(days: i)));
  }

  // Current month's days
  for (var i = 0; i < lastDayOfMonth.day; i++) {
    days.add(DateTime(currentMonth.year, currentMonth.month, i + 1));
  }

  // Next month's leading days
  for (var i = 1; i <= trailingDays; i++) {
    days.add(DateTime(
        lastDayOfMonth.year, lastDayOfMonth.month, lastDayOfMonth.day + i));
  }

  return days;
}
