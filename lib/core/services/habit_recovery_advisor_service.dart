/// Habit Recovery Advisor - agentic per-habit recovery planner for **broken
/// or lapsed** habits in a portfolio.
///
/// Sibling to:
///   * `habit_momentum_service.dart`            (active streak momentum)
///   * `streak_guardian_service.dart`           (defensive: protect alive streaks)
///   * `habit_correlation_engine_service.dart`  (cross-habit correlations)
///   * `goal_checkin_cadence_advisor_service.dart` (goal review discipline)
///   * `daily_top_three_advisor_service.dart`   (today shortlist)
///
/// Where those focus on goals, today, or *still-alive* habits, this advisor
/// is the after-action review for habits whose streaks have *already broken*
/// (or that are about to silently collapse) and answers a different question:
///
///   "These habits stopped working. For each one, what should I do next:
///    resume tomorrow, scale it down, restructure it, pause it, or drop it
///    entirely — and in what order should I tackle the portfolio?"
///
/// Pipeline:
///   1. For every habit, compute streak liveness using `lastCompletionAt`,
///      `expectedFrequencyPerWeek`, completion history over the lookback
///      window, and `pausedAt`/`abandonedAt`.
///   2. Classify into one of [HabitRecoveryVerdict]:
///      RESUME_TOMORROW / SCALE_DOWN / RESTRUCTURE / PAUSE_INTENTIONALLY /
///      DROP_AND_ARCHIVE / KEEP_ACTIVE_NO_ACTION / NEW_HABIT_PROBATION.
///   3. Score per-habit `recoveryDifficulty` 0..100 (length of lapse, prior
///      streak, completion ratio, attempts) modulated by risk appetite.
///   4. Aggregate portfolio: lapsed-ratio, weighted-lapsed-ratio (priority),
///      `portfolioRecoveryScore`, band + A-F grade + headline + insights.
///   5. Emit a deduped P0-first playbook of [RecoveryAction] items
///      (priority, owner, blastRadius, reversibility).
///   6. Render via `toText` / `toMarkdown` / `toJson` (deterministic).
///
/// Pure Dart, zero new dependencies. Deterministic - no `Random` usage. All
/// "now" reads go through `options.now ?? DateTime.now`. Stable sorts.
library;

import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum RecoveryRiskAppetite { cautious, balanced, aggressive }

enum RecoveryPriority { p0, p1, p2, p3 }

enum HabitRecoveryVerdict {
  resumeTomorrow,
  scaleDown,
  restructure,
  pauseIntentionally,
  dropAndArchive,
  keepActiveNoAction,
  newHabitProbation,
}

enum RecoveryPortfolioBand { healthy, watch, atRisk, critical }

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

class HabitRecoverySnapshot {
  final String id;
  final String title;
  final String category;
  final int priorityWeight; // 1..5 (5 = highest)
  final DateTime createdAt;
  final DateTime? lastCompletionAt;

  /// Expected completions per 7 days when the habit is healthy. e.g. 7 = daily.
  final double expectedFrequencyPerWeek;

  /// Count of *completions* observed within the lookback window (default 28d).
  final int completionsInWindow;

  /// Longest streak ever achieved for this habit (in completions, not days).
  final int longestStreak;

  /// Current consecutive completion streak (0 if broken).
  final int currentStreak;

  /// How many times this habit has been restarted (broken and resumed).
  final int restartCount;

  /// Set when the user has explicitly paused (deload week, vacation, injury).
  final DateTime? pausedAt;

  /// Set when the user has explicitly abandoned the habit.
  final DateTime? abandonedAt;

  /// Optional freeform note - surfaced in `currentStatus` rendering only.
  final String currentStatus;

  const HabitRecoverySnapshot({
    required this.id,
    required this.title,
    required this.category,
    required this.priorityWeight,
    required this.createdAt,
    this.lastCompletionAt,
    required this.expectedFrequencyPerWeek,
    required this.completionsInWindow,
    this.longestStreak = 0,
    this.currentStreak = 0,
    this.restartCount = 0,
    this.pausedAt,
    this.abandonedAt,
    this.currentStatus = '',
  });
}

class RecoveryOptions {
  final RecoveryRiskAppetite riskAppetite;
  final int lookbackDays;
  final DateTime Function()? now;

