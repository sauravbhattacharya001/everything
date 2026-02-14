import 'package:flutter_test/flutter_test.dart';
import 'package:everything/state/blocs/event_bloc.dart';
import 'package:everything/models/event_model.dart';

void main() {
  late EventBloc bloc;

  setUp(() {
    bloc = EventBloc();
  });

  tearDown(() {
    bloc.close();
  });

  group('EventBloc', () {
    final event1 = EventModel(
      id: '1',
      title: 'Sprint Planning',
      date: DateTime(2026, 2, 14, 9),
    );
    final event2 = EventModel(
      id: '2',
      title: 'Code Review',
      date: DateTime(2026, 2, 14, 14),
    );
    final event3 = EventModel(
      id: '3',
      title: 'Retro',
      date: DateTime(2026, 2, 14, 16),
    );

    group('initial state', () {
      test('starts in EventInitial state', () {
        expect(bloc.state, isA<EventInitial>());
      });
    });

    group('loadEvents', () {
      test('transitions to EventLoaded with events', () {
        bloc.loadEvents([event1, event2]);

        expect(bloc.state, isA<EventLoaded>());
        final loaded = bloc.state as EventLoaded;
        expect(loaded.events.length, 2);
        expect(loaded.events[0].title, 'Sprint Planning');
        expect(loaded.events[1].title, 'Code Review');
      });

      test('loading empty list results in EventLoaded with empty list', () {
        bloc.loadEvents([]);

        expect(bloc.state, isA<EventLoaded>());
        expect((bloc.state as EventLoaded).events, isEmpty);
      });

      test('loading replaces previous events', () {
        bloc.loadEvents([event1]);
        bloc.loadEvents([event2, event3]);

        final loaded = bloc.state as EventLoaded;
        expect(loaded.events.length, 2);
        expect(loaded.events[0].id, '2');
      });
    });

    group('addEvent', () {
      test('adds event to loaded state', () {
        bloc.loadEvents([event1]);
        bloc.addEvent(event2);

        final loaded = bloc.state as EventLoaded;
        expect(loaded.events.length, 2);
        expect(loaded.events.last.id, '2');
      });

      test('does nothing when in initial state', () {
        bloc.addEvent(event1);

        // Should still be EventInitial since addEvent only works on EventLoaded
        expect(bloc.state, isA<EventInitial>());
      });

      test('preserves existing events when adding', () {
        bloc.loadEvents([event1, event2]);
        bloc.addEvent(event3);

        final loaded = bloc.state as EventLoaded;
        expect(loaded.events.length, 3);
        expect(loaded.events[0].id, '1');
        expect(loaded.events[1].id, '2');
        expect(loaded.events[2].id, '3');
      });
    });

    group('removeEvent', () {
      test('removes event by id', () {
        bloc.loadEvents([event1, event2, event3]);
        bloc.removeEvent('2');

        final loaded = bloc.state as EventLoaded;
        expect(loaded.events.length, 2);
        expect(loaded.events.any((e) => e.id == '2'), isFalse);
      });

      test('does nothing when id not found', () {
        bloc.loadEvents([event1]);
        bloc.removeEvent('nonexistent');

        final loaded = bloc.state as EventLoaded;
        expect(loaded.events.length, 1);
      });

      test('does nothing when in initial state', () {
        bloc.removeEvent('1');

        expect(bloc.state, isA<EventInitial>());
      });

      test('removing last event results in empty loaded state', () {
        bloc.loadEvents([event1]);
        bloc.removeEvent('1');

        final loaded = bloc.state as EventLoaded;
        expect(loaded.events, isEmpty);
      });
    });

    group('stream emissions', () {
      test('emits states in order', () async {
        final states = <EventState>[];
        final sub = bloc.stream.listen(states.add);

        bloc.loadEvents([event1]);
        bloc.addEvent(event2);
        bloc.removeEvent('1');

        // Allow microtasks to complete
        await Future.delayed(Duration.zero);

        expect(states.length, 3);
        expect(states[0], isA<EventLoaded>());
        expect((states[0] as EventLoaded).events.length, 1);
        expect(states[1], isA<EventLoaded>());
        expect((states[1] as EventLoaded).events.length, 2);
        expect(states[2], isA<EventLoaded>());
        expect((states[2] as EventLoaded).events.length, 1);

        await sub.cancel();
      });
    });
  });
}
