import 'dart:math';

// ──────────────────────────────────────────────────────────────────
// Smart Pattern Detector Service
//
// Generates demo multi-tracker data with embedded correlations,
// computes Pearson r between all pairs, detects lagged correlations,
// and produces human-readable insights.
// ──────────────────────────────────────────────────────────────────

/// Strength classification for a discovered pattern.
enum PatternStrength { strongPositive, moderatePositive, moderateNegative, strongNegative }

/// A single discovered correlation pattern.
class DiscoveredPattern {
  final String trackerA;
  final String trackerB;
  final double r;
  final PatternStrength strength;
  final String insight;
  final bool isLagged; // yesterday→today

  const DiscoveredPattern({
    required this.trackerA,
    required this.trackerB,
    required this.r,
    required this.strength,
    required this.insight,
    this.isLagged = false,
  });
}

/// Predictability info for one tracker.
class PredictabilityInfo {
  final String tracker;
  final double score; // 0-1
  final List<String> topPredictors;

  const PredictabilityInfo({
    required this.tracker,
    required this.score,
    required this.topPredictors,
  });
}

/// Service that analyses demo tracker data for cross-tracker patterns.
class PatternDetectorService {
  static final _rng = Random(42);

  // ── Tracker names ──────────────────────────────────────────────
  static const trackers = [
    'Mood',
    'Sleep Hours',
    'Steps',
    'Water Intake',
    'Caffeine',
    'Calories',
    'Screen Time',
    'Meditation',
    'Weight',
    'Heart Rate',
    'Stress',
    'Productivity',
  ];

  // ── Demo data (30 days) with embedded correlations ─────────────
  List<Map<String, List<double>>> generateDemoData() {
    const days = 30;
    final data = <String, List<double>>{};

    // Base random series
    List<double> base(double mean, double std) =>
        List.generate(days, (_) => mean + _rng.nextDouble() * std * 2 - std);

    final sleep = base(7, 1.5);
    final exercise = base(6000, 3000);
    final caffeine = base(200, 100);
    final meditation = base(10, 8);
    final screenTime = base(5, 2);

    // Correlated series
    final mood = List.generate(days, (i) =>
        5 + sleep[i] * 0.3 - caffeine[i] * 0.005 + exercise[i] * 0.0003 + (_rng.nextDouble() - 0.5));
    final stress = List.generate(days, (i) =>
        5 - sleep[i] * 0.2 + screenTime[i] * 0.3 + caffeine[i] * 0.003 + (_rng.nextDouble() - 0.5));
    final productivity = List.generate(days, (i) =>
        4 + sleep[i] * 0.25 + meditation[i] * 0.05 - stress[i] * 0.15 + (_rng.nextDouble() - 0.5));
    final heartRate = base(72, 8);
    final water = base(2000, 500);
    final calories = base(2200, 400);
    final weight = base(75, 1);

    data['Mood'] = mood;
    data['Sleep Hours'] = sleep;
    data['Steps'] = exercise;
    data['Water Intake'] = water;
    data['Caffeine'] = caffeine;
    data['Calories'] = calories;
    data['Screen Time'] = screenTime;
    data['Meditation'] = meditation;
    data['Weight'] = weight;
    data['Heart Rate'] = heartRate;
    data['Stress'] = stress;
    data['Productivity'] = productivity;

    return [data];
  }

  // ── Pearson correlation ────────────────────────────────────────
  double pearson(List<double> x, List<double> y) {
    final n = min(x.length, y.length);
    if (n < 3) return 0;
    double mx = 0, my = 0;
    for (int i = 0; i < n; i++) { mx += x[i]; my += y[i]; }
    mx /= n; my /= n;
    double num = 0, dx = 0, dy = 0;
    for (int i = 0; i < n; i++) {
      final a = x[i] - mx, b = y[i] - my;
      num += a * b; dx += a * a; dy += b * b;
    }
    final denom = sqrt(dx) * sqrt(dy);
    return denom == 0 ? 0 : num / denom;
  }

