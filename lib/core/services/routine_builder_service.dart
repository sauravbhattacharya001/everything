/// Daily Routine Builder — service logic for ordered step sequences.
///
/// Model types (TimeSlot, RoutineStep, Routine, StepStatus, StepCompletion,
/// RoutineRun, RoutineAnalytics) live in models/routine.dart and are
/// re-exported here for backward compatibility.

import 'dart:convert';

import '../../models/routine.dart';
import '../utils/date_utils.dart';

// Re-export models so existing imports of this file continue to work.
export '../../models/routine.dart';

/// The main routine builder service.
class RoutineBuilderService {
  final List<Routine> _routines;
  final List<RoutineRun> _runs;

  RoutineBuilderService({
    List<Routine>? routines,
    List<RoutineRun>? runs,
  })  : _routines = routines ?? [],
        _runs = runs ?? [];

  /// All registered routines.
  List<Routine> get routines => List.unmodifiable(_routines);

  /// All recorded runs.
  List<RoutineRun> get runs => List.unmodifiable(_runs);

  // ΓöÇΓöÇ Routine CRUD ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  /// Add a new routine.
  void addRoutine(Routine routine) {
    if (_routines.any((r) => r.id == routine.id)) {
      throw ArgumentError('Routine with id "${routine.id}" already exists.');
    }
    if (routine.steps.isEmpty) {
      throw ArgumentError('Routine must have at least one step.');
    }
    _routines.add(routine);
  }

  /// Update an existing routine by id.
  void updateRoutine(Routine updated) {
    final idx = _routines.indexWhere((r) => r.id == updated.id);
    if (idx < 0) {
      throw ArgumentError('Routine "${updated.id}" not found.');
    }
    _routines[idx] = updated;
  }

  /// Remove a routine and all its runs.
  void removeRoutine(String routineId) {
    _routines.removeWhere((r) => r.id == routineId);
    _runs.removeWhere((r) => r.routineId == routineId);
  }

  /// Get a routine by id.
  Routine? getRoutine(String routineId) {
    try {
      return _routines.firstWhere((r) => r.id == routineId);
    } catch (_) {
      return null;
    }
  }

  // ΓöÇΓöÇ Scheduling ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  /// Get routines scheduled for a specific date.
  List<Routine> getRoutinesForDate(DateTime date) {
    final weekday = date.weekday; // 1=Mon, 7=Sun
    return _routines
        .where((r) => r.isActive && r.isScheduledFor(weekday))
        .toList()
      ..sort((a, b) => a.timeSlot.index.compareTo(b.timeSlot.index));
  }

  /// Get the total estimated minutes for all routines on a date.
  int getTotalMinutesForDate(DateTime date) {
    return getRoutinesForDate(date)
        .fold(0, (sum, r) => sum + r.totalDurationMinutes);
  }

  // ΓöÇΓöÇ Routine Execution ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  /// Start a routine run for today.
  RoutineRun startRun(String routineId, {DateTime? now}) {
    final routine = getRoutine(routineId);
    if (routine == null) {
      throw ArgumentError('Routine "$routineId" not found.');
    }

    final currentTime = now ?? DateTime.now();
    final dateOnly =
        DateTime(currentTime.year, currentTime.month, currentTime.day);

    // Check if already started today
    final existing = _runs.where(
        (r) => r.routineId == routineId && AppDateUtils.isSameDay(r.date, dateOnly));
    if (existing.isNotEmpty) {
      throw StateError(
          'Routine "$routineId" already started for ${_formatDate(dateOnly)}.');
    }

    final run = RoutineRun(
      routineId: routineId,
      date: dateOnly,
      startedAt: currentTime,
      stepCompletions:
          routine.steps.map((s) => StepCompletion(stepId: s.id)).toList(),
    );
    _runs.add(run);
    return run;
  }

  /// Complete a step in an active run.
  RoutineRun completeStep(
    String routineId,
    DateTime date,
    String stepId, {
    int? actualMinutes,
    String? note,
    DateTime? completedAt,
  }) {
    final runIdx = _findRunIndex(routineId, date);
    final run = _runs[runIdx];

    if (run.isFinished) {
      throw StateError('Run is already finished.');
    }

    final stepIdx =
        run.stepCompletions.indexWhere((s) => s.stepId == stepId);
    if (stepIdx < 0) {
      throw ArgumentError('Step "$stepId" not found in run.');
    }

    if (run.stepCompletions[stepIdx].status != StepStatus.pending) {
      throw StateError('Step "$stepId" is already ${run.stepCompletions[stepIdx].status.name}.');
    }

    final updated = List<StepCompletion>.from(run.stepCompletions);
    updated[stepIdx] = updated[stepIdx].copyWith(
      status: StepStatus.completed,
      completedAt: completedAt ?? DateTime.now(),
      actualMinutes: actualMinutes,
      note: note,
    );

    final allDone = updated.every((s) => s.status != StepStatus.pending);
    final updatedRun = run.copyWith(
      stepCompletions: updated,
      finishedAt: allDone ? (completedAt ?? DateTime.now()) : null,
    );
    _runs[runIdx] = updatedRun;
    return updatedRun;
  }

