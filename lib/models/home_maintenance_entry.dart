import 'dart:convert';

/// Category of home maintenance task.
enum MaintenanceCategory {
  hvac,
  plumbing,
  electrical,
  exterior,
  interior,
  appliance,
  safety,
  seasonal,
  landscaping,
  other;

  String get label {
    switch (this) {
      case MaintenanceCategory.hvac: return 'HVAC';
      case MaintenanceCategory.plumbing: return 'Plumbing';
      case MaintenanceCategory.electrical: return 'Electrical';
      case MaintenanceCategory.exterior: return 'Exterior';
      case MaintenanceCategory.interior: return 'Interior';
      case MaintenanceCategory.appliance: return 'Appliance';
      case MaintenanceCategory.safety: return 'Safety';
      case MaintenanceCategory.seasonal: return 'Seasonal';
      case MaintenanceCategory.landscaping: return 'Landscaping';
      case MaintenanceCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case MaintenanceCategory.hvac: return '🌡️';
      case MaintenanceCategory.plumbing: return '🔧';
      case MaintenanceCategory.electrical: return '⚡';
      case MaintenanceCategory.exterior: return '🏠';
      case MaintenanceCategory.interior: return '🪟';
      case MaintenanceCategory.appliance: return '🧊';
      case MaintenanceCategory.safety: return '🔒';
      case MaintenanceCategory.seasonal: return '🍂';
      case MaintenanceCategory.landscaping: return '🌿';
      case MaintenanceCategory.other: return '🔩';
    }
  }
}

/// Priority level for a task.
enum MaintenancePriority {
  low,
  medium,
  high,
  urgent;

  String get label {
    switch (this) {
      case MaintenancePriority.low: return 'Low';
      case MaintenancePriority.medium: return 'Medium';
      case MaintenancePriority.high: return 'High';
      case MaintenancePriority.urgent: return 'Urgent';
    }
  }

  String get emoji {
    switch (this) {
      case MaintenancePriority.low: return '🟢';
      case MaintenancePriority.medium: return '🟡';
      case MaintenancePriority.high: return '🟠';
      case MaintenancePriority.urgent: return '🔴';
    }
  }
}

/// Status of a maintenance task.
enum MaintenanceStatus {
  overdue,
  dueSoon,    // within 7 days
  upcoming,   // within 30 days
  onTrack;    // > 30 days

  String get label {
    switch (this) {
      case MaintenanceStatus.overdue: return 'Overdue';
      case MaintenanceStatus.dueSoon: return 'Due Soon';
      case MaintenanceStatus.upcoming: return 'Upcoming';
      case MaintenanceStatus.onTrack: return 'On Track';
    }
  }

  String get emoji {
    switch (this) {
      case MaintenanceStatus.overdue: return '🔴';
      case MaintenanceStatus.dueSoon: return '🟠';
      case MaintenanceStatus.upcoming: return '🟡';
      case MaintenanceStatus.onTrack: return '🟢';
    }
  }
}

/// Recurrence interval for recurring tasks.
enum RecurrenceInterval {
  weekly,
  biweekly,
  monthly,
  quarterly,
  biannually,
  annually,
  custom;

  String get label {
    switch (this) {
      case RecurrenceInterval.weekly: return 'Weekly';
      case RecurrenceInterval.biweekly: return 'Every 2 Weeks';
      case RecurrenceInterval.monthly: return 'Monthly';
      case RecurrenceInterval.quarterly: return 'Quarterly';
      case RecurrenceInterval.biannually: return 'Every 6 Months';
      case RecurrenceInterval.annually: return 'Annually';
      case RecurrenceInterval.custom: return 'Custom';
    }
  }

  int get defaultDays {
    switch (this) {
      case RecurrenceInterval.weekly: return 7;
      case RecurrenceInterval.biweekly: return 14;
      case RecurrenceInterval.monthly: return 30;
      case RecurrenceInterval.quarterly: return 90;
      case RecurrenceInterval.biannually: return 182;
      case RecurrenceInterval.annually: return 365;
      case RecurrenceInterval.custom: return 30;
    }
  }
}

