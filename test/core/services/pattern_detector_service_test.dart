import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/pattern_detector_service.dart';

void main() {
  group('PatternDetectorService.generateDemoData', () {
    test('is deterministic across repeated calls on the same instance', () {
      // Regression test for issue #148: previously the RNG was a class-level
      // `static final Random(42)` shared across every call, so the second
      // invocation consumed RNG state left over from the first and returned
      // different values.
      final svc = PatternDetectorService();
      final a = svc.generateDemoData().first;
      final b = svc.generateDemoData().first;
      expect(a.keys, equals(b.keys));
      for (final key in a.keys) {
        expect(b[key], equals(a[key]),
            reason: 'tracker "$key" should be identical across calls');
      }
    });

    test('is deterministic across different instances', () {
      final a = PatternDetectorService().generateDemoData().first;
      final b = PatternDetectorService().generateDemoData().first;
      for (final key in a.keys) {
        expect(b[key], equals(a[key]),
            reason: 'tracker "$key" should match across instances');
      }
    });

    test('honours custom seed and produces different data for different seeds', () {
      final svc = PatternDetectorService();
      final a = svc.generateDemoData(seed: 7).first['Mood']!;
      final b = svc.generateDemoData(seed: 7).first['Mood']!;
      final c = svc.generateDemoData(seed: 99).first['Mood']!;
      expect(b, equals(a));
      expect(c, isNot(equals(a)));
    });

    test('produces all 12 declared trackers with 30 days each', () {
      final data = PatternDetectorService().generateDemoData().first;
      expect(data.length, PatternDetectorService.trackers.length);
      for (final name in PatternDetectorService.trackers) {
        expect(data.containsKey(name), isTrue, reason: 'missing tracker $name');
        expect(data[name]!.length, 30);
      }
    });
  });

  group('PatternDetectorService.pearson', () {
    final svc = PatternDetectorService();

    test('returns 1.0 for perfectly correlated series', () {
      final x = List<double>.generate(10, (i) => i.toDouble());
      final y = List<double>.generate(10, (i) => 2.0 * i + 3);
      expect(svc.pearson(x, y), closeTo(1.0, 1e-9));
    });

    test('returns -1.0 for perfectly anti-correlated series', () {
      final x = List<double>.generate(10, (i) => i.toDouble());
      final y = List<double>.generate(10, (i) => -i.toDouble());
      expect(svc.pearson(x, y), closeTo(-1.0, 1e-9));
    });

    test('returns 0 when either series has zero variance', () {
      final x = List<double>.filled(10, 5);
      final y = List<double>.generate(10, (i) => i.toDouble());
      expect(svc.pearson(x, y), 0);
    });

    test('returns 0 when n < 3', () {
      expect(svc.pearson([1, 2], [3, 4]), 0);
    });

    test('offset-based form matches sublist-based form', () {
      final x = List<double>.generate(20, (i) => i.toDouble() * 1.7 - 4);
      final y = List<double>.generate(20, (i) => (i * i).toDouble() % 13);
      // Compute lagged correlation (yesterday's x → today's y) via offsets:
      final lag = svc.pearson(x, y, xOff: 0, yOff: 1, count: 19);
      // …and the slower sublist form for comparison:
      final ref = svc.pearson(x.sublist(0, 19), y.sublist(1, 20));
      expect(lag, closeTo(ref, 1e-12));
    });
  });

  group('PatternDetectorService.correlationMatrix', () {
    test('is symmetric and has unit diagonal', () {
      final svc = PatternDetectorService();
      final data = svc.generateDemoData().first;
      final m = svc.correlationMatrix(data);
      for (final a in data.keys) {
        expect(m[a]![a], 1.0);
        for (final b in data.keys) {
          expect(m[a]![b], closeTo(m[b]![a]!, 1e-12));
        }
      }
    });
  });

  group('PatternDetectorService.discoverPatterns', () {
    test('returns same patterns when called twice (deterministic input)', () {
      final svc = PatternDetectorService();
      final p1 = svc.discoverPatterns(svc.generateDemoData().first);
      final p2 = svc.discoverPatterns(svc.generateDemoData().first);
      expect(p1.length, p2.length);
      for (int i = 0; i < p1.length; i++) {
        expect(p1[i].trackerA, p2[i].trackerA);
        expect(p1[i].trackerB, p2[i].trackerB);
        expect(p1[i].r, closeTo(p2[i].r, 1e-12));
      }
    });
  });
}
