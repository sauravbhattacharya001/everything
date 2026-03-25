import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_service.dart';

/// Generic persistence helper for tracker screens that store lists of entries
/// in memory. Uses encrypted storage (Android EncryptedSharedPreferences /
/// iOS Keychain) to protect sensitive health, financial, and personal data.
///
/// On first load, automatically migrates any existing plaintext
/// SharedPreferences data to the encrypted backend.
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

  /// Migrate plaintext SharedPreferences data to secure storage if present.
  Future<String?> _migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final plaintext = prefs.getString(storageKey);
    if (plaintext != null && plaintext.isNotEmpty) {
      await SecureStorageService.write(storageKey, plaintext);
      await prefs.remove(storageKey);
      return plaintext;
    }
    return null;
  }

  /// Load all entries from encrypted storage. Returns empty list if none.
  Future<List<T>> load() async {
    try {
      String? data = await SecureStorageService.read(storageKey);

      // Auto-migrate from plaintext if encrypted store is empty
      if (data == null || data.isEmpty) {
        data = await _migrateIfNeeded();
      }

      if (data == null || data.isEmpty) return [];
      final list = jsonDecode(data) as List<dynamic>;
      return list
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save all entries to encrypted storage.
  Future<void> save(List<T> entries) async {
    try {
      final data = jsonEncode(entries.map((e) => toJson(e)).toList());
      await SecureStorageService.write(storageKey, data);
    } catch (_) {
      // Silently fail — don't crash the UI for persistence errors.
    }
  }

  /// Delete all persisted entries from both encrypted and plaintext storage.
  Future<void> clear() async {
    await SecureStorageService.delete(storageKey);
    // Also clean up any lingering plaintext data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  /// Load a single JSON map (for non-list state like counters, configs).
  Future<Map<String, dynamic>?> loadMap() async {
    try {
      String? data = await SecureStorageService.read(storageKey);

      if (data == null || data.isEmpty) {
        data = await _migrateIfNeeded();
      }

      if (data == null || data.isEmpty) return null;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Save a single JSON map to encrypted storage.
  Future<void> saveMap(Map<String, dynamic> map) async {
    try {
      await SecureStorageService.write(storageKey, jsonEncode(map));
    } catch (_) {
      // Silently fail.
    }
  }
}
