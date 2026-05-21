import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/utils/date_streak_calculator.dart';

/// Regression tests for issue #147: `DateStreakCalculator` loses streaks
/// across the spring-forward DST boundary because adjacent local midnights
/// are only 23 hours apart, so `Duration.inDays` rounds down to 0.
///
/// These tests are written to work on **any** host time zone:
///  - On a UTC host the original (buggy) implementation already passed; the
///    extra assertions still hold.
///  - On a DST-observing host (America/Los_Angeles, America/New_York, most
///    of Europe, AU/NZ) the spring-forward and fall-back cases below were
///    silent failures pre-fix and are the actual regression guards.
void main() {
  group('DateStreakCalculator - basic behaviour', () {
    test('empty input yields zero/zero', () {
      final r = DateStreakCalculator.compute(
        const <DateTime>[],
        referenceDate: DateTime(2026, 5, 21),
      );
      expect(r.current, 0);
      expect(r.longest, 0);
    });

    test('single date today => current 1, longest 1', () {
      final r = DateStreakCalculator.compute(
        [DateTime(2026, 5, 21)],
        referenceDate: DateTime(2026, 5, 21),
      );
      expect(r.current, 1);
      expect(r.longest, 1);
    });

    test('four consecutive days with no DST seam', () {
      final r = DateStreakCalculator.compute(
        [
          DateTime(2026, 5, 18),
          DateTime(2026, 5, 19),
          DateTime(2026, 5, 20),
          DateTime(2026, 5, 21),
        ],
        referenceDate: DateTime(2026, 5, 21),
      );
      expect(r.current, 4);
      expect(r.longest, 4);
    });

    test('streak broken by a gap day', () {
      final r = DateStreakCalculator.compute(
        [
          DateTime(2026, 5, 18),
          DateTime(2026, 5, 19),
          // gap on the 20th
          DateTime(2026, 5, 21),
        ],
        referenceDate: DateTime(2026, 5, 21),
      );
      expect(r.current, 1, reason: 'only today counts after the gap');
      expect(r.longest, 2, reason: 'previous run of 18-19 is the longest');
    });

    test('streak counts yesterday as still-active', () {
      final r = DateStreakCalculator.compute(
        [
          DateTime(2026, 5, 19),
          DateTime(2026, 5, 20),
        ],
        referenceDate: DateTime(2026, 5, 21),
      );
      expect(r.current, 2);
      expect(r.longest, 2);
    });

    test('streak broken if last entry is older than yesterday', () {
      final r = DateStreakCalculator.compute(
        [
          DateTime(2026, 5, 17),
          DateTime(2026, 5, 18),
          DateTime(2026, 5, 19),
        ],
        referenceDate: DateTime(2026, 5, 21),
      );
      expect(r.current, 0);
      expect(r.longest, 3);
    });

    test('duplicate dates within the same day are collapsed', () {
      final r = DateStreakCalculator.compute(
        [
          DateTime(2026, 5, 20, 8, 0),
          DateTime(2026, 5, 20, 23, 0),
          DateTime(2026, 5, 21, 7, 30),
        ],
        referenceDate: DateTime(2026, 5, 21, 12, 0),
      );
      expect(r.current, 2);
      expect(r.longest, 2);
    });
  });

  group('DateStreakCalculator - DST regression (issue #147)', () {
    // America/New_York spring-forward: Sun 2025-03-09 02:00 -> 03:00.
    // America/Los_Angeles spring-forward: same wall-clock instant.
    // Most of Europe spring-forward: Sun 2025-03-30.
    // On any DST-observing host, two local midnights straddling these dates
    // are only 23 h apart; the buggy implementation collapsed the streak.

    test('US spring-forward Mar 8 -> 9 -> 10 stays a 3-streak', () {
      final r = DateStreakCalculator.compute(
        [
          DateTime(2025, 3, 8),
          DateTime(2025, 3, 9), // DST seam in US
          DateTime(2025, 3, 10),
        ],
        referenceDate: DateTime(2025, 3, 10),
      );
      expect(r.current, 3, reason: 'streak must survive US spring-forward');
      expect(r.longest, 3);
    });

    test('US spring-forward full week Mar 7..10 stays a 4-streak', () {
      final r = DateStreakCalculator.compute(
        [
          DateTime(2025, 3, 7),
          DateTime(2025, 3, 8),
          DateTime(2025, 3, 9),
          DateTime(2025, 3, 10),
        ],
        referenceDate: DateTime(2025, 3, 10),
      );
      expect(r.current, 4);
      expect(r.longest, 4);
    });

    test('EU spring-forward Mar 29 -> 30 -> 31 stays a 3-streak', () {
      final r = DateStreakCalculator.compute(
        [
          DateTime(2025, 3, 29),
          DateTime(2025, 3, 30), // DST seam in EU
          DateTime(2025, 3, 31),
        ],
        referenceDate: DateTime(2025, 3, 31),
      );
      expect(r.current, 3);
      expect(r.longest, 3);
    });

    test('US fall-back Nov 1 -> 2 -> 3 stays a 3-streak', () {
      // Fall-back gives a 25-hour day; old implementation handled this case
      // accidentally (.inDays still rounded down to 1), but pin it down so
      // future changes don't accidentally regress.
      final r = DateStreakCalculator.compute(
        [
          DateTime(2025, 11, 1),
          DateTime(2025, 11, 2), // DST seam in US (fall-back)
          DateTime(2025, 11, 3),
        ],
        referenceDate: DateTime(2025, 11, 3),
      );
      expect(r.current, 3);
      expect(r.longest, 3);
    });

    test('current-streak anchor "today is yesterday" works across DST', () {
      // User logged on Mar 8 and Mar 9 but not yet on Mar 10. Mar 9 is
      // "yesterday" from Mar 10, so the streak is still active = 2.
      // Pre-fix on a DST-observing host this returned 0 because the
      // today->Mar 9 diff was 0 days, not 1.
      final r = DateStreakCalculator.compute(
        [
          DateTime(2025, 3, 8),
          DateTime(2025, 3, 9),
        ],
        referenceDate: DateTime(2025, 3, 10),
      );
      expect(r.current, 2);
      expect(r.longest, 2);
    });

    test('long streak that contains the DST seam', () {
      // 10-day streak Mar 3..12 2025 contains the US spring-forward seam.
      final dates = <DateTime>[
        for (int d = 3; d <= 12; d++) DateTime(2025, 3, d),
      ];
      final r = DateStreakCalculator.compute(
        dates,
        referenceDate: DateTime(2025, 3, 12),
      );
      expect(r.current, 10);
      expect(r.longest, 10);
    });
  });
}
