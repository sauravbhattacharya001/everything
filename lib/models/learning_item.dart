import 'package:everything/core/utils/date_utils.dart';

/// Learning resource type.
enum LearningType {
  course,
  book,
  tutorial,
  video,
  podcast,
  article,
  workshop,
  certification;

  String get label {
    switch (this) {
      case LearningType.course:
        return 'Course';
      case LearningType.book:
        return 'Book';
      case LearningType.tutorial:
        return 'Tutorial';
      case LearningType.video:
        return 'Video';
      case LearningType.podcast:
        return 'Podcast';
      case LearningType.article:
        return 'Article';
      case LearningType.workshop:
        return 'Workshop';
      case LearningType.certification:
        return 'Certification';
    }
  }

  String get emoji {
    switch (this) {
      case LearningType.course:
        return '🎓';
      case LearningType.book:
        return '📚';
      case LearningType.tutorial:
        return '📝';
      case LearningType.video:
        return '🎬';
      case LearningType.podcast:
        return '🎧';
      case LearningType.article:
        return '📄';
      case LearningType.workshop:
        return '🔧';
      case LearningType.certification:
        return '🏆';
    }
  }
}

/// Learning status.
enum LearningStatus {
  planned,
  inProgress,
  completed,
  paused,
  dropped;

  String get label {
    switch (this) {
      case LearningStatus.planned:
        return 'Planned';
      case LearningStatus.inProgress:
        return 'In Progress';
      case LearningStatus.completed:
        return 'Completed';
      case LearningStatus.paused:
        return 'Paused';
      case LearningStatus.dropped:
        return 'Dropped';
    }
  }

  String get emoji {
    switch (this) {
      case LearningStatus.planned:
        return '📋';
      case LearningStatus.inProgress:
        return '▶️';
      case LearningStatus.completed:
        return '✅';
      case LearningStatus.paused:
        return '⏸️';
      case LearningStatus.dropped:
        return '🚫';
    }
  }
}

/// Learning topic category.
enum LearningCategory {
  programming,
  dataScience,
  design,
  business,
  language,
  math,
  science,
  music,
  health,
  finance,
  other;

  String get label {
    switch (this) {
      case LearningCategory.programming:
        return 'Programming';
      case LearningCategory.dataScience:
        return 'Data Science';
      case LearningCategory.design:
        return 'Design';
      case LearningCategory.business:
        return 'Business';
      case LearningCategory.language:
        return 'Language';
      case LearningCategory.math:
        return 'Math';
      case LearningCategory.science:
        return 'Science';
      case LearningCategory.music:
        return 'Music';
      case LearningCategory.health:
        return 'Health';
      case LearningCategory.finance:
        return 'Finance';
      case LearningCategory.other:
        return 'Other';
    }
  }
}

/// A study session log entry.
class StudySession {
  final DateTime date;
  final int minutesSpent;
  final int progressDelta; // e.g. chapters/lessons completed
  final String? notes;

