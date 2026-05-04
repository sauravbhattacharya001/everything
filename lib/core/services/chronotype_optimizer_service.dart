import 'dart:math';

/// Chronotype Optimizer Engine — autonomous circadian rhythm analyzer.
///
/// Analyzes activity timing patterns to detect the user's natural chronotype,
/// identifies peak performance windows for different task types, and provides
/// personalized time-of-day recommendations for schedule optimization.
///
/// 7 engines:
/// 1. **Activity Clock Logger** — records activities with timestamps & task types
/// 2. **Circadian Profile Builder** — 24-hour energy curve via kernel density
/// 3. **Chronotype Classifier** — Lion / Bear / Wolf / Dolphin classification
/// 4. **Peak Window Detector** — optimal time windows per task type
/// 5. **Schedule Alignment Scorer** — current-vs-optimal alignment 0-100
/// 6. **Drift Detector** — circadian rhythm shifts over time
/// 7. **Insight Generator** — ranked actionable recommendations

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Type of task being performed.
enum TaskType {
  deepWork,
  creative,
  routine,
  social,
  physical;

  String get label {
    switch (this) {
      case TaskType.deepWork:
        return 'Deep Work';
      case TaskType.creative:
        return 'Creative';
      case TaskType.routine:
        return 'Routine';
      case TaskType.social:
        return 'Social';
      case TaskType.physical:
        return 'Physical';
    }
  }

  String get emoji {
    switch (this) {
      case TaskType.deepWork:
        return '🧠';
      case TaskType.creative:
        return '🎨';
      case TaskType.routine:
        return '📋';
      case TaskType.social:
        return '👥';
      case TaskType.physical:
        return '🏃';
    }
  }

  String get description {
    switch (this) {
      case TaskType.deepWork:
        return 'Focused analytical or complex problem-solving work';
      case TaskType.creative:
        return 'Brainstorming, writing, design, and creative tasks';
      case TaskType.routine:
        return 'Email, admin, meetings, and repetitive tasks';
      case TaskType.social:
        return 'Collaboration, networking, and social interactions';
      case TaskType.physical:
        return 'Exercise, movement, and physical activities';
    }
  }
}

/// Chronotype classification based on circadian rhythm patterns.
enum Chronotype {
  lion,
  bear,
  wolf,
  dolphin;

  String get label {
    switch (this) {
      case Chronotype.lion:
        return 'Lion';
      case Chronotype.bear:
        return 'Bear';
      case Chronotype.wolf:
        return 'Wolf';
      case Chronotype.dolphin:
        return 'Dolphin';
    }
  }

  String get emoji {
    switch (this) {
      case Chronotype.lion:
        return '🦁';
      case Chronotype.bear:
        return '🐻';
      case Chronotype.wolf:
        return '🐺';
      case Chronotype.dolphin:
        return '🐬';
    }
  }

  String get description {
    switch (this) {
      case Chronotype.lion:
        return 'Early bird — peak energy before 10 AM, winds down by evening';
      case Chronotype.bear:
        return 'Solar-aligned — follows the sun, peaks mid-morning to early afternoon';
      case Chronotype.wolf:
        return 'Night owl — energy rises in the afternoon, peaks in the evening';
      case Chronotype.dolphin:
        return 'Irregular — no clear peak, sensitive sleeper, variable energy';
    }
  }

  int get colorHex {
    switch (this) {
      case Chronotype.lion:
        return 0xFFFFA726;
      case Chronotype.bear:
        return 0xFF8D6E63;
      case Chronotype.wolf:
        return 0xFF5C6BC0;
      case Chronotype.dolphin:
        return 0xFF26C6DA;
    }
  }
}

/// How well current activity timing aligns with detected chronotype.
enum AlignmentGrade {
  optimal,
  good,
  fair,
  misaligned,
  chaotic;

  String get label {
    switch (this) {
      case AlignmentGrade.optimal:
        return 'Optimal';
      case AlignmentGrade.good:
        return 'Good';
      case AlignmentGrade.fair:
        return 'Fair';
      case AlignmentGrade.misaligned:
        return 'Misaligned';
      case AlignmentGrade.chaotic:
        return 'Chaotic';
    }
  }

