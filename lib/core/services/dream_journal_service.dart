import 'dart:convert';
import '../../models/dream_entry.dart';

/// Dream pattern analysis result.
class DreamPattern {
  final String tag;
  final int count;
  final double percentage;

  DreamPattern({
    required this.tag,
    required this.count,
    required this.percentage,
  });
}

/// Dream statistics summary.
class DreamStats {
  final int totalDreams;
  final int lucidCount;
  final int nightmareCount;
  final double avgClarity;
  final Map<DreamType, int> typeBreakdown;
  final Map<WakingMood, int> moodBreakdown;
  final List<DreamPattern> topTags;
  final int currentStreak;
  final int longestStreak;

  DreamStats({
    required this.totalDreams,
    required this.lucidCount,
    required this.nightmareCount,
    required this.avgClarity,
    required this.typeBreakdown,
    required this.moodBreakdown,
    required this.topTags,
    required this.currentStreak,
    required this.longestStreak,
  });
}

/// Service for managing dream journal entries.
class DreamJournalService {
  final List<DreamEntry> _entries = [];

  List<DreamEntry> get entries => List.unmodifiable(_entries);

  void addEntry(DreamEntry entry) {
    _entries.add(entry);
    _entries.sort((a, b) => b.date.compareTo(a.date));
  }

  void updateEntry(String id, DreamEntry updated) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _entries[idx] = updated;
    }
  }

  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
  }

  void toggleFavorite(String id) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _entries[idx] = _entries[idx].copyWith(isFavorite: !_entries[idx].isFavorite);
    }
  }

  List<DreamEntry> get favorites => _entries.where((e) => e.isFavorite).toList();

  List<DreamEntry> searchByTag(String tag) =>
      _entries.where((e) => e.tags.contains(tag)).toList();

  List<DreamEntry> searchByText(String query) {
    final q = query.toLowerCase();
    return _entries
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q))
        .toList();
  }

  List<DreamEntry> filterByType(DreamType type) =>
      _entries.where((e) => e.type == type).toList();

  List<DreamEntry> filterByMood(WakingMood mood) =>
      _entries.where((e) => e.mood == mood).toList();

  Set<String> get allTags =>
      _entries.expand((e) => e.tags).toSet();

  DreamStats getStats() {
    if (_entries.isEmpty) {
      return DreamStats(
        totalDreams: 0,
        lucidCount: 0,
        nightmareCount: 0,
        avgClarity: 0,
        typeBreakdown: {},
        moodBreakdown: {},
        topTags: [],
        currentStreak: 0,
        longestStreak: 0,
      );
    }

    final typeBreakdown = <DreamType, int>{};
    final moodBreakdown = <WakingMood, int>{};
    final tagCounts = <String, int>{};
    double claritySum = 0;

    for (final e in _entries) {
      typeBreakdown[e.type] = (typeBreakdown[e.type] ?? 0) + 1;
      moodBreakdown[e.mood] = (moodBreakdown[e.mood] ?? 0) + 1;
      claritySum += e.clarity;
      for (final t in e.tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }

    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topTags = sortedTags.take(10).map((e) => DreamPattern(
          tag: e.key,
          count: e.value,
          percentage: e.value / _entries.length * 100,
        )).toList();

    // Streak calculation
    final dates = _entries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int currentStreak = 0;
    int longestStreak = 0;
    if (dates.isNotEmpty) {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final diff = todayDate.difference(dates.first).inDays;
      if (diff <= 1) {
        currentStreak = 1;
        for (int i = 1; i < dates.length; i++) {
          if (dates[i - 1].difference(dates[i]).inDays == 1) {
            currentStreak++;
          } else {
            break;
          }
        }
      }

      int streak = 1;
      for (int i = 1; i < dates.length; i++) {
        if (dates[i - 1].difference(dates[i]).inDays == 1) {
          streak++;
        } else {
          if (streak > longestStreak) longestStreak = streak;
          streak = 1;
        }
      }
      if (streak > longestStreak) longestStreak = streak;
    }

    return DreamStats(
      totalDreams: _entries.length,
      lucidCount: typeBreakdown[DreamType.lucid] ?? 0,
      nightmareCount: typeBreakdown[DreamType.nightmare] ?? 0,
      avgClarity: claritySum / _entries.length,
      typeBreakdown: typeBreakdown,
      moodBreakdown: moodBreakdown,
      topTags: topTags,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  String exportToJson() => DreamEntry.encodeList(_entries);

  void importFromJson(String json) {
    _entries.clear();
    _entries.addAll(DreamEntry.decodeList(json));
    _entries.sort((a, b) => b.date.compareTo(a.date));
  }
}
