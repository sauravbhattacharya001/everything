/// Achievement Service — gamification layer that awards badges based on
/// milestones across all trackers (habits, events, goals, mood, sleep,
/// fitness, nutrition, productivity, social, learning).
///
/// Features:
///   - **40 built-in achievements** across 12 categories and 5 tiers
///   - **Progress tracking** toward each achievement
///   - **Newly unlocked detection** for UI notifications
///   - **Point scoring** with tier-based point values
///   - **Level system** based on total points
///   - **Category completion** tracking
///   - **Summary statistics** and text report
///   - **JSON persistence** for earned achievements
///   - **Custom achievement** registration

import 'dart:convert';

import '../../models/achievement.dart';

// ─── Built-in Achievement Definitions ────────────────────────────

/// All 40 built-in achievements.
const List<AchievementDefinition> builtInAchievements = [
  // ── Habits (4) ──
  AchievementDefinition(
    id: 'habit_first',
    name: 'Creature of Habit',
    description: 'Complete your first habit',
    category: AchievementCategory.habits,
    tier: AchievementTier.bronze,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'habit_50',
    name: 'Habitual',
    description: 'Complete 50 habit entries',
    category: AchievementCategory.habits,
    tier: AchievementTier.silver,
    threshold: 50,
  ),
  AchievementDefinition(
    id: 'habit_500',
    name: 'Habit Machine',
    description: 'Complete 500 habit entries',
    category: AchievementCategory.habits,
    tier: AchievementTier.gold,
    threshold: 500,
  ),
  AchievementDefinition(
    id: 'habit_master',
    name: 'Habit Grandmaster',
    description: 'Complete 2,000 habit entries',
    category: AchievementCategory.habits,
    tier: AchievementTier.diamond,
    threshold: 2000,
  ),

  // ── Events (3) ──
  AchievementDefinition(
    id: 'event_first',
    name: 'Getting Started',
    description: 'Create your first event',
    category: AchievementCategory.events,
    tier: AchievementTier.bronze,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'event_100',
    name: 'Event Planner',
    description: 'Create 100 events',
    category: AchievementCategory.events,
    tier: AchievementTier.silver,
    threshold: 100,
  ),
  AchievementDefinition(
    id: 'event_1000',
    name: 'Master Scheduler',
    description: 'Create 1,000 events',
    category: AchievementCategory.events,
    tier: AchievementTier.gold,
    threshold: 1000,
  ),

  // ── Goals (4) ──
  AchievementDefinition(
    id: 'goal_first',
    name: 'Dreamer',
    description: 'Set your first goal',
    category: AchievementCategory.goals,
    tier: AchievementTier.bronze,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'goal_complete_first',
    name: 'Goal Getter',
    description: 'Complete your first goal',
    category: AchievementCategory.goals,
    tier: AchievementTier.silver,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'goal_complete_10',
    name: 'Unstoppable',
    description: 'Complete 10 goals',
    category: AchievementCategory.goals,
    tier: AchievementTier.gold,
    threshold: 10,
  ),
  AchievementDefinition(
    id: 'goal_complete_50',
    name: 'Legend',
    description: 'Complete 50 goals',
    category: AchievementCategory.goals,
    tier: AchievementTier.platinum,
    threshold: 50,
  ),

  // ── Mood (3) ──
  AchievementDefinition(
    id: 'mood_first',
    name: 'Self-Aware',
    description: 'Log your first mood entry',
    category: AchievementCategory.mood,
    tier: AchievementTier.bronze,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'mood_30',
    name: 'Emotionally Literate',
    description: 'Log 30 mood entries',
    category: AchievementCategory.mood,
    tier: AchievementTier.silver,
    threshold: 30,
  ),
  AchievementDefinition(
    id: 'mood_365',
    name: 'Year of Feelings',
    description: 'Log 365 mood entries',
    category: AchievementCategory.mood,
    tier: AchievementTier.platinum,
    threshold: 365,
  ),

  // ── Sleep (3) ──
  AchievementDefinition(
    id: 'sleep_first',
    name: 'Tracking Zzz',
    description: 'Log your first sleep entry',
    category: AchievementCategory.sleep,
    tier: AchievementTier.bronze,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'sleep_quality_streak',
    name: 'Well Rested',
    description: 'Log 7 consecutive nights with quality ≥ 4',
    category: AchievementCategory.sleep,
    tier: AchievementTier.gold,
    threshold: 7,
  ),
  AchievementDefinition(
    id: 'sleep_100',
    name: 'Sleep Scholar',
    description: 'Log 100 sleep entries',
    category: AchievementCategory.sleep,
    tier: AchievementTier.silver,
    threshold: 100,
  ),

  // ── Fitness (4) ──
  AchievementDefinition(
    id: 'workout_first',
    name: 'First Rep',
    description: 'Log your first workout',
    category: AchievementCategory.fitness,
    tier: AchievementTier.bronze,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'workout_50',
    name: 'Gym Regular',
    description: 'Log 50 workouts',
    category: AchievementCategory.fitness,
    tier: AchievementTier.silver,
    threshold: 50,
  ),
  AchievementDefinition(
    id: 'workout_200',
    name: 'Iron Will',
    description: 'Log 200 workouts',
    category: AchievementCategory.fitness,
    tier: AchievementTier.gold,
    threshold: 200,
  ),
  AchievementDefinition(
    id: 'workout_minutes_1000',
    name: 'Endurance King',
    description: 'Accumulate 1,000 workout minutes',
    category: AchievementCategory.fitness,
    tier: AchievementTier.platinum,
    threshold: 1000,
  ),

  // ── Nutrition (3) ──
  AchievementDefinition(
    id: 'meal_first',
    name: 'Food Logger',
    description: 'Log your first meal',
    category: AchievementCategory.nutrition,
    tier: AchievementTier.bronze,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'water_hydrated',
    name: 'Hydrated',
    description: 'Meet your daily water goal 7 days in a row',
    category: AchievementCategory.nutrition,
    tier: AchievementTier.silver,
    threshold: 7,
  ),
  AchievementDefinition(
    id: 'meal_100',
    name: 'Nutrition Nerd',
    description: 'Log 100 meals',
    category: AchievementCategory.nutrition,
    tier: AchievementTier.gold,
    threshold: 100,
  ),

  // ── Productivity (4) ──
  AchievementDefinition(
    id: 'pomodoro_first',
    name: 'Focused',
    description: 'Complete your first Pomodoro session',
    category: AchievementCategory.productivity,
    tier: AchievementTier.bronze,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'pomodoro_100',
    name: 'Deep Worker',
    description: 'Complete 100 Pomodoro sessions',
    category: AchievementCategory.productivity,
    tier: AchievementTier.silver,
    threshold: 100,
  ),
  AchievementDefinition(
    id: 'focus_hours_100',
    name: 'Flow State',
    description: 'Accumulate 100 focus hours',
    category: AchievementCategory.productivity,
    tier: AchievementTier.gold,
    threshold: 100,
  ),
  AchievementDefinition(
    id: 'daily_review_30',
    name: 'Reflector',
    description: 'Complete 30 daily reviews',
    category: AchievementCategory.productivity,
    tier: AchievementTier.silver,
    threshold: 30,
  ),

  // ── Social (3) ──
  AchievementDefinition(
    id: 'contact_first',
    name: 'Networker',
    description: 'Add your first contact',
    category: AchievementCategory.social,
    tier: AchievementTier.bronze,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'event_share_first',
    name: 'Sharing is Caring',
    description: 'Share your first event',
    category: AchievementCategory.social,
    tier: AchievementTier.bronze,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'contact_50',
    name: 'Social Butterfly',
    description: 'Track 50 contacts',
    category: AchievementCategory.social,
    tier: AchievementTier.silver,
    threshold: 50,
  ),

  // ── Learning (3) ──
  AchievementDefinition(
    id: 'book_first',
    name: 'Bookworm',
    description: 'Add your first book to the reading list',
    category: AchievementCategory.learning,
    tier: AchievementTier.bronze,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'book_finished_10',
    name: 'Well Read',
    description: 'Finish 10 books',
    category: AchievementCategory.learning,
    tier: AchievementTier.silver,
    threshold: 10,
  ),
  AchievementDefinition(
    id: 'skill_level_up',
    name: 'Level Up',
    description: 'Advance a skill to level 5',
    category: AchievementCategory.learning,
    tier: AchievementTier.gold,
    threshold: 5,
  ),

  // ── Streaks (3) ──
  AchievementDefinition(
    id: 'streak_7',
    name: 'On Fire',
    description: 'Maintain a 7-day activity streak',
    category: AchievementCategory.streaks,
    tier: AchievementTier.bronze,
    threshold: 7,
    repeatable: true,
  ),
  AchievementDefinition(
    id: 'streak_30',
    name: 'Committed',
    description: 'Maintain a 30-day activity streak',
    category: AchievementCategory.streaks,
    tier: AchievementTier.silver,
    threshold: 30,
  ),
  AchievementDefinition(
    id: 'streak_100',
    name: 'Centurion',
    description: 'Maintain a 100-day activity streak',
    category: AchievementCategory.streaks,
    tier: AchievementTier.gold,
    threshold: 100,
  ),

  // ── Special (3) ──
  AchievementDefinition(
    id: 'first_day',
    name: 'Day One',
    description: 'Use the app for the first time',
    category: AchievementCategory.special,
    tier: AchievementTier.bronze,
  ),
  AchievementDefinition(
    id: 'all_trackers',
    name: 'Renaissance',
    description: 'Use at least 8 different tracker types',
    category: AchievementCategory.special,
    tier: AchievementTier.platinum,
    threshold: 8,
  ),
  AchievementDefinition(
    id: 'points_1000',
    name: 'Overachiever',
    description: 'Earn 1,000 achievement points',
    category: AchievementCategory.special,
    tier: AchievementTier.diamond,
    threshold: 1000,
  ),
];

