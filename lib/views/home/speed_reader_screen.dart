import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/speed_reader_service.dart';

/// RSVP Speed Reader – flash words/chunks at adjustable WPM for speed reading
/// practice. Includes built-in sample texts, custom text input, and session
/// history with stats.
class SpeedReaderScreen extends StatefulWidget {
  const SpeedReaderScreen({super.key});

  @override
  State<SpeedReaderScreen> createState() => _SpeedReaderScreenState();
}

class _SpeedReaderScreenState extends State<SpeedReaderScreen> {
  final _service = SpeedReaderService();
  final _textController = TextEditingController();

  int _wpm = 300;
  SpeedReadMode _mode = SpeedReadMode.word;
  List<String> _tokens = [];
  int _currentIndex = 0;
  bool _playing = false;
  bool _finished = false;
  Timer? _timer;
  DateTime? _sessionStart;
  int _selectedSample = -1; // -1 = custom

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _loadSample(int index) {
    _stop();
    setState(() {
      _selectedSample = index;
      _textController.text = SpeedReaderService.sampleTexts[index];
      _tokens = [];
      _finished = false;
    });
  }

  void _prepare() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _stop();
    setState(() {
      _tokens = _service.tokenize(text, _mode);
      _currentIndex = 0;
      _finished = false;
    });
  }

  void _play() {
    if (_tokens.isEmpty) _prepare();
    if (_tokens.isEmpty) return;
    if (_finished) {
      setState(() {
        _currentIndex = 0;
        _finished = false;
      });
    }

    final interval = Duration(milliseconds: (60000 / _wpm).round());
    _sessionStart ??= DateTime.now();

    setState(() => _playing = true);
    _timer = Timer.periodic(interval, (_) {
      if (_currentIndex >= _tokens.length - 1) {
        _finishSession();
        return;
      }
      setState(() => _currentIndex++);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _playing = false);
  }

  void _stop() {
    _timer?.cancel();
    _sessionStart = null;
    setState(() {
      _playing = false;
      _currentIndex = 0;
      _finished = false;
    });
  }

  void _finishSession() {
    _timer?.cancel();
    final duration = DateTime.now().difference(_sessionStart!);
    final wordCount = _textController.text.trim().split(RegExp(r'\s+')).length;
    _service.addSession(ReadingSession(
      timestamp: DateTime.now(),
      wordCount: wordCount,
      wpm: _wpm,
      duration: duration,
    ));
    setState(() {
      _playing = false;
      _finished = true;
      _sessionStart = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTokens = _tokens.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Reader'),
        actions: [
          if (_service.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'Stats',
              onPressed: _showStats,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Sample texts ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sample Texts',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        SpeedReaderService.sampleTitles.length,
                        (i) => ChoiceChip(
                          label: Text(SpeedReaderService.sampleTitles[i]),
                          selected: _selectedSample == i,
                          onSelected: (_) => _loadSample(i),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Text input ──
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Paste or type your text',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _stop();
                    _textController.clear();
                    setState(() {
                      _tokens = [];
                      _selectedSample = -1;
                    });
                  },
                ),
              ),
              onChanged: (_) => setState(() => _selectedSample = -1),
            ),
            const SizedBox(height: 12),

            // ── Settings ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Speed: ',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text('$_wpm WPM',
                            style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: _wpm.toDouble(),
                      min: 100,
                      max: 1000,
                      divisions: 18,
                      label: '$_wpm WPM',
                      onChanged: _playing
                          ? null
                          : (v) => setState(() => _wpm = v.round()),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Mode: ',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        ...SpeedReadMode.values.map((m) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(m.label),
                                selected: _mode == m,
                                onSelected: _playing
                                    ? null
                                    : (_) {
                                        setState(() => _mode = m);
                                        if (hasTokens) _prepare();
                                      },
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Display area ──
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: hasTokens
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _tokens[_currentIndex],
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_currentIndex + 1} / ${_tokens.length}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (_currentIndex + 1) / _tokens.length,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    )
                  : Text(
                      _finished ? '✅ Done!' : 'Enter text and press Start',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: Colors.grey[500]),
                    ),
            ),
            const SizedBox(height: 16),

            // ── Controls ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.stop),
                  onPressed: hasTokens ? _stop : null,
                  tooltip: 'Stop',
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  iconSize: 40,
                  icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                  onPressed: _textController.text.trim().isNotEmpty
                      ? (_playing ? _pause : _play)
                      : null,
                  tooltip: _playing ? 'Pause' : 'Start',
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  icon: const Icon(Icons.skip_next),
                  onPressed: hasTokens && !_playing
                      ? () {
                          if (_currentIndex < _tokens.length - 1) {
                            setState(() => _currentIndex++);
                          }
                        }
                      : null,
                  tooltip: 'Next',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Quick stats ──
            if (_service.history.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statChip('Sessions', '${_service.history.length}',
                          Icons.history),
                      _statChip('Avg WPM', '${_service.averageWpm}',
                          Icons.speed),
                      _statChip('Words Read', '${_service.totalWordsRead}',
                          Icons.menu_book),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  void _showStats() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reading History',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._service.history.take(10).map((s) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    child: Text('${s.wpm}',
                        style: const TextStyle(fontSize: 11)),
                  ),
                  title: Text('${s.wordCount} words @ ${s.wpm} WPM'),
                  subtitle: Text(
                    '${s.duration.inSeconds}s • ${s.timestamp.hour.toString().padLeft(2, '0')}:${s.timestamp.minute.toString().padLeft(2, '0')}',
                  ),
                )),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  _service.clearHistory();
                  Navigator.pop(ctx);
                  setState(() {});
                },
                child: const Text('Clear History'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
