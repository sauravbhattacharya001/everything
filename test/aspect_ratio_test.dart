import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/aspect_ratio_service.dart';

void main() {
  group('AspectRatioService', () {
    // ── gcd ──

    group('gcd', () {
      test('gcd of two coprime numbers is 1', () {
        expect(AspectRatioService.gcd(7, 11), 1);
        expect(AspectRatioService.gcd(13, 17), 1);
      });

      test('gcd of common factors', () {
        expect(AspectRatioService.gcd(12, 8), 4);
        expect(AspectRatioService.gcd(100, 75), 25);
        expect(AspectRatioService.gcd(1920, 1080), 120);
      });

      test('gcd with same number returns that number', () {
        expect(AspectRatioService.gcd(42, 42), 42);
      });

      test('gcd with 1 returns 1', () {
        expect(AspectRatioService.gcd(1, 999), 1);
      });

      test('gcd handles negative numbers (absolute value)', () {
        expect(AspectRatioService.gcd(-12, 8), 4);
        expect(AspectRatioService.gcd(12, -8), 4);
        expect(AspectRatioService.gcd(-12, -8), 4);
      });

      test('gcd with zero', () {
        expect(AspectRatioService.gcd(0, 5), 5);
        expect(AspectRatioService.gcd(7, 0), 7);
      });
    });

    // ── simplify ──

    group('simplify', () {
      test('simplifies 1920x1080 to 16:9', () {
        final (w, h) = AspectRatioService.simplify(1920, 1080);
        expect(w, 16);
        expect(h, 9);
      });

      test('simplifies 1024x768 to 4:3', () {
        final (w, h) = AspectRatioService.simplify(1024, 768);
        expect(w, 4);
        expect(h, 3);
      });

      test('simplifies 1080x1080 to 1:1', () {
        final (w, h) = AspectRatioService.simplify(1080, 1080);
        expect(w, 1);
        expect(h, 1);
      });

      test('simplifies already-reduced ratio', () {
        final (w, h) = AspectRatioService.simplify(16, 9);
        expect(w, 16);
        expect(h, 9);
      });

      test('returns (0, 0) for zero width', () {
        final (w, h) = AspectRatioService.simplify(0, 1080);
        expect(w, 0);
        expect(h, 0);
      });

      test('returns (0, 0) for zero height', () {
        final (w, h) = AspectRatioService.simplify(1920, 0);
        expect(w, 0);
        expect(h, 0);
      });

      test('returns (0, 0) for negative dimensions', () {
        final (w, h) = AspectRatioService.simplify(-1920, 1080);
        expect(w, 0);
        expect(h, 0);
      });
    });

    // ── calculateHeight ──

    group('calculateHeight', () {
      test('16:9 width 1920 yields height 1080', () {
        expect(AspectRatioService.calculateHeight(1920, 16, 9), closeTo(1080, 0.01));
      });

      test('4:3 width 1024 yields height 768', () {
        expect(AspectRatioService.calculateHeight(1024, 4, 3), closeTo(768, 0.01));
      });

      test('1:1 square', () {
        expect(AspectRatioService.calculateHeight(500, 1, 1), closeTo(500, 0.01));
      });

      test('returns 0 when ratioW is zero', () {
        expect(AspectRatioService.calculateHeight(1920, 0, 9), 0);
      });
    });

    // ── calculateWidth ──

    group('calculateWidth', () {
      test('16:9 height 1080 yields width 1920', () {
        expect(AspectRatioService.calculateWidth(1080, 16, 9), closeTo(1920, 0.01));
      });

      test('4:3 height 768 yields width 1024', () {
        expect(AspectRatioService.calculateWidth(768, 4, 3), closeTo(1024, 0.01));
      });

      test('returns 0 when ratioH is zero', () {
        expect(AspectRatioService.calculateWidth(1080, 16, 0), 0);
      });
    });

    // ── toDecimal ──

    group('toDecimal', () {
      test('16:9 as decimal', () {
        expect(AspectRatioService.toDecimal(16, 9), closeTo(1.778, 0.001));
      });

      test('4:3 as decimal', () {
        expect(AspectRatioService.toDecimal(4, 3), closeTo(1.333, 0.001));
      });

      test('1:1 as decimal', () {
        expect(AspectRatioService.toDecimal(1, 1), 1.0);
      });

      test('returns 0 when ratioH is zero', () {
        expect(AspectRatioService.toDecimal(16, 0), 0);
      });
    });

    // ── orientation ──

    group('orientation', () {
      test('landscape when width > height', () {
        expect(AspectRatioService.orientation(1920, 1080), 'Landscape');
      });

      test('portrait when height > width', () {
        expect(AspectRatioService.orientation(1080, 1920), 'Portrait');
      });

      test('square when equal', () {
        expect(AspectRatioService.orientation(1000, 1000), 'Square');
      });
    });

    // ── megapixels ──

    group('megapixels', () {
      test('1920x1080 is approximately 2.07 MP', () {
        expect(AspectRatioService.megapixels(1920, 1080), closeTo(2.074, 0.001));
      });

      test('4000x3000 is 12 MP', () {
        expect(AspectRatioService.megapixels(4000, 3000), 12.0);
      });

      test('zero dimensions yield 0 MP', () {
        expect(AspectRatioService.megapixels(0, 1080), 0);
      });
    });

    // ── scale ──

    group('scale', () {
      test('scale by 2x doubles dimensions', () {
        final (w, h) = AspectRatioService.scale(100, 50, 2.0);
        expect(w, 200);
        expect(h, 100);
      });

      test('scale by 0.5 halves dimensions', () {
        final (w, h) = AspectRatioService.scale(1920, 1080, 0.5);
        expect(w, 960);
        expect(h, 540);
      });

      test('scale by 1 preserves dimensions', () {
        final (w, h) = AspectRatioService.scale(800, 600, 1.0);
        expect(w, 800);
        expect(h, 600);
      });
    });

    // ── fitWithin ──

    group('fitWithin', () {
      test('fits landscape image into smaller box', () {
        // 1920x1080 into 960x960
        final (w, h) = AspectRatioService.fitWithin(1920, 1080, 960, 960);
        expect(w, closeTo(960, 0.01));
        expect(h, closeTo(540, 0.01));
      });

      test('fits portrait image into landscape box', () {
        // 1080x1920 into 960x960
        final (w, h) = AspectRatioService.fitWithin(1080, 1920, 960, 960);
        expect(w, closeTo(540, 0.01));
        expect(h, closeTo(960, 0.01));
      });

      test('preserves aspect ratio', () {
        final (w, h) = AspectRatioService.fitWithin(1600, 900, 800, 600);
        final originalRatio = 1600 / 900;
        final fittedRatio = w / h;
        expect(fittedRatio, closeTo(originalRatio, 0.01));
      });

      test('returns (0, 0) for zero input dimensions', () {
        final (w, h) = AspectRatioService.fitWithin(0, 0, 800, 600);
        expect(w, 0);
        expect(h, 0);
      });

      test('image smaller than box scales up to fit', () {
        // 100x100 into 200x300 — scale limited by width
        final (w, h) = AspectRatioService.fitWithin(100, 100, 200, 300);
        expect(w, closeTo(200, 0.01));
        expect(h, closeTo(200, 0.01));
      });
    });

    // ── presets ──

    group('presets', () {
      test('contains standard aspect ratios', () {
        final labels = AspectRatioService.presets.map((p) => p.label).toList();
        expect(labels, contains('16:9'));
        expect(labels, contains('4:3'));
        expect(labels, contains('1:1'));
        expect(labels, contains('9:16'));
      });

      test('all presets have non-empty labels and descriptions', () {
        for (final preset in AspectRatioService.presets) {
          expect(preset.label.isNotEmpty, isTrue);
          expect(preset.description.isNotEmpty, isTrue);
          expect(preset.w, greaterThan(0));
          expect(preset.h, greaterThan(0));
        }
      });

      test('at least 10 presets available', () {
        expect(AspectRatioService.presets.length, greaterThanOrEqualTo(10));
      });
    });
  });
}
