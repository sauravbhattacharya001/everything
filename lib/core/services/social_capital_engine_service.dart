import 'dart:convert';
import 'dart:math';

/// Social Capital Engine — autonomous relationship network health analyzer.
///
/// Goes beyond simple contact tracking to perform network-level analysis:
/// strength scoring with exponential decay, decay prediction, cluster
/// detection, reciprocity analysis, and proactive insight generation.
///
/// Core concepts:
/// - **Relationship**: a person in your network with tier and importance
/// - **Interaction**: a logged touchpoint with quality and initiator
/// - **Strength Score**: composite 0-100 per relationship (recency+frequency+quality+reciprocity)
/// - **Social Capital Score**: overall network health 0-100
/// - **Cluster**: detected group of related relationships by shared tags
/// - **Decay Prediction**: forecast when a relationship becomes dormant
/// - **Reciprocity Index**: balance of self vs other-initiated interactions
/// - **Insight**: autonomous recommendation for network maintenance

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Relationship closeness tiers.
enum RelationshipTier {
  innerCircle,
  close,
  regular,
  acquaintance,
  dormant;

  String get label {
    switch (this) {
      case RelationshipTier.innerCircle:
        return 'Inner Circle';
      case RelationshipTier.close:
        return 'Close';
      case RelationshipTier.regular:
        return 'Regular';
      case RelationshipTier.acquaintance:
        return 'Acquaintance';
      case RelationshipTier.dormant:
        return 'Dormant';
    }
  }

  String get emoji {
    switch (this) {
      case RelationshipTier.innerCircle:
        return '💎';
      case RelationshipTier.close:
        return '⭐';
      case RelationshipTier.regular:
        return '👋';
      case RelationshipTier.acquaintance:
        return '🤝';
      case RelationshipTier.dormant:
        return '💤';
    }
  }

  /// Expected minimum interactions per month for this tier.
  double get expectedMonthlyFrequency {
    switch (this) {
      case RelationshipTier.innerCircle:
        return 8.0;
      case RelationshipTier.close:
        return 4.0;
      case RelationshipTier.regular:
        return 2.0;
      case RelationshipTier.acquaintance:
        return 0.5;
      case RelationshipTier.dormant:
        return 0.0;
    }
  }
}

/// Types of interaction.
enum InteractionType {
  message,
  call,
  videoCall,
  inPerson,
  socialMedia,
  email,
  gift,
  event;

  String get label {
    switch (this) {
      case InteractionType.message:
        return 'Message';
      case InteractionType.call:
        return 'Call';
      case InteractionType.videoCall:
        return 'Video Call';
      case InteractionType.inPerson:
        return 'In Person';
      case InteractionType.socialMedia:
        return 'Social Media';
      case InteractionType.email:
        return 'Email';
      case InteractionType.gift:
        return 'Gift';
      case InteractionType.event:
        return 'Event';
    }
  }

  String get emoji {
    switch (this) {
      case InteractionType.message:
        return '💬';
      case InteractionType.call:
        return '📞';
      case InteractionType.videoCall:
        return '📹';
      case InteractionType.inPerson:
        return '🤗';
      case InteractionType.socialMedia:
        return '📱';
      case InteractionType.email:
        return '📧';
      case InteractionType.gift:
        return '🎁';
      case InteractionType.event:
        return '🎉';
    }
  }

  /// Quality weight — higher-effort interactions contribute more.
  double get qualityWeight {
    switch (this) {
      case InteractionType.inPerson:
        return 1.5;
      case InteractionType.videoCall:
        return 1.3;
      case InteractionType.call:
        return 1.2;
      case InteractionType.gift:
        return 1.4;
      case InteractionType.event:
        return 1.3;
      case InteractionType.message:
        return 1.0;
      case InteractionType.email:
        return 1.0;
      case InteractionType.socialMedia:
        return 0.8;
    }
  }
}

/// Who initiated the interaction.
enum InteractionInitiator {
  self,
  them,
  mutual;

  String get label {
    switch (this) {
      case InteractionInitiator.self:
        return 'You';
      case InteractionInitiator.them:
        return 'Them';
      case InteractionInitiator.mutual:
        return 'Mutual';
    }
  }
}

/// Types of autonomous insights.
enum InsightType {
  neglectWarning,
  decayAlert,
  reciprocityImbalance,
  clusterWeakening,
  streakBroken,
  reconnectSuggestion,
  strengthMilestone,
  networkGap;

  String get label {
    switch (this) {
      case InsightType.neglectWarning:
        return 'Neglect Warning';
      case InsightType.decayAlert:
        return 'Decay Alert';
      case InsightType.reciprocityImbalance:
        return 'Reciprocity Imbalance';
      case InsightType.clusterWeakening:
        return 'Cluster Weakening';
      case InsightType.streakBroken:
        return 'Streak Broken';
      case InsightType.reconnectSuggestion:
        return 'Reconnect Suggestion';
      case InsightType.strengthMilestone:
        return 'Strength Milestone';
      case InsightType.networkGap:
        return 'Network Gap';
    }
  }

