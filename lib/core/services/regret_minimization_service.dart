import 'dart:math';

import 'service_persistence.dart';

/// Regret Minimization Engine — autonomous decision outcome tracker that
/// analyzes past decisions for regret patterns, identifies cognitive biases,
/// generates forward-looking wisdom, and helps users make decisions they'll
/// be proud of in 10 years.
///
/// Core concepts:
/// - **Decision Recording**: log decisions with context, stakes, emotions
/// - **Outcome Tracking**: revisit decisions after time passes to record outcomes
/// - **Regret Analysis**: detect regret patterns (action vs inaction, domain-specific)
/// - **Bias Detection**: identify recurring cognitive biases from decision history
/// - **Wisdom Generation**: distill personalized decision-making principles
/// - **Future Self Test**: "Will 80-year-old me regret NOT doing this?"

// ---------------------------------------------------------------------------
// Enums & Constants
// ---------------------------------------------------------------------------

/// Decision domain categories.
enum DecisionDomain {
  career,
  relationships,
  health,
  finance,
  education,
  lifestyle,
  creative,
  spiritual;

  String get label {
    switch (this) {
      case DecisionDomain.career:
        return 'Career';
      case DecisionDomain.relationships:
        return 'Relationships';
      case DecisionDomain.health:
        return 'Health';
      case DecisionDomain.finance:
        return 'Finance';
      case DecisionDomain.education:
        return 'Education';
      case DecisionDomain.lifestyle:
        return 'Lifestyle';
      case DecisionDomain.creative:
        return 'Creative';
      case DecisionDomain.spiritual:
        return 'Spiritual';
    }
  }

  String get emoji {
    switch (this) {
      case DecisionDomain.career:
        return '💼';
      case DecisionDomain.relationships:
        return '❤️';
      case DecisionDomain.health:
        return '🏥';
      case DecisionDomain.finance:
        return '💰';
      case DecisionDomain.education:
        return '📚';
      case DecisionDomain.lifestyle:
        return '🏠';
      case DecisionDomain.creative:
        return '🎨';
      case DecisionDomain.spiritual:
        return '🧘';
    }
  }
}

/// Type of regret.
enum RegretType {
  actionRegret,
  inactionRegret,
  timingRegret,
  methodRegret,
  scopeRegret;

  String get label {
    switch (this) {
      case RegretType.actionRegret:
        return 'Action Regret';
      case RegretType.inactionRegret:
        return 'Inaction Regret';
      case RegretType.timingRegret:
        return 'Timing Regret';
      case RegretType.methodRegret:
        return 'Method Regret';
      case RegretType.scopeRegret:
        return 'Scope Regret';
    }
  }

  String get description {
    switch (this) {
      case RegretType.actionRegret:
        return 'Regret for something you did';
      case RegretType.inactionRegret:
        return 'Regret for something you didn\'t do';
      case RegretType.timingRegret:
        return 'Right decision, wrong timing';
      case RegretType.methodRegret:
        return 'Right goal, wrong approach';
      case RegretType.scopeRegret:
        return 'Too big or too small for the situation';
    }
  }
}

/// Cognitive bias detected in decision patterns.
enum CognitiveBias {
  statusQuoBias,
  lossAversion,
  confirmationBias,
  sunkCostFallacy,
  availabilityHeuristic,
  anchoringBias,
  overconfidence,
  bandwagonEffect,
  presentBias,
  planningFallacy;

  String get label {
    switch (this) {
      case CognitiveBias.statusQuoBias:
        return 'Status Quo Bias';
      case CognitiveBias.lossAversion:
        return 'Loss Aversion';
      case CognitiveBias.confirmationBias:
        return 'Confirmation Bias';
      case CognitiveBias.sunkCostFallacy:
        return 'Sunk Cost Fallacy';
      case CognitiveBias.availabilityHeuristic:
        return 'Availability Heuristic';
      case CognitiveBias.anchoringBias:
        return 'Anchoring Bias';
      case CognitiveBias.overconfidence:
        return 'Overconfidence';
      case CognitiveBias.bandwagonEffect:
        return 'Bandwagon Effect';
      case CognitiveBias.presentBias:
        return 'Present Bias';
      case CognitiveBias.planningFallacy:
        return 'Planning Fallacy';
    }
  }

  String get description {
    switch (this) {
      case CognitiveBias.statusQuoBias:
        return 'Preferring things to stay the same over change';
      case CognitiveBias.lossAversion:
        return 'Fear of loss outweighing potential gains';
      case CognitiveBias.confirmationBias:
        return 'Seeking info that confirms existing beliefs';
      case CognitiveBias.sunkCostFallacy:
        return 'Continuing due to past investment, not future value';
      case CognitiveBias.availabilityHeuristic:
        return 'Overweighting vivid/recent examples';
      case CognitiveBias.anchoringBias:
        return 'Over-relying on first piece of information';
      case CognitiveBias.overconfidence:
        return 'Overestimating own knowledge or ability';
      case CognitiveBias.bandwagonEffect:
        return 'Following others rather than independent analysis';
      case CognitiveBias.presentBias:
        return 'Overvaluing immediate rewards over future benefits';
      case CognitiveBias.planningFallacy:
        return 'Underestimating time, costs, or risks';
    }
  }

