import '../../models/bookmark.dart';

/// Service for bookmark analytics and management.
class BookmarkService {
  const BookmarkService();

  /// Total bookmarks (excluding archived).
  int activeCount(List<Bookmark> items) =>
      items.where((b) => !b.isArchived).length;

  /// Bookmarks per folder.
  Map<BookmarkFolder, int> folderBreakdown(List<Bookmark> items) {
    final counts = <BookmarkFolder, int>{};
    for (final b in items.where((b) => !b.isArchived)) {
      counts[b.folder] = (counts[b.folder] ?? 0) + 1;
    }
    return counts;
  }

  /// Most-visited bookmarks.
  List<Bookmark> mostVisited(List<Bookmark> items, {int limit = 10}) {
    final sorted = items.where((b) => b.visitCount > 0).toList()
      ..sort((a, b) => b.visitCount.compareTo(a.visitCount));
    return sorted.take(limit).toList();
  }

  /// Bookmarks never visited.
  List<Bookmark> neverVisited(List<Bookmark> items) =>
      items.where((b) => !b.isArchived && b.visitCount == 0).toList();

  /// Stale bookmarks (not visited in > thresholdDays).
  List<Bookmark> staleBookmarks(List<Bookmark> items,
      {int thresholdDays = 60}) {
    return items
        .where((b) =>
            !b.isArchived &&
            b.lastVisited != null &&
            b.daysSinceVisited! > thresholdDays)
        .toList();
  }

  /// Unique domains across all bookmarks.
  Map<String, int> domainBreakdown(List<Bookmark> items) {
    final counts = <String, int>{};
    for (final b in items.where((b) => !b.isArchived)) {
      counts[b.domain] = (counts[b.domain] ?? 0) + 1;
    }
    return counts;
  }

  /// Top domains by bookmark count.
  List<MapEntry<String, int>> topDomains(List<Bookmark> items,
      {int limit = 10}) {
    final domains = domainBreakdown(items).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return domains.take(limit).toList();
  }

  /// All unique tags used.
  Set<String> allTags(List<Bookmark> items) =>
      items.expand((b) => b.tags).toSet();

  /// Tag frequency.
  Map<String, int> tagBreakdown(List<Bookmark> items) {
    final counts = <String, int>{};
    for (final b in items) {
      for (final tag in b.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Sample bookmarks for demo.
  List<Bookmark> sampleItems() => [
        Bookmark(
          id: '1',
          title: 'Flutter Documentation',
          url: 'https://docs.flutter.dev',
          description: 'Official Flutter docs',
          folder: BookmarkFolder.learning,
          tags: ['flutter', 'dart', 'mobile'],
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastVisited: DateTime.now().subtract(const Duration(days: 2)),
          visitCount: 15,
          isFavorite: true,
        ),
        Bookmark(
          id: '2',
          title: 'Hacker News',
          url: 'https://news.ycombinator.com',
          description: 'Tech news aggregator',
          folder: BookmarkFolder.general,
          tags: ['news', 'tech'],
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          lastVisited: DateTime.now().subtract(const Duration(days: 1)),
          visitCount: 42,
        ),
        Bookmark(
          id: '3',
          title: 'Dart Packages',
          url: 'https://pub.dev',
          description: 'Find Dart and Flutter packages',
          folder: BookmarkFolder.reference,
          tags: ['dart', 'packages'],
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          visitCount: 8,
        ),
        Bookmark(
          id: '4',
          title: 'CSS Tricks',
          url: 'https://css-tricks.com',
          folder: BookmarkFolder.readLater,
          tags: ['css', 'web'],
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
          visitCount: 0,
        ),
        Bookmark(
          id: '5',
          title: 'Material Design 3',
          url: 'https://m3.material.io',
          description: 'Google Material Design guidelines',
          folder: BookmarkFolder.inspiration,
          tags: ['design', 'ui'],
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          visitCount: 3,
          isFavorite: true,
        ),
      ];

  /// Smart suggestions.
  List<String> suggestions(List<Bookmark> items) {
    final tips = <String>[];

    final never = neverVisited(items);
    if (never.length > 5) {
      tips.add(
          '📭 ${never.length} bookmarks never visited — review or archive them');
    }

    final stale = staleBookmarks(items);
    if (stale.isNotEmpty) {
      tips.add(
          '⏰ ${stale.length} bookmark(s) not visited in 60+ days — still relevant?');
    }

    final archived = items.where((b) => b.isArchived).length;
    final total = items.length;
    if (total > 50 && archived == 0) {
      tips.add('🗂️ You have $total bookmarks but none archived — declutter?');
    }

    final domains = domainBreakdown(items);
    final topDomain = domains.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (topDomain.isNotEmpty && topDomain.first.value > 10) {
      tips.add(
          '🌐 ${topDomain.first.value} bookmarks from ${topDomain.first.key} — consider a folder');
    }

    if (tips.isEmpty) {
      tips.add('✨ Your bookmarks are well-organized!');
    }

    return tips;
  }
}
