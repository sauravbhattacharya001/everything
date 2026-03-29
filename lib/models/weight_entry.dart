import 'dart:convert';

/// BMI category based on WHO classification.
enum BMICategory {
  underweight,
  normal,
  overweight,
  obeseClass1,
  obeseClass2,
  obeseClass3;

  String get label {
    switch (this) {
      case BMICategory.underweight:
        return 'Underweight';
      case BMICategory.normal:
        return 'Normal';
      case BMICategory.overweight:
        return 'Overweight';
      case BMICategory.obeseClass1:
        return 'Obese (Class I)';
      case BMICategory.obeseClass2:
        return 'Obese (Class II)';
      case BMICategory.obeseClass3:
        return 'Obese (Class III)';
    }
  }

  String get emoji {
    switch (this) {
      case BMICategory.underweight:
        return '⚠️';
      case BMICategory.normal:
        return '💚';
      case BMICategory.overweight:
        return '💛';
      case BMICategory.obeseClass1:
        return '🟠';
      case BMICategory.obeseClass2:
        return '🔴';
      case BMICategory.obeseClass3:
        return '🚨';
    }
  }
}

/// Unit system for weight display.
enum WeightUnit {
  kg,
  lbs;

  String get label => this == WeightUnit.kg ? 'kg' : 'lbs';
}

/// A single weight log entry.
class WeightEntry {
  final String id;
  final DateTime timestamp;

  /// Weight stored in kg internally.
  final double weightKg;
  final String? note;

  const WeightEntry({
    required this.id,
    required this.timestamp,
    required this.weightKg,
    this.note,
  });

  /// Convert to lbs for display.
  double get weightLbs => weightKg * 2.20462;

  /// Display weight in chosen unit.
  String displayWeight(WeightUnit unit) {
    final val = unit == WeightUnit.kg ? weightKg : weightLbs;
    return '${val.toStringAsFixed(1)} ${unit.label}';
  }

  /// Calculate BMI given height in cm.
  double bmi(double heightCm) {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Classify BMI per WHO guidelines.
  BMICategory bmiCategory(double heightCm) {
    final b = bmi(heightCm);
    if (b < 18.5) return BMICategory.underweight;
    if (b < 25) return BMICategory.normal;
    if (b < 30) return BMICategory.overweight;
    if (b < 35) return BMICategory.obeseClass1;
    if (b < 40) return BMICategory.obeseClass2;
    return BMICategory.obeseClass3;
  }

  WeightEntry copyWith({
    String? id,
    DateTime? timestamp,
    double? weightKg,
    String? note,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      weightKg: weightKg ?? this.weightKg,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'weightKg': weightKg,
        'note': note,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id'] as String,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 70.0,
      note: json['note'] as String?,
    );
  }

  static String encodeList(List<WeightEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<WeightEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
