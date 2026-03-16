import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/learning_item.dart';
import 'package:everything/core/services/learning_tracker_service.dart';

void main() {
  group('LearningItem', () {
    test('fromJson/toJson roundtrip', () {
      final item = LearningItem(
        id: '1',
        title: 'Flutter Course',
        source: 'Udemy',
        type: LearningType.course,
        category: LearningCategory.programming,
        status: LearningStatus.inProgress,
        totalUnits: 20,
        completedUnits: 5,
        rating: 4,
        dateAdded: DateTime(2026, 1, 1),
        dateStarted: DateTime(2026, 1, 5),
        sessions: [
          StudySession(
            date: DateTime(2026, 1, 5),
            minutesSpent: 60,
            progressDelta: 3,
            notes: 'Great start',
          ),
        ],
        tags: ['flutter', 'mobile'],
        priority: 5,
      );

      final json = item.toJson();
      final restored = LearningItem.fromJson(json);

      expect(restored.id, '1');
      expect(restored.title, 'Flutter Course');
      expect(restored.source, 'Udemy');
      expect(restored.type, LearningType.course);
      expect(restored.category, LearningCategory.programming);
      expect(restored.status, LearningStatus.inProgress);
      expect(restored.totalUnits, 20);
      expect(restored.completedUnits, 5);
      expect(restored.rating, 4);
      expect(restored.sessions.length, 1);
      expect(restored.sessions.first.minutesSpent, 60);
      expect(restored.tags, ['flutter', 'mobile']);
      expect(restored.priority, 5);
    });

    test('progressPercent calculation', () {
      final item = LearningItem(
        id: '1', title: 'Test', dateAdded: DateTime.now(),
        totalUnits: 10, completedUnits: 7,
      );
      expect(item.progressPercent, 70.0);
    });

    test('progressPercent zero when no units', () {
      final item = LearningItem(
        id: '1', title: 'Test', dateAdded: DateTime.now(),
      );
      expect(item.progressPercent, 0);
    });

    test('totalMinutesStudied sums sessions', () {
      final item = LearningItem(
        id: '1', title: 'Test', dateAdded: DateTime.now(),
        sessions: [
          StudySession(date: DateTime.now(), minutesSpent: 30),
          StudySession(date: DateTime.now(), minutesSpent: 45),
        ],
      );
      expect(item.totalMinutesStudied, 75);
      expect(item.hoursStudied, 1.25);
    });

    test('copyWith creates modified copy', () {
      final item = LearningItem(
        id: '1', title: 'Original', dateAdded: DateTime.now(),
        priority: 2,
      );
      final copy = item.copyWith(title: 'Modified', priority: 5);
      expect(copy.title, 'Modified');
      expect(copy.priority, 5);
      expect(copy.id, '1');
    });

    test('unitsRemaining is correct', () {
      final item = LearningItem(
        id: '1', title: 'T', dateAdded: DateTime.now(),
        totalUnits: 10, completedUnits: 3,
      );
      expect(item.unitsRemaining, 7);
    });
  });

  group('StudySession', () {
    test('fromJson/toJson roundtrip', () {
      final s = StudySession(
        date: DateTime(2026, 3, 1),
        minutesSpent: 45,
        progressDelta: 2,
        notes: 'Good session',
      );
      final json = s.toJson();
      final restored = StudySession.fromJson(json);
      expect(restored.minutesSpent, 45);
      expect(restored.progressDelta, 2);
      expect(restored.notes, 'Good session');
    });
  });

  group('LearningTrackerService', () {
    late LearningTrackerService service;

    setUp(() {
      service = LearningTrackerService();
    });

    LearningItem _makeItem(String id, {
      LearningStatus status = LearningStatus.planned,
      LearningType type = LearningType.course,
      LearningCategory category = LearningCategory.programming,
      int priority = 3,
      int totalUnits = 10,
      int completedUnits = 0,
      int? rating,
      List<StudySession> sessions = const [],
    }) => LearningItem(
      id: id, title: 'Item $id', dateAdded: DateTime.now(),
      status: status, type: type, category: category,
      priority: priority, totalUnits: totalUnits,
      completedUnits: completedUnits, rating: rating,
      sessions: sessions,
    );

    test('add and retrieve items', () {
      service.addItem(_makeItem('1'));
      service.addItem(_makeItem('2'));
      expect(service.items.length, 2);
      expect(service.getItem('1')?.title, 'Item 1');
    });

    test('remove item', () {
      service.addItem(_makeItem('1'));
      service.removeItem('1');
      expect(service.items.isEmpty, true);
    });

    test('update item', () {
      service.addItem(_makeItem('1', priority: 1));
      service.updateItem(_makeItem('1', priority: 5));
      expect(service.getItem('1')?.priority, 5);
    });

    test('byStatus filters correctly', () {
      service.addItem(_makeItem('1', status: LearningStatus.inProgress));
      service.addItem(_makeItem('2', status: LearningStatus.completed));
      service.addItem(_makeItem('3', status: LearningStatus.inProgress));
      expect(service.byStatus(LearningStatus.inProgress).length, 2);
      expect(service.byStatus(LearningStatus.completed).length, 1);
    });

    test('byType filters correctly', () {
      service.addItem(_makeItem('1', type: LearningType.book));
      service.addItem(_makeItem('2', type: LearningType.video));
      expect(service.byType(LearningType.book).length, 1);
    });

    test('byCategory filters correctly', () {
      service.addItem(_makeItem('1', category: LearningCategory.design));
      service.addItem(_makeItem('2', category: LearningCategory.design));
      expect(service.byCategory(LearningCategory.design).length, 2);
    });

    test('search by title', () {
      service.addItem(LearningItem(
        id: '1', title: 'Flutter Advanced', dateAdded: DateTime.now(),
      ));
      service.addItem(LearningItem(
        id: '2', title: 'Python Basics', dateAdded: DateTime.now(),
      ));
      expect(service.search('flutter').length, 1);
      expect(service.search('PYTHON').length, 1);
    });

    test('totalMinutesStudied sums all items', () {
      service.addItem(_makeItem('1', sessions: [
        StudySession(date: DateTime.now(), minutesSpent: 30),
      ]));
      service.addItem(_makeItem('2', sessions: [
        StudySession(date: DateTime.now(), minutesSpent: 45),
      ]));
      expect(service.totalMinutesStudied, 75);
      expect(service.totalHoursStudied, 1.25);
    });

    test('completedCount and completionRate', () {
      service.addItem(_makeItem('1', status: LearningStatus.completed));
      service.addItem(_makeItem('2', status: LearningStatus.inProgress));
      service.addItem(_makeItem('3', status: LearningStatus.completed));
      expect(service.completedCount, 2);
      expect(service.completionRate, closeTo(66.67, 0.1));
    });

    test('averageRating', () {
      service.addItem(_makeItem('1', rating: 4));
      service.addItem(_makeItem('2', rating: 5));
      service.addItem(_makeItem('3')); // no rating
      expect(service.averageRating, 4.5);
    });

    test('averageRating returns 0 when none rated', () {
      service.addItem(_makeItem('1'));
      expect(service.averageRating, 0);
    });

    test('prioritized sorts by priority desc', () {
      service.addItem(_makeItem('1', priority: 2));
      service.addItem(_makeItem('2', priority: 5));
      service.addItem(_makeItem('3', priority: 3));
      final sorted = service.prioritized;
      expect(sorted.first.id, '2');
      expect(sorted.last.id, '1');
    });

    test('categoryBreakdown counts correctly', () {
      service.addItem(_makeItem('1', category: LearningCategory.programming));
      service.addItem(_makeItem('2', category: LearningCategory.programming));
      service.addItem(_makeItem('3', category: LearningCategory.math));
      final breakdown = service.categoryBreakdown;
      expect(breakdown[LearningCategory.programming], 2);
      expect(breakdown[LearningCategory.math], 1);
    });

    test('typeBreakdown counts correctly', () {
      service.addItem(_makeItem('1', type: LearningType.course));
      service.addItem(_makeItem('2', type: LearningType.book));
      service.addItem(_makeItem('3', type: LearningType.course));
      final breakdown = service.typeBreakdown;
      expect(breakdown[LearningType.course], 2);
      expect(breakdown[LearningType.book], 1);
    });

    test('suggestedNext prioritizes in-progress then planned', () {
      service.addItem(_makeItem('1', status: LearningStatus.planned, priority: 5));
      service.addItem(_makeItem('2', status: LearningStatus.inProgress, priority: 1));
      service.addItem(_makeItem('3', status: LearningStatus.completed));
      final suggested = service.suggestedNext;
      expect(suggested.length, 2); // excludes completed
      expect(suggested.first.id, '2'); // in-progress first
    });

    test('getItem returns null for missing id', () {
      expect(service.getItem('missing'), isNull);
    });

    test('inProgress shortcut', () {
      service.addItem(_makeItem('1', status: LearningStatus.inProgress));
      service.addItem(_makeItem('2', status: LearningStatus.planned));
      expect(service.inProgress.length, 1);
    });

    test('completionRate is 0 when empty', () {
      expect(service.completionRate, 0);
    });

    test('currentStreak with no sessions is 0', () {
      service.addItem(_makeItem('1'));
      expect(service.currentStreak, 0);
    });
  });

  group('Enums', () {
    test('LearningType labels and emojis', () {
      expect(LearningType.course.label, 'Course');
      expect(LearningType.course.emoji, '🎓');
      expect(LearningType.certification.label, 'Certification');
    });

    test('LearningStatus labels and emojis', () {
      expect(LearningStatus.inProgress.label, 'In Progress');
      expect(LearningStatus.completed.emoji, '✅');
    });

    test('LearningCategory labels', () {
      expect(LearningCategory.programming.label, 'Programming');
      expect(LearningCategory.dataScience.label, 'Data Science');
    });
  });
}
