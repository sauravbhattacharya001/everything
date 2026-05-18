/// Energy Budget Planner Service — agentic daily energy/calendar load advisor.
///
/// Most planners only ask "does this event fit in my calendar?". The harder
/// question users actually live is "does this *day* fit in my body?" — a
/// calendar packed full of meetings, deep work, errands, and an evening social
/// commitment can technically be free of overlap and still leave the user
/// fried by 4 PM. This service answers:
///
///   "Given today's planned events, my recent sleep/mood/workload, and how
///    much energy I usually have, which events should I keep as anchors,
///    which should I shorten or reschedule, and where do I need recovery
///    buffers — without breaking the things that actually matter?"
///
/// It is a sibling of [GoalPortfolioOptimizerService] (which trades off goals
/// across a *week*) and [HabitMomentumService] (which protects streaks across
/// many habits). This service operates on the *daily* layer — what to do with
/// the next 16 waking hours.
///
/// Pipeline:
///   1. Estimate per-event energy cost from duration, [EventKind] weight,
///      and back-to-back density.
///   2. Apply context modifiers to the effective daily budget (sleep debt,
///      low mood, recent workload roll, risk appetite).
///   3. Walk events earliest-first, assigning a verdict per event:
///        KEEP_ANCHOR / KEEP / SHORTEN / RESCHEDULE / DECLINE_OR_DELEGATE.
///   4. Insert up to [maxBufferInserts] synthetic `BUFFER_INSERT` recovery
///      slots between dense back-to-back stretches.
///   5. Compute `dayLoadScore` (0..100, % of effective budget consumed after
///      recommendations), classify into a band (UNDER_USED / BALANCED /
///      TIGHT / OVERLOADED / UNSAFE), and assign an A–F grade.
///   6. Emit a P0/P1/P2 playbook (`RESCHEDULE_LOW_PRIORITY`,
///      `INSERT_RECOVERY_BUFFER`, `MOVE_DEEP_WORK_TO_PEAK`,
///      `PROTECT_SLEEP_TONIGHT`, `BATCH_SHALLOW_MEETINGS`, ...).
///   7. Emit autonomous cross-event insights (meeting-heavy day,
///      no-deep-work, sleep-debt amplifier, low-mood amplifier,
///      cascade-risk).
///
/// Pure Dart, no Flutter / persistence dependency. Deterministic given a
/// fixed [now]. Never mutates input lists. Powers widgets, headless cron
/// summaries, and unit tests from the same code path.
library;

import 'dart:math' as math;

/// A single planned event for the day.
class PlannedEvent {
  final String id;
  final String title;
  final DateTime start;
  final Duration duration;
  final EventKind kind;

  /// 1 (low) .. 5 (critical). Anchors are usually 4-5 but priority is
  /// independent of `isAnchor`.
  final int priority;

  /// If true, the event cannot be RESCHEDULED, SHORTENED, or DECLINED.
  final bool isAnchor;

  const PlannedEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.duration,
    this.kind = EventKind.meeting,
    this.priority = 3,
    this.isAnchor = false,
  });
}

/// The kind of event — drives the base energy weight per minute.
enum EventKind {
  deepWork,
  meeting,
  admin,
  exercise,
  social,
  learning,
  errand,
  breakSlot,
}

/// Risk appetite shifts thresholds and the effective daily budget.
enum EnergyRiskAppetite { cautious, balanced, aggressive }

/// Optional ambient context for the day. Sensible defaults if omitted.
class EnergyContext {
  /// Hours slept the previous night. <6h shrinks the effective budget.
  final double sleepHoursLastNight;

  /// 1 (terrible) .. 5 (great). <=2 shrinks the effective budget.
  final int mood;

  /// 0..1 rolling exhaustion proxy (avg of last 7 days load).
  final double recentWorkloadIndex;

  /// Hour-of-day (0..23) where the user does their best deep work.
  final int chronotypePeakHour;

  const EnergyContext({
    this.sleepHoursLastNight = 7.5,
    this.mood = 3,
    this.recentWorkloadIndex = 0.5,
    this.chronotypePeakHour = 10,
  });
}

