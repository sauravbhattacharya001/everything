/// Habit Momentum Service - agentic cross-habit streak/risk advisor.
///
/// While individual trackers (water, exercise, meditation, sleep, journaling…)
/// each show their own streak, real users juggle many habits at once. When
/// one slips, others often follow within days. This service answers:
///
///   "Across all my habits this week, which streaks are about to break, what
///    is the smallest action I can take *today* to save the most-at-risk one,
///    and is the overall pattern improving or collapsing?"
///
/// Inputs are platform-agnostic [HabitDailyRecord]s (one per habit per day,
/// boolean done + optional intensity 0..1). No Flutter or persistence
/// dependency, so the same service powers widgets, headless cron summaries,
/// and unit tests.
///
/// Pipeline:
///   1. Aggregate per-habit windows over the trailing `windowDays` (default 28).
///   2. Score breakage risk 0..100 from:
///        - drift     (last-7d consistency vs prior-7d)
///        - recency   (consecutive recent misses)
///        - buffer    (missable days left to hit the weekly target)
///        - cadence   (weekday-pattern misses for habits with regular schedule)
///        - intensity (recent average intensity slip vs baseline)
///      Weighted, modulated by [HabitRiskAppetite].
///   3. Verdict: ON_TRACK / MOMENTUM_RISING / AT_RISK / BREAKING / BROKEN.
///   4. Per-habit micro-intervention (smallest action that preserves streak).
///   5. Portfolio P0/P1/P2 playbook + A-F grade + autonomous insights
///      (e.g. cluster_at_risk, keystone_in_danger, cross-habit fatigue,
///      rising-momentum suggests raising target).
///
/// Sibling to [GoalPortfolioOptimizerService] (goals/weekly trade-off) but
/// operates on the higher-frequency *habit* layer.
library;

import 'dart:math' as math;

/// A single per-habit per-day observation.
class HabitDailyRecord {
  final String habitId;
  final DateTime date;
  final bool done;

  /// Optional 0..1 effort indicator (e.g. minutes_meditated / target_minutes).
  /// When null, treated as 1.0 if [done] else 0.0.
  final double? intensity;

  const HabitDailyRecord({
    required this.habitId,
    required this.date,
    required this.done,
    this.intensity,
  });
}

/// Static configuration about a habit (target cadence, importance).
class HabitProfile {
  final String habitId;
  final String displayName;

  /// 1..7 — how many days per week the user committed to.
  final int weeklyTarget;

  /// If true, missing 1 day flips to BROKEN immediately
  /// (e.g. medication adherence). Defaults false.
  final bool zeroToleranceStreak;

  /// Keystone habits (sleep, exercise) get an importance multiplier in
  /// portfolio risk + playbook prioritisation.
  final bool isKeystone;

  /// Optional category for grouping insights (health/mind/finance/work/social).
  final String category;

  const HabitProfile({
    required this.habitId,
    required this.displayName,
    this.weeklyTarget = 7,
    this.zeroToleranceStreak = false,
    this.isKeystone = false,
    this.category = 'general',
  });
}

/// Knob to tighten/loosen risk thresholds across the portfolio.
enum HabitRiskAppetite { cautious, balanced, aggressive }

/// Per-habit overall verdict.
enum HabitVerdict {
  onTrack,
  momentumRising,
  atRisk,
  breaking,
  broken,
}

/// Playbook priority bucket.
enum HabitPlaybookPriority { p0, p1, p2 }

/// Smallest action the user can take to preserve a habit's streak.
class HabitMicroIntervention {
  final String action;
  final String reason;
  final int estimatedMinutes;
  final bool dueToday;

  const HabitMicroIntervention({
    required this.action,
    required this.reason,
    required this.estimatedMinutes,
    required this.dueToday,
  });
}

/// Per-habit analysis result.
class HabitMomentumReport {
  final String habitId;
  final String displayName;
  final HabitVerdict verdict;
  final int currentStreak;
  final int longestStreak;

  /// 0..1 — completion rate over the last 7 days.
  final double weekConsistency;

