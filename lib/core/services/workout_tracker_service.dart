import 'dart:convert';
import 'dart:math';
import '../../models/workout_entry.dart';

/// Configuration for workout tracking.
class WorkoutConfig {
  /// Weekly workout frequency goal.
  final int weeklyGoal;
  /// Default rest time between sets in seconds.
  final int defaultRestSeconds;
  /// Whether to track estimated calories.
  final bool trackCalories;
  /// Body weight in kg (used for bodyweight exercise volume).
  final double bodyWeightKg;

  const WorkoutConfig({
    this.weeklyGoal = 4,
    this.defaultRestSeconds = 90,
    this.trackCalories = true,
    this.bodyWeightKg = 75,
  });

  Map<String, dynamic> toJson() => {
        'weeklyGoal': weeklyGoal,
        'defaultRestSeconds': defaultRestSeconds,
        'trackCalories': trackCalories,
        'bodyWeightKg': bodyWeightKg,
      };

  factory WorkoutConfig.fromJson(Map<String, dynamic> json) {
    return WorkoutConfig(
      weeklyGoal: json['weeklyGoal'] as int? ?? 4,
      defaultRestSeconds: json['defaultRestSeconds'] as int? ?? 90,
      trackCalories: json['trackCalories'] as bool? ?? true,
      bodyWeightKg: (json['bodyWeightKg'] as num?)?.toDouble() ?? 75,
    );
  }
}

/// Personal record for an exercise.
class PersonalRecord {
  final String exerciseName;
  final double maxWeight;
  final int maxReps;
  final double maxVolume;
  final DateTime achievedAt;

  const PersonalRecord({
    required this.exerciseName,
    required this.maxWeight,
    required this.maxReps,
    required this.maxVolume,
    required this.achievedAt,
  });
}

/// Weekly workout summary.
class WeeklySummary {
  final DateTime weekStart;
  final int workoutCount;
  final double totalVolume;
  final int totalSets;
  final int totalReps;
  final int totalMinutes;
  final int weeklyGoal;
  final Map<MuscleGroup, int> muscleGroupFrequency;
  final double avgRpe;

  const WeeklySummary({
    required this.weekStart,
    required this.workoutCount,
    required this.totalVolume,
    required this.totalSets,
    required this.totalReps,
    required this.totalMinutes,
    required this.weeklyGoal,
    required this.muscleGroupFrequency,
    required this.avgRpe,
  });

  double get goalProgress =>
      weeklyGoal > 0 ? (workoutCount / weeklyGoal * 100).clamp(0, 200) : 0;
  bool get goalMet => workoutCount >= weeklyGoal;

  String get grade {
    final pct = goalProgress;
    if (pct >= 100) return 'A';
    if (pct >= 75) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 25) return 'D';
    return 'F';
  }
}

/// Muscle group balance analysis.
class MuscleBalance {
  final Map<MuscleGroup, double> volumeByGroup;
  final Map<MuscleGroup, int> frequencyByGroup;
  final List<MuscleGroup> neglectedGroups;
  final List<MuscleGroup> overtrainedGroups;
  final double upperLowerRatio;
  final double pushPullRatio;

  const MuscleBalance({
    required this.volumeByGroup,
    required this.frequencyByGroup,
    required this.neglectedGroups,
    required this.overtrainedGroups,
    required this.upperLowerRatio,
    required this.pushPullRatio,
  });
}

/// Volume trend data point.
class VolumeTrend {
  final DateTime date;
  final double volume;
  final int sets;
  final int reps;

  const VolumeTrend({
    required this.date,
    required this.volume,
    required this.sets,
    required this.reps,
  });
}

/// Workout streak information.
class WorkoutStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastWorkoutDate;
  final int totalWorkouts;
  final int totalDaysTracked;

  const WorkoutStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastWorkoutDate,
    required this.totalWorkouts,
    required this.totalDaysTracked,
  });

  double get consistency =>
      totalDaysTracked > 0 ? totalWorkouts / totalDaysTracked * 100 : 0;
}

