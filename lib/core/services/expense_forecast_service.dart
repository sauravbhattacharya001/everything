import 'dart:math';
import '../../models/expense_entry.dart';

/// Trend direction for a category forecast.
enum TrendDirection { up, down, stable }

/// Severity levels for alerts and anomalies.
enum AlertSeverity { low, medium, high }

/// Forecast for a single expense category.
class CategoryForecast {
  final ExpenseCategory category;
  final double predictedAmount;
  final double confidence;
  final TrendDirection trend;
  final double changePercent;
  final List<double> recentMonthly;

  const CategoryForecast({
    required this.category,
    required this.predictedAmount,
    required this.confidence,
    required this.trend,
    required this.changePercent,
    required this.recentMonthly,
  });
}

/// A detected spending anomaly.
class SpendingAnomaly {
  final DateTime date;
  final ExpenseCategory category;
  final double amount;
  final double expectedAmount;
  final AlertSeverity severity;
  final String description;

  const SpendingAnomaly({
    required this.date,
    required this.category,
    required this.amount,
    required this.expectedAmount,
    required this.severity,
    required this.description,
  });
}

/// A detected recurring expense.
class RecurringExpense {
  final String name;
  final double amount;
  final ExpenseCategory category;
  final String frequency;
  final DateTime? nextExpected;
  final double annualCost;

  const RecurringExpense({
    required this.name,
    required this.amount,
    required this.category,
    required this.frequency,
    this.nextExpected,
    required this.annualCost,
  });
}

/// Budget-related alert.
class BudgetAlert {
  final String type;
  final ExpenseCategory? category;
  final String message;
  final AlertSeverity severity;

  const BudgetAlert({
    required this.type,
    this.category,
    required this.message,
    required this.severity,
  });
}

/// Complete forecast report.
class ForecastReport {
  final double totalForecast;
  final double totalConfidence;
  final List<CategoryForecast> categoryForecasts;
  final List<SpendingAnomaly> anomalies;
  final List<RecurringExpense> recurringExpenses;
  final List<BudgetAlert> alerts;
  final double savingsPotential;
  final double dataQualityScore;
  final DateTime generatedAt;

  const ForecastReport({
    required this.totalForecast,
    required this.totalConfidence,
    required this.categoryForecasts,
    required this.anomalies,
    required this.recurringExpenses,
    required this.alerts,
    required this.savingsPotential,
    required this.dataQualityScore,
    required this.generatedAt,
  });
}

/// Autonomous expense forecasting service.
///
/// Analyzes spending history to predict future expenses, detect anomalies,
/// identify recurring charges, and generate budget impact alerts.
class ExpenseForecastService {
  /// Generate a complete forecast report from expense entries.
  ForecastReport generateReport(
    List<ExpenseEntry> entries, {
    double monthlyBudget = 3000.0,
  }) {
    if (entries.isEmpty) {
      return ForecastReport(
        totalForecast: 0,
        totalConfidence: 0,
        categoryForecasts: [],
        anomalies: [],
        recurringExpenses: [],
        alerts: [],
        savingsPotential: 0,
        dataQualityScore: 0,
        generatedAt: DateTime.now(),
      );
    }

    final categoryForecasts = _forecastCategories(entries);
    final anomalies = _detectAnomalies(entries);
    final recurring = _findRecurring(entries);
    final totalForecast =
        categoryForecasts.fold(0.0, (s, f) => s + f.predictedAmount);
    final totalConfidence = categoryForecasts.isEmpty
        ? 0.0
        : categoryForecasts.fold(0.0, (s, f) => s + f.confidence) /
            categoryForecasts.length;
    final alerts =
        _generateAlerts(categoryForecasts, totalForecast, monthlyBudget);
    final savingsPotential = _calcSavingsPotential(entries);
    final dataQuality = _calcDataQuality(entries);

    return ForecastReport(
      totalForecast: totalForecast,
      totalConfidence: totalConfidence,
      categoryForecasts: categoryForecasts,
      anomalies: anomalies,
      recurringExpenses: recurring,
      alerts: alerts,
      savingsPotential: savingsPotential,
      dataQualityScore: dataQuality,
      generatedAt: DateTime.now(),
    );
  }

