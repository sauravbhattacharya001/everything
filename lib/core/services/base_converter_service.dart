/// Service for converting numbers between bases (binary, octal, decimal, hex)
/// with support for arbitrary bases 2–36.
class BaseConverterService {
  BaseConverterService._();

  /// Supported named bases.
  static const Map<String, int> namedBases = {
    'Binary (2)': 2,
    'Octal (8)': 8,
    'Decimal (10)': 10,
    'Hexadecimal (16)': 16,
    'Base-32': 32,
    'Base-36': 36,
  };

  /// Convert [input] from [fromBase] to [toBase].
  /// Returns null if the input is invalid for the given base.
  static String? convert(String input, int fromBase, int toBase) {
    input = input.trim();
    if (input.isEmpty) return null;
    if (fromBase < 2 || fromBase > 36 || toBase < 2 || toBase > 36) {
      return null;
    }
    try {
      final value = BigInt.parse(input, radix: fromBase);
      return value.toRadixString(toBase).toUpperCase();
    } catch (_) {
      return null;
    }
  }

  /// Convert [input] from [fromBase] to all named bases.
  /// Returns a map of base-name → converted-value, or null if invalid.
  static Map<String, String>? convertToAll(String input, int fromBase) {
    input = input.trim();
    if (input.isEmpty) return null;
    try {
      final value = BigInt.parse(input, radix: fromBase);
      final result = <String, String>{};
      for (final entry in namedBases.entries) {
        result[entry.key] = value.toRadixString(entry.value).toUpperCase();
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Returns valid characters for the given base.
  static String validChars(int base) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return chars.substring(0, base);
  }

  /// Validates whether [input] is a valid number in the given [base].
  static bool isValid(String input, int base) {
    input = input.trim().toUpperCase();
    if (input.isEmpty) return false;
    final valid = validChars(base);
    return input.split('').every((c) => valid.contains(c));
  }

  /// Format a binary string with spaces every 4 digits for readability.
  static String formatBinary(String binary) {
    binary = binary.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < binary.length; i++) {
      if (i > 0 && (binary.length - i) % 4 == 0) buffer.write(' ');
      buffer.write(binary[i]);
    }
    return buffer.toString();
  }

  /// Format a hex string with spaces every 2 digits.
  static String formatHex(String hex) {
    hex = hex.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < hex.length; i++) {
      if (i > 0 && (hex.length - i) % 2 == 0) buffer.write(' ');
      buffer.write(hex[i]);
    }
    return buffer.toString();
  }
}
