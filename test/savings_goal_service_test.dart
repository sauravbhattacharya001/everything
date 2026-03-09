import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/savings_goal_service.dart';
import 'package:everything/models/savings_goal.dart';

void main() {
  late SavingsGoalService service;

  setUp(() {
    service = SavingsGoalService();
  });

  group('SavingsGoal model', () {
    test('progressPercent clamps to 0-1', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Test',
        targetAmount: 100,
        contributions: [
          SavingsContribution(id: 'c1', amount: 150),
        ],
      );
      expect(goal.progressPercent, 1.0);
      expect(goal.isComplete, true);
      expect(goal.remainingAmount, 0.0);
    });

    test('zero target gives 0 progress', () {
      final goal = SavingsGoal(id: '1', name: 'Test', targetAmount: 0);
      expect(goal.progressPercent, 0.0);
    });

    test('daysRemaining returns null without deadline', () {
      final goal = SavingsGoal(id: '1', name: 'Test', targetAmount: 100);
      expect(goal.daysRemaining, isNull);
      expect(goal.isOnTrack, isNull);
    });

    test('serialization roundtrip', () {
      final goal = SavingsGoal(
        id: 'g1',
        name: 'Vacation',
        emoji: '✈️',
        targetAmount: 2000,
        category: SavingsGoalCategory.travel,
        priority: SavingsGoalPriority.high,
        contributions: [
          SavingsContribution(id: 'c1', amount: 500, note: 'bonus'),
        ],
      );
      final json = goal.toJson();
      final restored = SavingsGoal.fromJson(json);
      expect(restored.id, 'g1');
      expect(restored.name, 'Vacation');
      expect(restored.emoji, '✈️');
      expect(restored.targetAmount, 2000);
      expect(restored.category, SavingsGoalCategory.travel);
      expect(restored.priority, SavingsGoalPriority.high);
      expect(restored.contributions.length, 1);
      expect(restored.contributions.first.note, 'bonus');
    });

    test('copyWith preserves unmodified fields', () {
      final goal = SavingsGoal(
        id: 'g1',
        name: 'Fund',
        targetAmount: 1000,
        category: SavingsGoalCategory.emergency,
      );
      final updated = goal.copyWith(name: 'Safety Net');
      expect(updated.id, 'g1');
      expect(updated.name, 'Safety Net');
      expect(updated.targetAmount, 1000);
      expect(updated.category, SavingsGoalCategory.emergency);
    });
  });

  group('addGoal', () {
    test('creates goal with correct properties', () {
      final goal = service.addGoal(
        name: 'Emergency Fund',
        targetAmount: 5000,
        category: SavingsGoalCategory.emergency,
        priority: SavingsGoalPriority.high,
      );
      expect(goal.name, 'Emergency Fund');
      expect(goal.targetAmount, 5000);
      expect(service.goals.length, 1);
    });

    test('trims whitespace from name', () {
      final goal = service.addGoal(name: '  Vacation  ', targetAmount: 2000);
      expect(goal.name, 'Vacation');
    });

    test('throws on empty name', () {
      expect(
        () => service.addGoal(name: '', targetAmount: 1000),
        throwsArgumentError,
      );
    });

    test('throws on zero target', () {
      expect(
        () => service.addGoal(name: 'Test', targetAmount: 0),
        throwsArgumentError,
      );
    });

    test('throws on negative target', () {
      expect(
        () => service.addGoal(name: 'Test', targetAmount: -100),
        throwsArgumentError,
      );
    });
  });

  group('updateGoal', () {
    test('updates existing goal', () {
      final goal = service.addGoal(name: 'Fund', targetAmount: 1000);
      final updated = service.updateGoal(goal.id, name: 'Big Fund');
      expect(updated?.name, 'Big Fund');
      expect(updated?.targetAmount, 1000);
    });

    test('returns null for unknown id', () {
      expect(service.updateGoal('nope', name: 'X'), isNull);
    });

    test('throws on empty name update', () {
      final goal = service.addGoal(name: 'Fund', targetAmount: 1000);
      expect(
        () => service.updateGoal(goal.id, name: '  '),
        throwsArgumentError,
      );
    });
  });

  group('removeGoal', () {
    test('removes existing goal', () {
      final goal = service.addGoal(name: 'X', targetAmount: 100);
      service.removeGoal(goal.id);
      expect(service.goals, isEmpty);
    });
  });

  group('toggleArchive', () {
    test('archives and unarchives', () {
      final goal = service.addGoal(name: 'X', targetAmount: 100);
      expect(goal.isArchived, false);

      final archived = service.toggleArchive(goal.id);
      expect(archived?.isArchived, true);
      expect(service.activeGoals, isEmpty);
      expect(service.archivedGoals.length, 1);

      final unarchived = service.toggleArchive(goal.id);
      expect(unarchived?.isArchived, false);
    });

    test('returns null for unknown id', () {
      expect(service.toggleArchive('nope'), isNull);
    });
  });

  group('contributions', () {
    test('addContribution increases savedAmount', () {
      final goal = service.addGoal(name: 'X', targetAmount: 1000);
      service.addContribution(goal.id, amount: 100, note: 'paycheck');
      service.addContribution(goal.id, amount: 200);

      final updated = service.getGoal(goal.id)!;
      expect(updated.savedAmount, 300);
      expect(updated.contributions.length, 2);
      expect(updated.contributions.first.note, 'paycheck');
    });

    test('returns null for unknown goal', () {
      expect(service.addContribution('nope', amount: 100), isNull);
    });

    test('throws on zero amount', () {
      final goal = service.addGoal(name: 'X', targetAmount: 100);
      expect(
        () => service.addContribution(goal.id, amount: 0),
        throwsArgumentError,
      );
    });

    test('removeContribution works', () {
      final goal = service.addGoal(name: 'X', targetAmount: 1000);
      final c = service.addContribution(goal.id, amount: 100)!;
      expect(service.removeContribution(goal.id, c.id), true);
      expect(service.getGoal(goal.id)!.contributions, isEmpty);
    });

    test('removeContribution returns false for unknown', () {
      final goal = service.addGoal(name: 'X', targetAmount: 100);
      expect(service.removeContribution(goal.id, 'nope'), false);
    });
  });

  group('analytics', () {
    test('totalSaved and totalTarget aggregate active goals', () {
      service.addGoal(name: 'A', targetAmount: 1000);
      service.addGoal(name: 'B', targetAmount: 2000);
      service.addContribution(service.goals[0].id, amount: 300);
      service.addContribution(service.goals[1].id, amount: 500);

      expect(service.totalSaved, 800);
      expect(service.totalTarget, 3000);
    });

    test('archived goals excluded from totals', () {
      final goal = service.addGoal(name: 'A', targetAmount: 1000);
      service.addContribution(goal.id, amount: 300);
      service.toggleArchive(goal.id);

      expect(service.totalSaved, 0);
      expect(service.totalTarget, 0);
    });

    test('overallProgress correct', () {
      service.addGoal(name: 'A', targetAmount: 100);
      service.addContribution(service.goals[0].id, amount: 50);
      expect(service.overallProgress, 0.5);
    });

    test('overallProgress returns 0 with no goals', () {
      expect(service.overallProgress, 0.0);
    });

    test('behindSchedule returns goals past deadline pace', () {
      final goal = service.addGoal(
        name: 'Urgent',
        targetAmount: 10000,
        deadline: DateTime.now().add(const Duration(days: 1)),
      );
      // No contributions — way behind
      expect(service.behindSchedule.length, 1);
    });

    test('prioritized sorts by priority then progress', () {
      service.addGoal(
          name: 'Low', targetAmount: 100, priority: SavingsGoalPriority.low);
      service.addGoal(
          name: 'High',
          targetAmount: 100,
          priority: SavingsGoalPriority.high);
      service.addGoal(
          name: 'Med',
          targetAmount: 100,
          priority: SavingsGoalPriority.medium);

      final sorted = service.prioritized;
      expect(sorted[0].name, 'High');
      expect(sorted[1].name, 'Med');
      expect(sorted[2].name, 'Low');
    });

    test('completedGoals tracks fully funded goals', () {
      final goal = service.addGoal(name: 'Done', targetAmount: 100);
      service.addContribution(goal.id, amount: 100);
      expect(service.completedGoals.length, 1);
    });
  });

  group('monthlySavings', () {
    test('sums contributions for a given month', () {
      final goal = service.addGoal(name: 'X', targetAmount: 1000);
      final now = DateTime.now();
      service.addContribution(goal.id,
          amount: 100, date: DateTime(now.year, now.month, 1));
      service.addContribution(goal.id,
          amount: 200, date: DateTime(now.year, now.month, 15));
      // Different month
      service.addContribution(goal.id,
          amount: 50, date: DateTime(now.year, now.month - 1, 10));

      expect(service.monthlySavings(now.year, now.month), 300);
    });
  });

  group('savingsHistory', () {
    test('returns correct number of months', () {
      final history = service.savingsHistory(months: 6);
      expect(history.length, 6);
    });
  });

  group('categoryBreakdown', () {
    test('groups goals by category', () {
      service.addGoal(
          name: 'Trip', targetAmount: 2000, category: SavingsGoalCategory.travel);
      service.addGoal(
          name: 'Cruise',
          targetAmount: 3000,
          category: SavingsGoalCategory.travel);
      service.addGoal(
          name: 'Fund',
          targetAmount: 5000,
          category: SavingsGoalCategory.emergency);

      final breakdown = service.categoryBreakdown;
      expect(breakdown.length, 2);
      expect(breakdown[SavingsGoalCategory.travel]!.goalCount, 2);
      expect(breakdown[SavingsGoalCategory.travel]!.totalTarget, 5000);
    });
  });

  group('insights', () {
    test('empty state recommendation', () {
      final insights = service.insights;
      expect(insights.activeGoalCount, 0);
      expect(insights.recommendation, contains('first savings goal'));
    });

    test('behind schedule recommendation', () {
      service.addGoal(
        name: 'Urgent',
        targetAmount: 10000,
        deadline: DateTime.now().add(const Duration(days: 1)),
      );
      expect(service.insights.recommendation, contains('behind schedule'));
    });

    test('all completed recommendation', () {
      final goal = service.addGoal(name: 'Done', targetAmount: 50);
      service.addContribution(goal.id, amount: 50);
      expect(service.insights.recommendation, contains('completed'));
    });
  });

  group('serialization', () {
    test('export and import roundtrip', () {
      service.addGoal(name: 'A', targetAmount: 1000);
      service.addGoal(
          name: 'B',
          targetAmount: 2000,
          category: SavingsGoalCategory.travel);
      service.addContribution(service.goals[0].id, amount: 300);

      final json = service.exportJson();

      final service2 = SavingsGoalService();
      service2.importJson(json);

      expect(service2.goals.length, 2);
      expect(service2.goals[0].savedAmount, 300);
      expect(service2.goals[1].category, SavingsGoalCategory.travel);
    });
  });

  group('getGoal', () {
    test('returns null for unknown id', () {
      expect(service.getGoal('nope'), isNull);
    });

    test('finds existing goal', () {
      final goal = service.addGoal(name: 'X', targetAmount: 100);
      expect(service.getGoal(goal.id)?.name, 'X');
    });
  });

  group('SavingsGoalCategory extensions', () {
    test('all categories have labels', () {
      for (final cat in SavingsGoalCategory.values) {
        expect(cat.label, isNotEmpty);
        expect(cat.emoji, isNotEmpty);
      }
    });
  });

  group('SavingsGoalPriority extensions', () {
    test('all priorities have labels', () {
      for (final p in SavingsGoalPriority.values) {
        expect(p.label, isNotEmpty);
      }
    });
  });
}
