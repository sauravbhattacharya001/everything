import 'package:flutter/material.dart';
import '../../core/services/social_capital_engine_service.dart';

/// Social Capital Engine screen — autonomous relationship network dashboard.
///
/// 4-tab layout:
/// 1. **Network** — overall score gauge, key metrics, top insights
/// 2. **Relationships** — all relationships with strength bars and reciprocity
/// 3. **Clusters** — detected social clusters with cohesion scores
/// 4. **Insights** — autonomous recommendations sorted by severity
class SocialCapitalScreen extends StatefulWidget {
  const SocialCapitalScreen({super.key});

  @override
  State<SocialCapitalScreen> createState() => _SocialCapitalScreenState();
}

class _SocialCapitalScreenState extends State<SocialCapitalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SocialCapitalEngineService _service;
  SocialCapitalAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _service = SocialCapitalEngineService();
    _loadDemoIfEmpty();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDemoIfEmpty() {
    if (_service.relationships.isEmpty) {
      _service.loadDemoData();
    }
    _runAnalysis();
  }

  void _runAnalysis() {
    setState(() {
      _analysis = _service.analyze();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Capital'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-analyze',
            onPressed: _runAnalysis,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.hub), text: 'Network'),
            Tab(icon: Icon(Icons.people), text: 'People'),
            Tab(icon: Icon(Icons.group_work), text: 'Clusters'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Insights'),
          ],
        ),
      ),
      body: _analysis == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNetworkTab(theme),
                _buildPeopleTab(theme),
                _buildClustersTab(theme),
                _buildInsightsTab(theme),
              ],
            ),
    );
  }

  // ── Tab 1: Network Overview ──

  Widget _buildNetworkTab(ThemeData theme) {
    final a = _analysis!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Score gauge
        Center(
          child: SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: a.overallScore / 100,
                    strokeWidth: 12,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      _scoreColor(a.overallScore),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      a.overallScore.toStringAsFixed(0),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Social Capital',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Key metrics
        Row(
          children: [
            _metricCard(theme, '${a.activeRelationships}', 'Active', Icons.person, Colors.green),
            const SizedBox(width: 8),
            _metricCard(theme, '${a.neglectedCount}', 'Neglected', Icons.person_off, Colors.orange),
            const SizedBox(width: 8),
            _metricCard(theme, '${a.strongTieCount}', 'Strong', Icons.favorite, Colors.red),
          ],
        ),
        const SizedBox(height: 16),
        // Tier distribution
        Text('Tier Distribution', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _buildTierChips(theme),
        ),
        const SizedBox(height: 24),
        // Top 3 insights
        if (a.insights.isNotEmpty) ...[
          Text('Top Insights', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...a.insights.take(3).map((i) => _insightCard(theme, i)),
        ],
        // Trend
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(
              _trendIcon(_service.trendDirection()),
              color: _trendColor(_service.trendDirection()),
            ),
            title: Text('Network Trend: ${_service.trendDirection().toUpperCase()}'),
            subtitle: Text(
              'Diversity: ${(a.networkDiversity * 100).toStringAsFixed(0)}%',
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(
      ThemeData theme, String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(value,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTierChips(ThemeData theme) {
    final a = _analysis!;
    final counts = <RelationshipTier, int>{};
    for (final h in a.healthMap.values) {
      counts[h.computedTier] = (counts[h.computedTier] ?? 0) + 1;
    }
    return RelationshipTier.values
        .where((t) => (counts[t] ?? 0) > 0)
        .map((t) => Chip(
              avatar: Text(t.emoji),
              label: Text('${t.label}: ${counts[t]}'),
            ))
        .toList();
  }

  // ── Tab 2: People ──

  Widget _buildPeopleTab(ThemeData theme) {
    final a = _analysis!;
    final sorted = _service.relationships.toList()
      ..sort((x, y) {
        final hx = a.healthMap[x.id]?.strengthScore ?? 0;
        final hy = a.healthMap[y.id]?.strengthScore ?? 0;
        return hy.compareTo(hx);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final r = sorted[index];
        final h = a.healthMap[r.id];
        if (h == null) return const SizedBox.shrink();
        final ints = _service.interactionsFor(r.id);
        final lastDate = ints.isNotEmpty
            ? '${ints.first.date.month}/${ints.first.date.day}'
            : 'Never';

        return Card(
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _scoreColor(h.strengthScore).withValues(alpha: 0.2),
              child: Text(
                h.strengthScore.toStringAsFixed(0),
                style: TextStyle(
                  color: _scoreColor(h.strengthScore),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(r.name),
                const SizedBox(width: 6),
                Text(h.computedTier.emoji, style: const TextStyle(fontSize: 14)),
              ],
            ),
            subtitle: Row(
              children: [
                Text('Last: $lastDate'),
                const Spacer(),
                _reciprocityIndicator(h.reciprocityIndex),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _strengthBar(theme, 'Recency', h.recencyScore),
                    _strengthBar(theme, 'Frequency', h.frequencyScore),
                    _strengthBar(theme, 'Quality', h.qualityScore),
                    const SizedBox(height: 8),
                    if (h.decayDate != null)
                      Text(
                        '⏳ Predicted dormant: ${h.decayDate!.month}/${h.decayDate!.day}/${h.decayDate!.year}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    if (r.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: r.tags
                            .map((t) => Chip(
                                  label: Text(t, style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Recent interactions:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ...ints.take(5).map((i) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Text(
                            '${i.type.emoji} ${i.date.month}/${i.date.day} — ${i.initiatedBy.label} (${i.quality}★)',
                            style: theme.textTheme.bodySmall,
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _strengthBar(ThemeData theme, String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(_scoreColor(value)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              value.toStringAsFixed(0),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reciprocityIndicator(double index) {
    // index: -1 (all them) to +1 (all you)
    final color = index.abs() > 0.6
        ? Colors.orange
        : index.abs() > 0.3
            ? Colors.amber
            : Colors.green;
    final label = index > 0.3
        ? '→'
        : index < -0.3
            ? '←'
            : '↔';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.swap_horiz, size: 14, color: color),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  // ── Tab 3: Clusters ──

  Widget _buildClustersTab(ThemeData theme) {
    final a = _analysis!;
    if (a.clusters.isEmpty) {
      return const Center(
        child: Text('No clusters detected.\nAdd tags to relationships to group them.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: a.clusters.length,
      itemBuilder: (context, index) {
        final c = a.clusters[index];
        final members = _service.relationships
            .where((r) => c.memberIds.contains(r.id))
            .toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.group_work, color: _scoreColor(c.cohesionScore)),
                    const SizedBox(width: 8),
                    Text(c.name, style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Chip(
                      label: Text(
                        '${c.trend.arrow} ${c.trend.label}',
                        style: TextStyle(
                          color: c.trend == ClusterTrend.growing
                              ? Colors.green
                              : c.trend == ClusterTrend.weakening
                                  ? Colors.red
                                  : null,
                          fontSize: 12,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: c.cohesionScore / 100,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(_scoreColor(c.cohesionScore)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cohesion: ${c.cohesionScore.toStringAsFixed(0)}/100 · ${members.length} members',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: members
                      .map((m) => Chip(
                            avatar: Text(
                              (a.healthMap[m.id]?.computedTier ?? RelationshipTier.dormant).emoji,
                            ),
                            label: Text(m.name, style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Tab 4: Insights ──

  Widget _buildInsightsTab(ThemeData theme) {
    final insights = _analysis!.insights;
    if (insights.isEmpty) {
      return const Center(
        child: Text('No insights right now.\nYour network looks healthy! 🎉'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: insights.length,
      itemBuilder: (context, index) => _insightCard(theme, insights[index]),
    );
  }

  Widget _insightCard(ThemeData theme, SocialCapitalInsight insight) {
    return Card(
      color: insight.severity == InsightSeverity.critical
          ? Colors.red.withValues(alpha: 0.08)
          : insight.severity == InsightSeverity.warning
              ? Colors.orange.withValues(alpha: 0.06)
              : null,
      child: ListTile(
        leading: Text(
          insight.type.emoji,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(insight.message),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _severityChip(insight.severity),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.actionSuggestion,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _severityChip(InsightSeverity severity) {
    final color = severity == InsightSeverity.critical
        ? Colors.red
        : severity == InsightSeverity.warning
            ? Colors.orange
            : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        severity.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── Helpers ──

  Color _scoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.lime;
    if (score >= 30) return Colors.orange;
    return Colors.red;
  }

  IconData _trendIcon(String trend) {
    switch (trend) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _trendColor(String trend) {
    switch (trend) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
