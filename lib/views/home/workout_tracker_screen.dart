import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/workout_tracker_service.dart';
import '../../models/workout_entry.dart';

/// Workout Tracker screen for logging workouts, viewing history,
/// personal records, and muscle balance insights.
class WorkoutTrackerScreen extends StatefulWidget {
  const WorkoutTrackerScreen({super.key});

  @override
  State<WorkoutTrackerScreen> createState() => _WorkoutTrackerScreenState();
}

class _WorkoutTrackerScreenState extends State<WorkoutTrackerScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'workout_tracker_data';
  late TabController _tabController;
  late WorkoutTrackerService _service;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _service = WorkoutTrackerService();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null && json.isNotEmpty) {
      try {
        _service = WorkoutTrackerService.fromJson(json);
      } catch (_) {
        _service = WorkoutTrackerService();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _service.toJson());
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
        title: const Text('Workout Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Log'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.emoji_events), text: 'PRs'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _LogTab(
                  service: _service,
                  onSaved: () {
                    _save();
                    setState(() {});
                  },
                ),
                _HistoryTab(
                  service: _service,
                  onChanged: () {
                    _save();
                    setState(() {});
                  },
                ),
                _PRsTab(service: _service),
                _InsightsTab(service: _service),
              ],
            ),
    );
  }
}

// ─── LOG TAB ────────────────────────────────────────────────────────────────

class _LogTab extends StatefulWidget {
  final WorkoutTrackerService service;
  final VoidCallback onSaved;

