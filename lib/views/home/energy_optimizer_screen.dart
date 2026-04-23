import 'package:flutter/material.dart';
import '../../core/services/energy_optimizer_service.dart';

/// Smart Energy Optimizer — autonomous energy prediction with cross-tracker
/// correlation, circadian modeling, and proactive work/rest window
/// recommendations.
class EnergyOptimizerScreen extends StatefulWidget {
  const EnergyOptimizerScreen({super.key});

  @override
  State<EnergyOptimizerScreen> createState() => _EnergyOptimizerScreenState();
}

class _EnergyOptimizerScreenState extends State<EnergyOptimizerScreen> {
  final _service = EnergyOptimizerService();
  int _selectedProfile = 2; // default: Balanced

  EnergyOptimization get _optimization =>
      _service.optimize(EnergyOptimizerService.profiles[_selectedProfile]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opt = _optimization;

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ Energy Optimizer'),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Switch profile',
            icon: const Icon(Icons.person_outline, size: 20),
            onSelected: (i) => setState(() => _selectedProfile = i),
            itemBuilder: (_) => [
              for (int i = 0; i < EnergyOptimizerService.profiles.length; i++)
                PopupMenuItem(
                  value: i,
                  child: Text(
                    '${EnergyOptimizerService.profiles[i].emoji} '
                    '${EnergyOptimizerService.profiles[i].name}',
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _profileCard(theme, opt),
          const SizedBox(height: 16),
          _scoreCard(theme, opt),
          const SizedBox(height: 16),
          _energyCurve(theme, opt),
          const SizedBox(height: 16),
          _windowsSection(theme, opt),
          const SizedBox(height: 16),
          _peakTroughCard(theme, opt),
          const SizedBox(height: 16),
          _recommendationsSection(theme, opt),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _profileCard(ThemeData theme, EnergyOptimization opt) {
    final p = opt.profile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(p.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(p.description,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard(ThemeData theme, EnergyOptimization opt) {
    final score = opt.overallScore;
    final color = score >= 70
        ? Colors.green
        : score >= 50
            ? Colors.orange
            : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text('Overall Energy Score',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 12),
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
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
          ],
        ),
      ),
    );
  }

  Widget _energyCurve(ThemeData theme, EnergyOptimization opt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('24-Hour Energy Curve',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final signal in opt.hourlyEnergy) ...[
                    Expanded(
                      child: Tooltip(
                        message:
                            '${signal.hour}:00 — ${signal.energyScore.toStringAsFixed(0)}%',
                        child: Container(
                          height: (signal.energyScore / 100 * 110) + 2,
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          decoration: BoxDecoration(
                            color: _barColor(signal.energyScore),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('12AM', style: theme.textTheme.labelSmall),
                Text('6AM', style: theme.textTheme.labelSmall),
                Text('12PM', style: theme.textTheme.labelSmall),
                Text('6PM', style: theme.textTheme.labelSmall),
                Text('11PM', style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                _legend(Colors.green, '>70 High'),
                _legend(Colors.orange, '50–70 Med'),
                _legend(Colors.red.shade300, '<50 Low'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Color _barColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red.shade300;
  }

  Widget _windowsSection(ThemeData theme, EnergyOptimization opt) {
    if (opt.windows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recommended Schedule',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final w in opt.windows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _windowColor(w.type).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(w.type.emoji, style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.type.label,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text(w.timeRange,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor)),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _windowColor(w.type).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(w.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: _windowColor(w.type),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _windowColor(WindowType t) {
    switch (t) {
      case WindowType.deepWork:
        return Colors.blue;
      case WindowType.lightWork:
        return Colors.cyan;
      case WindowType.creative:
        return Colors.purple;
      case WindowType.exercise:
        return Colors.orange;
      case WindowType.rest:
        return Colors.green;
    }
  }

  Widget _peakTroughCard(ThemeData theme, EnergyOptimization opt) {
    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.green.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('🔋', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text('Peak',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: Colors.green)),
                  Text(_fmtHour(opt.peakHour),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    '${opt.hourlyEnergy[opt.peakHour].energyScore.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            color: Colors.red.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('🪫', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text('Trough',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: Colors.red)),
                  Text(_fmtHour(opt.troughHour),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    '${opt.hourlyEnergy[opt.troughHour].energyScore.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _recommendationsSection(ThemeData theme, EnergyOptimization opt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Proactive Recommendations',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final rec in opt.recommendations)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(rec, style: theme.textTheme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtHour(int h) =>
      '${h % 12 == 0 ? 12 : h % 12}:00 ${h < 12 ? 'AM' : 'PM'}';
}
