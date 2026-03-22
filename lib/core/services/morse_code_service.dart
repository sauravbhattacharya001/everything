/// Morse Code Translator service.
///
/// Converts text ↔ Morse code with support for letters, digits,
/// and common punctuation. Provides both encoding and decoding.
class MorseCodeService {
  MorseCodeService._();

  static const Map<String, String> _charToMorse = {
    'A': '.-',    'B': '-...',  'C': '-.-.',  'D': '-..',
    'E': '.',     'F': '..-.',  'G': '--.',   'H': '....',
    'I': '..',    'J': '.---',  'K': '-.-',   'L': '.-..',
    'M': '--',    'N': '-.',    'O': '---',   'P': '.--.',
    'Q': '--.-',  'R': '.-.',   'S': '...',   'T': '-',
    'U': '..-',   'V': '...-',  'W': '.--',   'X': '-..-',
    'Y': '-.--',  'Z': '--..',
    '0': '-----', '1': '.----', '2': '..---', '3': '...--',
    '4': '....-', '5': '.....', '6': '-....', '7': '--...',
    '8': '---..', '9': '----.',
    '.': '.-.-.-', ',': '--..--', '?': '..--..', '!': '-.-.--',
    '/': '-..-.', '(': '-.--.',  ')': '-.--.-', '&': '.-...',
    ':': '---...', ';': '-.-.-.', '=': '-...-', '+': '.-.-.',
    '-': '-....-', '_': '..--.-', '"': '.-..-.', '\$': '...-..-',
    '@': '.--.-.', "'": '.----.',
  };

  static final Map<String, String> _morseToChar = {
    for (final e in _charToMorse.entries) e.value: e.key,
  };

  /// Encode plain text to Morse code.
  /// Words are separated by ' / ', letters by ' '.
  static String encode(String text) {
    final upper = text.toUpperCase();
    final buf = StringBuffer();
    for (var i = 0; i < upper.length; i++) {
      final ch = upper[i];
      if (ch == ' ') {
        buf.write(' / ');
      } else {
        final morse = _charToMorse[ch];
        if (morse != null) {
          if (buf.isNotEmpty &&
              buf.toString().isNotEmpty &&
              !buf.toString().endsWith(' ')) {
            buf.write(' ');
          }
          buf.write(morse);
        }
        // skip unknown chars
      }
    }
    return buf.toString();
  }

  /// Decode Morse code back to plain text.
  /// Expects words separated by ' / ' and letters by ' '.
  static String decode(String morse) {
    final words = morse.trim().split(RegExp(r'\s*/\s*'));
    final decoded = <String>[];
    for (final word in words) {
      final letters = word.trim().split(RegExp(r'\s+'));
      final buf = StringBuffer();
      for (final code in letters) {
        if (code.isEmpty) continue;
        final ch = _morseToChar[code];
        buf.write(ch ?? '?');
      }
      decoded.add(buf.toString());
    }
    return decoded.join(' ');
  }

  /// International Morse Code reference table for display.
  static List<MapEntry<String, String>> get referenceTable =>
      _charToMorse.entries.toList();
}
