import 'dart:math';

/// A single commitment/promise the user tracks.
class Commitment {
  final String id;
  final String title;
  final String source; // which tracker it came from
  final IconSource sourceIcon;
  final DateTime createdDate;
  final DateTime dueDate;
  CommitmentStatus status;
  final CommitmentPriority priority;
  final String? notes;

  Commitment({
    required this.id,
    required this.title,
    required this.source,
    required this.sourceIcon,
    required this.createdDate,
    required this.dueDate,
    required this.status,
    required this.priority,
    this.notes,
  });
}

enum CommitmentStatus { overdue, pending, completed, abandoned }

enum CommitmentPriority { high, medium, low }

/// Icon identifier for sources (avoids importing flutter/material here).
enum IconSource {
  fitness,
  goal,
  journal,
  health,
  finance,
  learning,
  social,
}

/// A proactive nudge message.
class Nudge {
  final String message;
  final String action;
  final NudgeSeverity severity;
  Nudge({required this.message, required this.action, required this.severity});
}

enum NudgeSeverity { info, warning, critical }

/// Weekly trend data point.
class WeekTrend {
  final String label;
  final int score;
  WeekTrend(this.label, this.score);
}

/// Category breakdown.
class CategoryBreakdown {
  final String name;
  final int count;
  final int completed;
  CategoryBreakdown(this.name, this.count, this.completed);
}

/// Service that monitors commitments across trackers.
class AccountabilityService {
  final _rng = Random(42);

