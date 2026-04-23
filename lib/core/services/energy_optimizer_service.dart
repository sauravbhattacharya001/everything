/// Smart Energy Optimizer Service — autonomous energy prediction with
/// cross-tracker correlation, circadian modeling, and proactive
/// work/rest window recommendations.

/// Energy window types for scheduling recommendations.
enum WindowType {
  deepWork,
  lightWork,
  creative,
  exercise,
  rest;

  String get label {
    switch (this) {
      case WindowType.deepWork:
        return 'Deep Work';
      case WindowType.lightWork:
        return 'Light Work';
      case WindowType.creative:
        return 'Creative';
      case WindowType.exercise:
        return 'Exercise';
      case WindowType.rest:
        return 'Rest';
    }
  }

  String get emoji {
    switch (this) {
      case WindowType.deepWork:
        return '🧠';
      case WindowType.lightWork:
        return '📋';
      case WindowType.creative:
        return '🎨';
      case WindowType.exercise:
        return '🏃';
      case WindowType.rest:
        return '😴';
    }
  }
}

/// A single hour's energy signal with contributing factors.
class EnergySignal {
  final int hour;
  final double sleepFactor;
  final double caffeineFactor;
  final double activityFactor;
  final double circadianFactor;
  final double energyScore;

  const EnergySignal({
    required this.hour,
    required this.sleepFactor,
    required this.caffeineFactor,
    required this.activityFactor,
    required this.circadianFactor,
    required this.energyScore,
  });
}

/// A recommended time window for a specific activity type.
class EnergyWindow {
  final int startHour;
  final int endHour;
  final WindowType type;
  final double confidence;

  const EnergyWindow({
    required this.startHour,
    required this.endHour,
    required this.type,
    required this.confidence,
  });

  String get timeRange {
    String _fmt(int h) => '${h % 12 == 0 ? 12 : h % 12}${h < 12 ? 'AM' : 'PM'}';
    return '${_fmt(startHour)}–${_fmt(endHour)}';
  }
}

/// An energy profile describing sleep/caffeine/activity habits.
class EnergyProfile {
  final String name;
  final String emoji;
  final String description;
  final int wakeHour;
  final int sleepHour;
  final double sleepQuality;
  final List<int> caffeineHours;
  final List<int> activityHours;

  const EnergyProfile({
    required this.name,
    required this.emoji,
    required this.description,
    required this.wakeHour,
    required this.sleepHour,
    required this.sleepQuality,
    required this.caffeineHours,
    required this.activityHours,
  });
}

/// Full optimization result.
class EnergyOptimization {
  final List<EnergySignal> hourlyEnergy;
  final List<EnergyWindow> windows;
  final int peakHour;
  final int troughHour;
  final double overallScore;
  final List<String> recommendations;
  final EnergyProfile profile;

  const EnergyOptimization({
    required this.hourlyEnergy,
    required this.windows,
    required this.peakHour,
    required this.troughHour,
    required this.overallScore,
    required this.recommendations,
    required this.profile,
  });
}

/// Service that models energy curves and generates scheduling advice.
class EnergyOptimizerService {
  static final List<EnergyProfile> profiles = [
    const EnergyProfile(
      name: 'Early Bird',
      emoji: '🐦',
      description: 'Rises at 5 AM, peaks mid-morning, winds down by evening.',
      wakeHour: 5,
      sleepHour: 21,
      sleepQuality: 0.9,
      caffeineHours: [6],
      activityHours: [6, 17],
    ),
    const EnergyProfile(
      name: 'Night Owl',
      emoji: '🦉',
      description: 'Wakes at 9 AM, hits stride after lunch, creative bursts at night.',
      wakeHour: 9,
      sleepHour: 1,
      sleepQuality: 0.7,
      caffeineHours: [10, 14],
      activityHours: [18],
    ),
    const EnergyProfile(
      name: 'Balanced',
      emoji: '⚖️',
      description: 'Standard 7–11 schedule with moderate caffeine and midday exercise.',
      wakeHour: 7,
      sleepHour: 23,
      sleepQuality: 0.8,
      caffeineHours: [8],
      activityHours: [12, 18],
    ),
    const EnergyProfile(
      name: 'Caffeine Dependent',
      emoji: '☕',
      description: 'Poor sleep compensated by frequent coffee. Crashes hard in the afternoon.',
      wakeHour: 7,
      sleepHour: 0,
      sleepQuality: 0.45,
      caffeineHours: [7, 10, 13, 16],
      activityHours: [],
    ),
  ];

