import 'dart:convert';
import 'package:everything/core/utils/date_utils.dart';

/// Difficulty level for a recipe.
enum RecipeDifficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case RecipeDifficulty.easy:
        return 'Easy';
      case RecipeDifficulty.medium:
        return 'Medium';
      case RecipeDifficulty.hard:
        return 'Hard';
    }
  }

  String get emoji {
    switch (this) {
      case RecipeDifficulty.easy:
        return '🟢';
      case RecipeDifficulty.medium:
        return '🟡';
      case RecipeDifficulty.hard:
        return '🔴';
    }
  }
}

/// Meal type categorization.
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
  dessert,
  drink;

  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
      case MealType.dessert:
        return 'Dessert';
      case MealType.drink:
        return 'Drink';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🍳';
      case MealType.lunch:
        return '🥗';
      case MealType.dinner:
        return '🍽️';
      case MealType.snack:
        return '🍿';
      case MealType.dessert:
        return '🍰';
      case MealType.drink:
        return '🥤';
    }
  }
}

/// A single ingredient in a recipe.
class RecipeIngredient {
  final String name;
  final double quantity;
  final String unit;
  final bool optional;

  const RecipeIngredient({
    required this.name,
    required this.quantity,
    this.unit = '',
    this.optional = false,
  });

  /// Scale ingredient by a multiplier (for serving adjustments).
  RecipeIngredient scale(double multiplier) => RecipeIngredient(
        name: name,
        quantity: quantity * multiplier,
        unit: unit,
        optional: optional,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'optional': optional,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String? ?? '',
        optional: json['optional'] as bool? ?? false,
      );

  @override
  String toString() {
    final opt = optional ? ' (optional)' : '';
    if (unit.isEmpty) return '$quantity $name$opt';
    return '$quantity $unit $name$opt';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredient &&
          name == other.name &&
          quantity == other.quantity &&
          unit == other.unit &&
          optional == other.optional;

  @override
  int get hashCode => Object.hash(name, quantity, unit, optional);
}

/// A recipe with ingredients, steps, metadata, and ratings.
class Recipe {
  final String id;
  final String title;
  final String description;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final int prepMinutes;
  final int cookMinutes;
  final int servings;
  final RecipeDifficulty difficulty;
  final MealType mealType;
  final List<String> tags;
  final int? rating; // 1-5
  final String? notes;
  final String? source; // URL or book name
  final DateTime createdAt;
  final DateTime? lastCookedAt;
  final int timesCookedd;
  final bool isFavorite;

  const Recipe({
    required this.id,
    required this.title,
    this.description = '',
    this.ingredients = const [],
    this.steps = const [],
    this.prepMinutes = 0,
    this.cookMinutes = 0,
    this.servings = 1,
    this.difficulty = RecipeDifficulty.easy,
    this.mealType = MealType.dinner,
    this.tags = const [],
    this.rating,
    this.notes,
    this.source,
    required this.createdAt,
    this.lastCookedAt,
    this.timesCookedd = 0,
    this.isFavorite = false,
  });

  /// Total time in minutes.
  int get totalMinutes => prepMinutes + cookMinutes;

  /// Formatted total time (e.g. "1h 30m").
  String get totalTimeFormatted {
    final total = totalMinutes;
    if (total < 60) return '${total}m';
    final h = total ~/ 60;
    final m = total % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  /// Scale recipe to a different number of servings.
  Recipe scaleToServings(int newServings) {
    if (newServings <= 0 || servings <= 0) return this;
    final multiplier = newServings / servings;
    return Recipe(
      id: id,
      title: title,
      description: description,
      ingredients: ingredients.map((i) => i.scale(multiplier)).toList(),
      steps: steps,
      prepMinutes: prepMinutes,
      cookMinutes: cookMinutes,
      servings: newServings,
      difficulty: difficulty,
      mealType: mealType,
      tags: tags,
      rating: rating,
      notes: notes,
      source: source,
      createdAt: createdAt,
      lastCookedAt: lastCookedAt,
      timesCookedd: timesCookedd,
      isFavorite: isFavorite,
    );
  }

  Recipe copyWith({
    String? title,
    String? description,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    int? prepMinutes,
    int? cookMinutes,
    int? servings,
    RecipeDifficulty? difficulty,
    MealType? mealType,
    List<String>? tags,
    int? rating,
    String? notes,
    String? source,
    DateTime? lastCookedAt,
    int? timesCookedd,
    bool? isFavorite,
  }) =>
      Recipe(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
        prepMinutes: prepMinutes ?? this.prepMinutes,
        cookMinutes: cookMinutes ?? this.cookMinutes,
        servings: servings ?? this.servings,
        difficulty: difficulty ?? this.difficulty,
        mealType: mealType ?? this.mealType,
        tags: tags ?? this.tags,
        rating: rating ?? this.rating,
        notes: notes ?? this.notes,
        source: source ?? this.source,
        createdAt: createdAt,
        lastCookedAt: lastCookedAt ?? this.lastCookedAt,
        timesCookedd: timesCookedd ?? this.timesCookedd,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'steps': steps,
        'prepMinutes': prepMinutes,
        'cookMinutes': cookMinutes,
        'servings': servings,
        'difficulty': difficulty.name,
        'mealType': mealType.name,
        'tags': tags,
        'rating': rating,
        'notes': notes,
        'source': source,
        'createdAt': createdAt.toIso8601String(),
        'lastCookedAt': lastCookedAt?.toIso8601String(),
        'timesCookedd': timesCookedd,
        'isFavorite': isFavorite,
      };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        ingredients: (json['ingredients'] as List<dynamic>?)
                ?.map((e) =>
                    RecipeIngredient.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        steps: (json['steps'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        prepMinutes: json['prepMinutes'] as int? ?? 0,
        cookMinutes: json['cookMinutes'] as int? ?? 0,
        servings: json['servings'] as int? ?? 1,
        difficulty: RecipeDifficulty.values.firstWhere(
          (d) => d.name == json['difficulty'],
          orElse: () => RecipeDifficulty.easy,
        ),
        mealType: MealType.values.firstWhere(
          (m) => m.name == json['mealType'],
          orElse: () => MealType.dinner,
        ),
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        rating: json['rating'] as int?,
        notes: json['notes'] as String?,
        source: json['source'] as String?,
        createdAt: AppDateUtils.safeParse(json['createdAt'] as String?),
        lastCookedAt: AppDateUtils.safeParseNullable(json['lastCookedAt'] as String?),
        timesCookedd: json['timesCookedd'] as int? ?? 0,
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  String toJsonString() => jsonEncode(toJson());

  factory Recipe.fromJsonString(String source) =>
      Recipe.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Recipe && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Recipe($title, ${totalTimeFormatted}, $servings servings)';
}
