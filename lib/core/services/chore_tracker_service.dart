import '../../models/chore_entry.dart';

/// Service for chore tracking analytics and logic.
class ChoreTrackerService {
  const ChoreTrackerService();

  /// Whether a chore is overdue based on its frequency and last completion.
  bool isOverdue(Chore chore, List<ChoreCompletion> completions) {
    if (chore.frequency == ChoreFrequency.asNeeded) return false;
    final last = lastCompletion(chore.id, completions);
    if (last == null) return true;
    final daysSince = DateTime.now().difference(last.completedAt).inDays;
    return daysSince >= chore.frequency.intervalDays;
  }

  /// Days until next due (negative = overdue).
  int daysUntilDue(Chore chore, List<ChoreCompletion> completions) {
    if (chore.frequency == ChoreFrequency.asNeeded) return 999;
    final last = lastCompletion(chore.id, completions);
    if (last == null) return -1;
    final daysSince = DateTime.now().difference(last.completedAt).inDays;
    return chore.frequency.intervalDays - daysSince;
  }

  /// Get the last completion for a chore.
  ChoreCompletion? lastCompletion(
      String choreId, List<ChoreCompletion> completions) {
    final matches = completions.where((c) => c.choreId == choreId).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return matches.isEmpty ? null : matches.first;
  }

  /// Count completions in a date range.
  int completionsInRange(String choreId, List<ChoreCompletion> completions,
      DateTime start, DateTime end) {
    return completions
        .where((c) =>
            c.choreId == choreId &&
            !c.completedAt.isBefore(start) &&
            c.completedAt.isBefore(end))
        .length;
  }

  /// Current streak: consecutive on-time completions.
  int currentStreak(Chore chore, List<ChoreCompletion> completions) {
    if (chore.frequency == ChoreFrequency.asNeeded) return 0;
    final matches = completions.where((c) => c.choreId == chore.id).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    if (matches.isEmpty) return 0;
    int streak = 0;
    DateTime expected = DateTime.now();
    for (final comp in matches) {
      final diff = expected.difference(comp.completedAt).inDays;
      if (diff > chore.frequency.intervalDays + 1) break;
      streak++;
      expected = comp.completedAt;
    }
    return streak;
  }

  /// Overall adherence rate (0.0 - 1.0) for the last N days.
  double adherenceRate(
      Chore chore, List<ChoreCompletion> completions, int days) {
    if (chore.frequency == ChoreFrequency.asNeeded ||
        chore.frequency.intervalDays == 0) return 1.0;
    final start = DateTime.now().subtract(Duration(days: days));
    final count = completionsInRange(chore.id, completions, start, DateTime.now());
    final expected = days / chore.frequency.intervalDays;
    if (expected <= 0) return 1.0;
    return (count / expected).clamp(0.0, 1.0);
  }

  /// Completions per room in range.
  Map<ChoreRoom, int> completionsByRoom(
      List<Chore> chores, List<ChoreCompletion> completions,
      DateTime start, DateTime end) {
    final map = <ChoreRoom, int>{};
    final choreMap = {for (final c in chores) c.id: c};
    for (final comp in completions) {
      if (comp.completedAt.isBefore(start) || !comp.completedAt.isBefore(end)) {
        continue;
      }
      final chore = choreMap[comp.choreId];
      if (chore != null) {
        map[chore.room] = (map[chore.room] ?? 0) + 1;
      }
    }
    return map;
  }

  /// Average completion rating for a chore.
  double averageRating(String choreId, List<ChoreCompletion> completions) {
    final matches = completions.where((c) => c.choreId == choreId).toList();
    if (matches.isEmpty) return 0;
    return matches.map((c) => c.rating).reduce((a, b) => a + b) /
        matches.length;
  }

  /// Total estimated time spent (from durations or effort estimates).
  int totalMinutesSpent(
      String choreId, List<Chore> chores, List<ChoreCompletion> completions) {
    final chore = chores.where((c) => c.id == choreId).firstOrNull;
    final matches = completions.where((c) => c.choreId == choreId).toList();
    int total = 0;
    for (final comp in matches) {
      total += comp.durationMinutes > 0
          ? comp.durationMinutes
          : (chore?.effort.estimatedMinutes ?? 10);
    }
    return total;
  }

  /// Sort chores by urgency (most overdue first).
  List<Chore> sortByUrgency(
      List<Chore> chores, List<ChoreCompletion> completions) {
    final sorted = List<Chore>.from(chores);
    sorted.sort((a, b) {
      final da = daysUntilDue(a, completions);
      final db = daysUntilDue(b, completions);
      return da.compareTo(db);
    });
    return sorted;
  }

  /// Weekly completion summary: day -> count.
  Map<int, int> weeklyCompletionMap(List<ChoreCompletion> completions) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final map = <int, int>{};
    for (int d = 1; d <= 7; d++) {
      map[d] = 0;
    }
    for (final comp in completions) {
      if (!comp.completedAt.isBefore(start) &&
          comp.completedAt.isBefore(start.add(const Duration(days: 7)))) {
        final day = comp.completedAt.weekday;
        map[day] = (map[day] ?? 0) + 1;
      }
    }
    return map;
  }

  /// Grade based on overall adherence across all chores (A-F).
  String overallGrade(
      List<Chore> chores, List<ChoreCompletion> completions, int days) {
    if (chores.isEmpty) return 'N/A';
    final scheduled =
        chores.where((c) => c.frequency != ChoreFrequency.asNeeded).toList();
    if (scheduled.isEmpty) return 'A';
    double totalAdherence = 0;
    for (final chore in scheduled) {
      totalAdherence += adherenceRate(chore, completions, days);
    }
    final avg = totalAdherence / scheduled.length;
    if (avg >= 0.9) return 'A';
    if (avg >= 0.8) return 'B';
    if (avg >= 0.7) return 'C';
    if (avg >= 0.5) return 'D';
    return 'F';
  }

  /// List of chores that are most neglected (lowest adherence).
  List<MapEntry<Chore, double>> mostNeglected(
      List<Chore> chores, List<ChoreCompletion> completions, int days) {
    final scheduled =
        chores.where((c) => c.frequency != ChoreFrequency.asNeeded).toList();
    final entries = scheduled.map((c) {
      return MapEntry(c, adherenceRate(c, completions, days));
    }).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.take(5).toList();
  }

  /// Recommendations based on current state.
  List<String> recommendations(
      List<Chore> chores, List<ChoreCompletion> completions) {
    final tips = <String>[];
    final overdue =
        chores.where((c) => !c.archived && isOverdue(c, completions)).toList();
    if (overdue.length >= 3) {
      tips.add(
          '${overdue.length} chores are overdue — try tackling the quick ones first');
    }
    final weekMap = weeklyCompletionMap(completions);
    final totalWeek = weekMap.values.fold(0, (a, b) => a + b);
    if (totalWeek == 0) {
      tips.add('No chores done this week yet — start with a quick win!');
    }
    final neglected = mostNeglected(chores, completions, 30);
    if (neglected.isNotEmpty && neglected.first.value < 0.3) {
      tips.add(
          '"${neglected.first.key.name}" needs attention — only ${(neglected.first.value * 100).round()}% adherence');
    }
    if (tips.isEmpty) {
      tips.add('Great job keeping up with your chores! 🎉');
    }
    return tips;
  }
}
