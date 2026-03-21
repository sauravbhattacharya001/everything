import 'dart:convert';
import '../../models/body_measurement_entry.dart';

/// Service for managing body measurement entries.
class BodyMeasurementService {
  final List<BodyMeasurementEntry> _entries = [];

  List<BodyMeasurementEntry> get entries =>
      List.unmodifiable(_entries..sort((a, b) => b.date.compareTo(a.date)));

  void add(BodyMeasurementEntry entry) => _entries.add(entry);

  void update(BodyMeasurementEntry entry) {
    final i = _entries.indexWhere((e) => e.id == entry.id);
    if (i != -1) _entries[i] = entry;
  }

  void delete(String id) => _entries.removeWhere((e) => e.id == id);

  /// Latest entry (most recent date).
  BodyMeasurementEntry? get latest =>
      _entries.isEmpty ? null : entries.first;

  /// Previous entry before [current] for comparison.
  BodyMeasurementEntry? previousBefore(BodyMeasurementEntry current) {
    final sorted = entries;
    final i = sorted.indexWhere((e) => e.id == current.id);
    return (i >= 0 && i + 1 < sorted.length) ? sorted[i + 1] : null;
  }

  /// Returns change between latest two entries for a given field.
  double? changeFor(double? Function(BodyMeasurementEntry) getter) {
    if (_entries.length < 2) return null;
    final sorted = entries;
    final curr = getter(sorted[0]);
    final prev = getter(sorted[1]);
    if (curr == null || prev == null) return null;
    return curr - prev;
  }

  String exportToJson() =>
      jsonEncode(_entries.map((e) => e.toJson()).toList());

  void importFromJson(String json) {
    _entries.clear();
    final list = jsonDecode(json) as List<dynamic>;
    _entries.addAll(
        list.map((j) => BodyMeasurementEntry.fromJson(j as Map<String, dynamic>)));
  }
}
