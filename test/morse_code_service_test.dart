import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/morse_code_service.dart';

void main() {
  group('MorseCodeService.encode', () {
    test('encodes single letters correctly', () {
      expect(MorseCodeService.encode('A'), '.-');
      expect(MorseCodeService.encode('E'), '.');
      expect(MorseCodeService.encode('T'), '-');
      expect(MorseCodeService.encode('S'), '...');
    });

    test('encodes a word with spaces between letters', () {
      expect(MorseCodeService.encode('SOS'), '... --- ...');
    });

    test('encodes words separated by " / "', () {
      expect(MorseCodeService.encode('HI THERE'),
          '.... .. / - .... . .-. .');
    });

    test('is case-insensitive', () {
      expect(MorseCodeService.encode('abc'),
          MorseCodeService.encode('ABC'));
    });

    test('encodes digits', () {
      expect(MorseCodeService.encode('1'), '.----');
      expect(MorseCodeService.encode('0'), '-----');
      expect(MorseCodeService.encode('42'), '....- ..---');
    });

    test('encodes punctuation', () {
      expect(MorseCodeService.encode('.'), '.-.-.-');
      expect(MorseCodeService.encode(','), '--..--');
      expect(MorseCodeService.encode('?'), '..--..');
      expect(MorseCodeService.encode('!'), '-.-.--');
    });

    test('skips unknown characters', () {
      // tilde is not in Morse — should be silently skipped
      expect(MorseCodeService.encode('A~B'), '.- -...');
    });

    test('encodes empty string', () {
      expect(MorseCodeService.encode(''), '');
    });

    test('encodes full alphabet', () {
      final encoded = MorseCodeService.encode('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
      // Each letter separated by space
      final parts = encoded.split(' ');
      expect(parts.length, 26);
    });

    test('multiple spaces between words produce single separator', () {
      // Two spaces should become ' / ' + ' / ' (each space → separator)
      final result = MorseCodeService.encode('A B');
      expect(result, '.- / -...');
    });
  });

  group('MorseCodeService.decode', () {
    test('decodes single letter', () {
      expect(MorseCodeService.decode('.-'), 'A');
      expect(MorseCodeService.decode('-'), 'T');
    });

    test('decodes a word', () {
      expect(MorseCodeService.decode('... --- ...'), 'SOS');
    });

    test('decodes multiple words', () {
      expect(MorseCodeService.decode('.... .. / - .... . .-. .'),
          'HI THERE');
    });

    test('unknown morse code replaced with ?', () {
      expect(MorseCodeService.decode('........'), '?');
    });

    test('decodes digits', () {
      expect(MorseCodeService.decode('.---- ..--- ...-- ....- .....'),
          '12345');
    });

    test('handles extra whitespace gracefully', () {
      // Multiple spaces between letters
      expect(MorseCodeService.decode('...  ---  ...'), 'SOS');
    });

    test('round-trip encode/decode preserves text', () {
      const original = 'HELLO WORLD 123';
      final encoded = MorseCodeService.encode(original);
      final decoded = MorseCodeService.decode(encoded);
      expect(decoded, original);
    });

    test('round-trip with punctuation', () {
      const original = 'OK? YES!';
      final encoded = MorseCodeService.encode(original);
      final decoded = MorseCodeService.decode(encoded);
      expect(decoded, original);
    });
  });

  group('MorseCodeService.referenceTable', () {
    test('contains all 36+ entries (letters + digits + punctuation)', () {
      expect(MorseCodeService.referenceTable.length, greaterThanOrEqualTo(36));
    });

    test('every entry has non-empty key and value', () {
      for (final entry in MorseCodeService.referenceTable) {
        expect(entry.key.isNotEmpty, isTrue);
        expect(entry.value.isNotEmpty, isTrue);
      }
    });

    test('morse values only contain dots and dashes', () {
      for (final entry in MorseCodeService.referenceTable) {
        expect(entry.value, matches(RegExp(r'^[.\-]+$')));
      }
    });
  });
}
