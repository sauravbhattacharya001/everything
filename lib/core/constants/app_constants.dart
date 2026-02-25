class AppConstants {
  static const String appName = 'Everything App';

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
