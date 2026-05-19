/// Weekly Review Synthesizer Service - agentic end-of-week reflection +
/// next-week pre-commitment advisor.
///
/// Sibling to GoalPortfolioOptimizerService (weekly trade-off),
/// HabitMomentumService (streaks), and EnergyBudgetPlannerService (daily load).
/// While those operate on a single layer, this one fuses the *outcomes* of a
/// finished week (habits + goals + completed events) into:
///
///   1. A per-item weekly review (what hit, what slipped, why)
///   2. A next-week pre-commitment plan (concrete targets to lock in)
///   3. A P0/P1/P2 playbook of cross-cutting actions
///   4. Cross-signal insights (keystone risk, category imbalance,
///      deep-work shortfall, meeting overload, building streak, ...)
///
/// Pure Dart - no Flutter, no persistence, no new pubspec deps. Powers
/// widgets, headless cron summaries, and tests off the same call.
library;

import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum WeeklyReviewVerdict {
  breakthroughWeek,
  steadyProgress,
  mixedResults,
  slippingWeek,
  crashAndReset,
}

enum WeeklyReviewPriority { p0, p1, p2 }

enum WeeklyReviewRiskAppetite { cautious, balanced, aggressive }

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

class WeeklyHabitInput {
  final String id;
  final String name;
  final int weeklyTarget;
  final int completions;
  final bool isKeystone;
  final String? category;

  const WeeklyHabitInput({
    required this.id,
    required this.name,
    required this.weeklyTarget,
    required this.completions,
    this.isKeystone = false,
    this.category,
  });
}

class WeeklyGoalInput {
  final String id;
  final String name;
  final double startProgress;
  final double endProgress;
  final double weeklyTargetDelta;
  final DateTime? deadline;
  final String? category;

  const WeeklyGoalInput({
    required this.id,
    required this.name,
    required this.startProgress,
    required this.endProgress,
    required this.weeklyTargetDelta,
    this.deadline,
    this.category,
  });
}

class WeeklyEventInput {
  final String id;
  final String title;
  final DateTime when;
  final Duration duration;
  final String kind;
  final bool completed;

  const WeeklyEventInput({
    required this.id,
    required this.title,
    required this.when,
    required this.duration,
    required this.kind,
    required this.completed,
  });
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

class WeeklyReviewItem {
  final String id;
  final String label;
  final String kind;
  final double progressScore;
  final WeeklyReviewPriority priority;
  final String verdict;
  final List<String> reasons;
  final String recommendation;

  const WeeklyReviewItem({
    required this.id,
    required this.label,
    required this.kind,
    required this.progressScore,
    required this.priority,
    required this.verdict,
    required this.reasons,
    required this.recommendation,
  });
}

class WeeklyReviewPlaybookAction {
  final String id;
  final WeeklyReviewPriority priority;
  final String code;
  final String label;
  final String reason;
  final String owner;
  final int blastRadius;
  final String reversibility;
  final List<String> relatedIds;

  const WeeklyReviewPlaybookAction({
    required this.id,
    required this.priority,
    required this.code,
    required this.label,
    required this.reason,
    required this.owner,
    required this.blastRadius,
    required this.reversibility,
    required this.relatedIds,
  });
}

class WeeklyPreCommitment {
  final String id;
  final String label;
  final String kind;
  final int suggestedWeeklyTarget;
  final double suggestedProgressDelta;
  final String rationale;

  const WeeklyPreCommitment({
    required this.id,
    required this.label,
    required this.kind,
    required this.suggestedWeeklyTarget,
    required this.suggestedProgressDelta,
    required this.rationale,
  });
}

class WeeklyReviewReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final WeeklyReviewVerdict verdict;
  final String grade;
  final double weekScore;
  final List<WeeklyReviewItem> items;
  final List<WeeklyReviewPlaybookAction> playbook;
  final List<WeeklyPreCommitment> nextWeekPlan;
  final List<String> insights;
  final String summary;
  final DateTime generatedAt;

  const WeeklyReviewReport({
    required this.weekStart,
    required this.weekEnd,
    required this.verdict,
    required this.grade,
    required this.weekScore,
    required this.items,
    required this.playbook,
    required this.nextWeekPlan,
    required this.insights,
    required this.summary,
    required this.generatedAt,
  });

  String toText() {
    final buf = StringBuffer();
    final ws = _isoDate(weekStart);
    buf.writeln(
      'WEEKLY REVIEW: ${verdict.name} grade=$grade score=${weekScore.toStringAsFixed(0)}/100 (week of $ws)',
    );
    buf.writeln(summary);
    buf.writeln('');
    buf.writeln('Items:');
    for (final it in items) {
      buf.writeln(
        '  [${it.priority.name.toUpperCase()}] ${it.label} (${it.kind}) - ${it.verdict} '
        'score=${it.progressScore.toStringAsFixed(0)} :: ${it.recommendation}',
      );
    }
    buf.writeln('');
    buf.writeln('Next week plan:');
    for (final c in nextWeekPlan) {
      final suggestion = c.kind == 'habit'
          ? '${c.suggestedWeeklyTarget}x/wk'
          : '+${(c.suggestedProgressDelta * 100).toStringAsFixed(1)}% progress';
      buf.writeln('  - ${c.label} (${c.kind}): $suggestion - ${c.rationale}');
    }
    buf.writeln('');
    buf.writeln('Playbook:');
    for (final a in playbook) {
      buf.writeln(
        '  [${a.priority.name.toUpperCase()}] ${a.code}: ${a.label} - ${a.reason}',
      );
    }
    buf.writeln('');
    buf.writeln('Insights:');
    for (final ins in insights) {
      buf.writeln('  - $ins');
    }
    return buf.toString().trimRight();
  }

