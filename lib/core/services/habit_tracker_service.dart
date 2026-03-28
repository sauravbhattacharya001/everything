/// Habit Tracker Service — manage daily habits, log completions, and analyze
/// completion rates, streaks, and weekly summaries.
///
/// Features:
/// - Define habits with daily/weekday/weekend/custom schedules
/// - Count-based habits (e.g., "drink 8 glasses of water")
/// - Log completions with optional notes
/// - Completion rate calculation over any date range
/// - Current and longest streak tracking per habit
/// - Weekly summary with per-habit breakdown
/// - Habit archiving (soft delete)

import '../../models/habit.dart';
import 'service_persistence.dart';

/// Stats for a single habit over a date range.
class HabitStats {
  final Habit habit;

  /// Number of days the habit was scheduled in the range.
  final int scheduledDays;

  /// Number of days the habit was completed (count >= target).
  final int completedDays;

  /// Total completions logged (sum of counts).
  final int totalCompletions;

  /// Completion rate (0.0 – 1.0).
  final double completionRate;

  /// Current consecutive-day streak (ending today or most recent).
  final int currentStreak;

  /// Longest streak ever for this habit.
  final int longestStreak;

  const HabitStats({
    required this.habit,
    required this.scheduledDays,
    required this.completedDays,
    required this.totalCompletions,
    required this.completionRate,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  String toString() {
    final pct = (completionRate * 100).toStringAsFixed(0);
    final icon = habit.emoji ?? '📌';
    return '$icon ${habit.name}: $pct% ($completedDays/$scheduledDays days) '
        '| streak: $currentStreak | best: $longestStreak';
  }
}

/// Weekly summary across all habits.
class WeeklyHabitSummary {
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<HabitStats> habitStats;

  /// Overall completion rate across all habits.
  final double overallRate;

  /// Total habits tracked this week.
  final int totalHabits;

  /// Number of perfect days (all scheduled habits completed).
  final int perfectDays;

  const WeeklyHabitSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.habitStats,
    required this.overallRate,
    required this.totalHabits,
    required this.perfectDays,
  });

