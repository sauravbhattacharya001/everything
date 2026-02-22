import 'dart:convert';

/// Predefined reminder intervals before an event.
///
/// Each value represents a specific time offset before the event's
/// scheduled date/time when the user wants to be reminded.
enum ReminderOffset {
  atTime,
  fiveMinutes,
  fifteenMinutes,
  thirtyMinutes,
  oneHour,
  twoHours,
  oneDay,
  twoDays,
  oneWeek;

  /// Human-readable label for display.
  String get label {
    switch (this) {
      case ReminderOffset.atTime:
        return 'At time of event';
      case ReminderOffset.fiveMinutes:
        return '5 minutes before';
      case ReminderOffset.fifteenMinutes:
        return '15 minutes before';
      case ReminderOffset.thirtyMinutes:
        return '30 minutes before';
      case ReminderOffset.oneHour:
        return '1 hour before';
      case ReminderOffset.twoHours:
        return '2 hours before';
      case ReminderOffset.oneDay:
        return '1 day before';
      case ReminderOffset.twoDays:
        return '2 days before';
      case ReminderOffset.oneWeek:
        return '1 week before';
    }
  }

  /// Short label for compact display (e.g., chips).
  String get shortLabel {
    switch (this) {
      case ReminderOffset.atTime:
        return 'At time';
      case ReminderOffset.fiveMinutes:
        return '5m';
      case ReminderOffset.fifteenMinutes:
        return '15m';
      case ReminderOffset.thirtyMinutes:
        return '30m';
      case ReminderOffset.oneHour:
        return '1h';
      case ReminderOffset.twoHours:
        return '2h';
      case ReminderOffset.oneDay:
        return '1d';
      case ReminderOffset.twoDays:
        return '2d';
      case ReminderOffset.oneWeek:
        return '1w';
    }
  }

  /// The [Duration] to subtract from the event time.
  Duration get duration {
    switch (this) {
      case ReminderOffset.atTime:
        return Duration.zero;
      case ReminderOffset.fiveMinutes:
        return const Duration(minutes: 5);
      case ReminderOffset.fifteenMinutes:
        return const Duration(minutes: 15);
      case ReminderOffset.thirtyMinutes:
        return const Duration(minutes: 30);
      case ReminderOffset.oneHour:
        return const Duration(hours: 1);
      case ReminderOffset.twoHours:
        return const Duration(hours: 2);
      case ReminderOffset.oneDay:
        return const Duration(days: 1);
      case ReminderOffset.twoDays:
        return const Duration(days: 2);
      case ReminderOffset.oneWeek:
        return const Duration(days: 7);
    }
  }

  /// Calculates the notification time given an event date.
  DateTime notificationTime(DateTime eventDate) {
    return eventDate.subtract(duration);
  }

  /// Whether the reminder is still in the future for the given event date.
  bool isUpcoming(DateTime eventDate) {
    return notificationTime(eventDate).isAfter(DateTime.now());
  }

  /// Converts the offset name to a string for serialization.
  String toJsonValue() => name;

  /// Parses a stored string back to a [ReminderOffset].
  static ReminderOffset fromString(String value) {
    return ReminderOffset.values.firstWhere(
      (r) => r.name == value,
      orElse: () => ReminderOffset.fifteenMinutes,
    );
  }
}

/// A set of reminders attached to an event.
///
/// Wraps a list of [ReminderOffset] values with serialization support.
/// An event can have zero or more reminders. Duplicates are prevented.
class ReminderSettings {
  final List<ReminderOffset> offsets;

  const ReminderSettings({this.offsets = const []});

  /// Default reminder (15 minutes before).
  static const ReminderSettings defaultReminder = ReminderSettings(
    offsets: [ReminderOffset.fifteenMinutes],
  );

  /// No reminders.
  static const ReminderSettings none = ReminderSettings();

  /// Whether any reminders are set.
  bool get hasReminders => offsets.isNotEmpty;

  /// Number of reminders.
  int get count => offsets.length;

  /// Add a reminder offset (no duplicates).
  ReminderSettings addReminder(ReminderOffset offset) {
    if (offsets.contains(offset)) return this;
    return ReminderSettings(
      offsets: [...offsets, offset]..sort((a, b) => a.index.compareTo(b.index)),
    );
  }

  /// Remove a reminder offset.
  ReminderSettings removeReminder(ReminderOffset offset) {
    return ReminderSettings(
      offsets: offsets.where((o) => o != offset).toList(),
    );
  }

  /// Toggle a reminder offset on/off.
  ReminderSettings toggleReminder(ReminderOffset offset) {
    if (offsets.contains(offset)) {
      return removeReminder(offset);
    } else {
      return addReminder(offset);
    }
  }

  /// Get all upcoming notification times for an event date.
  List<DateTime> notificationTimes(DateTime eventDate) {
    return offsets
        .map((o) => o.notificationTime(eventDate))
        .where((t) => t.isAfter(DateTime.now()))
        .toList()
      ..sort();
  }

  /// The next upcoming notification time, or null if none.
  DateTime? nextNotificationTime(DateTime eventDate) {
    final times = notificationTimes(eventDate);
    return times.isEmpty ? null : times.first;
  }

  /// Display summary (e.g., "15m, 1h, 1d").
  String get summary {
    if (offsets.isEmpty) return 'None';
    return offsets.map((o) => o.shortLabel).join(', ');
  }

  /// Serialize to JSON string for storage.
  String toJsonString() {
    return jsonEncode(offsets.map((o) => o.toJsonValue()).toList());
  }

  /// Deserialize from JSON string.
  factory ReminderSettings.fromJsonString(String? json) {
    if (json == null || json.isEmpty) return ReminderSettings.none;
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      final offsets = decoded
          .map((v) => ReminderOffset.fromString(v as String))
          .toList();
      return ReminderSettings(offsets: offsets);
    } catch (_) {
      return ReminderSettings.none;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderSettings &&
          offsets.length == other.offsets.length &&
          offsets.every((o) => other.offsets.contains(o));

  @override
  int get hashCode => Object.hashAll(offsets);

  @override
  String toString() => 'ReminderSettings(${summary})';
}
