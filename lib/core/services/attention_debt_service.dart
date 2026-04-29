import 'dart:math';

/// Attention Debt Tracker — autonomous cognitive overhead monitor that tracks
/// deferred decisions, postponed tasks, and accumulated mental load items.
/// Models "attention debt" like financial debt: items accrue cognitive interest
/// over time, and the system generates autonomous debt reduction sprints.
///
/// Core concepts:
/// - **Debt Item**: any deferred decision, postponed task, or unresolved mental load
/// - **Cognitive Interest**: the growing mental cost of keeping something unresolved
/// - **Debt Score**: composite measure of total cognitive overhead (0-100, lower is better)
/// - **Sprint**: a focused time-boxed session to resolve high-interest items
/// - **Bankruptcy Threshold**: when debt score exceeds capacity, triggers emergency triage
/// - **Amortization Plan**: autonomous scheduling of debt resolution over time

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Category of attention debt.
enum AttentionDebtCategory {
  deferredDecision,
  postponedTask,
  unresolvedConflict,
  pendingResponse,
  incompleteProject,
  avoidedConversation,
  undefinedGoal,
  informationBacklog;

  String get label {
    switch (this) {
      case AttentionDebtCategory.deferredDecision:
        return 'Deferred Decision';
      case AttentionDebtCategory.postponedTask:
        return 'Postponed Task';
      case AttentionDebtCategory.unresolvedConflict:
        return 'Unresolved Conflict';
      case AttentionDebtCategory.pendingResponse:
        return 'Pending Response';
      case AttentionDebtCategory.incompleteProject:
        return 'Incomplete Project';
      case AttentionDebtCategory.avoidedConversation:
        return 'Avoided Conversation';
      case AttentionDebtCategory.undefinedGoal:
        return 'Undefined Goal';
      case AttentionDebtCategory.informationBacklog:
        return 'Information Backlog';
    }
  }

  String get emoji {
    switch (this) {
      case AttentionDebtCategory.deferredDecision:
        return '🤷';
      case AttentionDebtCategory.postponedTask:
        return '⏳';
      case AttentionDebtCategory.unresolvedConflict:
        return '⚔️';
      case AttentionDebtCategory.pendingResponse:
        return '📨';
      case AttentionDebtCategory.incompleteProject:
        return '🏗️';
      case AttentionDebtCategory.avoidedConversation:
        return '🙈';
      case AttentionDebtCategory.undefinedGoal:
        return '🎯';
      case AttentionDebtCategory.informationBacklog:
        return '📚';
    }
  }

  /// Daily interest rate (percentage of base cost added per day unresolved).
  double get dailyInterestRate {
    switch (this) {
      case AttentionDebtCategory.deferredDecision:
        return 0.08; // 8% per day
      case AttentionDebtCategory.postponedTask:
        return 0.05; // 5% per day
      case AttentionDebtCategory.unresolvedConflict:
        return 0.12; // 12% per day — conflicts compound fast
      case AttentionDebtCategory.pendingResponse:
        return 0.10; // 10% per day
      case AttentionDebtCategory.incompleteProject:
        return 0.03; // 3% per day — slow but steady
      case AttentionDebtCategory.avoidedConversation:
        return 0.15; // 15% per day — avoidance is expensive
      case AttentionDebtCategory.undefinedGoal:
        return 0.04; // 4% per day
      case AttentionDebtCategory.informationBacklog:
        return 0.06; // 6% per day
    }
  }

  /// Base cognitive cost (1-20 scale).
  int get baseCost {
    switch (this) {
      case AttentionDebtCategory.deferredDecision:
        return 10;
      case AttentionDebtCategory.postponedTask:
        return 8;
      case AttentionDebtCategory.unresolvedConflict:
        return 16;
      case AttentionDebtCategory.pendingResponse:
        return 6;
      case AttentionDebtCategory.incompleteProject:
        return 14;
      case AttentionDebtCategory.avoidedConversation:
        return 12;
      case AttentionDebtCategory.undefinedGoal:
        return 9;
      case AttentionDebtCategory.informationBacklog:
        return 7;
    }
  }
}

