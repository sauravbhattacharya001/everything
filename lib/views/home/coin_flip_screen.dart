import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/services/coin_flip_service.dart';

/// A coin flip screen with animation, multi-flip, history, and statistics.
class CoinFlipScreen extends StatefulWidget {
  const CoinFlipScreen({super.key});

  @override
  State<CoinFlipScreen> createState() => _CoinFlipScreenState();
}

class _CoinFlipScreenState extends State<CoinFlipScreen>
    with SingleTickerProviderStateMixin {
  final _service = CoinFlipService();
  CoinFlipResult? _lastResult;
  List<CoinFlipResult>? _multiResults;
  bool _flipping = false;
  int _flipCount = 1;
  late AnimationController _animController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() {
      _flipping = true;
      _multiResults = null;
    });
    _animController.forward(from: 0).then((_) {
      if (_flipCount == 1) {
        final result = _service.flip();
        setState(() {
          _lastResult = result;
          _flipping = false;
        });
      } else {
        final results = _service.flipMultiple(_flipCount);
        setState(() {
          _multiResults = results;
          _lastResult = results.last;
          _flipping = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _service.getStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Flip'),
        actions: [
          if (_service.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear history',
              onPressed: () => setState(() {
                _service.clearHistory();
                _lastResult = null;
                _multiResults = null;
              }),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Coin display
            Center(
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, _) {
                  final angle = _flipping ? _flipAnimation.value * pi * 4 : 0.0;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _lastResult == null
                              ? [Colors.grey.shade400, Colors.grey.shade600]
                              : _lastResult!.isHeads
                                  ? [Colors.amber.shade400, Colors.amber.shade700]
                                  : [Colors.blueGrey.shade300, Colors.blueGrey.shade600],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _lastResult == null
                              ? '?'
                              : _lastResult!.isHeads
                                  ? 'H'
                                  : 'T',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Result label
            Center(
              child: Text(
                _lastResult == null
                    ? 'Tap to flip!'
                    : _lastResult!.label,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Flip count selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Flip count: '),
                ...([1, 3, 5, 10].map((n) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('$n'),
                        selected: _flipCount == n,
                        onSelected: (_) => setState(() => _flipCount = n),
                      ),
                    ))),
              ],
            ),
            const SizedBox(height: 16),

            // Flip button
            ElevatedButton.icon(
              onPressed: _flipping ? null : _flip,
              icon: const Icon(Icons.monetization_on),
              label: Text(_flipCount == 1 ? 'Flip!' : 'Flip $_flipCount coins!'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 24),

            // Multi-flip results
            if (_multiResults != null && _multiResults!.length > 1) ...[
              Text('Results:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _multiResults!.map((r) => Chip(
                  avatar: Icon(
                    r.isHeads ? Icons.circle : Icons.circle_outlined,
                    size: 18,
                    color: r.isHeads ? Colors.amber.shade700 : Colors.blueGrey,
                  ),
                  label: Text(r.label),
                )).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Heads: ${_multiResults!.where((r) => r.isHeads).length} | '
                'Tails: ${_multiResults!.where((r) => !r.isHeads).length}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            // Statistics card
            if (stats.totalFlips > 0) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Statistics', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _statRow('Total Flips', '${stats.totalFlips}'),
                      _statRow('Heads', '${stats.heads} (${stats.headsPercentage.toStringAsFixed(1)}%)'),
                      _statRow('Tails', '${stats.tails} (${stats.tailsPercentage.toStringAsFixed(1)}%)'),
                      const Divider(),
                      _statRow('Current Streak', stats.currentStreakLabel),
                      _statRow('Longest Streak', stats.longestStreakLabel),
                      const SizedBox(height: 12),
                      // Distribution bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stats.headsPercentage / 100,
                          minHeight: 12,
                          backgroundColor: Colors.blueGrey.shade300,
                          valueColor: AlwaysStoppedAnimation(Colors.amber.shade600),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Heads', style: TextStyle(color: Colors.amber.shade700, fontSize: 12)),
                          Text('Tails', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // History
            if (_service.history.isNotEmpty) ...[
              Text(
                'History (last ${_service.history.length > 20 ? 20 : _service.history.length})',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _service.history
                    .reversed
                    .take(20)
                    .map((r) => CircleAvatar(
                          radius: 16,
                          backgroundColor: r.isHeads
                              ? Colors.amber.shade600
                              : Colors.blueGrey.shade400,
                          child: Text(
                            r.isHeads ? 'H' : 'T',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
