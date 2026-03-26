/// Chess clock service supporting multiple time control modes.
class ChessClockService {
  ChessClockService._();

  /// Available preset time controls.
  static const List<TimeControl> presets = [
    TimeControl(name: 'Bullet 1+0', minutes: 1, increment: 0),
    TimeControl(name: 'Bullet 2+1', minutes: 2, increment: 1),
    TimeControl(name: 'Blitz 3+0', minutes: 3, increment: 0),
    TimeControl(name: 'Blitz 3+2', minutes: 3, increment: 2),
    TimeControl(name: 'Blitz 5+0', minutes: 5, increment: 0),
    TimeControl(name: 'Blitz 5+3', minutes: 5, increment: 3),
    TimeControl(name: 'Rapid 10+0', minutes: 10, increment: 0),
    TimeControl(name: 'Rapid 10+5', minutes: 10, increment: 5),
    TimeControl(name: 'Rapid 15+10', minutes: 15, increment: 10),
    TimeControl(name: 'Classical 30+0', minutes: 30, increment: 0),
    TimeControl(name: 'Classical 60+30', minutes: 60, increment: 30),
  ];

  /// Format remaining time as M:SS or H:MM:SS, with tenths when < 10s.
  static String formatTime(Duration d) {
    if (d.isNegative) return '0:00';
    final totalSeconds = d.inSeconds;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = totalSeconds.remainder(60);

    if (totalSeconds < 10) {
      final tenths = (d.inMilliseconds.remainder(1000) ~/ 100);
      return '0:${seconds.toString().padLeft(2, '0')}.$tenths';
    }
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// A time control configuration.
class TimeControl {
  final String name;
  final int minutes;
  final int increment; // seconds added after each move

  const TimeControl({
    required this.name,
    required this.minutes,
    required this.increment,
  });

  Duration get initialDuration => Duration(minutes: minutes);
}
