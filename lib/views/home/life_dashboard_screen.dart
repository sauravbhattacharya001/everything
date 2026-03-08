import 'package:flutter/material.dart';
import 'dart:math' show pi;
import '../../core/services/life_dashboard_service.dart';
import '../../models/water_entry.dart';
import '../../models/sleep_entry.dart';
import '../../models/energy_entry.dart';
import '../../models/mood_entry.dart';
import '../../models/workout_entry.dart';
import '../../models/meal_entry.dart';
import '../../models/meditation_entry.dart';
import '../../models/habit.dart';
import '../../models/expense_entry.dart';
import '../../models/screen_time_entry.dart';

/// Life Dashboard — a unified wellness overview aggregating data from
/// all trackers into a single composite "Life Score" with per-dimension
/// breakdowns, 7-day trends, streaks, and actionable insights.
class LifeDashboardScreen extends StatefulWidget {
  const LifeDashboardScreen({super.key});

  @override
  State<LifeDashboardScreen> createState() => _LifeDashboardScreenState();
}

class _LifeDashboardScreenState extends State<LifeDashboardScreen>
    with SingleTickerProviderStateMixin {
  final LifeDashboardService _service = const LifeDashboardService();
  late TabController _tabController;
  LifeDashboardData? _data;
  int _lookbackDays = 7;

  // ── Demo data lists (in a real app these come from persistent storage) ──
  final List<SleepEntry> _sleepEntries = [];
  final List<WaterEntry> _waterEntries = [];
  final List<EnergyEntry> _energyEntries = [];
  final List<MoodEntry> _moodEntries = [];
  final List<WorkoutEntry> _workoutEntries = [];
  final List<MealEntry> _mealEntries = [];
  final List<MeditationEntry> _meditationEntries = [];
  final List<Habit> _habits = [];
  final List<HabitCompletion> _completions = [];
  final List<ExpenseEntry> _expenseEntries = [];
  final List<ScreenTimeEntry> _screenTimeEntries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _generateSampleData();
    _recompute();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _recompute() {
    setState(() {
      _data = _service.compute(
        sleepEntries: _sleepEntries,
        waterEntries: _waterEntries,
        energyEntries: _energyEntries,
        moodEntries: _moodEntries,
        workoutEntries: _workoutEntries,
        mealEntries: _mealEntries,
        meditationEntries: _meditationEntries,
        habits: _habits,
        completions: _completions,
        expenseEntries: _expenseEntries,
        screenTimeEntries: _screenTimeEntries,
        lookbackDays: _lookbackDays,
      );
    });
  }

  void _generateSampleData() {
    final now = DateTime.now();
    int sid = 1;

    for (int i = 0; i < 10; i++) {
      final day = now.subtract(Duration(days: i));
      final bedtime = DateTime(day.year, day.month, day.day, 22 + (i % 3), 30);
      final wakeTime = bedtime.add(Duration(hours: 6 + (i % 4), minutes: 30));
      _sleepEntries.add(SleepEntry(
        id: 's${sid++}',
        bedtime: bedtime,
        wakeTime: wakeTime,
        quality: SleepQuality.values[(2 + i % 3).clamp(0, 4)],
      ));
    }

    for (int i = 0; i < 14; i++) {
      final day = now.subtract(Duration(days: i ~/ 2));
      _waterEntries.add(WaterEntry(
        id: 'w${sid++}',
        timestamp: day.subtract(Duration(hours: 8 - i % 5)),
        amountMl: 250 + (i % 4) * 100,
        drinkType: DrinkType.water,
        containerSize: ContainerSize.medium,
      ));
    }

    for (int i = 0; i < 8; i++) {
      final day = now.subtract(Duration(days: i));
      _energyEntries.add(EnergyEntry(
        id: 'e${sid++}',
        timestamp: day.subtract(const Duration(hours: 6)),
        level: EnergyLevel.values[(1 + i % 4).clamp(0, 4)],
      ));
    }

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      _moodEntries.add(MoodEntry(
        id: 'm${sid++}',
        timestamp: day.subtract(const Duration(hours: 4)),
        mood: MoodLevel.values[(1 + i % 4).clamp(0, 4)],
      ));
    }

    for (int i = 0; i < 5; i++) {
      final day = now.subtract(Duration(days: i * 2));
      _workoutEntries.add(WorkoutEntry(
        id: 'wo${sid++}',
        name: ['Running', 'Weights', 'Yoga', 'Swimming', 'HIIT'][i],
        startTime: day.subtract(const Duration(hours: 14)),
        endTime: day.subtract(Duration(hours: 14 - (i % 2 == 0 ? 1 : 0), minutes: 45 - i * 5)),
      ));
    }

    for (int i = 0; i < 12; i++) {
      final day = now.subtract(Duration(days: i ~/ 2));
      _mealEntries.add(MealEntry(
        id: 'ml${sid++}',
        timestamp: day.subtract(Duration(hours: 6 + (i % 3) * 5)),
        items: [
          FoodItem(
            name: ['Oatmeal', 'Salad', 'Chicken', 'Pasta', 'Rice'][i % 5],
            category: FoodCategory.values[i % FoodCategory.values.length],
            calories: 300 + (i % 4) * 100,
            proteinG: 10 + i * 2,
            carbsG: 30 + i * 3,
            fatG: 5 + i,
          ),
        ],
        type: MealType.values[i % 3],
      ));
    }

    for (int i = 0; i < 4; i++) {
      final day = now.subtract(Duration(days: i * 2));
      _meditationEntries.add(MeditationEntry(
        id: 'md${sid++}',
        dateTime: day.subtract(const Duration(hours: 7)),
        durationMinutes: 10 + i * 5,
        type: MeditationType.values[i % MeditationType.values.length],
      ));
    }

    _habits.addAll([
      Habit(
        id: 'h1',
        name: 'Read 30 min',
        emoji: '📚',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Habit(
        id: 'h2',
        name: 'Meditate',
        emoji: '🧘',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ]);

    for (int i = 0; i < 5; i++) {
      _completions.add(HabitCompletion(
        habitId: 'h1',
        date: now.subtract(Duration(days: i)),
      ));
    }

    for (int i = 0; i < 6; i++) {
      final day = now.subtract(Duration(days: i));
      _expenseEntries.add(ExpenseEntry(
        id: 'ex${sid++}',
        timestamp: day,
        amount: 10 + i * 5.5,
        category: ExpenseCategory.values[i % ExpenseCategory.values.length],
        paymentMethod:
            PaymentMethod.values[i % PaymentMethod.values.length],
      ));
    }

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      _screenTimeEntries.add(ScreenTimeEntry(
        id: 'st${sid++}',
        date: day,
        appName: ['Twitter', 'Instagram', 'YouTube', 'Reddit', 'Chrome',
                  'Slack', 'VS Code'][i],
        category: AppCategory.values[i % AppCategory.values.length],
        durationMinutes: 30 + i * 20,
        pickups: 5 + i * 2,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Dimensions'),
            Tab(icon: Icon(Icons.show_chart), text: 'Trends'),
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Insights'),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            tooltip: 'Lookback period',
            onSelected: (days) {
              _lookbackDays = days;
              _recompute();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 3, child: Text('3 days')),
              const PopupMenuItem(value: 7, child: Text('7 days')),
              const PopupMenuItem(value: 14, child: Text('14 days')),
              const PopupMenuItem(value: 30, child: Text('30 days')),
            ],
          ),
        ],
      ),
      body: _data == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDimensionsTab(),
                _buildTrendsTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  TAB 1 — Overview
  // ══════════════════════════════════════════════════════════════

  Widget _buildOverviewTab() {
    final data = _data!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Big score ring
          _ScoreRing(score: data.overallScore, label: data.overallLabel),
          const SizedBox(height: 24),

          // Quick dimension grid
          Text('Dimensions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.8,
            children: data.dimensions.map((d) {
              return _DimensionChip(dimension: d);
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Streaks
          Text('Active Streaks',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: data.streaks.entries
                .where((e) => e.value > 0)
                .map((e) => Chip(
                      avatar: Text(_streakEmoji(e.key)),
                      label: Text('${_capitalize(e.key)}: ${e.value}d'),
                    ))
                .toList(),
          ),
          if (data.streaks.values.every((v) => v == 0))
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No active streaks — start logging today!',
                  style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  TAB 2 — Dimensions detail
  // ══════════════════════════════════════════════════════════════

  Widget _buildDimensionsTab() {
    final data = _data!;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.dimensions.length,
      itemBuilder: (ctx, i) {
        final d = data.dimensions[i];
        final trend = data.trends[d.name.toLowerCase().replaceAll(' ', '_')];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(d.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(d.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const Spacer(),
                              if (trend != null) _trendIcon(trend),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _scoreColor(d.score).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${d.score.round()}%',
                                  style: TextStyle(
                                    color: _scoreColor(d.score),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(d.detail,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: d.score / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation(_scoreColor(d.score)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(d.label,
                    style: TextStyle(
                        color: _scoreColor(d.score),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  TAB 3 — Trends (7-day chart)
  // ══════════════════════════════════════════════════════════════

  Widget _buildTrendsTab() {
    final data = _data!;
    if (data.history.isEmpty) {
      return const Center(child: Text('No history yet'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overall Score — Last $_lookbackDays Days',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _TrendChartPainter(
                snapshots: data.history,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Dimension trend indicators
          Text('Dimension Trends',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...data.trends.entries
              .where((e) => e.key != 'overall')
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        _trendIcon(e.value),
                        const SizedBox(width: 12),
                        Text(_capitalize(e.key)),
                        const Spacer(),
                        Text(
                          e.value == Trend.rising
                              ? 'Improving'
                              : e.value == Trend.falling
                                  ? 'Declining'
                                  : 'Stable',
                          style: TextStyle(
                            color: e.value == Trend.rising
                                ? Colors.green
                                : e.value == Trend.falling
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  TAB 4 — Insights
  // ══════════════════════════════════════════════════════════════

  Widget _buildInsightsTab() {
    final data = _data!;
    if (data.insights.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb_outline, size: 48, color: Colors.amber),
            SizedBox(height: 16),
            Text('Log more data to unlock insights'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: data.insights.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (ctx, i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            data.insights[i],
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  Helpers
  // ══════════════════════════════════════════════════════════════

  Widget _trendIcon(Trend trend) {
    switch (trend) {
      case Trend.rising:
        return const Icon(Icons.trending_up, color: Colors.green, size: 20);
      case Trend.falling:
        return const Icon(Icons.trending_down, color: Colors.red, size: 20);
      case Trend.stable:
        return const Icon(Icons.trending_flat, color: Colors.grey, size: 20);
    }
  }

  Color _scoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.amber;
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }

  String _streakEmoji(String key) {
    switch (key) {
      case 'sleep':
        return '😴';
      case 'hydration':
        return '💧';
      case 'exercise':
        return '🏋️';
      case 'mindfulness':
        return '🧘';
      default:
        return '🔥';
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Custom Widgets
// ═══════════════════════════════════════════════════════════════════

/// Circular score ring with animated-feel display.
class _ScoreRing extends StatelessWidget {
  final double score;
  final String label;

  const _ScoreRing({required this.score, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(score);
    return SizedBox(
      width: 180,
      height: 180,
      child: CustomPaint(
        painter: _RingPainter(score: score, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.round()}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w500)),
              const Text('Life Score',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorFor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.amber;
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }
}

class _RingPainter extends CustomPainter {
  final double score;
  final Color color;

  _RingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..color = Colors.grey[200]!,
    );

    // Score arc
    final sweep = (score / 100) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.score != score || old.color != color;
}

/// Compact dimension chip for the overview grid.
class _DimensionChip extends StatelessWidget {
  final DimensionScore dimension;

  const _DimensionChip({required this.dimension});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _colorFor(dimension.score).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _colorFor(dimension.score).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(dimension.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dimension.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                Text('${dimension.score.round()}% · ${dimension.label}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.amber;
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }
}

/// Simple line chart painter for the trends tab.
class _TrendChartPainter extends CustomPainter {
  final List<DailySnapshot> snapshots;
  final Color color;

  _TrendChartPainter({required this.snapshots, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshots.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    final textStyle = TextStyle(color: Colors.grey[500], fontSize: 10);

    // Draw grid lines at 0, 25, 50, 75, 100
    for (int g = 0; g <= 100; g += 25) {
      final y = size.height - (g / 100 * size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      // Label
      final tp = TextPainter(
        text: TextSpan(text: '$g', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-2, y - tp.height / 2));
    }

    // Plot points
    final n = snapshots.length;
    final dx = n > 1 ? size.width / (n - 1) : size.width / 2;

    final path = Path();
    for (int i = 0; i < n; i++) {
      final x = n > 1 ? i * dx : size.width / 2;
      final y = size.height - (snapshots[i].overallScore / 100 * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);

      // Day label
      final day = snapshots[i].date;
      final label = '${day.month}/${day.day}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height + 4));
    }

    canvas.drawPath(path, paint);

    // Fill area under the curve
    final fillPath = Path.from(path)
      ..lineTo(n > 1 ? (n - 1) * dx : size.width / 2, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()..color = color.withOpacity(0.1),
    );
  }

  @override
  bool shouldRepaint(_TrendChartPainter old) =>
      old.snapshots != snapshots || old.color != color;
}
