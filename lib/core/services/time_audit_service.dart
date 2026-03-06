import 'dart:math';
import '../../models/event_model.dart';
import '../../models/event_tag.dart';

// ─── Data Classes ───────────────────────────────────────────────

/// How time was spent on a single category (tag) during the audit period.
class CategoryTimeAllocation {
  /// Tag name (or "Untagged" for events without tags).
  final String category;

  /// Total minutes spent on events in this category.
  final double totalMinutes;

  /// Number of events in this category.
  final int eventCount;

  /// Percentage of total scheduled time (0.0–100.0).
  final double percentage;

  /// Average event duration in minutes for this category.
  final double avgDurationMinutes;

  /// Longest single event duration in minutes.
  final double longestEventMinutes;

  const CategoryTimeAllocation({
    required this.category,
    required this.totalMinutes,
    required this.eventCount,
    required this.percentage,
    required this.avgDurationMinutes,
    required this.longestEventMinutes,
  });
}

/// Summary of a single day within the audit period.
class DailyTimeSummary {
  /// The date this summary covers.
  final DateTime date;

  /// Total scheduled minutes (sum of event durations).
  final double scheduledMinutes;

  /// Total available minutes in working hours.
  final double availableMinutes;

  /// Free (unscheduled) minutes during working hours.
  final double freeMinutes;

  /// Utilization rate = scheduled / available (0.0–1.0).
  final double utilizationRate;

  /// Number of events on this day.
  final int eventCount;

  /// Number of context switches (transitions between events).
  final int contextSwitches;

  const DailyTimeSummary({
    required this.date,
    required this.scheduledMinutes,
    required this.availableMinutes,
    required this.freeMinutes,
    required this.utilizationRate,
    required this.eventCount,
    required this.contextSwitches,
  });
}

/// Comparison of planned vs actual time for a category.
class PlannedVsActual {
  /// Category name.
  final String category;

  /// Planned minutes (from events at creation time / priority weighting).
  final double plannedMinutes;

  /// Actual minutes (based on final event durations in period).
  final double actualMinutes;

  /// Variance = actual - planned (positive = over, negative = under).
  final double varianceMinutes;

  /// Variance as percentage of planned (-100 to ∞).
  final double variancePercent;

  const PlannedVsActual({
    required this.category,
    required this.plannedMinutes,
    required this.actualMinutes,
    required this.varianceMinutes,
    required this.variancePercent,
  });
}

/// Peak productivity hours analysis.
class PeakHoursAnalysis {
  /// Hour of day (0–23) with the most scheduled events.
  final int busiestHour;

  /// Average events per hour for the busiest hour.
  final double busiestHourAvgEvents;

  /// Hour of day with the least scheduled events (during working hours).
  final int quietestHour;

  /// Distribution of event start times by hour (hour → count).
  final Map<int, int> hourlyDistribution;

  /// Morning (6–12) vs afternoon (12–18) vs evening (18–22) split in minutes.
  final double morningMinutes;
  final double afternoonMinutes;
  final double eveningMinutes;

  const PeakHoursAnalysis({
    required this.busiestHour,
    required this.busiestHourAvgEvents,
    required this.quietestHour,
    required this.hourlyDistribution,
    required this.morningMinutes,
    required this.afternoonMinutes,
    required this.eveningMinutes,
  });
}

/// Full time audit report for a date range.
class TimeAuditReport {
  /// Start of the audit period.
  final DateTime periodStart;

  /// End of the audit period.
  final DateTime periodEnd;

  /// Number of days in the audit period.
  final int totalDays;

  /// Total events analyzed.
  final int totalEvents;

  /// Total scheduled minutes across all events.
  final double totalScheduledMinutes;

  /// Total available minutes (working hours × days).
  final double totalAvailableMinutes;

  /// Overall utilization rate (0.0–1.0).
  final double overallUtilization;

  /// Average daily scheduled minutes.
  final double avgDailyScheduledMinutes;

  /// Time allocation by category.
  final List<CategoryTimeAllocation> categoryBreakdown;

  /// Daily summaries.
  final List<DailyTimeSummary> dailySummaries;

  /// Peak hours analysis.
  final PeakHoursAnalysis peakHours;

  /// Priority breakdown in minutes.
  final Map<EventPriority, double> priorityMinutes;

  /// Average event duration in minutes.
  final double avgEventDuration;

  /// Median event duration in minutes.
  final double medianEventDuration;

  /// Longest event duration in minutes.
  final double longestEventDuration;

  /// Events without an end date (point-in-time events), excluded from
  /// duration analysis.
  final int pointEvents;

