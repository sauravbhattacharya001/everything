import 'package:flutter/material.dart';
import '../../models/weight_entry.dart';
import '../../core/services/weight_tracker_service.dart';
import 'dart:math';

/// Weight Tracker with logging, BMI calculation, trend analysis,
/// goal tracking, and visual progress chart.
class WeightTrackerScreen extends StatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  State<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends State<WeightTrackerScreen> {
  final _service = const WeightTrackerService();
  final List<WeightEntry> _entries = [];

  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  final _heightController = TextEditingController(text: '170');
  final _goalController = TextEditingController();

  WeightUnit _unit = WeightUnit.kg;
  double _heightCm = 170;
  double? _goalKg;

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _addEntry() {
    final raw = double.tryParse(_weightController.text);
    if (raw == null || raw <= 0 || raw > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid weight value')),
      );
      return;
    }
    final kg = _unit == WeightUnit.kg ? raw : raw / 2.20462;
    final entry = WeightEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      timestamp: DateTime.now(),
      weightKg: kg,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );
    setState(() {
      _entries.insert(0, entry);
      _weightController.clear();
      _noteController.clear();
    });
  }

  void _deleteEntry(int index) {
    setState(() => _entries.removeAt(index));
  }

  void _updateHeight() {
    final h = double.tryParse(_heightController.text);
    if (h != null && h > 0) {
      setState(() => _heightCm = h);
    }
  }

  void _updateGoal() {
    final g = double.tryParse(_goalController.text);
    if (g != null && g > 0) {
      setState(() => _goalKg = _unit == WeightUnit.kg ? g : g / 2.20462);
    }
  }

  String _formatWeight(double kg) {
    final val = _unit == WeightUnit.kg ? kg : kg * 2.20462;
    return '${val.toStringAsFixed(1)} ${_unit.label}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _updateHeight();

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚖️ Weight Tracker'),
        actions: [
          SegmentedButton<WeightUnit>(
            segments: const [
              ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
              ButtonSegment(value: WeightUnit.lbs, label: Text('lbs')),
            ],
            selected: {_unit},
            onSelectionChanged: (s) => setState(() => _unit = s.first),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Input card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log Weight', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Weight (${_unit.label})',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Height (cm)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _updateHeight(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Note (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _goalController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Goal (${_unit.label})',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => _updateGoal(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addEntry,
                      icon: const Icon(Icons.add),
                      label: const Text('Log Weight'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats cards
          if (_entries.isNotEmpty) ...[
            _buildStatsSection(theme),
            const SizedBox(height: 16),
            _buildChartSection(theme),
            const SizedBox(height: 16),
          ],

          // History
          Text('History', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_entries.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No entries yet. Log your first weight!')),
              ),
            )
          else
            ..._entries.asMap().entries.map((e) => _buildEntryCard(e.key, e.value, theme)),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    final latest = _entries.first;
    final bmiVal = latest.bmi(_heightCm);
    final cat = latest.bmiCategory(_heightCm);
    final weekAvg = _service.weeklyAverage(_entries);
    final trend = _service.weeklyTrend(_entries);
    final streak = _service.currentStreak(_entries);
    final minW = _service.minWeight(_entries);
    final maxW = _service.maxWeight(_entries);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stats', style: theme.textTheme.titleMedium),
            const Divider(),
            _statRow('Current', _formatWeight(latest.weightKg)),
            _statRow('BMI', '${bmiVal.toStringAsFixed(1)} ${cat.emoji} ${cat.label}'),
            if (weekAvg != null) _statRow('7-day avg', _formatWeight(weekAvg)),
            if (trend != null)
              _statRow(
                'Weekly trend',
                '${trend >= 0 ? "+" : ""}${_formatWeight(trend.abs())}${trend > 0 ? " ↑" : trend < 0 ? " ↓" : ""}',
              ),
            _statRow('Streak', '$streak day${streak == 1 ? "" : "s"}'),
            if (minW != null) _statRow('All-time low', _formatWeight(minW)),
            if (maxW != null) _statRow('All-time high', _formatWeight(maxW)),
            if (_goalKg != null) ...[
              const Divider(),
              _buildGoalProgress(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgress(ThemeData theme) {
    if (_entries.isEmpty || _goalKg == null) return const SizedBox.shrink();
    final startKg = _entries.last.weightKg; // oldest entry
    final progress = _service.goalProgress(_entries, startKg, _goalKg!);
    final pct = (progress * 100).clamp(0, 200);
    final remaining = (_entries.first.weightKg - _goalKg!).abs();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Goal: ${_formatWeight(_goalKg!)}'),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0, 1),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text('${pct.toStringAsFixed(0)}% — ${_formatWeight(remaining)} to go',
            style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildChartSection(ThemeData theme) {
    final sorted = [..._entries]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (sorted.length < 2) return const SizedBox.shrink();

    final weights = sorted.map((e) => e.weightKg).toList();
    final minW = weights.reduce(min) - 1;
    final maxW = weights.reduce(max) + 1;
    final range = maxW - minW;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trend', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: CustomPaint(
                size: const Size(double.infinity, 150),
                painter: _WeightChartPainter(
                  weights: weights,
                  minVal: minW,
                  range: range,
                  lineColor: theme.colorScheme.primary,
                  goalKg: _goalKg,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(sorted.first.timestamp), style: theme.textTheme.bodySmall),
                Text(_formatDate(sorted.last.timestamp), style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(int index, WeightEntry entry, ThemeData theme) {
    final cat = entry.bmiCategory(_heightCm);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _bmiColor(cat),
          child: Text(cat.emoji, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(entry.displayWeight(_unit)),
        subtitle: Text(
          '${_formatDateTime(entry.timestamp)} • BMI ${entry.bmi(_heightCm).toStringAsFixed(1)}'
          '${entry.note != null ? " • ${entry.note}" : ""}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteEntry(index),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _bmiColor(BMICategory cat) {
    switch (cat) {
      case BMICategory.underweight:
        return Colors.blue.shade100;
      case BMICategory.normal:
        return Colors.green.shade100;
      case BMICategory.overweight:
        return Colors.amber.shade100;
      case BMICategory.obeseClass1:
        return Colors.orange.shade100;
      case BMICategory.obeseClass2:
        return Colors.red.shade100;
      case BMICategory.obeseClass3:
        return Colors.red.shade200;
    }
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}';
  String _formatDateTime(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}';
}

class _WeightChartPainter extends CustomPainter {
  final List<double> weights;
  final double minVal;
  final double range;
  final Color lineColor;
  final double? goalKg;

  _WeightChartPainter({
    required this.weights,
    required this.minVal,
    required this.range,
    required this.lineColor,
    this.goalKg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.length < 2 || range == 0) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < weights.length; i++) {
      final x = i / (weights.length - 1) * size.width;
      final y = size.height - ((weights[i] - minVal) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
    canvas.drawPath(path, paint);

    // Goal line
    if (goalKg != null) {
      final goalY = size.height - ((goalKg! - minVal) / range * size.height);
      if (goalY >= 0 && goalY <= size.height) {
        final goalPaint = Paint()
          ..color = Colors.green
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(0, goalY), Offset(size.width, goalY), goalPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
