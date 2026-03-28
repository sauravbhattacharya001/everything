/// Service for tracking sobriety streaks with milestones and multiple trackers.
class SobrietyCounterService {
  SobrietyCounterService._();

  /// Standard milestones (in days) with labels.
  static const Map<int, String> milestones = {
    1: '1 Day',
    7: '1 Week',
    14: '2 Weeks',
    30: '1 Month',
    60: '2 Months',
    90: '3 Months',
    180: '6 Months',
    365: '1 Year',
    500: '500 Days',
    730: '2 Years',
    1000: '1000 Days',
    1095: '3 Years',
    1825: '5 Years',
    3650: '10 Years',
  };

  /// Calculate elapsed time from a start date.
  static SobrietyStats calculate(DateTime startDate) {
    final now = DateTime.now();
    final diff = now.difference(startDate);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    // Next milestone
    String? nextMilestone;
    int? daysToNext;
    for (final entry in milestones.entries) {
      if (entry.key > days) {
        nextMilestone = entry.value;
        daysToNext = entry.key - days;
        break;
      }
    }

    // Achieved milestones
    final achieved = <String>[];
    for (final entry in milestones.entries) {
      if (entry.key <= days) {
        achieved.add(entry.value);
      }
    }

    return SobrietyStats(
      startDate: startDate,
      totalDays: days,
      hours: hours,
      minutes: minutes,
      achievedMilestones: achieved,
      nextMilestone: nextMilestone,
      daysToNextMilestone: daysToNext,
    );
  }

  /// Format days into a human-readable duration.
  static String formatDuration(int totalDays) {
    final years = totalDays ~/ 365;
    final months = (totalDays % 365) ~/ 30;
    final days = totalDays % 30;

    final parts = <String>[];
    if (years > 0) parts.add('$years year${years > 1 ? 's' : ''}');
    if (months > 0) parts.add('$months month${months > 1 ? 's' : ''}');
    if (days > 0 || parts.isEmpty) {
      parts.add('$days day${days != 1 ? 's' : ''}');
    }
    return parts.join(', ');
  }

  /// Motivational quotes for sobriety.
  static const List<String> quotes = [
    'Every day is a new beginning.',
    'One day at a time.',
    'You are stronger than you think.',
    'Progress, not perfection.',
    'The best time to start was yesterday. The next best time is now.',
    'Fall seven times, stand up eight.',
    'Recovery is not a race. You don\'t have to feel guilty if it takes you longer than you thought.',
    'It does not matter how slowly you go as long as you do not stop.',
    'Believe you can and you\'re halfway there.',
    'Strength does not come from winning. Your struggles develop your strengths.',
  ];

  /// Get a quote based on the day (rotates through the list).
  static String quoteOfTheDay() {
    final dayOfYear = DateTime.now().difference(
      DateTime(DateTime.now().year),
    ).inDays;
    return quotes[dayOfYear % quotes.length];
  }

  /// Preset categories users commonly track.
  static const List<String> presetCategories = [
    'Alcohol',
    'Smoking',
    'Caffeine',
    'Sugar',
    'Social Media',
    'Gambling',
    'Junk Food',
    'Vaping',
    'Other',
  ];
}

class SobrietyStats {
  final DateTime startDate;
  final int totalDays;
  final int hours;
  final int minutes;
  final List<String> achievedMilestones;
  final String? nextMilestone;
  final int? daysToNextMilestone;

  const SobrietyStats({
    required this.startDate,
    required this.totalDays,
    required this.hours,
    required this.minutes,
    required this.achievedMilestones,
    this.nextMilestone,
    this.daysToNextMilestone,
  });
}

class SobrietyTracker {
  final String id;
  final String label;
  final String category;
  final DateTime startDate;
  final String? note;

  const SobrietyTracker({
    required this.id,
    required this.label,
    required this.category,
    required this.startDate,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'category': category,
    'startDate': startDate.toIso8601String(),
    'note': note,
  };

  factory SobrietyTracker.fromJson(Map<String, dynamic> json) =>
      SobrietyTracker(
        id: json['id'] as String,
        label: json['label'] as String,
        category: json['category'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        note: json['note'] as String?,
      );
}
