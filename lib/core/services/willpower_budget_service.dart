import 'dart:math';

/// Willpower Budget Engine — autonomous cognitive resource manager that
/// models daily willpower as a finite, depletable resource (ego depletion
/// theory). Tracks cognitive demands, estimates remaining budget, predicts
/// decision fatigue windows, and generates strategic recovery recommendations.
///
/// Core concepts:
/// - **Budget**: starts at 100 each day, drained by cognitive demands
/// - **Zone**: classified state based on remaining budget (fullTank → empty)
/// - **Demand**: each decision/resistance/focus block costs willpower
/// - **Recovery**: strategic actions that partially restore budget
/// - **Fatigue Forecast**: predicts when budget crosses danger thresholds
/// - **Strategic Score**: how well the user manages their cognitive resources

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Current willpower zone based on remaining budget.
enum WillpowerZone {
  fullTank,
  comfortable,
  stretching,
  depleted,
  empty;

  String get label {
    switch (this) {
      case WillpowerZone.fullTank:
        return 'Full Tank';
      case WillpowerZone.comfortable:
        return 'Comfortable';
      case WillpowerZone.stretching:
        return 'Stretching';
      case WillpowerZone.depleted:
        return 'Depleted';
      case WillpowerZone.empty:
        return 'Empty';
    }
  }

  String get emoji {
    switch (this) {
      case WillpowerZone.fullTank:
        return '🔋';
      case WillpowerZone.comfortable:
        return '✅';
      case WillpowerZone.stretching:
        return '⚡';
      case WillpowerZone.depleted:
        return '🪫';
      case WillpowerZone.empty:
        return '💀';
    }
  }

  String get colorHex {
    switch (this) {
      case WillpowerZone.fullTank:
        return '#4CAF50';
      case WillpowerZone.comfortable:
        return '#8BC34A';
      case WillpowerZone.stretching:
        return '#FF9800';
      case WillpowerZone.depleted:
        return '#F44336';
      case WillpowerZone.empty:
        return '#9E9E9E';
    }
  }

  String get advice {
    switch (this) {
      case WillpowerZone.fullTank:
        return 'Great time for hard decisions and challenging tasks.';
      case WillpowerZone.comfortable:
        return 'You have capacity. Tackle important items now.';
      case WillpowerZone.stretching:
        return 'Getting thin. Prioritize — defer non-essential decisions.';
      case WillpowerZone.depleted:
        return 'Decision fatigue likely. Stick to routines and easy wins.';
      case WillpowerZone.empty:
        return 'Stop. Rest and recover before any more decisions.';
    }
  }
}

/// Types of cognitive demands that drain willpower.
enum CognitiveDemandType {
  decision,
  resistance,
  focusBlock,
  socialInteraction,
  novelTask,
  routineBreak,
  emotionalRegulation,
  creativeWork;

  String get label {
    switch (this) {
      case CognitiveDemandType.decision:
        return 'Decision';
      case CognitiveDemandType.resistance:
        return 'Resistance';
      case CognitiveDemandType.focusBlock:
        return 'Focus Block';
      case CognitiveDemandType.socialInteraction:
        return 'Social Interaction';
      case CognitiveDemandType.novelTask:
        return 'Novel Task';
      case CognitiveDemandType.routineBreak:
        return 'Routine Break';
      case CognitiveDemandType.emotionalRegulation:
        return 'Emotional Regulation';
      case CognitiveDemandType.creativeWork:
        return 'Creative Work';
    }
  }

  String get emoji {
    switch (this) {
      case CognitiveDemandType.decision:
        return '🤔';
      case CognitiveDemandType.resistance:
        return '🛡️';
      case CognitiveDemandType.focusBlock:
        return '🎯';
      case CognitiveDemandType.socialInteraction:
        return '👥';
      case CognitiveDemandType.novelTask:
        return '🆕';
      case CognitiveDemandType.routineBreak:
        return '🔀';
      case CognitiveDemandType.emotionalRegulation:
        return '🧘';
      case CognitiveDemandType.creativeWork:
        return '🎨';
    }
  }

