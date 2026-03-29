import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/salary_calculator_service.dart';

/// A salary / take-home-pay calculator.
///
/// Enter gross salary, filing status, state tax rate, pre-tax deductions,
/// and see a full breakdown of federal tax, state tax, FICA, and net pay
/// across multiple pay frequencies.
class SalaryCalculatorScreen extends StatefulWidget {
  const SalaryCalculatorScreen({super.key});

  @override
  State<SalaryCalculatorScreen> createState() => _SalaryCalculatorScreenState();
}

class _SalaryCalculatorScreenState extends State<SalaryCalculatorScreen> {
  final _grossController = TextEditingController(text: '75000');
  final _stateRateController = TextEditingController(text: '5.0');
  final _k401Controller = TextEditingController(text: '0');
  final _healthController = TextEditingController(text: '0');
  final _hsaController = TextEditingController(text: '0');

  FilingStatus _filingStatus = FilingStatus.single;
  PayFrequency _frequency = PayFrequency.biweekly;
  SalaryResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _grossController.dispose();
    _stateRateController.dispose();
    _k401Controller.dispose();
    _healthController.dispose();
    _hsaController.dispose();
    super.dispose();
  }

  void _calculate() {
    final gross = double.tryParse(_grossController.text.trim());
    if (gross == null || gross <= 0) {
      setState(() => _result = null);
      return;
    }
    final stateRate =
        (double.tryParse(_stateRateController.text.trim()) ?? 0) / 100;
    final k401 = double.tryParse(_k401Controller.text.trim()) ?? 0;
    final health = double.tryParse(_healthController.text.trim()) ?? 0;
    final hsa = double.tryParse(_hsaController.text.trim()) ?? 0;

    setState(() {
      _result = SalaryCalculatorService.calculate(
        grossAnnual: gross,
        filingStatus: _filingStatus,
        stateTaxRate: stateRate,
        preTax401k: k401,
        preTaxHealthInsurance: health,
        preTaxHSA: hsa,
        frequency: _frequency,
      );
    });
  }

  String _fmt(double v) => '\$${v.toStringAsFixed(2)}';
  String _fmtPct(double v) => '${v.toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Salary Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gross salary
          TextField(
            controller: _grossController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Annual Gross Salary',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),

          // Filing status
          Text('Filing Status', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<FilingStatus>(
            segments: const [
              ButtonSegment(
                value: FilingStatus.single,
                label: Text('Single'),
                icon: Icon(Icons.person),
              ),
              ButtonSegment(
                value: FilingStatus.marriedJointly,
                label: Text('Married'),
                icon: Icon(Icons.people),
              ),
            ],
            selected: {_filingStatus},
            onSelectionChanged: (v) {
              setState(() => _filingStatus = v.first);
              _calculate();
            },
          ),
          const SizedBox(height: 16),

          // State tax rate
          TextField(
            controller: _stateRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'State Tax Rate',
              suffixText: '%',
              border: OutlineInputBorder(),
              helperText: 'e.g. 0 for WA/TX/FL, 13.3 for CA top bracket',
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),

          // Pre-tax deductions
          Text('Pre-Tax Deductions (Annual)',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _k401Controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: '401(k)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _healthController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Health Ins.',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _hsaController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'HSA',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _calculate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pay frequency
          Text('Pay Frequency', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<PayFrequency>(
            value: _frequency,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: PayFrequency.values.map((f) {
              final labels = {
                PayFrequency.annually: 'Annually',
                PayFrequency.monthly: 'Monthly',
                PayFrequency.semiMonthly: 'Semi-Monthly (24/yr)',
                PayFrequency.biweekly: 'Bi-Weekly (26/yr)',
                PayFrequency.weekly: 'Weekly (52/yr)',
              };
              return DropdownMenuItem(value: f, child: Text(labels[f]!));
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _frequency = v);
                _calculate();
              }
            },
          ),
          const SizedBox(height: 24),

          // Results
          if (_result != null) ...[
            _buildResultCard(theme),
            const SizedBox(height: 16),
            _buildBreakdownCard(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    final r = _result!;
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Take-Home Pay',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer)),
            const SizedBox(height: 8),
            Text(
              _fmt(r.netPerPeriod),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              'per paycheck',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('Annual Net', _fmt(r.netAnnual), theme),
                _miniStat('Effective Rate', _fmtPct(r.effectiveTaxRate), theme),
                _miniStat('Marginal Rate', _fmtPct(r.marginalTaxRate), theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer)),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer)),
      ],
    );
  }

  Widget _buildBreakdownCard(ThemeData theme) {
    final r = _result!;
    final mult = SalaryCalculatorService.frequencyMultipliers[r.frequency]!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Breakdown', style: theme.textTheme.titleMedium),
            const Divider(),
            _row('Gross Salary', r.grossAnnual, mult),
            _row('Pre-Tax Deductions', -r.totalPreTaxDeductions, mult),
            const Divider(),
            _row('Federal Income Tax', -r.federalTax, mult),
            _row('State Income Tax', -r.stateTax, mult),
            _row('Social Security', -r.socialSecurity, mult),
            _row('Medicare', -r.medicare, mult),
            const Divider(),
            _row('Total Taxes', -r.totalTax, mult, bold: true),
            const Divider(),
            _row('Net Pay', r.netAnnual, mult, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double annual, int mult, {bool bold = false}) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold)
        : const TextStyle();
    final perPeriod = annual / mult;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          SizedBox(
              width: 100,
              child:
                  Text(_fmt(annual), textAlign: TextAlign.right, style: style)),
          SizedBox(
              width: 100,
              child: Text(_fmt(perPeriod),
                  textAlign: TextAlign.right, style: style)),
        ],
      ),
    );
  }
}
