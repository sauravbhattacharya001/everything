import 'dart:convert';

/// How often an event repeats.
enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  /// Human-readable label for the frequency.
  String get label {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }

  /// Short description with interval (e.g., "Every 2 weeks").
  String descriptionWithInterval(int interval) {
    if (interval == 1) {
      switch (this) {
        case RecurrenceFrequency.daily:
          return 'Every day';
        case RecurrenceFrequency.weekly:
          return 'Every week';
        case RecurrenceFrequency.monthly:
          return 'Every month';
        case RecurrenceFrequency.yearly:
          return 'Every year';
      }
    }
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Every $interval days';
      case RecurrenceFrequency.weekly:
        return 'Every $interval weeks';
      case RecurrenceFrequency.monthly:
        return 'Every $interval months';
      case RecurrenceFrequency.yearly:
        return 'Every $interval years';
    }
  }

  /// Converts a stored string back to a [RecurrenceFrequency].
  static RecurrenceFrequency fromString(String value) {
    return RecurrenceFrequency.values.firstWhere(
      (f) => f.name == value,
      orElse: () => RecurrenceFrequency.weekly,
    );
  }
}

/// Defines a recurrence rule for repeating events.
///
/// A recurrence rule specifies [frequency] (daily/weekly/monthly/yearly),
/// an [interval] (e.g., every 2 weeks), and an optional [endDate] after
/// which the recurrence stops. If [endDate] is null, the event repeats
/// indefinitely (occurrences are generated up to a practical limit).
class RecurrenceRule {
  /// How often the event repeats.
  final RecurrenceFrequency frequency;

  /// The interval between recurrences (e.g., 2 = every 2 weeks).
  /// Must be >= 1.
  final int interval;

  /// Optional end date for the recurrence. If null, repeats indefinitely.
  final DateTime? endDate;

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.endDate,
  });

  /// A human-readable summary of this rule (e.g., "Every 2 weeks until Mar 15, 2026").
  String get summary {
    final desc = frequency.descriptionWithInterval(interval);
    if (endDate != null) {
      final month = _monthName(endDate!.month);
      return '$desc until $month ${endDate!.day}, ${endDate!.year}';
    }
    return desc;
  }

  static String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month.clamp(1, 12) - 1];
  }

  /// Generates occurrence dates starting from [startDate].
  ///
  /// Returns up to [maxOccurrences] dates (default 52, roughly one year
  /// of weekly events). Stops early if [endDate] is set and reached.
  List<DateTime> generateOccurrences(DateTime startDate, {int maxOccurrences = 52}) {
    final occurrences = <DateTime>[startDate];
    var current = startDate;

    for (var i = 1; i < maxOccurrences; i++) {
      current = _nextOccurrence(current);
      if (endDate != null && current.isAfter(endDate!)) break;
      occurrences.add(current);
    }

    return occurrences;
  }

  /// Computes the next occurrence after [current].
  DateTime _nextOccurrence(DateTime current) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return current.add(Duration(days: interval));
      case RecurrenceFrequency.weekly:
        return current.add(Duration(days: 7 * interval));
      case RecurrenceFrequency.monthly:
        return _addMonths(current, interval);
      case RecurrenceFrequency.yearly:
        return _addMonths(current, 12 * interval);
    }
  }

  /// Adds [months] to a date, clamping to valid day-of-month.
  ///
  /// E.g., Jan 31 + 1 month = Feb 28 (or 29 in leap years).
  static DateTime _addMonths(DateTime date, int months) {
    var newMonth = date.month + months;
    var newYear = date.year;
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    // Clamp day to the last valid day of the target month
    final maxDay = DateTime(newYear, newMonth + 1, 0).day;
    final clampedDay = date.day > maxDay ? maxDay : date.day;
    return DateTime(newYear, newMonth, clampedDay, date.hour, date.minute);
  }

  /// Creates a [RecurrenceRule] from a JSON map.
  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.fromString(json['frequency'] as String),
      interval: (json['interval'] as int?) ?? 1,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
    );
  }

  /// Serializes this rule to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.name,
      'interval': interval,
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
    };
  }

  /// Serializes to a JSON string for database storage.
  String toJsonString() => jsonEncode(toJson());

  /// Deserializes from a JSON string (database storage).
  static RecurrenceRule? fromJsonString(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return RecurrenceRule.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceRule &&
          runtimeType == other.runtimeType &&
          frequency == other.frequency &&
          interval == other.interval &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(frequency, interval, endDate);

  @override
  String toString() =>
      'RecurrenceRule(frequency: ${frequency.name}, interval: $interval, endDate: $endDate)';
}
