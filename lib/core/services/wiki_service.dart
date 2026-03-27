import 'dart:convert';
import '../../models/wiki_page_entry.dart';

/// Summary statistics for the personal wiki.
class WikiSummary {
  final int totalPages;
  final int totalWords;
  final int pinnedCount;
  final int totalLinks;
  final Map<String, int> tagBreakdown;

  const WikiSummary({
    required this.totalPages,
    required this.totalWords,
    required this.pinnedCount,
    required this.totalLinks,
    required this.tagBreakdown,
  });
}

/// Service for managing personal wiki pages.
class WikiService {
  List<WikiPageEntry> _pages = [];

  List<WikiPageEntry> get pages => List.unmodifiable(_pages);

  List<WikiPageEntry> get pinnedPages =>
      _pages.where((p) => p.isPinned).toList();

  /// Search pages by title, content, or tags.
  List<WikiPageEntry> search(String query) {
    final q = query.toLowerCase();
    return _pages.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.content.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  /// Get pages that link to a given page title.
  List<WikiPageEntry> backlinks(String title) {
    final t = title.toLowerCase();
    return _pages
        .where(
            (p) => p.internalLinks.any((l) => l.toLowerCase() == t))
        .toList();
  }

  /// Find a page by title (case-insensitive).
  WikiPageEntry? findByTitle(String title) {
    final t = title.toLowerCase();
    try {
      return _pages.firstWhere((p) => p.title.toLowerCase() == t);
    } catch (_) {
      return null;
    }
  }

  /// Get all unique tags across all pages.
  List<String> get allTags {
    final tags = <String>{};
    for (final p in _pages) {
      tags.addAll(p.tags);
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  void addPage(WikiPageEntry page) => _pages.add(page);

  void removePage(String id) => _pages.removeWhere((p) => p.id == id);

  void updatePage(WikiPageEntry page) {
    final idx = _pages.indexWhere((p) => p.id == page.id);
    if (idx >= 0) _pages[idx] = page;
  }

  WikiSummary get summary {
    final tagMap = <String, int>{};
    int totalLinks = 0;
    for (final p in _pages) {
      for (final t in p.tags) {
        tagMap[t] = (tagMap[t] ?? 0) + 1;
      }
      totalLinks += p.internalLinks.length;
    }
    return WikiSummary(
      totalPages: _pages.length,
      totalWords: _pages.fold(0, (sum, p) => sum + p.wordCount),
      pinnedCount: pinnedPages.length,
      totalLinks: totalLinks,
      tagBreakdown: tagMap,
    );
  }

  String toJson() =>
      jsonEncode(_pages.map((p) => p.toMap()).toList());

  void loadFromJson(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    _pages = list
        .map((e) => WikiPageEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
