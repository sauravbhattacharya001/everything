import 'package:flutter/material.dart';
import '../../core/services/budget_planner_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/budget_entry.dart';
import '../../models/expense_entry.dart';

/// Budget Planner — set monthly budgets per category, compare against
/// actual spending, use templates, and view insights.
/// 4-tab UI: Budget / Set / Compare / Insights.
class BudgetPlannerScreen extends StatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  State<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen>
    with SingleTickerProviderStateMixin, PersistentStateMixin {
  final BudgetPlannerService _service = BudgetPlannerService();
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  // Demo expense entries for comparison
  final List<ExpenseEntry> _demoEntries = [];

  @override
  String get storageKey => 'budget_planner_data';

  @override
  String exportData() => _service.exportToJson();

  @override
  void importData(String json) => _service.importFromJson(json);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    initPersistence().then((_) {
      if (_service.budgets.isEmpty) {
        _service.generateDemoData();
      }
      _generateDemoExpenses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateDemoExpenses() {
    final now = DateTime.now();
    int id = 0;
    String nextId() => 'demo_${id++}';

    // Current month expenses
    _demoEntries.addAll([
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 2), amount: 45.0, category: ExpenseCategory.food),
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 5), amount: 120.0, category: ExpenseCategory.food),
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 8), amount: 85.0, category: ExpenseCategory.food),
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 12), amount: 60.0, category: ExpenseCategory.food),
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 3), amount: 50.0, category: ExpenseCategory.transport),
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 10), amount: 80.0, category: ExpenseCategory.transport),
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 1), amount: 1200.0, category: ExpenseCategory.housing),
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 1), amount: 95.0, category: ExpenseCategory.utilities),
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 7), amount: 35.0, category: ExpenseCategory.entertainment),
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 14), amount: 75.0, category: ExpenseCategory.entertainment),
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 6), amount: 250.0, category: ExpenseCategory.shopping),
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 4), amount: 30.0, category: ExpenseCategory.health),
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 1), amount: 45.0, category: ExpenseCategory.subscriptions),
      ExpenseEntry(id: nextId(), timestamp: DateTime(now.year, now.month, 1), amount: 4000.0, category: ExpenseCategory.income),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planner'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Budget'),
            Tab(icon: Icon(Icons.edit_note), text: 'Set'),
            Tab(icon: Icon(Icons.compare_arrows), text: 'Compare'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BudgetTab(
            service: _service,
            entries: _demoEntries,
            year: _selectedYear,
            month: _selectedMonth,
            onMonthChanged: (y, m) => setState(() {
              _selectedYear = y;
              _selectedMonth = m;
            }),
          ),
          _SetTab(
            service: _service,
            year: _selectedYear,
            month: _selectedMonth,
            onChanged: () => setState(() {}),
          ),
          _CompareTab(
            service: _service,
            entries: _demoEntries,
            year: _selectedYear,
            month: _selectedMonth,
          ),
          _InsightsTab(
            service: _service,
            entries: _demoEntries,
            year: _selectedYear,
            month: _selectedMonth,
          ),
        ],
      ),
    );
  }
}

// ─── BUDGET TAB ──────────────────────────────────────────────────────────────

class _BudgetTab extends StatelessWidget {
  final BudgetPlannerService service;
  final List<ExpenseEntry> entries;
  final int year;
  final int month;
  final void Function(int year, int month) onMonthChanged;

