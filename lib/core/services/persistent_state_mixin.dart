import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'encrypted_preferences_service.dart';

/// Mixin for StatefulWidget states that need to persist service data
/// across app restarts via SharedPreferences.
///
/// Subclasses must implement [storageKey], [exportData], and [importData].
/// Data is automatically saved when the app goes to background or the
/// widget is deactivated, and loaded on [initPersistence].
///
/// Sensitive keys (medical, financial, diary data) are automatically
/// encrypted at rest using [EncryptedPreferencesService]. Non-sensitive
/// keys use plain SharedPreferences for performance. Existing plaintext
/// data for sensitive keys is transparently migrated on first read.
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
  /// SharedPreferences key for this screen's data.
  String get storageKey;

  /// Serialize current state to JSON string.
  String exportData();

  /// Restore state from a JSON string.
  void importData(String json);

  bool _persistenceInitialized = false;

  /// Whether this storage key holds sensitive personal data that
  /// requires encryption at rest.
  bool get _isSensitive => SensitiveKeys.isSensitive(storageKey);

  /// Call in [initState] to load saved data and register lifecycle observer.
  /// Returns a Future that completes after data is loaded.
  Future<void> initPersistence() {
    _persistenceInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    return _loadData();
  }

  /// Reads the raw JSON string from the appropriate storage backend.
  ///
  /// Sensitive keys are read (and transparently migrated from plaintext)
  /// via [EncryptedPreferencesService]. Non-sensitive keys use plain
  /// SharedPreferences.
  Future<String?> _readStorage() async {
    if (_isSensitive) {
      final encrypted = await EncryptedPreferencesService.getInstance();
      return encrypted.getString(storageKey);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(storageKey);
  }

  /// Writes the raw JSON string to the appropriate storage backend.
  Future<void> _writeStorage(String data) async {
    if (_isSensitive) {
      final encrypted = await EncryptedPreferencesService.getInstance();
      await encrypted.setString(storageKey, data);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, data);
    }
  }

  Future<void> _loadData() async {
    final json = await _readStorage();
    if (json != null && json.isNotEmpty) {
      try {
        importData(json);
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  /// Save current state to storage. Call after mutations.
  ///
  /// Sensitive data is encrypted; non-sensitive data is stored as-is.
  Future<void> saveData() async {
    try {
      await _writeStorage(exportData());
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
