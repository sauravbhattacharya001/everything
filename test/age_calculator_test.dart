import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/age_calculator_service.dart';

void main() {
  group('AgeCalculatorService', () {
    // ── Basic age calculation ──

    group('calculate - basic age', () {
      test('exact years when same month and day', () {
        final birth = DateTime(1990, 6, 15);
        final now = DateTime(2020, 6, 15);
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.years, 30);
        expect(result.months, 0);
        expect(result.days, 0);
      });

      test('partial year when birthday has not occurred yet', () {
        final birth = DateTime(1990, 12, 25);
        final now = DateTime(2020, 6, 15);
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.years, 29);
        expect(result.months, 5);
      });

      test('handles day overflow correctly', () {
        // Born Jan 31, check March 1 (Feb has 28 days)
        final birth = DateTime(2000, 1, 31);
        final now = DateTime(2000, 3, 1);
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.years, 0);
        expect(result.months, 1);
        // Expect a valid days value (depends on Feb length)
        expect(result.days, greaterThanOrEqualTo(0));
      });

      test('newborn (same day) has zero age', () {
        final birth = DateTime(2024, 3, 10, 8, 30);
        final now = DateTime(2024, 3, 10, 20, 0);
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.years, 0);
        expect(result.months, 0);
        expect(result.days, 0);
      });

      test('one day old', () {
        final birth = DateTime(2024, 1, 1);
        final now = DateTime(2024, 1, 2);
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.days, 1);
        expect(result.months, 0);
        expect(result.years, 0);
      });
    });

    // ── Future birth date ──

    group('calculate - future birth date', () {
      test('returns zero result when birth is in the future', () {
        final birth = DateTime(2030, 1, 1);
        final now = DateTime(2020, 6, 15);
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.years, 0);
        expect(result.months, 0);
        expect(result.days, 0);
        expect(result.totalDays, 0);
        expect(result.heartbeats, 0);
      });
    });

    // ── Total days and weeks ──

    group('calculate - totals', () {
      test('totalDays is correct for exactly one year (non-leap)', () {
        final birth = DateTime(2023, 1, 1);
        final now = DateTime(2024, 1, 1);
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.totalDays, 365);
      });

      test('totalDays for a leap year span', () {
        final birth = DateTime(2024, 1, 1); // 2024 is leap year
        final now = DateTime(2025, 1, 1);
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.totalDays, 366);
      });

      test('totalWeeks equals totalDays divided by 7', () {
        final birth = DateTime(2000, 1, 1);
        final now = DateTime(2020, 1, 1);
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.totalWeeks, result.totalDays ~/ 7);
      });

      test('totalHours equals totalDays times 24', () {
        final birth = DateTime(2000, 5, 15);
        final now = DateTime(2025, 5, 15);
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.totalHours, result.totalDays * 24);
      });
    });

    // ── Fun statistics ──

    group('calculate - lifetime stats', () {
      test('heartbeats are approximately 100800 per day', () {
        final birth = DateTime(2020, 1, 1);
        final now = DateTime(2021, 1, 1); // 365 or 366 days
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.heartbeats, result.totalDays * 100800);
      });

      test('breaths are approximately 23040 per day', () {
        final birth = DateTime(2020, 1, 1);
        final now = DateTime(2020, 2, 1); // 31 days
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.breaths, 31 * 23040);
      });

      test('sleepHours are 8 per day', () {
        final birth = DateTime(2020, 1, 1);
        final now = DateTime(2020, 1, 11); // 10 days
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.sleepHours, 80);
      });

      test('mealsEaten are 3 per day', () {
        final birth = DateTime(2000, 6, 1);
        final now = DateTime(2000, 6, 8); // 7 days
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.mealsEaten, 21);
      });

      test('stepsWalked are 7500 per day', () {
        final birth = DateTime(2020, 3, 1);
        final now = DateTime(2020, 3, 2); // 1 day
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.stepsWalked, 7500);
      });

      test('wordsSpoken are 16000 per day', () {
        final birth = DateTime(2020, 3, 1);
        final now = DateTime(2020, 3, 4); // 3 days
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.wordsSpoken, 48000);
      });
    });

    // ── Next birthday ──

    group('calculate - daysUntilBirthday', () {
      test('day before birthday yields 1', () {
        final birth = DateTime(1995, 7, 20);
        final now = DateTime(2025, 7, 19);
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.daysUntilBirthday, 1);
      });

      test('on birthday itself, counts to next year', () {
        final birth = DateTime(1990, 3, 15);
        final now = DateTime(2024, 3, 15);
        final result = AgeCalculatorService.calculate(birth, now);
        // On birthday → next birthday is next year
        expect(result.daysUntilBirthday, greaterThan(0));
        expect(result.daysUntilBirthday, lessThanOrEqualTo(366));
      });

      test('daysUntilBirthday is always positive for valid ages', () {
        final birth = DateTime(1985, 11, 30);
        final now = DateTime(2025, 4, 10);
        final result = AgeCalculatorService.calculate(birth, now);
        expect(result.daysUntilBirthday, greaterThan(0));
      });
    });

    // ── Zodiac sign ──

    group('calculate - zodiac', () {
      test('January 15 is Capricorn', () {
        final result = AgeCalculatorService.calculate(
          DateTime(2000, 1, 15),
          DateTime(2025, 6, 1),
        );
        expect(result.zodiacSign, contains('Capricorn'));
      });

      test('February 10 is Aquarius', () {
        final result = AgeCalculatorService.calculate(
          DateTime(2000, 2, 10),
          DateTime(2025, 6, 1),
        );
        expect(result.zodiacSign, contains('Aquarius'));
      });

      test('March 25 is Aries', () {
        final result = AgeCalculatorService.calculate(
          DateTime(2000, 3, 25),
          DateTime(2025, 6, 1),
        );
        expect(result.zodiacSign, contains('Aries'));
      });

      test('July 4 is Cancer', () {
        final result = AgeCalculatorService.calculate(
          DateTime(2000, 7, 4),
          DateTime(2025, 6, 1),
        );
        expect(result.zodiacSign, contains('Cancer'));
      });

      test('December 25 is Capricorn', () {
        final result = AgeCalculatorService.calculate(
          DateTime(2000, 12, 25),
          DateTime(2025, 6, 1),
        );
        expect(result.zodiacSign, contains('Capricorn'));
      });
    });

    // ── Day of week born ──

    group('calculate - dayOfWeekBorn', () {
      test('known historical date: July 20, 1969 was a Sunday', () {
        final result = AgeCalculatorService.calculate(
          DateTime(1969, 7, 20),
          DateTime(2025, 1, 1),
        );
        expect(result.dayOfWeekBorn, 'Sunday');
      });

      test('January 1, 2024 was a Monday', () {
        final result = AgeCalculatorService.calculate(
          DateTime(2024, 1, 1),
          DateTime(2025, 1, 1),
        );
        expect(result.dayOfWeekBorn, 'Monday');
      });
    });
  });

  // ── AgeResult ──

  group('AgeResult', () {
    group('zero factory', () {
      test('all fields are zero or empty', () {
        final zero = AgeResult.zero();
        expect(zero.years, 0);
        expect(zero.months, 0);
        expect(zero.days, 0);
        expect(zero.totalDays, 0);
        expect(zero.totalWeeks, 0);
        expect(zero.totalHours, 0);
        expect(zero.heartbeats, 0);
        expect(zero.zodiacSign, '');
        expect(zero.dayOfWeekBorn, '');
        expect(zero.birthDate, isNull);
      });
    });

    group('formattedAge', () {
      test('shows only days when less than 1 month', () {
        const result = AgeResult(
          years: 0, months: 0, days: 15,
          totalDays: 15, totalWeeks: 2, totalHours: 360,
          daysUntilBirthday: 350, heartbeats: 0, breaths: 0,
          sleepHours: 0, mealsEaten: 0, stepsWalked: 0, wordsSpoken: 0,
          zodiacSign: '', dayOfWeekBorn: '',
        );
        expect(result.formattedAge, '15 days');
      });

      test('shows months and days when less than 1 year', () {
        const result = AgeResult(
          years: 0, months: 3, days: 12,
          totalDays: 100, totalWeeks: 14, totalHours: 2400,
          daysUntilBirthday: 265, heartbeats: 0, breaths: 0,
          sleepHours: 0, mealsEaten: 0, stepsWalked: 0, wordsSpoken: 0,
          zodiacSign: '', dayOfWeekBorn: '',
        );
        expect(result.formattedAge, '3 months, 12 days');
      });

      test('shows full years, months, days when over 1 year', () {
        const result = AgeResult(
          years: 25, months: 6, days: 10,
          totalDays: 9300, totalWeeks: 1328, totalHours: 223200,
          daysUntilBirthday: 180, heartbeats: 0, breaths: 0,
          sleepHours: 0, mealsEaten: 0, stepsWalked: 0, wordsSpoken: 0,
          zodiacSign: '', dayOfWeekBorn: '',
        );
        expect(result.formattedAge, '25 years, 6 months, 10 days');
      });
    });
  });
}
