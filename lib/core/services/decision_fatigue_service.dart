import 'dart:convert';
import 'dart:math';

/// Decision Fatigue Detector — autonomous decision quality monitor that
/// tracks decision-making patterns throughout the day, detects cognitive
/// degradation signals, estimates remaining decision capacity, identifies
/// peak quality windows, and proactively recommends batching/deferring
/// decisions when fatigue is predicted.
///
/// Core concepts:
/// - **Decision Event**: each choice made with weight, category, and outcome
/// - **Quality Score**: estimated quality of decisions (drops with fatigue)
/// - **Capacity**: daily decision budget that depletes with each choice
/// - **Fatigue Signal**: behavioral indicators that quality is degrading
/// - **Peak Window**: time slots when decision quality is historically highest
/// - **Batch Suggestion**: recommendation to group similar decisions together
/// - **Deferral Alert**: proactive warning to postpone important decisions

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Decision weight categories.
enum DecisionWeight {
  trivial,
  minor,
  moderate,
  significant,
  critical;

  String get label {
    switch (this) {
      case DecisionWeight.trivial:
        return 'Trivial';
      case DecisionWeight.minor:
        return 'Minor';
      case DecisionWeight.moderate:
        return 'Moderate';
      case DecisionWeight.significant:
        return 'Significant';
      case DecisionWeight.critical:
        return 'Critical';
    }
  }

  /// Cognitive cost multiplier.
  double get cost {
    switch (this) {
      case DecisionWeight.trivial:
        return 1.0;
      case DecisionWeight.minor:
        return 2.5;
      case DecisionWeight.moderate:
        return 5.0;
      case DecisionWeight.significant:
        return 10.0;
      case DecisionWeight.critical:
        return 20.0;
    }
  }

  String get emoji {
    switch (this) {
      case DecisionWeight.trivial:
        return '·';
      case DecisionWeight.minor:
        return '○';
      case DecisionWeight.moderate:
        return '●';
      case DecisionWeight.significant:
        return '◆';
      case DecisionWeight.critical:
        return '★';
    }
  }
}

/// Decision category for pattern grouping.
enum DecisionCategory {
  scheduling,
  financial,
  social,
  dietary,
  professional,
  creative,
  health,
  logistics,
  purchasing,
  prioritization;

  String get label {
    switch (this) {
      case DecisionCategory.scheduling:
        return 'Scheduling';
      case DecisionCategory.financial:
        return 'Financial';
      case DecisionCategory.social:
        return 'Social';
      case DecisionCategory.dietary:
        return 'Dietary';
      case DecisionCategory.professional:
        return 'Professional';
      case DecisionCategory.creative:
        return 'Creative';
      case DecisionCategory.health:
        return 'Health';
      case DecisionCategory.logistics:
        return 'Logistics';
      case DecisionCategory.purchasing:
        return 'Purchasing';
      case DecisionCategory.prioritization:
        return 'Prioritization';
    }
  }

  String get emoji {
    switch (this) {
      case DecisionCategory.scheduling:
        return '📅';
      case DecisionCategory.financial:
        return '💰';
      case DecisionCategory.social:
        return '👥';
      case DecisionCategory.dietary:
        return '🍽️';
      case DecisionCategory.professional:
        return '💼';
      case DecisionCategory.creative:
        return '🎨';
      case DecisionCategory.health:
        return '🏥';
      case DecisionCategory.logistics:
        return '🚚';
      case DecisionCategory.purchasing:
        return '🛒';
      case DecisionCategory.prioritization:
        return '🎯';
    }
  }
}

/// Fatigue level classification.
enum FatigueLevel {
  fresh,
  alert,
  mildlyTired,
  fatigued,
  exhausted;

  String get label {
    switch (this) {
      case FatigueLevel.fresh:
        return 'Fresh';
      case FatigueLevel.alert:
        return 'Alert';
      case FatigueLevel.mildlyTired:
        return 'Mildly Tired';
      case FatigueLevel.fatigued:
        return 'Fatigued';
      case FatigueLevel.exhausted:
        return 'Exhausted';
    }
  }

  String get emoji {
    switch (this) {
      case FatigueLevel.fresh:
        return '🌟';
      case FatigueLevel.alert:
        return '✅';
      case FatigueLevel.mildlyTired:
        return '😐';
      case FatigueLevel.fatigued:
        return '😓';
      case FatigueLevel.exhausted:
        return '🧠💤';
    }
  }

  /// Threshold for capacity remaining (0-100).
  double get capacityThreshold {
    switch (this) {
      case FatigueLevel.fresh:
        return 80.0;
      case FatigueLevel.alert:
        return 60.0;
      case FatigueLevel.mildlyTired:
        return 40.0;
      case FatigueLevel.fatigued:
        return 20.0;
      case FatigueLevel.exhausted:
        return 0.0;
    }
  }
}

/// Type of fatigue signal detected.
enum FatigueSignalType {
  decisionSpeedDrop,
  choiceAvoidance,
  defaultBias,
  impulsiveChoice,
  optionOverload,
  reversalFrequency,
  deliberationCollapse,
  categorySwitch;

  String get label {
    switch (this) {
      case FatigueSignalType.decisionSpeedDrop:
        return 'Speed Degradation';
      case FatigueSignalType.choiceAvoidance:
        return 'Choice Avoidance';
      case FatigueSignalType.defaultBias:
        return 'Default Bias';
      case FatigueSignalType.impulsiveChoice:
        return 'Impulsive Choice';
      case FatigueSignalType.optionOverload:
        return 'Option Overload';
      case FatigueSignalType.reversalFrequency:
        return 'Reversal Frequency';
      case FatigueSignalType.deliberationCollapse:
        return 'Deliberation Collapse';
      case FatigueSignalType.categorySwitch:
        return 'Category Switch Cost';
    }
  }

