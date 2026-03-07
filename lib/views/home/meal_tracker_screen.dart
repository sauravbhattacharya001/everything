import 'package:flutter/material.dart';
import '../../core/services/meal_tracker_service.dart';
import '../../models/meal_entry.dart';

/// Meal Tracker screen — log meals with food items, view daily history,
/// track nutrition goals, and see insights.
class MealTrackerScreen extends StatefulWidget {
  const MealTrackerScreen({super.key});

  @override
  State<MealTrackerScreen> createState() => _MealTrackerScreenState();
}

class _MealTrackerScreenState extends State<MealTrackerScreen>
    with SingleTickerProviderStateMixin {
  final MealTrackerService _service = MealTrackerService();
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍽️ Meal Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Log'),
            Tab(icon: Icon(Icons.history), text: 'Today'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Nutrition'),
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LogMealTab(service: _service, onAdded: () => setState(() {})),
          _DailyMealsTab(
            service: _service,
            date: _selectedDate,
            onDateChanged: (d) => setState(() => _selectedDate = d),
            onChanged: () => setState(() {}),
          ),
          _NutritionTab(service: _service, date: _selectedDate),
          _InsightsTab(service: _service),
        ],
      ),
    );
  }
}

// ─── LOG MEAL TAB ───────────────────────────────────────────────────────────

class _LogMealTab extends StatefulWidget {
  final MealTrackerService service;
  final VoidCallback onAdded;

  const _LogMealTab({required this.service, required this.onAdded});

  @override
  State<_LogMealTab> createState() => _LogMealTabState();
}

class _LogMealTabState extends State<_LogMealTab> {
  MealType _selectedType = MealType.lunch;
  final List<FoodItem> _items = [];
  final _notesController = TextEditingController();
  int? _hungerBefore;
  int? _fullnessAfter;
  TimeOfDay _mealTime = TimeOfDay.now();

  // Food item form
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  FoodCategory _foodCategory = FoodCategory.other;

