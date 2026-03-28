/// Service for common percentage calculations.
class PercentageCalculatorService {
  PercentageCalculatorService._();

  /// What is [percent]% of [value]?
  static double percentOf(double percent, double value) => (percent / 100) * value;

  /// [part] is what % of [whole]?
  static double whatPercent(double part, double whole) =>
      whole == 0 ? 0 : (part / whole) * 100;

  /// Percentage change from [oldValue] to [newValue].
  static double percentChange(double oldValue, double newValue) =>
      oldValue == 0 ? 0 : ((newValue - oldValue) / oldValue.abs()) * 100;

  /// Increase [value] by [percent]%.
  static double increaseBy(double value, double percent) =>
      value * (1 + percent / 100);

  /// Decrease [value] by [percent]%.
  static double decreaseBy(double value, double percent) =>
      value * (1 - percent / 100);

  /// Percentage difference between two values (symmetric).
  static double percentDifference(double a, double b) {
    final avg = (a.abs() + b.abs()) / 2;
    return avg == 0 ? 0 : ((a - b).abs() / avg) * 100;
  }
}
