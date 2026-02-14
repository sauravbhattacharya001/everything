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
  });
}