  /// 0..1 — completion rate over the prior 7 days (week-2).
  final double priorWeekConsistency;

  /// 0..100 — composite breakage risk.
  final double riskScore;

  /// Number of misses in the trailing 3 days.
  final int recentMisses;

  /// Days remaining this week without breaking weekly target.
  final int bufferDaysLeft;

  /// Component scores summed (with weights) into [riskScore].
  final Map<String, double> scoreBreakdown;

  /// Human-readable rationale fragments.
  final List<String> reasons;

  /// Smallest action that meaningfully reduces risk.
  final HabitMicroIntervention? intervention;

  const HabitMomentumReport({
    required this.habitId,
    required this.displayName,
    required this.verdict,
    required this.currentStreak,
    required this.longestStreak,
    required this.weekConsistency,
    required this.priorWeekConsistency,
    required this.riskScore,
    required this.recentMisses,
    required this.bufferDaysLeft,
    required this.scoreBreakdown,
    required this.reasons,
    required this.intervention,
  });
}

/// A single portfolio-level recommendation.
class HabitPlaybookAction {
  final HabitPlaybookPriority priority;
  final String code;
  final String headline;
  final String detail;
  final List<String> habitIds;

  const HabitPlaybookAction({
    required this.priority,
    required this.code,
    required this.headline,
    required this.detail,
    required this.habitIds,
  });
}

/// Aggregate result returned to UI / cron.
class HabitPortfolioReport {
  final DateTime generatedAt;
  final List<HabitMomentumReport> habits;
  final List<HabitPlaybookAction> playbook;

  /// 0..100 averaged across all habits (lower is better).
  final double portfolioRisk;

  /// A..F overall health grade.
  final String grade;

  /// Free-form one-liners surfacing cross-habit observations.
  final List<String> insights;

  const HabitPortfolioReport({
    required this.generatedAt,
    required this.habits,
    required this.playbook,
    required this.portfolioRisk,
    required this.grade,
    required this.insights,
  });

  /// Render as plain text suitable for terminals / Telegram.
  String formatText() {
    final b = StringBuffer();
    b.writeln('Habit Momentum Report  (risk ${portfolioRisk.toStringAsFixed(1)}/100, grade $grade)');
    b.writeln('Generated: ${generatedAt.toIso8601String()}');
    if (insights.isNotEmpty) {
      b.writeln('\nInsights:');
      for (final i in insights) {
        b.writeln('  • $i');
      }
    }
    b.writeln('\nHabits:');
    for (final h in habits) {
      b.writeln(
        '  [${_verdictTag(h.verdict)}] ${h.displayName} '
        '— streak ${h.currentStreak}d, week ${(h.weekConsistency * 100).round()}%, '
        'risk ${h.riskScore.toStringAsFixed(0)}/100',
      );
      if (h.intervention != null) {
        b.writeln('       → ${h.intervention!.action} '
            '(~${h.intervention!.estimatedMinutes}m, '
            '${h.intervention!.dueToday ? "today" : "this week"})');
      }
    }
    if (playbook.isNotEmpty) {
      b.writeln('\nPlaybook:');
      for (final a in playbook) {
        b.writeln('  [${_priTag(a.priority)}] ${a.headline}');
        b.writeln('       ${a.detail}');
      }
    }
    return b.toString();
  }

