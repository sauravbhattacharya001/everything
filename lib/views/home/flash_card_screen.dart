import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/flash_card_service.dart';

/// Flash Cards study screen with decks, SM-2 spaced repetition, and flip animation.
class FlashCardScreen extends StatefulWidget {
  const FlashCardScreen({super.key});

  @override
  State<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  static const _storageKey = 'flash_card_decks';
  List<FlashDeck> _decks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      setState(() => _decks = FlashCardService.decodeDecks(raw));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, FlashCardService.encodeDecks(_decks));
  }

  void _addDeck() {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Deck'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true),
            const SizedBox(height: 8),
            TextField(
                controller: descC,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameC.text.trim().isEmpty) return;
              setState(() {
                _decks.add(FlashCardService.createDeck(nameC.text.trim(),
                    description: descC.text.trim().isEmpty
                        ? null
                        : descC.text.trim()));
              });
              _save();
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _deleteDeck(int index) {
    final deck = _decks[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Deck?'),
        content: Text(
            'Delete "${deck.name}" and all ${deck.cards.length} cards? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _decks.removeAt(index));
              _save();
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openDeck(FlashDeck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DeckDetailScreen(
          deck: deck,
          onSave: () {
            _save();
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Flash Cards')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDeck,
        child: const Icon(Icons.add),
      ),
      body: _decks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.style, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No decks yet',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
                  const SizedBox(height: 8),
                  const Text('Tap + to create your first deck'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _decks.length,
              itemBuilder: (ctx, i) {
                final deck = _decks[i];
                final stats = FlashCardService.getStats(deck);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${stats['total']}'),
                    ),
                    title: Text(deck.name),
                    subtitle: Text(deck.description ??
                        '${stats['due']} due · ${stats['mastered']} mastered'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (stats['due'] as int > 0)
                          Chip(
                            label: Text('${stats['due']} due'),
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                          ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteDeck(i),
                        ),
                      ],
                    ),
                    onTap: () => _openDeck(deck),
                  ),
                );
              },
            ),
    );
  }
}

/// Detail screen for a single deck — manage cards and study.
class _DeckDetailScreen extends StatefulWidget {
  final FlashDeck deck;
  final VoidCallback onSave;

  const _DeckDetailScreen({required this.deck, required this.onSave});

  @override
  State<_DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<_DeckDetailScreen> {
  void _addCard() {
    final qC = TextEditingController();
    final aC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: qC,
                decoration: const InputDecoration(labelText: 'Question'),
                autofocus: true,
                maxLines: 3),
            const SizedBox(height: 8),
            TextField(
                controller: aC,
                decoration: const InputDecoration(labelText: 'Answer'),
                maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (qC.text.trim().isEmpty || aC.text.trim().isEmpty) return;
              setState(() {
                FlashCardService.addCard(
                    widget.deck, qC.text.trim(), aC.text.trim());
              });
              widget.onSave();
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editCard(FlashCard card) {
    final qC = TextEditingController(text: card.question);
    final aC = TextEditingController(text: card.answer);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: qC,
                decoration: const InputDecoration(labelText: 'Question'),
                maxLines: 3),
            const SizedBox(height: 8),
            TextField(
                controller: aC,
                decoration: const InputDecoration(labelText: 'Answer'),
                maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (qC.text.trim().isEmpty || aC.text.trim().isEmpty) return;
              setState(() {
                card.question = qC.text.trim();
                card.answer = aC.text.trim();
              });
              widget.onSave();
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCard(FlashCard card) {
    setState(() => widget.deck.cards.remove(card));
    widget.onSave();
  }

  void _startStudy() {
    final due = FlashCardService.getDueCards(widget.deck);
    if (due.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cards due for review!')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StudyScreen(
          cards: due,
          deckName: widget.deck.name,
          onComplete: () {
            widget.onSave();
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = FlashCardService.getStats(widget.deck);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: [
          if (widget.deck.cards.isNotEmpty)
            FilledButton.icon(
              onPressed: _startStudy,
              icon: const Icon(Icons.play_arrow),
              label: Text('Study (${stats['due']})'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip('Total', '${stats['total']}', Icons.style),
                _StatChip('Due', '${stats['due']}', Icons.schedule),
                _StatChip(
                    'Mastered', '${stats['mastered']}', Icons.check_circle),
                _StatChip(
                    'Mastery', '${stats['masteryPercent']}%', Icons.trending_up),
              ],
            ),
          ),
          // Card list
          Expanded(
            child: widget.deck.cards.isEmpty
                ? Center(
                    child: Text('No cards yet. Tap + to add one.',
                        style: TextStyle(color: theme.colorScheme.outline)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.deck.cards.length,
                    itemBuilder: (ctx, i) {
                      final card = widget.deck.cards[i];
                      return Card(
                        child: ListTile(
                          title: Text(card.question, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(card.answer, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: theme.colorScheme.outline)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (card.repetitions >= 3)
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                              IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _editCard(card)),
                              IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _deleteCard(card)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// Study session with flip-to-reveal cards and quality rating.
class _StudyScreen extends StatefulWidget {
  final List<FlashCard> cards;
  final String deckName;
  final VoidCallback onComplete;

  const _StudyScreen({
    required this.cards,
    required this.deckName,
    required this.onComplete,
  });

  @override
  State<_StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<_StudyScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _showAnswer = false;
  int _correct = 0;
  int _incorrect = 0;

  void _flip() => setState(() => _showAnswer = !_showAnswer);

  void _rate(int quality) {
    widget.cards[_index].review(quality);
    if (quality >= 3) {
      _correct++;
    } else {
      _incorrect++;
    }
    if (_index + 1 < widget.cards.length) {
      setState(() {
        _index++;
        _showAnswer = false;
      });
    } else {
      widget.onComplete();
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Complete! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reviewed ${widget.cards.length} cards'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [
                  Text('$_correct',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const Text('Correct'),
                ]),
                Column(children: [
                  Text('$_incorrect',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red)),
                  const Text('Again'),
                ]),
              ],
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = widget.cards[_index];
    final progress = (_index + 1) / widget.cards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
                child: Text('${_index + 1}/${widget.cards.length}',
                    style: theme.textTheme.titleSmall)),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress),
          Expanded(
            child: GestureDetector(
              onTap: _showAnswer ? null : _flip,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey('${_index}_$_showAnswer'),
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(32),
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 200),
                    decoration: BoxDecoration(
                      color: _showAnswer
                          ? theme.colorScheme.secondaryContainer
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showAnswer ? 'ANSWER' : 'QUESTION',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _showAnswer
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onPrimaryContainer,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showAnswer ? card.answer : card.question,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: _showAnswer
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onPrimaryContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (!_showAnswer) ...[
                          const SizedBox(height: 24),
                          Text('Tap to reveal',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withOpacity(0.6))),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Rating buttons
          if (_showAnswer)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style:
                          FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => _rate(1),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Again', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('< 1 min', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange),
                      onPressed: () => _rate(3),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Hard', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('< 10 min', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () => _rate(4),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Good', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('1 day', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue),
                      onPressed: () => _rate(5),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Easy', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('4 days', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 80),
        ],
      ),
    );
  }
}
