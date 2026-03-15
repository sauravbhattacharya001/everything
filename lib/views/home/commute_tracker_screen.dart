import 'package:flutter/material.dart';
import '../../core/services/screen_persistence.dart';
import '../../core/services/commute_tracker_service.dart';
import '../../models/commute_entry.dart';

/// Commute Tracker screen — log daily commutes, view history,
/// track costs, CO₂ emissions, and commute patterns.
class CommuteTrackerScreen extends StatefulWidget {
  const CommuteTrackerScreen({super.key});

  @override
  State<CommuteTrackerScreen> createState() => _CommuteTrackerScreenState();
}

class _CommuteTrackerScreenState extends State<CommuteTrackerScreen>
    with SingleTickerProviderStateMixin {
  final CommuteTrackerService _service = const CommuteTrackerService();
  late TabController _tabController;
  final List<CommuteEntry> _entries = [];
  final _persistence = ScreenPersistence<CommuteEntry>(
    storageKey: 'commute_tracker_entries',
    toJson: (e) => e.toJson(),
    fromJson: CommuteEntry.fromJson,
  );
  int _nextId = 1;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final saved = await _persistence.load();
    if (saved.isNotEmpty) {
      setState(() {
        _entries.addAll(saved);
        for (final e in saved) {
          final numPart = int.tryParse(e.id.replaceAll(RegExp(r'[^0-9]'), ''));
          if (numPart != null && numPart >= _nextId) _nextId = numPart + 1;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addEntry(CommuteEntry entry) {
    setState(() => _entries.add(entry));
    _persistence.save(_entries);
  }

  void _deleteEntry(String id) {
    setState(() => _entries.removeWhere((e) => e.id == id));
    _persistence.save(_entries);
  }

  void _showLogDialog({bool isReturn = false}) {
    var mode = CommuteMode.car;
    final durationCtl = TextEditingController(text: '30');
    final distanceCtl = TextEditingController();
    final costCtl = TextEditingController();
    final notesCtl = TextEditingController();
    CommuteComfort? comfort;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(isReturn ? 'Log Return Trip' : 'Log Commute'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode selector
                const Text('Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: CommuteMode.values.map((m) {
                    final sel = mode == m;
                    return ChoiceChip(
                      label: Text('${m.emoji} ${m.label}'),
                      selected: sel,
                      onSelected: (_) => setDState(() => mode = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Duration
                TextField(
                  controller: durationCtl,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    prefixIcon: Icon(Icons.timer),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                // Distance
                TextField(
                  controller: distanceCtl,
                  decoration: const InputDecoration(
                    labelText: 'Distance (km, optional)',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                // Cost
                TextField(
                  controller: costCtl,
                  decoration: const InputDecoration(
                    labelText: 'Cost (\$, optional)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                // Comfort
                const Text('Comfort',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: CommuteComfort.values.map((c) {
                    final sel = comfort == c;
                    return ChoiceChip(
                      label: Text('${c.emoji} ${c.label}'),
                      selected: sel,
                      onSelected: (_) => setDState(() => comfort = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                // Notes
                TextField(
                  controller: notesCtl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
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
                final dur = int.tryParse(durationCtl.text);
                if (dur == null || dur <= 0) return;
                final entry = CommuteEntry(
                  id: 'c${_nextId++}',
                  date: DateTime.now(),
                  mode: mode,
                  durationMinutes: dur,
                  distanceKm: double.tryParse(distanceCtl.text),
                  cost: double.tryParse(costCtl.text),
                  comfort: comfort,
                  notes:
                      notesCtl.text.trim().isEmpty ? null : notesCtl.text.trim(),
                  isReturn: isReturn,
                );
                _addEntry(entry);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab: Log ───
  Widget _buildLogTab() {
    final today = _service.entriesForDate(_entries, DateTime.now());
    final todayMin = _service.totalMinutes(today);
    final todayCost = _service.totalCost(today);
    final todayCo2 = _service.totalCo2(today);

    return Column(
      children: [
        // Today's summary strip
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryChip('🧭', '${today.length} trips'),
              _summaryChip('⏱️', '$todayMin min'),
              _summaryChip('💰', '\$${todayCost.toStringAsFixed(2)}'),
              _summaryChip('🌿', '${todayCo2.toStringAsFixed(1)} kg'),
            ],
          ),
        ),
        // Quick-log buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showLogDialog(),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Log Going'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showLogDialog(isReturn: true),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Log Return'),
                ),
              ),
            ],
          ),
        ),
        // Today's entries
        Expanded(
          child: today.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🚀', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 8),
                      Text('No commutes logged today'),
                      Text('Tap a button above to start',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: today.length,
                  itemBuilder: (_, i) {
                    final e = today[i];
                    return Dismissible(
                      key: Key(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child:
                            const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteEntry(e.id),
                      child: ListTile(
                        leading: Text(e.mode.emoji,
                            style: const TextStyle(fontSize: 28)),
                        title: Text(
                            '${e.mode.label}${e.isReturn ? ' (return)' : ''}'),
                        subtitle: Text(
                            '${e.durationMinutes} min'
                            '${e.distanceKm != null ? ' · ${e.distanceKm!.toStringAsFixed(1)} km' : ''}'
                            '${e.cost != null ? ' · \$${e.cost!.toStringAsFixed(2)}' : ''}'),
                        trailing: e.comfort != null
                            ? Text(e.comfort!.emoji,
                                style: const TextStyle(fontSize: 20))
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _summaryChip(String emoji, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─── Tab: History ───
  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Date nav
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() =>
                    _selectedDate =
                        _selectedDate.subtract(const Duration(days: 1))),
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
                  '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final tomorrow =
                      _selectedDate.add(const Duration(days: 1));
                  if (!tomorrow.isAfter(DateTime.now())) {
                    setState(() => _selectedDate = tomorrow);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (_) {
              final dayEntries =
                  _service.entriesForDate(_entries, _selectedDate);
              if (dayEntries.isEmpty) {
                return const Center(child: Text('No commutes on this date'));
              }
              return ListView.builder(
                itemCount: dayEntries.length,
                itemBuilder: (_, i) {
                  final e = dayEntries[i];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Text(e.mode.emoji,
                          style: const TextStyle(fontSize: 28)),
                      title: Text(
                          '${e.mode.label}${e.isReturn ? ' ↩' : ' →'}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.durationMinutes} min'
                              '${e.distanceKm != null ? ' · ${e.distanceKm!.toStringAsFixed(1)} km' : ''}'
                              '${e.cost != null ? ' · \$${e.cost!.toStringAsFixed(2)}' : ''}'),
                          if (e.notes != null)
                            Text(e.notes!,
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey)),
                        ],
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (e.comfort != null)
                            Text(e.comfort!.emoji,
                                style: const TextStyle(fontSize: 18)),
                          Text(
                            '${e.co2Kg.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Tab: Breakdown ───
  Widget _buildBreakdownTab() {
    final monthly = _service.currentMonthEntries(_entries);
    final dist = _service.modeDistribution(monthly);
    final sorted = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mode Breakdown (This Month)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (sorted.isEmpty)
            const Center(child: Text('No data yet')),
          ...sorted.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${e.key.emoji} ${e.key.label}'),
                        Text('${e.value.toStringAsFixed(1)}%'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: e.value / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              )),
          const Divider(height: 32),
          const Text('CO₂ by Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...CommuteMode.values.where((m) => m.co2PerKm > 0).map(
            (m) {
              final modeEntries =
                  monthly.where((e) => e.mode == m).toList();
              final co2 = _service.totalCo2(modeEntries);
              return co2 > 0
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${m.emoji} ${m.label}'),
                          Text('${co2.toStringAsFixed(1)} kg CO₂',
                              style: TextStyle(
                                  color: co2 > 10
                                      ? Colors.red
                                      : Colors.green)),
                        ],
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // ─── Tab: Insights ───
  Widget _buildInsightsTab() {
    final insights = _service.monthlyInsights(_entries);
    final streak = _service.currentStreak(_entries);
    final avgComf = _service.avgComfort(_entries);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak + comfort
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('🔥',
                            style: TextStyle(fontSize: 32)),
                        Text('$streak day${streak != 1 ? 's' : ''}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const Text('streak',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                            avgComf >= 4
                                ? '😊'
                                : avgComf >= 3
                                    ? '😐'
                                    : avgComf > 0
                                        ? '😟'
                                        : '➖',
                            style: const TextStyle(fontSize: 32)),
                        Text(avgComf > 0
                            ? '${avgComf.toStringAsFixed(1)}/5'
                            : 'N/A',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const Text('avg comfort',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Monthly Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...insights.map((ins) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(ins.emoji,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(ins.label),
                  trailing: Text(ins.value,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: ins.comparison != null
                      ? Text(ins.comparison!)
                      : null,
                ),
              )),
          const SizedBox(height: 16),
          // Green tip
          Card(
            color: Colors.green.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('🌱', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Try biking or walking once a week to reduce your carbon footprint and boost your mood!',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commute Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_road), text: 'Log'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Breakdown'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogTab(),
          _buildHistoryTab(),
          _buildBreakdownTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }
}
