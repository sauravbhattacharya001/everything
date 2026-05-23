/// Subscription Rotation Advisor - agentic per-subscription keep/downgrade/
/// pause/cancel/swap advisor for a portfolio of recurring expenses.
///
/// Sibling to:
///   * `subscription_tracker_service.dart`         (raw subscription CRUD)
///   * `expense_forecast_service.dart`             (forward-looking cashflow)
///   * `budget_planner_service.dart`               (budget envelopes)
///   * `daily_top_three_advisor_service.dart`      (today's shortlist)
///   * `habit_recovery_advisor_service.dart`       (lapsed habits)
///
/// Where those modules describe *what is spent* and *what the budget allows*,
/// this advisor answers a different question:
///
///   "Across all my recurring subscriptions, which ones should I keep,
///    downgrade, pause for the next month, cancel outright, or swap to a
///    cheaper alternative — and in what order should I act to free up the
///    most cash with the least pain?"
///
/// Pipeline:
///   1. For every subscription, compute a 0..100 `rotationRisk` from:
///      cost vs portfolio mean, usage decay (last-used age + frequency),
///      cost-per-use, duplicate-category overlap, free-trial expiring,
///      price increase since signup, and renewal proximity.
///   2. Classify into one of [SubscriptionVerdict]:
///      KEEP / DOWNGRADE_TIER / PAUSE_ONE_MONTH / CANCEL_NOW / SWAP_TO_ALTERNATIVE
///      / WATCH / INSUFFICIENT_DATA.
///   3. Modulate by [SubscriptionRiskAppetite] (cautious 1.15x / balanced /
///      aggressive 0.85x score multiplier; cautious adds an extra audit step;
///      aggressive trims P3 fallbacks).
///   4. Aggregate portfolio: total monthly cost, projectedMonthlySavings,
///      `portfolioBloatScore`, band + A-F grade + headline + insights.
///   5. Emit a deduped P0-first playbook of [RotationAction] items
///      (priority, owner, blastRadius, reversibility, related_ids).
///   6. Render via `toText` / `toMarkdown` / `toJson` (byte-stable: keys are
///      sorted via Dart Map insertion order with deterministic key sequence).
///
/// Pure Dart, zero new dependencies. Deterministic - no `Random` usage. All
/// "now" reads go through `options.now ?? DateTime.now`. Stable sorts.
library;

import 'dart:convert';
import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum SubscriptionRiskAppetite { cautious, balanced, aggressive }

enum SubscriptionPriority { p0, p1, p2, p3 }

enum SubscriptionVerdict {
  keep,
  downgradeTier,
  pauseOneMonth,
  cancelNow,
  swapToAlternative,
  watch,
  insufficientData,
}

enum SubscriptionPortfolioBand { lean, healthy, bloated, severelyBloated }

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

class SubscriptionSnapshot {
  final String id;
  final String name;
  final String category; // e.g. 'streaming', 'cloud', 'productivity', 'fitness'
  final double monthlyCost; // normalised to USD per month
  final DateTime? signedUpAt;
  final DateTime? lastUsedAt;
  final int usesInLast30Days;
  final double? signupMonthlyCost; // for price-creep detection
  final DateTime? nextRenewalAt;
  final DateTime? freeTrialEndsAt;
  final bool isShared; // shared with family/team => harder to cancel
  final bool hasContractLock; // annual lock, ETF, etc.
  final String? cheaperAlternative; // free-form: e.g. "Netflix basic w/ ads"
  final double? cheaperAlternativeCost;

  const SubscriptionSnapshot({
    required this.id,
    required this.name,
    required this.category,
    required this.monthlyCost,
    this.signedUpAt,
    this.lastUsedAt,
    this.usesInLast30Days = 0,
    this.signupMonthlyCost,
    this.nextRenewalAt,
    this.freeTrialEndsAt,
    this.isShared = false,
    this.hasContractLock = false,
    this.cheaperAlternative,
    this.cheaperAlternativeCost,
  });
}

class RotationOptions {
  final SubscriptionRiskAppetite riskAppetite;
  final int unusedDaysThreshold; // default 30
  final double duplicateCategoryCostFloor; // category overlap cost trigger
  final DateTime Function()? now;

