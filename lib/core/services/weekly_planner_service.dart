/// Weekly Planner Service — generates a structured weekly plan by analyzing
/// upcoming events, active goals, scheduled habits, and available free time.
///
/// Produces a day-by-day plan with:
///   - **Scheduled events** from the calendar
///   - **Goal work blocks** allocated into free time slots
///   - **Habit reminders** based on each habit's frequency
///   - **Free time windows** for unstructured use
///   - **Daily load scores** indicating how packed each day is
///   - **Warnings** for overloaded days, deadline conflicts, and neglected goals
///
/// The planner respects working hours (configurable), minimum block sizes,
/// and goal urgency (deadline proximity × remaining progress).

import '../../models/event_model.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';

// ─── Configuration ──────────────────────────────────────────────

/// Configuration for the weekly planner.
class PlannerConfig {
  /// Start of working/planning hours (0–23).
  final int dayStartHour;

  /// End of working/planning hours (0–23).
  final int dayEndHour;

  /// Minimum free block size (minutes) to be considered usable.
  final int minBlockMinutes;

  /// Default duration (minutes) for a goal work session.
  final int goalBlockMinutes;

  /// Maximum planned hours per day before triggering an overload warning.
  final double maxDailyHours;

  /// Days ahead to plan (1–14).
  final int planDays;

  /// Buffer minutes between consecutive planned items.
  final int bufferMinutes;

  const PlannerConfig({
    this.dayStartHour = 8,
    this.dayEndHour = 20,
    this.minBlockMinutes = 30,
    this.goalBlockMinutes = 60,
    this.maxDailyHours = 10.0,
    this.planDays = 7,
    this.bufferMinutes = 15,
  });

  /// Plannable minutes per day.
  int get dailyMinutes => (dayEndHour - dayStartHour) * 60;
}

// ─── Data Classes ───────────────────────────────────────────────

/// Types of items in the plan.
enum PlanItemType {
  event,
  goalWork,
  habit,
  freeTime,
}

/// A single planned item in the daily schedule.
class PlanItem {
  /// Type of this plan item.
  final PlanItemType type;

  /// Display title.
  final String title;

  /// Start time of this block.
  final DateTime start;

  /// End time of this block.
  final DateTime end;

  /// Duration in minutes.
  int get minutes => end.difference(start).inMinutes;

  /// Optional reference ID (event ID, goal ID, or habit ID).
  final String? refId;

  /// Optional category label (goal category, event tag, etc.).
  final String? category;

  /// Priority score (higher = more important). Used for sorting suggestions.
  final double priority;

  const PlanItem({
    required this.type,
    required this.title,
    required this.start,
    required this.end,
    this.refId,
    this.category,
    this.priority = 0,
  });

  @override
  String toString() {
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startStr–$endStr ${type.name}: $title (${minutes}min)';
  }
}

/// Warning about potential planning issues.
class PlanWarning {
  /// Warning severity.
  final WarningSeverity severity;

  /// Which day this warning applies to (null = week-level).
  final DateTime? date;

  /// Human-readable warning message.
  final String message;

  /// Optional reference ID.
  final String? refId;

  const PlanWarning({
    required this.severity,
    this.date,
    required this.message,
    this.refId,
  });

  @override
  String toString() {
    final dateStr = date != null
        ? '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}: '
        : '';
    return '[${severity.name}] $dateStr$message';
  }
}

enum WarningSeverity { info, warning, critical }

/// A single day's plan.
class DailyPlan {
  /// The date of this plan.
  final DateTime date;

  /// All planned items, sorted by start time.
  final List<PlanItem> items;

  /// Load score: planned minutes / available minutes (0.0–1.0+).
  final double loadScore;

  /// Warnings specific to this day.
  final List<PlanWarning> warnings;

  const DailyPlan({
    required this.date,
    required this.items,
    required this.loadScore,
    required this.warnings,
  });

