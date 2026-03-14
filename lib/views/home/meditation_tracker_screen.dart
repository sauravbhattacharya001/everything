import 'package:flutter/material.dart';
import '../../core/services/meditation_tracker_service.dart';
import '../../models/meditation_entry.dart';

/// Meditation Tracker screen for logging sessions, viewing history,
/// and exploring mood insights across meditation techniques.
class MeditationTrackerScreen extends StatefulWidget {
  const MeditationTrackerScreen({super.key});

  @override
  State<MeditationTrackerScreen> createState() =>
      _MeditationTrackerScreenState();
}

class _MeditationTrackerScreenState extends State<MeditationTrackerScreen>
    with SingleTickerProviderStateMixin {
  final MeditationTrackerService _service = MeditationTrackerService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('\u{1F9D8} Meditation'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Log'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LogTab(service: _service, onLogged: () => setState(() {})),
          _HistoryTab(service: _service, onChanged: () => setState(() {})),
          _InsightsTab(service: _service),
        ],
      ),
    );
  }
}

// ─── LOG TAB ────────────────────────────────────────────────────────────────

class _LogTab extends StatefulWidget {
  final MeditationTrackerService service;
  final VoidCallback onLogged;

  const _LogTab({required this.service, required this.onLogged});

  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  MeditationType _selectedType = MeditationType.mindfulness;
  double _durationMinutes = 10;
  int? _preMood;
  int? _postMood;
  String _note = '';
  String _guideName = '';
  bool _interrupted = false;

  void _logSession() {
    final entry = MeditationEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateTime: DateTime.now(),
      durationMinutes: _durationMinutes.round(),
      type: _selectedType,
      preMood: _preMood,
      postMood: _postMood,
      note: _note.isNotEmpty ? _note : null,
      guideName: _guideName.isNotEmpty ? _guideName : null,
      interrupted: _interrupted,
    );

