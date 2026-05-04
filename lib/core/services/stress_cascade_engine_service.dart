import 'dart:math';

/// Stress Cascade Engine — autonomous stress propagation and resilience analyzer.
///
/// Models how stress in one life domain cascades to others, tracks resilience
/// buffers, detects tipping points, and forecasts recovery trajectories.
///
/// 7 engines:
/// 1. **Stress Source Tracker** — logs stressors with severity and domain
/// 2. **Cascade Simulator** — models inter-domain stress propagation
/// 3. **Resilience Scorer** — measures coping capacity via recovery rates
/// 4. **Tipping Point Detector** — identifies approaching breakdown thresholds
/// 5. **Buffer Analyzer** — tracks stress buffers and depletion rates
/// 6. **Recovery Forecaster** — predicts time to recovery per domain
/// 7. **Insight Generator** — ranked actionable recommendations

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Life domain where stress originates or propagates to.
enum StressDomain {
  work,
  health,
  social,
  financial,
  environmental,
  existential;

  String get label {
    switch (this) {
      case StressDomain.work:
        return 'Work';
      case StressDomain.health:
        return 'Health';
      case StressDomain.social:
        return 'Social';
      case StressDomain.financial:
        return 'Financial';
      case StressDomain.environmental:
        return 'Environmental';
      case StressDomain.existential:
        return 'Existential';
    }
  }

  String get emoji {
    switch (this) {
      case StressDomain.work:
        return '💼';
      case StressDomain.health:
        return '🏥';
      case StressDomain.social:
        return '👥';
      case StressDomain.financial:
        return '💰';
      case StressDomain.environmental:
        return '🌍';
      case StressDomain.existential:
        return '🧠';
    }
  }

  int get colorHex {
    switch (this) {
      case StressDomain.work:
        return 0xFFE53935;
      case StressDomain.health:
        return 0xFF43A047;
      case StressDomain.social:
        return 0xFF1E88E5;
      case StressDomain.financial:
        return 0xFFFDD835;
      case StressDomain.environmental:
        return 0xFF8D6E63;
      case StressDomain.existential:
        return 0xFF8E24AA;
    }
  }
}

/// Severity of a stress event.
enum StressSeverity {
  minimal,
  mild,
  moderate,
  severe,
  extreme;

  String get label {
    switch (this) {
      case StressSeverity.minimal:
        return 'Minimal';
      case StressSeverity.mild:
        return 'Mild';
      case StressSeverity.moderate:
        return 'Moderate';
      case StressSeverity.severe:
        return 'Severe';
      case StressSeverity.extreme:
        return 'Extreme';
    }
  }

  String get emoji {
    switch (this) {
      case StressSeverity.minimal:
        return '🟢';
      case StressSeverity.mild:
        return '🟡';
      case StressSeverity.moderate:
        return '🟠';
      case StressSeverity.severe:
        return '🔴';
      case StressSeverity.extreme:
        return '💥';
    }
  }

  int get numericValue {
    switch (this) {
      case StressSeverity.minimal:
        return 1;
      case StressSeverity.mild:
        return 2;
      case StressSeverity.moderate:
        return 3;
      case StressSeverity.severe:
        return 4;
      case StressSeverity.extreme:
        return 5;
    }
  }
}

/// Phase of the overall stress cascade.
enum CascadePhase {
  dormant,
  building,
  spreading,
  peaking,
  recovering;

  String get label {
    switch (this) {
      case CascadePhase.dormant:
        return 'Dormant';
      case CascadePhase.building:
        return 'Building';
      case CascadePhase.spreading:
        return 'Spreading';
      case CascadePhase.peaking:
        return 'Peaking';
      case CascadePhase.recovering:
        return 'Recovering';
    }
  }

  String get emoji {
    switch (this) {
      case CascadePhase.dormant:
        return '😌';
      case CascadePhase.building:
        return '⚡';
      case CascadePhase.spreading:
        return '🔥';
      case CascadePhase.peaking:
        return '🌋';
      case CascadePhase.recovering:
        return '🌱';
    }
  }

  String get description {
    switch (this) {
      case CascadePhase.dormant:
        return 'Stress contained — no active cascades';
      case CascadePhase.building:
        return 'Stress accumulating in isolated domains';
      case CascadePhase.spreading:
        return 'Stress propagating across multiple domains';
      case CascadePhase.peaking:
        return 'Maximum cascade activity — intervention needed';
      case CascadePhase.recovering:
        return 'Stress levels declining — recovery in progress';
    }
  }
}

/// Resilience tier based on composite resilience score.
enum ResilienceTier {
  antifragile,
  resilient,
  adequate,
  fragile,
  brittle;

  String get label {
    switch (this) {
      case ResilienceTier.antifragile:
        return 'Antifragile';
      case ResilienceTier.resilient:
        return 'Resilient';
      case ResilienceTier.adequate:
        return 'Adequate';
      case ResilienceTier.fragile:
        return 'Fragile';
      case ResilienceTier.brittle:
        return 'Brittle';
    }
  }

