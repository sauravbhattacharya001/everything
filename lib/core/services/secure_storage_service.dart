import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data (tokens, credentials).
///
/// Uses platform-specific secure storage:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences / Keystore
///
/// Use this instead of [StorageService] (SharedPreferences) for any
/// sensitive values like access tokens, refresh tokens, or API keys.
/// SharedPreferences stores data as plaintext in XML files that can
/// be read on rooted/jailbroken devices or via device backups.
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Store a sensitive value securely.
  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a sensitive value from secure storage.
  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete a specific key from secure storage.
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Delete all values from secure storage (e.g., on logout).
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Check if a key exists in secure storage.
  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  // Common key constants to avoid typos
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
}
