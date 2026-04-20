import 'package:flutter/material.dart';
import '../../core/services/habit_insights_service.dart';

/// Smart Habit Insights — autonomous habit pattern analysis with
/// correlations, streak forecasting, optimal timing, and proactive
/// recommendations.
///
/// 4 tabs: Insights · Correlations · Health · Forecast
class HabitInsightsScreen extends StatefulWidget {
  const HabitInsightsScreen({super.key});

  @override
  State<HabitInsightsScreen> createState() => _HabitInsightsScreenState();
}

class _HabitInsightsScreenState extends State<HabitInsightsScreen>
    with SingleTickerProviderStateMixin {
  final HabitInsightsService _service = HabitInsightsService();
  late TabController _tabController;

  late final _habits = _service.getDemoHabits();
  late final _insights = _service.generateInsights(_habits);
  late final _correlations = _service.analyzeCorrelations(_habits);
  late final _health = _service.calculateHealthScores(_habits);
  late final _forecasts = _service.forecastStreaks(_habits);
  late final _timing = _service.analyzeTimingPatterns(_habits);
  late final _summary = _service.getSummary(_habits);

  InsightType? _insightFilter;

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

  // ─── Insights tab ────────────────────────────────────────────────

  Widget _buildInsightsTab() {
    final filtered = _insightFilter == null
        ? _insights
        : _insights.where((i) => i.type == _insightFilter).toList();

    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _filterChip('All', null),
              ...InsightType.values.map((t) => _filterChip(_typeName(t), t)),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No insights match this filter'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _insightCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, InsightType? type) {
    final selected = _insightFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _insightFilter = selected ? null : type),
      ),
    );
  }

  Widget _insightCard(HabitInsight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(insight.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(insight.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                _priorityBadge(insight.priority),
              ],
            ),
            const SizedBox(height: 6),
            Text(insight.description, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 8),
            // Confidence bar
            Row(
              children: [
                const Text('Confidence ', style: TextStyle(fontSize: 11)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: insight.confidence,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      color: insight.confidence > 0.7
                          ? Colors.green
                          : insight.confidence > 0.4
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('${(insight.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11)),
              ],
            ),
            if (insight.actionable && insight.action != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: Text(insight.action!, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _priorityBadge(InsightPriority p) {
    final (color, label) = switch (p) {
      InsightPriority.critical => (Colors.red, 'CRITICAL'),
      InsightPriority.high => (Colors.orange, 'HIGH'),
      InsightPriority.medium => (Colors.blue, 'MED'),
      InsightPriority.low => (Colors.grey, 'LOW'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  // ─── Correlations tab ────────────────────────────────────────────

  Widget _buildCorrelationsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _correlations.length,
      itemBuilder: (_, i) => _correlationCard(_correlations[i]),
    );
  }

  Widget _correlationCard(HabitCorrelation c) {
    final barColor = c.direction == 'positive'
        ? Colors.green
        : c.direction == 'negative'
            ? Colors.red
            : Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${c.habitA}  ↔  ${c.habitB}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Text(c.correlationScore.toStringAsFixed(2),
                    style: TextStyle(fontWeight: FontWeight.bold, color: barColor, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            // Correlation bar from -1 to +1
            Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  alignment: c.correlationScore >= 0 ? Alignment.centerLeft : Alignment.centerRight,
                  widthFactor: 0.5,
                  child: Align(
                    alignment: c.correlationScore >= 0 ? Alignment.centerRight : Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: c.correlationScore.abs(),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('-1', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('0', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('+1', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            Text(c.description, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  // ─── Health tab ──────────────────────────────────────────────────

  Widget _buildHealthTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Summary card
        Card(
          color: _gradeColor(_summary.healthGrade).withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gradeColor(_summary.healthGrade),
                  ),
                  alignment: Alignment.center,
                  child: Text(_summary.healthGrade,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overall Grade: ${_summary.healthGrade}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                          '${_summary.totalHabits} habits · ${(_summary.avgCompletionRate * 100).toStringAsFixed(0)}% avg completion'),
                      Text('Strongest: ${_summary.strongestHabit}',
                          style: const TextStyle(fontSize: 12)),
                      Text('Weakest: ${_summary.weakestHabit}',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Health cards grid
        ...List.generate((_health.length / 2).ceil(), (row) {
          final idx = row * 2;
          return Row(
            children: [
              Expanded(child: _healthCard(_health[idx])),
              const SizedBox(width: 8),
              if (idx + 1 < _health.length)
                Expanded(child: _healthCard(_health[idx + 1]))
              else
                const Expanded(child: SizedBox()),
            ],
          );
        }),
      ],
    );
  }

  Widget _healthCard(HabitHealthScore h) {
    final color = h.score > 70 ? Colors.green : h.score > 40 ? Colors.orange : Colors.red;
    final trendIcon = h.trend == 'up'
        ? Icons.trending_up
        : h.trend == 'down'
            ? Icons.trending_down
            : Icons.trending_flat;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: h.score / 100,
                    strokeWidth: 5,
                    backgroundColor: Colors.grey[200],
                    color: color,
                  ),
                ),
                Text('${h.score}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${h.emoji} ${h.habitName}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Icon(trendIcon, size: 14, color: color),
              ],
            ),
            const SizedBox(height: 4),
            ...h.factors.take(2).map((f) => Text(f,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }

  // ─── Forecast tab ────────────────────────────────────────────────

  Widget _buildForecastTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _forecasts.length,
      itemBuilder: (_, i) {
        final f = _forecasts[i];
        final t = _timing.firstWhere((tp) => tp.habitName == f.habitName,
            orElse: () => _timing.first);
        return _forecastCard(f, t);
      },
    );
  }

  Widget _forecastCard(StreakForecast f, TimingProfile t) {
    final total = f.currentStreak + f.predictedDays;
    final currentFrac = total == 0 ? 0.0 : f.currentStreak / total;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${f.emoji} ${f.habitName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Text('🔥 ${f.currentStreak}d → +${f.predictedDays}d',
                    style: TextStyle(fontSize: 13, color: Colors.orange[700])),
              ],
            ),
            const SizedBox(height: 8),
            // Streak bar
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    Expanded(
                      flex: (currentFrac * 100).round().clamp(1, 100),
                      child: Container(color: Colors.orange),
                    ),
                    Expanded(
                      flex: ((1 - currentFrac) * 100).round().clamp(1, 100),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.3),
                          border: Border.all(color: Colors.orange.withOpacity(0.5), width: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Current: ${f.currentStreak}d', style: const TextStyle(fontSize: 10)),
                Text('Predicted: +${f.predictedDays}d',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                Text('Conf: ${(f.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 10)),
              ],
            ),
            if (f.riskFactors.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...f.riskFactors.map((r) => Row(
                    children: [
                      const Icon(Icons.warning_amber, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(r, style: const TextStyle(fontSize: 11, color: Colors.orange))),
                    ],
                  )),
            ],
            // Mini heatmap for day-of-week
            const SizedBox(height: 8),
            Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                final rate = t.completionByDay[day] ?? 0;
                final color = Color.lerp(Colors.grey[200], Colors.green[700], rate)!;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      children: [
                        Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          alignment: Alignment.center,
                          child: Text('${(rate * 100).round()}',
                              style: TextStyle(
                                  fontSize: 8,
                                  color: rate > 0.5 ? Colors.white : Colors.black54)),
                        ),
                        Text(day, style: const TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  String _typeName(InsightType t) => switch (t) {
        InsightType.correlation => 'Correlations',
        InsightType.streakForecast => 'Streaks',
        InsightType.optimalTiming => 'Timing',
        InsightType.risk => 'Risks',
        InsightType.celebration => 'Wins',
        InsightType.suggestion => 'Tips',
      };

  Color _gradeColor(String g) => switch (g) {
        'A' => Colors.green,
        'B' => Colors.lightGreen,
        'C' => Colors.orange,
        'D' => Colors.deepOrange,
        _ => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Smart Habit Insights'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Insights'),
            Tab(text: 'Correlations'),
            Tab(text: 'Health'),
            Tab(text: 'Forecast'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInsightsTab(),
          _buildCorrelationsTab(),
          _buildHealthTab(),
          _buildForecastTab(),
        ],
      ),
    );
  }
}
