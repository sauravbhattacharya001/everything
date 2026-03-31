/// Service for calculating optimal sleep and wake times based on
/// 90-minute sleep cycles.
///
/// Sleep occurs in ~90-minute cycles. Waking between cycles (rather
/// than mid-cycle) helps you feel more refreshed. This calculator
/// works in both directions:
///   • Given a wake-up time → suggests bedtimes
///   • Given a bedtime → suggests wake-up times
///
/// It also accounts for the average 14-minute sleep-onset latency.
class SleepCalculatorService {
  SleepCalculatorService._();

  /// Duration of one sleep cycle.
  static const cycleDuration = Duration(minutes: 90);

  /// Average time to fall asleep.
  static const fallAsleepDuration = Duration(minutes: 14);

  /// Recommended number of cycles (3–6, i.e. 4.5–9 hours).
  static const minCycles = 3;
  static const maxCycles = 6;

  /// Given a desired wake-up time, returns suggested bedtimes
  /// (one per cycle count, from most sleep to least).
  static List<SleepSuggestion> bedtimesForWakeUp(DateTime wakeUp) {
    final suggestions = <SleepSuggestion>[];
    for (var cycles = maxCycles; cycles >= minCycles; cycles--) {
      final sleepDuration = cycleDuration * cycles;
      final bedtime = wakeUp.subtract(sleepDuration + fallAsleepDuration);
      suggestions.add(SleepSuggestion(
        time: bedtime,
        cycles: cycles,
        sleepHours: sleepDuration.inMinutes / 60.0,
      ));
    }
    return suggestions;
  }

  /// Given a bedtime, returns suggested wake-up times
  /// (one per cycle count, from least sleep to most).
  static List<SleepSuggestion> wakeTimesForBedtime(DateTime bedtime) {
    final fallAsleep = bedtime.add(fallAsleepDuration);
    final suggestions = <SleepSuggestion>[];
    for (var cycles = minCycles; cycles <= maxCycles; cycles++) {
      final sleepDuration = cycleDuration * cycles;
      final wakeUp = fallAsleep.add(sleepDuration);
      suggestions.add(SleepSuggestion(
        time: wakeUp,
        cycles: cycles,
        sleepHours: sleepDuration.inMinutes / 60.0,
      ));
    }
    return suggestions;
  }

  /// Quality label based on cycle count.
  static String qualityLabel(int cycles) {
    if (cycles >= 6) return 'Ideal';
    if (cycles >= 5) return 'Great';
    if (cycles >= 4) return 'Good';
    return 'Minimum';
  }

  /// Color hint for quality (used by the screen).
  static int qualityColorValue(int cycles) {
    if (cycles >= 6) return 0xFF4CAF50; // green
    if (cycles >= 5) return 0xFF8BC34A; // light green
    if (cycles >= 4) return 0xFFFFC107; // amber
    return 0xFFFF9800; // orange
  }
}

/// A single bedtime or wake-up suggestion.
class SleepSuggestion {
  final DateTime time;
  final int cycles;
  final double sleepHours;

  const SleepSuggestion({
    required this.time,
    required this.cycles,
    required this.sleepHours,
  });
}
