/// Habit Tracker service – manages daily habits with streaks and completion tracking.
///
/// Each habit has a name, icon, target frequency (daily/weekly), and tracks
/// completions by date. The service computes current streaks, completion rates,
/// and weekly/monthly summaries.
class HabitTrackerService {
  List<Habit> getDefaultHabits() => [
        Habit(name: 'Exercise', emoji: '🏃', frequency: HabitFrequency.daily),
        Habit(name: 'Read', emoji: '📚', frequency: HabitFrequency.daily),
        Habit(name: 'Meditate', emoji: '🧘', frequency: HabitFrequency.daily),
        Habit(name: 'Drink Water', emoji: '💧', frequency: HabitFrequency.daily),
        Habit(name: 'Journal', emoji: '✍️', frequency: HabitFrequency.daily),
      ];

  /// Calculate current streak (consecutive days completed ending today or yesterday).
  int currentStreak(Habit habit) {
    final sorted = habit.completedDates.toList()..sort((a, b) => b.compareTo(a));
    if (sorted.isEmpty) return 0;

    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    // Streak must start from today or yesterday
    if (sorted.first != today && sorted.first != yesterday) return 0;

    int streak = 1;
    for (int i = 0; i < sorted.length - 1; i++) {
      final diff = sorted[i].difference(sorted[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Best streak ever achieved.
  int bestStreak(Habit habit) {
    final sorted = habit.completedDates.toList()..sort();
    if (sorted.isEmpty) return 0;

    int best = 1;
    int current = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  /// Completion rate for the last N days.
  double completionRate(Habit habit, {int days = 30}) {
    final today = _dateOnly(DateTime.now());
    int completed = 0;
    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      if (habit.completedDates.contains(date)) completed++;
    }
    return completed / days;
  }

  /// Get completion status for each day of the current week (Mon-Sun).
  List<DayStatus> weekView(Habit habit) {
    final today = _dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      return DayStatus(
        date: date,
        completed: habit.completedDates.contains(date),
        isToday: date == today,
        isFuture: date.isAfter(today),
      );
    });
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

enum HabitFrequency { daily, weekly }

class Habit {
  String name;
  String emoji;
  HabitFrequency frequency;
  final Set<DateTime> completedDates;
  DateTime createdAt;

  Habit({
    required this.name,
    required this.emoji,
    this.frequency = HabitFrequency.daily,
    Set<DateTime>? completedDates,
    DateTime? createdAt,
  })  : completedDates = completedDates ?? {},
        createdAt = createdAt ?? DateTime.now();

  bool isCompletedToday() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return completedDates.contains(todayDate);
  }

  void toggleToday() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (completedDates.contains(todayDate)) {
      completedDates.remove(todayDate);
    } else {
      completedDates.add(todayDate);
    }
  }
}

class DayStatus {
  final DateTime date;
  final bool completed;
  final bool isToday;
  final bool isFuture;

  const DayStatus({
    required this.date,
    required this.completed,
    required this.isToday,
    required this.isFuture,
  });
}
