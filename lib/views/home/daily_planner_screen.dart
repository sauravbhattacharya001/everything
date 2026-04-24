import 'package:flutter/material.dart';

/// Smart Daily Planner — autonomous schedule optimizer with time blocking,
/// energy-aware scheduling, automatic breaks, and proactive insights.
class DailyPlannerScreen extends StatefulWidget {
  const DailyPlannerScreen({super.key});

  @override
  State<DailyPlannerScreen> createState() => _DailyPlannerScreenState();
}

// ── Data models ──

enum EnergyLevel { high, medium, low }

extension EnergyLevelX on EnergyLevel {
  String get label => name[0].toUpperCase() + name.substring(1);
  Color get color {
    switch (this) {
      case EnergyLevel.high:
        return const Color(0xFFEF5350);
      case EnergyLevel.medium:
        return const Color(0xFFFFCA28);
      case EnergyLevel.low:
        return const Color(0xFF66BB6A);
    }
  }

  IconData get icon {
    switch (this) {
      case EnergyLevel.high:
        return Icons.bolt;
      case EnergyLevel.medium:
        return Icons.trending_flat;
      case EnergyLevel.low:
        return Icons.nightlight_round;
    }
  }
}

class PlannerTask {
  final String id;
  String name;
  int durationMinutes;
  int priority; // 1-5 (5 = highest)
  EnergyLevel energyNeeded;

  PlannerTask({
    String? id,
    required this.name,
    required this.durationMinutes,
    this.priority = 3,
    this.energyNeeded = EnergyLevel.medium,
  }) : id = id ?? UniqueKey().toString();
}

class TimeBlock {
  final int startMinute; // minutes from midnight
  final int endMinute;
  final String label;
  final Color color;
  final bool isBreak;
  final bool isLunch;
  final PlannerTask? task;

  const TimeBlock({
    required this.startMinute,
    required this.endMinute,
    required this.label,
    required this.color,
    this.isBreak = false,
    this.isLunch = false,
    this.task,
  });

  int get durationMinutes => endMinute - startMinute;
  String get startTimeStr => _minutesToTime(startMinute);
  String get endTimeStr => _minutesToTime(endMinute);

  static String _minutesToTime(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${hour.toString()}:${min.toString().padLeft(2, '0')} $period';
  }
}

class _DailyPlannerScreenState extends State<DailyPlannerScreen> {
  final List<PlannerTask> _tasks = [];
  List<TimeBlock> _schedule = [];
  List<String> _insights = [];
  bool _scheduled = false;

  // Schedule config
  static const int _dayStartMinute = 6 * 60; // 6 AM
  static const int _dayEndMinute = 23 * 60; // 11 PM
  static const int _lunchStartMinute = 12 * 60;
  static const int _lunchEndMinute = 13 * 60;
  static const int _breakDuration = 15;
  static const int _workBlockBeforeBreak = 90;

  // Energy curve: relative energy 0.0-1.0 for each hour 6-22
  static const List<double> _energyCurve = [
    0.4, 0.6, 0.85, 0.95, 1.0, 0.9, // 6-11 AM
    0.5, // noon (lunch dip)
    0.55, 0.65, 0.7, 0.65, 0.55, // 1-5 PM
    0.45, 0.35, 0.3, 0.25, 0.2, // 6-10 PM
  ];

  double _energyAtMinute(int minute) {
    final hour = (minute ~/ 60).clamp(6, 22);
    final idx = hour - 6;
    if (idx < 0 || idx >= _energyCurve.length) return 0.2;
    return _energyCurve[idx];
  }

  EnergyLevel _energyLevelAtMinute(int minute) {
    final e = _energyAtMinute(minute);
    if (e >= 0.7) return EnergyLevel.high;
    if (e >= 0.45) return EnergyLevel.medium;
    return EnergyLevel.low;
  }

