import 'dart:math';

/// Focus Entropy Engine — autonomous focus fragmentation detector.
///
/// Uses Shannon entropy to measure how scattered attention is across life
/// domains. Tracks context-switching costs, identifies deep-work blocks,
/// scores flow-state quality, and forecasts focus trajectory.
///
/// 7 engines:
/// 1. **Activity Logger** — records focus sessions with domain, time, duration
/// 2. **Entropy Calculator** — Shannon H = −Σ p log₂ p on domain distribution
/// 3. **Context Switch Counter** — domain transitions & switching-cost estimate
/// 4. **Deep Work Detector** — uninterrupted ≥25 min single-domain sessions
/// 5. **Flow State Scorer** — composite 0-100 from deep-work ratio & entropy
/// 6. **Focus Forecast** — linear-regression trend on daily entropy
/// 7. **Insight Generator** — ranked actionable recommendations

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Overall focus-quality grade derived from entropy level.
enum FocusGrade {
  laser,
  focused,
  balanced,
  scattered,
  chaotic;

  String get label {
    switch (this) {
      case FocusGrade.laser:
        return 'Laser';
      case FocusGrade.focused:
        return 'Focused';
      case FocusGrade.balanced:
        return 'Balanced';
      case FocusGrade.scattered:
        return 'Scattered';
      case FocusGrade.chaotic:
        return 'Chaotic';
    }
  }

  String get emoji {
    switch (this) {
      case FocusGrade.laser:
        return '🎯';
      case FocusGrade.focused:
        return '🔬';
      case FocusGrade.balanced:
        return '⚖️';
      case FocusGrade.scattered:
        return '🌀';
      case FocusGrade.chaotic:
        return '🌪️';
    }
  }

  String get description {
    switch (this) {
      case FocusGrade.laser:
        return 'Extraordinary single-domain immersion';
      case FocusGrade.focused:
        return 'Strong focus with minimal distraction';
      case FocusGrade.balanced:
        return 'Healthy mix of depth and breadth';
      case FocusGrade.scattered:
        return 'Attention spread too thin';
      case FocusGrade.chaotic:
        return 'Severe fragmentation — deep work impossible';
    }
  }
}

/// Direction of the entropy trend.
enum FocusTrend {
  improving,
  stable,
  degrading;

  String get label {
    switch (this) {
      case FocusTrend.improving:
        return 'Improving';
      case FocusTrend.stable:
        return 'Stable';
      case FocusTrend.degrading:
        return 'Degrading';
    }
  }

  String get emoji {
    switch (this) {
      case FocusTrend.improving:
        return '📈';
      case FocusTrend.stable:
        return '➡️';
      case FocusTrend.degrading:
        return '📉';
    }
  }
}

/// Category of a generated insight.
enum FocusInsightCategory {
  discovery,
  warning,
  recommendation,
  pattern,
  forecast;

  String get label {
    switch (this) {
      case FocusInsightCategory.discovery:
        return 'Discovery';
      case FocusInsightCategory.warning:
        return 'Warning';
      case FocusInsightCategory.recommendation:
        return 'Recommendation';
      case FocusInsightCategory.pattern:
        return 'Pattern';
      case FocusInsightCategory.forecast:
        return 'Forecast';
    }
  }

  String get emoji {
    switch (this) {
      case FocusInsightCategory.discovery:
        return '🔬';
      case FocusInsightCategory.warning:
        return '⚠️';
      case FocusInsightCategory.recommendation:
        return '💡';
      case FocusInsightCategory.pattern:
        return '🔄';
      case FocusInsightCategory.forecast:
        return '🔮';
    }
  }
}

/// Priority of a generated insight.
enum FocusInsightPriority {
  critical,
  high,
  medium,
  low;