  /// Total planned minutes (excluding free time).
  int get plannedMinutes => items
      .where((i) => i.type != PlanItemType.freeTime)
      .fold(0, (sum, i) => sum + i.minutes);

  /// Total free minutes.
  int get freeMinutes => items
      .where((i) => i.type == PlanItemType.freeTime)
      .fold(0, (sum, i) => sum + i.minutes);

  /// Number of events.
  int get eventCount =>
      items.where((i) => i.type == PlanItemType.event).length;

  /// Number of goal work blocks.
  int get goalBlockCount =>
      items.where((i) => i.type == PlanItemType.goalWork).length;

  /// Number of habit items.
  int get habitCount =>
      items.where((i) => i.type == PlanItemType.habit).length;

  /// Human-readable load label.
  String get loadLabel {
    if (loadScore >= 1.0) return 'overloaded';
    if (loadScore >= 0.8) return 'heavy';
    if (loadScore >= 0.5) return 'moderate';
    if (loadScore >= 0.2) return 'light';
    return 'free';
  }

  /// Day-of-week name.
  String get weekdayName {
    const names = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return names[date.weekday - 1];
  }

  @override
  String toString() {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$weekdayName $dateStr: $loadLabel (${plannedMinutes}min planned, '
        '${freeMinutes}min free, ${items.length} items)';
  }
}

/// The complete weekly plan.
class WeeklyPlan {
  /// Daily plans in chronological order.
  final List<DailyPlan> days;

  /// Week-level warnings.
  final List<PlanWarning> warnings;

  /// Configuration used to generate this plan.
  final PlannerConfig config;

  /// When this plan was generated.
  final DateTime generatedAt;

  const WeeklyPlan({
    required this.days,
    required this.warnings,
    required this.config,
    required this.generatedAt,
  });

  /// All warnings (week-level + daily).
  List<PlanWarning> get allWarnings => [
        ...warnings,
        for (final day in days) ...day.warnings,
      ];

  /// Total planned minutes across the week (excluding free time).
  int get totalPlannedMinutes =>
      days.fold(0, (sum, d) => sum + d.plannedMinutes);

  /// Total free minutes across the week.
  int get totalFreeMinutes => days.fold(0, (sum, d) => sum + d.freeMinutes);

  /// Average daily load score.
  double get avgLoadScore {
    if (days.isEmpty) return 0;
    return days.fold(0.0, (sum, d) => sum + d.loadScore) / days.length;
  }

  /// Number of overloaded days.
  int get overloadedDays =>
      days.where((d) => d.loadScore >= 1.0).length;

  /// Goals that received work blocks.
  Set<String> get scheduledGoalIds => days
      .expand((d) => d.items)
      .where((i) => i.type == PlanItemType.goalWork && i.refId != null)
      .map((i) => i.refId!)
      .toSet();

  /// Human-readable text summary.
  String get summary {
    final buf = StringBuffer();
    buf.writeln('── Weekly Plan ──');
    buf.writeln(
        'Generated: ${generatedAt.toIso8601String().substring(0, 16)}');
    buf.writeln(
        'Total: ${(totalPlannedMinutes / 60).toStringAsFixed(1)}h planned, '
        '${(totalFreeMinutes / 60).toStringAsFixed(1)}h free');
    buf.writeln(
        'Avg load: ${(avgLoadScore * 100).toStringAsFixed(0)}% '
        '(${overloadedDays} overloaded day${overloadedDays != 1 ? 's' : ''})');

    for (final day in days) {
      buf.writeln('\n${day.weekdayName} (${day.loadLabel}):');
      for (final item in day.items) {
        buf.writeln('  $item');
      }
      for (final w in day.warnings) {
        buf.writeln('  ⚠ ${w.message}');
      }
    }

    if (warnings.isNotEmpty) {
      buf.writeln('\nWeek-level warnings:');
      for (final w in warnings) {
        buf.writeln('  $w');
      }
    }

    return buf.toString().trimRight();
  }

