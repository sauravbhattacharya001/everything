import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/savings_goal_service.dart';
import '../../models/savings_goal.dart';

/// Savings Goal Tracker — set goals, log contributions, track progress,
/// and view projections. 4-tab UI: Goals / Add / Progress / Insights.
class SavingsGoalScreen extends StatefulWidget {
  const SavingsGoalScreen({super.key});

  @override
  State<SavingsGoalScreen> createState() => _SavingsGoalScreenState();
}

class _SavingsGoalScreenState extends State<SavingsGoalScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'savings_goal_data';
  final SavingsGoalService _service = SavingsGoalService();
  late TabController _tabController;
  SavingsGoalCategory? _filterCategory;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null && json.isNotEmpty) {
      try {
        _service.importJson(json);
        if (mounted) setState(() {});
      } catch (_) {}
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _service.exportJson());
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
        title: const Text('Savings Goals'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.savings), text: 'Goals'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Add'),
            Tab(icon: Icon(Icons.trending_up), text: 'Progress'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GoalsTab(
            service: _service,
            filterCategory: _filterCategory,
            showArchived: _showArchived,
            onFilterChanged: (cat) => setState(() => _filterCategory = cat),
            onToggleArchived: () =>
                setState(() => _showArchived = !_showArchived),
            onChanged: () => setState(() {}),
          ),
          _AddTab(service: _service, onAdded: () {
            setState(() {});
            _tabController.animateTo(0);
          }),
          _ProgressTab(service: _service),
          _InsightsTab(service: _service),
        ],
      ),
    );
    _saveData();
  }
}

// ─── GOALS TAB ──────────────────────────────────────────────────────────────

class _GoalsTab extends StatelessWidget {
  final SavingsGoalService service;
  final SavingsGoalCategory? filterCategory;
  final bool showArchived;
  final ValueChanged<SavingsGoalCategory?> onFilterChanged;
  final VoidCallback onToggleArchived;
  final VoidCallback onChanged;

  const _GoalsTab({
    required this.service,
    required this.filterCategory,
    required this.showArchived,
    required this.onFilterChanged,
    required this.onToggleArchived,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    var goals = showArchived ? service.archivedGoals : service.activeGoals;
    if (filterCategory != null) {
      goals = goals.where((g) => g.category == filterCategory).toList();
    }

    return Column(
      children: [
        // Filter row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: filterCategory == null,
                        onSelected: (_) => onFilterChanged(null),
                      ),
                      const SizedBox(width: 6),
                      ...SavingsGoalCategory.values.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text('${cat.emoji} ${cat.label}'),
                              selected: filterCategory == cat,
                              onSelected: (_) => onFilterChanged(
                                  filterCategory == cat ? null : cat),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(showArchived
                    ? Icons.unarchive
                    : Icons.archive_outlined),
                tooltip: showArchived ? 'Show active' : 'Show archived',
                onPressed: onToggleArchived,
              ),
            ],
          ),
        ),

        // Summary strip
        if (!showArchived && service.activeGoals.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Saved',
                  value: '\$${service.totalSaved.toStringAsFixed(0)}',
                ),
                _SummaryItem(
                  label: 'Target',
                  value: '\$${service.totalTarget.toStringAsFixed(0)}',
                ),
                _SummaryItem(
                  label: 'Progress',
                  value: '${(service.overallProgress * 100).round()}%',
                ),
              ],
            ),
          ),

        // Goals list
        Expanded(
          child: goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.savings_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        showArchived
                            ? 'No archived goals'
                            : 'No savings goals yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (!showArchived)
                        const Text('Tap "Add" to create your first goal'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: goals.length,
                  itemBuilder: (context, i) => _GoalCard(
                    goal: goals[i],
                    service: service,
                    onChanged: onChanged,
                  ),
                ),
        ),
      ],
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

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final SavingsGoalService service;
  final VoidCallback onChanged;

  const _GoalCard({
    required this.goal,
    required this.service,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = goal.isComplete
        ? Colors.green
        : (goal.isOnTrack == false ? Colors.orange : theme.colorScheme.primary);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(goal.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '${goal.category.label} • ${goal.priority.label} priority',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (goal.isComplete)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'contribute':
                        _showContributeDialog(context);
                        break;
                      case 'archive':
                        service.toggleArchive(goal.id);
                        onChanged();
                        break;
                      case 'delete':
                        service.removeGoal(goal.id);
                        onChanged();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'contribute',
                      child: Text('Add contribution'),
                    ),
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(goal.isArchived ? 'Unarchive' : 'Archive'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.progressPercent,
                minHeight: 8,
                backgroundColor: progressColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),

            const SizedBox(height: 8),

            // Amount row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${goal.savedAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(goal.progressPercent * 100).round()}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Deadline/projection info
            if (goal.deadline != null || goal.projectedCompletionDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    if (goal.deadline != null) ...[
                      Icon(Icons.calendar_today,
                          size: 14, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${_formatDate(goal.deadline!)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (goal.daysRemaining != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          goal.daysRemaining! >= 0
                              ? '(${goal.daysRemaining}d left)'
                              : '(${-goal.daysRemaining!}d overdue)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: goal.isOnTrack == false
                                ? Colors.orange
                                : null,
                          ),
                        ),
                      ],
                    ],
                    const Spacer(),
                    if (!goal.isComplete &&
                        goal.projectedCompletionDate != null)
                      Text(
                        'ETA: ${_formatDate(goal.projectedCompletionDate!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),

            // Recent contributions
            if (goal.contributions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Recent:',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline)),
              ...goal.contributions
                  .reversed
                  .take(3)
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Text(
                              '+\$${c.amount.toStringAsFixed(0)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(c.date),
                              style: theme.textTheme.bodySmall,
                            ),
                            if (c.note != null) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  c.note!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.outline),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )),
            ],
          ],
        ),
      ),
    );
  }

  void _showContributeDialog(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to "${goal.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                service.addContribution(
                  goal.id,
                  amount: amount,
                  note: noteController.text.isEmpty
                      ? null
                      : noteController.text,
                );
                onChanged();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