  /// Forecast per-category spending using exponential moving average.
  List<CategoryForecast> _forecastCategories(List<ExpenseEntry> entries) {
    final now = DateTime.now();
    final byCategory = <ExpenseCategory, List<ExpenseEntry>>{};
    for (final e in entries) {
      if (e.category == ExpenseCategory.income) continue;
      byCategory.putIfAbsent(e.category, () => []).add(e);
    }

    final forecasts = <CategoryForecast>[];
    for (final entry in byCategory.entries) {
      final monthly = _monthlyTotals(entry.value, now, 6);
      if (monthly.isEmpty) continue;

      final ema = _exponentialMovingAverage(monthly);
      final trend = _detectTrend(monthly);
      final changePercent = monthly.length >= 2 && monthly[monthly.length - 2] > 0
          ? ((monthly.last - monthly[monthly.length - 2]) /
                  monthly[monthly.length - 2]) *
              100
          : 0.0;
      final confidence = _calcConfidence(monthly);

      forecasts.add(CategoryForecast(
        category: entry.key,
        predictedAmount: ema,
        confidence: confidence,
        trend: trend,
        changePercent: changePercent,
        recentMonthly: monthly,
      ));
    }

    forecasts.sort((a, b) => b.predictedAmount.compareTo(a.predictedAmount));
    return forecasts;
  }

  /// Get monthly totals for the last N months.
  List<double> _monthlyTotals(
      List<ExpenseEntry> entries, DateTime now, int months) {
    final totals = <double>[];
    for (var i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(month.year, month.month + 1, 1);
      final total = entries
          .where((e) =>
              e.timestamp.isAfter(month.subtract(const Duration(days: 1))) &&
              e.timestamp.isBefore(nextMonth))
          .fold(0.0, (s, e) => s + e.amount);
      totals.add(total);
    }
    return totals;
  }

  /// Exponential moving average with alpha=0.3.
  double _exponentialMovingAverage(List<double> values) {
    if (values.isEmpty) return 0;
    const alpha = 0.3;
    var ema = values.first;
    for (var i = 1; i < values.length; i++) {
      ema = alpha * values[i] + (1 - alpha) * ema;
    }
    return ema;
  }

  /// Detect trend from monthly values.
  TrendDirection _detectTrend(List<double> values) {
    if (values.length < 2) return TrendDirection.stable;
    final recent = values.last;
    final prev = values[values.length - 2];
    if (prev == 0) return recent > 0 ? TrendDirection.up : TrendDirection.stable;
    final change = (recent - prev) / prev;
    if (change > 0.1) return TrendDirection.up;
    if (change < -0.1) return TrendDirection.down;
    return TrendDirection.stable;
  }

