import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/budget_planner_service.dart';
import 'package:everything/models/budget_entry.dart';
import 'package:everything/models/expense_entry.dart';

void main() {
  late BudgetPlannerService service;

  setUp(() {
    service = BudgetPlannerService();
  });

  // ── Model Tests ─────────────────────────────────────────────────────

  group('BudgetAllocation model', () {
    test('serialization roundtrip', () {
      const allocation = BudgetAllocation(
        id: 'a1',
        category: ExpenseCategory.food,
        budgetAmount: 500,
        notes: 'groceries + dining',
      );
      final json = allocation.toJson();
      final restored = BudgetAllocation.fromJson(json);
      expect(restored.id, 'a1');
      expect(restored.category, ExpenseCategory.food);
      expect(restored.budgetAmount, 500);
      expect(restored.notes, 'groceries + dining');
    });

    test('copyWith preserves unmodified fields', () {
      const allocation = BudgetAllocation(
        id: 'a1',
        category: ExpenseCategory.food,
        budgetAmount: 500,
      );
      final updated = allocation.copyWith(budgetAmount: 600);
      expect(updated.id, 'a1');
      expect(updated.category, ExpenseCategory.food);
      expect(updated.budgetAmount, 600);
      expect(updated.notes, isNull);
    });

    test('fromJson handles missing notes', () {
      final json = {
        'id': 'a1',
        'category': 'food',
        'budgetAmount': 300,
      };
      final allocation = BudgetAllocation.fromJson(json);
      expect(allocation.notes, isNull);
      expect(allocation.budgetAmount, 300);
    });

    test('fromJson handles unknown category', () {
      final json = {
        'id': 'a1',
        'category': 'unknown_cat',
        'budgetAmount': 100,
      };
      final allocation = BudgetAllocation.fromJson(json);
      expect(allocation.category, ExpenseCategory.other);
    });
  });

  group('MonthlyBudget model', () {
    test('totalBudget computes sum of allocations', () {
      final budget = MonthlyBudget(
        id: 'b1',
        year: 2024,
        month: 6,
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 500),
          BudgetAllocation(id: 'a2', category: ExpenseCategory.transport, budgetAmount: 200),
          BudgetAllocation(id: 'a3', category: ExpenseCategory.housing, budgetAmount: 1200),
        ],
        createdAt: DateTime(2024, 6, 1),
      );
      expect(budget.totalBudget, 1900);
    });

    test('totalBudget is 0 with no allocations', () {
      final budget = MonthlyBudget(
        id: 'b1',
        year: 2024,
        month: 6,
        createdAt: DateTime(2024, 6, 1),
      );
      expect(budget.totalBudget, 0.0);
    });

    test('serialization roundtrip', () {
      final budget = MonthlyBudget(
        id: 'b1',
        year: 2024,
        month: 6,
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 500),
        ],
        createdAt: DateTime(2024, 6, 1),
      );
      final json = budget.toJson();
      final restored = MonthlyBudget.fromJson(json);
      expect(restored.id, 'b1');
      expect(restored.year, 2024);
      expect(restored.month, 6);
      expect(restored.allocations.length, 1);
      expect(restored.allocations.first.category, ExpenseCategory.food);
      expect(restored.totalBudget, 500);
    });

    test('copyWith preserves unmodified fields', () {
      final budget = MonthlyBudget(
        id: 'b1',
        year: 2024,
        month: 6,
        createdAt: DateTime(2024, 6, 1),
      );
      final updated = budget.copyWith(month: 7);
      expect(updated.id, 'b1');
      expect(updated.year, 2024);
      expect(updated.month, 7);
    });
  });

  // ── Service CRUD Tests ──────────────────────────────────────────────

  group('setBudget / getBudget', () {
    test('sets and retrieves a budget', () {
      final budget = MonthlyBudget(
        id: 'b1',
        year: 2024,
        month: 6,
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 500),
        ],
        createdAt: DateTime(2024, 6, 1),
      );
      service.setBudget(budget);
      final retrieved = service.getBudget(2024, 6);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'b1');
      expect(retrieved.totalBudget, 500);
    });

    test('replaces existing budget for same month', () {
      final budget1 = MonthlyBudget(
        id: 'b1', year: 2024, month: 6, createdAt: DateTime(2024, 6, 1),
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 500),
        ],
      );
      final budget2 = MonthlyBudget(
        id: 'b2', year: 2024, month: 6, createdAt: DateTime(2024, 6, 15),
        allocations: const [
          BudgetAllocation(id: 'a2', category: ExpenseCategory.food, budgetAmount: 600),
        ],
      );
      service.setBudget(budget1);
      service.setBudget(budget2);
      expect(service.budgets.length, 1);
      expect(service.getBudget(2024, 6)!.id, 'b2');
    });

    test('returns null for nonexistent month', () {
      expect(service.getBudget(2024, 1), isNull);
    });
  });

  group('getOrCreateBudget', () {
    test('returns existing budget', () {
      final budget = MonthlyBudget(
        id: 'b1', year: 2024, month: 6, createdAt: DateTime(2024, 6, 1),
      );
      service.setBudget(budget);
      final result = service.getOrCreateBudget(2024, 6);
      expect(result.id, 'b1');
    });

    test('creates new budget if none exists', () {
      final result = service.getOrCreateBudget(2024, 7);
      expect(result.year, 2024);
      expect(result.month, 7);
      expect(result.allocations, isEmpty);
      expect(service.budgets.length, 1);
    });
  });

  group('deleteBudget', () {
    test('deletes existing budget', () {
      service.setBudget(MonthlyBudget(
        id: 'b1', year: 2024, month: 6, createdAt: DateTime(2024, 6, 1),
      ));
      expect(service.deleteBudget(2024, 6), true);
      expect(service.budgets, isEmpty);
    });

    test('returns false for nonexistent budget', () {
      expect(service.deleteBudget(2024, 1), false);
    });
  });

  // ── Spending Analysis ───────────────────────────────────────────────

  group('getSpendingByCategory', () {
    test('aggregates spending correctly', () {
      final entries = [
        ExpenseEntry(id: '1', timestamp: DateTime(2024, 6, 1), amount: 50, category: ExpenseCategory.food),
        ExpenseEntry(id: '2', timestamp: DateTime(2024, 6, 5), amount: 30, category: ExpenseCategory.food),
        ExpenseEntry(id: '3', timestamp: DateTime(2024, 6, 3), amount: 100, category: ExpenseCategory.transport),
        // Different month — should be excluded
        ExpenseEntry(id: '4', timestamp: DateTime(2024, 5, 15), amount: 200, category: ExpenseCategory.food),
        // Income — should be excluded
        ExpenseEntry(id: '5', timestamp: DateTime(2024, 6, 1), amount: 3000, category: ExpenseCategory.income),
      ];
      final spending = service.getSpendingByCategory(entries, 2024, 6);
      expect(spending[ExpenseCategory.food], 80);
      expect(spending[ExpenseCategory.transport], 100);
      expect(spending.containsKey(ExpenseCategory.income), false);
    });

    test('returns empty map for no matching entries', () {
      final spending = service.getSpendingByCategory([], 2024, 6);
      expect(spending, isEmpty);
    });
  });

  group('getBudgetComparison', () {
    test('computes comparison correctly', () {
      final budget = MonthlyBudget(
        id: 'b1', year: 2024, month: 6, createdAt: DateTime(2024, 6, 1),
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 500),
          BudgetAllocation(id: 'a2', category: ExpenseCategory.transport, budgetAmount: 200),
        ],
      );
      final entries = [
        ExpenseEntry(id: '1', timestamp: DateTime(2024, 6, 1), amount: 300, category: ExpenseCategory.food),
        ExpenseEntry(id: '2', timestamp: DateTime(2024, 6, 5), amount: 250, category: ExpenseCategory.transport),
      ];
      final comparisons = service.getBudgetComparison(budget, entries);
      expect(comparisons.length, 2);

      final food = comparisons.firstWhere((c) => c.category == ExpenseCategory.food);
      expect(food.budgeted, 500);
      expect(food.spent, 300);
      expect(food.remaining, 200);
      expect(food.percentUsed, closeTo(0.6, 0.01));

      final transport = comparisons.firstWhere((c) => c.category == ExpenseCategory.transport);
      expect(transport.budgeted, 200);
      expect(transport.spent, 250);
      expect(transport.remaining, -50);
      expect(transport.percentUsed, closeTo(1.25, 0.01));
    });

    test('includes unbudgeted categories with spending', () {
      final budget = MonthlyBudget(
        id: 'b1', year: 2024, month: 6, createdAt: DateTime(2024, 6, 1),
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 500),
        ],
      );
      final entries = [
        ExpenseEntry(id: '1', timestamp: DateTime(2024, 6, 1), amount: 100, category: ExpenseCategory.shopping),
      ];
      final comparisons = service.getBudgetComparison(budget, entries);
      expect(comparisons.length, 2);
      final shopping = comparisons.firstWhere((c) => c.category == ExpenseCategory.shopping);
      expect(shopping.budgeted, 0);
      expect(shopping.spent, 100);
    });
  });

  // ── Templates ───────────────────────────────────────────────────────

  group('createFromPrevious', () {
    test('copies previous month allocations', () {
      final prevBudget = MonthlyBudget(
        id: 'b1', year: 2024, month: 5, createdAt: DateTime(2024, 5, 1),
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 500),
          BudgetAllocation(id: 'a2', category: ExpenseCategory.housing, budgetAmount: 1200),
        ],
      );
      service.setBudget(prevBudget);

      final result = service.createFromPrevious(2024, 6);
      expect(result, isNotNull);
      expect(result!.year, 2024);
      expect(result.month, 6);
      expect(result.allocations.length, 2);
      expect(result.allocations[0].category, ExpenseCategory.food);
      expect(result.allocations[0].budgetAmount, 500);
    });

    test('returns null when no previous month exists', () {
      expect(service.createFromPrevious(2024, 6), isNull);
    });

    test('handles year boundary (Jan copies from Dec)', () {
      service.setBudget(MonthlyBudget(
        id: 'b1', year: 2023, month: 12, createdAt: DateTime(2023, 12, 1),
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 400),
        ],
      ));
      final result = service.createFromPrevious(2024, 1);
      expect(result, isNotNull);
      expect(result!.allocations.first.budgetAmount, 400);
    });
  });

  group('createEvenSplit', () {
    test('splits evenly across non-income categories', () {
      final result = service.createEvenSplit(2024, 6, 1300);
      expect(result.year, 2024);
      expect(result.month, 6);
      // 13 non-income categories
      final nonIncome = ExpenseCategory.values.where((c) => c != ExpenseCategory.income).length;
      expect(result.allocations.length, nonIncome);
      final expected = 1300.0 / nonIncome;
      for (final a in result.allocations) {
        expect(a.budgetAmount, closeTo(expected, 0.01));
      }
    });

    test('replaces existing budget', () {
      service.createEvenSplit(2024, 6, 1000);
      service.createEvenSplit(2024, 6, 2000);
      expect(service.budgets.length, 1);
    });
  });

  // ── Insights ────────────────────────────────────────────────────────

  group('getOverspendingCategories', () {
    test('returns only overspent categories', () {
      final budget = MonthlyBudget(
        id: 'b1', year: 2024, month: 6, createdAt: DateTime(2024, 6, 1),
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 200),
          BudgetAllocation(id: 'a2', category: ExpenseCategory.transport, budgetAmount: 300),
        ],
      );
      final entries = [
        ExpenseEntry(id: '1', timestamp: DateTime(2024, 6, 1), amount: 250, category: ExpenseCategory.food),
        ExpenseEntry(id: '2', timestamp: DateTime(2024, 6, 1), amount: 100, category: ExpenseCategory.transport),
      ];
      final overspent = service.getOverspendingCategories(budget, entries);
      expect(overspent.length, 1);
      expect(overspent.first.category, ExpenseCategory.food);
    });
  });

  group('getSavingsRate', () {
    test('calculates savings rate correctly', () {
      final entries = [
        ExpenseEntry(id: '1', timestamp: DateTime(2024, 6, 1), amount: 5000, category: ExpenseCategory.income),
        ExpenseEntry(id: '2', timestamp: DateTime(2024, 6, 1), amount: 3000, category: ExpenseCategory.housing),
        ExpenseEntry(id: '3', timestamp: DateTime(2024, 6, 5), amount: 500, category: ExpenseCategory.food),
      ];
      final rate = service.getSavingsRate(entries, 2024, 6);
      // (5000 - 3500) / 5000 = 0.3
      expect(rate, closeTo(0.3, 0.01));
    });

    test('returns 0 with no income', () {
      final entries = [
        ExpenseEntry(id: '1', timestamp: DateTime(2024, 6, 1), amount: 100, category: ExpenseCategory.food),
      ];
      expect(service.getSavingsRate(entries, 2024, 6), 0.0);
    });

    test('clamps to 0-1 range', () {
      final entries = [
        ExpenseEntry(id: '1', timestamp: DateTime(2024, 6, 1), amount: 1000, category: ExpenseCategory.income),
      ];
      // No expenses = 100% savings
      expect(service.getSavingsRate(entries, 2024, 6), 1.0);
    });
  });

  group('getBudgetAdherenceScore', () {
    test('returns 100 when all under budget', () {
      final budget = MonthlyBudget(
        id: 'b1', year: 2024, month: 6, createdAt: DateTime(2024, 6, 1),
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 500),
        ],
      );
      final entries = [
        ExpenseEntry(id: '1', timestamp: DateTime(2024, 6, 1), amount: 200, category: ExpenseCategory.food),
      ];
      expect(service.getBudgetAdherenceScore(budget, entries), 100);
    });

    test('decreases when over budget', () {
      final budget = MonthlyBudget(
        id: 'b1', year: 2024, month: 6, createdAt: DateTime(2024, 6, 1),
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 100),
        ],
      );
      final entries = [
        ExpenseEntry(id: '1', timestamp: DateTime(2024, 6, 1), amount: 150, category: ExpenseCategory.food),
      ];
      final score = service.getBudgetAdherenceScore(budget, entries);
      expect(score, lessThan(100));
      expect(score, greaterThan(0));
    });

    test('returns 100 with empty allocations', () {
      final budget = MonthlyBudget(
        id: 'b1', year: 2024, month: 6, createdAt: DateTime(2024, 6, 1),
      );
      expect(service.getBudgetAdherenceScore(budget, []), 100);
    });
  });

  group('getMonthlyTrend', () {
    test('returns correct number of months', () {
      final trend = service.getMonthlyTrend([], months: 6);
      expect(trend.length, 6);
    });

    test('includes budget and actual data', () {
      final now = DateTime.now();
      service.setBudget(MonthlyBudget(
        id: 'b1', year: now.year, month: now.month,
        createdAt: now,
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 500),
        ],
      ));
      final entries = [
        ExpenseEntry(id: '1', timestamp: DateTime(now.year, now.month, 1), amount: 300, category: ExpenseCategory.food),
      ];
      final trend = service.getMonthlyTrend(entries, months: 1);
      expect(trend.length, 1);
      expect(trend.first.budgeted, 500);
      expect(trend.first.actual, 300);
    });
  });

  group('getRecommendations', () {
    test('recommends setting up budget when empty', () {
      final budget = MonthlyBudget(
        id: 'b1', year: 2024, month: 6, createdAt: DateTime(2024, 6, 1),
      );
      final recs = service.getRecommendations(budget, []);
      expect(recs.any((r) => r.contains('Set up')), true);
    });

    test('warns about overspending', () {
      final budget = MonthlyBudget(
        id: 'b1', year: 2024, month: 6, createdAt: DateTime(2024, 6, 1),
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 100),
        ],
      );
      final entries = [
        ExpenseEntry(id: '1', timestamp: DateTime(2024, 6, 1), amount: 200, category: ExpenseCategory.food),
      ];
      final recs = service.getRecommendations(budget, entries);
      expect(recs.any((r) => r.contains('over budget')), true);
    });
  });

  // ── Demo & Loading ──────────────────────────────────────────────────

  group('generateDemoData', () {
    test('creates budgets for current and previous month', () {
      service.generateDemoData();
      final now = DateTime.now();
      expect(service.getBudget(now.year, now.month), isNotNull);
      final prev = DateTime(now.year, now.month - 1, 1);
      expect(service.getBudget(prev.year, prev.month), isNotNull);
    });
  });

  group('loadBudgets', () {
    test('replaces all budgets', () {
      service.generateDemoData();
      final budget = MonthlyBudget(
        id: 'new', year: 2025, month: 1, createdAt: DateTime(2025, 1, 1),
      );
      service.loadBudgets([budget]);
      expect(service.budgets.length, 1);
      expect(service.budgets.first.id, 'new');
    });
  });

  // ── Edge Cases ──────────────────────────────────────────────────────

  group('edge cases', () {
    test('zero budget amount in allocation', () {
      final budget = MonthlyBudget(
        id: 'b1', year: 2024, month: 6, createdAt: DateTime(2024, 6, 1),
        allocations: const [
          BudgetAllocation(id: 'a1', category: ExpenseCategory.food, budgetAmount: 0),
        ],
      );
      final entries = [
        ExpenseEntry(id: '1', timestamp: DateTime(2024, 6, 1), amount: 50, category: ExpenseCategory.food),
      ];
      final comparisons = service.getBudgetComparison(budget, entries);
      final food = comparisons.firstWhere((c) => c.category == ExpenseCategory.food);
      expect(food.percentUsed, 0.0);
    });

    test('multiple budgets for different months', () {
      service.setBudget(MonthlyBudget(
        id: 'b1', year: 2024, month: 1, createdAt: DateTime(2024, 1, 1),
      ));
      service.setBudget(MonthlyBudget(
        id: 'b2', year: 2024, month: 2, createdAt: DateTime(2024, 2, 1),
      ));
      expect(service.budgets.length, 2);
      expect(service.getBudget(2024, 1)!.id, 'b1');
      expect(service.getBudget(2024, 2)!.id, 'b2');
    });
  });
}
