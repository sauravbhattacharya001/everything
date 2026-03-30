import 'dart:convert';
import 'storage_backend.dart';

/// Mixin for adding persistence to stateful services.
///
/// Routes all storage through [StorageBackend], which automatically
/// encrypts sensitive keys (medical, financial, diary data) via
/// [EncryptedPreferencesService] while using plain SharedPreferences
/// for non-sensitive keys.
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
  /// Unique key for storage. Sensitive keys are automatically encrypted.
  String get storageKey;

  /// Serialize service state to JSON-compatible map.
  Map<String, dynamic> toStorageJson();

  /// Restore service state from a JSON-compatible map.
  void fromStorageJson(Map<String, dynamic> json);

  bool _persInitialized = false;

  /// Whether persistence has been initialized (data loaded).
  bool get isInitialized => _persInitialized;

  /// Load state from storage. Call once at startup or before first use.
  ///
  /// Sensitive keys are transparently decrypted. Existing plaintext
  /// data for sensitive keys is migrated to encrypted form on first read.
  Future<bool> loadState() async {
    final data = await StorageBackend.read(storageKey);
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

  /// Save current state to storage.
  ///
  /// Sensitive keys are automatically encrypted before storage.
  Future<void> saveState() async {
    await StorageBackend.write(storageKey, jsonEncode(toStorageJson()));
  }

  /// Clear persisted state.
  Future<void> clearState() async {
    await StorageBackend.remove(storageKey);
  }
}
