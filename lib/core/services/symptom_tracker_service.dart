import '../../models/symptom_entry.dart';
import 'persisted_list_service.dart';

/// Service for managing symptom log entries with local persistence.
///
/// Extends [PersistedListService] for SharedPreferences-based CRUD,
/// adding symptom-specific queries: body area filtering, frequency analysis.
class SymptomTrackerService extends PersistedListService<SymptomEntry> {
  @override
  String get storageKey => 'symptom_tracker_entries';

  @override
  String encodeList(List<SymptomEntry> entries) =>
      SymptomEntry.encodeList(entries);

  @override
  List<SymptomEntry> decodeList(String data) => SymptomEntry.decodeList(data);

  @override
  String getId(SymptomEntry e) => e.id;

  @override
  DateTime? getTimestamp(SymptomEntry e) => e.timestamp;

  @override
  int defaultSort(SymptomEntry a, SymptomEntry b) =>
      b.timestamp.compareTo(a.timestamp);

  // ── Queries ──

  /// Get entries for a specific body area.
  List<SymptomEntry> entriesForArea(BodyArea area) {
    return entries.where((e) => e.bodyArea == area).toList();
  }

  /// Get most frequent symptoms.
  Map<String, int> symptomFrequency() {
    final freq = <String, int>{};
    for (final e in entries) {
      freq[e.symptom] = (freq[e.symptom] ?? 0) + 1;
    }
    return Map.fromEntries(
      freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Get most common triggers across all entries.
  Map<String, int> triggerFrequency() {
    final freq = <String, int>{};
    for (final e in entries) {
      for (final t in e.triggers) {
        freq[t] = (freq[t] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }
}
