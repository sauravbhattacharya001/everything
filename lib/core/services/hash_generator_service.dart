import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service for computing cryptographic hash digests of text input.
class HashGeneratorService {
  HashGeneratorService._();

  /// All supported algorithm names.
  static const List<String> algorithms = [
    'MD5',
    'SHA-1',
    'SHA-224',
    'SHA-256',
    'SHA-384',
    'SHA-512',
  ];

  /// Compute the hash of [input] using the named [algorithm].
  /// Returns the hex-encoded digest string.
  static String computeHash(String input, String algorithm) {
    final bytes = utf8.encode(input);
    Digest digest;
    switch (algorithm) {
      case 'MD5':
        digest = md5.convert(bytes);
        break;
      case 'SHA-1':
        digest = sha1.convert(bytes);
        break;
      case 'SHA-224':
        digest = sha224.convert(bytes);
        break;
      case 'SHA-256':
        digest = sha256.convert(bytes);
        break;
      case 'SHA-384':
        digest = sha384.convert(bytes);
        break;
      case 'SHA-512':
        digest = sha512.convert(bytes);
        break;
      default:
        digest = sha256.convert(bytes);
    }
    return digest.toString();
  }

  /// Compute all hashes at once, returned as a map of algorithm → hex string.
  static Map<String, String> computeAll(String input) {
    return {
      for (final algo in algorithms) algo: computeHash(input, algo),
    };
  }
}
