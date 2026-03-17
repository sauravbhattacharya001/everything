/// Free Slot Finder — discovers available time slots in a user's calendar.
///
/// Given a list of existing events and constraints (date range, working hours,
/// minimum slot duration), this service finds gaps where new events can be
/// scheduled. Supports configurable working hours, buffer time between events,
/// and preferred slot durations.
///
/// Use this to answer: "When am I free this week?", "Find me a 2-hour slot
/// tomorrow", "What's my availability for the next 3 days?"

import '../../models/event_model.dart';
import '../utils/formatting_utils.dart';

/// Represents a free time slot in the calendar.
class FreeSlot {
  /// Start of the free slot.
  final DateTime start;

  /// End of the free slot.
  final DateTime end;

  /// Duration of this free slot.
  Duration get duration => end.difference(start);

  /// Duration in minutes for convenience.
  int get durationMinutes => duration.inMinutes;

  /// A human-friendly label like "Mon 9:00 AM – 11:30 AM (2h 30m)".
  String get label {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = days[start.weekday - 1];
    final startStr = FormattingUtils.formatTime12h(start);
    final endStr = FormattingUtils.formatTime12h(end);
    final hrs = duration.inHours;
    final mins = duration.inMinutes % 60;
    final durStr = hrs > 0
        ? (mins > 0 ? '${hrs}h ${mins}m' : '${hrs}h')
        : '${mins}m';
    return '$day $startStr – $endStr ($durStr)';
  }

  const FreeSlot({required this.start, required this.end});

  /// Whether this slot can fit an event of the given duration.
  bool canFit(Duration eventDuration) => duration >= eventDuration;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FreeSlot && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'FreeSlot($label)';
}

/// Configuration for working hours on a given day.
class WorkingHours {
  /// Hour the work day starts (0-23).
  final int startHour;

  /// Minute the work day starts (0-59).
  final int startMinute;

  /// Hour the work day ends (0-23).
  final int endHour;

  /// Minute the work day ends (0-59).
  final int endMinute;

  const WorkingHours({
    this.startHour = 9,
    this.startMinute = 0,
    this.endHour = 17,
    this.endMinute = 0,
  });

  /// Total working minutes in the day.
  int get totalMinutes =>
      (endHour * 60 + endMinute) - (startHour * 60 + startMinute);

  /// Creates the start-of-day DateTime for a given date.
  DateTime startOn(DateTime date) =>
      DateTime(date.year, date.month, date.day, startHour, startMinute);

  /// Creates the end-of-day DateTime for a given date.
  DateTime endOn(DateTime date) =>
      DateTime(date.year, date.month, date.day, endHour, endMinute);
}

/// Result of a free slot search with summary statistics.
class FreeSlotResult {
  /// All free slots found.
  final List<FreeSlot> slots;

  /// The search date range start.
  final DateTime rangeStart;

  /// The search date range end.
  final DateTime rangeEnd;

  /// Minimum duration filter applied.
  final Duration minimumDuration;

  /// Total free time across all slots.
  Duration get totalFreeTime =>
      slots.fold(Duration.zero, (sum, s) => sum + s.duration);

  /// Total free minutes.
  int get totalFreeMinutes => totalFreeTime.inMinutes;

  /// Number of free slots found.
  int get slotCount => slots.length;

  /// The longest available slot, or null if none found.
  FreeSlot? get longestSlot => slots.isEmpty
      ? null
      : slots.reduce((a, b) => a.duration > b.duration ? a : b);

  /// Slots grouped by date.
  Map<DateTime, List<FreeSlot>> get slotsByDate {
    final map = <DateTime, List<FreeSlot>>{};
    for (final slot in slots) {
      final dateKey = DateTime(slot.start.year, slot.start.month, slot.start.day);
      map.putIfAbsent(dateKey, () => []).add(slot);
    }
    return map;
  }

  /// Slots that can fit the given duration.
  List<FreeSlot> slotsForDuration(Duration needed) =>
      slots.where((s) => s.canFit(needed)).toList();

  const FreeSlotResult({
    required this.slots,
    required this.rangeStart,
    required this.rangeEnd,
    required this.minimumDuration,
  });
}

