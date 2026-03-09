import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/chore_entry.dart';
import 'package:everything/core/services/chore_tracker_service.dart';

void main() {
  const service = ChoreTrackerService();

  final now = DateTime.now();

  final chore1 = Chore(
    id: 'c1', name: 'Vacuum', room: ChoreRoom.livingRoom,
    frequency: ChoreFrequency.weekly, effort: ChoreEffort.moderate,
  );
  final chore2 = Chore(
    id: 'c2', name: 'Dishes', room: ChoreRoom.kitchen,
    frequency: ChoreFrequency.daily, effort: ChoreEffort.quick,
    assignee: 'Alice',
  );
  final chore3 = Chore(
    id: 'c3', name: 'Fix stuff', room: ChoreRoom.garage,
    frequency: ChoreFrequency.asNeeded, effort: ChoreEffort.major,
  );

  ChoreCompletion comp(String id, String choreId, int daysAgo,
      {int duration = 10, int rating = 3}) {
    return ChoreCompletion(
      id: id, choreId: choreId,
      completedAt: now.subtract(Duration(days: daysAgo)),
      durationMinutes: duration, rating: rating,
    );
  }

  group('ChoreRoom', () {
    test('has label and emoji for all values', () {
      for (final r in ChoreRoom.values) {
        expect(r.label, isNotEmpty);
        expect(r.emoji, isNotEmpty);
      }
    });
  });

  group('ChoreFrequency', () {
    test('has label for all values', () {
      for (final f in ChoreFrequency.values) {
        expect(f.label, isNotEmpty);
      }
    });

    test('intervalDays is 0 for asNeeded', () {
      expect(ChoreFrequency.asNeeded.intervalDays, 0);
    });

    test('daily interval is 1', () {
      expect(ChoreFrequency.daily.intervalDays, 1);
    });

    test('weekly interval is 7', () {
      expect(ChoreFrequency.weekly.intervalDays, 7);
    });
  });

  group('ChoreEffort', () {
    test('has label and emoji', () {
      for (final e in ChoreEffort.values) {
        expect(e.label, isNotEmpty);
        expect(e.emoji, isNotEmpty);
        expect(e.estimatedMinutes, greaterThan(0));
      }
    });
  });

  group('Chore model', () {
    test('copyWith preserves id', () {
      final copy = chore1.copyWith(name: 'Mop');
      expect(copy.id, 'c1');
      expect(copy.name, 'Mop');
      expect(copy.room, ChoreRoom.livingRoom);
    });

    test('toJson/fromJson roundtrip', () {
      final json = chore2.toJson();
      final restored = Chore.fromJson(json);
      expect(restored.id, chore2.id);
      expect(restored.name, chore2.name);
      expect(restored.room, chore2.room);
      expect(restored.frequency, chore2.frequency);
      expect(restored.effort, chore2.effort);
      expect(restored.assignee, 'Alice');
    });

    test('archived defaults to false', () {
      expect(chore1.archived, false);
    });

    test('copyWith archived', () {
      final archived = chore1.copyWith(archived: true);
      expect(archived.archived, true);
    });
  });

  group('ChoreCompletion model', () {
    test('toJson/fromJson roundtrip', () {
      final c = comp('x1', 'c1', 2, duration: 15, rating: 4);
      final json = c.toJson();
      final restored = ChoreCompletion.fromJson(json);
      expect(restored.id, 'x1');
      expect(restored.choreId, 'c1');
      expect(restored.durationMinutes, 15);
      expect(restored.rating, 4);
    });
  });

  group('isOverdue', () {
    test('returns true when no completions', () {
      expect(service.isOverdue(chore1, []), true);
    });

    test('returns false for asNeeded', () {
      expect(service.isOverdue(chore3, []), false);
    });

    test('returns false when recently completed', () {
      final completions = [comp('x1', 'c1', 1)];
      expect(service.isOverdue(chore1, completions), false);
    });

    test('returns true when overdue', () {
      final completions = [comp('x1', 'c1', 10)];
      expect(service.isOverdue(chore1, completions), true);
    });
  });

  group('daysUntilDue', () {
    test('returns -1 for no completions', () {
      expect(service.daysUntilDue(chore1, []), -1);
    });

    test('returns 999 for asNeeded', () {
      expect(service.daysUntilDue(chore3, []), 999);
    });

    test('calculates correctly', () {
      final completions = [comp('x1', 'c1', 3)];
      // weekly (7) - 3 days = 4
      expect(service.daysUntilDue(chore1, completions), 4);
    });
  });

  group('lastCompletion', () {
    test('returns null when none', () {
      expect(service.lastCompletion('c1', []), null);
    });

    test('returns most recent', () {
      final completions = [comp('x1', 'c1', 5), comp('x2', 'c1', 2)];
      final last = service.lastCompletion('c1', completions);
      expect(last!.id, 'x2');
    });
  });

  group('completionsInRange', () {
    test('counts correctly', () {
      final completions = [
        comp('x1', 'c1', 1),
        comp('x2', 'c1', 5),
        comp('x3', 'c1', 15),
      ];
      final count = service.completionsInRange(
        'c1', completions,
        now.subtract(const Duration(days: 7)),
        now.add(const Duration(days: 1)),
      );
      expect(count, 2);
    });
  });

  group('currentStreak', () {
    test('returns 0 for no completions', () {
      expect(service.currentStreak(chore1, []), 0);
    });

    test('returns 0 for asNeeded', () {
      expect(service.currentStreak(chore3, [comp('x1', 'c3', 0)]), 0);
    });

    test('counts consecutive completions', () {
      final completions = [
        comp('x1', 'c2', 0),
        comp('x2', 'c2', 1),
        comp('x3', 'c2', 2),
      ];
      expect(service.currentStreak(chore2, completions), 3);
    });
  });

  group('adherenceRate', () {
    test('returns 1.0 for asNeeded', () {
      expect(service.adherenceRate(chore3, [], 30), 1.0);
    });

    test('calculates rate', () {
      // weekly over 14 days = expected 2, if 1 done = 0.5
      final completions = [comp('x1', 'c1', 3)];
      final rate = service.adherenceRate(chore1, completions, 14);
      expect(rate, closeTo(0.5, 0.01));
    });
  });

  group('completionsByRoom', () {
    test('groups by room', () {
      final chores = [chore1, chore2];
      final completions = [
        comp('x1', 'c1', 1),
        comp('x2', 'c2', 1),
        comp('x3', 'c2', 2),
      ];
      final result = service.completionsByRoom(
        chores, completions,
        now.subtract(const Duration(days: 7)),
        now.add(const Duration(days: 1)),
      );
      expect(result[ChoreRoom.livingRoom], 1);
      expect(result[ChoreRoom.kitchen], 2);
    });
  });

  group('averageRating', () {
    test('returns 0 for no completions', () {
      expect(service.averageRating('c1', []), 0);
    });

    test('calculates average', () {
      final completions = [
        comp('x1', 'c1', 1, rating: 4),
        comp('x2', 'c1', 2, rating: 2),
      ];
      expect(service.averageRating('c1', completions), 3.0);
    });
  });

  group('totalMinutesSpent', () {
    test('sums durations', () {
      final completions = [
        comp('x1', 'c1', 1, duration: 20),
        comp('x2', 'c1', 2, duration: 15),
      ];
      expect(service.totalMinutesSpent('c1', [chore1], completions), 35);
    });

    test('uses estimate when duration is 0', () {
      final completions = [
        ChoreCompletion(id: 'x1', choreId: 'c1',
            completedAt: now, durationMinutes: 0),
      ];
      // moderate estimate = 20
      expect(service.totalMinutesSpent('c1', [chore1], completions), 20);
    });
  });

  group('sortByUrgency', () {
    test('most overdue first', () {
      final completions = [
        comp('x1', 'c1', 1), // vacuum: 7-1=6 days left
        comp('x2', 'c2', 3), // dishes: 1-3=-2 overdue
      ];
      final sorted = service.sortByUrgency([chore1, chore2], completions);
      expect(sorted.first.id, 'c2');
    });
  });

  group('weeklyCompletionMap', () {
    test('initializes all days', () {
      final map = service.weeklyCompletionMap([]);
      expect(map.length, 7);
      for (int d = 1; d <= 7; d++) {
        expect(map[d], 0);
      }
    });
  });

  group('overallGrade', () {
    test('returns N/A for empty', () {
      expect(service.overallGrade([], [], 30), 'N/A');
    });

    test('returns A for all asNeeded', () {
      expect(service.overallGrade([chore3], [], 30), 'A');
    });

    test('returns F for no completions on scheduled chores', () {
      final grade = service.overallGrade([chore1, chore2], [], 30);
      expect(grade, 'F');
    });
  });

  group('mostNeglected', () {
    test('returns lowest adherence first', () {
      final completions = [
        comp('x1', 'c1', 1), // vacuum has some
        // dishes has none
      ];
      final result = service.mostNeglected([chore1, chore2], completions, 14);
      expect(result.first.key.id, 'c2');
    });
  });

  group('recommendations', () {
    test('suggests quick wins when many overdue', () {
      final chores = List.generate(4, (i) => Chore(
        id: 'r$i', name: 'Chore $i', room: ChoreRoom.general,
        frequency: ChoreFrequency.daily, effort: ChoreEffort.quick,
      ));
      final tips = service.recommendations(chores, []);
      expect(tips.any((t) => t.contains('overdue')), true);
    });

    test('celebrates when all good', () {
      final chores = [chore3]; // only asNeeded
      final tips = service.recommendations(chores, []);
      expect(tips.any((t) => t.contains('Great job')), true);
    });
  });
}
