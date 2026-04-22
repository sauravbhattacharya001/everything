import 'dart:math';
import '../../models/event_model.dart';
import '../../models/habit.dart';
import '../../models/goal.dart';
import '../../models/sleep_entry.dart';
import '../../models/mood_entry.dart';
import '../utils/date_utils.dart';

/// Configurable weights for each productivity dimension.
class ProductivityWeights {
  final double events;
  final double habits;
  final double goals;
  final double sleep;
  final double mood;
  final double focus;

  const ProductivityWeights({
    this.events = 0.25,
    this.habits = 0.20,
    this.goals = 0.20,
    this.sleep = 0.15,
    this.mood = 0.10,
    this.focus = 0.10,
  });

  /// Sum of all weights; must equal 1.0 for correct scoring.
  double get total => events + habits + goals + sleep + mood + focus;

  /// Validate that weights are non-negative and sum to 1.0.
  bool get isValid =>
      events >= 0 &&
      habits >= 0 &&
      goals >= 0 &&
      sleep >= 0 &&
      mood >= 0 &&
      focus >= 0 &&
      (total - 1.0).abs() < 0.001;

  Map<String, double> toMap() => {
        'events': events,
        'habits': habits,
        'goals': goals,
        'sleep': sleep,
        'mood': mood,
        'focus': focus,
      };

  factory ProductivityWeights.fromMap(Map<String, dynamic> map) {
    return ProductivityWeights(
      events: (map['events'] as num?)?.toDouble() ?? 0.25,
      habits: (map['habits'] as num?)?.toDouble() ?? 0.20,
      goals: (map['goals'] as num?)?.toDouble() ?? 0.20,
      sleep: (map['sleep'] as num?)?.toDouble() ?? 0.15,
      mood: (map['mood'] as num?)?.toDouble() ?? 0.10,
      focus: (map['focus'] as num?)?.toDouble() ?? 0.10,
    );
  }

  /// Preset: balanced across all dimensions.
  static const balanced = ProductivityWeights();

  /// Preset: emphasize task completion.
  static const taskFocused = ProductivityWeights(
    events: 0.35,
    habits: 0.25,
    goals: 0.20,
    sleep: 0.10,
    mood: 0.05,
    focus: 0.05,
  );

  /// Preset: emphasize wellness (sleep + mood).
  static const wellnessFocused = ProductivityWeights(
    events: 0.15,
    habits: 0.15,
    goals: 0.10,
    sleep: 0.30,
    mood: 0.20,
    focus: 0.10,
  );
}

/// Per-dimension breakdown of a productivity score.
class DimensionScore {
  final String name;
  final double score; // 0-100
  final double weight;
  final double contribution; // score * weight
  final String insight;

  const DimensionScore({
    required this.name,
    required this.score,
    required this.weight,
    required this.contribution,
    required this.insight,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'score': score,
        'weight': weight,
        'contribution': contribution,
        'insight': insight,
      };
}

/// Grade label for a productivity score.
enum ProductivityGrade {
  excellent,
  great,
  good,
  fair,
  needsWork;

  String get label {
    switch (this) {
      case ProductivityGrade.excellent:
        return 'Excellent';
      case ProductivityGrade.great:
        return 'Great';
      case ProductivityGrade.good:
        return 'Good';
      case ProductivityGrade.fair:
        return 'Fair';
      case ProductivityGrade.needsWork:
        return 'Needs Work';
    }
  }

  String get emoji {
    switch (this) {
      case ProductivityGrade.excellent:
        return '🏆';
      case ProductivityGrade.great:
        return '🌟';
      case ProductivityGrade.good:
        return '👍';
      case ProductivityGrade.fair:
        return '📊';
      case ProductivityGrade.needsWork:
        return '💪';
    }
  }
}

/// A single day's productivity score with breakdown.
class DailyProductivityScore {
  final DateTime date;
  final double overallScore; // 0-100
  final ProductivityGrade grade;
  final List<DimensionScore> dimensions;
  final List<String> strengths;
  final List<String> improvements;