// ─── Level System ────────────────────────────────────────────────

/// Calculate user level from total achievement points.
///
/// Levels use a quadratic curve: level N requires N*50 cumulative points.
///   Level 1:   0 pts
///   Level 2:  50 pts
///   Level 3: 150 pts
///   Level 4: 300 pts
///   ...
class UserLevel {
  final int level;
  final int totalPoints;
  final int pointsForNextLevel;
  final int pointsInCurrentLevel;

  const UserLevel({
    required this.level,
    required this.totalPoints,
    required this.pointsForNextLevel,
    required this.pointsInCurrentLevel,
  });

  /// Progress toward next level as 0.0–1.0.
  double get progressToNext {
    if (pointsForNextLevel == 0) return 1.0;
    final needed = pointsForNextLevel - _cumulativeForLevel(level);
    if (needed <= 0) return 1.0;
    return pointsInCurrentLevel / needed;
  }

  /// Title based on level range.
  String get title {
    if (level >= 20) return 'Grandmaster';
    if (level >= 15) return 'Master';
    if (level >= 10) return 'Expert';
    if (level >= 7) return 'Advanced';
    if (level >= 4) return 'Intermediate';
    if (level >= 2) return 'Beginner';
    return 'Newcomer';
  }

  static int _cumulativeForLevel(int level) {
    // Sum of 50*i for i=1..level-1 = 50 * (level-1)*level/2
    if (level <= 1) return 0;
    return 50 * (level - 1) * level ~/ 2;
  }