  const StudySession({
    required this.date,
    required this.minutesSpent,
    this.progressDelta = 0,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'minutesSpent': minutesSpent,
        'progressDelta': progressDelta,
        if (notes != null) 'notes': notes,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      date: AppDateUtils.safeParse(json['date'] as String?),
      minutesSpent: json['minutesSpent'] as int,
      progressDelta: json['progressDelta'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }
}

/// A learning item (course, book, tutorial, etc.).
class LearningItem {
  final String id;
  final String title;
  final String? source; // e.g. "Udemy", "Coursera", URL
  final LearningType type;
  final LearningCategory category;
  final LearningStatus status;
  final int totalUnits; // chapters, lessons, modules, etc.
  final int completedUnits;
  final int? rating; // 1-5 stars
  final String? notes;
  final DateTime dateAdded;
  final DateTime? dateStarted;
  final DateTime? dateCompleted;
  final List<StudySession> sessions;
  final List<String> tags;
  final int priority; // 1 (low) - 5 (high)

  const LearningItem({
    required this.id,
    required this.title,
    this.source,
    this.type = LearningType.course,
    this.category = LearningCategory.other,
    this.status = LearningStatus.planned,
    this.totalUnits = 0,
    this.completedUnits = 0,
    this.rating,
    this.notes,
    required this.dateAdded,
    this.dateStarted,
    this.dateCompleted,
    this.sessions = const [],
    this.tags = const [],
    this.priority = 3,
  });

  double get progressPercent =>
      totalUnits > 0 ? (completedUnits / totalUnits * 100).clamp(0, 100) : 0;

  int get unitsRemaining => (totalUnits - completedUnits).clamp(0, totalUnits);

  int get totalMinutesStudied =>
      sessions.fold(0, (sum, s) => sum + s.minutesSpent);

  double get hoursStudied => totalMinutesStudied / 60.0;

  double get averageSessionMinutes {
    if (sessions.isEmpty) return 0;
    return totalMinutesStudied / sessions.length;
  }

  /// Days since started (or since added if not started).
  int get daysActive {
    final start = dateStarted ?? dateAdded;
    final end = dateCompleted ?? DateTime.now();
    return end.difference(start).inDays;
  }

  LearningItem copyWith({
    String? id,
    String? title,
    String? source,
    LearningType? type,
    LearningCategory? category,
    LearningStatus? status,
    int? totalUnits,
    int? completedUnits,
    int? rating,
    String? notes,
    DateTime? dateAdded,
    DateTime? dateStarted,
    DateTime? dateCompleted,
    List<StudySession>? sessions,
    List<String>? tags,
    int? priority,
  }) {
    return LearningItem(
      id: id ?? this.id,
      title: title ?? this.title,
      source: source ?? this.source,
      type: type ?? this.type,
      category: category ?? this.category,
      status: status ?? this.status,
      totalUnits: totalUnits ?? this.totalUnits,
      completedUnits: completedUnits ?? this.completedUnits,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      dateAdded: dateAdded ?? this.dateAdded,
      dateStarted: dateStarted ?? this.dateStarted,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      sessions: sessions ?? this.sessions,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (source != null) 'source': source,
        'type': type.name,
        'category': category.name,
        'status': status.name,
        'totalUnits': totalUnits,
        'completedUnits': completedUnits,
        if (rating != null) 'rating': rating,
        if (notes != null) 'notes': notes,
        'dateAdded': dateAdded.toIso8601String(),
        if (dateStarted != null) 'dateStarted': dateStarted!.toIso8601String(),
        if (dateCompleted != null)
          'dateCompleted': dateCompleted!.toIso8601String(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'tags': tags,
        'priority': priority,
      };

  factory LearningItem.fromJson(Map<String, dynamic> json) {
    return LearningItem(
      id: json['id'] as String,
      title: json['title'] as String,
      source: json['source'] as String?,
      type: LearningType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => LearningType.course,
      ),
      category: LearningCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => LearningCategory.other,
      ),
      status: LearningStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => LearningStatus.planned,
      ),
      totalUnits: json['totalUnits'] as int? ?? 0,
      completedUnits: json['completedUnits'] as int? ?? 0,
      rating: json['rating'] as int?,
      notes: json['notes'] as String?,
      dateAdded: AppDateUtils.safeParse(json['dateAdded'] as String?),
      dateStarted: AppDateUtils.safeParseNullable(json['dateStarted'] as String?),
      dateCompleted: AppDateUtils.safeParseNullable(json['dateCompleted'] as String?),
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((s) => StudySession.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t as String)
              .toList() ??
          [],
      priority: json['priority'] as int? ?? 3,
    );
  }

  @override
  String toString() =>
      '${type.emoji} "$title" (${status.label}, ${progressPercent.toStringAsFixed(0)}%)';
}
