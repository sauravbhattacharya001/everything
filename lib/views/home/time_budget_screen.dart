import 'package:flutter/material.dart';
import '../../core/services/time_budget_service.dart';
import '../../models/event_model.dart';
import '../../models/event_tag.dart';

/// Time Budget Screen — track weekly hour budgets per category, compare
/// planned vs actual time allocation, and get insights.
/// 4-tab UI: Budget / Set / Compare / Insights.
class TimeBudgetScreen extends StatefulWidget {
  const TimeBudgetScreen({super.key});

  @override
  State<TimeBudgetScreen> createState() => _TimeBudgetScreenState();
}

class _TimeBudgetScreenState extends State<TimeBudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Budget targets managed in-screen
  final List<TimeBudget> _budgets = [];

  // Demo events
  late final List<EventModel> _demoEvents;

  // Current report
  TimeBudgetReport? _report;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _generateDemoData();
    _rebuildReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateDemoData() {
    final now = DateTime.now();
    final events = <EventModel>[];
    int id = 0;
    String nextId() => 'tb_${id++}';

    // Work events — heavily scheduled
    for (int d = 0; d < 14; d++) {
      final day = now.subtract(Duration(days: d));
      if (day.weekday <= 5) {
        // Weekday work
        events.add(EventModel(
          id: nextId(),
          title: 'Morning Work Block',
          date: DateTime(day.year, day.month, day.day, 9, 0),
          endDate: DateTime(day.year, day.month, day.day, 12, 0),
          priority: EventPriority.high,
          tags: [const EventTag(name: 'Work', colorIndex: 0)],
        ));
        events.add(EventModel(
          id: nextId(),
          title: 'Afternoon Work',
          date: DateTime(day.year, day.month, day.day, 13, 0),
          endDate: DateTime(day.year, day.month, day.day, 17, 0),
          priority: EventPriority.high,
          tags: [const EventTag(name: 'Work', colorIndex: 0)],
        ));
      }
    }

    // Personal events
    for (int d = 0; d < 14; d += 2) {
      final day = now.subtract(Duration(days: d));
      events.add(EventModel(
        id: nextId(),
        title: 'Personal Time',
        date: DateTime(day.year, day.month, day.day, 18, 0),
        endDate: DateTime(day.year, day.month, day.day, 19, 30),
        priority: EventPriority.medium,
        tags: [const EventTag(name: 'Personal', colorIndex: 1)],
      ));
    }

    // Health events
    for (int d = 0; d < 14; d += 2) {
      final day = now.subtract(Duration(days: d));
      events.add(EventModel(
        id: nextId(),
        title: 'Workout',
        date: DateTime(day.year, day.month, day.day, 6, 0),
        endDate: DateTime(day.year, day.month, day.day, 7, 0),
        priority: EventPriority.medium,
        tags: [const EventTag(name: 'Health', colorIndex: 4)],
      ));
    }

    // Learning events
    for (int d = 1; d < 14; d += 3) {
      final day = now.subtract(Duration(days: d));
      events.add(EventModel(
        id: nextId(),
        title: 'Study Session',
        date: DateTime(day.year, day.month, day.day, 20, 0),
        endDate: DateTime(day.year, day.month, day.day, 21, 30),
        priority: EventPriority.medium,
        tags: [const EventTag(name: 'Learning', colorIndex: 3)],
      ));
    }

    // Some heavy days to trigger overload
    for (int d = 0; d < 3; d++) {
      final day = now.subtract(Duration(days: d));
      events.add(EventModel(
        id: nextId(),
        title: 'Extra Project',
        date: DateTime(day.year, day.month, day.day, 20, 0),
        endDate: DateTime(day.year, day.month, day.day, 23, 0),
        priority: EventPriority.urgent,
        tags: [const EventTag(name: 'Work', colorIndex: 0)],
      ));
    }

    _demoEvents = events;

    // Set budgets: Work intentionally under-budgeted for demo
    _budgets.addAll([
      const TimeBudget(category: 'Work', targetHoursPerWeek: 30),
      const TimeBudget(category: 'Personal', targetHoursPerWeek: 10),
      const TimeBudget(category: 'Health', targetHoursPerWeek: 5),
      const TimeBudget(category: 'Learning', targetHoursPerWeek: 8),
    ]);
  }

  void _rebuildReport() {
    final service = TimeBudgetService(
      budgets: _budgets,
      overloadThresholdHours: 8.0,
    );
    _report = service.analyze(
      _demoEvents,
      since: DateTime.now().subtract(const Duration(days: 14)),
      until: DateTime.now(),
    );
  }

  void _addBudget(TimeBudget budget) {
    setState(() {
      _budgets.removeWhere(
          (b) => b.category.toLowerCase() == budget.category.toLowerCase());
      _budgets.add(budget);
      _rebuildReport();
    });
  }

  void _removeBudget(String category) {
    setState(() {
      _budgets
          .removeWhere((b) => b.category.toLowerCase() == category.toLowerCase());
      _rebuildReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Budget'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.timer), text: 'Budget'),
            Tab(icon: Icon(Icons.edit_calendar), text: 'Set'),
            Tab(icon: Icon(Icons.compare_arrows), text: 'Compare'),
            Tab(icon: Icon(Icons.psychology), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BudgetTab(report: _report, budgets: _budgets),
          _SetTab(
            budgets: _budgets,
            onAdd: _addBudget,
            onRemove: _removeBudget,
          ),
          _CompareTab(report: _report, budgets: _budgets),
          _InsightsTab(report: _report),
        ],
      ),
    );
  }
}