  String get antidote {
    switch (this) {
      case CognitiveBias.statusQuoBias:
        return 'Ask: "If I weren\'t already doing this, would I start?"';
      case CognitiveBias.lossAversion:
        return 'Reframe: "What am I losing by NOT acting?"';
      case CognitiveBias.confirmationBias:
        return 'Actively seek evidence against your preferred choice';
      case CognitiveBias.sunkCostFallacy:
        return 'Ask: "Ignoring the past, what\'s the best move forward?"';
      case CognitiveBias.availabilityHeuristic:
        return 'Look at base rates and statistics, not anecdotes';
      case CognitiveBias.anchoringBias:
        return 'Generate your own estimate before seeing others\'';
      case CognitiveBias.overconfidence:
        return 'Assign confidence %, then widen the range by 50%';
      case CognitiveBias.bandwagonEffect:
        return 'Ask: "Would I choose this if nobody else was doing it?"';
      case CognitiveBias.presentBias:
        return 'Imagine your future self judging this choice';
      case CognitiveBias.planningFallacy:
        return 'Use reference class forecasting from similar past projects';
    }
  }
}

/// Outcome satisfaction level.
enum OutcomeSatisfaction {
  thrilled,
  satisfied,
  neutral,
  disappointed,
  regretful;

  String get label {
    switch (this) {
      case OutcomeSatisfaction.thrilled:
        return 'Thrilled';
      case OutcomeSatisfaction.satisfied:
        return 'Satisfied';
      case OutcomeSatisfaction.neutral:
        return 'Neutral';
      case OutcomeSatisfaction.disappointed:
        return 'Disappointed';
      case OutcomeSatisfaction.regretful:
        return 'Regretful';
    }
  }

  String get emoji {
    switch (this) {
      case OutcomeSatisfaction.thrilled:
        return '🤩';
      case OutcomeSatisfaction.satisfied:
        return '😊';
      case OutcomeSatisfaction.neutral:
        return '😐';
      case OutcomeSatisfaction.disappointed:
        return '😔';
      case OutcomeSatisfaction.regretful:
        return '😫';
    }
  }

  /// Numeric value for scoring: 1.0 (thrilled) to -1.0 (regretful).
  double get score {
    switch (this) {
      case OutcomeSatisfaction.thrilled:
        return 1.0;
      case OutcomeSatisfaction.satisfied:
        return 0.5;
      case OutcomeSatisfaction.neutral:
        return 0.0;
      case OutcomeSatisfaction.disappointed:
        return -0.5;
      case OutcomeSatisfaction.regretful:
        return -1.0;
    }
  }
}

/// Stakes level of a decision.
enum StakesLevel {
  trivial,
  low,
  moderate,
  high,
  lifeChanging;

  String get label {
    switch (this) {
      case StakesLevel.trivial:
        return 'Trivial';
      case StakesLevel.low:
        return 'Low';
      case StakesLevel.moderate:
        return 'Moderate';
      case StakesLevel.high:
        return 'High';
      case StakesLevel.lifeChanging:
        return 'Life-Changing';
    }
  }

  /// Weight multiplier for regret calculations.
  double get weight {
    switch (this) {
      case StakesLevel.trivial:
        return 0.2;
      case StakesLevel.low:
        return 0.5;
      case StakesLevel.moderate:
        return 1.0;
      case StakesLevel.high:
        return 2.0;
      case StakesLevel.lifeChanging:
        return 4.0;
    }
  }
}

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

/// A recorded decision with context.
class Decision {
  final String id;
  final DateTime timestamp;
  final String title;
  final String description;
  final DecisionDomain domain;
  final StakesLevel stakes;
  final List<String> alternatives;
  final String chosenOption;
  final String reasoning;
  final double confidenceLevel; // 0.0 - 1.0
  final List<String> emotionsAtTime;
  final bool wasReversible;
  final String? externalPressure;
  DecisionOutcome? outcome;

  Decision({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.description,
    required this.domain,
    required this.stakes,
    required this.alternatives,
    required this.chosenOption,
    required this.reasoning,
    required this.confidenceLevel,
    required this.emotionsAtTime,
    required this.wasReversible,
    this.externalPressure,
    this.outcome,
  });
}

/// Outcome recorded after time has passed.
class DecisionOutcome {
  final DateTime recordedAt;
  final OutcomeSatisfaction satisfaction;
  final String whatHappened;
  final String whatSurprised;
  final RegretType? regretType;
  final double regretIntensity; // 0.0 - 1.0 (0 = no regret)
  final String? lessonLearned;
  final bool wouldChooseSameAgain;

  DecisionOutcome({
    required this.recordedAt,
    required this.satisfaction,
    required this.whatHappened,
    required this.whatSurprised,
    this.regretType,
    required this.regretIntensity,
    this.lessonLearned,
    required this.wouldChooseSameAgain,
  });
}

/// Detected bias instance in a specific decision.
class BiasDetection {
  final String decisionId;
  final CognitiveBias bias;
  final double confidence; // 0.0 - 1.0
  final String evidence;

  BiasDetection({
    required this.decisionId,
    required this.bias,
    required this.confidence,
    required this.evidence,
  });
}

/// A wisdom principle distilled from decision patterns.
class WisdomPrinciple {
  final String id;
  final String principle;
  final String evidence;
  final List<DecisionDomain> applicableDomains;
  final double strength; // 0.0 - 1.0 (how well supported)
  final int supportingDecisions;
  final DateTime discoveredAt;

  WisdomPrinciple({
    required this.id,
    required this.principle,
    required this.evidence,
    required this.applicableDomains,
    required this.strength,
    required this.supportingDecisions,
    required this.discoveredAt,
  });
}

