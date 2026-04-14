import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// Quick Math Drill — timed arithmetic practice with adaptive difficulty.
///
/// The difficulty auto-adjusts based on accuracy and speed:
/// - 3+ correct in a row → harder problems
/// - 2+ wrong in a row → easier problems
///
/// Tracks session stats: score, streak, accuracy, average time.
class MathDrillScreen extends StatefulWidget {
  const MathDrillScreen({super.key});

  @override
  State<MathDrillScreen> createState() => _MathDrillScreenState();
}

enum _Op { add, subtract, multiply, divide }

class _Problem {
  final int a;
  final int b;
  final _Op op;
  final int answer;

  _Problem(this.a, this.b, this.op, this.answer);

  String get display {
    final sym = switch (op) {
      _Op.add => '+',
      _Op.subtract => '−',
      _Op.multiply => '×',
      _Op.divide => '÷',
    };
    return '$a $sym $b = ?';
  }
}

class _MathDrillScreenState extends State<MathDrillScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  // Difficulty: 1-5
  int _level = 1;
  int _streak = 0;
  int _wrongStreak = 0;
  int _correct = 0;
  int _total = 0;
  int _bestStreak = 0;
  final List<int> _responseTimes = [];

  _Problem? _current;
  DateTime? _problemStart;
  bool _showResult = false;
  bool _wasCorrect = false;
  bool _isRunning = false;
  int _timeLeft = 60;
  Timer? _timer;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startDrill() {
    setState(() {
      _isRunning = true;
      _level = 1;
      _streak = 0;
      _wrongStreak = 0;
      _correct = 0;
      _total = 0;
      _bestStreak = 0;
      _responseTimes.clear();
      _timeLeft = 60;
      _showResult = false;
    });
    _nextProblem();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _endDrill();
      }
    });
  }

  void _endDrill() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _current = null;
    });
  }

  _Problem _generateProblem() {
    // Ops allowed by level
    final ops = <_Op>[_Op.add];
    if (_level >= 2) ops.add(_Op.subtract);
    if (_level >= 3) ops.add(_Op.multiply);
    if (_level >= 4) ops.add(_Op.divide);

    final op = ops[_random.nextInt(ops.length)];

    // Number range by level
    final maxNum = switch (_level) {
      1 => 10,
      2 => 20,
      3 => 12,
      4 => 12,
      _ => 20,
    };

    int a, b, answer;
    switch (op) {
      case _Op.add:
        a = _random.nextInt(maxNum) + 1;
        b = _random.nextInt(maxNum) + 1;
        answer = a + b;
      case _Op.subtract:
        a = _random.nextInt(maxNum) + 1;
        b = _random.nextInt(a) + 1; // b <= a so no negatives
        answer = a - b;
      case _Op.multiply:
        a = _random.nextInt(maxNum) + 1;
        b = _random.nextInt(maxNum) + 1;
        answer = a * b;
      case _Op.divide:
        b = _random.nextInt(maxNum - 1) + 2; // divisor 2..maxNum
        answer = _random.nextInt(maxNum) + 1;
        a = b * answer; // clean division
    }

    return _Problem(a, b, op, answer);
  }

  void _nextProblem() {
    _controller.clear();
    setState(() {
      _current = _generateProblem();
      _problemStart = DateTime.now();
      _showResult = false;
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _submit() {
    if (_current == null || !_isRunning) return;
    final input = int.tryParse(_controller.text.trim());
    if (input == null) return;

    final elapsed =
        DateTime.now().difference(_problemStart!).inMilliseconds;
    _responseTimes.add(elapsed);

    final isCorrect = input == _current!.answer;
    setState(() {
      _total++;
      _wasCorrect = isCorrect;
      _showResult = true;
      if (isCorrect) {
        _correct++;
        _streak++;
        _wrongStreak = 0;
        if (_streak > _bestStreak) _bestStreak = _streak;
        // Adaptive: level up after 3 correct in a row
        if (_streak % 3 == 0 && _level < 5) _level++;
      } else {
        _wrongStreak++;
        _streak = 0;
        // Adaptive: level down after 2 wrong in a row
        if (_wrongStreak >= 2 && _level > 1) {
          _level--;
          _wrongStreak = 0;
        }
        _shakeController.forward(from: 0);
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _isRunning) _nextProblem();
    });
  }

  String _levelLabel(int level) => switch (level) {
        1 => 'Easy',
        2 => 'Medium',
        3 => 'Hard',
        4 => 'Expert',
        _ => 'Master',
      };

  Color _levelColor(int level) => switch (level) {
        1 => Colors.green,
        2 => Colors.blue,
        3 => Colors.orange,
        4 => Colors.red,
        _ => Colors.purple,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Math Drill')),
      body: _isRunning ? _buildDrill() : _buildLobby(),
    );
  }

  Widget _buildLobby() {
    final hasResults = _total > 0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate, size: 80, color: Colors.blue[300]),
            const SizedBox(height: 16),
            const Text(
              'Quick Math Drill',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Solve as many as you can in 60 seconds!\n'
              'Difficulty adapts to your skill level.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            if (hasResults) ...[
              _ResultCard(
                correct: _correct,
                total: _total,
                bestStreak: _bestStreak,
                avgMs: _responseTimes.isEmpty
                    ? 0
                    : _responseTimes.reduce((a, b) => a + b) ~/
                        _responseTimes.length,
                finalLevel: _level,
                levelLabel: _levelLabel(_level),
                levelColor: _levelColor(_level),
              ),
              const SizedBox(height: 24),
            ],
            FilledButton.icon(
              onPressed: _startDrill,
              icon: const Icon(Icons.play_arrow),
              label: Text(hasResults ? 'Play Again' : 'Start'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrill() {
    final accuracy =
        _total == 0 ? 100.0 : (_correct / _total * 100);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Top bar: timer, level, streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Timer
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _timeLeft <= 10
                      ? Colors.red[100]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer,
                        size: 18,
                        color:
                            _timeLeft <= 10 ? Colors.red : Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text(
                      '${_timeLeft}s',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            _timeLeft <= 10 ? Colors.red : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              // Level badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _levelColor(_level).withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: _levelColor(_level).withAlpha(120)),
                ),
                child: Text(
                  'Lv${_level} ${_levelLabel(_level)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _levelColor(_level),
                  ),
                ),
              ),
              // Streak
              Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 2),
                  Text(
                    '$_streak',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress
          LinearProgressIndicator(
            value: accuracy / 100,
            backgroundColor: Colors.grey[200],
            color: accuracy >= 80
                ? Colors.green
                : accuracy >= 50
                    ? Colors.orange
                    : Colors.red,
          ),
          Text(
            '$_correct / $_total correct (${accuracy.toStringAsFixed(0)}%)',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const Spacer(),
          // Problem display
          if (_current != null)
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final dx = _shakeController.isAnimating
                    ? sin(_shakeController.value * 3 * pi) * 10
                    : 0.0;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _showResult
                      ? (_wasCorrect
                          ? Colors.green.withAlpha(20)
                          : Colors.red.withAlpha(20))
                      : Colors.blue.withAlpha(10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showResult
                        ? (_wasCorrect ? Colors.green : Colors.red)
                        : Colors.blue.withAlpha(50),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _current!.display,
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    if (_showResult)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _wasCorrect
                              ? '✓ Correct!'
                              : '✗ Answer: ${_current!.answer}',
                          style: TextStyle(
                            fontSize: 20,
                            color:
                                _wasCorrect ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Input
          SizedBox(
            width: 200,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.numberWithOptions(signed: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28),
              enabled: !_showResult,
              decoration: InputDecoration(
                hintText: 'Answer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _showResult ? null : _submit,
            child: const Text('Submit', style: TextStyle(fontSize: 18)),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final int correct;
  final int total;
  final int bestStreak;
  final int avgMs;
  final int finalLevel;
  final String levelLabel;
  final Color levelColor;

  const _ResultCard({
    required this.correct,
    required this.total,
    required this.bestStreak,
    required this.avgMs,
    required this.finalLevel,
    required this.levelLabel,
    required this.levelColor,
  });

  String _grade() {
    final pct = total == 0 ? 0 : (correct / total * 100);
    if (pct >= 95 && avgMs < 3000) return '🏆 Math Wizard';
    if (pct >= 85) return '⭐ Excellent';
    if (pct >= 70) return '👍 Good';
    if (pct >= 50) return '📝 Keep Practicing';
    return '💪 Getting Started';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(_grade(),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('Score', '$correct/$total'),
                _stat('Best Streak', '$bestStreak'),
                _stat('Avg Time', '${(avgMs / 1000).toStringAsFixed(1)}s'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: levelColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Final Level: $finalLevel ($levelLabel)',
                style: TextStyle(
                  color: levelColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }
}
