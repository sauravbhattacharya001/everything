import 'package:flutter/material.dart';
import '../../core/services/regex_tester_service.dart';

/// Interactive regex tester with live match highlighting,
/// capture groups display, and a library of common patterns.
class RegexTesterScreen extends StatefulWidget {
  const RegexTesterScreen({super.key});

  @override
  State<RegexTesterScreen> createState() => _RegexTesterScreenState();
}

class _RegexTesterScreenState extends State<RegexTesterScreen> {
  final _patternController = TextEditingController();
  final _inputController = TextEditingController();
  bool _caseSensitive = true;
  bool _multiLine = false;
  bool _dotAll = false;
  bool _unicode = false;
  RegexTestResult? _result;

  @override
  void initState() {
    super.initState();
    _patternController.addListener(_onChanged);
    _inputController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _patternController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final result = RegexTesterService.test(
      pattern: _patternController.text,
      input: _inputController.text,
      caseSensitive: _caseSensitive,
      multiLine: _multiLine,
      dotAll: _dotAll,
      unicode: _unicode,
    );
    setState(() => _result = result);
  }

  void _applyCommonPattern(String pattern) {
    _patternController.text = pattern;
  }

  List<InlineSpan> _buildHighlightedSpans(String text, List<RegexMatchDetail> matches) {
    if (matches.isEmpty) {
      return [TextSpan(text: text)];
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;
    final colors = [
      Colors.yellow.withValues(alpha: 0.4),
      Colors.lightBlue.withValues(alpha: 0.4),
      Colors.lightGreen.withValues(alpha: 0.4),
      Colors.orange.withValues(alpha: 0.4),
      Colors.purple.withValues(alpha: 0.2),
    ];

    for (var i = 0; i < matches.length; i++) {
      final m = matches[i];
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start)));
      }
      spans.add(TextSpan(
        text: text.substring(m.start, m.end),
        style: TextStyle(
          backgroundColor: colors[i % colors.length],
          fontWeight: FontWeight.bold,
        ),
      ));
      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    final inputText = _inputController.text;

    return Scaffold(
      appBar: AppBar(title: const Text('Regex Tester')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pattern input
          TextField(
            controller: _patternController,
            decoration: InputDecoration(
              labelText: 'Regex Pattern',
              hintText: r'e.g. \b\w+@\w+\.\w+\b',
              border: const OutlineInputBorder(),
              prefixText: '/ ',
              suffixText: ' /',
              errorText: result?.error,
              suffixIcon: _patternController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _patternController.clear(),
                    )
                  : null,
            ),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 12),

          // Flags
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Case Sensitive'),
                selected: _caseSensitive,
                onSelected: (v) {
                  setState(() => _caseSensitive = v);
                  _onChanged();
                },
              ),
              FilterChip(
                label: const Text('Multi-line'),
                selected: _multiLine,
                onSelected: (v) {
                  setState(() => _multiLine = v);
                  _onChanged();
                },
              ),
              FilterChip(
                label: const Text('Dot All'),
                selected: _dotAll,
                onSelected: (v) {
                  setState(() => _dotAll = v);
                  _onChanged();
                },
              ),
              FilterChip(
                label: const Text('Unicode'),
                selected: _unicode,
                onSelected: (v) {
                  setState(() => _unicode = v);
                  _onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Test input
          TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              labelText: 'Test String',
              hintText: 'Enter text to test against the pattern...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 16),

          // Results summary
          if (result != null && result.error == null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      result.matchCount > 0
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: result.matchCount > 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${result.matchCount} match${result.matchCount == 1 ? '' : 'es'}',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (result.groupCount > 0) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${result.groupCount} group${result.groupCount == 1 ? '' : 's'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Highlighted text
            if (inputText.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Highlighted Matches',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                          ),
                          children: _buildHighlightedSpans(
                            inputText,
                            result.matches,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Match details
            if (result.matches.isNotEmpty)
              ...result.matches.asMap().entries.map((entry) {
                final idx = entry.key;
                final m = entry.value;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Match ${idx + 1}: "${m.fullMatch}"',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'Position: ${m.start}–${m.end}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (m.groups.length > 1) ...[
                          const Divider(),
                          ...m.groups.entries
                              .where((g) => g.key > 0)
                              .map((g) => Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      'Group ${g.key}: "${g.value ?? '(null)'}"',
                                      style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 13),
                                    ),
                                  )),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],

          const SizedBox(height: 24),

          // Common patterns
          Text('Common Patterns', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...RegexTesterService.commonPatterns.entries.map((entry) => ListTile(
                dense: true,
                title: Text(entry.key),
                subtitle: Text(entry.value,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _applyCommonPattern(entry.value),
              )),
        ],
      ),
    );
  }
}