  const RotationOptions({
    this.riskAppetite = SubscriptionRiskAppetite.balanced,
    this.unusedDaysThreshold = 30,
    this.duplicateCategoryCostFloor = 5.0,
    this.now,
  });
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

class SubscriptionForecast {
  final String id;
  final String name;
  final String category;
  final double monthlyCost;
  final SubscriptionVerdict verdict;
  final int? daysSinceLastUse;
  final double costPerUse;
  final double rotationRisk; // 0..100
  final double projectedMonthlySavings;
  final String suggestedAction;
  final List<String> reasons;

  const SubscriptionForecast({
    required this.id,
    required this.name,
    required this.category,
    required this.monthlyCost,
    required this.verdict,
    required this.daysSinceLastUse,
    required this.costPerUse,
    required this.rotationRisk,
    required this.projectedMonthlySavings,
    required this.suggestedAction,
    required this.reasons,
  });

  Map<String, dynamic> toJsonMap() => {
        'category': category,
        'cost_per_use': _round2(costPerUse),
        'days_since_last_use': daysSinceLastUse,
        'id': id,
        'monthly_cost': _round2(monthlyCost),
        'name': name,
        'projected_monthly_savings': _round2(projectedMonthlySavings),
        'reasons': reasons,
        'rotation_risk': _round2(rotationRisk),
        'suggested_action': suggestedAction,
        'verdict': _verdictName(verdict),
      };
}

class RotationAction {
  final SubscriptionPriority priority;
  final String code;
  final String label;
  final String reason;
  final String owner;
  final int blastRadius; // 1..5
  final String reversibility; // 'low' | 'medium' | 'high'
  final List<String> relatedIds;
  final double projectedSavings;

  const RotationAction({
    required this.priority,
    required this.code,
    required this.label,
    required this.reason,
    required this.owner,
    required this.blastRadius,
    required this.reversibility,
    this.relatedIds = const [],
    this.projectedSavings = 0.0,
  });

  Map<String, dynamic> toJsonMap() => {
        'blast_radius': blastRadius,
        'code': code,
        'label': label,
        'owner': owner,
        'priority': _priorityName(priority),
        'projected_savings': _round2(projectedSavings),
        'reason': reason,
        'related_ids': relatedIds,
        'reversibility': reversibility,
      };
}

class SubscriptionRotationReport {
  final DateTime generatedAt;
  final SubscriptionRiskAppetite riskAppetite;
  final int totalSubscriptions;
  final double totalMonthlyCost;
  final double projectedMonthlySavings;
  final double portfolioBloatScore; // 0..100 higher = worse
  final SubscriptionPortfolioBand band;
  final String grade;
  final String headline;
  final List<SubscriptionForecast> forecasts;
  final List<RotationAction> playbook;
  final List<String> insights;

  const SubscriptionRotationReport({
    required this.generatedAt,
    required this.riskAppetite,
    required this.totalSubscriptions,
    required this.totalMonthlyCost,
    required this.projectedMonthlySavings,
    required this.portfolioBloatScore,
    required this.band,
    required this.grade,
    required this.headline,
    required this.forecasts,
    required this.playbook,
    required this.insights,
  });

  Map<String, dynamic> toJsonMap() => {
        'band': _bandName(band),
        'forecasts': forecasts.map((f) => f.toJsonMap()).toList(),
        'generated_at': generatedAt.toUtc().toIso8601String(),
        'grade': grade,
        'headline': headline,
        'insights': insights,
        'playbook': playbook.map((a) => a.toJsonMap()).toList(),
        'portfolio_bloat_score': _round2(portfolioBloatScore),
        'projected_monthly_savings': _round2(projectedMonthlySavings),
        'risk_appetite': _appetiteName(riskAppetite),
        'total_monthly_cost': _round2(totalMonthlyCost),
        'total_subscriptions': totalSubscriptions,
      };
}

// ---------------------------------------------------------------------------
// Advisor
// ---------------------------------------------------------------------------

class SubscriptionRotationAdvisorService {
  const SubscriptionRotationAdvisorService();