  void _addTask() {
    final nameCtrl = TextEditingController();
    int duration = 30;
    int priority = 3;
    EnergyLevel energy = EnergyLevel.medium;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Task name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: duration,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 min')),
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                    DropdownMenuItem(value: 45, child: Text('45 min')),
                    DropdownMenuItem(value: 60, child: Text('1 hour')),
                    DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                    DropdownMenuItem(value: 120, child: Text('2 hours')),
                  ],
                  onChanged: (v) => setDlgState(() => duration = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Priority: '),
                    Expanded(
                      child: Slider(
                        value: priority.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: '$priority',
                        onChanged: (v) =>
                            setDlgState(() => priority = v.round()),
                      ),
                    ),
                    Text('$priority',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<EnergyLevel>(
                  segments: EnergyLevel.values
                      .map((e) => ButtonSegment(
                            value: e,
                            label: Text(e.label),
                            icon: Icon(e.icon),
                          ))
                      .toList(),
                  selected: {energy},
                  onSelectionChanged: (s) =>
                      setDlgState(() => energy = s.first),
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
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _tasks.add(PlannerTask(
                    name: nameCtrl.text.trim(),
                    durationMinutes: duration,
                    priority: priority,
                    energyNeeded: energy,
                  ));
                  _scheduled = false;
                  _schedule.clear();
                  _insights.clear();
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

  void _autoSchedule() {
    if (_tasks.isEmpty) return;

    final sorted = List<PlannerTask>.from(_tasks)
      ..sort((a, b) {
        // Sort by priority desc, then energy desc
        final pc = b.priority.compareTo(a.priority);
        if (pc != 0) return pc;
        return b.energyNeeded.index.compareTo(a.energyNeeded.index);
      });

    final blocks = <TimeBlock>[];
    final scheduled = <String>{};
    int cursor = _dayStartMinute;
    int workSinceBreak = 0;

    void addBreak() {
      if (cursor + _breakDuration > _dayEndMinute) return;
      blocks.add(TimeBlock(
        startMinute: cursor,
        endMinute: cursor + _breakDuration,
        label: '☕ Break',
        color: const Color(0xFF42A5F5),
        isBreak: true,
      ));
      cursor += _breakDuration;
      workSinceBreak = 0;
    }

    while (cursor < _dayEndMinute) {
      // Insert lunch
      if (cursor < _lunchEndMinute && cursor + 1 > _lunchStartMinute - 1) {
        if (cursor < _lunchStartMinute) {
          // Small gap before lunch — try to fit a short task
          final gap = _lunchStartMinute - cursor;
          final filler = sorted.where(
              (t) => !scheduled.contains(t.id) && t.durationMinutes <= gap);
          if (filler.isNotEmpty) {
            final t = filler.first;
            blocks.add(TimeBlock(
              startMinute: cursor,
              endMinute: cursor + t.durationMinutes,
              label: t.name,
              color: t.energyNeeded.color,
              task: t,
            ));
            scheduled.add(t.id);
            cursor += t.durationMinutes;
            workSinceBreak += t.durationMinutes;
          }
          if (cursor < _lunchStartMinute) cursor = _lunchStartMinute;
        }
        blocks.add(TimeBlock(
          startMinute: _lunchStartMinute,
          endMinute: _lunchEndMinute,
          label: '🍽️ Lunch Break',
          color: const Color(0xFF9E9E9E),
          isLunch: true,
        ));
        cursor = _lunchEndMinute;
        workSinceBreak = 0;
        continue;
      }

      // Need a break?
      if (workSinceBreak >= _workBlockBeforeBreak) {
        addBreak();
        continue;
      }

      // Find best matching task for current energy level
      final currentEnergy = _energyLevelAtMinute(cursor);
      final remaining = _dayEndMinute - cursor;

      // Try to match energy level first, then fall back
      PlannerTask? best;
      for (final energyPref in [
        currentEnergy,
        ...EnergyLevel.values.where((e) => e != currentEnergy)
      ]) {
        final candidates = sorted.where((t) =>
            !scheduled.contains(t.id) &&
            t.durationMinutes <= remaining &&
            t.energyNeeded == energyPref);
        if (candidates.isNotEmpty) {
          best = candidates.first;
          break;
        }
      }

      if (best == null) break; // No more tasks fit

      blocks.add(TimeBlock(
        startMinute: cursor,
        endMinute: cursor + best.durationMinutes,
        label: best.name,
        color: best.energyNeeded.color,
        task: best,
      ));
      scheduled.add(best.id);
      cursor += best.durationMinutes;
      workSinceBreak += best.durationMinutes;
    }

    // Generate insights
    final insights = <String>[];
    final unscheduledCount = _tasks.length - scheduled.length;
    if (unscheduledCount > 0) {
      insights.add(
          '⚠️ $unscheduledCount task${unscheduledCount > 1 ? 's' : ''} couldn\'t fit — consider reducing durations or extending your day.');
    }

    final totalWork = blocks
        .where((b) => !b.isBreak && !b.isLunch)
        .fold<int>(0, (sum, b) => sum + b.durationMinutes);
    final totalBreaks =
        blocks.where((b) => b.isBreak).fold<int>(0, (sum, b) => sum + b.durationMinutes);

    if (totalWork > 480) {
      insights.add(
          '🔥 Heavy day ahead (${(totalWork / 60).toStringAsFixed(1)}h of work). Make sure to take your breaks!');
    }

    final freeMinutes =
        (_dayEndMinute - _dayStartMinute) - totalWork - totalBreaks - 60;
    if (freeMinutes > 60) {
      insights.add(
          '💡 You have ${(freeMinutes / 60).toStringAsFixed(1)}h of unscheduled time — consider adding a learning or exercise block.');
    }

    final highEnergyInEvening = blocks.where((b) =>
        b.task?.energyNeeded == EnergyLevel.high && b.startMinute >= 17 * 60);
    if (highEnergyInEvening.isNotEmpty) {
      insights.add(
          '🌙 High-energy task scheduled in the evening — you might struggle with focus. Consider swapping with a morning slot.');
    }

    final morningLoad = blocks
        .where((b) =>
            !b.isBreak &&
            !b.isLunch &&
            b.startMinute >= 6 * 60 &&
            b.endMinute <= 12 * 60)
        .fold<int>(0, (sum, b) => sum + b.durationMinutes);
    if (morningLoad > 300) {
      insights.add(
          '⏰ Morning is packed (${(morningLoad / 60).toStringAsFixed(1)}h). Consider moving one task to the afternoon.');
    }

    if (insights.isEmpty) {
      insights.add('✅ Schedule looks well-balanced! Great mix of work and breaks.');
    }

    setState(() {
      _schedule = blocks;
      _insights = insights;
      _scheduled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Daily Planner'),
        actions: [
          if (_tasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'Auto-Schedule',
              onPressed: _autoSchedule,
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              setState(() {
                if (v == 'clear_schedule') {
                  _schedule.clear();
                  _insights.clear();
                  _scheduled = false;
                } else if (v == 'clear_all') {
                  _tasks.clear();
                  _schedule.clear();
                  _insights.clear();
                  _scheduled = false;
                }
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear_schedule', child: Text('Clear Schedule')),
              PopupMenuItem(value: 'clear_all', child: Text('Clear All')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
      body: _tasks.isEmpty ? _buildEmptyState() : _buildContent(theme),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_view_day, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No tasks yet',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text('Tap + to add tasks, then auto-schedule your day',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Energy curve
        _buildEnergyCurve(theme),
        const SizedBox(height: 16),

        // Stats bar
        if (_scheduled) ...[
          _buildStatsBar(theme),
          const SizedBox(height: 16),
        ],

        // Insights
        if (_insights.isNotEmpty) ...[
          _buildInsights(theme),
          const SizedBox(height: 16),
        ],

        // Schedule or task list
        if (_scheduled && _schedule.isNotEmpty) ...[
          Text('Schedule', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._schedule.map(_buildTimeBlock),
        ],

        const SizedBox(height: 16),
        Text('Tasks (${_tasks.length})', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._tasks.map((t) => _buildTaskCard(t, theme)),

        const SizedBox(height: 80), // FAB space
      ],
    );
  }

  Widget _buildEnergyCurve(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Energy Curve', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: CustomPaint(
                size: const Size(double.infinity, 60),
                painter: _EnergyCurvePainter(
                  curve: _energyCurve,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('6AM', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('12PM',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('6PM', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('11PM',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(ThemeData theme) {
    final totalWork = _schedule
        .where((b) => !b.isBreak && !b.isLunch)
        .fold<int>(0, (sum, b) => sum + b.durationMinutes);
    final breakCount = _schedule.where((b) => b.isBreak).length;
    final scheduledCount =
        _schedule.where((b) => b.task != null).map((b) => b.task!.id).toSet().length;
    final efficiency =
        _tasks.isEmpty ? 0 : ((scheduledCount / _tasks.length) * 100).round();

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('${(totalWork / 60).toStringAsFixed(1)}h', 'Work',
                Icons.work_outline),
            _statItem('$breakCount', 'Breaks', Icons.coffee),
            _statItem('$efficiency%', 'Scheduled', Icons.pie_chart_outline),
            _statItem(
                '${_tasks.length - scheduledCount}', 'Pending', Icons.pending),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInsights(ThemeData theme) {
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insights', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._insights.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(i, style: const TextStyle(fontSize: 13)),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBlock(TimeBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(block.startTimeStr,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          Expanded(
            child: Container(
              height: (block.durationMinutes * 0.6).clamp(28.0, 80.0),
              decoration: BoxDecoration(
                color: block.color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.left(
                    width: 4, color: block.color),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(block.label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                  if (block.durationMinutes >= 30)
                    Text('${block.durationMinutes} min',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(PlannerTask task, ThemeData theme) {
    final isScheduled =
        _scheduled && _schedule.any((b) => b.task?.id == task.id);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: task.energyNeeded.color.withOpacity(0.2),
          child: Icon(task.energyNeeded.icon, color: task.energyNeeded.color),
        ),
        title: Text(task.name),
        subtitle: Text(
            '${task.durationMinutes} min • Priority ${task.priority} • ${task.energyNeeded.label} energy'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isScheduled)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                setState(() {
                  _tasks.removeWhere((t) => t.id == task.id);
                  if (_tasks.isEmpty) {
                    _schedule.clear();
                    _insights.clear();
                    _scheduled = false;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a smooth energy curve.
class _EnergyCurvePainter extends CustomPainter {
  final List<double> curve;
  final Color color;

  _EnergyCurvePainter({required this.curve, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (curve.isEmpty) return;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.05)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < curve.length; i++) {
      final x = (i / (curve.length - 1)) * size.width;
      final y = size.height - (curve[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
