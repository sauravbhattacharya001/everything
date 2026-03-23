import 'package:flutter/material.dart';

/// A text analysis utility that provides word count, character count,
/// sentence count, paragraph count, reading time, and top word frequencies.
class TextAnalyzerScreen extends StatefulWidget {
  const TextAnalyzerScreen({super.key});

  @override
  State<TextAnalyzerScreen> createState() => _TextAnalyzerScreenState();
}

class _TextAnalyzerScreenState extends State<TextAnalyzerScreen> {
  final _controller = TextEditingController();
  _TextStats _stats = _TextStats.empty();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_analyze);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyze() {
    setState(() {
      _stats = _TextStats.from(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Analyzer'),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear',
              onPressed: () => _controller.clear(),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Paste or type text here…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid
            _StatsGrid(stats: _stats),

            const SizedBox(height: 16),

            // Top words
            if (_stats.topWords.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Top Words',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _stats.topWords.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final entry = _stats.topWords[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(entry.key),
                      trailing: Text(
                        '${entry.value}×',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text(
                    'Start typing to see analysis',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stats widget ──

class _StatsGrid extends StatelessWidget {
  final _TextStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatChip(label: 'Words', value: '${stats.words}', icon: Icons.text_fields),
        _StatChip(label: 'Characters', value: '${stats.characters}', icon: Icons.abc),
        _StatChip(label: 'Sentences', value: '${stats.sentences}', icon: Icons.short_text),
        _StatChip(label: 'Paragraphs', value: '${stats.paragraphs}', icon: Icons.subject),
        _StatChip(label: 'Reading', value: stats.readingTime, icon: Icons.schedule),
        _StatChip(label: 'Speaking', value: stats.speakingTime, icon: Icons.mic),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// ── Analysis model ──

class _TextStats {
  final int words;
  final int characters;
  final int sentences;
  final int paragraphs;
  final String readingTime;
  final String speakingTime;
  final List<MapEntry<String, int>> topWords;

  const _TextStats({
    required this.words,
    required this.characters,
    required this.sentences,
    required this.paragraphs,
    required this.readingTime,
    required this.speakingTime,
    required this.topWords,
  });

  factory _TextStats.empty() => const _TextStats(
        words: 0,
        characters: 0,
        sentences: 0,
        paragraphs: 0,
        readingTime: '0s',
        speakingTime: '0s',
        topWords: [],
      );

  factory _TextStats.from(String text) {
    if (text.trim().isEmpty) return _TextStats.empty();

    final chars = text.length;

    // Words: split on whitespace, filter empties
    final wordList = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final wordCount = wordList.length;

    // Sentences: split on .!? followed by space or end
    final sentenceCount =
        RegExp(r'[.!?]+(\s|$)').allMatches(text).length.clamp(wordCount > 0 ? 1 : 0, 99999);

    // Paragraphs: split on double newline
    final paraCount = text
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .length;

    // Reading time (~238 wpm) and speaking time (~150 wpm)
    String _formatTime(double minutes) {
      if (minutes < 1) return '${(minutes * 60).round()}s';
      if (minutes < 60) return '${minutes.round()} min';
      return '${(minutes / 60).floor()}h ${(minutes % 60).round()}m';
    }

    final readTime = _formatTime(wordCount / 238);
    final speakTime = _formatTime(wordCount / 150);

    // Top words (lowercase, ≥2 chars, skip common stop words)
    const stopWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to',
      'for', 'of', 'is', 'it', 'that', 'this', 'was', 'are', 'be',
      'has', 'had', 'have', 'with', 'as', 'by', 'not', 'from', 'we',
      'he', 'she', 'they', 'you', 'i', 'my', 'your', 'his', 'her',
      'its', 'our', 'if', 'so', 'do', 'no', 'can', 'will', 'all',
    };
    final freq = <String, int>{};
    for (final w in wordList) {
      final clean = w.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (clean.length >= 2 && !stopWords.contains(clean)) {
        freq[clean] = (freq[clean] ?? 0) + 1;
      }
    }
    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return _TextStats(
      words: wordCount,
      characters: chars,
      sentences: sentenceCount,
      paragraphs: paraCount,
      readingTime: readTime,
      speakingTime: speakTime,
      topWords: sorted.take(10).toList(),
    );
  }
}
