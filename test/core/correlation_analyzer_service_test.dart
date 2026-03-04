import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/correlation_analyzer_service.dart';
import 'package:everything/models/mood_entry.dart';
import 'package:everything/models/sleep_entry.dart';
import 'package:everything/models/habit.dart';
import 'package:everything/models/event_model.dart';

void main() {
  late CorrelationAnalyzerService service;

  setUp(() {
    service = const CorrelationAnalyzerService(minSampleSize: 3);
  });

  // ── Helper Factories ─────────────────────────────────────────────

  SleepEntry makeSleep(DateTime date, double hours, SleepQuality quality,
      {int? awakenings, List<SleepFactor> factors = const []}) {
    final bedtime = date.subtract(Duration(minutes: (hours * 60).round()));
    return SleepEntry(
      id: 'sleep-${date.toIso8601String()}',
      bedtime: bedtime,
      wakeTime: date,
      quality: quality,
      awakenings: awakenings,
      factors: factors,
    );
  }

  MoodEntry makeMood(DateTime date, MoodLevel mood,
      {List<MoodActivity> activities = const []}) {
    return MoodEntry(
      id: 'mood-${date.toIso8601String()}',
      timestamp: date,
      mood: mood,
      activities: activities,
    );
  }

  Habit makeHabit(String id, {HabitFrequency freq = HabitFrequency.daily}) {
    return Habit(
      id: id,
      name: 'Habit $id',
      frequency: freq,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  HabitCompletion makeCompletion(String habitId, DateTime date) {
    return HabitCompletion(habitId: habitId, date: date);
  }

  EventModel makeEvent(DateTime start, Duration duration) {
    return EventModel(
      id: 'evt-${start.toIso8601String()}',
      title: 'Event',
      date: start,
      endDate: start.add(duration),
    );
  }

  DateTime day(int d) => DateTime(2026, 3, d, 8, 0);

  // ── Snapshot Building ────────────────────────────────────────────

  group('buildSnapshots', () {
    test('returns empty for no data', () {
      final result = service.buildSnapshots(
        sleepEntries: [],
        moodEntries: [],
        habits: [],
        completions: [],
        events: [],
      );
      expect(result, isEmpty);
    });

    test('creates snapshots from sleep data only', () {
      final result = service.buildSnapshots(
        sleepEntries: [
          makeSleep(day(1), 7.5, SleepQuality.good),
          makeSleep(day(2), 6.0, SleepQuality.poor),
        ],
        moodEntries: [],
        habits: [],
        completions: [],
        events: [],
      );
      expect(result.length, 2);
      expect(result[0].sleepHours, closeTo(7.5, 0.01));
      expect(result[0].sleepQuality, 4);
      expect(result[0].moodScore, isNull);
      expect(result[1].sleepHours, closeTo(6.0, 0.01));
    });

    test('creates snapshots from mood data only', () {
      final result = service.buildSnapshots(
        sleepEntries: [],
        moodEntries: [
          makeMood(day(1), MoodLevel.great),
          makeMood(day(2), MoodLevel.bad),
        ],
        habits: [],
        completions: [],
        events: [],
      );
      expect(result.length, 2);
      expect(result[0].moodScore, 5);
      expect(result[0].sleepHours, isNull);
      expect(result[1].moodScore, 2);
    });

    test('merges sleep and mood on same day', () {
      final result = service.buildSnapshots(
        sleepEntries: [makeSleep(day(1), 8.0, SleepQuality.excellent)],
        moodEntries: [makeMood(day(1), MoodLevel.great)],
        habits: [],
        completions: [],
        events: [],
      );
      expect(result.length, 1);
      expect(result[0].sleepHours, closeTo(8.0, 0.01));
      expect(result[0].moodScore, 5);
    });

    test('averages multiple sleep entries on same day', () {
      final result = service.buildSnapshots(
        sleepEntries: [
          makeSleep(day(1), 6.0, SleepQuality.poor, awakenings: 2),
          makeSleep(day(1), 8.0, SleepQuality.good, awakenings: 0),
        ],
        moodEntries: [],
        habits: [],
        completions: [],
        events: [],
      );
      expect(result.length, 1);
      expect(result[0].sleepHours, closeTo(7.0, 0.01));
      expect(result[0].sleepQuality, 3); // avg of 2 and 4 → 3
      expect(result[0].awakenings, 1); // avg of 2 and 0 → 1
    });

    test('averages multiple mood entries on same day', () {
      final result = service.buildSnapshots(
        sleepEntries: [],
        moodEntries: [
          makeMood(day(1), MoodLevel.great),
          makeMood(day(1), MoodLevel.neutral),
        ],
        habits: [],
        completions: [],
        events: [],
      );
      expect(result.length, 1);
      expect(result[0].moodScore, 4); // avg of 5 and 3 → 4
    });

    test('counts habit completion correctly', () {
      final habits = [makeHabit('h1'), makeHabit('h2')];
      final result = service.buildSnapshots(
        sleepEntries: [],
        moodEntries: [],
        habits: habits,
        completions: [makeCompletion('h1', day(1))], // only h1 completed
        events: [],
      );
      // day(1) is a specific date; daily habits are always due
      expect(result.length, 1);
      expect(result[0].habitsDue, 2);
      expect(result[0].habitsCompleted, 1);
      expect(result[0].habitCompletionRate, closeTo(0.5, 0.01));
    });

    test('counts events and hours', () {
      final result = service.buildSnapshots(
        sleepEntries: [],
        moodEntries: [],
        habits: [],
        completions: [],
        events: [
          makeEvent(day(1), const Duration(hours: 1)),
          makeEvent(day(1), const Duration(hours: 2, minutes: 30)),
        ],
      );
      expect(result.length, 1);
      expect(result[0].eventCount, 2);
      expect(result[0].eventHours, closeTo(3.5, 0.01));
    });

    test('collects mood activities', () {
      final result = service.buildSnapshots(
        sleepEntries: [],
        moodEntries: [
          makeMood(day(1), MoodLevel.good,
              activities: [MoodActivity.exercise, MoodActivity.meditation]),
        ],
        habits: [],
        completions: [],
        events: [],
      );
      expect(result[0].moodActivities, contains(MoodActivity.exercise));
      expect(result[0].moodActivities, contains(MoodActivity.meditation));
    });

    test('collects sleep factors', () {
      final result = service.buildSnapshots(
        sleepEntries: [
          makeSleep(day(1), 7.0, SleepQuality.fair,
              factors: [SleepFactor.caffeine, SleepFactor.stress]),
        ],
        moodEntries: [],
        habits: [],
        completions: [],
        events: [],
      );
      expect(result[0].sleepFactors, contains(SleepFactor.caffeine));
      expect(result[0].sleepFactors, contains(SleepFactor.stress));
    });

    test('snapshots are sorted by date', () {
      final result = service.buildSnapshots(
        sleepEntries: [
          makeSleep(day(5), 7.0, SleepQuality.fair),
          makeSleep(day(1), 8.0, SleepQuality.good),
          makeSleep(day(3), 6.0, SleepQuality.poor),
        ],
        moodEntries: [],
        habits: [],
        completions: [],
        events: [],
      );
      expect(result.length, 3);
      expect(result[0].date.day, 1);
      expect(result[1].date.day, 3);
      expect(result[2].date.day, 5);
    });

    test('ignores inactive habits', () {
      final habits = [
        makeHabit('h1'),
        Habit(id: 'h2', name: 'Inactive', createdAt: DateTime(2026, 1, 1), isActive: false),
      ];
      final result = service.buildSnapshots(
        sleepEntries: [],
        moodEntries: [],
        habits: habits,
        completions: [makeCompletion('h1', day(1))],
        events: [],
      );
      expect(result[0].habitsDue, 1); // only h1 is active
      expect(result[0].habitsCompleted, 1);
    });
  });

  // ── DailySnapshot ────────────────────────────────────────────────

  group('DailySnapshot', () {
    test('habitCompletionRate returns null when no habits due', () {
      final snap = DailySnapshot(date: DateTime(2026, 1, 1), habitsDue: 0, habitsCompleted: 0);
      expect(snap.habitCompletionRate, isNull);
    });

    test('habitCompletionRate returns correct ratio', () {
      final snap = DailySnapshot(date: DateTime(2026, 1, 1), habitsDue: 4, habitsCompleted: 3);
      expect(snap.habitCompletionRate, closeTo(0.75, 0.01));
    });
  });

  // ── Correlation Analysis ─────────────────────────────────────────

  group('analyze', () {
    test('returns empty report for no snapshots', () {
      final report = service.analyze([]);
      expect(report.correlations, isEmpty);
      expect(report.totalDays, 0);
      expect(report.topInsights, contains(contains('Not enough data')));
    });

    test('returns no correlations below minimum sample size', () {
      // Only 2 snapshots, minSampleSize=3
      final snapshots = [
        DailySnapshot(date: day(1), sleepHours: 7, moodScore: 4),
        DailySnapshot(date: day(2), sleepHours: 8, moodScore: 5),
      ];
      final report = service.analyze(snapshots);
      expect(report.correlations, isEmpty);
    });

    test('detects perfect positive correlation', () {
      // Sleep and mood increase together perfectly
      final snapshots = [
        DailySnapshot(date: day(1), sleepHours: 5, moodScore: 1),
        DailySnapshot(date: day(2), sleepHours: 6, moodScore: 2),
        DailySnapshot(date: day(3), sleepHours: 7, moodScore: 3),
        DailySnapshot(date: day(4), sleepHours: 8, moodScore: 4),
        DailySnapshot(date: day(5), sleepHours: 9, moodScore: 5),
      ];
      final report = service.analyze(snapshots);
      final sleepMood = report.correlations.firstWhere(
          (c) => c.variableA == 'sleep_hours' && c.variableB == 'mood_score');
      expect(sleepMood.coefficient, closeTo(1.0, 0.01));
      expect(sleepMood.strength, CorrelationStrength.veryStrong);
    });

    test('detects perfect negative correlation', () {
      final snapshots = [
        DailySnapshot(date: day(1), sleepHours: 9, moodScore: 1),
        DailySnapshot(date: day(2), sleepHours: 8, moodScore: 2),
        DailySnapshot(date: day(3), sleepHours: 7, moodScore: 3),
        DailySnapshot(date: day(4), sleepHours: 6, moodScore: 4),
        DailySnapshot(date: day(5), sleepHours: 5, moodScore: 5),
      ];
      final report = service.analyze(snapshots);
      final sleepMood = report.correlations.firstWhere(
          (c) => c.variableA == 'sleep_hours' && c.variableB == 'mood_score');
      expect(sleepMood.coefficient, closeTo(-1.0, 0.01));
    });

    test('detects no correlation for unrelated data', () {
      final snapshots = [
        DailySnapshot(date: day(1), sleepHours: 7, moodScore: 3),
        DailySnapshot(date: day(2), sleepHours: 5, moodScore: 5),
        DailySnapshot(date: day(3), sleepHours: 9, moodScore: 1),
        DailySnapshot(date: day(4), sleepHours: 6, moodScore: 4),
        DailySnapshot(date: day(5), sleepHours: 8, moodScore: 2),
        DailySnapshot(date: day(6), sleepHours: 7, moodScore: 3),
      ];
      final report = service.analyze(snapshots);
      final sleepMood = report.correlations.firstWhere(
          (c) => c.variableA == 'sleep_hours' && c.variableB == 'mood_score');
      expect(sleepMood.coefficient.abs(), lessThan(0.3));
    });

    test('sorts correlations by absolute strength', () {
      // Strong sleep-mood, weak event-mood
      final snapshots = [
        DailySnapshot(date: day(1), sleepHours: 5, moodScore: 1, eventCount: 3),
        DailySnapshot(date: day(2), sleepHours: 6, moodScore: 2, eventCount: 2),
        DailySnapshot(date: day(3), sleepHours: 7, moodScore: 3, eventCount: 4),
        DailySnapshot(date: day(4), sleepHours: 8, moodScore: 4, eventCount: 1),
        DailySnapshot(date: day(5), sleepHours: 9, moodScore: 5, eventCount: 5),
      ];
      final report = service.analyze(snapshots);
      if (report.correlations.length >= 2) {
        for (int i = 0; i < report.correlations.length - 1; i++) {
          expect(report.correlations[i].coefficient.abs(),
              greaterThanOrEqualTo(report.correlations[i + 1].coefficient.abs()));
        }
      }
    });

    test('skips pairs with insufficient data', () {
      // Only 2 of 4 have mood
      final snapshots = [
        DailySnapshot(date: day(1), sleepHours: 7, moodScore: 3),
        DailySnapshot(date: day(2), sleepHours: 8, moodScore: null),
        DailySnapshot(date: day(3), sleepHours: 6, moodScore: null),
        DailySnapshot(date: day(4), sleepHours: 9, moodScore: 5),
      ];
      final report = service.analyze(snapshots);
      final sleepMood = report.correlations.where(
          (c) => c.variableA == 'sleep_hours' && c.variableB == 'mood_score');
      expect(sleepMood, isEmpty); // only 2 paired points < minSampleSize=3
    });

    test('computes variable stats', () {
      final snapshots = [
        DailySnapshot(date: day(1), sleepHours: 6),
        DailySnapshot(date: day(2), sleepHours: 7),
        DailySnapshot(date: day(3), sleepHours: 8),
      ];
      final report = service.analyze(snapshots);
      final stats = report.variableStats['sleep_hours'];
      expect(stats, isNotNull);
      expect(stats!.mean, closeTo(7.0, 0.01));
      expect(stats.min, closeTo(6.0, 0.01));
      expect(stats.max, closeTo(8.0, 0.01));
      expect(stats.count, 3);
      expect(stats.stdDev, closeTo(1.0, 0.01));
    });

    test('generates top insights', () {
      final snapshots = [
        DailySnapshot(date: day(1), sleepHours: 5, moodScore: 1),
        DailySnapshot(date: day(2), sleepHours: 6, moodScore: 2),
        DailySnapshot(date: day(3), sleepHours: 7, moodScore: 3),
        DailySnapshot(date: day(4), sleepHours: 8, moodScore: 4),
      ];
      final report = service.analyze(snapshots);
      expect(report.topInsights, isNotEmpty);
      expect(report.topInsights.first, contains('sleep duration'));
    });

    test('handles constant values (zero variance)', () {
      final snapshots = [
        DailySnapshot(date: day(1), sleepHours: 7, moodScore: 3),
        DailySnapshot(date: day(2), sleepHours: 7, moodScore: 3),
        DailySnapshot(date: day(3), sleepHours: 7, moodScore: 3),
      ];
      final report = service.analyze(snapshots);
      final sleepMood = report.correlations.where(
          (c) => c.variableA == 'sleep_hours' && c.variableB == 'mood_score');
      if (sleepMood.isNotEmpty) {
        expect(sleepMood.first.coefficient, closeTo(0.0, 0.01));
      }
    });
  });

  // ── Correlation Classification ───────────────────────────────────

  group('CorrelationStrength', () {
    test('all strengths have labels', () {
      for (final s in CorrelationStrength.values) {
        expect(s.label, isNotEmpty);
      }
    });
  });

  // ── Activity Mood Impact ─────────────────────────────────────────

  group('activityMoodImpact', () {
    test('returns empty when insufficient data', () {
      final service2 = const CorrelationAnalyzerService(minSampleSize: 10);
      final snapshots = [
        DailySnapshot(date: day(1), moodScore: 4,
            moodActivities: [MoodActivity.exercise]),
      ];
      expect(service2.activityMoodImpact(snapshots), isEmpty);
    });

    test('computes positive impact for exercise', () {
      final snapshots = [
        DailySnapshot(date: day(1), moodScore: 5,
            moodActivities: [MoodActivity.exercise]),
        DailySnapshot(date: day(2), moodScore: 5,
            moodActivities: [MoodActivity.exercise]),
        DailySnapshot(date: day(3), moodScore: 2, moodActivities: []),
        DailySnapshot(date: day(4), moodScore: 2, moodActivities: []),
        DailySnapshot(date: day(5), moodScore: 3, moodActivities: []),
      ];
      final impact = service.activityMoodImpact(snapshots);
      expect(impact[MoodActivity.exercise], greaterThan(0));
    });

    test('computes negative impact for work-only days', () {
      final snapshots = [
        DailySnapshot(date: day(1), moodScore: 2,
            moodActivities: [MoodActivity.work]),
        DailySnapshot(date: day(2), moodScore: 1,
            moodActivities: [MoodActivity.work]),
        DailySnapshot(date: day(3), moodScore: 5, moodActivities: []),
        DailySnapshot(date: day(4), moodScore: 5, moodActivities: []),
        DailySnapshot(date: day(5), moodScore: 5, moodActivities: []),
      ];
      final impact = service.activityMoodImpact(snapshots);
      expect(impact[MoodActivity.work], lessThan(0));
    });
  });

  // ── Factor Sleep Impact ──────────────────────────────────────────

  group('factorSleepImpact', () {
    test('returns empty when insufficient data', () {
      expect(service.factorSleepImpact([]), isEmpty);
    });

    test('computes negative impact for caffeine', () {
      final snapshots = [
        DailySnapshot(date: day(1), sleepQuality: 2,
            sleepFactors: [SleepFactor.caffeine]),
        DailySnapshot(date: day(2), sleepQuality: 1,
            sleepFactors: [SleepFactor.caffeine]),
        DailySnapshot(date: day(3), sleepQuality: 5, sleepFactors: []),
        DailySnapshot(date: day(4), sleepQuality: 4, sleepFactors: []),
        DailySnapshot(date: day(5), sleepQuality: 5, sleepFactors: []),
      ];
      final impact = service.factorSleepImpact(snapshots);
      expect(impact[SleepFactor.caffeine], lessThan(0));
    });

    test('computes positive impact for meditation', () {
      final snapshots = [
        DailySnapshot(date: day(1), sleepQuality: 5,
            sleepFactors: [SleepFactor.meditation]),
        DailySnapshot(date: day(2), sleepQuality: 5,
            sleepFactors: [SleepFactor.meditation]),
        DailySnapshot(date: day(3), sleepQuality: 2, sleepFactors: []),
        DailySnapshot(date: day(4), sleepQuality: 2, sleepFactors: []),
        DailySnapshot(date: day(5), sleepQuality: 3, sleepFactors: []),
      ];
      final impact = service.factorSleepImpact(snapshots);
      expect(impact[SleepFactor.meditation], greaterThan(0));
    });
  });

  // ── Rolling Correlation ──────────────────────────────────────────

  group('rollingCorrelation', () {
    test('returns empty for insufficient window', () {
      final snapshots = [
        DailySnapshot(date: day(1), sleepHours: 7, moodScore: 4),
        DailySnapshot(date: day(2), sleepHours: 8, moodScore: 5),
      ];
      final result = service.rollingCorrelation(
        snapshots: snapshots,
        extractA: (s) => s.sleepHours,
        extractB: (s) => s.moodScore?.toDouble(),
        windowSize: 5,
      );
      expect(result, isEmpty);
    });

    test('computes rolling values for adequate data', () {
      final snapshots = List.generate(10, (i) => DailySnapshot(
            date: day(i + 1),
            sleepHours: 5.0 + i,
            moodScore: 1 + (i % 5),
          ));
      final result = service.rollingCorrelation(
        snapshots: snapshots,
        extractA: (s) => s.sleepHours,
        extractB: (s) => s.moodScore?.toDouble(),
        windowSize: 5,
      );
      expect(result, isNotEmpty);
      expect(result.length, 6); // 10 - 5 + 1
      for (final entry in result) {
        expect(entry.value, inInclusiveRange(-1.0, 1.0));
      }
    });
  });

  // ── Full Analysis ────────────────────────────────────────────────

  group('fullAnalysis', () {
    test('runs end-to-end with mixed data', () {
      final report = service.fullAnalysis(
        sleepEntries: [
          makeSleep(day(1), 7.5, SleepQuality.good),
          makeSleep(day(2), 6.0, SleepQuality.poor),
          makeSleep(day(3), 8.0, SleepQuality.excellent),
          makeSleep(day(4), 5.5, SleepQuality.terrible),
          makeSleep(day(5), 7.0, SleepQuality.fair),
        ],
        moodEntries: [
          makeMood(day(1), MoodLevel.good),
          makeMood(day(2), MoodLevel.bad),
          makeMood(day(3), MoodLevel.great),
          makeMood(day(4), MoodLevel.veryBad),
          makeMood(day(5), MoodLevel.neutral),
        ],
        habits: [makeHabit('h1')],
        completions: [
          makeCompletion('h1', day(1)),
          makeCompletion('h1', day(3)),
          makeCompletion('h1', day(5)),
        ],
        events: [
          makeEvent(day(1), const Duration(hours: 2)),
          makeEvent(day(3), const Duration(hours: 1)),
        ],
      );

      expect(report.totalDays, 5);
      expect(report.snapshots.length, 5);
      expect(report.correlations, isNotEmpty);
      expect(report.variableStats, isNotEmpty);

      // Sleep-mood should show positive correlation
      final sleepMood = report.correlations.firstWhere(
          (c) => c.variableA == 'sleep_hours' && c.variableB == 'mood_score');
      expect(sleepMood.coefficient, greaterThan(0.5));
    });

    test('returns sensible report with only sleep data', () {
      final report = service.fullAnalysis(
        sleepEntries: [
          makeSleep(day(1), 7.0, SleepQuality.good),
          makeSleep(day(2), 8.0, SleepQuality.excellent),
          makeSleep(day(3), 6.0, SleepQuality.fair),
        ],
        moodEntries: [],
        habits: [],
        completions: [],
        events: [],
      );
      expect(report.totalDays, 3);
      expect(report.variableStats.containsKey('sleep_hours'), isTrue);
    });
  });
}

// No trailing helpers needed.
