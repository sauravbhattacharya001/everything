import 'package:flutter/material.dart';

/// Electricity Cost Calculator — estimate electricity costs for appliances
/// based on wattage, usage hours, and rate per kWh.
class ElectricityCostScreen extends StatefulWidget {
  const ElectricityCostScreen({super.key});

  @override
  State<ElectricityCostScreen> createState() => _ElectricityCostScreenState();
}

class _Appliance {
  String name;
  double watts;
  double hoursPerDay;
  bool enabled;

  _Appliance({
    required this.name,
    required this.watts,
    this.hoursPerDay = 1.0,
    this.enabled = true,
  });

  double get dailyKwh => (watts * hoursPerDay) / 1000.0;
  double dailyCost(double rate) => dailyKwh * rate;
  double monthlyCost(double rate) => dailyCost(rate) * 30;
  double yearlyCost(double rate) => dailyCost(rate) * 365;
}

class _ElectricityCostScreenState extends State<ElectricityCostScreen> {
  double _ratePerKwh = 0.12; // USD default
  final List<_Appliance> _appliances = [];
  final _nameController = TextEditingController();
  final _wattsController = TextEditingController();
  final _hoursController = TextEditingController(text: '1');

  // Common appliance presets
  static const _presets = <String, double>{
    'LED Bulb': 10,
    'CFL Bulb': 14,
    'Incandescent Bulb': 60,
    'Laptop': 50,
    'Desktop PC': 200,
    'Gaming PC': 500,
    'Monitor': 30,
    'TV (LED 55")': 80,
    'TV (OLED 65")': 120,
    'Refrigerator': 150,
    'Microwave': 1000,
    'Oven': 2500,
    'Dishwasher': 1800,
    'Washing Machine': 500,
    'Dryer': 3000,
    'Air Conditioner (Window)': 1200,
    'Central AC': 3500,
    'Space Heater': 1500,
    'Hair Dryer': 1800,
    'Iron': 1200,
    'Vacuum Cleaner': 1400,
    'Ceiling Fan': 75,
    'Phone Charger': 5,
    'Router/Modem': 12,
    'Electric Kettle': 1500,
    'Toaster': 850,
    'Coffee Maker': 900,
    'Dehumidifier': 300,
    'EV Charger (Level 2)': 7200,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _wattsController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _addAppliance({String? presetName, double? presetWatts}) {
    final name = presetName ?? _nameController.text.trim();
    final watts = presetWatts ?? double.tryParse(_wattsController.text) ?? 0;
    final hours = double.tryParse(_hoursController.text) ?? 1;

    if (name.isEmpty || watts <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid name and wattage')),
      );
      return;
    }

    setState(() {
      _appliances.add(_Appliance(name: name, watts: watts, hoursPerDay: hours));
    });

    if (presetName == null) {
      _nameController.clear();
      _wattsController.clear();
      _hoursController.text = '1';
    }
  }

  void _removeAppliance(int index) {
    setState(() => _appliances.removeAt(index));
  }

  double get _totalDailyKwh =>
      _appliances.where((a) => a.enabled).fold(0, (s, a) => s + a.dailyKwh);

  double get _totalDailyCost => _totalDailyKwh * _ratePerKwh;
  double get _totalMonthlyCost => _totalDailyCost * 30;
  double get _totalYearlyCost => _totalDailyCost * 365;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Electricity Cost Calculator'),
        actions: [
          if (_appliances.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all',
              onPressed: () => setState(() => _appliances.clear()),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Rate input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Electricity Rate',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _ratePerKwh,
                          min: 0.01,
                          max: 0.60,
                          divisions: 59,
                          label: '\$${_ratePerKwh.toStringAsFixed(2)}/kWh',
                          onChanged: (v) => setState(() => _ratePerKwh = v),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          '\$${_ratePerKwh.toStringAsFixed(2)}/kWh',
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      _rateChip('US Avg', 0.16),
                      _rateChip('CA Avg', 0.27),
                      _rateChip('EU Avg', 0.25),
                      _rateChip('TX Low', 0.09),
                      _rateChip('HI High', 0.43),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Summary cards
          if (_appliances.isNotEmpty) ...[
            Row(
              children: [
                _summaryCard('Daily', _totalDailyCost, _totalDailyKwh, cs),
                const SizedBox(width: 8),
                _summaryCard(
                    'Monthly', _totalMonthlyCost, _totalDailyKwh * 30, cs),
                const SizedBox(width: 8),
                _summaryCard(
                    'Yearly', _totalYearlyCost, _totalDailyKwh * 365, cs),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Add custom appliance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Appliance',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _wattsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Watts',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _hoursController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Hours/day',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addAppliance,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Presets
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Add Presets',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _presets.entries.map((e) {
                      return ActionChip(
                        label: Text('${e.key} (${e.value.toInt()}W)',
                            style: const TextStyle(fontSize: 12)),
                        onPressed: () => _addAppliance(
                            presetName: e.key, presetWatts: e.value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Appliance list
          if (_appliances.isNotEmpty) ...[
            Text('Your Appliances (${_appliances.length})',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._appliances.asMap().entries.map((entry) {
              final i = entry.key;
              final a = entry.value;
              return Card(
                child: ListTile(
                  leading: Switch(
                    value: a.enabled,
                    onChanged: (v) => setState(() => a.enabled = v),
                  ),
                  title: Text(a.name,
                      style: TextStyle(
                        decoration:
                            a.enabled ? null : TextDecoration.lineThrough,
                      )),
                  subtitle: Text(
                    '${a.watts.toStringAsFixed(0)}W × ${a.hoursPerDay.toStringAsFixed(1)}h/day = '
                    '${a.dailyKwh.toStringAsFixed(2)} kWh/day',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${a.monthlyCost(_ratePerKwh).toStringAsFixed(2)}/mo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: a.enabled ? cs.primary : cs.outline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeAppliance(i),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Cost breakdown bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cost Breakdown',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._appliances.where((a) => a.enabled).map((a) {
                      final pct = _totalMonthlyCost > 0
                          ? a.monthlyCost(_ratePerKwh) / _totalMonthlyCost
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(child: Text(a.name, overflow: TextOverflow.ellipsis)),
                                Text('${(pct * 100).toStringAsFixed(1)}%'),
                              ],
                            ),
                            const SizedBox(height: 2),
                            LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rateChip(String label, double rate) {
    final selected = (_ratePerKwh - rate).abs() < 0.005;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _ratePerKwh = rate),
    );
  }

  Widget _summaryCard(
      String period, double cost, double kwh, ColorScheme cs) {
    return Expanded(
      child: Card(
        color: cs.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(period,
                  style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('\$${cost.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  )),
              Text('${kwh.toStringAsFixed(1)} kWh',
                  style: TextStyle(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                      fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
