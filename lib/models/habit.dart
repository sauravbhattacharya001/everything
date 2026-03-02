import 'dart:convert';

/// Frequency at which a habit should be performed.
enum HabitFrequency {
  daily,
  weekdays,
  weekends,
  custom;

  String get label {
    switch (this) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekdays:
        return 'Weekdays';
      case HabitFrequency.weekends:
        return 'Weekends';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }
}

/// A single habit definition.
class Habit {
  /// Unique identifier for the habit.
  final String id;

  /// Display name.
  final String name;

  /// Optional description or motivation note.
  final String? description;

  /// Target frequency.
  final HabitFrequency frequency;

  /// For [HabitFrequency.custom], which days of the week (1=Mon, 7=Sun).
  final List<int> customDays;

  /// Optional emoji icon for quick visual identification.
  final String? emoji;

  /// When the habit was created.
  final DateTime createdAt;

  /// Whether the habit is currently active (not archived).
  final bool isActive;

  /// Optional target count per day (e.g., "drink 8 glasses of water").
  /// Defaults to 1 (binary: done or not done).
  final int targetCount;

  const Habit({
    required this.id,
    required this.name,
    this.description,
    this.frequency = HabitFrequency.daily,
    this.customDays = const [],
    this.emoji,
    required this.createdAt,
    this.isActive = true,
    this.targetCount = 1,
  });

  /// Whether this habit is scheduled for a given [weekday] (1=Mon, 7=Sun).
  bool isScheduledFor(int weekday) {
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekdays:
        return weekday >= 1 && weekday <= 5;
      case HabitFrequency.weekends:
        return weekday == 6 || weekday == 7;
      case HabitFrequency.custom:
        return customDays.contains(weekday);
    }
  }

  Habit copyWith({
    String? name,
    String? description,
    HabitFrequency? frequency,
    List<int>? customDays,
    String? emoji,
    bool? isActive,
    int? targetCount,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      targetCount: targetCount ?? this.targetCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'frequency': frequency.name,
        'customDays': customDays,
        'emoji': emoji,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
        'targetCount': targetCount,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        frequency: HabitFrequency.values.firstWhere(
          (f) => f.name == json['frequency'],
          orElse: () => HabitFrequency.daily,
        ),
        customDays: (json['customDays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
        emoji: json['emoji'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isActive: json['isActive'] as bool? ?? true,
        targetCount: json['targetCount'] as int? ?? 1,
      );
}

/// A single completion log entry.
class HabitCompletion {
  /// The habit this completion belongs to.
  final String habitId;

  /// The date of completion (date only, no time component).
  final DateTime date;

  /// How many times completed on this date (for count-based habits).
  final int count;

  /// Optional note for the day.
  final String? note;

  const HabitCompletion({
    required this.habitId,
    required this.date,
    this.count = 1,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'date': date.toIso8601String(),
        'count': count,
        'note': note,
      };

  factory HabitCompletion.fromJson(Map<String, dynamic> json) =>
      HabitCompletion(
        habitId: json['habitId'] as String,
        date: DateTime.parse(json['date'] as String),
        count: json['count'] as int? ?? 1,
        note: json['note'] as String?,
      );
}
