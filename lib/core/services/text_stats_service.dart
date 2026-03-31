/// Analyzes text and returns detailed statistics including word count,
/// character count, sentence count, paragraph count, reading time, and
/// character/word frequency distributions.
class TextStatsService {
  TextStatsService._();

  /// Analyze [text] and return a [TextStatsResult].
  static TextStatsResult analyze(String text) {
    if (text.trim().isEmpty) return TextStatsResult.empty();

    final characters = text.length;
    final charactersNoSpaces = text.replaceAll(RegExp(r'\s'), '').length;

    final words = _countWords(text);
    final sentences = _countSentences(text);
    final paragraphs = _countParagraphs(text);
    final lines = text.split('\n').length;

    // Average adult reads ~238 words per minute (based on meta-analysis)
    final readingTimeSeconds = words > 0 ? (words / 238 * 60).round() : 0;

    // Speaking rate ~150 wpm
    final speakingTimeSeconds = words > 0 ? (words / 150 * 60).round() : 0;

    final avgWordLength =
        words > 0 ? (charactersNoSpaces / words).toStringAsFixed(1) : '0.0';
    final avgSentenceLength =
        sentences > 0 ? (words / sentences).toStringAsFixed(1) : '0.0';

    final topWords = _topWords(text, 10);
    final topLetters = _topLetters(text, 10);

    // Unique words
    final allWords = _extractWords(text);
    final uniqueWords = allWords.map((w) => w.toLowerCase()).toSet().length;

    // Longest word
    final longestWord =
        allWords.isNotEmpty ? allWords.reduce((a, b) => a.length >= b.length ? a : b) : '';

    return TextStatsResult(
      characters: characters,
      charactersNoSpaces: charactersNoSpaces,
      words: words,
      uniqueWords: uniqueWords,
      sentences: sentences,
      paragraphs: paragraphs,
      lines: lines,
      readingTimeSeconds: readingTimeSeconds,
      speakingTimeSeconds: speakingTimeSeconds,
      avgWordLength: avgWordLength,
      avgSentenceLength: avgSentenceLength,
      longestWord: longestWord,
      topWords: topWords,
      topLetters: topLetters,
    );
  }

  static List<String> _extractWords(String text) {
    return RegExp(r"[a-zA-Z'\u2019]+")
        .allMatches(text)
        .map((m) => m.group(0)!)
        .where((w) => w.isNotEmpty)
        .toList();
  }

  static int _countWords(String text) => _extractWords(text).length;

  static int _countSentences(String text) {
    final matches = RegExp(r'[.!?]+(\s|$)').allMatches(text);
    return matches.isEmpty ? (text.trim().isNotEmpty ? 1 : 0) : matches.length;
  }

  static int _countParagraphs(String text) {
    return text
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .length;
  }

  static List<MapEntry<String, int>> _topWords(String text, int count) {
    final freq = <String, int>{};
    for (final w in _extractWords(text)) {
      final lower = w.toLowerCase();
      freq[lower] = (freq[lower] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).toList();
  }

  static List<MapEntry<String, int>> _topLetters(String text, int count) {
    final freq = <String, int>{};
    for (final ch in text.toLowerCase().runes) {
      final c = String.fromCharCode(ch);
      if (RegExp(r'[a-z]').hasMatch(c)) {
        freq[c] = (freq[c] ?? 0) + 1;
      }
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).toList();
  }
}

class TextStatsResult {
  final int characters;
  final int charactersNoSpaces;
  final int words;
  final int uniqueWords;
  final int sentences;
  final int paragraphs;
  final int lines;
  final int readingTimeSeconds;
  final int speakingTimeSeconds;
  final String avgWordLength;
  final String avgSentenceLength;
  final String longestWord;
  final List<MapEntry<String, int>> topWords;
  final List<MapEntry<String, int>> topLetters;

  const TextStatsResult({
    required this.characters,
    required this.charactersNoSpaces,
    required this.words,
    required this.uniqueWords,
    required this.sentences,
    required this.paragraphs,
    required this.lines,
    required this.readingTimeSeconds,
    required this.speakingTimeSeconds,
    required this.avgWordLength,
    required this.avgSentenceLength,
    required this.longestWord,
    required this.topWords,
    required this.topLetters,
  });

  factory TextStatsResult.empty() => const TextStatsResult(
        characters: 0,
        charactersNoSpaces: 0,
        words: 0,
        uniqueWords: 0,
        sentences: 0,
        paragraphs: 0,
        lines: 0,
        readingTimeSeconds: 0,
        speakingTimeSeconds: 0,
        avgWordLength: '0.0',
        avgSentenceLength: '0.0',
        longestWord: '',
        topWords: [],
        topLetters: [],
      );

  String get readingTime {
    if (readingTimeSeconds < 60) return '${readingTimeSeconds}s';
    final min = readingTimeSeconds ~/ 60;
    final sec = readingTimeSeconds % 60;
    return sec > 0 ? '${min}m ${sec}s' : '${min}m';
  }

  String get speakingTime {
    if (speakingTimeSeconds < 60) return '${speakingTimeSeconds}s';
    final min = speakingTimeSeconds ~/ 60;
    final sec = speakingTimeSeconds % 60;
    return sec > 0 ? '${min}m ${sec}s' : '${min}m';
  }
}
