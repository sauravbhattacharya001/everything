import '../../models/event_model.dart';
import '../utils/formatting_utils.dart';

/// Configuration for agenda digest generation.
class DigestConfig {
  /// Number of days to include in the digest (default: 7).
  final int days;

  /// Whether to expand recurring events into individual occurrences.
  final bool expandRecurring;

  /// Whether to include checklist progress summaries.
  final bool includeChecklists;

  /// Whether to include tag labels on events.
  final bool includeTags;

  /// Whether to group events by priority within each day.
  final bool groupByPriority;

  /// Maximum number of events to show per day (null = unlimited).
  final int? maxEventsPerDay;

  const DigestConfig({
    this.days = 7,
    this.expandRecurring = true,
    this.includeChecklists = true,
    this.includeTags = true,
    this.groupByPriority = false,
    this.maxEventsPerDay,
  });
}

/// A single day's agenda within a digest.
class DayAgenda {
  /// The date this agenda covers.
  final DateTime date;

  /// Events occurring on this day, sorted by time.
  final List<EventModel> events;

  const DayAgenda({required this.date, required this.events});

  /// Whether this day has any events.
  bool get hasEvents => events.isNotEmpty;

  /// Number of events on this day.
  int get eventCount => events.length;

  /// Number of urgent/high priority events.
  int get urgentCount => events
      .where((e) =>
          e.priority == EventPriority.urgent ||
          e.priority == EventPriority.high)
      .length;

  /// Whether this day is today.
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Whether this day is in the past.
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today);
  }
}

/// Summary statistics for a digest.
class DigestSummary {
  /// Total events across all days.
  final int totalEvents;

  /// Number of days with at least one event.
  final int busyDays;

  /// Number of days with no events.
  final int freeDays;

  /// Total number of days in the digest window.
  final int totalDays;

  /// Number of urgent-priority events.
  final int urgentEvents;

  /// Number of high-priority events.
  final int highEvents;

  /// Number of recurring events (before expansion).
  final int recurringEvents;

  /// The busiest day (most events). Null if no events.
  final DayAgenda? busiestDay;

  /// Average events per day (only counting busy days).
  final double averageEventsPerBusyDay;

  const DigestSummary({
    required this.totalEvents,
    required this.busyDays,
    required this.freeDays,
    required this.totalDays,
    required this.urgentEvents,
    required this.highEvents,
    required this.recurringEvents,
    required this.busiestDay,
    required this.averageEventsPerBusyDay,
  });
}

/// Result of generating an agenda digest.
class AgendaDigest {
  /// Daily agendas in chronological order.
  final List<DayAgenda> days;

  /// Summary statistics.
  final DigestSummary summary;

  /// Configuration used to generate this digest.
  final DigestConfig config;

  /// Start date of the digest window.
  final DateTime startDate;

  /// End date of the digest window (exclusive).
  final DateTime endDate;

  const AgendaDigest({
    required this.days,
    required this.summary,
    required this.config,
    required this.startDate,
    required this.endDate,
  });
}

