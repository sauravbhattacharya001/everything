import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'encrypted_persistence.dart';

/// Generic persistence helper for tracker screens that store lists of entries.
///
/// **Security:** Keys listed in [StorageMigration.sensitiveKeys] are
/// automatically stored in encrypted storage (EncryptedSharedPreferences /
/// Keychain). Non-sensitive keys still use SharedPreferences for performance.
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

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  const ScreenPersistence({
    required this.storageKey,
    required this.toJson,
    required this.fromJson,
  });

  bool get _isSensitive =>
      StorageMigration.sensitiveKeys.contains(storageKey);

  /// Load all entries. Uses encrypted storage for sensitive keys.
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

  /// Save all entries. Uses encrypted storage for sensitive keys.
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
      await _secureStorage.delete(key: storageKey);
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

  Future<String?> _read() async {
    if (_isSensitive) {
      return await _secureStorage.read(key: storageKey);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(storageKey);
  }

  Future<void> _write(String data) async {
    if (_isSensitive) {
      await _secureStorage.write(key: storageKey, value: data);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, data);
    }
  }
}