  SubscriptionRotationReport recommend(
    List<SubscriptionSnapshot> subs, [
    RotationOptions options = const RotationOptions(),
  ]) {
    final now = (options.now ?? DateTime.now)();
    final appetiteMul = switch (options.riskAppetite) {
      SubscriptionRiskAppetite.cautious => 1.15,
      SubscriptionRiskAppetite.balanced => 1.0,
      SubscriptionRiskAppetite.aggressive => 0.85,
    };

    if (subs.isEmpty) {
      return SubscriptionRotationReport(
        generatedAt: now,
        riskAppetite: options.riskAppetite,
        totalSubscriptions: 0,
        totalMonthlyCost: 0,
        projectedMonthlySavings: 0,
        portfolioBloatScore: 0,
        band: SubscriptionPortfolioBand.lean,
        grade: 'A',
        headline: 'EMPTY_PORTFOLIO: no subscriptions tracked',
        forecasts: const [],
        playbook: const [],
        insights: const ['EMPTY_PORTFOLIO'],
      );
    }

    final totalCost = subs.fold<double>(0.0, (s, x) => s + x.monthlyCost);
    final meanCost = totalCost / subs.length;

    // Category overlap detection.
    final byCategory = <String, List<SubscriptionSnapshot>>{};
    for (final s in subs) {
      byCategory.putIfAbsent(s.category.toLowerCase(), () => []).add(s);
    }

    final forecasts = <SubscriptionForecast>[];
    for (final s in subs) {
      forecasts.add(_evaluate(
        s,
        now: now,
        meanCost: meanCost,
        options: options,
        appetiteMul: appetiteMul,
        sameCategoryPeers: byCategory[s.category.toLowerCase()]!
            .where((p) => p.id != s.id)
            .toList(growable: false),
      ));
    }

    forecasts.sort((a, b) {
      final p = _verdictRank(a.verdict).compareTo(_verdictRank(b.verdict));
      if (p != 0) return p;
      final r = b.rotationRisk.compareTo(a.rotationRisk);
      if (r != 0) return r;
      return a.id.compareTo(b.id);
    });

    final projectedSavings = forecasts.fold<double>(
        0.0, (acc, f) => acc + f.projectedMonthlySavings);

    // Portfolio bloat = mean rotationRisk weighted by share of cost.
    double bloat = 0.0;
    if (totalCost > 0) {
      for (final f in forecasts) {
        final weight = f.monthlyCost / totalCost;
        bloat += f.rotationRisk * weight;
      }
    }
    bloat = bloat.clamp(0.0, 100.0);

    final band = _bandFor(bloat);
    final grade = _gradeFor(bloat, forecasts);
    final insights = _insights(forecasts, totalCost, byCategory, options, now);
    final playbook = _playbook(forecasts, options, projectedSavings);

    final headline = _headline(grade, band, forecasts, projectedSavings);

    return SubscriptionRotationReport(
      generatedAt: now,
      riskAppetite: options.riskAppetite,
      totalSubscriptions: subs.length,
      totalMonthlyCost: totalCost,
      projectedMonthlySavings: projectedSavings,
      portfolioBloatScore: bloat,
      band: band,
      grade: grade,
      headline: headline,
      forecasts: forecasts,
      playbook: playbook,
      insights: insights,
    );
  }

  // ---- per-subscription evaluation ----

