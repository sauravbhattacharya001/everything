import 'dart:math' show pow;

/// Represents a single point in the compound interest projection.
class ProjectionPoint {
  final int year;
  final double balance;
  final double totalContributed;
  final double totalInterest;

  const ProjectionPoint({
    required this.year,
    required this.balance,
    required this.totalContributed,
    required this.totalInterest,
  });
}

/// Frequency of compounding or contributions.
enum CompoundFrequency {
  annually(1, 'Annually'),
  semiAnnually(2, 'Semi-Annually'),
  quarterly(4, 'Quarterly'),
  monthly(12, 'Monthly'),
  daily(365, 'Daily');

  final int periodsPerYear;
  final String label;
  const CompoundFrequency(this.periodsPerYear, this.label);
}

/// Service for compound interest calculations.
class CompoundInterestService {
  const CompoundInterestService();

  /// Calculate compound interest with recurring contributions.
  ///
  /// Uses the standard compound interest formula:
  /// A = P(1 + r/n)^(nt) + PMT × [((1 + r/n)^(nt) - 1) / (r/n)]
  List<ProjectionPoint> calculate({
    required double principal,
    required double annualRate,
    required int years,
    double monthlyContribution = 0,
    CompoundFrequency compoundFrequency = CompoundFrequency.monthly,
  }) {
    final points = <ProjectionPoint>[];
    final r = annualRate / 100;
    final n = compoundFrequency.periodsPerYear;
    final contributionPerPeriod = monthlyContribution * 12 / n;

    double balance = principal;
    double totalContributed = principal;

    points.add(ProjectionPoint(
      year: 0,
      balance: principal,
      totalContributed: principal,
      totalInterest: 0,
    ));

    for (int year = 1; year <= years; year++) {
      // Simulate each compounding period for this year
      for (int period = 0; period < n; period++) {
        balance += balance * (r / n);
        balance += contributionPerPeriod;
      }
      totalContributed += monthlyContribution * 12;

      points.add(ProjectionPoint(
        year: year,
        balance: balance,
        totalContributed: totalContributed,
        totalInterest: balance - totalContributed,
      ));
    }

    return points;
  }

  /// Calculate the final balance only (no year-by-year breakdown).
  double finalBalance({
    required double principal,
    required double annualRate,
    required int years,
    double monthlyContribution = 0,
    CompoundFrequency compoundFrequency = CompoundFrequency.monthly,
  }) {
    final points = calculate(
      principal: principal,
      annualRate: annualRate,
      years: years,
      monthlyContribution: monthlyContribution,
      compoundFrequency: compoundFrequency,
    );
    return points.last.balance;
  }

  /// Calculate how many years to reach a target balance.
  int yearsToReach({
    required double principal,
    required double annualRate,
    required double target,
    double monthlyContribution = 0,
    CompoundFrequency compoundFrequency = CompoundFrequency.monthly,
    int maxYears = 100,
  }) {
    final r = annualRate / 100;
    final n = compoundFrequency.periodsPerYear;
    final contributionPerPeriod = monthlyContribution * 12 / n;
    double balance = principal;

    for (int year = 1; year <= maxYears; year++) {
      for (int period = 0; period < n; period++) {
        balance += balance * (r / n);
        balance += contributionPerPeriod;
      }
      if (balance >= target) return year;
    }
    return maxYears;
  }

  /// Rule of 72: approximate years to double at a given rate.
  double ruleOf72(double annualRate) {
    if (annualRate <= 0) return double.infinity;
    return 72 / annualRate;
  }
}
