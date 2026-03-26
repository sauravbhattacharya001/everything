import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/countdown_timer_service.dart';

/// A countdown timer screen that tracks time remaining to named events.
class CountdownTimerScreen extends StatefulWidget {
  const CountdownTimerScreen({super.key});

  @override
  State<CountdownTimerScreen> createState() => _CountdownTimerScreenState();
}

class _CountdownTimerScreenState extends State<CountdownTimerScreen> {
  final List<CountdownEntry> _entries = [];
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh every second so countdowns stay live.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _addCountdown() async {
    final nameCtrl = TextEditingController();
    String? selectedCategory;

    final result = await showDialog<CountdownEntry>(
      context: context,
      builder: (ctx) {
        DateTime pickedDate = DateTime.now().add(const Duration(days: 7));
        TimeOfDay pickedTime = TimeOfDay.midnight;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('New Countdown'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category presets
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: CountdownTimerService.presets.map((p) {
                        final selected = selectedCategory == p;
                        return ChoiceChip(
                          label: Text(p),
                          selected: selected,
                          onSelected: (v) {
                            setDialogState(() {
                              selectedCategory = v ? p : null;
                              if (v && nameCtrl.text.isEmpty) {
                                nameCtrl.text = p;
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Event Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}',
                      ),
                      subtitle: Text(pickedTime.format(ctx)),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: pickedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (d != null) {
                          setDialogState(() => pickedDate = d);
                        }
                        if (!ctx.mounted) return;
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: pickedTime,
                        );
                        if (t != null) {
                          setDialogState(() => pickedTime = t);
                        }
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
                  onPressed: () {
                    final name = nameCtrl.text.trim().isEmpty
                        ? 'Countdown ${_entries.length + 1}'
                        : nameCtrl.text.trim();
                    final target = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    Navigator.pop(
                      ctx,
                      CountdownEntry(
                        name: name,
                        targetDate: target,
                        category: selectedCategory,
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _entries.add(result));
    }
  }

  void _removeEntry(int index) {
    setState(() => _entries.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sort: active first (nearest deadline), then expired.
    final sorted = List<CountdownEntry>.from(_entries)
      ..sort((a, b) {
        if (a.isExpired != b.isExpired) return a.isExpired ? 1 : -1;
        return a.targetDate.compareTo(b.targetDate);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Countdown Timer'),
        actions: [
          if (_entries.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_entries.where((e) => !e.isExpired).length} active',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
        ],
      ),
      body: _entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 64, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text('No countdowns yet',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Tap + to count down to an event'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final entry = sorted[index];
                return _CountdownCard(
                  entry: entry,
                  onDelete: () {
                    final realIndex = _entries.indexOf(entry);
                    if (realIndex >= 0) _removeEntry(realIndex);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCountdown,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final CountdownEntry entry;
  final VoidCallback onDelete;

  const _CountdownCard({required this.entry, required this.onDelete});

  IconData _categoryIcon(String? cat) {
    switch (cat) {
      case 'Birthday':
        return Icons.cake;
      case 'Vacation':
        return Icons.flight;
      case 'Deadline':
        return Icons.assignment_late;
      case 'Holiday':
        return Icons.celebration;
      case 'Wedding':
        return Icons.favorite;
      case 'Exam':
        return Icons.school;
      case 'Launch Day':
        return Icons.rocket_launch;
      case 'New Year':
        return Icons.auto_awesome;
      default:
        return Icons.timer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expired = entry.isExpired;
    final remaining = entry.remaining;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _categoryIcon(entry.category),
                  color: expired
                      ? theme.disabledColor
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration:
                              expired ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text(
                        '${entry.targetDate.year}-${entry.targetDate.month.toString().padLeft(2, '0')}-${entry.targetDate.day.toString().padLeft(2, '0')} ${entry.targetDate.hour.toString().padLeft(2, '0')}:${entry.targetDate.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: entry.progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: expired ? Colors.green : null,
              ),
            ),
            const SizedBox(height: 12),

            // Countdown display
            Center(
              child: expired
                  ? Text(
                      '🎉 Arrived!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TimeUnit(
                            value: remaining.inDays.toString(), label: 'days'),
                        _TimeUnit(
                            value: (remaining.inHours % 24).toString(),
                            label: 'hrs'),
                        _TimeUnit(
                            value: (remaining.inMinutes % 60).toString(),
                            label: 'min'),
                        _TimeUnit(
                            value: (remaining.inSeconds % 60).toString(),
                            label: 'sec'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final String value;
  final String label;

  const _TimeUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            value.padLeft(2, '0'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
