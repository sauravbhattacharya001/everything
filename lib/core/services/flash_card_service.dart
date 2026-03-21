import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// A single flash card with question and answer.
class FlashCard {
  final String id;
  String question;
  String answer;
  int repetitions; // SM-2 reps
  double easeFactor; // SM-2 ease factor
  int intervalDays; // SM-2 interval
  DateTime? nextReview;
  DateTime createdAt;

  FlashCard({
    required this.id,
    required this.question,
    required this.answer,
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.nextReview,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isDue =>
      nextReview == null ||
      nextReview!.isBefore(DateTime.now().add(const Duration(hours: 1)));

  /// SM-2 algorithm: update card based on quality (0-5).
  void review(int quality) {
    assert(quality >= 0 && quality <= 5);
    if (quality >= 3) {
      if (repetitions == 0) {
        intervalDays = 1;
      } else if (repetitions == 1) {
        intervalDays = 6;
      } else {
        intervalDays = (intervalDays * easeFactor).round();
      }
      repetitions++;
    } else {
      repetitions = 0;
      intervalDays = 1;
    }
    easeFactor =
        (easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
            .clamp(1.3, 2.5);
    nextReview = DateTime.now().add(Duration(days: intervalDays));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'repetitions': repetitions,
        'easeFactor': easeFactor,
        'intervalDays': intervalDays,
        'nextReview': nextReview?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory FlashCard.fromJson(Map<String, dynamic> j) => FlashCard(
        id: j['id'] as String,
        question: j['question'] as String,
        answer: j['answer'] as String,
        repetitions: j['repetitions'] as int? ?? 0,
        easeFactor: (j['easeFactor'] as num?)?.toDouble() ?? 2.5,
        intervalDays: j['intervalDays'] as int? ?? 1,
        nextReview: j['nextReview'] != null
            ? DateTime.parse(j['nextReview'] as String)
            : null,
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
      );
}

/// A deck of flash cards.
class FlashDeck {
  final String id;
  String name;
  String? description;
  IconLabel icon;
  List<FlashCard> cards;
  DateTime createdAt;

  FlashDeck({
    required this.id,
    required this.name,
    this.description,
    this.icon = IconLabel.book,
    List<FlashCard>? cards,
    DateTime? createdAt,
  })  : cards = cards ?? [],
        createdAt = createdAt ?? DateTime.now();

  int get dueCount => cards.where((c) => c.isDue).length;
  int get masteredCount => cards.where((c) => c.repetitions >= 3).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon.name,
        'cards': cards.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory FlashDeck.fromJson(Map<String, dynamic> j) => FlashDeck(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        icon: IconLabel.values.firstWhere(
          (e) => e.name == j['icon'],
          orElse: () => IconLabel.book,
        ),
        cards: (j['cards'] as List?)
                ?.map((c) => FlashCard.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
      );
}

/// Icon options for decks.
enum IconLabel {
  book,
  science,
  language,
  code,
  music,
  math,
  history,
  art,
}

/// Service for managing flash card decks with persistence via JSON strings.
class FlashCardService {
  FlashCardService._();

  static String _uid() =>
      '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

  /// Create a new deck.
  static FlashDeck createDeck(String name, {String? description, IconLabel icon = IconLabel.book}) {
    return FlashDeck(id: _uid(), name: name, description: description, icon: icon);
  }

  /// Add a card to a deck.
  static FlashCard addCard(FlashDeck deck, String question, String answer) {
    final card = FlashCard(id: _uid(), question: question, answer: answer);
    deck.cards.add(card);
    return card;
  }

  /// Get due cards for study, shuffled.
  static List<FlashCard> getDueCards(FlashDeck deck) {
    final due = deck.cards.where((c) => c.isDue).toList()..shuffle();
    return due;
  }

  /// Serialize all decks to JSON string.
  static String encodeDecks(List<FlashDeck> decks) =>
      jsonEncode(decks.map((d) => d.toJson()).toList());

  /// Deserialize decks from JSON string.
  static List<FlashDeck> decodeDecks(String json) {
    final list = jsonDecode(json) as List;
    return list.map((d) => FlashDeck.fromJson(d as Map<String, dynamic>)).toList();
  }

  /// Get study statistics for a deck.
  static Map<String, dynamic> getStats(FlashDeck deck) {
    final total = deck.cards.length;
    final due = deck.dueCount;
    final mastered = deck.masteredCount;
    final learning = total - mastered;
    return {
      'total': total,
      'due': due,
      'mastered': mastered,
      'learning': learning,
      'masteryPercent': total > 0 ? (mastered / total * 100).round() : 0,
    };
  }
}
