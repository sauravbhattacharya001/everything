/// Focus Session Advisor Service - agentic deep-work session planner.
///
/// While calendar and task services track *what* to do, this service answers
/// the agentic question:
///
///   "Given my energy curve, task complexity, and available time blocks,
///    when and how long should my next focus session be, and what technique
///    should I use?"
///
/// Inputs are platform-agnostic [FocusTask], [EnergyReading], and [TimeBlock]
/// records. No Flutter or persistence dependency — same service powers widgets,
/// notifications, and unit tests.
///
/// Pipeline:
///   1. Profile user energy curve from recent [EnergyReading] entries.
///   2. Match tasks to optimal energy windows by complexity.
///   3. Fit sessions into available [TimeBlock] gaps.
///   4. Recommend technique (pomodoro/deep-work/time-boxing/flow-state) and
///      duration based on task type + energy match.
///   5. Per-session verdict: OPTIMAL_WINDOW / GOOD_FIT / SUBOPTIMAL /
///      ENERGY_MISMATCH / TOO_SHORT / OVERCOMMITTED / INSUFFICIENT_DATA.
///   6. Portfolio-level day plan with P0-P3 playbook, A-F grade, and
///      autonomous insights.
///
/// Sibling to [EnergyBudgetPlannerService] (energy allocation) and
/// [TaskBatchingAdvisorService] (task grouping) but focused on the session-level
/// scheduling that those services cannot model.
library;

import 'dart:math' as math;

// ─── Data Models ──────────────────────────────────────────────────────────────

/// A task requiring focused attention.
class FocusTask {
  final String id;
  final String title;

  /// 1-10 complexity rating.
  final int complexity;

  /// Estimated minutes to complete.
  final int estimatedMinutes;

  /// Category for batching hints.
  final String category;

  /// Priority 1 (highest) to 5 (lowest).
  final int priority;

  /// Whether the task has a hard deadline today.
  final bool deadlineToday;

  const FocusTask({
    required this.id,
    required this.title,
    this.complexity = 5,
    this.estimatedMinutes = 45,
    this.category = 'general',
    this.priority = 3,
    this.deadlineToday = false,
  });
}

/// A point-in-time energy self-report.
class EnergyReading {
  final DateTime timestamp;

  /// 1-10 energy level.
  final int level;

  /// Optional context (e.g. 'after_lunch', 'morning', 'evening').
  final String? context;

  const EnergyReading({
    required this.timestamp,
    required this.level,
    this.context,
  });

  int get hour => timestamp.hour;
}

/// An available time block for scheduling.
class TimeBlock {
  final DateTime start;
  final DateTime end;

  /// Whether this block has hard boundaries (meeting before/after).
  final bool hardBoundary;

  const TimeBlock({
    required this.start,
    required this.end,
    this.hardBoundary = false,
  });

  int get durationMinutes => end.difference(start).inMinutes;
}

/// Risk appetite for focus session planning.
enum FocusRiskAppetite { cautious, balanced, aggressive }

/// Recommended focus technique.
enum FocusTechnique {
  pomodoro, // 25 min on / 5 min off
  deepWork, // 90 min uninterrupted
  timeBoxing, // fixed duration per task
  flowState, // open-ended, energy-driven
}

/// Per-session recommendation.
class SessionRecommendation {
  final String taskId;
  final String taskTitle;
  final TimeBlock? block;
  final int recommendedMinutes;
  final FocusTechnique technique;
  final int breakMinutes;
  final String verdict;
  final int priority; // 0-3
  final double fitScore; // 0-100
  final List<String> reasons;

  const SessionRecommendation({
    required this.taskId,
    required this.taskTitle,
    this.block,
    required this.recommendedMinutes,
    required this.technique,
    required this.breakMinutes,
    required this.verdict,
    required this.priority,
    required this.fitScore,
    required this.reasons,
  });
}

/// A playbook action.
class FocusAction {
  final String id;
  final int priority;
  final String label;
  final String reason;
  final String owner;
  final int blastRadius;
  final String reversibility;

  const FocusAction({
    required this.id,
    required this.priority,
    required this.label,
    required this.reason,
    required this.owner,
    required this.blastRadius,
    required this.reversibility,
  });
}

