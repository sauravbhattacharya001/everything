/// Service for parsing and rendering Markdown to styled widgets.
///
/// Supports: headings (h1-h6), bold, italic, bold+italic, strikethrough,
/// inline code, code blocks, blockquotes, ordered/unordered lists,
/// horizontal rules, and links.
///
/// Performance: all regular expressions used by [parse] are compiled once as
/// `static final` fields, so parsing an N-line document constructs zero
/// [RegExp] instances per line. Previously, [parse] re-constructed up to five
/// regexes per loop iteration, which made parsing scale poorly on documents
/// containing many list items or long paragraphs.
class MarkdownPreviewService {
  // --- Hoisted block-level regexes (compiled once, reused for every line). ---

  /// Matches an ATX heading prefix (`#` to `######` followed by whitespace).
  static final RegExp _headingRe = RegExp(r'^(#{1,6})\s+(.+)$');

  /// Matches a horizontal rule made of `-`, `*`, or `_` characters,
  /// possibly separated by whitespace, with at least three repetitions.
  ///
  /// Examples that match: `---`, `***`, `___`, `- - -`, `----`, `* * * *`.
  /// The original implementation used `[\s\1]*` which Dart does not treat as
  /// a backreference inside a character class, so HR lines of more than three
  /// characters (e.g. `----`) were incorrectly rejected.
  static final RegExp _hrRe =
      RegExp(r'^[ \t]*([-*_])(?:[ \t]*\1){2,}[ \t]*$');

  /// Matches the start of an unordered list item (`-`, `*`, or `+`).
  static final RegExp _ulRe = RegExp(r'^\s*[-*+]\s+');

  /// Matches the start of an ordered list item (`1.`, `2.`, ...).
  static final RegExp _olRe = RegExp(r'^\s*\d+\.\s+');

  /// Word-splitting regex used by [wordCount].
  static final RegExp _wsRe = RegExp(r'\s+');

  /// Parse markdown text into a list of [MarkdownNode] elements.
  List<MarkdownNode> parse(String text) {
    if (text.isEmpty) return const [];
    final lines = text.split('\n');
    final nodes = <MarkdownNode>[];
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmedLeft = line.trimLeft();

      // Code block (fenced)
      if (trimmedLeft.startsWith('```')) {
        final lang = trimmedLeft.substring(3).trim();
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
      if (_hrRe.hasMatch(line)) {
        nodes.add(MarkdownNode(type: MdType.hr));
        i++;
        continue;
      }

      // Heading
      final headingMatch = _headingRe.firstMatch(line);
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
      if (trimmedLeft.startsWith('> ')) {
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
      if (_ulRe.hasMatch(line)) {
        final items = <String>[];
        while (i < lines.length && _ulRe.hasMatch(lines[i])) {
          items.add(lines[i].replaceFirst(_ulRe, ''));
          i++;
        }
        nodes.add(MarkdownNode(
          type: MdType.unorderedList,
          children: items,
        ));
        continue;
      }

      // Ordered list
      if (_olRe.hasMatch(line)) {
        final items = <String>[];
        while (i < lines.length && _olRe.hasMatch(lines[i])) {
          items.add(lines[i].replaceFirst(_olRe, ''));
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
      text.split(_wsRe).where((w) => w.isNotEmpty).length;

  /// Count lines in the raw text.
  int lineCount(String text) => text.isEmpty ? 0 : text.split('\n').length;

  /// Estimate reading time in minutes (200 words per minute).
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
