/// Goal Deadline Risk Advisor — agentic deadline-risk forecaster for a
/// portfolio of goals.
///
/// Sibling to:
///   * `goal_portfolio_optimizer_service.dart` (weekly trade-offs)
///   * `habit_momentum_service.dart`            (streak risk)
///   * `daily_top_three_advisor_service.dart`   (today shortlist)
///   * `weekly_review_synthesizer_service.dart` (cross-domain summary)
///
/// Where those operate on weekly portfolios / streaks / today / week, this
/// advisor focuses on one question:
///
///   "For every goal I'm holding, what is the realistic risk that I miss the
///    deadline given current velocity, and what is the smallest concrete
///    action I should take this week to keep it on track?"
///
/// Inputs are platform-agnostic value objects ([GoalSnapshot] +
/// [DeadlineRiskOptions]). No Flutter / persistence dependency — same service
/// powers widgets, headless briefings, and unit tests.
///
/// Pipeline:
///   1. For each non-paused goal compute days-remaining / velocity /
///      shortfall / projected completion / risk score 0..100.
///   2. Classify into MISSED / CRITICAL / AT_RISK / WATCH / ON_TRACK /
///      COASTING with structured `reasons` codes.
///   3. Roll up portfolioRiskScore + band + A-F grade + headline + insights.
///   4. Emit P0-P3 playbook (deduped, P0-first, owner+blastRadius+reversibility).
///   5. Render via `toText` / `toMarkdown` / `toJson`.
///
/// Deterministic — no [Random] usage, all "now" reads go through
/// `options.now ?? DateTime.now`. Stable sort by (riskScore desc, id asc) for
/// forecasts and (priority asc, id asc) for playbook actions.
library;

import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum DeadlineRiskAppetite { cautious, balanced, aggressive }

enum DeadlineRiskPriority { p0, p1, p2, p3 }

enum GoalDeadlineVerdict {
  missed,
  critical,
  atRisk,
  watch,
  onTrack,
  coasting,
}

enum DeadlineRiskBand { healthy, watch, atRisk, critical }

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

class GoalSnapshot {
  final String id;
  final String title;
  final String category;
  final DateTime deadline;
  final double progress; // 0..1
  final double targetUnits;
  final double unitsDoneSoFar;
  final DateTime createdAt;
  final double recentVelocityUnitsPerWeek;
  final int priorityWeight; // 1..5
  final bool isPaused;
  final List<String> tags;

  const GoalSnapshot({
    required this.id,
    required this.title,
    required this.category,
    required this.deadline,
    required this.progress,
    required this.createdAt,
    this.targetUnits = 1.0,
    this.unitsDoneSoFar = 0.0,
    this.recentVelocityUnitsPerWeek = 0.0,
    this.priorityWeight = 3,
    this.isPaused = false,
    this.tags = const [],
  });
}

class DeadlineRiskOptions {
  final DeadlineRiskAppetite riskAppetite;
  final DateTime Function()? now;
  final int bufferDaysCushion;
  final int maxRecommendations;

  const DeadlineRiskOptions({
    this.riskAppetite = DeadlineRiskAppetite.balanced,
    this.now,
    this.bufferDaysCushion = 7,
    this.maxRecommendations = 12,
  });
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

class GoalDeadlineForecast {
  final String goalId;
  final String title;
  final String category;
  final double riskScore; // 0..100
  final DeadlineRiskPriority priority;
  final GoalDeadlineVerdict verdict;
  final List<String> reasons;
  final String recommendedFirstStep;
  final int daysRemaining;
  final int daysSlippage;
  final DateTime? projectedCompletion;
  final double requiredUnitsPerWeek;
  final double recentVelocityUnitsPerWeek;
  final int priorityWeight;

  const GoalDeadlineForecast({
    required this.goalId,
    required this.title,
    required this.category,
    required this.riskScore,
    required this.priority,
    required this.verdict,
    required this.reasons,
    required this.recommendedFirstStep,
    required this.daysRemaining,
    required this.daysSlippage,
    required this.projectedCompletion,
    required this.requiredUnitsPerWeek,
    required this.recentVelocityUnitsPerWeek,
    required this.priorityWeight,
  });

