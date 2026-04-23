import 'package:flutter/material.dart';
import '../../core/services/digital_detox_service.dart';

/// Smart Digital Detox Planner — autonomous screen time analysis with
/// pattern detection, proactive insights, detox scheduling, and
/// adaptive plan generation.
class DigitalDetoxScreen extends StatefulWidget {
  const DigitalDetoxScreen({super.key});

  @override
  State<DigitalDetoxScreen> createState() => _DigitalDetoxScreenState();
}

class _DigitalDetoxScreenState extends State<DigitalDetoxScreen>
    with SingleTickerProviderStateMixin {
  final DigitalDetoxService _service = DigitalDetoxService();
  late TabController _tabController;
  int _targetReduction = 20;

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
        title: const Text('📵 Digital Detox'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.grid_on), text: 'Patterns'),
            Tab(icon: Icon(Icons.auto_fix_high), text: 'Plan'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DashboardTab(service: _service),
          _PatternsTab(service: _service),
          _PlanTab(
            service: _service,
            targetReduction: _targetReduction,
            onTargetChanged: (v) => setState(() => _targetReduction = v),
          ),
          _HistoryTab(service: _service),
        ],
      ),
    );
  }
}

// ─── DASHBOARD TAB ─────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  final DigitalDetoxService service;
  const _DashboardTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = service.getHealthScore();
    final streak = service.getStreakInfo();
    final insights = service.getProactiveInsights();

    Color scoreColor;
    if (score >= 70) {
      scoreColor = Colors.green;
    } else if (score >= 40) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Health score
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Detox Health Score',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 10,
                          backgroundColor: scoreColor.withAlpha(40),
                          valueColor: AlwaysStoppedAnimation(scoreColor),
                        ),
                      ),
                      Text('$score',
                          style: theme.textTheme.headlineLarge
                              ?.copyWith(color: scoreColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  score >= 70
                      ? 'Great digital balance!'
                      : score >= 40
                          ? 'Room for improvement'
                          : 'Needs attention',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Streak & Stats row
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text('${streak.current}',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Day Streak', style: theme.textTheme.bodySmall),
                  ]),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    const Text('🏆', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text('${streak.longest}',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Best Streak', style: theme.textTheme.bodySmall),
                  ]),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    const Text('🎯', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text('${(streak.successRate * 100).round()}%',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Success', style: theme.textTheme.bodySmall),
                  ]),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Daily average
        Card(
          child: ListTile(
            leading: const Icon(Icons.phone_android, size: 32),
            title: Text('${service.totalDailyAverage} min/day',
                style: theme.textTheme.titleMedium),
            subtitle: const Text('Average daily screen time'),
            trailing: Text(
              '${(service.totalDailyAverage / 60).toStringAsFixed(1)}h',
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Proactive Insights
        Text('🧠 Proactive Insights',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...insights.map((insight) {
          Color borderColor;
          switch (insight.severity) {
            case InsightSeverity.positive:
              borderColor = Colors.green;
            case InsightSeverity.neutral:
              borderColor = Colors.blue;
            case InsightSeverity.warning:
              borderColor = Colors.orange;
            case InsightSeverity.critical:
              borderColor = Colors.red;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: 1.5),
              ),
              child: ListTile(
                leading: Text(insight.icon, style: const TextStyle(fontSize: 24)),
                title: Text(insight.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(insight.body),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── PATTERNS TAB ──────────────────────────────────────────────────────────

class _PatternsTab extends StatelessWidget {
  final DigitalDetoxService service;
  const _PatternsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grid = service.usageGrid;
    final dayTotals = service.dayTotals;
    final maxDay = dayTotals.reduce((a, b) => a > b ? a : b);

    // Find max cell value for heatmap scaling
    int maxCell = 1;
    for (final row in grid) {
      for (final v in row) {
        if (v > maxCell) maxCell = v;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('📊 Usage Heatmap',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Hours (6 AM – 11 PM) × Days of Week',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),

        // Heatmap grid
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Hour labels
                Row(
                  children: [
                    const SizedBox(width: 32),
                    ...List.generate(17, (i) {
                      final h = i + 6;
                      return Expanded(
                        child: Center(
                          child: Text(
                            h % 3 == 0 ? '${h > 12 ? h - 12 : h}${h >= 12 ? 'p' : 'a'}' : '',
                            style: const TextStyle(fontSize: 9),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 4),
                // Grid rows
                ...List.generate(7, (d) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(service.dayName(d),
                              style: const TextStyle(fontSize: 10)),
                        ),
                        ...List.generate(17, (i) {
                          final h = i + 6;
                          final val = grid[d][h];
                          final intensity = (val / maxCell).clamp(0.0, 1.0);
                          return Expanded(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                margin: const EdgeInsets.all(0.5),
                                decoration: BoxDecoration(
                                  color: Color.lerp(
                                    Colors.green.shade50,
                                    Colors.red.shade700,
                                    intensity,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Low ', style: TextStyle(fontSize: 10)),
                    ...List.generate(5, (i) {
                      return Container(
                        width: 16,
                        height: 10,
                        color: Color.lerp(
                          Colors.green.shade50,
                          Colors.red.shade700,
                          i / 4,
                        ),
                      );
                    }),
                    const Text(' High', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Day-of-week bars
        Text('📅 Daily Usage',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: List.generate(7, (d) {
                final total = dayTotals[d];
                final fraction = maxDay > 0 ? total / maxDay : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(service.dayName(d),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 14,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            fraction > 0.8 ? Colors.red : fraction > 0.6 ? Colors.orange : Colors.green,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 52,
                        child: Text('${(total / 60).toStringAsFixed(1)}h',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── PLAN TAB ──────────────────────────────────────────────────────────────

class _PlanTab extends StatelessWidget {
  final DigitalDetoxService service;
  final int targetReduction;
  final ValueChanged<int> onTargetChanged;

  const _PlanTab({
    required this.service,
    required this.targetReduction,
    required this.onTargetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = service.generatePlan(targetReduction);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('🤖 Auto-Generated Detox Plan',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('AI analyzes your usage patterns and creates optimal detox blocks.',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),

        // Target slider
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Target Reduction: $targetReduction%',
                    style: theme.textTheme.titleSmall),
                Slider(
                  value: targetReduction.toDouble(),
                  min: 10,
                  max: 50,
                  divisions: 8,
                  label: '$targetReduction%',
                  onChanged: (v) => onTargetChanged(v.round()),
                ),
                Text(plan.strategy, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Predicted outcome
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Predicted Outcome',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '${plan.weeklyTargetMinutes} min/week detox '
                        '(~${plan.predictedReduction.toStringAsFixed(1)}% reduction)',
                      ),
                      Text('${plan.blocks.length} scheduled blocks across the week',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Schedule blocks
        Text('📋 Weekly Schedule (${plan.blocks.length} blocks)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        if (plan.blocks.isEmpty)
          const Card(child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No blocks needed — your usage is already low!'),
          ))
        else
          ...plan.blocks.take(15).map((block) {
            final dayNames = const ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text(dayNames[block.dayOfWeek].substring(0, 1),
                      style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
                ),
                title: Text(block.label),
                subtitle: Text(
                  '${dayNames[block.dayOfWeek]} · ${service.hourName(block.startHour)} · ${block.durationMinutes} min',
                ),
                trailing: Icon(Icons.phone_disabled,
                    color: theme.colorScheme.primary, size: 20),
              ),
            );
          }),

        if (plan.blocks.length > 15)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('... and ${plan.blocks.length - 15} more blocks',
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ),
      ],
    );
  }
}

// ─── HISTORY TAB ───────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final DigitalDetoxService service;
  const _HistoryTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = [...service.sessions]
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final streak = service.getStreakInfo();

    final totalDetoxMin = sorted.fold<int>(0, (s, e) => s + e.actualMinutes);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCol('Total', '${(totalDetoxMin / 60).toStringAsFixed(1)}h', '🕐'),
                _StatCol('Sessions', '${sorted.length}', '📊'),
                _StatCol('Avg Length',
                    sorted.isEmpty
                        ? '0'
                        : '${(totalDetoxMin / sorted.length).round()}m',
                    '⏱️'),
                _StatCol('Success',
                    '${(streak.successRate * 100).round()}%',
                    streak.successRate >= 0.7 ? '📈' : '📉'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text('📜 Session History',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        ...sorted.map((session) {
          final date = session.startTime;
          final dateStr = '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: session.completed ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(
                  session.completed ? Icons.check : Icons.close,
                  color: session.completed ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              title: Text(session.name),
              subtitle: Text(
                '$dateStr · ${session.actualMinutes}/${session.targetMinutes} min'
                '${session.distractions.isNotEmpty ? ' · ${session.distractions.length} distractions' : ''}',
              ),
              trailing: Text(
                '${(session.adherenceRate * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: session.completed ? Colors.green : Colors.red,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _StatCol(this.label, this.value, this.emoji);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
