import 'dart:math';
import '../../models/event_model.dart';
import '../../models/event_checklist.dart';
import '../../models/event_tag.dart';
import '../../models/habit.dart';
import '../../models/goal.dart';
import '../../models/sleep_entry.dart';
import '../../models/mood_entry.dart';

/// Generates sample data for the Productivity Score Dashboard demo.
class ProductivitySampleData {
  static final _rng = Random(42);

  /// Generate sample events for the past [days] days.
  static List<EventModel> sampleEvents({int days = 14}) {
    final events = <EventModel>[];
    final now = DateTime.now();
    final titles = [
      'Team standup',
      'Code review',
      'Lunch break',
      'Design meeting',
      'Write docs',
      'Bug fix sprint',
      'Client call',
      'Planning session',
    ];
    final priorities = EventPriority.values;

    for (int d = 0; d < days; d++) {
      final date = DateTime(now.year, now.month, now.day - d);
      final count = 2 + _rng.nextInt(5);
      for (int i = 0; i < count; i++) {
        final title = titles[_rng.nextInt(titles.length)];
        final priority = priorities[_rng.nextInt(priorities.length)];
        final hasChecklist = _rng.nextBool();
        final items = <ChecklistItem>[];
        if (hasChecklist) {
          final itemCount = 1 + _rng.nextInt(4);
          for (int j = 0; j < itemCount; j++) {
            items.add(ChecklistItem(
              title: 'Task ${j + 1}',
              completed: _rng.nextDouble() > 0.3,
            ));
          }
        }
        events.add(EventModel(
          id: 'prod-evt-$d-$i',
          title: title,
          date: date,
          priority: priority,
          checklist: EventChecklist(items: items),
        ));
      }
    }
    return events;
  }

  /// Generate sample habits.
  static List<Habit> sampleHabits() {
    final now = DateTime.now();
    return [
      Habit(id: 'h1', name: 'Exercise', frequency: HabitFrequency.daily, createdAt: now.subtract(const Duration(days: 60))),
      Habit(id: 'h2', name: 'Read 30 min', frequency: HabitFrequency.daily, createdAt: now.subtract(const Duration(days: 60))),
      Habit(id: 'h3', name: 'Meditate', frequency: HabitFrequency.weekdays, createdAt: now.subtract(const Duration(days: 30))),
      Habit(id: 'h4', name: 'Journal', frequency: HabitFrequency.daily, createdAt: now.subtract(const Duration(days: 45))),
    ];
  }

  /// Generate sample habit completions for the past [days] days.
  static Map<String, List<DateTime>> sampleHabitCompletions({int days = 14}) {
    final completions = <String, List<DateTime>>{};
    final now = DateTime.now();
    for (final id in ['h1', 'h2', 'h3', 'h4']) {
      final dates = <DateTime>[];
      for (int d = 0; d < days; d++) {
        if (_rng.nextDouble() > 0.25) {
          dates.add(DateTime(now.year, now.month, now.day - d));
        }
      }
      completions[id] = dates;
    }
    return completions;
  }

  /// Generate sample goals.
  static List<Goal> sampleGoals() {
    final now = DateTime.now();
    return [
      Goal(id: 'g1', title: 'Launch MVP', progress: 65, createdAt: now.subtract(const Duration(days: 30)), deadline: now.add(const Duration(days: 15))),
      Goal(id: 'g2', title: 'Read 12 books', progress: 42, createdAt: now.subtract(const Duration(days: 60)), deadline: now.add(const Duration(days: 120))),
      Goal(id: 'g3', title: 'Run 5K under 25 min', progress: 80, createdAt: now.subtract(const Duration(days: 45)), deadline: now.add(const Duration(days: 30))),
    ];
  }

  /// Generate sample sleep entries for the past [days] days.
  static List<SleepEntry> sampleSleepEntries({int days = 14}) {
    final entries = <SleepEntry>[];
    final now = DateTime.now();
    final qualities = SleepQuality.values;

    for (int d = 0; d < days; d++) {
      final wakeDate = DateTime(now.year, now.month, now.day - d, 7 + _rng.nextInt(2));
      final hours = 5.5 + _rng.nextDouble() * 4;
      final bedtime = wakeDate.subtract(Duration(minutes: (hours * 60).round()));
      entries.add(SleepEntry(
        id: 'sleep-$d',
        bedTime: bedtime,
        wakeTime: wakeDate,
        quality: qualities[1 + _rng.nextInt(qualities.length - 1)],
      ));
    }
    return entries;
  }

  /// Generate sample mood entries for the past [days] days.
  static List<MoodEntry> sampleMoodEntries({int days = 14}) {
    final entries = <MoodEntry>[];
    final now = DateTime.now();
    final moods = MoodLevel.values;

    for (int d = 0; d < days; d++) {
      final date = DateTime(now.year, now.month, now.day - d, 12);
      entries.add(MoodEntry(
        id: 'mood-$d',
        timestamp: date,
        mood: moods[1 + _rng.nextInt(moods.length - 1)],
        note: '',
        activities: const [],
      ));
    }
    return entries;
  }

  /// Generate sample focus minutes per day for the past [days] days.
  static Map<int, int> sampleFocusMinutes({int days = 14}) {
    final map = <int, int>{};
    for (int d = 0; d < days; d++) {
      map[d] = 20 + _rng.nextInt(140);
    }
    return map;
  }
}
