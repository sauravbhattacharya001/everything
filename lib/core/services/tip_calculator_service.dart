/// Service for tip calculations with split, rounding, and history.
class TipCalculatorService {
  TipCalculatorService._();

  /// Standard tip percentages.
  static const List<int> presetPercentages = [10, 15, 18, 20, 25, 30];

  /// Calculate tip details.
  static TipResult calculate({
    required double billAmount,
    required double tipPercent,
    required int splitCount,
    bool roundUp = false,
  }) {
    assert(splitCount >= 1);
    final tipAmount = billAmount * tipPercent / 100;
    var total = billAmount + tipAmount;
    if (roundUp) {
      total = total.ceilToDouble();
    }
    final perPerson = splitCount > 1 ? total / splitCount : total;
    final tipPerPerson = splitCount > 1 ? tipAmount / splitCount : tipAmount;

    return TipResult(
      billAmount: billAmount,
      tipPercent: tipPercent,
      tipAmount: tipAmount,
      total: total,
      splitCount: splitCount,
      perPerson: perPerson,
      tipPerPerson: tipPerPerson,
    );
  }

  /// Suggest a custom tip to round the total to a nice number.
  static double suggestRoundTip(double billAmount) {
    // Find a tip that makes the total a round number
    final target = (billAmount * 1.2).ceilToDouble(); // ~20% rounded up
    final tip = target - billAmount;
    return tip > 0 ? tip : billAmount * 0.2;
  }

  /// Quality of service ratings mapped to suggested percentages.
  static const Map<String, int> serviceRatings = {
    'Poor': 10,
    'Fair': 15,
    'Good': 18,
    'Great': 20,
    'Excellent': 25,
    'Outstanding': 30,
  };
}

class TipResult {
  final double billAmount;
  final double tipPercent;
  final double tipAmount;
  final double total;
  final int splitCount;
  final double perPerson;
  final double tipPerPerson;

  const TipResult({
    required this.billAmount,
    required this.tipPercent,
    required this.tipAmount,
    required this.total,
    required this.splitCount,
    required this.perPerson,
    required this.tipPerPerson,
  });
}
