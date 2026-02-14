import '../utils/http_utils.dart';
import '../constants/app_constants.dart';

class GraphService {
  final String accessToken;

  /// Maximum number of pages to fetch to prevent infinite loops
  /// in case of malformed `@odata.nextLink` responses.
  static const int _maxPages = 50;

  GraphService(this.accessToken);

  /// Fetches all calendar events from Microsoft Graph API with pagination.
  ///
  /// Follows `@odata.nextLink` URLs to retrieve all pages of results.
  /// Validates response structure before casting to prevent runtime errors
  /// from malformed or error responses.
  ///
  /// Throws [GraphServiceException] if the response is missing the
  /// expected `value` field or contains an API error.
  Future<List<Map<String, dynamic>>> fetchCalendarEvents() async {
    final allEvents = <Map<String, dynamic>>[];
    String? nextUrl = '${AppConstants.microsoftGraphBaseUrl}/me/events?\$top=50';
    int page = 0;

    while (nextUrl != null && page < _maxPages) {
      // Use requireTrustedHost for pagination links to prevent SSRF —
      // a malicious API response could set @odata.nextLink to an internal
      // service URL (e.g., cloud metadata endpoint).
      final response = await HttpUtils.getRequest(
        nextUrl,
        headers: {'Authorization': 'Bearer $accessToken'},
        requireTrustedHost: page > 0, // First request is our own URL; subsequent are from API
      );

      // Validate response structure — the Graph API returns errors as
      // { "error": { "code": "...", "message": "..." } } rather than
      // the expected { "value": [...] } shape.
      if (response.containsKey('error')) {
        final error = response['error'];
        final code = error is Map ? error['code'] ?? 'unknown' : 'unknown';
        final message = error is Map ? error['message'] ?? '' : '$error';
        throw GraphServiceException(
          'Graph API error ($code): $message',
        );
      }

      final value = response['value'];
      if (value == null || value is! List) {
        throw GraphServiceException(
          'Unexpected Graph API response: missing or invalid "value" field',
        );
      }

      allEvents.addAll(List<Map<String, dynamic>>.from(value));

      // Follow pagination link if present
      nextUrl = response['@odata.nextLink'] as String?;
      page++;
    }

    return allEvents;
  }
}

/// Exception thrown when the Microsoft Graph API returns an error or
/// an unexpected response format.
class GraphServiceException implements Exception {
  final String message;
  GraphServiceException(this.message);

  @override
  String toString() => 'GraphServiceException: $message';
}
