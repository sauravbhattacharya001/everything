import 'package:flutter/material.dart';
import '../../core/services/fuel_log_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/fuel_entry.dart';

/// Fuel Log screen — track fill-ups, fuel economy (MPG), cost per mile,
/// and monthly spending across multiple vehicles.
class FuelLogScreen extends StatefulWidget {
  const FuelLogScreen({super.key});

  @override
  State<FuelLogScreen> createState() => _FuelLogScreenState();
}

class _FuelLogScreenState extends State<FuelLogScreen>
    with PersistentStateMixin {
  @override
  String get storageKey => 'fuel_log_data';
  @override
  String exportData() => _service.exportToJson();
  @override
  void importData(String json) {
    _service.importFromJson(json);
    setState(() {});
  }

  final FuelLogService _service = FuelLogService();
  int _nextId = 1;
  String? _selectedVehicle; // null = all vehicles

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await initPersistence();
    if (_service.entries.isEmpty) _loadSample();
    setState(() {});
  }

  void _loadSample() {
    final now = DateTime.now();
    final samples = [
      FuelEntry(
        id: _nextId++,
        vehicleName: 'My Car',
        date: now.subtract(const Duration(days: 30)),
        odometer: 45000,
        gallons: 12.5,
        pricePerUnit: 3.89,
        totalCost: 48.63,
        fuelType: FuelType.regular,
      ),
      FuelEntry(
        id: _nextId++,
        vehicleName: 'My Car',
        date: now.subtract(const Duration(days: 20)),
        odometer: 45320,
        gallons: 11.8,
        pricePerUnit: 3.95,
        totalCost: 46.61,
        fuelType: FuelType.regular,
      ),
      FuelEntry(
        id: _nextId++,
        vehicleName: 'My Car',
        date: now.subtract(const Duration(days: 10)),
        odometer: 45650,
        gallons: 12.1,
        pricePerUnit: 4.05,
        totalCost: 49.01,
        fuelType: FuelType.regular,
      ),
    ];
    for (final s in samples) {
      _service.addEntry(s);
    }
    savePersistentData();
  }

  void _addEntry() async {
    final result = await _showEntryDialog();
    if (result != null) {
      setState(() {
        _service.addEntry(result);
        savePersistentData();
      });
    }
  }

  void _deleteEntry(int id) {
    setState(() {
      _service.removeEntry(id);
      savePersistentData();
    });
  }

  Future<FuelEntry?> _showEntryDialog({FuelEntry? existing}) async {
    final vehicleCtrl =
        TextEditingController(text: existing?.vehicleName ?? _selectedVehicle ?? '');
    final odometerCtrl =
        TextEditingController(text: existing?.odometer.toString() ?? '');
    final gallonsCtrl =
        TextEditingController(text: existing?.gallons.toString() ?? '');
    final priceCtrl =
        TextEditingController(text: existing?.pricePerUnit.toString() ?? '');
    final stationCtrl =
        TextEditingController(text: existing?.station ?? '');
    final notesCtrl =
        TextEditingController(text: existing?.notes ?? '');
    var fuelType = existing?.fuelType ?? FuelType.regular;
    var fullTank = existing?.fullTank ?? true;
    var date = existing?.date ?? DateTime.now();

    return showDialog<FuelEntry>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Fill-Up' : 'New Fill-Up'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: vehicleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Name *',
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    '${date.month}/${date.day}/${date.year}',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setDialogState(() => date = picked);
                    }
                  },
                ),
                TextField(
                  controller: odometerCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Odometer (miles) *',
                    prefixIcon: Icon(Icons.speed),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: gallonsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Gallons *',
                    prefixIcon: Icon(Icons.local_gas_station),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price per gallon *',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<FuelType>(
                  value: fuelType,
                  decoration: const InputDecoration(
                    labelText: 'Fuel Type',
                    prefixIcon: Icon(Icons.opacity),
                  ),
                  items: FuelType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => fuelType = v!),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Full tank'),
                  subtitle: const Text('Required for MPG calculation'),
                  value: fullTank,
                  onChanged: (v) => setDialogState(() => fullTank = v),
                ),
                TextField(
                  controller: stationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Station (optional)',
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.notes),
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
                final vehicle = vehicleCtrl.text.trim();
                final odo = double.tryParse(odometerCtrl.text.trim());
                final gal = double.tryParse(gallonsCtrl.text.trim());
                final price = double.tryParse(priceCtrl.text.trim());
                if (vehicle.isEmpty || odo == null || gal == null || price == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please fill required fields')),
                  );
                  return;
                }
                Navigator.pop(
                  ctx,
                  FuelEntry(
                    id: existing?.id ?? _nextId++,
                    vehicleName: vehicle,
                    date: date,
                    odometer: odo,
                    gallons: gal,
                    pricePerUnit: price,
                    totalCost: gal * price,
                    fuelType: fuelType,
                    fullTank: fullTank,
                    station: stationCtrl.text.trim().isEmpty
                        ? null
                        : stationCtrl.text.trim(),
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _service.stats(vehicleName: _selectedVehicle);
    final vehicles = _service.vehicleNames;
    final displayEntries = _selectedVehicle != null
        ? _service.entriesForVehicle(_selectedVehicle!)
        : _service.entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Log'),
        actions: [
          if (vehicles.length > 1)
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter by vehicle',
              onSelected: (v) => setState(() => _selectedVehicle = v),
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('All Vehicles')),
                ...vehicles.map((v) => PopupMenuItem(value: v, child: Text(v))),
              ],
            ),
        ],
      ),
      body: displayEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_gas_station,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No fill-ups yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _addEntry,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Fill-Up'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedVehicle ?? 'All Vehicles',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Divider(),
                        _StatRow('Fill-ups', '${stats.fillUpCount}'),
                        _StatRow('Avg MPG',
                            stats.avgMpg > 0 ? stats.avgMpg.toStringAsFixed(1) : '—'),
                        _StatRow('Avg Price/gal',
                            '\$${stats.avgPricePerGallon.toStringAsFixed(2)}'),
                        _StatRow('Cost/mile',
                            stats.avgCostPerMile > 0
                                ? '\$${stats.avgCostPerMile.toStringAsFixed(2)}'
                                : '—'),
                        _StatRow('Total Spent',
                            '\$${stats.totalSpent.toStringAsFixed(2)}'),
                        _StatRow('Total Miles',
                            stats.totalMiles.toStringAsFixed(0)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Monthly spending
                if (_service.monthlySpending(vehicleName: _selectedVehicle).isNotEmpty)
                  _MonthlySpendingCard(
                    spending: _service.monthlySpending(vehicleName: _selectedVehicle),
                  ),
                const SizedBox(height: 12),
                // Entries
                Text('Fill-Up History',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...displayEntries.reversed.map((e) => _EntryTile(
                      entry: e,
                      mpg: _service.mpgForEntry(e),
                      onDelete: () => _deleteEntry(e.id),
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MonthlySpendingCard extends StatelessWidget {
  final Map<String, double> spending;
  const _MonthlySpendingCard({required this.spending});

  @override
  Widget build(BuildContext context) {
    final maxVal = spending.values.fold<double>(0, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Spending',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...spending.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: const TextStyle(fontSize: 12)),
                          Text('\$${e.value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: maxVal > 0 ? e.value / maxVal : 0,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final FuelEntry entry;
  final double? mpg;
  final VoidCallback onDelete;
  const _EntryTile({
    required this.entry,
    required this.mpg,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            entry.fuelType == FuelType.electric
                ? Icons.bolt
                : Icons.local_gas_station,
          ),
        ),
        title: Text(
          '${entry.gallons.toStringAsFixed(2)} gal @ \$${entry.pricePerUnit.toStringAsFixed(2)}',
        ),
        subtitle: Text(
          '${entry.date.month}/${entry.date.day}/${entry.date.year}'
          ' · ${entry.odometer.toStringAsFixed(0)} mi'
          '${entry.station != null ? ' · ${entry.station}' : ''}'
          '${mpg != null ? ' · ${mpg!.toStringAsFixed(1)} MPG' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${entry.totalCost.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