  String get description {
    switch (this) {
      case FatigueSignalType.decisionSpeedDrop:
        return 'Decisions taking significantly longer than baseline';
      case FatigueSignalType.choiceAvoidance:
        return 'Postponing or delegating decisions that normally get made';
      case FatigueSignalType.defaultBias:
        return 'Choosing defaults/status-quo more often than usual';
      case FatigueSignalType.impulsiveChoice:
        return 'Making rapid choices without normal deliberation';
      case FatigueSignalType.optionOverload:
        return 'Feeling overwhelmed by number of alternatives';
      case FatigueSignalType.reversalFrequency:
        return 'Changing mind more often than baseline';
      case FatigueSignalType.deliberationCollapse:
        return 'Skipping comparison/evaluation steps';
      case FatigueSignalType.categorySwitch:
        return 'Rapid switching between unrelated decision types';
    }
  }
}

/// Recommendation type.
enum RecommendationType {
  batchSimilar,
  deferHeavy,
  eliminateOptions,
  useHeuristic,
  delegateChoice,
  restFirst,
  scheduleForPeak,
  simplifyFraming;

  String get label {
    switch (this) {
      case RecommendationType.batchSimilar:
        return 'Batch Similar Decisions';
      case RecommendationType.deferHeavy:
        return 'Defer Heavy Decisions';
      case RecommendationType.eliminateOptions:
        return 'Eliminate Options';
      case RecommendationType.useHeuristic:
        return 'Use Heuristic Rule';
      case RecommendationType.delegateChoice:
        return 'Delegate Choice';
      case RecommendationType.restFirst:
        return 'Rest Before Deciding';
      case RecommendationType.scheduleForPeak:
        return 'Schedule for Peak Window';
      case RecommendationType.simplifyFraming:
        return 'Simplify the Framing';
    }
  }

  String get emoji {
    switch (this) {
      case RecommendationType.batchSimilar:
        return '📦';
      case RecommendationType.deferHeavy:
        return '⏰';
      case RecommendationType.eliminateOptions:
        return '✂️';
      case RecommendationType.useHeuristic:
        return '🧭';
      case RecommendationType.delegateChoice:
        return '🤝';
      case RecommendationType.restFirst:
        return '☕';
      case RecommendationType.scheduleForPeak:
        return '🎯';
      case RecommendationType.simplifyFraming:
        return '🔍';
    }
  }
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// A single decision event.
class DecisionEvent {
  final String id;
  final DateTime timestamp;
  final String description;
  final DecisionWeight weight;
  final DecisionCategory category;
  final int optionsConsidered;
  final Duration deliberationTime;
  final bool wasReversed;
  final bool usedDefault;
  final bool wasDeferred;
  final double? satisfactionScore; // 0-10 post-hoc rating

  DecisionEvent({
    required this.id,
    required this.timestamp,
    required this.description,
    required this.weight,
    required this.category,
    this.optionsConsidered = 2,
    this.deliberationTime = const Duration(seconds: 30),
    this.wasReversed = false,
    this.usedDefault = false,
    this.wasDeferred = false,
    this.satisfactionScore,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'description': description,
        'weight': weight.name,
        'category': category.name,
        'optionsConsidered': optionsConsidered,
        'deliberationTimeMs': deliberationTime.inMilliseconds,
        'wasReversed': wasReversed,
        'usedDefault': usedDefault,
        'wasDeferred': wasDeferred,
        'satisfactionScore': satisfactionScore,
      };

  factory DecisionEvent.fromJson(Map<String, dynamic> json) => DecisionEvent(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        description: json['description'] as String,
        weight: DecisionWeight.values.firstWhere(
            (w) => w.name == json['weight'],
            orElse: () => DecisionWeight.moderate),
        category: DecisionCategory.values.firstWhere(
            (c) => c.name == json['category'],
            orElse: () => DecisionCategory.prioritization),
        optionsConsidered: json['optionsConsidered'] as int? ?? 2,
        deliberationTime:
            Duration(milliseconds: json['deliberationTimeMs'] as int? ?? 30000),
        wasReversed: json['wasReversed'] as bool? ?? false,
        usedDefault: json['usedDefault'] as bool? ?? false,
        wasDeferred: json['wasDeferred'] as bool? ?? false,
        satisfactionScore: (json['satisfactionScore'] as num?)?.toDouble(),
      );
}

/// A detected fatigue signal.
class FatigueSignal {
  final FatigueSignalType type;
  final double intensity; // 0-1
  final DateTime detectedAt;
  final String evidence;

  FatigueSignal({
    required this.type,
    required this.intensity,
    required this.detectedAt,
    required this.evidence,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'intensity': intensity,
        'detectedAt': detectedAt.toIso8601String(),
        'evidence': evidence,
      };
}

/// Peak decision quality window.
class PeakWindow {
  final int hourStart;
  final int hourEnd;
  final double averageQuality; // 0-100
  final int sampleCount;

  PeakWindow({
    required this.hourStart,
    required this.hourEnd,
    required this.averageQuality,
    required this.sampleCount,
  });

  String get timeRange =>
      '${hourStart.toString().padLeft(2, '0')}:00 - ${hourEnd.toString().padLeft(2, '0')}:00';

  Map<String, dynamic> toJson() => {
        'hourStart': hourStart,
        'hourEnd': hourEnd,
        'averageQuality': averageQuality,
        'sampleCount': sampleCount,
      };
}

/// Batch suggestion for similar pending decisions.
class BatchSuggestion {
  final DecisionCategory category;
  final List<String> pendingDecisions;
  final String suggestedTimeSlot;
  final double estimatedTimeSavedMinutes;
  final String rationale;

