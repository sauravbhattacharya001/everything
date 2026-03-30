import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_backend.dart';

/// Unified data backup and restore service.
///
/// Discovers all registered storage keys, exports their data into a single
/// JSON backup, and restores from a backup with optional merge/replace
/// strategy.
///
/// Usage:
/// ```dart
/// final backup = DataBackupService();
/// final json = await backup.exportAll();
/// // ... save json to file ...
/// final result = await backup.importAll(json);
/// ```
class DataBackupService {
  /// Current backup format version.
  static const int backupVersion = 1;

  /// Maximum allowed backup size in bytes (50 MB).
  ///
  /// Prevents memory exhaustion from maliciously large backup files
  /// on resource-constrained mobile devices.
  static const int maxBackupBytes = 50 * 1024 * 1024;

  /// All storage keys used by tracker screens across the app.
  /// Maintain this list when adding new persistent screens.
  static const Map<String, String> _storageKeys = {
    // PersistentStateMixin-based screens
    'debt_payoff_data': 'Debt Payoff Planner',
    'grocery_list_data': 'Grocery List',
    'home_inventory_data': 'Home Inventory',
    'loyalty_tracker_data': 'Loyalty Tracker',
    'net_worth_tracker_data': 'Net Worth Tracker',
    'plant_care_data': 'Plant Care Tracker',
    'savings_goal_data': 'Savings Goals',
    'warranty_tracker_data': 'Warranty Tracker',
    'screen_time_tracker_data': 'Screen Time Tracker',
    'routine_builder_data': 'Routine Builder',
    'budget_planner_data': 'Budget Planner',
    'quick_capture_data': 'Quick Capture',

    // ScreenPersistence-based screens
    'chore_tracker_entries': 'Chore Tracker',
    'commute_tracker_entries': 'Commute Tracker',
    'contact_tracker_entries': 'Contact Tracker',
    'decision_journal_entries': 'Decision Journal',
    'energy_tracker_entries': 'Energy Tracker',
    'goal_tracker_entries': 'Goal Tracker',
    'medication_tracker_entries': 'Medication Tracker',
    'meditation_tracker_entries': 'Meditation Tracker',
    'pet_care_tracker_entries': 'Pet Care Tracker',
    'reading_list_entries': 'Reading List',
    'subscription_tracker_entries': 'Subscription Tracker',
    'time_tracker_entries': 'Time Tracker',
    'travel_log_entries': 'Travel Log',
    'water_tracker_entries': 'Water Tracker',
    'wishlist_entries': 'Wishlist',

    // Direct SharedPreferences-based services
    'mood_journal_entries': 'Mood Journal',
    'sleep_tracker_entries': 'Sleep Tracker',
    'expense_tracker_entries': 'Expense Tracker',
    'gratitude_journal_entries': 'Gratitude Journal',
    'dream_journal_data': 'Dream Journal',
    'habit_tracker_data': 'Habit Tracker',
    'meal_tracker_entries': 'Meal Tracker',
    'skill_tracker_entries': 'Skill Tracker',
    'workout_tracker_entries': 'Workout Tracker',

    // Previously missing — added to ensure complete backup coverage
    'blood_pressure_entries': 'Blood Pressure',
    'blood_sugar_entries': 'Blood Sugar',
    'body_measurement_entries': 'Body Measurements',
    'fasting_tracker_entries': 'Fasting Tracker',
    'daily_journal_entries': 'Daily Journal',
    'emergency_card_data': 'Emergency Card',
    'symptom_tracker_entries': 'Symptom Tracker',
  };

  /// Reads a value from the appropriate storage backend.
  ///
  /// Delegates to [StorageBackend] which transparently handles
  /// encryption for sensitive keys.
  static Future<String?> _readKey(String key) async {
    return StorageBackend.read(key);
  }

  /// Writes a value through the appropriate storage backend.
  ///
  /// Delegates to [StorageBackend] which transparently handles
  /// encryption for sensitive keys.
  static Future<void> _writeKey(String key, String value) async {
    await StorageBackend.write(key, value);
  }

  /// Export all service data as a single JSON string.
  ///
  /// Sensitive keys are transparently decrypted before export so the
  /// backup contains readable JSON regardless of at-rest encryption.
  ///
  /// All storage keys are read concurrently via [Future.wait] to reduce
  /// total export time from O(n × latency) to O(latency) — a significant
  /// improvement when many tracker screens have data, especially on
  /// devices where [StorageBackend] involves async decryption.
  Future<String> exportAll() async {
    final keys = _storageKeys.keys.toList();
    final values = await Future.wait(keys.map(_readKey));

    final services = <String, dynamic>{};
    for (var i = 0; i < keys.length; i++) {
      if (values[i] != null) {
        services[keys[i]] = values[i];
      }
    }

    final backup = {
      'version': backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'appName': 'Everything',
      'serviceCount': services.length,
      'totalKeys': _storageKeys.length,
      'services': services,
    };

    return jsonEncode(backup);
  }

