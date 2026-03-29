import 'dart:math';

/// Modes of Lorem Ipsum generation.
enum LoremUnit { words, sentences, paragraphs }

/// Service that generates placeholder Latin text (Lorem Ipsum).
class LoremIpsumService {
  static const _classic = 'Lorem ipsum dolor sit amet, consectetur adipiscing '
      'elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';

  static const _words = [
    'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing',
    'elit', 'sed', 'do', 'eiusmod', 'tempor', 'incididunt', 'ut', 'labore',
    'et', 'dolore', 'magna', 'aliqua', 'enim', 'ad', 'minim', 'veniam',
    'quis', 'nostrud', 'exercitation', 'ullamco', 'laboris', 'nisi',
    'aliquip', 'ex', 'ea', 'commodo', 'consequat', 'duis', 'aute', 'irure',
    'in', 'reprehenderit', 'voluptate', 'velit', 'esse', 'cillum', 'fugiat',
    'nulla', 'pariatur', 'excepteur', 'sint', 'occaecat', 'cupidatat', 'non',
    'proident', 'sunt', 'culpa', 'qui', 'officia', 'deserunt', 'mollit',
    'anim', 'id', 'est', 'laborum', 'cras', 'justo', 'odio', 'dapibus',
    'ac', 'facilisis', 'egestas', 'semper', 'dictum', 'viverra', 'nam',
    'libero', 'tempus', 'blandit', 'volutpat', 'maecenas', 'accumsan',
    'lacus', 'vel', 'facilisi', 'morbi', 'tristique', 'senectus', 'netus',
    'fames', 'turpis', 'massa', 'tincidunt', 'arcu', 'vitae', 'elementum',
    'pulvinar', 'etiam', 'dignissim', 'diam', 'vulputate', 'praesent',
    'pellentesque', 'habitant', 'ante', 'primis', 'faucibus', 'orci',
    'luctus', 'ultrices', 'posuere', 'cubilia', 'curae', 'donec', 'velit',
    'pharetra', 'leo', 'integer', 'malesuada', 'bibendum', 'neque',
    'gravida', 'risus', 'pretium', 'fusce', 'feugiat', 'nisl', 'rhoncus',
    'mattis', 'scelerisque', 'mauris', 'imperdiet', 'augue', 'interdum',
    'porttitor', 'felis', 'euismod', 'ornare', 'sapien', 'placerat',
    'porta', 'condimentum', 'quisque', 'sagittis', 'purus', 'convallis',
    'suscipit', 'tellus', 'urna', 'hendrerit', 'iaculis', 'nunc',
  ];

  final _random = Random();

  /// Generate [count] random words.
  String generateWords(int count, {bool startClassic = true}) {
    if (count <= 0) return '';
    final buf = <String>[];
    if (startClassic && count >= 2) {
      buf.addAll(['Lorem', 'ipsum']);
      count -= 2;
    }
    for (var i = 0; i < count; i++) {
      buf.add(_words[_random.nextInt(_words.length)]);
    }
    return buf.join(' ');
  }

  /// Generate a single sentence of [wordCount] words.
  String _makeSentence(int wordCount) {
    final words = <String>[];
    for (var i = 0; i < wordCount; i++) {
      words.add(_words[_random.nextInt(_words.length)]);
    }
    words[0] = words[0][0].toUpperCase() + words[0].substring(1);
    return '${words.join(' ')}.';
  }

  /// Generate [count] sentences.
  String generateSentences(int count, {bool startClassic = true}) {
    if (count <= 0) return '';
    final sentences = <String>[];
    if (startClassic) {
      sentences.add(_classic);
      count--;
    }
    for (var i = 0; i < count; i++) {
      sentences.add(_makeSentence(8 + _random.nextInt(10)));
    }
    return sentences.join(' ');
  }

  /// Generate [count] paragraphs.
  String generateParagraphs(int count, {bool startClassic = true}) {
    if (count <= 0) return '';
    final paragraphs = <String>[];
    for (var i = 0; i < count; i++) {
      final sentenceCount = 3 + _random.nextInt(5);
      final useClassic = startClassic && i == 0;
      paragraphs.add(generateSentences(sentenceCount, startClassic: useClassic));
    }
    return paragraphs.join('\n\n');
  }

  /// Main entry point.
  String generate({
    required LoremUnit unit,
    required int count,
    bool startClassic = true,
  }) {
    switch (unit) {
      case LoremUnit.words:
        return generateWords(count, startClassic: startClassic);
      case LoremUnit.sentences:
        return generateSentences(count, startClassic: startClassic);
      case LoremUnit.paragraphs:
        return generateParagraphs(count, startClassic: startClassic);
    }
  }
}
