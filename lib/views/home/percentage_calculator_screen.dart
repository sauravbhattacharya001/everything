import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/percentage_calculator_service.dart';

/// A multi-mode percentage calculator with instant results.
class PercentageCalculatorScreen extends StatefulWidget {
  const PercentageCalculatorScreen({super.key});

  @override
  State<PercentageCalculatorScreen> createState() =>
      _PercentageCalculatorScreenState();
}

enum _CalcMode { percentOf, whatPercent, change, increaseDecrease, difference }

class _PercentageCalculatorScreenState
    extends State<PercentageCalculatorScreen> {
  _CalcMode _mode = _CalcMode.percentOf;
  final _ctrl1 = TextEditingController();
  final _ctrl2 = TextEditingController();
  String? _result;
  bool _isIncrease = true;

  static const _labels = {
    _CalcMode.percentOf: 'X% of Y',
    _CalcMode.whatPercent: 'X is what % of Y',
    _CalcMode.change: '% Change',
    _CalcMode.increaseDecrease: 'Increase / Decrease',
    _CalcMode.difference: '% Difference',
  };

  void _calculate() {
    final a = double.tryParse(_ctrl1.text.trim());
    final b = double.tryParse(_ctrl2.text.trim());
    if (a == null || b == null) {
      setState(() => _result = null);
      return;
    }
    double res;
    String label;
    switch (_mode) {
      case _CalcMode.percentOf:
        res = PercentageCalculatorService.percentOf(a, b);
        label = '${_fmt(a)}% of ${_fmt(b)} = ${_fmt(res)}';
      case _CalcMode.whatPercent:
        res = PercentageCalculatorService.whatPercent(a, b);
        label = '${_fmt(a)} is ${_fmt(res)}% of ${_fmt(b)}';
      case _CalcMode.change:
        res = PercentageCalculatorService.percentChange(a, b);
        final dir = res >= 0 ? '↑' : '↓';
        label = 'From ${_fmt(a)} → ${_fmt(b)}: $dir ${_fmt(res.abs())}%';
      case _CalcMode.increaseDecrease:
        if (_isIncrease) {
          res = PercentageCalculatorService.increaseBy(b, a);
          label = '${_fmt(b)} + ${_fmt(a)}% = ${_fmt(res)}';
        } else {
          res = PercentageCalculatorService.decreaseBy(b, a);
          label = '${_fmt(b)} − ${_fmt(a)}% = ${_fmt(res)}';
        }
      case _CalcMode.difference:
        res = PercentageCalculatorService.percentDifference(a, b);
        label = 'Difference: ${_fmt(res)}%';
    }
    setState(() => _result = label);
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(4);

  String _label1() {
    switch (_mode) {
      case _CalcMode.percentOf:
        return 'Percent (X)';
      case _CalcMode.whatPercent:
        return 'Part (X)';
      case _CalcMode.change:
        return 'Old value';
      case _CalcMode.increaseDecrease:
        return 'Percent';
      case _CalcMode.difference:
        return 'Value A';
    }
  }

  String _label2() {
    switch (_mode) {
      case _CalcMode.percentOf:
        return 'Value (Y)';
      case _CalcMode.whatPercent:
        return 'Whole (Y)';
      case _CalcMode.change:
        return 'New value';
      case _CalcMode.increaseDecrease:
        return 'Value';
      case _CalcMode.difference:
        return 'Value B';
    }
  }

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Percentage Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mode chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _CalcMode.values.map((m) {
              return ChoiceChip(
                label: Text(_labels[m]!),
                selected: _mode == m,
                onSelected: (_) {
                  setState(() {
                    _mode = m;
                    _result = null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Increase/Decrease toggle
          if (_mode == _CalcMode.increaseDecrease) ...[
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Increase')),
                ButtonSegment(value: false, label: Text('Decrease')),
              ],
              selected: {_isIncrease},
              onSelectionChanged: (v) {
                setState(() {
                  _isIncrease = v.first;
                  _result = null;
                });
              },
            ),
            const SizedBox(height: 16),
          ],
          // Input fields
          TextField(
            controller: _ctrl1,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.\-]')),
            ],
            decoration: InputDecoration(
              labelText: _label1(),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl2,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.\-]')),
            ],
            decoration: InputDecoration(
              labelText: _label2(),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 24),
          // Result
          if (_result != null)
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _result!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Quick reference
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Reference',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('• X% of Y = (X ÷ 100) × Y'),
                  const Text('• X is what % of Y = (X ÷ Y) × 100'),
                  const Text('• % Change = ((New − Old) ÷ |Old|) × 100'),
                  const Text('• % Difference = |A − B| ÷ avg(|A|, |B|) × 100'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
