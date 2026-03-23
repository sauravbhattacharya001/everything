/// Service for managing multiple named tally counters with history.
class TallyCounterService {
  TallyCounterService._();

  /// Preset counter templates for common use cases.
  static const List<String> presets = [
    'People',
    'Reps',
    'Laps',
    'Items',
    'Score',
    'Inventory',
    'Visitors',
    'Birds',
  ];
}

/// A single tally counter with name, count, and optional target.
class TallyCounter {
  final String name;
  int count;
  final int? target;
  final int step;
  final DateTime createdAt;

  TallyCounter({
    required this.name,
    this.count = 0,
    this.target,
    this.step = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  void increment() => count += step;

  void decrement() {
    count = (count - step).clamp(0, double.maxFinite.toInt());
  }

  void reset() => count = 0;

  double? get progress =>
      target != null && target! > 0 ? (count / target!).clamp(0.0, 1.0) : null;

  bool get targetReached => target != null && count >= target!;

  Map<String, dynamic> toJson() => {
        'name': name,
        'count': count,
        'target': target,
        'step': step,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TallyCounter.fromJson(Map<String, dynamic> json) => TallyCounter(
        name: json['name'] as String,
        count: json['count'] as int? ?? 0,
        target: json['target'] as int?,
        step: json['step'] as int? ?? 1,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
