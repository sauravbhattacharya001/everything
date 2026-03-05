import 'dart:convert';
import '../../models/meal_entry.dart';

/// Nutrition goals configuration.
class NutritionConfig {
  final int dailyCalorieGoal;
  final int proteinGoalG;
  final int carbsGoalG;
  final int fatGoalG;
  final int fiberGoalG;
  final int mealsPerDay;

  const NutritionConfig({
    this.dailyCalorieGoal = 2000,
    this.proteinGoalG = 50,
    this.carbsGoalG = 250,
    this.fatGoalG = 65,
    this.fiberGoalG = 25,
    this.mealsPerDay = 3,
  });

  Map<String, dynamic> toJson() => {
        'dailyCalorieGoal': dailyCalorieGoal,
        'proteinGoalG': proteinGoalG,
        'carbsGoalG': carbsGoalG,
        'fatGoalG': fatGoalG,
        'fiberGoalG': fiberGoalG,
        'mealsPerDay': mealsPerDay,
      };

  factory NutritionConfig.fromJson(Map<String, dynamic> json) {
    return NutritionConfig(
      dailyCalorieGoal: json['dailyCalorieGoal'] as int? ?? 2000,
      proteinGoalG: json['proteinGoalG'] as int? ?? 50,
      carbsGoalG: json['carbsGoalG'] as int? ?? 250,
      fatGoalG: json['fatGoalG'] as int? ?? 65,
      fiberGoalG: json['fiberGoalG'] as int? ?? 25,
      mealsPerDay: json['mealsPerDay'] as int? ?? 3,
    );
  }
}

/// Daily nutrition summary.
class DailyNutritionSummary {
  final DateTime date;
  final int mealCount;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final Map<MealType, double> caloriesByMeal;
  final Map<FoodCategory, int> foodCategoryCount;
  final NutritionConfig config;

  const DailyNutritionSummary({
    required this.date,
    required this.mealCount,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.caloriesByMeal,
    required this.foodCategoryCount,
    required this.config,
  });

  double get calorieProgress =>
      config.dailyCalorieGoal > 0
          ? (totalCalories / config.dailyCalorieGoal * 100).clamp(0, 300)
          : 0;
  double get proteinProgress =>
      config.proteinGoalG > 0
          ? (totalProtein / config.proteinGoalG * 100).clamp(0, 300)
          : 0;
  double get carbsProgress =>
      config.carbsGoalG > 0
          ? (totalCarbs / config.carbsGoalG * 100).clamp(0, 300)
          : 0;
  double get fatProgress =>
      config.fatGoalG > 0
          ? (totalFat / config.fatGoalG * 100).clamp(0, 300)
          : 0;
  double get fiberProgress =>
      config.fiberGoalG > 0
          ? (totalFiber / config.fiberGoalG * 100).clamp(0, 300)
          : 0;

  bool get calorieGoalMet => totalCalories >= config.dailyCalorieGoal;

  String get grade {
    // Average of macro adherence (how close to goals without exceeding much)
    double score = 0;
    int count = 0;
    for (final pct in [calorieProgress, proteinProgress, carbsProgress, fatProgress, fiberProgress]) {
      // Score: 100 at exactly 100%, decreasing for over/under
      final deviation = (pct - 100).abs();
      score += (100 - deviation).clamp(0, 100);
      count++;
    }
    final avg = count > 0 ? score / count : 0;
    if (avg >= 85) return 'A';
    if (avg >= 70) return 'B';
    if (avg >= 55) return 'C';
    if (avg >= 40) return 'D';
    return 'F';
  }

  /// Macro ratio by calorie percentage.
  Map<String, double> get macroRatio {
    final protCal = totalProtein * 4;
    final carbCal = totalCarbs * 4;
    final fatCal = totalFat * 9;
    final total = protCal + carbCal + fatCal;
    if (total == 0) return {'protein': 0, 'carbs': 0, 'fat': 0};
    return {
      'protein': protCal / total * 100,
      'carbs': carbCal / total * 100,
      'fat': fatCal / total * 100,
    };
  }
}

