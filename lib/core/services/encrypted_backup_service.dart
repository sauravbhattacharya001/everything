import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

import 'data_backup_service.dart';

/// Encrypts and decrypts backup data using AES-256-CBC with PBKDF2 key
/// derivation.
///
/// The backup JSON produced by [DataBackupService] contains sensitive
/// personal data — medical records, financial entries, emergency contacts,
/// and medication schedules. Storing or sharing this as plaintext is a
/// security risk, especially when exported to files, cloud storage, or
/// shared via messaging.
///
/// This service wraps [DataBackupService] and adds:
/// - **AES-256-CBC encryption** with a user-supplied passphrase
/// - **PBKDF2 key derivation** (100 000 iterations of HMAC-SHA256) so
///   the passphrase is never used directly as a key
/// - **Random 128-bit IV** per export (stored in the output)
/// - **Random 256-bit salt** per export (stored in the output)
/// - **HMAC-SHA256 integrity tag** so tampered backups are detected
///   before decryption
///
/// Encrypted output format (JSON):
/// ```json
/// {
///   "format": "everything-encrypted-backup",
///   "version": 1,
///   "salt": "<base64>",
///   "iv": "<base64>",
///   "hmac": "<base64>",
///   "ciphertext": "<base64>"
/// }
/// ```
class EncryptedBackupService {
  final DataBackupService _backupService;

  /// Number of PBKDF2 iterations. 100k is the current OWASP minimum
  /// recommendation for HMAC-SHA256.
  static const int _pbkdf2Iterations = 100000;

  /// Salt length in bytes (256 bits).
  static const int _saltLength = 32;

  /// Creates an [EncryptedBackupService] wrapping the given backup service.
  EncryptedBackupService({DataBackupService? backupService})
      : _backupService = backupService ?? DataBackupService();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Exports all app data as an encrypted JSON string.
  ///
  /// [passphrase] must be non-empty. The caller is responsible for
  /// prompting the user and never storing the passphrase in plaintext.
  ///
  /// Returns a JSON string containing the encrypted backup (see class doc
  /// for format). This string is safe to write to a file or share.
  Future<String> exportEncrypted(String passphrase) async {
    if (passphrase.isEmpty) {
      throw ArgumentError('Passphrase must not be empty');
    }

    // 1. Get plaintext backup from the underlying service.
    final plaintext = await _backupService.exportAll();
    final plaintextBytes = utf8.encode(plaintext);

    // 2. Generate random salt and IV.
    final salt = _secureRandom(_saltLength);
    final iv = _secureRandom(16); // 128-bit IV for AES-CBC

    // 3. Derive 256-bit key from passphrase via PBKDF2.
    final key = _deriveKey(passphrase, salt);

    // 4. Encrypt with AES-256-CBC.
    final encrypter = enc.Encrypter(enc.AES(
      enc.Key(key),
      mode: enc.AESMode.cbc,
      padding: 'PKCS7',
    ));
    final encrypted = encrypter.encryptBytes(
      plaintextBytes,
      iv: enc.IV(iv),
    );

    // 5. Compute HMAC-SHA256 over (salt ‖ iv ‖ ciphertext) for integrity.
    final hmacKey = _deriveHmacKey(passphrase, salt);
    final hmacInput = Uint8List.fromList([
      ...salt,
      ...iv,
      ...encrypted.bytes,
    ]);
    final hmacDigest = Hmac(sha256, hmacKey).convert(hmacInput);

    // 6. Package into JSON envelope.
    final envelope = {
      'format': 'everything-encrypted-backup',
      'version': 1,
      'salt': base64Encode(salt),
      'iv': base64Encode(iv),
      'hmac': base64Encode(hmacDigest.bytes),
      'ciphertext': encrypted.base64,
    };

    return jsonEncode(envelope);
  }

