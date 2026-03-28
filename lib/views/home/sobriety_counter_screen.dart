import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/sobriety_counter_service.dart';

/// Track sobriety streaks with milestones, multiple trackers, and motivation.
class SobrietyCounterScreen extends StatefulWidget {
  const SobrietyCounterScreen({super.key});

  @override
  State<SobrietyCounterScreen> createState() => _SobrietyCounterScreenState();
}

class _SobrietyCounterScreenState extends State<SobrietyCounterScreen> {
  static const _storageKey = 'sobriety_trackers';
  List<SobrietyTracker> _trackers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() {
        _trackers = list
            .map((e) => SobrietyTracker.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_trackers.map((t) => t.toJson()).toList()),
    );
  }

  void _addTracker() {
    final labelCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String category = SobrietyCounterService.presetCategories.first;
    DateTime startDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Sobriety Tracker'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'e.g. "Quit smoking"',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: SobrietyCounterService.presetCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => category = v);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date'),
                  subtitle: Text(
                    '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => startDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'Your motivation...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                final label = labelCtrl.text.trim();
                if (label.isEmpty) return;
                setState(() {
                  _trackers.add(SobrietyTracker(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    label: label,
                    category: category,
                    startDate: startDate,
                    note: noteCtrl.text.trim().isEmpty
                        ? null
                        : noteCtrl.text.trim(),
                  ));
                });
                _save();
                Navigator.pop(ctx);
              },
              child: const Text('Start Tracking'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTracker(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tracker?'),
        content: Text(
          'Remove "${_trackers[index].label}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              setState(() => _trackers.removeAt(index));
              _save();
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _resetTracker(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Timer?'),
        content: const Text(
          'This will reset your counter to today. Your previous streak will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                final old = _trackers[index];
                _trackers[index] = SobrietyTracker(
                  id: old.id,
                  label: old.label,
                  category: old.category,
                  startDate: DateTime.now(),
                  note: old.note,
                );
              });
              _save();
              Navigator.pop(ctx);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sobriety Counter')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTracker,
        child: const Icon(Icons.add),
      ),
      body: _trackers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.spa, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'No trackers yet',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to start tracking your journey',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '"${SobrietyCounterService.quoteOfTheDay()}"',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _trackers.length,
              itemBuilder: (context, index) {
                final tracker = _trackers[index];
                final stats = SobrietyCounterService.calculate(
                  tracker.startDate,
                );
                return _TrackerCard(
                  tracker: tracker,
                  stats: stats,
                  onReset: () => _resetTracker(index),
                  onDelete: () => _deleteTracker(index),
                );
              },
            ),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  final SobrietyTracker tracker;
  final SobrietyStats stats;
  final VoidCallback onReset;
  final VoidCallback onDelete;

  const _TrackerCard({
    required this.tracker,
    required this.stats,
    required this.onReset,
    required this.onDelete,
  });

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Alcohol':
        return Icons.local_bar;
      case 'Smoking':
        return Icons.smoke_free;
      case 'Caffeine':
        return Icons.coffee;
      case 'Sugar':
        return Icons.cake;
      case 'Social Media':
        return Icons.phone_android;
      case 'Gambling':
        return Icons.casino;
      case 'Junk Food':
        return Icons.fastfood;
      case 'Vaping':
        return Icons.cloud;
      default:
        return Icons.spa;
    }
  }

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
                Icon(
                  _categoryIcon(tracker.category),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tracker.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tracker.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'reset') onReset();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'reset',
                      child: Text('Reset Counter'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Big counter
            Center(
              child: Column(
                children: [
                  Text(
                    '${stats.totalDays}',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    stats.totalDays == 1 ? 'day' : 'days',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    SobrietyCounterService.formatDuration(stats.totalDays),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Next milestone
            if (stats.nextMilestone != null) ...[
              LinearProgressIndicator(
                value: _milestoneProgress(stats),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                'Next milestone: ${stats.nextMilestone} (${stats.daysToNextMilestone} days away)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            // Achieved milestones
            if (stats.achievedMilestones.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: stats.achievedMilestones.map((m) {
                  return Chip(
                    avatar: const Icon(Icons.emoji_events, size: 16),
                    label: Text(m),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],

            // Note
            if (tracker.note != null) ...[
              const SizedBox(height: 12),
              Text(
                '"${tracker.note}"',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _milestoneProgress(SobrietyStats stats) {
    if (stats.daysToNextMilestone == null) return 1.0;
    // Find previous milestone
    int prevDays = 0;
    for (final entry in SobrietyCounterService.milestones.entries) {
      if (entry.key > stats.totalDays) break;
      prevDays = entry.key;
    }
    final range =
        (stats.totalDays + stats.daysToNextMilestone!) - prevDays;
    if (range <= 0) return 1.0;
    return (stats.totalDays - prevDays) / range;
  }
}