  String get emoji {
    switch (this) {
      case ResilienceTier.antifragile:
        return '💎';
      case ResilienceTier.resilient:
        return '🛡️';
      case ResilienceTier.adequate:
        return '⚖️';
      case ResilienceTier.fragile:
        return '🥀';
      case ResilienceTier.brittle:
        return '💔';
    }
  }

  String get description {
    switch (this) {
      case ResilienceTier.antifragile:
        return 'Grows stronger under stress';
      case ResilienceTier.resilient:
        return 'Recovers quickly from adversity';
      case ResilienceTier.adequate:
        return 'Handles moderate stress acceptably';
      case ResilienceTier.fragile:
        return 'Easily overwhelmed by stress';
      case ResilienceTier.brittle:
        return 'Near breaking point — urgent intervention needed';
    }
  }
}

/// Category of a generated insight.
enum CascadeInsightCategory {
  discovery,
  warning,
  recommendation,
  pattern,
  forecast;

  String get label {
    switch (this) {
      case CascadeInsightCategory.discovery:
        return 'Discovery';
      case CascadeInsightCategory.warning:
        return 'Warning';
      case CascadeInsightCategory.recommendation:
        return 'Recommendation';
      case CascadeInsightCategory.pattern:
        return 'Pattern';
      case CascadeInsightCategory.forecast:
        return 'Forecast';
    }
  }

  String get emoji {
    switch (this) {
      case CascadeInsightCategory.discovery:
        return '🔬';
      case CascadeInsightCategory.warning:
        return '⚠️';
      case CascadeInsightCategory.recommendation:
        return '💡';
      case CascadeInsightCategory.pattern:
        return '🔄';
      case CascadeInsightCategory.forecast:
        return '🔮';
    }
  }
}

/// Priority of a generated insight.
enum CascadeInsightPriority {
  critical,
  high,
  medium,
  low;

  String get label {
    switch (this) {
      case CascadeInsightPriority.critical:
        return 'Critical';
      case CascadeInsightPriority.high:
        return 'High';
      case CascadeInsightPriority.medium:
        return 'Medium';
      case CascadeInsightPriority.low:
        return 'Low';
    }
  }
}

/// Category of a stress buffer.
enum BufferCategory {
  exercise,
  sleep,
  social,
  nature,
  creative,
  mindfulness;

  String get label {
    switch (this) {
      case BufferCategory.exercise:
        return 'Exercise';
      case BufferCategory.sleep:
        return 'Sleep';
      case BufferCategory.social:
        return 'Social Support';
      case BufferCategory.nature:
        return 'Nature';
      case BufferCategory.creative:
        return 'Creative Outlet';
      case BufferCategory.mindfulness:
        return 'Mindfulness';
    }
  }

