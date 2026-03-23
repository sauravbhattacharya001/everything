import 'dart:convert';

/// A breathing pattern defines the phases and timing of a breathing exercise.
enum BreathingPattern {
  boxBreathing,
  relaxing478,
  energizing,
  calming,
  deepBreath,
  custom;

  String get label {
    switch (this) {
      case BreathingPattern.boxBreathing:
        return 'Box Breathing';
      case BreathingPattern.relaxing478:
        return '4-7-8 Relaxing';
      case BreathingPattern.energizing:
        return 'Energizing';
      case BreathingPattern.calming:
        return 'Calming';
      case BreathingPattern.deepBreath:
        return 'Deep Breath';
      case BreathingPattern.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case BreathingPattern.boxBreathing:
        return 'Equal inhale, hold, exhale, hold. Great for focus and calm.';
      case BreathingPattern.relaxing478:
        return 'Inhale 4s, hold 7s, exhale 8s. Promotes deep relaxation.';
      case BreathingPattern.energizing:
        return 'Quick inhale, short hold, quick exhale. Boosts alertness.';
      case BreathingPattern.calming:
        return 'Long inhale, gentle exhale. Activates parasympathetic system.';
      case BreathingPattern.deepBreath:
        return 'Slow deep inhale and exhale. Simple and effective.';
      case BreathingPattern.custom:
        return 'Your own custom breathing pattern.';
    }
  }

  String get emoji {
    switch (this) {
      case BreathingPattern.boxBreathing:
        return '📦';
      case BreathingPattern.relaxing478:
        return '😌';
      case BreathingPattern.energizing:
        return '⚡';
      case BreathingPattern.calming:
        return '🌊';
      case BreathingPattern.deepBreath:
        return '🫁';
      case BreathingPattern.custom:
        return '⚙️';
    }
  }

  /// Phase durations in seconds: [inhale, holdAfterInhale, exhale, holdAfterExhale].
  List<int> get defaultPhases {
    switch (this) {
      case BreathingPattern.boxBreathing:
        return [4, 4, 4, 4];
      case BreathingPattern.relaxing478:
        return [4, 7, 8, 0];
      case BreathingPattern.energizing:
        return [2, 1, 2, 0];
      case BreathingPattern.calming:
        return [6, 0, 8, 0];
      case BreathingPattern.deepBreath:
        return [5, 2, 5, 0];
      case BreathingPattern.custom:
        return [4, 4, 4, 4];
    }
  }
}

/// The four phases of a breathing cycle.
enum BreathPhase {
  inhale,
  holdIn,
  exhale,
  holdOut;

  String get label {
    switch (this) {
      case BreathPhase.inhale:
        return 'Breathe In';
      case BreathPhase.holdIn:
        return 'Hold';
      case BreathPhase.exhale:
        return 'Breathe Out';
      case BreathPhase.holdOut:
        return 'Hold';
    }
  }

  String get emoji {
    switch (this) {
      case BreathPhase.inhale:
        return '🌬️';
      case BreathPhase.holdIn:
        return '⏸️';
      case BreathPhase.exhale:
        return '💨';
      case BreathPhase.holdOut:
        return '⏸️';
    }
  }
}

/// A completed breathing session log entry.
class BreathingSessionEntry {
  final String id;
  final DateTime timestamp;
  final BreathingPattern pattern;
  final int cyclesCompleted;
  final int totalDurationSeconds;
  final String? note;

  const BreathingSessionEntry({
    required this.id,
    required this.timestamp,
    required this.pattern,
    required this.cyclesCompleted,
    required this.totalDurationSeconds,
    this.note,
  });

  BreathingSessionEntry copyWith({
    String? id,
    DateTime? timestamp,
    BreathingPattern? pattern,
    int? cyclesCompleted,
    int? totalDurationSeconds,
    String? note,
  }) {
    return BreathingSessionEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      pattern: pattern ?? this.pattern,
      cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'pattern': pattern.name,
      'cyclesCompleted': cyclesCompleted,
      'totalDurationSeconds': totalDurationSeconds,
      'note': note,
    };
  }

  factory BreathingSessionEntry.fromJson(Map<String, dynamic> json) {
    return BreathingSessionEntry(
      id: json['id'] as String,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      pattern: BreathingPattern.values.firstWhere(
        (v) => v.name == json['pattern'],
        orElse: () => BreathingPattern.boxBreathing,
      ),
      cyclesCompleted: json['cyclesCompleted'] as int? ?? 0,
      totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 0,
      note: json['note'] as String?,
    );
  }

  static String encodeList(List<BreathingSessionEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<BreathingSessionEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => BreathingSessionEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Weekly breathing stats.
class BreathingWeeklyStats {
  final int totalSessions;
  final int totalMinutes;
  final int totalCycles;
  final Map<BreathingPattern, int> byPattern;
  final int currentStreak; // consecutive days with at least one session

  const BreathingWeeklyStats({
    required this.totalSessions,
    required this.totalMinutes,
    required this.totalCycles,
    required this.byPattern,
    required this.currentStreak,
  });
}

/// Service for breathing exercise logic, stats, and session history.
class BreathingExerciseService {
  const BreathingExerciseService();

  /// Get the active phases for a pattern (skips 0-duration phases).
  List<MapEntry<BreathPhase, int>> getActivePhases(BreathingPattern pattern) {
    final durations = pattern.defaultPhases;
    final phases = <MapEntry<BreathPhase, int>>[];
    if (durations[0] > 0) {
      phases.add(MapEntry(BreathPhase.inhale, durations[0]));
    }
    if (durations[1] > 0) {
      phases.add(MapEntry(BreathPhase.holdIn, durations[1]));
    }
    if (durations[2] > 0) {
      phases.add(MapEntry(BreathPhase.exhale, durations[2]));
    }
    if (durations[3] > 0) {
      phases.add(MapEntry(BreathPhase.holdOut, durations[3]));
    }
    return phases;
  }

  /// Total seconds for one full cycle of a pattern.
  int cycleDurationSeconds(BreathingPattern pattern) {
    return pattern.defaultPhases.fold(0, (a, b) => a + b);
  }

  /// Compute weekly stats from session entries.
  BreathingWeeklyStats weeklyStats(
      List<BreathingSessionEntry> entries, DateTime today) {
    final weekAgo = today.subtract(const Duration(days: 7));
    final weekEntries = entries
        .where((e) => e.timestamp.isAfter(weekAgo))
        .toList();

    final byPattern = <BreathingPattern, int>{};
    int totalCycles = 0;
    int totalSeconds = 0;

    for (final e in weekEntries) {
      byPattern[e.pattern] = (byPattern[e.pattern] ?? 0) + 1;
      totalCycles += e.cyclesCompleted;
      totalSeconds += e.totalDurationSeconds;
    }

    // Current streak: consecutive days with a session, walking back from today
    final daySet = <String>{};
    for (final e in entries) {
      daySet.add(_dateKey(e.timestamp));
    }
    int streak = 0;
    var day = DateTime(today.year, today.month, today.day);
    while (daySet.contains(_dateKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    return BreathingWeeklyStats(
      totalSessions: weekEntries.length,
      totalMinutes: (totalSeconds / 60).round(),
      totalCycles: totalCycles,
      byPattern: byPattern,
      currentStreak: streak,
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