  @override
  String toString() =>
      'WeeklyPlan(${days.length} days, '
      '${totalPlannedMinutes}min planned, '
      '${allWarnings.length} warnings)';
}

// ─── Service ────────────────────────────────────────────────────

/// Service that generates a weekly plan from events, goals, and habits.
class WeeklyPlannerService {
  final PlannerConfig config;

  /// Override "now" for deterministic testing.
  final DateTime? _referenceDate;

  WeeklyPlannerService({
    this.config = const PlannerConfig(),
    DateTime? referenceDate,
  }) : _referenceDate = referenceDate;

  DateTime get _now => _referenceDate ?? DateTime.now();

  /// Generate a weekly plan.
  ///
  /// [events] — calendar events (may include recurring events).
  /// [goals] — active goals to schedule work blocks for.
  /// [habits] — habits to include as daily reminders.
  /// [habitCompletions] — past completions to check today's status.
  WeeklyPlan generate({
    List<EventModel> events = const [],
    List<Goal> goals = const [],
    List<Habit> habits = const [],
    List<HabitCompletion> habitCompletions = const [],
  }) {
    final startDate = _dateOnly(_now);
    final endDate = startDate.add(Duration(days: config.planDays));

    // Expand recurring events
    final allEvents = _expandEvents(events, startDate, endDate);

    // Score and sort goals by urgency
    final scoredGoals = _scoreGoals(goals, startDate);

    // Generate daily plans
    final dailyPlans = <DailyPlan>[];
    final weekWarnings = <PlanWarning>[];

    // Track how many blocks each goal has received
    final goalBlockCounts = <String, int>{};

    for (var dayOffset = 0; dayOffset < config.planDays; dayOffset++) {
      final day = startDate.add(Duration(days: dayOffset));
      final dayPlan = _planDay(
        day: day,
        events: allEvents,
        scoredGoals: scoredGoals,
        habits: habits,
        habitCompletions: habitCompletions,
        goalBlockCounts: goalBlockCounts,
      );
      dailyPlans.add(dayPlan);
    }

    // Week-level warnings
    _addWeekWarnings(weekWarnings, dailyPlans, goals, scoredGoals,
        goalBlockCounts);

    return WeeklyPlan(
      days: dailyPlans,
      warnings: weekWarnings,
      config: config,
      generatedAt: _now,
    );
  }

