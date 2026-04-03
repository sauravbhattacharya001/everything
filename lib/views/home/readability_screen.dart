import 'package:flutter/material.dart';
import '../../core/services/readability_service.dart';

/// Readability Analyzer — paste text to get Flesch Reading Ease,
/// Flesch-Kincaid Grade Level, Gunning Fog, Coleman-Liau, ARI, and
/// SMOG Grade scores with audience guidance and color-coded gauges.
class ReadabilityScreen extends StatefulWidget {
  const ReadabilityScreen({super.key});

  @override
  State<ReadabilityScreen> createState() => _ReadabilityScreenState();
}

class _ReadabilityScreenState extends State<ReadabilityScreen> {
  final _controller = TextEditingController();
  ReadabilityResult? _result;

  static const _sampleTexts = <String, String>{
    'Simple': 'The cat sat on the mat. It was a good cat. The sun was warm.',
    'News Article':
        'The Federal Reserve announced today that interest rates will remain '
            'unchanged for the foreseeable future. Economists had widely anticipated '
            'this decision, citing persistent inflationary pressures and a resilient '
            'labor market. The central bank emphasized its commitment to achieving '
            'the two percent inflation target through continued monetary restraint.',
    'Academic':
        'The epistemological implications of quantum decoherence necessitate a '
            'fundamental reconceptualization of observer-dependent measurement '
            'paradigms. Furthermore, the non-commutative algebraic structures '
            'underlying entangled quantum states preclude any straightforward '
            'classical interpretation of superposition phenomena.',
  };

  void _analyze() {
    setState(() {
      _result = ReadabilityService.analyze(_controller.text);
    });
  }

  void _clear() {
    _controller.clear();
    setState(() => _result = null);
  }

  void _loadSample(String text) {
    _controller.text = text;
    _analyze();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Readability Analyzer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: _sampleTexts.entries
                .map((e) => ActionChip(
                      label: Text(e.key),
                      onPressed: () => _loadSample(e.value),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Paste or type your text here…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _analyze,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Analyze'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _clear, child: const Text('Clear')),
            ],
          ),
          if (_result != null && _result!.wordCount > 0) ...[
            const SizedBox(height: 20),
            _buildSummaryCard(theme),
            const SizedBox(height: 12),
            _buildScoresCard(theme),
            const SizedBox(height: 12),
            _buildDetailsCard(theme),
          ] else if (_result != null) ...[
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Enter some text to analyze.',
                    textAlign: TextAlign.center),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final r = _result!;
    final easeColor = _easeColor(r.fleschReadingEase);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Reading Level', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: easeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: easeColor),
              ),
              child: Text(r.readingLevel,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: easeColor, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text('Audience: ${r.audience}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            _buildGauge(r.fleschReadingEase, 0, 100, easeColor, 'Flesch Ease'),
          ],
        ),
      ),
    );
  }

  Widget _buildScoresCard(ThemeData theme) {
    final r = _result!;
    final scores = [
      _ScoreItem('Flesch-Kincaid', r.fleschKincaidGrade),
      _ScoreItem('Gunning Fog', r.gunningFog),
      _ScoreItem('Coleman-Liau', r.colemanLiau),
      _ScoreItem('ARI', r.ari),
      _ScoreItem('SMOG', r.smogGrade),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grade Level Scores', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Lower = easier to read',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            ...scores.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildGauge(
                    s.value, 0, 20, _gradeColor(s.value),
                    '${s.label}: ${s.value.toStringAsFixed(1)}',
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(ThemeData theme) {
    final r = _result!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Text Details', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _detailRow('Words', r.wordCount.toString()),
            _detailRow('Sentences', r.sentenceCount.toString()),
            _detailRow('Syllables', r.syllableCount.toString()),
            _detailRow('Complex words (3+ syllables)',
                '${r.complexWordCount} (${(r.complexWordCount / r.wordCount * 100).toStringAsFixed(1)}%)'),
            _detailRow('Avg words/sentence',
                r.avgWordsPerSentence.toStringAsFixed(1)),
            _detailRow('Avg syllables/word',
                r.avgSyllablesPerWord.toStringAsFixed(2)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildGauge(
      double value, double min, double max, Color color, String label) {
    final fraction = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor: color.withAlpha(40),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Color _easeColor(double ease) {
    if (ease >= 70) return Colors.green;
    if (ease >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _gradeColor(double grade) {
    if (grade <= 8) return Colors.green;
    if (grade <= 12) return Colors.orange;
    return Colors.red;
  }
}

class _ScoreItem {
  final String label;
  final double value;
  const _ScoreItem(this.label, this.value);
}