/// Per-event verdict after the planner has reasoned about it.
enum EnergyEventVerdict {
  keepAnchor,
  keep,
  shorten,
  reschedule,
  declineOrDelegate,
  bufferInsert,
}

/// Day-load band classifying the whole day.
enum EnergyDayBand {
  underUsed,
  balanced,
  tight,
  overloaded,
  unsafe,
}

/// Playbook action priority.
enum EnergyActionPriority { p0, p1, p2 }

class EnergyEventDecision {
  final String id;
  final String title;
  final DateTime start;
  final Duration originalDuration;
  final Duration recommendedDuration;
  final EventKind kind;
  final int priority;
  final bool isAnchor;
  final double estimatedCost;
  final EnergyEventVerdict verdict;
  final List<String> reasons;

  /// True for synthetic recovery slots the planner inserted (verdict
  /// [EnergyEventVerdict.bufferInsert]).
  final bool synthetic;

  const EnergyEventDecision({
    required this.id,
    required this.title,
    required this.start,
    required this.originalDuration,
    required this.recommendedDuration,
    required this.kind,
    required this.priority,
    required this.isAnchor,
    required this.estimatedCost,
    required this.verdict,
    required this.reasons,
    this.synthetic = false,
  });
}

class EnergyAction {
  final EnergyActionPriority priority;
  final String code;
  final String headline;
  final String detail;
  final String owner;
  final int blastRadius; // 1..5
  final String reversibility; // low | medium | high
  final List<String> eventIds;

  const EnergyAction({
    required this.priority,
    required this.code,
    required this.headline,
    required this.detail,
    this.owner = 'user',
    this.blastRadius = 2,
    this.reversibility = 'high',
    this.eventIds = const [],
  });
}

class EnergyDayPlan {
  final DateTime generatedAt;
  final double dailyBudget;
  final double effectiveBudget;
  final double consumedEnergy;
  final double dayLoadScore; // 0..100, can clamp 100 on overload
  final EnergyDayBand band;
  final String grade;
  final String summary;
  final List<EnergyEventDecision> items;
  final List<EnergyAction> playbook;
  final List<String> insights;

  const EnergyDayPlan({
    required this.generatedAt,
    required this.dailyBudget,
    required this.effectiveBudget,
    required this.consumedEnergy,
    required this.dayLoadScore,
    required this.band,
    required this.grade,
    required this.summary,
    required this.items,
    required this.playbook,
    required this.insights,
  });
}

/// Agentic per-day energy/calendar load planner.
class EnergyBudgetPlannerService {
  final DateTime Function() now;
  final double dailyBudget;
  final int maxBufferInserts;

  EnergyBudgetPlannerService({
    DateTime Function()? now,
    this.dailyBudget = 100,
    this.maxBufferInserts = 2,
  }) : now = now ?? DateTime.now;

  /// Per-minute energy cost by event kind (units / minute).
  static const Map<EventKind, double> _kindWeight = {
    EventKind.deepWork: 0.55,
    EventKind.meeting: 0.45,
    EventKind.admin: 0.20,
    EventKind.exercise: 0.50,
    EventKind.social: 0.35,
    EventKind.learning: 0.40,
    EventKind.errand: 0.25,
    EventKind.breakSlot: -0.15, // a real break refunds a bit of energy
  };

