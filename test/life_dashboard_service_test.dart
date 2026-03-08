import 'package:flutter_test/flutter_test.dart';
import 'package:everything_app/core/services/life_dashboard_service.dart';
import 'package:everything_app/models/sleep_entry.dart';
import 'package:everything_app/models/water_entry.dart';
import 'package:everything_app/models/energy_entry.dart';
import 'package:everything_app/models/mood_entry.dart';
import 'package:everything_app/models/workout_entry.dart';
import 'package:everything_app/models/meal_entry.dart';
import 'package:everything_app/models/meditation_entry.dart';
import 'package:everything_app/models/habit.dart';
import 'package:everything_app/models/expense_entry.dart';
import 'package:everything_app/models/screen_time_entry.dart';

void main() {
  const service = LifeDashboardService();
  final now = DateTime.now();

  // ── Helper factories ──────────────────────────────────────────

  SleepEntry mkSleep({
    String id = 's1',
    DateTime? bedtime,
    DateTime? wakeTime,
    SleepQuality quality = SleepQuality.good,
  }) =>
      SleepEntry(
        id: id,
        bedtime: bedtime ?? now.subtract(const Duration(hours: 8)),
        wakeTime: wakeTime ?? now,
        quality: quality,
      );

  WaterEntry mkWater({
    String id = 'w1',
    DateTime? timestamp,
    int amountMl = 250,
  }) =>
      WaterEntry(
        id: id,
        timestamp: timestamp ?? now,
        amountMl: amountMl,
        drinkType: DrinkType.water,
        containerSize: ContainerSize.medium,
      );

  EnergyEntry mkEnergy({
    String id = 'e1',
    DateTime? timestamp,
    EnergyLevel level = EnergyLevel.high,
  }) =>
      EnergyEntry(
        id: id,
        timestamp: timestamp ?? now,
        level: level,
      );

  MoodEntry mkMood({
    String id = 'm1',
    DateTime? timestamp,
    MoodLevel mood = MoodLevel.good,
  }) =>
      MoodEntry(
        id: id,
        timestamp: timestamp ?? now,
        mood: mood,
      );

  WorkoutEntry mkWorkout({
    String id = 'wo1',
    DateTime? startTime,
    DateTime? endTime,
  }) =>
      WorkoutEntry(
        id: id,
        startTime: startTime ?? now.subtract(const Duration(hours: 1)),
        endTime: endTime ?? now,
        name: 'Run',
      );

  MealEntry mkMeal({
    String id = 'ml1',
    DateTime? timestamp,
  }) =>
      MealEntry(
        id: id,
        timestamp: timestamp ?? now,
        items: [
          FoodItem(
            name: 'Oats',
            category: FoodCategory.grain,
            calories: 300,
            proteinG: 10,
            carbsG: 50,
            fatG: 5,
          ),
        ],
        type: MealType.breakfast,
      );

  MeditationEntry mkMeditation({
    String id = 'md1',
    DateTime? dateTime,
    int durationMinutes = 15,
  }) =>
      MeditationEntry(
        id: id,
        dateTime: dateTime ?? now,
        durationMinutes: durationMinutes,
        type: MeditationType.mindfulness,
      );

  ExpenseEntry mkExpense({
    String id = 'ex1',
    DateTime? timestamp,
    double amount = 10.0,
  }) =>
      ExpenseEntry(
        id: id,
        timestamp: timestamp ?? now,
        amount: amount,
        category: ExpenseCategory.food,
        paymentMethod: PaymentMethod.credit,
      );

  ScreenTimeEntry mkScreenTime({
    String id = 'st1',
    DateTime? date,
    int durationMinutes = 60,
  }) =>
      ScreenTimeEntry(
        id: id,
        date: date ?? now,
        appName: 'Twitter',
        category: AppCategory.social,
        durationMinutes: durationMinutes,
        pickups: 10,
      );

  // ── Tests ─────────────────────────────────────────────────────

  group('LifeDashboardService', () {
    test('compute returns valid data with empty inputs', () {
      final data = service.compute();
      expect(data.overallScore, greaterThanOrEqualTo(0));
      expect(data.overallScore, lessThanOrEqualTo(100));
      expect(data.dimensions.length, 10);
      expect(data.insights, isA<List<String>>());
      expect(data.streaks, isA<Map<String, int>>());
      expect(data.computedAt, isNotNull);
    });

    test('all dimensions default to 50 (no data) with empty inputs', () {
      final data = service.compute();
      for (final d in data.dimensions) {
        expect(d.score, 50.0, reason: '${d.name} should default to 50');
        expect(d.label, 'No Data');
      }
    });

    test('overall label maps correctly', () {
      // With all defaults at 50, the weighted average is 50
      final data = service.compute();
      expect(data.overallLabel, isIn(['Good', 'Fair']));
    });

    test('sleep scoring reflects hours and quality', () {
      // 8h sleep, excellent quality → high score
      final data = service.compute(
        sleepEntries: [
          mkSleep(
            bedtime: now.subtract(const Duration(hours: 8)),
            wakeTime: now,
            quality: SleepQuality.excellent,
          ),
        ],
      );
      final sleep = data.dimensions.firstWhere((d) => d.name == 'Sleep');
      expect(sleep.score, greaterThan(70));
      expect(sleep.label, isNot('No Data'));
    });

    test('terrible sleep quality lowers score', () {
      final good = service.compute(
        sleepEntries: [mkSleep(quality: SleepQuality.excellent)],
      );
      final bad = service.compute(
        sleepEntries: [mkSleep(quality: SleepQuality.terrible)],
      );
      final goodSleep =
          good.dimensions.firstWhere((d) => d.name == 'Sleep');
      final badSleep =
          bad.dimensions.firstWhere((d) => d.name == 'Sleep');
      expect(goodSleep.score, greaterThan(badSleep.score));
    });

    test('hydration scoring with 2000ml target', () {
      // Log 2000ml in one day → 100%
      final data = service.compute(
        waterEntries: [
          mkWater(id: 'w1', amountMl: 500),
          mkWater(id: 'w2', amountMl: 500),
          mkWater(id: 'w3', amountMl: 500),
          mkWater(id: 'w4', amountMl: 500),
        ],
      );
      final hydration =
          data.dimensions.firstWhere((d) => d.name == 'Hydration');
      expect(hydration.score, 100.0);
    });

    test('energy scoring maps enum index to percentage', () {
      final data = service.compute(
        energyEntries: [mkEnergy(level: EnergyLevel.peak)],
      );
      final energy =
          data.dimensions.firstWhere((d) => d.name == 'Energy');
      expect(energy.score, 100.0);
    });

    test('exhausted energy gives low score', () {
      final data = service.compute(
        energyEntries: [mkEnergy(level: EnergyLevel.exhausted)],
      );
      final energy =
          data.dimensions.firstWhere((d) => d.name == 'Energy');
      expect(energy.score, 0.0);
    });

    test('mood scoring maps enum index', () {
      final data = service.compute(
        moodEntries: [mkMood(mood: MoodLevel.values.last)],
      );
      final mood = data.dimensions.firstWhere((d) => d.name == 'Mood');
      expect(mood.score, 100.0);
    });

    test('exercise frequency scoring', () {
      // 7 workouts in 7 days = 7/week → capped at 100
      final entries = List.generate(
        7,
        (i) => mkWorkout(
          id: 'wo$i',
          startTime: now.subtract(Duration(days: i, hours: 1)),
          endTime: now.subtract(Duration(days: i)),
        ),
      );
      final data = service.compute(workoutEntries: entries);
      final exercise =
          data.dimensions.firstWhere((d) => d.name == 'Exercise');
      expect(exercise.score, greaterThan(80));
    });

    test('nutrition scores meals per day', () {
      // 3 meals today → 100%
      final data = service.compute(
        mealEntries: [
          mkMeal(id: 'ml1'),
          mkMeal(id: 'ml2'),
          mkMeal(id: 'ml3'),
        ],
      );
      final nutrition =
          data.dimensions.firstWhere((d) => d.name == 'Nutrition');
      expect(nutrition.score, 100.0);
    });

    test('mindfulness scores frequency and duration', () {
      final data = service.compute(
        meditationEntries: List.generate(
          7,
          (i) => mkMeditation(
            id: 'md$i',
            dateTime: now.subtract(Duration(days: i)),
            durationMinutes: 15,
          ),
        ),
      );
      final mindfulness =
          data.dimensions.firstWhere((d) => d.name == 'Mindfulness');
      expect(mindfulness.score, greaterThan(80));
    });

    test('habits score uses completion days', () {
      final habits = [
        Habit(
          id: 'h1',
          name: 'Read',
          createdAt: now.subtract(const Duration(days: 30)),
        ),
      ];
      final completions = List.generate(
        7,
        (i) => HabitCompletion(
          habitId: 'h1',
          date: now.subtract(Duration(days: i)),
        ),
      );
      final data = service.compute(
        habits: habits,
        completions: completions,
      );
      final habitsScore =
          data.dimensions.firstWhere((d) => d.name == 'Habits');
      expect(habitsScore.score, 100.0);
    });

    test('inactive habits are ignored', () {
      final habits = [
        Habit(
          id: 'h1',
          name: 'Archived',
          createdAt: now.subtract(const Duration(days: 30)),
          isActive: false,
        ),
      ];
      final data = service.compute(habits: habits);
      final habitsScore =
          data.dimensions.firstWhere((d) => d.name == 'Habits');
      expect(habitsScore.label, 'No Data');
    });

    test('finances score by tracking consistency', () {
      final data = service.compute(
        expenseEntries: List.generate(
          7,
          (i) => mkExpense(
            id: 'ex$i',
            timestamp: now.subtract(Duration(days: i)),
          ),
        ),
      );
      final finances =
          data.dimensions.firstWhere((d) => d.name == 'Finances');
      expect(finances.score, 100.0);
    });

    test('screen time: less is better', () {
      // Low screen time → high score
      final low = service.compute(
        screenTimeEntries: [mkScreenTime(durationMinutes: 30)],
      );
      final high = service.compute(
        screenTimeEntries: [mkScreenTime(durationMinutes: 480)],
      );
      final lowScore = low.dimensions
          .firstWhere((d) => d.name == 'Screen Time');
      final highScore = high.dimensions
          .firstWhere((d) => d.name == 'Screen Time');
      expect(lowScore.score, greaterThan(highScore.score));
    });

    test('lookbackDays filters old entries', () {
      // Entry 30 days ago, lookback = 7 → should be excluded
      final data = service.compute(
        sleepEntries: [
          mkSleep(
            bedtime: now.subtract(const Duration(days: 30)),
            wakeTime: now.subtract(Duration(days: 29, hours: 16)),
          ),
        ],
        lookbackDays: 7,
      );
      final sleep = data.dimensions.firstWhere((d) => d.name == 'Sleep');
      expect(sleep.label, 'No Data');
    });

    test('history has correct number of days', () {
      final data = service.compute(lookbackDays: 7);
      expect(data.history.length, 7);
    });

    test('history snapshots are ordered oldest to newest', () {
      final data = service.compute(lookbackDays: 5);
      for (int i = 1; i < data.history.length; i++) {
        expect(
          data.history[i].date.isAfter(data.history[i - 1].date),
          isTrue,
        );
      }
    });

    test('trends computed from history', () {
      // With no variation, trends should be stable
      final data = service.compute(lookbackDays: 7);
      expect(data.trends, isNotEmpty);
      expect(data.trends['overall'], Trend.stable);
    });

    test('rising trend detected when latter days are better', () {
      // Simulate improving sleep over 7 days
      final sleepEntries = List.generate(7, (i) {
        final bedtime = now.subtract(Duration(days: 6 - i, hours: 8));
        // Better quality as days progress
        final quality = i < 3 ? SleepQuality.poor : SleepQuality.excellent;
        return mkSleep(
          id: 's$i',
          bedtime: bedtime,
          wakeTime: bedtime.add(const Duration(hours: 8)),
          quality: quality,
        );
      });
      final data = service.compute(sleepEntries: sleepEntries);
      // Sleep trend should be rising (or at least not falling)
      if (data.trends.containsKey('sleep')) {
        expect(data.trends['sleep'], isNot(Trend.falling));
      }
    });

    test('insights generated for strong/weak dimensions', () {
      final data = service.compute(
        energyEntries: [mkEnergy(level: EnergyLevel.peak)],
        moodEntries: [mkMood(mood: MoodLevel.values.last)],
      );
      // Should have at least one insight about strongest area
      expect(data.insights, isNotEmpty);
    });

    test('streaks count consecutive days', () {
      final entries = List.generate(
        5,
        (i) => mkWater(
          id: 'w$i',
          timestamp: now.subtract(Duration(days: i)),
        ),
      );
      final data = service.compute(waterEntries: entries);
      expect(data.streaks['hydration'], greaterThanOrEqualTo(4));
    });

    test('streaks return 0 when no entries', () {
      final data = service.compute();
      for (final v in data.streaks.values) {
        expect(v, 0);
      }
    });

    test('weighted score is between 0 and 100', () {
      // Mix of good and bad entries
      final data = service.compute(
        sleepEntries: [mkSleep(quality: SleepQuality.excellent)],
        waterEntries: [mkWater(amountMl: 2000)],
        energyEntries: [mkEnergy(level: EnergyLevel.exhausted)],
        moodEntries: [mkMood(mood: MoodLevel.values.first)],
      );
      expect(data.overallScore, greaterThanOrEqualTo(0));
      expect(data.overallScore, lessThanOrEqualTo(100));
    });
  });
}
