import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reason categories for procrastination.
enum ProcrastinationReason {
  perfectionism('Perfectionism', Icons.star, Color(0xFFE91E63)),
  overwhelm('Overwhelm', Icons.layers, Color(0xFF9C27B0)),
  boring('Boring', Icons.sentiment_dissatisfied, Color(0xFF607D8B)),
  fearOfFailure('Fear of Failure', Icons.warning_amber, Color(0xFFFF5722)),
  noDeadline('No Deadline', Icons.timer_off, Color(0xFF795548)),
  unclear('Unclear Task', Icons.help_outline, Color(0xFF2196F3)),
  distracted('Distracted', Icons.notifications_active, Color(0xFFFF9800)),
  tired('Too Tired', Icons.bedtime, Color(0xFF4CAF50));

  const ProcrastinationReason(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// Task category.
enum TaskCategory {
  work('Work', Icons.work),
  health('Health', Icons.favorite),
  learning('Learning', Icons.school),
  personal('Personal', Icons.person),
  chores('Chores', Icons.cleaning_services);

  const TaskCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// A single procrastination log entry.
class ProcrastinationEntry {
  ProcrastinationEntry({
    required this.id,
    required this.taskDescription,
    required this.scheduledTime,
    this.completionTime,
    required this.category,
    required this.reason,
    required this.delayMinutes,
    this.intervention,
    this.completed = false,
  });

  final String id;
  final String taskDescription;
  final DateTime scheduledTime;
  final DateTime? completionTime;
  final TaskCategory category;
  final ProcrastinationReason reason;
  final int delayMinutes;
  final String? intervention;
  final bool completed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskDescription': taskDescription,
        'scheduledTime': scheduledTime.toIso8601String(),
        'completionTime': completionTime?.toIso8601String(),
        'category': category.name,
        'reason': reason.name,
        'delayMinutes': delayMinutes,
        'intervention': intervention,
        'completed': completed,
      };

  factory ProcrastinationEntry.fromJson(Map<String, dynamic> json) {
    return ProcrastinationEntry(
      id: json['id'] as String,
      taskDescription: json['taskDescription'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      completionTime: json['completionTime'] != null
          ? DateTime.parse(json['completionTime'] as String)
          : null,
      category: TaskCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => TaskCategory.personal,
      ),
      reason: ProcrastinationReason.values.firstWhere(
        (r) => r.name == json['reason'],
        orElse: () => ProcrastinationReason.distracted,
      ),
      delayMinutes: json['delayMinutes'] as int? ?? 0,
      intervention: json['intervention'] as String?,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

/// Smart Procrastination Buster — autonomous procrastination pattern detection
/// with personalized interventions and proactive insights.
class ProcrastinationBusterScreen extends StatefulWidget {
  const ProcrastinationBusterScreen({super.key});

  @override
  State<ProcrastinationBusterScreen> createState() =>
      _ProcrastinationBusterScreenState();
}

class _ProcrastinationBusterScreenState
    extends State<ProcrastinationBusterScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'procrastination_entries';

  late TabController _tabController;
  List<ProcrastinationEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _entries = list
          .map((e) => ProcrastinationEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    setState(() => _loading = false);
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(_entries.map((e) => e.toJson()).toList()));
  }

  void _addEntry(ProcrastinationEntry entry) {
    setState(() => _entries.insert(0, entry));
    _saveEntries();
  }

  void _markCompleted(String id) {
    setState(() {
      final idx = _entries.indexWhere((e) => e.id == id);
      if (idx >= 0) {
        final old = _entries[idx];
        _entries[idx] = ProcrastinationEntry(
          id: old.id,
          taskDescription: old.taskDescription,
          scheduledTime: old.scheduledTime,
          completionTime: DateTime.now(),
          category: old.category,
          reason: old.reason,
          delayMinutes: old.delayMinutes,
          intervention: old.intervention,
          completed: true,
        );
      }
    });
    _saveEntries();
  }

  void _deleteEntry(String id) {
    setState(() => _entries.removeWhere((e) => e.id == id));
    _saveEntries();
  }

  // ── Score calculation ──
  double get _procrastinationScore {
    if (_entries.isEmpty) return 100.0;
    final recent = _entries
        .where((e) =>
            e.scheduledTime.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();
    if (recent.isEmpty) return 100.0;

    final completedCount = recent.where((e) => e.completed).length;
    final completionRate = completedCount / recent.length;
    final avgDelay = recent.isEmpty
        ? 0.0
        : recent.map((e) => e.delayMinutes).reduce((a, b) => a + b) /
            recent.length;
    final delayPenalty = (avgDelay / 120).clamp(0.0, 0.5);
    return ((completionRate * 0.6 + (1.0 - delayPenalty) * 0.4) * 100)
        .clamp(0, 100);
  }

  // ── Pattern analysis ──
  Map<ProcrastinationReason, int> get _reasonCounts {
    final counts = <ProcrastinationReason, int>{};
    for (final e in _entries) {
      counts[e.reason] = (counts[e.reason] ?? 0) + 1;
    }
    return counts;
  }

  Map<TaskCategory, double> get _avgDelayByCategory {
    final totals = <TaskCategory, List<int>>{};
    for (final e in _entries) {
      totals.putIfAbsent(e.category, () => []).add(e.delayMinutes);
    }
    return totals.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }

  String get _worstTimeOfDay {
    final hourCounts = <String, int>{'Morning': 0, 'Afternoon': 0, 'Evening': 0, 'Night': 0};
    for (final e in _entries) {
      final h = e.scheduledTime.hour;
      if (h >= 5 && h < 12) {
        hourCounts['Morning'] = hourCounts['Morning']! + 1;
      } else if (h >= 12 && h < 17) {
        hourCounts['Afternoon'] = hourCounts['Afternoon']! + 1;
      } else if (h >= 17 && h < 21) {
        hourCounts['Evening'] = hourCounts['Evening']! + 1;
      } else {
        hourCounts['Night'] = hourCounts['Night']! + 1;
      }
    }
    final sorted = hourCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  int get _streakDays {
    if (_entries.isEmpty) return 0;
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayEntries = _entries.where((e) =>
          e.scheduledTime.year == day.year &&
          e.scheduledTime.month == day.month &&
          e.scheduledTime.day == day.day);
      if (dayEntries.isEmpty) {
        if (i == 0) continue; // today might not have entries yet
        streak = i - 1;
        break;
      }
      final allCompleted = dayEntries.every((e) => e.completed);
      if (!allCompleted) {
        streak = i;
        break;
      }
      if (i == 364) streak = 365;
    }
    return streak;
  }

  List<String> get _proactiveInsights {
    final insights = <String>[];
    if (_entries.isEmpty) {
      insights.add('Start logging procrastination moments to unlock personalized insights.');
      return insights;
    }

    // Top reason insight
    final reasons = _reasonCounts;
    if (reasons.isNotEmpty) {
      final top = (reasons.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
      insights.add('${top.key.label} is your #1 procrastination trigger (${top.value} times). ${_interventionFor(top.key)}');
    }

    // Time-of-day insight
    if (_entries.length >= 3) {
      insights.add('You tend to procrastinate most in the $_worstTimeOfDay. Try scheduling tough tasks at other times.');
    }

    // Category insight
    final delays = _avgDelayByCategory;
    if (delays.isNotEmpty) {
      final worst = (delays.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
      insights.add('${worst.key.label} tasks have the highest average delay (${worst.value.round()} min). Consider breaking them into smaller steps.');
    }

    // Streak insight
    final streak = _streakDays;
    if (streak >= 3) {
      insights.add('🔥 Great streak! $streak days without major procrastination. Keep it going!');
    } else if (streak == 0 && _entries.length >= 5) {
      insights.add('⚡ Today is a fresh start. Log your first completed task to begin a new streak.');
    }

    // Completion rate
    final recent7 = _entries.where((e) =>
        e.scheduledTime.isAfter(DateTime.now().subtract(const Duration(days: 7))));
    if (recent7.length >= 3) {
      final rate = recent7.where((e) => e.completed).length / recent7.length;
      if (rate > 0.8) {
        insights.add('👏 ${(rate * 100).round()}% completion rate this week. You\'re crushing it!');
      } else if (rate < 0.4) {
        insights.add('📉 Only ${(rate * 100).round()}% completed this week. Try the "Just 5 Minutes" trick on your next task.');
      }
    }

    return insights;
  }

  String _interventionFor(ProcrastinationReason reason) {
    switch (reason) {
      case ProcrastinationReason.perfectionism:
        return 'Good enough is better than perfect. Set a 25-min timer and ship it.';
      case ProcrastinationReason.overwhelm:
        return 'Break it into 3 tiny steps. Do just step 1.';
      case ProcrastinationReason.boring:
        return 'Pair it with something you enjoy. Music? Coffee? Reward after?';
      case ProcrastinationReason.fearOfFailure:
        return 'What\'s the worst that actually happens? Usually nothing.';
      case ProcrastinationReason.noDeadline:
        return 'Create an artificial deadline: finish by ${TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2))).format(context)}.';
      case ProcrastinationReason.unclear:
        return 'Spend 5 minutes just defining what "done" looks like.';
      case ProcrastinationReason.distracted:
        return 'Put your phone in another room. Set a 25-min focus block.';
      case ProcrastinationReason.tired:
        return 'Take a 20-min power nap or walk first. Energy > willpower.';
    }
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procrastination Buster'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_task), text: 'Log'),
            Tab(icon: Icon(Icons.analytics), text: 'Patterns'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Strategies'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLogTab(theme),
                _buildPatternsTab(theme),
                _buildStrategiesTab(theme),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Log Tab ──
  Widget _buildLogTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Score gauge
        Center(child: _ScoreGauge(score: _procrastinationScore)),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Productivity Score',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 16),
        // Quick actions
        _buildQuickActions(theme),
        const SizedBox(height: 16),
        // Entry list
        if (_entries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.flash_on, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No entries yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Tap + to log a procrastination moment',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          ..._entries.take(20).map((e) => _buildEntryCard(e, theme)),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.timer, size: 18),
          label: const Text('5-Min Start'),
          onPressed: _startFiveMinTimer,
        ),
        ActionChip(
          avatar: const Icon(Icons.call_split, size: 18),
          label: const Text('Break It Down'),
          onPressed: _showBreakDownDialog,
        ),
        ActionChip(
          avatar: const Icon(Icons.people, size: 18),
          label: const Text('Body Double'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Virtual coworking session started! Focus for 25 minutes.')),
            );
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.card_giftcard, size: 18),
          label: const Text('Set Reward'),
          onPressed: _showRewardDialog,
        ),
      ],
    );
  }

  Widget _buildEntryCard(ProcrastinationEntry entry, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entry.reason.color.withValues(alpha: 0.2),
          child: Icon(entry.reason.icon, color: entry.reason.color, size: 20),
        ),
        title: Text(
          entry.taskDescription,
          style: TextStyle(
            decoration: entry.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${entry.category.label} · ${entry.reason.label} · ${entry.delayMinutes} min delay',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!entry.completed)
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                onPressed: () => _markCompleted(entry.id),
                tooltip: 'Mark done',
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteEntry(entry.id),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  // ── Patterns Tab ──
  Widget _buildPatternsTab(ThemeData theme) {
    if (_entries.isEmpty) {
      return const Center(child: Text('Log some entries to see patterns'));
    }

    final reasons = _reasonCounts;
    final maxCount = reasons.values.isEmpty ? 1 : reasons.values.reduce(max);
    final delays = _avgDelayByCategory;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Top Procrastination Reasons', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...(reasons.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Row(
                          children: [
                            Icon(e.key.icon, size: 16, color: e.key.color),
                            const SizedBox(width: 4),
                            Flexible(child: Text(e.key.label, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: e.value / maxCount,
                          backgroundColor: e.key.color.withValues(alpha: 0.1),
                          color: e.key.color,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${e.value}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                )),
        const SizedBox(height: 24),
        Text('Worst Time of Day', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(_timeIcon(_worstTimeOfDay), color: Colors.orange),
            title: Text(_worstTimeOfDay),
            subtitle: const Text('Most procrastination happens during this period'),
          ),
        ),
        const SizedBox(height: 24),
        Text('Average Delay by Category', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...(delays.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .map((e) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: Icon(e.key.icon),
                    title: Text(e.key.label),
                    trailing: Text('${e.value.round()} min avg',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: e.value > 60 ? Colors.red : e.value > 30 ? Colors.orange : Colors.green,
                        )),
                  ),
                )),
        const SizedBox(height: 24),
        Card(
          color: theme.colorScheme.primaryContainer,
          child: ListTile(
            leading: const Icon(Icons.local_fire_department, color: Colors.orange),
            title: Text('$_streakDays day streak'),
            subtitle: const Text('Days with all tasks completed'),
          ),
        ),
      ],
    );
  }

  IconData _timeIcon(String period) {
    switch (period) {
      case 'Morning': return Icons.wb_sunny;
      case 'Afternoon': return Icons.wb_cloudy;
      case 'Evening': return Icons.nights_stay;
      default: return Icons.dark_mode;
    }
  }

  // ── Strategies Tab ──
  Widget _buildStrategiesTab(ThemeData theme) {
    final insights = _proactiveInsights;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Proactive Insights', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...insights.map((insight) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(insight)),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 24),
        Text('Intervention Playbook', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...ProcrastinationReason.values.map((reason) => ExpansionTile(
              leading: Icon(reason.icon, color: reason.color),
              title: Text(reason.label),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(_interventionFor(reason),
                      style: theme.textTheme.bodyMedium),
                ),
              ],
            )),
      ],
    );
  }

