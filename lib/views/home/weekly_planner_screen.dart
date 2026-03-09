import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/weekly_planner_service.dart';
import '../../models/event_model.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../state/providers/event_provider.dart';

/// Weekly Planner screen — interactive day-by-day plan with events, goal work
/// blocks, habit reminders, free time windows, load scores, and warnings.
///
/// 4 tabs: Overview | Daily | Goals | Warnings
class WeeklyPlannerScreen extends StatefulWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  State<WeeklyPlannerScreen> createState() => _WeeklyPlannerScreenState();
}

class _WeeklyPlannerScreenState extends State<WeeklyPlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PlannerConfig _config = const PlannerConfig();
  int _selectedDayIndex = 0;

  // Sample goals and habits for demonstration (in a real app these come from providers)
  final List<Goal> _sampleGoals = [];
  final List<Habit> _sampleHabits = [];
  final List<HabitCompletion> _sampleCompletions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<EventModel> get _events =>
      Provider.of<EventProvider>(context, listen: false).events;

  WeeklyPlan get _plan {
    final service = WeeklyPlannerService(config: _config);
    return service.generate(
      events: _events,
      goals: _sampleGoals,
      habits: _sampleHabits,
      habitCompletions: _sampleCompletions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showConfigDialog,
            tooltip: 'Planner settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.view_day), text: 'Daily'),
            Tab(icon: Icon(Icons.flag), text: 'Goals'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Warnings'),
          ],
        ),
      ),
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          final plan = _plan;
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(plan),
              _buildDailyTab(plan),
              _buildGoalsTab(plan),
              _buildWarningsTab(plan),
            ],
          );
        },
      ),
    );
  }

  // ─── Overview Tab ──────────────────────────────────────────

  Widget _buildOverviewTab(WeeklyPlan plan) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week at a Glance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statColumn(
                      '${(plan.totalPlannedMinutes / 60).toStringAsFixed(1)}h',
                      'Planned',
                      Icons.schedule,
                      Colors.blue,
                    ),
                    _statColumn(
                      '${(plan.totalFreeMinutes / 60).toStringAsFixed(1)}h',
                      'Free',
                      Icons.free_breakfast,
                      Colors.green,
                    ),
                    _statColumn(
                      '${(plan.avgLoadScore * 100).toStringAsFixed(0)}%',
                      'Avg Load',
                      Icons.speed,
                      plan.avgLoadScore >= 0.8 ? Colors.red : Colors.orange,
                    ),
                    _statColumn(
                      '${plan.overloadedDays}',
                      'Overloaded',
                      Icons.warning,
                      plan.overloadedDays > 0 ? Colors.red : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Day-by-day load bars
        Text(
          'Daily Load',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...plan.days.map((day) => _buildDayLoadBar(day)),

        const SizedBox(height: 16),

        // Item type breakdown
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item Breakdown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _breakdownRow(
                  'Events',
                  plan.days.fold(0, (s, d) => s + d.eventCount),
                  Colors.blue,
                  Icons.event,
                ),
                _breakdownRow(
                  'Goal Blocks',
                  plan.days.fold(0, (s, d) => s + d.goalBlockCount),
                  Colors.purple,
                  Icons.flag,
                ),
                _breakdownRow(
                  'Habits',
                  plan.days.fold(0, (s, d) => s + d.habitCount),
                  Colors.teal,
                  Icons.repeat,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statColumn(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: color,
        )),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildDayLoadBar(DailyPlan day) {
    final loadColor = day.loadScore >= 1.0
        ? Colors.red
        : day.loadScore >= 0.8
            ? Colors.orange
            : day.loadScore >= 0.5
                ? Colors.amber
                : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              day.weekdayName.substring(0, 3),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: day.loadScore.clamp(0, 1.2) / 1.2,
                backgroundColor: Colors.grey[200],
                color: loadColor,
                minHeight: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text(
              '${(day.loadScore * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: loadColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, int count, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            '$count',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ─── Daily Tab ─────────────────────────────────────────────

  Widget _buildDailyTab(WeeklyPlan plan) {
    if (plan.days.isEmpty) {
      return const Center(child: Text('No plan generated'));
    }

    final day = plan.days[_selectedDayIndex.clamp(0, plan.days.length - 1)];

    return Column(
      children: [
        // Day selector
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: plan.days.length,
            itemBuilder: (context, index) {
              final d = plan.days[index];
              final isSelected = index == _selectedDayIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    '${d.weekdayName.substring(0, 3)} ${d.date.day}',
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedDayIndex = index),
                  avatar: isSelected
                      ? null
                      : Icon(
                          d.loadScore >= 1.0
                              ? Icons.error
                              : d.loadScore >= 0.8
                                  ? Icons.warning
                                  : Icons.check_circle,
                          size: 16,
                          color: d.loadScore >= 1.0
                              ? Colors.red
                              : d.loadScore >= 0.8
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                ),
              );
            },
          ),
        ),

        // Day header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${day.weekdayName} — ${day.loadLabel}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${day.plannedMinutes}m planned · ${day.freeMinutes}m free',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Divider(),

        // Items list
        Expanded(
          child: day.items.isEmpty
              ? const Center(child: Text('No items scheduled'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: day.items.length,
                  itemBuilder: (context, index) =>
                      _buildPlanItemCard(day.items[index]),
                ),
        ),

        // Day warnings
        if (day.warnings.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.amber[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: day.warnings.map((w) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      w.severity == WarningSeverity.critical
                          ? Icons.error
                          : Icons.warning,
                      size: 16,
                      color: w.severity == WarningSeverity.critical
                          ? Colors.red
                          : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        w.message,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPlanItemCard(PlanItem item) {
    final color = _itemColor(item.type);
    final icon = _itemIcon(item.type);
    final startStr =
        '${item.start.hour.toString().padLeft(2, '0')}:${item.start.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${item.end.hour.toString().padLeft(2, '0')}:${item.end.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: item.type == PlanItemType.freeTime
                ? Colors.grey[600]
                : null,
            fontStyle: item.type == PlanItemType.freeTime
                ? FontStyle.italic
                : null,
          ),
        ),
        subtitle: Text('$startStr – $endStr · ${item.minutes} min'),
        trailing: item.category != null
            ? Chip(
                label: Text(
                  item.category!,
                  style: const TextStyle(fontSize: 11),
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )
            : null,
      ),
    );
  }

  Color _itemColor(PlanItemType type) {
    switch (type) {
      case PlanItemType.event:
        return Colors.blue;
      case PlanItemType.goalWork:
        return Colors.purple;
      case PlanItemType.habit:
        return Colors.teal;
      case PlanItemType.freeTime:
        return Colors.grey;
    }
  }

  IconData _itemIcon(PlanItemType type) {
    switch (type) {
      case PlanItemType.event:
        return Icons.event;
      case PlanItemType.goalWork:
        return Icons.flag;
      case PlanItemType.habit:
        return Icons.repeat;
      case PlanItemType.freeTime:
        return Icons.free_breakfast;
    }
  }

  // ─── Goals Tab ─────────────────────────────────────────────

  Widget _buildGoalsTab(WeeklyPlan plan) {
    final scheduledIds = plan.scheduledGoalIds;
    final allGoalItems = plan.days
        .expand((d) => d.items)
        .where((i) => i.type == PlanItemType.goalWork)
        .toList();

    // Group by goal refId
    final goalBlocks = <String, List<PlanItem>>{};
    for (final item in allGoalItems) {
      final id = item.refId ?? 'unknown';
      goalBlocks.putIfAbsent(id, () => []).add(item);
    }

    if (goalBlocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No goal blocks scheduled',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add goals to see work blocks in your plan',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${scheduledIds.length} goal${scheduledIds.length != 1 ? 's' : ''} scheduled',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...goalBlocks.entries.map((entry) {
          final blocks = entry.value;
          final totalMinutes = blocks.fold(0, (s, b) => s + b.minutes);
          final title = blocks.first.title;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ExpansionTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x26673AB7),
                child: Icon(Icons.flag, color: Colors.purple, size: 20),
              ),
              title: Text(title),
              subtitle: Text(
                '${blocks.length} block${blocks.length != 1 ? 's' : ''} · '
                '${totalMinutes} min total',
              ),
              children: blocks.map((b) {
                final dayName = [
                  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                ][b.start.weekday - 1];
                final startStr =
                    '${b.start.hour.toString().padLeft(2, '0')}:${b.start.minute.toString().padLeft(2, '0')}';
                return ListTile(
                  dense: true,
                  leading: Text(dayName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  title: Text('$startStr · ${b.minutes} min'),
                  subtitle: b.category != null ? Text(b.category!) : null,
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  // ─── Warnings Tab ──────────────────────────────────────────

  Widget _buildWarningsTab(WeeklyPlan plan) {
    final allWarnings = plan.allWarnings;

    if (allWarnings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
            const SizedBox(height: 16),
            Text(
              'No warnings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your week looks well-balanced!',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    // Group by severity
    final critical =
        allWarnings.where((w) => w.severity == WarningSeverity.critical).toList();
    final warnings =
        allWarnings.where((w) => w.severity == WarningSeverity.warning).toList();
    final info =
        allWarnings.where((w) => w.severity == WarningSeverity.info).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Card(
          color: critical.isNotEmpty
              ? Colors.red[50]
              : warnings.isNotEmpty
                  ? Colors.orange[50]
                  : Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  critical.isNotEmpty ? Icons.error : Icons.warning,
                  color: critical.isNotEmpty ? Colors.red : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${allWarnings.length} warning${allWarnings.length != 1 ? 's' : ''}: '
                    '${critical.length} critical, ${warnings.length} warning, ${info.length} info',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (critical.isNotEmpty) ...[
          _warningSection('Critical', critical, Colors.red, Icons.error),
          const SizedBox(height: 12),
        ],
        if (warnings.isNotEmpty) ...[
          _warningSection('Warnings', warnings, Colors.orange, Icons.warning),
          const SizedBox(height: 12),
        ],
        if (info.isNotEmpty)
          _warningSection('Info', info, Colors.blue, Icons.info),
      ],
    );
  }

  Widget _warningSection(
    String title,
    List<PlanWarning> items,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
        ),
        const SizedBox(height: 6),
        ...items.map((w) => Card(
              margin: const EdgeInsets.symmetric(vertical: 3),
              child: ListTile(
                leading: Icon(icon, color: color, size: 20),
                title: Text(w.message, style: const TextStyle(fontSize: 14)),
                subtitle: w.date != null
                    ? Text(
                        '${w.date!.year}-${w.date!.month.toString().padLeft(2, '0')}-${w.date!.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12),
                      )
                    : const Text('Week-level',
                        style: TextStyle(fontSize: 12)),
              ),
            )),
      ],
    );
  }

  // ─── Config Dialog ─────────────────────────────────────────

  void _showConfigDialog() {
    var dayStart = _config.dayStartHour;
    var dayEnd = _config.dayEndHour;
    var planDays = _config.planDays;
    var goalBlock = _config.goalBlockMinutes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Planner Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _configSlider(
                  label: 'Day starts at',
                  value: dayStart,
                  min: 5,
                  max: 12,
                  suffix: ':00',
                  onChanged: (v) => setDialogState(() => dayStart = v),
                ),
                _configSlider(
                  label: 'Day ends at',
                  value: dayEnd,
                  min: 16,
                  max: 23,
                  suffix: ':00',
                  onChanged: (v) => setDialogState(() => dayEnd = v),
                ),
                _configSlider(
                  label: 'Plan days ahead',
                  value: planDays,
                  min: 1,
                  max: 14,
                  suffix: ' days',
                  onChanged: (v) => setDialogState(() => planDays = v),
                ),
                _configSlider(
                  label: 'Goal block size',
                  value: goalBlock,
                  min: 15,
                  max: 120,
                  suffix: ' min',
                  onChanged: (v) => setDialogState(() => goalBlock = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _config = PlannerConfig(
                    dayStartHour: dayStart,
                    dayEndHour: dayEnd,
                    planDays: planDays,
                    goalBlockMinutes: goalBlock,
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _configSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$value$suffix',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}
