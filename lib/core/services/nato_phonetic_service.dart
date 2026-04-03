/// NATO Phonetic Alphabet Converter service.
///
/// Converts text to NATO phonetic alphabet words and back.
/// Supports letters (A-Z) and digits (0-9).
class NatoPhoneticService {
  NatoPhoneticService._();

  static const Map<String, String> _charToNato = {
    'A': 'Alfa',     'B': 'Bravo',    'C': 'Charlie',  'D': 'Delta',
    'E': 'Echo',     'F': 'Foxtrot',  'G': 'Golf',     'H': 'Hotel',
    'I': 'India',    'J': 'Juliet',   'K': 'Kilo',     'L': 'Lima',
    'M': 'Mike',     'N': 'November', 'O': 'Oscar',    'P': 'Papa',
    'Q': 'Quebec',   'R': 'Romeo',    'S': 'Sierra',   'T': 'Tango',
    'U': 'Uniform',  'V': 'Victor',   'W': 'Whiskey',  'X': 'X-ray',
    'Y': 'Yankee',   'Z': 'Zulu',
    '0': 'Zero',     '1': 'One',      '2': 'Two',      '3': 'Three',
    '4': 'Four',     '5': 'Five',     '6': 'Six',      '7': 'Seven',
    '8': 'Eight',    '9': 'Niner',
  };

  static final Map<String, String> _natoToChar = {
    for (final e in _charToNato.entries) e.value.toUpperCase(): e.key,
  };

  /// Encode plain text to NATO phonetic words.
  /// Words in the input are separated by ' | ' in the output.
  /// Letters within a word are separated by spaces.
  static String encode(String text) {
    final upper = text.toUpperCase();
    final words = <String>[];
    final currentWord = <String>[];

    for (var i = 0; i < upper.length; i++) {
      final ch = upper[i];
      if (ch == ' ') {
        if (currentWord.isNotEmpty) {
          words.add(currentWord.join(' '));
          currentWord.clear();
        }
      } else {
        final nato = _charToNato[ch];
        if (nato != null) {
          currentWord.add(nato);
        }
      }
    }
    if (currentWord.isNotEmpty) {
      words.add(currentWord.join(' '));
    }
    return words.join('  |  ');
  }

  /// Decode NATO phonetic words back to plain text.
  /// Expects words separated by '|' and NATO words separated by spaces.
  static String decode(String natoText) {
    final parts = natoText.trim().split(RegExp(r'\s*\|\s*'));
    final decoded = <String>[];
    for (final part in parts) {
      final natoWords = part.trim().split(RegExp(r'\s+'));
      final buf = StringBuffer();
      for (final word in natoWords) {
        if (word.isEmpty) continue;
        final ch = _natoToChar[word.toUpperCase()];
        buf.write(ch ?? '?');
      }
      decoded.add(buf.toString());
    }
    return decoded.join(' ');
  }

  /// Reference table for display.
  static List<MapEntry<String, String>> get referenceTable =>
      _charToNato.entries.toList();
}
