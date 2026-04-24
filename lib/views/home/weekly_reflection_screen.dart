import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/weekly_reflection_service.dart';

/// Smart Weekly Reflection — autonomous cross-tracker weekly review
/// with pattern detection, insights, and goal suggestions.
class WeeklyReflectionScreen extends StatefulWidget {
  const WeeklyReflectionScreen({super.key});

  @override
  State<WeeklyReflectionScreen> createState() => _WeeklyReflectionScreenState();
}

class _WeeklyReflectionScreenState extends State<WeeklyReflectionScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'weekly_reflections';
  late TabController _tabController;
  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnimation;

  WeeklyReflection? _currentReflection;
  List<_StoredReflection> _history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scoreAnimController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scoreAnimation =
        CurvedAnimation(parent: _scoreAnimController, curve: Curves.easeOut);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scoreAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() {
        _history = list
            .map((e) => _StoredReflection.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.weekEnd.compareTo(a.weekEnd));
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(_history.map((e) => e.toJson()).toList()));
  }

  List<DaySnapshot> _generateSampleWeek() {
    final rng = math.Random();
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      final baseMood = 50.0 + rng.nextDouble() * 30 + (i * 2);
      return DaySnapshot(
        date: date,
        moodScore: (baseMood + rng.nextDouble() * 20 - 10).clamp(10, 95),
        habitsCompleted: 3 + rng.nextInt(5),
        habitsTotal: 8,
        energyLevel: (40 + rng.nextDouble() * 40 + (i % 3) * 5).clamp(10, 95),
        productivityScore:
            (35 + rng.nextDouble() * 45 + (i < 5 ? 10 : 0)).clamp(10, 95),
        sleepHours: 5.5 + rng.nextDouble() * 3,
        exerciseMinutes: rng.nextBool() ? 20 + rng.nextDouble() * 50 : 0,
        spendingAmount: 5 + rng.nextDouble() * 80,
        journalEntries: rng.nextBool() ? 1 : 0,
        stressLevel: (20 + rng.nextDouble() * 50).clamp(5, 90),
        socialBattery: (30 + rng.nextDouble() * 50).clamp(10, 90),
      );
    });
  }

  void _generateReflection() {
    final days = _generateSampleWeek();
    final reflection = WeeklyReflectionService.generateReflection(days);
    setState(() => _currentReflection = reflection);
    _scoreAnimController.forward(from: 0);

    // Save to history
    _history.insert(
        0,
        _StoredReflection(
          weekStart: reflection.weekStart,
          weekEnd: reflection.weekEnd,
          overallScore: reflection.overallScore,
          verdict: reflection.overallVerdict,
          verdictEmoji: reflection.verdictEmoji,
          insightCount: reflection.insights.length,
          goalCount: reflection.suggestedGoals.length,
        ));
    if (_history.length > 12) _history.removeRange(12, _history.length);
    _saveHistory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Reflection'),
        bottom: _currentReflection != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                  Tab(icon: Icon(Icons.lightbulb), text: 'Insights'),
                  Tab(icon: Icon(Icons.flag), text: 'Goals'),
                ],
              )
            : null,
      ),
      body: _currentReflection == null ? _buildEmpty(theme) : _buildTabs(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateReflection,
        icon: const Icon(Icons.auto_awesome),
        label: Text(
            _currentReflection == null ? 'Generate Reflection' : 'Regenerate'),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 48),
        Icon(Icons.auto_awesome, size: 80, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Smart Weekly Reflection',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Autonomous cross-tracker analysis with pattern detection,\ninsights, and goal suggestions for next week.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (_history.isNotEmpty) ...[
          Text('Past Reflections',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._history.map(_buildHistoryCard),
        ],
      ],
    );
  }

  Widget _buildHistoryCard(_StoredReflection r) {
    final dateStr =
        '${r.weekStart.month}/${r.weekStart.day} — ${r.weekEnd.month}/${r.weekEnd.day}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(r.verdictEmoji, style: const TextStyle(fontSize: 28)),
        title: Text('${r.verdict} (${r.overallScore.round()})'),
        subtitle: Text(
            '$dateStr • ${r.insightCount} insights • ${r.goalCount} goals'),
      ),
    );
  }

  Widget _buildTabs() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverview(),
        _buildInsights(),
        _buildGoals(),
      ],
    );
  }

  // ── Overview Tab ──

  Widget _buildOverview() {
    final r = _currentReflection!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Score gauge
        AnimatedBuilder(
          animation: _scoreAnimation,
          builder: (_, __) => _ScoreGauge(
            score: r.overallScore * _scoreAnimation.value,
            verdict: r.overallVerdict,
            emoji: r.verdictEmoji,
          ),
        ),
        const SizedBox(height: 16),
        // Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(r.weekSummary,
                style: const TextStyle(fontSize: 15, height: 1.5)),
          ),
        ),
        const SizedBox(height: 12),
        // Best / Toughest day
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                emoji: '🌟',
                label: 'Best Day',
                value: r.bestDay,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                emoji: '💪',
                label: 'Toughest Day',
                value: r.toughestDay,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Dimension bars
        Text('Dimensions',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...r.dimensionScores.entries.map(_buildDimensionBar),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDimensionBar(MapEntry<String, double> entry) {
    final colors = {
      'Mood': Colors.amber,
      'Habits': Colors.teal,
      'Energy': Colors.orange,
      'Productivity': Colors.blue,
      'Sleep': Colors.indigo,
      'Exercise': Colors.green,
      'Calm': Colors.purple,
      'Social': Colors.pink,
    };
    final color = colors[entry.key] ?? Colors.grey;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('${entry.value.round()}%',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: entry.value / 100,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── Insights Tab ──

  Widget _buildInsights() {
    final r = _currentReflection!;
    if (r.insights.isEmpty) {
      return const Center(child: Text('No insights detected.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: r.insights.length + 1,
      itemBuilder: (_, i) {
        if (i == r.insights.length) return const SizedBox(height: 80);
        return _InsightCard(insight: r.insights[i]);
      },
    );
  }

  // ── Goals Tab ──

  Widget _buildGoals() {
    final r = _currentReflection!;
    if (r.suggestedGoals.isEmpty) {
      return const Center(
          child: Text('No goal suggestions — you\'re crushing it!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: r.suggestedGoals.length + 1,
      itemBuilder: (_, i) {
        if (i == r.suggestedGoals.length) return const SizedBox(height: 80);
        return _GoalCard(goal: r.suggestedGoals[i]);
      },
    );
  }
}

// ── Widgets ──

class _ScoreGauge extends StatelessWidget {
  final double score;
  final String verdict;
  final String emoji;
  const _ScoreGauge(
      {required this.score, required this.verdict, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          width: 180,
          child: CustomPaint(
            painter: _ArcPainter(score / 100),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  Text('${score.round()}',
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(verdict,
            style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  _ArcPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    const startAngle = 2.3562; // 135°
    const sweepMax = 4.7124; // 270°

    // Background arc
    canvas.drawArc(
      rect,
      startAngle,
      sweepMax,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = Colors.grey[200]!
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    final color = progress >= 0.7
        ? Colors.green
        : progress >= 0.4
            ? Colors.orange
            : Colors.red;
    canvas.drawArc(
      rect,
      startAngle,
      sweepMax * progress.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.progress != progress;
}

class _InfoCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _InfoCard(
      {required this.emoji,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 2),
            Text(value,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final WeeklyInsight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final typeColors = {
      InsightType.win: Colors.green,
      InsightType.concern: Colors.red,
      InsightType.pattern: Colors.blue,
      InsightType.recommendation: Colors.orange,
      InsightType.milestone: Colors.purple,
    };
    final typeLabels = {
      InsightType.win: 'WIN',
      InsightType.concern: 'CONCERN',
      InsightType.pattern: 'PATTERN',
      InsightType.recommendation: 'TIP',
      InsightType.milestone: 'MILESTONE',
    };
    final color = typeColors[insight.type] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(insight.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(insight.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeLabels[insight.type] ?? '',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(insight.description,
                      style: TextStyle(
                          color: Colors.grey[700], height: 1.4)),
                  const SizedBox(height: 4),
                  Text(
                      'Confidence: ${(insight.confidence * 100).round()}%',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalSuggestion goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final diffColors = {
      GoalDifficulty.easy: Colors.green,
      GoalDifficulty.moderate: Colors.orange,
      GoalDifficulty.stretch: Colors.red,
    };
    final diffLabels = {
      GoalDifficulty.easy: 'EASY',
      GoalDifficulty.moderate: 'MODERATE',
      GoalDifficulty.stretch: 'STRETCH',
    };
    final color = diffColors[goal.difficulty] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(goal.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    diffLabels[goal.difficulty] ?? '',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(goal.rationale,
                style: TextStyle(color: Colors.grey[700], height: 1.4)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.track_changes,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                    '${goal.metric}: ${goal.targetValue.toStringAsFixed(goal.targetValue == goal.targetValue.roundToDouble() ? 0 : 1)}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Storage Model ──

class _StoredReflection {
  final DateTime weekStart;
  final DateTime weekEnd;
  final double overallScore;
  final String verdict;
  final String verdictEmoji;
  final int insightCount;
  final int goalCount;

  _StoredReflection({
    required this.weekStart,
    required this.weekEnd,
    required this.overallScore,
    required this.verdict,
    required this.verdictEmoji,
    required this.insightCount,
    required this.goalCount,
  });

  factory _StoredReflection.fromJson(Map<String, dynamic> j) =>
      _StoredReflection(
        weekStart: DateTime.parse(j['weekStart'] as String),
        weekEnd: DateTime.parse(j['weekEnd'] as String),
        overallScore: (j['overallScore'] as num).toDouble(),
        verdict: j['verdict'] as String,
        verdictEmoji: j['verdictEmoji'] as String,
        insightCount: j['insightCount'] as int,
        goalCount: j['goalCount'] as int,
      );

  Map<String, dynamic> toJson() => {
        'weekStart': weekStart.toIso8601String(),
        'weekEnd': weekEnd.toIso8601String(),
        'overallScore': overallScore,
        'verdict': verdict,
        'verdictEmoji': verdictEmoji,
        'insightCount': insightCount,
        'goalCount': goalCount,
      };
}
