import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/password_strength_service.dart';

void main() {
  group('PasswordStrengthService.analyze - empty input', () {
    test('returns Empty label and zero entropy for empty string', () {
      final a = PasswordStrengthService.analyze('');
      expect(a.password, '');
      expect(a.label, 'Empty');
      expect(a.score, 0);
      expect(a.entropy, 0);
      expect(a.crackTimeSeconds, 0);
      expect(a.crackTimeLabel, 'Instant');
      expect(a.charsetSize, 0);
      expect(a.uniqueChars, 0);
      expect(a.repeatedChars, 0);
      expect(a.suggestions, contains('Enter a password to analyze.'));
      expect(a.hasUpper, isFalse);
      expect(a.hasLower, isFalse);
      expect(a.hasDigit, isFalse);
      expect(a.hasSymbol, isFalse);
      expect(a.hasUnicode, isFalse);
    });
  });

  group('PasswordStrengthService.analyze - charset detection', () {
    test('lowercase-only has 26-char alphabet', () {
      final a = PasswordStrengthService.analyze('abcdwxyz');
      expect(a.hasLower, isTrue);
      expect(a.hasUpper, isFalse);
      expect(a.hasDigit, isFalse);
      expect(a.hasSymbol, isFalse);
      expect(a.charsetSize, 26);
    });

    test('lowercase + uppercase = 52', () {
      final a = PasswordStrengthService.analyze('aBcDwXyZ');
      expect(a.charsetSize, 52);
    });

    test('lowercase + digits = 36', () {
      final a = PasswordStrengthService.analyze('abc12345');
      expect(a.charsetSize, 36);
    });

    test('all four classes = 95', () {
      final a = PasswordStrengthService.analyze('aB3!xY8@');
      expect(a.hasUpper, isTrue);
      expect(a.hasLower, isTrue);
      expect(a.hasDigit, isTrue);
      expect(a.hasSymbol, isTrue);
      expect(a.charsetSize, 26 + 26 + 10 + 33); // 95
    });

    test('unicode adds +100 to charset estimate', () {
      final a = PasswordStrengthService.analyze('abcこんにちは');
      expect(a.hasUnicode, isTrue);
      expect(a.charsetSize, 26 + 100);
    });

    test('digits-only counts as digit only', () {
      final a = PasswordStrengthService.analyze('98765432');
      expect(a.hasDigit, isTrue);
      expect(a.hasLower, isFalse);
      expect(a.charsetSize, 10);
    });
  });

  group('PasswordStrengthService.analyze - entropy & crack time', () {
    test('entropy is length * log2(charset)', () {
      // 'abcdefgh' → 8 chars, charset 26
      final a = PasswordStrengthService.analyze('abcdefgh');
      // 8 * log2(26) ≈ 37.6035
      expect(a.entropy, closeTo(37.6035, 0.001));
    });

    test('longer password has higher entropy than shorter (same charset)', () {
      final shorter = PasswordStrengthService.analyze('mnopqrst');
      final longer = PasswordStrengthService.analyze('mnopqrstuvwx');
      expect(longer.entropy, greaterThan(shorter.entropy));
      expect(longer.crackTimeSeconds, greaterThan(shorter.crackTimeSeconds));
    });

    test('crack-time label progression covers all magnitude buckets', () {
      final labels = <String>{};
      for (final pw in [
        'a',                              // tiny
        'mnop',                           // < seconds-ish
        'mnopqrst',                       // larger
        'aB3!xY8@',                       // all 4 classes
        'aB3!xY8@aB3!xY8@',               // 16-char all-class
        'aB3!xY8@aB3!xY8@aB3!xY8@xX',     // very long
      ]) {
        labels.add(PasswordStrengthService.analyze(pw).crackTimeLabel);
      }
      // Different inputs produce different bucketed labels.
      expect(labels.length, greaterThan(1));
    });
  });

  group('PasswordStrengthService.analyze - unique vs repeated', () {
    test('all-distinct chars: repeatedChars == 0', () {
      final a = PasswordStrengthService.analyze('abcdef');
      expect(a.uniqueChars, 6);
      expect(a.repeatedChars, 0);
    });

    test('all-same chars: repeatedChars == length - 1', () {
      final a = PasswordStrengthService.analyze('aaaaaa');
      expect(a.uniqueChars, 1);
      expect(a.repeatedChars, 5);
      expect(a.patterns, contains('High character repetition'));
    });
  });

  group('PasswordStrengthService.analyze - pattern detection', () {
    test('flags too-short passwords', () {
      final a = PasswordStrengthService.analyze('aB3!');
      expect(a.patterns, contains('Too short (< 8 characters)'));
    });

    test('flags sequential characters (abc)', () {
      final a = PasswordStrengthService.analyze('myabcpass');
      expect(a.patterns, contains('Sequential characters detected (abc, 123)'));
    });

    test('flags sequential digits (123)', () {
      final a = PasswordStrengthService.analyze('foo123bar');
      expect(a.patterns, contains('Sequential characters detected (abc, 123)'));
    });

    test('does NOT flag non-sequential digits as sequential', () {
      final a = PasswordStrengthService.analyze('foo159bar');
      expect(a.patterns,
          isNot(contains('Sequential characters detected (abc, 123)')));
    });

    test('flags repeated pattern (abcabc)', () {
      final a = PasswordStrengthService.analyze('xyzxyzxyz');
      expect(a.patterns, contains('Repeated pattern detected'));
    });

    test('does NOT flag short non-repeating strings as repeated pattern', () {
      final a = PasswordStrengthService.analyze('xyzwvut');
      expect(a.patterns, isNot(contains('Repeated pattern detected')));
    });

    test('flags common password "password"', () {
      final a = PasswordStrengthService.analyze('password');
      expect(a.patterns, contains('Common password detected'));
      // and gets a heavy score penalty
      expect(a.score, lessThan(10));
    });

    test('flags common password case-insensitively', () {
      final a = PasswordStrengthService.analyze('PASSWORD');
      expect(a.patterns, contains('Common password detected'));
    });

    test('flags keyboard walks', () {
      final a = PasswordStrengthService.analyze('qwerty123');
      expect(a.patterns, contains('Keyboard walk detected (qwerty, asdf)'));
    });

    test('flags single-case-only passwords', () {
      final a = PasswordStrengthService.analyze('thisisalllower');
      expect(a.patterns, contains('Single case only'));
      final b = PasswordStrengthService.analyze('ALLCAPSONLY');
      expect(b.patterns, contains('Single case only'));
    });

    test('does NOT flag mixed case as single-case', () {
      final a = PasswordStrengthService.analyze('MixedCasePw');
      expect(a.patterns, isNot(contains('Single case only')));
    });
  });

  group('PasswordStrengthService.analyze - suggestions', () {
    test('suggests adding uppercase when missing', () {
      final a = PasswordStrengthService.analyze('lowercase1!');
      expect(a.suggestions,
          contains('Add uppercase letters for more complexity.'));
    });

    test('suggests adding digits when missing', () {
      final a = PasswordStrengthService.analyze('NoDigits!Here');
      expect(a.suggestions, contains('Add numbers for more complexity.'));
    });

    test('suggests adding symbols when missing', () {
      final a = PasswordStrengthService.analyze('NoSymbolHere1');
      expect(
        a.suggestions,
        contains('Add symbols (!@#\$%^&*) for much stronger entropy.'),
      );
    });

    test('praises long clean passwords', () {
      final a =
          PasswordStrengthService.analyze('VeryLongCleanPassphrase9!#wXz');
      expect(a.patterns, isEmpty);
      expect(
        a.suggestions,
        contains('Excellent length! This password is very strong.'),
      );
    });
  });

  group('PasswordStrengthService.analyze - scoring & labels', () {
    test('score is bounded to 0..100', () {
      for (final pw in [
        '',
        'a',
        'password',
        'aB3!xY8@',
        'aaaaaa',
        'VeryLongCleanPassphrase9!#wXz',
        'qwerty123',
      ]) {
        final s = PasswordStrengthService.analyze(pw).score;
        expect(s, inInclusiveRange(0, 100));
      }
    });

    test('label ordering: very weak < weak < fair < strong < very strong', () {
      final order = [
        PasswordStrengthService.analyze('a').score,
        PasswordStrengthService.analyze('abcdef').score,
        PasswordStrengthService.analyze('Abcdef1').score,
        PasswordStrengthService.analyze('Abcdef1!XyZ').score,
        PasswordStrengthService.analyze('VeryLongCleanPassphrase9!#wXz').score,
      ];
      for (int i = 1; i < order.length; i++) {
        expect(order[i], greaterThanOrEqualTo(order[i - 1]),
            reason: 'score[$i]=${order[i]} should be >= score[${i - 1}]=${order[i - 1]}');
      }
    });

    test('strong password gets Strong or Very Strong label', () {
      final a = PasswordStrengthService.analyze('Tr0ub4dor&3xZqVm!');
      expect(a.label, anyOf('Strong', 'Very Strong'));
    });

    test('common password is heavily penalised (Very Weak)', () {
      final a = PasswordStrengthService.analyze('password');
      expect(a.label, 'Very Weak');
    });
  });

  group('PasswordStrengthService.analyze - determinism', () {
    test('repeated calls return identical reports', () {
      const pw = 'Tr0ub4dor&3xZqVm!';
      final a = PasswordStrengthService.analyze(pw);
      final b = PasswordStrengthService.analyze(pw);
      expect(b.score, a.score);
      expect(b.entropy, a.entropy);
      expect(b.crackTimeSeconds, a.crackTimeSeconds);
      expect(b.crackTimeLabel, a.crackTimeLabel);
      expect(b.patterns, a.patterns);
      expect(b.suggestions, a.suggestions);
      expect(b.charsetSize, a.charsetSize);
      expect(b.uniqueChars, a.uniqueChars);
      expect(b.repeatedChars, a.repeatedChars);
      expect(b.label, a.label);
    });
  });
}
