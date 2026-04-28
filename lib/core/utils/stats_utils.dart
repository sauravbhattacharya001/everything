import 'dart:math' as math;

/// Shared descriptive-statistics utilities to eliminate duplicated
/// _mean / _stdDev / _variance / _pooledStdDev helpers across
/// services (event_pattern, experiment_engine, sleep_tracker, etc.).
///
/// All methods are static and null-safe for empty or single-element
/// input. Standard-deviation variants use **sample** (Bessel-corrected,
/// n − 1) unless noted otherwise — this matches the existing private
/// implementations.
class StatsUtils {
  StatsUtils._();

  /// Arithmetic mean.  Returns `0` for an empty list.
  static double mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.fold<double>(0, (a, b) => a + b) / values.length;
  }

  /// **Sample** standard deviation (n − 1).
  /// Returns `0` when fewer than 2 values.
  ///
  /// If [m] is provided it is used as the mean (avoids a redundant pass
  /// when the caller already computed it).
  static double stdDev(List<double> values, [double? m]) {
    if (values.length < 2) return 0;
    final avg = m ?? mean(values);
    final sumSqDiff =
        values.fold<double>(0, (s, v) => s + (v - avg) * (v - avg));
    return math.sqrt(sumSqDiff / (values.length - 1));
  }

  /// **Population** variance (n).
  /// Returns `0` when fewer than 2 values.
  ///
  /// The sleep-tracker used population variance (dividing by n) to
  /// compute schedule consistency, so this preserves that behaviour.
  static double populationVariance(List<double> values) {
    if (values.length < 2) return 0;
    final avg = mean(values);
    return values.fold<double>(0, (s, v) => s + (v - avg) * (v - avg)) /
        values.length;
  }

  /// Square root helper — just `sqrt(v)`, but returns `0` for ≤ 0 input.
  /// Replaces the sleep-tracker's private `_stdDev(double variance)`.
  static double sqrtSafe(double value) =>
      value <= 0 ? 0 : math.sqrt(value);

  /// Pooled standard deviation for two independent samples
  /// (Welch-style pooling used in experiment_engine_service).
  static double pooledStdDev(double s1, int n1, double s2, int n2) {
    if (n1 < 2 && n2 < 2) return 0;
    if (n1 < 2) return s2;
    if (n2 < 2) return s1;
    final num = (n1 - 1) * s1 * s1 + (n2 - 1) * s2 * s2;
    final den = n1 + n2 - 2;
    return den > 0 ? math.sqrt(num / den) : 0;
  }
}