  String get emoji {
    switch (this) {
      case AlignmentGrade.optimal:
        return '🌟';
      case AlignmentGrade.good:
        return '✅';
      case AlignmentGrade.fair:
        return '⚠️';
      case AlignmentGrade.misaligned:
        return '🔴';
      case AlignmentGrade.chaotic:
        return '🌪️';
    }
  }

  String get description {
    switch (this) {
      case AlignmentGrade.optimal:
        return 'Activities perfectly match your natural rhythm';
      case AlignmentGrade.good:
        return 'Mostly aligned with minor scheduling opportunities';
      case AlignmentGrade.fair:
        return 'Some activities could be better timed';
      case AlignmentGrade.misaligned:
        return 'Significant mismatch between schedule and biology';
      case AlignmentGrade.chaotic:
        return 'No discernible alignment with circadian rhythm';
    }
  }
}

/// Type of circadian drift detected.
enum DriftType {
  stable,
  jetLag,
  scheduleCreep,
  weekendShift,
  erratic;

  String get label {
    switch (this) {
      case DriftType.stable:
        return 'Stable';
      case DriftType.jetLag:
        return 'Jet Lag';
      case DriftType.scheduleCreep:
        return 'Schedule Creep';
      case DriftType.weekendShift:
        return 'Weekend Shift';
      case DriftType.erratic:
        return 'Erratic';
    }
  }

  String get emoji {
    switch (this) {
      case DriftType.stable:
        return '⚓';
      case DriftType.jetLag:
        return '✈️';
      case DriftType.scheduleCreep:
        return '🐌';
      case DriftType.weekendShift:
        return '🔄';
      case DriftType.erratic:
        return '🎲';
    }
  }

  String get description {
    switch (this) {
      case DriftType.stable:
        return 'Consistent circadian timing across days';
      case DriftType.jetLag:
        return 'Abrupt timing shift detected, similar to jet lag';
      case DriftType.scheduleCreep:
        return 'Gradual drift in activity timing over weeks';
      case DriftType.weekendShift:
        return 'Significant difference between weekday and weekend patterns';
      case DriftType.erratic:
        return 'High variability in daily timing with no clear pattern';
    }
  }
}

/// Severity for insights.
enum InsightSeverity {
  high,
  medium,
  low;

  String get emoji {
    switch (this) {
      case InsightSeverity.high:
        return '🔴';
      case InsightSeverity.medium:
        return '🟡';
      case InsightSeverity.low:
        return '🟢';
    }
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// A single logged activity with timestamp and task type.
class ActivityClockEntry {
  final String id;
  final DateTime timestamp;
  final TaskType taskType;
  final int durationMinutes;
  final double performanceScore; // 0.0 – 1.0 self-reported effectiveness

  ActivityClockEntry({
    required this.id,
    required this.timestamp,
    required this.taskType,
    this.durationMinutes = 30,
    this.performanceScore = 0.7,
  });

  /// Hour of day as fractional value (e.g. 14.5 = 2:30 PM).
  double get fractionalHour =>
      timestamp.hour + timestamp.minute / 60.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'taskType': taskType.name,
        'durationMinutes': durationMinutes,
        'performanceScore': performanceScore,
      };

  factory ActivityClockEntry.fromJson(Map<String, dynamic> json) {
    return ActivityClockEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      taskType: TaskType.values.firstWhere(
        (t) => t.name == json['taskType'],
        orElse: () => TaskType.routine,
      ),
      durationMinutes: json['durationMinutes'] as int? ?? 30,
      performanceScore: (json['performanceScore'] as num?)?.toDouble() ?? 0.7,
    );
  }
}

/// 24-hour energy profile built from activity timing data.
class CircadianProfile {
  /// Energy density for each hour 0-23, normalized to 0.0 – 1.0.
  final List<double> hourlyEnergy;

  /// Hour with peak energy.
  final int peakHour;

  /// Hour with lowest energy.
  final int troughHour;

  /// Standard deviation of activity start times (hours).
  final double timingVariability;

  CircadianProfile({
    required this.hourlyEnergy,
    required this.peakHour,
    required this.troughHour,
    required this.timingVariability,
  });
}

/// An optimal time window for a specific task type.
class PeakWindow {
  final TaskType taskType;
  final int startHour;
  final int endHour;
  final double confidenceScore; // 0.0 – 1.0

