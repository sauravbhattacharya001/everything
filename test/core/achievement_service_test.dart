import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/achievement.dart';
import 'package:everything/core/services/achievement_service.dart';

void main() {
  // ─── Model Tests ───────────────────────────────────────────────

  group('AchievementCategory', () {
    test('all categories have labels', () {
      for (final cat in AchievementCategory.values) {
        expect(cat.label.isNotEmpty, isTrue);
      }
    });

    test('all categories have emoji', () {
      for (final cat in AchievementCategory.values) {
        expect(cat.emoji.isNotEmpty, isTrue);
      }
    });

    test('labels are human-readable', () {
      expect(AchievementCategory.habits.label, 'Habits');
      expect(AchievementCategory.fitness.label, 'Fitness');
      expect(AchievementCategory.special.label, 'Special');
    });
  });

  group('AchievementTier', () {
    test('all tiers have labels and emoji', () {
      for (final tier in AchievementTier.values) {
        expect(tier.label.isNotEmpty, isTrue);
        expect(tier.emoji.isNotEmpty, isTrue);
      }
    });

    test('points increase with tier', () {
      expect(AchievementTier.bronze.points, 10);
      expect(AchievementTier.silver.points, 25);
      expect(AchievementTier.gold.points, 50);
      expect(AchievementTier.platinum.points, 100);
      expect(AchievementTier.diamond.points, 250);
    });

    test('tiers are ordered by value', () {
      final points =
          AchievementTier.values.map((t) => t.points).toList();
      for (int i = 1; i < points.length; i++) {
        expect(points[i], greaterThan(points[i - 1]));
      }
    });
  });

  group('AchievementDefinition', () {
    test('serialization round-trip', () {
      const def = AchievementDefinition(
        id: 'test_1',
        name: 'Test',
        description: 'A test achievement',
        category: AchievementCategory.habits,
        tier: AchievementTier.gold,
        threshold: 10,
        repeatable: true,
        icon: '🧪',
      );
      final json = def.toJson();
      final restored = AchievementDefinition.fromJson(json);
      expect(restored.id, def.id);
      expect(restored.name, def.name);
      expect(restored.description, def.description);
      expect(restored.category, def.category);
      expect(restored.tier, def.tier);
      expect(restored.threshold, def.threshold);
      expect(restored.repeatable, def.repeatable);
      expect(restored.icon, def.icon);
    });

    test('displayIcon uses custom icon when set', () {
      const def = AchievementDefinition(
        id: 'x',
        name: 'X',
        description: 'd',
        category: AchievementCategory.habits,
        tier: AchievementTier.bronze,
        icon: '🧪',
      );
      expect(def.displayIcon, '🧪');
    });

    test('displayIcon falls back to category emoji', () {
      const def = AchievementDefinition(
        id: 'x',
        name: 'X',
        description: 'd',
        category: AchievementCategory.fitness,
        tier: AchievementTier.bronze,
      );
      expect(def.displayIcon, AchievementCategory.fitness.emoji);
    });

    test('fromJson handles unknown category gracefully', () {
      final def = AchievementDefinition.fromJson({
        'id': 'x',
        'name': 'X',
        'description': 'd',
        'category': 'nonexistent',
        'tier': 'bronze',
      });
      expect(def.category, AchievementCategory.special);
    });

    test('fromJson handles unknown tier gracefully', () {
      final def = AchievementDefinition.fromJson({
        'id': 'x',
        'name': 'X',
        'description': 'd',
        'category': 'habits',
        'tier': 'mythic',
      });
      expect(def.tier, AchievementTier.bronze);
    });

    test('fromJson defaults repeatable to false', () {
      final def = AchievementDefinition.fromJson({
        'id': 'x',
        'name': 'X',
        'description': 'd',
        'category': 'habits',
        'tier': 'bronze',
      });
      expect(def.repeatable, isFalse);
    });
  });

  group('EarnedAchievement', () {
    test('serialization round-trip', () {
      final ea = EarnedAchievement(
        achievementId: 'test_1',
        earnedAt: DateTime(2026, 3, 6),
        progressAtEarning: 15,
        timesEarned: 3,
      );
      final json = ea.toJson();
      final restored = EarnedAchievement.fromJson(json);
      expect(restored.achievementId, ea.achievementId);
      expect(restored.earnedAt.year, 2026);
      expect(restored.progressAtEarning, 15);
      expect(restored.timesEarned, 3);
    });

    test('copyWith preserves unchanged fields', () {
      final ea = EarnedAchievement(
        achievementId: 'a',
        earnedAt: DateTime(2026, 1, 1),
        timesEarned: 2,
      );
      final updated = ea.copyWith(timesEarned: 5);
      expect(updated.achievementId, 'a');
      expect(updated.timesEarned, 5);
      expect(updated.earnedAt, ea.earnedAt);
    });

    test('fromJson defaults timesEarned to 1', () {
      final ea = EarnedAchievement.fromJson({
        'achievementId': 'x',
        'earnedAt': '2026-03-06T00:00:00.000',
      });
      expect(ea.timesEarned, 1);
    });

    test('fromJson handles missing earnedAt', () {
      final ea = EarnedAchievement.fromJson({
        'achievementId': 'x',
      });
      // Should default to now, not crash
      expect(ea.achievementId, 'x');
      expect(ea.earnedAt.year, greaterThanOrEqualTo(2026));
    });
  });

  group('AchievementProgress', () {
    test('fraction for threshold-based achievement', () {
      const def = AchievementDefinition(
        id: 'x',
        name: 'X',
        description: 'd',
        category: AchievementCategory.habits,
        tier: AchievementTier.bronze,
        threshold: 10,
      );
      const progress = AchievementProgress(
        definition: def,
        current: 7,
      );
      expect(progress.fraction, closeTo(0.7, 0.001));
      expect(progress.percentLabel, '70%');
      expect(progress.progressLabel, '7 / 10');
    });

    test('fraction caps at 1.0', () {
      const def = AchievementDefinition(
        id: 'x',
        name: 'X',
        description: 'd',
        category: AchievementCategory.habits,
        tier: AchievementTier.bronze,
        threshold: 5,
      );
      const progress = AchievementProgress(
        definition: def,
        current: 20,
      );
      expect(progress.fraction, 1.0);
    });

    test('fraction for boolean achievement earned', () {
      const def = AchievementDefinition(
        id: 'x',
        name: 'X',
        description: 'd',
        category: AchievementCategory.special,
        tier: AchievementTier.bronze,
      );
      const progress = AchievementProgress(
        definition: def,
        current: 0,
        isEarned: true,
      );
      expect(progress.fraction, 1.0);
      expect(progress.progressLabel, 'Unlocked');
    });

    test('fraction for boolean achievement not earned', () {
      const def = AchievementDefinition(
        id: 'x',
        name: 'X',
        description: 'd',
        category: AchievementCategory.special,
        tier: AchievementTier.bronze,
      );
      const progress = AchievementProgress(
        definition: def,
        current: 0,
        isEarned: false,
      );
      expect(progress.fraction, 0.0);
      expect(progress.progressLabel, 'Locked');
    });

    test('fraction handles zero threshold', () {
      const def = AchievementDefinition(
        id: 'x',
        name: 'X',
        description: 'd',
        category: AchievementCategory.habits,
        tier: AchievementTier.bronze,
        threshold: 0,
      );
      const progress = AchievementProgress(definition: def, current: 0);
      expect(progress.fraction, 1.0);
    });
  });

  // ─── UserLevel Tests ──────────────────────────────────────────

  group('UserLevel', () {
    test('level 1 at 0 points', () {
      final level = UserLevel.fromPoints(0);
      expect(level.level, 1);
      expect(level.title, 'Newcomer');
    });

    test('level 2 at 50 points', () {
      final level = UserLevel.fromPoints(50);
      expect(level.level, 2);
      expect(level.title, 'Beginner');
    });

    test('level 3 at 150 points', () {
      final level = UserLevel.fromPoints(150);
      expect(level.level, 3);
    });

    test('level 4 at 300 points', () {
      final level = UserLevel.fromPoints(300);
      expect(level.level, 4);
      expect(level.title, 'Intermediate');
    });

    test('level 7 title is Advanced', () {
      final level = UserLevel.fromPoints(1050);
      expect(level.level, 7);
      expect(level.title, 'Advanced');
    });

    test('level 10 title is Expert', () {
      // cumulative(10) = 50 * 9 * 10 / 2 = 2250
      final level = UserLevel.fromPoints(2250);
      expect(level.level, 10);
      expect(level.title, 'Expert');
    });

    test('level 15 title is Master', () {
      // cumulative(15) = 50 * 14 * 15 / 2 = 5250
      final level = UserLevel.fromPoints(5250);
      expect(level.level, 15);
      expect(level.title, 'Master');
    });

    test('level 20 title is Grandmaster', () {
      // cumulative(20) = 50 * 19 * 20 / 2 = 9500
      final level = UserLevel.fromPoints(9500);
      expect(level.level, 20);
      expect(level.title, 'Grandmaster');
    });

    test('negative points treated as 0', () {
      final level = UserLevel.fromPoints(-100);
      expect(level.level, 1);
      expect(level.totalPoints, 0);
    });

    test('progressToNext between levels', () {
      // Level 2: 50 pts, Level 3: 150 pts, so 100 pts needed
      // At 100 pts: 50 into level 2 range = 50/100 = 0.5
      final level = UserLevel.fromPoints(100);
      expect(level.level, 2);
      expect(level.progressToNext, closeTo(0.5, 0.01));
    });

    test('points just below next level', () {
      final level = UserLevel.fromPoints(49);
      expect(level.level, 1);
    });
  });

  // ─── Service Tests ─────────────────────────────────────────────

  group('AchievementService', () {
    late AchievementService service;

    setUp(() {
      service = AchievementService();
    });

    test('loads 40 built-in definitions', () {
      expect(service.definitions.length, 40);
    });

    test('built-in definitions have unique IDs', () {
      final ids = service.definitions.map((d) => d.id).toSet();
      expect(ids.length, service.definitions.length);
    });

    test('no achievements earned initially', () {
      expect(service.earned, isEmpty);
      expect(service.totalPoints, 0);
    });

    group('register', () {
      test('adds custom achievement', () {
        const custom = AchievementDefinition(
          id: 'custom_1',
          name: 'Custom',
          description: 'A custom achievement',
          category: AchievementCategory.special,
          tier: AchievementTier.gold,
          threshold: 5,
        );
        expect(service.register(custom), isTrue);
        expect(service.definitions.length, 41);
      });

      test('rejects duplicate ID', () {
        expect(service.register(builtInAchievements[0]), isFalse);
        expect(service.definitions.length, 40);
      });
    });

    group('updateProgress', () {
      test('sets progress value', () {
        service.updateProgress('habit_first', 1);
        expect(service.getProgress('habit_first'), 1);
      });

      test('batch update', () {
        service.updateProgressBatch({
          'habit_first': 5,
          'event_first': 10,
        });
        expect(service.getProgress('habit_first'), 5);
        expect(service.getProgress('event_first'), 10);
      });

      test('unset progress returns 0', () {
        expect(service.getProgress('nonexistent'), 0);
      });
    });

    group('evaluate', () {
      test('unlocks achievement when threshold met', () {
        final now = DateTime(2026, 3, 6);
        service.updateProgress('habit_first', 1);
        final unlocked = service.evaluate(now: now);
        expect(unlocked.length, 1);
        expect(unlocked[0].id, 'habit_first');
        expect(service.isEarned('habit_first'), isTrue);
      });

      test('does not unlock below threshold', () {
        service.updateProgress('habit_50', 49);
        final unlocked = service.evaluate();
        expect(
          unlocked.where((d) => d.id == 'habit_50'),
          isEmpty,
        );
        expect(service.isEarned('habit_50'), isFalse);
      });

      test('does not re-unlock non-repeatable', () {
        service.updateProgress('habit_first', 1);
        service.evaluate();
        // Evaluate again — should not re-unlock
        final second = service.evaluate();
        expect(second.where((d) => d.id == 'habit_first'), isEmpty);
      });

      test('re-unlocks repeatable achievements', () {
        service.updateProgress('streak_7', 7);
        final first = service.evaluate();
        expect(first.any((d) => d.id == 'streak_7'), isTrue);
        // Evaluate again — repeatable should re-unlock
        final second = service.evaluate();
        expect(second.any((d) => d.id == 'streak_7'), isTrue);
        expect(service.earned
            .firstWhere((e) => e.achievementId == 'streak_7')
            .timesEarned, 2);
      });

      test('unlocks multiple achievements at once', () {
        service.updateProgressBatch({
          'habit_first': 1,
          'event_first': 1,
          'goal_first': 1,
          'mood_first': 1,
        });
        final unlocked = service.evaluate();
        expect(unlocked.length, 4);
        final ids = unlocked.map((d) => d.id).toSet();
        expect(ids.contains('habit_first'), isTrue);
        expect(ids.contains('event_first'), isTrue);
        expect(ids.contains('goal_first'), isTrue);
        expect(ids.contains('mood_first'), isTrue);
      });

      test('exceeding threshold still unlocks', () {
        service.updateProgress('habit_50', 100);
        final unlocked = service.evaluate();
        expect(unlocked.any((d) => d.id == 'habit_50'), isTrue);
      });
    });

    group('award', () {
      test('awards boolean achievement', () {
        expect(service.award('first_day'), isTrue);
        expect(service.isEarned('first_day'), isTrue);
      });

      test('does not re-award non-repeatable', () {
        service.award('first_day');
        expect(service.award('first_day'), isFalse);
      });

      test('re-awards repeatable', () {
        service.award('streak_7');
        expect(service.award('streak_7'), isTrue);
        expect(service.earned
            .firstWhere((e) => e.achievementId == 'streak_7')
            .timesEarned, 2);
      });

      test('returns false for unknown ID', () {
        expect(service.award('nonexistent'), isFalse);
      });
    });

    group('revoke', () {
      test('removes earned achievement', () {
        service.award('first_day');
        expect(service.revoke('first_day'), isTrue);
        expect(service.isEarned('first_day'), isFalse);
      });

      test('returns false for non-earned', () {
        expect(service.revoke('first_day'), isFalse);
      });
    });

    group('scoring', () {
      test('totalPoints sums tier values', () {
        // Bronze = 10, Silver = 25
        service.award('first_day'); // bronze
        service.updateProgress('habit_first', 1); // bronze
        service.updateProgress('habit_50', 50); // silver
        service.evaluate();
        expect(service.totalPoints, 10 + 10 + 25);
      });

      test('repeatable achievements multiply points', () {
        service.updateProgress('streak_7', 7);
        service.evaluate();
        service.evaluate(); // 2nd time
        // Bronze (10) * 2 times
        final streak = service.earned
            .firstWhere((e) => e.achievementId == 'streak_7');
        expect(streak.timesEarned, 2);
        expect(service.totalPoints, 10 * 2);
      });

      test('userLevel increases with points', () {
        // Award enough for level 2 (50+ pts)
        service.award('first_day'); // 10
        service.updateProgressBatch({
          'habit_first': 1, // 10
          'event_first': 1, // 10
          'goal_first': 1, // 10
          'mood_first': 1, // 10
          'sleep_first': 1, // 10
        });
        service.evaluate();
        expect(service.totalPoints, 60);
        expect(service.userLevel.level, 2);
      });
    });

    group('getAchievementProgress', () {
      test('returns progress for known ID', () {
        service.updateProgress('habit_first', 0);
        final p = service.getAchievementProgress('habit_first');
        expect(p, isNotNull);
        expect(p!.definition.id, 'habit_first');
        expect(p.current, 0);
        expect(p.isEarned, isFalse);
      });

      test('returns null for unknown ID', () {
        expect(service.getAchievementProgress('fake'), isNull);
      });

      test('reflects earned status', () {
        service.updateProgress('habit_first', 1);
        service.evaluate();
        final p = service.getAchievementProgress('habit_first');
        expect(p!.isEarned, isTrue);
      });
    });

    group('getAllProgress', () {
      test('returns progress for all definitions', () {
        final all = service.getAllProgress();
        expect(all.length, 40);
      });
    });

    group('getProgressByCategory', () {
      test('filters by category', () {
        final habits =
            service.getProgressByCategory(AchievementCategory.habits);
        expect(habits.every((p) =>
            p.definition.category == AchievementCategory.habits), isTrue);
        expect(habits.length, 4); // 4 habit achievements
      });
    });

    group('getProgressByTier', () {
      test('filters by tier', () {
        final bronze =
            service.getProgressByTier(AchievementTier.bronze);
        expect(bronze.every((p) =>
            p.definition.tier == AchievementTier.bronze), isTrue);
      });
    });

    group('getSummary', () {
      test('summary with no achievements', () {
        final s = service.getSummary();
        expect(s.totalDefined, 40);
        expect(s.totalEarned, 0);
        expect(s.totalPoints, 0);
        expect(s.completionRate, 0.0);
        expect(s.level.level, 1);
        expect(s.recentUnlocks, isEmpty);
      });

      test('summary after earning achievements', () {
        service.award('first_day');
        service.updateProgressBatch({
          'habit_first': 1,
          'event_first': 1,
        });
        service.evaluate();
        final s = service.getSummary();
        expect(s.totalEarned, 3);
        expect(s.totalPoints, 30);
        expect(s.recentUnlocks.length, 3);
      });

      test('earnedByCategory tracks correctly', () {
        service.updateProgressBatch({
          'habit_first': 1,
          'habit_50': 50,
        });
        service.evaluate();
        final s = service.getSummary();
        expect(s.earnedByCategory[AchievementCategory.habits], 2);
      });

      test('earnedByTier tracks correctly', () {
        service.updateProgress('habit_first', 1); // bronze
        service.updateProgress('habit_50', 50); // silver
        service.evaluate();
        final s = service.getSummary();
        expect(s.earnedByTier[AchievementTier.bronze], 1);
        expect(s.earnedByTier[AchievementTier.silver], 1);
      });

      test('recentUnlocks respects count limit', () {
        // Unlock many
        service.updateProgressBatch({
          'habit_first': 1,
          'event_first': 1,
          'goal_first': 1,
          'mood_first': 1,
          'sleep_first': 1,
          'workout_first': 1,
          'meal_first': 1,
          'pomodoro_first': 1,
        });
        service.evaluate();
        final s = service.getSummary(recentCount: 3);
        expect(s.recentUnlocks.length, 3);
      });
    });

    group('generateReport', () {
      test('report contains key sections', () {
        service.award('first_day');
        service.updateProgress('habit_first', 1);
        service.evaluate();
        final report = service.generateReport();
        expect(report.contains('Achievement Report'), isTrue);
        expect(report.contains('Level'), isTrue);
        expect(report.contains('By Category'), isTrue);
        expect(report.contains('By Tier'), isTrue);
        expect(report.contains('Recent Unlocks'), isTrue);
      });

      test('report shows near-completion', () {
        service.updateProgress('habit_50', 40); // 80%
        service.evaluate();
        final report = service.generateReport();
        expect(report.contains('Almost There'), isTrue);
        expect(report.contains('Habitual'), isTrue);
      });

      test('empty report works', () {
        final report = service.generateReport();
        expect(report.contains('0/40'), isTrue);
        expect(report.contains('Newcomer'), isTrue);
      });
    });

    group('persistence', () {
      test('toJson and loadFromJson round-trip', () {
        service.award('first_day');
        service.updateProgress('habit_first', 1);
        service.evaluate();
        final json = service.toJson();

        final service2 = AchievementService();
        service2.loadFromJson(json);
        expect(service2.isEarned('first_day'), isTrue);
        expect(service2.isEarned('habit_first'), isTrue);
        expect(service2.earned.length, 2);
      });

      test('loadFromJson handles corrupt data', () {
        service.loadFromJson('not valid json!!!');
        expect(service.earned, isEmpty);
      });

      test('loadFromJson handles empty array', () {
        service.loadFromJson('[]');
        expect(service.earned, isEmpty);
      });

      test('loadFromJson replaces existing state', () {
        service.award('first_day');
        service.loadFromJson('[]');
        expect(service.isEarned('first_day'), isFalse);
      });

      test('definitionsToJson exports all', () {
        final json = service.definitionsToJson();
        expect(json.contains('habit_first'), isTrue);
        expect(json.contains('points_1000'), isTrue);
      });
    });

    group('constructor with pre-earned', () {
      test('loads earned achievements from constructor', () {
        final service2 = AchievementService(
          earned: [
            EarnedAchievement(
              achievementId: 'first_day',
              earnedAt: DateTime(2026, 3, 6),
            ),
          ],
        );
        expect(service2.isEarned('first_day'), isTrue);
        expect(service2.totalPoints, 10);
      });
    });
  });

  // ─── Built-in Achievements Integrity ──────────────────────────

  group('Built-in achievements', () {
    test('all IDs are unique', () {
      final ids = builtInAchievements.map((d) => d.id).toSet();
      expect(ids.length, builtInAchievements.length);
    });

    test('all have non-empty name and description', () {
      for (final def in builtInAchievements) {
        expect(def.name.isNotEmpty, isTrue,
            reason: '${def.id} has empty name');
        expect(def.description.isNotEmpty, isTrue,
            reason: '${def.id} has empty description');
      }
    });

    test('thresholds are positive when set', () {
      for (final def in builtInAchievements) {
        if (def.threshold != null) {
          expect(def.threshold, greaterThan(0),
              reason: '${def.id} has non-positive threshold');
        }
      }
    });

    test('exactly 40 achievements defined', () {
      expect(builtInAchievements.length, 40);
    });

    test('covers all 12 categories', () {
      final categories =
          builtInAchievements.map((d) => d.category).toSet();
      expect(categories.length, AchievementCategory.values.length);
    });

    test('covers all 5 tiers', () {
      final tiers = builtInAchievements.map((d) => d.tier).toSet();
      expect(tiers.length, AchievementTier.values.length);
    });

    test('repeatable achievements are only streaks', () {
      final repeatable =
          builtInAchievements.where((d) => d.repeatable).toList();
      for (final def in repeatable) {
        expect(def.id.startsWith('streak'),
            isTrue,
            reason: '${def.id} is repeatable but not a streak');
      }
    });
  });
}