  const _BudgetTab({
    required this.service,
    required this.entries,
    required this.year,
    required this.month,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = service.getBudget(year, month);
    final spending = service.getSpendingByCategory(entries, year, month);
    final totalSpent = spending.values.fold(0.0, (s, v) => s + v);
    final totalBudget = budget?.totalBudget ?? 0.0;
    final progress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 2.0) : 0.0;

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month picker
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final prev = month == 1 ? 12 : month - 1;
                  final prevY = month == 1 ? year - 1 : year;
                  onMonthChanged(prevY, prev);
                },
              ),
              Text(
                '${months[month - 1]} $year',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final next = month == 12 ? 1 : month + 1;
                  final nextY = month == 12 ? year + 1 : year;
                  onMonthChanged(nextY, next);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Circular total progress
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 12,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    color: progress > 1.0
                        ? Colors.red
                        : progress > 0.8
                            ? Colors.orange
                            : Colors.green,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text('spent', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Remaining summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(label: 'Budget', value: '\$${totalBudget.toStringAsFixed(0)}'),
                _SummaryItem(label: 'Spent', value: '\$${totalSpent.toStringAsFixed(0)}'),
                _SummaryItem(
                  label: 'Remaining',
                  value: '\$${(totalBudget - totalSpent).toStringAsFixed(0)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Per-category progress bars
          if (budget != null && budget.allocations.isNotEmpty) ...[
            Text('Category Breakdown',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...budget.allocations.map((allocation) {
              final spent = spending[allocation.category] ?? 0.0;
              final pct = allocation.budgetAmount > 0
                  ? spent / allocation.budgetAmount
                  : 0.0;
              final color = pct > 1.0
                  ? Colors.red
                  : pct > 0.8
                      ? Colors.orange
                      : Colors.green;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${allocation.category.emoji} ${allocation.category.label}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          '\$${spent.toStringAsFixed(0)} / \$${allocation.budgetAmount.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No budget set for this month',
                      style: theme.textTheme.titleMedium),
                  const Text('Go to "Set" tab to create a budget'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ─── SET TAB ────────────────────────────────────────────────────────────────

class _SetTab extends StatefulWidget {
  final BudgetPlannerService service;
  final int year;
  final int month;
  final VoidCallback onChanged;

  const _SetTab({
    required this.service,
    required this.year,
    required this.month,
    required this.onChanged,
  });

  @override
  State<_SetTab> createState() => _SetTabState();
}

class _SetTabState extends State<_SetTab> {
  final Map<ExpenseCategory, TextEditingController> _controllers = {};
  final _totalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant _SetTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      _initControllers();
    }
  }

  void _initControllers() {
    final budget = widget.service.getBudget(widget.year, widget.month);
    for (final cat in ExpenseCategory.values) {
      if (cat == ExpenseCategory.income) continue;
      _controllers[cat]?.dispose();
      final allocation = budget?.allocations
          .where((a) => a.category == cat)
          .toList();
      final amount = (allocation != null && allocation.isNotEmpty)
          ? allocation.first.budgetAmount
          : 0.0;
      _controllers[cat] = TextEditingController(
        text: amount > 0 ? amount.toStringAsFixed(0) : '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _totalController.dispose();
    super.dispose();
  }

  double get _currentTotal {
    double total = 0.0;
    for (final c in _controllers.values) {
      total += double.tryParse(c.text) ?? 0.0;
    }
    return total;
  }

  void _saveBudget() {
    final allocations = <BudgetAllocation>[];
    for (final entry in _controllers.entries) {
      final amount = double.tryParse(entry.value.text) ?? 0.0;
      if (amount > 0) {
        allocations.add(BudgetAllocation(
          id: '${entry.key.name}_${widget.year}_${widget.month}',
          category: entry.key,
          budgetAmount: amount,
        ));
      }
    }

    final existing = widget.service.getBudget(widget.year, widget.month);
    widget.service.setBudget(MonthlyBudget(
      id: existing?.id ?? '${widget.year}_${widget.month}',
      year: widget.year,
      month: widget.month,
      allocations: allocations,
      createdAt: existing?.createdAt ?? DateTime.now(),
    ));

    widget.onChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved!')),
      );
    }
  }

  void _applyEvenSplit() {
    final totalText = _totalController.text;
    final total = double.tryParse(totalText);
    if (total == null || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid total amount')),
      );
      return;
    }

    widget.service.createEvenSplit(widget.year, widget.month, total);
    _initControllers();
    setState(() {});
    widget.onChanged();
  }

  void _copyPrevious() {
    final result = widget.service.createFromPrevious(widget.year, widget.month);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous month budget found')),
      );
      return;
    }
    _initControllers();
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Set Budget — ${months[widget.month - 1]} ${widget.year}',
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),

          // Quick templates
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.content_copy, size: 18),
                  label: const Text('Copy Previous'),
                  onPressed: _copyPrevious,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _totalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Total',
                          prefixText: '\$',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.auto_fix_high),
                      tooltip: 'Even split',
                      onPressed: _applyEvenSplit,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Per-category fields
          ...ExpenseCategory.values
              .where((c) => c != ExpenseCategory.income)
              .map((cat) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _controllers[cat],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${cat.emoji} ${cat.label}',
                        prefixText: '\$',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  )),
          const SizedBox(height: 8),

          // Total display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Budget',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('\$${_currentTotal.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Save button
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Budget'),
            onPressed: _saveBudget,
          ),
        ],
      ),
    );
  }
}

// ─── COMPARE TAB ────────────────────────────────────────────────────────────

class _CompareTab extends StatelessWidget {
  final BudgetPlannerService service;
  final List<ExpenseEntry> entries;
  final int year;
  final int month;

