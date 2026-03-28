import 'package:flutter/material.dart';
import '../../models/movie_entry.dart';
import '../../core/services/movie_tracker_service.dart';
import 'dart:math';

/// Movie Tracker – log movies you've watched, maintain a watchlist,
/// rate and review, and see stats about your viewing habits.
class MovieTrackerScreen extends StatefulWidget {
  const MovieTrackerScreen({super.key});

  @override
  State<MovieTrackerScreen> createState() => _MovieTrackerScreenState();
}

class _MovieTrackerScreenState extends State<MovieTrackerScreen> {
  final _service = MovieTrackerService();
  bool _loading = true;
  int _tabIndex = 0; // 0 = Add, 1 = Library, 2 = Stats

  // Form state
  final _titleController = TextEditingController();
  final _directorController = TextEditingController();
  final _yearController = TextEditingController();
  final _noteController = TextEditingController();
  MovieGenre _genre = MovieGenre.drama;
  WatchStatus _status = WatchStatus.watched;
  double _rating = 0;

  // Library filter
  WatchStatus? _filterStatus;
  MovieGenre? _filterGenre;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service.init().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _directorController.dispose();
    _yearController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _titleController.clear();
    _directorController.clear();
    _yearController.clear();
    _noteController.clear();
    _genre = MovieGenre.drama;
    _status = WatchStatus.watched;
    _rating = 0;
  }

  Future<void> _addMovie() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a movie title')),
      );
      return;
    }
    final entry = MovieEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      title: title,
      genre: _genre,
      status: _status,
      rating: _status == WatchStatus.watched ? _rating : 0,
      dateAdded: DateTime.now(),
      dateWatched: _status == WatchStatus.watched ? DateTime.now() : null,
      director: _directorController.text.trim().isEmpty
          ? null
          : _directorController.text.trim(),
      year: int.tryParse(_yearController.text.trim()),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    await _service.addEntry(entry);
    _resetForm();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "$title" ${_status == WatchStatus.watched ? "✅" : "📋"}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('🎬 Movie Tracker')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('🎬 Movie Tracker')),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                _buildAddTab(),
                _buildLibraryTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    const tabs = ['➕ Add', '📚 Library', '📊 Stats'];
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Movie Title *',
              prefixIcon: Icon(Icons.movie),
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _directorController,
                  decoration: const InputDecoration(
                    labelText: 'Director',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Genre', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MovieGenre.values.map((g) {
              final selected = _genre == g;
              return ChoiceChip(
                label: Text('${g.emoji} ${g.label}'),
                selected: selected,
                onSelected: (_) => setState(() => _genre = g),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<WatchStatus>(
            segments: WatchStatus.values
                .map((s) => ButtonSegment(
                      value: s,
                      label: Text('${s.emoji} ${s.label}'),
                    ))
                .toList(),
            selected: {_status},
            onSelectionChanged: (v) => setState(() => _status = v.first),
          ),
          if (_status == WatchStatus.watched) ...[
            const SizedBox(height: 16),
            const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starValue = i + 1.0;
                return IconButton(
                  onPressed: () => setState(() => _rating = starValue),
                  icon: Icon(
                    _rating >= starValue ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                );
              }),
            ),
            Center(
              child: Text(
                _rating > 0 ? '${_rating.toStringAsFixed(0)}/5' : 'Tap to rate',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _addMovie,
            icon: const Icon(Icons.add),
            label: const Text('Add Movie'),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    var movies = List<MovieEntry>.from(_service.entries);

    if (_filterStatus != null) {
      movies = movies.where((e) => e.status == _filterStatus).toList();
    }
    if (_filterGenre != null) {
      movies = movies.where((e) => e.genre == _filterGenre).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      movies = movies
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              (e.director?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search movies...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _filterStatus == null,
                onSelected: (_) =>
                    setState(() => _filterStatus = null),
              ),
              const SizedBox(width: 8),
              ...WatchStatus.values.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('${s.emoji} ${s.label}'),
                      selected: _filterStatus == s,
                      onSelected: (_) => setState(
                          () => _filterStatus = _filterStatus == s ? null : s),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: movies.isEmpty
              ? const Center(child: Text('No movies yet. Add some! 🎬'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: movies.length,
                  itemBuilder: (context, index) =>
                      _buildMovieCard(movies[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildMovieCard(MovieEntry movie) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(movie.genre.emoji),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                movie.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (movie.favorite)
              const Icon(Icons.favorite, color: Colors.red, size: 18),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${movie.status.emoji} ${movie.status.label}'),
                if (movie.year != null) Text(' • ${movie.year}'),
                if (movie.director != null) Text(' • ${movie.director}'),
              ],
            ),
            if (movie.rating > 0)
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < movie.rating.round() ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'favorite') {
              await _service.toggleFavorite(movie.id);
              setState(() {});
            } else if (action == 'delete') {
              await _service.deleteEntry(movie.id);
              setState(() {});
            } else if (action == 'markWatched' &&
                movie.status != WatchStatus.watched) {
              await _service.updateEntry(movie.copyWith(
                status: WatchStatus.watched,
                dateWatched: DateTime.now(),
              ));
              setState(() {});
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'favorite',
              child: Text(movie.favorite ? '💔 Unfavorite' : '❤️ Favorite'),
            ),
            if (movie.status != WatchStatus.watched)
              const PopupMenuItem(
                value: 'markWatched',
                child: Text('✅ Mark Watched'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('🗑️ Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    final totalWatched = _service.totalWatched;
    final avgRating = _service.averageRating;
    final genreDist = _service.genreDistribution();
    final topRated = _service.topRated(limit: 5);
    final watchlistCount =
        _service.entriesByStatus(WatchStatus.watchlist).length;
    final favCount = _service.favorites.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overview cards
          Row(
            children: [
              _statCard('🎬', 'Watched', '$totalWatched'),
              const SizedBox(width: 8),
              _statCard('📋', 'Watchlist', '$watchlistCount'),
              const SizedBox(width: 8),
              _statCard('⭐', 'Avg Rating', avgRating > 0 ? avgRating.toStringAsFixed(1) : '-'),
              const SizedBox(width: 8),
              _statCard('❤️', 'Favorites', '$favCount'),
            ],
          ),
          const SizedBox(height: 20),
          // Genre breakdown
          if (genreDist.isNotEmpty) ...[
            const Text('Genre Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...genreDist.entries.map((e) {
              final pct =
                  totalWatched > 0 ? (e.value / totalWatched * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text('${e.key.emoji} ${e.key.label}'),
                    const Spacer(),
                    Text('${e.value} (${pct.toStringAsFixed(0)}%)'),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 20),
          // Top rated
          if (topRated.isNotEmpty) ...[
            const Text('Top Rated',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...topRated.asMap().entries.map((e) {
              final movie = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('${e.key + 1}. ${movie.title}'),
                    const Spacer(),
                    ...List.generate(
                      movie.rating.round(),
                      (_) => const Icon(Icons.star, size: 14, color: Colors.amber),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (_service.entries.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Add some movies to see your stats! 📊'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
