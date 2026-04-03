import 'package:flutter/material.dart';
import '../../core/services/hangman_service.dart';

/// Hangman Game — guess the word before the stick figure is complete.
class HangmanScreen extends StatefulWidget {
  const HangmanScreen({super.key});

  @override
  State<HangmanScreen> createState() => _HangmanScreenState();
}

class _HangmanScreenState extends State<HangmanScreen>
    with SingleTickerProviderStateMixin {
  final _service = HangmanService();
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onLetterTap(String letter) {
    final wasNew = _service.guessLetter(letter);
    if (wasNew && !_service.word.contains(letter.toUpperCase())) {
      _shakeController.forward(from: 0);
    }
    setState(() {});

    if (_service.gameOver) {
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          _service.won ? '🎉 You Won!' : '💀 Game Over',
          style: TextStyle(
            color: _service.won ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _service.won
                  ? 'You guessed "${_service.word}" correctly!'
                  : 'The word was "${_service.word}"',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statChip('🏆 Wins', '${_service.wins}', Colors.green),
                _statChip('💔 Losses', '${_service.losses}', Colors.red),
                _statChip('🔥 Streak', '${_service.streak}', Colors.orange),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _service.newGame());
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hangman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Game',
            onPressed: () => setState(() => _service.newGame()),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statChip('🏆', '${_service.wins}', Colors.green),
                  _statChip('💔', '${_service.losses}', Colors.red),
                  _statChip('🔥', '${_service.streak}', Colors.orange),
                ],
              ),
              const SizedBox(height: 16),

              // Hangman ASCII art
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final dx = _shakeController.isAnimating
                      ? (4.0 *
                          (0.5 - _shakeController.value).abs() *
                          (_shakeController.value > 0.5 ? -1 : 1) *
                          8)
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    HangmanService.hangmanArt[_service.wrongGuesses],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      height: 1.2,
                      color: _service.wrongGuesses >= 4
                          ? Colors.red
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Lives remaining
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  HangmanService.maxWrong,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      i < _service.remainingLives
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: i < _service.remainingLives
                          ? Colors.red
                          : Colors.grey,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Word display
              Text(
                _service.displayWord,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              // Hint button
              if (!_service.hintUsed && !_service.gameOver)
                TextButton.icon(
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Show Hint'),
                  onPressed: () => setState(() => _service.useHint()),
                ),
              if (_service.hintUsed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _service.hint,
                          style: TextStyle(
                            color: isDark ? Colors.amber[200] : Colors.amber[800],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Keyboard
              _buildKeyboard(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard(bool isDark) {
    const rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((letter) {
              final guessed = _service.guessedLetters.contains(letter);
              final inWord = _service.word.contains(letter);

              Color bgColor;
              Color textColor;
              if (!guessed) {
                bgColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
                textColor = isDark ? Colors.white : Colors.black;
              } else if (inWord) {
                bgColor = Colors.green;
                textColor = Colors.white;
              } else {
                bgColor = Colors.red[400]!;
                textColor = Colors.white;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: guessed || _service.gameOver
                        ? null
                        : () => _onLetterTap(letter),
                    child: SizedBox(
                      width: 32,
                      height: 42,
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
