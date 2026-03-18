import 'package:flutter/material.dart';
import '../../core/services/vehicle_maintenance_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/vehicle_entry.dart';

/// Vehicle Maintenance Tracker screen — manage vehicles, log maintenance
/// records, view upcoming/overdue alerts, and analyze costs.
class VehicleMaintenanceScreen extends StatefulWidget {
  const VehicleMaintenanceScreen({super.key});

  @override
  State<VehicleMaintenanceScreen> createState() =>
      _VehicleMaintenanceScreenState();
}

class _VehicleMaintenanceScreenState extends State<VehicleMaintenanceScreen>
    with SingleTickerProviderStateMixin, PersistentStateMixin {
  @override
  String get storageKey => 'vehicle_maintenance_data';
  @override
  String exportData() => _service.exportToJson();
  @override
  void importData(String json) => _service.importFromJson(json);

  final VehicleMaintenanceService _service = VehicleMaintenanceService();
  late TabController _tabController;
  int _nextVehicleId = 1;
  int _nextRecordId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initData();
  }

  Future<void> _initData() async {
    await initPersistence();
    if (_service.vehicles.isEmpty) {
      _loadSampleData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    final now = DateTime.now();
    _service.addVehicle(Vehicle(
      id: 'v1',
      name: 'Daily Driver',
      type: VehicleType.car,
      year: 2021,
      make: 'Toyota',
      model: 'Camry',
      currentMileage: 45000,
      addedAt: now.subtract(const Duration(days: 365)),
    ));
    _service.addVehicle(Vehicle(
      id: 'v2',
      name: 'Weekend Ride',
      type: VehicleType.suv,
      year: 2019,
      make: 'Subaru',
      model: 'Outback',
      currentMileage: 68000,
      addedAt: now.subtract(const Duration(days: 730)),
    ));

    _service.addRecord(MaintenanceRecord(
      id: 'r1',
      vehicleId: 'v1',
      category: MaintenanceCategory.oilChange,
      date: now.subtract(const Duration(days: 90)),
      mileage: 42000,
      cost: 65.00,
      shop: 'Quick Lube',
    ));
    _service.addRecord(MaintenanceRecord(
      id: 'r2',
      vehicleId: 'v1',
      category: MaintenanceCategory.tireRotation,
      date: now.subtract(const Duration(days: 180)),
      mileage: 38000,
      cost: 40.00,
      shop: 'Discount Tire',
    ));
    _service.addRecord(MaintenanceRecord(
      id: 'r3',
      vehicleId: 'v2',
      category: MaintenanceCategory.brakes,
      date: now.subtract(const Duration(days: 60)),
      mileage: 65000,
      cost: 450.00,
      shop: 'Midas',
      notes: 'Front and rear pads replaced',
    ));
    _service.addRecord(MaintenanceRecord(
      id: 'r4',
      vehicleId: 'v2',
      category: MaintenanceCategory.oilChange,
      date: now.subtract(const Duration(days: 200)),
      mileage: 60000,
      cost: 75.00,
    ));

    _nextVehicleId = 3;
    _nextRecordId = 5;
    scheduleSave();
  }

  // ── Helpers ──

  String _uid(String prefix) {
    if (prefix == 'v') return 'v${_nextVehicleId++}';
    return 'r${_nextRecordId++}';
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Maintenance'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.directions_car), text: 'Vehicles'),
            Tab(icon: Icon(Icons.build), text: 'Records'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Alerts'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Costs'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'export') exportDialog(context);
              if (v == 'import') importDialog(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Export Data')),
              PopupMenuItem(value: 'import', child: Text('Import Data')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVehiclesTab(theme),
          _buildRecordsTab(theme),
          _buildAlertsTab(theme),
          _buildCostsTab(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddVehicleDialog();
          } else if (_tabController.index == 1) {
            _showAddRecordDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Vehicles Tab ──

  Widget _buildVehiclesTab(ThemeData theme) {
    final vehicles = _service.vehicles;
    if (vehicles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No vehicles yet', style: TextStyle(color: Colors.grey)),
            Text('Tap + to add your first vehicle',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicles.length,
      itemBuilder: (context, i) {
        final v = vehicles[i];
        final recordCount = _service.getRecordsForVehicle(v.id).length;
        final totalCost = _service.getTotalCost(vehicleId: v.id);
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(_vehicleIcon(v.type)),
            ),
            title: Text(v.name),
            subtitle: Text(
              '${v.year} ${v.make} ${v.model} • ${_formatMileage(v.currentMileage)} mi\n'
              '$recordCount records • \$${totalCost.toStringAsFixed(0)} total',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'mileage') _showUpdateMileageDialog(v);
                if (action == 'edit') _showEditVehicleDialog(v);
                if (action == 'delete') _deleteVehicle(v);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'mileage', child: Text('Update Mileage')),
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Records Tab ──

  Widget _buildRecordsTab(ThemeData theme) {
    final records = List<MaintenanceRecord>.from(_service.records)
      ..sort((a, b) => b.date.compareTo(a.date));
    if (records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.build, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No maintenance records',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, i) {
        final r = records[i];
        final vehicle = _service.getVehicle(r.vehicleId);
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _categoryColor(r.category),
              child: Icon(_categoryIcon(r.category), color: Colors.white),
            ),
            title: Text(r.category.label),
            subtitle: Text(
              '${vehicle?.name ?? "Unknown"} • ${_formatDate(r.date)} • ${_formatMileage(r.mileage)} mi\n'
              '\$${r.cost.toStringAsFixed(2)}${r.shop != null ? " at ${r.shop}" : ""}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                setState(() => _service.removeRecord(r.id));
                scheduleSave();
              },
            ),
          ),
        );
      },
    );
  }

  // ── Alerts Tab ──

  Widget _buildAlertsTab(ThemeData theme) {
    final alerts = _service.getAlerts();
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            const Text('All maintenance up to date!',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, i) {
        final a = alerts[i];
        return Card(
          color: a.overdue
              ? Colors.red.withValues(alpha: 0.08)
              : Colors.orange.withValues(alpha: 0.08),
          child: ListTile(
            leading: Icon(
              a.overdue ? Icons.error : Icons.warning_amber,
              color: a.overdue ? Colors.red : Colors.orange,
            ),
            title: Text('${a.vehicle.name} — ${a.category.label}'),
            subtitle: Text(a.message),
            trailing: TextButton(
              onPressed: () => _showAddRecordDialog(
                preselectedVehicle: a.vehicle.id,
                preselectedCategory: a.category,
              ),
              child: const Text('Log'),
            ),
          ),
        );
      },
    );
  }

  // ── Costs Tab ──

  Widget _buildCostsTab(ThemeData theme) {
    final summary = _service.getSummary();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _summaryCard('Total Spent',
                  '\$${summary.totalCost.toStringAsFixed(0)}', Icons.payments),
              const SizedBox(width: 12),
              _summaryCard(
                  'Avg per Service',
                  '\$${summary.averageCostPerService.toStringAsFixed(0)}',
                  Icons.calculate),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryCard('Records', '${summary.totalRecords}',
                  Icons.receipt_long),
              const SizedBox(width: 12),
              _summaryCard(
                  'Alerts',
                  '${summary.alertCount} (${summary.overdueCount} overdue)',
                  Icons.warning_amber),
            ],
          ),
          const SizedBox(height: 24),
          Text('Cost by Category',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (summary.costByCategory.isEmpty)
            const Text('No data yet', style: TextStyle(color: Colors.grey))
          else
            ...summary.costByCategory.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(b.category.label),
                          Text(
                              '\$${b.totalCost.toStringAsFixed(0)} (${b.percentOfTotal.toStringAsFixed(0)}%)'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: b.percentOfTotal / 100,
                        backgroundColor: Colors.grey[200],
                        color: _categoryColor(b.category),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 24),
          // Per-vehicle cost
          Text('Cost by Vehicle',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._service.vehicles.map((v) {
            final cost = _service.getTotalCost(vehicleId: v.id);
            final count = _service.getRecordsForVehicle(v.id).length;
            return Card(
              child: ListTile(
                leading: Icon(_vehicleIcon(v.type)),
                title: Text(v.name),
                subtitle: Text('$count records'),
                trailing: Text('\$${cost.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 28, color: Colors.blueGrey),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text(label,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialogs ──

  void _showAddVehicleDialog() {
    final nameCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    final makeCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final mileageCtrl = TextEditingController();
    var type = VehicleType.car;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Vehicle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nickname')),
                const SizedBox(height: 8),
                DropdownButtonFormField<VehicleType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: VehicleType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => type = v ?? VehicleType.car),
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: yearCtrl,
                    decoration: const InputDecoration(labelText: 'Year'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(
                    controller: makeCtrl,
                    decoration: const InputDecoration(labelText: 'Make')),
                const SizedBox(height: 8),
                TextField(
                    controller: modelCtrl,
                    decoration: const InputDecoration(labelText: 'Model')),
                const SizedBox(height: 8),
                TextField(
                    controller: mileageCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Current Mileage'),
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final year = int.tryParse(yearCtrl.text.trim()) ?? 2024;
                final mileage =
                    int.tryParse(mileageCtrl.text.trim()) ?? 0;
                if (name.isEmpty) return;
                setState(() {
                  _service.addVehicle(Vehicle(
                    id: _uid('v'),
                    name: name,
                    type: type,
                    year: year,
                    make: makeCtrl.text.trim(),
                    model: modelCtrl.text.trim(),
                    currentMileage: mileage,
                    addedAt: DateTime.now(),
                  ));
                });
                scheduleSave();
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditVehicleDialog(Vehicle v) {
    final nameCtrl = TextEditingController(text: v.name);
    final yearCtrl = TextEditingController(text: v.year.toString());
    final makeCtrl = TextEditingController(text: v.make);
    final modelCtrl = TextEditingController(text: v.model);
    var type = v.type;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Vehicle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nickname')),
                const SizedBox(height: 8),
                DropdownButtonFormField<VehicleType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: VehicleType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => type = val ?? v.type),
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: yearCtrl,
                    decoration: const InputDecoration(labelText: 'Year'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(
                    controller: makeCtrl,
                    decoration: const InputDecoration(labelText: 'Make')),
                const SizedBox(height: 8),
                TextField(
                    controller: modelCtrl,
                    decoration: const InputDecoration(labelText: 'Model')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                setState(() {
                  _service.updateVehicle(v.copyWith(
                    name: nameCtrl.text.trim(),
                    type: type,
                    year: int.tryParse(yearCtrl.text.trim()) ?? v.year,
                    make: makeCtrl.text.trim(),
                    model: modelCtrl.text.trim(),
                  ));
                });
                scheduleSave();
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateMileageDialog(Vehicle v) {
    final ctrl =
        TextEditingController(text: v.currentMileage.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update ${v.name} Mileage'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'Current Mileage', suffixText: 'mi'),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final m = int.tryParse(ctrl.text.trim());
              if (m != null && m >= 0) {
                setState(() => _service.updateMileage(v.id, m));
                scheduleSave();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddRecordDialog({
    String? preselectedVehicle,
    MaintenanceCategory? preselectedCategory,
  }) {
    if (_service.vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a vehicle first')),
      );
      return;
    }

    var vehicleId = preselectedVehicle ?? _service.vehicles.first.id;
    var category = preselectedCategory ?? MaintenanceCategory.oilChange;
    final costCtrl = TextEditingController();
    final mileageCtrl = TextEditingController();
    final shopCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var date = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Log Maintenance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: vehicleId,
                  decoration:
                      const InputDecoration(labelText: 'Vehicle'),
                  items: _service.vehicles
                      .map((v) => DropdownMenuItem(
                          value: v.id, child: Text(v.name)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => vehicleId = v ?? vehicleId),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<MaintenanceCategory>(
                  value: category,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  items: MaintenanceCategory.values
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c.label)))
                      .toList(),
                  onChanged: (c) => setDialogState(
                      () => category = c ?? MaintenanceCategory.oilChange),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 3650)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => date = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(_formatDate(date)),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: mileageCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Mileage', suffixText: 'mi'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(
                    controller: costCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Cost', prefixText: '\$'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 8),
                TextField(
                    controller: shopCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Shop (optional)')),
                const SizedBox(height: 8),
                TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Notes (optional)'),
                    maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final cost =
                    double.tryParse(costCtrl.text.trim()) ?? 0;
                final mileage =
                    int.tryParse(mileageCtrl.text.trim()) ?? 0;
                setState(() {
                  _service.addRecord(MaintenanceRecord(
                    id: _uid('r'),
                    vehicleId: vehicleId,
                    category: category,
                    date: date,
                    mileage: mileage,
                    cost: cost,
                    shop: shopCtrl.text.trim().isEmpty
                        ? null
                        : shopCtrl.text.trim(),
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                  ));
                });
                scheduleSave();
                Navigator.pop(ctx);
              },
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteVehicle(Vehicle v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: Text(
            'Remove "${v.name}" and all its maintenance records? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _service.removeVehicle(v.id));
              scheduleSave();
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Formatting helpers ──

  String _formatDate(DateTime d) =>
      '${d.month}/${d.day}/${d.year}';

  String _formatMileage(int m) {
    if (m >= 1000) {
      return '${(m / 1000).toStringAsFixed(1)}k';
    }
    return m.toString();
  }

  IconData _vehicleIcon(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.truck:
        return Icons.local_shipping;
      case VehicleType.suv:
        return Icons.directions_car_filled;
      case VehicleType.motorcycle:
        return Icons.two_wheeler;
      case VehicleType.van:
        return Icons.airport_shuttle;
      case VehicleType.other:
        return Icons.commute;
    }
  }

  IconData _categoryIcon(MaintenanceCategory cat) {
    switch (cat) {
      case MaintenanceCategory.oilChange:
        return Icons.oil_barrel;
      case MaintenanceCategory.tireRotation:
        return Icons.tire_repair;
      case MaintenanceCategory.brakes:
        return Icons.do_not_step;
      case MaintenanceCategory.battery:
        return Icons.battery_charging_full;
      case MaintenanceCategory.fluids:
        return Icons.water_drop;
      case MaintenanceCategory.filters:
        return Icons.filter_alt;
      case MaintenanceCategory.belts:
        return Icons.settings;
      case MaintenanceCategory.inspection:
        return Icons.fact_check;
      case MaintenanceCategory.wipers:
        return Icons.water;
      case MaintenanceCategory.alignment:
        return Icons.straighten;
      case MaintenanceCategory.transmission:
        return Icons.precision_manufacturing;
      case MaintenanceCategory.other:
        return Icons.build;
    }
  }

  Color _categoryColor(MaintenanceCategory cat) {
    const colors = [
      Colors.amber,
      Colors.teal,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.brown,
      Colors.indigo,
      Colors.cyan,
      Colors.orange,
      Colors.deepPurple,
      Colors.grey,
    ];
    return colors[cat.index % colors.length];
  }
}
