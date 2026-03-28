import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../core/services/reaction_time_service.dart';

/// Reaction time test: wait for the screen to turn green, then tap as fast as
/// you can. Tracks history, best/average/worst times, and gives ratings.
class ReactionTimeScreen extends StatefulWidget {
  const ReactionTimeScreen({super.key});

  @override
  State<ReactionTimeScreen> createState() => _ReactionTimeScreenState();
}

enum _Phase { idle, waiting, ready, result, tooSoon }

class _ReactionTimeScreenState extends State<ReactionTimeScreen> {
  final _service = ReactionTimeService();
  _Phase _phase = _Phase.idle;
  DateTime? _readyAt;
  int? _lastMs;
  Timer? _timer;
  final _random = Random();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _phase = _Phase.waiting);
    final delay = Duration(milliseconds: 1500 + _random.nextInt(4000));
    _timer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.ready;
        _readyAt = DateTime.now();
      });
    });
  }

  void _onTap() {
    switch (_phase) {
      case _Phase.idle:
      case _Phase.result:
      case _Phase.tooSoon:
        _start();
        break;
      case _Phase.waiting:
        _timer?.cancel();
        setState(() => _phase = _Phase.tooSoon);
        break;
      case _Phase.ready:
        final ms = DateTime.now().difference(_readyAt!).inMilliseconds;
        final result = ReactionTimeResult(reactionMs: ms);
        _service.addResult(result);
        setState(() {
          _lastMs = ms;
          _phase = _Phase.result;
        });
        break;
    }
  }

  Color get _bgColor {
    switch (_phase) {
      case _Phase.idle:
        return Colors.blue;
      case _Phase.waiting:
        return Colors.red.shade700;
      case _Phase.ready:
        return Colors.green;
      case _Phase.result:
        return Colors.blue;
      case _Phase.tooSoon:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reaction Time'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_service.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: _showHistory,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: _onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: _bgColor,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_phase) {
      case _Phase.idle:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, size: 80, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Reaction Time Test',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Tap anywhere to start.\nWhen the screen turns GREEN, tap as fast as you can!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        );

      case _Phase.waiting:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top, size: 80, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Wait for green...',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              "Don't tap yet!",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        );

      case _Phase.ready:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, size: 80, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'TAP NOW!',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        );

      case _Phase.tooSoon:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, size: 80, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Too Soon!',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Wait for the screen to turn green.\nTap to try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        );

      case _Phase.result:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _lastMs! < 300 ? Icons.emoji_events : Icons.timer,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              '${_lastMs}ms',
              style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _service.ratingFor(_lastMs!),
              style: const TextStyle(fontSize: 22, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            _buildStats(),
            const SizedBox(height: 24),
            const Text(
              'Tap to try again',
              style: TextStyle(fontSize: 16, color: Colors.white54),
            ),
          ],
        );
    }
  }

  Widget _buildStats() {
    final avg = _service.averageMs;
    final best = _service.bestMs;
    if (avg == null || best == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statChip('Best', '${best}ms', Colors.greenAccent),
          const SizedBox(width: 24),
          _statChip('Average', '${avg.round()}ms', Colors.amberAccent),
          const SizedBox(width: 24),
          _statChip('Tries', '${_service.history.length}', Colors.cyanAccent),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _HistorySheet(service: _service, onClear: () {
        _service.clearHistory();
        Navigator.pop(context);
        setState(() {});
      }),
    );
  }
}

class _HistorySheet extends StatelessWidget {
  final ReactionTimeService service;
  final VoidCallback onClear;

  const _HistorySheet({required this.service, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final history = service.history;
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('History',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Clear',
                    style: TextStyle(color: Colors.red)),
                onPressed: onClear,
              ),
            ],
          ),
          const Divider(),
          if (service.bestMs != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Best', '${service.bestMs}ms', Colors.green),
                _stat('Average', '${service.averageMs!.round()}ms',
                    Colors.blue),
                _stat('Worst', '${service.worstMs}ms', Colors.red),
                _stat('Last 5 avg', '${service.last5AverageMs}ms',
                    Colors.purple),
              ],
            ),
            const Divider(),
          ],
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: history.length,
              itemBuilder: (_, i) {
                final r = history[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: _colorForMs(r.reactionMs),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white)),
                  ),
                  title: Text('${r.reactionMs}ms'),
                  subtitle: Text(service.ratingFor(r.reactionMs)),
                  trailing: Text(
                    '${r.timestamp.hour.toString().padLeft(2, '0')}:'
                    '${r.timestamp.minute.toString().padLeft(2, '0')}:'
                    '${r.timestamp.second.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Color _colorForMs(int ms) {
    if (ms < 250) return Colors.green;
    if (ms < 350) return Colors.blue;
    if (ms < 500) return Colors.orange;
    return Colors.red;
  }
}
