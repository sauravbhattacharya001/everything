// Unit tests for MarkdownPreviewService.
//
// These exercise the block-level parser and the small text utilities. They
// also lock in the behaviour that was tightened during the perf refactor:
//   * hoisted regexes do not change parsing semantics for the common cases,
//   * HR lines of any length >= 3 (`---`, `----`, `* * * *`) are recognised
//     (the original `[\s\1]*` inside a character class was a bug — Dart does
//     not honour backreferences inside character classes, so 4+ dashes used
//     to fall through to the paragraph branch),
//   * unordered/ordered lists collapse contiguous items into a single node.

import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/markdown_preview_service.dart';

void main() {
  late MarkdownPreviewService svc;

  setUp(() {
    svc = MarkdownPreviewService();
  });

  group('parse — empty / blank', () {
    test('empty string returns empty list', () {
      expect(svc.parse(''), isEmpty);
    });

    test('only a blank line returns a single blank node', () {
      final nodes = svc.parse('\n');
      expect(nodes, hasLength(2));
      expect(nodes.every((n) => n.type == MdType.blank), isTrue);
    });
  });

  group('parse — headings', () {
    test('# through ###### map to levels 1..6', () {
      for (var i = 1; i <= 6; i++) {
        final hashes = '#' * i;
        final nodes = svc.parse('$hashes Title $i');
        expect(nodes, hasLength(1));
        expect(nodes.first.type, MdType.heading);
        expect(nodes.first.level, i);
        expect(nodes.first.text, 'Title $i');
      }
    });

    test('seven hashes is treated as a paragraph (max heading is h6)', () {
      final nodes = svc.parse('####### Too deep');
      expect(nodes.single.type, MdType.paragraph);
    });
  });

  group('parse — horizontal rule', () {
    test('three-dash rule is recognised', () {
      expect(svc.parse('---').single.type, MdType.hr);
    });

    test('four-dash rule is recognised (regression: old regex rejected it)', () {
      // The pre-refactor regex `^([-*_])\s*\1\s*\1[\s\1]*$` treated `\1`
      // inside a character class as the literal character "1", so a four-dash
      // line was only matched if it happened to contain a literal "1". This
      // test pins down the fixed behaviour.
      expect(svc.parse('----').single.type, MdType.hr);
      expect(svc.parse('--------').single.type, MdType.hr);
    });

    test('spaced rule and asterisk/underscore variants', () {
      expect(svc.parse('- - -').single.type, MdType.hr);
      expect(svc.parse('***').single.type, MdType.hr);
      expect(svc.parse('___').single.type, MdType.hr);
      expect(svc.parse('* * * *').single.type, MdType.hr);
    });

    test('two-dash line is a paragraph, not a rule', () {
      expect(svc.parse('--').single.type, MdType.paragraph);
    });

    test('mixed marker chars are not a rule', () {
      // `-*-` mixes markers; HR requires a single marker character.
      expect(svc.parse('-*-').single.type, MdType.paragraph);
    });
  });

  group('parse — fenced code block', () {
    test('captures language and inner lines verbatim', () {
      const src = '```dart\nvoid main() {\n  print(1);\n}\n```';
      final nodes = svc.parse(src);
      expect(nodes, hasLength(1));
      final node = nodes.single;
      expect(node.type, MdType.codeBlock);
      expect(node.meta, 'dart');
      expect(node.text, 'void main() {\n  print(1);\n}');
    });

    test('unclosed code block consumes to EOF without throwing', () {
      const src = '```\nhello\nworld';
      final nodes = svc.parse(src);
      expect(nodes.single.type, MdType.codeBlock);
      expect(nodes.single.text, 'hello\nworld');
      expect(nodes.single.meta, isNull);
    });
  });

  group('parse — blockquote', () {
    test('consecutive `> ` lines collapse into one blockquote', () {
      const src = '> first\n> second\n> third';
      final nodes = svc.parse(src);
      expect(nodes, hasLength(1));
      expect(nodes.single.type, MdType.blockquote);
      expect(nodes.single.text, 'first\nsecond\nthird');
    });
  });

  group('parse — lists', () {
    test('unordered list collapses contiguous items', () {
      const src = '- one\n- two\n- three';
      final nodes = svc.parse(src);
      expect(nodes, hasLength(1));
      expect(nodes.single.type, MdType.unorderedList);
      expect(nodes.single.children, ['one', 'two', 'three']);
    });

    test('unordered list accepts -, * and + markers', () {
      for (final marker in ['-', '*', '+']) {
        final nodes = svc.parse('$marker item');
        expect(nodes.single.type, MdType.unorderedList);
        expect(nodes.single.children, ['item']);
      }
    });

    test('ordered list strips the numeric prefix', () {
      const src = '1. one\n2. two\n10. ten';
      final nodes = svc.parse(src);
      expect(nodes.single.type, MdType.orderedList);
      expect(nodes.single.children, ['one', 'two', 'ten']);
    });

    test('blank line ends a list (next item belongs to a new node)', () {
      const src = '- one\n\n- two';
      final nodes = svc.parse(src);
      // [unorderedList(one), blank, unorderedList(two)]
      expect(nodes.map((n) => n.type).toList(), [
        MdType.unorderedList,
        MdType.blank,
        MdType.unorderedList,
      ]);
    });
  });

  group('parse — mixed document', () {
    test('preserves block order and counts', () {
      const fence = '```';
      final src = '# Title\n\n'
          'Paragraph one.\n\n'
          '- a\n- b\n\n'
          '$fence\ncode\n$fence\n\n'
          '---\n\n'
          '> quote';
      final types = svc.parse(src).map((n) => n.type).toList();
      expect(types, [
        MdType.heading,
        MdType.blank,
        MdType.paragraph,
        MdType.blank,
        MdType.unorderedList,
        MdType.blank,
        MdType.codeBlock,
        MdType.blank,
        MdType.hr,
        MdType.blank,
        MdType.blockquote,
      ]);
    });
  });

  group('wordCount / lineCount / readingTime', () {
    test('wordCount ignores extra whitespace', () {
      expect(svc.wordCount(''), 0);
      expect(svc.wordCount('   '), 0);
      expect(svc.wordCount('hello   world'), 2);
      expect(svc.wordCount(' one\ttwo\nthree '), 3);
    });

    test('lineCount returns 0 for empty and counts split lines otherwise', () {
      expect(svc.lineCount(''), 0);
      expect(svc.lineCount('a'), 1);
      expect(svc.lineCount('a\nb\nc'), 3);
    });

    test('readingTimeMinutes uses a 200 wpm baseline', () {
      // 400 words ~ 2 minutes.
      final words = List.filled(400, 'word').join(' ');
      expect(svc.readingTimeMinutes(words), closeTo(2.0, 1e-9));
      expect(svc.readingTimeMinutes(''), 0.0);
    });
  });
}