  const DailyProductivityScore({
    required this.date,
    required this.overallScore,
    required this.grade,
    required this.dimensions,
    required this.strengths,
    required this.improvements,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'overallScore': overallScore,
        'grade': grade.label,
        'dimensions': dimensions.map((d) => d.toMap()).toList(),
        'strengths': strengths,
        'improvements': improvements,
      };
}

/// Trend direction for multi-day analysis.
enum TrendDirection { rising, stable, declining }

/// Multi-day productivity trend analysis.
class ProductivityTrend {
  final List<DailyProductivityScore> dailyScores;
  final double averageScore;
  final double bestScore;
  final double worstScore;
  final DateTime? bestDay;
  final DateTime? worstDay;
  final TrendDirection direction;
  final double trendSlope;
  final Map<String, double> dimensionAverages;
  final String? topStrength;
  final String? topWeakness;
  final int streak; // consecutive days >= 60

  const ProductivityTrend({
    required this.dailyScores,
    required this.averageScore,
    required this.bestScore,
    required this.worstScore,
    this.bestDay,
    this.worstDay,
    required this.direction,
    required this.trendSlope,
    required this.dimensionAverages,
    this.topStrength,
    this.topWeakness,
    required this.streak,
  });

  Map<String, dynamic> toMap() => {
        'period': '${dailyScores.length} days',
        'averageScore': averageScore,
        'bestScore': bestScore,
        'worstScore': worstScore,
        'bestDay': bestDay?.toIso8601String(),
        'worstDay': worstDay?.toIso8601String(),
        'direction': direction.name,
        'trendSlope': trendSlope,
        'dimensionAverages': dimensionAverages,
        'topStrength': topStrength,
        'topWeakness': topWeakness,
        'streak': streak,
      };
}

/// Computes daily composite productivity scores from events, habits,
/// goals, sleep, mood, and focus (Pomodoro) data.
///
/// Each dimension is scored 0-100 independently, then combined using
/// configurable weights into an overall daily score. Provides trend
/// analysis, insights, and grade labels.
class ProductivityScoreService {
  final ProductivityWeights weights;

  /// Target number of events per day (for normalization).
  final int targetEventsPerDay;

  /// Target focus minutes per day (Pomodoro).
  final int targetFocusMinutes;

  ProductivityScoreService({
    this.weights = const ProductivityWeights(),
    this.targetEventsPerDay = 5,
    this.targetFocusMinutes = 120,
  }) {
    if (!weights.isValid) {
      throw ArgumentError(
        'Weights must be non-negative and sum to 1.0, got ${weights.total}',
      );
    }
    if (targetEventsPerDay < 1) {
      throw ArgumentError('targetEventsPerDay must be >= 1');
    }
    if (targetFocusMinutes < 1) {
      throw ArgumentError('targetFocusMinutes must be >= 1');
    }
  }

  // ── Event Score ────────────────────────────────────────────

  /// Score events for a given day: completion rate of checklist items,
  /// high-priority event completion bonus, and count normalization.
  double scoreEvents(List<EventModel> events, DateTime date) {
    final dayEvents = _eventsForDay(events, date);
    if (dayEvents.isEmpty) return 0;

    double score = 0;

    // 1. Count score: having events planned is productive (up to 40 pts)
    final countRatio = min(dayEvents.length / targetEventsPerDay, 1.5);
    score += min(countRatio * 30, 40);

    // 2. Checklist completion (up to 40 pts)
    int totalItems = 0;
    int completedItems = 0;
    for (final e in dayEvents) {
      if (e.checklist.hasItems) {
        totalItems += e.checklist.items.length;
        completedItems +=
            e.checklist.items.where((i) => i.completed).length;
      }
    }
    if (totalItems > 0) {
      score += (completedItems / totalItems) * 40;
    } else {
      // No checklists — give partial credit for having events
      score += 20;
    }

    // 3. Priority bonus: completing high/urgent events (up to 20 pts)
    final highPriority = dayEvents.where(
      (e) =>
          e.priority == EventPriority.high ||
          e.priority == EventPriority.urgent,
    );
    if (highPriority.isNotEmpty) {
      int highWithChecklist = 0;
      int highCompleted = 0;
      for (final e in highPriority) {
        if (e.checklist.hasItems) {
          highWithChecklist++;
          final allDone =
              e.checklist.items.every((i) => i.completed);
          if (allDone) highCompleted++;
        }
      }
      if (highWithChecklist > 0) {
        score += (highCompleted / highWithChecklist) * 20;
      } else {
        score += 10; // Partial credit for having high-priority items
      }
    }

    return min(score, 100);
  }

