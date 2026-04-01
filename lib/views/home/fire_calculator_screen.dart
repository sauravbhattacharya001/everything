import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/fire_calculator_service.dart';

/// FIRE (Financial Independence, Retire Early) Calculator screen.
///
/// Helps users determine how many years until they can retire based on
/// their income, expenses, savings, and expected investment returns.
class FireCalculatorScreen extends StatefulWidget {
  const FireCalculatorScreen({super.key});

  @override
  State<FireCalculatorScreen> createState() => _FireCalculatorScreenState();
}

class _FireCalculatorScreenState extends State<FireCalculatorScreen> {
  final _service = const FireCalculatorService();

  final _incomeCtrl = TextEditingController(text: '80000');
  final _expensesCtrl = TextEditingController(text: '50000');
  final _savingsCtrl = TextEditingController(text: '50000');
  final _returnCtrl = TextEditingController(text: '7');
  WithdrawalStrategy _strategy = WithdrawalStrategy.standard;

  FireResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _expensesCtrl.dispose();
    _savingsCtrl.dispose();
    _returnCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final income = double.tryParse(_incomeCtrl.text) ?? 0;
    final expenses = double.tryParse(_expensesCtrl.text) ?? 0;
    final savings = double.tryParse(_savingsCtrl.text) ?? 0;
    final returnRate = double.tryParse(_returnCtrl.text) ?? 7;

