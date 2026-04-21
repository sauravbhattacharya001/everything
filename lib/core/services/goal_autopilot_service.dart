/// Goal Autopilot Service — autonomous goal monitoring with
/// completion prediction, stall detection, velocity tracking,
/// and proactive recommendations.

import '../../models/goal.dart';

/// Risk level for a goal.
enum GoalRisk {
  onTrack,
  slipping,
  stalled,
  critical;

  String get label {
    switch (this) {
      case GoalRisk.onTrack:
        return 'On Track';
      case GoalRisk.slipping:
        return 'Slipping';
      case GoalRisk.stalled:
        return 'Stalled';
      case GoalRisk.critical:
        return 'Critical';
    }
  }

  String get emoji {
    switch (this) {
      case GoalRisk.onTrack:
        return '✅';
      case GoalRisk.slipping:
        return '⚠️';
      case GoalRisk.stalled:
        return '🛑';
      case GoalRisk.critical:
        return '🚨';
    }
  }
}

/// Analysis result for a single goal.
class GoalAnalysis {
  final Goal goal;
  final GoalRisk risk;
  final double velocity; // progress per day
  final DateTime? predictedCompletion;
  final int? daysAhead; // positive = ahead of schedule, negative = behind
  final List<String> recommendations;
  final double healthScore; // 0-100

  const GoalAnalysis({
    required this.goal,
    required this.risk,
    required this.velocity,
    this.predictedCompletion,
    this.daysAhead,
    required this.recommendations,
    required this.healthScore,
  });
}

/// Fleet-level summary across all goals.
class GoalFleetSummary {
  final int totalActive;
  final int onTrack;
  final int slipping;
  final int stalled;
  final int critical;
  final double avgHealth;
  final double avgVelocity;
  final List<String> topActions;

  const GoalFleetSummary({
    required this.totalActive,
    required this.onTrack,
    required this.slipping,
    required this.stalled,
    required this.critical,
    required this.avgHealth,
    required this.avgVelocity,
    required this.topActions,
  });
}

class GoalAutopilotService {
  /// Analyze a single goal's health and trajectory.
  GoalAnalysis analyzeGoal(Goal goal) {
    final now = DateTime.now();
    final daysSinceCreation =
        now.difference(goal.createdAt).inDays.clamp(1, 99999);
    final progress = goal.effectiveProgress;
    final velocity = progress / daysSinceCreation; // progress/day (0-1 scale)

    // Predict completion date
    DateTime? predictedCompletion;
    if (velocity > 0.001 && progress < 1.0) {
      final daysToGo = ((1.0 - progress) / velocity).ceil();
      predictedCompletion = now.add(Duration(days: daysToGo));
    }

    // Calculate days ahead/behind schedule
    int? daysAhead;
    if (goal.deadline != null && predictedCompletion != null) {
      daysAhead = goal.deadline!.difference(predictedCompletion).inDays;
    }

    // Determine risk level
    GoalRisk risk;
    if (goal.isCompleted) {
      risk = GoalRisk.onTrack;
    } else if (goal.isOverdue) {
      risk = GoalRisk.critical;
    } else if (velocity < 0.002 && daysSinceCreation > 7) {
      risk = GoalRisk.stalled;
    } else if (daysAhead != null && daysAhead < -14) {
      risk = GoalRisk.critical;
    } else if (daysAhead != null && daysAhead < 0) {
      risk = GoalRisk.slipping;
    } else if (velocity < 0.005 && daysSinceCreation > 3) {
      risk = GoalRisk.slipping;
    } else {
      risk = GoalRisk.onTrack;
    }

    // Health score (0-100)
    double health = 50.0;
    // Progress contribution (0-30)
    health += progress * 30;
    // Velocity contribution (0-20)
    health += (velocity * 100).clamp(0, 20);
    // Deadline proximity (0-20 bonus if ahead, penalty if behind)
    if (daysAhead != null) {
      health += (daysAhead / 7.0).clamp(-20, 20);
    } else if (goal.deadline == null) {
      health += 5; // no deadline = slight bonus (less stress)
    }
    // Milestone completion bonus
    if (goal.milestones.isNotEmpty) {
      final msDone =
          goal.milestones.where((m) => m.isCompleted).length;
      health += (msDone / goal.milestones.length) * 10;
    }
    health = health.clamp(0, 100);

    // Generate recommendations
    final recs = <String>[];
    if (risk == GoalRisk.stalled) {
      recs.add('Break this goal into smaller milestones to build momentum');
      recs.add('Consider if this goal still aligns with your priorities');
    }
    if (risk == GoalRisk.critical && goal.isOverdue) {
      recs.add('This goal is overdue — extend the deadline or archive it');
    }
    if (risk == GoalRisk.critical && !goal.isOverdue) {
      recs.add('At current pace, you\'ll miss the deadline by ${daysAhead?.abs() ?? "?"} days');
      recs.add('Dedicate focused time this week to catch up');
    }
    if (risk == GoalRisk.slipping) {
      recs.add('Increase effort slightly — small daily progress compounds');
    }
    if (goal.milestones.isEmpty && !goal.isCompleted) {
      recs.add('Add milestones to track incremental progress');
    }
    if (goal.deadline == null && !goal.isCompleted) {
      recs.add('Set a target deadline to create healthy urgency');
    }
    if (progress > 0.7 && !goal.isCompleted) {
      recs.add('You\'re 70%+ done — push to finish!');
    }
    if (risk == GoalRisk.onTrack && progress > 0) {
      recs.add('Great pace! Keep it up.');
    }

    return GoalAnalysis(
      goal: goal,
      risk: risk,
      velocity: velocity,
      predictedCompletion: predictedCompletion,
      daysAhead: daysAhead,
      recommendations: recs,
      healthScore: health,
    );
  }

