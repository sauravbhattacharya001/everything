import 'dart:convert';
import 'dart:math';
import '../../models/budget_entry.dart';
import '../../models/expense_entry.dart';

/// Service for managing monthly budgets with category allocations,
/// spending comparison, templates, and insights.
class BudgetPlannerService {
  final List<MonthlyBudget> _budgets = [];

  List<MonthlyBudget> get budgets => List.unmodifiable(_budgets);

  // ── CRUD ──────────────────────────────────────────────────────────

  /// Set (create or replace) a monthly budget.
  MonthlyBudget setBudget(MonthlyBudget budget) {
    final idx = _budgets.indexWhere(
        (b) => b.year == budget.year && b.month == budget.month);
    if (idx != -1) {
      _budgets[idx] = budget;
    } else {
      _budgets.add(budget);
    }
    return budget;
  }

  /// Get a budget for a specific month.
  MonthlyBudget? getBudget(int year, int month) {
    try {
      return _budgets.firstWhere(
          (b) => b.year == year && b.month == month);
    } catch (_) {
      return null;
    }
  }

  /// Get or create a budget for a specific month.
  MonthlyBudget getOrCreateBudget(int year, int month) {
    final existing = getBudget(year, month);
    if (existing != null) return existing;

    final budget = MonthlyBudget(
      id: _generateId(),
      year: year,
      month: month,
      allocations: [],
      createdAt: DateTime.now(),
    );
    _budgets.add(budget);
    return budget;
  }

  /// Delete a budget for a specific month.
  bool deleteBudget(int year, int month) {
    final len = _budgets.length;
    _budgets.removeWhere((b) => b.year == year && b.month == month);
    return _budgets.length < len;
  }

  // ── Spending Analysis ─────────────────────────────────────────────

  /// Get spending by category from expense entries for a given month.
  Map<ExpenseCategory, double> getSpendingByCategory(
    List<ExpenseEntry> entries,
    int year,
    int month,
  ) {
    final map = <ExpenseCategory, double>{};
    for (final entry in entries) {
      if (entry.timestamp.year == year &&
          entry.timestamp.month == month &&
          entry.isExpense) {
        map[entry.category] = (map[entry.category] ?? 0.0) + entry.amount;
      }
    }
    return map;
  }

  /// Compare budget allocations against actual spending.
  List<BudgetComparison> getBudgetComparison(
    MonthlyBudget budget,
    List<ExpenseEntry> entries,
  ) {
    final spending = getSpendingByCategory(entries, budget.year, budget.month);
    final comparisons = <BudgetComparison>[];

    for (final allocation in budget.allocations) {
      final spent = spending[allocation.category] ?? 0.0;
      comparisons.add(BudgetComparison(
        category: allocation.category,
        budgeted: allocation.budgetAmount,
        spent: spent,
        remaining: allocation.budgetAmount - spent,
        percentUsed:
            allocation.budgetAmount > 0 ? spent / allocation.budgetAmount : 0.0,
      ));
    }

    // Include categories with spending but no budget — use a Set for O(1)
    // lookups instead of O(n) .any() scan per spending entry.
    final budgetedCategories = <ExpenseCategory>{
      for (final a in budget.allocations) a.category,
    };
    for (final entry in spending.entries) {
      if (!budgetedCategories.contains(entry.key)) {
        comparisons.add(BudgetComparison(
          category: entry.key,
          budgeted: 0.0,
          spent: entry.value,
          remaining: -entry.value,
          percentUsed: double.infinity,
        ));
      }
    }

    return comparisons;
  }

  // ── Templates ─────────────────────────────────────────────────────

  /// Create a budget by copying the previous month's allocations.
  MonthlyBudget? createFromPrevious(int year, int month) {
    // Find the previous month
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final previous = getBudget(prevYear, prevMonth);
    if (previous == null) return null;

    final budget = MonthlyBudget(
      id: _generateId(),
      year: year,
      month: month,
      allocations: previous.allocations.map((a) => BudgetAllocation(
        id: _generateId(),
        category: a.category,
        budgetAmount: a.budgetAmount,
        notes: a.notes,
      )).toList(),
      createdAt: DateTime.now(),
    );
    return setBudget(budget);
  }

