/// Routine models — data types for the Daily Routine Builder.
///
/// Extracted from `routine_builder_service.dart` so that models can be
/// imported independently (e.g., in views, tests, serialization layers)
/// without pulling in the service logic.

/// Time-of-day slot for scheduling routines.
enum TimeSlot {
  earlyMorning, // 5-7 AM
  morning, // 7-9 AM
  midMorning, // 9-11 AM
  afternoon, // 12-3 PM
  evening, // 5-8 PM
  night; // 8-11 PM

  String get label {
    switch (this) {
      case TimeSlot.earlyMorning:
        return 'Early Morning (5-7 AM)';
      case TimeSlot.morning:
        return 'Morning (7-9 AM)';
      case TimeSlot.midMorning:
        return 'Mid-Morning (9-11 AM)';
      case TimeSlot.afternoon:
        return 'Afternoon (12-3 PM)';
      case TimeSlot.evening:
        return 'Evening (5-8 PM)';
      case TimeSlot.night:
        return 'Night (8-11 PM)';
    }
  }
}

/// A single step within a routine.
class RoutineStep {
  final String id;
  final String name;
  final String? description;
  final int durationMinutes;
  final String? emoji;
  final bool isOptional;
  final int order;

  const RoutineStep({
    required this.id,
    required this.name,
    this.description,
    this.durationMinutes = 5,
    this.emoji,
    this.isOptional = false,
    this.order = 0,
  });

  RoutineStep copyWith({
    String? name,
    String? description,
    int? durationMinutes,
    String? emoji,
    bool? isOptional,
    int? order,
  }) {
    return RoutineStep(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      emoji: emoji ?? this.emoji,
      isOptional: isOptional ?? this.isOptional,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'durationMinutes': durationMinutes,
        'emoji': emoji,
        'isOptional': isOptional,
        'order': order,
      };

  factory RoutineStep.fromJson(Map<String, dynamic> json) => RoutineStep(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        durationMinutes: json['durationMinutes'] as int? ?? 5,
        emoji: json['emoji'] as String?,
        isOptional: json['isOptional'] as bool? ?? false,
        order: json['order'] as int? ?? 0,
      );
}

/// A routine definition — an ordered collection of steps with scheduling.
class Routine {
  final String id;
  final String name;
  final String? description;
  final String? emoji;
  final List<RoutineStep> steps;
  final List<int> activeDays;
  final TimeSlot timeSlot;
  final DateTime createdAt;
  final bool isActive;

  const Routine({
    required this.id,
    required this.name,
    this.description,
    this.emoji,
    this.steps = const [],
    this.activeDays = const [],
    this.timeSlot = TimeSlot.morning,
    required this.createdAt,
    this.isActive = true,
  });

  int get totalDurationMinutes =>
      steps.fold(0, (sum, step) => sum + step.durationMinutes);

  int get requiredStepCount => steps.where((s) => !s.isOptional).length;

  bool isScheduledFor(int weekday) {
    if (activeDays.isEmpty) return true;
    return activeDays.contains(weekday);
  }

