import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/goal.dart';

void main() {
  // ── GoalCategory ─────────────────────────────────────────────────

  group('GoalCategory', () {
    test('all categories have non-empty labels', () {
      for (final cat in GoalCategory.values) {
        expect(cat.label, isNotEmpty, reason: '${cat.name} label is empty');
      }
    });

    test('all categories have non-empty emoji', () {
      for (final cat in GoalCategory.values) {
        expect(cat.emoji, isNotEmpty, reason: '${cat.name} emoji is empty');
      }
    });

    test('label returns correct strings', () {
      expect(GoalCategory.health.label, 'Health');
      expect(GoalCategory.career.label, 'Career');
      expect(GoalCategory.finance.label, 'Finance');
      expect(GoalCategory.fitness.label, 'Fitness');
    });

    test('emoji returns correct strings', () {
      expect(GoalCategory.health.emoji, contains('🏥'));
      expect(GoalCategory.career.emoji, contains('💼'));
      expect(GoalCategory.finance.emoji, contains('💰'));
    });
  });

  // ── Milestone ────────────────────────────────────────────────────

  group('Milestone', () {
    test('constructor defaults', () {
      final m = Milestone(id: 'm1', title: 'Do thing');
      expect(m.id, 'm1');
      expect(m.title, 'Do thing');
      expect(m.isCompleted, false);
      expect(m.completedAt, isNull);
    });

    test('copyWith overrides fields', () {
      final m = Milestone(id: 'm1', title: 'Original');
      final now = DateTime(2026, 3, 4);
      final updated = m.copyWith(title: 'Updated', isCompleted: true, completedAt: now);
      expect(updated.title, 'Updated');
      expect(updated.isCompleted, true);
      expect(updated.completedAt, now);
      expect(updated.id, 'm1'); // unchanged
    });

    test('copyWith clearCompletedAt', () {
      final m = Milestone(
        id: 'm1', title: 'T', isCompleted: true, completedAt: DateTime(2026, 1, 1));
      final cleared = m.copyWith(clearCompletedAt: true);
      expect(cleared.completedAt, isNull);
    });

    test('toJson round-trip', () {
      final now = DateTime(2026, 3, 4, 12, 30);
      final m = Milestone(id: 'm1', title: 'Step 1', isCompleted: true, completedAt: now);
      final json = m.toJson();
      final restored = Milestone.fromJson(json);
      expect(restored.id, 'm1');
      expect(restored.title, 'Step 1');
      expect(restored.isCompleted, true);
      expect(restored.completedAt?.year, 2026);
    });

    test('fromJson handles missing completedAt', () {
      final m = Milestone.fromJson({'id': 'm2', 'title': 'Step 2'});
      expect(m.isCompleted, false);
      expect(m.completedAt, isNull);
    });
  });

  // ── Goal construction ────────────────────────────────────────────

  group('Goal construction', () {
    test('defaults', () {
      final g = Goal(id: 'g1', title: 'Test', createdAt: DateTime(2026, 1, 1));
      expect(g.description, '');
      expect(g.category, GoalCategory.personal);
      expect(g.deadline, isNull);
      expect(g.progress, 0);
      expect(g.isCompleted, false);
      expect(g.milestones, isEmpty);
      expect(g.isArchived, false);
    });

    test('copyWith overrides', () {
      final g = Goal(id: 'g1', title: 'Old', createdAt: DateTime(2026, 1, 1));
      final updated = g.copyWith(
        title: 'New',
        category: GoalCategory.fitness,
        progress: 50,
        isCompleted: true,
        isArchived: true,
      );
      expect(updated.title, 'New');
      expect(updated.category, GoalCategory.fitness);
      expect(updated.progress, 50);
      expect(updated.isCompleted, true);
      expect(updated.isArchived, true);
      expect(updated.id, 'g1');
    });

    test('copyWith clearDeadline', () {
      final g = Goal(
        id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1),
        deadline: DateTime(2026, 12, 31));
      final cleared = g.copyWith(clearDeadline: true);
      expect(cleared.deadline, isNull);
    });
  });

  // ── effectiveProgress ────────────────────────────────────────────

  group('effectiveProgress', () {
    test('returns 1.0 when completed', () {
      final g = Goal(
        id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1),
        isCompleted: true, progress: 0);
      expect(g.effectiveProgress, 1.0);
    });

    test('uses manual progress when no milestones', () {
      final g = Goal(
        id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1), progress: 75);
      expect(g.effectiveProgress, 0.75);
    });

    test('uses milestone ratio when milestones exist', () {
      final g = Goal(
        id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1),
        progress: 10, // should be ignored
        milestones: [
          Milestone(id: 'm1', title: 'A', isCompleted: true),
          Milestone(id: 'm2', title: 'B', isCompleted: false),
          Milestone(id: 'm3', title: 'C', isCompleted: true),
        ]);
      expect(g.effectiveProgress, closeTo(2.0 / 3.0, 0.01));
    });

    test('returns 0 when progress is 0 and no milestones', () {
      final g = Goal(id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1));
      expect(g.effectiveProgress, 0.0);
    });

    test('all milestones complete gives 1.0', () {
      final g = Goal(
        id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1),
        milestones: [
          Milestone(id: 'm1', title: 'A', isCompleted: true),
          Milestone(id: 'm2', title: 'B', isCompleted: true),
        ]);
      expect(g.effectiveProgress, 1.0);
    });

    test('no milestones complete gives 0.0', () {
      final g = Goal(
        id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1),
        milestones: [
          Milestone(id: 'm1', title: 'A', isCompleted: false),
        ]);
      expect(g.effectiveProgress, 0.0);
    });
  });

  // ── daysRemaining ────────────────────────────────────────────────

  group('daysRemaining', () {
    test('returns null when no deadline', () {
      final g = Goal(id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1));
      expect(g.daysRemaining, isNull);
    });

    test('returns positive for future deadline', () {
      final g = Goal(
        id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1),
        deadline: DateTime.now().add(const Duration(days: 30)));
      expect(g.daysRemaining, greaterThanOrEqualTo(29));
    });

    test('returns negative for past deadline', () {
      final g = Goal(
        id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1),
        deadline: DateTime(2020, 1, 1));
      expect(g.daysRemaining, lessThan(0));
    });
  });

  // ── isOverdue ────────────────────────────────────────────────────

  group('isOverdue', () {
    test('false when no deadline', () {
      final g = Goal(id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1));
      expect(g.isOverdue, false);
    });

    test('false when completed even if past deadline', () {
      final g = Goal(
        id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1),
        deadline: DateTime(2020, 1, 1), isCompleted: true);
      expect(g.isOverdue, false);
    });

    test('true when past deadline and not completed', () {
      final g = Goal(
        id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1),
        deadline: DateTime(2020, 1, 1), isCompleted: false);
      expect(g.isOverdue, true);
    });

    test('false when future deadline', () {
      final g = Goal(
        id: 'g1', title: 'T', createdAt: DateTime(2026, 1, 1),
        deadline: DateTime.now().add(const Duration(days: 30)));
      expect(g.isOverdue, false);
    });
  });

  // ── Serialization ────────────────────────────────────────────────

  group('Goal serialization', () {
    test('toJson includes all fields', () {
      final g = Goal(
        id: 'g1', title: 'Learn Dart', description: 'A desc',
        category: GoalCategory.education,
        createdAt: DateTime(2026, 3, 4),
        deadline: DateTime(2026, 6, 30),
        progress: 42, isCompleted: false, isArchived: false,
        milestones: [
          Milestone(id: 'm1', title: 'Basics', isCompleted: true),
        ]);

      final json = g.toJson();
      expect(json['id'], 'g1');
      expect(json['title'], 'Learn Dart');
      expect(json['description'], 'A desc');
      expect(json['category'], 'education');
      expect(json['progress'], 42);
      expect(json['isCompleted'], false);
      expect(json['isArchived'], false);
      expect(json['deadline'], contains('2026-06-30'));
      expect(json['milestones'], isA<String>());
    });

    test('fromJson round-trip', () {
      final original = Goal(
        id: 'g1', title: 'Round Trip',
        category: GoalCategory.fitness,
        createdAt: DateTime(2026, 3, 1),
        deadline: DateTime(2026, 12, 31),
        progress: 60, isCompleted: false,
        milestones: [
          Milestone(id: 'm1', title: 'Step 1', isCompleted: true,
            completedAt: DateTime(2026, 3, 2)),
          Milestone(id: 'm2', title: 'Step 2', isCompleted: false),
        ]);

      final json = original.toJson();
      final restored = Goal.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.category, GoalCategory.fitness);
      expect(restored.progress, 60);
      expect(restored.milestones.length, 2);
      expect(restored.milestones[0].isCompleted, true);
      expect(restored.milestones[1].isCompleted, false);
    });

    test('fromJson handles missing optional fields', () {
      final g = Goal.fromJson({
        'id': 'g2',
        'title': 'Minimal',
      });
      expect(g.id, 'g2');
      expect(g.title, 'Minimal');
      expect(g.description, '');
      expect(g.category, GoalCategory.personal);
      expect(g.deadline, isNull);
      expect(g.progress, 0);
      expect(g.isCompleted, false);
      expect(g.milestones, isEmpty);
      expect(g.isArchived, false);
    });

    test('fromJson handles milestones as JSON string', () {
      final milestoneJson = jsonEncode([
        {'id': 'm1', 'title': 'A', 'isCompleted': true},
        {'id': 'm2', 'title': 'B', 'isCompleted': false},
      ]);

      final g = Goal.fromJson({
        'id': 'g3', 'title': 'T',
        'milestones': milestoneJson,
      });
      expect(g.milestones.length, 2);
      expect(g.milestones[0].id, 'm1');
      expect(g.milestones[0].isCompleted, true);
    });

    test('fromJson handles milestones as List', () {
      final g = Goal.fromJson({
        'id': 'g4', 'title': 'T',
        'milestones': [
          {'id': 'm1', 'title': 'A', 'isCompleted': false},
        ],
      });
      expect(g.milestones.length, 1);
    });

    test('fromJson handles invalid milestones string gracefully', () {
      final g = Goal.fromJson({
        'id': 'g5', 'title': 'T',
        'milestones': 'not valid json',
      });
      expect(g.milestones, isEmpty);
    });

    test('fromJson handles empty milestones string', () {
      final g = Goal.fromJson({
        'id': 'g6', 'title': 'T',
        'milestones': '',
      });
      expect(g.milestones, isEmpty);
    });

    test('fromJson unknown category falls back to personal', () {
      final g = Goal.fromJson({
        'id': 'g7', 'title': 'T',
        'category': 'nonexistent_category',
      });
      expect(g.category, GoalCategory.personal);
    });

    test('toJson deadline null omits it', () {
      final g = Goal(id: 'g8', title: 'T', createdAt: DateTime(2026, 1, 1));
      expect(g.toJson()['deadline'], isNull);
    });
  });
}
