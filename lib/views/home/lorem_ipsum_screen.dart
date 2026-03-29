import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/lorem_ipsum_service.dart';

/// Lorem Ipsum placeholder text generator.
///
/// Users can choose words, sentences, or paragraphs, set a count,
/// toggle the classic opening, and copy the result to clipboard.
class LoremIpsumScreen extends StatefulWidget {
  const LoremIpsumScreen({super.key});

  @override
  State<LoremIpsumScreen> createState() => _LoremIpsumScreenState();
}

class _LoremIpsumScreenState extends State<LoremIpsumScreen> {
  final _service = LoremIpsumService();
  LoremUnit _unit = LoremUnit.paragraphs;
  int _count = 3;
  bool _startClassic = true;
  String _output = '';
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    setState(() {
      _output = _service.generate(
        unit: _unit,
        count: _count,
        startClassic: _startClassic,
      );
      _copied = false;
    });
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _output));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _unitLabel(LoremUnit u) {
    switch (u) {
      case LoremUnit.words:
        return 'Words';
      case LoremUnit.sentences:
        return 'Sentences';
      case LoremUnit.paragraphs:
        return 'Paragraphs';
    }
  }

  int get _maxCount {
    switch (_unit) {
      case LoremUnit.words:
        return 500;
      case LoremUnit.sentences:
        return 50;
      case LoremUnit.paragraphs:
        return 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wordCount = _output.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lorem Ipsum Generator'),
        actions: [
          IconButton(
            icon: Icon(_copied ? Icons.check : Icons.copy),
            tooltip: 'Copy to clipboard',
            onPressed: _output.isEmpty ? null : _copy,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Unit selector
            SegmentedButton<LoremUnit>(
              segments: LoremUnit.values
                  .map((u) => ButtonSegment(value: u, label: Text(_unitLabel(u))))
                  .toList(),
              selected: {_unit},
              onSelectionChanged: (s) {
                _unit = s.first;
                if (_count > _maxCount) _count = _maxCount;
                _generate();
              },
            ),
            const SizedBox(height: 16),

            // Count slider
            Row(
              children: [
                Text('Count: $_count', style: theme.textTheme.bodyLarge),
                Expanded(
                  child: Slider(
                    value: _count.toDouble(),
                    min: 1,
                    max: _maxCount.toDouble(),
                    divisions: _maxCount - 1,
                    label: '$_count',
                    onChanged: (v) {
                      _count = v.round();
                      _generate();
                    },
                  ),
                ),
              ],
            ),

            // Classic start toggle
            SwitchListTile(
              title: const Text('Start with "Lorem ipsum…"'),
              value: _startClassic,
              onChanged: (v) {
                _startClassic = v;
                _generate();
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),

            // Word count badge
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.text_fields, size: 16),
                label: Text('$wordCount words'),
              ),
            ),
            const SizedBox(height: 8),

            // Output
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _output,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Generate button
            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.refresh),
              label: const Text('Regenerate'),
            ),
          ],
        ),
      ),
    );
  }
}
