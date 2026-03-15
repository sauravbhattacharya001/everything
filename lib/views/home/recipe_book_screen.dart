import 'package:flutter/material.dart';
import '../../core/services/recipe_book_service.dart';
import '../../core/services/screen_persistence.dart';
import '../../models/recipe.dart';

/// Recipe Book screen — browse, search, add, rate, and plan meals
/// with a personal recipe collection.
class RecipeBookScreen extends StatefulWidget {
  const RecipeBookScreen({super.key});

  @override
  State<RecipeBookScreen> createState() => _RecipeBookScreenState();
}

class _RecipeBookScreenState extends State<RecipeBookScreen>
    with SingleTickerProviderStateMixin {
  final RecipeBookService _service = RecipeBookService();
  final _persistence = ScreenPersistence<Recipe>(
    storageKey: 'recipe_book_recipes',
    toJson: (e) => e.toJson(),
    fromJson: Recipe.fromJson,
  );
  late TabController _tabController;
  String _searchQuery = '';
  MealType? _mealFilter;
  RecipeDifficulty? _difficultyFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final saved = await _persistence.load();
    if (saved.isNotEmpty) {
      _service.importJson(
        saved.map((r) => r.toJson()).toList().toString().replaceAll(')', ']').replaceAll('(', '['),
      );
      // Re-import properly
    } else {
      _addSampleRecipes();
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    await _persistence.save(_service.allRecipes);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addSampleRecipes() {
    _service.addRecipe(
      title: 'Classic Pancakes',
      description: 'Fluffy buttermilk pancakes perfect for lazy mornings',
      ingredients: const [
        RecipeIngredient(name: 'flour', quantity: 1.5, unit: 'cups'),
        RecipeIngredient(name: 'milk', quantity: 1.25, unit: 'cups'),
        RecipeIngredient(name: 'egg', quantity: 1, unit: ''),
        RecipeIngredient(name: 'butter', quantity: 3, unit: 'tbsp'),
        RecipeIngredient(name: 'sugar', quantity: 2, unit: 'tbsp'),
        RecipeIngredient(name: 'baking powder', quantity: 2, unit: 'tsp'),
        RecipeIngredient(name: 'vanilla extract', quantity: 1, unit: 'tsp', optional: true),
      ],
      steps: [
        'Mix dry ingredients in a large bowl',
        'Whisk wet ingredients separately',
        'Combine wet and dry — don\'t overmix',
        'Heat griddle to medium, grease lightly',
        'Pour ¼ cup batter per pancake',
        'Flip when bubbles form, cook until golden',
      ],
      prepMinutes: 10,
      cookMinutes: 15,
      servings: 4,
      difficulty: RecipeDifficulty.easy,
      mealType: MealType.breakfast,
      tags: ['classic', 'quick', 'family'],
      rating: 5,
    );

    _service.addRecipe(
      title: 'Chicken Stir Fry',
      description: 'Quick weeknight dinner with crispy vegetables',
      ingredients: const [
        RecipeIngredient(name: 'chicken breast', quantity: 500, unit: 'g'),
        RecipeIngredient(name: 'broccoli', quantity: 2, unit: 'cups'),
        RecipeIngredient(name: 'bell pepper', quantity: 1, unit: ''),
        RecipeIngredient(name: 'soy sauce', quantity: 3, unit: 'tbsp'),
        RecipeIngredient(name: 'garlic', quantity: 3, unit: 'cloves'),
        RecipeIngredient(name: 'ginger', quantity: 1, unit: 'tbsp'),
        RecipeIngredient(name: 'sesame oil', quantity: 1, unit: 'tbsp'),
        RecipeIngredient(name: 'cornstarch', quantity: 1, unit: 'tbsp'),
      ],
      steps: [
        'Slice chicken into thin strips, toss with cornstarch',
        'Heat oil in wok over high heat',
        'Cook chicken until golden, set aside',
        'Stir fry vegetables with garlic and ginger (2-3 min)',
        'Return chicken, add soy sauce and sesame oil',
        'Toss until coated, serve over rice',
      ],
      prepMinutes: 15,
      cookMinutes: 10,
      servings: 3,
      difficulty: RecipeDifficulty.easy,
      mealType: MealType.dinner,
      tags: ['asian', 'quick', 'healthy', 'high-protein'],
      rating: 4,
    );

    _service.addRecipe(
      title: 'Chocolate Lava Cake',
      description: 'Molten chocolate center with a crisp shell — pure indulgence',
      ingredients: const [
        RecipeIngredient(name: 'dark chocolate', quantity: 120, unit: 'g'),
        RecipeIngredient(name: 'butter', quantity: 100, unit: 'g'),
        RecipeIngredient(name: 'eggs', quantity: 2, unit: ''),
        RecipeIngredient(name: 'egg yolks', quantity: 2, unit: ''),
        RecipeIngredient(name: 'sugar', quantity: 50, unit: 'g'),
        RecipeIngredient(name: 'flour', quantity: 25, unit: 'g'),
        RecipeIngredient(name: 'cocoa powder', quantity: 1, unit: 'tbsp', optional: true),
      ],
      steps: [
        'Preheat oven to 220°C (425°F)',
        'Melt chocolate and butter together',
        'Whisk eggs, yolks, and sugar until thick',
        'Fold in chocolate mixture, then flour',
        'Pour into greased ramekins',
        'Bake 12-14 minutes — edges set, center jiggly',
        'Let rest 1 minute, invert onto plates, serve immediately',
      ],
      prepMinutes: 15,
      cookMinutes: 14,
      servings: 4,
      difficulty: RecipeDifficulty.medium,
      mealType: MealType.dessert,
      tags: ['chocolate', 'impressive', 'date-night'],
      rating: 5,
    );

    _service.addRecipe(
      title: 'Mediterranean Quinoa Bowl',
      description: 'Nutritious grain bowl with fresh herbs and tangy dressing',
      ingredients: const [
        RecipeIngredient(name: 'quinoa', quantity: 1, unit: 'cup'),
        RecipeIngredient(name: 'cucumber', quantity: 1, unit: ''),
        RecipeIngredient(name: 'cherry tomatoes', quantity: 1, unit: 'cup'),
        RecipeIngredient(name: 'feta cheese', quantity: 100, unit: 'g'),
        RecipeIngredient(name: 'kalamata olives', quantity: 0.5, unit: 'cup'),
        RecipeIngredient(name: 'red onion', quantity: 0.25, unit: ''),
        RecipeIngredient(name: 'olive oil', quantity: 3, unit: 'tbsp'),
        RecipeIngredient(name: 'lemon juice', quantity: 2, unit: 'tbsp'),
        RecipeIngredient(name: 'fresh parsley', quantity: 0.25, unit: 'cup'),
      ],
      steps: [
        'Cook quinoa according to package directions, let cool',
        'Dice cucumber, halve tomatoes, slice red onion thinly',
        'Whisk olive oil with lemon juice, salt, and pepper',
        'Toss quinoa with vegetables and dressing',
        'Top with crumbled feta, olives, and parsley',
      ],
      prepMinutes: 15,
      cookMinutes: 20,
      servings: 2,
      difficulty: RecipeDifficulty.easy,
      mealType: MealType.lunch,
      tags: ['healthy', 'vegetarian', 'meal-prep'],
    );

    _service.addRecipe(
      title: 'Spicy Thai Basil Noodles',
      description: 'Street-food style noodles with holy basil and chili',
      ingredients: const [
        RecipeIngredient(name: 'rice noodles', quantity: 200, unit: 'g'),
        RecipeIngredient(name: 'ground pork', quantity: 250, unit: 'g'),
        RecipeIngredient(name: 'Thai basil leaves', quantity: 1, unit: 'cup'),
        RecipeIngredient(name: 'Thai chilies', quantity: 3, unit: ''),
        RecipeIngredient(name: 'garlic', quantity: 4, unit: 'cloves'),
        RecipeIngredient(name: 'fish sauce', quantity: 2, unit: 'tbsp'),
        RecipeIngredient(name: 'oyster sauce', quantity: 1, unit: 'tbsp'),
        RecipeIngredient(name: 'sugar', quantity: 1, unit: 'tsp'),
      ],
      steps: [
        'Soak rice noodles in hot water until tender, drain',
        'Pound garlic and chilies in mortar',
        'Fry garlic-chili paste in hot oil until fragrant',
        'Add pork, break apart, cook until browned',
        'Add fish sauce, oyster sauce, and sugar',
        'Toss in noodles and basil leaves, stir until wilted',
        'Serve with a fried egg on top',
      ],
      prepMinutes: 10,
      cookMinutes: 10,
      servings: 2,
      difficulty: RecipeDifficulty.medium,
      mealType: MealType.dinner,
      tags: ['asian', 'spicy', 'street-food', 'quick'],
      rating: 4,
    );

    _service.addRecipe(
      title: 'Mango Lassi',
      description: 'Creamy Indian yogurt smoothie — sweet and refreshing',
      ingredients: const [
        RecipeIngredient(name: 'ripe mango', quantity: 1, unit: ''),
        RecipeIngredient(name: 'yogurt', quantity: 1, unit: 'cup'),
        RecipeIngredient(name: 'milk', quantity: 0.5, unit: 'cup'),
        RecipeIngredient(name: 'sugar', quantity: 2, unit: 'tbsp'),
        RecipeIngredient(name: 'cardamom', quantity: 0.25, unit: 'tsp', optional: true),
      ],
      steps: [
        'Peel and chop mango',
        'Blend all ingredients until smooth',
        'Adjust sweetness to taste',
        'Serve chilled with a pinch of cardamom',
      ],
      prepMinutes: 5,
      cookMinutes: 0,
      servings: 2,
      difficulty: RecipeDifficulty.easy,
      mealType: MealType.drink,
      tags: ['indian', 'refreshing', 'quick', 'no-cook'],
    );
  }

  List<Recipe> get _filteredRecipes {
    var recipes = _service.allRecipes;
    if (_searchQuery.isNotEmpty) {
      recipes = _service.search(_searchQuery);
    }
    if (_mealFilter != null) {
      recipes = recipes.where((r) => r.mealType == _mealFilter).toList();
    }
    if (_difficultyFilter != null) {
      recipes = recipes.where((r) => r.difficulty == _difficultyFilter).toList();
    }
    return recipes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('📖 Recipe Book'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: '❤️ Favorites'),
            Tab(text: '📅 Meal Plan'),
            Tab(text: '📊 Stats'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddRecipeDialog,
            tooltip: 'Add recipe',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTab(theme),
          _buildFavoritesTab(theme),
          _buildMealPlanTab(theme),
          _buildStatsTab(theme),
        ],
      ),
    );
  }

  // ── ALL RECIPES TAB ──

  Widget _buildAllTab(ThemeData theme) {
    final recipes = _filteredRecipes;
    return Column(
      children: [
        // Search and filter bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search recipes, ingredients, tags...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All meals', _mealFilter == null, () {
                      setState(() => _mealFilter = null);
                    }),
                    ...MealType.values.map((t) => _filterChip(
                          '${t.emoji} ${t.label}',
                          _mealFilter == t,
                          () => setState(() => _mealFilter = _mealFilter == t ? null : t),
                        )),
                    const SizedBox(width: 8),
                    ...RecipeDifficulty.values.map((d) => _filterChip(
                          '${d.emoji} ${d.label}',
                          _difficultyFilter == d,
                          () => setState(() => _difficultyFilter = _difficultyFilter == d ? null : d),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Recipe list
        Expanded(
          child: recipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🍽️', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text('No recipes found', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Add your first recipe!',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: recipes.length,
                  itemBuilder: (context, i) => _recipeCard(recipes[i], theme),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _recipeCard(Recipe recipe, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRecipeDetail(recipe),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(recipe.mealType.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.title,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        if (recipe.description.isNotEmpty)
                          Text(recipe.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  if (recipe.isFavorite) const Icon(Icons.favorite, color: Colors.red, size: 18),
                  const SizedBox(width: 4),
                  Text(recipe.difficulty.emoji),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _metaChip(Icons.timer, recipe.totalTimeFormatted),
                  const SizedBox(width: 10),
                  _metaChip(Icons.people, '${recipe.servings} servings'),
                  const SizedBox(width: 10),
                  _metaChip(Icons.restaurant, '${recipe.ingredients.length} ingredients'),
                  const Spacer(),
                  if (recipe.rating != null)
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < recipe.rating! ? Icons.star : Icons.star_border,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                ],
              ),
              if (recipe.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: recipe.tags.take(4).map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  // ── FAVORITES TAB ──

  Widget _buildFavoritesTab(ThemeData theme) {
    final favs = _service.favorites;
    if (favs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('❤️', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text('No favorites yet'),
            SizedBox(height: 4),
            Text('Tap the heart on any recipe to save it here',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: favs.length,
      itemBuilder: (context, i) => _recipeCard(favs[i], theme),
    );
  }

  // ── MEAL PLAN TAB ──

  Widget _buildMealPlanTab(ThemeData theme) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final mealPlan = _service.mealPlan;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Weekly Meal Plan', style: theme.textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.shopping_cart, size: 16),
                label: const Text('Shopping List'),
                onPressed: mealPlan.isEmpty ? null : _showShoppingList,
              ),
              TextButton.icon(
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear'),
                onPressed: mealPlan.isEmpty
                    ? null
                    : () {
                        _service.clearMealPlan();
                        _save();
                        setState(() {});
                      },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(7, (dayIndex) {
            final dayNum = dayIndex + 1;
            final dayEntries = _service.mealPlanForDay(dayNum);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(days[dayIndex],
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () => _showAddToMealPlan(dayNum),
                          tooltip: 'Add meal',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (dayEntries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('No meals planned',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      )
                    else
                      ...dayEntries.map((entry) {
                        final recipe = _service.getRecipe(entry.recipeId);
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Text(entry.mealType.emoji, style: const TextStyle(fontSize: 20)),
                          title: Text(recipe?.title ?? 'Unknown recipe'),
                          subtitle: Text(entry.mealType.label),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                            onPressed: () {
                              _service.removeFromMealPlan(entry.dayOfWeek, entry.mealType);
                              _save();
                              setState(() {});
                            },
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── STATS TAB ──

  Widget _buildStatsTab(ThemeData theme) {
    final summary = _service.getSummary();
    final topRated = _service.topRated(limit: 5);
    final mostCooked = _service.mostCooked(limit: 5);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.8,
            children: [
              _statCard('📖', 'Total Recipes', '${summary.totalRecipes}', theme),
              _statCard('❤️', 'Favorites', '${summary.favorites}', theme),
              _statCard('⭐', 'Avg Rating', summary.averageRating.toStringAsFixed(1), theme),
              _statCard('🍳', 'Times Cooked', '${summary.totalTimesCookedd}', theme),
              _statCard('⏱️', 'Avg Prep', '${summary.avgPrepMinutes}m', theme),
              _statCard('🔥', 'Avg Cook', '${summary.avgCookMinutes}m', theme),
            ],
          ),
          const SizedBox(height: 16),

          // By meal type
          Text('By Meal Type', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...MealType.values.where((m) => (summary.byMealType[m] ?? 0) > 0).map((m) {
            final count = summary.byMealType[m]!;
            final pct = summary.totalRecipes > 0 ? count / summary.totalRecipes : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text('${m.emoji} ${m.label}', style: const TextStyle(fontSize: 12))),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.grey[200],
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Top rated
          if (topRated.isNotEmpty) ...[
            Text('⭐ Top Rated', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ...topRated.map((r) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(r.mealType.emoji, style: const TextStyle(fontSize: 18)),
                  title: Text(r.title),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      r.rating!,
                      (_) => const Icon(Icons.star, size: 14, color: Colors.amber),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Top tags
          if (summary.topTags.isNotEmpty) ...[
            Text('🏷️ Popular Tags', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: summary.topTags.map((t) => Chip(
                    label: Text(t),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String label, String value, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$emoji $value', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // ── DIALOGS ──

  void _showRecipeDetail(Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(recipe.mealType.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${recipe.difficulty.emoji} ${recipe.difficulty.label} · ${recipe.totalTimeFormatted} · ${recipe.servings} servings',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Action buttons
              Row(
                children: [
                  IconButton(
                    icon: Icon(recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: recipe.isFavorite ? Colors.red : null),
                    onPressed: () {
                      _service.toggleFavorite(recipe.id);
                      _save();
                      setState(() {});
                      Navigator.pop(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.restaurant),
                    tooltip: 'Mark as cooked',
                    onPressed: () {
                      _service.markCooked(recipe.id);
                      _save();
                      setState(() {});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text('Marked "${recipe.title}" as cooked! 👨‍🍳')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      _service.deleteRecipe(recipe.id);
                      _save();
                      setState(() {});
                      Navigator.pop(context);
                    },
                  ),
                  const Spacer(),
                  // Rating
                  ...List.generate(
                    5,
                    (i) => GestureDetector(
                      onTap: () {
                        _service.rateRecipe(recipe.id, i + 1);
                        _save();
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: Icon(
                        i < (recipe.rating ?? 0) ? Icons.star : Icons.star_border,
                        size: 22,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),

              // Description
              if (recipe.description.isNotEmpty) ...[
                Text(recipe.description, style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
              ],

              // Prep/Cook time breakdown
              Row(
                children: [
                  _timeBlock('Prep', recipe.prepMinutes),
                  const SizedBox(width: 16),
                  _timeBlock('Cook', recipe.cookMinutes),
                  const SizedBox(width: 16),
                  _timeBlock('Total', recipe.totalMinutes),
                ],
              ),
              const SizedBox(height: 16),

              // Ingredients
              Text('Ingredients', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...recipe.ingredients.map((ing) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ing.toString(),
                            style: TextStyle(
                              color: ing.optional ? Colors.grey : null,
                              fontStyle: ing.optional ? FontStyle.italic : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),

              // Steps
              Text('Steps', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...recipe.steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          child: Text('${e.key + 1}', style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(e.value)),
                      ],
                    ),
                  )),

              // Tags
              if (recipe.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: recipe.tags.map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                ),
              ],

              // Notes
              if (recipe.notes != null) ...[
                const SizedBox(height: 12),
                Text('Notes', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(recipe.notes!, style: TextStyle(color: Colors.grey[600])),
              ],

              // Source
              if (recipe.source != null) ...[
                const SizedBox(height: 8),
                Text('Source: ${recipe.source}', style: TextStyle(color: Colors.blue[600], fontSize: 12)),
              ],

              // Cook history
              if (recipe.timesCookedd > 0) ...[
                const SizedBox(height: 12),
                Text(
                  'Cooked ${recipe.timesCookedd} time${recipe.timesCookedd == 1 ? '' : 's'}${recipe.lastCookedAt != null ? ' · Last: ${_formatDate(recipe.lastCookedAt!)}' : ''}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeBlock(String label, int minutes) {
    return Column(
      children: [
        Text('${minutes}m', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _showAddRecipeDialog() {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    final prepCtl = TextEditingController(text: '15');
    final cookCtl = TextEditingController(text: '30');
    final servingsCtl = TextEditingController(text: '4');
    final tagsCtl = TextEditingController();
    final ingredientControllers = <Map<String, TextEditingController>>[
      {'name': TextEditingController(), 'qty': TextEditingController(), 'unit': TextEditingController()},
    ];
    final stepControllers = <TextEditingController>[TextEditingController()];
    var selectedMealType = MealType.dinner;
    var selectedDifficulty = RecipeDifficulty.easy;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Recipe'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtl, decoration: const InputDecoration(labelText: 'Recipe title *')),
                  const SizedBox(height: 8),
                  TextField(controller: descCtl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<MealType>(
                          value: selectedMealType,
                          decoration: const InputDecoration(labelText: 'Meal type'),
                          items: MealType.values.map((t) => DropdownMenuItem(
                                value: t,
                                child: Text('${t.emoji} ${t.label}'),
                              )).toList(),
                          onChanged: (v) => setDialogState(() => selectedMealType = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<RecipeDifficulty>(
                          value: selectedDifficulty,
                          decoration: const InputDecoration(labelText: 'Difficulty'),
                          items: RecipeDifficulty.values.map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('${d.emoji} ${d.label}'),
                              )).toList(),
                          onChanged: (v) => setDialogState(() => selectedDifficulty = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: prepCtl, decoration: const InputDecoration(labelText: 'Prep (min)'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: cookCtl, decoration: const InputDecoration(labelText: 'Cook (min)'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: servingsCtl, decoration: const InputDecoration(labelText: 'Servings'), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ingredients
                  Row(
                    children: [
                      const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                        onPressed: () {
                          setDialogState(() {
                            ingredientControllers.add({
                              'name': TextEditingController(),
                              'qty': TextEditingController(),
                              'unit': TextEditingController(),
                            });
                          });
                        },
                      ),
                    ],
                  ),
                  ...ingredientControllers.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            SizedBox(width: 50, child: TextField(controller: e.value['qty'], decoration: const InputDecoration(hintText: 'Qty', isDense: true), keyboardType: TextInputType.number)),
                            const SizedBox(width: 4),
                            SizedBox(width: 50, child: TextField(controller: e.value['unit'], decoration: const InputDecoration(hintText: 'Unit', isDense: true))),
                            const SizedBox(width: 4),
                            Expanded(child: TextField(controller: e.value['name'], decoration: const InputDecoration(hintText: 'Ingredient name', isDense: true))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),

                  // Steps
                  Row(
                    children: [
                      const Text('Steps', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                        onPressed: () {
                          setDialogState(() => stepControllers.add(TextEditingController()));
                        },
                      ),
                    ],
                  ),
                  ...stepControllers.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text('${e.key + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: e.value, decoration: const InputDecoration(hintText: 'Step description', isDense: true))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  TextField(controller: tagsCtl, decoration: const InputDecoration(labelText: 'Tags (comma-separated)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (titleCtl.text.trim().isEmpty) return;
                final ingredients = ingredientControllers
                    .where((c) => c['name']!.text.trim().isNotEmpty)
                    .map((c) => RecipeIngredient(
                          name: c['name']!.text.trim(),
                          quantity: double.tryParse(c['qty']!.text) ?? 0,
                          unit: c['unit']!.text.trim(),
                        ))
                    .toList();
                final steps = stepControllers
                    .map((c) => c.text.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                final tags = tagsCtl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

                _service.addRecipe(
                  title: titleCtl.text.trim(),
                  description: descCtl.text.trim(),
                  ingredients: ingredients,
                  steps: steps,
                  prepMinutes: int.tryParse(prepCtl.text) ?? 0,
                  cookMinutes: int.tryParse(cookCtl.text) ?? 0,
                  servings: int.tryParse(servingsCtl.text) ?? 1,
                  mealType: selectedMealType,
                  difficulty: selectedDifficulty,
                  tags: tags,
                );
                _save();
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Add Recipe'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToMealPlan(int dayOfWeek) {
    final recipes = _service.allRecipes;
    if (recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some recipes first!')),
      );
      return;
    }
    var selectedMealType = MealType.dinner;
    String? selectedRecipeId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Meal — Day $dayOfWeek'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MealType>(
                value: selectedMealType,
                decoration: const InputDecoration(labelText: 'Meal'),
                items: MealType.values.map((t) => DropdownMenuItem(value: t, child: Text('${t.emoji} ${t.label}'))).toList(),
                onChanged: (v) => setDialogState(() => selectedMealType = v!),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedRecipeId,
                decoration: const InputDecoration(labelText: 'Recipe'),
                items: recipes.map((r) => DropdownMenuItem(value: r.id, child: Text(r.title))).toList(),
                onChanged: (v) => setDialogState(() => selectedRecipeId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: selectedRecipeId == null
                  ? null
                  : () {
                      _service.addToMealPlan(
                        dayOfWeek: dayOfWeek,
                        mealType: selectedMealType,
                        recipeId: selectedRecipeId!,
                      );
                      _save();
                      setState(() {});
                      Navigator.pop(context);
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showShoppingList() {
    final items = _service.mealPlanShoppingList();
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🛒 Shopping List', style: Theme.of(context).textTheme.titleLarge),
            Text('${items.length} items from your meal plan',
                style: TextStyle(color: Colors.grey[600])),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.circle, size: 8),
                    title: Text(item.toString()),
                    subtitle: Text('From: ${item.fromRecipes.join(', ')}',
                        style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
