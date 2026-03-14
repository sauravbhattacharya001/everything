import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/mood_entry.dart';

/// Service for managing mood journal entries with local persistence.
class MoodJournalService {
  static const String _storageKey = 'mood_journal_entries';
  List<MoodEntry> _entries = [];
  bool _initialized = false;

  List<MoodEntry> get entries => List.unmodifiable(_entries);

  /// Load entries from local storage.
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null && data.isNotEmpty) {
      _entries = MoodEntry.decodeList(data);
    }
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _initialized = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, MoodEntry.encodeList(_entries));
  }

  /// Add a new mood entry.
  Future<void> addEntry(MoodEntry entry) async {
    await init();
    _entries.insert(0, entry);
    await _save();
  }

  /// Delete an entry by id.
  Future<void> deleteEntry(String id) async {
    await init();
    _entries.removeWhere((e) => e.id == id);
    await _save();
  }

  /// Update an existing entry.
  Future<void> updateEntry(MoodEntry entry) async {
    await init();
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      _entries[idx] = entry;
      await _save();
    }
  }

  /// Get entries for a specific date.
  List<MoodEntry> entriesForDate(DateTime date) {
    return _entries.where((e) =>
        e.timestamp.year == date.year &&
        e.timestamp.month == date.month &&
        e.timestamp.day == date.day).toList();
  }

  /// Get entries for the last N days.
  List<MoodEntry> entriesForLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  /// Average mood for a specific date (or null if no entries).
  double? averageMoodForDate(DateTime date) {
    final dayEntries = entriesForDate(date);
    if (dayEntries.isEmpty) return null;
    final sum = dayEntries.fold<int>(0, (s, e) => s + e.mood.value);
    return sum / dayEntries.length;
  }

  /// Daily average moods for the last N days (for trend chart).
  Map<DateTime, double> moodTrend(int days) {
    final result = <DateTime, double>{};
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final avg = averageMoodForDate(date);
      if (avg != null) {
        result[date] = avg;
      }
    }
    return result;
  }

  /// Most common activities across all entries.
  Map<MoodActivity, int> activityFrequency() {
    final counts = <MoodActivity, int>{};
    for (final entry in _entries) {
      for (final activity in entry.activities) {
        counts[activity] = (counts[activity] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Average mood per activity (which activities correlate with good moods?).
  Map<MoodActivity, double> moodByActivity() {
    final sums = <MoodActivity, int>{};
    final counts = <MoodActivity, int>{};
    for (final entry in _entries) {
      for (final activity in entry.activities) {
        sums[activity] = (sums[activity] ?? 0) + entry.mood.value;
        counts[activity] = (counts[activity] ?? 0) + 1;
      }
    }
    final result = <MoodActivity, double>{};
    for (final activity in sums.keys) {
      result[activity] = sums[activity]! / counts[activity]!;
    }
    return Map.fromEntries(
      result.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  // ── Export / Import ──────────────────────────────────────────────

  /// Maximum number of entries allowed via import.
  static const int maxImportEntries = 100000;

  /// Export all mood entries as a JSON string.
  String exportToJson() {
    return jsonEncode({
      'entries': _entries.map((e) => e.toJson()).toList(),
    });
  }

  /// Import mood entries from a JSON string.
  ///
  /// Replaces all existing entries. Parse into temporaries first so
  /// malformed JSON doesn't wipe existing data.
  Future<void> importFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (!data.containsKey('entries')) {
      throw ArgumentError('Missing "entries" key in mood journal backup');
    }
    final list = data['entries'] as List<dynamic>;
    if (list.length > maxImportEntries) {
      throw ArgumentError(
        'Import exceeds maximum of $maxImportEntries entries '
        '(got ${list.length}).',
      );
    }
    final parsed = list
        .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    // All parsed successfully — safe to apply.
    _entries = parsed;
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _save();
  }

  /// Current streak of days with at least one entry.
  int currentStreak() {
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      if (entriesForDate(date).isNotEmpty) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
