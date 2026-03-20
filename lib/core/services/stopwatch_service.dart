/// Stopwatch service with lap tracking, split times, and session history.
class StopwatchService {
  StopwatchService._();

  /// Format duration as HH:MM:SS.cc (centiseconds).
  static String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    final centis = (d.inMilliseconds.remainder(1000) ~/ 10);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}.'
          '${centis.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${centis.toString().padLeft(2, '0')}';
  }

  /// Format a compact duration for lap deltas.
  static String formatCompact(Duration d) {
    final totalSecs = d.inMilliseconds / 1000.0;
    if (totalSecs < 60) return '+${totalSecs.toStringAsFixed(2)}s';
    return '+${formatDuration(d)}';
  }

  /// Calculate statistics for a list of lap durations.
  static LapStats? calculateStats(List<Duration> laps) {
    if (laps.isEmpty) return null;
    final sorted = List<Duration>.from(laps)
      ..sort((a, b) => a.compareTo(b));
    final totalMs = laps.fold<int>(0, (s, d) => s + d.inMilliseconds);
    final avgMs = totalMs ~/ laps.length;
    return LapStats(
      fastest: sorted.first,
      slowest: sorted.last,
      average: Duration(milliseconds: avgMs),
      total: Duration(milliseconds: totalMs),
      count: laps.length,
    );
  }
}

/// Result of lap statistics computation.
class LapStats {
  final Duration fastest;
  final Duration slowest;
  final Duration average;
  final Duration total;
  final int count;

  const LapStats({
    required this.fastest,
    required this.slowest,
    required this.average,
    required this.total,
    required this.count,
  });
}

/// A single recorded lap.
class LapRecord {
  final int number;
  final Duration splitTime;  // time since start
  final Duration lapTime;    // time since previous lap

  const LapRecord({
    required this.number,
    required this.splitTime,
    required this.lapTime,
  });
}
