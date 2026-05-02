import 'dart:math';

/// Life Balance Radar Engine — autonomous multi-dimensional life balance
/// assessment. Tracks activity across 8 life dimensions, detects imbalances
/// via variance/threshold analysis, generates rebalancing recommendations,
/// and computes a composite balance score 0-100.
///
/// 7 engines: Activity Tracker · Dimension Scorer · Imbalance Detector ·
/// Trend Analyzer · Recommendation Engine · Snapshot Generator · Insight Generator

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// The 8 core life dimensions tracked by the radar.
enum BalanceDimension {
  health,
  work,
  social,
  learning,
  finance,
  fitness,
  creativity,
  mindfulness;

  String get label {
    switch (this) {
      case BalanceDimension.health:
        return 'Health';
      case BalanceDimension.work:
        return 'Work';
      case BalanceDimension.social:
        return 'Social';
      case BalanceDimension.learning:
        return 'Learning';
      case BalanceDimension.finance:
        return 'Finance';
      case BalanceDimension.fitness:
        return 'Fitness';
      case BalanceDimension.creativity:
        return 'Creativity';
      case BalanceDimension.mindfulness:
        return 'Mindfulness';
    }
  }

  String get emoji {
    switch (this) {
      case BalanceDimension.health:
        return '🏥';
      case BalanceDimension.work:
        return '💼';
      case BalanceDimension.social:
        return '👥';
      case BalanceDimension.learning:
        return '📚';
      case BalanceDimension.finance:
        return '💰';
      case BalanceDimension.fitness:
        return '🏋️';
      case BalanceDimension.creativity:
        return '🎨';
      case BalanceDimension.mindfulness:
        return '🧘';
    }
  }

  String get description {
    switch (this) {
      case BalanceDimension.health:
        return 'Physical and mental health activities';
      case BalanceDimension.work:
        return 'Career, projects, and professional growth';
      case BalanceDimension.social:
        return 'Relationships, community, and social engagement';
      case BalanceDimension.learning:
        return 'Education, reading, and skill acquisition';
      case BalanceDimension.finance:
        return 'Budgeting, investing, and financial planning';
      case BalanceDimension.fitness:
        return 'Exercise, sports, and physical activity';
      case BalanceDimension.creativity:
        return 'Art, music, writing, and creative expression';
      case BalanceDimension.mindfulness:
        return 'Meditation, reflection, and mental clarity';
    }
  }
}

/// Types of detected imbalances.
enum ImbalanceType {
  overinvested,
  neglected,
  volatile,
  stagnant,
  declining;

  String get label {
    switch (this) {
      case ImbalanceType.overinvested:
        return 'Overinvested';
      case ImbalanceType.neglected:
        return 'Neglected';
      case ImbalanceType.volatile:
        return 'Volatile';
      case ImbalanceType.stagnant:
        return 'Stagnant';
      case ImbalanceType.declining:
        return 'Declining';
    }
  }
}

/// Trend direction for balance scores.
enum BalanceTrend {
  improving,
  stable,
  declining,
  volatile;

  String get label {
    switch (this) {
      case BalanceTrend.improving:
        return 'Improving';
      case BalanceTrend.stable:
        return 'Stable';
      case BalanceTrend.declining:
        return 'Declining';
      case BalanceTrend.volatile:
        return 'Volatile';
    }
  }

  String get arrow {
    switch (this) {
      case BalanceTrend.improving:
        return '↑';
      case BalanceTrend.stable:
        return '→';
      case BalanceTrend.declining:
        return '↓';
      case BalanceTrend.volatile:
        return '↕';
    }
  }
}

/// Priority levels for recommendations.
enum RecommendationPriority {
  critical,
  high,
  medium,
  low;

  String get label {
    switch (this) {
      case RecommendationPriority.critical:
        return 'Critical';
      case RecommendationPriority.high:
        return 'High';
      case RecommendationPriority.medium:
        return 'Medium';
      case RecommendationPriority.low:
        return 'Low';
    }
  }

  int get sortOrder {
    switch (this) {
      case RecommendationPriority.critical:
        return 0;
      case RecommendationPriority.high:
        return 1;
      case RecommendationPriority.medium:
        return 2;
      case RecommendationPriority.low:
        return 3;
    }
  }
}

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

