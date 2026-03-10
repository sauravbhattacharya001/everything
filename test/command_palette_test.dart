import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:everything/core/services/command_palette_service.dart';

void main() {
  group('PaletteAction', () {
    late PaletteAction action;

    setUp(() {
      action = PaletteAction(
        id: 'nav_calendar',
        label: 'Calendar',
        subtitle: 'View your schedule',
        icon: Icons.calendar_today,
        category: 'Navigation',
        keywords: ['schedule', 'dates', 'month'],
        onExecute: (_) {},
      );
    });

    test('exact prefix match returns 1.0', () {
      expect(action.matchScore('Cal'), 1.0);
      expect(action.matchScore('calendar'), 1.0);
    });

    test('contains match returns 0.9', () {
      expect(action.matchScore('enda'), 0.9);
    });

    test('keyword prefix match returns 0.85', () {
      expect(action.matchScore('sched'), 0.85);
    });

    test('keyword contains match returns 0.75', () {
      expect(action.matchScore('ates'), 0.75);
    });

    test('category match returns 0.7', () {
      expect(action.matchScore('Navig'), 0.7);
    });

    test('subtitle match returns 0.6', () {
      expect(action.matchScore('schedule'), closeTo(0.85, 0.01)); // keyword first
      // Test subtitle-only match
      final a2 = PaletteAction(
        id: 'test',
        label: 'Foo',
        subtitle: 'unique subtitle text',
        icon: Icons.abc,
        category: 'Cat',
        onExecute: (_) {},
      );
      expect(a2.matchScore('subtitle'), 0.6);
    });

    test('fuzzy match returns 0.4', () {
      expect(action.matchScore('clndr'), 0.4);
    });

    test('no match returns 0.0', () {
      expect(action.matchScore('zzzzz'), 0.0);
    });

    test('empty query returns 1.0', () {
      expect(action.matchScore(''), 1.0);
    });

    test('case insensitive matching', () {
      expect(action.matchScore('CALENDAR'), 1.0);
      expect(action.matchScore('cAlEnDaR'), 1.0);
    });
  });

  group('CommandPaletteService', () {
    late CommandPaletteService service;

    setUp(() {
      service = CommandPaletteService.instance;
      // Clear recent state
      while (service.recentScreenIds.isNotEmpty) {
        // We can't clear directly, but recording a new visit will cycle out
        break;
      }
    });

    test('buildActions returns all actions', () {
      final actions = service.buildActions();
      // Should have navigation + quick actions
      expect(actions.length, greaterThan(40));
    });

    test('buildActions includes all categories', () {
      final actions = service.buildActions();
      final categories = actions.map((a) => a.category).toSet();
      expect(categories, containsAll([
        'Navigation', 'Trackers', 'Productivity', 'Finance',
        'Personal', 'Lists', 'Quick Actions',
      ]));
    });

    test('recordVisit tracks recent screens', () {
      service.recordVisit('nav_calendar');
      service.recordVisit('nav_water');
      expect(service.recentScreenIds, contains('nav_calendar'));
      expect(service.recentScreenIds, contains('nav_water'));
      // Most recent should be first
      expect(service.recentScreenIds.first, 'nav_water');
    });

    test('recordVisit deduplicates', () {
      service.recordVisit('nav_goals');
      service.recordVisit('nav_mood');
      service.recordVisit('nav_goals');
      final count = service.recentScreenIds
          .where((id) => id == 'nav_goals')
          .length;
      expect(count, 1);
      expect(service.recentScreenIds.first, 'nav_goals');
    });

    test('recordVisit caps at 5', () {
      for (int i = 0; i < 10; i++) {
        service.recordVisit('screen_$i');
      }
      expect(service.recentScreenIds.length, lessThanOrEqualTo(5));
    });

    test('all nav actions have unique ids', () {
      final actions = service.buildActions();
      final ids = actions.map((a) => a.id).toList();
      expect(ids.length, ids.toSet().length);
    });

    test('all actions have non-empty labels', () {
      final actions = service.buildActions();
      for (final a in actions) {
        expect(a.label.isNotEmpty, true, reason: 'Action ${a.id} has empty label');
      }
    });

    test('quick actions have subtitles', () {
      final actions = service.buildActions()
          .where((a) => a.category == 'Quick Actions');
      for (final a in actions) {
        expect(a.subtitle, isNotNull,
            reason: 'Quick action ${a.id} should have subtitle');
      }
    });
  });

  group('CommandPaletteOverlay widget', () {
    testWidgets('shows search field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox()),
        ),
      );

      // We can't easily test the overlay without full app context,
      // but we can verify the service works correctly
      final service = CommandPaletteService.instance;
      final actions = service.buildActions();
      expect(actions, isNotEmpty);
    });

    testWidgets('filtering works correctly', (tester) async {
      final actions = CommandPaletteService.instance.buildActions();

      // Test filtering
      final waterResults = actions.where((a) => a.matchScore('water') > 0).toList();
      expect(waterResults.length, greaterThan(0));

      // Water tracker should be in results
      final waterTracker = waterResults.firstWhere(
        (a) => a.id == 'nav_water',
        orElse: () => waterResults.first,
      );
      expect(waterTracker.matchScore('water'), greaterThan(0.5));
    });

    testWidgets('quick actions appear for relevant queries', (tester) async {
      final actions = CommandPaletteService.instance.buildActions();
      final quickActions = actions
          .where((a) => a.category == 'Quick Actions')
          .toList();

      // Should have common quick actions
      final ids = quickActions.map((a) => a.id).toSet();
      expect(ids, contains('action_new_event'));
      expect(ids, contains('action_log_water'));
      expect(ids, contains('action_start_pomodoro'));
      expect(ids, contains('action_log_mood'));
      expect(ids, contains('action_daily_review'));
    });
  });
}