  /// Analyze the day's planned events and return a full plan.
  EnergyDayPlan analyze(
    List<PlannedEvent> events, {
    EnergyContext? context,
    EnergyRiskAppetite appetite = EnergyRiskAppetite.balanced,
  }) {
    final ctx = context ?? const EnergyContext();
    final generatedAt = now();

    // Snapshot + sort copy (never mutate caller's list).
    final sorted = [...events]
      ..sort((a, b) {
        final c = a.start.compareTo(b.start);
        return c != 0 ? c : a.id.compareTo(b.id);
      });

    // Compute effective budget.
    final effective = _effectiveBudget(ctx, appetite);

    // Cost per event (factoring back-to-back density).
    final baseCosts = <String, double>{};
    for (int i = 0; i < sorted.length; i++) {
      baseCosts[sorted[i].id] = _baseCost(sorted[i], i, sorted);
    }

    // Walk events earliest-first, assigning verdicts and tracking consumption.
    final decisions = <EnergyEventDecision>[];
    double consumed = 0;
    for (final e in sorted) {
      final cost = baseCosts[e.id]!;
      final remaining = effective - consumed;
      final decision = _decide(
        event: e,
        cost: cost,
        remaining: remaining,
        effective: effective,
        appetite: appetite,
        ctx: ctx,
      );
      decisions.add(decision);
      consumed += decision.estimatedCost;
    }

    // Insert synthetic recovery buffers between dense stretches.
    final withBuffers = _insertBuffers(decisions);

    // Day load + band + grade.
    final loadScore = effective <= 0 ? 100.0 : (consumed / effective) * 100.0;
    final clampedLoad = loadScore.clamp(0.0, 150.0).toDouble();
    final band = _band(clampedLoad, appetite);
    final grade = _grade(band, decisions);

    // Playbook + insights.
    final playbook = _playbook(
      decisions: decisions,
      ctx: ctx,
      band: band,
      appetite: appetite,
      effective: effective,
      consumed: consumed,
    );
    final insights = _insights(
      decisions: decisions,
      ctx: ctx,
      band: band,
      effective: effective,
      consumed: consumed,
    );

    // Final items list: original decisions (sorted by start) + buffer inserts
    // appended at the end so they are easy to filter / display separately.
    final realItems = [...decisions]
      ..sort((a, b) {
        final c = a.start.compareTo(b.start);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    final allItems = [...realItems, ...withBuffers];

    final summary = _summary(
      decisions: decisions,
      band: band,
      grade: grade,
      effective: effective,
      consumed: consumed,
    );

    return EnergyDayPlan(
      generatedAt: generatedAt,
      dailyBudget: dailyBudget,
      effectiveBudget: effective,
      consumedEnergy: consumed,
      dayLoadScore: clampedLoad,
      band: band,
      grade: grade,
      summary: summary,
      items: allItems,
      playbook: playbook,
      insights: insights,
    );
  }

  // ------------------------------------------------------------------ scoring

  double _effectiveBudget(EnergyContext ctx, EnergyRiskAppetite a) {
    double mult = 1.0;
    // Sleep debt: <6h is significant; <5h is critical.
    if (ctx.sleepHoursLastNight < 5) {
      mult -= 0.30;
    } else if (ctx.sleepHoursLastNight < 6) {
      mult -= 0.18;
    } else if (ctx.sleepHoursLastNight < 7) {
      mult -= 0.08;
    } else if (ctx.sleepHoursLastNight >= 8.5) {
      mult += 0.05;
    }
    // Mood.
    if (ctx.mood <= 1) {
      mult -= 0.20;
    } else if (ctx.mood == 2) {
      mult -= 0.10;
    } else if (ctx.mood >= 5) {
      mult += 0.05;
    }
    // Rolling workload exhaustion.
    if (ctx.recentWorkloadIndex >= 0.85) {
      mult -= 0.15;
    } else if (ctx.recentWorkloadIndex >= 0.70) {
      mult -= 0.08;
    } else if (ctx.recentWorkloadIndex <= 0.20) {
      mult += 0.05;
    }
    // Risk appetite final shift.
    switch (a) {
      case EnergyRiskAppetite.cautious:
        mult -= 0.10;
        break;
      case EnergyRiskAppetite.balanced:
        break;
      case EnergyRiskAppetite.aggressive:
        mult += 0.10;
        break;
    }
    final eff = dailyBudget * mult;
    return eff < 10 ? 10 : eff;
  }

  double _baseCost(PlannedEvent e, int idx, List<PlannedEvent> sorted) {
    final minutes = e.duration.inMinutes.toDouble();
    final w = _kindWeight[e.kind] ?? 0.30;
    double cost = minutes * w;

    // Back-to-back penalty: if previous event ends within 5 min of this start,
    // tack on +10% cost for cognitive switch.
    if (idx > 0) {
      final prev = sorted[idx - 1];
      final gapMin = e.start
              .difference(prev.start.add(prev.duration))
              .inMinutes;
      if (gapMin <= 5) {
        cost *= 1.10;
      }
    }

    // Sub-15-minute events still cost a minimum (context switching).
    if (e.kind != EventKind.breakSlot && cost < 2) {
      cost = 2;
    }
    return cost;
  }

  EnergyEventDecision _decide({
    required PlannedEvent event,
    required double cost,
    required double remaining,
    required double effective,
    required EnergyRiskAppetite appetite,
    required EnergyContext ctx,
  }) {
    final reasons = <String>[];
    var verdict = EnergyEventVerdict.keep;
    var recommended = event.duration;
    var finalCost = cost;

    // Anchors always KEEP_ANCHOR (cannot be shortened or moved).
    if (event.isAnchor) {
      verdict = EnergyEventVerdict.keepAnchor;
      reasons.add('Anchor event — protected from reshuffling.');
      // Deep-work outside peak still flagged as a reason but anchor wins.
      if (event.kind == EventKind.deepWork &&
          (event.start.hour - ctx.chronotypePeakHour).abs() >= 3) {
        reasons.add('Deep work scheduled outside chronotype peak hour '
            '(${ctx.chronotypePeakHour}:00) — accept reduced output.');
      }
      return EnergyEventDecision(
        id: event.id,
        title: event.title,
        start: event.start,
        originalDuration: event.duration,
        recommendedDuration: event.duration,
        kind: event.kind,
        priority: event.priority,
        isAnchor: true,
        estimatedCost: cost,
        verdict: verdict,
        reasons: reasons,
      );
    }

    // Over-budget logic.
    final shortenThreshold = appetite == EnergyRiskAppetite.cautious
        ? 0.85
        : appetite == EnergyRiskAppetite.aggressive
            ? 1.05
            : 0.95;

    if (cost > remaining && remaining > 0) {
      // Doesn't fit cleanly.
      if (event.priority <= 2) {
        verdict = EnergyEventVerdict.reschedule;
        reasons.add('Low-priority (${event.priority}) event over remaining '
            'budget — better moved to a lighter day.');
        finalCost = 0; // assumed moved
      } else {
        // Try shortening to fit within shortenThreshold * remaining.
        final target = remaining * shortenThreshold;
        final ratio = target / cost;
        if (ratio >= 0.4) {
          final newMin = (event.duration.inMinutes * ratio)
              .clamp(15, event.duration.inMinutes)
              .round();
          recommended = Duration(minutes: newMin);
          finalCost = cost * (newMin / event.duration.inMinutes);
          verdict = EnergyEventVerdict.shorten;
          reasons.add(
              'Trimmed from ${event.duration.inMinutes}m to ${newMin}m to fit '
              'remaining ${remaining.toStringAsFixed(0)} energy units.');
        } else {
          verdict = EnergyEventVerdict.declineOrDelegate;
          reasons.add(
              'Cannot meaningfully shorten — decline or delegate to free the '
              'day.');
          finalCost = 0;
        }
      }
    } else if (remaining <= 0) {
      // Already over.
      if (event.priority >= 4) {
        verdict = EnergyEventVerdict.shorten;
        final newMin = math.max(15, (event.duration.inMinutes * 0.5).round());
        recommended = Duration(minutes: newMin);
        finalCost = cost * (newMin / event.duration.inMinutes);
        reasons.add(
            'Budget already exhausted but priority is ${event.priority} — '
            'kept at half length.');
      } else if (event.priority <= 2) {
        verdict = EnergyEventVerdict.declineOrDelegate;
        reasons.add('No budget remaining for low-priority work — decline.');
        finalCost = 0;
      } else {
        verdict = EnergyEventVerdict.reschedule;
        reasons.add('Budget exhausted — push to tomorrow.');
        finalCost = 0;
      }
    }

    // Deep-work-off-peak hint (informational; does not change verdict for
    // non-anchor unless KEEP).
    if (event.kind == EventKind.deepWork &&
        (event.start.hour - ctx.chronotypePeakHour).abs() >= 3 &&
        verdict == EnergyEventVerdict.keep) {
      reasons.add('Deep work scheduled outside chronotype peak hour '
          '(${ctx.chronotypePeakHour}:00) — consider moving.');
    }

    if (reasons.isEmpty) {
      reasons.add('Fits within remaining budget.');
    }

    return EnergyEventDecision(
      id: event.id,
      title: event.title,
      start: event.start,
      originalDuration: event.duration,
      recommendedDuration: recommended,
      kind: event.kind,
      priority: event.priority,
      isAnchor: event.isAnchor,
      estimatedCost: finalCost,
      verdict: verdict,
      reasons: reasons,
    );
  }

  List<EnergyEventDecision> _insertBuffers(
    List<EnergyEventDecision> decisions,
  ) {
    if (maxBufferInserts <= 0 || decisions.length < 3) return const [];
    final buffers = <EnergyEventDecision>[];
    // Look for runs of >=3 consecutive events with <15 min gap that
    // weren't already dropped (reschedule/decline => cost 0).
    final active = decisions
        .where((d) =>
            d.verdict != EnergyEventVerdict.reschedule &&
            d.verdict != EnergyEventVerdict.declineOrDelegate)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    int runStart = 0;
    int idx = 0;
    while (idx < active.length && buffers.length < maxBufferInserts) {
      if (idx == 0) {
        idx++;
        continue;
      }
      final prev = active[idx - 1];
      final cur = active[idx];
      final gap = cur.start
          .difference(prev.start.add(prev.recommendedDuration))
          .inMinutes;
      if (gap < 15) {
        // continue run
        if (idx - runStart + 1 >= 3) {
          // Insert buffer after `prev` (between prev and cur).
          final bStart = prev.start.add(prev.recommendedDuration);
          buffers.add(EnergyEventDecision(
            id: 'buffer_${buffers.length}',
            title: 'Recovery buffer',
            start: bStart,
            originalDuration: const Duration(minutes: 15),
            recommendedDuration: const Duration(minutes: 15),
            kind: EventKind.breakSlot,
            priority: 3,
            isAnchor: false,
            estimatedCost: -2.0,
            verdict: EnergyEventVerdict.bufferInsert,
            reasons: const [
              'Inserted between back-to-back events to prevent cascade '
                  'fatigue (3+ in a row with <15 min gap).',
            ],
            synthetic: true,
          ));
          runStart = idx; // restart counting after this buffer
        }
      } else {
        runStart = idx;
      }
      idx++;
    }
    return buffers;
  }

  EnergyDayBand _band(double load, EnergyRiskAppetite a) {
    double shift = 0;
    switch (a) {
      case EnergyRiskAppetite.cautious:
        shift = -8;
        break;
      case EnergyRiskAppetite.balanced:
        break;
      case EnergyRiskAppetite.aggressive:
        shift = 8;
        break;
    }
    final l = load - shift;
    if (l < 35) return EnergyDayBand.underUsed;
    if (l < 70) return EnergyDayBand.balanced;
    if (l < 90) return EnergyDayBand.tight;
    if (l < 110) return EnergyDayBand.overloaded;
    return EnergyDayBand.unsafe;
  }

  String _grade(EnergyDayBand band, List<EnergyEventDecision> decisions) {
    final anyDecline = decisions
        .any((d) => d.verdict == EnergyEventVerdict.declineOrDelegate);
    switch (band) {
      case EnergyDayBand.balanced:
        return 'A';
      case EnergyDayBand.underUsed:
        return 'B';
      case EnergyDayBand.tight:
        return anyDecline ? 'D' : 'C';
      case EnergyDayBand.overloaded:
        return 'D';
      case EnergyDayBand.unsafe:
        return 'F';
    }
  }

  List<EnergyAction> _playbook({
    required List<EnergyEventDecision> decisions,
    required EnergyContext ctx,
    required EnergyDayBand band,
    required EnergyRiskAppetite appetite,
    required double effective,
    required double consumed,
  }) {
    final out = <EnergyAction>[];
    final reschedule = decisions
        .where((d) => d.verdict == EnergyEventVerdict.reschedule)
        .toList();
    final decline = decisions
        .where((d) => d.verdict == EnergyEventVerdict.declineOrDelegate)
        .toList();
    final shorten =
        decisions.where((d) => d.verdict == EnergyEventVerdict.shorten).toList();
    final offPeakDeep = decisions
        .where((d) =>
            d.kind == EventKind.deepWork &&
            (d.start.hour - ctx.chronotypePeakHour).abs() >= 3)
        .toList();

    // P0: unsafe-load => protect sleep tonight.
    if (band == EnergyDayBand.unsafe) {
      out.add(EnergyAction(
        priority: EnergyActionPriority.p0,
        code: 'PROTECT_SLEEP_TONIGHT',
        headline: 'Day is in the unsafe load band — protect sleep tonight',
        detail:
            'Effective budget exceeded by >10%. Push every non-anchor item '
            'after 19:00 and aim for >=8h sleep to avoid a 2-day debt spiral.',
        blastRadius: 3,
      ));
    }

    // P0: reschedule low-priority items.
    if (reschedule.isNotEmpty || decline.isNotEmpty) {
      out.add(EnergyAction(
        priority: EnergyActionPriority.p0,
        code: 'RESCHEDULE_LOW_PRIORITY',
        headline:
            'Move ${reschedule.length + decline.length} low-priority event'
            '${(reschedule.length + decline.length) == 1 ? "" : "s"} off today',
        detail:
            'These events were flagged because they push the day past safe '
            'load. Reschedule or delegate them to recover headroom for the '
            'anchors that actually matter.',
        eventIds: [...reschedule, ...decline].map((d) => d.id).toList(),
        blastRadius: 2,
      ));
    }

    // P1: insert recovery buffer when the planner already added one (or
    // would benefit from one).
    final backToBack = _countBackToBackRun(decisions);
    if (backToBack >= 3) {
      out.add(EnergyAction(
        priority: EnergyActionPriority.p1,
        code: 'INSERT_RECOVERY_BUFFER',
        headline: 'Insert 15-min recovery buffer in back-to-back stretch',
        detail:
            'You have $backToBack events in a row with <15 min between them. '
            'Drop in a 15-min walk or breathing break to reset attention.',
        blastRadius: 1,
      ));
    }

    // P1: move deep work to peak hour.
    if (offPeakDeep.isNotEmpty) {
      out.add(EnergyAction(
        priority: EnergyActionPriority.p1,
        code: 'MOVE_DEEP_WORK_TO_PEAK',
        headline:
            'Move deep-work block${offPeakDeep.length == 1 ? "" : "s"} to '
            '${ctx.chronotypePeakHour}:00 peak window',
        detail:
            'Deep work outside your chronotype peak (${ctx.chronotypePeakHour}'
            ':00) costs ~30% more energy per result. Swap with a meeting or '
            'admin block in the peak window.',
        eventIds: offPeakDeep.map((d) => d.id).toList(),
        blastRadius: 2,
      ));
    }

    // P1: protect sleep when sleep-debt already in play and day is tight+.
    if (ctx.sleepHoursLastNight < 6 &&
        (band == EnergyDayBand.tight ||
            band == EnergyDayBand.overloaded ||
            band == EnergyDayBand.unsafe)) {
      out.add(EnergyAction(
        priority: EnergyActionPriority.p1,
        code: 'PROTECT_SLEEP_TONIGHT',
        headline: 'Sleep debt + heavy day — protect tonight\'s sleep',
        detail:
            'You slept ${ctx.sleepHoursLastNight.toStringAsFixed(1)}h last '
            'night and today is ${band.name}. Cap evening commitments by '
            '21:00.',
        blastRadius: 2,
      ));
    }

    // P2: batch shallow meetings if 3+ admin/meeting back-to-back.
    final shallow = decisions
        .where((d) =>
            (d.kind == EventKind.meeting || d.kind == EventKind.admin) &&
            d.verdict != EnergyEventVerdict.reschedule &&
            d.verdict != EnergyEventVerdict.declineOrDelegate)
        .toList();
    if (shallow.length >= 4) {
      out.add(EnergyAction(
        priority: EnergyActionPriority.p2,
        code: 'BATCH_SHALLOW_MEETINGS',
        headline:
            'Batch ${shallow.length} shallow meeting/admin blocks together',
        detail:
            'Cluster meetings and admin into a single window so the rest of '
            'the day stays free for deep work and recovery.',
        eventIds: shallow.map((d) => d.id).toList(),
        blastRadius: 1,
      ));
    }

    // P2: SHORTEN already happened automatically — surface as a reminder.
    if (shorten.isNotEmpty) {
      out.add(EnergyAction(
        priority: EnergyActionPriority.p2,
        code: 'CONFIRM_SHORTENED_EVENTS',
        headline:
            'Confirm shortened length on ${shorten.length} event${shorten.length == 1 ? "" : "s"}',
        detail:
            'Auto-trimmed to fit remaining budget. Send a quick note to '
            'attendees so the shorter time is respected.',
        eventIds: shorten.map((d) => d.id).toList(),
        blastRadius: 2,
      ));
    }

    // De-dup by code+eventIds.
    final seen = <String>{};
    final dedup = <EnergyAction>[];
    for (final a in out) {
      final key = '${a.code}:${a.eventIds.join(",")}';
      if (seen.add(key)) dedup.add(a);
    }
    dedup.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return dedup;
  }

  List<String> _insights({
    required List<EnergyEventDecision> decisions,
    required EnergyContext ctx,
    required EnergyDayBand band,
    required double effective,
    required double consumed,
  }) {
    final out = <String>[];
    if (decisions.isEmpty) {
      out.add('No events planned — day is wide open.');
      return out;
    }

    final meetingShare = decisions
            .where((d) =>
                d.kind == EventKind.meeting &&
                d.verdict != EnergyEventVerdict.reschedule &&
                d.verdict != EnergyEventVerdict.declineOrDelegate)
            .length /
        decisions.length;
    if (meetingShare >= 0.6) {
      out.add(
          'Meeting-heavy day (${(meetingShare * 100).round()}% of events) — '
          'expect attention residue.');
    }

    final anyDeep = decisions.any((d) => d.kind == EventKind.deepWork);
    if (!anyDeep) {
      out.add(
          'No deep-work blocks scheduled — entire day is reactive work.');
    }

    if (ctx.sleepHoursLastNight < 6) {
      out.add(
          'Sleep-debt amplifier active (${ctx.sleepHoursLastNight.toStringAsFixed(1)}h '
          '< 6h) — effective budget reduced.');
    }
    if (ctx.mood <= 2) {
      out.add(
          'Low-mood amplifier active (mood=${ctx.mood}/5) — energy spend is '
          'noisier and recovery is slower.');
    }
    if (ctx.recentWorkloadIndex >= 0.8) {
      out.add(
          'Rolling 7-day workload index ${(ctx.recentWorkloadIndex * 100).round()}% — '
          'borderline burnout territory.');
    }

    final run = _countBackToBackRun(decisions);
    if (run >= 4) {
      out.add('Cascade risk: $run events back-to-back with <15 min gap.');
    }

    out.add(
        'Consumed ${consumed.toStringAsFixed(0)} of ${effective.toStringAsFixed(0)} effective energy units (${band.name}).');
    return out;
  }

  int _countBackToBackRun(List<EnergyEventDecision> decisions) {
    final active = decisions
        .where((d) =>
            d.verdict != EnergyEventVerdict.reschedule &&
            d.verdict != EnergyEventVerdict.declineOrDelegate)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    int best = 0;
    int run = 1;
    for (int i = 1; i < active.length; i++) {
      final prev = active[i - 1];
      final cur = active[i];
      final gap = cur.start
          .difference(prev.start.add(prev.recommendedDuration))
          .inMinutes;
      if (gap < 15) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return math.max(best, run);
  }

  String _summary({
    required List<EnergyEventDecision> decisions,
    required EnergyDayBand band,
    required String grade,
    required double effective,
    required double consumed,
  }) {
    final anchors =
        decisions.where((d) => d.verdict == EnergyEventVerdict.keepAnchor).length;
    final reschedule = decisions
        .where((d) =>
            d.verdict == EnergyEventVerdict.reschedule ||
            d.verdict == EnergyEventVerdict.declineOrDelegate)
        .length;
    return 'Day load ${(consumed / (effective <= 0 ? 1 : effective) * 100).round()}% '
        '(${band.name}, grade $grade) — $anchors anchor'
        '${anchors == 1 ? "" : "s"} protected, $reschedule item'
        '${reschedule == 1 ? "" : "s"} suggested off today.';
  }

  // ---------------------------------------------------------------- renderers

  String formatText(EnergyDayPlan plan) {
    final b = StringBuffer();
    b.writeln('Energy Budget Plan — ${_fmtDate(plan.generatedAt)}');
    b.writeln('Grade: ${plan.grade}   Band: ${plan.band.name}   '
        'Load: ${plan.dayLoadScore.toStringAsFixed(0)}%');
    b.writeln('Budget: ${plan.effectiveBudget.toStringAsFixed(0)} '
        '(raw ${plan.dailyBudget.toStringAsFixed(0)})   '
        'Consumed: ${plan.consumedEnergy.toStringAsFixed(0)}');
    b.writeln();
    b.writeln(plan.summary);
    b.writeln();
    b.writeln('Events:');
    for (final d in plan.items) {
      b.writeln('  ${_fmtTime(d.start)}  '
          '${d.title.padRight(28)}  '
          '${_verdictTag(d.verdict).padRight(20)} '
          'cost=${d.estimatedCost.toStringAsFixed(1)}');
      for (final r in d.reasons) {
        b.writeln('      - $r');
      }
    }
    if (plan.playbook.isNotEmpty) {
      b.writeln();
      b.writeln('Playbook:');
      for (final a in plan.playbook) {
        b.writeln('  [${a.priority.name.toUpperCase()}] ${a.headline}');
        b.writeln('      ${a.detail}');
      }
    }
    if (plan.insights.isNotEmpty) {
      b.writeln();
      b.writeln('Insights:');
      for (final i in plan.insights) {
        b.writeln('  • $i');
      }
    }
    return b.toString();
  }

  String formatMarkdown(EnergyDayPlan plan) {
    final b = StringBuffer();
    b.writeln('# Energy Budget Plan — ${_fmtDate(plan.generatedAt)}');
    b.writeln();
    b.writeln('## Day load');
    b.writeln();
    b.writeln('- **Grade:** ${plan.grade}');
    b.writeln('- **Band:** ${plan.band.name}');
    b.writeln(
        '- **Load:** ${plan.dayLoadScore.toStringAsFixed(0)}% of effective budget');
    b.writeln(
        '- **Effective budget:** ${plan.effectiveBudget.toStringAsFixed(0)} units '
        '(raw ${plan.dailyBudget.toStringAsFixed(0)})');
    b.writeln(
        '- **Consumed:** ${plan.consumedEnergy.toStringAsFixed(0)} units');
    b.writeln();
    b.writeln('> ${plan.summary}');
    b.writeln();

    b.writeln('## Events');
    b.writeln();
    b.writeln('| Time | Title | Verdict | Cost |');
    b.writeln('|------|-------|---------|------|');
    for (final d in plan.items) {
      b.writeln('| ${_fmtTime(d.start)} | ${d.title} | '
          '${_verdictTag(d.verdict)} | ${d.estimatedCost.toStringAsFixed(1)} |');
    }
    b.writeln();

    if (plan.playbook.isNotEmpty) {
      b.writeln('## Playbook');
      b.writeln();
      for (final a in plan.playbook) {
        b.writeln(
            '- **[${a.priority.name.toUpperCase()}] ${a.headline}** — ${a.detail}');
      }
      b.writeln();
    }

    if (plan.insights.isNotEmpty) {
      b.writeln('## Insights');
      b.writeln();
      for (final i in plan.insights) {
        b.writeln('- $i');
      }
      b.writeln();
    }
    return b.toString();
  }

  String _verdictTag(EnergyEventVerdict v) {
    switch (v) {
      case EnergyEventVerdict.keepAnchor:
        return 'KEEP_ANCHOR';
      case EnergyEventVerdict.keep:
        return 'KEEP';
      case EnergyEventVerdict.shorten:
        return 'SHORTEN';
      case EnergyEventVerdict.reschedule:
        return 'RESCHEDULE';
      case EnergyEventVerdict.declineOrDelegate:
        return 'DECLINE_OR_DELEGATE';
      case EnergyEventVerdict.bufferInsert:
        return 'BUFFER_INSERT';
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, "0")}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';
  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
}
