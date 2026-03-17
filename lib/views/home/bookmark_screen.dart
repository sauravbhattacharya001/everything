import 'package:flutter/material.dart';
import '../../models/bookmark.dart';
import '../../core/services/bookmark_service.dart';
import '../../core/services/screen_persistence.dart';

/// Bookmark Manager Screen — 4-tab UI for saving & organizing URLs.
///
/// Tabs:
///   Browse: Search/filter bookmarks by folder, tags, favorites
///   Add: Form to add new bookmarks with URL, title, tags, folder
///   Stats: Analytics — domains, tags, visit counts, suggestions
///   Folders: View bookmarks grouped by folder
class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

enum _SortMode { newest, oldest, mostVisited, alphabetical }

class _BookmarkScreenState extends State<BookmarkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = const BookmarkService();
  final _persistence = ScreenPersistence<Bookmark>(
    storageKey: 'bookmark_items',
    toJson: (e) => e.toJson(),
    fromJson: Bookmark.fromJson,
  );
  final List<Bookmark> _items = [];
  String _searchQuery = '';
  BookmarkFolder? _filterFolder;
  _SortMode _sortMode = _SortMode.newest;
  bool _favoritesOnly = false;
  bool _showArchived = false;

  // Add-tab form
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  BookmarkFolder _selectedFolder = BookmarkFolder.general;

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

  Future<void> _save() => _persistence.save(_items);

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  List<Bookmark> get _filteredItems {
    var list = _items.where((b) => _showArchived ? b.isArchived : !b.isArchived);
    if (_favoritesOnly) list = list.where((b) => b.isFavorite);
    if (_filterFolder != null) list = list.where((b) => b.folder == _filterFolder);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((b) =>
          b.title.toLowerCase().contains(q) ||
          b.url.toLowerCase().contains(q) ||
          b.tags.any((t) => t.toLowerCase().contains(q)) ||
          (b.description?.toLowerCase().contains(q) ?? false));
    }
    final sorted = list.toList();
    switch (_sortMode) {
      case _SortMode.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortMode.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortMode.mostVisited:
        sorted.sort((a, b) => b.visitCount.compareTo(a.visitCount));
      case _SortMode.alphabetical:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return sorted;
  }

  void _addBookmark() {
    final title = _titleController.text.trim();
    final url = _urlController.text.trim();
    if (title.isEmpty || url.isEmpty) return;

    final normalizedUrl = url.startsWith('http') ? url : 'https://$url';
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() {
      _items.add(Bookmark(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        url: normalizedUrl,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        folder: _selectedFolder,
        tags: tags,
        createdAt: DateTime.now(),
      ));
    });
    _save();

    _titleController.clear();
    _urlController.clear();
    _descriptionController.clear();
    _tagsController.clear();
    setState(() => _selectedFolder = BookmarkFolder.general);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmark saved ✓'), duration: Duration(seconds: 2)),
    );
  }

  void _deleteBookmark(String id) {
    setState(() => _items.removeWhere((b) => b.id == id));
    _save();
  }

  void _toggleFavorite(String id) {
    setState(() {
      final i = _items.indexWhere((b) => b.id == id);
      if (i >= 0) _items[i] = _items[i].toggleFavorite();
    });
    _save();
  }

  void _toggleArchive(String id) {
    setState(() {
      final i = _items.indexWhere((b) => b.id == id);
      if (i >= 0) _items[i] = _items[i].toggleArchive();
    });
    _save();
  }

  void _recordVisit(Bookmark bookmark) {
    setState(() {
      final i = _items.indexWhere((b) => b.id == bookmark.id);
      if (i >= 0) _items[i] = _items[i].recordVisit();
    });
    _save();
    // URL opening would require url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Visiting ${bookmark.title}'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔖 Bookmarks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bookmarks_outlined), text: 'Browse'),
            Tab(icon: Icon(Icons.add_link), text: 'Add'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Stats'),
            Tab(icon: Icon(Icons.folder_outlined), text: 'Folders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(),
          _buildAddTab(),
          _buildStatsTab(),
          _buildFoldersTab(),
        ],
      ),
    );
  }

  // ─── Browse Tab ───────────────────────────────────────────

  Widget _buildBrowseTab() {
    final items = _filteredItems;
    return Column(
      children: [
        // Search & filter bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search bookmarks...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('⭐ Favorites'),
                      selected: _favoritesOnly,
                      onSelected: (v) => setState(() => _favoritesOnly = v),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('🗄️ Archived'),
                      selected: _showArchived,
                      onSelected: (v) => setState(() => _showArchived = v),
                    ),
                    const SizedBox(width: 8),
                    ...BookmarkFolder.values.map((f) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text('${f.emoji} ${f.label}'),
                            selected: _filterFolder == f,
                            onSelected: (v) =>
                                setState(() => _filterFolder = v ? f : null),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('${items.length} bookmarks',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const Spacer(),
                  PopupMenuButton<_SortMode>(
                    icon: const Icon(Icons.sort, size: 20),
                    onSelected: (v) => setState(() => _sortMode = v),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: _SortMode.newest, child: Text('Newest')),
                      const PopupMenuItem(value: _SortMode.oldest, child: Text('Oldest')),
                      const PopupMenuItem(value: _SortMode.mostVisited, child: Text('Most visited')),
                      const PopupMenuItem(value: _SortMode.alphabetical, child: Text('A–Z')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('No bookmarks found',
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (ctx, i) => _buildBookmarkCard(items[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildBookmarkCard(Bookmark b) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _recordVisit(b),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: b.folder.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${b.folder.emoji} ${b.folder.label}',
                        style: TextStyle(fontSize: 11, color: b.folder.color)),
                  ),
                  const Spacer(),
                  if (b.visitCount > 0)
                    Text('${b.visitCount} visits',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  IconButton(
                    icon: Icon(
                      b.isFavorite ? Icons.star : Icons.star_border,
                      color: b.isFavorite ? Colors.amber : null,
                      size: 20,
                    ),
                    onPressed: () => _toggleFavorite(b.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(b.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 2),
              Text(b.domain,
                  style: TextStyle(color: Colors.blue[700], fontSize: 12)),
              if (b.description != null) ...[
                const SizedBox(height: 4),
                Text(b.description!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              if (b.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: b.tags
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('#$t',
                                style: const TextStyle(fontSize: 11)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(b.isArchived ? Icons.unarchive : Icons.archive_outlined, size: 18),
                    onPressed: () => _toggleArchive(b.id),
                    tooltip: b.isArchived ? 'Unarchive' : 'Archive',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () => _deleteBookmark(b.id),
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Add Tab ──────────────────────────────────────────────

  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Bookmark', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL *',
              hintText: 'https://example.com',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText: 'Page title',
              prefixIcon: Icon(Icons.title),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Optional notes about this link',
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BookmarkFolder>(
            value: _selectedFolder,
            decoration: const InputDecoration(
              labelText: 'Folder',
              prefixIcon: Icon(Icons.folder),
              border: OutlineInputBorder(),
            ),
            items: BookmarkFolder.values
                .map((f) => DropdownMenuItem(
                      value: f,
                      child: Text('${f.emoji} ${f.label}'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedFolder = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags',
              hintText: 'flutter, dart, mobile (comma-separated)',
              prefixIcon: Icon(Icons.tag),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addBookmark,
              icon: const Icon(Icons.bookmark_add),
              label: const Text('Save Bookmark'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Tab ────────────────────────────────────────────

  Widget _buildStatsTab() {
    final active = _items.where((b) => !b.isArchived).toList();
    final folders = _service.folderBreakdown(active);
    final topDomains = _service.topDomains(active, limit: 5);
    final tags = _service.tagBreakdown(active).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final tips = _service.suggestions(_items);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overview card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statTile('📚', 'Active', '${_service.activeCount(_items)}'),
                    _statTile('🗄️', 'Archived', '${_items.where((b) => b.isArchived).length}'),
                    _statTile('⭐', 'Favorites', '${_items.where((b) => b.isFavorite).length}'),
                    _statTile('👀', 'Total Visits',
                        '${_items.fold(0, (s, b) => s + b.visitCount)}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Top domains
        if (topDomains.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌐 Top Domains',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...topDomains.map((d) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Expanded(child: Text(d.key)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${d.value}', style: TextStyle(color: Colors.blue[700])),
                          ),
                        ]),
                      )),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Folder breakdown
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📁 By Folder',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...folders.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Text('${e.key.emoji} ${e.key.label}'),
                        const Spacer(),
                        Text('${e.value}'),
                      ]),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Tags
        if (tags.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏷️ Popular Tags',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.take(15).map((t) => Chip(
                          label: Text('#${t.key} (${t.value})', style: const TextStyle(fontSize: 12)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )).toList(),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Suggestions
        Card(
          color: Colors.amber[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 Suggestions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...tips.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(t, style: const TextStyle(fontSize: 14)),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statTile(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  // ─── Folders Tab ──────────────────────────────────────────

  Widget _buildFoldersTab() {
    final active = _items.where((b) => !b.isArchived).toList();
    final grouped = <BookmarkFolder, List<Bookmark>>{};
    for (final b in active) {
      grouped.putIfAbsent(b.folder, () => []).add(b);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: BookmarkFolder.values
          .where((f) => grouped.containsKey(f))
          .map((f) {
        final bookmarks = grouped[f]!;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Text(f.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(f.label),
            subtitle: Text('${bookmarks.length} bookmarks'),
            children: bookmarks.map((b) => ListTile(
                  title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(b.domain, style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (b.isFavorite)
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('${b.visitCount}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                  onTap: () => _recordVisit(b),
                )).toList(),
          ),
        );
      }).toList(),
    );
  }
}
