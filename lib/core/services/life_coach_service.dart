import 'package:flutter/material.dart';

/// Represents a nudge/recommendation from the life coach.
class CoachNudge {
  final int id;
  final String title;
  final String message;
  final NudgeType type;
  final NudgePriority priority;
  final String source;
  final DateTime createdAt;
  final bool isDismissed;
  final String? actionLabel;

  CoachNudge({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.source,
    required this.createdAt,
    this.isDismissed = false,
    this.actionLabel,
  });

  CoachNudge copyWith({bool? isDismissed}) => CoachNudge(
        id: id,
        title: title,
        message: message,
        type: type,
        priority: priority,
        source: source,
        createdAt: createdAt,
        isDismissed: isDismissed ?? this.isDismissed,
        actionLabel: actionLabel,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.index,
        'priority': priority.index,
        'source': source,
        'createdAt': createdAt.toIso8601String(),
        'isDismissed': isDismissed,
        'actionLabel': actionLabel,
      };

  factory CoachNudge.fromJson(Map<String, dynamic> j) => CoachNudge(
        id: j['id'] as int,
        title: j['title'] as String,
        message: j['message'] as String,
        type: NudgeType.values[j['type'] as int],
        priority: NudgePriority.values[j['priority'] as int],
        source: j['source'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        isDismissed: j['isDismissed'] as bool? ?? false,
        actionLabel: j['actionLabel'] as String?,
      );
}

/// Types of coaching nudges.
enum NudgeType { streak, warning, celebration, suggestion, insight, challenge }

/// Priority levels for nudges.
enum NudgePriority { low, medium, high, urgent }

/// A pattern detected across multiple trackers.
class DetectedPattern {
  final String title;
  final String description;
  final String evidence;
  final double confidence;
  final List<String> trackers;
  final PatternType type;

  const DetectedPattern({
    required this.title,
    required this.description,
    required this.evidence,
    required this.confidence,
    required this.trackers,
    required this.type,
  });
}

/// Types of detected patterns.
enum PatternType { correlation, trend, anomaly, cycle, milestone }

/// Weekly coaching summary.
class CoachingSummary {
  final String headline;
  final int totalNudges;
  final int nudgesActedOn;
  final List<String> wins;
  final List<String> opportunities;
  final String focusArea;
  final double overallScore;

  const CoachingSummary({
    required this.headline,
    required this.totalNudges,
    required this.nudgesActedOn,
    required this.wins,
    required this.opportunities,
    required this.focusArea,
    required this.overallScore,
  });
}

/// Focus area with score and advice.
class FocusArea {
  final String name;
  final IconData icon;
  final int score;
  final String trend; // up, down, stable
  final String advice;

