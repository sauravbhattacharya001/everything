import 'dart:math';

/// Loan/EMI calculator with amortization schedule generation.
class LoanCalculatorService {
  LoanCalculatorService._();

  /// Calculate EMI (Equated Monthly Installment).
  /// [principal] - loan amount, [annualRate] - annual interest rate %,
  /// [months] - loan tenure in months.
  static LoanResult calculate({
    required double principal,
    required double annualRate,
    required int months,
  }) {
    if (principal <= 0 || months <= 0) {
      return LoanResult(
        principal: principal,
        annualRate: annualRate,
        months: months,
        emi: 0,
        totalPayment: 0,
        totalInterest: 0,
        schedule: [],
      );
    }

    double emi;
    if (annualRate == 0) {
      emi = principal / months;
    } else {
      final r = annualRate / 12 / 100;
      emi = principal * r * pow(1 + r, months) / (pow(1 + r, months) - 1);
    }

    final schedule = <AmortizationEntry>[];
    double balance = principal;
    double totalInterest = 0;

    for (int i = 1; i <= months; i++) {
      final interest = balance * (annualRate / 12 / 100);
      final principalPaid = emi - interest;
      balance -= principalPaid;
      if (balance < 0.01) balance = 0;
      totalInterest += interest;
      schedule.add(AmortizationEntry(
        month: i,
        emi: emi,
        principalPaid: principalPaid,
        interestPaid: interest,
        balance: balance,
      ));
    }

    return LoanResult(
      principal: principal,
      annualRate: annualRate,
      months: months,
      emi: emi,
      totalPayment: emi * months,
      totalInterest: totalInterest,
      schedule: schedule,
    );
  }

  /// Preset loan types with typical rates and tenures.
  static const Map<String, LoanPreset> presets = {
    'Home Loan': LoanPreset(rate: 7.0, months: 240),
    'Car Loan': LoanPreset(rate: 8.5, months: 60),
    'Personal Loan': LoanPreset(rate: 12.0, months: 36),
    'Education Loan': LoanPreset(rate: 9.0, months: 120),
    'Business Loan': LoanPreset(rate: 14.0, months: 48),
  };

  /// Calculate how much extra payment saves.
  static ExtraPaymentResult calculateExtraPay({
    required double principal,
    required double annualRate,
    required int months,
    required double extraMonthly,
  }) {
    final normal = calculate(
        principal: principal, annualRate: annualRate, months: months);
    if (annualRate == 0 || extraMonthly <= 0) {
      return ExtraPaymentResult(
        normalTotal: normal.totalPayment,
        newTotal: normal.totalPayment,
        interestSaved: 0,
        monthsSaved: 0,
      );
    }

    final r = annualRate / 12 / 100;
    double balance = principal;
    double totalPaid = 0;
    int actualMonths = 0;

    for (int i = 0; i < months && balance > 0; i++) {
      final interest = balance * r;
      final payment = min(normal.emi + extraMonthly, balance + interest);
      balance -= (payment - interest);
      if (balance < 0.01) balance = 0;
      totalPaid += payment;
      actualMonths++;
    }

    return ExtraPaymentResult(
      normalTotal: normal.totalPayment,
      newTotal: totalPaid,
      interestSaved: normal.totalPayment - totalPaid,
      monthsSaved: months - actualMonths,
    );
  }
}

class LoanResult {
  final double principal;
  final double annualRate;
  final int months;
  final double emi;
  final double totalPayment;
  final double totalInterest;
  final List<AmortizationEntry> schedule;

  const LoanResult({
    required this.principal,
    required this.annualRate,
    required this.months,
    required this.emi,
    required this.totalPayment,
    required this.totalInterest,
    required this.schedule,
  });
}

class AmortizationEntry {
  final int month;
  final double emi;
  final double principalPaid;
  final double interestPaid;
  final double balance;

  const AmortizationEntry({
    required this.month,
    required this.emi,
    required this.principalPaid,
    required this.interestPaid,
    required this.balance,
  });
}

class LoanPreset {
  final double rate;
  final int months;
  const LoanPreset({required this.rate, required this.months});
}

class ExtraPaymentResult {
  final double normalTotal;
  final double newTotal;
  final double interestSaved;
  final int monthsSaved;

  const ExtraPaymentResult({
    required this.normalTotal,
    required this.newTotal,
    required this.interestSaved,
    required this.monthsSaved,
  });
}
