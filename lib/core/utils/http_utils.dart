import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class HttpUtils {
  /// Default request timeout to prevent hanging connections.
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Validates that a URL uses an allowed scheme and (optionally) a trusted
  /// host. This prevents SSRF attacks where a malicious API response could
  /// redirect requests to internal services (e.g., http://169.254.169.254).
  static Uri _validateUrl(String url, {bool requireTrustedHost = false}) {
    final uri = Uri.parse(url);

    if (!AppConstants.allowedSchemes.contains(uri.scheme)) {
      throw HttpSecurityException(
        'Blocked request to disallowed scheme: ${uri.scheme}. '
        'Only ${AppConstants.allowedSchemes.join(", ")} allowed.',
      );
    }

    if (requireTrustedHost &&
        !AppConstants.trustedApiHosts.contains(uri.host)) {
      throw HttpSecurityException(
        'Blocked request to untrusted host: ${uri.host}. '
        'Pagination links must point to a trusted API domain.',
      );
    }

    return uri;
  }

  static Future<Map<String, dynamic>> getRequest(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
    bool requireTrustedHost = false,
  }) async {
    final uri = _validateUrl(url, requireTrustedHost: requireTrustedHost);

    final response = await http
        .get(uri, headers: headers)
        .timeout(timeout ?? defaultTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw HttpException(response.statusCode, response.body);
    }
  }

  static Future<Map<String, dynamic>> postRequest(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = _validateUrl(url);
    final mergedHeaders = {
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    final response = await http
        .post(
          uri,
          headers: mergedHeaders,
          body: jsonEncode(body),
        )
        .timeout(timeout ?? defaultTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw HttpException(response.statusCode, response.body);
    }
  }
}

/// Structured HTTP error with status code and response body for better
/// error handling and debugging.
class HttpException implements Exception {
  final int statusCode;
  final String responseBody;

  HttpException(this.statusCode, this.responseBody);

  @override
  String toString() => 'HttpException($statusCode): $responseBody';
}

/// Security exception for blocked requests (SSRF prevention).
class HttpSecurityException implements Exception {
  final String message;

  HttpSecurityException(this.message);

  @override
  String toString() => 'HttpSecurityException: $message';
}
