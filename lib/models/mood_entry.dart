import 'dart:convert';

/// Mood levels from 1 (very bad) to 5 (great).
enum MoodLevel {
  veryBad,
  bad,
  neutral,
  good,
  great;

  String get label {
    switch (this) {
      case MoodLevel.veryBad:
        return 'Very Bad';
      case MoodLevel.bad:
        return 'Bad';
      case MoodLevel.neutral:
        return 'Neutral';
      case MoodLevel.good:
        return 'Good';
      case MoodLevel.great:
        return 'Great';
    }
  }

  String get emoji {
    switch (this) {
      case MoodLevel.veryBad:
        return '😢';
      case MoodLevel.bad:
        return '😕';
      case MoodLevel.neutral:
        return '😐';
      case MoodLevel.good:
        return '😊';
      case MoodLevel.great:
        return '😄';
    }
  }

  int get value {
    switch (this) {
      case MoodLevel.veryBad:
        return 1;
      case MoodLevel.bad:
        return 2;
      case MoodLevel.neutral:
        return 3;
      case MoodLevel.good:
        return 4;
      case MoodLevel.great:
        return 5;
    }
  }

  static MoodLevel fromValue(int value) {
    switch (value) {
      case 1:
        return MoodLevel.veryBad;
      case 2:
        return MoodLevel.bad;
      case 3:
        return MoodLevel.neutral;
      case 4:
        return MoodLevel.good;
      case 5:
        return MoodLevel.great;
      default:
        return MoodLevel.neutral;
    }
  }
}

/// Predefined activities that may affect mood.
enum MoodActivity {
  work,
  exercise,
  socializing,
  reading,
  cooking,
  gaming,
  meditation,
  travel,
  family,
  music,
  nature,
  shopping,
  studying,
  rest;

  String get label {
    switch (this) {
      case MoodActivity.work:
        return 'Work';
      case MoodActivity.exercise:
        return 'Exercise';
      case MoodActivity.socializing:
        return 'Socializing';
      case MoodActivity.reading:
        return 'Reading';
      case MoodActivity.cooking:
        return 'Cooking';
      case MoodActivity.gaming:
        return 'Gaming';
      case MoodActivity.meditation:
        return 'Meditation';
      case MoodActivity.travel:
        return 'Travel';
      case MoodActivity.family:
        return 'Family';
      case MoodActivity.music:
        return 'Music';
      case MoodActivity.nature:
        return 'Nature';
      case MoodActivity.shopping:
        return 'Shopping';
      case MoodActivity.studying:
        return 'Studying';
      case MoodActivity.rest:
        return 'Rest';
    }
  }

  String get emoji {
    switch (this) {
      case MoodActivity.work:
        return '💼';
      case MoodActivity.exercise:
        return '🏋️';
      case MoodActivity.socializing:
        return '👥';
      case MoodActivity.reading:
        return '📚';
      case MoodActivity.cooking:
        return '🍳';
      case MoodActivity.gaming:
        return '🎮';
      case MoodActivity.meditation:
        return '🧘';
      case MoodActivity.travel:
        return '✈️';
      case MoodActivity.family:
        return '👨‍👩‍👧‍👦';
      case MoodActivity.music:
        return '🎵';
      case MoodActivity.nature:
        return '🌿';
      case MoodActivity.shopping:
        return '🛍️';
      case MoodActivity.studying:
        return '📝';
      case MoodActivity.rest:
        return '😴';
    }
  }
}

/// A single mood journal entry.
class MoodEntry {
  final String id;
  final DateTime timestamp;
  final MoodLevel mood;
  final String? note;
  final List<MoodActivity> activities;

  const MoodEntry({
    required this.id,
    required this.timestamp,
    required this.mood,
    this.note,
    this.activities = const [],
  });

  MoodEntry copyWith({
    String? id,
    DateTime? timestamp,
    MoodLevel? mood,
    String? note,
    List<MoodActivity>? activities,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      activities: activities ?? this.activities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood.value,
      'note': note,
      'activities': activities.map((a) => a.name).toList(),
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      mood: MoodLevel.fromValue(json['mood'] as int),
      note: json['note'] as String?,
      activities: (json['activities'] as List<dynamic>?)
              ?.map((a) => MoodActivity.values.firstWhere(
                    (v) => v.name == a,
                    orElse: () => MoodActivity.rest,
                  ))
              .toList() ??
          [],
    );
  }

  static String encodeList(List<MoodEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<MoodEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => MoodEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