// ─── ADD TAB ────────────────────────────────────────────────────────────────

class _AddTab extends StatefulWidget {
  final SavingsGoalService service;
  final VoidCallback onAdded;

  const _AddTab({required this.service, required this.onAdded});

  @override
  State<_AddTab> createState() => _AddTabState();
}

class _AddTabState extends State<_AddTab> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  SavingsGoalCategory _category = SavingsGoalCategory.general;
  SavingsGoalPriority _priority = SavingsGoalPriority.medium;
  DateTime? _deadline;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create Savings Goal',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),

          // Name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Goal Name',
              hintText: 'e.g., Emergency Fund',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 16),

          // Target amount
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Target Amount',
              hintText: 'e.g., 5000',
              border: OutlineInputBorder(),
              prefixText: '\$',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 16),

          // Category
          DropdownButtonFormField<SavingsGoalCategory>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: SavingsGoalCategory.values.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text('${cat.emoji} ${cat.label}'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _category = val);
              _saveData();
            },
          ),
          const SizedBox(height: 16),

          // Priority
          DropdownButtonFormField<SavingsGoalPriority>(
            value: _priority,
            decoration: const InputDecoration(
              labelText: 'Priority',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            items: SavingsGoalPriority.values.map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(p.label),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _priority = val);
              _saveData();
            },
          ),
          const SizedBox(height: 16),

          // Deadline
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(_deadline != null
                ? 'Deadline: ${_deadline!.month}/${_deadline!.day}/${_deadline!.year}'
                : 'Set deadline (optional)'),
            trailing: _deadline != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _deadline = null),
                  )
                : null,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            tileColor: Theme.of(context).colorScheme.surfaceVariant,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    _deadline ?? DateTime.now().add(const Duration(days: 90)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (date != null) setState(() => _deadline = date);
              _saveData();
            },
          ),
          const SizedBox(height: 24),

          // Submit
          FilledButton.icon(
            icon: const Icon(Icons.savings),
            label: const Text('Create Goal'),
            onPressed: () {
              final name = _nameController.text.trim();
              final amount = double.tryParse(_amountController.text);

              if (name.isEmpty || amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a name and valid amount')),
                );
                return;
              }

              widget.service.addGoal(
                name: name,
                targetAmount: amount,
                category: _category,
                priority: _priority,
                deadline: _deadline,
              );

              _nameController.clear();
              _amountController.clear();
              setState(() {
                _category = SavingsGoalCategory.general;
                _priority = SavingsGoalPriority.medium;
                _deadline = null;
              });
              _saveData();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Goal "$name" created!')),
              );
              widget.onAdded();
            },
          ),
        ],
      ),
    );
  }
}

