import 'package:flutter/material.dart';
import '../../models/vocab_entry.dart';
import '../../core/services/vocabulary_builder_service.dart';
import '../../core/services/screen_persistence.dart';

/// Vocabulary Builder Screen — 4-tab UI for building vocabulary.
///
/// Tabs:
///   Words: Browse, search, filter vocabulary list
///   Add: Form to add new words
///   Quiz: Interactive flashcard quiz
///   Stats: Mastery breakdown, accuracy, progress
class VocabularyBuilderScreen extends StatefulWidget {
  const VocabularyBuilderScreen({super.key});

  @override
  State<VocabularyBuilderScreen> createState() =>
      _VocabularyBuilderScreenState();
}

class _VocabularyBuilderScreenState extends State<VocabularyBuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = VocabularyBuilderService();
  final _persistence = ScreenPersistence<VocabEntry>(
    storageKey: 'vocabulary_words',
    toJson: (e) => e.toJson(),
    fromJson: VocabEntry.fromJson,
  );

  String _searchQuery = '';
  MasteryLevel? _filterMastery;
  PartOfSpeech? _filterPos;

  // Add-tab form state
  final _wordController = TextEditingController();
  final _definitionController = TextEditingController();
  final _exampleController = TextEditingController();
  final _pronunciationController = TextEditingController();
  final _originController = TextEditingController();
  final _synonymsController = TextEditingController();
  final _tagsController = TextEditingController();
  final _notesController = TextEditingController();
  PartOfSpeech _selectedPos = PartOfSpeech.noun;

  // Quiz state
  QuizQuestion? _currentQuiz;
  String? _selectedAnswer;
  bool _answered = false;
  int _quizCorrect = 0;
  int _quizTotal = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final saved = await _persistence.load();
    setState(() {
      if (saved.isEmpty) {
        _service.loadAll(VocabularyBuilderService.sampleWords);
      } else {
        _service.loadAll(saved);
      }
    });
  }

  Future<void> _save() async {
    await _persistence.save(_service.words);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wordController.dispose();
    _definitionController.dispose();
    _exampleController.dispose();
    _pronunciationController.dispose();
    _originController.dispose();
    _synonymsController.dispose();
    _tagsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Filtered list ──
  List<VocabEntry> get _filtered {
    var list = _service.search(_searchQuery);
    if (_filterMastery != null) {
      list = list.where((w) => w.mastery == _filterMastery).toList();
    }
    if (_filterPos != null) {
      list = list.where((w) => w.partOfSpeech == _filterPos).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary Builder'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Words'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Add'),
            Tab(icon: Icon(Icons.quiz), text: 'Quiz'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWordsTab(theme),
          _buildAddTab(theme),
          _buildQuizTab(theme),
          _buildStatsTab(theme),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 1 — Words
  // ═══════════════════════════════════════════════════════════════
  Widget _buildWordsTab(ThemeData theme) {
    final items = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search words...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              ...MasteryLevel.values.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text('${m.emoji} ${m.label}'),
                      selected: _filterMastery == m,
                      onSelected: (sel) => setState(
                          () => _filterMastery = sel ? m : null),
                    ),
                  )),
              const SizedBox(width: 8),
              ...PartOfSpeech.values
                  .where((p) => p != PartOfSpeech.other)
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(p.label),
                          selected: _filterPos == p,
                          onSelected: (sel) =>
                              setState(() => _filterPos = sel ? p : null),
                        ),
                      )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No words found.'))
              : ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (ctx, i) => _wordCard(items[i], theme),
                ),
        ),
      ],
    );
  }

  Widget _wordCard(VocabEntry w, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: w.mastery.color.withOpacity(0.2),
          child: Text(w.mastery.emoji),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(w.word,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Text(w.partOfSpeech.label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey)),
          ],
        ),
        subtitle: Text(w.definition, maxLines: 1, overflow: TextOverflow.ellipsis),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.definition),
                if (w.exampleSentence != null) ...[
                  const SizedBox(height: 6),
                  Text('"${w.exampleSentence}"',
                      style: const TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey)),
                ],
                if (w.synonyms.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: w.synonyms
                        .map((s) => Chip(
                              label: Text(s,
                                  style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
                if (w.pronunciation != null) ...[
                  const SizedBox(height: 4),
                  Text('Pronunciation: ${w.pronunciation}',
                      style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                        'Reviewed ${w.timesReviewed}x · ${(w.accuracy * 100).toStringAsFixed(0)}% accuracy',
                        style: theme.textTheme.bodySmall),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                          w.isFavorite
                              ? Icons.star
                              : Icons.star_border,
                          color: w.isFavorite ? Colors.amber : null),
                      onPressed: () {
                        setState(() => _service.toggleFavorite(w.id));
                        _save();
                      },
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() => _service.removeWord(w.id));
                        _save();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 2 — Add
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAddTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _wordController,
            decoration: const InputDecoration(
                labelText: 'Word *', border: OutlineInputBorder()),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _definitionController,
            decoration: const InputDecoration(
                labelText: 'Definition *', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PartOfSpeech>(
            value: _selectedPos,
            decoration: const InputDecoration(
                labelText: 'Part of Speech', border: OutlineInputBorder()),
            items: PartOfSpeech.values
                .map((p) =>
                    DropdownMenuItem(value: p, child: Text(p.label)))
                .toList(),
            onChanged: (v) => setState(() => _selectedPos = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _exampleController,
            decoration: const InputDecoration(
                labelText: 'Example Sentence', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pronunciationController,
            decoration: const InputDecoration(
                labelText: 'Pronunciation', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _synonymsController,
            decoration: const InputDecoration(
                labelText: 'Synonyms (comma-separated)',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
                labelText: 'Notes', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Word'),
            onPressed: _addWord,
          ),
        ],
      ),
    );
  }

  void _addWord() {
    final word = _wordController.text.trim();
    final def = _definitionController.text.trim();
    if (word.isEmpty || def.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Word and definition are required.')));
      return;
    }
    final entry = VocabEntry(
      id: 'vocab_${DateTime.now().millisecondsSinceEpoch}',
      word: word,
      definition: def,
      partOfSpeech: _selectedPos,
      exampleSentence: _exampleController.text.trim().isEmpty
          ? null
          : _exampleController.text.trim(),
      pronunciation: _pronunciationController.text.trim().isEmpty
          ? null
          : _pronunciationController.text.trim(),
      synonyms: _synonymsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      tags: _tagsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );
    setState(() => _service.addWord(entry));
    _save();
    _wordController.clear();
    _definitionController.clear();
    _exampleController.clear();
    _pronunciationController.clear();
    _synonymsController.clear();
    _tagsController.clear();
    _notesController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$word" added to vocabulary!')));
    _tabController.animateTo(0);
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 3 — Quiz
  // ═══════════════════════════════════════════════════════════════
  Widget _buildQuizTab(ThemeData theme) {
    if (_service.totalWords < 4) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Add at least 4 words to start quizzing!',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_currentQuiz == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_quizTotal > 0) ...[
              Text('Session: $_quizCorrect / $_quizTotal correct',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(_quizTotal > 0 ? 'Next Question' : 'Start Quiz'),
              onPressed: () {
                setState(() {
                  _currentQuiz = _service.generateQuiz();
                  _selectedAnswer = null;
                  _answered = false;
                });
              },
            ),
          ],
        ),
      );
    }

    final quiz = _currentQuiz!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Session: $_quizCorrect / $_quizTotal',
              style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('What word matches this definition?',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 12),
                  Text(quiz.definition,
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...quiz.options.map((opt) {
            Color? bgColor;
            if (_answered) {
              if (opt.id == quiz.correctId) {
                bgColor = Colors.green.withOpacity(0.2);
              } else if (opt.id == _selectedAnswer) {
                bgColor = Colors.red.withOpacity(0.2);
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: bgColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _answered
                    ? null
                    : () {
                        final correct = opt.id == quiz.correctId;
                        setState(() {
                          _selectedAnswer = opt.id;
                          _answered = true;
                          _quizTotal++;
                          if (correct) _quizCorrect++;
                          _service.recordAnswer(quiz.correctId, correct);
                        });
                        _save();
                      },
                child: Text(opt.word,
                    style: const TextStyle(fontSize: 16)),
              ),
            );
          }),
          if (_answered) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() {
                  _currentQuiz = _service.generateQuiz();
                  _selectedAnswer = null;
                  _answered = false;
                });
              },
              child: const Text('Next Question'),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 4 — Stats
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatsTab(ThemeData theme) {
    final breakdown = _service.masteryBreakdown;
    final wotd = _service.wordOfTheDay();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Word of the day
          if (wotd != null)
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Word of the Day',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(wotd.word,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(wotd.definition,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _statRow('Total Words', '${_service.totalWords}'),
                  _statRow('Favorites', '${_service.favoriteCount}'),
                  _statRow('Mastered', '${_service.masteredCount}'),
                  _statRow('Overall Accuracy',
                      '${(_service.overallAccuracy * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mastery breakdown
          Text('Mastery Breakdown', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...MasteryLevel.values.map((m) {
            final count = breakdown[m] ?? 0;
            final pct = _service.totalWords > 0
                ? count / _service.totalWords
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${m.emoji} ${m.label}'),
                      const Spacer(),
                      Text('$count'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: m.color,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
