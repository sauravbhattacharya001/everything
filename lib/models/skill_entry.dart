import 'dart:convert';

/// Categories of skills being learned.
enum SkillCategory {
  programming,
  language,
  music,
  art,
  sports,
  cooking,
  writing,
  science,
  math,
  business,
  craft,
  other;

  String get label {
    switch (this) {
      case SkillCategory.programming: return 'Programming';
      case SkillCategory.language: return 'Language';
      case SkillCategory.music: return 'Music';
      case SkillCategory.art: return 'Art';
      case SkillCategory.sports: return 'Sports';
      case SkillCategory.cooking: return 'Cooking';
      case SkillCategory.writing: return 'Writing';
      case SkillCategory.science: return 'Science';
      case SkillCategory.math: return 'Math';
      case SkillCategory.business: return 'Business';
      case SkillCategory.craft: return 'Craft';
      case SkillCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case SkillCategory.programming: return '💻';
      case SkillCategory.language: return '🗣️';
      case SkillCategory.music: return '🎵';
      case SkillCategory.art: return '🎨';
      case SkillCategory.sports: return '⚽';
      case SkillCategory.cooking: return '🍳';
      case SkillCategory.writing: return '✍️';
      case SkillCategory.science: return '🔬';
      case SkillCategory.math: return '📐';
      case SkillCategory.business: return '💼';
      case SkillCategory.craft: return '🛠️';
      case SkillCategory.other: return '📚';
    }
  }
}

/// Proficiency level from beginner to master.
enum ProficiencyLevel {
  beginner,
  elementary,
  intermediate,
  upperIntermediate,
  advanced,
  expert,
  master;

  int get value {
    switch (this) {
      case ProficiencyLevel.beginner: return 1;
      case ProficiencyLevel.elementary: return 2;
      case ProficiencyLevel.intermediate: return 3;
      case ProficiencyLevel.upperIntermediate: return 4;
      case ProficiencyLevel.advanced: return 5;
      case ProficiencyLevel.expert: return 6;
      case ProficiencyLevel.master: return 7;
    }
  }

  String get label {
    switch (this) {
      case ProficiencyLevel.beginner: return 'Beginner';
      case ProficiencyLevel.elementary: return 'Elementary';
      case ProficiencyLevel.intermediate: return 'Intermediate';
      case ProficiencyLevel.upperIntermediate: return 'Upper Intermediate';
      case ProficiencyLevel.advanced: return 'Advanced';
      case ProficiencyLevel.expert: return 'Expert';
      case ProficiencyLevel.master: return 'Master';
    }
  }

  static ProficiencyLevel fromValue(int v) {
    if (v <= 1) return ProficiencyLevel.beginner;
    if (v == 2) return ProficiencyLevel.elementary;
    if (v == 3) return ProficiencyLevel.intermediate;
    if (v == 4) return ProficiencyLevel.upperIntermediate;
    if (v == 5) return ProficiencyLevel.advanced;
    if (v == 6) return ProficiencyLevel.expert;
    return ProficiencyLevel.master;
  }
}

/// A single practice/learning session.
class PracticeSession {
  final String id;
  final DateTime startTime;
  final int durationMinutes;
  final String? topic;
  final String? notes;
  final int quality;
  final List<String> resources;

  PracticeSession({
    required this.id,
    required this.startTime,
    required this.durationMinutes,
    this.topic,
    this.notes,
    this.quality = 3,
    this.resources = const [],
  });

