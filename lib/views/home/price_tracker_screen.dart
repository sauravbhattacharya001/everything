import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// A price tracking screen for monitoring item prices over time.
///
/// Users can add items they want to buy, record price observations,
/// view price history with trend indicators, and see which items
/// have dropped in price. Data persists via SharedPreferences.
class PriceTrackerScreen extends StatefulWidget {
  const PriceTrackerScreen({super.key});

  @override
  State<PriceTrackerScreen> createState() => _PriceTrackerScreenState();
}

class _PriceTrackerScreenState extends State<PriceTrackerScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'price_tracker_items';

  List<PriceTrackerItem> _items = [];
  late TabController _tabController;
  String _sortBy = 'recent'; // recent, name, biggest_drop

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final list = jsonDecode(data) as List;
      setState(() {
        _items = list.map((e) => PriceTrackerItem.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  List<PriceTrackerItem> get _activeItems =>
      _items.where((i) => !i.purchased).toList();

  List<PriceTrackerItem> get _purchasedItems =>
      _items.where((i) => i.purchased).toList();

  List<PriceTrackerItem> get _droppedItems => _activeItems
      .where((i) => i.priceHistory.length >= 2 && i.priceDelta < 0)
      .toList()
    ..sort((a, b) => a.priceDelta.compareTo(b.priceDelta));

  List<PriceTrackerItem> _sorted(List<PriceTrackerItem> items) {
    switch (_sortBy) {
      case 'name':
        return items..sort((a, b) => a.name.compareTo(b.name));
      case 'biggest_drop':
        return items..sort((a, b) => a.priceDelta.compareTo(b.priceDelta));
      case 'recent':
      default:
        return items
          ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    }
  }

  void _addItem() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Track New Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g. Sony WH-1000XM5',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Current Price *',
                  prefixText: '\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g. Electronics, Books',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL (optional)',
                  hintText: 'https://...',
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
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim());
              if (name.isEmpty || price == null || price <= 0) return;

              setState(() {
                _items.add(PriceTrackerItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  category: categoryCtrl.text.trim().isEmpty
                      ? 'General'
                      : categoryCtrl.text.trim(),
                  url: urlCtrl.text.trim(),
                  targetPrice: null,
                  priceHistory: [
                    PricePoint(
                      price: price,
                      date: DateTime.now(),
                    ),
                  ],
                  purchased: false,
                  createdAt: DateTime.now(),
                ));
              });
              _saveItems();
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _recordPrice(PriceTrackerItem item) {
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Price: ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current: \$${item.latestPrice.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(
                labelText: 'New Price',
                prefixText: '\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final price = double.tryParse(priceCtrl.text.trim());
              if (price == null || price <= 0) return;

              setState(() {
                item.priceHistory.add(PricePoint(
                  price: price,
                  date: DateTime.now(),
                ));
              });
              _saveItems();
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _setTargetPrice(PriceTrackerItem item) {
    final ctrl = TextEditingController(
      text: item.targetPrice?.toStringAsFixed(2) ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Target Price'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Buy when price drops to',
            prefixText: '\$ ',
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (item.targetPrice != null)
            TextButton(
              onPressed: () {
                setState(() => item.targetPrice = null);
                _saveItems();
                Navigator.pop(ctx);
              },
              child: const Text('Clear'),
            ),
          FilledButton(
            onPressed: () {
              final price = double.tryParse(ctrl.text.trim());
              if (price == null || price <= 0) return;
              setState(() => item.targetPrice = price);
              _saveItems();
              Navigator.pop(ctx);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _markPurchased(PriceTrackerItem item) {
    setState(() => item.purchased = true);
    _saveItems();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} marked as purchased!'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => item.purchased = false);
            _saveItems();
          },
        ),
      ),
    );
  }

  void _deleteItem(PriceTrackerItem item) {
    setState(() => _items.remove(item));
    _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Watching (${_activeItems.length})',
              icon: const Icon(Icons.visibility, size: 18),
            ),
            Tab(
              text: 'Drops (${_droppedItems.length})',
              icon: const Icon(Icons.trending_down, size: 18),
            ),
            Tab(
              text: 'Bought (${_purchasedItems.length})',
              icon: const Icon(Icons.shopping_cart, size: 18),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => [
              _sortMenuItem('recent', 'Most Recent'),
              _sortMenuItem('name', 'Name'),
              _sortMenuItem('biggest_drop', 'Biggest Drop'),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemList(_sorted(_activeItems)),
          _buildItemList(_droppedItems),
          _buildItemList(_sorted(_purchasedItems)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  PopupMenuItem<String> _sortMenuItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (_sortBy == value) const Icon(Icons.check, size: 18),
          if (_sortBy == value) const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildItemList(List<PriceTrackerItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.price_check, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No items yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _PriceItemCard(
        item: items[i],
        onRecordPrice: () => _recordPrice(items[i]),
        onSetTarget: () => _setTargetPrice(items[i]),
        onMarkPurchased: () => _markPurchased(items[i]),
        onDelete: () => _deleteItem(items[i]),
      ),
    );
  }
}

// ── Item Card Widget ──

class _PriceItemCard extends StatelessWidget {
  final PriceTrackerItem item;
  final VoidCallback onRecordPrice;
  final VoidCallback onSetTarget;
  final VoidCallback onMarkPurchased;
  final VoidCallback onDelete;

  const _PriceItemCard({
    required this.item,
    required this.onRecordPrice,
    required this.onSetTarget,
    required this.onMarkPurchased,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final delta = item.priceDelta;
    final deltaPercent = item.priceDeltaPercent;
    final atTarget =
        item.targetPrice != null && item.latestPrice <= item.targetPrice!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: atTarget
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${item.latestPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.priceHistory.length >= 2)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            delta < 0
                                ? Icons.trending_down
                                : delta > 0
                                    ? Icons.trending_up
                                    : Icons.trending_flat,
                            size: 16,
                            color: delta < 0
                                ? Colors.green
                                : delta > 0
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${delta >= 0 ? '+' : ''}\$${delta.toStringAsFixed(2)} (${deltaPercent.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: delta < 0
                                  ? Colors.green
                                  : delta > 0
                                      ? Colors.red
                                      : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),

            // Target price indicator
            if (item.targetPrice != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    atTarget ? Icons.check_circle : Icons.flag,
                    size: 14,
                    color: atTarget ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    atTarget
                        ? 'Target reached! (\$${item.targetPrice!.toStringAsFixed(2)})'
                        : 'Target: \$${item.targetPrice!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: atTarget ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Mini price history chart
            if (item.priceHistory.length >= 2) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: _MiniPriceChart(history: item.priceHistory),
              ),
            ],

            // Stats row
            const SizedBox(height: 8),
            Row(
              children: [
                _StatChip(
                  icon: Icons.history,
                  label:
                      '${item.priceHistory.length} price${item.priceHistory.length == 1 ? '' : 's'}',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.arrow_downward,
                  label: 'Low: \$${item.lowestPrice.toStringAsFixed(2)}',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.arrow_upward,
                  label: 'High: \$${item.highestPrice.toStringAsFixed(2)}',
                ),
              ],
            ),

            // Action buttons
            if (!item.purchased) ...[
              const Divider(height: 24),
              Row(
                children: [
                  _ActionChip(
                    icon: Icons.update,
                    label: 'Update',
                    onTap: onRecordPrice,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: Icons.flag,
                    label: 'Target',
                    onTap: onSetTarget,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: Icons.shopping_cart,
                    label: 'Bought',
                    onTap: onMarkPurchased,
                    color: Colors.green,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red[300],
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Mini sparkline chart ──

class _MiniPriceChart extends StatelessWidget {
  final List<PricePoint> history;

  const _MiniPriceChart({required this.history});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        prices: history.map((p) => p.price).toList(),
        color: history.last.price <= history.first.price
            ? Colors.green
            : Colors.red,
      ),
      size: const Size(double.infinity, 40),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  _SparklinePainter({required this.prices, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    final range = maxP - minP;
    if (range == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < prices.length; i++) {
      final x = (i / (prices.length - 1)) * size.width;
      final y = size.height - ((prices[i] - minP) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dot on latest price
    final lastX = size.width;
    final lastY =
        size.height - ((prices.last - minP) / range) * size.height;
    canvas.drawCircle(
      Offset(lastX, lastY),
      3,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Small UI helpers ──

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color ?? Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? Colors.grey[700]),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color ?? Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}

// ── Data Models ──

class PricePoint {
  final double price;
  final DateTime date;

  PricePoint({required this.price, required this.date});

  Map<String, dynamic> toJson() => {
        'price': price,
        'date': date.toIso8601String(),
      };

  factory PricePoint.fromJson(Map<String, dynamic> json) => PricePoint(
        price: (json['price'] as num).toDouble(),
        date: DateTime.parse(json['date']),
      );
}

class PriceTrackerItem {
  final String id;
  String name;
  String category;
  String url;
  double? targetPrice;
  List<PricePoint> priceHistory;
  bool purchased;
  final DateTime createdAt;

  PriceTrackerItem({
    required this.id,
    required this.name,
    required this.category,
    this.url = '',
    this.targetPrice,
    required this.priceHistory,
    this.purchased = false,
    required this.createdAt,
  });

  double get latestPrice => priceHistory.last.price;
  double get lowestPrice =>
      priceHistory.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  double get highestPrice =>
      priceHistory.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  DateTime get lastUpdated => priceHistory.last.date;

  double get priceDelta {
    if (priceHistory.length < 2) return 0;
    return priceHistory.last.price -
        priceHistory[priceHistory.length - 2].price;
  }

  double get priceDeltaPercent {
    if (priceHistory.length < 2) return 0;
    final prev = priceHistory[priceHistory.length - 2].price;
    if (prev == 0) return 0;
    return (priceDelta / prev) * 100;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'url': url,
        'targetPrice': targetPrice,
        'priceHistory': priceHistory.map((p) => p.toJson()).toList(),
        'purchased': purchased,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PriceTrackerItem.fromJson(Map<String, dynamic> json) =>
      PriceTrackerItem(
        id: json['id'],
        name: json['name'],
        category: json['category'] ?? 'General',
        url: json['url'] ?? '',
        targetPrice: json['targetPrice'] != null
            ? (json['targetPrice'] as num).toDouble()
            : null,
        priceHistory: (json['priceHistory'] as List)
            .map((p) => PricePoint.fromJson(p))
            .toList(),
        purchased: json['purchased'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
