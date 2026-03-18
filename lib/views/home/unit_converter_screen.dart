import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/unit_converter_service.dart';

/// A full-featured unit converter with 8 measurement categories,
/// real-time conversion, swap button, and result copying.
class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  int _categoryIndex = 0;
  late UnitDef _fromUnit;
  late UnitDef _toUnit;
  final _inputController = TextEditingController(text: '1');
  String _result = '';

  UnitCategory get _category =>
      UnitConverterService.categories[_categoryIndex];

  @override
  void initState() {
    super.initState();
    _initUnits();
    _compute();
  }

  void _initUnits() {
    final units = _category.units;
    _fromUnit = units[0];
    _toUnit = units.length > 1 ? units[1] : units[0];
  }

  void _compute() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() => _result = '');
      return;
    }
    final value = double.tryParse(text);
    if (value == null) {
      setState(() => _result = 'Invalid number');
      return;
    }
    final converted = UnitConverterService.convert(
      category: _category,
      fromUnit: _fromUnit,
      toUnit: _toUnit,
      value: value,
    );
    setState(
        () => _result = UnitConverterService.formatResult(converted));
  }

  void _swap() {
    setState(() {
      final tmp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = tmp;
    });
    _compute();
  }

  void _copyResult() {
    if (_result.isNotEmpty && _result != 'Invalid number') {
      Clipboard.setData(ClipboardData(text: '$_result ${_toUnit.abbrev}'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied $_result ${_toUnit.abbrev}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  static const _categoryIcons = <String, IconData>{
    'Length': Icons.straighten,
    'Weight': Icons.scale,
    'Temperature': Icons.thermostat,
    'Volume': Icons.local_drink,
    'Speed': Icons.speed,
    'Data': Icons.storage,
    'Area': Icons.square_foot,
    'Time': Icons.schedule,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Unit Converter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Category chips ──
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: UnitConverterService.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = UnitConverterService.categories[i];
                final selected = i == _categoryIndex;
                return ChoiceChip(
                  avatar: Icon(
                    _categoryIcons[cat.name] ?? Icons.calculate,
                    size: 18,
                    color: selected ? cs.onPrimary : null,
                  ),
                  label: Text(cat.name),
                  selected: selected,
                  selectedColor: cs.primary,
                  labelStyle: TextStyle(
                    color: selected ? cs.onPrimary : null,
                    fontWeight: selected ? FontWeight.bold : null,
                  ),
                  onSelected: (_) {
                    setState(() => _categoryIndex = i);
                    _initUnits();
                    _compute();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── From ──
          _buildUnitRow(
            label: 'From',
            unit: _fromUnit,
            onChanged: (u) {
              setState(() => _fromUnit = u);
              _compute();
            },
          ),
          const SizedBox(height: 12),

          // ── Input ──
          TextField(
            controller: _inputController,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: 'Value',
              suffixText: _fromUnit.abbrev,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => _compute(),
          ),
          const SizedBox(height: 12),

          // ── Swap button ──
          Center(
            child: IconButton.filledTonal(
              icon: const Icon(Icons.swap_vert),
              tooltip: 'Swap units',
              onPressed: _swap,
            ),
          ),
          const SizedBox(height: 12),

          // ── To ──
          _buildUnitRow(
            label: 'To',
            unit: _toUnit,
            onChanged: (u) {
              setState(() => _toUnit = u);
              _compute();
            },
          ),
          const SizedBox(height: 24),

          // ── Result card ──
          Card(
            color: cs.primaryContainer,
            child: InkWell(
              onTap: _copyResult,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _result.isEmpty ? '—' : _result,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _toUnit.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to copy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onPrimaryContainer.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Quick reference: all conversions from input ──
          const SizedBox(height: 24),
          Text('All conversions', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._buildQuickReference(),
        ],
      ),
    );
  }

  Widget _buildUnitRow({
    required String label,
    required UnitDef unit,
    required ValueChanged<UnitDef> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: unit.abbrev,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: _category.units
          .map((u) => DropdownMenuItem(
                value: u.abbrev,
                child: Text('${u.name} (${u.abbrev})'),
              ))
          .toList(),
      onChanged: (abbrev) {
        if (abbrev == null) return;
        final u = _category.units.firstWhere((u) => u.abbrev == abbrev);
        onChanged(u);
      },
    );
  }

  List<Widget> _buildQuickReference() {
    final text = _inputController.text.trim();
    final value = double.tryParse(text);
    if (value == null) return [];

    return _category.units
        .where((u) => u.abbrev != _fromUnit.abbrev)
        .map((u) {
      final converted = UnitConverterService.convert(
        category: _category,
        fromUnit: _fromUnit,
        toUnit: u,
        value: value,
      );
      return ListTile(
        dense: true,
        title: Text('${u.name} (${u.abbrev})'),
        trailing: Text(
          UnitConverterService.formatResult(converted),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}
