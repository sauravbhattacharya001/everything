import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/views/home/routine_builder_screen.dart';
import 'package:everything/core/services/routine_builder_service.dart';
import 'package:everything/models/routine.dart';

void main() {
  group('RoutineBuilderScreen', () {
    Widget buildApp() => const MaterialApp(home: RoutineBuilderScreen());

    testWidgets('renders with 4 tabs', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Routine Builder'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Run'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('Today tab shows scheduled routines from templates', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Morning Routine'), findsOneWidget);
    });

    testWidgets('Library tab shows all routines', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(find.text('Morning Routine'), findsOneWidget);
      expect(find.text('Evening Wind-Down'), findsOneWidget);
      expect(find.text('Workout Session'), findsOneWidget);
      expect(find.text('Deep Study Block'), findsOneWidget);
    });

    testWidgets('can expand routine to see steps', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Morning Routine'));
      await tester.pumpAndSettle();
      expect(find.text('Add Step'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('start button appears for unstarted routines', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Start'), findsWidgets);
    });

    testWidgets('can start a routine run', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Start').first);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsWidgets);
    });

    testWidgets('Run tab shows empty state when no runs', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();
      expect(find.text('No active runs today.'), findsOneWidget);
    });

    testWidgets('Analytics tab shows routines with stats', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      expect(find.text('Total Runs'), findsWidgets);
      expect(find.text('Completion'), findsWidgets);
    });

    testWidgets('date navigation works', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Today'), findsWidgets);
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('Tomorrow'), findsOneWidget);
    });

    testWidgets('add routine dialog opens from menu', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('New Custom Routine'), findsOneWidget);
      expect(find.text('From Template'), findsOneWidget);
    });

    testWidgets('new custom routine dialog has form fields', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Custom Routine'));
      await tester.pumpAndSettle();
      expect(find.text('New Routine'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('can delete routine from library', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Morning Routine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();
      expect(find.text('Routine removed'), findsOneWidget);
    });

    testWidgets('can pause/activate routine', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Evening Wind-Down'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pause').first);
      await tester.pumpAndSettle();
      expect(find.text('Activate'), findsWidgets);
    });

    testWidgets('stat chips show on Today tab', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Routines'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('yesterday navigation shows correct label', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('Yesterday'), findsOneWidget);
    });
  });

  group('RoutineBuilderService (unit)', () {
    test('addRoutine and getRoutine work', () {
      final svc = RoutineBuilderService();
      final r = Routine(
        id: 'r1', name: 'Test', createdAt: DateTime.now(),
        steps: [const RoutineStep(id: 's1', name: 'Step 1', order: 0)],
      );
      svc.addRoutine(r);
      expect(svc.routines.length, 1);
      expect(svc.getRoutine('r1')?.name, 'Test');
    });

    test('startRun creates run with pending steps', () {
      final svc = RoutineBuilderService();
      svc.addRoutine(RoutineBuilderService.createTemplate('morning'));
      final run = svc.startRun(svc.routines.first.id);
      expect(run.stepCompletions.length, 6);
      expect(run.pendingCount, 6);
      expect(run.isFinished, false);
    });

    test('completeStep marks step done', () {
      final svc = RoutineBuilderService();
      svc.addRoutine(RoutineBuilderService.createTemplate('morning'));
      final routine = svc.routines.first;
      final now = DateTime.now();
      svc.startRun(routine.id, now: now);
      final updated = svc.completeStep(routine.id, now, routine.steps.first.id);
      expect(updated.completedCount, 1);
    });

    test('skipStep marks step skipped', () {
      final svc = RoutineBuilderService();
      svc.addRoutine(RoutineBuilderService.createTemplate('morning'));
      final routine = svc.routines.first;
      final now = DateTime.now();
      svc.startRun(routine.id, now: now);
      final updated = svc.skipStep(routine.id, now, routine.steps.first.id);
      expect(updated.skippedCount, 1);
    });

    test('getAnalytics returns empty analytics for new routine', () {
      final svc = RoutineBuilderService();
      svc.addRoutine(RoutineBuilderService.createTemplate('morning'));
      final analytics = svc.getAnalytics(svc.routines.first.id);
      expect(analytics.totalRuns, 0);
      expect(analytics.completionRate, 0.0);
    });

    test('template creation works for all templates', () {
      for (final name in RoutineBuilderService.templateNames) {
        final r = RoutineBuilderService.createTemplate(name);
        expect(r.steps.isNotEmpty, true);
        expect(r.name.isNotEmpty, true);
      }
    });

    test('reorderSteps changes step order', () {
      final svc = RoutineBuilderService();
      svc.addRoutine(RoutineBuilderService.createTemplate('morning'));
      final routine = svc.routines.first;
      final reversed = routine.steps.map((s) => s.id).toList().reversed.toList();
      final updated = svc.reorderSteps(routine.id, reversed);
      expect(updated.steps.first.id, reversed.first);
    });

    test('removeRoutine also removes runs', () {
      final svc = RoutineBuilderService();
      svc.addRoutine(RoutineBuilderService.createTemplate('morning'));
      final id = svc.routines.first.id;
      svc.startRun(id);
      expect(svc.runs.length, 1);
      svc.removeRoutine(id);
      expect(svc.runs.length, 0);
    });

    test('getDailySummary returns correct format', () {
      final svc = RoutineBuilderService();
      svc.addRoutine(RoutineBuilderService.createTemplate('morning'));
      final summary = svc.getDailySummary(DateTime.now());
      expect(summary['totalRoutines'], greaterThan(0));
    });

    test('duplicate routine id throws', () {
      final svc = RoutineBuilderService();
      svc.addRoutine(RoutineBuilderService.createTemplate('morning'));
      expect(() => svc.addRoutine(svc.routines.first), throwsArgumentError);
    });

    test('starting run twice same day throws', () {
      final svc = RoutineBuilderService();
      svc.addRoutine(RoutineBuilderService.createTemplate('morning'));
      final id = svc.routines.first.id;
      svc.startRun(id);
      expect(() => svc.startRun(id), throwsStateError);
    });

    test('completing already-completed step throws', () {
      final svc = RoutineBuilderService();
      svc.addRoutine(RoutineBuilderService.createTemplate('morning'));
      final routine = svc.routines.first;
      final now = DateTime.now();
      svc.startRun(routine.id, now: now);
      svc.completeStep(routine.id, now, routine.steps.first.id);
      expect(() => svc.completeStep(routine.id, now, routine.steps.first.id), throwsStateError);
    });
  });
}
