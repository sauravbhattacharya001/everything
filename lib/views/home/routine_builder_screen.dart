import 'package:flutter/material.dart';
import '../../core/services/routine_builder_service.dart';
import '../../models/routine.dart';

/// Routine Builder screen — create routines, run step-by-step, track analytics.
///
/// 4 tabs: Today (scheduled routines), Library (all routines), Run (active
/// execution), Analytics (streaks, completion rates, step insights).
class RoutineBuilderScreen extends StatefulWidget {
  const RoutineBuilderScreen({super.key});

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen>
    with SingleTickerProviderStateMixin {
  final RoutineBuilderService _service = RoutineBuilderService();
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDemoData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDemoData() {
    for (final name in RoutineBuilderService.templateNames) {
      try {
        _service.addRoutine(RoutineBuilderService.createTemplate(name));
      } catch (_) {}
    }
  }

  Future<void> _showAddRoutineDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedEmoji = '📋';
    TimeSlot selectedSlot = TimeSlot.morning;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('New Routine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Morning Routine',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TimeSlot>(
                  value: selectedSlot,
                  decoration: const InputDecoration(labelText: 'Time Slot'),
                  items: TimeSlot.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setD(() => selectedSlot = v!),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['📋', '☀️', '🌙', '💪', '📚', '🧘', '🎯', '⚡']
                      .map((e) => ChoiceChip(
                            label: Text(e, style: const TextStyle(fontSize: 20)),
                            selected: selectedEmoji == e,
                            onSelected: (_) => setD(() => selectedEmoji = e),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        _service.addRoutine(Routine(
          id: 'r-${DateTime.now().millisecondsSinceEpoch}',
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          emoji: selectedEmoji,
          timeSlot: selectedSlot,
          createdAt: DateTime.now(),
          steps: [
            RoutineStep(id: 's-${DateTime.now().millisecondsSinceEpoch}', name: 'First Step', durationMinutes: 5, order: 0),
          ],
        ));
      });
      _showSnack('Routine created! Tap it to add steps.');
    }
  }

  Future<void> _showAddStepDialog(Routine routine) async {
    final nameCtrl = TextEditingController();
    int duration = 5;
    bool optional = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Add Step to ${routine.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Step Name'), autofocus: true),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Duration: '),
                DropdownButton<int>(
                  value: duration,
                  items: [1, 2, 5, 10, 15, 20, 25, 30, 45, 60].map((d) => DropdownMenuItem(value: d, child: Text('$d min'))).toList(),
                  onChanged: (v) => setD(() => duration = v!),
                ),
                const Spacer(),
                FilterChip(label: const Text('Optional'), selected: optional, onSelected: (v) => setD(() => optional = v)),
              ]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        final steps = List<RoutineStep>.from(routine.steps)
          ..add(RoutineStep(id: 's-${DateTime.now().millisecondsSinceEpoch}', name: nameCtrl.text.trim(), durationMinutes: duration, isOptional: optional, order: routine.steps.length));
        _service.updateRoutine(routine.copyWith(steps: steps));
      });
      _showSnack('Step added');
    }
  }

  Future<void> _showTemplatePickerDialog() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Add from Template'),
        children: RoutineBuilderService.templateNames
            .map((name) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, name),
                  child: ListTile(
                    leading: Text(name == 'morning' ? '☀️' : name == 'evening' ? '🌙' : name == 'workout' ? '💪' : '📚', style: const TextStyle(fontSize: 24)),
                    title: Text(name[0].toUpperCase() + name.substring(1)),
                  ),
                ))
            .toList(),
      ),
    );
    if (picked != null) {
      try {
        setState(() => _service.addRoutine(RoutineBuilderService.createTemplate(picked)));
        _showSnack('$picked routine added!');
      } catch (e) {
        _showSnack('Could not add: $e');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routine Builder'),
        elevation: 0,
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(icon: Icon(Icons.today), text: 'Today'),
          Tab(icon: Icon(Icons.list_alt), text: 'Library'),
          Tab(icon: Icon(Icons.play_circle_outline), text: 'Run'),
          Tab(icon: Icon(Icons.insights), text: 'Analytics'),
        ]),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: 'Add routine',
            onSelected: (v) { if (v == 'custom') _showAddRoutineDialog(); if (v == 'template') _showTemplatePickerDialog(); },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'custom', child: Text('New Custom Routine')),
              PopupMenuItem(value: 'template', child: Text('From Template')),
            ],
          ),
        ],
      ),
      body: TabBarView(controller: _tabController, children: [
        _TodayTab(service: _service, date: _selectedDate, onDateChanged: (d) => setState(() => _selectedDate = d), onStartRun: (routineId) {
          try {
            setState(() => _service.startRun(routineId, now: DateTime.now()));
            _tabController.animateTo(2);
            _showSnack('Routine started! Complete steps below.');
          } catch (e) { _showSnack('$e'); }
        }),
        _LibraryTab(service: _service, onAddStep: (r) => _showAddStepDialog(r), onDelete: (id) { setState(() => _service.removeRoutine(id)); _showSnack('Routine removed'); }, onToggleActive: (r) { setState(() => _service.updateRoutine(r.copyWith(isActive: !r.isActive))); }),
        _RunTab(service: _service, date: _selectedDate, onComplete: (rid, sid) { try { setState(() => _service.completeStep(rid, _selectedDate, sid)); } catch (e) { _showSnack('$e'); } }, onSkip: (rid, sid) { try { setState(() => _service.skipStep(rid, _selectedDate, sid)); } catch (e) { _showSnack('$e'); } }),
        _AnalyticsTab(service: _service),
      ]),
    );
  }
}

