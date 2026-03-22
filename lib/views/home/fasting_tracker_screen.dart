import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' show pi;
import '../../core/services/screen_persistence.dart';
import '../../core/services/fasting_tracker_service.dart';
import '../../models/fasting_entry.dart';

/// Fasting Tracker screen — start/stop intermittent fasting timers,
/// track progress through metabolic zones, and view history & stats.
class FastingTrackerScreen extends StatefulWidget {
  const FastingTrackerScreen({super.key});

  @override
  State<FastingTrackerScreen> createState() => _FastingTrackerScreenState();
}

class _FastingTrackerScreenState extends State<FastingTrackerScreen>
    with SingleTickerProviderStateMixin {
  final FastingTrackerService _service = const FastingTrackerService();
  final _persistence = ScreenPersistence<FastingEntry>(
    storageKey: 'fasting_tracker_entries',
    toJson: (e) => e.toJson(),
    fromJson: FastingEntry.fromJson,
  );
  late TabController _tabController;
  final List<FastingEntry> _entries = [];
  FastingProtocol _selectedProtocol = FastingProtocol.f16_8;
  int _customHours = 16;
  int _nextId = 1;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEntries();
    // Tick every 30s to update active fast timer.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_service.getActiveFast(_entries) != null) {
        setState(() {});
      }
    });
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

  FastingEntry? get _activeFast => _service.getActiveFast(_entries);

  void _startFast() {
    if (_activeFast != null) return;
    final target = _selectedProtocol == FastingProtocol.custom
        ? _customHours
        : _selectedProtocol.targetHours;
    setState(() {
      _entries.insert(
        0,
        FastingEntry(
          id: 'f${_nextId++}',
          startTime: DateTime.now(),
          protocol: _selectedProtocol,
          targetHours: target,
          status: FastingStatus.active,
        ),
      );
    });
    _persistence.save(_entries);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${_selectedProtocol.emoji} Fast started! Target: ${target}h'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _endFast({bool broken = false}) {
    final active = _activeFast;
    if (active == null) return;
    final idx = _entries.indexOf(active);
    final ended = active.copyWith(
      endTime: DateTime.now(),
      status:
          broken ? FastingStatus.broken : FastingStatus.completed,
    );
    setState(() => _entries[idx] = ended);
    _persistence.save(_entries);

    _showMoodDialog(idx);
  }

  void _showMoodDialog(int entryIdx) {
    int? mood;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('How do you feel?'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final val = i + 1;
              final emojis = ['😫', '😕', '😐', '🙂', '😄'];
              return GestureDetector(
                onTap: () => setDState(() => mood = val),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emojis[i],
                        style: TextStyle(
                            fontSize: mood == val ? 36 : 28)),
                    if (mood == val)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () {
                if (mood != null) {
                  setState(() {
                    _entries[entryIdx] =
                        _entries[entryIdx].copyWith(moodAfter: mood);
                  });
                  _persistence.save(_entries);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteEntry(int index) {
    final entry = _entries[index];
    setState(() => _entries.removeAt(index));
    _persistence.save(_entries);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${entry.protocol.label} fast'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _entries.insert(index, entry));
            _persistence.save(_entries);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fasting Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.timer), text: 'Timer'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.insights), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimerTab(theme, cs),
          _buildHistoryTab(theme, cs),
          _buildStatsTab(theme, cs),
        ],
      ),
    );
  }

  // ── Timer Tab ──

  Widget _buildTimerTab(ThemeData theme, ColorScheme cs) {
    final active = _activeFast;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (active != null) ...[
            _buildActiveTimer(active, theme, cs),
            const SizedBox(height: 16),
            _buildZoneProgress(active, cs),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _endFast(broken: true),
                    icon: const Icon(Icons.close),
                    label: const Text('Break Fast'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _endFast(),
                    icon: const Icon(Icons.check),
                    label: const Text('Complete'),
                  ),
                ),
              ],
            ),
          ] else ...[
            _buildProtocolSelector(theme, cs),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _startFast,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: Text('Start ${_selectedProtocol.label} Fast',
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildZoneLegend(cs),
        ],
      ),
    );
  }

  Widget _buildActiveTimer(
      FastingEntry active, ThemeData theme, ColorScheme cs) {
    final elapsed = DateTime.now().difference(active.startTime);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);
    final zone = FastingTrackerService.getCurrentZone(active.durationHours);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('${active.protocol.emoji} ${active.protocol.label}',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: active.progress.clamp(0.0, 1.0),
                      strokeWidth: 12,
                      backgroundColor: cs.surfaceContainerHighest,
                      color: Color(zone.color),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${hours.toString().padLeft(2, '0')}:'
                        '${minutes.toString().padLeft(2, '0')}:'
                        '${seconds.toString().padLeft(2, '0')}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFeatures: [
                            const FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                      Text(
                        '/ ${active.targetHours}h target',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(zone.color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${zone.emoji} ${zone.name}',
                style: TextStyle(
                  color: Color(zone.color),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(zone.description,
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneProgress(FastingEntry active, ColorScheme cs) {
    final zones = FastingTrackerService.fastingZones;
    final elapsed = active.durationHours;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Metabolic Zones',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...zones.map((z) {
              final reached = elapsed >= z.startHour;
              final inZone =
                  elapsed >= z.startHour && elapsed < z.endHour;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(z.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${z.name} (${z.startHour}-${z.endHour}h)',
                            style: TextStyle(
                              fontWeight: inZone
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: reached
                                  ? Color(z.color)
                                  : cs.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (inZone)
                      Icon(Icons.arrow_forward,
                          size: 16, color: Color(z.color))
                    else if (reached)
                      Icon(Icons.check_circle,
                          size: 16, color: Color(z.color)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolSelector(ThemeData theme, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Protocol',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FastingProtocol.values.map((p) {
                final selected = p == _selectedProtocol;
                return ChoiceChip(
                  label: Text('${p.emoji} ${p.label}'),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedProtocol = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(_selectedProtocol.description,
                style: theme.textTheme.bodySmall),
            if (_selectedProtocol == FastingProtocol.custom) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Target hours: '),
                  Expanded(
                    child: Slider(
                      value: _customHours.toDouble(),
                      min: 4,
                      max: 48,
                      divisions: 44,
                      label: '${_customHours}h',
                      onChanged: (v) =>
                          setState(() => _customHours = v.round()),
                    ),
                  ),
                  Text('${_customHours}h',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildZoneLegend(ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fasting Zones Guide',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...FastingTrackerService.fastingZones.map((z) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(z.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${z.emoji} ${z.name}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Text('${z.startHour}-${z.endHour}h',
                          style: TextStyle(
                              color: cs.onSurface.withOpacity(0.6),
                              fontSize: 12)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── History Tab ──

  Widget _buildHistoryTab(ThemeData theme, ColorScheme cs) {
    final completed = _entries
        .where((e) => e.status != FastingStatus.active)
        .toList();

    if (completed.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🍽️', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text('No fasting history yet'),
            Text('Start your first fast!',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completed.length,
      itemBuilder: (_, i) {
        final e = completed[i];
        final realIdx = _entries.indexOf(e);
        return Dismissible(
          key: ValueKey(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: cs.error,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteEntry(realIdx),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Color(FastingTrackerService.getCurrentZone(
                                e.durationHours)
                            .color)
                        .withOpacity(0.2),
                child: Text(e.status.emoji),
              ),
              title: Text(
                  '${e.protocol.emoji} ${e.protocol.label} — ${e.durationFormatted}'),
              subtitle: Text(
                '${_formatDate(e.startTime)}'
                '${e.moodAfter != null ? '  •  Mood: ${'😫😕😐🙂😄'.split('')[e.moodAfter! - 1]}' : ''}',
              ),
              trailing: e.targetReached
                  ? const Icon(Icons.check_circle,
                      color: Colors.green)
                  : const Icon(Icons.cancel, color: Colors.red),
            ),
          ),
        );
      },
    );
  }

  // ── Stats Tab ──

  Widget _buildStatsTab(ThemeData theme, ColorScheme cs) {
    final summary = _service.getWeeklySummary(_entries);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This Week',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _statRow('Total Fasts', '${summary.totalFasts}'),
                  _statRow('Completed', '${summary.completedFasts}'),
                  _statRow('Completion Rate',
                      '${summary.completionRate.toStringAsFixed(0)}%'),
                  _statRow('Avg Duration',
                      '${summary.avgDurationHours.toStringAsFixed(1)}h'),
                  _statRow('Total Fasting Hours',
                      '${summary.totalFastingHours.toStringAsFixed(1)}h'),
                  _statRow(
                      'Current Streak', '${summary.longestStreakDays} days'),
                  if (summary.mostUsedProtocol != null)
                    _statRow('Favorite Protocol',
                        '${summary.mostUsedProtocol!.emoji} ${summary.mostUsedProtocol!.label}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildWeeklyChart(cs),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(ColorScheme cs) {
    final now = DateTime.now();
    final days = <String>[];
    final hours = <double>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      days.add(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
          [day.weekday - 1]);
      final dayEntries = _service.getEntriesForDate(_entries, day);
      double total = 0;
      for (final e in dayEntries) {
        if (e.status == FastingStatus.completed) {
          total += e.durationHours;
        }
      }
      hours.add(total);
    }

    final maxH = hours.fold(0.0, (a, b) => a > b ? a : b);
    final scale = maxH > 0 ? maxH : 24.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weekly Fasting Hours',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final h = hours[i];
                  final barHeight = scale > 0 ? (h / scale * 100) : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${h.toStringAsFixed(0)}h',
                              style: const TextStyle(fontSize: 10)),
                          const SizedBox(height: 4),
                          Container(
                            height: barHeight.clamp(4.0, 100.0),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(
                                  h > 0 ? 0.7 : 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(days[i],
                              style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