  const _CompareTab({
    required this.service,
    required this.entries,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = service.getBudget(year, month);

    if (budget == null || budget.allocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No budget to compare',
                style: theme.textTheme.titleMedium),
            const Text('Set a budget first in the "Set" tab'),
          ],
        ),
      );
    }

    final comparisons = service.getBudgetComparison(budget, entries);
    final totalBudgeted = budget.totalBudget;
    final totalSpent =
        comparisons.fold(0.0, (sum, c) => sum + c.spent);
    final surplus = totalBudgeted - totalSpent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall surplus/deficit
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surplus >= 0
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surplus >= 0 ? 'Surplus' : 'Deficit',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: surplus >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${surplus.abs().toStringAsFixed(0)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: surplus >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  surplus >= 0
                      ? Icons.trending_down
                      : Icons.trending_up,
                  size: 48,
                  color: surplus >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Budget vs Actual',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Per-category comparison bars
          ...comparisons.map((c) {
            final maxVal =
                c.budgeted > c.spent ? c.budgeted : c.spent;
            final budgetWidth = maxVal > 0 ? c.budgeted / maxVal : 0.0;
            final spentWidth = maxVal > 0 ? c.spent / maxVal : 0.0;
            final isOver = c.spent > c.budgeted && c.budgeted > 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${c.category.emoji} ${c.category.label}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isOver
                            ? 'Over by \$${(c.spent - c.budgeted).toStringAsFixed(0)}'
                            : '\$${c.remaining.toStringAsFixed(0)} left',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOver ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Budget bar
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text('Budget',
                            style: theme.textTheme.labelSmall),
                      ),
                      Expanded(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: budgetWidth.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '\$${c.budgeted.toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Actual bar
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text('Actual',
                            style: theme.textTheme.labelSmall),
                      ),
                      Expanded(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: spentWidth.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isOver ? Colors.red : Colors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '\$${c.spent.toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── INSIGHTS TAB ───────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final BudgetPlannerService service;
  final List<ExpenseEntry> entries;
  final int year;
  final int month;

  const _InsightsTab({
    required this.service,
    required this.entries,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = service.getBudget(year, month);
    final adherenceScore = budget != null
        ? service.getBudgetAdherenceScore(budget, entries)
        : 0;
    final savingsRate = service.getSavingsRate(entries, year, month);
    final trend = service.getMonthlyTrend(entries, months: 6);
    final overspending = budget != null
        ? service.getOverspendingCategories(budget, entries)
        : <BudgetComparison>[];
    final recommendations = budget != null
        ? service.getRecommendations(budget, entries)
        : ['Set up a budget to get personalized recommendations.'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
            children: [
              _InsightCard(
                icon: Icons.speed,
                label: 'Adherence',
                value: '$adherenceScore/100',
                color: adherenceScore >= 80
                    ? Colors.green
                    : adherenceScore >= 50
                        ? Colors.orange
                        : Colors.red,
              ),
              _InsightCard(
                icon: Icons.savings,
                label: 'Savings Rate',
                value: '${(savingsRate * 100).round()}%',
                color: savingsRate >= 0.2
                    ? Colors.green
                    : savingsRate > 0
                        ? Colors.orange
                        : Colors.red,
              ),
              _InsightCard(
                icon: Icons.warning_amber,
                label: 'Over Budget',
                value: '${overspending.length}',
                color: overspending.isEmpty ? Colors.green : Colors.red,
              ),
              _InsightCard(
                icon: Icons.category,
                label: 'Categories',
                value: '${budget?.allocations.length ?? 0}',
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recommendations
          for (final rec in recommendations)
            Card(
              color: theme.colorScheme.secondaryContainer,
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(rec, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 6-month trend
          Text('6-Month Trend',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (trend.isNotEmpty)
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trend.map((point) {
                  final maxVal = trend
                      .map((p) => p.budgeted > p.actual ? p.budgeted : p.actual)
                      .reduce((a, b) => a > b ? a : b);
                  final budgetHeight =
                      maxVal > 0 ? (point.budgeted / maxVal * 100) : 0.0;
                  final actualHeight =
                      maxVal > 0 ? (point.actual / maxVal * 100) : 0.0;
                  final months = [
                    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                  ];

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Budget bar
                              Container(
                                width: 12,
                                height: budgetHeight,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 2),
                              // Actual bar
                              Container(
                                width: 12,
                                height: actualHeight,
                                decoration: BoxDecoration(
                                  color: actualHeight > budgetHeight
                                      ? Colors.red
                                      : Colors.green,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            months[point.month - 1],
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // Legend
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text('Budget', style: theme.textTheme.labelSmall),
                const SizedBox(width: 12),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text('Actual', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Over-budget categories
          if (overspending.isNotEmpty) ...[
            Text('Over Budget Categories',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...overspending.map((c) => Card(
                  color: Colors.red.withOpacity(0.1),
                  child: ListTile(
                    leading: Text(c.category.emoji,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(c.category.label),
                    subtitle: Text(
                      'Over by \$${(c.spent - c.budgeted).toStringAsFixed(0)} (${(c.percentUsed * 100).round()}% used)',
                    ),
                    trailing: Text(
                      '\$${c.spent.toStringAsFixed(0)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
