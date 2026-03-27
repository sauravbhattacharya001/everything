import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/services/typing_speed_service.dart';

/// A typing speed test screen where users type a passage and get
/// WPM + accuracy stats.
class TypingSpeedScreen extends StatefulWidget {
  const TypingSpeedScreen({super.key});

  @override
  State<TypingSpeedScreen> createState() => _TypingSpeedScreenState();
}

enum _TestState { ready, running, finished }

class _TypingSpeedScreenState extends State<TypingSpeedScreen> {
  final _service = TypingSpeedService();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  String _targetText = '';
  _TestState _state = _TestState.ready;
  DateTime? _startTime;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  TypingResult? _result;
  final List<TypingResult> _history = [];

  @override
  void initState() {
    super.initState();
    _newTest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _newTest() {
    _timer?.cancel();
    setState(() {
      _targetText = _service.getRandomParagraph();
      _controller.clear();
      _state = _TestState.ready;
      _startTime = null;
      _elapsed = Duration.zero;
      _result = null;
    });
    _focusNode.requestFocus();
  }

  void _onTextChanged(String value) {
    if (_state == _TestState.finished) return;

    if (_state == _TestState.ready && value.isNotEmpty) {
      _startTime = DateTime.now();
      _state = _TestState.running;
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime!);
        });
      });
    }

    // Check if done (typed enough characters)
    if (value.length >= _targetText.length) {
      _finish();
    } else {
      setState(() {});
    }
  }

  void _finish() {
    _timer?.cancel();
    final elapsed = DateTime.now().difference(_startTime!);
    final result = _service.calculateResult(
      target: _targetText,
      typed: _controller.text,
      elapsed: elapsed,
    );
    setState(() {
      _state = _TestState.finished;
      _elapsed = elapsed;
      _result = result;
      _history.insert(0, result);
    });
  }

  Color _charColor(int index) {
    final typed = _controller.text;
    if (index >= typed.length) return Colors.grey.shade400;
    return typed[index] == _targetText[index]
        ? Colors.green.shade700
        : Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Typing Speed Test'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'History',
              onPressed: _showHistory,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Test',
            onPressed: _newTest,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timer & live stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(
                  icon: Icons.timer,
                  label: _formatDuration(_elapsed),
                ),
                const SizedBox(width: 16),
                if (_state == _TestState.running) ...[
                  _StatChip(
                    icon: Icons.speed,
                    label: '${_liveWpm()} WPM',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Target text with colored characters
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withAlpha(80),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withAlpha(50),
                  ),
                ),
                child: SingleChildScrollView(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        height: 1.6,
                        letterSpacing: 0.3,
                      ),
                      children: List.generate(_targetText.length, (i) {
                        return TextSpan(
                          text: _targetText[i],
                          style: TextStyle(
                            color: _charColor(i),
                            fontWeight: i < _controller.text.length
                                ? FontWeight.bold
                                : FontWeight.normal,
                            backgroundColor:
                                i == _controller.text.length &&
                                        _state != _TestState.finished
                                    ? Colors.yellow.withAlpha(80)
                                    : null,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Input field
            if (_state != _TestState.finished)
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onTextChanged,
                maxLines: 3,
                minLines: 2,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: _state == _TestState.ready
                      ? 'Start typing to begin the test...'
                      : 'Keep typing...',
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 16),
              ),

            // Results card
            if (_state == _TestState.finished && _result != null) ...[
              const SizedBox(height: 12),
              _ResultCard(result: _result!),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _newTest,
                icon: const Icon(Icons.replay),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _liveWpm() {
    if (_elapsed.inSeconds == 0) return 0;
    final words = _controller.text.length / 5.0;
    final minutes = _elapsed.inMilliseconds / 60000.0;
    return (words / minutes).round();
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    final tenths = ((d.inMilliseconds % 1000) ~/ 100).toString();
    return '$mins:$secs.$tenths';
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (_, i) {
          final r = _history[i];
          return ListTile(
            leading: CircleAvatar(child: Text('${r.wordsPerMinute}')),
            title: Text('${r.wordsPerMinute} WPM'),
            subtitle: Text(
              'Accuracy: ${r.accuracy.toStringAsFixed(1)}% • '
              '${_formatDuration(r.elapsed)}',
            ),
            trailing: Text(
              '${r.timestamp.hour}:${r.timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final TypingResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Test Complete!',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ResultStat(
                  value: '${result.wordsPerMinute}',
                  label: 'WPM',
                  color: Colors.blue,
                ),
                _ResultStat(
                  value: '${result.accuracy.toStringAsFixed(1)}%',
                  label: 'Accuracy',
                  color: result.accuracy >= 95
                      ? Colors.green
                      : result.accuracy >= 80
                          ? Colors.orange
                          : Colors.red,
                ),
                _ResultStat(
                  value: '${result.correctChars}/${result.totalChars}',
                  label: 'Correct',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _ResultStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            )),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
