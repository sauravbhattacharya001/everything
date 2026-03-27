import 'dart:math';

/// Holds results of a typing speed test.
class TypingResult {
  final int wordsPerMinute;
  final double accuracy;
  final int correctChars;
  final int totalChars;
  final Duration elapsed;
  final DateTime timestamp;

  const TypingResult({
    required this.wordsPerMinute,
    required this.accuracy,
    required this.correctChars,
    required this.totalChars,
    required this.elapsed,
    required this.timestamp,
  });
}

/// Service that manages typing speed test logic.
class TypingSpeedService {
  static final _random = Random();

  static const List<String> _paragraphs = [
    'The quick brown fox jumps over the lazy dog near the riverbank while the sun sets behind the mountains painting the sky in shades of orange and purple.',
    'Programming is the art of telling a computer what to do through a series of instructions written in a language it can understand and execute efficiently.',
    'A journey of a thousand miles begins with a single step and every great achievement started with the decision to try something new and challenging.',
    'The best way to predict the future is to create it by working hard today and making small improvements every day that compound over time into something remarkable.',
    'In the middle of difficulty lies opportunity and those who persevere through challenges often discover strengths they never knew they had within themselves.',
    'Technology is best when it brings people together and helps them communicate collaborate and solve problems that matter to the world around them.',
    'Reading is to the mind what exercise is to the body and both require consistent practice dedication and a willingness to push beyond comfortable limits.',
    'Success is not final and failure is not fatal it is the courage to continue that counts most when facing the inevitable obstacles along the path.',
    'The only limit to our realization of tomorrow will be our doubts of today so let us move forward with strong and active faith in our abilities.',
    'Creativity is intelligence having fun and the most innovative solutions often come from combining ideas that nobody thought to put together before.',
    'Every expert was once a beginner and every master was once a disaster but they kept practicing kept learning and kept pushing forward despite setbacks.',
    'The secret of getting ahead is getting started and breaking complex tasks into small manageable pieces that can be completed one at a time with focus.',
  ];

  /// Returns a random paragraph for the user to type.
  String getRandomParagraph() {
    return _paragraphs[_random.nextInt(_paragraphs.length)];
  }

  /// Calculate typing result from the target text, typed text, and elapsed time.
  TypingResult calculateResult({
    required String target,
    required String typed,
    required Duration elapsed,
  }) {
    if (elapsed.inSeconds == 0) {
      return TypingResult(
        wordsPerMinute: 0,
        accuracy: 0,
        correctChars: 0,
        totalChars: typed.length,
        elapsed: elapsed,
        timestamp: DateTime.now(),
      );
    }

    int correctChars = 0;
    final minLen = min(target.length, typed.length);
    for (int i = 0; i < minLen; i++) {
      if (target[i] == typed[i]) correctChars++;
    }

    final accuracy = typed.isEmpty ? 0.0 : (correctChars / typed.length) * 100;
    // Standard: 1 word = 5 characters
    final minutes = elapsed.inMilliseconds / 60000.0;
    final grossWpm = (typed.length / 5.0) / minutes;
    final netWpm = max(0, (grossWpm * (accuracy / 100)).round());

    return TypingResult(
      wordsPerMinute: netWpm,
      accuracy: accuracy,
      correctChars: correctChars,
      totalChars: typed.length,
      elapsed: elapsed,
      timestamp: DateTime.now(),
    );
  }
}
