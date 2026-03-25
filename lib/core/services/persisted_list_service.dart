import 'package:shared_preferences/shared_preferences.dart';

/// Generic base class for services that persist a list of entries to
/// SharedPreferences with lazy initialization.
///
/// Eliminates the init/save/addEntry/deleteEntry/updateEntry boilerplate
/// that was duplicated across MoodJournalService, SymptomTrackerService,
/// SleepTrackerService, and others.
///
/// Subclasses provide:
/// - [storageKey]: the SharedPreferences key
/// - [encodeList]/[decodeList]: serialization for the entry list
/// - [getId]: extract unique id from an entry
/// - [defaultSort]: how to sort entries after load (newest-first, etc.)
///
/// Example:
/// ```dart
/// class MoodJournalService extends PersistedListService<MoodEntry> {
///   @override String get storageKey => 'mood_journal_entries';
///   @override String encodeList(List<MoodEntry> entries) => MoodEntry.encodeList(entries);
///   @override List<MoodEntry> decodeList(String data) => MoodEntry.decodeList(data);
///   @override String getId(MoodEntry e) => e.id;
///   @override int defaultSort(MoodEntry a, MoodEntry b) => b.timestamp.compareTo(a.timestamp);
/// }
/// ```
abstract class PersistedListService<T> {
  List<T> _entries = [];
  bool _initialized = false;

  /// Unmodifiable view of all entries.
  List<T> get entries => List.unmodifiable(_entries);

  /// The SharedPreferences key used for storage.
  String get storageKey;

  /// Serialize all entries to a string.
  String encodeList(List<T> entries);

  /// Deserialize entries from a stored string.
  List<T> decodeList(String data);

  /// Extract the unique identifier from an entry.
  String getId(T entry);

  /// Default sort comparator applied after loading. Return 0 for no sort.
  int defaultSort(T a, T b);

  /// Load entries from local storage. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(storageKey);
    if (data != null && data.isNotEmpty) {
      _entries = decodeList(data);
    }
    _entries.sort(defaultSort);
    _initialized = true;
  }

  /// Persist current entries to SharedPreferences.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, encodeList(_entries));
  }

  /// Add an entry (inserted at the front for newest-first lists).
  Future<void> addEntry(T entry) async {
    await init();
    _entries.insert(0, entry);
    await save();
  }

  /// Delete an entry by id.
  Future<void> deleteEntry(String id) async {
    await init();
    _entries.removeWhere((e) => getId(e) == id);
    await save();
  }

  /// Update an existing entry. Returns true if found and updated.
  Future<bool> updateEntry(T entry) async {
    await init();
    final entryId = getId(entry);
    final idx = _entries.indexWhere((e) => getId(e) == entryId);
    if (idx >= 0) {
      _entries[idx] = entry;
      await save();
      return true;
    }
    return false;
  }

  /// Get entries within a date range. Subclasses must override [getTimestamp]
  /// or use this default which returns nothing.
  DateTime? getTimestamp(T entry) => null;

  /// Get entries within a date range (requires [getTimestamp] override).
  List<T> entriesInRange(DateTime start, DateTime end) {
    return _entries.where((e) {
      final ts = getTimestamp(e);
      return ts != null && ts.isAfter(start) && ts.isBefore(end);
    }).toList();
  }

  /// Get entries for a specific date (requires [getTimestamp] override).
  List<T> entriesForDate(DateTime date) {
    return _entries.where((e) {
      final ts = getTimestamp(e);
      return ts != null &&
          ts.year == date.year &&
          ts.month == date.month &&
          ts.day == date.day;
    }).toList();
  }
}
