import 'dart:convert';
import '../../models/savings_goal.dart';
import '../utils/id_utils.dart';

/// Service for managing savings goals with contributions, projections,
/// and progress tracking.
class SavingsGoalService {
  final List<SavingsGoal> _goals = [];

  List<SavingsGoal> get goals => List.unmodifiable(_goals);

  List<SavingsGoal> get activeGoals =>
      _goals.where((g) => !g.isArchived).toList();

  List<SavingsGoal> get archivedGoals =>
      _goals.where((g) => g.isArchived).toList();

  List<SavingsGoal> get completedGoals =>
      _goals.where((g) => g.isComplete && !g.isArchived).toList();

  // ── CRUD ──────────────────────────────────────────────────────────

  /// Add a new savings goal. Returns the created goal.
  SavingsGoal addGoal({
    required String name,
    required double targetAmount,
    String emoji = '🎯',
    DateTime? deadline,
    SavingsGoalCategory category = SavingsGoalCategory.general,
    SavingsGoalPriority priority = SavingsGoalPriority.medium,
  }) {
    if (name.trim().isEmpty) throw ArgumentError('Name cannot be empty');
    if (targetAmount <= 0) throw ArgumentError('Target must be positive');

    final goal = SavingsGoal(
      id: _generateId(),
      name: name.trim(),
      emoji: emoji,
      targetAmount: targetAmount,
      deadline: deadline,
      category: category,
      priority: priority,
    );
    _goals.add(goal);
    return goal;
  }

  /// Update an existing goal's properties.
  SavingsGoal? updateGoal(String goalId, {
    String? name,
    String? emoji,
    double? targetAmount,
    DateTime? deadline,
    SavingsGoalCategory? category,
    SavingsGoalPriority? priority,
  }) {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return null;

    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }
    if (targetAmount != null && targetAmount <= 0) {
      throw ArgumentError('Target must be positive');
    }

