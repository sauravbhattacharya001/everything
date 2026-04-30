import 'dart:convert';
import 'dart:math';

/// Serendipity Engine — autonomous detection of unexpected connections between
/// disparate life areas. Surfaces "lucky" insights that feel coincidental but
/// are data-driven, mining patterns across all tracked signals to find
/// non-obvious cross-domain links.
///
/// Core concepts:
/// - **Life Domain**: categorized life areas (work, health, relationships, etc.)
/// - **Signal**: a tagged data point from any domain with keywords and timestamp
/// - **Connection**: a detected link between signals from different domains
/// - **Serendipity Score**: measures unexpectedness × actionability (0-100)
/// - **Insight**: human-readable narrative with actionable suggestion
/// - **Receptivity Window**: optimal delivery times based on engagement history
/// - **Cultivation Tip**: proactive suggestions to increase serendipity potential

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Life domain categories.
enum LifeDomain {
  work,
  health,
  relationships,
  learning,
  creativity,
  finance,
  fitness,
  spirituality,
  hobbies,
  environment;

  String get label {
    switch (this) {
      case LifeDomain.work:
        return 'Work';
      case LifeDomain.health:
        return 'Health';
      case LifeDomain.relationships:
        return 'Relationships';
      case LifeDomain.learning:
        return 'Learning';
      case LifeDomain.creativity:
        return 'Creativity';
      case LifeDomain.finance:
        return 'Finance';
      case LifeDomain.fitness:
        return 'Fitness';
      case LifeDomain.spirituality:
        return 'Spirituality';
      case LifeDomain.hobbies:
        return 'Hobbies';
      case LifeDomain.environment:
        return 'Environment';
    }
  }

  String get emoji {
    switch (this) {
      case LifeDomain.work:
        return '💼';
      case LifeDomain.health:
        return '🏥';
      case LifeDomain.relationships:
        return '👥';
      case LifeDomain.learning:
        return '📚';
      case LifeDomain.creativity:
        return '🎨';
      case LifeDomain.finance:
        return '💰';
      case LifeDomain.fitness:
        return '🏋️';
      case LifeDomain.spirituality:
        return '🧘';
      case LifeDomain.hobbies:
        return '🎮';
      case LifeDomain.environment:
        return '🌿';
    }
  }
}

/// Types of connections between signals.
enum ConnectionType {
  keywordOverlap,
  temporalCluster,
  patternEcho,
  domainBridge,
  recurringTheme;

  String get label {
    switch (this) {
      case ConnectionType.keywordOverlap:
        return 'Keyword Overlap';
      case ConnectionType.temporalCluster:
        return 'Temporal Cluster';
      case ConnectionType.patternEcho:
        return 'Pattern Echo';
      case ConnectionType.domainBridge:
        return 'Domain Bridge';
      case ConnectionType.recurringTheme:
        return 'Recurring Theme';
    }
  }

  String get description {
    switch (this) {
      case ConnectionType.keywordOverlap:
        return 'Shared keywords across different life areas';
      case ConnectionType.temporalCluster:
        return 'Events happening close together in time across domains';
      case ConnectionType.patternEcho:
        return 'Similar patterns repeating in different contexts';
      case ConnectionType.domainBridge:
        return 'A signal that naturally bridges two domains';
      case ConnectionType.recurringTheme:
        return 'A theme that keeps appearing across your life';
    }
  }
}

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