/// Weekly nutrition trends.
class WeeklyNutritionTrend {
  final DateTime weekStart;
  final int daysLogged;
  final double avgCalories;
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;
  final double avgFiber;
  final int totalMeals;
  final double consistencyScore; // 0-100
  final Map<MealType, int> mealTypeDistribution;
  final String? trend; // 'increasing', 'decreasing', 'stable'

  const WeeklyNutritionTrend({
    required this.weekStart,
    required this.daysLogged,
    required this.avgCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.avgFiber,
    required this.totalMeals,
    required this.consistencyScore,
    required this.mealTypeDistribution,
    this.trend,
  });
}

/// Favorite/frequent foods for quick logging.
class FrequentFood {
  final FoodItem food;
  final int count;
  final DateTime lastUsed;

  const FrequentFood({
    required this.food,
    required this.count,
    required this.lastUsed,
  });
}

/// Full nutrition report.
class NutritionReport {
  final DailyNutritionSummary? today;
  final List<WeeklyNutritionTrend> weeklyTrends;
  final List<FrequentFood> topFoods;
  final int totalEntries;
  final int loggingStreak;
  final List<String> insights;

  const NutritionReport({
    this.today,
    this.weeklyTrends = const [],
    this.topFoods = const [],
    this.totalEntries = 0,
    this.loggingStreak = 0,
    this.insights = const [],
  });

  String toTextSummary() {
    final buf = StringBuffer();
    buf.writeln('=== Nutrition Report ===');
    buf.writeln('Total entries: $totalEntries');
    buf.writeln('Logging streak: $loggingStreak days');
    buf.writeln();

    if (today != null) {
      buf.writeln('--- Today ---');
      buf.writeln('Calories: ${today!.totalCalories.toStringAsFixed(0)} / ${today!.config.dailyCalorieGoal} kcal (${today!.calorieProgress.toStringAsFixed(0)}%)');
      buf.writeln('Protein: ${today!.totalProtein.toStringAsFixed(1)}g / ${today!.config.proteinGoalG}g');
      buf.writeln('Carbs: ${today!.totalCarbs.toStringAsFixed(1)}g / ${today!.config.carbsGoalG}g');
      buf.writeln('Fat: ${today!.totalFat.toStringAsFixed(1)}g / ${today!.config.fatGoalG}g');
      buf.writeln('Fiber: ${today!.totalFiber.toStringAsFixed(1)}g / ${today!.config.fiberGoalG}g');
      buf.writeln('Grade: ${today!.grade}');
      buf.writeln('Meals: ${today!.mealCount}');
      buf.writeln();
    }

    if (topFoods.isNotEmpty) {
      buf.writeln('--- Top Foods ---');
      for (final f in topFoods.take(5)) {
        buf.writeln('  ${f.food.name}: ${f.count}x (${f.food.calories.toStringAsFixed(0)} cal/serving)');
      }
      buf.writeln();
    }

    if (insights.isNotEmpty) {
      buf.writeln('--- Insights ---');
      for (final i in insights) {
        buf.writeln('  • $i');
      }
    }

    return buf.toString();
  }
}

/// Meal/Nutrition Tracker service.
///
/// Tracks daily food intake with calories, macronutrients (protein/carbs/fat/fiber),
/// meal types, food categories, hunger/fullness levels, and tags.
/// Provides daily summaries, weekly trends, streak tracking, frequent foods,
/// smart insights, and comprehensive reports.
class MealTrackerService {
  final List<MealEntry> _entries = [];
  NutritionConfig _config;
  int _nextId = 1;

  MealTrackerService({NutritionConfig? config})
      : _config = config ?? const NutritionConfig();

  NutritionConfig get config => _config;

  void updateConfig(NutritionConfig config) {
    _config = config;
  }

  List<MealEntry> get entries => List.unmodifiable(_entries);

  // ─── CRUD ───────────────────────────────────────────────

