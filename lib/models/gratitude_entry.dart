import 'dart:convert';

/// Categories of gratitude entries.
enum GratitudeCategory {
  people,
  health,
  nature,
  achievement,
  experience,
  possession,
  opportunity,
  general;

  String get label {
    switch (this) {
      case GratitudeCategory.people:
        return 'People';
      case GratitudeCategory.health:
        return 'Health';
      case GratitudeCategory.nature:
        return 'Nature';
      case GratitudeCategory.achievement:
        return 'Achievement';
      case GratitudeCategory.experience:
        return 'Experience';
      case GratitudeCategory.possession:
        return 'Possession';
      case GratitudeCategory.opportunity:
        return 'Opportunity';
      case GratitudeCategory.general:
        return 'General';
    }
  }

  String get emoji {
    switch (this) {
      case GratitudeCategory.people:
        return '👥';
      case GratitudeCategory.health:
        return '💪';
      case GratitudeCategory.nature:
        return '🌿';
      case GratitudeCategory.achievement:
        return '🏆';
      case GratitudeCategory.experience:
        return '✨';
      case GratitudeCategory.possession:
        return '🎁';
      case GratitudeCategory.opportunity:
        return '🚀';
      case GratitudeCategory.general:
        return '🙏';
    }
  }
}

/// Intensity of gratitude feeling (1-5).
enum GratitudeIntensity {
  slight,
  mild,
  moderate,
  strong,
  profound;

  int get value {
    switch (this) {
      case GratitudeIntensity.slight:
        return 1;
      case GratitudeIntensity.mild:
        return 2;
      case GratitudeIntensity.moderate:
        return 3;
      case GratitudeIntensity.strong:
        return 4;
      case GratitudeIntensity.profound:
        return 5;
    }
  }

  String get label {
    switch (this) {
      case GratitudeIntensity.slight:
        return 'Slight';
      case GratitudeIntensity.mild:
        return 'Mild';
      case GratitudeIntensity.moderate:
        return 'Moderate';
      case GratitudeIntensity.strong:
        return 'Strong';
      case GratitudeIntensity.profound:
        return 'Profound';
    }
  }

  static GratitudeIntensity fromValue(int v) {
    if (v <= 1) return GratitudeIntensity.slight;
    if (v == 2) return GratitudeIntensity.mild;
    if (v == 3) return GratitudeIntensity.moderate;
    if (v == 4) return GratitudeIntensity.strong;
    return GratitudeIntensity.profound;
  }
}

/// A single gratitude journal entry.
class GratitudeEntry {
  final String id;
  final DateTime timestamp;
  final String text;
  final GratitudeCategory category;
  final GratitudeIntensity intensity;
  final List<String> tags;
  final String? note;
  final bool isFavorite;

  GratitudeEntry({
    required this.id,
    required this.timestamp,
    required this.text,
    this.category = GratitudeCategory.general,
    this.intensity = GratitudeIntensity.moderate,
    this.tags = const [],
    this.note,
    this.isFavorite = false,
  });

  GratitudeEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? text,
    GratitudeCategory? category,
    GratitudeIntensity? intensity,
    List<String>? tags,
    String? note,
    bool? isFavorite,
  }) {
    return GratitudeEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      text: text ?? this.text,
      category: category ?? this.category,
      intensity: intensity ?? this.intensity,
      tags: tags ?? List.from(this.tags),
      note: note ?? this.note,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'text': text,
      'category': category.index,
      'intensity': intensity.index,
      'tags': tags,
      'note': note,
      'isFavorite': isFavorite,
    };
  }

  factory GratitudeEntry.fromJson(Map<String, dynamic> json) {
    return GratitudeEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      text: json['text'] as String,
      category: GratitudeCategory.values[json['category'] as int],
      intensity: GratitudeIntensity.values[json['intensity'] as int],
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      note: json['note'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory GratitudeEntry.fromJsonString(String s) =>
      GratitudeEntry.fromJson(jsonDecode(s) as Map<String, dynamic>);

  @override
  String toString() =>
      '${category.emoji} $text (${intensity.label}) - ${timestamp.toIso8601String()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GratitudeEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
