import 'package:flutter/material.dart';
import '../../core/data/productivity_sample_data.dart';
import '../../core/services/productivity_score_service.dart';

/// Productivity Score Dashboard — visualize daily composite productivity
/// scores across 6 dimensions (Events, Habits, Goals, Sleep, Mood, Focus)
/// with trend analysis and weekly comparison.
///
/// 4 tabs: Today | History | Trends | Settings
class ProductivityScoreScreen extends StatefulWidget {
  const ProductivityScoreScreen({super.key});

  @override
  State<ProductivityScoreScreen> createState() =>
      _ProductivityScoreScreenState();
}

class _ProductivityScoreScreenState extends State<ProductivityScoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ProductivityScoreService _service;
  late List<DailyProductivityScore> _dailyScores;
  late ProductivityTrend _trend;
  late Map<String, dynamic> _weeklySummary;
  ProductivityWeights _weights = const ProductivityWeights();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _computeScores();
  }

  void _computeScores() {
    setState(() => _loading = true);
    _service = ProductivityScoreService(weights: _weights);

    final events = ProductivitySampleData.sampleEvents(days: 14);
    final habits = ProductivitySampleData.sampleHabits();
    final habitCompletions =
        ProductivitySampleData.sampleHabitCompletions(days: 14);
    final goals = ProductivitySampleData.sampleGoals();
    final sleepEntries = ProductivitySampleData.sampleSleepEntries(days: 14);
    final moodEntries = ProductivitySampleData.sampleMoodEntries(days: 14);
    final focusMap = ProductivitySampleData.sampleFocusMinutes(days: 14);

    final now = DateTime.now();
    _dailyScores = [];
    for (int d = 0; d < 14; d++) {
      final date = DateTime(now.year, now.month, now.day - d);
      _dailyScores.add(_service.computeDailyScore(
        date: date,
        events: events,
        habits: habits,
        habitCompletions: habitCompletions,
        goals: goals,
        sleepEntries: sleepEntries,
        moodEntries: moodEntries,
        focusMinutes: focusMap[d] ?? 0,
      ));
    }

    _trend = _service.analyzeTrend(_dailyScores);

    final thisWeek = _dailyScores.where((s) {
      final diff = now.difference(s.date).inDays;
      return diff < 7;
    }).toList();
    final lastWeek = _dailyScores.where((s) {
      final diff = now.difference(s.date).inDays;
      return diff >= 7 && diff < 14;
    }).toList();
    _weeklySummary = _service.weeklySummary(thisWeek, lastWeek);

    setState(() => _loading = false);
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
        title: const Text('Productivity Score'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
            Tab(icon: Icon(Icons.tune), text: 'Settings'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _TodayTab(score: _dailyScores.first),
                _HistoryTab(scores: _dailyScores),
                _TrendsTab(
                    trend: _trend, weeklySummary: _weeklySummary),
                _SettingsTab(
                  weights: _weights,
                  onWeightsChanged: (w) {
                    _weights = w;
                    _computeScores();
                  },
                ),
              ],
            ),
    );
  }
}

// ─── TODAY TAB ───────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  final DailyProductivityScore score;
  const _TodayTab({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall score circle
          _ScoreCircle(score: score.overallScore, grade: score.grade),
          const SizedBox(height: 24),

          // Dimension breakdown
          Text('Dimension Breakdown',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...score.dimensions.map((d) => _DimensionBar(dimension: d)),

          // Strengths
          if (score.strengths.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(
                icon: Icons.star, title: 'Strengths', color: Colors.green),
            ...score.strengths
                .map((s) => _InsightTile(text: s, color: Colors.green)),
          ],

          // Improvements
          if (score.improvements.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(
                icon: Icons.arrow_upward,
                title: 'Areas to Improve',
                color: Colors.orange),
            ...score.improvements
                .map((s) => _InsightTile(text: s, color: Colors.orange)),
          ],
        ],
      ),
    );
  }
}

