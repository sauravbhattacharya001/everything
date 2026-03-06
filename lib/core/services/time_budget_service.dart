/// Time Budget Service — analyzes how users allocate their time across
/// event tags, priorities, and days of the week, with configurable
/// budget targets and overload detection.
///
/// Use this to answer: "Am I spending too much time on Work?", "What does
/// my ideal vs actual time split look like?", "Which days am I overloaded?"

import '../../models/event_model.dart';

/// A budget target for a specific tag or priority category.
class TimeBudget {
  /// The category name (tag name or priority label).
  final String category;

  /// Target hours per week for this category.
  final double targetHoursPerWeek;

  const TimeBudget({
    required this.category,
    required this.targetHoursPerWeek,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeBudget &&
          category == other.category &&
          targetHoursPerWeek == other.targetHoursPerWeek;

  @override
  int get hashCode => Object.hash(category, targetHoursPerWeek);

  @override
  String toString() =>
      'TimeBudget($category: ${targetHoursPerWeek}h/week)';
}

/// Time allocation data for a single category (tag or priority).
class TimeAllocation {
  /// Category name.
  final String category;

  /// Total hours spent in the analysis period.
  final double totalHours;

  /// Number of events in this category.
  final int eventCount;

  /// Average event duration in minutes.
  final double avgDurationMinutes;

  /// Percentage of total tracked time.
  final double percentage;

  /// Budget target (if set), null otherwise.
  final double? budgetHoursPerWeek;

  /// Actual hours per week in the analysis period.
  final double actualHoursPerWeek;

  const TimeAllocation({
    required this.category,
    required this.totalHours,
    required this.eventCount,
    required this.avgDurationMinutes,
    required this.percentage,
    this.budgetHoursPerWeek,
    required this.actualHoursPerWeek,
  });

  /// Whether this category is over budget. Null if no budget set.
  bool? get isOverBudget =>
      budgetHoursPerWeek != null ? actualHoursPerWeek > budgetHoursPerWeek! : null;

  /// Budget utilization as a percentage. Null if no budget set.
  double? get budgetUtilization => budgetHoursPerWeek != null && budgetHoursPerWeek! > 0
      ? (actualHoursPerWeek / budgetHoursPerWeek!) * 100
      : null;

  @override
  String toString() =>
      'TimeAllocation($category: ${totalHours.toStringAsFixed(1)}h, '
      '${percentage.toStringAsFixed(1)}%, $eventCount events)';
}

/// A day that exceeds the configured daily hour threshold.
class OverloadedDay {
  /// The overloaded date.
  final DateTime date;

  /// Total scheduled hours on this day.
  final double totalHours;

  /// Number of events on this day.
  final int eventCount;

  /// How many hours over the threshold.
  final double excessHours;

  const OverloadedDay({
    required this.date,
    required this.totalHours,
    required this.eventCount,
    required this.excessHours,
  });

  @override
  String toString() =>
      'OverloadedDay(${date.toIso8601String().substring(0, 10)}: '
      '${totalHours.toStringAsFixed(1)}h, +${excessHours.toStringAsFixed(1)}h over)';
}

/// Comprehensive time budget analysis result.
class TimeBudgetReport {
  /// Total tracked hours across all events with duration.
  final double totalTrackedHours;

  /// Number of events analyzed (with valid duration).
  final int analyzedEvents;

  /// Number of events skipped (no end date / zero duration).
  final int skippedEvents;

  /// Number of weeks in the analysis period.
  final double weeksInPeriod;

  /// Time allocation breakdown by tag.
  final List<TimeAllocation> byTag;

  /// Time allocation breakdown by priority.
  final List<TimeAllocation> byPriority;

  /// Average hours per day (across the period).
  final double avgHoursPerDay;

  /// Days that exceed the overload threshold.
  final List<OverloadedDay> overloadedDays;

  /// Hours per weekday (0=Monday..6=Sunday).
  final Map<int, double> weekdayHours;

  const TimeBudgetReport({
    required this.totalTrackedHours,
    required this.analyzedEvents,
    required this.skippedEvents,
    required this.weeksInPeriod,
    required this.byTag,
    required this.byPriority,
    required this.avgHoursPerDay,
    required this.overloadedDays,
    required this.weekdayHours,
  });

  /// The tag category consuming the most time.
  TimeAllocation? get topTag =>
      byTag.isEmpty ? null : byTag.first;

  /// The priority level consuming the most time.
  TimeAllocation? get topPriority =>
      byPriority.isEmpty ? null : byPriority.first;

  /// Categories that are over budget.
  List<TimeAllocation> get overBudgetCategories =>
      [...byTag, ...byPriority]
          .where((a) => a.isOverBudget == true)
          .toList();

  /// Name of the busiest weekday.
  String? get busiestWeekday {
    if (weekdayHours.isEmpty) return null;
    final busiest = weekdayHours.entries.reduce(
        (a, b) => a.value >= b.value ? a : b);
    return _weekdayName(busiest.key);
  }

  /// Name of the lightest weekday.
  String? get lightestWeekday {
    if (weekdayHours.isEmpty) return null;
    final lightest = weekdayHours.entries.reduce(
        (a, b) => a.value <= b.value ? a : b);
    return _weekdayName(lightest.key);
  }

  /// Human-readable text summary.
  String get summary {
    final buf = StringBuffer();
    buf.writeln('── Time Budget Report ──');
    buf.writeln('Period: ${weeksInPeriod.toStringAsFixed(1)} weeks');
    buf.writeln('Tracked: ${totalTrackedHours.toStringAsFixed(1)}h '
        'across $analyzedEvents events '
        '($skippedEvents without duration)');
    buf.writeln('Average: ${avgHoursPerDay.toStringAsFixed(1)}h/day');

    if (byTag.isNotEmpty) {
      buf.writeln('\nBy Tag:');
      for (final a in byTag) {
        var line = '  ${a.category}: ${a.totalHours.toStringAsFixed(1)}h '
            '(${a.percentage.toStringAsFixed(0)}%)';
        if (a.budgetUtilization != null) {
          line += ' [${a.budgetUtilization!.toStringAsFixed(0)}% of budget]';
        }
        buf.writeln(line);
      }
    }

    if (byPriority.isNotEmpty) {
      buf.writeln('\nBy Priority:');
      for (final a in byPriority) {
        buf.writeln('  ${a.category}: ${a.totalHours.toStringAsFixed(1)}h '
            '(${a.percentage.toStringAsFixed(0)}%)');
      }
    }

    if (overloadedDays.isNotEmpty) {
      buf.writeln('\nOverloaded Days: ${overloadedDays.length}');
    }

    final over = overBudgetCategories;
    if (over.isNotEmpty) {
      buf.writeln('\n⚠ Over Budget:');
      for (final a in over) {
        buf.writeln('  ${a.category}: '
            '${a.actualHoursPerWeek.toStringAsFixed(1)}h/week '
            'vs ${a.budgetHoursPerWeek!.toStringAsFixed(1)}h target');
      }
    }

    return buf.toString().trimRight();
  }

  @override
  String toString() => 'TimeBudgetReport(${totalTrackedHours.toStringAsFixed(1)}h, '
      '$analyzedEvents events, ${overloadedDays.length} overloaded days)';
}

/// Service that analyzes time allocation across event categories.
class TimeBudgetService {
  /// Budget targets, keyed by lowercase category name.
  final Map<String, TimeBudget> _budgets;

  /// Hours per day threshold for overload detection.
  final double overloadThresholdHours;

  /// Reference date for "today" (configurable for testing).
  final DateTime? _referenceDate;

  /// Creates a TimeBudgetService.
  ///
  /// [budgets] — optional list of budget targets for categories.
  /// [overloadThresholdHours] — daily hours above which a day is "overloaded" (default: 8).
  /// [referenceDate] — override "today" for deterministic testing.
  TimeBudgetService({
    List<TimeBudget> budgets = const [],
    this.overloadThresholdHours = 8.0,
    DateTime? referenceDate,
  })  : _budgets = {
          for (final b in budgets) b.category.toLowerCase(): b,
        },
        _referenceDate = referenceDate;

  DateTime get _today => _dateOnly(_referenceDate ?? DateTime.now());

  /// Analyzes events and produces a [TimeBudgetReport].
  ///
  /// Only events with both [date] and [endDate] (i.e., a duration) are
  /// analyzed for time allocation. Events without duration are counted
  /// as skipped.
  ///
  /// [since] — start of analysis period (defaults to 30 days ago).
  /// [until] — end of analysis period (defaults to today).
  /// [includeRecurring] — expand recurring events into occurrences.
  TimeBudgetReport analyze(
    List<EventModel> events, {
    DateTime? since,
    DateTime? until,
    bool includeRecurring = true,
  }) {
    final allEvents = _expandEvents(events, includeRecurring: includeRecurring);
    final startDate = since != null ? _dateOnly(since) : _today.subtract(const Duration(days: 30));
    final endDate = until != null ? _dateOnly(until) : _today;
    final daysInPeriod = endDate.difference(startDate).inDays + 1;
    final weeksInPeriod = daysInPeriod / 7.0;

    // Filter to events within the analysis period
    final periodEvents = allEvents.where((e) {
      final d = _dateOnly(e.date);
      return !d.isBefore(startDate) && !d.isAfter(endDate);
    }).toList();

    // Separate events with and without duration
    final withDuration = periodEvents.where((e) => e.hasTimeRange).toList();
    final skipped = periodEvents.length - withDuration.length;

    // Total tracked hours
    final totalHours = _totalHours(withDuration);

    // By-tag breakdown
    final byTag = _analyzeByTag(withDuration, totalHours, weeksInPeriod);

    // By-priority breakdown
    final byPriority = _analyzeByPriority(withDuration, totalHours, weeksInPeriod);

    // Daily hours for overload detection
    final dailyHours = _computeDailyHours(withDuration);
    final overloaded = _findOverloadedDays(dailyHours);

    // Weekday distribution
    final weekdayHours = _computeWeekdayHours(withDuration);

    final avgPerDay = daysInPeriod > 0 ? totalHours / daysInPeriod : 0.0;

    return TimeBudgetReport(
      totalTrackedHours: totalHours,
      analyzedEvents: withDuration.length,
      skippedEvents: skipped,
      weeksInPeriod: weeksInPeriod,
      byTag: byTag,
      byPriority: byPriority,
      avgHoursPerDay: avgPerDay,
      overloadedDays: overloaded,
      weekdayHours: Map.unmodifiable(weekdayHours),
    );
  }

  /// Gets time allocation for a specific tag across events.
  TimeAllocation? getAllocationForTag(
    List<EventModel> events,
    String tagName, {
    DateTime? since,
    DateTime? until,
    bool includeRecurring = true,
  }) {
    final report = analyze(events,
        since: since, until: until, includeRecurring: includeRecurring);
    final matches = report.byTag.where(
        (a) => a.category.toLowerCase() == tagName.toLowerCase());
    return matches.isEmpty ? null : matches.first;
  }

  /// Compares actual time allocation against budgets.
  ///
  /// Returns only categories that have a budget set, with utilization data.
  List<TimeAllocation> getBudgetComparison(
    List<EventModel> events, {
    DateTime? since,
    DateTime? until,
    bool includeRecurring = true,
  }) {
    final report = analyze(events,
        since: since, until: until, includeRecurring: includeRecurring);
    return [...report.byTag, ...report.byPriority]
        .where((a) => a.budgetHoursPerWeek != null)
        .toList();
  }

  // ─── Private helpers ──────────────────────────────────────────

  double _totalHours(List<EventModel> events) {
    var total = 0.0;
    for (final e in events) {
      if (e.duration != null && !e.duration!.isNegative) {
        total += e.duration!.inMinutes / 60.0;
      }
    }
    return total;
  }

  List<TimeAllocation> _analyzeByTag(
    List<EventModel> events,
    double totalHours,
    double weeksInPeriod,
  ) {
    final tagHours = <String, double>{};
    final tagCounts = <String, int>{};
    final tagMinutes = <String, List<double>>{};

    for (final e in events) {
      if (e.duration == null || e.duration!.isNegative) continue;
      final mins = e.duration!.inMinutes.toDouble();
      final hours = mins / 60.0;

      // NOTE: Multi-tag events count hours once per tag. Tag percentages
      // may therefore sum to >100% of totalTrackedHours. This is by
      // design — each tag gets the full event duration attributed to it.
      if (e.tags.isEmpty) {
        tagHours['(untagged)'] = (tagHours['(untagged)'] ?? 0) + hours;
        tagCounts['(untagged)'] = (tagCounts['(untagged)'] ?? 0) + 1;
        tagMinutes.putIfAbsent('(untagged)', () => []).add(mins);
      } else {
        for (final tag in e.tags) {
          tagHours[tag.name] = (tagHours[tag.name] ?? 0) + hours;
          tagCounts[tag.name] = (tagCounts[tag.name] ?? 0) + 1;
          tagMinutes.putIfAbsent(tag.name, () => []).add(mins);
        }
      }
    }

    final allocations = <TimeAllocation>[];
    for (final name in tagHours.keys) {
      final hours = tagHours[name]!;
      final count = tagCounts[name]!;
      final durations = tagMinutes[name]!;
      final avgMins = durations.isNotEmpty
          ? durations.reduce((a, b) => a + b) / durations.length
          : 0.0;
      final pct = totalHours > 0 ? (hours / totalHours) * 100 : 0.0;
      final perWeek = weeksInPeriod > 0 ? hours / weeksInPeriod : 0.0;
      final budget = _budgets[name.toLowerCase()];

      allocations.add(TimeAllocation(
        category: name,
        totalHours: hours,
        eventCount: count,
        avgDurationMinutes: avgMins,
        percentage: pct,
        budgetHoursPerWeek: budget?.targetHoursPerWeek,
        actualHoursPerWeek: perWeek,
      ));
    }

    // Sort by total hours descending
    allocations.sort((a, b) => b.totalHours.compareTo(a.totalHours));
    return allocations;
  }

  List<TimeAllocation> _analyzeByPriority(
    List<EventModel> events,
    double totalHours,
    double weeksInPeriod,
  ) {
    final prioHours = <String, double>{};
    final prioCounts = <String, int>{};
    final prioMinutes = <String, List<double>>{};

    for (final e in events) {
      if (e.duration == null || e.duration!.isNegative) continue;
      final mins = e.duration!.inMinutes.toDouble();
      final hours = mins / 60.0;
      final label = e.priority.label;

      prioHours[label] = (prioHours[label] ?? 0) + hours;
      prioCounts[label] = (prioCounts[label] ?? 0) + 1;
      prioMinutes.putIfAbsent(label, () => []).add(mins);
    }

    final allocations = <TimeAllocation>[];
    for (final label in prioHours.keys) {
      final hours = prioHours[label]!;
      final count = prioCounts[label]!;
      final durations = prioMinutes[label]!;
      final avgMins = durations.isNotEmpty
          ? durations.reduce((a, b) => a + b) / durations.length
          : 0.0;
      final pct = totalHours > 0 ? (hours / totalHours) * 100 : 0.0;
      final perWeek = weeksInPeriod > 0 ? hours / weeksInPeriod : 0.0;
      final budget = _budgets[label.toLowerCase()];

      allocations.add(TimeAllocation(
        category: label,
        totalHours: hours,
        eventCount: count,
        avgDurationMinutes: avgMins,
        percentage: pct,
        budgetHoursPerWeek: budget?.targetHoursPerWeek,
        actualHoursPerWeek: perWeek,
      ));
    }

    allocations.sort((a, b) => b.totalHours.compareTo(a.totalHours));
    return allocations;
  }

  Map<DateTime, _DayData> _computeDailyHours(List<EventModel> events) {
    final daily = <DateTime, _DayData>{};
    for (final e in events) {
      if (e.duration == null || e.duration!.isNegative) continue;
      // Split multi-day events across each calendar day they span.
      final start = e.date;
      final end = e.endDate ?? start;
      var cursor = _dateOnly(start);
      final endDay = _dateOnly(end);
      while (!cursor.isAfter(endDay)) {
        final dayStart =
            cursor == _dateOnly(start) ? start : cursor;
        final nextDay = cursor.add(const Duration(days: 1));
        final dayEnd =
            cursor == endDay ? end : nextDay;
        final hours = dayEnd.difference(dayStart).inMinutes / 60.0;
        if (hours > 0) {
          final data = daily.putIfAbsent(cursor, () => _DayData());
          data.hours += hours;
          data.count++;
        }
        cursor = nextDay;
      }
    }
    return daily;
  }

  List<OverloadedDay> _findOverloadedDays(Map<DateTime, _DayData> daily) {
    final overloaded = <OverloadedDay>[];
    for (final entry in daily.entries) {
      if (entry.value.hours > overloadThresholdHours) {
        overloaded.add(OverloadedDay(
          date: entry.key,
          totalHours: entry.value.hours,
          eventCount: entry.value.count,
          excessHours: entry.value.hours - overloadThresholdHours,
        ));
      }
    }
    overloaded.sort((a, b) => b.totalHours.compareTo(a.totalHours));
    return overloaded;
  }

  Map<int, double> _computeWeekdayHours(List<EventModel> events) {
    final weekday = <int, double>{};
    for (final e in events) {
      if (e.duration == null || e.duration!.isNegative) continue;
      // Split multi-day events across each calendar day's weekday.
      final start = e.date;
      final end = e.endDate ?? start;
      var cursor = _dateOnly(start);
      final endDay = _dateOnly(end);
      while (!cursor.isAfter(endDay)) {
        final dayStart =
            cursor == _dateOnly(start) ? start : cursor;
        final nextDay = cursor.add(const Duration(days: 1));
        final dayEnd =
            cursor == endDay ? end : nextDay;
        final hours = dayEnd.difference(dayStart).inMinutes / 60.0;
        if (hours > 0) {
          final wd = cursor.weekday - 1; // 0=Mon..6=Sun
          weekday[wd] = (weekday[wd] ?? 0) + hours;
        }
        cursor = nextDay;
      }
    }
    return weekday;
  }

  List<EventModel> _expandEvents(
    List<EventModel> events, {
    required bool includeRecurring,
  }) {
    if (!includeRecurring) return events;
    final expanded = <EventModel>[];
    for (final e in events) {
      expanded.add(e);
      if (e.isRecurring) {
        expanded.addAll(e.generateOccurrences());
      }
    }
    return expanded;
  }
}

class _DayData {
  double hours = 0;
  int count = 0;
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String _weekdayName(int weekday) {
  const names = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  return names[weekday.clamp(0, 6)];
}
