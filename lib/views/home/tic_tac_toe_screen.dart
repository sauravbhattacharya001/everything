import 'package:flutter/material.dart';
import '../../core/services/tic_tac_toe_service.dart';

/// Tic Tac Toe — classic 3×3 grid game with two-player and vs-AI modes.
///
/// Features:
/// - Two-player local or vs AI (minimax — unbeatable)
/// - Animated winning line highlight
/// - Score tracking across rounds
/// - Tap to play, swipe-down or button to reset
class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen>
    with SingleTickerProviderStateMixin {
  final _service = TicTacToeService();
  int _xWins = 0;
  int _oWins = 0;
  int _draws = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (_service.makeMove(index)) {
      setState(() {});
      if (_service.gameOver) {
        _animController.forward(from: 0);
        if (_service.winner == 'X') {
          _xWins++;
        } else if (_service.winner == 'O') {
          _oWins++;
        } else {
          _draws++;
        }
      }
    }
  }

  void _reset() {
    setState(() {
      _service.reset();
      _animController.reset();
    });
  }

  void _resetScores() {
    setState(() {
      _xWins = 0;
      _oWins = 0;
      _draws = 0;
      _service.reset();
      _animController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final winLine = _service.winningLine;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic Tac Toe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset scores',
            onPressed: _resetScores,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Mode toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('2 Players')),
                ButtonSegment(value: true, label: Text('vs AI')),
              ],
              selected: {_service.vsAi},
              onSelectionChanged: (v) => setState(() {
                _service.setVsAi(v.first);
                _xWins = 0;
                _oWins = 0;
                _draws = 0;
              }),
            ),
            const SizedBox(height: 16),
            // Scoreboard
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _scoreChip('X', _xWins, cs.primary),
                _scoreChip('Draw', _draws, cs.outline),
                _scoreChip(_service.vsAi ? 'AI' : 'O', _oWins, cs.error),
              ],
            ),
            const SizedBox(height: 16),
            // Status
            Text(
              _service.gameOver
                  ? (_service.winner != null
                      ? '${_service.winner == "O" && _service.vsAi ? "AI" : _service.winner} wins!'
                      : "It's a draw!")
                  : '${_service.currentPlayer == "O" && _service.vsAi ? "AI" : _service.currentPlayer}\'s turn',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Board
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final cell = _service.board[index];
                      final isWinCell =
                          winLine != null && winLine.contains(index);
                      return GestureDetector(
                        onTap: () => _onTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isWinCell
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: isWinCell
                                ? Border.all(color: cs.primary, width: 3)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              cell,
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: cell == 'X' ? cs.primary : cs.error,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // New game button
            if (_service.gameOver)
              FadeTransition(
                opacity: _fadeAnim,
                child: FilledButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.replay),
                  label: const Text('New Game'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _scoreChip(String label, int score, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text('$score', style: TextStyle(fontSize: 24, color: color)),
      ],
    );
  }
}
