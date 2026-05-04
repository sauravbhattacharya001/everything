import 'package:flutter/material.dart';
import '../../core/services/stress_cascade_engine_service.dart';

/// Stress Cascade Engine — autonomous stress propagation and resilience analyzer.
///
/// 4-tab layout:
/// 1. Overview — composite score, phase, resilience, domain bars
/// 2. Cascade Map — propagation edges between domains
/// 3. Buffers — stress buffer levels, tipping points
/// 4. Insights — ranked actionable recommendations
class StressCascadeScreen extends StatefulWidget {
  const StressCascadeScreen({super.key});

  @override
  State<StressCascadeScreen> createState() => _StressCascadeScreenState();
}

class _StressCascadeScreenState extends State<StressCascadeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final StressCascadeEngineService _service = StressCascadeEngineService();
  late StressCascadeReport _report;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _service.loadSampleData();
    _report = _service.analyze();
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
        title: const Text('Stress Cascade Engine'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.account_tree), text: 'Cascade'),
            Tab(icon: Icon(Icons.shield), text: 'Buffers'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(theme),
          _buildCascadeTab(theme),
          _buildBuffersTab(theme),
          _buildInsightsTab(theme),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Tab 1 — Overview
  // -----------------------------------------------------------------------

  Widget _buildOverviewTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Composite stress score.
        _scoreCard(theme),
        const SizedBox(height: 16),
        // Phase + resilience badges.
        Row(
          children: [
            Expanded(child: _phaseBadge(theme)),
            const SizedBox(width: 12),
            Expanded(child: _resilienceBadge(theme)),
          ],
        ),
        const SizedBox(height: 16),
        // Domain stress bars.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Domain Stress Levels',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                ..._report.domainProfiles.map((p) => _domainBar(theme, p)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Quick stats.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Stats', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _statRow('Total Events', '${_service.events.length}'),
                _statRow('Cascade Edges', '${_report.cascadeEdges.length}'),
                _statRow('Tipping Points', '${_report.tippingPoints.length}'),
                _statRow(
                    'Recovery Forecasts', '${_report.recoveryForecasts.length}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _scoreCard(ThemeData theme) {
    final score = _report.compositeStressScore;
    final color = score >= 70
        ? Colors.red
        : score >= 50
            ? Colors.orange
            : score >= 30
                ? Colors.amber
                : Colors.green;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Composite Stress Score',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100.0,
                    strokeWidth: 12,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text('$score',
                    style: theme.textTheme.headlineLarge
                        ?.copyWith(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _phaseBadge(ThemeData theme) {
    final phase = _report.cascadePhase;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(phase.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(phase.label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(phase.description,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _resilienceBadge(ThemeData theme) {
    final tier = _report.resilienceTier;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(tier.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(tier.label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(tier.description,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _domainBar(ThemeData theme, DomainStressProfile profile) {
    final color = Color(profile.domain.colorHex);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(profile.domain.emoji,
                style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(profile.domain.label,
                style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: profile.currentLevel / 100.0,
                minHeight: 14,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text('${profile.currentLevel}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Tab 2 — Cascade Map
  // -----------------------------------------------------------------------

  Widget _buildCascadeTab(ThemeData theme) {
    if (_report.cascadeEdges.isEmpty) {
      return const Center(child: Text('No cascade edges detected.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _report.cascadeEdges.length,
      itemBuilder: (_, i) {
        final edge = _report.cascadeEdges[i];
        final strength = edge.propagationStrength;
        final color = strength > 0.6
            ? Colors.red
            : strength > 0.3
                ? Colors.orange
                : Colors.grey;
        return Card(
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(edge.fromDomain.emoji,
                    style: const TextStyle(fontSize: 20)),
                const Icon(Icons.arrow_downward, size: 16),
                Text(edge.toDomain.emoji,
                    style: const TextStyle(fontSize: 20)),
              ],
            ),
            title: Text(
              '${edge.fromDomain.label} → ${edge.toDomain.label}',
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength,
                    minHeight: 8,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Strength: ${(strength * 100).round()}% · '
                  'Delay: ${edge.delayHours.round()}h · '
                  'Evidence: ${edge.evidenceCount}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // Tab 3 — Buffers & Tipping Points
  // -----------------------------------------------------------------------

  Widget _buildBuffersTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Stress Buffers', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._report.bufferStatus.map((b) => _bufferCard(theme, b)),
        if (_report.tippingPoints.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('⚠️ Tipping Points', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._report.tippingPoints.map((tp) => _tippingPointCard(theme, tp)),
        ],
        if (_report.recoveryForecasts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('🔮 Recovery Forecasts', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._report.recoveryForecasts
              .map((rf) => _recoveryCard(theme, rf)),
        ],
      ],
    );
  }

  Widget _bufferCard(ThemeData theme, StressBuffer buffer) {
    final level = buffer.currentLevel;
    final color = level >= 60
        ? Colors.green
        : level >= 30
            ? Colors.orange
            : Colors.red;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(buffer.category.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(buffer.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('$level%',
                    style: theme.textTheme.titleSmall?.copyWith(color: color)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: level / 100.0,
                minHeight: 10,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Depletion: ${buffer.depletionRate.toStringAsFixed(1)}/day'
              '${buffer.lastReplenished != null ? ' · Last replenished: ${_daysAgo(buffer.lastReplenished!)}' : ''}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tippingPointCard(ThemeData theme, TippingPointAlert tp) {
    return Card(
      color: tp.daysUntilBreach <= 3
          ? Colors.red.withOpacity(0.1)
          : Colors.orange.withOpacity(0.1),
      child: ListTile(
        leading: Text(tp.domain.emoji,
            style: const TextStyle(fontSize: 24)),
        title: Text(
          '${tp.domain.label} — ${tp.daysUntilBreach} days to breach',
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          'Current: ${tp.currentLevel}/100 → Threshold: ${tp.threshold} '
          '(${(tp.confidence * 100).round()}% confidence)',
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _recoveryCard(ThemeData theme, RecoveryForecast rf) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(rf.domain.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(rf.domain.label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('~${rf.projectedDays} days',
                    style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Current: ${rf.currentLevel}/100 · '
              'Confidence: ${(rf.confidence * 100).round()}%',
              style: theme.textTheme.bodySmall,
            ),
            if (rf.recommendedActions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...rf.recommendedActions.map((a) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 12)),
                        Expanded(
                            child: Text(a,
                                style: theme.textTheme.bodySmall)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  String _daysAgo(DateTime dt) {
    final days = DateTime.now().difference(dt).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  // -----------------------------------------------------------------------
  // Tab 4 — Insights
  // -----------------------------------------------------------------------

  Widget _buildInsightsTab(ThemeData theme) {
    if (_report.insights.isEmpty) {
      return const Center(child: Text('No insights generated.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _report.insights.length,
      itemBuilder: (_, i) {
        final insight = _report.insights[i];
        final priorityColor = _priorityColor(insight.priority);
        return Card(
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(insight.emoji, style: const TextStyle(fontSize: 20)),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(insight.priority.label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priorityColor)),
                ),
              ],
            ),
            title: Text(insight.title,
                style: theme.textTheme.titleSmall),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(insight.description,
                  style: theme.textTheme.bodySmall),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Color _priorityColor(CascadeInsightPriority priority) {
    switch (priority) {
      case CascadeInsightPriority.critical:
        return Colors.red;
      case CascadeInsightPriority.high:
        return Colors.orange;
      case CascadeInsightPriority.medium:
        return Colors.amber.shade700;
      case CascadeInsightPriority.low:
        return Colors.green;
    }
  }
}
