import 'dart:convert';
import 'dart:math';
import '../../models/meditation_entry.dart';

/// Configuration for meditation tracking.
class MeditationConfig {
  /// Daily meditation goal in minutes.
  final int dailyGoalMinutes;
  /// Weekly session count goal.
  final int weeklySessionGoal;
  /// Preferred default technique.
  final MeditationType defaultType;

  const MeditationConfig({
    this.dailyGoalMinutes = 15,
    this.weeklySessionGoal = 5,
    this.defaultType = MeditationType.mindfulness,
  });

  Map<String, dynamic> toJson() => {
        'dailyGoalMinutes': dailyGoalMinutes,
        'weeklySessionGoal': weeklySessionGoal,
        'defaultType': defaultType.name,
      };

  factory MeditationConfig.fromJson(Map<String, dynamic> json) {
    return MeditationConfig(
      dailyGoalMinutes: json['dailyGoalMinutes'] as int? ?? 15,
      weeklySessionGoal: json['weeklySessionGoal'] as int? ?? 5,
      defaultType: MeditationType.values.firstWhere(
        (v) => v.name == json['defaultType'],
        orElse: () => MeditationType.mindfulness,
      ),
    );
  }
}

/// Daily meditation summary.
class DailyMeditationSummary {
  final DateTime date;
  final int sessionCount;
  final int totalMinutes;
  final int goalMinutes;
  final double? avgMoodDelta;
  final List<MeditationType> typesUsed;

  const DailyMeditationSummary({
    required this.date,
    required this.sessionCount,
    required this.totalMinutes,
    required this.goalMinutes,
    required this.avgMoodDelta,
    required this.typesUsed,
  });

  double get goalProgress =>
      goalMinutes > 0 ? (totalMinutes / goalMinutes * 100).clamp(0, 200) : 0;
  bool get goalMet => totalMinutes >= goalMinutes;
}

/// Weekly meditation summary.
class WeeklyMeditationSummary {
  final DateTime weekStart;
  final int sessionCount;
  final int totalMinutes;
  final int sessionGoal;
  final double avgDuration;
  final double? avgMoodDelta;
  final Map<MeditationType, int> typeBreakdown;

  const WeeklyMeditationSummary({
    required this.weekStart,
    required this.sessionCount,
    required this.totalMinutes,
    required this.sessionGoal,
    required this.avgDuration,
    required this.avgMoodDelta,
    required this.typeBreakdown,
  });

  double get goalProgress =>
      sessionGoal > 0 ? (sessionCount / sessionGoal * 100).clamp(0, 200) : 0;
  bool get goalMet => sessionCount >= sessionGoal;
}

/// Meditation streak info.
class MeditationStreak {
  final int currentDays;
  final int longestDays;
  final DateTime? lastSessionDate;
  final int totalSessions;
  final int totalMinutes;

  const MeditationStreak({
    required this.currentDays,
    required this.longestDays,
    this.lastSessionDate,
    required this.totalSessions,
    required this.totalMinutes,
  });
}

/// Mood impact analysis per technique type.
class TechniqueMoodImpact {
  final MeditationType type;
  final int sessionCount;
  final double avgMoodBefore;
  final double avgMoodAfter;
  final double avgMoodDelta;

  const TechniqueMoodImpact({
    required this.type,
    required this.sessionCount,
    required this.avgMoodBefore,
    required this.avgMoodAfter,
    required this.avgMoodDelta,
  });
}

/// Comprehensive meditation report.
class MeditationReport {
  final int totalSessions;
  final int totalMinutes;
  final double avgSessionMinutes;
  final double? avgMoodDelta;
  final MeditationStreak streak;
  final Map<MeditationType, int> typeFrequency;
  final List<TechniqueMoodImpact> techniqueMoodImpacts;
  final double completionRate; // % of non-interrupted sessions
  final List<String> insights;

  const MeditationReport({
    required this.totalSessions,
    required this.totalMinutes,
    required this.avgSessionMinutes,
    required this.avgMoodDelta,
    required this.streak,
    required this.typeFrequency,
    required this.techniqueMoodImpacts,
    required this.completionRate,
    required this.insights,
  });

