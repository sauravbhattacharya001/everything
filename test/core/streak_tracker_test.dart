import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/streak_tracker.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/recurrence_rule.dart';

void main() {
  final today = DateTime(2026, 2, 28);

  late StreakTracker tracker;

  setUp(() {
    tracker = StreakTracker(referenceDate: today);
  });

  EventModel _event(String id, String title, DateTime date, {
    RecurrenceRule? recurrence,
  }) {
    return EventModel(
      id: id,
      title: title,
      date: date,
      recurrence: recurrence,
    );
  }

  // ─── Streak model tests ──────────────────────────────────────

  group('Streak', () {
    test('single day streak summary', () {
      final s = Streak(
        startDate: DateTime(2026, 2, 28),
        endDate: DateTime(2026, 2, 28),
        length: 1,
      );
      expect(s.summary, '1 day (Feb 28)');
    });

    test('multi-day streak summary', () {
      final s = Streak(
        startDate: DateTime(2026, 2, 25),
        endDate: DateTime(2026, 2, 28),
        length: 4,
      );
      expect(s.summary, '4 days (Feb 25 – Feb 28)');
    });

    test('isActiveOn detects active streak', () {
      final s = Streak(
        startDate: DateTime(2026, 2, 26),
        endDate: DateTime(2026, 2, 28),
        length: 3,
      );
      expect(s.isActiveOn(DateTime(2026, 2, 28)), isTrue);
    });

    test('isActiveOn false for old streak', () {
      final s = Streak(
        startDate: DateTime(2026, 2, 10),
        endDate: DateTime(2026, 2, 12),
        length: 3,
      );
      expect(s.isActiveOn(DateTime(2026, 2, 28)), isFalse);
    });

    test('equality', () {
      final a = Streak(startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 1, 3), length: 3);
      final b = Streak(startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 1, 3), length: 3);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString', () {
      final s = Streak(startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 1, 3), length: 3);
      expect(s.toString(), contains('3 days'));
    });
  });

  // ─── ActivityStats tests ──────────────────────────────────────

  group('ActivityStats', () {
    test('activityRate calculation', () {
      const stats = ActivityStats(activeDays: 10, totalDays: 30, eventsPerActiveDay: 2.0);
      expect(stats.activityRate, closeTo(33.3, 0.1));
    });

    test('activityRate zero when no days', () {
      const stats = ActivityStats(activeDays: 0, totalDays: 0, eventsPerActiveDay: 0);
      expect(stats.activityRate, 0);
    });

    test('busiestWeekdayName maps correctly', () {
      const stats = ActivityStats(
        activeDays: 5, totalDays: 30, eventsPerActiveDay: 1.0,
        busiestWeekday: 0,
      );
      expect(stats.busiestWeekdayName, 'Monday');
    });

    test('busiestWeekdayName null when no busiest', () {
      const stats = ActivityStats(activeDays: 0, totalDays: 0, eventsPerActiveDay: 0);
      expect(stats.busiestWeekdayName, isNull);
    });

    test('busiestWeekdayName Sunday', () {
      const stats = ActivityStats(
        activeDays: 1, totalDays: 7, eventsPerActiveDay: 1.0,
        busiestWeekday: 6,
      );
      expect(stats.busiestWeekdayName, 'Sunday');
    });

    test('toString includes key info', () {
      const stats = ActivityStats(
        activeDays: 5, totalDays: 10, eventsPerActiveDay: 2.0,
        busiestWeekday: 2,
      );
      expect(stats.toString(), contains('5/10'));
      expect(stats.toString(), contains('Wednesday'));
    });
  });

  // ─── StreakReport tests ──────────────────────────────────────

  group('StreakReport', () {
    test('isStreakActive true when currentStreak > 0', () {
      const report = StreakReport(
        currentStreak: 3, longestStreak: 5, totalStreaks: 2,
        streaks: [], stats: ActivityStats(activeDays: 0, totalDays: 0, eventsPerActiveDay: 0),
      );
      expect(report.isStreakActive, isTrue);
    });

    test('isStreakActive false when currentStreak is 0', () {
      const report = StreakReport(
        currentStreak: 0, longestStreak: 5, totalStreaks: 1,
        streaks: [], stats: ActivityStats(activeDays: 0, totalDays: 0, eventsPerActiveDay: 0),
      );
      expect(report.isStreakActive, isFalse);
    });

    test('motivationMessage for no streak', () {
      const report = StreakReport(
        currentStreak: 0, longestStreak: 0, totalStreaks: 0,
        streaks: [], stats: ActivityStats(activeDays: 0, totalDays: 0, eventsPerActiveDay: 0),
      );
      expect(report.motivationMessage, contains('Start'));
    });

    test('motivationMessage for short streak', () {
      const report = StreakReport(
        currentStreak: 2, longestStreak: 2, totalStreaks: 1,
        streaks: [], stats: ActivityStats(activeDays: 0, totalDays: 0, eventsPerActiveDay: 0),
      );
      expect(report.motivationMessage, contains('Nice start'));
    });

    test('motivationMessage for medium streak', () {
      const report = StreakReport(
        currentStreak: 5, longestStreak: 5, totalStreaks: 1,
        streaks: [], stats: ActivityStats(activeDays: 0, totalDays: 0, eventsPerActiveDay: 0),
      );
      expect(report.motivationMessage, contains('momentum'));
    });

    test('motivationMessage for good streak', () {
      const report = StreakReport(
        currentStreak: 10, longestStreak: 10, totalStreaks: 1,
        streaks: [], stats: ActivityStats(activeDays: 0, totalDays: 0, eventsPerActiveDay: 0),
      );
      expect(report.motivationMessage, contains('Impressive'));
    });

    test('motivationMessage for great streak', () {
      const report = StreakReport(
        currentStreak: 20, longestStreak: 20, totalStreaks: 1,
        streaks: [], stats: ActivityStats(activeDays: 0, totalDays: 0, eventsPerActiveDay: 0),
      );
      expect(report.motivationMessage, contains('Amazing'));
    });

    test('motivationMessage for legendary streak', () {
      const report = StreakReport(
        currentStreak: 35, longestStreak: 35, totalStreaks: 1,
        streaks: [], stats: ActivityStats(activeDays: 0, totalDays: 0, eventsPerActiveDay: 0),
      );
      expect(report.motivationMessage, contains('Legendary'));
    });

    test('summary includes all info', () {
      const report = StreakReport(
        currentStreak: 3, longestStreak: 7, totalStreaks: 4,
        streaks: [],
        stats: ActivityStats(
          activeDays: 15, totalDays: 30, eventsPerActiveDay: 2.5,
          busiestWeekday: 4, busiestWeekdayCount: 8,
        ),
      );
      final s = report.summary;
      expect(s, contains('Current streak: 3 days'));
      expect(s, contains('Longest streak: 7 days'));
      expect(s, contains('Total streaks: 4'));
      expect(s, contains('15/30'));
      expect(s, contains('Friday'));
    });

    test('toString', () {
      const report = StreakReport(
        currentStreak: 3, longestStreak: 7, totalStreaks: 2,
        streaks: [], stats: ActivityStats(activeDays: 0, totalDays: 0, eventsPerActiveDay: 0),
      );
      expect(report.toString(), contains('current: 3'));
      expect(report.toString(), contains('longest: 7'));
    });
  });

  // ─── StreakTracker.analyze tests ──────────────────────────────

  group('analyze', () {
    test('empty events returns zero streaks', () {
      final report = tracker.analyze([]);
      expect(report.currentStreak, 0);
      expect(report.longestStreak, 0);
      expect(report.totalStreaks, 0);
      expect(report.streaks, isEmpty);
    });

    test('single event today gives 1-day streak', () {
      final report = tracker.analyze([
        _event('1', 'A', today),
      ]);
      expect(report.currentStreak, 1);
      expect(report.longestStreak, 1);
      expect(report.totalStreaks, 1);
      expect(report.isStreakActive, isTrue);
    });

    test('single event yesterday gives 1-day streak', () {
      final report = tracker.analyze([
        _event('1', 'A', today.subtract(const Duration(days: 1))),
      ]);
      expect(report.currentStreak, 1);
      expect(report.longestStreak, 1);
    });

    test('single event two days ago gives no current streak', () {
      final report = tracker.analyze([
        _event('1', 'A', today.subtract(const Duration(days: 2))),
      ]);
      expect(report.currentStreak, 0);
      expect(report.longestStreak, 1);
    });

    test('three consecutive days ending today', () {
      final report = tracker.analyze([
        _event('1', 'A', today.subtract(const Duration(days: 2))),
        _event('2', 'B', today.subtract(const Duration(days: 1))),
        _event('3', 'C', today),
      ]);
      expect(report.currentStreak, 3);
      expect(report.longestStreak, 3);
      expect(report.totalStreaks, 1);
    });

    test('two separate streaks', () {
      final report = tracker.analyze([
        _event('1', 'A', today.subtract(const Duration(days: 10))),
        _event('2', 'B', today.subtract(const Duration(days: 9))),
        // Gap
        _event('3', 'C', today.subtract(const Duration(days: 1))),
        _event('4', 'D', today),
      ]);
      expect(report.currentStreak, 2);
      expect(report.longestStreak, 2);
      expect(report.totalStreaks, 2);
    });

    test('longest streak is not current', () {
      final report = tracker.analyze([
        // Long old streak: 5 days
        _event('1', 'A', today.subtract(const Duration(days: 20))),
        _event('2', 'B', today.subtract(const Duration(days: 19))),
        _event('3', 'C', today.subtract(const Duration(days: 18))),
        _event('4', 'D', today.subtract(const Duration(days: 17))),
        _event('5', 'E', today.subtract(const Duration(days: 16))),
        // Short current streak: 2 days
        _event('6', 'F', today.subtract(const Duration(days: 1))),
        _event('7', 'G', today),
      ]);
      expect(report.currentStreak, 2);
      expect(report.longestStreak, 5);
      expect(report.longestStreakDetails, isNotNull);
      expect(report.longestStreakDetails!.length, 5);
      expect(report.currentStreakDetails, isNotNull);
      expect(report.currentStreakDetails!.length, 2);
    });

    test('multiple events on same day count as one day', () {
      final report = tracker.analyze([
        _event('1', 'A', today),
        _event('2', 'B', today),
        _event('3', 'C', today),
      ]);
      expect(report.currentStreak, 1);
      expect(report.longestStreak, 1);
    });

    test('streaks sorted newest first', () {
      final report = tracker.analyze([
        _event('1', 'A', today.subtract(const Duration(days: 30))),
        _event('2', 'B', today.subtract(const Duration(days: 10))),
        _event('3', 'C', today),
      ]);
      expect(report.streaks.length, 3);
      // Newest first
      expect(report.streaks.first.startDate, today);
    });

    test('week-long streak', () {
      final events = List.generate(7, (i) =>
        _event('$i', 'Day $i', today.subtract(Duration(days: 6 - i))),
      );
      final report = tracker.analyze(events);
      expect(report.currentStreak, 7);
      expect(report.longestStreak, 7);
      expect(report.totalStreaks, 1);
    });

    test('stats activity rate', () {
      final report = tracker.analyze([
        _event('1', 'A', today),
        _event('2', 'B', today.subtract(const Duration(days: 1))),
      ], since: today.subtract(const Duration(days: 9)));
      expect(report.stats.activeDays, 2);
      expect(report.stats.totalDays, 10);
      expect(report.stats.activityRate, closeTo(20.0, 0.1));
    });

    test('stats eventsPerActiveDay', () {
      final report = tracker.analyze([
        _event('1', 'A', today),
        _event('2', 'B', today),
        _event('3', 'C', today),
      ]);
      expect(report.stats.eventsPerActiveDay, 3.0);
    });

    test('stats weekday distribution', () {
      // Feb 28, 2026 is a Saturday (weekday=6 → index 5)
      final report = tracker.analyze([
        _event('1', 'A', today),
      ]);
      expect(report.stats.weekdayDistribution[5], 1); // Saturday
    });

    test('stats busiest weekday', () {
      // Add multiple events on same weekday
      final mon1 = DateTime(2026, 2, 23); // Monday
      final mon2 = DateTime(2026, 2, 16); // Monday
      final tue = DateTime(2026, 2, 24); // Tuesday
      final report = tracker.analyze([
        _event('1', 'A', mon1),
        _event('2', 'B', mon2),
        _event('3', 'C', tue),
      ]);
      expect(report.stats.busiestWeekday, 0); // Monday
      expect(report.stats.busiestWeekdayName, 'Monday');
      expect(report.stats.busiestWeekdayCount, 2);
    });
  });

  // ─── currentStreakLength tests ────────────────────────────────

  group('currentStreakLength', () {
    test('returns 0 for empty events', () {
      expect(tracker.currentStreakLength([]), 0);
    });

    test('returns 1 for event today', () {
      expect(tracker.currentStreakLength([_event('1', 'A', today)]), 1);
    });

    test('returns 0 if last event was 2+ days ago', () {
      expect(tracker.currentStreakLength([
        _event('1', 'A', today.subtract(const Duration(days: 3))),
      ]), 0);
    });

    test('counts consecutive days', () {
      expect(tracker.currentStreakLength([
        _event('1', 'A', today),
        _event('2', 'B', today.subtract(const Duration(days: 1))),
        _event('3', 'C', today.subtract(const Duration(days: 2))),
      ]), 3);
    });
  });

  // ─── longestStreakLength tests ────────────────────────────────

  group('longestStreakLength', () {
    test('returns 0 for empty events', () {
      expect(tracker.longestStreakLength([]), 0);
    });

    test('returns 1 for single event', () {
      expect(tracker.longestStreakLength([_event('1', 'A', today)]), 1);
    });

    test('finds longest among multiple streaks', () {
      expect(tracker.longestStreakLength([
        // 3-day streak
        _event('1', 'A', today.subtract(const Duration(days: 20))),
        _event('2', 'B', today.subtract(const Duration(days: 19))),
        _event('3', 'C', today.subtract(const Duration(days: 18))),
        // 1-day
        _event('4', 'D', today),
      ]), 3);
    });
  });

  // ─── suggestDates tests ──────────────────────────────────────

  group('suggestDates', () {
    test('suggests today when no events', () {
      final suggestions = tracker.suggestDates([]);
      expect(suggestions.first, today);
    });

    test('does not suggest today if already active', () {
      final suggestions = tracker.suggestDates([_event('1', 'A', today)]);
      expect(suggestions.contains(today), isFalse);
    });

    test('returns requested count', () {
      final suggestions = tracker.suggestDates([], count: 5);
      expect(suggestions.length, lessThanOrEqualTo(5));
    });

    test('suggests future days', () {
      final suggestions = tracker.suggestDates([_event('1', 'A', today)], count: 3);
      expect(suggestions.length, 3);
      for (final d in suggestions) {
        expect(d.isAfter(today), isTrue);
      }
    });
  });

  // ─── Recurring event tests ───────────────────────────────────

  group('recurring events', () {
    test('daily recurring builds streak', () {
      final recurrence = RecurrenceRule(frequency: RecurrenceFrequency.daily);
      final start = today.subtract(const Duration(days: 4));
      final report = tracker.analyze([
        _event('1', 'Daily', start, recurrence: recurrence),
      ]);
      // Original + occurrences should create consecutive days
      expect(report.longestStreak, greaterThanOrEqualTo(5));
    });

    test('includeRecurring false ignores occurrences', () {
      final recurrence = RecurrenceRule(frequency: RecurrenceFrequency.daily);
      final start = today.subtract(const Duration(days: 4));
      final report = tracker.analyze([
        _event('1', 'Daily', start, recurrence: recurrence),
      ], includeRecurring: false);
      expect(report.longestStreak, 1);
    });
  });

  // ─── Edge cases ──────────────────────────────────────────────

  group('edge cases', () {
    test('events with time components still group by date', () {
      final report = tracker.analyze([
        _event('1', 'Morning', DateTime(2026, 2, 28, 9, 0)),
        _event('2', 'Evening', DateTime(2026, 2, 28, 21, 0)),
      ]);
      expect(report.stats.activeDays, 1);
      expect(report.currentStreak, 1);
    });

    test('events far in the past', () {
      final report = tracker.analyze([
        _event('1', 'Old', DateTime(2020, 1, 1)),
      ]);
      expect(report.currentStreak, 0);
      expect(report.longestStreak, 1);
      expect(report.totalStreaks, 1);
    });

    test('many streaks scattered across time', () {
      final events = <EventModel>[];
      // Create 10 isolated events (each 5 days apart)
      for (int i = 0; i < 10; i++) {
        events.add(_event('$i', 'E$i', today.subtract(Duration(days: i * 5))));
      }
      final report = tracker.analyze(events);
      expect(report.totalStreaks, 10);
      expect(report.longestStreak, 1);
    });

    test('streak ending yesterday counts as current', () {
      final yesterday = today.subtract(const Duration(days: 1));
      final report = tracker.analyze([
        _event('1', 'A', yesterday.subtract(const Duration(days: 2))),
        _event('2', 'B', yesterday.subtract(const Duration(days: 1))),
        _event('3', 'C', yesterday),
      ]);
      expect(report.currentStreak, 3);
    });

    test('large number of events on same day', () {
      final events = List.generate(100, (i) => _event('$i', 'E$i', today));
      final report = tracker.analyze(events);
      expect(report.currentStreak, 1);
      expect(report.stats.eventsPerActiveDay, 100.0);
    });
  });
}