  /// Base willpower cost (1–25 scale).
  int get baseCost {
    switch (this) {
      case CognitiveDemandType.decision:
        return 12;
      case CognitiveDemandType.resistance:
        return 18;
      case CognitiveDemandType.focusBlock:
        return 15;
      case CognitiveDemandType.socialInteraction:
        return 8;
      case CognitiveDemandType.novelTask:
        return 14;
      case CognitiveDemandType.routineBreak:
        return 10;
      case CognitiveDemandType.emotionalRegulation:
        return 20;
      case CognitiveDemandType.creativeWork:
        return 16;
    }
  }
}

/// Recovery actions that restore willpower.
enum RecoveryAction {
  microBreak,
  snack,
  natureWalk,
  easyWin,
  powerNap,
  meditation,
  socialChat,
  mindlessTask;

  String get label {
    switch (this) {
      case RecoveryAction.microBreak:
        return 'Micro Break';
      case RecoveryAction.snack:
        return 'Healthy Snack';
      case RecoveryAction.natureWalk:
        return 'Nature Walk';
      case RecoveryAction.easyWin:
        return 'Easy Win Task';
      case RecoveryAction.powerNap:
        return 'Power Nap';
      case RecoveryAction.meditation:
        return 'Meditation';
      case RecoveryAction.socialChat:
        return 'Social Chat';
      case RecoveryAction.mindlessTask:
        return 'Mindless Task';
    }
  }

  String get emoji {
    switch (this) {
      case RecoveryAction.microBreak:
        return '☕';
      case RecoveryAction.snack:
        return '🍎';
      case RecoveryAction.natureWalk:
        return '🌿';
      case RecoveryAction.easyWin:
        return '✅';
      case RecoveryAction.powerNap:
        return '😴';
      case RecoveryAction.meditation:
        return '🧘';
      case RecoveryAction.socialChat:
        return '💬';
      case RecoveryAction.mindlessTask:
        return '🧹';
    }
  }

  /// How many willpower points this action restores.
  int get recoveryPoints {
    switch (this) {
      case RecoveryAction.microBreak:
        return 5;
      case RecoveryAction.snack:
        return 8;
      case RecoveryAction.natureWalk:
        return 20;
      case RecoveryAction.easyWin:
        return 10;
      case RecoveryAction.powerNap:
        return 25;
      case RecoveryAction.meditation:
        return 15;
      case RecoveryAction.socialChat:
        return 7;
      case RecoveryAction.mindlessTask:
        return 6;
    }
  }

  /// Typical duration in minutes.
  int get durationMinutes {
    switch (this) {
      case RecoveryAction.microBreak:
        return 5;
      case RecoveryAction.snack:
        return 10;
      case RecoveryAction.natureWalk:
        return 20;
      case RecoveryAction.easyWin:
        return 10;
      case RecoveryAction.powerNap:
        return 20;
      case RecoveryAction.meditation:
        return 15;
      case RecoveryAction.socialChat:
        return 10;
      case RecoveryAction.mindlessTask:
        return 15;
    }
  }
}

// ---------------------------------------------------------------------------
// Data Classes
// ---------------------------------------------------------------------------

/// A single cognitive demand that drains willpower.
class CognitiveDemand {
  final String id;
  final CognitiveDemandType type;
  final String description;
  final DateTime timestamp;
  final int intensity; // 1–10
  final double contextMultiplier;

  const CognitiveDemand({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    this.intensity = 5,
    this.contextMultiplier = 1.0,
  });

  /// Actual willpower cost = baseCost × (intensity/5) × contextMultiplier.
  double get actualCost =>
      type.baseCost * (intensity / 5.0) * contextMultiplier;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'intensity': intensity,
        'contextMultiplier': contextMultiplier,
      };

  factory CognitiveDemand.fromJson(Map<String, dynamic> json) =>
      CognitiveDemand(
        id: json['id'] as String,
        type: CognitiveDemandType.values.byName(json['type'] as String),
        description: json['description'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        intensity: json['intensity'] as int? ?? 5,
        contextMultiplier:
            (json['contextMultiplier'] as num?)?.toDouble() ?? 1.0,
      );
}

/// A point-in-time snapshot of the willpower budget.
class WillpowerSnapshot {
  final DateTime timestamp;
  final double budget;
  final WillpowerZone zone;
  final int demandsSinceLastSnapshot;
  final double cumulativeDrain;

