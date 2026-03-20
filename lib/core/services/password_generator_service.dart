import 'dart:math';

/// Configuration and result types for password generation.
class PasswordConfig {
  final int length;
  final bool uppercase;
  final bool lowercase;
  final bool digits;
  final bool symbols;
  final String customSymbols;
  final bool excludeAmbiguous;

  const PasswordConfig({
    this.length = 16,
    this.uppercase = true,
    this.lowercase = true,
    this.digits = true,
    this.symbols = true,
    this.customSymbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?',
    this.excludeAmbiguous = false,
  });

  PasswordConfig copyWith({
    int? length,
    bool? uppercase,
    bool? lowercase,
    bool? digits,
    bool? symbols,
    String? customSymbols,
    bool? excludeAmbiguous,
  }) {
    return PasswordConfig(
      length: length ?? this.length,
      uppercase: uppercase ?? this.uppercase,
      lowercase: lowercase ?? this.lowercase,
      digits: digits ?? this.digits,
      symbols: symbols ?? this.symbols,
      customSymbols: customSymbols ?? this.customSymbols,
      excludeAmbiguous: excludeAmbiguous ?? this.excludeAmbiguous,
    );
  }
}

enum PasswordStrength { weak, fair, good, strong, veryStrong }

class PasswordResult {
  final String password;
  final PasswordStrength strength;
  final double entropy;
  final String strengthLabel;
  final double crackTimeYears;

  const PasswordResult({
    required this.password,
    required this.strength,
    required this.entropy,
    required this.strengthLabel,
    required this.crackTimeYears,
  });
}

/// Generates secure random passwords and evaluates their strength.
class PasswordGeneratorService {
  PasswordGeneratorService._();

  static const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const _digit = '0123456789';
  static const _ambiguous = 'Il1O0';

  static final _random = Random.secure();

  /// Generate a password from [config] and return result with strength info.
  static PasswordResult generate(PasswordConfig config) {
    var pool = '';
    if (config.uppercase) pool += _upper;
    if (config.lowercase) pool += _lower;
    if (config.digits) pool += _digit;
    if (config.symbols) pool += config.customSymbols;

    if (pool.isEmpty) pool = _lower; // fallback

    if (config.excludeAmbiguous) {
      pool = pool.split('').where((c) => !_ambiguous.contains(c)).join();
    }

    final chars = List.generate(
      config.length,
      (_) => pool[_random.nextInt(pool.length)],
    );
    final password = chars.join();

    final entropy = _calcEntropy(password, pool.length);
    final strength = _strengthFromEntropy(entropy);

    return PasswordResult(
      password: password,
      strength: strength,
      entropy: entropy,
      strengthLabel: _strengthLabel(strength),
      crackTimeYears: _crackTime(entropy),
    );
  }

  /// Generate a memorable passphrase from common words.
  static PasswordResult generatePassphrase({
    int wordCount = 4,
    String separator = '-',
    bool capitalize = true,
  }) {
    final words = <String>[];
    for (var i = 0; i < wordCount; i++) {
      var word = _wordList[_random.nextInt(_wordList.length)];
      if (capitalize) {
        word = word[0].toUpperCase() + word.substring(1);
      }
      words.add(word);
    }
    final password = words.join(separator);
    // Approximate entropy: log2(wordListSize) * wordCount
    final entropy = (log(_wordList.length) / ln2) * wordCount;
    final strength = _strengthFromEntropy(entropy);

    return PasswordResult(
      password: password,
      strength: strength,
      entropy: entropy,
      strengthLabel: _strengthLabel(strength),
      crackTimeYears: _crackTime(entropy),
    );
  }

  static double _calcEntropy(String password, int poolSize) {
    if (poolSize <= 1) return 0;
    return password.length * (log(poolSize) / ln2);
  }

  static PasswordStrength _strengthFromEntropy(double entropy) {
    if (entropy < 28) return PasswordStrength.weak;
    if (entropy < 36) return PasswordStrength.fair;
    if (entropy < 60) return PasswordStrength.good;
    if (entropy < 100) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  static String _strengthLabel(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  /// Estimated crack time in years assuming 10 billion guesses/sec.
  static double _crackTime(double entropy) {
    final guesses = pow(2, entropy);
    const guessesPerSec = 1e10;
    const secsPerYear = 365.25 * 24 * 3600;
    return guesses / guessesPerSec / secsPerYear;
  }

  // A small word list for passphrase generation (EFF-inspired subset).
  static const _wordList = [
    'apple', 'brave', 'candy', 'dream', 'eagle', 'flame', 'grace',
    'honey', 'ivory', 'joker', 'kites', 'lemon', 'maple', 'noble',
    'ocean', 'pearl', 'quest', 'river', 'stone', 'tiger', 'ultra',
    'vivid', 'waltz', 'xenon', 'yield', 'zebra', 'amber', 'blaze',
    'charm', 'delta', 'ember', 'frost', 'globe', 'haven', 'index',
    'jewel', 'karma', 'lunar', 'music', 'nerve', 'orbit', 'plaza',
    'quiet', 'radar', 'solar', 'trail', 'unity', 'vault', 'wheat',
    'pixel', 'yacht', 'zephyr', 'acorn', 'bloom', 'coral', 'drift',
    'epoch', 'fjord', 'grain', 'haste', 'igloo', 'jolly', 'knack',
    'lodge', 'mango', 'nexus', 'oasis', 'prism', 'quilt', 'reign',
    'spark', 'tempo', 'urban', 'vigor', 'wrist', 'xylem', 'youth',
    'zingy', 'arrow', 'badge', 'crane', 'diver', 'elbow', 'fable',
    'glyph', 'hiker', 'intro', 'jumbo', 'kneel', 'lilac', 'marsh',
    'north', 'olive', 'patch', 'quota', 'robin', 'swift', 'thorn',
    'usher', 'venom', 'woven', 'oxide', 'yeast', 'zones',
  ];
}
