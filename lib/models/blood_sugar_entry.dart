import 'dart:convert';

/// Blood sugar reading category based on ADA guidelines.
enum BSCategory {
  low,
  normal,
  prediabetic,
  diabetic,
  dangerouslyHigh;

  String get label {
    switch (this) {
      case BSCategory.low:
        return 'Low';
      case BSCategory.normal:
        return 'Normal';
      case BSCategory.prediabetic:
        return 'Pre-diabetic';
      case BSCategory.diabetic:
        return 'Diabetic';
      case BSCategory.dangerouslyHigh:
        return 'Dangerously High';
    }
  }

  String get emoji {
    switch (this) {
      case BSCategory.low:
        return '🔵';
      case BSCategory.normal:
        return '💚';
      case BSCategory.prediabetic:
        return '💛';
      case BSCategory.diabetic:
        return '🔴';
      case BSCategory.dangerouslyHigh:
        return '🚨';
    }
  }

  String get advice {
    switch (this) {
      case BSCategory.low:
        return 'Eat something with sugar. If symptoms persist, seek help.';
      case BSCategory.normal:
        return 'Great! Keep maintaining a healthy lifestyle.';
      case BSCategory.prediabetic:
        return 'Consider lifestyle changes: diet, exercise, weight management.';
      case BSCategory.diabetic:
        return 'Consult your doctor about management options.';
      case BSCategory.dangerouslyHigh:
        return 'Seek immediate medical attention!';
    }
  }
}

/// Context for when the reading was taken.
enum MealContext {
  fasting,
  beforeMeal,
  afterMeal1h,
  afterMeal2h,
  bedtime,
  random,
  other;

  String get label {
    switch (this) {
      case MealContext.fasting:
        return 'Fasting';
      case MealContext.beforeMeal:
        return 'Before Meal';
      case MealContext.afterMeal1h:
        return '1h After Meal';
      case MealContext.afterMeal2h:
        return '2h After Meal';
      case MealContext.bedtime:
        return 'Bedtime';
      case MealContext.random:
        return 'Random';
      case MealContext.other:
        return 'Other';
    }
  }
}

/// A single blood sugar reading (mg/dL).
class BloodSugarEntry {
  final String id;
  final DateTime timestamp;
  final int glucoseMgDl;
  final MealContext mealContext;
  final String? note;

  const BloodSugarEntry({
    required this.id,
    required this.timestamp,
    required this.glucoseMgDl,
    this.mealContext = MealContext.random,
    this.note,
  });

  /// Classify this reading per ADA fasting/post-meal guidelines.
  BSCategory get category {
    if (glucoseMgDl < 70) return BSCategory.low;
    if (glucoseMgDl > 300) return BSCategory.dangerouslyHigh;

    // Post-meal thresholds are higher
    final isPostMeal =
        mealContext == MealContext.afterMeal1h ||
        mealContext == MealContext.afterMeal2h;

    if (isPostMeal) {
      if (glucoseMgDl <= 140) return BSCategory.normal;
      if (glucoseMgDl <= 199) return BSCategory.prediabetic;
      return BSCategory.diabetic;
    } else {
      // Fasting / before meal / random
      if (glucoseMgDl <= 99) return BSCategory.normal;
      if (glucoseMgDl <= 125) return BSCategory.prediabetic;
      return BSCategory.diabetic;
    }
  }

  /// Convert mg/dL to mmol/L.
  double get glucoseMmolL => glucoseMgDl / 18.0;

  BloodSugarEntry copyWith({
    String? id,
    DateTime? timestamp,
    int? glucoseMgDl,
    MealContext? mealContext,
    String? note,
  }) {
    return BloodSugarEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      glucoseMgDl: glucoseMgDl ?? this.glucoseMgDl,
      mealContext: mealContext ?? this.mealContext,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'glucoseMgDl': glucoseMgDl,
        'mealContext': mealContext.name,
        'note': note,
      };

  factory BloodSugarEntry.fromJson(Map<String, dynamic> json) {
    return BloodSugarEntry(
      id: json['id'] as String,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      glucoseMgDl: json['glucoseMgDl'] as int? ?? 100,
      mealContext: MealContext.values.firstWhere(
        (v) => v.name == json['mealContext'],
        orElse: () => MealContext.random,
      ),
      note: json['note'] as String?,
    );
  }

  static String encodeList(List<BloodSugarEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<BloodSugarEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => BloodSugarEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