  String get emoji {
    switch (this) {
      case InsightType.neglectWarning:
        return '⚠️';
      case InsightType.decayAlert:
        return '📉';
      case InsightType.reciprocityImbalance:
        return '⚖️';
      case InsightType.clusterWeakening:
        return '🔗';
      case InsightType.streakBroken:
        return '💔';
      case InsightType.reconnectSuggestion:
        return '🔄';
      case InsightType.strengthMilestone:
        return '🏆';
      case InsightType.networkGap:
        return '🕳️';
    }
  }
}

/// Severity levels for insights.
enum InsightSeverity {
  info,
  warning,
  critical;

  String get label {
    switch (this) {
      case InsightSeverity.info:
        return 'Info';
      case InsightSeverity.warning:
        return 'Warning';
      case InsightSeverity.critical:
        return 'Critical';
    }
  }
}

/// Cluster trend direction.
enum ClusterTrend {
  growing,
  stable,
  weakening;

  String get label {
    switch (this) {
      case ClusterTrend.growing:
        return 'Growing';
      case ClusterTrend.stable:
        return 'Stable';
      case ClusterTrend.weakening:
        return 'Weakening';
    }
  }

  String get arrow {
    switch (this) {
      case ClusterTrend.growing:
        return '↑';
      case ClusterTrend.stable:
        return '→';
      case ClusterTrend.weakening:
        return '↓';
    }
  }
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// A person in your relationship network.
class Relationship {
  final String id;
  final String name;
  final RelationshipTier tier;
  final List<String> tags;
  final int importance; // 1-10
  final DateTime createdAt;

  const Relationship({
    required this.id,
    required this.name,
    required this.tier,
    this.tags = const [],
    this.importance = 5,
    required this.createdAt,
  });