  /// Compute level from total points.
  factory UserLevel.fromPoints(int points) {
    if (points < 0) points = 0;
    // Find level: cumulative(level) <= points < cumulative(level+1)
    int level = 1;
    while (_cumulativeForLevel(level + 1) <= points) {
      level++;
      if (level > 100) break; // safety cap
    }
    final currentLevelStart = _cumulativeForLevel(level);
    final nextLevelStart = _cumulativeForLevel(level + 1);
    return UserLevel(
      level: level,
      totalPoints: points,
      pointsForNextLevel: nextLevelStart,
      pointsInCurrentLevel: points - currentLevelStart,
    );
  }
}

// ─── Achievement Summary ─────────────────────────────────────────

/// Overall achievement statistics.
class AchievementSummary {
  final int totalDefined;
  final int totalEarned;
  final int totalPoints;
  final UserLevel level;
  final Map<AchievementCategory, int> earnedByCategory;
  final Map<AchievementCategory, int> totalByCategory;
  final Map<AchievementTier, int> earnedByTier;
  final List<EarnedAchievement> recentUnlocks;

  const AchievementSummary({
    required this.totalDefined,
    required this.totalEarned,
    required this.totalPoints,
    required this.level,
    required this.earnedByCategory,
    required this.totalByCategory,
    required this.earnedByTier,
    required this.recentUnlocks,
  });

