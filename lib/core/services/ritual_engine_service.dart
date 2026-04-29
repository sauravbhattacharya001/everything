import 'dart:math';

/// Adaptive Ritual Engine — autonomous daily ritual optimizer that tracks
/// routine execution patterns, learns optimal timing windows, detects
/// disruptions, and generates micro-adjustments to improve ritual adherence.
///
/// Core concepts:
/// - **Ritual**: a named daily activity with target time window
/// - **Timing Score**: how close to optimal window each execution was (0-100)
/// - **Rhythm State**: classified phase (lockedIn → abandoned)
/// - **Disruption Detection**: 6 disruption types with severity scoring
/// - **Micro-Adjustments**: context-aware suggestions to improve adherence
/// - **Chain Health**: overall daily sequence scoring (0-100)

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Rhythm lifecycle phase for a ritual.
enum RhythmState {
  lockedIn,
  consistent,
  drifting,
  disrupted,
  abandoned;

  String get label {
    switch (this) {
      case RhythmState.lockedIn:
        return 'Locked In';
      case RhythmState.consistent:
        return 'Consistent';
      case RhythmState.drifting:
        return 'Drifting';
      case RhythmState.disrupted:
        return 'Disrupted';
      case RhythmState.abandoned:
        return 'Abandoned';
    }
  }

  String get emoji {
    switch (this) {
      case RhythmState.lockedIn:
        return '🎯';
      case RhythmState.consistent:
        return '✅';
      case RhythmState.drifting:
        return '🌊';
      case RhythmState.disrupted:
        return '⚡';
      case RhythmState.abandoned:
        return '💤';
    }
  }

  String get colorHex {
    switch (this) {
      case RhythmState.lockedIn:
        return '#4CAF50';
      case RhythmState.consistent:
        return '#8BC34A';
      case RhythmState.drifting:
        return '#FFC107';
      case RhythmState.disrupted:
        return '#FF5722';
      case RhythmState.abandoned:
        return '#9E9E9E';
    }
  }
}

/// Disruption type detected by the engine.
enum DisruptionType {
  timeDrift,
  skipStreak,
  orderSwap,
  durationChange,
  contextShift,
  cascadeFailure;

  String get label {
    switch (this) {
      case DisruptionType.timeDrift:
        return 'Time Drift';
      case DisruptionType.skipStreak:
        return 'Skip Streak';
      case DisruptionType.orderSwap:
        return 'Order Swap';
      case DisruptionType.durationChange:
        return 'Duration Change';
      case DisruptionType.contextShift:
        return 'Context Shift';
      case DisruptionType.cascadeFailure:
        return 'Cascade Failure';
    }
  }

  String get emoji {
    switch (this) {
      case DisruptionType.timeDrift:
        return '⏰';
      case DisruptionType.skipStreak:
        return '🚫';
      case DisruptionType.orderSwap:
        return '🔀';
      case DisruptionType.durationChange:
        return '⏱️';
      case DisruptionType.contextShift:
        return '🔄';
      case DisruptionType.cascadeFailure:
        return '💥';
    }
  }
}

/// Micro-adjustment type the engine can recommend.
enum AdjustmentType {
  shiftTiming,
  splitRitual,
  anchorToTrigger,
  reduceScope,
  swapOrder,
  addBuffer;

  String get label {
    switch (this) {
      case AdjustmentType.shiftTiming:
        return 'Shift Timing';
      case AdjustmentType.splitRitual:
        return 'Split Ritual';
      case AdjustmentType.anchorToTrigger:
        return 'Anchor to Trigger';
      case AdjustmentType.reduceScope:
        return 'Reduce Scope';
      case AdjustmentType.swapOrder:
        return 'Swap Order';
      case AdjustmentType.addBuffer:
        return 'Add Buffer';
    }
  }

