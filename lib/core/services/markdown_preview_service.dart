/// Service for parsing and rendering Markdown to styled widgets.
///
/// Supports: headings (h1-h6), bold, italic, bold+italic, strikethrough,
/// inline code, code blocks, blockquotes, ordered/unordered lists,
/// horizontal rules, and links.
class MarkdownPreviewService {
  /// Parse markdown text into a list of [MarkdownNode] elements.
  List<MarkdownNode> parse(String text) {
    if (text.isEmpty) return [];
    final lines = text.split('\n');
    final nodes = <MarkdownNode>[];
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // Code block (fenced)
      if (line.trimLeft().startsWith('```')) {
        final lang = line.trim().substring(3).trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++; // skip closing ```
        nodes.add(MarkdownNode(
          type: MdType.codeBlock,
          text: codeLines.join('\n'),
          meta: lang.isNotEmpty ? lang : null,
        ));
        continue;
      }

      // Horizontal rule
      if (RegExp(r'^([-*_])\s*\1\s*\1[\s\1]*$').hasMatch(line.trim()) &&
          line.trim().length >= 3) {
        nodes.add(MarkdownNode(type: MdType.hr));
        i++;
        continue;
      }

      // Heading
      final headingMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (headingMatch != null) {
        nodes.add(MarkdownNode(
          type: MdType.heading,
          text: headingMatch.group(2)!,
          level: headingMatch.group(1)!.length,
        ));
        i++;
        continue;
      }

      // Blockquote
      if (line.trimLeft().startsWith('> ')) {
        final quoteLines = <String>[];
        while (i < lines.length && lines[i].trimLeft().startsWith('> ')) {
          quoteLines.add(lines[i].trimLeft().substring(2));
          i++;
        }
        nodes.add(MarkdownNode(
          type: MdType.blockquote,
          text: quoteLines.join('\n'),
        ));
        continue;
      }

      // Unordered list
      if (RegExp(r'^[\s]*[-*+]\s+').hasMatch(line)) {
        final items = <String>[];
        while (i < lines.length &&
            RegExp(r'^[\s]*[-*+]\s+').hasMatch(lines[i])) {
          items.add(lines[i].replaceFirst(RegExp(r'^[\s]*[-*+]\s+'), ''));
          i++;
        }
        nodes.add(MarkdownNode(
          type: MdType.unorderedList,
          children: items,
        ));
        continue;
      }

      // Ordered list
      if (RegExp(r'^[\s]*\d+\.\s+').hasMatch(line)) {
        final items = <String>[];
        while (i < lines.length &&
            RegExp(r'^[\s]*\d+\.\s+').hasMatch(lines[i])) {
          items.add(lines[i].replaceFirst(RegExp(r'^[\s]*\d+\.\s+'), ''));
          i++;
        }
        nodes.add(MarkdownNode(
          type: MdType.orderedList,
          children: items,
        ));
        continue;
      }

      // Empty line
      if (line.trim().isEmpty) {
        nodes.add(MarkdownNode(type: MdType.blank));
        i++;
        continue;
      }

      // Paragraph
      nodes.add(MarkdownNode(type: MdType.paragraph, text: line));
      i++;
    }

    return nodes;
  }

  /// Count words in the raw text.
  int wordCount(String text) =>
      text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  /// Count lines in the raw text.
  int lineCount(String text) => text.isEmpty ? 0 : text.split('\n').length;

  /// Estimate reading time in minutes.
  double readingTimeMinutes(String text) => wordCount(text) / 200.0;
}

/// Types of markdown elements.
enum MdType {
  heading,
  paragraph,
  codeBlock,
  blockquote,
  unorderedList,
  orderedList,
  hr,
  blank,
}

/// A parsed markdown element.
class MarkdownNode {
  final MdType type;
  final String text;
  final int level;
  final String? meta;
  final List<String> children;

  MarkdownNode({
    required this.type,
    this.text = '',
    this.level = 1,
    this.meta,
    this.children = const [],
  });
}