  String get label {
    switch (this) {
      case FocusInsightPriority.critical:
        return 'Critical';
      case FocusInsightPriority.high:
        return 'High';
      case FocusInsightPriority.medium:
        return 'Medium';
      case FocusInsightPriority.low:
        return 'Low';
    }
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// A single recorded focus session.
class FocusSession {
  final String domain;
  final DateTime startTime;
  final int durationMinutes;
  final String? notes;

  const FocusSession({
    required this.domain,
    required this.startTime,
    required this.durationMinutes,
    this.notes,
  });
}

/// Time distribution for a single domain.
class DomainDistribution {
  final String domain;
  final int totalMinutes;
  final double percentage;
  final int sessionCount;

  const DomainDistribution({
    required this.domain,
    required this.totalMinutes,
    required this.percentage,
    required this.sessionCount,
  });
}

/// A detected context switch between domains.
class ContextSwitch {
  final String fromDomain;
  final String toDomain;
  final DateTime timestamp;
  final double estimatedCostMinutes;

  const ContextSwitch({
    required this.fromDomain,
    required this.toDomain,
    required this.timestamp,
    this.estimatedCostMinutes = 23.0,
  });
}

/// An identified deep-work block (≥25 min uninterrupted single-domain).
class DeepWorkBlock {
  final String domain;
  final DateTime startTime;
  final int durationMinutes;
  final int qualityScore;

  const DeepWorkBlock({
    required this.domain,
    required this.startTime,
    required this.durationMinutes,
    required this.qualityScore,
  });
}

/// Daily entropy snapshot.
class EntropySnapshot {
  final DateTime date;
  final double entropy;
  final int domainCount;
  final String interpretation;

  const EntropySnapshot({
    required this.date,
    required this.entropy,
    required this.domainCount,
    required this.interpretation,
  });
}

/// Forecast of focus trajectory.
class FocusForecast {
  final FocusTrend trend;
  final double projectedEntropy;
  final int? daysUntilCritical;
  final double confidence;

  const FocusForecast({
    required this.trend,
    required this.projectedEntropy,
    this.daysUntilCritical,
    required this.confidence,
  });
}

/// A single generated insight.
class FocusInsight {
  final FocusInsightCategory category;
  final FocusInsightPriority priority;
  final String title;
  final String description;

  const FocusInsight({
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
  });

  String get emoji => category.emoji;
}

/// Full analysis report.
class FocusEntropyReport {
  final int flowScore;
  final FocusGrade focusGrade;
  final double currentEntropy;
  final double weeklyEntropy;
  final int totalDeepWorkMinutes;
  final int totalContextSwitches;
  final double averageSwitchCost;
  final double deepWorkRatio;
  final List<DomainDistribution> domainDistributions;
  final List<DeepWorkBlock> deepWorkBlocks;
  final List<EntropySnapshot> entropyHistory;
  final FocusForecast forecast;
  final List<FocusInsight> insights;

  const FocusEntropyReport({
    required this.flowScore,
    required this.focusGrade,
    required this.currentEntropy,
    required this.weeklyEntropy,
    required this.totalDeepWorkMinutes,
    required this.totalContextSwitches,
    required this.averageSwitchCost,
    required this.deepWorkRatio,
    required this.domainDistributions,
    required this.deepWorkBlocks,
    required this.entropyHistory,
    required this.forecast,
    required this.insights,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Focus Entropy Engine service — autonomous focus fragmentation detector.
class FocusEntropyEngineService {
  final List<FocusSession> _sessions = [];

  /// Read-only access to recorded sessions.
  List<FocusSession> get sessions => List.unmodifiable(_sessions);

  // -------------------------------------------------------------------------
  // Engine 1 — Activity Logger
  // -------------------------------------------------------------------------

  /// Add a focus session.
  void addSession(FocusSession session) {
    _sessions.add(session);
  }

  /// Load realistic demo data spanning 14 days across 7 domains.
  void loadSampleData() {
    _sessions.clear();
    final rng = Random(42);
    final domains = [
      'Coding',
      'Email',
      'Meetings',
      'Research',
      'Design',
      'Admin',
      'Learning',
    ];
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 13));

    for (int d = 0; d < 14; d++) {
      final day = startDate.add(Duration(days: d));
      // Trend: earlier days more scattered, later days more focused.
      final focusFactor = d / 13.0; // 0.0 → 1.0
      final sessionsToday = 4 + rng.nextInt(6); // 4-9 sessions

      // Weight coding higher on later days for improving trend.
      final weights = <String, double>{};
      for (final domain in domains) {
        if (domain == 'Coding') {
          weights[domain] = 1.0 + focusFactor * 3.0;
        } else if (domain == 'Research') {
          weights[domain] = 0.8 + focusFactor * 1.5;
        } else if (domain == 'Email' || domain == 'Admin') {
          weights[domain] = 1.5 - focusFactor * 0.8;
        } else {
          weights[domain] = 1.0;
        }
      }

      final totalWeight = weights.values.fold(0.0, (a, b) => a + b);

      int minuteOfDay = 480 + rng.nextInt(60); // Start 8:00-9:00
      for (int s = 0; s < sessionsToday; s++) {
        // Weighted random domain selection.
        double roll = rng.nextDouble() * totalWeight;
        String domain = domains.last;
        for (final entry in weights.entries) {
          roll -= entry.value;
          if (roll <= 0) {
            domain = entry.key;
            break;
          }
        }

        // Duration: longer for focused days, shorter for scattered.
        final baseDuration = (15 + focusFactor * 30 + rng.nextInt(40)).round();
        final duration = baseDuration.clamp(10, 120);

        _sessions.add(FocusSession(
          domain: domain,
          startTime: DateTime(day.year, day.month, day.day,
              minuteOfDay ~/ 60, minuteOfDay % 60),
          durationMinutes: duration,
        ));

        minuteOfDay += duration + 5 + rng.nextInt(20); // gap
      }
    }
  }

  // -------------------------------------------------------------------------
  // Engine 2 — Entropy Calculator
  // -------------------------------------------------------------------------

  /// Compute Shannon entropy for a set of sessions.
  ///
  /// Returns 0.0 when all time is in one domain, log₂(n) when perfectly
  /// uniform across *n* domains.
  static double computeEntropy(List<FocusSession> sessions) {
    if (sessions.isEmpty) return 0.0;

    final domainMinutes = <String, int>{};
    for (final s in sessions) {
      domainMinutes[s.domain] =
          (domainMinutes[s.domain] ?? 0) + s.durationMinutes;
    }

    final totalMinutes =
        domainMinutes.values.fold(0, (a, b) => a + b);
    if (totalMinutes == 0) return 0.0;

    double h = 0.0;
    for (final minutes in domainMinutes.values) {
      if (minutes == 0) continue;
      final p = minutes / totalMinutes;
      h -= p * (log(p) / ln2);
    }
    return h;
  }

  /// Group sessions by calendar date.
  Map<DateTime, List<FocusSession>> _groupByDate() {
    final map = <DateTime, List<FocusSession>>{};
    for (final s in _sessions) {
      final key =
          DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  /// Build daily entropy history.
  List<EntropySnapshot> _buildEntropyHistory() {
    final grouped = _groupByDate();
    final dates = grouped.keys.toList()..sort();
    return dates.map((date) {
      final daySessions = grouped[date]!;
      final h = computeEntropy(daySessions);
      final domainCount =
          daySessions.map((s) => s.domain).toSet().length;
      return EntropySnapshot(
        date: date,
        entropy: h,
        domainCount: domainCount,
        interpretation: _interpretEntropy(h, domainCount),
      );
    }).toList();
  }

  static String _interpretEntropy(double h, int domainCount) {
    if (domainCount <= 1) return 'Single-domain immersion';
    if (h < 1.0) return 'Highly focused';
    if (h < 1.8) return 'Moderate focus';
    if (h < 2.3) return 'Scattered attention';
    return 'Chaotic fragmentation';
  }

  // -------------------------------------------------------------------------
  // Engine 3 — Context Switch Counter
  // -------------------------------------------------------------------------

  /// Detect context switches (domain transitions sorted by time).
  List<ContextSwitch> _detectContextSwitches() {
    if (_sessions.length < 2) return [];

    final sorted = List<FocusSession>.from(_sessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final switches = <ContextSwitch>[];
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].domain != sorted[i - 1].domain) {
        switches.add(ContextSwitch(
          fromDomain: sorted[i - 1].domain,
          toDomain: sorted[i].domain,
          timestamp: sorted[i].startTime,
        ));
      }
    }
    return switches;
  }

  // -------------------------------------------------------------------------
  // Engine 4 — Deep Work Detector
  // -------------------------------------------------------------------------

  /// Identify deep-work blocks: uninterrupted ≥25 min single-domain sessions.
  List<DeepWorkBlock> _detectDeepWork() {
    return _sessions
        .where((s) => s.durationMinutes >= 25)
        .map((s) {
      // Quality based on duration: 25 min = 50, 60 min = 80, 120 min = 100.
      final q = ((s.durationMinutes - 25) / 95.0 * 50 + 50).round().clamp(0, 100);
      return DeepWorkBlock(
        domain: s.domain,
        startTime: s.startTime,
        durationMinutes: s.durationMinutes,
        qualityScore: q,
      );
    }).toList();
  }

  // -------------------------------------------------------------------------
  // Engine 5 — Flow State Scorer
  // -------------------------------------------------------------------------

  /// Compute composite flow score 0-100.
  ///
  /// Components (equal weight):
  /// - Deep-work ratio (% of total time in deep-work sessions)
  /// - Inverse entropy (lower entropy → higher score)
  /// - Low switch rate (fewer switches per hour → higher score)
  static int computeFlowScore({
    required double deepWorkRatio,
    required double entropy,
    required int domainCount,
    required double switchesPerHour,
  }) {
    // Deep-work component: 0-100.
    final dwComponent = (deepWorkRatio * 100).clamp(0.0, 100.0);

    // Entropy component: max entropy for domainCount domains = log2(n).
    final maxEntropy =
        domainCount > 1 ? log(domainCount) / ln2 : 1.0;
    final entropyComponent =
        ((1.0 - (entropy / maxEntropy).clamp(0.0, 1.0)) * 100);

    // Switch-rate component: 0 switches/hr = 100, ≥6/hr = 0.
    final switchComponent = ((1.0 - (switchesPerHour / 6.0).clamp(0.0, 1.0)) * 100);

    return ((dwComponent + entropyComponent + switchComponent) / 3.0)
        .round()
        .clamp(0, 100);
  }

  /// Classify entropy into a focus grade.
  static FocusGrade classifyGrade(double entropy, int domainCount) {
    if (domainCount <= 1) return FocusGrade.laser;
    if (entropy < 0.8) return FocusGrade.laser;
    if (entropy < 1.4) return FocusGrade.focused;
    if (entropy < 2.0) return FocusGrade.balanced;
    if (entropy < 2.5) return FocusGrade.scattered;
    return FocusGrade.chaotic;
  }

  // -------------------------------------------------------------------------
  // Engine 6 — Focus Forecast
  // -------------------------------------------------------------------------

  /// Simple linear regression on daily entropy values.
  FocusForecast _buildForecast(List<EntropySnapshot> history) {
    if (history.length < 3) {
      return const FocusForecast(
        trend: FocusTrend.stable,
        projectedEntropy: 0.0,
        confidence: 0.0,
      );
    }

    // Use last 7 days or all available, whichever is smaller.
    final recent = history.length > 7
        ? history.sublist(history.length - 7)
        : history;

    // x = index, y = entropy.
    final n = recent.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += recent[i].entropy;
      sumXY += i * recent[i].entropy;
      sumX2 += i * i;
    }
    final denom = (n * sumX2 - sumX * sumX);
    if (denom.abs() < 1e-10) {
      return FocusForecast(
        trend: FocusTrend.stable,
        projectedEntropy: sumY / n,
        confidence: 0.5,
      );
    }

    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;

    // Project 7 days ahead.
    final projected = intercept + slope * (n + 6);

    // R² for confidence.
    final meanY = sumY / n;
    double ssTot = 0, ssRes = 0;
    for (int i = 0; i < n; i++) {
      ssTot += (recent[i].entropy - meanY) * (recent[i].entropy - meanY);
      final predicted = intercept + slope * i;
      ssRes +=
          (recent[i].entropy - predicted) * (recent[i].entropy - predicted);
    }
    final r2 = ssTot > 0 ? (1.0 - ssRes / ssTot).clamp(0.0, 1.0) : 0.0;

    FocusTrend trend;
    if (slope < -0.05) {
      trend = FocusTrend.improving; // entropy decreasing = focus improving
    } else if (slope > 0.05) {
      trend = FocusTrend.degrading;
    } else {
      trend = FocusTrend.stable;
    }

    // Days until entropy hits 2.5 (chaotic threshold).
    int? daysUntilCritical;
    if (trend == FocusTrend.degrading && slope > 0) {
      final currentEntropy = recent.last.entropy;
      if (currentEntropy < 2.5) {
        daysUntilCritical = ((2.5 - currentEntropy) / slope).ceil();
      }
    }

    return FocusForecast(
      trend: trend,
      projectedEntropy: projected.clamp(0.0, 10.0),
      daysUntilCritical: daysUntilCritical,
      confidence: r2,
    );
  }

  // -------------------------------------------------------------------------
  // Engine 7 — Insight Generator
  // -------------------------------------------------------------------------

  List<FocusInsight> _generateInsights({
    required double entropy,
    required double weeklyEntropy,
    required double deepWorkRatio,
    required int contextSwitches,
    required List<DomainDistribution> distributions,
    required FocusForecast forecast,
    required int totalMinutes,
  }) {
    final insights = <FocusInsight>[];

    // Discovery: dominant domain.
    if (distributions.isNotEmpty) {
      final top = distributions.first;
      insights.add(FocusInsight(
        category: FocusInsightCategory.discovery,
        priority: FocusInsightPriority.medium,
        title: 'Primary domain: ${top.domain}',
        description:
            '${top.percentage.toStringAsFixed(1)}% of your focus time '
            '(${top.totalMinutes} min) goes to ${top.domain}.',
      ));
    }

    // Warning: high entropy.
    if (entropy > 2.3) {
      insights.add(const FocusInsight(
        category: FocusInsightCategory.warning,
        priority: FocusInsightPriority.critical,
        title: 'Chaotic fragmentation detected',
        description:
            'Your attention is spread across too many domains. '
            'Consider blocking dedicated focus time for your top 2 domains.',
      ));
    } else if (entropy > 1.8) {
      insights.add(const FocusInsight(
        category: FocusInsightCategory.warning,
        priority: FocusInsightPriority.high,
        title: 'Attention is scattered',
        description:
            'You\'re switching between many domains frequently. '
            'Try theme days or time-blocking to reduce fragmentation.',
      ));
    }

    // Recommendation: low deep-work ratio.
    if (deepWorkRatio < 0.3 && totalMinutes > 60) {
      insights.add(const FocusInsight(
        category: FocusInsightCategory.recommendation,
        priority: FocusInsightPriority.high,
        title: 'Increase deep-work sessions',
        description:
            'Less than 30% of your time is in deep-work blocks (≥25 min). '
            'Aim for at least 2 uninterrupted 45-min sessions daily.',
      ));
    }

    // Recommendation: high switch rate.
    if (contextSwitches > 0 && totalMinutes > 0) {
      final switchesPerHour = contextSwitches / (totalMinutes / 60.0);
      if (switchesPerHour > 4) {
        insights.add(FocusInsight(
          category: FocusInsightCategory.recommendation,
          priority: FocusInsightPriority.high,
          title: 'Reduce context switching',
          description:
              'You\'re switching domains ${switchesPerHour.toStringAsFixed(1)}×/hr. '
              'Each switch costs ~23 min of recovery. Batch similar tasks together.',
        ));
      }
    }

    // Pattern: deep work in specific domain.
    if (distributions.length >= 2) {
      final sorted = List<DomainDistribution>.from(distributions)
        ..sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));
      if (sorted[0].percentage > 40) {
        insights.add(FocusInsight(
          category: FocusInsightCategory.pattern,
          priority: FocusInsightPriority.medium,
          title: '${sorted[0].domain} dominates your schedule',
          description:
              'Consider if ${sorted[0].domain} truly deserves '
              '${sorted[0].percentage.toStringAsFixed(0)}% of your time, '
              'or if other domains are being neglected.',
        ));
      }
    }

    // Pattern: entropy improving.
    if (forecast.trend == FocusTrend.improving) {
      insights.add(const FocusInsight(
        category: FocusInsightCategory.pattern,
        priority: FocusInsightPriority.low,
        title: 'Focus is improving 📈',
        description:
            'Your entropy trend is decreasing — you\'re becoming more focused '
            'over time. Keep it up!',
      ));
    }

    // Forecast: degrading.
    if (forecast.trend == FocusTrend.degrading) {
      insights.add(FocusInsight(
        category: FocusInsightCategory.forecast,
        priority: FocusInsightPriority.high,
        title: 'Focus may deteriorate',
        description:
            'At the current rate, entropy will reach '
            '${forecast.projectedEntropy.toStringAsFixed(2)} in 7 days.'
            '${forecast.daysUntilCritical != null ? ' Critical threshold in ~${forecast.daysUntilCritical} days.' : ''}',
      ));
    }

    // Forecast: stable.
    if (forecast.trend == FocusTrend.stable && entropy < 1.8) {
      insights.add(const FocusInsight(
        category: FocusInsightCategory.forecast,
        priority: FocusInsightPriority.low,
        title: 'Focus is stable and healthy',
        description:
            'Your attention distribution is consistent. '
            'Small experiments with deeper focus blocks could push you further.',
      ));
    }

    // Discovery: unused potential.
    if (deepWorkRatio > 0.5) {
      insights.add(const FocusInsight(
        category: FocusInsightCategory.discovery,
        priority: FocusInsightPriority.low,
        title: 'Deep work champion 🏆',
        description:
            'Over 50% of your time is in deep-work blocks. '
            'This is exceptional — most people average 20-30%.',
      ));
    }

    return insights;
  }