  Map<String, dynamic> toJson() => {
        'goalId': goalId,
        'title': title,
        'category': category,
        'riskScore': double.parse(riskScore.toStringAsFixed(2)),
        'priority': priority.name,
        'verdict': verdict.name,
        'reasons': List<String>.from(reasons),
        'recommendedFirstStep': recommendedFirstStep,
        'daysRemaining': daysRemaining,
        'daysSlippage': daysSlippage,
        'projectedCompletion': projectedCompletion?.toIso8601String(),
        'requiredUnitsPerWeek':
            double.parse(requiredUnitsPerWeek.toStringAsFixed(3)),
        'recentVelocityUnitsPerWeek':
            double.parse(recentVelocityUnitsPerWeek.toStringAsFixed(3)),
        'priorityWeight': priorityWeight,
      };
}

class PlaybookAction {
  final String id;
  final DeadlineRiskPriority priority;
  final String label;
  final String reason;
  final String owner;
  final int blastRadius; // 1..5
  final String reversibility; // low / medium / high
  final List<String> relatedGoalIds;
  final String? suggestedValue;

  const PlaybookAction({
    required this.id,
    required this.priority,
    required this.label,
    required this.reason,
    required this.owner,
    required this.blastRadius,
    required this.reversibility,
    required this.relatedGoalIds,
    this.suggestedValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'priority': priority.name,
        'label': label,
        'reason': reason,
        'owner': owner,
        'blastRadius': blastRadius,
        'reversibility': reversibility,
        'relatedGoalIds': List<String>.from(relatedGoalIds),
        'suggestedValue': suggestedValue,
      };
}

class GoalDeadlineRiskReport {
  final List<GoalDeadlineForecast> forecasts;
  final List<PlaybookAction> playbook;
  final double portfolioRiskScore; // 0..100
  final DeadlineRiskBand band;
  final String grade; // A..F
  final String headline;
  final List<String> insights;
  final DateTime generatedAt;

