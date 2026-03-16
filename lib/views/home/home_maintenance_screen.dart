import 'package:flutter/material.dart';
import '../../core/services/home_maintenance_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/home_maintenance_entry.dart';

/// Home Maintenance Tracker — manage recurring home tasks with scheduling,
/// completion tracking, cost analytics, and overdue alerts.
class HomeMaintenanceScreen extends StatefulWidget {
  const HomeMaintenanceScreen({super.key});

  @override
  State<HomeMaintenanceScreen> createState() => _HomeMaintenanceScreenState();
}

class _HomeMaintenanceScreenState extends State<HomeMaintenanceScreen>
    with SingleTickerProviderStateMixin, PersistentStateMixin {
  @override
  String get storageKey => 'home_maintenance_data';
  @override
  String exportData() => _service.exportToJson();
  @override
  void importData(String json) => _service.importFromJson(json);

  final HomeMaintenanceService _service = HomeMaintenanceService();
  late TabController _tabController;
  MaintenanceCategory? _filterCategory;
  String _searchQuery = '';
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initData();
  }

  Future<void> _initData() async {
    await initPersistence();
    if (_service.tasks.isEmpty) {
      _loadSampleData();
    } else {
      _nextId = _service.tasks.length + 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    final now = DateTime.now();
    final samples = [
      HomeMaintenanceEntry(
        id: 'm1',
        name: 'Replace HVAC Filter',
        category: MaintenanceCategory.hvac,
        priority: MaintenancePriority.high,
        description: 'Replace air filter in furnace/AC unit',
        recurrence: RecurrenceInterval.quarterly,
        recurrenceDays: 90,
        nextDueDate: now.add(const Duration(days: 12)),
        location: 'Basement',
        estimatedCost: 25,
        completions: [
          MaintenanceCompletion(
            completedDate: now.subtract(const Duration(days: 78)),
            cost: 22,
            vendor: 'Home Depot',
          ),
        ],
      ),
      HomeMaintenanceEntry(
        id: 'm2',
        name: 'Clean Gutters',
        category: MaintenanceCategory.exterior,
        priority: MaintenancePriority.medium,
        description: 'Remove debris from gutters and downspouts',
        recurrence: RecurrenceInterval.biannually,
        recurrenceDays: 182,
        nextDueDate: now.subtract(const Duration(days: 5)),
        location: 'Exterior',
        estimatedCost: 150,
      ),
      HomeMaintenanceEntry(
        id: 'm3',
        name: 'Test Smoke Detectors',
        category: MaintenanceCategory.safety,
        priority: MaintenancePriority.urgent,
        description: 'Test all smoke and CO detectors, replace batteries',
        recurrence: RecurrenceInterval.biannually,
        recurrenceDays: 182,
        nextDueDate: now.add(const Duration(days: 3)),
        location: 'Whole House',
        estimatedCost: 20,
        completions: [
          MaintenanceCompletion(
            completedDate: now.subtract(const Duration(days: 179)),
            cost: 18,
            notes: 'Replaced batteries in 3 detectors',
          ),
        ],
      ),
      HomeMaintenanceEntry(
        id: 'm4',
        name: 'Service Water Heater',
        category: MaintenanceCategory.plumbing,
        priority: MaintenancePriority.medium,
        description: 'Flush sediment, check anode rod, inspect for leaks',
        recurrence: RecurrenceInterval.annually,
        recurrenceDays: 365,
        nextDueDate: now.add(const Duration(days: 95)),
        location: 'Garage',
        estimatedCost: 200,
        completions: [
          MaintenanceCompletion(
            completedDate: now.subtract(const Duration(days: 270)),
            cost: 185,
            vendor: 'ABC Plumbing',
            notes: 'Anode rod replaced',
          ),
        ],
      ),
      HomeMaintenanceEntry(
        id: 'm5',
        name: 'Deep Clean Kitchen Appliances',
        category: MaintenanceCategory.appliance,
        priority: MaintenancePriority.low,
        description: 'Clean oven, dishwasher, refrigerator coils',
        recurrence: RecurrenceInterval.quarterly,
        recurrenceDays: 90,
        nextDueDate: now.add(const Duration(days: 45)),
        location: 'Kitchen',
        estimatedCost: 0,
      ),
      HomeMaintenanceEntry(
        id: 'm6',
        name: 'Lawn Mowing',
        category: MaintenanceCategory.landscaping,
        priority: MaintenancePriority.medium,
        description: 'Mow front and back lawn',
        recurrence: RecurrenceInterval.weekly,
        recurrenceDays: 7,
        nextDueDate: now.add(const Duration(days: 2)),
        location: 'Yard',
        estimatedCost: 0,
        completions: [
          MaintenanceCompletion(
            completedDate: now.subtract(const Duration(days: 5)),
            cost: 0,
          ),
          MaintenanceCompletion(
            completedDate: now.subtract(const Duration(days: 12)),
            cost: 0,
          ),
        ],
      ),
      HomeMaintenanceEntry(
        id: 'm7',
        name: 'Check Electrical Panel',
        category: MaintenanceCategory.electrical,
        priority: MaintenancePriority.high,
        description: 'Inspect breakers, check for corrosion, verify labels',
        recurrence: RecurrenceInterval.annually,
        recurrenceDays: 365,
        nextDueDate: now.add(const Duration(days: 200)),
        location: 'Garage',
        estimatedCost: 0,
      ),
      HomeMaintenanceEntry(
        id: 'm8',
        name: 'Repaint Bathroom',
        category: MaintenanceCategory.interior,
        priority: MaintenancePriority.low,
        description: 'Touch up paint, check for moisture damage',
        recurrence: RecurrenceInterval.annually,
        recurrenceDays: 365,
        nextDueDate: now.add(const Duration(days: 150)),
        location: 'Master Bathroom',
        estimatedCost: 80,
      ),
      HomeMaintenanceEntry(
        id: 'm9',
        name: 'Winterize Sprinklers',
        category: MaintenanceCategory.seasonal,
        priority: MaintenancePriority.high,
        description: 'Blow out sprinkler lines before first freeze',
        recurrence: RecurrenceInterval.annually,
        recurrenceDays: 365,
        nextDueDate: now.add(const Duration(days: 240)),
        location: 'Yard',
        estimatedCost: 75,
        completions: [
          MaintenanceCompletion(
            completedDate: now.subtract(const Duration(days: 125)),
            cost: 70,
            vendor: 'Green Thumb Irrigation',
          ),
        ],
      ),
    ];
    for (final s in samples) {
      _service.addTask(s);
    }
    _nextId = 10;
    setState(() {});
    savePersistence();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏠 Home Maintenance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.warning_amber), text: 'Alerts'),
            Tab(icon: Icon(Icons.list), text: 'All Tasks'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.analytics), text: 'Costs'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
            tooltip: 'Add task',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertsTab(),
          _buildAllTasksTab(),
          _buildHistoryTab(),
          _buildCostsTab(),
        ],
      ),
    );
  }

  // --- Alerts Tab ---
  Widget _buildAlertsTab() {
    final alerts = _service.alertTasks;
    if (alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('All caught up!', style: TextStyle(fontSize: 18)),
            Text('No overdue or upcoming tasks'),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: alerts.length,
      itemBuilder: (ctx, i) => _buildTaskCard(alerts[i]),
    );
  }

  // --- All Tasks Tab ---
  Widget _buildAllTasksTab() {
    var tasks = _service.sortedByUrgency;
    if (_filterCategory != null) {
      tasks = tasks.where((t) => t.category == _filterCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      tasks = _service.search(_searchQuery)
          .where((t) => _filterCategory == null || t.category == _filterCategory)
          .toList();
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<MaintenanceCategory?>(
                value: _filterCategory,
                hint: const Text('Category'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...MaintenanceCategory.values.map((c) =>
                      DropdownMenuItem(value: c, child: Text('${c.emoji} ${c.label}'))),
                ],
                onChanged: (v) => setState(() => _filterCategory = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(child: Text('No tasks found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: tasks.length,
                  itemBuilder: (ctx, i) => _buildTaskCard(tasks[i]),
                ),
        ),
      ],
    );
  }

  // --- History Tab ---
  Widget _buildHistoryTab() {
    final allCompletions = <_CompletionWithTask>[];
    for (final t in _service.tasks) {
      for (final c in t.completions) {
        allCompletions.add(_CompletionWithTask(task: t, completion: c));
      }
    }
    allCompletions.sort((a, b) =>
        b.completion.completedDate.compareTo(a.completion.completedDate));

    if (allCompletions.isEmpty) {
      return const Center(child: Text('No completion history yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: allCompletions.length,
      itemBuilder: (ctx, i) {
        final item = allCompletions[i];
        final c = item.completion;
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(item.task.category.emoji)),
            title: Text(item.task.name),
            subtitle: Text(
              '${_formatDate(c.completedDate)}'
              '${c.cost != null ? ' • \$${c.cost!.toStringAsFixed(2)}' : ''}'
              '${c.vendor != null ? ' • ${c.vendor}' : ''}',
            ),
            trailing: c.notes != null
                ? Tooltip(message: c.notes!, child: const Icon(Icons.notes))
                : null,
          ),
        );
      },
    );
  }

  // --- Costs Tab ---
  Widget _buildCostsTab() {
    final spending = _service.spendingByCategory;
    final statusCounts = _service.countByStatus;
    final total = _service.totalSpent;
    final rate = _service.completionRate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _summaryCard('Total Spent', '\$${total.toStringAsFixed(2)}', Icons.attach_money),
              const SizedBox(width: 8),
              _summaryCard('Tasks', '${_service.tasks.length}', Icons.task),
              const SizedBox(width: 8),
              _summaryCard('Done Rate', '${(rate * 100).toStringAsFixed(0)}%', Icons.pie_chart),
            ],
          ),
          const SizedBox(height: 16),
          // Status overview
          const Text('Status Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...MaintenanceStatus.values.map((s) {
            final count = statusCounts[s] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text('${s.emoji} ${s.label}'),
                  const Spacer(),
                  Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
          const Divider(height: 24),
          // Spending by category
          const Text('Spending by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (spending.isEmpty)
            const Text('No spending data yet')
          else
            ...(spending.entries
                .where((e) => e.value > 0)
                .toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text('${e.key.emoji} ${e.key.label}'),
                          const Spacer(),
                          Text('\$${e.value.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
          const Divider(height: 24),
          // Tasks needing attention
          const Text('Never Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._service.neverCompleted.map((t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${t.category.emoji} ${t.name}'),
                    const Spacer(),
                    Text('Due ${_daysLabel(t.daysUntilDue)}',
                        style: TextStyle(
                          color: t.daysUntilDue < 0 ? Colors.red : null,
                        )),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Task Card ---
  Widget _buildTaskCard(HomeMaintenanceEntry task) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(task.status),
          child: Text(task.category.emoji),
        ),
        title: Text(task.name),
        subtitle: Text(
          '${task.status.emoji} ${_daysLabel(task.daysUntilDue)} '
          '• ${task.priority.emoji} ${task.priority.label}'
          '${task.location != null ? ' • 📍${task.location}' : ''}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null) ...[
                  Text(task.description!),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    const Icon(Icons.repeat, size: 16),
                    const SizedBox(width: 4),
                    Text('Every ${task.recurrenceDays} days (${task.recurrence.label})'),
                  ],
                ),
                if (task.estimatedCost != null && task.estimatedCost! > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 16),
                      Text('Est. \$${task.estimatedCost!.toStringAsFixed(2)}'
                          ' • Avg. \$${task.averageCost.toStringAsFixed(2)}'
                          ' • Total \$${task.totalSpent.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16),
                    const SizedBox(width: 4),
                    Text('Completed ${task.completionCount} times'
                        '${task.lastCompleted != null ? ' (last: ${_formatDate(task.lastCompleted!)})' : ''}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Mark Done'),
                      onPressed: () => _showCompleteDialog(task),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () => _showEditDialog(task),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        setState(() => _service.removeTask(task.id));
                        savePersistence();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Dialogs ---
  void _showAddDialog() {
    _showTaskFormDialog(null);
  }

  void _showEditDialog(HomeMaintenanceEntry task) {
    _showTaskFormDialog(task);
  }

  void _showTaskFormDialog(HomeMaintenanceEntry? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    final costCtrl = TextEditingController(
        text: existing?.estimatedCost?.toString() ?? '');
    var category = existing?.category ?? MaintenanceCategory.other;
    var priority = existing?.priority ?? MaintenancePriority.medium;
    var recurrence = existing?.recurrence ?? RecurrenceInterval.monthly;
    var dueDate = existing?.nextDueDate ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Task' : 'Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Task Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<MaintenanceCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: MaintenanceCategory.values.map((c) =>
                      DropdownMenuItem(value: c, child: Text('${c.emoji} ${c.label}'))).toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<MaintenancePriority>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: MaintenancePriority.values.map((p) =>
                      DropdownMenuItem(value: p, child: Text('${p.emoji} ${p.label}'))).toList(),
                  onChanged: (v) => setDialogState(() => priority = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<RecurrenceInterval>(
                  value: recurrence,
                  decoration: const InputDecoration(labelText: 'Recurrence'),
                  items: RecurrenceInterval.values.map((r) =>
                      DropdownMenuItem(value: r, child: Text(r.label))).toList(),
                  onChanged: (v) => setDialogState(() => recurrence = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location (optional)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: costCtrl,
                  decoration: const InputDecoration(labelText: 'Estimated Cost'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Next Due Date'),
                  subtitle: Text(_formatDate(dueDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (picked != null) setDialogState(() => dueDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final task = HomeMaintenanceEntry(
                  id: existing?.id ?? 'm${_nextId++}',
                  name: nameCtrl.text.trim(),
                  category: category,
                  priority: priority,
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  recurrence: recurrence,
                  recurrenceDays: recurrence.defaultDays,
                  nextDueDate: dueDate,
                  completions: existing?.completions ?? [],
                  location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                  estimatedCost: double.tryParse(costCtrl.text),
                );
                setState(() {
                  if (existing != null) {
                    _service.updateTask(existing.id, task);
                  } else {
                    _service.addTask(task);
                  }
                });
                savePersistence();
                Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteDialog(HomeMaintenanceEntry task) {
    final costCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Complete: ${task.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: costCtrl,
              decoration: const InputDecoration(labelText: 'Cost (optional)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: vendorCtrl,
              decoration: const InputDecoration(labelText: 'Vendor (optional)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _service.completeTask(
                  task.id,
                  cost: double.tryParse(costCtrl.text),
                  vendor: vendorCtrl.text.trim().isEmpty ? null : vendorCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                );
              });
              savePersistence();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ ${task.name} marked complete!')),
              );
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
  Color _statusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.overdue: return Colors.red;
      case MaintenanceStatus.dueSoon: return Colors.orange;
      case MaintenanceStatus.upcoming: return Colors.amber;
      case MaintenanceStatus.onTrack: return Colors.green;
    }
  }

  String _daysLabel(int days) {
    if (days < 0) return '${-days}d overdue';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in ${days}d';
  }

  String _formatDate(DateTime d) =>
      '${d.month}/${d.day}/${d.year}';
}

class _CompletionWithTask {
  final HomeMaintenanceEntry task;
  final MaintenanceCompletion completion;
  const _CompletionWithTask({required this.task, required this.completion});
}