  /// Analyze all active goals and produce a fleet summary.
  GoalFleetSummary analyzeFleet(List<Goal> goals) {
    final active =
        goals.where((g) => !g.isArchived && !g.isCompleted).toList();
    if (active.isEmpty) {
      return const GoalFleetSummary(
        totalActive: 0,
        onTrack: 0,
        slipping: 0,
        stalled: 0,
        critical: 0,
        avgHealth: 0,
        avgVelocity: 0,
        topActions: ['Add some goals to get started!'],
      );
    }

    final analyses = active.map(analyzeGoal).toList();
    final onTrack =
        analyses.where((a) => a.risk == GoalRisk.onTrack).length;
    final slipping =
        analyses.where((a) => a.risk == GoalRisk.slipping).length;
    final stalled =
        analyses.where((a) => a.risk == GoalRisk.stalled).length;
    final critical =
        analyses.where((a) => a.risk == GoalRisk.critical).length;
    final avgHealth =
        analyses.fold(0.0, (s, a) => s + a.healthScore) / analyses.length;
    final avgVelocity =
        analyses.fold(0.0, (s, a) => s + a.velocity) / analyses.length;

    // Top actions: pick most urgent recommendations
    final topActions = <String>[];
    // Critical goals first
    for (final a in analyses.where((a) => a.risk == GoalRisk.critical)) {
      if (topActions.length < 3 && a.recommendations.isNotEmpty) {
        topActions.add('${a.goal.category.emoji} ${a.goal.title}: ${a.recommendations.first}');
      }
    }
    // Then stalled
    for (final a in analyses.where((a) => a.risk == GoalRisk.stalled)) {
      if (topActions.length < 5 && a.recommendations.isNotEmpty) {
        topActions.add('${a.goal.category.emoji} ${a.goal.title}: ${a.recommendations.first}');
      }
    }
    if (topActions.isEmpty) {
      topActions.add('All goals are on track! 🎉');
    }

    return GoalFleetSummary(
      totalActive: active.length,
      onTrack: onTrack,
      slipping: slipping,
      stalled: stalled,
      critical: critical,
      avgHealth: avgHealth,
      avgVelocity: avgVelocity,
      topActions: topActions,
    );
  }

  /// Generate sample goals for demo/preview.
  List<Goal> getSampleGoals() {
    final now = DateTime.now();
    return [
      Goal(
        id: 'demo-1',
        title: 'Learn Spanish',
        description: 'Complete B1 level',
        category: GoalCategory.education,
        createdAt: now.subtract(const Duration(days: 45)),
        deadline: now.add(const Duration(days: 60)),
        progress: 40,
        milestones: [
          Milestone(id: 'm1', title: 'A1 basics', isCompleted: true, completedAt: now.subtract(const Duration(days: 30))),
          Milestone(id: 'm2', title: 'A2 grammar', isCompleted: true, completedAt: now.subtract(const Duration(days: 15))),
          Milestone(id: 'm3', title: 'B1 conversation'),
          Milestone(id: 'm4', title: 'B1 exam prep'),
        ],
      ),
      Goal(
        id: 'demo-2',
        title: 'Run a half marathon',
        description: 'Complete 21km race',
        category: GoalCategory.fitness,
        createdAt: now.subtract(const Duration(days: 90)),
        deadline: now.add(const Duration(days: 30)),
        progress: 25,
      ),
      Goal(
        id: 'demo-3',
        title: 'Save \$5000 emergency fund',
        category: GoalCategory.finance,
        createdAt: now.subtract(const Duration(days: 60)),
        deadline: now.add(const Duration(days: 120)),
        progress: 65,
      ),
      Goal(
        id: 'demo-4',
        title: 'Read 12 books this year',
        category: GoalCategory.personal,
        createdAt: now.subtract(const Duration(days: 120)),
        progress: 8,
        milestones: List.generate(
          12,
          (i) => Milestone(
            id: 'book-${i + 1}',
            title: 'Book ${i + 1}',
            isCompleted: i < 3,
            completedAt: i < 3 ? now.subtract(Duration(days: (3 - i) * 30)) : null,
          ),
        ),
      ),
      Goal(
        id: 'demo-5',
        title: 'Build a side project',
        category: GoalCategory.career,
        createdAt: now.subtract(const Duration(days: 30)),
        progress: 5,
      ),
    ];
  }
}
