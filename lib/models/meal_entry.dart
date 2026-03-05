import 'dart:convert';

/// Meal type categories.
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
        return '🥞';
      case MealType.lunch:
        return '🥗';
      case MealType.dinner:
        return '🍽️';
      case MealType.snack:
        return '🍎';
      case MealType.dessert:
        return '🍰';
      case MealType.drink:
        return '🥤';
    }
  }
}

/// Food category for nutritional grouping.
enum FoodCategory {
  grain,
  protein,
  dairy,
  fruit,
  vegetable,
  fat,
  sweet,
  beverage,
  other;

  String get label {
    switch (this) {
      case FoodCategory.grain:
        return 'Grains & Carbs';
      case FoodCategory.protein:
        return 'Protein';
      case FoodCategory.dairy:
        return 'Dairy';
      case FoodCategory.fruit:
        return 'Fruit';
      case FoodCategory.vegetable:
        return 'Vegetable';
      case FoodCategory.fat:
        return 'Fats & Oils';
      case FoodCategory.sweet:
        return 'Sweets';
      case FoodCategory.beverage:
        return 'Beverage';
      case FoodCategory.other:
        return 'Other';
    }
  }
}

/// A single food item within a meal.
class FoodItem {
  final String name;
  final FoodCategory category;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double servingSize; // in grams
  final double servings;

  const FoodItem({
    required this.name,
    required this.category,
    required this.calories,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
    this.servingSize = 100,
    this.servings = 1,
  });

  /// Total calories for the amount consumed.
  double get totalCalories => calories * servings;
  double get totalProtein => proteinG * servings;
  double get totalCarbs => carbsG * servings;
  double get totalFat => fatG * servings;
  double get totalFiber => fiberG * servings;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category.name,
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'fiberG': fiberG,
        'servingSize': servingSize,
        'servings': servings,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] as String,
      category: FoodCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => FoodCategory.other,
      ),
      calories: (json['calories'] as num).toDouble(),
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0,
      fatG: (json['fatG'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiberG'] as num?)?.toDouble() ?? 0,
      servingSize: (json['servingSize'] as num?)?.toDouble() ?? 100,
      servings: (json['servings'] as num?)?.toDouble() ?? 1,
    );
  }
}

/// A meal entry containing one or more food items.
class MealEntry {
  final String id;
  final DateTime timestamp;
  final MealType type;
  final List<FoodItem> items;
  final String? notes;
  final int? hungerBefore; // 1-5
  final int? fullnessAfter; // 1-5
  final List<String> tags;

  const MealEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.items,
    this.notes,
    this.hungerBefore,
    this.fullnessAfter,
    this.tags = const [],
  });

  double get totalCalories =>
      items.fold(0.0, (sum, item) => sum + item.totalCalories);
  double get totalProtein =>
      items.fold(0.0, (sum, item) => sum + item.totalProtein);
  double get totalCarbs =>
      items.fold(0.0, (sum, item) => sum + item.totalCarbs);
  double get totalFat => items.fold(0.0, (sum, item) => sum + item.totalFat);
  double get totalFiber =>
      items.fold(0.0, (sum, item) => sum + item.totalFiber);

  /// Macro ratio as percentages (protein/carbs/fat by calories).
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'items': items.map((i) => i.toJson()).toList(),
        'notes': notes,
        'hungerBefore': hungerBefore,
        'fullnessAfter': fullnessAfter,
        'tags': tags,
      };

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: MealType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MealType.snack,
      ),
      items: (json['items'] as List)
          .map((i) => FoodItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      hungerBefore: json['hungerBefore'] as int?,
      fullnessAfter: json['fullnessAfter'] as int?,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
    );
  }

  MealEntry copyWith({
    String? id,
    DateTime? timestamp,
    MealType? type,
    List<FoodItem>? items,
    String? notes,
    int? hungerBefore,
    int? fullnessAfter,
    List<String>? tags,
  }) {
    return MealEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      hungerBefore: hungerBefore ?? this.hungerBefore,
      fullnessAfter: fullnessAfter ?? this.fullnessAfter,
      tags: tags ?? this.tags,
    );
  }
}
