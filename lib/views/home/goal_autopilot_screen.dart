import 'package:flutter/material.dart';
import '../../core/services/goal_autopilot_service.dart';
import '../../core/services/goal_tracker_service.dart';
import '../../models/goal.dart';

/// Goal Autopilot — autonomous goal monitoring with completion prediction,
/// stall detection, velocity tracking, and proactive recommendations.
///
/// Analyzes all active goals and surfaces risks before they become problems.
class GoalAutopilotScreen extends StatefulWidget {
  const GoalAutopilotScreen({super.key});

  @override
  State<GoalAutopilotScreen> createState() => _GoalAutopilotScreenState();
}

class _GoalAutopilotScreenState extends State<GoalAutopilotScreen> {
  final _autopilot = GoalAutopilotService();
  final _goalService = GoalTrackerService();
  late List<Goal> _goals;
  bool _useDemo = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() {
    final realGoals = _goalService.inProgressGoals;
    if (realGoals.isNotEmpty) {
      _goals = realGoals;
      _useDemo = false;
    } else {
      _goals = _autopilot.getSampleGoals();
      _useDemo = true;
    }
  }

  void _toggleDataSource() {
    setState(() {
      if (_useDemo) {
        final real = _goalService.inProgressGoals;
        if (real.isNotEmpty) {
          _goals = real;
          _useDemo = false;
        }
      } else {
        _goals = _autopilot.getSampleGoals();
        _useDemo = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fleet = _autopilot.analyzeFleet(_goals);
    final analyses =
        _goals.map((g) => _autopilot.analyzeGoal(g)).toList()
          ..sort((a, b) => a.healthScore.compareTo(b.healthScore));

    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 Goal Autopilot'),
        actions: [
          if (_goalService.inProgressGoals.isNotEmpty)
            TextButton.icon(
              onPressed: _toggleDataSource,
              icon: Icon(_useDemo ? Icons.data_object : Icons.play_arrow,
                  size: 18),
              label: Text(_useDemo ? 'Real Data' : 'Demo'),
            ),
        ],
      ),
      body: analyses.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rocket_launch,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('No active goals',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Add goals in the Goal Tracker to get started'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_useDemo)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Showing demo data. Add goals in Goal Tracker to see your real analysis.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildFleetDashboard(theme, fleet),
                const SizedBox(height: 20),
                _buildTopActions(theme, fleet),
                const SizedBox(height: 20),
                Text('Goal Health Report',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...analyses.map((a) => _buildGoalCard(theme, a)),
              ],
            ),
    );
  }

  Widget _buildFleetDashboard(ThemeData theme, GoalFleetSummary fleet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Fleet Overview',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _healthColor(fleet.avgHealth).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${fleet.avgHealth.toStringAsFixed(0)}% health',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _healthColor(fleet.avgHealth),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatPill('${fleet.totalActive}', 'Active', Colors.blue),
              const SizedBox(width: 8),
              _buildStatPill('${fleet.onTrack}', 'On Track', Colors.green),
              const SizedBox(width: 8),
              _buildStatPill(
                  '${fleet.slipping}', 'Slipping', Colors.orange),
              const SizedBox(width: 8),
              _buildStatPill('${fleet.stalled}', 'Stalled', Colors.red),
              if (fleet.critical > 0) ...[
                const SizedBox(width: 8),
                _buildStatPill(
                    '${fleet.critical}', 'Critical', Colors.purple),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Health bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fleet.avgHealth / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(
                  _healthColor(fleet.avgHealth)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color)),
            Text(label,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActions(ThemeData theme, GoalFleetSummary fleet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high, size: 20),
              const SizedBox(width: 8),
              Text('🎯 Priority Actions',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          ...fleet.topActions.map((action) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('→ ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(action)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildGoalCard(ThemeData theme, GoalAnalysis analysis) {
    final goal = analysis.goal;
    final riskColor = _riskColor(analysis.risk);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: riskColor.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(goal.category.emoji, style: const TextStyle(fontSize: 24)),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(goal.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${analysis.risk.emoji} ${analysis.risk.label}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: riskColor),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goal.effectiveProgress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(riskColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(goal.effectiveProgress * 100).toStringAsFixed(0)}% complete • Health: ${analysis.healthScore.toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics row
                Row(
                  children: [
                    _buildMetric(
                        'Velocity',
                        '${(analysis.velocity * 100).toStringAsFixed(1)}%/day',
                        Icons.speed),
                    const SizedBox(width: 16),
                    if (analysis.predictedCompletion != null)
                      _buildMetric(
                          'ETA',
                          _formatDate(analysis.predictedCompletion!),
                          Icons.event),
                    if (analysis.daysAhead != null) ...[
                      const SizedBox(width: 16),
                      _buildMetric(
                        'Schedule',
                        analysis.daysAhead! >= 0
                            ? '${analysis.daysAhead}d ahead'
                            : '${analysis.daysAhead!.abs()}d behind',
                        analysis.daysAhead! >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                      ),
                    ],
                  ],
                ),
                if (goal.deadline != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Deadline: ${_formatDate(goal.deadline!)} (${goal.daysRemaining ?? 0} days left)',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
                // Milestones
                if (goal.milestones.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Milestones',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...goal.milestones.map((m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              m.isCompleted
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color:
                                  m.isCompleted ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(m.title,
                                style: TextStyle(
                                  decoration: m.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                )),
                          ],
                        ),
                      )),
                ],
                // Recommendations
                if (analysis.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: riskColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🤖 Autopilot Recommendations',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ...analysis.recommendations.map((r) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(child: Text(r)),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Color _healthColor(double health) {
    if (health >= 70) return Colors.green;
    if (health >= 45) return Colors.orange;
    return Colors.red;
  }

  Color _riskColor(GoalRisk risk) {
    switch (risk) {
      case GoalRisk.onTrack:
        return Colors.green;
      case GoalRisk.slipping:
        return Colors.orange;
      case GoalRisk.stalled:
        return Colors.red;
      case GoalRisk.critical:
        return Colors.purple;
    }
  }
}
