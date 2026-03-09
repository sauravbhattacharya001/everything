/// Represents a savings goal with target amount, deadline, and contributions.
class SavingsGoal {
  final String id;
  final String name;
  final String emoji;
  final double targetAmount;
  final DateTime? deadline;
  final DateTime createdAt;
  final SavingsGoalCategory category;
  final SavingsGoalPriority priority;
  final List<SavingsContribution> contributions;
  final bool isArchived;

  SavingsGoal({
    required this.id,
    required this.name,
    this.emoji = '🎯',
    required this.targetAmount,
    this.deadline,
    DateTime? createdAt,
    this.category = SavingsGoalCategory.general,
    this.priority = SavingsGoalPriority.medium,
    List<SavingsContribution>? contributions,
    this.isArchived = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        contributions = contributions ?? [];

  double get savedAmount =>
      contributions.fold(0.0, (sum, c) => sum + c.amount);

  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remainingAmount => (targetAmount - savedAmount).clamp(0.0, double.infinity);

  bool get isComplete => savedAmount >= targetAmount;

  int? get daysRemaining =>
      deadline != null ? deadline!.difference(DateTime.now()).inDays : null;

  /// Average daily savings rate based on contribution history.
  double get dailySavingsRate {
    if (contributions.isEmpty) return 0.0;
    final sorted = List<SavingsContribution>.from(contributions)
      ..sort((a, b) => a.date.compareTo(b.date));
    final days = DateTime.now().difference(sorted.first.date).inDays;
    return days > 0 ? savedAmount / days : savedAmount;
  }

  /// Projected date to reach the goal at current savings rate.
  DateTime? get projectedCompletionDate {
    if (isComplete) return DateTime.now();
    if (dailySavingsRate <= 0) return null;
    final daysNeeded = (remainingAmount / dailySavingsRate).ceil();
    return DateTime.now().add(Duration(days: daysNeeded));
  }

  /// Whether the goal is on track to meet the deadline.
  bool? get isOnTrack {
    if (deadline == null) return null;
    if (isComplete) return true;
    final projected = projectedCompletionDate;
    if (projected == null) return false;
    return !projected.isAfter(deadline!);
  }

  SavingsGoal copyWith({
    String? name,
    String? emoji,
    double? targetAmount,
    DateTime? deadline,
    SavingsGoalCategory? category,
    SavingsGoalPriority? priority,
    List<SavingsContribution>? contributions,
    bool? isArchived,
  }) {
    return SavingsGoal(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      contributions: contributions ?? this.contributions,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'targetAmount': targetAmount,
        'deadline': deadline?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'category': category.name,
        'priority': priority.name,
        'contributions': contributions.map((c) => c.toJson()).toList(),
        'isArchived': isArchived,
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '🎯',
      targetAmount: (json['targetAmount'] as num).toDouble(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: SavingsGoalCategory.values.firstWhere(
        (v) => v.name == json['category'],
        orElse: () => SavingsGoalCategory.general,
      ),
      priority: SavingsGoalPriority.values.firstWhere(
        (v) => v.name == json['priority'],
        orElse: () => SavingsGoalPriority.medium,
      ),
      contributions: (json['contributions'] as List<dynamic>?)
              ?.map((c) =>
                  SavingsContribution.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }
}

/// A single contribution to a savings goal.
class SavingsContribution {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  SavingsContribution({
    required this.id,
    required this.amount,
    DateTime? date,
    this.note,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory SavingsContribution.fromJson(Map<String, dynamic> json) {
    return SavingsContribution(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }
}

enum SavingsGoalCategory {
  general,
  emergency,
  travel,
  education,
  housing,
  vehicle,
  retirement,
  health,
  gift,
  gadget,
}

extension SavingsGoalCategoryX on SavingsGoalCategory {
  String get label => switch (this) {
        SavingsGoalCategory.general => 'General',
        SavingsGoalCategory.emergency => 'Emergency Fund',
        SavingsGoalCategory.travel => 'Travel',
        SavingsGoalCategory.education => 'Education',
        SavingsGoalCategory.housing => 'Housing',
        SavingsGoalCategory.vehicle => 'Vehicle',
        SavingsGoalCategory.retirement => 'Retirement',
        SavingsGoalCategory.health => 'Health',
        SavingsGoalCategory.gift => 'Gift',
        SavingsGoalCategory.gadget => 'Gadget',
      };

  String get emoji => switch (this) {
        SavingsGoalCategory.general => '🎯',
        SavingsGoalCategory.emergency => '🛡️',
        SavingsGoalCategory.travel => '✈️',
        SavingsGoalCategory.education => '📚',
        SavingsGoalCategory.housing => '🏠',
        SavingsGoalCategory.vehicle => '🚗',
        SavingsGoalCategory.retirement => '🏖️',
        SavingsGoalCategory.health => '💊',
        SavingsGoalCategory.gift => '🎁',
        SavingsGoalCategory.gadget => '📱',
      };
}

enum SavingsGoalPriority {
  low,
  medium,
  high,
}

extension SavingsGoalPriorityX on SavingsGoalPriority {
  String get label => switch (this) {
        SavingsGoalPriority.low => 'Low',
        SavingsGoalPriority.medium => 'Medium',
        SavingsGoalPriority.high => 'High',
      };
}