  String toTextSummary() {
    final buf = StringBuffer();
    buf.writeln('=== Meditation Report ===');
    buf.writeln('Total sessions: $totalSessions');
    buf.writeln('Total time: $totalMinutes min');
    buf.writeln('Avg session: ${avgSessionMinutes.toStringAsFixed(1)} min');
    if (avgMoodDelta != null) {
      buf.writeln('Avg mood change: ${avgMoodDelta! >= 0 ? '+' : ''}${avgMoodDelta!.toStringAsFixed(1)}');
    }
    buf.writeln('Completion rate: ${completionRate.toStringAsFixed(0)}%');
    buf.writeln('');
    buf.writeln('--- Streak ---');
    buf.writeln('Current: ${streak.currentDays} days');
    buf.writeln('Longest: ${streak.longestDays} days');
    buf.writeln('');
    if (techniqueMoodImpacts.isNotEmpty) {
      buf.writeln('--- Best Techniques for Mood ---');
      final sorted = List.of(techniqueMoodImpacts)
        ..sort((a, b) => b.avgMoodDelta.compareTo(a.avgMoodDelta));
      for (final t in sorted.take(3)) {
        buf.writeln('${t.type.emoji} ${t.type.label}: '
            '${t.avgMoodDelta >= 0 ? '+' : ''}${t.avgMoodDelta.toStringAsFixed(1)} mood '
            '(${t.sessionCount} sessions)');
      }
      buf.writeln('');
    }
    if (insights.isNotEmpty) {
      buf.writeln('--- Insights ---');
      for (final tip in insights) {
        buf.writeln('- $tip');
      }
    }
    return buf.toString();
  }
}

/// Meditation tracker service with logging, streaks, mood analysis, and insights.
class MeditationTrackerService {
  final List<MeditationEntry> _sessions;
  final MeditationConfig config;

  MeditationTrackerService({
    List<MeditationEntry>? sessions,
    this.config = const MeditationConfig(),
  }) : _sessions = sessions != null ? List.of(sessions) : [];

  List<MeditationEntry> get sessions => List.unmodifiable(_sessions);

  // ── CRUD ──

  void addSession(MeditationEntry session) {
    _sessions.add(session);
    _sessions.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  bool removeSession(String id) {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx == -1) return false;
    _sessions.removeAt(idx);
    return true;
  }

  MeditationEntry? getSession(String id) {
    for (final s in _sessions) {
      if (s.id == id) return s;
    }
    return null;
  }

