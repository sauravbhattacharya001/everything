import 'dart:convert';

/// Blood pressure reading category based on AHA guidelines.
enum BPCategory {
  normal,
  elevated,
  hypertensionStage1,
  hypertensionStage2,
  hypertensiveCrisis;

  String get label {
    switch (this) {
      case BPCategory.normal:
        return 'Normal';
      case BPCategory.elevated:
        return 'Elevated';
      case BPCategory.hypertensionStage1:
        return 'Hypertension Stage 1';
      case BPCategory.hypertensionStage2:
        return 'Hypertension Stage 2';
      case BPCategory.hypertensiveCrisis:
        return 'Hypertensive Crisis';
    }
  }

  String get emoji {
    switch (this) {
      case BPCategory.normal:
        return '💚';
      case BPCategory.elevated:
        return '💛';
      case BPCategory.hypertensionStage1:
        return '🟠';
      case BPCategory.hypertensionStage2:
        return '🔴';
      case BPCategory.hypertensiveCrisis:
        return '🚨';
    }
  }

  String get advice {
    switch (this) {
      case BPCategory.normal:
        return 'Maintain a healthy lifestyle.';
      case BPCategory.elevated:
        return 'Adopt healthier habits to prevent progression.';
      case BPCategory.hypertensionStage1:
        return 'Lifestyle changes recommended; consult your doctor.';
      case BPCategory.hypertensionStage2:
        return 'Medication likely needed; see your doctor.';
      case BPCategory.hypertensiveCrisis:
        return 'Seek immediate medical attention!';
    }
  }
}

/// Context/position when reading was taken.
enum ReadingContext {
  morning,
  afternoon,
  evening,
  beforeMeal,
  afterMeal,
  afterExercise,
  atRest,
  other;

  String get label {
    switch (this) {
      case ReadingContext.morning:
        return 'Morning';
      case ReadingContext.afternoon:
        return 'Afternoon';
      case ReadingContext.evening:
        return 'Evening';
      case ReadingContext.beforeMeal:
        return 'Before Meal';
      case ReadingContext.afterMeal:
        return 'After Meal';
      case ReadingContext.afterExercise:
        return 'After Exercise';
      case ReadingContext.atRest:
        return 'At Rest';
      case ReadingContext.other:
        return 'Other';
    }
  }
}

/// Arm used for the reading.
enum ArmUsed {
  left,
  right;

  String get label => this == ArmUsed.left ? 'Left Arm' : 'Right Arm';
}

/// A single blood pressure reading.
class BloodPressureEntry {
  final String id;
  final DateTime timestamp;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final ReadingContext context;
  final ArmUsed arm;
  final String? note;

  const BloodPressureEntry({
    required this.id,
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    this.context = ReadingContext.atRest,
    this.arm = ArmUsed.left,
    this.note,
  });

  /// Classify this reading per AHA guidelines.
  BPCategory get category {
    if (systolic >= 180 || diastolic >= 120) return BPCategory.hypertensiveCrisis;
    if (systolic >= 140 || diastolic >= 90) return BPCategory.hypertensionStage2;
    if (systolic >= 130 || diastolic >= 80) return BPCategory.hypertensionStage1;
    if (systolic >= 120 && diastolic < 80) return BPCategory.elevated;
    return BPCategory.normal;
  }

  /// Mean arterial pressure.
  double get meanArterialPressure =>
      diastolic + (systolic - diastolic) / 3.0;

  /// Pulse pressure (systolic − diastolic).
  int get pulsePressure => systolic - diastolic;

  BloodPressureEntry copyWith({
    String? id,
    DateTime? timestamp,
    int? systolic,
    int? diastolic,
    int? pulse,
    ReadingContext? context,
    ArmUsed? arm,
    String? note,
  }) {
    return BloodPressureEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      context: context ?? this.context,
      arm: arm ?? this.arm,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
        'context': context.name,
        'arm': arm.name,
        'note': note,
      };

  factory BloodPressureEntry.fromJson(Map<String, dynamic> json) {
    return BloodPressureEntry(
      id: json['id'] as String,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      systolic: json['systolic'] as int? ?? 120,
      diastolic: json['diastolic'] as int? ?? 80,
      pulse: json['pulse'] as int?,
      context: ReadingContext.values.firstWhere(
        (v) => v.name == json['context'],
        orElse: () => ReadingContext.atRest,
      ),
      arm: ArmUsed.values.firstWhere(
        (v) => v.name == json['arm'],
        orElse: () => ArmUsed.left,
      ),
      note: json['note'] as String?,
    );
  }

  static String encodeList(List<BloodPressureEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<BloodPressureEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => BloodPressureEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
