import 'dart:convert';
import 'dart:math';
import '../../models/gratitude_entry.dart';

/// Daily gratitude summary.
class DailyGratitudeSummary {
  final DateTime date;
  final int entryCount;
  final double averageIntensity;
  final Map<GratitudeCategory, int> categoryBreakdown;
  final List<String> topTags;
  final int favoriteCount;

  DailyGratitudeSummary({
    required this.date,
    required this.entryCount,
    required this.averageIntensity,
    required this.categoryBreakdown,
    required this.topTags,
    required this.favoriteCount,
  });
}

/// Streak information for gratitude journaling.
class GratitudeStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastEntryDate;

  GratitudeStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastEntryDate,
  });
}

/// Weekly gratitude report.
class WeeklyGratitudeReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalEntries;
  final double averageIntensity;
  final double entriesPerDay;
  final Map<GratitudeCategory, int> categoryBreakdown;
  final List<String> topTags;
  final int favoriteCount;
  final String grade;

  WeeklyGratitudeReport({
    required this.weekStart,
    required this.weekEnd,
    required this.totalEntries,
    required this.averageIntensity,
    required this.entriesPerDay,
    required this.categoryBreakdown,
    required this.topTags,
    required this.favoriteCount,
    required this.grade,
  });
}

/// Gratitude insights from analysis.
class GratitudeInsight {
  final String type;
  final String message;

  GratitudeInsight({required this.type, required this.message});
}

/// Full gratitude report.
class GratitudeReport {
  final int totalEntries;
  final GratitudeStreak streak;
  final Map<GratitudeCategory, int> categoryBreakdown;
  final Map<String, int> tagFrequency;
  final double averageIntensity;
  final double averageEntriesPerDay;
  final int favoriteCount;
  final List<GratitudeInsight> insights;
  final String textSummary;

  GratitudeReport({
    required this.totalEntries,
    required this.streak,
    required this.categoryBreakdown,
    required this.tagFrequency,
    required this.averageIntensity,
    required this.averageEntriesPerDay,
    required this.favoriteCount,
    required this.insights,
    required this.textSummary,
  });
}

/// Gratitude Journal Service — tracks daily gratitude entries with categories,
/// intensity, tags, favorites, streaks, weekly reports, insights, and prompts.
class GratitudeJournalService {
  final List<GratitudeEntry> _entries = [];
  int _idCounter = 0;

  // --- CRUD ---

  String addEntry({
    required String text,
    DateTime? timestamp,
    GratitudeCategory category = GratitudeCategory.general,
    GratitudeIntensity intensity = GratitudeIntensity.moderate,
    List<String> tags = const [],
    String? note,
  }) {
    if (text.trim().isEmpty) throw ArgumentError('Text cannot be empty');
    final id = 'grat_${++_idCounter}';
    _entries.add(GratitudeEntry(
      id: id,
      timestamp: timestamp ?? DateTime.now(),
      text: text.trim(),
      category: category,
      intensity: intensity,
      tags: List.from(tags),
      note: note?.trim(),
    ));
    return id;
  }

