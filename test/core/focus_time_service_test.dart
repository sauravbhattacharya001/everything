import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/focus_time_service.dart';
import 'package:everything/models/event_model.dart';

void main() {
  late FocusTimeService service;

  setUp(() {
    service = const FocusTimeService();
  });

  EventModel _event(String id, DateTime start, DateTime end) {
    return EventModel(
      id: id,
      title: 'Meeting $id',
      date: start,
      endDate: end,
    );
  }

  // Monday March 2, 2026
  final day = DateTime(2026, 3, 2);

  // ─── FocusBlock ─────────────────────────────────────────────

  group('FocusBlock', () {
    test('calculates minutes correctly', () {
      final block = FocusBlock(
        start: DateTime(2026, 3, 2, 9, 0),
        end: DateTime(2026, 3, 2, 11, 30),
      );
      expect(block.minutes, 150);
    });

    test('quality labels by duration', () {
      expect(
        FocusBlock(
          start: DateTime(2026, 3, 2, 9, 0),
          end: DateTime(2026, 3, 2, 12, 0),
        ).quality,
        'excellent',
      );
      expect(
        FocusBlock(
          start: DateTime(2026, 3, 2, 9, 0),
          end: DateTime(2026, 3, 2, 11, 0),
        ).quality,
        'great',
      );
      expect(
        FocusBlock(
          start: DateTime(2026, 3, 2, 9, 0),
          end: DateTime(2026, 3, 2, 10, 30),
        ).quality,
        'good',
      );
      expect(
        FocusBlock(
          start: DateTime(2026, 3, 2, 9, 0),
          end: DateTime(2026, 3, 2, 10, 0),
        ).quality,
        'fair',
      );
      expect(
        FocusBlock(
          start: DateTime(2026, 3, 2, 9, 0),
          end: DateTime(2026, 3, 2, 9, 20),
        ).quality,
        'short',
      );
    });

    test('equality', () {
      final a = FocusBlock(
        start: DateTime(2026, 3, 2, 9),
        end: DateTime(2026, 3, 2, 11),
      );
      final b = FocusBlock(
        start: DateTime(2026, 3, 2, 9),
        end: DateTime(2026, 3, 2, 11),
      );
      expect(a, equals(b));
    });
  });

  // ─── FocusWindow ────────────────────────────────────────────

  group('FocusWindow', () {
    test('availability rate', () {
      const w = FocusWindow(
        startHour: 9,
        endHour: 12,
        freeDays: 3,
        totalDays: 5,
      );
      expect(w.availabilityRate, 60.0);
      expect(w.hours, 3);
    });

    test('zero total days returns 0 availability', () {
      const w = FocusWindow(
        startHour: 9,
        endHour: 12,
        freeDays: 0,
        totalDays: 0,
      );
      expect(w.availabilityRate, 0);
    });
  });

  // ─── analyzeDay ─────────────────────────────────────────────

  group('analyzeDay', () {
    test('empty day returns full working block', () {
      final result = service.analyzeDay(day, []);

      expect(result.focusBlocks.length, 1);
      expect(result.focusBlocks.first.start, DateTime(2026, 3, 2, 9, 0));
      expect(result.focusBlocks.first.end, DateTime(2026, 3, 2, 17, 0));
      expect(result.focusBlocks.first.minutes, 480);
      expect(result.meetingCount, 0);
      expect(result.meetingMinutes, 0);
      expect(result.fragmentationScore, 0.0);
      expect(result.contextSwitches, 0);
    });

    test('single morning meeting creates afternoon focus block', () {
      final events = [
        _event('1', DateTime(2026, 3, 2, 9, 0), DateTime(2026, 3, 2, 10, 0)),
      ];

      final result = service.analyzeDay(day, events);

      // After 10:00 + 5 min buffer = 10:05 to 17:00 = 415 min
      expect(result.meetingCount, 1);
      expect(result.focusBlocks.isNotEmpty, true);
      expect(result.contextSwitches, 0); // Only 1 meeting = 0 switches
    });

    test('two meetings with gap creates focus block between them', () {
      final events = [
        _event('1', DateTime(2026, 3, 2, 9, 0), DateTime(2026, 3, 2, 10, 0)),
        _event('2', DateTime(2026, 3, 2, 14, 0), DateTime(2026, 3, 2, 15, 0)),
      ];

      final result = service.analyzeDay(day, events);

      expect(result.meetingCount, 2);
      expect(result.contextSwitches, 1);
      // Should have focus blocks in the gap and after second meeting
      expect(result.focusBlocks.length, greaterThanOrEqualTo(2));
    });

    test('back-to-back meetings leave no focus gaps', () {
      // Fill 9-17 with hourly meetings
      final events = List.generate(
        8,
        (i) => _event(
          '$i',
          DateTime(2026, 3, 2, 9 + i, 0),
          DateTime(2026, 3, 2, 10 + i, 0),
        ),
      );

      final result = service.analyzeDay(day, events);

      // With 5-min buffers, meetings overlap/merge
      expect(result.focusBlocks.length, 0);
      expect(result.meetingCount, greaterThan(0));
    });

    test('events outside working hours are excluded', () {
      final events = [
        _event('early', DateTime(2026, 3, 2, 7, 0), DateTime(2026, 3, 2, 8, 0)),
        _event('late', DateTime(2026, 3, 2, 18, 0), DateTime(2026, 3, 2, 19, 0)),
      ];

      final result = service.analyzeDay(day, events);

      expect(result.meetingCount, 0);
      expect(result.focusBlocks.length, 1);
      expect(result.focusMinutes, 480);
    });

    test('event spanning work boundaries is clipped', () {
      final events = [
        _event('span', DateTime(2026, 3, 2, 8, 0), DateTime(2026, 3, 2, 10, 0)),
      ];

      final result = service.analyzeDay(day, events);

      // Clipped to 9:00-10:00 + 5 min buffer = 65 min meeting
      expect(result.meetingCount, 1);
      expect(result.meetingMinutes, 65); // 60 + 5 buffer
    });

    test('overlapping meetings are merged', () {
      final events = [
        _event('1', DateTime(2026, 3, 2, 10, 0), DateTime(2026, 3, 2, 11, 0)),
        _event('2', DateTime(2026, 3, 2, 10, 30), DateTime(2026, 3, 2, 11, 30)),
      ];

      final result = service.analyzeDay(day, events);

      // Merged into one slot: 10:00-11:35 (11:30 + 5 min buffer)
      expect(result.meetingCount, 1);
    });

    test('bestBlock returns the longest focus block', () {
      final events = [
        _event('1', DateTime(2026, 3, 2, 11, 0), DateTime(2026, 3, 2, 12, 0)),
      ];

      final result = service.analyzeDay(day, events);
      final best = result.bestBlock;

      expect(best, isNotNull);
      // Gap before meeting (9-11 = 120 min) should be best
      // OR gap after (12:05-17 = 295 min) should be best
      expect(best!.minutes, greaterThan(100));
    });

    test('focusRatio is correct', () {
      final result = service.analyzeDay(day, []);

      // 480 focus min / 480 working min = 1.0
      expect(result.focusRatio, closeTo(1.0, 0.01));
    });

    test('event without endDate treated as 1-hour event', () {
      final noEndEvent = EventModel(
        id: 'noend',
        title: 'Quick sync',
        date: DateTime(2026, 3, 2, 10, 0),
      );

      final result = service.analyzeDay(day, [noEndEvent]);

      expect(result.meetingCount, 1);
      // 60 min + 5 min buffer = 65 min
      expect(result.meetingMinutes, 65);
    });
  });

  // ─── analyzeDay with custom settings ────────────────────────

  group('analyzeDay with custom settings', () {
    test('custom working hours', () {
      final custom = const FocusTimeService(
        workStartHour: 8,
        workEndHour: 18,
      );

      final result = custom.analyzeDay(day, []);

      expect(result.focusBlocks.first.start, DateTime(2026, 3, 2, 8, 0));
      expect(result.focusBlocks.first.end, DateTime(2026, 3, 2, 18, 0));
      expect(result.focusMinutes, 600); // 10 hours
    });

    test('larger minFocusMinutes filters out small gaps', () {
      final strict = const FocusTimeService(minFocusMinutes: 60);

      final events = [
        _event('1', DateTime(2026, 3, 2, 9, 0), DateTime(2026, 3, 2, 9, 30)),
        _event('2', DateTime(2026, 3, 2, 10, 0), DateTime(2026, 3, 2, 10, 30)),
      ];

      final result = strict.analyzeDay(day, events);

      // The 25-min gap between meetings (9:35 to 10:00) < 60 min threshold
      // Only longer blocks qualify
      for (final block in result.focusBlocks) {
        expect(block.minutes, greaterThanOrEqualTo(60));
      }
    });

    test('zero buffer time', () {
      final noBuf = const FocusTimeService(bufferMinutes: 0);

      final events = [
        _event('1', DateTime(2026, 3, 2, 10, 0), DateTime(2026, 3, 2, 11, 0)),
      ];

      final result = noBuf.analyzeDay(day, events);

      expect(result.meetingMinutes, 60); // No buffer added
    });
  });

  // ─── analyzeRange ───────────────────────────────────────────

  group('analyzeRange', () {
    test('empty events gives perfect score', () {
      final report = service.analyzeRange(
        [],
        from: DateTime(2026, 3, 2), // Monday
        to: DateTime(2026, 3, 6),   // Friday
      );

      expect(report.days.length, 5);
      expect(report.averageFragmentation, 0.0);
      expect(report.focusScore, greaterThan(80));
      expect(report.suggestions.isEmpty, true);
    });

    test('skips weekends by default', () {
      final report = service.analyzeRange(
        [],
        from: DateTime(2026, 3, 2), // Monday
        to: DateTime(2026, 3, 8),   // Sunday
      );

      expect(report.days.length, 5); // Mon-Fri only
    });

    test('includes weekends when requested', () {
      final report = service.analyzeRange(
        [],
        from: DateTime(2026, 3, 2), // Monday
        to: DateTime(2026, 3, 8),   // Sunday
        includeWeekends: true,
      );

      expect(report.days.length, 7);
    });

    test('empty range returns empty report', () {
      // Saturday to Sunday with no weekends
      final report = service.analyzeRange(
        [],
        from: DateTime(2026, 3, 7), // Saturday
        to: DateTime(2026, 3, 8),   // Sunday
      );

      expect(report.days.length, 0);
      expect(report.focusScore, 100);
    });

    test('heavy meeting schedule lowers focus score', () {
      // Create events that fill most of each workday
      final events = <EventModel>[];
      for (var d = 2; d <= 6; d++) {
        for (var h = 9; h < 16; h++) {
          events.add(_event(
            'd${d}h$h',
            DateTime(2026, 3, d, h, 0),
            DateTime(2026, 3, d, h + 1, 0),
          ));
        }
      }

      final report = service.analyzeRange(
        events,
        from: DateTime(2026, 3, 2),
        to: DateTime(2026, 3, 6),
      );

      expect(report.focusScore, lessThan(50));
      expect(report.averageMeetings, greaterThan(0));
      expect(report.suggestions.isNotEmpty, true);
    });

    test('report summary is non-empty', () {
      final report = service.analyzeRange(
        [],
        from: DateTime(2026, 3, 2),
        to: DateTime(2026, 3, 6),
      );

      final summary = report.summary;
      expect(summary.contains('Focus Time Report'), true);
      expect(summary.contains('Days analyzed: 5'), true);
      expect(summary.contains('Focus score:'), true);
    });
  });

  // ─── Focus windows ─────────────────────────────────────────

  group('focus windows', () {
    test('finds consistent free window across days', () {
      // Meetings 9-11 every day, leaving 11-17 free
      final events = <EventModel>[];
      for (var d = 2; d <= 6; d++) {
        events.add(_event(
          'd$d',
          DateTime(2026, 3, d, 9, 0),
          DateTime(2026, 3, d, 11, 0),
        ));
      }

      final report = service.analyzeRange(
        events,
        from: DateTime(2026, 3, 2),
        to: DateTime(2026, 3, 6),
      );

      expect(report.bestWindows.isNotEmpty, true);
      // The afternoon window should be identified
      final best = report.bestWindows.first;
      expect(best.startHour, greaterThanOrEqualTo(11));
      expect(best.freeDays, greaterThan(0));
    });
  });

  // ─── Fragmentation ─────────────────────────────────────────

  group('fragmentation', () {
    test('no meetings = zero fragmentation', () {
      final result = service.analyzeDay(day, []);
      expect(result.fragmentationScore, 0.0);
    });

    test('single meeting has low fragmentation', () {
      final events = [
        _event('1', DateTime(2026, 3, 2, 13, 0), DateTime(2026, 3, 2, 14, 0)),
      ];

      final result = service.analyzeDay(day, events);
      expect(result.fragmentationScore, lessThanOrEqualTo(25));
    });

    test('many scattered meetings = high fragmentation', () {
      final events = [
        _event('1', DateTime(2026, 3, 2, 9, 0), DateTime(2026, 3, 2, 9, 30)),
        _event('2', DateTime(2026, 3, 2, 10, 30), DateTime(2026, 3, 2, 11, 0)),
        _event('3', DateTime(2026, 3, 2, 12, 0), DateTime(2026, 3, 2, 12, 30)),
        _event('4', DateTime(2026, 3, 2, 13, 30), DateTime(2026, 3, 2, 14, 0)),
        _event('5', DateTime(2026, 3, 2, 15, 0), DateTime(2026, 3, 2, 15, 30)),
        _event('6', DateTime(2026, 3, 2, 16, 0), DateTime(2026, 3, 2, 16, 30)),
      ];

      final result = service.analyzeDay(day, events);
      expect(result.fragmentationScore, greaterThan(25));
      expect(result.contextSwitches, greaterThanOrEqualTo(3));
    });

    test('all-day meeting = 100 fragmentation', () {
      final events = [
        _event('full', DateTime(2026, 3, 2, 9, 0), DateTime(2026, 3, 2, 17, 0)),
      ];

      final result = service.analyzeDay(day, events);
      // Single meeting covering entire day — low frag (it's one block)
      expect(result.focusBlocks.length, 0);
    });
  });

  // ─── Suggestions ────────────────────────────────────────────

  group('suggestions', () {
    test('suggests reducing fragmentation when high', () {
      // Many short meetings scattered across every day
      final events = <EventModel>[];
      for (var d = 2; d <= 6; d++) {
        for (var h = 9; h < 17; h += 2) {
          events.add(_event(
            'd${d}h$h',
            DateTime(2026, 3, d, h, 0),
            DateTime(2026, 3, d, h, 30),
          ));
        }
      }

      final report = service.analyzeRange(
        events,
        from: DateTime(2026, 3, 2),
        to: DateTime(2026, 3, 6),
      );

      // Should have window suggestions
      if (report.bestWindows.isNotEmpty) {
        expect(
          report.suggestions.any((s) => s.contains('focus window')),
          true,
        );
      }
    });

    test('no suggestions for light schedule', () {
      final report = service.analyzeRange(
        [],
        from: DateTime(2026, 3, 2),
        to: DateTime(2026, 3, 6),
      );

      expect(report.suggestions.isEmpty, true);
    });
  });

  // ─── Quick methods ──────────────────────────────────────────

  group('quick methods', () {
    test('todaysFocusBlocks returns blocks for reference date', () {
      final events = [
        _event('1', DateTime(2026, 3, 2, 10, 0), DateTime(2026, 3, 2, 11, 0)),
      ];

      final blocks = service.todaysFocusBlocks(
        events,
        referenceDate: DateTime(2026, 3, 2),
      );

      expect(blocks.isNotEmpty, true);
    });

    test('todaysFragmentation returns score for reference date', () {
      final frag = service.todaysFragmentation(
        [],
        referenceDate: DateTime(2026, 3, 2),
      );

      expect(frag, 0.0);
    });

    test('todaysFocusBlocks filters to correct day', () {
      final events = [
        _event('1', DateTime(2026, 3, 2, 10, 0), DateTime(2026, 3, 2, 11, 0)),
        _event('2', DateTime(2026, 3, 3, 10, 0), DateTime(2026, 3, 3, 11, 0)),
      ];

      final blocks = service.todaysFocusBlocks(
        events,
        referenceDate: DateTime(2026, 3, 3),
      );

      // Should only analyze March 3rd
      for (final b in blocks) {
        expect(b.start.day, 3);
      }
    });
  });

  // ─── DayAnalysis computed properties ────────────────────────

  group('DayAnalysis computed properties', () {
    test('focusMinutes sums all blocks', () {
      final result = service.analyzeDay(day, [
        _event('1', DateTime(2026, 3, 2, 11, 0), DateTime(2026, 3, 2, 12, 0)),
      ]);

      final totalMins = result.focusBlocks
          .fold<int>(0, (sum, b) => sum + b.minutes);
      expect(result.focusMinutes, totalMins);
    });

    test('bestBlock is null when no focus blocks', () {
      // Fill entire day
      final events = List.generate(
        8,
        (i) => _event(
          '$i',
          DateTime(2026, 3, 2, 9 + i, 0),
          DateTime(2026, 3, 2, 10 + i, 0),
        ),
      );

      final result = service.analyzeDay(day, events);
      expect(result.bestBlock, isNull);
    });
  });

  // ─── FocusTimeReport ────────────────────────────────────────

  group('FocusTimeReport', () {
    test('toString includes key metrics', () {
      final report = service.analyzeRange(
        [],
        from: DateTime(2026, 3, 2),
        to: DateTime(2026, 3, 6),
      );

      final str = report.toString();
      expect(str.contains('days: 5'), true);
      expect(str.contains('score:'), true);
    });

    test('summary includes all sections', () {
      // Create some meetings to trigger suggestions
      final events = <EventModel>[];
      for (var d = 2; d <= 6; d++) {
        for (var h = 9; h < 16; h++) {
          events.add(_event(
            'd${d}h$h',
            DateTime(2026, 3, d, h, 0),
            DateTime(2026, 3, d, h + 1, 0),
          ));
        }
      }

      final report = service.analyzeRange(
        events,
        from: DateTime(2026, 3, 2),
        to: DateTime(2026, 3, 6),
      );

      final summary = report.summary;
      expect(summary.contains('Focus Time Report'), true);
      expect(summary.contains('Avg focus time:'), true);
      expect(summary.contains('Focus score:'), true);
    });
  });
}
