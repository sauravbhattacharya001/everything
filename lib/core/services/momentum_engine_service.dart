import 'dart:math';

import 'service_persistence.dart';

/// Momentum Engine — autonomous completion velocity tracker that monitors
/// task/habit/goal throughput, classifies momentum state, detects blockers,
/// and generates adaptive micro-nudges to sustain productive flow.
///
/// Core concepts:
/// - **Velocity**: rolling completion rate (completions per day) over windows
/// - **Acceleration**: change in velocity between windows (speeding up/slowing)
/// - **Momentum State**: classified phase (igniting/accelerating/cruising/coasting/stalling/crashed)
/// - **Blocker Detection**: identifies patterns causing momentum loss
/// - **Micro-Nudges**: context-aware, adaptive suggestions to maintain/recover momentum

// ---------------------------------------------------------------------------
// Enums & Constants
// ---------------------------------------------------------------------------

/// Momentum lifecycle phase.
enum MomentumPhase {
  igniting,
  accelerating,
  cruising,
  coasting,
  stalling,
  crashed;

  String get label {
    switch (this) {
      case MomentumPhase.igniting:
        return 'Igniting';
      case MomentumPhase.accelerating:
        return 'Accelerating';
      case MomentumPhase.cruising:
        return 'Cruising';
      case MomentumPhase.coasting:
        return 'Coasting';
      case MomentumPhase.stalling:
        return 'Stalling';
      case MomentumPhase.crashed:
        return 'Crashed';
    }
  }

  String get emoji {
    switch (this) {
      case MomentumPhase.igniting:
        return '🔥';
      case MomentumPhase.accelerating:
        return '🚀';
      case MomentumPhase.cruising:
        return '✈️';
      case MomentumPhase.coasting:
        return '🛶';
      case MomentumPhase.stalling:
        return '⚠️';
      case MomentumPhase.crashed:
        return '💥';
    }
  }

  /// Energy level 0-100.
  int get energyLevel {
    switch (this) {
      case MomentumPhase.igniting:
        return 60;
      case MomentumPhase.accelerating:
        return 90;
      case MomentumPhase.cruising:
        return 75;
      case MomentumPhase.coasting:
        return 50;
      case MomentumPhase.stalling:
        return 25;
      case MomentumPhase.crashed:
        return 5;
    }
  }

  /// Whether this phase is considered healthy.
  bool get isHealthy =>
      this == MomentumPhase.igniting ||
      this == MomentumPhase.accelerating ||
      this == MomentumPhase.cruising;
}

/// Category of completion event tracked.
enum CompletionCategory {
  habit,
  goal,
  task,
  milestone,
  challenge;

  String get label {
    switch (this) {
      case CompletionCategory.habit:
        return 'Habit';
      case CompletionCategory.goal:
        return 'Goal';
      case CompletionCategory.task:
        return 'Task';
      case CompletionCategory.milestone:
        return 'Milestone';
      case CompletionCategory.challenge:
        return 'Challenge';
    }
  }
}

/// Type of momentum blocker detected.
enum BlockerType {
  gapAfterWeekend,
  consistencyDrop,
  categoryAbandonment,
  overcommitment,
  timeOfDayShift,
  streakBreakSpiral;

  String get label {
    switch (this) {
      case BlockerType.gapAfterWeekend:
        return 'Post-Weekend Gap';
      case BlockerType.consistencyDrop:
        return 'Consistency Drop';
      case BlockerType.categoryAbandonment:
        return 'Category Abandonment';
      case BlockerType.overcommitment:
        return 'Overcommitment';
      case BlockerType.timeOfDayShift:
        return 'Time-of-Day Shift';
      case BlockerType.streakBreakSpiral:
        return 'Streak Break Spiral';
    }
  }

  String get description {
    switch (this) {
      case BlockerType.gapAfterWeekend:
        return 'Momentum drops after weekends — Monday restart friction';
      case BlockerType.consistencyDrop:
        return 'Overall completion rate declining steadily';
      case BlockerType.categoryAbandonment:
        return 'One or more categories have gone silent';
      case BlockerType.overcommitment:
        return 'Too many active items causing decision fatigue';
      case BlockerType.timeOfDayShift:
        return 'Peak completion time has shifted away from habit window';
      case BlockerType.streakBreakSpiral:
        return 'Broken streak triggered cascading disengagement';
    }
  }
}