/// Comprehensive workout report.
class WorkoutReport {
  final int totalWorkouts;
  final double totalVolume;
  final int totalSets;
  final int totalReps;
  final int totalMinutes;
  final double avgWorkoutMinutes;
  final double avgVolume;
  final double avgRpe;
  final WorkoutStreak streak;
  final List<PersonalRecord> personalRecords;
  final MuscleBalance muscleBalance;
  final List<VolumeTrend> volumeTrend;
  final Map<String, int> exerciseFrequency;
  final List<String> tips;

  const WorkoutReport({
    required this.totalWorkouts,
    required this.totalVolume,
    required this.totalSets,
    required this.totalReps,
    required this.totalMinutes,
    required this.avgWorkoutMinutes,
    required this.avgVolume,
    required this.avgRpe,
    required this.streak,
    required this.personalRecords,
    required this.muscleBalance,
    required this.volumeTrend,
    required this.exerciseFrequency,
    required this.tips,
  });

  String toTextSummary() {
    final buf = StringBuffer();
    buf.writeln('=== Workout Report ===');
    buf.writeln('Total workouts: $totalWorkouts');
    buf.writeln('Total volume: ${totalVolume.toStringAsFixed(0)} kg');
    buf.writeln('Total sets: $totalSets | Total reps: $totalReps');
    buf.writeln('Total time: $totalMinutes min');
    buf.writeln('Avg workout: ${avgWorkoutMinutes.toStringAsFixed(0)} min, '
        '${avgVolume.toStringAsFixed(0)} kg volume');
    if (avgRpe > 0) buf.writeln('Avg RPE: ${avgRpe.toStringAsFixed(1)}/10');
    buf.writeln('');
    buf.writeln('--- Streak ---');
    buf.writeln('Current: ${streak.currentStreak} weeks');
    buf.writeln('Longest: ${streak.longestStreak} weeks');
    buf.writeln('Consistency: ${streak.consistency.toStringAsFixed(1)}%');
    buf.writeln('');
    if (personalRecords.isNotEmpty) {
      buf.writeln('--- Personal Records ---');
      for (final pr in personalRecords) {
        buf.writeln('${pr.exerciseName}: ${pr.maxWeight} kg x ${pr.maxReps} reps');
      }
      buf.writeln('');
    }
    if (muscleBalance.neglectedGroups.isNotEmpty) {
      buf.writeln('--- Neglected Muscles ---');
      for (final g in muscleBalance.neglectedGroups) {
        buf.writeln('${g.emoji} ${g.label}');
      }
      buf.writeln('');
    }
    if (tips.isNotEmpty) {
      buf.writeln('--- Tips ---');
      for (final tip in tips) {
        buf.writeln('- $tip');
      }
    }
    return buf.toString();
  }
}

/// Workout tracker service with logging, analytics, streaks, and PRs.
class WorkoutTrackerService {
  final List<WorkoutEntry> _workouts;
  final WorkoutConfig config;

  WorkoutTrackerService({
    List<WorkoutEntry>? workouts,
    this.config = const WorkoutConfig(),
  }) : _workouts = workouts != null ? List.of(workouts) : [];

  List<WorkoutEntry> get workouts => List.unmodifiable(_workouts);

  // ── CRUD ──

