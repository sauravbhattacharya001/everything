/// Model classes for the Time Tracker feature.

/// Categories for time entries.
enum TimeCategory {
  work('Work', '💼'),
  study('Study', '📚'),
  exercise('Exercise', '🏋️'),
  creative('Creative', '🎨'),
  social('Social', '👥'),
  chores('Chores', '🏠'),
  selfCare('Self Care', '🧘'),
  entertainment('Entertainment', '🎮'),
  commute('Commute', '🚗'),
  other('Other', '📌');

  final String label;
  final String emoji;
  const TimeCategory(this.label, this.emoji);
}

/// A single time entry representing an activity session.
class TimeEntry {
  final String id;
  final String activity;
  final TimeCategory category;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final List<String> tags;

  const TimeEntry({
    required this.id,
    required this.activity,
    required this.category,
    required this.startTime,
    this.endTime,
    this.notes,
    this.tags = const [],
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isRunning => endTime == null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'activity': activity,
        'category': category.name,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'notes': notes,
        'tags': tags,
      };

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    return TimeEntry(
      id: json['id'] as String,
      activity: json['activity'] as String,
      category: TimeCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => TimeCategory.other),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      notes: json['notes'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  TimeEntry copyWith({
    String? activity,
    TimeCategory? category,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    List<String>? tags,
    bool clearEndTime = false,
  }) {
    return TimeEntry(
      id: id,
      activity: activity ?? this.activity,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }
}

/// Daily productivity summary.
class TimeAuditDailySummary {
  final DateTime date;
  final Duration totalTracked;
  final Map<TimeCategory, Duration> categoryBreakdown;
  final int entryCount;
  final String? topCategory;
  final Duration longestSession;

  const TimeAuditDailySummary({
    required this.date,
    required this.totalTracked,
    required this.categoryBreakdown,
    required this.entryCount,
    this.topCategory,
    required this.longestSession,
  });
}

/// Weekly insights data.
class WeeklyInsight {
  final String label;
  final String value;
  final String? trend;
  final IconType icon;

  const WeeklyInsight({
    required this.label,
    required this.value,
    this.trend,
    this.icon = IconType.info,
  });
}

enum IconType { info, time, chart, star, fire, target }
