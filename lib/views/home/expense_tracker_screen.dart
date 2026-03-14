import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/expense_tracker_service.dart';
import '../../models/expense_entry.dart';

/// Expense Tracker screen — log expenses/income, view history,
/// and see monthly budget summary with category breakdowns.
class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'expense_tracker_data';
  final ExpenseTrackerService _service = ExpenseTrackerService();
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null && json.isNotEmpty) {
      try {
        _service.importFromJson(json);
        setState(() {});
      } catch (_) {}
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _service.exportToJson());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Log'),
            Tab(icon: Icon(Icons.receipt_long), text: 'History'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LogTab(service: _service, onAdded: () { setState(() {}); _saveData(); }),
          _HistoryTab(service: _service, onChanged: () { setState(() {}); _saveData(); }),
          _SummaryTab(
            service: _service,
            year: _selectedYear,
            month: _selectedMonth,
            onMonthChanged: (y, m) => setState(() {
              _selectedYear = y;
              _selectedMonth = m;
            }),
          ),
        ],
      ),
    );
  }
}

// ─── LOG TAB ────────────────────────────────────────────────────────────────

class _LogTab extends StatefulWidget {
  final ExpenseTrackerService service;
  final VoidCallback onAdded;

  const _LogTab({required this.service, required this.onAdded});

  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _vendorController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.food;
  PaymentMethod _paymentMethod = PaymentMethod.debit;
  bool _isRecurring = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final entry = ExpenseEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      amount: amount,
      category: _category,
      paymentMethod: _paymentMethod,
      description: _descController.text.isEmpty ? null : _descController.text,
      vendor: _vendorController.text.isEmpty ? null : _vendorController.text,
      isRecurring: _isRecurring,
    );

    widget.service.addEntry(entry);
    _amountController.clear();
    _descController.clear();
    _vendorController.clear();
    setState(() {
      _isRecurring = false;
    });
    widget.onAdded();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_category.emoji} \$${amount.toStringAsFixed(2)} logged'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick Stats Banner
            _QuickStatsBanner(service: widget.service),
            const SizedBox(height: 24),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              style: theme.textTheme.headlineSmall,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                if (double.tryParse(v) == null) return 'Invalid number';
                if (double.parse(v) <= 0) return 'Must be positive';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Selector
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.values.map((cat) {
                final selected = cat == _category;
                return ChoiceChip(
                  label: Text('${cat.emoji} ${cat.label}'),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: theme.colorScheme.primaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Payment Method
            DropdownButtonFormField<PaymentMethod>(
              value: _paymentMethod,
              decoration: InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              items: PaymentMethod.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                  .toList(),
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            const SizedBox(height: 16),

            // Vendor
            TextFormField(
              controller: _vendorController,
              decoration: InputDecoration(
                labelText: 'Vendor / Store (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                prefixIcon: const Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                prefixIcon: const Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Recurring toggle
            SwitchListTile(
              title: const Text('Recurring expense'),
              subtitle: const Text('Mark as repeating monthly'),
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
              secondary: const Icon(Icons.repeat),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add),
              label: const Text('Log Expense'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── QUICK STATS BANNER ────────────────────────────────────────────────────

class _QuickStatsBanner extends StatelessWidget {
  final ExpenseTrackerService service;

  const _QuickStatsBanner({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final report = service.getMonthlyReport(now.year, now.month);
    final streak = service.getLoggingStreak();

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatColumn(
              label: 'Today',
              value: '\$${service.getDailySummary(now).totalSpent.toStringAsFixed(0)}',
              icon: Icons.today,
            ),
            _StatColumn(
              label: 'This Month',
              value: '\$${report.totalSpent.toStringAsFixed(0)}',
              icon: Icons.calendar_month,
            ),
            _StatColumn(
              label: 'Budget Left',
              value: '\$${report.remainingBudget.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet,
              color: report.remainingBudget < 0 ? Colors.red : null,
            ),
            _StatColumn(
              label: 'Streak',
              value: '$streak days',
              icon: Icons.local_fire_department,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color ?? theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

// ─── HISTORY TAB ────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final ExpenseTrackerService service;
  final VoidCallback onChanged;

  const _HistoryTab({required this.service, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = List<ExpenseEntry>.from(service.entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No expenses logged yet',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text('Switch to the Log tab to add your first expense',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<ExpenseEntry>>{};
    for (final e in entries) {
      final key = '${e.timestamp.year}-${e.timestamp.month.toString().padLeft(2, '0')}-${e.timestamp.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(e);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dayEntries = grouped[dateKey]!;
        final dayTotal = dayEntries
            .where((e) => !e.category.isIncome)
            .fold<double>(0, (s, e) => s + e.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateKey,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  Text('\$${dayTotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          )),
                ],
              ),
            ),
            ...dayEntries.map((entry) => Dismissible(
                  key: ValueKey(entry.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    service.removeEntry(entry.id);
                    onChanged();
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(entry.category.emoji),
                    ),
                    title: Text(
                      entry.description ?? entry.category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        entry.vendor,
                        entry.paymentMethod.label,
                        if (entry.isRecurring) '🔄 Recurring',
                      ].whereType<String>().join(' · '),
                      maxLines: 1,
                    ),
                    trailing: Text(
                      '${entry.category.isIncome ? '+' : '-'}\$${entry.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: entry.category.isIncome
                            ? Colors.green
                            : null,
                      ),
                    ),
                  ),
                )),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}

// ─── SUMMARY TAB ────────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  final ExpenseTrackerService service;
  final int year;
  final int month;
  final void Function(int year, int month) onMonthChanged;

  const _SummaryTab({
    required this.service,
    required this.year,
    required this.month,
    required this.onMonthChanged,
  });

  static const _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  void _prevMonth() {
    if (month == 1) {
      onMonthChanged(year - 1, 12);
    } else {
      onMonthChanged(year, month - 1);
    }
  }

  void _nextMonth() {
    if (month == 12) {
      onMonthChanged(year + 1, 1);
    } else {
      onMonthChanged(year, month + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = service.getMonthlyReport(year, month);
    final percentages = service.getCategoryPercentages(
      service.getEntriesForMonth(year, month),
    );
    final trend = service.getSpendingTrend();
    final insights = service.generateInsights(year, month);
    final topVendors = service.getTopVendors(limit: 5);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _prevMonth,
              ),
              Text(
                '${_monthNames[month]} $year',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Budget Overview Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Budget', style: theme.textTheme.titleMedium),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _gradeColor(report.budgetGrade),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Grade: ${report.budgetGrade}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (report.budgetUsedPercent / 100).clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: report.budgetUsedPercent > 100
                          ? Colors.red
                          : report.budgetUsedPercent > 80
                              ? Colors.orange
                              : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${report.totalSpent.toStringAsFixed(2)} spent',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '\$${report.budget.toStringAsFixed(2)} budget',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MiniStat(
                        label: 'Income',
                        value: '\$${report.totalIncome.toStringAsFixed(0)}',
                        color: Colors.green,
                      ),
                      _MiniStat(
                        label: 'Avg/Day',
                        value: '\$${report.averageDailySpend.toStringAsFixed(0)}',
                      ),
                      _MiniStat(
                        label: 'Projected',
                        value: '\$${report.projectedMonthlySpend.toStringAsFixed(0)}',
                        color: report.projectedMonthlySpend > report.budget
                            ? Colors.red
                            : null,
                      ),
                      _MiniStat(
                        label: 'Savings',
                        value: '${report.savingsRate.toStringAsFixed(0)}%',
                        color: report.savingsRate >= 20
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Alerts
          if (report.alerts.isNotEmpty) ...[
            ...report.alerts.map((alert) => Card(
                  color: alert.severity == 'critical'
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      alert.severity == 'critical'
                          ? Icons.error
                          : Icons.warning,
                      color: alert.severity == 'critical'
                          ? Colors.red
                          : Colors.orange,
                    ),
                    title: Text(alert.message),
                    subtitle: Text(
                      '${alert.percentUsed.toStringAsFixed(0)}% of limit',
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Category Breakdown
          if (percentages.isNotEmpty) ...[
            Text('Category Breakdown',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._buildCategoryBars(context, percentages, report),
            const SizedBox(height: 16),
          ],

          // Spending Trend
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        trend.direction == 'increasing'
                            ? Icons.trending_up
                            : trend.direction == 'decreasing'
                                ? Icons.trending_down
                                : Icons.trending_flat,
                        color: trend.direction == 'increasing'
                            ? Colors.red
                            : trend.direction == 'decreasing'
                                ? Colors.green
                                : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Trend: ${trend.direction}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (trend.weeklyTotals.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        trend.weeklyTotals.length,
                        (i) => Column(
                          children: [
                            Text(
                              '\$${trend.weeklyTotals[i].toStringAsFixed(0)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Wk ${i + 1}',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Top Vendors
          if (topVendors.isNotEmpty) ...[
            Text('Top Vendors',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...topVendors.map((v) => ListTile(
                  leading: CircleAvatar(
                    child: Text(v.primaryCategory.emoji),
                  ),
                  title: Text(v.vendor),
                  subtitle: Text(
                    '${v.transactionCount} transactions · avg \$${v.averageTransaction.toStringAsFixed(2)}',
                  ),
                  trailing: Text(
                    '\$${v.totalSpent.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Insights
          if (insights.isNotEmpty) ...[
            Text('Insights',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...insights.map((i) => Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(i, style: theme.textTheme.bodyMedium),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCategoryBars(
    BuildContext context,
    Map<ExpenseCategory, double> percentages,
    MonthlyReport report,
  ) {
    final sorted = percentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final theme = Theme.of(context);

    return sorted.map((entry) {
      final spent = report.byCategory[entry.key] ?? 0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 32, child: Text(entry.key.emoji)),
            Expanded(
              flex: 3,
              child: Text(entry.key.label, style: theme.textTheme.bodySmall),
            ),
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: entry.value / 100,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: Text(
                '\$${spent.toStringAsFixed(0)} (${entry.value.toStringAsFixed(0)}%)',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }
}

// ─── MINI STAT ──────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MiniStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