  String get summary {
    final pct = (overallRate * 100).toStringAsFixed(0);
    final buf = StringBuffer()
      ..writeln('📊 Weekly Habit Summary')
      ..writeln('${_fmt(weekStart)} – ${_fmt(weekEnd)}')
      ..writeln('Overall: $pct% | Perfect days: $perfectDays/7')
      ..writeln('─' * 40);
    for (final s in habitStats) {
      buf.writeln(s.toString());
    }
    return buf.toString();
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Main service for habit tracking.
class HabitTrackerService with ServicePersistence {
  final List<Habit> _habits;
  final List<HabitCompletion> _completions;

  @override
  String get storageKey => 'habit_tracker_data';

  @override
  Map<String, dynamic> toStorageJson() => {
        'habits': _habits.map((h) => h.toJson()).toList(),
        'completions': _completions.map((c) => c.toJson()).toList(),
      };

  @override
  void fromStorageJson(Map<String, dynamic> json) {
    _habits.clear();
    _completions.clear();
    if (json['habits'] != null) {
      _habits.addAll(
        (json['habits'] as List).map((h) => Habit.fromJson(h as Map<String, dynamic>)),
      );
    }
    if (json['completions'] != null) {
      _completions.addAll(
        (json['completions'] as List).map((c) => HabitCompletion.fromJson(c as Map<String, dynamic>)),
      );
    }
  }

  HabitTrackerService({
    List<Habit>? habits,
    List<HabitCompletion>? completions,
  })  : _habits = habits ?? [],
        _completions = completions ?? [];

  /// All active habits.
  List<Habit> get activeHabits =>
      _habits.where((h) => h.isActive).toList();

  /// All habits including archived.
  List<Habit> get allHabits => List.unmodifiable(_habits);

  /// All completions.
  List<HabitCompletion> get completions => List.unmodifiable(_completions);

  // ── Habit Management ──────────────────────────────────────────────

  /// Add a new habit.
  void addHabit(Habit habit) {
    if (_habits.any((h) => h.id == habit.id)) {
      throw ArgumentError('Habit with id "${habit.id}" already exists');
    }
    _habits.add(habit);
  }

  /// Update an existing habit.
  void updateHabit(Habit updated) {
    final idx = _habits.indexWhere((h) => h.id == updated.id);
    if (idx == -1) {
      throw ArgumentError('Habit "${updated.id}" not found');
    }
    _habits[idx] = updated;
  }

  /// Archive a habit (soft delete).
  void archiveHabit(String habitId) {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return;
    _habits[idx] = _habits[idx].copyWith(isActive: false);
  }

  // ── Completion Logging ────────────────────────────────────────────

  /// Log a completion for a habit on a specific date.
  /// If a completion already exists for that date, increments the count.
  void logCompletion(String habitId, DateTime date, {String? note}) {
    final d = _dateOnly(date);
    final existing = _completions.indexWhere(
      (c) => c.habitId == habitId && _dateOnly(c.date) == d,
    );
    if (existing >= 0) {
      final old = _completions[existing];
      _completions[existing] = HabitCompletion(
        habitId: habitId,
        date: d,
        count: old.count + 1,
        note: note ?? old.note,
      );
    } else {
      _completions.add(HabitCompletion(
        habitId: habitId,
        date: d,
        count: 1,
        note: note,
      ));
    }
  }

  /// Remove a completion entry for a habit on a specific date.
  void removeCompletion(String habitId, DateTime date) {
    final d = _dateOnly(date);
    _completions.removeWhere(
      (c) => c.habitId == habitId && _dateOnly(c.date) == d,
    );
  }

  /// Get completions for a habit in a date range.
  List<HabitCompletion> getCompletions(
    String habitId, {
    DateTime? from,
    DateTime? to,
  }) {
    return _completions.where((c) {
      if (c.habitId != habitId) return false;
      final d = _dateOnly(c.date);
      if (from != null && d.isBefore(_dateOnly(from))) return false;
      if (to != null && d.isAfter(_dateOnly(to))) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ── Statistics ────────────────────────────────────────────────────

  /// Calculate stats for a single habit over a date range.
  HabitStats getHabitStats(
    String habitId, {
    required DateTime from,
    required DateTime to,
  }) {
    final habit = _habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => throw ArgumentError('Habit "$habitId" not found'),
    );
    final start = _dateOnly(from);
    final end = _dateOnly(to);

    int scheduledDays = 0;
    int completedDays = 0;
    int totalCompletions = 0;

    for (var d = start;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      if (!habit.isScheduledFor(d.weekday)) continue;
      scheduledDays++;
      final comp = _completionFor(habitId, d);
      if (comp != null) {
        totalCompletions += comp.count;
        if (comp.count >= habit.targetCount) completedDays++;
      }
    }

    final rate = scheduledDays > 0 ? completedDays / scheduledDays : 0.0;

    return HabitStats(
      habit: habit,
      scheduledDays: scheduledDays,
      completedDays: completedDays,
      totalCompletions: totalCompletions,
      completionRate: rate,
      currentStreak: _currentStreak(habit, end),
      longestStreak: _longestStreak(habit, start, end),
    );
  }

  /// Weekly summary for all active habits.
  WeeklyHabitSummary weeklySummary({DateTime? referenceDate}) {
    final ref = _dateOnly(referenceDate ?? DateTime.now());
    // Week starts on Monday.
    final weekStart = ref.subtract(Duration(days: ref.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final stats = activeHabits
        .map((h) => getHabitStats(h.id, from: weekStart, to: weekEnd))
        .toList();

    final totalScheduled = stats.fold<int>(0, (s, h) => s + h.scheduledDays);
    final totalCompleted = stats.fold<int>(0, (s, h) => s + h.completedDays);
    final overallRate =
        totalScheduled > 0 ? totalCompleted / totalScheduled : 0.0;

    // Count perfect days.
    int perfectDays = 0;
    for (var d = weekStart;
        !d.isAfter(weekEnd);
        d = d.add(const Duration(days: 1))) {
      bool allDone = true;
      for (final h in activeHabits) {
        if (!h.isScheduledFor(d.weekday)) continue;
        final comp = _completionFor(h.id, d);
        if (comp == null || comp.count < h.targetCount) {
          allDone = false;
          break;
        }
      }
      if (allDone) perfectDays++;
    }

    return WeeklyHabitSummary(
      weekStart: weekStart,
      weekEnd: weekEnd,
      habitStats: stats,
      overallRate: overallRate,
      totalHabits: activeHabits.length,
      perfectDays: perfectDays,
    );
  }

  /// Get today's status: which habits are due, which are done.
  List<({Habit habit, bool completed, int count, int target})> todayStatus({
    DateTime? referenceDate,
  }) {
    final today = _dateOnly(referenceDate ?? DateTime.now());
    return activeHabits
        .where((h) => h.isScheduledFor(today.weekday))
        .map((h) {
      final comp = _completionFor(h.id, today);
      return (
        habit: h,
        completed: (comp?.count ?? 0) >= h.targetCount,
        count: comp?.count ?? 0,
        target: h.targetCount,
      );
    }).toList();
  }

  // ── Streak Helpers ────────────────────────────────────────────────

  int _currentStreak(Habit habit, DateTime endDate) {
    int streak = 0;
    var d = endDate;
    while (true) {
      if (!habit.isScheduledFor(d.weekday)) {
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      final comp = _completionFor(habit.id, d);
      if (comp == null || comp.count < habit.targetCount) break;
      streak++;
      d = d.subtract(const Duration(days: 1));
      // Safety limit.
      if (streak > 3650) break;
    }
    return streak;
  }

  int _longestStreak(Habit habit, DateTime start, DateTime end) {
    int longest = 0;
    int current = 0;
    for (var d = start;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      if (!habit.isScheduledFor(d.weekday)) continue;
      final comp = _completionFor(habit.id, d);
      if (comp != null && comp.count >= habit.targetCount) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    return longest;
  }

  // ── Private Helpers ───────────────────────────────────────────────

  HabitCompletion? _completionFor(String habitId, DateTime date) {
    final d = _dateOnly(date);
    final matches = _completions.where(
      (c) => c.habitId == habitId && _dateOnly(c.date) == d,
    );
    return matches.isEmpty ? null : matches.first;
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
