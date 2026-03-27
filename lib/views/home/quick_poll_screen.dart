import 'package:flutter/material.dart';
import '../../core/services/quick_poll_service.dart';

/// Quick Poll screen — create simple polls and vote on them.
///
/// Useful for personal decision-making or quick group votes.
class QuickPollScreen extends StatefulWidget {
  const QuickPollScreen({super.key});

  @override
  State<QuickPollScreen> createState() => _QuickPollScreenState();
}

class _QuickPollScreenState extends State<QuickPollScreen> {
  final _service = QuickPollService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _showCreateDialog() {
    final questionCtrl = TextEditingController();
    final optionCtrls = [TextEditingController(), TextEditingController()];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Poll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    hintText: 'What should we do?',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                ...List.generate(optionCtrls.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: optionCtrls[i],
                          decoration: InputDecoration(
                            labelText: 'Option ${i + 1}',
                          ),
                        ),
                      ),
                      if (optionCtrls.length > 2)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setDialogState(() {
                              optionCtrls[i].dispose();
                              optionCtrls.removeAt(i);
                            });
                          },
                        ),
                    ],
                  ),
                )),
                if (optionCtrls.length < 8)
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Option'),
                    onPressed: () {
                      setDialogState(() => optionCtrls.add(TextEditingController()));
                    },
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
              onPressed: () async {
                final q = questionCtrl.text.trim();
                final opts = optionCtrls
                    .map((c) => c.text.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();
                if (q.isEmpty || opts.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Need a question and at least 2 options')),
                  );
                  return;
                }
                await _service.createPoll(q, opts);
                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Poll')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _service.polls.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.poll, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No polls yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to create one',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _service.polls.length,
                  itemBuilder: (ctx, i) => _PollCard(
                    poll: _service.polls[i],
                    onVote: (optIdx) async {
                      await _service.vote(_service.polls[i].id, optIdx);
                      setState(() {});
                    },
                    onClose: () async {
                      await _service.closePoll(_service.polls[i].id);
                      setState(() {});
                    },
                    onDelete: () async {
                      await _service.deletePoll(_service.polls[i].id);
                      setState(() {});
                    },
                    onReset: () async {
                      await _service.resetVotes(_service.polls[i].id);
                      setState(() {});
                    },
                  ),
                ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final Poll poll;
  final ValueChanged<int> onVote;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onReset;

  const _PollCard({
    required this.poll,
    required this.onVote,
    required this.onClose,
    required this.onDelete,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    poll.question,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (poll.isClosed)
                  Chip(
                    label: const Text('Closed'),
                    backgroundColor: Colors.grey[300],
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'close':
                        onClose();
                      case 'reset':
                        onReset();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    if (!poll.isClosed)
                      const PopupMenuItem(value: 'close', child: Text('Close Poll')),
                    const PopupMenuItem(value: 'reset', child: Text('Reset Votes')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Options
            ...List.generate(poll.options.length, (i) {
              final pct = poll.percentFor(i);
              final isWinner = poll.isClosed && poll.winningIndex == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: poll.isClosed ? null : () => onVote(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isWinner ? theme.colorScheme.primary : Colors.grey[300]!,
                        width: isWinner ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Stack(
                        children: [
                          // Progress bar background
                          if (poll.totalVotes > 0)
                            FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(
                                height: 44,
                                color: (isWinner
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.primaryContainer)
                                    .withOpacity(0.3),
                              ),
                            ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                if (!poll.isClosed)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.radio_button_unchecked,
                                      size: 20,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                if (isWinner)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    poll.options[i],
                                    style: TextStyle(
                                      fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (poll.totalVotes > 0)
                                  Text(
                                    '${poll.votesFor(i)} (${(pct * 100).toStringAsFixed(0)}%)',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            // Footer
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${poll.totalVotes} vote${poll.totalVotes == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
