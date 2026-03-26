import 'dart:math';

/// A single affirmation entry.
class Affirmation {
  final String text;
  final String category;
  final bool isFavorite;
  final DateTime? shownAt;

  Affirmation({
    required this.text,
    required this.category,
    this.isFavorite = false,
    this.shownAt,
  });

  Affirmation copyWith({bool? isFavorite, DateTime? shownAt}) {
    return Affirmation(
      text: text,
      category: category,
      isFavorite: isFavorite ?? this.isFavorite,
      shownAt: shownAt ?? this.shownAt,
    );
  }
}

/// Service that manages daily affirmations.
class AffirmationService {
  static const List<Map<String, String>> _builtInAffirmations = [
    {'text': 'I am capable of achieving great things.', 'category': 'Confidence'},
    {'text': 'I choose to be happy and grateful today.', 'category': 'Gratitude'},
    {'text': 'I am worthy of love and respect.', 'category': 'Self-Worth'},
    {'text': 'I trust the process and embrace the journey.', 'category': 'Growth'},
    {'text': 'I release all negativity and welcome positivity.', 'category': 'Positivity'},
    {'text': 'My potential is limitless.', 'category': 'Confidence'},
    {'text': 'I am grateful for this moment.', 'category': 'Gratitude'},
    {'text': 'I forgive myself and let go of the past.', 'category': 'Self-Worth'},
    {'text': 'Every challenge is an opportunity to grow.', 'category': 'Growth'},
    {'text': 'I radiate positive energy to those around me.', 'category': 'Positivity'},
    {'text': 'I am strong, resilient, and brave.', 'category': 'Confidence'},
    {'text': 'I appreciate the abundance in my life.', 'category': 'Gratitude'},
    {'text': 'I deserve success and happiness.', 'category': 'Self-Worth'},
    {'text': 'I learn from my mistakes and keep moving forward.', 'category': 'Growth'},
    {'text': 'Today is full of possibilities.', 'category': 'Positivity'},
    {'text': 'I believe in my abilities and talents.', 'category': 'Confidence'},
    {'text': 'I am thankful for the people in my life.', 'category': 'Gratitude'},
    {'text': 'I am enough, just as I am.', 'category': 'Self-Worth'},
    {'text': 'I embrace change as a path to growth.', 'category': 'Growth'},
    {'text': 'I choose peace over worry.', 'category': 'Positivity'},
    {'text': 'I have the power to create change.', 'category': 'Confidence'},
    {'text': 'I am surrounded by beauty and wonder.', 'category': 'Gratitude'},
    {'text': 'My voice matters and my feelings are valid.', 'category': 'Self-Worth'},
    {'text': 'I am becoming the best version of myself.', 'category': 'Growth'},
    {'text': 'I attract good things into my life.', 'category': 'Positivity'},
    {'text': 'I face today with courage and confidence.', 'category': 'Confidence'},
    {'text': 'I am grateful for the lessons life teaches me.', 'category': 'Gratitude'},
    {'text': 'I honor my boundaries and my needs.', 'category': 'Self-Worth'},
    {'text': 'Every day I grow stronger and wiser.', 'category': 'Growth'},
    {'text': 'I bring joy and light wherever I go.', 'category': 'Positivity'},
  ];

  final List<Affirmation> _all = [];
  final List<Affirmation> _favorites = [];
  final List<Affirmation> _history = [];
  final List<Affirmation> _custom = [];
  final _random = Random();

  AffirmationService() {
    _all.addAll(_builtInAffirmations.map((m) => Affirmation(
      text: m['text']!,
      category: m['category']!,
    )));
  }

  List<String> get categories =>
      _all.map((a) => a.category).toSet().toList()..sort();

  List<Affirmation> get favorites => List.unmodifiable(_favorites);
  List<Affirmation> get history => List.unmodifiable(_history);
  List<Affirmation> get custom => List.unmodifiable(_custom);

  /// Get today's affirmation (deterministic per day).
  Affirmation getTodaysAffirmation() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final index = Random(seed).nextInt(_all.length);
    final affirmation = _all[index].copyWith(shownAt: now);
    if (!_history.any((h) => h.text == affirmation.text &&
        h.shownAt?.day == now.day &&
        h.shownAt?.month == now.month &&
        h.shownAt?.year == now.year)) {
      _history.insert(0, affirmation);
    }
    return affirmation;
  }

  /// Get a random affirmation, optionally filtered by category.
  Affirmation getRandomAffirmation({String? category}) {
    var pool = category != null
        ? _all.where((a) => a.category == category).toList()
        : _all;
    if (pool.isEmpty) pool = _all;
    final affirmation = pool[_random.nextInt(pool.length)]
        .copyWith(shownAt: DateTime.now());
    _history.insert(0, affirmation);
    return affirmation;
  }

  /// Get affirmations by category.
  List<Affirmation> getByCategory(String category) =>
      _all.where((a) => a.category == category).toList();

  /// Toggle favorite status.
  void toggleFavorite(Affirmation affirmation) {
    final existing = _favorites.indexWhere((f) => f.text == affirmation.text);
    if (existing >= 0) {
      _favorites.removeAt(existing);
    } else {
      _favorites.add(affirmation.copyWith(isFavorite: true));
    }
  }

  bool isFavorite(Affirmation affirmation) =>
      _favorites.any((f) => f.text == affirmation.text);

  /// Add a custom affirmation.
  void addCustom(String text, String category) {
    final affirmation = Affirmation(text: text, category: category);
    _custom.add(affirmation);
    _all.add(affirmation);
  }

  /// Remove a custom affirmation.
  void removeCustom(Affirmation affirmation) {
    _custom.removeWhere((a) => a.text == affirmation.text);
    _all.removeWhere((a) => a.text == affirmation.text);
  }

  /// Clear history.
  void clearHistory() => _history.clear();
}
