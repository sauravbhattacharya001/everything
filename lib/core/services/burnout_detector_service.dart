/// Smart Burnout Detector Service — autonomous burnout risk analysis
/// with multi-signal monitoring, pattern detection, resilience scoring,
/// and proactive recovery recommendations.

/// Burnout risk level classification.
enum BurnoutRiskLevel {
  low,
  moderate,
  elevated,
  high,
  critical;

  String get label {
    switch (this) {
      case BurnoutRiskLevel.low:
        return 'Low Risk';
      case BurnoutRiskLevel.moderate:
        return 'Moderate';
      case BurnoutRiskLevel.elevated:
        return 'Elevated';
      case BurnoutRiskLevel.high:
        return 'High Risk';
      case BurnoutRiskLevel.critical:
        return 'Critical';
    }
  }

  String get emoji {
    switch (this) {
      case BurnoutRiskLevel.low:
        return '🟢';
      case BurnoutRiskLevel.moderate:
        return '🟡';
      case BurnoutRiskLevel.elevated:
        return '🟠';
      case BurnoutRiskLevel.high:
        return '🔴';
      case BurnoutRiskLevel.critical:
        return '🚨';
    }
  }
}

/// Trend direction for a signal.
enum SignalTrend {
  improving,
  stable,
  declining;

  String get arrow {
    switch (this) {
      case SignalTrend.improving:
        return '↑';
      case SignalTrend.stable:
        return '→';
      case SignalTrend.declining:
        return '↓';
    }
  }
}

/// A single wellness signal feeding the burnout model.
class BurnoutSignal {
  final String name;
  final String category; // sleep, mood, energy, activity, social, nutrition
  final double value; // 0–100 (higher = healthier)
  final double weight;
  final SignalTrend trend;

  const BurnoutSignal({
    required this.name,
    required this.category,
    required this.value,
    required this.weight,
    required this.trend,
  });
}

/// A detected warning pattern.
class WarningPattern {
  final String name;
  final String description;
  final String severity; // mild, moderate, severe
  const WarningPattern(
      {required this.name, required this.description, required this.severity});
}

/// A phased recovery step.
class RecoveryStep {
  final String phase; // Immediate, Short-term, Medium-term
  final String action;
  const RecoveryStep({required this.phase, required this.action});
}

/// Full analysis result.
class BurnoutAnalysis {
  final BurnoutRiskLevel overallRisk;
  final double riskScore; // 0–100
  final List<BurnoutSignal> signals;
  final List<String> recommendations;
  final List<RecoveryStep> recoveryPlan;
  final List<WarningPattern> warningPatterns;
  final double resilienceScore; // 0–100

  const BurnoutAnalysis({
    required this.overallRisk,
    required this.riskScore,
    required this.signals,
    required this.recommendations,
    required this.recoveryPlan,
    required this.warningPatterns,
    required this.resilienceScore,
  });
}

/// Named scenario for demo purposes.
class BurnoutScenario {
  final String name;
  final String description;
  final List<BurnoutSignal> signals;
  const BurnoutScenario(
      {required this.name, required this.description, required this.signals});
}

class BurnoutDetectorService {
  // ── Sample signals ──────────────────────────────────────────

  List<BurnoutSignal> generateSampleSignals() =>
      getSampleScenarios()[1].signals;

  // ── Scenarios ───────────────────────────────────────────────

