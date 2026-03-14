import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/medication_tracker_service.dart';
import '../../models/medication_entry.dart';

/// Medication Tracker screen — manage medications, track doses, view adherence.
class MedicationTrackerScreen extends StatefulWidget {
  const MedicationTrackerScreen({super.key});

  @override
  State<MedicationTrackerScreen> createState() => _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends State<MedicationTrackerScreen>
    with SingleTickerProviderStateMixin {
  static const _medsKey = 'medication_tracker_meds';
  static const _logsKey = 'medication_tracker_logs';
  final MedicationTrackerService _service = const MedicationTrackerService();
  late TabController _tabController;
  final List<Medication> _medications = [];
  final List<DoseLog> _logs = [];
  int _nextMedId = 1;
  int _nextLogId = 1;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final medsJson = prefs.getString(_medsKey);
    final logsJson = prefs.getString(_logsKey);
    if (medsJson != null && medsJson.isNotEmpty) {
      try {
        final meds = (jsonDecode(medsJson) as List)
            .map((e) => Medication.fromJson(e as Map<String, dynamic>))
            .toList();
        final logs = logsJson != null && logsJson.isNotEmpty
            ? (jsonDecode(logsJson) as List)
                .map((e) => DoseLog.fromJson(e as Map<String, dynamic>))
                .toList()
            : <DoseLog>[];
        if (mounted) {
          setState(() {
            _medications.addAll(meds);
            _logs.addAll(logs);
            _nextMedId = _medications.length + 1;
            _nextLogId = _logs.length + 1;
          });
          _saveData();
        }
      } catch (_) {}
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_medsKey,
        jsonEncode(_medications.map((m) => m.toJson()).toList()));
    await prefs.setString(_logsKey,
        jsonEncode(_logs.map((l) => l.toJson()).toList()));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _logDose(Medication med, DoseTime time,
      {bool skip = false, String? skipReason, String? sideEffects}) {
    setState(() {
      _logs.add(DoseLog(
        id: 'dl${_nextLogId++}',
        medicationId: med.id,
        timestamp: DateTime.now(),
        scheduledTime: time,
        taken: !skip,
        skipped: skip,
        skipReason: skipReason,
        sideEffects: sideEffects,
      ));
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(skip
          ? '⏭️ ${med.name} skipped (${time.label})'
          : '✅ ${med.name} taken (${time.label})'),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showAddMedicationDialog() {
    String name = '';
    String dosage = '';
    MedForm form = MedForm.tablet;
    MedFrequency frequency = MedFrequency.onceDaily;
    final selectedTimes = <DoseTime>{DoseTime.morning};
    String? notes;
    String? prescribedBy;
    final colors = [
      '#2196F3', '#4CAF50', '#FF9800', '#E91E63',
      '#9C27B0', '#00BCD4', '#FF5722', '#607D8B',
    ];
    String color = colors[_nextMedId % colors.length];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Medication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                      labelText: 'Medication Name *', hintText: 'e.g. Ibuprofen'),
                  onChanged: (v) => name = v,
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                      labelText: 'Dosage *', hintText: 'e.g. 200mg'),
                  onChanged: (v) => dosage = v,
                ),
                const SizedBox(height: 12),
                const Text('Form:', style: TextStyle(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 6,
                  children: MedForm.values
                      .map((f) => ChoiceChip(
                            label: Text('${f.emoji} ${f.label}'),
                            selected: form == f,
                            onSelected: (_) => setDialogState(() => form = f),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                const Text('Frequency:', style: TextStyle(fontWeight: FontWeight.w600)),
                DropdownButton<MedFrequency>(
                  value: frequency,
                  isExpanded: true,
                  items: MedFrequency.values
                      .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => frequency = v);
                  },
                ),
                const SizedBox(height: 12),
                if (frequency != MedFrequency.asNeeded) ...[
                  const Text('Scheduled Times:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 6,
                    children: DoseTime.values
                        .map((t) => FilterChip(
                              label: Text('${t.emoji} ${t.label}'),
                              selected: selectedTimes.contains(t),
                              onSelected: (sel) {
                                setDialogState(() {
                                  if (sel) {
                                    selectedTimes.add(t);
                                  } else if (selectedTimes.length > 1) {
                                    selectedTimes.remove(t);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  decoration: const InputDecoration(
                      labelText: 'Prescribed by', hintText: 'Doctor name (optional)'),
                  onChanged: (v) => prescribedBy = v.isEmpty ? null : v,
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                      labelText: 'Notes', hintText: 'Take with food, etc.'),
                  onChanged: (v) => notes = v.isEmpty ? null : v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (name.trim().isEmpty || dosage.trim().isEmpty) return;
                setState(() {
                  _medications.add(Medication(
                    id: 'med${_nextMedId++}',
                    name: name.trim(),
                    dosage: dosage.trim(),
                    form: form,
                    frequency: frequency,
                    scheduledTimes: selectedTimes.toList()
                      ..sort((a, b) => a.defaultHour.compareTo(b.defaultHour)),
                    notes: notes,
                    prescribedBy: prescribedBy,
                    startDate: DateTime.now(),
                    color: color,
                  ));
                });
                _saveData();
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSkipDialog(Medication med, DoseTime time) {
    final reasons = ['Forgot', 'Side effects', 'Ran out', 'Feeling better', 'Doctor advised', 'Other'];
    String? selected;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Skip ${med.name}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Why are you skipping this dose?'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: reasons
                    .map((r) => ChoiceChip(
                          label: Text(r),
                          selected: selected == r,
                          onSelected: (_) => setDialogState(() => selected = r),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                _logDose(med, time, skip: true, skipReason: selected);
                Navigator.pop(ctx);
              },
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSideEffectDialog(Medication med, DoseTime time) {
    final commonEffects = ['Nausea', 'Headache', 'Dizziness', 'Fatigue', 'Drowsiness', 'Stomach upset'];
    String? selected;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Report Side Effect'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select or type a side effect:'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: commonEffects
                    .map((e) => ChoiceChip(
                          label: Text(e),
                          selected: selected == e,
                          onSelected: (_) => setDialogState(() => selected = e),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                _logDose(med, time, sideEffects: selected);
                Navigator.pop(ctx);
              },
              child: const Text('Log with Side Effect'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.medication), text: 'Meds'),
            Tab(icon: Icon(Icons.schedule), text: 'Schedule'),
            Tab(icon: Icon(Icons.history), text: 'Log'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMedsTab(),
          _buildScheduleTab(),
          _buildLogTab(),
          _buildInsightsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicationDialog,
        tooltip: 'Add Medication',
        child: const Icon(Icons.add),
      ),
    );
  }

  // ─── Meds Tab ──────────────────────────────────────────────────────────
  Widget _buildMedsTab() {
    if (_medications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No medications yet',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Tap + to add your first medication',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final active = _medications.where((m) => m.active).toList();
    final inactive = _medications.where((m) => !m.active).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          Text('Active (${active.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...active.map(_buildMedCard),
        ],
        if (inactive.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Inactive (${inactive.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          ...inactive.map(_buildMedCard),
        ],
      ],
    );
  }

  Widget _buildMedCard(Medication med) {
    final adherence = _service.adherenceRate(med, _logs, med.startDate, DateTime.now());
    final streak = _service.currentStreak(med, _logs);
    final colorValue = int.tryParse(med.color.replaceFirst('#', '0xFF'));
    final medColor = colorValue != null ? Color(colorValue) : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: medColor.withOpacity(0.2),
          child: Text(med.form.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(med.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: med.active ? null : TextDecoration.lineThrough,
            )),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${med.dosage} • ${med.form.label} • ${med.frequency.label}'),
            if (med.notes != null)
              Text(med.notes!,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            Row(children: [
              Text(
                  'Adherence: ${(adherence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 12,
                      color: _colorFromHex(_service.adherenceColor(adherence)))),
              if (streak > 0) ...[
                const SizedBox(width: 12),
                Text('🔥 $streak day streak',
                    style: const TextStyle(fontSize: 12)),
              ],
            ]),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'toggle') {
              setState(() {
                final idx = _medications.indexOf(med);
                _medications[idx] = med.copyWith(active: !med.active);
              });
              _saveData();
            } else if (action == 'delete') {
              setState(() {
                _medications.remove(med);
                _logs.removeWhere((l) => l.medicationId == med.id);
              });
              _saveData();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
                value: 'toggle',
                child: Text(med.active ? 'Deactivate' : 'Reactivate')),
            const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  // ─── Schedule Tab ──────────────────────────────────────────────────────
  Widget _buildScheduleTab() {
    final schedule = _service.todaySchedule(_medications, _logs);

    if (schedule.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No doses scheduled today',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    final taken = schedule.where((s) => s['taken'] as bool).length;
    final total = schedule.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text("Today's Progress",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: total > 0 ? taken / total : 0,
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 8),
              Text('$taken of $total doses taken',
                  style: const TextStyle(color: Colors.grey)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        ...DoseTime.values.map((time) {
          final timeDoses =
              schedule.where((s) => s['doseTime'] == time).toList();
          if (timeDoses.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('${time.emoji} ${time.label}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              ...timeDoses.map((dose) {
                final med = dose['medication'] as Medication;
                final isTaken = dose['taken'] as bool;
                final isSkipped = dose['skipped'] as bool;
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: isTaken
                      ? Colors.green.withOpacity(0.05)
                      : isSkipped
                          ? Colors.orange.withOpacity(0.05)
                          : null,
                  child: ListTile(
                    leading: Icon(
                      isTaken
                          ? Icons.check_circle
                          : isSkipped
                              ? Icons.skip_next
                              : Icons.radio_button_unchecked,
                      color: isTaken
                          ? Colors.green
                          : isSkipped
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    title: Text(med.name),
                    subtitle: Text('${med.dosage} • ${med.form.label}'),
                    trailing: (!isTaken && !isSkipped)
                        ? Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              tooltip: 'Take',
                              onPressed: () => _logDose(med, time),
                            ),
                            IconButton(
                              icon: const Icon(Icons.warning_amber,
                                  color: Colors.deepOrange),
                              tooltip: 'Take with side effect',
                              onPressed: () =>
                                  _showSideEffectDialog(med, time),
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next,
                                  color: Colors.orange),
                              tooltip: 'Skip',
                              onPressed: () => _showSkipDialog(med, time),
                            ),
                          ])
                        : null,
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  // ─── Log Tab ───────────────────────────────────────────────────────────
  Widget _buildLogTab() {
    final dayLogs = _logs
        .where((l) => _sameDay(l.timestamp, _selectedDate))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                _saveData();
              },
              child: Text(
                _sameDay(_selectedDate, DateTime.now())
                    ? 'Today'
                    : '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _sameDay(_selectedDate, DateTime.now())
                  ? null
                  : () => setState(() =>
                      _selectedDate =
                          _selectedDate.add(const Duration(days: 1))),
            ),
          ],
        ),
      ),
      Expanded(
        child: dayLogs.isEmpty
            ? const Center(
                child: Text('No dose logs for this date',
                    style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: dayLogs.length,
                itemBuilder: (_, i) {
                  final log = dayLogs[i];
                  final med = _medications
                      .where((m) => m.id == log.medicationId)
                      .firstOrNull;
                  return Dismissible(
                    key: Key(log.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      final idx = _logs.indexOf(log);
                      setState(() => _logs.remove(log));
                      _saveData();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Log entry removed'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () =>
                              setState(() => _logs.insert(idx, log)),
                        ),
                      ));
                      _saveData();
                    },
                    child: Card(
                      child: ListTile(
                        leading: Icon(
                          log.taken ? Icons.check_circle : Icons.skip_next,
                          color: log.taken ? Colors.green : Colors.orange,
                        ),
                        title: Text(med?.name ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${log.scheduledTime.emoji} ${log.scheduledTime.label} • '
                              '${log.timestamp.hour.toString().padLeft(2, '0')}:'
                              '${log.timestamp.minute.toString().padLeft(2, '0')}',
                            ),
                            if (log.skipped && log.skipReason != null)
                              Text('Reason: ${log.skipReason}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.orange)),
                            if (log.sideEffects != null)
                              Text('Side effects: ${log.sideEffects}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.red)),
                          ],
                        ),
                        isThreeLine:
                            log.skipReason != null || log.sideEffects != null,
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  // ─── Insights Tab ──────────────────────────────────────────────────────
  Widget _buildInsightsTab() {
    final activeMeds = _medications.where((m) => m.active).toList();

    if (activeMeds.isEmpty) {
      return const Center(
        child: Text('Add medications to see insights',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall adherence
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Adherence',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...activeMeds.map((med) {
                  final rate = _service.adherenceRate(
                      med, _logs, med.startDate, DateTime.now());
                  final grade = _service.adherenceGrade(rate);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(med.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500))),
                            Text(grade,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _colorFromHex(
                                      _service.adherenceColor(rate)),
                                )),
                            const SizedBox(width: 8),
                            Text('${(rate * 100).toStringAsFixed(0)}%'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: rate,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          color: _colorFromHex(_service.adherenceColor(rate)),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Streaks
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔥 Streaks',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...activeMeds
                    .where((m) => m.frequency != MedFrequency.asNeeded)
                    .map((med) {
                  final current = _service.currentStreak(med, _logs);
                  final longest = _service.longestStreak(med, _logs);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(child: Text(med.name)),
                      Text('$current days',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Text('Best: $longest',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ]),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Side effects
        ..._buildSideEffectsCards(),

        // Summary stats
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 Summary',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _statRow('Total medications', '${_medications.length}'),
                _statRow('Active', '${activeMeds.length}'),
                _statRow('Total doses logged',
                    '${_logs.where((l) => l.taken).length}'),
                _statRow('Total skipped',
                    '${_logs.where((l) => l.skipped).length}'),
                _statRow('Side effects reported',
                    '${_logs.where((l) => l.sideEffects != null).length}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSideEffectsCards() {
    final result = <Widget>[];
    for (final med in _medications.where((m) => m.active)) {
      final effects = _service.sideEffectFrequency(med.id, _logs);
      if (effects.isEmpty) continue;
      result.add(Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⚠️ Side Effects: ${med.name}',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...effects.entries.take(5).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Expanded(child: Text(e.key)),
                      Text('${e.value}x',
                          style: const TextStyle(color: Colors.red)),
                    ]),
                  )),
            ],
          ),
        ),
      ));
      result.add(const SizedBox(height: 12));
    }
    return result;
  }

  Widget _statRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Color _colorFromHex(String hex) {
    final value = int.tryParse(hex.replaceFirst('#', '0xFF'));
    return value != null ? Color(value) : Colors.blue;
  }
}
