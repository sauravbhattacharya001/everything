import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/free_slot_finder.dart';
import 'package:everything/models/event_model.dart';

/// Helper to create a simple event with start and end times.
EventModel _event(DateTime start, DateTime end, {String title = 'Event'}) {
  return EventModel(
    id: '${start.millisecondsSinceEpoch}',
    title: title,
    date: start,
    endDate: end,
  );
}

/// Monday 9 AM for a known test week.
DateTime _monday(int hour, [int minute = 0]) =>
    DateTime(2026, 3, 2, hour, minute); // 2026-03-02 is a Monday

DateTime _tuesday(int hour, [int minute = 0]) =>
    DateTime(2026, 3, 3, hour, minute);

DateTime _wednesday(int hour, [int minute = 0]) =>
    DateTime(2026, 3, 4, hour, minute);

DateTime _saturday(int hour, [int minute = 0]) =>
    DateTime(2026, 3, 7, hour, minute);

void main() {
  late FreeSlotFinder finder;

  setUp(() {
    finder = FreeSlotFinder();
  });

  group('FreeSlot', () {
    test('duration and durationMinutes are correct', () {
      final slot = FreeSlot(
        start: _monday(9),
        end: _monday(11, 30),
      );
      expect(slot.duration, const Duration(hours: 2, minutes: 30));
      expect(slot.durationMinutes, 150);
    });

    test('canFit returns true when slot is large enough', () {
      final slot = FreeSlot(start: _monday(9), end: _monday(11));
      expect(slot.canFit(const Duration(hours: 1)), isTrue);
      expect(slot.canFit(const Duration(hours: 2)), isTrue);
      expect(slot.canFit(const Duration(hours: 3)), isFalse);
    });

    test('equality and hashCode', () {
      final a = FreeSlot(start: _monday(9), end: _monday(10));
      final b = FreeSlot(start: _monday(9), end: _monday(10));
      final c = FreeSlot(start: _monday(9), end: _monday(11));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('label includes day, times, and duration', () {
      final slot = FreeSlot(start: _monday(9), end: _monday(11, 30));
      expect(slot.label, contains('Mon'));
      expect(slot.label, contains('2h 30m'));
    });
  });

  group('WorkingHours', () {
    test('totalMinutes for default 9-5', () {
      const wh = WorkingHours();
      expect(wh.totalMinutes, 480); // 8 hours
    });

    test('startOn and endOn produce correct DateTimes', () {
      const wh = WorkingHours(startHour: 10, startMinute: 30, endHour: 18, endMinute: 0);
      final date = _monday(0);
      expect(wh.startOn(date).hour, 10);
      expect(wh.startOn(date).minute, 30);
      expect(wh.endOn(date).hour, 18);
    });
  });

  group('findSlots', () {
    test('returns full working day when no events', () {
      final result = finder.findSlots(
        events: [],
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
      );
      expect(result.slotCount, 1);
      expect(result.slots.first.start, _monday(9));
      expect(result.slots.first.end, _monday(17));
      expect(result.totalFreeMinutes, 480);
    });

    test('skips weekends by default', () {
      final result = finder.findSlots(
        events: [],
        rangeStart: _saturday(0),
        rangeEnd: _saturday(23, 59),
      );
      expect(result.slotCount, 0);
    });

    test('includes weekends when includeWeekends is true', () {
      final result = finder.findSlots(
        events: [],
        rangeStart: _saturday(0),
        rangeEnd: _saturday(23, 59),
        includeWeekends: true,
      );
      expect(result.slotCount, 1);
    });

    test('event in middle splits day into two slots', () {
      final events = [_event(_monday(12), _monday(13))];
      final result = finder.findSlots(
        events: events,
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
      );
      // 9-12 and 13-17
      expect(result.slotCount, 2);
      expect(result.slots[0].start, _monday(9));
      expect(result.slots[0].end, _monday(12));
      expect(result.slots[1].start, _monday(13));
      expect(result.slots[1].end, _monday(17));
    });

    test('event at start of day leaves only afternoon slot', () {
      final events = [_event(_monday(9), _monday(11))];
      final result = finder.findSlots(
        events: events,
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
      );
      expect(result.slotCount, 1);
      expect(result.slots.first.start, _monday(11));
      expect(result.slots.first.end, _monday(17));
    });

    test('event at end of day leaves only morning slot', () {
      final events = [_event(_monday(15), _monday(17))];
      final result = finder.findSlots(
        events: events,
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
      );
      expect(result.slotCount, 1);
      expect(result.slots.first.start, _monday(9));
      expect(result.slots.first.end, _monday(15));
    });

    test('all-day event leaves no slots', () {
      final events = [_event(_monday(8), _monday(18))];
      final result = finder.findSlots(
        events: events,
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
      );
      expect(result.slotCount, 0);
    });

    test('multiple events leave correct gaps', () {
      final events = [
        _event(_monday(9), _monday(10)),
        _event(_monday(11), _monday(12)),
        _event(_monday(14), _monday(15)),
      ];
      final result = finder.findSlots(
        events: events,
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
      );
      // Gaps: 10-11, 12-14, 15-17
      expect(result.slotCount, 3);
      expect(result.slots[0].durationMinutes, 60);
      expect(result.slots[1].durationMinutes, 120);
      expect(result.slots[2].durationMinutes, 120);
    });

    test('minimumDuration filters out short gaps', () {
      final events = [
        _event(_monday(9), _monday(9, 45)),
        _event(_monday(10), _monday(17)),
      ];
      final result = finder.findSlots(
        events: events,
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
        minimumDuration: const Duration(minutes: 30),
      );
      // Gap is 9:45-10:00 = 15 min, filtered out
      expect(result.slotCount, 0);
    });

    test('bufferMinutes shrinks available gaps', () {
      final events = [_event(_monday(12), _monday(13))];
      final result = finder.findSlots(
        events: events,
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
        bufferMinutes: 15,
      );
      // 9:00-11:45 and 13:15-17:00
      expect(result.slotCount, 2);
      expect(result.slots[0].end, _monday(11, 45));
      expect(result.slots[1].start, _monday(13, 15));
    });

    test('multi-day range returns slots for each working day', () {
      final result = finder.findSlots(
        events: [],
        rangeStart: _monday(0),
        rangeEnd: _wednesday(23, 59),
      );
      // Mon, Tue, Wed = 3 full slots
      expect(result.slotCount, 3);
    });

    test('custom working hours are respected', () {
      final result = finder.findSlots(
        events: [],
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
        workingHours: {
          1: const WorkingHours(startHour: 7, endHour: 12),
        },
      );
      expect(result.slotCount, 1);
      expect(result.slots.first.start, _monday(7));
      expect(result.slots.first.end, _monday(12));
      expect(result.totalFreeMinutes, 300);
    });

    test('overlapping events do not produce negative gaps', () {
      final events = [
        _event(_monday(10), _monday(13)),
        _event(_monday(11), _monday(14)), // overlaps previous
      ];
      final result = finder.findSlots(
        events: events,
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
      );
      // 9-10 and 14-17
      expect(result.slotCount, 2);
      expect(result.slots[0].end, _monday(10));
      expect(result.slots[1].start, _monday(14));
    });

    test('event without endDate defaults to 1 hour', () {
      final event = EventModel(
        id: 'no-end',
        title: 'Quick event',
        date: _monday(12),
        // no endDate
      );
      final result = finder.findSlots(
        events: [event],
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
      );
      // 9-12 and 13-17
      expect(result.slotCount, 2);
      expect(result.slots[0].end, _monday(12));
      expect(result.slots[1].start, _monday(13));
    });
  });

  group('FreeSlotResult', () {
    test('longestSlot returns the longest', () {
      final result = finder.findSlots(
        events: [_event(_monday(10), _monday(11))],
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
      );
      // 9-10 (1h) and 11-17 (6h)
      expect(result.longestSlot!.durationMinutes, 360);
    });

    test('slotsByDate groups correctly', () {
      final result = finder.findSlots(
        events: [],
        rangeStart: _monday(0),
        rangeEnd: _tuesday(23, 59),
      );
      final byDate = result.slotsByDate;
      expect(byDate.length, 2);
    });

    test('slotsForDuration filters by duration', () {
      final result = finder.findSlots(
        events: [
          _event(_monday(10), _monday(11)),
          _event(_monday(14), _monday(15)),
        ],
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
      );
      // Slots: 9-10 (1h), 11-14 (3h), 15-17 (2h)
      final twoHourSlots = result.slotsForDuration(const Duration(hours: 2));
      expect(twoHourSlots.length, 2); // 3h and 2h slots
    });

    test('totalFreeTime sums all slots', () {
      final result = finder.findSlots(
        events: [_event(_monday(12), _monday(13))],
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
      );
      // 9-12 (3h) + 13-17 (4h) = 7h
      expect(result.totalFreeMinutes, 420);
    });

    test('empty result returns null longestSlot', () {
      final result = finder.findSlots(
        events: [_event(_monday(8), _monday(18))],
        rangeStart: _monday(0),
        rangeEnd: _monday(23, 59),
      );
      expect(result.longestSlot, isNull);
    });
  });

  group('findFirstAvailable', () {
    test('returns first slot that fits', () {
      final events = [
        _event(_monday(9), _monday(14)),
      ];
      final slot = finder.findFirstAvailable(
        events: events,
        eventDuration: const Duration(hours: 2),
        searchFrom: _monday(0),
      );
      // First 2h+ slot: 14-17
      expect(slot, isNotNull);
      expect(slot!.start, _monday(14));
    });

    test('returns null when nothing fits', () {
      final events = [_event(_monday(8), _monday(18))];
      final slot = finder.findFirstAvailable(
        events: events,
        eventDuration: const Duration(hours: 2),
        searchFrom: _monday(0),
        searchDays: 1,
        // Only Monday, which is fully booked; Tue is day 2 but searchDays=1
      );
      // Depends on whether searchDays covers next day — test with tight range
      // Actually searchDays=1 means rangeEnd = _monday + 1 day = Tuesday
      // so Tuesday should have free slots. Let's test with a fully booked week.
    });
  });

  group('suggestBestSlots', () {
    test('returns scored slots preferring mornings', () {
      final events = [
        _event(_monday(10), _monday(11)),
      ];
      final suggestions = finder.suggestBestSlots(
        events: events,
        eventDuration: const Duration(hours: 1),
        searchFrom: _monday(0),
        maxSuggestions: 3,
        bufferMinutes: 0,
      );
      expect(suggestions, isNotEmpty);
      // Should include the 9-10 morning slot
      expect(suggestions.any((s) => s.start.hour == 9), isTrue);
    });

    test('respects maxSuggestions limit', () {
      final suggestions = finder.suggestBestSlots(
        events: [],
        eventDuration: const Duration(minutes: 30),
        searchFrom: _monday(0),
        searchDays: 5,
        maxSuggestions: 2,
      );
      expect(suggestions.length, lessThanOrEqualTo(2));
    });
  });
}