  /// Render as Markdown.
  String formatMarkdown() {
    final b = StringBuffer();
    b.writeln('# Habit Momentum Report');
    b.writeln('');
    b.writeln('- **Portfolio risk:** ${portfolioRisk.toStringAsFixed(1)} / 100');
    b.writeln('- **Grade:** $grade');
    b.writeln('- **Generated:** ${generatedAt.toIso8601String()}');
    if (insights.isNotEmpty) {
      b.writeln('\n## Insights');
      for (final i in insights) {
        b.writeln('- $i');
      }
    }
    b.writeln('\n## Habits');
    b.writeln('| Habit | Verdict | Streak | Week | Risk | Next action |');
    b.writeln('|---|---|---:|---:|---:|---|');
    for (final h in habits) {
      final action = h.intervention == null
          ? '—'
          : '${h.intervention!.action} (~${h.intervention!.estimatedMinutes}m)';
      b.writeln('| ${h.displayName} | ${_verdictTag(h.verdict)} | '
          '${h.currentStreak}d | ${(h.weekConsistency * 100).round()}% | '
          '${h.riskScore.toStringAsFixed(0)} | $action |');
    }
    if (playbook.isNotEmpty) {
      b.writeln('\n## Playbook');
      for (final a in playbook) {
        b.writeln('- **[${_priTag(a.priority)}] ${a.headline}** — ${a.detail}');
      }
    }
    return b.toString();
  }

  static String _verdictTag(HabitVerdict v) {
    switch (v) {
      case HabitVerdict.onTrack:
        return 'ON_TRACK';
      case HabitVerdict.momentumRising:
        return 'RISING';
      case HabitVerdict.atRisk:
        return 'AT_RISK';
      case HabitVerdict.breaking:
        return 'BREAKING';
      case HabitVerdict.broken:
        return 'BROKEN';
    }
  }

  static String _priTag(HabitPlaybookPriority p) {
    switch (p) {
      case HabitPlaybookPriority.p0:
        return 'P0';
      case HabitPlaybookPriority.p1:
        return 'P1';
      case HabitPlaybookPriority.p2:
        return 'P2';
    }
  }
}

/// Service entry point. Stateless — safe to instantiate per call.
class HabitMomentumService {
  final DateTime Function() _now;
  final int windowDays;
  final HabitRiskAppetite riskAppetite;

  HabitMomentumService({
    DateTime Function()? now,
    this.windowDays = 28,
    this.riskAppetite = HabitRiskAppetite.balanced,
  }) : _now = now ?? DateTime.now;

  /// Analyze [records] against [profiles] and return a portfolio report.
  HabitPortfolioReport analyze({
    required List<HabitProfile> profiles,
    required List<HabitDailyRecord> records,
  }) {
    final today = _dateOnly(_now());
    final byHabit = <String, List<HabitDailyRecord>>{};
    for (final r in records) {
      byHabit.putIfAbsent(r.habitId, () => []).add(r);
    }

    final reports = <HabitMomentumReport>[];
    for (final p in profiles) {
      final rs = byHabit[p.habitId] ?? const <HabitDailyRecord>[];
      reports.add(_analyzeOne(p, rs, today));
    }

    final playbook = _buildPlaybook(reports, profiles);
    final risk = reports.isEmpty
        ? 0.0
        : reports.map((r) => r.riskScore).reduce((a, b) => a + b) /
            reports.length;
    final grade = _grade(risk, reports);
    final insights = _insights(reports, profiles);

    return HabitPortfolioReport(
      generatedAt: _now(),
      habits: reports,
      playbook: playbook,
      portfolioRisk: risk,
      grade: grade,
      insights: insights,
    );
  }

