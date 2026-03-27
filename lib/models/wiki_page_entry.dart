import 'dart:convert';

/// A single page in the personal wiki.
class WikiPageEntry {
  final String id;
  String title;
  String content;
  List<String> tags;
  DateTime createdAt;
  DateTime updatedAt;
  bool isPinned;

  WikiPageEntry({
    required this.id,
    required this.title,
    this.content = '',
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Extract internal wiki links from content — format: [[Page Title]]
  List<String> get internalLinks {
    final regex = RegExp(r'\[\[([^\]]+)\]\]');
    return regex.allMatches(content).map((m) => m.group(1)!.trim()).toList();
  }

  /// Word count of the content.
  int get wordCount =>
      content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isPinned': isPinned,
      };

  factory WikiPageEntry.fromMap(Map<String, dynamic> m) => WikiPageEntry(
        id: m['id'] as String,
        title: m['title'] as String,
        content: (m['content'] as String?) ?? '',
        tags: (m['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(m['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        isPinned: (m['isPinned'] as bool?) ?? false,
      );

  String toJson() => jsonEncode(toMap());
  factory WikiPageEntry.fromJson(String json) =>
      WikiPageEntry.fromMap(jsonDecode(json) as Map<String, dynamic>);
}
