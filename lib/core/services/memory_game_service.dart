import 'dart:math';

/// A card in the memory matching game.
class MemoryCard {
  final int id;
  final String emoji;
  bool isFaceUp;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.emoji,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}

/// Difficulty levels for the memory game.
enum GameDifficulty {
  easy(pairs: 6, label: 'Easy (6 pairs)'),
  medium(pairs: 8, label: 'Medium (8 pairs)'),
  hard(pairs: 10, label: 'Hard (10 pairs)'),
  expert(pairs: 15, label: 'Expert (15 pairs)');

  final int pairs;
  final String label;
  const GameDifficulty({required this.pairs, required this.label});
}

/// Game statistics for a completed round.
class GameStats {
  final int moves;
  final Duration elapsed;
  final GameDifficulty difficulty;
  final DateTime completedAt;

  GameStats({
    required this.moves,
    required this.elapsed,
    required this.difficulty,
    required this.completedAt,
  });

  double get movesPerPair => moves / difficulty.pairs;
}

/// Service that manages memory card game state and history.
class MemoryGameService {
  static const List<String> _allEmojis = [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼',
    '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐔',
    '🦄', '🐝', '🦋', '🐢', '🐙', '🦀', '🐬', '🦜',
  ];

  List<MemoryCard> cards = [];
  int moves = 0;
  int? _firstFlippedIndex;
  bool isProcessing = false;
  bool isGameOver = false;
  final List<GameStats> history = [];
  GameDifficulty difficulty = GameDifficulty.easy;
  DateTime? _startTime;
  final _random = Random();

  /// Start a new game with the current difficulty.
  void newGame() {
    final emojis = List<String>.from(_allEmojis)..shuffle(_random);
    final selected = emojis.take(difficulty.pairs).toList();
    final paired = <MemoryCard>[];

    for (int i = 0; i < selected.length; i++) {
      paired.add(MemoryCard(id: i * 2, emoji: selected[i]));
      paired.add(MemoryCard(id: i * 2 + 1, emoji: selected[i]));
    }
    paired.shuffle(_random);

    cards = paired;
    moves = 0;
    _firstFlippedIndex = null;
    isProcessing = false;
    isGameOver = false;
    _startTime = DateTime.now();
  }

  /// Flip a card at the given index. Returns true if a pair check is needed.
  bool flipCard(int index) {
    if (isProcessing || cards[index].isFaceUp || cards[index].isMatched) {
      return false;
    }

    cards[index].isFaceUp = true;

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
      return false;
    }

    moves++;
    return true; // pair check needed
  }

  /// Check if the two flipped cards match. Returns the indices.
  ({int first, int second, bool matched}) checkMatch() {
    final first = _firstFlippedIndex!;
    final second = cards.indexWhere(
      (c) => c.isFaceUp && !c.isMatched && cards.indexOf(c) != first,
    );

    final matched = cards[first].emoji == cards[second].emoji;

    if (matched) {
      cards[first].isMatched = true;
      cards[second].isMatched = true;

      if (cards.every((c) => c.isMatched)) {
        isGameOver = true;
        final elapsed = DateTime.now().difference(_startTime!);
        history.insert(
          0,
          GameStats(
            moves: moves,
            elapsed: elapsed,
            difficulty: difficulty,
            completedAt: DateTime.now(),
          ),
        );
      }
    }

    _firstFlippedIndex = null;
    return (first: first, second: second, matched: matched);
  }

  /// Hide unmatched cards after a delay.
  void hideUnmatched(int first, int second) {
    cards[first].isFaceUp = false;
    cards[second].isFaceUp = false;
  }

  Duration get elapsed => _startTime != null
      ? DateTime.now().difference(_startTime!)
      : Duration.zero;

  int get matchedPairs => cards.where((c) => c.isMatched).length ~/ 2;
  int get totalPairs => cards.length ~/ 2;

  GameStats? get bestGame {
    if (history.isEmpty) return null;
    final byDifficulty = history.where((g) => g.difficulty == difficulty);
    if (byDifficulty.isEmpty) return null;
    return byDifficulty.reduce((a, b) => a.moves < b.moves ? a : b);
  }
}
