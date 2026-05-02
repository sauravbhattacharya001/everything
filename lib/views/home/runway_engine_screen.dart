import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/runway_engine_service.dart';

/// Personal Runway Engine screen — autonomous financial resilience dashboard.
///
/// 4-tab layout:
/// 1. **Dashboard** — runway gauge, resilience score, key metrics
/// 2. **Burn Rate** — expense breakdown with essential vs discretionary split
/// 3. **Scenarios** — what-if simulation results
/// 4. **Insights** — alerts, recommendations, and trend analysis
class RunwayEngineScreen extends StatefulWidget {
  const RunwayEngineScreen({super.key});

  @override
  State<RunwayEngineScreen> createState() => _RunwayEngineScreenState();
}

class _RunwayEngineScreenState extends State<RunwayEngineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late RunwayEngineService _service;
  RunwayAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _service = RunwayEngineService();
    // Load demo data for first-time users, then analyze
    _loadDemoIfEmpty();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDemoIfEmpty() {
    if (_service.assets.isEmpty && _service.expenses.isEmpty) {
      _loadDemoData();
    }
    _runAnalysis();
  }

  void _loadDemoData() {
    final now = DateTime.now();
    // Sample assets
    _service.addAsset(RunwayAsset(
      id: 'a1',
      name: 'Primary Checking',
      category: AssetCategory.checking,
      balance: 5000,
      lastUpdated: now,
    ));
    _service.addAsset(RunwayAsset(
      id: 'a2',
      name: 'High-Yield Savings',
      category: AssetCategory.savings,
      balance: 15000,
      lastUpdated: now,
    ));
    _service.addAsset(RunwayAsset(
      id: 'a3',
      name: 'Emergency Fund',
      category: AssetCategory.emergencyFund,
      balance: 8000,
      lastUpdated: now,
    ));
    _service.addAsset(RunwayAsset(
      id: 'a4',
      name: 'Investment Portfolio',
      category: AssetCategory.investment,
      balance: 25000,
      lastUpdated: now,
    ));

    // Sample monthly expenses
    _service.addExpense(const RunwayExpense(
      id: 'e1', name: 'Rent', category: ExpenseCategory.housing, monthlyAmount: 2000));
    _service.addExpense(const RunwayExpense(
      id: 'e2', name: 'Utilities', category: ExpenseCategory.utilities, monthlyAmount: 200));
    _service.addExpense(const RunwayExpense(
      id: 'e3', name: 'Groceries', category: ExpenseCategory.food, monthlyAmount: 500));
    _service.addExpense(const RunwayExpense(
      id: 'e4', name: 'Car + Gas', category: ExpenseCategory.transportation, monthlyAmount: 400));
    _service.addExpense(const RunwayExpense(
      id: 'e5', name: 'Health Insurance', category: ExpenseCategory.insurance, monthlyAmount: 300));
    _service.addExpense(const RunwayExpense(
      id: 'e6', name: 'Subscriptions', category: ExpenseCategory.subscriptions, monthlyAmount: 80));
    _service.addExpense(const RunwayExpense(
      id: 'e7', name: 'Entertainment', category: ExpenseCategory.entertainment, monthlyAmount: 150));
    _service.addExpense(const RunwayExpense(
      id: 'e8', name: 'Student Loan', category: ExpenseCategory.debtPayments, monthlyAmount: 350));
    _service.addExpense(const RunwayExpense(
      id: 'e9', name: 'Dining Out', category: ExpenseCategory.food, monthlyAmount: 200, isFixed: false));
    _service.addExpense(const RunwayExpense(
      id: 'e10', name: 'Clothing', category: ExpenseCategory.clothing, monthlyAmount: 100, isFixed: false));

    // Sample history for trend
    for (int i = 5; i >= 0; i--) {
      _service.addSnapshot(RunwaySnapshot(
        date: now.subtract(Duration(days: 30 * i)),
        runwayMonths: 8.0 + i * 0.3,
        burnRate: 4280 - i * 20,
        liquidAssets: 45000 + i * 500,
        resilienceScore: 55 + i * 2,
      ));
    }
  }

  void _runAnalysis() {
    setState(() {
      _analysis = _service.analyze();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✈️ Personal Runway'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.local_fire_department), text: 'Burn Rate'),
            Tab(icon: Icon(Icons.science), text: 'Scenarios'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Insights'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-analyze',
            onPressed: _runAnalysis,
          ),
        ],
      ),
      body: _analysis == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _DashboardTab(analysis: _analysis!),
                _BurnRateTab(analysis: _analysis!),
                _ScenariosTab(analysis: _analysis!),
                _InsightsTab(analysis: _analysis!),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        tooltip: 'Add Asset or Expense',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Entry',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.green),
              title: const Text('Add Asset'),
              subtitle: const Text('Savings, checking, investments, etc.'),
              onTap: () {
                Navigator.pop(ctx);
                _showAssetForm(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.red),
              title: const Text('Add Monthly Expense'),
              subtitle: const Text('Rent, food, subscriptions, etc.'),
              onTap: () {
                Navigator.pop(ctx);
                _showExpenseForm(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAssetForm(BuildContext context) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    AssetCategory selectedCat = AssetCategory.checking;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Asset'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Balance (\$)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AssetCategory>(
                  value: selectedCat,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AssetCategory.values
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.emoji} ${c.label}')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedCat = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final balance =
                    double.tryParse(balanceCtrl.text.replaceAll(',', ''));
                if (nameCtrl.text.isNotEmpty && balance != null) {
                  _service.addAsset(RunwayAsset(
                    id: 'a_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text,
                    category: selectedCat,
                    balance: balance,
                    lastUpdated: DateTime.now(),
                  ));
                  _runAnalysis();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseForm(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    ExpenseCategory selectedCat = ExpenseCategory.other;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Monthly Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Monthly Amount (\$)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ExpenseCategory>(
                  value: selectedCat,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ExpenseCategory.values
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.emoji} ${c.label}')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedCat = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final amount =
                    double.tryParse(amountCtrl.text.replaceAll(',', ''));
                if (nameCtrl.text.isNotEmpty && amount != null) {
                  _service.addExpense(RunwayExpense(
                    id: 'e_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text,
                    category: selectedCat,
                    monthlyAmount: amount,
                  ));
                  _runAnalysis();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Tab 1: Dashboard
// =============================================================================

class _DashboardTab extends StatelessWidget {
  final RunwayAnalysis analysis;
  const _DashboardTab({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final months = analysis.runwayMonthsFull;
    final score = analysis.resilienceScore;
    final tier = analysis.tier;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Runway gauge
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Your Runway',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(
                  months.isInfinite
                      ? '∞'
                      : '${months.toStringAsFixed(1)} months',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _runwayColor(months),
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: months.isInfinite
                      ? 1.0
                      : (months / 24).clamp(0, 1).toDouble(),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  color: _runwayColor(months),
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(height: 8),
                Text(
                  'Austerity mode: ${analysis.runwayMonthsEssentialOnly.isInfinite ? "∞" : "${analysis.runwayMonthsEssentialOnly.toStringAsFixed(1)} months"}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Resilience score
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                        color: _scoreColor(score),
                        backgroundColor: Colors.grey[200],
                      ),
                      Text(
                        score.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resilience Score',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${tier.emoji} ${tier.label}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _scoreColor(score),
                        ),
                      ),
                      if (analysis.runwayTrendPerMonth != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Trend: ${analysis.runwayTrendPerMonth! >= 0 ? "↑" : "↓"} ${analysis.runwayTrendPerMonth!.abs().toStringAsFixed(2)} mo/mo',
                          style: TextStyle(
                            color: analysis.runwayTrendPerMonth! >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Key metrics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Key Metrics',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _MetricRow(
                    label: 'Liquid Assets',
                    value:
                        '\$${analysis.totalLiquidAssets.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet),
                _MetricRow(
                    label: 'Gross Assets',
                    value:
                        '\$${analysis.totalGrossAssets.toStringAsFixed(0)}',
                    icon: Icons.savings),
                _MetricRow(
                    label: 'Monthly Burn Rate',
                    value:
                        '\$${analysis.monthlyBurnRate.toStringAsFixed(0)}/mo',
                    icon: Icons.local_fire_department,
                    valueColor: Colors.red),
                _MetricRow(
                    label: 'Essential Expenses',
                    value:
                        '\$${analysis.essentialBurnRate.toStringAsFixed(0)}/mo',
                    icon: Icons.shield),
                _MetricRow(
                    label: 'Discretionary',
                    value:
                        '\$${analysis.discretionaryBurnRate.toStringAsFixed(0)}/mo',
                    icon: Icons.shopping_bag),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _runwayColor(double months) {
    if (months.isInfinite || months >= 12) return Colors.green;
    if (months >= 6) return Colors.orange;
    if (months >= 3) return Colors.deepOrange;
    return Colors.red;
  }

  Color _scoreColor(double score) {
    if (score >= 85) return Colors.blue;
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    if (score >= 30) return Colors.deepOrange;
    return Colors.red;
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab 2: Burn Rate
// =============================================================================

class _BurnRateTab extends StatelessWidget {
  final RunwayAnalysis analysis;
  const _BurnRateTab({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final breakdown = analysis.burnBreakdown;
    if (breakdown.isEmpty) {
      return const Center(child: Text('No expenses tracked yet.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _BurnSummaryChip(
                      label: 'Total',
                      amount: analysis.monthlyBurnRate,
                      color: Colors.red,
                    ),
                    _BurnSummaryChip(
                      label: 'Essential',
                      amount: analysis.essentialBurnRate,
                      color: Colors.orange,
                    ),
                    _BurnSummaryChip(
                      label: 'Discretionary',
                      amount: analysis.discretionaryBurnRate,
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Essential vs discretionary bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 16,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (analysis.essentialBurnRate * 100).round(),
                          child: Container(color: Colors.orange),
                        ),
                        Expanded(
                          flex: (analysis.discretionaryBurnRate * 100).round(),
                          child: Container(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Essential: ${(analysis.essentialBurnRate / analysis.monthlyBurnRate * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                    Text(
                      'Discretionary: ${(analysis.discretionaryBurnRate / analysis.monthlyBurnRate * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Category breakdown
        ...breakdown.map((b) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      b.isEssential ? Colors.orange[50] : Colors.blue[50],
                  child: Text(b.category.emoji),
                ),
                title: Text(b.category.label),
                subtitle: LinearProgressIndicator(
                  value: b.percentage / 100,
                  color: b.isEssential ? Colors.orange : Colors.blue,
                  backgroundColor: Colors.grey[200],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${b.amount.toStringAsFixed(0)}/mo',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${b.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _BurnSummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _BurnSummaryChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const Text('/month', style: TextStyle(fontSize: 10)),
      ],
    );
  }
}

// =============================================================================
// Tab 3: Scenarios
// =============================================================================

class _ScenariosTab extends StatelessWidget {
  final RunwayAnalysis analysis;
  const _ScenariosTab({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final scenarios = analysis.scenarios;
    if (scenarios.isEmpty) {
      return const Center(
          child: Text('Add assets and expenses to see scenario analysis.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('What-If Scenarios',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'How your runway changes under different life events',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ...scenarios.map((s) => _ScenarioCard(
              scenario: s,
              baselineRunway: analysis.runwayMonthsFull,
            )),
      ],
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final ScenarioResult scenario;
  final double baselineRunway;

  const _ScenarioCard({
    required this.scenario,
    required this.baselineRunway,
  });

  @override
  Widget build(BuildContext context) {
    final diff = scenario.adjustedRunwayMonths - baselineRunway;
    final isWorse = diff < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Text(scenario.type.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(scenario.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Text(
              '${scenario.adjustedRunwayMonths.toStringAsFixed(1)} months',
              style: TextStyle(
                color: scenario.adjustedRunwayMonths < 3
                    ? Colors.red
                    : scenario.adjustedRunwayMonths < 6
                        ? Colors.orange
                        : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${isWorse ? "" : "+"}${diff.toStringAsFixed(1)})',
              style: TextStyle(
                color: isWorse ? Colors.red : Colors.green,
                fontSize: 12,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scenario.type.description,
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                _MetricRow(
                  label: 'Adjusted Burn Rate',
                  value:
                      '\$${scenario.adjustedBurnRate.toStringAsFixed(0)}/mo',
                  icon: Icons.local_fire_department,
                ),
                _MetricRow(
                  label: 'Adjusted Liquid Assets',
                  value:
                      '\$${scenario.adjustedLiquidAssets.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet,
                ),
                if (scenario.portfolioHaircut > 0)
                  _MetricRow(
                    label: 'Portfolio Loss',
                    value:
                        '-\$${scenario.portfolioHaircut.toStringAsFixed(0)}',
                    icon: Icons.trending_down,
                    valueColor: Colors.red,
                  ),
                const SizedBox(height: 8),
                if (scenario.recommendations.isNotEmpty) ...[
                  const Text('Recommendations:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ...scenario.recommendations.map((r) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(
                                child: Text(r,
                                    style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab 4: Insights
// =============================================================================

class _InsightsTab extends StatelessWidget {
  final RunwayAnalysis analysis;
  const _InsightsTab({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Alerts
        if (analysis.alerts.isNotEmpty) ...[
          Text('Alerts', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...analysis.alerts.map((a) => Card(
                color: a.severity == AlertSeverity.critical
                    ? Colors.red[50]
                    : a.severity == AlertSeverity.warning
                        ? Colors.orange[50]
                        : Colors.blue[50],
                child: ListTile(
                  leading: Text(a.severity.emoji,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(a.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.message),
                      const SizedBox(height: 4),
                      Text('💡 ${a.recommendation}',
                          style: const TextStyle(
                              fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                  isThreeLine: true,
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Recommendations
        if (analysis.recommendations.isNotEmpty) ...[
          Text('Recommendations',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...analysis.recommendations.map((r) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: r.priority == 'high'
                        ? Colors.red[100]
                        : r.priority == 'medium'
                            ? Colors.orange[100]
                            : Colors.green[100],
                    child: Icon(
                      Icons.tips_and_updates,
                      color: r.priority == 'high'
                          ? Colors.red
                          : r.priority == 'medium'
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
                  title: Text(r.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.description),
                      if (r.potentialSavingsPerMonth > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Save \$${r.potentialSavingsPerMonth.toStringAsFixed(0)}/mo → +${r.runwayExtensionMonths.toStringAsFixed(1)} months runway',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  isThreeLine: true,
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Trend
        if (analysis.history.length >= 2) ...[
          Text('Runway History', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...analysis.history.reversed.take(8).map((s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                '${s.date.month}/${s.date.day}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: (s.runwayMonths / 24).clamp(0, 1).toDouble(),
                                minHeight: 12,
                                borderRadius: BorderRadius.circular(6),
                                color: s.runwayMonths >= 12
                                    ? Colors.green
                                    : s.runwayMonths >= 6
                                        ? Colors.orange
                                        : Colors.red,
                                backgroundColor: Colors.grey[200],
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                '${s.runwayMonths.toStringAsFixed(1)}mo',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],

        // No insights
        if (analysis.alerts.isEmpty &&
            analysis.recommendations.isEmpty &&
            analysis.history.length < 2)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Add assets and expenses to get insights.'),
            ),
          ),
      ],
    );
  }
}