  String get emoji {
    switch (this) {
      case AdjustmentType.shiftTiming:
        return '↔️';
      case AdjustmentType.splitRitual:
        return '✂️';
      case AdjustmentType.anchorToTrigger:
        return '⚓';
      case AdjustmentType.reduceScope:
        return '📐';
      case AdjustmentType.swapOrder:
        return '🔃';
      case AdjustmentType.addBuffer:
        return '🛡️';
    }
  }
}

/// Category for ritual classification.
enum RitualCategory {
  health,
  productivity,
  mindfulness,
  social,
  creative,
  maintenance;

  String get label {
    switch (this) {
      case RitualCategory.health:
        return 'Health';
      case RitualCategory.productivity:
        return 'Productivity';
      case RitualCategory.mindfulness:
        return 'Mindfulness';
      case RitualCategory.social:
        return 'Social';
      case RitualCategory.creative:
        return 'Creative';
      case RitualCategory.maintenance:
        return 'Maintenance';
    }
  }

  String get emoji {
    switch (this) {
      case RitualCategory.health:
        return '💪';
      case RitualCategory.productivity:
        return '🚀';
      case RitualCategory.mindfulness:
        return '🧘';
      case RitualCategory.social:
        return '👥';
      case RitualCategory.creative:
        return '🎨';
      case RitualCategory.maintenance:
        return '🔧';
    }
  }
}

// ---------------------------------------------------------------------------
// Data Classes
// ---------------------------------------------------------------------------

/// A configured daily ritual.
class Ritual {
  final String id;
  final String name;
  final RitualCategory category;
  final int targetHour;
  final int targetMinute;
  final int durationMinutes;
  final int priority; // 1-10
  final bool isActive;

  const Ritual({
    required this.id,
    required this.name,
    required this.category,
    required this.targetHour,
    required this.targetMinute,
    required this.durationMinutes,
    required this.priority,
    this.isActive = true,
  });

  /// Target time as minutes since midnight.
  int get targetMinuteOfDay => targetHour * 60 + targetMinute;

  /// Formatted target time string (e.g., "06:30").
  String get targetTimeStr {
    final h = targetHour.toString().padLeft(2, '0');
    final m = targetMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Ritual copyWith({int? targetHour, int? targetMinute, int? durationMinutes}) {
    return Ritual(
      id: id,
      name: name,
      category: category,
      targetHour: targetHour ?? this.targetHour,
      targetMinute: targetMinute ?? this.targetMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      priority: priority,
      isActive: isActive,
    );
  }
}

/// A recorded execution of a ritual.
class RitualExecution {
  final String ritualId;
  final DateTime executedAt;
  final int durationMinutes;
  final int qualityRating; // 1-5
  final String notes;

  const RitualExecution({
    required this.ritualId,
    required this.executedAt,
    required this.durationMinutes,
    required this.qualityRating,
    this.notes = '',
  });

  /// Execution time as minutes since midnight.
  int get minuteOfDay => executedAt.hour * 60 + executedAt.minute;
}

/// A detected disruption event.
class DisruptionEvent {
  final DisruptionType type;
  final String ritualId;
  final DateTime detectedAt;
  final int severity; // 0-100
  final String description;

  const DisruptionEvent({
    required this.type,
    required this.ritualId,
    required this.detectedAt,
    required this.severity,
    required this.description,
  });
}

/// A recommended micro-adjustment.
class MicroAdjustment {
  final AdjustmentType type;
  final String ritualId;
  final int confidence; // 0-100
  final String reasoning;
  final String suggestedChange;

  const MicroAdjustment({
    required this.type,
    required this.ritualId,
    required this.confidence,
    required this.reasoning,
    required this.suggestedChange,
  });
}

/// Full daily chain analysis report.
class RitualChainReport {
  final DateTime date;
  final List<Ritual> rituals;
  final List<RitualExecution> executions;
  final int chainScore;
  final RhythmState overallState;
  final List<DisruptionEvent> disruptions;
  final List<MicroAdjustment> adjustments;
  final int streakDays;

