import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/ics_export_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';
import 'package:everything/models/recurrence_rule.dart';

void main() {
  late IcsExportService service;

  setUp(() {
    service = IcsExportService();
  });

  EventModel _makeEvent({
    String id = 'test-123',
    String title = 'Team Meeting',
    String description = 'Weekly sync with the team',
    DateTime? date,
    EventPriority priority = EventPriority.medium,
    List<EventTag>? tags,
    RecurrenceRule? recurrence,
  }) {
    return EventModel(
      id: id,
      title: title,
      description: description,
      date: date ?? DateTime(2026, 3, 15, 14, 30),
      priority: priority,
      tags: tags,
      recurrence: recurrence,
    );
  }

  group('IcsExportService - Single Event Export', () {
    test('generates valid VCALENDAR wrapper', () {
      final event = _makeEvent();
      final ics = service.exportEvent(event);

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('END:VCALENDAR'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('CALSCALE:GREGORIAN'));
      expect(ics, contains('METHOD:PUBLISH'));
    });

    test('contains PRODID', () {
      final ics = service.exportEvent(_makeEvent());
      expect(ics, contains('PRODID:'));
      expect(ics, contains('Everything App'));
    });

    test('generates VEVENT block', () {
      final ics = service.exportEvent(_makeEvent());
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('END:VEVENT'));
    });

    test('includes UID from event id', () {
      final ics = service.exportEvent(_makeEvent(id: 'abc-456'));
      expect(ics, contains('UID:abc-456@everything.app'));
    });

    test('includes DTSTAMP', () {
      final ics = service.exportEvent(_makeEvent());
      expect(ics, contains('DTSTAMP:'));
    });

    test('formats DTSTART correctly', () {
      final event = _makeEvent(date: DateTime(2026, 3, 15, 14, 30, 0));
      final ics = service.exportEvent(event);
      expect(ics, contains('DTSTART:20260315T143000'));
    });

    test('formats DTEND as 1 hour after start', () {
      final event = _makeEvent(date: DateTime(2026, 3, 15, 14, 30, 0));
      final ics = service.exportEvent(event);
      expect(ics, contains('DTEND:20260315T153000'));
    });

    test('includes SUMMARY with title', () {
      final ics = service.exportEvent(_makeEvent(title: 'My Event'));
      expect(ics, contains('SUMMARY:My Event'));
    });

    test('includes DESCRIPTION when present', () {
      final ics = service.exportEvent(_makeEvent(description: 'Details here'));
      expect(ics, contains('DESCRIPTION:'));
      expect(ics, contains('Details here'));
    });

    test('omits DESCRIPTION for empty events', () {
      final event = _makeEvent(description: '', tags: []);
      final ics = service.exportEvent(event);
      expect(ics, isNot(contains('DESCRIPTION:')));
    });

    test('includes priority label in description', () {
      final ics = service.exportEvent(_makeEvent(priority: EventPriority.high));
      expect(ics, contains('Priority: High'));
    });

    test('includes tags in description', () {
      final event = _makeEvent(tags: [
        const EventTag(name: 'Work', colorIndex: 0),
        const EventTag(name: 'Meeting', colorIndex: 2),
      ]);
      final ics = service.exportEvent(event);
      expect(ics, contains('Tags: Work\\, Meeting'));
    });

    test('includes CATEGORIES from tags', () {
      final event = _makeEvent(tags: [
        const EventTag(name: 'Work', colorIndex: 0),
      ]);
      final ics = service.exportEvent(event);
      expect(ics, contains('CATEGORIES:Work'));
    });

    test('omits CATEGORIES when no tags', () {
      final ics = service.exportEvent(_makeEvent(tags: []));
      expect(ics, isNot(contains('CATEGORIES:')));
    });
  });

  group('IcsExportService - Priority Mapping', () {
    test('maps urgent to RFC 5545 priority 1', () {
      final ics = service.exportEvent(_makeEvent(priority: EventPriority.urgent));
      expect(ics, contains('PRIORITY:1'));
    });

    test('maps high to RFC 5545 priority 3', () {
      final ics = service.exportEvent(_makeEvent(priority: EventPriority.high));
      expect(ics, contains('PRIORITY:3'));
    });

    test('maps medium to RFC 5545 priority 5', () {
      final ics = service.exportEvent(_makeEvent(priority: EventPriority.medium));
      expect(ics, contains('PRIORITY:5'));
    });

    test('maps low to RFC 5545 priority 9', () {
      final ics = service.exportEvent(_makeEvent(priority: EventPriority.low));
      expect(ics, contains('PRIORITY:9'));
    });
  });

  group('IcsExportService - Recurrence Rules', () {
    test('generates daily RRULE', () {
      final event = _makeEvent(
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
      );
      final ics = service.exportEvent(event);
      expect(ics, contains('RRULE:FREQ=DAILY'));
    });

    test('generates weekly RRULE', () {
      final event = _makeEvent(
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.weekly),
      );
      final ics = service.exportEvent(event);
      expect(ics, contains('RRULE:FREQ=WEEKLY'));
    });

    test('generates monthly RRULE', () {
      final event = _makeEvent(
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.monthly),
      );
      final ics = service.exportEvent(event);
      expect(ics, contains('RRULE:FREQ=MONTHLY'));
    });

    test('generates yearly RRULE', () {
      final event = _makeEvent(
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.yearly),
      );
      final ics = service.exportEvent(event);
      expect(ics, contains('RRULE:FREQ=YEARLY'));
    });

    test('includes INTERVAL when > 1', () {
      final event = _makeEvent(
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
        ),
      );
      final ics = service.exportEvent(event);
      expect(ics, contains('INTERVAL=2'));
    });

    test('omits INTERVAL when 1', () {
      final event = _makeEvent(
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
        ),
      );
      final ics = service.exportEvent(event);
      expect(ics, isNot(contains('INTERVAL=')));
    });

    test('includes UNTIL when endDate set', () {
      final event = _makeEvent(
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          endDate: DateTime(2026, 12, 31, 23, 59),
        ),
      );
      final ics = service.exportEvent(event);
      expect(ics, contains('UNTIL=20261231T235900'));
    });

    test('omits RRULE for non-recurring events', () {
      final ics = service.exportEvent(_makeEvent(recurrence: null));
      expect(ics, isNot(contains('RRULE:')));
    });
  });

  group('IcsExportService - Text Escaping', () {
    test('escapes commas in title', () {
      final ics = service.exportEvent(_makeEvent(title: 'Meeting, Room A'));
      expect(ics, contains('SUMMARY:Meeting\\, Room A'));
    });

    test('escapes semicolons in title', () {
      final ics = service.exportEvent(_makeEvent(title: 'A;B'));
      expect(ics, contains('SUMMARY:A\\;B'));
    });

    test('escapes backslashes in title', () {
      final ics = service.exportEvent(_makeEvent(title: r'Path\To'));
      expect(ics, contains(r'SUMMARY:Path\\To'));
    });

    test('escapes newlines in description', () {
      final ics = service.exportEvent(_makeEvent(description: 'Line1\nLine2'));
      expect(ics, contains('Line1\\nLine2'));
    });
  });

  group('IcsExportService - Bulk Export', () {
    test('exports multiple events in one calendar', () {
      final events = [
        _makeEvent(id: '1', title: 'Event 1'),
        _makeEvent(id: '2', title: 'Event 2'),
        _makeEvent(id: '3', title: 'Event 3'),
      ];
      final ics = service.exportEvents(events);

      // One calendar wrapper
      expect('BEGIN:VCALENDAR'.allMatches(ics).length, equals(1));
      expect('END:VCALENDAR'.allMatches(ics).length, equals(1));

      // Three events
      expect('BEGIN:VEVENT'.allMatches(ics).length, equals(3));
      expect('END:VEVENT'.allMatches(ics).length, equals(3));

      expect(ics, contains('SUMMARY:Event 1'));
      expect(ics, contains('SUMMARY:Event 2'));
      expect(ics, contains('SUMMARY:Event 3'));
    });

    test('exports empty list as empty calendar', () {
      final ics = service.exportEvents([]);
      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('END:VCALENDAR'));
      expect(ics, isNot(contains('BEGIN:VEVENT')));
    });
  });

  group('IcsExportService - Filename Generation', () {
    test('generates sanitized filename from title', () {
      final filename = service.generateFilename(
        _makeEvent(title: 'Team Meeting'),
      );
      expect(filename, equals('team_meeting.ics'));
    });

    test('removes special characters', () {
      final filename = service.generateFilename(
        _makeEvent(title: 'Meeting @ 3pm! (Room #5)'),
      );
      expect(filename, equals('meeting__3pm_room_5.ics'));
    });

    test('truncates long titles to 50 chars', () {
      final longTitle = 'A' * 100;
      final filename = service.generateFilename(_makeEvent(title: longTitle));
      // 50 chars + .ics = 54
      expect(filename.length, lessThanOrEqualTo(54));
      expect(filename, endsWith('.ics'));
    });

    test('uses fallback for empty title after sanitization', () {
      final filename = service.generateFilename(
        _makeEvent(title: '!!!'),
      );
      expect(filename, equals('event.ics'));
    });

    test('generates bulk filename with date', () {
      final filename = service.generateBulkFilename();
      expect(filename, startsWith('everything_events_'));
      expect(filename, endsWith('.ics'));
    });
  });

  group('IcsExportService - Bytes Export', () {
    test('exportEventBytes returns UTF-8 encoded bytes', () {
      final bytes = service.exportEventBytes(_makeEvent());
      expect(bytes, isNotEmpty);
      final decoded = String.fromCharCodes(bytes);
      expect(decoded, contains('BEGIN:VCALENDAR'));
    });

    test('exportEventsBytes returns UTF-8 encoded bytes', () {
      final events = [_makeEvent(id: '1'), _makeEvent(id: '2')];
      final bytes = service.exportEventsBytes(events);
      expect(bytes, isNotEmpty);
      final decoded = String.fromCharCodes(bytes);
      expect(decoded, contains('BEGIN:VCALENDAR'));
      expect('BEGIN:VEVENT'.allMatches(decoded).length, equals(2));
    });
  });

  group('IcsExportService - MIME Type', () {
    test('has correct MIME type', () {
      expect(IcsExportService.mimeType, equals('text/calendar'));
    });
  });

  group('IcsExportService - Date Formatting', () {
    test('pads single-digit month and day', () {
      final event = _makeEvent(date: DateTime(2026, 1, 5, 9, 5, 0));
      final ics = service.exportEvent(event);
      expect(ics, contains('DTSTART:20260105T090500'));
    });

    test('handles midnight', () {
      final event = _makeEvent(date: DateTime(2026, 12, 31, 0, 0, 0));
      final ics = service.exportEvent(event);
      expect(ics, contains('DTSTART:20261231T000000'));
    });

    test('handles end of day', () {
      final event = _makeEvent(date: DateTime(2026, 6, 15, 23, 0, 0));
      final ics = service.exportEvent(event);
      expect(ics, contains('DTSTART:20260615T230000'));
      // End time wraps to next day
      expect(ics, contains('DTEND:20260616T000000'));
    });
  });

  group('IcsExportService - Line Folding', () {
    test('folds long lines at 75 characters', () {
      final longTitle = 'A' * 200;
      final event = _makeEvent(title: longTitle);
      final ics = service.exportEvent(event);

      // Each line should be <= 75 chars (after folding, continuation lines
      // start with a space which doesn't count as a new property)
      final lines = ics.split('\n');
      for (final line in lines) {
        final trimmed = line.replaceAll('\r', '');
        // Lines starting with space are continuation lines
        if (trimmed.isNotEmpty) {
          expect(trimmed.length, lessThanOrEqualTo(76),
              reason: 'Line too long: "$trimmed" (${trimmed.length} chars)');
        }
      }
    });

    test('does not fold short lines', () {
      final event = _makeEvent(title: 'Short');
      final ics = service.exportEvent(event);
      // SUMMARY:Short should be on one line, no continuation
      expect(ics, contains('SUMMARY:Short'));
    });
  });

  group('IcsExportService - Edge Cases', () {
    test('handles event with all fields', () {
      final event = _makeEvent(
        id: 'full-event',
        title: 'Complete Event',
        description: 'Full description with details',
        date: DateTime(2026, 6, 15, 10, 0),
        priority: EventPriority.urgent,
        tags: [
          const EventTag(name: 'Work', colorIndex: 0),
          const EventTag(name: 'Important', colorIndex: 4),
        ],
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
          endDate: DateTime(2026, 12, 31),
        ),
      );

      final ics = service.exportEvent(event);

      expect(ics, contains('UID:full-event@everything.app'));
      expect(ics, contains('SUMMARY:Complete Event'));
      expect(ics, contains('Full description with details'));
      expect(ics, contains('PRIORITY:1'));
      expect(ics, contains('CATEGORIES:Work,Important'));
      expect(ics, contains('RRULE:FREQ=WEEKLY;INTERVAL=2;UNTIL='));
      expect(ics, contains('Tags: Work\\, Important'));
    });

    test('handles event with minimal fields', () {
      final event = EventModel(
        id: 'min',
        title: 'Minimal',
        date: DateTime(2026, 1, 1),
      );

      final ics = service.exportEvent(event);
      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('SUMMARY:Minimal'));
      expect(ics, contains('END:VCALENDAR'));
    });
  });
}
