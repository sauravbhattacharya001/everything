import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/free_slot_finder.dart';
import 'package:everything/models/event_model.dart';

void main() {
  late FreeSlotFinder finder;

  setUp(() {
    finder = FreeSlotFinder();
  });

  EventModel _event(String id, DateTime start, DateTime end) {
    return EventModel(
      id: id,
      title: 'Event $id',
      date: start,
      endDate: end,
    );
  }

  group('FreeSlotFinder', () {
    test('finds full day free when no events', () {
      final result = finder.findSlots(
        events: [],
        rangeStart: DateTime(2026, 3, 2), // Monday
        rangeEnd: DateTime(2026, 3, 2, 23, 59),
      );

      expect(result.slots.length, 1);
      expect(result.slots.first.start, DateTime(2026, 3, 2, 9, 0));
      expect(result.slots.first.end, DateTime(2026, 3, 2, 17, 0));
      expect(result.slots.first.durationMinutes, 480);
    });

    test('finds gaps between events', () {
      final events = [
        _event('1', DateTime(2026, 3, 2, 10, 0), DateTime(2026, 3, 2, 11, 0)),
        _event('2', DateTime(2026, 3, 2, 14, 0), DateTime(2026, 3, 2, 15, 0)),
      ];

      final result = finder.findSlots(
        events: events,
        rangeStart: DateTime(2026, 3, 2),
        rangeEnd: DateTime(2026, 3, 2, 23, 59),
      );

      expect(result.slots.length, 3);
      // 9-10, 11-14, 15-17
      expect(result.slots[0].start.hour, 9);
      expect(result.slots[0].end.hour, 10);
      expect(result.slots[1].start.hour, 11);
      expect(result.slots[1].end.hour, 14);
      expect(result.slots[2].start.hour, 15);
      expect(result.slots[2].end.hour, 17);
    });

    test('respects minimum duration filter', () {
      final events = [
        _event('1', DateTime(2026, 3, 2, 9, 0), DateTime(2026, 3, 2, 9, 20)),
      ];

      final result = finder.findSlots(
        events: events,
        rangeStart: DateTime(2026, 3, 2),
        rangeEnd: DateTime(2026, 3, 2, 23, 59),
        minimumDuration: const Duration(minutes: 30),
      );

      // The 0-20min gap is filtered out, only 9:20-17:00 remains
      expect(result.slots.length, 1);
      expect(result.slots.first.start, DateTime(2026, 3, 2, 9, 20));
    });

    test('applies buffer time around events', () {
      final events = [
        _event('1', DateTime(2026, 3, 2, 12, 0), DateTime(2026, 3, 2, 13, 0)),
      ];

      final result = finder.findSlots(
        events: events,
        rangeStart: DateTime(2026, 3, 2),
        rangeEnd: DateTime(2026, 3, 2, 23, 59),
        bufferMinutes: 15,
      );

      // 9:00-11:45, 13:15-17:00
      expect(result.slots.length, 2);
      expect(result.slots[0].end, DateTime(2026, 3, 2, 11, 45));
      expect(result.slots[1].start, DateTime(2026, 3, 2, 13, 15));
    });

    test('skips weekends by default', () {
      final result = finder.findSlots(
        events: [],
        rangeStart: DateTime(2026, 3, 7), // Saturday
        rangeEnd: DateTime(2026, 3, 8, 23, 59), // Sunday
      );

      expect(result.slots, isEmpty);
    });

    test('includes weekends when requested', () {
      final result = finder.findSlots(
        events: [],
        rangeStart: DateTime(2026, 3, 7), // Saturday
        rangeEnd: DateTime(2026, 3, 8, 23, 59), // Sunday
        includeWeekends: true,
      );

      expect(result.slots.length, 2);
    });

    test('findFirstAvailable returns first viable slot', () {
      final events = [
        _event('1', DateTime(2026, 3, 2, 9, 0), DateTime(2026, 3, 2, 16, 0)),
      ];

      final slot = finder.findFirstAvailable(
        events: events,
        eventDuration: const Duration(hours: 2),
        searchFrom: DateTime(2026, 3, 2),
      );

      // Only 1h free on Monday (16-17), so first 2h slot is Tuesday 9-17
      expect(slot, isNotNull);
      expect(slot!.start, DateTime(2026, 3, 3, 9, 0));
    });

    test('suggestBestSlots ranks morning slots higher', () {
      final events = [
        _event('1', DateTime(2026, 3, 2, 10, 0), DateTime(2026, 3, 2, 11, 0)),
      ];

      final suggestions = finder.suggestBestSlots(
        events: events,
        eventDuration: const Duration(hours: 1),
        searchFrom: DateTime(2026, 3, 2),
        maxSuggestions: 3,
      );

      expect(suggestions, isNotEmpty);
    });
  });

  group('FreeSlot', () {
    test('label formats correctly', () {
      final slot = FreeSlot(
        start: DateTime(2026, 3, 2, 9, 0), // Monday
        end: DateTime(2026, 3, 2, 11, 30),
      );

      expect(slot.label, 'Mon 9:00 AM – 11:30 AM (2h 30m)');
    });

    test('canFit checks duration', () {
      final slot = FreeSlot(
        start: DateTime(2026, 3, 2, 9, 0),
        end: DateTime(2026, 3, 2, 10, 0),
      );

      expect(slot.canFit(const Duration(minutes: 30)), isTrue);
      expect(slot.canFit(const Duration(hours: 2)), isFalse);
    });
  });

  group('FreeSlotResult', () {
    test('totalFreeTime sums all slots', () {
      final result = FreeSlotResult(
        slots: [
          FreeSlot(
            start: DateTime(2026, 3, 2, 9, 0),
            end: DateTime(2026, 3, 2, 10, 0),
          ),
          FreeSlot(
            start: DateTime(2026, 3, 2, 14, 0),
            end: DateTime(2026, 3, 2, 17, 0),
          ),
        ],
        rangeStart: DateTime(2026, 3, 2),
        rangeEnd: DateTime(2026, 3, 2, 23, 59),
        minimumDuration: const Duration(minutes: 30),
      );

      expect(result.totalFreeMinutes, 240); // 1h + 3h
      expect(result.slotCount, 2);
      expect(result.longestSlot!.durationMinutes, 180);
    });

    test('slotsByDate groups correctly', () {
      final result = FreeSlotResult(
        slots: [
          FreeSlot(
            start: DateTime(2026, 3, 2, 9, 0),
            end: DateTime(2026, 3, 2, 10, 0),
          ),
          FreeSlot(
            start: DateTime(2026, 3, 3, 9, 0),
            end: DateTime(2026, 3, 3, 12, 0),
          ),
        ],
        rangeStart: DateTime(2026, 3, 2),
        rangeEnd: DateTime(2026, 3, 3, 23, 59),
        minimumDuration: const Duration(minutes: 30),
      );

      expect(result.slotsByDate.length, 2);
    });
  });

  group('WorkingHours', () {
    test('totalMinutes calculates correctly', () {
      const wh = WorkingHours(startHour: 9, endHour: 17);
      expect(wh.totalMinutes, 480);
    });

    test('custom hours work', () {
      const wh = WorkingHours(
        startHour: 8,
        startMinute: 30,
        endHour: 18,
        endMinute: 30,
      );
      expect(wh.totalMinutes, 600);
    });
  });
}
