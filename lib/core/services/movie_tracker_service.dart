import '../../models/movie_entry.dart';
import 'storage_backend.dart';

/// Service for managing movie log entries with local persistence.
class MovieTrackerService {
  static const String _storageKey = 'movie_tracker_entries';
  List<MovieEntry> _entries = [];
  bool _initialized = false;

  List<MovieEntry> get entries => List.unmodifiable(_entries);

  /// Load entries from local storage.
  Future<void> init() async {
    if (_initialized) return;
    final data = await StorageBackend.read(_storageKey);
    if (data != null && data.isNotEmpty) {
      _entries = MovieEntry.decodeList(data);
    }
    _entries.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    _initialized = true;
  }

  Future<void> _save() async {
    await StorageBackend.write(_storageKey, MovieEntry.encodeList(_entries));
  }

  /// Add a new movie entry.
  Future<void> addEntry(MovieEntry entry) async {
    await init();
    _entries.insert(0, entry);
    await _save();
  }

  /// Delete an entry by id.
  Future<void> deleteEntry(String id) async {
    await init();
    _entries.removeWhere((e) => e.id == id);
    await _save();
  }

  /// Update an existing entry.
  Future<void> updateEntry(MovieEntry updated) async {
    await init();
    final idx = _entries.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _entries[idx] = updated;
      await _save();
    }
  }

  /// Toggle favorite status.
  Future<void> toggleFavorite(String id) async {
    await init();
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _entries[idx] = _entries[idx].copyWith(favorite: !_entries[idx].favorite);
      await _save();
    }
  }

  /// Get entries by watch status.
  List<MovieEntry> entriesByStatus(WatchStatus status) {
    return _entries.where((e) => e.status == status).toList();
  }

  /// Get entries by genre.
  List<MovieEntry> entriesByGenre(MovieGenre genre) {
    return _entries.where((e) => e.genre == genre).toList();
  }

  /// Get favorite movies.
  List<MovieEntry> get favorites =>
      _entries.where((e) => e.favorite).toList();

  /// Genre distribution.
  Map<MovieGenre, int> genreDistribution() {
    final dist = <MovieGenre, int>{};
    for (final e in _entries.where((e) => e.status == WatchStatus.watched)) {
      dist[e.genre] = (dist[e.genre] ?? 0) + 1;
    }
    return Map.fromEntries(
      dist.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Average rating of watched movies.
  double get averageRating {
    final watched = _entries.where((e) => e.status == WatchStatus.watched && e.rating > 0).toList();
    if (watched.isEmpty) return 0;
    return watched.fold<double>(0, (sum, e) => sum + e.rating) / watched.length;
  }

  /// Total movies watched.
  int get totalWatched =>
      _entries.where((e) => e.status == WatchStatus.watched).length;

  /// Movies watched per month (last 12 months).
  Map<String, int> monthlyWatched() {
    final now = DateTime.now();
    final counts = <String, int>{};
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      counts[key] = 0;
    }
    for (final e in _entries) {
      if (e.status == WatchStatus.watched && e.dateWatched != null) {
        final key =
            '${e.dateWatched!.year}-${e.dateWatched!.month.toString().padLeft(2, '0')}';
        if (counts.containsKey(key)) {
          counts[key] = counts[key]! + 1;
        }
      }
    }
    return counts;
  }

  /// Search movies by title.
  List<MovieEntry> search(String query) {
    final q = query.toLowerCase();
    return _entries
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            (e.director?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  /// Top-rated movies.
  List<MovieEntry> topRated({int limit = 10}) {
    final watched = _entries
        .where((e) => e.status == WatchStatus.watched && e.rating > 0)
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return watched.take(limit).toList();
  }
}
