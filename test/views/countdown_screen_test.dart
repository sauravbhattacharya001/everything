import 'package:flutter_test/flutter_test.dart';
import 'package:everything/views/home/countdown_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:everything/state/providers/event_provider.dart';
import 'package:everything/models/event_model.dart';

void main() {
  group('CountdownScreen', () {
    Widget createTestWidget({List<EventModel>? events}) {
      final provider = EventProvider();
      if (events != null) {
        for (final e in events) {
          provider.addEvent(e);
        }
      }
      return MaterialApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: const CountdownScreen(),
        ),
      );
    }

    testWidgets('shows empty state when no events', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('No upcoming events'), findsOneWidget);
    });

    testWidgets('shows countdown for future event', (tester) async {
      final futureEvent = EventModel(
        id: 'test-1',
        title: 'Future Meeting',
        date: DateTime.now().add(const Duration(days: 5, hours: 3)),
      );
      await tester.pumpWidget(createTestWidget(events: [futureEvent]));
      await tester.pump();

      expect(find.text('Future Meeting'), findsOneWidget);
      expect(find.text('days'), findsOneWidget);
      expect(find.text('hrs'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);
      expect(find.text('sec'), findsOneWidget);
    });

    testWidgets('does not show past events', (tester) async {
      final pastEvent = EventModel(
        id: 'past-1',
        title: 'Past Event',
        date: DateTime.now().subtract(const Duration(days: 1)),
      );
      await tester.pumpWidget(createTestWidget(events: [pastEvent]));
      expect(find.text('No upcoming events'), findsOneWidget);
    });

    testWidgets('sorts events by date ascending', (tester) async {
      final soonEvent = EventModel(
        id: 'soon',
        title: 'Soon Event',
        date: DateTime.now().add(const Duration(hours: 2)),
      );
      final laterEvent = EventModel(
        id: 'later',
        title: 'Later Event',
        date: DateTime.now().add(const Duration(days: 10)),
      );
      await tester.pumpWidget(createTestWidget(events: [laterEvent, soonEvent]));
      await tester.pump();

      final soonOffset = tester.getTopLeft(find.text('Soon Event'));
      final laterOffset = tester.getTopLeft(find.text('Later Event'));
      expect(soonOffset.dy, lessThan(laterOffset.dy));
    });
  });
}
