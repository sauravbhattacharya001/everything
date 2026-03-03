/// Event Snooze Service — postpone events by preset intervals with
/// full snooze history tracking, serial-snooze detection, and smart
/// reschedule suggestions.
///
/// Use this when a user wants to push an event forward: "remind me in
/// 15 minutes", "move to tomorrow morning", "push to next week".
///
/// Key concepts:
///   - **Snooze Option**: A named preset duration (15 min, 1 hour,
///     tomorrow 9 AM, next Monday 9 AM, etc.).
///   - **Snooze Record**: Tracks each postponement — when, by how much,
///     and optionally why.
///   - **Snooze Summary**: Aggregated stats for an event — total snooze
///     count, cumulative delay, serial-snooze flag.
///   - **Serial Snooze**: An event snoozed 3+ times in 24 hours,
///     suggesting the user should reschedule rather than keep snoozing.

import '../../models/event_model.dart';

// ─── Data Classes ───────────────────────────────────────────────

/// A preset snooze duration option presented to the user.
class SnoozeOption {
  /// Machine-readable identifier (e.g., '15min', '1hr', 'tomorrow').
  final String id;

  /// Human-readable label (e.g., '15 minutes', 'Tomorrow morning').
  final String label;

  /// Icon suggestion for UI rendering.
  final String icon;

  /// The category this option belongs to.
  final SnoozeCategory category;

  const SnoozeOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SnoozeOption && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SnoozeOption($id: $label)';
}

/// Categories for grouping snooze options in the UI.
enum SnoozeCategory {
  quick,    // 15 min, 30 min, 1 hr
  later,    // 2 hrs, 4 hrs, tonight
  nextDay,  // tomorrow morning, tomorrow afternoon
  nextWeek, // next Monday, next week same day
}

/// A record of a single snooze action on an event.
class SnoozeRecord {
  /// When the snooze was performed.
  final DateTime snoozedAt;

  /// The event's original date before this snooze.
  final DateTime originalDate;

  /// The event's new date after this snooze.
  final DateTime newDate;

  /// Which snooze option was used.
  final String optionId;

  /// Optional reason or note from the user.
  final String? reason;

  const SnoozeRecord({
    required this.snoozedAt,
    required this.originalDate,
    required this.newDate,
    required this.optionId,
    this.reason,
  });

  /// How much the event was pushed forward.
  Duration get delay => newDate.difference(originalDate);

  /// Human-readable delay description.
  String get delayDescription {
    final d = delay;
    if (d.inDays > 0) {
      return d.inDays == 1 ? '1 day' : '${d.inDays} days';
    }
    if (d.inHours > 0) {
      return d.inHours == 1 ? '1 hour' : '${d.inHours} hours';
    }
    return d.inMinutes == 1 ? '1 minute' : '${d.inMinutes} minutes';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SnoozeRecord &&
          snoozedAt == other.snoozedAt &&
          originalDate == other.originalDate &&
          newDate == other.newDate &&
          optionId == other.optionId;

  @override
  int get hashCode =>
      Object.hash(snoozedAt, originalDate, newDate, optionId);

  @override
  String toString() =>
      'SnoozeRecord($optionId: ${_fmtDateTime(originalDate)} → ${_fmtDateTime(newDate)})';
}

/// Aggregated snooze statistics for a single event.
class SnoozeSummary {
  /// The event being summarized.
  final String eventId;

  /// Complete snooze history, oldest first.
  final List<SnoozeRecord> history;

  const SnoozeSummary({
    required this.eventId,
    required this.history,
  });

  /// How many times this event has been snoozed.
  int get snoozeCount => history.length;

  /// Whether the event has ever been snoozed.
  bool get wasSnoozed => history.isNotEmpty;

  /// Total cumulative delay across all snoozes.
  Duration get totalDelay {
    if (history.isEmpty) return Duration.zero;
    return history.first.originalDate
        .difference(history.first.originalDate)
        .abs() +
        history.fold<Duration>(
          Duration.zero,
          (sum, r) => sum + r.delay,
        );
  }

  /// The event's very first original date (before any snoozes).
  DateTime? get firstOriginalDate =>
      history.isEmpty ? null : history.first.originalDate;

  /// The most recent snooze record, or null if never snoozed.
  SnoozeRecord? get lastSnooze =>
      history.isEmpty ? null : history.last;

  /// Human-readable summary.
  String get description {
    if (history.isEmpty) return 'Never snoozed';
    final d = totalDelay;
    final delayStr = d.inDays > 0
        ? '${d.inDays}d ${d.inHours % 24}h'
        : d.inHours > 0
            ? '${d.inHours}h ${d.inMinutes % 60}m'
            : '${d.inMinutes}m';
    return 'Snoozed $snoozeCount time${snoozeCount == 1 ? '' : 's'} '
        '(total delay: $delayStr)';
  }

  @override
  String toString() => 'SnoozeSummary($eventId: $description)';
}

/// Result of a serial-snooze check with actionable advice.
class SerialSnoozeAlert {
  /// The event that's being serially snoozed.
  final String eventId;

