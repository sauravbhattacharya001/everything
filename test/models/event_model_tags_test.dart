import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';

void main() {
  group('EventModel tags', () {
    final sampleDate = DateTime(2026, 3, 15, 14, 0);
    const workTag = EventTag(name: 'Work', colorIndex: 0);
    const meetingTag = EventTag(name: 'Meeting', colorIndex: 2);

    group('construction', () {
      test('defaults to empty tags list', () {
        final event =
            EventModel(id: '1', title: 'Test', date: sampleDate);
        expect(event.tags, isEmpty);
      });

      test('accepts tags list', () {
        final event = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          tags: [workTag, meetingTag],
        );
        expect(event.tags.length, 2);
        expect(event.tags[0].name, 'Work');
        expect(event.tags[1].name, 'Meeting');
      });
    });

    group('JSON serialization', () {
      test('toJson encodes tags as JSON string', () {
        final event = EventModel(
          id: '1',
          title: 'Tagged',
          date: sampleDate,
          tags: [workTag],
        );
        final json = event.toJson();
        expect(json['tags'], isA<String>());
        expect(json['tags'], contains('Work'));
      });

      test('fromJson decodes tags from JSON string', () {
        final json = {
          'id': '1',
          'title': 'Tagged',
          'date': sampleDate.toIso8601String(),
          'tags': '[{"name":"Work","colorIndex":0}]',
        };
        final event = EventModel.fromJson(json);
        expect(event.tags.length, 1);
        expect(event.tags[0].name, 'Work');
        expect(event.tags[0].colorIndex, 0);
      });

      test('fromJson handles tags as List (non-string)', () {
        final json = {
          'id': '1',
          'title': 'Tagged',
          'date': sampleDate.toIso8601String(),
          'tags': [
            {'name': 'Personal', 'colorIndex': 1}
          ],
        };
        final event = EventModel.fromJson(json);
        expect(event.tags.length, 1);
        expect(event.tags[0].name, 'Personal');
      });

      test('fromJson handles missing tags field', () {
        final json = {
          'id': '1',
          'title': 'No Tags',
          'date': sampleDate.toIso8601String(),
        };
        final event = EventModel.fromJson(json);
        expect(event.tags, isEmpty);
      });

      test('fromJson handles empty tags string', () {
        final json = {
          'id': '1',
          'title': 'Empty',
          'date': sampleDate.toIso8601String(),
          'tags': '',
        };
        final event = EventModel.fromJson(json);
        expect(event.tags, isEmpty);
      });

      test('fromJson handles malformed tags JSON gracefully', () {
        final json = {
          'id': '1',
          'title': 'Bad',
          'date': sampleDate.toIso8601String(),
          'tags': 'not valid json',
        };
        final event = EventModel.fromJson(json);
        expect(event.tags, isEmpty);
      });

      test('round-trip preserves multiple tags', () {
        final original = EventModel(
          id: 'rt-1',
          title: 'Round Trip',
          date: sampleDate,
          tags: [workTag, meetingTag],
        );
        final restored = EventModel.fromJson(original.toJson());
        expect(restored.tags.length, 2);
        expect(restored.tags[0].name, 'Work');
        expect(restored.tags[1].name, 'Meeting');
      });
    });

    group('copyWith', () {
      test('copies with tags unchanged', () {
        final event = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          tags: [workTag],
        );
        final copy = event.copyWith(title: 'Updated');
        expect(copy.tags.length, 1);
        expect(copy.tags[0].name, 'Work');
      });

      test('copies with new tags', () {
        final event = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          tags: [workTag],
        );
        final copy = event.copyWith(tags: [meetingTag]);
        expect(copy.tags.length, 1);
        expect(copy.tags[0].name, 'Meeting');
        // Original unchanged
        expect(event.tags[0].name, 'Work');
      });

      test('copies with empty tags', () {
        final event = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          tags: [workTag],
        );
        final copy = event.copyWith(tags: []);
        expect(copy.tags, isEmpty);
      });
    });

    group('equality with tags', () {
      test('events with same tags are equal', () {
        final a = EventModel(
          id: '1',
          title: 'A',
          date: sampleDate,
          tags: [workTag],
        );
        final b = EventModel(
          id: '1',
          title: 'A',
          date: sampleDate,
          tags: [workTag],
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('events with different tags are not equal', () {
        final a = EventModel(
          id: '1',
          title: 'A',
          date: sampleDate,
          tags: [workTag],
        );
        final b = EventModel(
          id: '1',
          title: 'A',
          date: sampleDate,
          tags: [meetingTag],
        );
        expect(a, isNot(b));
      });

      test('tagged vs untagged events are not equal', () {
        final a = EventModel(
          id: '1',
          title: 'A',
          date: sampleDate,
          tags: [workTag],
        );
        final b = EventModel(
          id: '1',
          title: 'A',
          date: sampleDate,
        );
        expect(a, isNot(b));
      });
    });

    group('toString with tags', () {
      test('includes tag names', () {
        final event = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          tags: [workTag, meetingTag],
        );
        final str = event.toString();
        expect(str, contains('Work'));
        expect(str, contains('Meeting'));
      });
    });
  });
}