/// Urgency level based on accumulated interest.
enum DebtUrgency {
  low,
  moderate,
  high,
  critical,
  bankruptcy;

  String get label {
    switch (this) {
      case DebtUrgency.low:
        return 'Low';
      case DebtUrgency.moderate:
        return 'Moderate';
      case DebtUrgency.high:
        return 'High';
      case DebtUrgency.critical:
        return 'Critical';
      case DebtUrgency.bankruptcy:
        return 'Bankruptcy';
    }
  }

  String get emoji {
    switch (this) {
      case DebtUrgency.low:
        return '🟢';
      case DebtUrgency.moderate:
        return '🟡';
      case DebtUrgency.high:
        return '🟠';
      case DebtUrgency.critical:
        return '🔴';
      case DebtUrgency.bankruptcy:
        return '💀';
    }
  }

  String get colorHex {
    switch (this) {
      case DebtUrgency.low:
        return '#4CAF50';
      case DebtUrgency.moderate:
        return '#FFC107';
      case DebtUrgency.high:
        return '#FF9800';
      case DebtUrgency.critical:
        return '#F44336';
      case DebtUrgency.bankruptcy:
        return '#9C27B0';
    }
  }
}

/// Sprint type for debt reduction.
enum SprintType {
  microSprint, // 15 min — resolve 1-2 quick items
  focusSprint, // 45 min — tackle 1 medium item deeply
  deepClean, // 2 hours — clear multiple items
  emergencyTriage; // when in bankruptcy mode

  String get label {
    switch (this) {
      case SprintType.microSprint:
        return 'Micro Sprint (15 min)';
      case SprintType.focusSprint:
        return 'Focus Sprint (45 min)';
      case SprintType.deepClean:
        return 'Deep Clean (2 hr)';
      case SprintType.emergencyTriage:
        return 'Emergency Triage';
    }
  }

  int get durationMinutes {
    switch (this) {
      case SprintType.microSprint:
        return 15;
      case SprintType.focusSprint:
        return 45;
      case SprintType.deepClean:
        return 120;
      case SprintType.emergencyTriage:
        return 60;
    }
  }
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// A single attention debt item.
class AttentionDebtItem {
  final String id;
  final String title;
  final String? description;
  final AttentionDebtCategory category;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final int baseCost; // override or use category default
  final List<String> tags;
  final int timesPostponed;

  const AttentionDebtItem({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.createdAt,
    this.resolvedAt,
    required this.baseCost,
    this.tags = const [],
    this.timesPostponed = 0,
  });

  bool get isResolved => resolvedAt != null;

  /// Days this item has been open.
  int get daysOpen {
    final end = resolvedAt ?? DateTime.now();
    return end.difference(createdAt).inDays;
  }

  /// Current total cognitive cost including accrued interest.
  double get currentCost {
    final rate = category.dailyInterestRate;
    final days = daysOpen;
    // Compound interest: baseCost * (1 + rate)^days
    return baseCost * pow(1 + rate, days);
  }

  /// Interest accrued so far.
  double get accruedInterest => currentCost - baseCost;

  /// Postponement penalty multiplier (each postponement adds 20%).
  double get postponementMultiplier => 1.0 + (timesPostponed * 0.20);

  /// Effective cost including postponement penalty.
  double get effectiveCost => currentCost * postponementMultiplier;

  /// Urgency classification based on effective cost vs base cost ratio.
  DebtUrgency get urgency {
    final ratio = effectiveCost / baseCost;
    if (ratio < 1.5) return DebtUrgency.low;
    if (ratio < 3.0) return DebtUrgency.moderate;
    if (ratio < 6.0) return DebtUrgency.high;
    if (ratio < 12.0) return DebtUrgency.critical;
    return DebtUrgency.bankruptcy;
  }

