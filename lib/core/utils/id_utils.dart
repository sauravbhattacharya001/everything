import 'dart:math';

/// Shared ID generation utilities.
///
/// Centralises the timestamp + random-suffix pattern that was previously
/// duplicated across budget_planner, net_worth_tracker, quick_capture,
/// savings_goal, and debt_payoff services.
class IdUtils {
  static final Random _random = Random();

  /// Generate a unique ID with an optional [prefix].
  ///
  /// Format: `{prefix}{epochMs}_{random5}` (e.g. `nw_1714387200000_04821`).
  /// When no prefix is given: `{epochMs}_{random5}`.
  static String generateId([String prefix = '']) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = _random.nextInt(99999).toString().padLeft(5, '0');
    return '$prefix${now}_$rand';
  }
}
