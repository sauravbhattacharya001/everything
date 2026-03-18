import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/services/random_decision_service.dart';
import '../../models/decision_list.dart';

/// Random Decision Maker — create option lists, spin to decide, track history.
class RandomDecisionScreen extends StatefulWidget {
  const RandomDecisionScreen({super.key});

  @override
  State<RandomDecisionScreen> createState() => _RandomDecisionScreenState();
}

class _RandomDecisionScreenState extends State<RandomDecisionScreen>
    with TickerProviderStateMixin {
  final RandomDecisionService _service = RandomDecisionService();
  DecisionList? _selectedList;
  DecisionResult? _lastResult;
  bool _isSpinning = false;
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    );
    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isSpinning = false);
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_selectedList == null || _selectedList!.options.isEmpty) return;
    setState(() {
      _isSpinning = true;
      _lastResult = _service.spin(_selectedList!.id);
      _selectedList =
          _service.lists.where((l) => l.id == _selectedList!.id).first;
    });
    _spinController.reset();
    _spinController.forward();
  }

  void _showCreateListDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Decision List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'List name',
                hintText: 'e.g., Where to eat tonight?',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('Or start from a template:',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: RandomDecisionService.templates.keys.map((name) {
                return ActionChip(
                  label: Text(name, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    final list = _service.createFromTemplate(name);
                    Navigator.pop(ctx);
                    setState(() => _selectedList = list);
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              final list = _service.createList(
                title: titleController.text.trim(),
              );
              Navigator.pop(ctx);
              setState(() => _selectedList = list);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddOptionDialog() {
    if (_selectedList == null) return;
    final optionController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Option'),
        content: TextField(
          controller: optionController,
          decoration: const InputDecoration(
            labelText: 'Option',
            hintText: 'e.g., Sushi',
          ),
          autofocus: true,
          onSubmitted: (_) {
            if (optionController.text.trim().isEmpty) return;
            _service.addOption(_selectedList!.id, optionController.text.trim());
            Navigator.pop(ctx);
            setState(() {
              _selectedList = _service.lists
                  .where((l) => l.id == _selectedList!.id)
                  .first;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (optionController.text.trim().isEmpty) return;
              _service.addOption(
                  _selectedList!.id, optionController.text.trim());
              Navigator.pop(ctx);
              setState(() {
                _selectedList = _service.lists
                    .where((l) => l.id == _selectedList!.id)
                    .first;
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showHistorySheet() {
    if (_selectedList == null) return;
    final history = _service.getHistory(_selectedList!.id);
    final stats = _service.getFrequencyStats(_selectedList!.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Decision History',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (history.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _service.clearHistory(_selectedList!.id);
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedList = _service.lists
                              .where((l) => l.id == _selectedList!.id)
                              .first;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            if (stats.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: stats.entries.map((e) {
                    return Chip(
                      label: Text('${e.key}: ${e.value}x',
                          style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.deepPurple.withAlpha(25),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
            ],
            Expanded(
              child: history.isEmpty
                  ? const Center(
                      child: Text('No decisions yet!\nSpin the wheel 🎰',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: history.length,
                      itemBuilder: (_, i) {
                        final r = history[i];
                        final ago = DateTime.now().difference(r.decidedAt);
                        String timeStr;
                        if (ago.inMinutes < 1) {
                          timeStr = 'just now';
                        } else if (ago.inHours < 1) {
                          timeStr = '${ago.inMinutes}m ago';
                        } else if (ago.inDays < 1) {
                          timeStr = '${ago.inHours}h ago';
                        } else {
                          timeStr = '${ago.inDays}d ago';
                        }
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.withAlpha(25),
                            child: Text('${i + 1}',
                                style: const TextStyle(fontSize: 12)),
                          ),
                          title: Text(r.optionText),
                          trailing: Text(timeStr,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lists = _service.lists;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Random Decision Maker'),
        actions: [
          if (_selectedList != null)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Decision History',
              onPressed: _showHistorySheet,
            ),
          if (_selectedList != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'All Lists',
              onPressed: () => setState(() {
                _selectedList = null;
                _lastResult = null;
              }),
            ),
        ],
      ),
      body: _selectedList == null
          ? _buildListsView(lists, theme)
          : _buildDecisionView(theme),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _selectedList == null ? _showCreateListDialog : _showAddOptionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListsView(List<DecisionList> lists, ThemeData theme) {
    if (lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.casino, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("Can't decide?",
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Create a list and let fate choose!',
                style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showCreateListDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First List'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lists.length,
      itemBuilder: (_, i) {
        final list = lists[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.withAlpha(25),
              child: Text(list.emoji ?? '🎲', style: const TextStyle(fontSize: 20)),
            ),
            title: Text(list.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${list.options.length} options · ${list.history.length} decisions',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    _service.deleteList(list.id);
                    setState(() {});
                  },
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => setState(() {
              _selectedList = list;
              _lastResult = null;
            }),
          ),
        );
      },
    );
  }

  Widget _buildDecisionView(ThemeData theme) {
    final list = _selectedList!;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            list.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),

        // Spin result area
        AnimatedBuilder(
          animation: _spinAnimation,
          builder: (_, __) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _lastResult != null
                      ? [
                          Colors.deepPurple.withAlpha(25),
                          Colors.deepPurple.withAlpha(50)
                        ]
                      : [Colors.grey.withAlpha(15), Colors.grey.withAlpha(25)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _lastResult != null
                      ? Colors.deepPurple.withAlpha(75)
                      : Colors.grey.withAlpha(50),
                ),
              ),
              child: Column(
                children: [
                  Transform.rotate(
                    angle: _isSpinning ? _spinAnimation.value * 4 * pi : 0,
                    child: Text(
                      _isSpinning ? '🎰' : (_lastResult != null ? '🎯' : '🎲'),
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSpinning
                        ? 'Deciding...'
                        : (_lastResult?.optionText ?? 'Tap spin to decide!'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _lastResult != null
                          ? Colors.deepPurple
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Spin button
        FilledButton.icon(
          onPressed:
              list.options.isEmpty || _isSpinning ? null : _spin,
          icon: const Icon(Icons.casino),
          label: Text(list.options.isEmpty
              ? 'Add options first'
              : (_isSpinning ? 'Spinning...' : 'Spin!')),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),

        const SizedBox(height: 16),
        const Divider(),

        // Options list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text('Options (${list.options.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
            ],
          ),
        ),
        Expanded(
          child: list.options.isEmpty
              ? Center(
                  child: Text('No options yet — tap + to add some!',
                      style: TextStyle(color: Colors.grey[500])))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: list.options.length,
                  onReorder: (oldIdx, newIdx) {
                    if (newIdx > oldIdx) newIdx--;
                    final opts = List<DecisionOption>.from(list.options);
                    final item = opts.removeAt(oldIdx);
                    opts.insert(newIdx, item);
                    setState(() {
                      _selectedList = list.copyWith(options: opts);
                    });
                  },
                  itemBuilder: (_, i) {
                    final option = list.options[i];
                    final isWinner =
                        _lastResult?.optionId == option.id && !_isSpinning;
                    return Card(
                      key: ValueKey(option.id),
                      color:
                          isWinner ? Colors.deepPurple.withAlpha(25) : null,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      child: ListTile(
                        leading: isWinner
                            ? const Icon(Icons.stars,
                                color: Colors.deepPurple)
                            : const Icon(Icons.circle, size: 8),
                        title: Text(option.text),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (option.weight > 1)
                              Chip(
                                label: Text('${option.weight}x',
                                    style: const TextStyle(fontSize: 10)),
                                visualDensity: VisualDensity.compact,
                              ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _service.removeOption(list.id, option.id);
                                setState(() {
                                  _selectedList = _service.lists
                                      .where((l) => l.id == list.id)
                                      .first;
                                });
                              },
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
}

/// Wrapper to use [AnimatedBuilder] which is just [AnimatedWidget] in builder form.
/// Flutter's built-in AnimatedBuilder works the same way.
