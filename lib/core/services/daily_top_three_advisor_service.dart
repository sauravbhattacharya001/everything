/// Daily Top Three Advisor - agentic synthesizer for "what should I actually
/// do today?".
///
/// Sibling to GoalPortfolioOptimizerService (weekly trade-offs),
/// HabitMomentumService (streaks), and EnergyBudgetPlannerService (calendar
/// load). Where those operate on a single dimension, this advisor crosses
/// goals + habits + energy + chronotype into a single ranked shortlist that
/// answers:
///
///   "Out of everything I *could* do today, which 1-3 things would actually
///    make today not feel wasted, and what is the smallest concrete first step
///    on each?"
///
/// Inputs are platform-agnostic value objects ([CandidateAction] +
/// [DailyContext]). No Flutter / persistence dependency — same service powers
/// widgets, headless briefings, and unit tests.
///
/// Pipeline:
///   1. Score each candidate 0..100 from importance/urgency/goal alignment/
///      keystone-habit rescue/energy fit/chronotype fit/location/deadline/
///      enjoyment, modulated by [DailyRiskAppetite].
///   2. Greedy knapsack pack picks under `availableMinutes`; anchors are
///      always retained first.
///   3. Verdict ladder SHIP_TODAY / PROTECT_TIME / PILOT / BACKUP for picks;
///      DEFER / DROP for unpicked.
///   4. Per-pick first step + suggested start hour.
///   5. Portfolio P0-P3 playbook + A-F grade + autonomous insights.
///
/// Deterministic — no [Random] usage; stable sort by (score desc, id asc).
library;

import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum CandidateCategory {
  deepWork,
  admin,
  exercise,
  social,
  learning,
  errand,
  rest,
  habit,
  goal,
  inbox,
  other,
}

enum CandidateContext { any, home, office, outdoors }

enum DailyRiskAppetite { cautious, balanced, aggressive }

enum DailyPriority { p0, p1, p2, p3 }

enum DailyVerdict {
  shipToday,
  protectTime,
  pilot,
  backup,
  defer,
  drop,
}

enum DailyBand { underUsed, balanced, tight, overloaded }

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

class CandidateAction {
  final String id;
  final String title;
  final CandidateCategory category;
  final int estimateMinutes;
  final int importance; // 1..5
  final int urgency; // 1..5
  final String? tiedToGoalId;
  final String? tiedToHabitId;
  final DateTime? deadline;
  final bool isAnchor;
  final CandidateContext context;
  final int enjoyment; // 1..5

  const CandidateAction({
    required this.id,
    required this.title,
    required this.category,
    required this.estimateMinutes,
    this.importance = 3,
    this.urgency = 3,
    this.tiedToGoalId,
    this.tiedToHabitId,
    this.deadline,
    this.isAnchor = false,
    this.context = CandidateContext.any,
    this.enjoyment = 3,
  });
}

class DailyContext {
  final int availableMinutes;
  final double energyState; // 0..1
  final int moodScore; // 1..5
  final int chronotypePeakHour;
  final int currentHour;
  final CandidateContext location;
  final List<String> keystoneHabitsAtRisk;
  final List<String> topGoalIds;

  const DailyContext({
    this.availableMinutes = 240,
    this.energyState = 0.6,
    this.moodScore = 3,
    this.chronotypePeakHour = 10,
    this.currentHour = 9,
    this.location = CandidateContext.any,
    this.keystoneHabitsAtRisk = const [],
    this.topGoalIds = const [],
  });
}

class DailyAdvisorOptions {
  final DailyRiskAppetite riskAppetite;
  final int maxPicks;
  final int minPicks;
  final DateTime Function()? now;

  const DailyAdvisorOptions({
    this.riskAppetite = DailyRiskAppetite.balanced,
    this.maxPicks = 3,
    this.minPicks = 1,
    this.now,
  });
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

class DailyPick {
  final String actionId;
  final String title;
  final CandidateCategory category;
  final double score; // 0..100
  final DailyPriority priority;
  final DailyVerdict verdict;
  final List<String> reasons;
  final String firstStep;
  final int estimateMinutes;
  final int suggestedStartHour;

