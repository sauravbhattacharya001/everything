import 'package:flutter/material.dart';
import '../../core/services/balance_radar_engine_service.dart';

/// Life Balance Radar — autonomous multi-dimensional life balance assessment.
///
/// Analyses activity across 8 life dimensions, detects imbalances, computes
/// a composite balance score 0-100, and generates rebalancing recommendations.
///
/// 4 tabs: Radar · Alerts · Recommendations · Insights
class BalanceRadarScreen extends StatefulWidget {
  const BalanceRadarScreen({super.key});

  @override
  State<BalanceRadarScreen> createState() => _BalanceRadarScreenState();
}

class _BalanceRadarScreenState extends State<BalanceRadarScreen>
    with SingleTickerProviderStateMixin {
  final BalanceRadarEngineService _service = BalanceRadarEngineService();
  late TabController _tabController;

  BalanceSnapshot? _snapshot;
  List<ImbalanceAlert> _alerts = [];
  List<RebalanceRecommendation> _recommendations = [];
  List<String> _insights = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _runAnalysis();
  }

  void _runAnalysis() {
    _service.reset();
    _service.generateDemoData();
    final snapshot = _service.takeSnapshot();
    final recs = _service.generateRecommendations();
    final insights = _service.generateInsights();
    setState(() {
      _snapshot = snapshot;
      _alerts = snapshot.alerts;
      _recommendations = recs;
      _insights = insights;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Summary banner ─────────────────────────────────────────

  Widget _buildBanner() {
    final snap = _snapshot;
    if (snap == null) return const SizedBox.shrink();

    final trend = snap.trend;
    Color trendColor;
    switch (trend) {
      case BalanceTrend.improving:
        trendColor = Colors.green;
        break;
      case BalanceTrend.declining:
        trendColor = Colors.red;
        break;
      case BalanceTrend.volatile:
        trendColor = Colors.orange;
        break;
      case BalanceTrend.stable:
        trendColor = Colors.blue;
        break;
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snap.compositeScore.toStringAsFixed(0),
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const Text('Balance Score',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      trend == BalanceTrend.improving
                          ? Icons.trending_up
                          : trend == BalanceTrend.declining
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      color: trendColor,
                    ),
                    const SizedBox(width: 4),
                    Text(trend.label,
                        style: TextStyle(color: trendColor, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    'Gini: ${snap.giniCoefficient.toStringAsFixed(2)}',
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 13)),
                Text('${_alerts.length} alerts',
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Radar tab ──────────────────────────────────────────────

  Widget _buildRadarTab() {
    final snap = _snapshot;
    if (snap == null) return const Center(child: CircularProgressIndicator());

    final sorted = snap.dimensionScores.entries.toList()
      ..sort((a, b) => b.value.score.compareTo(a.value.score));

    return ListView(
      children: [
        _buildBanner(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Dimension Scores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...sorted.map((entry) {
          final dim = entry.key;
          final ds = entry.value;
          Color barColor;
          if (ds.score < 30) {
            barColor = Colors.red;
          } else if (ds.score < 50) {
            barColor = Colors.orange;
          } else if (ds.score < 70) {
            barColor = Colors.amber;
          } else {
            barColor = Colors.green;
          }
          return ListTile(
            leading: Text(dim.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(dim.label),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: ds.score / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ds.score.toStringAsFixed(0)}/100 · ${ds.activityCount} activities · ${ds.trend.arrow}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: Text(
              ds.score.toStringAsFixed(0),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: barColor),
            ),
          );
        }),
      ],
    );
  }

  // ─── Alerts tab ─────────────────────────────────────────────

  Widget _buildAlertsTab() {
    if (_alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text('No imbalances detected!',
                style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _alerts.length,
      itemBuilder: (ctx, i) {
        final alert = _alerts[i];
        Color severityColor;
        if (alert.severity > 60) {
          severityColor = Colors.red;
        } else if (alert.severity > 30) {
          severityColor = Colors.orange;
        } else {
          severityColor = Colors.amber;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.warning_rounded, color: severityColor),
            title: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(alert.type.label,
                      style: TextStyle(
                          fontSize: 11, color: severityColor)),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(alert.description,
                        style: const TextStyle(fontSize: 14))),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('💡 ${alert.suggestion}',
                  style: const TextStyle(fontSize: 12)),
            ),
          ),
        );
      },
    );
  }

  // ─── Recommendations tab ────────────────────────────────────

  Widget _buildRecommendationsTab() {
    if (_recommendations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.thumb_up, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text('All balanced — no action needed!',
                style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _recommendations.length,
      itemBuilder: (ctx, i) {
        final rec = _recommendations[i];
        Color priorityColor;
        switch (rec.priority) {
          case RecommendationPriority.critical:
            priorityColor = Colors.red;
            break;
          case RecommendationPriority.high:
            priorityColor = Colors.orange;
            break;
          case RecommendationPriority.medium:
            priorityColor = Colors.amber;
            break;
          case RecommendationPriority.low:
            priorityColor = Colors.blue;
            break;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(rec.priority.label,
                          style: TextStyle(
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        '${rec.targetDimension.emoji} ${rec.targetDimension.label}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(rec.action, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(rec.reasoning,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                        'Score: ${rec.currentScore.toStringAsFixed(0)} → ${rec.targetScore.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    Text(
                        'Impact: +${rec.estimatedImpact.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 12, color: priorityColor)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Insights tab ───────────────────────────────────────────

  Widget _buildInsightsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Balance Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ..._insights.map((insight) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(insight, style: const TextStyle(fontSize: 14)),
              ),
            )),
        if (_snapshot != null) ...[
          const Divider(height: 32),
          const Text('Report Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Composite Score: ${_snapshot!.compositeScore.toStringAsFixed(1)}'),
                  Text('Gini Coefficient: ${_snapshot!.giniCoefficient.toStringAsFixed(3)}'),
                  Text('Active Alerts: ${_alerts.length}'),
                  Text('Recommendations: ${_recommendations.length}'),
                  Text('Total Activities: ${_service.activities.length}'),
                  Text('Trend: ${_snapshot!.trend.label} ${_snapshot!.trend.arrow}'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚖️ Life Balance Radar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.radar), text: 'Radar'),
            Tab(icon: Icon(Icons.warning), text: 'Alerts'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Advice'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRadarTab(),
          _buildAlertsTab(),
          _buildRecommendationsTab(),
          _buildInsightsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _runAnalysis();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Balance radar refreshed')),
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
