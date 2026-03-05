import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/meal_entry.dart';
import 'package:everything/core/services/meal_tracker_service.dart';

void main() {
  late MealTrackerService service;
  final today = DateTime(2026, 3, 5, 12, 0);
  final yesterday = DateTime(2026, 3, 4, 12, 0);

  final chickenBreast = FoodItem(
    name: 'Chicken Breast',
    category: FoodCategory.protein,
    calories: 165,
    proteinG: 31,
    carbsG: 0,
    fatG: 3.6,
    servings: 1,
  );

  final rice = FoodItem(
    name: 'Brown Rice',
    category: FoodCategory.grain,
    calories: 216,
    proteinG: 5,
    carbsG: 45,
    fatG: 1.8,
    fiberG: 3.5,
    servings: 1,
  );

  final salad = FoodItem(
    name: 'Mixed Salad',
    category: FoodCategory.vegetable,
    calories: 50,
    proteinG: 2,
    carbsG: 8,
    fatG: 0.5,
    fiberG: 4,
    servings: 1,
  );

  final egg = FoodItem(
    name: 'Scrambled Eggs',
    category: FoodCategory.protein,
    calories: 147,
    proteinG: 10,
    carbsG: 2,
    fatG: 11,
    servings: 1,
  );

  final toast = FoodItem(
    name: 'Whole Wheat Toast',
    category: FoodCategory.grain,
    calories: 80,
    proteinG: 4,
    carbsG: 15,
    fatG: 1,
    fiberG: 2,
    servings: 2,
  );

  final apple = FoodItem(
    name: 'Apple',
    category: FoodCategory.fruit,
    calories: 95,
    proteinG: 0.5,
    carbsG: 25,
    fatG: 0.3,
    fiberG: 4.4,
    servings: 1,
  );

  setUp(() {
    service = MealTrackerService(config: const NutritionConfig(
      dailyCalorieGoal: 2000,
      proteinGoalG: 50,
      carbsGoalG: 250,
      fatGoalG: 65,
      fiberGoalG: 25,
    ));
  });

  group('MealEntry model', () {
    test('calculates total macros correctly', () {
      final entry = MealEntry(
        id: '1',
        timestamp: today,
        type: MealType.lunch,
        items: [chickenBreast, rice],
      );
      expect(entry.totalCalories, 381);
      expect(entry.totalProtein, 36);
      expect(entry.totalCarbs, 45);
    });

    test('calculates macro ratio', () {
      final entry = MealEntry(
        id: '1',
        timestamp: today,
        type: MealType.lunch,
        items: [chickenBreast],
      );
      final ratio = entry.macroRatio;
      expect(ratio['protein']!, greaterThan(50)); // high protein food
      expect(ratio['fat']!, greaterThan(0));
    });

    test('handles empty items macro ratio', () {
      final entry = MealEntry(id: '1', timestamp: today, type: MealType.snack, items: [
        const FoodItem(name: 'Water', category: FoodCategory.beverage, calories: 0),
      ]);
      // Zero macros but has an item
      expect(entry.macroRatio['protein'], 0);
    });

    test('serializes and deserializes', () {
      final entry = MealEntry(
        id: 'test_1',
        timestamp: today,
        type: MealType.dinner,
        items: [chickenBreast, rice, salad],
        notes: 'Good meal',
        hungerBefore: 4,
        fullnessAfter: 3,
        tags: ['healthy', 'homemade'],
      );
      final json = entry.toJson();
      final restored = MealEntry.fromJson(json);
      expect(restored.id, 'test_1');
      expect(restored.type, MealType.dinner);
      expect(restored.items.length, 3);
      expect(restored.notes, 'Good meal');
      expect(restored.hungerBefore, 4);
      expect(restored.fullnessAfter, 3);
      expect(restored.tags, ['healthy', 'homemade']);
    });

    test('copyWith works', () {
      final entry = MealEntry(
        id: '1', timestamp: today, type: MealType.lunch, items: [chickenBreast],
      );
      final updated = entry.copyWith(type: MealType.dinner, notes: 'changed');
      expect(updated.type, MealType.dinner);
      expect(updated.notes, 'changed');
      expect(updated.id, '1');
    });

    test('FoodItem servings multiply correctly', () {
      expect(toast.totalCalories, 160); // 80 * 2
      expect(toast.totalProtein, 8); // 4 * 2
    });
  });

  group('FoodItem model', () {
    test('serializes and deserializes', () {
      final json = chickenBreast.toJson();
      final restored = FoodItem.fromJson(json);
      expect(restored.name, 'Chicken Breast');
      expect(restored.category, FoodCategory.protein);
      expect(restored.calories, 165);
    });
  });

  group('MealType enum', () {
    test('has labels', () {
      expect(MealType.breakfast.label, 'Breakfast');
      expect(MealType.dinner.label, 'Dinner');
    });

    test('has emojis', () {
      expect(MealType.breakfast.emoji, '🥞');
      expect(MealType.snack.emoji, '🍎');
    });
  });

  group('FoodCategory enum', () {
    test('has labels', () {
      expect(FoodCategory.protein.label, 'Protein');
      expect(FoodCategory.grain.label, 'Grains & Carbs');
    });
  });

  group('CRUD operations', () {
    test('addMeal creates entry with id', () {
      final meal = service.addMeal(
        timestamp: today,
        type: MealType.lunch,
        items: [chickenBreast, rice],
      );
      expect(meal.id, startsWith('meal_'));
      expect(service.entries.length, 1);
    });

    test('addMeal rejects empty items', () {
      expect(() => service.addMeal(
        timestamp: today, type: MealType.lunch, items: [],
      ), throwsArgumentError);
    });

    test('addMeal validates hunger range', () {
      expect(() => service.addMeal(
        timestamp: today, type: MealType.lunch, items: [chickenBreast],
        hungerBefore: 6,
      ), throwsArgumentError);
    });

    test('addMeal validates fullness range', () {
      expect(() => service.addMeal(
        timestamp: today, type: MealType.lunch, items: [chickenBreast],
        fullnessAfter: 0,
      ), throwsArgumentError);
    });

    test('getMeal returns entry by id', () {
      final meal = service.addMeal(
        timestamp: today, type: MealType.lunch, items: [chickenBreast],
      );
      expect(service.getMeal(meal.id), isNotNull);
      expect(service.getMeal(meal.id)!.type, MealType.lunch);
    });

    test('getMeal returns null for unknown id', () {
      expect(service.getMeal('nonexistent'), isNull);
    });

    test('removeMeal deletes entry', () {
      final meal = service.addMeal(
        timestamp: today, type: MealType.lunch, items: [chickenBreast],
      );
      expect(service.removeMeal(meal.id), true);
      expect(service.entries.length, 0);
    });

    test('removeMeal returns false for unknown id', () {
      expect(service.removeMeal('nope'), false);
    });

    test('updateMeal modifies entry', () {
      final meal = service.addMeal(
        timestamp: today, type: MealType.lunch, items: [chickenBreast],
      );
      final updated = service.updateMeal(meal.id, type: MealType.dinner, notes: 'Changed');
      expect(updated, isNotNull);
      expect(updated!.type, MealType.dinner);
      expect(updated.notes, 'Changed');
    });

    test('updateMeal returns null for unknown id', () {
      expect(service.updateMeal('nope'), isNull);
    });
  });

  group('Queries', () {
    test('getMealsForDate filters correctly', () {
      service.addMeal(timestamp: today, type: MealType.breakfast, items: [egg]);
      service.addMeal(timestamp: today.add(const Duration(hours: 4)), type: MealType.lunch, items: [chickenBreast]);
      service.addMeal(timestamp: yesterday, type: MealType.lunch, items: [rice]);

      final todayMeals = service.getMealsForDate(today);
      expect(todayMeals.length, 2);
    });

    test('getMealsInRange works', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast]);
      service.addMeal(timestamp: yesterday, type: MealType.lunch, items: [rice]);
      service.addMeal(timestamp: today.subtract(const Duration(days: 10)), type: MealType.lunch, items: [salad]);

      final meals = service.getMealsInRange(yesterday, today);
      expect(meals.length, 2);
    });

    test('getMealsByType filters', () {
      service.addMeal(timestamp: today, type: MealType.breakfast, items: [egg]);
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast]);
      service.addMeal(timestamp: today, type: MealType.breakfast, items: [toast]);

      expect(service.getMealsByType(MealType.breakfast).length, 2);
    });

    test('searchMeals finds by food name', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast]);
      service.addMeal(timestamp: today, type: MealType.lunch, items: [rice]);

      expect(service.searchMeals('chicken').length, 1);
    });

    test('searchMeals finds by notes', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast], notes: 'meal prep');
      expect(service.searchMeals('prep').length, 1);
    });

    test('searchMeals finds by tags', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast], tags: ['keto']);
      expect(service.searchMeals('keto').length, 1);
    });
  });

  group('Daily Summary', () {
    test('calculates totals correctly', () {
      service.addMeal(timestamp: today, type: MealType.breakfast, items: [egg, toast]);
      service.addMeal(timestamp: today.add(const Duration(hours: 4)), type: MealType.lunch, items: [chickenBreast, rice, salad]);

      final summary = service.getDailySummary(today);
      expect(summary.mealCount, 2);
      expect(summary.totalCalories, closeTo(egg.totalCalories + toast.totalCalories + chickenBreast.totalCalories + rice.totalCalories + salad.totalCalories, 0.1));
      expect(summary.caloriesByMeal.keys.length, 2);
    });

    test('grade reflects adherence', () {
      // Add meals close to goals
      service = MealTrackerService(config: const NutritionConfig(dailyCalorieGoal: 400));
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast, rice]);
      final summary = service.getDailySummary(today);
      expect(summary.grade, isNotEmpty);
    });

    test('empty day returns zero summary', () {
      final summary = service.getDailySummary(today);
      expect(summary.mealCount, 0);
      expect(summary.totalCalories, 0);
    });

    test('food category count tracks correctly', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast, rice, salad, apple]);
      final summary = service.getDailySummary(today);
      expect(summary.foodCategoryCount.length, 4); // protein, grain, vegetable, fruit
    });

    test('macro ratio is calculated', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast]);
      final summary = service.getDailySummary(today);
      expect(summary.macroRatio['protein']!, greaterThan(0));
    });

    test('calorie progress percentage works', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast]); // 165 cal
      final summary = service.getDailySummary(today);
      expect(summary.calorieProgress, closeTo(165 / 2000 * 100, 0.1));
    });
  });

  group('Weekly Trends', () {
    test('calculates weekly averages', () {
      final monday = DateTime(2026, 3, 2); // Monday
      for (int i = 0; i < 5; i++) {
        service.addMeal(
          timestamp: monday.add(Duration(days: i, hours: 12)),
          type: MealType.lunch,
          items: [chickenBreast],
        );
      }

      final trend = service.getWeeklyTrend(monday);
      expect(trend.daysLogged, 5);
      expect(trend.totalMeals, 5);
      expect(trend.avgCalories, closeTo(165, 0.1));
      expect(trend.consistencyScore, closeTo(5 / 7 * 100, 0.1));
    });

    test('empty week returns zeros', () {
      final trend = service.getWeeklyTrend(DateTime(2026, 3, 2));
      expect(trend.daysLogged, 0);
      expect(trend.totalMeals, 0);
    });
  });

  group('Streaks', () {
    test('counts consecutive days', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast]);
      service.addMeal(timestamp: yesterday, type: MealType.lunch, items: [rice]);
      service.addMeal(timestamp: today.subtract(const Duration(days: 2)), type: MealType.lunch, items: [salad]);

      expect(service.getLoggingStreak(asOf: today), 3);
    });

    test('streak breaks on gap', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast]);
      // Skip yesterday
      service.addMeal(timestamp: today.subtract(const Duration(days: 2)), type: MealType.lunch, items: [rice]);

      expect(service.getLoggingStreak(asOf: today), 1);
    });

    test('no entries returns 0', () {
      expect(service.getLoggingStreak(asOf: today), 0);
    });
  });

  group('Frequent Foods', () {
    test('returns most used foods', () {
      for (int i = 0; i < 5; i++) {
        service.addMeal(
          timestamp: today.subtract(Duration(days: i)),
          type: MealType.lunch,
          items: [chickenBreast],
        );
      }
      service.addMeal(timestamp: today, type: MealType.snack, items: [apple]);

      final frequent = service.getFrequentFoods(limit: 5);
      expect(frequent.first.food.name, 'Chicken Breast');
      expect(frequent.first.count, 5);
    });

    test('respects limit', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast, rice, salad, apple]);
      expect(service.getFrequentFoods(limit: 2).length, 2);
    });

    test('empty returns empty', () {
      expect(service.getFrequentFoods().isEmpty, true);
    });
  });

  group('Insights', () {
    test('generates no-data insight', () {
      final insights = service.generateInsights(asOf: today);
      expect(insights.any((i) => i.contains('No meals logged')), true);
    });

    test('detects over-calorie', () {
      // Add enough to exceed 120%
      for (int i = 0; i < 15; i++) {
        service.addMeal(timestamp: today.add(Duration(minutes: i)), type: MealType.lunch, items: [chickenBreast]);
      }
      final insights = service.generateInsights(asOf: today);
      expect(insights.any((i) => i.contains('over your calorie goal')), true);
    });

    test('detects good variety', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast, rice, salad, apple]);
      final insights = service.generateInsights(asOf: today);
      expect(insights.any((i) => i.contains('variety')), true);
    });

    test('detects missing breakfast', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast]);
      final insights = service.generateInsights(asOf: today);
      expect(insights.any((i) => i.contains('breakfast')), true);
    });
  });

  group('Hourly Calories', () {
    test('maps calories by hour', () {
      service.addMeal(
        timestamp: DateTime(2026, 3, 5, 8, 0),
        type: MealType.breakfast,
        items: [egg],
      );
      service.addMeal(
        timestamp: DateTime(2026, 3, 5, 12, 0),
        type: MealType.lunch,
        items: [chickenBreast],
      );
      final hourly = service.getHourlyCalories(today);
      expect(hourly[8], closeTo(147, 0.1));
      expect(hourly[12], closeTo(165, 0.1));
    });
  });

  group('Hunger/Fullness Analysis', () {
    test('calculates averages', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast], hungerBefore: 4, fullnessAfter: 3);
      service.addMeal(timestamp: today, type: MealType.dinner, items: [rice], hungerBefore: 2, fullnessAfter: 5);

      final analysis = service.getHungerFullnessAvg();
      expect(analysis['avgHunger'], closeTo(3, 0.01));
      expect(analysis['avgFullness'], closeTo(4, 0.01));
    });

    test('handles no hunger data', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast]);
      final analysis = service.getHungerFullnessAvg();
      expect(analysis['avgHunger'], 0);
    });

    test('respects date range', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast], hungerBefore: 5);
      service.addMeal(timestamp: yesterday, type: MealType.lunch, items: [rice], hungerBefore: 1);

      final analysis = service.getHungerFullnessAvg(start: today);
      expect(analysis['avgHunger'], closeTo(5, 0.01));
    });
  });

  group('Report', () {
    test('generates comprehensive report', () {
      service.addMeal(timestamp: today, type: MealType.breakfast, items: [egg, toast]);
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast, rice, salad]);
      service.addMeal(timestamp: yesterday, type: MealType.lunch, items: [rice]);

      final report = service.generateReport(asOf: today);
      expect(report.today, isNotNull);
      expect(report.totalEntries, 3);
      expect(report.insights, isNotEmpty);
    });

    test('text summary is readable', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast, rice]);
      final report = service.generateReport(asOf: today);
      final text = report.toTextSummary();
      expect(text, contains('Nutrition Report'));
      expect(text, contains('Calories'));
    });
  });

  group('Config', () {
    test('default config values', () {
      final config = const NutritionConfig();
      expect(config.dailyCalorieGoal, 2000);
      expect(config.proteinGoalG, 50);
    });

    test('updateConfig changes goals', () {
      service.updateConfig(const NutritionConfig(dailyCalorieGoal: 2500));
      expect(service.config.dailyCalorieGoal, 2500);
    });

    test('config serializes', () {
      final config = const NutritionConfig(dailyCalorieGoal: 1800, proteinGoalG: 80);
      final json = config.toJson();
      final restored = NutritionConfig.fromJson(json);
      expect(restored.dailyCalorieGoal, 1800);
      expect(restored.proteinGoalG, 80);
    });
  });

  group('Persistence', () {
    test('toJson/fromJson round-trips', () {
      service.addMeal(timestamp: today, type: MealType.lunch, items: [chickenBreast, rice], tags: ['test']);
      service.addMeal(timestamp: yesterday, type: MealType.breakfast, items: [egg]);

      final json = service.toJson();
      final restored = MealTrackerService.fromJson(json);
      expect(restored.entries.length, 2);
      expect(restored.config.dailyCalorieGoal, 2000);
      expect(restored.entries.first.items.length, 2);
    });
  });
}
