/// Running/cycling pace calculator service.
///
/// Supports three calculation modes:
/// - Given distance + time → pace & speed
/// - Given distance + pace → finish time
/// - Given time + pace → distance
class PaceCalculatorService {
  PaceCalculatorService._();

  /// Common race distances in km.
  static const Map<String, double> raceDistances = {
    '5K': 5.0,
    '10K': 10.0,
    'Half Marathon': 21.0975,
    'Marathon': 42.195,
    '50K Ultra': 50.0,
    '100K Ultra': 100.0,
  };

  /// Calculate pace (min/km or min/mi) and speed from distance + time.
  static PaceResult fromDistanceAndTime({
    required double distanceKm,
    required Duration totalTime,
    bool useMiles = false,
  }) {
    final distanceUnit = useMiles ? distanceKm / 1.60934 : distanceKm;
    final totalMinutes = totalTime.inSeconds / 60.0;
    final paceMinPerUnit = totalMinutes / distanceUnit;
    final speedKmh = distanceKm / (totalTime.inSeconds / 3600.0);
    final speedMph = speedKmh / 1.60934;

    return PaceResult(
      distanceKm: distanceKm,
      totalTime: totalTime,
      paceMinPerUnit: paceMinPerUnit,
      speedKmh: speedKmh,
      speedMph: speedMph,
      useMiles: useMiles,
    );
  }

  /// Calculate finish time from distance + pace.
  static PaceResult fromDistanceAndPace({
    required double distanceKm,
    required double paceMinPerUnit,
    bool useMiles = false,
  }) {
    final distanceUnit = useMiles ? distanceKm / 1.60934 : distanceKm;
    final totalMinutes = paceMinPerUnit * distanceUnit;
    final totalTime = Duration(seconds: (totalMinutes * 60).round());
    final speedKmh = distanceKm / (totalTime.inSeconds / 3600.0);
    final speedMph = speedKmh / 1.60934;

    return PaceResult(
      distanceKm: distanceKm,
      totalTime: totalTime,
      paceMinPerUnit: paceMinPerUnit,
      speedKmh: speedKmh,
      speedMph: speedMph,
      useMiles: useMiles,
    );
  }

  /// Calculate distance from time + pace.
  static PaceResult fromTimeAndPace({
    required Duration totalTime,
    required double paceMinPerUnit,
    bool useMiles = false,
  }) {
    final totalMinutes = totalTime.inSeconds / 60.0;
    final distanceUnit = totalMinutes / paceMinPerUnit;
    final distanceKm = useMiles ? distanceUnit * 1.60934 : distanceUnit;
    final speedKmh = distanceKm / (totalTime.inSeconds / 3600.0);
    final speedMph = speedKmh / 1.60934;

    return PaceResult(
      distanceKm: distanceKm,
      totalTime: totalTime,
      paceMinPerUnit: paceMinPerUnit,
      speedKmh: speedKmh,
      speedMph: speedMph,
      useMiles: useMiles,
    );
  }

  /// Generate a race-day split table for even pacing.
  static List<SplitEntry> generateSplits({
    required double distanceKm,
    required Duration totalTime,
    double splitEveryKm = 1.0,
    bool useMiles = false,
  }) {
    final splitEvery = useMiles ? splitEveryKm * 1.60934 : splitEveryKm;
    final splits = <SplitEntry>[];
    final paceSecsPerKm = totalTime.inSeconds / distanceKm;
    var remaining = distanceKm;
    var elapsed = 0.0;

    while (remaining > 0.01) {
      final segmentKm = remaining >= splitEvery ? splitEvery : remaining;
      final segmentSecs = paceSecsPerKm * segmentKm;
      elapsed += segmentSecs;
      remaining -= segmentKm;
      final segmentDisplay = useMiles ? segmentKm / 1.60934 : segmentKm;
      splits.add(SplitEntry(
        splitNumber: splits.length + 1,
        distance: segmentDisplay,
        elapsedTime: Duration(seconds: elapsed.round()),
        splitTime: Duration(seconds: segmentSecs.round()),
      ));
    }
    return splits;
  }

  /// Format pace as "M:SS".
  static String formatPace(double paceMinPerUnit) {
    final mins = paceMinPerUnit.floor();
    final secs = ((paceMinPerUnit - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Format duration as "H:MM:SS" or "MM:SS".
  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class PaceResult {
  final double distanceKm;
  final Duration totalTime;
  final double paceMinPerUnit;
  final double speedKmh;
  final double speedMph;
  final bool useMiles;

  const PaceResult({
    required this.distanceKm,
    required this.totalTime,
    required this.paceMinPerUnit,
    required this.speedKmh,
    required this.speedMph,
    required this.useMiles,
  });

  String get unitLabel => useMiles ? 'mi' : 'km';
  double get displayDistance => useMiles ? distanceKm / 1.60934 : distanceKm;
  double get displaySpeed => useMiles ? speedMph : speedKmh;
}

class SplitEntry {
  final int splitNumber;
  final double distance;
  final Duration elapsedTime;
  final Duration splitTime;

  const SplitEntry({
    required this.splitNumber,
    required this.distance,
    required this.elapsedTime,
    required this.splitTime,
  });
}