  // ── Classify strength ─────────────────────────────────────────
  PatternStrength? classify(double r) {
    if (r >= 0.6) return PatternStrength.strongPositive;
    if (r >= 0.4) return PatternStrength.moderatePositive;
    if (r <= -0.6) return PatternStrength.strongNegative;
    if (r <= -0.4) return PatternStrength.moderateNegative;
    return null;
  }

  String _emoji(PatternStrength s) {
    switch (s) {
      case PatternStrength.strongPositive: return '🔗';
      case PatternStrength.moderatePositive: return '🔄';
      case PatternStrength.strongNegative: return '⚡';
      case PatternStrength.moderateNegative: return '↔️';
    }
  }

  String _verb(PatternStrength s) {
    switch (s) {
      case PatternStrength.strongPositive: return 'strongly increases with';
      case PatternStrength.moderatePositive: return 'tends to increase with';
      case PatternStrength.strongNegative: return 'strongly decreases with';
      case PatternStrength.moderateNegative: return 'tends to decrease with';
    }
  }

  // ── Discover same-day patterns ────────────────────────────────
  List<DiscoveredPattern> discoverPatterns(Map<String, List<double>> data) {
    final patterns = <DiscoveredPattern>[];
    final keys = data.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      for (int j = i + 1; j < keys.length; j++) {
        final r = pearson(data[keys[i]]!, data[keys[j]]!);
        final s = classify(r);
        if (s != null) {
          patterns.add(DiscoveredPattern(
            trackerA: keys[i],
            trackerB: keys[j],
            r: r,
            strength: s,
            insight: '${_emoji(s)} ${keys[i]} ${_verb(s)} ${keys[j]} (r=${r.toStringAsFixed(2)})',
          ));
        }
      }
    }
    patterns.sort((a, b) => b.r.abs().compareTo(a.r.abs()));
    return patterns;
  }

  // ── Discover lagged patterns (yesterday→today) ────────────────
  List<DiscoveredPattern> discoverLaggedPatterns(Map<String, List<double>> data) {
    final patterns = <DiscoveredPattern>[];
    final keys = data.keys.toList();
    for (final a in keys) {
      for (final b in keys) {
        if (a == b) continue;
        final x = data[a]!.sublist(0, data[a]!.length - 1);
        final y = data[b]!.sublist(1);
        final r = pearson(x, y);
        final s = classify(r);
        if (s != null) {
          patterns.add(DiscoveredPattern(
            trackerA: a,
            trackerB: b,
            r: r,
            strength: s,
            insight: '${_emoji(s)} Yesterday\'s $a ${_verb(s)} today\'s $b (r=${r.toStringAsFixed(2)})',
            isLagged: true,
          ));
        }
      }
    }
    patterns.sort((a, b) => b.r.abs().compareTo(a.r.abs()));
    return patterns;
  }

  // ── Correlation matrix ────────────────────────────────────────
  Map<String, Map<String, double>> correlationMatrix(Map<String, List<double>> data) {
    final keys = data.keys.toList();
    final matrix = <String, Map<String, double>>{};
    for (final a in keys) {
      matrix[a] = {};
      for (final b in keys) {
        matrix[a]![b] = a == b ? 1.0 : pearson(data[a]!, data[b]!);
      }
    }
    return matrix;
  }

  // ── Predictability scores ─────────────────────────────────────
  List<PredictabilityInfo> predictability(Map<String, List<double>> data) {
    final keys = data.keys.toList();
    final result = <PredictabilityInfo>[];
    for (final target in keys) {
      final correlations = <MapEntry<String, double>>[];
      for (final other in keys) {
        if (other == target) continue;
        correlations.add(MapEntry(other, pearson(data[other]!, data[target]!).abs()));
      }
      correlations.sort((a, b) => b.value.compareTo(a.value));
      final top3 = correlations.take(3).toList();
      final score = top3.isEmpty ? 0.0 : top3.map((e) => e.value).reduce((a, b) => a + b) / top3.length;
      result.add(PredictabilityInfo(
        tracker: target,
        score: score.clamp(0.0, 1.0),
        topPredictors: top3.map((e) => '${e.key} (${e.value.toStringAsFixed(2)})').toList(),
      ));
    }
    result.sort((a, b) => b.score.compareTo(a.score));
    return result;
  }
}