/// Full focus session plan.
class FocusSessionPlan {
  final String grade;
  final double planScore; // 0-100
  final List<SessionRecommendation> sessions;
  final List<FocusAction> playbook;
  final List<String> insights;
  final int totalFocusMinutes;
  final int totalBreakMinutes;
  final String headline;
  final DateTime generatedAt;

  const FocusSessionPlan({
    required this.grade,
    required this.planScore,
    required this.sessions,
    required this.playbook,
    required this.insights,
    required this.totalFocusMinutes,
    required this.totalBreakMinutes,
    required this.headline,
    required this.generatedAt,
  });
}

// ─── Service ──────────────────────────────────────────────────────────────────

class FocusSessionAdvisorService {
  final DateTime Function() _now;
  final FocusRiskAppetite _appetite;
  final double _targetFocusHours;

  FocusSessionAdvisorService({
    DateTime Function()? now,
    FocusRiskAppetite appetite = FocusRiskAppetite.balanced,
    double targetFocusHours = 4.0,
  })  : _now = now ?? DateTime.now,
        _appetite = appetite,
        _targetFocusHours = targetFocusHours;

  /// Analyze tasks, energy, and available blocks to produce a focus session plan.
  FocusSessionPlan analyze({
    required List<FocusTask> tasks,
    List<EnergyReading> energyHistory = const [],
    List<TimeBlock> availableBlocks = const [],
  }) {
    final now = _now();

    if (tasks.isEmpty) {
      return FocusSessionPlan(
        grade: 'A',
        planScore: 100,
        sessions: const [],
        playbook: const [
          FocusAction(
            id: 'NO_TASKS',
            priority: 3,
            label: 'No tasks to schedule',
            reason: 'Task queue is empty',
            owner: 'user',
            blastRadius: 1,
            reversibility: 'high',
          ),
        ],
        insights: const ['EMPTY_TASK_QUEUE'],
        totalFocusMinutes: 0,
        totalBreakMinutes: 0,
        headline: 'VERDICT: grade=A tasks=0 — no focus sessions needed',
        generatedAt: now,
      );
    }

    // Build energy profile by hour (0-23).
    final energyByHour = _buildEnergyProfile(energyHistory);

    // Sort tasks by scheduling priority.
    final sortedTasks = List<FocusTask>.from(tasks)
      ..sort((a, b) {
        // Deadline today first
        if (a.deadlineToday != b.deadlineToday) {
          return a.deadlineToday ? -1 : 1;
        }
        // Then by priority (lower = more important)
        if (a.priority != b.priority) return a.priority.compareTo(b.priority);
        // Then by complexity desc (harder tasks first for peak energy)
        return b.complexity.compareTo(a.complexity);
      });

    // Sort blocks by start time.
    final sortedBlocks = List<TimeBlock>.from(availableBlocks)
      ..sort((a, b) => a.start.compareTo(b.start));

    // Assign sessions.
    final sessions = <SessionRecommendation>[];
    final usedBlockMinutes = <int, int>{}; // block index -> minutes used

    for (final task in sortedTasks) {
      final result = _assignSession(
        task: task,
        blocks: sortedBlocks,
        usedBlockMinutes: usedBlockMinutes,
        energyByHour: energyByHour,
        now: now,
      );
      sessions.add(result);
    }

    // Compute scores.
    final totalFocus = sessions.fold<int>(0, (s, r) => s + r.recommendedMinutes);
    final totalBreak = sessions.fold<int>(0, (s, r) => s + r.breakMinutes);
    final avgFit = sessions.isEmpty
        ? 100.0
        : sessions.fold<double>(0, (s, r) => s + r.fitScore) / sessions.length;

    final planScore = _computePlanScore(sessions, totalFocus, avgFit);
    final grade = _gradeFromScore(planScore);
    final playbook = _buildPlaybook(sessions, grade, totalFocus);
    final insights = _buildInsights(sessions, totalFocus, energyHistory);

    final p0 = sessions.where((s) => s.priority == 0).length;
    final p1 = sessions.where((s) => s.priority == 1).length;

    return FocusSessionPlan(
      grade: grade,
      planScore: planScore,
      sessions: sessions,
      playbook: playbook,
      insights: insights,
      totalFocusMinutes: totalFocus,
      totalBreakMinutes: totalBreak,
      headline:
          'VERDICT: grade=$grade tasks=${tasks.length} P0=$p0 P1=$p1 focus=${totalFocus}min score=${planScore.toStringAsFixed(1)}',
      generatedAt: now,
    );
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  Map<int, double> _buildEnergyProfile(List<EnergyReading> history) {
    if (history.isEmpty) return {};
    final byHour = <int, List<int>>{};
    for (final r in history) {
      byHour.putIfAbsent(r.hour, () => []).add(r.level);
    }
    return byHour.map((h, levels) =>
        MapEntry(h, levels.reduce((a, b) => a + b) / levels.length));
  }

  double _energyAtHour(Map<int, double> profile, int hour) {
    if (profile.isEmpty) return 5.0; // neutral default
    if (profile.containsKey(hour)) return profile[hour]!;
    // Interpolate from nearest known hours.
    final known = profile.keys.toList()..sort();
    if (known.length == 1) return profile[known.first]!;
    // Find bracketing hours.
    int? lower, upper;
    for (final k in known) {
      if (k <= hour) lower = k;
      if (k >= hour && upper == null) upper = k;
    }
    if (lower == null) return profile[upper ?? known.first]!;
    if (upper == null) return profile[lower]!;
    if (lower == upper) return profile[lower]!;
    final frac = (hour - lower) / (upper - lower);
    return profile[lower]! + frac * (profile[upper]! - profile[lower]!);
  }

  SessionRecommendation _assignSession({
    required FocusTask task,
    required List<TimeBlock> blocks,
    required Map<int, int> usedBlockMinutes,
    required Map<int, double> energyByHour,
    required DateTime now,
  }) {
    final idealMinutes = _idealSessionMinutes(task);
    final technique = _selectTechnique(task, idealMinutes);
    final breakMin = _breakForTechnique(technique, idealMinutes);

    // Find best block.
    TimeBlock? bestBlock;
    double bestFit = -1;
    int bestIdx = -1;

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final used = usedBlockMinutes[i] ?? 0;
      final remaining = block.durationMinutes - used;
      if (remaining < 15) continue; // too short for any session

      final midHour = block.start.add(Duration(minutes: used + idealMinutes ~/ 2)).hour;
      final energy = _energyAtHour(energyByHour, midHour);
      final energyFit = _energyFitScore(energy, task.complexity);
      final sizeFit = remaining >= idealMinutes + breakMin ? 1.0 : remaining / (idealMinutes + breakMin);
      final fit = energyFit * 0.6 + sizeFit * 40;

      if (fit > bestFit) {
        bestFit = fit;
        bestBlock = block;
        bestIdx = i;
      }
    }

    // Determine verdict.
    String verdict;
    int priority;
    double fitScore;
    final reasons = <String>[];

    if (bestBlock == null) {
      // No block available.
      if (blocks.isEmpty) {
        verdict = 'INSUFFICIENT_DATA';
        priority = 3;
        fitScore = 0;
        reasons.add('NO_TIME_BLOCKS_PROVIDED');
      } else {
        verdict = 'OVERCOMMITTED';
        priority = 0;
        fitScore = 10;
        reasons.add('NO_REMAINING_CAPACITY');
        if (task.deadlineToday) reasons.add('DEADLINE_TODAY');
      }
    } else {
      final used = usedBlockMinutes[bestIdx] ?? 0;
      final remaining = bestBlock.durationMinutes - used;
      final midHour = bestBlock.start.add(Duration(minutes: used + idealMinutes ~/ 2)).hour;
      final energy = _energyAtHour(energyByHour, midHour);

      // Claim the block.
      usedBlockMinutes[bestIdx] = used + math.min(idealMinutes + breakMin, remaining);

      fitScore = _computeFitScore(energy, task.complexity, remaining, idealMinutes + breakMin);
      fitScore = (fitScore * _appetiteMult).clamp(0, 100);

      if (fitScore >= 75) {
        verdict = 'OPTIMAL_WINDOW';
        priority = 3;
        reasons.add('HIGH_ENERGY_MATCH');
        if (task.deadlineToday) reasons.add('DEADLINE_TODAY');
      } else if (fitScore >= 55) {
        verdict = 'GOOD_FIT';
        priority = 2;
        if (energy >= 6) reasons.add('ADEQUATE_ENERGY');
        if (remaining >= idealMinutes) reasons.add('SUFFICIENT_TIME');
      } else if (remaining < idealMinutes) {
        verdict = 'TOO_SHORT';
        priority = 1;
        reasons.add('BLOCK_SHORTER_THAN_IDEAL');
        if (task.deadlineToday) reasons.add('DEADLINE_TODAY');
      } else if (energy < 4 && task.complexity >= 7) {
        verdict = 'ENERGY_MISMATCH';
        priority = 1;
        reasons.add('LOW_ENERGY_HIGH_COMPLEXITY');
      } else {
        verdict = 'SUBOPTIMAL';
        priority = 2;
        if (energy < 5) reasons.add('LOW_ENERGY');
        if (remaining < idealMinutes + breakMin) reasons.add('TIGHT_WINDOW');
      }
    }

    return SessionRecommendation(
      taskId: task.id,
      taskTitle: task.title,
      block: bestBlock,
      recommendedMinutes: idealMinutes,
      technique: technique,
      breakMinutes: breakMin,
      verdict: verdict,
      priority: priority,
      fitScore: fitScore,
      reasons: reasons,
    );
  }