  /// Generate a full 24-hour energy optimization for a profile.
  EnergyOptimization optimize(EnergyProfile profile) {
    final signals = <EnergySignal>[];

    for (int h = 0; h < 24; h++) {
      final circadian = _circadian(h, profile.wakeHour);
      final sleep = _sleepDecay(h, profile.wakeHour, profile.sleepQuality);
      final caffeine = _caffeineEffect(h, profile.caffeineHours);
      final activity = _activityBoost(h, profile.activityHours);

      final energy = (0.4 * circadian + 0.3 * sleep + 0.2 * caffeine + 0.1 * activity)
          .clamp(0.0, 1.0);

      signals.add(EnergySignal(
        hour: h,
        circadianFactor: circadian,
        sleepFactor: sleep,
        caffeineFactor: caffeine,
        activityFactor: activity,
        energyScore: energy * 100,
      ));
    }

    // Peak / trough (only during waking hours).
    int peak = profile.wakeHour;
    int trough = profile.wakeHour;
    for (final s in signals) {
      if (_isAwake(s.hour, profile)) {
        if (s.energyScore > signals[peak].energyScore) peak = s.hour;
        if (s.energyScore < signals[trough].energyScore) trough = s.hour;
      }
    }

    final windows = _buildWindows(signals, profile);
    final recs = _buildRecommendations(signals, profile, peak, trough);

    final wakingScores = signals
        .where((s) => _isAwake(s.hour, profile))
        .map((s) => s.energyScore)
        .toList();
    final avg = wakingScores.isEmpty
        ? 0.0
        : wakingScores.reduce((a, b) => a + b) / wakingScores.length;
    final variance = wakingScores.isEmpty
        ? 0.0
        : wakingScores.map((s) => (s - avg) * (s - avg)).reduce((a, b) => a + b) /
            wakingScores.length;
    final consistency = 1.0 - (variance / 2500).clamp(0.0, 0.5);
    final overall = (avg * consistency).clamp(0.0, 100.0);

    return EnergyOptimization(
      hourlyEnergy: signals,
      windows: windows,
      peakHour: peak,
      troughHour: trough,
      overallScore: overall,
      recommendations: recs,
      profile: profile,
    );
  }

  // ── Circadian rhythm: peaks ~10 AM offset from wake, dips ~2 PM ──

  double _circadian(int hour, int wakeHour) {
    final awake = ((hour - wakeHour) % 24).toDouble();
    // Two-peak model: morning peak at wake+4, afternoon recovery at wake+9.
    final morning = _gaussian(awake, 4.0, 2.5);
    final afternoon = _gaussian(awake, 9.0, 3.0) * 0.75;
    final night = awake > 14 ? (awake - 14) / 10.0 : 0.0;
    return (morning + afternoon - night).clamp(0.0, 1.0);
  }

  double _gaussian(double x, double mu, double sigma) {
    final d = (x - mu) / sigma;
    return _exp(-0.5 * d * d);
  }

  // ── Sleep factor: starts high, decays through the day ──

  double _sleepDecay(int hour, int wakeHour, double quality) {
    final awake = ((hour - wakeHour) % 24).toDouble();
    return (quality * _exp(-awake / 18.0)).clamp(0.0, 1.0);
  }

  // ── Caffeine: half-life ~5 hours ──

