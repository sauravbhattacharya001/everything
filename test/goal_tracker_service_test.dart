import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/goal.dart';
import 'package:everything/core/services/goal_tracker_service.dart';

/// Helper to create a simple test goal.
Goal _makeGoal({
  String id = 'g1',
  String title = 'Test Goal',
  GoalCategory category = GoalCategory.personal,
  DateTime? deadline,
  int progress = 0,
  bool isCompleted = false,
  bool isArchived = false,
  List<Milestone> milestones = const [],
}) {
  return Goal(
    id: id,
    title: title,
    category: category,
    createdAt: DateTime(2026, 1, 1),
    deadline: deadline,
    progress: progress,
    isCompleted: isCompleted,
    isArchived: isArchived,
    milestones: milestones,
  );
}

void main() {
  group('GoalTrackerService', () {
    late GoalTrackerService service;

    setUp(() {
      service = GoalTrackerService();
    });

    test('starts empty', () {
      expect(service.allGoals, isEmpty);
      expect(service.activeGoals, isEmpty);
    });

    test('addGoal adds to list', () {
      service.addGoal(_makeGoal());
      expect(service.allGoals, hasLength(1));
      expect(service.allGoals.first.title, 'Test Goal');
    });

    test('addGoal rejects duplicate id', () {
      service.addGoal(_makeGoal(id: 'g1'));
      expect(
        () => service.addGoal(_makeGoal(id: 'g1', title: 'Duplicate')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deleteGoal removes by id', () {
      service.addGoal(_makeGoal(id: 'g1'));
      service.addGoal(_makeGoal(id: 'g2', title: 'Second'));
      service.deleteGoal('g1');
      expect(service.allGoals, hasLength(1));
      expect(service.allGoals.first.id, 'g2');
    });

    test('deleteGoal no-op for unknown id', () {
      service.addGoal(_makeGoal());
      service.deleteGoal('nonexistent');
      expect(service.allGoals, hasLength(1));
    });

    test('updateGoal replaces goal', () {
      service.addGoal(_makeGoal(id: 'g1', title: 'Original'));
      service.updateGoal(_makeGoal(id: 'g1', title: 'Updated'));
      expect(service.allGoals.first.title, 'Updated');
    });

    test('updateGoal throws for unknown id', () {
      expect(
        () => service.updateGoal(_makeGoal(id: 'missing')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('archiveGoal sets isArchived', () {
      service.addGoal(_makeGoal(id: 'g1'));
      service.archiveGoal('g1');
      expect(service.allGoals.first.isArchived, true);
      expect(service.activeGoals, isEmpty); // archived not in active
    });

    test('completeGoal sets completed and progress 100', () {
      service.addGoal(_makeGoal(id: 'g1'));
      service.completeGoal('g1');
      expect(service.allGoals.first.isCompleted, true);
      expect(service.allGoals.first.progress, 100);
    });
  });

  group('GoalTrackerService filters', () {
    late GoalTrackerService service;

    setUp(() {
      service = GoalTrackerService();
      service.addGoal(_makeGoal(id: 'active', progress: 50));
      service.addGoal(_makeGoal(id: 'done', isCompleted: true));
      service.addGoal(_makeGoal(id: 'archived', isArchived: true));
      service.addGoal(_makeGoal(
        id: 'overdue',
        deadline: DateTime.now().subtract(const Duration(days: 5)),
      ));
    });

    test('activeGoals excludes archived', () {
      final active = service.activeGoals;
      expect(active.map((g) => g.id), isNot(contains('archived')));
    });

    test('completedGoals returns only completed non-archived', () {
      final completed = service.completedGoals;
      expect(completed, hasLength(1));
      expect(completed.first.id, 'done');
    });

    test('inProgressGoals excludes completed and archived', () {
      final inProgress = service.inProgressGoals;
      expect(inProgress.map((g) => g.id), isNot(contains('done')));
      expect(inProgress.map((g) => g.id), isNot(contains('archived')));
    });

    test('overdueGoals returns only overdue in-progress', () {
      final overdue = service.overdueGoals;
      expect(overdue, hasLength(1));
      expect(overdue.first.id, 'overdue');
    });
  });

  group('GoalTrackerService milestones', () {
    late GoalTrackerService service;

    setUp(() {
      service = GoalTrackerService();
      service.addGoal(_makeGoal(
        id: 'g1',
        milestones: [
          const Milestone(id: 'm1', title: 'Step 1'),
          const Milestone(id: 'm2', title: 'Step 2'),
        ],
      ));
    });

    test('addMilestone appends to goal', () {
      service.addMilestone('g1', const Milestone(id: 'm3', title: 'Step 3'));
      expect(service.allGoals.first.milestones, hasLength(3));
    });

    test('removeMilestone removes by id', () {
      service.removeMilestone('g1', 'm1');
      final milestones = service.allGoals.first.milestones;
      expect(milestones, hasLength(1));
      expect(milestones.first.id, 'm2');
    });

    test('toggleMilestone marks complete', () {
      service.toggleMilestone('g1', 'm1');
      final m = service.allGoals.first.milestones.firstWhere((m) => m.id == 'm1');
      expect(m.isCompleted, true);
      expect(m.completedAt, isNotNull);
    });

    test('toggleMilestone again marks incomplete', () {
      service.toggleMilestone('g1', 'm1');
      service.toggleMilestone('g1', 'm1');
      final m = service.allGoals.first.milestones.firstWhere((m) => m.id == 'm1');
      expect(m.isCompleted, false);
    });

    test('completing all milestones auto-completes goal', () {
      service.toggleMilestone('g1', 'm1');
      service.toggleMilestone('g1', 'm2');
      final goal = service.allGoals.first;
      expect(goal.isCompleted, true);
      expect(goal.progress, 100);
    });
  });

  group('GoalTrackerService progress', () {
    late GoalTrackerService service;

    setUp(() {
      service = GoalTrackerService();
      service.addGoal(_makeGoal(id: 'g1'));
    });

    test('updateProgress sets value', () {
      service.updateProgress('g1', 75);
      expect(service.allGoals.first.progress, 75);
    });

    test('updateProgress clamps to 0-100', () {
      service.updateProgress('g1', 150);
      expect(service.allGoals.first.progress, 100);
      service.updateProgress('g1', -10);
      expect(service.allGoals.first.progress, 0);
    });

    test('updateProgress to 100 marks completed', () {
      service.updateProgress('g1', 100);
      expect(service.allGoals.first.isCompleted, true);
    });
  });

  group('GoalTrackerService getSummary', () {
    test('returns zeros for empty service', () {
      final service = GoalTrackerService();
      final summary = service.getSummary();
      expect(summary.totalGoals, 0);
      expect(summary.completedGoals, 0);
      expect(summary.activeGoals, 0);
      expect(summary.overdueGoals, 0);
      expect(summary.averageProgress, 0.0);
    });

    test('computes correct summary', () {
      final service = GoalTrackerService();
      service.addGoal(_makeGoal(id: 'a', progress: 50, category: GoalCategory.health));
      service.addGoal(_makeGoal(id: 'b', isCompleted: true, category: GoalCategory.health));
      service.addGoal(_makeGoal(
        id: 'c',
        category: GoalCategory.career,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      ));

      final summary = service.getSummary();
      expect(summary.totalGoals, 3);
      expect(summary.completedGoals, 1);
      expect(summary.activeGoals, 2);
      expect(summary.overdueGoals, 1);
      expect(summary.byCategory[GoalCategory.health], 2);
      expect(summary.byCategory[GoalCategory.career], 1);
    });
  });

  group('GoalTrackerService getByUrgency', () {
    test('overdue goals come first', () {
      final service = GoalTrackerService();
      service.addGoal(_makeGoal(
        id: 'future',
        deadline: DateTime.now().add(const Duration(days: 30)),
      ));
      service.addGoal(_makeGoal(
        id: 'overdue',
        deadline: DateTime.now().subtract(const Duration(days: 5)),
      ));

      final sorted = service.getByUrgency();
      expect(sorted.first.id, 'overdue');
    });

    test('closer deadlines come before farther ones', () {
      final service = GoalTrackerService();
      service.addGoal(_makeGoal(
        id: 'far',
        deadline: DateTime.now().add(const Duration(days: 30)),
      ));
      service.addGoal(_makeGoal(
        id: 'near',
        deadline: DateTime.now().add(const Duration(days: 2)),
      ));

      final sorted = service.getByUrgency();
      expect(sorted.first.id, 'near');
    });

    test('goals without deadline come last', () {
      final service = GoalTrackerService();
      service.addGoal(_makeGoal(id: 'no-deadline'));
      service.addGoal(_makeGoal(
        id: 'has-deadline',
        deadline: DateTime.now().add(const Duration(days: 10)),
      ));

      final sorted = service.getByUrgency();
      expect(sorted.last.id, 'no-deadline');
    });
  });

  group('Goal model', () {
    test('effectiveProgress uses milestones when present', () {
      final goal = _makeGoal(
        milestones: [
          const Milestone(id: 'm1', title: 'A', isCompleted: true),
          const Milestone(id: 'm2', title: 'B', isCompleted: false),
        ],
      );
      expect(goal.effectiveProgress, 0.5);
    });

    test('effectiveProgress uses manual progress without milestones', () {
      final goal = _makeGoal(progress: 75);
      expect(goal.effectiveProgress, 0.75);
    });

    test('effectiveProgress is 1.0 when completed', () {
      final goal = _makeGoal(isCompleted: true, progress: 50);
      expect(goal.effectiveProgress, 1.0);
    });

    test('isOverdue is true when past deadline and not completed', () {
      final goal = _makeGoal(
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(goal.isOverdue, true);
    });

    test('isOverdue is false when completed', () {
      final goal = _makeGoal(
        deadline: DateTime.now().subtract(const Duration(days: 1)),
        isCompleted: true,
      );
      expect(goal.isOverdue, false);
    });

    test('isOverdue is false with no deadline', () {
      final goal = _makeGoal();
      expect(goal.isOverdue, false);
    });

    test('toJson and fromJson round-trip', () {
      final goal = _makeGoal(
        id: 'rt',
        title: 'Round Trip',
        category: GoalCategory.fitness,
        progress: 42,
        milestones: [
          const Milestone(id: 'm1', title: 'First'),
        ],
      );
      final json = goal.toJson();
      final restored = Goal.fromJson(json);
      expect(restored.id, 'rt');
      expect(restored.title, 'Round Trip');
      expect(restored.category, GoalCategory.fitness);
      expect(restored.progress, 42);
      expect(restored.milestones, hasLength(1));
      expect(restored.milestones.first.title, 'First');
    });
  });

  group('Milestone model', () {
    test('copyWith overrides fields', () {
      const m = Milestone(id: 'm1', title: 'Original');
      final m2 = m.copyWith(title: 'Updated', isCompleted: true);
      expect(m2.id, 'm1'); // id unchanged
      expect(m2.title, 'Updated');
      expect(m2.isCompleted, true);
    });

    test('copyWith clearCompletedAt', () {
      final m = Milestone(
        id: 'm1',
        title: 'Done',
        isCompleted: true,
        completedAt: DateTime(2026, 3, 8),
      );
      final m2 = m.copyWith(isCompleted: false, clearCompletedAt: true);
      expect(m2.isCompleted, false);
      expect(m2.completedAt, isNull);
    });

    test('toJson and fromJson round-trip', () {
      final m = Milestone(
        id: 'm1',
        title: 'Test',
        isCompleted: true,
        completedAt: DateTime(2026, 3, 8),
      );
      final json = m.toJson();
      final restored = Milestone.fromJson(json);
      expect(restored.id, 'm1');
      expect(restored.title, 'Test');
      expect(restored.isCompleted, true);
      expect(restored.completedAt, isNotNull);
    });
  });
}
