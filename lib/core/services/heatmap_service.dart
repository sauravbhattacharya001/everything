import '../../models/event_model.dart';

/// A single cell in the heatmap representing one day's event activity.
class HeatmapCell {
  /// The calendar date this cell represents (time portion is midnight).
  final DateTime date;

  /// Number of events on this date.
  final int eventCount;

  /// Number of high/urgent priority events on this date.
  final int urgentCount;

  /// Intensity level from 0 (no events) to 4 (very busy).
  final int intensity;

  /// Whether this date is today.
  final bool isToday;

  /// The events on this date (for drill-down).
  final List<EventModel> events;

  const HeatmapCell({
    required this.date,
    required this.eventCount,
    required this.urgentCount,
    required this.intensity,
    required this.isToday,
    required this.events,
  });

  /// Whether this day has any events.
  bool get hasEvents => eventCount > 0;

  /// Whether this day has urgent/high priority events.
  bool get hasUrgent => urgentCount > 0;
}

/// A full week row in the heatmap (Sun–Sat or Mon–Sun).
class HeatmapWeek {
  /// The 7 cells for this week (index 0 = first day of week).
  final List<HeatmapCell?> cells;

  const HeatmapWeek({required this.cells});
}

/// Summary statistics for the heatmap period.
class HeatmapStats {
  /// Total number of events in the period.
  final int totalEvents;

  /// Number of days with at least one event.
  final int activeDays;

  /// Total number of days in the period.
  final int totalDays;

  /// The busiest single day (most events).
  final HeatmapCell? busiestDay;

  /// Average events per active day.
  final double avgEventsPerActiveDay;

  /// Longest streak of consecutive days with events.
  final int longestStreak;

  /// Current streak (consecutive days with events ending today or yesterday).
  final int currentStreak;

  const HeatmapStats({
    required this.totalEvents,
    required this.activeDays,
    required this.totalDays,
    required this.busiestDay,
    required this.avgEventsPerActiveDay,
    required this.longestStreak,
    required this.currentStreak,
  });

  /// Percentage of days that had events.
  double get activityRate =>
      totalDays > 0 ? (activeDays / totalDays) * 100 : 0;
}

/// Complete heatmap data for rendering.
class HeatmapData {
  /// The year this heatmap covers.
  final int year;

  /// Weeks of heatmap cells, ordered chronologically.
  final List<HeatmapWeek> weeks;

  /// Month labels with their starting week index for axis labels.
  final List<MapEntry<String, int>> monthLabels;

  /// Summary statistics.
  final HeatmapStats stats;

  /// Intensity thresholds used for the legend.
  final List<int> thresholds;

  const HeatmapData({
    required this.year,
    required this.weeks,
    required this.monthLabels,
    required this.stats,
    required this.thresholds,
  });
}

/// Service that generates GitHub-style event density heatmaps.
///
/// Produces a year-at-a-glance grid where each cell represents one day,
/// colored by event density. Supports configurable intensity thresholds
/// and provides drill-down data for each cell.
class HeatmapService {
  /// Default intensity thresholds: [1, 3, 5, 8].
  /// - 0 events → intensity 0 (empty)
  /// - 1–2 events → intensity 1 (light)
  /// - 3–4 events → intensity 2 (medium)
  /// - 5–7 events → intensity 3 (busy)
  /// - 8+ events → intensity 4 (very busy)
  static const List<int> defaultThresholds = [1, 3, 5, 8];

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Generates heatmap data for the given [year] from the event list.
  ///
  /// Events are bucketed by date (ignoring time). Recurring events are
  /// expanded up to [maxRecurrenceExpansion] occurrences per event.
  /// Intensity levels are assigned based on [thresholds].
  HeatmapData generate(
    List<EventModel> events, {
    required int year,
    List<int>? thresholds,
    int maxRecurrenceExpansion = 52,
  }) {
    final effectiveThresholds = thresholds ?? defaultThresholds;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Expand recurring events and bucket all events by date
    final buckets = _bucketByDate(events, year, maxRecurrenceExpansion);

    // Build the weekly grid
    final firstDay = DateTime(year, 1, 1);
    final lastDay = DateTime(year, 12, 31);

    // Start from the Sunday on or before Jan 1
    final gridStart = firstDay.subtract(
      Duration(days: firstDay.weekday % 7),
    );
    // End on the Saturday on or after Dec 31
    final gridEnd = lastDay.add(
      Duration(days: (6 - lastDay.weekday % 7) % 7),
    );

    final weeks = <HeatmapWeek>[];
    final monthLabels = <MapEntry<String, int>>[];
    int? lastMonth;

    var current = gridStart;
    while (!current.isAfter(gridEnd)) {
      final cells = <HeatmapCell?>[];
      for (var d = 0; d < 7; d++) {
        final cellDate = current.add(Duration(days: d));

        // Only include cells within the target year
        if (cellDate.year != year) {
          cells.add(null);
        } else {
          final key = _dateKey(cellDate);
          final dayEvents = buckets[key] ?? [];
          final urgentCount = dayEvents.where((e) =>
              e.priority == EventPriority.urgent ||
              e.priority == EventPriority.high).length;

          cells.add(HeatmapCell(
            date: cellDate,
            eventCount: dayEvents.length,
            urgentCount: urgentCount,
            intensity: _computeIntensity(dayEvents.length, effectiveThresholds),
            isToday: cellDate == today,
            events: dayEvents,
          ));

          // Track month boundaries for labels
          if (lastMonth == null || cellDate.month != lastMonth) {
            if (cellDate.day <= 7) {
              monthLabels.add(MapEntry(
                _monthNames[cellDate.month - 1],
                weeks.length,
              ));
            }
            lastMonth = cellDate.month;
          }
        }
      }
      weeks.add(HeatmapWeek(cells: cells));
      current = current.add(const Duration(days: 7));
    }

    // Compute stats
    final allCells = weeks
        .expand((w) => w.cells)
        .whereType<HeatmapCell>()
        .toList();
    final stats = _computeStats(allCells, today);

    return HeatmapData(
      year: year,
      weeks: weeks,
      monthLabels: monthLabels,
      stats: stats,
      thresholds: effectiveThresholds,
    );
  }