  double _caffeineEffect(int hour, List<int> doses) {
    double total = 0;
    for (final dose in doses) {
      final elapsed = ((hour - dose) % 24).toDouble();
      if (elapsed >= 0 && elapsed < 20) {
        // Onset ~30 min, peak ~1h, then decay.
        final onset = elapsed < 1 ? elapsed : 1.0;
        final decay = _exp(-0.693 * (elapsed / 5.0)); // half-life 5h
        total += onset * decay * 0.8;
      }
    }
    return total.clamp(0.0, 1.0);
  }

  // ── Activity: short boost after exercise ──

  double _activityBoost(int hour, List<int> sessions) {
    double boost = 0;
    for (final s in sessions) {
      final elapsed = ((hour - s) % 24).toDouble();
      if (elapsed >= 0 && elapsed < 4) {
        boost += _gaussian(elapsed, 1.0, 1.5) * 0.7;
      }
    }
    return boost.clamp(0.0, 1.0);
  }

  bool _isAwake(int hour, EnergyProfile p) {
    if (p.sleepHour > p.wakeHour) {
      return hour >= p.wakeHour && hour < p.sleepHour;
    } else {
      return hour >= p.wakeHour || hour < p.sleepHour;
    }
  }

  // ── Window generation ──

  List<EnergyWindow> _buildWindows(List<EnergySignal> signals, EnergyProfile p) {
    final windows = <EnergyWindow>[];
    int? start;
    WindowType? current;

    for (int h = 0; h < 24; h++) {
      if (!_isAwake(h, p)) continue;
      final score = signals[h].energyScore;
      final type = score >= 70
          ? WindowType.deepWork
          : score >= 55
              ? WindowType.lightWork
              : score >= 40
                  ? WindowType.creative
                  : WindowType.rest;

      if (type != current) {
        if (current != null && start != null) {
          windows.add(EnergyWindow(
            startHour: start,
            endHour: h,
            type: current,
            confidence: 0.6 + (signals[start].energyScore / 250),
          ));
        }
        start = h;
        current = type;
      }
    }
    if (current != null && start != null) {
      windows.add(EnergyWindow(
        startHour: start,
        endHour: (start + 1) % 24,
        type: current,
        confidence: 0.7,
      ));
    }
    return windows;
  }

  List<String> _buildRecommendations(
      List<EnergySignal> signals, EnergyProfile p, int peak, int trough) {
    final recs = <String>[];

    recs.add(
        '⚡ Peak energy at ${_fmtHour(peak)} — schedule your hardest tasks here.');

    if (signals[trough].energyScore < 40) {
      recs.add(
          '⚠️ Energy drops to ${signals[trough].energyScore.toStringAsFixed(0)}% '
          'at ${_fmtHour(trough)} — take a 15-min walk or power nap.');
    }

    if (p.caffeineHours.any((h) => h >= 14)) {
      recs.add(
          '☕ Caffeine after 2 PM may disrupt sleep quality. '
          'Consider switching to decaf in the afternoon.');
    }

    if (p.sleepQuality < 0.6) {
      recs.add(
          '😴 Low sleep quality (${(p.sleepQuality * 100).toStringAsFixed(0)}%) '
          'is dragging overall energy. Prioritize sleep hygiene.');
    }

    if (p.activityHours.isEmpty) {
      recs.add(
          '🏃 No exercise detected. A 20-min workout can boost energy for 2-3 hours.');
    }

    final afternoonDip = signals
        .where((s) => s.hour >= 13 && s.hour <= 15)
        .any((s) => s.energyScore < 45);
    if (afternoonDip) {
      recs.add(
          '🌅 Afternoon dip detected (1-3 PM). '
          'Try a light snack or brief outdoor break.');
    }

    return recs;
  }

  String _fmtHour(int h) =>
      '${h % 12 == 0 ? 12 : h % 12}:00 ${h < 12 ? 'AM' : 'PM'}';

  /// Simple exp approximation for dart without dart:math in service layer.
  static double _exp(double x) {
    // Use Taylor series approximation, good enough for our range.
    if (x < -10) return 0.0;
    if (x > 10) return 22026.0;
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }
}