  /// Recommendations based on the audit findings.
  final List<String> recommendations;

  const TimeAuditReport({
    required this.periodStart,
    required this.periodEnd,
    required this.totalDays,
    required this.totalEvents,
    required this.totalScheduledMinutes,
    required this.totalAvailableMinutes,
    required this.overallUtilization,
    required this.avgDailyScheduledMinutes,
    required this.categoryBreakdown,
    required this.dailySummaries,
    required this.peakHours,
    required this.priorityMinutes,
    required this.avgEventDuration,
    required this.medianEventDuration,
    required this.longestEventDuration,
    required this.pointEvents,
    required this.recommendations,
  });
}

// ─── Service ────────────────────────────────────────────────────

/// Time Audit Service — analyzes how time was actually spent over a
/// period based on calendar event data.
///
/// Answers questions like:
///   - "Where does my time go?"
///   - "How much of my day is actually scheduled?"
///   - "Which categories eat the most time?"
///   - "When am I busiest?"
///   - "Am I over-committing or under-utilizing my schedule?"
///
/// Unlike [FocusTimeService] (which finds free blocks) or
/// [WeeklyReportService] (which counts events), this service performs
/// deep duration analysis: category breakdowns, daily utilization,
/// peak hours, priority splits, and generates actionable
/// recommendations.
class TimeAuditService {
  /// Start of working day (hour, 0–23).
  final int workDayStartHour;

  /// End of working day (hour, 0–23).
  final int workDayEndHour;

  /// Minimum event duration in minutes to include in audit.
  /// Events shorter than this are counted but flagged.
  final int minEventMinutes;

  /// Creates a [TimeAuditService] with configurable working hours.
  ///
  /// Defaults: 8 AM – 18 PM (10-hour workday), 0-minute minimum.
  TimeAuditService({
    this.workDayStartHour = 8,
    this.workDayEndHour = 18,
    this.minEventMinutes = 0,
  })  : assert(workDayStartHour >= 0 && workDayStartHour <= 23),
        assert(workDayEndHour >= 0 && workDayEndHour <= 23),
        assert(workDayStartHour < workDayEndHour,
            'workDayStartHour must be before workDayEndHour'),
        assert(minEventMinutes >= 0);

