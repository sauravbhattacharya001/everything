import 'dart:math';

/// Business logic for the Simon Says memory game.
///
/// The game shows a sequence of colored-button flashes that the player must
/// reproduce in the same order.  Each successful round adds one more flash.
class SimonSaysService {
  final _random = Random();

  /// The four button indices (0-3 → green, red, yellow, blue).
  static const int buttonCount = 4;

  /// Computer-generated sequence so far.
  List<int> _sequence = [];

  /// Player's input for the current round.
  List<int> _playerInput = [];

  /// Whether the game is over.
  bool gameOver = false;

  /// Highest score this session.
  int highScore = 0;

  /// Current round (1-based, equals sequence length).
  int get round => _sequence.length;

  /// Current score = rounds completed successfully.
  int get score => gameOver ? _sequence.length - 1 : _sequence.length;

  /// The sequence the player needs to match.
  List<int> get sequence => List.unmodifiable(_sequence);

  /// How many inputs the player has entered this round.
  int get inputCount => _playerInput.length;

  /// Start a new game from scratch.
  void reset() {
    _sequence = [];
    _playerInput = [];
    gameOver = false;
    _addToSequence();
  }

  /// Extend the sequence by one random button.
  void _addToSequence() {
    _sequence.add(_random.nextInt(buttonCount));
    _playerInput = [];
  }

  /// Player taps a button.  Returns `true` if the input was correct.
  /// When the player completes the round, automatically advances.
  /// Sets [gameOver] on wrong input.
  bool tap(int buttonIndex) {
    if (gameOver) return false;

    _playerInput.add(buttonIndex);
    final pos = _playerInput.length - 1;

    if (_sequence[pos] != buttonIndex) {
      gameOver = true;
      if (score > highScore) highScore = score;
      return false;
    }

    // Round complete?
    if (_playerInput.length == _sequence.length) {
      _addToSequence();
    }
    return true;
  }
}
