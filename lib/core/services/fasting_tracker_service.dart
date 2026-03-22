import '../../models/fasting_entry.dart';

/// Weekly fasting summary.
class FastingWeeklySummary {
  final int totalFasts;
  final int completedFasts;
  final double avgDurationHours;
  final double totalFastingHours;
  final int longestStreakDays;
  final FastingProtocol? mostUsedProtocol;

  const FastingWeeklySummary({
    required this.totalFasts,
    required this.completedFasts,
    required this.avgDurationHours,
    required this.totalFastingHours,
    required this.longestStreakDays,
    this.mostUsedProtocol,
  });

  double get completionRate =>
      totalFasts > 0 ? completedFasts / totalFasts * 100 : 0;
}

/// Service for fasting tracker analytics and logic.
class FastingTrackerService {
  const FastingTrackerService();

  /// Get the currently active fast, if any.
  FastingEntry? getActiveFast(List<FastingEntry> entries) {
    try {
      return entries.firstWhere((e) => e.status == FastingStatus.active);
    } catch (_) {
      return null;
    }
  }

  /// Get entries for a specific date.
  List<FastingEntry> getEntriesForDate(
      List<FastingEntry> entries, DateTime date) {
    return entries.where((e) {
      return e.startTime.year == date.year &&
          e.startTime.month == date.month &&
          e.startTime.day == date.day;
    }).toList();
  }

  /// Get completed entries for the last N days.
  List<FastingEntry> getRecentCompleted(
      List<FastingEntry> entries, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return entries
        .where((e) =>
            e.status == FastingStatus.completed &&
            e.startTime.isAfter(cutoff))
        .toList();
  }

  /// Calculate weekly summary.
  FastingWeeklySummary getWeeklySummary(List<FastingEntry> entries) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recent = entries.where((e) => e.startTime.isAfter(weekAgo)).toList();
    final completed =
        recent.where((e) => e.status == FastingStatus.completed).toList();

    double totalHours = 0;
    for (final e in completed) {
      totalHours += e.durationHours;
    }

    // Most used protocol
    final protocolCounts = <FastingProtocol, int>{};
    for (final e in recent) {
      protocolCounts[e.protocol] = (protocolCounts[e.protocol] ?? 0) + 1;
    }
    FastingProtocol? topProtocol;
    int topCount = 0;
    protocolCounts.forEach((p, c) {
      if (c > topCount) {
        topCount = c;
        topProtocol = p;
      }
    });

    // Streak calculation
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final dayCompleted = completed.any((e) =>
          e.startTime.year == day.year &&
          e.startTime.month == day.month &&
          e.startTime.day == day.day);
      if (dayCompleted) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return FastingWeeklySummary(
      totalFasts: recent.length,
      completedFasts: completed.length,
      avgDurationHours:
          completed.isNotEmpty ? totalHours / completed.length : 0,
      totalFastingHours: totalHours,
      longestStreakDays: streak,
      mostUsedProtocol: topProtocol,
    );
  }

  /// Get fasting zones (metabolic stages) for display.
  static List<FastingZone> get fastingZones => const [
        FastingZone(
          name: 'Fed State',
          emoji: '🍔',
          startHour: 0,
          endHour: 4,
          description: 'Body digesting and absorbing nutrients',
          color: 0xFF4CAF50,
        ),
        FastingZone(
          name: 'Early Fasting',
          emoji: '⏳',
          startHour: 4,
          endHour: 12,
          description: 'Insulin drops, fat burning begins',
          color: 0xFF2196F3,
        ),
        FastingZone(
          name: 'Fat Burning',
          emoji: '🔥',
          startHour: 12,
          endHour: 18,
          description: 'Ketosis starts, increased fat oxidation',
          color: 0xFFFF9800,
        ),
        FastingZone(
          name: 'Deep Ketosis',
          emoji: '⚡',
          startHour: 18,
          endHour: 24,
          description: 'Autophagy begins, cellular cleanup',
          color: 0xFFF44336,
        ),
        FastingZone(
          name: 'Autophagy',
          emoji: '🧬',
          startHour: 24,
          endHour: 48,
          description: 'Peak cellular regeneration',
          color: 0xFF9C27B0,
        ),
      ];

  /// Get the current fasting zone for a given duration.
  static FastingZone getCurrentZone(double hours) {
    for (final zone in fastingZones.reversed) {
      if (hours >= zone.startHour) return zone;
    }
    return fastingZones.first;
  }
}

/// Represents a metabolic fasting zone/stage.
class FastingZone {
  final String name;
  final String emoji;
  final int startHour;
  final int endHour;
  final String description;
  final int color;

  const FastingZone({
    required this.name,
    required this.emoji,
    required this.startHour,
    required this.endHour,
    required this.description,
    required this.color,
  });
}
