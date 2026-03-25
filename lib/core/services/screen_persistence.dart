import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'encrypted_preferences_service.dart';

/// Generic persistence helper for tracker screens that store lists of entries
/// in memory. Provides save/load via SharedPreferences using model
/// toJson/fromJson serialization.
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

  /// Whether this storage key holds sensitive personal data.
  ///
  /// Sensitive keys (medical, financial, diary) are encrypted at rest
  /// using [EncryptedPreferencesService]. Non-sensitive keys use plain
  /// SharedPreferences for performance.
  bool get _isSensitive => SensitiveKeys.isSensitive(storageKey);

  /// Reads a raw string from the appropriate storage backend.
  Future<String?> _read() async {
    if (_isSensitive) {
      final encrypted = await EncryptedPreferencesService.getInstance();
      return encrypted.getString(storageKey);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(storageKey);
  }

  /// Writes a raw string to the appropriate storage backend.
  Future<void> _write(String data) async {
    if (_isSensitive) {
      final encrypted = await EncryptedPreferencesService.getInstance();
      await encrypted.setString(storageKey, data);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, data);
    }
  }

  /// Load all entries from storage. Returns empty list if none.
  ///
  /// Sensitive keys are decrypted transparently. Existing plaintext
  /// data is migrated to encrypted form on first read.
  Future<List<T>> load() async {
    try {
      final data = await _read();
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
      await _write(data);
    } catch (_) {
      // Silently fail — don't crash the UI for persistence errors.
    }
  }

  /// Delete all persisted entries.
  Future<void> clear() async {
    if (_isSensitive) {
      final encrypted = await EncryptedPreferencesService.getInstance();
      await encrypted.remove(storageKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(storageKey);
    }
  }

  /// Load a single JSON map (for non-list state like counters, configs).
  Future<Map<String, dynamic>?> loadMap() async {
    try {
      final data = await _read();
      if (data == null || data.isEmpty) return null;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Save a single JSON map.
  Future<void> saveMap(Map<String, dynamic> map) async {
    try {
      await _write(jsonEncode(map));
    } catch (_) {
      // Silently fail.
    }
  }
}
