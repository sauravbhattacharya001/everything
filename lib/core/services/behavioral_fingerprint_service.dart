import 'dart:convert';
import 'dart:math';

import 'service_persistence.dart';

/// Behavioral Fingerprint Engine — autonomous behavioral signature analysis
/// that creates a multi-dimensional identity fingerprint from daily patterns
/// and detects when the user deviates significantly from their baseline self.
///
/// Core concepts:
/// - **Behavioral Dimensions**: 8 measurable axes (activity timing, task velocity,
///   category preferences, consistency, social engagement, energy curve, completion
///   patterns, exploration vs routine)
/// - **Fingerprint**: a normalized multi-dimensional signature vector built from
///   rolling behavioral data
/// - **Baseline**: the user's stable fingerprint computed from sufficient history
/// - **Deviation Detection**: Mahalanobis-inspired distance from baseline with
///   per-dimension breakdowns
/// - **Identity Phases**: classified behavioral state (authentic/shifting/exploring/
///   disrupted/transformed)
/// - **Change Narratives**: human-readable explanations of what changed and why
///   it might matter

// ---------------------------------------------------------------------------
// Enums & Constants
// ---------------------------------------------------------------------------

/// The 8 behavioral dimensions that form the fingerprint.
enum BehaviorDimension {
  activityTiming('Activity Timing', '⏰',
      'When you tend to be active — early bird vs night owl patterns'),
  taskVelocity('Task Velocity', '⚡',
      'How fast you complete tasks once started'),
  categoryFocus('Category Focus', '🎯',
      'Which life areas you spend most energy on'),
  consistency('Consistency', '📏',
      'How regular and predictable your patterns are'),
  socialEngagement('Social Engagement', '👥',
      'How much you interact with shared/social features'),
  energyCurve('Energy Curve', '🔋',
      'Your productivity distribution across the day'),
  completionStyle('Completion Style', '✅',
      'Whether you finish things in bursts or steadily'),
  explorationRatio('Exploration Ratio', '🧭',
      'How much you try new things vs stick to routines');

  final String label;
  final String emoji;
  final String description;
  const BehaviorDimension(this.label, this.emoji, this.description);
}

/// Identity phase classification based on deviation patterns.
enum IdentityPhase {
  authentic('Authentic', '🟢',
      'Behaving consistently with your established patterns'),
  shifting('Shifting', '🟡',
      'Gradual changes detected — possibly adapting to new circumstances'),
  exploring('Exploring', '🔵',
      'Trying new patterns — high variety, low consistency with baseline'),
  disrupted('Disrupted', '🟠',
      'Significant deviation across multiple dimensions — life event likely'),
  transformed('Transformed', '🟣',
      'Sustained new pattern — your baseline identity may be evolving');

  final String label;
  final String emoji;
  final String description;
  const IdentityPhase(this.label, this.emoji, this.description);
}

/// Deviation severity for a single dimension.
enum DeviationLevel {
  normal('Normal', 0),
  mild('Mild', 1),
  moderate('Moderate', 2),
  significant('Significant', 3),
  extreme('Extreme', 4);

  final String label;
  final int priority;
  const DeviationLevel(this.label, this.priority);
}

/// A single behavioral event recorded from user activity.
class BehaviorEvent {
  final String id;
  final DateTime timestamp;
  final String category;
  final String action; // 'complete', 'start', 'skip', 'view', 'create'
  final double? durationMinutes;
  final Map<String, dynamic> metadata;