  /// Skip a step in an active run.
  RoutineRun skipStep(
    String routineId,
    DateTime date,
    String stepId, {
    String? reason,
  }) {
    final runIdx = _findRunIndex(routineId, date);
    final run = _runs[runIdx];

    if (run.isFinished) {
      throw StateError('Run is already finished.');
    }

    final stepIdx =
        run.stepCompletions.indexWhere((s) => s.stepId == stepId);
    if (stepIdx < 0) {
      throw ArgumentError('Step "$stepId" not found in run.');
    }

    if (run.stepCompletions[stepIdx].status != StepStatus.pending) {
      throw StateError('Step "$stepId" is already ${run.stepCompletions[stepIdx].status.name}.');
    }

    final updated = List<StepCompletion>.from(run.stepCompletions);
    updated[stepIdx] = updated[stepIdx].copyWith(
      status: StepStatus.skipped,
      note: reason,
    );

    final allDone = updated.every((s) => s.status != StepStatus.pending);
    final updatedRun = run.copyWith(
      stepCompletions: updated,
      finishedAt: allDone ? DateTime.now() : null,
    );
    _runs[runIdx] = updatedRun;
    return updatedRun;
  }

  /// Get a run for a specific routine and date.
  RoutineRun? getRun(String routineId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    try {
      return _runs.firstWhere(
          (r) => r.routineId == routineId && AppDateUtils.isSameDay(r.date, dateOnly));
    } catch (_) {
      return null;
    }
  }

