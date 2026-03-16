import 'dart:math';
import '../models/quote_entry.dart';

/// Service for managing a quote collection with search, filtering,
/// and "quote of the day" functionality.
class QuoteCollectionService {
  final List<QuoteEntry> _quotes = [];
  final Random _random = Random();

  List<QuoteEntry> get quotes => List.unmodifiable(_quotes);

  int get totalQuotes => _quotes.length;

  int get favoriteCount => _quotes.where((q) => q.isFavorite).length;

  /// Add a new quote.
  void addQuote(QuoteEntry quote) {
    _quotes.add(quote);
  }

  /// Remove a quote by id.
  bool removeQuote(String id) {
    final idx = _quotes.indexWhere((q) => q.id == id);
    if (idx >= 0) {
      _quotes.removeAt(idx);
      return true;
    }
    return false;
  }

  /// Update a quote in place.
  bool updateQuote(QuoteEntry updated) {
    final idx = _quotes.indexWhere((q) => q.id == updated.id);
    if (idx >= 0) {
      _quotes[idx] = updated;
      return true;
    }
    return false;
  }

  /// Toggle favorite on a quote.
  QuoteEntry? toggleFavorite(String id) {
    final idx = _quotes.indexWhere((q) => q.id == id);
    if (idx < 0) return null;
    _quotes[idx] = _quotes[idx].toggleFavorite();
    return _quotes[idx];
  }

  /// Get a deterministic "quote of the day" based on the date.
  QuoteEntry? quoteOfTheDay([DateTime? date]) {
    if (_quotes.isEmpty) return null;
    final d = date ?? DateTime.now();
    final seed = d.year * 10000 + d.month * 100 + d.day;
    final index = seed % _quotes.length;
    return _quotes[index];
  }

  /// Random quote.
  QuoteEntry? randomQuote() {
    if (_quotes.isEmpty) return null;
    return _quotes[_random.nextInt(_quotes.length)];
  }

  /// Search quotes by text, author, or tags.
  List<QuoteEntry> search(String query) {
    if (query.trim().isEmpty) return quotes;
    final q = query.toLowerCase();
    return _quotes.where((quote) {
      return quote.text.toLowerCase().contains(q) ||
          (quote.author?.toLowerCase().contains(q) ?? false) ||
          (quote.source?.toLowerCase().contains(q) ?? false) ||
          quote.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  /// Filter by category.
  List<QuoteEntry> byCategory(QuoteCategory category) {
    return _quotes.where((q) => q.category == category).toList();
  }

  /// Get all favorites.
  List<QuoteEntry> get favorites =>
      _quotes.where((q) => q.isFavorite).toList();

  /// Get all unique authors.
  List<String> get authors {
    final set = <String>{};
    for (final q in _quotes) {
      if (q.author != null && q.author!.isNotEmpty) {
        set.add(q.author!);
      }
    }
    return set.toList()..sort();
  }

  /// Get quotes by author.
  List<QuoteEntry> byAuthor(String author) {
    final a = author.toLowerCase();
    return _quotes
        .where((q) => q.author?.toLowerCase() == a)
        .toList();
  }

  /// Get all unique tags.
  List<String> get allTags {
    final set = <String>{};
    for (final q in _quotes) {
      set.addAll(q.tags);
    }
    return set.toList()..sort();
  }

  /// Category breakdown stats.
  Map<QuoteCategory, int> get categoryBreakdown {
    final map = <QuoteCategory, int>{};
    for (final q in _quotes) {
      map[q.category] = (map[q.category] ?? 0) + 1;
    }
    return map;
  }

  /// Longest quote.
  QuoteEntry? get longestQuote {
    if (_quotes.isEmpty) return null;
    return _quotes.reduce((a, b) => a.wordCount > b.wordCount ? a : b);
  }

  /// Shortest quote.
  QuoteEntry? get shortestQuote {
    if (_quotes.isEmpty) return null;
    return _quotes.reduce((a, b) => a.wordCount < b.wordCount ? a : b);
  }

  /// Average word count.
  double get averageWordCount {
    if (_quotes.isEmpty) return 0;
    final total = _quotes.fold<int>(0, (sum, q) => sum + q.wordCount);
    return total / _quotes.length;
  }

  /// Load quotes from saved data.
  void loadAll(List<QuoteEntry> entries) {
    _quotes.clear();
    _quotes.addAll(entries);
  }

  /// Sample quotes for first-time users.
  static List<QuoteEntry> get sampleQuotes => [
        QuoteEntry(
          id: 'sample_1',
          text: 'The only way to do great work is to love what you do.',
          author: 'Steve Jobs',
          category: QuoteCategory.motivation,
          tags: ['work', 'passion'],
          createdAt: DateTime.now(),
        ),
        QuoteEntry(
          id: 'sample_2',
          text: 'In the middle of difficulty lies opportunity.',
          author: 'Albert Einstein',
          category: QuoteCategory.wisdom,
          tags: ['adversity', 'opportunity'],
          createdAt: DateTime.now(),
        ),
        QuoteEntry(
          id: 'sample_3',
          text: 'The unexamined life is not worth living.',
          author: 'Socrates',
          category: QuoteCategory.philosophy,
          tags: ['reflection', 'meaning'],
          createdAt: DateTime.now(),
        ),
        QuoteEntry(
          id: 'sample_4',
          text: 'Imagination is more important than knowledge.',
          author: 'Albert Einstein',
          category: QuoteCategory.creativity,
          tags: ['imagination', 'thinking'],
          createdAt: DateTime.now(),
        ),
        QuoteEntry(
          id: 'sample_5',
          text: 'Be yourself; everyone else is already taken.',
          author: 'Oscar Wilde',
          category: QuoteCategory.humor,
          tags: ['authenticity', 'self'],
          createdAt: DateTime.now(),
        ),
        QuoteEntry(
          id: 'sample_6',
          text: 'The best time to plant a tree was 20 years ago. The second best time is now.',
          author: 'Chinese Proverb',
          category: QuoteCategory.wisdom,
          tags: ['action', 'timing'],
          createdAt: DateTime.now(),
        ),
      ];
}
