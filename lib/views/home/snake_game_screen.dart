import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/snake_game_service.dart';

/// Classic Snake game.
///
/// Use swipe gestures or arrow keys to control the snake. Eat food to
/// grow and score points. The snake speeds up as your score increases.
class SnakeGameScreen extends StatefulWidget {
  const SnakeGameScreen({super.key});

  @override
  State<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends State<SnakeGameScreen> {
  final _service = SnakeGameService();
  Timer? _timer;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startGame() {
    _service.newGame();
    _service.isPlaying = true;
    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: _service.tickDuration),
      (_) {
        final alive = _service.tick();
        setState(() {});
        if (!alive) {
          _timer?.cancel();
          _showGameOverDialog();
        } else {
          // Adjust speed dynamically
          if (_timer != null) {
            final newDuration = _service.tickDuration;
            if (_timer!.tick > 0) {
              _timer?.cancel();
              _timer = Timer.periodic(
                Duration(milliseconds: newDuration),
                (_) {
                  final alive = _service.tick();
                  setState(() {});
                  if (!alive) {
                    _timer?.cancel();
                    _showGameOverDialog();
                  }
                },
              );
            }
          }
        }
      },
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Game Over 🐍'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: ${_service.score}',
                style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text('High Score: ${_service.highScore}',
                style: TextStyle(
                    fontSize: 16, color: Colors.grey[600])),
          ],
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
    if (event is! KeyDownEvent) return;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _service.setDirection(SnakeDirection.up);
        break;
      case LogicalKeyboardKey.arrowDown:
        _service.setDirection(SnakeDirection.down);
        break;
      case LogicalKeyboardKey.arrowLeft:
        _service.setDirection(SnakeDirection.left);
        break;
      case LogicalKeyboardKey.arrowRight:
        _service.setDirection(SnakeDirection.right);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snake'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Score: ${_service.score}  |  Best: ${_service.highScore}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < 0) {
              _service.setDirection(SnakeDirection.up);
            } else {
              _service.setDirection(SnakeDirection.down);
            }
          },
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < 0) {
              _service.setDirection(SnakeDirection.left);
            } else {
              _service.setDirection(SnakeDirection.right);
            }
          },
          child: Column(
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[700]!, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cellSize =
                              constraints.maxWidth / SnakeGameService.gridSize;
                          return CustomPaint(
                            painter: _SnakePainter(
                              snake: _service.snake,
                              food: _service.food,
                              cellSize: cellSize,
                              gridSize: SnakeGameService.gridSize,
                            ),
                            size: Size(constraints.maxWidth,
                                constraints.maxHeight),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_service.isPlaying && !_service.isGameOver)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: ElevatedButton.icon(
                    onPressed: _startGame,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Game'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                  ),
                ),
              if (_service.isPlaying)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dirButton(Icons.arrow_upward, SnakeDirection.up),
                      const SizedBox(width: 8),
                      _dirButton(Icons.arrow_back, SnakeDirection.left),
                      const SizedBox(width: 8),
                      _dirButton(Icons.arrow_downward, SnakeDirection.down),
                      const SizedBox(width: 8),
                      _dirButton(Icons.arrow_forward, SnakeDirection.right),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dirButton(IconData icon, SnakeDirection dir) {
    return IconButton.filled(
      onPressed: () => _service.setDirection(dir),
      icon: Icon(icon),
      iconSize: 28,
    );
  }
}

class _SnakePainter extends CustomPainter {
  final List<GridPoint> snake;
  final GridPoint food;
  final double cellSize;
  final int gridSize;

  _SnakePainter({
    required this.snake,
    required this.food,
    required this.cellSize,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background grid
    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, gridPaint);

    // Checkerboard
    final altPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;
    for (var x = 0; x < gridSize; x++) {
      for (var y = 0; y < gridSize; y++) {
        if ((x + y) % 2 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
            altPaint,
          );
        }
      }
    }

    // Food
    final foodPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final foodCenter = Offset(
      food.x * cellSize + cellSize / 2,
      food.y * cellSize + cellSize / 2,
    );
    canvas.drawCircle(foodCenter, cellSize / 2.5, foodPaint);

    // Snake
    for (var i = 0; i < snake.length; i++) {
      final p = snake[i];
      final isHead = i == 0;
      final paint = Paint()
        ..color = isHead ? Colors.green[800]! : Colors.green[600]!
        ..style = PaintingStyle.fill;
      final rect = Rect.fromLTWH(
        p.x * cellSize + 1,
        p.y * cellSize + 1,
        cellSize - 2,
        cellSize - 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(isHead ? 6 : 3)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnakePainter oldDelegate) => true;
}
