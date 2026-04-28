import '../../models/event_model.dart';

/// A summary report for a week's worth of events.
class WeeklyReport {
  /// The Monday that starts this reporting week.
  final DateTime weekStart;

  /// The Sunday that ends this reporting week.
  final DateTime weekEnd;

  /// Total events in this week.
  final int totalEvents;

  /// Events grouped by priority.
  final Map<EventPriority, int> priorityBreakdown;

  /// Events grouped by day of week (1=Mon, 7=Sun).
  final Map<int, int> dailyBreakdown;

  /// Top tags by frequency.
  final List<MapEntry<String, int>> topTags;

  /// Busiest day name and count.
  final String busiestDay;
  final int busiestDayCount;

  /// Completion rate from checklists (0.0 - 1.0), null if no checklists.
  final double? checklistCompletionRate;

  /// Comparison with previous week.
  final int? previousWeekTotal;

  /// Whether this week had more events than the previous.
  final bool? trending;

  const WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.totalEvents,
    required this.priorityBreakdown,
    required this.dailyBreakdown,
    required this.topTags,
    required this.busiestDay,
    required this.busiestDayCount,
    this.checklistCompletionRate,
    this.previousWeekTotal,
    this.trending,
  });

  /// Change in event count vs previous week, or null if no comparison data.
  int? get weekOverWeekChange =>
      previousWeekTotal != null ? totalEvents - previousWeekTotal! : null;

  /// Percentage change vs previous week, or null if no comparison data.
  double? get weekOverWeekPercent => previousWeekTotal != null && previousWeekTotal! > 0
      ? ((totalEvents - previousWeekTotal!) / previousWeekTotal!) * 100
      : null;
}

/// Service that generates weekly productivity reports from event data.
///
/// Analyzes events within a given week to produce a [WeeklyReport] with
/// priority breakdown, daily distribution, tag frequency, checklist
/// completion rates, and week-over-week comparisons.
class WeeklyReportService {
  static const _dayNames = [
    '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  /// Generates a [WeeklyReport] for the week containing [referenceDate].
  ///
  /// [allEvents] should include events from at least 2 weeks for
  /// week-over-week comparison. The week starts on Monday.
  WeeklyReport generateReport(List<EventModel> allEvents, {DateTime? referenceDate}) {
    final ref = referenceDate ?? DateTime.now();
    final weekStart = _startOfWeek(ref);
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final thisWeekEvents = _eventsInRange(allEvents, weekStart, weekEnd);
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final prevWeekEnd = weekStart.subtract(const Duration(seconds: 1));
    final prevWeekEvents = _eventsInRange(allEvents, prevWeekStart, prevWeekEnd);

    // Single-pass priority counting — O(N) instead of O(P×N).
    final priorityBreakdown = <EventPriority, int>{};
    for (final e in thisWeekEvents) {
      priorityBreakdown[e.priority] =
          (priorityBreakdown[e.priority] ?? 0) + 1;
    }

    final dailyBreakdown = <int, int>{};
    for (final e in thisWeekEvents) {
      final dow = e.date.weekday; // 1=Mon, 7=Sun
      dailyBreakdown[dow] = (dailyBreakdown[dow] ?? 0) + 1;
    }

    // Find busiest day
    var busiestDay = 'None';
    var busiestDayCount = 0;
    dailyBreakdown.forEach((dow, count) {
      if (count > busiestDayCount) {
        busiestDayCount = count;
        busiestDay = _dayNames[dow];
      }
    });

    // Tag frequency
    final tagCounts = <String, int>{};
    for (final e in thisWeekEvents) {
      for (final tag in e.tags) {
        tagCounts[tag.name] = (tagCounts[tag.name] ?? 0) + 1;
      }
    }
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Checklist completion rate — single pass, no intermediate lists.
    double? completionRate;
    var totalItems = 0;
    var checkedItems = 0;
    for (final e in thisWeekEvents) {
      if (e.checklist.hasItems) {
        for (final item in e.checklist.items) {
          totalItems++;
          if (item.isChecked) checkedItems++;
        }
      }
    }
    if (totalItems > 0) {
      completionRate = checkedItems / totalItems;
    }

    final prevTotal = prevWeekEvents.isNotEmpty ? prevWeekEvents.length : null;

    return WeeklyReport(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalEvents: thisWeekEvents.length,
      priorityBreakdown: priorityBreakdown,
      dailyBreakdown: dailyBreakdown,
      topTags: topTags.take(5).toList(),
      busiestDay: busiestDay,
      busiestDayCount: busiestDayCount,
      checklistCompletionRate: completionRate,
      previousWeekTotal: prevTotal,
      trending: prevTotal != null ? thisWeekEvents.length > prevTotal : null,
    );
  }

  /// Formats a [WeeklyReport] as a human-readable text summary.
  String formatReport(WeeklyReport report) {
    final buf = StringBuffer();
    buf.writeln('📊 Weekly Report');
    buf.writeln('${_formatDate(report.weekStart)} – ${_formatDate(report.weekEnd)}');
    buf.writeln('─' * 30);
    buf.writeln();
    buf.writeln('📅 Total Events: ${report.totalEvents}');

    if (report.weekOverWeekChange != null) {
      final change = report.weekOverWeekChange!;
      final arrow = change > 0 ? '↑' : change < 0 ? '↓' : '→';
      final pct = report.weekOverWeekPercent;
      buf.writeln('   vs last week: $arrow ${change.abs()} '
          '(${pct != null ? "${pct.toStringAsFixed(0)}%" : "N/A"})');
    }

    buf.writeln();
    buf.writeln('🎯 Priority Breakdown:');
    for (final p in EventPriority.values) {
      final count = report.priorityBreakdown[p] ?? 0;
      if (count > 0) {
        buf.writeln('   ${p.label}: $count');
      }
    }

    buf.writeln();
    buf.writeln('📆 Busiest Day: ${report.busiestDay} (${report.busiestDayCount} events)');

    if (report.topTags.isNotEmpty) {
      buf.writeln();
      buf.writeln('🏷️ Top Tags:');
      for (final tag in report.topTags) {
        buf.writeln('   ${tag.key}: ${tag.value}');
      }
    }

    if (report.checklistCompletionRate != null) {
      buf.writeln();
      buf.writeln('✅ Checklist Completion: '
          '${(report.checklistCompletionRate! * 100).toStringAsFixed(0)}%');
    }

    return buf.toString();
  }

  /// Returns the Monday 00:00 of the week containing [date].
  DateTime _startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Filters events whose [date] falls within [start] and [end] inclusive.
  List<EventModel> _eventsInRange(List<EventModel> events, DateTime start, DateTime end) {
    return events.where((e) =>
      !e.date.isBefore(start) && !e.date.isAfter(end)
    ).toList();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
