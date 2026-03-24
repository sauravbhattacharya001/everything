import 'dart:convert';
import 'package:everything/core/utils/date_utils.dart';

/// Mood associated with a journal entry.
enum JournalMood {
  terrible,
  bad,
  okay,
  good,
  great;

  String get emoji {
    switch (this) {
      case JournalMood.terrible:
        return '😢';
      case JournalMood.bad:
        return '😟';
      case JournalMood.okay:
        return '😐';
      case JournalMood.good:
        return '😊';
      case JournalMood.great:
        return '🤩';
    }
  }

  String get label {
    switch (this) {
      case JournalMood.terrible:
        return 'Terrible';
      case JournalMood.bad:
        return 'Bad';
      case JournalMood.okay:
        return 'Okay';
      case JournalMood.good:
        return 'Good';
      case JournalMood.great:
        return 'Great';
    }
  }
}

/// A single daily journal / diary entry.
class JournalEntry {
  final String id;
  final DateTime date;
  final String title;
  final String body;
  final JournalMood? mood;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry({
    required this.id,
    required this.date,
    this.title = '',
    this.body = '',
    this.mood,
    this.tags = const [],
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get wordCount {
    if (body.trim().isEmpty) return 0;
    return body.trim().split(RegExp(r'\s+')).length;
  }

  JournalEntry copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? body,
    JournalMood? mood,
    List<String>? tags,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      body: body ?? this.body,
      mood: mood ?? this.mood,
      tags: tags ?? List.from(this.tags),
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'body': body,
      'mood': mood?.index,
      'tags': tags,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      date: AppDateUtils.safeParse(json['date'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      mood: json['mood'] != null ? JournalMood.values[json['mood'] as int] : null,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? AppDateUtils.safeParse(json['createdAt'] as String?)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? AppDateUtils.safeParse(json['updatedAt'] as String?)
          : DateTime.now(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory JournalEntry.fromJsonString(String s) =>
      JournalEntry.fromJson(jsonDecode(s) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is JournalEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
