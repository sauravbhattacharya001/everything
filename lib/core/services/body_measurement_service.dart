import '../../models/body_measurement_entry.dart';
import 'crud_service.dart';

/// Service for managing body measurement entries.
///
/// Refactored to extend [CrudService], eliminating duplicated CRUD
/// boilerplate (add, update, delete, export/import) while preserving
/// all domain-specific methods.
class BodyMeasurementService extends CrudService<BodyMeasurementEntry> {
  @override
  String getId(BodyMeasurementEntry item) => item.id;

  @override
  Map<String, dynamic> toJson(BodyMeasurementEntry item) => item.toJson();

  @override
  BodyMeasurementEntry fromJson(Map<String, dynamic> json) =>
      BodyMeasurementEntry.fromJson(json);

  /// Entries sorted by date (most recent first).
  List<BodyMeasurementEntry> get entries {
    final sorted = List<BodyMeasurementEntry>.from(items);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  /// Convenience aliases to match the original API surface.
  void delete(String id) => remove(id);

  /// Latest entry (most recent date).
  BodyMeasurementEntry? get latest => isEmpty ? null : entries.first;

  /// Previous entry before [current] for comparison.
  BodyMeasurementEntry? previousBefore(BodyMeasurementEntry current) {
    final sorted = entries;
    final i = sorted.indexWhere((e) => e.id == current.id);
    return (i >= 0 && i + 1 < sorted.length) ? sorted[i + 1] : null;
  }

  /// Returns change between latest two entries for a given field.
  double? changeFor(double? Function(BodyMeasurementEntry) getter) {
    if (length < 2) return null;
    final sorted = entries;
    final curr = getter(sorted[0]);
    final prev = getter(sorted[1]);
    if (curr == null || prev == null) return null;
    return curr - prev;
  }
}
