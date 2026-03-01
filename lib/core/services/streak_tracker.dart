/// Event Streak Tracker — analyzes event activity patterns to calculate
/// consecutive-day streaks, activity rates, and streak history.
///
/// A "streak" is a series of consecutive calendar days where at least one
/// event exists. Streaks help users stay motivated by visualizing consistency.

import '../../models/event_model.dart';

/// A single streak period with start/end dates and length.
class Streak {
  /// First day of the streak (date only, no time).
  final DateTime startDate;

  /// Last day of the streak (date only, no time).
  final DateTime endDate;

  /// Number of consecutive days in this streak.
  final int length;

  const Streak({
    required this.startDate,
    required this.endDate,
    required this.length,
  });

  /// Whether this streak is still active (includes today or the reference date).
  bool isActiveOn(DateTime referenceDate) {
    final ref = _dateOnly(referenceDate);
    return !endDate.isAfter(ref) &&
        !ref.isAfter(endDate.add(const Duration(days: 1)));
  }

  /// Human-readable summary of the streak.
  String get summary {
    if (length == 1) {
      return '1 day (${_formatDate(startDate)})';
    }
    return '$length days (${_formatDate(startDate)} – ${_formatDate(endDate)})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Streak &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          length == other.length;

  @override
  int get hashCode => Object.hash(startDate, endDate, length);

  @override
  String toString() => 'Streak($summary)';
}

/// Activity statistics for a given set of events.
class ActivityStats {
  /// Total number of unique days with at least one event.
  final int activeDays;

  /// Total days in the analysis period.
  final int totalDays;

  /// Average events per active day.
  final double eventsPerActiveDay;

  /// Most active day of the week (0=Monday, 6=Sunday). Null if no events.
  final int? busiestWeekday;

  /// Events on the busiest weekday.
  final int busiestWeekdayCount;

  /// Number of events per weekday (0=Monday..6=Sunday).
  final Map<int, int> weekdayDistribution;

  const ActivityStats({
    required this.activeDays,
    required this.totalDays,
    required this.eventsPerActiveDay,
    this.busiestWeekday,
    this.busiestWeekdayCount = 0,
    this.weekdayDistribution = const {},
  });

  /// Activity rate as a percentage (0-100).
  double get activityRate =>
      totalDays > 0 ? (activeDays / totalDays) * 100 : 0;

  /// Name of the busiest weekday, or null.
  String? get busiestWeekdayName {
    if (busiestWeekday == null) return null;
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[busiestWeekday!.clamp(0, 6)];
  }

  @override
  String toString() =>
      'ActivityStats(active: $activeDays/$totalDays days, '
      'rate: ${activityRate.toStringAsFixed(1)}%, '
      'busiest: $busiestWeekdayName)';
}

/// Comprehensive streak analysis result.
class StreakReport {
  /// Current active streak (0 if no streak is active today).
  final int currentStreak;

  /// Longest streak ever recorded.
  final int longestStreak;

  /// Total number of distinct streaks found.
  final int totalStreaks;

  /// All streaks sorted by start date (newest first).
  final List<Streak> streaks;

  /// Activity statistics for the analysis period.
  final ActivityStats stats;

  /// The longest streak object, or null if no events.
  final Streak? longestStreakDetails;

  /// The current active streak object, or null if not active.
  final Streak? currentStreakDetails;

  const StreakReport({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalStreaks,
    required this.streaks,
    required this.stats,
    this.longestStreakDetails,
    this.currentStreakDetails,
  });

  /// Whether the user has an active streak right now.
  bool get isStreakActive => currentStreak > 0;

  /// Motivational message based on current streak.
  String get motivationMessage {
    if (currentStreak == 0) {
      return 'Start a new streak today! Add an event to get going.';
    } else if (currentStreak < 3) {
      return 'Nice start! Keep it up for $currentStreak more days.';
    } else if (currentStreak < 7) {
      return 'Great momentum! $currentStreak days and counting! 🔥';
    } else if (currentStreak < 14) {
      return 'Impressive! $currentStreak-day streak! You\'re on fire! 🔥🔥';
    } else if (currentStreak < 30) {
      return 'Amazing! $currentStreak days strong! Unstoppable! 🔥🔥🔥';
    } else {
      return 'Legendary $currentStreak-day streak! 🏆🔥';
    }
  }

