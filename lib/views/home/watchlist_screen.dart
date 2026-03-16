import 'package:flutter/material.dart';
import '../../models/watchlist_item.dart';
import '../../core/services/watchlist_service.dart';
import '../../core/services/screen_persistence.dart';

/// Movie & TV Watchlist Screen — 4-tab UI for tracking what to watch.
///
/// Tabs:
///   Browse: Search/filter list by status, genre, media type, platform
///   Add: Form to add new titles with genres, platform, episode count
///   Stats: Analytics — genre breakdown, ratings, completion rate, top rated
///   Currently Watching: Active shows with progress bars and episode tracking
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = const WatchlistService();
  final _persistence = ScreenPersistence<WatchlistItem>(
    storageKey: 'watchlist_items',
    toJson: (e) => e.toJson(),
    fromJson: WatchlistItem.fromJson,
  );
  final List<WatchlistItem> _items = [];
  String _searchQuery = '';
  WatchStatus? _filterStatus;
  WatchlistGenre? _filterGenre;
  WatchlistMediaType? _filterType;
  _SortMode _sortMode = _SortMode.newest;
  bool _favoritesOnly = false;

  // Add-tab form state
  final _titleController = TextEditingController();
  final _directorController = TextEditingController();
  final _platformController = TextEditingController();
  final _yearController = TextEditingController();
  final _episodesController = TextEditingController();
  final _notesController = TextEditingController();
  WatchlistMediaType _selectedType = WatchlistMediaType.movie;
  final List<WatchlistGenre> _selectedGenres = [];
  WatchStatus _selectedStatus = WatchStatus.planToWatch;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final saved = await _persistence.load();
    if (mounted) {
      setState(() {
        _items.addAll(saved.isNotEmpty ? saved : _service.sampleItems());
      });
    }
  }

  void _persistItems() {
    _persistence.save(_items);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _directorController.dispose();
    _platformController.dispose();
    _yearController.dispose();
    _episodesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_titleController.text.trim().isEmpty) return;
    final item = WatchlistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      mediaType: _selectedType,
      genres: List.from(_selectedGenres),
      status: _selectedStatus,
      year: int.tryParse(_yearController.text),
      totalEpisodes: int.tryParse(_episodesController.text),
      director: _directorController.text.trim().isEmpty
          ? null
          : _directorController.text.trim(),
      platform: _platformController.text.trim().isEmpty
          ? null
          : _platformController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      addedAt: DateTime.now(),
      startedAt: _selectedStatus == WatchStatus.watching ? DateTime.now() : null,
    );
    setState(() {
      _items.insert(0, item);
      _titleController.clear();
      _directorController.clear();
      _platformController.clear();
      _yearController.clear();
      _episodesController.clear();
      _notesController.clear();
      _selectedGenres.clear();
      _selectedType = WatchlistMediaType.movie;
      _selectedStatus = WatchStatus.planToWatch;
    });
    _persistItems();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "${item.title}" to watchlist')),
    );
  }

  void _deleteItem(WatchlistItem item) {
    setState(() => _items.remove(item));
    _persistItems();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${item.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _items.add(item));
            _persistItems();
          },
        ),
      ),
    );
  }

  void _toggleFavorite(WatchlistItem item) {
    final idx = _items.indexOf(item);
    if (idx < 0) return;
    setState(() => _items[idx] = item.copyWith(isFavorite: !item.isFavorite));
    _persistItems();
  }

  void _updateStatus(WatchlistItem item, WatchStatus newStatus) {
    final idx = _items.indexOf(item);
    if (idx < 0) return;
    setState(() {
      _items[idx] = item.copyWith(
        status: newStatus,
        startedAt: newStatus == WatchStatus.watching && item.startedAt == null
            ? DateTime.now()
            : item.startedAt,
        completedAt: newStatus == WatchStatus.completed
            ? DateTime.now()
            : item.completedAt,
        episodesWatched: newStatus == WatchStatus.completed &&
                item.totalEpisodes != null
            ? item.totalEpisodes
            : item.episodesWatched,
      );
    });
    _persistItems();
  }

  void _updateRating(WatchlistItem item, double rating) {
    final idx = _items.indexOf(item);
    if (idx < 0) return;
    setState(() => _items[idx] = item.copyWith(rating: rating));
    _persistItems();
  }

  void _incrementEpisodes(WatchlistItem item) {
    final idx = _items.indexOf(item);
    if (idx < 0) return;
    final newCount = item.episodesWatched + 1;
    final completed = item.totalEpisodes != null && newCount >= item.totalEpisodes!;
    setState(() {
      _items[idx] = item.copyWith(
        episodesWatched: newCount,
        status: completed ? WatchStatus.completed : item.status,
        completedAt: completed ? DateTime.now() : item.completedAt,
      );
    });
    _persistItems();
  }

  List<WatchlistItem> get _filteredItems {
    var list = List<WatchlistItem>.from(_items);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((i) =>
              i.title.toLowerCase().contains(q) ||
              (i.director?.toLowerCase().contains(q) ?? false) ||
              (i.platform?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    if (_filterStatus != null) {
      list = list.where((i) => i.status == _filterStatus).toList();
    }
    if (_filterGenre != null) {
      list = list.where((i) => i.genres.contains(_filterGenre)).toList();
    }
    if (_filterType != null) {
      list = list.where((i) => i.mediaType == _filterType).toList();
    }
    if (_favoritesOnly) {
      list = list.where((i) => i.isFavorite).toList();
    }
    switch (_sortMode) {
      case _SortMode.newest:
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      case _SortMode.oldest:
        list.sort((a, b) => a.addedAt.compareTo(b.addedAt));
      case _SortMode.ratingHigh:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortMode.ratingLow:
        list.sort((a, b) => a.rating.compareTo(b.rating));
      case _SortMode.titleAZ:
        list.sort((a, b) => a.title.compareTo(b.title));
      case _SortMode.titleZA:
        list.sort((a, b) => b.title.compareTo(a.title));
      case _SortMode.year:
        list.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎬 Watchlist'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Browse'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Add'),
            Tab(icon: Icon(Icons.play_circle_outline), text: 'Watching'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(theme),
          _buildAddTab(theme),
          _buildWatchingTab(theme),
          _buildStatsTab(theme),
        ],
      ),
    );
  }

  // ── Browse Tab ──

  Widget _buildBrowseTab(ThemeData theme) {
    final filtered = _filteredItems;
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search titles, directors, platforms...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Status filter
              ...WatchStatus.values.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text('${s.emoji} ${s.label}'),
                      selected: _filterStatus == s,
                      onSelected: (v) =>
                          setState(() => _filterStatus = v ? s : null),
                    ),
                  )),
              const SizedBox(width: 8),
              // Favorites toggle
              FilterChip(
                label: const Text('⭐ Favorites'),
                selected: _favoritesOnly,
                onSelected: (v) => setState(() => _favoritesOnly = v),
              ),
              const SizedBox(width: 8),
              // Sort
              PopupMenuButton<_SortMode>(
                icon: const Icon(Icons.sort, size: 20),
                onSelected: (v) => setState(() => _sortMode = v),
                itemBuilder: (_) => _SortMode.values
                    .map((s) => PopupMenuItem(
                          value: s,
                          child: Text(s.label),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        // Genre / type filter row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              ...WatchlistMediaType.values.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(t.label),
                      avatar: Icon(t.icon, size: 16),
                      selected: _filterType == t,
                      onSelected: (v) =>
                          setState(() => _filterType = v ? t : null),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('${filtered.length} titles',
                  style: theme.textTheme.bodySmall),
              const Spacer(),
              if (_filterStatus != null ||
                  _filterGenre != null ||
                  _filterType != null ||
                  _favoritesOnly)
                TextButton(
                  onPressed: () => setState(() {
                    _filterStatus = null;
                    _filterGenre = null;
                    _filterType = null;
                    _favoritesOnly = false;
                  }),
                  child: const Text('Clear filters'),
                ),
            ],
          ),
        ),
        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.movie_outlined,
                          size: 64, color: theme.disabledColor),
                      const SizedBox(height: 12),
                      Text('No titles found',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        _items.isEmpty
                            ? 'Add your first movie or show!'
                            : 'Try adjusting your filters',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (_, i) => _buildItemCard(filtered[i], theme),
                ),
        ),
      ],
    );
  }

  Widget _buildItemCard(WatchlistItem item, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showItemDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(item.mediaType.icon, size: 20, color: item.status.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (item.isFavorite)
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.status.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item.status.emoji} ${item.status.label}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: item.status.color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (item.year != null)
                    Text('${item.year}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor)),
                  if (item.year != null && item.director != null)
                    Text(' · ',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor)),
                  if (item.director != null)
                    Text(item.director!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor)),
                  const Spacer(),
                  if (item.platform != null)
                    Chip(
                      label: Text(item.platform!,
                          style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              if (item.genres.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: item.genres
                      .take(4)
                      .map((g) => Text('${g.emoji} ${g.label}',
                          style: theme.textTheme.bodySmall))
                      .toList(),
                ),
              ],
              if (item.rating > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < (item.rating / 2).round()
                            ? Icons.star
                            : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('${item.rating}/10',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
              if (item.totalEpisodes != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: item.progress,
                        backgroundColor: Colors.grey.shade200,
                        color: item.status.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.episodesWatched}/${item.totalEpisodes} ep',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetail(WatchlistItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(item.title,
                style: Theme.of(ctx)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(item.mediaType.icon, size: 18),
                const SizedBox(width: 6),
                Text(item.mediaType.label),
                if (item.year != null) ...[
                  const SizedBox(width: 12),
                  Text('${item.year}'),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Status changer
            Wrap(
              spacing: 6,
              children: WatchStatus.values
                  .map((s) => ChoiceChip(
                        label: Text('${s.emoji} ${s.label}'),
                        selected: item.status == s,
                        onSelected: (_) {
                          _updateStatus(item, s);
                          Navigator.pop(ctx);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            if (item.genres.isNotEmpty) ...[
              Text('Genres',
                  style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: item.genres
                    .map((g) => Chip(label: Text('${g.emoji} ${g.label}')))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (item.director != null) ...[
              _detailRow('Director', item.director!),
              const SizedBox(height: 8),
            ],
            if (item.platform != null) ...[
              _detailRow('Platform', item.platform!),
              const SizedBox(height: 8),
            ],
            if (item.totalEpisodes != null) ...[
              _detailRow('Progress',
                  '${item.episodesWatched}/${item.totalEpisodes} episodes (${(item.progress * 100).toStringAsFixed(0)}%)'),
              const SizedBox(height: 8),
            ],
            _detailRow('Added', _formatDate(item.addedAt)),
            if (item.startedAt != null) ...[
              const SizedBox(height: 4),
              _detailRow('Started', _formatDate(item.startedAt!)),
            ],
            if (item.completedAt != null) ...[
              const SizedBox(height: 4),
              _detailRow('Completed', _formatDate(item.completedAt!)),
            ],
            if (item.notes != null) ...[
              const SizedBox(height: 12),
              Text('Notes', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(item.notes!),
            ],
            const SizedBox(height: 16),
            // Rating slider
            Text('Rating: ${item.rating > 0 ? '${item.rating}/10' : 'Not rated'}',
                style: Theme.of(ctx).textTheme.titleSmall),
            Slider(
              value: item.rating,
              min: 0,
              max: 10,
              divisions: 20,
              label: item.rating > 0 ? item.rating.toString() : 'Not rated',
              onChanged: (v) {
                _updateRating(item, v);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    item.isFavorite ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    _toggleFavorite(item);
                    Navigator.pop(ctx);
                  },
                  tooltip: 'Toggle favorite',
                ),
                if (item.totalEpisodes != null &&
                    item.status == WatchStatus.watching)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.green),
                    onPressed: () {
                      _incrementEpisodes(item);
                      Navigator.pop(ctx);
                    },
                    tooltip: '+1 episode',
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deleteItem(item);
                  },
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      );

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // ── Add Tab ──

  Widget _buildAddTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add to Watchlist',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText: 'Movie or show name',
              prefixIcon: Icon(Icons.movie_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // Media type selector
          Text('Type', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: WatchlistMediaType.values
                .map((t) => ChoiceChip(
                      label: Text(t.label),
                      avatar: Icon(t.icon, size: 16),
                      selected: _selectedType == t,
                      onSelected: (_) =>
                          setState(() => _selectedType = t),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Genre multi-select
          Text('Genres', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: WatchlistGenre.values
                .map((g) => FilterChip(
                      label: Text('${g.emoji} ${g.label}'),
                      selected: _selectedGenres.contains(g),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selectedGenres.add(g);
                        } else {
                          _selectedGenres.remove(g);
                        }
                      }),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _episodesController,
                  decoration: const InputDecoration(
                    labelText: 'Total Episodes',
                    hintText: 'For TV shows',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _directorController,
            decoration: const InputDecoration(
              labelText: 'Director',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _platformController,
            decoration: const InputDecoration(
              labelText: 'Platform',
              hintText: 'Netflix, Hulu, Disney+...',
              prefixIcon: Icon(Icons.devices),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // Status selector
          Text('Status', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: WatchStatus.values
                .map((s) => ChoiceChip(
                      label: Text('${s.emoji} ${s.label}'),
                      selected: _selectedStatus == s,
                      onSelected: (_) =>
                          setState(() => _selectedStatus = s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Who recommended it, thoughts...',
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _titleController.text.trim().isNotEmpty ? _addItem : null,
            icon: const Icon(Icons.add),
            label: const Text('Add to Watchlist'),
          ),
        ],
      ),
    );
  }

  // ── Currently Watching Tab ──

  Widget _buildWatchingTab(ThemeData theme) {
    final watching = _service.currentlyWatching(_items);
    final randomPick = _service.randomPick(_items);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (randomPick != null) ...[
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎲 Random Pick',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '"${randomPick.title}" ${randomPick.year != null ? '(${randomPick.year})' : ''}',
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (randomPick.genres.isNotEmpty)
                    Text(
                      randomPick.genres.map((g) => g.emoji).join(' '),
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () =>
                        _updateStatus(randomPick, WatchStatus.watching),
                    child: const Text('Start Watching'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('Currently Watching (${watching.length})',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (watching.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.play_circle_outline,
                      size: 48, color: theme.disabledColor),
                  const SizedBox(height: 8),
                  Text('Nothing in progress',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          )
        else
          ...watching.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(item.mediaType.icon, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item.title,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          if (item.platform != null)
                            Text(item.platform!,
                                style: theme.textTheme.bodySmall),
                        ],
                      ),
                      if (item.totalEpisodes != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: item.progress,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.episodesWatched}/${item.totalEpisodes} episodes · ${(item.progress * 100).toStringAsFixed(0)}%',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.tonal(
                              onPressed: () => _incrementEpisodes(item),
                              child: const Text('+1 ep'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _updateStatus(
                                item, WatchStatus.completed),
                            child: const Text('✅ Complete'),
                          ),
                          TextButton(
                            onPressed: () =>
                                _updateStatus(item, WatchStatus.onHold),
                            child: const Text('⏸️ Pause'),
                          ),
                          TextButton(
                            onPressed: () =>
                                _updateStatus(item, WatchStatus.dropped),
                            child: const Text('❌ Drop'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  // ── Stats Tab ──

  Widget _buildStatsTab(ThemeData theme) {
    final statusBreakdown = _service.statusBreakdown(_items);
    final genreBreakdown = _service.genreBreakdown(_items);
    final mediaBreakdown = _service.mediaTypeBreakdown(_items);
    final platformBreakdown = _service.platformBreakdown(_items);
    final avgRating = _service.avgRating(_items);
    final totalEps = _service.totalEpisodesWatched(_items);
    final completionRate = _service.completionRate(_items);
    final topRated = _service.topRated(_items);
    final favGenre = _service.favoriteGenre(_items);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Watchlist Stats',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        // Overview cards
        Row(
          children: [
            _statCard(theme, '🎬', '${_items.length}', 'Total'),
            _statCard(theme, '⭐', avgRating > 0 ? avgRating.toStringAsFixed(1) : '—', 'Avg Rating'),
            _statCard(theme, '📺', '$totalEps', 'Episodes'),
            _statCard(theme, '✅', '${(completionRate * 100).toStringAsFixed(0)}%', 'Completed'),
          ],
        ),
        const SizedBox(height: 16),
        if (favGenre != null) ...[
          Card(
            child: ListTile(
              leading: Text(favGenre.emoji, style: const TextStyle(fontSize: 28)),
              title: const Text('Favorite Genre'),
              subtitle: Text(favGenre.label),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Status breakdown
        Text('By Status', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...statusBreakdown.entries.map((e) => _barRow(
              theme,
              '${e.key.emoji} ${e.key.label}',
              e.value,
              _items.length,
              e.key.color,
            )),
        const SizedBox(height: 16),
        // Media type breakdown
        Text('By Type', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...mediaBreakdown.entries.map((e) => _barRow(
              theme,
              e.key.label,
              e.value,
              _items.length,
              theme.colorScheme.primary,
            )),
        const SizedBox(height: 16),
        // Genre breakdown
        Text('By Genre', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...(genreBreakdown.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(10)
            .map((e) => _barRow(
                  theme,
                  '${e.key.emoji} ${e.key.label}',
                  e.value,
                  genreBreakdown.values.reduce((a, b) => a > b ? a : b),
                  theme.colorScheme.secondary,
                )),
        const SizedBox(height: 16),
        // Platform breakdown
        if (platformBreakdown.isNotEmpty) ...[
          Text('By Platform', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...(platformBreakdown.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .map((e) => _barRow(
                    theme,
                    e.key,
                    e.value,
                    _items.length,
                    theme.colorScheme.tertiary,
                  )),
          const SizedBox(height: 16),
        ],
        // Top rated
        if (topRated.isNotEmpty) ...[
          Text('Top Rated', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...topRated.asMap().entries.map((e) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text('${e.key + 1}'),
                ),
                title: Text(e.value.title),
                subtitle: Text(e.value.genres.map((g) => g.emoji).join(' ')),
                trailing: Text('${e.value.rating}/10',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              )),
        ],
      ],
    );
  }

  Widget _statCard(ThemeData theme, String emoji, String value, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barRow(
      ThemeData theme, String label, int value, int max, Color color) {
    final fraction = max > 0 ? value / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child:
                Text(label, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: Colors.grey.shade200,
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text('$value', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

enum _SortMode {
  newest('Newest First'),
  oldest('Oldest First'),
  ratingHigh('Rating ↓'),
  ratingLow('Rating ↑'),
  titleAZ('Title A–Z'),
  titleZA('Title Z–A'),
  year('Year');

  final String label;
  const _SortMode(this.label);
}
