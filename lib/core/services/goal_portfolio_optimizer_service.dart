/// Goal Portfolio Optimizer Service - agentic cross-goal trade-off advisor.
///
/// While [GoalAutopilotService] analyzes risk per individual goal, real users
/// have *limited weekly capacity* and must make trade-offs across many goals.
/// This service answers: "given my N active goals and a budget of H hours per
/// week, which goals should I focus on right now and which should I defer or
/// drop?"
///
/// Approach:
/// 1. For each active goal compute (urgency, value, effort, ROI) where:
///      urgency  = deadline pressure (0..1, higher = closer/overdue)
///      value    = category importance × remaining-progress weight
///      effort   = estimated remaining hours
///      roi      = (urgency × value) / effort
/// 2. Greedy knapsack: sort by ROI desc, pack goals into the weekly budget
///    with each goal taking a `recommendedHours` slice. The first ones in
///    become FOCUS_NOW, then MAINTAIN, then DEFER. Overdue + very-low-ROI
///    goals are flagged DROP_OR_ARCHIVE.
/// 3. Emit a portfolio summary with capacity utilisation, sacrifice warnings
///    (deferred deadlines about to hit), and a P0/P1/P2 action playbook.
///
/// Pure Dart, no Flutter deps — easy to unit test and reuse.
library;

import 'dart:math' as math;

import '../../models/goal.dart';

/// Where a goal sits in the recommended weekly plan.
enum PortfolioVerdict {
  focusNow,
  maintain,
  defer,
  dropOrArchive;

  String get label {
    switch (this) {
      case PortfolioVerdict.focusNow:
        return 'Focus now';
      case PortfolioVerdict.maintain:
        return 'Maintain';
      case PortfolioVerdict.defer:
        return 'Defer';
      case PortfolioVerdict.dropOrArchive:
        return 'Drop / archive';
    }
  }

  String get emoji {
    switch (this) {
      case PortfolioVerdict.focusNow:
        return '🎯';
      case PortfolioVerdict.maintain:
        return '🌿';
      case PortfolioVerdict.defer:
        return '⏸️';
      case PortfolioVerdict.dropOrArchive:
        return '🗑️';
    }
  }
}

/// Priority bucket for the action playbook.
enum PortfolioActionPriority { p0, p1, p2 }

/// Per-goal portfolio recommendation.
class GoalAllocation {
  final Goal goal;
  final PortfolioVerdict verdict;

  /// Hours per week this slate recommends spending on the goal.
  final double recommendedHours;

  /// Estimated remaining hours of effort.
  final double estimatedEffortHours;

  /// 0..1 deadline urgency (1 = overdue or due today).
  final double urgency;

  /// 0..1 strategic value (category × remaining-progress weight).
  final double value;

  /// (urgency × value) / max(effort, epsilon).
  final double roi;

  /// 0..100 composite priority score.
  final double priorityScore;

  /// Human-readable reasons (1-3 items).
  final List<String> reasons;

  const GoalAllocation({
    required this.goal,
    required this.verdict,
    required this.recommendedHours,
    required this.estimatedEffortHours,
    required this.urgency,
    required this.value,
    required this.roi,
    required this.priorityScore,
    required this.reasons,
  });
}

/// One item in the portfolio action playbook.
class PortfolioAction {
  final PortfolioActionPriority priority;
  final String title;
  final String reason;
  final String? goalId;

  const PortfolioAction({
    required this.priority,
    required this.title,
    required this.reason,
    this.goalId,
  });
}

/// Aggregate portfolio result for a fleet of goals under a weekly budget.
class PortfolioPlan {
  final double weeklyBudgetHours;
  final double allocatedHours;
  final double utilisation; // 0..1
  final List<GoalAllocation> focusNow;
  final List<GoalAllocation> maintain;
  final List<GoalAllocation> defer;
  final List<GoalAllocation> dropOrArchive;
  final List<PortfolioAction> playbook;
  final List<String> sacrifices;
  final String healthGrade; // A-F