/// Generates formatted agenda digests from a list of events.
///
/// Supports configurable time windows, recurring event expansion,
/// priority grouping, and multiple output formats (plain text and
/// markdown).
///
/// Usage:
/// ```dart
/// final service = AgendaDigestService();
/// final digest = service.generate(
///   events,
///   startDate: DateTime.now(),
///   config: DigestConfig(days: 7),
/// );
/// print(service.formatText(digest));
/// print(service.formatMarkdown(digest));
/// ```
class AgendaDigestService {
  /// Generates an agenda digest for the given events and time window.
  ///
  /// [events] is the full list of events to consider.
  /// [startDate] is the beginning of the digest window (defaults to today).
  /// [config] controls how many days, recurring expansion, etc.
  AgendaDigest generate(
    List<EventModel> events, {
    DateTime? startDate,
    DigestConfig config = const DigestConfig(),
  }) {
    final start = _normalizeDate(startDate ?? DateTime.now());
    final end = start.add(Duration(days: config.days));

    // Collect all events in the window, optionally expanding recurrences
    final allEvents = <EventModel>[];
    for (final event in events) {
      if (config.expandRecurring && event.isRecurring) {
        // Add the original if it falls in window
        if (_isInWindow(event.date, start, end)) {
          allEvents.add(event);
        }
        // Add generated occurrences that fall in window
        final occurrences = event.generateOccurrences(maxOccurrences: 52);
        for (final occ in occurrences) {
          if (_isInWindow(occ.date, start, end)) {
            allEvents.add(occ);
          }
        }
      } else {
        if (_isInWindow(event.date, start, end)) {
          allEvents.add(event);
        }
      }
    }

    // Group events by date
    final dayMap = <DateTime, List<EventModel>>{};
    for (var i = 0; i < config.days; i++) {
      dayMap[start.add(Duration(days: i))] = [];
    }
    for (final event in allEvents) {
      final dateKey = _normalizeDate(event.date);
      if (dayMap.containsKey(dateKey)) {
        dayMap[dateKey]!.add(event);
      }
    }

    // Sort events within each day by time
    final dayAgendas = <DayAgenda>[];
    for (var i = 0; i < config.days; i++) {
      final date = start.add(Duration(days: i));
      var dayEvents = dayMap[date]!;
      dayEvents.sort((a, b) => a.date.compareTo(b.date));

      if (config.groupByPriority) {
        dayEvents = _sortByPriority(dayEvents);
      }

      if (config.maxEventsPerDay != null &&
          dayEvents.length > config.maxEventsPerDay!) {
        dayEvents = dayEvents.sublist(0, config.maxEventsPerDay!);
      }

      dayAgendas.add(DayAgenda(date: date, events: dayEvents));
    }

    // Build summary
    final busyDays = dayAgendas.where((d) => d.hasEvents).length;
    final totalEvents =
        dayAgendas.fold<int>(0, (sum, d) => sum + d.eventCount);
    final urgentEvents = allEvents
        .where((e) => e.priority == EventPriority.urgent)
        .length;
    final highEvents = allEvents
        .where((e) => e.priority == EventPriority.high)
        .length;
    final recurringEvents = events.where((e) => e.isRecurring).length;

    DayAgenda? busiestDay;
    for (final day in dayAgendas) {
      if (busiestDay == null || day.eventCount > busiestDay.eventCount) {
        if (day.hasEvents) busiestDay = day;
      }
    }

    final summary = DigestSummary(
      totalEvents: totalEvents,
      busyDays: busyDays,
      freeDays: config.days - busyDays,
      totalDays: config.days,
      urgentEvents: urgentEvents,
      highEvents: highEvents,
      recurringEvents: recurringEvents,
      busiestDay: busiestDay,
      averageEventsPerBusyDay:
          busyDays > 0 ? totalEvents / busyDays : 0.0,
    );

    return AgendaDigest(
      days: dayAgendas,
      summary: summary,
      config: config,
      startDate: start,
      endDate: end,
    );
  }

  /// Formats a digest as plain text.
  String formatText(AgendaDigest digest) {
    final buf = StringBuffer();

    buf.writeln('═══════════════════════════════════════');
    buf.writeln('         Weekly Agenda Digest');
    buf.writeln('═══════════════════════════════════════');
    buf.writeln();

    // Summary line
    final s = digest.summary;
    buf.writeln(
        '${s.totalEvents} events across ${s.busyDays} days (${s.freeDays} free)');
    if (s.urgentEvents > 0) {
      buf.writeln('⚠ ${s.urgentEvents} urgent event${s.urgentEvents == 1 ? '' : 's'}');
    }
    buf.writeln();

    // Daily breakdown
    for (final day in digest.days) {
      final dayLabel = _formatDayLabel(day);
      buf.writeln('─── $dayLabel ───');

      if (!day.hasEvents) {
        buf.writeln('  (no events)');
      } else {
        for (final event in day.events) {
          buf.write('  ${FormattingUtils.formatTime24h(event.date)}  ');
          buf.write(_priorityIcon(event.priority));
          buf.write('  ${event.title}');

          if (digest.config.includeTags && event.tags.isNotEmpty) {
            final tagStr = event.tags.map((t) => t.name).join(', ');
            buf.write('  [$tagStr]');
          }

          if (event.isRecurring) {
            buf.write('  🔁');
          }

          buf.writeln();

          if (digest.config.includeChecklists && event.checklist.hasItems) {
            buf.writeln(
                '         ☑ ${event.checklist.completedCount}/${event.checklist.items.length} tasks');
          }
        }
      }
      buf.writeln();
    }

    // Footer summary
    if (s.busiestDay != null) {
      buf.writeln(
          'Busiest: ${_formatDayLabel(s.busiestDay!)} (${s.busiestDay!.eventCount} events)');
    }
    if (s.averageEventsPerBusyDay > 0) {
      buf.writeln(
          'Average: ${s.averageEventsPerBusyDay.toStringAsFixed(1)} events/busy day');
    }

    return buf.toString();
  }

