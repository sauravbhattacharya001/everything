/// Recipe Book Service — manage recipes with ingredients, steps, tags,
/// ratings, meal planning, and grocery list generation.

import 'dart:convert';
import '../../models/recipe.dart';

/// Weekly meal plan entry.
class MealPlanEntry {
  final int dayOfWeek; // 1=Monday, 7=Sunday
  final MealType mealType;
  final String recipeId;

  const MealPlanEntry({
    required this.dayOfWeek,
    required this.mealType,
    required this.recipeId,
  });

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'mealType': mealType.name,
        'recipeId': recipeId,
      };

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) => MealPlanEntry(
        dayOfWeek: json['dayOfWeek'] as int,
        mealType: MealType.values.firstWhere(
          (m) => m.name == json['mealType'],
          orElse: () => MealType.dinner,
        ),
        recipeId: json['recipeId'] as String,
      );
}

/// Summary statistics for the recipe collection.
class RecipeSummary {
  final int totalRecipes;
  final int favorites;
  final int withRating;
  final double averageRating;
  final Map<MealType, int> byMealType;
  final Map<RecipeDifficulty, int> byDifficulty;
  final int avgPrepMinutes;
  final int avgCookMinutes;
  final List<String> topTags;
  final int totalTimesCookedd;

  const RecipeSummary({
    required this.totalRecipes,
    required this.favorites,
    required this.withRating,
    required this.averageRating,
    required this.byMealType,
    required this.byDifficulty,
    required this.avgPrepMinutes,
    required this.avgCookMinutes,
    required this.topTags,
    required this.totalTimesCookedd,
  });
}

/// Ingredient aggregated across multiple recipes for shopping.
class ShoppingIngredient {
  final String name;
  final double totalQuantity;
  final String unit;
  final List<String> fromRecipes;

  const ShoppingIngredient({
    required this.name,
    required this.totalQuantity,
    required this.unit,
    required this.fromRecipes,
  });

  @override
  String toString() {
    if (unit.isEmpty) return '$totalQuantity $name';
    return '$totalQuantity $unit $name';
  }
}

/// Main service for recipe book management.
class RecipeBookService {
  final List<Recipe> _recipes;
  final List<MealPlanEntry> _mealPlan;

  RecipeBookService({
    List<Recipe>? recipes,
    List<MealPlanEntry>? mealPlan,
  })  : _recipes = recipes ?? [],
        _mealPlan = mealPlan ?? [];

  List<Recipe> get allRecipes => List.unmodifiable(_recipes);
  List<Recipe> get favorites => _recipes.where((r) => r.isFavorite).toList();
  List<MealPlanEntry> get mealPlan => List.unmodifiable(_mealPlan);

  // --- CRUD ---

