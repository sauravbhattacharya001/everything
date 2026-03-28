import 'dart:convert';

/// Categories of allergens.
enum AllergenCategory {
  food,
  environmental,
  medication,
  insect,
  contact,
  other;

  String get label {
    switch (this) {
      case AllergenCategory.food:
        return 'Food';
      case AllergenCategory.environmental:
        return 'Environmental';
      case AllergenCategory.medication:
        return 'Medication';
      case AllergenCategory.insect:
        return 'Insect';
      case AllergenCategory.contact:
        return 'Contact';
      case AllergenCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case AllergenCategory.food:
        return '🍽️';
      case AllergenCategory.environmental:
        return '🌿';
      case AllergenCategory.medication:
        return '💊';
      case AllergenCategory.insect:
        return '🐝';
      case AllergenCategory.contact:
        return '🧴';
      case AllergenCategory.other:
        return '❓';
    }
  }
}

/// Reaction severity.
enum ReactionSeverity {
  mild,
  moderate,
  severe,
  anaphylaxis;

  String get label {
    switch (this) {
      case ReactionSeverity.mild:
        return 'Mild';
      case ReactionSeverity.moderate:
        return 'Moderate';
      case ReactionSeverity.severe:
        return 'Severe';
      case ReactionSeverity.anaphylaxis:
        return 'Anaphylaxis';
    }
  }

  String get emoji {
    switch (this) {
      case ReactionSeverity.mild:
        return '🟡';
      case ReactionSeverity.moderate:
        return '🟠';
      case ReactionSeverity.severe:
        return '🔴';
      case ReactionSeverity.anaphylaxis:
        return '🚨';
    }
  }

  int get value {
    switch (this) {
      case ReactionSeverity.mild:
        return 1;
      case ReactionSeverity.moderate:
        return 2;
      case ReactionSeverity.severe:
        return 3;
      case ReactionSeverity.anaphylaxis:
        return 4;
    }
  }

  static ReactionSeverity fromValue(int value) {
    switch (value) {
      case 1:
        return ReactionSeverity.mild;
      case 2:
        return ReactionSeverity.moderate;
      case 3:
        return ReactionSeverity.severe;
      case 4:
        return ReactionSeverity.anaphylaxis;
      default:
        return ReactionSeverity.mild;
    }
  }
}

/// A single allergy reaction log entry.
class AllergyEntry {
  final String id;
  final DateTime timestamp;
  final String allergen;
  final AllergenCategory category;
  final ReactionSeverity severity;
  final List<String> symptoms;
  final String? treatment;
  final String? note;
  final int durationMinutes;

  const AllergyEntry({
    required this.id,
    required this.timestamp,
    required this.allergen,
    required this.category,
    required this.severity,
    this.symptoms = const [],
    this.treatment,
    this.note,
    this.durationMinutes = 0,
  });

  AllergyEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? allergen,
    AllergenCategory? category,
    ReactionSeverity? severity,
    List<String>? symptoms,
    String? treatment,
    String? note,
    int? durationMinutes,
  }) {
    return AllergyEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      allergen: allergen ?? this.allergen,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      symptoms: symptoms ?? this.symptoms,
      treatment: treatment ?? this.treatment,
      note: note ?? this.note,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'allergen': allergen,
      'category': category.name,
      'severity': severity.value,
      'symptoms': symptoms,
      'treatment': treatment,
      'note': note,
      'durationMinutes': durationMinutes,
    };
  }

  factory AllergyEntry.fromJson(Map<String, dynamic> json) {
    return AllergyEntry(
      id: json['id'] as String,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      allergen: json['allergen'] as String,
      category: AllergenCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => AllergenCategory.other,
      ),
      severity: ReactionSeverity.fromValue(json['severity'] as int),
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      treatment: json['treatment'] as String?,
      note: json['note'] as String?,
      durationMinutes: json['durationMinutes'] as int? ?? 0,
    );
  }

  static String encodeList(List<AllergyEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<AllergyEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => AllergyEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
