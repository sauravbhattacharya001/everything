import '../../models/allergy_entry.dart';
import 'encrypted_preferences_service.dart';

/// Service for managing allergy log entries with encrypted local persistence.
///
/// Allergy data (allergens, reactions, severity) is sensitive health
/// information and is encrypted at rest via [EncryptedPreferencesService].
class AllergyTrackerService {
  static const String _storageKey = 'allergy_tracker_entries';
  List<AllergyEntry> _entries = [];
  bool _initialized = false;

  List<AllergyEntry> get entries => List.unmodifiable(_entries);

  /// Load entries from encrypted local storage.
  Future<void> init() async {
    if (_initialized) return;
    final encPrefs = await EncryptedPreferencesService.getInstance();
    final data = await encPrefs.getString(_storageKey);
    if (data != null && data.isNotEmpty) {
      _entries = AllergyEntry.decodeList(data);
    }
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _initialized = true;
  }

  Future<void> _save() async {
    final encPrefs = await EncryptedPreferencesService.getInstance();
    await encPrefs.setString(_storageKey, AllergyEntry.encodeList(_entries));
  }

  /// Add a new allergy entry.
  Future<void> addEntry(AllergyEntry entry) async {
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
  Future<void> updateEntry(AllergyEntry updated) async {
    await init();
    final idx = _entries.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _entries[idx] = updated;
      await _save();
    }
  }

  /// Get entries for a specific allergen category.
  List<AllergyEntry> entriesForCategory(AllergenCategory category) {
    return _entries.where((e) => e.category == category).toList();
  }

  /// Get entries within a date range.
  List<AllergyEntry> entriesInRange(DateTime start, DateTime end) {
    return _entries
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .toList();
  }

  /// Get most frequent allergens.
  Map<String, int> allergenFrequency() {
    final freq = <String, int>{};
    for (final e in _entries) {
      freq[e.allergen] = (freq[e.allergen] ?? 0) + 1;
    }
    return Map.fromEntries(
      freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Get most common symptoms across all entries.
  Map<String, int> symptomFrequency() {
    final freq = <String, int>{};
    for (final e in _entries) {
      for (final s in e.symptoms) {
        freq[s] = (freq[s] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Get severity distribution.
  Map<ReactionSeverity, int> severityDistribution() {
    final dist = <ReactionSeverity, int>{};
    for (final e in _entries) {
      dist[e.severity] = (dist[e.severity] ?? 0) + 1;
    }
    return dist;
  }

  /// Get category distribution.
  Map<AllergenCategory, int> categoryDistribution() {
    final dist = <AllergenCategory, int>{};
    for (final e in _entries) {
      dist[e.category] = (dist[e.category] ?? 0) + 1;
    }
    return dist;
  }

  /// Get unique allergens list.
  List<String> get knownAllergens {
    return _entries.map((e) => e.allergen).toSet().toList()..sort();
  }
}