  /// Generate a full time audit report for events in [start]–[end].
  ///
  /// Only events with both a start date and end date are included in
  /// duration analysis. Point-in-time events (no endDate) are counted
  /// but excluded from time calculations.
  TimeAuditReport audit(
    List<EventModel> events, {
    required DateTime start,
    required DateTime end,
  }) {
    assert(!end.isBefore(start), 'end must be on or after start');

    final totalDays = end.difference(start).inDays + 1;
    final workDayMinutes = (workDayEndHour - workDayStartHour) * 60.0;
    final totalAvailable = workDayMinutes * totalDays;

    // Filter events to the audit period
    final periodEvents = events.where((e) {
      return !e.date.isBefore(start) &&
          e.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    // Separate timed events from point events
    final timedEvents =
        periodEvents.where((e) => e.endDate != null).toList();
    final pointCount =
        periodEvents.where((e) => e.endDate == null).length;

    // Event durations
    final durations = timedEvents
        .map((e) => e.duration!.inMinutes.toDouble())
        .where((d) => d >= minEventMinutes)
        .toList()
      ..sort();

    final totalScheduled = durations.fold(0.0, (sum, d) => sum + d);
    final avgDuration =
        durations.isEmpty ? 0.0 : totalScheduled / durations.length;
    final medianDuration = _median(durations);
    final longestDuration = durations.isEmpty ? 0.0 : durations.last;

    // Category breakdown
    final categoryBreakdown =
        _computeCategoryBreakdown(timedEvents, totalScheduled);

    // Daily summaries
    final dailySummaries =
        _computeDailySummaries(timedEvents, start, totalDays, workDayMinutes);

    // Peak hours
    final peakHours = _computePeakHours(timedEvents, totalDays);

    // Priority breakdown
    final priorityMinutes = _computePriorityMinutes(timedEvents);

    // Utilization
    final utilization =
        totalAvailable > 0 ? totalScheduled / totalAvailable : 0.0;

    // Recommendations
    final recommendations = _generateRecommendations(
      utilization: utilization,
      categoryBreakdown: categoryBreakdown,
      dailySummaries: dailySummaries,
      peakHours: peakHours,
      avgDuration: avgDuration,
      pointCount: pointCount,
      totalEvents: periodEvents.length,
    );

    return TimeAuditReport(
      periodStart: start,
      periodEnd: end,
      totalDays: totalDays,
      totalEvents: periodEvents.length,
      totalScheduledMinutes: totalScheduled,
      totalAvailableMinutes: totalAvailable,
      overallUtilization: utilization,
      avgDailyScheduledMinutes:
          totalDays > 0 ? totalScheduled / totalDays : 0.0,
      categoryBreakdown: categoryBreakdown,
      dailySummaries: dailySummaries,
      peakHours: peakHours,
      priorityMinutes: priorityMinutes,
      avgEventDuration: avgDuration,
      medianEventDuration: medianDuration,
      longestEventDuration: longestDuration,
      pointEvents: pointCount,
      recommendations: recommendations,
    );
  }

  // ── Category breakdown ──────────────────────────────────────────

  List<CategoryTimeAllocation> _computeCategoryBreakdown(
    List<EventModel> timedEvents,
    double totalScheduled,
  ) {
    final Map<String, _CategoryAccumulator> accum = {};

    for (final event in timedEvents) {
      final mins = event.duration!.inMinutes.toDouble();
      if (mins < minEventMinutes) continue;

      final categories = event.tags.isNotEmpty
          ? event.tags.map((t) => t.name).toSet()
          : {'Untagged'};

      // Split time equally among tags if multi-tagged
      final splitMins = mins / categories.length;

      for (final cat in categories) {
        accum.putIfAbsent(cat, () => _CategoryAccumulator());
        accum[cat]!.totalMinutes += splitMins;
        accum[cat]!.eventCount += 1;
        if (mins > accum[cat]!.longestMinutes) {
          accum[cat]!.longestMinutes = mins;
        }
      }
    }

    final result = accum.entries.map((entry) {
      final a = entry.value;
      return CategoryTimeAllocation(
        category: entry.key,
        totalMinutes: a.totalMinutes,
        eventCount: a.eventCount,
        percentage:
            totalScheduled > 0 ? (a.totalMinutes / totalScheduled) * 100 : 0,
        avgDurationMinutes:
            a.eventCount > 0 ? a.totalMinutes / a.eventCount : 0,
        longestEventMinutes: a.longestMinutes,
      );
    }).toList()
      ..sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

    return result;
  }

  // ── Daily summaries ─────────────────────────────────────────────

  List<DailyTimeSummary> _computeDailySummaries(
    List<EventModel> timedEvents,
    DateTime start,
    int totalDays,
    double workDayMinutes,
  ) {
    final summaries = <DailyTimeSummary>[];

    for (int d = 0; d < totalDays; d++) {
      final day = DateTime(start.year, start.month, start.day + d);
      final dayEnd = day.add(const Duration(days: 1));

      final dayEvents = timedEvents.where((e) {
        return !e.date.isBefore(day) && e.date.isBefore(dayEnd);
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final scheduled = dayEvents
          .map((e) => e.duration!.inMinutes.toDouble())
          .where((m) => m >= minEventMinutes)
          .fold(0.0, (sum, m) => sum + m);

      // Count context switches (transitions between events)
      int switches = dayEvents.length > 1 ? dayEvents.length - 1 : 0;

      summaries.add(DailyTimeSummary(
        date: day,
        scheduledMinutes: scheduled,
        availableMinutes: workDayMinutes,
        freeMinutes: max(0, workDayMinutes - scheduled),
        utilizationRate:
            workDayMinutes > 0 ? min(1.0, scheduled / workDayMinutes) : 0.0,
        eventCount: dayEvents.length,
        contextSwitches: switches,
      ));
    }

    return summaries;
  }

  // ── Peak hours ──────────────────────────────────────────────────

  PeakHoursAnalysis _computePeakHours(
    List<EventModel> timedEvents,
    int totalDays,
  ) {
    // Hourly distribution of event start times
    final hourly = <int, int>{};
    for (int h = 0; h < 24; h++) hourly[h] = 0;

    double morningMins = 0, afternoonMins = 0, eveningMins = 0;

    for (final event in timedEvents) {
      final hour = event.date.hour;
      hourly[hour] = hourly[hour]! + 1;

      final mins = event.duration!.inMinutes.toDouble();
      if (hour >= 6 && hour < 12) {
        morningMins += mins;
      } else if (hour >= 12 && hour < 18) {
        afternoonMins += mins;
      } else if (hour >= 18 && hour < 22) {
        eveningMins += mins;
      }
    }

    // Find busiest and quietest hours (within working hours)
    int busiestHour = workDayStartHour;
    int quietestHour = workDayStartHour;
    int maxCount = 0;
    int minCount = timedEvents.length + 1;

    for (int h = workDayStartHour; h < workDayEndHour; h++) {
      final count = hourly[h]!;
      if (count > maxCount) {
        maxCount = count;
        busiestHour = h;
      }
      if (count < minCount) {
        minCount = count;
        quietestHour = h;
      }
    }

    return PeakHoursAnalysis(
      busiestHour: busiestHour,
      busiestHourAvgEvents:
          totalDays > 0 ? maxCount / totalDays.toDouble() : 0,
      quietestHour: quietestHour,
      hourlyDistribution: hourly,
      morningMinutes: morningMins,
      afternoonMinutes: afternoonMins,
      eveningMinutes: eveningMins,
    );
  }

  // ── Priority breakdown ──────────────────────────────────────────

  Map<EventPriority, double> _computePriorityMinutes(
    List<EventModel> timedEvents,
  ) {
    final result = <EventPriority, double>{};
    for (final p in EventPriority.values) result[p] = 0;

    for (final event in timedEvents) {
      final mins = event.duration!.inMinutes.toDouble();
      if (mins >= minEventMinutes) {
        result[event.priority] = result[event.priority]! + mins;
      }
    }

    return result;
  }

  // ── Recommendations ─────────────────────────────────────────────

  List<String> _generateRecommendations({
    required double utilization,
    required List<CategoryTimeAllocation> categoryBreakdown,
    required List<DailyTimeSummary> dailySummaries,
    required PeakHoursAnalysis peakHours,
    required double avgDuration,
    required int pointCount,
    required int totalEvents,
  }) {
    final recs = <String>[];

    // Utilization recommendations
    if (utilization > 0.85) {
      recs.add(
          'Your schedule is very full (${(utilization * 100).toStringAsFixed(0)}% utilized). '
          'Consider leaving buffer time between events to reduce stress.');
    } else if (utilization < 0.3 && totalEvents > 0) {
      recs.add(
          'Low schedule utilization (${(utilization * 100).toStringAsFixed(0)}%). '
          'You have significant free time — consider scheduling focused work blocks.');
    }

    // Category dominance
    if (categoryBreakdown.isNotEmpty &&
        categoryBreakdown.first.percentage > 50) {
      recs.add(
          '"${categoryBreakdown.first.category}" dominates your schedule '
          '(${categoryBreakdown.first.percentage.toStringAsFixed(0)}%). '
          'Consider rebalancing your time across categories.');
    }

    // Uneven daily load
    if (dailySummaries.length >= 3) {
      final rates = dailySummaries.map((d) => d.utilizationRate).toList();
      final avgRate = rates.fold(0.0, (s, r) => s + r) / rates.length;
      final variance = rates
              .map((r) => (r - avgRate) * (r - avgRate))
              .fold(0.0, (s, v) => s + v) /
          rates.length;
      if (variance > 0.04) {
        recs.add(
            'Your daily schedule varies significantly. '
            'Some days are packed while others are light — '
            'try distributing events more evenly.');
      }
    }

    // Context switch overload
    final highSwitchDays =
        dailySummaries.where((d) => d.contextSwitches > 8).length;
    if (highSwitchDays > 0) {
      recs.add(
          '$highSwitchDays day(s) had more than 8 context switches. '
          'Batch similar tasks to reduce mental overhead.');
    }

    // Short event warning
    if (avgDuration > 0 && avgDuration < 20) {
      recs.add(
          'Average event duration is only ${avgDuration.toStringAsFixed(0)} minutes. '
          'Very short events may indicate over-scheduling or interruptions.');
    }

    // Point events
    if (pointCount > totalEvents * 0.3 && totalEvents > 5) {
      recs.add(
          '${(pointCount / totalEvents * 100).toStringAsFixed(0)}% of events '
          'have no end time. Adding durations enables better time analysis.');
    }

    // Time-of-day imbalance
    final totalTod =
        peakHours.morningMinutes +
        peakHours.afternoonMinutes +
        peakHours.eveningMinutes;
    if (totalTod > 0) {
      if (peakHours.eveningMinutes / totalTod > 0.4) {
        recs.add(
            'Over 40% of your time is scheduled in the evening (18:00–22:00). '
            'Consider shifting some activities to morning hours.');
      }
    }

    return recs;
  }

  // ── Utilities ───────────────────────────────────────────────────

  double _median(List<double> sorted) {
    if (sorted.isEmpty) return 0;
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }
}

// ── Internal helpers ────────────────────────────────────────────

class _CategoryAccumulator {
  double totalMinutes = 0;
  int eventCount = 0;
  double longestMinutes = 0;
}
