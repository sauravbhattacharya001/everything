import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Mixin that adds automatic SharedPreferences persistence to any service
/// that stores data in memory.
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

  /// Whether [restoreState] has completed.
  bool _persistenceInitialized = false;
  bool get isInitialized => _persistenceInitialized;

  /// Serialize the service's current state to a JSON-compatible map.
  Map<String, dynamic> toStorageJson();

  /// Restore the service's state from a previously-saved JSON map.
  void fromStorageJson(Map<String, dynamic> json);

  /// Load persisted state from SharedPreferences.
  /// Call this in the service's init/constructor before using data.
  /// Safe to call multiple times — only loads once.
  Future<void> restoreState() async {
    if (_persistenceInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(storageKey);
      if (data != null && data.isNotEmpty) {
        final json = jsonDecode(data) as Map<String, dynamic>;
        fromStorageJson(json);
      }
    } catch (e) {
      // Don't crash the app if stored data is corrupt — start fresh
      // ignore: avoid_print
      print('ServicePersistence($storageKey): failed to restore — $e');
    }
    _persistenceInitialized = true;
  }

  /// Persist the current state to SharedPreferences.
  /// Call this after any mutation (add, update, delete).
  Future<void> persistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(toStorageJson());
      await prefs.setString(storageKey, data);
    } catch (e) {
      // ignore: avoid_print
      print('ServicePersistence($storageKey): failed to persist — $e');
    }
  }

  /// Clear persisted state.
  Future<void> clearPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
