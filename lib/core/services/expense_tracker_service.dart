import 'dart:convert';
import 'dart:math';
import '../../models/expense_entry.dart';
import '../utils/date_utils.dart';
import 'service_persistence.dart';

/// Configuration for expense tracking budgets.
class BudgetConfig {
  /// Monthly budget limit.
  final double monthlyBudget;

  /// Per-category monthly limits (optional).
  final Map<ExpenseCategory, double> categoryLimits;

  /// Alert threshold as percentage (0.0-1.0). Default 0.8 = alert at 80%.
  final double alertThreshold;

  /// Currency symbol for display.
  final String currencySymbol;

  const BudgetConfig({
    this.monthlyBudget = 3000.0,
    this.categoryLimits = const {},
    this.alertThreshold = 0.8,
    this.currencySymbol = '\$',
  });

  Map<String, dynamic> toJson() => {
        'monthlyBudget': monthlyBudget,
        'categoryLimits': categoryLimits
            .map((k, v) => MapEntry(k.name, v)),
        'alertThreshold': alertThreshold,
        'currencySymbol': currencySymbol,
      };

  factory BudgetConfig.fromJson(Map<String, dynamic> json) {
    final limitsRaw =
        json['categoryLimits'] as Map<String, dynamic>? ?? {};
    final limits = <ExpenseCategory, double>{};
    for (final entry in limitsRaw.entries) {
      final cat = ExpenseCategory.values.firstWhere(
        (v) => v.name == entry.key,
        orElse: () => ExpenseCategory.other,
      );
      limits[cat] = (entry.value as num).toDouble();
    }
    return BudgetConfig(
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble() ?? 3000.0,
      categoryLimits: limits,
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble() ?? 0.8,
      currencySymbol: json['currencySymbol'] as String? ?? '\$',
    );
  }
}

/// Daily spending summary.
class DailyExpenseSummary {
  final DateTime date;
  final double totalSpent;
  final double totalIncome;
  final int transactionCount;
  final Map<ExpenseCategory, double> byCategory;
  final Map<PaymentMethod, double> byPaymentMethod;

  const DailyExpenseSummary({
    required this.date,
    required this.totalSpent,
    required this.totalIncome,
    required this.transactionCount,
    required this.byCategory,
    required this.byPaymentMethod,
  });

  double get netFlow => totalIncome - totalSpent;
  String get grade {
    // Relative to a daily budget (monthly / 30)
    return totalSpent == 0 ? 'A+' : 'N/A';
  }
}

/// Monthly spending report.
class MonthlyReport {
  final int year;
  final int month;
  final double totalSpent;
  final double totalIncome;
  final double budget;
  final int transactionCount;
  final Map<ExpenseCategory, double> byCategory;
  final Map<PaymentMethod, double> byPaymentMethod;
  final List<DailyExpenseSummary> dailySummaries;
  final double averageDailySpend;
  final double projectedMonthlySpend;
  final List<BudgetAlert> alerts;

  const MonthlyReport({
    required this.year,
    required this.month,
    required this.totalSpent,
    required this.totalIncome,
    required this.budget,
    required this.transactionCount,
    required this.byCategory,
    required this.byPaymentMethod,
    required this.dailySummaries,
    required this.averageDailySpend,
    required this.projectedMonthlySpend,
    required this.alerts,
  });

  double get budgetUsedPercent =>
      budget > 0 ? (totalSpent / budget * 100).clamp(0, 999) : 0;
  double get remainingBudget => budget - totalSpent;
  double get savingsRate =>
      totalIncome > 0 ? ((totalIncome - totalSpent) / totalIncome * 100) : 0;

  String get budgetGrade {
    final pct = budgetUsedPercent;
    if (pct <= 50) return 'A';
    if (pct <= 70) return 'B';
    if (pct <= 90) return 'C';
    if (pct <= 100) return 'D';
    return 'F';
  }
}

/// Budget alert when spending approaches or exceeds limits.
class BudgetAlert {
  final String message;
  final String severity; // 'info', 'warning', 'critical'
  final ExpenseCategory? category;
  final double currentAmount;
  final double limitAmount;

  const BudgetAlert({
    required this.message,
    required this.severity,
    this.category,
    required this.currentAmount,
    required this.limitAmount,
  });

