import 'dart:convert';

/// Cipher Tool service providing encode/decode for multiple ciphers.
class CipherToolService {
  CipherToolService._();

  // ── Caesar Cipher ──

  /// Shifts each letter by [shift] positions in the alphabet.
  static String caesarEncode(String text, int shift) {
    shift = shift % 26;
    if (shift < 0) shift += 26;
    return String.fromCharCodes(text.codeUnits.map((c) {
      if (c >= 65 && c <= 90) return (c - 65 + shift) % 26 + 65;
      if (c >= 97 && c <= 122) return (c - 97 + shift) % 26 + 97;
      return c;
    }));
  }

  static String caesarDecode(String text, int shift) =>
      caesarEncode(text, -shift);

  // ── ROT13 ──

  static String rot13(String text) => caesarEncode(text, 13);

  // ── Atbash ──

  /// Mirrors each letter: A↔Z, B↔Y, etc.
  static String atbash(String text) {
    return String.fromCharCodes(text.codeUnits.map((c) {
      if (c >= 65 && c <= 90) return 90 - (c - 65);
      if (c >= 97 && c <= 122) return 122 - (c - 97);
      return c;
    }));
  }

  // ── Base64 ──

  static String base64Encode(String text) => base64.encode(utf8.encode(text));

  static String base64Decode(String text) {
    try {
      return utf8.decode(base64.decode(text.trim()));
    } catch (_) {
      return '[Invalid Base64]';
    }
  }

  // ── Vigenère Cipher ──

  static String vigenereEncode(String text, String key) {
    if (key.isEmpty) return text;
    final k = key.toUpperCase().codeUnits;
    int ki = 0;
    return String.fromCharCodes(text.codeUnits.map((c) {
      if (c >= 65 && c <= 90) {
        final shift = k[ki % k.length] - 65;
        ki++;
        return (c - 65 + shift) % 26 + 65;
      }
      if (c >= 97 && c <= 122) {
        final shift = k[ki % k.length] - 65;
        ki++;
        return (c - 97 + shift) % 26 + 97;
      }
      return c;
    }));
  }

  static String vigenereDecode(String text, String key) {
    if (key.isEmpty) return text;
    final k = key.toUpperCase().codeUnits;
    int ki = 0;
    return String.fromCharCodes(text.codeUnits.map((c) {
      if (c >= 65 && c <= 90) {
        final shift = k[ki % k.length] - 65;
        ki++;
        return (c - 65 - shift + 26) % 26 + 65;
      }
      if (c >= 97 && c <= 122) {
        final shift = k[ki % k.length] - 65;
        ki++;
        return (c - 97 - shift + 26) % 26 + 97;
      }
      return c;
    }));
  }

  /// List of all available cipher names.
  static const List<String> cipherNames = [
    'Caesar',
    'ROT13',
    'Atbash',
    'Base64',
    'Vigenère',
  ];
}
