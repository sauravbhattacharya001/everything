import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/services/pomodoro_service.dart';

/// Pomodoro Timer screen with circular countdown, phase transitions,
/// configurable intervals, and daily statistics.
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin {
  late PomodoroService _service;
  PomodoroSettings _settings = const PomodoroSettings();
  PomodoroPhase _currentPhase = PomodoroPhase.work;
  bool _isRunning = false;
  int _remainingSeconds = 25 * 60;
  int _totalSeconds = 25 * 60;
  Timer? _timer;
  late AnimationController _pulseController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = PomodoroService(settings: _settings);
    _totalSeconds = _settings.workMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _initAsync();
  }

  Future<void> _initAsync() async {
    await _service.init();
    if (mounted) {
      setState(() {
        _currentPhase = _service.nextPhase();
        _totalSeconds = _service.phaseDuration(_currentPhase) * 60;
        _remainingSeconds = _totalSeconds;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Color get _phaseColor {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return Colors.red[400]!;
      case PomodoroPhase.shortBreak:
        return Colors.green[400]!;
      case PomodoroPhase.longBreak:
        return Colors.blue[400]!;
    }
  }

  Color get _bgColor {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return Colors.red[50]!;
      case PomodoroPhase.shortBreak:
        return Colors.green[50]!;
      case PomodoroPhase.longBreak:
        return Colors.blue[50]!;
    }
  }

  String get _phaseLabel {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return 'Focus Time';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
    }
  }

  IconData get _phaseIcon {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return Icons.local_fire_department;
      case PomodoroPhase.shortBreak:
        return Icons.coffee;
      case PomodoroPhase.longBreak:
        return Icons.self_improvement;
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _service.startSession(_currentPhase); // fire-and-forget persistence
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _onTimerComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
    _pulseController.repeat(reverse: true);
    setState(() => _isRunning = true);
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
      _currentPhase = _service.nextPhase();
      _totalSeconds = _service.phaseDuration(_currentPhase) * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    _service.completeCurrentSession();

    final completedPhase = _currentPhase;
    final nextPhase = _service.nextPhase();

    setState(() {
      _isRunning = false;
      _currentPhase = nextPhase;
      _totalSeconds = _service.phaseDuration(nextPhase) * 60;
      _remainingSeconds = _totalSeconds;
    });

    // Show completion notification
    if (mounted) {
      final msg = completedPhase == PomodoroPhase.work
          ? 'Pomodoro complete! Time for a break 🎉'
          : 'Break over! Ready to focus? 💪';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _skipPhase() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    _service.completeCurrentSession();
    final nextPhase = _service.nextPhase();
    setState(() {
      _isRunning = false;
      _currentPhase = nextPhase;
      _totalSeconds = _service.phaseDuration(nextPhase) * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _showSettings() {
    int work = _settings.workMinutes;
    int shortB = _settings.shortBreakMinutes;
    int longB = _settings.longBreakMinutes;
    int interval = _settings.longBreakInterval;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Timer Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _settingRow('Work duration', '$work min', () {
                setModalState(() => work = (work % 60) + 5);
              }, () {
                setModalState(() {
                  if (work > 5) work -= 5;
                });
              }),
              _settingRow('Short break', '$shortB min', () {
                setModalState(() => shortB = (shortB % 30) + 1);
              }, () {
                setModalState(() {
                  if (shortB > 1) shortB -= 1;
                });
              }),
              _settingRow('Long break', '$longB min', () {
                setModalState(() => longB = (longB % 60) + 5);
              }, () {
                setModalState(() {
                  if (longB > 5) longB -= 5;
                });
              }),
              _settingRow('Long break every', '$interval pomodoros', () {
                setModalState(() => interval = (interval % 8) + 1);
              }, () {
                setModalState(() {
                  if (interval > 1) interval -= 1;
                });
              }),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _settings = PomodoroSettings(
                        workMinutes: work,
                        shortBreakMinutes: shortB,
                        longBreakMinutes: longB,
                        longBreakInterval: interval,
                      );
                      _service = PomodoroService(settings: _settings);
                      _resetTimer();
                    });
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _phaseColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingRow(
      String label, String value, VoidCallback onInc, VoidCallback onDec) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500))),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 22),
            onPressed: onDec,
            color: Colors.grey[600],
          ),
          SizedBox(
            width: 100,
            child: Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 22),
            onPressed: onInc,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _service.todayStats();
    final progress =
        _totalSeconds > 0 ? 1.0 - (_remainingSeconds / _totalSeconds) : 0.0;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _phaseColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _isRunning ? null : _showSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Phase indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_phaseIcon, color: _phaseColor, size: 28),
                const SizedBox(width: 8),
                Text(
                  _phaseLabel,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _phaseColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Circular timer
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      color: _phaseColor.withAlpha(40),
                    ),
                  ),
                  // Progress arc
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      color: _phaseColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Time display
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) {
                      final scale = _isRunning
                          ? 1.0 + (_pulseController.value * 0.02)
                          : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w300,
                            color: _phaseColor,
                            letterSpacing: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset
                IconButton(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh, size: 28),
                  color: _phaseColor.withAlpha(180),
                  tooltip: 'Reset',
                ),
                const SizedBox(width: 16),
                // Play/Pause
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ElevatedButton(
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _phaseColor,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 4,
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Skip
                IconButton(
                  onPressed: _skipPhase,
                  icon: const Icon(Icons.skip_next, size: 28),
                  color: _phaseColor.withAlpha(180),
                  tooltip: 'Skip',
                ),
              ],
            ),

            const Spacer(flex: 1),

            // Pomodoro dots (completed count)
            if (stats.completedPomodoros > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    min(stats.completedPomodoros, 12),
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Stats bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem(
                    Icons.local_fire_department,
                    '${stats.completedPomodoros}',
                    'Pomodoros',
                    Colors.red[400]!,
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[200]),
                  _statItem(
                    Icons.timer,
                    '${stats.totalFocusMinutes}m',
                    'Focus',
                    Colors.orange[400]!,
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[200]),
                  _statItem(
                    Icons.bolt,
                    '${stats.currentStreak}',
                    'Streak',
                    Colors.amber[600]!,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}


