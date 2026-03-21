/// Score Keeper service for tracking game scores across multiple players.
///
/// Supports named game sessions, per-round scoring, undo, and winner
/// detection. All data is ephemeral (lives in memory per app session).
class ScoreKeeperService {
  ScoreKeeperService._();

  /// Predefined game presets with suggested player counts and score targets.
  static final List<GamePreset> presets = [
    GamePreset(name: 'Custom', minPlayers: 2, maxPlayers: 10),
    GamePreset(name: 'Scrabble', minPlayers: 2, maxPlayers: 4, targetScore: 300),
    GamePreset(name: 'Uno', minPlayers: 2, maxPlayers: 10, targetScore: 500),
    GamePreset(name: 'Yahtzee', minPlayers: 1, maxPlayers: 6, rounds: 13),
    GamePreset(name: 'Bowling', minPlayers: 1, maxPlayers: 8, rounds: 10, targetScore: 300),
    GamePreset(name: 'Darts (501)', minPlayers: 2, maxPlayers: 4, targetScore: 501, countDown: true),
    GamePreset(name: 'Basketball', minPlayers: 2, maxPlayers: 2),
    GamePreset(name: 'Catan', minPlayers: 3, maxPlayers: 4, targetScore: 10),
  ];

  /// Determine the winner(s) of a game session.
  static List<PlayerScore> getWinners(GameSession session) {
    if (session.players.isEmpty) return [];
    final sorted = List<PlayerScore>.from(session.players)
      ..sort((a, b) {
        if (session.countDown) return a.total.compareTo(b.total);
        return b.total.compareTo(a.total);
      });
    final topScore = sorted.first.total;
    return sorted.where((p) => p.total == topScore).toList();
  }

  /// Check if any player has reached the target score.
  static PlayerScore? checkTargetReached(GameSession session) {
    if (session.targetScore == null) return null;
    for (final p in session.players) {
      if (session.countDown && p.total <= 0) return p;
      if (!session.countDown && p.total >= session.targetScore!) return p;
    }
    return null;
  }

  /// Calculate per-round scores as a table (players × rounds).
  static List<List<int>> roundTable(GameSession session) {
    return session.players.map((p) => List<int>.from(p.roundScores)).toList();
  }
}

/// A game preset configuration.
class GamePreset {
  final String name;
  final int minPlayers;
  final int maxPlayers;
  final int? targetScore;
  final int? rounds;
  final bool countDown;

  const GamePreset({
    required this.name,
    required this.minPlayers,
    required this.maxPlayers,
    this.targetScore,
    this.rounds,
    this.countDown = false,
  });
}

/// Tracks a single player's score.
class PlayerScore {
  String name;
  final List<int> roundScores;

  PlayerScore({required this.name}) : roundScores = [];

  int get total => roundScores.fold(0, (s, v) => s + v);
  int get roundCount => roundScores.length;

  void addRound(int score) => roundScores.add(score);

  int? undoLast() {
    if (roundScores.isEmpty) return null;
    return roundScores.removeLast();
  }
}

/// A game session holding players and metadata.
class GameSession {
  final String name;
  final List<PlayerScore> players;
  final int? targetScore;
  final int? maxRounds;
  final bool countDown;
  final DateTime createdAt;

  GameSession({
    required this.name,
    required List<String> playerNames,
    this.targetScore,
    this.maxRounds,
    this.countDown = false,
  })  : players = playerNames.map((n) => PlayerScore(name: n)).toList(),
        createdAt = DateTime.now();

  bool get isFinished {
    if (maxRounds != null && players.isNotEmpty) {
      return players.every((p) => p.roundCount >= maxRounds!);
    }
    return ScoreKeeperService.checkTargetReached(this) != null;
  }

  int get currentRound {
    if (players.isEmpty) return 0;
    return players.map((p) => p.roundCount).reduce((a, b) => a < b ? a : b) + 1;
  }
}
