import 'dart:convert';

/// Meditation technique types.
enum MeditationType {
  mindfulness,
  breathing,
  bodyScanning,
  loving_kindness,
  visualization,
  mantra,
  walking,
  transcendental,
  unguided;

  String get label {
    switch (this) {
      case MeditationType.mindfulness:
        return 'Mindfulness';
      case MeditationType.breathing:
        return 'Breathing';
      case MeditationType.bodyScanning:
        return 'Body Scan';
      case MeditationType.loving_kindness:
        return 'Loving Kindness';
      case MeditationType.visualization:
        return 'Visualization';
      case MeditationType.mantra:
        return 'Mantra';
      case MeditationType.walking:
        return 'Walking';
      case MeditationType.transcendental:
        return 'Transcendental';
      case MeditationType.unguided:
        return 'Unguided';
    }
  }

  String get emoji {
    switch (this) {
      case MeditationType.mindfulness:
        return '\u{1F9D8}';
      case MeditationType.breathing:
        return '\u{1F32C}\uFE0F';
      case MeditationType.bodyScanning:
        return '\u{1F9CD}';
      case MeditationType.loving_kindness:
        return '\u2764\uFE0F';
      case MeditationType.visualization:
        return '\u{1F30C}';
      case MeditationType.mantra:
        return '\u{1F549}\uFE0F';
      case MeditationType.walking:
        return '\u{1F6B6}';
      case MeditationType.transcendental:
        return '\u2728';
      case MeditationType.unguided:
        return '\u{1F54A}\uFE0F';
    }
  }
}

/// A single meditation session entry.
class MeditationEntry {
  final String id;
  final DateTime dateTime;
  final int durationMinutes;
  final MeditationType type;
  final int? preMood;   // 1-10
  final int? postMood;  // 1-10
  final String? note;
  final String? guideName; // name of guide / app used
  final bool interrupted;

  const MeditationEntry({
    required this.id,
    required this.dateTime,
    required this.durationMinutes,
    this.type = MeditationType.mindfulness,
    this.preMood,
    this.postMood,
    this.note,
    this.guideName,
    this.interrupted = false,
  });

  /// Mood improvement (positive = better after).
  int? get moodDelta {
    if (preMood == null || postMood == null) return null;
    return postMood! - preMood!;
  }

  MeditationEntry copyWith({
    String? id,
    DateTime? dateTime,
    int? durationMinutes,
    MeditationType? type,
    int? preMood,
    int? postMood,
    String? note,
    String? guideName,
    bool? interrupted,
  }) {
    return MeditationEntry(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      preMood: preMood ?? this.preMood,
      postMood: postMood ?? this.postMood,
      note: note ?? this.note,
      guideName: guideName ?? this.guideName,
      interrupted: interrupted ?? this.interrupted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'durationMinutes': durationMinutes,
        'type': type.name,
        'preMood': preMood,
        'postMood': postMood,
        'note': note,
        'guideName': guideName,
        'interrupted': interrupted,
      };

  factory MeditationEntry.fromJson(Map<String, dynamic> json) {
    return MeditationEntry(
      id: json['id'] as String,
      dateTime: DateTime.tryParse(json['dateTime'] as String? ?? '') ?? DateTime.now(),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      type: MeditationType.values.firstWhere(
        (v) => v.name == json['type'],
        orElse: () => MeditationType.mindfulness,
      ),
      preMood: json['preMood'] as int?,
      postMood: json['postMood'] as int?,
      note: json['note'] as String?,
      guideName: json['guideName'] as String?,
      interrupted: json['interrupted'] as bool? ?? false,
    );
  }

  static String encodeList(List<MeditationEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<MeditationEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => MeditationEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
