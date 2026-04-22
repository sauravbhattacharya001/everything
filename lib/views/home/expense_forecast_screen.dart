import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/expense_forecast_service.dart';
import '../../models/expense_entry.dart';

/// Expense Forecaster — autonomous spending prediction with category forecasts,
/// anomaly detection, recurring expense identification, and budget alerts.
class ExpenseForecastScreen extends StatefulWidget {
  const ExpenseForecastScreen({super.key});

  @override
  State<ExpenseForecastScreen> createState() => _ExpenseForecastScreenState();
}

class _ExpenseForecastScreenState extends State<ExpenseForecastScreen>
    with SingleTickerProviderStateMixin {
  static const _expenseKey = 'expense_tracker_data';
  final _service = ExpenseForecastService();
  late TabController _tabController;
  ForecastReport? _report;
  bool _usingDemo = false;
  double _monthlyBudget = 3000.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAndForecast();
  }

  Future<void> _loadAndForecast() async {
    final prefs = await SharedPreferences.getInstance();
    var entries = <ExpenseEntry>[];

    final json = prefs.getString(_expenseKey);
    if (json != null && json.isNotEmpty) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        final list = data['entries'] as List<dynamic>? ?? [];
        entries = list
            .map((e) => ExpenseEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        final config = data['config'] as Map<String, dynamic>?;
        if (config != null) {
          _monthlyBudget =
              (config['monthlyBudget'] as num?)?.toDouble() ?? 3000.0;
        }
      } catch (_) {}
    }

    if (entries.isEmpty) {
      entries = _service.generateDemoData();
      _usingDemo = true;
    }

    setState(() {
      _report = _service.generateReport(entries, monthlyBudget: _monthlyBudget);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Forecaster'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.category), text: 'Categories'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Alerts'),
            Tab(icon: Icon(Icons.repeat), text: 'Recurring'),
          ],
        ),
      ),
      body: _report == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_usingDemo)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: cs.tertiaryContainer,
                    child: Text(
                      '📊 Showing demo data — add expenses in Expense Tracker to see real forecasts',
                      style: TextStyle(color: cs.onTertiaryContainer, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverview(cs),
                      _buildCategories(cs),
                      _buildAlerts(cs),
                      _buildRecurring(cs),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverview(ColorScheme cs) {
    final r = _report!;
    final budgetRatio =
        _monthlyBudget > 0 ? r.totalForecast / _monthlyBudget : 0.0;
    final healthColor = budgetRatio > 1.0
        ? Colors.red
        : budgetRatio > 0.8
            ? Colors.orange
            : Colors.green;
    final healthEmoji = budgetRatio > 1.0
        ? '🔴'
        : budgetRatio > 0.8
            ? '🟡'
            : '🟢';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Health score card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('$healthEmoji Financial Health',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: budgetRatio.clamp(0.0, 1.0),
                        strokeWidth: 12,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(healthColor),
                      ),
                      Center(
                        child: Text(
                          '${(budgetRatio * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: healthColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('of budget projected',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Key metrics
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Forecast',
                '\$${r.totalForecast.toStringAsFixed(0)}',
                Icons.trending_up,
                cs,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard(
                'Budget',
                '\$${_monthlyBudget.toStringAsFixed(0)}',
                Icons.account_balance_wallet,
                cs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Confidence',
                '${(r.totalConfidence * 100).toStringAsFixed(0)}%',
                Icons.psychology,
                cs,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard(
                'Save Potential',
                '\$${r.savingsPotential.toStringAsFixed(0)}',
                Icons.savings,
                cs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Anomalies',
                '${r.anomalies.length}',
                Icons.report_problem,
                cs,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard(
                'Data Quality',
                '${(r.dataQualityScore * 100).toStringAsFixed(0)}%',
                Icons.data_usage,
                cs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Top categories preview
        if (r.categoryForecasts.isNotEmpty) ...[
          Text('Top Spending Categories',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...r.categoryForecasts.take(5).map((f) => _categoryTile(f, cs)),
        ],
      ],
    );
  }

  Widget _metricCard(
      String label, String value, IconData icon, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _categoryTile(CategoryForecast f, ColorScheme cs) {
    final trendIcon = f.trend == TrendDirection.up
        ? Icons.trending_up
        : f.trend == TrendDirection.down
            ? Icons.trending_down
            : Icons.trending_flat;
    final trendColor = f.trend == TrendDirection.up
        ? Colors.red
        : f.trend == TrendDirection.down
            ? Colors.green
            : cs.onSurfaceVariant;

    return Card(
      child: ListTile(
        leading: Text(f.category.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(f.category.label),
        subtitle: Row(
          children: [
            Text('${(f.confidence * 100).toStringAsFixed(0)}% confidence'),
            const SizedBox(width: 8),
            // Mini sparkline
            ...f.recentMonthly.take(6).map((_) {
              return Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(128),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${f.predictedAmount.toStringAsFixed(0)}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Icon(trendIcon, color: trendColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(ColorScheme cs) {
    final forecasts = _report!.categoryForecasts;
    if (forecasts.isEmpty) {
      return const Center(child: Text('No category data available'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: forecasts.length,
      itemBuilder: (context, i) {
        final f = forecasts[i];
        return _categoryDetailCard(f, cs);
      },
    );
  }

  Widget _categoryDetailCard(CategoryForecast f, ColorScheme cs) {
    final changeSign = f.changePercent >= 0 ? '+' : '';
    final maxVal = f.recentMonthly.isEmpty
        ? 1.0
        : f.recentMonthly.reduce((a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(f.category.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.category.label,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '$changeSign${f.changePercent.toStringAsFixed(1)}% from last month',
                        style: TextStyle(
                          color: f.changePercent > 0
                              ? Colors.red
                              : f.changePercent < 0
                                  ? Colors.green
                                  : cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${f.predictedAmount.toStringAsFixed(0)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(f.confidence * 100).toStringAsFixed(0)}% conf.',
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Sparkline bars
            SizedBox(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: f.recentMonthly.map((v) {
                  final h = maxVal > 0 ? (v / maxVal) * 36 + 4 : 4.0;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: h,
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(180),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('6 months ago',
                    style:
                        TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                Text('This month',
                    style:
                        TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerts(ColorScheme cs) {
    final alerts = _report!.alerts;
    final anomalies = _report!.anomalies;
    if (alerts.isEmpty && anomalies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('All clear! No alerts or anomalies detected.'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (alerts.isNotEmpty) ...[
          Text('Budget Alerts',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...alerts.map((a) => _alertCard(a, cs)),
          const SizedBox(height: 16),
        ],
        if (anomalies.isNotEmpty) ...[
          Text('Spending Anomalies',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...anomalies.map((a) => _anomalyCard(a, cs)),
        ],
      ],
    );
  }

  Widget _alertCard(BudgetAlert a, ColorScheme cs) {
    final icon = a.severity == AlertSeverity.high
        ? Icons.error
        : a.severity == AlertSeverity.medium
            ? Icons.warning
            : Icons.info;
    final color = a.severity == AlertSeverity.high
        ? Colors.red
        : a.severity == AlertSeverity.medium
            ? Colors.orange
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(a.message),
        subtitle: a.category != null
            ? Text('Category: ${a.category!.label}')
            : null,
        trailing: Chip(
          label: Text(a.severity.name.toUpperCase(),
              style: const TextStyle(fontSize: 10)),
          backgroundColor: color.withAlpha(40),
        ),
      ),
    );
  }

  Widget _anomalyCard(SpendingAnomaly a, ColorScheme cs) {
    final color = a.severity == AlertSeverity.high
        ? Colors.red
        : a.severity == AlertSeverity.medium
            ? Colors.orange
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(40),
          child: Text(a.category.emoji),
        ),
        title: Text(a.description),
        subtitle: Text(
          '${a.date.month}/${a.date.day}/${a.date.year}',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildRecurring(ColorScheme cs) {
    final recurring = _report!.recurringExpenses;
    if (recurring.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No recurring expenses detected yet.'),
            SizedBox(height: 8),
            Text('Add more expenses to improve detection.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final totalAnnual =
        recurring.fold(0.0, (s, r) => s + r.annualCost);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: cs.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Annual Recurring',
                          style: TextStyle(color: cs.onPrimaryContainer)),
                      Text(
                        '\$${totalAnnual.toStringAsFixed(0)}/year',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${(totalAnnual / 12).toStringAsFixed(0)}/mo',
                  style: TextStyle(color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...recurring.map((r) => _recurringCard(r, cs)),
      ],
    );
  }

  Widget _recurringCard(RecurringExpense r, ColorScheme cs) {
    final freqColor = r.frequency == 'Weekly'
        ? Colors.blue
        : r.frequency == 'Monthly'
            ? Colors.purple
            : r.frequency == 'Quarterly'
                ? Colors.teal
                : Colors.brown;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(r.category.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(r.name[0].toUpperCase() + r.name.substring(1)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${r.amount.toStringAsFixed(2)} per charge'),
            if (r.nextExpected != null)
              Text(
                'Next: ${r.nextExpected!.month}/${r.nextExpected!.day}/${r.nextExpected!.year}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Chip(
              label: Text(r.frequency,
                  style: const TextStyle(fontSize: 10)),
              backgroundColor: freqColor.withAlpha(40),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            Text(
              '\$${r.annualCost.toStringAsFixed(0)}/yr',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurfaceVariant,
                  fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
