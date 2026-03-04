import 'dart:convert';

/// Category for organizing goals.
enum GoalCategory {
  health,
  career,
  finance,
  education,
  personal,
  fitness,
  creative,
  social,
  other;

  String get label {
    switch (this) {
      case GoalCategory.health:
        return 'Health';
      case GoalCategory.career:
        return 'Career';
      case GoalCategory.finance:
        return 'Finance';
      case GoalCategory.education:
        return 'Education';
      case GoalCategory.personal:
        return 'Personal';
      case GoalCategory.fitness:
        return 'Fitness';
      case GoalCategory.creative:
        return 'Creative';
      case GoalCategory.social:
        return 'Social';
      case GoalCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case GoalCategory.health:
        return '🏥';
      case GoalCategory.career:
        return '💼';
      case GoalCategory.finance:
        return '💰';
      case GoalCategory.education:
        return '📚';
      case GoalCategory.personal:
        return '🌟';
      case GoalCategory.fitness:
        return '💪';
      case GoalCategory.creative:
        return '🎨';
      case GoalCategory.social:
        return '🤝';
      case GoalCategory.other:
        return '📌';
    }
  }
}

/// A milestone within a goal.
class Milestone {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? completedAt;

  const Milestone({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
  });

  Milestone copyWith({
    String? title,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Milestone(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String? ?? '')
            : null,
      );
}

/// A goal with progress tracking, milestones, and deadline.
class Goal {
  final String id;
  final String title;
  final String description;
  final GoalCategory category;
  final DateTime createdAt;
  final DateTime? deadline;

  /// Manual progress value 0–100.
  final int progress;

  /// Whether the goal is completed.
  final bool isCompleted;

  /// Sub-milestones for breaking down the goal.
  final List<Milestone> milestones;

  /// Whether the goal is archived.
  final bool isArchived;

  const Goal({
    required this.id,
    required this.title,
    this.description = '',
    this.category = GoalCategory.personal,
    required this.createdAt,
    this.deadline,
    this.progress = 0,
    this.isCompleted = false,
    this.milestones = const [],
    this.isArchived = false,
  });

  /// Computed progress based on milestones if any, otherwise manual progress.
  double get effectiveProgress {
    if (isCompleted) return 1.0;
    if (milestones.isNotEmpty) {
      final done = milestones.where((m) => m.isCompleted).length;
      return done / milestones.length;
    }
    return progress / 100.0;
  }

  /// Days remaining until deadline, or null if no deadline.
  int? get daysRemaining {
    if (deadline == null) return null;
    final now = DateTime.now();
    return deadline!.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// Whether the deadline has passed.
  bool get isOverdue {
    final days = daysRemaining;
    return days != null && days < 0 && !isCompleted;
  }

  Goal copyWith({
    String? title,
    String? description,
    GoalCategory? category,
    DateTime? deadline,
    bool clearDeadline = false,
    int? progress,
    bool? isCompleted,
    List<Milestone>? milestones,
    bool? isArchived,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      milestones: milestones ?? List.of(this.milestones),
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'createdAt': createdAt.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
        'progress': progress,
        'isCompleted': isCompleted,
        'milestones':
            jsonEncode(milestones.map((m) => m.toJson()).toList()),
        'isArchived': isArchived,
      };

  factory Goal.fromJson(Map<String, dynamic> json) {
    List<Milestone> parsedMilestones = [];
    final msRaw = json['milestones'];
    if (msRaw is String && msRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(msRaw) as List<dynamic>;
        parsedMilestones = decoded
            .map((m) => Milestone.fromJson(m as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    } else if (msRaw is List) {
      parsedMilestones = msRaw
          .map((m) => Milestone.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      category: GoalCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => GoalCategory.personal,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String? ?? '')
          : null,
      progress: json['progress'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      milestones: parsedMilestones,
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }
}