  /// Get all runs for a date.
  List<RoutineRun> getRunsForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _runs.where((r) => AppDateUtils.isSameDay(r.date, dateOnly)).toList();
  }

  // ΓöÇΓöÇ Analytics ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  /// Get analytics for a routine over a date range.
  RoutineAnalytics getAnalytics(
    String routineId, {
    DateTime? from,
    DateTime? to,
  }) {
    final routine = getRoutine(routineId);
    if (routine == null) {
      throw ArgumentError('Routine "$routineId" not found.');
    }

    var relevantRuns = _runs.where((r) => r.routineId == routineId);
    if (from != null) {
      relevantRuns = relevantRuns.where((r) => !r.date.isBefore(from));
    }
    if (to != null) {
      relevantRuns = relevantRuns.where((r) => !r.date.isAfter(to));
    }
    final runsList = relevantRuns.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (runsList.isEmpty) {
      return RoutineAnalytics(
          routineId: routineId, routineName: routine.name);
    }

    // Single-pass: completion count, duration sum, and step-level
    // analytics are computed together instead of 3 separate iterations
    // over runsList (was O(3n), now O(n)).
    int fullyCompleted = 0;
    int durationSum = 0;
    int durationCount = 0;
    final stepCompletionCounts = <String, int>{};
    final stepTotalCounts = <String, int>{};
    final stepDurationSums = <String, int>{};
    final stepDurationCounts = <String, int>{};
    final stepSkipCounts = <String, int>{};

    for (final run in runsList) {
      if (run.completionRatio >= 1.0) fullyCompleted++;
      final dur = run.actualDurationMinutes;
      if (dur > 0) {
        durationSum += dur;
        durationCount++;
      }
      for (final sc in run.stepCompletions) {
        stepTotalCounts[sc.stepId] = (stepTotalCounts[sc.stepId] ?? 0) + 1;
        if (sc.status == StepStatus.completed) {
          stepCompletionCounts[sc.stepId] =
              (stepCompletionCounts[sc.stepId] ?? 0) + 1;
          if (sc.actualMinutes != null) {
            stepDurationSums[sc.stepId] =
                (stepDurationSums[sc.stepId] ?? 0) + sc.actualMinutes!;
            stepDurationCounts[sc.stepId] =
                (stepDurationCounts[sc.stepId] ?? 0) + 1;
          }
        } else if (sc.status == StepStatus.skipped) {
          stepSkipCounts[sc.stepId] = (stepSkipCounts[sc.stepId] ?? 0) + 1;
        }
      }
    }
    final completionRate = fullyCompleted / runsList.length;
    final avgDuration =
        durationCount == 0 ? 0.0 : durationSum / durationCount;

    final stepCompRates = <String, double>{};
    for (final entry in stepTotalCounts.entries) {
      stepCompRates[entry.key] =
          (stepCompletionCounts[entry.key] ?? 0) / entry.value;
    }

    final stepAvgDurs = <String, double>{};
    for (final entry in stepDurationSums.entries) {
      stepAvgDurs[entry.key] =
          entry.value / stepDurationCounts[entry.key]!;
    }

    // Most skipped step
    String? mostSkipped;
    int maxSkips = 0;
    for (final entry in stepSkipCounts.entries) {
      if (entry.value > maxSkips) {
        maxSkips = entry.value;
        mostSkipped = entry.key;
      }
    }

    // Slowest step (by average actual duration)
    String? slowest;
    double maxAvg = 0;
    for (final entry in stepAvgDurs.entries) {
      if (entry.value > maxAvg) {
        maxAvg = entry.value;
        slowest = entry.key;
      }
    }

    // Streak calculation — extract completed runs once instead of
    // filtering in both _calculateCurrentStreak and _calculateLongestStreak
    // (was 2× O(n) filter + 2× O(n log n) sort, now 1× each).
    final completedRuns = runsList
        .where((r) => r.completionRatio >= 1.0)
        .toList();
    final currentStreak = _calculateCurrentStreakFromCompleted(routine, completedRuns);
    final longestStreak = _calculateLongestStreakFromCompleted(routine, completedRuns);

    return RoutineAnalytics(
      routineId: routineId,
      routineName: routine.name,
      totalRuns: runsList.length,
      fullyCompletedRuns: fullyCompleted,
      completionRate: completionRate,
      averageDurationMinutes: avgDuration,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      stepCompletionRates: stepCompRates,
      stepAvgDurations: stepAvgDurs,
      mostSkippedStep: mostSkipped,
      slowestStep: slowest,
    );
  }

  /// Summary of all routines: today's schedule, overall completion trends.
  Map<String, dynamic> getDailySummary(DateTime date) {
    final scheduled = getRoutinesForDate(date);
    final todayRuns = getRunsForDate(date);
    final totalMinutes = getTotalMinutesForDate(date);

    // Index runs by routineId for O(1) lookup per routine instead of
    // O(n) linear scan (was O(scheduled × todayRuns), now O(scheduled + todayRuns)).
    final runsByRoutineId = <String, RoutineRun>{};
    for (final run in todayRuns) {
      runsByRoutineId[run.routineId] = run;
    }

    final routineSummaries = scheduled.map((r) {
      final run = runsByRoutineId[r.id];
      final hasRun = run != null;
      return {
        'routineId': r.id,
        'name': r.name,
        'emoji': r.emoji,
        'timeSlot': r.timeSlot.label,
        'estimatedMinutes': r.totalDurationMinutes,
        'stepCount': r.steps.length,
        'started': hasRun,
        'completed': hasRun && run.isFinished,
        'completionRatio': hasRun ? run.completionRatio : 0.0,
      };
    }).toList();

    final completedCount =
        routineSummaries.where((r) => r['completed'] == true).length;
    final startedCount =
        routineSummaries.where((r) => r['started'] == true).length;

    return {
      'date': _formatDate(date),
      'totalRoutines': scheduled.length,
      'startedCount': startedCount,
      'completedCount': completedCount,
      'totalEstimatedMinutes': totalMinutes,
      'routines': routineSummaries,
    };
  }

  // ΓöÇΓöÇ Step Reordering ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  /// Reorder steps within a routine. [stepIds] must contain all step ids
  /// in the desired new order.
  Routine reorderSteps(String routineId, List<String> stepIds) {
    final routine = getRoutine(routineId);
    if (routine == null) {
      throw ArgumentError('Routine "$routineId" not found.');
    }

    final existingIds = routine.steps.map((s) => s.id).toSet();
    final newIds = stepIds.toSet();
    if (!existingIds.containsAll(newIds) ||
        !newIds.containsAll(existingIds)) {
      throw ArgumentError(
          'stepIds must contain exactly the same step ids as the routine.');
    }

    final stepMap = {for (final s in routine.steps) s.id: s};
    final reordered = <RoutineStep>[];
    for (var i = 0; i < stepIds.length; i++) {
      reordered.add(stepMap[stepIds[i]]!.copyWith(order: i));
    }

    final updated = routine.copyWith(steps: reordered);
    updateRoutine(updated);
    return updated;
  }

  // ΓöÇΓöÇ Template Routines ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  /// Create a pre-built template routine.
  static Routine createTemplate(String templateName, {DateTime? createdAt}) {
    final created = createdAt ?? DateTime.now();
    switch (templateName.toLowerCase()) {
      case 'morning':
        return Routine(
          id: 'tpl-morning-${created.millisecondsSinceEpoch}',
          name: 'Morning Routine',
          emoji: '\u2600\uFE0F', // ΓÿÇ∩╕Å
          timeSlot: TimeSlot.morning,
          createdAt: created,
          steps: [
            const RoutineStep(id: 'ms1', name: 'Wake Up & Hydrate', emoji: '\uD83D\uDCA7', durationMinutes: 5, order: 0),
            const RoutineStep(id: 'ms2', name: 'Meditate', emoji: '\uD83E\uDDD8', durationMinutes: 10, order: 1),
            const RoutineStep(id: 'ms3', name: 'Exercise', emoji: '\uD83C\uDFCB\uFE0F', durationMinutes: 30, order: 2),
            const RoutineStep(id: 'ms4', name: 'Shower', emoji: '\uD83D\uDEBF', durationMinutes: 15, order: 3),
            const RoutineStep(id: 'ms5', name: 'Healthy Breakfast', emoji: '\uD83E\uDD57', durationMinutes: 20, order: 4),
            const RoutineStep(id: 'ms6', name: 'Journal / Plan Day', emoji: '\uD83D\uDCDD', durationMinutes: 10, isOptional: true, order: 5),
          ],
        );

      case 'evening':
        return Routine(
          id: 'tpl-evening-${created.millisecondsSinceEpoch}',
          name: 'Evening Wind-Down',
          emoji: '\uD83C\uDF19', // ≡ƒîÖ
          timeSlot: TimeSlot.night,
          createdAt: created,
          steps: [
            const RoutineStep(id: 'es1', name: 'Review Today', emoji: '\uD83D\uDCCB', durationMinutes: 10, order: 0),
            const RoutineStep(id: 'es2', name: 'Prepare Tomorrow', emoji: '\uD83D\uDCC5', durationMinutes: 10, order: 1),
            const RoutineStep(id: 'es3', name: 'Read', emoji: '\uD83D\uDCDA', durationMinutes: 30, order: 2),
            const RoutineStep(id: 'es4', name: 'Stretch / Yoga', emoji: '\uD83E\uDDD8', durationMinutes: 15, isOptional: true, order: 3),
            const RoutineStep(id: 'es5', name: 'Screen Off & Sleep', emoji: '\uD83D\uDE34', durationMinutes: 5, order: 4),
          ],
        );

      case 'workout':
        return Routine(
          id: 'tpl-workout-${created.millisecondsSinceEpoch}',
          name: 'Workout Session',
          emoji: '\uD83D\uDCAA', // ≡ƒÆ¬
          timeSlot: TimeSlot.afternoon,
          activeDays: [1, 3, 5], // Mon, Wed, Fri
          createdAt: created,
          steps: [
            const RoutineStep(id: 'ws1', name: 'Warm Up', emoji: '\uD83D\uDD25', durationMinutes: 10, order: 0),
            const RoutineStep(id: 'ws2', name: 'Strength Training', emoji: '\uD83C\uDFCB\uFE0F', durationMinutes: 30, order: 1),
            const RoutineStep(id: 'ws3', name: 'Cardio', emoji: '\uD83C\uDFC3', durationMinutes: 20, order: 2),
            const RoutineStep(id: 'ws4', name: 'Cool Down & Stretch', emoji: '\uD83E\uDDD8', durationMinutes: 10, order: 3),
            const RoutineStep(id: 'ws5', name: 'Protein Shake', emoji: '\uD83E\uDD64', durationMinutes: 5, isOptional: true, order: 4),
          ],
        );

      case 'study':
        return Routine(
          id: 'tpl-study-${created.millisecondsSinceEpoch}',
          name: 'Deep Study Block',
          emoji: '\uD83D\uDCDA', // ≡ƒôÜ
          timeSlot: TimeSlot.midMorning,
          createdAt: created,
          steps: [
            const RoutineStep(id: 'ss1', name: 'Set Goals for Session', emoji: '\uD83C\uDFAF', durationMinutes: 5, order: 0),
            const RoutineStep(id: 'ss2', name: 'Review Previous Notes', emoji: '\uD83D\uDDD2\uFE0F', durationMinutes: 10, order: 1),
            const RoutineStep(id: 'ss3', name: 'Focused Study Block 1', emoji: '\uD83E\uDDE0', durationMinutes: 25, order: 2),
            const RoutineStep(id: 'ss4', name: 'Short Break', emoji: '\u2615', durationMinutes: 5, order: 3),
            const RoutineStep(id: 'ss5', name: 'Focused Study Block 2', emoji: '\uD83E\uDDE0', durationMinutes: 25, order: 4),
            const RoutineStep(id: 'ss6', name: 'Summarize & Review', emoji: '\uD83D\uDCDD', durationMinutes: 10, order: 5),
          ],
        );

      default:
        throw ArgumentError(
            'Unknown template "$templateName". '
            'Available: morning, evening, workout, study.');
    }
  }

  /// List available template names.
  static List<String> get templateNames =>
      const ['morning', 'evening', 'workout', 'study'];

  // ── Import / Export ──────────────────────────────────────

  /// Export all routines and runs as a JSON string.
  String exportToJson() => jsonEncode({
        'routines': _routines.map((r) => r.toJson()).toList(),
        'runs': _runs.map((r) => r.toJson()).toList(),
      });

  /// Import routines and runs from a JSON string, replacing current state.
  void importFromJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final rawRoutines = data['routines'] as List<dynamic>? ?? [];
    final rawRuns = data['runs'] as List<dynamic>? ?? [];

    final parsedRoutines = rawRoutines
        .map((r) => Routine.fromJson(r as Map<String, dynamic>))
        .toList();
    final parsedRuns = rawRuns
        .map((r) => RoutineRun.fromJson(r as Map<String, dynamic>))
        .toList();

    _routines.clear();
    _routines.addAll(parsedRoutines);
    _runs.clear();
    _runs.addAll(parsedRuns);
  }

  // ── Private Helpers ───────────────────────────────────────

  int _findRunIndex(String routineId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final idx = _runs.indexWhere(
        (r) => r.routineId == routineId && AppDateUtils.isSameDay(r.date, dateOnly));
    if (idx < 0) {
      throw ArgumentError(
          'No run found for routine "$routineId" on ${_formatDate(dateOnly)}.');
    }
    return idx;
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Maximum gap in days between two consecutive scheduled occurrences of a
  /// routine. For daily routines (or routines with no specific active days)
  /// this returns 1. For routines scheduled on specific weekdays, it computes
  /// the largest gap between any two adjacent scheduled days (including the
  /// wrap-around from the last day of the week back to the first).
  int _maxScheduledGap(Routine routine) {
    final days = routine.activeDays;
    if (days.isEmpty || days.length >= 7) return 1; // daily
    final sorted = days.toList()..sort();
    int maxGap = 0;
    for (var i = 1; i < sorted.length; i++) {
      final gap = sorted[i] - sorted[i - 1];
      if (gap > maxGap) maxGap = gap;
    }
    // Wrap-around gap (e.g., Fri=5 to Mon=1 → 7 - 5 + 1 = 3)
    final wrapGap = 7 - sorted.last + sorted.first;
    if (wrapGap > maxGap) maxGap = wrapGap;
    return maxGap;
  }

  /// Compute current and longest streaks from pre-filtered completed runs.
  ///
  /// Accepts an already-filtered list of completed runs to avoid redundant
  /// filtering. Sorts chronologically once and computes both streaks in a
  /// single traversal (was 2 separate filter+sort+traverse passes).
  int _calculateCurrentStreakFromCompleted(
      Routine routine, List<RoutineRun> completedRuns) {
    if (completedRuns.isEmpty) return 0;
    // Sort most-recent-first for current streak
    final sorted = List.of(completedRuns)
      ..sort((a, b) => b.date.compareTo(a.date));
    final maxGap = _maxScheduledGap(routine);
    int streak = 1;
    for (var i = 1; i < sorted.length; i++) {
      final diff =
          sorted[i - 1].date.difference(sorted[i].date).inDays;
      if (diff <= maxGap) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int _calculateLongestStreakFromCompleted(
      Routine routine, List<RoutineRun> completedRuns) {
    if (completedRuns.isEmpty) return 0;
    final sorted = List.of(completedRuns)
      ..sort((a, b) => a.date.compareTo(b.date));
    final maxGap = _maxScheduledGap(routine);
    int longest = 1;
    int current = 1;
    for (var i = 1; i < sorted.length; i++) {
      final diff =
          sorted[i].date.difference(sorted[i - 1].date).inDays;
      if (diff <= maxGap) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }
}
