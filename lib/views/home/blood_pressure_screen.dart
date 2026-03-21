import 'package:flutter/material.dart';
import '../../models/blood_pressure_entry.dart';
import '../../core/services/blood_pressure_service.dart';
import 'dart:math';

/// Blood Pressure Tracker with logging, categorization (AHA guidelines),
/// trend analysis, and insights.
class BloodPressureScreen extends StatefulWidget {
  const BloodPressureScreen({super.key});

  @override
  State<BloodPressureScreen> createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> {
  final _service = const BloodPressureService();
  final List<BloodPressureEntry> _entries = [];

  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  final _pulseController = TextEditingController();
  final _noteController = TextEditingController();
  ReadingContext _selectedContext = ReadingContext.atRest;
  ArmUsed _selectedArm = ArmUsed.left;

  @override
  void dispose() {
    _sysController.dispose();
    _diaController.dispose();
    _pulseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addReading() {
    final sys = int.tryParse(_sysController.text);
    final dia = int.tryParse(_diaController.text);
    if (sys == null || dia == null || sys <= 0 || dia <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid systolic and diastolic values')),
      );
      return;
    }
    final pulse = int.tryParse(_pulseController.text);
    final entry = BloodPressureEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      timestamp: DateTime.now(),
      systolic: sys,
      diastolic: dia,
      pulse: pulse,
      context: _selectedContext,
      arm: _selectedArm,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );
    setState(() {
      _entries.insert(0, entry);
      _sysController.clear();
      _diaController.clear();
      _pulseController.clear();
      _noteController.clear();
    });
  }

  void _deleteEntry(int index) {
    setState(() => _entries.removeAt(index));
  }

  Color _categoryColor(BPCategory cat) {
    switch (cat) {
      case BPCategory.normal:
        return Colors.green;
      case BPCategory.elevated:
        return Colors.amber;
      case BPCategory.hypertensionStage1:
        return Colors.orange;
      case BPCategory.hypertensionStage2:
        return Colors.red;
      case BPCategory.hypertensiveCrisis:
        return Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _service.summarize(_entries);
    final insights = _service.generateInsights(_entries);

    return Scaffold(
      appBar: AppBar(title: const Text('Blood Pressure')),
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
                  Text('New Reading', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sysController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Systolic',
                            hintText: '120',
                            suffixText: 'mmHg',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('/', style: TextStyle(fontSize: 24)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _diaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Diastolic',
                            hintText: '80',
                            suffixText: 'mmHg',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pulseController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pulse (optional)',
                      hintText: '72',
                      suffixText: 'bpm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ReadingContext>(
                          value: _selectedContext,
                          decoration: const InputDecoration(
                            labelText: 'Context',
                            border: OutlineInputBorder(),
                          ),
                          items: ReadingContext.values
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.label),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedContext = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<ArmUsed>(
                          value: _selectedArm,
                          decoration: const InputDecoration(
                            labelText: 'Arm',
                            border: OutlineInputBorder(),
                          ),
                          items: ArmUsed.values
                              .map((a) => DropdownMenuItem(
                                    value: a,
                                    child: Text(a.label),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedArm = v!),
                        ),
                      ),
                    ],
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
                    Text('Summary', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatChip(
                          label: 'Average',
                          value: '${summary.avgSystolic}/${summary.avgDiastolic}',
                          unit: 'mmHg',
                          color: _categoryColor(summary.overallCategory),
                        ),
                        const SizedBox(width: 8),
                        if (summary.avgPulse != null)
                          _StatChip(
                            label: 'Pulse',
                            value: '${summary.avgPulse}',
                            unit: 'bpm',
                            color: Colors.blue,
                          ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'Readings',
                          value: '${summary.readingCount}',
                          unit: '',
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _categoryColor(summary.overallCategory)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${summary.overallCategory.emoji} ${summary.overallCategory.label}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _categoryColor(summary.overallCategory),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Insights ──
          if (insights.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Insights', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...insights.map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(i),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── BP Reference Chart ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BP Categories (AHA)', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _BPRangeRow(
                      label: 'Normal', range: '<120 / <80', color: Colors.green),
                  _BPRangeRow(
                      label: 'Elevated',
                      range: '120-129 / <80',
                      color: Colors.amber),
                  _BPRangeRow(
                      label: 'Stage 1',
                      range: '130-139 / 80-89',
                      color: Colors.orange),
                  _BPRangeRow(
                      label: 'Stage 2',
                      range: '≥140 / ≥90',
                      color: Colors.red),
                  _BPRangeRow(
                      label: 'Crisis',
                      range: '≥180 / ≥120',
                      color: Colors.red.shade900),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Reading History ──
          if (_entries.isNotEmpty) ...[
            Text('History', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._entries.asMap().entries.map((e) {
              final idx = e.key;
              final entry = e.value;
              return Dismissible(
                key: ValueKey(entry.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteEntry(idx),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _categoryColor(entry.category).withOpacity(0.2),
                      child: Text(
                        entry.category.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    title: Text(
                      '${entry.systolic}/${entry.diastolic} mmHg'
                      '${entry.pulse != null ? '  ❤️ ${entry.pulse} bpm' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${_formatTime(entry.timestamp)} · ${entry.context.label} · ${entry.arm.label}'
                      '${entry.note != null ? '\n${entry.note}' : ''}',
                    ),
                    trailing: Text(
                      entry.category.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: _categoryColor(entry.category),
                      ),
                    ),
                    isThreeLine: entry.note != null,
                  ),
                ),
              );
            }),
          ],

          if (_entries.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.monitor_heart_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No readings yet',
                        style: TextStyle(color: Colors.grey)),
                    Text('Log your first blood pressure reading above.',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            if (unit.isNotEmpty)
              Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _BPRangeRow extends StatelessWidget {
  final String label;
  final String range;
  final Color color;

  const _BPRangeRow({
    required this.label,
    required this.range,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(range, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}
