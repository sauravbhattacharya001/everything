/// Random Decision Maker Service — create lists of options, spin to decide,
/// track decision history, and manage weighted randomness.
///
/// Features:
/// - Create named decision lists with options
/// - Weighted random selection (assign weights to options)
/// - Decision history per list
/// - Preset templates (where to eat, movie night, etc.)

import 'dart:math';
import '../../models/decision_list.dart';

class RandomDecisionService {
  final List<DecisionList> _lists = [];
  final Random _random = Random();

  List<DecisionList> get lists => List.unmodifiable(_lists);

  /// Creates a new decision list.
  DecisionList createList({
    required String title,
    String? emoji,
    List<String> options = const [],
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final list = DecisionList(
      id: id,
      title: title,
      emoji: emoji,
      options: options
          .map((text) => DecisionOption(
                id: '${id}_${options.indexOf(text)}',
                text: text,
              ))
          .toList(),
      createdAt: DateTime.now(),
    );
    _lists.add(list);
    return list;
  }

  /// Removes a decision list by id.
  void deleteList(String listId) {
    _lists.removeWhere((l) => l.id == listId);
  }

  /// Adds an option to a list.
  void addOption(String listId, String text, {String? emoji, int weight = 1}) {
    final idx = _lists.indexWhere((l) => l.id == listId);
    if (idx == -1) return;
    final list = _lists[idx];
    final option = DecisionOption(
      id: '${listId}_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      emoji: emoji,
      weight: weight,
    );
    _lists[idx] = list.copyWith(options: [...list.options, option]);
  }

  /// Removes an option from a list.
  void removeOption(String listId, String optionId) {
    final idx = _lists.indexWhere((l) => l.id == listId);
    if (idx == -1) return;
    final list = _lists[idx];
    _lists[idx] = list.copyWith(
      options: list.options.where((o) => o.id != optionId).toList(),
    );
  }

  /// Updates an option's text, emoji, or weight.
  void updateOption(String listId, String optionId,
      {String? text, String? emoji, int? weight}) {
    final idx = _lists.indexWhere((l) => l.id == listId);
    if (idx == -1) return;
    final list = _lists[idx];
    _lists[idx] = list.copyWith(
      options: list.options.map((o) {
        if (o.id != optionId) return o;
        return o.copyWith(text: text, emoji: emoji, weight: weight);
      }).toList(),
    );
  }

  /// Spin! Returns a weighted-random option from the list.
  DecisionResult? spin(String listId) {
    final idx = _lists.indexWhere((l) => l.id == listId);
    if (idx == -1) return null;
    final list = _lists[idx];
    if (list.options.isEmpty) return null;

    // Weighted selection
    final totalWeight = list.options.fold<int>(0, (sum, o) => sum + o.weight);
    var roll = _random.nextInt(totalWeight);
    DecisionOption? chosen;
    for (final option in list.options) {
      roll -= option.weight;
      if (roll < 0) {
        chosen = option;
        break;
      }
    }
    chosen ??= list.options.last;

    final result = DecisionResult(
      optionId: chosen.id,
      optionText: chosen.text,
      decidedAt: DateTime.now(),
    );

    _lists[idx] = list.copyWith(
      history: [result, ...list.history],
    );

    return result;
  }

  /// Gets decision history for a list.
  List<DecisionResult> getHistory(String listId) {
    final list = _lists.where((l) => l.id == listId).firstOrNull;
    return list?.history ?? [];
  }

  /// Clears decision history for a list.
  void clearHistory(String listId) {
    final idx = _lists.indexWhere((l) => l.id == listId);
    if (idx == -1) return;
    _lists[idx] = _lists[idx].copyWith(history: []);
  }

  /// Get frequency stats for a list's decisions.
  Map<String, int> getFrequencyStats(String listId) {
    final list = _lists.where((l) => l.id == listId).firstOrNull;
    if (list == null) return {};
    final stats = <String, int>{};
    for (final result in list.history) {
      stats[result.optionText] = (stats[result.optionText] ?? 0) + 1;
    }
    return stats;
  }

  /// Preset templates users can quickly load.
  static final Map<String, List<String>> templates = {
    '🍽️ Where to Eat': [
      'Chinese',
      'Italian',
      'Mexican',
      'Thai',
      'Indian',
      'Sushi',
      'Pizza',
      'Burgers',
    ],
    '🎬 Movie Night': [
      'Action',
      'Comedy',
      'Drama',
      'Horror',
      'Sci-Fi',
      'Romance',
      'Documentary',
      'Animation',
    ],
    '🏋️ Workout': [
      'Running',
      'Yoga',
      'Weight Training',
      'Swimming',
      'Cycling',
      'HIIT',
      'Pilates',
      'Dance',
    ],
    '🎲 Team Activity': [
      'Board Game Night',
      'Movie Marathon',
      'Cooking Together',
      'Trivia Night',
      'Video Games',
      'Karaoke',
      'Escape Room',
      'Bowling',
    ],
    '📚 What to Read': [
      'Fiction',
      'Non-Fiction',
      'Sci-Fi',
      'Mystery',
      'Biography',
      'Self-Help',
      'History',
      'Fantasy',
    ],
  };

  /// Creates a list from a preset template.
  DecisionList createFromTemplate(String templateName) {
    final options = templates[templateName] ?? [];
    return createList(
      title: templateName,
      emoji: templateName.characters.first,
      options: options,
    );
  }
}