/// Regret pattern across multiple decisions.
class RegretPattern {
  final RegretType type;
  final DecisionDomain domain;
  final int occurrences;
  final double averageIntensity;
  final String insight;
  final String prevention;

  RegretPattern({
    required this.type,
    required this.domain,
    required this.occurrences,
    required this.averageIntensity,
    required this.insight,
    required this.prevention,
  });
}

/// Future Self projection for decision evaluation.
class FutureSelfTest {
  final String decisionTitle;
  final double regretIfAct; // predicted regret 0-1 if you DO it
  final double regretIfSkip; // predicted regret 0-1 if you DON'T
  final String tenYearPerspective;
  final String deathbedPerspective;
  final String recommendation;

  FutureSelfTest({
    required this.decisionTitle,
    required this.regretIfAct,
    required this.regretIfSkip,
    required this.tenYearPerspective,
    required this.deathbedPerspective,
    required this.recommendation,
  });
}

/// Overall regret health dashboard data.
class RegretDashboard {
  final int totalDecisions;
  final int outcomeRecorded;
  final int pendingReview;
  final double overallSatisfaction; // -1.0 to 1.0
  final double regretScore; // 0-100 (0 = no regret, 100 = maximum)
  final double wisdomScore; // 0-100 (learning from past)
  final Map<DecisionDomain, double> domainSatisfaction;
  final List<RegretPattern> topPatterns;
  final List<BiasDetection> recentBiases;
  final List<WisdomPrinciple> wisdomPrinciples;
  final List<Decision> upcomingReviews;
  final String healthVerdict;

