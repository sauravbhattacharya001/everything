import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/tax_calculator_service.dart';

/// US Federal Income Tax calculator with bracket breakdown.
class TaxCalculatorScreen extends StatefulWidget {
  const TaxCalculatorScreen({super.key});

  @override
  State<TaxCalculatorScreen> createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen> {
  final _service = TaxCalculatorService();
  final _incomeController = TextEditingController();
  final _deductionController = TextEditingController();
  FilingStatus _filingStatus = FilingStatus.single;
  bool _useCustomDeduction = false;
  TaxResult? _result;

  @override
  void dispose() {
    _incomeController.dispose();
    _deductionController.dispose();
    super.dispose();
  }

  void _calculate() {
    final income = double.tryParse(
        _incomeController.text.replaceAll(RegExp(r'[,\$]'), ''));
    if (income == null || income < 0) return;

    double? customDeduction;
    if (_useCustomDeduction) {
      customDeduction = double.tryParse(
          _deductionController.text.replaceAll(RegExp(r'[,\$]'), ''));
    }

    setState(() {
      _result = _service.calculate(
        grossIncome: income,
        filingStatus: _filingStatus,
        customDeduction: customDeduction,
      );
    });
  }

  String _formatCurrency(double value) {
    final isNegative = value < 0;
    final abs = value.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '${isNegative ? '-' : ''}\$$buffer.$decPart';
  }

  String _formatPercent(double value) =>
      '${(value * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tax Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filing Status
          Text('Filing Status', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<FilingStatus>(
            segments: FilingStatus.values.map((s) {
              return ButtonSegment(
                value: s,
                label: Text(
                  s == FilingStatus.marriedJoint
                      ? 'Joint'
                      : s == FilingStatus.marriedSeparate
                          ? 'Separate'
                          : s == FilingStatus.headOfHousehold
                              ? 'HoH'
                              : 'Single',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
            selected: {_filingStatus},
            onSelectionChanged: (v) =>
                setState(() => _filingStatus = v.first),
          ),
          const SizedBox(height: 16),

          // Gross Income
          TextField(
            controller: _incomeController,
            decoration: const InputDecoration(
              labelText: 'Annual Gross Income',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            onSubmitted: (_) => _calculate(),
          ),
          const SizedBox(height: 12),

          // Custom Deduction toggle
          SwitchListTile(
            title: const Text('Custom Deduction'),
            subtitle: Text(_useCustomDeduction
                ? 'Enter your itemized deduction'
                : 'Using standard deduction: ${_formatCurrency(TaxCalculatorService.standardDeductions[_filingStatus]!)}'),
            value: _useCustomDeduction,
            onChanged: (v) => setState(() => _useCustomDeduction = v),
          ),

          if (_useCustomDeduction) ...[
            TextField(
              controller: _deductionController,
              decoration: const InputDecoration(
                labelText: 'Itemized Deduction',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Calculate button
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate Tax'),
          ),
          const SizedBox(height: 24),

          // Results
          if (_result != null) ...[
            _buildSummaryCard(_result!),
            const SizedBox(height: 16),
            _buildBracketBreakdown(_result!),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(TaxResult r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            _row('Gross Income', _formatCurrency(r.grossIncome)),
            _row('Deductions', '- ${_formatCurrency(r.totalDeductions)}'),
            _row('Taxable Income', _formatCurrency(r.taxableIncome)),
            const Divider(),
            _row('Federal Tax', _formatCurrency(r.federalTax),
                bold: true),
            _row('Effective Rate', _formatPercent(r.effectiveRate)),
            _row('Marginal Rate', _formatPercent(r.marginalRate)),
            const Divider(),
            _row('Take-Home Pay', _formatCurrency(r.takeHome),
                bold: true, color: Colors.green),
            _row('Monthly Take-Home',
                _formatCurrency(r.takeHome / 12)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketBreakdown(TaxResult r) {
    if (r.bracketBreakdown.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bracket Breakdown',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...r.bracketBreakdown.map((b) {
              final pct = r.federalTax > 0
                  ? b.taxInBracket / r.federalTax
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_formatPercent(b.rate)} bracket'),
                        Text(_formatCurrency(b.taxInBracket)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct.toDouble(),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    Text(
                      '${_formatCurrency(b.incomeInBracket)} taxed at ${_formatPercent(b.rate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
