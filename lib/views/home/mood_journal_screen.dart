import 'package:flutter/material.dart';
import '../../core/services/mood_journal_service.dart';
import '../../models/mood_entry.dart';

/// Mood Journal screen for logging daily moods with notes, activities,
/// and viewing mood trends over time.
class MoodJournalScreen extends StatefulWidget {
  const MoodJournalScreen({super.key});

  @override
  State<MoodJournalScreen> createState() => _MoodJournalScreenState();
}

class _MoodJournalScreenState extends State<MoodJournalScreen>
    with SingleTickerProviderStateMixin {
  final MoodJournalService _service = MoodJournalService();
  late TabController _tabController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await _service.init();
    if (mounted) setState(() => _loading = false);
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
        title: const Text('Mood Journal'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_reaction), text: 'Log'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
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
  final MoodJournalService service;
  final VoidCallback onLogged;

  const _LogTab({required this.service, required this.onLogged});

  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  MoodLevel _selectedMood = MoodLevel.neutral;
  final Set<MoodActivity> _selectedActivities = {};
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveMood() async {
    final entry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      mood: _selectedMood,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      activities: _selectedActivities.toList(),
    );
    await widget.service.addEntry(entry);
    if (mounted) {
      _noteController.clear();
      setState(() {
        _selectedMood = MoodLevel.neutral;
        _selectedActivities.clear();
      });
      widget.onLogged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mood logged! 🎉'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mood question
          const Text(
            'How are you feeling?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Mood selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: MoodLevel.values.map((mood) {
              final isSelected = _selectedMood == mood;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = mood),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _moodColor(mood).withOpacity(0.2)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? _moodColor(mood) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(mood.emoji, style: TextStyle(fontSize: isSelected ? 36 : 28)),
                      const SizedBox(height: 4),
                      Text(
                        mood.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? _moodColor(mood) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Activities
          const Text(
            'What have you been doing?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MoodActivity.values.map((activity) {
              final isSelected = _selectedActivities.contains(activity);
              return FilterChip(
                label: Text('${activity.emoji} ${activity.label}'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedActivities.add(activity);
                    } else {
                      _selectedActivities.remove(activity);
                    }
                  });
                },
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Note
          const Text(
            'Add a note (optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'What\'s on your mind?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saveMood,
              icon: const Icon(Icons.check),
              label: const Text('Log Mood', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HISTORY TAB ────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final MoodJournalService service;
  final VoidCallback onChanged;

  const _HistoryTab({required this.service, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = service.entries;
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📝', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No entries yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('Start logging your mood!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Dismissible(
          key: Key(entry.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          onDismissed: (_) async {
            await service.deleteEntry(entry.id);
            onChanged();
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.mood.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.mood.label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _moodColor(entry.mood),
                              ),
                            ),
                            Text(
                              _formatDateTime(entry.timestamp),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (entry.activities.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: entry.activities.map((a) {
                        return Chip(
                          label: Text('${a.emoji} ${a.label}', style: const TextStyle(fontSize: 12)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(entry.note!, style: const TextStyle(fontSize: 14)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── INSIGHTS TAB ───────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final MoodJournalService service;

  const _InsightsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final entries = service.entries;
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📊', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Log some moods first', style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('Insights will appear here', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final trend = service.moodTrend(14);
    final activityFreq = service.activityFrequency();
    final moodByActivity = service.moodByActivity();
    final streak = service.currentStreak();

    // Overall average
    final totalMood = entries.fold<int>(0, (s, e) => s + e.mood.value);
    final avgMood = totalMood / entries.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _StatCard(
                title: 'Average',
                value: avgMood.toStringAsFixed(1),
                subtitle: MoodLevel.fromValue(avgMood.round()).emoji,
                color: _moodColor(MoodLevel.fromValue(avgMood.round())),
              ),
              const SizedBox(width: 12),
              _StatCard(
                title: 'Entries',
                value: entries.length.toString(),
                subtitle: 'total',
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _StatCard(
                title: 'Streak',
                value: '$streak',
                subtitle: streak == 1 ? 'day' : 'days',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 14-day trend
          const Text(
            '14-Day Mood Trend',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (trend.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No data for the last 14 days', style: TextStyle(color: Colors.grey)),
            )
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trend.entries.map((e) {
                  final fraction = (e.value - 1) / 4; // normalize 1-5 to 0-1
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Tooltip(
                        message: '${_formatShortDate(e.key)}: ${e.value.toStringAsFixed(1)}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              MoodLevel.fromValue(e.value.round()).emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 80 * fraction + 10,
                              decoration: BoxDecoration(
                                color: _moodColor(MoodLevel.fromValue(e.value.round()))
                                    .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${e.key.day}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 24),

          // Activities that boost mood
          if (moodByActivity.isNotEmpty) ...[
            const Text(
              'Activities & Mood',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Which activities correlate with better moods?',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...moodByActivity.entries.take(8).map((e) {
              final fraction = (e.value - 1) / 4;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${e.key.emoji} ${e.key.label}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 18,
                          backgroundColor: Colors.grey[200],
                          color: _moodColor(MoodLevel.fromValue(e.value.round())),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      e.value.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 24),

          // Activity frequency
          if (activityFreq.isNotEmpty) ...[
            const Text(
              'Most Logged Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activityFreq.entries.take(10).map((e) {
                return Chip(
                  label: Text('${e.key.emoji} ${e.key.label} (${e.value})'),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── HELPERS ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: color)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}

Color _moodColor(MoodLevel mood) {
  switch (mood) {
    case MoodLevel.veryBad:
      return Colors.red;
    case MoodLevel.bad:
      return Colors.orange;
    case MoodLevel.neutral:
      return Colors.amber;
    case MoodLevel.good:
      return Colors.lightGreen;
    case MoodLevel.great:
      return Colors.green;
  }
}

String _formatDateTime(DateTime dt) {
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
}

String _formatShortDate(DateTime dt) {
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[dt.month - 1]} ${dt.day}';
}
