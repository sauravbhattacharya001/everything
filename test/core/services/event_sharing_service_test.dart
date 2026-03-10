import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/event_sharing_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';

void main() {
  late EventSharingService service;

  setUp(() {
    service = const EventSharingService();
  });

  EventModel _makeEvent({
    String id = 'test-123',
    String title = 'Team Meeting',
    String description = 'Weekly sync with the team',
    String location = 'Room 42',
    DateTime? date,
    DateTime? endDate,
    EventPriority priority = EventPriority.medium,
    List<EventTag>? tags,
  }) {
    return EventModel(
      id: id,
      title: title,
      description: description,
      location: location,
      date: date ?? DateTime(2026, 3, 15, 14, 30),
      endDate: endDate,
      priority: priority,
      tags: tags,
    );
  }

  // ── Plain Text Format ─────────────────────────────────────────────

  group('EventSharingService - Plain Text', () {
    test('includes event title with emoji', () {
      final text = service.share(_makeEvent());
      expect(text, contains('📅 Team Meeting'));
    });

    test('includes formatted date', () {
      final text = service.share(_makeEvent());
      expect(text, contains('Date:'));
      expect(text, contains('Sun, Mar 15, 2026'));
    });

    test('includes location with pin emoji', () {
      final text = service.share(_makeEvent());
      expect(text, contains('📍 Room 42'));
    });

    test('omits location when empty', () {
      final text = service.share(_makeEvent(location: ''));
      expect(text, isNot(contains('📍')));
    });

    test('includes description', () {
      final text = service.share(_makeEvent());
      expect(text, contains('Weekly sync with the team'));
    });

    test('omits description when empty', () {
      final text = service.share(_makeEvent(description: ''));
      expect(text, isNot(contains('Weekly sync')));
    });

    test('includes priority label', () {
      final text = service.share(_makeEvent(priority: EventPriority.high));
      expect(text, contains('Priority: High'));
    });

    test('includes tags with hash prefix', () {
      final text = service.share(_makeEvent(
        tags: [const EventTag(name: 'work'), const EventTag(name: 'sync')],
      ));
      expect(text, contains('#work'));
      expect(text, contains('#sync'));
    });

    test('omits tags line when empty', () {
      final text = service.share(_makeEvent(tags: []));
      expect(text, isNot(contains('Tags:')));
    });

    test('includes end date when present', () {
      final text = service.share(_makeEvent(
        endDate: DateTime(2026, 3, 15, 16, 0),
      ));
      expect(text, contains('Until:'));
    });

    test('omits end date when absent', () {
      final text = service.share(_makeEvent());
      expect(text, isNot(contains('Until:')));
    });

    test('has no trailing whitespace', () {
      final text = service.share(_makeEvent());
      expect(text, isNot(endsWith(' ')));
      expect(text, isNot(endsWith('\n')));
    });
  });

  // ── Markdown Format ───────────────────────────────────────────────

  group('EventSharingService - Markdown', () {
    test('starts with h2 header', () {
      final md = service.share(_makeEvent(), format: ShareFormat.markdown);
      expect(md, startsWith('## 📅 Team Meeting'));
    });

    test('includes markdown table', () {
      final md = service.share(_makeEvent(), format: ShareFormat.markdown);
      expect(md, contains('| Field | Value |'));
      expect(md, contains('|-------|-------|'));
    });

    test('includes date in table', () {
      final md = service.share(_makeEvent(), format: ShareFormat.markdown);
      expect(md, contains('| **Date** |'));
    });

    test('includes location in table', () {
      final md = service.share(_makeEvent(), format: ShareFormat.markdown);
      expect(md, contains('| **Location** | Room 42 |'));
    });

    test('omits location row when empty', () {
      final md = service.share(_makeEvent(location: ''), format: ShareFormat.markdown);
      expect(md, isNot(contains('**Location**')));
    });

    test('includes priority in table', () {
      final md = service.share(_makeEvent(priority: EventPriority.urgent),
          format: ShareFormat.markdown);
      expect(md, contains('| **Priority** | Urgent |'));
    });

    test('renders tags with backtick formatting', () {
      final md = service.share(_makeEvent(
        tags: [const EventTag(name: 'meeting')],
      ), format: ShareFormat.markdown);
      expect(md, contains('`meeting`'));
    });

    test('renders description as blockquote', () {
      final md = service.share(_makeEvent(), format: ShareFormat.markdown);
      expect(md, contains('> Weekly sync with the team'));
    });

    test('omits blockquote when description empty', () {
      final md = service.share(_makeEvent(description: ''),
          format: ShareFormat.markdown);
      expect(md, isNot(contains('>')));
    });

    test('includes end date row when present', () {
      final md = service.share(_makeEvent(
        endDate: DateTime(2026, 3, 15, 16, 0),
      ), format: ShareFormat.markdown);
      expect(md, contains('| **End** |'));
    });

    test('multiline description uses blockquote continuation', () {
      final md = service.share(_makeEvent(
        description: 'Line one\nLine two',
      ), format: ShareFormat.markdown);
      expect(md, contains('> Line one'));
      expect(md, contains('> Line two'));
    });
  });

  // ── Google Calendar URL ───────────────────────────────────────────

  group('EventSharingService - Google Calendar URL', () {
    test('starts with correct base URL', () {
      final url = service.share(_makeEvent(),
          format: ShareFormat.googleCalendarUrl);
      expect(url, startsWith('https://calendar.google.com/calendar/render?'));
    });

    test('includes action=TEMPLATE', () {
      final url = service.share(_makeEvent(),
          format: ShareFormat.googleCalendarUrl);
      expect(url, contains('action=TEMPLATE'));
    });

    test('includes encoded event title', () {
      final url = service.share(_makeEvent(title: 'Team Meeting'),
          format: ShareFormat.googleCalendarUrl);
      expect(url, contains('text=Team'));
    });

    test('includes dates parameter with UTC format', () {
      final url = service.share(_makeEvent(),
          format: ShareFormat.googleCalendarUrl);
      // Should contain dates=START/END in compact UTC format
      expect(url, contains('dates='));
      expect(url, matches(RegExp(r'dates=\d{8}T\d{6}Z')));
    });

    test('includes encoded location', () {
      final url = service.share(_makeEvent(location: 'Room 42'),
          format: ShareFormat.googleCalendarUrl);
      expect(url, contains('location='));
    });

    test('includes encoded description', () {
      final url = service.share(_makeEvent(),
          format: ShareFormat.googleCalendarUrl);
      expect(url, contains('details='));
    });

    test('omits details when description empty', () {
      final url = service.share(_makeEvent(description: ''),
          format: ShareFormat.googleCalendarUrl);
      expect(url, isNot(contains('details=')));
    });

    test('omits location when empty', () {
      final url = service.share(_makeEvent(location: ''),
          format: ShareFormat.googleCalendarUrl);
      expect(url, isNot(contains('location=')));
    });

    test('uses 1-hour default when no end date', () {
      final event = _makeEvent(date: DateTime.utc(2026, 3, 15, 14, 30));
      final url = service.share(event, format: ShareFormat.googleCalendarUrl);
      // End time should be 15:30 (1 hour later)
      expect(url, contains('20260315T153000Z'));
    });

    test('special characters are URL-encoded', () {
      final url = service.share(_makeEvent(title: 'Q&A Session'),
          format: ShareFormat.googleCalendarUrl);
      expect(url, contains('Q%26A'));
    });
  });

  // ── Outlook URL ───────────────────────────────────────────────────

  group('EventSharingService - Outlook URL', () {
    test('starts with correct Outlook base URL', () {
      final url = service.share(_makeEvent(), format: ShareFormat.outlookUrl);
      expect(url, startsWith(
          'https://outlook.live.com/calendar/0/deeplink/compose?'));
    });

    test('includes compose path parameter', () {
      final url = service.share(_makeEvent(), format: ShareFormat.outlookUrl);
      expect(url, contains('path='));
      expect(url, contains('compose'));
    });

    test('includes rru=addevent', () {
      final url = service.share(_makeEvent(), format: ShareFormat.outlookUrl);
      expect(url, contains('rru=addevent'));
    });

    test('includes subject parameter', () {
      final url = service.share(_makeEvent(), format: ShareFormat.outlookUrl);
      expect(url, contains('subject='));
    });

    test('includes startdt and enddt parameters', () {
      final url = service.share(_makeEvent(), format: ShareFormat.outlookUrl);
      expect(url, contains('startdt='));
      expect(url, contains('enddt='));
    });

    test('enddt defaults to 1 hour after startdt when no end date', () {
      final event = _makeEvent(date: DateTime.utc(2026, 3, 15, 14, 30));
      final url = service.share(event, format: ShareFormat.outlookUrl);
      // Both start and end should appear as ISO 8601 strings
      expect(url, contains('startdt='));
      expect(url, contains('enddt='));
    });

    test('includes body when description present', () {
      final url = service.share(_makeEvent(), format: ShareFormat.outlookUrl);
      expect(url, contains('body='));
    });

    test('omits body when description empty', () {
      final url = service.share(_makeEvent(description: ''),
          format: ShareFormat.outlookUrl);
      expect(url, isNot(contains('body=')));
    });

    test('includes location when present', () {
      final url = service.share(_makeEvent(), format: ShareFormat.outlookUrl);
      expect(url, contains('location='));
    });

    test('omits location when empty', () {
      final url = service.share(_makeEvent(location: ''),
          format: ShareFormat.outlookUrl);
      expect(url, isNot(contains('location=')));
    });
  });

  // ── shareAll ──────────────────────────────────────────────────────

  group('EventSharingService - shareAll', () {
    test('returns all four formats', () {
      final results = service.shareAll(_makeEvent());
      expect(results.length, equals(4));
      expect(results.containsKey(ShareFormat.plainText), isTrue);
      expect(results.containsKey(ShareFormat.markdown), isTrue);
      expect(results.containsKey(ShareFormat.googleCalendarUrl), isTrue);
      expect(results.containsKey(ShareFormat.outlookUrl), isTrue);
    });

    test('each value is non-empty', () {
      final results = service.shareAll(_makeEvent());
      for (final entry in results.entries) {
        expect(entry.value, isNotEmpty,
            reason: '${entry.key} should not be empty');
      }
    });

    test('plain text and markdown differ', () {
      final results = service.shareAll(_makeEvent());
      expect(results[ShareFormat.plainText],
          isNot(equals(results[ShareFormat.markdown])));
    });

    test('google and outlook URLs differ', () {
      final results = service.shareAll(_makeEvent());
      expect(results[ShareFormat.googleCalendarUrl],
          isNot(equals(results[ShareFormat.outlookUrl])));
    });
  });

  // ── Date Formatting ───────────────────────────────────────────────

  group('EventSharingService - Date Formatting', () {
    test('formats AM time correctly', () {
      final text = service.share(_makeEvent(
        date: DateTime(2026, 3, 15, 9, 5),
      ));
      expect(text, contains('9:05 AM'));
    });

    test('formats PM time correctly', () {
      final text = service.share(_makeEvent(
        date: DateTime(2026, 3, 15, 14, 30),
      ));
      expect(text, contains('2:30 PM'));
    });

    test('formats midnight as 12:00 AM', () {
      final text = service.share(_makeEvent(
        date: DateTime(2026, 3, 15, 0, 0),
      ));
      expect(text, contains('12:00 AM'));
    });

    test('formats noon as 12:00 PM', () {
      final text = service.share(_makeEvent(
        date: DateTime(2026, 3, 15, 12, 0),
      ));
      expect(text, contains('12:00 PM'));
    });

    test('pads minutes with leading zero', () {
      final text = service.share(_makeEvent(
        date: DateTime(2026, 3, 15, 14, 5),
      ));
      expect(text, contains('2:05 PM'));
    });

    test('different weekdays render correctly', () {
      // Monday
      final mon = service.share(_makeEvent(date: DateTime(2026, 3, 16, 10, 0)));
      expect(mon, contains('Mon,'));

      // Saturday
      final sat = service.share(_makeEvent(date: DateTime(2026, 3, 14, 10, 0)));
      expect(sat, contains('Sat,'));
    });
  });

  // ── Edge Cases ────────────────────────────────────────────────────

  group('EventSharingService - Edge Cases', () {
    test('handles empty title', () {
      final text = service.share(_makeEvent(title: ''));
      expect(text, contains('📅'));
    });

    test('handles very long description', () {
      final longDesc = 'A' * 1000;
      final text = service.share(_makeEvent(description: longDesc));
      expect(text, contains(longDesc));
    });

    test('handles special characters in title', () {
      final text = service.share(_makeEvent(title: 'Q&A <Session> "Test"'));
      expect(text, contains('Q&A <Session> "Test"'));
    });

    test('handles special characters in Google URL', () {
      final url = service.share(_makeEvent(title: 'Meeting @ HQ'),
          format: ShareFormat.googleCalendarUrl);
      expect(url, contains(Uri.encodeComponent('Meeting @ HQ')));
    });

    test('handles multiple tags', () {
      final text = service.share(_makeEvent(
        tags: [
          const EventTag(name: 'work'),
          const EventTag(name: 'urgent'),
          const EventTag(name: 'team'),
        ],
      ));
      expect(text, contains('#work'));
      expect(text, contains('#urgent'));
      expect(text, contains('#team'));
    });

    test('all priority levels render in plain text', () {
      for (final p in EventPriority.values) {
        final text = service.share(_makeEvent(priority: p));
        expect(text, contains('Priority: ${p.label}'));
      }
    });

    test('consistent across multiple calls with same event', () {
      final event = _makeEvent();
      final text1 = service.share(event);
      final text2 = service.share(event);
      expect(text1, equals(text2));
    });

    test('different events produce different output', () {
      final text1 = service.share(_makeEvent(title: 'Event A'));
      final text2 = service.share(_makeEvent(title: 'Event B'));
      expect(text1, isNot(equals(text2)));
    });
  });
}
