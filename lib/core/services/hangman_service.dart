import 'dart:math';

/// Hangman game service — classic word guessing game.
class HangmanService {
  static const List<Map<String, String>> _wordBank = [
    {'word': 'FLUTTER', 'hint': 'Mobile app framework'},
    {'word': 'PYTHON', 'hint': 'Programming language named after a snake'},
    {'word': 'GALAXY', 'hint': 'A system of millions of stars'},
    {'word': 'PUZZLE', 'hint': 'A game that tests ingenuity'},
    {'word': 'RHYTHM', 'hint': 'A pattern of beats in music'},
    {'word': 'OXYGEN', 'hint': 'Element we breathe'},
    {'word': 'QUARTZ', 'hint': 'A common mineral in watches'},
    {'word': 'JUNGLE', 'hint': 'Dense tropical forest'},
    {'word': 'WIZARD', 'hint': 'A person who practices magic'},
    {'word': 'SPHINX', 'hint': 'Mythical creature in Egypt'},
    {'word': 'VOYAGE', 'hint': 'A long journey by sea'},
    {'word': 'FROZEN', 'hint': 'Turned to ice'},
    {'word': 'BREEZE', 'hint': 'A gentle wind'},
    {'word': 'CASTLE', 'hint': 'Medieval fortified building'},
    {'word': 'PLANET', 'hint': 'A celestial body orbiting a star'},
    {'word': 'DONKEY', 'hint': 'A domesticated hoofed animal'},
    {'word': 'TROPHY', 'hint': 'An award for winning'},
    {'word': 'CANDLE', 'hint': 'Wax cylinder with a wick'},
    {'word': 'PICKLE', 'hint': 'A preserved cucumber'},
    {'word': 'BANDIT', 'hint': 'An outlaw or robber'},
    {'word': 'JIGSAW', 'hint': 'A puzzle with interlocking pieces'},
    {'word': 'ANCHOR', 'hint': 'Keeps a ship in place'},
    {'word': 'VELVET', 'hint': 'A soft, luxurious fabric'},
    {'word': 'HORROR', 'hint': 'A genre meant to scare'},
    {'word': 'SUMMIT', 'hint': 'The top of a mountain'},
    {'word': 'FOSSIL', 'hint': 'Preserved remains of ancient life'},
    {'word': 'IGLOO', 'hint': 'An ice house'},
    {'word': 'BAMBOO', 'hint': 'Fast-growing grass, panda food'},
    {'word': 'LAPTOP', 'hint': 'Portable computer'},
    {'word': 'MUFFIN', 'hint': 'A small baked cake'},
    {'word': 'COFFEE', 'hint': 'Popular caffeinated beverage'},
    {'word': 'PARROT', 'hint': 'A colorful talking bird'},
    {'word': 'ROCKET', 'hint': 'Vehicle for space travel'},
    {'word': 'SUNSET', 'hint': 'When the sun goes down'},
    {'word': 'PIRATE', 'hint': 'A sea robber'},
    {'word': 'TUNNEL', 'hint': 'An underground passage'},
    {'word': 'JACKET', 'hint': 'An outer garment'},
    {'word': 'DESERT', 'hint': 'A dry, sandy region'},
    {'word': 'FERRET', 'hint': 'A small, furry pet'},
    {'word': 'HARBOR', 'hint': 'A sheltered port for ships'},
  ];

  static const int maxWrong = 6;

  final _random = Random();

  String _word = '';
  String _hint = '';
  Set<String> _guessedLetters = {};
  int _wrongGuesses = 0;
  int _wins = 0;
  int _losses = 0;
  int _streak = 0;
  bool _gameOver = false;
  bool _won = false;
  bool _hintUsed = false;

  String get word => _word;
  String get hint => _hint;
  Set<String> get guessedLetters => _guessedLetters;
  int get wrongGuesses => _wrongGuesses;
  int get maxWrongGuesses => maxWrong;
  int get wins => _wins;
  int get losses => _losses;
  int get streak => _streak;
  bool get gameOver => _gameOver;
  bool get won => _won;
  bool get hintUsed => _hintUsed;

  String get displayWord {
    return _word.split('').map((c) => _guessedLetters.contains(c) ? c : '_').join(' ');
  }

  int get remainingLives => maxWrong - _wrongGuesses;

  HangmanService() {
    newGame();
  }

  void newGame() {
    final entry = _wordBank[_random.nextInt(_wordBank.length)];
    _word = entry['word']!;
    _hint = entry['hint']!;
    _guessedLetters = {};
    _wrongGuesses = 0;
    _gameOver = false;
    _won = false;
    _hintUsed = false;
  }

  /// Returns true if the letter hadn't been guessed before.
  bool guessLetter(String letter) {
    letter = letter.toUpperCase();
    if (_gameOver || _guessedLetters.contains(letter)) return false;

    _guessedLetters.add(letter);

    if (!_word.contains(letter)) {
      _wrongGuesses++;
    }

    // Check win
    if (_word.split('').every((c) => _guessedLetters.contains(c))) {
      _gameOver = true;
      _won = true;
      _wins++;
      _streak++;
    }

    // Check loss
    if (_wrongGuesses >= maxWrong) {
      _gameOver = true;
      _won = false;
      _losses++;
      _streak = 0;
    }

    return true;
  }

  void useHint() {
    _hintUsed = true;
  }

  /// ASCII art hangman stages (0-6 wrong guesses).
  static const List<String> hangmanArt = [
    '  +---+\n  |   |\n      |\n      |\n      |\n      |\n=========',
    '  +---+\n  |   |\n  O   |\n      |\n      |\n      |\n=========',
    '  +---+\n  |   |\n  O   |\n  |   |\n      |\n      |\n=========',
    '  +---+\n  |   |\n  O   |\n /|   |\n      |\n      |\n=========',
    '  +---+\n  |   |\n  O   |\n /|\\  |\n      |\n      |\n=========',
    '  +---+\n  |   |\n  O   |\n /|\\  |\n /    |\n      |\n=========',
    '  +---+\n  |   |\n  O   |\n /|\\  |\n / \\  |\n      |\n=========',
  ];
}
