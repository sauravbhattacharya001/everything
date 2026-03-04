import 'dart:convert';

/// Sleep quality rating from 1 (terrible) to 5 (excellent).
enum SleepQuality {
  terrible,
  poor,
  fair,
  good,
  excellent;

  String get label {
    switch (this) {
      case SleepQuality.terrible:
        return 'Terrible';
      case SleepQuality.poor:
        return 'Poor';
      case SleepQuality.fair:
        return 'Fair';
      case SleepQuality.good:
        return 'Good';
      case SleepQuality.excellent:
        return 'Excellent';
    }
  }

  String get emoji {
    switch (this) {
      case SleepQuality.terrible:
        return '😫';
      case SleepQuality.poor:
        return '😴';
      case SleepQuality.fair:
        return '😐';
      case SleepQuality.good:
        return '😊';
      case SleepQuality.excellent:
        return '🌟';
    }
  }

  int get value {
    switch (this) {
      case SleepQuality.terrible:
        return 1;
      case SleepQuality.poor:
        return 2;
      case SleepQuality.fair:
        return 3;
      case SleepQuality.good:
        return 4;
      case SleepQuality.excellent:
        return 5;
    }
  }

  static SleepQuality fromValue(int value) {
    switch (value) {
      case 1:
        return SleepQuality.terrible;
      case 2:
        return SleepQuality.poor;
      case 3:
        return SleepQuality.fair;
      case 4:
        return SleepQuality.good;
      case 5:
        return SleepQuality.excellent;
      default:
        return SleepQuality.fair;
    }
  }
}

/// Factors that can affect sleep quality.
enum SleepFactor {
  caffeine,
  alcohol,
  exercise,
  screenTime,
  stress,
  lateNight,
  nap,
  meditation,
  reading,
  noise,
  temperature,
  travel;

  String get label {
    switch (this) {
      case SleepFactor.caffeine:
        return 'Caffeine';
      case SleepFactor.alcohol:
        return 'Alcohol';
      case SleepFactor.exercise:
        return 'Exercise';
      case SleepFactor.screenTime:
        return 'Screen Time';
      case SleepFactor.stress:
        return 'Stress';
      case SleepFactor.lateNight:
        return 'Late Night';
      case SleepFactor.nap:
        return 'Daytime Nap';
      case SleepFactor.meditation:
        return 'Meditation';
      case SleepFactor.reading:
        return 'Reading';
      case SleepFactor.noise:
        return 'Noise';
      case SleepFactor.temperature:
        return 'Temperature';
      case SleepFactor.travel:
        return 'Travel';
    }
  }

  String get emoji {
    switch (this) {
      case SleepFactor.caffeine:
        return '☕';
      case SleepFactor.alcohol:
        return '🍷';
      case SleepFactor.exercise:
        return '🏋️';
      case SleepFactor.screenTime:
        return '📱';
      case SleepFactor.stress:
        return '😰';
      case SleepFactor.lateNight:
        return '🌙';
      case SleepFactor.nap:
        return '💤';
      case SleepFactor.meditation:
        return '🧘';
      case SleepFactor.reading:
        return '📖';
      case SleepFactor.noise:
        return '🔊';
      case SleepFactor.temperature:
        return '🌡️';
      case SleepFactor.travel:
        return '✈️';
    }
  }
}

/// A single sleep log entry.
class SleepEntry {
  final String id;
  final DateTime bedtime;
  final DateTime wakeTime;
  final SleepQuality quality;
  final String? note;
  final List<SleepFactor> factors;
  final int? awakenings; // number of times woken during the night

  const SleepEntry({
    required this.id,
    required this.bedtime,
    required this.wakeTime,
    required this.quality,
    this.note,
    this.factors = const [],
    this.awakenings,
  });

  /// Total sleep duration in hours.
  double get durationHours {
    final diff = wakeTime.difference(bedtime);
    return diff.inMinutes / 60.0;
  }

  /// Total sleep duration as Duration.
  Duration get duration => wakeTime.difference(bedtime);

  /// Formatted duration string, e.g., "7h 30m".
  String get durationFormatted {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// The date this entry belongs to (based on wake time).
  DateTime get date => DateTime(wakeTime.year, wakeTime.month, wakeTime.day);

  SleepEntry copyWith({
    String? id,
    DateTime? bedtime,
    DateTime? wakeTime,
    SleepQuality? quality,
    String? note,
    List<SleepFactor>? factors,
    int? awakenings,
  }) {
    return SleepEntry(
      id: id ?? this.id,
      bedtime: bedtime ?? this.bedtime,
      wakeTime: wakeTime ?? this.wakeTime,
      quality: quality ?? this.quality,
      note: note ?? this.note,
      factors: factors ?? this.factors,
      awakenings: awakenings ?? this.awakenings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bedtime': bedtime.toIso8601String(),
      'wakeTime': wakeTime.toIso8601String(),
      'quality': quality.value,
      'note': note,
      'factors': factors.map((f) => f.name).toList(),
      'awakenings': awakenings,
    };
  }

  factory SleepEntry.fromJson(Map<String, dynamic> json) {
    return SleepEntry(
      id: json['id'] as String,
      bedtime: DateTime.tryParse(json['bedtime'] as String? ?? '') ?? DateTime.now(),
      wakeTime: DateTime.tryParse(json['wakeTime'] as String? ?? '') ?? DateTime.now(),
      quality: SleepQuality.fromValue(json['quality'] as int),
      note: json['note'] as String?,
      factors: (json['factors'] as List<dynamic>?)
              ?.map((f) => SleepFactor.values.firstWhere(
                    (v) => v.name == f,
                    orElse: () => SleepFactor.stress,
                  ))
              .toList() ??
          [],
      awakenings: json['awakenings'] as int?,
    );
  }

  static String encodeList(List<SleepEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<SleepEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => SleepEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
