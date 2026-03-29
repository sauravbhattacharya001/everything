import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/game_of_life_service.dart';

/// Conway's Game of Life interactive cellular automaton simulator.
class GameOfLifeScreen extends StatefulWidget {
  const GameOfLifeScreen({super.key});

  @override
  State<GameOfLifeScreen> createState() => _GameOfLifeScreenState();
}

class _GameOfLifeScreenState extends State<GameOfLifeScreen> {
  late GameOfLifeService _service;
  Timer? _timer;
  bool _running = false;
  int _speedMs = 200;

  @override
  void initState() {
    super.initState();
    _service = GameOfLifeService(rows: 40, cols: 30);
    _service.randomize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleRunning() {
    setState(() {
      _running = !_running;
      if (_running) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _speedMs), (_) {
      final changed = _service.step();
      setState(() {});
      if (!changed) {
        _timer?.cancel();
        setState(() => _running = false);
      }
    });
  }

  void _step() {
    _service.step();
    setState(() {});
  }

  void _clear() {
    _timer?.cancel();
    _service.clear();
    setState(() => _running = false);
  }

  void _randomize() {
    _timer?.cancel();
    _service.randomize();
    setState(() => _running = false);
  }

  void _loadPreset(String name) {
    _timer?.cancel();
    _service.clear();
    final midR = _service.rows ~/ 2;
    final midC = _service.cols ~/ 2;
    switch (name) {
      case 'glider':
        _service.loadGlider(midR - 1, midC - 1);
        break;
      case 'blinker':
        _service.loadBlinker(midR, midC - 1);
        break;
      case 'pulsar':
        _service.loadPulsar(midR - 6, midC - 6);
        break;
      case 'gun':
        _service.loadGliderGun(2, 2);
        break;
    }
    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grid = _service.grid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game of Life'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.pattern),
            tooltip: 'Load Preset',
            onSelected: _loadPreset,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'glider', child: Text('Glider')),
              PopupMenuItem(value: 'blinker', child: Text('Blinker')),
              PopupMenuItem(value: 'pulsar', child: Text('Pulsar')),
              PopupMenuItem(value: 'gun', child: Text('Gosper Glider Gun')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                  icon: Icons.replay,
                  label: 'Gen',
                  value: '${_service.generation}',
                ),
                _StatChip(
                  icon: Icons.circle,
                  label: 'Alive',
                  value: '${_service.liveCellCount}',
                ),
                _StatChip(
                  icon: Icons.speed,
                  label: 'Speed',
                  value: '${_speedMs}ms',
                ),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellW = constraints.maxWidth / _service.cols;
                final cellH = constraints.maxHeight / _service.rows;
                final cellSize = cellW < cellH ? cellW : cellH;

                return GestureDetector(
                  onTapUp: (details) {
                    final col =
                        (details.localPosition.dx / cellSize).floor();
                    final row =
                        (details.localPosition.dy / cellSize).floor();
                    if (row >= 0 &&
                        row < _service.rows &&
                        col >= 0 &&
                        col < _service.cols) {
                      _service.toggleCell(row, col);
                      setState(() {});
                    }
                  },
                  child: CustomPaint(
                    size: Size(
                      cellSize * _service.cols,
                      cellSize * _service.rows,
                    ),
                    painter: _GridPainter(
                      grid: grid,
                      cellSize: cellSize,
                      aliveColor: theme.colorScheme.primary,
                      deadColor: theme.colorScheme.surfaceContainerLow,
                      gridLineColor:
                          theme.colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                );
              },
            ),
          ),

          // Speed slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.speed, size: 18),
                Expanded(
                  child: Slider(
                    value: _speedMs.toDouble(),
                    min: 50,
                    max: 1000,
                    divisions: 19,
                    label: '${_speedMs}ms',
                    onChanged: (v) {
                      setState(() => _speedMs = v.round());
                      if (_running) _startTimer();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton.icon(
                  onPressed: _toggleRunning,
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(_running ? 'Pause' : 'Play'),
                ),
                OutlinedButton.icon(
                  onPressed: _running ? null : _step,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Step'),
                ),
                OutlinedButton.icon(
                  onPressed: _randomize,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Random'),
                ),
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text('$label: ', style: theme.textTheme.labelSmall),
        Text(value,
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final List<List<bool>> grid;
  final double cellSize;
  final Color aliveColor;
  final Color deadColor;
  final Color gridLineColor;

  _GridPainter({
    required this.grid,
    required this.cellSize,
    required this.aliveColor,
    required this.deadColor,
    required this.gridLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final alivePaint = Paint()..color = aliveColor;
    final deadPaint = Paint()..color = deadColor;
    final linePaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 0.5;

    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        final rect = Rect.fromLTWH(
          c * cellSize,
          r * cellSize,
          cellSize,
          cellSize,
        );
        canvas.drawRect(rect, grid[r][c] ? alivePaint : deadPaint);
        canvas.drawRect(rect, linePaint..style = PaintingStyle.stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => true;
}
