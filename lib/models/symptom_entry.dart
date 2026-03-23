import 'dart:convert';

/// Severity levels for a symptom.
enum SymptomSeverity {
  mild,
  moderate,
  severe;

  String get label {
    switch (this) {
      case SymptomSeverity.mild:
        return 'Mild';
      case SymptomSeverity.moderate:
        return 'Moderate';
      case SymptomSeverity.severe:
        return 'Severe';
    }
  }

  String get emoji {
    switch (this) {
      case SymptomSeverity.mild:
        return '🟡';
      case SymptomSeverity.moderate:
        return '🟠';
      case SymptomSeverity.severe:
        return '🔴';
    }
  }

  int get value {
    switch (this) {
      case SymptomSeverity.mild:
        return 1;
      case SymptomSeverity.moderate:
        return 2;
      case SymptomSeverity.severe:
        return 3;
    }
  }

  static SymptomSeverity fromValue(int value) {
    switch (value) {
      case 1:
        return SymptomSeverity.mild;
      case 2:
        return SymptomSeverity.moderate;
      case 3:
        return SymptomSeverity.severe;
      default:
        return SymptomSeverity.mild;
    }
  }
}

/// Common body areas where symptoms may occur.
enum BodyArea {
  head,
  chest,
  abdomen,
  back,
  arms,
  legs,
  throat,
  skin,
  eyes,
  general;

  String get label {
    switch (this) {
      case BodyArea.head:
        return 'Head';
      case BodyArea.chest:
        return 'Chest';
      case BodyArea.abdomen:
        return 'Abdomen';
      case BodyArea.back:
        return 'Back';
      case BodyArea.arms:
        return 'Arms';
      case BodyArea.legs:
        return 'Legs';
      case BodyArea.throat:
        return 'Throat';
      case BodyArea.skin:
        return 'Skin';
      case BodyArea.eyes:
        return 'Eyes';
      case BodyArea.general:
        return 'General';
    }
  }

  String get emoji {
    switch (this) {
      case BodyArea.head:
        return '🧠';
      case BodyArea.chest:
        return '🫁';
      case BodyArea.abdomen:
        return '🤢';
      case BodyArea.back:
        return '🦴';
      case BodyArea.arms:
        return '💪';
      case BodyArea.legs:
        return '🦵';
      case BodyArea.throat:
        return '🗣️';
      case BodyArea.skin:
        return '🩹';
      case BodyArea.eyes:
        return '👁️';
      case BodyArea.general:
        return '🏥';
    }
  }
}

/// A single symptom log entry.
class SymptomEntry {
  final String id;
  final DateTime timestamp;
  final String symptom;
  final SymptomSeverity severity;
  final BodyArea bodyArea;
  final String? note;
  final List<String> triggers;

  const SymptomEntry({
    required this.id,
    required this.timestamp,
    required this.symptom,
    required this.severity,
    required this.bodyArea,
    this.note,
    this.triggers = const [],
  });

  SymptomEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? symptom,
    SymptomSeverity? severity,
    BodyArea? bodyArea,
    String? note,
    List<String>? triggers,
  }) {
    return SymptomEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      symptom: symptom ?? this.symptom,
      severity: severity ?? this.severity,
      bodyArea: bodyArea ?? this.bodyArea,
      note: note ?? this.note,
      triggers: triggers ?? this.triggers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'symptom': symptom,
      'severity': severity.value,
      'bodyArea': bodyArea.name,
      'note': note,
      'triggers': triggers,
    };
  }

  factory SymptomEntry.fromJson(Map<String, dynamic> json) {
    return SymptomEntry(
      id: json['id'] as String,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      symptom: json['symptom'] as String,
      severity: SymptomSeverity.fromValue(json['severity'] as int),
      bodyArea: BodyArea.values.firstWhere(
        (b) => b.name == json['bodyArea'],
        orElse: () => BodyArea.general,
      ),
      note: json['note'] as String?,
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((t) => t as String)
              .toList() ??
          [],
    );
  }

  static String encodeList(List<SymptomEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<SymptomEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => SymptomEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