  int _idealSessionMinutes(FocusTask task) {
    if (task.estimatedMinutes <= 25) return 25;
    if (task.complexity >= 8) return math.min(task.estimatedMinutes, 90);
    if (task.complexity >= 5) return math.min(task.estimatedMinutes, 60);
    return math.min(task.estimatedMinutes, 45);
  }

  FocusTechnique _selectTechnique(FocusTask task, int minutes) {
    if (minutes <= 25) return FocusTechnique.pomodoro;
    if (task.complexity >= 8 && minutes >= 60) return FocusTechnique.deepWork;
    if (task.complexity >= 6) return FocusTechnique.flowState;
    return FocusTechnique.timeBoxing;
  }

  int _breakForTechnique(FocusTechnique technique, int sessionMinutes) {
    switch (technique) {
      case FocusTechnique.pomodoro:
        return 5;
      case FocusTechnique.deepWork:
        return 15;
      case FocusTechnique.flowState:
        return 10;
      case FocusTechnique.timeBoxing:
        return sessionMinutes >= 45 ? 10 : 5;
    }
  }

  double _energyFitScore(double energy, int complexity) {
    // High-complexity tasks need high energy; low-complexity are flexible.
    final needed = complexity >= 8
        ? 7.0
        : complexity >= 5
            ? 5.0
            : 3.0;
    final surplus = energy - needed;
    // Score 0-60 for energy match.
    return (30 + surplus * 10).clamp(0, 60).toDouble();
  }

