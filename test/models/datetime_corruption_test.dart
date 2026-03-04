import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_checklist.dart';
import 'package:everything/models/goal.dart';
import 'package:everything/models/habit.dart';
import 'package:everything/models/mood_entry.dart';
import 'package:everything/models/sleep_entry.dart';
import 'package:everything/models/recurrence_rule.dart';

/// Tests that corrupted or malformed date strings in persisted JSON
/// do not crash the app. All model fromJson methods should gracefully
/// handle invalid dates via DateTime.tryParse with safe fallbacks.
void main() {
  group('DateTime corruption resilience', () {
    group('EventModel', () {
      test('survives corrupted date field', () {
        final json = {
          'id': 'e1',
          'title': 'Test',
          'date': 'NOT-A-DATE',
        };
        final event = EventModel.fromJson(json);
        expect(event.id, 'e1');
        expect(event.date, DateTime.fromMillisecondsSinceEpoch(0));
      });

      test('survives empty date field', () {
        final json = {
          'id': 'e2',
          'title': 'Test',
          'date': '',
        };
        final event = EventModel.fromJson(json);
        expect(event.date, DateTime.fromMillisecondsSinceEpoch(0));
      });

      test('survives corrupted end_date field', () {
        final json = {
          'id': 'e3',
          'title': 'Test',
          'date': '2026-01-01T00:00:00.000',
          'end_date': 'GARBAGE',
        };
        final event = EventModel.fromJson(json);
        expect(event.endDate, isNull);
      });

      test('valid dates still parse correctly', () {
        final json = {
          'id': 'e4',
          'title': 'Test',
          'date': '2026-03-03T10:00:00.000',
          'end_date': '2026-03-03T11:00:00.000',
        };
        final event = EventModel.fromJson(json);
        expect(event.date.year, 2026);
        expect(event.date.month, 3);
        expect(event.endDate!.hour, 11);
      });
    });

    group('ChecklistItem', () {
      test('survives corrupted createdAt', () {
        final json = {
          'id': 'ci1',
          'title': 'Task',
          'createdAt': 'INVALID',
        };
        final item = ChecklistItem.fromJson(json);
        expect(item.title, 'Task');
        // Falls back to DateTime.now() via ternary null check
      });

      test('survives corrupted completedAt', () {
        final json = {
          'id': 'ci2',
          'title': 'Task',
          'completed': true,
          'completedAt': 'BAD-DATE',
        };
        final item = ChecklistItem.fromJson(json);
        expect(item.completed, isTrue);
        expect(item.completedAt, isNull);
      });
    });

    group('Goal', () {
      test('survives corrupted createdAt', () {
        final json = {
          'id': 'g1',
          'title': 'Goal',
          'createdAt': 'CORRUPT',
          'milestones': '[]',
        };
        final goal = Goal.fromJson(json);
        expect(goal.id, 'g1');
        // Falls back to DateTime.now()
      });

      test('survives corrupted deadline', () {
        final json = {
          'id': 'g2',
          'title': 'Goal',
          'createdAt': '2026-01-01T00:00:00.000',
          'deadline': 'NOT-A-DATE',
          'milestones': '[]',
        };
        final goal = Goal.fromJson(json);
        expect(goal.deadline, isNull);
      });
    });

    group('Milestone', () {
      test('survives corrupted completedAt', () {
        final json = {
          'id': 'm1',
          'title': 'Step 1',
          'isCompleted': true,
          'completedAt': 'CORRUPT',
        };
        final ms = Milestone.fromJson(json);
        expect(ms.isCompleted, isTrue);
        expect(ms.completedAt, isNull);
      });
    });

    group('Habit', () {
      test('survives corrupted createdAt', () {
        final json = {
          'id': 'h1',
          'title': 'Exercise',
          'frequency': 'daily',
          'createdAt': 'BAD',
        };
        final habit = Habit.fromJson(json);
        expect(habit.title, 'Exercise');
      });
    });

    group('HabitCompletion', () {
      test('survives corrupted date', () {
        final json = {
          'habitId': 'h1',
          'date': 'INVALID-DATE',
        };
        final completion = HabitCompletion.fromJson(json);
        expect(completion.habitId, 'h1');
        expect(completion.date, DateTime.fromMillisecondsSinceEpoch(0));
      });
    });

    group('MoodEntry', () {
      test('survives corrupted timestamp', () {
        final json = {
          'id': 'mood1',
          'mood': 4,
          'timestamp': 'NOT-ISO-8601',
          'activities': '[]',
        };
        final entry = MoodEntry.fromJson(json);
        expect(entry.id, 'mood1');
      });
    });

    group('SleepEntry', () {
      test('survives corrupted bedtime', () {
        final json = {
          'id': 'se1',
          'bedtime': 'CORRUPT',
          'wakeTime': '2026-01-01T07:00:00.000',
          'quality': 3,
        };
        final entry = SleepEntry.fromJson(json);
        expect(entry.id, 'se1');
      });

      test('survives corrupted wakeTime', () {
        final json = {
          'id': 'se2',
          'bedtime': '2026-01-01T23:00:00.000',
          'wakeTime': 'BAD-TIME',
          'quality': 4,
        };
        final entry = SleepEntry.fromJson(json);
        expect(entry.id, 'se2');
      });
    });

    group('RecurrenceRule', () {
      test('survives corrupted endDate', () {
        final json = {
          'frequency': 'weekly',
          'interval': 1,
          'endDate': 'NOT-A-DATE',
        };
        final rule = RecurrenceRule.fromJson(json);
        expect(rule.endDate, isNull);
      });
    });
  });
}
