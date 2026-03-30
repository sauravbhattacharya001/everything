import 'package:flutter/material.dart';
import '../../core/services/rps_service.dart';

/// Rock Paper Scissors game screen with animations, history, and stats.
class RpsScreen extends StatefulWidget {
  const RpsScreen({super.key});

  @override
  State<RpsScreen> createState() => _RpsScreenState();
}

class _RpsScreenState extends State<RpsScreen>
    with SingleTickerProviderStateMixin {
  final _service = RpsService();
  RpsRound? _lastRound;
  bool _playing = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _play(RpsMove move) async {
    if (_playing) return;
    setState(() => _playing = true);
    _animController.reset();

    // Brief suspense delay
    await Future.delayed(const Duration(milliseconds: 300));

    final round = _service.play(move);
    setState(() {
      _lastRound = round;
      _playing = false;
    });
    _animController.forward();
  }

  Color _outcomeColor(RpsOutcome outcome) {
    switch (outcome) {
      case RpsOutcome.win:
        return Colors.green;
      case RpsOutcome.lose:
        return Colors.red;
      case RpsOutcome.draw:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _service.getStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rock Paper Scissors'),
        actions: [
          if (_service.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear History',
              onPressed: () {
                setState(() {
                  _service.clearHistory();
                  _lastRound = null;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
            onPressed: () => _showStats(context, stats),
          ),
        ],
      ),
      body: Column(
        children: [
          // Result area
          Expanded(
            flex: 3,
            child: Center(
              child: _lastRound == null
                  ? Text(
                      'Choose your move!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    )
                  : ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildResult(theme),
                    ),
            ),
          ),

          // Score bar
          if (stats.totalRounds > 0)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _scoreTile('Wins', stats.wins, Colors.green),
                  _scoreTile('Draws', stats.draws, Colors.orange),
                  _scoreTile('Losses', stats.losses, Colors.red),
                ],
              ),
            ),

          // Move buttons
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: RpsMove.values.map((move) {
                  return _moveButton(move);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(ThemeData theme) {
    final round = _lastRound!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Player
            Column(
              children: [
                Text('You', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(
                  RpsService.moveEmoji(round.playerMove),
                  style: const TextStyle(fontSize: 64),
                ),
                Text(RpsService.moveLabel(round.playerMove)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('VS',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            // CPU
            Column(
              children: [
                Text('CPU', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(
                  RpsService.moveEmoji(round.cpuMove),
                  style: const TextStyle(fontSize: 64),
                ),
                Text(RpsService.moveLabel(round.cpuMove)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _outcomeColor(round.outcome).withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            RpsService.outcomeLabel(round.outcome),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: _outcomeColor(round.outcome),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _scoreTile(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _moveButton(RpsMove move) {
    return GestureDetector(
      onTap: _playing ? null : () => _play(move),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: _playing
              ? Colors.grey.withOpacity(0.2)
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(RpsService.moveEmoji(move),
                style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 4),
            Text(RpsService.moveLabel(move),
                style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _showStats(BuildContext context, RpsStats stats) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Statistics',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              _statRow('Total Rounds', '${stats.totalRounds}'),
              _statRow('Win Rate',
                  '${stats.winRate.toStringAsFixed(1)}%'),
              _statRow('Current Win Streak',
                  '${stats.currentWinStreak}'),
              _statRow('Best Win Streak', '${stats.bestWinStreak}'),
              const Divider(),
              Text('Your Move Preferences',
                  style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...RpsMove.values.map((move) => _statRow(
                    '${RpsService.moveEmoji(move)} ${RpsService.moveLabel(move)}',
                    '${stats.moveCounts[move] ?? 0}',
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