  BatchSuggestion({
    required this.category,
    required this.pendingDecisions,
    required this.suggestedTimeSlot,
    required this.estimatedTimeSavedMinutes,
    required this.rationale,
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'pendingDecisions': pendingDecisions,
        'suggestedTimeSlot': suggestedTimeSlot,
        'estimatedTimeSavedMinutes': estimatedTimeSavedMinutes,
        'rationale': rationale,
      };
}

/// A proactive recommendation.
class FatigueRecommendation {
  final RecommendationType type;
  final String message;
  final double confidence; // 0-1
  final double urgency; // 0-1
  final String? actionableStep;

  FatigueRecommendation({
    required this.type,
    required this.message,
    required this.confidence,
    required this.urgency,
    this.actionableStep,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'message': message,
        'confidence': confidence,
        'urgency': urgency,
        'actionableStep': actionableStep,
      };
}

/// Daily decision capacity state.
class CapacityState {
  final double maxCapacity;
  final double currentCapacity;
  final FatigueLevel fatigueLevel;
  final int decisionsToday;
  final double totalCostToday;
  final double qualityEstimate; // 0-100
  final DateTime lastUpdated;

  CapacityState({
    required this.maxCapacity,
    required this.currentCapacity,
    required this.fatigueLevel,
    required this.decisionsToday,
    required this.totalCostToday,
    required this.qualityEstimate,
    required this.lastUpdated,
  });

  double get capacityPercent =>
      maxCapacity > 0 ? (currentCapacity / maxCapacity * 100).clamp(0, 100) : 0;

  Map<String, dynamic> toJson() => {
        'maxCapacity': maxCapacity,
        'currentCapacity': currentCapacity,
        'fatigueLevel': fatigueLevel.name,
        'decisionsToday': decisionsToday,
        'totalCostToday': totalCostToday,
        'qualityEstimate': qualityEstimate,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}

/// Full fatigue analysis report.
class FatigueReport {
  final CapacityState capacity;
  final List<FatigueSignal> signals;
  final List<PeakWindow> peakWindows;
  final List<BatchSuggestion> batchSuggestions;
  final List<FatigueRecommendation> recommendations;
  final Map<DecisionCategory, int> categoryBreakdown;
  final double overallFatigueScore; // 0-100 (higher = more fatigued)
  final List<String> insights;
  final DateTime generatedAt;

