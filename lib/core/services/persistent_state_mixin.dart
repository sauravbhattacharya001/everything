import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

/// Mixin for StatefulWidget states that need to persist service data
/// across app restarts using encrypted storage.
///
/// Data is stored via [SecureStorageService] (EncryptedSharedPreferences on
/// Android, Keychain on iOS). On first load, any existing plaintext data in
/// SharedPreferences is automatically migrated to the encrypted store and
/// the plaintext copy is deleted.
///
/// Subclasses must implement [storageKey], [exportData], and [importData].
/// Data is automatically saved when the app goes to background or the
/// widget is deactivated, and loaded on [initPersistence].
///
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen>
///     with SingleTickerProviderStateMixin, PersistentStateMixin {
///   @override
///   String get storageKey => 'my_screen_data';
///   @override
///   String exportData() => _service.exportToJson();
///   @override
///   void importData(String json) => _service.importFromJson(json);
///
///   @override
///   void initState() {
///     super.initState();
///     initPersistence(); // loads saved data & registers lifecycle observer
///   }
/// }
/// ```
mixin PersistentStateMixin<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  /// Storage key for this screen's data.
  String get storageKey;

  /// Serialize current state to JSON string.
  String exportData();

  /// Restore state from a JSON string.
  void importData(String json);

  bool _persistenceInitialized = false;

  /// Call in [initState] to load saved data and register lifecycle observer.
  /// Returns a Future that completes after data is loaded.
  Future<void> initPersistence() {
    _persistenceInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    return _loadData();
  }

  Future<void> _loadData() async {
    // Migrate plaintext SharedPreferences → encrypted storage if needed.
    await _migrateFromPlaintext();

    final json = await SecureStorageService.read(storageKey);
    if (json != null && json.isNotEmpty) {
      try {
        importData(json);
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  /// One-time migration: move data from plaintext SharedPreferences to
  /// encrypted storage, then delete the plaintext copy.
  Future<void> _migrateFromPlaintext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plaintext = prefs.getString(storageKey);
      if (plaintext != null && plaintext.isNotEmpty) {
        // Only migrate if encrypted store doesn't already have data.
        final existing = await SecureStorageService.read(storageKey);
        if (existing == null || existing.isEmpty) {
          await SecureStorageService.write(storageKey, plaintext);
        }
        // Remove plaintext regardless (idempotent cleanup).
        await prefs.remove(storageKey);
      }
    } catch (_) {
      // Migration failure is non-fatal; data stays in plaintext until
      // next successful migration attempt.
    }
  }

  /// Save current state to encrypted storage. Call after mutations.
  Future<void> saveData() async {
    try {
      await SecureStorageService.write(storageKey, exportData());
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      saveData();
    }
  }

  @override
  void deactivate() {
    if (_persistenceInitialized) saveData();
    super.deactivate();
  }

  @override
  void dispose() {
    if (_persistenceInitialized) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  // WidgetsBindingObserver no-op stubs
  @override
  void didChangeAccessibilityFeatures() {}
  @override
  void didChangeLocales(List<Locale>? locales) {}
  @override
  void didChangeMetrics() {}
  @override
  void didChangePlatformBrightness() {}
  @override
  void didChangeTextScaleFactor() {}
  @override
  void didHaveMemoryPressure() {}
  @override
  Future<bool> didPopRoute() => Future.value(false);
  @override
  Future<bool> didPushRoute(String route) => Future.value(false);
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) =>
      Future.value(false);
  @override
  Future<AppExitResponse> didRequestAppExit() =>
      Future.value(AppExitResponse.exit);
}