  const PortfolioPlan({
    required this.weeklyBudgetHours,
    required this.allocatedHours,
    required this.utilisation,
    required this.focusNow,
    required this.maintain,
    required this.defer,
    required this.dropOrArchive,
    required this.playbook,
    required this.sacrifices,
    required this.healthGrade,
  });

  int get totalConsidered =>
      focusNow.length + maintain.length + defer.length + dropOrArchive.length;

  /// Flat list of every allocation in priority order.
  List<GoalAllocation> get all => [
        ...focusNow,
        ...maintain,
        ...defer,
        ...dropOrArchive,
      ];
}

/// Optional tuning knobs.
class PortfolioOptimizerConfig {
  /// Total weekly hours the user is willing to spend across all goals.
  final double weeklyBudgetHours;

  /// Max hours per single goal (cap so one mega-goal doesn't eat the budget).
  final double maxHoursPerGoal;

  /// Minimum hours a goal needs to be considered "in the plan".
  final double minSliceHours;

  /// "cautious" pads recommended hours; "aggressive" trims them.
  final String riskAppetite; // 'cautious' | 'balanced' | 'aggressive'

  const PortfolioOptimizerConfig({
    this.weeklyBudgetHours = 14,
    this.maxHoursPerGoal = 8,
    this.minSliceHours = 0.5,
    this.riskAppetite = 'balanced',
  });
}

/// The optimizer itself. Stateless — call [optimise] with goals + config.
class GoalPortfolioOptimizerService {
  const GoalPortfolioOptimizerService();

  /// Category weights — what the user typically considers "strategically
  /// valuable". These are heuristics, not opinions; users can tune.
  static const Map<GoalCategory, double> _categoryWeight = {
    GoalCategory.health: 1.0,
    GoalCategory.career: 0.95,
    GoalCategory.finance: 0.9,
    GoalCategory.education: 0.85,
    GoalCategory.fitness: 0.85,
    GoalCategory.personal: 0.75,
    GoalCategory.creative: 0.7,
    GoalCategory.social: 0.7,
    GoalCategory.other: 0.6,
  };

  /// Default per-milestone effort assumption when caller hasn't supplied one.
  static const double _defaultHoursPerMilestone = 3.0;

  /// Default total-effort estimate for goals with no milestones (so the
  /// optimizer still has something to chew on).
  static const double _defaultGoalHours = 12.0;

