import 'package:flutter/material.dart';
import 'dart:math' show pi;
import '../../core/services/screen_persistence.dart';
import '../../core/services/caffeine_tracker_service.dart';
import '../../models/caffeine_entry.dart';

/// Caffeine Tracker screen — log daily caffeine intake, see active levels,
/// weekly trends, and get sleep-safety cutoff warnings.
class CaffeineTrackerScreen extends StatefulWidget {
  const CaffeineTrackerScreen({super.key});

  @override
  State<CaffeineTrackerScreen> createState() => _CaffeineTrackerScreenState();
}

class _CaffeineTrackerScreenState extends State<CaffeineTrackerScreen>
    with SingleTickerProviderStateMixin {
  final CaffeineTrackerService _service = const CaffeineTrackerService();
  final _persistence = ScreenPersistence<CaffeineEntry>(
    storageKey: 'caffeine_tracker_entries',
    toJson: (e) => e.toJson(),
    fromJson: CaffeineEntry.fromJson,
  );
  late TabController _tabController;
  final List<CaffeineEntry> _entries = [];
  CaffeineSource _selectedSource = CaffeineSource.drip;
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _tabController.dispose();
    super.dispose();
  }

  void _addEntry(int mg) {
    setState(() {
      _entries.add(CaffeineEntry(
        id: 'c${_nextId++}',
        timestamp: DateTime.now(),
        caffeineMg: mg,
        source: _selectedSource,
      ));
    });
    _persistence.save(_entries);
  }

  void _deleteEntry(String id) {
    setState(() => _entries.removeWhere((e) => e.id == id));
    _persistence.save(_entries);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final summary = _service.dailySummary(_entries, now);
    final activeMg = _service.activeSystemCaffeine(_entries, now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caffeine Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.coffee), text: 'Today'),
            Tab(icon: Icon(Icons.show_chart), text: 'Active'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Week'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(summary, activeMg),
          _buildActiveTab(activeMg),
          _buildWeekTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Today Tab ──

  Widget _buildTodayTab(CaffeineDailySummary summary, double activeMg) {
    final now = DateTime.now();
    final todayEntries = _service.entriesForDate(_entries, now);
    final isAfterCutoff = now.hour >= _service.config.cutoffHour;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily intake card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${summary.totalMg} mg',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: summary.overLimit
                                    ? Colors.red
                                    : null,
                              ),
                        ),
                        Text(
                          'of ${summary.limitMg} mg daily limit',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: summary.percentOfLimit.clamp(0.0, 1.0),
                        strokeWidth: 6,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        color: summary.overLimit
                            ? Colors.red
                            : summary.percentOfLimit > 0.75
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Active in system
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        size: 18, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      '${activeMg.round()} mg active in your system',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (summary.hadCaffeineAfterCutoff || isAfterCutoff) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bedtime,
                            size: 18, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAfterCutoff
                                ? 'Past ${_service.config.cutoffHour}:00 cutoff — caffeine may affect sleep'
                                : 'You had caffeine after the cutoff today',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Quick-add buttons
        _buildQuickAddRow(),

        const SizedBox(height: 16),

        // Today's entries
        if (todayEntries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No caffeine logged today ☕',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(120),
                    ),
              ),
            ),
          )
        else
          ...todayEntries.reversed.map((e) => _buildEntryTile(e)),
      ],
    );
  }

  Widget _buildQuickAddRow() {
    final sources = [
      CaffeineSource.espresso,
      CaffeineSource.drip,
      CaffeineSource.greenTea,
      CaffeineSource.energyDrink,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sources.map((src) {
        return ActionChip(
          avatar: Text(src.emoji),
          label: Text('${src.label} (${src.defaultMg}mg)'),
          onPressed: () {
            _selectedSource = src;
            _addEntry(src.defaultMg);
          },
        );
      }).toList(),
    );
  }

  Widget _buildEntryTile(CaffeineEntry entry) {
    final time = TimeOfDay.fromDateTime(entry.timestamp);
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteEntry(entry.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: Text(entry.source.emoji, style: const TextStyle(fontSize: 24)),
        title: Text('${entry.caffeineMg} mg — ${entry.source.label}'),
        subtitle: Text(time.format(context)),
        trailing: Text(
          '${entry.remainingMgAt(DateTime.now()).round()} mg left',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  // ── Active Tab ──

  Widget _buildActiveTab(double activeMg) {
    final now = DateTime.now();
    final hoursToSleep =
        _service.hoursUntilBelow(_entries, now, threshold: 50);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.local_fire_department,
                    size: 48, color: Colors.orange),
                const SizedBox(height: 8),
                Text(
                  '${activeMg.round()} mg',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Text('active in your system'),
                const SizedBox(height: 16),
                Text(
                  'Caffeine has a ~5 hour half-life',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Decay Timeline',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...List.generate(7, (i) {
                  final futureTime = now.add(Duration(hours: i * 2));
                  final mg = _service.activeSystemCaffeine(_entries, futureTime);
                  final maxMg =
                      _service.activeSystemCaffeine(_entries, now).clamp(1.0, 9999.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            '+${i * 2}h',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (mg / maxMg).clamp(0.0, 1.0),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            color: mg > 200
                                ? Colors.red
                                : mg > 100
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 55,
                          child: Text(
                            '${mg.round()} mg',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bedtime, color: Colors.indigo),
            title: Text(hoursToSleep <= 0
                ? 'Caffeine is below sleep-safe levels'
                : '~${hoursToSleep.toStringAsFixed(1)}h until sleep-safe (<50mg)'),
            subtitle: hoursToSleep > 0
                ? Text(
                    'Estimated at ${TimeOfDay.fromDateTime(now.add(Duration(minutes: (hoursToSleep * 60).round()))).format(context)}')
                : null,
          ),
        ),
      ],
    );
  }

  // ── Week Tab ──

  Widget _buildWeekTab() {
    final now = DateTime.now();
    final week = _service.weeklyHistory(_entries, now);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weekly Intake',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: week.map((day) {
                      final maxMg = week
                          .map((d) => d.totalMg)
                          .fold(400, (a, b) => a > b ? a : b);
                      final height =
                          maxMg > 0 ? (day.totalMg / maxMg) * 120 : 0.0;
                      final dayLabel =
                          days[day.date.weekday - 1];
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('${day.totalMg}',
                                style: const TextStyle(fontSize: 10)),
                            const SizedBox(height: 4),
                            Container(
                              height: height,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: day.overLimit
                                    ? Colors.red
                                    : Colors.brown.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(dayLabel,
                                style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Weekly total: ${week.map((d) => d.totalMg).fold(0, (a, b) => a + b)} mg  •  '
                    'Avg: ${(week.map((d) => d.totalMg).fold(0, (a, b) => a + b) / 7).round()} mg/day',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Source breakdown for the week
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sources This Week',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._weeklySourceBreakdown(week),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _weeklySourceBreakdown(List<CaffeineDailySummary> week) {
    final totals = <CaffeineSource, int>{};
    for (final day in week) {
      day.bySource.forEach((src, mg) {
        totals[src] = (totals[src] ?? 0) + mg;
      });
    }
    if (totals.isEmpty) {
      return [
        const Center(
            child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No data this week'),
        ))
      ];
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value;

    return sorted.map((e) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(e.key.emoji),
            const SizedBox(width: 8),
            SizedBox(width: 90, child: Text(e.key.label)),
            Expanded(
              child: LinearProgressIndicator(
                value: maxVal > 0 ? e.value / maxVal : 0,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                color: Colors.brown,
              ),
            ),
            const SizedBox(width: 8),
            Text('${e.value} mg', style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }).toList();
  }

  // ── Add Dialog ──

  void _showAddDialog() {
    int mg = _selectedSource.defaultMg;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Log Caffeine'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<CaffeineSource>(
                    value: _selectedSource,
                    decoration:
                        const InputDecoration(labelText: 'Source'),
                    items: CaffeineSource.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text('${s.emoji} ${s.label}'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() {
                          _selectedSource = v;
                          mg = v.defaultMg;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: mg.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Caffeine (mg)',
                      suffixText: 'mg',
                    ),
                    onChanged: (v) {
                      mg = int.tryParse(v) ?? mg;
                    },
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
                    _addEntry(mg);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Log'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