  // ── Dialogs ──

  void _showAddEntryDialog() {
    final taskController = TextEditingController();
    var selectedCategory = TaskCategory.work;
    var selectedReason = ProcrastinationReason.distracted;
    var delayMinutes = 30;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Log Procrastination'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: taskController,
                  decoration: const InputDecoration(
                    labelText: 'What are you procrastinating on?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Category'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: TaskCategory.values
                      .map((c) => ChoiceChip(
                            label: Text(c.label),
                            selected: selectedCategory == c,
                            onSelected: (_) => setDialogState(() => selectedCategory = c),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text('Why are you procrastinating?'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ProcrastinationReason.values
                      .map((r) => ChoiceChip(
                            avatar: Icon(r.icon, size: 16, color: r.color),
                            label: Text(r.label),
                            selected: selectedReason == r,
                            onSelected: (_) => setDialogState(() => selectedReason = r),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Text('Delay so far: $delayMinutes min'),
                Slider(
                  value: delayMinutes.toDouble(),
                  min: 5,
                  max: 240,
                  divisions: 47,
                  label: '$delayMinutes min',
                  onChanged: (v) => setDialogState(() => delayMinutes = v.round()),
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
                if (taskController.text.trim().isEmpty) return;
                _addEntry(ProcrastinationEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  taskDescription: taskController.text.trim(),
                  scheduledTime: DateTime.now(),
                  category: selectedCategory,
                  reason: selectedReason,
                  delayMinutes: delayMinutes,
                ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logged! ${_interventionFor(selectedReason)}')),
                );
              },
              child: const Text('Log It'),
            ),
          ],
        ),
      ),
    );
  }

  void _startFiveMinTimer() {
    showDialog(
      context: context,
      builder: (ctx) => _FiveMinTimerDialog(),
    );
  }

  void _showBreakDownDialog() {
    final steps = [TextEditingController(), TextEditingController(), TextEditingController()];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Break It Down'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Split your task into 3 tiny steps:'),
            const SizedBox(height: 12),
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: steps[i],
                  decoration: InputDecoration(
                    labelText: 'Step ${i + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Now do just Step 1. Nothing else. Go!')),
              );
            },
            child: const Text('Start Step 1'),
          ),
        ],
      ),
    );
  }

  void _showRewardDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Your Reward'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'What will you treat yourself to?',
            hintText: 'e.g., Coffee break, YouTube video, Snack...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (controller.text.trim().isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reward set: ${controller.text.trim()}. Now earn it! 💪')),
                );
              }
            },
            child: const Text('Set Reward'),
          ),
        ],
      ),
    );
  }
}

