/// Application-wide constants and configuration values.
///
/// Sensitive values (API keys, secrets) are loaded from environment
/// variables at compile time via `--dart-define`, never hardcoded.
class AppConstants {
  /// Display name used in the app bar and window title.
  static const String appName = 'Everything App';

  /// Google API key for Maps, Calendar, or other Google services.
  ///
  /// Must be provided at build time:
  /// ```sh
  /// flutter run --dart-define=GOOGLE_API_KEY=your_key_here
  /// ```
  ///
  /// Defaults to an empty string when not set, which disables
  /// Google-dependent features gracefully.
  static const String googleApiKey =
      String.fromEnvironment('GOOGLE_API_KEY', defaultValue: '');
}