  @override
  void dispose() {
    _notesController.dispose();
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _addFoodItem() {
    final name = _foodNameController.text.trim();
    final cal = double.tryParse(_caloriesController.text) ?? 0;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a food name')),
      );
      return;
    }
    setState(() {
      _items.add(FoodItem(
        name: name,
        category: _foodCategory,
        calories: cal,
        proteinG: double.tryParse(_proteinController.text) ?? 0,
        carbsG: double.tryParse(_carbsController.text) ?? 0,
        fatG: double.tryParse(_fatController.text) ?? 0,
      ));
      _foodNameController.clear();
      _caloriesController.clear();
      _proteinController.clear();
      _carbsController.clear();
      _fatController.clear();
      _foodCategory = FoodCategory.other;
    });
  }

  void _saveMeal() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one food item')),
      );
      return;
    }
    final now = DateTime.now();
    final timestamp = DateTime(
      now.year, now.month, now.day,
      _mealTime.hour, _mealTime.minute,
    );
    widget.service.addMeal(
      timestamp: timestamp,
      type: _selectedType,
      items: List.of(_items),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      hungerBefore: _hungerBefore,
      fullnessAfter: _fullnessAfter,
    );
    setState(() {
      _items.clear();
      _notesController.clear();
      _hungerBefore = null;
      _fullnessAfter = null;
    });
    widget.onAdded();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedType.emoji} ${_selectedType.label} logged!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal type selector
          Text('Meal Type', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: MealType.values.map((type) {
              final selected = type == _selectedType;
              return ChoiceChip(
                label: Text('${type.emoji} ${type.label}'),
                selected: selected,
                onSelected: (_) => setState(() => _selectedType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Time picker
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text('Time: ${_mealTime.format(context)}'),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _mealTime,
              );
              if (picked != null) setState(() => _mealTime = picked);
            },
          ),
          const Divider(),

          // Hunger before
          Text('Hunger Before (1-5)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          _RatingRow(
            value: _hungerBefore,
            labels: const ['Not hungry', 'Slightly', 'Moderate', 'Hungry', 'Starving'],
            onChanged: (v) => setState(() => _hungerBefore = v),
          ),
          const SizedBox(height: 16),

          // Add food items section
          Text('Food Items', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _foodNameController,
                    decoration: const InputDecoration(
                      labelText: 'Food name',
                      prefixIcon: Icon(Icons.restaurant),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<FoodCategory>(
                    value: _foodCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: FoodCategory.values.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.label));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _foodCategory = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _caloriesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Calories',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _proteinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Protein (g)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _carbsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Carbs (g)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _fatController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Fat (g)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Food Item'),
                      onPressed: _addFoodItem,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Current food items list
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.calories.toStringAsFixed(0)} cal · '
                    'P ${item.proteinG.toStringAsFixed(0)}g · '
                    'C ${item.carbsG.toStringAsFixed(0)}g · '
                    'F ${item.fatG.toStringAsFixed(0)}g',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => setState(() => _items.removeAt(idx)),
                  ),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Total: ${_items.fold(0.0, (s, i) => s + i.calories).toStringAsFixed(0)} cal',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Fullness after
          Text('Fullness After (1-5)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          _RatingRow(
            value: _fullnessAfter,
            labels: const ['Still hungry', 'Light', 'Satisfied', 'Full', 'Stuffed'],
            onChanged: (v) => setState(() => _fullnessAfter = v),
          ),
          const SizedBox(height: 12),

          // Notes
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              icon: const Icon(Icons.check),
              label: Text('Log ${_selectedType.label}'),
              onPressed: _items.isNotEmpty ? _saveMeal : null,
            ),
          ),

          // Quick-add from frequent foods
          if (widget.service.entries.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('⚡ Frequent Foods', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.service.getFrequentFoods(limit: 8).map((ff) {
                return ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text('${ff.food.name} (${ff.food.calories.toStringAsFixed(0)} cal)'),
                  onPressed: () {
                    setState(() => _items.add(ff.food));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added ${ff.food.name}')),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── DAILY MEALS TAB ────────────────────────────────────────────────────────

class _DailyMealsTab extends StatelessWidget {
  final MealTrackerService service;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onChanged;

  const _DailyMealsTab({
    required this.service,
    required this.date,
    required this.onDateChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meals = service.getMealsForDate(date);
    final summary = service.getDailySummary(date);

    return Column(
      children: [
        // Date navigator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onDateChanged(
                  date.subtract(const Duration(days: 1)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) onDateChanged(picked);
                },
                child: Text(
                  _formatDate(date),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: date.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                    ? () => onDateChanged(date.add(const Duration(days: 1)))
                    : null,
              ),
            ],
          ),
        ),

        // Quick summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat('Calories', '${summary.totalCalories.toStringAsFixed(0)}', Icons.local_fire_department),
              _MiniStat('Protein', '${summary.totalProtein.toStringAsFixed(0)}g', Icons.egg),
              _MiniStat('Carbs', '${summary.totalCarbs.toStringAsFixed(0)}g', Icons.grain),
              _MiniStat('Fat', '${summary.totalFat.toStringAsFixed(0)}g', Icons.opacity),
            ],
          ),
        ),

        // Meals list
        Expanded(
          child: meals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.no_meals, size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text('No meals logged', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text('Tap the Log tab to add a meal',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return _MealCard(
                      meal: meal,
                      onDelete: () {
                        service.removeMeal(meal.id);
                        onChanged();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    if (target == today) return 'Today';
    if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ─── NUTRITION TAB ──────────────────────────────────────────────────────────

class _NutritionTab extends StatelessWidget {
  final MealTrackerService service;
  final DateTime date;

  const _NutritionTab({required this.service, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = service.getDailySummary(date);
    final config = service.config;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grade badge
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gradeColor(summary.grade).withOpacity(0.15),
                border: Border.all(color: _gradeColor(summary.grade), width: 3),
              ),
              child: Center(
                child: Text(
                  summary.grade,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: _gradeColor(summary.grade),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Daily Nutrition Grade',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),

          // Macro progress bars
          _NutrientProgress(
            label: 'Calories',
            current: summary.totalCalories,
            goal: config.dailyCalorieGoal.toDouble(),
            unit: 'kcal',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _NutrientProgress(
            label: 'Protein',
            current: summary.totalProtein,
            goal: config.proteinGoalG.toDouble(),
            unit: 'g',
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _NutrientProgress(
            label: 'Carbs',
            current: summary.totalCarbs,
            goal: config.carbsGoalG.toDouble(),
            unit: 'g',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _NutrientProgress(
            label: 'Fat',
            current: summary.totalFat,
            goal: config.fatGoalG.toDouble(),
            unit: 'g',
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          _NutrientProgress(
            label: 'Fiber',
            current: summary.totalFiber,
            goal: config.fiberGoalG.toDouble(),
            unit: 'g',
            color: Colors.green,
          ),
          const SizedBox(height: 24),

          // Macro ratio pie-like display
          Text('Macro Split', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _MacroSplitBar(ratio: summary.macroRatio),
          const SizedBox(height: 16),

          // Calories by meal type
          if (summary.caloriesByMeal.isNotEmpty) ...[
            Text('Calories by Meal', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...summary.caloriesByMeal.entries.map((e) {
              final pct = summary.totalCalories > 0
                  ? (e.value / summary.totalCalories * 100)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${e.key.emoji} ${e.key.label}'),
                    const Spacer(),
                    Text('${e.value.toStringAsFixed(0)} kcal (${pct.toStringAsFixed(0)}%)'),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A': return Colors.green;
      case 'B': return Colors.lightGreen;
      case 'C': return Colors.orange;
      case 'D': return Colors.deepOrange;
      default: return Colors.red;
    }
  }
}

// ─── INSIGHTS TAB ───────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final MealTrackerService service;

  const _InsightsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = service.generateReport();
    final insights = report.insights;
    final streak = report.loggingStreak;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak card
          Card(
            color: streak >= 3 ? Colors.orange.shade50 : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    streak >= 3 ? Icons.local_fire_department : Icons.restaurant_menu,
                    size: 40,
                    color: streak >= 3 ? Colors.orange : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streak day${streak == 1 ? '' : 's'}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Logging streak',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text('${report.totalEntries}',
                            style: theme.textTheme.headlineSmall),
                        Text('Total Meals', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(report.today?.grade ?? '-',
                            style: theme.textTheme.headlineSmall),
                        Text('Today\'s Grade', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Insights
          Text('💡 Insights', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (insights.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Log some meals to see personalized insights!',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            ...insights.map((insight) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(insight)),
                  ],
                ),
              ),
            )),

          // Top foods
          if (report.topFoods.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('🏆 Most Logged Foods', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...report.topFoods.map((ff) => ListTile(
              leading: CircleAvatar(child: Text('${ff.count}x')),
              title: Text(ff.food.name),
              subtitle: Text(
                '${ff.food.calories.toStringAsFixed(0)} cal · ${ff.food.category.label}',
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// ─── HELPER WIDGETS ─────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final int? value;
  final List<String> labels;
  final ValueChanged<int?> onChanged;

  const _RatingRow({
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final rating = i + 1;
        final selected = value == rating;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(selected ? null : rating),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '$rating',
                    style: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: selected ? FontWeight.bold : null,
                    ),
                  ),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 9,
                      color: selected ? Colors.white70 : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onDelete;

  const _MealCard({required this.meal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = '${meal.timestamp.hour.toString().padLeft(2, '0')}:${meal.timestamp.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: Text(meal.type.emoji, style: const TextStyle(fontSize: 24)),
        title: Text('${meal.type.label} · $time'),
        subtitle: Text(
          '${meal.totalCalories.toStringAsFixed(0)} cal · ${meal.items.length} item${meal.items.length == 1 ? '' : 's'}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete meal?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onDelete();
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
        children: [
          ...meal.items.map((item) => ListTile(
            dense: true,
            title: Text(item.name),
            subtitle: Text('${item.category.label}'),
            trailing: Text('${item.totalCalories.toStringAsFixed(0)} cal'),
          )),
          if (meal.hungerBefore != null || meal.fullnessAfter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  if (meal.hungerBefore != null)
                    Text('Hunger: ${meal.hungerBefore}/5',
                        style: theme.textTheme.bodySmall),
                  if (meal.hungerBefore != null && meal.fullnessAfter != null)
                    const Text(' · '),
                  if (meal.fullnessAfter != null)
                    Text('Fullness: ${meal.fullnessAfter}/5',
                        style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          if (meal.notes != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(meal.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }
}

class _NutrientProgress extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final String unit;
  final Color color;

  const _NutrientProgress({
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal > 0 ? (current / goal).clamp(0.0, 1.5) : 0.0;
    final displayPct = goal > 0 ? (current / goal * 100) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '${current.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit (${displayPct.toStringAsFixed(0)}%)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0).toDouble(),
            minHeight: 8,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(
              displayPct > 120 ? Colors.red : color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MacroSplitBar extends StatelessWidget {
  final Map<String, double> ratio;

  const _MacroSplitBar({required this.ratio});

  @override
  Widget build(BuildContext context) {
    final protein = ratio['protein'] ?? 0;
    final carbs = ratio['carbs'] ?? 0;
    final fat = ratio['fat'] ?? 0;
    final total = protein + carbs + fat;

    if (total == 0) {
      return const Text('No data yet', style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 24,
            child: Row(
              children: [
                if (protein > 0)
                  Expanded(
                    flex: protein.round(),
                    child: Container(color: Colors.red.shade300),
                  ),
                if (carbs > 0)
                  Expanded(
                    flex: carbs.round(),
                    child: Container(color: Colors.blue.shade300),
                  ),
                if (fat > 0)
                  Expanded(
                    flex: fat.round(),
                    child: Container(color: Colors.amber.shade300),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _MacroLabel('Protein', '${protein.toStringAsFixed(0)}%', Colors.red.shade300),
            _MacroLabel('Carbs', '${carbs.toStringAsFixed(0)}%', Colors.blue.shade300),
            _MacroLabel('Fat', '${fat.toStringAsFixed(0)}%', Colors.amber.shade300),
          ],
        ),
      ],
    );
  }
}

class _MacroLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroLabel(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label $value', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
