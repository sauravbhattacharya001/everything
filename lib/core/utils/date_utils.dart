/// Renamed from `DateUtils` to avoid conflict with Flutter's built-in
/// `DateUtils` class from `package:flutter/material.dart`.
class AppDateUtils {
  /// Returns a relative time description (e.g. "2 hours ago", "in 3 days").
  ///
  /// Handles seconds, minutes, hours, days, weeks, months, and years
  /// for both past and future dates.
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return _formatFuture(dateTime.difference(now));
    }
    return _formatPast(difference);
  }

  static String _formatPast(Duration difference) {
    if (difference.inDays >= 365) {
      final years = difference.inDays ~/ 365;
      return '$years year${years == 1 ? '' : 's'} ago';
    }
    if (difference.inDays >= 30) {
      final months = difference.inDays ~/ 30;
      return '$months month${months == 1 ? '' : 's'} ago';
    }
    if (difference.inDays >= 7) {
      final weeks = difference.inDays ~/ 7;
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
    return 'just now';
  }

  static String _formatFuture(Duration future) {
    if (future.inDays >= 365) {
      final years = future.inDays ~/ 365;
      return 'in $years year${years == 1 ? '' : 's'}';
    }
    if (future.inDays >= 30) {
      final months = future.inDays ~/ 30;
      return 'in $months month${months == 1 ? '' : 's'}';
    }
    if (future.inDays >= 7) {
      final weeks = future.inDays ~/ 7;
      return 'in $weeks week${weeks == 1 ? '' : 's'}';
    }
    if (future.inDays > 0) {
      return 'in ${future.inDays} day${future.inDays == 1 ? '' : 's'}';
    }
    if (future.inHours > 0) {
      return 'in ${future.inHours} hour${future.inHours == 1 ? '' : 's'}';
    }
    if (future.inMinutes > 0) {
      return 'in ${future.inMinutes} minute${future.inMinutes == 1 ? '' : 's'}';
    }
    return 'just now';
  }

  /// Whether two [DateTime] values fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Strips the time component from a [DateTime], returning midnight
  /// on that day.
  static DateTime dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