    widget.service.addSession(entry);
    widget.onLogged();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedType.emoji} ${_durationMinutes.round()} min session logged!',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      _durationMinutes = 10;
      _preMood = null;
      _postMood = null;
      _note = '';
      _guideName = '';
      _interrupted = false;
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
          // ── Technique Picker ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Technique', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MeditationType.values.map((type) {
                      final selected = type == _selectedType;
                      return ChoiceChip(
                        label: Text('${type.emoji} ${type.label}'),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedType = type),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Duration Slider ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duration', style: theme.textTheme.titleMedium),
                      Text(
                        '${_durationMinutes.round()} min',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _durationMinutes,
                    min: 1,
                    max: 120,
                    divisions: 119,
                    label: '${_durationMinutes.round()} min',
                    onChanged: (v) => setState(() => _durationMinutes = v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [5, 10, 15, 20, 30, 45, 60].map((m) {
                      return TextButton(
                        onPressed: () =>
                            setState(() => _durationMinutes = m.toDouble()),
                        child: Text('$m'),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Mood Before / After ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mood Check', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _MoodRow(
                    label: 'Before',
                    value: _preMood,
                    onChanged: (v) => setState(() => _preMood = v),
                  ),
                  const SizedBox(height: 8),
                  _MoodRow(
                    label: 'After',
                    value: _postMood,
                    onChanged: (v) => setState(() => _postMood = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Optional Fields ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Guide / App (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onChanged: (v) => _guideName = v,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                    onChanged: (v) => _note = v,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Session interrupted?'),
                    subtitle: const Text('Mark if you couldn\'t finish'),
                    value: _interrupted,
                    onChanged: (v) => setState(() => _interrupted = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Submit ──
          FilledButton.icon(
            onPressed: _logSession,
            icon: const Icon(Icons.self_improvement),
            label: const Text('Log Session'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mood selection row (1-10 scale with emoji faces).
class _MoodRow extends StatelessWidget {
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _MoodRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  static const _moodEmojis = [
    '\u{1F629}', // 1
    '\u{1F61E}', // 2
    '\u{1F615}', // 3
    '\u{1F610}', // 4
    '\u{1F642}', // 5
    '\u{1F60A}', // 6
    '\u{1F60C}', // 7
    '\u{1F60D}', // 8
    '\u{1F929}', // 9
    '\u{1F970}', // 10
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(width: 50, child: Text(label)),
            if (value != null)
              Text('${_moodEmojis[value! - 1]} $value/10')
            else
              const Text('Not set', style: TextStyle(color: Colors.grey)),
            const Spacer(),
            if (value != null)
              TextButton(
                onPressed: () => onChanged(null),
                child: const Text('Clear'),
              ),
          ],
        ),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            itemBuilder: (context, i) {
              final mood = i + 1;
              final selected = mood == value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ChoiceChip(
                  label: Text(_moodEmojis[i]),
                  selected: selected,
                  onSelected: (_) => onChanged(mood),
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── HISTORY TAB ────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final MeditationTrackerService service;
  final VoidCallback onChanged;

  const _HistoryTab({required this.service, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final sessions = service.sessions.reversed.toList();

    if (sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.self_improvement, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No sessions yet', style: TextStyle(color: Colors.grey)),
            Text('Log your first meditation!',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sessions.length,
      itemBuilder: (context, i) {
        final s = sessions[i];
        final moodText = s.moodDelta != null
            ? '  Mood: ${s.moodDelta! >= 0 ? '+' : ''}${s.moodDelta}'
            : '';
        final dateStr = _formatDate(s.dateTime);

        return Dismissible(
          key: Key(s.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            service.removeSession(s.id);
            onChanged();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session deleted')),
            );
          },
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(s.type.emoji, style: const TextStyle(fontSize: 20)),
              ),
              title: Text('${s.type.label} \u2022 ${s.durationMinutes} min'),
              subtitle: Text('$dateStr$moodText'),
              trailing: s.interrupted
                  ? const Tooltip(
                      message: 'Interrupted',
                      child: Icon(Icons.warning_amber, color: Colors.orange),
                    )
                  : null,
              isThreeLine: s.note != null,
              onTap: s.note != null
                  ? () => _showNoteDialog(context, s)
                  : null,
            ),
          ),
        );
      },
    );
  }

  void _showNoteDialog(BuildContext context, MeditationEntry s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${s.type.emoji} ${s.type.label} Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${s.durationMinutes} min'),
            Text('Date: ${_formatDate(s.dateTime)}'),
            if (s.guideName != null) Text('Guide: ${s.guideName}'),
            if (s.preMood != null) Text('Mood before: ${s.preMood}/10'),
            if (s.postMood != null) Text('Mood after: ${s.postMood}/10'),
            if (s.moodDelta != null)
              Text(
                'Change: ${s.moodDelta! >= 0 ? '+' : ''}${s.moodDelta}',
                style: TextStyle(
                  color: s.moodDelta! > 0
                      ? Colors.green
                      : s.moodDelta! < 0
                          ? Colors.red
                          : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (s.note != null) ...[
              const Divider(),
              Text(s.note!, style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $hour:$min $ampm';
  }
}

// ─── INSIGHTS TAB ───────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final MeditationTrackerService service;

  const _InsightsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (service.sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Log sessions to see insights',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final report = service.generateReport();
    final streak = report.streak;
    final typeFreq = report.typeFrequency;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Stats Cards ──
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.timer,
                  label: 'Total Time',
                  value: '${report.totalMinutes} min',
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.event_repeat,
                  label: 'Sessions',
                  value: '${report.totalSessions}',
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                  value: '${streak.currentDays} days',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events,
                  label: 'Best Streak',
                  value: '${streak.longestDays} days',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.avg_timer,
                  label: 'Avg Duration',
                  value: '${report.avgSessionMinutes.toStringAsFixed(1)} min',
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle,
                  label: 'Completion',
                  value: '${report.completionRate.toStringAsFixed(0)}%',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          if (report.avgMoodDelta != null) ...[
            const SizedBox(height: 8),
            _StatCard(
              icon: Icons.mood,
              label: 'Avg Mood Change',
              value:
                  '${report.avgMoodDelta! >= 0 ? '+' : ''}${report.avgMoodDelta!.toStringAsFixed(1)}',
              color: report.avgMoodDelta! >= 0 ? Colors.green : Colors.red,
            ),
          ],
          const SizedBox(height: 16),

          // ── Technique Breakdown ──
          if (typeFreq.isNotEmpty) ...[
            Text('Technique Breakdown', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...(typeFreq.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .map((e) => _TechniqueBar(
                      type: e.key,
                      count: e.value,
                      total: report.totalSessions,
                    ))
                .toList(),
            const SizedBox(height: 16),
          ],

          // ── Mood Impact by Technique ──
          if (report.techniqueMoodImpacts.isNotEmpty) ...[
            Text('Best Techniques for Mood',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...report.techniqueMoodImpacts.map((t) => Card(
                  child: ListTile(
                    leading: Text(t.type.emoji,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(t.type.label),
                    subtitle: Text(
                      '${t.sessionCount} sessions \u2022 '
                      'Mood: ${t.avgMoodBefore.toStringAsFixed(1)} \u2192 ${t.avgMoodAfter.toStringAsFixed(1)}',
                    ),
                    trailing: Text(
                      '${t.avgMoodDelta >= 0 ? '+' : ''}${t.avgMoodDelta.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: t.avgMoodDelta >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // ── Insights ──
          if (report.insights.isNotEmpty) ...[
            Text('Insights', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...report.insights.map((tip) => Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.lightbulb, color: Colors.amber),
                    title: Text(tip),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

/// Small stat card widget.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

/// Horizontal bar showing technique usage proportion.
class _TechniqueBar extends StatelessWidget {
  final MeditationType type;
  final int count;
  final int total;

  const _TechniqueBar({
    required this.type,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text(type.emoji)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${type.label} ($count)'),
                const SizedBox(height: 2),
                LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${(pct * 100).toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}
