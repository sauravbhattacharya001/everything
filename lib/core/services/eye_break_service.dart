/// Service for the 20-20-20 Eye Break Reminder.
///
/// The rule: every 20 minutes of screen time, look at something
/// 20 feet away for 20 seconds to reduce eye strain.
class EyeBreakService {
  EyeBreakService._();

  /// Default work interval in minutes.
  static const int defaultWorkMinutes = 20;

  /// Default break duration in seconds.
  static const int defaultBreakSeconds = 20;

  /// Preset work intervals (minutes).
  static const List<int> workPresets = [15, 20, 25, 30, 45, 60];

  /// Preset break durations (seconds).
  static const List<int> breakPresets = [10, 15, 20, 30, 45, 60];

  /// Tips for eye health.
  static const List<String> tips = [
    'Look at something 20 feet (~6 meters) away.',
    'Blink frequently to keep eyes moist.',
    'Adjust screen brightness to match surroundings.',
    'Position your screen at arm\'s length distance.',
    'Use the 20-20-20 rule consistently for best results.',
    'Keep artificial tears handy for dry eyes.',
    'Ensure proper room lighting to reduce glare.',
    'Consider blue-light filtering glasses.',
  ];
}