  // ── Habit Score ────────────────────────────────────────────

  /// Score habit completion for a day: percentage of due habits completed.
  double scoreHabits(
    List<Habit> habits,
    Map<String, List<DateTime>> completions,
    DateTime date,
  ) {
    if (habits.isEmpty) return 0;

    final dueHabits = habits.where((h) => h.isActive && _isDue(h, date));
    if (dueHabits.isEmpty) return 100; // No habits due = perfect

    int due = 0;
    int completed = 0;

    for (final habit in dueHabits) {
      due++;
      final dates = completions[habit.id] ?? [];
      final doneToday = dates.any((d) => AppDateUtils.isSameDay(d, date));
      if (doneToday) completed++;
    }

    if (due == 0) return 100;
    return (completed / due) * 100;
  }

  // ── Goal Score ─────────────────────────────────────────────

  /// Score goal progress: average progress across active goals,
  /// with bonus for goals ahead of schedule.
  double scoreGoals(List<Goal> goals, DateTime date) {
    final activeGoals =
        goals.where((g) => !g.isCompleted && (g.deadline == null || g.deadline!.isAfter(date)));
    if (activeGoals.isEmpty) {
      // All goals completed or none exist
      final anyCompleted = goals.any((g) => g.isCompleted);
      return anyCompleted ? 100 : 0;
    }

    double totalScore = 0;
    int count = 0;

    for (final goal in activeGoals) {
      count++;
      final elapsed =
          date.difference(goal.createdAt).inDays.toDouble();
      final totalDays =
          (goal.deadline ?? date.add(const Duration(days: 30))).difference(goal.createdAt).inDays.toDouble();
      final expectedProgress =
          totalDays > 0 ? min(elapsed / totalDays, 1.0) : 1.0;
      final actualProgress = goal.progress / 100.0;

      // Base: actual progress (0-70)
      totalScore += actualProgress * 70;

      // Ahead-of-schedule bonus (0-30)
      if (expectedProgress > 0) {
        final ratio = actualProgress / expectedProgress;
        totalScore += min(ratio, 2.0) * 15;
      }
    }

    return min(totalScore / count, 100);
  }

  // ── Sleep Score ────────────────────────────────────────────

  /// Score sleep quality: quality rating (0-60), duration fit (0-40).
  double scoreSleep(List<SleepEntry> entries, DateTime date) {
    final entry = _sleepForDay(entries, date);
    return _scoreSleepEntry(entry);
  }

  // ── Mood Score ─────────────────────────────────────────────

  /// Score mood: directly maps mood level (1-5) to 0-100.
  double scoreMood(List<MoodEntry> entries, DateTime date) {
    final dayEntries =
        entries.where((e) => AppDateUtils.isSameDay(e.timestamp, date)).toList();
    return _scoreMoodEntries(dayEntries);
  }

  // ── Focus Score ────────────────────────────────────────────

  /// Score focus time (Pomodoro minutes) against daily target.
  double scoreFocus(int focusMinutes) {
    if (focusMinutes <= 0) return 0;
    final ratio = focusMinutes / targetFocusMinutes;
    // Cap at 100 — meeting or exceeding target is full marks
    return min(ratio * 100, 100);
  }

  // ── Batch Multi-Day Scoring ──────────────────────────────────