  double get percentUsed =>
      limitAmount > 0 ? currentAmount / limitAmount * 100 : 0;
}

/// Spending trend over time.
class SpendingTrend {
  final List<double> weeklyTotals;
  final double trend; // positive = increasing, negative = decreasing
  final String direction; // 'increasing', 'decreasing', 'stable'

  const SpendingTrend({
    required this.weeklyTotals,
    required this.trend,
    required this.direction,
  });
}

/// Vendor spending analysis.
class VendorStats {
  final String vendor;
  final double totalSpent;
  final int transactionCount;
  final double averageTransaction;
  final ExpenseCategory primaryCategory;

  const VendorStats({
    required this.vendor,
    required this.totalSpent,
    required this.transactionCount,
    required this.averageTransaction,
    required this.primaryCategory,
  });
}

/// Full expense report with insights.
class ExpenseReport {
  final MonthlyReport currentMonth;
  final SpendingTrend trend;
  final List<VendorStats> topVendors;
  final List<String> insights;
  final Map<ExpenseCategory, double> categoryPercentages;

  const ExpenseReport({
    required this.currentMonth,
    required this.trend,
    required this.topVendors,
    required this.insights,
    required this.categoryPercentages,
  });

  String toTextSummary(String currencySymbol) {
    final buf = StringBuffer();
    buf.writeln('=== Expense Report: ${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')} ===');
    buf.writeln('Total Spent: $currencySymbol${currentMonth.totalSpent.toStringAsFixed(2)}');
    buf.writeln('Total Income: $currencySymbol${currentMonth.totalIncome.toStringAsFixed(2)}');
    buf.writeln('Budget: $currencySymbol${currentMonth.budget.toStringAsFixed(2)} (${currentMonth.budgetUsedPercent.toStringAsFixed(1)}% used, Grade: ${currentMonth.budgetGrade})');
    buf.writeln('Savings Rate: ${currentMonth.savingsRate.toStringAsFixed(1)}%');
    buf.writeln('Transactions: ${currentMonth.transactionCount}');
    buf.writeln('Avg Daily Spend: $currencySymbol${currentMonth.averageDailySpend.toStringAsFixed(2)}');
    buf.writeln('Projected Monthly: $currencySymbol${currentMonth.projectedMonthlySpend.toStringAsFixed(2)}');
    buf.writeln('');
    buf.writeln('--- By Category ---');
    for (final entry in currentMonth.byCategory.entries) {
      final pct = categoryPercentages[entry.key] ?? 0;
      buf.writeln('  ${entry.key.emoji} ${entry.key.label}: $currencySymbol${entry.value.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)');
    }
    buf.writeln('');
    buf.writeln('--- Trend: ${trend.direction} ---');
    buf.writeln('Weekly totals: ${trend.weeklyTotals.map((w) => '$currencySymbol${w.toStringAsFixed(0)}').join(', ')}');
    if (topVendors.isNotEmpty) {
      buf.writeln('');
      buf.writeln('--- Top Vendors ---');
      for (final v in topVendors.take(5)) {
        buf.writeln('  ${v.vendor}: $currencySymbol${v.totalSpent.toStringAsFixed(2)} (${v.transactionCount}x)');
      }
    }
    if (insights.isNotEmpty) {
      buf.writeln('');
      buf.writeln('--- Insights ---');
      for (final i in insights) {
        buf.writeln('  💡 $i');
      }
    }
    if (currentMonth.alerts.isNotEmpty) {
      buf.writeln('');
      buf.writeln('--- Alerts ---');
      for (final a in currentMonth.alerts) {
        final icon = a.severity == 'critical' ? '🚨' : a.severity == 'warning' ? '⚠️' : 'ℹ️';
        buf.writeln('  $icon ${a.message}');
      }
    }
    return buf.toString();
  }
}

/// Expense tracker service with budgeting, analytics, and insights.
class ExpenseTrackerService with ServicePersistence {
  final List<ExpenseEntry> _entries = [];
  BudgetConfig _config;

  @override
  String get storageKey => 'expense_tracker_data';

  @override
  Map<String, dynamic> toStorageJson() => {
        'entries': _entries.map((e) => e.toJson()).toList(),
        'config': {
          'monthlyBudget': _config.monthlyBudget,
          'alertThreshold': _config.alertThreshold,
          'currencySymbol': _config.currencySymbol,
        },
      };

