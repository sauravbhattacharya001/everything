import 'package:flutter/material.dart';

/// Bookmark folder/collection.
enum BookmarkFolder {
  general('General', '📁', Colors.blue),
  readLater('Read Later', '📖', Colors.orange),
  work('Work', '💼', Colors.indigo),
  learning('Learning', '🎓', Colors.green),
  recipes('Recipes', '🍳', Colors.red),
  shopping('Shopping', '🛒', Colors.purple),
  inspiration('Inspiration', '💡', Colors.amber),
  reference('Reference', '📌', Colors.teal);

  final String label;
  final String emoji;
  final Color color;
  const BookmarkFolder(this.label, this.emoji, this.color);
}

/// A single bookmark entry.
class Bookmark {
  final String id;
  final String title;
  final String url;
  final String? description;
  final BookmarkFolder folder;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? lastVisited;
  final int visitCount;
  final bool isFavorite;
  final bool isArchived;

  const Bookmark({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    required this.folder,
    this.tags = const [],
    required this.createdAt,
    this.lastVisited,
    this.visitCount = 0,
    this.isFavorite = false,
    this.isArchived = false,
  });

  /// Domain extracted from URL.
  String get domain {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  /// Days since bookmark was created.
  int get daysSinceCreated => DateTime.now().difference(createdAt).inDays;

  /// Days since last visited (null if never visited).
  int? get daysSinceVisited =>
      lastVisited != null ? DateTime.now().difference(lastVisited!).inDays : null;

  Bookmark copyWith({
    String? title,
    String? url,
    String? description,
    BookmarkFolder? folder,
    List<String>? tags,
    DateTime? lastVisited,
    int? visitCount,
    bool? isFavorite,
    bool? isArchived,
  }) =>
      Bookmark(
        id: id,
        title: title ?? this.title,
        url: url ?? this.url,
        description: description ?? this.description,
        folder: folder ?? this.folder,
        tags: tags ?? this.tags,
        createdAt: createdAt,
        lastVisited: lastVisited ?? this.lastVisited,
        visitCount: visitCount ?? this.visitCount,
        isFavorite: isFavorite ?? this.isFavorite,
        isArchived: isArchived ?? this.isArchived,
      );

  Bookmark recordVisit() => copyWith(
        lastVisited: DateTime.now(),
        visitCount: visitCount + 1,
      );

  Bookmark toggleFavorite() => copyWith(isFavorite: !isFavorite);

  Bookmark toggleArchive() => copyWith(isArchived: !isArchived);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        if (description != null) 'description': description,
        'folder': folder.name,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        if (lastVisited != null) 'lastVisited': lastVisited!.toIso8601String(),
        'visitCount': visitCount,
        'isFavorite': isFavorite,
        'isArchived': isArchived,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'] as String,
        title: json['title'] as String,
        url: json['url'] as String,
        description: json['description'] as String?,
        folder: BookmarkFolder.values.byName(json['folder'] as String),
        tags: (json['tags'] as List<dynamic>?)
                ?.map((t) => t as String)
                .toList() ??
            const [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastVisited: json['lastVisited'] != null
            ? DateTime.parse(json['lastVisited'] as String)
            : null,
        visitCount: json['visitCount'] as int? ?? 0,
        isFavorite: json['isFavorite'] as bool? ?? false,
        isArchived: json['isArchived'] as bool? ?? false,
      );
}
