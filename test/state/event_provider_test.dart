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

      test('does not notify when id not found', () {
        provider.addEvent(event1);
        var notified = false;
        provider.addListener(() => notified = true);

        provider.updateEvent(EventModel(
          id: 'nonexistent',
          title: 'Ghost',
          date: DateTime(2026, 1, 1),
        ));

        expect(notified, isFalse);
      });

      test('preserves position in list', () {
        provider.addEvent(event1);
        provider.addEvent(event2);
        provider.addEvent(event3);
        provider.updateEvent(event2.copyWith(title: 'Updated Lunch'));

        expect(provider.events[0].id, '1');
        expect(provider.events[1].title, 'Updated Lunch');
        expect(provider.events[2].id, '3');
      });
    });

    group('getEventById', () {
      test('returns event when it exists', () {
        provider.addEvent(event1);
        provider.addEvent(event2);

        final found = provider.getEventById('1');

        expect(found, isNotNull);
        expect(found!.id, '1');
        expect(found.title, 'Meeting');
      });

      test('returns null when id not found', () {
        provider.addEvent(event1);

        expect(provider.getEventById('nonexistent'), isNull);
      });

      test('returns null on empty provider', () {
        expect(provider.getEventById('1'), isNull);
      });

      test('finds last added event', () {
        provider.addEvent(event1);
        provider.addEvent(event2);
        provider.addEvent(event3);

        final found = provider.getEventById('3');
        expect(found, isNotNull);
        expect(found!.title, 'Review');
      });

      test('returns updated event after updateEvent', () {
        provider.addEvent(event1);
        provider.updateEvent(event1.copyWith(title: 'Changed'));

        final found = provider.getEventById('1');
        expect(found, isNotNull);
        expect(found!.title, 'Changed');
      });

      test('returns null after event is removed', () {
        provider.addEvent(event1);
        provider.removeEvent('1');

        expect(provider.getEventById('1'), isNull);
      });

      test('still finds other events after removal', () {
        provider.addEvent(event1);
        provider.addEvent(event2);
        provider.addEvent(event3);
        provider.removeEvent('2');

        expect(provider.getEventById('1'), isNotNull);
        expect(provider.getEventById('2'), isNull);
        expect(provider.getEventById('3'), isNotNull);
      });

      test('works after setEvents', () {
        provider.addEvent(event1);
        provider.setEvents([event2, event3]);

        expect(provider.getEventById('1'), isNull);
        expect(provider.getEventById('2'), isNotNull);
        expect(provider.getEventById('3'), isNotNull);
      });

      test('returns null after clearEvents', () {
        provider.addEvent(event1);
        provider.clearEvents();

        expect(provider.getEventById('1'), isNull);
      });
    });

    group('eventCount', () {
      test('returns 0 initially', () {
        expect(provider.eventCount, 0);
      });

      test('increments on add', () {
        provider.addEvent(event1);
        expect(provider.eventCount, 1);

        provider.addEvent(event2);
        expect(provider.eventCount, 2);
      });

      test('decrements on remove', () {
        provider.addEvent(event1);
        provider.addEvent(event2);
        provider.removeEvent('1');

        expect(provider.eventCount, 1);
      });

      test('reflects setEvents count', () {
        provider.setEvents([event1, event2, event3]);
        expect(provider.eventCount, 3);
      });

      test('returns 0 after clear', () {
        provider.addEvent(event1);
        provider.clearEvents();

        expect(provider.eventCount, 0);
      });
    });

    group('isEmpty', () {
      test('true initially', () {
        expect(provider.isEmpty, isTrue);
      });

      test('false after adding event', () {
        provider.addEvent(event1);
        expect(provider.isEmpty, isFalse);
      });

      test('true after removing all events', () {
        provider.addEvent(event1);
        provider.removeEvent('1');

        expect(provider.isEmpty, isTrue);
      });

      test('true after clearEvents', () {
        provider.addEvent(event1);
        provider.addEvent(event2);
        provider.clearEvents();

        expect(provider.isEmpty, isTrue);
      });

      test('false after setEvents with non-empty list', () {
        provider.setEvents([event1]);
        expect(provider.isEmpty, isFalse);
      });

      test('true after setEvents with empty list', () {
        provider.addEvent(event1);
        provider.setEvents([]);

        expect(provider.isEmpty, isTrue);
      });
    });

    group('index consistency', () {
      test('getEventById works after add-remove-add sequence', () {
        provider.addEvent(event1);
        provider.addEvent(event2);
        provider.removeEvent('1');
        provider.addEvent(event3);

        expect(provider.getEventById('1'), isNull);
        expect(provider.getEventById('2'), isNotNull);
        expect(provider.getEventById('3'), isNotNull);
        expect(provider.eventCount, 2);
      });

      test('index is correct after removing middle element', () {
        provider.addEvent(event1);
        provider.addEvent(event2);
        provider.addEvent(event3);
        provider.removeEvent('2');

        // After removing middle, remaining events should still be findable
        expect(provider.getEventById('1')!.title, 'Meeting');
        expect(provider.getEventById('3')!.title, 'Review');
        expect(provider.events[0].id, '1');
        expect(provider.events[1].id, '3');
      });

      test('index survives setEvents then add', () {
        provider.setEvents([event1]);
        provider.addEvent(event2);

        expect(provider.getEventById('1'), isNotNull);
        expect(provider.getEventById('2'), isNotNull);
        expect(provider.eventCount, 2);
      });

      test('update after remove maintains consistency', () {
        provider.addEvent(event1);
        provider.addEvent(event2);
        provider.addEvent(event3);
        provider.removeEvent('1');
        provider.updateEvent(event3.copyWith(title: 'Updated Review'));

        expect(provider.getEventById('1'), isNull);
        expect(provider.getEventById('2'), isNotNull);
        expect(provider.getEventById('3')!.title, 'Updated Review');
      });

      test('clear then add resets index cleanly', () {
        provider.addEvent(event1);
        provider.addEvent(event2);
        provider.clearEvents();
        provider.addEvent(event3);

        expect(provider.getEventById('1'), isNull);
        expect(provider.getEventById('2'), isNull);
        expect(provider.getEventById('3'), isNotNull);
        expect(provider.eventCount, 1);
      });

      test('rapid add-remove cycle maintains correct state', () {
        for (var i = 0; i < 10; i++) {
          provider.addEvent(EventModel(
            id: 'tmp-$i',
            title: 'Temp $i',
            date: DateTime(2026, 1, 1),
          ));
        }
        // Remove odds
        for (var i = 1; i < 10; i += 2) {
          provider.removeEvent('tmp-$i');
        }

        expect(provider.eventCount, 5);
        for (var i = 0; i < 10; i += 2) {
          expect(provider.getEventById('tmp-$i'), isNotNull);
        }
        for (var i = 1; i < 10; i += 2) {
          expect(provider.getEventById('tmp-$i'), isNull);
        }
      });

      test('duplicate add does not corrupt index', () {
        // Adding an event with the same ID twice — second should overwrite
        // in the list (or be appended, depending on implementation).
        // The key thing is the index doesn't break.
        provider.addEvent(event1);
        provider.addEvent(event1); // same ID

        // Implementation appends, so there are 2 entries but index
        // points to the last one.
        expect(provider.events.length, 2);
        expect(provider.getEventById('1'), isNotNull);
      });

      test('remove non-existent does not corrupt state', () {
        provider.addEvent(event1);
        provider.addEvent(event2);
        provider.removeEvent('nonexistent');
        provider.removeEvent('also-nonexistent');

        expect(provider.eventCount, 2);
        expect(provider.getEventById('1'), isNotNull);
        expect(provider.getEventById('2'), isNotNull);
      });
    });
  });
}
