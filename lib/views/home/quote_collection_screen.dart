import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/quote_collection_service.dart';
import '../../core/services/screen_persistence.dart';
import '../../models/quote_entry.dart';

/// Quote Collection screen — save, browse, search, and discover
/// favorite quotes with categories, tags, and quote of the day.
class QuoteCollectionScreen extends StatefulWidget {
  const QuoteCollectionScreen({super.key});

  @override
  State<QuoteCollectionScreen> createState() => _QuoteCollectionScreenState();
}

class _QuoteCollectionScreenState extends State<QuoteCollectionScreen>
    with SingleTickerProviderStateMixin {
  final QuoteCollectionService _service = QuoteCollectionService();
  final _persistence = ScreenPersistence<QuoteEntry>(
    storageKey: 'quote_collection_entries',
    toJson: (e) => e.toJson(),
    fromJson: QuoteEntry.fromJson,
  );
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  QuoteCategory? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final saved = await _persistence.load();
    if (saved.isNotEmpty) {
      _service.loadAll(saved);
    } else {
      // Pre-load sample quotes for new users
      for (final q in QuoteCollectionService.sampleQuotes) {
        _service.addQuote(q);
      }
      await _save();
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    await _persistence.save(_service.quotes);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Collection'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.format_quote), text: 'All'),
            Tab(icon: Icon(Icons.star), text: 'Favorites'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'Discover'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllQuotesTab(
            service: _service,
            searchController: _searchController,
            searchQuery: _searchQuery,
            categoryFilter: _categoryFilter,
            onCategoryChanged: (c) => setState(() => _categoryFilter = c),
            onChanged: () {
              setState(() {});
              _save();
            },
          ),
          _FavoritesTab(
            service: _service,
            onChanged: () {
              setState(() {});
              _save();
            },
          ),
          _DiscoverTab(
            service: _service,
            onChanged: () {
              setState(() {});
              _save();
            },
          ),
          _StatsTab(service: _service),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddQuoteDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Quote'),
      ),
    );
  }

  Future<void> _showAddQuoteDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AddQuoteDialog(service: _service),
    );
    if (result == true) {
      await _save();
      if (mounted) setState(() {});
    }
  }
}

// ─── All Quotes Tab ────────────────────────────────────────────

class _AllQuotesTab extends StatelessWidget {
  final QuoteCollectionService service;
  final TextEditingController searchController;
  final String searchQuery;
  final QuoteCategory? categoryFilter;
  final ValueChanged<QuoteCategory?> onCategoryChanged;
  final VoidCallback onChanged;

