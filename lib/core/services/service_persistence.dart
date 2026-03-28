import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Mixin for adding SharedPreferences-based persistence to stateful services.
///
/// Services that hold in-memory state (lists, maps) can use this mixin to
/// automatically save/restore their data across app restarts.
///
/// Usage:
/// ```dart
/// class MyService with ServicePersistence {
///   @override
///   String get storageKey => 'my_service_data';
///
///   @override
///   Map<String, dynamic> toStorageJson() => { 'items': _items.map((e) => e.toJson()).toList() };
///
///   @override
///   void fromStorageJson(Map<String, dynamic> json) {
///     _items = (json['items'] as List).map((e) => Item.fromJson(e)).toList();
///   }
/// }
/// ```
mixin ServicePersistence {
  /// Unique key for SharedPreferences storage.
  String get storageKey;

  /// Serialize service state to JSON-compatible map.
  Map<String, dynamic> toStorageJson();

  /// Restore service state from a JSON-compatible map.
  void fromStorageJson(Map<String, dynamic> json);

  bool _persInitialized = false;

  /// Whether persistence has been initialized (data loaded).
  bool get isInitialized => _persInitialized;

  /// Load state from SharedPreferences. Call once at startup or before first use.
  Future<bool> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(storageKey);
    if (data != null && data.isNotEmpty) {
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        fromStorageJson(json);
        _persInitialized = true;
        return true;
      } catch (_) {
        // Corrupted data — start fresh
        _persInitialized = true;
        return false;
      }
    }
    _persInitialized = true;
    return false;
  }

  /// Save current state to SharedPreferences.
  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(toStorageJson()));
  }

  /// Clear persisted state.
  Future<void> clearState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