  const GoalDeadlineRiskReport({
    required this.forecasts,
    required this.playbook,
    required this.portfolioRiskScore,
    required this.band,
    required this.grade,
    required this.headline,
    required this.insights,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'forecasts': forecasts.map((f) => f.toJson()).toList(),
        'playbook': playbook.map((a) => a.toJson()).toList(),
        'portfolioRiskScore':
            double.parse(portfolioRiskScore.toStringAsFixed(2)),
        'band': band.name,
        'grade': grade,
        'headline': headline,
        'insights': List<String>.from(insights),
        'generatedAt': generatedAt.toIso8601String(),
      };

  String toText() {
    final buf = StringBuffer();
    buf.writeln('Goal Deadline Risk Report');
    buf.writeln('Generated: ${generatedAt.toIso8601String()}');
    buf.writeln('Headline: $headline');
    buf.writeln(
        'Portfolio risk: ${portfolioRiskScore.toStringAsFixed(1)}/100 '
        '(${band.name})  Grade: $grade');
    buf.writeln('');
    buf.writeln('Forecasts:');
    if (forecasts.isEmpty) {
      buf.writeln('  (none)');
    } else {
      for (final f in forecasts) {
        buf.writeln(
            '  - [${f.priority.name}] ${f.title} :: ${f.verdict.name} '
            '(risk ${f.riskScore.toStringAsFixed(1)}, '
            'days_remaining=${f.daysRemaining}, '
            'slippage=${f.daysSlippage})');
        buf.writeln('      first step: ${f.recommendedFirstStep}');
        if (f.reasons.isNotEmpty) {
          buf.writeln('      reasons: ${f.reasons.join(", ")}');
        }
      }
    }
    buf.writeln('');
    buf.writeln('Playbook:');
    if (playbook.isEmpty) {
      buf.writeln('  (none)');
    } else {
      for (final a in playbook) {
        buf.writeln('  - [${a.priority.name}] ${a.label} (owner=${a.owner}, '
            'blast=${a.blastRadius}, rev=${a.reversibility})');
        buf.writeln('      ${a.reason}');
      }
    }
    buf.writeln('');
    buf.writeln('Insights:');
    if (insights.isEmpty) {
      buf.writeln('  (none)');
    } else {
      for (final code in insights) {
        buf.writeln('  - $code');
      }
    }
    return buf.toString();
  }

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('## Summary');
    buf.writeln('');
    buf.writeln('- Headline: **$headline**');
    buf.writeln(
        '- Portfolio risk: **${portfolioRiskScore.toStringAsFixed(1)}/100** '
        '(${band.name})');
    buf.writeln('- Grade: **$grade**');
    buf.writeln('- Generated: ${generatedAt.toIso8601String()}');
    buf.writeln('');
    buf.writeln('## Forecasts');
    buf.writeln('');
    if (forecasts.isEmpty) {
      buf.writeln('_No goals in scope._');
    } else {
      buf.writeln(
          '| Goal | Verdict | Priority | Risk | Days left | Slippage | First step |');
      buf.writeln(
          '|---|---|---|---:|---:|---:|---|');
      for (final f in forecasts) {
        buf.writeln('| ${_escape(f.title)} | ${f.verdict.name} | '
            '${f.priority.name} | ${f.riskScore.toStringAsFixed(1)} | '
            '${f.daysRemaining} | ${f.daysSlippage} | '
            '${_escape(f.recommendedFirstStep)} |');
      }
    }
    buf.writeln('');
    buf.writeln('## Playbook');
    buf.writeln('');
    if (playbook.isEmpty) {
      buf.writeln('_No actions._');
    } else {
      buf.writeln('| Priority | Action | Owner | Blast | Reversibility | Reason |');
      buf.writeln('|---|---|---|---:|---|---|');
      for (final a in playbook) {
        buf.writeln('| ${a.priority.name} | ${_escape(a.label)} | ${a.owner} | '
            '${a.blastRadius} | ${a.reversibility} | ${_escape(a.reason)} |');
      }
    }
    buf.writeln('');
    buf.writeln('## Insights');
    buf.writeln('');
    if (insights.isEmpty) {
      buf.writeln('_No insights._');
    } else {
      for (final code in insights) {
        buf.writeln('- $code');
      }
    }
    return buf.toString();
  }