  /// Plan a single day.
  DailyPlan _planDay({
    required DateTime day,
    required List<EventModel> events,
    required List<_ScoredGoal> scoredGoals,
    required List<Habit> habits,
    required List<HabitCompletion> habitCompletions,
    required Map<String, int> goalBlockCounts,
  }) {
    final dayStart =
        DateTime(day.year, day.month, day.day, config.dayStartHour);
    final dayEnd = DateTime(day.year, day.month, day.day, config.dayEndHour);
    final items = <PlanItem>[];
    final warnings = <PlanWarning>[];

    // 1. Place calendar events
    final dayEvents = events.where((e) {
      final eDate = _dateOnly(e.date);
      return eDate.year == day.year &&
          eDate.month == day.month &&
          eDate.day == day.day;
    }).toList();
    dayEvents.sort((a, b) => a.date.compareTo(b.date));

    for (final event in dayEvents) {
      final eventStart = event.date.isBefore(dayStart) ? dayStart : event.date;
      final eventEnd = event.endDate != null
          ? (event.endDate!.isAfter(dayEnd) ? dayEnd : event.endDate!)
          : eventStart.add(const Duration(minutes: 30));

      if (eventStart.isBefore(dayEnd) && eventEnd.isAfter(dayStart)) {
        items.add(PlanItem(
          type: PlanItemType.event,
          title: event.title,
          start: eventStart,
          end: eventEnd,
          refId: event.id,
          category: event.tags.isNotEmpty ? event.tags.first.name : null,
          priority: _eventPriority(event),
        ));
      }
    }

    // 2. Place habit reminders (15 min each, at day start or in gaps)
    final dayHabits = habits
        .where((h) => h.isActive && h.isScheduledFor(day.weekday))
        .toList();
    final completedToday = habitCompletions
        .where((c) =>
            _dateOnly(c.date).isAtSameMomentAs(day) && c.count > 0)
        .map((c) => c.habitId)
        .toSet();

    for (final habit in dayHabits) {
      // Skip already completed habits (for today)
      if (_dateOnly(_now).isAtSameMomentAs(day) &&
          completedToday.contains(habit.id)) {
        continue;
      }
      items.add(PlanItem(
        type: PlanItemType.habit,
        title: '${habit.emoji ?? '✓'} ${habit.name}',
        start: dayStart,
        end: dayStart.add(const Duration(minutes: 15)),
        refId: habit.id,
        category: 'habit',
        priority: 0.5,
      ));
    }

    // Sort items by start time
    items.sort((a, b) => a.start.compareTo(b.start));

    // 3. Find free slots between items
    final freeSlots = _findFreeSlots(items, dayStart, dayEnd);

    // 4. Allocate goal work blocks into free slots
    final goalItems = _allocateGoalBlocks(
      freeSlots: freeSlots,
      scoredGoals: scoredGoals,
      day: day,
      goalBlockCounts: goalBlockCounts,
    );
    items.addAll(goalItems);

    // 5. Recalculate free slots after goal allocation
    items.sort((a, b) => a.start.compareTo(b.start));
    final remainingFree = _findFreeSlots(items, dayStart, dayEnd);
    for (final slot in remainingFree) {
      if (slot.inMinutes >= config.minBlockMinutes) {
        items.add(PlanItem(
          type: PlanItemType.freeTime,
          title: 'Free time',
          start: slot.start,
          end: slot.end,
        ));
      }
    }

    // Final sort
    items.sort((a, b) => a.start.compareTo(b.start));

    // Compute load score
    final plannedMins = items
        .where((i) => i.type != PlanItemType.freeTime)
        .fold(0, (sum, i) => sum + i.minutes);
    final loadScore = config.dailyMinutes > 0
        ? plannedMins / config.dailyMinutes
        : 0.0;

    // Day warnings
    if (loadScore >= 1.0) {
      warnings.add(PlanWarning(
        severity: WarningSeverity.warning,
        date: day,
        message:
            'Overloaded: ${(plannedMins / 60).toStringAsFixed(1)}h planned '
            'vs ${config.dailyMinutes ~/ 60}h available',
      ));
    }

    if (dayEvents.length >= 6) {
      warnings.add(PlanWarning(
        severity: WarningSeverity.info,
        date: day,
        message:
            'High context switching: ${dayEvents.length} events scheduled',
      ));
    }

    // Check for overlapping events
    for (var i = 0; i < dayEvents.length - 1; i++) {
      final current = dayEvents[i];
      final next = dayEvents[i + 1];
      if (current.endDate != null && current.endDate!.isAfter(next.date)) {
        warnings.add(PlanWarning(
          severity: WarningSeverity.warning,
          date: day,
          message:
              'Overlap: "${current.title}" and "${next.title}"',
          refId: current.id,
        ));
      }
    }

    return DailyPlan(
      date: day,
      items: items,
      loadScore: loadScore,
      warnings: warnings,
    );
  }

