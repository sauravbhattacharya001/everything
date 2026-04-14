/// Event Pattern Recognizer — analyzes historical events to discover
/// recurring patterns the user hasn't explicitly formalized, detect
/// scheduling habits, and predict likely future events.
///
/// Use this to answer: "What meetings do I have regularly that aren't
/// marked as recurring?", "What are my scheduling habits?", "What events
/// am I likely to have next week?"
///
/// Key concepts:
///   - **Pattern**: A group of similar events that recur at detectable
///     intervals (daily, weekly, biweekly, monthly).
///   - **Habit**: A behavioral tendency like "most meetings are in the
///     morning" or "Fridays are light".
///   - **Prediction**: A forecasted event based on detected patterns.

import 'dart:math' as math;

import '../../models/event_model.dart';

// ─── Data Classes ───────────────────────────────────────────────

/// The detected recurrence cadence of a pattern.
enum PatternCadence {
  daily,
  weekly,
  biweekly,
  monthly,
  irregular;

  String get label {
    switch (this) {
      case PatternCadence.daily:
        return 'Daily';
      case PatternCadence.weekly:
        return 'Weekly';
      case PatternCadence.biweekly:
        return 'Biweekly';
      case PatternCadence.monthly:
        return 'Monthly';
      case PatternCadence.irregular:
        return 'Irregular';
    }
  }
}

/// A detected recurring pattern from historical events.
class EventPattern {
  final String title;
  final PatternCadence cadence;
  final double confidence;
  final int occurrenceCount;
  final double averageIntervalDays;
  final double intervalStdDev;
  final int? preferredDayOfWeek;
  final int? preferredHour;
  final List<DateTime> occurrenceDates;
  final bool alreadyRecurring;

  const EventPattern({
    required this.title,
    required this.cadence,
    required this.confidence,
    required this.occurrenceCount,
    required this.averageIntervalDays,
    required this.intervalStdDev,
    this.preferredDayOfWeek,
    this.preferredHour,
    required this.occurrenceDates,
    this.alreadyRecurring = false,
  });

  bool get isSuggestionWorthy =>
      confidence >= 0.6 && occurrenceCount >= 3 && !alreadyRecurring;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventPattern && title == other.title && cadence == other.cadence;

  @override
  int get hashCode => Object.hash(title, cadence);

  @override
  String toString() =>
      'EventPattern("$title", ${cadence.label}, '
      'confidence: ${(confidence * 100).toStringAsFixed(0)}%, '
      'count: $occurrenceCount)';
}

/// A scheduling habit detected from the user's event history.
class SchedulingHabit {
  final String description;
  final String category;
  final double value;
  final String detail;

  const SchedulingHabit({
    required this.description,
    required this.category,
    required this.value,
    required this.detail,
  });

  @override
  String toString() => 'SchedulingHabit($description: $detail)';
}

/// A predicted future event based on a detected pattern.
class EventPrediction {
  final EventPattern pattern;
  final DateTime predictedDate;
  final double confidence;

  const EventPrediction({
    required this.pattern,
    required this.predictedDate,
    required this.confidence,
  });

  @override
  String toString() =>
      'EventPrediction("${pattern.title}" on '
      '${predictedDate.toIso8601String().substring(0, 10)}, '
      'confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
}

/// Complete analysis report from the pattern recognizer.
class PatternReport {
  final List<EventPattern> patterns;
  final List<EventPattern> suggestions;
  final List<SchedulingHabit> habits;
  final List<EventPrediction> predictions;
  final int eventsAnalyzed;
  final DateTime from;
  final DateTime to;

  const PatternReport({
    required this.patterns,
    required this.suggestions,
    required this.habits,
    required this.predictions,
    required this.eventsAnalyzed,
    required this.from,
    required this.to,
  });