// ─── HISTORY TAB ────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final List<DailyProductivityScore> scores;
  const _HistoryTab({required this.scores});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scores.length,
      itemBuilder: (context, index) {
        final s = scores[index];
        final dateStr = _formatDate(s.date);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: _GradeChip(grade: s.grade),
            title: Text(dateStr),
            subtitle: Text(
              '${s.overallScore.toStringAsFixed(1)} / 100',
              style: TextStyle(
                color: _scoreColor(s.overallScore),
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: s.dimensions
                      .map((d) => _DimensionBar(dimension: d))
                      .toList(),
                ),
              ),
              if (s.strengths.isNotEmpty || s.improvements.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...s.strengths.map(
                          (t) => _InsightTile(text: t, color: Colors.green)),
                      ...s.improvements.map(
                          (t) => _InsightTile(text: t, color: Colors.orange)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── TRENDS TAB ─────────────────────────────────────────────────────────────

class _TrendsTab extends StatelessWidget {
  final ProductivityTrend trend;
  final Map<String, dynamic> weeklySummary;
  const _TrendsTab({required this.trend, required this.weeklySummary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thisWeek = weeklySummary['thisWeek'] as Map<String, dynamic>;
    final change = weeklySummary['change'] as double;
    final improving = weeklySummary['improving'] as bool;
    final dimChanges =
        weeklySummary['dimensionChanges'] as Map<String, double>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trend overview card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('14-Day Trend',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      _TrendBadge(direction: trend.direction),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(
                          label: 'Average', value: trend.averageScore, suffix: ''),
                      _StatCard(label: 'Best', value: trend.bestScore, suffix: ''),
                      _StatCard(
                          label: 'Worst', value: trend.worstScore, suffix: ''),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(
                          label: 'Streak',
                          value: trend.streak.toDouble(),
                          suffix: ' days'),
                      if (trend.topStrength != null)
                        _StatCard(
                            label: 'Strength',
                            textValue: trend.topStrength!,
                            suffix: ''),
                      if (trend.topWeakness != null)
                        _StatCard(
                            label: 'Weakness',
                            textValue: trend.topWeakness!,
                            suffix: ''),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Weekly comparison
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Week-over-Week',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        improving ? Icons.arrow_upward : Icons.arrow_downward,
                        color: improving ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} pts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: improving ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                          'avg ${(thisWeek['average'] as double).toStringAsFixed(1)}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Per-Dimension Changes',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...dimChanges.entries.map((e) {
                    final positive = e.value >= 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 60,
                              child: Text(e.key,
                                  style: const TextStyle(fontSize: 13))),
                          Icon(
                            positive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: positive ? Colors.green : Colors.red,
                          ),
                          Text(
                            '${positive ? '+' : ''}${e.value.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: positive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mini bar chart of daily scores
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Scores',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: trend.dailyScores.map((s) {
                        final barH = (s.overallScore / 100) * 120;
                        return Expanded(
                          child: Tooltip(
                            message:
                                '${_formatDateShort(s.date)}: ${s.overallScore.toStringAsFixed(0)}',
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Container(
                                height: barH,
                                decoration: BoxDecoration(
                                  color: _scoreColor(s.overallScore)
                                      .withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SETTINGS TAB ───────────────────────────────────────────────────────────

class _SettingsTab extends StatelessWidget {
  final ProductivityWeights weights;
  final ValueChanged<ProductivityWeights> onWeightsChanged;
  const _SettingsTab(
      {required this.weights, required this.onWeightsChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weight Presets',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _PresetChip(
                label: 'Balanced',
                selected: _isPreset(weights, const ProductivityWeights()),
                onTap: () => onWeightsChanged(const ProductivityWeights()),
              ),
              _PresetChip(
                label: 'Task-Focused',
                selected:
                    _isPreset(weights, ProductivityWeights.taskFocused),
                onTap: () =>
                    onWeightsChanged(ProductivityWeights.taskFocused),
              ),
              _PresetChip(
                label: 'Wellness',
                selected:
                    _isPreset(weights, ProductivityWeights.wellnessFocused),
                onTap: () =>
                    onWeightsChanged(ProductivityWeights.wellnessFocused),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Current Weights',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...weights.toMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                        width: 80,
                        child: Text(_capitalize(e.key),
                            style: const TextStyle(
                                fontWeight: FontWeight.w500))),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: e.value,
                        backgroundColor: Colors.grey[200],
                        color: _dimensionColor(e.key),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(e.value * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How it works',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'Your daily productivity score combines 6 dimensions:\n\n'
                    '• Events — task planning & completion\n'
                    '• Habits — consistency with daily habits\n'
                    '• Goals — progress toward active goals\n'
                    '• Sleep — quality and duration\n'
                    '• Mood — emotional wellbeing\n'
                    '• Focus — deep work (Pomodoro) time\n\n'
                    'Each dimension is scored 0-100, then weighted to '
                    'produce a composite score. Choose a preset or '
                    'adjust weights to match your priorities.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPreset(ProductivityWeights a, ProductivityWeights b) {
    return (a.events - b.events).abs() < 0.001 &&
        (a.habits - b.habits).abs() < 0.001 &&
        (a.goals - b.goals).abs() < 0.001 &&
        (a.sleep - b.sleep).abs() < 0.001 &&
        (a.mood - b.mood).abs() < 0.001 &&
        (a.focus - b.focus).abs() < 0.001;
  }
}

// ─── SHARED WIDGETS ─────────────────────────────────────────────────────────

class _ScoreCircle extends StatelessWidget {
  final double score;
  final ProductivityGrade grade;
  const _ScoreCircle({required this.score, required this.grade});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[200],
                  color: _scoreColor(score),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: _scoreColor(score),
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _scoreColor(score).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${grade.emoji} ${grade.label}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _scoreColor(score),
            ),
          ),
        ),
      ],
    );
  }
}

class _DimensionBar extends StatelessWidget {
  final DimensionScore dimension;
  const _DimensionBar({required this.dimension});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_dimensionIcon(dimension.name),
                      size: 18, color: _dimensionColor(dimension.name.toLowerCase())),
                  const SizedBox(width: 6),
                  Text(dimension.name,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              Text(
                '${dimension.score.toStringAsFixed(0)} (${(dimension.weight * 100).round()}%)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: dimension.score / 100,
              backgroundColor: Colors.grey[200],
              color: _scoreColor(dimension.score),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dimension.insight,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final ProductivityGrade grade;
  const _GradeChip({required this.grade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _gradeColor(grade).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(grade.emoji,
          style: const TextStyle(fontSize: 20)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 15)),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String text;
  final Color color;
  const _InsightTile({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: color.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final TrendDirection direction;
  const _TrendBadge({required this.direction});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (direction) {
      TrendDirection.rising => (Icons.trending_up, Colors.green, 'Rising'),
      TrendDirection.stable => (Icons.trending_flat, Colors.blue, 'Stable'),
      TrendDirection.declining =>
        (Icons.trending_down, Colors.red, 'Declining'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double? value;
  final String? textValue;
  final String suffix;
  const _StatCard(
      {required this.label, this.value, this.textValue, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          textValue ?? '${value!.toStringAsFixed(0)}$suffix',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PresetChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

// ─── HELPERS ────────────────────────────────────────────────────────────────

Color _scoreColor(double score) {
  if (score >= 85) return Colors.green;
  if (score >= 70) return Colors.teal;
  if (score >= 55) return Colors.blue;
  if (score >= 40) return Colors.orange;
  return Colors.red;
}

Color _gradeColor(ProductivityGrade grade) {
  return switch (grade) {
    ProductivityGrade.excellent => Colors.green,
    ProductivityGrade.great => Colors.teal,
    ProductivityGrade.good => Colors.blue,
    ProductivityGrade.fair => Colors.orange,
    ProductivityGrade.needsWork => Colors.red,
  };
}

Color _dimensionColor(String key) {
  return switch (key) {
    'events' => Colors.blue,
    'habits' => Colors.purple,
    'goals' => Colors.green,
    'sleep' => Colors.indigo,
    'mood' => Colors.orange,
    'focus' => Colors.red,
    _ => Colors.grey,
  };
}

IconData _dimensionIcon(String name) {
  return switch (name) {
    'Events' => Icons.event,
    'Habits' => Icons.track_changes,
    'Goals' => Icons.flag,
    'Sleep' => Icons.bedtime,
    'Mood' => Icons.mood,
    'Focus' => Icons.timer,
    _ => Icons.circle,
  };
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

String _formatDateShort(DateTime d) {
  return '${d.month}/${d.day}';
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
