import '../../models/sleep_entry.dart';
import '../utils/stats_utils.dart';
import 'encrypted_preferences_service.dart';

/// Service for managing sleep log entries with local persistence and analytics.
///
/// Sleep data is encrypted at rest via [EncryptedPreferencesService].
/// Plaintext entries written before this migration are transparently
/// re-encrypted on first read (handled by [EncryptedPreferencesService]).
class SleepTrackerService {
  static const String _storageKey = 'sleep_tracker_entries';
  List<SleepEntry> _entries = [];
  bool _initialized = false;

  List<SleepEntry> get entries => List.unmodifiable(_entries);

  /// Load entries from encrypted local storage.
  Future<void> init() async {
    if (_initialized) return;
    final encPrefs = await EncryptedPreferencesService.getInstance();
    final data = await encPrefs.getString(_storageKey);
    if (data != null && data.isNotEmpty) {
      _entries = SleepEntry.decodeList(data);
    }
    _entries.sort((a, b) => b.wakeTime.compareTo(a.wakeTime));
    _initialized = true;
  }

  Future<void> _save() async {
    final encPrefs = await EncryptedPreferencesService.getInstance();
    await encPrefs.setString(_storageKey, SleepEntry.encodeList(_entries));
  }

  /// Add a new sleep entry.
  Future<void> addEntry(SleepEntry entry) async {
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
  Future<void> updateEntry(SleepEntry entry) async {
    await init();
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      _entries[idx] = entry;
      await _save();
    }
  }

  /// Get entries for a specific date (by wake date).
  List<SleepEntry> entriesForDate(DateTime date) {
    return _entries.where((e) =>
        e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day).toList();
  }