  PeakWindow({
    required this.taskType,
    required this.startHour,
    required this.endHour,
    required this.confidenceScore,
  });

  String get timeRange =>
      '${_formatHour(startHour)} – ${_formatHour(endHour)}';

  static String _formatHour(int h) {
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final amPm = h < 12 ? 'AM' : 'PM';
    return '$hour12 $amPm';
  }
}

/// A detected circadian drift event.
class DriftEvent {
  final DateTime detectedAt;
  final DriftType type;
  final double magnitudeHours;
  final String description;

  DriftEvent({
    required this.detectedAt,
    required this.type,
    required this.magnitudeHours,
    required this.description,
  });
}

/// An actionable insight from the engine.
class ChronotypeInsight {
  final InsightSeverity severity;
  final String title;
  final String body;
  final String recommendation;

  ChronotypeInsight({
    required this.severity,
    required this.title,
    required this.body,
    required this.recommendation,
  });
}

/// Weekly centroid for drift tracking.
class WeeklyCentroid {
  final DateTime weekStart;
  final double centroidHour;
  final int activityCount;

  WeeklyCentroid({
    required this.weekStart,
    required this.centroidHour,
    required this.activityCount,
  });
}

/// Full report from the Chronotype Optimizer Engine.
class ChronotypeReport {
  final Chronotype chronotype;
  final CircadianProfile profile;
  final List<PeakWindow> peakWindows;
  final int alignmentScore;
  final AlignmentGrade alignmentGrade;
  final DriftType currentDrift;
  final List<DriftEvent> driftEvents;
  final List<WeeklyCentroid> weeklyCentroids;
  final List<ChronotypeInsight> insights;
  final int totalActivities;

