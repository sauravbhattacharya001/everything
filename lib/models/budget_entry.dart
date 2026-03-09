import 'expense_entry.dart';

/// A single category budget allocation within a monthly budget.
class BudgetAllocation {
  final String id;
  final ExpenseCategory category;
  final double budgetAmount;
  final String? notes;

  const BudgetAllocation({
    required this.id,
    required this.category,
    required this.budgetAmount,
    this.notes,
  });

  BudgetAllocation copyWith({
    String? id,
    ExpenseCategory? category,
    double? budgetAmount,
    String? notes,
  }) {
    return BudgetAllocation(
      id: id ?? this.id,
      category: category ?? this.category,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'budgetAmount': budgetAmount,
      'notes': notes,
    };
  }

  factory BudgetAllocation.fromJson(Map<String, dynamic> json) {
    return BudgetAllocation(
      id: json['id'] as String,
      category: ExpenseCategory.values.firstWhere(
        (v) => v.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
    );
  }
}

/// A monthly budget containing allocations across expense categories.
class MonthlyBudget {
  final String id;
  final int year;
  final int month;
  final List<BudgetAllocation> allocations;
  final DateTime createdAt;

  const MonthlyBudget({
    required this.id,
    required this.year,
    required this.month,
    this.allocations = const [],
    required this.createdAt,
  });

  /// Total budget is the sum of all allocations.
  double get totalBudget =>
      allocations.fold(0.0, (sum, a) => sum + a.budgetAmount);

  MonthlyBudget copyWith({
    String? id,
    int? year,
    int? month,
    List<BudgetAllocation>? allocations,
    DateTime? createdAt,
  }) {
    return MonthlyBudget(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      allocations: allocations ?? this.allocations,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'allocations': allocations.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MonthlyBudget.fromJson(Map<String, dynamic> json) {
    return MonthlyBudget(
      id: json['id'] as String,
      year: json['year'] as int,
      month: json['month'] as int,
      allocations: (json['allocations'] as List<dynamic>?)
              ?.map((a) =>
                  BudgetAllocation.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
