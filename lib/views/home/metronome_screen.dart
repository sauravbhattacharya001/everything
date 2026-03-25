import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/metronome_service.dart';

/// A visual metronome with adjustable BPM, tap-tempo, time signatures,
/// preset tempos, and a pendulum animation.
class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen>
    with SingleTickerProviderStateMixin {
  final _service = MetronomeService();
  int _bpm = 120;
  int _beatsPerMeasure = 4;
  int _currentBeat = 0;
  bool _playing = false;
  Timer? _timer;
  late AnimationController _pendulumController;

  @override
  void initState() {
    super.initState();
    _pendulumController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: MetronomeService.msPerBeat(_bpm)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pendulumController.dispose();
    super.dispose();
  }

  void _startStop() {
    setState(() {
      _playing = !_playing;
      if (_playing) {
        _currentBeat = 0;
        _scheduleTick();
      } else {
        _timer?.cancel();
        _pendulumController.stop();
      }
    });
  }

  void _scheduleTick() {
    final ms = MetronomeService.msPerBeat(_bpm);
    _pendulumController.duration = Duration(milliseconds: ms);
    _timer?.cancel();
    _tick(); // immediate first beat
    _timer = Timer.periodic(Duration(milliseconds: ms), (_) => _tick());
  }

  void _tick() {
    if (!mounted || !_playing) return;
    setState(() {
      _currentBeat = (_currentBeat % _beatsPerMeasure) + 1;
    });
    // Haptic feedback: heavy on beat 1, light on others.
    if (_currentBeat == 1) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    // Restart pendulum swing.
    _pendulumController.forward(from: 0);
  }

  void _setBpm(int bpm) {
    setState(() => _bpm = bpm.clamp(20, 300));
    if (_playing) _scheduleTick();
  }

  void _onTapTempo() {
    final detected = _service.tap();
    if (detected != null) _setBpm(detected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronome'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.music_note),
            tooltip: 'Tempo presets',
            onSelected: _setBpm,
            itemBuilder: (_) => MetronomeService.presets.entries
                .map((e) => PopupMenuItem(
                      value: e.value,
                      child: Text('${e.key}  (${e.value} BPM)'),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // ── Pendulum ──
            SizedBox(
              height: 160,
              child: AnimatedBuilder(
                animation: _pendulumController,
                builder: (_, __) {
                  // Swing from -30° to +30°.
                  final angle = (_pendulumController.value - 0.5) * 1.05;
                  return CustomPaint(
                    size: const Size(double.infinity, 160),
                    painter: _PendulumPainter(
                      angle: angle,
                      color: cs.primary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // ── BPM display ──
            Text(
              '$_bpm',
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            Text('BPM', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            // ── Slider ──
            Slider(
              value: _bpm.toDouble(),
              min: 20,
              max: 300,
              divisions: 280,
              label: '$_bpm',
              onChanged: (v) => _setBpm(v.round()),
            ),
            const SizedBox(height: 8),

            // ── Fine-tune buttons ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  icon: const Icon(Icons.remove),
                  onPressed: () => _setBpm(_bpm - 1),
                ),
                const SizedBox(width: 16),
                IconButton.outlined(
                  icon: const Icon(Icons.add),
                  onPressed: () => _setBpm(_bpm + 1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Beat indicator dots ──
            Wrap(
              spacing: 12,
              children: List.generate(_beatsPerMeasure, (i) {
                final beat = i + 1;
                final isActive = _playing && beat == _currentBeat;
                final isFirst = beat == 1;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: isActive ? 28 : 20,
                  height: isActive ? 28 : 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? (isFirst ? cs.error : cs.primary)
                        : cs.surfaceContainerHighest,
                    border: isFirst
                        ? Border.all(color: cs.error, width: 2)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // ── Time signature selector ──
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 2, label: Text('2/4')),
                ButtonSegment(value: 3, label: Text('3/4')),
                ButtonSegment(value: 4, label: Text('4/4')),
                ButtonSegment(value: 6, label: Text('6/8')),
              ],
              selected: {_beatsPerMeasure},
              onSelectionChanged: (s) =>
                  setState(() => _beatsPerMeasure = s.first),
            ),
            const Spacer(),

            // ── Tap Tempo & Play/Stop ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.touch_app),
                    label: const Text('Tap Tempo'),
                    onPressed: _onTapTempo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                    label: Text(_playing ? 'Stop' : 'Start'),
                    onPressed: _startStop,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Paints a simple pendulum arm + bob.
class _PendulumPainter extends CustomPainter {
  final double angle;
  final Color color;

  _PendulumPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, 0);
    final armLength = size.height * 0.85;
    final end = Offset(
      pivot.dx + armLength * _sin(angle),
      pivot.dy + armLength * _cos(angle),
    );

    // Arm.
    final armPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot, end, armPaint);

    // Bob.
    final bobPaint = Paint()..color = color;
    canvas.drawCircle(end, 12, bobPaint);

    // Pivot dot.
    canvas.drawCircle(pivot, 4, Paint()..color = color.withOpacity(0.4));
  }

  double _sin(double v) => v; // small-angle approximation is fine here
  double _cos(double v) => 1.0 - (v * v / 2);

  @override
  bool shouldRepaint(_PendulumPainter old) => old.angle != angle;
}
