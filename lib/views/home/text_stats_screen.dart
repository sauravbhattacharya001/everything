import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/text_stats_service.dart';

/// Live text statistics analyzer — paste or type text and get instant
/// word count, character count, reading time, and frequency analysis.
class TextStatsScreen extends StatefulWidget {
  const TextStatsScreen({super.key});

  @override
  State<TextStatsScreen> createState() => _TextStatsScreenState();
}

class _TextStatsScreenState extends State<TextStatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _textController = TextEditingController();
  TextStatsResult _stats = TextStatsResult.empty();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _analyze() {
    setState(() {
      _stats = TextStatsService.analyze(_textController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Statistics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stats'),
            Tab(text: 'Words'),
            Tab(text: 'Letters'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_paste),
            tooltip: 'Paste from clipboard',
            onPressed: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text != null) {
                _textController.text = data!.text!;
                _analyze();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
            onPressed: () {
              _textController.clear();
              _analyze();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter or paste your text',
                hintText: 'Start typing or paste text here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              minLines: 3,
              onChanged: (_) => _analyze(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatsTab(context),
                _buildTopWordsTab(context),
                _buildTopLettersTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatRow(icon: Icons.text_fields, label: 'Characters', value: '${_stats.characters}'),
        _StatRow(icon: Icons.space_bar, label: 'Characters (no spaces)', value: '${_stats.charactersNoSpaces}'),
        _StatRow(icon: Icons.short_text, label: 'Words', value: '${_stats.words}'),
        _StatRow(icon: Icons.fingerprint, label: 'Unique words', value: '${_stats.uniqueWords}'),
        _StatRow(icon: Icons.format_align_left, label: 'Sentences', value: '${_stats.sentences}'),
        _StatRow(icon: Icons.view_headline, label: 'Paragraphs', value: '${_stats.paragraphs}'),
        _StatRow(icon: Icons.format_line_spacing, label: 'Lines', value: '${_stats.lines}'),
        const Divider(height: 32),
        _StatRow(icon: Icons.menu_book, label: 'Reading time', value: _stats.readingTime),
        _StatRow(icon: Icons.record_voice_over, label: 'Speaking time', value: _stats.speakingTime),
        const Divider(height: 32),
        _StatRow(icon: Icons.straighten, label: 'Avg word length', value: '${_stats.avgWordLength} chars'),
        _StatRow(icon: Icons.format_size, label: 'Avg sentence length', value: '${_stats.avgSentenceLength} words'),
        if (_stats.longestWord.isNotEmpty)
          _StatRow(icon: Icons.text_rotation_none, label: 'Longest word', value: _stats.longestWord),
      ],
    );
  }

  Widget _buildTopWordsTab(BuildContext context) {
    final theme = Theme.of(context);
    if (_stats.topWords.isEmpty) {
      return const Center(child: Text('Type some text to see word frequency'));
    }
    final maxCount = _stats.topWords.first.value;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stats.topWords.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Top Words', style: theme.textTheme.titleMedium),
          );
        }
        final entry = _stats.topWords[index - 1];
        final fraction = maxCount > 0 ? entry.value / maxCount : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text('${index}.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
              Expanded(
                flex: 2,
                child: Text(entry.key,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                flex: 3,
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 30,
                child: Text('${entry.value}',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopLettersTab(BuildContext context) {
    final theme = Theme.of(context);
    if (_stats.topLetters.isEmpty) {
      return const Center(child: Text('Type some text to see letter frequency'));
    }
    final maxCount = _stats.topLetters.first.value;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stats.topLetters.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Letter Frequency', style: theme.textTheme.titleMedium),
          );
        }
        final entry = _stats.topLetters[index - 1];
        final fraction = maxCount > 0 ? entry.value / maxCount : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(entry.key.toUpperCase(),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 3,
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                child: Text('${entry.value}',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyLarge),
          ),
          Text(value,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
