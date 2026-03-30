import 'package:flutter/material.dart';
import '../../core/services/game_2048_service.dart';

/// The classic 2048 sliding-tile puzzle game.
///
/// Swipe (or use arrow keys) to slide tiles. When two tiles with the
/// same number collide, they merge into one. Reach 2048 to win!
class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  final _service = Game2048Service();

  void _handleSwipe(SwipeDirection dir) {
    setState(() {
      _service.swipe(dir);
      if (_service.won) {
        _showWinDialog();
      } else if (_service.isGameOver) {
        _showGameOverDialog();
      }
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎉 You Win!'),
        content: Text('Score: ${_service.score}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _service.acknowledgeWin());
            },
            child: const Text('Keep Playing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _service.newGame());
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Final Score: ${_service.score}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _service.newGame());
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Color _tileColor(int value) {
    return switch (value) {
      0 => Colors.grey[300]!,
      2 => const Color(0xFFEEE4DA),
      4 => const Color(0xFFEDE0C8),
      8 => const Color(0xFFF2B179),
      16 => const Color(0xFFF59563),
      32 => const Color(0xFFF67C5F),
      64 => const Color(0xFFF65E3B),
      128 => const Color(0xFFEDCF72),
      256 => const Color(0xFFEDCC61),
      512 => const Color(0xFFEDC850),
      1024 => const Color(0xFFEDC53F),
      2048 => const Color(0xFFEDC22E),
      _ => const Color(0xFF3C3A32),
    };
  }

  Color _textColor(int value) {
    return value <= 4 ? const Color(0xFF776E65) : Colors.white;
  }

  double _fontSize(int value) {
    if (value < 100) return 32;
    if (value < 1000) return 26;
    if (value < 10000) return 22;
    return 18;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2048'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Game',
            onPressed: () => setState(() => _service.newGame()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Score bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ScoreCard(label: 'SCORE', value: _service.score),
                _ScoreCard(label: 'BEST', value: _service.bestScore),
              ],
            ),
          ),

          // Game board
          Expanded(
            child: Center(
              child: GestureDetector(
                onVerticalDragEnd: (d) {
                  if (d.primaryVelocity == null) return;
                  _handleSwipe(d.primaryVelocity! < 0
                      ? SwipeDirection.up
                      : SwipeDirection.down);
                },
                onHorizontalDragEnd: (d) {
                  if (d.primaryVelocity == null) return;
                  _handleSwipe(d.primaryVelocity! < 0
                      ? SwipeDirection.left
                      : SwipeDirection.right);
                },
                child: Focus(
                  autofocus: true,
                  onKeyEvent: (_, event) {
                    if (event is! KeyDownEvent) return KeyEventResult.ignored;
                    final dir = switch (event.logicalKey.keyLabel) {
                      'Arrow Up' => SwipeDirection.up,
                      'Arrow Down' => SwipeDirection.down,
                      'Arrow Left' => SwipeDirection.left,
                      'Arrow Right' => SwipeDirection.right,
                      _ => null,
                    };
                    if (dir != null) {
                      _handleSwipe(dir);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBADA0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: 16,
                        itemBuilder: (_, i) {
                          final r = i ~/ 4;
                          final c = i % 4;
                          final val = _service.grid[r][c];
                          return Container(
                            decoration: BoxDecoration(
                              color: _tileColor(val),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: val > 0
                                ? Text(
                                    '$val',
                                    style: TextStyle(
                                      fontSize: _fontSize(val),
                                      fontWeight: FontWeight.bold,
                                      color: _textColor(val),
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Swipe or use arrow keys to move tiles.\n'
              'Merge matching numbers to reach 2048!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final int value;

  const _ScoreCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFEEE4DA), fontSize: 12, fontWeight: FontWeight.bold)),
          Text('$value',
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
