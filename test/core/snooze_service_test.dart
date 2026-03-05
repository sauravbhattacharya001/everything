import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/snooze_service.dart';
import 'package:everything/models/event_model.dart';

void main() {
  // Fixed "now" for deterministic tests: Monday, March 2, 2026 at 10:00 AM
  final fixedNow = DateTime(2026, 3, 2, 10, 0);
  late SnoozeService service;

  setUp(() {
    service = SnoozeService(now: () => fixedNow);
  });

  EventModel _event(String id, DateTime date, {DateTime? endDate}) {
    return EventModel(
      id: id,
      title: 'Test Event $id',
      date: date,
      endDate: endDate,
    );
  }

  // ─── SnoozeOption ───────────────────────────────────────────

  group('SnoozeOption', () {
    test('allOptions has 10 presets', () {
      expect(SnoozeService.allOptions.length, 10);
    });

    test('all option IDs are unique', () {
      final ids = SnoozeService.allOptions.map((o) => o.id).toSet();
      expect(ids.length, SnoozeService.allOptions.length);
    });

    test('optionsByCategory filters correctly', () {
      final quick = SnoozeService.optionsByCategory(SnoozeCategory.quick);
      expect(quick.length, 3);
      expect(quick.map((o) => o.id), ['15min', '30min', '1hr']);

      final later = SnoozeService.optionsByCategory(SnoozeCategory.later);
      expect(later.length, 3);

      final nextDay = SnoozeService.optionsByCategory(SnoozeCategory.nextDay);
      expect(nextDay.length, 2);

      final nextWeek = SnoozeService.optionsByCategory(SnoozeCategory.nextWeek);
      expect(nextWeek.length, 2);
    });

    test('equality by id', () {
      const a = SnoozeOption(
        id: '15min', label: '15 minutes', icon: '⏰',
        category: SnoozeCategory.quick,
      );
      const b = SnoozeOption(
        id: '15min', label: 'Different label', icon: '🔔',
        category: SnoozeCategory.later,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('toString', () {
      expect(SnoozeService.allOptions.first.toString(),
          'SnoozeOption(15min: 15 minutes)');
    });
  });

  // ─── SnoozeRecord ─────────────────────────────────────────

  group('SnoozeRecord', () {
    test('delay computation', () {
      final record = SnoozeRecord(
        snoozedAt: fixedNow,
        originalDate: DateTime(2026, 3, 2, 10, 0),
        newDate: DateTime(2026, 3, 2, 11, 0),
        optionId: '1hr',
      );
      expect(record.delay, const Duration(hours: 1));
    });

    test('delayDescription for minutes', () {
      final record = SnoozeRecord(
        snoozedAt: fixedNow,
        originalDate: DateTime(2026, 3, 2, 10, 0),
        newDate: DateTime(2026, 3, 2, 10, 15),
        optionId: '15min',
      );
      expect(record.delayDescription, '15 minutes');
    });

    test('delayDescription for 1 minute', () {
      final record = SnoozeRecord(
        snoozedAt: fixedNow,
        originalDate: DateTime(2026, 3, 2, 10, 0),
        newDate: DateTime(2026, 3, 2, 10, 1),
        optionId: 'custom',
      );
      expect(record.delayDescription, '1 minute');
    });

    test('delayDescription for hours', () {
      final record = SnoozeRecord(
        snoozedAt: fixedNow,
        originalDate: DateTime(2026, 3, 2, 10, 0),
        newDate: DateTime(2026, 3, 2, 12, 0),
        optionId: '2hr',
      );
      expect(record.delayDescription, '2 hours');
    });

    test('delayDescription for 1 hour', () {
      final record = SnoozeRecord(
        snoozedAt: fixedNow,
        originalDate: DateTime(2026, 3, 2, 10, 0),
        newDate: DateTime(2026, 3, 2, 11, 0),
        optionId: '1hr',
      );
      expect(record.delayDescription, '1 hour');
    });

    test('delayDescription for days', () {
      final record = SnoozeRecord(
        snoozedAt: fixedNow,
        originalDate: DateTime(2026, 3, 2, 10, 0),
        newDate: DateTime(2026, 3, 5, 10, 0),
        optionId: 'custom',
      );
      expect(record.delayDescription, '3 days');
    });

    test('delayDescription for 1 day', () {
      final record = SnoozeRecord(
        snoozedAt: fixedNow,
        originalDate: DateTime(2026, 3, 2, 10, 0),
        newDate: DateTime(2026, 3, 3, 10, 0),
        optionId: 'tomorrow_morning',
      );
      expect(record.delayDescription, '1 day');
    });

    test('equality', () {
      final a = SnoozeRecord(
        snoozedAt: fixedNow,
        originalDate: DateTime(2026, 3, 2, 10, 0),
        newDate: DateTime(2026, 3, 2, 10, 15),
        optionId: '15min',
      );
      final b = SnoozeRecord(
        snoozedAt: fixedNow,
        originalDate: DateTime(2026, 3, 2, 10, 0),
        newDate: DateTime(2026, 3, 2, 10, 15),
        optionId: '15min',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('toString contains option and dates', () {
      final record = SnoozeRecord(
        snoozedAt: fixedNow,
        originalDate: DateTime(2026, 3, 2, 10, 0),
        newDate: DateTime(2026, 3, 2, 10, 15),
        optionId: '15min',
      );
      expect(record.toString(), contains('15min'));
      expect(record.toString(), contains('SnoozeRecord'));
    });
  });

  // ─── SnoozeSummary ────────────────────────────────────────

  group('SnoozeSummary', () {
    test('empty history', () {
      const summary = SnoozeSummary(eventId: 'e1', history: []);
      expect(summary.snoozeCount, 0);
      expect(summary.wasSnoozed, false);
      expect(summary.totalDelay, Duration.zero);
      expect(summary.firstOriginalDate, isNull);
      expect(summary.lastSnooze, isNull);
      expect(summary.description, 'Never snoozed');
    });

    test('single snooze summary', () {
      final records = [
        SnoozeRecord(
          snoozedAt: fixedNow,
          originalDate: DateTime(2026, 3, 2, 10, 0),
          newDate: DateTime(2026, 3, 2, 11, 0),
          optionId: '1hr',
        ),
      ];
      final summary = SnoozeSummary(eventId: 'e1', history: records);
      expect(summary.snoozeCount, 1);
      expect(summary.wasSnoozed, true);
      expect(summary.firstOriginalDate, DateTime(2026, 3, 2, 10, 0));
      expect(summary.lastSnooze, records.last);
      expect(summary.description, contains('1 time'));
    });

    test('multiple snooze summary with cumulative delay', () {
      final records = [
        SnoozeRecord(
          snoozedAt: fixedNow,
          originalDate: DateTime(2026, 3, 2, 10, 0),
          newDate: DateTime(2026, 3, 2, 10, 30),
          optionId: '30min',
        ),
        SnoozeRecord(
          snoozedAt: fixedNow.add(const Duration(minutes: 30)),
          originalDate: DateTime(2026, 3, 2, 10, 30),
          newDate: DateTime(2026, 3, 2, 11, 30),
          optionId: '1hr',
        ),
      ];
      final summary = SnoozeSummary(eventId: 'e1', history: records);
      expect(summary.snoozeCount, 2);
      expect(summary.description, contains('2 times'));
      expect(summary.totalDelay, const Duration(minutes: 90));
    });

    test('totalDelay with single snooze equals that snooze delay', () {
      final records = [
        SnoozeRecord(
          snoozedAt: fixedNow,
          originalDate: DateTime(2026, 3, 2, 10, 0),
          newDate: DateTime(2026, 3, 2, 12, 0),
          optionId: '2hr',
        ),
      ];
      final summary = SnoozeSummary(eventId: 'e1', history: records);
      expect(summary.totalDelay, const Duration(hours: 2));
    });

    test('totalDelay with three snoozes accumulates correctly', () {
      final records = [
        SnoozeRecord(
          snoozedAt: fixedNow,
          originalDate: DateTime(2026, 3, 2, 10, 0),
          newDate: DateTime(2026, 3, 2, 10, 15),
          optionId: '15min',
        ),
        SnoozeRecord(
          snoozedAt: fixedNow.add(const Duration(minutes: 15)),
          originalDate: DateTime(2026, 3, 2, 10, 15),
          newDate: DateTime(2026, 3, 2, 10, 45),
          optionId: '30min',
        ),
        SnoozeRecord(
          snoozedAt: fixedNow.add(const Duration(minutes: 45)),
          originalDate: DateTime(2026, 3, 2, 10, 45),
          newDate: DateTime(2026, 3, 2, 14, 45),
          optionId: '4hr',
        ),
      ];
      final summary = SnoozeSummary(eventId: 'e1', history: records);
      // 15min + 30min + 4hr = 4h 45m = 285 min
      expect(summary.totalDelay, const Duration(minutes: 285));
      expect(summary.snoozeCount, 3);
    });

    test('toString', () {
      const summary = SnoozeSummary(eventId: 'e1', history: []);
      expect(summary.toString(), contains('e1'));
      expect(summary.toString(), contains('Never snoozed'));
    });
  });

  // ─── computeSnoozeDate ────────────────────────────────────

  group('computeSnoozeDate', () {
    final event = _event('e1', DateTime(2026, 3, 2, 14, 0));

    test('15min adds 15 minutes', () {
      final result = service.computeSnoozeDate(event, '15min');
      expect(result, DateTime(2026, 3, 2, 14, 15));
    });

    test('30min adds 30 minutes', () {
      final result = service.computeSnoozeDate(event, '30min');
      expect(result, DateTime(2026, 3, 2, 14, 30));
    });

    test('1hr adds 1 hour', () {
      final result = service.computeSnoozeDate(event, '1hr');
      expect(result, DateTime(2026, 3, 2, 15, 0));
    });

    test('2hr adds 2 hours', () {
      final result = service.computeSnoozeDate(event, '2hr');
      expect(result, DateTime(2026, 3, 2, 16, 0));
    });

    test('4hr adds 4 hours', () {
      final result = service.computeSnoozeDate(event, '4hr');
      expect(result, DateTime(2026, 3, 2, 18, 0));
    });

    test('tonight sets to 8 PM today', () {
      final result = service.computeSnoozeDate(event, 'tonight');
      expect(result, DateTime(2026, 3, 2, 20, 0));
    });

    test('tonight after 8 PM pushes to tomorrow 8 PM', () {
      final lateService = SnoozeService(
        now: () => DateTime(2026, 3, 2, 21, 0),
      );
      final result = lateService.computeSnoozeDate(event, 'tonight');
      expect(result, DateTime(2026, 3, 3, 20, 0));
    });

    test('tomorrow_morning sets to next day 9 AM', () {
      final result = service.computeSnoozeDate(event, 'tomorrow_morning');
      expect(result, DateTime(2026, 3, 3, 9, 0));
    });

    test('tomorrow_afternoon sets to next day 2 PM', () {
      final result = service.computeSnoozeDate(event, 'tomorrow_afternoon');
      expect(result, DateTime(2026, 3, 3, 14, 0));
    });

    test('next_monday from Monday goes to following Monday', () {
      // fixedNow is Monday March 2
      final result = service.computeSnoozeDate(event, 'next_monday');
      expect(result, DateTime(2026, 3, 9, 9, 0));
    });

    test('next_monday from Wednesday', () {
      final wedService = SnoozeService(
        now: () => DateTime(2026, 3, 4, 10, 0), // Wednesday
      );
      final result = wedService.computeSnoozeDate(event, 'next_monday');
      expect(result, DateTime(2026, 3, 9, 9, 0));
    });

    test('next_monday from Friday', () {
      final friService = SnoozeService(
        now: () => DateTime(2026, 3, 6, 10, 0), // Friday
      );
      final result = friService.computeSnoozeDate(event, 'next_monday');
      expect(result, DateTime(2026, 3, 9, 9, 0));
    });

    test('next_monday from Sunday', () {
      final sunService = SnoozeService(
        now: () => DateTime(2026, 3, 8, 10, 0), // Sunday
      );
      final result = sunService.computeSnoozeDate(event, 'next_monday');
      expect(result, DateTime(2026, 3, 9, 9, 0));
    });

    test('next_week adds 7 days preserving time', () {
      final result = service.computeSnoozeDate(event, 'next_week');
      expect(result, DateTime(2026, 3, 9, 14, 0));
    });

    test('unknown option returns null', () {
      expect(service.computeSnoozeDate(event, 'invalid'), isNull);
    });
  });

  // ─── snooze ───────────────────────────────────────────────

  group('snooze', () {
    test('returns new event with updated date', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      final snoozed = service.snooze(event, '1hr');
      expect(snoozed, isNotNull);
      expect(snoozed!.date, DateTime(2026, 3, 2, 15, 0));
      expect(snoozed.id, 'e1');
      expect(snoozed.title, event.title);
    });

    test('preserves event duration on snooze', () {
      final event = _event(
        'e1',
        DateTime(2026, 3, 2, 14, 0),
        endDate: DateTime(2026, 3, 2, 15, 30), // 90 min duration
      );
      final snoozed = service.snooze(event, '2hr');
      expect(snoozed, isNotNull);
      expect(snoozed!.date, DateTime(2026, 3, 2, 16, 0));
      expect(snoozed!.endDate, DateTime(2026, 3, 2, 17, 30));
      expect(snoozed!.duration, const Duration(minutes: 90));
    });

    test('event without endDate stays without endDate', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      final snoozed = service.snooze(event, '30min');
      expect(snoozed!.endDate, isNull);
    });

    test('records snooze in history', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      service.snooze(event, '15min');
      final history = service.getHistory('e1');
      expect(history.length, 1);
      expect(history.first.optionId, '15min');
      expect(history.first.originalDate, event.date);
      expect(history.first.snoozedAt, fixedNow);
    });

    test('records reason when provided', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      service.snooze(event, '1hr', reason: 'In a meeting');
      expect(service.getHistory('e1').first.reason, 'In a meeting');
    });

    test('invalid option returns null and records nothing', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      final result = service.snooze(event, 'bad_option');
      expect(result, isNull);
      expect(service.getHistory('e1'), isEmpty);
    });

    test('multiple snoozes accumulate history', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      final s1 = service.snooze(event, '15min')!;
      service.snooze(s1, '30min');
      expect(service.getHistory('e1').length, 2);
    });
  });

  // ─── History & Summary ──────────────────────────────────

  group('history management', () {
    test('getSnoozeCount returns 0 for unknown event', () {
      expect(service.getSnoozeCount('unknown'), 0);
    });

    test('getSnoozeCount increments with snoozes', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      expect(service.getSnoozeCount('e1'), 0);
      service.snooze(event, '15min');
      expect(service.getSnoozeCount('e1'), 1);
      service.snooze(event, '30min');
      expect(service.getSnoozeCount('e1'), 2);
    });

    test('getSnoozedEventIds returns only snoozed events', () {
      final e1 = _event('e1', DateTime(2026, 3, 2, 14, 0));
      final e2 = _event('e2', DateTime(2026, 3, 2, 15, 0));
      service.snooze(e1, '15min');
      // e2 is never snoozed
      expect(service.getSnoozedEventIds(), ['e1']);
    });

    test('clearHistory removes event history', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      service.snooze(event, '15min');
      service.clearHistory('e1');
      expect(service.getHistory('e1'), isEmpty);
      expect(service.getSnoozeCount('e1'), 0);
    });

    test('clearAll removes all history', () {
      final e1 = _event('e1', DateTime(2026, 3, 2, 14, 0));
      final e2 = _event('e2', DateTime(2026, 3, 2, 15, 0));
      service.snooze(e1, '15min');
      service.snooze(e2, '30min');
      service.clearAll();
      expect(service.getSnoozedEventIds(), isEmpty);
    });

    test('getSummary for snoozed event', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      service.snooze(event, '1hr');
      final summary = service.getSummary('e1');
      expect(summary.snoozeCount, 1);
      expect(summary.wasSnoozed, true);
      expect(summary.eventId, 'e1');
    });

    test('getSummary for unknown event', () {
      final summary = service.getSummary('unknown');
      expect(summary.snoozeCount, 0);
      expect(summary.wasSnoozed, false);
      expect(summary.description, 'Never snoozed');
    });

    test('history returns unmodifiable list', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      service.snooze(event, '15min');
      final history = service.getHistory('e1');
      expect(() => history.add(SnoozeRecord(
        snoozedAt: fixedNow,
        originalDate: fixedNow,
        newDate: fixedNow,
        optionId: 'x',
      )), throwsUnsupportedError);
    });
  });

  // ─── Serial Snooze Detection ──────────────────────────────

  group('serial snooze detection', () {
    test('no alert when below threshold', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      service.snooze(event, '15min');
      service.snooze(event, '15min');
      expect(service.checkSerialSnooze('e1'), isNull);
    });

    test('warning alert at 3 snoozes in 24h', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      service.snooze(event, '15min');
      service.snooze(event, '15min');
      service.snooze(event, '15min');
      final alert = service.checkSerialSnooze('e1');
      expect(alert, isNotNull);
      expect(alert!.severity, 'warning');
      expect(alert.recentSnoozeCount, 3);
      expect(alert.suggestion, contains('better time slot'));
    });

    test('critical alert at 5+ snoozes', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      for (var i = 0; i < 5; i++) {
        service.snooze(event, '15min');
      }
      final alert = service.checkSerialSnooze('e1');
      expect(alert, isNotNull);
      expect(alert!.severity, 'critical');
      expect(alert.recentSnoozeCount, 5);
      expect(alert.suggestion, contains('cancelling or rescheduling'));
    });

    test('no alert for unknown event', () {
      expect(service.checkSerialSnooze('unknown'), isNull);
    });

    test('custom threshold', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      service.snooze(event, '15min');
      service.snooze(event, '15min');
      // Threshold 2 should trigger
      final alert = service.checkSerialSnooze('e1', threshold: 2);
      expect(alert, isNotNull);
      expect(alert!.recentSnoozeCount, 2);
    });

    test('checkAllSerialSnoozes returns alerts for all events', () {
      final e1 = _event('e1', DateTime(2026, 3, 2, 14, 0));
      final e2 = _event('e2', DateTime(2026, 3, 2, 15, 0));
      for (var i = 0; i < 3; i++) {
        service.snooze(e1, '15min');
        service.snooze(e2, '30min');
      }
      final alerts = service.checkAllSerialSnoozes();
      expect(alerts.length, 2);
    });

    test('SerialSnoozeAlert toString', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      for (var i = 0; i < 3; i++) service.snooze(event, '15min');
      final alert = service.checkSerialSnooze('e1')!;
      expect(alert.toString(), contains('e1'));
      expect(alert.toString(), contains('warning'));
    });
  });

  // ─── suggestOptions ───────────────────────────────────────

  group('suggestOptions', () {
    test('filters out options that would be in the past', () {
      // Event at 10 AM, now is 10 AM — "tonight" (8 PM) should be included
      final event = _event('e1', DateTime(2026, 3, 2, 10, 0));
      final options = service.suggestOptions(event);
      final ids = options.map((o) => o.id).toSet();
      expect(ids, contains('tonight'));
      expect(ids, contains('tomorrow_morning'));
    });

    test('past event gets only future options', () {
      // Event was yesterday at 10 AM, now is 10 AM today
      final pastEvent = _event('e1', DateTime(2026, 3, 1, 10, 0));
      final options = service.suggestOptions(pastEvent);
      // 15min, 30min, 1hr relative options on a past date would still be
      // in the past, so they should be filtered out
      for (final option in options) {
        final newDate = service.computeSnoozeDate(pastEvent, option.id);
        expect(newDate!.isAfter(fixedNow), isTrue,
            reason: '${option.id} should result in a future date');
      }
    });

    test('late night filters tonight option', () {
      final lateService = SnoozeService(
        now: () => DateTime(2026, 3, 2, 23, 0), // 11 PM
      );
      // Event at 11 PM, tonight (8 PM) would be tomorrow now
      final event = _event('e1', DateTime(2026, 3, 2, 23, 0));
      final options = lateService.suggestOptions(event);
      // All options should result in dates after 11 PM
      for (final option in options) {
        final newDate = lateService.computeSnoozeDate(event, option.id);
        expect(newDate!.isAfter(DateTime(2026, 3, 2, 23, 0)), isTrue,
            reason: '${option.id} should be after current time');
      }
    });
  });

  // ─── getMostUsedOption ────────────────────────────────────

  group('getMostUsedOption', () {
    test('returns null for unsnoozed event', () {
      expect(service.getMostUsedOption('unknown'), isNull);
    });

    test('returns the most common option', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      service.snooze(event, '15min');
      service.snooze(event, '15min');
      service.snooze(event, '1hr');
      expect(service.getMostUsedOption('e1'), '15min');
    });

    test('ties favor the first encountered', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      service.snooze(event, '15min');
      service.snooze(event, '30min');
      // Both have count 1, reduce picks the one with >= comparison
      final result = service.getMostUsedOption('e1');
      expect(result, isNotNull);
    });
  });

  // ─── Edge cases ───────────────────────────────────────────

  group('edge cases', () {
    test('snooze event at midnight', () {
      final event = _event('e1', DateTime(2026, 3, 3, 0, 0));
      final snoozed = service.snooze(event, '15min');
      expect(snoozed!.date, DateTime(2026, 3, 3, 0, 15));
    });

    test('snooze event at end of month', () {
      final event = _event('e1', DateTime(2026, 3, 31, 22, 0));
      final snoozed = service.snooze(event, '4hr');
      expect(snoozed!.date, DateTime(2026, 4, 1, 2, 0));
    });

    test('next_week at end of year', () {
      final decService = SnoozeService(
        now: () => DateTime(2026, 12, 28, 10, 0),
      );
      final event = _event('e1', DateTime(2026, 12, 28, 14, 0));
      final result = decService.computeSnoozeDate(event, 'next_week');
      expect(result, DateTime(2027, 1, 4, 14, 0));
    });

    test('snooze with reason in history', () {
      final event = _event('e1', DateTime(2026, 3, 2, 14, 0));
      service.snooze(event, '1hr', reason: 'Phone call');
      final history = service.getHistory('e1');
      expect(history.first.reason, 'Phone call');
    });

    test('summary description format for hours', () {
      final event = _event('e1', DateTime(2026, 3, 2, 10, 0));
      service.snooze(event, '2hr');
      final summary = service.getSummary('e1');
      expect(summary.description, contains('2h'));
    });

    test('summary description format for days', () {
      final event = _event('e1', DateTime(2026, 3, 2, 10, 0));
      service.snooze(event, 'next_week');
      final summary = service.getSummary('e1');
      expect(summary.description, contains('7d'));
    });
  });
}
