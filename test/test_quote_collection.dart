import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/quote_collection_service.dart';
import 'package:everything/models/quote_entry.dart';

void main() {
  late QuoteCollectionService service;

  QuoteEntry _make({
    String id = 'q1',
    String text = 'Test quote',
    String? author,
    QuoteCategory category = QuoteCategory.motivation,
    List<String> tags = const [],
    bool isFavorite = false,
  }) =>
      QuoteEntry(
        id: id,
        text: text,
        author: author,
        category: category,
        tags: tags,
        isFavorite: isFavorite,
        createdAt: DateTime(2026, 1, 1),
      );

  setUp(() {
    service = QuoteCollectionService();
  });

  group('QuoteEntry model', () {
    test('wordCount counts words correctly', () {
      final q = _make(text: 'Hello world foo bar');
      expect(q.wordCount, 4);
    });

    test('wordCount handles empty', () {
      final q = _make(text: '');
      expect(q.wordCount, 0);
    });

    test('toggleFavorite flips state', () {
      final q = _make(isFavorite: false);
      expect(q.toggleFavorite().isFavorite, true);
      expect(q.toggleFavorite().toggleFavorite().isFavorite, false);
    });

    test('toJson and fromJson roundtrip', () {
      final q = _make(
        text: 'Be yourself',
        author: 'Oscar Wilde',
        category: QuoteCategory.humor,
        tags: ['self', 'authenticity'],
      );
      final json = q.toJson();
      final restored = QuoteEntry.fromJson(json);
      expect(restored.id, q.id);
      expect(restored.text, q.text);
      expect(restored.author, q.author);
      expect(restored.category, q.category);
      expect(restored.tags, q.tags);
    });

    test('copyWith preserves unchanged fields', () {
      final q = _make(text: 'Original', author: 'Author');
      final copy = q.copyWith(text: 'Changed');
      expect(copy.text, 'Changed');
      expect(copy.author, 'Author');
      expect(copy.id, q.id);
    });
  });

  group('QuoteCollectionService', () {
    test('addQuote increases count', () {
      expect(service.totalQuotes, 0);
      service.addQuote(_make());
      expect(service.totalQuotes, 1);
    });

    test('removeQuote removes by id', () {
      service.addQuote(_make(id: 'a'));
      service.addQuote(_make(id: 'b'));
      expect(service.removeQuote('a'), true);
      expect(service.totalQuotes, 1);
      expect(service.removeQuote('nonexistent'), false);
    });

    test('updateQuote replaces in place', () {
      service.addQuote(_make(id: 'x', text: 'old'));
      final updated = _make(id: 'x', text: 'new');
      expect(service.updateQuote(updated), true);
      expect(service.quotes.first.text, 'new');
    });

    test('toggleFavorite works', () {
      service.addQuote(_make(id: 'f1', isFavorite: false));
      final toggled = service.toggleFavorite('f1');
      expect(toggled?.isFavorite, true);
      expect(service.favoriteCount, 1);
    });

    test('search finds by text', () {
      service.addQuote(_make(id: 'a', text: 'The quick brown fox'));
      service.addQuote(_make(id: 'b', text: 'Lazy dog'));
      expect(service.search('quick').length, 1);
      expect(service.search('QUICK').length, 1); // case-insensitive
    });

    test('search finds by author', () {
      service.addQuote(_make(id: 'a', text: 'x', author: 'Einstein'));
      service.addQuote(_make(id: 'b', text: 'y', author: 'Socrates'));
      expect(service.search('einstein').length, 1);
    });

    test('search finds by tags', () {
      service.addQuote(_make(id: 'a', text: 'x', tags: ['wisdom', 'life']));
      service.addQuote(_make(id: 'b', text: 'y', tags: ['humor']));
      expect(service.search('wisdom').length, 1);
    });

    test('search with empty query returns all', () {
      service.addQuote(_make(id: 'a'));
      service.addQuote(_make(id: 'b'));
      expect(service.search('').length, 2);
    });

    test('byCategory filters correctly', () {
      service.addQuote(_make(id: 'a', category: QuoteCategory.humor));
      service.addQuote(_make(id: 'b', category: QuoteCategory.wisdom));
      service.addQuote(_make(id: 'c', category: QuoteCategory.humor));
      expect(service.byCategory(QuoteCategory.humor).length, 2);
    });

    test('favorites returns only favorites', () {
      service.addQuote(_make(id: 'a', isFavorite: true));
      service.addQuote(_make(id: 'b', isFavorite: false));
      expect(service.favorites.length, 1);
    });

    test('authors returns unique sorted list', () {
      service.addQuote(_make(id: 'a', author: 'Zeno'));
      service.addQuote(_make(id: 'b', author: 'Albert'));
      service.addQuote(_make(id: 'c', author: 'Zeno'));
      service.addQuote(_make(id: 'd'));
      expect(service.authors, ['Albert', 'Zeno']);
    });

    test('byAuthor filters case-insensitively', () {
      service.addQuote(_make(id: 'a', author: 'Einstein'));
      service.addQuote(_make(id: 'b', author: 'einstein'));
      expect(service.byAuthor('Einstein').length, 2);
    });

    test('allTags returns unique sorted tags', () {
      service.addQuote(_make(id: 'a', tags: ['b', 'a']));
      service.addQuote(_make(id: 'b', tags: ['c', 'a']));
      expect(service.allTags, ['a', 'b', 'c']);
    });

    test('categoryBreakdown counts correctly', () {
      service.addQuote(_make(id: 'a', category: QuoteCategory.humor));
      service.addQuote(_make(id: 'b', category: QuoteCategory.humor));
      service.addQuote(_make(id: 'c', category: QuoteCategory.wisdom));
      final breakdown = service.categoryBreakdown;
      expect(breakdown[QuoteCategory.humor], 2);
      expect(breakdown[QuoteCategory.wisdom], 1);
    });

    test('longestQuote and shortestQuote', () {
      service.addQuote(_make(id: 'a', text: 'Short'));
      service.addQuote(_make(id: 'b', text: 'This is a much longer quote text'));
      expect(service.longestQuote?.id, 'b');
      expect(service.shortestQuote?.id, 'a');
    });

    test('averageWordCount calculates correctly', () {
      service.addQuote(_make(id: 'a', text: 'One two'));  // 2 words
      service.addQuote(_make(id: 'b', text: 'One two three four'));  // 4 words
      expect(service.averageWordCount, 3.0);
    });

    test('quoteOfTheDay is deterministic for same date', () {
      service.addQuote(_make(id: 'a', text: 'First'));
      service.addQuote(_make(id: 'b', text: 'Second'));
      service.addQuote(_make(id: 'c', text: 'Third'));
      final date = DateTime(2026, 3, 16);
      final q1 = service.quoteOfTheDay(date);
      final q2 = service.quoteOfTheDay(date);
      expect(q1?.id, q2?.id);
    });

    test('quoteOfTheDay returns null when empty', () {
      expect(service.quoteOfTheDay(), null);
    });

    test('randomQuote returns null when empty', () {
      expect(service.randomQuote(), null);
    });

    test('randomQuote returns a quote', () {
      service.addQuote(_make(id: 'a'));
      expect(service.randomQuote()?.id, 'a');
    });

    test('loadAll replaces all quotes', () {
      service.addQuote(_make(id: 'old'));
      service.loadAll([_make(id: 'new1'), _make(id: 'new2')]);
      expect(service.totalQuotes, 2);
      expect(service.quotes.first.id, 'new1');
    });

    test('sampleQuotes are valid', () {
      final samples = QuoteCollectionService.sampleQuotes;
      expect(samples.length, 6);
      for (final q in samples) {
        expect(q.text.isNotEmpty, true);
        expect(q.id.isNotEmpty, true);
      }
    });
  });
}