  SubscriptionForecast _evaluate(
    SubscriptionSnapshot s, {
    required DateTime now,
    required double meanCost,
    required RotationOptions options,
    required double appetiteMul,
    required List<SubscriptionSnapshot> sameCategoryPeers,
  }) {
    final reasons = <String>[];
    double risk = 0.0;

    final lastUsedAge = s.lastUsedAt == null
        ? null
        : now.difference(s.lastUsedAt!).inDays;
    final uses = s.usesInLast30Days;
    final cpu = uses > 0 ? s.monthlyCost / uses : s.monthlyCost; // proxy

    // Usage decay
    if (lastUsedAge == null) {
      risk += 40;
      reasons.add('NEVER_LOGGED_USE');
    } else if (lastUsedAge >= options.unusedDaysThreshold * 3) {
      risk += 45;
      reasons.add('UNUSED_90D_PLUS');
    } else if (lastUsedAge >= options.unusedDaysThreshold) {
      risk += 25;
      reasons.add('UNUSED_${options.unusedDaysThreshold}D_PLUS');
    } else if (lastUsedAge >= 14) {
      risk += 10;
      reasons.add('LIGHT_RECENT_USAGE');
    }

    if (uses == 0) {
      risk += 15;
      reasons.add('ZERO_USES_LAST_30D');
    } else if (uses <= 2) {
      risk += 8;
      reasons.add('VERY_LOW_USE_FREQUENCY');
    }

    // Cost-per-use heuristic
    if (uses > 0 && cpu >= 20) {
      risk += 18;
      reasons.add('HIGH_COST_PER_USE');
    } else if (uses > 0 && cpu >= 8) {
      risk += 8;
      reasons.add('ELEVATED_COST_PER_USE');
    }

    // Cost vs mean
    if (meanCost > 0 && s.monthlyCost >= meanCost * 2.0) {
      risk += 12;
      reasons.add('ABOVE_PORTFOLIO_MEAN_2X');
    } else if (meanCost > 0 && s.monthlyCost >= meanCost * 1.4) {
      risk += 6;
      reasons.add('ABOVE_PORTFOLIO_MEAN_1_4X');
    }

    // Duplicate category
    if (sameCategoryPeers.isNotEmpty &&
        s.monthlyCost >= options.duplicateCategoryCostFloor) {
      risk += 12;
      reasons.add('DUPLICATE_CATEGORY_${s.category.toUpperCase()}');
    }

    // Price creep
    if (s.signupMonthlyCost != null && s.signupMonthlyCost! > 0) {
      final ratio = s.monthlyCost / s.signupMonthlyCost!;
      if (ratio >= 1.5) {
        risk += 12;
        reasons.add('PRICE_CREEP_50PCT_PLUS');
      } else if (ratio >= 1.2) {
        risk += 6;
        reasons.add('PRICE_CREEP_20PCT_PLUS');
      }
    }

    // Trial expiring
    if (s.freeTrialEndsAt != null) {
      final hrs = s.freeTrialEndsAt!.difference(now).inHours;
      if (hrs >= 0 && hrs <= 72) {
        risk += 20;
        reasons.add('FREE_TRIAL_ENDING_SOON');
      }
    }

    // Cheaper alternative present
    final hasCheaperAlt = s.cheaperAlternative != null &&
        s.cheaperAlternativeCost != null &&
        s.cheaperAlternativeCost! < s.monthlyCost;
    if (hasCheaperAlt) {
      risk += 8;
      reasons.add('CHEAPER_ALTERNATIVE_AVAILABLE');
    }

    // Renewal proximity (mildly time-sensitive but not a risk multiplier
    // on its own — surfaces as a reason so playbook can sequence).
    if (s.nextRenewalAt != null) {
      final days = s.nextRenewalAt!.difference(now).inDays;
      if (days >= 0 && days <= 7) {
        reasons.add('RENEWS_WITHIN_7D');
      }
    }

    // Stickiness modifiers
    if (s.hasContractLock) {
      risk -= 12;
      if (risk < 0) risk = 0;
      reasons.add('CONTRACT_LOCK');
    }
    if (s.isShared) {
      risk -= 6;
      if (risk < 0) risk = 0;
      reasons.add('SHARED_WITH_OTHERS');
    }

    risk = (risk * appetiteMul).clamp(0.0, 100.0);

    // Verdict ladder
    SubscriptionVerdict verdict;
    String suggested;
    double projectedSavings = 0.0;

    final criticalUnused = (lastUsedAge != null &&
            lastUsedAge >= options.unusedDaysThreshold * 3) ||
        (lastUsedAge == null && s.usesInLast30Days == 0);

    if (s.signedUpAt == null && s.lastUsedAt == null && uses == 0) {
      verdict = SubscriptionVerdict.insufficientData;
      suggested = 'Log a usage event or signup date before deciding.';
    } else if (s.freeTrialEndsAt != null &&
        s.freeTrialEndsAt!.difference(now).inHours >= 0 &&
        s.freeTrialEndsAt!.difference(now).inHours <= 72 &&
        uses < 2) {
      verdict = SubscriptionVerdict.cancelNow;
      suggested =
          'Free trial ends within 72h with <2 uses — cancel before auto-renew.';
      projectedSavings = s.monthlyCost;
    } else if (criticalUnused && !s.hasContractLock) {
      verdict = SubscriptionVerdict.cancelNow;
      suggested =
          'Unused for ${lastUsedAge ?? 999}d with no recent uses — cancel.';
      projectedSavings = s.monthlyCost;
    } else if (criticalUnused && s.hasContractLock) {
      verdict = SubscriptionVerdict.pauseOneMonth;
      suggested =
          'Locked contract — pause/freeze if allowed, otherwise calendar a cancel for renewal.';
      projectedSavings = s.monthlyCost * 0.5;
    } else if (hasCheaperAlt && risk >= 35) {
      verdict = SubscriptionVerdict.swapToAlternative;
      suggested =
          'Swap to ${s.cheaperAlternative} (\$${_round2(s.cheaperAlternativeCost!)}/mo).';
      projectedSavings =
          (s.monthlyCost - (s.cheaperAlternativeCost ?? s.monthlyCost))
              .clamp(0.0, double.infinity)
              .toDouble();
    } else if (sameCategoryPeers.isNotEmpty &&
        s.monthlyCost >= options.duplicateCategoryCostFloor &&
        uses <= 4 &&
        risk >= 40) {
      verdict = SubscriptionVerdict.cancelNow;
      suggested =
          'Duplicate ${s.category} subscription — consolidate to one provider.';
      projectedSavings = s.monthlyCost;
    } else if (uses <= 4 && risk >= 45) {
      verdict = SubscriptionVerdict.downgradeTier;
      suggested =
          'Downgrade to a cheaper tier — usage does not justify the current plan.';
      projectedSavings = s.monthlyCost * 0.35;
    } else if (lastUsedAge != null &&
        lastUsedAge >= options.unusedDaysThreshold &&
        !s.hasContractLock) {
      verdict = SubscriptionVerdict.pauseOneMonth;
      suggested =
          'Pause for one month — re-evaluate if you re-engage with it.';
      projectedSavings = s.monthlyCost;
    } else if (risk >= 30) {
      verdict = SubscriptionVerdict.watch;
      suggested = 'Watch for one cycle — usage is borderline.';
    } else {
      verdict = SubscriptionVerdict.keep;
      suggested = 'Keep — usage justifies the cost.';
    }

    return SubscriptionForecast(
      id: s.id,
      name: s.name,
      category: s.category,
      monthlyCost: s.monthlyCost,
      verdict: verdict,
      daysSinceLastUse: lastUsedAge,
      costPerUse: cpu,
      rotationRisk: risk,
      projectedMonthlySavings: projectedSavings,
      suggestedAction: suggested,
      reasons: reasons,
    );
  }

