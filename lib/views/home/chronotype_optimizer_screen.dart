import 'package:flutter/material.dart';
import '../../core/services/chronotype_optimizer_service.dart';

/// Chronotype Optimizer screen — autonomous circadian rhythm analyzer.
///
/// 4-tab interface showing alignment overview, circadian energy profile,
/// drift tracking, and ranked actionable insights.
class ChronotypeOptimizerScreen extends StatefulWidget {
  const ChronotypeOptimizerScreen({super.key});

  @override
  State<ChronotypeOptimizerScreen> createState() =>
      _ChronotypeOptimizerScreenState();
}

class _ChronotypeOptimizerScreenState extends State<ChronotypeOptimizerScreen>
    with SingleTickerProviderStateMixin {
  final ChronotypeOptimizerService _service = ChronotypeOptimizerService();
  late TabController _tabController;
  late ChronotypeReport _report;

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
        title: const Text('Chronotype Optimizer'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.access_time_filled), text: 'Overview'),
            Tab(icon: Icon(Icons.show_chart), text: 'Profile'),
            Tab(icon: Icon(Icons.trending_up), text: 'Drift'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(theme),
          _buildProfileTab(theme),
          _buildDriftTab(theme),
          _buildInsightsTab(theme),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1 — Overview
  // ---------------------------------------------------------------------------

  Widget _buildOverviewTab(ThemeData theme) {
    final ct = _report.chronotype;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Alignment score gauge.
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
                        value: _report.alignmentScore / 100.0,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _scoreColor(_report.alignmentScore),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_report.alignmentScore}',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Alignment',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_report.alignmentGrade.emoji} ${_report.alignmentGrade.label}',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Chronotype badge.
        Card(
          child: ListTile(
            leading: Text(ct.emoji, style: const TextStyle(fontSize: 36)),
            title: Text('You are a ${ct.label}',
                style: theme.textTheme.titleLarge),
            subtitle: Text(ct.description),
          ),
        ),
        const SizedBox(height: 12),

        // Stats row.
        Row(
          children: [
            _statCard(theme, 'Activities', '${_report.totalActivities}',
                Icons.bar_chart),
            const SizedBox(width: 8),
            _statCard(theme, 'Peak Hour',
                PeakWindow._formatHour(_report.profile.peakHour), Icons.wb_sunny),
            const SizedBox(width: 8),
            _statCard(theme, 'Drift',
                '${_report.currentDrift.emoji} ${_report.currentDrift.label}',
                Icons.compare_arrows),
          ],
        ),
        const SizedBox(height: 16),

        // 24-hour energy mini-bar.
        Text('24-Hour Energy Curve', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(24, (i) {
              final energy = _report.profile.hourlyEnergy[i];
              return Expanded(
                child: Tooltip(
                  message: '${i}:00 — ${(energy * 100).round()}%',
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    height: 60 * energy,
                    decoration: BoxDecoration(
                      color: _energyBarColor(energy),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12 AM', style: theme.textTheme.bodySmall),
              Text('6 AM', style: theme.textTheme.bodySmall),
              Text('12 PM', style: theme.textTheme.bodySmall),
              Text('6 PM', style: theme.textTheme.bodySmall),
              Text('11 PM', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(
      ThemeData theme, String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
              Text(value,
                  style: theme.textTheme.titleSmall,
                  textAlign: TextAlign.center),
              Text(label,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2 — Profile (energy curve + peak windows)
  // ---------------------------------------------------------------------------

  Widget _buildProfileTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Energy Curve', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        // Full-height bars.
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(24, (i) {
              final energy = _report.profile.hourlyEnergy[i];
              final isPeak = i == _report.profile.peakHour;
              final isTrough = i == _report.profile.troughHour;
              return Expanded(
                child: Tooltip(
                  message:
                      '${i.toString().padLeft(2, '0')}:00\n${(energy * 100).round()}% energy'
                      '${isPeak ? '\n⚡ PEAK' : ''}${isTrough ? '\n💤 TROUGH' : ''}',
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    height: 180 * energy,
                    decoration: BoxDecoration(
                      color: isPeak
                          ? Colors.amber
                          : isTrough
                              ? Colors.blueGrey
                              : _energyBarColor(energy),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              8,
              (i) => Text('${i * 3}', style: theme.textTheme.bodySmall),
            ),
          ),
        ),

        const SizedBox(height: 24),
        Text('Optimal Task Windows', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (_report.peakWindows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No peak windows detected yet.'),
          )
        else
          ...(_report.peakWindows.map((pw) => Card(
                child: ListTile(
                  leading: Text(pw.taskType.emoji,
                      style: const TextStyle(fontSize: 28)),
                  title: Text(pw.taskType.label),
                  subtitle: Text(pw.timeRange),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(pw.confidenceScore * 100).round()}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _scoreColor(
                              (pw.confidenceScore * 100).round()),
                        ),
                      ),
                      Text('confidence', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ))),

        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Timing Stats', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                    '⚡ Peak energy at ${PeakWindow._formatHour(_report.profile.peakHour)}'),
                Text(
                    '💤 Energy trough at ${PeakWindow._formatHour(_report.profile.troughHour)}'),
                Text(
                    '📊 Timing variability: ±${_report.profile.timingVariability.toStringAsFixed(1)}h'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3 — Drift
  // ---------------------------------------------------------------------------

  Widget _buildDriftTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current drift status.
        Card(
          child: ListTile(
            leading: Text(_report.currentDrift.emoji,
                style: const TextStyle(fontSize: 32)),
            title: Text(_report.currentDrift.label,
                style: theme.textTheme.titleLarge),
            subtitle: Text(_report.currentDrift.description),
          ),
        ),
        const SizedBox(height: 16),

        // Weekly centroids.
        Text('Weekly Activity Centroids', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_report.weeklyCentroids.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Need more data to compute weekly centroids.'),
          )
        else
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _report.weeklyCentroids.map((c) {
                final normalized = (c.centroidHour / 24.0).clamp(0.0, 1.0);
                return Expanded(
                  child: Tooltip(
                    message:
                        'Week of ${c.weekStart.month}/${c.weekStart.day}\n'
                        'Centroid: ${c.centroidHour.toStringAsFixed(1)}h\n'
                        '${c.activityCount} activities',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        height: 120 * normalized,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(180),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 24),

        // Drift events list.
        Text('Drift Events', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_report.driftEvents.isEmpty)
          Card(
            child: ListTile(
              leading: const Text('⚓', style: TextStyle(fontSize: 24)),
              title: const Text('No drift detected'),
              subtitle: const Text('Your circadian rhythm is stable.'),
            ),
          )
        else
          ...(_report.driftEvents.map((evt) => Card(
                child: ListTile(
                  leading: Text(evt.type.emoji,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(evt.type.label),
                  subtitle: Text(evt.description),
                  trailing: Text(
                    '${evt.magnitudeHours.toStringAsFixed(1)}h',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: evt.magnitudeHours > 2.0
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                ),
              ))),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 4 — Insights
  // ---------------------------------------------------------------------------

  Widget _buildInsightsTab(ThemeData theme) {
    if (_report.insights.isEmpty) {
      return const Center(child: Text('No insights available yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _report.insights.length,
      itemBuilder: (context, index) {
        final insight = _report.insights[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(insight.severity.emoji,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(insight.title,
                          style: theme.textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(insight.body, style: theme.textTheme.bodyMedium),
                const Divider(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight.recommendation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.deepOrange;
    return Colors.red;
  }

  Color _energyBarColor(double energy) {
    if (energy > 0.8) return Colors.amber.shade600;
    if (energy > 0.6) return Colors.orange.shade400;
    if (energy > 0.4) return Colors.blue.shade400;
    if (energy > 0.2) return Colors.blue.shade300;
    return Colors.blueGrey.shade200;
  }
}