  PracticeSession copyWith({
    String? id,
    DateTime? startTime,
    int? durationMinutes,
    String? topic,
    String? notes,
    int? quality,
    List<String>? resources,
  }) {
    return PracticeSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      topic: topic ?? this.topic,
      notes: notes ?? this.notes,
      quality: quality ?? this.quality,
      resources: resources ?? List.from(this.resources),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'durationMinutes': durationMinutes,
    'topic': topic,
    'notes': notes,
    'quality': quality,
    'resources': resources,
  };

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      durationMinutes: json['durationMinutes'] as int,
      topic: json['topic'] as String?,
      notes: json['notes'] as String?,
      quality: json['quality'] as int? ?? 3,
      resources: (json['resources'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  @override
  String toString() =>
      '${durationMinutes}min${topic != null ? " ($topic)" : ""} - ${startTime.toIso8601String()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PracticeSession && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A milestone/goal within a skill.
class SkillMilestone {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime? completedAt;
  final int orderIndex;

  SkillMilestone({
    required this.id,
    required this.title,
    this.description,
    this.completed = false,
    this.completedAt,
    this.orderIndex = 0,
  });

  SkillMilestone copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    DateTime? completedAt,
    int? orderIndex,
  }) {
    return SkillMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
    'orderIndex': orderIndex,
  };

  factory SkillMilestone.fromJson(Map<String, dynamic> json) {
    return SkillMilestone(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      orderIndex: json['orderIndex'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SkillMilestone && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A skill being tracked/learned.
class SkillEntry {
  final String id;
  final String name;
  final SkillCategory category;
  final ProficiencyLevel currentLevel;
  final ProficiencyLevel targetLevel;
  final DateTime startedAt;
  final DateTime? lastPracticedAt;
  final List<PracticeSession> sessions;
  final List<SkillMilestone> milestones;
  final List<String> tags;
  final String? notes;
  final bool isArchived;
  final int weeklyGoalMinutes;

  SkillEntry({
    required this.id,
    required this.name,
    this.category = SkillCategory.other,
    this.currentLevel = ProficiencyLevel.beginner,
    this.targetLevel = ProficiencyLevel.advanced,
    required this.startedAt,
    this.lastPracticedAt,
    this.sessions = const [],
    this.milestones = const [],
    this.tags = const [],
    this.notes,
    this.isArchived = false,
    this.weeklyGoalMinutes = 120,
  });

  int get totalMinutes =>
      sessions.fold(0, (sum, s) => sum + s.durationMinutes);

  double get totalHours => (totalMinutes / 60.0 * 10).round() / 10.0;

  double get averageQuality {
    if (sessions.isEmpty) return 0;
    return sessions.map((s) => s.quality).reduce((a, b) => a + b) /
        sessions.length;
  }

  double get levelProgress {
    final range = targetLevel.value - ProficiencyLevel.beginner.value;
    if (range <= 0) return 1.0;
    final progress = currentLevel.value - ProficiencyLevel.beginner.value;
    return (progress / range).clamp(0.0, 1.0);
  }

  double get milestoneProgress {
    if (milestones.isEmpty) return 0;
    return milestones.where((m) => m.completed).length / milestones.length;
  }

  int daysSinceStart(DateTime now) => now.difference(startedAt).inDays;

  int? daysSinceLastPractice(DateTime now) {
    if (lastPracticedAt == null) return null;
    return now.difference(lastPracticedAt!).inDays;
  }

  SkillEntry copyWith({
    String? id,
    String? name,
    SkillCategory? category,
    ProficiencyLevel? currentLevel,
    ProficiencyLevel? targetLevel,
    DateTime? startedAt,
    DateTime? lastPracticedAt,
    List<PracticeSession>? sessions,
    List<SkillMilestone>? milestones,
    List<String>? tags,
    String? notes,
    bool? isArchived,
    int? weeklyGoalMinutes,
  }) {
    return SkillEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentLevel: currentLevel ?? this.currentLevel,
      targetLevel: targetLevel ?? this.targetLevel,
      startedAt: startedAt ?? this.startedAt,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      sessions: sessions ?? List.from(this.sessions),
      milestones: milestones ?? List.from(this.milestones),
      tags: tags ?? List.from(this.tags),
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      weeklyGoalMinutes: weeklyGoalMinutes ?? this.weeklyGoalMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.index,
    'currentLevel': currentLevel.index,
    'targetLevel': targetLevel.index,
    'startedAt': startedAt.toIso8601String(),
    'lastPracticedAt': lastPracticedAt?.toIso8601String(),
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'milestones': milestones.map((m) => m.toJson()).toList(),
    'tags': tags,
    'notes': notes,
    'isArchived': isArchived,
    'weeklyGoalMinutes': weeklyGoalMinutes,
  };

  factory SkillEntry.fromJson(Map<String, dynamic> json) {
    return SkillEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      category: SkillCategory.values[json['category'] as int],
      currentLevel: ProficiencyLevel.values[json['currentLevel'] as int],
      targetLevel: ProficiencyLevel.values[json['targetLevel'] as int],
      startedAt: DateTime.parse(json['startedAt'] as String),
      lastPracticedAt: json['lastPracticedAt'] != null
          ? DateTime.parse(json['lastPracticedAt'] as String)
          : null,
      sessions: (json['sessions'] as List<dynamic>?)
          ?.map((e) => PracticeSession.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      milestones: (json['milestones'] as List<dynamic>?)
          ?.map((e) => SkillMilestone.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      notes: json['notes'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
      weeklyGoalMinutes: json['weeklyGoalMinutes'] as int? ?? 120,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SkillEntry.fromJsonString(String s) =>
      SkillEntry.fromJson(jsonDecode(s) as Map<String, dynamic>);

  @override
  String toString() =>
      '${category.emoji} $name (${currentLevel.label} → ${targetLevel.label}) - ${totalHours}h';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SkillEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
