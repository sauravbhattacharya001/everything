import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/base_converter_service.dart';

void main() {
  group('BaseConverterService', () {
    // ── convert ──

    group('convert', () {
      test('decimal to binary', () {
        expect(BaseConverterService.convert('255', 10, 2), '11111111');
        expect(BaseConverterService.convert('0', 10, 2), '0');
        expect(BaseConverterService.convert('42', 10, 2), '101010');
      });

      test('binary to decimal', () {
        expect(BaseConverterService.convert('101010', 2, 10), '42');
        expect(BaseConverterService.convert('11111111', 2, 16), 'FF');
      });

      test('decimal to hexadecimal', () {
        expect(BaseConverterService.convert('255', 10, 16), 'FF');
        expect(BaseConverterService.convert('16', 10, 16), '10');
      });

      test('hex to decimal', () {
        expect(BaseConverterService.convert('FF', 16, 10), '255');
        expect(BaseConverterService.convert('ff', 16, 10), '255');
      });

      test('decimal to octal', () {
        expect(BaseConverterService.convert('8', 10, 8), '10');
        expect(BaseConverterService.convert('255', 10, 8), '377');
      });

      test('handles large numbers via BigInt', () {
        expect(BaseConverterService.convert(
            '18446744073709551615', 10, 16), 'FFFFFFFFFFFFFFFF');
      });

      test('returns null for empty input', () {
        expect(BaseConverterService.convert('', 10, 2), isNull);
      });

      test('returns null for whitespace-only input', () {
        expect(BaseConverterService.convert('   ', 10, 2), isNull);
      });

      test('returns null for invalid base range', () {
        expect(BaseConverterService.convert('5', 1, 10), isNull);
        expect(BaseConverterService.convert('5', 10, 37), isNull);
      });

      test('returns null for invalid digits in given base', () {
        expect(BaseConverterService.convert('2', 2, 10), isNull);
        expect(BaseConverterService.convert('G', 16, 10), isNull);
      });

      test('trims whitespace from input', () {
        expect(BaseConverterService.convert('  FF  ', 16, 10), '255');
      });

      test('same base returns same value (uppercase)', () {
        expect(BaseConverterService.convert('ff', 16, 16), 'FF');
      });
    });

    // ── convertToAll ──

    group('convertToAll', () {
      test('converts decimal 255 to all named bases', () {
        final result = BaseConverterService.convertToAll('255', 10);
        expect(result, isNotNull);
        expect(result!['Binary (2)'], '11111111');
        expect(result['Octal (8)'], '377');
        expect(result['Decimal (10)'], '255');
        expect(result['Hexadecimal (16)'], 'FF');
      });

      test('returns null for empty input', () {
        expect(BaseConverterService.convertToAll('', 10), isNull);
      });

      test('returns null for invalid input', () {
        expect(BaseConverterService.convertToAll('ZZ', 10), isNull);
      });

      test('returns all named bases in result map', () {
        final result = BaseConverterService.convertToAll('10', 10);
        expect(result, isNotNull);
        for (final name in BaseConverterService.namedBases.keys) {
          expect(result!.containsKey(name), isTrue,
              reason: 'missing key: $name');
        }
      });
    });

    // ── validChars ──

    group('validChars', () {
      test('binary has 0 and 1', () {
        expect(BaseConverterService.validChars(2), '01');
      });

      test('decimal has 0-9', () {
        expect(BaseConverterService.validChars(10), '0123456789');
      });

      test('hex has 0-9 A-F', () {
        expect(BaseConverterService.validChars(16), '0123456789ABCDEF');
      });

      test('base 36 has all alphanumeric chars', () {
        expect(BaseConverterService.validChars(36),
            '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ');
      });
    });

    // ── isValid ──

    group('isValid', () {
      test('validates binary input', () {
        expect(BaseConverterService.isValid('0101', 2), isTrue);
        expect(BaseConverterService.isValid('0123', 2), isFalse);
      });

      test('validates hex input (case-insensitive)', () {
        expect(BaseConverterService.isValid('FF', 16), isTrue);
        expect(BaseConverterService.isValid('ff', 16), isTrue);
        expect(BaseConverterService.isValid('GG', 16), isFalse);
      });

      test('returns false for empty string', () {
        expect(BaseConverterService.isValid('', 10), isFalse);
      });

      test('trims whitespace', () {
        expect(BaseConverterService.isValid('  101  ', 2), isTrue);
      });
    });

    // ── formatBinary ──

    group('formatBinary', () {
      test('groups binary digits in fours', () {
        expect(BaseConverterService.formatBinary('11111111'), '1111 1111');
      });

      test('handles non-multiple-of-4 length', () {
        expect(BaseConverterService.formatBinary('101010'), '10 1010');
      });

      test('handles single digit', () {
        expect(BaseConverterService.formatBinary('1'), '1');
      });

      test('strips existing spaces', () {
        expect(BaseConverterService.formatBinary('1111 0000'), '1111 0000');
      });
    });

    // ── formatHex ──

    group('formatHex', () {
      test('groups hex digits in pairs', () {
        expect(BaseConverterService.formatHex('AABBCCDD'), 'AA BB CC DD');
      });

      test('handles odd-length hex', () {
        expect(BaseConverterService.formatHex('ABC'), 'A BC');
      });

      test('handles single char', () {
        expect(BaseConverterService.formatHex('F'), 'F');
      });
    });

    // ── namedBases ──

    test('namedBases contains expected entries', () {
      expect(BaseConverterService.namedBases.length, 6);
      expect(BaseConverterService.namedBases.values, contains(2));
      expect(BaseConverterService.namedBases.values, contains(8));
      expect(BaseConverterService.namedBases.values, contains(10));
      expect(BaseConverterService.namedBases.values, contains(16));
    });
  });
}