  /// Create a budget with an even split across non-income categories.
  MonthlyBudget createEvenSplit(int year, int month, double totalAmount) {
    final categories = ExpenseCategory.values
        .where((c) => c != ExpenseCategory.income)
        .toList();
    final perCategory = categories.isEmpty ? 0.0 : totalAmount / categories.length;

    final budget = MonthlyBudget(
      id: _generateId(),
      year: year,
      month: month,
      allocations: categories.map((c) => BudgetAllocation(
        id: _generateId(),
        category: c,
        budgetAmount: double.parse(perCategory.toStringAsFixed(2)),
      )).toList(),
      createdAt: DateTime.now(),
    );
    return setBudget(budget);
  }

  // ── Trends & Insights ─────────────────────────────────────────────

  /// Get monthly budget vs actual trend for the last N months.
  List<MonthlyTrendPoint> getMonthlyTrend(
    List<ExpenseEntry> entries, {
    int months = 6,
  }) {
    final now = DateTime.now();
    final points = <MonthlyTrendPoint>[];

    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final year = date.year;
      final month = date.month;
      final budget = getBudget(year, month);
      final spending = getSpendingByCategory(entries, year, month);
      final totalSpent = spending.values.fold(0.0, (s, v) => s + v);

      points.add(MonthlyTrendPoint(
        year: year,
        month: month,
        budgeted: budget?.totalBudget ?? 0.0,
        actual: totalSpent,
      ));
    }