/// A completion record for a maintenance task.
class MaintenanceCompletion {
  final DateTime completedDate;
  final double? cost;
  final String? vendor;
  final String? notes;

  const MaintenanceCompletion({
    required this.completedDate,
    this.cost,
    this.vendor,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'completedDate': completedDate.toIso8601String(),
    'cost': cost,
    'vendor': vendor,
    'notes': notes,
  };

  factory MaintenanceCompletion.fromJson(Map<String, dynamic> json) =>
      MaintenanceCompletion(
        completedDate: DateTime.parse(json['completedDate'] as String),
        cost: (json['cost'] as num?)?.toDouble(),
        vendor: json['vendor'] as String?,
        notes: json['notes'] as String?,
      );
}

/// A home maintenance task with scheduling, completion history, and cost tracking.
class HomeMaintenanceEntry {
  final String id;
  final String name;
  final MaintenanceCategory category;
  final MaintenancePriority priority;
  final String? description;
  final RecurrenceInterval recurrence;
  final int recurrenceDays; // actual interval in days
  final DateTime nextDueDate;
  final List<MaintenanceCompletion> completions;
  final String? location; // e.g., "Basement", "Kitchen"
  final double? estimatedCost;

  const HomeMaintenanceEntry({
    required this.id,
    required this.name,
    required this.category,
    this.priority = MaintenancePriority.medium,
    this.description,
    required this.recurrence,
    required this.recurrenceDays,
    required this.nextDueDate,
    this.completions = const [],
    this.location,
    this.estimatedCost,
  });

  /// Days until next due (negative = overdue).
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return due.difference(today).inDays;
  }

  /// Current status based on due date.
  MaintenanceStatus get status {
    final days = daysUntilDue;
    if (days < 0) return MaintenanceStatus.overdue;
    if (days <= 7) return MaintenanceStatus.dueSoon;
    if (days <= 30) return MaintenanceStatus.upcoming;
    return MaintenanceStatus.onTrack;
  }

  /// Total spent across all completions.
  double get totalSpent =>
      completions.fold(0.0, (sum, c) => sum + (c.cost ?? 0));

  /// Average cost per completion.
  double get averageCost =>
      completions.isEmpty ? 0 : totalSpent / completions.length;

  /// Last completion date, if any.
  DateTime? get lastCompleted =>
      completions.isEmpty ? null : completions.last.completedDate;

  /// Number of times completed.
  int get completionCount => completions.length;

  HomeMaintenanceEntry copyWith({
    String? id,
    String? name,
    MaintenanceCategory? category,
    MaintenancePriority? priority,
    String? description,
    RecurrenceInterval? recurrence,
    int? recurrenceDays,
    DateTime? nextDueDate,
    List<MaintenanceCompletion>? completions,
    String? location,
    double? estimatedCost,
  }) {
    return HomeMaintenanceEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      recurrence: recurrence ?? this.recurrence,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      completions: completions ?? this.completions,
      location: location ?? this.location,
      estimatedCost: estimatedCost ?? this.estimatedCost,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.index,
    'priority': priority.index,
    'description': description,
    'recurrence': recurrence.index,
    'recurrenceDays': recurrenceDays,
    'nextDueDate': nextDueDate.toIso8601String(),
    'completions': completions.map((c) => c.toJson()).toList(),
    'location': location,
    'estimatedCost': estimatedCost,
  };

  factory HomeMaintenanceEntry.fromJson(Map<String, dynamic> json) =>
      HomeMaintenanceEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        category: MaintenanceCategory.values[json['category'] as int],
        priority: MaintenancePriority.values[json['priority'] as int? ?? 1],
        description: json['description'] as String?,
        recurrence: RecurrenceInterval.values[json['recurrence'] as int],
        recurrenceDays: json['recurrenceDays'] as int,
        nextDueDate: DateTime.parse(json['nextDueDate'] as String),
        completions: (json['completions'] as List<dynamic>?)
            ?.map((c) => MaintenanceCompletion.fromJson(c as Map<String, dynamic>))
            .toList() ?? [],
        location: json['location'] as String?,
        estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      );
}
