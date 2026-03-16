import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/watchlist_item.dart';
import 'package:everything/core/services/watchlist_service.dart';

void main() {
  const service = WatchlistService();

  late List<WatchlistItem> items;

  setUp(() {
    items = service.sampleItems();
  });

  group('WatchlistItem', () {
    test('fromJson/toJson round-trip', () {
      for (final item in items) {
        final json = item.toJson();
        final restored = WatchlistItem.fromJson(json);
        expect(restored.id, item.id);
        expect(restored.title, item.title);
        expect(restored.mediaType, item.mediaType);
        expect(restored.status, item.status);
        expect(restored.genres.length, item.genres.length);
        expect(restored.rating, item.rating);
        expect(restored.isFavorite, item.isFavorite);
      }
    });

    test('progress calculation', () {
      final show = items.firstWhere((i) => i.title == 'Severance');
      expect(show.progress, closeTo(12 / 19, 0.01));
    });

    test('progress is 0 when no total episodes', () {
      final movie = items.firstWhere((i) => i.title == 'Inception');
      expect(movie.progress, 0.0);
    });

    test('copyWith preserves fields', () {
      final item = items.first;
      final copy = item.copyWith(rating: 7.5, isFavorite: true);
      expect(copy.title, item.title);
      expect(copy.rating, 7.5);
      expect(copy.isFavorite, true);
    });

    test('daysOnList is non-negative', () {
      for (final item in items) {
        expect(item.daysOnList, greaterThanOrEqualTo(0));
      }
    });
  });

  group('WatchlistService', () {
    test('statusBreakdown counts correctly', () {
      final breakdown = service.statusBreakdown(items);
      final total = breakdown.values.fold(0, (a, b) => a + b);
      expect(total, items.length);
    });

    test('genreBreakdown counts across items', () {
      final breakdown = service.genreBreakdown(items);
      expect(breakdown.isNotEmpty, true);
      // Sci-fi appears in Inception, Severance, Dune = 3
      expect(breakdown[WatchlistGenre.scifi], 3);
    });

    test('mediaTypeBreakdown', () {
      final breakdown = service.mediaTypeBreakdown(items);
      expect(breakdown[WatchlistMediaType.movie], 2); // Inception, Dune
      expect(breakdown[WatchlistMediaType.tvShow], 3); // Breaking Bad, Severance, The Bear
      expect(breakdown[WatchlistMediaType.anime], 1); // Spirited Away
    });

    test('avgRating of completed items', () {
      final avg = service.avgRating(items);
      // Completed & rated: Inception(9), Breaking Bad(9.5), Spirited Away(8.5) → avg = 9.0
      expect(avg, closeTo(9.0, 0.01));
    });

    test('totalEpisodesWatched', () {
      final total = service.totalEpisodesWatched(items);
      // Breaking Bad: 62, Severance: 12, The Bear: 18 = 92
      expect(total, 92);
    });

    test('completionRate', () {
      final rate = service.completionRate(items);
      // 3 completed out of 6
      expect(rate, closeTo(0.5, 0.01));
    });

    test('topRated returns sorted desc', () {
      final top = service.topRated(items);
      expect(top.isNotEmpty, true);
      expect(top.first.title, 'Breaking Bad');
      for (int i = 1; i < top.length; i++) {
        expect(top[i].rating, lessThanOrEqualTo(top[i - 1].rating));
      }
    });

    test('favoriteGenre returns most common', () {
      final fav = service.favoriteGenre(items);
      expect(fav, isNotNull);
    });

    test('currentlyWatching returns only watching items', () {
      final watching = service.currentlyWatching(items);
      for (final item in watching) {
        expect(item.status, WatchStatus.watching);
      }
    });

    test('randomPick returns plan-to-watch item', () {
      final pick = service.randomPick(items);
      expect(pick, isNotNull);
      expect(pick!.status, WatchStatus.planToWatch);
    });

    test('randomPick returns null when no plan-to-watch', () {
      final noPlans = items
          .where((i) => i.status != WatchStatus.planToWatch)
          .toList();
      expect(service.randomPick(noPlans), isNull);
    });

    test('platformBreakdown counts platforms', () {
      final breakdown = service.platformBreakdown(items);
      expect(breakdown['Netflix'], 2); // Inception + Breaking Bad
      expect(breakdown['Apple TV+'], 1);
    });

    test('sampleItems returns non-empty list', () {
      expect(service.sampleItems().isNotEmpty, true);
    });

    test('completionRate of empty list is 0', () {
      expect(service.completionRate([]), 0.0);
    });

    test('avgRating of empty list is 0', () {
      expect(service.avgRating([]), 0.0);
    });
  });

  group('Enums', () {
    test('WatchlistGenre has labels and emojis', () {
      for (final g in WatchlistGenre.values) {
        expect(g.label.isNotEmpty, true);
        expect(g.emoji.isNotEmpty, true);
      }
    });

    test('WatchlistMediaType has labels', () {
      for (final t in WatchlistMediaType.values) {
        expect(t.label.isNotEmpty, true);
      }
    });

    test('WatchStatus has labels and colors', () {
      for (final s in WatchStatus.values) {
        expect(s.label.isNotEmpty, true);
        expect(s.emoji.isNotEmpty, true);
      }
    });
  });
}
