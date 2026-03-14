import 'package:flutter/material.dart';
import '../../core/services/home_inventory_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/inventory_item.dart';

/// Home Inventory Tracker — catalog belongings by room, track values,
/// condition ratings, and generate insurance reports.
class HomeInventoryScreen extends StatefulWidget {
  const HomeInventoryScreen({super.key});

  @override
  State<HomeInventoryScreen> createState() => _HomeInventoryScreenState();
}

class _HomeInventoryScreenState extends State<HomeInventoryScreen>
    with SingleTickerProviderStateMixin, PersistentStateMixin {
  @override
  String get storageKey => 'home_inventory_data';
  @override
  String exportData() => _service.exportToJson();
  @override
  void importData(String json) => _service.importFromJson(json);

  final HomeInventoryService _service = HomeInventoryService();
  late TabController _tabController;
  InventoryRoom? _filterRoom;
  InventoryCategory? _filterCategory;
  String _searchQuery = '';
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initData();
  }

  Future<void> _initData() async {
    await initPersistence();
    // If no saved data was loaded, add sample data
    if (_service.items.isEmpty) {
      _loadSampleData();
      saveData();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    final now = DateTime.now();
    final samples = [
      InventoryItem(
        id: 'inv1',
        name: 'Samsung 65" OLED TV',
        room: InventoryRoom.livingRoom,
        category: InventoryCategory.electronics,
        condition: ItemCondition.excellent,
        purchasePrice: 1799.99,
        purchaseDate: now.subtract(const Duration(days: 180)),
        brand: 'Samsung',
        model: 'QN65S95D',
      ),
      InventoryItem(
        id: 'inv2',
        name: 'Leather Sectional Sofa',
        room: InventoryRoom.livingRoom,
        category: InventoryCategory.furniture,
        condition: ItemCondition.good,
        purchasePrice: 2499.00,
        purchaseDate: now.subtract(const Duration(days: 400)),
        brand: 'West Elm',
      ),
      InventoryItem(
        id: 'inv3',
        name: 'KitchenAid Stand Mixer',
        room: InventoryRoom.kitchen,
        category: InventoryCategory.appliance,
        condition: ItemCondition.good,
        purchasePrice: 449.99,
        purchaseDate: now.subtract(const Duration(days: 800)),
        brand: 'KitchenAid',
        model: 'Artisan 5-Qt',
        serialNumber: 'KA-29384756',
      ),
      InventoryItem(
        id: 'inv4',
        name: 'MacBook Pro 16"',
        room: InventoryRoom.office,
        category: InventoryCategory.electronics,
        condition: ItemCondition.excellent,
        purchasePrice: 2499.00,
        purchaseDate: now.subtract(const Duration(days: 90)),
        brand: 'Apple',
        model: 'M3 Max',
        serialNumber: 'C02X9876WXYZ',
      ),
      InventoryItem(
        id: 'inv5',
        name: 'Dyson V15 Vacuum',
        room: InventoryRoom.storage,
        category: InventoryCategory.appliance,
        condition: ItemCondition.good,
        purchasePrice: 749.99,
        purchaseDate: now.subtract(const Duration(days: 500)),
        brand: 'Dyson',
        model: 'V15 Detect',
      ),
      InventoryItem(
        id: 'inv6',
        name: 'Queen Bed Frame',
        room: InventoryRoom.bedroom,
        category: InventoryCategory.furniture,
        condition: ItemCondition.good,
        purchasePrice: 899.00,
        purchaseDate: now.subtract(const Duration(days: 1200)),
        brand: 'Crate & Barrel',
      ),
      InventoryItem(
        id: 'inv7',
        name: 'Fender Stratocaster',
        room: InventoryRoom.office,
        category: InventoryCategory.instrument,
        condition: ItemCondition.excellent,
        purchasePrice: 1299.00,
        purchaseDate: now.subtract(const Duration(days: 600)),
        brand: 'Fender',
        model: 'Player Series',
        serialNumber: 'MX22045678',
      ),
    ];
    for (final s in samples) {
      _service.addItem(s);
    }
    _nextId = 8;
  }

  List<InventoryItem> get _filteredItems {
    var items = _service.items;
    if (_filterRoom != null) {
      items = items.where((i) => i.room == _filterRoom).toList();
    }
    if (_filterCategory != null) {
      items = items.where((i) => i.category == _filterCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      items = _service.search(_searchQuery)
          .where((i) =>
              (_filterRoom == null || i.room == _filterRoom) &&
              (_filterCategory == null || i.category == _filterCategory))
          .toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Inventory'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Items'),
            Tab(icon: Icon(Icons.room), text: 'By Room'),
            Tab(icon: Icon(Icons.analytics), text: 'Summary'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            onPressed: _showInsuranceReport,
            tooltip: 'Insurance Report',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemsTab(),
          _buildRoomsTab(),
          _buildSummaryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItemsTab() {
    final items = _filteredItems;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<InventoryRoom?>(
                value: _filterRoom,
                hint: const Text('Room'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Rooms')),
                  ...InventoryRoom.values.map((r) =>
                      DropdownMenuItem(value: r, child: Text(r.label))),
                ],
                onChanged: (v) => setState(() => _filterRoom = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No items found'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, idx) {
                    final item = items[idx];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(item.room.iconData.emoji,
                              style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                            '${item.category.label} • ${item.condition.label} • \$${item.estimatedValue.toStringAsFixed(0)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.room.label,
                                style: Theme.of(ctx).textTheme.bodySmall),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'delete') {
                                  setState(
                                      () => _service.removeItem(item.id));
                                  saveData();
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => _showItemDetail(item),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRoomsTab() {
    final summary = _service.getSummary();
    return ListView.builder(
      itemCount: summary.roomBreakdown.length,
      itemBuilder: (ctx, idx) {
        final room = summary.roomBreakdown[idx];
        final roomItems = _service.getItemsByRoom(room.room);
        return ExpansionTile(
          leading: CircleAvatar(
            child: Text(room.room.iconData.emoji,
                style: const TextStyle(fontSize: 20)),
          ),
          title: Text(room.room.label),
          subtitle: Text(
              '${room.itemCount} items • \$${room.totalEstimatedValue.toStringAsFixed(0)} (${room.percentOfTotal.toStringAsFixed(1)}%)'),
          children: roomItems
              .map((item) => ListTile(
                    contentPadding:
                        const EdgeInsets.only(left: 72, right: 16),
                    title: Text(item.name),
                    subtitle: Text(
                        '${item.category.label} • ${item.condition.label}'),
                    trailing: Text(
                        '\$${item.estimatedValue.toStringAsFixed(0)}'),
                    onTap: () => _showItemDetail(item),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildSummaryTab() {
    final summary = _service.getSummary();
    if (summary.totalItems == 0) {
      return const Center(child: Text('Add items to see your summary'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _summaryCard('Total Items', '${summary.totalItems}',
                  Icons.inventory_2, Colors.blue),
              const SizedBox(width: 8),
              _summaryCard(
                  'Purchase Value',
                  '\$${summary.totalPurchaseValue.toStringAsFixed(0)}',
                  Icons.receipt_long,
                  Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _summaryCard(
                  'Estimated Value',
                  '\$${summary.totalEstimatedValue.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.orange),
              const SizedBox(width: 8),
              _summaryCard(
                  'Depreciation',
                  '\$${summary.depreciationAmount.toStringAsFixed(0)}',
                  Icons.trending_down,
                  Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Text('Category Breakdown',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...summary.categoryBreakdown.map((cat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                        width: 100, child: Text(cat.category.label)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: summary.totalEstimatedValue > 0
                            ? cat.totalEstimatedValue /
                                summary.totalEstimatedValue
                            : 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        '\$${cat.totalEstimatedValue.toStringAsFixed(0)}'),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Text('High-Value Items',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...summary.highValueItems.map((item) => ListTile(
                dense: true,
                title: Text(item.name),
                subtitle: Text('${item.room.label} • ${item.brand ?? ""}'),
                trailing: Text(
                    '\$${item.estimatedValue.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetail(InventoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Room', item.room.label),
              _detailRow('Category', item.category.label),
              _detailRow('Condition', item.condition.label),
              _detailRow('Purchase Price',
                  '\$${item.purchasePrice.toStringAsFixed(2)}'),
              _detailRow('Estimated Value',
                  '\$${item.estimatedValue.toStringAsFixed(2)}'),
              if (item.brand != null) _detailRow('Brand', item.brand!),
              if (item.model != null) _detailRow('Model', item.model!),
              if (item.serialNumber != null)
                _detailRow('Serial #', item.serialNumber!),
              if (item.purchaseDate != null)
                _detailRow('Purchased',
                    '${item.purchaseDate!.month}/${item.purchaseDate!.day}/${item.purchaseDate!.year}'),
              if (item.description != null)
                _detailRow('Description', item.description!),
              if (item.notes != null) _detailRow('Notes', item.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    var room = InventoryRoom.livingRoom;
    var category = InventoryCategory.electronics;
    var condition = ItemCondition.good;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Item Name *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Purchase Price *'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<InventoryRoom>(
                  value: room,
                  decoration: const InputDecoration(labelText: 'Room'),
                  items: InventoryRoom.values
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(r.label)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => room = v ?? room),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<InventoryCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: InventoryCategory.values
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.label)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => category = v ?? category),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ItemCondition>(
                  value: condition,
                  decoration: const InputDecoration(labelText: 'Condition'),
                  items: ItemCondition.values
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.label)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => condition = v ?? condition),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(labelText: 'Brand'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(labelText: 'Model'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: serialCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Serial Number'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim());
                if (name.isEmpty || price == null) return;
                setState(() {
                  _service.addItem(InventoryItem(
                    id: 'inv${_nextId++}',
                    name: name,
                    room: room,
                    category: category,
                    condition: condition,
                    purchasePrice: price,
                    purchaseDate: DateTime.now(),
                    brand: brandCtrl.text.trim().isEmpty
                        ? null
                        : brandCtrl.text.trim(),
                    model: modelCtrl.text.trim().isEmpty
                        ? null
                        : modelCtrl.text.trim(),
                    serialNumber: serialCtrl.text.trim().isEmpty
                        ? null
                        : serialCtrl.text.trim(),
                  ));
                });
                saveData();
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInsuranceReport() {
    final report = _service.generateInsuranceReport();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insurance Report'),
        content: SingleChildScrollView(
          child: SelectableText(
            report,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
