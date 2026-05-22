/// Goal Check-in Cadence Advisor — agentic per-goal review-discipline
/// advisor for a portfolio of goals.
///
/// Sibling to:
///   * `goal_portfolio_optimizer_service.dart` (weekly trade-offs)
///   * `habit_momentum_service.dart`            (streak risk)
///   * `energy_budget_planner_service.dart`     (daily energy load)
///   * `daily_top_three_advisor_service.dart`   (today shortlist)
///   * `weekly_review_synthesizer_service.dart` (cross-domain weekly summary)
///   * `goal_deadline_risk_advisor_service.dart` (deadline-miss risk)
///
/// Where those focus on what to do / what to ship / what is at deadline-risk,
/// this advisor focuses on a different question:
///
///   "Which goals have I stopped checking in on, and what cadence should I
///    actually be reviewing each goal at given its priority and deadline
///    pressure?"
///
/// Inputs are platform-agnostic value objects ([GoalCheckinSnapshot] +
/// [CheckinCadenceOptions]) — no Flutter, no persistence dependency. Same
/// service powers widgets, headless briefings, and unit tests.
///
/// Pipeline:
///   1. For each goal, compute `recommendedCadenceDays` (priority + deadline
///      pressure + risk-appetite modulated), `daysSinceCheckin`, and an
///      `overdueFactor` = daysSinceCheckin / recommendedCadenceDays.
///   2. Classify each goal into one of:
///      OVERDUE_CRITICAL / OVERDUE / DUE_SOON / ON_CADENCE / NEW / PAUSED
///      with structured `reasons` codes.
///   3. Aggregate portfolio cadence health: overdue ratio, weighted overdue
///      ratio (by priority), portfolio band + A-F grade + headline + insights.
///   4. Emit a deduped P0-first playbook of [CadenceAction] items
///      (priority + owner + blastRadius + reversibility).
///   5. Render via `toText` / `toMarkdown` / `toJson` (deterministic).
///
/// Deterministic — no `Random` usage. All "now" reads go through
/// `options.now ?? DateTime.now`. Stable sort by (overdueFactor desc, id asc)
/// for cadence rows and (priority asc, id asc) for playbook actions.
library;

import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum CheckinRiskAppetite { cautious, balanced, aggressive }

enum CadencePriority { p0, p1, p2, p3 }

enum GoalCheckinVerdict {
  overdueCritical,
  overdue,
  dueSoon,
  onCadence,
  newGoal,
  paused,
}

enum CheckinPortfolioBand { healthy, watch, atRisk, critical }

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

class GoalCheckinSnapshot {
  final String id;
  final String title;
  final String category;
  final int priorityWeight; // 1..5 (5 = highest)
  final DateTime createdAt;
  final DateTime? lastCheckinAt;
  final DateTime? lastProgressUpdateAt;
  final double recentProgressDelta; // progress units since last check-in
  final DateTime? deadline;
  final bool isPaused;
  final String currentStatus; // freeform short label

  const GoalCheckinSnapshot({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
    this.priorityWeight = 3,
    this.lastCheckinAt,
    this.lastProgressUpdateAt,
    this.recentProgressDelta = 0.0,
    this.deadline,
    this.isPaused = false,
    this.currentStatus = '',
  });
}

class CheckinCadenceOptions {
  final CheckinRiskAppetite riskAppetite;
  final DateTime Function()? now;

  /// Cadence in days for a "default" mid-priority goal (priorityWeight==3).
  final int defaultCadenceDays;

  /// Hard floor for any cadence (P0 high-priority urgent goals).
  final int minCadenceDays;

  /// Hard ceiling for any cadence (low-priority, long-runway goals).
  final int maxCadenceDays;

  /// New goals younger than this are treated as NEW and not flagged overdue.
  final int newGoalGraceDays;

  /// Goal is "due soon" when overdueFactor >= this and < 1.0.
  final double dueSoonFactor;

  /// Goal is "overdue critical" when overdueFactor >= this.
  final double criticalFactor;

  /// Max actions in playbook.
  final int maxRecommendations;

  const CheckinCadenceOptions({
    this.riskAppetite = CheckinRiskAppetite.balanced,
    this.now,
    this.defaultCadenceDays = 14,
    this.minCadenceDays = 2,
    this.maxCadenceDays = 60,
    this.newGoalGraceDays = 7,
    this.dueSoonFactor = 0.75,
    this.criticalFactor = 2.0,
    this.maxRecommendations = 12,
  });
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

class CadenceForecast {
  final String id;
  final String title;
  final String category;
  final int priorityWeight;
  final bool isPaused;
  final int? daysSinceCheckin; // null if never checked-in
  final int recommendedCadenceDays;
  final double overdueFactor; // daysSinceCheckin / recommendedCadenceDays
  final int? daysUntilDeadline;
  final GoalCheckinVerdict verdict;
  final CadencePriority priority;
  final List<String> reasons;
  final String suggestedAction;

