import 'date_utils.dart';

/// Lightweight streak result — just the numbers most services need.
class StreakResult {
  /// Current consecutive-day streak (0 if broken).
  final int current;

  /// Longest consecutive-day streak ever.
  final int longest;

  const StreakResult({required this.current, required this.longest});

  @override
  String toString() => 'StreakResult(current: $current, longest: $longest)';
}

/// Calculates consecutive-day streaks from a collection of dates.
///
/// Many services (journal, tracker, exercise, etc.) independently implement
/// the same "sort dates → walk backward for current streak → walk forward
/// for longest streak" algorithm.  This class provides a single, tested
/// implementation that works on raw [DateTime] values — no model dependency.
///
/// Usage:
/// ```dart
/// final dates = entries.map((e) => e.date);
/// final streak = DateStreakCalculator.compute(dates);
/// print('Current: ${streak.current}, Longest: ${streak.longest}');
/// ```
class DateStreakCalculator {
  DateStreakCalculator._();

  /// Compute current and longest streaks from [dates].
  ///
  /// [referenceDate] defaults to `DateTime.now()` — pass a fixed date for
  /// deterministic testing.
  ///
  /// A date counts as part of the current streak only if the most recent
  /// active day is today or yesterday (i.e., the streak hasn't been broken).
  static StreakResult compute(
    Iterable<DateTime> dates, {
    DateTime? referenceDate,
  }) {
    // Deduplicate to calendar days.
    final daySet = <DateTime>{};
    for (final d in dates) {
      daySet.add(AppDateUtils.dateOnly(d));
    }
    if (daySet.isEmpty) {
      return const StreakResult(current: 0, longest: 0);
    }

    final sorted = daySet.toList()..sort((a, b) => b.compareTo(a)); // newest first

    final today = AppDateUtils.dateOnly(referenceDate ?? DateTime.now());

    // ── Current streak (walk backward from most recent) ──
    int current = 0;
    final daysSinceLast = today.difference(sorted.first).inDays;
    if (daysSinceLast <= 1) {
      current = 1;
      for (int i = 1; i < sorted.length; i++) {
        if (sorted[i - 1].difference(sorted[i]).inDays == 1) {
          current++;
        } else {
          break;
        }
      }
    }

    // ── Longest streak (single forward pass) ──
    // Re-sort ascending for a clean forward scan.
    sorted.sort();
    int longest = 1;
    int run = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }

    return StreakResult(current: current, longest: longest);
  }
}