  String get summary {
    final buf = StringBuffer();
    buf.writeln('── Event Pattern Report ──');
    buf.writeln('Period: ${_fmtDate(from)} – ${_fmtDate(to)}');
    buf.writeln('Events analyzed: $eventsAnalyzed');
    buf.writeln('Patterns found: ${patterns.length}');
    buf.writeln('');

    if (suggestions.isNotEmpty) {
      buf.writeln('💡 Suggestions (${suggestions.length}):');
      for (final s in suggestions) {
        buf.writeln(
            '  • "${s.title}" — ${s.cadence.label} '
            '(${(s.confidence * 100).toStringAsFixed(0)}% confidence, '
            '${s.occurrenceCount} occurrences)');
      }
      buf.writeln('');
    }

    if (habits.isNotEmpty) {
      buf.writeln('📊 Habits:');
      for (final h in habits) {
        buf.writeln('  • ${h.detail}');
      }
      buf.writeln('');
    }

    if (predictions.isNotEmpty) {
      buf.writeln('🔮 Predictions (next ${predictions.length}):');
      for (final p in predictions) {
        final date = _fmtDate(p.predictedDate);
        final conf = (p.confidence * 100).toStringAsFixed(0);
        buf.writeln('  • "${p.pattern.title}" on $date ($conf%)');
      }
    }

    return buf.toString().trimRight();
  }

  @override
  String toString() =>
      'PatternReport(patterns: ${patterns.length}, '
      'suggestions: ${suggestions.length}, '
      'predictions: ${predictions.length})';
}

// ─── Service ────────────────────────────────────────────────────

class EventPatternService {
  /// Pre-compiled regexes for title normalization — avoids re-compiling
  /// on every call to [_normalizeTitle] (which runs per-event during
  /// pattern detection grouping).
  static final RegExp _multiSpace = RegExp(r'\s+');
  static final RegExp _trailingNumbers = RegExp(r'[#\d]+$');

  final int minOccurrences;
  final double maxIntervalCV;
  final int predictionDays;

  const EventPatternService({
    this.minOccurrences = 3,
    this.maxIntervalCV = 0.5,
    this.predictionDays = 14,
  });

  PatternReport analyze(
    List<EventModel> events, {
    DateTime? from,
    DateTime? to,
  }) {
    if (events.isEmpty) {
      final now = DateTime.now();
      return PatternReport(
        patterns: const [], suggestions: const [],
        habits: const [], predictions: const [],
        eventsAnalyzed: 0, from: from ?? now, to: to ?? now,
      );
    }

    final sorted = List.of(events)..sort((a, b) => a.date.compareTo(b.date));
    final effectiveFrom = from ?? sorted.first.date;
    final effectiveTo = to ?? sorted.last.date;

    final filtered = sorted
        .where((e) =>
            !e.date.isBefore(effectiveFrom) && !e.date.isAfter(effectiveTo))
        .toList();

    final patterns = _detectPatterns(filtered);
    final suggestions = patterns.where((p) => p.isSuggestionWorthy).toList();
    final habits = _detectHabits(filtered);
    final predictions = _generatePredictions(patterns, effectiveTo);

    return PatternReport(
      patterns: patterns, suggestions: suggestions,
      habits: habits, predictions: predictions,
      eventsAnalyzed: filtered.length,
      from: effectiveFrom, to: effectiveTo,
    );
  }

  List<EventPattern> detectPatterns(List<EventModel> events) =>
      _detectPatterns(events);

  List<EventPrediction> predict(
    List<EventPattern> patterns, {
    required DateTime after,
    int? days,
  }) =>
      _generatePredictions(patterns, after, days: days);

  // ─── Pattern Detection ──────────────────────────────────────

