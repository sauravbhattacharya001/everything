import '../../models/watchlist_item.dart';

/// Service for watchlist analytics and recommendations.
class WatchlistService {
  const WatchlistService();

  /// Count items by status.
  Map<WatchStatus, int> statusBreakdown(List<WatchlistItem> items) {
    final counts = <WatchStatus, int>{};
    for (final item in items) {
      counts[item.status] = (counts[item.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Count items by genre (across all items).
  Map<WatchlistGenre, int> genreBreakdown(List<WatchlistItem> items) {
    final counts = <WatchlistGenre, int>{};
    for (final item in items) {
      for (final genre in item.genres) {
        counts[genre] = (counts[genre] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Count items by media type.
  Map<WatchlistMediaType, int> mediaTypeBreakdown(List<WatchlistItem> items) {
    final counts = <WatchlistMediaType, int>{};
    for (final item in items) {
      counts[item.mediaType] = (counts[item.mediaType] ?? 0) + 1;
    }
    return counts;
  }

  /// Count items by platform.
  Map<String, int> platformBreakdown(List<WatchlistItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final p = item.platform ?? 'Unknown';
      counts[p] = (counts[p] ?? 0) + 1;
    }
    return counts;
  }

  /// Average rating of completed items.
  double avgRating(List<WatchlistItem> items) {
    final rated =
        items.where((i) => i.status == WatchStatus.completed && i.rating > 0);
    if (rated.isEmpty) return 0;
    return rated.fold(0.0, (sum, i) => sum + i.rating) / rated.length;
  }

  /// Total episodes watched across all items.
  int totalEpisodesWatched(List<WatchlistItem> items) =>
      items.fold(0, (sum, i) => sum + i.episodesWatched);

  /// Completion rate (completed / total).
  double completionRate(List<WatchlistItem> items) {
    if (items.isEmpty) return 0;
    final completed =
        items.where((i) => i.status == WatchStatus.completed).length;
    return completed / items.length;
  }

  /// Top-rated items (completed, rated > 0, sorted by rating desc).
  List<WatchlistItem> topRated(List<WatchlistItem> items, {int limit = 5}) {
    final rated = items
        .where((i) => i.status == WatchStatus.completed && i.rating > 0)
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return rated.take(limit).toList();
  }

  /// Favorite genre (most frequently appearing across all items).
  WatchlistGenre? favoriteGenre(List<WatchlistItem> items) {
    final counts = genreBreakdown(items);
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Items currently being watched, sorted by progress descending.
  List<WatchlistItem> currentlyWatching(List<WatchlistItem> items) => items
      .where((i) => i.status == WatchStatus.watching)
      .toList()
    ..sort((a, b) => b.progress.compareTo(a.progress));

  /// Random pick from plan-to-watch list.
  WatchlistItem? randomPick(List<WatchlistItem> items) {
    final planToWatch =
        items.where((i) => i.status == WatchStatus.planToWatch).toList();
    if (planToWatch.isEmpty) return null;
    planToWatch.shuffle();
    return planToWatch.first;
  }

  /// Sample watchlist items for demo/testing.
  List<WatchlistItem> sampleItems() {
    final now = DateTime.now();
    return [
      WatchlistItem(
        id: 's1',
        title: 'Inception',
        mediaType: WatchlistMediaType.movie,
        genres: [WatchlistGenre.scifi, WatchlistGenre.thriller],
        status: WatchStatus.completed,
        rating: 9.0,
        year: 2010,
        director: 'Christopher Nolan',
        platform: 'Netflix',
        addedAt: now.subtract(const Duration(days: 90)),
        completedAt: now.subtract(const Duration(days: 85)),
        isFavorite: true,
      ),
      WatchlistItem(
        id: 's2',
        title: 'Breaking Bad',
        mediaType: WatchlistMediaType.tvShow,
        genres: [WatchlistGenre.drama, WatchlistGenre.crime, WatchlistGenre.thriller],
        status: WatchStatus.completed,
        rating: 9.5,
        year: 2008,
        totalEpisodes: 62,
        episodesWatched: 62,
        platform: 'Netflix',
        addedAt: now.subtract(const Duration(days: 200)),
        completedAt: now.subtract(const Duration(days: 120)),
        isFavorite: true,
      ),
      WatchlistItem(
        id: 's3',
        title: 'Severance',
        mediaType: WatchlistMediaType.tvShow,
        genres: [WatchlistGenre.scifi, WatchlistGenre.thriller, WatchlistGenre.mystery],
        status: WatchStatus.watching,
        rating: 0,
        year: 2022,
        totalEpisodes: 19,
        episodesWatched: 12,
        platform: 'Apple TV+',
        addedAt: now.subtract(const Duration(days: 30)),
        startedAt: now.subtract(const Duration(days: 25)),
      ),
      WatchlistItem(
        id: 's4',
        title: 'Dune: Part Two',
        mediaType: WatchlistMediaType.movie,
        genres: [WatchlistGenre.scifi, WatchlistGenre.action],
        status: WatchStatus.planToWatch,
        year: 2024,
        director: 'Denis Villeneuve',
        platform: 'Max',
        addedAt: now.subtract(const Duration(days: 15)),
      ),
      WatchlistItem(
        id: 's5',
        title: 'Spirited Away',
        mediaType: WatchlistMediaType.anime,
        genres: [WatchlistGenre.animation, WatchlistGenre.fantasy],
        status: WatchStatus.completed,
        rating: 8.5,
        year: 2001,
        director: 'Hayao Miyazaki',
        platform: 'Max',
        addedAt: now.subtract(const Duration(days: 60)),
        completedAt: now.subtract(const Duration(days: 55)),
        isFavorite: true,
      ),
      WatchlistItem(
        id: 's6',
        title: 'The Bear',
        mediaType: WatchlistMediaType.tvShow,
        genres: [WatchlistGenre.drama, WatchlistGenre.comedy],
        status: WatchStatus.onHold,
        year: 2022,
        totalEpisodes: 28,
        episodesWatched: 18,
        platform: 'Hulu',
        addedAt: now.subtract(const Duration(days: 45)),
        startedAt: now.subtract(const Duration(days: 40)),
      ),
    ];
  }
}