  void addWorkout(WorkoutEntry workout) {
    _workouts.add(workout);
    _workouts.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  bool removeWorkout(String id) {
    final idx = _workouts.indexWhere((w) => w.id == id);
    if (idx == -1) return false;
    _workouts.removeAt(idx);
    return true;
  }

  WorkoutEntry? getWorkout(String id) {
    for (final w in _workouts) {
      if (w.id == id) return w;
    }
    return null;
  }

  void updateWorkout(WorkoutEntry updated) {
    final idx = _workouts.indexWhere((w) => w.id == updated.id);
    if (idx != -1) {
      _workouts[idx] = updated;
      _workouts.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
  }

  // ── Filtering ──

  List<WorkoutEntry> getWorkoutsForDate(DateTime date) {
    return _workouts.where((w) =>
        w.startTime.year == date.year &&
        w.startTime.month == date.month &&
        w.startTime.day == date.day).toList();
  }

  List<WorkoutEntry> getWorkoutsInRange(DateTime start, DateTime end) {
    return _workouts.where((w) =>
        !w.startTime.isBefore(start) && !w.startTime.isAfter(end)).toList();
  }

  List<WorkoutEntry> getWorkoutsByMuscleGroup(MuscleGroup group) {
    return _workouts.where((w) =>
        w.exercises.any((e) => e.muscleGroups.contains(group))).toList();
  }

  // ── Personal Records ──

  List<PersonalRecord> getPersonalRecords() {
    final Map<String, PersonalRecord> prs = {};

    for (final workout in _workouts) {
      for (final exercise in workout.exercises) {
        final name = exercise.name.toLowerCase();
        final existing = prs[name];

        final maxW = exercise.maxWeight;
        final maxR = exercise.totalReps;
        final maxV = exercise.totalVolume;

        if (existing == null ||
            maxW > existing.maxWeight ||
            maxV > existing.maxVolume) {
          prs[name] = PersonalRecord(
            exerciseName: exercise.name,
            maxWeight: maxW > (existing?.maxWeight ?? 0) ? maxW : existing!.maxWeight,
            maxReps: maxR > (existing?.maxReps ?? 0) ? maxR : existing!.maxReps,
            maxVolume: maxV > (existing?.maxVolume ?? 0) ? maxV : existing!.maxVolume,
            achievedAt: workout.startTime,
          );
        }
      }
    }

    return prs.values.toList()
      ..sort((a, b) => b.maxVolume.compareTo(a.maxVolume));
  }

  /// Check if a workout contains any new personal records.
  List<PersonalRecord> checkForNewPRs(WorkoutEntry workout) {
    final prs = <PersonalRecord>[];
    final existingPRs = getPersonalRecords();
    final existingMap = {
      for (final pr in existingPRs) pr.exerciseName.toLowerCase(): pr
    };

    for (final exercise in workout.exercises) {
      final name = exercise.name.toLowerCase();
      final existing = existingMap[name];

      if (existing == null) {
        prs.add(PersonalRecord(
          exerciseName: exercise.name,
          maxWeight: exercise.maxWeight,
          maxReps: exercise.totalReps,
          maxVolume: exercise.totalVolume,
          achievedAt: workout.startTime,
        ));
      } else {
        if (exercise.maxWeight > existing.maxWeight ||
            exercise.totalVolume > existing.maxVolume) {
          prs.add(PersonalRecord(
            exerciseName: exercise.name,
            maxWeight: exercise.maxWeight > existing.maxWeight
                ? exercise.maxWeight : existing.maxWeight,
            maxReps: exercise.totalReps > existing.maxReps
                ? exercise.totalReps : existing.maxReps,
            maxVolume: exercise.totalVolume > existing.maxVolume
                ? exercise.totalVolume : existing.maxVolume,
            achievedAt: workout.startTime,
          ));
        }
      }
    }

    return prs;
  }

  // ── Weekly Summary ──

  WeeklySummary getWeeklySummary(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekWorkouts = getWorkoutsInRange(weekStart, weekEnd);

    final muscleFreq = <MuscleGroup, int>{};
    double rpeSum = 0;
    int rpeCount = 0;
    int totalMinutes = 0;

    for (final w in weekWorkouts) {
      for (final mg in w.muscleGroupsWorked) {
        muscleFreq[mg] = (muscleFreq[mg] ?? 0) + 1;
      }
      if (w.rpeScore != null) {
        rpeSum += w.rpeScore!;
        rpeCount++;
      }
      totalMinutes += w.durationMinutes ?? 0;
    }

    return WeeklySummary(
      weekStart: weekStart,
      workoutCount: weekWorkouts.length,
      totalVolume: weekWorkouts.fold(0.0, (sum, w) => sum + w.totalVolume),
      totalSets: weekWorkouts.fold(0, (sum, w) => sum + w.totalSets),
      totalReps: weekWorkouts.fold(0, (sum, w) => sum + w.totalReps),
      totalMinutes: totalMinutes,
      weeklyGoal: config.weeklyGoal,
      muscleGroupFrequency: muscleFreq,
      avgRpe: rpeCount > 0 ? rpeSum / rpeCount : 0,
    );
  }

  // ── Muscle Balance ──

  MuscleBalance analyzeMuscleBalance({int lastNWorkouts = 20}) {
    final recent = _workouts.length <= lastNWorkouts
        ? _workouts
        : _workouts.sublist(_workouts.length - lastNWorkouts);

    final volumeByGroup = <MuscleGroup, double>{};
    final freqByGroup = <MuscleGroup, int>{};

    for (final workout in recent) {
      for (final exercise in workout.exercises) {
        for (final mg in exercise.muscleGroups) {
          volumeByGroup[mg] = (volumeByGroup[mg] ?? 0) + exercise.totalVolume;
          freqByGroup[mg] = (freqByGroup[mg] ?? 0) + 1;
        }
      }
    }

    // Determine neglected and overtrained groups
    final allTrainable = MuscleGroup.values
        .where((g) => g != MuscleGroup.fullBody && g != MuscleGroup.cardio)
        .toList();

    double avgFreq = 0;
    if (freqByGroup.isNotEmpty) {
      avgFreq = freqByGroup.values.fold(0, (sum, v) => sum + v) /
          freqByGroup.length;
    }

    final neglected = <MuscleGroup>[];
    final overtrained = <MuscleGroup>[];

    for (final mg in allTrainable) {
      final freq = freqByGroup[mg] ?? 0;
      if (freq == 0 || (avgFreq > 0 && freq < avgFreq * 0.3)) {
        neglected.add(mg);
      } else if (avgFreq > 0 && freq > avgFreq * 2.0) {
        overtrained.add(mg);
      }
    }

    // Upper/lower ratio
    double upperVol = 0, lowerVol = 0;
    for (final mg in volumeByGroup.keys) {
      if (mg.isUpperBody) upperVol += volumeByGroup[mg]!;
      if (mg.isLowerBody) lowerVol += volumeByGroup[mg]!;
    }
    final upperLowerRatio = lowerVol > 0 ? upperVol / lowerVol : 0.0;

    // Push/pull ratio (simplified: chest+shoulders+triceps vs back+biceps)
    final pushGroups = [MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.triceps];
    final pullGroups = [MuscleGroup.back, MuscleGroup.biceps];
    double pushVol = 0, pullVol = 0;
    for (final mg in pushGroups) {
      pushVol += volumeByGroup[mg] ?? 0;
    }
    for (final mg in pullGroups) {
      pullVol += volumeByGroup[mg] ?? 0;
    }
    final pushPullRatio = pullVol > 0 ? pushVol / pullVol : 0.0;

    return MuscleBalance(
      volumeByGroup: volumeByGroup,
      frequencyByGroup: freqByGroup,
      neglectedGroups: neglected,
      overtrainedGroups: overtrained,
      upperLowerRatio: upperLowerRatio,
      pushPullRatio: pushPullRatio,
    );
  }

  // ── Volume Trends ──

  List<VolumeTrend> getVolumeTrend({int lastNDays = 30}) {
    if (_workouts.isEmpty) return [];

    final now = _workouts.last.startTime;
    final cutoff = now.subtract(Duration(days: lastNDays));
    final recent = _workouts.where((w) => w.startTime.isAfter(cutoff)).toList();

    // Group by date
    final Map<String, List<WorkoutEntry>> byDate = {};
    for (final w in recent) {
      final key = '${w.startTime.year}-${w.startTime.month}-${w.startTime.day}';
      byDate.putIfAbsent(key, () => []).add(w);
    }

    final trends = <VolumeTrend>[];
    for (final entry in byDate.entries) {
      final ws = entry.value;
      final date = ws.first.startTime;
      trends.add(VolumeTrend(
        date: DateTime(date.year, date.month, date.day),
        volume: ws.fold(0.0, (sum, w) => sum + w.totalVolume),
        sets: ws.fold(0, (sum, w) => sum + w.totalSets),
        reps: ws.fold(0, (sum, w) => sum + w.totalReps),
      ));
    }

    trends.sort((a, b) => a.date.compareTo(b.date));
    return trends;
  }

  // ── Streaks ──

  WorkoutStreak getStreak() {
    if (_workouts.isEmpty) {
      return const WorkoutStreak(
        currentStreak: 0,
        longestStreak: 0,
        totalWorkouts: 0,
        totalDaysTracked: 0,
      );
    }

    // Calculate weekly streaks (did user work out at least once this week?)
    final Set<String> workoutWeeks = {};
    for (final w in _workouts) {
      // ISO week key
      final monday = w.startTime.subtract(
          Duration(days: w.startTime.weekday - 1));
      workoutWeeks.add('${monday.year}-${monday.month}-${monday.day}');
    }

    final sortedWeeks = workoutWeeks.toList()..sort();

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 1;

    for (int i = 1; i < sortedWeeks.length; i++) {
      final prev = _parseWeekKey(sortedWeeks[i - 1]);
      final curr = _parseWeekKey(sortedWeeks[i]);
      final diff = curr.difference(prev).inDays;

      if (diff == 7) {
        tempStreak++;
      } else {
        if (tempStreak > longestStreak) longestStreak = tempStreak;
        tempStreak = 1;
      }
    }
    if (tempStreak > longestStreak) longestStreak = tempStreak;

    // Current streak: count consecutive weeks ending with most recent
    currentStreak = 1;
    for (int i = sortedWeeks.length - 1; i > 0; i--) {
      final prev = _parseWeekKey(sortedWeeks[i - 1]);
      final curr = _parseWeekKey(sortedWeeks[i]);
      if (curr.difference(prev).inDays == 7) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Total unique days
    final uniqueDays = <String>{};
    for (final w in _workouts) {
      uniqueDays.add('${w.startTime.year}-${w.startTime.month}-${w.startTime.day}');
    }

    final daySpan = _workouts.last.startTime
        .difference(_workouts.first.startTime)
        .inDays + 1;

    return WorkoutStreak(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastWorkoutDate: _workouts.last.startTime,
      totalWorkouts: _workouts.length,
      totalDaysTracked: daySpan,
    );
  }

  DateTime _parseWeekKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  // ── Exercise Frequency ──

  Map<String, int> getExerciseFrequency() {
    final freq = <String, int>{};
    for (final w in _workouts) {
      for (final e in w.exercises) {
        freq[e.name] = (freq[e.name] ?? 0) + 1;
      }
    }
    return freq;
  }

  /// Top N most performed exercises.
  List<MapEntry<String, int>> getTopExercises({int n = 10}) {
    final freq = getExerciseFrequency();
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }

  // ── Tips ──

  List<String> generateTips() {
    final tips = <String>[];

    if (_workouts.isEmpty) {
      tips.add('Start logging your workouts to get personalized tips!');
      return tips;
    }

    final balance = analyzeMuscleBalance();
    final streak = getStreak();

    if (balance.neglectedGroups.isNotEmpty) {
      final names = balance.neglectedGroups.take(3).map((g) => g.label).join(', ');
      tips.add('Consider adding exercises for: $names');
    }

    if (balance.upperLowerRatio > 2.0) {
      tips.add('Your upper/lower volume ratio is ${balance.upperLowerRatio.toStringAsFixed(1)}:1. '
          'Add more leg exercises for balance.');
    }

    if (balance.pushPullRatio > 1.5) {
      tips.add('Push volume exceeds pull by ${balance.pushPullRatio.toStringAsFixed(1)}x. '
          'Add more rows and pull-ups to balance.');
    } else if (balance.pushPullRatio > 0 && balance.pushPullRatio < 0.7) {
      tips.add('Pull volume exceeds push. Consider adding more pressing movements.');
    }

    if (streak.currentStreak >= 4) {
      tips.add('Great consistency! ${streak.currentStreak}-week streak going strong.');
    } else if (streak.currentStreak == 0 && _workouts.isNotEmpty) {
      tips.add('You missed last week. Get back on track!');
    }

    final avgDuration = _workouts
        .where((w) => w.durationMinutes != null)
        .map((w) => w.durationMinutes!)
        .fold<int>(0, (sum, d) => sum + d);
    final durationCount = _workouts.where((w) => w.durationMinutes != null).length;
    if (durationCount > 0) {
      final avg = avgDuration / durationCount;
      if (avg > 90) {
        tips.add('Average workout is ${avg.toStringAsFixed(0)} min. '
            'Consider keeping sessions under 75 min for optimal recovery.');
      } else if (avg < 30) {
        tips.add('Average workout is only ${avg.toStringAsFixed(0)} min. '
            'Try adding a few more exercises for better results.');
      }
    }

    return tips;
  }

  // ── Full Report ──

  WorkoutReport generateReport() {
    final totalMinutes = _workouts
        .where((w) => w.durationMinutes != null)
        .fold<int>(0, (sum, w) => sum + w.durationMinutes!);
    final durationCount =
        _workouts.where((w) => w.durationMinutes != null).length;
    final rpeSum = _workouts
        .where((w) => w.rpeScore != null)
        .fold<int>(0, (sum, w) => sum + w.rpeScore!);
    final rpeCount = _workouts.where((w) => w.rpeScore != null).length;

    return WorkoutReport(
      totalWorkouts: _workouts.length,
      totalVolume: _workouts.fold(0.0, (sum, w) => sum + w.totalVolume),
      totalSets: _workouts.fold(0, (sum, w) => sum + w.totalSets),
      totalReps: _workouts.fold(0, (sum, w) => sum + w.totalReps),
      totalMinutes: totalMinutes,
      avgWorkoutMinutes:
          durationCount > 0 ? totalMinutes / durationCount : 0,
      avgVolume: _workouts.isNotEmpty
          ? _workouts.fold(0.0, (sum, w) => sum + w.totalVolume) /
              _workouts.length
          : 0,
      avgRpe: rpeCount > 0 ? rpeSum / rpeCount : 0,
      streak: getStreak(),
      personalRecords: getPersonalRecords(),
      muscleBalance: analyzeMuscleBalance(),
      volumeTrend: getVolumeTrend(),
      exerciseFrequency: getExerciseFrequency(),
      tips: generateTips(),
    );
  }

  // ── Serialization ──

  String toJson() {
    return jsonEncode({
      'config': config.toJson(),
      'workouts': _workouts.map((w) => w.toJson()).toList(),
    });
  }

  /// Maximum workout entries allowed via [fromJson].
  static const int maxImportEntries = 100000;

  factory WorkoutTrackerService.fromJson(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final workoutList = data['workouts'] as List<dynamic>? ?? [];
    if (workoutList.length > maxImportEntries) {
      throw ArgumentError(
        'Import exceeds maximum of $maxImportEntries entries '
        '(got ${workoutList.length}). This limit prevents memory '
        'exhaustion from corrupted or malicious data.',
      );
    }
    return WorkoutTrackerService(
      config: data['config'] != null
          ? WorkoutConfig.fromJson(data['config'] as Map<String, dynamic>)
          : const WorkoutConfig(),
      workouts: workoutList
              .map((w) => WorkoutEntry.fromJson(w as Map<String, dynamic>))
              .toList(),
    );
  }
}
