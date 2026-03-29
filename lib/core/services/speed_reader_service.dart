import 'dart:convert';

/// Speed reading mode.
enum SpeedReadMode {
  word,
  chunk;

  String get label {
    switch (this) {
      case SpeedReadMode.word:
        return 'Word by Word';
      case SpeedReadMode.chunk:
        return 'Chunk (3 words)';
    }
  }
}

/// A single reading session record.
class ReadingSession {
  final DateTime timestamp;
  final int wordCount;
  final int wpm;
  final Duration duration;

  const ReadingSession({
    required this.timestamp,
    required this.wordCount,
    required this.wpm,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'wordCount': wordCount,
        'wpm': wpm,
        'durationMs': duration.inMilliseconds,
      };

  factory ReadingSession.fromJson(Map<String, dynamic> json) => ReadingSession(
        timestamp: DateTime.parse(json['timestamp'] as String),
        wordCount: json['wordCount'] as int,
        wpm: json['wpm'] as int,
        duration: Duration(milliseconds: json['durationMs'] as int),
      );
}

/// Service for RSVP (Rapid Serial Visual Presentation) speed reading.
class SpeedReaderService {
  final List<ReadingSession> _history = [];
  List<ReadingSession> get history => List.unmodifiable(_history);

  /// Default sample texts for practice.
  static const List<String> sampleTexts = [
    'The quick brown fox jumps over the lazy dog. '
        'A journey of a thousand miles begins with a single step. '
        'To be or not to be, that is the question. '
        'All that glitters is not gold. '
        'The only thing we have to fear is fear itself. '
        'In the middle of difficulty lies opportunity. '
        'Life is what happens when you are busy making other plans.',
    'Technology is best when it brings people together. '
        'The advance of technology is based on making it fit in so that you do not really even notice it. '
        'Any sufficiently advanced technology is indistinguishable from magic. '
        'Innovation distinguishes between a leader and a follower. '
        'The science of today is the technology of tomorrow.',
    'The universe is under no obligation to make sense to you. '
        'Somewhere, something incredible is waiting to be known. '
        'The good thing about science is that it is true whether or not you believe in it. '
        'We are all made of star stuff. '
        'Look up at the stars and not down at your feet.',
  ];

  static const List<String> sampleTitles = [
    'Classic Quotes',
    'Technology & Innovation',
    'Science & Universe',
  ];

  /// Split text into display units based on mode.
  List<String> tokenize(String text, SpeedReadMode mode) {
    final words = text.split(RegExp(r'\s+'));
    if (mode == SpeedReadMode.word) return words;

    // Chunk mode: groups of 3
    final chunks = <String>[];
    for (var i = 0; i < words.length; i += 3) {
      final end = (i + 3 > words.length) ? words.length : i + 3;
      chunks.add(words.sublist(i, end).join(' '));
    }
    return chunks;
  }

  /// Record a completed session.
  void addSession(ReadingSession session) {
    _history.insert(0, session);
    if (_history.length > 50) _history.removeLast();
  }

  /// Average WPM across all sessions.
  int get averageWpm {
    if (_history.isEmpty) return 0;
    final total = _history.fold<int>(0, (sum, s) => sum + s.wpm);
    return total ~/ _history.length;
  }

  /// Total words read.
  int get totalWordsRead =>
      _history.fold<int>(0, (sum, s) => sum + s.wordCount);

  void clearHistory() => _history.clear();
}