  /// How many times snoozed in the detection window.
  final int recentSnoozeCount;

  /// The detection window.
  final Duration window;

  /// Suggested action for the user.
  final String suggestion;

  /// Severity: 'warning' (3 snoozes) or 'critical' (5+).
  final String severity;

  const SerialSnoozeAlert({
    required this.eventId,
    required this.recentSnoozeCount,
    required this.window,
    required this.suggestion,
    required this.severity,
  });

  @override
  String toString() =>
      'SerialSnoozeAlert($eventId: $severity — $suggestion)';
}

// ─── Service ────────────────────────────────────────────────────

/// Manages event snoozing with preset options, history tracking,
/// and serial-snooze detection.
class SnoozeService {
  /// Current time provider (injectable for testing).
  final DateTime Function() _now;

  /// Per-event snooze history, keyed by event ID.
  final Map<String, List<SnoozeRecord>> _history = {};

  /// Creates a new snooze service.
  ///
  /// [now] is an optional clock function for testability; defaults
  /// to [DateTime.now].
  SnoozeService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  // ─── Snooze Options ─────────────────────────────────────────

  /// All available snooze options.
  static const List<SnoozeOption> allOptions = [
    SnoozeOption(
      id: '15min',
      label: '15 minutes',
      icon: '⏰',
      category: SnoozeCategory.quick,
    ),
    SnoozeOption(
      id: '30min',
      label: '30 minutes',
      icon: '⏰',
      category: SnoozeCategory.quick,
    ),
    SnoozeOption(
      id: '1hr',
      label: '1 hour',
      icon: '🕐',
      category: SnoozeCategory.quick,
    ),
    SnoozeOption(
      id: '2hr',
      label: '2 hours',
      icon: '🕑',
      category: SnoozeCategory.later,
    ),
    SnoozeOption(
      id: '4hr',
      label: '4 hours',
      icon: '🕓',
      category: SnoozeCategory.later,
    ),
    SnoozeOption(
      id: 'tonight',
      label: 'Tonight (8 PM)',
      icon: '🌙',
      category: SnoozeCategory.later,
    ),
    SnoozeOption(
      id: 'tomorrow_morning',
      label: 'Tomorrow morning (9 AM)',
      icon: '🌅',
      category: SnoozeCategory.nextDay,
    ),
    SnoozeOption(
      id: 'tomorrow_afternoon',
      label: 'Tomorrow afternoon (2 PM)',
      icon: '☀️',
      category: SnoozeCategory.nextDay,
    ),
    SnoozeOption(
      id: 'next_monday',
      label: 'Next Monday (9 AM)',
      icon: '📅',
      category: SnoozeCategory.nextWeek,
    ),
    SnoozeOption(
      id: 'next_week',
      label: 'Next week, same day',
      icon: '📆',
      category: SnoozeCategory.nextWeek,
    ),
  ];

  /// Returns options filtered by category.
  static List<SnoozeOption> optionsByCategory(SnoozeCategory category) =>
      allOptions.where((o) => o.category == category).toList();

  // ─── Snooze Computation ─────────────────────────────────────

  /// Computes the new date for an event snoozed with the given option.
  ///
  /// For relative options (15min, 1hr, etc.), the delay is added to
  /// the event's current [date]. For absolute options (tomorrow 9 AM,
  /// tonight 8 PM), the date is set to the next occurrence of that
  /// time slot.
  ///
  /// Returns null if the option ID is unknown.
  DateTime? computeSnoozeDate(EventModel event, String optionId) {
    final now = _now();
    switch (optionId) {
      case '15min':
        return event.date.add(const Duration(minutes: 15));
      case '30min':
        return event.date.add(const Duration(minutes: 30));
      case '1hr':
        return event.date.add(const Duration(hours: 1));
      case '2hr':
        return event.date.add(const Duration(hours: 2));
      case '4hr':
        return event.date.add(const Duration(hours: 4));
      case 'tonight':
        final tonight = DateTime(now.year, now.month, now.day, 20);
        // If it's already past 8 PM, push to tomorrow 8 PM
        return tonight.isAfter(now) ? tonight : tonight.add(const Duration(days: 1));
      case 'tomorrow_morning':
        final tomorrow = now.add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
      case 'tomorrow_afternoon':
        final tomorrow = now.add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14);
      case 'next_monday':
        final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
        final mondayOffset = daysUntilMonday == 0 ? 7 : daysUntilMonday;
        final nextMon = now.add(Duration(days: mondayOffset));
        return DateTime(nextMon.year, nextMon.month, nextMon.day, 9);
      case 'next_week':
        final nextWeek = event.date.add(const Duration(days: 7));
        return nextWeek;
      default:
        return null;
    }
  }