  // ---- portfolio aggregates ----

  SubscriptionPortfolioBand _bandFor(double bloat) {
    if (bloat >= 70) return SubscriptionPortfolioBand.severelyBloated;
    if (bloat >= 45) return SubscriptionPortfolioBand.bloated;
    if (bloat >= 20) return SubscriptionPortfolioBand.healthy;
    return SubscriptionPortfolioBand.lean;
  }

  String _gradeFor(double bloat, List<SubscriptionForecast> fs) {
    final cancelCount =
        fs.where((f) => f.verdict == SubscriptionVerdict.cancelNow).length;
    if (bloat >= 75 || cancelCount >= 4) return 'F';
    if (bloat >= 55 || cancelCount >= 2) return 'D';
    if (bloat >= 35) return 'C';
    if (bloat >= 18) return 'B';
    return 'A';
  }

  List<String> _insights(
    List<SubscriptionForecast> fs,
    double totalCost,
    Map<String, List<SubscriptionSnapshot>> byCategory,
    RotationOptions options,
    DateTime now,
  ) {
    final out = <String>[];
    final cancel =
        fs.where((f) => f.verdict == SubscriptionVerdict.cancelNow).toList();
    if (cancel.length >= 3) {
      out.add('HIGH_CANCEL_RECOMMENDATION_COUNT:${cancel.length}');
    }
    final swap = fs
        .where((f) => f.verdict == SubscriptionVerdict.swapToAlternative)
        .toList();
    if (swap.isNotEmpty) {
      out.add('SWAP_OPPORTUNITIES:${swap.length}');
    }
    final dupCats = byCategory.entries
        .where((e) => e.value.length >= 2)
        .map((e) => e.key)
        .toList();
    if (dupCats.isNotEmpty) {
      dupCats.sort();
      out.add('DUPLICATE_CATEGORIES:${dupCats.join(",")}');
    }
    final trial = fs.where((f) =>
        f.reasons.contains('FREE_TRIAL_ENDING_SOON')).toList();
    if (trial.isNotEmpty) {
      out.add('TRIALS_ENDING_SOON:${trial.length}');
    }
    final renew = fs
        .where((f) => f.reasons.contains('RENEWS_WITHIN_7D'))
        .toList();
    if (renew.isNotEmpty) {
      out.add('RENEWALS_WITHIN_7D:${renew.length}');
    }
    final keepShare =
        fs.where((f) => f.verdict == SubscriptionVerdict.keep).length /
            math.max(fs.length, 1);
    if (keepShare >= 0.9) out.add('LEAN_PORTFOLIO');
    if (out.isEmpty) out.add('NO_NOTABLE_SIGNALS');
    return out;
  }

