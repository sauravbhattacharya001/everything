import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of a backup import operation.
class BackupResult {
  final int servicesRestored;
  final int servicesFailed;
  final List<String> errors;

  const BackupResult({
    required this.servicesRestored,
    required this.servicesFailed,
    this.errors = const [],
  });

  bool get success => servicesFailed == 0;

  @override
  String toString() =>
      'BackupResult(restored: $servicesRestored, failed: $servicesFailed'
      '${errors.isNotEmpty ? ', errors: $errors' : ''})';
}

/// Unified data backup/restore service for the Everything app.
///
/// Aggregates all service data stored in SharedPreferences into a single
/// JSON backup that can be exported and imported to restore all user data.
///
/// Usage:
/// ```dart
/// final backup = DataBackupService();
/// final json = await backup.exportAll();  // Save this string to a file
/// final result = await backup.importAll(json);  // Restore from backup
/// ```
class DataBackupService {
  /// Version of the backup format for future compatibility.
  static const int backupVersion = 1;

  /// All known SharedPreferences keys used by services in the app.
  /// When adding a new service with persistence, add its key here.
  static const List<String> _serviceKeys = [
    // Services with SharedPreferences persistence
    'mood_journal_entries',
    'sleep_tracker_entries',
    'habit_tracker_habits',
    'habit_tracker_completions',
    'water_tracker_entries',
    'expense_tracker_entries',
    'expense_tracker_budgets',
    'gratitude_journal_entries',
    'meal_tracker_entries',
    'workout_tracker_entries',
    'skill_tracker_entries',
    'contact_tracker_entries',
    'decision_journal_entries',
    'energy_tracker_entries',
    'meditation_tracker_entries',
    'reading_list_entries',
    'chore_tracker_entries',
    'goals_tracker_entries',
    'medication_tracker_entries',
    'pet_care_tracker_entries',
    // Newly persisted services
    'subscription_tracker_data',
    'screen_time_tracker_data',
    'grocery_list_data',
    'savings_goal_data',
    'home_inventory_data',
    'warranty_tracker_data',
    // Template and secure storage
    'template_service_templates',
  ];

  /// Export all service data as a single JSON string.
  ///
  /// Returns a JSON string containing all persisted service data,
  /// along with metadata (version, timestamp, service count).
  Future<String> exportAll() async {
    final prefs = await SharedPreferences.getInstance();
    final services = <String, dynamic>{};

    for (final key in _serviceKeys) {
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) {
        services[key] = value;
      }
    }

    final backup = {
      'version': backupVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'serviceCount': services.length,
      'services': services,
    };

    return jsonEncode(backup);
  }

  /// Import all service data from a backup JSON string.
  ///
  /// Restores each service's data from the backup. Existing data for
  /// each service is replaced (not merged).
  Future<BackupResult> importAll(String json) async {
    final prefs = await SharedPreferences.getInstance();
    int restored = 0;
    int failed = 0;
    final errors = <String>[];

    try {
      final backup = jsonDecode(json) as Map<String, dynamic>;

      // Version check
      final version = backup['version'] as int? ?? 0;
      if (version > backupVersion) {
        return BackupResult(
          servicesRestored: 0,
          servicesFailed: 1,
          errors: [
            'Backup version $version is newer than supported version $backupVersion'
          ],
        );
      }

      final services = backup['services'] as Map<String, dynamic>?;
      if (services == null) {
        return const BackupResult(
          servicesRestored: 0,
          servicesFailed: 1,
          errors: ['Invalid backup format: missing services data'],
        );
      }

      for (final entry in services.entries) {
        try {
          final value = entry.value as String;
          // Validate it's valid JSON before storing
          jsonDecode(value);
          await prefs.setString(entry.key, value);
          restored++;
        } catch (e) {
          failed++;
          errors.add('${entry.key}: $e');
        }
      }
    } catch (e) {
      return BackupResult(
        servicesRestored: restored,
        servicesFailed: failed + 1,
        errors: [...errors, 'Parse error: $e'],
      );
    }

    return BackupResult(
      servicesRestored: restored,
      servicesFailed: failed,
      errors: errors,
    );
  }

  /// Check which services have persisted data.
  Future<Map<String, bool>> checkServiceSupport() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, bool>{};
    for (final key in _serviceKeys) {
      final value = prefs.getString(key);
      result[key] = value != null && value.isNotEmpty;
    }
    return result;
  }

  /// Clear all persisted service data.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _serviceKeys) {
      await prefs.remove(key);
    }
  }

  /// Get the total size of all persisted data in bytes (approximate).
  Future<int> estimateDataSize() async {
    final prefs = await SharedPreferences.getInstance();
    int totalBytes = 0;
    for (final key in _serviceKeys) {
      final value = prefs.getString(key);
      if (value != null) {
        totalBytes += value.length;
      }
    }
    return totalBytes;
  }
}
