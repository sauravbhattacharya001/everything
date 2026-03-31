import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/sort_visualizer_service.dart';

/// Interactive Sorting Algorithm Visualizer with animated bar chart,
/// speed control, step-through, and algorithm comparison info.
class SortVisualizerScreen extends StatefulWidget {
  const SortVisualizerScreen({super.key});

  @override
  State<SortVisualizerScreen> createState() => _SortVisualizerScreenState();
}

class _SortVisualizerScreenState extends State<SortVisualizerScreen> {
  final _service = SortVisualizerService();
  SortAlgorithm _algorithm = SortAlgorithm.bubble;
  int _arraySize = 20;
  List<SortStep> _steps = [];
  int _currentStep = 0;
  bool _playing = false;
  Timer? _timer;
  double _speed = 100; // ms per step

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generate() {
    _timer?.cancel();
    final arr = _service.generateArray(_arraySize);
    setState(() {
      _steps = _service.generateSteps(arr, _algorithm);
      _currentStep = 0;
      _playing = false;
    });
  }

  void _play() {
    if (_currentStep >= _steps.length - 1) return;
    setState(() => _playing = true);
    _timer = Timer.periodic(Duration(milliseconds: _speed.toInt()), (t) {
      if (_currentStep >= _steps.length - 1) {
        t.cancel();
        setState(() => _playing = false);
        return;
      }
      setState(() => _currentStep++);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _playing = false);
  }

  void _stepForward() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _stepBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _currentStep = 0;
      _playing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = _steps.isNotEmpty ? _steps[_currentStep] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Sort Visualizer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Algorithm selector & controls
            _buildAlgorithmSelector(theme),
            const SizedBox(height: 8),
            // Algorithm info card
            _buildInfoCard(theme),
            const SizedBox(height: 12),
            // Bar chart visualization
            Expanded(child: step != null ? _buildBars(step, theme) : const SizedBox()),
            const SizedBox(height: 8),
            // Step description
            if (step != null)
              Text(
                step.description,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 4),
            // Progress
            if (_steps.isNotEmpty)
              Text(
                'Step ${_currentStep + 1} / ${_steps.length}',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            // Playback controls
            _buildControls(theme),
            const SizedBox(height: 8),
            // Speed & size sliders
            _buildSliders(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAlgorithmSelector(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SortAlgorithm.values.map((algo) {
          final selected = algo == _algorithm;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(algo.label),
              selected: selected,
              onSelected: (_) {
                _algorithm = algo;
                _generate();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(_algorithm.description, style: theme.textTheme.bodySmall),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Time: ${_algorithm.timeComplexity}',
                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('Space: ${_algorithm.spaceComplexity}',
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBars(SortStep step, ThemeData theme) {
    final maxVal = step.array.reduce((a, b) => a > b ? a : b);
    return LayoutBuilder(builder: (context, constraints) {
      final barWidth = (constraints.maxWidth - (step.array.length - 1) * 2) / step.array.length;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(step.array.length, (i) {
          final height = (step.array[i] / maxVal) * constraints.maxHeight;
          Color color;
          if (step.sorted.contains(i)) {
            color = Colors.green;
          } else if (i == step.comparing1 || i == step.comparing2) {
            color = Colors.red;
          } else {
            color = theme.colorScheme.primary.withValues(alpha: 0.6);
          }
          return Padding(
            padding: EdgeInsets.only(right: i < step.array.length - 1 ? 2 : 0),
            child: AnimatedContainer(
              duration: Duration(milliseconds: (_speed * 0.8).toInt().clamp(30, 200)),
              width: barWidth.clamp(2, 40),
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ),
          );
        }),
      );
    });
  }

  Widget _buildControls(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'New Array',
          onPressed: _generate,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous),
          tooltip: 'Reset',
          onPressed: _reset,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Step Back',
          onPressed: _playing ? null : _stepBack,
        ),
        IconButton(
          icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
          tooltip: _playing ? 'Pause' : 'Play',
          onPressed: _playing ? _pause : _play,
          iconSize: 32,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Step Forward',
          onPressed: _playing ? null : _stepForward,
        ),
      ],
    );
  }

  Widget _buildSliders(ThemeData theme) {
    return Row(
      children: [
        const Icon(Icons.speed, size: 16),
        Expanded(
          child: Slider(
            min: 10,
            max: 500,
            value: _speed,
            divisions: 49,
            label: '${_speed.toInt()} ms',
            onChanged: (v) {
              setState(() => _speed = v);
              if (_playing) {
                _pause();
                _play();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.bar_chart, size: 16),
        Expanded(
          child: Slider(
            min: 5,
            max: 50,
            value: _arraySize.toDouble(),
            divisions: 45,
            label: '$_arraySize bars',
            onChanged: (v) {
              _arraySize = v.toInt();
              _generate();
            },
          ),
        ),
      ],
    );
  }
}
