/// Goal Tracker Service — manage long-term goals with milestones,
/// progress tracking, deadlines, and category-based organization.

import '../../models/goal.dart';
import 'service_persistence.dart';

/// Summary stats for goal tracking.
class GoalSummary {
  final int totalGoals;
  final int completedGoals;
  final int activeGoals;
  final int overdueGoals;
  final double averageProgress;
  final Map<GoalCategory, int> byCategory;

  const GoalSummary({
    required this.totalGoals,
    required this.completedGoals,
    required this.activeGoals,
    required this.overdueGoals,
    required this.averageProgress,
    required this.byCategory,
  });
}

/// Main service for goal tracking.
class GoalTrackerService with ServicePersistence {
  final List<Goal> _goals;

  @override
  String get storageKey => 'goal_tracker_data';

  @override
  Map<String, dynamic> toStorageJson() => {
        'goals': _goals.map((g) => g.toJson()).toList(),
      };

  @override
  void fromStorageJson(Map<String, dynamic> json) {
    _goals.clear();
    if (json['goals'] != null) {
      _goals.addAll(
        (json['goals'] as List).map((g) => Goal.fromJson(g as Map<String, dynamic>)),
      );
    }
  }

  GoalTrackerService({List<Goal>? goals}) : _goals = goals ?? [];

  /// All non-archived goals.
  List<Goal> get activeGoals =>
      _goals.where((g) => !g.isArchived).toList();

  /// Completed goals.
  List<Goal> get completedGoals =>
      _goals.where((g) => g.isCompleted && !g.isArchived).toList();

  /// In-progress goals (not completed, not archived).
  List<Goal> get inProgressGoals =>
      _goals.where((g) => !g.isCompleted && !g.isArchived).toList();

  /// Overdue goals.
  List<Goal> get overdueGoals =>
      inProgressGoals.where((g) => g.isOverdue).toList();

  /// All goals including archived.
  List<Goal> get allGoals => List.unmodifiable(_goals);

  // ── Goal Management ───────────────────────────────────────────────

  void addGoal(Goal goal) {
    if (_goals.any((g) => g.id == goal.id)) {
      throw ArgumentError('Goal with id "${goal.id}" already exists');
    }
    _goals.add(goal);
  }

  void updateGoal(Goal updated) {
    final idx = _goals.indexWhere((g) => g.id == updated.id);
    if (idx == -1) throw ArgumentError('Goal "${updated.id}" not found');
    _goals[idx] = updated;
  }

  void deleteGoal(String goalId) {
    _goals.removeWhere((g) => g.id == goalId);
  }

  void archiveGoal(String goalId) {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    _goals[idx] = _goals[idx].copyWith(isArchived: true);
  }

  void completeGoal(String goalId) {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    _goals[idx] = _goals[idx].copyWith(isCompleted: true, progress: 100);
  }

  // ── Milestone Management ─────────────────────────────────────────

  void toggleMilestone(String goalId, String milestoneId) {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    final goal = _goals[idx];
    final milestones = goal.milestones.map((m) {
      if (m.id != milestoneId) return m;
      return m.copyWith(
        isCompleted: !m.isCompleted,
        completedAt: !m.isCompleted ? DateTime.now() : null,
        clearCompletedAt: m.isCompleted,
      );
    }).toList();

    // Auto-complete goal if all milestones done.
    final allDone = milestones.every((m) => m.isCompleted);
    _goals[idx] = goal.copyWith(
      milestones: milestones,
      isCompleted: allDone,
      progress: allDone ? 100 : goal.progress,
    );
  }

  void addMilestone(String goalId, Milestone milestone) {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    final milestones = List<Milestone>.from(_goals[idx].milestones)
      ..add(milestone);
    _goals[idx] = _goals[idx].copyWith(milestones: milestones);
  }

  void removeMilestone(String goalId, String milestoneId) {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    final milestones = _goals[idx]
        .milestones
        .where((m) => m.id != milestoneId)
        .toList();
    _goals[idx] = _goals[idx].copyWith(milestones: milestones);
  }

  // ── Progress ──────────────────────────────────────────────────────

  void updateProgress(String goalId, int progress) {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    final clamped = progress.clamp(0, 100);
    _goals[idx] = _goals[idx].copyWith(
      progress: clamped,
      isCompleted: clamped == 100,
    );
  }

  // ── Statistics ────────────────────────────────────────────────────

  GoalSummary getSummary() {
    final active = activeGoals;
    final completed = active.where((g) => g.isCompleted).length;
    final inProgress = active.where((g) => !g.isCompleted).length;
    final overdue = active.where((g) => g.isOverdue).length;

    final avgProgress = active.isEmpty
        ? 0.0
        : active.fold<double>(
                0.0, (sum, g) => sum + g.effectiveProgress) /
            active.length;

    final byCategory = <GoalCategory, int>{};
    for (final g in active) {
      byCategory[g.category] = (byCategory[g.category] ?? 0) + 1;
    }

    return GoalSummary(
      totalGoals: active.length,
      completedGoals: completed,
      activeGoals: inProgress,
      overdueGoals: overdue,
      averageProgress: avgProgress,
      byCategory: byCategory,
    );
  }

  /// Goals sorted by urgency: overdue first, then by closest deadline.
  List<Goal> getByUrgency() {
    final goals = inProgressGoals.toList();
    goals.sort((a, b) {
      // Overdue goals first
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      // Then by deadline (soonest first, no-deadline last)
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      if (a.deadline != null) return -1;
      if (b.deadline != null) return 1;
      return 0;
    });
    return goals;
  }
}
