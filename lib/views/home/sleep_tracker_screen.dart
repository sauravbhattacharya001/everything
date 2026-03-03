import 'package:flutter/material.dart';
import '../../core/services/sleep_tracker_service.dart';
import '../../models/sleep_entry.dart';

/// Sleep Tracker screen for logging sleep duration, quality, and viewing
/// sleep patterns over time.
class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen>
    with SingleTickerProviderStateMixin {
  final SleepTrackerService _service = SleepTrackerService();
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
        title: const Text('Sleep Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bedtime), text: 'Log'),
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
                _HistoryTab(
                    service: _service, onChanged: () => setState(() {})),
                _InsightsTab(service: _service),
              ],
            ),
    );
  }
}

// ─── LOG TAB ────────────────────────────────────────────────────────────────

class _LogTab extends StatefulWidget {
  final SleepTrackerService service;
  final VoidCallback onLogged;

  const _LogTab({required this.service, required this.onLogged});

  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  SleepQuality _selectedQuality = SleepQuality.fair;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _awakeningsController = TextEditingController();
  final Set<SleepFactor> _selectedFactors = {};
  TimeOfDay _bedtime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _noteController.dispose();
    _awakeningsController.dispose();
    super.dispose();
  }

  double get _estimatedDuration {
    int bedMinutes = _bedtime.hour * 60 + _bedtime.minute;
    int wakeMinutes = _wakeTime.hour * 60 + _wakeTime.minute;
    if (wakeMinutes <= bedMinutes) wakeMinutes += 24 * 60;
    return (wakeMinutes - bedMinutes) / 60.0;
  }

  String get _durationText {
    final hours = _estimatedDuration.floor();
    final minutes = ((_estimatedDuration - hours) * 60).round();
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  Color get _durationColor {
    final h = _estimatedDuration;
    if (h < 5) return Colors.red;
    if (h < 6) return Colors.orange;
    if (h < 7) return Colors.amber;
    if (h <= 9) return Colors.green;
    return Colors.orange; // oversleeping
  }

  Future<void> _pickTime(bool isBedtime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBedtime ? _bedtime : _wakeTime,
    );
    if (picked != null) {
      setState(() {
        if (isBedtime) {
          _bedtime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _logSleep() async {
    final bedtime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _bedtime.hour,
      _bedtime.minute,
    ).subtract(Duration(
      // If bedtime is in the evening, it's the night before wake date
      days: _bedtime.hour >= 12 ? 1 : 0,
    ));

    final wakeTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _wakeTime.hour,
      _wakeTime.minute,
    );

    final entry = SleepEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bedtime: bedtime,
      wakeTime: wakeTime,
      quality: _selectedQuality,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      factors: _selectedFactors.toList(),
      awakenings: int.tryParse(_awakeningsController.text),
    );

    await widget.service.addEntry(entry);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Sleep logged: $_durationText, ${_selectedQuality.label}'),
          backgroundColor: Colors.indigo,
        ),
      );
      setState(() {
        _noteController.clear();
        _awakeningsController.clear();
        _selectedFactors.clear();
        _selectedQuality = SleepQuality.fair;
      });
      widget.onLogged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date picker
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.indigo),
              title: Text(
                'Wake Date: ${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
              ),
              trailing: const Icon(Icons.edit),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 12),

          // Time pickers
          Row(
            children: [
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => _pickTime(true),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.bedtime,
                              color: Colors.indigo, size: 32),
                          const SizedBox(height: 8),
                          const Text('Bedtime',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            _bedtime.format(context),
                            style: theme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    _durationText,
                    style: TextStyle(
                      color: _durationColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => _pickTime(false),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.wb_sunny,
                              color: Colors.orange, size: 32),
                          const SizedBox(height: 8),
                          const Text('Wake Up',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            _wakeTime.format(context),
                            style: theme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quality selector
          Text('Sleep Quality',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: SleepQuality.values.map((q) {
              final isSelected = q == _selectedQuality;
              return GestureDetector(
                onTap: () => setState(() => _selectedQuality = q),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.indigo.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Colors.indigo, width: 2)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(q.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        q.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.indigo : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Factors
          Text('Sleep Factors',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SleepFactor.values.map((f) {
              final isSelected = _selectedFactors.contains(f);
              return FilterChip(
                label: Text('${f.emoji} ${f.label}'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedFactors.add(f);
                    } else {
                      _selectedFactors.remove(f);
                    }
                  });
                },
                selectedColor: Colors.indigo.withOpacity(0.2),
                checkmarkColor: Colors.indigo,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Awakenings
          TextField(
            controller: _awakeningsController,
            decoration: const InputDecoration(
              labelText: 'Night Awakenings',
              hintText: 'How many times did you wake up?',
              prefixIcon: Icon(Icons.notifications_active),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),

          // Note
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Dreams, thoughts, how you feel...',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // Log button
          FilledButton.icon(
            onPressed: _logSleep,
            icon: const Icon(Icons.check),
            label: const Text('Log Sleep'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HISTORY TAB ────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final SleepTrackerService service;
  final VoidCallback onChanged;

  const _HistoryTab({required this.service, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = service.entries;
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bedtime, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No sleep entries yet',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('Log your first night\'s sleep!',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _SleepEntryCard(
          entry: entry,
          onDelete: () async {
            await service.deleteEntry(entry.id);
            onChanged();
          },
        );
      },
    );
  }
}

class _SleepEntryCard extends StatelessWidget {
  final SleepEntry entry;
  final VoidCallback onDelete;

  const _SleepEntryCard({required this.entry, required this.onDelete});

  Color get _qualityColor {
    switch (entry.quality) {
      case SleepQuality.terrible:
        return Colors.red;
      case SleepQuality.poor:
        return Colors.orange;
      case SleepQuality.fair:
        return Colors.amber;
      case SleepQuality.good:
        return Colors.lightGreen;
      case SleepQuality.excellent:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(entry.quality.emoji,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.wakeTime.month}/${entry.wakeTime.day}/${entry.wakeTime.year}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_formatTime(entry.bedtime)} → ${_formatTime(entry.wakeTime)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _qualityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _qualityColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    entry.durationFormatted,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _qualityColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  color: Colors.grey,
                ),
              ],
            ),
            if (entry.awakenings != null && entry.awakenings! > 0) ...[
              const SizedBox(height: 8),
              Text(
                '💤 Woke up ${entry.awakenings} time${entry.awakenings == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
            if (entry.factors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: entry.factors
                    .map((f) => Chip(
                          label: Text('${f.emoji} ${f.label}',
                              style: const TextStyle(fontSize: 12)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(entry.note!,
                  style:
                      TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $amPm';
  }
}

// ─── INSIGHTS TAB ───────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final SleepTrackerService service;

  const _InsightsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final entries = service.entries;
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Need data for insights',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('Log at least a few nights of sleep',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final avgDuration = service.overallAvgDuration();
    final avgQuality = service.overallAvgQuality();
    final avgBedtime = service.avgBedtimeHour(30);
    final avgWake = service.avgWakeTimeHour(30);
    final consistency = service.consistencyScore(14);
    final debt = service.sleepDebt(7);
    final streak = service.currentStreak();
    final bestStreak = service.bestStreak();
    final factorFreq = service.factorFrequency();
    final qualityByFactor = service.qualityByFactor();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary cards
          _buildSummaryCards(
            avgDuration: avgDuration,
            avgQuality: avgQuality,
            consistency: consistency,
            debt: debt,
          ),
          const SizedBox(height: 16),

          // Streaks
          _buildStreakCard(streak, bestStreak),
          const SizedBox(height: 16),

          // Schedule
          if (avgBedtime != null && avgWake != null)
            _buildScheduleCard(avgBedtime, avgWake),
          if (avgBedtime != null && avgWake != null)
            const SizedBox(height: 16),

          // Duration trend (last 14 days)
          _buildTrendCard(context, service),
          const SizedBox(height: 16),

          // Factor analysis
          if (factorFreq.isNotEmpty)
            _buildFactorCard(factorFreq, qualityByFactor),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    double? avgDuration,
    double? avgQuality,
    double? consistency,
    double? debt,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.access_time,
            label: 'Avg Duration',
            value: avgDuration != null
                ? '${avgDuration.toStringAsFixed(1)}h'
                : '--',
            color: _durationColor(avgDuration ?? 0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.star,
            label: 'Avg Quality',
            value: avgQuality != null
                ? avgQuality.toStringAsFixed(1)
                : '--',
            color: _qualityColor(avgQuality ?? 0),
            suffix: '/5',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule,
            label: 'Consistency',
            value: '${consistency?.round() ?? 0}%',
            color: consistency != null && consistency > 70
                ? Colors.green
                : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(int streak, int best) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department,
                color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak day${streak == 1 ? '' : 's'} current streak',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Best: $best day${best == 1 ? '' : 's'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              streak > 0 ? '🔥' : '💤',
              style: const TextStyle(fontSize: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(double avgBedtime, double avgWake) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Average Schedule',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.bedtime,
                          color: Colors.indigo, size: 28),
                      const SizedBox(height: 4),
                      Text(_formatHour(avgBedtime),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text('Bedtime',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.wb_sunny,
                          color: Colors.orange, size: 28),
                      const SizedBox(height: 4),
                      Text(_formatHour(avgWake),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text('Wake Up',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(BuildContext context, SleepTrackerService service) {
    final durationTrend = service.durationTrend(14);
    final qualityTrend = service.qualityTrend(14);

    if (durationTrend.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Last 14 Days',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            // Duration bars
            const Text('Duration',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(14, (i) {
                  final date = DateTime.now().subtract(Duration(days: 13 - i));
                  final dateKey = DateTime(date.year, date.month, date.day);
                  final hours = durationTrend[dateKey];
                  final barHeight = hours != null
                      ? (hours / 12 * 50).clamp(2.0, 50.0)
                      : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Tooltip(
                        message: hours != null
                            ? '${date.month}/${date.day}: ${hours.toStringAsFixed(1)}h'
                            : '${date.month}/${date.day}: No data',
                        child: Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: hours != null
                                ? _durationColor(hours)
                                : Colors.grey[300],
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Quality dots
            const Text('Quality',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(14, (i) {
                final date = DateTime.now().subtract(Duration(days: 13 - i));
                final dateKey = DateTime(date.year, date.month, date.day);
                final quality = qualityTrend[dateKey];
                return Expanded(
                  child: Tooltip(
                    message: quality != null
                        ? '${date.month}/${date.day}: ${quality.toStringAsFixed(1)}/5'
                        : '${date.month}/${date.day}: No data',
                    child: Container(
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: quality != null
                            ? _qualityColor(quality)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('14 days ago',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                Text('Today',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorCard(
    Map<SleepFactor, int> frequency,
    Map<SleepFactor, double> qualityMap,
  ) {
    final topFactors = frequency.entries.take(8).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Factor Analysis',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('How factors correlate with your sleep quality',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            ...topFactors.map((entry) {
              final factor = entry.key;
              final count = entry.value;
              final avgQ = qualityMap[factor];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(factor.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(factor.label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          Text('$count time${count == 1 ? '' : 's'}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    if (avgQ != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _qualityColor(avgQ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${avgQ.toStringAsFixed(1)}/5',
                          style: TextStyle(
                            color: _qualityColor(avgQ),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _durationColor(double hours) {
    if (hours < 5) return Colors.red;
    if (hours < 6) return Colors.orange;
    if (hours < 7) return Colors.amber;
    if (hours <= 9) return Colors.green;
    return Colors.orange;
  }

  Color _qualityColor(double quality) {
    if (quality < 1.5) return Colors.red;
    if (quality < 2.5) return Colors.orange;
    if (quality < 3.5) return Colors.amber;
    if (quality < 4.5) return Colors.lightGreen;
    return Colors.green;
  }

  String _formatHour(double hour) {
    final h = hour.floor();
    final m = ((hour - h) * 60).round();
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final amPm = h >= 12 && h < 24 ? 'PM' : 'AM';
    return '$displayH:${m.toString().padLeft(2, '0')} $amPm';
  }
}

// ─── STAT CARD WIDGET ───────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? suffix;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (suffix != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      suffix!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
