import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/event_model.dart';

void main() {
  group('EventModel', () {
    final sampleDate = DateTime(2026, 2, 14, 10, 30);
    final sampleJson = {
      'id': 'evt-001',
      'title': 'Team Standup',
      'description': 'Daily sync meeting',
      'date': '2026-02-14T10:30:00.000',
      'priority': 'high',
    };

    group('fromJson', () {
      test('creates EventModel from valid JSON', () {
        final event = EventModel.fromJson(sampleJson);

        expect(event.id, 'evt-001');
        expect(event.title, 'Team Standup');
        expect(event.description, 'Daily sync meeting');
        expect(event.priority, EventPriority.high);
        expect(event.date.year, 2026);
        expect(event.date.month, 2);
        expect(event.date.day, 14);
        expect(event.date.hour, 10);
        expect(event.date.minute, 30);
      });

      test('defaults description and priority when missing', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'date': '2026-01-01T00:00:00.000',
        };
        final event = EventModel.fromJson(json);
        expect(event.description, '');
        expect(event.priority, EventPriority.medium);
      });

      test('throws on missing id field', () {
        expect(
          () => EventModel.fromJson({'title': 'Test', 'date': '2026-01-01'}),
          throwsA(isA<TypeError>()),
        );
      });

      test('throws on missing title field', () {
        expect(
          () => EventModel.fromJson({'id': '1', 'date': '2026-01-01'}),
          throwsA(isA<TypeError>()),
        );
      });

      test('throws on invalid date string', () {
        expect(
          () => EventModel.fromJson({
            'id': '1',
            'title': 'Test',
            'date': 'not-a-date',
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('handles date with timezone offset', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'date': '2026-02-14T10:30:00.000Z',
        };
        final event = EventModel.fromJson(json);
        expect(event.date.isUtc, isTrue);
      });
    });

    group('toJson', () {
      test('converts EventModel to JSON map', () {
        final event = EventModel(
          id: 'evt-001',
          title: 'Standup',
          description: 'Team sync',
          date: sampleDate,
          priority: EventPriority.urgent,
        );
        final json = event.toJson();

        expect(json['id'], 'evt-001');
        expect(json['title'], 'Standup');
        expect(json['description'], 'Team sync');
        expect(json['priority'], 'urgent');
        expect(json['date'], isA<String>());
        expect(DateTime.parse(json['date'] as String), sampleDate);
      });

      test('toJson/fromJson round-trip preserves data', () {
        final original = EventModel(
          id: 'rt-1',
          title: 'Round Trip',
          description: 'Full round trip test',
          date: sampleDate,
          priority: EventPriority.high,
        );
        final restored = EventModel.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.description, original.description);
        expect(restored.date, original.date);
        expect(restored.priority, original.priority);
      });
    });

    group('copyWith', () {
      test('copies with no changes returns equal object', () {
        final event = EventModel(id: '1', title: 'Original', date: sampleDate);
        final copy = event.copyWith();

        expect(copy, event);
        expect(identical(copy, event), isFalse);
      });

      test('copies with changed title', () {
        final event = EventModel(id: '1', title: 'Original', date: sampleDate);
        final copy = event.copyWith(title: 'Updated');

        expect(copy.id, '1');
        expect(copy.title, 'Updated');
        expect(copy.date, sampleDate);
      });

      test('copies with changed description', () {
        final event = EventModel(id: '1', title: 'Test', date: sampleDate);
        final copy = event.copyWith(description: 'New desc');

        expect(copy.description, 'New desc');
      });

      test('copies with changed priority', () {
        final event = EventModel(id: '1', title: 'Test', date: sampleDate);
        final copy = event.copyWith(priority: EventPriority.urgent);

        expect(copy.priority, EventPriority.urgent);
      });

      test('copies with changed date', () {
        final event = EventModel(id: '1', title: 'Test', date: sampleDate);
        final newDate = DateTime(2027, 1, 1);
        final copy = event.copyWith(date: newDate);

        expect(copy.date, newDate);
        expect(copy.id, '1');
      });
    });

    group('equality', () {
      test('equal events have same hashCode', () {
        final a = EventModel(id: '1', title: 'Test', date: sampleDate);
        final b = EventModel(id: '1', title: 'Test', date: sampleDate);

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different id means not equal', () {
        final a = EventModel(id: '1', title: 'Test', date: sampleDate);
        final b = EventModel(id: '2', title: 'Test', date: sampleDate);

        expect(a, isNot(b));
      });

      test('different title means not equal', () {
        final a = EventModel(id: '1', title: 'A', date: sampleDate);
        final b = EventModel(id: '1', title: 'B', date: sampleDate);

        expect(a, isNot(b));
      });

      test('different priority means not equal', () {
        final a = EventModel(id: '1', title: 'A', date: sampleDate, priority: EventPriority.low);
        final b = EventModel(id: '1', title: 'A', date: sampleDate, priority: EventPriority.high);

        expect(a, isNot(b));
      });

      test('not equal to non-EventModel', () {
        final event = EventModel(id: '1', title: 'Test', date: sampleDate);
        // ignore: unrelated_type_equality_checks
        expect(event == 'not an event', isFalse);
      });

      test('identical returns true', () {
        final event = EventModel(id: '1', title: 'Test', date: sampleDate);
        expect(event, event);
      });
    });

    group('EventPriority', () {
      test('fromString returns correct priority', () {
        expect(EventPriority.fromString('low'), EventPriority.low);
        expect(EventPriority.fromString('medium'), EventPriority.medium);
        expect(EventPriority.fromString('high'), EventPriority.high);
        expect(EventPriority.fromString('urgent'), EventPriority.urgent);
      });

      test('fromString defaults to medium for unknown', () {
        expect(EventPriority.fromString('unknown'), EventPriority.medium);
        expect(EventPriority.fromString(''), EventPriority.medium);
      });

      test('label returns human-readable string', () {
        expect(EventPriority.low.label, 'Low');
        expect(EventPriority.medium.label, 'Medium');
        expect(EventPriority.high.label, 'High');
        expect(EventPriority.urgent.label, 'Urgent');
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        final event = EventModel(id: '1', title: 'Test', date: sampleDate);
        final str = event.toString();

        expect(str, contains('EventModel'));
        expect(str, contains('1'));
        expect(str, contains('Test'));
        expect(str, contains('Medium'));
      });
    });
  });
}
