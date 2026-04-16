import 'package:flutter/material.dart';
import '../../core/services/decision_matrix_service.dart';

/// Interactive weighted decision matrix.
///
/// Users add options (rows) and criteria with weights (columns),
/// score each combination 0-10, and see ranked results with
/// an AI-style recommendation.
class DecisionMatrixScreen extends StatefulWidget {
  const DecisionMatrixScreen({super.key});

  @override
  State<DecisionMatrixScreen> createState() => _DecisionMatrixScreenState();
}

class _DecisionMatrixScreenState extends State<DecisionMatrixScreen> {
  final List<String> _options = ['Option A', 'Option B'];
  final List<DecisionCriterion> _criteria = [
    const DecisionCriterion(name: 'Cost', weight: 7),
    const DecisionCriterion(name: 'Quality', weight: 8),
    const DecisionCriterion(name: 'Speed', weight: 5),
  ];

  // scores[optionIdx][criterionIdx] = 0..10
  final Map<int, Map<int, double>> _scores = {};
  List<DecisionResult> _results = [];
  bool _showResults = false;

  final _optionController = TextEditingController();
  final _criterionNameController = TextEditingController();
  double _criterionWeight = 5;

  @override
  void dispose() {
    _optionController.dispose();
    _criterionNameController.dispose();
    super.dispose();
  }

  void _evaluate() {
    setState(() {
      _results = DecisionMatrixService.evaluate(
        options: _options,
        criteria: _criteria,
        scores: _scores,
      );
      _showResults = true;
    });
  }

  void _addOption() {
    final name = _optionController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _options.add(name);
      _optionController.clear();
    });
  }

  void _addCriterion() {
    final name = _criterionNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _criteria.add(DecisionCriterion(name: name, weight: _criterionWeight));
      _criterionNameController.clear();
      _criterionWeight = 5;
    });
  }

  void _removeOption(int idx) {
    setState(() {
      _options.removeAt(idx);
      _scores.remove(idx);
      // Reindex scores above idx
      final newScores = <int, Map<int, double>>{};
      for (final entry in _scores.entries) {
        final key = entry.key > idx ? entry.key - 1 : entry.key;
        newScores[key] = entry.value;
      }
      _scores
        ..clear()
        ..addAll(newScores);
      _showResults = false;
    });
  }

  void _removeCriterion(int idx) {
    setState(() {
      _criteria.removeAt(idx);
      for (final optScores in _scores.values) {
        optScores.remove(idx);
        // Reindex criteria above idx
        final reindexed = <int, double>{};
        for (final e in optScores.entries) {
          final key = e.key > idx ? e.key - 1 : e.key;
          reindexed[key] = e.value;
        }
        optScores
          ..clear()
          ..addAll(reindexed);
      }
      _showResults = false;
    });
  }

  void _reset() {
    setState(() {
      _options
        ..clear()
        ..addAll(['Option A', 'Option B']);
      _criteria
        ..clear()
        ..addAll([
          const DecisionCriterion(name: 'Cost', weight: 7),
          const DecisionCriterion(name: 'Quality', weight: 8),
          const DecisionCriterion(name: 'Speed', weight: 5),
        ]);
      _scores.clear();
      _results.clear();
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decision Matrix'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: _reset,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Options ──
          _sectionHeader('Options', Icons.list_alt),
          ..._buildOptionChips(),
          _buildAddOptionRow(),
          const SizedBox(height: 20),

          // ── Criteria ──
          _sectionHeader('Criteria & Weights', Icons.tune),
          ..._buildCriteriaChips(),
          _buildAddCriterionRow(),
          const SizedBox(height: 20),

          // ── Scoring Grid ──
          if (_options.isNotEmpty && _criteria.isNotEmpty) ...[
            _sectionHeader('Score Each Option (0–10)', Icons.grid_on),
            const SizedBox(height: 8),
            _buildScoringGrid(),
            const SizedBox(height: 20),

            // Evaluate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _evaluate,
                icon: const Icon(Icons.analytics),
                label: const Text('Evaluate & Rank'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],

          // ── Results ──
          if (_showResults && _results.isNotEmpty) ...[
            const SizedBox(height: 24),
            _sectionHeader('Results', Icons.emoji_events),
            _buildRecommendation(),
            const SizedBox(height: 12),
            ..._buildResultCards(),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Widget> _buildOptionChips() {
    return [
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: List.generate(_options.length, (i) {
          return Chip(
            label: Text(_options[i]),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: _options.length > 2 ? () => _removeOption(i) : null,
          );
        }),
      ),
    ];
  }

  Widget _buildAddOptionRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _optionController,
              decoration: const InputDecoration(
                hintText: 'New option name',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addOption(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.indigo),
            onPressed: _addOption,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCriteriaChips() {
    return [
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: List.generate(_criteria.length, (i) {
          final c = _criteria[i];
          return Chip(
            label: Text('${c.name} (w:${c.weight.toStringAsFixed(0)})'),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted:
                _criteria.length > 1 ? () => _removeCriterion(i) : null,
          );
        }),
      ),
    ];
  }

  Widget _buildAddCriterionRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _criterionNameController,
              decoration: const InputDecoration(
                hintText: 'Criterion name',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addCriterion(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Text('W:', style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Slider(
                    value: _criterionWeight,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _criterionWeight.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _criterionWeight = v),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.indigo),
            onPressed: _addCriterion,
          ),
        ],
      ),
    );
  }

  Widget _buildScoringGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: [
          const DataColumn(label: Text('Option')),
          ..._criteria.map((c) => DataColumn(
                label: Text(c.name, style: const TextStyle(fontSize: 12)),
              )),
        ],
        rows: List.generate(_options.length, (optIdx) {
          return DataRow(
            cells: [
              DataCell(Text(_options[optIdx],
                  style: const TextStyle(fontWeight: FontWeight.w500))),
              ...List.generate(_criteria.length, (critIdx) {
                final val = _scores[optIdx]?[critIdx] ?? 5.0;
                return DataCell(
                  SizedBox(
                    width: 80,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 50,
                          child: Slider(
                            value: val,
                            min: 0,
                            max: 10,
                            divisions: 10,
                            onChanged: (v) {
                              setState(() {
                                _scores.putIfAbsent(optIdx, () => {});
                                _scores[optIdx]![critIdx] = v;
                                _showResults = false;
                              });
                            },
                          ),
                        ),
                        Text(val.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRecommendation() {
    final rec = DecisionMatrixService.recommend(_results);
    final strength = DecisionMatrixService.winnerStrength(_results);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text('Recommendation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Text(rec, style: const TextStyle(fontSize: 14)),
          if (strength != null) ...[
            const SizedBox(height: 4),
            Text(strength,
                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildResultCards() {
    return _results.map((r) {
      final isWinner = r.rank == 1;
      final pct = (r.totalScore / r.maxPossibleScore * 100).clamp(0, 100);
      return Card(
        elevation: isWinner ? 3 : 1,
        color: isWinner ? Colors.indigo.shade50 : null,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        isWinner ? Colors.indigo : Colors.grey[400],
                    child: Text('${r.rank}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(r.option,
                        style: TextStyle(
                          fontWeight:
                              isWinner ? FontWeight.bold : FontWeight.w500,
                          fontSize: 15,
                        )),
                  ),
                  Text('${r.totalScore.toStringAsFixed(1)}/10',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isWinner ? Colors.indigo : Colors.grey[700],
                      )),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    isWinner ? Colors.indigo : Colors.grey[500]!,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 2,
                children: r.breakdown.map((b) {
                  return Text(
                    '${b.criterionName}: ${b.rawScore.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
