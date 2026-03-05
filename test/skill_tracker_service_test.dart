import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/skill_entry.dart';
import 'package:everything/core/services/skill_tracker_service.dart';

void main() {
  late SkillTrackerService service;
  final now = DateTime(2026, 3, 5, 10, 0);

  SkillEntry _makeSkill({
    String id = 'skill-1',
    String name = 'Dart',
    SkillCategory category = SkillCategory.programming,
    ProficiencyLevel currentLevel = ProficiencyLevel.beginner,
    ProficiencyLevel targetLevel = ProficiencyLevel.advanced,
    DateTime? startedAt,
    List<PracticeSession> sessions = const [],
    List<SkillMilestone> milestones = const [],
    List<String> tags = const [],
    int weeklyGoalMinutes = 120,
    bool isArchived = false,
  }) {
    return SkillEntry(
      id: id,
      name: name,
      category: category,
      currentLevel: currentLevel,
      targetLevel: targetLevel,
      startedAt: startedAt ?? DateTime(2026, 1, 1),
      sessions: sessions,
      milestones: milestones,
      tags: tags,
      weeklyGoalMinutes: weeklyGoalMinutes,
      isArchived: isArchived,
    );
  }

  PracticeSession _makeSession({
    String id = 'sess-1',
    DateTime? startTime,
    int durationMinutes = 30,
    String? topic,
    int quality = 3,
  }) {
    return PracticeSession(
      id: id,
      startTime: startTime ?? now.subtract(const Duration(hours: 1)),
      durationMinutes: durationMinutes,
      topic: topic,
      quality: quality,
    );
  }

  setUp(() {
    service = SkillTrackerService();
  });

  group('SkillEntry model', () {
    test('creates with defaults', () {
      final s = _makeSkill();
      expect(s.name, 'Dart');
      expect(s.category, SkillCategory.programming);
      expect(s.currentLevel, ProficiencyLevel.beginner);
      expect(s.isArchived, false);
    });

    test('totalMinutes sums sessions', () {
      final s = _makeSkill(sessions: [
        _makeSession(id: 's1', durationMinutes: 30),
        _makeSession(id: 's2', durationMinutes: 45),
      ]);
      expect(s.totalMinutes, 75);
    });

    test('totalHours rounds correctly', () {
      final s = _makeSkill(sessions: [
        _makeSession(id: 's1', durationMinutes: 90),
      ]);
      expect(s.totalHours, 1.5);
    });

    test('averageQuality computes mean', () {
      final s = _makeSkill(sessions: [
        _makeSession(id: 's1', quality: 4),
        _makeSession(id: 's2', quality: 2),
      ]);
      expect(s.averageQuality, 3.0);
    });

    test('averageQuality returns 0 for empty', () {
      expect(_makeSkill().averageQuality, 0);
    });

    test('levelProgress tracks progress', () {
      final s = _makeSkill(
        currentLevel: ProficiencyLevel.intermediate,
        targetLevel: ProficiencyLevel.expert,
      );
      expect(s.levelProgress, greaterThan(0));
      expect(s.levelProgress, lessThan(1.0));
    });

    test('milestoneProgress computes ratio', () {
      final s = _makeSkill(milestones: [
        SkillMilestone(id: 'm1', title: 'A', completed: true),
        SkillMilestone(id: 'm2', title: 'B', completed: false),
      ]);
      expect(s.milestoneProgress, 0.5);
    });

    test('milestoneProgress returns 0 for empty', () {
      expect(_makeSkill().milestoneProgress, 0);
    });

    test('copyWith preserves values', () {
      final s = _makeSkill(name: 'Dart');
      final s2 = s.copyWith(name: 'Rust');
      expect(s2.name, 'Rust');
      expect(s2.id, s.id);
    });

    test('toJson/fromJson roundtrip', () {
      final s = _makeSkill(
        sessions: [_makeSession()],
        milestones: [SkillMilestone(id: 'm1', title: 'First')],
        tags: ['web'],
        notes: 'hello',
      );
      final json = s.toJson();
      final s2 = SkillEntry.fromJson(json);
      expect(s2.id, s.id);
      expect(s2.name, s.name);
      expect(s2.sessions.length, 1);
      expect(s2.milestones.length, 1);
      expect(s2.tags, ['web']);
      expect(s2.notes, 'hello');
    });

    test('toString includes emoji and name', () {
      final s = _makeSkill();
      expect(s.toString(), contains('Dart'));
    });

    test('equality by id', () {
      final a = _makeSkill(id: 'x');
      final b = _makeSkill(id: 'x', name: 'Different');
      expect(a, equals(b));
    });
  });

  group('PracticeSession model', () {
    test('toJson/fromJson roundtrip', () {
      final s = _makeSession(topic: 'async', quality: 5);
      final s2 = PracticeSession.fromJson(s.toJson());
      expect(s2.id, s.id);
      expect(s2.topic, 'async');
      expect(s2.quality, 5);
    });

    test('equality by id', () {
      final a = _makeSession(id: 'p1');
      final b = _makeSession(id: 'p1', durationMinutes: 99);
      expect(a, equals(b));
    });
  });

  group('SkillMilestone model', () {
    test('toJson/fromJson roundtrip', () {
      final m = SkillMilestone(
        id: 'm1', title: 'Learn basics', description: 'desc',
        completed: true, completedAt: now, orderIndex: 2,
      );
      final m2 = SkillMilestone.fromJson(m.toJson());
      expect(m2.id, 'm1');
      expect(m2.title, 'Learn basics');
      expect(m2.completed, true);
      expect(m2.orderIndex, 2);
    });
  });

  group('ProficiencyLevel', () {
    test('fromValue clamps', () {
      expect(ProficiencyLevel.fromValue(0), ProficiencyLevel.beginner);
      expect(ProficiencyLevel.fromValue(4), ProficiencyLevel.upperIntermediate);
      expect(ProficiencyLevel.fromValue(99), ProficiencyLevel.master);
    });
  });

  group('SkillCategory', () {
    test('all have labels and emojis', () {
      for (final c in SkillCategory.values) {
        expect(c.label.isNotEmpty, true);
        expect(c.emoji.isNotEmpty, true);
      }
    });
  });

  group('CRUD operations', () {
    test('addSkill and getSkill', () {
      service.addSkill(_makeSkill());
      expect(service.skills.length, 1);
      expect(service.getSkill('skill-1')?.name, 'Dart');
    });

    test('addSkill rejects duplicate id', () {
      service.addSkill(_makeSkill());
      expect(() => service.addSkill(_makeSkill()), throwsArgumentError);
    });

    test('getSkill returns null for missing', () {
      expect(service.getSkill('nope'), isNull);
    });

    test('updateSkill replaces', () {
      service.addSkill(_makeSkill());
      service.updateSkill(_makeSkill(name: 'Rust'));
      expect(service.getSkill('skill-1')?.name, 'Rust');
    });

    test('updateSkill throws for missing', () {
      expect(() => service.updateSkill(_makeSkill(id: 'nope')), throwsArgumentError);
    });

    test('removeSkill', () {
      service.addSkill(_makeSkill());
      service.removeSkill('skill-1');
      expect(service.skills, isEmpty);
    });

    test('archiveSkill / unarchiveSkill', () {
      service.addSkill(_makeSkill());
      service.archiveSkill('skill-1');
      expect(service.activeSkills, isEmpty);
      expect(service.archivedSkills.length, 1);
      service.unarchiveSkill('skill-1');
      expect(service.activeSkills.length, 1);
    });

    test('archiveSkill throws for missing', () {
      expect(() => service.archiveSkill('nope'), throwsArgumentError);
    });
  });

  group('Practice sessions', () {
    test('logPractice adds session and updates lastPracticedAt', () {
      service.addSkill(_makeSkill());
      service.logPractice('skill-1', _makeSession());
      final skill = service.getSkill('skill-1')!;
      expect(skill.sessions.length, 1);
      expect(skill.lastPracticedAt, isNotNull);
    });

    test('logPractice throws for missing skill', () {
      expect(() => service.logPractice('nope', _makeSession()), throwsArgumentError);
    });

    test('removePractice removes session', () {
      service.addSkill(_makeSkill());
      service.logPractice('skill-1', _makeSession(id: 's1'));
      service.logPractice('skill-1', _makeSession(id: 's2'));
      service.removePractice('skill-1', 's1');
      expect(service.getSkill('skill-1')!.sessions.length, 1);
    });

    test('removePractice updates lastPracticedAt', () {
      service.addSkill(_makeSkill());
      service.logPractice('skill-1', _makeSession(id: 's1', startTime: DateTime(2026, 1, 1)));
      service.logPractice('skill-1', _makeSession(id: 's2', startTime: DateTime(2026, 2, 1)));
      service.removePractice('skill-1', 's2');
      expect(service.getSkill('skill-1')!.lastPracticedAt, DateTime(2026, 1, 1));
    });

    test('removePractice clears lastPracticedAt when empty', () {
      service.addSkill(_makeSkill());
      service.logPractice('skill-1', _makeSession(id: 's1'));
      service.removePractice('skill-1', 's1');
      expect(service.getSkill('skill-1')!.lastPracticedAt, isNull);
    });
  });

  group('Milestones', () {
    test('addMilestone', () {
      service.addSkill(_makeSkill());
      service.addMilestone('skill-1', SkillMilestone(id: 'm1', title: 'Basics'));
      expect(service.getSkill('skill-1')!.milestones.length, 1);
    });

    test('completeMilestone', () {
      service.addSkill(_makeSkill());
      service.addMilestone('skill-1', SkillMilestone(id: 'm1', title: 'Basics'));
      service.completeMilestone('skill-1', 'm1', now);
      final m = service.getSkill('skill-1')!.milestones.first;
      expect(m.completed, true);
      expect(m.completedAt, now);
    });

    test('uncompleteMilestone', () {
      service.addSkill(_makeSkill());
      service.addMilestone('skill-1', SkillMilestone(id: 'm1', title: 'Basics', completed: true, completedAt: now));
      service.uncompleteMilestone('skill-1', 'm1');
      final m = service.getSkill('skill-1')!.milestones.first;
      expect(m.completed, false);
      expect(m.completedAt, isNull);
    });
  });

  group('Level management', () {
    test('updateLevel changes level', () {
      service.addSkill(_makeSkill());
      service.updateLevel('skill-1', ProficiencyLevel.intermediate);
      expect(service.getSkill('skill-1')!.currentLevel, ProficiencyLevel.intermediate);
    });
  });

  group('Filtering & search', () {
    setUp(() {
      service.addSkill(_makeSkill(id: 's1', name: 'Dart', category: SkillCategory.programming, tags: ['web', 'mobile']));
      service.addSkill(_makeSkill(id: 's2', name: 'Piano', category: SkillCategory.music, tags: ['hobby']));
      service.addSkill(_makeSkill(id: 's3', name: 'French', category: SkillCategory.language, isArchived: true));
    });

    test('filterByCategory', () {
      expect(service.filterByCategory(SkillCategory.programming).length, 1);
    });

    test('filterByLevel', () {
      expect(service.filterByLevel(ProficiencyLevel.beginner).length, 2);
    });

    test('filterByTag', () {
      expect(service.filterByTag('web').length, 1);
    });

    test('search by name', () {
      expect(service.search('dart').length, 1);
      expect(service.search('PIANO').length, 1);
    });

    test('search includes archived', () {
      expect(service.search('french').length, 1);
    });

    test('neglectedSkills finds un-practiced', () {
      expect(service.neglectedSkills(now, days: 7).length, 2);
    });

    test('sortByTotalTime', () {
      service.logPractice('s1', _makeSession(id: 'p1', durationMinutes: 100));
      service.logPractice('s2', _makeSession(id: 'p2', durationMinutes: 50));
      final sorted = service.sortByTotalTime();
      expect(sorted.first.name, 'Dart');
    });
  });

  group('Weekly tracking', () {
    test('weeklyMinutes counts within week', () {
      service.addSkill(_makeSkill());
      service.logPractice('skill-1', _makeSession(id: 's1', startTime: now, durationMinutes: 60));
      service.logPractice('skill-1', _makeSession(id: 's2', startTime: now.subtract(const Duration(days: 14)), durationMinutes: 30));
      expect(service.weeklyMinutes('skill-1', now), 60);
    });

    test('weeklyGoalProgress', () {
      service.addSkill(_makeSkill(weeklyGoalMinutes: 60));
      service.logPractice('skill-1', _makeSession(id: 's1', startTime: now, durationMinutes: 30));
      expect(service.weeklyGoalProgress('skill-1', now), 0.5);
    });

    test('weeklyGoalProgress returns 0 for missing skill', () {
      expect(service.weeklyGoalProgress('nope', now), 0);
    });
  });

  group('Practice streaks', () {
    test('returns 0 for empty', () {
      final streak = service.calculateStreak(now);
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
    });

    test('calculates consecutive days', () {
      service.addSkill(_makeSkill());
      service.logPractice('skill-1', _makeSession(id: 's1', startTime: DateTime(2026, 3, 3, 9)));
      service.logPractice('skill-1', _makeSession(id: 's2', startTime: DateTime(2026, 3, 4, 9)));
      service.logPractice('skill-1', _makeSession(id: 's3', startTime: DateTime(2026, 3, 5, 9)));
      final streak = service.calculateStreak(now);
      expect(streak.currentStreak, 3);
      expect(streak.longestStreak, 3);
    });

    test('streak breaks on gap', () {
      service.addSkill(_makeSkill());
      service.logPractice('skill-1', _makeSession(id: 's1', startTime: DateTime(2026, 3, 1, 9)));
      service.logPractice('skill-1', _makeSession(id: 's2', startTime: DateTime(2026, 3, 3, 9)));
      service.logPractice('skill-1', _makeSession(id: 's3', startTime: DateTime(2026, 3, 4, 9)));
      service.logPractice('skill-1', _makeSession(id: 's4', startTime: DateTime(2026, 3, 5, 9)));
      final streak = service.calculateStreak(now);
      expect(streak.currentStreak, 3);
      expect(streak.longestStreak, 3);
    });

    test('skill-specific streak', () {
      service.addSkill(_makeSkill());
      service.logPractice('skill-1', _makeSession(id: 's1', startTime: DateTime(2026, 3, 5, 9)));
      final streak = service.calculateSkillStreak('skill-1', now);
      expect(streak.currentStreak, 1);
    });

    test('skill streak returns 0 for missing', () {
      expect(service.calculateSkillStreak('nope', now).currentStreak, 0);
    });
  });

  group('Weekly summary', () {
    test('generates summary with correct totals', () {
      service.addSkill(_makeSkill(id: 's1', weeklyGoalMinutes: 60));
      service.addSkill(_makeSkill(id: 's2', name: 'Piano', category: SkillCategory.music, weeklyGoalMinutes: 40));
      service.logPractice('s1', _makeSession(id: 'p1', startTime: now, durationMinutes: 30));
      service.logPractice('s2', _makeSession(id: 'p2', startTime: now, durationMinutes: 20));
      final summary = service.getWeeklySummary(now);
      expect(summary.totalMinutes, 50);
      expect(summary.sessionCount, 2);
      expect(summary.goalMinutes, 100);
    });
  });

  group('Topic analysis', () {
    test('topTopics returns most practiced', () {
      service.addSkill(_makeSkill());
      service.logPractice('skill-1', _makeSession(id: 's1', topic: 'async', durationMinutes: 60));
      service.logPractice('skill-1', _makeSession(id: 's2', topic: 'async', durationMinutes: 30));
      service.logPractice('skill-1', _makeSession(id: 's3', topic: 'testing', durationMinutes: 20));
      final topics = service.topTopics();
      expect(topics['async'], 90);
      expect(topics['testing'], 20);
    });

    test('topTopics respects limit', () {
      service.addSkill(_makeSkill());
      for (int i = 0; i < 15; i++) {
        service.logPractice('skill-1', _makeSession(id: 's$i', topic: 'topic$i'));
      }
      expect(service.topTopics(limit: 5).length, 5);
    });
  });

  group('Reports', () {
    test('generateSkillReport returns valid report', () {
      service.addSkill(_makeSkill(milestones: [
        SkillMilestone(id: 'm1', title: 'A', completed: true),
        SkillMilestone(id: 'm2', title: 'B'),
      ]));
      service.logPractice('skill-1', _makeSession(id: 's1', startTime: now, durationMinutes: 60, quality: 4));
      final report = service.generateSkillReport('skill-1', now);
      expect(report.skillName, 'Dart');
      expect(report.totalMinutes, 60);
      expect(report.grade, isNotEmpty);
      expect(report.completedMilestones, 1);
    });

    test('generateSkillReport throws for missing', () {
      expect(() => service.generateSkillReport('nope', now), throwsArgumentError);
    });

    test('generateSkillReport shows neglect insight', () {
      service.addSkill(_makeSkill());
      service.logPractice('skill-1', _makeSession(id: 's1', startTime: now.subtract(const Duration(days: 10))));
      final report = service.generateSkillReport('skill-1', now);
      expect(report.insights.any((i) => i.contains('days')), true);
    });

    test('generatePortfolioReport includes all active skills', () {
      service.addSkill(_makeSkill(id: 's1'));
      service.addSkill(_makeSkill(id: 's2', name: 'Piano', category: SkillCategory.music));
      service.addSkill(_makeSkill(id: 's3', isArchived: true));
      final report = service.generatePortfolioReport(now);
      expect(report.totalSkills, 3);
      expect(report.activeSkills, 2);
      expect(report.archivedSkills, 1);
      expect(report.skillReports.length, 2);
    });

    test('portfolio recommendations for neglected skills', () {
      service.addSkill(_makeSkill(id: 's1'));
      final report = service.generatePortfolioReport(now);
      expect(report.recommendations.any((r) => r.contains('Neglected')), true);
    });

    test('portfolio recommendations for many skills', () {
      for (int i = 0; i < 7; i++) {
        service.addSkill(_makeSkill(id: 'sk$i', name: 'Skill$i'));
      }
      final report = service.generatePortfolioReport(now);
      expect(report.recommendations.any((r) => r.contains('focusing')), true);
    });
  });

  group('Text summary', () {
    test('generates readable summary', () {
      service.addSkill(_makeSkill());
      service.logPractice('skill-1', _makeSession(id: 's1', startTime: now));
      final text = service.generateTextSummary(now);
      expect(text, contains('Learning Portfolio Summary'));
      expect(text, contains('Dart'));
      expect(text, contains('streak'));
    });
  });

  group('Persistence', () {
    test('toJson/loadFromJson roundtrip', () {
      service.addSkill(_makeSkill(id: 's1'));
      service.addSkill(_makeSkill(id: 's2', name: 'Piano'));
      service.logPractice('s1', _makeSession(id: 'p1'));
      final json = service.toJson();
      final service2 = SkillTrackerService();
      service2.loadFromJson(json);
      expect(service2.skills.length, 2);
      expect(service2.getSkill('s1')!.sessions.length, 1);
    });

    test('loadFromJson clears existing', () {
      service.addSkill(_makeSkill());
      service.loadFromJson('[]');
      expect(service.skills, isEmpty);
    });
  });

  group('Edge cases', () {
    test('weeklyMinutes for non-existent skill returns 0', () {
      expect(service.weeklyMinutes('nope', now), 0);
    });

    test('empty portfolio report', () {
      final report = service.generatePortfolioReport(now);
      expect(report.totalSkills, 0);
      expect(report.recommendations.any((r) => r.contains('No active')), true);
    });

    test('skill with zero weekly goal', () {
      service.addSkill(_makeSkill(weeklyGoalMinutes: 0));
      expect(service.weeklyGoalProgress('skill-1', now), 0);
    });
  });
}