/// Animated circular score gauge.
class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? Colors.green
        : score >= 40
            ? Colors.orange
            : Colors.red;
    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(
        painter: _GaugePainter(score: score, color: color),
        child: Center(
          child: Text(
            '${score.round()}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.score, required this.color});
  final double score;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = 2.3562; // 135 degrees
    const sweepTotal = 4.7124; // 270 degrees

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = color.withValues(alpha: 0.15)
        ..strokeCap = StrokeCap.round,
    );

    // Score arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * (score / 100),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.score != score || old.color != color;
}

/// Simple 5-minute countdown timer dialog.
class _FiveMinTimerDialog extends StatefulWidget {
  @override
  State<_FiveMinTimerDialog> createState() => _FiveMinTimerDialogState();
}

class _FiveMinTimerDialogState extends State<_FiveMinTimerDialog> {
  int _seconds = 300;
  bool _running = false;

  void _toggle() {
    if (_running) {
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _tick();
    }
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_running) return;
      setState(() {
        _seconds--;
        if (_seconds <= 0) {
          _running = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('5 minutes done! Want to keep going? 🚀')),
          );
          Navigator.pop(context);
          return;
        }
      });
      if (_running) _tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final min = _seconds ~/ 60;
    final sec = _seconds % 60;
    return AlertDialog(
      title: const Text('Just 5 Minutes'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Commit to just 5 minutes. You can stop after.'),
          const SizedBox(height: 24),
          Text(
            '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _toggle,
          child: Text(_running ? 'Pause' : 'Start'),
        ),
      ],
    );
  }
}
