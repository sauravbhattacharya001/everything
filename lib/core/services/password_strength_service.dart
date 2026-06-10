import 'dart:math';

/// Service for analyzing password strength with entropy calculation,
/// crack-time estimation, pattern detection, and improvement tips.
class PasswordStrengthService {
  PasswordStrengthService._();

  // Pre-compiled regexes — avoid allocating new RegExp objects on every
  // analyze() call.  In a real-time password-strength UI where analyze()
  // fires on every keystroke, this eliminates 6 regex compilations per
  // keypress and reduces GC pressure.
  static final _reUpper = RegExp(r'[A-Z]');
  static final _reLower = RegExp(r'[a-z]');
  static final _reDigit = RegExp(r'[0-9]');
  static final _reSymbol = RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?/~`]');
  static final _reNonAlpha = RegExp(r'[^a-zA-Z]');

  /// Analyze a [password] and return a detailed [PasswordAnalysis] report.
  ///
  /// The analysis is purely local and deterministic — no network calls and
  /// no external word lists are consulted. It combines four signals:
  ///
  /// * **Entropy** — Shannon entropy in bits, computed as
  ///   `length * log2(charsetSize)`, where `charsetSize` is the size of the
  ///   alphabet the password draws from (lowercase 26, uppercase 26,
  ///   digits 10, common symbols 33, any non-ASCII rune +100).
  /// * **Crack time** — a rough offline-attack estimate assuming an
  ///   attacker can try 10 billion (1e10) guesses per second against the
  ///   full key space (`2^entropy`).
  /// * **Pattern detection** — flags sequential runs, repeated patterns,
  ///   keyboard walks, common passwords and excessive repetition.
  /// * **Composite score** — a 0–100 value blending the above into a single
  ///   number mapped to a human label (`Very Weak` … `Very Strong`).
  ///
  /// An empty [password] short-circuits to a zeroed report labelled
  /// `'Empty'`. The returned report is safe to display field-by-field; the
  /// original [password] is echoed back in [PasswordAnalysis.password] for
  /// convenience but is never logged or transmitted.
  static PasswordAnalysis analyze(String password) {
    if (password.isEmpty) {
      return PasswordAnalysis(
        password: password,
        score: 0,
        label: 'Empty',
        entropy: 0,
        crackTimeSeconds: 0,
        crackTimeLabel: 'Instant',
        patterns: [],
        suggestions: ['Enter a password to analyze.'],
        charsetSize: 0,
        hasUpper: false,
        hasLower: false,
        hasDigit: false,
        hasSymbol: false,
        hasUnicode: false,
        uniqueChars: 0,
        repeatedChars: 0,
      );
    }

    final hasUpper = password.contains(_reUpper);
    final hasLower = password.contains(_reLower);
    final hasDigit = password.contains(_reDigit);
    final hasSymbol = password.contains(_reSymbol);
    final hasUnicode = password.runes.any((r) => r > 127);

    int charsetSize = 0;
    if (hasLower) charsetSize += 26;
    if (hasUpper) charsetSize += 26;
    if (hasDigit) charsetSize += 10;
    if (hasSymbol) charsetSize += 33;
    if (hasUnicode) charsetSize += 100;

    if (charsetSize == 0) charsetSize = 26; // fallback

    final entropy = password.length * (log(charsetSize) / log(2));
    final crackTimeSeconds = pow(2, entropy) / 1e10; // 10 billion guesses/sec
    final crackTimeLabel = _formatCrackTime(crackTimeSeconds.toDouble());

    final uniqueChars = password.runes.toSet().length;
    final repeatedChars = password.length - uniqueChars;

    final patterns = <String>[];
    final suggestions = <String>[];

    // Pattern detection
    if (password.length < 8) {
      patterns.add('Too short (< 8 characters)');
      suggestions.add('Use at least 12 characters for good security.');
    }
    if (_hasSequentialChars(password)) {
      patterns.add('Sequential characters detected (abc, 123)');
      suggestions.add('Avoid sequential characters like "abc" or "123".');
    }
    if (_hasRepeatedPattern(password)) {
      patterns.add('Repeated pattern detected');
      suggestions.add('Avoid repeating patterns like "abcabc".');
    }
    if (_isCommonPassword(password.toLowerCase())) {
      patterns.add('Common password detected');
      suggestions.add('This password appears in common password lists.');
    }
    if (!hasUpper) {
      suggestions.add('Add uppercase letters for more complexity.');
    }
    if (!hasLower) {
      suggestions.add('Add lowercase letters.');
    }
    if (!hasDigit) {
      suggestions.add('Add numbers for more complexity.');
    }
    if (!hasSymbol) {
      suggestions.add('Add symbols (!@#\$%^&*) for much stronger entropy.');
    }
    if (repeatedChars > password.length * 0.5) {
      patterns.add('High character repetition');
      suggestions.add('Use more unique characters.');
    }
    if (_isKeyboardWalk(password.toLowerCase())) {
      patterns.add('Keyboard walk detected (qwerty, asdf)');
      suggestions.add('Avoid keyboard patterns.');
    }
    if (_isAllSameCase(password)) {
      patterns.add('Single case only');
    }
    if (password.length >= 16 && patterns.isEmpty) {
      suggestions.add('Excellent length! This password is very strong.');
    }

    // Score: 0-100
    double score = 0;
    score += min(30, entropy / 2.0);
    score += min(20, password.length * 1.5);
    score += (hasUpper ? 10 : 0) +
        (hasLower ? 5 : 0) +
        (hasDigit ? 10 : 0) +
        (hasSymbol ? 15 : 0);
    score += min(10, uniqueChars.toDouble());
    // Penalties
    if (_isCommonPassword(password.toLowerCase())) score *= 0.1;
    if (password.length < 6) score *= 0.3;
    score = score.clamp(0, 100);

    String label;
    if (score < 20) {
      label = 'Very Weak';
    } else if (score < 40) {
      label = 'Weak';
    } else if (score < 60) {
      label = 'Fair';
    } else if (score < 80) {
      label = 'Strong';
    } else {
      label = 'Very Strong';
    }

    return PasswordAnalysis(
      password: password,
      score: score.round(),
      label: label,
      entropy: entropy,
      crackTimeSeconds: crackTimeSeconds.toDouble(),
      crackTimeLabel: crackTimeLabel,
      patterns: patterns,
      suggestions: suggestions,
      charsetSize: charsetSize,
      hasUpper: hasUpper,
      hasLower: hasLower,
      hasDigit: hasDigit,
      hasSymbol: hasSymbol,
      hasUnicode: hasUnicode,
      uniqueChars: uniqueChars,
      repeatedChars: repeatedChars,
    );
  }

  /// Render a crack-time estimate in [seconds] as a human-friendly string
  /// (e.g. `'42 minutes'`, `'3 years'`, `'2 billion years'`).
  ///
  /// Buckets escalate from `'Instant'` (< 1 ms) up to billions of years so
  /// the UI never shows an unreadable number of seconds. Year-scale
  /// thresholds use a 365-day year for simplicity.
  static String _formatCrackTime(double seconds) {
    if (seconds < 0.001) return 'Instant';
    if (seconds < 1) return '< 1 second';
    if (seconds < 60) return '${seconds.toStringAsFixed(0)} seconds';
    if (seconds < 3600) return '${(seconds / 60).toStringAsFixed(0)} minutes';
    if (seconds < 86400) return '${(seconds / 3600).toStringAsFixed(0)} hours';
    if (seconds < 86400 * 365) {
      return '${(seconds / 86400).toStringAsFixed(0)} days';
    }
    if (seconds < 86400 * 365 * 1000) {
      return '${(seconds / (86400 * 365)).toStringAsFixed(0)} years';
    }
    if (seconds < 86400 * 365 * 1e6) {
      return '${(seconds / (86400 * 365 * 1000)).toStringAsFixed(0)} thousand years';
    }
    if (seconds < 86400 * 365 * 1e9) {
      return '${(seconds / (86400 * 365 * 1e6)).toStringAsFixed(0)} million years';
    }
    return '${(seconds / (86400 * 365 * 1e9)).toStringAsFixed(0)} billion years';
  }

  /// Whether [pw] contains three consecutive characters whose code units
  /// increase by one each step (e.g. `abc`, `123`, `xyz`).
  ///
  /// Comparison is done on UTF-16 code units, so it only catches ascending
  /// runs within a contiguous block of the character set.
  static bool _hasSequentialChars(String pw) {
    for (int i = 0; i < pw.length - 2; i++) {
      if (pw.codeUnitAt(i) + 1 == pw.codeUnitAt(i + 1) &&
          pw.codeUnitAt(i + 1) + 1 == pw.codeUnitAt(i + 2)) {
        return true;
      }
    }
    return false;
  }

  /// Whether [pw] is entirely composed of a repeated prefix
  /// (e.g. `abcabc`, `xyxyxy`).
  ///
  /// Tries every candidate block length from 2 up to `pw.length ~/ 2` and
  /// reports a match when the whole string is that block tiled end-to-end.
  /// Returns `false` for passwords shorter than four characters.
  ///
  /// Implementation note: the check compares characters by index modulo the
  /// block length rather than allocating concatenated candidate strings,
  /// keeping it allocation-free for the keystroke-driven UI.
  static bool _hasRepeatedPattern(String pw) {
    if (pw.length < 4) return false;
    // Check if pw consists entirely of a repeated prefix of length `len`.
    // Uses character-by-character comparison instead of allocating
    // O(len * repeats) concatenated strings for every candidate length.
    for (int len = 2; len <= pw.length ~/ 2; len++) {
      bool match = true;
      for (int i = len; i < pw.length; i++) {
        if (pw.codeUnitAt(i) != pw.codeUnitAt(i % len)) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
    return false;
  }

  /// Whether [pw] contains a well-known keyboard pattern such as `qwerty`,
  /// `asdf`, `zxcv` or a straight digit run.
  ///
  /// [pw] is expected to already be lower-cased by the caller. The check is
  /// a substring match against a small curated list of adjacent-key runs.
  static bool _isKeyboardWalk(String pw) {
    const walks = [
      'qwerty', 'asdf', 'zxcv', 'qwertyuiop', 'asdfghjkl',
      'zxcvbnm', '1234567890', 'qazwsx', 'password',
    ];
    for (final w in walks) {
      if (pw.contains(w)) return true;
    }
    return false;
  }

  /// Whether every letter in [pw] shares the same case (all upper or all
  /// lower), ignoring digits and symbols.
  ///
  /// Returns `false` when [pw] contains no letters at all, since case is
  /// undefined in that case.
  static bool _isAllSameCase(String pw) {
    final letters = pw.replaceAll(_reNonAlpha, '');
    if (letters.isEmpty) return false;
    return letters == letters.toUpperCase() || letters == letters.toLowerCase();
  }

  /// Whether [pw] exactly matches a small built-in set of the most common
  /// breached/default passwords (e.g. `password`, `123456`, `admin`).
  ///
  /// [pw] is expected to already be lower-cased by the caller. A match here
  /// heavily penalizes the composite score because such passwords are
  /// trivially guessed regardless of their nominal entropy.
  static bool _isCommonPassword(String pw) {
    const common = {
      'password', '123456', '12345678', 'qwerty', 'abc123', 'monkey',
      'master', 'dragon', 'login', 'princess', 'football', 'shadow',
      'sunshine', 'trustno1', 'iloveyou', 'batman', 'access',
      'hello', 'charlie', 'donald', '123456789', 'password1',
      'letmein', 'welcome', 'admin', '1234', '12345', '123',
      'passw0rd', 'p@ssword', 'password123', 'admin123', 'root',
      'toor', 'guest', 'changeme', 'default', 'test', 'demo',
    };
    return common.contains(pw);
  }
}

/// Immutable result of [PasswordStrengthService.analyze].
///
/// All fields are computed locally; no part of this object leaves the device
/// unless the caller chooses to surface it in the UI.
class PasswordAnalysis {
  /// The password that was analyzed, echoed back verbatim.
  final String password;

  /// Composite strength score in the range `0`–`100` (higher is stronger).
  final int score;

  /// Human-readable strength band derived from [score]:
  /// `Very Weak`, `Weak`, `Fair`, `Strong`, `Very Strong` (or `Empty`).
  final String label;

  /// Estimated Shannon entropy in **bits** (`length * log2(charsetSize)`).
  final double entropy;

  /// Estimated time to brute-force the full key space, in **seconds**,
  /// assuming 1e10 guesses/second. Can be astronomically large.
  final double crackTimeSeconds;

  /// [crackTimeSeconds] formatted as a friendly string (e.g. `'3 years'`).
  final String crackTimeLabel;

  /// Human-readable weaknesses detected (sequential chars, common password,
  /// keyboard walk, high repetition, etc.). Empty when none were found.
  final List<String> patterns;

  /// Actionable tips for strengthening the password. Empty when the password
  /// is already strong and no improvements are suggested.
  final List<String> suggestions;

  /// Size of the character alphabet the password draws from, used as the
  /// base for the [entropy] calculation.
  final int charsetSize;

  /// Whether the password contains at least one uppercase letter `A`–`Z`.
  final bool hasUpper;

  /// Whether the password contains at least one lowercase letter `a`–`z`.
  final bool hasLower;

  /// Whether the password contains at least one digit `0`–`9`.
  final bool hasDigit;

  /// Whether the password contains at least one ASCII symbol.
  final bool hasSymbol;

  /// Whether the password contains any non-ASCII rune (code point > 127).
  final bool hasUnicode;

  /// Number of distinct runes in the password.
  final int uniqueChars;

  /// Number of repeated runes, i.e. `length - uniqueChars`.
  final int repeatedChars;

  /// Creates an immutable password analysis result. Normally obtained via
  /// [PasswordStrengthService.analyze] rather than constructed directly.
  const PasswordAnalysis({
    required this.password,
    required this.score,
    required this.label,
    required this.entropy,
    required this.crackTimeSeconds,
    required this.crackTimeLabel,
    required this.patterns,
    required this.suggestions,
    required this.charsetSize,
    required this.hasUpper,
    required this.hasLower,
    required this.hasDigit,
    required this.hasSymbol,
    required this.hasUnicode,
    required this.uniqueChars,
    required this.repeatedChars,
  });
}
