import 'package:flutter/material.dart';
import '../../core/services/vehicle_maintenance_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/vehicle_entry.dart';

/// Vehicle Maintenance Tracker screen — manage vehicles, log maintenance,
/// track alerts for upcoming/overdue service, and view cost analysis.
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
  String? _selectedVehicleId;
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
    if (_service.vehicles.isEmpty) _loadSampleData();
    if (_service.vehicles.isNotEmpty) {
      _selectedVehicleId = _service.vehicles.first.id;
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
      id: 'v1', name: 'Daily Driver', type: VehicleType.car,
      year: 2022, make: 'Toyota', model: 'Camry',
      currentMileage: 35000, addedAt: now.subtract(const Duration(days: 400)),
    ));
    _service.addVehicle(Vehicle(
      id: 'v2', name: 'Weekend Truck', type: VehicleType.truck,
      year: 2020, make: 'Ford', model: 'F-150',
      currentMileage: 52000, addedAt: now.subtract(const Duration(days: 600)),
    ));

    _service.addRecord(MaintenanceRecord(
      id: 'r1', vehicleId: 'v1', category: MaintenanceCategory.oilChange,
      date: now.subtract(const Duration(days: 120)), mileage: 30000, cost: 65.00,
      shop: 'Jiffy Lube', notes: 'Synthetic 0W-20',
    ));
    _service.addRecord(MaintenanceRecord(
      id: 'r2', vehicleId: 'v1', category: MaintenanceCategory.tireRotation,
      date: now.subtract(const Duration(days: 90)), mileage: 31000, cost: 30.00,
      shop: 'Discount Tire',
    ));
    _service.addRecord(MaintenanceRecord(
      id: 'r3', vehicleId: 'v1', category: MaintenanceCategory.brakes,
      date: now.subtract(const Duration(days: 200)), mileage: 28000, cost: 450.00,
      shop: 'Toyota Dealer', notes: 'Front pads + rotors',
    ));
    _service.addRecord(MaintenanceRecord(
      id: 'r4', vehicleId: 'v2', category: MaintenanceCategory.oilChange,
      date: now.subtract(const Duration(days: 200)), mileage: 47000, cost: 85.00,
      shop: 'Valvoline',
    ));
    _service.addRecord(MaintenanceRecord(
      id: 'r5', vehicleId: 'v2', category: MaintenanceCategory.filters,
      date: now.subtract(const Duration(days: 365)), mileage: 40000, cost: 45.00,
      shop: 'AutoZone', notes: 'Air + cabin filter',
    ));
    _service.addRecord(MaintenanceRecord(
      id: 'r6', vehicleId: 'v2', category: MaintenanceCategory.inspection,
      date: now.subtract(const Duration(days: 400)), mileage: 38000, cost: 25.00,
    ));

    _nextVehicleId = 3;
    _nextRecordId = 7;
  }

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
            Tab(icon: Icon(Icons.build), text: 'Service Log'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Alerts'),
            Tab(icon: Icon(Icons.analytics), text: 'Costs'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'add_vehicle') _showAddVehicleDialog();
              if (action == 'add_record') _showAddRecordDialog();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'add_vehicle', child: Text('Add Vehicle')),
              const PopupMenuItem(value: 'add_record', child: Text('Log Service')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVehiclesTab(theme),
          _buildServiceLogTab(theme),
          _buildAlertsTab(theme),
          _buildCostsTab(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecordDialog,
        tooltip: 'Log Service',
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Tab 1: Vehicles ──

  Widget _buildVehiclesTab(ThemeData theme) {
    if (_service.vehicles.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.directions_car, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No vehicles yet', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _showAddVehicleDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Vehicle'),
          ),
        ]),
      );
    }
    return ListView.builder(
      itemCount: _service.vehicles.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (ctx, i) {
        final v = _service.vehicles[i];
        final records = _service.getRecordsForVehicle(v.id);
        final totalCost = _service.getTotalCost(vehicleId: v.id);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.15),
                    child: Icon(_vehicleIcon(v.type), color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${v.year} ${v.make} ${v.model}', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'mileage') _showUpdateMileageDialog(v);
                      if (action == 'delete') setState(() => _service.removeVehicle(v.id));
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'mileage', child: Text('Update Mileage')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ]),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniStat(Icons.speed, '${_formatMileage(v.currentMileage)} mi', theme),
                    _miniStat(Icons.receipt_long, '${records.length} services', theme),
                    _miniStat(Icons.attach_money, '\$${totalCost.toStringAsFixed(0)}', theme),
                  ],
                ),
                if (records.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text('Last Service', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${records.first.category.label} — ${_formatDate(records.first.date)} '
                    'at ${records.first.mileage} mi'
                    '${records.first.shop != null ? ' (${records.first.shop})' : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(IconData icon, String text, ThemeData theme) {
    return Column(children: [
      Icon(icon, size: 20, color: Colors.grey),
      const SizedBox(height: 4),
      Text(text, style: theme.textTheme.bodySmall),
    ]);
  }

  // ── Tab 2: Service Log ──

  Widget _buildServiceLogTab(ThemeData theme) {
    final allRecords = List<MaintenanceRecord>.from(_service.records)
      ..sort((a, b) => b.date.compareTo(a.date));

    if (allRecords.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.build, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No service records yet', style: TextStyle(fontSize: 18)),
        ]),
      );
    }

    return Column(children: [
      if (_service.vehicles.length > 1)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedVehicleId == null,
                onSelected: (_) => setState(() => _selectedVehicleId = null),
              ),
              const SizedBox(width: 8),
              ..._service.vehicles.map((v) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(v.name),
                      selected: _selectedVehicleId == v.id,
                      onSelected: (_) =>
                          setState(() => _selectedVehicleId = v.id),
                    ),
                  )),
            ]),
          ),
        ),
      Expanded(
        child: ListView.builder(
          itemCount: _filteredRecords(allRecords).length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (ctx, i) {
            final r = _filteredRecords(allRecords)[i];
            final vehicle = _service.getVehicle(r.vehicleId);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      _categoryColor(r.category).withOpacity(0.15),
                  child: Icon(_categoryIcon(r.category),
                      color: _categoryColor(r.category)),
                ),
                title: Text(r.category.label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${vehicle?.name ?? 'Unknown'} · ${_formatDate(r.date)}\n'
                  '${_formatMileage(r.mileage)} mi · \$${r.cost.toStringAsFixed(2)}'
                  '${r.shop != null ? ' · ${r.shop}' : ''}'
                  '${r.notes != null ? '\n${r.notes}' : ''}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () =>
                      setState(() => _service.removeRecord(r.id)),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  List<MaintenanceRecord> _filteredRecords(List<MaintenanceRecord> all) {
    if (_selectedVehicleId == null) return all;
    return all.where((r) => r.vehicleId == _selectedVehicleId).toList();
  }

  // ── Tab 3: Alerts ──

  Widget _buildAlertsTab(ThemeData theme) {
    final alerts = _service.getAlerts();
    if (alerts.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text('All maintenance up to date!',
              style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('No upcoming or overdue service items',
              style: TextStyle(color: Colors.grey)),
        ]),
      );
    }
    return ListView.builder(
      itemCount: alerts.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (ctx, i) {
        final alert = alerts[i];
        final color = alert.overdue ? Colors.red : Colors.orange;
        return Card(
          color: color.withOpacity(0.08),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(
                alert.overdue ? Icons.error : Icons.schedule,
                color: color,
              ),
            ),
            title: Text(
              '${alert.vehicle.name} — ${alert.category.label}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(alert.message),
            trailing: Chip(
              label: Text(
                alert.overdue ? 'OVERDUE' : 'DUE SOON',
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
              backgroundColor: color.withOpacity(0.1),
              side: BorderSide.none,
            ),
            onTap: () => _showAddRecordDialog(
              preselectedVehicleId: alert.vehicle.id,
              preselectedCategory: alert.category,
            ),
          ),
        );
      },
    );
  }

  // ── Tab 4: Cost Analysis ──

  Widget _buildCostsTab(ThemeData theme) {
    final summary = _service.getSummary();
    final costBreakdown = _service.getCostByCategory();
    final currentYear = DateTime.now().year;
    final thisYearCost = _service.getCostForYear(currentYear);
    final lastYearCost = _service.getCostForYear(currentYear - 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _statCard('Total Spent',
                '\$${summary.totalCost.toStringAsFixed(0)}', Colors.blue, theme),
            const SizedBox(width: 8),
            _statCard('Avg / Service',
                '\$${summary.averageCostPerService.toStringAsFixed(0)}',
                Colors.purple, theme),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _statCard('This Year', '\$${thisYearCost.toStringAsFixed(0)}',
                Colors.green, theme),
            const SizedBox(width: 8),
            _statCard('Last Year', '\$${lastYearCost.toStringAsFixed(0)}',
                Colors.grey, theme),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _statCard(
                'Vehicles', '${summary.totalVehicles}', Colors.teal, theme),
            const SizedBox(width: 8),
            _statCard(
                'Records', '${summary.totalRecords}', Colors.indigo, theme),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _statCard(
                'Alerts', '${summary.alertCount}', Colors.orange, theme),
            const SizedBox(width: 8),
            _statCard(
                'Overdue', '${summary.overdueCount}', Colors.red, theme),
          ]),
          const SizedBox(height: 20),
          Text('Cost by Category', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (costBreakdown.isEmpty)
            const Text('No records to analyze')
          else
            ...costBreakdown.map((cb) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: Icon(_categoryIcon(cb.category),
                        color: _categoryColor(cb.category)),
                    title: Text(cb.category.label),
                    subtitle: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: cb.percentOfTotal / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                            _categoryColor(cb.category)),
                      ),
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${cb.totalCost.toStringAsFixed(0)}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${cb.count} services',
                            style: theme.textTheme.bodySmall),
                        Text('${cb.percentOfTotal.toStringAsFixed(0)}%',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 20),
          if (_service.vehicles.length > 1) ...[
            Text('Cost by Vehicle', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._service.vehicles.map((v) {
              final vCost = _service.getTotalCost(vehicleId: v.id);
              final vRecords = _service.getRecordsForVehicle(v.id);
              final pct = summary.totalCost > 0
                  ? (vCost / summary.totalCost * 100)
                  : 0.0;
              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: Icon(_vehicleIcon(v.type), color: Colors.blue),
                  title: Text(v.name),
                  subtitle: Text('${v.year} ${v.make} ${v.model}'),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${vCost.toStringAsFixed(0)}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${vRecords.length} services',
                          style: theme.textTheme.bodySmall),
                      Text('${pct.toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              );
            }),
          ],
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
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }

  // ── Dialogs ──

  void _showAddVehicleDialog() {
    final nameCtrl = TextEditingController();
    final makeCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: '${DateTime.now().year}');
    final mileageCtrl = TextEditingController();
    var type = VehicleType.car;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Vehicle'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nickname *')),
              TextField(
                  controller: makeCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Make (e.g. Toyota) *')),
              TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Model (e.g. Camry) *')),
              TextField(
                  controller: yearCtrl,
                  decoration: const InputDecoration(labelText: 'Year'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: mileageCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Current Mileage'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<VehicleType>(
                value: type,
                decoration:
                    const InputDecoration(labelText: 'Vehicle Type'),
                items: VehicleType.values
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => type = v ?? type),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty ||
                    makeCtrl.text.isEmpty ||
                    modelCtrl.text.isEmpty) return;
                final id = 'v${_nextVehicleId++}';
                setState(() {
                  _service.addVehicle(Vehicle(
                    id: id,
                    name: nameCtrl.text,
                    type: type,
                    year: int.tryParse(yearCtrl.text) ??
                        DateTime.now().year,
                    make: makeCtrl.text,
                    model: modelCtrl.text,
                    currentMileage:
                        int.tryParse(mileageCtrl.text) ?? 0,
                    addedAt: DateTime.now(),
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

  void _showUpdateMileageDialog(Vehicle vehicle) {
    final ctrl =
        TextEditingController(text: vehicle.currentMileage.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Mileage — ${vehicle.name}'),
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
              final m = int.tryParse(ctrl.text);
              if (m != null && m > 0) {
                setState(() => _service.updateMileage(vehicle.id, m));
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
    String? preselectedVehicleId,
    MaintenanceCategory? preselectedCategory,
  }) {
    if (_service.vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a vehicle first!')),
      );
      return;
    }

    final costCtrl = TextEditingController();
    final mileageCtrl = TextEditingController();
    final shopCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var vehicleId =
        preselectedVehicleId ?? _service.vehicles.first.id;
    var category =
        preselectedCategory ?? MaintenanceCategory.oilChange;
    var date = DateTime.now();

    final v = _service.getVehicle(vehicleId);
    if (v != null) mileageCtrl.text = v.currentMileage.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Log Service'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: vehicleId,
                decoration:
                    const InputDecoration(labelText: 'Vehicle'),
                items: _service.vehicles
                    .map((v) => DropdownMenuItem(
                        value: v.id, child: Text(v.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() {
                      vehicleId = v;
                      final veh = _service.getVehicle(v);
                      if (veh != null) {
                        mileageCtrl.text =
                            veh.currentMileage.toString();
                      }
                    });
                  }
                },
              ),
              DropdownButtonFormField<MaintenanceCategory>(
                value: category,
                decoration:
                    const InputDecoration(labelText: 'Service Type'),
                items: MaintenanceCategory.values
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c.label)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => category = v ?? category),
              ),
              TextField(
                controller: costCtrl,
                decoration: const InputDecoration(
                    labelText: 'Cost', prefixText: '\$ '),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: mileageCtrl,
                decoration: const InputDecoration(
                    labelText: 'Mileage at Service',
                    suffixText: 'mi'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: shopCtrl,
                decoration: const InputDecoration(
                    labelText: 'Shop / Location'),
              ),
              TextField(
                controller: notesCtrl,
                decoration:
                    const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Service Date'),
                subtitle:
                    Text('${date.month}/${date.day}/${date.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setDialogState(() => date = d);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final mileage =
                    int.tryParse(mileageCtrl.text) ?? 0;
                final cost =
                    double.tryParse(costCtrl.text) ?? 0;
                final id = 'r${_nextRecordId++}';
                setState(() {
                  _service.addRecord(MaintenanceRecord(
                    id: id,
                    vehicleId: vehicleId,
                    category: category,
                    date: date,
                    mileage: mileage,
                    cost: cost,
                    shop: shopCtrl.text.isEmpty
                        ? null
                        : shopCtrl.text,
                    notes: notesCtrl.text.isEmpty
                        ? null
                        : notesCtrl.text,
                  ));
                  // Auto-update vehicle mileage if higher
                  final veh = _service.getVehicle(vehicleId);
                  if (veh != null &&
                      mileage > veh.currentMileage) {
                    _service.updateMileage(vehicleId, mileage);
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

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
        return Icons.disc_full;
      case MaintenanceCategory.battery:
        return Icons.battery_full;
      case MaintenanceCategory.fluids:
        return Icons.water_drop;
      case MaintenanceCategory.filters:
        return Icons.filter_alt;
      case MaintenanceCategory.belts:
        return Icons.settings;
      case MaintenanceCategory.inspection:
        return Icons.search;
      case MaintenanceCategory.wipers:
        return Icons.water;
      case MaintenanceCategory.alignment:
        return Icons.straighten;
      case MaintenanceCategory.transmission:
        return Icons.settings_applications;
      case MaintenanceCategory.other:
        return Icons.build;
    }
  }

  Color _categoryColor(MaintenanceCategory cat) {
    switch (cat) {
      case MaintenanceCategory.oilChange:
        return Colors.amber;
      case MaintenanceCategory.tireRotation:
        return Colors.grey;
      case MaintenanceCategory.brakes:
        return Colors.red;
      case MaintenanceCategory.battery:
        return Colors.green;
      case MaintenanceCategory.fluids:
        return Colors.blue;
      case MaintenanceCategory.filters:
        return Colors.teal;
      case MaintenanceCategory.belts:
        return Colors.brown;
      case MaintenanceCategory.inspection:
        return Colors.indigo;
      case MaintenanceCategory.wipers:
        return Colors.cyan;
      case MaintenanceCategory.alignment:
        return Colors.deepOrange;
      case MaintenanceCategory.transmission:
        return Colors.purple;
      case MaintenanceCategory.other:
        return Colors.blueGrey;
    }
  }
}
