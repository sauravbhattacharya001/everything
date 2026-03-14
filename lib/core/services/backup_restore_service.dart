import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Unified backup/restore service for all app data.
///
/// Exports all persisted screen data from SharedPreferences into a single
/// JSON document. Imports restore all data at once, providing a single
/// backup/restore format across all services.
///
/// The backup format:
/// ```json
/// {
///   "version": 1,
///   "createdAt": "2026-03-14T11:00:00Z",
///   "appName": "Everything",
///   "data": {
///     "water_tracker_entries": "...",
///     "workout_tracker_data": "...",
///     ...
///   }
/// }
/// ```
class BackupRestoreService {
  /// All known storage keys used by tracker screens.
  /// Add new keys here when new screens gain persistence.
  static const List<String> knownStorageKeys = [
    // Screens using ScreenPersistence (list-based)
    'water_tracker_entries',
    'contact_tracker_entries',
    'reading_list_entries',
    'meditation_tracker_entries',
    'energy_tracker_entries',
    'chore_tracker_entries',
    'pet_care_entries',
    'medication_tracker_entries',
    'commute_tracker_entries',
    'decision_journal_entries',
    'skill_tracker_entries',
    'vehicle_maintenance_entries',
    // Screens with custom SharedPreferences persistence
    'workout_tracker_data',
    'habit_tracker_habits',
    'habit_tracker_completions',
    'expense_tracker_data',
    'meal_tracker_data',
    'mood_journal_data',
    'gratitude_journal_data',
    'daily_review_data',
    'goal_tracker_data',
    'screen_time_tracker_data',
    'time_tracker_data',
    'sleep_tracker_data',
    // Screens using PersistentStateMixin
    'grocery_list_data',
    'subscription_tracker_data',
    'plant_care_data',
    'savings_goal_data',
    'loyalty_tracker_data',
    'net_worth_tracker_data',
    'home_inventory_data',
    'warranty_tracker_data',
    // Core services
    'mood_journal',
    'sleep_tracker',
    'template_service',
  ];

  /// Export all app data to a single JSON string.
  ///
  /// Returns a JSON document containing all persisted data from
  /// SharedPreferences, keyed by storage key.
  static Future<String> exportAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, String>{};

    for (final key in knownStorageKeys) {
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) {
        data[key] = value;
      }
    }

    // Also capture any unknown keys that look like app data
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (!data.containsKey(key) && _isAppDataKey(key)) {
        final value = prefs.getString(key);
        if (value != null && value.isNotEmpty) {
          data[key] = value;
        }
      }
    }

    final backup = {
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'appName': 'Everything',
      'keyCount': data.length,
      'data': data,
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Import all app data from a backup JSON string.
  ///
  /// Returns a [BackupResult] with counts of restored and skipped keys.
  /// Does NOT clear existing data for keys not in the backup — this is
  /// additive/overwrite only.
  static Future<BackupResult> importAll(String jsonStr) async {
    final backup = jsonDecode(jsonStr) as Map<String, dynamic>;

    // Version check
    final version = backup['version'] as int? ?? 0;
    if (version > 1) {
      return BackupResult(
        restored: 0,
        skipped: 0,
        errors: ['Unsupported backup version: $version (max supported: 1)'],
      );
    }

    final data = backup['data'] as Map<String, dynamic>?;
    if (data == null || data.isEmpty) {
      return BackupResult(
        restored: 0,
        skipped: 0,
        errors: ['No data found in backup'],
      );
    }

    final prefs = await SharedPreferences.getInstance();
    int restored = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final entry in data.entries) {
      try {
        final value = entry.value as String;
        // Validate it's valid JSON before storing
        jsonDecode(value);
        await prefs.setString(entry.key, value);
        restored++;
      } catch (e) {
        errors.add('Failed to restore ${entry.key}: $e');
        skipped++;
      }
    }

    return BackupResult(
      restored: restored,
      skipped: skipped,
      errors: errors,
    );
  }

  /// Clear all app data from SharedPreferences.
  ///
  /// ⚠️ Destructive — all persisted tracker data will be lost.
  static Future<int> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    int cleared = 0;

    for (final key in knownStorageKeys) {
      if (prefs.containsKey(key)) {
        await prefs.remove(key);
        cleared++;
      }
    }

    return cleared;
  }

  /// Get a summary of what data is currently persisted.
  static Future<Map<String, int>> getSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final summary = <String, int>{};

    for (final key in knownStorageKeys) {
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) {
        summary[key] = value.length;
      }
    }

    return summary;
  }

  static bool _isAppDataKey(String key) {
    return key.contains('tracker') ||
        key.contains('journal') ||
        key.contains('service') ||
        key.contains('entries') ||
        key.contains('_data');
  }
}

/// Result of a backup import operation.
class BackupResult {
  final int restored;
  final int skipped;
  final List<String> errors;

  const BackupResult({
    required this.restored,
    required this.skipped,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  int get total => restored + skipped;

  @override
  String toString() =>
      'BackupResult(restored: $restored, skipped: $skipped, errors: ${errors.length})';
}
