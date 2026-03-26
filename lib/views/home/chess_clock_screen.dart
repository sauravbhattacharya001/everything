import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/chess_clock_service.dart';

/// A chess clock with two timers, increment support, and preset time controls.
/// Tap each player's half of the screen to switch turns. Designed for
/// over-the-board play with the phone laid flat between players.
class ChessClockScreen extends StatefulWidget {
  const ChessClockScreen({super.key});

  @override
  State<ChessClockScreen> createState() => _ChessClockScreenState();
}

enum _ClockState { idle, running, paused, finished }

class _ChessClockScreenState extends State<ChessClockScreen> {
  TimeControl _timeControl = ChessClockService.presets[4]; // 5+0 default
  late Duration _player1Time;
  late Duration _player2Time;
  int _player1Moves = 0;
  int _player2Moves = 0;
  int _activePlayer = 0; // 0 = none, 1 or 2
  _ClockState _state = _ClockState.idle;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetClocks();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetClocks() {
    _timer?.cancel();
    setState(() {
      _player1Time = _timeControl.initialDuration;
      _player2Time = _timeControl.initialDuration;
      _player1Moves = 0;
      _player2Moves = 0;
      _activePlayer = 0;
      _state = _ClockState.idle;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        if (_activePlayer == 1) {
          _player1Time -= const Duration(milliseconds: 100);
          if (_player1Time <= Duration.zero) {
            _player1Time = Duration.zero;
            _state = _ClockState.finished;
            _timer?.cancel();
            HapticFeedback.heavyImpact();
          }
        } else if (_activePlayer == 2) {
          _player2Time -= const Duration(milliseconds: 100);
          if (_player2Time <= Duration.zero) {
            _player2Time = Duration.zero;
            _state = _ClockState.finished;
            _timer?.cancel();
            HapticFeedback.heavyImpact();
          }
        }
      });
    });
  }

  void _onPlayerTap(int player) {
    if (_state == _ClockState.finished) return;

    if (_state == _ClockState.idle) {
      // First tap starts the game — the tapping player ends their "turn"
      setState(() {
        _activePlayer = player == 1 ? 2 : 1;
        _state = _ClockState.running;
      });
      HapticFeedback.lightImpact();
      _startTimer();
      return;
    }

    if (_state == _ClockState.paused) return;

    // Only the active player can tap to switch
    if (_activePlayer != player) return;

    HapticFeedback.lightImpact();
    setState(() {
      // Add increment
      if (player == 1) {
        _player1Time += Duration(seconds: _timeControl.increment);
        _player1Moves++;
        _activePlayer = 2;
      } else {
        _player2Time += Duration(seconds: _timeControl.increment);
        _player2Moves++;
        _activePlayer = 1;
      }
    });
    _startTimer();
  }

  void _togglePause() {
    if (_state == _ClockState.idle || _state == _ClockState.finished) return;
    setState(() {
      if (_state == _ClockState.running) {
        _timer?.cancel();
        _state = _ClockState.paused;
      } else {
        _state = _ClockState.running;
        _startTimer();
      }
    });
  }

  Color _playerColor(int player, ThemeData theme) {
    if (_state == _ClockState.finished) {
      final lost = (player == 1 && _player1Time <= Duration.zero) ||
          (player == 2 && _player2Time <= Duration.zero);
      return lost ? Colors.red.shade700 : Colors.green.shade700;
    }
    if (_activePlayer == player) return theme.colorScheme.primary;
    return theme.colorScheme.surfaceContainerHighest;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Clock'),
        actions: [
          if (_state != _ClockState.idle)
            IconButton(
              icon: Icon(_state == _ClockState.paused
                  ? Icons.play_arrow
                  : Icons.pause),
              onPressed: _togglePause,
              tooltip: _state == _ClockState.paused ? 'Resume' : 'Pause',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetClocks,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Column(
        children: [
          // Player 2 (top, rotated 180° so it reads correctly from other side)
          Expanded(
            child: RotatedBox(
              quarterTurns: 2,
              child: _buildPlayerButton(2, theme),
            ),
          ),
          // Control bar in the middle
          _buildControlBar(theme),
          // Player 1 (bottom)
          Expanded(
            child: _buildPlayerButton(1, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerButton(int player, ThemeData theme) {
    final time = player == 1 ? _player1Time : _player2Time;
    final moves = player == 1 ? _player1Moves : _player2Moves;
    final isActive = _activePlayer == player && _state == _ClockState.running;
    final color = _playerColor(player, theme);

    return GestureDetector(
      onTap: () => _onPlayerTap(player),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: color,
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ChessClockService.formatTime(time),
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isActive ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Moves: $moves',
                style: TextStyle(
                  fontSize: 16,
                  color: isActive
                      ? Colors.white70
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_state == _ClockState.idle || _state == _ClockState.finished)
            DropdownButton<TimeControl>(
              value: _timeControl,
              onChanged: (tc) {
                if (tc != null) {
                  setState(() => _timeControl = tc);
                  _resetClocks();
                }
              },
              items: ChessClockService.presets
                  .map((tc) => DropdownMenuItem(
                        value: tc,
                        child: Text(tc.name, style: const TextStyle(fontSize: 14)),
                      ))
                  .toList(),
            )
          else
            Text(
              _timeControl.name,
              style: theme.textTheme.titleMedium,
            ),
        ],
      ),
    );
  }
}