  List<BurnoutScenario> getSampleScenarios() => [
        BurnoutScenario(
          name: 'Healthy Balance',
          description: 'All signals in the green — sustainable pace.',
          signals: const [
            BurnoutSignal(name: 'Sleep Quality', category: 'sleep', value: 85, weight: 1.3, trend: SignalTrend.stable),
            BurnoutSignal(name: 'Sleep Duration', category: 'sleep', value: 80, weight: 1.2, trend: SignalTrend.stable),
            BurnoutSignal(name: 'Mood Stability', category: 'mood', value: 82, weight: 1.3, trend: SignalTrend.improving),
            BurnoutSignal(name: 'Energy Level', category: 'energy', value: 78, weight: 1.2, trend: SignalTrend.stable),
            BurnoutSignal(name: 'Exercise Frequency', category: 'activity', value: 75, weight: 1.0, trend: SignalTrend.improving),
            BurnoutSignal(name: 'Social Interaction', category: 'social', value: 70, weight: 1.0, trend: SignalTrend.stable),
            BurnoutSignal(name: 'Screen Time', category: 'activity', value: 65, weight: 0.8, trend: SignalTrend.stable),
            BurnoutSignal(name: 'Work Hours', category: 'activity', value: 72, weight: 1.1, trend: SignalTrend.stable),
            BurnoutSignal(name: 'Break Frequency', category: 'activity', value: 70, weight: 0.9, trend: SignalTrend.stable),
            BurnoutSignal(name: 'Hydration', category: 'nutrition', value: 80, weight: 0.7, trend: SignalTrend.stable),
            BurnoutSignal(name: 'Nutrition Quality', category: 'nutrition', value: 75, weight: 0.8, trend: SignalTrend.stable),
            BurnoutSignal(name: 'Mindfulness Minutes', category: 'mood', value: 60, weight: 0.7, trend: SignalTrend.improving),
          ],
        ),
        BurnoutScenario(
          name: 'Early Warning',
          description: 'Some signals dipping — worth paying attention.',
          signals: const [
            BurnoutSignal(name: 'Sleep Quality', category: 'sleep', value: 58, weight: 1.3, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Sleep Duration', category: 'sleep', value: 55, weight: 1.2, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Mood Stability', category: 'mood', value: 52, weight: 1.3, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Energy Level', category: 'energy', value: 50, weight: 1.2, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Exercise Frequency', category: 'activity', value: 40, weight: 1.0, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Social Interaction', category: 'social', value: 45, weight: 1.0, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Screen Time', category: 'activity', value: 35, weight: 0.8, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Work Hours', category: 'activity', value: 38, weight: 1.1, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Break Frequency', category: 'activity', value: 42, weight: 0.9, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Hydration', category: 'nutrition', value: 60, weight: 0.7, trend: SignalTrend.stable),
            BurnoutSignal(name: 'Nutrition Quality', category: 'nutrition', value: 55, weight: 0.8, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Mindfulness Minutes', category: 'mood', value: 30, weight: 0.7, trend: SignalTrend.declining),
          ],
        ),
        BurnoutScenario(
          name: 'Approaching Burnout',
          description: 'Multiple red flags — intervention recommended.',
          signals: const [
            BurnoutSignal(name: 'Sleep Quality', category: 'sleep', value: 35, weight: 1.3, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Sleep Duration', category: 'sleep', value: 30, weight: 1.2, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Mood Stability', category: 'mood', value: 28, weight: 1.3, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Energy Level', category: 'energy', value: 25, weight: 1.2, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Exercise Frequency', category: 'activity', value: 15, weight: 1.0, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Social Interaction', category: 'social', value: 20, weight: 1.0, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Screen Time', category: 'activity', value: 18, weight: 0.8, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Work Hours', category: 'activity', value: 15, weight: 1.1, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Break Frequency', category: 'activity', value: 20, weight: 0.9, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Hydration', category: 'nutrition', value: 40, weight: 0.7, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Nutrition Quality', category: 'nutrition', value: 30, weight: 0.8, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Mindfulness Minutes', category: 'mood', value: 10, weight: 0.7, trend: SignalTrend.declining),
          ],
        ),
        BurnoutScenario(
          name: 'Critical Burnout',
          description: 'Severe depletion across all dimensions.',
          signals: const [
            BurnoutSignal(name: 'Sleep Quality', category: 'sleep', value: 15, weight: 1.3, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Sleep Duration', category: 'sleep', value: 12, weight: 1.2, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Mood Stability', category: 'mood', value: 10, weight: 1.3, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Energy Level', category: 'energy', value: 8, weight: 1.2, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Exercise Frequency', category: 'activity', value: 5, weight: 1.0, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Social Interaction', category: 'social', value: 8, weight: 1.0, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Screen Time', category: 'activity', value: 10, weight: 0.8, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Work Hours', category: 'activity', value: 5, weight: 1.1, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Break Frequency', category: 'activity', value: 8, weight: 0.9, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Hydration', category: 'nutrition', value: 20, weight: 0.7, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Nutrition Quality', category: 'nutrition', value: 15, weight: 0.8, trend: SignalTrend.declining),
            BurnoutSignal(name: 'Mindfulness Minutes', category: 'mood', value: 2, weight: 0.7, trend: SignalTrend.declining),
          ],
        ),
      ];

  // ── Core analysis ───────────────────────────────────────────

  BurnoutAnalysis analyzeSignals(List<BurnoutSignal> signals) {
    final riskScore = _computeRiskScore(signals);
    final risk = _classifyRisk(riskScore);
    final patterns = _detectPatterns(signals);
    final resilience = _calculateResilience(signals);
    final recs = _generateRecommendations(signals, risk);
    final plan = _generateRecoveryPlan(risk);

    return BurnoutAnalysis(
      overallRisk: risk,
      riskScore: riskScore,
      signals: signals,
      recommendations: recs,
      recoveryPlan: plan,
      warningPatterns: patterns,
      resilienceScore: resilience,
    );
  }

  // ── Private helpers ─────────────────────────────────────────

  double _computeRiskScore(List<BurnoutSignal> signals) {
    if (signals.isEmpty) return 0;
    double totalWeight = 0;
    double weightedSum = 0;
    for (final s in signals) {
      // Invert: low value = high risk
      final risk = 100 - s.value;
      // Declining trends amplify risk
      final trendMul =
          s.trend == SignalTrend.declining ? 1.2 : (s.trend == SignalTrend.improving ? 0.85 : 1.0);
      weightedSum += risk * s.weight * trendMul;
      totalWeight += s.weight;
    }
    return (weightedSum / totalWeight).clamp(0, 100);
  }

  BurnoutRiskLevel _classifyRisk(double score) {
    if (score < 25) return BurnoutRiskLevel.low;
    if (score < 40) return BurnoutRiskLevel.moderate;
    if (score < 60) return BurnoutRiskLevel.elevated;
    if (score < 80) return BurnoutRiskLevel.high;
    return BurnoutRiskLevel.critical;
  }

  List<WarningPattern> _detectPatterns(List<BurnoutSignal> signals) {
    final patterns = <WarningPattern>[];
    final byName = {for (final s in signals) s.name: s};

    // Sleep declining + work hours declining (low = overworking)
    final sleep = byName['Sleep Quality'];
    final work = byName['Work Hours'];
    if (sleep != null &&
        work != null &&
        sleep.trend == SignalTrend.declining &&
        work.value < 40) {
      patterns.add(const WarningPattern(
        name: 'Overwork-Sleep Spiral',
        description:
            'Sleep quality is declining while work hours appear excessive. This creates a self-reinforcing cycle.',
        severity: 'severe',
      ));
    }

    // Social isolation
    final social = byName['Social Interaction'];
    if (social != null && social.value < 30) {
      patterns.add(const WarningPattern(
        name: 'Social Isolation',
        description:
            'Very low social interaction detected. Isolation accelerates emotional exhaustion.',
        severity: social.value < 15 ? 'severe' : 'moderate',
      ));
    }

    // Energy crash cycle
    final energy = byName['Energy Level'];
    final breaks = byName['Break Frequency'];
    if (energy != null &&
        breaks != null &&
        energy.value < 35 &&
        breaks.value < 35) {
      patterns.add(const WarningPattern(
        name: 'Energy Crash Cycle',
        description:
            'Low energy combined with infrequent breaks creates a depletion loop. Recovery requires deliberate rest.',
        severity: 'severe',
      ));
    }

    // Screen overload
    final screen = byName['Screen Time'];
    if (screen != null && screen.value < 25 && screen.trend == SignalTrend.declining) {
      patterns.add(const WarningPattern(
        name: 'Digital Overload',
        description:
            'Excessive screen time with worsening trend contributes to mental fatigue and eye strain.',
        severity: 'moderate',
      ));
    }

    // Nutrition neglect
    final nutrition = byName['Nutrition Quality'];
    final hydration = byName['Hydration'];
    if (nutrition != null &&
        hydration != null &&
        nutrition.value < 40 &&
        hydration.value < 40) {
      patterns.add(const WarningPattern(
        name: 'Physical Neglect',
        description:
            'Both nutrition and hydration are poor. The body cannot sustain mental performance without fuel.',
        severity: 'moderate',
      ));
    }

    // Mindfulness gap
    final mind = byName['Mindfulness Minutes'];
    final mood = byName['Mood Stability'];
    if (mind != null && mood != null && mind.value < 20 && mood.value < 40) {
      patterns.add(const WarningPattern(
        name: 'Emotional Regulation Gap',
        description:
            'Low mindfulness practice paired with declining mood stability. Recovery tools are underutilised.',
        severity: 'moderate',
      ));
    }

    return patterns;
  }

  double _calculateResilience(List<BurnoutSignal> signals) {
    // Resilience = average of positive signals (value > 60)
    final strong = signals.where((s) => s.value >= 60).toList();
    if (strong.isEmpty) return 0;
    final improvingBonus =
        signals.where((s) => s.trend == SignalTrend.improving).length * 5.0;
    final avg = strong.fold<double>(0, (a, b) => a + b.value) / strong.length;
    return (avg * 0.7 + improvingBonus + strong.length / signals.length * 30)
        .clamp(0, 100);
  }

  List<String> _generateRecommendations(
      List<BurnoutSignal> signals, BurnoutRiskLevel risk) {
    final recs = <String>[];
    final sorted = List<BurnoutSignal>.from(signals)
      ..sort((a, b) => a.value.compareTo(b.value));

    // Top 3 worst signals drive recommendations
    for (final s in sorted.take(3)) {
      switch (s.category) {
        case 'sleep':
          recs.add(
              '🛌 Prioritise sleep: set a consistent bedtime, avoid screens 1h before bed.');
          break;
        case 'mood':
          recs.add(
              '🧘 Schedule 10 min daily mindfulness or journaling to stabilise mood.');
          break;
        case 'energy':
          recs.add(
              '⚡ Take a 20-min walk outdoors — movement and sunlight boost energy.');
          break;
        case 'activity':
          if (s.name == 'Work Hours') {
            recs.add(
                '⏰ Cap work at 8h/day this week. Set a hard stop alarm.');
          } else if (s.name == 'Break Frequency') {
            recs.add(
                '☕ Use the Pomodoro technique — 25 min work, 5 min break.');
          } else if (s.name == 'Screen Time') {
            recs.add(
                '📵 Introduce 1h screen-free time in the evening.');
          } else {
            recs.add(
                '🏃 Start with 15 min light exercise 3× this week.');
          }
          break;
        case 'social':
          recs.add(
              '👋 Reach out to one friend today — even a short text counts.');
          break;
        case 'nutrition':
          recs.add(
              '🥗 Prepare meals in advance and keep a water bottle visible.');
          break;
      }
    }

    if (risk.index >= BurnoutRiskLevel.high.index) {
      recs.add(
          '🩺 Consider talking to a professional — high burnout risk warrants support.');
    }
    if (risk.index >= BurnoutRiskLevel.elevated.index) {
      recs.add(
          '📅 Block 2h of unstructured free time on your calendar this week.');
    }

    return recs;
  }

  List<RecoveryStep> _generateRecoveryPlan(BurnoutRiskLevel risk) {
    final plan = <RecoveryStep>[
      const RecoveryStep(
          phase: 'Immediate',
          action: 'Take a 10-minute break right now — step away from all screens.'),
      const RecoveryStep(
          phase: 'Immediate',
          action: 'Drink a full glass of water and eat something nutritious.'),
    ];

    if (risk.index >= BurnoutRiskLevel.moderate.index) {
      plan.addAll([
        const RecoveryStep(
            phase: 'Short-term',
            action: 'Set a strict 8-hour work limit for the rest of this week.'),
        const RecoveryStep(
            phase: 'Short-term',
            action: 'Schedule one social activity before the weekend.'),
        const RecoveryStep(
            phase: 'Short-term',
            action: 'Go to bed 30 minutes earlier for the next 5 nights.'),
      ]);
    }

    if (risk.index >= BurnoutRiskLevel.elevated.index) {
      plan.addAll([
        const RecoveryStep(
            phase: 'Medium-term',
            action: 'Establish a daily wind-down routine (reading, stretching, no screens).'),
        const RecoveryStep(
            phase: 'Medium-term',
            action: 'Build 3× weekly exercise into your calendar as non-negotiable.'),
        const RecoveryStep(
            phase: 'Medium-term',
            action: 'Review your commitments — drop or delegate one recurring obligation.'),
      ]);
    }

    if (risk.index >= BurnoutRiskLevel.high.index) {
      plan.addAll([
        const RecoveryStep(
            phase: 'Medium-term',
            action: 'Take at least one full day off within the next 7 days.'),
        const RecoveryStep(
            phase: 'Medium-term',
            action: 'Book a check-in with a counsellor or trusted mentor.'),
      ]);
    }

    return plan;
  }
}
