import 'package:flutter/material.dart';
import '../../models/blood_sugar_entry.dart';
import '../../core/services/blood_sugar_service.dart';
import 'dart:math';

/// Blood Sugar Tracker with logging, ADA-based categorization,
/// trend analysis, estimated A1C, and time-in-range insights.
class BloodSugarScreen extends StatefulWidget {
  const BloodSugarScreen({super.key});

  @override
  State<BloodSugarScreen> createState() => _BloodSugarScreenState();
}

class _BloodSugarScreenState extends State<BloodSugarScreen> {
  final _service = const BloodSugarService();
  final List<BloodSugarEntry> _entries = [];

  final _glucoseController = TextEditingController();
  final _noteController = TextEditingController();
  MealContext _selectedMealContext = MealContext.fasting;

  @override
  void dispose() {
    _glucoseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addReading() {
    final glucose = int.tryParse(_glucoseController.text);
    if (glucose == null || glucose <= 0 || glucose > 600) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid glucose value (1-600 mg/dL)')),
      );
      return;
    }
    final entry = BloodSugarEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      timestamp: DateTime.now(),
      glucoseMgDl: glucose,
      mealContext: _selectedMealContext,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );
    setState(() {
      _entries.insert(0, entry);
      _glucoseController.clear();
      _noteController.clear();
    });
  }

  void _deleteEntry(int index) {
    setState(() => _entries.removeAt(index));
  }

  Color _categoryColor(BSCategory cat) {
    switch (cat) {
      case BSCategory.low:
        return Colors.blue;
      case BSCategory.normal:
        return Colors.green;
      case BSCategory.prediabetic:
        return Colors.amber;
      case BSCategory.diabetic:
        return Colors.red;
      case BSCategory.dangerouslyHigh:
        return Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _service.summarize(_entries);
    final trend = _service.trend(_entries);
    final a1c = _service.estimatedA1c(_entries);
    final tir = _service.timeInRange(_entries);
    final variability = _service.variability(_entries);

    return Scaffold(
      appBar: AppBar(title: const Text('Blood Sugar Tracker')),
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
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _glucoseController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Glucose (mg/dL)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. 95',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MealContext>(
                    value: _selectedMealContext,
                    decoration: const InputDecoration(
                      labelText: 'Context',
                      border: OutlineInputBorder(),
                    ),
                    items: MealContext.values
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedMealContext = v);
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
                      label: const Text('Log Reading'),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Summary',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _summaryRow(
                      'Average',
                      '${summary.avgGlucose} mg/dL',
                      _categoryColor(summary.overallCategory),
                    ),
                    _summaryRow(
                      'Range',
                      '${summary.minGlucose}–${summary.maxGlucose} mg/dL',
                      null,
                    ),
                    _summaryRow(
                      'Readings',
                      '${summary.readingCount}',
                      null,
                    ),
                    _summaryRow(
                      'Trend',
                      _trendLabel(trend),
                      _trendColor(trend),
                    ),
                    const Divider(),
                    _summaryRow(
                      'Est. A1C',
                      '${a1c.toStringAsFixed(1)}%',
                      a1c <= 5.7
                          ? Colors.green
                          : a1c <= 6.4
                              ? Colors.amber
                              : Colors.red,
                    ),
                    _summaryRow(
                      'Time in Range',
                      '${tir.toStringAsFixed(0)}%',
                      tir >= 70
                          ? Colors.green
                          : tir >= 50
                              ? Colors.amber
                              : Colors.red,
                    ),
                    _summaryRow(
                      'Variability (SD)',
                      '${variability.toStringAsFixed(1)} mg/dL',
                      variability <= 36
                          ? Colors.green
                          : variability <= 50
                              ? Colors.amber
                              : Colors.red,
                    ),
                    const Divider(),
                    Text(
                      '${summary.overallCategory.emoji} ${summary.overallCategory.label}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _categoryColor(summary.overallCategory),
                      ),
                    ),
                    Text(
                      summary.overallCategory.advice,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Category Breakdown ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category Breakdown',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...summary.categoryBreakdown.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(e.key.emoji),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.key.label)),
                            Text('${e.value}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Readings List ──
          Text('Readings',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_entries.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No readings yet. Log your first glucose reading!'),
              ),
            )
          else
            ..._entries.asMap().entries.map(
              (mapEntry) {
                final i = mapEntry.key;
                final e = mapEntry.value;
                return Dismissible(
                  key: Key(e.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteEntry(i),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _categoryColor(e.category).withValues(alpha: 0.2),
                        child: Text(
                          '${e.glucoseMgDl}',
                          style: TextStyle(
                            color: _categoryColor(e.category),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(
                        '${e.glucoseMgDl} mg/dL  ${e.category.emoji}',
                      ),
                      subtitle: Text(
                        '${e.mealContext.label} · ${_formatDate(e.timestamp)}'
                        '${e.note != null ? '\n${e.note}' : ''}',
                      ),
                      isThreeLine: e.note != null,
                      trailing: Text(
                        '${e.glucoseMmolL.toStringAsFixed(1)}\nmmol/L',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _trendLabel(BSTrend t) {
    switch (t) {
      case BSTrend.improving:
        return '↓ Improving';
      case BSTrend.stable:
        return '→ Stable';
      case BSTrend.worsening:
        return '↑ Worsening';
      case BSTrend.insufficient:
        return 'Need more data';
    }
  }

  Color? _trendColor(BSTrend t) {
    switch (t) {
      case BSTrend.improving:
        return Colors.green;
      case BSTrend.stable:
        return Colors.blue;
      case BSTrend.worsening:
        return Colors.red;
      case BSTrend.insufficient:
        return null;
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${h}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}