  const CadenceForecast({
    required this.id,
    required this.title,
    required this.category,
    required this.priorityWeight,
    required this.isPaused,
    required this.daysSinceCheckin,
    required this.recommendedCadenceDays,
    required this.overdueFactor,
    required this.daysUntilDeadline,
    required this.verdict,
    required this.priority,
    required this.reasons,
    required this.suggestedAction,
  });

  Map<String, Object?> toJsonMap() => {
        'id': id,
        'title': title,
        'category': category,
        'priorityWeight': priorityWeight,
        'isPaused': isPaused,
        'daysSinceCheckin': daysSinceCheckin,
        'recommendedCadenceDays': recommendedCadenceDays,
        'overdueFactor': double.parse(overdueFactor.toStringAsFixed(3)),
        'daysUntilDeadline': daysUntilDeadline,
        'verdict': _verdictName(verdict),
        'priority': _priorityName(priority),
        'reasons': reasons,
        'suggestedAction': suggestedAction,
      };
}

class CadenceAction {
  final String id;
  final CadencePriority priority;
  final String label;
  final String reason;
  final String owner;
  final int blastRadius; // 1..5
  final String reversibility; // 'low' | 'medium' | 'high'
  final List<String> targetGoalIds;

  const CadenceAction({
    required this.id,
    required this.priority,
    required this.label,
    required this.reason,
    required this.owner,
    required this.blastRadius,
    required this.reversibility,
    required this.targetGoalIds,
  });

  Map<String, Object?> toJsonMap() => {
        'id': id,
        'priority': _priorityName(priority),
        'label': label,
        'reason': reason,
        'owner': owner,
        'blastRadius': blastRadius,
        'reversibility': reversibility,
        'targetGoalIds': targetGoalIds,
      };
}

class CheckinCadenceReport {
  final DateTime generatedAt;
  final CheckinRiskAppetite riskAppetite;
  final List<CadenceForecast> forecasts;
  final double portfolioOverdueScore; // 0..100
  final CheckinPortfolioBand band;
  final String grade;
  final String headline;
  final List<String> insights;
  final List<CadenceAction> playbook;

  const CheckinCadenceReport({
    required this.generatedAt,
    required this.riskAppetite,
    required this.forecasts,
    required this.portfolioOverdueScore,
    required this.band,
    required this.grade,
    required this.headline,
    required this.insights,
    required this.playbook,
  });