  /// Add a new recipe.
  Recipe addRecipe({
    required String title,
    String description = '',
    List<RecipeIngredient> ingredients = const [],
    List<String> steps = const [],
    int prepMinutes = 0,
    int cookMinutes = 0,
    int servings = 1,
    RecipeDifficulty difficulty = RecipeDifficulty.easy,
    MealType mealType = MealType.dinner,
    List<String> tags = const [],
    int? rating,
    String? notes,
    String? source,
  }) {
    final recipe = Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      ingredients: ingredients,
      steps: steps,
      prepMinutes: prepMinutes,
      cookMinutes: cookMinutes,
      servings: servings,
      difficulty: difficulty,
      mealType: mealType,
      tags: tags,
      rating: rating,
      notes: notes,
      source: source,
      createdAt: DateTime.now(),
    );
    _recipes.add(recipe);
    return recipe;
  }

  /// Get a recipe by id.
  Recipe? getRecipe(String id) {
    try {
      return _recipes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Update a recipe.
  Recipe? updateRecipe(String id, Recipe Function(Recipe) updater) {
    final index = _recipes.indexWhere((r) => r.id == id);
    if (index < 0) return null;
    _recipes[index] = updater(_recipes[index]);
    return _recipes[index];
  }

  /// Delete a recipe.
  bool deleteRecipe(String id) {
    final removed = _recipes.removeWhere((r) => r.id == id);
    _mealPlan.removeWhere((e) => e.recipeId == id);
    return true;
  }

  /// Toggle favorite status.
  Recipe? toggleFavorite(String id) =>
      updateRecipe(id, (r) => r.copyWith(isFavorite: !r.isFavorite));

  /// Rate a recipe (1-5).
  Recipe? rateRecipe(String id, int rating) {
    if (rating < 1 || rating > 5) return null;
    return updateRecipe(id, (r) => r.copyWith(rating: rating));
  }

  /// Record that a recipe was cooked.
  Recipe? markCooked(String id) => updateRecipe(
        id,
        (r) => r.copyWith(
          lastCookedAt: DateTime.now(),
          timesCookedd: r.timesCookedd + 1,
        ),
      );

  // --- Search & Filter ---

  /// Search recipes by title, description, tags, or ingredient names.
  List<Recipe> search(String query) {
    final q = query.toLowerCase();
    return _recipes.where((r) {
      return r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.tags.any((t) => t.toLowerCase().contains(q)) ||
          r.ingredients.any((i) => i.name.toLowerCase().contains(q));
    }).toList();
  }

  /// Filter by meal type.
  List<Recipe> byMealType(MealType type) =>
      _recipes.where((r) => r.mealType == type).toList();

  /// Filter by difficulty.
  List<Recipe> byDifficulty(RecipeDifficulty difficulty) =>
      _recipes.where((r) => r.difficulty == difficulty).toList();

  /// Filter by tag.
  List<Recipe> byTag(String tag) {
    final t = tag.toLowerCase();
    return _recipes
        .where((r) => r.tags.any((rt) => rt.toLowerCase() == t))
        .toList();
  }

  /// Filter by max total time.
  List<Recipe> quickRecipes(int maxMinutes) =>
      _recipes.where((r) => r.totalMinutes <= maxMinutes).toList();

  /// Get all unique tags across all recipes.
  List<String> get allTags {
    final tags = <String>{};
    for (final r in _recipes) {
      tags.addAll(r.tags);
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  /// Get top-rated recipes.
  List<Recipe> topRated({int limit = 10}) {
    final rated = _recipes.where((r) => r.rating != null).toList()
      ..sort((a, b) => b.rating!.compareTo(a.rating!));
    return rated.take(limit).toList();
  }

  /// Get most-cooked recipes.
  List<Recipe> mostCooked({int limit = 10}) {
    final cooked = _recipes.where((r) => r.timesCookedd > 0).toList()
      ..sort((a, b) => b.timesCookedd.compareTo(a.timesCookedd));
    return cooked.take(limit).toList();
  }

  /// Get recipes not cooked in a long time (or never).
  List<Recipe> forgotten({int daysSince = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: daysSince));
    return _recipes
        .where((r) =>
            r.lastCookedAt == null || r.lastCookedAt!.isBefore(cutoff))
        .toList();
  }

  /// Get a random recipe, optionally filtered by meal type.
  Recipe? randomRecipe({MealType? mealType}) {
    var pool = mealType != null ? byMealType(mealType) : _recipes.toList();
    if (pool.isEmpty) return null;
    pool.shuffle();
    return pool.first;
  }

  // --- Meal Planning ---

  /// Add a recipe to the weekly meal plan.
  MealPlanEntry addToMealPlan({
    required int dayOfWeek,
    required MealType mealType,
    required String recipeId,
  }) {
    if (dayOfWeek < 1 || dayOfWeek > 7) {
      throw ArgumentError('dayOfWeek must be 1-7');
    }
    final entry = MealPlanEntry(
      dayOfWeek: dayOfWeek,
      mealType: mealType,
      recipeId: recipeId,
    );
    _mealPlan.add(entry);
    return entry;
  }

  /// Remove a meal plan entry.
  void removeFromMealPlan(int dayOfWeek, MealType mealType) {
    _mealPlan.removeWhere(
        (e) => e.dayOfWeek == dayOfWeek && e.mealType == mealType);
  }

  /// Clear the entire meal plan.
  void clearMealPlan() => _mealPlan.clear();

  /// Get meal plan for a specific day.
  List<MealPlanEntry> mealPlanForDay(int dayOfWeek) =>
      _mealPlan.where((e) => e.dayOfWeek == dayOfWeek).toList();

  // --- Shopping List Generation ---

  /// Generate aggregated shopping list from a list of recipe ids.
  List<ShoppingIngredient> generateShoppingList(List<String> recipeIds) {
    final map = <String, _AggIngredient>{};

    for (final id in recipeIds) {
      final recipe = getRecipe(id);
      if (recipe == null) continue;

      for (final ing in recipe.ingredients) {
        if (ing.optional) continue;
        final key = '${ing.name.toLowerCase()}|${ing.unit.toLowerCase()}';
        if (map.containsKey(key)) {
          map[key]!.quantity += ing.quantity;
          map[key]!.recipes.add(recipe.title);
        } else {
          map[key] = _AggIngredient(
            name: ing.name,
            quantity: ing.quantity,
            unit: ing.unit,
            recipes: [recipe.title],
          );
        }
      }
    }

    return map.values
        .map((a) => ShoppingIngredient(
              name: a.name,
              totalQuantity: a.quantity,
              unit: a.unit,
              fromRecipes: a.recipes,
            ))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Generate shopping list from the current meal plan.
  List<ShoppingIngredient> mealPlanShoppingList() {
    final ids = _mealPlan.map((e) => e.recipeId).toSet().toList();
    return generateShoppingList(ids);
  }

  // --- Import/Export ---

  /// Export all recipes as JSON string.
  String exportJson() => jsonEncode(_recipes.map((r) => r.toJson()).toList());

  /// Import recipes from JSON string (merges, skips duplicates by id).
  int importJson(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    int imported = 0;
    for (final item in list) {
      final recipe = Recipe.fromJson(item as Map<String, dynamic>);
      if (!_recipes.any((r) => r.id == recipe.id)) {
        _recipes.add(recipe);
        imported++;
      }
    }
    return imported;
  }

  // --- Statistics ---

  /// Get collection summary.
  RecipeSummary getSummary() {
    final rated = _recipes.where((r) => r.rating != null);
    final avgRating = rated.isEmpty
        ? 0.0
        : rated.map((r) => r.rating!).reduce((a, b) => a + b) / rated.length;

    final byMeal = <MealType, int>{};
    final byDiff = <RecipeDifficulty, int>{};
    for (final r in _recipes) {
      byMeal[r.mealType] = (byMeal[r.mealType] ?? 0) + 1;
      byDiff[r.difficulty] = (byDiff[r.difficulty] ?? 0) + 1;
    }

    // Top tags
    final tagCounts = <String, int>{};
    for (final r in _recipes) {
      for (final t in r.tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RecipeSummary(
      totalRecipes: _recipes.length,
      favorites: favorites.length,
      withRating: rated.length,
      averageRating: double.parse(avgRating.toStringAsFixed(1)),
      byMealType: byMeal,
      byDifficulty: byDiff,
      avgPrepMinutes: _recipes.isEmpty
          ? 0
          : _recipes.map((r) => r.prepMinutes).reduce((a, b) => a + b) ~/
              _recipes.length,
      avgCookMinutes: _recipes.isEmpty
          ? 0
          : _recipes.map((r) => r.cookMinutes).reduce((a, b) => a + b) ~/
              _recipes.length,
      topTags: topTags.take(10).map((e) => e.key).toList(),
      totalTimesCookedd:
          _recipes.map((r) => r.timesCookedd).fold(0, (a, b) => a + b),
    );
  }
}

/// Internal helper for aggregating ingredients.
class _AggIngredient {
  final String name;
  double quantity;
  final String unit;
  final List<String> recipes;

  _AggIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.recipes,
  });
}
