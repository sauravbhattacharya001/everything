import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/tetris_game_service.dart';

/// Classic Tetris game.
///
/// Use swipe gestures or arrow keys to move pieces. Tap to rotate.
/// Clear lines to score points. Speed increases with each level.
class TetrisGameScreen extends StatefulWidget {
  const TetrisGameScreen({super.key});

  @override
  State<TetrisGameScreen> createState() => _TetrisGameScreenState();
}

class _TetrisGameScreenState extends State<TetrisGameScreen> {
  final _service = TetrisGameService();
  Timer? _timer;
  final _focusNode = FocusNode();

  static const _pieceColors = <Color>[
    Color(0xFF00BCD4), // I - cyan
    Color(0xFFFFEB3B), // O - yellow
    Color(0xFF9C27B0), // T - purple
    Color(0xFF4CAF50), // S - green
    Color(0xFFF44336), // Z - red
    Color(0xFF2196F3), // J - blue
    Color(0xFFFF9800), // L - orange
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startGame() {
    _service.newGame();
    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: _service.tickDuration),
      (_) => _tick(),
    );
  }

  void _tick() {
    final alive = _service.tick();
    setState(() {});
    if (!alive) {
      _timer?.cancel();
      _showGameOverDialog();
    } else {
      // Adjust speed for level changes
      final newDuration = _service.tickDuration;
      _timer?.cancel();
      _timer = Timer.periodic(
        Duration(milliseconds: newDuration),
        (_) => _tick(),
      );
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Game Over'),
        content: Text(
          'Score: ${_service.score}\n'
          'Level: ${_service.level}\n'
          'Lines: ${_service.linesCleared}\n'
          'High Score: ${_service.highScore}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    if (!_service.isPlaying || _service.isGameOver) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _service.moveLeft();
      case LogicalKeyboardKey.arrowRight:
        _service.moveRight();
      case LogicalKeyboardKey.arrowUp:
        _service.rotate();
      case LogicalKeyboardKey.arrowDown:
        _service.softDrop();
      case LogicalKeyboardKey.space:
        _service.hardDrop();
      default:
        return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tetris')),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: _service.isPlaying
                    ? _buildGameView(constraints)
                    : _buildStartView(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStartView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.grid_view_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text('Tetris', style: Theme.of(context).textTheme.headlineLarge),
        if (_service.highScore > 0) ...[
          const SizedBox(height: 8),
          Text('High Score: ${_service.highScore}',
              style: Theme.of(context).textTheme.titleMedium),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _startGame,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Play'),
        ),
        const SizedBox(height: 16),
        Text('← → Move  ↑ Rotate  ↓ Soft Drop  Space Hard Drop',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildGameView(BoxConstraints constraints) {
    final maxBoardHeight = constraints.maxHeight - 60; // leave room for score
    final cellSize = (maxBoardHeight / TetrisGameService.rows)
        .clamp(12.0, 28.0);
    final boardWidth = cellSize * TetrisGameService.columns;
    final nextBoxSize = cellSize * 5;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Score bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statChip('Score', '${_service.score}'),
              _statChip('Level', '${_service.level}'),
              _statChip('Lines', '${_service.linesCleared}'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Board + Next piece
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Board
            GestureDetector(
              onHorizontalDragEnd: (d) {
                if (!_service.isPlaying) return;
                if ((d.primaryVelocity ?? 0) < 0) {
                  _service.moveLeft();
                } else {
                  _service.moveRight();
                }
                setState(() {});
              },
              onVerticalDragEnd: (d) {
                if (!_service.isPlaying) return;
                if ((d.primaryVelocity ?? 0) > 0) {
                  _service.hardDrop();
                }
                setState(() {});
              },
              onTap: () {
                if (!_service.isPlaying) return;
                _service.rotate();
                setState(() {});
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SizedBox(
                  width: boardWidth,
                  height: cellSize * TetrisGameService.rows,
                  child: CustomPaint(
                    painter: _TetrisBoardPainter(
                      board: _service.board,
                      current: _service.current,
                      ghostCells: _service.ghostCells,
                      cellSize: cellSize,
                      colors: _pieceColors,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Next piece + controls
            Column(
              children: [
                Text('Next', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                Container(
                  width: nextBoxSize,
                  height: nextBoxSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _service.nextPiece != null
                      ? CustomPaint(
                          painter: _NextPiecePainter(
                            piece: _service.nextPiece!,
                            cellSize: cellSize,
                            colors: _pieceColors,
                            isDark: Theme.of(context).brightness == Brightness.dark,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                // Touch controls
                _controlButton(Icons.rotate_right, () {
                  _service.rotate();
                  setState(() {});
                }),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _controlButton(Icons.arrow_left, () {
                      _service.moveLeft();
                      setState(() {});
                    }),
                    const SizedBox(width: 4),
                    _controlButton(Icons.arrow_drop_down, () {
                      _service.softDrop();
                      setState(() {});
                    }),
                    const SizedBox(width: 4),
                    _controlButton(Icons.arrow_right, () {
                      _service.moveRight();
                      setState(() {});
                    }),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: nextBoxSize,
                  child: FilledButton.tonal(
                    onPressed: () {
                      _service.hardDrop();
                      setState(() {});
                    },
                    child: const Text('Drop'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

class _TetrisBoardPainter extends CustomPainter {
  final List<List<int>> board;
  final Tetromino? current;
  final List<TetrisPoint>? ghostCells;
  final double cellSize;
  final List<Color> colors;
  final bool isDark;

  _TetrisBoardPainter({
    required this.board,
    required this.current,
    required this.ghostCells,
    required this.cellSize,
    required this.colors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.05)
      ..strokeWidth = 0.5;
    for (int x = 0; x <= TetrisGameService.columns; x++) {
      canvas.drawLine(Offset(x * cellSize, 0), Offset(x * cellSize, size.height), gridPaint);
    }
    for (int y = 0; y <= TetrisGameService.rows; y++) {
      canvas.drawLine(Offset(0, y * cellSize), Offset(size.width, y * cellSize), gridPaint);
    }

    // Locked cells
    for (int y = 0; y < TetrisGameService.rows; y++) {
      for (int x = 0; x < TetrisGameService.columns; x++) {
        if (board[y][x] != -1) {
          _drawCell(canvas, x, y, colors[board[y][x]], 1.0);
        }
      }
    }

    // Ghost cells
    if (ghostCells != null) {
      for (final cell in ghostCells!) {
        if (cell.y >= 0) {
          _drawCell(canvas, cell.x, cell.y,
              colors[tetrominoColorIndex(current!.type)], 0.2);
        }
      }
    }

    // Current piece
    if (current != null) {
      final color = colors[tetrominoColorIndex(current!.type)];
      for (final cell in current!.cells) {
        if (cell.y >= 0) {
          _drawCell(canvas, cell.x, cell.y, color, 1.0);
        }
      }
    }
  }

  void _drawCell(Canvas canvas, int x, int y, Color color, double opacity) {
    final rect = Rect.fromLTWH(
      x * cellSize + 1,
      y * cellSize + 1,
      cellSize - 2,
      cellSize - 2,
    );
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);

    if (opacity >= 1.0) {
      // Highlight edge
      final highlight = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * cellSize + 1.5, y * cellSize + 1.5, cellSize - 3, cellSize - 3),
          const Radius.circular(2),
        ),
        highlight,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TetrisBoardPainter old) => true;
}

class _NextPiecePainter extends CustomPainter {
  final Tetromino piece;
  final double cellSize;
  final List<Color> colors;
  final bool isDark;

  _NextPiecePainter({
    required this.piece,
    required this.cellSize,
    required this.colors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Center the preview piece
    final previewPiece = Tetromino(
      type: piece.type,
      rotation: 0,
      position: const TetrisPoint(0, 0),
    );
    final cells = previewPiece.cells;
    final minX = cells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final maxX = cells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final minY = cells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxY = cells.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    final pieceW = (maxX - minX + 1) * cellSize;
    final pieceH = (maxY - minY + 1) * cellSize;
    final offsetX = (size.width - pieceW) / 2 - minX * cellSize;
    final offsetY = (size.height - pieceH) / 2 - minY * cellSize;

    final color = colors[tetrominoColorIndex(piece.type)];
    for (final cell in cells) {
      final rect = Rect.fromLTWH(
        offsetX + cell.x * cellSize + 1,
        offsetY + cell.y * cellSize + 1,
        cellSize - 2,
        cellSize - 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NextPiecePainter old) => true;
}
