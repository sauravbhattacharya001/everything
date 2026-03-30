import 'dart:convert';

/// SpO2 reading category based on clinical guidelines.
enum SpO2Category {
  normal,
  mild,
  moderate,
  severe;

  String get label {
    switch (this) {
      case SpO2Category.normal:
        return 'Normal';
      case SpO2Category.mild:
        return 'Mild Hypoxemia';
      case SpO2Category.moderate:
        return 'Moderate Hypoxemia';
      case SpO2Category.severe:
        return 'Severe Hypoxemia';
    }
  }

  String get emoji {
    switch (this) {
      case SpO2Category.normal:
        return '💚';
      case SpO2Category.mild:
        return '💛';
      case SpO2Category.moderate:
        return '🟠';
      case SpO2Category.severe:
        return '🔴';
    }
  }

  String get advice {
    switch (this) {
      case SpO2Category.normal:
        return 'Oxygen levels are healthy. Keep it up!';
      case SpO2Category.mild:
        return 'Slightly low. Monitor closely and consider deep breathing.';
      case SpO2Category.moderate:
        return 'Below normal. Consult your doctor if persistent.';
      case SpO2Category.severe:
        return 'Dangerously low. Seek immediate medical attention!';
    }
  }
}

/// Activity context when reading was taken.
enum SpO2Context {
  atRest,
  afterExercise,
  sleeping,
  walking,
  highAltitude,
  other;

  String get label {
    switch (this) {
      case SpO2Context.atRest:
        return 'At Rest';
      case SpO2Context.afterExercise:
        return 'After Exercise';
      case SpO2Context.sleeping:
        return 'Sleeping';
      case SpO2Context.walking:
        return 'Walking';
      case SpO2Context.highAltitude:
        return 'High Altitude';
      case SpO2Context.other:
        return 'Other';
    }
  }
}

/// A single blood oxygen (SpO2) reading.
class SpO2Entry {
  final String id;
  final DateTime timestamp;
  final int spo2; // percentage 0-100
  final int? heartRate; // optional pulse reading
  final SpO2Context context;
  final String? note;

  const SpO2Entry({
    required this.id,
    required this.timestamp,
    required this.spo2,
    this.heartRate,
    this.context = SpO2Context.atRest,
    this.note,
  });

  /// Classify this reading per clinical guidelines.
  SpO2Category get category {
    if (spo2 >= 95) return SpO2Category.normal;
    if (spo2 >= 91) return SpO2Category.mild;
    if (spo2 >= 86) return SpO2Category.moderate;
    return SpO2Category.severe;
  }

  SpO2Entry copyWith({
    String? id,
    DateTime? timestamp,
    int? spo2,
    int? heartRate,
    SpO2Context? context,
    String? note,
  }) {
    return SpO2Entry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      spo2: spo2 ?? this.spo2,
      heartRate: heartRate ?? this.heartRate,
      context: context ?? this.context,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'spo2': spo2,
        'heartRate': heartRate,
        'context': context.name,
        'note': note,
      };

  factory SpO2Entry.fromJson(Map<String, dynamic> json) {
    return SpO2Entry(
      id: json['id'] as String,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      spo2: json['spo2'] as int? ?? 98,
      heartRate: json['heartRate'] as int?,
      context: SpO2Context.values.firstWhere(
        (v) => v.name == json['context'],
        orElse: () => SpO2Context.atRest,
      ),
      note: json['note'] as String?,
    );
  }

  static String encodeList(List<SpO2Entry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<SpO2Entry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => SpO2Entry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
