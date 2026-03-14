import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/grocery_list_service.dart';
import '../../models/grocery_item.dart';

/// Screen for managing grocery lists with categorized items,
/// quantities, price estimates, and check-off functionality.
class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'grocery_list_data';
  late final GroceryListService _service;
  late TabController _tabController;
  String? _selectedListId;

  @override
  void initState() {
    super.initState();
    _service = GroceryListService();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null && json.isNotEmpty) {
      try {
        _service.importFromJson(json);
        if (mounted) setState(() {});
      } catch (_) {}
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _service.exportToJson());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _createList() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Grocery List'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'List name (e.g. Weekly Shop)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  final list = _service.createList(controller.text.trim());
                  _selectedListId = list.id;
                });
                _saveData();
                _saveData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    if (_selectedListId == null) return;

    final nameController = TextEditingController();
    final noteController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    var category = GroceryCategory.other;
    var unit = GroceryUnit.piece;
    var priority = GroceryPriority.normal;

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
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<GroceryUnit>(
                        value: unit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: GroceryUnit.values.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(u.label),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => unit = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GroceryCategory>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: GroceryCategory.values.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text('${c.emoji} ${c.label}'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => category = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GroceryPriority>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: GroceryPriority.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text('${p.emoji} ${p.label}'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => priority = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Est. price (optional)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
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
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    _service.addItem(
                      _selectedListId!,
                      name: nameController.text.trim(),
                      category: category,
                      quantity: double.tryParse(quantityController.text) ?? 1,
                      unit: unit,
                      priority: priority,
                      note: noteController.text.trim(),
                      estimatedPrice: double.tryParse(priceController.text),
                    );
                  });
                  _saveData();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _service.getSummary();
    final active = _service.activeLists;
    final archived = _service.archivedLists;
    final selectedList =
        _selectedListId != null ? _service.getList(_selectedListId!) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 Grocery Lists'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Lists (${active.length})'),
            const Tab(text: 'Shopping'),
            const Tab(text: 'Summary'),
          ],
        ),
        actions: [
          if (_tabController.index == 1 && selectedList != null)
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'clear_checked':
                    setState(() => _service.clearChecked(_selectedListId!));
                    _saveData();
                    break;
                  case 'duplicate':
                    setState(() => _service.duplicateList(_selectedListId!));
                    _saveData();
                    break;
                  case 'archive':
                    setState(() {
                      _service.toggleArchive(_selectedListId!);
                      _selectedListId = null;
                    });
                    _saveData();
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'clear_checked',
                  child: ListTile(
                    leading: Icon(Icons.cleaning_services),
                    title: Text('Clear checked'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Duplicate list'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'archive',
                  child: ListTile(
                    leading: Icon(Icons.archive),
                    title: Text('Archive list'),
                    dense: true,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListsTab(active, archived),
          _buildShoppingTab(selectedList),
          _buildSummaryTab(summary),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _createList();
          } else if (_tabController.index == 1 && _selectedListId != null) {
            _addItem();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListsTab(List<GroceryList> active, List<GroceryList> archived) {
    if (active.isEmpty && archived.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No grocery lists yet',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Tap + to create your first list',
                style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          Text('Active Lists',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700])),
          const SizedBox(height: 8),
          ...active.map((list) => _buildListCard(list)),
        ],
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Archived',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500])),
          const SizedBox(height: 8),
          ...archived.map((list) => _buildListCard(list, isArchived: true)),
        ],
      ],
    );
  }

  Widget _buildListCard(GroceryList list, {bool isArchived = false}) {
    final isSelected = _selectedListId == list.id;
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Colors.blue[50]
          : isArchived
              ? Colors.grey[100]
              : null,
      child: ListTile(
        title: Text(list.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: isArchived ? TextDecoration.lineThrough : null,
            )),
        subtitle: Text(
          '${list.checkedItems}/${list.totalItems} items checked'
          '${list.estimatedTotal > 0 ? ' • \$${list.estimatedTotal.toStringAsFixed(2)}' : ''}',
        ),
        trailing: list.totalItems > 0
            ? SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: list.progress,
                      strokeWidth: 3,
                      backgroundColor: Colors.grey[200],
                    ),
                    Text('${(list.progress * 100).round()}%',
                        style: const TextStyle(fontSize: 10)),
                  ],
                ),
              )
            : null,
        onTap: () {
          setState(() {
            _selectedListId = list.id;
            _tabController.animateTo(1);
          });
          _saveData();
        },
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.archive),
                  title: Text(isArchived ? 'Unarchive' : 'Archive'),
                  onTap: () {
                    setState(() => _service.toggleArchive(list.id));
                    _saveData();
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Duplicate'),
                  onTap: () {
                    setState(() => _service.duplicateList(list.id));
                    _saveData();
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    setState(() {
                      _service.deleteList(list.id);
                      if (_selectedListId == list.id) _selectedListId = null;
                    });
                    _saveData();
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShoppingTab(GroceryList? list) {
    if (list == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Select a list to start shopping',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    final grouped = _service.getItemsByCategory(list.id);
    if (list.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_shopping_cart, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('${list.name} is empty',
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Tap + to add items',
                style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(list.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${list.checkedItems}/${list.totalItems}',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: list.progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              if (list.estimatedTotal > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Estimated: \$${list.estimatedTotal.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
        // Items by category
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      '${entry.key.emoji} ${entry.key.label}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  ...entry.value.map((item) => _buildItemTile(list.id, item)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(String listId, GroceryItem item) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() => _service.removeItem(listId, item.id));
        _saveData();
      },
      child: ListTile(
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (_) {
            setState(() => _service.toggleItem(listId, item.id));
            _saveData();
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            color: item.isChecked ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          '${item.quantity} ${item.unit.label}'
          '${item.note.isNotEmpty ? ' • ${item.note}' : ''}'
          '${item.estimatedPrice != null ? ' • \$${(item.estimatedPrice! * item.quantity).toStringAsFixed(2)}' : ''}',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: Text(item.priority.emoji),
      ),
    );
  }

  Widget _buildSummaryTab(GrocerySummary summary) {
    final frequent = _service.frequentItems(limit: 10);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats cards
        Row(
          children: [
            _buildStatCard('Lists', '${summary.activeLists}', Icons.list, Colors.blue),
            const SizedBox(width: 8),
            _buildStatCard('Items', '${summary.totalItems}', Icons.shopping_bag, Colors.green),
            const SizedBox(width: 8),
            _buildStatCard('Remaining', '${summary.remainingItems}', Icons.pending, Colors.orange),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatCard('Checked', '${summary.checkedItems}', Icons.check_circle, Colors.teal),
            const SizedBox(width: 8),
            _buildStatCard(
                'Est. Total',
                '\$${summary.estimatedTotal.toStringAsFixed(0)}',
                Icons.attach_money,
                Colors.purple),
            const SizedBox(width: 8),
            _buildStatCard(
                'Archived', '${summary.archivedLists}', Icons.archive, Colors.grey),
          ],
        ),
        const SizedBox(height: 24),

        // Category breakdown
        if (summary.itemsByCategory.isNotEmpty) ...[
          const Text('Items by Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...summary.itemsByCategory.entries.map((entry) => ListTile(
                leading: Text(entry.key.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(entry.key.label),
                trailing: Text('${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                dense: true,
              )),
        ],

        // Frequent items
        if (frequent.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Frequently Added',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...frequent.map((entry) => ListTile(
                leading: const Icon(Icons.trending_up, size: 20),
                title: Text(entry.key),
                trailing: Text('${entry.value}x',
                    style: TextStyle(color: Colors.grey[600])),
                dense: true,
              )),
        ],
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}