    _goals[idx] = _goals[idx].copyWith(
      name: name,
      emoji: emoji,
      targetAmount: targetAmount,
      deadline: deadline,
      category: category,
      priority: priority,
    );
    return _goals[idx];
  }

  /// Remove a goal entirely.
  bool removeGoal(String goalId) {
    final before = _goals.length;
    _goals.removeWhere((g) => g.id == goalId);
    return _goals.length < before;
  }

  /// Archive/unarchive a goal.
  SavingsGoal? toggleArchive(String goalId) {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return null;
    _goals[idx] = _goals[idx].copyWith(isArchived: !_goals[idx].isArchived);
    return _goals[idx];
  }

  /// Find a goal by ID.
  SavingsGoal? getGoal(String goalId) {
    try {
      return _goals.firstWhere((g) => g.id == goalId);
    } catch (_) {
      return null;
    }
  }

  // ── Contributions ─────────────────────────────────────────────────

  /// Add a contribution to a goal.
  SavingsContribution? addContribution(
    String goalId, {
    required double amount,
    DateTime? date,
    String? note,
  }) {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return null;
    if (amount <= 0) throw ArgumentError('Amount must be positive');

    final contribution = SavingsContribution(
      id: _generateId(),
      amount: amount,
      date: date,
      note: note,
    );

    final updatedContributions = [..._goals[idx].contributions, contribution];
    _goals[idx] = _goals[idx].copyWith(contributions: updatedContributions);
    return contribution;
  }

  /// Remove a contribution from a goal.
  bool removeContribution(String goalId, String contributionId) {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return false;

    final filtered = _goals[idx]
        .contributions
        .where((c) => c.id != contributionId)
        .toList();
    if (filtered.length == _goals[idx].contributions.length) return false;

    _goals[idx] = _goals[idx].copyWith(contributions: filtered);
    return true;
  }

  // ── Analytics ─────────────────────────────────────────────────────

  /// Get total saved across all active goals.
  double get totalSaved =>
      activeGoals.fold(0.0, (sum, g) => sum + g.savedAmount);

  /// Get total target across all active goals.
  double get totalTarget =>
      activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount);

  /// Overall progress percentage.
  double get overallProgress =>
      totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

  /// Goals that are behind schedule (have deadline and not on track).
  List<SavingsGoal> get behindSchedule =>
      activeGoals.where((g) => g.isOnTrack == false).toList();

  /// Goals sorted by priority (high first), then progress.
  List<SavingsGoal> get prioritized {
    final sorted = List<SavingsGoal>.from(activeGoals);
    sorted.sort((a, b) {
      final pCmp = b.priority.index.compareTo(a.priority.index);
      if (pCmp != 0) return pCmp;
      return b.progressPercent.compareTo(a.progressPercent);
    });
    return sorted;
  }

  /// Monthly savings rate across all goals for a given month.
  double monthlySavings(int year, int month) {
    double total = 0.0;
    for (final goal in _goals) {
      for (final c in goal.contributions) {
        if (c.date.year == year && c.date.month == month) {
          total += c.amount;
        }
      }
    }
    return total;
  }

  /// Get savings history as monthly totals for the last N months.
  List<MonthlySavingsPoint> savingsHistory({int months = 6}) {
    final now = DateTime.now();
    final points = <MonthlySavingsPoint>[];

    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final year = date.year;
      final month = date.month;
      points.add(MonthlySavingsPoint(
        year: year,
        month: month,
        amount: monthlySavings(year, month),
      ));
    }

    return points;
  }

  /// Per-category totals across active goals.
  Map<SavingsGoalCategory, CategorySavingsSummary> get categoryBreakdown {
    final map = <SavingsGoalCategory, CategorySavingsSummary>{};
    for (final goal in activeGoals) {
      final existing = map[goal.category];
      if (existing != null) {
        map[goal.category] = CategorySavingsSummary(
          category: goal.category,
          goalCount: existing.goalCount + 1,
          totalTarget: existing.totalTarget + goal.targetAmount,
          totalSaved: existing.totalSaved + goal.savedAmount,
        );
      } else {
        map[goal.category] = CategorySavingsSummary(
          category: goal.category,
          goalCount: 1,
          totalTarget: goal.targetAmount,
          totalSaved: goal.savedAmount,
        );
      }
    }
    return map;
  }

  /// Summary insights for the dashboard.
  SavingsInsights get insights {
    final active = activeGoals;
    final complete = completedGoals;
    final behind = behindSchedule;
    final history = savingsHistory(months: 3);
    final avgMonthly = history.isEmpty
        ? 0.0
        : history.fold(0.0, (s, p) => s + p.amount) / history.length;

    String recommendation;
    if (active.isEmpty) {
      recommendation = 'Set your first savings goal to start building wealth!';
    } else if (behind.isNotEmpty) {
      recommendation =
          '${behind.length} goal(s) behind schedule. Consider increasing contributions to "${behind.first.name}".';
    } else if (complete.isNotEmpty && active.length == complete.length) {
      recommendation =
          'All goals completed! 🎉 Time to set new savings targets.';
    } else {
      final closest = active
          .where((g) => !g.isComplete)
          .toList()
        ..sort((a, b) => b.progressPercent.compareTo(a.progressPercent));
      if (closest.isNotEmpty) {
        final pct = (closest.first.progressPercent * 100).round();
        recommendation =
            '"${closest.first.name}" is $pct% funded — almost there!';
      } else {
        recommendation = 'Keep saving consistently!';
      }
    }

    return SavingsInsights(
      activeGoalCount: active.length,
      completedGoalCount: complete.length,
      behindScheduleCount: behind.length,
      totalSaved: totalSaved,
      totalTarget: totalTarget,
      overallProgress: overallProgress,
      avgMonthlySavings: avgMonthly,
      recommendation: recommendation,
    );
  }

  // ── Serialization ─────────────────────────────────────────────────

  String exportJson() {
    return jsonEncode(_goals.map((g) => g.toJson()).toList());
  }

  void importJson(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    _goals.clear();
    for (final item in list) {
      _goals.add(SavingsGoal.fromJson(item as Map<String, dynamic>));
    }
  }

  void loadGoals(List<SavingsGoal> goals) {
    _goals.clear();
    _goals.addAll(goals);
  }

  // ── Private ───────────────────────────────────────────────────────

  String _generateId() => IdUtils.generateId();
}

/// Monthly savings data point.
class MonthlySavingsPoint {
  final int year;
  final int month;
  final double amount;

  MonthlySavingsPoint({
    required this.year,
    required this.month,
    required this.amount,
  });
}

/// Per-category savings summary.
class CategorySavingsSummary {
  final SavingsGoalCategory category;
  final int goalCount;
  final double totalTarget;
  final double totalSaved;

  double get progress =>
      totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

  CategorySavingsSummary({
    required this.category,
    required this.goalCount,
    required this.totalTarget,
    required this.totalSaved,
  });
}

/// Dashboard insights.
class SavingsInsights {
  final int activeGoalCount;
  final int completedGoalCount;
  final int behindScheduleCount;
  final double totalSaved;
  final double totalTarget;
  final double overallProgress;
  final double avgMonthlySavings;
  final String recommendation;

  SavingsInsights({
    required this.activeGoalCount,
    required this.completedGoalCount,
    required this.behindScheduleCount,
    required this.totalSaved,
    required this.totalTarget,
    required this.overallProgress,
    required this.avgMonthlySavings,
    required this.recommendation,
  });
}