  const _LogTab({required this.service, required this.onSaved});

  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  final List<_ExerciseFormData> _exercises = [];
  int _rpe = 7;
  DateTime _startTime = DateTime.now();
  DateTime? _endTime;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addExercise() {
    setState(() {
      _exercises.add(_ExerciseFormData());
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _saveWorkout() {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }

    final exercises = _exercises.map((e) => e.toExerciseEntry()).toList();
    final workout = WorkoutEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: _startTime,
      endTime: _endTime ?? DateTime.now(),
      name: _nameController.text.isNotEmpty
          ? _nameController.text
          : _generateWorkoutName(exercises),
      exercises: exercises,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      rpeScore: _rpe,
    );

    // Check for new PRs
    final newPRs = widget.service.checkForNewPRs(workout);
    widget.service.addWorkout(workout);
    widget.onSaved();

    // Show success
    String msg = 'Workout logged! ${exercises.length} exercises, '
        '${workout.totalSets} sets, ${workout.totalVolume.toStringAsFixed(0)} kg volume';
    if (newPRs.isNotEmpty) {
      msg += '\n🏆 ${newPRs.length} new PR${newPRs.length > 1 ? 's' : ''}!';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );

    // Reset form
    setState(() {
      _nameController.clear();
      _noteController.clear();
      _exercises.clear();
      _rpe = 7;
      _startTime = DateTime.now();
      _endTime = null;
    });
  }

  String _generateWorkoutName(List<ExerciseEntry> exercises) {
    final groups = exercises.expand((e) => e.muscleGroups).toSet();
    if (groups.isEmpty) return 'Workout';
    if (groups.every((g) => g.isUpperBody)) return 'Upper Body';
    if (groups.every((g) => g.isLowerBody)) return 'Leg Day';
    if (groups.contains(MuscleGroup.chest) &&
        groups.contains(MuscleGroup.triceps)) return 'Push Day';
    if (groups.contains(MuscleGroup.back) &&
        groups.contains(MuscleGroup.biceps)) return 'Pull Day';
    if (groups.length >= 4) return 'Full Body';
    return groups.take(2).map((g) => g.label).join(' & ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Workout name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Workout Name (optional)',
              hintText: 'e.g., Push Day, Full Body',
              prefixIcon: Icon(Icons.fitness_center),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Time row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    'Start: ${_formatTime(_startTime)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_startTime),
                    );
                    if (time != null) {
                      setState(() {
                        _startTime = DateTime(
                          _startTime.year, _startTime.month, _startTime.day,
                          time.hour, time.minute,
                        );
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.timer_off),
                  label: Text(
                    _endTime != null
                        ? 'End: ${_formatTime(_endTime!)}'
                        : 'Set End Time',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                          _endTime ?? DateTime.now()),
                    );
                    if (time != null) {
                      setState(() {
                        _endTime = DateTime(
                          _startTime.year, _startTime.month, _startTime.day,
                          time.hour, time.minute,
                        );
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // RPE slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Effort (RPE): $_rpe/10',
                      style: theme.textTheme.titleSmall),
                  Slider(
                    value: _rpe.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$_rpe',
                    onChanged: (v) => setState(() => _rpe = v.round()),
                  ),
                  Text(
                    _rpeDescription(_rpe),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Exercises header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Exercises', style: theme.textTheme.titleMedium),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Exercise'),
                onPressed: _addExercise,
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_exercises.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.fitness_center, size: 48,
                        color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text('Tap "Add Exercise" to start building your workout',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),

          // Exercise cards
          ...List.generate(_exercises.length, (i) {
            return _ExerciseCard(
              key: ValueKey(_exercises[i].key),
              data: _exercises[i],
              index: i,
              onRemove: () => _removeExercise(i),
              onChanged: () => setState(() {}),
            );
          }),

          const SizedBox(height: 16),

          // Note
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'How did it feel?',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Save button
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: Text('Save Workout (${_exercises.length} exercises)'),
            onPressed: _exercises.isNotEmpty ? _saveWorkout : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _rpeDescription(int rpe) {
    switch (rpe) {
      case 1: return 'Very light — barely any effort';
      case 2: return 'Light — easy warm-up';
      case 3: return 'Moderate — comfortable pace';
      case 4: return 'Somewhat hard — starting to feel it';
      case 5: return 'Hard — challenging but manageable';
      case 6: return 'Harder — could do a few more reps';
      case 7: return 'Very hard — 2-3 reps left in the tank';
      case 8: return 'Really hard — 1-2 reps left';
      case 9: return 'Near max — could maybe do 1 more';
      case 10: return 'Maximum effort — nothing left';
      default: return '';
    }
  }
}

// ─── EXERCISE FORM DATA ─────────────────────────────────────────────────────

class _ExerciseFormData {
  final int key = DateTime.now().microsecondsSinceEpoch;
  String name = '';
  ExerciseType type = ExerciseType.strength;
  final List<MuscleGroup> muscleGroups = [];
  final List<_SetData> sets = [_SetData()];

  ExerciseEntry toExerciseEntry() {
    return ExerciseEntry(
      name: name.isNotEmpty ? name : 'Unknown Exercise',
      type: type,
      muscleGroups: List.of(muscleGroups),
      sets: sets.map((s) => ExerciseSet(
        reps: s.reps,
        weightKg: s.weight,
        isWarmup: s.isWarmup,
      )).toList(),
    );
  }
}

class _SetData {
  int reps = 10;
  double weight = 0;
  bool isWarmup = false;
}

// ─── EXERCISE CARD ──────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final _ExerciseFormData data;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ExerciseCard({
    super.key,
    required this.data,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text('Exercise ${index + 1}',
                    style: theme.textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove exercise',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Exercise name
            TextFormField(
              initialValue: data.name,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g., Bench Press, Squat',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                data.name = v;
                onChanged();
              },
            ),
            const SizedBox(height: 8),

            // Type selector
            Row(
              children: [
                const Text('Type: ', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                ...ExerciseType.values.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ChoiceChip(
                    label: Text(t.label, style: const TextStyle(fontSize: 12)),
                    selected: data.type == t,
                    onSelected: (_) {
                      data.type = t;
                      onChanged();
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                )),
              ],
            ),
            const SizedBox(height: 8),

            // Muscle groups
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: MuscleGroup.values
                  .where((g) => g != MuscleGroup.fullBody)
                  .map((g) => FilterChip(
                        label: Text('${g.emoji} ${g.label}',
                            style: const TextStyle(fontSize: 11)),
                        selected: data.muscleGroups.contains(g),
                        onSelected: (selected) {
                          if (selected) {
                            data.muscleGroups.add(g);
                          } else {
                            data.muscleGroups.remove(g);
                          }
                          onChanged();
                        },
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Sets
            Text('Sets', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            ...List.generate(data.sets.length, (i) {
              final s = data.sets[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text('${i + 1}.',
                          style: theme.textTheme.bodySmall),
                    ),
                    SizedBox(
                      width: 70,
                      child: TextFormField(
                        initialValue: s.reps.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Reps',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13),
                        onChanged: (v) {
                          s.reps = int.tryParse(v) ?? 0;
                          onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: s.weight > 0
                            ? s.weight.toString()
                            : '',
                        decoration: const InputDecoration(
                          labelText: 'kg',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13),
                        onChanged: (v) {
                          s.weight = double.tryParse(v) ?? 0;
                          onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('W', style: TextStyle(fontSize: 11)),
                      selected: s.isWarmup,
                      onSelected: (v) {
                        s.isWarmup = v;
                        onChanged();
                      },
                      tooltip: 'Warmup set',
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                    if (data.sets.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            size: 18),
                        onPressed: () {
                          data.sets.removeAt(i);
                          onChanged();
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Set', style: TextStyle(fontSize: 12)),
              onPressed: () {
                // Copy last set values for convenience
                final last = data.sets.last;
                data.sets.add(_SetData()
                  ..reps = last.reps
                  ..weight = last.weight);
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HISTORY TAB ────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final WorkoutTrackerService service;
  final VoidCallback onChanged;

  const _HistoryTab({required this.service, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workouts = service.workouts.reversed.toList();

    if (workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 64,
                color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No workouts logged yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.outline,
                )),
            const SizedBox(height: 8),
            Text('Start logging to see your history here',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                )),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final w = workouts[index];
        final duration = w.durationMinutes;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _rpeColor(w.rpeScore ?? 5),
              child: Text(
                w.rpeScore?.toString() ?? '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(w.name ?? 'Workout'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatDate(w.startTime)}'
                  '${duration != null ? ' • ${duration}min' : ''}'
                  ' • ${w.totalSets} sets • ${w.totalVolume.toStringAsFixed(0)}kg',
                  style: theme.textTheme.bodySmall,
                ),
                if (w.muscleGroupsWorked.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      w.muscleGroupsWorked.map((g) => g.emoji).join(' '),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () {
                service.removeWorkout(w.id);
                onChanged();
              },
            ),
          ),
        );
      },
    );
  }

  Color _rpeColor(int rpe) {
    if (rpe <= 3) return Colors.green;
    if (rpe <= 5) return Colors.blue;
    if (rpe <= 7) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime dt) =>
      '${dt.month}/${dt.day}/${dt.year}';
}

// ─── PRs TAB ────────────────────────────────────────────────────────────────

class _PRsTab extends StatelessWidget {
  final WorkoutTrackerService service;

  const _PRsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prs = service.getPersonalRecords();

    if (prs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 64,
                color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No personal records yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.outline,
                )),
            const SizedBox(height: 8),
            Text('Log workouts to start tracking PRs',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                )),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prs.length,
      itemBuilder: (context, index) {
        final pr = prs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.amber,
              child: Icon(Icons.emoji_events, color: Colors.white),
            ),
            title: Text(pr.exerciseName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Max: ${pr.maxWeight}kg • ${pr.maxReps} reps • '
              '${pr.maxVolume.toStringAsFixed(0)}kg volume\n'
              'Set on ${pr.achievedAt.month}/${pr.achievedAt.day}/${pr.achievedAt.year}',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

// ─── INSIGHTS TAB ───────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final WorkoutTrackerService service;

  const _InsightsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workouts = service.workouts;

    if (workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('Log some workouts to see insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.outline,
                )),
          ],
        ),
      );
    }

    final report = service.generateReport();
    final balance = report.muscleBalance;
    final streak = report.streak;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary cards
          Row(
            children: [
              _StatCard(
                icon: Icons.fitness_center,
                label: 'Workouts',
                value: '${report.totalWorkouts}',
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _StatCard(
                icon: Icons.monitor_weight,
                label: 'Volume',
                value: '${(report.totalVolume / 1000).toStringAsFixed(1)}t',
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _StatCard(
                icon: Icons.timer,
                label: 'Avg Duration',
                value: '${report.avgWorkoutMinutes.toStringAsFixed(0)}m',
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: '${streak.currentStreak}w',
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              _StatCard(
                icon: Icons.star,
                label: 'Best Streak',
                value: '${streak.longestStreak}w',
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              _StatCard(
                icon: Icons.speed,
                label: 'Avg RPE',
                value: report.avgRpe > 0
                    ? report.avgRpe.toStringAsFixed(1)
                    : '—',
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Muscle balance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Muscle Balance',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (balance.frequencyByGroup.isNotEmpty) ...[
                    ...balance.frequencyByGroup.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)),
                  ].map((e) {
                    final maxFreq = balance.frequencyByGroup.values
                        .fold(1, (a, b) => a > b ? a : b);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text('${e.key.emoji} ${e.key.label}',
                                style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: e.value / maxFreq,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${e.value}x',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  if (balance.neglectedGroups.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, size: 18,
                              color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Neglected: ${balance.neglectedGroups.map((g) => g.label).join(', ')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Top exercises
          if (report.exerciseFrequency.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top Exercises',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...service.getTopExercises(n: 5).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: const TextStyle(fontSize: 13)),
                          Text('${e.value}x',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Tips
          if (report.tips.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡 Tips', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...report.tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(tip,
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── STAT CARD ──────────────────────────────────────────────────────────────

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
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
