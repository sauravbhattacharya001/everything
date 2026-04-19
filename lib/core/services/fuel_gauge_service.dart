import 'dart:math';
import 'package:flutter/material.dart';

// ─── Data Classes ───────────────────────────────────────────────

/// Status levels for fuel gauge dimensions.
enum FuelStatus {
  critical,
  low,
  fair,
  good,
  optimal;

  String get label {
    switch (this) {
      case FuelStatus.critical:
        return 'Critical';
      case FuelStatus.low:
        return 'Low';
      case FuelStatus.fair:
        return 'Fair';
      case FuelStatus.good:
        return 'Good';
      case FuelStatus.optimal:
        return 'Optimal';
    }
  }

  String get emoji {
    switch (this) {
      case FuelStatus.critical:
        return '🔴';
      case FuelStatus.low:
        return '🟠';
      case FuelStatus.fair:
        return '🟡';
      case FuelStatus.good:
        return '🟢';
      case FuelStatus.optimal:
        return '✨';
    }
  }

  Color get color {
    switch (this) {
      case FuelStatus.critical:
        return Colors.red;
      case FuelStatus.low:
        return Colors.orange;
      case FuelStatus.fair:
        return Colors.amber;
      case FuelStatus.good:
        return Colors.lightGreen;
      case FuelStatus.optimal:
        return Colors.green;
    }
  }
}

/// Trend direction comparing to previous reading.
enum FuelTrend {
  up,
  down,
  stable;

  String get emoji {
    switch (this) {
      case FuelTrend.up:
        return '📈';
      case FuelTrend.down:
        return '📉';
      case FuelTrend.stable:
        return '➡️';
    }
  }

  IconData get icon {
    switch (this) {
      case FuelTrend.up:
        return Icons.trending_up;
      case FuelTrend.down:
        return Icons.trending_down;
      case FuelTrend.stable:
        return Icons.trending_flat;
    }
  }
}

/// A single dimension contributing to the overall readiness score.
class FuelDimension {
  final String name;
  final IconData icon;
  final double score;
  final double weight;
  final FuelStatus status;
  final String detail;

  const FuelDimension({
    required this.name,
    required this.icon,
    required this.score,
    required this.weight,
    required this.status,
    required this.detail,
  });
}

/// Complete readiness assessment for a point in time.
class FuelGaugeReading {
  final double overallScore;
  final List<FuelDimension> dimensions;
  final List<String> recommendations;
  final DateTime timestamp;
  final FuelTrend trend;
  final double? trendDelta;

  const FuelGaugeReading({
    required this.overallScore,
    required this.dimensions,
    required this.recommendations,
    required this.timestamp,
    required this.trend,
    this.trendDelta,
  });

  FuelStatus get overallStatus => FuelGaugeService.scoreToStatus(overallScore);
}

// ─── Service ────────────────────────────────────────────────────

/// Generates cross-tracker readiness scores with proactive recommendations.
///
/// Aggregates sleep, hydration, energy, mood, caffeine, and activity data
/// into a single readiness score with per-dimension breakdowns.
class FuelGaugeService {
  /// Convert a 0-100 score to a status level.
  static FuelStatus scoreToStatus(double score) {
    if (score >= 85) return FuelStatus.optimal;
    if (score >= 70) return FuelStatus.good;
    if (score >= 50) return FuelStatus.fair;
    if (score >= 30) return FuelStatus.low;
    return FuelStatus.critical;
  }

