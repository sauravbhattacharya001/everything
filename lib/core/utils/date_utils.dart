/// Renamed from `DateUtils` to avoid conflict with Flutter's built-in
/// `DateUtils` class from `package:flutter/material.dart`.
class AppDateUtils {
  AppDateUtils._();

  /// Returns a relative time description (e.g. "2 hours ago", "in 3 days").
  ///
  /// Handles seconds, minutes, hours, days, weeks, months, and years
  /// for both past and future dates.
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return _formatRelative(dateTime.difference(now), future: true);
    }
    return _formatRelative(difference, future: false);
  }

  /// Formats a [Duration] as a human-readable relative time string.
  ///
  /// When [future] is true, produces "in X units"; otherwise "X units ago".
  /// Durations under one minute produce "just now" regardless of direction.
  static String _formatRelative(Duration d, {required bool future}) {
    final (int value, String unit)? pair = switch (d) {
      Duration(inDays: >= 365) => (d.inDays ~/ 365, 'year'),
      Duration(inDays: >= 30) => (d.inDays ~/ 30, 'month'),
      Duration(inDays: >= 7) => (d.inDays ~/ 7, 'week'),
      Duration(inDays: > 0) => (d.inDays, 'day'),
      Duration(inHours: > 0) => (d.inHours, 'hour'),
      Duration(inMinutes: > 0) => (d.inMinutes, 'minute'),
      _ => null,
    };

    if (pair == null) return 'just now';
    final (value, unit) = pair;
    final plural = value == 1 ? unit : '${unit}s';
    return future ? 'in $value $plural' : '$value $plural ago';
  }

  /// Whether two [DateTime] values fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Strips the time component from a [DateTime], returning midnight
  /// on that day.
  static DateTime dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// Returns a `YYYY-MM-DD` string key for grouping entries by date.
  ///
  /// Many tracker services need to group or bucket entries by calendar
  /// day. This avoids the duplicated `padLeft` formatting scattered
  /// across 15+ services.
  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Safely parses a date string, returning [fallback] (default: epoch) on
  /// malformed or null input instead of throwing [FormatException].
  ///
  /// Use this in `fromJson` factories instead of `DateTime.parse` to prevent
  /// crashes from corrupted or partially-migrated database records.
  static DateTime safeParse(String? raw, [DateTime? fallback]) =>
      DateTime.tryParse(raw ?? '') ?? fallback ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Nullable variant — returns `null` when [raw] is null or unparseable.
  static DateTime? safeParseNullable(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw);
}