  const RecoveryOptions({
    this.riskAppetite = RecoveryRiskAppetite.balanced,
    this.lookbackDays = 28,
    this.now,
  });
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

class HabitRecoveryForecast {
  final String id;
  final String title;
  final String category;
  final int priorityWeight;
  final HabitRecoveryVerdict verdict;
  final int? daysSinceCompletion;
  final double completionRatio; // observed / expected over lookback
  final double recoveryDifficulty; // 0..100
  final String suggestedAction;
  final List<String> reasons;

  const HabitRecoveryForecast({
    required this.id,
    required this.title,
    required this.category,
    required this.priorityWeight,
    required this.verdict,
    required this.daysSinceCompletion,
    required this.completionRatio,
    required this.recoveryDifficulty,
    required this.suggestedAction,
    required this.reasons,
  });

  Map<String, dynamic> toJsonMap() => {
        'id': id,
        'title': title,
        'category': category,
        'priority_weight': priorityWeight,
        'verdict': _verdictName(verdict),
        'days_since_completion': daysSinceCompletion,
        'completion_ratio': double.parse(completionRatio.toStringAsFixed(3)),
        'recovery_difficulty':
            double.parse(recoveryDifficulty.toStringAsFixed(2)),
        'suggested_action': suggestedAction,
        'reasons': reasons,
      };
}

class RecoveryAction {
  final RecoveryPriority priority;
  final String label;
  final String reason;
  final String owner;
  final int blastRadius; // 1..5
  final String reversibility; // 'low' | 'medium' | 'high'
  final List<String> relatedIds;

  const RecoveryAction({
    required this.priority,
    required this.label,
    required this.reason,
    required this.owner,
    required this.blastRadius,
    required this.reversibility,
    this.relatedIds = const [],
  });

  Map<String, dynamic> toJsonMap() => {
        'priority': _priorityName(priority),
        'label': label,
        'reason': reason,
        'owner': owner,
        'blast_radius': blastRadius,
        'reversibility': reversibility,
        'related_ids': relatedIds,
      };
}

class HabitRecoveryReport {
  final DateTime generatedAt;
  final RecoveryRiskAppetite riskAppetite;
  final int totalHabits;
  final int lapsedCount;
  final double lapsedRatio;
  final double weightedLapsedRatio;
  final double portfolioRecoveryScore; // 0..100 (higher = worse)
  final RecoveryPortfolioBand band;
  final String grade;
  final String headline;
  final List<HabitRecoveryForecast> forecasts;
  final List<RecoveryAction> playbook;
  final List<String> insights;

  const HabitRecoveryReport({
    required this.generatedAt,
    required this.riskAppetite,
    required this.totalHabits,
    required this.lapsedCount,
    required this.lapsedRatio,
    required this.weightedLapsedRatio,
    required this.portfolioRecoveryScore,
    required this.band,
    required this.grade,
    required this.headline,
    required this.forecasts,
    required this.playbook,
    required this.insights,
  });

