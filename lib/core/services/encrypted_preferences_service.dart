import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Encrypts sensitive tracker data before writing to SharedPreferences.
///
/// ## Problem
///
/// SharedPreferences stores data as **plaintext XML/JSON** on disk:
/// - Android: `/data/data/<pkg>/shared_prefs/*.xml`
/// - iOS: `Library/Preferences/<bundle-id>.plist`
///
/// On rooted/jailbroken devices, via ADB backups, or through device
/// forensics, this data is trivially readable. The app stores highly
/// sensitive personal data in SharedPreferences:
/// - **Medical:** medications, symptoms, blood pressure, blood sugar
/// - **Financial:** expenses, debts, net worth, subscriptions
/// - **Personal:** mood journals, sleep patterns, daily journals
///
/// ## Solution
///
/// This service wraps SharedPreferences with AES-256-GCM encryption.
/// The encryption key is generated once and stored in platform-secure
/// storage (Android Keystore / iOS Keychain via flutter_secure_storage).
///
/// It's a **drop-in replacement** for the raw `prefs.getString/setString`
/// pattern used by [ScreenPersistence] and [DataBackupService].
///
/// ## Migration
///
/// On first use for each key, if encrypted data is not found but
/// plaintext data exists, the service transparently migrates it:
/// reads the plaintext, encrypts it, writes the encrypted version,
/// and removes the plaintext key. This ensures zero data loss on upgrade.
class EncryptedPreferencesService {
  static const String _keyAlias = 'encrypted_prefs_aes_key';
  static const String _encPrefix = 'enc_v1:';

  static EncryptedPreferencesService? _instance;
  late final Uint8List _key;
  bool _initialized = false;

  EncryptedPreferencesService._();

  /// Returns the singleton instance, initializing the encryption key
  /// on first call.
  static Future<EncryptedPreferencesService> getInstance() async {
    _instance ??= EncryptedPreferencesService._();
    if (!_instance!._initialized) {
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );

    // Load or generate the AES-256 key.
    final existing = await storage.read(key: _keyAlias);
    if (existing != null) {
      _key = base64Decode(existing);
    } else {
      final random = Random.secure();
      _key = Uint8List.fromList(
        List<int>.generate(32, (_) => random.nextInt(256)),
      );
      await storage.write(key: _keyAlias, value: base64Encode(_key));
    }
    _initialized = true;
  }

  /// Reads and decrypts a value from SharedPreferences.
  ///
  /// If the stored value is plaintext (not encrypted), it is
  /// transparently migrated to encrypted form and the plaintext
  /// is removed.
  ///
  /// Returns `null` if the key doesn't exist.
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;

    if (raw.startsWith(_encPrefix)) {
      // Already encrypted — decrypt it.
      return _decrypt(raw.substring(_encPrefix.length));
    }

    // Plaintext data from before encryption was enabled — migrate it.
    await setString(key, raw);
    return raw;
  }

  /// Encrypts and writes a value to SharedPreferences.
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = _encrypt(value);
    await prefs.setString(key, '$_encPrefix$encrypted');
  }

  /// Removes a key from SharedPreferences.
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Checks if a key exists (encrypted or plaintext).
  Future<bool> containsKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  // ──────────────────────────────────────────────────────────────────
  // AES-256-GCM encryption
  // ──────────────────────────────────────────────────────────────────

  /// Encrypts [plaintext] with AES-256-GCM and a random 96-bit IV.
  ///
  /// Output format: `base64(iv) + '.' + base64(ciphertext+tag)`
  String _encrypt(String plaintext) {
    final random = Random.secure();
    final iv = Uint8List.fromList(
      List<int>.generate(12, (_) => random.nextInt(256)),
    );

    final encrypter = enc.Encrypter(enc.AES(
      enc.Key(_key),
      mode: enc.AESMode.gcm,
    ));
    final encrypted = encrypter.encryptBytes(
      utf8.encode(plaintext),
      iv: enc.IV(iv),
    );

    return '${base64Encode(iv)}.${encrypted.base64}';
  }

  /// Decrypts a value produced by [_encrypt].
  String _decrypt(String encoded) {
    final parts = encoded.split('.');
    if (parts.length != 2) {
      throw FormatException('Invalid encrypted format');
    }

    final iv = base64Decode(parts[0]);
    final ciphertext = base64Decode(parts[1]);

    final encrypter = enc.Encrypter(enc.AES(
      enc.Key(_key),
      mode: enc.AESMode.gcm,
    ));

    return encrypter.decrypt(
      enc.Encrypted(ciphertext),
      iv: enc.IV(iv),
    );
  }
}

/// Sensitive storage keys that should always be encrypted.
///
/// This list mirrors [DataBackupService._storageKeys] and identifies
/// keys containing personal health, financial, or diary data.
class SensitiveKeys {
  SensitiveKeys._();

  static const Set<String> keys = {
    // Health & medical
    'medication_tracker_entries',
    'symptom_tracker_entries',
    'blood_pressure_entries',
    'blood_sugar_entries',
    'body_measurement_entries',
    'sleep_tracker_entries',
    'water_tracker_entries',
    'meal_tracker_entries',
    'fasting_tracker_entries',
    'workout_tracker_entries',

    // Mental health & personal
    'mood_journal_entries',
    'gratitude_journal_entries',
    'daily_journal_entries',
    'meditation_tracker_entries',
    'energy_tracker_entries',

    // Financial
    'expense_tracker_entries',
    'debt_payoff_data',
    'net_worth_tracker_data',
    'budget_planner_data',
    'subscription_tracker_entries',
    'savings_goal_data',

    // Personal identity
    'emergency_card_data',
    'contact_tracker_entries',
  };

  /// Returns true if [key] contains sensitive personal data that
  /// should be encrypted at rest.
  static bool isSensitive(String key) => keys.contains(key);
}