  /// Compute daily scores for multiple dates efficiently.
  ///
  /// Pre-indexes events and sleep entries by date key (O(n) once) so
  /// each day's scoring is O(1) lookup instead of O(n) linear scan.
  /// For a 30-day period with 1000 events this reduces from O(30×1000)
  /// to O(1000 + 30).
  List<DailyProductivityScore> computeMultiDayScores({
    required List<DateTime> dates,
    required List<EventModel> events,
    required List<Habit> habits,
    required Map<String, List<DateTime>> habitCompletions,
    required List<Goal> goals,
    required List<SleepEntry> sleepEntries,
    required List<MoodEntry> moodEntries,
    required Map<DateTime, int> focusMinutesByDay,
  }) {
    // Pre-index for O(1) per-day lookups
    final eventIndex = _indexEventsByDay(events);
    final sleepIndex = _indexSleepByDay(sleepEntries);

    // Pre-index mood entries by day
    final moodIndex = <int, List<MoodEntry>>{};
    for (final m in moodEntries) {
      final key = m.timestamp.year * 10000 + m.timestamp.month * 100 + m.timestamp.day;
      moodIndex.putIfAbsent(key, () => []).add(m);
    }

    return dates.map((date) {
      final key = date.year * 10000 + date.month * 100 + date.day;
      final dayEvents = eventIndex[key] ?? [];
      final daySleep = sleepIndex[key];
      final dayMoods = moodIndex[key] ?? [];

      final eventScore = scoreEvents(dayEvents, date);
      final habitScore = scoreHabits(habits, habitCompletions, date);
      final goalScore = scoreGoals(goals, date);

      // Use indexed sleep/mood directly instead of linear scans
      final sleepScore = _scoreSleepEntry(daySleep);
      final moodScore = _scoreMoodEntries(dayMoods);

      final focusMins = focusMinutesByDay[date] ?? 0;
      final focusScore = scoreFocus(focusMins);

      final dimensions = [
        DimensionScore(name: 'Events', score: _round(eventScore), weight: weights.events, contribution: _round(eventScore * weights.events), insight: _eventInsight(eventScore)),
        DimensionScore(name: 'Habits', score: _round(habitScore), weight: weights.habits, contribution: _round(habitScore * weights.habits), insight: _habitInsight(habitScore)),
        DimensionScore(name: 'Goals', score: _round(goalScore), weight: weights.goals, contribution: _round(goalScore * weights.goals), insight: _goalInsight(goalScore)),
        DimensionScore(name: 'Sleep', score: _round(sleepScore), weight: weights.sleep, contribution: _round(sleepScore * weights.sleep), insight: _sleepInsight(sleepScore)),
        DimensionScore(name: 'Mood', score: _round(moodScore), weight: weights.mood, contribution: _round(moodScore * weights.mood), insight: _moodInsight(moodScore)),
        DimensionScore(name: 'Focus', score: _round(focusScore), weight: weights.focus, contribution: _round(focusScore * weights.focus), insight: _focusInsight(focusScore, focusMins)),
      ];

      final overall = dimensions.fold<double>(0, (sum, d) => sum + d.contribution);
      final roundedOverall = _round(overall);

      return DailyProductivityScore(
        date: date,
        overallScore: roundedOverall,
        grade: _gradeFromScore(roundedOverall),
        dimensions: dimensions,
        strengths: dimensions.where((d) => d.score >= 75 && d.weight > 0).map((d) => '${d.name}: ${d.insight}').toList(),
        improvements: dimensions.where((d) => d.score < 50 && d.weight > 0).map((d) => '${d.name}: ${d.insight}').toList(),
      );
    }).toList();
  }

  // ── Daily Composite Score ──────────────────────────────────

