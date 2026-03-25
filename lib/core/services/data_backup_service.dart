import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'encrypted_preferences_service.dart';

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
  };

  /// Export all service data as a single JSON string.
  ///
  /// Sensitive keys are transparently decrypted before export so the
  /// backup contains readable JSON regardless of at-rest encryption.
  Future<String> exportAll() async {
    final prefs = await SharedPreferences.getInstance();
    final services = <String, dynamic>{};
    final supported = <String, bool>{};

    for (final entry in _storageKeys.entries) {
      String? data;
      if (SensitiveKeys.isSensitive(entry.key)) {
        // Read through EncryptedPreferencesService to get decrypted data
        final encrypted = await EncryptedPreferencesService.getInstance();
        data = await encrypted.getString(entry.key);
      } else {
        data = prefs.getString(entry.key);
      }
      supported[entry.key] = data != null;
      if (data != null) {
        services[entry.key] = data;
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
    final prefs = await SharedPreferences.getInstance();

    int restored = 0;
    int skipped = 0;
    final serviceResults = <String, String>{};

    for (final entry in services.entries) {
      final key = entry.key;
      final value = entry.value as String?;
      if (value == null) continue;

      // Validate it's a known key
      if (!_storageKeys.containsKey(key)) {
        serviceResults[key] = 'unknown_key';
        skipped++;
        continue;
      }

      // Check merge strategy
      if (strategy == BackupStrategy.merge) {
        String? existing;
        if (SensitiveKeys.isSensitive(key)) {
          final encrypted = await EncryptedPreferencesService.getInstance();
          existing = await encrypted.getString(key);
        } else {
          existing = prefs.getString(key);
        }
        if (existing != null && existing.isNotEmpty) {
          serviceResults[key] = 'skipped_existing';
          skipped++;
          continue;
        }
      }

      // Validate JSON is parseable
      try {
        jsonDecode(value);
      } catch (_) {
        serviceResults[key] = 'invalid_json';
        skipped++;
        continue;
      }

      // Write through the appropriate storage backend
      if (SensitiveKeys.isSensitive(key)) {
        final encrypted = await EncryptedPreferencesService.getInstance();
        await encrypted.setString(key, value);
      } else {
        await prefs.setString(key, value);
      }
      serviceResults[key] = 'restored';
      restored++;
    }

    return BackupResult(
      success: true,
      restored: restored,
      skipped: skipped,
      services: serviceResults,
    );
  }

  /// Check which services have data and which support backup.
  Future<Map<String, ServiceBackupInfo>> checkServiceSupport() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, ServiceBackupInfo>{};

    for (final entry in _storageKeys.entries) {
      String? data;
      if (SensitiveKeys.isSensitive(entry.key)) {
        final encrypted = await EncryptedPreferencesService.getInstance();
        data = await encrypted.getString(entry.key);
      } else {
        data = prefs.getString(entry.key);
      }
      result[entry.key] = ServiceBackupInfo(
        displayName: entry.value,
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
