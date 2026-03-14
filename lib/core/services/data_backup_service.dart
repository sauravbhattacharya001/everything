import 'dart:convert';

/// Result of a backup import operation.
class BackupResult {
  /// Services that were successfully restored.
  final List<String> restored;

  /// Services that were skipped (not present in backup).
  final List<String> skipped;

  /// Services that failed to restore, with error messages.
  final Map<String, String> errors;

  const BackupResult({
    required this.restored,
    required this.skipped,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() {
    final lines = <String>[];
    if (restored.isNotEmpty) {
      lines.add('Restored: ${restored.join(", ")}');
    }
    if (skipped.isNotEmpty) {
      lines.add('Skipped: ${skipped.join(", ")}');
    }
    if (errors.isNotEmpty) {
      lines.add('Errors:');
      errors.forEach((k, v) => lines.add('  $k: $v'));
    }
    return lines.join('\n');
  }
}

/// Interface that data services must implement to support unified backup.
///
/// Services register themselves with [DataBackupService] using
/// [registerService]. Each service provides a unique key, an export
/// function that returns its data as a JSON-encodable map, and an
/// import function that restores from a decoded map.
typedef ExportFn = Map<String, dynamic> Function();
typedef ImportFn = void Function(Map<String, dynamic> data);
typedef AsyncImportFn = Future<void> Function(Map<String, dynamic> data);

/// Unified backup and restore for all registered data services.
///
/// Usage:
/// ```dart
/// final backup = DataBackupService();
/// backup.registerService(
///   key: 'expenses',
///   export: () => jsonDecode(expenseService.exportToJson()),
///   import: (data) => expenseService.importFromJson(jsonEncode(data)),
/// );
/// // ... register more services
///
/// final json = backup.exportAll();    // full backup as JSON string
/// final result = await backup.importAll(json);  // restore from backup
/// ```
class DataBackupService {
  static const int backupVersion = 1;

  /// Maximum number of services allowed (sanity check).
  static const int maxServices = 200;

  /// Maximum backup size in characters (50 MB of JSON text).
  static const int maxBackupSize = 50 * 1024 * 1024;

  final Map<String, _ServiceRegistration> _services = {};

  /// Register a data service for unified backup.
  ///
  /// [key] must be unique and stable across app versions.
  /// [export] returns the service's data as a JSON-encodable map.
  /// [import_] restores the service from a decoded map.
  /// [asyncImport] alternative async import for services that need
  /// to persist to SharedPreferences during import.
  void registerService({
    required String key,
    required ExportFn export,
    ImportFn? import_,
    AsyncImportFn? asyncImport,
  }) {
    if (key.isEmpty) {
      throw ArgumentError('Service key must not be empty');
    }
    if (_services.length >= maxServices) {
      throw StateError('Too many services registered (max $maxServices)');
    }
    _services[key] = _ServiceRegistration(
      export: export,
      import_: import_,
      asyncImport: asyncImport,
    );
  }

  /// Check which services support backup.
  Map<String, bool> checkServiceSupport() {
    return _services.map((key, _) => MapEntry(key, true));
  }

  /// List all registered service keys.
  List<String> get registeredServices => _services.keys.toList()..sort();

  /// Export all registered services as a single JSON string.
  ///
  /// The output contains a version number, timestamp, manifest of
  /// included services, and each service's data keyed by its
  /// registration key.
  String exportAll() {
    final serviceData = <String, dynamic>{};
    final manifest = <String>[];

    for (final entry in _services.entries) {
      try {
        serviceData[entry.key] = entry.value.export();
        manifest.add(entry.key);
      } catch (e) {
        // Skip services that fail to export — don't block the whole
        // backup because one service has bad state.
        serviceData['_errors'] ??= <String, String>{};
        (serviceData['_errors'] as Map<String, String>)[entry.key] =
            e.toString();
      }
    }

    final backup = <String, dynamic>{
      'version': backupVersion,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'manifest': manifest,
      'services': serviceData,
    };

    return jsonEncode(backup);
  }

  /// Import all services from a backup JSON string.
  ///
  /// Services not present in the backup are skipped (not cleared).
  /// Each service is imported independently — a failure in one
  /// service doesn't affect others.
  Future<BackupResult> importAll(String json) async {
    if (json.length > maxBackupSize) {
      throw ArgumentError(
        'Backup file exceeds maximum size of '
        '${(maxBackupSize / 1024 / 1024).toStringAsFixed(0)} MB.',
      );
    }

    final data = jsonDecode(json) as Map<String, dynamic>;

    // Version check
    final version = data['version'] as int?;
    if (version == null || version > backupVersion) {
      throw ArgumentError(
        'Unsupported backup version: $version '
        '(this app supports up to v$backupVersion). '
        'Please update the app.',
      );
    }

    final services = data['services'] as Map<String, dynamic>?;
    if (services == null) {
      throw ArgumentError('Invalid backup: missing "services" section.');
    }

    final restored = <String>[];
    final skipped = <String>[];
    final errors = <String, String>{};

    for (final key in _services.keys) {
      if (!services.containsKey(key)) {
        skipped.add(key);
        continue;
      }

      try {
        final serviceData = services[key] as Map<String, dynamic>;
        final reg = _services[key]!;
        if (reg.asyncImport != null) {
          await reg.asyncImport!(serviceData);
        } else if (reg.import_ != null) {
          reg.import_!(serviceData);
        } else {
          skipped.add(key);
          continue;
        }
        restored.add(key);
      } catch (e) {
        errors[key] = e.toString();
      }
    }

    return BackupResult(
      restored: restored,
      skipped: skipped,
      errors: errors,
    );
  }
}

class _ServiceRegistration {
  final ExportFn export;
  final ImportFn? import_;
  final AsyncImportFn? asyncImport;

  const _ServiceRegistration({
    required this.export,
    this.import_,
    this.asyncImport,
  });
}
