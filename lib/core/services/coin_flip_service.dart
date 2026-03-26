import 'dart:math';

/// Result of a single coin flip.
class CoinFlipResult {
  final bool isHeads;
  final DateTime timestamp;

  CoinFlipResult({required this.isHeads, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  String get label => isHeads ? 'Heads' : 'Tails';
}

/// Statistics for coin flip history.
class CoinFlipStats {
  final int totalFlips;
  final int heads;
  final int tails;
  final int currentStreak;
  final String currentStreakLabel;
  final int longestStreak;
  final String longestStreakLabel;

  CoinFlipStats({
    required this.totalFlips,
    required this.heads,
    required this.tails,
    required this.currentStreak,
    required this.currentStreakLabel,
    required this.longestStreak,
    required this.longestStreakLabel,
  });

  double get headsPercentage => totalFlips == 0 ? 0 : heads / totalFlips * 100;
  double get tailsPercentage => totalFlips == 0 ? 0 : tails / totalFlips * 100;
}

/// Service that handles coin flip logic, history, and statistics.
class CoinFlipService {
  final _random = Random();
  final List<CoinFlipResult> _history = [];

  List<CoinFlipResult> get history => List.unmodifiable(_history);

  /// Flip the coin and return the result.
  CoinFlipResult flip() {
    final result = CoinFlipResult(isHeads: _random.nextBool());
    _history.add(result);
    return result;
  }

  /// Flip multiple coins at once.
  List<CoinFlipResult> flipMultiple(int count) {
    return List.generate(count, (_) => flip());
  }

  /// Clear all history.
  void clearHistory() => _history.clear();

  /// Get statistics from the flip history.
  CoinFlipStats getStats() {
    final heads = _history.where((r) => r.isHeads).length;
    final tails = _history.length - heads;

    // Current streak
    int currentStreak = 0;
    String currentStreakLabel = '-';
    if (_history.isNotEmpty) {
      final lastVal = _history.last.isHeads;
      for (int i = _history.length - 1; i >= 0; i--) {
        if (_history[i].isHeads == lastVal) {
          currentStreak++;
        } else {
          break;
        }
      }
      currentStreakLabel = '${currentStreak} ${lastVal ? "Heads" : "Tails"}';
    }

    // Longest streak
    int longestStreak = 0;
    String longestStreakLabel = '-';
    if (_history.isNotEmpty) {
      int streak = 1;
      bool streakVal = _history.first.isHeads;
      bool bestVal = streakVal;
      int bestStreak = 1;
      for (int i = 1; i < _history.length; i++) {
        if (_history[i].isHeads == _history[i - 1].isHeads) {
          streak++;
        } else {
          if (streak > bestStreak) {
            bestStreak = streak;
            bestVal = _history[i - 1].isHeads;
          }
          streak = 1;
        }
      }
      if (streak > bestStreak) {
        bestStreak = streak;
        bestVal = _history.last.isHeads;
      }
      longestStreak = bestStreak;
      longestStreakLabel = '$bestStreak ${bestVal ? "Heads" : "Tails"}';
    }

    return CoinFlipStats(
      totalFlips: _history.length,
      heads: heads,
      tails: tails,
      currentStreak: currentStreak,
      currentStreakLabel: currentStreakLabel,
      longestStreak: longestStreak,
      longestStreakLabel: longestStreakLabel,
    );
  }
}
