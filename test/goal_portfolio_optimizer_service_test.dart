import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/goal.dart';
import 'package:everything/core/services/goal_portfolio_optimizer_service.dart';

Goal _goal({
  String id = 'g',
  String title = 'Goal',
  GoalCategory category = GoalCategory.personal,
  DateTime? deadline,
  int progress = 0,
  bool isCompleted = false,
  bool isArchived = false,
  List<Milestone> milestones = const [],
  DateTime? createdAt,
}) {
  return Goal(
    id: id,
    title: title,
    category: category,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    deadline: deadline,
    progress: progress,
    isCompleted: isCompleted,
    isArchived: isArchived,
    milestones: milestones,
  );
}

void main() {
  final now = DateTime(2026, 5, 17);
  const service = GoalPortfolioOptimizerService();

  group('GoalPortfolioOptimizerService.optimise', () {
    test('returns empty-friendly plan when no active goals', () {
      final plan = service.optimise(const [], now: now);
      expect(plan.totalConsidered, 0);
      expect(plan.allocatedHours, 0);
      expect(plan.healthGrade, 'N/A');
      expect(plan.playbook, isNotEmpty);
    });

    test('skips completed and archived goals', () {
      final plan = service.optimise(
        [
          _goal(id: 'a', isCompleted: true),
          _goal(id: 'b', isArchived: true),
        ],
        now: now,
      );
      expect(plan.totalConsidered, 0);
    });

    test('focusNow picks the highest priority goal first', () {
      final urgent = _goal(
        id: 'urgent',
        title: 'Urgent career goal',
        category: GoalCategory.career,
        deadline: now.add(const Duration(days: 3)),
        progress: 40,
      );
      final relaxed = _goal(
        id: 'relaxed',
        title: 'Distant creative goal',
        category: GoalCategory.creative,
        deadline: now.add(const Duration(days: 200)),
        progress: 10,
      );
      final plan = service.optimise([relaxed, urgent], now: now);
      expect(plan.focusNow, isNotEmpty);
      expect(plan.focusNow.first.goal.id, 'urgent');
    });

    test('respects weekly budget — extras get deferred', () {
      final goals = List.generate(
        10,
        (i) => _goal(
          id: 'g$i',
          title: 'Goal $i',
          category: GoalCategory.education,
          deadline: now.add(Duration(days: 7 + i)),
          progress: 20,
        ),
      );
      final plan = service.optimise(
        goals,
        now: now,
        config: const PortfolioOptimizerConfig(
          weeklyBudgetHours: 4,
          maxHoursPerGoal: 2,
          minSliceHours: 0.5,
        ),
      );
      expect(plan.allocatedHours, lessThanOrEqualTo(4 + 1e-6));
      expect(plan.defer, isNotEmpty);
      // Some goals must be planned (focus or maintain).
      expect(plan.focusNow.length + plan.maintain.length, greaterThan(0));
    });

    test('overdue + untouched goal is flagged dropOrArchive', () {
      final stale = _goal(
        id: 'stale',
        title: 'Forgotten goal',
        deadline: now.subtract(const Duration(days: 200)),
        progress: 0,
      );
      final fresh = _goal(
        id: 'fresh',
        title: 'Live goal',
        deadline: now.add(const Duration(days: 10)),
        progress: 30,
      );
      final plan = service.optimise([stale, fresh], now: now);
      expect(plan.dropOrArchive.map((a) => a.goal.id), contains('stale'));
    });

    test('aggressive risk appetite trims per-goal slices vs cautious', () {
      final goals = [
        _goal(
          id: 'a',
          title: 'A',
          category: GoalCategory.health,
          deadline: now.add(const Duration(days: 14)),
          progress: 10,
        ),
        _goal(
          id: 'b',
          title: 'B',
          category: GoalCategory.career,
          deadline: now.add(const Duration(days: 21)),
          progress: 10,
        ),
      ];
      final cautious = service.optimise(
        goals,
        now: now,
        config: const PortfolioOptimizerConfig(
          weeklyBudgetHours: 40,
          maxHoursPerGoal: 40,
          riskAppetite: 'cautious',
        ),
      );
      final aggressive = service.optimise(
        goals,
        now: now,
        config: const PortfolioOptimizerConfig(
          weeklyBudgetHours: 40,
          maxHoursPerGoal: 40,
          riskAppetite: 'aggressive',
        ),
      );
      expect(cautious.allocatedHours, greaterThan(aggressive.allocatedHours));
    });

    test('custom effortEstimator influences slice sizing', () {
      final g = _goal(
        id: 'big',
        title: 'Big',
        category: GoalCategory.career,
        deadline: now.add(const Duration(days: 30)),
        progress: 10,
      );
      final plan = service.optimise(
        [g],
        now: now,
        effortEstimator: (_) => 50,
        config: const PortfolioOptimizerConfig(
          weeklyBudgetHours: 20,
          maxHoursPerGoal: 20,
        ),
      );
      expect(plan.focusNow.single.estimatedEffortHours, 50);
      expect(plan.focusNow.single.recommendedHours, greaterThan(0));
    });

    test('sacrifice list flags deferred near-term deadlines', () {
      final tight1 = _goal(
        id: 't1',
        title: 'Tight 1',
        category: GoalCategory.career,
        deadline: now.add(const Duration(days: 5)),
        progress: 10,
      );
      final tight2 = _goal(
        id: 't2',
        title: 'Tight 2',
        category: GoalCategory.career,
        deadline: now.add(const Duration(days: 6)),
        progress: 10,
      );
      final tight3 = _goal(
        id: 't3',
        title: 'Tight 3',
        category: GoalCategory.career,
        deadline: now.add(const Duration(days: 7)),
        progress: 10,
      );
      final plan = service.optimise(
        [tight1, tight2, tight3],
        now: now,
        config: const PortfolioOptimizerConfig(
          weeklyBudgetHours: 2,
          maxHoursPerGoal: 2,
          minSliceHours: 1.5,
        ),
      );
      // With a tiny budget, at least one near-term deadline must be sacrificed.
      expect(plan.defer.length + plan.dropOrArchive.length, greaterThan(0));
      expect(plan.sacrifices, isNotEmpty);
    });

    test('plan.all returns allocations in verdict order', () {
      final goals = [
        _goal(
          id: 'a',
          deadline: now.add(const Duration(days: 5)),
          progress: 20,
        ),
        _goal(
          id: 'b',
          deadline: now.subtract(const Duration(days: 300)),
          progress: 0,
        ),
      ];
      final plan = service.optimise(goals, now: now);
      expect(plan.all.length, plan.totalConsidered);
    });

    test('formatMarkdown contains key sections and budget line', () {
      final goals = [
        _goal(
          id: 'a',
          title: 'Health',
          category: GoalCategory.health,
          deadline: now.add(const Duration(days: 4)),
          progress: 50,
        ),
      ];
      final plan = service.optimise(goals, now: now);
      final md = service.formatMarkdown(plan);
      expect(md, contains('Weekly Goal Portfolio'));
      expect(md, contains('Budget'));
      expect(md, contains('Health'));
    });

    test('health grade is in expected alphabet', () {
      final goals = [
        _goal(
          id: 'a',
          category: GoalCategory.health,
          deadline: now.add(const Duration(days: 14)),
          progress: 30,
        ),
      ];
      final plan = service.optimise(goals, now: now);
      expect(['A', 'B', 'C', 'D', 'F', 'N/A'], contains(plan.healthGrade));
    });

    test('priority and roi are stable scalars', () {
      final g = _goal(
        id: 'x',
        category: GoalCategory.finance,
        deadline: now.add(const Duration(days: 20)),
        progress: 25,
      );
      final plan = service.optimise([g], now: now);
      final alloc = plan.all.single;
      expect(alloc.priorityScore, greaterThan(0));
      expect(alloc.priorityScore, lessThanOrEqualTo(100));
      expect(alloc.urgency, inInclusiveRange(0, 1));
      expect(alloc.value, inInclusiveRange(0, 1));
      expect(alloc.roi, greaterThan(0));
    });
  });
}