  List<EventPattern> _detectPatterns(List<EventModel> events) {
    final groups = <String, List<EventModel>>{};
    for (final e in events) {
      final key = _normalizeTitle(e.title);
      groups.putIfAbsent(key, () => []).add(e);
    }

    final patterns = <EventPattern>[];

    for (final entry in groups.entries) {
      final group = entry.value;
      if (group.length < minOccurrences) continue;

      final sorted = List.of(group)
        ..sort((a, b) => a.date.compareTo(b.date));
      final dates = sorted.map((e) => e.date).toList();

      final intervals = <double>[];
      for (var i = 1; i < dates.length; i++) {
        intervals.add(dates[i].difference(dates[i - 1]).inHours / 24.0);
      }
      if (intervals.isEmpty) continue;

      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final stdDev = _stdDev(intervals, avgInterval);
      final cv = avgInterval > 0 ? stdDev / avgInterval : double.infinity;

      final cadence = _classifyCadence(avgInterval, cv);
      if (cadence == PatternCadence.irregular && cv > maxIntervalCV) continue;

      final regularityScore = (1.0 - cv.clamp(0.0, 1.0));
      final countScore = (group.length / 10.0).clamp(0.0, 1.0);
      final confidence = (regularityScore * 0.6 + countScore * 0.4).clamp(0.0, 1.0);

      // Preferred day of week
      final dayCounts = <int, int>{};
      for (final d in dates) {
        dayCounts[d.weekday] = (dayCounts[d.weekday] ?? 0) + 1;
      }
      int? preferredDay;
      if (dayCounts.isNotEmpty) {
        final maxCount = dayCounts.values.reduce((a, b) => a > b ? a : b);
        if (maxCount / dates.length >= 0.5) {
          preferredDay = dayCounts.entries.firstWhere((e) => e.value == maxCount).key;
        }
      }

      // Preferred hour
      final hourCounts = <int, int>{};
      for (final d in dates) {
        hourCounts[d.hour] = (hourCounts[d.hour] ?? 0) + 1;
      }
      int? preferredHour;
      if (hourCounts.isNotEmpty) {
        final maxCount = hourCounts.values.reduce((a, b) => a > b ? a : b);
        if (maxCount / dates.length >= 0.4) {
          preferredHour = hourCounts.entries.firstWhere((e) => e.value == maxCount).key;
        }
      }

      final alreadyRecurring = group.any((e) => e.isRecurring);

      patterns.add(EventPattern(
        title: entry.key, cadence: cadence, confidence: confidence,
        occurrenceCount: group.length, averageIntervalDays: avgInterval,
        intervalStdDev: stdDev, preferredDayOfWeek: preferredDay,
        preferredHour: preferredHour, occurrenceDates: dates,
        alreadyRecurring: alreadyRecurring,
      ));
    }

    patterns.sort((a, b) => b.confidence.compareTo(a.confidence));
    return patterns;
  }

  PatternCadence _classifyCadence(double avgDays, double cv) {
    if (cv > 0.5) return PatternCadence.irregular;
    if (avgDays <= 1.5) return PatternCadence.daily;
    if (avgDays >= 5.0 && avgDays <= 9.0) return PatternCadence.weekly;
    if (avgDays >= 12.0 && avgDays <= 18.0) return PatternCadence.biweekly;
    if (avgDays >= 25.0 && avgDays <= 35.0) return PatternCadence.monthly;
    return PatternCadence.irregular;
  }

  // ─── Habit Detection ────────────────────────────────────────