  AttentionDebtItem copyWith({
    String? title,
    String? description,
    AttentionDebtCategory? category,
    DateTime? resolvedAt,
    int? baseCost,
    List<String>? tags,
    int? timesPostponed,
  }) {
    return AttentionDebtItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      baseCost: baseCost ?? this.baseCost,
      tags: tags ?? this.tags,
      timesPostponed: timesPostponed ?? this.timesPostponed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.index,
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'baseCost': baseCost,
        'tags': tags,
        'timesPostponed': timesPostponed,
      };

  factory AttentionDebtItem.fromJson(Map<String, dynamic> json) {
    return AttentionDebtItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: AttentionDebtCategory.values[json['category'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      baseCost: json['baseCost'] as int,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      timesPostponed: json['timesPostponed'] as int? ?? 0,
    );
  }
}

/// A debt reduction sprint session.
class DebtSprint {
  final String id;
  final SprintType type;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<String> targetItemIds;
  final List<String> resolvedItemIds;
  final double debtReduced;

  const DebtSprint({
    required this.id,
    required this.type,
    required this.startedAt,
    this.completedAt,
    this.targetItemIds = const [],
    this.resolvedItemIds = const [],
    this.debtReduced = 0,
  });

  bool get isComplete => completedAt != null;

  double get efficiency {
    if (resolvedItemIds.isEmpty) return 0;
    return resolvedItemIds.length / targetItemIds.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'targetItemIds': targetItemIds,
        'resolvedItemIds': resolvedItemIds,
        'debtReduced': debtReduced,
      };

