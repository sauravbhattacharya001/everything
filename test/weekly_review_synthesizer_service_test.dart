import 'package:flutter_test/flutter_test.dart';

import 'package:everything/core/services/weekly_review_synthesizer_service.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 5, 19, 12, 0, 0);
  final weekStart = DateTime.utc(2026, 5, 11);
  final weekEnd = DateTime.utc(2026, 5, 17);

  WeeklyReviewSynthesizer build() =>
      WeeklyReviewSynthesizer(now: () => fixedNow);

  group('WeeklyReviewSynthesizer', () {
    test('empty inputs return EMPTY_WEEK insight + grade C', () {
      final r = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [],
        goals: const [],
      );
      expect(r.insights, contains('EMPTY_WEEK'));
      expect(r.grade, 'C');
      expect(r.items, isEmpty);
      expect(r.summary, contains('No tracked data'));
    });

    test('all targets hit and goals on-pace produces no P0', () {
      final r = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [
          WeeklyHabitInput(
            id: 'h1',
            name: 'Meditate',
            weeklyTarget: 5,
            completions: 5,
          ),
          WeeklyHabitInput(
            id: 'h2',
            name: 'Run',
            weeklyTarget: 3,
            completions: 3,
          ),
        ],
        goals: const [
          WeeklyGoalInput(
            id: 'g1',
            name: 'Ship feature',
            startProgress: 0.5,
            endProgress: 0.6,
            weeklyTargetDelta: 0.10,
          ),
        ],
      );
      expect(
        r.items.any((it) => it.priority == WeeklyReviewPriority.p0),
        isFalse,
      );
      expect(r.weekScore, greaterThanOrEqualTo(70));
      expect(
        r.playbook.any(
          (a) =>
              a.code == 'CELEBRATE_WIN' ||
              a.code == 'CARRY_MOMENTUM' ||
              a.code == 'WEEKLY_REVIEW_HEALTHY',
        ),
        isTrue,
      );
    });

    test('keystone MISSED -> RESCUE_KEYSTONE P0 + insight', () {
      final r = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [
          WeeklyHabitInput(
            id: 'sleep',
            name: 'Sleep 8h',
            weeklyTarget: 7,
            completions: 1,
            isKeystone: true,
          ),
        ],
        goals: const [],
      );
      expect(r.insights, contains('KEYSTONE_AT_RISK'));
      expect(r.playbook.any((a) => a.code == 'RESCUE_KEYSTONE'), isTrue);
      expect(
        r.playbook.firstWhere((a) => a.code == 'RESCUE_KEYSTONE').priority,
        WeeklyReviewPriority.p0,
      );
      expect(
        r.verdict == WeeklyReviewVerdict.slippingWeek ||
            r.verdict == WeeklyReviewVerdict.crashAndReset,
        isTrue,
      );
    });

    test('stagnant goal with distant deadline -> ARCHIVE_STAGNANT_GOAL P0', () {
      final r = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [],
        goals: [
          WeeklyGoalInput(
            id: 'g_stale',
            name: 'Old project',
            startProgress: 0.3,
            endProgress: 0.3,
            weeklyTargetDelta: 0.05,
            deadline: fixedNow.add(const Duration(days: 90)),
          ),
        ],
      );
      expect(
        r.playbook.any((a) => a.code == 'ARCHIVE_STAGNANT_GOAL'),
        isTrue,
      );
      expect(
        r.playbook
            .firstWhere((a) => a.code == 'ARCHIVE_STAGNANT_GOAL')
            .priority,
        WeeklyReviewPriority.p0,
      );
    });

    test('near deadline + behind pace bumps to P0 with DEADLINE_PRESSURE', () {
      final r = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [],
        goals: [
          WeeklyGoalInput(
            id: 'g_dl',
            name: 'Submit paper',
            startProgress: 0.50,
            endProgress: 0.53,
            weeklyTargetDelta: 0.10,
            deadline: fixedNow.add(const Duration(days: 5)),
          ),
        ],
      );
      final item = r.items.firstWhere((it) => it.id == 'g_dl');
      expect(item.priority, WeeklyReviewPriority.p0);
      expect(item.reasons, contains('DEADLINE_PRESSURE'));
    });

    test('OVER_DELIVERED appetite shifts next-week habit target', () {
      const habit = WeeklyHabitInput(
        id: 'walk',
        name: 'Walk',
        weeklyTarget: 5,
        completions: 8,
      );
      final balanced = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [habit],
        goals: const [],
      );
      final cautious = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [habit],
        goals: const [],
        riskAppetite: WeeklyReviewRiskAppetite.cautious,
      );
      final aggressive = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [habit],
        goals: const [],
        riskAppetite: WeeklyReviewRiskAppetite.aggressive,
      );
      expect(
        balanced.nextWeekPlan
            .firstWhere((c) => c.id == 'walk')
            .suggestedWeeklyTarget,
        6,
      );
      expect(
        cautious.nextWeekPlan
            .firstWhere((c) => c.id == 'walk')
            .suggestedWeeklyTarget,
        5,
      );
      expect(
        aggressive.nextWeekPlan
            .firstWhere((c) => c.id == 'walk')
            .suggestedWeeklyTarget,
        7,
      );
    });

    test('MISSED habit shrinks target to max(1, target-2)', () {
      final r = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [
          WeeklyHabitInput(
            id: 'jr',
            name: 'Journal',
            weeklyTarget: 5,
            completions: 1,
          ),
        ],
        goals: const [],
      );
      final c = r.nextWeekPlan.firstWhere((c) => c.id == 'jr');
      expect(c.suggestedWeeklyTarget, 3);
      expect(c.rationale.toLowerCase(), contains('shrink'));
    });

    test('risk appetite monotonicity (cautious <= balanced <= aggressive)', () {
      const habits = [
        WeeklyHabitInput(
          id: 'h',
          name: 'H',
          weeklyTarget: 5,
          completions: 4,
        ),
      ];
      const goals = [
        WeeklyGoalInput(
          id: 'g',
          name: 'G',
          startProgress: 0.4,
          endProgress: 0.45,
          weeklyTargetDelta: 0.10,
        ),
      ];
      final c = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: habits,
        goals: goals,
        riskAppetite: WeeklyReviewRiskAppetite.cautious,
      );
      final b = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: habits,
        goals: goals,
        riskAppetite: WeeklyReviewRiskAppetite.balanced,
      );
      final a = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: habits,
        goals: goals,
        riskAppetite: WeeklyReviewRiskAppetite.aggressive,
      );
      expect(c.weekScore, lessThanOrEqualTo(b.weekScore));
      expect(b.weekScore, lessThanOrEqualTo(a.weekScore));
    });

    test('aggressive trims WEEKLY_REVIEW_HEALTHY when P0 present', () {
      final r = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [
          WeeklyHabitInput(
            id: 'sleep',
            name: 'Sleep',
            weeklyTarget: 7,
            completions: 0,
            isKeystone: true,
          ),
        ],
        goals: const [],
        riskAppetite: WeeklyReviewRiskAppetite.aggressive,
      );
      expect(
        r.playbook.any((a) => a.code == 'WEEKLY_REVIEW_HEALTHY'),
        isFalse,
      );
    });

    test('cautious appends SCHEDULE_FOLLOWUP_REVIEW at grade C/D/F', () {
      final r = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [
          WeeklyHabitInput(
            id: 'a',
            name: 'A',
            weeklyTarget: 5,
            completions: 2,
          ),
        ],
        goals: const [],
        riskAppetite: WeeklyReviewRiskAppetite.cautious,
      );
      expect(const {'C', 'D', 'F'}.contains(r.grade), isTrue);
      expect(
        r.playbook.any((a) => a.code == 'SCHEDULE_FOLLOWUP_REVIEW'),
        isTrue,
      );
    });

    test('category imbalance insight at 60% threshold', () {
      final r = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [
          WeeklyHabitInput(
            id: 'h1',
            name: 'H1',
            weeklyTarget: 5,
            completions: 5,
            category: 'health',
          ),
          WeeklyHabitInput(
            id: 'h2',
            name: 'H2',
            weeklyTarget: 5,
            completions: 5,
            category: 'health',
          ),
          WeeklyHabitInput(
            id: 'h3',
            name: 'H3',
            weeklyTarget: 5,
            completions: 5,
            category: 'health',
          ),
          WeeklyHabitInput(
            id: 'h4',
            name: 'H4',
            weeklyTarget: 5,
            completions: 5,
            category: 'work',
          ),
        ],
        goals: const [],
      );
      expect(r.insights, contains('CATEGORY_IMBALANCE'));
    });

    test('deep work shortfall insight only fires when events present', () {
      final noEvents = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [
          WeeklyHabitInput(
            id: 'h',
            name: 'H',
            weeklyTarget: 5,
            completions: 5,
          ),
        ],
        goals: const [],
      );
      expect(noEvents.insights, isNot(contains('DEEP_WORK_SHORTFALL')));

      final withEvents = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [
          WeeklyHabitInput(
            id: 'h',
            name: 'H',
            weeklyTarget: 5,
            completions: 5,
          ),
        ],
        goals: const [],
        events: [
          WeeklyEventInput(
            id: 'm1',
            title: 'standup',
            when: fixedNow,
            duration: const Duration(minutes: 60),
            kind: 'meeting',
            completed: true,
          ),
          WeeklyEventInput(
            id: 'm2',
            title: 'review',
            when: fixedNow,
            duration: const Duration(minutes: 90),
            kind: 'meeting',
            completed: true,
          ),
        ],
      );
      expect(withEvents.insights, contains('DEEP_WORK_SHORTFALL'));
    });

    test('JSON byte determinism with fixed now', () {
      final habits = const [
        WeeklyHabitInput(
          id: 'h',
          name: 'H',
          weeklyTarget: 5,
          completions: 3,
          category: 'health',
        ),
      ];
      final a = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: habits,
        goals: const [],
      );
      final b = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: habits,
        goals: const [],
      );
      expect(a.toJson(), b.toJson());
    });

    test('markdown contains all required section headers', () {
      final r = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [
          WeeklyHabitInput(
            id: 'h',
            name: 'H',
            weeklyTarget: 5,
            completions: 5,
          ),
        ],
        goals: const [],
      );
      final md = r.toMarkdown();
      expect(md, contains('## Summary'));
      expect(md, contains('## Items'));
      expect(md, contains('## Next week plan'));
      expect(md, contains('## Playbook'));
      expect(md, contains('## Insights'));
    });

    test('items sorted by priority then progressScore asc', () {
      final r = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [
          WeeklyHabitInput(
            id: 'a',
            name: 'A',
            weeklyTarget: 5,
            completions: 5,
          ),
          WeeklyHabitInput(
            id: 'b',
            name: 'B',
            weeklyTarget: 5,
            completions: 1,
          ),
          WeeklyHabitInput(
            id: 'c',
            name: 'C',
            weeklyTarget: 5,
            completions: 3,
          ),
        ],
        goals: const [],
      );
      for (var i = 1; i < r.items.length; i++) {
        final prev = r.items[i - 1];
        final cur = r.items[i];
        final priCmp = prev.priority.index.compareTo(cur.priority.index);
        expect(priCmp <= 0, isTrue);
        if (priCmp == 0) {
          expect(prev.progressScore <= cur.progressScore, isTrue);
        }
      }
    });

    test('crashAndReset forces grade F and RECOVERY_WEEK_NEEDED', () {
      final r = build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: const [
          WeeklyHabitInput(
            id: 'sleep',
            name: 'Sleep',
            weeklyTarget: 7,
            completions: 0,
            isKeystone: true,
          ),
          WeeklyHabitInput(
            id: 'jr',
            name: 'Journal',
            weeklyTarget: 5,
            completions: 0,
          ),
        ],
        goals: const [],
      );
      expect(r.verdict, WeeklyReviewVerdict.crashAndReset);
      expect(r.grade, 'F');
      expect(r.insights, contains('RECOVERY_WEEK_NEEDED'));
    });

    test('does not mutate input lists', () {
      final habits = <WeeklyHabitInput>[
        const WeeklyHabitInput(
          id: 'h',
          name: 'H',
          weeklyTarget: 5,
          completions: 3,
        ),
      ];
      final goals = <WeeklyGoalInput>[
        const WeeklyGoalInput(
          id: 'g',
          name: 'G',
          startProgress: 0.1,
          endProgress: 0.15,
          weeklyTargetDelta: 0.10,
        ),
      ];
      final beforeH = habits.length;
      final beforeG = goals.length;
      build().synthesize(
        weekStart: weekStart,
        weekEnd: weekEnd,
        habits: habits,
        goals: goals,
      );
      expect(habits.length, beforeH);
      expect(goals.length, beforeG);
    });
  });
}
