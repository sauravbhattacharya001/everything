import 'package:flutter/material.dart';
import '../../core/services/attention_debt_service.dart';

/// Attention Debt Tracker screen — autonomous cognitive overhead monitor.
/// Visualizes deferred decisions, postponed tasks, and accumulated mental load
/// with compound interest modeling and sprint-based debt reduction planning.
class AttentionDebtScreen extends StatefulWidget {
  const AttentionDebtScreen({super.key});

  @override
  State<AttentionDebtScreen> createState() => _AttentionDebtScreenState();
}

class _AttentionDebtScreenState extends State<AttentionDebtScreen>
    with SingleTickerProviderStateMixin {
  final AttentionDebtService _service = AttentionDebtService();
  late TabController _tabController;
  DebtSprint? _activeSprint;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _service.loadSampleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = _service.getPortfolio();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attention Debt Tracker'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Portfolio'),
            Tab(icon: Icon(Icons.list_alt), text: 'Debt Items'),
            Tab(icon: Icon(Icons.bolt), text: 'Sprints'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Amortization'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPortfolioTab(portfolio, theme),
          _buildItemsTab(theme),
          _buildSprintsTab(theme),
          _buildAmortizationTab(portfolio, theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Debt'),
      ),
    );
  }

  // ── Portfolio Tab ──

  Widget _buildPortfolioTab(DebtPortfolio portfolio, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Debt Score Gauge
          _buildDebtScoreCard(portfolio, theme),
          const SizedBox(height: 16),

          // Autonomous Insight
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text('Autonomous Insight',
                          style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(portfolio.autonomousInsight,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'Open Items', '${portfolio.openItems}', '📋', theme),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Total Debt',
                    portfolio.totalDebt.toStringAsFixed(0), '💰', theme),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                    'Interest',
                    portfolio.totalInterestAccrued.toStringAsFixed(0),
                    '📈',
                    theme),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Breakdown
          Text('Debt by Category',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...portfolio.debtByCategory.entries.map((entry) {
            final maxDebt = portfolio.debtByCategory.values
                .fold(0.0, (a, b) => a > b ? a : b);
            final fraction = maxDebt > 0 ? entry.value / maxDebt : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.key.emoji),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.key.label)),
                      Text(entry.value.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Top Offenders
          Text('🔥 Top Offenders', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...portfolio.topOffenders.map((item) => Card(
                child: ListTile(
                  leading: Text(item.category.emoji,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(item.title),
                  subtitle: Text(
                      'Cost: ${item.effectiveCost.toStringAsFixed(1)} · '
                      '${item.daysOpen}d open · '
                      '${item.urgency.emoji} ${item.urgency.label}'),
                  trailing: Text(
                      '+${item.accruedInterest.toStringAsFixed(1)}',
                      style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDebtScoreCard(DebtPortfolio portfolio, ThemeData theme) {
    final urgencyColor =
        Color(int.parse(portfolio.overallUrgency.colorHex.replaceFirst('#', '0xFF')));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Attention Debt Score',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: portfolio.debtScore / 100,
                    strokeWidth: 12,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: urgencyColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(portfolio.debtScore.toStringAsFixed(0),
                        style: theme.textTheme.headlineLarge?.copyWith(
                            color: urgencyColor, fontWeight: FontWeight.bold)),
                    Text('/100', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Chip(
              avatar: Text(portfolio.overallUrgency.emoji),
              label: Text(portfolio.overallUrgency.label),
              backgroundColor: urgencyColor.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, String emoji, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  // ── Items Tab ──

  Widget _buildItemsTab(ThemeData theme) {
    final open = _service.openItems.toList()
      ..sort((a, b) => b.effectiveCost.compareTo(a.effectiveCost));
    final resolved = _service.resolvedItems;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Open Debt (${open.length})',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...open.map((item) => _buildDebtItemCard(item, theme)),
        if (resolved.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Resolved (${resolved.length})',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 8),
          ...resolved.take(5).map((item) => _buildDebtItemCard(item, theme,
              resolved: true)),
        ],
      ],
    );
  }

  Widget _buildDebtItemCard(AttentionDebtItem item, ThemeData theme,
      {bool resolved = false}) {
    return Card(
      color: resolved ? theme.colorScheme.surfaceContainerHighest : null,
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.category.emoji, style: const TextStyle(fontSize: 20)),
            Text(item.urgency.emoji, style: const TextStyle(fontSize: 12)),
          ],
        ),
        title: Text(item.title,
            style: resolved
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.category.label} · ${item.daysOpen}d open'),
            Row(
              children: [
                Text('Base: ${item.baseCost}',
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 8),
                Text('Now: ${item.effectiveCost.toStringAsFixed(1)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold)),
                if (item.timesPostponed > 0) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('⏭️ ×${item.timesPostponed}'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: resolved
            ? const Icon(Icons.check_circle, color: Colors.green)
            : PopupMenuButton<String>(
                onSelected: (action) {
                  setState(() {
                    if (action == 'resolve') {
                      _service.resolveItem(item.id);
                    } else if (action == 'postpone') {
                      _service.postponeItem(item.id);
                    } else if (action == 'delete') {
                      _service.removeItem(item.id);
                    }
                  });
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'resolve', child: Text('✅ Resolve')),
                  const PopupMenuItem(
                      value: 'postpone', child: Text('⏭️ Postpone (+20%)')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('🗑️ Delete')),
                ],
              ),
      ),
    );
  }

  // ── Sprints Tab ──

  Widget _buildSprintsTab(ThemeData theme) {
    final recommended = _service.recommendedSprintType;
    final plannedItems = _service.planSprintItems(recommended);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sprint Recommendation
        Card(
          color: theme.colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recommended Sprint',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer)),
                const SizedBox(height: 8),
                Text(recommended.label,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${plannedItems.length} items · '
                    '${recommended.durationMinutes} minutes'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _activeSprint == null
                      ? () {
                          setState(() {
                            _activeSprint = _service.startSprint(recommended);
                          });
                        }
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_activeSprint == null
                      ? 'Start Sprint'
                      : 'Sprint In Progress'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Active Sprint
        if (_activeSprint != null) ...[
          Text('⚡ Active Sprint', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_activeSprint!.type.label,
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...(_activeSprint!.targetItemIds.map((id) {
                    final item =
                        _service.items.where((i) => i.id == id).firstOrNull;
                    if (item == null) return const SizedBox.shrink();
                    return CheckboxListTile(
                      title: Text(item.title),
                      subtitle: Text(item.category.label),
                      value: item.isResolved,
                      onChanged: (checked) {
                        if (checked == true) {
                          setState(() => _service.resolveItem(item.id));
                        }
                      },
                    );
                  })),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        final resolved = _activeSprint!.targetItemIds
                            .where((id) => _service.items
                                .where((i) => i.id == id && i.isResolved)
                                .isNotEmpty)
                            .toList();
                        _service.completeSprint(
                            _activeSprint!.id, resolved);
                        _activeSprint = null;
                      });
                    },
                    child: const Text('Complete Sprint'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Sprint History
        Text('Sprint History (${_service.sprints.length})',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._service.sprints
            .where((s) => s.isComplete)
            .map((sprint) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(sprint.type.label),
                    subtitle: Text(
                        'Resolved ${sprint.resolvedItemIds.length}/'
                        '${sprint.targetItemIds.length} items · '
                        'Reduced ${sprint.debtReduced.toStringAsFixed(0)} debt'),
                    trailing: Text(
                        '${(sprint.efficiency * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.green)),
                  ),
                )),
        if (_service.sprints.where((s) => s.isComplete).isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No completed sprints yet. Start one above!'),
          )),
      ],
    );
  }

  // ── Amortization Tab ──

  Widget _buildAmortizationTab(DebtPortfolio portfolio, ThemeData theme) {
    final plan = portfolio.amortizationPlan;
    if (plan.isEmpty) {
      return const Center(child: Text('🎉 No debt to amortize!'));
    }

    final totalReduction =
        plan.fold(0.0, (sum, e) => sum + e.expectedReduction);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('14-Day Debt Freedom Plan',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                    'Clear all ${portfolio.openItems} items over ${plan.length} days'),
                Text(
                    'Expected total reduction: ${totalReduction.toStringAsFixed(0)} cognitive units'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...plan.asMap().entries.map((entry) {
          final idx = entry.key;
          final step = entry.value;
          final items = step.itemIds
              .map((id) => _service.items.where((i) => i.id == id).firstOrNull)
              .whereType<AttentionDebtItem>()
              .toList();

          return Card(
            child: ExpansionTile(
              leading: CircleAvatar(child: Text('D${idx + 1}')),
              title: Text(step.recommendedSprint.label),
              subtitle: Text(
                  '${items.length} items · '
                  '-${step.expectedReduction.toStringAsFixed(0)} debt'),
              children: items
                  .map((item) => ListTile(
                        dense: true,
                        leading: Text(item.category.emoji),
                        title: Text(item.title),
                        trailing: Text(
                            item.effectiveCost.toStringAsFixed(1),
                            style: TextStyle(color: theme.colorScheme.error)),
                      ))
                  .toList(),
            ),
          );
        }),
      ],
    );
  }

  // ── Add Item Dialog ──

  void _showAddItemDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    var selectedCategory = AttentionDebtCategory.deferredDecision;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Attention Debt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(labelText: 'What\'s weighing on you?'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration:
                      const InputDecoration(labelText: 'Details (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AttentionDebtCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AttentionDebtCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.emoji} ${c.label}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedCategory = v);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                setState(() {
                  _service.addItem(AttentionDebtItem(
                    id: 'debt_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleController.text.trim(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    category: selectedCategory,
                    createdAt: DateTime.now(),
                    baseCost: selectedCategory.baseCost,
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
