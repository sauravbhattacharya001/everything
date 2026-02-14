class AppConstants {
  static const String appName = 'Everything App';
  static const String apiBaseUrl = 'https://api.example.com';
  static const String microsoftGraphBaseUrl =
      'https://graph.microsoft.com/v1.0';
  static const String dateFormat = 'yyyy-MM-dd HH:mm:ss';

  /// Allowed URL schemes for outbound HTTP requests (SSRF prevention).
  static const List<String> allowedSchemes = ['https'];

  /// Allowed hostnames for API redirect/pagination following (SSRF prevention).
  /// Only follow pagination links to these trusted domains.
  static const List<String> trustedApiHosts = [
    'graph.microsoft.com',
    'api.example.com',
  ];

  // API keys should be loaded from environment variables or a secure
  // config mechanism (e.g., --dart-define, .env files via flutter_dotenv),
  // NEVER hardcoded in source code.
  //
  // Example usage:
  //   static const String googleApiKey =
  //       String.fromEnvironment('GOOGLE_API_KEY');
  //
  // Build with:
  //   flutter run --dart-define=GOOGLE_API_KEY=your_key_here
  static const String googleApiKey =
      String.fromEnvironment('GOOGLE_API_KEY', defaultValue: '');
}
