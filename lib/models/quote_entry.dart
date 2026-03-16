import 'package:flutter/material.dart';

/// Category for quotes.
enum QuoteCategory {
  motivation('Motivation', '🔥', Colors.orange),
  wisdom('Wisdom', '🦉', Colors.indigo),
  humor('Humor', '😄', Colors.amber),
  love('Love', '❤️', Colors.red),
  friendship('Friendship', '🤝', Colors.teal),
  success('Success', '🏆', Colors.green),
  creativity('Creativity', '🎨', Colors.purple),
  philosophy('Philosophy', '🧠', Colors.blueGrey),
  science('Science', '🔬', Colors.cyan),
  literature('Literature', '📖', Colors.brown),
  leadership('Leadership', '👑', Colors.deepOrange),
  mindfulness('Mindfulness', '🧘', Colors.lightGreen),
  other('Other', '💬', Colors.grey);

  final String label;
  final String emoji;
  final Color color;
  const QuoteCategory(this.label, this.emoji, this.color);
}

/// A single saved quote.
class QuoteEntry {
  final String id;
  final String text;
  final String? author;
  final String? source;
  final QuoteCategory category;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final String? notes;

  const QuoteEntry({
    required this.id,
    required this.text,
    this.author,
    this.source,
    required this.category,
    this.tags = const [],
    this.isFavorite = false,
    required this.createdAt,
    this.notes,
  });

  /// Word count of the quote text.
  int get wordCount => text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  /// Toggle favorite.
  QuoteEntry toggleFavorite() => QuoteEntry(
        id: id,
        text: text,
        author: author,
        source: source,
        category: category,
        tags: tags,
        isFavorite: !isFavorite,
        createdAt: createdAt,
        notes: notes,
      );

  /// Copy with modifications.
  QuoteEntry copyWith({
    String? text,
    String? author,
    String? source,
    QuoteCategory? category,
    List<String>? tags,
    bool? isFavorite,
    String? notes,
  }) =>
      QuoteEntry(
        id: id,
        text: text ?? this.text,
        author: author ?? this.author,
        source: source ?? this.source,
        category: category ?? this.category,
        tags: tags ?? this.tags,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        if (author != null) 'author': author,
        if (source != null) 'source': source,
        'category': category.name,
        'tags': tags,
        'isFavorite': isFavorite,
        'createdAt': createdAt.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

  factory QuoteEntry.fromJson(Map<String, dynamic> json) => QuoteEntry(
        id: json['id'] as String,
        text: json['text'] as String,
        author: json['author'] as String?,
        source: json['source'] as String?,
        category: QuoteCategory.values.byName(json['category'] as String),
        tags: (json['tags'] as List<dynamic>?)
                ?.map((t) => t as String)
                .toList() ??
            const [],
        isFavorite: json['isFavorite'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        notes: json['notes'] as String?,
      );
}