/// Urgency of a nudge.
enum NudgeUrgency {
  gentle,
  encouraging,
  urgent,
  critical;

  String get emoji {
    switch (this) {
      case NudgeUrgency.gentle:
        return '💡';
      case NudgeUrgency.encouraging:
        return '💪';
      case NudgeUrgency.urgent:
        return '⏰';
      case NudgeUrgency.critical:
        return '🚨';
    }
  }
}

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

/// A single completion event logged by the engine.
class CompletionEvent {
  final DateTime timestamp;
  final CompletionCategory category;
  final String label;
  final double weight;

  const CompletionEvent({
    required this.timestamp,
    required this.category,
    required this.label,
    this.weight = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'category': category.index,
        'label': label,
        'weight': weight,
      };

  factory CompletionEvent.fromJson(Map<String, dynamic> json) => CompletionEvent(
        timestamp: DateTime.parse(json['timestamp'] as String),
        category: CompletionCategory.values[json['category'] as int],
        label: json['label'] as String,
        weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      );
}

/// Velocity measurement for a time window.
class VelocitySnapshot {
  final DateTime windowStart;
  final DateTime windowEnd;
  final double completionsPerDay;
  final double weightedCompletionsPerDay;
  final int totalCompletions;
  final Map<CompletionCategory, int> byCategory;

  const VelocitySnapshot({
    required this.windowStart,
    required this.windowEnd,
    required this.completionsPerDay,
    required this.weightedCompletionsPerDay,
    required this.totalCompletions,
    required this.byCategory,
  });
}

/// Detected momentum blocker.
class MomentumBlocker {
  final BlockerType type;
  final double confidence;
  final String evidence;
  final DateTime detectedAt;

  const MomentumBlocker({
    required this.type,
    required this.confidence,
    required this.evidence,
    required this.detectedAt,
  });

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'confidence': confidence,
        'evidence': evidence,
        'detectedAt': detectedAt.toIso8601String(),
      };

  factory MomentumBlocker.fromJson(Map<String, dynamic> json) => MomentumBlocker(
        type: BlockerType.values[json['type'] as int],
        confidence: (json['confidence'] as num).toDouble(),
        evidence: json['evidence'] as String,
        detectedAt: DateTime.parse(json['detectedAt'] as String),
      );
}

/// Adaptive micro-nudge generated by the engine.
class MicroNudge {
  final String message;
  final NudgeUrgency urgency;
  final CompletionCategory? targetCategory;
  final String? suggestedAction;
  final DateTime generatedAt;

