import 'dart:math';
import '../../models/vocab_entry.dart';

/// Service for managing vocabulary words with quiz and review features.
class VocabularyBuilderService {
  final List<VocabEntry> _words = [];
  final Random _random = Random();

  List<VocabEntry> get words => List.unmodifiable(_words);
  int get totalWords => _words.length;
  int get favoriteCount => _words.where((w) => w.isFavorite).length;
  int get masteredCount =>
      _words.where((w) => w.mastery == MasteryLevel.mastered).length;

  void addWord(VocabEntry word) => _words.add(word);

  bool removeWord(String id) {
    final idx = _words.indexWhere((w) => w.id == id);
    if (idx >= 0) {
      _words.removeAt(idx);
      return true;
    }
    return false;
  }

  bool updateWord(VocabEntry updated) {
    final idx = _words.indexWhere((w) => w.id == updated.id);
    if (idx >= 0) {
      _words[idx] = updated;
      return true;
    }
    return false;
  }

  VocabEntry? toggleFavorite(String id) {
    final idx = _words.indexWhere((w) => w.id == id);
    if (idx < 0) return null;
    _words[idx] = _words[idx].toggleFavorite();
    return _words[idx];
  }

  /// Search words by term, definition, or tags.
  List<VocabEntry> search(String query) {
    if (query.trim().isEmpty) return words;
    final q = query.toLowerCase();
    return _words.where((w) {
      return w.word.toLowerCase().contains(q) ||
          w.definition.toLowerCase().contains(q) ||
          w.tags.any((t) => t.toLowerCase().contains(q)) ||
          (w.synonyms.any((s) => s.toLowerCase().contains(q)));
    }).toList();
  }

  /// Filter by mastery level.
  List<VocabEntry> byMastery(MasteryLevel level) =>
      _words.where((w) => w.mastery == level).toList();

  /// Filter by part of speech.
  List<VocabEntry> byPartOfSpeech(PartOfSpeech pos) =>
      _words.where((w) => w.partOfSpeech == pos).toList();

  /// Get words due for review (least recently reviewed first, prioritize lower mastery).
  List<VocabEntry> dueForReview({int limit = 10}) {
    final sorted = List<VocabEntry>.from(_words)
      ..sort((a, b) {
        // Prioritize lower mastery
        final mc = a.mastery.index.compareTo(b.mastery.index);
        if (mc != 0) return mc;
        // Then least recently reviewed
        final aTime = a.lastReviewedAt ?? DateTime(2000);
        final bTime = b.lastReviewedAt ?? DateTime(2000);
        return aTime.compareTo(bTime);
      });
    return sorted.take(limit).toList();
  }

  /// Record a quiz answer for a word.
  VocabEntry? recordAnswer(String id, bool correct) {
    final idx = _words.indexWhere((w) => w.id == id);
    if (idx < 0) return null;
    final w = _words[idx];
    final newReviewed = w.timesReviewed + 1;
    final newCorrect = w.timesCorrect + (correct ? 1 : 0);
    final accuracy = newCorrect / newReviewed;

    MasteryLevel newMastery = w.mastery;
    if (accuracy >= 0.9 && newReviewed >= 5) {
      newMastery = MasteryLevel.mastered;
    } else if (accuracy >= 0.7 && newReviewed >= 3) {
      newMastery = MasteryLevel.familiar;
    } else if (newReviewed >= 1) {
      newMastery = MasteryLevel.learning;
    }

    _words[idx] = w.copyWith(
      timesReviewed: newReviewed,
      timesCorrect: newCorrect,
      mastery: newMastery,
      lastReviewedAt: DateTime.now(),
    );
    return _words[idx];
  }

  /// Generate a quiz question (definition → pick the word).
  QuizQuestion? generateQuiz() {
    if (_words.length < 4) return null;
    final reviewPool = dueForReview(limit: _words.length);
    if (reviewPool.isEmpty) return null;
    final target = reviewPool[_random.nextInt(reviewPool.length.clamp(0, 5))];
    final others = _words.where((w) => w.id != target.id).toList()..shuffle();
    final options = [target, ...others.take(3)]..shuffle();
    return QuizQuestion(
      definition: target.definition,
      correctId: target.id,
      options: options.map((w) => QuizOption(id: w.id, word: w.word)).toList(),
    );
  }