  String toMarkdown() {
    final buf = StringBuffer();
    final ws = _isoDate(weekStart);
    final we = _isoDate(weekEnd);
    buf.writeln('## Summary');
    buf.writeln('');
    buf.writeln('- **Week:** $ws -> $we');
    buf.writeln('- **Verdict:** ${verdict.name}');
    buf.writeln('- **Grade:** $grade');
    buf.writeln('- **Score:** ${weekScore.toStringAsFixed(1)} / 100');
    buf.writeln('- **Headline:** $summary');
    buf.writeln('');
    buf.writeln('## Items');
    buf.writeln('');
    buf.writeln('| id | kind | verdict | priority | score | recommendation |');
    buf.writeln('|----|------|---------|----------|-------|----------------|');
    for (final it in items) {
      buf.writeln(
        '| ${_md(it.id)} | ${it.kind} | ${it.verdict} | ${it.priority.name} | '
        '${it.progressScore.toStringAsFixed(0)} | ${_md(it.recommendation)} |',
      );
    }
    buf.writeln('');
    buf.writeln('## Next week plan');
    buf.writeln('');
    buf.writeln('| id | kind | suggestion | rationale |');
    buf.writeln('|----|------|------------|-----------|');
    for (final c in nextWeekPlan) {
      final suggestion = c.kind == 'habit'
          ? '${c.suggestedWeeklyTarget}x/wk'
          : '+${(c.suggestedProgressDelta * 100).toStringAsFixed(1)}% progress';
      buf.writeln(
        '| ${_md(c.id)} | ${c.kind} | $suggestion | ${_md(c.rationale)} |',
      );
    }
    buf.writeln('');
    buf.writeln('## Playbook');
    buf.writeln('');
    buf.writeln('| priority | code | label | reason |');
    buf.writeln('|----------|------|-------|--------|');
    for (final a in playbook) {
      buf.writeln(
        '| ${a.priority.name} | ${a.code} | ${_md(a.label)} | ${_md(a.reason)} |',
      );
    }
    buf.writeln('');
    buf.writeln('## Insights');
    buf.writeln('');
    for (final ins in insights) {
      buf.writeln('- $ins');
    }
    return buf.toString().trimRight();
  }

  String toJson() {
    // Hand-rolled, deterministic, sorted top-level keys, 2-space indent.
    final m = <String, dynamic>{
      'generatedAt': generatedAt.toIso8601String(),
      'grade': grade,
      'insights': insights,
      'items': items
          .map(
            (it) => <String, dynamic>{
              'id': it.id,
              'kind': it.kind,
              'label': it.label,
              'priority': it.priority.name,
              'progressScore': _roundTo(it.progressScore, 4),
              'reasons': it.reasons,
              'recommendation': it.recommendation,
              'verdict': it.verdict,
            },
          )
          .toList(),
      'nextWeekPlan': nextWeekPlan
          .map(
            (c) => <String, dynamic>{
              'id': c.id,
              'kind': c.kind,
              'label': c.label,
              'rationale': c.rationale,
              'suggestedProgressDelta': _roundTo(c.suggestedProgressDelta, 6),
              'suggestedWeeklyTarget': c.suggestedWeeklyTarget,
            },
          )
          .toList(),
      'playbook': playbook
          .map(
            (a) => <String, dynamic>{
              'blastRadius': a.blastRadius,
              'code': a.code,
              'id': a.id,
              'label': a.label,
              'owner': a.owner,
              'priority': a.priority.name,
              'reason': a.reason,
              'relatedIds': a.relatedIds,
              'reversibility': a.reversibility,
            },
          )
          .toList(),
      'summary': summary,
      'verdict': verdict.name,
      'weekEnd': weekEnd.toIso8601String(),
      'weekScore': _roundTo(weekScore, 4),
      'weekStart': weekStart.toIso8601String(),
    };
    return _encodeJson(m, 0);
  }
}

// ---------------------------------------------------------------------------
// Synthesizer
// ---------------------------------------------------------------------------

class WeeklyReviewSynthesizer {
  final DateTime Function() _now;

