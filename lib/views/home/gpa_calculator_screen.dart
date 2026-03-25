import 'package:flutter/material.dart';
import '../../core/services/gpa_calculator_service.dart';

/// GPA Calculator screen — add courses with grades and credit hours,
/// see your semester and cumulative GPA.
class GpaCalculatorScreen extends StatefulWidget {
  const GpaCalculatorScreen({super.key});

  @override
  State<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends State<GpaCalculatorScreen> {
  final List<_CourseRow> _courses = [_CourseRow()];
  final _priorGpaController = TextEditingController();
  final _priorCreditsController = TextEditingController();
  bool _showCumulative = false;

  @override
  void dispose() {
    for (final c in _courses) {
      c.nameController.dispose();
      c.creditsController.dispose();
    }
    _priorGpaController.dispose();
    _priorCreditsController.dispose();
    super.dispose();
  }

  void _addCourse() {
    setState(() => _courses.add(_CourseRow()));
  }

  void _removeCourse(int index) {
    if (_courses.length > 1) {
      setState(() {
        _courses[index].nameController.dispose();
        _courses[index].creditsController.dispose();
        _courses.removeAt(index);
      });
    }
  }

  GpaResult _calculate() {
    final entries = _courses.map((c) {
      final credits = double.tryParse(c.creditsController.text.trim()) ?? 3.0;
      return CourseEntry(
        name: c.nameController.text.trim().isEmpty
            ? 'Course ${_courses.indexOf(c) + 1}'
            : c.nameController.text.trim(),
        grade: c.selectedGrade,
        credits: credits,
      );
    }).toList();
    return GpaCalculatorService.calculate(entries);
  }

  Color _gpaColor(double gpa) {
    if (gpa >= 3.5) return Colors.green;
    if (gpa >= 3.0) return Colors.blue;
    if (gpa >= 2.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _calculate();

    double? cumulativeGpa;
    if (_showCumulative) {
      final priorGpa = double.tryParse(_priorGpaController.text.trim());
      final priorCredits = double.tryParse(_priorCreditsController.text.trim());
      if (priorGpa != null && priorCredits != null && priorCredits > 0) {
        cumulativeGpa = GpaCalculatorService.cumulativeGpa(
          priorGpa: priorGpa,
          priorCredits: priorCredits,
          currentGpa: result.gpa,
          currentCredits: result.totalCredits,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('GPA Calculator')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCourse,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // GPA display card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Semester GPA',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    result.gpa.toStringAsFixed(2),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _gpaColor(result.gpa),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    GpaCalculatorService.classify(result.gpa),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _gpaColor(result.gpa),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.totalCredits.toStringAsFixed(0)} credits',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (cumulativeGpa != null) ...[
                    const Divider(height: 24),
                    Text('Cumulative GPA',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      cumulativeGpa.toStringAsFixed(2),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _gpaColor(cumulativeGpa),
                      ),
                    ),
                    Text(
                      GpaCalculatorService.classify(cumulativeGpa),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _gpaColor(cumulativeGpa),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cumulative toggle
          SwitchListTile(
            title: const Text('Include prior GPA'),
            subtitle: const Text('Calculate cumulative GPA'),
            value: _showCumulative,
            onChanged: (v) => setState(() => _showCumulative = v),
          ),
          if (_showCumulative) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priorGpaController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Prior GPA',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _priorCreditsController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Prior Credits',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Course list header
          Text('Courses', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),

          // Course entries
          ..._courses.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course name
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: c.nameController,
                      decoration: InputDecoration(
                        labelText: 'Course ${i + 1}',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Credits
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: c.creditsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cr',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Grade dropdown
                  SizedBox(
                    width: 70,
                    child: DropdownButtonFormField<String>(
                      value: c.selectedGrade,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Grade',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      items: GpaCalculatorService.letterGrades
                          .map((g) => DropdownMenuItem(
                              value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => c.selectedGrade = v);
                        }
                      },
                    ),
                  ),
                  // Remove button
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed:
                        _courses.length > 1 ? () => _removeCourse(i) : null,
                    padding: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 60), // FAB clearance
        ],
      ),
    );
  }
}

class _CourseRow {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController creditsController = TextEditingController(text: '3');
  String selectedGrade = 'A';
}
