import 'package:flutter/material.dart';
import '../../core/services/energy_tracker_service.dart';
import '../../models/energy_entry.dart';

/// Energy Tracker screen — monitor energy levels throughout the day,
/// identify patterns, and optimize productivity windows.
///
/// 4 tabs:
/// - **Log**: Quick energy check-in with level picker, factors, and notes
/// - **Timeline**: Daily energy timeline with date navigation
/// - **Patterns**: Time-of-day breakdown, factor impact analysis
/// - **Insights**: Overall stats, trends, streaks, recommendations
class EnergyTrackerScreen extends StatefulWidget {
  const EnergyTrackerScreen({super.key});

  @override
  State<EnergyTrackerScreen> createState() => _EnergyTrackerScreenState();
}

class _EnergyTrackerScreenState extends State<EnergyTrackerScreen>
    with SingleTickerProviderStateMixin {
  final EnergyTrackerService _service = EnergyTrackerService();
  late TabController _tabController;
  final List<EnergyEntry> _entries = [];
  int _nextId = 1;

  // Log tab state
  EnergyLevel _selectedLevel = EnergyLevel.moderate;
  final Set<EnergyFactor> _selectedFactors = {};
  final TextEditingController _noteController = TextEditingController();

  // Timeline tab state
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _addSampleEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addSampleEntries() {
    final now = DateTime.now();
    final rng = [
      EnergyLevel.peak, EnergyLevel.high, EnergyLevel.moderate,
      EnergyLevel.low, EnergyLevel.high, EnergyLevel.moderate,
      EnergyLevel.exhausted, EnergyLevel.moderate, EnergyLevel.high,
      EnergyLevel.peak, EnergyLevel.moderate, EnergyLevel.low,
      EnergyLevel.high, EnergyLevel.moderate, EnergyLevel.high,
      EnergyLevel.low, EnergyLevel.moderate, EnergyLevel.high,
    ];
    final sampleFactors = [
      [EnergyFactor.caffeine, EnergyFactor.exercise],
      [EnergyFactor.meal],
      [EnergyFactor.stress, EnergyFactor.screenTime],
      [EnergyFactor.nap],
      [EnergyFactor.outdoors, EnergyFactor.hydration],
      [EnergyFactor.meditation],
      [EnergyFactor.sugar, EnergyFactor.alcohol],
      [EnergyFactor.socializing],
      [EnergyFactor.exercise, EnergyFactor.hydration],
      [EnergyFactor.caffeine],
      [EnergyFactor.meal, EnergyFactor.hydration],
      [EnergyFactor.stress],
      [EnergyFactor.outdoors, EnergyFactor.exercise],
      [EnergyFactor.screenTime],
      [EnergyFactor.meditation, EnergyFactor.outdoors],
      [EnergyFactor.sugar],
      [EnergyFactor.meal],
      [EnergyFactor.caffeine, EnergyFactor.exercise],
    ];
    for (var i = 0; i < rng.length; i++) {
      final daysAgo = i ~/ 3;
      final hour = 7 + (i % 3) * 5; // 7, 12, 17
      _entries.add(EnergyEntry(
        id: 'sample-${_nextId++}',
        timestamp: now.subtract(Duration(days: daysAgo, hours: now.hour - hour)),
        level: rng[i],
        factors: sampleFactors[i],
        note: i % 4 == 0 ? 'Feeling ${rng[i].label.toLowerCase()} today' : null,
      ));
    }
  }

  void _addEntry() {
    final entry = EnergyEntry(
      id: 'energy-${_nextId++}',
      timestamp: DateTime.now(),
      level: _selectedLevel,
      factors: _selectedFactors.toList(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    setState(() {
      _entries.insert(0, entry);
      _selectedLevel = EnergyLevel.moderate;
      _selectedFactors.clear();
      _noteController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${entry.level.emoji} Energy logged: ${entry.level.label}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteEntry(String id) {
    setState(() => _entries.removeWhere((e) => e.id == id));
  }

  List<EnergyEntry> get _todayEntries {
    final now = _selectedDate;
    return _entries.where((e) =>
        e.timestamp.year == now.year &&
        e.timestamp.month == now.month &&
        e.timestamp.day == now.day).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ Energy Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Log'),
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
            Tab(icon: Icon(Icons.insights), text: 'Patterns'),
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogTab(),
          _buildTimelineTab(),
          _buildPatternsTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  // ─── Log Tab ────────────────────────────────────────────────────

  Widget _buildLogTab() {
    final now = DateTime.now();
    final currentSlot = TimeSlot.fromHour(now.hour);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current time slot
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(currentSlot.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentSlot.label,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${_todayEntriesCount()} logged today',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Energy level picker
          Text('How\'s your energy?',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: EnergyLevel.values.map((level) {
              final selected = _selectedLevel == level;
              return GestureDetector(
                onTap: () => setState(() => _selectedLevel = level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? _levelColor(level).withOpacity(0.2)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected ? _levelColor(level) : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(level.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(level.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? _levelColor(level) : null,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Factor chips
          Text('What factors?',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EnergyFactor.values.map((factor) {
              final selected = _selectedFactors.contains(factor);
              return FilterChip(
                label: Text('${factor.emoji} ${factor.label}'),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedFactors.add(factor);
                    } else {
                      _selectedFactors.remove(factor);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Note
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'How are you feeling?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit_note),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // Log button
          FilledButton.icon(
            onPressed: _addEntry,
            icon: const Icon(Icons.bolt),
            label: Text('Log ${_selectedLevel.emoji} ${_selectedLevel.label}'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: _levelColor(_selectedLevel),
            ),
          ),
          const SizedBox(height: 24),

          // Quick log (last 3 entries)
          if (_entries.isNotEmpty) ...[
            Text('Recent', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._entries.take(3).map((e) => _entryTile(e, compact: true)),
          ],
        ],
      ),
    );
  }

  int _todayEntriesCount() {
    final now = DateTime.now();
    return _entries.where((e) =>
        e.timestamp.year == now.year &&
        e.timestamp.month == now.month &&
        e.timestamp.day == now.day).length;
  }

  // ─── Timeline Tab ───────────────────────────────────────────────

  Widget _buildTimelineTab() {
    final dayEntries = _todayEntries;
    final dayAvg = dayEntries.isEmpty
        ? 0.0
        : dayEntries.fold<int>(0, (s, e) => s + e.level.value) / dayEntries.length;

    return Column(
      children: [
        // Date navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() =>
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Text(
                  _isToday(_selectedDate)
                      ? 'Today'
                      : '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _isToday(_selectedDate)
                    ? null
                    : () => setState(() =>
                        _selectedDate = _selectedDate.add(const Duration(days: 1))),
              ),
            ],
          ),
        ),

        // Day summary strip
        if (dayEntries.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip('Avg', '${dayAvg.toStringAsFixed(1)}/5'),
                _statChip('Entries', '${dayEntries.length}'),
                _statChip('Peak', dayEntries.map((e) => e.level.value)
                    .reduce((a, b) => a > b ? a : b).toString()),
                _statChip('Low', dayEntries.map((e) => e.level.value)
                    .reduce((a, b) => a < b ? a : b).toString()),
              ],
            ),
          ),

        // Energy curve visualization
        if (dayEntries.length >= 2)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CustomPaint(
              size: Size.infinite,
              painter: _EnergyCurvePainter(dayEntries, Theme.of(context)),
            ),
          ),

        // Timeline list
        Expanded(
          child: dayEntries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        _isToday(_selectedDate)
                            ? 'No entries yet today'
                            : 'No entries for this day',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: dayEntries.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (ctx, i) =>
                      _entryTile(dayEntries[i], showDelete: true),
                ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // ─── Patterns Tab ───────────────────────────────────────────────

  Widget _buildPatternsTab() {
    if (_entries.isEmpty) {
      return const Center(
        child: Text('Log some energy entries to see patterns.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final slotAvgs = _service.timeSlotAverages(_entries);
    final boosters = _service.energyBoosters(_entries);
    final drainers = _service.energyDrainers(_entries);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time-of-day breakdown
          Text('🕐 Energy by Time of Day',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...slotAvgs.map((avg) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text('${avg.slot.emoji} ${avg.slot.label}',
                          style: const TextStyle(fontSize: 13)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: avg.average / 5,
                          minHeight: 20,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            _levelColor(EnergyLevel.fromValue(avg.average.round())),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 45,
                      child: Text('${avg.average.toStringAsFixed(1)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),

          // Energy boosters
          if (boosters.isNotEmpty) ...[
            Text('🔋 Energy Boosters',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...boosters.take(5).map((b) => Card(
                  color: Colors.green.shade50,
                  child: ListTile(
                    leading: Text(b.factor.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(b.factor.label),
                    subtitle: Text(
                      '+${b.delta.toStringAsFixed(1)} energy '
                      '(${b.avgWithFactor.toStringAsFixed(1)} vs ${b.avgWithout.toStringAsFixed(1)})',
                    ),
                    trailing: Text(
                      '${b.occurrences}×',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Energy drainers
          if (drainers.isNotEmpty) ...[
            Text('🪫 Energy Drainers',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...drainers.take(5).map((d) => Card(
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: Text(d.factor.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(d.factor.label),
                    subtitle: Text(
                      '${d.delta.toStringAsFixed(1)} energy '
                      '(${d.avgWithFactor.toStringAsFixed(1)} vs ${d.avgWithout.toStringAsFixed(1)})',
                    ),
                    trailing: Text(
                      '${d.occurrences}×',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                )),
          ],
          const SizedBox(height: 24),

          // Factor frequency
          Text('📊 Factor Frequency',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _factorFrequency().entries.map((e) {
              return Chip(
                avatar: Text(e.key.emoji),
                label: Text('${e.key.label}: ${e.value}'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Map<EnergyFactor, int> _factorFrequency() {
    final counts = <EnergyFactor, int>{};
    for (final entry in _entries) {
      for (final factor in entry.factors) {
        counts[factor] = (counts[factor] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  // ─── Insights Tab ───────────────────────────────────────────────

  Widget _buildInsightsTab() {
    if (_entries.isEmpty) {
      return const Center(
        child: Text('Log some energy entries to see insights.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final report = _service.generateReport(_entries);
    final trendData = _service.trend(_entries);
    final streakData = _service.streaks(_entries);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overall stats card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _levelEmoji(report.overallAverage),
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${report.overallAverage.toStringAsFixed(1)}/5',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Average Energy',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statColumn('Entries', '${report.totalEntries}'),
                      _statColumn('Days', '${report.totalDays}'),
                      _statColumn(
                        'Stability',
                        _service.stability(_entries).toStringAsFixed(2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Peak & trough
          if (report.peakSlot != null || report.troughSlot != null)
            Row(
              children: [
                if (report.peakSlot != null)
                  Expanded(
                    child: Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(report.peakSlot!.emoji,
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            const Text('Peak Time',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(report.peakSlot!.label,
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (report.troughSlot != null)
                  Expanded(
                    child: Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(report.troughSlot!.emoji,
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            const Text('Low Time',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(report.troughSlot!.label,
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 16),

          // Trend
          if (trendData != null)
            Card(
              child: ListTile(
                leading: Icon(
                  trendData.direction == 'improving'
                      ? Icons.trending_up
                      : trendData.direction == 'declining'
                          ? Icons.trending_down
                          : Icons.trending_flat,
                  color: trendData.direction == 'improving'
                      ? Colors.green
                      : trendData.direction == 'declining'
                          ? Colors.red
                          : Colors.grey,
                  size: 32,
                ),
                title: Text(
                  'Energy is ${trendData.direction}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${trendData.startAvg.toStringAsFixed(1)} → ${trendData.endAvg.toStringAsFixed(1)} '
                  'over ${trendData.days} days',
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Streaks
          Row(
            children: [
              if (streakData['current'] != null)
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 28)),
                          Text(
                            '${streakData['current']!.days}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Text('Current Streak',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              if (streakData['longest'] != null)
                Expanded(
                  child: Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 28)),
                          Text(
                            '${streakData['longest']!.days}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Text('Best Streak',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Daily averages mini chart
          if (report.dailySummaries.length >= 2) ...[
            Text('📈 Daily Averages',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: CustomPaint(
                size: Size.infinite,
                painter: _DailyAvgPainter(report.dailySummaries, Theme.of(context)),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recommendations
          if (report.recommendations.isNotEmpty) ...[
            Text('💡 Recommendations',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...report.recommendations.map((rec) => Card(
                  child: ListTile(
                    leading: Icon(
                      rec.category == 'timing'
                          ? Icons.schedule
                          : rec.category == 'factor'
                              ? Icons.science
                              : rec.category == 'warning'
                                  ? Icons.warning_amber
                                  : Icons.tips_and_updates,
                      color: rec.category == 'warning' ? Colors.orange : Colors.blue,
                    ),
                    title: Text(rec.title, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(rec.description, style: const TextStyle(fontSize: 12)),
                    isThreeLine: true,
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ─── Shared Widgets ─────────────────────────────────────────────

  Widget _entryTile(EnergyEntry entry, {bool compact = false, bool showDelete = false}) {
    final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}';
    return Dismissible(
      key: Key(entry.id),
      direction: showDelete ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteEntry(entry.id),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _levelColor(entry.level).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(entry.level.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          title: Row(
            children: [
              Text(entry.level.label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('${entry.timeSlot.emoji} $time',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.factors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    children: entry.factors.map((f) =>
                        Text(f.emoji, style: const TextStyle(fontSize: 14))).toList(),
                  ),
                ),
              if (!compact && entry.note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(entry.note!,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Color _levelColor(EnergyLevel level) {
    switch (level) {
      case EnergyLevel.exhausted:
        return Colors.red.shade700;
      case EnergyLevel.low:
        return Colors.orange;
      case EnergyLevel.moderate:
        return Colors.amber;
      case EnergyLevel.high:
        return Colors.lightGreen;
      case EnergyLevel.peak:
        return Colors.green;
    }
  }

  String _levelEmoji(double avg) {
    if (avg >= 4.5) return '🚀';
    if (avg >= 3.5) return '🔋';
    if (avg >= 2.5) return '⚡';
    if (avg >= 1.5) return '😴';
    return '🪫';
  }
}

// ─── Custom Painters ──────────────────────────────────────────────

/// Draws a smooth energy curve for a single day's entries.
class _EnergyCurvePainter extends CustomPainter {
  final List<EnergyEntry> entries;
  final ThemeData theme;

  _EnergyCurvePainter(this.entries, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;

    final paint = Paint()
      ..color = theme.colorScheme.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.fill;

    final path = Path();
    final minHour = entries.first.timestamp.hour.toDouble();
    final maxHour = entries.last.timestamp.hour.toDouble();
    final hourRange = (maxHour - minHour).clamp(1, 24);

    for (var i = 0; i < entries.length; i++) {
      final x = ((entries[i].timestamp.hour - minHour) / hourRange) * size.width;
      final y = size.height - ((entries[i].level.value - 1) / 4) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    canvas.drawPath(path, paint);

    // Draw level labels on left
    final textStyle = TextStyle(fontSize: 9, color: Colors.grey.shade500);
    for (var level = 1; level <= 5; level++) {
      final y = size.height - ((level - 1) / 4) * size.height;
      final tp = TextPainter(
        text: TextSpan(text: '$level', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-12, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Draws a bar chart of daily average energy over time.
class _DailyAvgPainter extends CustomPainter {
  final List<DailyEnergySummary> summaries;
  final ThemeData theme;

  _DailyAvgPainter(this.summaries, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (summaries.isEmpty) return;

    final barWidth = (size.width / summaries.length).clamp(4.0, 20.0);
    final spacing = (size.width - barWidth * summaries.length) /
        (summaries.length + 1);

    for (var i = 0; i < summaries.length; i++) {
      final s = summaries[i];
      final x = spacing + i * (barWidth + spacing);
      final barHeight = (s.average / 5) * size.height;
      final y = size.height - barHeight;

      final color = s.average >= 4
          ? Colors.green
          : s.average >= 3
              ? Colors.lightGreen
              : s.average >= 2
                  ? Colors.amber
                  : Colors.red;

      final paint = Paint()
        ..color = color.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