  FatigueReport({
    required this.capacity,
    required this.signals,
    required this.peakWindows,
    required this.batchSuggestions,
    required this.recommendations,
    required this.categoryBreakdown,
    required this.overallFatigueScore,
    required this.insights,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'capacity': capacity.toJson(),
        'signals': signals.map((s) => s.toJson()).toList(),
        'peakWindows': peakWindows.map((p) => p.toJson()).toList(),
        'batchSuggestions': batchSuggestions.map((b) => b.toJson()).toList(),
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'categoryBreakdown':
            categoryBreakdown.map((k, v) => MapEntry(k.name, v)),
        'overallFatigueScore': overallFatigueScore,
        'insights': insights,
        'generatedAt': generatedAt.toIso8601String(),
      };
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Autonomous Decision Fatigue Detector service.
///
/// Tracks decision events, detects fatigue patterns, and generates
/// proactive recommendations to optimize decision quality.
class DecisionFatigueService {
  /// All recorded decision events (most recent first after sort).
  final List<DecisionEvent> _events = [];

  /// Max daily cognitive capacity (configurable per user).
  double _maxDailyCapacity;

  /// Recovery rate per hour of rest.
  final double _recoveryPerHour;

  /// Baseline deliberation time for detecting speed changes (ms).
  double _baselineDeliberationMs;

  /// Pending decisions for batch analysis.
  final List<Map<String, dynamic>> _pendingDecisions = [];

  DecisionFatigueService({
    double maxDailyCapacity = 100.0,
    double recoveryPerHour = 8.0,
    double baselineDeliberationMs = 45000.0,
  })  : _maxDailyCapacity = maxDailyCapacity,
        _recoveryPerHour = recoveryPerHour,
        _baselineDeliberationMs = baselineDeliberationMs;

  // -------------------------------------------------------------------------
  // Event Recording
  // -------------------------------------------------------------------------

  /// Record a new decision event.
  void recordDecision(DecisionEvent event) {
    _events.add(event);
  }

  /// Add a pending decision for batch suggestion analysis.
  void addPendingDecision({
    required String description,
    required DecisionCategory category,
    required DecisionWeight weight,
  }) {
    _pendingDecisions.add({
      'description': description,
      'category': category,
      'weight': weight,
    });
  }

  /// Clear pending decisions (after they've been batched/handled).
  void clearPendingDecisions() {
    _pendingDecisions.clear();
  }

  /// Get all recorded events.
  List<DecisionEvent> get events => List.unmodifiable(_events);

  /// Get today's events.
  List<DecisionEvent> getTodayEvents({DateTime? now}) {
    final today = now ?? DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _events.where((e) => e.timestamp.isAfter(startOfDay)).toList();
  }

  /// Get today's events pre-sorted by timestamp (ascending).
  ///
  /// Filters and sorts in a single pass instead of letting each caller
  /// independently copy + sort the same list.  Methods like
  /// [detectFatigueSignals], [getCapacityState], and [generateInsights]
  /// that previously sorted their own copy now accept an optional
  /// pre-sorted list to avoid redundant O(n log n) work.
  List<DecisionEvent> _getTodayEventsSorted({DateTime? now}) {
    final today = now ?? DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final list = _events.where((e) => e.timestamp.isAfter(startOfDay)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  // -------------------------------------------------------------------------
  // Capacity Analysis
  // -------------------------------------------------------------------------

  /// Calculate current capacity state.
  ///
  /// Accepts an optional [sortedToday] list (pre-sorted ascending by
  /// timestamp) to avoid re-filtering and re-sorting when called from
  /// [generateReport] which already has the data.
  CapacityState getCapacityState(
      {DateTime? now, List<DecisionEvent>? sortedToday}) {
    final currentTime = now ?? DateTime.now();
    final todayEvents =
        sortedToday ?? _getTodayEventsSorted(now: currentTime);
    final totalCost =
        todayEvents.fold<double>(0, (sum, e) => sum + e.weight.cost);

    // Apply time-based partial recovery (every 2h gap = some recovery)
    double recoveredAmount = 0;
    if (todayEvents.isNotEmpty) {
      // todayEvents is already sorted — no need to re-sort.
      for (int i = 1; i < todayEvents.length; i++) {
        final gap = todayEvents[i]
            .timestamp
            .difference(todayEvents[i - 1].timestamp);
        if (gap.inMinutes > 120) {
          recoveredAmount += _recoveryPerHour * (gap.inMinutes / 60.0) * 0.3;
        }
      }
    }

    final effectiveCost = (totalCost - recoveredAmount).clamp(0.0, double.infinity);
    final currentCapacity =
        (_maxDailyCapacity - effectiveCost).clamp(0.0, _maxDailyCapacity);
    final capacityPct = currentCapacity / _maxDailyCapacity * 100;

    final fatigueLevel = _classifyFatigue(capacityPct);
    final qualityEstimate = _estimateQuality(capacityPct, todayEvents);

    return CapacityState(
      maxCapacity: _maxDailyCapacity,
      currentCapacity: currentCapacity,
      fatigueLevel: fatigueLevel,
      decisionsToday: todayEvents.length,
      totalCostToday: totalCost,
      qualityEstimate: qualityEstimate,
      lastUpdated: currentTime,
    );
  }

  FatigueLevel _classifyFatigue(double capacityPct) {
    if (capacityPct >= 80) return FatigueLevel.fresh;
    if (capacityPct >= 60) return FatigueLevel.alert;
    if (capacityPct >= 40) return FatigueLevel.mildlyTired;
    if (capacityPct >= 20) return FatigueLevel.fatigued;
    return FatigueLevel.exhausted;
  }

  double _estimateQuality(double capacityPct, List<DecisionEvent> today) {
    // Quality degrades non-linearly as capacity drops
    // Fresh: 90-100, Alert: 75-90, Mildly: 55-75, Fatigued: 30-55, Exhausted: 0-30
    double baseQuality = 30 + (capacityPct * 0.7);

    // Penalize rapid sequential decisions (no breathing room)
    if (today.length >= 2) {
      final last = today.last;
      final secondLast = today[today.length - 2];
      final gap = last.timestamp.difference(secondLast.timestamp);
      if (gap.inMinutes < 5) {
        baseQuality -= 5;
      }
    }

    // Bonus for decisions with high satisfaction scores
    final ratedDecisions =
        today.where((e) => e.satisfactionScore != null).toList();
    if (ratedDecisions.isNotEmpty) {
      final avgSatisfaction =
          ratedDecisions.fold<double>(0, (s, e) => s + e.satisfactionScore!) /
              ratedDecisions.length;
      baseQuality = baseQuality * 0.7 + avgSatisfaction * 3.0;
    }

    return baseQuality.clamp(0, 100);
  }

  // -------------------------------------------------------------------------
  // Fatigue Signal Detection
  // -------------------------------------------------------------------------

  /// Detect active fatigue signals from recent decision patterns.
  ///
  /// Accepts an optional [sortedToday] list (pre-sorted ascending by
  /// timestamp) to avoid redundant filtering + sorting when called
  /// from [generateReport].
  List<FatigueSignal> detectFatigueSignals(
      {DateTime? now, List<DecisionEvent>? sortedToday}) {
    final currentTime = now ?? DateTime.now();
    // Sort once here; pass the sorted list to every sub-detector that
    // previously made its own copy + sort (3 redundant O(n log n) passes
    // eliminated).
    final todayEvents =
        sortedToday ?? _getTodayEventsSorted(now: currentTime);
    final signals = <FatigueSignal>[];

    if (todayEvents.length < 3) return signals;

    // 1. Decision Speed Drop
    final speedSignal = _detectSpeedDrop(todayEvents, currentTime);
    if (speedSignal != null) signals.add(speedSignal);

    // 2. Choice Avoidance (high deferral rate)
    final avoidanceSignal = _detectChoiceAvoidance(todayEvents, currentTime);
    if (avoidanceSignal != null) signals.add(avoidanceSignal);

    // 3. Default Bias
    final defaultSignal = _detectDefaultBias(todayEvents, currentTime);
    if (defaultSignal != null) signals.add(defaultSignal);

    // 4. Impulsive Choice (very short deliberation on significant decisions)
    final impulsiveSignal = _detectImpulsiveChoice(todayEvents, currentTime);
    if (impulsiveSignal != null) signals.add(impulsiveSignal);

    // 5. Reversal Frequency
    final reversalSignal = _detectReversalFrequency(todayEvents, currentTime);
    if (reversalSignal != null) signals.add(reversalSignal);

    // 6. Deliberation Collapse (options considered drops)
    final collapseSignal =
        _detectDeliberationCollapse(todayEvents, currentTime);
    if (collapseSignal != null) signals.add(collapseSignal);

    // 7. Category Switch Cost
    final switchSignal = _detectCategorySwitching(todayEvents, currentTime);
    if (switchSignal != null) signals.add(switchSignal);

    return signals;
  }

  /// [events] must be pre-sorted ascending by timestamp.
  FatigueSignal? _detectSpeedDrop(
      List<DecisionEvent> events, DateTime now) {
    if (events.length < 4) return null;
    // events is already sorted — no copy + sort needed.
    final mid = events.length ~/ 2;
    final firstHalf = events.sublist(0, mid);
    final secondHalf = events.sublist(mid);

    final avgFirst = firstHalf.fold<double>(
            0, (s, e) => s + e.deliberationTime.inMilliseconds) /
        firstHalf.length;
    final avgSecond = secondHalf.fold<double>(
            0, (s, e) => s + e.deliberationTime.inMilliseconds) /
        secondHalf.length;

    // If second half is > 60% slower, it's a speed drop signal
    if (avgFirst > 0 && avgSecond > avgFirst * 1.6) {
      final intensity = ((avgSecond / avgFirst - 1.0) / 2.0).clamp(0.0, 1.0);
      return FatigueSignal(
        type: FatigueSignalType.decisionSpeedDrop,
        intensity: intensity,
        detectedAt: now,
        evidence:
            'Avg deliberation increased from ${(avgFirst / 1000).toStringAsFixed(1)}s to ${(avgSecond / 1000).toStringAsFixed(1)}s',
      );
    }
    return null;
  }

  FatigueSignal? _detectChoiceAvoidance(
      List<DecisionEvent> events, DateTime now) {
    final deferredCount = events.where((e) => e.wasDeferred).length;
    final deferRate = deferredCount / events.length;

    if (deferRate > 0.3) {
      return FatigueSignal(
        type: FatigueSignalType.choiceAvoidance,
        intensity: (deferRate - 0.3).clamp(0.0, 1.0) / 0.7,
        detectedAt: now,
        evidence:
            '${(deferRate * 100).toStringAsFixed(0)}% of decisions deferred (${deferredCount}/${events.length})',
      );
    }
    return null;
  }

  FatigueSignal? _detectDefaultBias(
      List<DecisionEvent> events, DateTime now) {
    final defaultCount = events.where((e) => e.usedDefault).length;
    final defaultRate = defaultCount / events.length;

    if (defaultRate > 0.4) {
      return FatigueSignal(
        type: FatigueSignalType.defaultBias,
        intensity: (defaultRate - 0.4).clamp(0.0, 1.0) / 0.6,
        detectedAt: now,
        evidence:
            '${(defaultRate * 100).toStringAsFixed(0)}% choices went with default (${defaultCount}/${events.length})',
      );
    }
    return null;
  }

  FatigueSignal? _detectImpulsiveChoice(
      List<DecisionEvent> events, DateTime now) {
    // Significant+ decisions with very short deliberation
    final heavyDecisions = events
        .where((e) =>
            e.weight == DecisionWeight.significant ||
            e.weight == DecisionWeight.critical)
        .toList();

    if (heavyDecisions.isEmpty) return null;

    final impulsiveCount = heavyDecisions
        .where((e) => e.deliberationTime.inSeconds < 10)
        .length;
    final rate = impulsiveCount / heavyDecisions.length;

    if (rate > 0.3) {
      return FatigueSignal(
        type: FatigueSignalType.impulsiveChoice,
        intensity: rate.clamp(0.0, 1.0),
        detectedAt: now,
        evidence:
            '${impulsiveCount} significant decisions made in < 10s deliberation',
      );
    }
    return null;
  }

  FatigueSignal? _detectReversalFrequency(
      List<DecisionEvent> events, DateTime now) {
    final reversedCount = events.where((e) => e.wasReversed).length;
    final rate = reversedCount / events.length;

    if (rate > 0.2) {
      return FatigueSignal(
        type: FatigueSignalType.reversalFrequency,
        intensity: (rate - 0.2).clamp(0.0, 1.0) / 0.8,
        detectedAt: now,
        evidence:
            '${(rate * 100).toStringAsFixed(0)}% of decisions were reversed (${reversedCount}/${events.length})',
      );
    }
    return null;
  }

  /// [events] must be pre-sorted ascending by timestamp.
  FatigueSignal? _detectDeliberationCollapse(
      List<DecisionEvent> events, DateTime now) {
    if (events.length < 6) return null;
    // events is already sorted — no copy + sort needed.
    final mid = events.length ~/ 2;
    final firstHalf = events.sublist(0, mid);
    final secondHalf = events.sublist(mid);

    final avgOptionsFirst =
        firstHalf.fold<double>(0, (s, e) => s + e.optionsConsidered) /
            firstHalf.length;
    final avgOptionsSecond =
        secondHalf.fold<double>(0, (s, e) => s + e.optionsConsidered) /
            secondHalf.length;

    if (avgOptionsFirst > 2 && avgOptionsSecond < avgOptionsFirst * 0.6) {
      final dropPct = 1.0 - (avgOptionsSecond / avgOptionsFirst);
      return FatigueSignal(
        type: FatigueSignalType.deliberationCollapse,
        intensity: dropPct.clamp(0.0, 1.0),
        detectedAt: now,
        evidence:
            'Options considered dropped from avg ${avgOptionsFirst.toStringAsFixed(1)} to ${avgOptionsSecond.toStringAsFixed(1)}',
      );
    }
    return null;
  }

  /// [events] must be pre-sorted ascending by timestamp.
  FatigueSignal? _detectCategorySwitching(
      List<DecisionEvent> events, DateTime now) {
    if (events.length < 5) return null;
    // events is already sorted — no copy + sort needed.
    int switches = 0;
    for (int i = 1; i < events.length; i++) {
      if (events[i].category != events[i - 1].category) {
        switches++;
      }
    }

    final switchRate = switches / (events.length - 1);
    if (switchRate > 0.8) {
      return FatigueSignal(
        type: FatigueSignalType.categorySwitch,
        intensity: (switchRate - 0.8).clamp(0.0, 1.0) / 0.2,
        detectedAt: now,
        evidence:
            '${switches} category switches in ${events.length} decisions (${(switchRate * 100).toStringAsFixed(0)}% switch rate)',
      );
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Peak Window Detection
  // -------------------------------------------------------------------------

  /// Identify peak decision quality windows from historical data.
  List<PeakWindow> identifyPeakWindows() {
    if (_events.length < 10) return [];

    // Group events by hour of day
    final hourBuckets = <int, List<DecisionEvent>>{};
    for (final event in _events) {
      final hour = event.timestamp.hour;
      hourBuckets.putIfAbsent(hour, () => []).add(event);
    }

    // Calculate quality proxy per hour (satisfaction + non-reversal + proper deliberation)
    final hourScores = <int, double>{};
    for (final entry in hourBuckets.entries) {
      final events = entry.value;
      if (events.length < 2) continue;

      double qualitySum = 0;
      for (final e in events) {
        double q = 50.0; // baseline
        if (e.satisfactionScore != null) q += (e.satisfactionScore! - 5) * 10;
        if (!e.wasReversed) q += 10;
        if (!e.usedDefault) q += 5;
        if (!e.wasDeferred) q += 5;
        if (e.deliberationTime.inSeconds > 5 &&
            e.deliberationTime.inSeconds < 300) q += 10;
        qualitySum += q;
      }
      hourScores[entry.key] = qualitySum / events.length;
    }

    if (hourScores.isEmpty) return [];

    // Find contiguous high-quality windows (top 30% of hours)
    final sortedHours = hourScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final threshold =
        sortedHours[min(2, sortedHours.length - 1)].value * 0.9;

    final peakHours = hourScores.entries
        .where((e) => e.value >= threshold)
        .map((e) => e.key)
        .toList()
      ..sort();

    // Group into contiguous windows
    final windows = <PeakWindow>[];
    if (peakHours.isNotEmpty) {
      int start = peakHours[0];
      int end = peakHours[0];

      for (int i = 1; i < peakHours.length; i++) {
        if (peakHours[i] == end + 1) {
          end = peakHours[i];
        } else {
          windows.add(PeakWindow(
            hourStart: start,
            hourEnd: end + 1,
            averageQuality: _avgScoreForRange(hourScores, start, end),
            sampleCount: _sampleCountForRange(hourBuckets, start, end),
          ));
          start = peakHours[i];
          end = peakHours[i];
        }
      }
      windows.add(PeakWindow(
        hourStart: start,
        hourEnd: end + 1,
        averageQuality: _avgScoreForRange(hourScores, start, end),
        sampleCount: _sampleCountForRange(hourBuckets, start, end),
      ));
    }

    return windows;
  }

  double _avgScoreForRange(Map<int, double> scores, int start, int end) {
    double sum = 0;
    int count = 0;
    for (int h = start; h <= end; h++) {
      if (scores.containsKey(h)) {
        sum += scores[h]!;
        count++;
      }
    }
    return count > 0 ? sum / count : 0;
  }

  int _sampleCountForRange(
      Map<int, List<DecisionEvent>> buckets, int start, int end) {
    int count = 0;
    for (int h = start; h <= end; h++) {
      count += buckets[h]?.length ?? 0;
    }
    return count;
  }

  // -------------------------------------------------------------------------
  // Batch Suggestions
  // -------------------------------------------------------------------------

  /// Generate batch suggestions for pending similar decisions.
  List<BatchSuggestion> generateBatchSuggestions() {
    if (_pendingDecisions.isEmpty) return [];

    // Group pending by category
    final groups = <DecisionCategory, List<Map<String, dynamic>>>{};
    for (final pd in _pendingDecisions) {
      final cat = pd['category'] as DecisionCategory;
      groups.putIfAbsent(cat, () => []).add(pd);
    }

    final suggestions = <BatchSuggestion>[];
    final peaks = identifyPeakWindows();
    final peakTime = peaks.isNotEmpty ? peaks.first.timeRange : '09:00 - 11:00';

    for (final entry in groups.entries) {
      if (entry.value.length >= 2) {
        final totalWeight = entry.value.fold<double>(
            0, (s, pd) => s + (pd['weight'] as DecisionWeight).cost);
        final timeSaved =
            entry.value.length * 2.5; // ~2.5 min context-switch savings each

        suggestions.add(BatchSuggestion(
          category: entry.key,
          pendingDecisions:
              entry.value.map((pd) => pd['description'] as String).toList(),
          suggestedTimeSlot: peakTime,
          estimatedTimeSavedMinutes: timeSaved,
          rationale:
              'Group ${entry.value.length} ${entry.key.label} decisions to reduce context-switching overhead (est. weight: ${totalWeight.toStringAsFixed(0)})',
        ));
      }
    }

    suggestions.sort(
        (a, b) => b.pendingDecisions.length.compareTo(a.pendingDecisions.length));
    return suggestions;
  }

  // -------------------------------------------------------------------------
  // Recommendations
  // -------------------------------------------------------------------------

  /// Generate proactive recommendations based on current state.
  ///
  /// Accepts pre-computed [state], [signals], and [sortedToday] to avoid
  /// redundant work when called from [generateReport].
  List<FatigueRecommendation> generateRecommendations(
      {DateTime? now,
      CapacityState? state,
      List<FatigueSignal>? signals,
      List<DecisionEvent>? sortedToday}) {
    final currentTime = now ?? DateTime.now();
    final effectiveSorted =
        sortedToday ?? _getTodayEventsSorted(now: currentTime);
    state ??= getCapacityState(now: currentTime, sortedToday: effectiveSorted);
    signals ??=
        detectFatigueSignals(now: currentTime, sortedToday: effectiveSorted);
    final recs = <FatigueRecommendation>[];

    // Based on fatigue level
    if (state.fatigueLevel == FatigueLevel.fatigued ||
        state.fatigueLevel == FatigueLevel.exhausted) {
      recs.add(FatigueRecommendation(
        type: RecommendationType.deferHeavy,
        message:
            'Your decision capacity is at ${state.capacityPercent.toStringAsFixed(0)}%. Defer any significant/critical decisions to tomorrow morning.',
        confidence: 0.9,
        urgency: 0.85,
        actionableStep:
            'Move remaining important decisions to your peak window tomorrow.',
      ));

      recs.add(FatigueRecommendation(
        type: RecommendationType.restFirst,
        message: 'Take a 20-minute break before any remaining decisions.',
        confidence: 0.85,
        urgency: 0.7,
        actionableStep:
            'Walk, nap, or do something non-cognitive for 20 minutes.',
      ));
    }

    if (state.fatigueLevel == FatigueLevel.mildlyTired) {
      recs.add(FatigueRecommendation(
        type: RecommendationType.eliminateOptions,
        message:
            'You\'re mildly fatigued. For remaining decisions, limit yourself to 2-3 options max.',
        confidence: 0.75,
        urgency: 0.5,
        actionableStep:
            'Pre-filter options before deliberating. Less choice = better choice when tired.',
      ));
    }

    // Based on signals
    for (final signal in signals) {
      switch (signal.type) {
        case FatigueSignalType.categorySwitch:
          recs.add(FatigueRecommendation(
            type: RecommendationType.batchSimilar,
            message:
                'High category switching detected. Group similar decisions together.',
            confidence: signal.intensity,
            urgency: 0.6,
            actionableStep:
                'Sort remaining decisions by type and handle one category at a time.',
          ));
          break;
        case FatigueSignalType.defaultBias:
          recs.add(FatigueRecommendation(
            type: RecommendationType.scheduleForPeak,
            message:
                'You\'re defaulting more than usual. Important choices deserve your peak energy.',
            confidence: signal.intensity,
            urgency: 0.7,
            actionableStep:
                'Schedule important non-urgent decisions for your morning peak window.',
          ));
          break;
        case FatigueSignalType.impulsiveChoice:
          recs.add(FatigueRecommendation(
            type: RecommendationType.simplifyFraming,
            message:
                'Impulsive decisions detected on significant choices. Slow down with a simple framework.',
            confidence: signal.intensity,
            urgency: 0.8,
            actionableStep:
                'For each choice: write 1 sentence for pros, 1 for cons, then decide.',
          ));
          break;
        case FatigueSignalType.optionOverload:
          recs.add(FatigueRecommendation(
            type: RecommendationType.eliminateOptions,
            message: 'Too many options are taxing your cognition.',
            confidence: signal.intensity,
            urgency: 0.6,
            actionableStep:
                'Use a "satisficing" rule: pick the first option that meets your minimum bar.',
          ));
          break;
        case FatigueSignalType.choiceAvoidance:
          recs.add(FatigueRecommendation(
            type: RecommendationType.useHeuristic,
            message:
                'Decision avoidance pattern detected. Use simple heuristic rules to unblock.',
            confidence: signal.intensity,
            urgency: 0.65,
            actionableStep:
                'Apply the 2-minute rule: if a decision takes < 2 min, just make it now.',
          ));
          break;
        case FatigueSignalType.reversalFrequency:
          recs.add(FatigueRecommendation(
            type: RecommendationType.delegateChoice,
            message:
                'High reversal rate suggests second-guessing. Consider delegating or using a coin flip for low-stakes choices.',
            confidence: signal.intensity,
            urgency: 0.55,
            actionableStep:
                'For trivial/minor decisions: delegate or commit to the first instinct.',
          ));
          break;
        default:
          break;
      }
    }

    // Batch suggestions
    final batches = generateBatchSuggestions();
    if (batches.isNotEmpty) {
      recs.add(FatigueRecommendation(
        type: RecommendationType.batchSimilar,
        message:
            '${batches.length} batch opportunities found. Grouping saves ~${batches.fold<double>(0, (s, b) => s + b.estimatedTimeSavedMinutes).toStringAsFixed(0)} min.',
        confidence: 0.8,
        urgency: 0.4,
        actionableStep:
            'Handle ${batches.first.category.label} decisions (${batches.first.pendingDecisions.length} pending) in one focused session.',
      ));
    }

    // Deduplicate by type
    final seen = <RecommendationType>{};
    final deduped = <FatigueRecommendation>[];
    for (final r in recs) {
      if (!seen.contains(r.type)) {
        seen.add(r.type);
        deduped.add(r);
      }
    }

    deduped.sort((a, b) => b.urgency.compareTo(a.urgency));
    return deduped;
  }

  // -------------------------------------------------------------------------
  // Insights Generation
  // -------------------------------------------------------------------------

  /// Generate autonomous insights from decision history.
  ///
  /// Accepts optional [sortedToday], [state], and [peaks] to reuse
  /// values already computed by [generateReport].
  List<String> generateInsights(
      {DateTime? now,
      List<DecisionEvent>? sortedToday,
      CapacityState? state,
      List<PeakWindow>? peaks}) {
    final currentTime = now ?? DateTime.now();
    final todayEvents =
        sortedToday ?? _getTodayEventsSorted(now: currentTime);
    final insights = <String>[];

    if (todayEvents.isEmpty) {
      insights.add('No decisions recorded today. Fresh capacity available.');
      return insights;
    }

    // Category dominance
    final catCounts = <DecisionCategory, int>{};
    for (final e in todayEvents) {
      catCounts[e.category] = (catCounts[e.category] ?? 0) + 1;
    }
    final topCat = catCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (topCat.isNotEmpty) {
      insights.add(
          'Most active decision area today: ${topCat.first.key.label} (${topCat.first.value} decisions)');
    }

    // Total cognitive load
    final totalCost =
        todayEvents.fold<double>(0, (s, e) => s + e.weight.cost);
    insights.add(
        'Total cognitive load: ${totalCost.toStringAsFixed(0)}/${_maxDailyCapacity.toStringAsFixed(0)} capacity units used');

    // Decision pace
    if (todayEvents.length >= 2) {
      // todayEvents is already sorted — no copy + sort needed.
      final span =
          todayEvents.last.timestamp.difference(todayEvents.first.timestamp);
      if (span.inMinutes > 0) {
        final pace = todayEvents.length / (span.inMinutes / 60.0);
        insights.add(
            'Decision pace: ${pace.toStringAsFixed(1)} decisions/hour');
        if (pace > 8) {
          insights.add(
              '⚠️ High decision velocity. Consider batching or slowing down.');
        }
      }
    }

    // Reversal rate
    final reversals = todayEvents.where((e) => e.wasReversed).length;
    if (reversals > 0) {
      insights.add(
          'Reversed ${reversals} decision${reversals > 1 ? "s" : ""} today — possible indecision signal');
    }

    // Quality trend
    state ??= getCapacityState(now: currentTime, sortedToday: todayEvents);
    if (state.qualityEstimate < 50) {
      insights.add(
          '🔻 Decision quality estimate below 50%. Consider deferring important choices.');
    } else if (state.qualityEstimate > 80) {
      insights.add(
          '✅ Decision quality is high. Good time for important choices.');
    }

    // Peak window advice
    peaks ??= identifyPeakWindows();
    if (peaks.isNotEmpty) {
      insights.add(
          '🎯 Your historical peak decision window: ${peaks.first.timeRange}');
    }

    return insights;
  }

  // -------------------------------------------------------------------------
  // Full Report
  // -------------------------------------------------------------------------

  /// Generate a complete fatigue analysis report.
  ///
  /// Computes today's sorted events once and threads them through all
  /// sub-analyses, eliminating previously redundant O(n) filter passes
  /// and O(n log n) sorts across [getCapacityState],
  /// [detectFatigueSignals], [generateRecommendations], and
  /// [generateInsights].
  FatigueReport generateReport({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    // Single-pass filter + sort for today's events.
    final sortedToday = _getTodayEventsSorted(now: currentTime);
    final state =
        getCapacityState(now: currentTime, sortedToday: sortedToday);
    final signals =
        detectFatigueSignals(now: currentTime, sortedToday: sortedToday);
    final peaks = identifyPeakWindows();
    final batches = generateBatchSuggestions();
    final recs = generateRecommendations(
        now: currentTime,
        state: state,
        signals: signals,
        sortedToday: sortedToday);
    final insights = generateInsights(
        now: currentTime,
        sortedToday: sortedToday,
        state: state,
        peaks: peaks);

    final catBreakdown = <DecisionCategory, int>{};
    for (final e in sortedToday) {
      catBreakdown[e.category] = (catBreakdown[e.category] ?? 0) + 1;
    }

    // Composite fatigue score from capacity + signals
    double signalIntensity = signals.isEmpty
        ? 0
        : signals.fold<double>(0, (s, sig) => s + sig.intensity) /
            signals.length;
    final fatigueScore =
        ((100 - state.capacityPercent) * 0.6 + signalIntensity * 100 * 0.4)
            .clamp(0.0, 100.0);

    return FatigueReport(
      capacity: state,
      signals: signals,
      peakWindows: peaks,
      batchSuggestions: batches,
      recommendations: recs,
      categoryBreakdown: catBreakdown,
      overallFatigueScore: fatigueScore,
      insights: insights,
      generatedAt: currentTime,
    );
  }

  // -------------------------------------------------------------------------
  // Serialization
  // -------------------------------------------------------------------------

  /// Export full state to JSON.
  Map<String, dynamic> toJson() => {
        'events': _events.map((e) => e.toJson()).toList(),
        'maxDailyCapacity': _maxDailyCapacity,
        'recoveryPerHour': _recoveryPerHour,
        'baselineDeliberationMs': _baselineDeliberationMs,
        'pendingDecisions': _pendingDecisions
            .map((pd) => {
                  return {
                    'description': pd['description'],
                    'category': (pd['category'] as DecisionCategory).name,
                    'weight': (pd['weight'] as DecisionWeight).name,
                  };
                })
            .toList(),
      };

  /// Restore from JSON.
  factory DecisionFatigueService.fromJson(Map<String, dynamic> json) {
    final svc = DecisionFatigueService(
      maxDailyCapacity:
          (json['maxDailyCapacity'] as num?)?.toDouble() ?? 100.0,
      recoveryPerHour: (json['recoveryPerHour'] as num?)?.toDouble() ?? 8.0,
      baselineDeliberationMs:
          (json['baselineDeliberationMs'] as num?)?.toDouble() ?? 45000.0,
    );

    final eventsJson = json['events'] as List<dynamic>? ?? [];
    for (final ej in eventsJson) {
      svc.recordDecision(
          DecisionEvent.fromJson(ej as Map<String, dynamic>));
    }

    final pendingJson = json['pendingDecisions'] as List<dynamic>? ?? [];
    for (final pj in pendingJson) {
      final pd = pj as Map<String, dynamic>;
      svc.addPendingDecision(
        description: pd['description'] as String,
        category: DecisionCategory.values.firstWhere(
            (c) => c.name == pd['category'],
            orElse: () => DecisionCategory.prioritization),
        weight: DecisionWeight.values.firstWhere(
            (w) => w.name == pd['weight'],
            orElse: () => DecisionWeight.moderate),
      );
    }

    return svc;
  }

  /// Export to JSON string.
  String export() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Import from JSON string.
  static DecisionFatigueService import(String jsonStr) =>
      DecisionFatigueService.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>);
}
