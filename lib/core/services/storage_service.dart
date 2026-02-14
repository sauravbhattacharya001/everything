import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive key-value storage backed by [SharedPreferences].
///
/// Use this for user preferences, UI state, and other non-sensitive data.
/// For tokens, credentials, or any secret values, use [SecureStorageService]
/// instead — SharedPreferences stores data as plaintext XML that can be
/// read on rooted/jailbroken devices or extracted from backups.
///
/// All methods are static for convenience. The [SharedPreferences] instance
/// is obtained per-call; Flutter's implementation caches internally after
/// the first load.
class StorageService {
  /// Persists a string value under the given [key].
  ///
  /// Overwrites any existing value for [key].
  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Retrieves a previously stored string, or `null` if [key] doesn't exist.
  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Removes all entries from shared preferences.
  ///
  /// **Caution:** This deletes everything stored by the app in
  /// SharedPreferences, not just values written by this class.
  static Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
