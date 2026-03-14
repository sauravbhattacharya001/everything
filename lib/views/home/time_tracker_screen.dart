import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/services/screen_persistence.dart';
import '../../core/services/time_tracker_service.dart';
import '../../models/time_entry.dart';

/// Time Tracker screen — log time on activities, view daily breakdowns,
/// and track productivity insights across categories.
class TimeTrackerScreen extends StatefulWidget {
  const TimeTrackerScreen({super.key});

  @override
  State<TimeTrackerScreen> createState() => _TimeTrackerScreenState();
}

class _TimeTrackerScreenState extends State<TimeTrackerScreen>
    with SingleTickerProviderStateMixin {
  final TimeTrackerService _service = const TimeTrackerService();
  final _persistence = ScreenPersistence<TimeEntry>(
    storageKey: 'time_tracker_entries',
    toJson: (e) => e.toJson(),
    fromJson: TimeEntry.fromJson,
  );
  late TabController _tabController;
  final List<TimeEntry> _entries = [];
  int _nextId = 1;
  Timer? _ticker;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_entries.any((e) => e.isRunning)) setState(() {});
    });
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final saved = await _persistence.load();
    if (saved.isNotEmpty) {
      setState(() {
        _entries.addAll(saved);
        _nextId = _entries.length + 1;
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  TimeEntry? get _activeEntry {
    try {
      return _entries.firstWhere((e) => e.isRunning);
    } catch (_) {
      return null;
    }
  }

  void _startTimer(String activity, TimeCategory category, {String? notes}) {
    _stopActiveTimer();
    setState(() {
      _entries.add(TimeEntry(
        id: 't${_nextId++}',
        activity: activity,
        category: category,
        startTime: DateTime.now(),
        notes: notes,
      ));
    });
    _persistence.save(_entries);
  }

  void _stopActiveTimer() {
    final active = _activeEntry;
    if (active != null) {
      setState(() {
        final idx = _entries.indexWhere((e) => e.id == active.id);
        if (idx >= 0) {
          _entries[idx] = active.copyWith(endTime: DateTime.now());
        }
      });
      _persistence.save(_entries);
    }
  }

  void _deleteEntry(String id) {
    setState(() => _entries.removeWhere((e) => e.id == id));
    _persistence.save(_entries);
  }

  void _showNewEntryDialog() {
    final activityCtl = TextEditingController();
    final notesCtl = TextEditingController();
    var cat = TimeCategory.work;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Start Timer'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: activityCtl, decoration: const InputDecoration(labelText: 'Activity', hintText: 'What are you working on?', border: OutlineInputBorder()), autofocus: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<TimeCategory>(value: cat, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: TimeCategory.values.map((c) => DropdownMenuItem(value: c, child: Text('${c.emoji} ${c.label}'))).toList(),
              onChanged: (v) { if (v != null) setDlg(() => cat = v); }),
            const SizedBox(height: 12),
            TextField(controller: notesCtl, decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()), maxLines: 2),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton.icon(onPressed: () {
              final a = activityCtl.text.trim();
              if (a.isEmpty) return;
              _startTimer(a, cat, notes: notesCtl.text.trim().isEmpty ? null : notesCtl.text.trim());
              Navigator.pop(ctx);
            }, icon: const Icon(Icons.play_arrow), label: const Text('Start')),
          ],
        ),
      ),
    );
  }

  void _showManualEntryDialog() {
    final activityCtl = TextEditingController();
    final minutesCtl = TextEditingController();
    var cat = TimeCategory.work;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Log Time Manually'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: activityCtl, decoration: const InputDecoration(labelText: 'Activity', border: OutlineInputBorder()), autofocus: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<TimeCategory>(value: cat, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: TimeCategory.values.map((c) => DropdownMenuItem(value: c, child: Text('${c.emoji} ${c.label}'))).toList(),
              onChanged: (v) { if (v != null) setDlg(() => cat = v); }),
            const SizedBox(height: 12),
            TextField(controller: minutesCtl, decoration: const InputDecoration(labelText: 'Duration (minutes)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              final a = activityCtl.text.trim();
              final m = int.tryParse(minutesCtl.text.trim()) ?? 0;
              if (a.isEmpty || m <= 0) return;
              final end = DateTime.now();
              setState(() => _entries.add(TimeEntry(id: 't${_nextId++}', activity: a, category: cat, startTime: end.subtract(Duration(minutes: m)), endTime: end)));
              _persistence.save(_entries);
              Navigator.pop(ctx);
            }, child: const Text('Log')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('⏱️ Time Tracker'),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(icon: Icon(Icons.timer), text: 'Timer'),
          Tab(icon: Icon(Icons.list_alt), text: 'Log'),
          Tab(icon: Icon(Icons.pie_chart), text: 'Breakdown'),
          Tab(icon: Icon(Icons.insights), text: 'Insights'),
        ]),
      ),
      body: TabBarView(controller: _tabController, children: [
        _buildTimerTab(theme),
        _buildLogTab(theme),
        _buildBreakdownTab(theme),
        _buildInsightsTab(theme),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: _showNewEntryDialog, tooltip: 'Start timer', child: const Icon(Icons.play_arrow)),
    );
  }

  Widget _buildTimerTab(ThemeData theme) {
    final active = _activeEntry;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: active != null
                ? Column(children: [
                    Text(active.activity, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Chip(avatar: Text(active.category.emoji), label: Text(active.category.label)),
                    const SizedBox(height: 16),
                    Text(_formatTimer(active.duration), style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, fontFamily: 'monospace', color: theme.colorScheme.primary)),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(onPressed: _stopActiveTimer, icon: const Icon(Icons.stop), label: const Text('Stop')),
                  ])
                : Column(children: [
                    Icon(Icons.timer_off, size: 64, color: theme.disabledColor),
                    const SizedBox(height: 12),
                    Text('No timer running', style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor)),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: _showNewEntryDialog, icon: const Icon(Icons.play_arrow), label: const Text('Start Timer')),
                  ]),
          ),
        ),
        const SizedBox(height: 16),
        Text('Quick Start', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: TimeCategory.values.map((c) => ActionChip(avatar: Text(c.emoji), label: Text(c.label), onPressed: () => _startTimer(c.label, c))).toList()),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: _showManualEntryDialog, icon: const Icon(Icons.edit), label: const Text('Log time manually')),
        const SizedBox(height: 24),
        _buildTodaySummaryStrip(theme),
      ]),
    );
  }

  Widget _buildTodaySummaryStrip(ThemeData theme) {
    final summary = _service.getDailySummary(_entries, DateTime.now());
    final score = _service.productivityScore(_entries, DateTime.now());
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _stat(theme, 'Tracked', _service.formatDuration(summary.totalTracked)),
      _stat(theme, 'Sessions', '${summary.entryCount}'),
      _stat(theme, 'Score', '$score/100'),
    ])));
  }

  Widget _stat(ThemeData theme, String label, String value) => Column(children: [
    Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    Text(label, style: theme.textTheme.bodySmall),
  ]);

  Widget _buildLogTab(ThemeData theme) {
    final dayEntries = _service.getEntriesForDate(_entries, _selectedDate);
    final isToday = _isSameDay(_selectedDate, DateTime.now());

    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)))),
        TextButton(
          onPressed: () async {
            final p = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
            if (p != null) setState(() => _selectedDate = p);
          },
          child: Text(isToday ? 'Today' : _fmtDate(_selectedDate), style: theme.textTheme.titleMedium),
        ),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: isToday ? null : () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)))),
      ])),
      Expanded(
        child: dayEntries.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.hourglass_empty, size: 48, color: theme.disabledColor),
                const SizedBox(height: 8),
                Text('No entries for this day', style: TextStyle(color: theme.disabledColor)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: dayEntries.length,
                itemBuilder: (_, i) {
                  final e = dayEntries[i];
                  final color = Color(TimeTrackerService.categoryColors[e.category] ?? 0xFF9E9E9E);
                  return Dismissible(
                    key: Key(e.id), direction: DismissDirection.endToStart,
                    background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
                    onDismissed: (_) => _deleteEntry(e.id),
                    child: Card(child: ListTile(
                      leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Text(e.category.emoji)),
                      title: Text(e.activity),
                      subtitle: Text('${_fmtTime(e.startTime)} – ${e.isRunning ? "now" : _fmtTime(e.endTime!)}'),
                      trailing: Text(e.isRunning ? _formatTimer(e.duration) : _service.formatDuration(e.duration),
                        style: TextStyle(fontWeight: FontWeight.bold, color: e.isRunning ? theme.colorScheme.primary : null)),
                    )),
                  );
                }),
      ),
    ]);
  }

  Widget _buildBreakdownTab(ThemeData theme) {
    final summary = _service.getDailySummary(_entries, _selectedDate);
    if (summary.entryCount == 0) {
      final isToday = _isSameDay(_selectedDate, DateTime.now());
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.pie_chart_outline, size: 64, color: theme.disabledColor),
        const SizedBox(height: 12),
        Text('No data to show', style: TextStyle(color: theme.disabledColor)),
        Text(isToday ? 'Start tracking to see your breakdown' : 'No entries logged this day', style: theme.textTheme.bodySmall),
      ]));
    }

    final sorted = summary.categoryBreakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _stat(theme, 'Total', _service.formatDuration(summary.totalTracked)),
          _stat(theme, 'Sessions', '${summary.entryCount}'),
          _stat(theme, 'Longest', _service.formatDuration(summary.longestSession)),
          if (summary.topCategory != null) _stat(theme, 'Top', summary.topCategory!),
        ]))),
        const SizedBox(height: 16),
        Text('Category Breakdown', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...sorted.map((entry) {
          final frac = summary.totalTracked.inSeconds > 0 ? entry.value.inSeconds / summary.totalTracked.inSeconds : 0.0;
          final color = Color(TimeTrackerService.categoryColors[entry.key] ?? 0xFF9E9E9E);
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${entry.key.emoji} ${entry.key.label}'),
              Text('${_service.formatDuration(entry.value)} (${(frac * 100).toStringAsFixed(1)}%)'),
            ]),
            const SizedBox(height: 4),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: frac, backgroundColor: color.withOpacity(0.15), valueColor: AlwaysStoppedAnimation(color), minHeight: 12)),
          ]));
        }),
      ]),
    );
  }

  Widget _buildInsightsTab(ThemeData theme) {
    final insights = _service.getWeeklyInsights(_entries);
    final score = _service.productivityScore(_entries, DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Card(elevation: 4, child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          Text("Today's Productivity", style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(width: 120, height: 120, child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: score / 100.0, strokeWidth: 10, backgroundColor: theme.disabledColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(score >= 70 ? Colors.green : score >= 40 ? Colors.orange : Colors.red)),
            Text('$score', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          ])),
          const SizedBox(height: 8),
          Text(score >= 70 ? '🔥 Great day!' : score >= 40 ? '👍 Good progress' : '💪 Keep going!', style: theme.textTheme.bodyLarge),
        ]))),
        const SizedBox(height: 16),
        Text('Weekly Overview', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...insights.map((ins) => Card(child: ListTile(
          leading: Icon(_insIcon(ins.icon)),
          title: Text(ins.label),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(ins.value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (ins.trend != null) ...[
              const SizedBox(width: 4),
              Icon(ins.trend == 'up' ? Icons.trending_up : ins.trend == 'down' ? Icons.trending_down : Icons.trending_flat,
                size: 18, color: ins.trend == 'up' ? Colors.green : ins.trend == 'down' ? Colors.red : Colors.grey),
            ],
          ]),
        ))),
        const SizedBox(height: 16),
        Text('Tips', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._tips(score).map((t) => Card(child: ListTile(leading: const Icon(Icons.lightbulb_outline, color: Colors.amber), title: Text(t)))),
      ]),
    );
  }

  String _formatTimer(Duration d) => '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  String _fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  String _fmtDate(DateTime dt) { const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; return '${m[dt.month-1]} ${dt.day}, ${dt.year}'; }
  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  IconData _insIcon(IconType t) {
    switch (t) {
      case IconType.time: return Icons.access_time;
      case IconType.chart: return Icons.bar_chart;
      case IconType.star: return Icons.star;
      case IconType.fire: return Icons.local_fire_department;
      case IconType.target: return Icons.track_changes;
      case IconType.info: return Icons.info_outline;
    }
  }

  List<String> _tips(int s) {
    if (s >= 70) return ['You\'re on fire! Consider taking a break to recharge.', 'Great variety in your activities today.'];
    if (s >= 40) return ['Try tracking at least 6 sessions for full productivity credit.', 'Mix in different categories for a balanced day.'];
    return ['Start a timer to begin tracking your day!', 'Even 15 minutes of focused work counts.', 'Use quick-start chips for fast category logging.'];
  }
}