  const MicroNudge({
    required this.message,
    required this.urgency,
    this.targetCategory,
    this.suggestedAction,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'urgency': urgency.index,
        'targetCategory': targetCategory?.index,
        'suggestedAction': suggestedAction,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory MicroNudge.fromJson(Map<String, dynamic> json) => MicroNudge(
        message: json['message'] as String,
        urgency: NudgeUrgency.values[json['urgency'] as int],
        targetCategory: json['targetCategory'] != null
            ? CompletionCategory.values[json['targetCategory'] as int]
            : null,
        suggestedAction: json['suggestedAction'] as String?,
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}

/// Full momentum report produced by [MomentumEngineService.analyze].
class MomentumReport {
  final MomentumPhase phase;
  final double currentVelocity;
  final double acceleration;
  final double momentumScore;
  final VelocitySnapshot shortWindow;
  final VelocitySnapshot longWindow;
  final List<MomentumBlocker> blockers;
  final List<MicroNudge> nudges;
  final Map<CompletionCategory, double> categoryHealth;
  final int daysSinceLastCompletion;
  final DateTime generatedAt;

  const MomentumReport({
    required this.phase,
    required this.currentVelocity,
    required this.acceleration,
    required this.momentumScore,
    required this.shortWindow,
    required this.longWindow,
    required this.blockers,
    required this.nudges,
    required this.categoryHealth,
    required this.daysSinceLastCompletion,
    required this.generatedAt,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Autonomous momentum tracking engine.
///
/// Feed it completion events, and it continuously classifies your
/// productivity momentum, detects blockers, and generates nudges.
class MomentumEngineService with ServicePersistence {
  final List<CompletionEvent> _events;
  final List<MomentumBlocker> _blockerHistory;
  final List<MicroNudge> _nudgeHistory;

  /// Short velocity window in days (recent burst).
  final int shortWindowDays;

  /// Long velocity window in days (baseline).
  final int longWindowDays;

  @override
  String get storageKey => 'momentum_engine_data';

  @override
  Map<String, dynamic> toStorageJson() => {
        'events': _events.map((e) => e.toJson()).toList(),
        'blockerHistory': _blockerHistory.map((b) => b.toJson()).toList(),
        'nudgeHistory': _nudgeHistory.map((n) => n.toJson()).toList(),
      };

  @override
  void fromStorageJson(Map<String, dynamic> json) {
    _events.clear();
    _blockerHistory.clear();
    _nudgeHistory.clear();
    if (json['events'] != null) {
      _events.addAll(
        (json['events'] as List)
            .map((e) => CompletionEvent.fromJson(e as Map<String, dynamic>)),
      );
    }
    if (json['blockerHistory'] != null) {
      _blockerHistory.addAll(
        (json['blockerHistory'] as List)
            .map((b) => MomentumBlocker.fromJson(b as Map<String, dynamic>)),
      );
    }
    if (json['nudgeHistory'] != null) {
      _nudgeHistory.addAll(
        (json['nudgeHistory'] as List)
            .map((n) => MicroNudge.fromJson(n as Map<String, dynamic>)),
      );
    }
  }

  MomentumEngineService({
    List<CompletionEvent>? events,
    this.shortWindowDays = 3,
    this.longWindowDays = 14,
  })  : _events = events ?? [],
        _blockerHistory = [],
        _nudgeHistory = [];

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Log a completion event.
  void logCompletion({
    required CompletionCategory category,
    required String label,
    double weight = 1.0,
    DateTime? timestamp,
  }) {
    _events.add(CompletionEvent(
      timestamp: timestamp ?? DateTime.now(),
      category: category,
      label: label,
      weight: weight,
    ));
  }

  /// Get all logged events.
  List<CompletionEvent> get events => List.unmodifiable(_events);

  /// Get blocker history.
  List<MomentumBlocker> get blockerHistory => List.unmodifiable(_blockerHistory);

  /// Get nudge history.
  List<MicroNudge> get nudgeHistory => List.unmodifiable(_nudgeHistory);

  /// Run full momentum analysis and produce a report.
  MomentumReport analyze({DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final shortSnap = _computeVelocity(now, shortWindowDays);
    final longSnap = _computeVelocity(now, longWindowDays);

    final acceleration = longSnap.completionsPerDay > 0
        ? (shortSnap.completionsPerDay - longSnap.completionsPerDay) /
            longSnap.completionsPerDay
        : (shortSnap.completionsPerDay > 0 ? 1.0 : 0.0);

    final phase = _classifyPhase(shortSnap, longSnap, acceleration, now);
    final score = _computeMomentumScore(shortSnap, longSnap, acceleration, phase);
    final blockers = _detectBlockers(now);
    final nudges = _generateNudges(phase, blockers, shortSnap, now);
    final categoryHealth = _computeCategoryHealth(now);
    final daysSinceLast = _daysSinceLastCompletion(now);

    // Persist findings
    _blockerHistory.addAll(blockers);
    _nudgeHistory.addAll(nudges);

    return MomentumReport(
      phase: phase,
      currentVelocity: shortSnap.completionsPerDay,
      acceleration: acceleration,
      momentumScore: score,
      shortWindow: shortSnap,
      longWindow: longSnap,
      blockers: blockers,
      nudges: nudges,
      categoryHealth: categoryHealth,
      daysSinceLastCompletion: daysSinceLast,
      generatedAt: now,
    );
  }

  /// Quick check: current phase without full report.
  MomentumPhase currentPhase({DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final shortSnap = _computeVelocity(now, shortWindowDays);
    final longSnap = _computeVelocity(now, longWindowDays);
    final acceleration = longSnap.completionsPerDay > 0
        ? (shortSnap.completionsPerDay - longSnap.completionsPerDay) /
            longSnap.completionsPerDay
        : (shortSnap.completionsPerDay > 0 ? 1.0 : 0.0);
    return _classifyPhase(shortSnap, longSnap, acceleration, now);
  }

  /// Get the top active category by recent completions.
  CompletionCategory? topCategory({DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final snap = _computeVelocity(now, shortWindowDays);
    if (snap.byCategory.isEmpty) return null;
    return snap.byCategory.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Velocity trend: list of daily completion counts for past N days.
  List<int> dailyTrend({int days = 14, DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final result = <int>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = _dateOnly(now.subtract(Duration(days: i)));
      final count = _events.where((e) => _dateOnly(e.timestamp) == day).length;
      result.add(count);
    }
    return result;
  }

  /// Category breakdown for the last N days.
  Map<CompletionCategory, int> categoryBreakdown({int days = 7, DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    final counts = <CompletionCategory, int>{};
    for (final e in _events.where((e) => e.timestamp.isAfter(cutoff))) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    return counts;
  }

  /// Clear all data.
  void reset() {
    _events.clear();
    _blockerHistory.clear();
    _nudgeHistory.clear();
  }

  // -------------------------------------------------------------------------
  // Private: Velocity
  // -------------------------------------------------------------------------

  VelocitySnapshot _computeVelocity(DateTime now, int windowDays) {
    final cutoff = now.subtract(Duration(days: windowDays));
    final windowEvents = _events.where((e) =>
        e.timestamp.isAfter(cutoff) && !e.timestamp.isAfter(now)).toList();

    final byCategory = <CompletionCategory, int>{};
    double weightedSum = 0;
    for (final e in windowEvents) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + 1;
      weightedSum += e.weight;
    }

    return VelocitySnapshot(
      windowStart: cutoff,
      windowEnd: now,
      completionsPerDay: windowEvents.length / windowDays,
      weightedCompletionsPerDay: weightedSum / windowDays,
      totalCompletions: windowEvents.length,
      byCategory: byCategory,
    );
  }

  // -------------------------------------------------------------------------
  // Private: Phase Classification
  // -------------------------------------------------------------------------

  MomentumPhase _classifyPhase(
    VelocitySnapshot shortSnap,
    VelocitySnapshot longSnap,
    double acceleration,
    DateTime now,
  ) {
    final daysSinceLast = _daysSinceLastCompletion(now);

    // Crashed: no activity for 5+ days
    if (daysSinceLast >= 5) return MomentumPhase.crashed;

    // Stalling: no activity for 3+ days or very low recent velocity
    if (daysSinceLast >= 3 || shortSnap.completionsPerDay < 0.2) {
      return MomentumPhase.stalling;
    }

    // No baseline yet (new user): igniting
    if (longSnap.totalCompletions < 5) return MomentumPhase.igniting;

    // Accelerating: significant positive acceleration
    if (acceleration > 0.3) return MomentumPhase.accelerating;

    // Coasting: significant negative acceleration
    if (acceleration < -0.3) return MomentumPhase.coasting;

    // Cruising: stable velocity above baseline
    if (shortSnap.completionsPerDay >= longSnap.completionsPerDay * 0.7) {
      return MomentumPhase.cruising;
    }

    return MomentumPhase.coasting;
  }

  // -------------------------------------------------------------------------
  // Private: Momentum Score
  // -------------------------------------------------------------------------

  double _computeMomentumScore(
    VelocitySnapshot shortSnap,
    VelocitySnapshot longSnap,
    double acceleration,
    MomentumPhase phase,
  ) {
    // Composite score 0-100 based on:
    // - Velocity (40%): how fast relative to personal baseline
    // - Consistency (30%): how steady day-to-day
    // - Acceleration (20%): trending up or down
    // - Recency (10%): how recently you completed something

    // Velocity component: ratio to baseline, capped at 2x
    final velocityRatio = longSnap.completionsPerDay > 0
        ? (shortSnap.completionsPerDay / longSnap.completionsPerDay).clamp(0.0, 2.0)
        : (shortSnap.completionsPerDay > 0 ? 1.5 : 0.0);
    final velocityScore = velocityRatio / 2.0 * 100;

    // Consistency: std dev of daily completions (lower = better)
    final consistencyScore = _consistencyScore();

    // Acceleration component: map [-1, 1] to [0, 100]
    final accelScore = ((acceleration.clamp(-1.0, 1.0) + 1) / 2 * 100);

    // Recency component
    final daysSinceLast = _daysSinceLastCompletion(DateTime.now());
    final recencyScore = max(0, 100 - daysSinceLast * 20).toDouble();

    return (velocityScore * 0.4 +
            consistencyScore * 0.3 +
            accelScore * 0.2 +
            recencyScore * 0.1)
        .clamp(0, 100)
        .roundToDouble();
  }

  double _consistencyScore() {
    if (_events.isEmpty) return 0;
    final dailyCounts = dailyTrend(days: 7);
    if (dailyCounts.every((c) => c == 0)) return 0;
    final mean = dailyCounts.reduce((a, b) => a + b) / dailyCounts.length;
    if (mean == 0) return 0;
    final variance =
        dailyCounts.map((c) => pow(c - mean, 2)).reduce((a, b) => a + b) /
            dailyCounts.length;
    final cv = sqrt(variance) / mean; // coefficient of variation
    // Lower CV = more consistent = higher score
    return max(0, (1 - cv) * 100).clamp(0, 100).toDouble();
  }

  // -------------------------------------------------------------------------
  // Private: Blocker Detection
  // -------------------------------------------------------------------------

  List<MomentumBlocker> _detectBlockers(DateTime now) {
    final blockers = <MomentumBlocker>[];

    // 1. Post-weekend gap
    _checkWeekendGap(now, blockers);
    // 2. Consistency drop
    _checkConsistencyDrop(now, blockers);
    // 3. Category abandonment
    _checkCategoryAbandonment(now, blockers);
    // 4. Overcommitment
    _checkOvercommitment(now, blockers);
    // 5. Streak break spiral
    _checkStreakBreakSpiral(now, blockers);

    return blockers;
  }

  void _checkWeekendGap(DateTime now, List<MomentumBlocker> blockers) {
    if (now.weekday != DateTime.monday && now.weekday != DateTime.tuesday) return;

    final weekendStart = now.subtract(Duration(days: now.weekday + 1));
    final weekendEnd = now.subtract(Duration(days: now.weekday - 1));

    final weekendCompletions = _events
        .where((e) =>
            e.timestamp.isAfter(weekendStart) && e.timestamp.isBefore(weekendEnd))
        .length;

    // Compare with average weekday completions
    final weekdayAvg = _averageWeekdayCompletions(now);
    if (weekdayAvg > 0 && weekendCompletions < weekdayAvg * 0.3) {
      blockers.add(MomentumBlocker(
        type: BlockerType.gapAfterWeekend,
        confidence: 0.7,
        evidence:
            'Weekend completions ($weekendCompletions) vs weekday avg (${weekdayAvg.toStringAsFixed(1)})',
        detectedAt: now,
      ));
    }
  }

  void _checkConsistencyDrop(DateTime now, List<MomentumBlocker> blockers) {
    final recent3 = _computeVelocity(now, 3);
    final baseline7 = _computeVelocity(now, 7);

    if (baseline7.completionsPerDay > 0.5 &&
        recent3.completionsPerDay < baseline7.completionsPerDay * 0.4) {
      blockers.add(MomentumBlocker(
        type: BlockerType.consistencyDrop,
        confidence: 0.8,
        evidence:
            'Recent 3-day rate (${recent3.completionsPerDay.toStringAsFixed(1)}/day) '
            'vs 7-day baseline (${baseline7.completionsPerDay.toStringAsFixed(1)}/day)',
        detectedAt: now,
      ));
    }
  }

  void _checkCategoryAbandonment(DateTime now, List<MomentumBlocker> blockers) {
    final recentCats = categoryBreakdown(days: 7, asOf: now);
    final olderCats = categoryBreakdown(days: 14, asOf: now.subtract(const Duration(days: 7)));

    for (final cat in olderCats.keys) {
      if ((olderCats[cat] ?? 0) >= 3 && (recentCats[cat] ?? 0) == 0) {
        blockers.add(MomentumBlocker(
          type: BlockerType.categoryAbandonment,
          confidence: 0.75,
          evidence: '${cat.label} had ${olderCats[cat]} completions in prior week, 0 this week',
          detectedAt: now,
        ));
      }
    }
  }

  void _checkOvercommitment(DateTime now, List<MomentumBlocker> blockers) {
    final recentLabels = _events
        .where((e) => e.timestamp.isAfter(now.subtract(const Duration(days: 7))))
        .map((e) => e.label)
        .toSet();

    // If tracking 15+ distinct items but completing <2/day, likely overcommitted
    if (recentLabels.length >= 15) {
      final velocity = _computeVelocity(now, 7);
      if (velocity.completionsPerDay < 2.0) {
        blockers.add(MomentumBlocker(
          type: BlockerType.overcommitment,
          confidence: 0.65,
          evidence:
              '${recentLabels.length} active items but only '
              '${velocity.completionsPerDay.toStringAsFixed(1)} completions/day',
          detectedAt: now,
        ));
      }
    }
  }

  void _checkStreakBreakSpiral(DateTime now, List<MomentumBlocker> blockers) {
    // Pattern: after a gap of 2+ days, subsequent activity drops further
    final trend = dailyTrend(days: 10, asOf: now);

    for (int i = 1; i < trend.length - 2; i++) {
      // Found a gap (0 completions after active days)
      if (trend[i - 1] > 0 && trend[i] == 0 && trend[i + 1] == 0) {
        // Check if post-gap activity is lower than pre-gap
        final preGapAvg = trend.sublist(0, i).where((c) => c > 0).isEmpty
            ? 0.0
            : trend.sublist(0, i).where((c) => c > 0).reduce((a, b) => a + b) /
                trend.sublist(0, i).where((c) => c > 0).length;
        final postGap = trend.sublist(i + 2);
        final postGapAvg = postGap.isEmpty || postGap.every((c) => c == 0)
            ? 0.0
            : postGap.reduce((a, b) => a + b) / postGap.length;

        if (preGapAvg > 0 && postGapAvg < preGapAvg * 0.5) {
          blockers.add(MomentumBlocker(
            type: BlockerType.streakBreakSpiral,
            confidence: 0.7,
            evidence:
                'Pre-gap avg ${preGapAvg.toStringAsFixed(1)}/day → '
                'post-gap avg ${postGapAvg.toStringAsFixed(1)}/day',
            detectedAt: now,
          ));
          break; // Only report once
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // Private: Nudge Generation
  // -------------------------------------------------------------------------

  List<MicroNudge> _generateNudges(
    MomentumPhase phase,
    List<MomentumBlocker> blockers,
    VelocitySnapshot recentSnap,
    DateTime now,
  ) {
    final nudges = <MicroNudge>[];

    // Phase-based nudges
    switch (phase) {
      case MomentumPhase.crashed:
        nudges.add(MicroNudge(
          message: 'Just one tiny thing today. That\'s all it takes to restart.',
          urgency: NudgeUrgency.critical,
          suggestedAction: 'Pick your easiest habit and do it right now.',
          generatedAt: now,
        ));
        break;
      case MomentumPhase.stalling:
        nudges.add(MicroNudge(
          message: 'Your momentum is fading — a quick win now prevents a full stall.',
          urgency: NudgeUrgency.urgent,
          suggestedAction: 'Complete any one item to break the silence.',
          generatedAt: now,
        ));
        break;
      case MomentumPhase.coasting:
        nudges.add(MicroNudge(
          message: 'You\'re coasting — still moving but losing speed. Time to re-engage.',
          urgency: NudgeUrgency.encouraging,
          suggestedAction: 'Add one extra completion today beyond your minimum.',
          generatedAt: now,
        ));
        break;
      case MomentumPhase.cruising:
        nudges.add(MicroNudge(
          message: 'Solid cruising speed! Consider a stretch goal to level up.',
          urgency: NudgeUrgency.gentle,
          suggestedAction: 'Try a new category or increase difficulty slightly.',
          generatedAt: now,
        ));
        break;
      case MomentumPhase.accelerating:
        nudges.add(MicroNudge(
          message: 'You\'re accelerating! Ride this wave but don\'t burn out.',
          urgency: NudgeUrgency.gentle,
          suggestedAction: 'Maintain this pace — no need to push harder.',
          generatedAt: now,
        ));
        break;
      case MomentumPhase.igniting:
        nudges.add(MicroNudge(
          message: 'Great start! Build consistency now — 3 days makes a pattern.',
          urgency: NudgeUrgency.encouraging,
          suggestedAction: 'Set a reminder for tomorrow at the same time.',
          generatedAt: now,
        ));
        break;
    }

    // Blocker-specific nudges
    for (final blocker in blockers) {
      switch (blocker.type) {
        case BlockerType.gapAfterWeekend:
          nudges.add(MicroNudge(
            message: 'Weekends are your kryptonite. Pre-plan one Sunday evening task.',
            urgency: NudgeUrgency.encouraging,
            suggestedAction: 'Schedule a light Sunday evening habit to bridge the gap.',
            generatedAt: now,
          ));
          break;
        case BlockerType.categoryAbandonment:
          nudges.add(MicroNudge(
            message: 'A category went quiet. Reconnect or consciously let it go.',
            urgency: NudgeUrgency.encouraging,
            suggestedAction: 'Either do one item from the abandoned category or archive it.',
            generatedAt: now,
          ));
          break;
        case BlockerType.overcommitment:
          nudges.add(MicroNudge(
            message: 'Too many plates spinning. Focus beats breadth.',
            urgency: NudgeUrgency.urgent,
            suggestedAction: 'Pause 3 items and focus on your top 5.',
            generatedAt: now,
          ));
          break;
        case BlockerType.streakBreakSpiral:
          nudges.add(MicroNudge(
            message: 'A broken streak doesn\'t erase progress. Start fresh now.',
            urgency: NudgeUrgency.encouraging,
            suggestedAction: 'Forget the streak counter — just do today.',
            generatedAt: now,
          ));
          break;
        case BlockerType.consistencyDrop:
          nudges.add(MicroNudge(
            message: 'Your rhythm is off. Small consistent actions beat rare bursts.',
            urgency: NudgeUrgency.urgent,
            suggestedAction: 'Commit to just 1 completion per day this week.',
            generatedAt: now,
          ));
          break;
        case BlockerType.timeOfDayShift:
          nudges.add(MicroNudge(
            message: 'Your productive window shifted. Adjust your schedule to match.',
            urgency: NudgeUrgency.gentle,
            suggestedAction: 'Move reminders to your new peak time.',
            generatedAt: now,
          ));
          break;
      }
    }

    return nudges;
  }

  // -------------------------------------------------------------------------
  // Private: Category Health
  // -------------------------------------------------------------------------

  Map<CompletionCategory, double> _computeCategoryHealth(DateTime now) {
    final health = <CompletionCategory, double>{};
    final recent = categoryBreakdown(days: 7, asOf: now);
    final baseline = categoryBreakdown(days: 14, asOf: now);

    for (final cat in CompletionCategory.values) {
      final recentCount = recent[cat] ?? 0;
      final baselineCount = baseline[cat] ?? 0;

      if (baselineCount == 0 && recentCount == 0) {
        health[cat] = 0; // Never used
      } else if (baselineCount == 0) {
        health[cat] = 100; // New and active
      } else {
        // Health = recent activity relative to baseline (capped at 100)
        final ratio = (recentCount / (baselineCount / 2)).clamp(0.0, 1.0);
        health[cat] = (ratio * 100).roundToDouble();
      }
    }

    return health;
  }

  // -------------------------------------------------------------------------
  // Private: Utilities
  // -------------------------------------------------------------------------

  int _daysSinceLastCompletion(DateTime now) {
    if (_events.isEmpty) return 999;
    final lastEvent = _events.reduce((a, b) =>
        a.timestamp.isAfter(b.timestamp) ? a : b);
    return now.difference(lastEvent.timestamp).inDays;
  }

  double _averageWeekdayCompletions(DateTime now) {
    final cutoff = now.subtract(const Duration(days: 14));
    int weekdays = 0;
    int completions = 0;

    for (int i = 0; i < 14; i++) {
      final day = now.subtract(Duration(days: i));
      if (day.isBefore(cutoff)) break;
      if (day.weekday >= DateTime.monday && day.weekday <= DateTime.friday) {
        weekdays++;
        completions += _events
            .where((e) => _dateOnly(e.timestamp) == _dateOnly(day))
            .length;
      }
    }

    return weekdays > 0 ? completions / weekdays : 0;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
