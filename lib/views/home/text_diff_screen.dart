import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/text_diff_service.dart';

/// Diff comparison mode.
enum _DiffMode { line, word, character }

/// Text Diff Checker — compare two texts and see differences highlighted.
class TextDiffScreen extends StatefulWidget {
  const TextDiffScreen({super.key});

  @override
  State<TextDiffScreen> createState() => _TextDiffScreenState();
}

class _TextDiffScreenState extends State<TextDiffScreen> {
  final _service = TextDiffService();
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  _DiffMode _mode = _DiffMode.word;
  List<DiffChunk> _chunks = [];
  DiffStats? _stats;
  bool _hasCompared = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    super.dispose();
  }

  void _compare() {
    final oldText = _oldController.text;
    final newText = _newController.text;

    List<DiffChunk> chunks;
    switch (_mode) {
      case _DiffMode.line:
        chunks = _service.diffLines(oldText, newText);
        break;
      case _DiffMode.word:
        chunks = _service.diffWords(oldText, newText);
        break;
      case _DiffMode.character:
        chunks = _service.diffChars(oldText, newText);
        break;
    }

    setState(() {
      _chunks = chunks;
      _stats = _service.stats(chunks);
      _hasCompared = true;
    });
  }

  void _clear() {
    setState(() {
      _oldController.clear();
      _newController.clear();
      _chunks = [];
      _stats = null;
      _hasCompared = false;
    });
  }

  void _swap() {
    final tmp = _oldController.text;
    _oldController.text = _newController.text;
    _newController.text = tmp;
    if (_hasCompared) _compare();
  }

  void _loadSample() {
    _oldController.text =
        'The quick brown fox jumps over the lazy dog.\n'
        'She sells sea shells by the sea shore.\n'
        'Pack my box with five dozen liquor jugs.';
    _newController.text =
        'The quick red fox leaps over the lazy cat.\n'
        'She sells sea shells by the ocean shore.\n'
        'Pack my bag with five dozen liquor jugs.';
    _compare();
  }

  String get _modeLabel {
    switch (_mode) {
      case _DiffMode.line:
        return 'Line';
      case _DiffMode.word:
        return 'Word';
      case _DiffMode.character:
        return 'Character';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Diff Checker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Load sample',
            onPressed: _loadSample,
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert),
            tooltip: 'Swap texts',
            onPressed: _swap,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear all',
            onPressed: _clear,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode selector
            SegmentedButton<_DiffMode>(
              segments: _DiffMode.values
                  .map((m) => ButtonSegment(
                        value: m,
                        label: Text(m.name[0].toUpperCase() + m.name.substring(1)),
                      ))
                  .toList(),
              selected: {_mode},
              onSelectionChanged: (s) {
                setState(() => _mode = s.first);
                if (_hasCompared) _compare();
              },
            ),
            const SizedBox(height: 12),

            // Input fields
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      controller: _oldController,
                      label: 'Original Text',
                      icon: Icons.description_outlined,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInput(
                      controller: _newController,
                      label: 'Modified Text',
                      icon: Icons.edit_note,
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Compare button
            FilledButton.icon(
              onPressed: _compare,
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Compare'),
            ),
            const SizedBox(height: 12),

            // Stats bar
            if (_stats != null) _buildStatsBar(theme, isDark),
            if (_stats != null) const SizedBox(height: 8),

            // Diff output
            if (_hasCompared)
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: _chunks.isEmpty
                      ? Center(
                          child: Text(
                            'Texts are identical ✓',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: _buildDiffOutput(theme, isDark),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
  }) {
    return TextField(
      controller: controller,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        height: 1.5,
      ),
    );
  }

  Widget _buildStatsBar(ThemeData theme, bool isDark) {
    final s = _stats!;
    final simPct = (s.similarity * 100).toStringAsFixed(1);
    return Row(
      children: [
        _statChip(Icons.add, '+${s.additions}', Colors.green, theme),
        const SizedBox(width: 8),
        _statChip(Icons.remove, '-${s.deletions}', Colors.red, theme),
        const SizedBox(width: 8),
        _statChip(Icons.drag_handle, '${s.unchanged} unchanged', Colors.grey, theme),
        const Spacer(),
        Chip(
          avatar: Icon(
            s.similarity > 0.8
                ? Icons.check_circle
                : s.similarity > 0.5
                    ? Icons.info
                    : Icons.warning,
            size: 16,
            color: s.similarity > 0.8
                ? Colors.green
                : s.similarity > 0.5
                    ? Colors.orange
                    : Colors.red,
          ),
          label: Text('$simPct% similar'),
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String label, Color color, ThemeData theme) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDiffOutput(ThemeData theme, bool isDark) {
    if (_mode == _DiffMode.line) {
      return _buildLineDiff(theme, isDark);
    }
    // For word and character mode, use inline RichText
    return SelectableText.rich(
      TextSpan(
        children: _chunks.map((c) {
          Color? bg;
          TextDecoration? decoration;
          Color? textColor;
          switch (c.type) {
            case DiffType.added:
              bg = isDark ? Colors.green.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.2);
              textColor = isDark ? Colors.greenAccent : Colors.green.shade900;
              break;
            case DiffType.removed:
              bg = isDark ? Colors.red.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.2);
              textColor = isDark ? Colors.redAccent : Colors.red.shade900;
              decoration = TextDecoration.lineThrough;
              break;
            case DiffType.equal:
              break;
          }
          return TextSpan(
            text: c.text,
            style: TextStyle(
              backgroundColor: bg,
              color: textColor,
              decoration: decoration,
              fontFamily: 'monospace',
              height: 1.6,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineDiff(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _chunks.map((c) {
        Color? bg;
        IconData? icon;
        Color? iconColor;
        switch (c.type) {
          case DiffType.added:
            bg = isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.1);
            icon = Icons.add;
            iconColor = Colors.green;
            break;
          case DiffType.removed:
            bg = isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.1);
            icon = Icons.remove;
            iconColor = Colors.red;
            break;
          case DiffType.equal:
            break;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          color: bg,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 4),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
              if (icon == null) const SizedBox(width: 18),
              Expanded(
                child: SelectableText(
                  c.text,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    height: 1.5,
                    decoration: c.type == DiffType.removed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