// ─── PROGRESS TAB ───────────────────────────────────────────────────────────

class _ProgressTab extends StatelessWidget {
  final SavingsGoalService service;

  const _ProgressTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goals = service.prioritized;
    final history = service.savingsHistory(months: 6);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall progress ring
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: service.overallProgress,
                    strokeWidth: 12,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    color: theme.colorScheme.primary,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(service.overallProgress * 100).round()}%',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text('Overall',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Monthly savings chart
          Text('Monthly Savings',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (history.isNotEmpty)
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: history.map((point) {
                  final maxAmount = history
                      .map((p) => p.amount)
                      .reduce((a, b) => a > b ? a : b);
                  final height =
                      maxAmount > 0 ? (point.amount / maxAmount * 100) : 0.0;
                  final months = [
                    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                  ];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '\$${point.amount.toStringAsFixed(0)}',
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
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
          const SizedBox(height: 24),

          // Per-goal progress bars
          Text('Goal Progress',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...goals
              .where((g) => !g.isComplete)
              .map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${g.emoji} ${g.name}',
                                style: theme.textTheme.bodyMedium),
                            Text(
                              '${(g.progressPercent * 100).round()}%',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: g.progressPercent,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  )),

          // Category breakdown
          if (service.categoryBreakdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('By Category',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...service.categoryBreakdown.entries.map((entry) {
              final cat = entry.value;
              return ListTile(
                leading: Text(entry.key.emoji,
                    style: const TextStyle(fontSize: 24)),
                title: Text(entry.key.label),
                subtitle: LinearProgressIndicator(value: cat.progress),
                trailing: Text(
                  '\$${cat.totalSaved.toStringAsFixed(0)}/\$${cat.totalTarget.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─── INSIGHTS TAB ───────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final SavingsGoalService service;

  const _InsightsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insights = service.insights;
    final behind = service.behindSchedule;

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
                icon: Icons.flag,
                label: 'Active Goals',
                value: '${insights.activeGoalCount}',
                color: theme.colorScheme.primary,
              ),
              _InsightCard(
                icon: Icons.check_circle,
                label: 'Completed',
                value: '${insights.completedGoalCount}',
                color: Colors.green,
              ),
              _InsightCard(
                icon: Icons.savings,
                label: 'Total Saved',
                value: '\$${insights.totalSaved.toStringAsFixed(0)}',
                color: Colors.teal,
              ),
              _InsightCard(
                icon: Icons.trending_up,
                label: 'Avg Monthly',
                value: '\$${insights.avgMonthlySavings.toStringAsFixed(0)}',
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recommendation
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insights.recommendation,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Behind schedule warnings
          if (behind.isNotEmpty) ...[
            Text('⚠️ Behind Schedule',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...behind.map((g) {
              final needed = g.remainingAmount;
              final daysLeft = g.daysRemaining ?? 0;
              final perDay = daysLeft > 0 ? needed / daysLeft : needed;
              return Card(
                color: Colors.orange.withOpacity(0.1),
                child: ListTile(
                  leading: Text(g.emoji,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(g.name),
                  subtitle: Text(
                    daysLeft > 0
                        ? 'Need \$${perDay.toStringAsFixed(0)}/day for ${daysLeft}d'
                        : 'Deadline passed — \$${needed.toStringAsFixed(0)} remaining',
                  ),
                  trailing: Text(
                    '${(g.progressPercent * 100).round()}%',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              );
            }),
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