  /// Buckets events by date key (YYYY-MM-DD string) for the given year.
  Map<String, List<EventModel>> _bucketByDate(
    List<EventModel> events,
    int year,
    int maxRecurrence,
  ) {
    final buckets = <String, List<EventModel>>{};
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year, 12, 31, 23, 59, 59);

    for (final event in events) {
      // Include the base event if it falls in the year
      _addToBucket(buckets, event, year);

      // Expand recurring events
      if (event.isRecurring) {
        for (final occurrence in event.generateOccurrences(
          maxOccurrences: maxRecurrence,
        )) {
          if (occurrence.date.isBefore(yearStart)) continue;
          if (occurrence.date.isAfter(yearEnd)) break;
          _addToBucket(buckets, occurrence, year);
        }
      }
    }
    return buckets;
  }

  void _addToBucket(
    Map<String, List<EventModel>> buckets,
    EventModel event,
    int year,
  ) {
    if (event.date.year != year) return;
    final key = _dateKey(event.date);
    buckets.putIfAbsent(key, () => []).add(event);
  }

  /// Computes intensity level (0–4) from event count and thresholds.
  static int _computeIntensity(int count, List<int> thresholds) {
    if (count == 0) return 0;
    for (var i = thresholds.length - 1; i >= 0; i--) {
      if (count >= thresholds[i]) return i + 1;
    }
    return 1;
  }

  /// Generates a date key string for bucketing.
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Computes summary statistics from all heatmap cells.
  HeatmapStats _computeStats(List<HeatmapCell> cells, DateTime today) {
    if (cells.isEmpty) {
      return const HeatmapStats(
        totalEvents: 0,
        activeDays: 0,
        totalDays: 0,
        busiestDay: null,
        avgEventsPerActiveDay: 0,
        longestStreak: 0,
        currentStreak: 0,
      );
    }

    int totalEvents = 0;
    int activeDays = 0;
    HeatmapCell? busiest;

    for (final cell in cells) {
      totalEvents += cell.eventCount;
      if (cell.hasEvents) {
        activeDays++;
        if (busiest == null || cell.eventCount > busiest.eventCount) {
          busiest = cell;
        }
      }
    }

    final avgPerActive = activeDays > 0 ? totalEvents / activeDays : 0.0;

    // Compute streaks from sorted active dates
    final activeDates = cells
        .where((c) => c.hasEvents)
        .map((c) => c.date)
        .toList()
      ..sort();

    int longestStreak = 0;
    int currentStreakLen = 0;
    int runLength = 0;
    DateTime? lastActive;
    DateTime? runEnd;

    for (final d in activeDates) {
      if (lastActive != null &&
          d.difference(lastActive).inDays == 1) {
        runLength++;
      } else {
        runLength = 1;
      }
      if (runLength > longestStreak) {
        longestStreak = runLength;
      }
      runEnd = d;
      lastActive = d;
    }

    // Current streak: must include today or yesterday
    if (runEnd != null) {
      final diff = today.difference(runEnd).inDays;
      if (diff <= 1) {
        currentStreakLen = runLength;
      }
    }

    return HeatmapStats(
      totalEvents: totalEvents,
      activeDays: activeDays,
      totalDays: cells.length,
      busiestDay: busiest,
      avgEventsPerActiveDay: avgPerActive,
      longestStreak: longestStreak,
      currentStreak: currentStreakLen,
    );
  }
}