  double _computeFitScore(
      double energy, int complexity, int blockMinutes, int neededMinutes) {
    final energyComponent = _energyFitScore(energy, complexity);
    final timeComponent = blockMinutes >= neededMinutes
        ? 40.0
        : (blockMinutes / neededMinutes * 40).clamp(0, 40).toDouble();
    return energyComponent + timeComponent;
  }

  double get _appetiteMult {
    switch (_appetite) {
      case FocusRiskAppetite.cautious:
        return 0.90; // stricter - requires better conditions
      case FocusRiskAppetite.balanced:
        return 1.0;
      case FocusRiskAppetite.aggressive:
        return 1.10; // more optimistic
    }
  }

  double _computePlanScore(
      List<SessionRecommendation> sessions, int totalFocus, double avgFit) {
    if (sessions.isEmpty) return 100;
    final targetMinutes = (_targetFocusHours * 60).round();
    final coveragePenalty = totalFocus >= targetMinutes
        ? 0.0
        : (1 - totalFocus / targetMinutes) * 30;
    final p0Count = sessions.where((s) => s.priority == 0).length;
    final p0Penalty = p0Count * 15.0;
    return (avgFit - coveragePenalty - p0Penalty).clamp(0, 100);
  }

  String _gradeFromScore(double score) {
    if (score >= 80) return 'A';
    if (score >= 65) return 'B';
    if (score >= 50) return 'C';
    if (score >= 35) return 'D';
    return 'F';
  }

