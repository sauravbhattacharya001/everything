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

  // ── Helper factories ───────────────────────────────────────────

  SleepEntry makeSleep(DateTime wake, double hours, SleepQuality quality,
      {int? awakenings, List<SleepFactor> factors = const []}) {
    return SleepEntry(
      id: 'sleep-${wake.toIso8601String()}',
      bedtime: wake.subtract(Duration(minutes: (hours * 60).round())),
      wakeTime: wake,
      quality: quality,
      awakenings: awakenings,
      factors: factors,
    );
  }

  MoodEntry makeMood(DateTime ts, MoodLevel mood,
      {List<MoodActivity> activities = const []}) {
    return MoodEntry(
      id: 'mood-${ts.toIso8601String()}',
      timestamp: ts,
      mood: mood,
      activities: activities,
    );
  }

  EventModel makeEvent(DateTime date, String title,
      {DateTime? endDate}) {
    return EventModel(
      id: 'event-${date.toIso8601String()}-$title',
      title: title,
      date: date,
      endDate: endDate,
    );
  }

  Habit makeHabit(String id, {HabitFrequency freq = HabitFrequency.daily}) {
    return Habit(
      id: id,
      name: id,
      frequency: freq,
      createdAt: DateTime(2025, 1, 1),
    );
  }

  // ── buildSnapshots ─────────────────────────────────────────────

  group('buildSnapshots', () {
    test('returns empty list when all inputs are empty', () {
      final snapshots = service.buildSnapshots(
        sleepEntries: [],
        moodEntries: [],
        habits: [],
        completions: [],
        events: [],
      );
      expect(snapshots, isEmpty);
    });

    test('builds snapshot from sleep data only', () {
      final wake = DateTime(2025, 3, 10, 7, 0);
      final snapshots = service.buildSnapshots(
        sleepEntries: [makeSleep(wake, 8.0, SleepQuality.good)],
        moodEntries: [],
        habits: [],
        completions: [],
        events: [],
      );
      expect(snapshots.length, 1);
      expect(snapshots[0].sleepHours, closeTo(8.0, 0.01));
      expect(snapshots[0].sleepQuality, 4); // good = 4
      expect(snapshots[0].moodScore, isNull);
    });

    test('builds snapshot from mood data only', () {
      final ts = DateTime(2025, 3, 10, 14, 0);
      final snapshots = service.buildSnapshots(
        sleepEntries: [],
        moodEntries: [makeMood(ts, MoodLevel.great, activities: [MoodActivity.exercise])],
        habits: [],
        completions: [],
        events: [],
      );
      expect(snapshots.length, 1);
      expect(snapshots[0].moodScore, 5); // great = 5
      expect(snapshots[0].moodActivities, contains(MoodActivity.exercise));
      expect(snapshots[0].sleepHours, isNull);
    });

    test('merges multiple data sources on the same day', () {
      final day = DateTime(2025, 3, 10);
      final wake = DateTime(2025, 3, 10, 7, 0);
      final moodTs = DateTime(2025, 3, 10, 12, 0);
      final eventStart = DateTime(2025, 3, 10, 9, 0);
      final eventEnd = DateTime(2025, 3, 10, 10, 0);

      final snapshots = service.buildSnapshots(
        sleepEntries: [makeSleep(wake, 7.5, SleepQuality.excellent)],
        moodEntries: [makeMood(moodTs, MoodLevel.good)],
        habits: [makeHabit('h1')],
        completions: [HabitCompletion(habitId: 'h1', date: day)],
        events: [makeEvent(eventStart, 'Meeting', endDate: eventEnd)],
      );

      expect(snapshots.length, 1);
      final s = snapshots[0];
      expect(s.sleepHours, closeTo(7.5, 0.01));
      expect(s.moodScore, 4);
      expect(s.habitsDue, 1); // daily habit, March 10 2025 is Monday
      expect(s.habitsCompleted, 1);
      expect(s.habitCompletionRate, closeTo(1.0, 0.01));
      expect(s.eventCount, 1);
      expect(s.eventHours, closeTo(1.0, 0.01));
    });

    test('averages multiple sleep entries on same day', () {
      final wake1 = DateTime(2025, 3, 10, 7, 0);
      final wake2 = DateTime(2025, 3, 10, 7, 30);
      final snapshots = service.buildSnapshots(
        sleepEntries: [
          makeSleep(wake1, 6.0, SleepQuality.poor),
          makeSleep(wake2, 8.0, SleepQuality.good),
        ],
        moodEntries: [],
        habits: [],
        completions: [],
        events: [],
      );
      expect(snapshots.length, 1);
      expect(snapshots[0].sleepHours, closeTo(7.0, 0.01));
      // poor=2, good=4, avg=3 => fair
      expect(snapshots[0].sleepQuality, 3);
    });

    test('creates separate snapshots for different days', () {
      final snapshots = service.buildSnapshots(
        sleepEntries: [
          makeSleep(DateTime(2025, 3, 10, 7, 0), 7.0, SleepQuality.good),
          makeSleep(DateTime(2025, 3, 11, 7, 0), 6.0, SleepQuality.fair),
        ],
        moodEntries: [],
        habits: [],
        completions: [],
        events: [],
      );
      expect(snapshots.length, 2);
      expect(snapshots[0].sleepHours, closeTo(7.0, 0.01));
      expect(snapshots[1].sleepHours, closeTo(6.0, 0.01));
    });
  });

  // ── analyze ────────────────────────────────────────────────────

  group('analyze', () {
    test('returns empty report for empty snapshots', () {
      final report = service.analyze([]);
      expect(report.correlations, isEmpty);
      expect(report.totalDays, 0);
      expect(report.topInsights, contains('Not enough data. Keep tracking!'));
    });

    test('detects strong positive correlation', () {
      // Create snapshots where sleep hours and mood score increase together
      final snapshots = List.generate(10, (i) {
        return DailySnapshot(
          date: DateTime(2025, 3, 1 + i),
          sleepHours: 5.0 + i * 0.5,     // 5, 5.5, 6, ..., 9.5
          moodScore: 1 + (i ~/ 2),        // 1, 1, 2, 2, 3, 3, 4, 4, 5, 5
        );
      });

      final report = service.analyze(snapshots);
      expect(report.totalDays, 10);
      expect(report.correlations, isNotEmpty);

      // Find sleep_hours ↔ mood_score correlation
      final sleepMood = report.correlations.firstWhere(
        (c) =>
            (c.variableA == 'sleep_hours' && c.variableB == 'mood_score') ||
            (c.variableA == 'mood_score' && c.variableB == 'sleep_hours'),
      );
      expect(sleepMood.coefficient, greaterThan(0.8));
      expect(sleepMood.strength, isIn([CorrelationStrength.strong, CorrelationStrength.veryStrong]));
    });

    test('detects near-perfect correlation (coeff ~1.0)', () {
      final snapshots = List.generate(10, (i) {
        return DailySnapshot(
          date: DateTime(2025, 3, 1 + i),
          sleepHours: (i + 1).toDouble(),
          eventCount: (i + 1).toDouble().toInt(),
          eventHours: (i + 1).toDouble(),
        );
      });

      final report = service.analyze(snapshots);
      // event_count and event_hours should be perfectly correlated
      final corr = report.correlations.firstWhere(
        (c) =>
            (c.variableA == 'event_count' && c.variableB == 'event_hours') ||
            (c.variableA == 'event_hours' && c.variableB == 'event_count'),
      );
      expect(corr.coefficient, closeTo(1.0, 0.01));
      expect(corr.strength, CorrelationStrength.veryStrong);
    });

    test('returns no significant correlations for random-looking data', () {
      final snapshots = [
        DailySnapshot(date: DateTime(2025, 3, 1), sleepHours: 8, moodScore: 1),
        DailySnapshot(date: DateTime(2025, 3, 2), sleepHours: 5, moodScore: 5),
        DailySnapshot(date: DateTime(2025, 3, 3), sleepHours: 9, moodScore: 2),
        DailySnapshot(date: DateTime(2025, 3, 4), sleepHours: 4, moodScore: 4),
        DailySnapshot(date: DateTime(2025, 3, 5), sleepHours: 7, moodScore: 3),
        DailySnapshot(date: DateTime(2025, 3, 6), sleepHours: 6, moodScore: 3),
        DailySnapshot(date: DateTime(2025, 3, 7), sleepHours: 8, moodScore: 2),
      ];
      final report = service.analyze(snapshots);
      // Sleep/mood correlation should be weak/negative
      final sleepMood = report.correlations.firstWhere(
        (c) =>
            (c.variableA == 'sleep_hours' && c.variableB == 'mood_score') ||
            (c.variableA == 'mood_score' && c.variableB == 'sleep_hours'),
      );
      expect(sleepMood.coefficient, lessThan(0.0));
    });

    test('generates variable stats', () {
      final snapshots = List.generate(7, (i) {
        return DailySnapshot(
          date: DateTime(2025, 3, 1 + i),
          sleepHours: 6.0 + i,
        );
      });
      final report = service.analyze(snapshots);
      expect(report.variableStats.containsKey('sleep_hours'), isTrue);
      final stats = report.variableStats['sleep_hours']!;
      expect(stats.count, 7);
      expect(stats.min, 6.0);
      expect(stats.max, 12.0);
      expect(stats.mean, closeTo(9.0, 0.01));
    });
  });

  // ── CorrelationStrength ────────────────────────────────────────

  group('CorrelationStrength', () {
    test('labels are correct', () {
      expect(CorrelationStrength.none.label, 'None');
      expect(CorrelationStrength.weak.label, 'Weak');
      expect(CorrelationStrength.moderate.label, 'Moderate');
      expect(CorrelationStrength.strong.label, 'Strong');
      expect(CorrelationStrength.veryStrong.label, 'Very Strong');
    });
  });

  // ── activityMoodImpact ─────────────────────────────────────────

  group('activityMoodImpact', () {
    test('returns empty map when not enough data', () {
      final result = service.activityMoodImpact([]);
      expect(result, isEmpty);
    });

    test('computes positive impact for exercise', () {
      // Days with exercise have higher mood
      final snapshots = [
        DailySnapshot(date: DateTime(2025, 3, 1), moodScore: 5, moodActivities: [MoodActivity.exercise]),
        DailySnapshot(date: DateTime(2025, 3, 2), moodScore: 4, moodActivities: [MoodActivity.exercise]),
        DailySnapshot(date: DateTime(2025, 3, 3), moodScore: 2, moodActivities: []),
        DailySnapshot(date: DateTime(2025, 3, 4), moodScore: 1, moodActivities: []),
        DailySnapshot(date: DateTime(2025, 3, 5), moodScore: 3, moodActivities: []),
      ];
      final impact = service.activityMoodImpact(snapshots);
      expect(impact.containsKey(MoodActivity.exercise), isTrue);
      expect(impact[MoodActivity.exercise]!, greaterThan(0));
    });
  });

  // ── factorSleepImpact ──────────────────────────────────────────

  group('factorSleepImpact', () {
    test('returns empty map when not enough data', () {
      final result = service.factorSleepImpact([]);
      expect(result, isEmpty);
    });

    test('computes negative impact for caffeine', () {
      final snapshots = [
        DailySnapshot(date: DateTime(2025, 3, 1), sleepQuality: 2, sleepFactors: [SleepFactor.caffeine]),
        DailySnapshot(date: DateTime(2025, 3, 2), sleepQuality: 1, sleepFactors: [SleepFactor.caffeine]),
        DailySnapshot(date: DateTime(2025, 3, 3), sleepQuality: 5, sleepFactors: []),
        DailySnapshot(date: DateTime(2025, 3, 4), sleepQuality: 4, sleepFactors: []),
        DailySnapshot(date: DateTime(2025, 3, 5), sleepQuality: 4, sleepFactors: []),
      ];
      final impact = service.factorSleepImpact(snapshots);
      expect(impact.containsKey(SleepFactor.caffeine), isTrue);
      expect(impact[SleepFactor.caffeine]!, lessThan(0));
    });
  });

  // ── DailySnapshot ──────────────────────────────────────────────

  group('DailySnapshot', () {
    test('habitCompletionRate is null when no habits due', () {
      final s = DailySnapshot(date: DateTime(2025, 3, 1));
      expect(s.habitCompletionRate, isNull);
    });

    test('habitCompletionRate computes correctly', () {
      final s = DailySnapshot(
        date: DateTime(2025, 3, 1),
        habitsDue: 4,
        habitsCompleted: 3,
      );
      expect(s.habitCompletionRate, closeTo(0.75, 0.01));
    });
  });

  // ── fullAnalysis ───────────────────────────────────────────────

  group('fullAnalysis', () {
    test('end-to-end from raw data', () {
      final sleepEntries = List.generate(10, (i) {
        return makeSleep(
          DateTime(2025, 3, 1 + i, 7, 0),
          6.0 + i * 0.3,
          SleepQuality.fromValue((i % 5) + 1),
        );
      });
      final moodEntries = List.generate(10, (i) {
        return makeMood(
          DateTime(2025, 3, 1 + i, 12, 0),
          MoodLevel.fromValue((i % 5) + 1),
        );
      });
      final report = service.fullAnalysis(
        sleepEntries: sleepEntries,
        moodEntries: moodEntries,
        habits: [],
        completions: [],
        events: [],
      );
      expect(report.totalDays, 10);
      expect(report.correlations, isNotEmpty);
    });
  });

  // ── rollingCorrelation ─────────────────────────────────────────

  group('rollingCorrelation', () {
    test('returns empty when fewer snapshots than window', () {
      final snapshots = List.generate(3, (i) => DailySnapshot(
        date: DateTime(2025, 3, 1 + i),
        sleepHours: 7.0 + i,
        moodScore: 3 + (i % 3),
      ));
      final result = service.rollingCorrelation(
        snapshots: snapshots,
        extractA: (s) => s.sleepHours,
        extractB: (s) => s.moodScore?.toDouble(),
        windowSize: 5,
      );
      expect(result, isEmpty);
    });

    test('returns values when enough snapshots', () {
      final snapshots = List.generate(20, (i) => DailySnapshot(
        date: DateTime(2025, 3, 1 + i),
        sleepHours: 6.0 + (i % 4),
        moodScore: 1 + (i % 5),
      ));
      final result = service.rollingCorrelation(
        snapshots: snapshots,
        extractA: (s) => s.sleepHours,
        extractB: (s) => s.moodScore?.toDouble(),
        windowSize: 7,
      );
      expect(result, isNotEmpty);
      expect(result.length, lessThanOrEqualTo(20 - 7 + 1));
    });
  });

  // ── Correlation model ──────────────────────────────────────────

  group('Correlation', () {
    test('insight text is generated', () {
      // Test via analyze
      final snapshots = List.generate(10, (i) => DailySnapshot(
        date: DateTime(2025, 3, 1 + i),
        sleepHours: 5.0 + i,
        moodScore: 1 + (i ~/ 2),
      ));
      final report = service.analyze(snapshots);
      for (final c in report.correlations) {
        expect(c.insight, isNotEmpty);
        expect(c.sampleSize, greaterThanOrEqualTo(3));
      }
    });
  });
}