  /// Text summary of the full report.
  String get summary {
    final buf = StringBuffer();
    buf.writeln('── Streak Report ──');
    buf.writeln('Current streak: $currentStreak day${currentStreak == 1 ? '' : 's'}');
    buf.writeln('Longest streak: $longestStreak day${longestStreak == 1 ? '' : 's'}');
    buf.writeln('Total streaks: $totalStreaks');
    buf.writeln('Active days: ${stats.activeDays}/${stats.totalDays} '
        '(${stats.activityRate.toStringAsFixed(1)}%)');
    if (stats.busiestWeekdayName != null) {
      buf.writeln('Busiest day: ${stats.busiestWeekdayName} '
          '(${stats.busiestWeekdayCount} events)');
    }
    buf.writeln(motivationMessage);
    return buf.toString().trimRight();
  }

  @override
  String toString() => 'StreakReport(current: $currentStreak, '
      'longest: $longestStreak, streaks: $totalStreaks)';
}

/// Service that analyzes event lists for streak patterns.
class StreakTracker {
  /// Reference date for "today" (defaults to DateTime.now()).
  /// Configurable for testing.
  final DateTime? _referenceDate;

  /// Create a StreakTracker. Pass [referenceDate] for deterministic testing.
  StreakTracker({DateTime? referenceDate}) : _referenceDate = referenceDate;

  DateTime get _today => _dateOnly(_referenceDate ?? DateTime.now());

  /// Analyze events and produce a full [StreakReport].
  ///
  /// Events are analyzed from [since] (defaults to 365 days ago) up to today.
  /// Set [includeRecurring] to expand recurring event occurrences.
  StreakReport analyze(
    List<EventModel> events, {
    DateTime? since,
    bool includeRecurring = true,
  }) {
    final allEvents = _expandEvents(events, includeRecurring: includeRecurring);
    final activeDays = _getActiveDays(allEvents);
    final startDate = since != null ? _dateOnly(since) : _today.subtract(const Duration(days: 365));
    final streaks = _computeStreaks(activeDays);
    final stats = _computeStats(allEvents, activeDays, startDate);

    // Sort streaks newest first
    final sorted = List<Streak>.from(streaks)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    // Find longest
    Streak? longest;
    int longestLen = 0;
    for (final s in sorted) {
      if (s.length > longestLen) {
        longestLen = s.length;
        longest = s;
      }
    }

    // Find current (active today or yesterday)
    Streak? current;
    int currentLen = 0;
    for (final s in sorted) {
      if (s.isActiveOn(_today)) {
        current = s;
        currentLen = s.length;
        break;
      }
    }

    return StreakReport(
      currentStreak: currentLen,
      longestStreak: longestLen,
      totalStreaks: sorted.length,
      streaks: sorted,
      stats: stats,
      longestStreakDetails: longest,
      currentStreakDetails: current,
    );
  }

