import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/markdown_preview_service.dart';

/// Markdown Preview — type or paste Markdown and see live rendered output.
///
/// Features:
/// - Split-pane editor + preview layout
/// - Live rendering as you type
/// - Supports headings, bold, italic, code blocks, lists, quotes, HR
/// - Word/line count and estimated reading time
/// - Copy raw markdown to clipboard
/// - Sample markdown to get started
class MarkdownPreviewScreen extends StatefulWidget {
  const MarkdownPreviewScreen({super.key});

  @override
  State<MarkdownPreviewScreen> createState() => _MarkdownPreviewScreenState();
}

class _MarkdownPreviewScreenState extends State<MarkdownPreviewScreen> {
  final _service = MarkdownPreviewService();
  final _controller = TextEditingController();
  bool _showEditor = true;

  static const _sampleMarkdown = '''# Welcome to Markdown Preview

## Features

- **Bold text** and *italic text*
- ~~Strikethrough~~ support
- `Inline code` formatting

### Code Blocks

\`\`\`dart
void main() {
  print('Hello, Markdown!');
}
\`\`\`

> This is a blockquote.
> It can span multiple lines.

### Lists

1. First ordered item
2. Second ordered item
3. Third ordered item

- Unordered item A
- Unordered item B

---

*Happy writing!*
''';

  @override
  void initState() {
    super.initState();
    _controller.text = _sampleMarkdown;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _controller.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Markdown copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _clear() {
    _controller.clear();
    setState(() {});
  }

  void _loadSample() {
    _controller.text = _sampleMarkdown;
    setState(() {});
  }

  /// Render inline markdown formatting (bold, italic, code, strikethrough, links).
  List<InlineSpan> _renderInline(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(
      r'(\*\*\*.+?\*\*\*)'       // bold+italic
      r'|(\*\*.+?\*\*)'           // bold
      r'|(\*.+?\*)'               // italic
      r'|(~~.+?~~)'               // strikethrough
      r'|(`[^`]+`)'               // inline code
      r'|(\[.+?\]\(.+?\))',       // link
    );

    var lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: base,
        ));
      }

      final m = match.group(0)!;
      if (m.startsWith('***') && m.endsWith('***')) {
        spans.add(TextSpan(
          text: m.substring(3, m.length - 3),
          style: base.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ));
      } else if (m.startsWith('**') && m.endsWith('**')) {
        spans.add(TextSpan(
          text: m.substring(2, m.length - 2),
          style: base.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (m.startsWith('*') && m.endsWith('*')) {
        spans.add(TextSpan(
          text: m.substring(1, m.length - 1),
          style: base.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (m.startsWith('~~') && m.endsWith('~~')) {
        spans.add(TextSpan(
          text: m.substring(2, m.length - 2),
          style: base.copyWith(decoration: TextDecoration.lineThrough),
        ));
      } else if (m.startsWith('`') && m.endsWith('`')) {
        spans.add(WidgetSpan(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              m.substring(1, m.length - 1),
              style: base.copyWith(
                fontFamily: 'monospace',
                fontSize: (base.fontSize ?? 14) - 1,
              ),
            ),
          ),
        ));
      } else if (m.startsWith('[')) {
        final linkMatch = RegExp(r'\[(.+?)\]\((.+?)\)').firstMatch(m);
        if (linkMatch != null) {
          spans.add(TextSpan(
            text: linkMatch.group(1),
            style: base.copyWith(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ));
        }
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: base));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: base));
    }

    return spans;
  }

  Widget _buildPreview(String text) {
    final theme = Theme.of(context);
    final nodes = _service.parse(text);
    final children = <Widget>[];

    for (final node in nodes) {
      switch (node.type) {
        case MdType.heading:
          final sizes = [28.0, 24.0, 20.0, 18.0, 16.0, 14.0];
          final fontSize = sizes[(node.level - 1).clamp(0, 5)];
          children.add(Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: RichText(
              text: TextSpan(
                children: _renderInline(
                  node.text,
                  TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ));
          if (node.level <= 2) {
            children.add(Divider(
              height: 8,
              color: theme.dividerColor.withValues(alpha: 0.3),
            ));
          }

        case MdType.paragraph:
          children.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: RichText(
              text: TextSpan(
                children: _renderInline(
                  node.text,
                  TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ));

        case MdType.codeBlock:
          children.add(Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (node.meta != null && node.meta!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      node.meta!,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                SelectableText(
                  node.text,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ));

        case MdType.blockquote:
          children.add(Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  width: 3,
                ),
              ),
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
            ),
            child: RichText(
              text: TextSpan(
                children: _renderInline(
                  node.text,
                  TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ));

        case MdType.unorderedList:
          for (final item in node.children) {
            children.add(Padding(
              padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  )),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: _renderInline(
                          item,
                          TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ));
          }

        case MdType.orderedList:
          for (var j = 0; j < node.children.length; j++) {
            children.add(Padding(
              padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('${j + 1}. ', style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    )),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: _renderInline(
                          node.children[j],
                          TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ));
          }

        case MdType.hr:
          children.add(const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(thickness: 1),
          ));

        case MdType.blank:
          children.add(const SizedBox(height: 8));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _controller.text;
    final words = _service.wordCount(text);
    final lines = _service.lineCount(text);
    final readTime = _service.readingTimeMinutes(text);
    final isWide = MediaQuery.of(context).size.width > 600;

    Widget editor = Column(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
            decoration: const InputDecoration(
              hintText: 'Type your Markdown here…',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );

    Widget preview = Container(
      decoration: BoxDecoration(
        border: isWide
            ? Border(left: BorderSide(color: theme.dividerColor))
            : Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: text.isEmpty
          ? Center(
              child: Text(
                'Preview will appear here…',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            )
          : _buildPreview(text),
    );

    Widget body;
    if (isWide) {
      // Side-by-side on wide screens
      body = Row(
        children: [
          Expanded(child: editor),
          Expanded(child: preview),
        ],
      );
    } else {
      // Stacked with toggle on narrow screens
      body = _showEditor ? editor : preview;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Preview'),
        actions: [
          if (!isWide)
            IconButton(
              icon: Icon(_showEditor ? Icons.visibility : Icons.edit),
              tooltip: _showEditor ? 'Show preview' : 'Show editor',
              onPressed: () => setState(() => _showEditor = !_showEditor),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'copy':
                  _copy();
                case 'clear':
                  _clear();
                case 'sample':
                  _loadSample();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'copy', child: ListTile(
                leading: Icon(Icons.copy), title: Text('Copy Markdown'),
                dense: true, contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'sample', child: ListTile(
                leading: Icon(Icons.auto_awesome), title: Text('Load Sample'),
                dense: true, contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'clear', child: ListTile(
                leading: Icon(Icons.clear_all), title: Text('Clear'),
                dense: true, contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Row(
              children: [
                _StatChip(icon: Icons.text_fields, label: '$words words'),
                const SizedBox(width: 12),
                _StatChip(icon: Icons.format_list_numbered, label: '$lines lines'),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.timer,
                  label: readTime < 1
                      ? '<1 min read'
                      : '${readTime.ceil()} min read',
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
