import '../../models/mood_entry.dart';
import 'persisted_list_service.dart';

/// Service for managing mood journal entries with local persistence.
///
/// Extends [PersistedListService] for SharedPreferences-based CRUD,
/// adding mood-specific analytics: trends, activity correlations, streaks.
class MoodJournalService extends PersistedListService<MoodEntry> {
  @override
  String get storageKey => 'mood_journal_entries';

  @override
  String encodeList(List<MoodEntry> entries) => MoodEntry.encodeList(entries);

  @override
  List<MoodEntry> decodeList(String data) => MoodEntry.decodeList(data);

  @override
  String getId(MoodEntry e) => e.id;

  @override
  DateTime? getTimestamp(MoodEntry e) => e.timestamp;

  @override
  int defaultSort(MoodEntry a, MoodEntry b) =>
      b.timestamp.compareTo(a.timestamp);

  // ── Queries ──

  /// Get entries for the last N days.
  List<MoodEntry> entriesForLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
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
      final date =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
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
    for (final entry in entries) {
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
    for (final entry in entries) {
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

  /// Current streak of days with at least one entry.
  ///
  /// Uses a pre-built set of dates for O(1) lookups instead of
  /// scanning the full entry list for each of the last 365 days.
  int currentStreak() {
    if (entries.isEmpty) return 0;
    final dates = entries
        .map((e) =>
            DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
        .toSet();
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final date =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      if (dates.contains(date)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