  /// Compute a weekly portfolio plan from [goals] under [config].
  ///
  /// [now] is injectable for deterministic tests.
  /// [effortEstimator] lets callers plug in their own per-goal hours estimate
  /// (e.g. derived from a tracker). If null, a milestone-based heuristic is
  /// used.
  PortfolioPlan optimise(
    List<Goal> goals, {
    PortfolioOptimizerConfig config = const PortfolioOptimizerConfig(),
    DateTime? now,
    double Function(Goal goal)? effortEstimator,
  }) {
    final clock = now ?? DateTime.now();

    final active = goals
        .where((g) => !g.isArchived && !g.isCompleted)
        .toList(growable: false);

    if (active.isEmpty) {
      return PortfolioPlan(
        weeklyBudgetHours: config.weeklyBudgetHours,
        allocatedHours: 0,
        utilisation: 0,
        focusNow: const [],
        maintain: const [],
        defer: const [],
        dropOrArchive: const [],
        playbook: const [
          PortfolioAction(
            priority: PortfolioActionPriority.p2,
            title: 'Add some active goals',
            reason: 'No active goals to optimise across.',
          ),
        ],
        sacrifices: const [],
        healthGrade: 'N/A',
      );
    }

    // Score every goal.
    final scored = active.map((g) {
      final urgency = _urgency(g, clock);
      final value = _value(g);
      final effort =
          (effortEstimator?.call(g) ?? _defaultEffort(g)).clamp(0.25, 200).toDouble();
      final roi = (urgency * value) / effort;
      // 0..100 priority composite (urgency heavier than value heavier than ROI).
      final priority =
          (urgency * 55 + value * 30 + (roi * 50).clamp(0, 15)).clamp(0, 100).toDouble();
      return _ScoredGoal(g, urgency, value, effort, roi, priority);
    }).toList();

    // Highest priority first.
    scored.sort((a, b) => b.priority.compareTo(a.priority));

    // Greedy knapsack across the weekly budget.
    final appetiteMultiplier = switch (config.riskAppetite) {
      'cautious' => 1.25,
      'aggressive' => 0.8,
      _ => 1.0,
    };

    double remaining = config.weeklyBudgetHours;
    final allocations = <GoalAllocation>[];

    for (final s in scored) {
      // Each "slice" is sized as a fraction of remaining effort, padded by
      // urgency so close-deadline goals get bigger slices.
      final urgencyPad = 1 + s.urgency; // 1..2
      final rawSlice =
          (s.effort * 0.25 * urgencyPad * appetiteMultiplier)
              .clamp(config.minSliceHours, config.maxHoursPerGoal)
              .toDouble();

      PortfolioVerdict verdict;
      double slice;
      final reasons = <String>[];

      // Overdue + ultra-low ROI = candidate to drop/archive.
      final overdue = s.goal.isOverdue;
      if (overdue && s.roi < 0.005 && s.goal.effectiveProgress < 0.2) {
        verdict = PortfolioVerdict.dropOrArchive;
        slice = 0;
        reasons.add('Overdue and barely started — consider archiving.');
        reasons.add(
          'ROI (${s.roi.toStringAsFixed(3)}) is the lowest tier.',
        );
      } else if (remaining >= rawSlice) {
        verdict = PortfolioVerdict.focusNow;
        slice = rawSlice;
        remaining -= slice;
        reasons.add(
          'Highest-leverage goal: urgency ${(s.urgency * 100).round()}%, value ${(s.value * 100).round()}%.',
        );
        if (overdue) reasons.add('Already past deadline — act this week.');
      } else if (remaining >= config.minSliceHours) {
        verdict = PortfolioVerdict.maintain;
        slice = remaining;
        remaining = 0;
        reasons.add(
          'Budget partially full — keeping momentum with ${slice.toStringAsFixed(1)}h.',
        );
      } else {
        // Budget exhausted. Decide defer vs drop.
        if (overdue && s.roi < 0.01) {
          verdict = PortfolioVerdict.dropOrArchive;
          slice = 0;
          reasons.add(
            'Overdue and crowded out — archive or rescope before re-adding.',
          );
        } else {
          verdict = PortfolioVerdict.defer;
          slice = 0;
          reasons.add(
            'No remaining budget this week — defer to next planning cycle.',
          );
        }
      }

      // Always surface a "why" tied to the deadline.
      final days = s.goal.daysRemaining;
      if (days != null) {
        if (days < 0) {
          reasons.add('${days.abs()} days overdue.');
        } else if (days <= 7) {
          reasons.add('Deadline in $days day(s).');
        }
      }

      allocations.add(GoalAllocation(
        goal: s.goal,
        verdict: verdict,
        recommendedHours: double.parse(slice.toStringAsFixed(2)),
        estimatedEffortHours: double.parse(s.effort.toStringAsFixed(2)),
        urgency: double.parse(s.urgency.toStringAsFixed(3)),
        value: double.parse(s.value.toStringAsFixed(3)),
        roi: double.parse(s.roi.toStringAsFixed(4)),
        priorityScore: double.parse(s.priority.toStringAsFixed(1)),
        reasons: reasons,
      ));
    }

    // Group.
    List<GoalAllocation> pick(PortfolioVerdict v) =>
        allocations.where((a) => a.verdict == v).toList(growable: false);

    final focusNow = pick(PortfolioVerdict.focusNow);
    final maintain = pick(PortfolioVerdict.maintain);
    final defer = pick(PortfolioVerdict.defer);
    final drop = pick(PortfolioVerdict.dropOrArchive);

    final allocated =
        allocations.fold<double>(0, (s, a) => s + a.recommendedHours);
    final utilisation =
        (allocated / config.weeklyBudgetHours).clamp(0, 1.0).toDouble();

    // Sacrifices: deferred goals with a hard near-term deadline.
    final sacrifices = <String>[];
    for (final a in defer) {
      final d = a.goal.daysRemaining;
      if (d != null && d <= 14) {
        sacrifices.add(
          '${a.goal.category.emoji} ${a.goal.title}: deferred with only $d day(s) left — deadline likely to slip.',
        );
      }
    }

    final playbook = _buildPlaybook(
      focusNow: focusNow,
      maintain: maintain,
      defer: defer,
      drop: drop,
      sacrifices: sacrifices,
      utilisation: utilisation,
      budget: config.weeklyBudgetHours,
    );

    final grade = _grade(
      utilisation,
      focusNow.length,
      drop.length,
      sacrifices.length,
      active.length,
    );

    return PortfolioPlan(
      weeklyBudgetHours: config.weeklyBudgetHours,
      allocatedHours: double.parse(allocated.toStringAsFixed(2)),
      utilisation: utilisation,
      focusNow: focusNow,
      maintain: maintain,
      defer: defer,
      dropOrArchive: drop,
      playbook: playbook,
      sacrifices: sacrifices,
      healthGrade: grade,
    );
  }

