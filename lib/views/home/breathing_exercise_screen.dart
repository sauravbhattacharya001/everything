import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../core/services/breathing_exercise_service.dart';

/// Guided breathing exercise screen with animated circle, multiple patterns,
/// and session history tracking.
class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  final _service = const BreathingExerciseService();
  BreathingPattern _selectedPattern = BreathingPattern.boxBreathing;
  int _targetCycles = 4;
  bool _isRunning = false;
  bool _isPaused = false;

  // Current exercise state
  int _currentCycle = 0;
  int _currentPhaseIndex = 0;
  int _phaseSecondsRemaining = 0;
  BreathPhase _currentPhase = BreathPhase.inhale;
  Timer? _timer;

  // Animation
  late AnimationController _animController;
  late Animation<double> _breathAnimation;

  // Session tracking
  int _totalElapsedSeconds = 0;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _breathAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startExercise() {
    final phases = _service.getActivePhases(_selectedPattern);
    if (phases.isEmpty) return;

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _currentCycle = 1;
      _currentPhaseIndex = 0;
      _currentPhase = phases[0].key;
      _phaseSecondsRemaining = phases[0].value;
      _totalElapsedSeconds = 0;
    });

    _stopwatch.reset();
    _stopwatch.start();
    _updateAnimation();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused) return;

      setState(() {
        _phaseSecondsRemaining--;
        _totalElapsedSeconds++;
      });

      if (_phaseSecondsRemaining <= 0) {
        _advancePhase();
      }
    });
  }

  void _advancePhase() {
    final phases = _service.getActivePhases(_selectedPattern);
    _currentPhaseIndex++;

    if (_currentPhaseIndex >= phases.length) {
      // End of cycle
      _currentPhaseIndex = 0;
      _currentCycle++;

      if (_currentCycle > _targetCycles) {
        _completeExercise();
        return;
      }
    }

    setState(() {
      _currentPhase = phases[_currentPhaseIndex].key;
      _phaseSecondsRemaining = phases[_currentPhaseIndex].value;
    });
    _updateAnimation();
  }

  void _updateAnimation() {
    final phaseDuration = _phaseSecondsRemaining;
    _animController.duration = Duration(seconds: phaseDuration);

    if (_currentPhase == BreathPhase.inhale) {
      _animController.forward(from: 0);
    } else if (_currentPhase == BreathPhase.exhale) {
      _animController.reverse(from: 1);
    } else {
      // Hold — freeze animation at current value
      _animController.stop();
    }
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _stopwatch.stop();
      _animController.stop();
    } else {
      _stopwatch.start();
      _updateAnimation();
    }
  }

  void _stopExercise() {
    _timer?.cancel();
    _stopwatch.stop();
    _animController.stop();
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });
  }

  void _completeExercise() {
    _timer?.cancel();
    _stopwatch.stop();
    _animController.stop();

    final minutes = (_totalElapsedSeconds / 60).ceil();
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 Session Complete!'),
        content: Text(
          '${_selectedPattern.label}\n'
          'Cycles: $_targetCycles\n'
          'Duration: ${minutes}m ${_totalElapsedSeconds % 60}s\n\n'
          'Great job taking time to breathe!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Breathing Exercise')),
      body: _isRunning ? _buildExerciseView(theme) : _buildSetupView(theme),
    );
  }

  Widget _buildSetupView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Icon(Icons.air, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Choose a Breathing Pattern',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Pattern cards
          ...BreathingPattern.values
              .where((p) => p != BreathingPattern.custom)
              .map((pattern) => _patternCard(pattern, theme)),

          const SizedBox(height: 24),

          // Cycle selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Cycles: ', style: TextStyle(fontSize: 16)),
              IconButton(
                onPressed:
                    _targetCycles > 1 ? () => setState(() => _targetCycles--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$_targetCycles',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _targetCycles < 20
                    ? () => setState(() => _targetCycles++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ~${(_service.cycleDurationSeconds(_selectedPattern) * _targetCycles / 60).toStringAsFixed(1)} minutes',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),

          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _startExercise,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _patternCard(BreathingPattern pattern, ThemeData theme) {
    final isSelected = pattern == _selectedPattern;
    final phases = pattern.defaultPhases;
    final phaseStr =
        '${phases[0]}s in${phases[1] > 0 ? ' · ${phases[1]}s hold' : ''}'
        ' · ${phases[2]}s out${phases[3] > 0 ? ' · ${phases[3]}s hold' : ''}';

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedPattern = pattern),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(pattern.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(phaseStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 2),
                    Text(pattern.description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseView(ThemeData theme) {
    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cycle $_currentCycle / $_targetCycles',
                  style: theme.textTheme.titleMedium),
              Text(
                '${_selectedPattern.emoji} ${_selectedPattern.label}',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),

        // Animated breathing circle
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: _breathAnimation,
              builder: (context, child) {
                final size = 120 + (_breathAnimation.value * 100);
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _phaseColor().withOpacity(0.3),
                    border: Border.all(
                      color: _phaseColor(),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _phaseColor().withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPhase.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentPhase.label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_phaseSecondsRemaining',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: _togglePause,
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(_isPaused ? 'Resume' : 'Pause'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _stopExercise,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _phaseColor() {
    switch (_currentPhase) {
      case BreathPhase.inhale:
        return Colors.blue;
      case BreathPhase.holdIn:
        return Colors.indigo;
      case BreathPhase.exhale:
        return Colors.teal;
      case BreathPhase.holdOut:
        return Colors.blueGrey;
    }
  }
}

/// [AnimatedBuilder] is a typo-safe alias; Flutter's built-in is AnimatedBuilder.
/// Using the correct name:
// Note: AnimatedBuilder IS the correct Flutter class name.
