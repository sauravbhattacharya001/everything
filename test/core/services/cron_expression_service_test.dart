import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/cron_expression_service.dart';

void main() {
  group('CronExpressionService.build / parse', () {
    test('build joins 5 fields with single spaces', () {
      expect(
        CronExpressionService.build(['0', '12', '*', '*', '1-5']),
        '0 12 * * 1-5',
      );
    });

    test('parse splits a well-formed expression on any whitespace', () {
      expect(
        CronExpressionService.parse('0   12 *  *  1-5'),
        ['0', '12', '*', '*', '1-5'],
      );
    });

    test('parse trims surrounding whitespace', () {
      expect(
        CronExpressionService.parse('   * * * * *   '),
        ['*', '*', '*', '*', '*'],
      );
    });

    test('parse returns null when field count != 5', () {
      expect(CronExpressionService.parse('* * * *'), isNull);
      expect(CronExpressionService.parse('* * * * * *'), isNull);
      expect(CronExpressionService.parse(''), isNull);
    });
  });

  group('CronExpressionService.describe', () {
    test('returns preset label for an exact preset match', () {
      expect(CronExpressionService.describe('0 9 * * 1-5'), 'Weekdays at 9 AM');
      expect(CronExpressionService.describe('*/15 * * * *'), 'Every 15 minutes');
      expect(CronExpressionService.describe('0 0 1 1 *'), 'Every January 1st');
    });

    test('returns "Every minute" for fully wildcarded non-preset path', () {
      // '* * * * *' is also a preset, but if every field is '*' the inner
      // path would still fall through to 'Every minute'.
      expect(CronExpressionService.describe('* * * * *'), 'Every minute');
    });

    test('returns "Invalid cron expression" when parse fails', () {
      expect(
        CronExpressionService.describe('not a cron'),
        'Invalid cron expression',
      );
    });

    test('describes month and day-of-week fields using human names', () {
      // Non-preset expression so the synthetic describer runs.
      final desc = CronExpressionService.describe('5 10 * 3 2');
      expect(desc, contains('MAR'));
      expect(desc, contains('TUE'));
      expect(desc, contains('at 5'));
      expect(desc, contains('at 10'));
    });

    test('describes ranges with "through" between bounds', () {
      final desc = CronExpressionService.describeField('1-5', 4);
      expect(desc, 'MON through FRI');
    });

    test('describes */n step over wildcard as "every n <field>s"', () {
      expect(
        CronExpressionService.describeField('*/5', 0),
        'every 5 minutes',
      );
    });

    test('describes single numeric field with "at <value>"', () {
      expect(CronExpressionService.describeField('7', 0), 'at 7');
    });

    test('describes comma-separated list as comma-joined labels', () {
      expect(CronExpressionService.describeField('1,3,5', 4), 'MON, WED, FRI');
    });
  });

  group('CronExpressionService.nextOccurrences', () {
    test('returns the next N "every minute" occurrences', () {
      final from = DateTime(2026, 1, 1, 12, 0);
      final next = CronExpressionService.nextOccurrences(
        '* * * * *',
        from,
        count: 3,
      );
      expect(next.length, 3);
      expect(next[0], DateTime(2026, 1, 1, 12, 1));
      expect(next[1], DateTime(2026, 1, 1, 12, 2));
      expect(next[2], DateTime(2026, 1, 1, 12, 3));
    });

    test('handles hourly "0 * * * *" pattern', () {
      // Start 5 minutes past an hour - next match should be the next top of hour.
      final from = DateTime(2026, 1, 1, 12, 5);
      final next = CronExpressionService.nextOccurrences(
        '0 * * * *',
        from,
        count: 2,
      );
      expect(next.length, 2);
      expect(next[0], DateTime(2026, 1, 1, 13, 0));
      expect(next[1], DateTime(2026, 1, 1, 14, 0));
    });

    test('handles "*/15 * * * *" step pattern', () {
      // Start mid-quarter; expect the next quarter-hour multiples.
      final from = DateTime(2026, 1, 1, 9, 7);
      final next = CronExpressionService.nextOccurrences(
        '*/15 * * * *',
        from,
        count: 4,
      );
      expect(next, [
        DateTime(2026, 1, 1, 9, 15),
        DateTime(2026, 1, 1, 9, 30),
        DateTime(2026, 1, 1, 9, 45),
        DateTime(2026, 1, 1, 10, 0),
      ]);
    });

    test('matches Monday using day-of-week field (Sunday=0)', () {
      // Friday 2026-01-02 09:00. Next "0 0 * * 1" (Monday midnight) is Mon 2026-01-05.
      final from = DateTime(2026, 1, 2, 9, 0);
      final next = CronExpressionService.nextOccurrences(
        '0 0 * * 1',
        from,
        count: 1,
      );
      expect(next.length, 1);
      expect(next.single, DateTime(2026, 1, 5, 0, 0));
      expect(next.single.weekday, DateTime.monday);
    });

    test('matches Sunday using day-of-week=0 (cron Sun=0 vs DateTime Sun=7)', () {
      // Thursday 2026-01-01 09:00. Next Sun midnight is Sun 2026-01-04.
      final from = DateTime(2026, 1, 1, 9, 0);
      final next = CronExpressionService.nextOccurrences(
        '0 0 * * 0',
        from,
        count: 1,
      );
      expect(next.single, DateTime(2026, 1, 4, 0, 0));
      expect(next.single.weekday, DateTime.sunday);
    });

    test('returns empty list when expression is invalid', () {
      expect(
        CronExpressionService.nextOccurrences('garbage', DateTime(2026, 1, 1)),
        isEmpty,
      );
    });

    test('respects custom count parameter', () {
      final from = DateTime(2026, 1, 1, 12, 0);
      final next = CronExpressionService.nextOccurrences(
        '* * * * *',
        from,
        count: 1,
      );
      expect(next.length, 1);
    });

    test('starts strictly after `from` (never returns the from instant)', () {
      final from = DateTime(2026, 1, 1, 12, 0);
      final next = CronExpressionService.nextOccurrences(
        '* * * * *',
        from,
        count: 1,
      );
      expect(next.single.isAfter(from), isTrue);
    });

    test('matches comma-separated list field correctly', () {
      // Hours 5 or 10, top of hour.
      final from = DateTime(2026, 1, 1, 0, 0);
      final next = CronExpressionService.nextOccurrences(
        '0 5,10 * * *',
        from,
        count: 3,
      );
      expect(next, [
        DateTime(2026, 1, 1, 5, 0),
        DateTime(2026, 1, 1, 10, 0),
        DateTime(2026, 1, 2, 5, 0),
      ]);
    });

    test('matches range field correctly', () {
      // Top of hour during business hours 9-11.
      final from = DateTime(2026, 1, 1, 8, 30);
      final next = CronExpressionService.nextOccurrences(
        '0 9-11 * * *',
        from,
        count: 3,
      );
      expect(next, [
        DateTime(2026, 1, 1, 9, 0),
        DateTime(2026, 1, 1, 10, 0),
        DateTime(2026, 1, 1, 11, 0),
      ]);
    });
  });

  group('CronExpressionService constants', () {
    test('fieldNames has 5 entries in canonical order', () {
      expect(CronExpressionService.fieldNames, [
        'Minute',
        'Hour',
        'Day of Month',
        'Month',
        'Day of Week',
      ]);
    });

    test('monthNames has 12 entries starting at JAN', () {
      expect(CronExpressionService.monthNames.length, 12);
      expect(CronExpressionService.monthNames.first, 'JAN');
      expect(CronExpressionService.monthNames.last, 'DEC');
    });

    test('dayNames has 7 entries starting at SUN', () {
      expect(CronExpressionService.dayNames.length, 7);
      expect(CronExpressionService.dayNames.first, 'SUN');
      expect(CronExpressionService.dayNames.last, 'SAT');
    });

    test('fieldRanges enumerate sensible bounds', () {
      expect(CronExpressionService.fieldRanges[0], [0, 59]); // minute
      expect(CronExpressionService.fieldRanges[1], [0, 23]); // hour
      expect(CronExpressionService.fieldRanges[2], [1, 31]); // dom
      expect(CronExpressionService.fieldRanges[3], [1, 12]); // month
      expect(CronExpressionService.fieldRanges[4], [0, 6]);  // dow
    });

    test('every preset key parses into exactly 5 fields', () {
      for (final key in CronExpressionService.presets.keys) {
        expect(
          CronExpressionService.parse(key),
          isNotNull,
          reason: 'preset $key failed to parse',
        );
        expect(CronExpressionService.parse(key)!.length, 5);
      }
    });
  });
}
