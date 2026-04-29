import 'package:flutter/material.dart';
import '../../core/services/willpower_budget_service.dart';

/// Willpower Budget — autonomous cognitive resource manager that visualizes
/// daily willpower drain, predicts fatigue, and recommends recovery actions.
class WillpowerBudgetScreen extends StatefulWidget {
  const WillpowerBudgetScreen({super.key});

  @override
  State<WillpowerBudgetScreen> createState() => _WillpowerBudgetScreenState();
}

class _WillpowerBudgetScreenState extends State<WillpowerBudgetScreen> {
  final _service = WillpowerBudgetService();

  @override
  void initState() {
    super.initState();
    _service.loadSampleDay();
  }

  Color _zoneColor(WillpowerZone zone) {
    switch (zone) {
      case WillpowerZone.fullTank:
        return Colors.green;
      case WillpowerZone.comfortable:
        return Colors.lightGreen;
      case WillpowerZone.stretching:
        return Colors.orange;
      case WillpowerZone.depleted:
        return Colors.red;
      case WillpowerZone.empty:
        return Colors.grey;
    }
  }

  void _showLogDemandSheet() {
    var selectedType = CognitiveDemandType.decision;
    var intensity = 5.0;
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Log Cognitive Demand',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<CognitiveDemandType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Demand Type',
                  border: OutlineInputBorder(),
                ),
                items: CognitiveDemandType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text('${t.emoji} ${t.label}'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheetState(() => selectedType = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text('Intensity: ${intensity.round()}',
                  style: Theme.of(ctx).textTheme.bodyMedium),
              Slider(
                value: intensity,
                min: 1,
                max: 10,
                divisions: 9,
                label: intensity.round().toString(),
                onChanged: (v) => setSheetState(() => intensity = v),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  _service.logDemand(
                    selectedType,
                    description: descController.text,
                    intensity: intensity.round(),
                  );
                  Navigator.pop(ctx);
                  setState(() {});
                },
                icon: const Icon(Icons.add),
                label: const Text('Log Demand'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = _service.getDayReport();
    final zone = report.zone;
    final zoneCol = _zoneColor(zone);

    return Scaffold(
      appBar: AppBar(title: const Text('Willpower Budget')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogDemandSheet,
        tooltip: 'Log Demand',
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Budget Gauge ──
          _buildGaugeCard(theme, report, zoneCol),
          const SizedBox(height: 16),

          // ── Zone Banner ──
          _buildZoneBanner(theme, zone, zoneCol),
          const SizedBox(height: 16),

          // ── Day Stats ──
          _buildStatsRow(theme, report),
          const SizedBox(height: 16),

          // ── Recommendations ──
          if (report.recommendations.isNotEmpty) ...[
            Text('Recommendations',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...report.recommendations.map((r) => _buildRecommendationTile(theme, r)),
            const SizedBox(height: 16),
          ],

          // ── Demand Breakdown ──
          _buildBreakdownCard(theme),
          const SizedBox(height: 16),

          // ── Recovery Actions ──
          Text('Recovery Actions',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildRecoveryGrid(theme),
          const SizedBox(height: 16),

          // ── Fatigue Forecast ──
          if (report.fatigueWindows.isNotEmpty) ...[
            Text('Fatigue Forecast',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...report.fatigueWindows.map((w) => _buildFatigueWindowTile(theme, w)),
            const SizedBox(height: 16),
          ],

          // ── Today's Demands ──
          Text('Today\'s Demands (${_service.demands.length})',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._service.demands.reversed.map((d) => _buildDemandTile(theme, d)),
          const SizedBox(height: 80), // FAB clearance
        ],
      ),
    );
  }

  // ── Widgets ──

  Widget _buildGaugeCard(
      ThemeData theme, WillpowerDayReport report, Color zoneCol) {
    final budget = report.currentBudget;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                      value: budget / 100,
                      strokeWidth: 14,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: zoneCol,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(report.zone.emoji,
                          style: const TextStyle(fontSize: 28)),
                      Text('${budget.round()}',
                          style: theme.textTheme.headlineLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('/ 100',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(report.zone.label,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: zoneCol, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneBanner(ThemeData theme, WillpowerZone zone, Color zoneCol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: zoneCol.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zoneCol.withAlpha(80)),
      ),
      child: Row(
        children: [
          Text(zone.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(zone.advice,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: zoneCol.withAlpha(220))),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, WillpowerDayReport report) {
    return Row(
      children: [
        _statCard(theme, '🔥', 'Drain', report.totalDrain.round().toString()),
        const SizedBox(width: 8),
        _statCard(theme, '💚', 'Recovery', report.totalRecovery.round().toString()),
        const SizedBox(width: 8),
        _statCard(theme, '🎯', 'Score', '${report.strategicScore}'),
        const SizedBox(width: 8),
        _statCard(theme, '📊', 'Demands', '${report.totalDemands}'),
      ],
    );
  }

  Widget _statCard(ThemeData theme, String emoji, String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationTile(
      ThemeData theme, WillpowerRecommendation rec) {
    return Card(
      child: ListTile(
        leading: Text(rec.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(rec.title),
        subtitle: Text(rec.description, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: rec.recoveryAction != null
            ? ActionChip(
                label: Text(rec.recoveryAction!.label,
                    style: const TextStyle(fontSize: 11)),
                onPressed: () {
                  _service.logRecovery(rec.recoveryAction!);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        '${rec.recoveryAction!.emoji} +${rec.recoveryAction!.recoveryPoints} willpower'),
                  ));
                },
              )
            : null,
      ),
    );
  }

  Widget _buildBreakdownCard(ThemeData theme) {
    final breakdown = _service.getDemandBreakdown();
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Demand Breakdown',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...sorted.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(e.key.emoji,
                            style: const TextStyle(fontSize: 16)),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(e.key.label,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: maxVal > 0 ? e.value / maxVal : 0,
                            minHeight: 14,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 32,
                        child: Text(e.value.round().toString(),
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryGrid(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RecoveryAction.values.map((action) {
        return ActionChip(
          avatar: Text(action.emoji),
          label: Text('${action.label}\n+${action.recoveryPoints}pts · ${action.durationMinutes}m',
              style: const TextStyle(fontSize: 11)),
          onPressed: () {
            _service.logRecovery(action);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '${action.emoji} ${action.label}: +${action.recoveryPoints} willpower restored'),
            ));
          },
        );
      }).toList(),
    );
  }

  Widget _buildFatigueWindowTile(ThemeData theme, FatigueWindow window) {
    final col = _zoneColor(window.riskLevel);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: col.withAlpha(30),
          child: Text(window.riskLevel.emoji),
        ),
        title: Text(
            '${window.startHour.toString().padLeft(2, '0')}:00 – ${window.endHour.toString().padLeft(2, '0')}:00'),
        subtitle: Text(window.explanation),
        trailing: Text('${window.predictedBudget.round()}%',
            style: theme.textTheme.titleMedium?.copyWith(color: col)),
      ),
    );
  }

  Widget _buildDemandTile(ThemeData theme, CognitiveDemand demand) {
    return Card(
      child: ListTile(
        leading: Text(demand.type.emoji, style: const TextStyle(fontSize: 22)),
        title: Text(demand.description),
        subtitle: Text(
            '${demand.type.label} · Intensity ${demand.intensity}/10 · Cost ${demand.actualCost.round()}'),
        trailing: Text(
          '${demand.timestamp.hour.toString().padLeft(2, '0')}:${demand.timestamp.minute.toString().padLeft(2, '0')}',
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}
