/// Model classes for the Commute Tracker feature.

/// Mode of transportation.
enum CommuteMode {
  car('Car', '🚗', 0.21),
  bus('Bus', '🚌', 0.089),
  train('Train', '🚆', 0.041),
  subway('Subway', '🚇', 0.036),
  bike('Bike', '🚲', 0.0),
  walk('Walk', '🚶', 0.0),
  scooter('Scooter', '🛴', 0.035),
  carpool('Carpool', '🚙', 0.108),
  motorcycle('Motorcycle', '🏍️', 0.113),
  workFromHome('Work from Home', '🏠', 0.0);

  /// Label for display.
  final String label;
  /// Emoji icon.
  final String emoji;
  /// kg CO₂ per km (average estimates).
  final double co2PerKm;
  const CommuteMode(this.label, this.emoji, this.co2PerKm);
}

/// Comfort rating for a commute.
enum CommuteComfort {
  terrible(1, 'Terrible', '😫'),
  poor(2, 'Poor', '😟'),
  okay(3, 'Okay', '😐'),
  good(4, 'Good', '🙂'),
  great(5, 'Great', '😊');

  final int value;
  final String label;
  final String emoji;
  const CommuteComfort(this.value, this.label, this.emoji);
}

/// A single commute entry.
class CommuteEntry {
  final String id;
  final DateTime date;
  final CommuteMode mode;
  final int durationMinutes;
  final double? distanceKm;
  final double? cost;
  final CommuteComfort? comfort;
  final String? notes;
  final bool isReturn;

  const CommuteEntry({
    required this.id,
    required this.date,
    required this.mode,
    required this.durationMinutes,
    this.distanceKm,
    this.cost,
    this.comfort,
    this.notes,
    this.isReturn = false,
  });

  /// Estimated CO₂ emissions in kg.
  double get co2Kg => (distanceKm ?? 0) * mode.co2PerKm;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'mode': mode.name,
    'durationMinutes': durationMinutes,
    'distanceKm': distanceKm,
    'cost': cost,
    'comfort': comfort?.name,
    'notes': notes,
    'isReturn': isReturn,
  };

  factory CommuteEntry.fromJson(Map<String, dynamic> json) => CommuteEntry(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    mode: CommuteMode.values.firstWhere((m) => m.name == json['mode']),
    durationMinutes: json['durationMinutes'] as int,
    distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    cost: (json['cost'] as num?)?.toDouble(),
    comfort: json['comfort'] != null
        ? CommuteComfort.values.firstWhere((c) => c.name == json['comfort'])
        : null,
    notes: json['notes'] as String?,
    isReturn: json['isReturn'] as bool? ?? false,
  );

  CommuteEntry copyWith({
    DateTime? date,
    CommuteMode? mode,
    int? durationMinutes,
    double? distanceKm,
    double? cost,
    CommuteComfort? comfort,
    String? notes,
    bool? isReturn,
  }) {
    return CommuteEntry(
      id: id,
      date: date ?? this.date,
      mode: mode ?? this.mode,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      cost: cost ?? this.cost,
      comfort: comfort ?? this.comfort,
      notes: notes ?? this.notes,
      isReturn: isReturn ?? this.isReturn,
    );
  }
}

/// Weekly commute summary.
class CommuteWeeklySummary {
  final DateTime weekStart;
  final int totalTrips;
  final int totalMinutes;
  final double totalDistanceKm;
  final double totalCost;
  final double totalCo2Kg;
  final Map<CommuteMode, int> modeBreakdown;
  final double avgComfort;

  const CommuteWeeklySummary({
    required this.weekStart,
    required this.totalTrips,
    required this.totalMinutes,
    required this.totalDistanceKm,
    required this.totalCost,
    required this.totalCo2Kg,
    required this.modeBreakdown,
    required this.avgComfort,
  });
}

/// Monthly commute insights.
class CommuteMonthlyInsight {
  final String label;
  final String value;
  final String? comparison;
  final String emoji;

  const CommuteMonthlyInsight({
    required this.label,
    required this.value,
    this.comparison,
    required this.emoji,
  });
}