  List<RotationAction> _playbook(
    List<SubscriptionForecast> fs,
    RotationOptions options,
    double projectedSavings,
  ) {
    final out = <RotationAction>[];
    final cancels = fs
        .where((f) => f.verdict == SubscriptionVerdict.cancelNow)
        .toList();
    final pauses = fs
        .where((f) => f.verdict == SubscriptionVerdict.pauseOneMonth)
        .toList();
    final downgrades = fs
        .where((f) => f.verdict == SubscriptionVerdict.downgradeTier)
        .toList();
    final swaps = fs
        .where((f) => f.verdict == SubscriptionVerdict.swapToAlternative)
        .toList();
    final trials = fs
        .where((f) => f.reasons.contains('FREE_TRIAL_ENDING_SOON'))
        .toList();

    if (trials.isNotEmpty) {
      out.add(RotationAction(
        priority: SubscriptionPriority.p0,
        code: 'CANCEL_BEFORE_TRIAL_AUTORENEW',
        label: 'Cancel ${trials.length} trial(s) before auto-renew',
        reason: 'Free trial ends within 72h and usage is low.',
        owner: 'user',
        blastRadius: 2,
        reversibility: 'high',
        relatedIds: trials.map((f) => f.id).toList(),
        projectedSavings:
            trials.fold<double>(0.0, (s, f) => s + f.monthlyCost),
      ));
    }

    if (cancels.isNotEmpty) {
      out.add(RotationAction(
        priority: SubscriptionPriority.p0,
        code: 'CANCEL_UNUSED_SUBSCRIPTIONS',
        label: 'Cancel ${cancels.length} unused subscription(s)',
        reason: 'No recent usage AND no contract lock — straight savings.',
        owner: 'user',
        blastRadius: 3,
        reversibility: 'medium',
        relatedIds: cancels.map((f) => f.id).toList(),
        projectedSavings:
            cancels.fold<double>(0.0, (s, f) => s + f.projectedMonthlySavings),
      ));
    }

    if (swaps.isNotEmpty) {
      out.add(RotationAction(
        priority: SubscriptionPriority.p1,
        code: 'SWAP_TO_CHEAPER_ALTERNATIVE',
        label: 'Swap ${swaps.length} subscription(s) to cheaper alternatives',
        reason: 'A documented cheaper alternative exists for each.',
        owner: 'user',
        blastRadius: 2,
        reversibility: 'medium',
        relatedIds: swaps.map((f) => f.id).toList(),
        projectedSavings:
            swaps.fold<double>(0.0, (s, f) => s + f.projectedMonthlySavings),
      ));
    }

    if (downgrades.isNotEmpty) {
      out.add(RotationAction(
        priority: SubscriptionPriority.p1,
        code: 'DOWNGRADE_OVERSPECCED_TIERS',
        label: 'Downgrade ${downgrades.length} oversized plan(s)',
        reason: 'Usage is too low to justify current tier.',
        owner: 'user',
        blastRadius: 2,
        reversibility: 'high',
        relatedIds: downgrades.map((f) => f.id).toList(),
        projectedSavings: downgrades.fold<double>(
            0.0, (s, f) => s + f.projectedMonthlySavings),
      ));
    }

    if (pauses.isNotEmpty) {
      out.add(RotationAction(
        priority: SubscriptionPriority.p2,
        code: 'PAUSE_FOR_ONE_CYCLE',
        label: 'Pause ${pauses.length} subscription(s) for one cycle',
        reason: 'Borderline usage — pause and re-evaluate next month.',
        owner: 'user',
        blastRadius: 2,
        reversibility: 'high',
        relatedIds: pauses.map((f) => f.id).toList(),
        projectedSavings:
            pauses.fold<double>(0.0, (s, f) => s + f.projectedMonthlySavings),
      ));
    }

    final renewSoon = fs
        .where((f) => f.reasons.contains('RENEWS_WITHIN_7D'))
        .map((f) => f.id)
        .toList();
    if (renewSoon.isNotEmpty) {
      out.add(RotationAction(
        priority: SubscriptionPriority.p1,
        code: 'ACT_BEFORE_RENEWAL_WINDOW',
        label: 'Resolve ${renewSoon.length} subscription(s) before renewal',
        reason: 'Each renews within 7 days — decisions are time-sensitive.',
        owner: 'user',
        blastRadius: 1,
        reversibility: 'high',
        relatedIds: renewSoon,
      ));
    }

    if (options.riskAppetite == SubscriptionRiskAppetite.cautious) {
      out.add(const RotationAction(
        priority: SubscriptionPriority.p2,
        code: 'SCHEDULE_QUARTERLY_AUDIT',
        label: 'Schedule a quarterly subscription audit',
        reason: 'Cautious appetite — codify a recurring review cadence.',
        owner: 'user',
        blastRadius: 1,
        reversibility: 'high',
      ));
    }

    final hasHigh =
        out.any((a) => a.priority == SubscriptionPriority.p0 ||
            a.priority == SubscriptionPriority.p1);
    if (!hasHigh) {
      out.add(const RotationAction(
        priority: SubscriptionPriority.p3,
        code: 'MAINTAIN_PORTFOLIO_HEALTH',
        label: 'Portfolio looks lean — maintain current discipline',
        reason: 'No high-priority rotation actions surfaced this cycle.',
        owner: 'user',
        blastRadius: 1,
        reversibility: 'high',
      ));
    }

    if (options.riskAppetite == SubscriptionRiskAppetite.aggressive) {
      out.removeWhere((a) => a.priority == SubscriptionPriority.p3 && hasHigh);
    }

    out.sort((a, b) {
      final p = _priorityRank(a.priority).compareTo(_priorityRank(b.priority));
      if (p != 0) return p;
      return a.code.compareTo(b.code);
    });
    return out;
  }