  MealEntry addMeal({
    required DateTime timestamp,
    required MealType type,
    required List<FoodItem> items,
    String? notes,
    int? hungerBefore,
    int? fullnessAfter,
    List<String> tags = const [],
  }) {
    if (items.isEmpty) throw ArgumentError('Meal must have at least one item');
    if (hungerBefore != null && (hungerBefore < 1 || hungerBefore > 5)) {
      throw ArgumentError('hungerBefore must be 1-5');
    }
    if (fullnessAfter != null && (fullnessAfter < 1 || fullnessAfter > 5)) {
      throw ArgumentError('fullnessAfter must be 1-5');
    }

    final entry = MealEntry(
      id: 'meal_${_nextId++}',
      timestamp: timestamp,
      type: type,
      items: List.unmodifiable(items),
      notes: notes,
      hungerBefore: hungerBefore,
      fullnessAfter: fullnessAfter,
      tags: tags,
    );
    _entries.add(entry);
    return entry;
  }

  MealEntry? getMeal(String id) {
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  bool removeMeal(String id) {
    final len = _entries.length;
    _entries.removeWhere((e) => e.id == id);
    return _entries.length < len;
  }

  MealEntry? updateMeal(String id, {
    DateTime? timestamp,
    MealType? type,
    List<FoodItem>? items,
    String? notes,
    int? hungerBefore,
    int? fullnessAfter,
    List<String>? tags,
  }) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx < 0) return null;
    final old = _entries[idx];
    final updated = old.copyWith(
      timestamp: timestamp,
      type: type,
      items: items,
      notes: notes,
      hungerBefore: hungerBefore,
      fullnessAfter: fullnessAfter,
      tags: tags,
    );
    _entries[idx] = updated;
    return updated;
  }

  // ─── Queries ────────────────────────────────────────────

  List<MealEntry> getMealsForDate(DateTime date) {
    return _entries.where((e) =>
        e.timestamp.year == date.year &&
        e.timestamp.month == date.month &&
        e.timestamp.day == date.day).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<MealEntry> getMealsInRange(DateTime start, DateTime end) {
    return _entries.where((e) =>
        !e.timestamp.isBefore(start) && !e.timestamp.isAfter(end)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<MealEntry> getMealsByType(MealType type) {
    return _entries.where((e) => e.type == type).toList();
  }

  List<MealEntry> searchMeals(String query) {
    final q = query.toLowerCase();
    return _entries.where((e) =>
        e.items.any((i) => i.name.toLowerCase().contains(q)) ||
        (e.notes?.toLowerCase().contains(q) ?? false) ||
        e.tags.any((t) => t.toLowerCase().contains(q))).toList();
  }

  // ─── Daily Summary ─────────────────────────────────────

  DailyNutritionSummary getDailySummary(DateTime date) {
    final meals = getMealsForDate(date);
    double totalCal = 0, totalProt = 0, totalCarbs = 0, totalFat = 0, totalFiber = 0;
    final calByMeal = <MealType, double>{};
    final catCount = <FoodCategory, int>{};

    for (final meal in meals) {
      totalCal += meal.totalCalories;
      totalProt += meal.totalProtein;
      totalCarbs += meal.totalCarbs;
      totalFat += meal.totalFat;
      totalFiber += meal.totalFiber;
      calByMeal[meal.type] = (calByMeal[meal.type] ?? 0) + meal.totalCalories;
      for (final item in meal.items) {
        catCount[item.category] = (catCount[item.category] ?? 0) + 1;
      }
    }

    return DailyNutritionSummary(
      date: date,
      mealCount: meals.length,
      totalCalories: totalCal,
      totalProtein: totalProt,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      totalFiber: totalFiber,
      caloriesByMeal: calByMeal,
      foodCategoryCount: catCount,
      config: _config,
    );
  }

  // ─── Weekly Trends ──────────────────────────────────────

  WeeklyNutritionTrend getWeeklyTrend(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final meals = getMealsInRange(weekStart, weekEnd.subtract(const Duration(seconds: 1)));

    // Group by day
    final daySet = <String>{};
    final mealTypeDist = <MealType, int>{};
    double totalCal = 0, totalProt = 0, totalCarbs = 0, totalFat = 0, totalFiber = 0;

    for (final meal in meals) {
      daySet.add('${meal.timestamp.year}-${meal.timestamp.month}-${meal.timestamp.day}');
      totalCal += meal.totalCalories;
      totalProt += meal.totalProtein;
      totalCarbs += meal.totalCarbs;
      totalFat += meal.totalFat;
      totalFiber += meal.totalFiber;
      mealTypeDist[meal.type] = (mealTypeDist[meal.type] ?? 0) + 1;
    }

    final daysLogged = daySet.length;
    final divisor = daysLogged > 0 ? daysLogged : 1;
    final consistency = daysLogged / 7 * 100;

    return WeeklyNutritionTrend(
      weekStart: weekStart,
      daysLogged: daysLogged,
      avgCalories: totalCal / divisor,
      avgProtein: totalProt / divisor,
      avgCarbs: totalCarbs / divisor,
      avgFat: totalFat / divisor,
      avgFiber: totalFiber / divisor,
      totalMeals: meals.length,
      consistencyScore: consistency,
      mealTypeDistribution: mealTypeDist,
    );
  }

  // ─── Streaks ────────────────────────────────────────────

  int getLoggingStreak({DateTime? asOf}) {
    final today = asOf ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int streak = 0;
    var check = todayDate;

    while (true) {
      final meals = getMealsForDate(check);
      if (meals.isEmpty) break;
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ─── Frequent Foods ─────────────────────────────────────

  List<FrequentFood> getFrequentFoods({int limit = 10}) {
    final foodMap = <String, _FoodCount>{};
    for (final entry in _entries) {
      for (final item in entry.items) {
        final key = item.name.toLowerCase();
        if (foodMap.containsKey(key)) {
          foodMap[key]!.count++;
          if (entry.timestamp.isAfter(foodMap[key]!.lastUsed)) {
            foodMap[key]!.lastUsed = entry.timestamp;
          }
        } else {
          foodMap[key] = _FoodCount(item, 1, entry.timestamp);
        }
      }
    }

    final sorted = foodMap.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return sorted.take(limit).map((f) => FrequentFood(
      food: f.food,
      count: f.count,
      lastUsed: f.lastUsed,
    )).toList();
  }

  // ─── Insights ───────────────────────────────────────────

  List<String> generateInsights({DateTime? asOf}) {
    final today = asOf ?? DateTime.now();
    final insights = <String>[];
    final summary = getDailySummary(today);

    if (summary.mealCount == 0) {
      insights.add('No meals logged today yet. Start tracking to see insights!');
      return insights;
    }

    // Calorie insights
    if (summary.calorieProgress > 120) {
      insights.add('You\'re ${(summary.calorieProgress - 100).toStringAsFixed(0)}% over your calorie goal today.');
    } else if (summary.calorieProgress >= 90 && summary.calorieProgress <= 110) {
      insights.add('Great job! You\'re right on target with your calorie goal.');
    } else if (summary.calorieProgress < 50 && summary.mealCount >= 2) {
      insights.add('You\'re under 50% of your calorie goal. Consider a nutrient-dense meal.');
    }

    // Protein check
    if (summary.proteinProgress < 50 && summary.mealCount >= 2) {
      insights.add('Protein intake is low. Consider adding eggs, chicken, fish, or legumes.');
    } else if (summary.proteinProgress >= 100) {
      insights.add('Excellent protein intake today! 💪');
    }

    // Fiber check
    if (summary.totalFiber > 0 && summary.fiberProgress < 40) {
      insights.add('Fiber is low. Add more fruits, vegetables, or whole grains.');
    }

    // Food variety
    if (summary.foodCategoryCount.length >= 4) {
      insights.add('Good food variety today with ${summary.foodCategoryCount.length} food groups!');
    } else if (summary.foodCategoryCount.length <= 2 && summary.mealCount >= 2) {
      insights.add('Try diversifying your food groups for better nutrition.');
    }

    // Macro balance
    final ratio = summary.macroRatio;
    if (ratio['fat']! > 40) {
      insights.add('Fat intake is high (${ratio['fat']!.toStringAsFixed(0)}% of calories). Consider more lean options.');
    }

    // Meal regularity
    final mealTypes = summary.caloriesByMeal.keys.toSet();
    if (!mealTypes.contains(MealType.breakfast) && summary.mealCount > 0) {
      insights.add('No breakfast logged. Starting the day with a meal can boost energy.');
    }

    // Streak
    final streak = getLoggingStreak(asOf: today);
    if (streak >= 7) {
      insights.add('🔥 $streak-day logging streak! Keep it up!');
    } else if (streak >= 3) {
      insights.add('Nice $streak-day streak going!');
    }

    return insights;
  }

  // ─── Calorie Distribution by Hour ──────────────────────

  Map<int, double> getHourlyCalories(DateTime date) {
    final meals = getMealsForDate(date);
    final hourly = <int, double>{};
    for (final meal in meals) {
      final hour = meal.timestamp.hour;
      hourly[hour] = (hourly[hour] ?? 0) + meal.totalCalories;
    }
    return hourly;
  }

  // ─── Hunger/Fullness Analysis ──────────────────────────

  Map<String, double> getHungerFullnessAvg({DateTime? start, DateTime? end}) {
    var filtered = _entries.toList();
    if (start != null) filtered = filtered.where((e) => !e.timestamp.isBefore(start)).toList();
    if (end != null) filtered = filtered.where((e) => !e.timestamp.isAfter(end)).toList();

    final hungerEntries = filtered.where((e) => e.hungerBefore != null).toList();
    final fullnessEntries = filtered.where((e) => e.fullnessAfter != null).toList();

    return {
      'avgHunger': hungerEntries.isEmpty ? 0 :
          hungerEntries.fold(0.0, (s, e) => s + e.hungerBefore!) / hungerEntries.length,
      'avgFullness': fullnessEntries.isEmpty ? 0 :
          fullnessEntries.fold(0.0, (s, e) => s + e.fullnessAfter!) / fullnessEntries.length,
      'hungerCount': hungerEntries.length.toDouble(),
      'fullnessCount': fullnessEntries.length.toDouble(),
    };
  }

  // ─── Full Report ────────────────────────────────────────

  NutritionReport generateReport({DateTime? asOf}) {
    final today = asOf ?? DateTime.now();
    final todaySummary = getDailySummary(today);

    // Last 4 weeks of trends
    final trends = <WeeklyNutritionTrend>[];
    for (int i = 0; i < 4; i++) {
      final weekStart = today.subtract(Duration(days: today.weekday - 1 + i * 7));
      trends.add(getWeeklyTrend(weekStart));
    }

    return NutritionReport(
      today: todaySummary,
      weeklyTrends: trends,
      topFoods: getFrequentFoods(limit: 5),
      totalEntries: _entries.length,
      loggingStreak: getLoggingStreak(asOf: today),
      insights: generateInsights(asOf: today),
    );
  }

  // ─── Persistence ────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'config': _config.toJson(),
        'entries': _entries.map((e) => e.toJson()).toList(),
        'nextId': _nextId,
      };

  factory MealTrackerService.fromJson(Map<String, dynamic> json) {
    final service = MealTrackerService(
      config: NutritionConfig.fromJson(json['config'] as Map<String, dynamic>),
    );
    service._nextId = json['nextId'] as int? ?? 1;
    final entries = (json['entries'] as List?)
        ?.map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    if (entries != null) service._entries.addAll(entries);
    return service;
  }
}

class _FoodCount {
  final FoodItem food;
  int count;
  DateTime lastUsed;
  _FoodCount(this.food, this.count, this.lastUsed);
}
