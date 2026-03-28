import 'package:flutter/material.dart';
import '../../core/services/mortgage_calculator_service.dart';

/// Mortgage Calculator screen — compute monthly payments, total interest,
/// and view a full amortization schedule for fixed-rate mortgages.
class MortgageCalculatorScreen extends StatefulWidget {
  const MortgageCalculatorScreen({super.key});

  @override
  State<MortgageCalculatorScreen> createState() =>
      _MortgageCalculatorScreenState();
}

class _MortgageCalculatorScreenState extends State<MortgageCalculatorScreen> {
  final _service = const MortgageCalculatorService();
  final _principalController = TextEditingController(text: '300000');
  final _rateController = TextEditingController(text: '6.5');
  final _termController = TextEditingController(text: '30');
  final _extraController = TextEditingController(text: '0');

  MortgageSummary? _summary;
  bool _showSchedule = false;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _termController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  void _calculate() {
    final principal = double.tryParse(
        _principalController.text.replaceAll(',', ''));
    final rate = double.tryParse(_rateController.text);
    final term = int.tryParse(_termController.text);
    final extra = double.tryParse(_extraController.text) ?? 0;

    if (principal == null || principal <= 0 ||
        rate == null || rate < 0 ||
        term == null || term <= 0) {
      setState(() => _summary = null);
      return;
    }

    setState(() {
      _summary = _service.calculate(
        principal: principal,
        annualRatePercent: rate,
        termYears: term,
        extraMonthlyPayment: extra,
      );
      _showSchedule = false;
    });
  }

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '\$${buffer.toString()}.$decPart';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mortgage Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Input Fields ──
          _buildTextField(
            controller: _principalController,
            label: 'Loan Amount (\$)',
            icon: Icons.home,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _rateController,
            label: 'Annual Interest Rate (%)',
            icon: Icons.percent,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _termController,
            label: 'Loan Term (years)',
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _extraController,
            label: 'Extra Monthly Payment (\$)',
            icon: Icons.add_circle_outline,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate'),
          ),

          // ── Results ──
          if (_summary != null) ...[
            const SizedBox(height: 24),
            _buildResultCard(theme),
            const SizedBox(height: 16),
            _buildBreakdownCard(theme),
            const SizedBox(height: 16),
            _buildAffordabilityCard(theme),
            const SizedBox(height: 16),
            _buildScheduleSection(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    final s = _summary!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Payment',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(height: 4),
            Text(
              _formatCurrency(s.monthlyPayment),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (double.tryParse(_extraController.text) != null &&
                double.parse(_extraController.text) > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Total with extra: ${_formatCurrency(s.monthlyPayment + double.parse(_extraController.text))}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard(ThemeData theme) {
    final s = _summary!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loan Breakdown',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _summaryRow('Principal', _formatCurrency(s.loanAmount)),
            _summaryRow('Total Interest', _formatCurrency(s.totalInterest)),
            const Divider(),
            _summaryRow('Total Cost', _formatCurrency(s.totalPayment)),
            const SizedBox(height: 12),
            // Interest-to-principal ratio bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: s.totalInterest / s.totalPayment,
                minHeight: 8,
                backgroundColor: theme.colorScheme.primary.withAlpha(51),
                valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.error.withAlpha(179)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(s.totalInterest / s.totalPayment * 100).toStringAsFixed(1)}% goes to interest',
              style: theme.textTheme.bodySmall,
            ),
            if (s.schedule.length < s.termYears * 12) ...[
              const SizedBox(height: 8),
              Text(
                '🎉 Paid off in ${(s.schedule.length / 12).toStringAsFixed(1)} years with extra payments!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAffordabilityCard(ThemeData theme) {
    final rate = double.tryParse(_rateController.text);
    if (rate == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Affordability Check',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final budget in [1500.0, 2000.0, 2500.0, 3000.0, 4000.0])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${_formatCurrency(budget)}/mo → ${_formatCurrency(_service.maxLoanAmount(monthlyBudget: budget, annualRatePercent: rate, termYears: int.tryParse(_termController.text) ?? 30))} loan',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection(ThemeData theme) {
    final s = _summary!;
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () => setState(() => _showSchedule = !_showSchedule),
          icon: Icon(_showSchedule ? Icons.expand_less : Icons.expand_more),
          label: Text(_showSchedule
              ? 'Hide Amortization Schedule'
              : 'Show Amortization Schedule (${s.schedule.length} months)'),
        ),
        if (_showSchedule) ...[
          const SizedBox(height: 12),
          // Show yearly summaries instead of every month for readability
          for (int year = 0;
              year < (s.schedule.length / 12).ceil();
              year++) ...[
            _buildYearSummary(theme, s, year + 1),
          ],
        ],
      ],
    );
  }

  Widget _buildYearSummary(
      ThemeData theme, MortgageSummary s, int year) {
    final startMonth = (year - 1) * 12;
    final endMonth =
        (year * 12).clamp(0, s.schedule.length);
    if (startMonth >= s.schedule.length) return const SizedBox.shrink();

    final yearRows = s.schedule.sublist(startMonth, endMonth);
    final yearInterest =
        yearRows.fold<double>(0, (sum, r) => sum + r.interest);
    final yearPrincipal =
        yearRows.fold<double>(0, (sum, r) => sum + r.principal);
    final endBalance = yearRows.last.balance;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text('Year $year',
            style: theme.textTheme.titleSmall),
        subtitle: Text(
          'Principal: ${_formatCurrency(yearPrincipal)} · '
          'Interest: ${_formatCurrency(yearInterest)}',
        ),
        trailing: Text(
          _formatCurrency(endBalance),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))],
      ),
    );
  }
}
