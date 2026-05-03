import 'package:flutter/material.dart';
import '../../core/services/habit_correlation_engine_service.dart';

/// Habit Correlation Engine screen — autonomous cross-tracker correlation
/// discovery. Finds hidden connections between habits, mood, sleep, energy
/// and surfaces actionable insights with synergy detection, anti-pattern
/// alerts, and optimal timing recommendations.
class HabitCorrelationScreen extends StatefulWidget {
  const HabitCorrelationScreen({super.key});

  @override
  State<HabitCorrelationScreen> createState() => _HabitCorrelationScreenState();
}

class _HabitCorrelationScreenState extends State<HabitCorrelationScreen>
    with SingleTickerProviderStateMixin {
  final HabitCorrelationEngineService _service =
      HabitCorrelationEngineService();
  late TabController _tabController;
  late CorrelationReport _report;

  // Filters for correlations tab.
  bool _showSameDay = true;
  bool _showLagged = true;
  bool _showPositive = true;
  bool _showNegative = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _service.loadSampleData();
    _report = _service.generateReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Correlations'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.hub), text: 'Overview'),
            Tab(icon: Icon(Icons.compare_arrows), text: 'Correlations'),
            Tab(icon: Icon(Icons.group_work), text: 'Synergies'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(theme),
          _buildCorrelationsTab(theme),
          _buildSynergiesTab(theme),
          _buildInsightsTab(theme),
        ],
      ),
    );
  }

  // ── Tab 1: Overview ──

  Widget _buildOverviewTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHealthGauge(theme),
        const SizedBox(height: 16),
        _buildMetricsRow(theme),
        const SizedBox(height: 16),
        Text('Top Correlations',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._report.correlations.take(5).map((c) => _buildCorrelationCard(c, theme)),
      ],
    );
  }

  Widget _buildHealthGauge(ThemeData theme) {
    final score = _report.networkHealth;
    final color = score >= 70
        ? Colors.green
        : score >= 40
            ? Colors.amber
            : Colors.red;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Network Health',
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
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  Text(
                    '${score.toStringAsFixed(0)}',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              score >= 70
                  ? 'Your habits form a healthy network'
                  : score >= 40
                      ? 'Some patterns need attention'
                      : 'Significant anti-patterns detected',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            theme,
            '${_report.daysAnalyzed}',
            'Days Analyzed',
            Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            theme,
            '${_report.totalSignals}',
            'Signals',
            Icons.sensors,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            theme,
            '${_report.correlations.length}',
            'Correlations',
            Icons.compare_arrows,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      ThemeData theme, String value, String label, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Correlations ──

  Widget _buildCorrelationsTab(ThemeData theme) {
    final filtered = _report.correlations.where((c) {
      if (!_showSameDay && c.lagDays == 0) return false;
      if (!_showLagged && c.lagDays > 0) return false;
      if (!_showPositive && c.r > 0) return false;
      if (!_showNegative && c.r < 0) return false;
      return true;
    }).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Same-day'),
                selected: _showSameDay,
                onSelected: (v) => setState(() => _showSameDay = v),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Lagged'),
                selected: _showLagged,
                onSelected: (v) => setState(() => _showLagged = v),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Positive'),
                selected: _showPositive,
                onSelected: (v) => setState(() => _showPositive = v),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Negative'),
                selected: _showNegative,
                onSelected: (v) => setState(() => _showNegative = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No correlations match filters'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) =>
                      _buildCorrelationCard(filtered[i], theme),
                ),
        ),
      ],
    );
  }

  Widget _buildCorrelationCard(CorrelationResult c, ThemeData theme) {
    final color = c.r > 0 ? Colors.green : Colors.red;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text(
            c.r.toStringAsFixed(2),
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('${c.signalA} ↔ ${c.signalB}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.interpretation, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildBadge(c.strength.label, color, theme),
                if (c.lagDays > 0) ...[
                  const SizedBox(width: 4),
                  _buildBadge('${c.lagDays}d lag', Colors.blue, theme),
                ],
                const SizedBox(width: 4),
                _buildBadge(
                    'p=${c.pValue.toStringAsFixed(3)}',
                    c.pValue < 0.05 ? Colors.green : Colors.grey,
                    theme),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildBadge(String text, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: theme.textTheme.labelSmall?.copyWith(color: color)),
    );
  }

  // ── Tab 3: Synergies ──

  Widget _buildSynergiesTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_report.synergies.isNotEmpty) ...[
          Text('🤝 Habit Synergies',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._report.synergies.map((s) => _buildSynergyCard(s, theme)),
          const SizedBox(height: 16),
        ],
        if (_report.antiPatterns.isNotEmpty) ...[
          Text('⚠️ Anti-Patterns',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 8),
          ..._report.antiPatterns.map((a) => _buildAntiPatternCard(a, theme)),
          const SizedBox(height: 16),
        ],
        if (_report.timingInsights.isNotEmpty) ...[
          Text('⏰ Optimal Timing',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._report.timingInsights.map((t) => _buildTimingCard(t, theme)),
        ],
        if (_report.synergies.isEmpty &&
            _report.antiPatterns.isEmpty &&
            _report.timingInsights.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Not enough data for synergy analysis yet'),
            ),
          ),
      ],
    );
  }

  Widget _buildSynergyCard(SynergyResult s, ThemeData theme) {
    final boostPct = ((s.synergyScore - 1) * 100).toStringAsFixed(0);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.habits.join(" + ")} → ${s.outcome}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildEffectBar(
                      'Individual sum', s.individualSum, Colors.blue, theme),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEffectBar(
                      'Combined', s.combinedEffect, Colors.green, theme),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('+$boostPct% synergy bonus',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectBar(
      String label, double value, Color color, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: (value / 2).clamp(0, 1),
          backgroundColor: color.withOpacity(0.15),
          valueColor: AlwaysStoppedAnimation(color),
        ),
        Text(value.toStringAsFixed(2), style: theme.textTheme.labelSmall),
      ],
    );
  }

  Widget _buildAntiPatternCard(AntiPattern a, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.red.withOpacity(0.05),
      child: ListTile(
        leading: const Icon(Icons.warning_amber, color: Colors.red),
        title: Text('${a.habit} → ${a.outcome}',
            style: const TextStyle(color: Colors.red)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.explanation, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(a.recommendation,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildTimingCard(TimingInsight t, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.schedule, color: Colors.blue),
        title: Text('${t.habit} → ${t.outcome}'),
        subtitle: Text(
            'Best: ${t.bestDayName} (${t.bestDayEffect.toStringAsFixed(1)})  •  '
            'Worst: ${t.worstDayName} (${t.worstDayEffect.toStringAsFixed(1)})'),
      ),
    );
  }

  // ── Tab 4: Insights ──

  Widget _buildInsightsTab(ThemeData theme) {
    if (_report.insights.isEmpty) {
      return const Center(child: Text('No insights generated yet'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._report.insights.map((i) => _buildInsightCard(i, theme)),
        if (_report.hypotheses.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('🧪 Experiments to Try',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._report.hypotheses.take(5).map((h) => _buildHypothesisCard(h, theme)),
        ],
      ],
    );
  }

  Widget _buildInsightCard(CorrelationInsight i, ThemeData theme) {
    final priorityColor = switch (i.priority) {
      InsightPriority.critical => Colors.red,
      InsightPriority.high => Colors.orange,
      InsightPriority.medium => Colors.blue,
      InsightPriority.low => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Text(i.category.emoji, style: const TextStyle(fontSize: 20)),
        title: Text(i.title),
        subtitle: Row(
          children: [
            _buildBadge(i.priority.label, priorityColor, theme),
            const SizedBox(width: 4),
            _buildBadge(
                '${(i.confidence * 100).toStringAsFixed(0)}%', Colors.blue, theme),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.description),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(i.actionItem,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHypothesisCard(CausalHypothesis h, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.science, color: Colors.purple),
        title: Text('${h.cause} → ${h.effect} (${h.lagDays}d lag)'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h.experiment, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: h.confidence,
              backgroundColor: Colors.purple.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(Colors.purple),
            ),
            Text('Confidence: ${(h.confidence * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.labelSmall),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
