import 'dart:convert';
import 'storage_backend.dart';

/// Generic persistence helper for tracker screens that store lists of entries
/// in memory. Provides save/load via [StorageBackend] using model
/// toJson/fromJson serialization.
///
/// Sensitive keys are automatically encrypted at rest; non-sensitive keys
/// use plain SharedPreferences. See [StorageBackend] for details.
///
/// Usage:
/// ```dart
/// final _persistence = ScreenPersistence<WaterEntry>(
///   storageKey: 'water_tracker_entries',
///   toJson: (e) => e.toJson(),
///   fromJson: WaterEntry.fromJson,
/// );
///
/// // In initState:
/// _persistence.load().then((entries) => setState(() => _entries.addAll(entries)));
///
/// // After mutation:
/// _persistence.save(_entries);
/// ```
class ScreenPersistence<T> {
  final String storageKey;
  final Map<String, dynamic> Function(T) toJson;
  final T Function(Map<String, dynamic>) fromJson;

  const ScreenPersistence({
    required this.storageKey,
    required this.toJson,
    required this.fromJson,
  });

  /// Load all entries from storage. Returns empty list if none.
  ///
  /// Sensitive keys are decrypted transparently. Existing plaintext
  /// data is migrated to encrypted form on first read.
  Future<List<T>> load() async {
    try {
      final data = await StorageBackend.read(storageKey);
      if (data == null || data.isEmpty) return [];
      final list = jsonDecode(data) as List<dynamic>;
      return list
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save all entries to storage (encrypted for sensitive keys).
  Future<void> save(List<T> entries) async {
    try {
      final data = jsonEncode(entries.map((e) => toJson(e)).toList());
      await StorageBackend.write(storageKey, data);
    } catch (_) {
      // Silently fail — don't crash the UI for persistence errors.
    }
  }

  /// Delete all persisted entries.
  Future<void> clear() async {
    await StorageBackend.remove(storageKey);
  }

  /// Load a single JSON map (for non-list state like counters, configs).
  Future<Map<String, dynamic>?> loadMap() async {
    try {
      final data = await StorageBackend.read(storageKey);
      if (data == null || data.isEmpty) return null;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Save a single JSON map.
  Future<void> saveMap(Map<String, dynamic> map) async {
    try {
      await StorageBackend.write(storageKey, jsonEncode(map));
    } catch (_) {
      // Silently fail.
    }
  }
}