  List<Commitment> getSampleCommitments() {
    final now = DateTime.now();
    return [
      Commitment(
        id: '1', title: 'Exercise 4x this week', source: 'Habit Tracker',
        sourceIcon: IconSource.fitness, createdDate: now.subtract(const Duration(days: 10)),
        dueDate: now.subtract(const Duration(days: 2)), status: CommitmentStatus.overdue,
        priority: CommitmentPriority.high, notes: 'Only completed 2 of 4 sessions',
      ),
      Commitment(
        id: '2', title: 'Read 30 pages daily', source: 'Reading List',
        sourceIcon: IconSource.learning, createdDate: now.subtract(const Duration(days: 14)),
        dueDate: now.add(const Duration(days: 1)), status: CommitmentStatus.pending,
        priority: CommitmentPriority.medium,
      ),
      Commitment(
        id: '3', title: 'Save \$500 this month', source: 'Savings Goal',
        sourceIcon: IconSource.finance, createdDate: now.subtract(const Duration(days: 20)),
        dueDate: now.add(const Duration(days: 8)), status: CommitmentStatus.pending,
        priority: CommitmentPriority.high, notes: 'Currently at \$320',
      ),
      Commitment(
        id: '4', title: 'Meditate 10 min daily', source: 'Meditation',
        sourceIcon: IconSource.health, createdDate: now.subtract(const Duration(days: 7)),
        dueDate: now.subtract(const Duration(days: 1)), status: CommitmentStatus.completed,
        priority: CommitmentPriority.medium,
      ),
      Commitment(
        id: '5', title: 'Journal every evening', source: 'Daily Journal',
        sourceIcon: IconSource.journal, createdDate: now.subtract(const Duration(days: 21)),
        dueDate: now.add(const Duration(days: 3)), status: CommitmentStatus.pending,
        priority: CommitmentPriority.low, notes: 'Missed 3 of last 7 days',
      ),
      Commitment(
        id: '6', title: 'Drink 8 glasses of water', source: 'Water Tracker',
        sourceIcon: IconSource.health, createdDate: now.subtract(const Duration(days: 5)),
        dueDate: now, status: CommitmentStatus.pending,
        priority: CommitmentPriority.medium,
      ),
      Commitment(
        id: '7', title: 'Complete Python course', source: 'Learning Tracker',
        sourceIcon: IconSource.learning, createdDate: now.subtract(const Duration(days: 30)),
        dueDate: now.subtract(const Duration(days: 5)), status: CommitmentStatus.overdue,
        priority: CommitmentPriority.high, notes: '60% done, stalled on week 4',
      ),
      Commitment(
        id: '8', title: 'Call mom weekly', source: 'Contact Tracker',
        sourceIcon: IconSource.social, createdDate: now.subtract(const Duration(days: 14)),
        dueDate: now.subtract(const Duration(days: 3)), status: CommitmentStatus.completed,
        priority: CommitmentPriority.medium,
      ),
      Commitment(
        id: '9', title: 'Budget review Friday', source: 'Budget Planner',
        sourceIcon: IconSource.finance, createdDate: now.subtract(const Duration(days: 3)),
        dueDate: now.add(const Duration(days: 2)), status: CommitmentStatus.pending,
        priority: CommitmentPriority.low,
      ),
      Commitment(
        id: '10', title: 'Weight goal: lose 2 lbs', source: 'Weight Tracker',
        sourceIcon: IconSource.health, createdDate: now.subtract(const Duration(days: 28)),
        dueDate: now.subtract(const Duration(days: 7)), status: CommitmentStatus.abandoned,
        priority: CommitmentPriority.medium, notes: 'Gained 1 lb instead',
      ),
      Commitment(
        id: '11', title: 'Practice guitar 20 min', source: 'Music Practice',
        sourceIcon: IconSource.learning, createdDate: now.subtract(const Duration(days: 10)),
        dueDate: now.add(const Duration(days: 4)), status: CommitmentStatus.pending,
        priority: CommitmentPriority.low,
      ),
      Commitment(
        id: '12', title: 'Meal prep Sundays', source: 'Meal Tracker',
        sourceIcon: IconSource.health, createdDate: now.subtract(const Duration(days: 7)),
        dueDate: now.subtract(const Duration(days: 1)), status: CommitmentStatus.completed,
        priority: CommitmentPriority.medium,
      ),
      Commitment(
        id: '13', title: 'Sleep by 11pm nightly', source: 'Sleep Tracker',
        sourceIcon: IconSource.health, createdDate: now.subtract(const Duration(days: 14)),
        dueDate: now.add(const Duration(days: 7)), status: CommitmentStatus.pending,
        priority: CommitmentPriority.high, notes: 'Averaging 11:45pm this week',
      ),
      Commitment(
        id: '14', title: 'No social media before noon', source: 'Screen Time',
        sourceIcon: IconSource.goal, createdDate: now.subtract(const Duration(days: 5)),
        dueDate: now.add(const Duration(days: 9)), status: CommitmentStatus.pending,
        priority: CommitmentPriority.medium,
      ),
      Commitment(
        id: '15', title: 'Write gratitude entry', source: 'Gratitude Journal',
        sourceIcon: IconSource.journal, createdDate: now.subtract(const Duration(days: 3)),
        dueDate: now, status: CommitmentStatus.completed,
        priority: CommitmentPriority.low,
      ),
    ];
  }

  /// Overall accountability score 0-100.
  int getAccountabilityScore(List<Commitment> commitments) {
    if (commitments.isEmpty) return 100;
    final total = commitments.length;
    final completed = commitments.where((c) => c.status == CommitmentStatus.completed).length;
    final overdue = commitments.where((c) => c.status == CommitmentStatus.overdue).length;
    final abandoned = commitments.where((c) => c.status == CommitmentStatus.abandoned).length;

    final completionRate = completed / total;
    final overdueRate = overdue / total;
    final abandonRate = abandoned / total;

    final score = (completionRate * 60 + (1 - overdueRate) * 25 + (1 - abandonRate) * 15) * 100;
    return score.round().clamp(0, 100);
  }