  /// Snoozes an event, returning a new [EventModel] with the updated date.
  ///
  /// Records the snooze in history and adjusts the end date to maintain
  /// the original event duration. Returns null if the option ID is invalid.
  EventModel? snooze(EventModel event, String optionId, {String? reason}) {
    final newDate = computeSnoozeDate(event, optionId);
    if (newDate == null) return null;

    // Record the snooze
    final record = SnoozeRecord(
      snoozedAt: _now(),
      originalDate: event.date,
      newDate: newDate,
      optionId: optionId,
      reason: reason,
    );
    _history.putIfAbsent(event.id, () => []).add(record);

    // Compute new end date preserving duration
    DateTime? newEndDate;
    if (event.endDate != null) {
      final duration = event.endDate!.difference(event.date);
      newEndDate = newDate.add(duration);
    }

    return event.copyWith(date: newDate, endDate: newEndDate);
  }

  // ─── History & Summary ──────────────────────────────────────

  /// Returns the full snooze history for an event.
  List<SnoozeRecord> getHistory(String eventId) =>
      List.unmodifiable(_history[eventId] ?? const []);

  /// Returns an aggregated summary for an event.
  SnoozeSummary getSummary(String eventId) => SnoozeSummary(
        eventId: eventId,
        history: getHistory(eventId),
      );

  /// Returns the number of times an event has been snoozed.
  int getSnoozeCount(String eventId) =>
      _history[eventId]?.length ?? 0;

  /// Returns all events that have been snoozed at least once.
  List<String> getSnoozedEventIds() =>
      _history.keys.where((id) => _history[id]!.isNotEmpty).toList();

  /// Clears snooze history for an event (e.g., when it's completed).
  void clearHistory(String eventId) => _history.remove(eventId);

  /// Clears all snooze history.
  void clearAll() => _history.clear();

  // ─── Serial Snooze Detection ────────────────────────────────

  /// Checks if an event is being "serially snoozed" — postponed
  /// repeatedly in a short time window, suggesting the user should
  /// reschedule or cancel instead.
  ///
  /// [window] controls the lookback period (default: 24 hours).
  /// [threshold] is the minimum snoozes within the window to trigger
  /// (default: 3).
  SerialSnoozeAlert? checkSerialSnooze(
    String eventId, {
    Duration window = const Duration(hours: 24),
    int threshold = 3,
  }) {
    final records = _history[eventId];
    if (records == null || records.length < threshold) return null;

    final now = _now();
    final cutoff = now.subtract(window);
    final recent = records.where((r) => r.snoozedAt.isAfter(cutoff)).toList();

    if (recent.length < threshold) return null;

    final severity = recent.length >= 5 ? 'critical' : 'warning';
    final suggestion = severity == 'critical'
        ? 'This event has been snoozed ${recent.length} times in '
            '${_formatDuration(window)}. Consider cancelling or rescheduling '
            'to a time that actually works.'
        : 'This event has been snoozed ${recent.length} times in '
            '${_formatDuration(window)}. Maybe pick a better time slot?';

    return SerialSnoozeAlert(
      eventId: eventId,
      recentSnoozeCount: recent.length,
      window: window,
      suggestion: suggestion,
      severity: severity,
    );
  }

  /// Checks all tracked events for serial snoozing.
  List<SerialSnoozeAlert> checkAllSerialSnoozes({
    Duration window = const Duration(hours: 24),
    int threshold = 3,
  }) {
    final alerts = <SerialSnoozeAlert>[];
    for (final eventId in _history.keys) {
      final alert = checkSerialSnooze(
        eventId,
        window: window,
        threshold: threshold,
      );
      if (alert != null) alerts.add(alert);
    }
    return alerts;
  }

  // ─── Smart Suggestions ──────────────────────────────────────

  /// Returns contextually appropriate snooze options based on the
  /// current time and event timing.
  ///
  /// - Past events: only forward-looking options (tomorrow, next week)
  /// - Evening events: skip "tonight" if it's already past 8 PM
  /// - Short-term options filtered if they'd result in a date in the past
  List<SnoozeOption> suggestOptions(EventModel event) {
    final now = _now();
    final result = <SnoozeOption>[];

    for (final option in allOptions) {
      final newDate = computeSnoozeDate(event, option.id);
      if (newDate == null) continue;
      // Only include options that move the event into the future
      if (newDate.isAfter(now)) {
        result.add(option);
      }
    }
    return result;
  }

  /// Returns the most popular snooze option for a given event,
  /// based on its history. Returns null if never snoozed.
  String? getMostUsedOption(String eventId) {
    final records = _history[eventId];
    if (records == null || records.isEmpty) return null;

    final counts = <String, int>{};
    for (final r in records) {
      counts[r.optionId] = (counts[r.optionId] ?? 0) + 1;
    }

    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }
}

// ─── Private Helpers ──────────────────────────────────────────

String _fmtDateTime(DateTime dt) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '${months[dt.month - 1]} ${dt.day} $h:$m';
}

String _formatDuration(Duration d) {
  if (d.inDays > 0) return '${d.inDays} day${d.inDays == 1 ? '' : 's'}';
  if (d.inHours > 0) return '${d.inHours} hour${d.inHours == 1 ? '' : 's'}';
  return '${d.inMinutes} minute${d.inMinutes == 1 ? '' : 's'}';
}
