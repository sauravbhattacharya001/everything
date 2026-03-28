import 'dart:math' show pow;

/// A single row in the amortization schedule.
class AmortizationRow {
  final int month;
  final double payment;
  final double principal;
  final double interest;
  final double balance;

  const AmortizationRow({
    required this.month,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balance,
  });
}

/// Summary of a mortgage calculation.
class MortgageSummary {
  final double loanAmount;
  final double annualRate;
  final int termYears;
  final double monthlyPayment;
  final double totalPayment;
  final double totalInterest;
  final List<AmortizationRow> schedule;

  const MortgageSummary({
    required this.loanAmount,
    required this.annualRate,
    required this.termYears,
    required this.monthlyPayment,
    required this.totalPayment,
    required this.totalInterest,
    required this.schedule,
  });
}

/// Service for mortgage payment calculations.
///
/// Computes fixed-rate mortgage monthly payments, total interest,
/// and a full amortization schedule using the standard annuity formula.
class MortgageCalculatorService {
  const MortgageCalculatorService();

  /// Calculate mortgage details.
  ///
  /// [principal] — loan amount in dollars.
  /// [annualRatePercent] — annual interest rate as a percentage (e.g. 6.5).
  /// [termYears] — loan term in years.
  /// [extraMonthlyPayment] — optional extra principal payment per month.
  MortgageSummary calculate({
    required double principal,
    required double annualRatePercent,
    required int termYears,
    double extraMonthlyPayment = 0,
  }) {
    final monthlyRate = annualRatePercent / 100 / 12;
    final totalMonths = termYears * 12;

    double monthlyPayment;
    if (monthlyRate == 0) {
      monthlyPayment = principal / totalMonths;
    } else {
      monthlyPayment = principal *
          (monthlyRate * pow(1 + monthlyRate, totalMonths)) /
          (pow(1 + monthlyRate, totalMonths) - 1);
    }

    final schedule = <AmortizationRow>[];
    double balance = principal;
    double totalInterest = 0;

    for (int m = 1; m <= totalMonths && balance > 0; m++) {
      final interestPortion = balance * monthlyRate;
      final basePrincipal = monthlyPayment - interestPortion;
      final principalPortion = basePrincipal + extraMonthlyPayment;
      final actualPrincipal =
          principalPortion > balance ? balance : principalPortion;
      final actualPayment = interestPortion + actualPrincipal;
      balance -= actualPrincipal;
      if (balance < 0.01) balance = 0;
      totalInterest += interestPortion;

      schedule.add(AmortizationRow(
        month: m,
        payment: actualPayment,
        principal: actualPrincipal,
        interest: interestPortion,
        balance: balance,
      ));

      if (balance == 0) break;
    }

    final totalPayment = principal + totalInterest;

    return MortgageSummary(
      loanAmount: principal,
      annualRate: annualRatePercent,
      termYears: termYears,
      monthlyPayment: monthlyPayment,
      totalPayment: totalPayment,
      totalInterest: totalInterest,
      schedule: schedule,
    );
  }

  /// How much house can you afford given a monthly budget?
  double maxLoanAmount({
    required double monthlyBudget,
    required double annualRatePercent,
    required int termYears,
  }) {
    final monthlyRate = annualRatePercent / 100 / 12;
    final totalMonths = termYears * 12;
    if (monthlyRate == 0) return monthlyBudget * totalMonths;
    return monthlyBudget *
        (pow(1 + monthlyRate, totalMonths) - 1) /
        (monthlyRate * pow(1 + monthlyRate, totalMonths));
  }
}
