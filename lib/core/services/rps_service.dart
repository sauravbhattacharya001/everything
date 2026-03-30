import 'dart:math';

/// Possible moves in Rock Paper Scissors.
enum RpsMove { rock, paper, scissors }

/// Result of a single round.
enum RpsOutcome { win, lose, draw }

/// A single round result.
class RpsRound {
  final RpsMove playerMove;
  final RpsMove cpuMove;
  final RpsOutcome outcome;
  final DateTime timestamp;

  RpsRound({
    required this.playerMove,
    required this.cpuMove,
    required this.outcome,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Statistics for RPS history.
class RpsStats {
  final int totalRounds;
  final int wins;
  final int losses;
  final int draws;
  final int currentWinStreak;
  final int bestWinStreak;
  final Map<RpsMove, int> moveCounts;

  RpsStats({
    required this.totalRounds,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.currentWinStreak,
    required this.bestWinStreak,
    required this.moveCounts,
  });

  double get winRate => totalRounds == 0 ? 0 : wins / totalRounds * 100;
}

/// Service that handles Rock Paper Scissors game logic.
class RpsService {
  final _random = Random();
  final List<RpsRound> _history = [];

  List<RpsRound> get history => List.unmodifiable(_history);

  static String moveEmoji(RpsMove move) {
    switch (move) {
      case RpsMove.rock:
        return '🪨';
      case RpsMove.paper:
        return '📄';
      case RpsMove.scissors:
        return '✂️';
    }
  }

  static String moveLabel(RpsMove move) {
    switch (move) {
      case RpsMove.rock:
        return 'Rock';
      case RpsMove.paper:
        return 'Paper';
      case RpsMove.scissors:
        return 'Scissors';
    }
  }

  static String outcomeLabel(RpsOutcome outcome) {
    switch (outcome) {
      case RpsOutcome.win:
        return 'You Win!';
      case RpsOutcome.lose:
        return 'You Lose!';
      case RpsOutcome.draw:
        return 'Draw!';
    }
  }

  static RpsOutcome _determine(RpsMove player, RpsMove cpu) {
    if (player == cpu) return RpsOutcome.draw;
    if ((player == RpsMove.rock && cpu == RpsMove.scissors) ||
        (player == RpsMove.paper && cpu == RpsMove.rock) ||
        (player == RpsMove.scissors && cpu == RpsMove.paper)) {
      return RpsOutcome.win;
    }
    return RpsOutcome.lose;
  }

  /// Play a round against the CPU.
  RpsRound play(RpsMove playerMove) {
    final cpuMove = RpsMove.values[_random.nextInt(3)];
    final outcome = _determine(playerMove, cpuMove);
    final round = RpsRound(
      playerMove: playerMove,
      cpuMove: cpuMove,
      outcome: outcome,
    );
    _history.add(round);
    return round;
  }

  /// Clear all history.
  void clearHistory() => _history.clear();

  /// Get statistics from the game history.
  RpsStats getStats() {
    final wins = _history.where((r) => r.outcome == RpsOutcome.win).length;
    final losses = _history.where((r) => r.outcome == RpsOutcome.lose).length;
    final draws = _history.length - wins - losses;

    // Current win streak
    int currentWinStreak = 0;
    for (int i = _history.length - 1; i >= 0; i--) {
      if (_history[i].outcome == RpsOutcome.win) {
        currentWinStreak++;
      } else {
        break;
      }
    }

    // Best win streak
    int bestWinStreak = 0;
    int streak = 0;
    for (final round in _history) {
      if (round.outcome == RpsOutcome.win) {
        streak++;
        if (streak > bestWinStreak) bestWinStreak = streak;
      } else {
        streak = 0;
      }
    }

    final moveCounts = <RpsMove, int>{};
    for (final move in RpsMove.values) {
      moveCounts[move] = _history.where((r) => r.playerMove == move).length;
    }

    return RpsStats(
      totalRounds: _history.length,
      wins: wins,
      losses: losses,
      draws: draws,
      currentWinStreak: currentWinStreak,
      bestWinStreak: bestWinStreak,
      moveCounts: moveCounts,
    );
  }
}
