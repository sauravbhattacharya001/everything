import '../models/event_model.dart';
import '../utils/formatting_utils.dart';

/// Represents a block of time in the daily timeline.
///
/// A [TimelineBlock] is either an event or a free gap between events.
/// Blocks are ordered chronologically and provide metadata for rendering
/// a visual daily schedule.
class TimelineBlock {
  /// Whether this block represents an event (true) or free time (false).
  final bool isEvent;

  /// The event associated with this block, or null for free-time gaps.
  final EventModel? event;

  /// Start time of this block.
  final DateTime start;

  /// End time of this block.
  final DateTime end;

  /// Duration of this block.
  Duration get duration => end.difference(start);

  /// Human-readable duration label (e.g. "1h 30m", "45m").
  String get durationLabel {
    final d = duration;
    if (d.inHours > 0) {
      final mins = d.inMinutes % 60;
      return mins > 0 ? '${d.inHours}h ${mins}m' : '${d.inHours}h';
    }
    return '${d.inMinutes}m';
  }

  /// Whether this block overlaps with another block (conflict).
  bool overlapsWith(TimelineBlock other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  const TimelineBlock({
    required this.isEvent,
    this.event,
    required this.start,
    required this.end,
  });

  @override
  String toString() => isEvent
      ? 'Event(${event?.title}, $start - $end)'
      : 'Free($start - $end, $durationLabel)';
}

/// Summary statistics for a daily timeline.
class DailySummary {
  /// Total number of events on this day.
  final int eventCount;

  /// Total time occupied by events.
  final Duration busyTime;

  /// Total free time between events (within the day window).
  final Duration freeTime;

  /// Number of scheduling conflicts (overlapping events).
  final int conflictCount;

  /// The longest free gap, or null if no gaps exist.
  final TimelineBlock? longestFreeBlock;

  /// The busiest hour (0-23) by event count, or null if no events.
  final int? busiestHour;

  /// Percentage of the day window occupied by events (0.0 - 1.0).
  double get busyRatio {
    final total = busyTime + freeTime;
    if (total.inMinutes == 0) return 0.0;
    return busyTime.inMinutes / total.inMinutes;
  }

  /// Human-readable busy time label.
  String get busyTimeLabel => _formatDuration(busyTime);

  /// Human-readable free time label.
  String get freeTimeLabel => _formatDuration(freeTime);

  static String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      final mins = d.inMinutes % 60;
      return mins > 0 ? '${d.inHours}h ${mins}m' : '${d.inHours}h';
    }
    return '${d.inMinutes}m';
  }

  const DailySummary({
    required this.eventCount,
    required this.busyTime,
    required this.freeTime,
    required this.conflictCount,
    this.longestFreeBlock,
    this.busiestHour,
  });

  @override
  String toString() =>
      'DailySummary(events: $eventCount, busy: $busyTimeLabel, '
      'free: $freeTimeLabel, conflicts: $conflictCount)';
}

/// Service that builds a chronological timeline of events for a given day.
///
/// The [DailyTimelineService] takes a list of events and produces an
/// ordered sequence of [TimelineBlock]s representing both events and
/// free gaps. It also detects scheduling conflicts and computes
/// [DailySummary] statistics.
///
/// Usage:
/// ```dart
/// final service = DailyTimelineService();
/// final timeline = service.buildTimeline(
///   events: myEvents,
///   date: DateTime(2026, 3, 2),
/// );
/// final summary = service.summarize(timeline, date: DateTime(2026, 3, 2));
/// ```
class DailyTimelineService {
  /// Default day start hour (inclusive).
  final int dayStartHour;

  /// Default day end hour (exclusive).
  final int dayEndHour;

  /// Minimum gap duration to report as a free block.
  final Duration minimumGap;

  const DailyTimelineService({
    this.dayStartHour = 8,
    this.dayEndHour = 22,
    this.minimumGap = const Duration(minutes: 15),
  });

