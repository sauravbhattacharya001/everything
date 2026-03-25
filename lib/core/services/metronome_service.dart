/// Metronome service — provides tempo tracking, tap-tempo detection,
/// and common time-signature presets.
class MetronomeService {
  /// Standard tempo presets (name → BPM).
  static const Map<String, int> presets = {
    'Largo': 50,
    'Adagio': 70,
    'Andante': 92,
    'Moderato': 112,
    'Allegro': 132,
    'Vivace': 160,
    'Presto': 184,
  };

  final List<DateTime> _tapTimestamps = [];

  /// Register a tap and return the detected BPM (or null if < 2 taps).
  /// Resets if gap > 2 seconds.
  int? tap() {
    final now = DateTime.now();
    if (_tapTimestamps.isNotEmpty &&
        now.difference(_tapTimestamps.last).inMilliseconds > 2000) {
      _tapTimestamps.clear();
    }
    _tapTimestamps.add(now);
    if (_tapTimestamps.length < 2) return null;

    // Keep only last 8 taps for a stable average.
    if (_tapTimestamps.length > 8) {
      _tapTimestamps.removeAt(0);
    }

    double totalMs = 0;
    for (int i = 1; i < _tapTimestamps.length; i++) {
      totalMs += _tapTimestamps[i]
          .difference(_tapTimestamps[i - 1])
          .inMilliseconds;
    }
    final avgMs = totalMs / (_tapTimestamps.length - 1);
    return (60000 / avgMs).round().clamp(20, 300);
  }

  void resetTap() => _tapTimestamps.clear();

  /// Milliseconds per beat for a given BPM.
  static int msPerBeat(int bpm) => (60000 / bpm).round();

  /// Subdivisions: returns ms offsets within one beat for n subdivisions.
  static List<int> subdivisionOffsets(int bpm, int subdivisions) {
    final beat = msPerBeat(bpm);
    return List.generate(
        subdivisions, (i) => (beat * i / subdivisions).round());
  }
}
