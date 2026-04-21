import 'package:flutter/material.dart';
import '../../core/services/streak_guardian_service.dart';

/// Smart Streak Guardian — autonomous streak risk monitoring across
/// all trackers with proactive warnings and rescue strategies.
class StreakGuardianScreen extends StatefulWidget {
  const StreakGuardianScreen({super.key});

  @override
  State<StreakGuardianScreen> createState() => _StreakGuardianScreenState();
}

class _StreakGuardianScreenState extends State<StreakGuardianScreen> {
  final _guardian = StreakGuardianService();
  late List<Map<String, dynamic>> _trackers;
  String _sortBy = 'risk'; // risk, streak, name

  @override
  void initState() {
    super.initState();
    _trackers = _guardian.getSampleTrackers();
  }

  List<StreakAnalysis> _getSortedAnalyses() {
    final analyses = _trackers.map((t) => _guardian.analyzeTracker(t)).toList();
    switch (_sortBy) {
      case 'risk':
        analyses.sort((a, b) {
          final riskCmp = b.risk.index.compareTo(a.risk.index);
          if (riskCmp != 0) return riskCmp;
          return b.currentStreak.compareTo(a.currentStreak);
        });
        break;
      case 'streak':
        analyses.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
        break;
      case 'name':
        analyses.sort((a, b) => a.trackerName.compareTo(b.trackerName));
        break;
    }
    return analyses;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fleet = _guardian.analyzeFleet(_trackers);
    final analyses = _getSortedAnalyses();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Streak Guardian'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'risk', child: Text('Sort by Risk')),
              const PopupMenuItem(value: 'streak', child: Text('Sort by Streak')),
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Fleet summary card
          _buildFleetCard(theme, fleet),
          const SizedBox(height: 16),

          // Verdict banner
          _buildVerdictBanner(theme, fleet),
          const SizedBox(height: 16),

          // Top actions
          if (fleet.topActions.isNotEmpty) ...[
            Text('Priority Actions',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...fleet.topActions.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(a, style: theme.textTheme.bodyMedium),
                )),
            const SizedBox(height: 16),
          ],

          // Individual tracker cards
          Text('Streak Monitor',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...analyses.map((a) => _buildTrackerCard(theme, a)),
        ],
      ),
    );
  }

  Widget _buildFleetCard(ThemeData theme, StreakFleetSummary fleet) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield, size: 28),
                const SizedBox(width: 8),
                Text('Fleet Overview',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            // Health gauge
            _buildHealthGauge(theme, fleet.overallHealth),
            const SizedBox(height: 16),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip('Active', '${fleet.activeStreaks}', Colors.green),
                _buildStatChip('Total Days', '${fleet.totalStreakDays}', Colors.blue),
                _buildStatChip('At Risk', '${fleet.inDanger + fleet.critical}',
                    fleet.inDanger + fleet.critical > 0 ? Colors.orange : Colors.grey),
                _buildStatChip('Broken', '${fleet.broken}',
                    fleet.broken > 0 ? Colors.red : Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            // Risk breakdown
            Row(
              children: [
                _buildRiskDot('🛡️', fleet.safe, Colors.green),
                const SizedBox(width: 12),
                _buildRiskDot('👀', fleet.watching, Colors.amber),
                const SizedBox(width: 12),
                _buildRiskDot('⚠️', fleet.inDanger, Colors.orange),
                const SizedBox(width: 12),
                _buildRiskDot('🚨', fleet.critical, Colors.red),
                const SizedBox(width: 12),
                _buildRiskDot('💔', fleet.broken, Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthGauge(ThemeData theme, double health) {
    final color = health >= 80
        ? Colors.green
        : health >= 60
            ? Colors.amber
            : health >= 40
                ? Colors.orange
                : Colors.red;
    return Column(
      children: [
        Text('Overall Health',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: health / 100,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Text('${health.round()}',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildRiskDot(String emoji, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 2),
        Text('$count',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }

  Widget _buildVerdictBanner(ThemeData theme, StreakFleetSummary fleet) {
    Color bg;
    if (fleet.critical > 0) {
      bg = Colors.red.shade50;
    } else if (fleet.inDanger > 0) {
      bg = Colors.orange.shade50;
    } else if (fleet.watching > 0) {
      bg = Colors.amber.shade50;
    } else {
      bg = Colors.green.shade50;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(fleet.guardianVerdict,
          style: theme.textTheme.bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center),
    );
  }

  Widget _buildTrackerCard(ThemeData theme, StreakAnalysis analysis) {
    final riskColor = _riskColor(analysis.risk);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: riskColor.withValues(alpha: 0.4),
          width: analysis.risk.index >= StreakRisk.danger.index ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        leading: Text(analysis.trackerEmoji,
            style: const TextStyle(fontSize: 28)),
        title: Row(
          children: [
            Expanded(
              child: Text(analysis.trackerName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${analysis.risk.emoji} ${analysis.risk.label}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: riskColor),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              analysis.currentStreak > 0
                  ? '🔥 ${analysis.currentStreak} days'
                  : 'No active streak',
              style: TextStyle(
                  fontSize: 13,
                  color: analysis.currentStreak > 0
                      ? Colors.deepOrange
                      : Colors.grey),
            ),
            const SizedBox(width: 8),
            if (analysis.completedToday)
              const Text('✅', style: TextStyle(fontSize: 13))
            else
              Text(analysis.timeRemaining,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Health bar
                Row(
                  children: [
                    const Text('Health: ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: analysis.healthScore / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                            _healthColor(analysis.healthScore)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${analysis.healthScore.round()}%',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),

                // Stats
                Wrap(
                  spacing: 16,
                  children: [
                    Text('Best: ${analysis.longestStreak}d',
                        style: const TextStyle(fontSize: 12)),
                    Text(
                        'Weekly: ${(analysis.weeklyConsistency * 100).round()}%',
                        style: const TextStyle(fontSize: 12)),
                    if (analysis.predictedBreakDay != null)
                      Text('⚡ Break risk in ~${analysis.predictedBreakDay}d',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.red)),
                  ],
                ),

                // Insights
                if (analysis.insights.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...analysis.insights.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(i, style: const TextStyle(fontSize: 12)),
                      )),
                ],

                // Rescue strategies
                if (analysis.rescueStrategies.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Rescue Strategies',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...analysis.rescueStrategies.map((r) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.emoji,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(r.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13)),
                                      ),
                                      Text('~${r.effortMinutes}m',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600)),
                                    ],
                                  ),
                                  Text(r.description,
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _riskColor(StreakRisk risk) {
    switch (risk) {
      case StreakRisk.safe:
        return Colors.green;
      case StreakRisk.watch:
        return Colors.amber.shade700;
      case StreakRisk.danger:
        return Colors.orange;
      case StreakRisk.critical:
        return Colors.red;
      case StreakRisk.broken:
        return Colors.grey;
    }
  }

  Color _healthColor(double health) {
    if (health >= 80) return Colors.green;
    if (health >= 60) return Colors.amber;
    if (health >= 40) return Colors.orange;
    return Colors.red;
  }
}