  @override
  void fromStorageJson(Map<String, dynamic> json) {
    _entries.clear();
    if (json['entries'] != null) {
      _entries.addAll(
        (json['entries'] as List).map((e) => ExpenseEntry.fromJson(e as Map<String, dynamic>)),
      );
    }
    if (json['config'] != null) {
      final c = json['config'] as Map<String, dynamic>;
      _config = BudgetConfig(
        monthlyBudget: (c['monthlyBudget'] as num?)?.toDouble() ?? 3000.0,
        alertThreshold: (c['alertThreshold'] as num?)?.toDouble() ?? 0.8,
        currencySymbol: c['currencySymbol'] as String? ?? '\$',
      );
    }
  }

  ExpenseTrackerService({BudgetConfig? config})
      : _config = config ?? const BudgetConfig();

  // --- Config ---

  BudgetConfig get config => _config;

  void updateConfig(BudgetConfig config) {
    _config = config;
  }

  // --- CRUD ---

  List<ExpenseEntry> get entries => List.unmodifiable(_entries);

  void addEntry(ExpenseEntry entry) {
    _entries.add(entry);
  }

  void addEntries(List<ExpenseEntry> entries) {
    _entries.addAll(entries);
  }

  bool removeEntry(String id) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx < 0) return false;
    _entries.removeAt(idx);
    return true;
  }

  ExpenseEntry? getEntry(String id) {
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  bool updateEntry(String id, ExpenseEntry updated) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx < 0) return false;
    _entries[idx] = updated;
    return true;
  }

  // --- Filtering ---

  List<ExpenseEntry> getEntriesForDate(DateTime date) {
    return _entries
        .where((e) => AppDateUtils.isSameDay(e.timestamp, date))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<ExpenseEntry> getEntriesForMonth(int year, int month) {
    return _entries
        .where((e) => e.timestamp.year == year && e.timestamp.month == month)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<ExpenseEntry> getEntriesInRange(DateTime start, DateTime end) {
    return _entries
        .where((e) =>
            !e.timestamp.isBefore(start) && e.timestamp.isBefore(end))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<ExpenseEntry> getByCategory(ExpenseCategory category) {
    return _entries.where((e) => e.category == category).toList();
  }

  List<ExpenseEntry> getByVendor(String vendor) {
    final lower = vendor.toLowerCase();
    return _entries
        .where((e) =>
            e.vendor != null && e.vendor!.toLowerCase().contains(lower))
        .toList();
  }

  List<ExpenseEntry> getByTag(String tag) {
    final lower = tag.toLowerCase();
    return _entries
        .where(
            (e) => e.tags.any((t) => t.toLowerCase() == lower))
        .toList();
  }

  List<ExpenseEntry> getRecurring() {
    return _entries.where((e) => e.isRecurring).toList();
  }

  // --- Daily Summary ---

  DailyExpenseSummary getDailySummary(DateTime date) {
    final dayEntries = getEntriesForDate(date);
    double totalSpent = 0;
    double totalIncome = 0;
    final byCategory = <ExpenseCategory, double>{};
    final byPayment = <PaymentMethod, double>{};

    for (final e in dayEntries) {
      if (e.category.isIncome) {
        totalIncome += e.amount;
      } else {
        totalSpent += e.amount;
      }
      byCategory[e.category] =
          (byCategory[e.category] ?? 0) + e.amount;
      byPayment[e.paymentMethod] =
          (byPayment[e.paymentMethod] ?? 0) + e.amount;
    }

    return DailyExpenseSummary(
      date: date,
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      transactionCount: dayEntries.length,
      byCategory: byCategory,
      byPaymentMethod: byPayment,
    );
  }

  // --- Monthly Report ---

  MonthlyReport getMonthlyReport(int year, int month) {
    final monthEntries = getEntriesForMonth(year, month);
    double totalSpent = 0;
    double totalIncome = 0;
    final byCategory = <ExpenseCategory, double>{};
    final byPayment = <PaymentMethod, double>{};

    for (final e in monthEntries) {
      if (e.category.isIncome) {
        totalIncome += e.amount;
      } else {
        totalSpent += e.amount;
      }
      byCategory[e.category] =
          (byCategory[e.category] ?? 0) + e.amount;
      byPayment[e.paymentMethod] =
          (byPayment[e.paymentMethod] ?? 0) + e.amount;
    }

    // Daily summaries — pre-group entries by day to avoid O(days * entries)
    // rescanning.  Previous code called getDailySummary() per day, each of
    // which scanned the full entry list via getEntriesForDate().
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final dayBuckets = <int, List<ExpenseEntry>>{};
    for (final e in monthEntries) {
      dayBuckets.putIfAbsent(e.timestamp.day, () => []).add(e);
    }
    final dailySummaries = <DailyExpenseSummary>[];
    int daysWithData = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      if (date.isAfter(DateTime.now())) break;
      final dayEntries = dayBuckets[d] ?? [];
      double daySpent = 0;
      double dayIncome = 0;
      final dayCat = <ExpenseCategory, double>{};
      final dayPay = <PaymentMethod, double>{};
      for (final e in dayEntries) {
        if (e.category.isIncome) {
          dayIncome += e.amount;
        } else {
          daySpent += e.amount;
        }
        dayCat[e.category] = (dayCat[e.category] ?? 0) + e.amount;
        dayPay[e.paymentMethod] = (dayPay[e.paymentMethod] ?? 0) + e.amount;
      }
      dailySummaries.add(DailyExpenseSummary(
        date: date,
        totalSpent: daySpent,
        totalIncome: dayIncome,
        transactionCount: dayEntries.length,
        byCategory: dayCat,
        byPaymentMethod: dayPay,
      ));
      if (dayEntries.isNotEmpty) daysWithData++;
    }

    final avgDaily =
        daysWithData > 0 ? totalSpent / daysWithData : 0.0;
    final daysSoFar = dailySummaries.length;
    final projected = daysSoFar > 0
        ? (totalSpent / daysSoFar) * daysInMonth
        : 0.0;

    // Budget alerts
    final alerts = <BudgetAlert>[];
    final budgetPct = _config.monthlyBudget > 0
        ? totalSpent / _config.monthlyBudget
        : 0.0;

    if (budgetPct >= 1.0) {
      alerts.add(BudgetAlert(
        message:
            'Monthly budget exceeded! Spent ${_config.currencySymbol}${totalSpent.toStringAsFixed(2)} of ${_config.currencySymbol}${_config.monthlyBudget.toStringAsFixed(2)}',
        severity: 'critical',
        currentAmount: totalSpent,
        limitAmount: _config.monthlyBudget,
      ));
    } else if (budgetPct >= _config.alertThreshold) {
      alerts.add(BudgetAlert(
        message:
            'Approaching monthly budget: ${(budgetPct * 100).toStringAsFixed(1)}% used',
        severity: 'warning',
        currentAmount: totalSpent,
        limitAmount: _config.monthlyBudget,
      ));
    }

    // Category-specific alerts
    for (final catLimit in _config.categoryLimits.entries) {
      final spent = byCategory[catLimit.key] ?? 0;
      final pct = catLimit.value > 0 ? spent / catLimit.value : 0.0;
      if (pct >= 1.0) {
        alerts.add(BudgetAlert(
          message:
              '${catLimit.key.label} budget exceeded: ${_config.currencySymbol}${spent.toStringAsFixed(2)} of ${_config.currencySymbol}${catLimit.value.toStringAsFixed(2)}',
          severity: 'critical',
          category: catLimit.key,
          currentAmount: spent,
          limitAmount: catLimit.value,
        ));
      } else if (pct >= _config.alertThreshold) {
        alerts.add(BudgetAlert(
          message:
              '${catLimit.key.label} budget at ${(pct * 100).toStringAsFixed(1)}%',
          severity: 'warning',
          category: catLimit.key,
          currentAmount: spent,
          limitAmount: catLimit.value,
        ));
      }
    }

    return MonthlyReport(
      year: year,
      month: month,
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      budget: _config.monthlyBudget,
      transactionCount: monthEntries.length,
      byCategory: byCategory,
      byPaymentMethod: byPayment,
      dailySummaries: dailySummaries,
      averageDailySpend: avgDaily,
      projectedMonthlySpend: projected,
      alerts: alerts,
    );
  }

  // --- Spending Trend ---

  SpendingTrend getSpendingTrend({int weeks = 4}) {
    final now = DateTime.now();
    final periodStart = now.subtract(Duration(days: weeks * 7));
    final weeklyTotals = List<double>.filled(weeks, 0.0);

    // Single pass over entries instead of per-week getEntriesInRange scans.
    for (final e in _entries) {
      if (e.category.isIncome) continue;
      if (e.timestamp.isBefore(periodStart) || !e.timestamp.isBefore(now)) {
        continue;
      }
      final daysAgo = now.difference(e.timestamp).inDays;
      final weekIndex = weeks - 1 - (daysAgo ~/ 7);
      if (weekIndex >= 0 && weekIndex < weeks) {
        weeklyTotals[weekIndex] += e.amount;
      }
    }

    // Simple linear trend
    double trend = 0;
    if (weeklyTotals.length >= 2) {
      final n = weeklyTotals.length;
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      for (int i = 0; i < n; i++) {
        sumX += i;
        sumY += weeklyTotals[i];
        sumXY += i * weeklyTotals[i];
        sumX2 += i * i;
      }
      final denom = n * sumX2 - sumX * sumX;
      trend = denom != 0 ? (n * sumXY - sumX * sumY) / denom : 0;
    }

    final direction = trend > 10
        ? 'increasing'
        : trend < -10
            ? 'decreasing'
            : 'stable';

    return SpendingTrend(
      weeklyTotals: weeklyTotals,
      trend: trend,
      direction: direction,
    );
  }

  // --- Vendor Analysis ---

  List<VendorStats> getTopVendors({int limit = 10}) {
    final vendorMap = <String, List<ExpenseEntry>>{};
    for (final e in _entries) {
      if (e.vendor != null && e.vendor!.isNotEmpty && !e.category.isIncome) {
        vendorMap.putIfAbsent(e.vendor!, () => []).add(e);
      }
    }

    final stats = vendorMap.entries.map((entry) {
      final total = entry.value.fold<double>(0, (s, e) => s + e.amount);
      // Find most common category
      final catCounts = <ExpenseCategory, int>{};
      for (final e in entry.value) {
        catCounts[e.category] = (catCounts[e.category] ?? 0) + 1;
      }
      final primaryCat = catCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      return VendorStats(
        vendor: entry.key,
        totalSpent: total,
        transactionCount: entry.value.length,
        averageTransaction: total / entry.value.length,
        primaryCategory: primaryCat,
      );
    }).toList();

    stats.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return stats.take(limit).toList();
  }

  // --- Category Percentages ---

  Map<ExpenseCategory, double> getCategoryPercentages(
      List<ExpenseEntry> entries) {
    double totalExpenses = 0;
    final byCategory = <ExpenseCategory, double>{};

    for (final e in entries) {
      if (!e.category.isIncome) {
        totalExpenses += e.amount;
        byCategory[e.category] =
            (byCategory[e.category] ?? 0) + e.amount;
      }
    }

    if (totalExpenses == 0) return {};

    return byCategory
        .map((k, v) => MapEntry(k, v / totalExpenses * 100));
  }

  // --- Insights ---

  /// Generate insights for a month.
  ///
  /// When [report] and [percentages] are provided they are reused directly,
  /// avoiding the redundant full-entry scans that occur when this method is
  /// called from [getFullReport] (which already computed both).
  List<String> generateInsights(int year, int month, {
    MonthlyReport? report,
    Map<ExpenseCategory, double>? percentages,
  }) {
    final insights = <String>[];
    report ??= getMonthlyReport(year, month);
    percentages ??= getCategoryPercentages(getEntriesForMonth(year, month));

    // Top spending category
    if (percentages.isNotEmpty) {
      final top = percentages.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      insights.add(
          '${top.key.emoji} ${top.key.label} is your top spending category at ${top.value.toStringAsFixed(1)}%');
    }

    // Savings rate
    if (report.totalIncome > 0) {
      final rate = report.savingsRate;
      if (rate >= 20) {
        insights.add('💪 Great savings rate of ${rate.toStringAsFixed(1)}%!');
      } else if (rate >= 0) {
        insights.add(
            '📊 Savings rate is ${rate.toStringAsFixed(1)}%. Aim for 20%+.');
      } else {
        insights.add('⚠️ You\'re spending more than you earn this month.');
      }
    }

    // Recurring expenses
    final recurring = getRecurring();
    if (recurring.isNotEmpty) {
      final recurringTotal =
          recurring.fold<double>(0, (s, e) => s + e.amount);
      insights.add(
          '🔄 ${recurring.length} recurring expenses totaling ${_config.currencySymbol}${recurringTotal.toStringAsFixed(2)}');
    }

    // Daily spending pattern
    if (report.averageDailySpend > 0) {
      final dailyBudget = _config.monthlyBudget / 30;
      if (report.averageDailySpend > dailyBudget * 1.2) {
        insights.add(
            '📈 Daily spending (${_config.currencySymbol}${report.averageDailySpend.toStringAsFixed(2)}) exceeds daily budget target');
      }
    }

    // Projected overspend
    if (report.projectedMonthlySpend > _config.monthlyBudget * 1.1) {
      insights.add(
          '🔮 At current pace, projected to spend ${_config.currencySymbol}${report.projectedMonthlySpend.toStringAsFixed(2)} this month');
    }

    return insights;
  }

  // --- Full Report ---

  ExpenseReport getFullReport(int year, int month) {
    final monthlyReport = getMonthlyReport(year, month);
    final trend = getSpendingTrend();
    final topVendors = getTopVendors();
    // Reuse the already-computed monthly entries to avoid re-scanning.
    final monthEntries = getEntriesForMonth(year, month);
    final percentages = getCategoryPercentages(monthEntries);
    final insights = generateInsights(year, month,
        report: monthlyReport, percentages: percentages);

    return ExpenseReport(
      currentMonth: monthlyReport,
      trend: trend,
      topVendors: topVendors,
      insights: insights,
      categoryPercentages: percentages,
    );
  }

  // --- Streak ---

  /// Number of consecutive days (ending today or most recent entry)
  /// where at least one expense was logged.
  int getLoggingStreak() {
    if (_entries.isEmpty) return 0;

    final dates = <DateTime>{};
    for (final e in _entries) {
      dates.add(DateTime(
          e.timestamp.year, e.timestamp.month, e.timestamp.day));
    }

    final sortedDates = dates.toList()
      ..sort((a, b) => b.compareTo(a));

    // Anchor check: most recent entry must be today or yesterday,
    // otherwise the streak is broken.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceLast = today.difference(sortedDates.first).inDays;
    if (daysSinceLast > 1) return 0;

    int streak = 1;
    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i - 1].difference(sortedDates[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // --- Persistence ---

  String exportToJson() {
    return jsonEncode({
      'config': _config.toJson(),
      'entries': _entries.map((e) => e.toJson()).toList(),
    });
  }

  /// Maximum number of entries allowed via import.
  ///
  /// Prevents memory exhaustion from a maliciously crafted JSON file
  /// containing millions of entries.  Normal usage should never come
  /// close to this limit.
  static const int maxImportEntries = 100000;

  void importFromJson(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    // Parse config and entries into temporaries first so that a
    // malformed JSON string doesn't wipe existing financial data.
    BudgetConfig? parsedConfig;
    if (data.containsKey('config')) {
      parsedConfig = BudgetConfig.fromJson(
          data['config'] as Map<String, dynamic>);
    }
    List<ExpenseEntry>? parsedEntries;
    if (data.containsKey('entries')) {
      final list = data['entries'] as List<dynamic>;
      if (list.length > maxImportEntries) {
        throw ArgumentError(
          'Import exceeds maximum of $maxImportEntries entries '
          '(got ${list.length}). This limit prevents memory exhaustion '
          'from corrupted or malicious data.',
        );
      }
      parsedEntries = list
          .map((e) =>
              ExpenseEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // All parsed successfully — safe to apply.
    if (parsedConfig != null) _config = parsedConfig;
    if (parsedEntries != null) {
      _entries.clear();
      _entries.addAll(parsedEntries);
    }
  }

  // --- Text Summary ---

  String getTextSummary(int year, int month) {
    final report = getFullReport(year, month);
    return report.toTextSummary(_config.currencySymbol);
  }
}
