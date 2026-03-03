import 'package:flutter/material.dart';
import '../../core/services/habit_tracker_service.dart';
import '../../models/habit.dart';

/// Habit Tracker screen — view today's habits, check them off, see streaks,
/// and manage habit definitions.
class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen>
    with SingleTickerProviderStateMixin {
  late final HabitTrackerService _service;
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _service = HabitTrackerService(
      habits: _sampleHabits(),
      completions: [],
    );
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Habit> _sampleHabits() => [
        Habit(
          id: 'h1',
          name: 'Morning Exercise',
          emoji: '🏋️',
          frequency: HabitFrequency.weekdays,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Habit(
          id: 'h2',
          name: 'Read 30 minutes',
          emoji: '📖',
          frequency: HabitFrequency.daily,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        Habit(
          id: 'h3',
          name: 'Drink Water',
          emoji: '💧',
          frequency: HabitFrequency.daily,
          targetCount: 8,
          description: 'Drink 8 glasses of water',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ];

  void _toggleCompletion(String habitId) {
    setState(() {
      final comp = _service.getCompletions(habitId,
          from: _selectedDate, to: _selectedDate);
      if (comp.isEmpty) {
        _service.logCompletion(habitId, _selectedDate);
      } else {
        final habit = _service.allHabits.firstWhere((h) => h.id == habitId);
        if (comp.first.count < habit.targetCount) {
          _service.logCompletion(habitId, _selectedDate);
        } else {
          _service.removeCompletion(habitId, _selectedDate);
        }
      }
    });
  }

  void _changeDate(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
  }

  void _showAddHabitDialog() {
    final nameController = TextEditingController();
    final emojiController = TextEditingController();
    final descController = TextEditingController();
    var frequency = HabitFrequency.daily;
    var targetCount = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Habit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emojiController,
                  decoration: const InputDecoration(
                    labelText: 'Emoji',
                    hintText: '🎯',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Habit Name'),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration:
                      const InputDecoration(labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<HabitFrequency>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: HabitFrequency.values
                      .where((f) => f != HabitFrequency.custom)
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => frequency = v);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Daily target: '),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: targetCount > 1
                          ? () => setDialogState(() => targetCount--)
                          : null,
                    ),
                    Text('$targetCount',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setDialogState(() => targetCount++),
                    ),
                  ],
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
                if (nameController.text.trim().isEmpty) return;
                setState(() {
                  _service.addHabit(Habit(
                    id: 'h${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    emoji: emojiController.text.trim().isEmpty
                        ? '📌'
                        : emojiController.text.trim(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    frequency: frequency,
                    targetCount: targetCount,
                    createdAt: DateTime.now(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Today'),
            Tab(icon: Icon(Icons.insights), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildStatsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add habit',
      ),
    );
  }

  Widget _buildTodayTab() {
    final today = _selectedDate;
    final status = _service.todayStatus(referenceDate: today);
    final completedCount = status.where((s) => s.completed).length;
    final totalCount = status.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Column(
      children: [
        // Date navigation
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeDate(-1),
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Text(
                  _isToday(today)
                      ? 'Today'
                      : _isYesterday(today)
                          ? 'Yesterday'
                          : '${today.month}/${today.day}/${today.year}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: !_isToday(today) ? () => _changeDate(1) : null,
              ),
            ],
          ),
        ),

        // Progress ring
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        progress >= 1.0 ? Colors.green : Colors.blue,
                      ),
                    ),
                    Center(
                      child: Text(
                        '$completedCount/$totalCount',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progress >= 1.0
                    ? '🎉 All done!'
                    : '${(progress * 100).toInt()}% complete',
                style: TextStyle(
                  color: progress >= 1.0 ? Colors.green : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Habit list
        Expanded(
          child: status.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.weekend, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No habits scheduled',
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: status.length,
                  itemBuilder: (context, index) {
                    final s = status[index];
                    final isCountBased = s.target > 1;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () => _toggleCompletion(s.habit.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: s.completed
                                  ? Colors.green
                                  : Colors.grey[200],
                            ),
                            child: Center(
                              child: s.completed
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 24)
                                  : Text(
                                      s.habit.emoji ?? '📌',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                            ),
                          ),
                        ),
                        title: Text(
                          '${s.habit.emoji ?? ''} ${s.habit.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            decoration: s.completed
                                ? TextDecoration.lineThrough
                                : null,
                            color: s.completed ? Colors.grey : null,
                          ),
                        ),
                        subtitle: isCountBased
                            ? Text('${s.count}/${s.target}')
                            : s.habit.description != null
                                ? Text(s.habit.description!,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500]))
                                : null,
                        trailing: isCountBased
                            ? SizedBox(
                                width: 36,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () =>
                                          _toggleCompletion(s.habit.id),
                                      child: Icon(Icons.add_circle,
                                          color: s.completed
                                              ? Colors.green
                                              : Colors.blue),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                        onTap: () => _toggleCompletion(s.habit.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    final habits = _service.activeHabits;
    if (habits.isEmpty) {
      return const Center(child: Text('No habits to show stats for'));
    }

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Weekly summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This Week',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Builder(
                  builder: (_) {
                    final summary = _service.weeklySummary();
                    return Column(
                      children: [
                        _statRow('Overall Rate',
                            '${(summary.overallRate * 100).toInt()}%'),
                        _statRow(
                            'Perfect Days', '${summary.perfectDays}/7'),
                        _statRow(
                            'Habits Tracked', '${summary.totalHabits}'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Last 30 Days',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Per-habit stats
        ...habits.map((habit) {
          final stats = _service.getHabitStats(habit.id,
              from: thirtyDaysAgo, to: now);
          final rate = stats.completionRate;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(habit.emoji ?? '📌',
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(habit.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _rateColor(rate).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(rate * 100).toInt()}%',
                          style: TextStyle(
                            color: _rateColor(rate),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rate,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(_rateColor(rate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniStat('🔥 Streak', '${stats.currentStreak}'),
                      _miniStat('🏆 Best', '${stats.longestStreak}'),
                      _miniStat('✅ Done',
                          '${stats.completedDays}/${stats.scheduledDays}'),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Color _rateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.5) return Colors.orange;
    return Colors.red;
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isYesterday(DateTime d) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return d.year == y.year && d.month == y.month && d.day == y.day;
  }
}
