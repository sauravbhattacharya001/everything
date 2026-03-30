import 'package:flutter/material.dart';
import '../../models/spo2_entry.dart';
import '../../core/services/spo2_service.dart';
import 'dart:math';

/// Blood Oxygen (SpO2) Tracker with logging, categorization,
/// trend analysis, and insights.
class SpO2Screen extends StatefulWidget {
  const SpO2Screen({super.key});

  @override
  State<SpO2Screen> createState() => _SpO2ScreenState();
}

class _SpO2ScreenState extends State<SpO2Screen> {
  final _service = const SpO2Service();
  final List<SpO2Entry> _entries = [];

  final _spo2Controller = TextEditingController();
  final _heartRateController = TextEditingController();
  final _noteController = TextEditingController();
  SpO2Context _selectedContext = SpO2Context.atRest;

  @override
  void dispose() {
    _spo2Controller.dispose();
    _heartRateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addReading() {
    final spo2 = int.tryParse(_spo2Controller.text);
    if (spo2 == null || spo2 < 0 || spo2 > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid SpO2 value (0-100%)')),
      );
      return;
    }
    final heartRate = int.tryParse(_heartRateController.text);
    final entry = SpO2Entry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      timestamp: DateTime.now(),
      spo2: spo2,
      heartRate: heartRate,
      context: _selectedContext,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );
    setState(() {
      _entries.insert(0, entry);
      _spo2Controller.clear();
      _heartRateController.clear();
      _noteController.clear();
    });
  }

  void _deleteEntry(int index) {
    setState(() => _entries.removeAt(index));
  }

  Color _categoryColor(SpO2Category cat) {
    switch (cat) {
      case SpO2Category.normal:
        return Colors.green;
      case SpO2Category.mild:
        return Colors.amber;
      case SpO2Category.moderate:
        return Colors.orange;
      case SpO2Category.severe:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _service.summarize(_entries);
    final insights = _service.generateInsights(_entries);

    return Scaffold(
      appBar: AppBar(title: const Text('Blood Oxygen (SpO2)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Input Card ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Reading',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _spo2Controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'SpO2 %',
                            hintText: '98',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _heartRateController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Heart Rate',
                            hintText: '72',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SpO2Context>(
                    value: _selectedContext,
                    decoration: const InputDecoration(
                      labelText: 'Context',
                      border: OutlineInputBorder(),
                    ),
                    items: SpO2Context.values
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c.label)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedContext = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addReading,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Reading'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Summary Card ──
          if (_entries.isNotEmpty) ...[
            Card(
              color: _categoryColor(summary.overallCategory).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Summary',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statChip('Avg', '${summary.avgSpO2}%', theme),
                        _statChip('Min', '${summary.minSpO2}%', theme),
                        _statChip('Max', '${summary.maxSpO2}%', theme),
                        _statChip('Count', '${summary.readingCount}', theme),
                      ],
                    ),
                    if (summary.avgHeartRate != null) ...[
                      const SizedBox(height: 8),
                      Text('❤️ Avg Heart Rate: ${summary.avgHeartRate} bpm',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Insights Card ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Insights',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...insights.map((i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(i, style: theme.textTheme.bodyMedium),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Category Breakdown ──
            if (summary.categoryBreakdown.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category Breakdown',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...summary.categoryBreakdown.entries.map((e) {
                        final pct =
                            (e.value / summary.readingCount * 100).round();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(e.key.emoji),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(e.key.label),
                                    const SizedBox(height: 2),
                                    LinearProgressIndicator(
                                      value: pct / 100,
                                      color: _categoryColor(e.key),
                                      backgroundColor: _categoryColor(e.key)
                                          .withOpacity(0.2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$pct%'),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],

          // ── Readings List ──
          Text('Readings',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_entries.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No readings yet.\nTap + to add one!',
                    textAlign: TextAlign.center),
              ),
            )
          else
            ...List.generate(_entries.length, (i) {
              final e = _entries[i];
              return Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteEntry(i),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _categoryColor(e.category).withOpacity(0.2),
                      child: Text('${e.spo2}',
                          style: TextStyle(
                            color: _categoryColor(e.category),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          )),
                    ),
                    title: Text(
                        '${e.category.emoji} ${e.spo2}% — ${e.category.label}'),
                    subtitle: Text(
                      '${_formatTime(e.timestamp)} • ${e.context.label}'
                      '${e.heartRate != null ? ' • ❤️ ${e.heartRate} bpm' : ''}'
                      '${e.note != null ? '\n${e.note}' : ''}',
                    ),
                    isThreeLine: e.note != null,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