  /// Import all service data from a backup JSON string.
  ///
  /// [strategy] controls conflict resolution:
  /// - [BackupStrategy.replace]: overwrite all existing data (default)
  /// - [BackupStrategy.merge]: only import services that don't have data
  ///
  /// Returns a [BackupResult] with details about what was restored.
  Future<BackupResult> importAll(
    String json, {
    BackupStrategy strategy = BackupStrategy.replace,
  }) async {
    // Guard against oversized payloads that could exhaust memory on mobile.
    if (json.length > maxBackupBytes) {
      final sizeMB = (json.length / (1024 * 1024)).toStringAsFixed(1);
      final limitMB = (maxBackupBytes / (1024 * 1024)).round();
      return BackupResult(
        success: false,
        error: 'Backup is $sizeMB MB which exceeds the $limitMB MB limit. '
            'Please use a smaller backup file.',
        restored: 0,
        skipped: 0,
        services: {},
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (e) {
      return BackupResult(
        success: false,
        error: 'Invalid JSON: ${e.message}',
        restored: 0,
        skipped: 0,
        services: {},
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return BackupResult(
        success: false,
        error: 'Invalid backup format: expected a JSON object but got '
            '${decoded.runtimeType}.',
        restored: 0,
        skipped: 0,
        services: {},
      );
    }

    final data = decoded;

    // Version check
    final version = data['version'] as int? ?? 0;
    if (version > backupVersion) {
      return BackupResult(
        success: false,
        error: 'Backup version $version is newer than supported '
            'version $backupVersion. Please update the app.',
        restored: 0,
        skipped: 0,
        services: {},
      );
    }

    final services = data['services'] as Map<String, dynamic>? ?? {};

    int restored = 0;
    int skipped = 0;
    final serviceResults = <String, String>{};

    // Phase 1: Filter and validate entries (sync — no I/O).
    final validEntries = <String, String>{};
    for (final entry in services.entries) {
      final key = entry.key;
      final value = entry.value as String?;
      if (value == null) continue;

      if (!_storageKeys.containsKey(key)) {
        serviceResults[key] = 'unknown_key';
        skipped++;
        continue;
      }

      // Validate JSON is parseable before any I/O.
      try {
        jsonDecode(value);
      } catch (_) {
        serviceResults[key] = 'invalid_json';
        skipped++;
        continue;
      }

      validEntries[key] = value;
    }

    // Phase 2 (merge only): Batch-read all existing values concurrently
    // to decide which keys to skip. Previously each key was read
    // sequentially inside the loop, making import O(n × latency).
    if (strategy == BackupStrategy.merge && validEntries.isNotEmpty) {
      final keys = validEntries.keys.toList();
      final existing = await Future.wait(keys.map(_readKey));
      for (var i = 0; i < keys.length; i++) {
        if (existing[i] != null && existing[i]!.isNotEmpty) {
          serviceResults[keys[i]] = 'skipped_existing';
          skipped++;
          validEntries.remove(keys[i]);
        }
      }
    }

    // Phase 3: Write all remaining entries concurrently.
    // Previously writes were sequential (O(n × latency)); batching
    // reduces total time to O(latency) — same approach as exportAll.
    if (validEntries.isNotEmpty) {
      await Future.wait(
        validEntries.entries.map((e) => _writeKey(e.key, e.value)),
      );
      for (final key in validEntries.keys) {
        serviceResults[key] = 'restored';
        restored++;
      }
    }

    return BackupResult(
      success: true,
      restored: restored,
      skipped: skipped,
      services: serviceResults,
    );
  }

  /// Check which services have data and which support backup.
  ///
  /// Reads all keys concurrently for the same latency win as [exportAll].
  Future<Map<String, ServiceBackupInfo>> checkServiceSupport() async {
    final entries = _storageKeys.entries.toList();
    final values = await Future.wait(entries.map((e) => _readKey(e.key)));

    final result = <String, ServiceBackupInfo>{};
    for (var i = 0; i < entries.length; i++) {
      final data = values[i];
      result[entries[i].key] = ServiceBackupInfo(
        displayName: entries[i].value,
        hasData: data != null && data.isNotEmpty,
        dataSize: data?.length ?? 0,
      );
    }

    return result;
  }

  /// Clear all persisted data. Use with caution.
  Future<int> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    int cleared = 0;
    for (final key in _storageKeys.keys) {
      if (prefs.containsKey(key)) {
        await prefs.remove(key);
        cleared++;
      }
    }
    return cleared;
  }
}

/// Strategy for handling conflicts during import.
enum BackupStrategy {
  /// Overwrite existing data with backup data.
  replace,

  /// Only import services that don't have existing data.
  merge,
}

/// Result of an import operation.
class BackupResult {
  final bool success;
  final String? error;
  final int restored;
  final int skipped;
  final Map<String, String> services;

  const BackupResult({
    required this.success,
    this.error,
    required this.restored,
    required this.skipped,
    required this.services,
  });

  @override
  String toString() => success
      ? 'BackupResult(restored: $restored, skipped: $skipped)'
      : 'BackupResult(error: $error)';
}

/// Info about a service's backup capability.
class ServiceBackupInfo {
  final String displayName;
  final bool hasData;
  final int dataSize;

  const ServiceBackupInfo({
    required this.displayName,
    required this.hasData,
    required this.dataSize,
  });
}
