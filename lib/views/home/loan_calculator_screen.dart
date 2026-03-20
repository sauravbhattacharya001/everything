import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/loan_calculator_service.dart';

/// Loan/EMI calculator with presets, amortization schedule,
/// extra payment analysis, and copy-to-clipboard.
class LoanCalculatorScreen extends StatefulWidget {
  const LoanCalculatorScreen({super.key});

  @override
  State<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen>
    with SingleTickerProviderStateMixin {
  final _principalCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _tenureCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();

  late TabController _tabCtrl;
  LoanResult? _result;
  ExtraPaymentResult? _extraResult;
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _tenureCtrl.dispose();
    _extraCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(String name) {
    final preset = LoanCalculatorService.presets[name]!;
    setState(() {
      _selectedPreset = name;
      _rateCtrl.text = preset.rate.toString();
      _tenureCtrl.text = preset.months.toString();
    });
    _calculate();
  }

  void _calculate() {
    final p = double.tryParse(_principalCtrl.text.replaceAll(',', ''));
    final r = double.tryParse(_rateCtrl.text);
    final m = int.tryParse(_tenureCtrl.text);
    if (p == null || p <= 0 || r == null || m == null || m <= 0) {
      setState(() {
        _result = null;
        _extraResult = null;
      });
      return;
    }
    final result =
        LoanCalculatorService.calculate(principal: p, annualRate: r, months: m);
    final extra = double.tryParse(_extraCtrl.text.replaceAll(',', '')) ?? 0;
    ExtraPaymentResult? extraResult;
    if (extra > 0) {
      extraResult = LoanCalculatorService.calculateExtraPay(
        principal: p,
        annualRate: r,
        months: m,
        extraMonthly: extra,
      );
    }
    setState(() {
      _result = result;
      _extraResult = extraResult;
    });
  }

  String _fmt(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Calculator'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Calculator'),
            Tab(text: 'Schedule'),
            Tab(text: 'Extra Pay'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCalculatorTab(theme),
          _buildScheduleTab(theme),
          _buildExtraPayTab(theme),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Presets
        Text('Loan Type', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LoanCalculatorService.presets.keys.map((name) {
            final selected = _selectedPreset == name;
            return ChoiceChip(
              label: Text(name,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : null,
                  )),
              selected: selected,
              selectedColor: theme.colorScheme.primary,
              onSelected: (_) => _applyPreset(name),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Principal
        TextField(
          controller: _principalCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Loan Amount',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _calculate(),
        ),
        const SizedBox(height: 16),

        // Rate & Tenure row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Annual Rate',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  _selectedPreset = null;
                  _calculate();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _tenureCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Tenure',
                  suffixText: 'months',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  _selectedPreset = null;
                  _calculate();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Results
        if (_result != null) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Monthly EMI', style: theme.textTheme.titleSmall),
                  Text(
                    _fmt(_result!.emi),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _row('Principal', _fmt(_result!.principal)),
          _row('Total Interest', _fmt(_result!.totalInterest)),
          _row('Total Payment', _fmt(_result!.totalPayment)),
          _row(
              'Interest %',
              '${(_result!.totalInterest / _result!.principal * 100).toStringAsFixed(1)}%'),
          const SizedBox(height: 16),

          // Pie chart placeholder - visual ratio bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: (_result!.principal * 100 / _result!.totalPayment)
                      .round(),
                  child: Container(
                    height: 24,
                    color: theme.colorScheme.primary,
                    alignment: Alignment.center,
                    child: Text('Principal',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
                Expanded(
                  flex: (_result!.totalInterest * 100 / _result!.totalPayment)
                      .round(),
                  child: Container(
                    height: 24,
                    color: Colors.orange,
                    alignment: Alignment.center,
                    child: Text('Interest',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              final text =
                  'Loan: ${_fmt(_result!.principal)} | Rate: ${_result!.annualRate}% | ${_result!.months} months\n'
                  'EMI: ${_fmt(_result!.emi)} | Total: ${_fmt(_result!.totalPayment)} | Interest: ${_fmt(_result!.totalInterest)}';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Copied'), duration: Duration(seconds: 1)),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Summary'),
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleTab(ThemeData theme) {
    if (_result == null || _result!.schedule.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Enter loan details in Calculator tab first.',
              textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _result!.schedule.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                children: [
                  SizedBox(
                      width: 40,
                      child: Text('#',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold))),
                  Expanded(
                      child: Text('Principal',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold))),
                  Expanded(
                      child: Text('Interest',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold))),
                  Expanded(
                      child: Text('Balance',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.end)),
                ],
              ),
            ),
          );
        }
        final e = _result!.schedule[i - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                  width: 40,
                  child: Text('${e.month}',
                      style: theme.textTheme.bodySmall)),
              Expanded(
                  child: Text(_fmt(e.principalPaid),
                      style: theme.textTheme.bodySmall)),
              Expanded(
                  child: Text(_fmt(e.interestPaid),
                      style: theme.textTheme.bodySmall)),
              Expanded(
                  child: Text(_fmt(e.balance),
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.end)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExtraPayTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'See how extra monthly payments reduce your loan.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _extraCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Extra Monthly Payment',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _calculate(),
        ),
        const SizedBox(height: 24),
        if (_result == null)
          const Text('Enter loan details in Calculator tab first.')
        else if (_extraResult == null)
          const Text('Enter an extra payment amount above.')
        else ...[
          Card(
            elevation: 2,
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Interest Saved', style: theme.textTheme.titleSmall),
                  Text(
                    _fmt(_extraResult!.interestSaved),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_extraResult!.monthsSaved} months earlier',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _row('Original Total', _fmt(_extraResult!.normalTotal)),
          _row('New Total', _fmt(_extraResult!.newTotal)),
          _row('Saved', _fmt(_extraResult!.interestSaved)),
          _row('Months Saved', '${_extraResult!.monthsSaved}'),
        ],
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
