import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/score_keeper_service.dart';

/// Score Keeper screen — track game scores for multiple players with
/// round-by-round entry, undo, presets, and winner detection.
class ScoreKeeperScreen extends StatefulWidget {
  const ScoreKeeperScreen({super.key});

  @override
  State<ScoreKeeperScreen> createState() => _ScoreKeeperScreenState();
}

class _ScoreKeeperScreenState extends State<ScoreKeeperScreen> {
  final List<GameSession> _history = [];
  GameSession? _active;

  // ── Setup form state ──
  GamePreset _selectedPreset = ScoreKeeperService.presets.first;
  final _sessionNameCtrl = TextEditingController(text: 'Game 1');
  final _targetScoreCtrl = TextEditingController();
  final _maxRoundsCtrl = TextEditingController();
  final List<TextEditingController> _playerCtrls = [
    TextEditingController(text: 'Player 1'),
    TextEditingController(text: 'Player 2'),
  ];

  @override
  void dispose() {
    _sessionNameCtrl.dispose();
    _targetScoreCtrl.dispose();
    _maxRoundsCtrl.dispose();
    for (final c in _playerCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyPreset(GamePreset preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset.targetScore != null) {
        _targetScoreCtrl.text = preset.targetScore.toString();
      } else {
        _targetScoreCtrl.clear();
      }
      if (preset.rounds != null) {
        _maxRoundsCtrl.text = preset.rounds.toString();
      } else {
        _maxRoundsCtrl.clear();
      }
      // Adjust player count to min
      while (_playerCtrls.length < preset.minPlayers) {
        _addPlayer();
      }
    });
  }

  void _addPlayer() {
    _playerCtrls.add(
      TextEditingController(text: 'Player ${_playerCtrls.length + 1}'),
    );
    setState(() {});
  }

  void _removePlayer(int i) {
    if (_playerCtrls.length <= 2) return;
    _playerCtrls[i].dispose();
    _playerCtrls.removeAt(i);
    setState(() {});
  }

  void _startGame() {
    final names = _playerCtrls.map((c) => c.text.trim()).toList();
    if (names.any((n) => n.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All players need names')),
      );
      return;
    }
    final target = int.tryParse(_targetScoreCtrl.text);
    final rounds = int.tryParse(_maxRoundsCtrl.text);
    setState(() {
      _active = GameSession(
        name: _sessionNameCtrl.text.trim().isEmpty
            ? 'Game'
            : _sessionNameCtrl.text.trim(),
        playerNames: names,
        targetScore: target,
        maxRounds: rounds,
        countDown: _selectedPreset.countDown,
      );
    });
  }

  void _endGame() {
    if (_active != null) {
      _history.insert(0, _active!);
    }
    setState(() => _active = null);
  }

  // ── Score entry ──

  void _addScore(PlayerScore player) async {
    final ctrl = TextEditingController();
    final score = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Score for ${player.name}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
          ],
          decoration: const InputDecoration(
            hintText: 'Enter score',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) {
            final n = int.tryParse(v);
            Navigator.of(ctx).pop(n);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, int.tryParse(ctrl.text));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (score == null) return;
    setState(() => player.addRound(score));

    // Check for winner
    final winner = ScoreKeeperService.checkTargetReached(_active!);
    if (winner != null) {
      _showWinnerDialog([winner]);
    } else if (_active!.isFinished) {
      _showWinnerDialog(ScoreKeeperService.getWinners(_active!));
    }
  }

  void _quickAdd(PlayerScore player, int delta) {
    setState(() => player.addRound(delta));
    final winner = ScoreKeeperService.checkTargetReached(_active!);
    if (winner != null) {
      _showWinnerDialog([winner]);
    }
  }

  void _undoScore(PlayerScore player) {
    final removed = player.undoLast();
    if (removed != null) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed $removed from ${player.name}')),
      );
    }
  }

  void _showWinnerDialog(List<PlayerScore> winners) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
        title: Text(
          winners.length == 1
              ? '🏆 ${winners.first.name} Wins!'
              : '🏆 Tie: ${winners.map((w) => w.name).join(' & ')}',
        ),
        content: Text('Score: ${winners.first.total}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _endGame();
            },
            child: const Text('End Game'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_active != null ? _active!.name : 'Score Keeper'),
        actions: [
          if (_active != null)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: 'End Game',
              onPressed: _endGame,
            ),
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'History',
              onPressed: _showHistory,
            ),
        ],
      ),
      body: _active != null ? _buildGameView(theme) : _buildSetupView(theme),
    );
  }

  // ── Setup View ──

  Widget _buildSetupView(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Preset chips
        Text('Game Preset', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: ScoreKeeperService.presets.map((p) {
            return ChoiceChip(
              label: Text(p.name),
              selected: _selectedPreset == p,
              onSelected: (_) => _applyPreset(p),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Session name
        TextField(
          controller: _sessionNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Session Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // Target score & max rounds
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _targetScoreCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Target Score',
                  border: OutlineInputBorder(),
                  hintText: 'Optional',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxRoundsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Max Rounds',
                  border: OutlineInputBorder(),
                  hintText: 'Optional',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Players
        Row(
          children: [
            Text('Players', style: theme.textTheme.titleSmall),
            const Spacer(),
            TextButton.icon(
              onPressed: _playerCtrls.length < 10 ? _addPlayer : null,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_playerCtrls.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _playerColor(i),
                  child: Text('${i + 1}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _playerCtrls[i],
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      hintText: 'Player ${i + 1}',
                    ),
                  ),
                ),
                if (_playerCtrls.length > 2)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _removePlayer(i),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),

        FilledButton.icon(
          onPressed: _startGame,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Game'),
        ),
      ],
    );
  }

  // ── Game View ──

  Widget _buildGameView(ThemeData theme) {
    final session = _active!;
    return Column(
      children: [
        // Round indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Text('Round ${session.currentRound}',
                  style: theme.textTheme.titleMedium),
              if (session.maxRounds != null)
                Text(' / ${session.maxRounds}',
                    style: theme.textTheme.bodyMedium),
              const Spacer(),
              if (session.targetScore != null)
                Chip(
                  label: Text(
                    session.countDown
                        ? 'Count down from ${session.targetScore}'
                        : 'First to ${session.targetScore}',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),

        // Player scores
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: session.players.length,
            itemBuilder: (ctx, i) {
              final player = session.players[i];
              final isLeading = session.players.isNotEmpty &&
                  player.total ==
                      (session.countDown
                          ? session.players
                              .map((p) => p.total)
                              .reduce((a, b) => a < b ? a : b)
                          : session.players
                              .map((p) => p.total)
                              .reduce((a, b) => a > b ? a : b));
              return Card(
                elevation: isLeading ? 3 : 1,
                color: isLeading
                    ? theme.colorScheme.primaryContainer
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: _playerColor(i),
                            child: Text(
                              player.name.isNotEmpty
                                  ? player.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(player.name,
                                    style: theme.textTheme.titleMedium),
                                Text(
                                  '${player.roundCount} rounds',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (isLeading && session.players.length > 1)
                            const Icon(Icons.arrow_upward,
                                color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${player.total}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Quick score buttons + custom
                      Row(
                        children: [
                          _quickBtn(player, -1, '-1'),
                          const SizedBox(width: 4),
                          _quickBtn(player, 1, '+1'),
                          const SizedBox(width: 4),
                          _quickBtn(player, 5, '+5'),
                          const SizedBox(width: 4),
                          _quickBtn(player, 10, '+10'),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _addScore(player),
                            child: const Text('Custom'),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.undo, size: 20),
                            tooltip: 'Undo last',
                            onPressed: player.roundScores.isNotEmpty
                                ? () => _undoScore(player)
                                : null,
                          ),
                        ],
                      ),
                      // Round scores preview
                      if (player.roundScores.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: player.roundScores
                                .asMap()
                                .entries
                                .map((e) => Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text(
                                        'R${e.key + 1}: ${e.value}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _quickBtn(PlayerScore player, int delta, String label) {
    return SizedBox(
      width: 48,
      child: FilledButton.tonal(
        onPressed: () => _quickAdd(player, delta),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(48, 36),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Game History',
              style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            const Center(child: Text('No completed games yet')),
          ..._history.map((session) {
            final winners = ScoreKeeperService.getWinners(session);
            return Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events),
                title: Text(session.name),
                subtitle: Text(
                  '${session.players.length} players · '
                  'Winner: ${winners.map((w) => '${w.name} (${w.total})').join(', ')}',
                ),
                trailing: Text(
                  '${session.createdAt.hour}:${session.createdAt.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _playerColor(int index) {
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }
}
