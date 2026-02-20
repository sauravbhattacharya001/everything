import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/recurrence_rule.dart';

void main() {
  group('RecurrenceFrequency', () {
    test('fromString returns correct frequency', () {
      expect(RecurrenceFrequency.fromString('daily'), RecurrenceFrequency.daily);
      expect(RecurrenceFrequency.fromString('weekly'), RecurrenceFrequency.weekly);
      expect(RecurrenceFrequency.fromString('monthly'), RecurrenceFrequency.monthly);
      expect(RecurrenceFrequency.fromString('yearly'), RecurrenceFrequency.yearly);
    });

    test('fromString defaults to weekly for unknown', () {
      expect(RecurrenceFrequency.fromString('unknown'), RecurrenceFrequency.weekly);
      expect(RecurrenceFrequency.fromString(''), RecurrenceFrequency.weekly);
    });

    test('label returns human-readable string', () {
      expect(RecurrenceFrequency.daily.label, 'Daily');
      expect(RecurrenceFrequency.weekly.label, 'Weekly');
      expect(RecurrenceFrequency.monthly.label, 'Monthly');
      expect(RecurrenceFrequency.yearly.label, 'Yearly');
    });

    test('descriptionWithInterval singular', () {
      expect(RecurrenceFrequency.daily.descriptionWithInterval(1), 'Every day');
      expect(RecurrenceFrequency.weekly.descriptionWithInterval(1), 'Every week');
      expect(RecurrenceFrequency.monthly.descriptionWithInterval(1), 'Every month');
      expect(RecurrenceFrequency.yearly.descriptionWithInterval(1), 'Every year');
    });

    test('descriptionWithInterval plural', () {
      expect(RecurrenceFrequency.daily.descriptionWithInterval(2), 'Every 2 days');
      expect(RecurrenceFrequency.weekly.descriptionWithInterval(3), 'Every 3 weeks');
      expect(RecurrenceFrequency.monthly.descriptionWithInterval(6), 'Every 6 months');
      expect(RecurrenceFrequency.yearly.descriptionWithInterval(2), 'Every 2 years');
    });
  });

  group('RecurrenceRule', () {
    group('construction', () {
      test('creates with required fields', () {
        const rule = RecurrenceRule(frequency: RecurrenceFrequency.weekly);
        expect(rule.frequency, RecurrenceFrequency.weekly);
        expect(rule.interval, 1);
        expect(rule.endDate, isNull);
      });

      test('creates with all fields', () {
        final endDate = DateTime(2026, 12, 31);
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 2,
          endDate: endDate,
        );
        expect(rule.frequency, RecurrenceFrequency.monthly);
        expect(rule.interval, 2);
        expect(rule.endDate, endDate);
      });
    });

    group('summary', () {
      test('weekly without end date', () {
        const rule = RecurrenceRule(frequency: RecurrenceFrequency.weekly);
        expect(rule.summary, 'Every week');
      });

      test('daily with interval', () {
        const rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 3,
        );
        expect(rule.summary, 'Every 3 days');
      });

      test('monthly with end date', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          endDate: DateTime(2026, 3, 15),
        );
        expect(rule.summary, 'Every month until Mar 15, 2026');
      });

      test('yearly with interval and end date', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.yearly,
          interval: 2,
          endDate: DateTime(2030, 6, 1),
        );
        expect(rule.summary, 'Every 2 years until Jun 1, 2030');
      });
    });

    group('generateOccurrences', () {
      test('daily generates correct dates', () {
        const rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);
        final start = DateTime(2026, 1, 1, 10, 0);
        final dates = rule.generateOccurrences(start, maxOccurrences: 4);

        expect(dates.length, 4);
        expect(dates[0], DateTime(2026, 1, 1, 10, 0));
        expect(dates[1], DateTime(2026, 1, 2, 10, 0));
        expect(dates[2], DateTime(2026, 1, 3, 10, 0));
        expect(dates[3], DateTime(2026, 1, 4, 10, 0));
      });

      test('weekly generates correct dates', () {
        const rule = RecurrenceRule(frequency: RecurrenceFrequency.weekly);
        final start = DateTime(2026, 1, 5, 14, 30);
        final dates = rule.generateOccurrences(start, maxOccurrences: 3);

        expect(dates.length, 3);
        expect(dates[0], DateTime(2026, 1, 5, 14, 30));
        expect(dates[1], DateTime(2026, 1, 12, 14, 30));
        expect(dates[2], DateTime(2026, 1, 19, 14, 30));
      });

      test('monthly generates correct dates', () {
        const rule = RecurrenceRule(frequency: RecurrenceFrequency.monthly);
        final start = DateTime(2026, 1, 15, 9, 0);
        final dates = rule.generateOccurrences(start, maxOccurrences: 4);

        expect(dates.length, 4);
        expect(dates[0], DateTime(2026, 1, 15, 9, 0));
        expect(dates[1], DateTime(2026, 2, 15, 9, 0));
        expect(dates[2], DateTime(2026, 3, 15, 9, 0));
        expect(dates[3], DateTime(2026, 4, 15, 9, 0));
      });

      test('yearly generates correct dates', () {
        const rule = RecurrenceRule(frequency: RecurrenceFrequency.yearly);
        final start = DateTime(2026, 6, 1, 12, 0);
        final dates = rule.generateOccurrences(start, maxOccurrences: 3);

        expect(dates.length, 3);
        expect(dates[0], DateTime(2026, 6, 1, 12, 0));
        expect(dates[1], DateTime(2027, 6, 1, 12, 0));
        expect(dates[2], DateTime(2028, 6, 1, 12, 0));
      });

      test('interval of 2 weeks', () {
        const rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
        );
        final start = DateTime(2026, 1, 1);
        final dates = rule.generateOccurrences(start, maxOccurrences: 3);

        expect(dates[0], DateTime(2026, 1, 1));
        expect(dates[1], DateTime(2026, 1, 15));
        expect(dates[2], DateTime(2026, 1, 29));
      });

      test('interval of 3 months', () {
        const rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 3,
        );
        final start = DateTime(2026, 1, 10);
        final dates = rule.generateOccurrences(start, maxOccurrences: 3);

        expect(dates[0], DateTime(2026, 1, 10));
        expect(dates[1], DateTime(2026, 4, 10));
        expect(dates[2], DateTime(2026, 7, 10));
      });

      test('stops at end date', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          endDate: DateTime(2026, 1, 5),
        );
        final start = DateTime(2026, 1, 1);
        final dates = rule.generateOccurrences(start, maxOccurrences: 100);

        expect(dates.length, 5);
        expect(dates.last, DateTime(2026, 1, 5));
      });

      test('respects maxOccurrences', () {
        const rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);
        final start = DateTime(2026, 1, 1);
        final dates = rule.generateOccurrences(start, maxOccurrences: 5);

        expect(dates.length, 5);
      });

      test('monthly end-of-month clamping (Jan 31 → Feb 28)', () {
        const rule = RecurrenceRule(frequency: RecurrenceFrequency.monthly);
        final start = DateTime(2026, 1, 31, 15, 0);
        final dates = rule.generateOccurrences(start, maxOccurrences: 3);

        expect(dates[0], DateTime(2026, 1, 31, 15, 0));
        expect(dates[1], DateTime(2026, 2, 28, 15, 0)); // Feb has 28 days in 2026
        expect(dates[2], DateTime(2026, 3, 28, 15, 0)); // Clamped to 28 (from Feb)
      });

      test('monthly leap year handling (Jan 31 → Feb 29 in leap year)', () {
        const rule = RecurrenceRule(frequency: RecurrenceFrequency.monthly);
        final start = DateTime(2028, 1, 31); // 2028 is leap year
        final dates = rule.generateOccurrences(start, maxOccurrences: 3);

        expect(dates[0], DateTime(2028, 1, 31));
        expect(dates[1], DateTime(2028, 2, 29)); // Leap year
        expect(dates[2], DateTime(2028, 3, 29));
      });

      test('single occurrence when start equals end date', () {
        final start = DateTime(2026, 1, 1);
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          endDate: DateTime(2026, 1, 3), // Before next weekly occurrence
        );
        final dates = rule.generateOccurrences(start, maxOccurrences: 100);

        expect(dates.length, 1);
        expect(dates[0], start);
      });
    });

    group('serialization', () {
      test('toJson/fromJson round-trip without end date', () {
        const original = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
        );
        final restored = RecurrenceRule.fromJson(original.toJson());

        expect(restored.frequency, original.frequency);
        expect(restored.interval, original.interval);
        expect(restored.endDate, isNull);
      });

      test('toJson/fromJson round-trip with end date', () {
        final endDate = DateTime(2026, 12, 31);
        final original = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 3,
          endDate: endDate,
        );
        final restored = RecurrenceRule.fromJson(original.toJson());

        expect(restored.frequency, original.frequency);
        expect(restored.interval, original.interval);
        expect(restored.endDate, endDate);
      });

      test('toJsonString/fromJsonString round-trip', () {
        const original = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        );
        final jsonStr = original.toJsonString();
        final restored = RecurrenceRule.fromJsonString(jsonStr);

        expect(restored, isNotNull);
        expect(restored!.frequency, RecurrenceFrequency.daily);
        expect(restored.interval, 1);
      });

      test('fromJsonString returns null for null input', () {
        expect(RecurrenceRule.fromJsonString(null), isNull);
      });

      test('fromJsonString returns null for empty string', () {
        expect(RecurrenceRule.fromJsonString(''), isNull);
      });

      test('fromJsonString returns null for invalid JSON', () {
        expect(RecurrenceRule.fromJsonString('not json'), isNull);
      });

      test('fromJson defaults interval to 1 when missing', () {
        final rule = RecurrenceRule.fromJson({'frequency': 'daily'});
        expect(rule.interval, 1);
      });
    });

    group('equality', () {
      test('equal rules are equal', () {
        const a = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
        );
        const b = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different frequency means not equal', () {
        const a = RecurrenceRule(frequency: RecurrenceFrequency.daily);
        const b = RecurrenceRule(frequency: RecurrenceFrequency.weekly);
        expect(a, isNot(b));
      });

      test('different interval means not equal', () {
        const a = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
        );
        const b = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
        );
        expect(a, isNot(b));
      });

      test('different end date means not equal', () {
        final a = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          endDate: DateTime(2026, 6, 1),
        );
        final b = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          endDate: DateTime(2026, 12, 1),
        );
        expect(a, isNot(b));
      });

      test('null vs non-null end date means not equal', () {
        const a = RecurrenceRule(frequency: RecurrenceFrequency.weekly);
        final b = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          endDate: DateTime(2026, 6, 1),
        );
        expect(a, isNot(b));
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        const rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
        );
        final str = rule.toString();
        expect(str, contains('RecurrenceRule'));
        expect(str, contains('weekly'));
        expect(str, contains('2'));
      });
    });
  });
}
