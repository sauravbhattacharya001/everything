import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/services/eye_break_service.dart';

/// A 20-20-20 eye break reminder with configurable intervals.
///
/// Counts down a work period, then prompts the user to take a break
/// and look away from the screen for a set duration.
class EyeBreakScreen extends StatefulWidget {
  const EyeBreakScreen({super.key});

  @override
  State<EyeBreakScreen> createState() => _EyeBreakScreenState();
}

class _EyeBreakScreenState extends State<EyeBreakScreen>
    with TickerProviderStateMixin {
  int _workMinutes = EyeBreakService.defaultWorkMinutes;
  int _breakSeconds = EyeBreakService.defaultBreakSeconds;

  /// True when counting down work time, false during break.
  bool _isWorkPhase = true;

  /// Whether the timer is actively counting.
  bool _isRunning = false;

  /// Remaining seconds in the current phase.
  int _remainingSeconds = EyeBreakService.defaultWorkMinutes * 60;

  /// Total completed break cycles in this session.
  int _completedBreaks = 0;

  Timer? _timer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _random = Random();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _isRunning = true);
    if (!_isWorkPhase) {
      _pulseController.repeat(reverse: true);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          if (_isWorkPhase) {
            // Switch to break phase.
            _isWorkPhase = false;
            _remainingSeconds = _breakSeconds;
            _pulseController.repeat(reverse: true);
            _startTimer();
          } else {
            // Break completed.
            _completedBreaks++;
            _isWorkPhase = true;
            _remainingSeconds = _workMinutes * 60;
            _pulseController.stop();
            _pulseController.reset();
            _startTimer();
          }
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isRunning = false;
      _isWorkPhase = true;
      _remainingSeconds = _workMinutes * 60;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _randomTip =>
      EyeBreakService.tips[_random.nextInt(EyeBreakService.tips.length)];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBreak = !_isWorkPhase;
    final phaseColor = isBreak ? Colors.green : theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eye Break Reminder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Phase indicator
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  isBreak ? '👀 Look Away!' : '💻 Work Time',
                  key: ValueKey(isBreak),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: phaseColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (isBreak)
                Text(
                  _randomTip,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 32),

              // Timer display
              ScaleTransition(
                scale: isBreak && _isRunning
                    ? _pulseAnimation
                    : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: phaseColor, width: 4),
                  ),
                  child: Center(
                    child: Text(
                      _formatTime(_remainingSeconds),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? 'Pause' : 'Start'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Breaks taken: $_completedBreaks',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Timer Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text('Work interval (minutes)'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: EyeBreakService.workPresets.map((m) {
                      final selected = m == _workMinutes;
                      return ChoiceChip(
                        label: Text('$m'),
                        selected: selected,
                        onSelected: (_) {
                          setSheetState(() => _workMinutes = m);
                          setState(() {
                            if (_isWorkPhase && !_isRunning) {
                              _remainingSeconds = m * 60;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Break duration (seconds)'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: EyeBreakService.breakPresets.map((s) {
                      final selected = s == _breakSeconds;
                      return ChoiceChip(
                        label: Text('$s'),
                        selected: selected,
                        onSelected: (_) {
                          setSheetState(() => _breakSeconds = s);
                          setState(() {
                            if (!_isWorkPhase && !_isRunning) {
                              _remainingSeconds = s;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