  const BehaviorEvent({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.action,
    this.durationMinutes,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ts': timestamp.millisecondsSinceEpoch,
        'cat': category,
        'act': action,
        'dur': durationMinutes,
        'meta': metadata,
      };

  factory BehaviorEvent.fromJson(Map<String, dynamic> json) => BehaviorEvent(
        id: json['id'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
        category: json['cat'] as String,
        action: json['act'] as String,
        durationMinutes: (json['dur'] as num?)?.toDouble(),
        metadata: (json['meta'] as Map<String, dynamic>?) ?? {},
      );
}

/// A snapshot of dimensional values for a single day.
class DailyFingerprint {
  final DateTime date;
  final Map<BehaviorDimension, double> values; // 0.0 – 1.0 per dimension

  const DailyFingerprint({required this.date, required this.values});

  /// Euclidean distance to another fingerprint.
  double distanceTo(DailyFingerprint other) {
    double sum = 0;
    for (final dim in BehaviorDimension.values) {
      final a = values[dim] ?? 0.5;
      final b = other.values[dim] ?? 0.5;
      sum += (a - b) * (a - b);
    }
    return sqrt(sum);
  }

  Map<String, dynamic> toJson() => {
        'date': date.millisecondsSinceEpoch,
        'vals': {
          for (final e in values.entries) e.key.name: e.value,
        },
      };

  factory DailyFingerprint.fromJson(Map<String, dynamic> json) {
    final vals = json['vals'] as Map<String, dynamic>;
    return DailyFingerprint(
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      values: {
        for (final dim in BehaviorDimension.values)
          if (vals.containsKey(dim.name))
            dim: (vals[dim.name] as num).toDouble(),
      },
    );
  }
}

/// The baseline behavioral signature — the user's "normal self."
class BehaviorBaseline {
  final Map<BehaviorDimension, double> means;
  final Map<BehaviorDimension, double> stdDevs;
  final DateTime computedAt;
  final int sampleDays;

  const BehaviorBaseline({
    required this.means,
    required this.stdDevs,
    required this.computedAt,
    required this.sampleDays,
  });

  /// Whether enough data exists for a meaningful baseline.
  bool get isReliable => sampleDays >= 14;

  Map<String, dynamic> toJson() => {
        'means': {for (final e in means.entries) e.key.name: e.value},
        'stds': {for (final e in stdDevs.entries) e.key.name: e.value},
        'at': computedAt.millisecondsSinceEpoch,
        'n': sampleDays,
      };

  factory BehaviorBaseline.fromJson(Map<String, dynamic> json) {
    final m = json['means'] as Map<String, dynamic>;
    final s = json['stds'] as Map<String, dynamic>;
    return BehaviorBaseline(
      means: {
        for (final dim in BehaviorDimension.values)
          if (m.containsKey(dim.name)) dim: (m[dim.name] as num).toDouble(),
      },
      stdDevs: {
        for (final dim in BehaviorDimension.values)
          if (s.containsKey(dim.name)) dim: (s[dim.name] as num).toDouble(),
      },
      computedAt:
          DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
      sampleDays: json['n'] as int,
    );
  }
}

/// Per-dimension deviation result.
class DimensionDeviation {
  final BehaviorDimension dimension;
  final double currentValue;
  final double baselineMean;
  final double baselineStdDev;
  final double zScore;
  final DeviationLevel level;
  final String narrative;

  const DimensionDeviation({
    required this.dimension,
    required this.currentValue,
    required this.baselineMean,
    required this.baselineStdDev,
    required this.zScore,
    required this.level,
    required this.narrative,
  });
}

/// Overall deviation analysis result.
class DeviationReport {
  final DateTime analyzedAt;
  final DailyFingerprint current;
  final BehaviorBaseline baseline;
  final List<DimensionDeviation> deviations;
  final double compositeDistance;
  final IdentityPhase phase;
  final List<String> changeNarratives;
  final double authenticityScore; // 0-100

  const DeviationReport({
    required this.analyzedAt,
    required this.current,
    required this.baseline,
    required this.deviations,
    required this.compositeDistance,
    required this.phase,
    required this.changeNarratives,
    required this.authenticityScore,
  });

  /// Dimensions deviating at moderate or higher.
  List<DimensionDeviation> get significantDeviations =>
      deviations.where((d) => d.level.priority >= 2).toList()
        ..sort((a, b) => b.level.priority.compareTo(a.level.priority));
}

/// Trend of identity stability over time.
class IdentityTrend {
  final List<_TrendPoint> points;
  final String direction; // 'stabilizing', 'destabilizing', 'steady'
  final double volatility;

  const IdentityTrend({
    required this.points,
    required this.direction,
    required this.volatility,
  });
}

class _TrendPoint {
  final DateTime date;
  final double distance;
  final IdentityPhase phase;
  const _TrendPoint(
      {required this.date, required this.distance, required this.phase});

  Map<String, dynamic> toJson() => {
        'date': date.millisecondsSinceEpoch,
        'dist': distance,
        'phase': phase.name,
      };

  factory _TrendPoint.fromJson(Map<String, dynamic> json) => _TrendPoint(
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
        distance: (json['dist'] as num).toDouble(),
        phase: IdentityPhase.values.firstWhere(
          (p) => p.name == json['phase'],
          orElse: () => IdentityPhase.authentic,
        ),
      );
}

// ---------------------------------------------------------------------------
// Main Service
// ---------------------------------------------------------------------------

class BehavioralFingerprintService with ServicePersistence {
  final List<BehaviorEvent> _events = [];
  final List<DailyFingerprint> _fingerprints = [];
  BehaviorBaseline? _baseline;
  final List<_TrendPoint> _trendHistory = [];

  static const int _baselineMinDays = 14;
  static const int _baselineWindowDays = 30;
  static const int _recentWindowDays = 7;

  // -- ServicePersistence ---------------------------------------------------

  @override
  String get storageKey => 'behavioral_fingerprint';

  @override
  Map<String, dynamic> toStorageJson() => {
        'events': _events.map((e) => e.toJson()).toList(),
        'fps': _fingerprints.map((f) => f.toJson()).toList(),
        'baseline': _baseline?.toJson(),
        'trend': _trendHistory.map((t) => t.toJson()).toList(),
      };

  @override
  void fromStorageJson(Map<String, dynamic> json) {
    _events
      ..clear()
      ..addAll(
        ((json['events'] as List?) ?? [])
            .map((e) => BehaviorEvent.fromJson(e as Map<String, dynamic>)),
      );
    _fingerprints
      ..clear()
      ..addAll(
        ((json['fps'] as List?) ?? [])
            .map((f) => DailyFingerprint.fromJson(f as Map<String, dynamic>)),
      );
    if (json['baseline'] != null) {
      _baseline =
          BehaviorBaseline.fromJson(json['baseline'] as Map<String, dynamic>);
    }
    _trendHistory
      ..clear()
      ..addAll(
        ((json['trend'] as List?) ?? [])
            .map((t) => _TrendPoint.fromJson(t as Map<String, dynamic>)),
      );
  }

  // -- Public API -----------------------------------------------------------

  List<BehaviorEvent> get events => List.unmodifiable(_events);
  List<DailyFingerprint> get fingerprints => List.unmodifiable(_fingerprints);
  BehaviorBaseline? get baseline => _baseline;
  int get totalDays => _fingerprints.length;

  /// Record a behavioral event.
  void recordEvent(BehaviorEvent event) {
    _events.add(event);
  }

  /// Record multiple events at once.
  void recordEvents(List<BehaviorEvent> events) {
    _events.addAll(events);
  }

  /// Compute today's fingerprint from recent events.
  DailyFingerprint computeDailyFingerprint({DateTime? date}) {
    final target = _dateOnly(date ?? DateTime.now());
    final dayEvents = _events
        .where((e) => _dateOnly(e.timestamp) == target)
        .toList();

    final values = <BehaviorDimension, double>{};

    // 1. Activity Timing — peak hour normalized (0=midnight, 1=noon-ish)
    values[BehaviorDimension.activityTiming] =
        _computeActivityTiming(dayEvents);

    // 2. Task Velocity — completions per active hour
    values[BehaviorDimension.taskVelocity] =
        _computeTaskVelocity(dayEvents);

    // 3. Category Focus — HHI concentration index
    values[BehaviorDimension.categoryFocus] =
        _computeCategoryFocus(dayEvents);

    // 4. Consistency — similarity to same-weekday average
    values[BehaviorDimension.consistency] =
        _computeConsistency(target, dayEvents);

    // 5. Social Engagement — fraction of social-category events
    values[BehaviorDimension.socialEngagement] =
        _computeSocialEngagement(dayEvents);

    // 6. Energy Curve — morning vs evening activity ratio
    values[BehaviorDimension.energyCurve] =
        _computeEnergyCurve(dayEvents);

    // 7. Completion Style — burst vs steady completion pattern
    values[BehaviorDimension.completionStyle] =
        _computeCompletionStyle(dayEvents);

    // 8. Exploration Ratio — unique new categories / total categories
    values[BehaviorDimension.explorationRatio] =
        _computeExplorationRatio(target, dayEvents);

    final fp = DailyFingerprint(date: target, values: values);

    // Replace existing fingerprint for this date or add new
    _fingerprints.removeWhere((f) => _dateOnly(f.date) == target);
    _fingerprints.add(fp);
    _fingerprints.sort((a, b) => a.date.compareTo(b.date));

    return fp;
  }

  /// Recompute the baseline from the last N days of fingerprints.
  BehaviorBaseline computeBaseline({DateTime? now}) {
    final currentDate = now ?? DateTime.now();
    final cutoff =
        currentDate.subtract(Duration(days: _baselineWindowDays));
    final recent = _fingerprints
        .where((f) => f.date.isAfter(cutoff))
        .toList();

    final means = <BehaviorDimension, double>{};
    final stdDevs = <BehaviorDimension, double>{};

    for (final dim in BehaviorDimension.values) {
      final vals =
          recent.map((f) => f.values[dim] ?? 0.5).toList();
      if (vals.isEmpty) {
        means[dim] = 0.5;
        stdDevs[dim] = 0.1;
        continue;
      }
      final mean = vals.reduce((a, b) => a + b) / vals.length;
      final variance =
          vals.fold(0.0, (sum, v) => sum + (v - mean) * (v - mean)) /
              vals.length;
      means[dim] = mean;
      stdDevs[dim] = sqrt(variance).clamp(0.01, 1.0);
    }

    _baseline = BehaviorBaseline(
      means: means,
      stdDevs: stdDevs,
      computedAt: currentDate,
      sampleDays: recent.length,
    );
    return _baseline!;
  }

  /// Analyze deviation of a fingerprint from baseline.
  DeviationReport analyzeDeviation({DailyFingerprint? fingerprint}) {
    final fp = fingerprint ?? _fingerprints.lastOrNull;
    if (fp == null) {
      throw StateError('No fingerprint available to analyze');
    }

    final bl = _baseline ?? computeBaseline(now: fp.date);

    final deviations = <DimensionDeviation>[];
    double distanceSum = 0;

    for (final dim in BehaviorDimension.values) {
      final current = fp.values[dim] ?? 0.5;
      final mean = bl.means[dim] ?? 0.5;
      final std = bl.stdDevs[dim] ?? 0.1;
      final z = (current - mean).abs() / std;

      final level = _classifyDeviation(z);
      final narrative = _generateNarrative(dim, current, mean, z, level);

      deviations.add(DimensionDeviation(
        dimension: dim,
        currentValue: current,
        baselineMean: mean,
        baselineStdDev: std,
        zScore: z,
        level: level,
        narrative: narrative,
      ));

      distanceSum += z * z;
    }

    final compositeDistance = sqrt(distanceSum / BehaviorDimension.values.length);
    final phase = _classifyPhase(deviations, compositeDistance);
    final narratives = _buildChangeNarratives(deviations, phase);
    final authenticity = _computeAuthenticityScore(compositeDistance);

    // Record trend point
    _trendHistory.add(_TrendPoint(
      date: fp.date,
      distance: compositeDistance,
      phase: phase,
    ));

    return DeviationReport(
      analyzedAt: DateTime.now(),
      current: fp,
      baseline: bl,
      deviations: deviations,
      compositeDistance: compositeDistance,
      phase: phase,
      changeNarratives: narratives,
      authenticityScore: authenticity,
    );
  }

  /// Get the identity stability trend over time.
  IdentityTrend getIdentityTrend({int days = 30}) {
    final cutoff =
        DateTime.now().subtract(Duration(days: days));
    final points = _trendHistory
        .where((t) => t.date.isAfter(cutoff))
        .toList();

    if (points.length < 2) {
      return IdentityTrend(
          points: points, direction: 'steady', volatility: 0);
    }

    // Linear regression on distance values
    final n = points.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += points[i].distance;
      sumXY += i * points[i].distance;
      sumX2 += i * i;
    }
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    // Volatility = std dev of distances
    final meanDist = sumY / n;
    final variance = points.fold(
            0.0, (sum, p) => sum + (p.distance - meanDist) * (p.distance - meanDist)) /
        n;
    final volatility = sqrt(variance);

    final direction = slope > 0.02
        ? 'destabilizing'
        : slope < -0.02
            ? 'stabilizing'
            : 'steady';

    return IdentityTrend(
      points: points,
      direction: direction,
      volatility: volatility,
    );
  }

  /// Get a summary of the user's behavioral signature.
  Map<String, dynamic> getSignatureSummary() {
    if (_baseline == null) {
      return {'status': 'insufficient_data', 'daysRecorded': totalDays};
    }

    final bl = _baseline!;
    final dominantDims = <BehaviorDimension>[];
    final recessiveDims = <BehaviorDimension>[];

    for (final dim in BehaviorDimension.values) {
      final mean = bl.means[dim] ?? 0.5;
      if (mean > 0.65) dominantDims.add(dim);
      if (mean < 0.35) recessiveDims.add(dim);
    }

    // Find the most stable and most variable dimensions
    final sortedByStd = BehaviorDimension.values.toList()
      ..sort((a, b) =>
          (bl.stdDevs[a] ?? 0.1).compareTo(bl.stdDevs[b] ?? 0.1));

    return {
      'status': bl.isReliable ? 'reliable' : 'developing',
      'daysRecorded': totalDays,
      'sampleDays': bl.sampleDays,
      'dominantTraits': dominantDims.map((d) => d.label).toList(),
      'recessiveTraits': recessiveDims.map((d) => d.label).toList(),
      'mostStable': sortedByStd.first.label,
      'mostVariable': sortedByStd.last.label,
      'dimensions': {
        for (final dim in BehaviorDimension.values)
          dim.label: {
            'mean': _round(bl.means[dim] ?? 0.5),
            'stdDev': _round(bl.stdDevs[dim] ?? 0.1),
          },
      },
    };
  }

  /// Generate personalized insights about behavioral patterns.
  List<String> generateInsights() {
    final insights = <String>[];

    if (_baseline == null || !_baseline!.isReliable) {
      insights.add(
          'Still learning your patterns — ${_baselineMinDays - totalDays} more days needed for a reliable fingerprint.');
      return insights;
    }

    final bl = _baseline!;

    // Activity timing insight
    final timing = bl.means[BehaviorDimension.activityTiming] ?? 0.5;
    if (timing > 0.65) {
      insights.add(
          '🌙 You\'re a night owl — most of your activity clusters in the evening hours.');
    } else if (timing < 0.35) {
      insights.add(
          '🌅 Early bird pattern detected — you\'re most active in the morning.');
    }

    // Consistency insight
    final consistency = bl.means[BehaviorDimension.consistency] ?? 0.5;
    if (consistency > 0.7) {
      insights.add(
          '📏 Highly consistent — your daily patterns are remarkably predictable.');
    } else if (consistency < 0.3) {
      insights.add(
          '🎲 Spontaneous style — your days vary a lot, which keeps things fresh but may hurt habit building.');
    }

    // Exploration insight
    final exploration = bl.means[BehaviorDimension.explorationRatio] ?? 0.5;
    if (exploration > 0.6) {
      insights.add(
          '🧭 Explorer mindset — you frequently try new categories and features.');
    } else if (exploration < 0.3) {
      insights.add(
          '🏠 Creature of habit — you stick to familiar routines, which builds mastery but watch for stagnation.');
    }

    // Energy curve insight
    final energy = bl.means[BehaviorDimension.energyCurve] ?? 0.5;
    if (energy > 0.65) {
      insights.add(
          '☀️ Morning-loaded energy — you front-load productivity in the first half of the day.');
    } else if (energy < 0.35) {
      insights.add(
          '🌙 Evening surge — your productivity peaks later in the day.');
    }

    // Completion style insight
    final completion = bl.means[BehaviorDimension.completionStyle] ?? 0.5;
    if (completion > 0.65) {
      insights.add(
          '⚡ Burst completer — you tend to finish many tasks in concentrated sessions.');
    } else if (completion < 0.35) {
      insights.add(
          '🐢 Steady worker — you spread completions evenly throughout the day.');
    }

    // Volatility insight from trend
    final trend = getIdentityTrend();
    if (trend.volatility > 0.5) {
      insights.add(
          '🌊 High behavioral volatility — your patterns have been fluctuating a lot recently.');
    } else if (trend.volatility < 0.15 && _trendHistory.length > 7) {
      insights.add(
          '🧘 Very stable identity — your behavioral fingerprint has been remarkably consistent.');
    }

    return insights;
  }

  // -- Private Dimension Computations ---------------------------------------

  double _computeActivityTiming(List<BehaviorEvent> events) {
    if (events.isEmpty) return 0.5;
    final hours = events.map((e) => e.timestamp.hour + e.timestamp.minute / 60);
    final avgHour = hours.reduce((a, b) => a + b) / hours.length;
    return (avgHour / 24).clamp(0.0, 1.0);
  }

  double _computeTaskVelocity(List<BehaviorEvent> events) {
    final completions =
        events.where((e) => e.action == 'complete').length;
    if (completions == 0) return 0.0;
    // Normalize: 0-20 completions/day → 0-1
    return (completions / 20).clamp(0.0, 1.0);
  }

  double _computeCategoryFocus(List<BehaviorEvent> events) {
    if (events.isEmpty) return 0.5;
    final catCounts = <String, int>{};
    for (final e in events) {
      catCounts[e.category] = (catCounts[e.category] ?? 0) + 1;
    }
    // HHI (Herfindahl–Hirschman Index) — higher = more concentrated
    final total = events.length.toDouble();
    double hhi = 0;
    for (final count in catCounts.values) {
      final share = count / total;
      hhi += share * share;
    }
    return hhi.clamp(0.0, 1.0);
  }

  double _computeConsistency(DateTime date, List<BehaviorEvent> events) {
    // Compare event count distribution to same-weekday historical average
    final weekday = date.weekday;
    final historicalDays = _fingerprints
        .where((f) => f.date.weekday == weekday && _dateOnly(f.date) != date)
        .toList();

    if (historicalDays.isEmpty) return 0.5;

    // Compare current event count to historical average event count
    final historicalCounts = historicalDays.map((f) {
      return _events
          .where((e) => _dateOnly(e.timestamp) == _dateOnly(f.date))
          .length;
    }).toList();

    if (historicalCounts.isEmpty) return 0.5;

    final avgCount =
        historicalCounts.reduce((a, b) => a + b) / historicalCounts.length;
    final currentCount = events.length.toDouble();

    if (avgCount == 0 && currentCount == 0) return 1.0;
    if (avgCount == 0) return 0.0;

    // Similarity = 1 - normalized absolute deviation
    final deviation = (currentCount - avgCount).abs() / avgCount;
    return (1.0 - deviation).clamp(0.0, 1.0);
  }

  double _computeSocialEngagement(List<BehaviorEvent> events) {
    if (events.isEmpty) return 0.0;
    const socialCategories = {
      'contact', 'social', 'sharing', 'event', 'meeting', 'call',
      'message', 'collaboration',
    };
    final socialCount =
        events.where((e) => socialCategories.contains(e.category.toLowerCase())).length;
    return (socialCount / events.length).clamp(0.0, 1.0);
  }

  double _computeEnergyCurve(List<BehaviorEvent> events) {
    if (events.isEmpty) return 0.5;
    // Ratio of morning (5-12) events to total
    final morningCount = events
        .where((e) => e.timestamp.hour >= 5 && e.timestamp.hour < 12)
        .length;
    return (morningCount / events.length).clamp(0.0, 1.0);
  }

  double _computeCompletionStyle(List<BehaviorEvent> events) {
    final completions =
        events.where((e) => e.action == 'complete').toList();
    if (completions.length < 2) return 0.5;

    // Measure burstiness: std dev of inter-completion gaps
    completions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final gaps = <double>[];
    for (int i = 1; i < completions.length; i++) {
      gaps.add(completions[i]
          .timestamp
          .difference(completions[i - 1].timestamp)
          .inMinutes
          .toDouble());
    }

    final meanGap = gaps.reduce((a, b) => a + b) / gaps.length;
    if (meanGap == 0) return 1.0;

    final variance =
        gaps.fold(0.0, (sum, g) => sum + (g - meanGap) * (g - meanGap)) /
            gaps.length;
    final cv = sqrt(variance) / meanGap; // coefficient of variation

    // High CV = bursty (near 1), Low CV = steady (near 0)
    return cv.clamp(0.0, 1.0);
  }

  double _computeExplorationRatio(
      DateTime date, List<BehaviorEvent> events) {
    if (events.isEmpty) return 0.0;

    // Categories seen before this date
    final historicalCats = <String>{};
    for (final e in _events) {
      if (_dateOnly(e.timestamp).isBefore(date)) {
        historicalCats.add(e.category);
      }
    }

    if (historicalCats.isEmpty) return 1.0; // everything is new on day 1

    final todayCats = events.map((e) => e.category).toSet();
    final newCats =
        todayCats.where((c) => !historicalCats.contains(c)).length;
    return (newCats / todayCats.length).clamp(0.0, 1.0);
  }

  // -- Classification & Narrative -------------------------------------------

  DeviationLevel _classifyDeviation(double zScore) {
    if (zScore < 1.0) return DeviationLevel.normal;
    if (zScore < 1.5) return DeviationLevel.mild;
    if (zScore < 2.0) return DeviationLevel.moderate;
    if (zScore < 3.0) return DeviationLevel.significant;
    return DeviationLevel.extreme;
  }

  IdentityPhase _classifyPhase(
      List<DimensionDeviation> deviations, double composite) {
    final significantCount =
        deviations.where((d) => d.level.priority >= 2).length;
    final extremeCount =
        deviations.where((d) => d.level.priority >= 3).length;

    // Check if this is a sustained transformation
    final recentPhases = _trendHistory
        .reversed
        .take(7)
        .map((t) => t.phase)
        .toList();
    final sustainedDeviation = recentPhases.length >= 5 &&
        recentPhases.every(
            (p) => p != IdentityPhase.authentic);

    if (sustainedDeviation && composite > 1.0) {
      return IdentityPhase.transformed;
    }
    if (extremeCount >= 3 || composite > 2.5) {
      return IdentityPhase.disrupted;
    }
    if (significantCount >= 2 && composite > 1.5) {
      return IdentityPhase.exploring;
    }
    if (significantCount >= 1 || composite > 1.0) {
      return IdentityPhase.shifting;
    }
    return IdentityPhase.authentic;
  }

  String _generateNarrative(BehaviorDimension dim, double current,
      double mean, double z, DeviationLevel level) {
    if (level == DeviationLevel.normal) {
      return '${dim.label} is within your normal range.';
    }

    final direction = current > mean ? 'higher' : 'lower';
    final intensity = level.priority >= 3 ? 'significantly' : 'noticeably';

    switch (dim) {
      case BehaviorDimension.activityTiming:
        return current > mean
            ? 'You\'re active $intensity later than usual — shifted ${_formatShift(current, mean)} hours.'
            : 'You\'re starting $intensity earlier than normal — shifted ${_formatShift(current, mean)} hours.';
      case BehaviorDimension.taskVelocity:
        return 'Task completion rate is $intensity $direction than your baseline.';
      case BehaviorDimension.categoryFocus:
        return current > mean
            ? 'More focused on fewer categories than usual — deeper specialization.'
            : 'Spreading attention across more categories than normal — wider but shallower.';
      case BehaviorDimension.consistency:
        return current > mean
            ? 'Today is more structured than your typical ${_weekdayName(DateTime.now().weekday)}.'
            : 'Today\'s pattern deviates $intensity from your usual ${_weekdayName(DateTime.now().weekday)} rhythm.';
      case BehaviorDimension.socialEngagement:
        return 'Social activity is $intensity $direction than your norm.';
      case BehaviorDimension.energyCurve:
        return current > mean
            ? 'Energy skewing more toward morning than usual.'
            : 'Energy shifting toward evening — later productivity peak.';
      case BehaviorDimension.completionStyle:
        return current > mean
            ? 'Completing things in more concentrated bursts today.'
            : 'More evenly-paced completions than your typical burst pattern.';
      case BehaviorDimension.explorationRatio:
        return current > mean
            ? 'Trying more new things than usual — high exploration mode.'
            : 'Sticking closer to familiar patterns today.';
    }
  }

  List<String> _buildChangeNarratives(
      List<DimensionDeviation> deviations, IdentityPhase phase) {
    final narratives = <String>[];

    switch (phase) {
      case IdentityPhase.authentic:
        narratives.add('You\'re behaving like your usual self today.');
        break;
      case IdentityPhase.shifting:
        final shifted = deviations
            .where((d) => d.level.priority >= 2)
            .map((d) => d.dimension.label)
            .join(', ');
        narratives.add('Subtle shifts detected in: $shifted.');
        narratives.add(
            'This could be natural variation or the start of a pattern change.');
        break;
      case IdentityPhase.exploring:
        narratives.add(
            'You\'re in exploration mode — several dimensions are outside your comfort zone.');
        narratives.add(
            'This often happens when trying new routines or after a motivational spark.');
        break;
      case IdentityPhase.disrupted:
        narratives.add(
            '⚠️ Significant behavioral disruption detected across multiple dimensions.');
        narratives.add(
            'This pattern often correlates with major life events, illness, or travel.');
        narratives.add(
            'Consider whether this is intentional change or something to address.');
        break;
      case IdentityPhase.transformed:
        narratives.add(
            '🦋 Your behavior has sustainably shifted to a new pattern.');
        narratives.add(
            'Your baseline identity appears to be evolving — this may become your new normal.');
        break;
    }

    // Add specific dimension narratives for significant deviations
    for (final d in deviations) {
      if (d.level.priority >= 2) {
        narratives.add('${d.dimension.emoji} ${d.narrative}');
      }
    }

    return narratives;
  }

  double _computeAuthenticityScore(double compositeDistance) {
    // Exponential decay: score drops as distance increases
    // distance 0 → 100, distance 1 → ~60, distance 2 → ~37, distance 3 → ~22
    return (100 * exp(-0.5 * compositeDistance)).clamp(0.0, 100.0);
  }

  // -- Helpers --------------------------------------------------------------

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  double _round(double v) => (v * 1000).roundToDouble() / 1000;

  String _formatShift(double current, double mean) {
    final hours = ((current - mean).abs() * 24).round();
    return '$hours';
  }

  String _weekdayName(int weekday) {
    const names = [
      '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
      'Saturday', 'Sunday',
    ];
    return names[weekday.clamp(1, 7)];
  }
}
