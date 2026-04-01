import 'dart:math' show pow;

/// A single year in the FIRE projection.
class FireProjectionYear {
  final int year;
  final double portfolioValue;
  final double totalContributed;
  final double totalGrowth;
  final double annualExpenses;

  const FireProjectionYear({
    required this.year,
    required this.portfolioValue,
    required this.totalContributed,
    required this.totalGrowth,
    required this.annualExpenses,
  });
}

/// Summary result of a FIRE calculation.
class FireResult {
  /// Years until financial independence.
  final int yearsToFire;

  /// Savings rate as a percentage (0–100).
  final double savingsRate;

  /// The FIRE number (annual expenses × withdrawal multiplier).
  final double fireNumber;

  /// Year-by-year projection.
  final List<FireProjectionYear> projection;

  /// Safe withdrawal amount per year in retirement.
  final double annualWithdrawal;

  /// Whether FIRE is achievable within the max projection window.
  final bool achievable;

  const FireResult({
    required this.yearsToFire,
    required this.savingsRate,
    required this.fireNumber,
    required this.projection,
    required this.annualWithdrawal,
    required this.achievable,
  });
}

/// Withdrawal strategy for determining the FIRE number.
enum WithdrawalStrategy {
  conservative(3.0, '3% (Conservative)'),
  standard(4.0, '4% (Standard)'),
  aggressive(5.0, '5% (Aggressive)');

  final double rate;
  final String label;
  const WithdrawalStrategy(this.rate, this.label);
}

/// Service for Financial Independence / Retire Early calculations.
///
/// Calculates how long until a person can retire based on their
/// savings rate, current portfolio, expected returns, and expenses.
class FireCalculatorService {
  const FireCalculatorService();

  /// Calculate the FIRE projection.
  ///
  /// [annualIncome] — gross annual income.
  /// [annualExpenses] — total annual spending.
  /// [currentSavings] — current invested portfolio value.
  /// [expectedReturn] — annual real return rate (percent, e.g. 7.0).
  /// [strategy] — withdrawal rate strategy.
  /// [maxYears] — cap for the projection (default 60).
  FireResult calculate({
    required double annualIncome,
    required double annualExpenses,
    required double currentSavings,
    double expectedReturn = 7.0,
    WithdrawalStrategy strategy = WithdrawalStrategy.standard,
    int maxYears = 60,
  }) {
    if (annualIncome <= 0 || annualExpenses < 0) {
      return FireResult(
        yearsToFire: maxYears,
        savingsRate: 0,
        fireNumber: 0,
        projection: const [],
        annualWithdrawal: 0,
        achievable: false,
      );
    }

    final annualSavings = annualIncome - annualExpenses;
    final savingsRate =
        annualIncome > 0 ? (annualSavings / annualIncome) * 100 : 0.0;
    final fireNumber = annualExpenses * (100 / strategy.rate);
    final annualWithdrawal = fireNumber * (strategy.rate / 100);
    final r = expectedReturn / 100;

    final projection = <FireProjectionYear>[];
    double portfolio = currentSavings;
    double totalContributed = currentSavings;
    int yearsToFire = maxYears;
    bool achievable = false;

    projection.add(FireProjectionYear(
      year: 0,
      portfolioValue: currentSavings,
      totalContributed: currentSavings,
      totalGrowth: 0,
      annualExpenses: annualExpenses,
    ));

    for (int year = 1; year <= maxYears; year++) {
      final growth = portfolio * r;
      portfolio += growth + annualSavings;
      totalContributed += annualSavings;

      projection.add(FireProjectionYear(
        year: year,
        portfolioValue: portfolio,
        totalContributed: totalContributed,
        totalGrowth: portfolio - totalContributed,
        annualExpenses: annualExpenses,
      ));

      if (!achievable && portfolio >= fireNumber) {
        yearsToFire = year;
        achievable = true;
      }
    }

    return FireResult(
      yearsToFire: yearsToFire,
      savingsRate: savingsRate,
      fireNumber: fireNumber,
      projection: projection,
      annualWithdrawal: annualWithdrawal,
      achievable: achievable,
    );
  }

  /// Estimate the savings rate needed to retire in [targetYears].
  ///
  /// Returns the required savings rate as a percentage (0–100),
  /// or null if it's not achievable.
  double? requiredSavingsRate({
    required double annualIncome,
    required double currentSavings,
    required int targetYears,
    double expectedReturn = 7.0,
    WithdrawalStrategy strategy = WithdrawalStrategy.standard,
  }) {
    if (annualIncome <= 0 || targetYears <= 0) return null;

    // Binary search for the savings rate
    double low = 0;
    double high = 100;

    for (int i = 0; i < 100; i++) {
      final mid = (low + high) / 2;
      final expenses = annualIncome * (1 - mid / 100);
      final result = calculate(
        annualIncome: annualIncome,
        annualExpenses: expenses,
        currentSavings: currentSavings,
        expectedReturn: expectedReturn,
        strategy: strategy,
        maxYears: targetYears,
      );
      if (result.achievable) {
        high = mid;
      } else {
        low = mid;
      }
    }

    final rate = (low + high) / 2;
    if (rate > 99.9) return null; // Not achievable
    return rate;
  }

  /// Quick label for savings rate quality.
  String savingsRateLabel(double rate) {
    if (rate >= 70) return 'Extreme Saver';
    if (rate >= 50) return 'Aggressive';
    if (rate >= 30) return 'On Track';
    if (rate >= 15) return 'Getting Started';
    if (rate >= 0) return 'Below Target';
    return 'Negative';
  }

  /// Color-coded tier for the savings rate (as a hex int for Color).
  int savingsRateColorValue(double rate) {
    if (rate >= 50) return 0xFF4CAF50; // green
    if (rate >= 30) return 0xFF2196F3; // blue
    if (rate >= 15) return 0xFFFF9800; // orange
    return 0xFFF44336; // red
  }
}
