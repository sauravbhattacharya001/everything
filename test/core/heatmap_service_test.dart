import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/heatmap_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';
import 'package:everything/models/recurrence_rule.dart';

void main() {
  late HeatmapService service;

  setUp(() {
    service = HeatmapService();
  });

  EventModel _makeEvent({
    String id = 'e1',
    String title = 'Test Event',
    required DateTime date,
    DateTime? endDate,
    EventPriority priority = EventPriority.medium,
    RecurrenceRule? recurrence,
  }) {
    return EventModel(
      id: id,
      title: title,
      date: date,
      endDate: endDate,
      priority: priority,
      recurrence: recurrence,
    );
  }

  group('HeatmapService - generate', () {
    test('returns empty heatmap for empty event list', () {
      final data = service.generate([], year: 2026);
      expect(data.year, 2026);
      expect(data.weeks.isNotEmpty, true);
      expect(data.stats.totalEvents, 0);
      expect(data.stats.activeDays, 0);
      expect(data.stats.busiestDay, isNull);
      expect(data.stats.longestStreak, 0);
      expect(data.stats.currentStreak, 0);
    });

    test('single event produces correct cell', () {
      final event = _makeEvent(date: DateTime(2026, 6, 15, 10, 0));
      final data = service.generate([event], year: 2026);

      // Find the cell for June 15
      HeatmapCell? found;
      for (final week in data.weeks) {
        for (final cell in week.cells) {
          if (cell != null &&
              cell.date.month == 6 &&
              cell.date.day == 15) {
            found = cell;
            break;
          }
        }
        if (found != null) break;
      }

      expect(found, isNotNull);
      expect(found!.eventCount, 1);
      expect(found.intensity, 1);
      expect(found.hasEvents, true);
      expect(found.events.length, 1);
      expect(found.events.first.title, 'Test Event');
    });

    test('multiple events on same day increase intensity', () {
      final events = List.generate(5, (i) => _makeEvent(
            id: 'e$i',
            title: 'Event $i',
            date: DateTime(2026, 3, 10, 9 + i, 0),
          ));
      final data = service.generate(events, year: 2026);

      HeatmapCell? found;
      for (final week in data.weeks) {
        for (final cell in week.cells) {
          if (cell != null &&
              cell.date.month == 3 &&
              cell.date.day == 10) {
            found = cell;
            break;
          }
        }
        if (found != null) break;
      }

      expect(found, isNotNull);
      expect(found!.eventCount, 5);
      // 5 events → intensity 3 (thresholds: 1, 3, 5, 8)
      expect(found.intensity, 3);
    });

    test('events outside target year are excluded', () {
      final events = [
        _makeEvent(id: 'e1', date: DateTime(2025, 12, 31)),
        _makeEvent(id: 'e2', date: DateTime(2026, 1, 1)),
        _makeEvent(id: 'e3', date: DateTime(2027, 1, 1)),
      ];
      final data = service.generate(events, year: 2026);

      expect(data.stats.totalEvents, 1);
      expect(data.stats.activeDays, 1);
    });

    test('urgent events tracked in cell', () {
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2026, 7, 4),
          priority: EventPriority.urgent,
        ),
        _makeEvent(
          id: 'e2',
          date: DateTime(2026, 7, 4),
          priority: EventPriority.low,
        ),
      ];
      final data = service.generate(events, year: 2026);

      HeatmapCell? found;
      for (final week in data.weeks) {
        for (final cell in week.cells) {
          if (cell != null &&
              cell.date.month == 7 &&
              cell.date.day == 4) {
            found = cell;
            break;
          }
        }
        if (found != null) break;
      }

      expect(found, isNotNull);
      expect(found!.urgentCount, 1);
      expect(found.hasUrgent, true);
    });

    test('high priority events counted as urgent', () {
      final events = [
        _makeEvent(
          id: 'e1',
          date: DateTime(2026, 5, 1),
          priority: EventPriority.high,
        ),
      ];
      final data = service.generate(events, year: 2026);

      HeatmapCell? found;
      for (final week in data.weeks) {
        for (final cell in week.cells) {
          if (cell != null &&
              cell.date.month == 5 &&
              cell.date.day == 1) {
            found = cell;
            break;
          }
        }
        if (found != null) break;
      }

      expect(found!.urgentCount, 1);
    });

    test('heatmap covers all 365/366 days of the year', () {
      final data = service.generate([], year: 2026);
      final allCells = data.weeks
          .expand((w) => w.cells)
          .whereType<HeatmapCell>()
          .toList();

      // 2026 is not a leap year → 365 days
      expect(allCells.length, 365);
    });

    test('leap year has 366 day cells', () {
      final data = service.generate([], year: 2024);
      final allCells = data.weeks
          .expand((w) => w.cells)
          .whereType<HeatmapCell>()
          .toList();

      expect(allCells.length, 366);
    });

    test('month labels are generated', () {
      final data = service.generate([], year: 2026);
      expect(data.monthLabels.isNotEmpty, true);
      // Should have labels for most months
      expect(data.monthLabels.length, greaterThanOrEqualTo(10));
    });

    test('each week has exactly 7 cells', () {
      final data = service.generate([], year: 2026);
      for (final week in data.weeks) {
        expect(week.cells.length, 7);
      }
    });

    test('busiest day identified correctly', () {
      final events = [
        _makeEvent(id: 'a1', date: DateTime(2026, 4, 1)),
        _makeEvent(id: 'b1', date: DateTime(2026, 4, 10)),
        _makeEvent(id: 'b2', date: DateTime(2026, 4, 10)),
        _makeEvent(id: 'b3', date: DateTime(2026, 4, 10)),
      ];
      final data = service.generate(events, year: 2026);

      expect(data.stats.busiestDay, isNotNull);
      expect(data.stats.busiestDay!.date.day, 10);
      expect(data.stats.busiestDay!.eventCount, 3);
    });

    test('activity rate computed correctly', () {
      final events = [
        _makeEvent(id: 'e1', date: DateTime(2026, 1, 1)),
        _makeEvent(id: 'e2', date: DateTime(2026, 1, 2)),
      ];
      final data = service.generate(events, year: 2026);

      expect(data.stats.activeDays, 2);
      expect(data.stats.totalDays, 365);
      // 2/365 * 100 ≈ 0.55%
      expect(data.stats.activityRate, closeTo(0.55, 0.1));
    });

    test('average events per active day', () {
      final events = [
        _makeEvent(id: 'e1', date: DateTime(2026, 2, 1)),
        _makeEvent(id: 'e2', date: DateTime(2026, 2, 1)),
        _makeEvent(id: 'e3', date: DateTime(2026, 2, 1)),
        _makeEvent(id: 'e4', date: DateTime(2026, 2, 2)),
      ];
      final data = service.generate(events, year: 2026);

      expect(data.stats.activeDays, 2);
      expect(data.stats.avgEventsPerActiveDay, 2.0);
    });

    test('consecutive day streak computed correctly', () {
      final events = [
        _makeEvent(id: 'e1', date: DateTime(2026, 3, 1)),
        _makeEvent(id: 'e2', date: DateTime(2026, 3, 2)),
        _makeEvent(id: 'e3', date: DateTime(2026, 3, 3)),
        // gap
        _makeEvent(id: 'e4', date: DateTime(2026, 3, 5)),
        _makeEvent(id: 'e5', date: DateTime(2026, 3, 6)),
      ];
      final data = service.generate(events, year: 2026);

      expect(data.stats.longestStreak, 3);
    });

    test('recurring events are expanded into heatmap', () {
      final event = _makeEvent(
        id: 'recurring',
        date: DateTime(2026, 1, 5),
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
        ),
      );
      final data = service.generate([event], year: 2026);

      // Weekly recurrence starting Jan 5 → multiple cells populated
      final activeCells = data.weeks
          .expand((w) => w.cells)
          .whereType<HeatmapCell>()
          .where((c) => c.hasEvents)
          .toList();

      // Should have the base event + weekly occurrences (up to 52)
      expect(activeCells.length, greaterThan(10));
    });

    test('custom thresholds affect intensity', () {
      final events = List.generate(3, (i) => _makeEvent(
            id: 'e$i',
            date: DateTime(2026, 8, 20, 10 + i),
          ));
      // With custom thresholds [1, 2, 3, 4], 3 events → intensity 3
      final data = service.generate(
        events,
        year: 2026,
        thresholds: [1, 2, 3, 4],
      );

      HeatmapCell? found;
      for (final week in data.weeks) {
        for (final cell in week.cells) {
          if (cell != null &&
              cell.date.month == 8 &&
              cell.date.day == 20) {
            found = cell;
            break;
          }
        }
        if (found != null) break;
      }

      expect(found, isNotNull);
      expect(found!.intensity, 3);
    });

    test('default thresholds are provided', () {
      final data = service.generate([], year: 2026);
      expect(data.thresholds, HeatmapService.defaultThresholds);
      expect(data.thresholds, [1, 3, 5, 8]);
    });
  });

  group('HeatmapService - intensity computation', () {
    test('0 events → intensity 0', () {
      final events = <EventModel>[];
      final data = service.generate(events, year: 2026);
      final cell = data.weeks
          .expand((w) => w.cells)
          .whereType<HeatmapCell>()
          .first;
      expect(cell.intensity, 0);
    });

    test('1 event → intensity 1', () {
      final data = service.generate(
        [_makeEvent(date: DateTime(2026, 1, 15))],
        year: 2026,
      );
      final cell = data.weeks
          .expand((w) => w.cells)
          .whereType<HeatmapCell>()
          .firstWhere((c) => c.date.month == 1 && c.date.day == 15);
      expect(cell.intensity, 1);
    });

    test('3 events → intensity 2', () {
      final events = List.generate(3, (i) => _makeEvent(
            id: 'e$i',
            date: DateTime(2026, 1, 15, 10 + i),
          ));
      final data = service.generate(events, year: 2026);
      final cell = data.weeks
          .expand((w) => w.cells)
          .whereType<HeatmapCell>()
          .firstWhere((c) => c.date.month == 1 && c.date.day == 15);
      expect(cell.intensity, 2);
    });

    test('8 events → intensity 4', () {
      final events = List.generate(8, (i) => _makeEvent(
            id: 'e$i',
            date: DateTime(2026, 1, 15, 8 + i),
          ));
      final data = service.generate(events, year: 2026);
      final cell = data.weeks
          .expand((w) => w.cells)
          .whereType<HeatmapCell>()
          .firstWhere((c) => c.date.month == 1 && c.date.day == 15);
      expect(cell.intensity, 4);
    });

    test('10 events → still intensity 4 (max)', () {
      final events = List.generate(10, (i) => _makeEvent(
            id: 'e$i',
            date: DateTime(2026, 1, 15, 8 + i),
          ));
      final data = service.generate(events, year: 2026);
      final cell = data.weeks
          .expand((w) => w.cells)
          .whereType<HeatmapCell>()
          .firstWhere((c) => c.date.month == 1 && c.date.day == 15);
      expect(cell.intensity, 4);
    });
  });

  group('HeatmapService - edge cases', () {
    test('events on Dec 31 are included', () {
      final event = _makeEvent(date: DateTime(2026, 12, 31));
      final data = service.generate([event], year: 2026);

      final lastDayCells = data.weeks
          .expand((w) => w.cells)
          .whereType<HeatmapCell>()
          .where((c) => c.date.month == 12 && c.date.day == 31)
          .toList();

      expect(lastDayCells.length, 1);
      expect(lastDayCells.first.eventCount, 1);
    });

    test('events on Jan 1 are included', () {
      final event = _makeEvent(date: DateTime(2026, 1, 1));
      final data = service.generate([event], year: 2026);

      final firstDayCells = data.weeks
          .expand((w) => w.cells)
          .whereType<HeatmapCell>()
          .where((c) => c.date.month == 1 && c.date.day == 1)
          .toList();

      expect(firstDayCells.length, 1);
      expect(firstDayCells.first.eventCount, 1);
    });

    test('null cells for dates outside target year', () {
      final data = service.generate([], year: 2026);
      // The grid pads to full weeks, so some cells at start/end may be null
      final nullCells = data.weeks
          .expand((w) => w.cells)
          .where((c) => c == null)
          .toList();

      // Grid should have some padding nulls (unless Jan 1 is Sunday
      // and Dec 31 is Saturday — rare)
      // Just verify the total cell count makes sense
      final totalCells = data.weeks.length * 7;
      final nonNullCells = totalCells - nullCells.length;
      expect(nonNullCells, 365); // 2026 is not a leap year
    });

    test('single-day streak has length 1', () {
      final events = [
        _makeEvent(id: 'e1', date: DateTime(2026, 6, 15)),
      ];
      final data = service.generate(events, year: 2026);
      expect(data.stats.longestStreak, 1);
    });

    test('no streak gaps computed correctly', () {
      // 3 separate isolated days
      final events = [
        _makeEvent(id: 'e1', date: DateTime(2026, 3, 1)),
        _makeEvent(id: 'e2', date: DateTime(2026, 3, 5)),
        _makeEvent(id: 'e3', date: DateTime(2026, 3, 10)),
      ];
      final data = service.generate(events, year: 2026);
      expect(data.stats.longestStreak, 1);
      expect(data.stats.activeDays, 3);
    });

    test('multiple events same day count as one active day', () {
      final events = [
        _makeEvent(id: 'e1', date: DateTime(2026, 4, 1, 10)),
        _makeEvent(id: 'e2', date: DateTime(2026, 4, 1, 14)),
        _makeEvent(id: 'e3', date: DateTime(2026, 4, 1, 18)),
      ];
      final data = service.generate(events, year: 2026);
      expect(data.stats.activeDays, 1);
      expect(data.stats.totalEvents, 3);
    });
  });

  group('HeatmapCell', () {
    test('hasEvents returns false for empty cell', () {
      final cell = HeatmapCell(
        date: DateTime(2026, 1, 1),
        eventCount: 0,
        urgentCount: 0,
        intensity: 0,
        isToday: false,
        events: [],
      );
      expect(cell.hasEvents, false);
      expect(cell.hasUrgent, false);
    });

    test('hasUrgent true when urgentCount > 0', () {
      final cell = HeatmapCell(
        date: DateTime(2026, 1, 1),
        eventCount: 2,
        urgentCount: 1,
        intensity: 1,
        isToday: false,
        events: [],
      );
      expect(cell.hasUrgent, true);
    });
  });

  group('HeatmapStats', () {
    test('activityRate is 0 for 0 total days', () {
      const stats = HeatmapStats(
        totalEvents: 0,
        activeDays: 0,
        totalDays: 0,
        busiestDay: null,
        avgEventsPerActiveDay: 0,
        longestStreak: 0,
        currentStreak: 0,
      );
      expect(stats.activityRate, 0);
    });

    test('activityRate computes correctly', () {
      const stats = HeatmapStats(
        totalEvents: 10,
        activeDays: 50,
        totalDays: 365,
        busiestDay: null,
        avgEventsPerActiveDay: 0.2,
        longestStreak: 5,
        currentStreak: 2,
      );
      expect(stats.activityRate, closeTo(13.7, 0.1));
    });
  });
}