  Relationship copyWith({
    String? name,
    RelationshipTier? tier,
    List<String>? tags,
    int? importance,
  }) =>
      Relationship(
        id: id,
        name: name ?? this.name,
        tier: tier ?? this.tier,
        tags: tags ?? this.tags,
        importance: importance ?? this.importance,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tier': tier.index,
        'tags': tags,
        'importance': importance,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Relationship.fromJson(Map<String, dynamic> json) => Relationship(
        id: json['id'] as String,
        name: json['name'] as String,
        tier: RelationshipTier.values[json['tier'] as int],
        tags: (json['tags'] as List<dynamic>).cast<String>(),
        importance: json['importance'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// A logged touchpoint with someone.
class Interaction {
  final String id;
  final String relationshipId;
  final InteractionType type;
  final DateTime date;
  final int quality; // 1-5
  final InteractionInitiator initiatedBy;
  final String notes;

  const Interaction({
    required this.id,
    required this.relationshipId,
    required this.type,
    required this.date,
    this.quality = 3,
    this.initiatedBy = InteractionInitiator.mutual,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'relationshipId': relationshipId,
        'type': type.index,
        'date': date.toIso8601String(),
        'quality': quality,
        'initiatedBy': initiatedBy.index,
        'notes': notes,
      };

  factory Interaction.fromJson(Map<String, dynamic> json) => Interaction(
        id: json['id'] as String,
        relationshipId: json['relationshipId'] as String,
        type: InteractionType.values[json['type'] as int],
        date: DateTime.parse(json['date'] as String),
        quality: json['quality'] as int,
        initiatedBy:
            InteractionInitiator.values[json['initiatedBy'] as int],
        notes: (json['notes'] as String?) ?? '',
      );
}

/// Health assessment for a single relationship.
class RelationshipHealth {
  final String relationshipId;
  final double strengthScore; // 0-100
  final double recencyScore; // 0-100
  final double frequencyScore; // 0-100
  final double qualityScore; // 0-100
  final double reciprocityIndex; // -1 to 1 (0 = balanced)
  final DateTime? decayDate; // predicted dormancy date
  final RelationshipTier computedTier;

  const RelationshipHealth({
    required this.relationshipId,
    required this.strengthScore,
    required this.recencyScore,
    required this.frequencyScore,
    required this.qualityScore,
    required this.reciprocityIndex,
    this.decayDate,
    required this.computedTier,
  });

  Map<String, dynamic> toJson() => {
        'relationshipId': relationshipId,
        'strengthScore': strengthScore,
        'recencyScore': recencyScore,
        'frequencyScore': frequencyScore,
        'qualityScore': qualityScore,
        'reciprocityIndex': reciprocityIndex,
        'decayDate': decayDate?.toIso8601String(),
        'computedTier': computedTier.index,
      };

  factory RelationshipHealth.fromJson(Map<String, dynamic> json) =>
      RelationshipHealth(
        relationshipId: json['relationshipId'] as String,
        strengthScore: (json['strengthScore'] as num).toDouble(),
        recencyScore: (json['recencyScore'] as num).toDouble(),
        frequencyScore: (json['frequencyScore'] as num).toDouble(),
        qualityScore: (json['qualityScore'] as num).toDouble(),
        reciprocityIndex: (json['reciprocityIndex'] as num).toDouble(),
        decayDate: json['decayDate'] != null
            ? DateTime.parse(json['decayDate'] as String)
            : null,
        computedTier:
            RelationshipTier.values[json['computedTier'] as int],
      );
}

/// A detected cluster of related relationships.
class SocialCluster {
  final String id;
  final String name;
  final List<String> memberIds;
  final double cohesionScore; // 0-100
  final ClusterTrend trend;

  const SocialCluster({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.cohesionScore,
    required this.trend,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'memberIds': memberIds,
        'cohesionScore': cohesionScore,
        'trend': trend.index,
      };

  factory SocialCluster.fromJson(Map<String, dynamic> json) => SocialCluster(
        id: json['id'] as String,
        name: json['name'] as String,
        memberIds: (json['memberIds'] as List<dynamic>).cast<String>(),
        cohesionScore: (json['cohesionScore'] as num).toDouble(),
        trend: ClusterTrend.values[json['trend'] as int],
      );
}

/// An autonomous insight about your social network.
class SocialCapitalInsight {
  final InsightType type;
  final InsightSeverity severity;
  final String message;
  final String? relationshipId;
  final String actionSuggestion;
  final DateTime timestamp;

  const SocialCapitalInsight({
    required this.type,
    required this.severity,
    required this.message,
    this.relationshipId,
    required this.actionSuggestion,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'severity': severity.index,
        'message': message,
        'relationshipId': relationshipId,
        'actionSuggestion': actionSuggestion,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SocialCapitalInsight.fromJson(Map<String, dynamic> json) =>
      SocialCapitalInsight(
        type: InsightType.values[json['type'] as int],
        severity: InsightSeverity.values[json['severity'] as int],
        message: json['message'] as String,
        relationshipId: json['relationshipId'] as String?,
        actionSuggestion: json['actionSuggestion'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Complete network analysis result.
class SocialCapitalAnalysis {
  final double overallScore; // 0-100
  final double networkDiversity; // Shannon entropy
  final int activeRelationships;
  final int neglectedCount;
  final int strongTieCount;
  final Map<String, RelationshipHealth> healthMap;
  final List<SocialCluster> clusters;
  final List<SocialCapitalInsight> insights;
  final DateTime analyzedAt;

  const SocialCapitalAnalysis({
    required this.overallScore,
    required this.networkDiversity,
    required this.activeRelationships,
    required this.neglectedCount,
    required this.strongTieCount,
    required this.healthMap,
    required this.clusters,
    required this.insights,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() => {
        'overallScore': overallScore,
        'networkDiversity': networkDiversity,
        'activeRelationships': activeRelationships,
        'neglectedCount': neglectedCount,
        'strongTieCount': strongTieCount,
        'healthMap': healthMap.map((k, v) => MapEntry(k, v.toJson())),
        'clusters': clusters.map((c) => c.toJson()).toList(),
        'insights': insights.map((i) => i.toJson()).toList(),
        'analyzedAt': analyzedAt.toIso8601String(),
      };

  factory SocialCapitalAnalysis.fromJson(Map<String, dynamic> json) =>
      SocialCapitalAnalysis(
        overallScore: (json['overallScore'] as num).toDouble(),
        networkDiversity: (json['networkDiversity'] as num).toDouble(),
        activeRelationships: json['activeRelationships'] as int,
        neglectedCount: json['neglectedCount'] as int,
        strongTieCount: json['strongTieCount'] as int,
        healthMap: (json['healthMap'] as Map<String, dynamic>).map(
          (k, v) =>
              MapEntry(k, RelationshipHealth.fromJson(v as Map<String, dynamic>)),
        ),
        clusters: (json['clusters'] as List<dynamic>)
            .map((c) => SocialCluster.fromJson(c as Map<String, dynamic>))
            .toList(),
        insights: (json['insights'] as List<dynamic>)
            .map((i) =>
                SocialCapitalInsight.fromJson(i as Map<String, dynamic>))
            .toList(),
        analyzedAt: DateTime.parse(json['analyzedAt'] as String),
      );
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Autonomous relationship network health analyzer.
///
/// 7 engines:
/// 1. Strength Calculator — per-relationship composite scoring
/// 2. Decay Predictor — forecasts dormancy dates
/// 3. Cluster Detector — groups relationships by shared tags
/// 4. Reciprocity Analyzer — measures interaction balance
/// 5. Network Health Scorer — composite network score
/// 6. Insight Generator — autonomous recommendations
/// 7. Trend Tracker — compares against historical snapshots
class SocialCapitalEngineService {
  final List<Relationship> _relationships = [];
  final List<Interaction> _interactions = [];
  final List<SocialCapitalAnalysis> _history = [];

  /// Half-life for recency decay in days.
  static const double _recencyHalfLifeDays = 30.0;

  /// Strength threshold below which a relationship is considered dormant.
  static const double _dormantThreshold = 30.0;

  // ── Getters ──

  List<Relationship> get relationships => List.unmodifiable(_relationships);
  List<Interaction> get interactions => List.unmodifiable(_interactions);
  List<SocialCapitalAnalysis> get history => List.unmodifiable(_history);

  // ── CRUD: Relationships ──

  void addRelationship(Relationship r) {
    _relationships.add(r);
  }

  void removeRelationship(String id) {
    _relationships.removeWhere((r) => r.id == id);
    _interactions.removeWhere((i) => i.relationshipId == id);
  }

  void updateRelationship(Relationship updated) {
    final idx = _relationships.indexWhere((r) => r.id == updated.id);
    if (idx >= 0) _relationships[idx] = updated;
  }

  // ── CRUD: Interactions ──

  void logInteraction(Interaction i) {
    _interactions.add(i);
  }

  void removeInteraction(String id) {
    _interactions.removeWhere((i) => i.id == id);
  }

  /// Interactions for a specific relationship, newest first.
  List<Interaction> interactionsFor(String relationshipId) {
    final list =
        _interactions.where((i) => i.relationshipId == relationshipId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ── Engine 1: Strength Calculator ──

  /// Computes strength score 0-100 for a relationship.
  RelationshipHealth computeHealth(String relationshipId, {DateTime? now}) {
    final rel = _relationships.firstWhere((r) => r.id == relationshipId);
    final ints = interactionsFor(relationshipId);
    final reference = now ?? DateTime.now();

    // Recency: exponential decay from last interaction
    double recencyScore = 0;
    if (ints.isNotEmpty) {
      final daysSinceLast =
          reference.difference(ints.first.date).inHours / 24.0;
      recencyScore =
          100.0 * exp(-0.693 * daysSinceLast / _recencyHalfLifeDays);
    }

    // Frequency: interactions per month vs expected
    double frequencyScore = 0;
    if (ints.isNotEmpty) {
      final spanDays = max(
          1,
          reference.difference(ints.last.date).inDays);
      final perMonth = ints.length / (spanDays / 30.0);
      final expected = rel.tier.expectedMonthlyFrequency;
      if (expected > 0) {
        frequencyScore = min(100.0, (perMonth / expected) * 100.0);
      } else {
        frequencyScore = min(100.0, perMonth * 50.0);
      }
    }

    // Quality: weighted average of interaction quality
    double qualityScore = 0;
    if (ints.isNotEmpty) {
      double totalWeight = 0;
      double totalQuality = 0;
      for (final interaction in ints) {
        final w = interaction.type.qualityWeight;
        totalWeight += w;
        totalQuality += interaction.quality * w;
      }
      qualityScore = (totalQuality / totalWeight) * 20.0; // scale 1-5 → 0-100
    }

    // Reciprocity: -1 (all them) to +1 (all self), 0 = balanced
    final reciprocity = _computeReciprocity(ints);

    // Reciprocity bonus/penalty: balanced = +10, extreme = -15
    final reciprocityBonus = 10.0 * (1.0 - reciprocity.abs()) - 5.0;

    // Composite strength
    final raw = recencyScore * 0.35 +
        frequencyScore * 0.30 +
        qualityScore * 0.25 +
        reciprocityBonus;
    final strength = max(0, min(100, raw)).toDouble();

    // Computed tier based on strength
    final computedTier = _tierFromStrength(strength);

    // Decay prediction
    final decayDate = _predictDecay(strength, reference);

    return RelationshipHealth(
      relationshipId: relationshipId,
      strengthScore: _round2(strength),
      recencyScore: _round2(recencyScore),
      frequencyScore: _round2(min(100, frequencyScore)),
      qualityScore: _round2(min(100, qualityScore)),
      reciprocityIndex: _round2(reciprocity),
      decayDate: decayDate,
      computedTier: computedTier,
    );
  }

  // ── Engine 2: Decay Predictor ──

  /// Predicts when strength will drop below dormant threshold.
  DateTime? _predictDecay(double currentStrength, DateTime now) {
    if (currentStrength <= _dormantThreshold) return null; // already dormant
    // Model: strength decays with same half-life as recency
    // Solve: threshold = current * exp(-0.693 * days / halfLife)
    // days = -halfLife * ln(threshold / current) / 0.693
    final days = -_recencyHalfLifeDays *
        log(_dormantThreshold / currentStrength) /
        0.693;
    return now.add(Duration(hours: (days * 24).round()));
  }

  // ── Engine 3: Cluster Detector ──

  /// Groups relationships by shared tags using Jaccard similarity.
  List<SocialCluster> detectClusters(
      Map<String, RelationshipHealth> healthMap) {
    // Build tag → member mapping
    final tagMembers = <String, Set<String>>{};
    for (final r in _relationships) {
      for (final tag in r.tags) {
        tagMembers.putIfAbsent(tag, () => {}).add(r.id);
      }
    }

    // Each tag with 2+ members becomes a cluster
    final clusters = <SocialCluster>[];
    var clusterIdx = 0;
    for (final entry in tagMembers.entries) {
      if (entry.value.length < 2) continue;
      final memberIds = entry.value.toList();
      final cohesion = _clusterCohesion(memberIds, healthMap);

      // Determine trend based on average strength vs 50
      ClusterTrend trend;
      if (cohesion > 60) {
        trend = ClusterTrend.growing;
      } else if (cohesion > 40) {
        trend = ClusterTrend.stable;
      } else {
        trend = ClusterTrend.weakening;
      }

      clusters.add(SocialCluster(
        id: 'cluster_$clusterIdx',
        name: entry.key,
        memberIds: memberIds,
        cohesionScore: _round2(cohesion),
        trend: trend,
      ));
      clusterIdx++;
    }

    return clusters;
  }

  double _clusterCohesion(
      List<String> memberIds, Map<String, RelationshipHealth> healthMap) {
    if (memberIds.isEmpty) return 0;
    double total = 0;
    int count = 0;
    for (final id in memberIds) {
      final h = healthMap[id];
      if (h != null) {
        total += h.strengthScore;
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }

  // ── Engine 4: Reciprocity Analyzer ──

  double _computeReciprocity(List<Interaction> ints) {
    if (ints.isEmpty) return 0;
    int selfCount = 0;
    int themCount = 0;
    for (final i in ints) {
      if (i.initiatedBy == InteractionInitiator.self) {
        selfCount++;
      } else if (i.initiatedBy == InteractionInitiator.them) {
        themCount++;
      } else {
        selfCount++;
        themCount++;
      }
    }
    final total = selfCount + themCount;
    if (total == 0) return 0;
    return _round2((selfCount - themCount) / total);
  }

  /// Network-wide reciprocity index.
  double networkReciprocity() {
    return _computeReciprocity(_interactions);
  }

  // ── Engine 5: Network Health Scorer ──

  /// Computes overall network health score 0-100.
  double computeNetworkScore(Map<String, RelationshipHealth> healthMap) {
    if (_relationships.isEmpty) return 0;

    // Active ratio (strength > dormant threshold)
    final active =
        healthMap.values.where((h) => h.strengthScore > _dormantThreshold).length;
    final activeRatio = active / _relationships.length;

    // Mean strength
    final meanStrength = healthMap.values.isEmpty
        ? 0.0
        : healthMap.values
                .map((h) => h.strengthScore)
                .reduce((a, b) => a + b) /
            healthMap.values.length;

    // Network diversity: Shannon entropy across tiers
    final diversity = _shannonEntropy(healthMap);

    // Reciprocity balance: how close to 0
    final recipBalance = 1.0 - networkReciprocity().abs();

    // Weighted composite
    final score = activeRatio * 40.0 +
        (meanStrength / 100.0) * 30.0 +
        diversity * 20.0 +
        recipBalance * 10.0;

    return _round2(max(0, min(100, score)));
  }

  /// Shannon entropy of tier distribution, normalized to 0-1.
  double _shannonEntropy(Map<String, RelationshipHealth> healthMap) {
    if (healthMap.isEmpty) return 0;
    final tierCounts = <RelationshipTier, int>{};
    for (final h in healthMap.values) {
      tierCounts[h.computedTier] = (tierCounts[h.computedTier] ?? 0) + 1;
    }
    final total = healthMap.length.toDouble();
    double entropy = 0;
    for (final count in tierCounts.values) {
      final p = count / total;
      if (p > 0) entropy -= p * log(p);
    }
    // Normalize by max entropy (log of number of tier types)
    final maxEntropy = log(RelationshipTier.values.length);
    return maxEntropy > 0 ? entropy / maxEntropy : 0;
  }

  // ── Engine 6: Insight Generator ──

  /// Generates autonomous insights about the network.
  List<SocialCapitalInsight> generateInsights(
    Map<String, RelationshipHealth> healthMap,
    List<SocialCluster> clusters, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final insights = <SocialCapitalInsight>[];

    for (final r in _relationships) {
      final h = healthMap[r.id];
      if (h == null) continue;
      final ints = interactionsFor(r.id);

      // Neglect warning: no interaction in 30+ days for close/inner
      if (ints.isNotEmpty &&
          (r.tier == RelationshipTier.innerCircle ||
              r.tier == RelationshipTier.close)) {
        final daysSince =
            reference.difference(ints.first.date).inDays;
        if (daysSince > 30) {
          insights.add(SocialCapitalInsight(
            type: InsightType.neglectWarning,
            severity: daysSince > 60
                ? InsightSeverity.critical
                : InsightSeverity.warning,
            message:
                "Haven't connected with ${r.name} in $daysSince days",
            relationshipId: r.id,
            actionSuggestion:
                'Send a quick message or schedule a call with ${r.name}',
            timestamp: reference,
          ));
        }
      }

      // Decay alert: predicted dormant within 14 days
      if (h.decayDate != null) {
        final daysUntilDecay =
            h.decayDate!.difference(reference).inDays;
        if (daysUntilDecay <= 14 && daysUntilDecay > 0) {
          insights.add(SocialCapitalInsight(
            type: InsightType.decayAlert,
            severity: daysUntilDecay <= 7
                ? InsightSeverity.critical
                : InsightSeverity.warning,
            message:
                '${r.name} will become dormant in ~$daysUntilDecay days',
            relationshipId: r.id,
            actionSuggestion: 'Reach out to ${r.name} to maintain the connection',
            timestamp: reference,
          ));
        }
      }

      // Reciprocity imbalance
      if (h.reciprocityIndex.abs() > 0.6 && ints.length >= 3) {
        final direction = h.reciprocityIndex > 0
            ? 'You initiate most interactions'
            : '${r.name} initiates most interactions';
        insights.add(SocialCapitalInsight(
          type: InsightType.reciprocityImbalance,
          severity: InsightSeverity.info,
          message: 'Reciprocity imbalance with ${r.name}: $direction',
          relationshipId: r.id,
          actionSuggestion: h.reciprocityIndex > 0
              ? 'Give ${r.name} space to initiate next time'
              : 'Take initiative to reach out to ${r.name}',
          timestamp: reference,
        ));
      }

      // Strength milestone: crossed 80
      if (h.strengthScore >= 80) {
        insights.add(SocialCapitalInsight(
          type: InsightType.strengthMilestone,
          severity: InsightSeverity.info,
          message:
              '${r.name} relationship strength is excellent at ${h.strengthScore.toStringAsFixed(0)}',
          relationshipId: r.id,
          actionSuggestion: 'Keep nurturing this strong connection!',
          timestamp: reference,
        ));
      }
    }

    // Cluster weakening
    for (final c in clusters) {
      if (c.trend == ClusterTrend.weakening) {
        insights.add(SocialCapitalInsight(
          type: InsightType.clusterWeakening,
          severity: InsightSeverity.warning,
          message:
              'Your "${c.name}" group (${c.memberIds.length} people) is weakening',
          actionSuggestion:
              'Organize a group activity with your ${c.name} circle',
          timestamp: reference,
        ));
      }
    }

    // Network gap: check if any tier has zero members
    final tierCounts = <RelationshipTier, int>{};
    for (final h in healthMap.values) {
      tierCounts[h.computedTier] = (tierCounts[h.computedTier] ?? 0) + 1;
    }
    for (final tier in [
      RelationshipTier.innerCircle,
      RelationshipTier.close,
      RelationshipTier.regular
    ]) {
      if ((tierCounts[tier] ?? 0) == 0 && _relationships.length >= 3) {
        insights.add(SocialCapitalInsight(
          type: InsightType.networkGap,
          severity: InsightSeverity.info,
          message: 'No ${tier.label} relationships detected',
          actionSuggestion:
              'Consider deepening some connections to fill this gap',
          timestamp: reference,
        ));
      }
    }

    // Sort: critical first, then warning, then info
    insights.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return insights;
  }

  // ── Engine 7: Trend Tracker ──

  /// Compares current score against last historical snapshot.
  String trendDirection() {
    if (_history.length < 2) return 'stable';
    final current = _history.last.overallScore;
    final previous = _history[_history.length - 2].overallScore;
    final delta = current - previous;
    if (delta > 3) return 'improving';
    if (delta < -3) return 'declining';
    return 'stable';
  }

  // ── Main Analysis ──

  /// Runs all 7 engines and returns a complete analysis.
  SocialCapitalAnalysis analyze({DateTime? now}) {
    final reference = now ?? DateTime.now();

    // Engine 1: Compute health for every relationship
    final healthMap = <String, RelationshipHealth>{};
    for (final r in _relationships) {
      healthMap[r.id] = computeHealth(r.id, now: reference);
    }

    // Engine 3: Detect clusters
    final clusters = detectClusters(healthMap);

    // Engine 5: Network score
    final overallScore = computeNetworkScore(healthMap);

    // Stats
    final active =
        healthMap.values.where((h) => h.strengthScore > _dormantThreshold).length;
    final neglected = healthMap.values
        .where((h) => h.strengthScore <= _dormantThreshold)
        .length;
    final strong =
        healthMap.values.where((h) => h.strengthScore >= 70).length;

    // Engine 6: Insights
    final insights = generateInsights(healthMap, clusters, now: reference);

    // Diversity
    final diversity = _shannonEntropy(healthMap);

    final analysis = SocialCapitalAnalysis(
      overallScore: overallScore,
      networkDiversity: _round2(diversity),
      activeRelationships: active,
      neglectedCount: neglected,
      strongTieCount: strong,
      healthMap: healthMap,
      clusters: clusters,
      insights: insights,
      analyzedAt: reference,
    );

    _history.add(analysis);
    return analysis;
  }

  // ── Queries ──

  /// Top neglected relationships by days since last interaction.
  List<MapEntry<Relationship, int>> getTopNeglected(int n, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final entries = <MapEntry<Relationship, int>>[];
    for (final r in _relationships) {
      final ints = interactionsFor(r.id);
      final daysSince = ints.isEmpty
          ? reference.difference(r.createdAt).inDays
          : reference.difference(ints.first.date).inDays;
      entries.add(MapEntry(r, daysSince));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(n).toList();
  }

  /// Strongest relationships by score.
  List<MapEntry<Relationship, double>> getStrongestRelationships(int n,
      {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final entries = <MapEntry<Relationship, double>>[];
    for (final r in _relationships) {
      final h = computeHealth(r.id, now: reference);
      entries.add(MapEntry(r, h.strengthScore));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(n).toList();
  }

  // ── Demo Data ──

  /// Loads realistic sample data for first-time users.
  void loadDemoData() {
    final now = DateTime.now();
    final d = (int days) => now.subtract(Duration(days: days));

    // 12 sample relationships across tiers
    final rels = [
      Relationship(
          id: 'r1', name: 'Alex Chen', tier: RelationshipTier.innerCircle,
          tags: ['college', 'tech'], importance: 9, createdAt: d(730)),
      Relationship(
          id: 'r2', name: 'Jordan Park', tier: RelationshipTier.innerCircle,
          tags: ['childhood', 'travel'], importance: 10, createdAt: d(3650)),
      Relationship(
          id: 'r3', name: 'Sam Rivera', tier: RelationshipTier.close,
          tags: ['work', 'tech'], importance: 7, createdAt: d(365)),
      Relationship(
          id: 'r4', name: 'Taylor Kim', tier: RelationshipTier.close,
          tags: ['college', 'music'], importance: 7, createdAt: d(1460)),
      Relationship(
          id: 'r5', name: 'Morgan Lee', tier: RelationshipTier.regular,
          tags: ['work', 'fitness'], importance: 5, createdAt: d(200)),
      Relationship(
          id: 'r6', name: 'Casey Walsh', tier: RelationshipTier.regular,
          tags: ['neighborhood', 'family'], importance: 5, createdAt: d(500)),
      Relationship(
          id: 'r7', name: 'Riley Nguyen', tier: RelationshipTier.regular,
          tags: ['hobby', 'music'], importance: 4, createdAt: d(300)),
      Relationship(
          id: 'r8', name: 'Drew Martinez', tier: RelationshipTier.acquaintance,
          tags: ['work'], importance: 3, createdAt: d(180)),
      Relationship(
          id: 'r9', name: 'Avery Thompson', tier: RelationshipTier.acquaintance,
          tags: ['fitness'], importance: 3, createdAt: d(120)),
      Relationship(
          id: 'r10', name: 'Jamie Brooks', tier: RelationshipTier.dormant,
          tags: ['college'], importance: 4, createdAt: d(2000)),
      Relationship(
          id: 'r11', name: 'Pat O\'Brien', tier: RelationshipTier.close,
          tags: ['family', 'travel'], importance: 8, createdAt: d(5000)),
      Relationship(
          id: 'r12', name: 'Quinn Davis', tier: RelationshipTier.regular,
          tags: ['tech', 'hobby'], importance: 5, createdAt: d(250)),
    ];
    for (final r in rels) {
      addRelationship(r);
    }

    // ~40 interactions spread across relationships
    final sampleInteractions = [
      // Alex - frequent recent
      Interaction(id: 'i1', relationshipId: 'r1', type: InteractionType.message,
          date: d(1), quality: 4, initiatedBy: InteractionInitiator.self),
      Interaction(id: 'i2', relationshipId: 'r1', type: InteractionType.videoCall,
          date: d(5), quality: 5, initiatedBy: InteractionInitiator.them),
      Interaction(id: 'i3', relationshipId: 'r1', type: InteractionType.inPerson,
          date: d(14), quality: 5, initiatedBy: InteractionInitiator.mutual),
      Interaction(id: 'i4', relationshipId: 'r1', type: InteractionType.message,
          date: d(20), quality: 3, initiatedBy: InteractionInitiator.self),
      // Jordan - moderately recent
      Interaction(id: 'i5', relationshipId: 'r2', type: InteractionType.call,
          date: d(3), quality: 5, initiatedBy: InteractionInitiator.them),
      Interaction(id: 'i6', relationshipId: 'r2', type: InteractionType.message,
          date: d(10), quality: 4, initiatedBy: InteractionInitiator.self),
      Interaction(id: 'i7', relationshipId: 'r2', type: InteractionType.inPerson,
          date: d(30), quality: 5, initiatedBy: InteractionInitiator.mutual),
      // Sam - work friend, mostly self-initiated
      Interaction(id: 'i8', relationshipId: 'r3', type: InteractionType.message,
          date: d(2), quality: 3, initiatedBy: InteractionInitiator.self),
      Interaction(id: 'i9', relationshipId: 'r3', type: InteractionType.email,
          date: d(7), quality: 3, initiatedBy: InteractionInitiator.self),
      Interaction(id: 'i10', relationshipId: 'r3', type: InteractionType.videoCall,
          date: d(15), quality: 4, initiatedBy: InteractionInitiator.self),
      Interaction(id: 'i11', relationshipId: 'r3', type: InteractionType.message,
          date: d(25), quality: 3, initiatedBy: InteractionInitiator.self),
      // Taylor - neglected close friend
      Interaction(id: 'i12', relationshipId: 'r4', type: InteractionType.socialMedia,
          date: d(45), quality: 2, initiatedBy: InteractionInitiator.self),
      Interaction(id: 'i13', relationshipId: 'r4', type: InteractionType.message,
          date: d(60), quality: 3, initiatedBy: InteractionInitiator.them),
      // Morgan - work/fitness
      Interaction(id: 'i14', relationshipId: 'r5', type: InteractionType.inPerson,
          date: d(4), quality: 4, initiatedBy: InteractionInitiator.mutual),
      Interaction(id: 'i15', relationshipId: 'r5', type: InteractionType.message,
          date: d(12), quality: 3, initiatedBy: InteractionInitiator.them),
      Interaction(id: 'i16', relationshipId: 'r5', type: InteractionType.event,
          date: d(28), quality: 4, initiatedBy: InteractionInitiator.mutual),
      // Casey - neighborhood
      Interaction(id: 'i17', relationshipId: 'r6', type: InteractionType.inPerson,
          date: d(8), quality: 4, initiatedBy: InteractionInitiator.mutual),
      Interaction(id: 'i18', relationshipId: 'r6', type: InteractionType.message,
          date: d(22), quality: 3, initiatedBy: InteractionInitiator.self),
      // Riley - music buddy
      Interaction(id: 'i19', relationshipId: 'r7', type: InteractionType.event,
          date: d(10), quality: 5, initiatedBy: InteractionInitiator.mutual),
      Interaction(id: 'i20', relationshipId: 'r7', type: InteractionType.message,
          date: d(35), quality: 3, initiatedBy: InteractionInitiator.them),
      // Drew - acquaintance
      Interaction(id: 'i21', relationshipId: 'r8', type: InteractionType.email,
          date: d(20), quality: 3, initiatedBy: InteractionInitiator.self),
      Interaction(id: 'i22', relationshipId: 'r8', type: InteractionType.message,
          date: d(50), quality: 2, initiatedBy: InteractionInitiator.them),
      // Avery - gym acquaintance
      Interaction(id: 'i23', relationshipId: 'r9', type: InteractionType.inPerson,
          date: d(6), quality: 3, initiatedBy: InteractionInitiator.mutual),
      // Jamie - dormant college friend
      Interaction(id: 'i24', relationshipId: 'r10', type: InteractionType.socialMedia,
          date: d(120), quality: 2, initiatedBy: InteractionInitiator.self),
      // Pat - family
      Interaction(id: 'i25', relationshipId: 'r11', type: InteractionType.call,
          date: d(2), quality: 5, initiatedBy: InteractionInitiator.them),
      Interaction(id: 'i26', relationshipId: 'r11', type: InteractionType.videoCall,
          date: d(9), quality: 5, initiatedBy: InteractionInitiator.self),
      Interaction(id: 'i27', relationshipId: 'r11', type: InteractionType.inPerson,
          date: d(21), quality: 5, initiatedBy: InteractionInitiator.mutual),
      Interaction(id: 'i28', relationshipId: 'r11', type: InteractionType.gift,
          date: d(35), quality: 5, initiatedBy: InteractionInitiator.self),
      // Quinn - tech/hobby
      Interaction(id: 'i29', relationshipId: 'r12', type: InteractionType.message,
          date: d(5), quality: 4, initiatedBy: InteractionInitiator.them),
      Interaction(id: 'i30', relationshipId: 'r12', type: InteractionType.event,
          date: d(18), quality: 4, initiatedBy: InteractionInitiator.mutual),
      // Extra interactions for depth
      Interaction(id: 'i31', relationshipId: 'r1', type: InteractionType.call,
          date: d(28), quality: 4, initiatedBy: InteractionInitiator.them),
      Interaction(id: 'i32', relationshipId: 'r2', type: InteractionType.gift,
          date: d(60), quality: 5, initiatedBy: InteractionInitiator.self),
      Interaction(id: 'i33', relationshipId: 'r5', type: InteractionType.message,
          date: d(40), quality: 3, initiatedBy: InteractionInitiator.self),
      Interaction(id: 'i34', relationshipId: 'r6', type: InteractionType.inPerson,
          date: d(45), quality: 4, initiatedBy: InteractionInitiator.them),
      Interaction(id: 'i35', relationshipId: 'r11', type: InteractionType.call,
          date: d(50), quality: 4, initiatedBy: InteractionInitiator.mutual),
      Interaction(id: 'i36', relationshipId: 'r3', type: InteractionType.inPerson,
          date: d(40), quality: 4, initiatedBy: InteractionInitiator.mutual),
      Interaction(id: 'i37', relationshipId: 'r7', type: InteractionType.message,
          date: d(55), quality: 3, initiatedBy: InteractionInitiator.self),
      Interaction(id: 'i38', relationshipId: 'r9', type: InteractionType.inPerson,
          date: d(30), quality: 3, initiatedBy: InteractionInitiator.mutual),
      Interaction(id: 'i39', relationshipId: 'r12', type: InteractionType.socialMedia,
          date: d(40), quality: 3, initiatedBy: InteractionInitiator.self),
      Interaction(id: 'i40', relationshipId: 'r4', type: InteractionType.call,
          date: d(90), quality: 4, initiatedBy: InteractionInitiator.them),
    ];
    for (final i in sampleInteractions) {
      logInteraction(i);
    }
  }

  // ── Serialization ──

  /// Serializes the entire service state to a JSON string.
  String toJsonString() {
    return jsonEncode({
      'relationships': _relationships.map((r) => r.toJson()).toList(),
      'interactions': _interactions.map((i) => i.toJson()).toList(),
    });
  }

  /// Restores service state from a JSON string.
  void loadFromJsonString(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    _relationships.clear();
    _interactions.clear();
    for (final rJson in (data['relationships'] as List<dynamic>)) {
      _relationships
          .add(Relationship.fromJson(rJson as Map<String, dynamic>));
    }
    for (final iJson in (data['interactions'] as List<dynamic>)) {
      _interactions
          .add(Interaction.fromJson(iJson as Map<String, dynamic>));
    }
  }

  // ── Helpers ──

  RelationshipTier _tierFromStrength(double strength) {
    if (strength >= 80) return RelationshipTier.innerCircle;
    if (strength >= 60) return RelationshipTier.close;
    if (strength >= 40) return RelationshipTier.regular;
    if (strength >= 30) return RelationshipTier.acquaintance;
    return RelationshipTier.dormant;
  }

  static double _round2(double v) =>
      (v * 100).roundToDouble() / 100;
}
