import 'package:flutter/material.dart';
import '../../core/services/burnout_detector_service.dart';

/// Smart Burnout Detector — autonomous burnout risk analysis with
/// multi-signal monitoring, pattern detection, resilience scoring,
/// and proactive recovery recommendations.
class BurnoutDetectorScreen extends StatefulWidget {
  const BurnoutDetectorScreen({super.key});

  @override
  State<BurnoutDetectorScreen> createState() => _BurnoutDetectorScreenState();
}

class _BurnoutDetectorScreenState extends State<BurnoutDetectorScreen> {
  final _service = BurnoutDetectorService();
  late List<BurnoutScenario> _scenarios;
  int _selectedScenario = 1; // default: Early Warning

  @override
  void initState() {
    super.initState();
    _scenarios = _service.getSampleScenarios();
  }

  BurnoutAnalysis get _analysis =>
      _service.analyzeSignals(_scenarios[_selectedScenario].signals);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysis = _analysis;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Burnout Detector'),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Switch scenario',
            icon: const Icon(Icons.science, size: 20),
            onSelected: (i) => setState(() => _selectedScenario = i),
            itemBuilder: (_) => [
              for (int i = 0; i < _scenarios.length; i++)
                PopupMenuItem(
                  value: i,
                  child: Row(children: [
                    if (i == _selectedScenario)
                      const Icon(Icons.check, size: 16)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(_scenarios[i].name),
                  ]),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Scenario label ──
          Center(
            child: Chip(
              avatar: const Icon(Icons.science, size: 16),
              label: Text(
                  '${_scenarios[_selectedScenario].name} — ${_scenarios[_selectedScenario].description}'),
            ),
          ),
          const SizedBox(height: 16),

          // ── Risk gauge ──
          _buildRiskGauge(theme, analysis),
          const SizedBox(height: 24),

          // ── Signals grid ──
          Text('📡 Wellness Signals',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildSignalGrid(theme, analysis.signals),
          const SizedBox(height: 24),

          // ── Warning patterns ──
          if (analysis.warningPatterns.isNotEmpty) ...[
            Text('⚠️ Warning Patterns (${analysis.warningPatterns.length})',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...analysis.warningPatterns.map((p) => _buildPatternCard(theme, p)),
            const SizedBox(height: 24),
          ],

          // ── Recommendations ──
          Text('💡 Recommendations',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...analysis.recommendations.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.15),
                        child: Text('${e.key + 1}',
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.value)),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 24),

          // ── Recovery plan ──
          Text('🗺️ Recovery Plan',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildRecoveryPlan(theme, analysis.recoveryPlan),
        ],
      ),
    );
  }

  // ── Risk gauge ────────────────────────────────────────────

  Widget _buildRiskGauge(ThemeData theme, BurnoutAnalysis analysis) {
    final color = _riskColor(analysis.overallRisk);
    return Row(
      children: [
        // Circular gauge
        Expanded(
          child: Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: analysis.riskScore / 100,
                      strokeWidth: 12,
                      backgroundColor: color.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(analysis.riskScore.round().toString(),
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold, color: color)),
                      Text(analysis.overallRisk.label,
                          style: theme.textTheme.bodySmall?.copyWith(color: color)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Resilience badge
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.shield,
                      size: 36,
                      color: analysis.resilienceScore >= 50
                          ? Colors.green
                          : Colors.orange),
                  const SizedBox(height: 8),
                  Text('${analysis.resilienceScore.round()}',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Resilience',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Signals grid ──────────────────────────────────────────

  Widget _buildSignalGrid(ThemeData theme, List<BurnoutSignal> signals) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: signals.map((s) => _buildSignalCard(theme, s)).toList(),
    );
  }

  Widget _buildSignalCard(ThemeData theme, BurnoutSignal s) {
    final color = s.value >= 60
        ? Colors.green
        : s.value >= 35
            ? Colors.orange
            : Colors.red;
    final icon = _categoryIcon(s.category);
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(s.name,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis)),
                Text(s.trend.arrow,
                    style: TextStyle(
                        color: s.trend == SignalTrend.improving
                            ? Colors.green
                            : s.trend == SignalTrend.declining
                                ? Colors.red
                                : Colors.grey)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: s.value / 100,
                  minHeight: 6,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 2),
              Text('${s.value.round()}/100',
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: color, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Warning pattern card ──────────────────────────────────

  Widget _buildPatternCard(ThemeData theme, WarningPattern p) {
    final sevColor = p.severity == 'severe'
        ? Colors.red
        : p.severity == 'moderate'
            ? Colors.orange
            : Colors.yellow.shade700;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(Icons.warning_amber, color: sevColor, size: 20),
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(p.severity.toUpperCase(),
            style: TextStyle(fontSize: 11, color: sevColor)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(p.description),
          ),
        ],
      ),
    );
  }

  // ── Recovery plan ─────────────────────────────────────────

  Widget _buildRecoveryPlan(ThemeData theme, List<RecoveryStep> plan) {
    final phases = ['Immediate', 'Short-term', 'Medium-term'];
    final phaseIcons = [Icons.flash_on, Icons.date_range, Icons.trending_up];

    return Column(
      children: [
        for (int i = 0; i < phases.length; i++) ...[
          if (plan.any((s) => s.phase == phases[i]))
            ExpansionTile(
              leading: Icon(phaseIcons[i], color: theme.colorScheme.primary),
              title: Text(phases[i],
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              initiallyExpanded: i == 0,
              children: [
                for (final step in plan.where((s) => s.phase == phases[i]))
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.check_circle_outline, size: 18),
                    title: Text(step.action, style: theme.textTheme.bodyMedium),
                  ),
              ],
            ),
        ],
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Color _riskColor(BurnoutRiskLevel risk) {
    switch (risk) {
      case BurnoutRiskLevel.low:
        return Colors.green;
      case BurnoutRiskLevel.moderate:
        return Colors.amber;
      case BurnoutRiskLevel.elevated:
        return Colors.orange;
      case BurnoutRiskLevel.high:
        return Colors.red;
      case BurnoutRiskLevel.critical:
        return Colors.red.shade900;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'sleep':
        return Icons.bedtime;
      case 'mood':
        return Icons.mood;
      case 'energy':
        return Icons.bolt;
      case 'activity':
        return Icons.directions_run;
      case 'social':
        return Icons.people;
      case 'nutrition':
        return Icons.restaurant;
      default:
        return Icons.circle;
    }
  }
}