  Routine copyWith({
    String? name,
    String? description,
    String? emoji,
    List<RoutineStep>? steps,
    List<int>? activeDays,
    TimeSlot? timeSlot,
    bool? isActive,
  }) {
    return Routine(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      steps: steps ?? this.steps,
      activeDays: activeDays ?? this.activeDays,
      timeSlot: timeSlot ?? this.timeSlot,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'emoji': emoji,
        'steps': steps.map((s) => s.toJson()).toList(),
        'activeDays': activeDays,
        'timeSlot': timeSlot.name,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
      };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        emoji: json['emoji'] as String?,
        steps: (json['steps'] as List<dynamic>?)
                ?.map((s) => RoutineStep.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        activeDays: (json['activeDays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
        timeSlot: TimeSlot.values.firstWhere(
          (t) => t.name == json['timeSlot'],
          orElse: () => TimeSlot.morning,
        ),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        isActive: json['isActive'] as bool? ?? true,
      );
}

/// Completion status of a single step within a routine run.
enum StepStatus { pending, completed, skipped }

/// Records the completion of a single step during a routine run.
class StepCompletion {
  final String stepId;
  final StepStatus status;
  final DateTime? completedAt;
  final String? note;
  final int? actualMinutes;

  const StepCompletion({
    required this.stepId,
    this.status = StepStatus.pending,
    this.completedAt,
    this.note,
    this.actualMinutes,
  });

  StepCompletion copyWith({
    StepStatus? status,
    DateTime? completedAt,
    String? note,
    int? actualMinutes,
  }) {
    return StepCompletion(
      stepId: stepId,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
      actualMinutes: actualMinutes ?? this.actualMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'stepId': stepId,
        'status': status.name,
        'completedAt': completedAt?.toIso8601String(),
        'note': note,
        'actualMinutes': actualMinutes,
      };

  factory StepCompletion.fromJson(Map<String, dynamic> json) => StepCompletion(
        stepId: json['stepId'] as String,
        status: StepStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => StepStatus.pending,
        ),
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
        note: json['note'] as String?,
        actualMinutes: json['actualMinutes'] as int?,
      );
}

/// A single execution of a routine on a specific date.
class RoutineRun {
  final String routineId;
  final DateTime date;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final List<StepCompletion> stepCompletions;

  const RoutineRun({
    required this.routineId,
    required this.date,
    this.startedAt,
    this.finishedAt,
    this.stepCompletions = const [],
  });

  bool get isFinished => finishedAt != null;

  int get completedCount =>
      stepCompletions.where((s) => s.status == StepStatus.completed).length;

  int get skippedCount =>
      stepCompletions.where((s) => s.status == StepStatus.skipped).length;

  int get pendingCount =>
      stepCompletions.where((s) => s.status == StepStatus.pending).length;

  double get completionRatio {
    final applicable =
        stepCompletions.where((s) => s.status != StepStatus.skipped).length;
    if (applicable == 0) return 0.0;
    return completedCount / applicable;
  }

  int get actualDurationMinutes => stepCompletions
      .where((s) => s.status == StepStatus.completed && s.actualMinutes != null)
      .fold(0, (sum, s) => sum + s.actualMinutes!);

  RoutineRun copyWith({
    DateTime? startedAt,
    DateTime? finishedAt,
    List<StepCompletion>? stepCompletions,
  }) {
    return RoutineRun(
      routineId: routineId,
      date: date,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      stepCompletions: stepCompletions ?? this.stepCompletions,
    );
  }

  Map<String, dynamic> toJson() => {
        'routineId': routineId,
        'date': date.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'stepCompletions': stepCompletions.map((s) => s.toJson()).toList(),
      };

  factory RoutineRun.fromJson(Map<String, dynamic> json) => RoutineRun(
        routineId: json['routineId'] as String,
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        startedAt: json['startedAt'] != null
            ? DateTime.tryParse(json['startedAt'] as String)
            : null,
        finishedAt: json['finishedAt'] != null
            ? DateTime.tryParse(json['finishedAt'] as String)
            : null,
        stepCompletions: (json['stepCompletions'] as List<dynamic>?)
                ?.map((s) => StepCompletion.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

/// Analytics summary for a routine over a period.
class RoutineAnalytics {
  final String routineId;
  final String routineName;
  final int totalRuns;
  final int fullyCompletedRuns;
  final double completionRate;
  final double averageDurationMinutes;
  final int currentStreak;
  final int longestStreak;
  final Map<String, double> stepCompletionRates;
  final Map<String, double> stepAvgDurations;
  final String? mostSkippedStep;
  final String? slowestStep;

  const RoutineAnalytics({
    required this.routineId,
    required this.routineName,
    this.totalRuns = 0,
    this.fullyCompletedRuns = 0,
    this.completionRate = 0.0,
    this.averageDurationMinutes = 0.0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.stepCompletionRates = const {},
    this.stepAvgDurations = const {},
    this.mostSkippedStep,
    this.slowestStep,
  });
}
