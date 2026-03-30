import 'package:flutter/material.dart';
import '../../core/services/habit_tracker_service.dart';

/// A habit tracker screen for building and maintaining daily habits.
/// Users can add habits, check them off daily, and track streaks.
class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final _service = HabitTrackerService();
  late List<Habit> _habits;

  @override
  void initState() {
    super.initState();
    _habits = _service.getDefaultHabits();
  }

  void _toggleHabit(Habit habit) {
    setState(() => habit.toggleToday());
  }

  void _addHabit() {
    final nameController = TextEditingController();
    final emojiController = TextEditingController(text: '⭐');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g. Exercise',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(
                labelText: 'Emoji',
                hintText: 'e.g. 🏃',
              ),
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
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _habits.add(Habit(
                    name: name,
                    emoji: emojiController.text.trim().isEmpty
                        ? '⭐'
                        : emojiController.text.trim(),
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteHabit(int index) {
    final habit = _habits[index];
    setState(() => _habits.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${habit.name}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => setState(() => _habits.insert(index, habit)),
        ),
      ),
    );
  }

  int get _completedToday => _habits.where((h) => h.isCompletedToday()).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _habits.isEmpty ? 0.0 : _completedToday / _habits.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addHabit,
            tooltip: 'Add habit',
          ),
        ],
      ),
      body: Column(
        children: [
          // Daily progress card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Today\'s Progress',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            progress == 1.0
                                ? Colors.green
                                : theme.colorScheme.primary,
                          ),
                        ),
                        Center(
                          child: Text(
                            '${(progress * 100).round()}%',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_completedToday / ${_habits.length} habits',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Habit list
          Expanded(
            child: _habits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.track_changes,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('No habits yet',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _addHabit,
                          icon: const Icon(Icons.add),
                          label: const Text('Add your first habit'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _habits.length,
                    itemBuilder: (context, index) {
                      final habit = _habits[index];
                      final streak = _service.currentStreak(habit);
                      final weekDays = _service.weekView(habit);
                      final done = habit.isCompletedToday();

                      return Dismissible(
                        key: ValueKey(habit),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child:
                              const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteHabit(index),
                        child: Card(
                          child: InkWell(
                            onTap: () => _toggleHabit(habit),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(habit.emoji,
                                          style: const TextStyle(
                                              fontSize: 28)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              habit.name,
                                              style: theme
                                                  .textTheme.titleMedium
                                                  ?.copyWith(
                                                decoration: done
                                                    ? TextDecoration
                                                        .lineThrough
                                                    : null,
                                              ),
                                            ),
                                            if (streak > 0)
                                              Text(
                                                '🔥 $streak day streak',
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: Colors
                                                      .deepOrange,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        done
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: done
                                            ? Colors.green
                                            : theme.colorScheme
                                                .onSurfaceVariant,
                                        size: 32,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Week view dots
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: weekDays.map((day) {
                                      final label = [
                                        'M', 'T', 'W', 'T', 'F', 'S', 'S'
                                      ][day.date.weekday - 1];
                                      return Column(
                                        children: [
                                          Text(
                                            label,
                                            style: theme
                                                .textTheme.labelSmall
                                                ?.copyWith(
                                              fontWeight: day.isToday
                                                  ? FontWeight.bold
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: day.isFuture
                                                  ? theme.colorScheme
                                                      .surfaceContainerHighest
                                                  : day.completed
                                                      ? Colors.green
                                                      : theme.colorScheme
                                                          .surfaceContainerHighest,
                                              border: day.isToday
                                                  ? Border.all(
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                      width: 2,
                                                    )
                                                  : null,
                                            ),
                                            child: day.completed
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 12,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
