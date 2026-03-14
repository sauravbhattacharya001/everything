import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/habit.dart';
import 'package:everything/core/services/habit_tracker_service.dart';

void main() {
  late HabitTrackerService service;
  late Habit dailyHabit;
  late Habit weekdayHabit;
  late Habit countHabit;

  setUp(() {
    service = HabitTrackerService();

    dailyHabit = Habit(
      id: 'meditate',
      name: 'Meditate',
      emoji: '🧘',
      createdAt: DateTime(2026, 1, 1),
    );

    weekdayHabit = Habit(
      id: 'exercise',
      name: 'Exercise',
      emoji: '💪',
      frequency: HabitFrequency.weekdays,
      createdAt: DateTime(2026, 1, 1),
    );

    countHabit = Habit(
      id: 'water',
      name: 'Drink Water',
      emoji: '💧',
      targetCount: 8,
      createdAt: DateTime(2026, 1, 1),
    );
  });

  group('Habit model', () {
    test('daily habit is scheduled every day', () {
      for (int d = 1; d <= 7; d++) {
        expect(dailyHabit.isScheduledFor(d), isTrue);
      }
    });

    test('weekday habit skips weekends', () {
      expect(weekdayHabit.isScheduledFor(1), isTrue); // Monday
      expect(weekdayHabit.isScheduledFor(5), isTrue); // Friday
      expect(weekdayHabit.isScheduledFor(6), isFalse); // Saturday
      expect(weekdayHabit.isScheduledFor(7), isFalse); // Sunday
    });

    test('weekend habit only on weekends', () {
      final h = Habit(
        id: 'hike',
        name: 'Hike',
        frequency: HabitFrequency.weekends,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(h.isScheduledFor(6), isTrue);
      expect(h.isScheduledFor(7), isTrue);
      expect(h.isScheduledFor(3), isFalse);
    });

    test('custom days', () {
      final h = Habit(
        id: 'piano',
        name: 'Piano Practice',
        frequency: HabitFrequency.custom,
        customDays: [1, 3, 5], // Mon, Wed, Fri
        createdAt: DateTime(2026, 1, 1),
      );
      expect(h.isScheduledFor(1), isTrue);
      expect(h.isScheduledFor(2), isFalse);
      expect(h.isScheduledFor(3), isTrue);
    });

    test('serialization roundtrip', () {
      final json = dailyHabit.toJson();
      final restored = Habit.fromJson(json);
      expect(restored.id, dailyHabit.id);
      expect(restored.name, dailyHabit.name);
      expect(restored.emoji, dailyHabit.emoji);
      expect(restored.frequency, dailyHabit.frequency);
    });
  });

  group('HabitTrackerService', () {
    test('add and retrieve habits', () {
      service.addHabit(dailyHabit);
      service.addHabit(weekdayHabit);
      expect(service.activeHabits.length, 2);
    });

    test('duplicate habit id throws', () {
      service.addHabit(dailyHabit);
      expect(() => service.addHabit(dailyHabit), throwsArgumentError);
    });

    test('archive habit', () {
      service.addHabit(dailyHabit);
      service.archiveHabit('meditate');
      expect(service.activeHabits, isEmpty);
      expect(service.allHabits.length, 1);
    });

    test('log and retrieve completions', () {
      service.addHabit(dailyHabit);
      service.logCompletion('meditate', DateTime(2026, 3, 1));
      service.logCompletion('meditate', DateTime(2026, 3, 2));

      final comps = service.getCompletions('meditate',
          from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 2));
      expect(comps.length, 2);
    });

    test('duplicate log increments count', () {
      service.addHabit(countHabit);
      service.logCompletion('water', DateTime(2026, 3, 1));
      service.logCompletion('water', DateTime(2026, 3, 1));
      service.logCompletion('water', DateTime(2026, 3, 1));

      final comps = service.getCompletions('water');
      expect(comps.length, 1);
      expect(comps.first.count, 3);
    });

    test('remove completion', () {
      service.addHabit(dailyHabit);
      service.logCompletion('meditate', DateTime(2026, 3, 1));
      service.removeCompletion('meditate', DateTime(2026, 3, 1));
      expect(service.getCompletions('meditate'), isEmpty);
    });
  });

  group('Stats', () {
    test('completion rate calculation', () {
      service.addHabit(dailyHabit);
      // Complete 3 out of 7 days
      service.logCompletion('meditate', DateTime(2026, 3, 2)); // Mon
      service.logCompletion('meditate', DateTime(2026, 3, 3)); // Tue
      service.logCompletion('meditate', DateTime(2026, 3, 4)); // Wed

      final stats = service.getHabitStats('meditate',
          from: DateTime(2026, 3, 2), to: DateTime(2026, 3, 8));
      expect(stats.scheduledDays, 7);
      expect(stats.completedDays, 3);
      expect(stats.completionRate, closeTo(3 / 7, 0.01));
    });

    test('count-based habit needs target to count as complete', () {
      service.addHabit(countHabit);
      // Log 3 glasses out of 8 target
      for (int i = 0; i < 3; i++) {
        service.logCompletion('water', DateTime(2026, 3, 2));
      }

      final stats = service.getHabitStats('water',
          from: DateTime(2026, 3, 2), to: DateTime(2026, 3, 2));
      expect(stats.totalCompletions, 3);
      expect(stats.completedDays, 0); // didn't reach target of 8
    });

    test('streak calculation', () {
      service.addHabit(dailyHabit);
      // 5-day streak
      for (int i = 0; i < 5; i++) {
        service.logCompletion(
            'meditate', DateTime(2026, 3, 1).add(Duration(days: i)));
      }

      final stats = service.getHabitStats('meditate',
          from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 5));
      expect(stats.currentStreak, 5);
      expect(stats.longestStreak, 5);
    });
  });

  group('Today status', () {
    test('shows due habits for today', () {
      service.addHabit(dailyHabit);
      service.addHabit(weekdayHabit);

      // Monday
      final status = service.todayStatus(referenceDate: DateTime(2026, 3, 2));
      expect(status.length, 2); // both due on Monday
      expect(status.every((s) => !s.completed), isTrue);
    });

    test('marks completed habits', () {
      service.addHabit(dailyHabit);
      service.logCompletion('meditate', DateTime(2026, 3, 2));

      final status = service.todayStatus(referenceDate: DateTime(2026, 3, 2));
      expect(status.first.completed, isTrue);
    });
  });

  group('Weekly summary', () {
    test('generates summary with perfect days', () {
      service.addHabit(dailyHabit);
      // Complete all 7 days of the week of March 2 (Mon) to March 8 (Sun)
      for (int i = 0; i < 7; i++) {
        service.logCompletion(
            'meditate', DateTime(2026, 3, 2).add(Duration(days: i)));
      }

      final summary =
          service.weeklySummary(referenceDate: DateTime(2026, 3, 5));
      expect(summary.perfectDays, 7);
      expect(summary.overallRate, closeTo(1.0, 0.01));
      expect(summary.habitStats.length, 1);
    });
  });

  group('Export / Import', () {
    test('exportToJson round-trips habits and completions', () {
      service.addHabit(dailyHabit);
      service.logCompletion('meditate', DateTime(2026, 3, 2), note: 'good');

      final json = service.exportToJson();
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      expect(parsed['habits'], hasLength(1));
      expect(parsed['completions'], hasLength(1));

      // Import into a fresh service
      final fresh = HabitTrackerService();
      fresh.importFromJson(json);
      expect(fresh.allHabits.length, 1);
      expect(fresh.allHabits.first.name, 'Meditate');
      expect(fresh.completions.length, 1);
      expect(fresh.completions.first.note, 'good');
    });

    test('importFromJson rejects oversized input', () {
      final huge = jsonEncode({
        'habits': List.generate(100001, (i) => {
          'id': 'h$i', 'name': 'H$i', 'frequency': 'daily',
          'targetCount': 1, 'isActive': true,
        }),
      });
      expect(() => service.importFromJson(huge), throwsArgumentError);
    });
  });
}
