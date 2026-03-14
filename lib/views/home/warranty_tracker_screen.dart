import 'package:flutter/material.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../core/services/warranty_tracker_service.dart';
import '../../models/warranty_entry.dart';

/// Warranty Tracker screen — manage product warranties, track expiration dates,
/// file claims, and view coverage analysis.
class WarrantyTrackerScreen extends StatefulWidget {
  const WarrantyTrackerScreen({super.key});

  @override
  State<WarrantyTrackerScreen> createState() => _WarrantyTrackerScreenState();
}

class _WarrantyTrackerScreenState extends State<WarrantyTrackerScreen>
    with SingleTickerProviderStateMixin, PersistentStateMixin {
  @override
  String get storageKey => 'warranty_tracker_data';
  @override
  String exportData() => _service.exportToJson();
  @override
  void importData(String json) => _service.importFromJson(json);
  final WarrantyTrackerService _service = WarrantyTrackerService();
  late TabController _tabController;
  WarrantyCategory? _filterCategory;
  String _searchQuery = '';
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSampleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    final now = DateTime.now();
    final samples = [
      WarrantyEntry(
        id: 'w1',
        productName: 'MacBook Pro 16"',
        brand: 'Apple',
        category: WarrantyCategory.electronics,
        type: WarrantyType.manufacturer,
        purchaseDate: now.subtract(const Duration(days: 300)),
        expirationDate: now.add(const Duration(days: 65)),
        purchasePrice: 2499.00,
        retailer: 'Apple Store',
        serialNumber: 'C02X1234ABCD',
      ),
      WarrantyEntry(
        id: 'w2',
        productName: 'Samsung Refrigerator',
        brand: 'Samsung',
        category: WarrantyCategory.appliance,
        type: WarrantyType.extended,
        purchaseDate: now.subtract(const Duration(days: 730)),
        expirationDate: now.add(const Duration(days: 1095)),
        purchasePrice: 1899.00,
        retailer: 'Best Buy',
        serialNumber: 'RF28HMELBSR',
      ),
      WarrantyEntry(
        id: 'w3',
        productName: 'Sony WH-1000XM5',
        brand: 'Sony',
        category: WarrantyCategory.electronics,
        type: WarrantyType.manufacturer,
        purchaseDate: now.subtract(const Duration(days: 400)),
        expirationDate: now.subtract(const Duration(days: 35)),
        purchasePrice: 349.99,
        retailer: 'Amazon',
      ),
      WarrantyEntry(
        id: 'w4',
        productName: 'Standing Desk',
        brand: 'Uplift',
        category: WarrantyCategory.furniture,
        type: WarrantyType.lifetime,
        purchaseDate: now.subtract(const Duration(days: 200)),
        expirationDate: now.add(const Duration(days: 36000)),
        purchasePrice: 699.00,
        retailer: 'Uplift Desk',
      ),
      WarrantyEntry(
        id: 'w5',
        productName: 'Dyson V15 Detect',
        brand: 'Dyson',
        category: WarrantyCategory.appliance,
        type: WarrantyType.manufacturer,
        purchaseDate: now.subtract(const Duration(days: 350)),
        expirationDate: now.add(const Duration(days: 15)),
        purchasePrice: 749.99,
        retailer: 'Dyson.com',
        claims: [
          WarrantyClaim(
            id: 'c1',
            dateSubmitted: now.subtract(const Duration(days: 30)),
            issue: 'Battery not holding charge',
            status: ClaimStatus.completed,
            resolution: 'Battery replaced under warranty',
            dateResolved: now.subtract(const Duration(days: 15)),
          ),
        ],
      ),
      WarrantyEntry(
        id: 'w6',
        productName: 'DeWalt Drill Set',
        brand: 'DeWalt',
        category: WarrantyCategory.tool,
        type: WarrantyType.limited,
        purchaseDate: now.subtract(const Duration(days: 100)),
        expirationDate: now.add(const Duration(days: 995)),
        purchasePrice: 199.00,
        retailer: 'Home Depot',
      ),
    ];
    for (final s in samples) {
      _service.addWarranty(s);
    }
    _nextId = 7;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranty Tracker'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.verified_user), text: 'Warranties'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Expiring'),
            Tab(icon: Icon(Icons.assignment), text: 'Claims'),
            Tab(icon: Icon(Icons.analytics), text: 'Coverage'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddWarrantyDialog,
            tooltip: 'Add Warranty',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWarrantiesTab(theme),
          _buildExpiringTab(theme),
          _buildClaimsTab(theme),
          _buildCoverageTab(theme),
        ],
      ),
    );
  }

  // ── Tab 1: All Warranties ──

  Widget _buildWarrantiesTab(ThemeData theme) {
    var items = _service.warranties;
    if (_filterCategory != null) {
      items = items.where((w) => w.category == _filterCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      items = _service.searchByName(_searchQuery);
      if (_filterCategory != null) {
        items = items.where((w) => w.category == _filterCategory).toList();
      }
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search warranties...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<WarrantyCategory?>(
                value: _filterCategory,
                hint: const Text('Category'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...WarrantyCategory.values.map((c) =>
                      DropdownMenuItem(value: c, child: Text(c.label))),
                ],
                onChanged: (v) => setState(() => _filterCategory = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No warranties found'))
              : ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (ctx, i) =>
                      _buildWarrantyCard(items[i], theme),
                ),
        ),
      ],
    );
  }

  Widget _buildWarrantyCard(WarrantyEntry w, ThemeData theme) {
    final color = w.isExpired
        ? Colors.red
        : w.isExpiringSoon
            ? Colors.orange
            : Colors.green;
    final statusText = w.isExpired
        ? 'Expired'
        : w.isExpiringSoon
            ? '${w.daysRemaining}d left!'
            : '${w.daysRemaining}d remaining';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(_categoryIcon(w.category), color: color),
        ),
        title: Text(w.productName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${w.brand ?? ''} · ${w.type.label} · ${w.category.label}\n'
          '$statusText · \$${w.purchasePrice.toStringAsFixed(2)}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'claim') _showAddClaimDialog(w);
            if (action == 'delete') {
              setState(() => _service.removeWarranty(w.id));
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'claim', child: Text('File Claim')),
            const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Expiring Soon ──

  Widget _buildExpiringTab(ThemeData theme) {
    final expiring = _service.getExpiringSoon(withinDays: 90);
    final alerts = _service.getExpiryAlerts(withinDays: 90);
    if (expiring.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No warranties expiring soon!',
                style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: alerts.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (ctx, i) {
        final alert = alerts[i];
        final urgency = alert.daysUntilExpiry <= 7
            ? Colors.red
            : alert.daysUntilExpiry <= 30
                ? Colors.orange
                : Colors.amber;
        return Card(
          color: urgency.withOpacity(0.08),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.timer, color: urgency),
            title: Text(alert.warranty.productName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(alert.message),
            trailing: Text('${alert.daysUntilExpiry}d',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: urgency)),
          ),
        );
      },
    );
  }

  // ── Tab 3: Claims ──

  Widget _buildClaimsTab(ThemeData theme) {
    final withClaims =
        _service.warranties.where((w) => w.claims.isNotEmpty).toList();
    if (withClaims.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No warranty claims yet',
                style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: withClaims.expand((w) {
        return w.claims.map((c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _claimColor(c.status).withOpacity(0.15),
                  child: Icon(_claimIcon(c.status),
                      color: _claimColor(c.status)),
                ),
                title: Text(w.productName),
                subtitle: Text(
                  '${c.issue}\nStatus: ${c.status.label}'
                  '${c.resolution != null ? '\nResolution: ${c.resolution}' : ''}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<ClaimStatus>(
                  onSelected: (status) {
                    setState(() {
                      _service.updateClaim(
                        w.id,
                        c.copyWith(
                          status: status,
                          dateResolved:
                              (status == ClaimStatus.completed ||
                                      status == ClaimStatus.denied)
                                  ? DateTime.now()
                                  : null,
                        ),
                      );
                    });
                  },
                  itemBuilder: (_) => ClaimStatus.values
                      .map((s) =>
                          PopupMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  child: Chip(
                    label: Text(c.status.label,
                        style: TextStyle(color: _claimColor(c.status))),
                    backgroundColor:
                        _claimColor(c.status).withOpacity(0.1),
                  ),
                ),
              ),
            ));
      }).toList(),
    );
  }

  // ── Tab 4: Coverage Analysis ──

  Widget _buildCoverageTab(ThemeData theme) {
    final summary = _service.getSummary();
    final score = _service.getCoverageScore();
    final scoreColor = score >= 80
        ? Colors.green
        : score >= 50
            ? Colors.orange
            : Colors.red;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coverage Score
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Coverage Score',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation(scoreColor),
                        ),
                        Center(
                          child: Text('${score.round()}%',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'of your purchase value is under warranty',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stats Grid
          Row(
            children: [
              _statCard('Active', '${summary.activeCount}',
                  Colors.green, theme),
              const SizedBox(width: 8),
              _statCard('Expired', '${summary.expiredCount}',
                  Colors.red, theme),
              const SizedBox(width: 8),
              _statCard('Expiring', '${summary.expiringSoonCount}',
                  Colors.orange, theme),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statCard(
                  'Protected',
                  '\$${summary.protectedValue.toStringAsFixed(0)}',
                  Colors.blue,
                  theme),
              const SizedBox(width: 8),
              _statCard(
                  'Unprotected',
                  '\$${summary.unprotectedValue.toStringAsFixed(0)}',
                  Colors.grey,
                  theme),
              const SizedBox(width: 8),
              _statCard('Claims', '${summary.totalClaims}',
                  Colors.purple, theme),
            ],
          ),
          const SizedBox(height: 16),
          // Category Breakdown
          Text('By Category',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...summary.categoryBreakdown.map((cb) => Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: Icon(_categoryIcon(cb.category)),
                  title: Text(cb.category.label),
                  subtitle: LinearProgressIndicator(
                    value: cb.percentOfTotal / 100,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${cb.count} items'),
                      Text('\$${cb.totalPurchaseValue.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, Color color, ThemeData theme) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialogs ──

  void _showAddWarrantyDialog() {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final retailerCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    var cat = WarrantyCategory.electronics;
    var type = WarrantyType.manufacturer;
    var purchaseDate = DateTime.now();
    var expirationDate = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Warranty'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Product Name *'),
                ),
                TextField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(labelText: 'Brand'),
                ),
                TextField(
                  controller: priceCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Purchase Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: retailerCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Retailer'),
                ),
                TextField(
                  controller: serialCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Serial Number'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<WarrantyCategory>(
                  value: cat,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  items: WarrantyCategory.values
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c.label)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => cat = v ?? cat),
                ),
                DropdownButtonFormField<WarrantyType>(
                  value: type,
                  decoration:
                      const InputDecoration(labelText: 'Warranty Type'),
                  items: WarrantyType.values
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => type = v ?? type),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Purchase Date'),
                  subtitle: Text(
                      '${purchaseDate.month}/${purchaseDate.day}/${purchaseDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: purchaseDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) {
                      setDialogState(() => purchaseDate = d);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Expiration Date'),
                  subtitle: Text(
                      '${expirationDate.month}/${expirationDate.day}/${expirationDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: expirationDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) {
                      setDialogState(() => expirationDate = d);
                    }
                  },
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
                if (nameCtrl.text.isEmpty) return;
                final id = 'w${_nextId++}';
                setState(() {
                  _service.addWarranty(WarrantyEntry(
                    id: id,
                    productName: nameCtrl.text,
                    brand: brandCtrl.text.isEmpty
                        ? null
                        : brandCtrl.text,
                    category: cat,
                    type: type,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate,
                    purchasePrice:
                        double.tryParse(priceCtrl.text) ?? 0,
                    retailer: retailerCtrl.text.isEmpty
                        ? null
                        : retailerCtrl.text,
                    serialNumber: serialCtrl.text.isEmpty
                        ? null
                        : serialCtrl.text,
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddClaimDialog(WarrantyEntry warranty) {
    final issueCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('File Claim — ${warranty.productName}'),
        content: TextField(
          controller: issueCtrl,
          decoration: const InputDecoration(
            labelText: 'Describe the issue',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (issueCtrl.text.isEmpty) return;
              final claimId = 'c${DateTime.now().millisecondsSinceEpoch}';
              setState(() {
                _service.addClaim(
                  warranty.id,
                  WarrantyClaim(
                    id: claimId,
                    dateSubmitted: DateTime.now(),
                    issue: issueCtrl.text,
                  ),
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Submit Claim'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──

  IconData _categoryIcon(WarrantyCategory cat) {
    switch (cat) {
      case WarrantyCategory.electronics:
        return Icons.devices;
      case WarrantyCategory.appliance:
        return Icons.kitchen;
      case WarrantyCategory.furniture:
        return Icons.chair;
      case WarrantyCategory.vehicle:
        return Icons.directions_car;
      case WarrantyCategory.tool:
        return Icons.build;
      case WarrantyCategory.clothing:
        return Icons.checkroom;
      case WarrantyCategory.jewelry:
        return Icons.diamond;
      case WarrantyCategory.sporting:
        return Icons.sports;
      case WarrantyCategory.home:
        return Icons.home;
      case WarrantyCategory.other:
        return Icons.category;
    }
  }

  Color _claimColor(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.submitted:
        return Colors.blue;
      case ClaimStatus.inProgress:
        return Colors.orange;
      case ClaimStatus.approved:
        return Colors.green;
      case ClaimStatus.denied:
        return Colors.red;
      case ClaimStatus.completed:
        return Colors.teal;
    }
  }

  IconData _claimIcon(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.submitted:
        return Icons.send;
      case ClaimStatus.inProgress:
        return Icons.hourglass_top;
      case ClaimStatus.approved:
        return Icons.check_circle;
      case ClaimStatus.denied:
        return Icons.cancel;
      case ClaimStatus.completed:
        return Icons.done_all;
    }
  }
}
