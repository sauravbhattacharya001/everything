import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/event_model.dart';

void main() {
  group('EventModel', () {
    final sampleDate = DateTime(2026, 2, 14, 10, 30);
    final sampleJson = {
      'id': 'evt-001',
      'title': 'Team Standup',
      'date': '2026-02-14T10:30:00.000',
    };

    group('fromJson', () {
      test('creates EventModel from valid JSON', () {
        final event = EventModel.fromJson(sampleJson);

        expect(event.id, 'evt-001');
        expect(event.title, 'Team Standup');
        expect(event.date.year, 2026);
        expect(event.date.month, 2);
        expect(event.date.day, 14);
        expect(event.date.hour, 10);
        expect(event.date.minute, 30);
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
        final event = EventModel(id: 'evt-001', title: 'Standup', date: sampleDate);
        final json = event.toJson();

        expect(json['id'], 'evt-001');
        expect(json['title'], 'Standup');
        expect(json['date'], isA<String>());
        // Verify the date round-trips
        expect(DateTime.parse(json['date'] as String), sampleDate);
      });

      test('toJson/fromJson round-trip preserves data', () {
        final original = EventModel(id: 'rt-1', title: 'Round Trip', date: sampleDate);
        final restored = EventModel.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.date, original.date);
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

      test('copies with changed id', () {
        final event = EventModel(id: '1', title: 'Test', date: sampleDate);
        final copy = event.copyWith(id: '2');

        expect(copy.id, '2');
        expect(copy.title, 'Test');
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

    group('toString', () {
      test('returns descriptive string', () {
        final event = EventModel(id: '1', title: 'Test', date: sampleDate);
        final str = event.toString();

        expect(str, contains('EventModel'));
        expect(str, contains('1'));
        expect(str, contains('Test'));
      });
    });
  });
}