  /// Find free time slots between existing items.
  List<_TimeSlot> _findFreeSlots(
    List<PlanItem> items,
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    final nonFree =
        items.where((i) => i.type != PlanItemType.freeTime).toList();
    nonFree.sort((a, b) => a.start.compareTo(b.start));

    final slots = <_TimeSlot>[];
    var cursor = dayStart;

    for (final item in nonFree) {
      final gapStart = cursor;
      final gapEnd = item.start;
      if (gapEnd.isAfter(gapStart)) {
        final gap = gapEnd.difference(gapStart).inMinutes;
        if (gap >= config.minBlockMinutes) {
          slots.add(_TimeSlot(start: gapStart, end: gapEnd));
        }
      }
      if (item.end.isAfter(cursor)) {
        cursor = item.end;
      }
    }

    // Trailing gap
    if (dayEnd.isAfter(cursor)) {
      final gap = dayEnd.difference(cursor).inMinutes;
      if (gap >= config.minBlockMinutes) {
        slots.add(_TimeSlot(start: cursor, end: dayEnd));
      }
    }

    return slots;
  }

  /// Allocate goal work blocks into available free slots.
  List<PlanItem> _allocateGoalBlocks({
    required List<_TimeSlot> freeSlots,
    required List<_ScoredGoal> scoredGoals,
    required DateTime day,
    required Map<String, int> goalBlockCounts,
  }) {
    if (scoredGoals.isEmpty || freeSlots.isEmpty) return [];

    final items = <PlanItem>[];
    final availableSlots = freeSlots.toList();

    for (final sg in scoredGoals) {
      if (availableSlots.isEmpty) break;

      // Limit blocks per goal per week: at most 2 per day
      final existingToday = goalBlockCounts[sg.goal.id] ?? 0;
      if (existingToday >= 2) continue;

      // Find a slot that can fit the goal block
      _TimeSlot? bestSlot;
      var bestIdx = -1;
      for (var i = 0; i < availableSlots.length; i++) {
        final slot = availableSlots[i];
        if (slot.inMinutes >= config.goalBlockMinutes + config.bufferMinutes) {
          bestSlot = slot;
          bestIdx = i;
          break;
        }
      }

      if (bestSlot == null) continue;

      final blockStart =
          bestSlot.start.add(Duration(minutes: config.bufferMinutes));
      final blockEnd =
          blockStart.add(Duration(minutes: config.goalBlockMinutes));

      items.add(PlanItem(
        type: PlanItemType.goalWork,
        title: '🎯 ${sg.goal.title}',
        start: blockStart,
        end: blockEnd.isBefore(bestSlot.end) ? blockEnd : bestSlot.end,
        refId: sg.goal.id,
        category: sg.goal.category.label,
        priority: sg.score,
      ));

      goalBlockCounts[sg.goal.id] =
          (goalBlockCounts[sg.goal.id] ?? 0) + 1;

      // Shrink or remove the used slot
      final remaining =
          bestSlot.end.difference(blockEnd).inMinutes;
      if (remaining >= config.minBlockMinutes) {
        availableSlots[bestIdx] =
            _TimeSlot(start: blockEnd, end: bestSlot.end);
      } else {
        availableSlots.removeAt(bestIdx);
      }
    }

    return items;
  }

