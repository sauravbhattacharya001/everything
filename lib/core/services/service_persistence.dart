import 'dart:convert';
import 'storage_backend.dart';

/// Mixin for adding persistence to stateful services via [StorageBackend].
///
/// Sensitive keys (medical, financial, diary data) are automatically
/// encrypted at rest. Non-sensitive keys use plain SharedPreferences
/// for performance. See [StorageBackend] and [SensitiveKeys] for details.
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
  /// Unique key for storage.
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
  /// Sensitive data is encrypted before writing; non-sensitive data
  /// is stored as-is.
  Future<void> saveState() async {
    await StorageBackend.write(storageKey, jsonEncode(toStorageJson()));
  }

  /// Clear persisted state.
  Future<void> clearState() async {
    await StorageBackend.remove(storageKey);
  }
}