  // -------------------------------------------------------------------------
  // Report generation
  // -------------------------------------------------------------------------

  /// Generate the full analysis report.
  FocusEntropyReport generateReport() {
    if (_sessions.isEmpty) {
      return const FocusEntropyReport(
        flowScore: 0,
        focusGrade: FocusGrade.chaotic,
        currentEntropy: 0.0,
        weeklyEntropy: 0.0,
        totalDeepWorkMinutes: 0,
        totalContextSwitches: 0,
        averageSwitchCost: 23.0,
        deepWorkRatio: 0.0,
        domainDistributions: [],
        deepWorkBlocks: [],
        entropyHistory: [],
        forecast: FocusForecast(
          trend: FocusTrend.stable,
          projectedEntropy: 0.0,
          confidence: 0.0,
        ),
        insights: [],
      );
    }

    // Domain distributions.
    final domainMinutes = <String, int>{};
    final domainCounts = <String, int>{};
    int totalMinutes = 0;
    for (final s in _sessions) {
      domainMinutes[s.domain] =
          (domainMinutes[s.domain] ?? 0) + s.durationMinutes;
      domainCounts[s.domain] = (domainCounts[s.domain] ?? 0) + 1;
      totalMinutes += s.durationMinutes;
    }

    final distributions = domainMinutes.entries.map((e) {
      return DomainDistribution(
        domain: e.key,
        totalMinutes: e.value,
        percentage:
            totalMinutes > 0 ? (e.value / totalMinutes * 100) : 0.0,
        sessionCount: domainCounts[e.key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

    // Entropy.
    final entropy = computeEntropy(_sessions);
    final domainCount = domainMinutes.keys.length;

    // Entropy history.
    final entropyHistory = _buildEntropyHistory();
    final weeklyEntropy = entropyHistory.length >= 7
        ? entropyHistory
                .sublist(entropyHistory.length - 7)
                .map((s) => s.entropy)
                .fold(0.0, (a, b) => a + b) /
            7
        : entropy;

    // Today's entropy (last day).
    final currentEntropy =
        entropyHistory.isNotEmpty ? entropyHistory.last.entropy : entropy;

    // Context switches.
    final switches = _detectContextSwitches();
    final avgSwitchCost = switches.isEmpty
        ? 23.0
        : switches.map((s) => s.estimatedCostMinutes).fold(0.0, (a, b) => a + b) /
            switches.length;

    // Deep work.
    final deepWorkBlocks = _detectDeepWork();
    final deepWorkMinutes = deepWorkBlocks.fold(
        0, (sum, b) => sum + b.durationMinutes);
    final deepWorkRatio =
        totalMinutes > 0 ? deepWorkMinutes / totalMinutes : 0.0;

    // Flow score.
    final totalHours = totalMinutes / 60.0;
    final switchesPerHour =
        totalHours > 0 ? switches.length / totalHours : 0.0;
    final flowScore = computeFlowScore(
      deepWorkRatio: deepWorkRatio,
      entropy: currentEntropy,
      domainCount: domainCount,
      switchesPerHour: switchesPerHour,
    );

    final grade = classifyGrade(currentEntropy, domainCount);

    // Forecast.
    final forecast = _buildForecast(entropyHistory);

    // Insights.
    final insights = _generateInsights(
      entropy: currentEntropy,
      weeklyEntropy: weeklyEntropy,
      deepWorkRatio: deepWorkRatio,
      contextSwitches: switches.length,
      distributions: distributions,
      forecast: forecast,
      totalMinutes: totalMinutes,
    );

    return FocusEntropyReport(
      flowScore: flowScore,
      focusGrade: grade,
      currentEntropy: currentEntropy,
      weeklyEntropy: weeklyEntropy,
      totalDeepWorkMinutes: deepWorkMinutes,
      totalContextSwitches: switches.length,
      averageSwitchCost: avgSwitchCost,
      deepWorkRatio: deepWorkRatio,
      domainDistributions: distributions,
      deepWorkBlocks: deepWorkBlocks,
      entropyHistory: entropyHistory,
      forecast: forecast,
      insights: insights,
    );
  }
}
