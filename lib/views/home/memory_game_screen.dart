import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/services/memory_game_service.dart';

/// A classic card-matching memory game for brain training.
class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  final _service = MemoryGameService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _service.newGame();
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
      if (!_service.isGameOver) setState(() {});
    });
  }

  void _newGame() {
    setState(() {
      _service.newGame();
    });
    _startTimer();
  }

  void _onCardTap(int index) {
    final needsCheck = _service.flipCard(index);
    setState(() {});

    if (needsCheck) {
      _service.isProcessing = true;
      final result = _service.checkMatch();

      if (result.matched) {
        _service.isProcessing = false;
        setState(() {});
        if (_service.isGameOver) {
          _timer?.cancel();
          _showWinDialog();
        }
      } else {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _service.hideUnmatched(result.first, result.second);
              _service.isProcessing = false;
            });
          }
        });
      }
    }
  }

  void _showWinDialog() {
    final elapsed = _service.elapsed;
    final mins = elapsed.inMinutes;
    final secs = elapsed.inSeconds % 60;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 You Win!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Moves: ${_service.moves}'),
            Text('Time: ${mins}m ${secs}s'),
            Text('Difficulty: ${_service.difficulty.label}'),
            if (_service.bestGame != null)
              Text('Best: ${_service.bestGame!.moves} moves'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _newGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  String _formatElapsed() {
    final d = _service.elapsed;
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int get _crossAxisCount {
    final total = _service.cards.length;
    if (total <= 12) return 3;
    if (total <= 16) return 4;
    if (total <= 20) return 5;
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Game',
            onPressed: _newGame,
          ),
          PopupMenuButton<GameDifficulty>(
            icon: const Icon(Icons.tune),
            tooltip: 'Difficulty',
            onSelected: (d) {
              _service.difficulty = d;
              _newGame();
            },
            itemBuilder: (_) => GameDifficulty.values
                .map((d) => PopupMenuItem(
                      value: d,
                      child: Row(
                        children: [
                          if (d == _service.difficulty)
                            const Icon(Icons.check, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(d.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Score bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip(Icons.touch_app, 'Moves', '${_service.moves}'),
                _statChip(Icons.timer, 'Time', _formatElapsed()),
                _statChip(
                  Icons.check_circle_outline,
                  'Matched',
                  '${_service.matchedPairs}/${_service.totalPairs}',
                ),
              ],
            ),
          ),

          // Card grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _service.cards.length,
                itemBuilder: (context, index) {
                  final card = _service.cards[index];
                  return _CardTile(
                    card: card,
                    onTap: () => _onCardTap(index),
                  );
                },
              ),
            ),
          ),

          // History
          if (_service.history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ExpansionTile(
                leading: const Icon(Icons.history),
                title: Text(
                  'Game History (${_service.history.length})',
                  style: theme.textTheme.titleSmall,
                ),
                children: _service.history
                    .take(5)
                    .map((g) => ListTile(
                          dense: true,
                          title: Text(
                            '${g.difficulty.label} — ${g.moves} moves in '
                            '${g.elapsed.inMinutes}m ${g.elapsed.inSeconds % 60}s',
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  final MemoryCard card;
  final VoidCallback onTap;

  const _CardTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final showFace = card.isFaceUp || card.isMatched;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.isMatched
              ? Colors.green.shade100
              : showFace
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: card.isMatched
                ? Colors.green.shade400
                : showFace
                    ? theme.colorScheme.primary.withOpacity(0.5)
                    : theme.colorScheme.outline.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: showFace
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: showFace
              ? Text(card.emoji, style: const TextStyle(fontSize: 32))
              : Icon(
                  Icons.question_mark,
                  size: 28,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
        ),
      ),
    );
  }
}