  HabitMomentumReport _analyzeOne(
    HabitProfile profile,
    List<HabitDailyRecord> records,
    DateTime today,
  ) {
    // Sorted oldest -> newest, dedup by date keeping the most "done" record.
    final byDate = <DateTime, HabitDailyRecord>{};
    for (final r in records) {
      final d = _dateOnly(r.date);
      final existing = byDate[d];
      if (existing == null || (r.done && !existing.done)) {
        byDate[d] = r;
      }
    }
    final daily = List<HabitDailyRecord>.from(byDate.values)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Current streak: walk back from today while done==true (or yesterday).
    int currentStreak = 0;
    for (int i = 0; i < windowDays; i++) {
      final day = today.subtract(Duration(days: i));
      final r = byDate[day];
      if (r != null && r.done) {
        currentStreak++;
      } else if (i == 0) {
        // Today not yet logged — peek yesterday-based streak instead of zeroing.
        continue;
      } else {
        break;
      }
    }

    // Longest streak in window.
    int longest = 0;
    int run = 0;
    for (int i = windowDays - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final r = byDate[day];
      if (r != null && r.done) {
        run++;
        longest = math.max(longest, run);
      } else {
        run = 0;
      }
    }

    final week = _consistency(byDate, today, 0, 7);
    final prior = _consistency(byDate, today, 7, 7);

    // Recent misses in last 3 days (excluding today if not logged).
    int recentMisses = 0;
    for (int i = 1; i <= 3; i++) {
      final day = today.subtract(Duration(days: i));
      final r = byDate[day];
      if (r == null || !r.done) recentMisses++;
    }

    // Buffer days: how many more this week can be skipped before
    // weekly target is unreachable. Week starts Monday.
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    int doneThisWeek = 0;
    int daysElapsed = 0;
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (!day.isAfter(today)) {
        daysElapsed++;
        final r = byDate[day];
        if (r != null && r.done) doneThisWeek++;
      }
    }
    final daysRemaining = 7 - daysElapsed;
    final stillNeeded =
        math.max(0, profile.weeklyTarget - doneThisWeek);
    final bufferDaysLeft = daysRemaining - stillNeeded;

    // ---- score components 0..100 each ----
    // drift: prior-week vs week (drop is bad).
    final drop = (prior - week).clamp(-1.0, 1.0);
    final driftScore = drop > 0 ? drop * 100 : 0.0;

    // recency: 3-day window miss density.
    final recencyScore = (recentMisses / 3.0) * 100.0;

    // buffer: negative buffer (already infeasible) caps high.
    final bufferScore = bufferDaysLeft < 0
        ? 100.0
        : (bufferDaysLeft == 0
            ? 60.0
            : (bufferDaysLeft == 1 ? 30.0 : 0.0));

    // cadence: only meaningful for sub-daily targets — count weekday misses.
    final cadenceScore = _cadenceScore(byDate, today, profile);

    // intensity: trailing 14d avg intensity vs prior 14d avg.
    final intensityScore = _intensityScore(byDate, today);

    // weights (sum to ~1.0).
    var w = <String, double>{
      'drift': 0.30,
      'recency': 0.30,
      'buffer': 0.20,
      'cadence': 0.10,
      'intensity': 0.10,
    };
    final raw = w['drift']! * driftScore +
        w['recency']! * recencyScore +
        w['buffer']! * bufferScore +
        w['cadence']! * cadenceScore +
        w['intensity']! * intensityScore;

    // risk appetite modulation
    final modulator = switch (riskAppetite) {
      HabitRiskAppetite.cautious => 1.15,
      HabitRiskAppetite.balanced => 1.0,
      HabitRiskAppetite.aggressive => 0.85,
    };
    final keystoneBump = profile.isKeystone ? 1.10 : 1.0;
    final score = (raw * modulator * keystoneBump).clamp(0.0, 100.0);

    final todayRec = byDate[today];
    final todayMissed = todayRec != null && !todayRec.done;

    // verdict
    HabitVerdict verdict;
    if (profile.zeroToleranceStreak && todayMissed) {
      verdict = HabitVerdict.broken;
    } else if (profile.zeroToleranceStreak && recentMisses >= 1 && currentStreak == 0) {
      verdict = HabitVerdict.broken;
    } else if (currentStreak == 0 && week < 0.20) {
      verdict = HabitVerdict.broken;
    } else if (score >= 70 || recentMisses >= 3) {
      verdict = HabitVerdict.breaking;
    } else if (score >= 40 || bufferDaysLeft < 0) {
      verdict = HabitVerdict.atRisk;
    } else if (week > prior && week >= 0.85) {
      verdict = HabitVerdict.momentumRising;
    } else {
      verdict = HabitVerdict.onTrack;
    }

