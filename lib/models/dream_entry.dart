import 'dart:convert';

/// Types of dreams.
enum DreamType {
  normal,
  lucid,
  nightmare,
  recurring,
  vivid,
  prophetic;

  String get label {
    switch (this) {
      case DreamType.normal:
        return 'Normal';
      case DreamType.lucid:
        return 'Lucid';
      case DreamType.nightmare:
        return 'Nightmare';
      case DreamType.recurring:
        return 'Recurring';
      case DreamType.vivid:
        return 'Vivid';
      case DreamType.prophetic:
        return 'Prophetic';
    }
  }

  String get emoji {
    switch (this) {
      case DreamType.normal:
        return '💤';
      case DreamType.lucid:
        return '✨';
      case DreamType.nightmare:
        return '😱';
      case DreamType.recurring:
        return '🔁';
      case DreamType.vivid:
        return '🌈';
      case DreamType.prophetic:
        return '🔮';
    }
  }
}

/// Mood upon waking.
enum WakingMood {
  peaceful,
  happy,
  confused,
  anxious,
  scared,
  inspired,
  neutral;

  String get label {
    switch (this) {
      case WakingMood.peaceful:
        return 'Peaceful';
      case WakingMood.happy:
        return 'Happy';
      case WakingMood.confused:
        return 'Confused';
      case WakingMood.anxious:
        return 'Anxious';
      case WakingMood.scared:
        return 'Scared';
      case WakingMood.inspired:
        return 'Inspired';
      case WakingMood.neutral:
        return 'Neutral';
    }
  }

  String get emoji {
    switch (this) {
      case WakingMood.peaceful:
        return '😌';
      case WakingMood.happy:
        return '😊';
      case WakingMood.confused:
        return '😕';
      case WakingMood.anxious:
        return '😰';
      case WakingMood.scared:
        return '😨';
      case WakingMood.inspired:
        return '🤩';
      case WakingMood.neutral:
        return '😐';
    }
  }
}

/// A single dream journal entry.
class DreamEntry {
  final String id;
  final DateTime date;
  final String title;
  final String description;
  final DreamType type;
  final WakingMood mood;
  final int clarity; // 1-5
  final List<String> tags;
  final bool isFavorite;

  DreamEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.description,
    this.type = DreamType.normal,
    this.mood = WakingMood.neutral,
    this.clarity = 3,
    this.tags = const [],
    this.isFavorite = false,
  });

  DreamEntry copyWith({
    String? title,
    String? description,
    DreamType? type,
    WakingMood? mood,
    int? clarity,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return DreamEntry(
      id: id,
      date: date,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      mood: mood ?? this.mood,
      clarity: clarity ?? this.clarity,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'description': description,
        'type': type.index,
        'mood': mood.index,
        'clarity': clarity,
        'tags': tags,
        'isFavorite': isFavorite,
      };

  factory DreamEntry.fromJson(Map<String, dynamic> json) => DreamEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        title: json['title'] as String,
        description: json['description'] as String,
        type: DreamType.values[json['type'] as int],
        mood: WakingMood.values[json['mood'] as int],
        clarity: json['clarity'] as int? ?? 3,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  static String encodeList(List<DreamEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<DreamEntry> decodeList(String json) =>
      (jsonDecode(json) as List<dynamic>)
          .map((e) => DreamEntry.fromJson(e as Map<String, dynamic>))
          .toList();
}
