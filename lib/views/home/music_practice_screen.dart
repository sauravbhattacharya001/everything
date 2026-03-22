import 'package:flutter/material.dart';
import '../../core/services/music_practice_service.dart';

/// Music Practice Tracker — log sessions, track streaks, monitor progress.
class MusicPracticeScreen extends StatefulWidget {
  const MusicPracticeScreen({super.key});

  @override
  State<MusicPracticeScreen> createState() => _MusicPracticeScreenState();
}

class _MusicPracticeScreenState extends State<MusicPracticeScreen> {
  List<PracticeSession> _sessions = [];
  PracticeGoal _goal = const PracticeGoal();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await MusicPracticeService.loadSessions();
    final goal = await MusicPracticeService.loadGoal();
    setState(() {
      _sessions = sessions;
      if (goal != null) _goal = goal;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await MusicPracticeService.saveSessions(_sessions);
  }

  void _addSession() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddSessionSheet(
        onAdd: (session) {
          setState(() => _sessions.insert(0, session));
          _save();
        },
      ),
    );
  }

  void _deleteSession(int index) {
    final removed = _sessions[index];
    setState(() => _sessions.removeAt(index));
    _save();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${removed.instrument} session'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _sessions.insert(index, removed));
            _save();
          },
        ),
      ),
    );
  }

  void _editGoal() {
    final weeklyCtrl =
        TextEditingController(text: _goal.weeklyMinutes.toString());
    final dailyCtrl =
        TextEditingController(text: _goal.dailySessions.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Practice Goals'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weeklyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weekly target (minutes)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dailyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily sessions target',
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
              final goal = PracticeGoal(
                weeklyMinutes: int.tryParse(weeklyCtrl.text) ?? 300,
                dailySessions: int.tryParse(dailyCtrl.text) ?? 1,
              );
              setState(() => _goal = goal);
              MusicPracticeService.saveGoal(goal);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = MusicPracticeService.currentStreak(_sessions);
    final longest = MusicPracticeService.longestStreak(_sessions);
    final weekMins = MusicPracticeService.weeklyMinutes(_sessions);
    final totalMins = MusicPracticeService.totalMinutes(_sessions);
    final weeklyProgress =
        _goal.weeklyMinutes > 0 ? (weekMins / _goal.weeklyMinutes) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Practice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Set Goals',
            onPressed: _editGoal,
          ),
          if (_sessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'Breakdown',
              onPressed: _showBreakdown,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSession,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Stats Cards ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Weekly progress
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Weekly Progress',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '$weekMins / ${_goal.weeklyMinutes} min',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: weeklyProgress.clamp(0.0, 1.0),
                                    minHeight: 10,
                                    backgroundColor: Colors.grey[200],
                                  ),
                                ),
                                if (weeklyProgress >= 1.0)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      '🎉 Weekly goal reached!',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Quick stats row
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Streak',
                                value: '$streak day${streak != 1 ? 's' : ''}',
                                icon: Icons.local_fire_department,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatCard(
                                label: 'Best',
                                value:
                                    '$longest day${longest != 1 ? 's' : ''}',
                                icon: Icons.emoji_events,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatCard(
                                label: 'Total',
                                value: _formatTotal(totalMins),
                                icon: Icons.music_note,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Session List ──
                if (_sessions.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.music_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No practice sessions yet',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap + to log your first session',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final s = _sessions[index];
                        return Dismissible(
                          key: Key(s.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteSession(index),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Colors.deepPurple.withOpacity(0.1),
                              child: const Icon(Icons.music_note,
                                  color: Colors.deepPurple),
                            ),
                            title: Text(
                              '${s.instrument} — ${s.category}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${s.durationMinutes} min • ${_formatDate(s.date)}'
                              '${s.notes != null && s.notes!.isNotEmpty ? ' • ${s.notes}' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < s.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _sessions.length,
                    ),
                  ),
              ],
            ),
    );
  }

  void _showBreakdown() {
    final byInstrument =
        MusicPracticeService.minutesByInstrument(_sessions);
    final byCategory = MusicPracticeService.minutesByCategory(_sessions);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('By Instrument',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...byInstrument.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key),
                      Text('${e.value} min',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            const Text('By Category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...byCategory.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key),
                      Text('${e.value} min',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatTotal(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${d.month}/${d.day}/${d.year}';
  }
}

// ── Stat Card Widget ──

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ── Add Session Sheet ──

class _AddSessionSheet extends StatefulWidget {
  final ValueChanged<PracticeSession> onAdd;
  const _AddSessionSheet({required this.onAdd});

  @override
  State<_AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<_AddSessionSheet> {
  String _instrument = MusicPracticeService.instruments.first;
  String _category = MusicPracticeService.categories.first;
  final _durationCtrl = TextEditingController(text: '30');
  final _notesCtrl = TextEditingController();
  int _rating = 3;

  @override
  void dispose() {
    _durationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Log Practice Session',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Instrument
            DropdownButtonFormField<String>(
              value: _instrument,
              decoration: const InputDecoration(
                labelText: 'Instrument',
                border: OutlineInputBorder(),
              ),
              items: MusicPracticeService.instruments
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: (v) => setState(() => _instrument = v!),
            ),
            const SizedBox(height: 12),
            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Focus Area',
                border: OutlineInputBorder(),
              ),
              items: MusicPracticeService.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            // Duration
            TextField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Rating
            Row(
              children: [
                const Text('Quality: '),
                ...List.generate(
                  5,
                  (i) => IconButton(
                    icon: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => _rating = i + 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Notes
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Log Session'),
              onPressed: () {
                final mins = int.tryParse(_durationCtrl.text) ?? 30;
                if (mins <= 0) return;
                final session = PracticeSession(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  instrument: _instrument,
                  category: _category,
                  durationMinutes: mins,
                  date: DateTime.now(),
                  notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
                  rating: _rating,
                );
                widget.onAdd(session);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