    final reasons = <String>[];
    if (drop > 0.1) {
      reasons.add(
          'consistency dropped ${(drop * 100).round()}% vs last week');
    }
    if (recentMisses >= 2) {
      reasons.add('$recentMisses of the last 3 days missed');
    }
    if (bufferDaysLeft < 0) {
      reasons.add('weekly target already unreachable');
    } else if (bufferDaysLeft == 0) {
      reasons.add('no buffer days remaining this week');
    }
    if (profile.isKeystone && verdict != HabitVerdict.onTrack) {
      reasons.add('keystone habit — downstream impact on other habits');
    }
    if (verdict == HabitVerdict.momentumRising) {
      reasons.add('week-over-week improvement — consider raising target');
    }

    final intervention = _intervention(profile, verdict, today, byDate);

    return HabitMomentumReport(
      habitId: profile.habitId,
      displayName: profile.displayName,
      verdict: verdict,
      currentStreak: currentStreak,
      longestStreak: longest,
      weekConsistency: week,
      priorWeekConsistency: prior,
      riskScore: double.parse(score.toStringAsFixed(2)),
      recentMisses: recentMisses,
      bufferDaysLeft: bufferDaysLeft,
      scoreBreakdown: {
        'drift': double.parse(driftScore.toStringAsFixed(2)),
        'recency': double.parse(recencyScore.toStringAsFixed(2)),
        'buffer': double.parse(bufferScore.toStringAsFixed(2)),
        'cadence': double.parse(cadenceScore.toStringAsFixed(2)),
        'intensity': double.parse(intensityScore.toStringAsFixed(2)),
      },
      reasons: reasons,
      intervention: intervention,
    );
  }

  double _consistency(
    Map<DateTime, HabitDailyRecord> byDate,
    DateTime today,
    int offsetDays,
    int windowSize,
  ) {
    int done = 0;
    int total = 0;
    for (int i = 0; i < windowSize; i++) {
      final day = today.subtract(Duration(days: offsetDays + i));
      total++;
      final r = byDate[day];
      if (r != null && r.done) done++;
    }
    if (total == 0) return 0.0;
    return done / total;
  }

  double _cadenceScore(
    Map<DateTime, HabitDailyRecord> byDate,
    DateTime today,
    HabitProfile profile,
  ) {
    if (profile.weeklyTarget >= 7) return 0.0; // daily — recency covers it.
    // For sub-daily targets, look at last 14 days and count misses on the
    // user's *most frequent* weekday pattern. Simple heuristic: count misses
    // among weekdays where they have historically been active.
    final activeWeekdays = <int, int>{};
    for (int i = 0; i < 28; i++) {
      final day = today.subtract(Duration(days: i));
      final r = byDate[day];
      if (r != null && r.done) {
        activeWeekdays.update(day.weekday, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    if (activeWeekdays.isEmpty) return 0.0;
    final medianActive = activeWeekdays.values.toList()..sort();
    final cutoff = medianActive[medianActive.length ~/ 2];
    final preferredDays = activeWeekdays.entries
        .where((e) => e.value >= cutoff)
        .map((e) => e.key)
        .toSet();
    int misses = 0;
    int total = 0;
    for (int i = 0; i < 14; i++) {
      final day = today.subtract(Duration(days: i));
      if (!preferredDays.contains(day.weekday)) continue;
      total++;
      final r = byDate[day];
      if (r == null || !r.done) misses++;
    }
    if (total == 0) return 0.0;
    return (misses / total) * 100.0;
  }

  double _intensityScore(
    Map<DateTime, HabitDailyRecord> byDate,
    DateTime today,
  ) {
    double recentSum = 0;
    int recentCount = 0;
    double priorSum = 0;
    int priorCount = 0;
    for (int i = 0; i < 14; i++) {
      final day = today.subtract(Duration(days: i));
      final r = byDate[day];
      if (r != null && r.done) {
        recentSum += r.intensity ?? 1.0;
        recentCount++;
      }
    }
    for (int i = 14; i < 28; i++) {
      final day = today.subtract(Duration(days: i));
      final r = byDate[day];
      if (r != null && r.done) {
        priorSum += r.intensity ?? 1.0;
        priorCount++;
      }
    }
    if (recentCount == 0 || priorCount == 0) return 0.0;
    final recentAvg = recentSum / recentCount;
    final priorAvg = priorSum / priorCount;
    final drop = priorAvg - recentAvg;
    if (drop <= 0) return 0.0;
    return (drop / math.max(priorAvg, 0.01)) * 100.0;
  }

  HabitMicroIntervention? _intervention(
    HabitProfile profile,
    HabitVerdict verdict,
    DateTime today,
    Map<DateTime, HabitDailyRecord> byDate,
  ) {
    if (verdict == HabitVerdict.onTrack ||
        verdict == HabitVerdict.momentumRising) {
      if (verdict == HabitVerdict.momentumRising) {
        return HabitMicroIntervention(
          action:
              'Hold the line on ${profile.displayName} and consider +1 day/week',
          reason: 'week-over-week gain — raising target locks in progress',
          estimatedMinutes: 1,
          dueToday: false,
        );
      }
      return null;
    }
    if (verdict == HabitVerdict.broken) {
      return HabitMicroIntervention(
        action:
            'Restart ${profile.displayName} with a 2-minute version today',
        reason: 'streak already broken — re-onboarding with smallest action',
        estimatedMinutes: 2,
        dueToday: true,
      );
    }
    // breaking / atRisk
    final todayDone = byDate[today]?.done == true;
    if (todayDone) {
      return HabitMicroIntervention(
        action:
            'Schedule ${profile.displayName} on the calendar for tomorrow morning',
        reason: 'today is logged — protect the next-day handoff',
        estimatedMinutes: 1,
        dueToday: false,
      );
    }
    return HabitMicroIntervention(
      action:
          'Do a 5-minute minimum-viable ${profile.displayName} before bed',
      reason: 'logging anything today resets the recency penalty',
      estimatedMinutes: 5,
      dueToday: true,
    );
  }

  List<HabitPlaybookAction> _buildPlaybook(
    List<HabitMomentumReport> reports,
    List<HabitProfile> profiles,
  ) {
    final profilesById = {for (final p in profiles) p.habitId: p};
    final actions = <HabitPlaybookAction>[];

    // P0: broken habits.
    final broken =
        reports.where((r) => r.verdict == HabitVerdict.broken).toList();
    if (broken.isNotEmpty) {
      actions.add(HabitPlaybookAction(
        priority: HabitPlaybookPriority.p0,
        code: 'RE_ONBOARD_BROKEN',
        headline:
            'Re-onboard ${broken.length} broken habit${broken.length == 1 ? "" : "s"}',
        detail:
            'Pick the easiest minimum-viable version of each and do it today. '
            'Broken streaks decay fast — every additional day off raises the '
            'restart cost.',
        habitIds: broken.map((r) => r.habitId).toList(),
      ));
    }

    // P0: keystone habit breaking.
    final keystoneAtRisk = reports
        .where((r) =>
            profilesById[r.habitId]?.isKeystone == true &&
            (r.verdict == HabitVerdict.breaking ||
                r.verdict == HabitVerdict.atRisk))
        .toList();
    if (keystoneAtRisk.isNotEmpty) {
      actions.add(HabitPlaybookAction(
        priority: HabitPlaybookPriority.p0,
        code: 'PROTECT_KEYSTONE',
        headline:
            'Protect keystone habit${keystoneAtRisk.length == 1 ? "" : "s"} tonight',
        detail:
            'Keystone habits (sleep, exercise) anchor the rest of the portfolio. '
            'Losing one typically drags 2–3 dependent habits within a week.',
        habitIds: keystoneAtRisk.map((r) => r.habitId).toList(),
      ));
    }

    // P1: cluster at risk (>=3 simultaneously).
    final cluster = reports
        .where((r) =>
            r.verdict == HabitVerdict.atRisk ||
            r.verdict == HabitVerdict.breaking)
        .toList();
    if (cluster.length >= 3) {
      actions.add(HabitPlaybookAction(
        priority: HabitPlaybookPriority.p1,
        code: 'CLUSTER_FATIGUE',
        headline: '${cluster.length} habits at risk simultaneously',
        detail:
            'Multiple habits slipping at once usually signals overall fatigue '
            'or schedule disruption. Pick the single highest-leverage one and '
            'cut the others to minimum-viable for the next 7 days.',
        habitIds: cluster.map((r) => r.habitId).toList(),
      ));
    }

    // P1: explicit breaking single habit.
    final breakingList =
        reports.where((r) => r.verdict == HabitVerdict.breaking).toList();
    for (final r in breakingList) {
      if (keystoneAtRisk.any((k) => k.habitId == r.habitId)) continue;
      actions.add(HabitPlaybookAction(
        priority: HabitPlaybookPriority.p1,
        code: 'INTERVENE_BREAKING',
        headline: 'Intervene on ${r.displayName} today',
        detail: r.intervention?.action ??
            'Take the smallest action that still counts as a completion.',
        habitIds: [r.habitId],
      ));
    }

    // P2: momentum rising opportunities.
    final rising = reports
        .where((r) => r.verdict == HabitVerdict.momentumRising)
        .toList();
    if (rising.isNotEmpty) {
      actions.add(HabitPlaybookAction(
        priority: HabitPlaybookPriority.p2,
        code: 'RAISE_TARGET',
        headline:
            'Consider raising target on ${rising.length} rising habit${rising.length == 1 ? "" : "s"}',
        detail:
            'Momentum is the cheapest time to upgrade — habits with sustained '
            'week-over-week gains can usually absorb +1 day/week or a slightly '
            'higher intensity without breaking the streak.',
        habitIds: rising.map((r) => r.habitId).toList(),
      ));
    }

    // De-dup by code+habitIds and sort P0 → P2.
    final seen = <String>{};
    final dedup = <HabitPlaybookAction>[];
    for (final a in actions) {
      final key = '${a.code}:${a.habitIds.join(",")}';
      if (seen.add(key)) dedup.add(a);
    }
    dedup.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return dedup;
  }

  List<String> _insights(
    List<HabitMomentumReport> reports,
    List<HabitProfile> profiles,
  ) {
    final out = <String>[];
    if (reports.isEmpty) return out;

    final atRisk = reports.where((r) =>
        r.verdict == HabitVerdict.atRisk ||
        r.verdict == HabitVerdict.breaking).length;
    final broken = reports.where((r) => r.verdict == HabitVerdict.broken).length;
    final rising = reports
        .where((r) => r.verdict == HabitVerdict.momentumRising)
        .length;

    out.add(
        '$atRisk at risk / $broken broken / $rising rising across ${reports.length} tracked habits.');

    // Category fatigue: any category with >=2 at-risk-or-worse.
    final profilesById = {for (final p in profiles) p.habitId: p};
    final byCat = <String, int>{};
    for (final r in reports) {
      final cat = profilesById[r.habitId]?.category ?? 'general';
      if (r.verdict == HabitVerdict.atRisk ||
          r.verdict == HabitVerdict.breaking ||
          r.verdict == HabitVerdict.broken) {
        byCat.update(cat, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    byCat.forEach((cat, count) {
      if (count >= 2) {
        out.add('Category "$cat" has $count habits slipping — investigate '
            'shared upstream cause.');
      }
    });

    // Keystone collapse.
    final brokenKey = reports.any((r) =>
        profilesById[r.habitId]?.isKeystone == true &&
        r.verdict == HabitVerdict.broken);
    if (brokenKey) {
      out.add('A keystone habit is broken — expect cascading misses if not '
          'addressed within 48h.');
    }

    return out;
  }

  String _grade(double portfolioRisk, List<HabitMomentumReport> reports) {
    final brokenCount =
        reports.where((r) => r.verdict == HabitVerdict.broken).length;
    if (brokenCount >= 2 || portfolioRisk >= 80) return 'F';
    if (brokenCount >= 1 || portfolioRisk >= 60) return 'D';
    if (portfolioRisk >= 40) return 'C';
    if (portfolioRisk >= 20) return 'B';
    return 'A';
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