  /// Proactive nudge messages based on patterns.
  List<Nudge> getProactiveNudges(List<Commitment> commitments) {
    final nudges = <Nudge>[];
    final overdue = commitments.where((c) => c.status == CommitmentStatus.overdue).toList();
    final pending = commitments.where((c) => c.status == CommitmentStatus.pending).toList();
    final highPriOverdue = overdue.where((c) => c.priority == CommitmentPriority.high).toList();

    if (highPriOverdue.isNotEmpty) {
      nudges.add(Nudge(
        message: '${highPriOverdue.length} high-priority commitment${highPriOverdue.length > 1 ? 's are' : ' is'} overdue. These need immediate attention.',
        action: 'Review and recommit or reschedule',
        severity: NudgeSeverity.critical,
      ));
    }

    final healthCommits = commitments.where((c) =>
      c.sourceIcon == IconSource.health &&
      (c.status == CommitmentStatus.overdue || c.status == CommitmentStatus.abandoned)
    ).toList();
    if (healthCommits.length >= 2) {
      nudges.add(Nudge(
        message: '${healthCommits.length} health commitments need attention. Your well-being matters!',
        action: 'Prioritize one health goal today',
        severity: NudgeSeverity.warning,
      ));
    }

    final dueSoon = pending.where((c) =>
      c.dueDate.difference(DateTime.now()).inDays <= 1
    ).toList();
    if (dueSoon.isNotEmpty) {
      nudges.add(Nudge(
        message: '${dueSoon.length} commitment${dueSoon.length > 1 ? 's' : ''} due within 24 hours.',
        action: 'Focus on these today',
        severity: NudgeSeverity.warning,
      ));
    }

    final score = getAccountabilityScore(commitments);
    if (score < 50) {
      nudges.add(Nudge(
        message: 'Accountability score is below 50. Consider reducing active commitments to stay focused.',
        action: 'Archive or postpone 2-3 low-priority items',
        severity: NudgeSeverity.critical,
      ));
    } else if (score >= 80) {
      nudges.add(Nudge(
        message: 'Great accountability! You\'re keeping 80%+ of your commitments. Keep it up!',
        action: 'Consider adding a stretch goal',
        severity: NudgeSeverity.info,
      ));
    }

    if (pending.length > 8) {
      nudges.add(Nudge(
        message: 'You have ${pending.length} pending commitments. Overcommitting leads to burnout.',
        action: 'Pick your top 5 and defer the rest',
        severity: NudgeSeverity.warning,
      ));
    }

    return nudges;
  }

  /// Commitments at risk of being missed.
  List<Commitment> predictAtRisk(List<Commitment> commitments) {
    final now = DateTime.now();
    return commitments.where((c) {
      if (c.status != CommitmentStatus.pending) return false;
      final daysLeft = c.dueDate.difference(now).inDays;
      final age = now.difference(c.createdDate).inDays;
      // At risk if: due soon + old (stalled), or high priority + close deadline
      if (daysLeft <= 2) return true;
      if (age > 14 && daysLeft <= 5) return true;
      if (c.priority == CommitmentPriority.high && daysLeft <= 3) return true;
      return false;
    }).toList();
  }

  /// Weekly trend scores for last 8 weeks.
  List<WeekTrend> getWeeklyTrend() {
    // Simulated historical data
    final labels = ['W-7', 'W-6', 'W-5', 'W-4', 'W-3', 'W-2', 'W-1', 'Now'];
    final scores = [72, 68, 75, 71, 78, 65, 73, 69];
    return List.generate(8, (i) => WeekTrend(labels[i], scores[i]));
  }

  /// Breakdown by source category.
  List<CategoryBreakdown> getCategoryBreakdown(List<Commitment> commitments) {
    final map = <String, List<Commitment>>{};
    for (final c in commitments) {
      map.putIfAbsent(c.source, () => []).add(c);
    }
    return map.entries.map((e) {
      final completed = e.value.where((c) => c.status == CommitmentStatus.completed).length;
      return CategoryBreakdown(e.key, e.value.length, completed);
    }).toList()..sort((a, b) => b.count.compareTo(a.count));
  }
}
