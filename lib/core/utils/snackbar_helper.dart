import 'package:flutter/material.dart';

/// Centralised SnackBar helper to ensure consistent feedback across the app.
///
/// **Before (repeated in 50+ screens):**
/// ```dart
/// ScaffoldMessenger.of(context).showSnackBar(
///   SnackBar(
///     content: Text('Item saved!'),
///     behavior: SnackBarBehavior.floating,
///     duration: Duration(seconds: 2),
///   ),
/// );
/// ```
///
/// **After:**
/// ```dart
/// SnackBarHelper.show(context, 'Item saved!');
/// SnackBarHelper.success(context, 'Item saved!');
/// SnackBarHelper.error(context, 'Something went wrong');
/// ```
class SnackBarHelper {
  SnackBarHelper._();

  static const _defaultDuration = Duration(seconds: 2);
  static const _shortDuration = Duration(seconds: 1);

  /// Show a standard informational snackbar.
  static void show(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _display(context, message, duration: duration, action: action);
  }

  /// Show a success snackbar (green background).
  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _display(
      context,
      message,
      backgroundColor: Colors.green,
      duration: duration,
      action: action,
    );
  }

  /// Show an error snackbar (red background).
  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _display(
      context,
      message,
      backgroundColor: Colors.red,
      duration: duration,
      action: action,
    );
  }

  /// Show a brief confirmation (1 second, floating).
  static void brief(BuildContext context, String message) {
    _display(context, message, duration: _shortDuration);
  }

  static void _display(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: duration ?? _defaultDuration,
          backgroundColor: backgroundColor,
          action: action,
        ),
      );
  }
}