/// A recorded activity in a life dimension.
class DimensionActivity {
  final String id;
  final BalanceDimension dimension;
  final double intensity; // 0-100
  final int durationMinutes;
  final DateTime timestamp;
  final String notes;

  DimensionActivity({
    required this.id,
    required this.dimension,
    required this.intensity,
    required this.durationMinutes,
    required this.timestamp,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dimension': dimension.name,
        'intensity': intensity,
        'durationMinutes': durationMinutes,
        'timestamp': timestamp.toIso8601String(),
        'notes': notes,
      };

  factory DimensionActivity.fromJson(Map<String, dynamic> json) =>
      DimensionActivity(
        id: json['id'] as String,
        dimension: BalanceDimension.values
            .firstWhere((d) => d.name == json['dimension']),
        intensity: (json['intensity'] as num).toDouble(),
        durationMinutes: json['durationMinutes'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        notes: json['notes'] as String? ?? '',
      );
}

/// Computed score for one dimension.
class DimensionScore {
  final BalanceDimension dimension;
  final double score; // 0-100
  final int activityCount;
  final double avgIntensity;
  final BalanceTrend trend;
  final double trendDelta;

  DimensionScore({
    required this.dimension,
    required this.score,
    required this.activityCount,
    required this.avgIntensity,
    required this.trend,
    required this.trendDelta,
  });

  Map<String, dynamic> toJson() => {
        'dimension': dimension.name,
        'score': score,
        'activityCount': activityCount,
        'avgIntensity': avgIntensity,
        'trend': trend.name,
        'trendDelta': trendDelta,
      };
}

/// Detected imbalance alert.
class ImbalanceAlert {
  final String id;
  final ImbalanceType type;
  final List<BalanceDimension> affectedDimensions;
  final double severity; // 0-100
  final String description;
  final String suggestion;
  final DateTime createdAt;

  ImbalanceAlert({
    required this.id,
    required this.type,
    required this.affectedDimensions,
    required this.severity,
    required this.description,
    required this.suggestion,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'affectedDimensions':
            affectedDimensions.map((d) => d.name).toList(),
        'severity': severity,
        'description': description,
        'suggestion': suggestion,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Full radar snapshot at a point in time.
class BalanceSnapshot {
  final String id;
  final DateTime timestamp;
  final Map<BalanceDimension, DimensionScore> dimensionScores;
  final double compositeScore; // 0-100
  final double giniCoefficient; // 0-1
  final List<ImbalanceAlert> alerts;
  final BalanceTrend trend;

  BalanceSnapshot({
    required this.id,
    required this.timestamp,
    required this.dimensionScores,
    required this.compositeScore,
    required this.giniCoefficient,
    required this.alerts,
    required this.trend,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'dimensionScores': dimensionScores
            .map((k, v) => MapEntry(k.name, v.toJson())),
        'compositeScore': compositeScore,
        'giniCoefficient': giniCoefficient,
        'alerts': alerts.map((a) => a.toJson()).toList(),
        'trend': trend.name,
      };
}

/// Actionable rebalancing recommendation.
class RebalanceRecommendation {
  final String id;
  final RecommendationPriority priority;
  final BalanceDimension targetDimension;
  final double currentScore;
  final double targetScore;
  final String action;
  final String reasoning;
  final double estimatedImpact;

  RebalanceRecommendation({
    required this.id,
    required this.priority,
    required this.targetDimension,
    required this.currentScore,
    required this.targetScore,
    required this.action,
    required this.reasoning,
    required this.estimatedImpact,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'priority': priority.name,
        'targetDimension': targetDimension.name,
        'currentScore': currentScore,
        'targetScore': targetScore,
        'action': action,
        'reasoning': reasoning,
        'estimatedImpact': estimatedImpact,
      };
}

/// Full analysis report.
class BalanceReport {
  final List<BalanceSnapshot> snapshots;
  final List<RebalanceRecommendation> recommendations;
  final List<String> insights;
  final String overallHealth;

  BalanceReport({
    required this.snapshots,
    required this.recommendations,
    required this.insights,
    required this.overallHealth,
  });

  Map<String, dynamic> toJson() => {
        'snapshots': snapshots.map((s) => s.toJson()).toList(),
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'insights': insights,
        'overallHealth': overallHealth,
      };
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Life Balance Radar Engine — autonomously assesses multi-dimensional life
/// balance and generates actionable rebalancing insights.
class BalanceRadarEngineService {
  final List<DimensionActivity> _activities = [];
  final List<BalanceSnapshot> _snapshots = [];
  final Random _random = Random(42);

  /// Exponential decay half-life in days for recency weighting.
  final double halfLifeDays;

  /// Threshold below which a dimension is considered neglected.
  final double neglectThreshold;

  /// Threshold above which overinvestment is flagged (if others are low).
  final double overinvestThreshold;

  /// Days of inactivity before a dimension is flagged as stagnant.
  final int stagnantDays;

  BalanceRadarEngineService({
    this.halfLifeDays = 7.0,
    this.neglectThreshold = 20.0,
    this.overinvestThreshold = 80.0,
    this.stagnantDays = 14,
  });

  // -----------------------------------------------------------------------
  // 1. Activity Tracker
  // -----------------------------------------------------------------------

  /// Record a new activity.
  void addActivity(DimensionActivity activity) {
    _activities.add(activity);
  }

  /// All recorded activities (unmodifiable).
  List<DimensionActivity> get activities => List.unmodifiable(_activities);

  /// All historical snapshots (unmodifiable).
  List<BalanceSnapshot> get snapshots => List.unmodifiable(_snapshots);

  /// Activities filtered by dimension.
  List<DimensionActivity> getActivitiesByDimension(BalanceDimension dim) =>
      _activities.where((a) => a.dimension == dim).toList();

  /// Activities within a date range.
  List<DimensionActivity> getActivitiesInRange(DateTime start, DateTime end) =>
      _activities
          .where((a) =>
              !a.timestamp.isBefore(start) && !a.timestamp.isAfter(end))
          .toList();

  // -----------------------------------------------------------------------
  // 2. Dimension Scorer
  // -----------------------------------------------------------------------

  /// Score a single dimension 0-100 based on recency-weighted activity.
  ///
  /// Formula: frequency(40%) + intensity(30%) + recency(30%)
  /// Frequency = min(1, count / expectedWeekly) where expectedWeekly = 3
  /// Intensity = average intensity of recent activities
  /// Recency = exponential decay from most recent activity
  DimensionScore scoreDimension(BalanceDimension dim, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final dimActivities = getActivitiesByDimension(dim);

    if (dimActivities.isEmpty) {
      return DimensionScore(
        dimension: dim,
        score: 0,
        activityCount: 0,
        avgIntensity: 0,
        trend: BalanceTrend.stable,
        trendDelta: 0,
      );
    }

    // Recency-weighted activities (last 30 days matter most).
    final decayConstant = log(2) / halfLifeDays;
    double weightedSum = 0;
    double weightTotal = 0;
    int recentCount = 0;

    for (final act in dimActivities) {
      final daysAgo =
          reference.difference(act.timestamp).inHours / 24.0;
      if (daysAgo < 0) continue; // future activities ignored
      final weight = exp(-decayConstant * daysAgo);
      weightedSum += act.intensity * weight;
      weightTotal += weight;
      if (daysAgo <= 30) recentCount++;
    }

    // Frequency score: how often in last 30 days vs expected ~3/week.
    final expectedMonthly = 12.0; // ~3/week * 4 weeks
    final frequencyScore =
        (recentCount / expectedMonthly).clamp(0.0, 1.0) * 100;

    // Intensity score: weighted average intensity.
    final intensityScore =
        weightTotal > 0 ? (weightedSum / weightTotal) : 0.0;

    // Recency score: how recent is the latest activity?
    final sorted = List<DimensionActivity>.from(dimActivities)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final daysSinceLast =
        reference.difference(sorted.first.timestamp).inHours / 24.0;
    final recencyScore =
        (exp(-decayConstant * daysSinceLast) * 100).clamp(0.0, 100.0);

    // Composite dimension score.
    final score =
        (frequencyScore * 0.4 + intensityScore * 0.3 + recencyScore * 0.3)
            .clamp(0.0, 100.0);

    // Simple trend: compare first-half vs second-half activity counts.
    final halfPoint =
        reference.subtract(Duration(days: 15));
    final firstHalf = dimActivities
        .where((a) =>
            a.timestamp.isBefore(halfPoint) &&
            reference.difference(a.timestamp).inDays <= 30)
        .length;
    final secondHalf = dimActivities
        .where((a) => !a.timestamp.isBefore(halfPoint) &&
            reference.difference(a.timestamp).inDays <= 30)
        .length;
    final trendDelta = (secondHalf - firstHalf).toDouble();
    final trend = trendDelta > 2
        ? BalanceTrend.improving
        : trendDelta < -2
            ? BalanceTrend.declining
            : BalanceTrend.stable;

    final avgIntensity = dimActivities.isEmpty
        ? 0.0
        : dimActivities.map((a) => a.intensity).reduce((a, b) => a + b) /
            dimActivities.length;

    return DimensionScore(
      dimension: dim,
      score: double.parse(score.toStringAsFixed(1)),
      activityCount: dimActivities.length,
      avgIntensity: double.parse(avgIntensity.toStringAsFixed(1)),
      trend: trend,
      trendDelta: trendDelta,
    );
  }

  // -----------------------------------------------------------------------
  // 3. Imbalance Detector
  // -----------------------------------------------------------------------

  /// Detect imbalances across all dimensions.
  List<ImbalanceAlert> detectImbalances({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final scores = <BalanceDimension, DimensionScore>{};
    for (final dim in BalanceDimension.values) {
      scores[dim] = scoreDimension(dim, now: reference);
    }

    final alerts = <ImbalanceAlert>[];
    int alertId = 0;

    final scoreValues = scores.values.map((s) => s.score).toList();
    final mean = scoreValues.isEmpty
        ? 0.0
        : scoreValues.reduce((a, b) => a + b) / scoreValues.length;

    // Neglected: score < threshold.
    for (final entry in scores.entries) {
      if (entry.value.score < neglectThreshold && entry.value.score >= 0) {
        alerts.add(ImbalanceAlert(
          id: 'alert-${alertId++}',
          type: ImbalanceType.neglected,
          affectedDimensions: [entry.key],
          severity: (neglectThreshold - entry.value.score)
              .clamp(0.0, 100.0),
          description:
              '${entry.key.label} is severely neglected (score: ${entry.value.score})',
          suggestion:
              'Schedule at least 2-3 ${entry.key.label.toLowerCase()} activities this week',
          createdAt: reference,
        ));
      }
    }

    // Overinvested: score > threshold AND average of others < 40.
    for (final entry in scores.entries) {
      if (entry.value.score > overinvestThreshold) {
        final otherScores = scores.entries
            .where((e) => e.key != entry.key)
            .map((e) => e.value.score);
        final otherAvg = otherScores.isEmpty
            ? 0.0
            : otherScores.reduce((a, b) => a + b) / otherScores.length;
        if (otherAvg < 40) {
          alerts.add(ImbalanceAlert(
            id: 'alert-${alertId++}',
            type: ImbalanceType.overinvested,
            affectedDimensions: [entry.key],
            severity:
                ((entry.value.score - overinvestThreshold) + (40 - otherAvg))
                    .clamp(0.0, 100.0),
            description:
                '${entry.key.label} dominates your attention while other areas suffer',
            suggestion:
                'Redistribute some ${entry.key.label.toLowerCase()} time to neglected dimensions',
            createdAt: reference,
          ));
        }
      }
    }

    // Stagnant: no activity in stagnantDays.
    for (final dim in BalanceDimension.values) {
      final dimActs = getActivitiesByDimension(dim);
      if (dimActs.isEmpty) continue; // already caught by neglected
      final latest = dimActs
          .map((a) => a.timestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final daysSince = reference.difference(latest).inDays;
      if (daysSince >= stagnantDays) {
        alerts.add(ImbalanceAlert(
          id: 'alert-${alertId++}',
          type: ImbalanceType.stagnant,
          affectedDimensions: [dim],
          severity: ((daysSince - stagnantDays) * 3.0).clamp(0.0, 100.0),
          description:
              '${dim.label} has been inactive for $daysSince days',
          suggestion:
              'Even a small ${dim.label.toLowerCase()} activity can restart momentum',
          createdAt: reference,
        ));
      }
    }

    // Declining: negative trend detected.
    for (final entry in scores.entries) {
      if (entry.value.trend == BalanceTrend.declining) {
        alerts.add(ImbalanceAlert(
          id: 'alert-${alertId++}',
          type: ImbalanceType.declining,
          affectedDimensions: [entry.key],
          severity: (entry.value.trendDelta.abs() * 10).clamp(0.0, 100.0),
          description:
              '${entry.key.label} activity is trending downward',
          suggestion:
              'Recommit to ${entry.key.label.toLowerCase()} before the habit breaks',
          createdAt: reference,
        ));
      }
    }

    // Volatile: high standard deviation in recent scores across snapshots.
    if (_snapshots.length >= 3) {
      for (final dim in BalanceDimension.values) {
        final recentScores = _snapshots
            .reversed
            .take(5)
            .map((s) => s.dimensionScores[dim]?.score ?? 0.0)
            .toList();
        if (recentScores.length >= 3) {
          final m = recentScores.reduce((a, b) => a + b) / recentScores.length;
          final variance = recentScores
                  .map((s) => (s - m) * (s - m))
                  .reduce((a, b) => a + b) /
              recentScores.length;
          final stdDev = sqrt(variance);
          if (stdDev > 25) {
            alerts.add(ImbalanceAlert(
              id: 'alert-${alertId++}',
              type: ImbalanceType.volatile,
              affectedDimensions: [dim],
              severity: ((stdDev - 25) * 3).clamp(0.0, 100.0),
              description:
                  '${dim.label} scores are highly volatile (σ=${stdDev.toStringAsFixed(1)})',
              suggestion:
                  'Establish a consistent routine for ${dim.label.toLowerCase()}',
              createdAt: reference,
            ));
          }
        }
      }
    }

    return alerts;
  }

  // -----------------------------------------------------------------------
  // 4. Trend Analyzer
  // -----------------------------------------------------------------------

  /// Analyze overall balance trend from historical snapshots using linear
  /// regression on composite scores.
  BalanceTrend analyzeTrend() {
    if (_snapshots.length < 3) return BalanceTrend.stable;

    final recent = _snapshots.length > 10
        ? _snapshots.sublist(_snapshots.length - 10)
        : _snapshots;

    // Simple linear regression: y = composite score, x = index.
    final n = recent.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = recent[i].compositeScore;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    // Check for volatility: residual variance.
    final meanY = sumY / n;
    final residuals = <double>[];
    for (int i = 0; i < n; i++) {
      final predicted = (sumY / n) + slope * (i - sumX / n);
      residuals.add((recent[i].compositeScore - predicted).abs());
    }
    final avgResidual =
        residuals.reduce((a, b) => a + b) / residuals.length;

    if (avgResidual > 15) return BalanceTrend.volatile;
    if (slope > 1.5) return BalanceTrend.improving;
    if (slope < -1.5) return BalanceTrend.declining;
    return BalanceTrend.stable;
  }

  // -----------------------------------------------------------------------
  // 5. Recommendation Engine
  // -----------------------------------------------------------------------

  /// Generate prioritized rebalancing recommendations.
  List<RebalanceRecommendation> generateRecommendations({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final scores = <BalanceDimension, DimensionScore>{};
    for (final dim in BalanceDimension.values) {
      scores[dim] = scoreDimension(dim, now: reference);
    }

    final recs = <RebalanceRecommendation>[];
    int recId = 0;

    final allScores = scores.values.map((s) => s.score).toList();
    final avgScore = allScores.isEmpty
        ? 0.0
        : allScores.reduce((a, b) => a + b) / allScores.length;
    final targetScore = (avgScore + 20).clamp(40.0, 80.0);

    for (final entry in scores.entries) {
      final dim = entry.key;
      final ds = entry.value;

      RecommendationPriority? priority;
      String action = '';
      String reasoning = '';

      if (ds.score < neglectThreshold) {
        priority = RecommendationPriority.critical;
        action = _neglectAction(dim);
        reasoning =
            '${dim.label} score is critically low at ${ds.score}. Immediate attention needed.';
      } else if (ds.trend == BalanceTrend.declining) {
        priority = RecommendationPriority.high;
        action =
            'Reverse the decline in ${dim.label.toLowerCase()} by scheduling regular activities';
        reasoning =
            '${dim.label} is trending downward. Intervene before it becomes critical.';
      } else if (ds.score < avgScore - 15) {
        priority = RecommendationPriority.medium;
        action =
            'Boost ${dim.label.toLowerCase()} to match your average engagement level';
        reasoning =
            '${dim.label} is significantly below your personal average.';
      } else if (ds.score < 50) {
        priority = RecommendationPriority.low;
        action =
            'Maintain and gradually increase ${dim.label.toLowerCase()} activities';
        reasoning =
            '${dim.label} could use a bit more attention for balanced growth.';
      }

      if (priority != null) {
        recs.add(RebalanceRecommendation(
          id: 'rec-${recId++}',
          priority: priority,
          targetDimension: dim,
          currentScore: ds.score,
          targetScore: targetScore,
          action: action,
          reasoning: reasoning,
          estimatedImpact: (targetScore - ds.score).clamp(0.0, 100.0),
        ));
      }
    }

    // Sort by priority.
    recs.sort((a, b) => a.priority.sortOrder.compareTo(b.priority.sortOrder));
    return recs;
  }

  String _neglectAction(BalanceDimension dim) {
    switch (dim) {
      case BalanceDimension.health:
        return 'Schedule a health check-up and start a daily wellness routine';
      case BalanceDimension.work:
        return 'Set clear work goals and dedicate focused time blocks';
      case BalanceDimension.social:
        return 'Reach out to a friend or join a community event this week';
      case BalanceDimension.learning:
        return 'Start a short online course or read for 20 minutes daily';
      case BalanceDimension.finance:
        return 'Review your budget and set one financial goal for this month';
      case BalanceDimension.fitness:
        return 'Begin with 15-minute walks and gradually increase intensity';
      case BalanceDimension.creativity:
        return 'Try a creative activity: sketch, write, play music, or cook something new';
      case BalanceDimension.mindfulness:
        return 'Start with 5-minute guided meditation sessions daily';
    }
  }

  // -----------------------------------------------------------------------
  // 6. Snapshot Generator
  // -----------------------------------------------------------------------

  /// Take a full balance snapshot.
  BalanceSnapshot takeSnapshot({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final scores = <BalanceDimension, DimensionScore>{};
    for (final dim in BalanceDimension.values) {
      scores[dim] = scoreDimension(dim, now: reference);
    }

    final scoreValues = scores.values.map((s) => s.score).toList();
    final composite = scoreValues.isEmpty
        ? 0.0
        : scoreValues.reduce((a, b) => a + b) / scoreValues.length;
    final gini = giniCoefficient(scoreValues);
    final alerts = detectImbalances(now: reference);
    final trend = analyzeTrend();

    final snapshot = BalanceSnapshot(
      id: 'snap-${_snapshots.length}',
      timestamp: reference,
      dimensionScores: scores,
      compositeScore: double.parse(composite.toStringAsFixed(1)),
      giniCoefficient: double.parse(gini.toStringAsFixed(3)),
      alerts: alerts,
      trend: trend,
    );

    _snapshots.add(snapshot);
    return snapshot;
  }

  // -----------------------------------------------------------------------
  // 7. Insight Generator
  // -----------------------------------------------------------------------

  /// Generate human-readable insights from current state.
  List<String> generateInsights({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final scores = <BalanceDimension, DimensionScore>{};
    for (final dim in BalanceDimension.values) {
      scores[dim] = scoreDimension(dim, now: reference);
    }

    final insights = <String>[];
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.score.compareTo(a.value.score));

    if (sorted.isNotEmpty) {
      final strongest = sorted.first;
      insights.add(
          '💪 Your strongest dimension is ${strongest.key.emoji} ${strongest.key.label} '
          'with a score of ${strongest.value.score}');
    }

    if (sorted.length > 1) {
      final weakest = sorted.last;
      insights.add(
          '⚠️ Your weakest dimension is ${weakest.key.emoji} ${weakest.key.label} '
          'with a score of ${weakest.value.score}');
    }

    if (sorted.length >= 2) {
      final gap = sorted.first.value.score - sorted.last.value.score;
      if (gap > 50) {
        insights.add(
            '🔴 Large balance gap of ${gap.toStringAsFixed(0)} points between '
            '${sorted.first.key.label} and ${sorted.last.key.label}');
      } else if (gap > 25) {
        insights.add(
            '🟡 Moderate balance gap of ${gap.toStringAsFixed(0)} points — '
            'some rebalancing would help');
      } else {
        insights.add(
            '🟢 Your life dimensions are fairly well-balanced '
            '(gap: ${gap.toStringAsFixed(0)} points)');
      }
    }

    // Trajectory.
    final trend = analyzeTrend();
    insights.add(
        '📈 Overall balance trajectory: ${trend.label} ${trend.arrow}');

    // Activity distribution.
    final totalActivities = _activities.length;
    if (totalActivities > 0) {
      final activeDims =
          BalanceDimension.values.where((d) => scores[d]!.activityCount > 0);
      insights.add(
          '📊 $totalActivities activities across ${activeDims.length}/${BalanceDimension.values.length} dimensions');
    }

    // Gini insight.
    final scoreValues = scores.values.map((s) => s.score).toList();
    final gini = giniCoefficient(scoreValues);
    if (gini > 0.4) {
      insights.add(
          '⚖️ High inequality (Gini: ${gini.toStringAsFixed(2)}) — '
          'attention is concentrated in few areas');
    } else if (gini < 0.15) {
      insights.add(
          '⚖️ Excellent equality (Gini: ${gini.toStringAsFixed(2)}) — '
          'attention is well-distributed');
    }

    return insights;
  }

  // -----------------------------------------------------------------------
  // Utilities
  // -----------------------------------------------------------------------

  /// Compute Gini coefficient for a list of values. 0 = perfect equality,
  /// 1 = perfect inequality.
  double giniCoefficient(List<double> values) {
    if (values.isEmpty || values.length == 1) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final n = sorted.length;
    final mean =
        sorted.reduce((a, b) => a + b) / n;
    if (mean == 0) return 0.0;

    double sumDiff = 0;
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        sumDiff += (sorted[i] - sorted[j]).abs();
      }
    }
    return sumDiff / (2 * n * n * mean);
  }

  /// Generate realistic demo data spanning 60 days.
  void generateDemoData({DateTime? now}) {
    final reference = now ?? DateTime.now();

    // Patterns: work is overinvested, creativity and mindfulness are neglected.
    final patterns = <BalanceDimension, _DemoPattern>{
      BalanceDimension.health: _DemoPattern(freq: 0.6, intensity: 55, variance: 15),
      BalanceDimension.work: _DemoPattern(freq: 0.9, intensity: 80, variance: 10),
      BalanceDimension.social: _DemoPattern(freq: 0.4, intensity: 50, variance: 20),
      BalanceDimension.learning: _DemoPattern(freq: 0.5, intensity: 60, variance: 15),
      BalanceDimension.finance: _DemoPattern(freq: 0.3, intensity: 45, variance: 10),
      BalanceDimension.fitness: _DemoPattern(freq: 0.55, intensity: 65, variance: 20),
      BalanceDimension.creativity: _DemoPattern(freq: 0.1, intensity: 30, variance: 10),
      BalanceDimension.mindfulness: _DemoPattern(freq: 0.08, intensity: 25, variance: 10),
    };

    int actId = 0;
    for (int day = 60; day >= 0; day--) {
      final date = reference.subtract(Duration(days: day));
      for (final dim in BalanceDimension.values) {
        final pattern = patterns[dim]!;
        if (_random.nextDouble() < pattern.freq) {
          final intensity = (pattern.intensity +
                  (_random.nextDouble() - 0.5) * 2 * pattern.variance)
              .clamp(5.0, 100.0);
          final duration = (20 + _random.nextInt(60));
          addActivity(DimensionActivity(
            id: 'demo-${actId++}',
            dimension: dim,
            intensity: double.parse(intensity.toStringAsFixed(1)),
            durationMinutes: duration,
            timestamp: date.add(Duration(
                hours: 8 + _random.nextInt(12),
                minutes: _random.nextInt(60))),
            notes: '${dim.label} activity',
          ));
        }
      }
    }
  }

  /// Generate a full balance report.
  BalanceReport generateReport({DateTime? now}) {
    final snapshot = takeSnapshot(now: now);
    final recs = generateRecommendations(now: now);
    final insights = generateInsights(now: now);

    String health;
    if (snapshot.compositeScore >= 70) {
      health = 'Excellent';
    } else if (snapshot.compositeScore >= 50) {
      health = 'Good';
    } else if (snapshot.compositeScore >= 30) {
      health = 'Needs Attention';
    } else {
      health = 'Critical';
    }

    return BalanceReport(
      snapshots: [snapshot],
      recommendations: recs,
      insights: insights,
      overallHealth: health,
    );
  }

  /// Clear all data.
  void reset() {
    _activities.clear();
    _snapshots.clear();
  }
}

/// Internal helper for demo data generation patterns.
class _DemoPattern {
  final double freq;
  final double intensity;
  final double variance;

  _DemoPattern({
    required this.freq,
    required this.intensity,
    required this.variance,
  });
}