  void updateSession(MeditationEntry updated) {
    final idx = _sessions.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      _sessions[idx] = updated;
      _sessions.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    }
  }

  // ── Filtering ──

  List<MeditationEntry> getSessionsForDate(DateTime date) {
    return _sessions.where((s) =>
        s.dateTime.year == date.year &&
        s.dateTime.month == date.month &&
        s.dateTime.day == date.day).toList();
  }

  List<MeditationEntry> getSessionsInRange(DateTime start, DateTime end) {
    return _sessions.where((s) =>
        !s.dateTime.isBefore(start) && !s.dateTime.isAfter(end)).toList();
  }

  List<MeditationEntry> getSessionsByType(MeditationType type) {
    return _sessions.where((s) => s.type == type).toList();
  }

  // ── Daily Summary ──

  DailyMeditationSummary getDailySummary(DateTime date) {
    final daySessions = getSessionsForDate(date);
    final totalMin = daySessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

    final moodDeltas = daySessions
        .where((s) => s.moodDelta != null)
        .map((s) => s.moodDelta!)
        .toList();
    final avgMoodDelta = moodDeltas.isNotEmpty
        ? moodDeltas.fold<double>(0, (sum, d) => sum + d) / moodDeltas.length
        : null;

    return DailyMeditationSummary(
      date: date,
      sessionCount: daySessions.length,
      totalMinutes: totalMin,
      goalMinutes: config.dailyGoalMinutes,
      avgMoodDelta: avgMoodDelta,
      typesUsed: daySessions.map((s) => s.type).toSet().toList(),
    );
  }

  // ── Weekly Summary ──

  WeeklyMeditationSummary getWeeklySummary(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekSessions = getSessionsInRange(weekStart, weekEnd);

    final totalMin = weekSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final avgDur = weekSessions.isNotEmpty ? totalMin / weekSessions.length : 0.0;

    final moodDeltas = weekSessions
        .where((s) => s.moodDelta != null)
        .map((s) => s.moodDelta!)
        .toList();
    final avgMoodDelta = moodDeltas.isNotEmpty
        ? moodDeltas.fold<double>(0, (sum, d) => sum + d) / moodDeltas.length
        : null;

    final typeBreakdown = <MeditationType, int>{};
    for (final s in weekSessions) {
      typeBreakdown[s.type] = (typeBreakdown[s.type] ?? 0) + 1;
    }

    return WeeklyMeditationSummary(
      weekStart: weekStart,
      sessionCount: weekSessions.length,
      totalMinutes: totalMin,
      sessionGoal: config.weeklySessionGoal,
      avgDuration: avgDur,
      avgMoodDelta: avgMoodDelta,
      typeBreakdown: typeBreakdown,
    );
  }

  // ── Streaks ──

  MeditationStreak getStreak() {
    if (_sessions.isEmpty) {
      return const MeditationStreak(
        currentDays: 0,
        longestDays: 0,
        totalSessions: 0,
        totalMinutes: 0,
      );
    }

    // Unique days with sessions
    final uniqueDays = <String>{};
    for (final s in _sessions) {
      uniqueDays.add('${s.dateTime.year}-${s.dateTime.month.toString().padLeft(2, '0')}-${s.dateTime.day.toString().padLeft(2, '0')}');
    }

    final sortedDays = uniqueDays.toList()..sort();

    int currentStreak = 1;
    int longestStreak = 1;
    int tempStreak = 1;

    for (int i = 1; i < sortedDays.length; i++) {
      final prev = DateTime.parse(sortedDays[i - 1]);
      final curr = DateTime.parse(sortedDays[i]);
      if (curr.difference(prev).inDays == 1) {
        tempStreak++;
      } else {
        if (tempStreak > longestStreak) longestStreak = tempStreak;
        tempStreak = 1;
      }
    }
    if (tempStreak > longestStreak) longestStreak = tempStreak;

    // Current streak from most recent day backwards
    currentStreak = 1;
    for (int i = sortedDays.length - 1; i > 0; i--) {
      final prev = DateTime.parse(sortedDays[i - 1]);
      final curr = DateTime.parse(sortedDays[i]);
      if (curr.difference(prev).inDays == 1) {
        currentStreak++;
      } else {
        break;
      }
    }

    final totalMin = _sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

    return MeditationStreak(
      currentDays: currentStreak,
      longestDays: longestStreak,
      lastSessionDate: _sessions.last.dateTime,
      totalSessions: _sessions.length,
      totalMinutes: totalMin,
    );
  }

  // ── Technique Mood Analysis ──

  List<TechniqueMoodImpact> analyzeTechniqueMoodImpact() {
    final byType = <MeditationType, List<MeditationEntry>>{};
    for (final s in _sessions) {
      if (s.preMood != null && s.postMood != null) {
        byType.putIfAbsent(s.type, () => []).add(s);
      }
    }

    return byType.entries.map((entry) {
      final sessions = entry.value;
      final avgBefore = sessions.map((s) => s.preMood!).fold<double>(0, (sum, m) => sum + m) / sessions.length;
      final avgAfter = sessions.map((s) => s.postMood!).fold<double>(0, (sum, m) => sum + m) / sessions.length;
      return TechniqueMoodImpact(
        type: entry.key,
        sessionCount: sessions.length,
        avgMoodBefore: avgBefore,
        avgMoodAfter: avgAfter,
        avgMoodDelta: avgAfter - avgBefore,
      );
    }).toList()
      ..sort((a, b) => b.avgMoodDelta.compareTo(a.avgMoodDelta));
  }

  // ── Type Frequency ──

  Map<MeditationType, int> getTypeFrequency() {
    final freq = <MeditationType, int>{};
    for (final s in _sessions) {
      freq[s.type] = (freq[s.type] ?? 0) + 1;
    }
    return freq;
  }

  // ── Insights ──

  List<String> generateInsights() {
    final insights = <String>[];

    if (_sessions.isEmpty) {
      insights.add('Start meditating to unlock personalized insights!');
      return insights;
    }

    final streak = getStreak();
    final impacts = analyzeTechniqueMoodImpact();
    final typeFreq = getTypeFrequency();

    // Streak-based
    if (streak.currentDays >= 7) {
      insights.add('Amazing ${streak.currentDays}-day streak! Consistency builds lasting benefits.');
    } else if (streak.currentDays == 0 && _sessions.isNotEmpty) {
      insights.add('No sessions today yet. Even 5 minutes can reset your focus.');
    }

    // Best technique for mood
    if (impacts.isNotEmpty) {
      final best = impacts.first;
      if (best.avgMoodDelta > 0) {
        insights.add('${best.type.label} meditation improves your mood the most '
            '(+${best.avgMoodDelta.toStringAsFixed(1)} avg).');
      }
    }

    // Variety
    if (typeFreq.length == 1) {
      insights.add('Try exploring different meditation techniques for varied benefits.');
    } else if (typeFreq.length >= 4) {
      insights.add('Great variety! You\'ve explored ${typeFreq.length} different techniques.');
    }

    // Duration trend
    if (_sessions.length >= 5) {
      final recent5 = _sessions.sublist(_sessions.length - 5);
      final avgRecent = recent5.fold<int>(0, (sum, s) => sum + s.durationMinutes) / 5;
      final early5 = _sessions.take(min(5, _sessions.length)).toList();
      final avgEarly = early5.fold<int>(0, (sum, s) => sum + s.durationMinutes) / early5.length;
      if (avgRecent > avgEarly * 1.3) {
        insights.add('Your session duration is growing — great progress!');
      }
    }

    // Completion rate
    final interrupted = _sessions.where((s) => s.interrupted).length;
    final completionRate = (_sessions.length - interrupted) / _sessions.length * 100;
    if (completionRate < 70) {
      insights.add('${completionRate.toStringAsFixed(0)}% completion rate. '
          'Try shorter sessions you can finish comfortably.');
    }

    return insights;
  }

  // ── Full Report ──

  MeditationReport generateReport() {
    final totalMin = _sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final moodDeltas = _sessions
        .where((s) => s.moodDelta != null)
        .map((s) => s.moodDelta!)
        .toList();
    final avgMoodDelta = moodDeltas.isNotEmpty
        ? moodDeltas.fold<double>(0, (sum, d) => sum + d) / moodDeltas.length
        : null;
    final interrupted = _sessions.where((s) => s.interrupted).length;
    final completionRate = _sessions.isNotEmpty
        ? (_sessions.length - interrupted) / _sessions.length * 100
        : 100.0;

    return MeditationReport(
      totalSessions: _sessions.length,
      totalMinutes: totalMin,
      avgSessionMinutes: _sessions.isNotEmpty ? totalMin / _sessions.length : 0,
      avgMoodDelta: avgMoodDelta,
      streak: getStreak(),
      typeFrequency: getTypeFrequency(),
      techniqueMoodImpacts: analyzeTechniqueMoodImpact(),
      completionRate: completionRate,
      insights: generateInsights(),
    );
  }

  // ── Serialization ──

  String toJson() {
    return jsonEncode({
      'config': config.toJson(),
      'sessions': _sessions.map((s) => s.toJson()).toList(),
    });
  }

  factory MeditationTrackerService.fromJson(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    return MeditationTrackerService(
      config: data['config'] != null
          ? MeditationConfig.fromJson(data['config'] as Map<String, dynamic>)
          : const MeditationConfig(),
      sessions: (data['sessions'] as List<dynamic>?)
              ?.map((s) => MeditationEntry.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
