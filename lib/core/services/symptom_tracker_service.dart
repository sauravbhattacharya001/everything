import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/symptom_entry.dart';

/// Service for managing symptom log entries with local persistence.
class SymptomTrackerService {
  static const String _storageKey = 'symptom_tracker_entries';
  List<SymptomEntry> _entries = [];
  bool _initialized = false;

  List<SymptomEntry> get entries => List.unmodifiable(_entries);

  /// Load entries from local storage.
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null && data.isNotEmpty) {
      _entries = SymptomEntry.decodeList(data);
    }
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _initialized = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, SymptomEntry.encodeList(_entries));
  }

  /// Add a new symptom entry.
  Future<void> addEntry(SymptomEntry entry) async {
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

  /// Get entries for a specific body area.
  List<SymptomEntry> entriesForArea(BodyArea area) {
    return _entries.where((e) => e.bodyArea == area).toList();
  }

  /// Get entries within a date range.
  List<SymptomEntry> entriesInRange(DateTime start, DateTime end) {
    return _entries
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .toList();
  }

  /// Get most frequent symptoms.
  Map<String, int> symptomFrequency() {
    final freq = <String, int>{};
    for (final e in _entries) {
      freq[e.symptom] = (freq[e.symptom] ?? 0) + 1;
    }
    return Map.fromEntries(
      freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Get most common triggers across all entries.
  Map<String, int> triggerFrequency() {
    final freq = <String, int>{};
    for (final e in _entries) {
      for (final t in e.triggers) {
        freq[t] = (freq[t] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }
}