  const DailyPick({
    required this.actionId,
    required this.title,
    required this.category,
    required this.score,
    required this.priority,
    required this.verdict,
    required this.reasons,
    required this.firstStep,
    required this.estimateMinutes,
    required this.suggestedStartHour,
  });
}

class PlaybookAction {
  final DailyPriority priority;
  final String code;
  final String headline;
  final String detail;
  final String owner; // always 'user'
  final int blastRadius; // 1..3
  final String reversibility; // low|medium|high
  final List<String> actionIds;

  const PlaybookAction({
    required this.priority,
    required this.code,
    required this.headline,
    required this.detail,
    this.owner = 'user',
    this.blastRadius = 1,
    this.reversibility = 'high',
    this.actionIds = const [],
  });
}

class DailyAdvisorReport {
  final List<DailyPick> picks;
  final List<DailyPick> unpicked;
  final double dayLoadScore; // 0..120
  final DailyBand band;
  final String grade; // A..F
  final List<PlaybookAction> playbook;
  final List<String> insights;
  final String headline;
  final DateTime generatedAt;

  const DailyAdvisorReport({
    required this.picks,
    required this.unpicked,
    required this.dayLoadScore,
    required this.band,
    required this.grade,
    required this.playbook,
    required this.insights,
    required this.headline,
    required this.generatedAt,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class DailyTopThreeAdvisorService {
  DailyTopThreeAdvisorService();

  DailyAdvisorReport recommend(
    Iterable<CandidateAction> actions,
    DailyContext context, [
    DailyAdvisorOptions options = const DailyAdvisorOptions(),
  ]) {
    final now = (options.now ?? DateTime.now)();
    final mult = switch (options.riskAppetite) {
      DailyRiskAppetite.cautious => 0.92,
      DailyRiskAppetite.balanced => 1.0,
      DailyRiskAppetite.aggressive => 1.10,
    };

    // 1. Score every candidate.
    final scored = <_Scored>[];
    for (final a in actions) {
      final raw = _scoreCandidate(a, context, now);
      final adjusted = (raw * mult).clamp(0.0, 100.0).toDouble();
      scored.add(_Scored(a, adjusted, _reasonsFor(a, context, now)));
    }
    // Stable sort: score desc, id asc.
    scored.sort((x, y) {
      final c = y.score.compareTo(x.score);
      if (c != 0) return c;
      return x.action.id.compareTo(y.action.id);
    });

    // 2. Greedy knapsack with anchors-first.
    final maxPicks = options.maxPicks.clamp(1, 5);
    final pickedActions = <_Scored>[];
    var minutesUsed = 0;

    // Anchors first (in score order).
    for (final s in scored) {
      if (!s.action.isAnchor) continue;
      if (pickedActions.length >= maxPicks) break;
      pickedActions.add(s);
      minutesUsed += s.action.estimateMinutes;
    }
    // Then highest-score non-anchors that fit budget.
    for (final s in scored) {
      if (s.action.isAnchor) continue;
      if (pickedActions.length >= maxPicks) break;
      if (minutesUsed + s.action.estimateMinutes > context.availableMinutes &&
          pickedActions.isNotEmpty) {
        continue;
      }
      pickedActions.add(s);
      minutesUsed += s.action.estimateMinutes;
    }

    final pickedIds = pickedActions.map((p) => p.action.id).toSet();

    // 3. Build pick + unpicked rows.
    final picks = <DailyPick>[];
    var hourCursor = math.max(context.currentHour, 0);
    for (final s in pickedActions) {
      final pick = _buildPick(s, context, hourCursor, picked: true);
      picks.add(pick);
      hourCursor = math.min(
        23,
        pick.suggestedStartHour + (s.action.estimateMinutes / 60).ceil(),
      );
    }

    final unpicked = <DailyPick>[];
    for (final s in scored) {
      if (pickedIds.contains(s.action.id)) continue;
      unpicked.add(_buildPick(s, context, context.currentHour, picked: false));
    }

    // 4. Day load + band.
    final totalMin = picks.fold<int>(0, (acc, p) => acc + p.estimateMinutes);
    final available = math.max(1, context.availableMinutes);
    final dayLoad = (totalMin / available * 100).clamp(0.0, 120.0).toDouble();
    final band = _bandFromLoad(dayLoad);

    // 5. Insights + grade + playbook + headline.
    final insights = _buildInsights(picks, context);
    final grade = _grade(picks, band, context);
    final playbook = _buildPlaybook(picks, unpicked, band, context, now);
    final headline = _buildHeadline(picks, grade);

    return DailyAdvisorReport(
      picks: picks,
      unpicked: unpicked,
      dayLoadScore: dayLoad,
      band: band,
      grade: grade,
      playbook: playbook,
      insights: insights,
      headline: headline,
      generatedAt: now,
    );
  }

  // -------------------------------------------------------------------------
  // Formatters
  // -------------------------------------------------------------------------

  String formatText(DailyAdvisorReport r) {
    final b = StringBuffer();
    b.writeln(r.headline);
    b.writeln(
      'Day load ${r.dayLoadScore.toStringAsFixed(0)}/100  '
      'band=${_bandLabel(r.band)}  grade=${r.grade}',
    );
    if (r.picks.isEmpty) {
      b.writeln('No picks for today.');
    } else {
      b.writeln('Picks:');
      for (final p in r.picks) {
        b.writeln(
          '  [${_priorityLabel(p.priority)}] ${p.title} '
          '(${p.estimateMinutes}m @ ${p.suggestedStartHour}:00) '
          '${_verdictLabel(p.verdict)} - ${p.firstStep}',
        );
      }
    }
    if (r.unpicked.isNotEmpty) {
      b.writeln('Skipped:');
      for (final p in r.unpicked) {
        b.writeln(
          '  [${_priorityLabel(p.priority)}] ${p.title} '
          '${_verdictLabel(p.verdict)} (score ${p.score.toStringAsFixed(0)})',
        );
      }
    }
    if (r.playbook.isNotEmpty) {
      b.writeln('Playbook:');
      for (final a in r.playbook) {
        b.writeln('  [${_priorityLabel(a.priority)}] ${a.code} - ${a.headline}');
      }
    }
    if (r.insights.isNotEmpty) {
      b.writeln('Insights: ${r.insights.join(', ')}');
    }
    return b.toString();
  }

  String formatMarkdown(DailyAdvisorReport r) {
    final b = StringBuffer();
    b.writeln('## Headline');
    b.writeln(r.headline);
    b.writeln();
    b.writeln(
      'Day load **${r.dayLoadScore.toStringAsFixed(0)}/100** | '
      'band **${_bandLabel(r.band)}** | grade **${r.grade}**',
    );
    b.writeln();
    b.writeln('## Picks');
    if (r.picks.isEmpty) {
      b.writeln('_No picks selected._');
    } else {
      b.writeln('| Priority | Title | Verdict | Score | Minutes | Start | First step |');
      b.writeln('| --- | --- | --- | --- | --- | --- | --- |');
      for (final p in r.picks) {
        b.writeln(
          '| ${_priorityLabel(p.priority)} | ${p.title} | '
          '${_verdictLabel(p.verdict)} | ${p.score.toStringAsFixed(0)} | '
          '${p.estimateMinutes} | ${p.suggestedStartHour}:00 | ${p.firstStep} |',
        );
      }
    }
    b.writeln();
    b.writeln('## Skipped');
    if (r.unpicked.isEmpty) {
      b.writeln('_Nothing skipped._');
    } else {
      b.writeln('| Priority | Title | Verdict | Score |');
      b.writeln('| --- | --- | --- | --- |');
      for (final p in r.unpicked) {
        b.writeln(
          '| ${_priorityLabel(p.priority)} | ${p.title} | '
          '${_verdictLabel(p.verdict)} | ${p.score.toStringAsFixed(0)} |',
        );
      }
    }
    b.writeln();
    b.writeln('## Playbook');
    if (r.playbook.isEmpty) {
      b.writeln('_No actions._');
    } else {
      b.writeln('| Priority | Code | Headline | Detail |');
      b.writeln('| --- | --- | --- | --- |');
      for (final a in r.playbook) {
        b.writeln(
          '| ${_priorityLabel(a.priority)} | ${a.code} | ${a.headline} | ${a.detail} |',
        );
      }
    }
    b.writeln();
    b.writeln('## Insights');
    if (r.insights.isEmpty) {
      b.writeln('_None._');
    } else {
      for (final i in r.insights) {
        b.writeln('- $i');
      }
    }
    return b.toString();
  }

  // -------------------------------------------------------------------------
  // Internal: scoring
  // -------------------------------------------------------------------------

  double _scoreCandidate(
    CandidateAction a,
    DailyContext ctx,
    DateTime now,
  ) {
    final importance = a.importance.clamp(1, 5);
    final urgency = a.urgency.clamp(1, 5);
    final enjoyment = a.enjoyment.clamp(1, 5);

    final goalAlignment =
        (a.tiedToGoalId != null && ctx.topGoalIds.contains(a.tiedToGoalId))
            ? 1.0
            : 0.0;
    final habitRescue = (a.tiedToHabitId != null &&
            ctx.keystoneHabitsAtRisk.contains(a.tiedToHabitId))
        ? 1.0
        : 0.0;

    final energy = ctx.energyState.clamp(0.0, 1.0);
    double energyFit;
    switch (a.category) {
      case CandidateCategory.deepWork:
      case CandidateCategory.learning:
        energyFit = energy >= 0.6 ? 1.0 : (energy >= 0.4 ? 0.5 : 0.2);
        break;
      case CandidateCategory.rest:
        energyFit = energy < 0.4 ? 1.0 : (energy < 0.6 ? 0.6 : 0.3);
        break;
      case CandidateCategory.exercise:
        energyFit = (energy >= 0.4 && energy <= 0.8) ? 0.7 : 0.4;
        break;
      case CandidateCategory.admin:
      case CandidateCategory.errand:
      case CandidateCategory.inbox:
        energyFit = 0.6;
        break;
      default:
        energyFit = 0.5;
    }

    double chronoFit;
    if (a.category == CandidateCategory.deepWork) {
      final delta = (ctx.currentHour - ctx.chronotypePeakHour).abs();
      chronoFit = math.max(0.0, 1.0 - delta / 8.0);
    } else {
      chronoFit = 0.5;
    }

    final locationFit = (ctx.location == CandidateContext.any ||
            a.context == CandidateContext.any ||
            a.context == ctx.location)
        ? 1.0
        : 0.0;

    double deadlineBoost = 0.0;
    if (a.deadline != null) {
      final hoursToDeadline = a.deadline!.difference(now).inHours;
      if (hoursToDeadline <= 24 && hoursToDeadline >= -24) {
        deadlineBoost = 15.0;
      } else if (hoursToDeadline <= 72) {
        deadlineBoost = 8.0;
      }
    }

    final enjoymentBonus = (enjoyment - 3) * 2.0;

    return importance * 8.0 +
        urgency * 7.0 +
        goalAlignment * 15.0 +
        habitRescue * 15.0 +
        energyFit * 10.0 +
        chronoFit * 8.0 +
        locationFit * 5.0 +
        deadlineBoost +
        enjoymentBonus;
  }

  List<String> _reasonsFor(
    CandidateAction a,
    DailyContext ctx,
    DateTime now,
  ) {
    final out = <String>[];
    if (a.importance >= 4) out.add('HIGH_IMPORTANCE');
    if (a.urgency >= 4) out.add('HIGH_URGENCY');
    if (a.tiedToGoalId != null && ctx.topGoalIds.contains(a.tiedToGoalId)) {
      out.add('ALIGNS_TOP_GOAL');
    }
    if (a.tiedToHabitId != null &&
        ctx.keystoneHabitsAtRisk.contains(a.tiedToHabitId)) {
      out.add('KEYSTONE_HABIT_AT_RISK');
    }
    if (a.category == CandidateCategory.deepWork && ctx.energyState >= 0.6) {
      out.add('ENERGY_FIT');
    }
    if (a.category == CandidateCategory.rest && ctx.energyState < 0.4) {
      out.add('LOW_ENERGY_RECOVERY');
    }
    if (a.category == CandidateCategory.deepWork &&
        (ctx.currentHour - ctx.chronotypePeakHour).abs() <= 2) {
      out.add('CHRONO_PEAK');
    }
    if (a.deadline != null) {
      final hours = a.deadline!.difference(now).inHours;
      if (hours <= 24 && hours >= -24) out.add('DEADLINE_TODAY');
      else if (hours <= 72) out.add('DEADLINE_SOON');
    }
    if (a.isAnchor) out.add('ANCHOR_COMMITMENT');
    if (a.enjoyment >= 4) out.add('HIGH_ENJOYMENT');
    if (out.isEmpty) out.add('BASELINE_CANDIDATE');
    return out;
  }

  DailyPriority _priorityFromScore(double s) {
    if (s >= 75) return DailyPriority.p0;
    if (s >= 55) return DailyPriority.p1;
    if (s >= 35) return DailyPriority.p2;
    return DailyPriority.p3;
  }

  DailyPick _buildPick(
    _Scored s,
    DailyContext ctx,
    int startHour, {
    required bool picked,
  }) {
    final priority = _priorityFromScore(s.score);
    DailyVerdict verdict;
    if (picked) {
      if (s.action.isAnchor) {
        verdict = DailyVerdict.protectTime;
      } else if (s.score >= 75) {
        verdict = DailyVerdict.shipToday;
      } else if (s.score >= 55) {
        verdict = DailyVerdict.pilot;
      } else {
        verdict = DailyVerdict.backup;
      }
    } else {
      verdict = s.score < 20 ? DailyVerdict.drop : DailyVerdict.defer;
    }

    // Suggested start hour: deep work near peak if possible.
    var suggested = startHour;
    if (picked &&
        s.action.category == CandidateCategory.deepWork &&
        ctx.chronotypePeakHour >= startHour) {
      suggested = ctx.chronotypePeakHour;
    }
    suggested = suggested.clamp(0, 23);

    return DailyPick(
      actionId: s.action.id,
      title: s.action.title,
      category: s.action.category,
      score: s.score,
      priority: priority,
      verdict: verdict,
      reasons: List.unmodifiable(s.reasons),
      firstStep: _firstStepFor(s.action),
      estimateMinutes: s.action.estimateMinutes,
      suggestedStartHour: suggested,
    );
  }

  String _firstStepFor(CandidateAction a) {
    switch (a.category) {
      case CandidateCategory.deepWork:
        return 'Open the doc and write 1 sentence.';
      case CandidateCategory.admin:
        return 'List the next 3 sub-tasks on paper.';
      case CandidateCategory.exercise:
        return 'Put on the shoes and step outside.';
      case CandidateCategory.social:
        return 'Send the first message now.';
      case CandidateCategory.learning:
        return 'Read one paragraph or watch 2 minutes.';
      case CandidateCategory.errand:
        return 'Grab keys and head to the door.';
      case CandidateCategory.rest:
        return 'Set a 10-minute timer and unplug.';
      case CandidateCategory.habit:
        return 'Do the smallest version of the habit now.';
      case CandidateCategory.goal:
        return 'Do the smallest concrete step toward the goal.';
      case CandidateCategory.inbox:
        return 'Process the top 3 messages only.';
      case CandidateCategory.other:
        return 'Take the first 2-minute action.';
    }
  }

  // -------------------------------------------------------------------------
  // Internal: portfolio
  // -------------------------------------------------------------------------

  DailyBand _bandFromLoad(double load) {
    if (load < 35) return DailyBand.underUsed;
    if (load < 90) return DailyBand.balanced;
    if (load <= 100) return DailyBand.tight;
    return DailyBand.overloaded;
  }

  String _grade(
    List<DailyPick> picks,
    DailyBand band,
    DailyContext ctx,
  ) {
    if (picks.isEmpty) return 'F';
    if (picks.every((p) => p.verdict == DailyVerdict.drop)) return 'F';
    final hasShip = picks.any((p) => p.verdict == DailyVerdict.shipToday);
    final hasTopGoalShip = picks.any(
      (p) =>
          p.verdict == DailyVerdict.shipToday &&
          (p.reasons.contains('ALIGNS_TOP_GOAL') ||
              p.reasons.contains('KEYSTONE_HABIT_AT_RISK')),
    );
    switch (band) {
      case DailyBand.balanced:
        if (hasShip && hasTopGoalShip) return 'A';
        return 'B';
      case DailyBand.underUsed:
      case DailyBand.tight:
        return 'C';
      case DailyBand.overloaded:
        return 'D';
    }
  }

  List<PlaybookAction> _buildPlaybook(
    List<DailyPick> picks,
    List<DailyPick> unpicked,
    DailyBand band,
    DailyContext ctx,
    DateTime now,
  ) {
    final out = <PlaybookAction>[];
    final shipped =
        picks.where((p) => p.verdict == DailyVerdict.shipToday).toList();
    if (shipped.isNotEmpty) {
      out.add(PlaybookAction(
        priority: DailyPriority.p0,
        code: 'PROTECT_TOP_PICK_TIME',
        headline: 'Block calendar time for the top pick',
        detail:
            'Defend ${shipped.first.title} from meetings/interruptions today.',
        blastRadius: 2,
        reversibility: 'high',
        actionIds: shipped.map((p) => p.actionId).toList(),
      ));
    }
    final rescueIds = picks
        .where((p) => p.reasons.contains('KEYSTONE_HABIT_AT_RISK'))
        .map((p) => p.actionId)
        .toList();
    if (rescueIds.isNotEmpty) {
      out.add(PlaybookAction(
        priority: DailyPriority.p0,
        code: 'RESCUE_KEYSTONE_HABIT',
        headline: 'Save a keystone habit before the streak breaks',
        detail: 'Do the minimum-viable version today to preserve momentum.',
        blastRadius: 2,
        reversibility: 'high',
        actionIds: rescueIds,
      ));
    }
    final shallowPicks = picks
        .where((p) =>
            p.category == CandidateCategory.admin ||
            p.category == CandidateCategory.errand)
        .toList();
    if (shallowPicks.length >= 3) {
      out.add(PlaybookAction(
        priority: DailyPriority.p1,
        code: 'BATCH_SHALLOW',
        headline: 'Batch shallow work into a single block',
        detail: 'Group admin/errands to protect focus elsewhere.',
        blastRadius: 1,
        reversibility: 'high',
        actionIds: shallowPicks.map((p) => p.actionId).toList(),
      ));
    }
    final offPeakDeep = picks
        .where((p) =>
            p.category == CandidateCategory.deepWork &&
            (p.suggestedStartHour - ctx.chronotypePeakHour).abs() >= 3)
        .toList();
    if (offPeakDeep.isNotEmpty) {
      out.add(PlaybookAction(
        priority: DailyPriority.p1,
        code: 'MOVE_DEEP_WORK_TO_PEAK',
        headline: 'Move deep work to your chronotype peak',
        detail:
            'Your peak hour is ${ctx.chronotypePeakHour}:00; consider shifting.',
        blastRadius: 2,
        reversibility: 'high',
        actionIds: offPeakDeep.map((p) => p.actionId).toList(),
      ));
    }
    final deadlineDefers = unpicked.where((p) {
      // We don't carry the deadline on DailyPick directly; use reasons.
      return p.verdict == DailyVerdict.defer &&
          (p.reasons.contains('DEADLINE_TODAY') ||
              p.reasons.contains('DEADLINE_SOON'));
    }).toList();
    if (deadlineDefers.length >= 2) {
      out.add(PlaybookAction(
        priority: DailyPriority.p2,
        code: 'NEGOTIATE_DEADLINES',
        headline: 'Renegotiate deadlines you cannot keep today',
        detail: 'Send a quick note before end of day.',
        blastRadius: 2,
        reversibility: 'medium',
        actionIds: deadlineDefers.map((p) => p.actionId).toList(),
      ));
    }
    if (band == DailyBand.overloaded) {
      out.add(PlaybookAction(
        priority: DailyPriority.p2,
        code: 'REDUCE_SCOPE',
        headline: 'Cut scope - day is overloaded',
        detail: 'Drop the lowest-priority pick or shorten the longest one.',
        blastRadius: 2,
        reversibility: 'high',
        actionIds: picks.map((p) => p.actionId).toList(),
      ));
    }
    if (picks.isNotEmpty &&
        picks.every((p) => p.reasons.contains('HIGH_ENJOYMENT'))) {
      out.add(const PlaybookAction(
        priority: DailyPriority.p3,
        code: 'ENJOY_DAY',
        headline: 'Lean into a high-enjoyment day',
        detail: 'Skip optimisation; today is for restoration and joy.',
        blastRadius: 1,
        reversibility: 'high',
      ));
    }
    return out;
  }

  List<String> _buildInsights(List<DailyPick> picks, DailyContext ctx) {
    final out = <String>[];
    if (ctx.energyState < 0.4) out.add('LOW_ENERGY_TODAY');
    if (picks.isNotEmpty &&
        !picks.any((p) => p.reasons.contains('ALIGNS_TOP_GOAL'))) {
      out.add('NO_TOP_GOAL_ALIGNMENT');
    }
    if (picks.any((p) => p.reasons.contains('KEYSTONE_HABIT_AT_RISK'))) {
      out.add('KEYSTONE_RESCUE_AVAILABLE');
    }
    final deep =
        picks.where((p) => p.category == CandidateCategory.deepWork).length;
    if (deep >= 2) out.add('BACK_TO_BACK_DEEP_WORK');
    final pressureCount = picks
        .where((p) =>
            p.reasons.contains('DEADLINE_TODAY') ||
            p.reasons.contains('DEADLINE_SOON'))
        .length;
    if (pressureCount >= 2) out.add('DEADLINE_PRESSURE');
    if (picks.isNotEmpty &&
        picks.where((p) => p.category == CandidateCategory.rest).length /
                picks.length >=
            0.5) {
      out.add('MOSTLY_REST_DAY');
    }
    return out;
  }

  String _buildHeadline(List<DailyPick> picks, String grade) {
    if (picks.isEmpty) return 'NO_PICKS: nothing actionable today (grade $grade)';
    final top = picks.first;
    return '${_verdictLabel(top.verdict)}: ${top.title} - ${top.estimateMinutes}m (grade $grade)';
  }

  // -------------------------------------------------------------------------
  // Labels
  // -------------------------------------------------------------------------

  String _priorityLabel(DailyPriority p) => switch (p) {
        DailyPriority.p0 => 'P0',
        DailyPriority.p1 => 'P1',
        DailyPriority.p2 => 'P2',
        DailyPriority.p3 => 'P3',
      };

  String _verdictLabel(DailyVerdict v) => switch (v) {
        DailyVerdict.shipToday => 'SHIP_TODAY',
        DailyVerdict.protectTime => 'PROTECT_TIME',
        DailyVerdict.pilot => 'PILOT',
        DailyVerdict.backup => 'BACKUP',
        DailyVerdict.defer => 'DEFER',
        DailyVerdict.drop => 'DROP',
      };

  String _bandLabel(DailyBand b) => switch (b) {
        DailyBand.underUsed => 'UNDER_USED',
        DailyBand.balanced => 'BALANCED',
        DailyBand.tight => 'TIGHT',
        DailyBand.overloaded => 'OVERLOADED',
      };
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _Scored {
  final CandidateAction action;
  final double score;
  final List<String> reasons;
  _Scored(this.action, this.score, this.reasons);
}
