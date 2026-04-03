import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/wordle_service.dart';

/// Wordle — guess the 5-letter word in 6 tries.
class WordleScreen extends StatefulWidget {
  const WordleScreen({super.key});
  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> {
  final _service = WordleService();
  String _currentInput = '';
  String? _error;

  static const _kbRows = [
    ['Q','W','E','R','T','Y','U','I','O','P'],
    ['A','S','D','F','G','H','J','K','L'],
    ['ENTER','Z','X','C','V','B','N','M','⌫'],
  ];

  void _onKey(String key) {
    if (_service.gameOver) return;
    setState(() {
      _error = null;
      if (key == '⌫') {
        if (_currentInput.isNotEmpty) _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      } else if (key == 'ENTER') {
        _submit();
      } else if (_currentInput.length < WordleService.wordLength) {
        _currentInput += key;
      }
    });
  }

  void _submit() {
    if (_currentInput.length != WordleService.wordLength) { _error = 'Not enough letters'; return; }
    final result = _service.submitGuess(_currentInput);
    if (result == null) { _error = 'Not in word list'; return; }
    _currentInput = '';
    if (_service.gameOver) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _showEndDialog();
      });
    }
  }

  void _showEndDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_service.won ? '🎉 You Won!' : '😔 Game Over'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!_service.won) Text('The word was: ${_service.secret}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Played: ${_service.gamesPlayed}  |  Won: ${_service.gamesWon}'),
          Text('Streak: ${_service.streak}  |  Best: ${_service.bestStreak}'),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); _newGame(); }, child: const Text('Play Again')),
        ],
      ),
    );
  }

  void _newGame() => setState(() { _service.newGame(); _currentInput = ''; _error = null; });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wordle'),
        actions: [IconButton(icon: const Icon(Icons.refresh), tooltip: 'New Game', onPressed: _newGame)],
      ),
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (e) {
          if (e is! KeyDownEvent) return;
          final l = e.logicalKey.keyLabel;
          if (l.length == 1 && RegExp(r'[A-Za-z]').hasMatch(l)) _onKey(l.toUpperCase());
          else if (e.logicalKey == LogicalKeyboardKey.backspace) _onKey('⌫');
          else if (e.logicalKey == LogicalKeyboardKey.enter) _onKey('ENTER');
        },
        child: Column(children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
            ),
          const SizedBox(height: 8),
          Expanded(child: Center(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min,
              children: List.generate(WordleService.maxGuesses, (r) => _buildRow(r, isDark))),
          ))),
          _buildKeyboard(isDark),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _buildRow(int row, bool isDark) {
    final guesses = _service.guesses;
    final isGuessed = row < guesses.length;
    final isCurrent = row == guesses.length && !_service.gameOver;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(WordleService.wordLength, (col) {
          String letter = '';
          Color bg = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
          Color tc = isDark ? Colors.white : Colors.black;
          if (isGuessed) {
            letter = guesses[row][col];
            final s = _service.evaluate(guesses[row]);
            switch (s[col]) {
              case LetterState.correct: bg = Colors.green.shade600; tc = Colors.white; break;
              case LetterState.present: bg = Colors.amber.shade600; tc = Colors.white; break;
              case LetterState.absent: bg = isDark ? Colors.grey.shade700 : Colors.grey.shade500; tc = Colors.white; break;
            }
          } else if (isCurrent && col < _currentInput.length) {
            letter = _currentInput[col];
            bg = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
          }
          return Container(
            width: 52, height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCurrent && col < _currentInput.length ? (isDark ? Colors.white54 : Colors.black38) : Colors.transparent, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(letter, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: tc)),
          );
        }),
      ),
    );
  }

  Widget _buildKeyboard(bool isDark) {
    final ks = _service.keyboardStates;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: _kbRows.map((row) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            final sp = key == 'ENTER' || key == '⌫';
            final st = ks[key];
            Color bg = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
            Color tc = isDark ? Colors.white : Colors.black;
            if (st != null) switch (st) {
              case LetterState.correct: bg = Colors.green.shade600; tc = Colors.white; break;
              case LetterState.present: bg = Colors.amber.shade600; tc = Colors.white; break;
              case LetterState.absent: bg = isDark ? Colors.grey.shade900 : Colors.grey.shade500; tc = Colors.white70; break;
            }
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(color: bg, borderRadius: BorderRadius.circular(6),
                child: InkWell(borderRadius: BorderRadius.circular(6), onTap: () => _onKey(key),
                  child: Container(width: sp ? 56 : 34, height: 48, alignment: Alignment.center,
                    child: Text(key, style: TextStyle(fontSize: sp ? 12 : 16, fontWeight: FontWeight.bold, color: tc))))));
          }).toList()),
      )).toList()),
    );
  }
}
