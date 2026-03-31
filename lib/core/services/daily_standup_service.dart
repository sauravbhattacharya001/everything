import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/standup_entry.dart';

/// Daily Standup service — manages quick morning check-ins with
/// yesterday/today/blockers format. Tracks streaks and completion rates.
class DailyStandupService extends ChangeNotifier {
  final List<StandupEntry> _entries = [];

  List<StandupEntry> get entries => List.unmodifiable(_entries);

  /// Get today's standup entry, creating one if it doesn't exist.
  StandupEntry getOrCreateToday() {
    final today = _dateOnly(DateTime.now());
    final existing = _entries.where((e) => _dateOnly(e.date) == today);
    if (existing.isNotEmpty) return existing.first;

    final entry = StandupEntry(
      id: '${today.millisecondsSinceEpoch}',
      date: today,
    );
    _entries.insert(0, entry);
    notifyListeners();
    return entry;
  }

  /// Save/update today's standup.
  void save(StandupEntry entry) {
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      _entries[idx] = entry;
    } else {
      _entries.insert(0, entry);
    }
    notifyListeners();
  }

  /// Mark today's goals as completed.
  void markGoalsCompleted(String id) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _entries[idx].goalsCompleted = true;
      notifyListeners();
    }
  }

  /// Delete a standup entry.
  void delete(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Get entries for a given date range.
  List<StandupEntry> getRange(DateTime start, DateTime end) {
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    return _entries
        .where((entry) {
          final d = _dateOnly(entry.date);
          return !d.isBefore(s) && !d.isAfter(e);
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Current streak of consecutive standup days.
  int get currentStreak {
    if (_entries.isEmpty) return 0;
    final sorted = _entries.map((e) => _dateOnly(e.date)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    if (sorted.first != today && sorted.first != yesterday) return 0;

    int streak = 1;
    for (int i = 0; i < sorted.length - 1; i++) {
      if (sorted[i].difference(sorted[i + 1]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Goal completion rate over last N entries.
  double completionRate({int count = 30}) {
    final recent = _entries.take(count).where((e) => e.isComplete).toList();
    if (recent.isEmpty) return 0;
    return recent.where((e) => e.goalsCompleted).length / recent.length;
  }

  /// How many standups had blockers over last N entries.
  int blockerCount({int count = 30}) {
    return _entries.take(count).where((e) => e.hasBlockers).length;
  }

  /// Average energy level over last N entries.
  double averageEnergy({int count = 30}) {
    final recent = _entries.take(count).where((e) => e.isComplete).toList();
    if (recent.isEmpty) return 0;
    return recent.map((e) => e.energy).reduce((a, b) => a + b) /
        recent.length;
  }

  /// Serialize all entries to JSON string.
  String toJsonString() =>
      jsonEncode(_entries.map((e) => e.toJson()).toList());

  /// Load entries from JSON string.
  void loadFromJson(String json) {
    _entries.clear();
    final list = jsonDecode(json) as List;
    _entries.addAll(list.map((e) => StandupEntry.fromJson(e)));
    notifyListeners();
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