  List<FocusAction> _buildPlaybook(
      List<SessionRecommendation> sessions, String grade, int totalFocus) {
    final actions = <FocusAction>[];
    final targetMin = (_targetFocusHours * 60).round();

    final overcommitted = sessions.where((s) => s.verdict == 'OVERCOMMITTED');
    final energyMismatch = sessions.where((s) => s.verdict == 'ENERGY_MISMATCH');
    final tooShort = sessions.where((s) => s.verdict == 'TOO_SHORT');

    if (overcommitted.isNotEmpty) {
      actions.add(const FocusAction(
        id: 'REDUCE_TASK_LOAD',
        priority: 0,
        label: 'Reduce task load or extend available time',
        reason: 'More tasks than available time blocks',
        owner: 'user',
        blastRadius: 4,
        reversibility: 'high',
      ));
    }

    if (energyMismatch.isNotEmpty) {
      actions.add(const FocusAction(
        id: 'RESCHEDULE_COMPLEX_TO_PEAK',
        priority: 1,
        label: 'Move complex tasks to peak energy windows',
        reason: 'High-complexity tasks scheduled during low energy',
        owner: 'user',
        blastRadius: 2,
        reversibility: 'high',
      ));
    }

    if (tooShort.isNotEmpty) {
      actions.add(const FocusAction(
        id: 'CONSOLIDATE_TIME_BLOCKS',
        priority: 1,
        label: 'Consolidate fragmented time blocks',
        reason: 'Available blocks are too short for deep work',
        owner: 'user',
        blastRadius: 3,
        reversibility: 'high',
      ));
    }

    if (totalFocus < targetMin && sessions.isNotEmpty) {
      actions.add(const FocusAction(
        id: 'EXTEND_FOCUS_BUDGET',
        priority: 2,
        label: 'Find more time for focused work today',
        reason: 'Total focus time below daily target',
        owner: 'user',
        blastRadius: 2,
        reversibility: 'high',
      ));
    }

    if (_appetite == FocusRiskAppetite.cautious &&
        (grade == 'C' || grade == 'D' || grade == 'F')) {
      actions.add(const FocusAction(
        id: 'SCHEDULE_FOCUS_AUDIT',
        priority: 2,
        label: 'Review focus habits this week',
        reason: 'Plan quality below standard under cautious analysis',
        owner: 'user',
        blastRadius: 1,
        reversibility: 'high',
      ));
    }

    if (actions.isEmpty) {
      actions.add(const FocusAction(
        id: 'MAINTAIN_FOCUS_ROUTINE',
        priority: 3,
        label: 'Continue current focus routine',
        reason: 'Plan is well-fitted to energy and time',
        owner: 'user',
        blastRadius: 1,
        reversibility: 'high',
      ));
    }

    // Trim P3 fallback when P0/P1 present (aggressive mode).
    if (_appetite == FocusRiskAppetite.aggressive) {
      final hasUrgent = actions.any((a) => a.priority <= 1);
      if (hasUrgent) {
        actions.removeWhere((a) => a.priority == 3);
      }
    }

    actions.sort((a, b) => a.priority.compareTo(b.priority));
    return actions;
  }

  List<String> _buildInsights(
      List<SessionRecommendation> sessions, int totalFocus, List<EnergyReading> history) {
    final insights = <String>[];

    if (sessions.isEmpty) {
      insights.add('EMPTY_TASK_QUEUE');
      return insights;
    }

    final targetMin = (_targetFocusHours * 60).round();

    if (totalFocus >= targetMin * 1.5) {
      insights.add('HEAVY_FOCUS_DAY');
    } else if (totalFocus < targetMin * 0.5 && sessions.length >= 2) {
      insights.add('FRAGMENTED_SCHEDULE');
    }

    final overcommitted = sessions.where((s) => s.verdict == 'OVERCOMMITTED').length;
    if (overcommitted >= 2) insights.add('CAPACITY_OVERLOAD');

    final deepWork = sessions.where((s) => s.technique == FocusTechnique.deepWork).length;
    if (deepWork >= 2) insights.add('DEEP_WORK_HEAVY');

    final optimal = sessions.where((s) => s.verdict == 'OPTIMAL_WINDOW').length;
    if (optimal >= sessions.length * 0.7 && sessions.length >= 3) {
      insights.add('EXCELLENT_ENERGY_ALIGNMENT');
    }

    if (history.isEmpty) insights.add('NO_ENERGY_DATA');

    final deadlineToday = sessions.where((s) =>
        s.reasons.contains('DEADLINE_TODAY')).length;
    if (deadlineToday >= 3) insights.add('DEADLINE_PRESSURE');

    if (insights.isEmpty) insights.add('BALANCED_FOCUS_DAY');

    return insights;
  }

