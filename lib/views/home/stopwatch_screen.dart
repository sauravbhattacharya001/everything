import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/stopwatch_service.dart';

/// Stopwatch with lap tracking, split times, statistics, and export.
class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  final List<LapRecord> _laps = [];

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startStop() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _ticker?.cancel();
    } else {
      _stopwatch.start();
      _ticker = Timer.periodic(const Duration(milliseconds: 30), (_) {
        setState(() => _elapsed = _stopwatch.elapsed);
      });
    }
    setState(() {});
  }

  void _lap() {
    if (!_stopwatch.isRunning) return;
    final splitTime = _stopwatch.elapsed;
    final prevSplit = _laps.isEmpty
        ? Duration.zero
        : _laps.first.splitTime;
    _laps.insert(
      0,
      LapRecord(
        number: _laps.length + 1,
        splitTime: splitTime,
        lapTime: splitTime - prevSplit,
      ),
    );
    setState(() {});
  }

  void _reset() {
    _stopwatch.stop();
    _stopwatch.reset();
    _ticker?.cancel();
    setState(() {
      _elapsed = Duration.zero;
      _laps.clear();
    });
  }

  void _copyLaps() {
    if (_laps.isEmpty) return;
    final buffer = StringBuffer('Stopwatch Laps\n');
    buffer.writeln('${'Lap'.padRight(6)}${'Lap Time'.padRight(16)}Split Time');
    buffer.writeln('-' * 40);
    for (final lap in _laps.reversed) {
      buffer.writeln(
        '${('#${lap.number}').padRight(6)}'
        '${StopwatchService.formatDuration(lap.lapTime).padRight(16)}'
        '${StopwatchService.formatDuration(lap.splitTime)}',
      );
    }
    final stats = StopwatchService.calculateStats(
      _laps.map((l) => l.lapTime).toList(),
    );
    if (stats != null) {
      buffer.writeln();
      buffer.writeln('Fastest: ${StopwatchService.formatDuration(stats.fastest)}');
      buffer.writeln('Slowest: ${StopwatchService.formatDuration(stats.slowest)}');
      buffer.writeln('Average: ${StopwatchService.formatDuration(stats.average)}');
      buffer.writeln('Total:   ${StopwatchService.formatDuration(stats.total)}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laps copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = _stopwatch.isRunning;
    final hasStarted = _elapsed > Duration.zero;
    final lapTimes = _laps.map((l) => l.lapTime).toList();
    final stats = StopwatchService.calculateStats(lapTimes);

    // Find fastest/slowest for highlighting
    Duration? fastest, slowest;
    if (_laps.length >= 2) {
      fastest = stats?.fastest;
      slowest = stats?.slowest;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stopwatch'),
        actions: [
          if (_laps.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: 'Copy laps',
              onPressed: _copyLaps,
            ),
        ],
      ),
      body: Column(
        children: [
          // Timer display
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              StopwatchService.formatDuration(_elapsed),
              style: theme.textTheme.displayLarge?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
                fontSize: 56,
                color: isRunning
                    ? theme.colorScheme.primary
                    : theme.textTheme.displayLarge?.color,
              ),
            ),
          ),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset / Lap
              SizedBox(
                width: 80,
                height: 80,
                child: ElevatedButton(
                  onPressed: hasStarted
                      ? (isRunning ? _lap : _reset)
                      : null,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                  ),
                  child: Text(
                    isRunning ? 'Lap' : (hasStarted ? 'Reset' : 'Lap'),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Start / Stop
              SizedBox(
                width: 80,
                height: 80,
                child: ElevatedButton(
                  onPressed: _startStop,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor:
                        isRunning ? Colors.red[400] : Colors.green[400],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isRunning ? 'Stop' : (hasStarted ? 'Resume' : 'Start'),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats bar
          if (stats != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCol('Fastest', StopwatchService.formatDuration(stats.fastest), Colors.green),
                  _statCol('Average', StopwatchService.formatDuration(stats.average), null),
                  _statCol('Slowest', StopwatchService.formatDuration(stats.slowest), Colors.red),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Laps list
          Expanded(
            child: _laps.isEmpty
                ? Center(
                    child: Text(
                      isRunning
                          ? 'Tap Lap to record split times'
                          : 'Press Start to begin',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _laps.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final lap = _laps[index];
                      Color? lapColor;
                      IconData? lapIcon;
                      if (_laps.length >= 2) {
                        if (lap.lapTime == fastest) {
                          lapColor = Colors.green;
                          lapIcon = Icons.bolt;
                        } else if (lap.lapTime == slowest) {
                          lapColor = Colors.red;
                          lapIcon = Icons.slow_motion_video;
                        }
                      }
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (lapIcon != null)
                              Icon(lapIcon, size: 16, color: lapColor),
                            if (lapIcon != null) const SizedBox(width: 4),
                            Text(
                              'Lap ${lap.number}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: lapColor,
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          StopwatchService.formatDuration(lap.lapTime),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                            color: lapColor,
                          ),
                        ),
                        trailing: Text(
                          StopwatchService.formatDuration(lap.splitTime),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, Color? color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }
}
