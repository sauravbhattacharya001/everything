/// Service for converting between Roman numerals and decimal numbers.
class RomanNumeralService {
  RomanNumeralService._();

  static const _romanValues = <String, int>{
    'M': 1000,
    'CM': 900,
    'D': 500,
    'CD': 400,
    'C': 100,
    'XC': 90,
    'L': 50,
    'XL': 40,
    'X': 10,
    'IX': 9,
    'V': 5,
    'IV': 4,
    'I': 1,
  };

  static const _singleValues = <String, int>{
    'I': 1,
    'V': 5,
    'X': 10,
    'L': 50,
    'C': 100,
    'D': 500,
    'M': 1000,
  };

  /// Convert a decimal integer (1–3999) to a Roman numeral string.
  static String toRoman(int number) {
    if (number < 1 || number > 3999) {
      throw ArgumentError('Number must be between 1 and 3999');
    }
    final buf = StringBuffer();
    var remaining = number;
    for (final entry in _romanValues.entries) {
      while (remaining >= entry.value) {
        buf.write(entry.key);
        remaining -= entry.value;
      }
    }
    return buf.toString();
  }

  /// Convert a Roman numeral string to a decimal integer.
  /// Returns null if the input is not a valid Roman numeral.
  static int? toDecimal(String roman) {
    final upper = roman.trim().toUpperCase();
    if (upper.isEmpty) return null;

    // Validate characters
    for (final c in upper.split('')) {
      if (!_singleValues.containsKey(c)) return null;
    }

    var result = 0;
    for (var i = 0; i < upper.length; i++) {
      final current = _singleValues[upper[i]]!;
      final next = i + 1 < upper.length ? _singleValues[upper[i + 1]]! : 0;
      if (current < next) {
        result -= current;
      } else {
        result += current;
      }
    }

    // Validate by round-tripping
    if (result < 1 || result > 3999) return null;
    if (toRoman(result) != upper) return null;

    return result;
  }

  /// Check if a string is a valid Roman numeral.
  static bool isValidRoman(String input) {
    return toDecimal(input) != null;
  }

  /// Common Roman numeral reference table.
  static const referenceTable = <MapEntry<int, String>>[
    MapEntry(1, 'I'),
    MapEntry(4, 'IV'),
    MapEntry(5, 'V'),
    MapEntry(9, 'IX'),
    MapEntry(10, 'X'),
    MapEntry(40, 'XL'),
    MapEntry(50, 'L'),
    MapEntry(90, 'XC'),
    MapEntry(100, 'C'),
    MapEntry(400, 'CD'),
    MapEntry(500, 'D'),
    MapEntry(900, 'CM'),
    MapEntry(1000, 'M'),
  ];
}
