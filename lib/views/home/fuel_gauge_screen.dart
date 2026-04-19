import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/services/fuel_gauge_service.dart';

/// Daily Fuel Gauge — a proactive cross-tracker readiness scoring tool.
///
/// Aggregates sleep, hydration, energy, mood, caffeine, and activity
/// data into a single readiness score with dimension breakdowns and
/// personalized recommendations.
class FuelGaugeScreen extends StatefulWidget {
  const FuelGaugeScreen({super.key});

  @override
  State<FuelGaugeScreen> createState() => _FuelGaugeScreenState();
}

class _FuelGaugeScreenState extends State<FuelGaugeScreen>
    with SingleTickerProviderStateMixin {
  final FuelGaugeService _service = FuelGaugeService();
  late AnimationController _animController;
  late Animation<double> _scoreAnim;

  // Input state
  double _sleepHours = 7.0;
  int _waterGlasses = 4;
  int _energyLevel = 3;
  int _moodRating = 3;
  int _caffeineCount = 2;
  bool _exercised = false;

  // Readings stored by date string for trend comparison
  static final Map<String, FuelGaugeReading> _history = {};

  FuelGaugeReading? _currentReading;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scoreAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _recalculate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final today = _dateKey(DateTime.now());
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    final yesterdayReading = _history[yesterday];

    final reading = _service.generateReading(
      sleepHours: _sleepHours,
      waterGlasses: _waterGlasses,
      energyLevel: _energyLevel,
      moodRating: _moodRating,
      caffeineCount: _caffeineCount,
      exercised: _exercised,
      yesterday: yesterdayReading,
    );

    _history[today] = reading;

    final oldScore = _currentReading?.overallScore ?? 0;
    setState(() {
      _currentReading = reading;
      _scoreAnim = Tween<double>(begin: oldScore, end: reading.overallScore)
          .animate(CurvedAnimation(
              parent: _animController, curve: Curves.easeOutCubic));
    });
    _animController.forward(from: 0);
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reading = _currentReading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Fuel Gauge'),
        actions: [
          if (reading != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(reading.trend.icon, size: 20),
                  if (reading.trendDelta != null)
                    Text(
                      ' ${reading.trendDelta! >= 0 ? '+' : ''}${reading.trendDelta!.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
        ],
      ),
      body: reading == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Gauge ──
                  _buildGauge(theme, reading),
                  const SizedBox(height: 24),
                  // ── Dimensions Grid ──
                  _buildDimensionsGrid(theme, reading),
                  const SizedBox(height: 24),
                  // ── Inputs ──
                  _buildInputSection(theme),
                  const SizedBox(height: 16),
                  // ── Recalculate Button ──
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _recalculate,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Recalculate'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ── Recommendations ──
                  _buildRecommendations(theme, reading),
                ],
              ),
            ),
    );
  }

  Widget _buildGauge(ThemeData theme, FuelGaugeReading reading) {
    return AnimatedBuilder(
      animation: _scoreAnim,
      builder: (context, child) {
        return SizedBox(
          height: 200,
          width: 200,
          child: CustomPaint(
            painter: _GaugePainter(
              score: _scoreAnim.value,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _scoreAnim.value.toStringAsFixed(0),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: reading.overallStatus.color,
                    ),
                  ),
                  Text(
                    reading.overallStatus.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: reading.overallStatus.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDimensionsGrid(ThemeData theme, FuelGaugeReading reading) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: reading.dimensions.length,
      itemBuilder: (context, index) {
        final dim = reading.dimensions[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(dim.icon, size: 16, color: dim.status.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(dim.name,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Text('${dim.score.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: dim.status.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: dim.score / 100,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(dim.status.color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(dim.detail,
                    style: theme.textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Inputs",
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            // Sleep
            _sliderRow(
              icon: Icons.bedtime,
              label: 'Sleep: ${_sleepHours.toStringAsFixed(1)}h',
              value: _sleepHours,
              min: 0,
              max: 14,
              divisions: 28,
              onChanged: (v) => setState(() => _sleepHours = v),
            ),
            // Water
            _sliderRow(
              icon: Icons.water_drop,
              label: 'Water: $_waterGlasses glasses',
              value: _waterGlasses.toDouble(),
              min: 0,
              max: 16,
              divisions: 16,
              onChanged: (v) => setState(() => _waterGlasses = v.round()),
            ),
            // Energy
            _sliderRow(
              icon: Icons.bolt,
              label: 'Energy: $_energyLevel/5',
              value: _energyLevel.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) => setState(() => _energyLevel = v.round()),
            ),
            // Mood
            _sliderRow(
              icon: Icons.mood,
              label: 'Mood: $_moodRating/5',
              value: _moodRating.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) => setState(() => _moodRating = v.round()),
            ),
            // Caffeine
            _sliderRow(
              icon: Icons.coffee,
              label: 'Caffeine: $_caffeineCount cups',
              value: _caffeineCount.toDouble(),
              min: 0,
              max: 8,
              divisions: 8,
              onChanged: (v) => setState(() => _caffeineCount = v.round()),
            ),
            // Exercise
            SwitchListTile(
              secondary: const Icon(Icons.directions_run),
              title: const Text('Exercised today'),
              value: _exercised,
              onChanged: (v) => setState(() => _exercised = v),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(ThemeData theme, FuelGaugeReading reading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('💡 Recommendations',
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...reading.recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Card(
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.auto_awesome, size: 20),
                  title: Text(rec, style: const TextStyle(fontSize: 13)),
                ),
              ),
            )),
      ],
    );
  }
}

// ─── Gauge Painter ──────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  final double score;
  final Color backgroundColor;

  _GaugePainter({required this.score, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;
    const strokeWidth = 14.0;
    const startAngle = 2.4; // radians (~137°)
    const sweepTotal = 2 * pi - (startAngle - pi) * 2;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // Score arc with gradient
    final scoreSweep = sweepTotal * (score / 100).clamp(0.0, 1.0);
    if (scoreSweep > 0) {
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepTotal,
        colors: const [
          Colors.red,
          Colors.orange,
          Colors.amber,
          Colors.lightGreen,
          Colors.green,
        ],
      );
      final scorePaint = Paint()
        ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        scoreSweep,
        false,
        scorePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.score != score || old.backgroundColor != backgroundColor;
}
