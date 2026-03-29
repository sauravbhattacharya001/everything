/// Service for salary / net-pay calculations.
///
/// Supports gross-to-net conversion with:
/// - Federal income tax (2024 brackets, simplified)
/// - State income tax (flat rate input)
/// - FICA (Social Security 6.2% + Medicare 1.45%)
/// - Pre-tax deductions (401k, health insurance, HSA)
/// - Pay frequency conversion (annual ↔ monthly ↔ biweekly ↔ weekly)
class SalaryCalculatorService {
  SalaryCalculatorService._();

  /// Pay frequencies with their annual multiplier.
  static const Map<PayFrequency, int> frequencyMultipliers = {
    PayFrequency.annually: 1,
    PayFrequency.monthly: 12,
    PayFrequency.semiMonthly: 24,
    PayFrequency.biweekly: 26,
    PayFrequency.weekly: 52,
  };

  /// 2024 US federal tax brackets (single filer).
  static const List<TaxBracket> federalBracketsSingle = [
    TaxBracket(0, 11600, 0.10),
    TaxBracket(11600, 47150, 0.12),
    TaxBracket(47150, 100525, 0.22),
    TaxBracket(100525, 191950, 0.24),
    TaxBracket(191950, 243725, 0.32),
    TaxBracket(243725, 609350, 0.35),
    TaxBracket(609350, double.infinity, 0.37),
  ];

  /// 2024 US federal tax brackets (married filing jointly).
  static const List<TaxBracket> federalBracketsMarried = [
    TaxBracket(0, 23200, 0.10),
    TaxBracket(23200, 94300, 0.12),
    TaxBracket(94300, 201050, 0.22),
    TaxBracket(201050, 383900, 0.24),
    TaxBracket(383900, 487450, 0.32),
    TaxBracket(487450, 731200, 0.35),
    TaxBracket(731200, double.infinity, 0.37),
  ];

  /// Standard deduction amounts (2024).
  static const double standardDeductionSingle = 14600;
  static const double standardDeductionMarried = 29200;

  /// FICA rates.
  static const double socialSecurityRate = 0.062;
  static const double socialSecurityWageCap = 168600;
  static const double medicareRate = 0.0145;
  static const double additionalMedicareRate = 0.009;
  static const double additionalMedicareThreshold = 200000;

  /// Calculate net pay breakdown.
  static SalaryResult calculate({
    required double grossAnnual,
    required FilingStatus filingStatus,
    double stateTaxRate = 0.0,
    double preTax401k = 0.0,
    double preTaxHealthInsurance = 0.0,
    double preTaxHSA = 0.0,
    double otherPreTaxDeductions = 0.0,
    PayFrequency frequency = PayFrequency.biweekly,
  }) {
    final totalPreTax =
        preTax401k + preTaxHealthInsurance + preTaxHSA + otherPreTaxDeductions;

    // Taxable income for federal
    final standardDeduction = filingStatus == FilingStatus.single
        ? standardDeductionSingle
        : standardDeductionMarried;
    final federalTaxableIncome =
        (grossAnnual - totalPreTax - standardDeduction).clamp(0.0, double.infinity);

    // Federal tax
    final brackets = filingStatus == FilingStatus.single
        ? federalBracketsSingle
        : federalBracketsMarried;
    final federalTax = _calculateBracketTax(federalTaxableIncome, brackets);

    // State tax (flat rate on gross minus pre-tax deductions)
    final stateTaxableIncome =
        (grossAnnual - totalPreTax).clamp(0.0, double.infinity);
    final stateTax = stateTaxableIncome * stateTaxRate;

    // FICA
    final ficaIncome = grossAnnual; // FICA is on gross, not reduced by pre-tax
    final socialSecurity =
        (ficaIncome.clamp(0.0, socialSecurityWageCap)) * socialSecurityRate;
    final medicare = ficaIncome * medicareRate;
    final additionalMedicare = ficaIncome > additionalMedicareThreshold
        ? (ficaIncome - additionalMedicareThreshold) * additionalMedicareRate
        : 0.0;
    final totalFICA = socialSecurity + medicare + additionalMedicare;

    final totalTax = federalTax + stateTax + totalFICA;
    final netAnnual = grossAnnual - totalPreTax - totalTax;

    final multiplier = frequencyMultipliers[frequency]!;

    return SalaryResult(
      grossAnnual: grossAnnual,
      grossPerPeriod: grossAnnual / multiplier,
      federalTax: federalTax,
      stateTax: stateTax,
      socialSecurity: socialSecurity,
      medicare: medicare + additionalMedicare,
      totalFICA: totalFICA,
      totalPreTaxDeductions: totalPreTax,
      totalTax: totalTax,
      netAnnual: netAnnual,
      netPerPeriod: netAnnual / multiplier,
      effectiveTaxRate: grossAnnual > 0 ? totalTax / grossAnnual * 100 : 0,
      marginalTaxRate: _marginalRate(federalTaxableIncome, brackets) * 100,
      frequency: frequency,
    );
  }

  static double _calculateBracketTax(
      double income, List<TaxBracket> brackets) {
    double tax = 0;
    for (final b in brackets) {
      if (income <= b.min) break;
      final taxable = (income.clamp(b.min, b.max)) - b.min;
      tax += taxable * b.rate;
    }
    return tax;
  }

  static double _marginalRate(double income, List<TaxBracket> brackets) {
    for (final b in brackets) {
      if (income >= b.min && income < b.max) return b.rate;
    }
    return brackets.last.rate;
  }
}

enum PayFrequency { annually, monthly, semiMonthly, biweekly, weekly }

enum FilingStatus { single, marriedJointly }

class TaxBracket {
  final double min;
  final double max;
  final double rate;
  const TaxBracket(this.min, this.max, this.rate);
}

class SalaryResult {
  final double grossAnnual;
  final double grossPerPeriod;
  final double federalTax;
  final double stateTax;
  final double socialSecurity;
  final double medicare;
  final double totalFICA;
  final double totalPreTaxDeductions;
  final double totalTax;
  final double netAnnual;
  final double netPerPeriod;
  final double effectiveTaxRate;
  final double marginalTaxRate;
  final PayFrequency frequency;

  const SalaryResult({
    required this.grossAnnual,
    required this.grossPerPeriod,
    required this.federalTax,
    required this.stateTax,
    required this.socialSecurity,
    required this.medicare,
    required this.totalFICA,
    required this.totalPreTaxDeductions,
    required this.totalTax,
    required this.netAnnual,
    required this.netPerPeriod,
    required this.effectiveTaxRate,
    required this.marginalTaxRate,
    required this.frequency,
  });
}
