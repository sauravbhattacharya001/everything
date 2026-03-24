import 'package:flutter/material.dart';
import 'package:everything/core/utils/date_utils.dart';

/// Mastery level for vocabulary words.
enum MasteryLevel {
  newWord('New', '🆕', Colors.grey),
  learning('Learning', '📖', Colors.orange),
  familiar('Familiar', '👍', Colors.blue),
  mastered('Mastered', '⭐', Colors.green);

  final String label;
  final String emoji;
  final Color color;
  const MasteryLevel(this.label, this.emoji, this.color);
}

/// Part of speech.
enum PartOfSpeech {
  noun('Noun'),
  verb('Verb'),
  adjective('Adjective'),
  adverb('Adverb'),
  pronoun('Pronoun'),
  preposition('Preposition'),
  conjunction('Conjunction'),
  interjection('Interjection'),
  other('Other');

  final String label;
  const PartOfSpeech(this.label);
}

/// A single vocabulary entry.
class VocabEntry {
  final String id;
  final String word;
  final String definition;
  final PartOfSpeech partOfSpeech;
  final String? exampleSentence;
  final String? pronunciation;
  final String? origin;
  final List<String> synonyms;
  final List<String> tags;
  final MasteryLevel mastery;
  final int timesReviewed;
  final int timesCorrect;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? lastReviewedAt;
  final String? notes;

  const VocabEntry({
    required this.id,
    required this.word,
    required this.definition,
    required this.partOfSpeech,
    this.exampleSentence,
    this.pronunciation,
    this.origin,
    this.synonyms = const [],
    this.tags = const [],
    this.mastery = MasteryLevel.newWord,
    this.timesReviewed = 0,
    this.timesCorrect = 0,
    this.isFavorite = false,
    required this.createdAt,
    this.lastReviewedAt,
    this.notes,
  });

  double get accuracy =>
      timesReviewed > 0 ? timesCorrect / timesReviewed : 0.0;

  VocabEntry toggleFavorite() => copyWith(isFavorite: !isFavorite);

  VocabEntry copyWith({
    String? word,
    String? definition,
    PartOfSpeech? partOfSpeech,
    String? exampleSentence,
    String? pronunciation,
    String? origin,
    List<String>? synonyms,
    List<String>? tags,
    MasteryLevel? mastery,
    int? timesReviewed,
    int? timesCorrect,
    bool? isFavorite,
    DateTime? lastReviewedAt,
    String? notes,
  }) =>
      VocabEntry(
        id: id,
        word: word ?? this.word,
        definition: definition ?? this.definition,
        partOfSpeech: partOfSpeech ?? this.partOfSpeech,
        exampleSentence: exampleSentence ?? this.exampleSentence,
        pronunciation: pronunciation ?? this.pronunciation,
        origin: origin ?? this.origin,
        synonyms: synonyms ?? this.synonyms,
        tags: tags ?? this.tags,
        mastery: mastery ?? this.mastery,
        timesReviewed: timesReviewed ?? this.timesReviewed,
        timesCorrect: timesCorrect ?? this.timesCorrect,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt,
        lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'definition': definition,
        'partOfSpeech': partOfSpeech.name,
        if (exampleSentence != null) 'exampleSentence': exampleSentence,
        if (pronunciation != null) 'pronunciation': pronunciation,
        if (origin != null) 'origin': origin,
        'synonyms': synonyms,
        'tags': tags,
        'mastery': mastery.name,
        'timesReviewed': timesReviewed,
        'timesCorrect': timesCorrect,
        'isFavorite': isFavorite,
        'createdAt': createdAt.toIso8601String(),
        if (lastReviewedAt != null)
          'lastReviewedAt': lastReviewedAt!.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

  factory VocabEntry.fromJson(Map<String, dynamic> json) => VocabEntry(
        id: json['id'] as String,
        word: json['word'] as String,
        definition: json['definition'] as String,
        partOfSpeech:
            PartOfSpeech.values.byName(json['partOfSpeech'] as String),
        exampleSentence: json['exampleSentence'] as String?,
        pronunciation: json['pronunciation'] as String?,
        origin: json['origin'] as String?,
        synonyms: (json['synonyms'] as List<dynamic>?)
                ?.map((s) => s as String)
                .toList() ??
            const [],
        tags: (json['tags'] as List<dynamic>?)
                ?.map((t) => t as String)
                .toList() ??
            const [],
        mastery: MasteryLevel.values.byName(json['mastery'] as String),
        timesReviewed: json['timesReviewed'] as int? ?? 0,
        timesCorrect: json['timesCorrect'] as int? ?? 0,
        isFavorite: json['isFavorite'] as bool? ?? false,
        createdAt: AppDateUtils.safeParse(json['createdAt'] as String?),
        lastReviewedAt: json['lastReviewedAt'] != null
            ? DateTime.tryParse(json['lastReviewedAt'] as String)
            : null,
        notes: json['notes'] as String?,
      );
}