  /// Generate a full readiness reading from input dimensions.
  FuelGaugeReading generateReading({
    double? sleepHours,
    int? waterGlasses,
    int? energyLevel,
    int? moodRating,
    int? caffeineCount,
    bool? exercised,
    FuelGaugeReading? yesterday,
  }) {
    final sleep = sleepHours ?? 7.0;
    final water = waterGlasses ?? 4;
    final energy = energyLevel ?? 3;
    final mood = moodRating ?? 3;
    final caffeine = caffeineCount ?? 2;
    final active = exercised ?? false;

    // Calculate individual dimension scores (0-100)
    final sleepScore = _scoreSleep(sleep);
    final waterScore = _scoreWater(water);
    final energyScore = _scoreEnergy(energy);
    final moodScore = _scoreMood(mood);
    final caffeineScore = _scoreCaffeine(caffeine);
    final activityScore = active ? 90.0 : 30.0;

    final dimensions = <FuelDimension>[
      FuelDimension(
        name: 'Sleep',
        icon: Icons.bedtime,
        score: sleepScore,
        weight: 0.25,
        status: scoreToStatus(sleepScore),
        detail: '${sleep.toStringAsFixed(1)}h (ideal: 7-9h)',
      ),
      FuelDimension(
        name: 'Hydration',
        icon: Icons.water_drop,
        score: waterScore,
        weight: 0.20,
        status: scoreToStatus(waterScore),
        detail: '$water glasses (goal: 8)',
      ),
      FuelDimension(
        name: 'Energy',
        icon: Icons.bolt,
        score: energyScore,
        weight: 0.20,
        status: scoreToStatus(energyScore),
        detail: '$energy/5 self-reported',
      ),
      FuelDimension(
        name: 'Mood',
        icon: Icons.mood,
        score: moodScore,
        weight: 0.15,
        status: scoreToStatus(moodScore),
        detail: '$mood/5 rating',
      ),
      FuelDimension(
        name: 'Caffeine',
        icon: Icons.coffee,
        score: caffeineScore,
        weight: 0.10,
        status: scoreToStatus(caffeineScore),
        detail: '$caffeine cups (sweet spot: 1-3)',
      ),
      FuelDimension(
        name: 'Activity',
        icon: Icons.directions_run,
        score: activityScore,
        weight: 0.10,
        status: scoreToStatus(activityScore),
        detail: active ? 'Exercise logged ✓' : 'No exercise yet',
      ),
    ];

    // Weighted overall score
    double overall = 0;
    for (final d in dimensions) {
      overall += d.score * d.weight;
    }
    overall = overall.clamp(0, 100);

    // Recommendations based on low dimensions
    final recs = <String>[];
    if (sleepScore < 60) {
      recs.add(sleep < 6
          ? '😴 Sleep deficit detected — prioritize an early bedtime tonight'
          : '😴 Oversleep can cause grogginess — aim for 7-9 hours');
    }
    if (waterScore < 60) {
      final deficit = max(0, 8 - water);
      recs.add('💧 Under-hydrated — aim for $deficit more glasses before 3 PM');
    }
    if (energyScore < 60) {
      recs.add('⚡ Energy is low — consider a 10-min walk or power nap');
    }
    if (moodScore < 60) {
      recs.add('🌈 Mood dip detected — try a gratitude pause or call a friend');
    }
    if (caffeineScore < 60) {
      recs.add(caffeine > 4
          ? '☕ High caffeine — switch to water to avoid a crash'
          : '☕ Consider a moderate caffeine boost (1-2 cups)');
    }
    if (activityScore < 60) {
      recs.add('🏃 No activity logged — even a short walk improves readiness');
    }
    if (recs.isEmpty) {
      recs.add('🎯 All systems optimal — you\'re firing on all cylinders!');
    }

    // Trend calculation
    FuelTrend trend = FuelTrend.stable;
    double? delta;
    if (yesterday != null) {
      delta = overall - yesterday.overallScore;
      if (delta > 5) {
        trend = FuelTrend.up;
      } else if (delta < -5) {
        trend = FuelTrend.down;
      }
    }

    return FuelGaugeReading(
      overallScore: overall,
      dimensions: dimensions,
      recommendations: recs,
      timestamp: DateTime.now(),
      trend: trend,
      trendDelta: delta,
    );
  }

  double _scoreSleep(double hours) {
    // Bell curve around 7-9 hours
    if (hours >= 7 && hours <= 9) return 95;
    if (hours >= 6 && hours < 7) return 70;
    if (hours >= 9 && hours <= 10) return 75;
    if (hours >= 5 && hours < 6) return 45;
    if (hours > 10) return 50;
    return 20; // <5 hours
  }

  double _scoreWater(int glasses) {
    if (glasses >= 8) return 95;
    if (glasses >= 6) return 80;
    if (glasses >= 4) return 60;
    if (glasses >= 2) return 40;
    return 20;
  }

  double _scoreEnergy(int level) {
    // 1-5 scale → 0-100
    return ((level - 1) / 4 * 80 + 15).clamp(15, 95);
  }

  double _scoreMood(int rating) {
    return ((rating - 1) / 4 * 80 + 15).clamp(15, 95);
  }

  double _scoreCaffeine(int cups) {
    // Sweet spot is 1-3
    if (cups >= 1 && cups <= 3) return 90;
    if (cups == 0) return 60;
    if (cups == 4) return 65;
    if (cups == 5) return 45;
    return 25; // 6+
  }
}
