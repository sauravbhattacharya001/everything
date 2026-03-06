import 'dart:convert';

/// Category grouping related achievements.
enum AchievementCategory {
  habits,
  events,
  goals,
  mood,
  sleep,
  fitness,
  nutrition,
  productivity,
  social,
  learning,
  streaks,
  special;

  String get label {
    switch (this) {
      case AchievementCategory.habits:
        return 'Habits';
      case AchievementCategory.events:
        return 'Events';
      case AchievementCategory.goals:
        return 'Goals';
      case AchievementCategory.mood:
        return 'Mood';
      case AchievementCategory.sleep:
        return 'Sleep';
      case AchievementCategory.fitness:
        return 'Fitness';
      case AchievementCategory.nutrition:
        return 'Nutrition';
      case AchievementCategory.productivity:
        return 'Productivity';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.learning:
        return 'Learning';
      case AchievementCategory.streaks:
        return 'Streaks';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  String get emoji {
    switch (this) {
      case AchievementCategory.habits:
        return '🔁';
      case AchievementCategory.events:
        return '📅';
      case AchievementCategory.goals:
        return '🎯';
      case AchievementCategory.mood:
        return '😊';
      case AchievementCategory.sleep:
        return '😴';
      case AchievementCategory.fitness:
        return '💪';
      case AchievementCategory.nutrition:
        return '🥗';
      case AchievementCategory.productivity:
        return '⚡';
      case AchievementCategory.social:
        return '🤝';
      case AchievementCategory.learning:
        return '📚';
      case AchievementCategory.streaks:
        return '🔥';
      case AchievementCategory.special:
        return '⭐';
    }
  }
}

/// Rarity tier — determines visual styling and point value.
enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond;

  String get label {
    switch (this) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinum:
        return 'Platinum';
      case AchievementTier.diamond:
        return 'Diamond';
    }
  }

  String get emoji {
    switch (this) {
      case AchievementTier.bronze:
        return '🥉';
      case AchievementTier.silver:
        return '🥈';
      case AchievementTier.gold:
        return '🥇';
      case AchievementTier.platinum:
        return '💎';
      case AchievementTier.diamond:
        return '👑';
    }
  }

  /// Point value awarded when this tier is unlocked.
  int get points {
    switch (this) {
      case AchievementTier.bronze:
        return 10;
      case AchievementTier.silver:
        return 25;
      case AchievementTier.gold:
        return 50;
      case AchievementTier.platinum:
        return 100;
      case AchievementTier.diamond:
        return 250;
    }
  }
}

/// Definition of an achievement — the template.
class AchievementDefinition {
  /// Unique identifier (e.g., 'habit_streak_7').
  final String id;

  /// Display name.
  final String name;

  /// How the user earns this achievement.
  final String description;

  /// Grouping category.
  final AchievementCategory category;

  /// Rarity/difficulty tier.
  final AchievementTier tier;

  /// Numeric threshold to unlock (e.g., 7 for "7-day streak").
  /// Null for boolean achievements (one-time triggers).
  final int? threshold;

  /// Whether this achievement can be earned multiple times
  /// (e.g., "Complete 100 events" can be earned once; "Log 7-day streak"
  /// resets if the streak breaks and can be earned again).
  final bool repeatable;

  /// Optional icon override (emoji).
  final String? icon;

  const AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.tier,
    this.threshold,
    this.repeatable = false,
    this.icon,
  });

  /// The emoji to display — custom icon or category default.
  String get displayIcon => icon ?? category.emoji;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.name,
        'tier': tier.name,
        'threshold': threshold,
        'repeatable': repeatable,
        'icon': icon,
      };

  factory AchievementDefinition.fromJson(Map<String, dynamic> json) =>
      AchievementDefinition(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        category: AchievementCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => AchievementCategory.special,
        ),
        tier: AchievementTier.values.firstWhere(
          (t) => t.name == json['tier'],
          orElse: () => AchievementTier.bronze,
        ),
        threshold: json['threshold'] as int?,
        repeatable: json['repeatable'] as bool? ?? false,
        icon: json['icon'] as String?,
      );
}

/// Record of an earned achievement.
class EarnedAchievement {
  /// ID of the [AchievementDefinition] this was earned from.
  final String achievementId;

  /// When it was unlocked.
  final DateTime earnedAt;

  /// The progress value when it was earned (for threshold-based).
  final int? progressAtEarning;

  /// Number of times earned (for repeatable achievements).
  final int timesEarned;

  const EarnedAchievement({
    required this.achievementId,
    required this.earnedAt,
    this.progressAtEarning,
    this.timesEarned = 1,
  });

  EarnedAchievement copyWith({
    DateTime? earnedAt,
    int? progressAtEarning,
    int? timesEarned,
  }) {
    return EarnedAchievement(
      achievementId: achievementId,
      earnedAt: earnedAt ?? this.earnedAt,
      progressAtEarning: progressAtEarning ?? this.progressAtEarning,
      timesEarned: timesEarned ?? this.timesEarned,
    );
  }

  Map<String, dynamic> toJson() => {
        'achievementId': achievementId,
        'earnedAt': earnedAt.toIso8601String(),
        'progressAtEarning': progressAtEarning,
        'timesEarned': timesEarned,
      };

  factory EarnedAchievement.fromJson(Map<String, dynamic> json) =>
      EarnedAchievement(
        achievementId: json['achievementId'] as String,
        earnedAt: DateTime.tryParse(json['earnedAt'] as String? ?? '') ??
            DateTime.now(),
        progressAtEarning: json['progressAtEarning'] as int?,
        timesEarned: json['timesEarned'] as int? ?? 1,
      );
}

/// Current progress toward an achievement.
class AchievementProgress {
  /// The achievement definition.
  final AchievementDefinition definition;

  /// Current progress value.
  final int current;

  /// Whether this achievement has been earned.
  final bool isEarned;

  /// When it was earned (null if not yet).
  final DateTime? earnedAt;

  /// Times earned (for repeatable).
  final int timesEarned;

  const AchievementProgress({
    required this.definition,
    required this.current,
    this.isEarned = false,
    this.earnedAt,
    this.timesEarned = 0,
  });

  /// Progress as a fraction (0.0–1.0). Returns 1.0 for boolean achievements
  /// that are earned, 0.0 for boolean achievements that aren't.
  double get fraction {
    if (definition.threshold == null) {
      return isEarned ? 1.0 : 0.0;
    }
    if (definition.threshold == 0) return 1.0;
    final ratio = current / definition.threshold!;
    return ratio > 1.0 ? 1.0 : ratio;
  }

  /// Percentage string (e.g., "75%").
  String get percentLabel => '${(fraction * 100).round()}%';

  /// Progress label (e.g., "5 / 7" or "Done" / "Locked").
  String get progressLabel {
    if (definition.threshold == null) {
      return isEarned ? 'Unlocked' : 'Locked';
    }
    return '$current / ${definition.threshold}';
  }
}
