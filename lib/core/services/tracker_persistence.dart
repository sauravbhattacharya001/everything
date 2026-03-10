import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic persistence helper for tracker services.
///
/// Provides save/load operations using SharedPreferences with JSON
/// serialization. Each service uses a unique storage key.
class TrackerPersistence {
  TrackerPersistence._();

  /// Save a list of JSON-serializable items.
  static Future<void> saveList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map(toJson).toList());
    await prefs.setString(key, encoded);
  }

  /// Load a list of items from storage.
  static Future<List<T>> loadList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    if (data == null || data.isEmpty) return [];
    try {
      final decoded = jsonDecode(data) as List;
      return decoded
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save an integer counter (e.g., nextId).
  static Future<void> saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  /// Load an integer counter.
  static Future<int> loadInt(String key, {int defaultValue = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? defaultValue;
  }
}