  /// Markdown-friendly summary for embedding in agenda/digest screens.
  String formatMarkdown(PortfolioPlan plan) {
    final b = StringBuffer()
      ..writeln('## 🎯 Weekly Goal Portfolio')
      ..writeln('')
      ..writeln(
          '**Budget:** ${plan.weeklyBudgetHours.toStringAsFixed(1)}h · **Allocated:** ${plan.allocatedHours.toStringAsFixed(1)}h (${(plan.utilisation * 100).round()}%) · **Grade:** ${plan.healthGrade}')
      ..writeln('');

    void section(String title, List<GoalAllocation> items) {
      if (items.isEmpty) return;
      b.writeln('### $title');
      for (final a in items) {
        final hrs = a.recommendedHours > 0
            ? ' — **${a.recommendedHours.toStringAsFixed(1)}h**'
            : '';
        b.writeln(
            '- ${a.verdict.emoji} ${a.goal.category.emoji} **${a.goal.title}**$hrs · priority ${a.priorityScore.toStringAsFixed(0)}');
        for (final r in a.reasons) {
          b.writeln('  - $r');
        }
      }
      b.writeln('');
    }

    section('🎯 Focus now', plan.focusNow);
    section('🌿 Maintain', plan.maintain);
    section('⏸️ Defer', plan.defer);
    section('🗑️ Drop or archive', plan.dropOrArchive);

    if (plan.sacrifices.isNotEmpty) {
      b.writeln('### ⚠️ Sacrifices this week');
      for (final s in plan.sacrifices) {
        b.writeln('- $s');
      }
      b.writeln('');
    }

    if (plan.playbook.isNotEmpty) {
      b.writeln('### 📋 Playbook');
      for (final p in plan.playbook) {
        final tag = switch (p.priority) {
          PortfolioActionPriority.p0 => 'P0',
          PortfolioActionPriority.p1 => 'P1',
          PortfolioActionPriority.p2 => 'P2',
        };
        b.writeln('- **[$tag]** ${p.title} — ${p.reason}');
      }
    }
    return b.toString();
  }

  // ---------- internals ----------

  double _urgency(Goal g, DateTime now) {
    final dl = g.deadline;
    if (dl == null) return 0.25; // no deadline → mild urgency
    final days =
        dl.difference(DateTime(now.year, now.month, now.day)).inDays.toDouble();
    if (days <= 0) return 1.0;
    // Smooth decay: 1d → 0.95, 7d → ~0.7, 30d → ~0.4, 90d → ~0.18.
    final score = 1 / (1 + math.log(1 + days) / math.ln2 / 4);
    return score.clamp(0.0, 1.0).toDouble();
  }

  double _value(Goal g) {
    final cat = _categoryWeight[g.category] ?? 0.6;
    // Remaining progress matters more for value — finishing a near-done goal
    // is valuable, but starting an untouched one has high potential too.
    final remaining = 1 - g.effectiveProgress;
    final completionBoost = g.effectiveProgress >= 0.75 ? 0.15 : 0.0;
    final v = cat * (0.6 + 0.4 * remaining) + completionBoost;
    return v.clamp(0.0, 1.0).toDouble();
  }