  GratitudeEntry? getEntry(String id) {
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  bool updateEntry(String id, {
    String? text,
    GratitudeCategory? category,
    GratitudeIntensity? intensity,
    List<String>? tags,
    String? note,
  }) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx == -1) return false;
    _entries[idx] = _entries[idx].copyWith(
      text: text,
      category: category,
      intensity: intensity,
      tags: tags,
      note: note,
    );
    return true;
  }

  bool deleteEntry(String id) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx == -1) return false;
    _entries.removeAt(idx);
    return true;
  }

  bool toggleFavorite(String id) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx == -1) return false;
    _entries[idx] = _entries[idx].copyWith(isFavorite: !_entries[idx].isFavorite);
    return true;
  }

  List<GratitudeEntry> get allEntries => List.unmodifiable(_entries);

  int get entryCount => _entries.length;

  // --- Filtering ---

  List<GratitudeEntry> getEntriesForDate(DateTime date) {
    return _entries.where((e) =>
        e.timestamp.year == date.year &&
        e.timestamp.month == date.month &&
        e.timestamp.day == date.day).toList();
  }

  List<GratitudeEntry> getEntriesInRange(DateTime start, DateTime end) {
    return _entries.where((e) =>
        !e.timestamp.isBefore(start) && !e.timestamp.isAfter(end)).toList();
  }

  List<GratitudeEntry> getEntriesByCategory(GratitudeCategory category) {
    return _entries.where((e) => e.category == category).toList();
  }

  List<GratitudeEntry> getEntriesByTag(String tag) {
    final lower = tag.toLowerCase();
    return _entries.where((e) =>
        e.tags.any((t) => t.toLowerCase() == lower)).toList();
  }

  List<GratitudeEntry> getFavorites() {
    return _entries.where((e) => e.isFavorite).toList();
  }

  List<GratitudeEntry> search(String query) {
    final lower = query.toLowerCase();
    return _entries.where((e) =>
        e.text.toLowerCase().contains(lower) ||
        (e.note?.toLowerCase().contains(lower) ?? false) ||
        e.tags.any((t) => t.toLowerCase().contains(lower))).toList();
  }

  // --- Daily Summary ---

  DailyGratitudeSummary getDailySummary(DateTime date) {
    final dayEntries = getEntriesForDate(date);
    final avgIntensity = dayEntries.isEmpty
        ? 0.0
        : dayEntries.map((e) => e.intensity.value).reduce((a, b) => a + b) /
            dayEntries.length;
    final catBreakdown = <GratitudeCategory, int>{};
    final tagCount = <String, int>{};
    int favCount = 0;
    for (final e in dayEntries) {
      catBreakdown[e.category] = (catBreakdown[e.category] ?? 0) + 1;
      for (final t in e.tags) {
        tagCount[t] = (tagCount[t] ?? 0) + 1;
      }
      if (e.isFavorite) favCount++;
    }
    final sortedTags = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DailyGratitudeSummary(
      date: date,
      entryCount: dayEntries.length,
      averageIntensity: avgIntensity,
      categoryBreakdown: catBreakdown,
      topTags: sortedTags.take(5).map((e) => e.key).toList(),
      favoriteCount: favCount,
    );
  }

  // --- Streaks ---

  GratitudeStreak getStreak({DateTime? today}) {
    if (_entries.isEmpty) {
      return GratitudeStreak(currentStreak: 0, longestStreak: 0);
    }
    final now = today ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    // Get unique dates with entries
    final dates = <DateTime>{};
    for (final e in _entries) {
      dates.add(DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day));
    }
    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));

    // Current streak
    int current = 0;
    var checkDate = todayDate;
    // Allow today or yesterday as start
    if (dates.contains(checkDate)) {
      current = 1;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (dates.contains(checkDate)) {
        current = 1;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }
    if (current > 0) {
      while (dates.contains(checkDate)) {
        current++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    // Longest streak
    int longest = 0;
    int streak = 1;
    for (int i = 0; i < sorted.length - 1; i++) {
      final diff = sorted[i].difference(sorted[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        if (streak > longest) longest = streak;
        streak = 1;
      }
    }
    if (streak > longest) longest = streak;

    return GratitudeStreak(
      currentStreak: current,
      longestStreak: longest,
      lastEntryDate: sorted.first,
    );
  }

  // --- Weekly Report ---

  WeeklyGratitudeReport getWeeklyReport(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    final entries = getEntriesInRange(weekStart, weekEnd);
    final avgInt = entries.isEmpty
        ? 0.0
        : entries.map((e) => e.intensity.value).reduce((a, b) => a + b) /
            entries.length;
    final catBreakdown = <GratitudeCategory, int>{};
    final tagCount = <String, int>{};
    int favCount = 0;
    for (final e in entries) {
      catBreakdown[e.category] = (catBreakdown[e.category] ?? 0) + 1;
      for (final t in e.tags) {
        tagCount[t] = (tagCount[t] ?? 0) + 1;
      }
      if (e.isFavorite) favCount++;
    }
    final sortedTags = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final epd = entries.length / 7.0;

    String grade;
    if (epd >= 3) {
      grade = 'A';
    } else if (epd >= 2) {
      grade = 'B';
    } else if (epd >= 1) {
      grade = 'C';
    } else if (epd > 0) {
      grade = 'D';
    } else {
      grade = 'F';
    }

    return WeeklyGratitudeReport(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalEntries: entries.length,
      averageIntensity: avgInt,
      entriesPerDay: epd,
      categoryBreakdown: catBreakdown,
      topTags: sortedTags.take(5).map((e) => e.key).toList(),
      favoriteCount: favCount,
      grade: grade,
    );
  }

  // --- Insights ---

  List<GratitudeInsight> getInsights() {
    final insights = <GratitudeInsight>[];
    if (_entries.isEmpty) {
      insights.add(GratitudeInsight(
        type: 'start',
        message: 'Start your gratitude journey by adding your first entry!',
      ));
      return insights;
    }

    // Category diversity
    final cats = <GratitudeCategory>{};
    for (final e in _entries) {
      cats.add(e.category);
    }
    if (cats.length >= 5) {
      insights.add(GratitudeInsight(
        type: 'diversity',
        message: 'Great diversity! You appreciate things across ${cats.length} categories.',
      ));
    } else if (cats.length <= 2 && _entries.length > 5) {
      insights.add(GratitudeInsight(
        type: 'diversity',
        message: 'Try branching out — most of your entries are in just ${cats.length} category(ies).',
      ));
    }

    // Top category
    final catCount = <GratitudeCategory, int>{};
    for (final e in _entries) {
      catCount[e.category] = (catCount[e.category] ?? 0) + 1;
    }
    final topCat = catCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (topCat.isNotEmpty) {
      insights.add(GratitudeInsight(
        type: 'topCategory',
        message: 'You\'re most grateful for ${topCat.first.key.label} '
            '(${topCat.first.value} entries).',
      ));
    }

    // Intensity trend
    final avgInt = _entries.map((e) => e.intensity.value).reduce((a, b) => a + b) /
        _entries.length;
    if (avgInt >= 4.0) {
      insights.add(GratitudeInsight(
        type: 'intensity',
        message: 'Your gratitude runs deep — average intensity is ${avgInt.toStringAsFixed(1)}/5!',
      ));
    }

    // Streak
    final streak = getStreak();
    if (streak.currentStreak >= 7) {
      insights.add(GratitudeInsight(
        type: 'streak',
        message: 'Amazing ${streak.currentStreak}-day streak! Keep it going!',
      ));
    } else if (streak.currentStreak >= 3) {
      insights.add(GratitudeInsight(
        type: 'streak',
        message: '${streak.currentStreak}-day streak — building a great habit!',
      ));
    }

    // Favorites ratio
    final favRatio = _entries.where((e) => e.isFavorite).length / _entries.length;
    if (favRatio > 0.3) {
      insights.add(GratitudeInsight(
        type: 'favorites',
        message: 'You\'ve starred ${(favRatio * 100).toStringAsFixed(0)}% of entries — lots of special moments!',
      ));
    }

    return insights;
  }

  // --- Prompts ---

  static const List<String> _prompts = [
    'What made you smile today?',
    'Who helped you recently?',
    'What\'s a simple pleasure you enjoyed today?',
    'What skill or ability are you grateful for?',
    'What challenge taught you something valuable?',
    'What about your home are you thankful for?',
    'What technology makes your life easier?',
    'What natural beauty did you notice recently?',
    'Who in your life do you often take for granted?',
    'What opportunity came your way recently?',
    'What\'s a memory that makes you feel warm?',
    'What part of your daily routine do you enjoy?',
    'What did you learn recently that excited you?',
    'What food or meal are you grateful for?',
    'What freedom do you have that others don\'t?',
    'What about your health are you thankful for?',
    'What book, show, or music enriched your life?',
    'What act of kindness did you witness or receive?',
    'What mistake led to something good?',
    'What are you looking forward to?',
  ];

  /// Get a random gratitude prompt.
  String getRandomPrompt({Random? random}) {
    final r = random ?? Random();
    return _prompts[r.nextInt(_prompts.length)];
  }

  /// Get the prompt for a specific index (wraps around).
  String getPrompt(int index) {
    return _prompts[index % _prompts.length];
  }

  int get promptCount => _prompts.length;

  // --- Full Report ---

  GratitudeReport getReport({DateTime? today}) {
    final streak = getStreak(today: today);
    final catBreakdown = <GratitudeCategory, int>{};
    final tagFreq = <String, int>{};
    int favCount = 0;
    double totalInt = 0;
    for (final e in _entries) {
      catBreakdown[e.category] = (catBreakdown[e.category] ?? 0) + 1;
      for (final t in e.tags) {
        tagFreq[t] = (tagFreq[t] ?? 0) + 1;
      }
      if (e.isFavorite) favCount++;
      totalInt += e.intensity.value;
    }
    final avgInt = _entries.isEmpty ? 0.0 : totalInt / _entries.length;

    // Average entries per day
    double avgEpd = 0;
    if (_entries.length >= 2) {
      final sorted = _entries.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final span = sorted.last.timestamp.difference(sorted.first.timestamp).inDays + 1;
      avgEpd = _entries.length / span;
    } else if (_entries.length == 1) {
      avgEpd = 1.0;
    }

    final insights = getInsights();

    // Text summary
    final buf = StringBuffer();
    buf.writeln('=== Gratitude Journal Report ===');
    buf.writeln('Total entries: ${_entries.length}');
    buf.writeln('Favorites: $favCount');
    buf.writeln('Average intensity: ${avgInt.toStringAsFixed(1)}/5');
    buf.writeln('Average entries/day: ${avgEpd.toStringAsFixed(1)}');
    buf.writeln('Current streak: ${streak.currentStreak} days');
    buf.writeln('Longest streak: ${streak.longestStreak} days');
    if (catBreakdown.isNotEmpty) {
      buf.writeln('\nCategories:');
      final sortedCats = catBreakdown.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final c in sortedCats) {
        buf.writeln('  ${c.key.emoji} ${c.key.label}: ${c.value}');
      }
    }
    if (tagFreq.isNotEmpty) {
      buf.writeln('\nTop tags:');
      final sortedTags = tagFreq.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final t in sortedTags.take(10)) {
        buf.writeln('  #${t.key}: ${t.value}');
      }
    }
    if (insights.isNotEmpty) {
      buf.writeln('\nInsights:');
      for (final i in insights) {
        buf.writeln('  💡 ${i.message}');
      }
    }

    return GratitudeReport(
      totalEntries: _entries.length,
      streak: streak,
      categoryBreakdown: catBreakdown,
      tagFrequency: tagFreq,
      averageIntensity: avgInt,
      averageEntriesPerDay: avgEpd,
      favoriteCount: favCount,
      insights: insights,
      textSummary: buf.toString(),
    );
  }

  // --- Persistence ---

  String exportToJson() {
    return jsonEncode(_entries.map((e) => e.toJson()).toList());
  }

  void importFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _entries.clear();
    _idCounter = 0;
    for (final item in list) {
      final entry = GratitudeEntry.fromJson(item as Map<String, dynamic>);
      _entries.add(entry);
      // Keep id counter in sync
      final numPart = entry.id.replaceAll(RegExp(r'[^0-9]'), '');
      final num = int.tryParse(numPart) ?? 0;
      if (num > _idCounter) _idCounter = num;
    }
  }
}
