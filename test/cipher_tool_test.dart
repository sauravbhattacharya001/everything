import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/cipher_tool_service.dart';

void main() {
  group('CipherToolService', () {
    // ── Caesar Cipher ──

    group('caesarEncode', () {
      test('shifts uppercase letters by shift amount', () {
        expect(CipherToolService.caesarEncode('ABC', 3), 'DEF');
        expect(CipherToolService.caesarEncode('XYZ', 3), 'ABC');
      });

      test('shifts lowercase letters by shift amount', () {
        expect(CipherToolService.caesarEncode('abc', 3), 'def');
        expect(CipherToolService.caesarEncode('xyz', 3), 'abc');
      });

      test('preserves non-alphabetic characters', () {
        expect(CipherToolService.caesarEncode('Hello, World! 123', 5),
            'Mjqqt, Btwqi! 123');
      });

      test('handles shift of 0', () {
        expect(CipherToolService.caesarEncode('Test', 0), 'Test');
      });

      test('handles shift of 26 (full cycle)', () {
        expect(CipherToolService.caesarEncode('Test', 26), 'Test');
      });

      test('handles shift > 26', () {
        expect(CipherToolService.caesarEncode('ABC', 29),
            CipherToolService.caesarEncode('ABC', 3));
      });

      test('handles negative shift', () {
        expect(CipherToolService.caesarEncode('DEF', -3), 'ABC');
      });

      test('handles empty string', () {
        expect(CipherToolService.caesarEncode('', 5), '');
      });
    });

    group('caesarDecode', () {
      test('reverses caesarEncode', () {
        const original = 'Hello, World!';
        final encoded = CipherToolService.caesarEncode(original, 7);
        expect(CipherToolService.caesarDecode(encoded, 7), original);
      });

      test('round-trips for all shift values 0-25', () {
        const text = 'AaBbZz';
        for (int shift = 0; shift < 26; shift++) {
          final encoded = CipherToolService.caesarEncode(text, shift);
          expect(CipherToolService.caesarDecode(encoded, shift), text,
              reason: 'shift=$shift');
        }
      });
    });

    // ── ROT13 ──

    group('rot13', () {
      test('applies shift of 13', () {
        expect(CipherToolService.rot13('ABC'), 'NOP');
        expect(CipherToolService.rot13('abc'), 'nop');
      });

      test('is self-inverse (applying twice returns original)', () {
        const text = 'Hello, World!';
        expect(CipherToolService.rot13(CipherToolService.rot13(text)), text);
      });

      test('preserves non-alphabetic characters', () {
        expect(CipherToolService.rot13('123!@#'), '123!@#');
      });
    });

    // ── Atbash ──

    group('atbash', () {
      test('mirrors uppercase letters A↔Z', () {
        expect(CipherToolService.atbash('A'), 'Z');
        expect(CipherToolService.atbash('Z'), 'A');
        expect(CipherToolService.atbash('M'), 'N');
        expect(CipherToolService.atbash('N'), 'M');
      });

      test('mirrors lowercase letters a↔z', () {
        expect(CipherToolService.atbash('a'), 'z');
        expect(CipherToolService.atbash('z'), 'a');
      });

      test('is self-inverse', () {
        const text = 'Hello, World!';
        expect(CipherToolService.atbash(CipherToolService.atbash(text)), text);
      });

      test('preserves non-alphabetic characters', () {
        expect(CipherToolService.atbash('123 !@#'), '123 !@#');
      });
    });

    // ── Base64 ──

    group('base64Encode / base64Decode', () {
      test('encodes and decodes ASCII text', () {
        const text = 'Hello, World!';
        final encoded = CipherToolService.base64Encode(text);
        expect(CipherToolService.base64Decode(encoded), text);
      });

      test('encodes to known Base64 value', () {
        expect(CipherToolService.base64Encode('Hello'), 'SGVsbG8=');
      });

      test('handles empty string', () {
        expect(CipherToolService.base64Encode(''), '');
        expect(CipherToolService.base64Decode(''), '');
      });

      test('handles UTF-8 characters', () {
        const text = 'Héllo Wörld 日本語';
        final encoded = CipherToolService.base64Encode(text);
        expect(CipherToolService.base64Decode(encoded), text);
      });

      test('returns error marker for invalid base64 input', () {
        expect(CipherToolService.base64Decode('not-valid!!!'),
            '[Invalid Base64]');
      });
    });

    // ── Vigenère Cipher ──

    group('vigenereEncode / vigenereDecode', () {
      test('encrypts with known key', () {
        // ATTACK with key LEMON:
        // A+L=L, T+E=X, T+M=F, A+O=O, C+N=P, K+L=V
        expect(
            CipherToolService.vigenereEncode('ATTACK', 'LEMON'), 'LXFOPV');
      });

      test('decrypts back to original', () {
        const plaintext = 'ATTACKATDAWN';
        const key = 'LEMON';
        final ciphertext = CipherToolService.vigenereEncode(plaintext, key);
        expect(CipherToolService.vigenereDecode(ciphertext, key), plaintext);
      });

      test('preserves case — lowercase plaintext', () {
        const text = 'hello';
        const key = 'KEY';
        final encoded = CipherToolService.vigenereEncode(text, key);
        // Should remain lowercase
        expect(encoded, encoded.toLowerCase());
        expect(CipherToolService.vigenereDecode(encoded, key), text);
      });

      test('skips non-alphabetic characters (key index does not advance)', () {
        const text = 'A B';
        const key = 'B';
        // A shifted by B(1) = B, space stays, B shifted by B(1) = C
        expect(CipherToolService.vigenereEncode(text, key), 'B C');
      });

      test('returns original text when key is empty', () {
        expect(CipherToolService.vigenereEncode('Test', ''), 'Test');
        expect(CipherToolService.vigenereDecode('Test', ''), 'Test');
      });

      test('round-trips mixed case with punctuation', () {
        const text = 'Hello, World! 2026';
        const key = 'Secret';
        final encoded = CipherToolService.vigenereEncode(text, key);
        expect(CipherToolService.vigenereDecode(encoded, key), text);
      });
    });

    // ── cipherNames ──

    test('cipherNames contains all 5 ciphers', () {
      expect(CipherToolService.cipherNames, hasLength(5));
      expect(CipherToolService.cipherNames, contains('Caesar'));
      expect(CipherToolService.cipherNames, contains('ROT13'));
      expect(CipherToolService.cipherNames, contains('Atbash'));
      expect(CipherToolService.cipherNames, contains('Base64'));
      expect(CipherToolService.cipherNames, contains('Vigenère'));
    });
  });
}