  Map<String, dynamic> toJsonMap() => {
        'generated_at': generatedAt.toUtc().toIso8601String(),
        'risk_appetite': _appetiteName(riskAppetite),
        'total_habits': totalHabits,
        'lapsed_count': lapsedCount,
        'lapsed_ratio': double.parse(lapsedRatio.toStringAsFixed(3)),
        'weighted_lapsed_ratio':
            double.parse(weightedLapsedRatio.toStringAsFixed(3)),
        'portfolio_recovery_score':
            double.parse(portfolioRecoveryScore.toStringAsFixed(2)),
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

class HabitRecoveryAdvisorService {
  HabitRecoveryReport advise(
    List<HabitRecoverySnapshot> snapshots, {
    RecoveryOptions options = const RecoveryOptions(),
  }) {
    final now = (options.now ?? DateTime.now)();
    final lookback = options.lookbackDays.clamp(7, 365);
    final forecasts = <HabitRecoveryForecast>[];

    for (final s in snapshots) {
      forecasts.add(_classify(s, now, lookback, options.riskAppetite));
    }

    // Stable sort: difficulty desc, then id asc.
    forecasts.sort((a, b) {
      final c = b.recoveryDifficulty.compareTo(a.recoveryDifficulty);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });

    final lapsedVerdicts = <HabitRecoveryVerdict>{
      HabitRecoveryVerdict.resumeTomorrow,
      HabitRecoveryVerdict.scaleDown,
      HabitRecoveryVerdict.restructure,
      HabitRecoveryVerdict.dropAndArchive,
    };
    final lapsed = forecasts.where((f) => lapsedVerdicts.contains(f.verdict)).toList();
    final totalHabits = forecasts.length;
    final lapsedCount = lapsed.length;
    final lapsedRatio = totalHabits == 0 ? 0.0 : lapsedCount / totalHabits;

    final priorityWeightSum = forecasts.fold<int>(
        0, (acc, f) => acc + math.max(1, f.priorityWeight));
    final lapsedWeightedSum = lapsed.fold<int>(
        0, (acc, f) => acc + math.max(1, f.priorityWeight));
    final weightedLapsedRatio =
        priorityWeightSum == 0 ? 0.0 : lapsedWeightedSum / priorityWeightSum;

    // Portfolio score (higher = worse): blends weighted lapse ratio with mean
    // recovery difficulty among lapsed habits.
    final meanLapsedDifficulty = lapsed.isEmpty
        ? 0.0
        : lapsed.map((f) => f.recoveryDifficulty).reduce((a, b) => a + b) /
            lapsed.length;
    final rawScore =
        100.0 * weightedLapsedRatio * 0.6 + meanLapsedDifficulty * 0.4;
    final appetiteShift = switch (options.riskAppetite) {
      RecoveryRiskAppetite.cautious => 8.0,
      RecoveryRiskAppetite.balanced => 0.0,
      RecoveryRiskAppetite.aggressive => -8.0,
    };
    final portfolioScore = (rawScore + appetiteShift).clamp(0.0, 100.0);

    final band = _bandFor(portfolioScore);
    final grade = _gradeFor(portfolioScore, lapsed);
    final headline = _buildHeadline(
        totalHabits, lapsedCount, weightedLapsedRatio, band, options.riskAppetite);
    final insights = _buildInsights(forecasts, lapsed, weightedLapsedRatio);
    final playbook =
        _buildPlaybook(forecasts, lapsed, options.riskAppetite, grade);

    return HabitRecoveryReport(
      generatedAt: now,
      riskAppetite: options.riskAppetite,
      totalHabits: totalHabits,
      lapsedCount: lapsedCount,
      lapsedRatio: lapsedRatio,
      weightedLapsedRatio: weightedLapsedRatio,
      portfolioRecoveryScore: portfolioScore,
      band: band,
      grade: grade,
      headline: headline,
      forecasts: forecasts,
      playbook: playbook,
      insights: insights,
    );
  }

  // -------------------------------------------------------------------------
  // Per-habit classification
  // -------------------------------------------------------------------------

  HabitRecoveryForecast _classify(
    HabitRecoverySnapshot s,
    DateTime now,
    int lookbackDays,
    RecoveryRiskAppetite appetite,
  ) {
    final reasons = <String>[];
    final daysSince = s.lastCompletionAt == null
        ? null
        : _dayDiff(now, s.lastCompletionAt!);
    final ageDays = _dayDiff(now, s.createdAt);
    final expectedInWindow =
        (s.expectedFrequencyPerWeek * (lookbackDays / 7.0)).clamp(0.001, 1e9);
    final completionRatio =
        (s.completionsInWindow / expectedInWindow).clamp(0.0, 5.0);

    // Cadence threshold for "broken" - 3x the expected gap, floor 4 days.
    final expectedGapDays = s.expectedFrequencyPerWeek <= 0
        ? lookbackDays.toDouble()
        : 7.0 / s.expectedFrequencyPerWeek;
    final brokenThresholdDays =
        math.max(4.0, expectedGapDays * 3.0).round();

    HabitRecoveryVerdict verdict;
    String suggested;

    if (s.abandonedAt != null) {
      verdict = HabitRecoveryVerdict.dropAndArchive;
      reasons.add('ABANDONED_BY_USER');
      suggested = 'Archive this habit; capture the lesson before removing.';
    } else if (s.pausedAt != null) {
      verdict = HabitRecoveryVerdict.pauseIntentionally;
      reasons.add('PAUSED_BY_USER');
      suggested = 'Intentionally paused - set a resume date so it does not drift.';
    } else if (s.lastCompletionAt == null) {
      if (ageDays <= 7) {
        verdict = HabitRecoveryVerdict.newHabitProbation;
        reasons.add('NEW_HABIT_NO_COMPLETIONS');
        suggested =
            'New habit on probation - log the first completion in the next 48h.';
      } else {
        verdict = HabitRecoveryVerdict.dropAndArchive;
        reasons.add('NEVER_COMPLETED_OLDER_THAN_A_WEEK');
        suggested =
            'Never completed and older than a week - archive or restructure into something smaller.';
      }
    } else if (daysSince != null && daysSince <= brokenThresholdDays ~/ 2) {
      verdict = HabitRecoveryVerdict.keepActiveNoAction;
      reasons.add('RECENT_COMPLETION');
      suggested = 'Habit is active - no recovery action needed.';
    } else {
      // It is lapsed in some form. Choose between the recovery verdicts.
      if (daysSince != null && daysSince <= brokenThresholdDays) {
        verdict = HabitRecoveryVerdict.resumeTomorrow;
        reasons.add('FRESH_LAPSE_WITHIN_GRACE');
        suggested =
            'Just lapsed - resume tomorrow with the same target before momentum fades.';
      } else if (s.restartCount >= 3 && completionRatio < 0.4) {
        verdict = HabitRecoveryVerdict.restructure;
        reasons.add('CHRONIC_RESTARTS');
        suggested =
            'This is the ${s.restartCount + 1}th attempt - restructure: change time, trigger, or scope.';
      } else if (completionRatio >= 0.35 && completionRatio < 0.7) {
        verdict = HabitRecoveryVerdict.scaleDown;
        reasons.add('PARTIAL_ADHERENCE');
        suggested =
            'Partial adherence - scale the target down (e.g. 7x/wk -> 3x/wk) so completion becomes automatic again.';
      } else if (completionRatio < 0.35 && s.longestStreak < 7) {
        verdict = HabitRecoveryVerdict.dropAndArchive;
        reasons.add('LOW_ADHERENCE_NEVER_STUCK');
        suggested =
            'Never really stuck - archive it and reclaim attention for higher-priority habits.';
      } else if (daysSince != null && daysSince > brokenThresholdDays * 3) {
        verdict = HabitRecoveryVerdict.restructure;
        reasons.add('LONG_LAPSE');
        suggested =
            'Long lapse ($daysSince days) - restructure or schedule an explicit relaunch session.';
      } else {
        verdict = HabitRecoveryVerdict.resumeTomorrow;
        reasons.add('LAPSED_RECOVERABLE');
        suggested = 'Resume tomorrow with a one-rep minimum to rebuild streak.';
      }
    }

    // Annotation reasons (additive, not classification-driving).
    if (s.priorityWeight >= 4 &&
        verdict != HabitRecoveryVerdict.keepActiveNoAction &&
        verdict != HabitRecoveryVerdict.pauseIntentionally) {
      reasons.add('HIGH_PRIORITY_HABIT');
    }
    if (s.longestStreak >= 21) reasons.add('PREVIOUSLY_STRONG_STREAK');
    if (s.restartCount >= 2) reasons.add('REPEAT_RESTART');
    if (completionRatio >= 1.0 && verdict == HabitRecoveryVerdict.keepActiveNoAction) {
      reasons.add('ON_TARGET');
    }

    // Recovery difficulty 0..100 - blends lapse length, restarts, completion
    // ratio, prior streak. Always set even for active habits (small value).
    final difficulty = _recoveryDifficulty(
      verdict: verdict,
      daysSince: daysSince,
      expectedGapDays: expectedGapDays,
      restartCount: s.restartCount,
      completionRatio: completionRatio,
      longestStreak: s.longestStreak,
      priorityWeight: s.priorityWeight,
      appetite: appetite,
    );

    return HabitRecoveryForecast(
      id: s.id,
      title: s.title,
      category: s.category,
      priorityWeight: s.priorityWeight,
      verdict: verdict,
      daysSinceCompletion: daysSince,
      completionRatio: completionRatio,
      recoveryDifficulty: difficulty,
      suggestedAction: suggested,
      reasons: reasons,
    );
  }

  double _recoveryDifficulty({
    required HabitRecoveryVerdict verdict,
    required int? daysSince,
    required double expectedGapDays,
    required int restartCount,
    required double completionRatio,
    required int longestStreak,
    required int priorityWeight,
    required RecoveryRiskAppetite appetite,
  }) {
    if (verdict == HabitRecoveryVerdict.keepActiveNoAction) return 5.0;
    if (verdict == HabitRecoveryVerdict.pauseIntentionally) return 15.0;
    if (verdict == HabitRecoveryVerdict.newHabitProbation) return 25.0;

    double base;
    switch (verdict) {
      case HabitRecoveryVerdict.resumeTomorrow:
        base = 25.0;
        break;
      case HabitRecoveryVerdict.scaleDown:
        base = 45.0;
        break;
      case HabitRecoveryVerdict.restructure:
        base = 65.0;
        break;
      case HabitRecoveryVerdict.dropAndArchive:
        base = 30.0;
        break;
      default:
        base = 20.0;
    }

    // Lapse pressure (capped).
    if (daysSince != null && expectedGapDays > 0) {
      final lapseFactor = (daysSince / expectedGapDays).clamp(0.0, 6.0);
      base += lapseFactor * 4.0; // up to +24
    }
    // Restart history makes recovery harder.
    base += math.min(restartCount, 5) * 3.0; // up to +15
    // Low adherence makes it harder.
    if (completionRatio < 0.5) base += (0.5 - completionRatio) * 20.0; // up to +10
    // High priority dominates portfolio attention -> mark as harder to ignore.
    if (priorityWeight >= 4) base += 4.0;
    // Strong prior streak is *easier* to recover (muscle memory).
    if (longestStreak >= 14) base -= 6.0;

    // Risk appetite modulates final value.
    final mult = switch (appetite) {
      RecoveryRiskAppetite.cautious => 1.10,
      RecoveryRiskAppetite.balanced => 1.0,
      RecoveryRiskAppetite.aggressive => 0.90,
    };
    return (base * mult).clamp(0.0, 100.0);
  }

  // -------------------------------------------------------------------------
  // Portfolio aggregates
  // -------------------------------------------------------------------------

  RecoveryPortfolioBand _bandFor(double score) {
    if (score >= 70) return RecoveryPortfolioBand.critical;
    if (score >= 50) return RecoveryPortfolioBand.atRisk;
    if (score >= 30) return RecoveryPortfolioBand.watch;
    return RecoveryPortfolioBand.healthy;
  }

  String _gradeFor(double score, List<HabitRecoveryForecast> lapsed) {
    final highPriRestructure = lapsed.where((f) =>
        f.priorityWeight >= 4 &&
        f.verdict == HabitRecoveryVerdict.restructure).length;
    if (highPriRestructure >= 2 || score >= 75) return 'F';
    if (score >= 55) return 'D';
    if (score >= 40) return 'C';
    if (score >= 20) return 'B';
    return 'A';
  }

  String _buildHeadline(
    int total,
    int lapsedCount,
    double weightedRatio,
    RecoveryPortfolioBand band,
    RecoveryRiskAppetite appetite,
  ) {
    if (total == 0) return 'No habits to advise on.';
    final pct = (weightedRatio * 100).round();
    return 'band=${_bandName(band)} '
        '$lapsedCount/$total habits lapsed (weighted $pct%) - '
        'appetite=${_appetiteName(appetite)}.';
  }

  List<String> _buildInsights(
    List<HabitRecoveryForecast> all,
    List<HabitRecoveryForecast> lapsed,
    double weightedRatio,
  ) {
    final out = <String>[];
    if (all.isEmpty) return out;

    final highPriLapsed =
        lapsed.where((f) => f.priorityWeight >= 4).toList();
    if (highPriLapsed.length >= 2) {
      out.add(
          'HIGH_PRIORITY_LAPSE_CLUSTER: ${highPriLapsed.length} high-priority habits are lapsed.');
    }

    final chronic = lapsed
        .where((f) => f.reasons.contains('CHRONIC_RESTARTS'))
        .toList();
    if (chronic.length >= 2) {
      out.add(
          'CHRONIC_RESTART_PATTERN: ${chronic.length} habits show repeated failed restarts - restructure rather than retry.');
    }

    final byCategory = <String, int>{};
    for (final f in lapsed) {
      byCategory.update(f.category, (v) => v + 1, ifAbsent: () => 1);
    }
    String? dominantCat;
    var dominantCount = 0;
    byCategory.forEach((k, v) {
      if (v > dominantCount) {
        dominantCat = k;
        dominantCount = v;
      }
    });
    if (dominantCat != null && dominantCount >= 3) {
      out.add(
          'CATEGORY_HOTSPOT: $dominantCount lapsed habits in "$dominantCat" - look for an environmental root cause.');
    }

    if (weightedRatio >= 0.5) {
      out.add(
          'PORTFOLIO_OVERLOAD: more than half (weighted) of habits are lapsed - cut scope before relaunching.');
    }

    final restructureNeeded = lapsed
        .where((f) => f.verdict == HabitRecoveryVerdict.restructure)
        .length;
    if (restructureNeeded >= 3) {
      out.add(
          'RESTRUCTURE_BACKLOG: $restructureNeeded habits need a redesign session.');
    }

    if (lapsed.isEmpty && all.length >= 3) {
      out.add('HEALTHY_PORTFOLIO: no habits currently need recovery action.');
    }

    return out;
  }

  // -------------------------------------------------------------------------
  // Playbook
  // -------------------------------------------------------------------------

  List<RecoveryAction> _buildPlaybook(
    List<HabitRecoveryForecast> all,
    List<HabitRecoveryForecast> lapsed,
    RecoveryRiskAppetite appetite,
    String grade,
  ) {
    final actions = <RecoveryAction>[];

    // P0: high-priority restructure (most expensive cognitive task, do first).
    final highPriRestructure = lapsed
        .where((f) =>
            f.priorityWeight >= 4 &&
            f.verdict == HabitRecoveryVerdict.restructure)
        .toList();
    if (highPriRestructure.isNotEmpty) {
      actions.add(RecoveryAction(
        priority: RecoveryPriority.p0,
        label: 'Schedule restructure session for high-priority habits',
        reason:
            '${highPriRestructure.length} high-priority habits keep breaking - block 30 min to redesign trigger/scope.',
        owner: 'self',
        blastRadius: 3,
        reversibility: 'medium',
        relatedIds: highPriRestructure.map((f) => f.id).toList()..sort(),
      ));
    }

    // P0: drop never-stuck habits to reclaim attention.
    final dropCandidates = lapsed
        .where((f) => f.verdict == HabitRecoveryVerdict.dropAndArchive)
        .toList();
    if (dropCandidates.length >= 2) {
      actions.add(RecoveryAction(
        priority: RecoveryPriority.p0,
        label: 'Archive habits you never stuck with',
        reason:
            '${dropCandidates.length} habits are dragging attention without delivering - archive them today.',
        owner: 'self',
        blastRadius: 2,
        reversibility: 'high',
        relatedIds: dropCandidates.map((f) => f.id).toList()..sort(),
      ));
    }

    // P1: resume the fresh lapses tomorrow (cheap wins).
    final resumeNow = lapsed
        .where((f) => f.verdict == HabitRecoveryVerdict.resumeTomorrow)
        .toList();
    if (resumeNow.isNotEmpty) {
      actions.add(RecoveryAction(
        priority: RecoveryPriority.p1,
        label: 'Resume fresh lapses tomorrow',
        reason:
            '${resumeNow.length} habits lapsed recently - one-rep minimum tomorrow to rebuild streak.',
        owner: 'self',
        blastRadius: 1,
        reversibility: 'high',
        relatedIds: resumeNow.map((f) => f.id).toList()..sort(),
      ));
    }

    // P1: scale-downs.
    final scaleDowns = lapsed
        .where((f) => f.verdict == HabitRecoveryVerdict.scaleDown)
        .toList();
    if (scaleDowns.isNotEmpty) {
      actions.add(RecoveryAction(
        priority: RecoveryPriority.p1,
        label: 'Scale down partial-adherence habits',
        reason:
            '${scaleDowns.length} habits show partial adherence - reduce the target so completion becomes automatic.',
        owner: 'self',
        blastRadius: 2,
        reversibility: 'high',
        relatedIds: scaleDowns.map((f) => f.id).toList()..sort(),
      ));
    }

    // P2: paused habits need a resume date.
    final paused = all
        .where((f) => f.verdict == HabitRecoveryVerdict.pauseIntentionally)
        .toList();
    if (paused.length >= 2) {
      actions.add(RecoveryAction(
        priority: RecoveryPriority.p2,
        label: 'Set explicit resume dates for paused habits',
        reason:
            '${paused.length} habits are paused - assign a resume date so they do not silently drift.',
        owner: 'self',
        blastRadius: 1,
        reversibility: 'high',
        relatedIds: paused.map((f) => f.id).toList()..sort(),
      ));
    }

    // P2: new-habit probation - confirm first reps land.
    final probation = all
        .where((f) => f.verdict == HabitRecoveryVerdict.newHabitProbation)
        .toList();
    if (probation.isNotEmpty) {
      actions.add(RecoveryAction(
        priority: RecoveryPriority.p2,
        label: 'Lock in first reps for new habits',
        reason:
            '${probation.length} new habits have not logged their first completion yet.',
        owner: 'self',
        blastRadius: 1,
        reversibility: 'high',
        relatedIds: probation.map((f) => f.id).toList()..sort(),
      ));
    }

    // Cautious adds a portfolio review when grade C/D/F.
    if (appetite == RecoveryRiskAppetite.cautious &&
        (grade == 'C' || grade == 'D' || grade == 'F')) {
      actions.add(const RecoveryAction(
        priority: RecoveryPriority.p2,
        label: 'Book a weekly habit-portfolio review',
        reason:
            'Cautious appetite + degraded grade - schedule a 15 min weekly recovery review.',
        owner: 'self',
        blastRadius: 1,
        reversibility: 'high',
      ));
    }

    // P3 fallback when no other action exists.
    if (actions.isEmpty) {
      actions.add(const RecoveryAction(
        priority: RecoveryPriority.p3,
        label: 'No habit recovery action needed',
        reason: 'Portfolio is healthy - keep current cadence.',
        owner: 'self',
        blastRadius: 1,
        reversibility: 'high',
      ));
    }

    // Aggressive trims lone P3 fallback when other actions exist (it wont
    // exist), and trims lone P2s when P0/P1 are present.
    if (appetite == RecoveryRiskAppetite.aggressive) {
      final hasP0OrP1 = actions.any((a) =>
          a.priority == RecoveryPriority.p0 ||
          a.priority == RecoveryPriority.p1);
      if (hasP0OrP1) {
        actions.removeWhere((a) =>
            a.priority == RecoveryPriority.p2 &&
            !a.label.toLowerCase().contains('paused'));
      }
    }

    // Stable sort: priority asc, then label asc.
    actions.sort((a, b) {
      final c = a.priority.index.compareTo(b.priority.index);
      if (c != 0) return c;
      return a.label.compareTo(b.label);
    });

    return actions;
  }

  // -------------------------------------------------------------------------
  // Renderers
  // -------------------------------------------------------------------------

  String toText(HabitRecoveryReport r) {
    final sb = StringBuffer();
    sb.writeln('Habit Recovery Report');
    sb.writeln('======================');
    sb.writeln(r.headline);
    sb.writeln('Grade: ${r.grade}  Score: '
        '${r.portfolioRecoveryScore.toStringAsFixed(0)}/100  '
        'Band: ${_bandName(r.band)}');
    sb.writeln('Generated: ${r.generatedAt.toUtc().toIso8601String()}');
    sb.writeln('');
    sb.writeln('Insights:');
    if (r.insights.isEmpty) {
      sb.writeln('  (none)');
    } else {
      for (final i in r.insights) {
        sb.writeln('  - $i');
      }
    }
    sb.writeln('');
    sb.writeln('Forecasts:');
    if (r.forecasts.isEmpty) {
      sb.writeln('  (none)');
    } else {
      for (final f in r.forecasts) {
        final ds = f.daysSinceCompletion == null
            ? 'never'
            : '${f.daysSinceCompletion}d';
        sb.writeln('  [${_verdictName(f.verdict).toUpperCase()}] '
            '${f.title} (id=${f.id}, p=${f.priorityWeight}) - '
            'since=$ds, ratio=${f.completionRatio.toStringAsFixed(2)}, '
            'difficulty=${f.recoveryDifficulty.toStringAsFixed(0)} '
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
            '${a.label} - ${a.reason} '
            '(owner=${a.owner}, blast=${a.blastRadius}, rev=${a.reversibility})');
      }
    }
    return sb.toString();
  }

  String toMarkdown(HabitRecoveryReport r) {
    final sb = StringBuffer();
    sb.writeln('# Habit Recovery Report');
    sb.writeln('');
    sb.writeln('**${r.headline}**');
    sb.writeln('');
    sb.writeln('- Grade: **${r.grade}**');
    sb.writeln('- Score: ${r.portfolioRecoveryScore.toStringAsFixed(0)}/100');
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
      sb.writeln('_(no habits)_');
    } else {
      sb.writeln(
          '| Habit | Priority | Verdict | Since | Ratio | Difficulty |');
      sb.writeln('| --- | --- | --- | --- | --- | --- |');
      for (final f in r.forecasts) {
        final ds = f.daysSinceCompletion == null
            ? 'never'
            : '${f.daysSinceCompletion}d';
        sb.writeln('| ${f.title} (${f.id}) | ${f.priorityWeight} | '
            '${_verdictName(f.verdict)} | $ds | '
            '${f.completionRatio.toStringAsFixed(2)} | '
            '${f.recoveryDifficulty.toStringAsFixed(0)} |');
      }
    }
    sb.writeln('');
    sb.writeln('## Playbook');
    if (r.playbook.isEmpty) {
      sb.writeln('_(no actions)_');
    } else {
      sb.writeln(
          '| Priority | Action | Reason | Owner | Blast | Reversibility |');
      sb.writeln('| --- | --- | --- | --- | --- | --- |');
      for (final a in r.playbook) {
        sb.writeln('| ${_priorityName(a.priority)} | ${a.label} | '
            '${a.reason} | ${a.owner} | ${a.blastRadius} | ${a.reversibility} |');
      }
    }
    return sb.toString();
  }

  String toJson(HabitRecoveryReport r) => _jsonEncodeMap(r.toJsonMap());
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

int _dayDiff(DateTime a, DateTime b) {
  final ad = DateTime(a.year, a.month, a.day);
  final bd = DateTime(b.year, b.month, b.day);
  return ad.difference(bd).inDays;
}

String _verdictName(HabitRecoveryVerdict v) => switch (v) {
      HabitRecoveryVerdict.resumeTomorrow => 'resume_tomorrow',
      HabitRecoveryVerdict.scaleDown => 'scale_down',
      HabitRecoveryVerdict.restructure => 'restructure',
      HabitRecoveryVerdict.pauseIntentionally => 'pause_intentionally',
      HabitRecoveryVerdict.dropAndArchive => 'drop_and_archive',
      HabitRecoveryVerdict.keepActiveNoAction => 'keep_active_no_action',
      HabitRecoveryVerdict.newHabitProbation => 'new_habit_probation',
    };

String _priorityName(RecoveryPriority p) => switch (p) {
      RecoveryPriority.p0 => 'P0',
      RecoveryPriority.p1 => 'P1',
      RecoveryPriority.p2 => 'P2',
      RecoveryPriority.p3 => 'P3',
    };

String _bandName(RecoveryPortfolioBand b) => switch (b) {
      RecoveryPortfolioBand.healthy => 'healthy',
      RecoveryPortfolioBand.watch => 'watch',
      RecoveryPortfolioBand.atRisk => 'at_risk',
      RecoveryPortfolioBand.critical => 'critical',
    };

String _appetiteName(RecoveryRiskAppetite a) => switch (a) {
      RecoveryRiskAppetite.cautious => 'cautious',
      RecoveryRiskAppetite.balanced => 'balanced',
      RecoveryRiskAppetite.aggressive => 'aggressive',
    };

/// Minimal deterministic JSON encoder so the service stays dependency-free.
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
    if (v is double && (v.isNaN || v.isInfinite)) {
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