  const _AllQuotesTab({
    required this.service,
    required this.searchController,
    required this.searchQuery,
    required this.categoryFilter,
    required this.onCategoryChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    var quotes = searchQuery.isNotEmpty
        ? service.search(searchQuery)
        : service.quotes;
    if (categoryFilter != null) {
      quotes = quotes.where((q) => q.category == categoryFilter).toList();
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search quotes, authors, tags...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
          ),
        ),

        // Category chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _FilterChip(
                label: 'All',
                selected: categoryFilter == null,
                onTap: () => onCategoryChanged(null),
              ),
              ...QuoteCategory.values.map((c) => _FilterChip(
                    label: '${c.emoji} ${c.label}',
                    selected: categoryFilter == c,
                    onTap: () => onCategoryChanged(
                        categoryFilter == c ? null : c),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Quote count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${quotes.length} quote${quotes.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Quote list
        Expanded(
          child: quotes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.format_quote, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No quotes found',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: quotes.length,
                  itemBuilder: (ctx, i) => _QuoteCard(
                    quote: quotes[i],
                    service: service,
                    onChanged: onChanged,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Favorites Tab ─────────────────────────────────────────────

class _FavoritesTab extends StatelessWidget {
  final QuoteCollectionService service;
  final VoidCallback onChanged;

  const _FavoritesTab({required this.service, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final favorites = service.favorites;
    if (favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.amber),
            SizedBox(height: 12),
            Text('No favorites yet', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 4),
            Text('Tap the ★ on any quote to add it here',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: favorites.length,
      itemBuilder: (ctx, i) => _QuoteCard(
        quote: favorites[i],
        service: service,
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Discover Tab ──────────────────────────────────────────────

class _DiscoverTab extends StatefulWidget {
  final QuoteCollectionService service;
  final VoidCallback onChanged;

  const _DiscoverTab({required this.service, required this.onChanged});

  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab> {
  QuoteEntry? _randomQuote;

  @override
  Widget build(BuildContext context) {
    final qotd = widget.service.quoteOfTheDay();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote of the Day
          if (qotd != null) ...[
            Text('✨ Quote of the Day',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _HighlightQuoteCard(quote: qotd, service: widget.service, onChanged: widget.onChanged),
            const SizedBox(height: 24),
          ],

          // Random quote button
          Text('🎲 Random Quote',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_randomQuote != null)
            _HighlightQuoteCard(
                quote: _randomQuote!, service: widget.service, onChanged: widget.onChanged),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _randomQuote = widget.service.randomQuote();
                });
              },
              icon: const Icon(Icons.shuffle),
              label: Text(
                  _randomQuote == null ? 'Show Random Quote' : 'Another One!'),
            ),
          ),
          const SizedBox(height: 24),

          // Authors
          if (widget.service.authors.isNotEmpty) ...[
            Text('✍️ Authors in Your Collection',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.service.authors.map((author) {
                final count = widget.service.byAuthor(author).length;
                return Chip(
                  avatar: CircleAvatar(
                    child: Text('$count', style: const TextStyle(fontSize: 11)),
                  ),
                  label: Text(author),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Stats Tab ─────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final QuoteCollectionService service;

  const _StatsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final breakdown = service.categoryBreakdown;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          Row(
            children: [
              _StatCard(
                icon: Icons.format_quote,
                label: 'Total Quotes',
                value: '${service.totalQuotes}',
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.star,
                label: 'Favorites',
                value: '${service.favoriteCount}',
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                icon: Icons.person,
                label: 'Authors',
                value: '${service.authors.length}',
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.tag,
                label: 'Tags',
                value: '${service.allTags.length}',
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                icon: Icons.short_text,
                label: 'Avg Words',
                value: service.averageWordCount.toStringAsFixed(1),
                color: Colors.teal,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.category,
                label: 'Categories',
                value: '${breakdown.length}',
                color: Colors.deepOrange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Category breakdown
          Text('📊 Category Breakdown',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (breakdown.isEmpty)
            const Text('No quotes yet', style: TextStyle(color: Colors.grey))
          else
            ...breakdown.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)),
          ...breakdown.entries.toList()
              .map((e) => _CategoryBar(
                    category: e.key,
                    count: e.value,
                    maxCount: breakdown.values
                        .reduce((a, b) => a > b ? a : b),
                  )),

          const SizedBox(height: 24),

          // Longest & shortest
          if (service.longestQuote != null) ...[
            Text('📏 Longest Quote',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '"${service.longestQuote!.text}"',
              style: const TextStyle(fontStyle: FontStyle.italic),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '— ${service.longestQuote!.author ?? 'Unknown'} (${service.longestQuote!.wordCount} words)',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
          ],
          if (service.shortestQuote != null) ...[
            Text('📐 Shortest Quote',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '"${service.shortestQuote!.text}"',
              style: const TextStyle(fontStyle: FontStyle.italic),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '— ${service.shortestQuote!.author ?? 'Unknown'} (${service.shortestQuote!.wordCount} words)',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final QuoteEntry quote;
  final QuoteCollectionService service;
  final VoidCallback onChanged;

  const _QuoteCard({
    required this.quote,
    required this.service,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showQuoteDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: quote.category.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${quote.category.emoji} ${quote.category.label}',
                      style: TextStyle(
                        fontSize: 11,
                        color: quote.category.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Favorite toggle
                  IconButton(
                    icon: Icon(
                      quote.isFavorite ? Icons.star : Icons.star_border,
                      color: quote.isFavorite ? Colors.amber : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      service.toggleFavorite(quote.id);
                      onChanged();
                    },
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quote text
              Text(
                '"${quote.text}"',
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),

              // Author
              if (quote.author != null)
                Text(
                  '— ${quote.author}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),

              // Tags
              if (quote.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: quote.tags
                      .map((t) => Chip(
                            label: Text(t, style: const TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 6),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showQuoteDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '"${quote.text}"',
                style: const TextStyle(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              if (quote.author != null)
                Text(
                  '— ${quote.author}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (quote.source != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Source: ${quote.source}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: quote.category.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${quote.category.emoji} ${quote.category.label}',
                      style: TextStyle(color: quote.category.color),
                    ),
                  ),
                  const Spacer(),
                  Text('${quote.wordCount} words',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
              if (quote.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: quote.tags.map((t) => Chip(label: Text(t))).toList(),
                ),
              ],
              if (quote.notes != null) ...[
                const SizedBox(height: 16),
                Text('Notes',
                    style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(quote.notes!),
              ],
              const SizedBox(height: 20),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '"${quote.text}"\n— ${quote.author ?? 'Unknown'}',
                      ));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Quote copied!')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      service.toggleFavorite(quote.id);
                      onChanged();
                      Navigator.pop(ctx);
                    },
                    icon: Icon(quote.isFavorite
                        ? Icons.star
                        : Icons.star_border),
                    label: Text(
                        quote.isFavorite ? 'Unfavorite' : 'Favorite'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      service.removeQuote(quote.id);
                      onChanged();
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightQuoteCard extends StatelessWidget {
  final QuoteEntry quote;
  final QuoteCollectionService service;
  final VoidCallback onChanged;

  const _HighlightQuoteCard({
    required this.quote,
    required this.service,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              quote.category.color.withAlpha(25),
              quote.category.color.withAlpha(8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote, size: 32, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              quote.text,
              style: const TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (quote.author != null)
                  Text(
                    '— ${quote.author}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    quote.isFavorite ? Icons.star : Icons.star_border,
                    color: quote.isFavorite ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () {
                    service.toggleFavorite(quote.id);
                    onChanged();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: '"${quote.text}"\n— ${quote.author ?? 'Unknown'}',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quote copied!')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(label,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final QuoteCategory category;
  final int count;
  final int maxCount;

  const _CategoryBar({
    required this.category,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '${category.emoji} ${category.label}',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: maxCount > 0 ? count / maxCount : 0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(category.color),
                minHeight: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Add Quote Dialog ──────────────────────────────────────────

class _AddQuoteDialog extends StatefulWidget {
  final QuoteCollectionService service;

  const _AddQuoteDialog({required this.service});

  @override
  State<_AddQuoteDialog> createState() => _AddQuoteDialogState();
}

class _AddQuoteDialogState extends State<_AddQuoteDialog> {
  final _textController = TextEditingController();
  final _authorController = TextEditingController();
  final _sourceController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();
  QuoteCategory _category = QuoteCategory.motivation;
  final List<String> _tags = [];

  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
    _sourceController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Quote'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Quote *',
                hintText: 'Enter the quote text...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author',
                hintText: 'Who said this?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Source',
                hintText: 'Book, speech, movie...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<QuoteCategory>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: QuoteCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.emoji} ${c.label}'),
                      ))
                  .toList(),
              onChanged: (c) {
                if (c != null) setState(() => _category = c);
              },
            ),
            const SizedBox(height: 12),
            // Tags
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Add tag',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final tag = _tagController.text.trim();
                    if (tag.isNotEmpty && !_tags.contains(tag)) {
                      setState(() {
                        _tags.add(tag);
                        _tagController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: _tags
                    .map((t) => Chip(
                          label: Text(t),
                          onDeleted: () => setState(() => _tags.remove(t)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Why does this quote resonate?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final text = _textController.text.trim();
            if (text.isEmpty) return;
            widget.service.addQuote(QuoteEntry(
              id: 'q_${DateTime.now().millisecondsSinceEpoch}',
              text: text,
              author: _authorController.text.trim().isNotEmpty
                  ? _authorController.text.trim()
                  : null,
              source: _sourceController.text.trim().isNotEmpty
                  ? _sourceController.text.trim()
                  : null,
              category: _category,
              tags: List.from(_tags),
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
              createdAt: DateTime.now(),
            ));
            Navigator.pop(context, true);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
