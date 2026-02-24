import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/ics_export_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/reminder_settings.dart';

void main() {
  late IcsExportService service;

  setUp(() {
    service = IcsExportService();
  });

  group('VALARM export', () {
    test('event with no reminders has no VALARM', () {
      final event = EventModel(
        id: 'test-1',
        title: 'No Reminder Event',
        date: DateTime(2026, 3, 1, 14, 0),
      );
      final ics = service.exportEvent(event);
      expect(ics, isNot(contains('BEGIN:VALARM')));
      expect(ics, isNot(contains('END:VALARM')));
    });

    test('event with 15min reminder includes VALARM', () {
      final event = EventModel(
        id: 'test-2',
        title: 'Reminder Event',
        date: DateTime(2026, 3, 1, 14, 0),
        reminders: const ReminderSettings(
          offsets: [ReminderOffset.fifteenMinutes],
        ),
      );
      final ics = service.exportEvent(event);
      expect(ics, contains('BEGIN:VALARM'));
      expect(ics, contains('ACTION:DISPLAY'));
      expect(ics, contains('TRIGGER:-PT15M'));
      expect(ics, contains('END:VALARM'));
    });

    test('event with multiple reminders includes multiple VALARMs', () {
      final event = EventModel(
        id: 'test-3',
        title: 'Multi Reminder',
        date: DateTime(2026, 3, 1, 14, 0),
        reminders: const ReminderSettings(
          offsets: [ReminderOffset.fifteenMinutes, ReminderOffset.oneHour, ReminderOffset.oneDay],
        ),
      );
      final ics = service.exportEvent(event);
      // Count VALARM blocks
      final valarmCount = 'BEGIN:VALARM'.allMatches(ics).length;
      expect(valarmCount, 3);
      expect(ics, contains('TRIGGER:-PT15M'));
      expect(ics, contains('TRIGGER:-PT1H'));
      expect(ics, contains('TRIGGER:-P1D'));
    });

    test('at-time reminder uses PT0S trigger', () {
      final event = EventModel(
        id: 'test-4',
        title: 'At Time Event',
        date: DateTime(2026, 3, 1, 14, 0),
        reminders: const ReminderSettings(
          offsets: [ReminderOffset.atTime],
        ),
      );
      final ics = service.exportEvent(event);
      expect(ics, contains('TRIGGER:PT0S'));
    });

    test('2-hour reminder uses PT2H trigger', () {
      final event = EventModel(
        id: 'test-5',
        title: 'Two Hour',
        date: DateTime(2026, 3, 1, 14, 0),
        reminders: const ReminderSettings(
          offsets: [ReminderOffset.twoHours],
        ),
      );
      final ics = service.exportEvent(event);
      expect(ics, contains('TRIGGER:-PT2H'));
    });

    test('1-week reminder uses P7D trigger', () {
      final event = EventModel(
        id: 'test-6',
        title: 'Week Ahead',
        date: DateTime(2026, 3, 1, 14, 0),
        reminders: const ReminderSettings(
          offsets: [ReminderOffset.oneWeek],
        ),
      );
      final ics = service.exportEvent(event);
      expect(ics, contains('TRIGGER:-P7D'));
    });

    test('VALARM appears inside VEVENT', () {
      final event = EventModel(
        id: 'test-7',
        title: 'Nested',
        date: DateTime(2026, 3, 1, 14, 0),
        reminders: const ReminderSettings(
          offsets: [ReminderOffset.thirtyMinutes],
        ),
      );
      final ics = service.exportEvent(event);
      final veventStart = ics.indexOf('BEGIN:VEVENT');
      final veventEnd = ics.indexOf('END:VEVENT');
      final valarmStart = ics.indexOf('BEGIN:VALARM');
      final valarmEnd = ics.indexOf('END:VALARM');
      expect(valarmStart, greaterThan(veventStart));
      expect(valarmEnd, lessThan(veventEnd));
    });

    test('bulk export preserves VALARMs', () {
      final events = [
        EventModel(
          id: 'b-1',
          title: 'First',
          date: DateTime(2026, 3, 1),
          reminders: const ReminderSettings(
            offsets: [ReminderOffset.fiveMinutes],
          ),
        ),
        EventModel(
          id: 'b-2',
          title: 'Second',
          date: DateTime(2026, 3, 2),
        ),
      ];
      final ics = service.exportEvents(events);
      expect('BEGIN:VALARM'.allMatches(ics).length, 1);
      expect(ics, contains('TRIGGER:-PT5M'));
    });
  });
}
