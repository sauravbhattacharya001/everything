import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:everything/views/home/weekly_planner_screen.dart';
import 'package:everything/state/providers/event_provider.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/core/services/weekly_planner_service.dart';

Widget _wrap({List<EventModel>? events}) {
  final provider = EventProvider();
  if (events != null) {
    for (final e in events) {
      provider.addEvent(e);
    }
  }
  return ChangeNotifierProvider<EventProvider>.value(
    value: provider,
    child: const MaterialApp(home: WeeklyPlannerScreen()),
  );
}

void main() {
  group('WeeklyPlannerScreen', () {
    testWidgets('renders with title and 4 tabs', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Weekly Planner'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('Warnings'), findsOneWidget);
    });

    testWidgets('settings button exists', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('overview tab shows summary stats', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Week at a Glance'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Avg Load'), findsOneWidget);
      expect(find.text('Overloaded'), findsOneWidget);
    });

    testWidgets('overview tab shows daily load section', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Daily Load'), findsOneWidget);
      // Should show abbreviated day names
      expect(find.text('Mon'), findsWidgets);
    });

    testWidgets('overview tab shows item breakdown', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Item Breakdown'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Goal Blocks'), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
    });

    testWidgets('can switch to daily tab', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();
      // Day selector chips should appear
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('daily tab shows day header', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();
      // Should show a load label
      expect(
        find.textContaining(RegExp(r'free|light|moderate|heavy|overloaded')),
        findsWidgets,
      );
    });

    testWidgets('can switch to goals tab', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();
      // With no goals, shows empty state
      expect(find.text('No goal blocks scheduled'), findsOneWidget);
    });

    testWidgets('goals empty state has icon', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });

    testWidgets('can switch to warnings tab', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.text('Warnings'));
      await tester.pumpAndSettle();
      // With no events/goals, should show no warnings
      expect(find.text('No warnings'), findsOneWidget);
    });

    testWidgets('warnings empty state shows check icon', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.text('Warnings'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      expect(find.text('Your week looks well-balanced!'), findsOneWidget);
    });

    testWidgets('settings dialog opens', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Planner Settings'), findsOneWidget);
      expect(find.text('Day starts at'), findsOneWidget);
      expect(find.text('Day ends at'), findsOneWidget);
      expect(find.text('Plan days ahead'), findsOneWidget);
      expect(find.text('Goal block size'), findsOneWidget);
    });

    testWidgets('settings dialog has cancel and apply', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('settings cancel closes dialog', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Planner Settings'), findsNothing);
    });

    testWidgets('settings apply closes dialog', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Planner Settings'), findsNothing);
    });

    testWidgets('with events shows items on daily tab', (tester) async {
      final now = DateTime.now();
      final event = EventModel(
        id: 'e1',
        title: 'Test Meeting',
        date: DateTime(now.year, now.month, now.day, 10, 0),
        endDate: DateTime(now.year, now.month, now.day, 11, 0),
      );
      await tester.pumpWidget(_wrap(events: [event]));
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();
      expect(find.text('Test Meeting'), findsOneWidget);
    });

    testWidgets('event card shows time range', (tester) async {
      final now = DateTime.now();
      final event = EventModel(
        id: 'e2',
        title: 'Standup',
        date: DateTime(now.year, now.month, now.day, 9, 30),
        endDate: DateTime(now.year, now.month, now.day, 9, 45),
      );
      await tester.pumpWidget(_wrap(events: [event]));
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();
      expect(find.textContaining('09:30'), findsOneWidget);
    });

    testWidgets('overview updates with events', (tester) async {
      final now = DateTime.now();
      final events = List.generate(3, (i) => EventModel(
        id: 'ev$i',
        title: 'Event $i',
        date: DateTime(now.year, now.month, now.day, 10 + i, 0),
        endDate: DateTime(now.year, now.month, now.day, 10 + i, 30),
      ));
      await tester.pumpWidget(_wrap(events: events));
      // Should show non-zero planned time
      expect(find.textContaining('h'), findsWidgets);
    });

    testWidgets('day selector chips are tappable', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();
      final chips = find.byType(ChoiceChip);
      expect(chips, findsWidgets);
      // Tap second chip
      if (tester.widgetList(chips).length > 1) {
        await tester.tap(chips.at(1));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('has tab bar icons', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      expect(find.byIcon(Icons.view_day), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsWidgets);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('free time items shown in daily view', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();
      // With no events, most time should be free
      expect(find.text('Free time'), findsWidgets);
    });

    testWidgets('daily tab shows planned and free minutes', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();
      expect(find.textContaining('planned'), findsWidgets);
      expect(find.textContaining('free'), findsWidgets);
    });
  });

  group('WeeklyPlannerService', () {
    test('generates plan with correct number of days', () {
      final service = WeeklyPlannerService(
        config: const PlannerConfig(planDays: 7),
        referenceDate: DateTime(2026, 3, 9, 10, 0),
      );
      final plan = service.generate();
      expect(plan.days.length, 7);
    });

    test('default config has sensible values', () {
      const config = PlannerConfig();
      expect(config.dayStartHour, 8);
      expect(config.dayEndHour, 20);
      expect(config.planDays, 7);
      expect(config.goalBlockMinutes, 60);
    });

    test('load score is 0 with no items', () {
      final service = WeeklyPlannerService(
        referenceDate: DateTime(2026, 3, 9, 10, 0),
      );
      final plan = service.generate();
      for (final day in plan.days) {
        expect(day.loadScore, 0.0);
      }
    });

    test('plan summary is not empty', () {
      final service = WeeklyPlannerService(
        referenceDate: DateTime(2026, 3, 9, 10, 0),
      );
      final plan = service.generate();
      expect(plan.summary.isNotEmpty, true);
      expect(plan.summary, contains('Weekly Plan'));
    });

    test('plan toString includes day count', () {
      final service = WeeklyPlannerService(
        referenceDate: DateTime(2026, 3, 9, 10, 0),
      );
      final plan = service.generate();
      expect(plan.toString(), contains('7 days'));
    });

    test('daily plan shows correct weekday', () {
      final service = WeeklyPlannerService(
        referenceDate: DateTime(2026, 3, 9, 10, 0), // Monday
      );
      final plan = service.generate();
      expect(plan.days.first.weekdayName, 'Monday');
    });

    test('plan with events shows non-zero load', () {
      final service = WeeklyPlannerService(
        referenceDate: DateTime(2026, 3, 9, 10, 0),
      );
      final plan = service.generate(events: [
        EventModel(
          id: 'e1',
          title: 'Meeting',
          date: DateTime(2026, 3, 9, 10, 0),
          endDate: DateTime(2026, 3, 9, 12, 0),
        ),
      ]);
      expect(plan.days.first.loadScore, greaterThan(0));
    });

    test('events on a day are included as plan items', () {
      final service = WeeklyPlannerService(
        referenceDate: DateTime(2026, 3, 9, 10, 0),
      );
      final plan = service.generate(events: [
        EventModel(
          id: 'e1',
          title: 'Standup',
          date: DateTime(2026, 3, 9, 9, 0),
          endDate: DateTime(2026, 3, 9, 9, 30),
        ),
      ]);
      final eventItems = plan.days.first.items
          .where((i) => i.type == PlanItemType.event)
          .toList();
      expect(eventItems.length, 1);
      expect(eventItems.first.title, 'Standup');
    });

    test('PlanItem toString shows time range', () {
      final item = PlanItem(
        type: PlanItemType.event,
        title: 'Test',
        start: DateTime(2026, 3, 9, 10, 0),
        end: DateTime(2026, 3, 9, 11, 0),
      );
      expect(item.toString(), contains('10:00'));
      expect(item.toString(), contains('11:00'));
    });

    test('PlanWarning toString shows message', () {
      final w = PlanWarning(
        severity: WarningSeverity.warning,
        message: 'Overloaded day',
      );
      expect(w.toString(), contains('Overloaded day'));
    });

    test('DailyPlan loadLabel values', () {
      // Free
      final free = DailyPlan(
        date: DateTime(2026, 3, 9),
        items: [],
        loadScore: 0.1,
        warnings: [],
      );
      expect(free.loadLabel, 'free');

      final heavy = DailyPlan(
        date: DateTime(2026, 3, 9),
        items: [],
        loadScore: 0.9,
        warnings: [],
      );
      expect(heavy.loadLabel, 'heavy');
    });

    test('config dailyMinutes calculation', () {
      const config = PlannerConfig(dayStartHour: 8, dayEndHour: 20);
      expect(config.dailyMinutes, 720);
    });
  });
}