  const WillpowerSnapshot({
    required this.timestamp,
    required this.budget,
    required this.zone,
    required this.demandsSinceLastSnapshot,
    required this.cumulativeDrain,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'budget': budget,
        'zone': zone.name,
        'demandsSinceLastSnapshot': demandsSinceLastSnapshot,
        'cumulativeDrain': cumulativeDrain,
      };

  factory WillpowerSnapshot.fromJson(Map<String, dynamic> json) =>
      WillpowerSnapshot(
        timestamp: DateTime.parse(json['timestamp'] as String),
        budget: (json['budget'] as num).toDouble(),
        zone: WillpowerZone.values.byName(json['zone'] as String),
        demandsSinceLastSnapshot:
            json['demandsSinceLastSnapshot'] as int? ?? 0,
        cumulativeDrain:
            (json['cumulativeDrain'] as num?)?.toDouble() ?? 0,
      );
}

/// A predicted future time window where fatigue is expected.
class FatigueWindow {
  final int startHour;
  final int endHour;
  final double predictedBudget;
  final WillpowerZone riskLevel;
  final String explanation;

  const FatigueWindow({
    required this.startHour,
    required this.endHour,
    required this.predictedBudget,
    required this.riskLevel,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'startHour': startHour,
        'endHour': endHour,
        'predictedBudget': predictedBudget,
        'riskLevel': riskLevel.name,
        'explanation': explanation,
      };

  factory FatigueWindow.fromJson(Map<String, dynamic> json) => FatigueWindow(
        startHour: json['startHour'] as int,
        endHour: json['endHour'] as int,
        predictedBudget: (json['predictedBudget'] as num).toDouble(),
        riskLevel: WillpowerZone.values.byName(json['riskLevel'] as String),
        explanation: json['explanation'] as String,
      );
}

/// A strategic recommendation.
class WillpowerRecommendation {
  final String title;
  final String description;
  final String emoji;
  final int priority; // 1–5 (1 = highest)
  final RecoveryAction? recoveryAction;
  final String timing;

  const WillpowerRecommendation({
    required this.title,
    required this.description,
    required this.emoji,
    required this.priority,
    this.recoveryAction,
    required this.timing,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'emoji': emoji,
        'priority': priority,
        'recoveryAction': recoveryAction?.name,
        'timing': timing,
      };
}

/// End-of-day summary report.
class WillpowerDayReport {
  final DateTime date;
  final double startingBudget;
  final double currentBudget;
  final WillpowerZone zone;
  final int totalDemands;
  final double totalDrain;
  final double totalRecovery;
  final List<WillpowerSnapshot> snapshots;
  final List<FatigueWindow> fatigueWindows;
  final List<WillpowerRecommendation> recommendations;
  final double budgetEfficiency;
  final int strategicScore;