  /// Render plan as text.
  String formatText(FocusSessionPlan plan) {
    final buf = StringBuffer();
    buf.writeln(plan.headline);
    buf.writeln('');
    buf.writeln('Focus: ${plan.totalFocusMinutes}min | Break: ${plan.totalBreakMinutes}min');
    buf.writeln('');
    for (final s in plan.sessions) {
      buf.writeln(
          '  [P${s.priority}] ${s.taskTitle} — ${s.verdict} (${s.recommendedMinutes}min ${s.technique.name})');
    }
    buf.writeln('');
    buf.writeln('Playbook:');
    for (final a in plan.playbook) {
      buf.writeln('  [P${a.priority}] ${a.label}');
    }
    buf.writeln('');
    buf.writeln('Insights: ${plan.insights.join(', ')}');
    return buf.toString();
  }

  /// Render plan as markdown.
  String formatMarkdown(FocusSessionPlan plan) {
    final buf = StringBuffer();
    buf.writeln('## Focus Session Plan');
    buf.writeln('');
    buf.writeln('| Metric | Value |');
    buf.writeln('|--------|-------|');
    buf.writeln('| Grade | ${plan.grade} |');
    buf.writeln('| Score | ${plan.planScore.toStringAsFixed(1)} |');
    buf.writeln('| Tasks | ${plan.sessions.length} |');
    buf.writeln('| Focus | ${plan.totalFocusMinutes}min |');
    buf.writeln('| Break | ${plan.totalBreakMinutes}min |');
    buf.writeln('');
    buf.writeln('## Sessions');
    buf.writeln('');
    buf.writeln('| Task | Verdict | P | Minutes | Technique | Fit |');
    buf.writeln('|------|---------|---|---------|-----------|-----|');
    for (final s in plan.sessions) {
      buf.writeln(
          '| ${s.taskTitle} | ${s.verdict} | ${s.priority} | ${s.recommendedMinutes} | ${s.technique.name} | ${s.fitScore.toStringAsFixed(0)} |');
    }
    buf.writeln('');
    buf.writeln('## Playbook');
    buf.writeln('');
    for (final a in plan.playbook) {
      buf.writeln('- **[P${a.priority}]** ${a.label} — ${a.reason}');
    }
    buf.writeln('');
    buf.writeln('## Insights');
    buf.writeln('');
    for (final i in plan.insights) {
      buf.writeln('- $i');
    }
    return buf.toString();
  }

  /// Render plan as JSON map.
  Map<String, dynamic> formatJson(FocusSessionPlan plan) {
    return {
      'generated_at': plan.generatedAt.toIso8601String(),
      'grade': plan.grade,
      'headline': plan.headline,
      'insights': plan.insights,
      'plan_score': plan.planScore,
      'playbook': plan.playbook
          .map((a) => {
                return {
                  'blast_radius': a.blastRadius,
                  'id': a.id,
                  'label': a.label,
                  'owner': a.owner,
                  'priority': a.priority,
                  'reason': a.reason,
                  'reversibility': a.reversibility,
                };
              })
          .toList(),
      'sessions': plan.sessions
          .map((s) => {
                return {
                  'break_minutes': s.breakMinutes,
                  'fit_score': s.fitScore,
                  'priority': s.priority,
                  'reasons': s.reasons,
                  'recommended_minutes': s.recommendedMinutes,
                  'task_id': s.taskId,
                  'task_title': s.taskTitle,
                  'technique': s.technique.name,
                  'verdict': s.verdict,
                };
              })
          .toList(),
      'total_break_minutes': plan.totalBreakMinutes,
      'total_focus_minutes': plan.totalFocusMinutes,
    };
  }
}
