import 'package:test/test.dart';
import '../lib/models/recipe.dart';
import '../lib/core/services/recipe_book_service.dart';

void main() {
  late RecipeBookService service;

  Recipe _makeRecipe({
    String id = '1',
    String title = 'Pasta',
    List<RecipeIngredient> ingredients = const [],
    List<String> steps = const [],
    int prepMinutes = 10,
    int cookMinutes = 20,
    int servings = 4,
    RecipeDifficulty difficulty = RecipeDifficulty.easy,
    MealType mealType = MealType.dinner,
    List<String> tags = const [],
    int? rating,
    bool isFavorite = false,
  }) {
    return Recipe(
      id: id,
      title: title,
      ingredients: ingredients,
      steps: steps,
      prepMinutes: prepMinutes,
      cookMinutes: cookMinutes,
      servings: servings,
      difficulty: difficulty,
      mealType: mealType,
      tags: tags,
      rating: rating,
      isFavorite: isFavorite,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  setUp(() {
    service = RecipeBookService();
  });

  group('Recipe model', () {
    test('totalMinutes adds prep and cook', () {
      final r = _makeRecipe(prepMinutes: 15, cookMinutes: 45);
      expect(r.totalMinutes, 60);
    });

    test('totalTimeFormatted formats correctly', () {
      expect(_makeRecipe(prepMinutes: 5, cookMinutes: 10).totalTimeFormatted, '15m');
      expect(_makeRecipe(prepMinutes: 30, cookMinutes: 30).totalTimeFormatted, '1h');
      expect(_makeRecipe(prepMinutes: 30, cookMinutes: 45).totalTimeFormatted, '1h 15m');
    });

    test('scaleToServings scales ingredients', () {
      final r = _makeRecipe(
        servings: 2,
        ingredients: [
          RecipeIngredient(name: 'flour', quantity: 200, unit: 'g'),
          RecipeIngredient(name: 'sugar', quantity: 100, unit: 'g'),
        ],
      );
      final scaled = r.scaleToServings(4);
      expect(scaled.servings, 4);
      expect(scaled.ingredients[0].quantity, 400);
      expect(scaled.ingredients[1].quantity, 200);
    });

    test('JSON round-trip preserves data', () {
      final r = _makeRecipe(
        title: 'Test Recipe',
        tags: ['italian', 'quick'],
        rating: 4,
        ingredients: [RecipeIngredient(name: 'egg', quantity: 2)],
        steps: ['Crack eggs', 'Cook'],
      );
      final json = r.toJson();
      final restored = Recipe.fromJson(json);
      expect(restored.title, 'Test Recipe');
      expect(restored.tags, ['italian', 'quick']);
      expect(restored.rating, 4);
      expect(restored.ingredients.length, 1);
      expect(restored.steps.length, 2);
    });

    test('RecipeIngredient toString formats with optional', () {
      final i = RecipeIngredient(name: 'basil', quantity: 5, unit: 'leaves', optional: true);
      expect(i.toString(), '5.0 leaves basil (optional)');
    });
  });

  group('CRUD', () {
    test('addRecipe creates recipe', () {
      final r = service.addRecipe(title: 'Pancakes', servings: 2);
      expect(r.title, 'Pancakes');
      expect(service.allRecipes.length, 1);
    });

    test('getRecipe returns recipe by id', () {
      final r = service.addRecipe(title: 'Soup');
      expect(service.getRecipe(r.id)?.title, 'Soup');
      expect(service.getRecipe('nonexistent'), isNull);
    });

    test('updateRecipe modifies recipe', () {
      final r = service.addRecipe(title: 'Old');
      final updated = service.updateRecipe(r.id, (r) => r.copyWith(title: 'New'));
      expect(updated?.title, 'New');
    });

    test('deleteRecipe removes recipe', () {
      final r = service.addRecipe(title: 'Delete Me');
      service.deleteRecipe(r.id);
      expect(service.allRecipes, isEmpty);
    });

    test('toggleFavorite flips favorite', () {
      final r = service.addRecipe(title: 'Fav');
      expect(service.getRecipe(r.id)!.isFavorite, false);
      service.toggleFavorite(r.id);
      expect(service.getRecipe(r.id)!.isFavorite, true);
      service.toggleFavorite(r.id);
      expect(service.getRecipe(r.id)!.isFavorite, false);
    });

    test('rateRecipe validates range', () {
      final r = service.addRecipe(title: 'Rate Me');
      expect(service.rateRecipe(r.id, 0), isNull);
      expect(service.rateRecipe(r.id, 6), isNull);
      expect(service.rateRecipe(r.id, 3)?.rating, 3);
    });

    test('markCooked increments count and sets date', () {
      final r = service.addRecipe(title: 'Cook Me');
      service.markCooked(r.id);
      service.markCooked(r.id);
      final updated = service.getRecipe(r.id)!;
      expect(updated.timesCookedd, 2);
      expect(updated.lastCookedAt, isNotNull);
    });
  });

  group('Search & Filter', () {
    test('search matches title, tags, and ingredients', () {
      service.addRecipe(title: 'Garlic Bread', tags: ['italian']);
      service.addRecipe(
        title: 'Salad',
        ingredients: [RecipeIngredient(name: 'garlic', quantity: 1)],
      );
      service.addRecipe(title: 'Soup');

      expect(service.search('garlic').length, 2);
      expect(service.search('italian').length, 1);
      expect(service.search('soup').length, 1);
    });

    test('byMealType filters correctly', () {
      service.addRecipe(title: 'A', mealType: MealType.breakfast);
      service.addRecipe(title: 'B', mealType: MealType.dinner);
      expect(service.byMealType(MealType.breakfast).length, 1);
    });

    test('byDifficulty filters correctly', () {
      service.addRecipe(title: 'A', difficulty: RecipeDifficulty.hard);
      service.addRecipe(title: 'B', difficulty: RecipeDifficulty.easy);
      expect(service.byDifficulty(RecipeDifficulty.hard).length, 1);
    });

    test('quickRecipes filters by total time', () {
      service.addRecipe(title: 'Fast', prepMinutes: 5, cookMinutes: 10);
      service.addRecipe(title: 'Slow', prepMinutes: 30, cookMinutes: 60);
      expect(service.quickRecipes(30).length, 1);
      expect(service.quickRecipes(30).first.title, 'Fast');
    });

    test('allTags collects unique tags', () {
      service.addRecipe(title: 'A', tags: ['italian', 'quick']);
      service.addRecipe(title: 'B', tags: ['quick', 'healthy']);
      expect(service.allTags, ['healthy', 'italian', 'quick']);
    });

    test('topRated sorts by rating', () {
      service.addRecipe(title: 'A', rating: 3);
      service.addRecipe(title: 'B', rating: 5);
      service.addRecipe(title: 'C'); // no rating
      final top = service.topRated();
      expect(top.length, 2);
      expect(top.first.title, 'B');
    });

    test('randomRecipe returns recipe or null', () {
      expect(service.randomRecipe(), isNull);
      service.addRecipe(title: 'Only One');
      expect(service.randomRecipe()?.title, 'Only One');
    });
  });

  group('Meal Planning', () {
    test('addToMealPlan and retrieve by day', () {
      final r = service.addRecipe(title: 'Monday Dinner');
      service.addToMealPlan(dayOfWeek: 1, mealType: MealType.dinner, recipeId: r.id);
      expect(service.mealPlanForDay(1).length, 1);
      expect(service.mealPlanForDay(2), isEmpty);
    });

    test('invalid dayOfWeek throws', () {
      expect(
        () => service.addToMealPlan(dayOfWeek: 0, mealType: MealType.dinner, recipeId: '1'),
        throwsArgumentError,
      );
    });

    test('removeFromMealPlan clears entry', () {
      final r = service.addRecipe(title: 'X');
      service.addToMealPlan(dayOfWeek: 3, mealType: MealType.lunch, recipeId: r.id);
      service.removeFromMealPlan(3, MealType.lunch);
      expect(service.mealPlan, isEmpty);
    });

    test('clearMealPlan empties all', () {
      final r = service.addRecipe(title: 'X');
      service.addToMealPlan(dayOfWeek: 1, mealType: MealType.dinner, recipeId: r.id);
      service.addToMealPlan(dayOfWeek: 2, mealType: MealType.lunch, recipeId: r.id);
      service.clearMealPlan();
      expect(service.mealPlan, isEmpty);
    });
  });

  group('Shopping List', () {
    test('generateShoppingList aggregates ingredients', () {
      final r1 = service.addRecipe(
        title: 'A',
        ingredients: [
          RecipeIngredient(name: 'Flour', quantity: 200, unit: 'g'),
          RecipeIngredient(name: 'Sugar', quantity: 100, unit: 'g'),
        ],
      );
      final r2 = service.addRecipe(
        title: 'B',
        ingredients: [
          RecipeIngredient(name: 'flour', quantity: 300, unit: 'g'),
          RecipeIngredient(name: 'Butter', quantity: 50, unit: 'g'),
        ],
      );

      final list = service.generateShoppingList([r1.id, r2.id]);
      final flour = list.firstWhere((i) => i.name.toLowerCase() == 'flour');
      expect(flour.totalQuantity, 500);
      expect(flour.fromRecipes.length, 2);
      expect(list.length, 3); // flour, sugar, butter
    });

    test('optional ingredients are excluded', () {
      final r = service.addRecipe(
        title: 'C',
        ingredients: [
          RecipeIngredient(name: 'Salt', quantity: 1, unit: 'tsp'),
          RecipeIngredient(name: 'Garnish', quantity: 1, optional: true),
        ],
      );
      final list = service.generateShoppingList([r.id]);
      expect(list.length, 1);
      expect(list.first.name, 'Salt');
    });

    test('mealPlanShoppingList uses meal plan recipes', () {
      final r = service.addRecipe(
        title: 'D',
        ingredients: [RecipeIngredient(name: 'Milk', quantity: 500, unit: 'ml')],
      );
      service.addToMealPlan(dayOfWeek: 1, mealType: MealType.breakfast, recipeId: r.id);
      final list = service.mealPlanShoppingList();
      expect(list.length, 1);
      expect(list.first.name, 'Milk');
    });
  });

  group('Import/Export', () {
    test('export and import round-trip', () {
      service.addRecipe(title: 'Export Me', tags: ['test']);
      final json = service.exportJson();

      final service2 = RecipeBookService();
      final count = service2.importJson(json);
      expect(count, 1);
      expect(service2.allRecipes.first.title, 'Export Me');
    });

    test('import skips duplicates', () {
      service.addRecipe(title: 'Dup');
      final json = service.exportJson();
      final count = service.importJson(json);
      expect(count, 0);
      expect(service.allRecipes.length, 1);
    });
  });

  group('Summary', () {
    test('getSummary returns correct stats', () {
      service.addRecipe(
        title: 'A',
        mealType: MealType.breakfast,
        difficulty: RecipeDifficulty.easy,
        prepMinutes: 10,
        cookMinutes: 20,
        rating: 4,
        tags: ['quick', 'healthy'],
      );
      service.addRecipe(
        title: 'B',
        mealType: MealType.dinner,
        difficulty: RecipeDifficulty.hard,
        prepMinutes: 30,
        cookMinutes: 60,
        rating: 5,
        tags: ['italian'],
      );
      service.markCooked(service.allRecipes.first.id);

      final s = service.getSummary();
      expect(s.totalRecipes, 2);
      expect(s.withRating, 2);
      expect(s.averageRating, 4.5);
      expect(s.byMealType[MealType.breakfast], 1);
      expect(s.byDifficulty[RecipeDifficulty.hard], 1);
      expect(s.totalTimesCookedd, 1);
      expect(s.topTags.length, 3);
    });

    test('empty summary has zero values', () {
      final s = service.getSummary();
      expect(s.totalRecipes, 0);
      expect(s.averageRating, 0.0);
      expect(s.avgPrepMinutes, 0);
    });
  });

  group('MealPlanEntry', () {
    test('JSON round-trip', () {
      final entry = MealPlanEntry(dayOfWeek: 5, mealType: MealType.lunch, recipeId: '42');
      final json = entry.toJson();
      final restored = MealPlanEntry.fromJson(json);
      expect(restored.dayOfWeek, 5);
      expect(restored.mealType, MealType.lunch);
      expect(restored.recipeId, '42');
    });
  });
}
