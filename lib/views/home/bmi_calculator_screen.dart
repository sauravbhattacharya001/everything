import 'package:flutter/material.dart';
import '../../core/services/bmi_calculator_service.dart';

/// BMI Calculator with metric/imperial toggle, visual gauge, history, and
/// healthy-weight range display.
class BmiCalculatorScreen extends StatefulWidget {
  const BmiCalculatorScreen({super.key});

  @override
  State<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends State<BmiCalculatorScreen>
    with SingleTickerProviderStateMixin {
  bool _isMetric = true;
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();

  double? _bmi;
  BmiCategory? _category;
  (double, double)? _healthyRange;
  final List<BmiRecord> _history = [];

  late final AnimationController _animController;
  late Animation<double> _gaugeAnimation;
  double _animTarget = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _gaugeAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      _showError('Enter a valid weight');
      return;
    }

    double heightCm;
    double weightKg;

    if (_isMetric) {
      final h = double.tryParse(_heightController.text);
      if (h == null || h <= 0) {
        _showError('Enter a valid height in cm');
        return;
      }
      heightCm = h;
      weightKg = weight;
    } else {
      final feet = int.tryParse(_feetController.text);
      final inches = double.tryParse(_inchesController.text) ?? 0;
      if (feet == null || feet <= 0) {
        _showError('Enter a valid height');
        return;
      }
      heightCm = BmiCalculatorService.feetInchesToCm(feet, inches);
      weightKg = BmiCalculatorService.lbsToKg(weight);
    }

    final bmi = BmiCalculatorService.calculate(weightKg, heightCm);
    final cat = BmiCalculatorService.categorize(bmi);
    final range = BmiCalculatorService.healthyWeightRange(heightCm);

    setState(() {
      _bmi = bmi;
      _category = cat;
      _healthyRange = range;
      _history.insert(
        0,
        BmiRecord(
          date: DateTime.now(),
          weightKg: weightKg,
          heightCm: heightCm,
          bmi: bmi,
          category: cat,
        ),
      );
    });

    // Animate gauge
    final oldTarget = _animTarget;
    _animTarget = bmi.clamp(10, 50);
    _gaugeAnimation = Tween<double>(begin: oldTarget, end: _animTarget).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('BMI Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Unit toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Metric')),
              ButtonSegment(value: false, label: Text('Imperial')),
            ],
            selected: {_isMetric},
            onSelectionChanged: (v) => setState(() {
              _isMetric = v.first;
              _bmi = null;
              _category = null;
            }),
          ),
          const SizedBox(height: 20),

          // Weight input
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _isMetric ? 'Weight (kg)' : 'Weight (lbs)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.monitor_weight_outlined),
            ),
          ),
          const SizedBox(height: 12),

          // Height input
          if (_isMetric)
            TextField(
              controller: _heightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.height),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Feet',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.height),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _inchesController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Inches',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),

          // Calculate button
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate BMI'),
          ),
          const SizedBox(height: 24),

          // Result card with animated gauge
          if (_bmi != null && _category != null) ...[
            _buildResultCard(theme),
            const SizedBox(height: 16),
            _buildCategoryChart(theme),
            const SizedBox(height: 16),
            if (_healthyRange != null) _buildHealthyRange(theme),
          ],

          // History
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('History', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._history.take(10).map((r) => _buildHistoryTile(r, theme)),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    return AnimatedBuilder(
      animation: _gaugeAnimation,
      builder: (context, _) {
        final value = _gaugeAnimation.value;
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Color(_category!.colorValue),
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(_category!.label),
                  backgroundColor:
                      Color(_category!.colorValue).withValues(alpha: 0.15),
                  side: BorderSide(
                    color: Color(_category!.colorValue).withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 16),
                // Linear gauge
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 12,
                    child: CustomPaint(
                      size: const Size(double.infinity, 12),
                      painter: _BmiGaugePainter(value),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('10', style: theme.textTheme.bodySmall),
                    Text('18.5', style: theme.textTheme.bodySmall),
                    Text('25', style: theme.textTheme.bodySmall),
                    Text('30', style: theme.textTheme.bodySmall),
                    Text('40+', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChart(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BMI Categories', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            ...BmiCategory.values.map((cat) {
              final isActive = cat == _category;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(cat.colorValue),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.label,
                        style: TextStyle(
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      cat.range,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isActive)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.arrow_left, size: 16),
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

  Widget _buildHealthyRange(ThemeData theme) {
    final (minW, maxW) = _healthyRange!;
    final minDisp = _isMetric
        ? '${minW.toStringAsFixed(1)} kg'
        : '${BmiCalculatorService.kgToLbs(minW).toStringAsFixed(1)} lbs';
    final maxDisp = _isMetric
        ? '${maxW.toStringAsFixed(1)} kg'
        : '${BmiCalculatorService.kgToLbs(maxW).toStringAsFixed(1)} lbs';
    return Card(
      color: Colors.green.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Healthy weight range: $minDisp – $maxDisp'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(BmiRecord record, ThemeData theme) {
    final dateStr =
        '${record.date.month}/${record.date.day}/${record.date.year} '
        '${record.date.hour.toString().padLeft(2, '0')}:'
        '${record.date.minute.toString().padLeft(2, '0')}';
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor:
            Color(record.category.colorValue).withValues(alpha: 0.2),
        child: Text(
          record.bmi.toStringAsFixed(0),
          style: TextStyle(
            color: Color(record.category.colorValue),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text('BMI ${record.bmi.toStringAsFixed(1)} – ${record.category.label}'),
      subtitle: Text(
        '${record.weightKg.toStringAsFixed(1)} kg · ${record.heightCm.toStringAsFixed(0)} cm · $dateStr',
      ),
    );
  }
}

/// Paints a horizontal BMI gauge with color zones.
class _BmiGaugePainter extends CustomPainter {
  final double bmi;
  _BmiGaugePainter(this.bmi);

  @override
  void paint(Canvas canvas, Size size) {
    final zones = [
      (10.0, 18.5, const Color(0xFF2196F3)),
      (18.5, 25.0, const Color(0xFF4CAF50)),
      (25.0, 30.0, const Color(0xFFFF9800)),
      (30.0, 50.0, const Color(0xFFF44336)),
    ];
    const minBmi = 10.0;
    const maxBmi = 50.0;
    final range = maxBmi - minBmi;

    for (final (start, end, color) in zones) {
      final x1 = ((start - minBmi) / range) * size.width;
      final x2 = ((end - minBmi) / range) * size.width;
      canvas.drawRect(
        Rect.fromLTWH(x1, 0, x2 - x1, size.height),
        Paint()..color = color,
      );
    }

    // Indicator
    final indicatorX =
        ((bmi.clamp(minBmi, maxBmi) - minBmi) / range) * size.width;
    canvas.drawCircle(
      Offset(indicatorX, size.height / 2),
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(indicatorX, size.height / 2),
      8,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _BmiGaugePainter old) => old.bmi != bmi;
}


