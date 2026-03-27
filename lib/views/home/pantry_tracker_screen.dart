import 'package:flutter/material.dart';
import '../../models/pantry_item.dart';
import '../../core/services/pantry_tracker_service.dart';
import '../../core/services/screen_persistence.dart';

/// Pantry Tracker Screen — track food items with expiration dates,
/// quantities, locations, and low-stock alerts.
///
/// Tabs:
///   Pantry: Browse/search/filter items by category and location
///   Add: Form to add new pantry items
///   Alerts: Expired and expiring-soon items, low stock warnings
///   Stats: Category breakdown, total value, location distribution
class PantryTrackerScreen extends StatefulWidget {
  const PantryTrackerScreen({super.key});

  @override
  State<PantryTrackerScreen> createState() => _PantryTrackerScreenState();
}

enum _SortMode { nameAZ, nameZA, expirationSoon, newest, category }

class _PantryTrackerScreenState extends State<PantryTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _persistence = ScreenPersistence<PantryItem>(
    storageKey: 'pantry_items',
    toJson: (e) => e.toJson(),
    fromJson: PantryItem.fromJson,
  );
  final List<PantryItem> _items = [];
  String _searchQuery = '';
  PantryCategory? _filterCategory;
  PantryLocation? _filterLocation;
  _SortMode _sortMode = _SortMode.expirationSoon;

  // Add-tab form
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: 'count');
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();
  final _thresholdController = TextEditingController();
  PantryCategory _selectedCategory = PantryCategory.other;
  PantryLocation _selectedLocation = PantryLocation.pantry;
  DateTime? _selectedExpiration;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final saved = await _persistence.load();
    if (mounted) setState(() => _items.addAll(saved));
  }

  void _persist() => _persistence.save(_items);

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  // ── Add item ──
  void _addItem() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final qty = double.tryParse(_quantityController.text) ?? 1;
    final price = double.tryParse(_priceController.text);
    final threshold = double.tryParse(_thresholdController.text);
    setState(() {
      _items.add(PantryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        category: _selectedCategory,
        location: _selectedLocation,
        quantity: qty,
        unit: _unitController.text.trim().isEmpty
            ? 'count'
            : _unitController.text.trim(),
        expirationDate: _selectedExpiration,
        addedAt: DateTime.now(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        price: price,
        lowStockThreshold: threshold,
      ));
    });
    _persist();
    _nameController.clear();
    _quantityController.text = '1';
    _unitController.text = 'count';
    _notesController.clear();
    _priceController.clear();
    _thresholdController.clear();
    _selectedExpiration = null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "$name" to pantry')),
    );
  }

  void _removeItem(String id) {
    setState(() => _items.removeWhere((i) => i.id == id));
    _persist();
  }

  void _adjustQuantity(String id, double delta) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    setState(() {
      final item = _items[idx];
      final newQty = (item.quantity + delta).clamp(0.0, 99999.0);
      _items[idx] = item.copyWith(quantity: newQty);
    });
    _persist();
  }

  // ── Filtering & sorting ──
  List<PantryItem> get _filteredItems {
    var list = _items.toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((i) => i.name.toLowerCase().contains(q)).toList();
    }
    if (_filterCategory != null) {
      list = list.where((i) => i.category == _filterCategory).toList();
    }
    if (_filterLocation != null) {
      list = list.where((i) => i.location == _filterLocation).toList();
    }
    switch (_sortMode) {
      case _SortMode.nameAZ:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case _SortMode.nameZA:
        list.sort((a, b) => b.name.compareTo(a.name));
        break;
      case _SortMode.expirationSoon:
        list.sort((a, b) {
          if (a.expirationDate == null && b.expirationDate == null) return 0;
          if (a.expirationDate == null) return 1;
          if (b.expirationDate == null) return -1;
          return a.expirationDate!.compareTo(b.expirationDate!);
        });
        break;
      case _SortMode.newest:
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case _SortMode.category:
        list.sort((a, b) => a.category.label.compareTo(b.category.label));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantry Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.kitchen), text: 'Pantry'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Add'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Alerts'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(theme),
          _buildAddTab(theme),
          _buildAlertsTab(theme),
          _buildStatsTab(theme),
        ],
      ),
    );
  }

  // ── Browse Tab ──
  Widget _buildBrowseTab(ThemeData theme) {
    final items = _filteredItems;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search pantry…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              FilterChip(
                label: Text(_filterCategory?.label ?? 'Category'),
                selected: _filterCategory != null,
                onSelected: (_) => _showCategoryFilter(),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(_filterLocation?.label ?? 'Location'),
                selected: _filterLocation != null,
                onSelected: (_) => _showLocationFilter(),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_SortMode>(
                initialValue: _sortMode,
                onSelected: (v) => setState(() => _sortMode = v),
                itemBuilder: (_) => [
                  for (final m in _SortMode.values)
                    PopupMenuItem(value: m, child: Text(m.name)),
                ],
                child: Chip(
                  avatar: const Icon(Icons.sort, size: 18),
                  label: const Text('Sort'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    _items.isEmpty
                        ? 'Your pantry is empty.\nAdd items in the Add tab!'
                        : 'No matching items.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.hintColor),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _buildItemCard(items[i], theme),
                ),
        ),
      ],
    );
  }

  Widget _buildItemCard(PantryItem item, ThemeData theme) {
    final daysLeft = item.daysUntilExpiration;
    Color? expiryColor;
    String? expiryText;
    if (item.isExpired) {
      expiryColor = Colors.red;
      expiryText = 'EXPIRED';
    } else if (daysLeft != null && daysLeft <= 3) {
      expiryColor = Colors.orange;
      expiryText = '$daysLeft day${daysLeft == 1 ? '' : 's'} left';
    } else if (daysLeft != null && daysLeft <= 7) {
      expiryColor = Colors.amber;
      expiryText = '$daysLeft days left';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(item.category.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.quantity} ${item.unit} • ${item.location.emoji} ${item.location.label}',
            ),
            if (expiryText != null)
              Text(expiryText, style: TextStyle(color: expiryColor, fontWeight: FontWeight.bold)),
            if (item.needsRestock)
              const Text('⚠️ Low stock', style: TextStyle(color: Colors.orange)),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: () => _adjustQuantity(item.id, -1),
              tooltip: 'Use one',
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () => _adjustQuantity(item.id, 1),
              tooltip: 'Add one',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _removeItem(item.id),
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  // ── Add Tab ──
  Widget _buildAddTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Item Name *',
              prefixIcon: Icon(Icons.label),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    prefixIcon: Icon(Icons.straighten),
                    hintText: 'lbs, oz, count…',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PantryCategory>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category),
            ),
            items: PantryCategory.values
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text('${c.emoji} ${c.label}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PantryLocation>(
            value: _selectedLocation,
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.place),
            ),
            items: PantryLocation.values
                .map((l) => DropdownMenuItem(
                      value: l,
                      child: Text('${l.emoji} ${l.label}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedLocation = v!),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.event),
            title: Text(_selectedExpiration != null
                ? 'Expires: ${_formatDate(_selectedExpiration!)}'
                : 'Set Expiration Date'),
            trailing: _selectedExpiration != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () =>
                        setState(() => _selectedExpiration = null),
                  )
                : null,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    _selectedExpiration ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (date != null) setState(() => _selectedExpiration = date);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price per unit (\$)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _thresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Low stock at',
                    prefixIcon: Icon(Icons.warning_amber),
                    hintText: 'e.g. 2',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Add to Pantry'),
          ),
        ],
      ),
    );
  }

  // ── Alerts Tab ──
  Widget _buildAlertsTab(ThemeData theme) {
    final expired = _items.where((i) => i.isExpired).toList();
    final expiringSoon = _items
        .where((i) => !i.isExpired && i.expiresWithin(7))
        .toList()
      ..sort((a, b) => a.expirationDate!.compareTo(b.expirationDate!));
    final lowStock = _items.where((i) => i.needsRestock).toList();

    if (expired.isEmpty && expiringSoon.isEmpty && lowStock.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
            const SizedBox(height: 12),
            Text('All clear! No alerts.',
                style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (expired.isNotEmpty) ...[
          _sectionHeader('🚨 Expired', Colors.red, theme),
          ...expired.map((i) => _buildItemCard(i, theme)),
          const SizedBox(height: 16),
        ],
        if (expiringSoon.isNotEmpty) ...[
          _sectionHeader('⏰ Expiring Soon (7 days)', Colors.orange, theme),
          ...expiringSoon.map((i) => _buildItemCard(i, theme)),
          const SizedBox(height: 16),
        ],
        if (lowStock.isNotEmpty) ...[
          _sectionHeader('📉 Low Stock', Colors.amber, theme),
          ...lowStock.map((i) => _buildItemCard(i, theme)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: theme.textTheme.titleMedium?.copyWith(color: color)),
    );
  }

  // ── Stats Tab ──
  Widget _buildStatsTab(ThemeData theme) {
    if (_items.isEmpty) {
      return Center(
        child: Text('Add items to see stats.',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)),
      );
    }

    final service = PantryTrackerService(items: _items);
    final summary = service.getSummary();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overview cards
        Row(
          children: [
            _statCard('Total Items', '${summary.totalItems}',
                Icons.inventory_2, Colors.blue, theme),
            const SizedBox(width: 8),
            _statCard('Expired', '${summary.expiredItems}',
                Icons.dangerous, Colors.red, theme),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _statCard('Expiring Soon', '${summary.expiringSoon}',
                Icons.warning_amber, Colors.orange, theme),
            const SizedBox(width: 8),
            _statCard('Low Stock', '${summary.lowStockItems}',
                Icons.trending_down, Colors.amber, theme),
          ],
        ),
        if (summary.totalValue > 0) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.green),
              title: const Text('Estimated Pantry Value'),
              trailing: Text('\$${summary.totalValue.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('By Category', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...summary.itemsByCategory.entries.map((e) => ListTile(
              leading: Text(e.key.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(e.key.label),
              trailing: Text('${e.value}',
                  style: theme.textTheme.titleSmall),
            )),
        const SizedBox(height: 16),
        Text('By Location', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...summary.itemsByLocation.entries.map((e) => ListTile(
              leading: Text(e.key.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(e.key.label),
              trailing: Text('${e.value}',
                  style: theme.textTheme.titleSmall),
            )),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
      ThemeData theme) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineSmall),
              Text(label,
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──
  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('All Categories'),
            onTap: () {
              setState(() => _filterCategory = null);
              Navigator.pop(context);
            },
          ),
          ...PantryCategory.values.map((c) => ListTile(
                leading: Text(c.emoji),
                title: Text(c.label),
                selected: _filterCategory == c,
                onTap: () {
                  setState(() => _filterCategory = c);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  void _showLocationFilter() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('All Locations'),
            onTap: () {
              setState(() => _filterLocation = null);
              Navigator.pop(context);
            },
          ),
          ...PantryLocation.values.map((l) => ListTile(
                leading: Text(l.emoji),
                title: Text(l.label),
                selected: _filterLocation == l,
                onTap: () {
                  setState(() => _filterLocation = l);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.month}/${d.day}/${d.year}';
}