    setState(() {
      _result = _service.calculate(
        annualIncome: income,
        annualExpenses: expenses,
        currentSavings: savings,
        expectedReturn: returnRate,
        strategy: _strategy,
      );
    });
  }

  String _formatCurrency(double value) {
    if (value >= 1e9) return '\$${(value / 1e9).toStringAsFixed(2)}B';
    if (value >= 1e6) return '\$${(value / 1e6).toStringAsFixed(2)}M';
    if (value >= 1e3) return '\$${(value / 1e3).toStringAsFixed(1)}K';
    return '\$${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('FIRE Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Inputs card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Finances',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildInput('Annual Income', _incomeCtrl, Icons.work),
                  const SizedBox(height: 8),
                  _buildInput(
                      'Annual Expenses', _expensesCtrl, Icons.shopping_cart),
                  const SizedBox(height: 8),
                  _buildInput(
                      'Current Savings', _savingsCtrl, Icons.savings),
                  const SizedBox(height: 8),
                  _buildInput(
                      'Expected Return (%)', _returnCtrl, Icons.trending_up),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<WithdrawalStrategy>(
                    value: _strategy,
                    decoration: const InputDecoration(
                      labelText: 'Withdrawal Strategy',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                      border: OutlineInputBorder(),
                    ),
                    items: WithdrawalStrategy.values
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s.label)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        _strategy = v;
                        _calculate();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _calculate,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calculate'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_result != null) ...[
            const SizedBox(height: 16),
            _buildResultsCard(_result!, theme),
            const SizedBox(height: 16),
            _buildMilestonesCard(_result!, theme),
            const SizedBox(height: 16),
            _buildChartCard(_result!, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildInput(
      String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => _calculate(),
    );
  }

  Widget _buildResultsCard(FireResult result, ThemeData theme) {
    final rateColor = Color(_service.savingsRateColorValue(result.savingsRate));
    final rateLabel = _service.savingsRateLabel(result.savingsRate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Results',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // FIRE number
            _resultRow(
              'FIRE Number',
              _formatCurrency(result.fireNumber),
              Icons.flag,
              theme,
            ),
            const SizedBox(height: 8),
            // Years to FIRE
            _resultRow(
              'Years to FIRE',
              result.achievable
                  ? '${result.yearsToFire} years'
                  : '60+ years',
              Icons.timer,
              theme,
              valueColor: result.achievable ? null : Colors.red,
            ),
            const SizedBox(height: 8),
            // Savings rate
            Row(
              children: [
                Icon(Icons.pie_chart, size: 20, color: rateColor),
                const SizedBox(width: 8),
                Text('Savings Rate: ',
                    style: theme.textTheme.bodyMedium),
                Text(
                  '${result.savingsRate.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold, color: rateColor),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: rateColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(rateLabel,
                      style: TextStyle(
                          fontSize: 12,
                          color: rateColor,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _resultRow(
              'Safe Annual Withdrawal',
              _formatCurrency(result.annualWithdrawal),
              Icons.payments,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, IconData icon,
      ThemeData theme, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestonesCard(FireResult result, ThemeData theme) {
    if (result.projection.isEmpty) return const SizedBox.shrink();

    final milestones = <_Milestone>[];
    final fire = result.fireNumber;
    for (final pct in [25, 50, 75, 100]) {
      final target = fire * pct / 100;
      for (final p in result.projection) {
        if (p.portfolioValue >= target) {
          milestones.add(_Milestone(pct, p.year, p.portfolioValue));
          break;
        }
      }
    }

    if (milestones.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Milestones',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...milestones.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text('${m.percent}%',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: theme.colorScheme.onPrimaryContainer)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Year ${m.year}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              _formatCurrency(m.value),
                              style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(FireResult result, ThemeData theme) {
    if (result.projection.length < 2) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Portfolio Growth',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: CustomPaint(
                size: const Size(double.infinity, 200),
                painter: _GrowthChartPainter(
                  projection: result.projection,
                  fireNumber: result.fireNumber,
                  primaryColor: theme.colorScheme.primary,
                  fireColor: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(theme.colorScheme.primary, 'Portfolio'),
                const SizedBox(width: 16),
                _legendDot(Colors.green, 'FIRE Target'),
                const SizedBox(width: 16),
                _legendDot(Colors.grey.shade400, 'Contributions'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _Milestone {
  final int percent;
  final int year;
  final double value;
  const _Milestone(this.percent, this.year, this.value);
}

class _GrowthChartPainter extends CustomPainter {
  final List<FireProjectionYear> projection;
  final double fireNumber;
  final Color primaryColor;
  final Color fireColor;

  _GrowthChartPainter({
    required this.projection,
    required this.fireNumber,
    required this.primaryColor,
    required this.fireColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (projection.isEmpty) return;

    final maxVal = projection
        .map((p) => p.portfolioValue)
        .reduce((a, b) => a > b ? a : b);
    final maxY = [maxVal, fireNumber].reduce((a, b) => a > b ? a : b) * 1.1;
    final maxX = projection.last.year.toDouble();
    if (maxX == 0 || maxY == 0) return;

    double toX(double year) => (year / maxX) * size.width;
    double toY(double value) => size.height - (value / maxY) * size.height;

    // Contributions area (grey)
    final contribPath = Path()..moveTo(toX(0), toY(0));
    for (final p in projection) {
      contribPath.lineTo(toX(p.year.toDouble()), toY(p.totalContributed));
    }
    contribPath.lineTo(toX(maxX), size.height);
    contribPath.lineTo(0, size.height);
    contribPath.close();
    canvas.drawPath(
      contribPath,
      Paint()..color = Colors.grey.withOpacity(0.2),
    );

    // Portfolio line
    final portfolioPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final portfolioPath = Path();
    for (int i = 0; i < projection.length; i++) {
      final x = toX(projection[i].year.toDouble());
      final y = toY(projection[i].portfolioValue);
      if (i == 0) {
        portfolioPath.moveTo(x, y);
      } else {
        portfolioPath.lineTo(x, y);
      }
    }
    canvas.drawPath(portfolioPath, portfolioPaint);

    // FIRE target line (dashed)
    final firePaint = Paint()
      ..color = fireColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fireY = toY(fireNumber);
    const dashWidth = 6.0;
    const dashGap = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, fireY),
        Offset((startX + dashWidth).clamp(0, size.width), fireY),
        firePaint,
      );
      startX += dashWidth + dashGap;
    }

    // Axis labels
    final textStyle = TextStyle(color: Colors.grey.shade600, fontSize: 10);
    _drawText(canvas, '0', Offset(0, size.height + 2), textStyle);
    _drawText(canvas, '${maxX.toInt()}y',
        Offset(size.width - 20, size.height + 2), textStyle);
    _drawText(canvas, _shortCurrency(maxY), const Offset(0, -14), textStyle);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  String _shortCurrency(double v) {
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter oldDelegate) =>
      projection != oldDelegate.projection ||
      fireNumber != oldDelegate.fireNumber;
}