  /// Compute a composite daily productivity score (0-100).
  DailyProductivityScore computeDailyScore({
    required DateTime date,
    required List<EventModel> events,
    required List<Habit> habits,
    required Map<String, List<DateTime>> habitCompletions,
    required List<Goal> goals,
    required List<SleepEntry> sleepEntries,
    required List<MoodEntry> moodEntries,
    required int focusMinutes,
  }) {
    final eventScore = scoreEvents(events, date);
    final habitScore = scoreHabits(habits, habitCompletions, date);
    final goalScore = scoreGoals(goals, date);
    final sleepScore = scoreSleep(sleepEntries, date);
    final moodScore = scoreMood(moodEntries, date);
    final focusScore = scoreFocus(focusMinutes);

    final dimensions = [
      DimensionScore(
        name: 'Events',
        score: _round(eventScore),
        weight: weights.events,
        contribution: _round(eventScore * weights.events),
        insight: _eventInsight(eventScore),
      ),
      DimensionScore(
        name: 'Habits',
        score: _round(habitScore),
        weight: weights.habits,
        contribution: _round(habitScore * weights.habits),
        insight: _habitInsight(habitScore),
      ),
      DimensionScore(
        name: 'Goals',
        score: _round(goalScore),
        weight: weights.goals,
        contribution: _round(goalScore * weights.goals),
        insight: _goalInsight(goalScore),
      ),
      DimensionScore(
        name: 'Sleep',
        score: _round(sleepScore),
        weight: weights.sleep,
        contribution: _round(sleepScore * weights.sleep),
        insight: _sleepInsight(sleepScore),
      ),
      DimensionScore(
        name: 'Mood',
        score: _round(moodScore),
        weight: weights.mood,
        contribution: _round(moodScore * weights.mood),
        insight: _moodInsight(moodScore),
      ),
      DimensionScore(
        name: 'Focus',
        score: _round(focusScore),
        weight: weights.focus,
        contribution: _round(focusScore * weights.focus),
        insight: _focusInsight(focusScore, focusMinutes),
      ),
    ];

    final overall = dimensions.fold<double>(
      0,
      (sum, d) => sum + d.contribution,
    );
    final roundedOverall = _round(overall);
    final grade = _gradeFromScore(roundedOverall);

    // Find strengths (>= 75) and improvements (< 50)
    final strengths = dimensions
        .where((d) => d.score >= 75 && d.weight > 0)
        .map((d) => '${d.name}: ${d.insight}')
        .toList();
    final improvements = dimensions
        .where((d) => d.score < 50 && d.weight > 0)
        .map((d) => '${d.name}: ${d.insight}')
        .toList();

    return DailyProductivityScore(
      date: date,
      overallScore: roundedOverall,
      grade: grade,
      dimensions: dimensions,
      strengths: strengths,
      improvements: improvements,
    );
  }

  // ── Trend Analysis ─────────────────────────────────────────

  /// Compute productivity trend over a list of daily scores.
  ProductivityTrend analyzeTrend(List<DailyProductivityScore> scores) {
    if (scores.isEmpty) {
      return ProductivityTrend(
        dailyScores: [],
        averageScore: 0,
        bestScore: 0,
        worstScore: 0,
        direction: TrendDirection.stable,
        trendSlope: 0,
        dimensionAverages: {},
        streak: 0,
      );
    }

    final sorted = List<DailyProductivityScore>.from(scores)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Single pass: compute sum, best, worst, and linear regression
    // accumulators simultaneously instead of 4 separate iterations.
    double sumScore = 0;
    double best = -1;
    double worst = 101;
    DateTime? bestDay;
    DateTime? worstDay;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    final n = sorted.length;

    for (int i = 0; i < n; i++) {
      final s = sorted[i];
      final score = s.overallScore;
      sumScore += score;
      if (score > best) {
        best = score;
        bestDay = s.date;
      }
      if (score < worst) {
        worst = score;
        worstDay = s.date;
      }
      // Linear regression accumulators
      sumX += i;
      sumY += score;
      sumXY += i * score;
      sumX2 += i * i;
    }

    final avg = sumScore / n;

    // Linear regression slope (inline to avoid extra list allocation)
    final denom = n * sumX2 - sumX * sumX;
    final slope = denom == 0 ? 0.0 : (n * sumXY - sumX * sumY) / denom;

    TrendDirection direction;
    if (slope > 1.0) {
      direction = TrendDirection.rising;
    } else if (slope < -1.0) {
      direction = TrendDirection.declining;
    } else {
      direction = TrendDirection.stable;
    }

    // Dimension averages — single pass over all scores instead of
    // 6 separate expand+where+map passes (was O(6·n·d), now O(n·d)).
    final dimSums = <String, double>{};
    final dimCounts = <String, int>{};
    for (final s in sorted) {
      for (final d in s.dimensions) {
        dimSums[d.name] = (dimSums[d.name] ?? 0) + d.score;
        dimCounts[d.name] = (dimCounts[d.name] ?? 0) + 1;
      }
    }
    final dimAverages = <String, double>{};
    for (final name in dimSums.keys) {
      dimAverages[name] = _round(dimSums[name]! / dimCounts[name]!);
    }

    // Top strength / weakness
    String? topStrength;
    String? topWeakness;
    double maxAvg = -1;
    double minAvg = 101;
    for (final entry in dimAverages.entries) {
      if (entry.value > maxAvg) {
        maxAvg = entry.value;
        topStrength = entry.key;
      }
      if (entry.value < minAvg) {
        minAvg = entry.value;
        topWeakness = entry.key;
      }
    }

    // Streak: consecutive days with score >= 60
    int streak = 0;
    for (int i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].overallScore >= 60) {
        streak++;
      } else {
        break;
      }
    }