class _TodayTab extends StatelessWidget {
  final RoutineBuilderService service;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onStartRun;
  const _TodayTab({required this.service, required this.date, required this.onDateChanged, required this.onStartRun});

  @override
  Widget build(BuildContext context) {
    final scheduled = service.getRoutinesForDate(date);
    final runs = service.getRunsForDate(date);
    final totalMin = service.getTotalMinutesForDate(date);
    return Column(children: [
      Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => onDateChanged(date.subtract(const Duration(days: 1)))),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
              if (picked != null) onDateChanged(picked);
            },
            child: Text(_formatDateFriendly(date), style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => onDateChanged(date.add(const Duration(days: 1)))),
        ]),
      ),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
        _StatChip(label: 'Routines', value: '${scheduled.length}', icon: Icons.repeat),
        const SizedBox(width: 12),
        _StatChip(label: 'Total', value: '${totalMin}m', icon: Icons.schedule),
        const SizedBox(width: 12),
        _StatChip(label: 'Done', value: '${runs.where((r) => r.isFinished).length}', icon: Icons.check_circle_outline),
      ])),
      Expanded(
        child: scheduled.isEmpty
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.self_improvement, size: 64, color: Colors.grey), SizedBox(height: 16), Text('No routines scheduled for this day', style: TextStyle(color: Colors.grey))]))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: scheduled.length,
                itemBuilder: (ctx, i) {
                  final routine = scheduled[i];
                  final run = runs.where((r) => r.routineId == routine.id).toList();
                  final hasRun = run.isNotEmpty;
                  final isFinished = hasRun && run.first.isFinished;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isFinished ? Colors.green.shade100 : hasRun ? Colors.orange.shade100 : Colors.grey.shade200,
                        child: Text(routine.emoji ?? '📋', style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(routine.name, style: TextStyle(decoration: isFinished ? TextDecoration.lineThrough : null)),
                      subtitle: Text('${routine.timeSlot.label} · ${routine.steps.length} steps · ${routine.totalDurationMinutes}m${hasRun ? ' · ${(run.first.completionRatio * 100).round()}% done' : ''}'),
                      trailing: isFinished
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : hasRun
                              ? CircularProgressIndicator(value: run.first.completionRatio, strokeWidth: 3)
                              : FilledButton.tonal(onPressed: () => onStartRun(routine.id), child: const Text('Start')),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  String _formatDateFriendly(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}

class _LibraryTab extends StatelessWidget {
  final RoutineBuilderService service;
  final ValueChanged<Routine> onAddStep;
  final ValueChanged<String> onDelete;
  final ValueChanged<Routine> onToggleActive;
  const _LibraryTab({required this.service, required this.onAddStep, required this.onDelete, required this.onToggleActive});

  @override
  Widget build(BuildContext context) {
    final routines = service.routines;
    if (routines.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.playlist_add, size: 64, color: Colors.grey), SizedBox(height: 16), Text('No routines yet. Tap + to create one.', style: TextStyle(color: Colors.grey))]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: routines.length,
      itemBuilder: (ctx, i) {
        final routine = routines[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: routine.isActive ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade300,
              child: Text(routine.emoji ?? '📋', style: const TextStyle(fontSize: 20)),
            ),
            title: Text(routine.name, style: TextStyle(color: routine.isActive ? null : Colors.grey)),
            subtitle: Text('${routine.timeSlot.label} · ${routine.totalDurationMinutes}m · ${routine.steps.length} steps${routine.activeDays.isNotEmpty ? ' · ${_formatDays(routine.activeDays)}' : ' · Daily'}'),
            children: [
              ...routine.steps.map((step) => ListTile(
                dense: true,
                leading: Icon(step.isOptional ? Icons.radio_button_unchecked : Icons.circle, size: 12, color: step.isOptional ? Colors.grey : Colors.blue),
                title: Text('${step.emoji ?? ''} ${step.name}', style: TextStyle(fontStyle: step.isOptional ? FontStyle.italic : FontStyle.normal)),
                trailing: Text('${step.durationMinutes}m', style: const TextStyle(color: Colors.grey)),
              )),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(spacing: 8, children: [
                  ActionChip(avatar: const Icon(Icons.add, size: 16), label: const Text('Add Step'), onPressed: () => onAddStep(routine)),
                  ActionChip(avatar: Icon(routine.isActive ? Icons.pause : Icons.play_arrow, size: 16), label: Text(routine.isActive ? 'Pause' : 'Activate'), onPressed: () => onToggleActive(routine)),
                  ActionChip(avatar: const Icon(Icons.delete_outline, size: 16, color: Colors.red), label: const Text('Delete', style: TextStyle(color: Colors.red)), onPressed: () => onDelete(routine.id)),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDays(List<int> days) {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => names[d]).join(', ');
  }
}

class _RunTab extends StatelessWidget {
  final RoutineBuilderService service;
  final DateTime date;
  final void Function(String routineId, String stepId) onComplete;
  final void Function(String routineId, String stepId) onSkip;
  const _RunTab({required this.service, required this.date, required this.onComplete, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final runs = service.getRunsForDate(date);
    if (runs.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.play_circle_outline, size: 64, color: Colors.grey), SizedBox(height: 16), Text('No active runs today.', style: TextStyle(color: Colors.grey)), SizedBox(height: 8), Text('Go to Today tab and start a routine.', style: TextStyle(color: Colors.grey, fontSize: 12))]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: runs.length,
      itemBuilder: (ctx, i) {
        final run = runs[i];
        final routine = service.getRoutine(run.routineId);
        if (routine == null) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: run.isFinished ? Colors.green.shade50 : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(children: [
                Text(routine.emoji ?? '📋', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(routine.name, style: Theme.of(context).textTheme.titleMedium),
                  Text(run.isFinished ? '✅ Completed!' : '${run.completedCount}/${run.stepCompletions.length} steps done', style: TextStyle(color: run.isFinished ? Colors.green : null)),
                ])),
                SizedBox(width: 48, height: 48, child: Stack(fit: StackFit.expand, children: [
                  CircularProgressIndicator(value: run.completionRatio, strokeWidth: 4, backgroundColor: Colors.grey.shade300, color: run.isFinished ? Colors.green : null),
                  Center(child: Text('${(run.completionRatio * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ])),
              ]),
            ),
            ...List.generate(run.stepCompletions.length, (si) {
              final sc = run.stepCompletions[si];
              final step = routine.steps.firstWhere((s) => s.id == sc.stepId, orElse: () => RoutineStep(id: sc.stepId, name: 'Unknown', order: si));
              final isActive = sc.status == StepStatus.pending && !run.isFinished;
              return ListTile(
                leading: Icon(
                  sc.status == StepStatus.completed ? Icons.check_circle : sc.status == StepStatus.skipped ? Icons.skip_next : Icons.radio_button_unchecked,
                  color: sc.status == StepStatus.completed ? Colors.green : sc.status == StepStatus.skipped ? Colors.orange : Colors.grey,
                ),
                title: Text('${step.emoji ?? ''} ${step.name}', style: TextStyle(decoration: sc.status != StepStatus.pending ? TextDecoration.lineThrough : null, color: sc.status == StepStatus.skipped ? Colors.grey : null)),
                subtitle: Text('${step.durationMinutes}m${step.isOptional ? ' · optional' : ''}${sc.note != null ? ' · ${sc.note}' : ''}'),
                trailing: isActive ? Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.check, color: Colors.green), tooltip: 'Complete', onPressed: () => onComplete(run.routineId, sc.stepId)),
                  IconButton(icon: const Icon(Icons.skip_next, color: Colors.orange), tooltip: 'Skip', onPressed: () => onSkip(run.routineId, sc.stepId)),
                ]) : null,
              );
            }),
          ]),
        );
      },
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  final RoutineBuilderService service;
  const _AnalyticsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final routines = service.routines;
    if (routines.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.analytics_outlined, size: 64, color: Colors.grey), SizedBox(height: 16), Text('Add routines and start running them to see analytics.', style: TextStyle(color: Colors.grey))]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: routines.length,
      itemBuilder: (ctx, i) {
        final routine = routines[i];
        final analytics = service.getAnalytics(routine.id);
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(routine.emoji ?? '📋', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(child: Text(routine.name, style: Theme.of(context).textTheme.titleMedium)),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 16, runSpacing: 8, children: [
              _AnalyticsStat(label: 'Total Runs', value: '${analytics.totalRuns}', icon: Icons.replay),
              _AnalyticsStat(label: 'Completed', value: '${analytics.fullyCompletedRuns}', icon: Icons.check_circle, color: Colors.green),
              _AnalyticsStat(label: 'Completion', value: '${(analytics.completionRate * 100).round()}%', icon: Icons.pie_chart, color: analytics.completionRate >= 0.8 ? Colors.green : analytics.completionRate >= 0.5 ? Colors.orange : Colors.red),
              _AnalyticsStat(label: 'Avg Duration', value: analytics.averageDurationMinutes > 0 ? '${analytics.averageDurationMinutes.round()}m' : '--', icon: Icons.timer),
              _AnalyticsStat(label: 'Current Streak', value: '${analytics.currentStreak}🔥', icon: Icons.local_fire_department, color: Colors.deepOrange),
              _AnalyticsStat(label: 'Best Streak', value: '${analytics.longestStreak}', icon: Icons.emoji_events, color: Colors.amber),
            ]),
            if (analytics.mostSkippedStep != null || analytics.slowestStep != null) ...[
              const Divider(height: 24),
              if (analytics.mostSkippedStep != null) _InsightRow(icon: Icons.skip_next, color: Colors.orange, label: 'Most Skipped', value: _stepName(routine, analytics.mostSkippedStep!)),
              if (analytics.slowestStep != null) _InsightRow(icon: Icons.slow_motion_video, color: Colors.red, label: 'Slowest Step', value: _stepName(routine, analytics.slowestStep!)),
            ],
            if (analytics.totalRuns == 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Start running this routine to see analytics', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic))),
          ])),
        );
      },
    );
  }

  String _stepName(Routine routine, String stepId) {
    try { return routine.steps.firstWhere((s) => s.id == stepId).name; } catch (_) { return stepId; }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: const TextStyle(fontSize: 10)),
        ]),
      ]),
    ));
  }
}

class _AnalyticsStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const _AnalyticsStat({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, size: 20, color: color ?? Colors.grey),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]);
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _InsightRow({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
      Expanded(child: Text(value)),
    ]));
  }
}