  /// Formats a digest as markdown.
  String formatMarkdown(AgendaDigest digest) {
    final buf = StringBuffer();

    buf.writeln('# 📅 Weekly Agenda Digest');
    buf.writeln();

    // Summary
    final s = digest.summary;
    buf.writeln(
        '**${s.totalEvents} events** across ${s.busyDays} days (${s.freeDays} free)');
    if (s.urgentEvents > 0) {
      buf.writeln(
          '> ⚠️ **${s.urgentEvents} urgent** event${s.urgentEvents == 1 ? '' : 's'} this week');
    }
    buf.writeln();

    // Daily breakdown
    for (final day in digest.days) {
      final label = _formatDayLabel(day);
      buf.writeln('## $label');
      buf.writeln();

      if (!day.hasEvents) {
        buf.writeln('*No events scheduled*');
      } else {
        for (final event in day.events) {
          final time = FormattingUtils.formatTime24h(event.date);
          final icon = _priorityIcon(event.priority);
          final recurring = event.isRecurring ? ' 🔁' : '';

          var line = '- **$time** $icon ${event.title}$recurring';

          if (digest.config.includeTags && event.tags.isNotEmpty) {
            final tagStr =
                event.tags.map((t) => '`${t.name}`').join(' ');
            line += '  $tagStr';
          }

          buf.writeln(line);

          if (digest.config.includeChecklists && event.checklist.hasItems) {
            buf.writeln(
                '  - ☑ ${event.checklist.completedCount}/${event.checklist.items.length} tasks complete');
          }
        }
      }
      buf.writeln();
    }

    // Footer
    if (s.busiestDay != null) {
      buf.writeln(
          '---\n**Busiest day:** ${_formatDayLabel(s.busiestDay!)} (${s.busiestDay!.eventCount} events)');
    }

    return buf.toString();
  }

  // ── Private helpers ──────────────────────────────────────────────

  /// Normalizes a DateTime to midnight (strips time component).
  DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Checks if a date falls within [start, end) window.
  bool _isInWindow(DateTime date, DateTime start, DateTime end) {
    final normalized = _normalizeDate(date);
    return !normalized.isBefore(start) && normalized.isBefore(end);
  }

  /// Sorts events by priority (urgent first, then high, medium, low).
  List<EventModel> _sortByPriority(List<EventModel> events) {
    final priorityOrder = {
      EventPriority.urgent: 0,
      EventPriority.high: 1,
      EventPriority.medium: 2,
      EventPriority.low: 3,
    };
    return List.of(events)
      ..sort((a, b) =>
          (priorityOrder[a.priority] ?? 2)
              .compareTo(priorityOrder[b.priority] ?? 2));
  }

  /// Formats a day label like "Mon, Feb 24 (Today)" or "Tue, Feb 25".
  String _formatDayLabel(DayAgenda day) {
    final weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final wd = weekdays[day.date.weekday - 1];
    final mo = months[day.date.month - 1];
    final suffix = day.isToday ? ' (Today)' : '';
    return '$wd, $mo ${day.date.day}$suffix';
  }

  /// Formats a time as "HH:MM" (24-hour).
  String FormattingUtils.formatTime24h(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Returns a priority icon.
  String _priorityIcon(EventPriority priority) {
    switch (priority) {
      case EventPriority.urgent:
        return '🔴';
      case EventPriority.high:
        return '🟠';
      case EventPriority.medium:
        return '🟡';
      case EventPriority.low:
        return '🟢';
    }
  }
}