  ChronotypeReport({
    required this.chronotype,
    required this.profile,
    required this.peakWindows,
    required this.alignmentScore,
    required this.alignmentGrade,
    required this.currentDrift,
    required this.driftEvents,
    required this.weeklyCentroids,
    required this.insights,
    required this.totalActivities,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Autonomous Chronotype Optimizer Engine.
///
/// Call [addActivity] to log entries, then [generateReport] for full analysis.
/// Use [loadSampleData] to populate 30 days of realistic demo data.
class ChronotypeOptimizerService {
  final List<ActivityClockEntry> _activities = [];
  final Random _rng = Random(42);

  // ── Public API ──────────────────────────────────────────────────────────

  /// All logged activities.
  List<ActivityClockEntry> get activities => List.unmodifiable(_activities);

  /// Add a single activity entry.
  void addActivity(ActivityClockEntry entry) => _activities.add(entry);

  /// Clear all data.
  void clear() => _activities.clear();

  /// Populate with 30 days of realistic sample data.
  void loadSampleData() {
    _activities.clear();
    final now = DateTime.now();
    int idCounter = 0;

    for (int day = 29; day >= 0; day--) {
      final date = now.subtract(Duration(days: day));
      final isWeekend = date.weekday >= 6;

      // Base schedule shifts later on weekends.
      final baseShift = isWeekend ? 1.5 : 0.0;

      // Morning deep work block.
      _addSample(date, 7 + baseShift, TaskType.deepWork, 90, 0.85, idCounter++);
      _addSample(date, 8.5 + baseShift, TaskType.deepWork, 60, 0.80, idCounter++);

      // Mid-morning creative.
      _addSample(date, 10 + baseShift, TaskType.creative, 45, 0.75, idCounter++);

      // Late morning routine.
      _addSample(date, 11 + baseShift * 0.5, TaskType.routine, 30, 0.65, idCounter++);

      // Afternoon social.
      _addSample(date, 13 + baseShift * 0.3, TaskType.social, 60, 0.70, idCounter++);

      // Afternoon routine.
      _addSample(date, 14.5, TaskType.routine, 45, 0.60, idCounter++);

      // Late afternoon physical.
      _addSample(date, 17, TaskType.physical, 60, 0.80, idCounter++);

      // Evening creative burst (wolf-like).
      if (day % 3 == 0) {
        _addSample(date, 20, TaskType.creative, 45, 0.70, idCounter++);
      }

      // Add slight daily jitter.
      if (day % 5 == 0) {
        _addSample(date, 6 + _rng.nextDouble(), TaskType.physical, 30, 0.75, idCounter++);
      }
    }
  }

  void _addSample(DateTime date, double fracHour, TaskType type,
      int duration, double perf, int id) {
    final hour = fracHour.floor();
    final minute = ((fracHour - hour) * 60).round();
    final jitter = (_rng.nextDouble() - 0.5) * 30; // ±15 min jitter
    final ts = DateTime(date.year, date.month, date.day, hour, minute)
        .add(Duration(minutes: jitter.round()));
    _activities.add(ActivityClockEntry(
      id: 'sample_$id',
      timestamp: ts,
      taskType: type,
      durationMinutes: duration,
      performanceScore: (perf + (_rng.nextDouble() - 0.5) * 0.2).clamp(0.0, 1.0),
    ));
  }

  /// Run all 7 engines and produce a full report.
  ChronotypeReport generateReport() {
    if (_activities.isEmpty) {
      return _emptyReport();
    }

    // Engine 2: Circadian Profile Builder.
    final profile = _buildCircadianProfile();

    // Engine 3: Chronotype Classifier.
    final chronotype = _classifyChronotype(profile);

    // Engine 4: Peak Window Detector.
    final peakWindows = _detectPeakWindows();

    // Engine 5: Schedule Alignment Scorer.
    final alignResult = _scoreAlignment(chronotype, peakWindows);

    // Engine 6: Drift Detector.
    final centroids = _computeWeeklyCentroids();
    final driftResult = _detectDrift(centroids);

    // Engine 7: Insight Generator.
    final insights = _generateInsights(
      chronotype, profile, peakWindows, alignResult.$1, driftResult.$1,
    );

    return ChronotypeReport(
      chronotype: chronotype,
      profile: profile,
      peakWindows: peakWindows,
      alignmentScore: alignResult.$1,
      alignmentGrade: alignResult.$2,
      currentDrift: driftResult.$1,
      driftEvents: driftResult.$2,
      weeklyCentroids: centroids,
      insights: insights,
      totalActivities: _activities.length,
    );
  }

  // ── Engine 2: Circadian Profile Builder ─────────────────────────────────

  CircadianProfile _buildCircadianProfile() {
    // Gaussian kernel density estimation over 24 hours.
    final bandwidth = 1.0;
    final energyCurve = List<double>.filled(24, 0.0);

    for (final act in _activities) {
      final h = act.fractionalHour;
      for (int i = 0; i < 24; i++) {
        final diff = _circularDiff(i.toDouble(), h, 24.0);
        final kernel = exp(-(diff * diff) / (2 * bandwidth * bandwidth));
        energyCurve[i] += kernel * act.performanceScore;
      }
    }

    // Normalize to 0-1.
    final maxE = energyCurve.reduce(max);
    if (maxE > 0) {
      for (int i = 0; i < 24; i++) {
        energyCurve[i] /= maxE;
      }
    }

    // Find peak and trough.
    int peakHour = 0;
    int troughHour = 0;
    for (int i = 0; i < 24; i++) {
      if (energyCurve[i] > energyCurve[peakHour]) peakHour = i;
      if (energyCurve[i] < energyCurve[troughHour]) troughHour = i;
    }

    // Timing variability.
    final hours = _activities.map((a) => a.fractionalHour).toList();
    final meanHour = hours.reduce((a, b) => a + b) / hours.length;
    final variance = hours.map((h) {
      final d = _circularDiff(h, meanHour, 24.0);
      return d * d;
    }).reduce((a, b) => a + b) / hours.length;

    return CircadianProfile(
      hourlyEnergy: energyCurve,
      peakHour: peakHour,
      troughHour: troughHour,
      timingVariability: sqrt(variance),
    );
  }

  /// Circular distance on a 24-hour clock.
  double _circularDiff(double a, double b, double period) {
    final diff = (a - b).abs();
    return diff > period / 2 ? period - diff : diff;
  }

  // ── Engine 3: Chronotype Classifier ─────────────────────────────────────

  Chronotype _classifyChronotype(CircadianProfile profile) {
    // High variability → Dolphin.
    if (profile.timingVariability > 5.0) return Chronotype.dolphin;

    // Check if energy curve has a clear peak.
    final maxE = profile.hourlyEnergy.reduce(max);
    final minE = profile.hourlyEnergy.reduce(min);
    if (maxE - minE < 0.15) return Chronotype.dolphin;

    final peak = profile.peakHour;
    if (peak < 8) return Chronotype.lion;
    if (peak <= 14) return Chronotype.bear;
    return Chronotype.wolf;
  }

  // ── Engine 4: Peak Window Detector ──────────────────────────────────────

  List<PeakWindow> _detectPeakWindows() {
    final windows = <PeakWindow>[];

    for (final taskType in TaskType.values) {
      final taskActivities =
          _activities.where((a) => a.taskType == taskType).toList();
      if (taskActivities.isEmpty) continue;

      // Performance-weighted hour histogram.
      final hourPerf = List<double>.filled(24, 0.0);
      final hourCount = List<int>.filled(24, 0);
      for (final act in taskActivities) {
        final h = act.timestamp.hour;
        hourPerf[h] += act.performanceScore;
        hourCount[h]++;
      }

      // Average performance per hour.
      for (int i = 0; i < 24; i++) {
        if (hourCount[i] > 0) hourPerf[i] /= hourCount[i];
      }

      // Find best contiguous 3-hour window.
      double bestScore = -1;
      int bestStart = 0;
      for (int start = 0; start < 24; start++) {
        double score = 0;
        int count = 0;
        for (int offset = 0; offset < 3; offset++) {
          final h = (start + offset) % 24;
          if (hourCount[h] > 0) {
            score += hourPerf[h];
            count++;
          }
        }
        if (count > 0 && score / count > bestScore) {
          bestScore = score / count;
          bestStart = start;
        }
      }

      final totalTasks = taskActivities.length;
      final confidence = (totalTasks / 10.0).clamp(0.0, 1.0);

      windows.add(PeakWindow(
        taskType: taskType,
        startHour: bestStart,
        endHour: (bestStart + 3) % 24,
        confidenceScore: confidence * bestScore.clamp(0.0, 1.0),
      ));
    }

    // Sort by confidence descending.
    windows.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return windows;
  }

  // ── Engine 5: Schedule Alignment Scorer ─────────────────────────────────

  (int, AlignmentGrade) _scoreAlignment(
      Chronotype chronotype, List<PeakWindow> peakWindows) {
    if (_activities.isEmpty) return (0, AlignmentGrade.chaotic);

    // Ideal hour ranges per chronotype for deep work.
    final idealDeepWork = switch (chronotype) {
      Chronotype.lion => (6, 10),
      Chronotype.bear => (9, 13),
      Chronotype.wolf => (16, 20),
      Chronotype.dolphin => (10, 14),
    };

    // Score each activity by proximity to ideal window.
    double totalScore = 0;
    for (final act in _activities) {
      final h = act.fractionalHour;
      final ideal = idealDeepWork;
      if (h >= ideal.$1 && h <= ideal.$2) {
        totalScore += 1.0;
      } else {
        final dist = min(
          _circularDiff(h, ideal.$1.toDouble(), 24.0),
          _circularDiff(h, ideal.$2.toDouble(), 24.0),
        );
        totalScore += (1.0 - dist / 6.0).clamp(0.0, 1.0);
      }
    }

    final score = ((totalScore / _activities.length) * 100).round().clamp(0, 100);
    final grade = switch (score) {
      >= 80 => AlignmentGrade.optimal,
      >= 65 => AlignmentGrade.good,
      >= 45 => AlignmentGrade.fair,
      >= 25 => AlignmentGrade.misaligned,
      _ => AlignmentGrade.chaotic,
    };

    return (score, grade);
  }

  // ── Engine 6: Drift Detector ────────────────────────────────────────────

  List<WeeklyCentroid> _computeWeeklyCentroids() {
    if (_activities.isEmpty) return [];

    // Group by ISO week.
    final weekMap = <int, List<ActivityClockEntry>>{};
    for (final act in _activities) {
      final weekKey = _isoWeekKey(act.timestamp);
      weekMap.putIfAbsent(weekKey, () => []).add(act);
    }

    final centroids = <WeeklyCentroid>[];
    final sortedKeys = weekMap.keys.toList()..sort();
    for (final key in sortedKeys) {
      final acts = weekMap[key]!;
      final meanHour = acts.map((a) => a.fractionalHour).reduce((a, b) => a + b) /
          acts.length;
      centroids.add(WeeklyCentroid(
        weekStart: acts.map((a) => a.timestamp).reduce(
            (a, b) => a.isBefore(b) ? a : b),
        centroidHour: meanHour,
        activityCount: acts.length,
      ));
    }
    return centroids;
  }

  int _isoWeekKey(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(jan1).inDays;
    return date.year * 100 + (dayOfYear ~/ 7);
  }

  (DriftType, List<DriftEvent>) _detectDrift(List<WeeklyCentroid> centroids) {
    final events = <DriftEvent>[];
    if (centroids.length < 2) return (DriftType.stable, events);

    // Check for schedule creep (monotonic drift).
    double totalShift = 0;
    double maxAbruptShift = 0;
    for (int i = 1; i < centroids.length; i++) {
      final shift = centroids[i].centroidHour - centroids[i - 1].centroidHour;
      totalShift += shift;
      if (shift.abs() > maxAbruptShift) maxAbruptShift = shift.abs();

      if (shift.abs() > 2.0) {
        events.add(DriftEvent(
          detectedAt: centroids[i].weekStart,
          type: DriftType.jetLag,
          magnitudeHours: shift.abs(),
          description:
              'Abrupt ${shift.abs().toStringAsFixed(1)}h shift detected',
        ));
      }
    }

    // Weekend vs weekday analysis.
    final weekdayHours = <double>[];
    final weekendHours = <double>[];
    for (final act in _activities) {
      if (act.timestamp.weekday >= 6) {
        weekendHours.add(act.fractionalHour);
      } else {
        weekdayHours.add(act.fractionalHour);
      }
    }

    double weekendShiftMag = 0;
    if (weekdayHours.isNotEmpty && weekendHours.isNotEmpty) {
      final wdMean = weekdayHours.reduce((a, b) => a + b) / weekdayHours.length;
      final weMean = weekendHours.reduce((a, b) => a + b) / weekendHours.length;
      weekendShiftMag = (weMean - wdMean).abs();
      if (weekendShiftMag > 1.5) {
        events.add(DriftEvent(
          detectedAt: DateTime.now(),
          type: DriftType.weekendShift,
          magnitudeHours: weekendShiftMag,
          description:
              'Weekend activities shift ${weekendShiftMag.toStringAsFixed(1)}h later than weekdays',
        ));
      }
    }

    // Variability check.
    if (centroids.length >= 3) {
      final centroidHours = centroids.map((c) => c.centroidHour).toList();
      final mean = centroidHours.reduce((a, b) => a + b) / centroidHours.length;
      final variance =
          centroidHours.map((h) => (h - mean) * (h - mean)).reduce((a, b) => a + b) /
              centroidHours.length;
      if (sqrt(variance) > 2.5) {
        events.add(DriftEvent(
          detectedAt: DateTime.now(),
          type: DriftType.erratic,
          magnitudeHours: sqrt(variance),
          description: 'High week-to-week timing variability detected',
        ));
      }
    }

    // Determine overall drift type.
    DriftType overall;
    if (events.any((e) => e.type == DriftType.erratic)) {
      overall = DriftType.erratic;
    } else if (events.any((e) => e.type == DriftType.jetLag)) {
      overall = DriftType.jetLag;
    } else if (totalShift.abs() > 2.0) {
      events.add(DriftEvent(
        detectedAt: DateTime.now(),
        type: DriftType.scheduleCreep,
        magnitudeHours: totalShift.abs(),
        description:
            'Gradual ${totalShift.abs().toStringAsFixed(1)}h creep over the period',
      ));
      overall = DriftType.scheduleCreep;
    } else if (weekendShiftMag > 1.5) {
      overall = DriftType.weekendShift;
    } else {
      overall = DriftType.stable;
    }

    return (overall, events);
  }

  // ── Engine 7: Insight Generator ─────────────────────────────────────────

  List<ChronotypeInsight> _generateInsights(
    Chronotype chronotype,
    CircadianProfile profile,
    List<PeakWindow> peakWindows,
    int alignmentScore,
    DriftType driftType,
  ) {
    final insights = <ChronotypeInsight>[];

    // Chronotype description insight.
    insights.add(ChronotypeInsight(
      severity: InsightSeverity.low,
      title: 'You are a ${chronotype.emoji} ${chronotype.label}',
      body: chronotype.description,
      recommendation:
          'Organize your most demanding tasks around your natural peak hours.',
    ));

    // Alignment insight.
    if (alignmentScore < 50) {
      insights.add(ChronotypeInsight(
        severity: InsightSeverity.high,
        title: 'Schedule-Biology Mismatch',
        body:
            'Your alignment score is $alignmentScore/100 — you\'re working against your natural rhythm.',
        recommendation:
            'Try shifting your deep work sessions closer to your peak window (hour ${profile.peakHour}).',
      ));
    } else if (alignmentScore < 75) {
      insights.add(ChronotypeInsight(
        severity: InsightSeverity.medium,
        title: 'Room for Improvement',
        body:
            'Alignment score: $alignmentScore/100 — decent but not optimal.',
        recommendation:
            'Move 1-2 important tasks into your ${PeakWindow._formatHour(profile.peakHour)} peak window.',
      ));
    }

    // Peak window insights.
    for (final pw in peakWindows) {
      if (pw.confidenceScore > 0.5) {
        insights.add(ChronotypeInsight(
          severity: InsightSeverity.low,
          title: '${pw.taskType.emoji} Best time for ${pw.taskType.label}',
          body: 'Your data shows peak ${pw.taskType.label.toLowerCase()} performance during ${pw.timeRange}.',
          recommendation:
              'Schedule ${pw.taskType.label.toLowerCase()} tasks in this window when possible.',
        ));
      }
    }

    // Drift insights.
    if (driftType == DriftType.weekendShift) {
      insights.add(ChronotypeInsight(
        severity: InsightSeverity.medium,
        title: 'Social Jet Lag Detected',
        body:
            'Your weekend schedule differs significantly from weekdays, causing social jet lag.',
        recommendation:
            'Try to keep wake times within 1 hour of weekday schedule on weekends.',
      ));
    } else if (driftType == DriftType.scheduleCreep) {
      insights.add(ChronotypeInsight(
        severity: InsightSeverity.medium,
        title: 'Schedule Creep',
        body:
            'Your activity timing has been drifting gradually later over time.',
        recommendation:
            'Set a firm morning anchor activity to prevent continued drift.',
      ));
    } else if (driftType == DriftType.erratic) {
      insights.add(ChronotypeInsight(
        severity: InsightSeverity.high,
        title: 'Erratic Timing',
        body:
            'Your daily timing varies widely — this can impair sleep quality and cognitive performance.',
        recommendation:
            'Establish consistent wake and sleep times as top priority.',
      ));
    }

    // Variability insight.
    if (profile.timingVariability > 4.0) {
      insights.add(ChronotypeInsight(
        severity: InsightSeverity.high,
        title: 'High Timing Variability',
        body:
            'Activity start times vary by ±${profile.timingVariability.toStringAsFixed(1)} hours — this fragments circadian rhythm.',
        recommendation:
            'Anchor 2-3 daily activities at fixed times to stabilize your rhythm.',
      ));
    }

    // Trough avoidance insight.
    insights.add(ChronotypeInsight(
      severity: InsightSeverity.low,
      title: 'Avoid the Trough',
      body:
          'Your lowest energy is around ${PeakWindow._formatHour(profile.troughHour)} — not ideal for demanding tasks.',
      recommendation:
          'Reserve ${PeakWindow._formatHour(profile.troughHour)} for routine tasks, breaks, or physical activity.',
    ));

    // Sort by severity (high first).
    insights.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return insights;
  }

  // ── Empty report ────────────────────────────────────────────────────────

  ChronotypeReport _emptyReport() {
    return ChronotypeReport(
      chronotype: Chronotype.dolphin,
      profile: CircadianProfile(
        hourlyEnergy: List<double>.filled(24, 0.0),
        peakHour: 12,
        troughHour: 3,
        timingVariability: 0,
      ),
      peakWindows: [],
      alignmentScore: 0,
      alignmentGrade: AlignmentGrade.chaotic,
      currentDrift: DriftType.stable,
      driftEvents: [],
      weeklyCentroids: [],
      insights: [
        ChronotypeInsight(
          severity: InsightSeverity.low,
          title: 'No Data Yet',
          body: 'Start logging activities to discover your chronotype.',
          recommendation: 'Log at least 7 days of activities for meaningful analysis.',
        ),
      ],
      totalActivities: 0,
    );
  }
}