  /// Get just the current streak length (lighter than full [analyze]).
  ///
  /// Walks backward from the most recent active day. The streak is only
  /// "current" if today or yesterday is active; otherwise returns 0.
  /// Prefer this over [analyze] when only the current streak count is needed.
  int currentStreakLength(List<EventModel> events, {bool includeRecurring = true}) {
    final allEvents = _expandEvents(events, includeRecurring: includeRecurring);
    final activeDays = _getActiveDays(allEvents);

    if (activeDays.isEmpty) return 0;

    final sorted = activeDays.toList()..sort((a, b) => b.compareTo(a));

    // Must include today or yesterday to be "current"
    final latest = sorted.first;
    final diff = _today.difference(latest).inDays;
    if (diff > 1) return 0;

    int count = 1;
    for (int i = 1; i < sorted.length; i++) {
      final gap = sorted[i - 1].difference(sorted[i]).inDays;
      if (gap == 1) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Get the longest streak length from events.
  ///
  /// Scans all active days and finds the maximum run of consecutive days.
  /// Returns 0 if no events exist. Lighter than [analyze] when only the
  /// record length is needed.
  int longestStreakLength(List<EventModel> events, {bool includeRecurring = true}) {
    final allEvents = _expandEvents(events, includeRecurring: includeRecurring);
    final activeDays = _getActiveDays(allEvents);

    if (activeDays.isEmpty) return 0;

    final sorted = activeDays.toList()..sort();
    int longest = 1;
    int current = 1;

    for (int i = 1; i < sorted.length; i++) {
      final gap = sorted[i].difference(sorted[i - 1]).inDays;
      if (gap == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  /// Get dates that would extend the current streak if an event were added.
  ///
  /// Suggests today (if not yet active) plus upcoming days that keep the
  /// streak going. Returns up to [count] dates in chronological order.
  /// Useful for gamification prompts ("Add an event today to keep your streak!").
  List<DateTime> suggestDates(List<EventModel> events, {int count = 3, bool includeRecurring = true}) {
    final allEvents = _expandEvents(events, includeRecurring: includeRecurring);
    final activeDays = _getActiveDays(allEvents);
    final suggestions = <DateTime>[];

    // Always suggest today if not active
    if (!activeDays.contains(_today)) {
      suggestions.add(_today);
    }

    // Suggest upcoming days that would extend a streak
    for (int i = 1; i <= count + 1 && suggestions.length < count; i++) {
      final futureDate = _today.add(Duration(days: i));
      if (!activeDays.contains(futureDate)) {
        suggestions.add(futureDate);
      }
    }

    return suggestions.take(count).toList();
  }

  // ─── Private helpers ──────────────────────────────────────────

  /// Expands recurring events into individual occurrences.
  ///
  /// When [includeRecurring] is true, each recurring event generates
  /// its occurrences via [EventModel.generateOccurrences]. Non-recurring
  /// events are always included.
  List<EventModel> _expandEvents(List<EventModel> events, {required bool includeRecurring}) {
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

  /// Extracts the set of unique calendar days that have at least one event.
  Set<DateTime> _getActiveDays(List<EventModel> events) {
    return events.map((e) => _dateOnly(e.date)).toSet();
  }

  /// Identifies consecutive-day runs from a set of active dates.
  ///
  /// Sorts dates chronologically and groups them into [Streak] objects
  /// wherever consecutive days form an unbroken chain. A gap of 2+ days
  /// ends the current streak and starts a new one.
  List<Streak> _computeStreaks(Set<DateTime> activeDays) {
    if (activeDays.isEmpty) return [];

    final sorted = activeDays.toList()..sort();
    final streaks = <Streak>[];

    var streakStart = sorted[0];
    var prev = sorted[0];

    for (int i = 1; i < sorted.length; i++) {
      final gap = sorted[i].difference(prev).inDays;
      if (gap > 1) {
        streaks.add(Streak(
          startDate: streakStart,
          endDate: prev,
          length: prev.difference(streakStart).inDays + 1,
        ));
        streakStart = sorted[i];
      }
      prev = sorted[i];
    }

    // Close final streak
    streaks.add(Streak(
      startDate: streakStart,
      endDate: prev,
      length: prev.difference(streakStart).inDays + 1,
    ));

    return streaks;
  }

  /// Computes aggregate activity statistics from events and active days.
  ///
  /// Calculates active-day ratio, events-per-active-day average, and
  /// weekday distribution. The analysis window spans from [since] to
  /// today (inclusive).
  ActivityStats _computeStats(
    List<EventModel> events,
    Set<DateTime> activeDays,
    DateTime since,
  ) {
    final totalDays = _today.difference(since).inDays + 1;
    final eventsPerDay = activeDays.isNotEmpty
        ? events.length / activeDays.length
        : 0.0;

    // Weekday distribution (1=Monday..7=Sunday in Dart → remap to 0=Mon..6=Sun)
    final weekdayDist = <int, int>{};
    for (final e in events) {
      final wd = e.date.weekday - 1; // 0=Mon..6=Sun
      weekdayDist[wd] = (weekdayDist[wd] ?? 0) + 1;
    }

    int? busiestDay;
    int busiestCount = 0;
    for (final entry in weekdayDist.entries) {
      if (entry.value > busiestCount) {
        busiestCount = entry.value;
        busiestDay = entry.key;
      }
    }

    return ActivityStats(
      activeDays: activeDays.length,
      totalDays: totalDays > 0 ? totalDays : 0,
      eventsPerActiveDay: eventsPerDay,
      busiestWeekday: busiestDay,
      busiestWeekdayCount: busiestCount,
      weekdayDistribution: Map.unmodifiable(weekdayDist),
    );
  }
}

// ─── Utilities ──────────────────────────────────────────────────

/// Strips the time component from a [DateTime], returning midnight on that day.
DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Formats a date as "Mon DD" (e.g., "Jan 15").
String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[dt.month - 1]} ${dt.day}';
}
