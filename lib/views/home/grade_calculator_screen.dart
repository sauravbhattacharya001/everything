import 'package:flutter/material.dart';
import '../../core/services/grade_calculator_service.dart';

/// A grade calculator that computes weighted averages, letter grades,
/// GPA, and shows what score is needed on remaining work to hit a target.
class GradeCalculatorScreen extends StatefulWidget {
  const GradeCalculatorScreen({super.key});

  @override
  State<GradeCalculatorScreen> createState() => _GradeCalculatorScreenState();
}

class _GradeCalculatorScreenState extends State<GradeCalculatorScreen> {
  final _service = GradeCalculatorService();
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController();
  double _targetGrade = 90;

  void _addEntry() {
    final name = _nameCtrl.text.trim().isEmpty ? 'Item ${_service.entries.length + 1}' : _nameCtrl.text.trim();
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    final score = double.tryParse(_scoreCtrl.text) ?? 0;
    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight must be greater than 0')),
      );
      return;
    }
    if (_service.totalWeight + weight > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Total weight would exceed 100% (currently ${_service.totalWeight.toStringAsFixed(1)}%)')),
      );
      return;
    }
    setState(() {
      _service.addEntry(name, weight, score);
      _nameCtrl.clear();
      _weightCtrl.clear();
      _scoreCtrl.clear();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avg = _service.weightedAverage;
    final letter = _service.letterGrade;
    final gpa = _service.gpa;
    final needed = _service.scoreNeededForTarget(_targetGrade);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Calculator'),
        actions: [
          if (_service.entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all',
              onPressed: () => setState(() => _service.clear()),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Assignment', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name (optional)',
                        hintText: 'e.g. Midterm Exam',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Weight %',
                              hintText: '30',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _scoreCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Score %',
                              hintText: '85',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addEntry,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Results card
            if (_service.entries.isNotEmpty) ...[
              Card(
                color: _gradeColor(letter.letter).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        letter.letter,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _gradeColor(letter.letter),
                        ),
                      ),
                      Text(
                        '${avg.toStringAsFixed(1)}%',
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(letter.description, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text(
                        'GPA: ${gpa.toStringAsFixed(1)} / 4.0',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: avg / 100,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation(_gradeColor(letter.letter)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Weight used: ${_service.totalWeight.toStringAsFixed(1)}% of 100%',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Target grade calculator
              if (_service.totalWeight < 100) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What Do I Need?', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Target: '),
                            Expanded(
                              child: Slider(
                                value: _targetGrade,
                                min: 50,
                                max: 100,
                                divisions: 50,
                                label: '${_targetGrade.toInt()}%',
                                onChanged: (v) => setState(() => _targetGrade = v),
                              ),
                            ),
                            Text(
                              '${_targetGrade.toInt()}%',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (needed != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            needed > 100
                                ? '⚠️ You need ${needed.toStringAsFixed(1)}% on remaining work — not achievable.'
                                : needed <= 0
                                    ? '✅ You\'ve already secured a ${_targetGrade.toInt()}%+ grade!'
                                    : '📊 You need ${needed.toStringAsFixed(1)}% on the remaining ${(100 - _service.totalWeight).toStringAsFixed(1)}% of coursework.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: needed > 100
                                  ? Colors.red
                                  : needed <= 0
                                      ? Colors.green
                                      : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Entry list
              Text('Assignments', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...List.generate(_service.entries.length, (i) {
                final e = _service.entries[i];
                return Dismissible(
                  key: ValueKey('$i-${e.name}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => setState(() => _service.removeEntry(i)),
                  child: Card(
                    child: ListTile(
                      title: Text(e.name),
                      subtitle: Text('Weight: ${e.weight.toStringAsFixed(1)}%'),
                      trailing: Text(
                        '${e.score.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _gradeColor(LetterGrade.fromScore(e.score).letter),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Color _gradeColor(String letter) {
    if (letter.startsWith('A')) return Colors.green.shade700;
    if (letter.startsWith('B')) return Colors.blue.shade700;
    if (letter.startsWith('C')) return Colors.orange.shade700;
    if (letter.startsWith('D')) return Colors.deepOrange.shade700;
    return Colors.red.shade700;
  }
}