/// Service that finds free time slots in a calendar.
class FreeSlotFinder {
  /// Default working hours (9 AM – 5 PM).
  static const defaultWorkingHours = WorkingHours();

  /// Finds free slots within the given date range.
  ///
  /// [events] — existing calendar events to work around.
  /// [rangeStart] — beginning of the search range.
  /// [rangeEnd] — end of the search range.
  /// [minimumDuration] — minimum slot duration to include (default 30 min).
  /// [bufferMinutes] — buffer time to leave around each event (default 0).
  /// [workingHours] — per-weekday working hours (1=Mon..7=Sun). Days not
  ///   in the map are treated as non-working (weekends by default).
  /// [includeWeekends] — if true, applies default working hours to Sat/Sun.
  FreeSlotResult findSlots({
    required List<EventModel> events,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    Duration minimumDuration = const Duration(minutes: 30),
    int bufferMinutes = 0,
    Map<int, WorkingHours>? workingHours,
    bool includeWeekends = false,
  }) {
    // Build working hours map (1=Monday..7=Sunday)
    final hours = workingHours ??
        {
          for (var d = 1; d <= 5; d++) d: defaultWorkingHours,
          if (includeWeekends) ...{
            6: defaultWorkingHours,
            7: defaultWorkingHours,
          },
        };

    // Filter and sort events that overlap our range
    final relevant = events
        .where((e) => e.date.isBefore(rangeEnd) &&
            (e.endDate ?? e.date.add(const Duration(hours: 1)))
                .isAfter(rangeStart))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final buffer = Duration(minutes: bufferMinutes);
    final allSlots = <FreeSlot>[];

    // Pre-compute end times once instead of re-deriving them per-day.
    final relevantEnds = relevant
        .map((e) => e.endDate ?? e.date.add(const Duration(hours: 1)))
        .toList();

    // Iterate day by day
    var current = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final endDay = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);

    // Sliding index: since both days and events are sorted, we can
    // avoid re-scanning from the start of `relevant` on each day.
    var scanStart = 0;

    while (!current.isAfter(endDay)) {
      final dayHours = hours[current.weekday];
      if (dayHours != null) {
        final dayStart = dayHours.startOn(current);
        final dayEnd = dayHours.endOn(current);

        // Advance scanStart past events whose end is at or before dayStart.
        // These events can never overlap any future day either, so we can
        // permanently skip them.
        while (scanStart < relevant.length &&
            !relevantEnds[scanStart].isAfter(dayStart)) {
          scanStart++;
        }

        // Collect day events starting from scanStart; stop as soon as
        // an event starts at or after dayEnd (sorted order guarantees
        // all subsequent events are also past dayEnd).
        final dayEvents = <EventModel>[];
        for (var ei = scanStart; ei < relevant.length; ei++) {
          if (!relevant[ei].date.isBefore(dayEnd)) break;
          if (relevantEnds[ei].isAfter(dayStart)) {
            dayEvents.add(relevant[ei]);
          }
        }

        // Find gaps
        var cursor = dayStart;
        for (final event in dayEvents) {
          final eventStart = event.date.isBefore(dayStart) ? dayStart : event.date;
          final eventEnd = (event.endDate ?? event.date.add(const Duration(hours: 1)));
          final bufferedStart = eventStart.subtract(buffer);
          final bufferedEnd = eventEnd.add(buffer);

          final gapEnd = bufferedStart.isBefore(dayEnd) ? bufferedStart : dayEnd;
          if (gapEnd.isAfter(cursor)) {
            final slot = FreeSlot(start: cursor, end: gapEnd);
            if (slot.duration >= minimumDuration) {
              allSlots.add(slot);
            }
          }

          final newCursor = bufferedEnd.isAfter(cursor) ? bufferedEnd : cursor;
          cursor = newCursor.isAfter(dayEnd) ? dayEnd : newCursor;
        }

        // Gap after last event
        if (cursor.isBefore(dayEnd)) {
          final slot = FreeSlot(start: cursor, end: dayEnd);
          if (slot.duration >= minimumDuration) {
            allSlots.add(slot);
          }
        }
      }

      current = current.add(const Duration(days: 1));
    }

