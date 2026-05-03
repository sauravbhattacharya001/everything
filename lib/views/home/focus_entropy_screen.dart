import 'package:flutter/material.dart';
import '../../core/services/focus_entropy_engine_service.dart';

/// Focus Entropy Engine screen — autonomous focus fragmentation detector.
///
/// 4-tab interface showing flow score, domain distributions, entropy
/// history with forecast, and ranked actionable insights.
class FocusEntropyScreen extends StatefulWidget {
  const FocusEntropyScreen({super.key});

  @override
  State<FocusEntropyScreen> createState() => _FocusEntropyScreenState();
}

class _FocusEntropyScreenState extends State<FocusEntropyScreen>
    with SingleTickerProviderStateMixin {
  final FocusEntropyEngineService _service = FocusEntropyEngineService();
  late TabController _tabController;
  late FocusEntropyReport _report;

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
        title: const Text('Focus Entropy'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.speed), text: 'Overview'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Domains'),
            Tab(icon: Icon(Icons.show_chart), text: 'Entropy'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(theme),
          _buildDomainsTab(theme),
          _buildEntropyTab(theme),
          _buildInsightsTab(theme),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1 — Overview
  // ---------------------------------------------------------------------------

  Widget _buildOverviewTab(ThemeData theme) {
    final grade = _report.focusGrade;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Flow score gauge.
        Center(
          child: Column(
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
                        value: _report.flowScore / 100.0,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _flowScoreColor(_report.flowScore),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_report.flowScore}',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Flow Score',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Chip(
                avatar: Text(grade.emoji, style: const TextStyle(fontSize: 16)),
                label: Text(grade.label),
              ),
              const SizedBox(height: 4),
              Text(grade.description,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Key metrics grid.
        _metricRow(
          theme,
          [
            _MetricTile(
              label: 'Today Entropy',
              value: _report.currentEntropy.toStringAsFixed(2),
              icon: Icons.scatter_plot,
            ),
            _MetricTile(
              label: 'Weekly Avg',
              value: _report.weeklyEntropy.toStringAsFixed(2),
              icon: Icons.calendar_view_week,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _metricRow(
          theme,
          [
            _MetricTile(
              label: 'Deep Work',
              value: '${_report.totalDeepWorkMinutes} min',
              icon: Icons.psychology,
            ),
            _MetricTile(
              label: 'Switches',
              value: '${_report.totalContextSwitches}',
              icon: Icons.swap_horiz,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _metricRow(
          theme,
          [
            _MetricTile(
              label: 'Deep Work %',
              value: '${(_report.deepWorkRatio * 100).toStringAsFixed(1)}%',
              icon: Icons.center_focus_strong,
            ),
            _MetricTile(
              label: 'Trend',
              value:
                  '${_report.forecast.trend.emoji} ${_report.forecast.trend.label}',
              icon: Icons.trending_up,
            ),
          ],
        ),
      ],
    );
  }

  Color _flowScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.deepOrange;
    return Colors.red;
  }

  Widget _metricRow(ThemeData theme, List<_MetricTile> tiles) {
    return Row(
      children: tiles
          .map((t) => Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(t.icon, size: 28, color: theme.colorScheme.primary),
                        const SizedBox(height: 8),
                        Text(t.value,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(t.label,
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2 — Domains
  // ---------------------------------------------------------------------------

  Widget _buildDomainsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Domain Distribution',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._report.domainDistributions.map((d) => _buildDomainTile(theme, d)),
        const SizedBox(height: 24),
        Text('Deep Work Blocks (${_report.deepWorkBlocks.length})',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_report.deepWorkBlocks.isEmpty)
          const Center(child: Text('No deep work blocks detected'))
        else
          ..._report.deepWorkBlocks
              .take(20)
              .map((b) => _buildDeepWorkTile(theme, b)),
      ],
    );
  }

  Widget _buildDomainTile(ThemeData theme, DomainDistribution d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(d.domain, style: theme.textTheme.bodyLarge),
              Text(
                '${d.totalMinutes} min · ${d.sessionCount} sessions',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: d.percentage / 100.0,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text('${d.percentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeepWorkTile(ThemeData theme, DeepWorkBlock b) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _qualityColor(b.qualityScore),
          child: Text('${b.qualityScore}',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        title: Text(b.domain),
        subtitle: Text(
          '${b.durationMinutes} min · '
          '${b.startTime.month}/${b.startTime.day} '
          '${b.startTime.hour.toString().padLeft(2, '0')}:'
          '${b.startTime.minute.toString().padLeft(2, '0')}',
        ),
        trailing: const Icon(Icons.psychology, size: 20),
      ),
    );
  }

  Color _qualityColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  // ---------------------------------------------------------------------------
  // Tab 3 — Entropy
  // ---------------------------------------------------------------------------

  Widget _buildEntropyTab(ThemeData theme) {
    final history = _report.entropyHistory;
    final forecast = _report.forecast;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Daily Entropy',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (history.isEmpty)
          const Center(child: Text('No data yet'))
        else ...[
          // Sparkline as colored bars.
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: history.map((s) {
                final maxH = 3.0; // visual max
                final fraction = (s.entropy / maxH).clamp(0.0, 1.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(
                      message:
                          '${s.date.month}/${s.date.day}: ${s.entropy.toStringAsFixed(2)}',
                      child: Container(
                        height: 120 * fraction,
                        decoration: BoxDecoration(
                          color: _entropyBarColor(s.entropy),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Date labels.
          Row(
            children: history.map((s) {
              return Expanded(
                child: Text(
                  '${s.date.month}/${s.date.day}',
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.clip,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Detail list.
          ...history.reversed.map((s) => ListTile(
                dense: true,
                leading: Icon(
                  s.entropy < 1.4
                      ? Icons.check_circle
                      : s.entropy < 2.0
                          ? Icons.info
                          : Icons.warning,
                  color: _entropyBarColor(s.entropy),
                ),
                title: Text(
                  '${s.date.month}/${s.date.day} — H = ${s.entropy.toStringAsFixed(2)} '
                  '(${s.domainCount} domains)',
                ),
                subtitle: Text(s.interpretation),
              )),
        ],
        const SizedBox(height: 24),
        // Forecast card.
        Card(
          color: forecast.trend == FocusTrend.degrading
              ? Colors.red.shade50
              : forecast.trend == FocusTrend.improving
                  ? Colors.green.shade50
                  : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('7-Day Forecast',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(forecast.trend.emoji,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trend: ${forecast.trend.label}',
                              style: theme.textTheme.bodyLarge),
                          Text(
                            'Projected entropy: '
                            '${forecast.projectedEntropy.toStringAsFixed(2)} '
                            '(confidence: ${(forecast.confidence * 100).toStringAsFixed(0)}%)',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (forecast.daysUntilCritical != null)
                            Text(
                              '⚠️ Critical threshold in ~${forecast.daysUntilCritical} days',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _entropyBarColor(double entropy) {
    if (entropy < 1.0) return Colors.green;
    if (entropy < 1.5) return Colors.lightGreen;
    if (entropy < 2.0) return Colors.orange;
    if (entropy < 2.5) return Colors.deepOrange;
    return Colors.red;
  }

  // ---------------------------------------------------------------------------
  // Tab 4 — Insights
  // ---------------------------------------------------------------------------

  Widget _buildInsightsTab(ThemeData theme) {
    final insights = _report.insights;
    if (insights.isEmpty) {
      return const Center(child: Text('No insights yet — add more data.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        final insight = insights[index];
        return Card(
          child: ListTile(
            leading: Text(insight.emoji,
                style: const TextStyle(fontSize: 24)),
            title: Row(
              children: [
                _categoryBadge(theme, insight.category),
                const SizedBox(width: 8),
                _priorityBadge(theme, insight.priority),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.title,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(insight.description),
                ],
              ),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _categoryBadge(ThemeData theme, FocusInsightCategory cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(cat.label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
    );
  }

  Widget _priorityBadge(ThemeData theme, FocusInsightPriority p) {
    final color = switch (p) {
      FocusInsightPriority.critical => Colors.red,
      FocusInsightPriority.high => Colors.orange,
      FocusInsightPriority.medium => Colors.blue,
      FocusInsightPriority.low => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(p.label,
          style:
              theme.textTheme.labelSmall?.copyWith(color: color)),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _MetricTile {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });
}