  /// Get entries for the last N days.
  List<SleepEntry> entriesForLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _entries.where((e) => e.wakeTime.isAfter(cutoff)).toList();
  }

  /// Average sleep duration in hours for a specific date.
  double? avgDurationForDate(DateTime date) {
    final dayEntries = entriesForDate(date);
    if (dayEntries.isEmpty) return null;
    final total = dayEntries.fold<double>(0, (s, e) => s + e.durationHours);
    return total / dayEntries.length;
  }

  /// Average sleep quality for a specific date.
  double? avgQualityForDate(DateTime date) {
    final dayEntries = entriesForDate(date);
    if (dayEntries.isEmpty) return null;
    final sum = dayEntries.fold<int>(0, (s, e) => s + e.quality.value);
    return sum / dayEntries.length;
  }

  /// Daily average duration for the last N days (for trend chart).
  ///
  /// Groups entries once for O(n) performance instead of
  /// scanning per day (O(n×days)).
  Map<DateTime, double> durationTrend(int days) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days));

    final grouped = <DateTime, List<double>>{};
    for (final e in _entries) {
      if (e.wakeTime.isBefore(cutoff)) continue;
      final date = DateTime(e.date.year, e.date.month, e.date.day);
      (grouped[date] ??= []).add(e.durationHours);
    }

    final result = <DateTime, double>{};
    for (final entry in grouped.entries) {
      final sum = entry.value.fold<double>(0, (s, v) => s + v);
      result[entry.key] = sum / entry.value.length;
    }
    return Map.fromEntries(
      result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  /// Daily average quality for the last N days (for trend chart).
  ///
  /// Groups entries once for O(n) performance instead of
  /// scanning per day (O(n×days)).
  Map<DateTime, double> qualityTrend(int days) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days));

    final grouped = <DateTime, List<int>>{};
    for (final e in _entries) {
      if (e.wakeTime.isBefore(cutoff)) continue;
      final date = DateTime(e.date.year, e.date.month, e.date.day);
      (grouped[date] ??= []).add(e.quality.value);
    }

    final result = <DateTime, double>{};
    for (final entry in grouped.entries) {
      final sum = entry.value.fold<int>(0, (s, v) => s + v);
      result[entry.key] = sum / entry.value.length;
    }
    return Map.fromEntries(
      result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  /// Overall average duration across all entries.
  double? overallAvgDuration() {
    if (_entries.isEmpty) return null;
    final total = _entries.fold<double>(0, (s, e) => s + e.durationHours);
    return total / _entries.length;
  }

  /// Overall average quality across all entries.
  double? overallAvgQuality() {
    if (_entries.isEmpty) return null;
    final sum = _entries.fold<int>(0, (s, e) => s + e.quality.value);
    return sum / _entries.length;
  }

  /// Average bedtime hour (0-24) across recent entries.
  double? avgBedtimeHour(int days) {
    final recent = entriesForLastDays(days);
    if (recent.isEmpty) return null;
    // Normalize to 0-24 range, with hours after midnight staying > 24
    double total = 0;
    for (final entry in recent) {
      double hour = entry.bedtime.hour + entry.bedtime.minute / 60.0;
      // If bedtime is before 6 PM, assume it's past midnight (add 24)
      if (hour < 18) hour += 24;
      total += hour;
    }
    return (total / recent.length) % 24;
  }

  /// Average wake time hour (0-24) across recent entries.
  double? avgWakeTimeHour(int days) {
    final recent = entriesForLastDays(days);
    if (recent.isEmpty) return null;
    double total = 0;
    for (final entry in recent) {
      total += entry.wakeTime.hour + entry.wakeTime.minute / 60.0;
    }
    return total / recent.length;
  }

  /// Most common sleep factors.
  Map<SleepFactor, int> factorFrequency() {
    final counts = <SleepFactor, int>{};
    for (final entry in _entries) {
      for (final factor in entry.factors) {
        counts[factor] = (counts[factor] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Average quality per factor (which factors correlate with good sleep?).
  Map<SleepFactor, double> qualityByFactor() {
    final sums = <SleepFactor, int>{};
    final counts = <SleepFactor, int>{};
    for (final entry in _entries) {
      for (final factor in entry.factors) {
        sums[factor] = (sums[factor] ?? 0) + entry.quality.value;
        counts[factor] = (counts[factor] ?? 0) + 1;
      }
    }
    final result = <SleepFactor, double>{};
    for (final factor in sums.keys) {
      result[factor] = sums[factor]! / counts[factor]!;
    }
    return Map.fromEntries(
      result.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Sleep debt: difference from recommended 8 hours over the last N days.
  double sleepDebt(int days, {double targetHours = 8.0}) {
    final recent = entriesForLastDays(days);
    if (recent.isEmpty) return 0;
    // Group by date, take most recent entry per day
    final byDate = <DateTime, SleepEntry>{};
    for (final entry in recent) {
      final date = entry.date;
      if (!byDate.containsKey(date)) byDate[date] = entry;
    }
    double debt = 0;
    for (final entry in byDate.values) {
      debt += targetHours - entry.durationHours;
    }
    return debt;
  }

  /// Current streak of consecutive days with sleep logs.
  ///
  /// Uses a pre-built set of dates for O(1) lookups instead of
  /// scanning the full entry list for each of the last 365 days.
  int currentStreak() {
    if (_entries.isEmpty) return 0;
    final dates = _entries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet();
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      if (dates.contains(date)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Best streak ever.
  int bestStreak() {
    if (_entries.isEmpty) return 0;
    // Get all unique dates with entries
    final dates = _entries.map((e) => e.date).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    if (dates.isEmpty) return 0;

    int best = 1;
    int current = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  /// Sleep schedule consistency score (0-100).
  /// Measures how consistent bedtime and wake time are.
  double consistencyScore(int days) {
    final recent = entriesForLastDays(days);
    if (recent.length < 2) return 100;

    // Calculate variance in bedtime and wake time
    final bedtimeMinutes = recent.map((e) {
      int minutes = e.bedtime.hour * 60 + e.bedtime.minute;
      if (minutes < 18 * 60) minutes += 24 * 60; // normalize after-midnight
      return minutes.toDouble();
    }).toList();

    final wakeMinutes = recent.map((e) {
      return (e.wakeTime.hour * 60 + e.wakeTime.minute).toDouble();
    }).toList();

    double bedVar = StatsUtils.populationVariance(bedtimeMinutes);
    double wakeVar = StatsUtils.populationVariance(wakeMinutes);

    // Convert variance to a 0-100 score
    // Low variance = high consistency
    // 0 variance = 100 score; 120 min std dev = ~0 score
    double avgStdDev = (StatsUtils.sqrtSafe(bedVar) + StatsUtils.sqrtSafe(wakeVar)) / 2;
    double score = 100 * (1 - (avgStdDev / 120).clamp(0, 1));
    return score.clamp(0, 100);
  }
}