  String _headline(
    String grade,
    SubscriptionPortfolioBand band,
    List<SubscriptionForecast> forecasts,
    double projectedSavings,
  ) {
    final cancel = forecasts
        .where((f) => f.verdict == SubscriptionVerdict.cancelNow)
        .length;
    return 'SUBSCRIPTION_ROTATION grade=$grade band=${_bandName(band)} '
        'cancel=$cancel save=\$${_round2(projectedSavings)}/mo';
  }

  // ---- renderers ----

  String toText(SubscriptionRotationReport r) {
    final buf = StringBuffer()
      ..writeln(r.headline)
      ..writeln(
          'Total: ${r.totalSubscriptions} subs, \$${_round2(r.totalMonthlyCost)}/mo')
      ..writeln('Projected savings: \$${_round2(r.projectedMonthlySavings)}/mo')
      ..writeln('Bloat score: ${_round2(r.portfolioBloatScore)}/100')
      ..writeln('Insights: ${r.insights.join(", ")}')
      ..writeln('')
      ..writeln('Forecasts:');
    for (final f in r.forecasts) {
      buf.writeln('- [${_verdictName(f.verdict)}] ${f.name} '
          '(\$${_round2(f.monthlyCost)}/mo, risk=${_round2(f.rotationRisk)}) '
          '=> ${f.suggestedAction}');
    }
    buf.writeln('')..writeln('Playbook:');
    for (final a in r.playbook) {
      buf.writeln(
          '- [${_priorityName(a.priority)}] ${a.code}: ${a.label} '
          '(save \$${_round2(a.projectedSavings)}/mo)');
    }
    return buf.toString();
  }