  /// Completion percentage (0.0–1.0).
  double get completionRate =>
      totalDefined == 0 ? 0.0 : totalEarned / totalDefined;
}

// ─── Main Service ────────────────────────────────────────────────

/// Manages achievement definitions, progress evaluation, and earned records.
class AchievementService {
  final List<AchievementDefinition> _definitions;

  /// O(1) lookup index from achievement ID → definition.
  ///
  /// Rebuilt whenever definitions are added via [register].
  final Map<String, AchievementDefinition> _definitionIndex;

  final Map<String, EarnedAchievement> _earned;

  /// Current progress values keyed by achievement ID.
  /// Call [updateProgress] to set these before [evaluate].
  final Map<String, int> _progressValues;

  AchievementService({
    List<AchievementDefinition>? definitions,
    List<EarnedAchievement>? earned,
  })  : _definitions = definitions ?? List.of(builtInAchievements),
        _definitionIndex = {},
        _earned = {},
        _progressValues = {} {
    _rebuildIndex();
    if (earned != null) {
      for (final e in earned) {
        _earned[e.achievementId] = e;
      }
    }
  }

  /// Rebuild the ID → definition index from the current definitions list.
  void _rebuildIndex() {
    _definitionIndex.clear();
    for (final def in _definitions) {
      _definitionIndex[def.id] = def;
    }
  }

  /// Look up a definition by ID, or null if not registered.
  AchievementDefinition? _findDefinition(String id) => _definitionIndex[id];

  // ── Registration ──

  /// Register a custom achievement definition.
  /// Returns false if an achievement with that ID already exists.
  bool register(AchievementDefinition definition) {
    if (_definitionIndex.containsKey(definition.id)) return false;
    _definitions.add(definition);
    _definitionIndex[definition.id] = definition;
    return true;
  }

  /// All registered definitions.
  List<AchievementDefinition> get definitions =>
      List.unmodifiable(_definitions);

  /// All earned achievements.
  List<EarnedAchievement> get earned =>
      List.unmodifiable(_earned.values.toList());

  /// Check if a specific achievement has been earned.
  bool isEarned(String achievementId) => _earned.containsKey(achievementId);

  // ── Progress ──

  /// Set the current progress value for an achievement.
  void updateProgress(String achievementId, int value) {
    _progressValues[achievementId] = value;
  }

  /// Bulk-update progress from a map.
  void updateProgressBatch(Map<String, int> values) {
    _progressValues.addAll(values);
  }

  /// Get current progress value for an achievement (0 if unset).
  int getProgress(String achievementId) => _progressValues[achievementId] ?? 0;

  /// Get detailed progress for a specific achievement.
  AchievementProgress? getAchievementProgress(String achievementId) {
    final def = _findDefinition(achievementId);
    if (def == null) return null;
    final earnedRecord = _earned[achievementId];
    return AchievementProgress(
      definition: def,
      current: _progressValues[achievementId] ?? 0,
      isEarned: earnedRecord != null,
      earnedAt: earnedRecord?.earnedAt,
      timesEarned: earnedRecord?.timesEarned ?? 0,
    );
  }

  /// Get progress for all achievements.
  List<AchievementProgress> getAllProgress() {
    return _definitions.map((def) {
      final earnedRecord = _earned[def.id];
      return AchievementProgress(
        definition: def,
        current: _progressValues[def.id] ?? 0,
        isEarned: earnedRecord != null,
        earnedAt: earnedRecord?.earnedAt,
        timesEarned: earnedRecord?.timesEarned ?? 0,
      );
    }).toList();
  }