  static String _escape(String s) =>
      s.replaceAll('|', r'\|').replaceAll('\n', ' ');
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class GoalDeadlineRiskAdvisorService {
  GoalDeadlineRiskReport evaluate(
    List<GoalSnapshot> goals,
    DeadlineRiskOptions options,
  ) {
    final now = (options.now ?? DateTime.now)();
    final forecasts = <GoalDeadlineForecast>[];

    for (final g in goals) {
      forecasts.add(_forecast(g, now, options));
    }

    forecasts.sort((a, b) {
      final cmp = b.riskScore.compareTo(a.riskScore);
      if (cmp != 0) return cmp;
      return a.goalId.compareTo(b.goalId);
    });

    final portfolioRiskScore = _portfolioRisk(forecasts);
    final band = _band(portfolioRiskScore);
    final hasMissed = forecasts.any(
        (f) => f.verdict == GoalDeadlineVerdict.missed);
    final grade = _grade(portfolioRiskScore, hasMissed: hasMissed);
    final insights = _insights(forecasts);
    final playbook =
        _playbook(forecasts, options, grade, insights);
    final headline = _headline(forecasts, grade);

    return GoalDeadlineRiskReport(
      forecasts: forecasts,
      playbook: playbook.take(options.maxRecommendations).toList(),
      portfolioRiskScore: portfolioRiskScore,
      band: band,
      grade: grade,
      headline: headline,
      insights: insights,
      generatedAt: now,
    );
  }

  // -------------------------------------------------------------------------
  // Per-goal forecast
  // -------------------------------------------------------------------------

  GoalDeadlineForecast _forecast(
    GoalSnapshot g,
    DateTime now,
    DeadlineRiskOptions options,
  ) {
    final daysRemaining = g.deadline.difference(now).inDays;
    final workRemainingUnits =
        math.max(0.0, g.targetUnits - g.unitsDoneSoFar);
    final weeksRemaining = math.max(daysRemaining / 7.0, 0.1);
    final requiredUnitsPerWeek = workRemainingUnits / weeksRemaining;
    final velocityShortfall =
        requiredUnitsPerWeek - g.recentVelocityUnitsPerWeek;

    DateTime? projectedCompletion;
    int daysSlippage;
    if (g.recentVelocityUnitsPerWeek <= 1e-9) {
      // No velocity — treat as worst-case (never finishing).
      projectedCompletion = null;
      // Cap synthetic slippage so it cannot dominate everything else.
      daysSlippage = workRemainingUnits > 0 ? 3650 : 0;
    } else {
      final weeksToFinish =
          workRemainingUnits / g.recentVelocityUnitsPerWeek;
      // cap projection at ~5 years from now for stability
      final cappedDays = math.min(weeksToFinish * 7.0, 365.0 * 5.0);
      projectedCompletion =
          now.add(Duration(days: cappedDays.round()));
      daysSlippage =
          projectedCompletion.difference(g.deadline).inDays;
    }

    // Risk score components.
    double risk = 0.0;
    final reasons = <String>[];

    // (1) Deadline pressure
    if (daysRemaining <= 7) {
      risk += 35;
    } else if (daysRemaining <= 21) {
      risk += 25;
    } else if (daysRemaining <= 60) {
      risk += 15;
    } else {
      risk += 5;
    }
    if (daysRemaining <= 14) {
      reasons.add('DEADLINE_IMMINENT');
    }

    // (2) Velocity gap
    if (requiredUnitsPerWeek > 0) {
      final gapFrac =
          (velocityShortfall / math.max(requiredUnitsPerWeek, 0.01))
              .clamp(0.0, 1.0);
      risk += 30 * gapFrac;
      if (velocityShortfall > 0) {
        reasons.add('BEHIND_SCHEDULE');
      } else {
        reasons.add('AHEAD_OF_SCHEDULE');
      }
    }

    // (3) Progress lag
    final totalLifespanDays = math
        .max(1, g.deadline.difference(g.createdAt).inDays);
    final elapsedDays =
        math.max(0, now.difference(g.createdAt).inDays);
    final expectedProgress =
        (elapsedDays / totalLifespanDays).clamp(0.0, 1.0);
    final progressLag =
        (expectedProgress - g.progress).clamp(0.0, 1.0);
    risk += 20 * progressLag;

    // (4) Stale
    final ageDays = now.difference(g.createdAt).inDays;
    if (g.recentVelocityUnitsPerWeek <= 1e-9 &&
        ageDays > 14 &&
        g.progress < 0.5) {
      risk += 10;
      reasons.add('STALE_GOAL');
    }
    if (g.recentVelocityUnitsPerWeek <= 1e-9 && workRemainingUnits > 0) {
      if (!reasons.contains('NO_VELOCITY')) reasons.add('NO_VELOCITY');
    }

    // Priority multiplier.
    final priorityMult = 0.85 + 0.075 * g.priorityWeight;
    risk = risk * priorityMult;

    // Risk appetite shift.
    switch (options.riskAppetite) {
      case DeadlineRiskAppetite.cautious:
        risk += 8;
        break;
      case DeadlineRiskAppetite.aggressive:
        risk -= 8;
        break;
      case DeadlineRiskAppetite.balanced:
        break;
    }
    risk = risk.clamp(0.0, 100.0);

    if (g.priorityWeight >= 4) reasons.add('PRIORITY_HIGH');

    // Paused override: paused goals get a special verdict path.
    GoalDeadlineVerdict verdict;
    DeadlineRiskPriority priority;
    if (g.isPaused) {
      if (daysRemaining <= 14 && g.progress < 1.0) {
        verdict = GoalDeadlineVerdict.atRisk;
        priority = DeadlineRiskPriority.p1;
        reasons.add('PAUSED_BUT_DUE_SOON');
        // Boost risk a bit so it sorts above truly healthy items.
        risk = math.max(risk, 55.0);
      } else {
        verdict = GoalDeadlineVerdict.watch;
        priority = DeadlineRiskPriority.p2;
        reasons.add('PAUSED');
      }
    } else if (daysRemaining < 0 && g.progress < 1.0) {
      verdict = GoalDeadlineVerdict.missed;
      priority = DeadlineRiskPriority.p0;
      reasons.add('OVERDUE');
      risk = math.max(risk, 90.0);
    } else if (risk >= 80 ||
        (daysSlippage >= 14 && daysRemaining <= 30 && g.progress < 1.0)) {
      verdict = GoalDeadlineVerdict.critical;
      priority = DeadlineRiskPriority.p0;
    } else if (risk >= 60) {
      verdict = GoalDeadlineVerdict.atRisk;
      priority = DeadlineRiskPriority.p1;
    } else if (g.progress >= 1.0 ||
        (daysRemaining > 365 && g.progress >= 0.05)) {
      verdict = GoalDeadlineVerdict.coasting;
      priority = DeadlineRiskPriority.p3;
    } else if (risk <= 35 && velocityShortfall <= 0) {
      verdict = GoalDeadlineVerdict.onTrack;
      priority = DeadlineRiskPriority.p3;
    } else {
      verdict = GoalDeadlineVerdict.watch;
      priority = DeadlineRiskPriority.p2;
    }

    final firstStep = _firstStep(g, verdict, requiredUnitsPerWeek);

    return GoalDeadlineForecast(
      goalId: g.id,
      title: g.title,
      category: g.category,
      riskScore: risk,
      priority: priority,
      verdict: verdict,
      reasons: reasons,
      recommendedFirstStep: firstStep,
      daysRemaining: daysRemaining,
      daysSlippage: daysSlippage,
      projectedCompletion: projectedCompletion,
      requiredUnitsPerWeek: requiredUnitsPerWeek,
      recentVelocityUnitsPerWeek: g.recentVelocityUnitsPerWeek,
      priorityWeight: g.priorityWeight,
    );
  }

  String _firstStep(
    GoalSnapshot g,
    GoalDeadlineVerdict verdict,
    double required,
  ) {
    switch (verdict) {
      case GoalDeadlineVerdict.missed:
        return "Acknowledge missed deadline on '${g.title}' and renegotiate or close it out.";
      case GoalDeadlineVerdict.critical:
        return "Block a deep-work session this week toward '${g.title}' "
            "(needs ~${required.toStringAsFixed(1)} units/week).";
      case GoalDeadlineVerdict.atRisk:
        return "Schedule one concrete step on '${g.title}' in the next 48h.";
      case GoalDeadlineVerdict.watch:
        return "Log a single hour of progress on '${g.title}' this week.";
      case GoalDeadlineVerdict.onTrack:
        return "Keep current cadence on '${g.title}'.";
      case GoalDeadlineVerdict.coasting:
        return "Celebrate progress on '${g.title}' and consider raising the target.";
    }
  }

  // -------------------------------------------------------------------------
  // Portfolio
  // -------------------------------------------------------------------------

  double _portfolioRisk(List<GoalDeadlineForecast> fs) {
    if (fs.isEmpty) return 0.0;
    double num = 0;
    double den = 0;
    for (final f in fs) {
      final w = f.priorityWeight.toDouble();
      num += f.riskScore * w;
      den += w;
    }
    if (den <= 0) return 0.0;
    return (num / den).clamp(0.0, 100.0);
  }

  DeadlineRiskBand _band(double risk) {
    if (risk <= 25) return DeadlineRiskBand.healthy;
    if (risk <= 50) return DeadlineRiskBand.watch;
    if (risk <= 75) return DeadlineRiskBand.atRisk;
    return DeadlineRiskBand.critical;
  }

  String _grade(double risk, {required bool hasMissed}) {
    if (hasMissed) return 'F';
    if (risk <= 15) return 'A';
    if (risk <= 30) return 'B';
    if (risk <= 50) return 'C';
    if (risk <= 70) return 'D';
    return 'F';
  }

  String _headline(List<GoalDeadlineForecast> fs, String grade) {
    if (fs.isEmpty) {
      return 'CLEAR_RUNWAY — no goals in scope (grade $grade).';
    }
    final critical = fs
        .where((f) =>
            f.verdict == GoalDeadlineVerdict.critical ||
            f.verdict == GoalDeadlineVerdict.missed)
        .length;
    final atRisk =
        fs.where((f) => f.verdict == GoalDeadlineVerdict.atRisk).length;
    if (critical == 0 && atRisk == 0) {
      return 'All ${fs.length} goals on track — portfolio grade $grade.';
    }
    final parts = <String>[];
    if (critical > 0) parts.add('$critical critical');
    if (atRisk > 0) parts.add('$atRisk at risk');
    return '${parts.join(", ")} — portfolio grade $grade.';
  }

  List<String> _insights(List<GoalDeadlineForecast> fs) {
    final out = <String>[];
    if (fs.isEmpty) {
      out.add('CLEAR_RUNWAY');
      return out;
    }

    final critical = fs
        .where((f) =>
            f.verdict == GoalDeadlineVerdict.critical ||
            f.verdict == GoalDeadlineVerdict.missed)
        .toList();
    final atRisk = fs
        .where((f) => f.verdict == GoalDeadlineVerdict.atRisk)
        .toList();
    final dueSoon = fs.where((f) => f.daysRemaining <= 14).toList();
    final stalled = fs
        .where((f) => f.recentVelocityUnitsPerWeek <= 1e-9)
        .toList();

    if (critical.length >= 2) out.add('MANY_CRITICAL');
    if (dueSoon.length >= 2) out.add('DEADLINE_CLIFF');
    if (fs.isNotEmpty && stalled.length >= (fs.length / 2).ceil()) {
      out.add('STALLED_PORTFOLIO');
    }
    final allClear = fs.every((f) =>
        f.verdict == GoalDeadlineVerdict.onTrack ||
        f.verdict == GoalDeadlineVerdict.coasting);
    if (allClear) out.add('CLEAR_RUNWAY');

    // MONO_CATEGORY_RISK
    if (critical.isNotEmpty) {
      final byCat = <String, double>{};
      double total = 0;
      for (final f in critical) {
        byCat[f.category] =
            (byCat[f.category] ?? 0) + f.riskScore;
        total += f.riskScore;
      }
      if (total > 0) {
        for (final entry in byCat.entries) {
          if (entry.value / total >= 0.60) {
            out.add('MONO_CATEGORY_RISK');
            break;
          }
        }
      }
    }
    if (atRisk.isNotEmpty && out.isEmpty) {
      // surface something useful even when no big-bucket insight fired
      out.add('AT_RISK_SUBSET');
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // Playbook
  // -------------------------------------------------------------------------

  List<PlaybookAction> _playbook(
    List<GoalDeadlineForecast> fs,
    DeadlineRiskOptions options,
    String grade,
    List<String> insights,
  ) {
    final out = <PlaybookAction>[];

    // ESCALATE_MISSED_GOAL (P0, per missed)
    for (final f in fs) {
      if (f.verdict == GoalDeadlineVerdict.missed) {
        out.add(PlaybookAction(
          id: 'escalate_missed_goal:${f.goalId}',
          priority: DeadlineRiskPriority.p0,
          label: 'ESCALATE_MISSED_GOAL',
          reason:
              "'${f.title}' is past its deadline and still incomplete. Decide to renegotiate, drop, or salvage.",
          owner: 'goal_owner',
          blastRadius: 2,
          reversibility: 'medium',
          relatedGoalIds: [f.goalId],
          suggestedValue: f.goalId,
        ));
      }
    }

    // TRIPLE_DOWN_THIS_WEEK (P0) — >=1 CRITICAL with deadline<=14d
    final crit14 = fs
        .where((f) =>
            f.verdict == GoalDeadlineVerdict.critical &&
            f.daysRemaining <= 14)
        .toList();
    if (crit14.isNotEmpty) {
      out.add(PlaybookAction(
        id: 'triple_down_this_week',
        priority: DeadlineRiskPriority.p0,
        label: 'TRIPLE_DOWN_THIS_WEEK',
        reason:
            '${crit14.length} critical goal(s) have deadlines inside 14 days. Clear the calendar for them.',
        owner: 'goal_owner',
        blastRadius: 3,
        reversibility: 'low',
        relatedGoalIds: crit14.map((f) => f.goalId).toList(),
      ));
    }

    // INCREASE_WEEKLY_VELOCITY (P1)
    final atRisk = fs
        .where((f) => f.verdict == GoalDeadlineVerdict.atRisk)
        .toList();
    final big2x = fs.where((f) =>
        f.requiredUnitsPerWeek > 0 &&
        f.recentVelocityUnitsPerWeek <
            (f.requiredUnitsPerWeek / 2.0));
    if (atRisk.length >= 2 || big2x.isNotEmpty) {
      final related = <String>{
        ...atRisk.map((f) => f.goalId),
        ...big2x.map((f) => f.goalId),
      }.toList()
        ..sort();
      out.add(PlaybookAction(
        id: 'increase_weekly_velocity',
        priority: DeadlineRiskPriority.p1,
        label: 'INCREASE_WEEKLY_VELOCITY',
        reason:
            'Current weekly output is too low to clear remaining work for ${related.length} goal(s).',
        owner: 'goal_owner',
        blastRadius: 2,
        reversibility: 'high',
        relatedGoalIds: related,
      ));
    }

    // RENEGOTIATE_DEADLINE (P1) — CRITICAL with daysSlippage>=21
    final renegotiate = fs
        .where((f) =>
            f.verdict == GoalDeadlineVerdict.critical &&
            f.daysSlippage >= 21)
        .toList();
    if (renegotiate.isNotEmpty) {
      out.add(PlaybookAction(
        id: 'renegotiate_deadline',
        priority: DeadlineRiskPriority.p1,
        label: 'RENEGOTIATE_DEADLINE',
        reason:
            '${renegotiate.length} goal(s) are projecting >=21 days late. Reset expectations before they slip silently.',
        owner: 'stakeholder',
        blastRadius: 3,
        reversibility: 'medium',
        relatedGoalIds: renegotiate.map((f) => f.goalId).toList(),
      ));
    }

    // UNPAUSE_DUE_GOAL (P1)
    final pausedDue = fs
        .where((f) => f.reasons.contains('PAUSED_BUT_DUE_SOON'))
        .toList();
    if (pausedDue.isNotEmpty) {
      out.add(PlaybookAction(
        id: 'unpause_due_goal',
        priority: DeadlineRiskPriority.p1,
        label: 'UNPAUSE_DUE_GOAL',
        reason:
            '${pausedDue.length} paused goal(s) have a deadline inside 14 days. Either resume them or close them out.',
        owner: 'goal_owner',
        blastRadius: 1,
        reversibility: 'high',
        relatedGoalIds: pausedDue.map((f) => f.goalId).toList(),
      ));
    }

    // SHED_LOW_PRIORITY_GOALS (P2)
    final lowPriAtRisk = fs
        .where((f) =>
            f.verdict == GoalDeadlineVerdict.atRisk &&
            f.priorityWeight <= 2)
        .toList();
    if (atRisk.length >= 3 && lowPriAtRisk.length >= 2) {
      out.add(PlaybookAction(
        id: 'shed_low_priority_goals',
        priority: DeadlineRiskPriority.p2,
        label: 'SHED_LOW_PRIORITY_GOALS',
        reason:
            'Portfolio is overcommitted; drop or defer low-priority at-risk goals to protect the rest.',
        owner: 'goal_owner',
        blastRadius: 2,
        reversibility: 'medium',
        relatedGoalIds: lowPriAtRisk.map((f) => f.goalId).toList(),
      ));
    }

    // SCHEDULE_DEEP_WORK_BLOCK (P2)
    final atRiskNoVel = fs.where((f) =>
        f.verdict == GoalDeadlineVerdict.atRisk &&
        f.recentVelocityUnitsPerWeek <= 1e-9);
    if (atRiskNoVel.isNotEmpty) {
      out.add(PlaybookAction(
        id: 'schedule_deep_work_block',
        priority: DeadlineRiskPriority.p2,
        label: 'SCHEDULE_DEEP_WORK_BLOCK',
        reason:
            'At-risk goal(s) had zero recent velocity. A single protected block this week is the cheapest unstick.',
        owner: 'self',
        blastRadius: 1,
        reversibility: 'high',
        relatedGoalIds: atRiskNoVel.map((f) => f.goalId).toList(),
      ));
    }

    // CELEBRATE_WIN (P3) — coasting with progress>=1.0
    final wins = fs
        .where((f) =>
            f.verdict == GoalDeadlineVerdict.coasting &&
            _progressOf(f) >= 1.0)
        .toList();
    if (wins.isNotEmpty) {
      out.add(PlaybookAction(
        id: 'celebrate_win',
        priority: DeadlineRiskPriority.p3,
        label: 'CELEBRATE_WIN',
        reason:
            '${wins.length} goal(s) are complete. Acknowledge the win and either close or extend them.',
        owner: 'self',
        blastRadius: 1,
        reversibility: 'high',
        relatedGoalIds: wins.map((f) => f.goalId).toList(),
      ));
    }

    // HEALTHY_PORTFOLIO (P3 fallback)
    if (out.isEmpty) {
      out.add(PlaybookAction(
        id: 'healthy_portfolio',
        priority: DeadlineRiskPriority.p3,
        label: 'HEALTHY_PORTFOLIO',
        reason: 'No goals require intervention right now.',
        owner: 'self',
        blastRadius: 1,
        reversibility: 'high',
        relatedGoalIds: const [],
      ));
    }

    // Cautious appendix.
    if (options.riskAppetite == DeadlineRiskAppetite.cautious &&
        (grade == 'C' || grade == 'D' || grade == 'F')) {
      out.add(PlaybookAction(
        id: 'schedule_portfolio_review',
        priority: DeadlineRiskPriority.p2,
        label: 'SCHEDULE_PORTFOLIO_REVIEW',
        reason:
            'Cautious appetite + grade $grade — schedule a 30-min review to re-prioritise.',
        owner: 'self',
        blastRadius: 1,
        reversibility: 'high',
        relatedGoalIds: const [],
      ));
    }

    // Aggressive trim: drop p3 + any lone p2 when p0/p1 present.
    var trimmed = out;
    if (options.riskAppetite == DeadlineRiskAppetite.aggressive) {
      final hasP0orP1 = trimmed.any((a) =>
          a.priority == DeadlineRiskPriority.p0 ||
          a.priority == DeadlineRiskPriority.p1);
      if (hasP0orP1) {
        final p2 = trimmed
            .where((a) => a.priority == DeadlineRiskPriority.p2)
            .toList();
        if (p2.length <= 1) {
          trimmed = trimmed
              .where((a) => a.priority != DeadlineRiskPriority.p2)
              .toList();
        }
        trimmed = trimmed
            .where((a) => a.priority != DeadlineRiskPriority.p3)
            .toList();
      } else {
        // even with nothing serious, trim p3
        trimmed = trimmed
            .where((a) => a.priority != DeadlineRiskPriority.p3)
            .toList();
        if (trimmed.isEmpty) trimmed = out; // keep fallback
      }
    }

    // Stable sort: priority asc, then id asc.
    trimmed.sort((a, b) {
      final cmp = a.priority.index.compareTo(b.priority.index);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

    return trimmed;
  }

  /// `progress` is not surfaced on the forecast; we infer "done" from the
  /// computed required-units-per-week being zero (which only happens when
  /// `unitsDoneSoFar >= targetUnits`).
  double _progressOf(GoalDeadlineForecast f) {
    if (f.verdict == GoalDeadlineVerdict.missed) return 0.0;
    if (f.verdict == GoalDeadlineVerdict.coasting &&
        f.requiredUnitsPerWeek <= 1e-9) {
      return 1.0;
    }
    return 0.5;
  }
}
