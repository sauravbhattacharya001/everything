import 'dart:convert';

/// Energy levels from 1 (exhausted) to 5 (peak).
enum EnergyLevel {
  exhausted,
  low,
  moderate,
  high,
  peak;

  String get label {
    switch (this) {
      case EnergyLevel.exhausted:
        return 'Exhausted';
      case EnergyLevel.low:
        return 'Low';
      case EnergyLevel.moderate:
        return 'Moderate';
      case EnergyLevel.high:
        return 'High';
      case EnergyLevel.peak:
        return 'Peak';
    }
  }

  String get emoji {
    switch (this) {
      case EnergyLevel.exhausted:
        return '🪫';
      case EnergyLevel.low:
        return '😴';
      case EnergyLevel.moderate:
        return '⚡';
      case EnergyLevel.high:
        return '🔋';
      case EnergyLevel.peak:
        return '🚀';
    }
  }

  int get value {
    switch (this) {
      case EnergyLevel.exhausted:
        return 1;
      case EnergyLevel.low:
        return 2;
      case EnergyLevel.moderate:
        return 3;
      case EnergyLevel.high:
        return 4;
      case EnergyLevel.peak:
        return 5;
    }
  }

  static EnergyLevel fromValue(int value) {
    switch (value) {
      case 1:
        return EnergyLevel.exhausted;
      case 2:
        return EnergyLevel.low;
      case 3:
        return EnergyLevel.moderate;
      case 4:
        return EnergyLevel.high;
      case 5:
        return EnergyLevel.peak;
      default:
        return EnergyLevel.moderate;
    }
  }
}

/// Time-of-day slots for energy tracking.
enum TimeSlot {
  earlyMorning,
  morning,
  midday,
  afternoon,
  evening,
  night;

  String get label {
    switch (this) {
      case TimeSlot.earlyMorning:
        return 'Early Morning';
      case TimeSlot.morning:
        return 'Morning';
      case TimeSlot.midday:
        return 'Midday';
      case TimeSlot.afternoon:
        return 'Afternoon';
      case TimeSlot.evening:
        return 'Evening';
      case TimeSlot.night:
        return 'Night';
    }
  }

  String get emoji {
    switch (this) {
      case TimeSlot.earlyMorning:
        return '🌅';
      case TimeSlot.morning:
        return '☀️';
      case TimeSlot.midday:
        return '🌤️';
      case TimeSlot.afternoon:
        return '🌇';
      case TimeSlot.evening:
        return '🌆';
      case TimeSlot.night:
        return '🌙';
    }
  }

  /// Hour range for this slot (inclusive start, exclusive end).
  List<int> get hourRange {
    switch (this) {
      case TimeSlot.earlyMorning:
        return [5, 8];
      case TimeSlot.morning:
        return [8, 11];
      case TimeSlot.midday:
        return [11, 14];
      case TimeSlot.afternoon:
        return [14, 17];
      case TimeSlot.evening:
        return [17, 21];
      case TimeSlot.night:
        return [21, 5]; // wraps: 21-23 and 0-4
    }
  }

  /// Determine the time slot for a given hour (0-23).
  static TimeSlot fromHour(int hour) {
    if (hour >= 5 && hour < 8) return TimeSlot.earlyMorning;
    if (hour >= 8 && hour < 11) return TimeSlot.morning;
    if (hour >= 11 && hour < 14) return TimeSlot.midday;
    if (hour >= 14 && hour < 17) return TimeSlot.afternoon;
    if (hour >= 17 && hour < 21) return TimeSlot.evening;
    return TimeSlot.night;
  }
}

/// Factors that may influence energy level.
enum EnergyFactor {
  caffeine,
  exercise,
  meal,
  nap,
  meditation,
  stress,
  screenTime,
  socializing,
  outdoors,
  hydration,
  sugar,
  alcohol;

  String get label {
    switch (this) {
      case EnergyFactor.caffeine:
        return 'Caffeine';
      case EnergyFactor.exercise:
        return 'Exercise';
      case EnergyFactor.meal:
        return 'Meal';
      case EnergyFactor.nap:
        return 'Nap';
      case EnergyFactor.meditation:
        return 'Meditation';
      case EnergyFactor.stress:
        return 'Stress';
      case EnergyFactor.screenTime:
        return 'Screen Time';
      case EnergyFactor.socializing:
        return 'Socializing';
      case EnergyFactor.outdoors:
        return 'Outdoors';
      case EnergyFactor.hydration:
        return 'Hydration';
      case EnergyFactor.sugar:
        return 'Sugar';
      case EnergyFactor.alcohol:
        return 'Alcohol';
    }
  }

  String get emoji {
    switch (this) {
      case EnergyFactor.caffeine:
        return '☕';
      case EnergyFactor.exercise:
        return '🏃';
      case EnergyFactor.meal:
        return '🍽️';
      case EnergyFactor.nap:
        return '💤';
      case EnergyFactor.meditation:
        return '🧘';
      case EnergyFactor.stress:
        return '😰';
      case EnergyFactor.screenTime:
        return '📱';
      case EnergyFactor.socializing:
        return '👥';
      case EnergyFactor.outdoors:
        return '🌳';
      case EnergyFactor.hydration:
        return '💧';
      case EnergyFactor.sugar:
        return '🍬';
      case EnergyFactor.alcohol:
        return '🍷';
    }
  }
}

/// A single energy level log entry.
class EnergyEntry {
  final String id;
  final DateTime timestamp;
  final EnergyLevel level;
  final String? note;
  final List<EnergyFactor> factors;

  const EnergyEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    this.note,
    this.factors = const [],
  });

  /// Convenience: which time slot this entry falls in.
  TimeSlot get timeSlot => TimeSlot.fromHour(timestamp.hour);

  EnergyEntry copyWith({
    String? id,
    DateTime? timestamp,
    EnergyLevel? level,
    String? note,
    List<EnergyFactor>? factors,
  }) {
    return EnergyEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      level: level ?? this.level,
      note: note ?? this.note,
      factors: factors ?? this.factors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.value,
      'note': note,
      'factors': factors.map((f) => f.name).toList(),
    };
  }

  factory EnergyEntry.fromJson(Map<String, dynamic> json) {
    return EnergyEntry(
      id: json['id'] as String,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      level: EnergyLevel.fromValue(json['level'] as int),
      note: json['note'] as String?,
      factors: (json['factors'] as List<dynamic>?)
              ?.map((f) => EnergyFactor.values.firstWhere(
                    (v) => v.name == f,
                    orElse: () => EnergyFactor.caffeine,
                  ))
              .toList() ??
          [],
    );
  }

  static String encodeList(List<EnergyEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<EnergyEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => EnergyEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