    return ProductivityTrend(
      dailyScores: sorted,
      averageScore: _round(avg),
      bestScore: _round(best),
      worstScore: _round(worst),
      bestDay: bestDay,
      worstDay: worstDay,
      direction: direction,
      trendSlope: _round(slope),
      dimensionAverages: dimAverages,
      topStrength: topStrength,
      topWeakness: topWeakness,
      streak: streak,
    );
  }

  // ── Weekly Summary ─────────────────────────────────────────

  /// Summarize a week's productivity with comparisons.
  Map<String, dynamic> weeklySummary(
    List<DailyProductivityScore> thisWeek,
    List<DailyProductivityScore> lastWeek,
  ) {
    final thisTrend = analyzeTrend(thisWeek);
    final lastTrend = analyzeTrend(lastWeek);

    final change = thisTrend.averageScore - lastTrend.averageScore;

    // Per-dimension comparison
    final dimChanges = <String, double>{};
    for (final key in thisTrend.dimensionAverages.keys) {
      final thisVal = thisTrend.dimensionAverages[key] ?? 0;
      final lastVal = lastTrend.dimensionAverages[key] ?? 0;
      dimChanges[key] = _round(thisVal - lastVal);
    }

    return {
      'thisWeek': {
        'average': thisTrend.averageScore,
        'best': thisTrend.bestScore,
        'worst': thisTrend.worstScore,
        'direction': thisTrend.direction.name,
        'streak': thisTrend.streak,
      },
      'lastWeek': {
        'average': lastTrend.averageScore,
      },
      'change': _round(change),
      'improving': change > 0,
      'dimensionChanges': dimChanges,
      'topStrength': thisTrend.topStrength,
      'topWeakness': thisTrend.topWeakness,
    };
  }

  // ── Helpers ────────────────────────────────────────────────

  /// Pre-indexes events by date key for O(1) lookups per day.
  ///
  /// Call this once before scoring multiple days to avoid
  /// O(n) linear scans per day in [_eventsForDay].
  Map<int, List<EventModel>> _indexEventsByDay(List<EventModel> events) {
    final index = <int, List<EventModel>>{};
    for (final e in events) {
      final key = e.date.year * 10000 + e.date.month * 100 + e.date.day;
      index.putIfAbsent(key, () => []).add(e);
    }
    return index;
  }

  /// Pre-indexes sleep entries by wake-date key for O(1) lookups.
  Map<int, SleepEntry> _indexSleepByDay(List<SleepEntry> entries) {
    final index = <int, SleepEntry>{};
    for (final entry in entries) {
      final d = entry.wakeTime;
      final key = d.year * 10000 + d.month * 100 + d.day;
      // Last entry for a given day wins (most recent)
      index[key] = entry;
    }
    return index;
  }

