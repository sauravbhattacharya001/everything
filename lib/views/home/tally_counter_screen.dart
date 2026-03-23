import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/tally_counter_service.dart';

/// A multi-counter tally screen with haptic feedback, targets, and presets.
class TallyCounterScreen extends StatefulWidget {
  const TallyCounterScreen({super.key});

  @override
  State<TallyCounterScreen> createState() => _TallyCounterScreenState();
}

class _TallyCounterScreenState extends State<TallyCounterScreen> {
  final List<TallyCounter> _counters = [TallyCounter(name: 'Counter 1')];

  void _addCounter() {
    showDialog(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        final targetCtrl = TextEditingController();
        final stepCtrl = TextEditingController(text: '1');
        return AlertDialog(
          title: const Text('New Counter'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preset chips
                Wrap(
                  spacing: 8,
                  children: TallyCounterService.presets.map((p) {
                    return ActionChip(
                      label: Text(p),
                      onPressed: () => nameCtrl.text = p,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Target (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stepCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Step',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim().isEmpty
                    ? 'Counter ${_counters.length + 1}'
                    : nameCtrl.text.trim();
                final target = int.tryParse(targetCtrl.text.trim());
                final step = int.tryParse(stepCtrl.text.trim()) ?? 1;
                setState(() {
                  _counters.add(TallyCounter(
                    name: name,
                    target: target,
                    step: step > 0 ? step : 1,
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeCounter(int index) {
    setState(() => _counters.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _counters.fold<int>(0, (sum, c) => sum + c.count);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tally Counter'),
        actions: [
          if (_counters.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'Total: $total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _counters.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 64, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text('No counters yet',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first counter'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _counters.length,
              itemBuilder: (context, index) {
                final counter = _counters[index];
                return _CounterCard(
                  counter: counter,
                  onIncrement: () {
                    HapticFeedback.lightImpact();
                    setState(() => counter.increment());
                  },
                  onDecrement: () {
                    HapticFeedback.lightImpact();
                    setState(() => counter.decrement());
                  },
                  onReset: () {
                    setState(() => counter.reset());
                  },
                  onDelete: () => _removeCounter(index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCounter,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  final TallyCounter counter;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onReset;
  final VoidCallback onDelete;

  const _CounterCard({
    required this.counter,
    required this.onIncrement,
    required this.onDecrement,
    required this.onReset,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = counter.progress;
    final reached = counter.targetReached;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    counter.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (counter.target != null)
                  Chip(
                    label: Text(
                      reached ? '🎉 Target!' : '/ ${counter.target}',
                      style: TextStyle(
                        color: reached ? Colors.green : null,
                        fontWeight: reached ? FontWeight.bold : null,
                      ),
                    ),
                    backgroundColor: reached
                        ? Colors.green.withValues(alpha: 0.1)
                        : null,
                  ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'reset') onReset();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'reset',
                      child: Text('Reset'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar (if target set)
            if (progress != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Counter display + buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: onDecrement,
                  icon: const Icon(Icons.remove),
                  iconSize: 32,
                ),
                const SizedBox(width: 24),
                Text(
                  '${counter.count}',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 24),
                IconButton.filled(
                  onPressed: onIncrement,
                  icon: const Icon(Icons.add),
                  iconSize: 32,
                ),
              ],
            ),

            // Step indicator
            if (counter.step > 1) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Step: ${counter.step}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
