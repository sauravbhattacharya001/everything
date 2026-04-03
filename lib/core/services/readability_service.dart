/// Readability analysis service — computes standard readability indices
/// for English text: Flesch Reading Ease, Flesch-Kincaid Grade Level,
/// Gunning Fog Index, Coleman-Liau Index, Automated Readability Index (ARI),
/// and SMOG Grade.
class ReadabilityService {
  ReadabilityService._();

  static ReadabilityResult analyze(String text) {
    if (text.trim().isEmpty) return ReadabilityResult.empty();

    final sentences = _countSentences(text);
    final words = _extractWords(text);
    final wordCount = words.length;
    final syllableCounts = words.map(_countSyllables).toList();
    final totalSyllables = syllableCounts.fold<int>(0, (a, b) => a + b);
    final complexWords = syllableCounts.where((s) => s >= 3).length;
    final charCount = words.fold<int>(0, (a, w) => a + w.length);

    if (wordCount == 0 || sentences == 0) return ReadabilityResult.empty();

    final avgSentenceLen = wordCount / sentences;
    final avgSyllablesPerWord = totalSyllables / wordCount;
    final avgLettersPerWord = charCount / wordCount;

    final fleschEase =
        206.835 - 1.015 * avgSentenceLen - 84.6 * avgSyllablesPerWord;
    final fleschKincaid =
        0.39 * avgSentenceLen + 11.8 * avgSyllablesPerWord - 15.59;
    final fog = 0.4 * (avgSentenceLen + 100 * complexWords / wordCount);
    final L = avgLettersPerWord * 100;
    final S = sentences / wordCount * 100;
    final colemanLiau = 0.0588 * L - 0.296 * S - 15.8;
    final ari =
        4.71 * (charCount / wordCount) + 0.5 * (wordCount / sentences) - 21.43;
    final smog = 1.0430 *
            _sqrt(complexWords * (30 / (sentences > 0 ? sentences : 1))) +
        3.1291;

    return ReadabilityResult(
      wordCount: wordCount,
      sentenceCount: sentences,
      syllableCount: totalSyllables,
      complexWordCount: complexWords,
      fleschReadingEase: fleschEase.clamp(-200, 121).roundToDouble(),
      fleschKincaidGrade: fleschKincaid.clamp(0, 30).roundToDouble(),
      gunningFog: fog.clamp(0, 30).roundToDouble(),
      colemanLiau: colemanLiau.clamp(0, 30).roundToDouble(),
      ari: ari.clamp(0, 30).roundToDouble(),
      smogGrade: smog.clamp(0, 30).roundToDouble(),
      avgWordsPerSentence: avgSentenceLen,
      avgSyllablesPerWord: avgSyllablesPerWord,
    );
  }

  static double _sqrt(double v) {
    if (v <= 0) return 0;
    double x = v;
    for (int i = 0; i < 20; i++) {
      x = (x + v / x) / 2;
    }
    return x;
  }

  static int _countSentences(String text) {
    final matches = RegExp(r'[.!?]+').allMatches(text);
    return matches.isEmpty ? 1 : matches.length;
  }

  static List<String> _extractWords(String text) {
    return RegExp(r"[a-zA-Z']+")
        .allMatches(text)
        .map((m) => m.group(0)!)
        .where((w) => w.length > 0)
        .toList();
  }

  static int _countSyllables(String word) {
    word = word.toLowerCase();
    if (word.length <= 2) return 1;
    int count = 0;
    bool prevVowel = false;
    const vowels = {'a', 'e', 'i', 'o', 'u', 'y'};
    for (int i = 0; i < word.length; i++) {
      final isVowel = vowels.contains(word[i]);
      if (isVowel && !prevVowel) count++;
      prevVowel = isVowel;
    }
    if (word.endsWith('e') && !word.endsWith('le')) {
      count = count > 1 ? count - 1 : count;
    }
    if (word.endsWith('ed') && !word.endsWith('ted') && !word.endsWith('ded')) {
      count = count > 1 ? count - 1 : count;
    }
    return count < 1 ? 1 : count;
  }
}

class ReadabilityResult {
  final int wordCount;
  final int sentenceCount;
  final int syllableCount;
  final int complexWordCount;
  final double fleschReadingEase;
  final double fleschKincaidGrade;
  final double gunningFog;
  final double colemanLiau;
  final double ari;
  final double smogGrade;
  final double avgWordsPerSentence;
  final double avgSyllablesPerWord;

  const ReadabilityResult({
    required this.wordCount,
    required this.sentenceCount,
    required this.syllableCount,
    required this.complexWordCount,
    required this.fleschReadingEase,
    required this.fleschKincaidGrade,
    required this.gunningFog,
    required this.colemanLiau,
    required this.ari,
    required this.smogGrade,
    required this.avgWordsPerSentence,
    required this.avgSyllablesPerWord,
  });

  factory ReadabilityResult.empty() => const ReadabilityResult(
        wordCount: 0, sentenceCount: 0, syllableCount: 0, complexWordCount: 0,
        fleschReadingEase: 0, fleschKincaidGrade: 0, gunningFog: 0,
        colemanLiau: 0, ari: 0, smogGrade: 0, avgWordsPerSentence: 0,
        avgSyllablesPerWord: 0,
      );

  String get readingLevel {
    if (fleschReadingEase >= 90) return 'Very Easy (5th grade)';
    if (fleschReadingEase >= 80) return 'Easy (6th grade)';
    if (fleschReadingEase >= 70) return 'Fairly Easy (7th grade)';
    if (fleschReadingEase >= 60) return 'Standard (8th–9th grade)';
    if (fleschReadingEase >= 50) return 'Fairly Difficult (10th–12th)';
    if (fleschReadingEase >= 30) return 'Difficult (College)';
    return 'Very Difficult (Graduate)';
  }

  String get audience {
    final avg = (fleschKincaidGrade + gunningFog + colemanLiau + ari) / 4;
    if (avg <= 6) return 'Children / General Public';
    if (avg <= 9) return 'Teenagers / General Audience';
    if (avg <= 12) return 'High School / Educated Adults';
    if (avg <= 16) return 'College Students';
    return 'Graduate / Professional';
  }
}
