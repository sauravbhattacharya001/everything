import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/services/spin_wheel_service.dart';

/// A customizable spin-the-wheel decision maker with animated wheel,
/// presets, history, and frequency stats.
class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  final _service = SpinWheelService();
  final _optionController = TextEditingController();
  SpinResult? _lastResult;
  bool _spinning = false;
  late AnimationController _animController;
  late Animation<double> _rotationAnimation;
  double _currentRotation = 0;

  // Colors for wheel segments
  static const _segmentColors = [
    Color(0xFFE57373), Color(0xFF64B5F6), Color(0xFF81C784),
    Color(0xFFFFD54F), Color(0xFFBA68C8), Color(0xFF4DD0E1),
    Color(0xFFFF8A65), Color(0xFFA1887F), Color(0xFF90A4AE),
    Color(0xFFAED581), Color(0xFFF06292), Color(0xFF7986CB),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_service.options.length < 2 || _spinning) return;
    setState(() => _spinning = true);

    // Random number of full rotations (3-6) + random final position
    final extraRotations = 3 + Random().nextInt(4);
    final targetAngle = _currentRotation + extraRotations * 2 * pi + Random().nextDouble() * 2 * pi;

    _rotationAnimation = Tween<double>(
      begin: _currentRotation,
      end: targetAngle,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward(from: 0).then((_) {
      _currentRotation = targetAngle % (2 * pi);
      final result = _service.spin();
      setState(() {
        _lastResult = result;
        _spinning = false;
      });
    });
  }

  void _addOption() {
    final text = _optionController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _service.addOption(text);
        _optionController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _service.options;
    final freq = _service.getFrequencies();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spin the Wheel'),
        actions: [
          if (_service.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear history',
              onPressed: () => setState(() {
                _service.clearHistory();
                _lastResult = null;
              }),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wheel visualization
            if (options.length >= 2) ...[
              Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _spinning ? _rotationAnimation.value : _currentRotation,
                            child: CustomPaint(
                              size: const Size(240, 240),
                              painter: _WheelPainter(
                                options: options,
                                colors: _segmentColors,
                              ),
                            ),
                          );
                        },
                      ),
                      // Pointer
                      Positioned(
                        top: 0,
                        child: Icon(
                          Icons.arrow_drop_down,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      // Center circle
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surface,
                          border: Border.all(color: theme.colorScheme.outline, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.casino,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Result
            if (_lastResult != null)
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('🎯 Result',
                          style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Text(
                        _lastResult!.option,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Spin button
            ElevatedButton.icon(
              onPressed: options.length < 2 || _spinning ? null : _spin,
              icon: const Icon(Icons.refresh),
              label: Text(options.length < 2
                  ? 'Add at least 2 options'
                  : _spinning
                      ? 'Spinning...'
                      : 'Spin!'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 24),

            // Presets
            Text('Quick Presets', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SpinWheelService.presets.map((preset) =>
                ActionChip(
                  label: Text(preset.name),
                  avatar: const Icon(Icons.auto_awesome, size: 18),
                  onPressed: () => setState(() {
                    _service.loadPreset(preset);
                    _lastResult = null;
                    _currentRotation = 0;
                  }),
                ),
              ).toList(),
            ),
            const SizedBox(height: 24),

            // Add options
            Text('Options (${options.length})', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _optionController,
                    decoration: const InputDecoration(
                      hintText: 'Add an option...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addOption(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (options.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _service.clearOptions();
                      _lastResult = null;
                      _currentRotation = 0;
                    }),
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear all'),
                  ),
                ],
              ),
              ...List.generate(options.length, (i) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: _segmentColors[i % _segmentColors.length],
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(options[i]),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _service.removeOption(i)),
                ),
              )),
            ],
            const SizedBox(height: 24),

            // Frequency stats
            if (freq.isNotEmpty) ...[
              Text('Spin History', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: freq.entries.map((e) {
                      final total = _service.history.length;
                      final pct = (e.value / total * 100).toStringAsFixed(0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(e.key)),
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: e.value / total,
                                  minHeight: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 50,
                              child: Text('${e.value}x ($pct%)',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Total spins: ${_service.history.length}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom painter that draws a segmented wheel.
class _WheelPainter extends CustomPainter {
  final List<String> options;
  final List<Color> colors;

  _WheelPainter({required this.options, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / options.length;

    for (int i = 0; i < options.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      final startAngle = i * segmentAngle - pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw border
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Draw label
      final labelAngle = startAngle + segmentAngle / 2;
      final labelRadius = radius * 0.65;
      final labelX = center.dx + labelRadius * cos(labelAngle);
      final labelY = center.dy + labelRadius * sin(labelAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: options[i].length > 10
              ? '${options[i].substring(0, 8)}..'
              : options[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: radius * 0.5);

      canvas.save();
      canvas.translate(labelX, labelY);
      canvas.rotate(labelAngle + pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) =>
      options != oldDelegate.options;
}