  /// Score goals by urgency for prioritization.
  ///
  /// Score formula: `deadlineUrgency * (1 - progress) * categoryWeight`
  /// Goals without deadlines get a base score, sorted after urgent ones.
  List<_ScoredGoal> _scoreGoals(List<Goal> goals, DateTime startDate) {
    final active = goals
        .where((g) => !g.isCompleted && !g.isArchived)
        .toList();
    if (active.isEmpty) return [];

    final scored = <_ScoredGoal>[];
    for (final goal in active) {
      var score = 0.0;
      final remaining = 1.0 - goal.effectiveProgress;

      if (goal.deadline != null) {
        final daysUntil =
            goal.deadline!.difference(startDate).inDays.toDouble();
        if (daysUntil <= 0) {
          score = 100.0 * remaining; // Overdue: highest urgency
        } else if (daysUntil <= 7) {
          score = (50.0 + (7 - daysUntil) * 7) * remaining;
        } else if (daysUntil <= 30) {
          score = (20.0 + (30 - daysUntil) * 1.0) * remaining;
        } else {
          score = 10.0 * remaining;
        }
      } else {
        // No deadline: base score scaled by remaining progress
        score = 5.0 * remaining;
      }

      // Boost goals with incomplete milestones
      if (goal.milestones.isNotEmpty) {
        final incompleteMilestones =
            goal.milestones.where((m) => !m.isCompleted).length;
        score += incompleteMilestones * 2.0;
      }

      scored.add(_ScoredGoal(goal: goal, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  /// Expand recurring events into individual occurrences within the period.
  ///
  /// Uses [EventModel.generateOccurrencesInRange] to produce only the
  /// occurrences that fall within [start, end). For a 7-day planning
  /// window, a weekly recurring event now creates ~1 EventModel copy
  /// instead of up to 52 (the previous `generateOccurrences()` default).
  List<EventModel> _expandEvents(
    List<EventModel> events,
    DateTime start,
    DateTime end,
  ) {
    final expanded = <EventModel>[];
    for (final e in events) {
      final eDate = _dateOnly(e.date);
      if (!eDate.isBefore(start) && eDate.isBefore(end)) {
        expanded.add(e);
      }
      if (e.isRecurring) {
        expanded.addAll(e.generateOccurrencesInRange(start, end));
      }
    }
    return expanded;
  }

  /// Priority score for an event (used for display ordering).
  double _eventPriority(EventModel event) {
    switch (event.priority) {
      case EventPriority.urgent:
        return 4.0;
      case EventPriority.high:
        return 3.0;
      case EventPriority.medium:
        return 2.0;
      case EventPriority.low:
        return 1.0;
    }
  }

  /// Generate week-level warnings.
  void _addWeekWarnings(
    List<PlanWarning> warnings,
    List<DailyPlan> days,
    List<Goal> goals,
    List<_ScoredGoal> scoredGoals,
    Map<String, int> goalBlockCounts,
  ) {
    // Warn about goals that didn't get any blocks
    final activeGoals = goals
        .where((g) => !g.isCompleted && !g.isArchived)
        .toList();
    for (final goal in activeGoals) {
      if (!goalBlockCounts.containsKey(goal.id) ||
          goalBlockCounts[goal.id] == 0) {
        final severity = goal.isOverdue
            ? WarningSeverity.critical
            : WarningSeverity.warning;
        warnings.add(PlanWarning(
          severity: severity,
          message:
              'No time allocated for goal "${goal.title}"'
              '${goal.isOverdue ? ' (OVERDUE)' : ''}',
          refId: goal.id,
        ));
      }
    }

    // Warn if too many days are overloaded
    final overloaded = days.where((d) => d.loadScore >= 1.0).length;
    if (overloaded >= 3) {
      warnings.add(PlanWarning(
        severity: WarningSeverity.critical,
        message:
            '$overloaded out of ${days.length} days are overloaded. '
            'Consider rescheduling or delegating.',
      ));
    }

    // Warn about goals with imminent deadlines
    for (final sg in scoredGoals) {
      final goal = sg.goal;
      if (goal.deadline != null) {
        final daysUntil = goal.deadline!
            .difference(_dateOnly(_now))
            .inDays;
        if (daysUntil <= 3 && goal.effectiveProgress < 0.8) {
          warnings.add(PlanWarning(
            severity: WarningSeverity.critical,
            message:
                'Goal "${goal.title}" is due in $daysUntil day${daysUntil != 1 ? 's' : ''} '
                'but only ${(goal.effectiveProgress * 100).toStringAsFixed(0)}% complete',
            refId: goal.id,
          ));
        }
      }
    }
  }
}

// ─── Private Helpers ────────────────────────────────────────────

class _TimeSlot {
  final DateTime start;
  final DateTime end;

  const _TimeSlot({required this.start, required this.end});

  int get inMinutes => end.difference(start).inMinutes;
}

class _ScoredGoal {
  final Goal goal;
  final double score;

  const _ScoredGoal({required this.goal, required this.score});
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