/// A tagged data point from any life domain.
class LifeSignal {
  final String id;
  final LifeDomain domain;
  final List<String> keywords;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  LifeSignal({
    required this.id,
    required this.domain,
    required this.keywords,
    required this.description,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'domain': domain.name,
        'keywords': keywords,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory LifeSignal.fromJson(Map<String, dynamic> json) => LifeSignal(
        id: json['id'] as String,
        domain: LifeDomain.values.firstWhere((d) => d.name == json['domain']),
        keywords: List<String>.from(json['keywords'] as List),
        description: json['description'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );
}

/// A detected connection between two signals.
class SignalConnection {
  final String id;
  final String signalAId;
  final String signalBId;
  final ConnectionType connectionType;
  final List<String> sharedKeywords;
  final double serendipityScore;
  final String insight;
  final DateTime createdAt;

  SignalConnection({
    required this.id,
    required this.signalAId,
    required this.signalBId,
    required this.connectionType,
    required this.sharedKeywords,
    required this.serendipityScore,
    required this.insight,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'signalAId': signalAId,
        'signalBId': signalBId,
        'connectionType': connectionType.name,
        'sharedKeywords': sharedKeywords,
        'serendipityScore': serendipityScore,
        'insight': insight,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// A human-readable insight derived from a connection.
class SerendipityInsight {
  final String id;
  final SignalConnection connection;
  final String narrative;
  final String actionSuggestion;
  final DateTime? deliveryWindow;
  final double engagementProbability;

  SerendipityInsight({
    required this.id,
    required this.connection,
    required this.narrative,
    required this.actionSuggestion,
    this.deliveryWindow,
    required this.engagementProbability,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'connectionId': connection.id,
        'narrative': narrative,
        'actionSuggestion': actionSuggestion,
        'deliveryWindow': deliveryWindow?.toIso8601String(),
        'engagementProbability': engagementProbability,
      };
}

/// A proactive suggestion to increase serendipity potential.
class CultivationTip {
  final String id;
  final String suggestion;
  final List<LifeDomain> targetDomains;
  final double expectedImpact;
  final String reasoning;

  CultivationTip({
    required this.id,
    required this.suggestion,
    required this.targetDomains,
    required this.expectedImpact,
    required this.reasoning,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'suggestion': suggestion,
        'targetDomains': targetDomains.map((d) => d.name).toList(),
        'expectedImpact': expectedImpact,
        'reasoning': reasoning,
      };
}

/// Engagement record for receptivity learning.
class ReceptivityWindow {
  final int hourOfDay;
  final int dayOfWeek;
  double engagementRate;
  int totalDeliveries;
  int totalEngagements;

  ReceptivityWindow({
    required this.hourOfDay,
    required this.dayOfWeek,
    this.engagementRate = 0.5,
    this.totalDeliveries = 0,
    this.totalEngagements = 0,
  });

  void recordDelivery(bool engaged) {
    totalDeliveries++;
    if (engaged) totalEngagements++;
    engagementRate = totalDeliveries > 0
        ? totalEngagements / totalDeliveries
        : 0.5;
  }

  Map<String, dynamic> toJson() => {
        'hourOfDay': hourOfDay,
        'dayOfWeek': dayOfWeek,
        'engagementRate': engagementRate,
        'totalDeliveries': totalDeliveries,
        'totalEngagements': totalEngagements,
      };
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Serendipity Engine Service — mines cross-domain connections and surfaces
/// unexpected insights from life signals.
class SerendipityEngineService {
  final List<LifeSignal> _signals = [];
  final List<SignalConnection> _connections = [];
  final List<SerendipityInsight> _insights = [];
  final Map<String, bool> _engagementLog = {};
  final List<ReceptivityWindow> _receptivityWindows = [];
  final Random _random = Random(42);

  /// Temporal proximity threshold for clustering (hours).
  final int temporalWindowHours;

  /// Minimum Jaccard similarity for keyword overlap connections.
  final double minKeywordSimilarity;

  SerendipityEngineService({
    this.temporalWindowHours = 48,
    this.minKeywordSimilarity = 0.15,
  }) {
    // Initialize receptivity windows for all hour/day combinations.
    for (int day = 1; day <= 7; day++) {
      for (int hour = 0; hour < 24; hour++) {
        _receptivityWindows.add(ReceptivityWindow(
          hourOfDay: hour,
          dayOfWeek: day,
        ));
      }
    }
  }

  // -------------------------------------------------------------------------
  // Signal Collector
  // -------------------------------------------------------------------------

  /// Register a new life signal.
  void addSignal(LifeSignal signal) {
    _signals.add(signal);
  }

  /// Get all registered signals.
  List<LifeSignal> get signals => List.unmodifiable(_signals);

  /// Get signals filtered by domain.
  List<LifeSignal> getSignalsByDomain(LifeDomain domain) =>
      _signals.where((s) => s.domain == domain).toList();

  // -------------------------------------------------------------------------
  // Connection Miner
  // -------------------------------------------------------------------------

  /// Mine connections between signals across different domains.
  /// Returns new connections found with score >= [minScore].
  List<SignalConnection> mineConnections({double minScore = 30.0}) {
    final newConnections = <SignalConnection>[];
    final existingPairs = _connections
        .map((c) => '${c.signalAId}|${c.signalBId}')
        .toSet();

    for (int i = 0; i < _signals.length; i++) {
      for (int j = i + 1; j < _signals.length; j++) {
        final a = _signals[i];
        final b = _signals[j];

        // Only connect across different domains.
        if (a.domain == b.domain) continue;

        final pairKey = '${a.id}|${b.id}';
        final reversePairKey = '${b.id}|${a.id}';
        if (existingPairs.contains(pairKey) ||
            existingPairs.contains(reversePairKey)) {
          continue;
        }

        final connection = _evaluateConnection(a, b);
        if (connection != null && connection.serendipityScore >= minScore) {
          newConnections.add(connection);
          _connections.add(connection);
          existingPairs.add(pairKey);
        }
      }
    }

    return newConnections;
  }

  /// Evaluate potential connection between two signals.
  SignalConnection? _evaluateConnection(LifeSignal a, LifeSignal b) {
    // Try each connection type and pick the strongest.
    double bestScore = 0;
    ConnectionType? bestType;
    List<String> sharedKw = [];

    // 1. Keyword overlap (Jaccard similarity).
    final setA = a.keywords.map((k) => k.toLowerCase()).toSet();
    final setB = b.keywords.map((k) => k.toLowerCase()).toSet();
    final intersection = setA.intersection(setB);
    final union = setA.union(setB);

    if (union.isNotEmpty) {
      final jaccard = intersection.length / union.length;
      if (jaccard >= minKeywordSimilarity) {
        final score = _computeSurpriseScore(a, b, jaccard, ConnectionType.keywordOverlap);
        if (score > bestScore) {
          bestScore = score;
          bestType = ConnectionType.keywordOverlap;
          sharedKw = intersection.toList();
        }
      }
    }

    // 2. Temporal cluster.
    final timeDiffHours =
        a.timestamp.difference(b.timestamp).inHours.abs();
    if (timeDiffHours <= temporalWindowHours) {
      final temporalProximity = 1.0 - (timeDiffHours / temporalWindowHours);
      final score = _computeSurpriseScore(
          a, b, temporalProximity, ConnectionType.temporalCluster);
      if (score > bestScore) {
        bestScore = score;
        bestType = ConnectionType.temporalCluster;
        sharedKw = intersection.toList();
      }
    }

    // 3. Pattern echo — similar description length patterns or metadata.
    final descLenRatio = min(a.description.length, b.description.length) /
        max(a.description.length, b.description.length).toDouble();
    if (descLenRatio > 0.7 && intersection.isNotEmpty) {
      final score = _computeSurpriseScore(
          a, b, descLenRatio * 0.5, ConnectionType.patternEcho);
      if (score > bestScore) {
        bestScore = score;
        bestType = ConnectionType.patternEcho;
        sharedKw = intersection.toList();
      }
    }

    // 4. Domain bridge — signal keywords that naturally span two domains.
    final bridgeKeywords = _findBridgeKeywords(a.domain, b.domain, intersection);
    if (bridgeKeywords.isNotEmpty) {
      final score = _computeSurpriseScore(
          a, b, bridgeKeywords.length * 0.3, ConnectionType.domainBridge);
      if (score > bestScore) {
        bestScore = score;
        bestType = ConnectionType.domainBridge;
        sharedKw = bridgeKeywords;
      }
    }

    // 5. Recurring theme — keyword appears in 3+ signals across domains.
    final recurringKw = _findRecurringThemes(a, b);
    if (recurringKw.isNotEmpty) {
      final score = _computeSurpriseScore(
          a, b, recurringKw.length * 0.25, ConnectionType.recurringTheme);
      if (score > bestScore) {
        bestScore = score;
        bestType = ConnectionType.recurringTheme;
        sharedKw = recurringKw;
      }
    }

    if (bestType == null || bestScore < 10) return null;

    final insight = _generateConnectionInsight(a, b, bestType, sharedKw);

    return SignalConnection(
      id: 'conn_${a.id}_${b.id}',
      signalAId: a.id,
      signalBId: b.id,
      connectionType: bestType,
      sharedKeywords: sharedKw,
      serendipityScore: bestScore.clamp(0, 100).toDouble(),
      insight: insight,
      createdAt: DateTime.now(),
    );
  }

  // -------------------------------------------------------------------------
  // Surprise Scorer
  // -------------------------------------------------------------------------

  /// Compute surprise score for a potential connection.
  /// Higher score = more unexpected + more actionable.
  double _computeSurpriseScore(
    LifeSignal a,
    LifeSignal b,
    double rawSimilarity,
    ConnectionType type,
  ) {
    // Factor 1: Domain pair rarity (how rarely these two domains connect).
    final domainPairFreq = _getDomainPairFrequency(a.domain, b.domain);
    final rarityBonus = (1.0 - domainPairFreq) * 40; // 0-40 points

    // Factor 2: Keyword rarity (how rare are the shared keywords).
    final keywordRarity = _getKeywordRarity(
      a.keywords.toSet().intersection(b.keywords.toSet()),
    );
    final keywordBonus = keywordRarity * 30; // 0-30 points

    // Factor 3: Temporal distance (further apart = more surprising).
    final daysDiff =
        a.timestamp.difference(b.timestamp).inDays.abs().toDouble();
    final temporalSurprise = min(daysDiff / 30.0, 1.0) * 20; // 0-20 points

    // Factor 4: Raw similarity strength.
    final similarityBonus = rawSimilarity * 10; // 0-10 points

    return rarityBonus + keywordBonus + temporalSurprise + similarityBonus;
  }

  /// Get frequency of connections between two domain types (0-1).
  double _getDomainPairFrequency(LifeDomain a, LifeDomain b) {
    if (_connections.isEmpty) return 0.0;

    int pairCount = 0;
    for (final conn in _connections) {
      final sigA = _signals.where((s) => s.id == conn.signalAId).firstOrNull;
      final sigB = _signals.where((s) => s.id == conn.signalBId).firstOrNull;
      if (sigA == null || sigB == null) continue;

      if ((sigA.domain == a && sigB.domain == b) ||
          (sigA.domain == b && sigB.domain == a)) {
        pairCount++;
      }
    }
    return pairCount / _connections.length;
  }

  /// Get rarity score for a set of keywords (0-1, 1 = very rare).
  double _getKeywordRarity(Set<String> keywords) {
    if (keywords.isEmpty) return 0.5;

    final totalSignals = _signals.length;
    if (totalSignals == 0) return 0.5;

    double totalRarity = 0;
    for (final kw in keywords) {
      final freq = _signals
              .where((s) => s.keywords
                  .any((k) => k.toLowerCase() == kw.toLowerCase()))
              .length /
          totalSignals;
      totalRarity += (1.0 - freq);
    }
    return (totalRarity / keywords.length).clamp(0.0, 1.0);
  }

  // -------------------------------------------------------------------------
  // Insight Generator
  // -------------------------------------------------------------------------

  /// Generate actionable insights from top connections.
  List<SerendipityInsight> generateInsights({int maxInsights = 5}) {
    // Sort connections by score descending.
    final sorted = List<SignalConnection>.from(_connections)
      ..sort((a, b) => b.serendipityScore.compareTo(a.serendipityScore));

    final results = <SerendipityInsight>[];
    final usedConnections = _insights.map((i) => i.connection.id).toSet();

    for (final conn in sorted) {
      if (results.length >= maxInsights) break;
      if (usedConnections.contains(conn.id)) continue;

      final sigA = _signals.where((s) => s.id == conn.signalAId).firstOrNull;
      final sigB = _signals.where((s) => s.id == conn.signalBId).firstOrNull;
      if (sigA == null || sigB == null) continue;

      final narrative = _buildNarrative(sigA, sigB, conn);
      final suggestion = _buildActionSuggestion(sigA, sigB, conn);
      final deliveryTime = _findBestDeliveryWindow();
      final engProb = predictReceptivity(deliveryTime);

      final insight = SerendipityInsight(
        id: 'insight_${conn.id}',
        connection: conn,
        narrative: narrative,
        actionSuggestion: suggestion,
        deliveryWindow: deliveryTime,
        engagementProbability: engProb,
      );

      results.add(insight);
      _insights.add(insight);
    }

    return results;
  }

  /// Build a human-readable narrative for a connection.
  String _buildNarrative(
      LifeSignal a, LifeSignal b, SignalConnection conn) {
    final domainA = a.domain.label;
    final domainB = b.domain.label;

    switch (conn.connectionType) {
      case ConnectionType.keywordOverlap:
        return 'Your ${domainA.toLowerCase()} signal "${a.description}" shares '
            'themes (${conn.sharedKeywords.join(", ")}) with your '
            '${domainB.toLowerCase()} signal "${b.description}". '
            'This cross-pollination might unlock new perspectives.';
      case ConnectionType.temporalCluster:
        return 'Around the same time, you had activity in both '
            '${domainA.toLowerCase()} ("${a.description}") and '
            '${domainB.toLowerCase()} ("${b.description}"). '
            'Coincidence, or a deeper pattern?';
      case ConnectionType.patternEcho:
        return 'A pattern in your ${domainA.toLowerCase()} '
            '("${a.description}") echoes something in your '
            '${domainB.toLowerCase()} ("${b.description}"). '
            'Sometimes parallel patterns reveal underlying truths.';
      case ConnectionType.domainBridge:
        return 'The concept of "${conn.sharedKeywords.join(", ")}" naturally '
            'bridges your ${domainA.toLowerCase()} and '
            '${domainB.toLowerCase()} activities. '
            'This could be a fertile intersection to explore.';
      case ConnectionType.recurringTheme:
        return 'The theme "${conn.sharedKeywords.join(", ")}" keeps appearing '
            'across your ${domainA.toLowerCase()} and ${domainB.toLowerCase()}. '
            'Recurring themes often point to what matters most.';
    }
  }

  /// Build an actionable suggestion from a connection.
  String _buildActionSuggestion(
      LifeSignal a, LifeSignal b, SignalConnection conn) {
    final suggestions = <String>[
      'Try applying what you learned in ${a.domain.label.toLowerCase()} to your ${b.domain.label.toLowerCase()} activities.',
      'Dedicate 15 minutes to exploring how "${conn.sharedKeywords.isNotEmpty ? conn.sharedKeywords.first : 'this theme'}" connects these two areas.',
      'Write a brief reflection on what ${a.domain.label.toLowerCase()} and ${b.domain.label.toLowerCase()} have in common right now.',
      'Share this insight with someone who operates in both spaces.',
      'Create a mini-project that combines ${a.domain.label.toLowerCase()} with ${b.domain.label.toLowerCase()}.',
    ];
    return suggestions[_random.nextInt(suggestions.length)];
  }

  /// Generate a connection insight string.
  String _generateConnectionInsight(
      LifeSignal a, LifeSignal b, ConnectionType type, List<String> keywords) {
    final kw = keywords.isNotEmpty ? keywords.first : 'shared patterns';
    return '${a.domain.emoji} ${a.domain.label} ↔ ${b.domain.emoji} ${b.domain.label}: '
        '"$kw" connects "${a.description}" with "${b.description}"';
  }

  // -------------------------------------------------------------------------
  // Receptivity Predictor
  // -------------------------------------------------------------------------

  /// Predict engagement probability for a given time.
  double predictReceptivity(DateTime time) {
    final window = _receptivityWindows.where(
      (w) => w.hourOfDay == time.hour && w.dayOfWeek == time.weekday,
    ).firstOrNull;

    return window?.engagementRate ?? 0.5;
  }

  /// Record whether user engaged with an insight.
  void recordEngagement(String insightId, bool engaged) {
    _engagementLog[insightId] = engaged;

    // Update receptivity windows based on current time.
    final now = DateTime.now();
    final window = _receptivityWindows.where(
      (w) => w.hourOfDay == now.hour && w.dayOfWeek == now.weekday,
    ).firstOrNull;

    window?.recordDelivery(engaged);
  }

  /// Record engagement at a specific time (for testing/history).
  void recordEngagementAt(String insightId, bool engaged, DateTime time) {
    _engagementLog[insightId] = engaged;

    final window = _receptivityWindows.where(
      (w) => w.hourOfDay == time.hour && w.dayOfWeek == time.weekday,
    ).firstOrNull;

    window?.recordDelivery(engaged);
  }

  /// Find the best delivery window based on historical engagement.
  DateTime _findBestDeliveryWindow() {
    final sortedWindows = List<ReceptivityWindow>.from(_receptivityWindows)
      ..sort((a, b) => b.engagementRate.compareTo(a.engagementRate));

    final best = sortedWindows.first;
    final now = DateTime.now();

    // Find next occurrence of this window.
    var target = DateTime(now.year, now.month, now.day, best.hourOfDay);
    while (target.weekday != best.dayOfWeek || target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }

  // -------------------------------------------------------------------------
  // Serendipity Cultivator
  // -------------------------------------------------------------------------

  /// Get proactive suggestions to increase serendipity potential.
  List<CultivationTip> getCultivationTips({int count = 3}) {
    final tips = <CultivationTip>[];
    final domainCounts = <LifeDomain, int>{};

    for (final signal in _signals) {
      domainCounts[signal.domain] = (domainCounts[signal.domain] ?? 0) + 1;
    }

    // Identify neglected domains.
    final neglectedDomains = LifeDomain.values
        .where((d) => (domainCounts[d] ?? 0) < 2)
        .toList();

    // Identify domains with low cross-connections.
    final connectedDomains = <LifeDomain>{};
    for (final conn in _connections) {
      final sigA = _signals.where((s) => s.id == conn.signalAId).firstOrNull;
      final sigB = _signals.where((s) => s.id == conn.signalBId).firstOrNull;
      if (sigA != null) connectedDomains.add(sigA.domain);
      if (sigB != null) connectedDomains.add(sigB.domain);
    }
    final isolatedDomains = LifeDomain.values
        .where((d) =>
            (domainCounts[d] ?? 0) > 0 && !connectedDomains.contains(d))
        .toList();

    // Generate tips.
    int tipId = 0;

    // Tip type 1: Explore neglected domains.
    for (final domain in neglectedDomains) {
      if (tips.length >= count) break;
      tips.add(CultivationTip(
        id: 'tip_${tipId++}',
        suggestion:
            'Add more ${domain.label.toLowerCase()} signals. Try logging '
            'a ${domain.label.toLowerCase()} activity today — even a small one '
            'can create unexpected connections.',
        targetDomains: [domain],
        expectedImpact: 0.7,
        reasoning: 'Domain "${domain.label}" has fewer than 2 signals. '
            'More diverse inputs increase serendipity potential.',
      ));
    }

    // Tip type 2: Bridge isolated domains.
    for (final domain in isolatedDomains) {
      if (tips.length >= count) break;
      final activeDomains = domainCounts.entries
          .where((e) => e.value >= 3)
          .map((e) => e.key)
          .toList();
      if (activeDomains.isNotEmpty) {
        final bridgeTo = activeDomains[_random.nextInt(activeDomains.length)];
        tips.add(CultivationTip(
          id: 'tip_${tipId++}',
          suggestion:
              'Try connecting your ${domain.label.toLowerCase()} activities '
              'with ${bridgeTo.label.toLowerCase()}. Look for shared vocabulary '
              'or parallel challenges between them.',
          targetDomains: [domain, bridgeTo],
          expectedImpact: 0.8,
          reasoning:
              '"${domain.label}" has activity but no cross-domain connections yet. '
              'Bridging it with "${bridgeTo.label}" could unlock novel insights.',
        ));
      }
    }

    // Tip type 3: General serendipity cultivation.
    final generalTips = [
      CultivationTip(
        id: 'tip_${tipId++}',
        suggestion: 'Read something outside your usual topics today. '
            'Random inputs are the fuel of serendipity.',
        targetDomains: [LifeDomain.learning],
        expectedImpact: 0.6,
        reasoning: 'Diverse information intake increases the probability '
            'of unexpected cross-domain connections.',
      ),
      CultivationTip(
        id: 'tip_${tipId++}',
        suggestion: 'Have a conversation with someone from a different field. '
            'Cross-pollination happens at the boundaries.',
        targetDomains: [LifeDomain.relationships, LifeDomain.learning],
        expectedImpact: 0.75,
        reasoning: 'Social serendipity — unexpected connections often '
            'come through other people\'s perspectives.',
      ),
      CultivationTip(
        id: 'tip_${tipId++}',
        suggestion: 'Revisit a hobby you haven\'t touched in a while. '
            'Dormant interests often connect to current pursuits in surprising ways.',
        targetDomains: [LifeDomain.hobbies],
        expectedImpact: 0.65,
        reasoning: 'Reactivating dormant knowledge creates new bridging '
            'opportunities with recent activities.',
      ),
    ];

    while (tips.length < count && generalTips.isNotEmpty) {
      tips.add(generalTips.removeAt(0));
    }

    return tips.take(count).toList();
  }

  // -------------------------------------------------------------------------
  // Analytics
  // -------------------------------------------------------------------------

  /// Get overall serendipity health score (0-100).
  /// Higher = more cross-domain activity and connections.
  double getSerendipityScore() {
    if (_signals.isEmpty) return 0;

    // Component 1: Domain diversity (0-30).
    final diversity = getDomainDiversity();
    final maxEntropy = log(LifeDomain.values.length) / ln2;
    final diversityScore = (diversity / maxEntropy) * 30;

    // Component 2: Connection density (0-30).
    final maxPossibleConnections =
        _signals.length * (_signals.length - 1) / 2;
    final connectionDensity = maxPossibleConnections > 0
        ? _connections.length / maxPossibleConnections
        : 0.0;
    final connectionScore = min(connectionDensity * 10, 1.0) * 30;

    // Component 3: Recency of activity (0-20).
    final now = DateTime.now();
    final recentSignals = _signals
        .where((s) => now.difference(s.timestamp).inDays <= 7)
        .length;
    final recencyScore = min(recentSignals / 5.0, 1.0) * 20;

    // Component 4: Insight engagement rate (0-20).
    final engagements = _engagementLog.values.where((v) => v).length;
    final engagementRate = _engagementLog.isNotEmpty
        ? engagements / _engagementLog.length
        : 0.5;
    final engagementScore = engagementRate * 20;

    return (diversityScore + connectionScore + recencyScore + engagementScore)
        .clamp(0, 100)
        .toDouble();
  }

  /// Shannon entropy of domain distribution.
  double getDomainDiversity() {
    if (_signals.isEmpty) return 0;

    final counts = <LifeDomain, int>{};
    for (final signal in _signals) {
      counts[signal.domain] = (counts[signal.domain] ?? 0) + 1;
    }

    double entropy = 0;
    for (final count in counts.values) {
      final p = count / _signals.length;
      if (p > 0) {
        entropy -= p * (log(p) / ln2);
      }
    }
    return entropy;
  }

  /// Get connection graph: map of domain pairs to connection counts.
  Map<String, int> getConnectionGraph() {
    final graph = <String, int>{};

    for (final conn in _connections) {
      final sigA = _signals.where((s) => s.id == conn.signalAId).firstOrNull;
      final sigB = _signals.where((s) => s.id == conn.signalBId).firstOrNull;
      if (sigA == null || sigB == null) continue;

      final domains = [sigA.domain.name, sigB.domain.name]..sort();
      final key = '${domains[0]}-${domains[1]}';
      graph[key] = (graph[key] ?? 0) + 1;
    }

    return graph;
  }

  /// Get all connections.
  List<SignalConnection> get connections => List.unmodifiable(_connections);

  /// Get all insights.
  List<SerendipityInsight> get insights => List.unmodifiable(_insights);

  // -------------------------------------------------------------------------
  // Dashboard
  // -------------------------------------------------------------------------

  /// Comprehensive dashboard summary.
  Map<String, dynamic> getDashboard() {
    final domainCounts = <String, int>{};
    for (final signal in _signals) {
      domainCounts[signal.domain.label] =
          (domainCounts[signal.domain.label] ?? 0) + 1;
    }

    return {
      'serendipityScore': getSerendipityScore(),
      'totalSignals': _signals.length,
      'totalConnections': _connections.length,
      'totalInsights': _insights.length,
      'domainDiversity': getDomainDiversity(),
      'domainDistribution': domainCounts,
      'connectionGraph': getConnectionGraph(),
      'topConnections': _connections
          .toList()
          .cast<SignalConnection>()
        ..sort((a, b) => b.serendipityScore.compareTo(a.serendipityScore)),
      'engagementRate': _engagementLog.isNotEmpty
          ? _engagementLog.values.where((v) => v).length /
              _engagementLog.length
          : 0.0,
      'recentInsights': _insights.length > 5
          ? _insights.sublist(_insights.length - 5)
          : _insights,
    };
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Find keywords that naturally bridge two domains.
  List<String> _findBridgeKeywords(
      LifeDomain domainA, LifeDomain domainB, Set<String> candidates) {
    // Bridge keywords are those that appear in signals of both domains.
    final bridges = <String>[];
    for (final kw in candidates) {
      final inA = _signals.any((s) =>
          s.domain == domainA &&
          s.keywords.any((k) => k.toLowerCase() == kw.toLowerCase()));
      final inB = _signals.any((s) =>
          s.domain == domainB &&
          s.keywords.any((k) => k.toLowerCase() == kw.toLowerCase()));
      if (inA && inB) bridges.add(kw);
    }
    return bridges;
  }

  /// Find keywords that recur across 3+ signals in different domains.
  List<String> _findRecurringThemes(LifeSignal a, LifeSignal b) {
    final sharedKw = a.keywords
        .map((k) => k.toLowerCase())
        .toSet()
        .intersection(b.keywords.map((k) => k.toLowerCase()).toSet());

    final recurring = <String>[];
    for (final kw in sharedKw) {
      final domains = _signals
          .where(
              (s) => s.keywords.any((k) => k.toLowerCase() == kw))
          .map((s) => s.domain)
          .toSet();
      if (domains.length >= 3) recurring.add(kw);
    }
    return recurring;
  }

  /// Export state to JSON.
  String exportToJson() {
    return jsonEncode({
      'signals': _signals.map((s) => s.toJson()).toList(),
      'connections': _connections.map((c) => c.toJson()).toList(),
      'insights': _insights.map((i) => i.toJson()).toList(),
      'engagementLog': _engagementLog,
      'receptivityWindows':
          _receptivityWindows.map((w) => w.toJson()).toList(),
    });
  }
}
