import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/productivity_score_service.dart';
import 'package:everything/core/data/productivity_sample_data.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_checklist.dart';
import 'package:everything/models/habit.dart';
import 'package:everything/models/goal.dart';
import 'package:everything/models/sleep_entry.dart';
import 'package:everything/models/mood_entry.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  group('ProductivityWeights', () {
    test('default weights sum to 1.0', () {
      const w = ProductivityWeights();
      expect(w.isValid, isTrue);
      expect((w.total - 1.0).abs() < 0.001, isTrue);
    });

    test('taskFocused preset is valid', () {
      expect(ProductivityWeights.taskFocused.isValid, isTrue);
    });

    test('wellnessFocused preset is valid', () {
      expect(ProductivityWeights.wellnessFocused.isValid, isTrue);
    });

    test('serialization roundtrip', () {
      const w = ProductivityWeights();
      final map = w.toMap();
      final restored = ProductivityWeights.fromMap(map);
      expect((restored.events - w.events).abs() < 0.001, isTrue);
      expect((restored.habits - w.habits).abs() < 0.001, isTrue);
    });

    test('invalid weights detected', () {
      const w = ProductivityWeights(events: 0.5, habits: 0.5, goals: 0.5);
      expect(w.isValid, isFalse);
    });
  });

  group('ProductivityScoreService', () {
    late ProductivityScoreService service;

    setUp(() {
      service = ProductivityScoreService();
    });

    test('throws on invalid weights', () {
      expect(
        () => ProductivityScoreService(
          weights: const ProductivityWeights(events: 0.5, habits: 0.5, goals: 0.5),
        ),
        throwsArgumentError,
      );
    });

    test('throws on invalid targetEventsPerDay', () {
      expect(
        () => ProductivityScoreService(targetEventsPerDay: 0),
        throwsArgumentError,
      );
    });

    test('scoreEvents returns 0 for empty events', () {
      expect(service.scoreEvents([], today), equals(0));
    });

    test('scoreEvents returns > 0 for events on day', () {
      final events = [
        EventModel(id: '1', title: 'Test', date: today),
        EventModel(id: '2', title: 'Test2', date: today),
      ];
      final score = service.scoreEvents(events, today);
      expect(score, greaterThan(0));
      expect(score, lessThanOrEqualTo(100));
    });

    test('scoreEvents ignores events on other days', () {
      final events = [
        EventModel(
          id: '1',
          title: 'Yesterday',
          date: today.subtract(const Duration(days: 1)),
        ),
      ];
      expect(service.scoreEvents(events, today), equals(0));
    });

    test('scoreHabits returns 100 when no habits due', () {
      final habits = [
        Habit(
          id: 'h1', name: 'Weekend only',
          frequency: HabitFrequency.weekends,
          createdAt: today.subtract(const Duration(days: 10)),
        ),
      ];
      // If today is a weekday, no habits are due
      if (today.weekday <= 5) {
        expect(
          service.scoreHabits(habits, {}, today),
          equals(100),
        );
      }
    });

    test('scoreHabits returns 0 for empty habits', () {
      expect(service.scoreHabits([], {}, today), equals(0));
    });

    test('scoreGoals returns 0 for no goals', () {
      expect(service.scoreGoals([], today), equals(0));
    });

    test('scoreGoals returns 100 when all completed', () {
      final goals = [
        Goal(id: 'g1', title: 'Done', progress: 100, isCompleted: true, createdAt: today),
      ];
      expect(service.scoreGoals(goals, today), equals(100));
    });

    test('scoreSleep returns 0 with no entries', () {
      expect(service.scoreSleep([], today), equals(0));
    });

    test('scoreSleep scores good sleep highly', () {
      final entries = [
        SleepEntry(
          id: 's1',
          bedTime: DateTime(today.year, today.month, today.day, 23),
          wakeTime: DateTime(today.year, today.month, today.day, 7),
          quality: SleepQuality.excellent,
        ),
      ];
      final score = service.scoreSleep(entries, today);
      expect(score, greaterThanOrEqualTo(80));
    });

    test('scoreMood returns 0 with no entries', () {
      expect(service.scoreMood([], today), equals(0));
    });

    test('scoreMood maps mood levels correctly', () {
      final entries = [
        MoodEntry(
          id: 'm1', timestamp: today,
          mood: MoodLevel.great,
          note: '', activities: const [],
        ),
      ];
      final score = service.scoreMood(entries, today);
      expect(score, greaterThan(60));
    });

    test('scoreFocus returns 0 for 0 minutes', () {
      expect(service.scoreFocus(0), equals(0));
    });

    test('scoreFocus caps at 100', () {
      expect(service.scoreFocus(300), equals(100));
    });

    test('computeDailyScore produces valid score', () {
      final result = service.computeDailyScore(
        date: today,
        events: ProductivitySampleData.sampleEvents(),
        habits: ProductivitySampleData.sampleHabits(),
        habitCompletions: ProductivitySampleData.sampleHabitCompletions(),
        goals: ProductivitySampleData.sampleGoals(),
        sleepEntries: ProductivitySampleData.sampleSleepEntries(),
        moodEntries: ProductivitySampleData.sampleMoodEntries(),
        focusMinutes: 90,
      );
      expect(result.overallScore, greaterThanOrEqualTo(0));
      expect(result.overallScore, lessThanOrEqualTo(100));
      expect(result.dimensions.length, equals(6));
      expect(result.grade, isNotNull);
    });
  });

  group('ProductivityGrade', () {
    test('all grades have labels', () {
      for (final g in ProductivityGrade.values) {
        expect(g.label.isNotEmpty, isTrue);
        expect(g.emoji.isNotEmpty, isTrue);
      }
    });
  });

  group('DailyProductivityScore', () {
    test('toMap serializes correctly', () {
      final score = DailyProductivityScore(
        date: today,
        overallScore: 75.5,
        grade: ProductivityGrade.great,
        dimensions: [
          DimensionScore(name: 'Events', score: 80, weight: 0.25, contribution: 20, insight: 'Good'),
        ],
        strengths: ['Events: Good'],
        improvements: [],
      );
      final map = score.toMap();
      expect(map['overallScore'], equals(75.5));
      expect(map['grade'], equals('Great'));
      expect((map['dimensions'] as List).length, equals(1));
    });
  });

  group('Trend Analysis', () {
    late ProductivityScoreService service;
    late List<DailyProductivityScore> scores;

    setUp(() {
      service = ProductivityScoreService();
      scores = [];
      for (int d = 0; d < 7; d++) {
        scores.add(service.computeDailyScore(
          date: today.subtract(Duration(days: d)),
          events: ProductivitySampleData.sampleEvents(),
          habits: ProductivitySampleData.sampleHabits(),
          habitCompletions: ProductivitySampleData.sampleHabitCompletions(),
          goals: ProductivitySampleData.sampleGoals(),
          sleepEntries: ProductivitySampleData.sampleSleepEntries(),
          moodEntries: ProductivitySampleData.sampleMoodEntries(),
          focusMinutes: 60 + d * 10,
        ));
      }
    });

    test('analyzeTrend returns valid trend', () {
      final trend = service.analyzeTrend(scores);
      expect(trend.dailyScores.length, equals(7));
      expect(trend.averageScore, greaterThan(0));
      expect(trend.bestScore, greaterThanOrEqualTo(trend.averageScore));
      expect(trend.worstScore, lessThanOrEqualTo(trend.averageScore));
      expect(trend.dimensionAverages.length, equals(6));
    });

    test('analyzeTrend handles empty list', () {
      final trend = service.analyzeTrend([]);
      expect(trend.averageScore, equals(0));
      expect(trend.streak, equals(0));
    });

    test('weeklySummary computes changes', () {
      final thisWeek = scores.sublist(0, 4);
      final lastWeek = scores.sublist(4);
      final summary = service.weeklySummary(thisWeek, lastWeek);
      expect(summary.containsKey('change'), isTrue);
      expect(summary.containsKey('improving'), isTrue);
      expect(summary.containsKey('dimensionChanges'), isTrue);
    });

    test('trend toMap serializes', () {
      final trend = service.analyzeTrend(scores);
      final map = trend.toMap();
      expect(map['averageScore'], isA<double>());
      expect(map['direction'], isA<String>());
    });
  });

  group('Sample Data', () {
    test('generates events', () {
      final events = ProductivitySampleData.sampleEvents(days: 7);
      expect(events.isNotEmpty, isTrue);
    });

    test('generates habits', () {
      final habits = ProductivitySampleData.sampleHabits();
      expect(habits.length, equals(4));
    });

    test('generates goals', () {
      final goals = ProductivitySampleData.sampleGoals();
      expect(goals.length, equals(3));
    });

    test('generates sleep entries', () {
      final entries = ProductivitySampleData.sampleSleepEntries(days: 7);
      expect(entries.length, equals(7));
    });

    test('generates mood entries', () {
      final entries = ProductivitySampleData.sampleMoodEntries(days: 7);
      expect(entries.length, equals(7));
    });

    test('generates focus minutes', () {
      final map = ProductivitySampleData.sampleFocusMinutes(days: 7);
      expect(map.length, equals(7));
    });
  });
}
