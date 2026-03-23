import 'package:flutter/material.dart';
import '../../core/services/currency_converter_service.dart';

/// Offline currency converter with 25 currencies, swap, and favorites.
class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountCtrl =
      TextEditingController(text: '1.00');
  String _fromCode = 'USD';
  String _toCode = 'EUR';
  final Set<String> _favorites = {'USD', 'EUR', 'GBP', 'JPY', 'INR'};

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;

  double get _converted =>
      CurrencyConverterService.convert(_amount, _fromCode, _toCode);

  void _swap() => setState(() {
        final tmp = _fromCode;
        _fromCode = _toCode;
        _toCode = tmp;
      });

  void _toggleFavorite(String code) => setState(() {
        if (_favorites.contains(code)) {
          _favorites.remove(code);
        } else {
          _favorites.add(code);
        }
      });

  List<String> get _sortedCodes {
    final codes = CurrencyConverterService.codes;
    codes.sort((a, b) {
      final aFav = _favorites.contains(a);
      final bFav = _favorites.contains(b);
      if (aFav && !bFav) return -1;
      if (!aFav && bFav) return 1;
      return a.compareTo(b);
    });
    return codes;
  }

  Widget _buildCurrencyDropdown(String value, ValueChanged<String> onChanged) {
    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      items: _sortedCodes.map((code) {
        final info = CurrencyConverterService.currencies[code]!;
        final isFav = _favorites.contains(code);
        return DropdownMenuItem(
          value: code,
          child: Row(
            children: [
              Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(info.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ),
              if (isFav)
                const Icon(Icons.star, size: 14, color: Colors.amber),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Currency Converter')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount input
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.monetization_on_outlined),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // From currency
            _buildCurrencyDropdown(
                _fromCode, (v) => setState(() => _fromCode = v)),
            const SizedBox(height: 8),

            // Swap button
            Center(
              child: IconButton.filledTonal(
                icon: const Icon(Icons.swap_vert, size: 28),
                onPressed: _swap,
                tooltip: 'Swap currencies',
              ),
            ),
            const SizedBox(height: 8),

            // To currency
            _buildCurrencyDropdown(
                _toCode, (v) => setState(() => _toCode = v)),
            const SizedBox(height: 24),

            // Result card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      CurrencyConverterService.format(_converted, _toCode),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_amountCtrl.text} $_fromCode = ${_converted.toStringAsFixed(4)} $_toCode',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick-convert grid for favorites
            Text('Quick Convert',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: _favorites
                    .where((c) => c != _fromCode)
                    .map((code) {
                  final val = CurrencyConverterService.convert(
                      _amount, _fromCode, code);
                  final info = CurrencyConverterService.currencies[code]!;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      child: Text(info.symbol,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(code),
                    subtitle: Text(info.name),
                    trailing: Text(
                      CurrencyConverterService.format(val, code),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onLongPress: () => _toggleFavorite(code),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
