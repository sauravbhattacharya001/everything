import 'dart:convert';
import '../../models/journal_entry.dart';
import '../utils/date_streak_calculator.dart';

/// Service for managing daily journal / diary entries.
class DailyJournalService {
  final List<JournalEntry> _entries = [];

  List<JournalEntry> get entries => List.unmodifiable(_entries);

  int get totalEntries => _entries.length;

  int get totalWords => _entries.fold(0, (sum, e) => sum + e.wordCount);

  int get favoriteCount => _entries.where((e) => e.isFavorite).length;

  /// Current writing streak (consecutive days ending today or yesterday).
  int get currentStreak =>
      DateStreakCalculator.compute(_entries.map((e) => e.date)).current;

  /// Longest writing streak ever.
  int get longestStreak =>
      DateStreakCalculator.compute(_entries.map((e) => e.date)).longest;

  void addEntry(JournalEntry entry) {
    _entries.add(entry);
    _entries.sort((a, b) => b.date.compareTo(a.date));
  }

  bool removeEntry(String id) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _entries.removeAt(idx);
      return true;
    }
    return false;
  }

  bool updateEntry(JournalEntry updated) {
    final idx = _entries.indexWhere((e) => e.id == updated.id);
    if (idx >= 0) {
      _entries[idx] = updated;
      return true;
    }
    return false;
  }

  JournalEntry? toggleFavorite(String id) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx < 0) return null;
    _entries[idx] = _entries[idx].copyWith(isFavorite: !_entries[idx].isFavorite);
    return _entries[idx];
  }

  /// Get the entry for a specific date (if any).
  JournalEntry? entryForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    try {
      return _entries.firstWhere(
        (e) => DateTime(e.date.year, e.date.month, e.date.day) == target,
      );
    } catch (_) {
      return null;
    }
  }

  /// Search entries by keyword in title or body.
  List<JournalEntry> search(String query) {
    final q = query.toLowerCase();
    return _entries
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.body.toLowerCase().contains(q))
        .toList();
  }

  /// Get entries filtered by mood.
  List<JournalEntry> byMood(JournalMood mood) {
    return _entries.where((e) => e.mood == mood).toList();
  }

  /// Get entries filtered by tag.
  List<JournalEntry> byTag(String tag) {
    return _entries.where((e) => e.tags.contains(tag)).toList();
  }

  /// Get all unique tags across entries.
  Set<String> get allTags {
    final tags = <String>{};
    for (final e in _entries) {
      tags.addAll(e.tags);
    }
    return tags;
  }

  /// Get favorites only.
  List<JournalEntry> get favorites =>
      _entries.where((e) => e.isFavorite).toList();

  /// Entries for a given month.
  List<JournalEntry> forMonth(int year, int month) {
    return _entries
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
  }

  /// "On this day" — entries from previous years on the same month/day.
  List<JournalEntry> onThisDay([DateTime? date]) {
    final d = date ?? DateTime.now();
    return _entries
        .where((e) =>
            e.date.month == d.month &&
            e.date.day == d.day &&
            e.date.year != d.year)
        .toList();
  }

  /// Average word count per entry.
  double get averageWordCount {
    if (_entries.isEmpty) return 0;
    return totalWords / _entries.length;
  }

  /// Export all entries as a JSON list string.
  String exportJson() {
    return '[${_entries.map((e) => e.toJsonString()).join(',')}]';
  }

  /// Import entries from JSON list string.
  void importJson(String json) {
    final list = (jsonDecode(json) as List<dynamic>)
        .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final entry in list) {
      if (!_entries.any((e) => e.id == entry.id)) {
        _entries.add(entry);
      }
    }
    _entries.sort((a, b) => b.date.compareTo(a.date));
  }
}
