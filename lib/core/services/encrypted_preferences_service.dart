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
  // AES-256-GCM encryption with HMAC integrity verification
  // ──────────────────────────────────────────────────────────────────

  /// Derives a separate HMAC key from the encryption key to ensure
  /// encryption and authentication use independent keys.
  Uint8List get _hmacKey {
    // Derive HMAC key as HMAC-SHA256(encKey, "hmac-key-derivation")
    final hmac = Hmac(sha256, _key);
    return Uint8List.fromList(
      hmac.convert(utf8.encode('hmac-key-derivation')).bytes,
    );
  }

  /// Encrypts [plaintext] with AES-256-GCM and a random 96-bit IV,
  /// then appends an HMAC-SHA256 tag for integrity verification.
  ///
  /// The `encrypt` package's GCM implementation may not reliably
  /// validate the GCM authentication tag on decryption, which would
  /// allow tampered ciphertext to decrypt without error. Adding an
  /// explicit HMAC over (iv ‖ ciphertext) ensures tampered data is
  /// always detected regardless of the underlying package's behavior.
  ///
  /// Output format: `base64(iv) + '.' + base64(ciphertext+tag) + '.' + base64(hmac)`
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

    // Compute HMAC-SHA256 over (iv ‖ ciphertext) for integrity.
    final hmac = Hmac(sha256, _hmacKey);
    final hmacDigest = hmac.convert([...iv, ...encrypted.bytes]);

    return '${base64Encode(iv)}.${encrypted.base64}.${base64Encode(hmacDigest.bytes)}';
  }

  /// Decrypts a value produced by [_encrypt].
  ///
  /// Verifies the HMAC integrity tag before decryption (if present).
  /// Values without an HMAC (written before this security fix) are
  /// still accepted but will be re-encrypted with HMAC on next write.
  String _decrypt(String encoded) {
    final parts = encoded.split('.');
    if (parts.length < 2 || parts.length > 3) {
      throw FormatException('Invalid encrypted format');
    }

    final iv = base64Decode(parts[0]);
    final ciphertext = base64Decode(parts[1]);

    // Verify HMAC if present (v2 format with 3 parts).
    if (parts.length == 3) {
      final storedHmac = base64Decode(parts[2]);
      final hmac = Hmac(sha256, _hmacKey);
      final computedHmac = hmac.convert([...iv, ...ciphertext]);
      if (!_constantTimeEquals(
          Uint8List.fromList(computedHmac.bytes), Uint8List.fromList(storedHmac))) {
        throw FormatException('HMAC verification failed — data may be tampered');
      }
    }

    final encrypter = enc.Encrypter(enc.AES(
      enc.Key(_key),
      mode: enc.AESMode.gcm,
    ));

    return encrypter.decrypt(
      enc.Encrypted(ciphertext),
      iv: enc.IV(iv),
    );
  }

  /// Constant-time comparison to prevent timing attacks on HMAC.
  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
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
    'spo2_entries',
    'body_measurement_entries',
    'sleep_tracker_entries',
    'water_tracker_entries',
    'meal_tracker_entries',
    'fasting_tracker_entries',
    'workout_tracker_entries',

    // Mental health & personal
    'mood_journal_entries',
    'gratitude_journal_entries',
    'dream_journal_data',
    'daily_journal_entries',
    'meditation_tracker_entries',
    'energy_tracker_entries',
    'decision_journal_entries',

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

    // Location & behavioral patterns
    'travel_log_entries',
    'commute_tracker_entries',
    'habit_tracker_data',
    'goal_tracker_entries',
    'time_tracker_entries',

    // Health — previously missing from encryption
    'caffeine_tracker_entries',
    'weight_tracker_entries',
    'pet_care_tracker_entries', // pet medical records

    // Behavioral patterns — reveal daily routines and habits
    'screen_time_tracker_data',
    'routine_builder_data',
    'skill_tracker_entries',
    'chore_tracker_entries',

    // Freeform text that may contain sensitive content
    'quick_capture_data',
  };

  /// Returns true if [key] contains sensitive personal data that
  /// should be encrypted at rest.
  static bool isSensitive(String key) => keys.contains(key);
}
