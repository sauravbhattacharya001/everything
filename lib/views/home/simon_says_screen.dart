import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/simon_says_service.dart';

/// Simon Says — a classic memory pattern game.
///
/// Features:
/// - Watch the sequence of coloured flashes, then repeat it
/// - Each round adds one more step
/// - Animated flash playback with increasing speed
/// - High-score tracking per session
class SimonSaysScreen extends StatefulWidget {
  const SimonSaysScreen({super.key});

  @override
  State<SimonSaysScreen> createState() => _SimonSaysScreenState();
}

class _SimonSaysScreenState extends State<SimonSaysScreen> {
  final _service = SimonSaysService();

  /// Which button is currently "lit up" (-1 = none).
  int _activeButton = -1;

  /// True while the computer is playing back the sequence.
  bool _isPlayback = false;

  /// True before the first game starts.
  bool _notStarted = true;

  static const _colors = [
    Colors.green,
    Colors.red,
    Colors.yellow,
    Colors.blue,
  ];

  static const _litColors = [
    Color(0xFF69F0AE), // bright green
    Color(0xFFFF8A80), // bright red
    Color(0xFFFFFF8D), // bright yellow
    Color(0xFF82B1FF), // bright blue
  ];

  static const _icons = [
    Icons.park,
    Icons.favorite,
    Icons.star,
    Icons.water_drop,
  ];

  void _startGame() {
    _service.reset();
    _notStarted = false;
    setState(() {});
    _playSequence();
  }

  Future<void> _playSequence() async {
    setState(() => _isPlayback = true);
    await Future.delayed(const Duration(milliseconds: 400));

    // Speed up as rounds increase (min 250ms).
    final delay = Duration(
      milliseconds: (600 - (_service.round * 30)).clamp(250, 600),
    );

    for (final button in _service.sequence) {
      setState(() => _activeButton = button);
      await Future.delayed(delay);
      setState(() => _activeButton = -1);
      await Future.delayed(const Duration(milliseconds: 150));
    }

    setState(() => _isPlayback = false);
  }

  void _onButtonTap(int index) {
    if (_isPlayback || _service.gameOver || _notStarted) return;

    // Flash the tapped button briefly.
    setState(() => _activeButton = index);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _activeButton = -1);
    });

    final correct = _service.tap(index);
    if (!correct) {
      setState(() {});
      return;
    }

    // If the player just completed a round, play the next sequence.
    if (_service.inputCount == 0) {
      // inputCount resets to 0 when a new round starts.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _playSequence();
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simon Says')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Score row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _chip('Round', _notStarted ? '-' : '${_service.round}'),
                _chip('High Score', '${_service.highScore}'),
              ],
            ),

            const SizedBox(height: 24),

            // Status text
            Text(
              _notStarted
                  ? 'Tap START to play!'
                  : _service.gameOver
                      ? 'Game Over!  You reached round ${_service.score + 1}.'
                      : _isPlayback
                          ? 'Watch carefully...'
                          : 'Your turn!  (${_service.inputCount}/${_service.round})',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // 2×2 button grid
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(4, (i) => _buildButton(i)),
                    ),
                  ),
                ),
              ),
            ),

            // Start / Play Again button
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: FilledButton.icon(
                onPressed:
                    (_isPlayback) ? null : _startGame,
                icon: Icon(
                    _notStarted || _service.gameOver
                        ? Icons.play_arrow
                        : Icons.refresh),
                label: Text(
                    _notStarted
                        ? 'START'
                        : _service.gameOver
                            ? 'Play Again'
                            : 'Restart'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(int index) {
    final isLit = _activeButton == index;
    final color = isLit ? _litColors[index] : _colors[index];

    return GestureDetector(
      onTap: () => _onButtonTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: color.withOpacity(isLit ? 1.0 : 0.6),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isLit
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 24,
                    spreadRadius: 4,
                  )
                ]
              : [],
        ),
        child: Center(
          child: Icon(
            _icons[index],
            size: 48,
            color: Colors.white.withOpacity(isLit ? 1.0 : 0.7),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
