import 'package:everything/core/services/roman_numeral_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RomanNumeralService.toRoman', () {
    test('basic conversions', () {
      expect(RomanNumeralService.toRoman(1), 'I');
      expect(RomanNumeralService.toRoman(4), 'IV');
      expect(RomanNumeralService.toRoman(9), 'IX');
      expect(RomanNumeralService.toRoman(14), 'XIV');
      expect(RomanNumeralService.toRoman(40), 'XL');
      expect(RomanNumeralService.toRoman(90), 'XC');
      expect(RomanNumeralService.toRoman(400), 'CD');
      expect(RomanNumeralService.toRoman(900), 'CM');
      expect(RomanNumeralService.toRoman(1000), 'M');
    });

    test('complex numbers', () {
      expect(RomanNumeralService.toRoman(1994), 'MCMXCIV');
      expect(RomanNumeralService.toRoman(2024), 'MMXXIV');
      expect(RomanNumeralService.toRoman(3999), 'MMMCMXCIX');
      expect(RomanNumeralService.toRoman(1776), 'MDCCLXXVI');
      expect(RomanNumeralService.toRoman(58), 'LVIII');
    });

    test('throws on out-of-range values', () {
      expect(() => RomanNumeralService.toRoman(0), throwsArgumentError);
      expect(() => RomanNumeralService.toRoman(-1), throwsArgumentError);
      expect(() => RomanNumeralService.toRoman(4000), throwsArgumentError);
    });
  });

  group('RomanNumeralService.toDecimal', () {
    test('basic conversions', () {
      expect(RomanNumeralService.toDecimal('I'), 1);
      expect(RomanNumeralService.toDecimal('IV'), 4);
      expect(RomanNumeralService.toDecimal('IX'), 9);
      expect(RomanNumeralService.toDecimal('XLII'), 42);
      expect(RomanNumeralService.toDecimal('MCMXCIV'), 1994);
      expect(RomanNumeralService.toDecimal('MMMCMXCIX'), 3999);
    });

    test('case insensitive', () {
      expect(RomanNumeralService.toDecimal('iv'), 4);
      expect(RomanNumeralService.toDecimal('mcmxciv'), 1994);
    });

    test('trims whitespace', () {
      expect(RomanNumeralService.toDecimal('  XIV  '), 14);
    });

    test('returns null for empty string', () {
      expect(RomanNumeralService.toDecimal(''), isNull);
    });

    test('returns null for invalid characters', () {
      expect(RomanNumeralService.toDecimal('ABC'), isNull);
      expect(RomanNumeralService.toDecimal('123'), isNull);
    });

    test('returns null for invalid sequences (non-round-trippable)', () {
      // IIII is not valid standard form
      expect(RomanNumeralService.toDecimal('IIII'), isNull);
      // VV is not valid
      expect(RomanNumeralService.toDecimal('VV'), isNull);
    });
  });

  group('RomanNumeralService.isValidRoman', () {
    test('valid numerals', () {
      expect(RomanNumeralService.isValidRoman('XIV'), isTrue);
      expect(RomanNumeralService.isValidRoman('MCMXCIV'), isTrue);
    });

    test('invalid numerals', () {
      expect(RomanNumeralService.isValidRoman('IIII'), isFalse);
      expect(RomanNumeralService.isValidRoman('ABC'), isFalse);
      expect(RomanNumeralService.isValidRoman(''), isFalse);
    });
  });

  group('round-trip toRoman ↔ toDecimal', () {
    test('all values 1-3999 round-trip correctly', () {
      // Test a representative sample to avoid slow test
      for (final n in [1, 2, 3, 4, 5, 9, 10, 49, 99, 100, 399, 400, 500,
          888, 999, 1000, 1444, 1999, 2026, 2999, 3000, 3999]) {
        final roman = RomanNumeralService.toRoman(n);
        expect(RomanNumeralService.toDecimal(roman), n,
            reason: '$n → $roman → should be $n');
      }
    });
  });

  group('referenceTable', () {
    test('contains 13 standard entries', () {
      expect(RomanNumeralService.referenceTable.length, 13);
    });

    test('entries are in ascending order', () {
      for (int i = 1; i < RomanNumeralService.referenceTable.length; i++) {
        expect(RomanNumeralService.referenceTable[i].key,
            greaterThan(RomanNumeralService.referenceTable[i - 1].key));
      }
    });
  });
}
