import 'package:intl/intl.dart';

/// Renamed from `DateUtils` to avoid conflict with Flutter's built-in
/// `DateUtils` class from `package:flutter/material.dart`.
class AppDateUtils {
  /// Formats an ISO-8601 date string into a human-readable format.
  ///
  /// Returns `'Invalid date'` if [isoDate] cannot be parsed, rather than
  /// throwing a [FormatException].
  static String formatDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate);
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    } on FormatException {
      return 'Invalid date';
    }
  }

  static String getCurrentDateTime() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
  }

  /// Returns a relative time description (e.g. "2 hours ago", "in 3 days").
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      final future = dateTime.difference(now);
      if (future.inDays > 0) return 'in ${future.inDays} day${future.inDays == 1 ? '' : 's'}';
      if (future.inHours > 0) return 'in ${future.inHours} hour${future.inHours == 1 ? '' : 's'}';
      if (future.inMinutes > 0) return 'in ${future.inMinutes} minute${future.inMinutes == 1 ? '' : 's'}';
      return 'just now';
    }

    if (difference.inDays > 0) return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    if (difference.inHours > 0) return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    return 'just now';
  }
}
