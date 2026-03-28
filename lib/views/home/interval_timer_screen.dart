import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/interval_timer_service.dart';

/// Interval timer with configurable work/rest periods, rounds, and presets.
class IntervalTimerScreen extends StatefulWidget {
  const IntervalTimerScreen({super.key});

  @override
  State<IntervalTimerScreen> createState() => _IntervalTimerScreenState();
}

class _IntervalTimerScreenState extends State<IntervalTimerScreen> {
  // Configuration
  int _workSeconds = 30;
  int _restSeconds = 15;
  int _rounds = 8;
  int _warmupSeconds = 10;
  int _cooldownSeconds = 0;

  // Timer state
  IntervalPhase _phase = IntervalPhase.idle;
  int _currentRound = 0;
  int _secondsLeft = 0;
  Timer? _timer;
  int _totalElapsed = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_phase != IntervalPhase.idle && _phase != IntervalPhase.complete) return;
    _totalElapsed = 0;
    _currentRound = 0;
    if (_warmupSeconds > 0) {
      _phase = IntervalPhase.warmup;
      _secondsLeft = _warmupSeconds;
    } else {
      _currentRound = 1;
      _phase = IntervalPhase.work;
      _secondsLeft = _workSeconds;
    }
    _startTicker();
    setState(() {});
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _totalElapsed++;
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _advancePhase();
        }
      });
    });
  }

  void _advancePhase() {
    HapticFeedback.mediumImpact();
    switch (_phase) {
      case IntervalPhase.warmup:
        _currentRound = 1;
        _phase = IntervalPhase.work;
        _secondsLeft = _workSeconds;
        break;
      case IntervalPhase.work:
        if (_currentRound >= _rounds) {
          if (_cooldownSeconds > 0) {
            _phase = IntervalPhase.cooldown;
            _secondsLeft = _cooldownSeconds;
          } else {
            _complete();
          }
        } else {
          _phase = IntervalPhase.rest;
          _secondsLeft = _restSeconds;
        }
        break;
      case IntervalPhase.rest:
        _currentRound++;
        _phase = IntervalPhase.work;
        _secondsLeft = _workSeconds;
        break;
      case IntervalPhase.cooldown:
        _complete();
        break;
      default:
        break;
    }
  }

  void _complete() {
    _timer?.cancel();
    _phase = IntervalPhase.complete;
    HapticFeedback.heavyImpact();
  }

  void _pause() {
    _timer?.cancel();
    setState(() {});
  }

  void _resume() {
    _startTicker();
    setState(() {});
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _phase = IntervalPhase.idle;
      _currentRound = 0;
      _secondsLeft = 0;
      _totalElapsed = 0;
    });
  }

  bool get _isRunning => _timer?.isActive ?? false;

  Color _phaseColor() {
    switch (_phase) {
      case IntervalPhase.work:
        return Colors.red[400]!;
      case IntervalPhase.rest:
        return Colors.green[400]!;
      case IntervalPhase.warmup:
        return Colors.orange[400]!;
      case IntervalPhase.cooldown:
        return Colors.blue[400]!;
      case IntervalPhase.complete:
        return Colors.purple[400]!;
      default:
        return Colors.grey;
    }
  }

  String _phaseLabel() {
    switch (_phase) {
      case IntervalPhase.idle:
        return 'Ready';
      case IntervalPhase.warmup:
        return 'Warm Up';
      case IntervalPhase.work:
        return 'WORK';
      case IntervalPhase.rest:
        return 'Rest';
      case IntervalPhase.cooldown:
        return 'Cool Down';
      case IntervalPhase.complete:
        return 'Done!';
    }
  }

  void _applyPreset(IntervalPreset preset) {
    if (_phase != IntervalPhase.idle && _phase != IntervalPhase.complete) return;
    setState(() {
      _workSeconds = preset.workSeconds;
      _restSeconds = preset.restSeconds;
      _rounds = preset.rounds;
      _warmupSeconds = preset.warmupSeconds;
      _cooldownSeconds = preset.cooldownSeconds;
      _phase = IntervalPhase.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = _phase != IntervalPhase.idle &&
        _phase != IntervalPhase.complete;
    final totalDur = IntervalTimerService.totalDuration(
      workSeconds: _workSeconds,
      restSeconds: _restSeconds,
      rounds: _rounds,
      warmupSeconds: _warmupSeconds,
      cooldownSeconds: _cooldownSeconds,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Interval Timer')),
      body: Column(
        children: [
          // Phase display
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48),
            color: _phaseColor().withAlpha(isActive ? 40 : 15),
            child: Column(
              children: [
                Text(
                  _phaseLabel(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: _phaseColor(),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isActive
                      ? IntervalTimerService.formatSeconds(_secondsLeft)
                      : IntervalTimerService.formatSeconds(totalDur),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w300,
                    fontSize: 72,
                    color: isActive ? _phaseColor() : null,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Round $_currentRound / $_rounds',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Elapsed: ${IntervalTimerService.formatSeconds(_totalElapsed)}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
                if (_phase == IntervalPhase.complete) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[400], size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '$_rounds rounds in ${IntervalTimerService.formatSeconds(_totalElapsed)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isActive) ...[
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: ElevatedButton(
                      onPressed: _reset,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('Reset', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: ElevatedButton(
                      onPressed: _isRunning ? _pause : _resume,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor:
                            _isRunning ? Colors.orange[400] : Colors.green[400],
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _isRunning ? 'Pause' : 'Go',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: _start,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.green[400],
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _phase == IntervalPhase.complete ? 'Again' : 'Start',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Config / Presets (only when idle)
          if (!isActive)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Settings
                  Text('Settings', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _settingRow('Work', _workSeconds, (v) => setState(() => _workSeconds = v)),
                  _settingRow('Rest', _restSeconds, (v) => setState(() => _restSeconds = v)),
                  _settingRow('Warmup', _warmupSeconds, (v) => setState(() => _warmupSeconds = v)),
                  _settingRow('Cooldown', _cooldownSeconds, (v) => setState(() => _cooldownSeconds = v)),
                  _roundsRow(),
                  const SizedBox(height: 20),
                  // Presets
                  Text('Presets', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...IntervalPresets.builtIn.map(
                    (p) => Card(
                      child: ListTile(
                        title: Text(p.name),
                        subtitle: Text(IntervalTimerService.presetSummary(
                          workSeconds: p.workSeconds,
                          restSeconds: p.restSeconds,
                          rounds: p.rounds,
                        )),
                        trailing: const Icon(Icons.play_circle_outline),
                        onTap: () => _applyPreset(p),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _settingRow(String label, int seconds, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: seconds > 0
                ? () => onChanged((seconds - 5).clamp(0, 600))
                : null,
          ),
          SizedBox(
            width: 60,
            child: Text(
              IntervalTimerService.formatSeconds(seconds),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: seconds < 600
                ? () => onChanged((seconds + 5).clamp(0, 600))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _roundsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 80,
            child: Text('Rounds', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: _rounds > 1
                ? () => setState(() => _rounds--)
                : null,
          ),
          SizedBox(
            width: 60,
            child: Text(
              '$_rounds',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: _rounds < 99
                ? () => setState(() => _rounds++)
                : null,
          ),
        ],
      ),
    );
  }
}
