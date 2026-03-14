import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/chore_tracker_service.dart';
import '../../models/chore_entry.dart';

/// Chore Tracker screen — manage household chores, log completions,
/// track schedules, and view insights.
class ChoreTrackerScreen extends StatefulWidget {
  const ChoreTrackerScreen({super.key});

  @override
  State<ChoreTrackerScreen> createState() => _ChoreTrackerScreenState();
}

class _ChoreTrackerScreenState extends State<ChoreTrackerScreen>
    with SingleTickerProviderStateMixin {
  static const _choresKey = 'chore_tracker_chores';
  static const _completionsKey = 'chore_tracker_completions';
  final ChoreTrackerService _service = const ChoreTrackerService();
  late TabController _tabController;
  final List<Chore> _chores = [];
  final List<ChoreCompletion> _completions = [];
  int _nextChoreId = 1;
  int _nextCompId = 1;
  ChoreRoom? _filterRoom;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final choresJson = prefs.getString(_choresKey);
    final compsJson = prefs.getString(_completionsKey);
    if (choresJson != null && choresJson.isNotEmpty) {
      try {
        final chores = (jsonDecode(choresJson) as List)
            .map((e) => Chore.fromJson(e as Map<String, dynamic>))
            .toList();
        final comps = compsJson != null && compsJson.isNotEmpty
            ? (jsonDecode(compsJson) as List)
                .map((e) => ChoreCompletion.fromJson(e as Map<String, dynamic>))
                .toList()
            : <ChoreCompletion>[];
        if (mounted) {
          setState(() {
            _chores.addAll(chores);
            _completions.addAll(comps);
            _nextChoreId = _chores.length + 1;
            _nextCompId = _completions.length + 1;
          });
          _saveData();
        }
      } catch (_) {}
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_choresKey,
        jsonEncode(_chores.map((c) => c.toJson()).toList()));
    await prefs.setString(_completionsKey,
        jsonEncode(_completions.map((c) => c.toJson()).toList()));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Chore> get _filteredChores {
    return _chores.where((c) {
      if (!_showArchived && c.archived) return false;
      if (_filterRoom != null && c.room != _filterRoom) return false;
      return true;
    }).toList();
  }

  List<Chore> get _activeChores =>
      _chores.where((c) => !c.archived).toList();

  void _addChore(Chore chore) {
    setState(() => _chores.add(chore));
    _saveData();
  }

  void _toggleArchive(int index) {
    setState(() {
      final c = _chores[index];
      _chores[index] = c.copyWith(archived: !c.archived);
    });
    _saveData();
  }

  void _logCompletion(String choreId, {int duration = 0, int rating = 3, String? note}) {
    setState(() {
      _completions.add(ChoreCompletion(
        id: 'comp${_nextCompId++}',
        choreId: choreId,
        completedAt: DateTime.now(),
        durationMinutes: duration,
        rating: rating,
        note: note,
      ));
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Chore completed!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chore Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.checklist), text: 'Chores'),
            Tab(icon: Icon(Icons.add_task), text: 'Add'),
            Tab(icon: Icon(Icons.schedule), text: 'Schedule'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChoresTab(),
          _buildAddTab(),
          _buildScheduleTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  // ─── Chores Tab ───────────────────────────────────────────────────

  Widget _buildChoresTab() {
    final sorted = _service.sortByUrgency(_filteredChores, _completions);
    return Column(
      children: [
        // Room filter chips
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _filterRoom == null,
                onSelected: (_) => setState(() => _filterRoom = null),
              ),
              const SizedBox(width: 6),
              ...ChoreRoom.values.map((room) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text('${room.emoji} ${room.label}'),
                  selected: _filterRoom == room,
                  onSelected: (_) => setState(() =>
                      _filterRoom = _filterRoom == room ? null : room),
                ),
              )),
            ],
          ),
        ),
        // Show archived toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('${sorted.length} chores',
                  style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              TextButton.icon(
                icon: Icon(_showArchived ? Icons.visibility_off : Icons.visibility,
                    size: 16),
                label: Text(_showArchived ? 'Hide archived' : 'Show archived'),
                onPressed: () => setState(() => _showArchived = !_showArchived),
              ),
            ],
          ),
        ),
        Expanded(
          child: sorted.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cleaning_services, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No chores yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                      Text('Add some in the Add tab',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: sorted.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    final chore = sorted[index];
                    return _buildChoreCard(chore);
                  },
                ),
        ),
      ],
    );
    _saveData();
  }

  Widget _buildChoreCard(Chore chore) {
    final overdue = _service.isOverdue(chore, _completions);
    final daysDue = _service.daysUntilDue(chore, _completions);
    final streak = _service.currentStreak(chore, _completions);
    final last = _service.lastCompletion(chore.id, _completions);

    String statusText;
    Color statusColor;
    if (chore.frequency == ChoreFrequency.asNeeded) {
      statusText = 'As needed';
      statusColor = Colors.grey;
    } else if (overdue) {
      statusText = 'Overdue${daysDue < 0 ? " by ${-daysDue}d" : ""}';
      statusColor = Colors.red;
    } else if (daysDue <= 1) {
      statusText = 'Due today';
      statusColor = Colors.orange;
    } else {
      statusText = 'Due in ${daysDue}d';
      statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: chore.archived ? Colors.grey.shade100 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Text(chore.room.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          chore.name,
          style: TextStyle(
            decoration: chore.archived ? TextDecoration.lineThrough : null,
            fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusText,
                      style: TextStyle(fontSize: 11, color: statusColor)),
                ),
                const SizedBox(width: 8),
                Text(chore.effort.emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(chore.frequency.label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            if (streak > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('🔥 $streak streak',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.orange)),
              ),
            if (chore.assignee != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('👤 ${chore.assignee}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!chore.archived)
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                tooltip: 'Mark done',
                onPressed: () => _showCompleteDialog(chore),
              ),
            PopupMenuButton<String>(
              onSelected: (val) {
                final idx = _chores.indexWhere((c) => c.id == chore.id);
                if (idx < 0) return;
                if (val == 'archive') _toggleArchive(idx);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'archive',
                  child: Text(chore.archived ? 'Unarchive' : 'Archive'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteDialog(Chore chore) {
    int rating = 3;
    int duration = chore.effort.estimatedMinutes;
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Complete: ${chore.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How long did it take?'),
              Slider(
                value: duration.toDouble(),
                min: 1,
                max: 120,
                divisions: 23,
                label: '$duration min',
                onChanged: (v) =>
                    setDialogState(() => duration = v.round()),
              ),
              const SizedBox(height: 8),
              const Text('How was it?'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    icon: Icon(
                      star <= rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () =>
                        setDialogState(() => rating = star),
                  );
                }),
              ),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
                _logCompletion(chore.id,
                    duration: duration,
                    rating: rating,
                    note: noteCtrl.text.isEmpty ? null : noteCtrl.text);
                Navigator.pop(ctx);
              },
              child: const Text('Done ✅'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Add Tab ──────────────────────────────────────────────────────

  Widget _buildAddTab() {
    return _AddChoreForm(
      onAdd: (chore) {
        _addChore(chore);
        _tabController.animateTo(0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${chore.name}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      nextId: _nextChoreId++,
    );
  }

  // ─── Schedule Tab ─────────────────────────────────────────────────

  Widget _buildScheduleTab() {
    final active = _activeChores;
    if (active.isEmpty) {
      return const Center(
        child: Text('Add chores to see your schedule',
            style: TextStyle(color: Colors.grey)),
      );
    }

    // Group by urgency
    final overdue = <Chore>[];
    final dueToday = <Chore>[];
    final upcoming = <Chore>[];
    final ok = <Chore>[];

    for (final chore in active) {
      if (chore.frequency == ChoreFrequency.asNeeded) {
        ok.add(chore);
        continue;
      }
      final days = _service.daysUntilDue(chore, _completions);
      if (days < 0) {
        overdue.add(chore);
      } else if (days == 0) {
        dueToday.add(chore);
      } else if (days <= 3) {
        upcoming.add(chore);
      } else {
        ok.add(chore);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (overdue.isNotEmpty) ...[
          _sectionHeader('🔴 Overdue', overdue.length, Colors.red),
          ...overdue.map((c) => _scheduleItem(c, Colors.red)),
          const SizedBox(height: 16),
        ],
        if (dueToday.isNotEmpty) ...[
          _sectionHeader('🟠 Due Today', dueToday.length, Colors.orange),
          ...dueToday.map((c) => _scheduleItem(c, Colors.orange)),
          const SizedBox(height: 16),
        ],
        if (upcoming.isNotEmpty) ...[
          _sectionHeader('🟡 Upcoming (1-3 days)', upcoming.length,
              Colors.amber),
          ...upcoming.map((c) => _scheduleItem(c, Colors.amber)),
          const SizedBox(height: 16),
        ],
        if (ok.isNotEmpty) ...[
          _sectionHeader('🟢 On Track', ok.length, Colors.green),
          ...ok.map((c) => _scheduleItem(c, Colors.green)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count',
                style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _scheduleItem(Chore chore, Color color) {
    final days = _service.daysUntilDue(chore, _completions);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Text(chore.room.emoji, style: const TextStyle(fontSize: 20)),
        title: Text(chore.name),
        subtitle: Text(
            '${chore.frequency.label} • ${chore.effort.emoji} ${chore.effort.label}'),
        trailing: days < 0
            ? Text('${-days}d overdue',
                style: TextStyle(color: color, fontWeight: FontWeight.bold))
            : Text('${days}d',
                style: TextStyle(color: color)),
      ),
    );
  }

  // ─── Insights Tab ─────────────────────────────────────────────────

  Widget _buildInsightsTab() {
    final active = _activeChores;
    if (active.isEmpty) {
      return const Center(
        child: Text('Add chores to see insights',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final grade = _service.overallGrade(active, _completions, 30);
    final weekMap = _service.weeklyCompletionMap(_completions);
    final totalWeek = weekMap.values.fold(0, (a, b) => a + b);
    final tips = _service.recommendations(active, _completions);
    final overdueCount =
        active.where((c) => _service.isOverdue(c, _completions)).length;
    final roomBreakdown = _service.completionsByRoom(
        active, _completions,
        DateTime.now().subtract(const Duration(days: 30)), DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Grade card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('30-Day Grade',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(grade,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _gradeColor(grade),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Summary strip
        Row(
          children: [
            _statChip('This Week', '$totalWeek done', Icons.check),
            const SizedBox(width: 8),
            _statChip('Overdue', '$overdueCount', Icons.warning,
                color: overdueCount > 0 ? Colors.red : Colors.green),
            const SizedBox(width: 8),
            _statChip('Active', '${active.length}', Icons.list),
          ],
        ),
        const SizedBox(height: 16),

        // Weekly chart
        const Text('This Week',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .asMap()
                .entries
                .map((e) {
              final dayNum = e.key + 1;
              final count = weekMap[dayNum] ?? 0;
              final maxCount =
                  weekMap.values.fold(1, (a, b) => a > b ? a : b);
              final height = maxCount > 0 ? (count / maxCount) * 70 : 0.0;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (count > 0)
                      Text('$count',
                          style: const TextStyle(fontSize: 10)),
                    Container(
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(e.value,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Room breakdown
        if (roomBreakdown.isNotEmpty) ...[
          const Text('By Room (30 days)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...roomBreakdown.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${e.key.emoji} ${e.key.label}'),
                    const Spacer(),
                    Text('${e.value}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Tips
        const Text('Recommendations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...tips.map((tip) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(tip)),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _statChip(String label, String value, IconData icon,
      {Color? color}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color ?? Colors.grey),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A': return Colors.green;
      case 'B': return Colors.lightGreen;
      case 'C': return Colors.orange;
      case 'D': return Colors.deepOrange;
      case 'F': return Colors.red;
      default: return Colors.grey;
    }
  }
}

// ─── Add Chore Form ──────────────────────────────────────────────────

class _AddChoreForm extends StatefulWidget {
  final void Function(Chore) onAdd;
  final int nextId;

  const _AddChoreForm({required this.onAdd, required this.nextId});

  @override
  State<_AddChoreForm> createState() => _AddChoreFormState();
}

class _AddChoreFormState extends State<_AddChoreForm> {
  final _nameCtrl = TextEditingController();
  final _assigneeCtrl = TextEditingController();
  ChoreRoom _room = ChoreRoom.general;
  ChoreFrequency _frequency = ChoreFrequency.weekly;
  ChoreEffort _effort = ChoreEffort.moderate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _assigneeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Chore Name',
            hintText: 'e.g., Vacuum living room',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.cleaning_services),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),

        // Room
        const Text('Room', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ChoreRoom.values.map((room) {
            return ChoiceChip(
              label: Text('${room.emoji} ${room.label}'),
              selected: _room == room,
              onSelected: (_) => setState(() => _room = room),
            );
            _saveData();
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Frequency
        const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ChoreFrequency.values.map((freq) {
            return ChoiceChip(
              label: Text(freq.label),
              selected: _frequency == freq,
              onSelected: (_) => setState(() => _frequency = freq),
            );
            _saveData();
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Effort
        const Text('Effort Level',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ChoreEffort.values.map((eff) {
            return ChoiceChip(
              label: Text('${eff.emoji} ${eff.label}'),
              selected: _effort == eff,
              onSelected: (_) => setState(() => _effort = eff),
            );
            _saveData();
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Assignee
        TextField(
          controller: _assigneeCtrl,
          decoration: const InputDecoration(
            labelText: 'Assigned To (optional)',
            hintText: 'e.g., Mom, Dad, Kid',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 24),

        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Chore'),
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a chore name'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            widget.onAdd(Chore(
              id: 'chore${widget.nextId}',
              name: name,
              room: _room,
              frequency: _frequency,
              effort: _effort,
              assignee: _assigneeCtrl.text.trim().isEmpty
                  ? null
                  : _assigneeCtrl.text.trim(),
            ));
            _nameCtrl.clear();
            _assigneeCtrl.clear();
            setState(() {
              _room = ChoreRoom.general;
              _frequency = ChoreFrequency.weekly;
              _effort = ChoreEffort.moderate;
            });
            _saveData();
          },
        ),

        const SizedBox(height: 24),

        // Quick-add presets
        const Text('Quick Add Presets',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((p) {
            return ActionChip(
              avatar: Text(p.room.emoji),
              label: Text(p.name),
              onPressed: () {
                widget.onAdd(Chore(
                  id: 'chore${widget.nextId}',
                  name: p.name,
                  room: p.room,
                  frequency: p.frequency,
                  effort: p.effort,
                ));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  static final _presets = [
    const Chore(id: '', name: 'Vacuum floors', room: ChoreRoom.livingRoom,
        frequency: ChoreFrequency.weekly, effort: ChoreEffort.moderate),
    const Chore(id: '', name: 'Do dishes', room: ChoreRoom.kitchen,
        frequency: ChoreFrequency.daily, effort: ChoreEffort.quick),
    const Chore(id: '', name: 'Clean bathroom', room: ChoreRoom.bathroom,
        frequency: ChoreFrequency.weekly, effort: ChoreEffort.moderate),
    const Chore(id: '', name: 'Do laundry', room: ChoreRoom.laundry,
        frequency: ChoreFrequency.everyOtherDay, effort: ChoreEffort.moderate),
    const Chore(id: '', name: 'Mow lawn', room: ChoreRoom.yard,
        frequency: ChoreFrequency.weekly, effort: ChoreEffort.major),
    const Chore(id: '', name: 'Take out trash', room: ChoreRoom.kitchen,
        frequency: ChoreFrequency.everyOtherDay, effort: ChoreEffort.quick),
    const Chore(id: '', name: 'Change bed sheets', room: ChoreRoom.bedroom,
        frequency: ChoreFrequency.weekly, effort: ChoreEffort.moderate),
    const Chore(id: '', name: 'Clean gutters', room: ChoreRoom.yard,
        frequency: ChoreFrequency.quarterly, effort: ChoreEffort.major),
    const Chore(id: '', name: 'Organize desk', room: ChoreRoom.office,
        frequency: ChoreFrequency.monthly, effort: ChoreEffort.quick),
    const Chore(id: '', name: 'Wipe counters', room: ChoreRoom.kitchen,
        frequency: ChoreFrequency.daily, effort: ChoreEffort.quick),
  ];
}
