/// Model classes for the Bucket List feature.

/// Life experience category.
enum BucketCategory {
  travel('Travel', '✈️'),
  adventure('Adventure', '🏔️'),
  career('Career', '💼'),
  learning('Learning', '📚'),
  creative('Creative', '🎨'),
  social('Social', '👥'),
  health('Health & Fitness', '💪'),
  food('Food & Drink', '🍽️'),
  culture('Culture', '🏛️'),
  nature('Nature', '🌿'),
  personal('Personal Growth', '🌱'),
  financial('Financial', '💰');

  final String label;
  final String emoji;
  const BucketCategory(this.label, this.emoji);
}

/// Priority level for bucket list items.
enum BucketPriority {
  dream(1, 'Dream', '💭'),
  someday(2, 'Someday', '🌤️'),
  soon(3, 'Soon', '⏰'),
  thisYear(4, 'This Year', '📅'),
  urgent(5, 'Must Do', '🔥');

  final int value;
  final String label;
  final String emoji;
  const BucketPriority(this.value, this.label, this.emoji);
}

/// Difficulty/effort estimate.
enum BucketEffort {
  easy('Easy', '🟢'),
  moderate('Moderate', '🟡'),
  challenging('Challenging', '🟠'),
  epic('Epic', '🔴');

  final String label;
  final String emoji;
  const BucketEffort(this.label, this.emoji);
}

/// A single bucket list item.
class BucketItem {
  final String id;
  final String title;
  final String? description;
  final BucketCategory category;
  final BucketPriority priority;
  final BucketEffort effort;
  final double? estimatedCost;
  final String? location;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? targetDate;
  final DateTime? completedAt;
  final String? completionNotes;
  final int rating; // 0 = unrated, 1-5
  final String? inspiration; // what inspired this item

  const BucketItem({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    this.effort = BucketEffort.moderate,
    this.estimatedCost,
    this.location,
    this.tags = const [],
    required this.createdAt,
    this.targetDate,
    this.completedAt,
    this.completionNotes,
    this.rating = 0,
    this.inspiration,
  });

  bool get isCompleted => completedAt != null;

  bool get isOverdue =>
      targetDate != null &&
      !isCompleted &&
      targetDate!.isBefore(DateTime.now());

  int get daysUntilTarget {
    if (targetDate == null) return -1;
    return targetDate!.difference(DateTime.now()).inDays;
  }

  int get daysSinceCreated =>
      DateTime.now().difference(createdAt).inDays;

  BucketItem copyWith({
    String? title,
    String? description,
    BucketCategory? category,
    BucketPriority? priority,
    BucketEffort? effort,
    double? estimatedCost,
    String? location,
    List<String>? tags,
    DateTime? targetDate,
    DateTime? completedAt,
    String? completionNotes,
    int? rating,
    String? inspiration,
  }) {
    return BucketItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      effort: effort ?? this.effort,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      targetDate: targetDate ?? this.targetDate,
      completedAt: completedAt ?? this.completedAt,
      completionNotes: completionNotes ?? this.completionNotes,
      rating: rating ?? this.rating,
      inspiration: inspiration ?? this.inspiration,
    );
  }

  BucketItem markComplete({String? notes, int? rating}) {
    return copyWith(
      completedAt: DateTime.now(),
      completionNotes: notes,
      rating: rating,
    );
  }
}

/// Statistics summary for bucket list.
class BucketStats {
  final int totalItems;
  final int completedItems;
  final int overdueItems;
  final double completionRate;
  final double totalEstimatedCost;
  final double avgRating;
  final Map<BucketCategory, int> categoryBreakdown;
  final Map<BucketCategory, int> categoryCompleted;
  final Map<BucketPriority, int> priorityBreakdown;
  final Map<BucketEffort, int> effortBreakdown;
  final int avgDaysToComplete;
  final BucketCategory? topCategory;
  final String? mostUsedTag;

  const BucketStats({
    required this.totalItems,
    required this.completedItems,
    required this.overdueItems,
    required this.completionRate,
    required this.totalEstimatedCost,
    required this.avgRating,
    required this.categoryBreakdown,
    required this.categoryCompleted,
    required this.priorityBreakdown,
    required this.effortBreakdown,
    required this.avgDaysToComplete,
    this.topCategory,
    this.mostUsedTag,
  });
}

/// Insight generated from bucket list data.
class BucketInsight {
  final String emoji;
  final String title;
  final String description;

  const BucketInsight({
    required this.emoji,
    required this.title,
    required this.description,
  });
}
