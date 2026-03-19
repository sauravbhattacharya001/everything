import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/tip_calculator_service.dart';

/// A tip calculator with preset percentages, custom input,
/// bill splitting, round-up option, and service quality selector.
class TipCalculatorScreen extends StatefulWidget {
  const TipCalculatorScreen({super.key});

  @override
  State<TipCalculatorScreen> createState() => _TipCalculatorScreenState();
}

class _TipCalculatorScreenState extends State<TipCalculatorScreen> {
  final _billController = TextEditingController();
  final _customTipController = TextEditingController();
  double _tipPercent = 18;
  int _splitCount = 1;
  bool _roundUp = false;
  bool _useCustomTip = false;
  TipResult? _result;

  @override
  void dispose() {
    _billController.dispose();
    _customTipController.dispose();
    super.dispose();
  }

  void _calculate() {
    final bill = double.tryParse(_billController.text.trim());
    if (bill == null || bill <= 0) {
      setState(() => _result = null);
      return;
    }
    double tip = _tipPercent;
    if (_useCustomTip) {
      tip = double.tryParse(_customTipController.text.trim()) ?? _tipPercent;
    }
    setState(() {
      _result = TipCalculatorService.calculate(
        billAmount: bill,
        tipPercent: tip,
        splitCount: _splitCount,
        roundUp: _roundUp,
      );
    });
  }

  String _fmt(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tip Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bill amount
          TextField(
            controller: _billController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Bill Amount',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 20),

          // Service quality selector
          Text('Service Quality', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TipCalculatorService.serviceRatings.entries.map((e) {
              final selected = !_useCustomTip && _tipPercent == e.value;
              return ChoiceChip(
                label: Text('${e.key}\n${e.value}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : null,
                    )),
                selected: selected,
                selectedColor: theme.colorScheme.primary,
                onSelected: (_) {
                  setState(() {
                    _useCustomTip = false;
                    _tipPercent = e.value.toDouble();
                  });
                  _calculate();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Custom tip toggle
          Row(
            children: [
              Switch(
                value: _useCustomTip,
                onChanged: (v) {
                  setState(() => _useCustomTip = v);
                  _calculate();
                },
              ),
              const Text('Custom tip %'),
              if (_useCustomTip) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _customTipController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: const InputDecoration(
                      suffixText: '%',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Split count
          Row(
            children: [
              Text('Split between', style: theme.textTheme.titleSmall),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _splitCount > 1
                    ? () {
                        setState(() => _splitCount--);
                        _calculate();
                      }
                    : null,
              ),
              Text('$_splitCount',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _splitCount < 50
                    ? () {
                        setState(() => _splitCount++);
                        _calculate();
                      }
                    : null,
              ),
              Text(_splitCount == 1 ? 'person' : 'people'),
            ],
          ),
          const SizedBox(height: 8),

          // Round up toggle
          SwitchListTile(
            title: const Text('Round up total'),
            value: _roundUp,
            onChanged: (v) {
              setState(() => _roundUp = v);
              _calculate();
            },
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 32),

          // Results
          if (_result != null) _buildResults(_result!),
        ],
      ),
    );
  }

  Widget _buildResults(TipResult r) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Summary card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Total', style: theme.textTheme.titleSmall),
                Text(
                  _fmt(r.total),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (r.splitCount > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_fmt(r.perPerson)} per person',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Breakdown
        _row('Bill', _fmt(r.billAmount)),
        _row('Tip (${r.tipPercent.toStringAsFixed(1)}%)', _fmt(r.tipAmount)),
        _row('Total', _fmt(r.total)),
        if (r.splitCount > 1) ...[
          const Divider(),
          _row('Per person', _fmt(r.perPerson)),
          _row('Tip per person', _fmt(r.tipPerPerson)),
        ],
        const SizedBox(height: 16),

        // Copy button
        OutlinedButton.icon(
          onPressed: () {
            final text = r.splitCount > 1
                ? 'Bill: ${_fmt(r.billAmount)} | Tip: ${_fmt(r.tipAmount)} (${r.tipPercent}%) | Total: ${_fmt(r.total)} | ${r.splitCount} people: ${_fmt(r.perPerson)} each'
                : 'Bill: ${_fmt(r.billAmount)} | Tip: ${_fmt(r.tipAmount)} (${r.tipPercent}%) | Total: ${_fmt(r.total)}';
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copied to clipboard'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy Summary'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