  /// Builds a chronological timeline for the given [date].
  ///
  /// Events are filtered to those occurring on [date], sorted by start time,
  /// and interleaved with free-time gap blocks. Events without an [endDate]
  /// are treated as 30-minute blocks.
  List<TimelineBlock> buildTimeline({
    required List<EventModel> events,
    required DateTime date,
  }) {
    final dayStart = DateTime(date.year, date.month, date.day, dayStartHour);
    final dayEnd = DateTime(date.year, date.month, date.day, dayEndHour);

    // Filter to events on this date
    final dayEvents = events.where((e) {
      final eventDate = DateTime(e.date.year, e.date.month, e.date.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return eventDate == targetDate;
    }).toList();

    // Sort by start time
    dayEvents.sort((a, b) => a.date.compareTo(b.date));

    // Build event blocks
    final eventBlocks = dayEvents.map((e) {
      final start = e.date.isBefore(dayStart) ? dayStart : e.date;
      final end = e.endDate ?? e.date.add(const Duration(minutes: 30));
      final clampedEnd = end.isAfter(dayEnd) ? dayEnd : end;
      return TimelineBlock(isEvent: true, event: e, start: start, end: clampedEnd);
    }).toList();

    if (eventBlocks.isEmpty) {
      return [
        TimelineBlock(isEvent: false, start: dayStart, end: dayEnd),
      ];
    }

    // Interleave with free gaps
    final timeline = <TimelineBlock>[];
    var cursor = dayStart;

    for (final block in eventBlocks) {
      if (block.start.isAfter(cursor)) {
        final gap = block.start.difference(cursor);
        if (gap >= minimumGap) {
          timeline.add(TimelineBlock(
            isEvent: false,
            start: cursor,
            end: block.start,
          ));
        }
      }
      timeline.add(block);
      if (block.end.isAfter(cursor)) {
        cursor = block.end;
      }
    }

    // Trailing gap
    if (cursor.isBefore(dayEnd)) {
      final gap = dayEnd.difference(cursor);
      if (gap >= minimumGap) {
        timeline.add(TimelineBlock(
          isEvent: false,
          start: cursor,
          end: dayEnd,
        ));
      }
    }

    return timeline;
  }

  /// Detects scheduling conflicts (overlapping events) in the timeline.
  ///
  /// Returns pairs of conflicting [TimelineBlock]s.
  List<(TimelineBlock, TimelineBlock)> detectConflicts(
    List<TimelineBlock> timeline,
  ) {
    final eventBlocks = timeline.where((b) => b.isEvent).toList();
    final conflicts = <(TimelineBlock, TimelineBlock)>[];

    for (var i = 0; i < eventBlocks.length; i++) {
      for (var j = i + 1; j < eventBlocks.length; j++) {
        if (eventBlocks[i].overlapsWith(eventBlocks[j])) {
          conflicts.add((eventBlocks[i], eventBlocks[j]));
        }
      }
    }

    return conflicts;
  }

  /// Computes a [DailySummary] for the given timeline.
  DailySummary summarize(
    List<TimelineBlock> timeline, {
    required DateTime date,
  }) {
    final eventBlocks = timeline.where((b) => b.isEvent).toList();
    final freeBlocks = timeline.where((b) => !b.isEvent).toList();

    final busyTime = eventBlocks.fold<Duration>(
      Duration.zero,
      (sum, b) => sum + b.duration,
    );
    final freeTime = freeBlocks.fold<Duration>(
      Duration.zero,
      (sum, b) => sum + b.duration,
    );

    final conflicts = detectConflicts(timeline);

    TimelineBlock? longestFree;
    for (final block in freeBlocks) {
      if (longestFree == null || block.duration > longestFree.duration) {
        longestFree = block;
      }
    }

    // Find busiest hour
    int? busiestHour;
    if (eventBlocks.isNotEmpty) {
      final hourCounts = <int, int>{};
      for (final block in eventBlocks) {
        final hour = block.start.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
      busiestHour = hourCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    return DailySummary(
      eventCount: eventBlocks.length,
      busyTime: busyTime,
      freeTime: freeTime,
      conflictCount: conflicts.length,
      longestFreeBlock: longestFree,
      busiestHour: busiestHour,
    );
  }

  /// Formats the timeline as a text-based schedule string.
  ///
  /// Useful for notifications, exports, or text-based displays.
  String formatAsText(List<TimelineBlock> timeline) {
    final buffer = StringBuffer();
    for (final block in timeline) {
      final startStr = FormattingUtils.formatTime24h(block.start);
      final endStr = FormattingUtils.formatTime24h(block.end);
      if (block.isEvent) {
        final priority = block.event!.priority.label;
        buffer.writeln('$startStr - $endStr  [$priority] ${block.event!.title}');
        if (block.event!.location.isNotEmpty) {
          buffer.writeln('              📍 ${block.event!.location}');
        }
      } else {
        buffer.writeln('$startStr - $endStr  ── Free (${ block.durationLabel }) ──');
      }
    }
    return buffer.toString();
  }

  static String FormattingUtils.formatTime24h(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
