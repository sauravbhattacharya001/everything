import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mixin for StatefulWidget states that auto-persist service data via
/// SharedPreferences. Subclasses provide a storage key, export, and import.
///
/// On initState, data is loaded from SharedPreferences. On every setState,
/// data is debounce-saved (100ms) to avoid excessive writes during rapid
/// mutations.
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
/// }
/// ```
mixin PersistentStateMixin<T extends StatefulWidget> on State<T> {
  Timer? _saveTimer;

  /// Unique SharedPreferences key for this screen's data.
  String get storageKey;

  /// Serialize the current service state to a JSON string.
  String exportData();

  /// Restore service state from a JSON string.
  void importData(String json);

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
  }

  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(storageKey);
      if (json != null && json.isNotEmpty) {
        importData(json);
        if (mounted) setState(() {});
      }
    } catch (_) {
      // Don't crash on corrupt data; start fresh.
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 100), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(storageKey, exportData());
      } catch (_) {
        // Don't crash on save failure.
      }
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // Final synchronous-ish save attempt.
    _doFinalSave();
    super.dispose();
  }

  void _doFinalSave() {
    try {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(storageKey, exportData());
      });
    } catch (_) {}
  }
}
