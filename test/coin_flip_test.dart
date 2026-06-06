import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/coin_flip_service.dart';

void main() {
  group('CoinFlipService', () {
    late CoinFlipService service;

    setUp(() {
      service = CoinFlipService();
    });

    // ── flip ──

    group('flip', () {
      test('returns a CoinFlipResult', () {
        final result = service.flip();
        expect(result, isA<CoinFlipResult>());
        expect(result.isHeads, isA<bool>());
      });

      test('adds result to history', () {
        expect(service.history, isEmpty);
        service.flip();
        expect(service.history.length, 1);
        service.flip();
        expect(service.history.length, 2);
      });

      test('result has a timestamp', () {
        final before = DateTime.now();
        final result = service.flip();
        final after = DateTime.now();
        expect(result.timestamp.isAfter(before) || result.timestamp.isAtSameMomentAs(before), isTrue);
        expect(result.timestamp.isBefore(after) || result.timestamp.isAtSameMomentAs(after), isTrue);
      });
    });

    // ── flipMultiple ──

    group('flipMultiple', () {
      test('returns requested number of results', () {
        final results = service.flipMultiple(10);
        expect(results.length, 10);
      });

      test('all results are added to history', () {
        service.flipMultiple(5);
        expect(service.history.length, 5);
      });

      test('zero flips returns empty list', () {
        final results = service.flipMultiple(0);
        expect(results, isEmpty);
      });
    });

    // ── clearHistory ──

    group('clearHistory', () {
      test('clears all history', () {
        service.flipMultiple(10);
        expect(service.history.length, 10);
        service.clearHistory();
        expect(service.history, isEmpty);
      });
    });

    // ── history immutability ──

    group('history', () {
      test('returned list is unmodifiable', () {
        service.flip();
        expect(() => service.history.add(CoinFlipResult(isHeads: true)),
            throwsA(isA<UnsupportedError>()));
      });
    });

    // ── getStats ──

    group('getStats', () {
      test('empty history yields all zeros', () {
        final stats = service.getStats();
        expect(stats.totalFlips, 0);
        expect(stats.heads, 0);
        expect(stats.tails, 0);
        expect(stats.headsPercentage, 0);
        expect(stats.tailsPercentage, 0);
      });

      test('heads + tails equals totalFlips', () {
        service.flipMultiple(100);
        final stats = service.getStats();
        expect(stats.heads + stats.tails, stats.totalFlips);
        expect(stats.totalFlips, 100);
      });

      test('percentages sum to 100', () {
        service.flipMultiple(50);
        final stats = service.getStats();
        expect(stats.headsPercentage + stats.tailsPercentage, closeTo(100, 0.001));
      });

      test('currentStreak is at least 1 after any flip', () {
        service.flip();
        final stats = service.getStats();
        expect(stats.currentStreak, greaterThanOrEqualTo(1));
      });

      test('longestStreak is at least 1 after any flip', () {
        service.flip();
        final stats = service.getStats();
        expect(stats.longestStreak, greaterThanOrEqualTo(1));
      });

      test('longestStreak is at least as large as currentStreak', () {
        service.flipMultiple(50);
        final stats = service.getStats();
        expect(stats.longestStreak, greaterThanOrEqualTo(stats.currentStreak));
      });

      test('currentStreakLabel contains the streak count', () {
        service.flipMultiple(10);
        final stats = service.getStats();
        expect(stats.currentStreakLabel, contains(stats.currentStreak.toString()));
      });

      test('currentStreakLabel contains Heads or Tails', () {
        service.flip();
        final stats = service.getStats();
        expect(
          stats.currentStreakLabel.contains('Heads') ||
              stats.currentStreakLabel.contains('Tails'),
          isTrue,
        );
      });

      test('longestStreakLabel contains Heads or Tails', () {
        service.flip();
        final stats = service.getStats();
        expect(
          stats.longestStreakLabel.contains('Heads') ||
              stats.longestStreakLabel.contains('Tails'),
          isTrue,
        );
      });
    });
  });

  // ── CoinFlipResult ──

  group('CoinFlipResult', () {
    test('label returns Heads when isHeads is true', () {
      final result = CoinFlipResult(isHeads: true);
      expect(result.label, 'Heads');
    });

    test('label returns Tails when isHeads is false', () {
      final result = CoinFlipResult(isHeads: false);
      expect(result.label, 'Tails');
    });

    test('uses provided timestamp', () {
      final ts = DateTime(2020, 1, 1, 12, 0);
      final result = CoinFlipResult(isHeads: true, timestamp: ts);
      expect(result.timestamp, ts);
    });

    test('uses current time when timestamp not provided', () {
      final before = DateTime.now();
      final result = CoinFlipResult(isHeads: false);
      final after = DateTime.now();
      expect(result.timestamp.isAfter(before) || result.timestamp.isAtSameMomentAs(before), isTrue);
      expect(result.timestamp.isBefore(after) || result.timestamp.isAtSameMomentAs(after), isTrue);
    });
  });

  // ── CoinFlipStats ──

  group('CoinFlipStats', () {
    test('headsPercentage is 0 when no flips', () {
      final stats = CoinFlipStats(
        totalFlips: 0, heads: 0, tails: 0,
        currentStreak: 0, currentStreakLabel: '-',
        longestStreak: 0, longestStreakLabel: '-',
      );
      expect(stats.headsPercentage, 0);
      expect(stats.tailsPercentage, 0);
    });

    test('percentages are correct with known data', () {
      final stats = CoinFlipStats(
        totalFlips: 100, heads: 60, tails: 40,
        currentStreak: 3, currentStreakLabel: '3 Heads',
        longestStreak: 7, longestStreakLabel: '7 Tails',
      );
      expect(stats.headsPercentage, 60.0);
      expect(stats.tailsPercentage, 40.0);
    });
  });
}
