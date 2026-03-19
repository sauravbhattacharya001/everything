import 'package:flutter/material.dart';
import 'date_utils.dart';

/// Shared formatting utilities extracted from screen widgets and services
/// to eliminate duplication and ensure consistent behavior.
///
/// See: https://github.com/sauravbhattacharya001/everything/issues/31
class FormattingUtils {
  FormattingUtils._();

  // ─── Time Formatting ─────────────────────────────────────────

  /// Formats a [DateTime] as 12-hour time: "9:05 AM".
  static String formatTime12h(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  /// Formats a [DateTime] as 24-hour time: "09:05".
  static String formatTime24h(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Formats a time range in 12-hour format: "9:00 AM – 10:30 AM".
  static String formatTimeRange12h(DateTime start, DateTime end) {
    return '${formatTime12h(start)} – ${formatTime12h(end)}';
  }

  // ─── Date Comparison ─────────────────────────────────────────

  /// Returns `true` if [a] and [b] fall on the same calendar day.
  ///
  /// Delegates to [AppDateUtils.isSameDay] to avoid duplication.
  static bool sameDay(DateTime a, DateTime b) => AppDateUtils.isSameDay(a, b);

  // ─── Productivity / Completion Visuals ────────────────────────

  /// Maps a completion rate (0–100) to a color gradient
  /// from red (low) to green (high).
  static Color completionColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 75) return Colors.lightGreen;
    if (rate >= 50) return Colors.orange;
    if (rate >= 25) return Colors.deepOrange;
    return Colors.red;
  }

  /// Returns an icon representing a productivity label.
  static IconData productivityIcon(String label) {
    return switch (label) {
      'Excellent' => Icons.emoji_events,
      'Great' => Icons.thumb_up,
      'Good' => Icons.sentiment_satisfied,
      'Fair' => Icons.sentiment_neutral,
      _ => Icons.sentiment_dissatisfied,
    };
  }

  /// Returns a color representing a productivity label.
  static Color productivityColor(String label) {
    return switch (label) {
      'Excellent' => Colors.green,
      'Great' => Colors.lightGreen,
      'Good' => Colors.orange,
      'Fair' => Colors.deepOrange,
      _ => Colors.red,
    };
  }
}