  factory DebtSprint.fromJson(Map<String, dynamic> json) {
    return DebtSprint(
      id: json['id'] as String,
      type: SprintType.values[json['type'] as int],
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      targetItemIds:
          (json['targetItemIds'] as List<dynamic>?)?.cast<String>() ?? [],
      resolvedItemIds:
          (json['resolvedItemIds'] as List<dynamic>?)?.cast<String>() ?? [],
      debtReduced: (json['debtReduced'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Amortization plan entry — a scheduled debt resolution step.
class AmortizationEntry {
  final DateTime scheduledDate;
  final List<String> itemIds;
  final SprintType recommendedSprint;
  final double expectedReduction;

  const AmortizationEntry({
    required this.scheduledDate,
    required this.itemIds,
    required this.recommendedSprint,
    required this.expectedReduction,
  });
}

/// Portfolio-level debt summary.
class DebtPortfolio {
  final double totalDebt;
  final double totalInterestAccrued;
  final int openItems;
  final int resolvedItems;
  final double debtScore; // 0-100, higher = more overwhelmed
  final DebtUrgency overallUrgency;
  final Map<AttentionDebtCategory, double> debtByCategory;
  final List<AttentionDebtItem> topOffenders; // highest cost items
  final List<AmortizationEntry> amortizationPlan;
  final String autonomousInsight;

  const DebtPortfolio({
    required this.totalDebt,
    required this.totalInterestAccrued,
    required this.openItems,
    required this.resolvedItems,
    required this.debtScore,
    required this.overallUrgency,
    required this.debtByCategory,
    required this.topOffenders,
    required this.amortizationPlan,
    required this.autonomousInsight,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Autonomous attention debt tracking and resolution planning service.
class AttentionDebtService {
  final List<AttentionDebtItem> _items = [];
  final List<DebtSprint> _sprints = [];
  static const double _bankruptcyThreshold = 80.0;
  static const int _maxCapacity = 500; // max effective debt before bankruptcy

  List<AttentionDebtItem> get items => List.unmodifiable(_items);
  List<AttentionDebtItem> get openItems =>
      _items.where((i) => !i.isResolved).toList();
  List<AttentionDebtItem> get resolvedItems =>
      _items.where((i) => i.isResolved).toList();
  List<DebtSprint> get sprints => List.unmodifiable(_sprints);

  // ── CRUD ──

  void addItem(AttentionDebtItem item) => _items.add(item);

  void resolveItem(String id) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(resolvedAt: DateTime.now());
    }
  }

  void postponeItem(String id) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(
        timesPostponed: _items[idx].timesPostponed + 1,
      );
    }
  }

  void removeItem(String id) => _items.removeWhere((i) => i.id == id);

  // ── Analysis ──

  /// Calculate total effective debt across all open items.
  double get totalDebt =>
      openItems.fold(0.0, (sum, item) => sum + item.effectiveCost);

  /// Total interest accrued across all open items.
  double get totalInterestAccrued =>
      openItems.fold(0.0, (sum, item) => sum + item.accruedInterest);

  /// Debt score: 0-100 scale where 100 = total cognitive bankruptcy.
  double get debtScore {
    final debt = totalDebt;
    // Sigmoid-like scaling: debt/_maxCapacity mapped to 0-100
    return min(100, (debt / _maxCapacity) * 100);
  }

  /// Overall urgency classification.
  DebtUrgency get overallUrgency {
    final score = debtScore;
    if (score < 20) return DebtUrgency.low;
    if (score < 40) return DebtUrgency.moderate;
    if (score < 60) return DebtUrgency.high;
    if (score < _bankruptcyThreshold) return DebtUrgency.critical;
    return DebtUrgency.bankruptcy;
  }

  /// Debt broken down by category.
  Map<AttentionDebtCategory, double> get debtByCategory {
    final map = <AttentionDebtCategory, double>{};
    for (final item in openItems) {
      map[item.category] = (map[item.category] ?? 0) + item.effectiveCost;
    }
    return map;
  }

  /// Top N most expensive open items.
  List<AttentionDebtItem> topOffenders([int n = 5]) {
    final sorted = openItems.toList()
      ..sort((a, b) => b.effectiveCost.compareTo(a.effectiveCost));
    return sorted.take(n).toList();
  }

  /// Items that will hit critical urgency within N days if not resolved.
  List<AttentionDebtItem> itemsApproachingCritical({int withinDays = 7}) {
    return openItems.where((item) {
      if (item.urgency == DebtUrgency.critical ||
          item.urgency == DebtUrgency.bankruptcy) return false;
      // Simulate future cost
      final futureCost = item.baseCost *
          pow(1 + item.category.dailyInterestRate, item.daysOpen + withinDays) *
          item.postponementMultiplier;
      final futureRatio = futureCost / item.baseCost;
      return futureRatio >= 6.0; // critical threshold
    }).toList();
  }

  // ── Sprint Planning ──

  /// Generate an autonomous sprint recommendation based on current debt state.
  SprintType get recommendedSprintType {
    final score = debtScore;
    if (score >= _bankruptcyThreshold) return SprintType.emergencyTriage;
    if (score >= 60) return SprintType.deepClean;
    if (score >= 30) return SprintType.focusSprint;
    return SprintType.microSprint;
  }

  /// Select items for a sprint based on priority (highest interest rate first,
  /// then highest effective cost, limited by sprint duration capacity).
  List<AttentionDebtItem> planSprintItems(SprintType type) {
    final sorted = openItems.toList()
      ..sort((a, b) {
        // Priority: urgency desc, then interest rate desc, then cost desc
        final urgencyCompare = b.urgency.index.compareTo(a.urgency.index);
        if (urgencyCompare != 0) return urgencyCompare;
        final rateCompare = b.category.dailyInterestRate
            .compareTo(a.category.dailyInterestRate);
        if (rateCompare != 0) return rateCompare;
        return b.effectiveCost.compareTo(a.effectiveCost);
      });

    // Estimate capacity: ~1 item per 15 min for simple, 1 per 30 for complex
    final maxItems = (type.durationMinutes / 20).ceil();
    return sorted.take(maxItems).toList();
  }

  /// Start a new sprint.
  DebtSprint startSprint(SprintType type) {
    final items = planSprintItems(type);
    final sprint = DebtSprint(
      id: 'sprint_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      startedAt: DateTime.now(),
      targetItemIds: items.map((i) => i.id).toList(),
    );
    _sprints.add(sprint);
    return sprint;
  }

  /// Complete a sprint, marking resolved items.
  void completeSprint(String sprintId, List<String> resolvedIds) {
    final idx = _sprints.indexWhere((s) => s.id == sprintId);
    if (idx < 0) return;

    double reduced = 0;
    for (final id in resolvedIds) {
      final item = _items.where((i) => i.id == id).firstOrNull;
      if (item != null) {
        reduced += item.effectiveCost;
        resolveItem(id);
      }
    }

    _sprints[idx] = DebtSprint(
      id: _sprints[idx].id,
      type: _sprints[idx].type,
      startedAt: _sprints[idx].startedAt,
      completedAt: DateTime.now(),
      targetItemIds: _sprints[idx].targetItemIds,
      resolvedItemIds: resolvedIds,
      debtReduced: reduced,
    );
  }

  // ── Amortization Plan ──

  /// Generate an autonomous amortization plan to clear all debt in N days.
  List<AmortizationEntry> generateAmortizationPlan({int targetDays = 14}) {
    if (openItems.isEmpty) return [];

    final plan = <AmortizationEntry>[];
    final remaining = openItems.toList()
      ..sort((a, b) => b.effectiveCost.compareTo(a.effectiveCost));

    final itemsPerDay = max(1, (remaining.length / targetDays).ceil());
    final now = DateTime.now();

    for (int day = 0; day < targetDays && remaining.isNotEmpty; day++) {
      final batch = remaining.take(itemsPerDay).toList();
      remaining.removeRange(0, min(itemsPerDay, remaining.length));

      final sprintType = batch.length <= 2
          ? SprintType.microSprint
          : batch.length <= 4
              ? SprintType.focusSprint
              : SprintType.deepClean;

      plan.add(AmortizationEntry(
        scheduledDate: now.add(Duration(days: day + 1)),
        itemIds: batch.map((i) => i.id).toList(),
        recommendedSprint: sprintType,
        expectedReduction:
            batch.fold(0.0, (sum, i) => sum + i.effectiveCost),
      ));
    }
    return plan;
  }

  // ── Autonomous Insights ──

  /// Generate an autonomous insight about the current debt situation.
  String generateInsight() {
    if (openItems.isEmpty) {
      return '🎉 Debt-free! Your cognitive overhead is zero. Enjoy the clarity.';
    }

    final score = debtScore;
    final topCategory = debtByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (score >= _bankruptcyThreshold) {
      return '🚨 COGNITIVE BANKRUPTCY: ${openItems.length} unresolved items '
          'consuming ${totalDebt.toStringAsFixed(0)} cognitive units. '
          'Emergency triage needed NOW. Top debt source: '
          '${topCategory.first.key.label}.';
    }

    if (score >= 60) {
      final approaching = itemsApproachingCritical();
      return '⚠️ High cognitive load (score: ${score.toStringAsFixed(0)}/100). '
          '${approaching.length} items approaching critical within 7 days. '
          'Recommend a Deep Clean sprint targeting '
          '${topCategory.first.key.label} items.';
    }

    final oldestOpen = openItems.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final oldest = oldestOpen.first;
    final interestRate =
        (totalInterestAccrued / max(1, totalDebt) * 100).toStringAsFixed(1);

    return '📊 ${openItems.length} open items, debt score ${score.toStringAsFixed(0)}/100. '
        'Oldest item: "${oldest.title}" (${oldest.daysOpen} days, '
        '${oldest.accruedInterest.toStringAsFixed(1)} interest accrued). '
        'Portfolio interest rate: $interestRate%. '
        '${oldest.daysOpen > 14 ? "Consider resolving long-standing items first." : "Debt is manageable — maintain with micro-sprints."}';
  }

  // ── Full Portfolio ──

  /// Generate a complete debt portfolio analysis.
  DebtPortfolio getPortfolio() {
    return DebtPortfolio(
      totalDebt: totalDebt,
      totalInterestAccrued: totalInterestAccrued,
      openItems: openItems.length,
      resolvedItems: resolvedItems.length,
      debtScore: debtScore,
      overallUrgency: overallUrgency,
      debtByCategory: debtByCategory,
      topOffenders: topOffenders(),
      amortizationPlan: generateAmortizationPlan(),
      autonomousInsight: generateInsight(),
    );
  }

  // ── Persistence ──

  Map<String, dynamic> toJson() => {
        'items': _items.map((i) => i.toJson()).toList(),
        'sprints': _sprints.map((s) => s.toJson()).toList(),
      };

  void loadFromJson(Map<String, dynamic> json) {
    _items.clear();
    _sprints.clear();
    if (json['items'] != null) {
      for (final item in json['items'] as List<dynamic>) {
        _items.add(AttentionDebtItem.fromJson(item as Map<String, dynamic>));
      }
    }
    if (json['sprints'] != null) {
      for (final sprint in json['sprints'] as List<dynamic>) {
        _sprints.add(DebtSprint.fromJson(sprint as Map<String, dynamic>));
      }
    }
  }

  // ── Sample Data ──

  void loadSampleData() {
    final now = DateTime.now();
    final items = [
      AttentionDebtItem(
        id: 'debt_1',
        title: 'Decide on health insurance plan',
        description: 'Open enrollment ends soon, 3 options to compare',
        category: AttentionDebtCategory.deferredDecision,
        createdAt: now.subtract(const Duration(days: 12)),
        baseCost: 14,
        tags: ['finance', 'health'],
        timesPostponed: 2,
      ),
      AttentionDebtItem(
        id: 'debt_2',
        title: 'Reply to old colleague about coffee',
        category: AttentionDebtCategory.pendingResponse,
        createdAt: now.subtract(const Duration(days: 8)),
        baseCost: 5,
        tags: ['social'],
      ),
      AttentionDebtItem(
        id: 'debt_3',
        title: 'Organize garage',
        description: 'Has been on the list for weeks',
        category: AttentionDebtCategory.postponedTask,
        createdAt: now.subtract(const Duration(days: 21)),
        baseCost: 10,
        tags: ['home'],
        timesPostponed: 4,
      ),
      AttentionDebtItem(
        id: 'debt_4',
        title: 'Have performance conversation with manager',
        category: AttentionDebtCategory.avoidedConversation,
        createdAt: now.subtract(const Duration(days: 15)),
        baseCost: 15,
        tags: ['work', 'career'],
        timesPostponed: 3,
      ),
      AttentionDebtItem(
        id: 'debt_5',
        title: 'Define Q2 personal goals',
        category: AttentionDebtCategory.undefinedGoal,
        createdAt: now.subtract(const Duration(days: 30)),
        baseCost: 11,
        tags: ['growth'],
        timesPostponed: 1,
      ),
      AttentionDebtItem(
        id: 'debt_6',
        title: 'Clear 200+ unread articles in read-later',
        category: AttentionDebtCategory.informationBacklog,
        createdAt: now.subtract(const Duration(days: 45)),
        baseCost: 8,
        tags: ['reading'],
      ),
      AttentionDebtItem(
        id: 'debt_7',
        title: 'Finish side project MVP',
        description: '80% done but stalled 3 weeks ago',
        category: AttentionDebtCategory.incompleteProject,
        createdAt: now.subtract(const Duration(days: 25)),
        baseCost: 16,
        tags: ['code', 'personal'],
        timesPostponed: 2,
      ),
      AttentionDebtItem(
        id: 'debt_8',
        title: 'Address roommate disagreement about chores',
        category: AttentionDebtCategory.unresolvedConflict,
        createdAt: now.subtract(const Duration(days: 5)),
        baseCost: 13,
        tags: ['home', 'relationship'],
      ),
    ];

    for (final item in items) {
      _items.add(item);
    }
  }
}