  /// Confidence based on coefficient of variation (lower CV = higher confidence).
  double _calcConfidence(List<double> values) {
    if (values.length < 2) return 0.3;
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean == 0) return 0.5;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    final cv = sqrt(variance) / mean;
    return (1.0 - cv).clamp(0.1, 0.99);
  }

  /// Detect spending anomalies using z-score.
  List<SpendingAnomaly> _detectAnomalies(List<ExpenseEntry> entries) {
    final anomalies = <SpendingAnomaly>[];
    final byCategory = <ExpenseCategory, List<ExpenseEntry>>{};
    for (final e in entries) {
      byCategory.putIfAbsent(e.category, () => []).add(e);
    }

    for (final entry in byCategory.entries) {
      final amounts = entry.value.map((e) => e.amount).toList();
      if (amounts.length < 3) continue;
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance =
          amounts.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
              amounts.length;
      final stdDev = sqrt(variance);
      if (stdDev == 0) continue;

      for (final expense in entry.value) {
        final zScore = (expense.amount - mean).abs() / stdDev;
        if (zScore > 2.0) {
          final severity = zScore > 3.0
              ? AlertSeverity.high
              : zScore > 2.5
                  ? AlertSeverity.medium
                  : AlertSeverity.low;
          anomalies.add(SpendingAnomaly(
            date: expense.timestamp,
            category: expense.category,
            amount: expense.amount,
            expectedAmount: mean,
            severity: severity,
            description:
                '${expense.vendor ?? expense.description ?? entry.key.label}: '
                '\$${expense.amount.toStringAsFixed(2)} '
                'vs avg \$${mean.toStringAsFixed(2)} '
                '(${zScore.toStringAsFixed(1)}\u03c3)',
          ));
        }
      }
    }

    anomalies.sort((a, b) {
      final s = b.severity.index.compareTo(a.severity.index);
      return s != 0 ? s : b.date.compareTo(a.date);
    });
    return anomalies.take(20).toList();
  }

  /// Find recurring expenses by detecting similar amounts at regular intervals.
  List<RecurringExpense> _findRecurring(List<ExpenseEntry> entries) {
    final recurring = <RecurringExpense>[];
    final byVendor = <String, List<ExpenseEntry>>{};
    for (final e in entries) {
      final key = (e.vendor ?? e.description ?? '').toLowerCase().trim();
      if (key.isEmpty) continue;
      byVendor.putIfAbsent(key, () => []).add(e);
    }

    for (final entry in byVendor.entries) {
      if (entry.value.length < 2) continue;
      final sorted = List<ExpenseEntry>.from(entry.value)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final gaps = <int>[];
      for (var i = 1; i < sorted.length; i++) {
        gaps.add(sorted[i].timestamp.difference(sorted[i - 1].timestamp).inDays);
      }
      if (gaps.isEmpty) continue;
      final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
      final avgAmount =
          sorted.map((e) => e.amount).reduce((a, b) => a + b) / sorted.length;

      String frequency;
      double annualMultiplier;
      if (avgGap < 10) {
        frequency = 'Weekly';
        annualMultiplier = 52;
      } else if (avgGap < 45) {
        frequency = 'Monthly';
        annualMultiplier = 12;
      } else if (avgGap < 100) {
        frequency = 'Quarterly';
        annualMultiplier = 4;
      } else {
        frequency = 'Yearly';
        annualMultiplier = 1;
      }

      final lastDate = sorted.last.timestamp;
      final nextExpected = lastDate.add(Duration(days: avgGap.round()));

      recurring.add(RecurringExpense(
        name: entry.key,
        amount: avgAmount,
        category: sorted.last.category,
        frequency: frequency,
        nextExpected: nextExpected,
        annualCost: avgAmount * annualMultiplier,
      ));
    }

    recurring.sort((a, b) => b.annualCost.compareTo(a.annualCost));
    return recurring;
  }

  /// Generate budget alerts.
  List<BudgetAlert> _generateAlerts(
    List<CategoryForecast> forecasts,
    double totalForecast,
    double monthlyBudget,
  ) {
    final alerts = <BudgetAlert>[];
    final ratio = monthlyBudget > 0 ? totalForecast / monthlyBudget : 0.0;

    if (ratio > 1.0) {
      alerts.add(BudgetAlert(
        type: 'projected_exceed',
        message:
            'Projected spending \$${totalForecast.toStringAsFixed(0)} exceeds '
            'budget \$${monthlyBudget.toStringAsFixed(0)} by '
            '\$${(totalForecast - monthlyBudget).toStringAsFixed(0)}',
        severity: AlertSeverity.high,
      ));
    } else if (ratio > 0.8) {
      alerts.add(BudgetAlert(
        type: 'approaching',
        message:
            'On track to use ${(ratio * 100).toStringAsFixed(0)}% of budget',
        severity: AlertSeverity.medium,
      ));
    }

    for (final f in forecasts) {
      if (f.trend == TrendDirection.up && f.changePercent > 25) {
        alerts.add(BudgetAlert(
          type: 'spike',
          category: f.category,
          message:
              '${f.category.label} trending up ${f.changePercent.toStringAsFixed(0)}%',
          severity:
              f.changePercent > 50 ? AlertSeverity.high : AlertSeverity.medium,
        ));
      }
    }

    alerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return alerts;
  }

  /// Identify savings potential from high-variance categories.
  double _calcSavingsPotential(List<ExpenseEntry> entries) {
    final now = DateTime.now();
    final byCategory = <ExpenseCategory, List<ExpenseEntry>>{};
    for (final e in entries) {
      if (e.category == ExpenseCategory.income) continue;
      byCategory.putIfAbsent(e.category, () => []).add(e);
    }

    var potential = 0.0;
    for (final entry in byCategory.entries) {
      final monthly = _monthlyTotals(entry.value, now, 6);
      if (monthly.length < 2) continue;
      final mean = monthly.reduce((a, b) => a + b) / monthly.length;
      final minVal = monthly.reduce(min);
      if (mean > 0 && (mean - minVal) / mean > 0.3) {
        potential += mean - minVal;
      }
    }
    return potential;
  }

  /// Data quality score based on coverage and consistency.
  double _calcDataQuality(List<ExpenseEntry> entries) {
    if (entries.isEmpty) return 0;
    final now = DateTime.now();
    final oldest = entries
        .map((e) => e.timestamp)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final daysCovered = now.difference(oldest).inDays.abs();
    final coverageScore = (daysCovered / 180).clamp(0.0, 1.0);
    final volumeScore = (entries.length / 100).clamp(0.0, 1.0);
    final categoryCount =
        entries.map((e) => e.category).toSet().length;
    final diversityScore = (categoryCount / 8).clamp(0.0, 1.0);
    return (coverageScore * 0.4 + volumeScore * 0.3 + diversityScore * 0.3);
  }

  /// Generate demo data for preview when no real data exists.
  List<ExpenseEntry> generateDemoData() {
    final now = DateTime.now();
    final rng = Random(42);
    final entries = <ExpenseEntry>[];
    final categories = [
      ExpenseCategory.food,
      ExpenseCategory.transport,
      ExpenseCategory.utilities,
      ExpenseCategory.entertainment,
      ExpenseCategory.shopping,
      ExpenseCategory.subscriptions,
      ExpenseCategory.health,
    ];
    final vendors = {
      ExpenseCategory.food: ['Groceries', 'Restaurant', 'Coffee', 'Takeout'],
      ExpenseCategory.transport: ['Gas', 'Uber', 'Bus Pass', 'Parking'],
      ExpenseCategory.utilities: ['Electric', 'Water', 'Internet', 'Phone'],
      ExpenseCategory.entertainment: ['Netflix', 'Movies', 'Games', 'Concert'],
      ExpenseCategory.shopping: ['Clothes', 'Electronics', 'Home Decor', 'Books'],
      ExpenseCategory.subscriptions: ['Spotify', 'Gym', 'Cloud Storage', 'News'],
      ExpenseCategory.health: ['Pharmacy', 'Doctor', 'Vitamins', 'Dental'],
    };
    final baseCosts = {
      ExpenseCategory.food: 45.0,
      ExpenseCategory.transport: 35.0,
      ExpenseCategory.utilities: 80.0,
      ExpenseCategory.entertainment: 25.0,
      ExpenseCategory.shopping: 50.0,
      ExpenseCategory.subscriptions: 15.0,
      ExpenseCategory.health: 40.0,
    };

    for (var m = 5; m >= 0; m--) {
      for (final cat in categories) {
        final count = 3 + rng.nextInt(5);
        for (var i = 0; i < count; i++) {
          final day = 1 + rng.nextInt(28);
          final base = baseCosts[cat] ?? 30.0;
          final amount =
              base * (0.5 + rng.nextDouble() * 1.5) * (1 + m * 0.03);
          final vendorList = vendors[cat] ?? ['Expense'];
          entries.add(ExpenseEntry(
            id: 'demo_${m}_${cat.name}_$i',
            vendor: vendorList[rng.nextInt(vendorList.length)],
            amount: double.parse(amount.toStringAsFixed(2)),
            category: cat,
            timestamp: DateTime(now.year, now.month - m, day),
          ));
        }
      }
    }
    return entries;
  }
}