  String get emoji {
    switch (this) {
      case BufferCategory.exercise:
        return '🏃';
      case BufferCategory.sleep:
        return '😴';
      case BufferCategory.social:
        return '🤗';
      case BufferCategory.nature:
        return '🌿';
      case BufferCategory.creative:
        return '🎨';
      case BufferCategory.mindfulness:
        return '🧘';
    }
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// A single recorded stress event.
class StressEvent {
  final StressDomain domain;
  final StressSeverity severity;
  final DateTime timestamp;
  final String description;
  final String? triggerActivity;

  const StressEvent({
    required this.domain,
    required this.severity,
    required this.timestamp,
    required this.description,
    this.triggerActivity,
  });
}

/// Stress profile for a single life domain.
class DomainStressProfile {
  final StressDomain domain;
  final int currentLevel;
  final int eventCount;
  final double averageSeverity;
  final StressSeverity peakSeverity;
  final double recoveryRatePerDay;

  const DomainStressProfile({
    required this.domain,
    required this.currentLevel,
    required this.eventCount,
    required this.averageSeverity,
    required this.peakSeverity,
    required this.recoveryRatePerDay,
  });
}

/// An edge in the stress cascade graph showing propagation between domains.
class CascadeEdge {
  final StressDomain fromDomain;
  final StressDomain toDomain;
  final double propagationStrength;
  final double delayHours;
  final int evidenceCount;

  const CascadeEdge({
    required this.fromDomain,
    required this.toDomain,
    required this.propagationStrength,
    required this.delayHours,
    required this.evidenceCount,
  });
}

/// A stress buffer that absorbs or mitigates stress impact.
class StressBuffer {
  final String name;
  final BufferCategory category;
  final int currentLevel;
  final double depletionRate;
  final DateTime? lastReplenished;

  const StressBuffer({
    required this.name,
    required this.category,
    required this.currentLevel,
    required this.depletionRate,
    this.lastReplenished,
  });
}

/// Alert when a domain approaches its tipping point.
class TippingPointAlert {
  final StressDomain domain;
  final int currentLevel;
  final int threshold;
  final int daysUntilBreach;
  final double confidence;

  const TippingPointAlert({
    required this.domain,
    required this.currentLevel,
    required this.threshold,
    required this.daysUntilBreach,
    required this.confidence,
  });
}

/// Forecast of recovery timeline for a stressed domain.
class RecoveryForecast {
  final StressDomain domain;
  final int currentLevel;
  final int projectedDays;
  final double confidence;
  final List<String> recommendedActions;

  const RecoveryForecast({
    required this.domain,
    required this.currentLevel,
    required this.projectedDays,
    required this.confidence,
    required this.recommendedActions,
  });
}

/// A single generated insight.
class CascadeInsight {
  final CascadeInsightCategory category;
  final CascadeInsightPriority priority;
  final String title;
  final String description;

  const CascadeInsight({
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
  });

  String get emoji => category.emoji;
}

/// Full stress cascade analysis report.
class StressCascadeReport {
  final int compositeStressScore;
  final CascadePhase cascadePhase;
  final ResilienceTier resilienceTier;
  final List<DomainStressProfile> domainProfiles;
  final List<CascadeEdge> cascadeEdges;
  final List<StressBuffer> bufferStatus;
  final List<TippingPointAlert> tippingPoints;
  final List<RecoveryForecast> recoveryForecasts;
  final List<CascadeInsight> insights;

  const StressCascadeReport({
    required this.compositeStressScore,
    required this.cascadePhase,
    required this.resilienceTier,
    required this.domainProfiles,
    required this.cascadeEdges,
    required this.bufferStatus,
    required this.tippingPoints,
    required this.recoveryForecasts,
    required this.insights,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stress Cascade Engine service — autonomous stress propagation analyzer.
class StressCascadeEngineService {
  final List<StressEvent> _events = [];

  /// Read-only access to recorded events.
  List<StressEvent> get events => List.unmodifiable(_events);

  // -------------------------------------------------------------------------
  // Engine 1 — Stress Source Tracker
  // -------------------------------------------------------------------------

  /// Add a stress event.
  void addEvent(StressEvent event) {
    _events.add(event);
  }

  /// Load realistic demo data spanning 30 days with cascading patterns.
  void loadSampleData() {
    _events.clear();
    final rng = Random(42);
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 29));

    // Descriptions by domain for realistic data.
    final domainDescriptions = <StressDomain, List<String>>{
      StressDomain.work: [
        'Deadline pressure',
        'Difficult meeting',
        'Project overload',
        'Performance review anxiety',
        'Conflict with colleague',
        'Unclear expectations',
      ],
      StressDomain.health: [
        'Poor sleep quality',
        'Headache',
        'Skipped workout',
        'Unhealthy eating',
        'Back pain',
        'Fatigue',
      ],
      StressDomain.social: [
        'Argument with friend',
        'Social obligation overload',
        'Loneliness',
        'Family tension',
        'Missed social event',
        'Comparison on social media',
      ],
      StressDomain.financial: [
        'Unexpected bill',
        'Market downturn',
        'Budget overrun',
        'Debt worry',
        'Large purchase anxiety',
        'Income uncertainty',
      ],
      StressDomain.environmental: [
        'Noisy neighbors',
        'Cluttered workspace',
        'Weather affecting mood',
        'Long commute',
        'Air quality concern',
        'Uncomfortable temperature',
      ],
      StressDomain.existential: [
        'Purpose questioning',
        'Future uncertainty',
        'Mortality awareness',
        'Meaning crisis',
        'Value conflict',
        'Decision paralysis',
      ],
    };

    // Create cascading stress patterns:
    // Week 1-2: Work stress builds
    // Week 2-3: Work → Health cascade (sleep disruption)
    // Week 3-4: Health → Social cascade (withdrawal)
    // Week 4: Financial stress spike adds to cascade

    for (int d = 0; d < 30; d++) {
      final day = startDate.add(Duration(days: d));
      final phase = d / 30.0;

      // Work stress: high throughout with a peak mid-period.
      final workProb = 0.3 + 0.4 * sin(pi * phase * 2).abs();
      final workSeverityBase = (phase < 0.5)
          ? 2.0 + phase * 4.0
          : 4.0 - (phase - 0.5) * 3.0;

      // Health stress: delayed cascade from work.
      final healthProb = (d > 7) ? 0.2 + 0.3 * (d - 7) / 22.0 : 0.1;
      final healthSeverityBase = (d > 7) ? 1.5 + (d - 7) / 22.0 * 2.5 : 1.0;

      // Social stress: further delayed cascade.
      final socialProb = (d > 14) ? 0.15 + 0.25 * (d - 14) / 15.0 : 0.1;

      // Financial stress: sudden spike in last week.
      final financialProb = (d > 22) ? 0.3 + 0.2 * (d - 22) / 7.0 : 0.08;

      // Environmental: low-level background.
      final envProb = 0.1 + rng.nextDouble() * 0.1;

      // Existential: triggered by sustained multi-domain stress.
      final existProb = (d > 20) ? 0.1 + 0.2 * (d - 20) / 9.0 : 0.05;

      final domainProbs = <StressDomain, double>{
        StressDomain.work: workProb,
        StressDomain.health: healthProb,
        StressDomain.social: socialProb,
        StressDomain.financial: financialProb,
        StressDomain.environmental: envProb,
        StressDomain.existential: existProb,
      };

      final domainSeverityBases = <StressDomain, double>{
        StressDomain.work: workSeverityBase,
        StressDomain.health: healthSeverityBase,
        StressDomain.social: 1.5 + phase * 2.0,
        StressDomain.financial: (d > 22) ? 3.0 + (d - 22) / 7.0 : 1.5,
        StressDomain.environmental: 1.5,
        StressDomain.existential: 2.0 + phase * 1.5,
      };

      for (final domain in StressDomain.values) {
        if (rng.nextDouble() < domainProbs[domain]!) {
          final severityVal =
              (domainSeverityBases[domain]! + rng.nextDouble() * 1.5 - 0.5)
                  .round()
                  .clamp(1, 5);
          final severity = StressSeverity.values[severityVal - 1];
          final descriptions = domainDescriptions[domain]!;
          final desc = descriptions[rng.nextInt(descriptions.length)];

          final hour = 8 + rng.nextInt(14);
          final minute = rng.nextInt(60);

          _events.add(StressEvent(
            domain: domain,
            severity: severity,
            timestamp: DateTime(day.year, day.month, day.day, hour, minute),
            description: desc,
          ));
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // Engine 2 — Cascade Simulator
  // -------------------------------------------------------------------------

  /// Detect stress propagation edges between domains.
  ///
  /// Looks for temporal co-occurrence: if events in domain A are frequently
  /// followed by events in domain B within 72 hours, a cascade edge is
  /// inferred. Propagation strength = co-occurrence count / source events.
  List<CascadeEdge> _computeCascadeEdges() {
    if (_events.length < 2) return [];

    final sorted = List<StressEvent>.from(_events)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final edgeCounts = <String, int>{};
    final edgeDelays = <String, List<double>>{};
    final domainCounts = <StressDomain, int>{};

    for (final e in sorted) {
      domainCounts[e.domain] = (domainCounts[e.domain] ?? 0) + 1;
    }

    // Check each pair of events for temporal co-occurrence.
    for (int i = 0; i < sorted.length; i++) {
      for (int j = i + 1; j < sorted.length; j++) {
        if (sorted[j].domain == sorted[i].domain) continue;
        final hoursDiff = sorted[j]
            .timestamp
            .difference(sorted[i].timestamp)
            .inHours
            .abs()
            .toDouble();
        if (hoursDiff > 72) break; // Beyond 72h window.

        final key = '${sorted[i].domain.index}->${sorted[j].domain.index}';
        edgeCounts[key] = (edgeCounts[key] ?? 0) + 1;
        edgeDelays.putIfAbsent(key, () => []).add(hoursDiff);
      }
    }

    final edges = <CascadeEdge>[];
    for (final entry in edgeCounts.entries) {
      final parts = entry.key.split('->');
      final fromIdx = int.parse(parts[0]);
      final toIdx = int.parse(parts[1]);
      final fromDomain = StressDomain.values[fromIdx];
      final toDomain = StressDomain.values[toIdx];
      final sourceCount = domainCounts[fromDomain] ?? 1;
      final strength = (entry.value / sourceCount).clamp(0.0, 1.0);

      if (strength < 0.1) continue; // Filter weak edges.

      final delays = edgeDelays[entry.key]!;
      final avgDelay = delays.reduce((a, b) => a + b) / delays.length;

      edges.add(CascadeEdge(
        fromDomain: fromDomain,
        toDomain: toDomain,
        propagationStrength: strength,
        delayHours: avgDelay,
        evidenceCount: entry.value,
      ));
    }

    edges.sort((a, b) => b.propagationStrength.compareTo(a.propagationStrength));
    return edges;
  }

  // -------------------------------------------------------------------------
  // Engine 3 — Resilience Scorer
  // -------------------------------------------------------------------------

  /// Map a numeric resilience score (0-100) to a tier.
  static ResilienceTier computeResilienceTier(int score) {
    if (score >= 85) return ResilienceTier.antifragile;
    if (score >= 70) return ResilienceTier.resilient;
    if (score >= 50) return ResilienceTier.adequate;
    if (score >= 30) return ResilienceTier.fragile;
    return ResilienceTier.brittle;
  }

  /// Compute per-domain stress profiles including recovery rate.
  List<DomainStressProfile> _computeDomainProfiles() {
    final profiles = <DomainStressProfile>[];

    for (final domain in StressDomain.values) {
      final domainEvents =
          _events.where((e) => e.domain == domain).toList();

      if (domainEvents.isEmpty) {
        profiles.add(DomainStressProfile(
          domain: domain,
          currentLevel: 0,
          eventCount: 0,
          averageSeverity: 0.0,
          peakSeverity: StressSeverity.minimal,
          recoveryRatePerDay: 10.0,
        ));
        continue;
      }

      domainEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final avgSeverity = domainEvents
              .map((e) => e.severity.numericValue)
              .fold(0, (a, b) => a + b) /
          domainEvents.length;

      final peakSeverityVal = domainEvents
          .map((e) => e.severity.numericValue)
          .reduce((a, b) => a > b ? a : b);
      final peakSeverity = StressSeverity.values[peakSeverityVal - 1];

      // Current level: recency-weighted average of last 7 days.
      final now = DateTime.now();
      final recentEvents = domainEvents
          .where((e) =>
              now.difference(e.timestamp).inDays < 7)
          .toList();

      int currentLevel;
      if (recentEvents.isEmpty) {
        currentLevel = 0;
      } else {
        double weightedSum = 0;
        double weightTotal = 0;
        for (final e in recentEvents) {
          final daysAgo =
              now.difference(e.timestamp).inHours / 24.0;
          final weight = exp(-daysAgo / 3.0); // Exponential decay.
          weightedSum += e.severity.numericValue * weight;
          weightTotal += weight;
        }
        currentLevel =
            ((weightedSum / weightTotal) * 20).round().clamp(0, 100);
      }

      // Recovery rate: measure how quickly severity drops after peaks.
      double recoveryRate = 10.0; // Default.
      if (domainEvents.length >= 3) {
        // Find peak-to-trough transitions.
        final dailyAvg = <int, double>{};
        for (final e in domainEvents) {
          final dayKey = e.timestamp.difference(domainEvents.first.timestamp).inDays;
          dailyAvg.putIfAbsent(dayKey, () => 0.0);
          dailyAvg[dayKey] = dailyAvg[dayKey]! + e.severity.numericValue;
        }
        // Simple: recovery = inverse of avg severity trend.
        recoveryRate = (10.0 - avgSeverity * 1.5).clamp(1.0, 15.0);
      }

      profiles.add(DomainStressProfile(
        domain: domain,
        currentLevel: currentLevel,
        eventCount: domainEvents.length,
        averageSeverity: avgSeverity,
        peakSeverity: peakSeverity,
        recoveryRatePerDay: recoveryRate,
      ));
    }

    return profiles;
  }

  // -------------------------------------------------------------------------
  // Engine 4 — Tipping Point Detector
  // -------------------------------------------------------------------------

  /// Detect domains approaching tipping points (stress level projected to
  /// cross 80 within 14 days via linear regression on daily averages).
  List<TippingPointAlert> _detectTippingPoints(
      List<DomainStressProfile> profiles) {
    final alerts = <TippingPointAlert>[];
    final now = DateTime.now();
    const threshold = 80;

    for (final domain in StressDomain.values) {
      final domainEvents =
          _events.where((e) => e.domain == domain).toList();
      if (domainEvents.length < 3) continue;

      domainEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Build daily severity averages for the last 14 days.
      final dailyScores = <int, List<int>>{};
      for (final e in domainEvents) {
        final daysAgo = now.difference(e.timestamp).inDays;
        if (daysAgo > 14) continue;
        dailyScores.putIfAbsent(daysAgo, () => []).add(e.severity.numericValue);
      }

      if (dailyScores.length < 2) continue;

      // Linear regression: x = days from now (negative = past), y = severity.
      final points = <List<double>>[];
      for (final entry in dailyScores.entries) {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        points.add([-entry.key.toDouble(), avg]);
      }

      final n = points.length;
      final sumX = points.map((p) => p[0]).fold(0.0, (a, b) => a + b);
      final sumY = points.map((p) => p[1]).fold(0.0, (a, b) => a + b);
      final sumXY =
          points.map((p) => p[0] * p[1]).fold(0.0, (a, b) => a + b);
      final sumX2 =
          points.map((p) => p[0] * p[0]).fold(0.0, (a, b) => a + b);

      final denom = n * sumX2 - sumX * sumX;
      if (denom.abs() < 1e-10) continue;

      final slope = (n * sumXY - sumX * sumY) / denom;
      final intercept = (sumY - slope * sumX) / n;

      if (slope <= 0) continue; // Not rising.

      // Project stress level to the 0-100 scale.
      final currentProjected = (intercept * 20).clamp(0, 100).toInt();
      final thresholdSeverity = threshold / 20.0;

      // Days until severity reaches threshold level.
      final daysUntil =
          ((thresholdSeverity - intercept) / slope).ceil();

      if (daysUntil > 0 && daysUntil <= 14) {
        final confidence = (slope / 0.5).clamp(0.3, 0.95);
        alerts.add(TippingPointAlert(
          domain: domain,
          currentLevel: currentProjected,
          threshold: threshold,
          daysUntilBreach: daysUntil,
          confidence: confidence,
        ));
      }
    }

    alerts.sort((a, b) => a.daysUntilBreach.compareTo(b.daysUntilBreach));
    return alerts;
  }

  // -------------------------------------------------------------------------
  // Engine 5 — Buffer Analyzer
  // -------------------------------------------------------------------------

  /// Analyze stress buffer levels based on event patterns.
  List<StressBuffer> _analyzeBuffers() {
    final now = DateTime.now();
    final recentEvents = _events
        .where((e) => now.difference(e.timestamp).inDays < 7)
        .toList();

    final highStressCount =
        recentEvents.where((e) => e.severity.numericValue >= 4).length;

    // Buffer depletion increases with high-stress events.
    final depletionFactor = (highStressCount / 5.0).clamp(0.0, 1.0);

    final bufferDefs = <BufferCategory, String>{
      BufferCategory.exercise: 'Physical Activity',
      BufferCategory.sleep: 'Quality Sleep',
      BufferCategory.social: 'Social Connection',
      BufferCategory.nature: 'Nature Exposure',
      BufferCategory.creative: 'Creative Expression',
      BufferCategory.mindfulness: 'Mindfulness Practice',
    };

    final rng = Random(42 + _events.length);
    final buffers = <StressBuffer>[];

    for (final entry in bufferDefs.entries) {
      // Base level affected by overall stress and domain-specific impact.
      final baseLevel = (70 - depletionFactor * 40 + rng.nextInt(20))
          .round()
          .clamp(5, 95);

      // Depletion rate: higher when more stress events.
      final rate = (depletionFactor * 8 + rng.nextDouble() * 3)
          .clamp(0.5, 12.0);

      // Last replenished: more recent if lower stress.
      final daysAgo = (1 + depletionFactor * 5 + rng.nextInt(3)).round();

      buffers.add(StressBuffer(
        name: entry.value,
        category: entry.key,
        currentLevel: baseLevel,
        depletionRate: rate,
        lastReplenished: now.subtract(Duration(days: daysAgo)),
      ));
    }

    return buffers;
  }

  // -------------------------------------------------------------------------
  // Engine 6 — Recovery Forecaster
  // -------------------------------------------------------------------------

  /// Forecast recovery timeline for each stressed domain.
  List<RecoveryForecast> _forecastRecovery(
      List<DomainStressProfile> profiles) {
    final forecasts = <RecoveryForecast>[];
    const recoveryTarget = 30;

    final domainActions = <StressDomain, List<String>>{
      StressDomain.work: [
        'Set firm boundaries on work hours',
        'Delegate non-essential tasks',
        'Take a mental health day',
      ],
      StressDomain.health: [
        'Prioritize 7-8 hours of sleep',
        'Schedule a health checkup',
        'Resume regular exercise',
      ],
      StressDomain.social: [
        'Reach out to a trusted friend',
        'Reduce social media time',
        'Schedule a low-key social activity',
      ],
      StressDomain.financial: [
        'Review and adjust budget',
        'Build an emergency fund plan',
        'Seek financial counseling',
      ],
      StressDomain.environmental: [
        'Declutter your workspace',
        'Invest in noise-canceling headphones',
        'Spend 30 minutes in nature daily',
      ],
      StressDomain.existential: [
        'Journal about values and priorities',
        'Practice mindfulness meditation',
        'Talk to a therapist or mentor',
      ],
    };

    for (final profile in profiles) {
      if (profile.currentLevel < 40) continue;

      // Estimate days to reach recoveryTarget.
      final gap = profile.currentLevel - recoveryTarget;
      final daysNeeded =
          (gap / profile.recoveryRatePerDay).ceil().clamp(1, 90);

      // Confidence based on recovery rate stability.
      final confidence =
          (profile.recoveryRatePerDay / 10.0).clamp(0.3, 0.9);

      forecasts.add(RecoveryForecast(
        domain: profile.domain,
        currentLevel: profile.currentLevel,
        projectedDays: daysNeeded,
        confidence: confidence,
        recommendedActions: domainActions[profile.domain] ?? [],
      ));
    }

    forecasts.sort((a, b) => b.currentLevel.compareTo(a.currentLevel));
    return forecasts;
  }

  // -------------------------------------------------------------------------
  // Engine 7 — Insight Generator
  // -------------------------------------------------------------------------

  /// Generate ranked actionable insights from the analysis.
  List<CascadeInsight> _generateInsights({
    required List<DomainStressProfile> profiles,
    required List<CascadeEdge> edges,
    required List<StressBuffer> buffers,
    required List<TippingPointAlert> tippingPoints,
    required int compositeScore,
    required CascadePhase phase,
  }) {
    final insights = <CascadeInsight>[];

    // Cascade propagation insights.
    for (final edge in edges.take(3)) {
      if (edge.propagationStrength > 0.3) {
        insights.add(CascadeInsight(
          category: CascadeInsightCategory.pattern,
          priority: edge.propagationStrength > 0.6
              ? CascadeInsightPriority.high
              : CascadeInsightPriority.medium,
          title:
              '${edge.fromDomain.label} → ${edge.toDomain.label} cascade detected',
          description:
              '${edge.fromDomain.label} stress is propagating to ${edge.toDomain.label} '
              'with ${(edge.propagationStrength * 100).round()}% strength '
              '(avg ${edge.delayHours.round()}h delay, ${edge.evidenceCount} occurrences).',
        ));
      }
    }

    // Tipping point warnings.
    for (final tp in tippingPoints) {
      insights.add(CascadeInsight(
        category: CascadeInsightCategory.warning,
        priority: tp.daysUntilBreach <= 3
            ? CascadeInsightPriority.critical
            : tp.daysUntilBreach <= 7
                ? CascadeInsightPriority.high
                : CascadeInsightPriority.medium,
        title:
            '${tp.domain.label} approaching tipping point',
        description:
            '${tp.domain.label} stress projected to breach ${tp.threshold} '
            'in ${tp.daysUntilBreach} days (confidence: ${(tp.confidence * 100).round()}%).',
      ));
    }

    // Buffer depletion insights.
    for (final buffer in buffers) {
      if (buffer.currentLevel < 30) {
        insights.add(CascadeInsight(
          category: CascadeInsightCategory.recommendation,
          priority: buffer.currentLevel < 15
              ? CascadeInsightPriority.high
              : CascadeInsightPriority.medium,
          title: '${buffer.name} buffer depleted',
          description:
              '${buffer.name} is at ${buffer.currentLevel}% — '
              'schedule replenishment to maintain stress resilience.',
        ));
      }
    }

    // High-stress domain insights.
    for (final profile in profiles) {
      if (profile.currentLevel >= 60) {
        insights.add(CascadeInsight(
          category: CascadeInsightCategory.warning,
          priority: profile.currentLevel >= 80
              ? CascadeInsightPriority.critical
              : CascadeInsightPriority.high,
          title: '${profile.domain.label} stress at critical level',
          description:
              '${profile.domain.label} stress is at ${profile.currentLevel}/100 '
              'with ${profile.eventCount} events. Peak severity: '
              '${profile.peakSeverity.label}.',
        ));
      }
    }

    // Phase-specific insights.
    if (phase == CascadePhase.spreading || phase == CascadePhase.peaking) {
      final activeDomains = profiles
          .where((p) => p.currentLevel >= 40)
          .map((p) => p.domain.label)
          .toList();
      insights.add(CascadeInsight(
        category: CascadeInsightCategory.forecast,
        priority: CascadeInsightPriority.high,
        title: 'Multi-domain stress cascade active',
        description:
            'Stress is cascading across ${activeDomains.length} domains '
            '(${activeDomains.join(", ")}). Prioritize breaking the '
            'weakest cascade link to halt propagation.',
      ));
    }

    // Overall score insight.
    if (compositeScore >= 70) {
      insights.add(CascadeInsight(
        category: CascadeInsightCategory.recommendation,
        priority: CascadeInsightPriority.critical,
        title: 'Composite stress dangerously high',
        description:
            'Overall stress score is $compositeScore/100. Consider '
            'immediate stress-reduction actions: cancel non-essential '
            'commitments, engage recovery buffers, seek support.',
      ));
    } else if (compositeScore <= 25) {
      insights.add(CascadeInsight(
        category: CascadeInsightCategory.discovery,
        priority: CascadeInsightPriority.low,
        title: 'Stress levels well-managed',
        description:
            'Composite stress is only $compositeScore/100. Current '
            'coping strategies are working — maintain your routines.',
      ));
    }

    // Resilience recommendation.
    final avgRecovery = profiles.isEmpty
        ? 10.0
        : profiles.map((p) => p.recoveryRatePerDay).reduce((a, b) => a + b) /
            profiles.length;
    if (avgRecovery < 5.0) {
      insights.add(CascadeInsight(
        category: CascadeInsightCategory.recommendation,
        priority: CascadeInsightPriority.high,
        title: 'Recovery capacity is low',
        description:
            'Average recovery rate is ${avgRecovery.toStringAsFixed(1)} '
            'points/day. Invest in recovery buffers (sleep, exercise, '
            'social connection) to rebuild resilience.',
      ));
    }

    // Sort by priority.
    final priorityOrder = {
      CascadeInsightPriority.critical: 0,
      CascadeInsightPriority.high: 1,
      CascadeInsightPriority.medium: 2,
      CascadeInsightPriority.low: 3,
    };
    insights.sort((a, b) =>
        priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!));

    return insights;
  }

  // -------------------------------------------------------------------------
  // Main analysis
  // -------------------------------------------------------------------------

  /// Compute the cascade phase from the composite score and active domains.
  static CascadePhase computeCascadePhase(
      int compositeScore, int activeDomainCount, double trend) {
    if (trend < -2.0 && compositeScore < 60) return CascadePhase.recovering;
    if (compositeScore >= 70 && activeDomainCount >= 4) {
      return CascadePhase.peaking;
    }
    if (compositeScore >= 50 && activeDomainCount >= 3) {
      return CascadePhase.spreading;
    }
    if (compositeScore >= 30) return CascadePhase.building;
    return CascadePhase.dormant;
  }

  /// Run the full stress cascade analysis and return a comprehensive report.
  StressCascadeReport analyze() {
    if (_events.isEmpty) {
      return StressCascadeReport(
        compositeStressScore: 0,
        cascadePhase: CascadePhase.dormant,
        resilienceTier: ResilienceTier.resilient,
        domainProfiles: StressDomain.values
            .map((d) => DomainStressProfile(
                  domain: d,
                  currentLevel: 0,
                  eventCount: 0,
                  averageSeverity: 0.0,
                  peakSeverity: StressSeverity.minimal,
                  recoveryRatePerDay: 10.0,
                ))
            .toList(),
        cascadeEdges: [],
        bufferStatus: [],
        tippingPoints: [],
        recoveryForecasts: [],
        insights: [
          const CascadeInsight(
            category: CascadeInsightCategory.discovery,
            priority: CascadeInsightPriority.low,
            title: 'No stress data recorded',
            description: 'Start logging stress events to enable analysis.',
          ),
        ],
      );
    }

    // Engine 1: Events already tracked.
    // Engine 2: Cascade edges.
    final edges = _computeCascadeEdges();
    // Engine 3: Domain profiles.
    final profiles = _computeDomainProfiles();
    // Engine 4: Tipping points.
    final tippingPoints = _detectTippingPoints(profiles);
    // Engine 5: Buffers.
    final buffers = _analyzeBuffers();
    // Engine 6: Recovery forecasts.
    final recoveryForecasts = _forecastRecovery(profiles);

    // Composite score: weighted average of domain levels.
    final activeDomains =
        profiles.where((p) => p.currentLevel > 0).toList();
    final compositeScore = activeDomains.isEmpty
        ? 0
        : (activeDomains
                    .map((p) => p.currentLevel)
                    .reduce((a, b) => a + b) /
                activeDomains.length)
            .round()
            .clamp(0, 100);

    // Compute trend from recent week.
    final now = DateTime.now();
    final recentEvents = _events
        .where((e) => now.difference(e.timestamp).inDays < 7)
        .toList();
    final olderEvents = _events
        .where((e) {
          final days = now.difference(e.timestamp).inDays;
          return days >= 7 && days < 14;
        })
        .toList();
    final recentAvg = recentEvents.isEmpty
        ? 0.0
        : recentEvents.map((e) => e.severity.numericValue).reduce((a, b) => a + b) /
            recentEvents.length;
    final olderAvg = olderEvents.isEmpty
        ? recentAvg
        : olderEvents.map((e) => e.severity.numericValue).reduce((a, b) => a + b) /
            olderEvents.length;
    final trend = recentAvg - olderAvg;

    final activeDomainCount =
        profiles.where((p) => p.currentLevel >= 40).length;
    final phase = computeCascadePhase(
        compositeScore, activeDomainCount, trend);

    // Resilience: inverse of composite stress + buffer health.
    final avgBufferLevel = buffers.isEmpty
        ? 50
        : buffers.map((b) => b.currentLevel).reduce((a, b) => a + b) ~/
            buffers.length;
    final resilienceScore =
        ((100 - compositeScore) * 0.6 + avgBufferLevel * 0.4)
            .round()
            .clamp(0, 100);
    final resilienceTier = computeResilienceTier(resilienceScore);

    // Engine 7: Insights.
    final insights = _generateInsights(
      profiles: profiles,
      edges: edges,
      buffers: buffers,
      tippingPoints: tippingPoints,
      compositeScore: compositeScore,
      phase: phase,
    );

    return StressCascadeReport(
      compositeStressScore: compositeScore,
      cascadePhase: phase,
      resilienceTier: resilienceTier,
      domainProfiles: profiles,
      cascadeEdges: edges,
      bufferStatus: buffers,
      tippingPoints: tippingPoints,
      recoveryForecasts: recoveryForecasts,
      insights: insights,
    );
  }
}
