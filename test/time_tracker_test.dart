import 'package:flutter_test/flutter_test.dart';
import 'package:everything_app/models/time_entry.dart';
import 'package:everything_app/core/services/time_tracker_service.dart';

void main() {
  const service = TimeTrackerService();
  final now = DateTime.now();

  TimeEntry mk({
    String id = 't1',
    String activity = 'Coding',
    TimeCategory category = TimeCategory.work,
    DateTime? start,
    DateTime? end,
  }) => TimeEntry(id: id, activity: activity, category: category,
    startTime: start ?? now.subtract(const Duration(hours: 1)),
    endTime: end ?? now);

  group('TimeEntry model', () {
    test('duration calculates correctly for completed entry', () {
      final e = mk(start: DateTime(2026, 3, 8, 10, 0), end: DateTime(2026, 3, 8, 11, 30));
      expect(e.duration, const Duration(hours: 1, minutes: 30));
      expect(e.isRunning, false);
    });

    test('isRunning is true when endTime is null', () {
      final e = TimeEntry(id: 't1', activity: 'Test', category: TimeCategory.work, startTime: now);
      expect(e.isRunning, true);
    });

    test('copyWith preserves fields', () {
      final o = mk(activity: 'Original');
      final c = o.copyWith(activity: 'Updated');
      expect(c.activity, 'Updated');
      expect(c.id, o.id);
      expect(c.category, o.category);
    });

    test('copyWith clearEndTime', () {
      final e = mk();
      expect(e.endTime, isNotNull);
      final c = e.copyWith(clearEndTime: true);
      expect(c.endTime, isNull);
      expect(c.isRunning, true);
    });
  });

  group('TimeCategory', () {
    test('all categories have label and emoji', () {
      for (final cat in TimeCategory.values) {
        expect(cat.label, isNotEmpty);
        expect(cat.emoji, isNotEmpty);
      }
    });

    test('has 10 categories', () {
      expect(TimeCategory.values.length, 10);
    });
  });

  group('TimeTrackerService', () {
    test('getDailySummary for empty list', () {
      final s = service.getDailySummary([], now);
      expect(s.entryCount, 0);
      expect(s.totalTracked, Duration.zero);
      expect(s.categoryBreakdown, isEmpty);
    });

    test('getDailySummary calculates totals', () {
      final entries = [
        mk(id: 't1', category: TimeCategory.work, start: DateTime(2026, 3, 8, 9, 0), end: DateTime(2026, 3, 8, 11, 0)),
        mk(id: 't2', category: TimeCategory.study, start: DateTime(2026, 3, 8, 13, 0), end: DateTime(2026, 3, 8, 14, 30)),
        mk(id: 't3', category: TimeCategory.work, start: DateTime(2026, 3, 8, 15, 0), end: DateTime(2026, 3, 8, 16, 0)),
      ];
      final s = service.getDailySummary(entries, DateTime(2026, 3, 8));
      expect(s.entryCount, 3);
      expect(s.totalTracked, const Duration(hours: 3, minutes: 30));
      expect(s.categoryBreakdown[TimeCategory.work], const Duration(hours: 3));
      expect(s.categoryBreakdown[TimeCategory.study], const Duration(hours: 1, minutes: 30));
      expect(s.topCategory, 'Work');
      expect(s.longestSession, const Duration(hours: 2));
    });

    test('getDailySummary excludes running entries', () {
      final entries = [
        mk(id: 't1', start: DateTime(2026, 3, 8, 9, 0), end: DateTime(2026, 3, 8, 10, 0)),
        TimeEntry(id: 't2', activity: 'Running', category: TimeCategory.work, startTime: DateTime(2026, 3, 8, 11, 0)),
      ];
      expect(service.getDailySummary(entries, DateTime(2026, 3, 8)).entryCount, 1);
    });

    test('getDailySummary filters by date', () {
      final entries = [
        mk(id: 't1', start: DateTime(2026, 3, 7, 9, 0), end: DateTime(2026, 3, 7, 10, 0)),
        mk(id: 't2', start: DateTime(2026, 3, 8, 9, 0), end: DateTime(2026, 3, 8, 10, 0)),
      ];
      expect(service.getDailySummary(entries, DateTime(2026, 3, 8)).entryCount, 1);
    });

    test('getEntriesForDate returns sorted by most recent', () {
      final entries = [
        mk(id: 't1', start: DateTime(2026, 3, 8, 9, 0), end: DateTime(2026, 3, 8, 10, 0)),
        mk(id: 't2', start: DateTime(2026, 3, 8, 14, 0), end: DateTime(2026, 3, 8, 15, 0)),
        mk(id: 't3', start: DateTime(2026, 3, 8, 11, 0), end: DateTime(2026, 3, 8, 12, 0)),
      ];
      final r = service.getEntriesForDate(entries, DateTime(2026, 3, 8));
      expect(r.length, 3);
      expect(r[0].id, 't2');
      expect(r[1].id, 't3');
      expect(r[2].id, 't1');
    });

    test('productivityScore returns 0 for no entries', () {
      expect(service.productivityScore([], now), 0);
    });

    test('productivityScore rewards hours, variety, sessions', () {
      final d = DateTime(2026, 3, 8);
      final entries = List.generate(6, (i) => mk(id: 't$i',
        category: [TimeCategory.work, TimeCategory.study, TimeCategory.exercise][i % 3],
        start: d.add(Duration(hours: i)), end: d.add(Duration(hours: i + 1))));
      final score = service.productivityScore(entries, d);
      expect(score, greaterThan(50));
      expect(score, lessThanOrEqualTo(100));
    });

    test('formatDuration formats correctly', () {
      expect(service.formatDuration(const Duration(hours: 2, minutes: 15)), '2h 15m');
      expect(service.formatDuration(const Duration(minutes: 45)), '45m');
      expect(service.formatDuration(Duration.zero), '0m');
    });

    test('categoryColors covers all categories', () {
      for (final cat in TimeCategory.values) {
        expect(TimeTrackerService.categoryColors.containsKey(cat), true);
      }
    });

    test('getWeeklyInsights returns 3 insights', () {
      final ins = service.getWeeklyInsights([]);
      expect(ins.length, 3);
      expect(ins[0].label, 'This Week');
      expect(ins[1].label, 'Sessions');
      expect(ins[2].label, 'Avg/Day');
    });

    test('getWeeklyInsights trend detection', () {
      final ws = now.subtract(Duration(days: now.weekday - 1));
      final lws = ws.subtract(const Duration(days: 7));
      final entries = [
        mk(id: 't1', start: ws.add(const Duration(hours: 1)), end: ws.add(const Duration(hours: 4))),
        mk(id: 't2', start: lws.add(const Duration(hours: 1)), end: lws.add(const Duration(hours: 2))),
      ];
      expect(service.getWeeklyInsights(entries)[0].trend, 'up');
    });

    test('longestSession tracks correctly', () {
      final d = DateTime(2026, 3, 8);
      final entries = [
        mk(id: 't1', start: d, end: d.add(const Duration(minutes: 30))),
        mk(id: 't2', start: d.add(const Duration(hours: 2)), end: d.add(const Duration(hours: 5))),
        mk(id: 't3', start: d.add(const Duration(hours: 6)), end: d.add(const Duration(hours: 7))),
      ];
      expect(service.getDailySummary(entries, d).longestSession, const Duration(hours: 3));
    });
  });
}