    return points;
  }

  /// Get categories that are over budget.
  List<BudgetComparison> getOverspendingCategories(
    MonthlyBudget budget,
    List<ExpenseEntry> entries,
  ) {
    return getBudgetComparison(budget, entries)
        .where((c) => c.spent > c.budgeted && c.budgeted > 0)
        .toList()
      ..sort((a, b) => (b.spent - b.budgeted).compareTo(a.spent - a.budgeted));
  }

  /// Calculate savings rate: (income - expenses) / income.
  double getSavingsRate(List<ExpenseEntry> entries, int year, int month) {
    double income = 0.0;
    double expenses = 0.0;

    for (final entry in entries) {
      if (entry.timestamp.year == year && entry.timestamp.month == month) {
        if (entry.category.isIncome) {
          income += entry.amount;
        } else if (entry.isExpense) {
          expenses += entry.amount;
        }
      }
    }

    if (income <= 0) return 0.0;
    return ((income - expenses) / income).clamp(0.0, 1.0);
  }

  /// Budget adherence score from 0-100.
  /// 100 = all categories at or under budget, 0 = all way over.
  int getBudgetAdherenceScore(
    MonthlyBudget budget,
    List<ExpenseEntry> entries,
  ) {
    if (budget.allocations.isEmpty) return 100;

    final comparisons = getBudgetComparison(budget, entries);
    final budgetedComparisons =
        comparisons.where((c) => c.budgeted > 0).toList();
    if (budgetedComparisons.isEmpty) return 100;

    double totalScore = 0.0;
    for (final c in budgetedComparisons) {
      // Score per category: 100 if at/under budget, decreasing as overspent
      if (c.percentUsed <= 1.0) {
        totalScore += 100.0;
      } else {
        // Deduct points proportionally for overspending, min 0
        totalScore += (100.0 * (2.0 - c.percentUsed)).clamp(0.0, 100.0);
      }
    }

    return (totalScore / budgetedComparisons.length).round().clamp(0, 100);
  }

  /// Generate recommendations based on budget data.
  List<String> getRecommendations(
    MonthlyBudget budget,
    List<ExpenseEntry> entries,
  ) {
    final recommendations = <String>[];
    final comparisons = getBudgetComparison(budget, entries);
    final overspent = comparisons.where((c) => c.spent > c.budgeted && c.budgeted > 0).toList();
    final underspent = comparisons.where((c) => c.percentUsed < 0.5 && c.budgeted > 0).toList();

    if (overspent.isNotEmpty) {
      final worst = overspent.first;
      recommendations.add(
        '${worst.category.emoji} ${worst.category.label} is over budget by \$${(worst.spent - worst.budgeted).toStringAsFixed(0)}. Consider reducing spending.',
      );
    }

    if (underspent.isNotEmpty) {
      recommendations.add(
        '${underspent.length} category(s) under 50% used. Consider reallocating to overspent areas.',
      );
    }

    final savingsRate = getSavingsRate(entries, budget.year, budget.month);
    if (savingsRate > 0.2) {
      recommendations.add(
        'Great savings rate of ${(savingsRate * 100).round()}%! Keep it up.',
      );
    } else if (savingsRate > 0) {
      recommendations.add(
        'Savings rate is ${(savingsRate * 100).round()}%. Aim for 20%+ for financial health.',
      );
    }

    if (recommendations.isEmpty) {
      if (budget.allocations.isEmpty) {
        recommendations.add('Set up your first budget to start tracking spending!');
      } else {
        recommendations.add('Budget is on track. Keep monitoring your spending.');
      }
    }

    return recommendations;
  }

  // ── Demo Data ─────────────────────────────────────────────────────

  /// Generate demo budget data for the current and previous months.
  void generateDemoData() {
    final now = DateTime.now();

    // Current month budget
    final currentAllocations = <BudgetAllocation>[
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.food, budgetAmount: 500),
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.transport, budgetAmount: 200),
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.housing, budgetAmount: 1200),
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.utilities, budgetAmount: 150),
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.entertainment, budgetAmount: 100),
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.shopping, budgetAmount: 200),
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.health, budgetAmount: 100),
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.subscriptions, budgetAmount: 50),
    ];

    setBudget(MonthlyBudget(
      id: _generateId(),
      year: now.year,
      month: now.month,
      allocations: currentAllocations,
      createdAt: now,
    ));

    // Previous month budget
    final prevDate = DateTime(now.year, now.month - 1, 1);
    final prevAllocations = <BudgetAllocation>[
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.food, budgetAmount: 450),
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.transport, budgetAmount: 180),
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.housing, budgetAmount: 1200),
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.utilities, budgetAmount: 140),
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.entertainment, budgetAmount: 120),
      BudgetAllocation(id: _generateId(), category: ExpenseCategory.shopping, budgetAmount: 250),
    ];

    setBudget(MonthlyBudget(
      id: _generateId(),
      year: prevDate.year,
      month: prevDate.month,
      allocations: prevAllocations,
      createdAt: prevDate,
    ));
  }

  // ── Serialization ─────────────────────────────────────────────────

  /// Export all budgets as a JSON string.
  String exportToJson() => jsonEncode(
      _budgets.map((b) => b.toJson()).toList());

  /// Import budgets from a JSON string, replacing current state.
  void importFromJson(String json) {
    final data = jsonDecode(json) as List<dynamic>;
    _budgets.clear();
    _budgets.addAll(
        data.map((b) => MonthlyBudget.fromJson(b as Map<String, dynamic>)));
  }

  void loadBudgets(List<MonthlyBudget> budgets) {
    _budgets.clear();
    _budgets.addAll(budgets);
  }

  // ── Private ───────────────────────────────────────────────────────

  String _generateId() {
    final r = Random();
    return '${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(99999).toString().padLeft(5, '0')}';
  }
}

/// Budget vs actual comparison for a single category.
class BudgetComparison {
  final ExpenseCategory category;
  final double budgeted;
  final double spent;
  final double remaining;
  final double percentUsed;

  BudgetComparison({
    required this.category,
    required this.budgeted,
    required this.spent,
    required this.remaining,
    required this.percentUsed,
  });
}

/// Monthly trend data point for budget vs actual.
class MonthlyTrendPoint {
  final int year;
  final int month;
  final double budgeted;
  final double actual;

  MonthlyTrendPoint({
    required this.year,
    required this.month,
    required this.budgeted,
    required this.actual,
  });
}
