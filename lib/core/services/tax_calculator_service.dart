import 'dart:math';

/// Filing status for US federal income tax.
enum FilingStatus {
  single('Single'),
  marriedJoint('Married Filing Jointly'),
  marriedSeparate('Married Filing Separately'),
  headOfHousehold('Head of Household');

  final String label;
  const FilingStatus(this.label);
}

/// A single tax bracket.
class TaxBracket {
  final double min;
  final double max;
  final double rate;

  const TaxBracket(this.min, this.max, this.rate);
}

/// Result of a tax calculation.
class TaxResult {
  final double grossIncome;
  final double totalDeductions;
  final double taxableIncome;
  final double federalTax;
  final double effectiveRate;
  final double marginalRate;
  final double takeHome;
  final List<BracketBreakdown> bracketBreakdown;

  TaxResult({
    required this.grossIncome,
    required this.totalDeductions,
    required this.taxableIncome,
    required this.federalTax,
    required this.effectiveRate,
    required this.marginalRate,
    required this.takeHome,
    required this.bracketBreakdown,
  });
}

/// Tax owed in a specific bracket.
class BracketBreakdown {
  final double rate;
  final double incomeInBracket;
  final double taxInBracket;

  BracketBreakdown({
    required this.rate,
    required this.incomeInBracket,
    required this.taxInBracket,
  });
}

/// US Federal Income Tax calculator (2024 brackets).
class TaxCalculatorService {
  // 2024 standard deductions
  static const Map<FilingStatus, double> standardDeductions = {
    FilingStatus.single: 14600,
    FilingStatus.marriedJoint: 29200,
    FilingStatus.marriedSeparate: 14600,
    FilingStatus.headOfHousehold: 21900,
  };

  // 2024 federal tax brackets
  static const Map<FilingStatus, List<TaxBracket>> brackets = {
    FilingStatus.single: [
      TaxBracket(0, 11600, 0.10),
      TaxBracket(11600, 47150, 0.12),
      TaxBracket(47150, 100525, 0.22),
      TaxBracket(100525, 191950, 0.24),
      TaxBracket(191950, 243725, 0.32),
      TaxBracket(243725, 609350, 0.35),
      TaxBracket(609350, double.infinity, 0.37),
    ],
    FilingStatus.marriedJoint: [
      TaxBracket(0, 23200, 0.10),
      TaxBracket(23200, 94300, 0.12),
      TaxBracket(94300, 201050, 0.22),
      TaxBracket(201050, 383900, 0.24),
      TaxBracket(383900, 487450, 0.32),
      TaxBracket(487450, 731200, 0.35),
      TaxBracket(731200, double.infinity, 0.37),
    ],
    FilingStatus.marriedSeparate: [
      TaxBracket(0, 11600, 0.10),
      TaxBracket(11600, 47150, 0.12),
      TaxBracket(47150, 100525, 0.22),
      TaxBracket(100525, 191950, 0.24),
      TaxBracket(191950, 243725, 0.32),
      TaxBracket(243725, 365600, 0.35),
      TaxBracket(365600, double.infinity, 0.37),
    ],
    FilingStatus.headOfHousehold: [
      TaxBracket(0, 16550, 0.10),
      TaxBracket(16550, 63100, 0.12),
      TaxBracket(63100, 100500, 0.22),
      TaxBracket(100500, 191950, 0.24),
      TaxBracket(191950, 243700, 0.32),
      TaxBracket(243700, 609350, 0.35),
      TaxBracket(609350, double.infinity, 0.37),
    ],
  };

  /// Calculate federal income tax.
  TaxResult calculate({
    required double grossIncome,
    required FilingStatus filingStatus,
    double? customDeduction,
  }) {
    final deduction = customDeduction ?? standardDeductions[filingStatus]!;
    final taxableIncome = max(0.0, grossIncome - deduction);
    final statusBrackets = brackets[filingStatus]!;

    double totalTax = 0;
    double marginalRate = statusBrackets.first.rate;
    final breakdown = <BracketBreakdown>[];

    for (final bracket in statusBrackets) {
      if (taxableIncome <= bracket.min) break;
      final incomeInBracket =
          min(taxableIncome, bracket.max) - bracket.min;
      final taxInBracket = incomeInBracket * bracket.rate;
      totalTax += taxInBracket;
      marginalRate = bracket.rate;
      breakdown.add(BracketBreakdown(
        rate: bracket.rate,
        incomeInBracket: incomeInBracket,
        taxInBracket: taxInBracket,
      ));
    }

    final effectiveRate =
        grossIncome > 0 ? totalTax / grossIncome : 0.0;

    return TaxResult(
      grossIncome: grossIncome,
      totalDeductions: deduction,
      taxableIncome: taxableIncome,
      federalTax: totalTax,
      effectiveRate: effectiveRate,
      marginalRate: marginalRate,
      takeHome: grossIncome - totalTax,
      bracketBreakdown: breakdown,
    );
  }
}
