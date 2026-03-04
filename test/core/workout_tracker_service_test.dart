import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/workout_entry.dart';
import 'package:everything/core/services/workout_tracker_service.dart';

// ── Test Helpers ──

WorkoutEntry _makeWorkout({
  String id = '1',
  DateTime? startTime,
  DateTime? endTime,
  String? name,
  List<ExerciseEntry> exercises = const [],
  int? rpeScore,
}) {
  return WorkoutEntry(
    id: id,
    startTime: startTime ?? DateTime(2026, 3, 1, 9, 0),
    endTime: endTime,
    name: name,
    exercises: exercises,
    rpeScore: rpeScore,
  );
}

ExerciseEntry _makeExercise({
  String name = 'Bench Press',
  ExerciseType type = ExerciseType.strength,
  List<MuscleGroup> groups = const [MuscleGroup.chest],
  List<ExerciseSet> sets = const [],
}) {
  return ExerciseEntry(
    name: name,
    type: type,
    muscleGroups: groups,
    sets: sets,
  );
}

ExerciseSet _set({int reps = 10, double weight = 60, bool warmup = false}) {
  return ExerciseSet(reps: reps, weightKg: weight, isWarmup: warmup);
}

void main() {
  // ═══════════════════════════════════════════════════
  // Model Tests
  // ═══════════════════════════════════════════════════

  group('MuscleGroup', () {
    test('all values have labels and emojis', () {
      for (final mg in MuscleGroup.values) {
        expect(mg.label.isNotEmpty, true);
        expect(mg.emoji.isNotEmpty, true);
      }
    });

    test('upper body classification', () {
      expect(MuscleGroup.chest.isUpperBody, true);
      expect(MuscleGroup.back.isUpperBody, true);
      expect(MuscleGroup.shoulders.isUpperBody, true);
      expect(MuscleGroup.biceps.isUpperBody, true);
      expect(MuscleGroup.triceps.isUpperBody, true);
      expect(MuscleGroup.forearms.isUpperBody, true);
      expect(MuscleGroup.quads.isUpperBody, false);
      expect(MuscleGroup.core.isUpperBody, false);
    });

    test('lower body classification', () {
      expect(MuscleGroup.quads.isLowerBody, true);
      expect(MuscleGroup.hamstrings.isLowerBody, true);
      expect(MuscleGroup.glutes.isLowerBody, true);
      expect(MuscleGroup.calves.isLowerBody, true);
      expect(MuscleGroup.chest.isLowerBody, false);
      expect(MuscleGroup.core.isLowerBody, false);
    });
  });

  group('ExerciseType', () {
    test('all values have labels', () {
      for (final t in ExerciseType.values) {
        expect(t.label.isNotEmpty, true);
      }
    });
  });

  group('ExerciseSet', () {
    test('volume is reps * weight', () {
      final s = _set(reps: 8, weight: 100);
      expect(s.volume, 800);
    });

    test('zero weight has zero volume', () {
      final s = _set(reps: 10, weight: 0);
      expect(s.volume, 0);
    });

    test('toJson/fromJson round-trips', () {
      final s = ExerciseSet(
        reps: 12,
        weightKg: 50,
        durationSeconds: 30,
        isWarmup: true,
      );
      final json = s.toJson();
      final restored = ExerciseSet.fromJson(json);
      expect(restored.reps, 12);
      expect(restored.weightKg, 50);
      expect(restored.durationSeconds, 30);
      expect(restored.isWarmup, true);
    });

    test('fromJson handles missing fields', () {
      final s = ExerciseSet.fromJson({});
      expect(s.reps, 0);
      expect(s.weightKg, 0);
      expect(s.durationSeconds, isNull);
      expect(s.isWarmup, false);
    });
  });

  group('ExerciseEntry', () {
    test('totalVolume excludes warmup sets', () {
      final e = _makeExercise(sets: [
        _set(reps: 10, weight: 40, warmup: true),
        _set(reps: 8, weight: 80),
        _set(reps: 8, weight: 80),
      ]);
      expect(e.totalVolume, 1280); // only 2 working sets
    });

    test('totalReps excludes warmup', () {
      final e = _makeExercise(sets: [
        _set(reps: 15, weight: 20, warmup: true),
        _set(reps: 10, weight: 60),
      ]);
      expect(e.totalReps, 10);
    });

    test('maxWeight across all sets', () {
      final e = _makeExercise(sets: [
        _set(reps: 10, weight: 60),
        _set(reps: 8, weight: 80),
        _set(reps: 5, weight: 100),
      ]);
      expect(e.maxWeight, 100);
    });

    test('workingSets counts non-warmup', () {
      final e = _makeExercise(sets: [
        _set(warmup: true),
        _set(),
        _set(),
        _set(),
      ]);
      expect(e.workingSets, 3);
    });

    test('totalDurationSeconds sums all sets', () {
      final e = ExerciseEntry(
        name: 'Plank',
        muscleGroups: [MuscleGroup.core],
        sets: [
          const ExerciseSet(durationSeconds: 60),
          const ExerciseSet(durationSeconds: 45),
        ],
      );
      expect(e.totalDurationSeconds, 105);
    });

    test('toJson/fromJson round-trips', () {
      final e = _makeExercise(
        name: 'Squat',
        type: ExerciseType.strength,
        groups: [MuscleGroup.quads, MuscleGroup.glutes],
        sets: [_set(reps: 5, weight: 120)],
      );
      final json = e.toJson();
      final restored = ExerciseEntry.fromJson(json);
      expect(restored.name, 'Squat');
      expect(restored.type, ExerciseType.strength);
      expect(restored.muscleGroups.length, 2);
      expect(restored.sets.length, 1);
    });
  });

  group('WorkoutEntry', () {
    test('durationMinutes computes from start/end', () {
      final w = _makeWorkout(
        startTime: DateTime(2026, 3, 1, 9, 0),
        endTime: DateTime(2026, 3, 1, 10, 15),
      );
      expect(w.durationMinutes, 75);
    });

    test('durationMinutes null when no end time', () {
      final w = _makeWorkout(endTime: null);
      expect(w.durationMinutes, isNull);
    });

    test('totalVolume sums across exercises', () {
      final w = _makeWorkout(exercises: [
        _makeExercise(sets: [_set(reps: 10, weight: 60)]),
        _makeExercise(sets: [_set(reps: 8, weight: 80)]),
      ]);
      expect(w.totalVolume, 1240); // 600 + 640
    });

    test('muscleGroupsWorked collects unique groups', () {
      final w = _makeWorkout(exercises: [
        _makeExercise(groups: [MuscleGroup.chest, MuscleGroup.triceps]),
        _makeExercise(groups: [MuscleGroup.chest, MuscleGroup.shoulders]),
      ]);
      expect(w.muscleGroupsWorked.length, 3);
      expect(w.muscleGroupsWorked.contains(MuscleGroup.chest), true);
    });

    test('copyWith preserves fields', () {
      final w = _makeWorkout(name: 'Push Day', rpeScore: 7);
      final copy = w.copyWith(name: 'Pull Day');
      expect(copy.name, 'Pull Day');
      expect(copy.rpeScore, 7);
      expect(copy.id, w.id);
    });

    test('toJson/fromJson round-trips', () {
      final w = WorkoutEntry(
        id: 'w1',
        startTime: DateTime(2026, 3, 1, 9, 0),
        endTime: DateTime(2026, 3, 1, 10, 0),
        name: 'Full Body',
        exercises: [
          _makeExercise(
            name: 'Deadlift',
            groups: [MuscleGroup.back, MuscleGroup.hamstrings],
            sets: [_set(reps: 5, weight: 140)],
          ),
        ],
        rpeScore: 8,
        caloriesEstimate: 350,
      );
      final json = w.toJson();
      final restored = WorkoutEntry.fromJson(json);
      expect(restored.id, 'w1');
      expect(restored.name, 'Full Body');
      expect(restored.exercises.length, 1);
      expect(restored.rpeScore, 8);
      expect(restored.caloriesEstimate, 350);
      expect(restored.durationMinutes, 60);
    });

    test('encodeList/decodeList round-trips', () {
      final list = [
        _makeWorkout(id: '1'),
        _makeWorkout(id: '2'),
      ];
      final encoded = WorkoutEntry.encodeList(list);
      final decoded = WorkoutEntry.decodeList(encoded);
      expect(decoded.length, 2);
      expect(decoded[0].id, '1');
      expect(decoded[1].id, '2');
    });
  });

  // ═══════════════════════════════════════════════════
  // Service Tests
  // ═══════════════════════════════════════════════════

  group('WorkoutTrackerService CRUD', () {
    test('adds and retrieves workout', () {
      final svc = WorkoutTrackerService();
      final w = _makeWorkout();
      svc.addWorkout(w);
      expect(svc.workouts.length, 1);
      expect(svc.getWorkout('1'), isNotNull);
    });

    test('removes workout by id', () {
      final svc = WorkoutTrackerService();
      svc.addWorkout(_makeWorkout(id: '1'));
      svc.addWorkout(_makeWorkout(id: '2'));
      expect(svc.removeWorkout('1'), true);
      expect(svc.workouts.length, 1);
      expect(svc.getWorkout('1'), isNull);
    });

    test('removeWorkout returns false for unknown id', () {
      final svc = WorkoutTrackerService();
      expect(svc.removeWorkout('nope'), false);
    });

    test('updateWorkout replaces existing', () {
      final svc = WorkoutTrackerService();
      svc.addWorkout(_makeWorkout(id: '1', name: 'Old'));
      svc.updateWorkout(_makeWorkout(id: '1', name: 'New'));
      expect(svc.getWorkout('1')!.name, 'New');
    });

    test('workouts are sorted by startTime', () {
      final svc = WorkoutTrackerService();
      svc.addWorkout(_makeWorkout(
          id: '2', startTime: DateTime(2026, 3, 5)));
      svc.addWorkout(_makeWorkout(
          id: '1', startTime: DateTime(2026, 3, 1)));
      expect(svc.workouts[0].id, '1');
      expect(svc.workouts[1].id, '2');
    });
  });

  group('WorkoutTrackerService filtering', () {
    late WorkoutTrackerService svc;

    setUp(() {
      svc = WorkoutTrackerService();
      svc.addWorkout(_makeWorkout(
        id: '1',
        startTime: DateTime(2026, 3, 1, 9, 0),
        exercises: [
          _makeExercise(groups: [MuscleGroup.chest]),
        ],
      ));
      svc.addWorkout(_makeWorkout(
        id: '2',
        startTime: DateTime(2026, 3, 1, 18, 0),
        exercises: [
          _makeExercise(groups: [MuscleGroup.back]),
        ],
      ));
      svc.addWorkout(_makeWorkout(
        id: '3',
        startTime: DateTime(2026, 3, 3, 9, 0),
        exercises: [
          _makeExercise(groups: [MuscleGroup.quads]),
        ],
      ));
    });

    test('getWorkoutsForDate returns same day', () {
      final results = svc.getWorkoutsForDate(DateTime(2026, 3, 1));
      expect(results.length, 2);
    });

    test('getWorkoutsForDate returns empty for no match', () {
      final results = svc.getWorkoutsForDate(DateTime(2026, 3, 2));
      expect(results.length, 0);
    });

    test('getWorkoutsInRange filters correctly', () {
      final results = svc.getWorkoutsInRange(
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 2),
      );
      expect(results.length, 2);
    });

    test('getWorkoutsByMuscleGroup filters correctly', () {
      final results = svc.getWorkoutsByMuscleGroup(MuscleGroup.chest);
      expect(results.length, 1);
      expect(results[0].id, '1');
    });
  });

  group('Personal Records', () {
    test('detects PRs across workouts', () {
      final svc = WorkoutTrackerService();
      svc.addWorkout(_makeWorkout(
        id: '1',
        startTime: DateTime(2026, 3, 1),
        exercises: [
          _makeExercise(
            name: 'Bench Press',
            sets: [_set(reps: 8, weight: 80)],
          ),
        ],
      ));
      svc.addWorkout(_makeWorkout(
        id: '2',
        startTime: DateTime(2026, 3, 3),
        exercises: [
          _makeExercise(
            name: 'Bench Press',
            sets: [_set(reps: 5, weight: 100)],
          ),
        ],
      ));

      final prs = svc.getPersonalRecords();
      expect(prs.length, 1);
      expect(prs[0].maxWeight, 100);
    });

    test('checkForNewPRs detects improvement', () {
      final svc = WorkoutTrackerService();
      svc.addWorkout(_makeWorkout(
        id: '1',
        exercises: [
          _makeExercise(sets: [_set(reps: 8, weight: 80)]),
        ],
      ));

      final newWorkout = _makeWorkout(
        id: '2',
        startTime: DateTime(2026, 3, 5),
        exercises: [
          _makeExercise(sets: [_set(reps: 5, weight: 100)]),
        ],
      );

      final newPRs = svc.checkForNewPRs(newWorkout);
      expect(newPRs.isNotEmpty, true);
      expect(newPRs[0].maxWeight, 100);
    });

    test('checkForNewPRs returns empty when no improvement', () {
      final svc = WorkoutTrackerService();
      svc.addWorkout(_makeWorkout(
        id: '1',
        exercises: [
          _makeExercise(sets: [_set(reps: 8, weight: 100)]),
        ],
      ));

      final newWorkout = _makeWorkout(
        id: '2',
        startTime: DateTime(2026, 3, 5),
        exercises: [
          _makeExercise(sets: [_set(reps: 6, weight: 80)]),
        ],
      );

      final newPRs = svc.checkForNewPRs(newWorkout);
      expect(newPRs.isEmpty, true);
    });

    test('first workout always counts as PR', () {
      final svc = WorkoutTrackerService();
      final w = _makeWorkout(
        exercises: [
          _makeExercise(
            name: 'Squat',
            sets: [_set(reps: 5, weight: 100)],
          ),
        ],
      );
      final prs = svc.checkForNewPRs(w);
      expect(prs.length, 1);
      expect(prs[0].exerciseName, 'Squat');
    });
  });

  group('Weekly Summary', () {
    test('computes weekly stats', () {
      final svc = WorkoutTrackerService(
        config: const WorkoutConfig(weeklyGoal: 3),
      );
      // Mon Mar 2, 2026
      final monday = DateTime(2026, 3, 2);
      svc.addWorkout(_makeWorkout(
        id: '1',
        startTime: monday,
        endTime: monday.add(const Duration(minutes: 60)),
        exercises: [
          _makeExercise(sets: [_set(reps: 10, weight: 60)]),
        ],
        rpeScore: 7,
      ));
      svc.addWorkout(_makeWorkout(
        id: '2',
        startTime: monday.add(const Duration(days: 2)),
        endTime: monday.add(const Duration(days: 2, minutes: 45)),
        exercises: [
          _makeExercise(
            name: 'Squat',
            groups: [MuscleGroup.quads],
            sets: [_set(reps: 5, weight: 100)],
          ),
        ],
        rpeScore: 8,
      ));

      final summary = svc.getWeeklySummary(monday);
      expect(summary.workoutCount, 2);
      expect(summary.totalVolume, 1100); // 600 + 500
      expect(summary.totalMinutes, 105);
      expect(summary.avgRpe, 7.5);
      expect(summary.goalProgress, closeTo(66.7, 0.1));
      expect(summary.goalMet, false);
      expect(summary.grade, 'C');
    });

    test('grade A when goal met', () {
      final svc = WorkoutTrackerService(
        config: const WorkoutConfig(weeklyGoal: 1),
      );
      final monday = DateTime(2026, 3, 2);
      svc.addWorkout(_makeWorkout(id: '1', startTime: monday));
      final summary = svc.getWeeklySummary(monday);
      expect(summary.goalMet, true);
      expect(summary.grade, 'A');
    });
  });

  group('Muscle Balance', () {
    test('detects neglected muscle groups', () {
      final svc = WorkoutTrackerService();
      // Only chest + back workouts, never legs
      for (int i = 0; i < 10; i++) {
        svc.addWorkout(_makeWorkout(
          id: 'w$i',
          startTime: DateTime(2026, 3, 1).add(Duration(days: i)),
          exercises: [
            _makeExercise(
              groups: [MuscleGroup.chest],
              sets: [_set(reps: 10, weight: 80)],
            ),
            _makeExercise(
              name: 'Row',
              groups: [MuscleGroup.back],
              sets: [_set(reps: 10, weight: 70)],
            ),
          ],
        ));
      }

      final balance = svc.analyzeMuscleBalance();
      expect(balance.neglectedGroups.isNotEmpty, true);
      expect(
        balance.neglectedGroups.any((g) => g == MuscleGroup.quads),
        true,
      );
    });

    test('upper/lower ratio computed correctly', () {
      final svc = WorkoutTrackerService();
      svc.addWorkout(_makeWorkout(
        id: '1',
        exercises: [
          _makeExercise(
            groups: [MuscleGroup.chest],
            sets: [_set(reps: 10, weight: 100)],
          ),
          _makeExercise(
            name: 'Squat',
            groups: [MuscleGroup.quads],
            sets: [_set(reps: 10, weight: 100)],
          ),
        ],
      ));
      final balance = svc.analyzeMuscleBalance();
      expect(balance.upperLowerRatio, 1.0);
    });

    test('push/pull ratio computed correctly', () {
      final svc = WorkoutTrackerService();
      svc.addWorkout(_makeWorkout(
        id: '1',
        exercises: [
          _makeExercise(
            groups: [MuscleGroup.chest], // push
            sets: [_set(reps: 10, weight: 100)],
          ),
          _makeExercise(
            name: 'Row',
            groups: [MuscleGroup.back], // pull
            sets: [_set(reps: 10, weight: 100)],
          ),
        ],
      ));
      final balance = svc.analyzeMuscleBalance();
      expect(balance.pushPullRatio, 1.0);
    });

    test('detects overtrained groups', () {
      final svc = WorkoutTrackerService();
      for (int i = 0; i < 15; i++) {
        svc.addWorkout(_makeWorkout(
          id: 'w$i',
          startTime: DateTime(2026, 3, 1).add(Duration(days: i)),
          exercises: [
            _makeExercise(
              groups: [MuscleGroup.chest],
              sets: [_set(reps: 10, weight: 80)],
            ),
            if (i % 5 == 0) // only occasionally train back
              _makeExercise(
                name: 'Row',
                groups: [MuscleGroup.back],
                sets: [_set(reps: 10, weight: 70)],
              ),
          ],
        ));
      }

      final balance = svc.analyzeMuscleBalance();
      expect(balance.overtrainedGroups.contains(MuscleGroup.chest), true);
    });
  });

  group('Volume Trends', () {
    test('returns trends grouped by day', () {
      final svc = WorkoutTrackerService();
      final baseDate = DateTime(2026, 3, 1);
      svc.addWorkout(_makeWorkout(
        id: '1',
        startTime: baseDate,
        exercises: [_makeExercise(sets: [_set(reps: 10, weight: 60)])],
      ));
      svc.addWorkout(_makeWorkout(
        id: '2',
        startTime: baseDate.add(const Duration(days: 2)),
        exercises: [_makeExercise(sets: [_set(reps: 8, weight: 80)])],
      ));

      final trends = svc.getVolumeTrend(lastNDays: 30);
      expect(trends.length, 2);
      expect(trends[0].volume, 600);
      expect(trends[1].volume, 640);
    });

    test('empty workouts returns empty trend', () {
      final svc = WorkoutTrackerService();
      expect(svc.getVolumeTrend().isEmpty, true);
    });

    test('multiple workouts same day aggregate', () {
      final svc = WorkoutTrackerService();
      final date = DateTime(2026, 3, 1, 9, 0);
      svc.addWorkout(_makeWorkout(
        id: '1',
        startTime: date,
        exercises: [_makeExercise(sets: [_set(reps: 10, weight: 60)])],
      ));
      svc.addWorkout(_makeWorkout(
        id: '2',
        startTime: date.add(const Duration(hours: 4)),
        exercises: [_makeExercise(sets: [_set(reps: 10, weight: 40)])],
      ));

      final trends = svc.getVolumeTrend();
      expect(trends.length, 1);
      expect(trends[0].volume, 1000);
    });
  });

  group('Streaks', () {
    test('consecutive weeks build streak', () {
      final svc = WorkoutTrackerService();
      // 4 consecutive Mondays
      for (int i = 0; i < 4; i++) {
        svc.addWorkout(_makeWorkout(
          id: 'w$i',
          startTime: DateTime(2026, 3, 2).add(Duration(days: i * 7)),
        ));
      }

      final streak = svc.getStreak();
      expect(streak.currentStreak, 4);
      expect(streak.longestStreak, 4);
      expect(streak.totalWorkouts, 4);
    });

    test('gap breaks streak', () {
      final svc = WorkoutTrackerService();
      svc.addWorkout(_makeWorkout(
        id: '1',
        startTime: DateTime(2026, 2, 3), // week 1
      ));
      svc.addWorkout(_makeWorkout(
        id: '2',
        startTime: DateTime(2026, 2, 10), // week 2
      ));
      // skip week 3
      svc.addWorkout(_makeWorkout(
        id: '3',
        startTime: DateTime(2026, 2, 24), // week 4
      ));
      svc.addWorkout(_makeWorkout(
        id: '4',
        startTime: DateTime(2026, 3, 3), // week 5
      ));

      final streak = svc.getStreak();
      expect(streak.longestStreak, 2);
      expect(streak.currentStreak, 2);
    });

    test('empty workouts returns zero streak', () {
      final svc = WorkoutTrackerService();
      final streak = svc.getStreak();
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(streak.totalWorkouts, 0);
    });

    test('consistency tracks unique days', () {
      final svc = WorkoutTrackerService();
      final start = DateTime(2026, 3, 1);
      svc.addWorkout(_makeWorkout(id: '1', startTime: start));
      svc.addWorkout(_makeWorkout(
          id: '2', startTime: start.add(const Duration(days: 9))));

      final streak = svc.getStreak();
      expect(streak.totalWorkouts, 2);
      expect(streak.totalDaysTracked, 10);
      expect(streak.consistency, 20.0);
    });
  });

  group('Exercise Frequency', () {
    test('counts exercise occurrences', () {
      final svc = WorkoutTrackerService();
      svc.addWorkout(_makeWorkout(
        id: '1',
        exercises: [
          _makeExercise(name: 'Bench Press'),
          _makeExercise(name: 'Squat'),
        ],
      ));
      svc.addWorkout(_makeWorkout(
        id: '2',
        startTime: DateTime(2026, 3, 2),
        exercises: [_makeExercise(name: 'Bench Press')],
      ));

      final freq = svc.getExerciseFrequency();
      expect(freq['Bench Press'], 2);
      expect(freq['Squat'], 1);
    });

    test('getTopExercises returns sorted', () {
      final svc = WorkoutTrackerService();
      for (int i = 0; i < 5; i++) {
        svc.addWorkout(_makeWorkout(
          id: 'w$i',
          startTime: DateTime(2026, 3, 1).add(Duration(days: i)),
          exercises: [
            _makeExercise(name: 'Bench Press'),
            if (i < 3) _makeExercise(name: 'Squat'),
            if (i < 1) _makeExercise(name: 'Deadlift'),
          ],
        ));
      }

      final top = svc.getTopExercises(n: 2);
      expect(top.length, 2);
      expect(top[0].key, 'Bench Press');
      expect(top[0].value, 5);
    });
  });

  group('Tips', () {
    test('empty workouts gets starter tip', () {
      final svc = WorkoutTrackerService();
      final tips = svc.generateTips();
      expect(tips.any((t) => t.contains('Start logging')), true);
    });

    test('neglected muscles generates tip', () {
      final svc = WorkoutTrackerService();
      for (int i = 0; i < 10; i++) {
        svc.addWorkout(_makeWorkout(
          id: 'w$i',
          startTime: DateTime(2026, 3, 1).add(Duration(days: i)),
          exercises: [
            _makeExercise(groups: [MuscleGroup.chest],
                sets: [_set(reps: 10, weight: 80)]),
          ],
        ));
      }
      final tips = svc.generateTips();
      expect(tips.any((t) => t.contains('Consider adding')), true);
    });

    test('long workouts generates tip', () {
      final svc = WorkoutTrackerService();
      svc.addWorkout(_makeWorkout(
        id: '1',
        startTime: DateTime(2026, 3, 1, 9, 0),
        endTime: DateTime(2026, 3, 1, 11, 0), // 120 min
        exercises: [_makeExercise(sets: [_set()])],
      ));
      final tips = svc.generateTips();
      expect(tips.any((t) => t.contains('under 75 min')), true);
    });
  });

  group('Full Report', () {
    test('generates comprehensive report', () {
      final svc = WorkoutTrackerService(
        config: const WorkoutConfig(weeklyGoal: 3),
      );
      svc.addWorkout(_makeWorkout(
        id: '1',
        startTime: DateTime(2026, 3, 1, 9, 0),
        endTime: DateTime(2026, 3, 1, 10, 0),
        exercises: [
          _makeExercise(
            name: 'Bench Press',
            groups: [MuscleGroup.chest, MuscleGroup.triceps],
            sets: [
              _set(reps: 10, weight: 60),
              _set(reps: 8, weight: 70),
              _set(reps: 6, weight: 80),
            ],
          ),
        ],
        rpeScore: 7,
      ));

      final report = svc.generateReport();
      expect(report.totalWorkouts, 1);
      expect(report.totalVolume, 1640);
      expect(report.totalSets, 3);
      expect(report.totalReps, 24);
      expect(report.totalMinutes, 60);
      expect(report.avgWorkoutMinutes, 60);
      expect(report.avgRpe, 7);
      expect(report.personalRecords.isNotEmpty, true);
      expect(report.tips.isNotEmpty, true);
    });

    test('toTextSummary produces output', () {
      final svc = WorkoutTrackerService();
      svc.addWorkout(_makeWorkout(
        id: '1',
        exercises: [_makeExercise(sets: [_set()])],
        rpeScore: 6,
      ));
      final report = svc.generateReport();
      final text = report.toTextSummary();
      expect(text.contains('Workout Report'), true);
      expect(text.contains('Total workouts: 1'), true);
    });
  });

  group('WorkoutConfig', () {
    test('defaults', () {
      const cfg = WorkoutConfig();
      expect(cfg.weeklyGoal, 4);
      expect(cfg.defaultRestSeconds, 90);
      expect(cfg.trackCalories, true);
      expect(cfg.bodyWeightKg, 75);
    });

    test('toJson/fromJson round-trips', () {
      const cfg = WorkoutConfig(
        weeklyGoal: 5,
        defaultRestSeconds: 120,
        trackCalories: false,
        bodyWeightKg: 80,
      );
      final json = cfg.toJson();
      final restored = WorkoutConfig.fromJson(json);
      expect(restored.weeklyGoal, 5);
      expect(restored.defaultRestSeconds, 120);
      expect(restored.trackCalories, false);
      expect(restored.bodyWeightKg, 80);
    });
  });

  group('Serialization', () {
    test('service toJson/fromJson round-trips', () {
      final svc = WorkoutTrackerService(
        config: const WorkoutConfig(weeklyGoal: 5),
      );
      svc.addWorkout(_makeWorkout(
        id: '1',
        exercises: [
          _makeExercise(
            name: 'Squat',
            groups: [MuscleGroup.quads, MuscleGroup.glutes],
            sets: [_set(reps: 5, weight: 120)],
          ),
        ],
        rpeScore: 9,
      ));

      final json = svc.toJson();
      final restored = WorkoutTrackerService.fromJson(json);
      expect(restored.config.weeklyGoal, 5);
      expect(restored.workouts.length, 1);
      expect(restored.workouts[0].exercises[0].name, 'Squat');
      expect(restored.workouts[0].rpeScore, 9);
    });

    test('fromJson handles empty state', () {
      final svc = WorkoutTrackerService.fromJson('{"config":{},"workouts":[]}');
      expect(svc.workouts.isEmpty, true);
      expect(svc.config.weeklyGoal, 4);
    });
  });

  group('WeeklySummary grades', () {
    test('grade B at 75%', () {
      const summary = WeeklySummary(
        weekStart: null ?? DateTime(2026),
        workoutCount: 3,
        totalVolume: 0,
        totalSets: 0,
        totalReps: 0,
        totalMinutes: 0,
        weeklyGoal: 4,
        muscleGroupFrequency: {},
        avgRpe: 0,
      );
      expect(summary.grade, 'B');
    });

    test('grade D at 25%', () {
      const summary = WeeklySummary(
        weekStart: null ?? DateTime(2026),
        workoutCount: 1,
        totalVolume: 0,
        totalSets: 0,
        totalReps: 0,
        totalMinutes: 0,
        weeklyGoal: 4,
        muscleGroupFrequency: {},
        avgRpe: 0,
      );
      expect(summary.grade, 'D');
    });

    test('grade F at 0%', () {
      const summary = WeeklySummary(
        weekStart: null ?? DateTime(2026),
        workoutCount: 0,
        totalVolume: 0,
        totalSets: 0,
        totalReps: 0,
        totalMinutes: 0,
        weeklyGoal: 4,
        muscleGroupFrequency: {},
        avgRpe: 0,
      );
      expect(summary.grade, 'F');
    });
  });
}