    return FreeSlotResult(
      slots: allSlots,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      minimumDuration: minimumDuration,
    );
  }

  /// Convenience: find slots for "today".
  FreeSlotResult findSlotsToday({
    required List<EventModel> events,
    Duration minimumDuration = const Duration(minutes: 30),
    int bufferMinutes = 0,
    Map<int, WorkingHours>? workingHours,
  }) {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return findSlots(
      events: events,
      rangeStart: now,
      rangeEnd: endOfDay,
      minimumDuration: minimumDuration,
      bufferMinutes: bufferMinutes,
      workingHours: workingHours,
      includeWeekends: true,
    );
  }

  /// Convenience: find slots for the next N days.
  FreeSlotResult findSlotsNextDays({
    required List<EventModel> events,
    int days = 7,
    Duration minimumDuration = const Duration(minutes: 30),
    int bufferMinutes = 0,
    Map<int, WorkingHours>? workingHours,
    bool includeWeekends = false,
  }) {
    final now = DateTime.now();
    final rangeEnd = now.add(Duration(days: days));
    return findSlots(
      events: events,
      rangeStart: now,
      rangeEnd: rangeEnd,
      minimumDuration: minimumDuration,
      bufferMinutes: bufferMinutes,
      workingHours: workingHours,
      includeWeekends: includeWeekends,
    );
  }

  /// Finds the first available slot that can fit the given duration.
  FreeSlot? findFirstAvailable({
    required List<EventModel> events,
    required Duration eventDuration,
    DateTime? searchFrom,
    int searchDays = 14,
    int bufferMinutes = 0,
    Map<int, WorkingHours>? workingHours,
    bool includeWeekends = false,
  }) {
    final from = searchFrom ?? DateTime.now();
    final result = findSlots(
      events: events,
      rangeStart: from,
      rangeEnd: from.add(Duration(days: searchDays)),
      minimumDuration: eventDuration,
      bufferMinutes: bufferMinutes,
      workingHours: workingHours,
      includeWeekends: includeWeekends,
    );
    return result.slots.isEmpty ? null : result.slots.first;
  }

  /// Suggests optimal slots — prefers morning slots and longer gaps.
  List<FreeSlot> suggestBestSlots({
    required List<EventModel> events,
    required Duration eventDuration,
    DateTime? searchFrom,
    int searchDays = 7,
    int maxSuggestions = 5,
    int bufferMinutes = 15,
    bool includeWeekends = false,
  }) {
    final from = searchFrom ?? DateTime.now();
    final result = findSlots(
      events: events,
      rangeStart: from,
      rangeEnd: from.add(Duration(days: searchDays)),
      minimumDuration: eventDuration,
      bufferMinutes: bufferMinutes,
      includeWeekends: includeWeekends,
    );

    final viable = result.slotsForDuration(eventDuration);

    // Score: prefer mornings (9-12), then early afternoon (12-14), longer slots
    viable.sort((a, b) {
      final scoreA = _slotScore(a, eventDuration);
      final scoreB = _slotScore(b, eventDuration);
      return scoreB.compareTo(scoreA); // Higher score = better
    });

    return viable.take(maxSuggestions).toList();
  }

  double _slotScore(FreeSlot slot, Duration needed) {
    var score = 0.0;

    // Morning bonus (9-12)
    if (slot.start.hour >= 9 && slot.start.hour < 12) score += 30;
    // Early afternoon (12-14)
    else if (slot.start.hour >= 12 && slot.start.hour < 14) score += 20;
    // Late afternoon
    else if (slot.start.hour >= 14 && slot.start.hour < 17) score += 10;

    // Prefer slots that aren't too much longer than needed (tighter fit = less wasted time)
    final excess = slot.duration - needed;
    if (excess.inMinutes < 30) {
      score += 15; // Tight fit bonus
    } else if (excess.inMinutes < 60) {
      score += 10;
    }

    // Prefer earlier dates
    final daysOut = slot.start.difference(DateTime.now()).inDays;
    score -= daysOut * 2;

    return score;
  }
}
