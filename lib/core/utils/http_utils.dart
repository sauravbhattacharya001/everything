import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpUtils {
  /// Default request timeout to prevent hanging connections.
  static const Duration defaultTimeout = Duration(seconds: 30);

  static Future<Map<String, dynamic>> getRequest(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final response = await http
        .get(Uri.parse(url), headers: headers)
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
    final mergedHeaders = {
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    final response = await http
        .post(
          Uri.parse(url),
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
