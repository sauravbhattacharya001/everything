import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/recurrence_rule.dart';

void main() {
  group('EventModel recurrence', () {
    final sampleDate = DateTime(2026, 3, 1, 10, 0);
    const weeklyRule = RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      interval: 1,
    );

    group('isRecurring', () {
      test('returns false when no recurrence', () {
        final event = EventModel(id: '1', title: 'Test', date: sampleDate);
        expect(event.isRecurring, isFalse);
      });

      test('returns true when recurrence is set', () {
        final event = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          recurrence: weeklyRule,
        );
        expect(event.isRecurring, isTrue);
      });
    });

    group('generateOccurrences', () {
      test('returns empty list for non-recurring event', () {
        final event = EventModel(id: '1', title: 'Test', date: sampleDate);
        expect(event.generateOccurrences(), isEmpty);
      });

      test('generates occurrences for weekly recurring event', () {
        final event = EventModel(
          id: 'evt-1',
          title: 'Standup',
          date: sampleDate,
          recurrence: weeklyRule,
        );
        final occurrences = event.generateOccurrences(maxOccurrences: 4);

        expect(occurrences.length, 3); // 4 total minus the original
        expect(occurrences[0].id, 'evt-1_1');
        expect(occurrences[0].date, DateTime(2026, 3, 8, 10, 0));
        expect(occurrences[0].title, 'Standup');
        expect(occurrences[1].id, 'evt-1_2');
        expect(occurrences[1].date, DateTime(2026, 3, 15, 10, 0));
        expect(occurrences[2].id, 'evt-1_3');
        expect(occurrences[2].date, DateTime(2026, 3, 22, 10, 0));
      });

      test('occurrences preserve event properties', () {
        final event = EventModel(
          id: '1',
          title: 'Meeting',
          description: 'Team sync',
          date: sampleDate,
          priority: EventPriority.high,
          recurrence: weeklyRule,
        );
        final occurrences = event.generateOccurrences(maxOccurrences: 2);

        expect(occurrences.length, 1);
        expect(occurrences[0].title, 'Meeting');
        expect(occurrences[0].description, 'Team sync');
        expect(occurrences[0].priority, EventPriority.high);
      });
    });

    group('serialization with recurrence', () {
      test('toJson includes recurrence', () {
        final event = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          recurrence: weeklyRule,
        );
        final json = event.toJson();

        expect(json['recurrence'], isA<String>());
        expect(json['recurrence'], contains('weekly'));
      });

      test('toJson omits recurrence when null', () {
        final event = EventModel(id: '1', title: 'Test', date: sampleDate);
        final json = event.toJson();

        expect(json['recurrence'], isNull);
      });

      test('fromJson parses recurrence from string', () {
        final event = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          recurrence: weeklyRule,
        );
        final json = event.toJson();
        final restored = EventModel.fromJson(json);

        expect(restored.isRecurring, isTrue);
        expect(restored.recurrence!.frequency, RecurrenceFrequency.weekly);
        expect(restored.recurrence!.interval, 1);
      });

      test('fromJson handles missing recurrence', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'date': sampleDate.toIso8601String(),
        };
        final event = EventModel.fromJson(json);
        expect(event.isRecurring, isFalse);
      });

      test('toJson/fromJson round-trip with recurrence and end date', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 2,
          endDate: DateTime(2027, 6, 30),
        );
        final original = EventModel(
          id: 'rt-1',
          title: 'Monthly Review',
          date: sampleDate,
          recurrence: rule,
        );
        final restored = EventModel.fromJson(original.toJson());

        expect(restored.recurrence, isNotNull);
        expect(restored.recurrence!.frequency, RecurrenceFrequency.monthly);
        expect(restored.recurrence!.interval, 2);
        expect(restored.recurrence!.endDate, DateTime(2027, 6, 30));
      });
    });

    group('copyWith recurrence', () {
      test('preserves recurrence by default', () {
        final event = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          recurrence: weeklyRule,
        );
        final copy = event.copyWith(title: 'Updated');

        expect(copy.recurrence, weeklyRule);
      });

      test('replaces recurrence', () {
        const newRule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 3,
        );
        final event = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          recurrence: weeklyRule,
        );
        final copy = event.copyWith(recurrence: newRule);

        expect(copy.recurrence!.frequency, RecurrenceFrequency.daily);
        expect(copy.recurrence!.interval, 3);
      });

      test('clearRecurrence removes recurrence', () {
        final event = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          recurrence: weeklyRule,
        );
        final copy = event.copyWith(clearRecurrence: true);

        expect(copy.isRecurring, isFalse);
        expect(copy.recurrence, isNull);
      });
    });

    group('equality with recurrence', () {
      test('events with same recurrence are equal', () {
        final a = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          recurrence: weeklyRule,
        );
        final b = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          recurrence: weeklyRule,
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('events with different recurrence are not equal', () {
        final a = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          recurrence: weeklyRule,
        );
        final b = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        );
        expect(a, isNot(b));
      });

      test('event with recurrence != event without', () {
        final a = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          recurrence: weeklyRule,
        );
        final b = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
        );
        expect(a, isNot(b));
      });
    });

    group('toString with recurrence', () {
      test('includes recurrence in toString', () {
        final event = EventModel(
          id: '1',
          title: 'Test',
          date: sampleDate,
          recurrence: weeklyRule,
        );
        final str = event.toString();
        expect(str, contains('RecurrenceRule'));
        expect(str, contains('weekly'));
      });
    });
  });
}
