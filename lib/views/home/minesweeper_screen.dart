import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/minesweeper_service.dart';

/// Classic Minesweeper game.
///
/// Tap to reveal cells, long-press to flag mines. Clear all safe cells
/// to win. Supports beginner, intermediate, and expert difficulties
/// with timer, flag counter, and chord reveal.
class MinesweeperScreen extends StatefulWidget {
  const MinesweeperScreen({super.key});

  @override
  State<MinesweeperScreen> createState() => _MinesweeperScreenState();
}

class _MinesweeperScreenState extends State<MinesweeperScreen> {
  final _service = MinesweeperService();
  Timer? _timer;

  static const _numberColors = <int, Color>{
    1: Colors.blue,
    2: Color(0xFF388E3C),
    3: Colors.red,
    4: Color(0xFF7B1FA2),
    5: Color(0xFF795548),
    6: Color(0xFF00838F),
    7: Colors.black,
    8: Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_service.state == MinesweeperState.playing && !_service.firstClick) {
        setState(() {});
      }
    });
  }

  void _newGame(MinesweeperDifficulty diff) {
    setState(() => _service.newGame(diff));
    _startTimer();
  }

  void _onTap(int r, int c) {
    final cell = _service.grid[r][c];
    if (cell.isRevealed && cell.adjacentMines > 0) {
      setState(() => _service.chordReveal(r, c));
    } else {
      setState(() => _service.reveal(r, c));
    }
    _showEndDialog();
  }

  void _onLongPress(int r, int c) {
    setState(() => _service.toggleFlag(r, c));
  }

  void _showEndDialog() {
    if (_service.state == MinesweeperState.won) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('🎉 You Win!'),
          content: Text(
            'Cleared ${_service.difficulty.label} in ${_service.elapsedSeconds}s',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _newGame(_service.difficulty);
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      );
    } else if (_service.state == MinesweeperState.lost) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('💥 Game Over'),
          content: const Text('You hit a mine!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _newGame(_service.difficulty);
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minesweeper'),
        actions: [
          PopupMenuButton<MinesweeperDifficulty>(
            icon: const Icon(Icons.tune),
            tooltip: 'Difficulty',
            onSelected: _newGame,
            itemBuilder: (_) => MinesweeperDifficulty.values
                .map(
                  (d) => PopupMenuItem(
                    value: d,
                    child: Text(
                      '${d.label} (${d.rows}×${d.cols}, ${d.mines} mines)',
                    ),
                  ),
                )
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Game',
            onPressed: () => _newGame(_service.difficulty),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${_service.remainingFlags}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  _service.difficulty.label,
                  style: theme.textTheme.titleMedium,
                ),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${_service.elapsedSeconds}s',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Grid
          Expanded(
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: _buildGrid(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(ThemeData theme) {
    final rows = _service.rows;
    final cols = _service.cols;
    final cellSize = _calcCellSize();

    return Table(
      defaultColumnWidth: FixedColumnWidth(cellSize),
      border: TableBorder.all(
        color: theme.dividerColor.withAlpha(80),
        width: 0.5,
      ),
      children: List.generate(rows, (r) {
        return TableRow(
          children: List.generate(cols, (c) {
            return _buildCell(r, c, cellSize, theme);
          }),
        );
      }),
    );
  }

  double _calcCellSize() {
    final screen = MediaQuery.of(context).size;
    final maxW = (screen.width - 16) / _service.cols;
    final maxH = (screen.height - 200) / _service.rows;
    return maxW < maxH ? maxW : maxH;
  }

  Widget _buildCell(int r, int c, double size, ThemeData theme) {
    final cell = _service.grid[r][c];
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Widget? content;

    if (!cell.isRevealed) {
      bg = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFBDBDBD);
      if (cell.isFlagged) {
        content = Icon(Icons.flag, color: Colors.red.shade700, size: size * 0.6);
      }
    } else if (cell.hasMine) {
      bg = Colors.red.shade100;
      content = Icon(Icons.brightness_7, color: Colors.black, size: size * 0.6);
    } else {
      bg = isDark ? const Color(0xFF303030) : const Color(0xFFE0E0E0);
      if (cell.adjacentMines > 0) {
        content = Text(
          '${cell.adjacentMines}',
          style: TextStyle(
            color: _numberColors[cell.adjacentMines] ?? Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.5,
          ),
        );
      }
    }

    return GestureDetector(
      onTap: () => _onTap(r, c),
      onLongPress: () => _onLongPress(r, c),
      child: Container(
        width: size,
        height: size,
        color: bg,
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}