  double _defaultEffort(Goal g) {
    if (g.milestones.isNotEmpty) {
      final remaining =
          g.milestones.where((m) => !m.isCompleted).length.toDouble();
      return math.max(1.0, remaining * _defaultHoursPerMilestone);
    }
    // Fall back to a remaining-progress estimate of a typical 12h goal.
    final remaining = 1 - g.effectiveProgress;
    return math.max(1.0, _defaultGoalHours * remaining);
  }

  List<PortfolioAction> _buildPlaybook({
    required List<GoalAllocation> focusNow,
    required List<GoalAllocation> maintain,
    required List<GoalAllocation> defer,
    required List<GoalAllocation> drop,
    required List<String> sacrifices,
    required double utilisation,
    required double budget,
  }) {
    final actions = <PortfolioAction>[];

    if (drop.isNotEmpty) {
      actions.add(PortfolioAction(
        priority: PortfolioActionPriority.p0,
        title: 'Archive ${drop.length} stagnant goal(s)',
        reason:
            'They are overdue with negligible progress and would crowd out higher-value work.',
        goalId: drop.first.goal.id,
      ));
    }

    if (focusNow.isNotEmpty) {
      final top = focusNow.first;
      actions.add(PortfolioAction(
        priority: PortfolioActionPriority.p0,
        title: 'Start this week with “${top.goal.title}”',
        reason:
            'Highest portfolio priority (score ${top.priorityScore.toStringAsFixed(0)}) — protect ${top.recommendedHours.toStringAsFixed(1)}h on the calendar.',
        goalId: top.goal.id,
      ));
    }

    if (sacrifices.isNotEmpty) {
      actions.add(PortfolioAction(
        priority: PortfolioActionPriority.p1,
        title: 'Acknowledge ${sacrifices.length} near-term slip(s)',
        reason:
            'Deferred goals have deadlines within 2 weeks. Either renegotiate the deadline or raise the weekly budget.',
      ));
    }

    if (utilisation < 0.5 && focusNow.isNotEmpty) {
      actions.add(PortfolioAction(
        priority: PortfolioActionPriority.p2,
        title: 'You have spare capacity',
        reason:
            'Only ${(utilisation * 100).round()}% of ${budget.toStringAsFixed(1)}h used — consider promoting a deferred goal.',
      ));
    } else if (utilisation >= 0.95) {
      actions.add(PortfolioAction(
        priority: PortfolioActionPriority.p1,
        title: 'Budget fully packed',
        reason:
            'No slack this week — keep new commitments out of the calendar until something lands.',
      ));
    }

    if (maintain.isNotEmpty) {
      actions.add(PortfolioAction(
        priority: PortfolioActionPriority.p2,
        title:
            'Tiny weekly check-ins for ${maintain.length} maintenance goal(s)',
        reason:
            'They are not the focus, but a 30-min touch each prevents stalling.',
      ));
    }

    return actions;
  }

  String _grade(
    double utilisation,
    int focusCount,
    int dropCount,
    int sacrificeCount,
    int activeCount,
  ) {
    // Higher is better. Balanced focus + low sacrifices + sensible utilisation.
    final focusRatio = activeCount == 0 ? 0.0 : focusCount / activeCount;
    double score = 50.0;
    score += focusRatio * 30.0;
    score += (utilisation.clamp(0.4, 0.95).toDouble() - 0.4) * 40.0;
    score -= sacrificeCount * 6.0;
    score -= dropCount * 4.0;
    score = score.clamp(0.0, 100.0).toDouble();
    if (score >= 85) return 'A';
    if (score >= 70) return 'B';
    if (score >= 55) return 'C';
    if (score >= 40) return 'D';
    return 'F';
  }
}

class _ScoredGoal {
  final Goal goal;
  final double urgency;
  final double value;
  final double effort;
  final double roi;
  final double priority;

  const _ScoredGoal(
    this.goal,
    this.urgency,
    this.value,
    this.effort,
    this.roi,
    this.priority,
  );
}
