import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/compound_interest_service.dart';

/// Compound Interest Calculator with visual projection chart.
class CompoundInterestScreen extends StatefulWidget {
  const CompoundInterestScreen({super.key});

  @override
  State<CompoundInterestScreen> createState() => _CompoundInterestScreenState();
}

class _CompoundInterestScreenState extends State<CompoundInterestScreen> {
  final _service = const CompoundInterestService();

  final _principalCtrl = TextEditingController(text: '10000');
  final _rateCtrl = TextEditingController(text: '7');
  final _yearsCtrl = TextEditingController(text: '30');
  final _monthlyCtrl = TextEditingController(text: '500');
  CompoundFrequency _frequency = CompoundFrequency.monthly;

  List<ProjectionPoint> _projection = [];
  bool _showChart = true;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _yearsCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final principal = double.tryParse(_principalCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    final years = int.tryParse(_yearsCtrl.text) ?? 0;
    final monthly = double.tryParse(_monthlyCtrl.text) ?? 0;

    setState(() {
      _projection = _service.calculate(
        principal: principal,
        annualRate: rate,
        years: years,
        monthlyContribution: monthly,
        compoundFrequency: _frequency,
      );
    });
  }

  String _formatCurrency(double value) {
    if (value >= 1e9) return '\$${(value / 1e9).toStringAsFixed(2)}B';
    if (value >= 1e6) return '\$${(value / 1e6).toStringAsFixed(2)}M';
    if (value >= 1e3) return '\$${(value / 1e3).toStringAsFixed(1)}K';
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final last = _projection.isNotEmpty ? _projection.last : null;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    final r72 = _service.ruleOf72(rate);

    return Scaffold(
      appBar: AppBar(title: const Text('Compound Interest')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Input fields
          _buildInputField('Principal (\$)', _principalCtrl, Icons.account_balance),
          const SizedBox(height: 12),
          _buildInputField('Annual Rate (%)', _rateCtrl, Icons.percent),
          const SizedBox(height: 12),
          _buildInputField('Years', _yearsCtrl, Icons.calendar_today),
          const SizedBox(height: 12),
          _buildInputField('Monthly Contribution (\$)', _monthlyCtrl, Icons.add_circle_outline),
          const SizedBox(height: 12),

          // Compound frequency dropdown
          DropdownButtonFormField<CompoundFrequency>(
            value: _frequency,
            decoration: const InputDecoration(
              labelText: 'Compound Frequency',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.repeat),
            ),
            items: CompoundFrequency.values
                .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                _frequency = v;
                _calculate();
              }
            },
          ),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate'),
          ),
          const SizedBox(height: 24),

          // Summary cards
          if (last != null) ...[
            Row(
              children: [
                Expanded(child: _summaryCard('Final Balance', _formatCurrency(last.balance), cs.primary, cs)),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard('Total Interest', _formatCurrency(last.totalInterest), cs.tertiary, cs)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _summaryCard('Contributed', _formatCurrency(last.totalContributed), cs.secondary, cs)),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard(
                  'Rule of 72',
                  rate > 0 ? '~${r72.toStringAsFixed(1)} yrs to 2×' : 'N/A',
                  cs.error,
                  cs,
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Chart toggle
            Row(
              children: [
                Text('Growth Chart', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: Icon(_showChart ? Icons.table_chart : Icons.bar_chart),
                  onPressed: () => setState(() => _showChart = !_showChart),
                  tooltip: _showChart ? 'Show Table' : 'Show Chart',
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_showChart)
              _buildChart(cs)
            else
              _buildTable(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      onChanged: (_) => _calculate(),
    );
  }

  Widget _summaryCard(String title, String value, Color color, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(ColorScheme cs) {
    if (_projection.length < 2) return const SizedBox.shrink();
    final maxVal = _projection.last.balance;
    if (maxVal <= 0) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: CustomPaint(
        size: const Size(double.infinity, 220),
        painter: _GrowthChartPainter(
          points: _projection,
          maxValue: maxVal,
          balanceColor: cs.primary,
          contributedColor: cs.secondary.withValues(alpha: 0.4),
          gridColor: cs.outlineVariant,
        ),
      ),
    );
  }

  Widget _buildTable(ThemeData theme) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(50),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
      },
      border: TableBorder.all(color: theme.dividerColor, width: 0.5),
      children: [
        TableRow(
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
          children: const [
            _TableHeader('Year'),
            _TableHeader('Balance'),
            _TableHeader('Contributed'),
            _TableHeader('Interest'),
          ],
        ),
        // Show every 5th year + last year for readability
        for (final p in _projection.where((p) => p.year % 5 == 0 || p.year == _projection.last.year))
          TableRow(children: [
            _TableCell('${p.year}'),
            _TableCell(_formatCurrency(p.balance)),
            _TableCell(_formatCurrency(p.totalContributed)),
            _TableCell(_formatCurrency(p.totalInterest)),
          ]),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      );
}

class _TableCell extends StatelessWidget {
  final String text;
  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      );
}

/// Custom painter for the growth chart.
class _GrowthChartPainter extends CustomPainter {
  final List<ProjectionPoint> points;
  final double maxValue;
  final Color balanceColor;
  final Color contributedColor;
  final Color gridColor;

  _GrowthChartPainter({
    required this.points,
    required this.maxValue,
    required this.balanceColor,
    required this.contributedColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || maxValue <= 0) return;

    final left = 50.0;
    final bottom = 30.0;
    final chartW = size.width - left - 16;
    final chartH = size.height - bottom - 8;

    // Grid lines
    final gridPaint = Paint()..color = gridColor..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = 8 + chartH * (1 - i / 4);
      canvas.drawLine(Offset(left, y), Offset(left + chartW, y), gridPaint);

      final label = _formatShort(maxValue * i / 4);
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(fontSize: 9, color: gridColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left - tp.width - 4, y - tp.height / 2));
    }

    // Contributed area (filled)
    final contribPath = Path()..moveTo(left, 8 + chartH);
    for (int i = 0; i < points.length; i++) {
      final x = left + (i / (points.length - 1)) * chartW;
      final y = 8 + chartH * (1 - points[i].totalContributed / maxValue);
      if (i == 0) {
        contribPath.lineTo(x, y);
      } else {
        contribPath.lineTo(x, y);
      }
    }
    contribPath.lineTo(left + chartW, 8 + chartH);
    contribPath.close();
    canvas.drawPath(contribPath, Paint()..color = contributedColor);

    // Balance line
    final balancePaint = Paint()
      ..color = balanceColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final balancePath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = left + (i / (points.length - 1)) * chartW;
      final y = 8 + chartH * (1 - points[i].balance / maxValue);
      if (i == 0) {
        balancePath.moveTo(x, y);
      } else {
        balancePath.lineTo(x, y);
      }
    }
    canvas.drawPath(balancePath, balancePaint);

    // X-axis labels
    final step = (points.length / 5).ceil().clamp(1, points.length);
    for (int i = 0; i < points.length; i += step) {
      final x = left + (i / (points.length - 1)) * chartW;
      final tp = TextPainter(
        text: TextSpan(text: '${points[i].year}', style: TextStyle(fontSize: 9, color: gridColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, 8 + chartH + 6));
    }
  }

  String _formatShort(double v) {
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter old) =>
      old.points != points || old.maxValue != maxValue;
}
