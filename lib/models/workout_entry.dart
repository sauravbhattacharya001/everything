import 'dart:convert';

/// Muscle groups targeted by exercises.
enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  core,
  quads,
  hamstrings,
  glutes,
  calves,
  fullBody,
  cardio;

  String get label {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.forearms:
        return 'Forearms';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.quads:
        return 'Quads';
      case MuscleGroup.hamstrings:
        return 'Hamstrings';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.calves:
        return 'Calves';
      case MuscleGroup.fullBody:
        return 'Full Body';
      case MuscleGroup.cardio:
        return 'Cardio';
    }
  }

  String get emoji {
    switch (this) {
      case MuscleGroup.chest:
        return '\u{1FAC1}';
      case MuscleGroup.back:
        return '\u{1F519}';
      case MuscleGroup.shoulders:
        return '\u{1F937}';
      case MuscleGroup.biceps:
        return '\u{1F4AA}';
      case MuscleGroup.triceps:
        return '\u{1F9BE}';
      case MuscleGroup.forearms:
        return '\u{1F91D}';
      case MuscleGroup.core:
        return '\u{1F3AF}';
      case MuscleGroup.quads:
        return '\u{1F9B5}';
      case MuscleGroup.hamstrings:
        return '\u{1F3C3}';
      case MuscleGroup.glutes:
        return '\u{1F351}';
      case MuscleGroup.calves:
        return '\u{1F9B6}';
      case MuscleGroup.fullBody:
        return '\u{1F3CB}\uFE0F';
      case MuscleGroup.cardio:
        return '\u2764\uFE0F';
    }
  }

  /// Whether this is primarily an upper body muscle group.
  bool get isUpperBody =>
      this == chest ||
      this == back ||
      this == shoulders ||
      this == biceps ||
      this == triceps ||
      this == forearms;

  /// Whether this is primarily a lower body muscle group.
  bool get isLowerBody =>
      this == quads ||
      this == hamstrings ||
      this == glutes ||
      this == calves;
}

/// Type of exercise movement.
enum ExerciseType {
  strength,
  cardio,
  flexibility,
  bodyweight;

  String get label {
    switch (this) {
      case ExerciseType.strength:
        return 'Strength';
      case ExerciseType.cardio:
        return 'Cardio';
      case ExerciseType.flexibility:
        return 'Flexibility';
      case ExerciseType.bodyweight:
        return 'Bodyweight';
    }
  }
}

/// A single set within an exercise.
class ExerciseSet {
  final int reps;
  final double weightKg;
  final int? durationSeconds;
  final bool isWarmup;

  const ExerciseSet({
    this.reps = 0,
    this.weightKg = 0,
    this.durationSeconds,
    this.isWarmup = false,
  });

  /// Volume for this set (reps x weight).
  double get volume => reps * weightKg;

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'weightKg': weightKg,
        'durationSeconds': durationSeconds,
        'isWarmup': isWarmup,
      };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      reps: json['reps'] as int? ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      durationSeconds: json['durationSeconds'] as int?,
      isWarmup: json['isWarmup'] as bool? ?? false,
    );
  }
}

/// A single exercise entry within a workout.
class ExerciseEntry {
  final String name;
  final ExerciseType type;
  final List<MuscleGroup> muscleGroups;
  final List<ExerciseSet> sets;
  final String? note;

  const ExerciseEntry({
    required this.name,
    this.type = ExerciseType.strength,
    this.muscleGroups = const [],
    this.sets = const [],
    this.note,
  });

  /// Total volume across all working (non-warmup) sets.
  double get totalVolume =>
      sets.where((s) => !s.isWarmup).fold(0.0, (sum, s) => sum + s.volume);

  /// Total reps across all working sets.
  int get totalReps =>
      sets.where((s) => !s.isWarmup).fold(0, (sum, s) => sum + s.reps);

  /// Max weight used in any set.
  double get maxWeight =>
      sets.isEmpty ? 0 : sets.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);

  /// Number of working (non-warmup) sets.
  int get workingSets => sets.where((s) => !s.isWarmup).length;

  /// Total duration in seconds (for timed exercises).
  int get totalDurationSeconds =>
      sets.fold(0, (sum, s) => sum + (s.durationSeconds ?? 0));

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        'muscleGroups': muscleGroups.map((m) => m.name).toList(),
        'sets': sets.map((s) => s.toJson()).toList(),
        'note': note,
      };

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) {
    return ExerciseEntry(
      name: json['name'] as String? ?? 'Unknown',
      type: ExerciseType.values.firstWhere(
        (v) => v.name == json['type'],
        orElse: () => ExerciseType.strength,
      ),
      muscleGroups: (json['muscleGroups'] as List<dynamic>?)
              ?.map((m) => MuscleGroup.values.firstWhere(
                    (v) => v.name == m,
                    orElse: () => MuscleGroup.fullBody,
                  ))
              .toList() ??
          [],
      sets: (json['sets'] as List<dynamic>?)
              ?.map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      note: json['note'] as String?,
    );
  }
}

/// A complete workout session.
class WorkoutEntry {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String? name;
  final List<ExerciseEntry> exercises;
  final String? note;
  final int? rpeScore; // Rate of Perceived Exertion (1-10)
  final int? caloriesEstimate;

  const WorkoutEntry({
    required this.id,
    required this.startTime,
    this.endTime,
    this.name,
    this.exercises = const [],
    this.note,
    this.rpeScore,
    this.caloriesEstimate,
  });

  /// Duration in minutes (null if no end time).
  int? get durationMinutes {
    if (endTime == null) return null;
    return endTime!.difference(startTime).inMinutes;
  }

  /// Total volume (kg x reps) across all exercises.
  double get totalVolume =>
      exercises.fold(0.0, (sum, e) => sum + e.totalVolume);

  /// Total working sets across all exercises.
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.workingSets);

  /// Total reps across all exercises.
  int get totalReps => exercises.fold(0, (sum, e) => sum + e.totalReps);

  /// All muscle groups targeted in this workout.
  Set<MuscleGroup> get muscleGroupsWorked =>
      exercises.expand((e) => e.muscleGroups).toSet();

  /// Number of distinct exercises.
  int get exerciseCount => exercises.length;

  WorkoutEntry copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    String? name,
    List<ExerciseEntry>? exercises,
    String? note,
    int? rpeScore,
    int? caloriesEstimate,
  }) {
    return WorkoutEntry(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      note: note ?? this.note,
      rpeScore: rpeScore ?? this.rpeScore,
      caloriesEstimate: caloriesEstimate ?? this.caloriesEstimate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'note': note,
        'rpeScore': rpeScore,
        'caloriesEstimate': caloriesEstimate,
      };

  factory WorkoutEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutEntry(
      id: json['id'] as String,
      startTime:
          DateTime.tryParse(json['startTime'] as String? ?? '') ?? DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)
          : null,
      name: json['name'] as String?,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => ExerciseEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      note: json['note'] as String?,
      rpeScore: json['rpeScore'] as int?,
      caloriesEstimate: json['caloriesEstimate'] as int?,
    );
  }

  static String encodeList(List<WorkoutEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<WorkoutEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => WorkoutEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
