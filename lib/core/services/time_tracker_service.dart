import '../../models/time_entry.dart';

/// Service for time tracking analytics and data operations.
class TimeTrackerService {
  const TimeTrackerService();

  DailySummary getDailySummary(List<TimeEntry> entries, DateTime date) {
    final dayEntries = entries.where((e) =>
      e.startTime.year == date.year &&
      e.startTime.month == date.month &&
      e.startTime.day == date.day &&
      !e.isRunning
    ).toList();

    final breakdown = <TimeCategory, Duration>{};
    var totalTracked = Duration.zero;
    var longestSession = Duration.zero;

    for (final entry in dayEntries) {
      final dur = entry.duration;
      totalTracked += dur;
      breakdown[entry.category] = (breakdown[entry.category] ?? Duration.zero) + dur;
      if (dur > longestSession) longestSession = dur;
    }

    String? topCat;
    if (breakdown.isNotEmpty) {
      final sorted = breakdown.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCat = sorted.first.key.label;
    }

    return DailySummary(
      date: date,
      totalTracked: totalTracked,
      categoryBreakdown: breakdown,
      entryCount: dayEntries.length,
      topCategory: topCat,
      longestSession: longestSession,
    );
  }

  List<TimeEntry> getEntriesForDate(List<TimeEntry> entries, DateTime date) {
    return entries.where((e) =>
      e.startTime.year == date.year &&
      e.startTime.month == date.month &&
      e.startTime.day == date.day
    ).toList()..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  int productivityScore(List<TimeEntry> entries, DateTime date) {
    final summary = getDailySummary(entries, date);
    if (summary.entryCount == 0) return 0;

    final hours = summary.totalTracked.inMinutes / 60.0;
    final hourScore = (hours / 8.0 * 40).clamp(0, 40).toInt();
    final varietyScore = (summary.categoryBreakdown.length / 5.0 * 30).clamp(0, 30).toInt();
    final sessionScore = (summary.entryCount / 6.0 * 30).clamp(0, 30).toInt();

    return hourScore + varietyScore + sessionScore;
  }

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  static const categoryColors = {
    TimeCategory.work: 0xFF4285F4,
    TimeCategory.study: 0xFF9C27B0,
    TimeCategory.exercise: 0xFF4CAF50,
    TimeCategory.creative: 0xFFFF9800,
    TimeCategory.social: 0xFFE91E63,
    TimeCategory.chores: 0xFF795548,
    TimeCategory.selfCare: 0xFF00BCD4,
    TimeCategory.entertainment: 0xFFFF5722,
    TimeCategory.commute: 0xFF607D8B,
    TimeCategory.other: 0xFF9E9E9E,
  };

  List<WeeklyInsight> getWeeklyInsights(List<TimeEntry> entries) {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    Duration thisWeekTotal = Duration.zero;
    Duration lastWeekTotal = Duration.zero;
    int thisWeekSessions = 0;
    int lastWeekSessions = 0;

    for (final e in entries.where((e) => !e.isRunning)) {
      if (e.startTime.isAfter(thisWeekStart)) {
        thisWeekTotal += e.duration;
        thisWeekSessions++;
      } else if (e.startTime.isAfter(lastWeekStart)) {
        lastWeekTotal += e.duration;
        lastWeekSessions++;
      }
    }

    final totalTrend = thisWeekTotal > lastWeekTotal ? 'up' :
                       thisWeekTotal < lastWeekTotal ? 'down' : 'stable';
    final sessionTrend = thisWeekSessions > lastWeekSessions ? 'up' :
                         thisWeekSessions < lastWeekSessions ? 'down' : 'stable';

    return [
      WeeklyInsight(label: 'This Week', value: formatDuration(thisWeekTotal), trend: totalTrend, icon: IconType.time),
      WeeklyInsight(label: 'Sessions', value: '$thisWeekSessions', trend: sessionTrend, icon: IconType.chart),
      WeeklyInsight(label: 'Avg/Day', value: formatDuration(Duration(minutes: thisWeekTotal.inMinutes ~/ (now.weekday > 0 ? now.weekday : 1))), icon: IconType.target),
    ];
  }
}