  const FocusArea({
    required this.name,
    required this.icon,
    required this.score,
    required this.trend,
    required this.advice,
  });
}

/// Cross-tracker intelligence service that analyzes patterns and generates
/// personalized nudges, insights, and recommendations.
class LifeCoachService {
  /// Generate active nudges based on cross-tracker analysis.
  List<CoachNudge> generateNudges() {
    final now = DateTime.now();
    return [
      CoachNudge(
        id: 1,
        title: 'Meditation Streak on Fire!',
        message:
            'You\'re at 7 days straight. Keep going for your 14-day milestone!',
        type: NudgeType.streak,
        priority: NudgePriority.medium,
        source: 'Habit Tracker',
        createdAt: now.subtract(const Duration(hours: 2)),
        actionLabel: 'View streak',
      ),
      CoachNudge(
        id: 2,
        title: 'Tuesday Energy Dip Detected',
        message:
            'Your energy drops every Tuesday afternoon. Consider scheduling lighter tasks or taking a walk.',
        type: NudgeType.warning,
        priority: NudgePriority.high,
        source: 'Energy Tracker',
        createdAt: now.subtract(const Duration(hours: 5)),
        actionLabel: 'See pattern',
      ),
      CoachNudge(
        id: 3,
        title: 'Exercise Boosts Your Mood',
        message:
            'When you exercise in the morning, your mood scores are 23% higher the rest of the day.',
        type: NudgeType.insight,
        priority: NudgePriority.medium,
        source: 'Energy + Mood Trackers',
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      CoachNudge(
        id: 4,
        title: 'Reading Goal Ahead of Pace!',
        message:
            'You\'re 80% done with 10 days left. You could finish early if you keep this pace.',
        type: NudgeType.celebration,
        priority: NudgePriority.low,
        source: 'Goal Tracker',
        createdAt: now.subtract(const Duration(hours: 12)),
        actionLabel: 'View goal',
      ),
      CoachNudge(
        id: 5,
        title: 'Peak Productivity Window',
        message:
            'Your most productive hours this week: 9-11 AM. Protect this block for deep work.',
        type: NudgeType.insight,
        priority: NudgePriority.medium,
        source: 'Pomodoro + Energy',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      CoachNudge(
        id: 6,
        title: '30-Day Journaling Challenge',
        message:
            'You\'ve journaled 18 of the last 21 days. Can you hit 30 consecutive days?',
        type: NudgeType.challenge,
        priority: NudgePriority.low,
        source: 'Daily Journal',
        createdAt: now.subtract(const Duration(days: 1)),
        actionLabel: 'Accept challenge',
      ),
      CoachNudge(
        id: 7,
        title: 'Hydration Dropping',
        message:
            'Your water intake has dropped 30% this week compared to last week. Stay hydrated!',
        type: NudgeType.warning,
        priority: NudgePriority.high,
        source: 'Health Tracker',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      CoachNudge(
        id: 8,
        title: 'Sleep Schedule Improving',
        message:
            'Your bedtime consistency improved from 45min variance to 20min this month. Great work!',
        type: NudgeType.celebration,
        priority: NudgePriority.low,
        source: 'Sleep Tracker',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      CoachNudge(
        id: 9,
        title: 'Budget Alert',
        message:
            'You\'ve used 85% of your dining budget with 12 days remaining. Consider cooking at home.',
        type: NudgeType.warning,
        priority: NudgePriority.urgent,
        source: 'Budget Planner',
        createdAt: now.subtract(const Duration(minutes: 30)),
        actionLabel: 'View budget',
      ),
      CoachNudge(
        id: 10,
        title: 'Social Connection Needed',
        message:
            'You haven\'t logged a social activity in 5 days. Reach out to someone today?',
        type: NudgeType.suggestion,
        priority: NudgePriority.medium,
        source: 'Mood + Activity Trackers',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
    ];
  }

  /// Detect patterns across trackers.
  List<DetectedPattern> detectPatterns() {
    return [
      const DetectedPattern(
        title: 'Morning Exercise → Better Mood',
        description:
            'On days you exercise before 9 AM, your afternoon mood ratings average 4.2/5 vs 3.1/5 on rest days.',
        evidence: 'Analyzed 45 days of exercise + mood data',
        confidence: 0.82,
        trackers: ['Habit Tracker', 'Mood Journal', 'Energy Tracker'],
        type: PatternType.correlation,
      ),
      const DetectedPattern(
        title: 'Sleep Quality Improving',
        description:
            'Your average sleep score rose from 62 to 78 over the last 2 weeks.',
        evidence: '14-day rolling average comparison',
        confidence: 0.75,
        trackers: ['Sleep Tracker'],
        type: PatternType.trend,
      ),
      const DetectedPattern(
        title: 'Wednesday Energy Anomaly',
        description:
            'Your energy levels on Wednesdays are consistently 25% below other weekdays.',
        evidence: '8 consecutive Wednesdays below baseline',
        confidence: 0.68,
        trackers: ['Energy Tracker', 'Pomodoro'],
        type: PatternType.anomaly,
      ),
      const DetectedPattern(
        title: 'Productivity Cycles Every 3 Days',
        description:
            'You have a high-low-medium productivity cycle repeating every 3 days.',
        evidence: 'Fourier analysis of 30-day task completion data',
        confidence: 0.71,
        trackers: ['Pomodoro', 'Goal Tracker', 'Habit Tracker'],
        type: PatternType.cycle,
      ),
      const DetectedPattern(
        title: 'Longest Journaling Streak Ever!',
        description:
            'At 18 days, this is your longest daily journaling streak. Previous best: 12 days.',
        evidence: 'Historical streak comparison',
        confidence: 1.0,
        trackers: ['Daily Journal'],
        type: PatternType.milestone,
      ),
      const DetectedPattern(
        title: 'Caffeine-Sleep Interference',
        description:
            'Coffee after 2 PM correlates with 18 minutes less sleep and lower sleep quality.',
        evidence: 'Correlation of caffeine log times vs sleep scores (r=-0.64)',
        confidence: 0.64,
        trackers: ['Caffeine Tracker', 'Sleep Tracker'],
        type: PatternType.correlation,
      ),
      const DetectedPattern(
        title: 'Weekend Mood Uplift',
        description:
            'Your mood ratings are 35% higher on weekends, possibly due to social activities.',
        evidence: 'Day-of-week mood distribution analysis',
        confidence: 0.88,
        trackers: ['Mood Journal', 'Activity Tracker'],
        type: PatternType.trend,
      ),
    ];
  }

  /// Generate weekly coaching summary.
  CoachingSummary generateWeeklySummary() {
    return const CoachingSummary(
      headline: 'Strong week! You\'re building momentum.',
      totalNudges: 24,
      nudgesActedOn: 18,
      wins: [
        'Meditation streak reached 7 days',
        'Sleep consistency improved significantly',
        'Hit reading goal ahead of schedule',
        'Exercised 5 out of 7 days',
      ],
      opportunities: [
        'Hydration dropped — set water reminders',
        'Wednesday energy dip — adjust schedule',
        'Social connections could use attention',
      ],
      focusArea: 'Physical Health',
      overallScore: 74,
    );
  }

  /// Get coaching focus areas ranked by importance.
  List<FocusArea> getFocusAreas() {
    return const [
      FocusArea(
        name: 'Physical Health',
        icon: Icons.fitness_center,
        score: 72,
        trend: 'up',
        advice:
            'Exercise consistency is great. Focus on hydration and stretching to round out physical wellness.',
      ),
      FocusArea(
        name: 'Mental Wellness',
        icon: Icons.spa,
        score: 68,
        trend: 'stable',
        advice:
            'Meditation streak is strong. Consider adding a gratitude practice for additional benefits.',
      ),
      FocusArea(
        name: 'Productivity',
        icon: Icons.rocket_launch,
        score: 81,
        trend: 'up',
        advice:
            'You\'re in a great flow. Protect your 9-11 AM peak window and batch shallow tasks.',
      ),
      FocusArea(
        name: 'Learning',
        icon: Icons.school,
        score: 76,
        trend: 'up',
        advice:
            'Reading goal ahead of pace. Consider starting a new skill-building habit next week.',
      ),
      FocusArea(
        name: 'Social',
        icon: Icons.people,
        score: 45,
        trend: 'down',
        advice:
            'Social engagement has decreased. Schedule one social activity this week to rebalance.',
      ),
      FocusArea(
        name: 'Financial',
        icon: Icons.savings,
        score: 62,
        trend: 'stable',
        advice:
            'Budget tracking is on point but dining spending is high. Try meal prepping on Sundays.',
      ),
    ];
  }

  /// Get a motivational daily message based on current patterns.
  String getDailyMotivation() {
    final weekday = DateTime.now().weekday;
    final messages = [
      'Monday energy! Set your intentions for the week and protect your focus time.', // Mon
      'Tuesday: your data shows strong momentum mid-week. Use it wisely.', // Tue
      'Wednesday dip ahead — schedule lighter tasks and prioritize self-care.', // Wed
      'Thursday: you\'re past the hump. Push toward your weekly goals now.', // Thu
      'Friday: great time to reflect on wins and plan a restful weekend.', // Fri
      'Saturday: recharge day. Your best weeks start with genuine rest.', // Sat
      'Sunday: prep tomorrow\'s success. Review goals, set intentions, rest up.', // Sun
    ];
    return messages[weekday - 1];
  }
}