  Map<String, Object?> toJsonMap() => {
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'riskAppetite': _appetiteName(riskAppetite),
        'portfolioOverdueScore':
            double.parse(portfolioOverdueScore.toStringAsFixed(2)),
        'band': _bandName(band),
        'grade': grade,
        'headline': headline,
        'insights': insights,
        'forecasts': forecasts.map((f) => f.toJsonMap()).toList(),
        'playbook': playbook.map((a) => a.toJsonMap()).toList(),
      };
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class GoalCheckinCadenceAdvisorService {
  const GoalCheckinCadenceAdvisorService();

  CheckinCadenceReport evaluate(
    List<GoalCheckinSnapshot> goals,
    CheckinCadenceOptions options,
  ) {
    final now = (options.now ?? DateTime.now)();

    // ----- Per-goal forecasts ------------------------------------------------
    final forecasts = <CadenceForecast>[];
    for (final g in goals) {
      forecasts.add(_forecast(g, options, now));
    }

    // Sort: overdueFactor desc, then id asc.
    forecasts.sort((a, b) {
      final cmp = b.overdueFactor.compareTo(a.overdueFactor);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

    // ----- Portfolio rollup --------------------------------------------------
    final active = forecasts.where((f) => !f.isPaused).toList();
    final overdueCount = active
        .where((f) =>
            f.verdict == GoalCheckinVerdict.overdue ||
            f.verdict == GoalCheckinVerdict.overdueCritical)
        .length;
    final criticalCount = active
        .where((f) => f.verdict == GoalCheckinVerdict.overdueCritical)
        .length;

    double weightedOverdue = 0.0;
    double weightSum = 0.0;
    for (final f in active) {
      final w = f.priorityWeight.clamp(1, 5).toDouble();
      weightSum += w;
      if (f.verdict == GoalCheckinVerdict.overdueCritical) {
        weightedOverdue += w * 1.0;
      } else if (f.verdict == GoalCheckinVerdict.overdue) {
        weightedOverdue += w * 0.6;
      } else if (f.verdict == GoalCheckinVerdict.dueSoon) {
        weightedOverdue += w * 0.25;
      }
    }
    final weightedRatio = weightSum == 0 ? 0.0 : weightedOverdue / weightSum;
    double portfolioScore = weightedRatio * 100.0;

    // Risk appetite modulation.
    portfolioScore = switch (options.riskAppetite) {
      CheckinRiskAppetite.cautious => math.min(100.0, portfolioScore * 1.15),
      CheckinRiskAppetite.balanced => portfolioScore,
      CheckinRiskAppetite.aggressive =>
        math.max(0.0, portfolioScore * 0.85),
    };
    portfolioScore = double.parse(portfolioScore.toStringAsFixed(2));

    final band = _band(portfolioScore, criticalCount);
    final grade = _grade(portfolioScore, criticalCount, active);

    // ----- Insights ----------------------------------------------------------
    final insights = <String>[];
    if (active.isEmpty) {
      insights.add('NO_ACTIVE_GOALS');
    } else {
      if (criticalCount > 0) insights.add('CRITICAL_NEGLECT_DETECTED');
      if (overdueCount >= math.max(1, (active.length * 0.5).round())) {
        insights.add('PORTFOLIO_REVIEW_DEBT');
      }
      // Concentration of overdue in high-priority goals?
      final hpOverdue = active
          .where((f) =>
              f.priorityWeight >= 4 &&
              (f.verdict == GoalCheckinVerdict.overdue ||
                  f.verdict == GoalCheckinVerdict.overdueCritical))
          .length;
      if (hpOverdue >= 2) insights.add('HIGH_PRIORITY_REVIEW_GAP');

      final paused = forecasts.where((f) => f.isPaused).length;
      if (paused > 0 && paused >= forecasts.length * 0.34) {
        insights.add('MANY_PAUSED_GOALS');
      }

      final newGoals = active
          .where((f) => f.verdict == GoalCheckinVerdict.newGoal)
          .length;
      if (newGoals >= 2) insights.add('NEW_GOAL_COHORT');

      // Silent goals: zero recent progress delta + overdue.
      // (We can't know progress directly; use snapshot supplied flag.)
      // Skipped here — reasons codes carry that signal.

      if (overdueCount == 0 && criticalCount == 0) {
        insights.add('CADENCE_HEALTHY');
      }
    }

    // ----- Playbook ----------------------------------------------------------
    final playbook = _buildPlaybook(active, options, insights);

    // ----- Headline ----------------------------------------------------------
    final headline = _headline(
      band: band,
      portfolioScore: portfolioScore,
      overdueCount: overdueCount,
      criticalCount: criticalCount,
      activeCount: active.length,
      insights: insights,
    );

    return CheckinCadenceReport(
      generatedAt: now,
      riskAppetite: options.riskAppetite,
      forecasts: forecasts,
      portfolioOverdueScore: portfolioScore,
      band: band,
      grade: grade,
      headline: headline,
      insights: insights,
      playbook: playbook,
    );
  }

  // ---------------------------------------------------------------------------
  // Per-goal forecasting
  // ---------------------------------------------------------------------------

  CadenceForecast _forecast(
    GoalCheckinSnapshot g,
    CheckinCadenceOptions options,
    DateTime now,
  ) {
    final reasons = <String>[];

    final ageDays = _dayDiff(now, g.createdAt);
    final lastCheck = g.lastCheckinAt;
    final daysSinceCheckin =
        lastCheck == null ? null : math.max(0, _dayDiff(now, lastCheck));

    final daysUntilDeadline =
        g.deadline == null ? null : _dayDiff(g.deadline!, now);

    final cadence = _recommendedCadence(g, options, daysUntilDeadline);

    // Effective elapsed days for "overdue" math: if never checked in,
    // count days since createdAt.
    final effectiveDays = daysSinceCheckin ?? math.max(0, ageDays);

    final overdueFactor = cadence == 0
        ? 0.0
        : effectiveDays.toDouble() / cadence.toDouble();

    // ----- Verdict ----------------------------------------------------------
    GoalCheckinVerdict verdict;
    if (g.isPaused) {
      verdict = GoalCheckinVerdict.paused;
      reasons.add('PAUSED');
    } else if (ageDays < options.newGoalGraceDays && lastCheck == null) {
      verdict = GoalCheckinVerdict.newGoal;
      reasons.add('NEW_GOAL_GRACE_PERIOD');
    } else if (overdueFactor >= options.criticalFactor) {
      verdict = GoalCheckinVerdict.overdueCritical;
      reasons.add('CRITICALLY_OVERDUE');
    } else if (overdueFactor >= 1.0) {
      verdict = GoalCheckinVerdict.overdue;
      reasons.add('OVERDUE');
    } else if (overdueFactor >= options.dueSoonFactor) {
      verdict = GoalCheckinVerdict.dueSoon;
      reasons.add('DUE_SOON');
    } else {
      verdict = GoalCheckinVerdict.onCadence;
      reasons.add('ON_CADENCE');
    }

    // ----- Extra structured reasons -----------------------------------------
    if (g.priorityWeight >= 4 &&
        (verdict == GoalCheckinVerdict.overdue ||
            verdict == GoalCheckinVerdict.overdueCritical)) {
      reasons.add('HIGH_PRIORITY_NEGLECT');
    }
    if (daysUntilDeadline != null && daysUntilDeadline <= 14 && !g.isPaused) {
      reasons.add('DEADLINE_PRESSURE');
    }
    if (daysUntilDeadline != null && daysUntilDeadline < 0 && !g.isPaused) {
      reasons.add('DEADLINE_PASSED');
    }
    if (lastCheck == null && !g.isPaused && ageDays >= options.newGoalGraceDays) {
      reasons.add('NEVER_CHECKED_IN');
    }
    if (g.recentProgressDelta <= 0 &&
        (verdict == GoalCheckinVerdict.overdue ||
            verdict == GoalCheckinVerdict.overdueCritical)) {
      reasons.add('NO_RECENT_PROGRESS');
    }
    if (g.lastProgressUpdateAt != null && lastCheck != null) {
      final progressLag = _dayDiff(lastCheck, g.lastProgressUpdateAt!);
      if (progressLag > cadence * 2) {
        reasons.add('STALE_PROGRESS_DATA');
      }
    }

    // ----- Priority ----------------------------------------------------------
    final CadencePriority priority;
    if (verdict == GoalCheckinVerdict.overdueCritical) {
      priority = CadencePriority.p0;
    } else if (verdict == GoalCheckinVerdict.overdue) {
      priority = g.priorityWeight >= 4 ? CadencePriority.p0 : CadencePriority.p1;
    } else if (verdict == GoalCheckinVerdict.dueSoon) {
      priority = CadencePriority.p2;
    } else if (verdict == GoalCheckinVerdict.newGoal) {
      priority = CadencePriority.p3;
    } else if (verdict == GoalCheckinVerdict.paused) {
      priority = CadencePriority.p3;
    } else {
      priority = CadencePriority.p3;
    }

    // ----- Suggested action --------------------------------------------------
    final suggestedAction = _suggestedAction(g, verdict, cadence);

    return CadenceForecast(
      id: g.id,
      title: g.title,
      category: g.category,
      priorityWeight: g.priorityWeight,
      isPaused: g.isPaused,
      daysSinceCheckin: daysSinceCheckin,
      recommendedCadenceDays: cadence,
      overdueFactor: double.parse(overdueFactor.toStringAsFixed(3)),
      daysUntilDeadline: daysUntilDeadline,
      verdict: verdict,
      priority: priority,
      reasons: reasons,
      suggestedAction: suggestedAction,
    );
  }

  int _recommendedCadence(
    GoalCheckinSnapshot g,
    CheckinCadenceOptions options,
    int? daysUntilDeadline,
  ) {
    // Base cadence: defaultCadenceDays scaled by priority.
    // Priority 5 (highest) -> cadence * 0.5, Priority 1 -> cadence * 1.6.
    final p = g.priorityWeight.clamp(1, 5);
    final priorityMultiplier = switch (p) {
      5 => 0.5,
      4 => 0.7,
      3 => 1.0,
      2 => 1.3,
      _ => 1.6,
    };
    double cadence = options.defaultCadenceDays * priorityMultiplier;

    // Deadline pressure: tighter cadence as deadline approaches.
    if (daysUntilDeadline != null && daysUntilDeadline >= 0) {
      if (daysUntilDeadline <= 7) {
        cadence = math.min(cadence, 2.0);
      } else if (daysUntilDeadline <= 21) {
        cadence = math.min(cadence, 4.0);
      } else if (daysUntilDeadline <= 60) {
        cadence = math.min(cadence, 7.0);
      }
    }

    // Risk appetite shift on cadence: cautious tightens, aggressive loosens.
    cadence = switch (options.riskAppetite) {
      CheckinRiskAppetite.cautious => cadence * 0.85,
      CheckinRiskAppetite.balanced => cadence,
      CheckinRiskAppetite.aggressive => cadence * 1.20,
    };

    final clamped = cadence.clamp(
      options.minCadenceDays.toDouble(),
      options.maxCadenceDays.toDouble(),
    );
    return clamped.round();
  }

  String _suggestedAction(
    GoalCheckinSnapshot g,
    GoalCheckinVerdict v,
    int cadence,
  ) {
    switch (v) {
      case GoalCheckinVerdict.overdueCritical:
        return 'Run a 15-min review now: log progress, decide next milestone, '
            'or formally pause "${g.title}".';
      case GoalCheckinVerdict.overdue:
        return 'Schedule a check-in within 48h for "${g.title}" '
            '(target cadence ≈ ${cadence}d).';
      case GoalCheckinVerdict.dueSoon:
        return 'Plan the next "${g.title}" check-in this week.';
      case GoalCheckinVerdict.onCadence:
        return 'No action needed — next check-in in ≈${cadence}d.';
      case GoalCheckinVerdict.newGoal:
        return 'New goal — first check-in due within ${cadence}d of creation.';
      case GoalCheckinVerdict.paused:
        return 'Paused — decide whether to resume or archive at next weekly review.';
    }
  }

  // ---------------------------------------------------------------------------
  // Portfolio rollup
  // ---------------------------------------------------------------------------

  CheckinPortfolioBand _band(double score, int criticalCount) {
    if (criticalCount > 0 || score >= 70) return CheckinPortfolioBand.critical;
    if (score >= 50) return CheckinPortfolioBand.atRisk;
    if (score >= 25) return CheckinPortfolioBand.watch;
    return CheckinPortfolioBand.healthy;
  }

  String _grade(
    double score,
    int criticalCount,
    List<CadenceForecast> active,
  ) {
    if (active.isEmpty) return 'A';
    if (criticalCount > 0 || score >= 75) return 'F';
    if (score >= 55) return 'D';
    if (score >= 35) return 'C';
    if (score >= 18) return 'B';
    return 'A';
  }

  String _headline({
    required CheckinPortfolioBand band,
    required double portfolioScore,
    required int overdueCount,
    required int criticalCount,
    required int activeCount,
    required List<String> insights,
  }) {
    if (activeCount == 0) {
      return 'CADENCE_VERDICT: NO_ACTIVE_GOALS — nothing to review.';
    }
    final bandLabel = switch (band) {
      CheckinPortfolioBand.healthy => 'CADENCE_HEALTHY',
      CheckinPortfolioBand.watch => 'CADENCE_WATCH',
      CheckinPortfolioBand.atRisk => 'CADENCE_AT_RISK',
      CheckinPortfolioBand.critical => 'CADENCE_CRITICAL',
    };
    return 'CADENCE_VERDICT: $bandLabel — score ${portfolioScore.toStringAsFixed(0)}/100, '
        '$overdueCount/${activeCount} goal(s) overdue '
        '(${criticalCount} critical).';
  }

  // ---------------------------------------------------------------------------
  // Playbook
  // ---------------------------------------------------------------------------

  List<CadenceAction> _buildPlaybook(
    List<CadenceForecast> active,
    CheckinCadenceOptions options,
    List<String> insights,
  ) {
    final out = <CadenceAction>[];

    final critical = active
        .where((f) => f.verdict == GoalCheckinVerdict.overdueCritical)
        .toList();
    final overdue = active
        .where((f) => f.verdict == GoalCheckinVerdict.overdue)
        .toList();
    final dueSoon = active
        .where((f) => f.verdict == GoalCheckinVerdict.dueSoon)
        .toList();
    final neverCheckedIn = active
        .where((f) => f.reasons.contains('NEVER_CHECKED_IN'))
        .toList();
    final highPriorityNeglect = active
        .where((f) => f.reasons.contains('HIGH_PRIORITY_NEGLECT'))
        .toList();
    final deadlinePressure = active
        .where((f) => f.reasons.contains('DEADLINE_PRESSURE'))
        .toList();
    final deadlinePassed = active
        .where((f) => f.reasons.contains('DEADLINE_PASSED'))
        .toList();

    // P0
    if (critical.isNotEmpty) {
      out.add(CadenceAction(
        id: 'EMERGENCY_REVIEW_SWEEP',
        priority: CadencePriority.p0,
        label: 'Run an emergency review sweep on critically-neglected goals',
        reason: '${critical.length} goal(s) are >= '
            '${options.criticalFactor.toStringAsFixed(1)}x past their '
            'recommended cadence — decide resume/pause/archive within 24h.',
        owner: 'self',
        blastRadius: 4,
        reversibility: 'medium',
        targetGoalIds: critical.map((f) => f.id).toList(),
      ));
    }
    if (deadlinePassed.isNotEmpty) {
      out.add(CadenceAction(
        id: 'TRIAGE_PASSED_DEADLINES',
        priority: CadencePriority.p0,
        label: 'Triage goals whose deadline already passed',
        reason: '${deadlinePassed.length} goal(s) have a deadline in the past — '
            'extend, archive, or convert to a follow-up goal.',
        owner: 'self',
        blastRadius: 4,
        reversibility: 'low',
        targetGoalIds: deadlinePassed.map((f) => f.id).toList(),
      ));
    }
    if (highPriorityNeglect.isNotEmpty &&
        highPriorityNeglect.length >= 2 &&
        critical.isEmpty) {
      // Only surface when not already covered by EMERGENCY_REVIEW_SWEEP.
      out.add(CadenceAction(
        id: 'CHECK_IN_TOP_PRIORITIES',
        priority: CadencePriority.p0,
        label: 'Check in on overdue high-priority goals first',
        reason: '${highPriorityNeglect.length} priority-4+ goal(s) are overdue '
            '— review the highest-priority ones first.',
        owner: 'self',
        blastRadius: 3,
        reversibility: 'high',
        targetGoalIds:
            highPriorityNeglect.map((f) => f.id).take(5).toList(),
      ));
    }

    // P1
    if (overdue.isNotEmpty) {
      out.add(CadenceAction(
        id: 'SCHEDULE_OVERDUE_CHECKINS',
        priority: CadencePriority.p1,
        label: 'Schedule check-ins for overdue goals this week',
        reason: '${overdue.length} goal(s) past their recommended cadence — '
            'put a 10-min slot on the calendar for each.',
        owner: 'self',
        blastRadius: 2,
        reversibility: 'high',
        targetGoalIds: overdue.map((f) => f.id).take(8).toList(),
      ));
    }
    if (deadlinePressure.isNotEmpty &&
        !deadlinePressure.every((f) => critical.contains(f))) {
      out.add(CadenceAction(
        id: 'TIGHTEN_DEADLINE_CADENCE',
        priority: CadencePriority.p1,
        label: 'Tighten cadence on goals with deadlines within 2 weeks',
        reason: '${deadlinePressure.length} goal(s) have a deadline within '
            '14 days — switch to ≤ weekly check-ins until ship.',
        owner: 'self',
        blastRadius: 2,
        reversibility: 'high',
        targetGoalIds: deadlinePressure.map((f) => f.id).toList(),
      ));
    }
    if (neverCheckedIn.isNotEmpty) {
      out.add(CadenceAction(
        id: 'KICKOFF_NEVER_CHECKED_GOALS',
        priority: CadencePriority.p1,
        label: 'Run a first check-in for goals that have never been reviewed',
        reason: '${neverCheckedIn.length} goal(s) past their grace period '
            'have no check-in on record yet.',
        owner: 'self',
        blastRadius: 2,
        reversibility: 'high',
        targetGoalIds: neverCheckedIn.map((f) => f.id).take(8).toList(),
      ));
    }

    // P2
    if (dueSoon.isNotEmpty) {
      out.add(CadenceAction(
        id: 'PRE_BOOK_DUE_SOON',
        priority: CadencePriority.p2,
        label: 'Pre-book upcoming check-ins for goals nearing cadence',
        reason: '${dueSoon.length} goal(s) are approaching their next '
            'check-in — block time before they slip into overdue.',
        owner: 'self',
        blastRadius: 1,
        reversibility: 'high',
        targetGoalIds: dueSoon.map((f) => f.id).take(8).toList(),
      ));
    }
    if (insights.contains('MANY_PAUSED_GOALS')) {
      out.add(CadenceAction(
        id: 'AUDIT_PAUSED_GOALS',
        priority: CadencePriority.p2,
        label: 'Audit paused goals — resume, archive, or restate',
        reason: 'A large share of the portfolio is paused; revisit before '
            'they become silent debt.',
        owner: 'self',
        blastRadius: 1,
        reversibility: 'high',
        targetGoalIds: const [],
      ));
    }
    if (insights.contains('NEW_GOAL_COHORT')) {
      out.add(CadenceAction(
        id: 'SET_NEW_GOAL_CADENCES',
        priority: CadencePriority.p2,
        label: 'Establish first-check-in dates for new goals',
        reason: 'Multiple new goals were created recently — fix a cadence '
            'before they age into "never checked in".',
        owner: 'self',
        blastRadius: 1,
        reversibility: 'high',
        targetGoalIds: const [],
      ));
    }

    // Aggressive trims P2 fallback when P0/P1 are present.
    final hasP0 = out.any((a) => a.priority == CadencePriority.p0);
    final hasP1 = out.any((a) => a.priority == CadencePriority.p1);
    if (options.riskAppetite == CheckinRiskAppetite.aggressive &&
        (hasP0 || hasP1)) {
      out.removeWhere((a) =>
          a.priority == CadencePriority.p2 &&
          (a.id == 'PRE_BOOK_DUE_SOON' || a.id == 'AUDIT_PAUSED_GOALS'));
    }

    // P3 fallback when nothing else.
    if (out.isEmpty) {
      out.add(CadenceAction(
        id: 'CADENCE_OK',
        priority: CadencePriority.p3,
        label: 'No cadence action needed — review the portfolio at next weekly cycle',
        reason: 'All active goals are on or ahead of their recommended cadence.',
        owner: 'self',
        blastRadius: 1,
        reversibility: 'high',
        targetGoalIds: const [],
      ));
    }

    // Deduplicate by id (defensive), preserve first occurrence.
    final seen = <String>{};
    final deduped = <CadenceAction>[];
    for (final a in out) {
      if (seen.add(a.id)) deduped.add(a);
    }

    // Stable sort: priority asc then id asc.
    deduped.sort((a, b) {
      final pc = a.priority.index.compareTo(b.priority.index);
      if (pc != 0) return pc;
      return a.id.compareTo(b.id);
    });

    if (deduped.length > options.maxRecommendations) {
      return deduped.sublist(0, options.maxRecommendations);
    }
    return deduped;
  }

  // ---------------------------------------------------------------------------
  // Rendering
  // ---------------------------------------------------------------------------

  String toText(CheckinCadenceReport r) {
    final sb = StringBuffer();
    sb.writeln(r.headline);
    sb.writeln('Grade: ${r.grade} | Score: '
        '${r.portfolioOverdueScore.toStringAsFixed(0)}/100 | '
        'Band: ${_bandName(r.band)} | Appetite: ${_appetiteName(r.riskAppetite)}');
    if (r.insights.isNotEmpty) {
      sb.writeln('Insights: ${r.insights.join(', ')}');
    }
    sb.writeln('');
    sb.writeln('Forecasts:');
    if (r.forecasts.isEmpty) {
      sb.writeln('  (none)');
    } else {
      for (final f in r.forecasts) {
        final ds = f.daysSinceCheckin == null
            ? 'never'
            : '${f.daysSinceCheckin}d';
        sb.writeln('  [${_verdictName(f.verdict).toUpperCase()}] '
            '${f.title} (id=${f.id}, p=${f.priorityWeight}) — '
            'since=$ds, cadence=${f.recommendedCadenceDays}d, '
            'overdue x${f.overdueFactor.toStringAsFixed(2)} '
            '${f.daysUntilDeadline != null ? "(deadline in ${f.daysUntilDeadline}d) " : ""}'
            '-> ${f.suggestedAction}');
      }
    }
    sb.writeln('');
    sb.writeln('Playbook:');
    if (r.playbook.isEmpty) {
      sb.writeln('  (none)');
    } else {
      for (final a in r.playbook) {
        sb.writeln('  [${_priorityName(a.priority).toUpperCase()}] '
            '${a.label} — ${a.reason} '
            '(owner=${a.owner}, blast=${a.blastRadius}, rev=${a.reversibility})');
      }
    }
    return sb.toString();
  }

  String toMarkdown(CheckinCadenceReport r) {
    final sb = StringBuffer();
    sb.writeln('# Goal Check-in Cadence Report');
    sb.writeln('');
    sb.writeln('**${r.headline}**');
    sb.writeln('');
    sb.writeln('- Grade: **${r.grade}**');
    sb.writeln('- Score: ${r.portfolioOverdueScore.toStringAsFixed(0)}/100');
    sb.writeln('- Band: ${_bandName(r.band)}');
    sb.writeln('- Risk appetite: ${_appetiteName(r.riskAppetite)}');
    sb.writeln('- Generated: ${r.generatedAt.toUtc().toIso8601String()}');
    if (r.insights.isNotEmpty) {
      sb.writeln('');
      sb.writeln('## Insights');
      for (final i in r.insights) {
        sb.writeln('- $i');
      }
    }
    sb.writeln('');
    sb.writeln('## Forecasts');
    if (r.forecasts.isEmpty) {
      sb.writeln('_(no goals)_');
    } else {
      sb.writeln('| Goal | Priority | Verdict | Since | Cadence | Overdue | Deadline |');
      sb.writeln('| --- | --- | --- | --- | --- | --- | --- |');
      for (final f in r.forecasts) {
        final ds = f.daysSinceCheckin == null
            ? 'never'
            : '${f.daysSinceCheckin}d';
        final dl = f.daysUntilDeadline == null
            ? '—'
            : '${f.daysUntilDeadline}d';
        sb.writeln('| ${f.title} (${f.id}) | ${f.priorityWeight} | '
            '${_verdictName(f.verdict)} | $ds | ${f.recommendedCadenceDays}d | '
            'x${f.overdueFactor.toStringAsFixed(2)} | $dl |');
      }
    }
    sb.writeln('');
    sb.writeln('## Playbook');
    if (r.playbook.isEmpty) {
      sb.writeln('_(no actions)_');
    } else {
      sb.writeln('| Priority | Action | Reason | Owner | Blast | Reversibility |');
      sb.writeln('| --- | --- | --- | --- | --- | --- |');
      for (final a in r.playbook) {
        sb.writeln('| ${_priorityName(a.priority)} | ${a.label} | '
            '${a.reason} | ${a.owner} | ${a.blastRadius} | ${a.reversibility} |');
      }
    }
    return sb.toString();
  }

  String toJson(CheckinCadenceReport r) {
    // Deterministic key order is guaranteed by toJsonMap insertion order.
    return _jsonEncodeMap(r.toJsonMap());
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

int _dayDiff(DateTime a, DateTime b) {
  final ad = DateTime(a.year, a.month, a.day);
  final bd = DateTime(b.year, b.month, b.day);
  return ad.difference(bd).inDays;
}

String _verdictName(GoalCheckinVerdict v) => switch (v) {
      GoalCheckinVerdict.overdueCritical => 'overdue_critical',
      GoalCheckinVerdict.overdue => 'overdue',
      GoalCheckinVerdict.dueSoon => 'due_soon',
      GoalCheckinVerdict.onCadence => 'on_cadence',
      GoalCheckinVerdict.newGoal => 'new_goal',
      GoalCheckinVerdict.paused => 'paused',
    };

String _priorityName(CadencePriority p) => switch (p) {
      CadencePriority.p0 => 'P0',
      CadencePriority.p1 => 'P1',
      CadencePriority.p2 => 'P2',
      CadencePriority.p3 => 'P3',
    };

String _bandName(CheckinPortfolioBand b) => switch (b) {
      CheckinPortfolioBand.healthy => 'healthy',
      CheckinPortfolioBand.watch => 'watch',
      CheckinPortfolioBand.atRisk => 'at_risk',
      CheckinPortfolioBand.critical => 'critical',
    };

String _appetiteName(CheckinRiskAppetite a) => switch (a) {
      CheckinRiskAppetite.cautious => 'cautious',
      CheckinRiskAppetite.balanced => 'balanced',
      CheckinRiskAppetite.aggressive => 'aggressive',
    };

/// Minimal deterministic JSON encoder (no `dart:convert` dependency) so the
/// service stays dependency-free at the leaf and renders byte-stable output.
String _jsonEncodeMap(Object? v) {
  final sb = StringBuffer();
  _writeJson(sb, v);
  return sb.toString();
}

void _writeJson(StringBuffer sb, Object? v) {
  if (v == null) {
    sb.write('null');
  } else if (v is bool) {
    sb.write(v ? 'true' : 'false');
  } else if (v is num) {
    if (v is double && v.isNaN) {
      sb.write('null');
    } else if (v is double && v.isInfinite) {
      sb.write('null');
    } else {
      sb.write(v.toString());
    }
  } else if (v is String) {
    sb.write('"');
    for (final code in v.codeUnits) {
      switch (code) {
        case 0x22:
          sb.write(r'\"');
          break;
        case 0x5C:
          sb.write(r'\\');
          break;
        case 0x0A:
          sb.write(r'\n');
          break;
        case 0x0D:
          sb.write(r'\r');
          break;
        case 0x09:
          sb.write(r'\t');
          break;
        default:
          if (code < 0x20) {
            sb.write('\\u${code.toRadixString(16).padLeft(4, '0')}');
          } else {
            sb.writeCharCode(code);
          }
      }
    }
    sb.write('"');
  } else if (v is List) {
    sb.write('[');
    for (var i = 0; i < v.length; i++) {
      if (i > 0) sb.write(',');
      _writeJson(sb, v[i]);
    }
    sb.write(']');
  } else if (v is Map) {
    sb.write('{');
    var first = true;
    v.forEach((key, value) {
      if (!first) sb.write(',');
      first = false;
      _writeJson(sb, key.toString());
      sb.write(':');
      _writeJson(sb, value);
    });
    sb.write('}');
  } else {
    _writeJson(sb, v.toString());
  }
}
