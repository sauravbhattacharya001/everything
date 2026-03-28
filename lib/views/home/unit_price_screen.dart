import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/unit_price_service.dart';

/// Compare unit prices across products to find the best deal.
class UnitPriceScreen extends StatefulWidget {
  const UnitPriceScreen({super.key});

  @override
  State<UnitPriceScreen> createState() => _UnitPriceScreenState();
}

class _UnitPriceScreenState extends State<UnitPriceScreen> {
  final List<_ProductEntry> _products = [
    _ProductEntry(),
    _ProductEntry(),
  ];
  String _selectedUnit = 'oz';
  List<UnitPriceResult>? _results;

  void _addProduct() {
    setState(() => _products.add(_ProductEntry()));
  }

  void _removeProduct(int index) {
    if (_products.length <= 2) return;
    setState(() {
      _products[index].dispose();
      _products.removeAt(index);
      _recalculate();
    });
  }

  void _recalculate() {
    final items = <UnitPriceResult>[];
    for (int i = 0; i < _products.length; i++) {
      final p = _products[i];
      final price = double.tryParse(p.priceController.text.trim());
      final qty = double.tryParse(p.quantityController.text.trim());
      if (price == null || price <= 0 || qty == null || qty <= 0) {
        setState(() => _results = null);
        return;
      }
      final result = UnitPriceService.calculate(
        price: price,
        quantity: qty,
        unit: _selectedUnit,
      );
      items.add(result.copyWith(
        label: p.labelController.text.trim().isEmpty
            ? 'Product ${i + 1}'
            : p.labelController.text.trim(),
      ));
    }
    setState(() => _results = UnitPriceService.compare(items));
  }

  @override
  void dispose() {
    for (final p in _products) {
      p.dispose();
    }
    super.dispose();
  }

  String _fmtPrice(double v) => '\$${v.toStringAsFixed(4)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savings =
        _results != null ? UnitPriceService.savingsPercent(_results!) : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Unit Price Comparator')),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _addProduct,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Unit selector
          Text('Unit of Measurement', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: UnitPriceService.commonUnits.map((unit) {
              final selected = unit == _selectedUnit;
              return ChoiceChip(
                label: Text(unit),
                selected: selected,
                onSelected: (_) {
                  setState(() => _selectedUnit = unit);
                  _recalculate();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Product entries
          ...List.generate(_products.length, (i) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Product ${i + 1}',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (_products.length > 2)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _removeProduct(i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _products[i].labelController,
                      decoration: const InputDecoration(
                        labelText: 'Name (optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => _recalculate(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _products[i].priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d.]')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => _recalculate(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _products[i].quantityController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d.]')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Quantity ($_selectedUnit)',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => _recalculate(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          // Results
          if (_results != null && _results!.isNotEmpty) ...[
            const Divider(height: 32),
            Text('Results (Best → Worst)',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (savings > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.savings, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Save up to ${savings.toStringAsFixed(1)}% by choosing the best deal!',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            ...List.generate(_results!.length, (i) {
              final r = _results![i];
              final isBest = i == 0;
              return Card(
                color: isBest ? Colors.green.shade50 : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isBest ? Colors.green : Colors.grey.shade300,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: isBest ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  title: Text(
                    r.label ?? 'Product',
                    style: TextStyle(
                      fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '\$${r.price.toStringAsFixed(2)} for ${r.quantity} ${r.unit}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmtPrice(r.pricePerUnit),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isBest ? Colors.green.shade700 : null,
                        ),
                      ),
                      Text(
                        'per ${r.unit}',
                        style: theme.textTheme.bodySmall,
                      ),
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
}

class _ProductEntry {
  final labelController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();

  void dispose() {
    labelController.dispose();
    priceController.dispose();
    quantityController.dispose();
  }
}