  /// Decrypts an encrypted backup and imports it via [DataBackupService].
  ///
  /// Returns a [BackupResult] from the underlying import. Throws
  /// [EncryptedBackupException] if the passphrase is wrong, the data
  /// is tampered, or the format is unrecognized.
  Future<BackupResult> importEncrypted(
    String encryptedJson,
    String passphrase, {
    BackupStrategy strategy = BackupStrategy.replace,
  }) async {
    if (passphrase.isEmpty) {
      throw ArgumentError('Passphrase must not be empty');
    }

    // Reject oversized encrypted payloads before parsing.
    // Encrypted data is base64-encoded so the envelope is ~1.37x the plaintext.
    // Use 2x the plaintext limit as a generous upper bound.
    if (encryptedJson.length > DataBackupService.maxBackupBytes * 2) {
      final sizeMB = (encryptedJson.length / (1024 * 1024)).toStringAsFixed(1);
      throw EncryptedBackupException(
        'Encrypted backup is $sizeMB MB which exceeds the maximum allowed size.',
      );
    }

    // 1. Parse envelope.
    final dynamic decoded;
    try {
      decoded = jsonDecode(encryptedJson);
    } on FormatException {
      throw EncryptedBackupException('Invalid JSON format');
    }

    if (decoded is! Map<String, dynamic>) {
      throw EncryptedBackupException('Expected a JSON object');
    }

    if (decoded['format'] != 'everything-encrypted-backup') {
      throw EncryptedBackupException(
        'Unrecognized backup format. '
        'This may be an unencrypted backup — use DataBackupService.importAll() instead.',
      );
    }

    final version = decoded['version'] as int? ?? 0;
    if (version > 1) {
      throw EncryptedBackupException(
        'Backup version $version is newer than supported. Please update the app.',
      );
    }

    final salt = base64Decode(decoded['salt'] as String);
    final iv = base64Decode(decoded['iv'] as String);
    final storedHmac = base64Decode(decoded['hmac'] as String);
    final ciphertext = base64Decode(decoded['ciphertext'] as String);

    // 2. Verify HMAC before decryption (authenticate-then-decrypt).
    final hmacKey = _deriveHmacKey(passphrase, salt);
    final hmacInput = Uint8List.fromList([...salt, ...iv, ...ciphertext]);
    final computedHmac = Hmac(sha256, hmacKey).convert(hmacInput);

    if (!_constantTimeEquals(
        Uint8List.fromList(computedHmac.bytes), Uint8List.fromList(storedHmac))) {
      throw EncryptedBackupException(
        'Authentication failed — wrong passphrase or tampered data.',
      );
    }

    // 3. Derive key and decrypt.
    final key = _deriveKey(passphrase, salt);
    final encrypter = enc.Encrypter(enc.AES(
      enc.Key(key),
      mode: enc.AESMode.cbc,
      padding: 'PKCS7',
    ));

    final String plaintext;
    try {
      plaintext = encrypter.decrypt(
        enc.Encrypted(ciphertext),
        iv: enc.IV(iv),
      );
    } catch (_) {
      // Do NOT expose the raw exception message — it may reveal
      // padding-specific errors or other internal details that help
      // an attacker distinguish failure modes (e.g., padding oracle).
      // The HMAC was already verified above, so a decryption failure
      // here indicates data corruption rather than a wrong passphrase.
      throw EncryptedBackupException(
        'Decryption failed — the backup data may be corrupted.',
      );
    }

    // 4. Import via the underlying service.
    return _backupService.importAll(plaintext, strategy: strategy);
  }

  /// Checks whether a JSON string looks like an encrypted backup.
  ///
  /// Does not validate the contents — only checks the format marker.
  static bool isEncryptedBackup(String json) {
    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, dynamic> &&
          decoded['format'] == 'everything-encrypted-backup';
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Key derivation
  // ---------------------------------------------------------------------------

  /// Derives a 256-bit encryption key from the passphrase and salt using
  /// PBKDF2-HMAC-SHA256.
  Uint8List _deriveKey(String passphrase, List<int> salt) {
    return _pbkdf2(passphrase, salt, _pbkdf2Iterations, 32);
  }

  /// Derives a separate 256-bit HMAC key (using "hmac" suffix to ensure
  /// encryption key and HMAC key are independent).
  Uint8List _deriveHmacKey(String passphrase, List<int> salt) {
    return _pbkdf2('$passphrase:hmac', salt, _pbkdf2Iterations, 32);
  }

  /// Simple PBKDF2-HMAC-SHA256 implementation.
  Uint8List _pbkdf2(
      String passphrase, List<int> salt, int iterations, int keyLength) {
    final passphraseBytes = utf8.encode(passphrase);
    final numBlocks = (keyLength + 31) ~/ 32; // SHA-256 = 32 bytes
    final result = BytesBuilder();

    for (int block = 1; block <= numBlocks; block++) {
      final blockBytes = ByteData(4)..setUint32(0, block);
      final hmac = Hmac(sha256, passphraseBytes);

      // U1 = HMAC(passphrase, salt ‖ INT(block))
      var u = hmac
          .convert([...salt, ...blockBytes.buffer.asUint8List()]).bytes;
      var xored = Uint8List.fromList(u);

      // U2..Uiterations
      for (int i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (int j = 0; j < xored.length; j++) {
          xored[j] ^= u[j];
        }
      }

      result.add(xored);
    }

    return Uint8List.fromList(result.toBytes().sublist(0, keyLength));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Generates cryptographically secure random bytes.
  static Uint8List _secureRandom(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(length, (_) => random.nextInt(256)));
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

/// Exception thrown when encrypted backup operations fail.
class EncryptedBackupException implements Exception {
  final String message;
  EncryptedBackupException(this.message);

  @override
  String toString() => 'EncryptedBackupException: $message';
}
