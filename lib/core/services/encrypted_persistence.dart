import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Encrypted persistence layer for sensitive tracker data.
///
/// Uses [FlutterSecureStorage] (EncryptedSharedPreferences on Android,
/// Keychain on iOS) instead of plaintext SharedPreferences.
///
/// Drop-in replacement for [ScreenPersistence] — same API, encrypted backend.
class EncryptedPersistence<T> {
  final String storageKey;
  final Map<String, dynamic> Function(T) toJson;
  final T Function(Map<String, dynamic>) fromJson;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  const EncryptedPersistence({
    required this.storageKey,
    required this.toJson,
    required this.fromJson,
  });

  /// Load all entries from encrypted storage. Returns empty list if none.
  Future<List<T>> load() async {
    try {
      // Auto-migrate from plaintext if needed
      await _migrateIfNeeded();
      final data = await _storage.read(key: storageKey);
      if (data == null || data.isEmpty) return [];
      final list = jsonDecode(data) as List<dynamic>;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save all entries to encrypted storage.
  Future<void> save(List<T> entries) async {
    try {
      final data = jsonEncode(entries.map((e) => toJson(e)).toList());
      await _storage.write(key: storageKey, value: data);
    } catch (_) {
      // Silently fail — don't crash the UI for persistence errors.
    }
  }

  /// Delete all persisted entries.
  Future<void> clear() async {
    await _storage.delete(key: storageKey);
  }

  /// Load a single JSON map (for non-list state like counters, configs).
  Future<Map<String, dynamic>?> loadMap() async {
    try {
      await _migrateIfNeeded();
      final data = await _storage.read(key: storageKey);
      if (data == null || data.isEmpty) return null;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Save a single JSON map.
  Future<void> saveMap(Map<String, dynamic> map) async {
    try {
      await _storage.write(key: storageKey, value: jsonEncode(map));
    } catch (_) {
      // Silently fail.
    }
  }

  /// Migrate data from plaintext SharedPreferences to encrypted storage.
  /// Only runs once per key — checks for a migration flag.
  Future<void> _migrateIfNeeded() async {
    final migrationKey = '${storageKey}_migrated';
    final alreadyMigrated = await _storage.read(key: migrationKey);
    if (alreadyMigrated == 'true') return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final plaintext = prefs.getString(storageKey);
      if (plaintext != null && plaintext.isNotEmpty) {
        // Copy to encrypted storage
        await _storage.write(key: storageKey, value: plaintext);
        // Remove plaintext copy
        await prefs.remove(storageKey);
      }
      // Mark as migrated
      await _storage.write(key: migrationKey, value: 'true');
    } catch (_) {
      // If migration fails, we'll try again next time
    }
  }
}

/// Bulk migration utility — call once at app startup to migrate all
/// known sensitive keys from SharedPreferences to encrypted storage.
class StorageMigration {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Sensitive storage keys that should be encrypted.
  /// Add any key that stores health, financial, or personal journal data.
  static const List<String> sensitiveKeys = [
    'blood_pressure_entries',
    'medication_tracker_entries',
    'symptom_tracker_entries',
    'body_measurement_entries',
    'net_worth_tracker_data',
    'expense_tracker_entries',
    'debt_payoff_data',
    'budget_planner_data',
    'mood_journal_entries',
    'gratitude_journal_entries',
    'daily_journal_entries',
    'sleep_tracker_entries',
    'water_tracker_entries',
    'meal_tracker_entries',
    'workout_tracker_entries',
    'fasting_tracker_entries',
    'energy_tracker_entries',
    'savings_goal_data',
    'loan_calculator_data',
    'subscription_tracker_entries',
    'invoice_data',
    'contact_tracker_entries',
    'emergency_card_data',
    'vehicle_maintenance_entries',
    'pet_care_entries',
    'decision_journal_entries',
  ];

  /// Run bulk migration at app startup. Safe to call multiple times —
  /// each key is only migrated once.
  static Future<void> migrateAll() async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in sensitiveKeys) {
      final migrationKey = '${key}_migrated';
      final alreadyMigrated = await _storage.read(key: migrationKey);
      if (alreadyMigrated == 'true') continue;

      try {
        final plaintext = prefs.getString(key);
        if (plaintext != null && plaintext.isNotEmpty) {
          await _storage.write(key: key, value: plaintext);
          await prefs.remove(key);
        }
        await _storage.write(key: migrationKey, value: 'true');
      } catch (_) {
        // Non-fatal — will retry next launch
      }
    }
  }
}