  WeeklyReviewSynthesizer({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  WeeklyReviewReport synthesize({
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<WeeklyHabitInput> habits,
    required List<WeeklyGoalInput> goals,
    List<WeeklyEventInput> events = const [],
    WeeklyReviewRiskAppetite riskAppetite = WeeklyReviewRiskAppetite.balanced,
  }) {
    final now = _now();

    // Empty short-circuit
    if (habits.isEmpty && goals.isEmpty && events.isEmpty) {
      return WeeklyReviewReport(
        weekStart: weekStart,
        weekEnd: weekEnd,
        verdict: WeeklyReviewVerdict.mixedResults,
        grade: 'C',
        weekScore: 0.0,
        items: const [],
        playbook: const [],
        nextWeekPlan: const [],
        insights: const ['EMPTY_WEEK'],
        summary: 'No tracked data this week',
        generatedAt: now,
      );
    }

    // Per-habit items
    final items = <WeeklyReviewItem>[];
    final habitVerdictById = <String, String>{};
    for (final h in habits) {
      final item = _scoreHabit(h);
      items.add(item);
      habitVerdictById[h.id] = item.verdict;
    }

    // Per-goal items
    final goalVerdictById = <String, String>{};
    for (final g in goals) {
      final item = _scoreGoal(g, now);
      items.add(item);
      goalVerdictById[g.id] = item.verdict;
    }

    // Aggregate weekScore
    final appetiteMult = switch (riskAppetite) {
      WeeklyReviewRiskAppetite.cautious => 0.92,
      WeeklyReviewRiskAppetite.balanced => 1.0,
      WeeklyReviewRiskAppetite.aggressive => 1.08,
    };

    final habitItems = items.where((it) => it.kind == 'habit').toList();
    final goalItems = items.where((it) => it.kind == 'goal').toList();
    double rawScore;
    if (habitItems.isEmpty && goalItems.isEmpty) {
      rawScore = 0.0;
    } else if (habitItems.isEmpty) {
      rawScore = _mean(goalItems.map((e) => e.progressScore));
    } else if (goalItems.isEmpty) {
      rawScore = _mean(habitItems.map((e) => e.progressScore));
    } else {
      rawScore =
          0.5 * _mean(habitItems.map((e) => e.progressScore)) +
          0.5 * _mean(goalItems.map((e) => e.progressScore));
    }
    var weekScore = (rawScore * appetiteMult).clamp(0.0, 100.0);

    // Keystone STAGNANT or MISSED triggers crashAndReset eligibility
    final keystoneCrash = habits.any(
      (h) =>
          h.isKeystone &&
          (habitVerdictById[h.id] == 'STAGNANT' ||
              habitVerdictById[h.id] == 'MISSED'),
    );

    final hasP0 = items.any((it) => it.priority == WeeklyReviewPriority.p0);

    WeeklyReviewVerdict verdict;
    if (weekScore < 30 || keystoneCrash) {
      verdict = WeeklyReviewVerdict.crashAndReset;
    } else if (weekScore < 50) {
      verdict = WeeklyReviewVerdict.slippingWeek;
    } else if (weekScore < 70) {
      verdict = WeeklyReviewVerdict.mixedResults;
    } else if (weekScore < 85 || hasP0) {
      verdict = WeeklyReviewVerdict.steadyProgress;
    } else {
      verdict = WeeklyReviewVerdict.breakthroughWeek;
    }

    String grade;
    if (verdict == WeeklyReviewVerdict.crashAndReset) {
      grade = 'F';
    } else if (weekScore >= 85) {
      grade = 'A';
    } else if (weekScore >= 70) {
      grade = 'B';
    } else if (weekScore >= 55) {
      grade = 'C';
    } else if (weekScore >= 40) {
      grade = 'D';
    } else {
      grade = 'F';
    }

    // Playbook
    final playbook = _buildPlaybook(
      habits: habits,
      goals: goals,
      events: events,
      items: items,
      verdict: verdict,
      grade: grade,
      riskAppetite: riskAppetite,
      now: now,
    );

    // Next week plan
    final nextWeekPlan = _buildNextWeekPlan(
      habits: habits,
      goals: goals,
      items: items,
      riskAppetite: riskAppetite,
    );

    // Insights
    final insights = _buildInsights(
      habits: habits,
      goals: goals,
      events: events,
      items: items,
      verdict: verdict,
      weekScore: weekScore,
      hasP0: hasP0,
    );

    // Sort items deterministically
    items.sort((a, b) {
      final ap = a.priority.index.compareTo(b.priority.index);
      if (ap != 0) return ap;
      final sc = a.progressScore.compareTo(b.progressScore);
      if (sc != 0) return sc;
      return a.id.compareTo(b.id);
    });

    final summary = _buildSummary(verdict, grade, weekScore, items);

    return WeeklyReviewReport(
      weekStart: weekStart,
      weekEnd: weekEnd,
      verdict: verdict,
      grade: grade,
      weekScore: weekScore,
      items: List.unmodifiable(items),
      playbook: List.unmodifiable(playbook),
      nextWeekPlan: List.unmodifiable(nextWeekPlan),
      insights: List.unmodifiable(insights),
      summary: summary,
      generatedAt: now,
    );
  }

  // -------------------------------------------------------------------------
  // Scoring helpers
  // -------------------------------------------------------------------------

  WeeklyReviewItem _scoreHabit(WeeklyHabitInput h) {
    final target = math.max(1, h.weeklyTarget);
    final attain = h.completions / target;
    String verdict;
    double score;
    WeeklyReviewPriority priority;
    final reasons = <String>[];

    if (h.isKeystone) reasons.add('KEYSTONE');
    if (h.category != null && h.category!.isNotEmpty) {
      reasons.add('CATEGORY:${h.category}');
    }

    if (target >= 3 && h.completions == 0) {
      verdict = 'STAGNANT';
      score = 5;
      priority = WeeklyReviewPriority.p0;
      reasons.add('STAGNANT');
    } else if (attain >= 1.25) {
      verdict = 'OVER_DELIVERED';
      score = 95;
      priority = WeeklyReviewPriority.p2;
      reasons.add('OVER_DELIVERED');
    } else if (attain >= 1.0) {
      verdict = 'TARGET_HIT';
      score = 85;
      priority = WeeklyReviewPriority.p2;
    } else if (attain >= 0.75) {
      verdict = 'NEAR_TARGET';
      score = 65;
      priority = WeeklyReviewPriority.p1;
    } else if (attain >= 0.40) {
      verdict = 'BEHIND_PACE';
      score = 40;
      priority = h.isKeystone
          ? WeeklyReviewPriority.p0
          : WeeklyReviewPriority.p1;
      reasons.add('BEHIND_PACE');
    } else {
      verdict = 'MISSED';
      score = 15;
      priority = WeeklyReviewPriority.p0;
    }

    final recommendation = switch (verdict) {
      'OVER_DELIVERED' => 'Carry momentum; consider raising target next week.',
      'TARGET_HIT' => 'Maintain cadence; keep the streak.',
      'NEAR_TARGET' => 'One extra session this week closes the gap.',
      'BEHIND_PACE' =>
        h.isKeystone
            ? 'Keystone behind pace - protect tomorrow morning slot.'
            : 'Schedule a recovery slot in the first half of next week.',
      'MISSED' =>
        'Shrink target and rebuild with one minimum-viable session today.',
      'STAGNANT' =>
        'Restart with a 2-minute version; remove all friction.',
      _ => 'Review and adjust.',
    };

    return WeeklyReviewItem(
      id: h.id,
      label: h.name,
      kind: 'habit',
      progressScore: score,
      priority: priority,
      verdict: verdict,
      reasons: reasons,
      recommendation: recommendation,
    );
  }

  WeeklyReviewItem _scoreGoal(WeeklyGoalInput g, DateTime now) {
    final delta = g.endProgress - g.startProgress;
    final ratio = delta / math.max(0.0001, g.weeklyTargetDelta);
    String verdict;
    double score;
    WeeklyReviewPriority priority;
    final reasons = <String>[];

    if (g.category != null && g.category!.isNotEmpty) {
      reasons.add('CATEGORY:${g.category}');
    }

    if (delta <= 0 && g.weeklyTargetDelta > 0) {
      verdict = 'STAGNANT';
      score = 5;
      priority = WeeklyReviewPriority.p0;
      reasons.add('STAGNANT');
    } else if (ratio >= 1.25) {
      verdict = 'OVER_DELIVERED';
      score = 95;
      priority = WeeklyReviewPriority.p2;
      reasons.add('OVER_DELIVERED');
    } else if (ratio >= 0.95) {
      verdict = 'TARGET_HIT';
      score = 85;
      priority = WeeklyReviewPriority.p2;
    } else if (ratio >= 0.40) {
      verdict = 'BEHIND_PACE';
      score = 40;
      priority = WeeklyReviewPriority.p1;
      reasons.add('BEHIND_PACE');
    } else {
      verdict = 'MISSED';
      score = 15;
      priority = WeeklyReviewPriority.p0;
    }

    // Deadline pressure bump.
    if (g.deadline != null) {
      final daysToDeadline = g.deadline!.difference(now).inDays;
      if (daysToDeadline >= 0 && daysToDeadline <= 14 && ratio < 0.75) {
        priority = WeeklyReviewPriority.p0;
        reasons.add('DEADLINE_PRESSURE');
      }
    }

    final recommendation = switch (verdict) {
      'OVER_DELIVERED' =>
        'Bank the lead; plan a stretch milestone for next week.',
      'TARGET_HIT' => 'On pace - keep weekly cadence.',
      'BEHIND_PACE' =>
        'Add one focused 60-90 min block to catch up next week.',
      'MISSED' =>
        'Right-size next sprint; tackle smallest unblocking task first.',
      'STAGNANT' =>
        'Consider archiving or restarting; goal made no progress.',
      _ => 'Review goal scope and adjust.',
    };

    return WeeklyReviewItem(
      id: g.id,
      label: g.name,
      kind: 'goal',
      progressScore: score,
      priority: priority,
      verdict: verdict,
      reasons: reasons,
      recommendation: recommendation,
    );
  }

  // -------------------------------------------------------------------------
  // Playbook
  // -------------------------------------------------------------------------

  List<WeeklyReviewPlaybookAction> _buildPlaybook({
    required List<WeeklyHabitInput> habits,
    required List<WeeklyGoalInput> goals,
    required List<WeeklyEventInput> events,
    required List<WeeklyReviewItem> items,
    required WeeklyReviewVerdict verdict,
    required String grade,
    required WeeklyReviewRiskAppetite riskAppetite,
    required DateTime now,
  }) {
    final actions = <WeeklyReviewPlaybookAction>[];
    final habitsById = {for (final h in habits) h.id: h};
    final goalsById = {for (final g in goals) g.id: g};

    // RESCUE_KEYSTONE
    final keystoneAtRisk = items
        .where(
          (it) =>
              it.kind == 'habit' &&
              const {
                'BEHIND_PACE',
                'MISSED',
                'STAGNANT',
              }.contains(it.verdict) &&
              (habitsById[it.id]?.isKeystone ?? false),
        )
        .map((it) => it.id)
        .toList()
      ..sort();
    if (keystoneAtRisk.isNotEmpty) {
      actions.add(
        WeeklyReviewPlaybookAction(
          id: 'rescue_keystone',
          priority: WeeklyReviewPriority.p0,
          code: 'RESCUE_KEYSTONE',
          label: 'Rescue keystone habits before they break',
          reason:
              'Keystone habit(s) ${keystoneAtRisk.join(", ")} slipped this week; '
              'rebuild with smallest viable session tomorrow.',
          owner: 'user',
          blastRadius: 3,
          reversibility: 'low',
          relatedIds: keystoneAtRisk,
        ),
      );
    }

    // ARCHIVE_STAGNANT_GOAL
    final stagnantGoalsNoDeadline = items
        .where((it) {
          if (it.kind != 'goal' || it.verdict != 'STAGNANT') return false;
          final g = goalsById[it.id];
          if (g == null) return false;
          if (g.deadline == null) return true;
          return g.deadline!.difference(now).inDays > 30;
        })
        .map((it) => it.id)
        .toList()
      ..sort();
    if (stagnantGoalsNoDeadline.isNotEmpty) {
      actions.add(
        WeeklyReviewPlaybookAction(
          id: 'archive_stagnant_goal',
          priority: WeeklyReviewPriority.p0,
          code: 'ARCHIVE_STAGNANT_GOAL',
          label: 'Archive stagnant goals with no near-term deadline',
          reason:
              'Goal(s) ${stagnantGoalsNoDeadline.join(", ")} made zero progress and have no '
              'pressing deadline; archive or restart with smaller scope.',
          owner: 'user',
          blastRadius: 3,
          reversibility: 'low',
          relatedIds: stagnantGoalsNoDeadline,
        ),
      );
    }

    // CARRY_MOMENTUM
    final overDelivered = items
        .where((it) => it.verdict == 'OVER_DELIVERED')
        .map((it) => it.id)
        .toList()
      ..sort();
    if (overDelivered.isNotEmpty) {
      actions.add(
        WeeklyReviewPlaybookAction(
          id: 'carry_momentum',
          priority: WeeklyReviewPriority.p1,
          code: 'CARRY_MOMENTUM',
          label: 'Carry over-delivered momentum into next week',
          reason:
              'Item(s) ${overDelivered.join(", ")} exceeded target; lock in '
              'a stretch goal while motivation is high.',
          owner: 'user',
          blastRadius: 2,
          reversibility: 'high',
          relatedIds: overDelivered,
        ),
      );
    }

    // REBALANCE_CATEGORIES
    final missedBehind = items
        .where(
          (it) => const {
            'BEHIND_PACE',
            'MISSED',
            'STAGNANT',
          }.contains(it.verdict),
        )
        .toList();
    final catCounts = <String, List<String>>{};
    for (final it in missedBehind) {
      final cat = it.kind == 'habit'
          ? habitsById[it.id]?.category
          : goalsById[it.id]?.category;
      if (cat == null || cat.isEmpty) continue;
      catCounts.putIfAbsent(cat, () => []).add(it.id);
    }
    final dominantCat = catCounts.entries
        .where((e) => e.value.length >= 3)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (dominantCat.isNotEmpty) {
      final winner = dominantCat.first;
      final ids = List<String>.from(winner.value)..sort();
      actions.add(
        WeeklyReviewPlaybookAction(
          id: 'rebalance_categories',
          priority: WeeklyReviewPriority.p1,
          code: 'REBALANCE_CATEGORIES',
          label: 'Rebalance attention across categories',
          reason:
              '${winner.value.length} slipping items in category "${winner.key}"; '
              'distribute focus next week.',
          owner: 'user',
          blastRadius: 2,
          reversibility: 'medium',
          relatedIds: ids,
        ),
      );
    }

    // SCHEDULE_DEEP_WORK (only when events present)
    if (events.isNotEmpty) {
      final completed = events.where((e) => e.completed).toList();
      if (completed.isNotEmpty) {
        final deepMin = completed
            .where((e) => e.kind == 'deepWork')
            .fold<int>(0, (acc, e) => acc + e.duration.inMinutes);
        final totalMin = completed.fold<int>(
          0,
          (acc, e) => acc + e.duration.inMinutes,
        );
        if (totalMin > 0 && deepMin / totalMin < 0.15) {
          actions.add(
            WeeklyReviewPlaybookAction(
              id: 'schedule_deep_work',
              priority: WeeklyReviewPriority.p1,
              code: 'SCHEDULE_DEEP_WORK',
              label: 'Schedule deep work blocks for next week',
              reason:
                  'Deep-work share was ${(deepMin / totalMin * 100).toStringAsFixed(0)}%; '
                  'lock in 2-3 protected blocks before meetings fill the calendar.',
              owner: 'user',
              blastRadius: 1,
              reversibility: 'high',
              relatedIds: const [],
            ),
          );
        }
      }
    }

    // CELEBRATE_WIN
    final targetHits = items.where((it) => it.verdict == 'TARGET_HIT').toList();
    final keystoneOver = items.any(
      (it) =>
          it.verdict == 'OVER_DELIVERED' &&
          (habitsById[it.id]?.isKeystone ?? false),
    );
    if (targetHits.length >= 2 || keystoneOver) {
      actions.add(
        WeeklyReviewPlaybookAction(
          id: 'celebrate_win',
          priority: WeeklyReviewPriority.p2,
          code: 'CELEBRATE_WIN',
          label: 'Celebrate the wins from this week',
          reason:
              'Multiple targets hit - acknowledge the wins so they stick.',
          owner: 'user',
          blastRadius: 1,
          reversibility: 'high',
          relatedIds: targetHits.map((it) => it.id).toList()..sort(),
        ),
      );
    }

    // Fallback healthy
    final hasP0OrP1 = actions.any(
      (a) =>
          a.priority == WeeklyReviewPriority.p0 ||
          a.priority == WeeklyReviewPriority.p1,
    );
    if (!hasP0OrP1 && actions.where((a) => a.priority == WeeklyReviewPriority.p2).isEmpty) {
      actions.add(
        const WeeklyReviewPlaybookAction(
          id: 'weekly_review_healthy',
          priority: WeeklyReviewPriority.p2,
          code: 'WEEKLY_REVIEW_HEALTHY',
          label: 'Weekly review healthy - no urgent action',
          reason: 'No P0/P1 issues detected; maintain current cadence.',
          owner: 'user',
          blastRadius: 1,
          reversibility: 'high',
          relatedIds: [],
        ),
      );
    }

    // Aggressive trims WEEKLY_REVIEW_HEALTHY fallback when P0/P1 present.
    if (riskAppetite == WeeklyReviewRiskAppetite.aggressive && hasP0OrP1) {
      actions.removeWhere((a) => a.code == 'WEEKLY_REVIEW_HEALTHY');
    }

    // Cautious appends SCHEDULE_FOLLOWUP_REVIEW at grade C/D/F.
    if (riskAppetite == WeeklyReviewRiskAppetite.cautious &&
        const {'C', 'D', 'F'}.contains(grade)) {
      actions.add(
        const WeeklyReviewPlaybookAction(
          id: 'schedule_followup_review',
          priority: WeeklyReviewPriority.p2,
          code: 'SCHEDULE_FOLLOWUP_REVIEW',
          label: 'Schedule a follow-up mid-week check-in',
          reason:
              'Cautious appetite + slipping grade; add a mid-week pulse '
              'review to catch further drift.',
          owner: 'user',
          blastRadius: 1,
          reversibility: 'high',
          relatedIds: [],
        ),
      );
    }

    // Dedupe by id, sort priority asc then code asc.
    final seen = <String>{};
    final unique = <WeeklyReviewPlaybookAction>[];
    for (final a in actions) {
      if (seen.add(a.id)) unique.add(a);
    }
    unique.sort((a, b) {
      final p = a.priority.index.compareTo(b.priority.index);
      if (p != 0) return p;
      return a.code.compareTo(b.code);
    });
    return unique;
  }

  // -------------------------------------------------------------------------
  // Next-week plan
  // -------------------------------------------------------------------------

  List<WeeklyPreCommitment> _buildNextWeekPlan({
    required List<WeeklyHabitInput> habits,
    required List<WeeklyGoalInput> goals,
    required List<WeeklyReviewItem> items,
    required WeeklyReviewRiskAppetite riskAppetite,
  }) {
    final out = <WeeklyPreCommitment>[];
    final habitsById = {for (final h in habits) h.id: h};
    final goalsById = {for (final g in goals) g.id: g};

    for (final it in items.where((it) => it.kind == 'habit')) {
      final h = habitsById[it.id];
      if (h == null) continue;
      int suggested = h.weeklyTarget;
      String rationale = 'maintain cadence';
      switch (it.verdict) {
        case 'OVER_DELIVERED':
          if (riskAppetite == WeeklyReviewRiskAppetite.cautious) {
            suggested = h.weeklyTarget;
            rationale = 'over-delivered - hold target (cautious)';
          } else if (riskAppetite == WeeklyReviewRiskAppetite.aggressive) {
            suggested = h.weeklyTarget + 2;
            rationale = 'over-delivered - stretch target +2 (aggressive)';
          } else {
            suggested = h.weeklyTarget + 1;
            rationale = 'over-delivered - raise target +1';
          }
          break;
        case 'TARGET_HIT':
          suggested = h.weeklyTarget;
          rationale = 'on pace - hold cadence';
          break;
        case 'NEAR_TARGET':
          suggested = h.weeklyTarget;
          rationale = 'near target - one extra session closes the gap';
          break;
        case 'BEHIND_PACE':
          suggested = h.weeklyTarget;
          rationale = 'protect existing target with calendar slot';
          break;
        case 'MISSED':
        case 'STAGNANT':
          suggested = math.max(1, h.weeklyTarget - 2);
          rationale = 'shrink to rebuild momentum';
          break;
      }
      out.add(
        WeeklyPreCommitment(
          id: h.id,
          label: h.name,
          kind: 'habit',
          suggestedWeeklyTarget: suggested,
          suggestedProgressDelta: 0,
          rationale: rationale,
        ),
      );
    }

    for (final it in items.where((it) => it.kind == 'goal')) {
      final g = goalsById[it.id];
      if (g == null) continue;
      double suggested = g.weeklyTargetDelta;
      String rationale = 'maintain weekly pace';
      switch (it.verdict) {
        case 'OVER_DELIVERED':
          suggested = g.weeklyTargetDelta * 1.25;
          rationale = 'over-delivered - stretch sprint';
          break;
        case 'TARGET_HIT':
          rationale = 'on pace - hold cadence';
          break;
        case 'BEHIND_PACE':
          suggested = g.weeklyTargetDelta * 1.10;
          rationale = 'catch up - slight stretch next sprint';
          break;
        case 'MISSED':
          suggested = g.weeklyTargetDelta * 0.75;
          rationale = 'right-size next sprint';
          break;
        case 'STAGNANT':
          suggested = 0;
          rationale = 'consider archiving or restarting';
          break;
      }
      out.add(
        WeeklyPreCommitment(
          id: g.id,
          label: g.name,
          kind: 'goal',
          suggestedWeeklyTarget: 0,
          suggestedProgressDelta: suggested,
          rationale: rationale,
        ),
      );
    }

    // Sort: keystone habits first, then by progressScore asc so weakest get focus.
    final scoreById = {for (final it in items) it.id: it.progressScore};
    final keystoneIds = {
      for (final h in habits.where((h) => h.isKeystone)) h.id,
    };
    out.sort((a, b) {
      final aKey = keystoneIds.contains(a.id) ? 0 : 1;
      final bKey = keystoneIds.contains(b.id) ? 0 : 1;
      if (aKey != bKey) return aKey - bKey;
      final aScore = scoreById[a.id] ?? 100;
      final bScore = scoreById[b.id] ?? 100;
      final sc = aScore.compareTo(bScore);
      if (sc != 0) return sc;
      return a.id.compareTo(b.id);
    });

    final cap = switch (riskAppetite) {
      WeeklyReviewRiskAppetite.cautious => 10,
      WeeklyReviewRiskAppetite.balanced => 8,
      WeeklyReviewRiskAppetite.aggressive => 6,
    };

    return out.length > cap ? out.sublist(0, cap) : out;
  }

  // -------------------------------------------------------------------------
  // Insights
  // -------------------------------------------------------------------------

  List<String> _buildInsights({
    required List<WeeklyHabitInput> habits,
    required List<WeeklyGoalInput> goals,
    required List<WeeklyEventInput> events,
    required List<WeeklyReviewItem> items,
    required WeeklyReviewVerdict verdict,
    required double weekScore,
    required bool hasP0,
  }) {
    final insights = <String>[];
    final habitsById = {for (final h in habits) h.id: h};

    // KEYSTONE_AT_RISK
    final keystoneAtRisk = items.any(
      (it) =>
          it.kind == 'habit' &&
          (habitsById[it.id]?.isKeystone ?? false) &&
          it.verdict != 'TARGET_HIT' &&
          it.verdict != 'OVER_DELIVERED');
    if (keystoneAtRisk) insights.add('KEYSTONE_AT_RISK');

    // CATEGORY_IMBALANCE
    final cats = <String, int>{};
    var withCat = 0;
    for (final it in items) {
      final cat = it.kind == 'habit'
          ? habitsById[it.id]?.category
          : goals.firstWhere(
              (g) => g.id == it.id,
              orElse: () => const WeeklyGoalInput(
                id: '',
                name: '',
                startProgress: 0,
                endProgress: 0,
                weeklyTargetDelta: 0,
              ),
            ).category;
      if (cat == null || cat.isEmpty) continue;
      cats[cat] = (cats[cat] ?? 0) + 1;
      withCat++;
    }
    if (withCat > 0) {
      for (final e in cats.entries) {
        if (e.value / withCat >= 0.6) {
          insights.add('CATEGORY_IMBALANCE');
          break;
        }
      }
    }

    // Event-based insights
    if (events.isNotEmpty) {
      final completed = events.where((e) => e.completed).toList();
      if (completed.isNotEmpty) {
        final totalMin = completed.fold<int>(
          0,
          (a, e) => a + e.duration.inMinutes,
        );
        final deepMin = completed
            .where((e) => e.kind == 'deepWork')
            .fold<int>(0, (a, e) => a + e.duration.inMinutes);
        final meetingMin = completed
            .where((e) => e.kind == 'meeting')
            .fold<int>(0, (a, e) => a + e.duration.inMinutes);
        if (totalMin > 0 && deepMin / totalMin < 0.25) {
          insights.add('DEEP_WORK_SHORTFALL');
        }
        if (totalMin > 0 && meetingMin / totalMin >= 0.5) {
          insights.add('MEETING_OVERLOAD');
        }
        if (!completed.any((e) => e.kind == 'exercise')) {
          insights.add('NO_EXERCISE');
        }
      }
    }

    // CONSISTENT_PROGRESS
    if (!hasP0 && weekScore >= 70) insights.add('CONSISTENT_PROGRESS');

    // BUILDING_STREAK
    final hits = items
        .where((it) =>
            it.kind == 'habit' &&
            (it.verdict == 'TARGET_HIT' || it.verdict == 'OVER_DELIVERED'))
        .length;
    if (hits >= 3) insights.add('BUILDING_STREAK');

    // RECOVERY_WEEK_NEEDED
    if (verdict == WeeklyReviewVerdict.crashAndReset) {
      insights.add('RECOVERY_WEEK_NEEDED');
    }

    if (insights.isEmpty) insights.add('STEADY_BASELINE');

    return insights;
  }

  // -------------------------------------------------------------------------
  // Summary headline
  // -------------------------------------------------------------------------

  String _buildSummary(
    WeeklyReviewVerdict verdict,
    String grade,
    double weekScore,
    List<WeeklyReviewItem> items,
  ) {
    final p0 = items.where((it) => it.priority == WeeklyReviewPriority.p0).length;
    final wins = items
        .where((it) =>
            it.verdict == 'TARGET_HIT' || it.verdict == 'OVER_DELIVERED')
        .length;
    return '${verdict.name} (grade $grade, ${weekScore.toStringAsFixed(0)}/100); '
        '$wins win(s), $p0 urgent issue(s).';
  }
}

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

double _mean(Iterable<double> xs) {
  if (xs.isEmpty) return 0.0;
  var sum = 0.0;
  var n = 0;
  for (final x in xs) {
    sum += x;
    n++;
  }
  return sum / n;
}

double _roundTo(double v, int places) {
  if (v.isNaN || v.isInfinite) return v;
  final mult = math.pow(10, places).toDouble();
  return (v * mult).round() / mult;
}

String _isoDate(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

String _md(String s) => s.replaceAll('|', '\\|').replaceAll('\n', ' ');

// Hand-rolled deterministic JSON encoder. Sorts map keys recursively,
// 2-space indent, strings/dates/enums/numbers/booleans/null/list/map only.
String _encodeJson(Object? v, int depth) {
  if (v == null) return 'null';
  if (v is bool) return v ? 'true' : 'false';
  if (v is num) {
    if (v is double) {
      if (v.isNaN || v.isInfinite) return 'null';
      // Render integers without trailing .0 for cleanliness when exact.
      if (v == v.truncateToDouble() && v.abs() < 1e16) {
        return v.toInt().toString();
      }
    }
    return v.toString();
  }
  if (v is String) return _encodeJsonString(v);
  if (v is List) {
    if (v.isEmpty) return '[]';
    final indent = '  ' * (depth + 1);
    final close = '  ' * depth;
    final items = v.map((e) => '$indent${_encodeJson(e, depth + 1)}').join(',\n');
    return '[\n$items\n$close]';
  }
  if (v is Map) {
    final keys = v.keys.map((k) => k.toString()).toList()..sort();
    if (keys.isEmpty) return '{}';
    final indent = '  ' * (depth + 1);
    final close = '  ' * depth;
    final entries = keys
        .map(
          (k) =>
              '$indent${_encodeJsonString(k)}: ${_encodeJson(v[k], depth + 1)}',
        )
        .join(',\n');
    return '{\n$entries\n$close}';
  }
  // Fallback for DateTime / other objects.
  return _encodeJsonString(v.toString());
}

String _encodeJsonString(String s) {
  final buf = StringBuffer('"');
  for (final rune in s.runes) {
    switch (rune) {
      case 0x22:
        buf.write(r'\"');
        break;
      case 0x5C:
        buf.write(r'\\');
        break;
      case 0x08:
        buf.write(r'\b');
        break;
      case 0x0C:
        buf.write(r'\f');
        break;
      case 0x0A:
        buf.write(r'\n');
        break;
      case 0x0D:
        buf.write(r'\r');
        break;
      case 0x09:
        buf.write(r'\t');
        break;
      default:
        if (rune < 0x20) {
          buf.write('\\u${rune.toRadixString(16).padLeft(4, '0')}');
        } else {
          buf.writeCharCode(rune);
        }
    }
  }
  buf.write('"');
  return buf.toString();
}