  RegretDashboard({
    required this.totalDecisions,
    required this.outcomeRecorded,
    required this.pendingReview,
    required this.overallSatisfaction,
    required this.regretScore,
    required this.wisdomScore,
    required this.domainSatisfaction,
    required this.topPatterns,
    required this.recentBiases,
    required this.wisdomPrinciples,
    required this.upcomingReviews,
    required this.healthVerdict,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Regret Minimization Engine service.
class RegretMinimizationService with ServicePersistence {
  final List<Decision> _decisions = [];
  final List<BiasDetection> _biasDetections = [];
  final List<WisdomPrinciple> _wisdomPrinciples = [];

  @override
  String get storageKey => 'regret_minimization';

  List<Decision> get decisions => List.unmodifiable(_decisions);
  List<WisdomPrinciple> get wisdomPrinciples =>
      List.unmodifiable(_wisdomPrinciples);

  // -------------------------------------------------------------------------
  // Decision CRUD
  // -------------------------------------------------------------------------

  /// Record a new decision.
  void recordDecision(Decision decision) {
    _decisions.add(decision);
  }

  /// Record outcome for a decision.
  void recordOutcome(String decisionId, DecisionOutcome outcome) {
    final idx = _decisions.indexWhere((d) => d.id == decisionId);
    if (idx >= 0) {
      _decisions[idx].outcome = outcome;
      _runBiasDetection(_decisions[idx]);
      _updateWisdom();
    }
  }

  /// Get decisions pending outcome review (older than 30 days without outcome).
  List<Decision> getPendingReviews() {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _decisions
        .where((d) => d.outcome == null && d.timestamp.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // -------------------------------------------------------------------------
  // Regret Analysis
  // -------------------------------------------------------------------------

  /// Compute the overall regret score (0-100, lower is better).
  double computeRegretScore() {
    final withOutcomes =
        _decisions.where((d) => d.outcome != null).toList();
    if (withOutcomes.isEmpty) return 0.0;

    double weightedRegret = 0;
    double totalWeight = 0;

    for (final d in withOutcomes) {
      final weight = d.stakes.weight;
      weightedRegret += d.outcome!.regretIntensity * weight;
      totalWeight += weight;
    }

    return totalWeight > 0
        ? (weightedRegret / totalWeight * 100).clamp(0.0, 100.0)
        : 0.0;
  }

  /// Detect regret patterns across all decisions.
  List<RegretPattern> detectRegretPatterns() {
    final withRegret = _decisions
        .where((d) =>
            d.outcome != null &&
            d.outcome!.regretType != null &&
            d.outcome!.regretIntensity > 0.2)
        .toList();

    if (withRegret.isEmpty) return [];

    final patterns = <String, List<Decision>>{};
    for (final d in withRegret) {
      final key = '${d.outcome!.regretType!.name}_${d.domain.name}';
      patterns.putIfAbsent(key, () => []).add(d);
    }

    return patterns.entries
        .where((e) => e.value.length >= 2)
        .map((e) {
          final decisions = e.value;
          final type = decisions.first.outcome!.regretType!;
          final domain = decisions.first.domain;
          final avgIntensity = decisions
                  .map((d) => d.outcome!.regretIntensity)
                  .reduce((a, b) => a + b) /
              decisions.length;

          return RegretPattern(
            type: type,
            domain: domain,
            occurrences: decisions.length,
            averageIntensity: avgIntensity,
            insight: _generatePatternInsight(type, domain, decisions.length),
            prevention:
                _generatePreventionStrategy(type, domain, avgIntensity),
          );
        })
        .toList()
      ..sort((a, b) =>
          (b.averageIntensity * b.occurrences)
              .compareTo(a.averageIntensity * a.occurrences));
  }

  /// Compute satisfaction by domain.
  Map<DecisionDomain, double> getDomainSatisfaction() {
    final result = <DecisionDomain, double>{};
    for (final domain in DecisionDomain.values) {
      final domainDecisions = _decisions
          .where((d) => d.domain == domain && d.outcome != null)
          .toList();
      if (domainDecisions.isNotEmpty) {
        result[domain] = domainDecisions
                .map((d) => d.outcome!.satisfaction.score)
                .reduce((a, b) => a + b) /
            domainDecisions.length;
      }
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Bias Detection
  // -------------------------------------------------------------------------

  /// Run bias detection on a single decision.
  void _runBiasDetection(Decision decision) {
    final detections = <BiasDetection>[];

    // Status Quo Bias: low confidence + chose inaction/safe option
    if (decision.confidenceLevel < 0.4 &&
        decision.outcome != null &&
        decision.outcome!.regretType == RegretType.inactionRegret) {
      detections.add(BiasDetection(
        decisionId: decision.id,
        bias: CognitiveBias.statusQuoBias,
        confidence: 0.7,
        evidence:
            'Low confidence (${(decision.confidenceLevel * 100).toInt()}%) '
            'combined with later inaction regret suggests status quo preference',
      ));
    }

    // Loss Aversion: high stakes + regret of inaction + mentions of risk/loss
    if (decision.stakes.weight >= 1.0 &&
        decision.outcome?.regretType == RegretType.inactionRegret &&
        (decision.reasoning.toLowerCase().contains('risk') ||
            decision.reasoning.toLowerCase().contains('lose') ||
            decision.reasoning.toLowerCase().contains('safe'))) {
      detections.add(BiasDetection(
        decisionId: decision.id,
        bias: CognitiveBias.lossAversion,
        confidence: 0.65,
        evidence: 'High-stakes inaction with risk-focused reasoning '
            'suggests loss aversion overriding potential gains',
      ));
    }

    // Sunk Cost: mentions of investment/time spent in reasoning
    if (decision.reasoning.toLowerCase().contains('already invested') ||
        decision.reasoning.toLowerCase().contains('already spent') ||
        decision.reasoning.toLowerCase().contains('too far to quit') ||
        decision.reasoning.toLowerCase().contains('come this far')) {
      detections.add(BiasDetection(
        decisionId: decision.id,
        bias: CognitiveBias.sunkCostFallacy,
        confidence: 0.8,
        evidence: 'Reasoning explicitly references past investment '
            'as justification for continuing',
      ));
    }

    // Present Bias: short-term choice + later regret
    if (decision.emotionsAtTime.any((e) =>
            e.toLowerCase().contains('impatient') ||
            e.toLowerCase().contains('excited') ||
            e.toLowerCase().contains('urgent')) &&
        decision.outcome != null &&
        decision.outcome!.satisfaction.score < 0) {
      detections.add(BiasDetection(
        decisionId: decision.id,
        bias: CognitiveBias.presentBias,
        confidence: 0.6,
        evidence: 'Urgency/impatience emotions at decision time '
            'combined with negative outcome suggests present bias',
      ));
    }

    // Overconfidence: very high confidence + negative outcome
    if (decision.confidenceLevel > 0.85 &&
        decision.outcome != null &&
        decision.outcome!.satisfaction.score < 0) {
      detections.add(BiasDetection(
        decisionId: decision.id,
        bias: CognitiveBias.overconfidence,
        confidence: 0.75,
        evidence:
            'Confidence was ${(decision.confidenceLevel * 100).toInt()}% '
            'but outcome was negative — calibration issue',
      ));
    }

    // Bandwagon: external pressure + later regret
    if (decision.externalPressure != null &&
        decision.externalPressure!.isNotEmpty &&
        decision.outcome != null &&
        decision.outcome!.regretIntensity > 0.3) {
      detections.add(BiasDetection(
        decisionId: decision.id,
        bias: CognitiveBias.bandwagonEffect,
        confidence: 0.55,
        evidence: 'External pressure noted ("${decision.externalPressure}") '
            'combined with later regret suggests social influence override',
      ));
    }

    _biasDetections.addAll(detections);
  }

  /// Get all bias detections sorted by confidence.
  List<BiasDetection> getBiasDetections() {
    return List.of(_biasDetections)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  /// Get bias frequency profile.
  Map<CognitiveBias, int> getBiasProfile() {
    final profile = <CognitiveBias, int>{};
    for (final d in _biasDetections) {
      profile[d.bias] = (profile[d.bias] ?? 0) + 1;
    }
    return profile;
  }

  // -------------------------------------------------------------------------
  // Wisdom Generation
  // -------------------------------------------------------------------------

  /// Update wisdom principles based on current decision history.
  void _updateWisdom() {
    _wisdomPrinciples.clear();
    final withOutcomes =
        _decisions.where((d) => d.outcome != null).toList();
    if (withOutcomes.length < 3) return;

    // Principle: Reversibility correlates with less regret
    final reversible =
        withOutcomes.where((d) => d.wasReversible).toList();
    final irreversible =
        withOutcomes.where((d) => !d.wasReversible).toList();
    if (reversible.isNotEmpty && irreversible.isNotEmpty) {
      final revRegret = reversible
              .map((d) => d.outcome!.regretIntensity)
              .reduce((a, b) => a + b) /
          reversible.length;
      final irrevRegret = irreversible
              .map((d) => d.outcome!.regretIntensity)
              .reduce((a, b) => a + b) /
          irreversible.length;
      if (irrevRegret > revRegret + 0.1) {
        _wisdomPrinciples.add(WisdomPrinciple(
          id: 'reversibility',
          principle:
              'Prefer reversible decisions — they carry less regret weight',
          evidence:
              'Irreversible decisions average ${(irrevRegret * 100).toInt()}% '
              'regret vs ${(revRegret * 100).toInt()}% for reversible ones',
          applicableDomains: DecisionDomain.values.toList(),
          strength: min(1.0, (irrevRegret - revRegret) * 2),
          supportingDecisions: withOutcomes.length,
          discoveredAt: DateTime.now(),
        ));
      }
    }

    // Principle: High confidence ≠ good outcomes
    final highConf =
        withOutcomes.where((d) => d.confidenceLevel > 0.8).toList();
    final lowConf =
        withOutcomes.where((d) => d.confidenceLevel < 0.5).toList();
    if (highConf.isNotEmpty && lowConf.isNotEmpty) {
      final highSat = highConf
              .map((d) => d.outcome!.satisfaction.score)
              .reduce((a, b) => a + b) /
          highConf.length;
      final lowSat = lowConf
              .map((d) => d.outcome!.satisfaction.score)
              .reduce((a, b) => a + b) /
          lowConf.length;
      if ((highSat - lowSat).abs() < 0.2) {
        _wisdomPrinciples.add(WisdomPrinciple(
          id: 'confidence_calibration',
          principle:
              'Your confidence level doesn\'t predict outcome quality — '
              'slow down on "sure things"',
          evidence:
              'High-confidence decisions (>${(0.8 * 100).toInt()}%) '
              'produced similar satisfaction to low-confidence ones',
          applicableDomains: DecisionDomain.values.toList(),
          strength: 0.7,
          supportingDecisions: highConf.length + lowConf.length,
          discoveredAt: DateTime.now(),
        ));
      }
    }

    // Principle: Domain-specific patterns
    for (final domain in DecisionDomain.values) {
      final domainDecisions =
          withOutcomes.where((d) => d.domain == domain).toList();
      if (domainDecisions.length >= 3) {
        final goodOnes = domainDecisions
            .where((d) => d.outcome!.satisfaction.score > 0)
            .toList();
        if (goodOnes.length >= 2) {
          // Check if good decisions share characteristics
          final avgConfGood = goodOnes
                  .map((d) => d.confidenceLevel)
                  .reduce((a, b) => a + b) /
              goodOnes.length;
          if (avgConfGood > 0.6) {
            _wisdomPrinciples.add(WisdomPrinciple(
              id: 'domain_${domain.name}_confidence',
              principle:
                  'In ${domain.label}, trust your gut — high confidence '
                  'correlates with good outcomes here',
              evidence:
                  '${goodOnes.length}/${domainDecisions.length} positive outcomes '
                  'had confidence >${(avgConfGood * 100).toInt()}%',
              applicableDomains: [domain],
              strength: min(1.0, goodOnes.length / domainDecisions.length),
              supportingDecisions: domainDecisions.length,
              discoveredAt: DateTime.now(),
            ));
          }
        }
      }
    }

    // Principle: Inaction regret dominates over time
    final actionRegrets = withOutcomes
        .where((d) => d.outcome!.regretType == RegretType.actionRegret)
        .toList();
    final inactionRegrets = withOutcomes
        .where((d) => d.outcome!.regretType == RegretType.inactionRegret)
        .toList();
    if (inactionRegrets.length > actionRegrets.length &&
        inactionRegrets.length >= 3) {
      _wisdomPrinciples.add(WisdomPrinciple(
        id: 'inaction_dominance',
        principle:
            'You regret inaction more than action — bias toward doing',
        evidence:
            '${inactionRegrets.length} inaction regrets vs '
            '${actionRegrets.length} action regrets',
        applicableDomains: DecisionDomain.values.toList(),
        strength: min(
            1.0,
            inactionRegrets.length /
                max(1, actionRegrets.length + inactionRegrets.length)),
        supportingDecisions:
            actionRegrets.length + inactionRegrets.length,
        discoveredAt: DateTime.now(),
      ));
    }
  }

  // -------------------------------------------------------------------------
  // Future Self Test
  // -------------------------------------------------------------------------

  /// Run the "Future Self" regret minimization test on a pending decision.
  FutureSelfTest runFutureSelfTest({
    required String title,
    required DecisionDomain domain,
    required StakesLevel stakes,
    required bool isAction, // true = considering acting, false = considering not acting
  }) {
    // Use historical patterns to predict regret
    final domainDecisions = _decisions
        .where((d) => d.domain == domain && d.outcome != null)
        .toList();

    double regretIfAct = 0.3; // baseline
    double regretIfSkip = 0.4; // slightly higher (inaction regret)

    if (domainDecisions.isNotEmpty) {
      final actionOnes = domainDecisions
          .where((d) => d.outcome!.regretType == RegretType.actionRegret);
      final inactionOnes = domainDecisions
          .where((d) => d.outcome!.regretType == RegretType.inactionRegret);

      if (actionOnes.isNotEmpty) {
        regretIfAct = actionOnes
                .map((d) => d.outcome!.regretIntensity)
                .reduce((a, b) => a + b) /
            actionOnes.length;
      }
      if (inactionOnes.isNotEmpty) {
        regretIfSkip = inactionOnes
                .map((d) => d.outcome!.regretIntensity)
                .reduce((a, b) => a + b) /
            inactionOnes.length;
      }
    }

    // Stakes amplify regret
    regretIfAct *= stakes.weight / 2;
    regretIfSkip *= stakes.weight / 2;
    regretIfAct = regretIfAct.clamp(0.0, 1.0);
    regretIfSkip = regretIfSkip.clamp(0.0, 1.0);

    final tenYear = regretIfSkip > regretIfAct
        ? 'In 10 years, you\'re more likely to regret NOT doing this '
            '(${(regretIfSkip * 100).toInt()}% vs ${(regretIfAct * 100).toInt()}%)'
        : 'In 10 years, the risk of action regret is higher '
            '(${(regretIfAct * 100).toInt()}% vs ${(regretIfSkip * 100).toInt()}%)';

    final deathbed = stakes.weight >= 2.0
        ? 'This is a life-defining moment. '
            '${regretIfSkip > regretIfAct ? "Your future self wants you to be brave." : "Caution is wisdom here — protect what matters."}'
        : 'This won\'t be a deathbed regret either way. '
            'Choose based on growth, not fear.';

    final recommendation = regretIfSkip > regretIfAct
        ? '🟢 ACT — Your history suggests inaction regret is higher in ${domain.label}'
        : regretIfAct > regretIfSkip
            ? '🟡 PAUSE — Consider more carefully; action regret is elevated'
            : '⚪ NEUTRAL — Either path is likely fine; follow your energy';

    return FutureSelfTest(
      decisionTitle: title,
      regretIfAct: regretIfAct,
      regretIfSkip: regretIfSkip,
      tenYearPerspective: tenYear,
      deathbedPerspective: deathbed,
      recommendation: recommendation,
    );
  }

  // -------------------------------------------------------------------------
  // Dashboard
  // -------------------------------------------------------------------------

  /// Generate the full regret minimization dashboard.
  RegretDashboard getDashboard() {
    final withOutcomes =
        _decisions.where((d) => d.outcome != null).toList();
    final pending = getPendingReviews();

    final overallSat = withOutcomes.isEmpty
        ? 0.0
        : withOutcomes
                .map((d) => d.outcome!.satisfaction.score)
                .reduce((a, b) => a + b) /
            withOutcomes.length;

    final regretScore = computeRegretScore();
    final wisdomScore = _computeWisdomScore();

    final verdict = _generateHealthVerdict(regretScore, wisdomScore);

    return RegretDashboard(
      totalDecisions: _decisions.length,
      outcomeRecorded: withOutcomes.length,
      pendingReview: pending.length,
      overallSatisfaction: overallSat,
      regretScore: regretScore,
      wisdomScore: wisdomScore,
      domainSatisfaction: getDomainSatisfaction(),
      topPatterns: detectRegretPatterns().take(5).toList(),
      recentBiases: getBiasDetections().take(5).toList(),
      wisdomPrinciples: _wisdomPrinciples,
      upcomingReviews: pending.take(5).toList(),
      healthVerdict: verdict,
    );
  }

  double _computeWisdomScore() {
    if (_decisions.isEmpty) return 0.0;

    double score = 0;

    // Decisions with outcomes recorded (+)
    final reviewRate = _decisions.isEmpty
        ? 0.0
        : _decisions.where((d) => d.outcome != null).length /
            _decisions.length;
    score += reviewRate * 30; // max 30 points for reviewing decisions

    // Wisdom principles generated
    score += min(30.0, _wisdomPrinciples.length * 10.0);

    // Improvement over time (recent decisions have less regret)
    final withOutcomes =
        _decisions.where((d) => d.outcome != null).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (withOutcomes.length >= 6) {
      final firstHalf = withOutcomes.sublist(0, withOutcomes.length ~/ 2);
      final secondHalf = withOutcomes.sublist(withOutcomes.length ~/ 2);
      final earlyRegret = firstHalf
              .map((d) => d.outcome!.regretIntensity)
              .reduce((a, b) => a + b) /
          firstHalf.length;
      final lateRegret = secondHalf
              .map((d) => d.outcome!.regretIntensity)
              .reduce((a, b) => a + b) /
          secondHalf.length;
      if (lateRegret < earlyRegret) {
        score += min(20.0, (earlyRegret - lateRegret) * 100);
      }
    }

    // Bias awareness (having detected biases shows self-awareness)
    score += min(20.0, _biasDetections.length * 4.0);

    return score.clamp(0.0, 100.0);
  }

  String _generateHealthVerdict(double regretScore, double wisdomScore) {
    if (regretScore < 20 && wisdomScore > 60) {
      return '🌟 Excellent — Low regret, high wisdom. You\'re making decisions you can be proud of.';
    } else if (regretScore < 40 && wisdomScore > 40) {
      return '✅ Good — Healthy decision-making with room to grow. Keep reviewing outcomes.';
    } else if (regretScore < 60) {
      return '⚠️ Mixed — Some regret patterns emerging. Focus on the bias antidotes.';
    } else if (wisdomScore > 50) {
      return '📈 Learning — High regret BUT you\'re gaining wisdom fast. The trend is positive.';
    } else {
      return '🔴 Attention needed — Significant regret accumulation. Consider slowing down major decisions.';
    }
  }

  // -------------------------------------------------------------------------
  // Pattern Helpers
  // -------------------------------------------------------------------------

  String _generatePatternInsight(
      RegretType type, DecisionDomain domain, int count) {
    switch (type) {
      case RegretType.inactionRegret:
        return 'You\'ve regretted NOT acting in ${domain.label} '
            '$count times. Fear may be holding you back.';
      case RegretType.actionRegret:
        return 'You\'ve regretted acting impulsively in ${domain.label} '
            '$count times. Adding a 24h delay might help.';
      case RegretType.timingRegret:
        return 'In ${domain.label}, your timing has been off $count times. '
            'Consider whether "when" matters as much as "what".';
      case RegretType.methodRegret:
        return 'The approach keeps being wrong in ${domain.label} ($count times). '
            'Try consulting someone with different expertise.';
      case RegretType.scopeRegret:
        return 'You\'ve misjudged the scale needed in ${domain.label} '
            '$count times. Start smaller or think bigger.';
    }
  }

  String _generatePreventionStrategy(
      RegretType type, DecisionDomain domain, double intensity) {
    final urgent = intensity > 0.6;
    switch (type) {
      case RegretType.inactionRegret:
        return urgent
            ? 'URGENT: Set a "bias to action" rule for ${domain.label}. '
                'If in doubt for >48h, default to acting.'
            : 'Consider: "What would I attempt if I knew I couldn\'t fail?"';
      case RegretType.actionRegret:
        return urgent
            ? 'URGENT: Institute a mandatory 72h cooling period for '
                '${domain.label} decisions above moderate stakes.'
            : 'Try writing down pros/cons and sleeping on it.';
      case RegretType.timingRegret:
        return urgent
            ? 'URGENT: Create explicit timing criteria — '
                '"I will act when X, Y, Z conditions are met"'
            : 'Set calendar reminders to revisit timing-sensitive decisions.';
      case RegretType.methodRegret:
        return urgent
            ? 'URGENT: Before your next ${domain.label} decision, '
                'consult 3 people who\'ve done it differently.'
            : 'Research 3 alternative approaches before committing to one.';
      case RegretType.scopeRegret:
        return urgent
            ? 'URGENT: Use the "10x test" — would this work at 10x scale? '
                'At 1/10 scale? Find the right order of magnitude.'
            : 'Prototype at small scale before committing to full scope.';
    }
  }

  // -------------------------------------------------------------------------
  // Sample Data
  // -------------------------------------------------------------------------

  /// Load sample data for demonstration.
  void loadSampleData() {
    _decisions.clear();
    _biasDetections.clear();
    _wisdomPrinciples.clear();

    final now = DateTime.now();

    _decisions.addAll([
      Decision(
        id: 'd1',
        timestamp: now.subtract(const Duration(days: 180)),
        title: 'Declined speaking opportunity at tech conference',
        description: 'Was invited to give a talk but turned it down due to imposter syndrome',
        domain: DecisionDomain.career,
        stakes: StakesLevel.moderate,
        alternatives: ['Accept and prepare', 'Decline', 'Propose co-presenting'],
        chosenOption: 'Decline',
        reasoning: 'Not ready yet, might embarrass myself, too risky',
        confidenceLevel: 0.3,
        emotionsAtTime: ['anxious', 'doubtful', 'relieved'],
        wasReversible: false,
        externalPressure: 'Manager encouraged me to accept',
        outcome: DecisionOutcome(
          recordedAt: now.subtract(const Duration(days: 90)),
          satisfaction: OutcomeSatisfaction.regretful,
          whatHappened: 'A junior colleague accepted and got promoted. I was still qualified.',
          whatSurprised: 'How much I underestimated myself',
          regretType: RegretType.inactionRegret,
          regretIntensity: 0.8,
          lessonLearned: 'Growth happens outside comfort zone',
          wouldChooseSameAgain: false,
        ),
      ),
      Decision(
        id: 'd2',
        timestamp: now.subtract(const Duration(days: 150)),
        title: 'Switched to a plant-based diet',
        description: 'Committed to 90 days of plant-based eating',
        domain: DecisionDomain.health,
        stakes: StakesLevel.low,
        alternatives: ['Full plant-based', 'Gradual transition', 'Stay same'],
        chosenOption: 'Full plant-based',
        reasoning: 'Research supports it, energy might improve',
        confidenceLevel: 0.6,
        emotionsAtTime: ['motivated', 'curious'],
        wasReversible: true,
        outcome: DecisionOutcome(
          recordedAt: now.subtract(const Duration(days: 60)),
          satisfaction: OutcomeSatisfaction.satisfied,
          whatHappened: 'Energy improved, but social dining became harder',
          whatSurprised: 'How much food is a social activity',
          regretType: null,
          regretIntensity: 0.1,
          lessonLearned: 'Partial changes are more sustainable than all-or-nothing',
          wouldChooseSameAgain: true,
        ),
      ),
      Decision(
        id: 'd3',
        timestamp: now.subtract(const Duration(days: 120)),
        title: 'Invested in crypto during hype cycle',
        description: 'Put 20% of savings into altcoins because everyone was doing it',
        domain: DecisionDomain.finance,
        stakes: StakesLevel.high,
        alternatives: ['Index funds', 'Crypto', 'Split 50/50', 'Wait'],
        chosenOption: 'Crypto',
        reasoning: 'Everyone is making money, FOMO, don\'t want to miss out',
        confidenceLevel: 0.9,
        emotionsAtTime: ['excited', 'impatient', 'urgent'],
        wasReversible: true,
        externalPressure: 'Friends all investing, social media hype',
        outcome: DecisionOutcome(
          recordedAt: now.subtract(const Duration(days: 30)),
          satisfaction: OutcomeSatisfaction.disappointed,
          whatHappened: 'Lost 60% of investment in the crash',
          whatSurprised: 'How confident I was despite zero expertise',
          regretType: RegretType.actionRegret,
          regretIntensity: 0.7,
          lessonLearned: 'High confidence + FOMO = danger zone',
          wouldChooseSameAgain: false,
        ),
      ),
      Decision(
        id: 'd4',
        timestamp: now.subtract(const Duration(days: 100)),
        title: 'Didn\'t apply for dream job posting',
        description: 'Saw perfect role but didn\'t apply because I met only 7/10 requirements',
        domain: DecisionDomain.career,
        stakes: StakesLevel.high,
        alternatives: ['Apply', 'Don\'t apply', 'Apply and lower expectations'],
        chosenOption: 'Don\'t apply',
        reasoning: 'Not qualified enough, would waste their time, too risky to leave current job',
        confidenceLevel: 0.25,
        emotionsAtTime: ['inadequate', 'safe', 'wistful'],
        wasReversible: false,
        outcome: DecisionOutcome(
          recordedAt: now.subtract(const Duration(days: 40)),
          satisfaction: OutcomeSatisfaction.regretful,
          whatHappened: 'Position filled. Still think about it.',
          whatSurprised: 'The person hired had similar experience to mine',
          regretType: RegretType.inactionRegret,
          regretIntensity: 0.85,
          lessonLearned: 'Let them say no — don\'t say no for them',
          wouldChooseSameAgain: false,
        ),
      ),
      Decision(
        id: 'd5',
        timestamp: now.subtract(const Duration(days: 90)),
        title: 'Started a side project instead of resting',
        description: 'Launched a weekend project despite being burned out',
        domain: DecisionDomain.creative,
        stakes: StakesLevel.moderate,
        alternatives: ['Start project', 'Take a break', 'Scale back hours'],
        chosenOption: 'Start project',
        reasoning: 'Already spent weeks thinking about it, come this far in planning',
        confidenceLevel: 0.7,
        emotionsAtTime: ['driven', 'tired', 'excited'],
        wasReversible: true,
        outcome: DecisionOutcome(
          recordedAt: now.subtract(const Duration(days: 20)),
          satisfaction: OutcomeSatisfaction.neutral,
          whatHappened: 'Project is half-done, burnout worse. Good learning though.',
          whatSurprised: 'How long recovery took afterwards',
          regretType: RegretType.timingRegret,
          regretIntensity: 0.4,
          lessonLearned: 'Timing matters — rest first, create second',
          wouldChooseSameAgain: false,
        ),
      ),
      Decision(
        id: 'd6',
        timestamp: now.subtract(const Duration(days: 60)),
        title: 'Signed up for a marathon',
        description: 'Committed to running a full marathon in 4 months',
        domain: DecisionDomain.health,
        stakes: StakesLevel.moderate,
        alternatives: ['Full marathon', 'Half marathon', 'Skip this year'],
        chosenOption: 'Full marathon',
        reasoning: 'Want to prove I can do it, already run half marathons',
        confidenceLevel: 0.75,
        emotionsAtTime: ['ambitious', 'determined'],
        wasReversible: true,
        outcome: DecisionOutcome(
          recordedAt: now.subtract(const Duration(days: 5)),
          satisfaction: OutcomeSatisfaction.thrilled,
          whatHappened: 'Finished in 4:15! Best accomplishment this year.',
          whatSurprised: 'The mental strength I discovered',
          regretType: null,
          regretIntensity: 0.0,
          lessonLearned: 'Stretch goals reveal hidden capacity',
          wouldChooseSameAgain: true,
        ),
      ),
      Decision(
        id: 'd7',
        timestamp: now.subtract(const Duration(days: 45)),
        title: 'Kept quiet in team disagreement',
        description: 'Disagreed with team direction but didn\'t speak up',
        domain: DecisionDomain.career,
        stakes: StakesLevel.moderate,
        alternatives: ['Speak up in meeting', 'Talk privately to lead', 'Stay quiet'],
        chosenOption: 'Stay quiet',
        reasoning: 'Don\'t want conflict, maybe I\'m wrong, too risky',
        confidenceLevel: 0.35,
        emotionsAtTime: ['uncomfortable', 'doubtful', 'safe'],
        wasReversible: false,
        externalPressure: 'Team consensus seemed strong',
        outcome: DecisionOutcome(
          recordedAt: now.subtract(const Duration(days: 10)),
          satisfaction: OutcomeSatisfaction.disappointed,
          whatHappened: 'Team hit exactly the problem I foresaw. Months wasted.',
          whatSurprised: 'Others had similar doubts but also stayed silent',
          regretType: RegretType.inactionRegret,
          regretIntensity: 0.6,
          lessonLearned: 'Silence isn\'t safety — it\'s complicity in bad outcomes',
          wouldChooseSameAgain: false,
        ),
      ),
      Decision(
        id: 'd8',
        timestamp: now.subtract(const Duration(days: 30)),
        title: 'Enrolled in online ML course',
        description: 'Committed to a 12-week machine learning program',
        domain: DecisionDomain.education,
        stakes: StakesLevel.low,
        alternatives: ['This course', 'Self-study', 'Wait for better course', 'Skip'],
        chosenOption: 'This course',
        reasoning: 'Structured learning works better for me, good reviews',
        confidenceLevel: 0.8,
        emotionsAtTime: ['enthusiastic', 'hopeful'],
        wasReversible: true,
        outcome: null, // Not yet reviewed
      ),
    ]);

    // Run bias detection on decisions with outcomes
    for (final d in _decisions.where((d) => d.outcome != null)) {
      _runBiasDetection(d);
    }
    _updateWisdom();
  }
}