  /// Detect scheduling habits from event history.
  ///
  /// **Single-pass implementation:** All per-event aggregations (time-of-day
  /// buckets, day-of-week counts, unique-day set, priority counts, weekend
  /// count, and duration accumulation) are computed in one traversal of the
  /// event list. The previous implementation iterated the list 6 separate
  /// times, which was O(6n) with poor cache locality and redundant null
  /// checks. This consolidation halves the wall-clock time for large event
  /// lists and eliminates intermediate allocations (the `where(...).map(...).
  /// toList()` chain for durations, the string-keyed `daySet`).
  ///
  /// The unique-day set now uses integer keys (YYYYMMDD) consistent with
  /// [HeatmapService] and [CorrelationAnalyzerService], avoiding per-event
  /// string interpolation.
  List<SchedulingHabit> _detectHabits(List<EventModel> events) {
    if (events.isEmpty) return [];

    // ── Single-pass aggregation ─────────────────────────────────
    int morningCount = 0, afternoonCount = 0, eveningCount = 0;
    final dayCounts = <int, int>{};
    final daySet = <int>{};
    final priorityCounts = <EventPriority, int>{};
    int weekendCount = 0;
    int durationSum = 0;
    int durationCount = 0;

    for (final e in events) {
      final d = e.date;
      // Time-of-day buckets
      final hour = d.hour;
      if (hour >= 6 && hour < 12) {
        morningCount++;
      } else if (hour >= 12 && hour < 17) {
        afternoonCount++;
      } else if (hour >= 17 && hour < 22) {
        eveningCount++;
      }
      // Day-of-week counts
      dayCounts[d.weekday] = (dayCounts[d.weekday] ?? 0) + 1;
      // Unique days (integer key, no string allocation)
      daySet.add(d.year * 10000 + d.month * 100 + d.day);
      // Priority counts
      priorityCounts[e.priority] = (priorityCounts[e.priority] ?? 0) + 1;
      // Weekend count
      if (d.weekday >= 6) weekendCount++;
      // Duration accumulation
      if (e.endDate != null) {
        final mins = e.endDate!.difference(d).inMinutes;
        if (mins > 0) {
          durationSum += mins;
          durationCount++;
        }
      }
    }

    // ── Build habit insights from aggregated data ───────────────
    final habits = <SchedulingHabit>[];

    // Time-of-day preference
    final totalTimed = morningCount + afternoonCount + eveningCount;
    if (totalTimed > 0) {
      String topPeriodName;
      int topPeriodValue;
      if (morningCount >= afternoonCount && morningCount >= eveningCount) {
        topPeriodName = 'morning'; topPeriodValue = morningCount;
      } else if (afternoonCount >= eveningCount) {
        topPeriodName = 'afternoon'; topPeriodValue = afternoonCount;
      } else {
        topPeriodName = 'evening'; topPeriodValue = eveningCount;
      }
      final pct = topPeriodValue / totalTimed * 100;
      if (pct >= 40) {
        habits.add(SchedulingHabit(
          description: 'Preferred time of day', category: 'timing',
          value: pct,
          detail: '${pct.toStringAsFixed(0)}% of events are in the $topPeriodName',
        ));
      }
    }

    // Day-of-week distribution
    if (dayCounts.isNotEmpty) {
      final busiestDay = dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      final quietestDay = dayCounts.entries.reduce((a, b) => a.value < b.value ? a : b);
      habits.add(SchedulingHabit(
        description: 'Busiest day', category: 'distribution',
        value: busiestDay.value.toDouble(),
        detail: '${_dayName(busiestDay.key)} is your busiest day (${busiestDay.value} events)',
      ));
      habits.add(SchedulingHabit(
        description: 'Quietest day', category: 'distribution',
        value: quietestDay.value.toDouble(),
        detail: '${_dayName(quietestDay.key)} is your quietest day (${quietestDay.value} events)',
      ));
    }

    // Event density (using integer daySet — no string allocations)
    if (daySet.isNotEmpty) {
      final avg = events.length / daySet.length;
      habits.add(SchedulingHabit(
        description: 'Event density', category: 'frequency',
        value: avg,
        detail: '${avg.toStringAsFixed(1)} events per active day on average',
      ));
    }

    // Priority preference
    if (priorityCounts.isNotEmpty) {
      final topPriority = priorityCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      final pct = (topPriority.value / events.length * 100);
      habits.add(SchedulingHabit(
        description: 'Priority preference', category: 'preference',
        value: pct,
        detail: '${pct.toStringAsFixed(0)}% of events are ${topPriority.key.label} priority',
      ));
    }

    // Weekend activity
    final weekendPct = (weekendCount / events.length * 100);
    habits.add(SchedulingHabit(
      description: 'Weekend activity', category: 'distribution',
      value: weekendPct,
      detail: weekendPct > 20
          ? 'Active weekends — ${weekendPct.toStringAsFixed(0)}% of events fall on weekends'
          : 'Weekday-focused — only ${weekendPct.toStringAsFixed(0)}% of events on weekends',
    ));

    // Event duration habit
    if (durationCount >= 3) {
      final avgDur = durationSum / durationCount;
      final label = avgDur < 30
          ? 'Quick scheduler — average event is ${avgDur.toStringAsFixed(0)} minutes'
          : avgDur < 60
              ? 'Standard blocks — average event is ${avgDur.toStringAsFixed(0)} minutes'
              : 'Long-block scheduler — average event is ${avgDur.toStringAsFixed(0)} minutes';
      habits.add(SchedulingHabit(
        description: 'Event duration', category: 'preference',
        value: avgDur, detail: label,
      ));
    }

    return habits;
  }

