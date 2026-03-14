import 'package:flutter/material.dart';
import '../../models/wishlist_item.dart';
import '../../core/services/wishlist_service.dart';
import '../../core/services/screen_persistence.dart';

/// Wishlist Screen — 4-tab UI for tracking things you want to buy.
///
/// Tabs:
///   Add: Form with name, category, urgency, price, URL, tags, notes
///   List: Searchable/filterable list with sort options, favorites, price badges
///   Purchased: History of bought items with satisfaction ratings
///   Insights: Budget impact, category breakdown, price trends, suggestions
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = const WishlistService();
  final _persistence = ScreenPersistence<WishlistItem>(
    storageKey: 'wishlist_items',
    toJson: (e) => e.toJson(),
    fromJson: WishlistItem.fromJson,
  );
  final List<WishlistItem> _items = [];
  String _searchQuery = '';
  WishlistCategory? _filterCategory;
  WishlistUrgency? _filterUrgency;
  _SortMode _sortMode = _SortMode.newest;
  bool _favoritesOnly = false;

  // Add-tab form state
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();
  WishlistCategory _selectedCategory = WishlistCategory.other;
  WishlistUrgency _selectedUrgency = WishlistUrgency.considering;
  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final saved = await _persistence.load();
    if (saved.isNotEmpty && mounted) {
      setState(() => _items.addAll(saved));
    }
  }

  void _persistItems() {
    _persistence.save(_items);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_nameController.text.trim().isEmpty) return;
    final item = WishlistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      category: _selectedCategory,
      urgency: _selectedUrgency,
      estimatedPrice: double.tryParse(_priceController.text),
      url: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      createdAt: DateTime.now(),
      tags: List.from(_selectedTags),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    setState(() {
      _items.add(item);
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _urlController.clear();
      _notesController.clear();
      _tagController.clear();
      _selectedTags.clear();
      _selectedCategory = WishlistCategory.other;
      _selectedUrgency = WishlistUrgency.considering;
    });
    _persistItems();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "${item.name}" to wishlist')),
    );
    _tabController.animateTo(1);
  }

  void _deleteItem(String id) {
    setState(() => _items.removeWhere((i) => i.id == id));
    _persistItems();
  }

  void _toggleFavorite(String id) {
    setState(() {
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx >= 0) _items[idx] = _items[idx].toggleFavorite();
    });
    _persistItems();
  }

  void _markPurchased(String id) {
    final item = _items.firstWhere((i) => i.id == id);
    _showPurchaseDialog(item);
  }

  void _addPriceUpdate(String id) {
    final item = _items.firstWhere((i) => i.id == id);
    _showPriceUpdateDialog(item);
  }

  List<WishlistItem> get _filteredItems {
    var items = _items.where((i) => !i.isPurchased).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((i) {
        return i.name.toLowerCase().contains(q) ||
            (i.description?.toLowerCase().contains(q) ?? false) ||
            i.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    if (_filterCategory != null) {
      items = items.where((i) => i.category == _filterCategory).toList();
    }
    if (_filterUrgency != null) {
      items = items.where((i) => i.urgency == _filterUrgency).toList();
    }
    if (_favoritesOnly) {
      items = items.where((i) => i.isFavorite).toList();
    }

    switch (_sortMode) {
      case _SortMode.newest:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortMode.oldest:
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortMode.priceHigh:
        items.sort((a, b) =>
            (b.estimatedPrice ?? 0).compareTo(a.estimatedPrice ?? 0));
      case _SortMode.priceLow:
        items.sort((a, b) =>
            (a.estimatedPrice ?? 0).compareTo(b.estimatedPrice ?? 0));
      case _SortMode.urgency:
        items.sort((a, b) => a.urgency.value.compareTo(b.urgency.value));
    }
    return items;
  }

  List<WishlistItem> get _purchasedItems =>
      _items.where((i) => i.isPurchased).toList()
        ..sort((a, b) =>
            (b.purchasedAt ?? b.createdAt)
                .compareTo(a.purchasedAt ?? a.createdAt));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 Wishlist'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Add'),
            Tab(icon: Icon(Icons.list), text: 'List'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Purchased'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddTab(),
          _buildListTab(),
          _buildPurchasedTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  // ── Add Tab ─────────────────────────────────────────────────

  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Item Name *',
              hintText: 'What do you want?',
              prefixIcon: Icon(Icons.shopping_cart),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Why do you want this?',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Category chips
          const Text('Category',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: WishlistCategory.values.map((cat) {
              return ChoiceChip(
                label: Text('${cat.emoji} ${cat.label}'),
                selected: _selectedCategory == cat,
                onSelected: (_) =>
                    setState(() => _selectedCategory = cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Urgency chips
          const Text('How much do you want it?',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: WishlistUrgency.values.map((urg) {
              return ChoiceChip(
                label: Text('${urg.emoji} ${urg.label}'),
                selected: _selectedUrgency == urg,
                selectedColor: urg.color.withValues(alpha: 0.3),
                onSelected: (_) =>
                    setState(() => _selectedUrgency = urg),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Price & URL
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Price',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Link (optional)',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tags
          const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    hintText: 'Add a tag',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      setState(() {
                        _selectedTags.add(val.trim());
                        _tagController.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (_tagController.text.trim().isNotEmpty) {
                    setState(() {
                      _selectedTags.add(_tagController.text.trim());
                      _tagController.clear();
                    });
                  }
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (_selectedTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _selectedTags.map((t) {
                return Chip(
                  label: Text(t),
                  onDeleted: () =>
                      setState(() => _selectedTags.remove(t)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),

          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Any thoughts or research...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // Submit
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Wishlist'),
            ),
          ),
        ],
      ),
    );
  }

  // ── List Tab ────────────────────────────────────────────────

  Widget _buildListTab() {
    final items = _filteredItems;
    return Column(
      children: [
        // Search + filter bar
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search wishlist...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_SortMode>(
                icon: const Icon(Icons.sort),
                onSelected: (m) => setState(() => _sortMode = m),
                itemBuilder: (_) => _SortMode.values
                    .map((m) => PopupMenuItem(
                          value: m,
                          child: Row(
                            children: [
                              if (_sortMode == m)
                                const Icon(Icons.check, size: 18),
                              const SizedBox(width: 8),
                              Text(m.label),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              IconButton(
                icon: Icon(_favoritesOnly
                    ? Icons.favorite
                    : Icons.favorite_border,
                    color: _favoritesOnly ? Colors.red : null),
                onPressed: () =>
                    setState(() => _favoritesOnly = !_favoritesOnly),
                tooltip: 'Favorites only',
              ),
            ],
          ),
        ),

        // Category filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _filterCategory == null,
                  onSelected: (_) =>
                      setState(() => _filterCategory = null),
                ),
              ),
              ...WishlistCategory.values.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text('${cat.emoji} ${cat.label}'),
                    selected: _filterCategory == cat,
                    onSelected: (_) => setState(
                        () => _filterCategory =
                            _filterCategory == cat ? null : cat),
                  ),
                );
              }),
            ],
          ),
        ),

        // Summary strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${items.length} items'),
              Text(
                'Total: \$${_service.totalWishlistCost(_items).toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Items
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text('No items yet.\nAdd something you want! 🛒',
                      textAlign: TextAlign.center))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _buildItemCard(items[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildItemCard(WishlistItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.urgency.color.withValues(alpha: 0.2),
          child: Text(item.category.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (item.isFavorite)
              const Icon(Icons.favorite, color: Colors.red, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${item.urgency.emoji} ${item.urgency.label}'),
                if (item.estimatedPrice != null) ...[
                  const Text(' · '),
                  Text('\$${item.estimatedPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
                if (item.priceTrend == PriceTrend.falling)
                  const Text(' 📉', style: TextStyle(fontSize: 12)),
                if (item.priceTrend == PriceTrend.rising)
                  const Text(' 📈', style: TextStyle(fontSize: 12)),
              ],
            ),
            Text('Added ${item.daysOnList}d ago',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 12)),
            if (item.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: item.tags
                    .map((t) => Chip(
                          label: Text(t,
                              style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'buy', child: Text('🛒 Mark Purchased')),
            const PopupMenuItem(
                value: 'price', child: Text('💲 Update Price')),
            PopupMenuItem(
                value: 'fav',
                child: Text(
                    item.isFavorite ? '💔 Unfavorite' : '❤️ Favorite')),
            const PopupMenuItem(
                value: 'delete',
                child: Text('🗑️ Remove',
                    style: TextStyle(color: Colors.red))),
          ],
          onSelected: (action) {
            switch (action) {
              case 'buy':
                _markPurchased(item.id);
              case 'price':
                _addPriceUpdate(item.id);
              case 'fav':
                _toggleFavorite(item.id);
              case 'delete':
                _deleteItem(item.id);
            }
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  // ── Purchased Tab ───────────────────────────────────────────

  Widget _buildPurchasedTab() {
    final items = _purchasedItems;
    if (items.isEmpty) {
      return const Center(
          child:
              Text('No purchases yet.\nMark items as bought! 🛍️',
                  textAlign: TextAlign.center));
    }
    return Column(
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statColumn('Bought', '${items.length}'),
              _statColumn('Spent',
                  '\$${_service.totalSpent(_items).toStringAsFixed(0)}'),
              _statColumn('Saved',
                  '\$${_service.totalSaved(_items).toStringAsFixed(0)}'),
              _statColumn('Avg Rating',
                  _service.avgSatisfaction(_items).toStringAsFixed(1)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(item.category.emoji,
                        style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.purchasedPrice != null)
                        Text(
                            'Paid \$${item.purchasedPrice!.toStringAsFixed(2)}'),
                      if (item.rating > 0)
                        Row(
                          children: List.generate(
                              5,
                              (s) => Icon(
                                    s < item.rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  )),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Insights Tab ────────────────────────────────────────────

  Widget _buildInsightsTab() {
    final suggestions = _service.suggestions(_items);
    final breakdown = _service.categoryBreakdown(_items);
    final spending = _service.spendingByCategory(_items);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          Row(
            children: [
              Expanded(
                  child: _insightCard(
                      '🛒 Wishlist',
                      '\$${_service.totalWishlistCost(_items).toStringAsFixed(0)}',
                      'Total cost')),
              const SizedBox(width: 8),
              Expanded(
                  child: _insightCard(
                      '💸 Spent',
                      '\$${_service.totalSpent(_items).toStringAsFixed(0)}',
                      'On purchases')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _insightCard(
                      '📊 Rate',
                      '${(_service.purchaseRate(_items) * 100).toStringAsFixed(0)}%',
                      'Purchase rate')),
              const SizedBox(width: 8),
              Expanded(
                  child: _insightCard(
                      '⏱️ Avg Days',
                      _service
                          .avgDaysToPurchase(_items)
                          .toStringAsFixed(0),
                      'To purchase')),
            ],
          ),
          const SizedBox(height: 8),
          _insightCard(
              '📅 Budget Impact',
              '\$${_service.budgetImpact(_items).toStringAsFixed(0)}/mo',
              'If you buy all urgent items over 3 months'),
          const SizedBox(height: 16),

          // Suggestions
          const Text('💡 Suggestions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(s),
                  ),
                ),
              )),
          const SizedBox(height: 16),

          // Category breakdown
          if (breakdown.isNotEmpty) ...[
            const Text('📂 By Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...breakdown.entries.map((e) {
              final spent = spending[e.key];
              return ListTile(
                leading: Text(e.key.emoji,
                    style: const TextStyle(fontSize: 24)),
                title: Text(e.key.label),
                subtitle: spent != null
                    ? Text(
                        'Spent: \$${spent.toStringAsFixed(0)}')
                    : null,
                trailing: Chip(label: Text('${e.value}')),
                dense: true,
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  Widget _statColumn(String label, String value) => Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );

  Widget _insightCard(String title, String value, String subtitle) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.outline)),
            ],
          ),
        ),
      );

  // ── Dialogs ─────────────────────────────────────────────────

  void _showPurchaseDialog(WishlistItem item) {
    final priceCtl = TextEditingController(
        text: item.estimatedPrice?.toStringAsFixed(2) ?? '');
    int rating = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Bought "${item.name}"?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceCtl,
                decoration: const InputDecoration(
                  labelText: 'Actual Price',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text('How satisfied are you?'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () =>
                        setDlgState(() => rating = i + 1),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                setState(() {
                  final idx =
                      _items.indexWhere((i) => i.id == item.id);
                  if (idx >= 0) {
                    _items[idx] = _items[idx].markPurchased(
                      price: double.tryParse(priceCtl.text),
                      rating: rating,
                    );
                  }
                });
                _persistItems();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${item.name} marked as purchased!')),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPriceUpdateDialog(WishlistItem item) {
    final priceCtl = TextEditingController();
    final noteCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Price: ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.estimatedPrice != null)
              Text(
                  'Current: \$${item.estimatedPrice!.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtl,
              decoration: const InputDecoration(
                labelText: 'New Price',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g., Amazon sale',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final price = double.tryParse(priceCtl.text);
              if (price != null) {
                setState(() {
                  final idx =
                      _items.indexWhere((i) => i.id == item.id);
                  if (idx >= 0) {
                    _items[idx] = _items[idx].addPricePoint(price,
                        note: noteCtl.text.trim().isEmpty
                            ? null
                            : noteCtl.text.trim());
                  }
                });
                _persistItems();
                Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

// ── Sort modes ──────────────────────────────────────────────

enum _SortMode {
  newest('Newest First'),
  oldest('Oldest First'),
  priceHigh('Price: High → Low'),
  priceLow('Price: Low → High'),
  urgency('Urgency');

  final String label;
  const _SortMode(this.label);
}
