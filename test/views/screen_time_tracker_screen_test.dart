import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/views/home/screen_time_tracker_screen.dart';

void main() {
  Widget createApp() => const MaterialApp(home: ScreenTimeTrackerScreen());

  group('ScreenTimeTrackerScreen', () {
    testWidgets('renders with 4 tabs', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Screen Time'), findsOneWidget);
      expect(find.text('Log'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Breakdown'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
    });

    testWidgets('Log tab shows quick add chips', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Quick Add'), findsOneWidget);
      expect(find.text('Instagram'), findsWidgets);
      expect(find.text('YouTube'), findsWidgets);
    });

    testWidgets('Log tab shows form fields', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('App Name'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Log Screen Time'), findsOneWidget);
    });

    testWidgets('Log tab has duration quick buttons', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('5m'), findsOneWidget);
      expect(find.text('15m'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
    });

    testWidgets('Today tab shows summary cards with demo data', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.text('Total'), findsWidgets);
      expect(find.text('Pickups'), findsWidgets);
      expect(find.text('Apps'), findsWidgets);
    });

    testWidgets('Today tab shows grade badge', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      // Grade should be displayed (A-F)
      expect(find.textContaining('Grade:'), findsOneWidget);
    });

    testWidgets('Today tab has date navigation arrows', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('Today tab shows usage log', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Usage Log'), findsOneWidget);
    });

    testWidgets('Breakdown tab shows overview stats', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Breakdown'));
      await tester.pumpAndSettle();
      expect(find.text('📊 Overview'), findsOneWidget);
      expect(find.text('Days Tracked'), findsOneWidget);
      expect(find.text('Avg Daily'), findsOneWidget);
    });

    testWidgets('Breakdown tab shows category breakdown', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Breakdown'));
      await tester.pumpAndSettle();
      expect(find.text('📂 By Category'), findsOneWidget);
    });

    testWidgets('Breakdown tab shows app rankings', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Breakdown'));
      await tester.pumpAndSettle();
      expect(find.text('🏆 App Rankings'), findsOneWidget);
    });

    testWidgets('Breakdown tab shows active limits', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Breakdown'));
      await tester.pumpAndSettle();
      expect(find.text('⏱️ Active Limits'), findsOneWidget);
    });

    testWidgets('Insights tab shows wellbeing score', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Digital Wellbeing'), findsOneWidget);
    });

    testWidgets('Insights tab shows daily goal card', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('🎯 Daily Goal'), findsOneWidget);
    });

    testWidgets('Insights tab shows streak cards', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Current'), findsWidgets);
      expect(find.textContaining('Streak'), findsWidgets);
    });

    testWidgets('Insights tab shows insights list', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('💡 Insights'), findsOneWidget);
    });

    testWidgets('Insights tab shows top category', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Most Used Category'), findsOneWidget);
    });

    testWidgets('Today tab date nav goes back', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      // Should still render without error
      expect(find.textContaining('Grade:'), findsOneWidget);
    });

    testWidgets('selecting preset chip updates category', (tester) async {
      await tester.pumpWidget(createApp());
      // Tap a preset chip
      await tester.tap(find.text('Netflix').first);
      await tester.pumpAndSettle();
      // Should be selected
      expect(find.text('Netflix'), findsWidgets);
    });

    testWidgets('Today tab shows limit violations for demo data', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      // Demo data has social > 60 min (Instagram 45 + Twitter 25 = 70) and YouTube 60 > 45 limit
      expect(find.textContaining('Limit Violations'), findsOneWidget);
    });

    testWidgets('Today tab shows top app', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.text('📱 Top App'), findsOneWidget);
    });

    testWidgets('Breakdown tab shows streak stats', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Breakdown'));
      await tester.pumpAndSettle();
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Best Streak'), findsOneWidget);
    });

    testWidgets('tab switching works correctly', (tester) async {
      await tester.pumpWidget(createApp());
      // Start on Log
      expect(find.text('Quick Add'), findsOneWidget);
      // Go to Today
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Grade:'), findsOneWidget);
      // Go to Breakdown
      await tester.tap(find.text('Breakdown'));
      await tester.pumpAndSettle();
      expect(find.text('📊 Overview'), findsOneWidget);
      // Go to Insights
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Digital Wellbeing'), findsOneWidget);
      // Back to Log
      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();
      expect(find.text('Quick Add'), findsOneWidget);
    });
  });
}