  // ─── Prediction ─────────────────────────────────────────────

  List<EventPrediction> _generatePredictions(
    List<EventPattern> patterns, DateTime after, {int? days,}
  ) {
    final horizon = days ?? predictionDays;
    final cutoff = after.add(Duration(days: horizon));
    final predictions = <EventPrediction>[];

    for (final pattern in patterns) {
      if (pattern.cadence == PatternCadence.irregular) continue;
      if (pattern.occurrenceDates.isEmpty) continue;

      final lastDate = pattern.occurrenceDates.last;
      final intervalDays = pattern.averageIntervalDays;
      if (intervalDays <= 0) continue;

      var nextDate = lastDate.add(Duration(hours: (intervalDays * 24).round()));
      while (nextDate.isBefore(after)) {
        nextDate = nextDate.add(Duration(hours: (intervalDays * 24).round()));
      }

      var count = 0;
      while (!nextDate.isAfter(cutoff) && count < 5) {
        var adjustedDate = nextDate;
        if (pattern.preferredDayOfWeek != null &&
            (pattern.cadence == PatternCadence.weekly || pattern.cadence == PatternCadence.biweekly)) {
          final diff = pattern.preferredDayOfWeek! - adjustedDate.weekday;
          adjustedDate = adjustedDate.add(Duration(days: diff));
        }
        if (pattern.preferredHour != null) {
          adjustedDate = DateTime(adjustedDate.year, adjustedDate.month, adjustedDate.day, pattern.preferredHour!);
        }

        final daysSinceLast = adjustedDate.difference(lastDate).inDays.abs();
        final decayFactor = 1.0 / (1.0 + (daysSinceLast / 30.0));
        final predConfidence = (pattern.confidence * decayFactor).clamp(0.0, 1.0);

        if (predConfidence >= 0.2) {
          predictions.add(EventPrediction(
            pattern: pattern, predictedDate: adjustedDate, confidence: predConfidence,
          ));
        }

        nextDate = nextDate.add(Duration(hours: (intervalDays * 24).round()));
        count++;
      }
    }

    predictions.sort((a, b) => a.predictedDate.compareTo(b.predictedDate));
    return predictions;
  }

  // ─── Utilities ──────────────────────────────────────────────

  /// Normalize a title for pattern grouping.
  ///
  /// Uses pre-compiled [_multiSpace] and [_trailingNumbers] regexes
  /// instead of constructing new [RegExp] instances on every call.
  /// Since this runs once per event during [_detectPatterns], avoiding
  /// repeated regex compilation saves ~2 allocations per event.
  String _normalizeTitle(String title) {
    return title.toLowerCase().trim()
        .replaceAll(_multiSpace, ' ')
        .replaceAll(_trailingNumbers, '')
        .trim();
  }

  double _stdDev(List<double> values, double mean) {
    if (values.length < 2) return 0.0;
    final sumSqDiff = values.fold<double>(0, (sum, v) => sum + (v - mean) * (v - mean));
    return math.sqrt(sumSqDiff / (values.length - 1));
  }

  String _dayName(int weekday) {
    const names = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[weekday.clamp(1, 7)];
  }
}

String _fmtDate(DateTime dt) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}