  List<EventModel> _eventsForDay(List<EventModel> events, DateTime date) {
    return events.where((e) {
      return AppDateUtils.isSameDay(e.date, date);
    }).toList();
  }

  SleepEntry? _sleepForDay(List<SleepEntry> entries, DateTime date) {
    // Sleep entry for a day is the one where wakeTime falls on that date
    for (final entry in entries) {
      if (AppDateUtils.isSameDay(entry.wakeTime, date)) return entry;
    }
    return null;
  }

  bool _isDue(Habit habit, DateTime date) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekdays:
        return date.weekday <= 5;
      case HabitFrequency.weekends:
        return date.weekday > 5;
      case HabitFrequency.custom:
        return habit.customDays.contains(date.weekday);
    }
  }

  double _round(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  ProductivityGrade _gradeFromScore(double score) {
    if (score >= 85) return ProductivityGrade.excellent;
    if (score >= 70) return ProductivityGrade.great;
    if (score >= 55) return ProductivityGrade.good;
    if (score >= 40) return ProductivityGrade.fair;
    return ProductivityGrade.needsWork;
  }

  /// Score a single sleep entry: quality rating (0-60) + duration fit (0-40).
  double _scoreSleepEntry(SleepEntry? entry) {
    if (entry == null) return 0;
    double score = (entry.quality.value / 5.0) * 60;
    final hours = entry.durationHours;
    if (hours >= 7 && hours <= 9) {
      score += 40;
    } else if (hours >= 6 && hours < 7) {
      score += 25;
    } else if (hours > 9 && hours <= 10) {
      score += 30;
    } else if (hours >= 5 && hours < 6) {
      score += 15;
    } else {
      score += 5;
    }
    return min(score, 100);
  }

  /// Score a list of mood entries for a single day: average mood mapped to 0-100.
  double _scoreMoodEntries(List<MoodEntry> dayEntries) {
    if (dayEntries.isEmpty) return 0;
    final avgMood =
        dayEntries.map((e) => e.mood.value).reduce((a, b) => a + b) /
            dayEntries.length;
    return (avgMood / 5.0) * 100;
  }

  String _eventInsight(double score) {
    if (score >= 80) return 'Strong task completion today';
    if (score >= 60) return 'Good event management';
    if (score >= 40) return 'Some tasks completed';
    if (score > 0) return 'Consider planning more structured tasks';
    return 'No events tracked today';
  }

  String _habitInsight(double score) {
    if (score >= 90) return 'All habits on track';
    if (score >= 70) return 'Most habits completed';
    if (score >= 50) return 'Some habits missed';
    if (score > 0) return 'Several habits need attention';
    return 'No habits tracked today';
  }

  String _goalInsight(double score) {
    if (score >= 80) return 'Ahead of schedule on goals';
    if (score >= 60) return 'Good progress toward goals';
    if (score >= 40) return 'Goals progressing slowly';
    if (score > 0) return 'Goals need more attention';
    return 'No active goals';
  }

  String _sleepInsight(double score) {
    if (score >= 80) return 'Excellent sleep quality and duration';
    if (score >= 60) return 'Good rest last night';
    if (score >= 40) return 'Sleep could be better';
    if (score > 0) return 'Poor sleep — may affect productivity';
    return 'No sleep data recorded';
  }

  String _moodInsight(double score) {
    if (score >= 80) return 'Feeling great today';
    if (score >= 60) return 'Positive mood';
    if (score >= 40) return 'Neutral mood';
    if (score > 0) return 'Low mood — be kind to yourself';
    return 'No mood logged today';
  }

  String _focusInsight(double score, int minutes) {
    if (score >= 80) return '${minutes}min of deep focus — excellent';
    if (score >= 60) return '${minutes}min focused — good progress';
    if (score >= 40) return '${minutes}min — try another Pomodoro session';
    if (score > 0) return '${minutes}min — more focus time would help';
    return 'No focus sessions today';
  }
}
