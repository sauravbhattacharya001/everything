import 'package:flutter_test/flutter_test.dart';
import 'package:everything/state/providers/event_provider.dart';
import 'package:everything/models/event_model.dart';

void main() {
  late EventProvider provider;

  setUp(() {
    provider = EventProvider();
  });

  group('EventProvider', () {
    final event1 = EventModel(
      id: '1',
      title: 'Meeting',
      date: DateTime(2026, 2, 14),
    );
    final event2 = EventModel(
      id: '2',
      title: 'Lunch',
      date: DateTime(2026, 2, 14, 12),
    );
    final event3 = EventModel(
      id: '3',
      title: 'Review',
      date: DateTime(2026, 2, 15),
    );

    group('initial state', () {
      test('starts with empty events list', () {
        expect(provider.events, isEmpty);
      });

      test('events list is unmodifiable', () {
        expect(
          () => provider.events.add(event1),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('addEvent', () {
      test('adds event to list', () {
        provider.addEvent(event1);

        expect(provider.events.length, 1);
        expect(provider.events.first.id, '1');
      });

      test('adds multiple events', () {
        provider.addEvent(event1);
        provider.addEvent(event2);

        expect(provider.events.length, 2);
      });

      test('notifies listeners on add', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.addEvent(event1);

        expect(notified, isTrue);
      });
    });

    group('removeEvent', () {
      test('removes event by id', () {
        provider.addEvent(event1);
        provider.addEvent(event2);
        provider.removeEvent('1');

        expect(provider.events.length, 1);
        expect(provider.events.first.id, '2');
      });

      test('does nothing when id not found', () {
        provider.addEvent(event1);
        provider.removeEvent('nonexistent');

        expect(provider.events.length, 1);
      });

      test('notifies listeners on remove', () {
        provider.addEvent(event1);
        var notified = false;
        provider.addListener(() => notified = true);

        provider.removeEvent('1');

        expect(notified, isTrue);
      });
    });

    group('setEvents', () {
      test('replaces all events', () {
        provider.addEvent(event1);
        provider.setEvents([event2, event3]);

        expect(provider.events.length, 2);
        expect(provider.events.first.id, '2');
        expect(provider.events.last.id, '3');
      });

      test('clears and sets when called with empty list', () {
        provider.addEvent(event1);
        provider.setEvents([]);

        expect(provider.events, isEmpty);
      });

      test('notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setEvents([event1]);

        expect(notified, isTrue);
      });
    });

    group('clearEvents', () {
      test('removes all events', () {
        provider.addEvent(event1);
        provider.addEvent(event2);
        provider.clearEvents();

        expect(provider.events, isEmpty);
      });

      test('notifies listeners on clear', () {
        provider.addEvent(event1);
        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearEvents();

        expect(notified, isTrue);
      });
    });

    group('updateEvent', () {
      test('updates existing event by id', () {
        provider.addEvent(event1);
        final updated = event1.copyWith(title: 'Updated Meeting');
        provider.updateEvent(updated);

        expect(provider.events.length, 1);
        expect(provider.events.first.title, 'Updated Meeting');
      });

      test('no-op when id not found', () {
        provider.addEvent(event1);
        final stranger = EventModel(
          id: 'unknown',
          title: 'Ghost',
          date: DateTime(2026, 1, 1),
        );
        provider.updateEvent(stranger);

        expect(provider.events.length, 1);
        expect(provider.events.first.title, 'Meeting');
      });

      test('notifies listeners on update', () {
        provider.addEvent(event1);
        var notified = false;
        provider.addListener(() => notified = true);

        provider.updateEvent(event1.copyWith(title: 'Changed'));

        expect(notified, isTrue);
      });

      test('updates description and priority', () {
        provider.addEvent(event1);
        final updated = event1.copyWith(
          description: 'Important',
          priority: EventPriority.urgent,
        );
        provider.updateEvent(updated);

        expect(provider.events.first.description, 'Important');
        expect(provider.events.first.priority, EventPriority.urgent);
      });
    });
  });
}
