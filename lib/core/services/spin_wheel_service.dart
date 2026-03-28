import 'dart:math';

/// A single spin result.
class SpinResult {
  final String option;
  final DateTime timestamp;

  SpinResult({required this.option, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

/// Preset wheel configurations.
class WheelPreset {
  final String name;
  final List<String> options;

  const WheelPreset({required this.name, required this.options});
}

/// Service that manages wheel options, spinning, and history.
class SpinWheelService {
  final _random = Random();
  final List<String> _options = [];
  final List<SpinResult> _history = [];

  List<String> get options => List.unmodifiable(_options);
  List<SpinResult> get history => List.unmodifiable(_history);

  static const List<WheelPreset> presets = [
    WheelPreset(name: 'Yes / No', options: ['Yes', 'No']),
    WheelPreset(name: 'Yes / No / Maybe', options: ['Yes', 'No', 'Maybe']),
    WheelPreset(
      name: 'Weekdays',
      options: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    ),
    WheelPreset(
      name: 'Meal Type',
      options: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'],
    ),
    WheelPreset(
      name: 'Priority',
      options: ['High', 'Medium', 'Low'],
    ),
    WheelPreset(
      name: 'Dice (1-6)',
      options: ['1', '2', '3', '4', '5', '6'],
    ),
  ];

  void addOption(String option) {
    final trimmed = option.trim();
    if (trimmed.isNotEmpty) _options.add(trimmed);
  }

  void removeOption(int index) {
    if (index >= 0 && index < _options.length) _options.removeAt(index);
  }

  void clearOptions() => _options.clear();

  void loadPreset(WheelPreset preset) {
    _options.clear();
    _options.addAll(preset.options);
  }

  /// Spin the wheel and return a random option.
  /// Returns null if no options available.
  SpinResult? spin() {
    if (_options.isEmpty) return null;
    final choice = _options[_random.nextInt(_options.length)];
    final result = SpinResult(option: choice);
    _history.add(result);
    return result;
  }

  void clearHistory() => _history.clear();

  /// Get frequency map of results.
  Map<String, int> getFrequencies() {
    final freq = <String, int>{};
    for (final r in _history) {
      freq[r.option] = (freq[r.option] ?? 0) + 1;
    }
    return freq;
  }
}
