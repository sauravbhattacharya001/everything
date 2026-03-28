/// Service for interval timer (work/rest rounds for workouts, HIIT, etc.).
class IntervalTimerService {
  IntervalTimerService._();

  /// Format seconds as MM:SS.
  static String formatSeconds(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Calculate total workout duration in seconds.
  static int totalDuration({
    required int workSeconds,
    required int restSeconds,
    required int rounds,
    int warmupSeconds = 0,
    int cooldownSeconds = 0,
  }) {
    return warmupSeconds +
        (workSeconds + restSeconds) * rounds -
        restSeconds + // no rest after last round
        cooldownSeconds;
  }

  /// Generate a summary string for a preset.
  static String presetSummary({
    required int workSeconds,
    required int restSeconds,
    required int rounds,
  }) {
    return '${formatSeconds(workSeconds)} work / '
        '${formatSeconds(restSeconds)} rest × $rounds rounds';
  }
}

/// A saved interval timer preset.
class IntervalPreset {
  final String name;
  final int workSeconds;
  final int restSeconds;
  final int rounds;
  final int warmupSeconds;
  final int cooldownSeconds;

  const IntervalPreset({
    required this.name,
    required this.workSeconds,
    required this.restSeconds,
    required this.rounds,
    this.warmupSeconds = 0,
    this.cooldownSeconds = 0,
  });
}

/// Built-in presets for common interval workouts.
class IntervalPresets {
  IntervalPresets._();

  static const List<IntervalPreset> builtIn = [
    IntervalPreset(name: 'Tabata', workSeconds: 20, restSeconds: 10, rounds: 8),
    IntervalPreset(name: 'HIIT 30/30', workSeconds: 30, restSeconds: 30, rounds: 10),
    IntervalPreset(name: 'EMOM', workSeconds: 40, restSeconds: 20, rounds: 10),
    IntervalPreset(name: 'Boxing Rounds', workSeconds: 180, restSeconds: 60, rounds: 5),
    IntervalPreset(name: 'Sprint Intervals', workSeconds: 15, restSeconds: 45, rounds: 8),
  ];
}

/// Current phase of the interval timer.
enum IntervalPhase { idle, warmup, work, rest, cooldown, complete }