  /// Word of the day based on date.
  VocabEntry? wordOfTheDay([DateTime? date]) {
    if (_words.isEmpty) return null;
    final d = date ?? DateTime.now();
    final seed = d.year * 10000 + d.month * 100 + d.day;
    return _words[seed % _words.length];
  }

  /// Get all unique tags.
  List<String> get allTags {
    final set = <String>{};
    for (final w in _words) {
      set.addAll(w.tags);
    }
    return set.toList()..sort();
  }

  /// Mastery breakdown.
  Map<MasteryLevel, int> get masteryBreakdown {
    final map = <MasteryLevel, int>{};
    for (final w in _words) {
      map[w.mastery] = (map[w.mastery] ?? 0) + 1;
    }
    return map;
  }

  /// Overall accuracy across all words.
  double get overallAccuracy {
    final totalReviewed =
        _words.fold<int>(0, (sum, w) => sum + w.timesReviewed);
    final totalCorrect =
        _words.fold<int>(0, (sum, w) => sum + w.timesCorrect);
    return totalReviewed > 0 ? totalCorrect / totalReviewed : 0.0;
  }

  void loadAll(List<VocabEntry> entries) {
    _words.clear();
    _words.addAll(entries);
  }

  static List<VocabEntry> get sampleWords => [
        VocabEntry(
          id: 'sample_v1',
          word: 'Ephemeral',
          definition: 'Lasting for a very short time.',
          partOfSpeech: PartOfSpeech.adjective,
          exampleSentence: 'The ephemeral beauty of cherry blossoms.',
          synonyms: ['transient', 'fleeting', 'momentary'],
          tags: ['gre', 'literary'],
          createdAt: DateTime.now(),
        ),
        VocabEntry(
          id: 'sample_v2',
          word: 'Ubiquitous',
          definition: 'Present, appearing, or found everywhere.',
          partOfSpeech: PartOfSpeech.adjective,
          exampleSentence: 'Smartphones have become ubiquitous.',
          synonyms: ['omnipresent', 'pervasive', 'universal'],
          tags: ['gre', 'academic'],
          createdAt: DateTime.now(),
        ),
        VocabEntry(
          id: 'sample_v3',
          word: 'Pragmatic',
          definition:
              'Dealing with things sensibly and realistically, in a practical way.',
          partOfSpeech: PartOfSpeech.adjective,
          exampleSentence: 'She took a pragmatic approach to problem-solving.',
          synonyms: ['practical', 'realistic', 'sensible'],
          tags: ['gre', 'business'],
          createdAt: DateTime.now(),
        ),
        VocabEntry(
          id: 'sample_v4',
          word: 'Eloquent',
          definition: 'Fluent or persuasive in speaking or writing.',
          partOfSpeech: PartOfSpeech.adjective,
          exampleSentence: 'She gave an eloquent speech at the ceremony.',
          synonyms: ['articulate', 'expressive', 'fluent'],
          tags: ['gre', 'literary'],
          createdAt: DateTime.now(),
        ),
        VocabEntry(
          id: 'sample_v5',
          word: 'Ameliorate',
          definition: 'To make something bad or unsatisfactory better.',
          partOfSpeech: PartOfSpeech.verb,
          exampleSentence:
              'Steps were taken to ameliorate living conditions.',
          synonyms: ['improve', 'enhance', 'mitigate'],
          tags: ['gre', 'formal'],
          createdAt: DateTime.now(),
        ),
      ];
}

/// A quiz question.
class QuizQuestion {
  final String definition;
  final String correctId;
  final List<QuizOption> options;

  const QuizQuestion({
    required this.definition,
    required this.correctId,
    required this.options,
  });
}

/// A quiz answer option.
class QuizOption {
  final String id;
  final String word;

  const QuizOption({required this.id, required this.word});
}