  const WillpowerDayReport({
    required this.date,
    required this.startingBudget,
    required this.currentBudget,
    required this.zone,
    required this.totalDemands,
    required this.totalDrain,
    required this.totalRecovery,
    required this.snapshots,
    required this.fatigueWindows,
    required this.recommendations,
    required this.budgetEfficiency,
    required this.strategicScore,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'startingBudget': startingBudget,
        'currentBudget': currentBudget,
        'zone': zone.name,
        'totalDemands': totalDemands,
        'totalDrain': totalDrain,
        'totalRecovery': totalRecovery,
        'snapshots': snapshots.map((s) => s.toJson()).toList(),
        'fatigueWindows': fatigueWindows.map((f) => f.toJson()).toList(),
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'budgetEfficiency': budgetEfficiency,
        'strategicScore': strategicScore,
      };
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Autonomous willpower budget tracker and cognitive resource manager.
class WillpowerBudgetService {
  final List<CognitiveDemand> _demands = [];
  final List<WillpowerSnapshot> _snapshots = [];
  final List<RecoveryAction> _recoveries = [];
  double _baselineBudget = 100.0;
  double _recoveryTotal = 0.0;
  int _nextId = 1;

  /// All demands logged today.
  List<CognitiveDemand> get demands => List.unmodifiable(_demands);

  /// Baseline budget (default 100).
  double get baselineBudget => _baselineBudget;
  set baselineBudget(double v) => _baselineBudget = v.clamp(50, 150);

  // ── Logging ──

  /// Log a cognitive demand and return the created entry.
  CognitiveDemand logDemand(
    CognitiveDemandType type, {
    String description = '',
    int intensity = 5,
    double contextMultiplier = 1.0,
  }) {
    final demand = CognitiveDemand(
      id: 'wp_${_nextId++}',
      type: type,
      description: description.isEmpty ? type.label : description,
      timestamp: DateTime.now(),
      intensity: intensity.clamp(1, 10),
      contextMultiplier: contextMultiplier.clamp(0.5, 3.0),
    );
    _demands.add(demand);
    return demand;
  }

  /// Log a recovery action.
  void logRecovery(RecoveryAction action) {
    _recoveries.add(action);
    _recoveryTotal += action.recoveryPoints;
  }

  // ── Budget Calculation ──

  /// Total willpower drained by all logged demands.
  double get totalDrain =>
      _demands.fold(0.0, (sum, d) => sum + d.actualCost);

  /// Current budget (clamped 0–100).
  double currentBudget() =>
      (_baselineBudget - totalDrain + _recoveryTotal).clamp(0, 100);

  /// Current willpower zone.
  WillpowerZone currentZone() {
    final b = currentBudget();
    if (b > 80) return WillpowerZone.fullTank;
    if (b > 60) return WillpowerZone.comfortable;
    if (b > 40) return WillpowerZone.stretching;
    if (b > 20) return WillpowerZone.depleted;
    return WillpowerZone.empty;
  }

  /// Take a snapshot of current state.
  WillpowerSnapshot takeSnapshot() {
    final snap = WillpowerSnapshot(
      timestamp: DateTime.now(),
      budget: currentBudget(),
      zone: currentZone(),
      demandsSinceLastSnapshot: _snapshots.isEmpty
          ? _demands.length
          : _demands
              .where((d) => d.timestamp.isAfter(_snapshots.last.timestamp))
              .length,
      cumulativeDrain: totalDrain,
    );
    _snapshots.add(snap);
    return snap;
  }

  // ── Forecasting ──

  /// Hourly drain rate based on demands so far.
  double getHourlyDrainRate() {
    if (_demands.isEmpty) return 0;
    final first = _demands.first.timestamp;
    final elapsed = DateTime.now().difference(first).inMinutes / 60.0;
    if (elapsed < 0.1) return totalDrain;
    return totalDrain / elapsed;
  }

  /// Predict fatigue windows for the next [hoursAhead] hours.
  List<FatigueWindow> predictFatigueWindows({int hoursAhead = 8}) {
    final windows = <FatigueWindow>[];
    final rate = getHourlyDrainRate();
    if (rate <= 0) return windows;

    final nowHour = DateTime.now().hour;
    var projectedBudget = currentBudget();

    for (int h = 1; h <= hoursAhead; h++) {
      final futureHour = (nowHour + h) % 24;
      projectedBudget = (projectedBudget - rate).clamp(0, 100);

      final zone = _zoneForBudget(projectedBudget);
      if (zone.index >= WillpowerZone.stretching.index) {
        windows.add(FatigueWindow(
          startHour: futureHour,
          endHour: (futureHour + 1) % 24,
          predictedBudget: projectedBudget,
          riskLevel: zone,
          explanation: _fatigueExplanation(zone, futureHour),
        ));
      }
    }
    return windows;
  }

  WillpowerZone _zoneForBudget(double b) {
    if (b > 80) return WillpowerZone.fullTank;
    if (b > 60) return WillpowerZone.comfortable;
    if (b > 40) return WillpowerZone.stretching;
    if (b > 20) return WillpowerZone.depleted;
    return WillpowerZone.empty;
  }

  String _fatigueExplanation(WillpowerZone zone, int hour) {
    final timeStr = '${hour.toString().padLeft(2, '0')}:00';
    switch (zone) {
      case WillpowerZone.stretching:
        return 'Budget projected to thin by $timeStr — defer hard choices.';
      case WillpowerZone.depleted:
        return 'Significant fatigue expected by $timeStr — plan recovery.';
      case WillpowerZone.empty:
        return 'Budget exhaustion predicted by $timeStr — avoid decisions.';
      default:
        return 'Budget stable at $timeStr.';
    }
  }

  // ── Analysis ──

  /// Cost breakdown by demand type.
  Map<CognitiveDemandType, double> getDemandBreakdown() {
    final map = <CognitiveDemandType, double>{};
    for (final d in _demands) {
      map[d.type] = (map[d.type] ?? 0) + d.actualCost;
    }
    return map;
  }

  /// Strategic score 0–100 measuring how well the user manages willpower.
  int strategicScore() {
    if (_demands.isEmpty) return 100;

    var score = 100.0;

    // Penalize for hitting low zones
    final budget = currentBudget();
    if (budget < 20) {
      score -= 30;
    } else if (budget < 40) {
      score -= 15;
    }

    // Reward for taking recoveries
    final recoveryRatio =
        _recoveries.isEmpty ? 0.0 : _recoveryTotal / max(totalDrain, 1);
    score += (recoveryRatio * 20).clamp(0, 20);

    // Reward for spacing demands (low variance in inter-demand gaps)
    if (_demands.length >= 3) {
      final gaps = <double>[];
      for (int i = 1; i < _demands.length; i++) {
        gaps.add(_demands[i]
            .timestamp
            .difference(_demands[i - 1].timestamp)
            .inMinutes
            .toDouble());
      }
      final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
      final variance =
          gaps.map((g) => (g - avgGap) * (g - avgGap)).reduce((a, b) => a + b) /
              gaps.length;
      final cv = avgGap > 0 ? sqrt(variance) / avgGap : 0;
      // Lower CV = more evenly spaced = better
      score += ((1.0 - cv.clamp(0, 1)) * 15);
    }

    // Penalize for too many demands without breaks
    final demandsPerRecovery =
        _recoveries.isEmpty ? _demands.length.toDouble() : _demands.length / _recoveries.length;
    if (demandsPerRecovery > 5) {
      score -= 10;
    }

    return score.round().clamp(0, 100);
  }

  /// Budget efficiency: how much useful work per unit of willpower spent.
  double budgetEfficiency() {
    if (totalDrain == 0) return 1.0;
    // Efficiency = demands completed / drain (normalized)
    return (_demands.length / totalDrain).clamp(0, 1);
  }

  // ── Recommendations ──

  /// Generate context-aware recommendations.
  List<WillpowerRecommendation> getRecommendations() {
    final recs = <WillpowerRecommendation>[];
    final zone = currentZone();
    final hour = DateTime.now().hour;

    // Zone-based recommendations
    if (zone == WillpowerZone.empty || zone == WillpowerZone.depleted) {
      recs.add(const WillpowerRecommendation(
        title: 'Take a Power Nap',
        description:
            'Your willpower is critically low. A 20-min nap can restore up to 25 points.',
        emoji: '😴',
        priority: 1,
        recoveryAction: RecoveryAction.powerNap,
        timing: 'Now',
      ));
      recs.add(const WillpowerRecommendation(
        title: 'Switch to Autopilot',
        description:
            'Avoid new decisions. Stick to routines and pre-planned tasks.',
        emoji: '🤖',
        priority: 1,
        recoveryAction: null,
        timing: 'Immediately',
      ));
    }

    if (zone == WillpowerZone.stretching) {
      recs.add(const WillpowerRecommendation(
        title: 'Quick Nature Walk',
        description:
            'Even 10 minutes outdoors can significantly restore cognitive resources.',
        emoji: '🌿',
        priority: 2,
        recoveryAction: RecoveryAction.natureWalk,
        timing: 'Within 30 min',
      ));
      recs.add(const WillpowerRecommendation(
        title: 'Grab an Easy Win',
        description:
            'Complete a simple task to build momentum without draining willpower.',
        emoji: '✅',
        priority: 2,
        recoveryAction: RecoveryAction.easyWin,
        timing: 'Next task',
      ));
    }

    // Time-based recommendations
    if (hour >= 14 && hour <= 16 && zone.index >= WillpowerZone.comfortable.index) {
      recs.add(const WillpowerRecommendation(
        title: 'Post-Lunch Dip Warning',
        description:
            'The 2–4 PM window is a natural energy low. Schedule easy tasks here.',
        emoji: '⏰',
        priority: 3,
        recoveryAction: RecoveryAction.snack,
        timing: 'Afternoon',
      ));
    }

    if (hour < 10 && zone == WillpowerZone.fullTank) {
      recs.add(const WillpowerRecommendation(
        title: 'Front-Load Hard Decisions',
        description:
            'Your willpower is fresh. Tackle your hardest decisions and tasks now.',
        emoji: '🏋️',
        priority: 2,
        recoveryAction: null,
        timing: 'This morning',
      ));
    }

    // Recovery-based
    if (_demands.length >= 4 && _recoveries.isEmpty) {
      recs.add(const WillpowerRecommendation(
        title: 'You Haven\'t Recovered Yet',
        description:
            'You\'ve logged several demands with no recovery. Take a micro-break.',
        emoji: '☕',
        priority: 1,
        recoveryAction: RecoveryAction.microBreak,
        timing: 'Now',
      ));
    }

    // Demand-type-specific
    final breakdown = getDemandBreakdown();
    final topType = breakdown.entries.isEmpty
        ? null
        : (breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .first;
    if (topType != null && topType.value > 30) {
      recs.add(WillpowerRecommendation(
        title: 'Heavy ${topType.key.label} Load',
        description:
            '${topType.key.label} tasks are your biggest drain today. Try batching them.',
        emoji: topType.key.emoji,
        priority: 3,
        recoveryAction: null,
        timing: 'Going forward',
      ));
    }

    recs.sort((a, b) => a.priority.compareTo(b.priority));
    return recs;
  }

  // ── Report ──

  /// Generate the full day report.
  WillpowerDayReport getDayReport() {
    return WillpowerDayReport(
      date: DateTime.now(),
      startingBudget: _baselineBudget,
      currentBudget: currentBudget(),
      zone: currentZone(),
      totalDemands: _demands.length,
      totalDrain: totalDrain,
      totalRecovery: _recoveryTotal,
      snapshots: List.unmodifiable(_snapshots),
      fatigueWindows: predictFatigueWindows(),
      recommendations: getRecommendations(),
      budgetEfficiency: budgetEfficiency(),
      strategicScore: strategicScore(),
    );
  }

  // ── Sample Data ──

  /// Pre-populate realistic sample data for demo purposes.
  void loadSampleDay() {
    _demands.clear();
    _snapshots.clear();
    _recoveries.clear();
    _recoveryTotal = 0;
    _nextId = 1;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Morning demands
    _addSample(CognitiveDemandType.decision,
        'Choose project priorities for the day', today.add(const Duration(hours: 8, minutes: 15)), 7);
    _addSample(CognitiveDemandType.focusBlock,
        'Deep work on quarterly report', today.add(const Duration(hours: 9)), 8);
    _addSample(CognitiveDemandType.socialInteraction,
        'Team standup meeting', today.add(const Duration(hours: 9, minutes: 45)), 4);

    // Mid-morning recovery
    logRecovery(RecoveryAction.microBreak);

    _addSample(CognitiveDemandType.creativeWork,
        'Design new feature mockups', today.add(const Duration(hours: 10, minutes: 30)), 7);
    _addSample(CognitiveDemandType.resistance,
        'Resisted checking social media', today.add(const Duration(hours: 11)), 6);
    _addSample(CognitiveDemandType.decision,
        'Lunch decision with team', today.add(const Duration(hours: 12)), 3);

    // Lunch recovery
    logRecovery(RecoveryAction.snack);
    logRecovery(RecoveryAction.socialChat);

    // Afternoon demands
    _addSample(CognitiveDemandType.novelTask,
        'Learn new deployment tool', today.add(const Duration(hours: 13, minutes: 30)), 8);
    _addSample(CognitiveDemandType.emotionalRegulation,
        'Navigate difficult feedback conversation', today.add(const Duration(hours: 14, minutes: 15)), 9);
    _addSample(CognitiveDemandType.routineBreak,
        'Unexpected production incident', today.add(const Duration(hours: 15)), 7);
    _addSample(CognitiveDemandType.focusBlock,
        'Debug intermittent test failure', today.add(const Duration(hours: 15, minutes: 45)), 6);

    // Take some snapshots
    takeSnapshot();
  }

  void _addSample(
      CognitiveDemandType type, String desc, DateTime time, int intensity) {
    _demands.add(CognitiveDemand(
      id: 'wp_${_nextId++}',
      type: type,
      description: desc,
      timestamp: time,
      intensity: intensity,
    ));
  }
}
