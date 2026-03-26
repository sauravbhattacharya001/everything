import 'package:shared_preferences/shared_preferences.dart';
import 'encrypted_preferences_service.dart';

/// Unified read/write layer that routes storage operations through the
/// correct backend based on key sensitivity.
///
/// Sensitive keys (medical, financial, diary data) are encrypted at rest
/// via [EncryptedPreferencesService]. All other keys use plain
/// [SharedPreferences] for performance.
///
/// This eliminates the duplicated sensitivity-routing logic that was
/// previously copy-pasted across [ScreenPersistence],
/// [PersistentStateMixin], and [DataBackupService].
class StorageBackend {
  StorageBackend._();

  /// Reads a value from the appropriate backend for [key].
  ///
  /// Sensitive keys are transparently decrypted. Existing plaintext
  /// data for sensitive keys is migrated to encrypted form on first read.
  static Future<String?> read(String key) async {
    if (SensitiveKeys.isSensitive(key)) {
      final encrypted = await EncryptedPreferencesService.getInstance();
      return encrypted.getString(key);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Writes a value through the appropriate backend for [key].
  ///
  /// Sensitive keys are encrypted before storage.
  static Future<void> write(String key, String value) async {
    if (SensitiveKeys.isSensitive(key)) {
      final encrypted = await EncryptedPreferencesService.getInstance();
      await encrypted.setString(key, value);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  /// Removes a key from storage.
  static Future<void> remove(String key) async {
    if (SensitiveKeys.isSensitive(key)) {
      final encrypted = await EncryptedPreferencesService.getInstance();
      await encrypted.remove(key);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }

  /// Checks if a key exists in storage.
  static Future<bool> containsKey(String key) async {
    if (SensitiveKeys.isSensitive(key)) {
      final encrypted = await EncryptedPreferencesService.getInstance();
      return encrypted.containsKey(key);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }
}