  /// Get progress for a specific category.
  List<AchievementProgress> getProgressByCategory(
      AchievementCategory category) {
    return getAllProgress()
        .where((p) => p.definition.category == category)
        .toList();
  }

  /// Get progress for a specific tier.
  List<AchievementProgress> getProgressByTier(AchievementTier tier) {
    return getAllProgress()
        .where((p) => p.definition.tier == tier)
        .toList();
  }

  // ── Evaluation ──

  /// Evaluate all achievements against current progress.
  /// Returns a list of **newly unlocked** achievements (those that
  /// weren't earned before this call but now meet their threshold).
  ///
  /// [now] defaults to [DateTime.now] and is used as the earned timestamp.
  List<AchievementDefinition> evaluate({DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    final newlyUnlocked = <AchievementDefinition>[];

    for (final def in _definitions) {
      final progress = _progressValues[def.id] ?? 0;
      final existing = _earned[def.id];

      // Boolean achievements (no threshold)
      if (def.threshold == null) {
        // Must be awarded explicitly via [award]
        continue;
      }

      final meetsThreshold = progress >= def.threshold!;

      if (meetsThreshold) {
        if (existing == null) {
          // First time earning
          _earned[def.id] = EarnedAchievement(
            achievementId: def.id,
            earnedAt: timestamp,
            progressAtEarning: progress,
            timesEarned: 1,
          );
          newlyUnlocked.add(def);
        } else if (def.repeatable) {
          // Re-earn: increment count
          _earned[def.id] = existing.copyWith(
            earnedAt: timestamp,
            progressAtEarning: progress,
            timesEarned: existing.timesEarned + 1,
          );
          newlyUnlocked.add(def);
        }
        // else: already earned, not repeatable — skip
      }
    }

    return newlyUnlocked;
  }

  /// Manually award a boolean (threshold-less) achievement.
  /// Returns true if newly awarded, false if already earned.
  bool award(String achievementId, {DateTime? now}) {
    final def = _findDefinition(achievementId);
    if (def == null) return false;
    if (_earned.containsKey(achievementId) && !def.repeatable) return false;

    final timestamp = now ?? DateTime.now();
    final existing = _earned[achievementId];
    if (existing != null && def.repeatable) {
      _earned[achievementId] = existing.copyWith(
        earnedAt: timestamp,
        timesEarned: existing.timesEarned + 1,
      );
    } else {
      _earned[achievementId] = EarnedAchievement(
        achievementId: achievementId,
        earnedAt: timestamp,
        timesEarned: 1,
      );
    }
    return true;
  }

  /// Revoke an earned achievement. Returns true if it was earned.
  bool revoke(String achievementId) {
    return _earned.remove(achievementId) != null;
  }

  // ── Scoring ──

  /// Total points from all earned achievements.
  int get totalPoints {
    int points = 0;
    for (final entry in _earned.entries) {
      final def = _findDefinition(entry.key);
      if (def != null) {
        points += def.tier.points * entry.value.timesEarned;
      }
    }
    return points;
  }

  /// Current user level based on total points.
  UserLevel get userLevel => UserLevel.fromPoints(totalPoints);

  // ── Summary ──

  /// Generate a comprehensive achievement summary.
  AchievementSummary getSummary({int recentCount = 5}) {
    final earnedByCategory = <AchievementCategory, int>{};
    final totalByCategory = <AchievementCategory, int>{};
    final earnedByTier = <AchievementTier, int>{};

    for (final cat in AchievementCategory.values) {
      totalByCategory[cat] = 0;
      earnedByCategory[cat] = 0;
    }
    for (final tier in AchievementTier.values) {
      earnedByTier[tier] = 0;
    }

    for (final def in _definitions) {
      totalByCategory[def.category] =
          (totalByCategory[def.category] ?? 0) + 1;

      final earnedRecord = _earned[def.id];
      if (earnedRecord != null) {
        earnedByCategory[def.category] =
            (earnedByCategory[def.category] ?? 0) + 1;
        earnedByTier[def.tier] = (earnedByTier[def.tier] ?? 0) + 1;
      }
    }

    // Recent unlocks sorted by date descending
    final sortedEarned = _earned.values.toList()
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    final recent = sortedEarned.take(recentCount).toList();

    return AchievementSummary(
      totalDefined: _definitions.length,
      totalEarned: _earned.length,
      totalPoints: totalPoints,
      level: userLevel,
      earnedByCategory: earnedByCategory,
      totalByCategory: totalByCategory,
      earnedByTier: earnedByTier,
      recentUnlocks: recent,
    );
  }

  /// Text report of achievement status.
  String generateReport() {
    final summary = getSummary();
    final buf = StringBuffer();

    buf.writeln('═══ Achievement Report ═══');
    buf.writeln();
    buf.writeln(
        'Level ${summary.level.level} ${summary.level.title} (${summary.totalPoints} pts)');
    buf.writeln(
        'Achievements: ${summary.totalEarned}/${summary.totalDefined} (${(summary.completionRate * 100).toStringAsFixed(1)}%)');
    buf.writeln();

    // By category
    buf.writeln('── By Category ──');
    for (final cat in AchievementCategory.values) {
      final earned = summary.earnedByCategory[cat] ?? 0;
      final total = summary.totalByCategory[cat] ?? 0;
      if (total == 0) continue;
      buf.writeln('  ${cat.emoji} ${cat.label}: $earned/$total');
    }
    buf.writeln();

    // By tier
    buf.writeln('── By Tier ──');
    for (final tier in AchievementTier.values) {
      final count = summary.earnedByTier[tier] ?? 0;
      buf.writeln('  ${tier.emoji} ${tier.label}: $count');
    }
    buf.writeln();

    // Recent unlocks
    if (summary.recentUnlocks.isNotEmpty) {
      buf.writeln('── Recent Unlocks ──');
      for (final unlock in summary.recentUnlocks) {
        final def = _findDefinition(unlock.achievementId);
        if (def != null) {
          buf.writeln(
              '  ${def.displayIcon} ${def.name} — ${def.description}');
        }
      }
    }

    // Near-completion (>= 75% progress, not yet earned)
    final nearComplete = getAllProgress()
        .where((p) =>
            !p.isEarned &&
            p.definition.threshold != null &&
            p.fraction >= 0.75)
        .toList()
      ..sort((a, b) => b.fraction.compareTo(a.fraction));

    if (nearComplete.isNotEmpty) {
      buf.writeln();
      buf.writeln('── Almost There ──');
      for (final p in nearComplete.take(5)) {
        buf.writeln(
            '  ${p.definition.displayIcon} ${p.definition.name}: ${p.progressLabel} (${p.percentLabel})');
      }
    }

    return buf.toString();
  }

  // ── Persistence ──

  /// Serialize earned achievements to JSON string.
  String toJson() {
    final list = _earned.values.map((e) => e.toJson()).toList();
    return jsonEncode(list);
  }

  /// Maximum entries allowed via [loadFromJson].
  ///
  /// Prevents memory exhaustion from a maliciously crafted JSON payload
  /// containing millions of entries.
  static const int maxImportEntries = 50000;

  /// Load earned achievements from JSON string.
  /// Replaces current earned state.
  void loadFromJson(String jsonStr) {
    // Parse into a temporary map first so that malformed JSON doesn't
    // wipe existing earned achievements.
    final parsed = <String, EarnedAchievement>{};
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      if (list.length > maxImportEntries) {
        throw ArgumentError(
          'Import exceeds maximum of $maxImportEntries entries '
          '(got ${list.length}). This limit prevents memory exhaustion '
          'from corrupted or malicious data.',
        );
      }
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final ea = EarnedAchievement.fromJson(item);
          parsed[ea.achievementId] = ea;
        }
      }
    } on ArgumentError {
      rethrow;
    } catch (_) {
      // Silently ignore corrupt data — preserve existing state
      return;
    }
    // All parsed successfully — safe to apply.
    _earned.clear();
    _earned.addAll(parsed);
  }

  /// Export all definitions to JSON (for backup/sync).
  String definitionsToJson() {
    return jsonEncode(_definitions.map((d) => d.toJson()).toList());
  }
}