  const RitualChainReport({
    required this.date,
    required this.rituals,
    required this.executions,
    required this.chainScore,
    required this.overallState,
    required this.disruptions,
    required this.adjustments,
    required this.streakDays,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Adaptive Ritual Engine service — autonomous ritual optimization.
class RitualEngineService {
  final List<Ritual> rituals = [];
  final List<RitualExecution> executions = [];
  final _rand = Random(42);

  // -------------------------------------------------------------------------
  // Sample Data
  // -------------------------------------------------------------------------

  /// Load sample rituals and 14 days of execution history.
  void loadSampleDay() {
    rituals.clear();
    executions.clear();

    // Sample rituals
    rituals.addAll([
      const Ritual(
        id: 'r1', name: 'Morning Meditation', category: RitualCategory.mindfulness,
        targetHour: 6, targetMinute: 30, durationMinutes: 15, priority: 9,
      ),
      const Ritual(
        id: 'r2', name: 'Exercise', category: RitualCategory.health,
        targetHour: 7, targetMinute: 0, durationMinutes: 45, priority: 8,
      ),
      const Ritual(
        id: 'r3', name: 'Journal Writing', category: RitualCategory.creative,
        targetHour: 7, targetMinute: 50, durationMinutes: 20, priority: 7,
      ),
      const Ritual(
        id: 'r4', name: 'Deep Work Block', category: RitualCategory.productivity,
        targetHour: 9, targetMinute: 0, durationMinutes: 90, priority: 10,
      ),
      const Ritual(
        id: 'r5', name: 'Lunch Walk', category: RitualCategory.health,
        targetHour: 12, targetMinute: 30, durationMinutes: 20, priority: 5,
      ),
      const Ritual(
        id: 'r6', name: 'Reading', category: RitualCategory.creative,
        targetHour: 21, targetMinute: 0, durationMinutes: 30, priority: 6,
      ),
      const Ritual(
        id: 'r7', name: 'Evening Review', category: RitualCategory.productivity,
        targetHour: 21, targetMinute: 45, durationMinutes: 10, priority: 7,
      ),
      const Ritual(
        id: 'r8', name: 'Social Check-in', category: RitualCategory.social,
        targetHour: 18, targetMinute: 0, durationMinutes: 15, priority: 4,
      ),
    ]);

    // Generate 14 days of execution data with realistic variance
    final now = DateTime.now();
    final baseDate = DateTime(now.year, now.month, now.day);

    for (var day = 13; day >= 0; day--) {
      final date = baseDate.subtract(Duration(days: day));
      final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

      for (final ritual in rituals) {
        // Skip probability: higher on weekends, higher for low-priority
        final skipChance = isWeekend ? 0.25 : 0.08;
        final prioritySkipBonus = (10 - ritual.priority) * 0.02;
        if (_rand.nextDouble() < skipChance + prioritySkipBonus) continue;

        // Time variance: normally distributed around target
        final baseVariance = isWeekend ? 25 : 10;
        final drift = day < 5 ? (5 - day) * 3 : 0; // recent days drift more for r1
        final variance = ritual.id == 'r1' ? baseVariance + drift : baseVariance;
        final offsetMinutes = (_rand.nextInt(variance * 2 + 1) - variance);

        final targetMin = ritual.targetMinuteOfDay;
        final actualMin = (targetMin + offsetMinutes).clamp(0, 1439);
        final execHour = actualMin ~/ 60;
        final execMinute = actualMin % 60;

        // Duration variance ±20%
        final durationVar = (ritual.durationMinutes * 0.2).round();
        final actualDuration = ritual.durationMinutes +
            _rand.nextInt(durationVar * 2 + 1) - durationVar;

        // Quality correlates with timing accuracy
        final timingDeviation = (actualMin - targetMin).abs();
        final baseQuality = timingDeviation < 5 ? 5 : (timingDeviation < 15 ? 4 : (timingDeviation < 30 ? 3 : 2));
        final quality = baseQuality.clamp(1, 5);

        executions.add(RitualExecution(
          ritualId: ritual.id,
          executedAt: DateTime(date.year, date.month, date.day, execHour, execMinute),
          durationMinutes: actualDuration.clamp(5, 180),
          qualityRating: quality,
        ));
      }
    }
  }

  // -------------------------------------------------------------------------
  // Analysis
  // -------------------------------------------------------------------------

  /// Main analysis entry point — produces full chain report for today.
  RitualChainReport analyzeToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayExecs = executions
        .where((e) => e.executedAt.year == today.year &&
            e.executedAt.month == today.month &&
            e.executedAt.day == today.day)
        .toList();

    final disruptions = detectDisruptions();
    final adjustments = generateAdjustments();
    final score = chainScore();
    final streak = streakDays();
    final state = _overallRhythmState();

    return RitualChainReport(
      date: today,
      rituals: List.unmodifiable(rituals),
      executions: todayExecs,
      chainScore: score,
      overallState: state,
      disruptions: disruptions,
      adjustments: adjustments,
      streakDays: streak,
    );
  }

  /// Compute timing score for a single execution (0-100).
  int computeTimingScore(Ritual ritual, RitualExecution exec) {
    final deviation = (exec.minuteOfDay - ritual.targetMinuteOfDay).abs();
    if (deviation == 0) return 100;
    if (deviation <= 5) return 95;
    if (deviation <= 10) return 85;
    if (deviation <= 15) return 75;
    if (deviation <= 30) return 55;
    if (deviation <= 60) return 30;
    return max(0, 100 - deviation * 2);
  }

  /// Classify the rhythm state for a specific ritual over the last 14 days.
  RhythmState classifyRhythm(String ritualId) {
    final ritual = rituals.firstWhere((r) => r.id == ritualId,
        orElse: () => rituals.first);
    final recentExecs = _recentExecutions(ritualId, 14);

    if (recentExecs.isEmpty) return RhythmState.abandoned;

    final totalDays = 14;
    final executionRate = recentExecs.length / totalDays;

    if (executionRate < 0.3) return RhythmState.abandoned;

    // Compute average timing score
    final scores = recentExecs.map((e) => computeTimingScore(ritual, e)).toList();
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;

    // Check recent trend (last 3 days vs previous)
    final last3 = _recentExecutions(ritualId, 3);
    final last3Rate = last3.length / 3;

    if (executionRate >= 0.9 && avgScore >= 85) return RhythmState.lockedIn;
    if (executionRate >= 0.7 && avgScore >= 65) return RhythmState.consistent;
    if (last3Rate < 0.5 && executionRate >= 0.5) return RhythmState.disrupted;
    if (executionRate >= 0.5) return RhythmState.drifting;
    return RhythmState.disrupted;
  }

  /// Detect all active disruptions across rituals.
  List<DisruptionEvent> detectDisruptions() {
    final disruptions = <DisruptionEvent>[];
    final now = DateTime.now();

    for (final ritual in rituals.where((r) => r.isActive)) {
      // Time Drift: avg execution time drifted >15min from target over 7 days
      final recent7 = _recentExecutions(ritual.id, 7);
      if (recent7.isNotEmpty) {
        final avgMinOfDay = recent7.map((e) => e.minuteOfDay).reduce((a, b) => a + b) / recent7.length;
        final drift = (avgMinOfDay - ritual.targetMinuteOfDay).abs();
        if (drift > 15) {
          disruptions.add(DisruptionEvent(
            type: DisruptionType.timeDrift,
            ritualId: ritual.id,
            detectedAt: now,
            severity: min(100, (drift * 2).round()),
            description: '${ritual.name} has drifted ${drift.round()}min from target time',
          ));
        }
      }

      // Skip Streak: 3+ consecutive missed days
      final skipStreak = _consecutiveSkips(ritual.id);
      if (skipStreak >= 3) {
        disruptions.add(DisruptionEvent(
          type: DisruptionType.skipStreak,
          ritualId: ritual.id,
          detectedAt: now,
          severity: min(100, skipStreak * 20),
          description: '${ritual.name} missed $skipStreak days in a row',
        ));
      }

      // Duration Change: avg duration changed >30% from baseline
      if (recent7.isNotEmpty) {
        final avgDuration = recent7.map((e) => e.durationMinutes).reduce((a, b) => a + b) / recent7.length;
        final change = ((avgDuration - ritual.durationMinutes) / ritual.durationMinutes).abs();
        if (change > 0.3) {
          disruptions.add(DisruptionEvent(
            type: DisruptionType.durationChange,
            ritualId: ritual.id,
            detectedAt: now,
            severity: min(100, (change * 100).round()),
            description: '${ritual.name} duration changed ${(change * 100).round()}% from target',
          ));
        }
      }
    }

    // Order Swap: check if ritual sequence order changed >40% of recent days
    final orderSwaps = _detectOrderSwaps();
    disruptions.addAll(orderSwaps);

    // Context Shift: weekday vs weekend pattern differences
    final contextShifts = _detectContextShifts();
    disruptions.addAll(contextShifts);

    // Cascade Failure: missing one ritual → 2+ subsequent misses same day
    final cascades = _detectCascadeFailures();
    disruptions.addAll(cascades);

    return disruptions;
  }

  /// Generate micro-adjustments based on detected patterns.
  List<MicroAdjustment> generateAdjustments() {
    final adjustments = <MicroAdjustment>[];

    for (final ritual in rituals.where((r) => r.isActive)) {
      final state = classifyRhythm(ritual.id);
      final recent7 = _recentExecutions(ritual.id, 7);

      if (recent7.isEmpty) continue;

      // Shift Timing: if consistently executing later/earlier, suggest moving target
      final avgMinOfDay = recent7.map((e) => e.minuteOfDay).reduce((a, b) => a + b) / recent7.length;
      final drift = avgMinOfDay - ritual.targetMinuteOfDay;
      if (drift.abs() > 10) {
        final direction = drift > 0 ? 'later' : 'earlier';
        final newHour = (avgMinOfDay ~/ 60);
        final newMin = (avgMinOfDay % 60).round();
        adjustments.add(MicroAdjustment(
          type: AdjustmentType.shiftTiming,
          ritualId: ritual.id,
          confidence: min(95, 50 + drift.abs().round()),
          reasoning: 'You consistently do ${ritual.name} ${drift.abs().round()}min $direction than planned',
          suggestedChange: 'Move target to ${newHour.toString().padLeft(2, '0')}:${newMin.toString().padLeft(2, '0')}',
        ));
      }

      // Reduce Scope: if duration is consistently shorter, suggest reducing
      final avgDuration = recent7.map((e) => e.durationMinutes).reduce((a, b) => a + b) / recent7.length;
      if (avgDuration < ritual.durationMinutes * 0.7 && state != RhythmState.lockedIn) {
        adjustments.add(MicroAdjustment(
          type: AdjustmentType.reduceScope,
          ritualId: ritual.id,
          confidence: 65,
          reasoning: 'Actual duration (${avgDuration.round()}min) is below target (${ritual.durationMinutes}min)',
          suggestedChange: 'Reduce to ${avgDuration.round()}min — consistency beats ambition',
        ));
      }

      // Add Buffer: if this ritual often causes the next one to be late
      if (state == RhythmState.drifting || state == RhythmState.disrupted) {
        final idx = rituals.indexOf(ritual);
        if (idx < rituals.length - 1) {
          adjustments.add(MicroAdjustment(
            type: AdjustmentType.addBuffer,
            ritualId: ritual.id,
            confidence: 55,
            reasoning: '${ritual.name} instability may cascade to subsequent rituals',
            suggestedChange: 'Add 5-10min buffer after ${ritual.name}',
          ));
        }
      }

      // Anchor to Trigger: for rituals with high skip rate
      final skipRate = 1.0 - (recent7.length / 7.0);
      if (skipRate > 0.3 && ritual.priority >= 6) {
        adjustments.add(MicroAdjustment(
          type: AdjustmentType.anchorToTrigger,
          ritualId: ritual.id,
          confidence: 70,
          reasoning: '${ritual.name} is skipped ${(skipRate * 100).round()}% of the time',
          suggestedChange: 'Anchor to an existing habit (e.g., "after coffee" or "after shower")',
        ));
      }
    }

    // Sort by confidence descending
    adjustments.sort((a, b) => b.confidence.compareTo(a.confidence));
    return adjustments;
  }

  /// Overall daily chain score (0-100).
  int chainScore() {
    if (rituals.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Use today's data, or most recent day with data
    var targetDate = today;
    var dayExecs = _executionsForDay(targetDate);
    if (dayExecs.isEmpty) {
      // Fall back to yesterday
      targetDate = today.subtract(const Duration(days: 1));
      dayExecs = _executionsForDay(targetDate);
    }

    if (dayExecs.isEmpty) return 0;

    final activeRituals = rituals.where((r) => r.isActive).toList();
    if (activeRituals.isEmpty) return 0;

    // Completion component (40%)
    final completionRate = dayExecs.length / activeRituals.length;
    final completionScore = (completionRate * 100).clamp(0, 100).round();

    // Timing component (40%)
    var timingTotal = 0;
    var timingCount = 0;
    for (final exec in dayExecs) {
      final ritual = rituals.firstWhere((r) => r.id == exec.ritualId,
          orElse: () => rituals.first);
      if (ritual.id == exec.ritualId) {
        timingTotal += computeTimingScore(ritual, exec);
        timingCount++;
      }
    }
    final timingScore = timingCount > 0 ? timingTotal ~/ timingCount : 0;

    // Quality component (20%)
    final avgQuality = dayExecs.map((e) => e.qualityRating).reduce((a, b) => a + b) / dayExecs.length;
    final qualityScore = ((avgQuality / 5.0) * 100).round();

    return ((completionScore * 0.4) + (timingScore * 0.4) + (qualityScore * 0.2)).round().clamp(0, 100);
  }

  /// Timing score history for a ritual over the last N days.
  Map<String, int> timingHistory(String ritualId, {int days = 14}) {
    final ritual = rituals.firstWhere((r) => r.id == ritualId,
        orElse: () => rituals.first);
    final history = <String, int>{};
    final now = DateTime.now();
    final baseDate = DateTime(now.year, now.month, now.day);

    for (var i = days - 1; i >= 0; i--) {
      final date = baseDate.subtract(Duration(days: i));
      final dateKey = '${date.month}/${date.day}';
      final dayExecs = executions.where((e) =>
          e.ritualId == ritualId &&
          e.executedAt.year == date.year &&
          e.executedAt.month == date.month &&
          e.executedAt.day == date.day).toList();

      if (dayExecs.isNotEmpty) {
        history[dateKey] = computeTimingScore(ritual, dayExecs.first);
      } else {
        history[dateKey] = -1; // -1 means missed
      }
    }
    return history;
  }

  /// Consecutive days with chainScore >= 70.
  int streakDays() {
    final now = DateTime.now();
    final baseDate = DateTime(now.year, now.month, now.day);
    var streak = 0;

    for (var i = 1; i <= 14; i++) {
      final date = baseDate.subtract(Duration(days: i));
      final dayExecs = _executionsForDay(date);
      if (dayExecs.isEmpty) break;

      final activeRituals = rituals.where((r) => r.isActive).toList();
      final completionRate = dayExecs.length / activeRituals.length;

      // Simplified chain score for historical days
      var timingTotal = 0;
      for (final exec in dayExecs) {
        final ritual = rituals.firstWhere((r) => r.id == exec.ritualId,
            orElse: () => rituals.first);
        timingTotal += computeTimingScore(ritual, exec);
      }
      final timingAvg = timingTotal / dayExecs.length;
      final dayScore = ((completionRate * 50) + (timingAvg * 0.5)).round();

      if (dayScore >= 70) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Apply a timing adjustment — updates the ritual's target time.
  void applyAdjustment(MicroAdjustment adjustment) {
    final idx = rituals.indexWhere((r) => r.id == adjustment.ritualId);
    if (idx < 0) return;

    if (adjustment.type == AdjustmentType.shiftTiming) {
      // Parse suggested time from "Move target to HH:MM"
      final match = RegExp(r'(\d{2}):(\d{2})').firstMatch(adjustment.suggestedChange);
      if (match != null) {
        final newHour = int.parse(match.group(1)!);
        final newMin = int.parse(match.group(2)!);
        rituals[idx] = rituals[idx].copyWith(targetHour: newHour, targetMinute: newMin);
      }
    } else if (adjustment.type == AdjustmentType.reduceScope) {
      // Parse duration from suggestion
      final match = RegExp(r'Reduce to (\d+)min').firstMatch(adjustment.suggestedChange);
      if (match != null) {
        final newDuration = int.parse(match.group(1)!);
        rituals[idx] = rituals[idx].copyWith(durationMinutes: newDuration);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Private Helpers
  // -------------------------------------------------------------------------

  RhythmState _overallRhythmState() {
    if (rituals.isEmpty) return RhythmState.abandoned;
    final states = rituals.where((r) => r.isActive).map((r) => classifyRhythm(r.id)).toList();
    if (states.isEmpty) return RhythmState.abandoned;

    // Weighted by priority
    var score = 0.0;
    var totalWeight = 0.0;
    for (var i = 0; i < states.length; i++) {
      final weight = rituals[i].priority.toDouble();
      totalWeight += weight;
      score += weight * states[i].index;
    }
    final avgIndex = score / totalWeight;

    if (avgIndex <= 0.5) return RhythmState.lockedIn;
    if (avgIndex <= 1.5) return RhythmState.consistent;
    if (avgIndex <= 2.5) return RhythmState.drifting;
    if (avgIndex <= 3.5) return RhythmState.disrupted;
    return RhythmState.abandoned;
  }

  List<RitualExecution> _recentExecutions(String ritualId, int days) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
    return executions.where((e) => e.ritualId == ritualId && e.executedAt.isAfter(cutoff)).toList();
  }

  List<RitualExecution> _executionsForDay(DateTime date) {
    return executions.where((e) =>
        e.executedAt.year == date.year &&
        e.executedAt.month == date.month &&
        e.executedAt.day == date.day).toList();
  }

  int _consecutiveSkips(String ritualId) {
    final now = DateTime.now();
    final baseDate = DateTime(now.year, now.month, now.day);
    var skips = 0;

    for (var i = 0; i < 14; i++) {
      final date = baseDate.subtract(Duration(days: i));
      final hasExec = executions.any((e) =>
          e.ritualId == ritualId &&
          e.executedAt.year == date.year &&
          e.executedAt.month == date.month &&
          e.executedAt.day == date.day);
      if (!hasExec) {
        skips++;
      } else {
        break;
      }
    }
    return skips;
  }

  List<DisruptionEvent> _detectOrderSwaps() {
    final disruptions = <DisruptionEvent>[];
    final now = DateTime.now();

    // Check if rituals are being done out of target order
    final sorted = List<Ritual>.from(rituals.where((r) => r.isActive))
      ..sort((a, b) => a.targetMinuteOfDay.compareTo(b.targetMinuteOfDay));

    var swapDays = 0;
    for (var day = 0; day < 7; day++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: day));
      final dayExecs = _executionsForDay(date);
      if (dayExecs.length < 2) continue;

      // Check if execution order matches target order
      final execOrder = dayExecs.map((e) => e.ritualId).toList();
      final targetOrder = sorted.where((r) => execOrder.contains(r.id)).map((r) => r.id).toList();

      var inversions = 0;
      for (var i = 0; i < execOrder.length - 1; i++) {
        final targetIdx = targetOrder.indexOf(execOrder[i]);
        final nextTargetIdx = targetOrder.indexOf(execOrder[i + 1]);
        if (targetIdx > nextTargetIdx) inversions++;
      }
      if (inversions > 0) swapDays++;
    }

    if (swapDays > 2) {
      disruptions.add(DisruptionEvent(
        type: DisruptionType.orderSwap,
        ritualId: sorted.first.id,
        detectedAt: now,
        severity: min(100, swapDays * 15),
        description: 'Ritual sequence order swapped on $swapDays of last 7 days',
      ));
    }

    return disruptions;
  }

  List<DisruptionEvent> _detectContextShifts() {
    final disruptions = <DisruptionEvent>[];
    final now = DateTime.now();

    for (final ritual in rituals.where((r) => r.isActive)) {
      final recent14 = _recentExecutions(ritual.id, 14);
      if (recent14.length < 5) continue;

      final weekdayExecs = recent14.where((e) => e.executedAt.weekday <= 5).toList();
      final weekendExecs = recent14.where((e) => e.executedAt.weekday > 5).toList();

      if (weekdayExecs.isEmpty || weekendExecs.isEmpty) continue;

      final weekdayAvg = weekdayExecs.map((e) => e.minuteOfDay).reduce((a, b) => a + b) / weekdayExecs.length;
      final weekendAvg = weekendExecs.map((e) => e.minuteOfDay).reduce((a, b) => a + b) / weekendExecs.length;

      final shift = (weekdayAvg - weekendAvg).abs();
      if (shift > 30) {
        disruptions.add(DisruptionEvent(
          type: DisruptionType.contextShift,
          ritualId: ritual.id,
          detectedAt: now,
          severity: min(100, shift.round()),
          description: '${ritual.name} shifts ${shift.round()}min between weekdays and weekends',
        ));
      }
    }
    return disruptions;
  }

  List<DisruptionEvent> _detectCascadeFailures() {
    final disruptions = <DisruptionEvent>[];
    final now = DateTime.now();
    final sorted = List<Ritual>.from(rituals.where((r) => r.isActive))
      ..sort((a, b) => a.targetMinuteOfDay.compareTo(b.targetMinuteOfDay));

    for (var day = 0; day < 7; day++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: day));
      final dayExecs = _executionsForDay(date);
      final completedIds = dayExecs.map((e) => e.ritualId).toSet();

      // Find first miss and count subsequent misses
      var firstMissFound = false;
      var subsequentMisses = 0;
      String? triggerRitualId;

      for (final ritual in sorted) {
        if (!completedIds.contains(ritual.id)) {
          if (!firstMissFound) {
            firstMissFound = true;
            triggerRitualId = ritual.id;
          } else {
            subsequentMisses++;
          }
        } else if (firstMissFound) {
          // Reset — there was a completion after the miss
          firstMissFound = false;
          subsequentMisses = 0;
        }
      }

      if (subsequentMisses >= 2 && triggerRitualId != null) {
        final triggerRitual = rituals.firstWhere((r) => r.id == triggerRitualId);
        disruptions.add(DisruptionEvent(
          type: DisruptionType.cascadeFailure,
          ritualId: triggerRitualId,
          detectedAt: now,
          severity: min(100, subsequentMisses * 25),
          description: 'Missing ${triggerRitual.name} cascaded to $subsequentMisses more skips',
        ));
        break; // Report only most recent cascade
      }
    }

    return disruptions;
  }
}