// ─── BUDGET TAB ──────────────────────────────────────────────────────────────

class _BudgetTab extends StatelessWidget {
  final TimeBudgetReport? report;
  final List<TimeBudget> budgets;

  const _BudgetTab({required this.report, required this.budgets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = report;

    if (r == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary strip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                    label: 'Tracked',
                    value: '${r.totalTrackedHours.toStringAsFixed(1)}h'),
                _SummaryItem(
                    label: 'Overloaded Days',
                    value: '${r.overloadedDays.length}'),
                _SummaryItem(
                    label: 'Weeks',
                    value: r.weeksInPeriod.toStringAsFixed(1)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Weekly Hour Budgets',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Category cards with progress bars
          if (r.byTag.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_off,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No tracked categories',
                      style: theme.textTheme.titleMedium),
                ],
              ),
            )
          else
            ...r.byTag.map((alloc) {
              final budget = budgets
                  .where((b) =>
                      b.category.toLowerCase() == alloc.category.toLowerCase())
                  .toList();
              final targetHours =
                  budget.isNotEmpty ? budget.first.targetHoursPerWeek : 0.0;
              final utilization = alloc.budgetUtilization;
              final isOver = alloc.isOverBudget == true;
              final progressColor = isOver
                  ? Colors.red
                  : (utilization != null && utilization > 80)
                      ? Colors.orange
                      : Colors.green;
              final progressValue = targetHours > 0
                  ? (alloc.actualHoursPerWeek / targetHours).clamp(0.0, 1.0)
                  : 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(alloc.category,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                              if (isOver)
                                const Icon(Icons.arrow_upward,
                                    color: Colors.red, size: 16),
                              if (alloc.isOverBudget == false)
                                const Icon(Icons.arrow_downward,
                                    color: Colors.green, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                utilization != null
                                    ? '${utilization.toStringAsFixed(0)}%'
                                    : 'No budget',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isOver ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Target: ${targetHours.toStringAsFixed(1)} h/week',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'Actual: ${alloc.actualHoursPerWeek.toStringAsFixed(1)} h/week',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 8,
                          backgroundColor: progressColor.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(progressColor),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
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
  final List<TimeBudget> budgets;
  final void Function(TimeBudget) onAdd;
  final void Function(String) onRemove;

  const _SetTab({
    required this.budgets,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_SetTab> createState() => _SetTabState();
}

class _SetTabState extends State<_SetTab> {
  static const _presetCategories = [
    'Work',
    'Personal',
    'Health',
    'Learning',
    'Social',
    'Creative',
    'Errands',
    'Rest',
  ];

  String _selectedCategory = 'Work';
  final _customController = TextEditingController();
  double _targetHours = 10.0;
  bool _useCustom = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _addBudget() {
    final category =
        _useCustom ? _customController.text.trim() : _selectedCategory;
    if (category.isEmpty) return;

    widget.onAdd(TimeBudget(
      category: category,
      targetHoursPerWeek: _targetHours,
    ));

    _customController.clear();
    setState(() {
      _targetHours = 10.0;
      _useCustom = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Set Budget Targets',
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),

          // Category picker
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _presetCategories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: _useCustom
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  const Text('Custom', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: _useCustom,
                    onChanged: (val) => setState(() => _useCustom = val),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_useCustom)
            TextField(
              controller: _customController,
              decoration: const InputDecoration(
                labelText: 'Custom Category Name',
                border: OutlineInputBorder(),
              ),
            ),

          const SizedBox(height: 16),

          // Hours slider
          Text(
            'Target: ${_targetHours.toStringAsFixed(1)} h/week',
            style: theme.textTheme.titleSmall,
          ),
          Slider(
            value: _targetHours,
            min: 0,
            max: 40,
            divisions: 80,
            label: '${_targetHours.toStringAsFixed(1)}h',
            onChanged: (val) => setState(() => _targetHours = val),
          ),
          const SizedBox(height: 12),

          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Budget'),
            onPressed: _addBudget,
          ),
          const SizedBox(height: 24),

          // Current budgets list
          Text('Current Budgets',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (widget.budgets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No budgets set yet',
                    style: theme.textTheme.bodyMedium),
              ),
            )
          else
            ...widget.budgets.map((b) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(b.category),
                    subtitle:
                        Text('${b.targetHoursPerWeek.toStringAsFixed(1)} h/week'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => widget.onRemove(b.category),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

// ─── COMPARE TAB ────────────────────────────────────────────────────────────

class _CompareTab extends StatelessWidget {
  final TimeBudgetReport? report;
  final List<TimeBudget> budgets;

  const _CompareTab({required this.report, required this.budgets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = report;

    if (r == null || r.byTag.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No data to compare', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    // Find max hours for bar scaling
    double maxHours = 0;
    for (final alloc in r.byTag) {
      final budget = budgets
          .where(
              (b) => b.category.toLowerCase() == alloc.category.toLowerCase())
          .toList();
      final target = budget.isNotEmpty ? budget.first.targetHoursPerWeek : 0.0;
      if (alloc.actualHoursPerWeek > maxHours) {
        maxHours = alloc.actualHoursPerWeek;
      }
      if (target > maxHours) maxHours = target;
    }
    if (maxHours == 0) maxHours = 1;

    const weekdayNames = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    double maxWeekdayHours = 0;
    for (int i = 0; i < 7; i++) {
      final h = r.weekdayHours[i] ?? 0;
      if (h > maxWeekdayHours) maxWeekdayHours = h;
    }
    if (maxWeekdayHours == 0) maxWeekdayHours = 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Planned vs Actual',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          // Legend
          Row(
            children: [
              Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('Budget', style: theme.textTheme.labelSmall),
              const SizedBox(width: 12),
              Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('Actual', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal bar chart per category
          ...r.byTag.map((alloc) {
            final budgetMatch = budgets
                .where((b) =>
                    b.category.toLowerCase() == alloc.category.toLowerCase())
                .toList();
            final target =
                budgetMatch.isNotEmpty ? budgetMatch.first.targetHoursPerWeek : 0.0;
            final actual = alloc.actualHoursPerWeek;
            final isOver = actual > target && target > 0;
            final budgetWidth = (target / maxHours).clamp(0.0, 1.0);
            final actualWidth = (actual / maxHours).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(alloc.category,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        isOver
                            ? 'Over by ${(actual - target).toStringAsFixed(1)}h'
                            : target > 0
                                ? 'Under by ${(target - actual).toStringAsFixed(1)}h'
                                : '${actual.toStringAsFixed(1)}h/week',
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
                          width: 50,
                          child: Text('Budget',
                              style: theme.textTheme.labelSmall)),
                      Expanded(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: budgetWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text('${target.toStringAsFixed(1)}h',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.labelSmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Actual bar
                  Row(
                    children: [
                      SizedBox(
                          width: 50,
                          child: Text('Actual',
                              style: theme.textTheme.labelSmall)),
                      Expanded(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: actualWidth,
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
                        width: 50,
                        child: Text('${actual.toStringAsFixed(1)}h',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.labelSmall),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 32),

          // Weekday distribution
          Text('Weekday Distribution',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final hours = r.weekdayHours[i] ?? 0;
                final barHeight =
                    maxWeekdayHours > 0 ? (hours / maxWeekdayHours) * 100 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${hours.toStringAsFixed(1)}h',
                            style: theme.textTheme.labelSmall),
                        const SizedBox(height: 4),
                        Container(
                          width: 24,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(weekdayNames[i],
                            style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── INSIGHTS TAB ───────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final TimeBudgetReport? report;

  const _InsightsTab({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = report;

    if (r == null) {
      return const Center(child: Text('No data available'));
    }

    final overBudget = r.overBudgetCategories;

    // Build recommendations
    final recommendations = <String>[];
    if (r.avgHoursPerDay > 8) {
      recommendations
          .add('Your average day is ${r.avgHoursPerDay.toStringAsFixed(1)}h — consider scheduling more breaks.');
    }
    if (r.overloadedDays.length > 2) {
      recommendations
          .add('You had ${r.overloadedDays.length} overloaded days. Try spreading tasks more evenly.');
    }
    if (overBudget.isNotEmpty) {
      recommendations.add(
          '${overBudget.length} categories are over budget. Review your allocations.');
    }
    if (r.topTag != null && r.topTag!.percentage > 60) {
      recommendations.add(
          '${r.topTag!.category} takes ${r.topTag!.percentage.toStringAsFixed(0)}% of your time. Consider diversifying.');
    }
    if (recommendations.isEmpty) {
      recommendations
          .add('Great balance! Your time allocation is within targets.');
    }

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
                icon: Icons.today,
                label: 'Busiest Day',
                value: r.busiestWeekday ?? '—',
                color: Colors.orange,
              ),
              _InsightCard(
                icon: Icons.weekend,
                label: 'Lightest Day',
                value: r.lightestWeekday ?? '—',
                color: Colors.green,
              ),
              _InsightCard(
                icon: Icons.category,
                label: 'Top Category',
                value: r.topTag?.category ?? '—',
                color: theme.colorScheme.primary,
              ),
              _InsightCard(
                icon: Icons.schedule,
                label: 'Avg Hours/Day',
                value: '${r.avgHoursPerDay.toStringAsFixed(1)}h',
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Over-budget warnings
          if (overBudget.isNotEmpty) ...[
            Text('Over-Budget Warnings',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...overBudget.map((a) => Card(
                  color: Colors.red.withOpacity(0.1),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading:
                        const Icon(Icons.warning_amber, color: Colors.red),
                    title: Text(a.category),
                    subtitle: Text(
                      '${a.actualHoursPerWeek.toStringAsFixed(1)}h/week vs ${a.budgetHoursPerWeek!.toStringAsFixed(1)}h target',
                    ),
                    trailing: Text(
                      '+${(a.actualHoursPerWeek - a.budgetHoursPerWeek!).toStringAsFixed(1)}h',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Overloaded days
          if (r.overloadedDays.isNotEmpty) ...[
            Text('Overloaded Days',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...r.overloadedDays.map((day) {
              final dateStr =
                  '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.event_busy, color: Colors.orange),
                  title: Text(dateStr),
                  subtitle: Text(
                      '${day.totalHours.toStringAsFixed(1)}h total, ${day.eventCount} events'),
                  trailing: Text(
                    '+${day.excessHours.toStringAsFixed(1)}h over',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Recommendations
          Text('Recommendations',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...recommendations.map((rec) => Card(
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
              )),
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
