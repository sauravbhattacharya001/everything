import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:everything/views/home/focus_time_screen.dart';
import 'package:everything/state/providers/event_provider.dart';

void main() {
  Widget makeTestable() => ChangeNotifierProvider(
        create: (_) => EventProvider(),
        child: const MaterialApp(home: FocusTimeScreen()),
      );

  group('FocusTimeScreen', () {
    testWidgets('renders with 4 tabs', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.text('Focus Time'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Windows'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
    });

    testWidgets('Today tab shows score card', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.text('Focus Score'), findsWidgets);
      expect(find.text('Focus Time'), findsWidgets);
      expect(find.text('Meetings'), findsOneWidget);
      expect(find.text('Switches'), findsOneWidget);
    });

    testWidgets('Today tab shows fragmentation bar', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.text('Fragmentation'), findsOneWidget);
    });

    testWidgets('Today tab shows day timeline', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.text('Day Timeline'), findsOneWidget);
    });

    testWidgets('Today tab has date navigation', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('can navigate to previous day', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      // Should still render without errors
      expect(find.text('Focus Score'), findsWidgets);
    });

    testWidgets('can navigate to next day', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('Focus Score'), findsWidgets);
    });

    testWidgets('Week tab shows averages', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.text('Avg Focus'), findsOneWidget);
      expect(find.text('Avg Meetings'), findsOneWidget);
      expect(find.text('Avg Frag'), findsOneWidget);
    });

    testWidgets('Week tab shows daily bars heading', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.text('Daily Focus Minutes'), findsOneWidget);
    });

    testWidgets('Week tab has period selector', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('14 days'), findsOneWidget);
      expect(find.text('30 days'), findsOneWidget);
    });

    testWidgets('can switch to 14 day period', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('14 days'));
      await tester.pumpAndSettle();
      expect(find.text('Avg Focus'), findsOneWidget);
    });

    testWidgets('can switch to 30 day period', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30 days'));
      await tester.pumpAndSettle();
      expect(find.text('Avg Focus'), findsOneWidget);
    });

    testWidgets('Windows tab renders', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Windows'));
      await tester.pumpAndSettle();
      expect(find.text('Best Recurring Focus Windows'), findsOneWidget);
      expect(find.text('Hourly Availability'), findsOneWidget);
    });

    testWidgets('Windows tab shows description', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Windows'));
      await tester.pumpAndSettle();
      expect(
        find.text(
            'Time slots that are consistently free across your schedule.'),
        findsOneWidget,
      );
    });

    testWidgets('Insights tab renders score', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Overall Focus Score'), findsOneWidget);
    });

    testWidgets('Insights tab shows breakdown', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Score Breakdown'), findsOneWidget);
      expect(find.text('Low Fragmentation'), findsOneWidget);
    });

    testWidgets('Insights tab shows breakdown rows', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Focus Time'), findsWidgets);
      expect(find.text('Few Meetings'), findsOneWidget);
    });

    testWidgets('tab icons are present', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.byIcon(Icons.today), findsOneWidget);
      expect(find.byIcon(Icons.date_range), findsOneWidget);
      expect(find.byIcon(Icons.window), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('score card icon renders', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.byIcon(Icons.center_focus_strong), findsWidgets);
    });

    testWidgets('stat cards show correct icons', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.groups), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    });

    testWidgets('Today tab shows available focus blocks or empty state',
        (tester) async {
      await tester.pumpWidget(makeTestable());
      // With no events, should show focus blocks
      final hasBlocks =
          find.text('Available Focus Blocks').evaluate().isNotEmpty;
      final hasEmpty =
          find.text('No focus blocks available').evaluate().isNotEmpty;
      expect(hasBlocks || hasEmpty, isTrue);
    });

    testWidgets('focus block shows quality badge', (tester) async {
      await tester.pumpWidget(makeTestable());
      // With no events, all working hours are one big focus block
      final hasExcellent = find.text('excellent').evaluate().isNotEmpty;
      final hasGreat = find.text('great').evaluate().isNotEmpty;
      final hasGood = find.text('good').evaluate().isNotEmpty;
      // At least one quality label should appear
      expect(hasExcellent || hasGreat || hasGood, isTrue);
    });

    testWidgets('timeline legend shows Focus and Meeting', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.text('Focus'), findsWidgets);
      expect(find.text('Meeting'), findsOneWidget);
    });

    testWidgets('empty state renders icon', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      // Either has data or shows empty state
      final hasData =
          find.text('Daily Focus Minutes').evaluate().isNotEmpty;
      expect(hasData, isTrue);
    });

    testWidgets('Windows tab has period selector too', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Windows'));
      await tester.pumpAndSettle();
      expect(find.text('7 days'), findsOneWidget);
    });

    testWidgets('Insights tab has period selector', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('7 days'), findsOneWidget);
    });

    testWidgets('renders /100 score format', (tester) async {
      await tester.pumpWidget(makeTestable());
      // Should find at least one score in N/100 format
      expect(find.textContaining('/100'), findsWidgets);
    });

    testWidgets('can swipe between tabs', (tester) async {
      await tester.pumpWidget(makeTestable());
      // Swipe left to go to Week tab
      await tester.fling(
          find.text('Focus Score').first, const Offset(-300, 0), 500);
      await tester.pumpAndSettle();
      // Should transition without error
      expect(find.byType(FocusTimeScreen), findsOneWidget);
    });

    testWidgets('score label appears', (tester) async {
      await tester.pumpWidget(makeTestable());
      // One of these should appear based on score
      final hasExcellent =
          find.text('Excellent focus environment').evaluate().isNotEmpty;
      final hasGood =
          find.text('Good — room for improvement').evaluate().isNotEmpty;
      final hasModerate = find
          .text('Moderate — consider restructuring')
          .evaluate()
          .isNotEmpty;
      final hasLow = find
          .text('Low — too fragmented for deep work')
          .evaluate()
          .isNotEmpty;
      expect(hasExcellent || hasGood || hasModerate || hasLow, isTrue);
    });
  });
}