  String toMarkdown(SubscriptionRotationReport r) {
    final buf = StringBuffer()
      ..writeln('# Subscription Rotation Advisor')
      ..writeln('')
      ..writeln('**${r.headline}**')
      ..writeln('')
      ..writeln('## Summary')
      ..writeln('')
      ..writeln('| metric | value |')
      ..writeln('| --- | --- |')
      ..writeln('| total_subscriptions | ${r.totalSubscriptions} |')
      ..writeln('| total_monthly_cost | \$${_round2(r.totalMonthlyCost)} |')
      ..writeln(
          '| projected_monthly_savings | \$${_round2(r.projectedMonthlySavings)} |')
      ..writeln(
          '| portfolio_bloat_score | ${_round2(r.portfolioBloatScore)} |')
      ..writeln('| band | ${_bandName(r.band)} |')
      ..writeln('| grade | ${r.grade} |')
      ..writeln('')
      ..writeln('## Forecasts')
      ..writeln('')
      ..writeln('| id | name | verdict | risk | save/mo | reasons |')
      ..writeln('| --- | --- | --- | --- | --- | --- |');
    for (final f in r.forecasts) {
      buf.writeln(
          '| ${_md(f.id)} | ${_md(f.name)} | ${_verdictName(f.verdict)} | '
          '${_round2(f.rotationRisk)} | \$${_round2(f.projectedMonthlySavings)} | '
          '${_md(f.reasons.join(", "))} |');
    }
    buf
      ..writeln('')
      ..writeln('## Playbook')
      ..writeln('')
      ..writeln('| priority | code | label | save/mo |')
      ..writeln('| --- | --- | --- | --- |');
    for (final a in r.playbook) {
      buf.writeln('| ${_priorityName(a.priority)} | ${_md(a.code)} | '
          '${_md(a.label)} | \$${_round2(a.projectedSavings)} |');
    }
    buf
      ..writeln('')
      ..writeln('## Insights')
      ..writeln('');
    for (final ins in r.insights) {
      buf.writeln('- ${_md(ins)}');
    }
    return buf.toString();
  }

  String toJson(SubscriptionRotationReport r) {
    return const JsonEncoder.withIndent('  ').convert(r.toJsonMap());
  }
}

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

String _verdictName(SubscriptionVerdict v) => switch (v) {
      SubscriptionVerdict.keep => 'KEEP',
      SubscriptionVerdict.downgradeTier => 'DOWNGRADE_TIER',
      SubscriptionVerdict.pauseOneMonth => 'PAUSE_ONE_MONTH',
      SubscriptionVerdict.cancelNow => 'CANCEL_NOW',
      SubscriptionVerdict.swapToAlternative => 'SWAP_TO_ALTERNATIVE',
      SubscriptionVerdict.watch => 'WATCH',
      SubscriptionVerdict.insufficientData => 'INSUFFICIENT_DATA',
    };

int _verdictRank(SubscriptionVerdict v) => switch (v) {
      SubscriptionVerdict.cancelNow => 0,
      SubscriptionVerdict.swapToAlternative => 1,
      SubscriptionVerdict.downgradeTier => 2,
      SubscriptionVerdict.pauseOneMonth => 3,
      SubscriptionVerdict.watch => 4,
      SubscriptionVerdict.keep => 5,
      SubscriptionVerdict.insufficientData => 6,
    };

String _priorityName(SubscriptionPriority p) => switch (p) {
      SubscriptionPriority.p0 => 'P0',
      SubscriptionPriority.p1 => 'P1',
      SubscriptionPriority.p2 => 'P2',
      SubscriptionPriority.p3 => 'P3',
    };

int _priorityRank(SubscriptionPriority p) => switch (p) {
      SubscriptionPriority.p0 => 0,
      SubscriptionPriority.p1 => 1,
      SubscriptionPriority.p2 => 2,
      SubscriptionPriority.p3 => 3,
    };

String _appetiteName(SubscriptionRiskAppetite a) => switch (a) {
      SubscriptionRiskAppetite.cautious => 'cautious',
      SubscriptionRiskAppetite.balanced => 'balanced',
      SubscriptionRiskAppetite.aggressive => 'aggressive',
    };

String _bandName(SubscriptionPortfolioBand b) => switch (b) {
      SubscriptionPortfolioBand.lean => 'lean',
      SubscriptionPortfolioBand.healthy => 'healthy',
      SubscriptionPortfolioBand.bloated => 'bloated',
      SubscriptionPortfolioBand.severelyBloated => 'severely_bloated',
    };

double _round2(double v) => double.parse(v.toStringAsFixed(2));

String _md(String s) => s.replaceAll('|', '\\|');
