import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/views/home/time_budget_screen.dart';

void main() {
  Widget makeTestable() => const MaterialApp(home: TimeBudgetScreen());

  group('TimeBudgetScreen', () {
    testWidgets('renders with 4 tabs', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.text('Time Budget'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Set'), findsOneWidget);
      expect(find.text('Compare'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
    });

    testWidgets('has tab icons', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.edit_calendar), findsOneWidget);
      expect(find.byIcon(Icons.compare_arrows), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });

    testWidgets('Budget tab shows summary strip', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.text('Tracked'), findsOneWidget);
      expect(find.text('Overloaded Days'), findsOneWidget);
      expect(find.text('Weeks'), findsOneWidget);
    });

    testWidgets('Budget tab shows Weekly Hour Budgets heading', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.text('Weekly Hour Budgets'), findsOneWidget);
    });

    testWidgets('Budget tab displays category cards', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.text('Work'), findsWidgets);
      expect(find.text('Personal'), findsWidgets);
      expect(find.text('Health'), findsWidgets);
    });

    testWidgets('Budget tab shows progress bars', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('Budget tab shows target and actual labels', (tester) async {
      await tester.pumpWidget(makeTestable());
      expect(find.textContaining('Target:'), findsWidgets);
      expect(find.textContaining('Actual:'), findsWidgets);
    });

    testWidgets('Budget tab shows utilization percentages', (tester) async {
      await tester.pumpWidget(makeTestable());
      // At least one percentage should show
      expect(find.textContaining('%'), findsWidgets);
    });

    // ── Set Tab ────────────────────────────────────────────────────────

    testWidgets('can switch to Set tab', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();
      expect(find.text('Set Budget Targets'), findsOneWidget);
    });

    testWidgets('Set tab has category dropdown', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();
      expect(find.text('Category'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('Set tab has hours slider', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsOneWidget);
      expect(find.textContaining('h/week'), findsWidgets);
    });

    testWidgets('Set tab has Add Budget button', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();
      expect(find.text('Add Budget'), findsOneWidget);
    });

    testWidgets('Set tab shows current budgets', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();
      expect(find.text('Current Budgets'), findsOneWidget);
      // Demo data has 4 budgets
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
    });

    testWidgets('Set tab has custom category toggle', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();
      expect(find.text('Custom'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('Set tab custom toggle shows text field', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Custom Category Name'), findsOneWidget);
    });

    testWidgets('Set tab delete removes a budget', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();
      final deleteButtons = find.byIcon(Icons.delete_outline);
      final countBefore = deleteButtons.evaluate().length;
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();
      final countAfter = find.byIcon(Icons.delete_outline).evaluate().length;
      expect(countAfter, countBefore - 1);
    });

    // ── Compare Tab ────────────────────────────────────────────────────

    testWidgets('can switch to Compare tab', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Compare'));
      await tester.pumpAndSettle();
      expect(find.text('Planned vs Actual'), findsOneWidget);
    });

    testWidgets('Compare tab shows bar chart legend', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Compare'));
      await tester.pumpAndSettle();
      // Legend has Budget and Actual labels
      expect(find.text('Budget'), findsWidgets);
      expect(find.text('Actual'), findsWidgets);
    });

    testWidgets('Compare tab shows category comparison bars', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Compare'));
      await tester.pumpAndSettle();
      // Should show Work, Personal, Health, Learning categories
      expect(find.text('Work'), findsWidgets);
    });

    testWidgets('Compare tab shows over/under indicators', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Compare'));
      await tester.pumpAndSettle();
      // At least one Over by or Under by
      final overFinder = find.textContaining('Over by');
      final underFinder = find.textContaining('Under by');
      expect(
        overFinder.evaluate().length + underFinder.evaluate().length,
        greaterThan(0),
      );
    });

    testWidgets('Compare tab shows Weekday Distribution', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Compare'));
      await tester.pumpAndSettle();
      expect(find.text('Weekday Distribution'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
    });

    // ── Insights Tab ────────────────────────────────────────────────────

    testWidgets('can switch to Insights tab', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Busiest Day'), findsOneWidget);
      expect(find.text('Lightest Day'), findsOneWidget);
    });

    testWidgets('Insights tab shows stat cards', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Top Category'), findsOneWidget);
      expect(find.text('Avg Hours/Day'), findsOneWidget);
    });

    testWidgets('Insights tab shows over-budget warnings', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Over-Budget Warnings'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsWidgets);
    });

    testWidgets('Insights tab shows overloaded days', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Overloaded Days'), findsWidgets);
      expect(find.textContaining('over'), findsWidgets);
    });

    testWidgets('Insights tab shows recommendations', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Recommendations'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsWidgets);
    });

    testWidgets('Insights tab shows avg hours per day value', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.textContaining('h'), findsWidgets);
    });
  });
}
