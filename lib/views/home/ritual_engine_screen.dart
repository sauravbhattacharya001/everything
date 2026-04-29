import 'package:flutter/material.dart';
import '../../core/services/ritual_engine_service.dart';

/// Ritual Engine — autonomous daily ritual optimizer that visualizes
/// ritual chain health, detects disruptions, and suggests micro-adjustments.
class RitualEngineScreen extends StatefulWidget {
  const RitualEngineScreen({super.key});

  @override
  State<RitualEngineScreen> createState() => _RitualEngineScreenState();
}

class _RitualEngineScreenState extends State<RitualEngineScreen> {
  final _service = RitualEngineService();
  late RitualChainReport _report;

  @override
  void initState() {
    super.initState();
    _service.loadSampleDay();
    _report = _service.analyzeToday();
  }

  void _refresh() {
    setState(() {
      _report = _service.analyzeToday();
    });
  }

  Color _rhythmColor(RhythmState state) {
    switch (state) {
      case RhythmState.lockedIn:
        return Colors.green;
      case RhythmState.consistent:
        return Colors.lightGreen;
      case RhythmState.drifting:
        return Colors.amber;
      case RhythmState.disrupted:
        return Colors.deepOrange;
      case RhythmState.abandoned:
        return Colors.grey;
    }
  }

  Color _severityColor(int severity) {
    if (severity >= 70) return Colors.red;
    if (severity >= 40) return Colors.orange;
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ritual Engine'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.self_improvement), text: 'Rituals'),
              Tab(icon: Icon(Icons.warning_amber), text: 'Disruptions'),
              Tab(icon: Icon(Icons.lightbulb), text: 'Adjustments'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDashboardTab(),
            _buildRitualsTab(),
            _buildDisruptionsTab(),
            _buildAdjustmentsTab(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dashboard Tab
  // ---------------------------------------------------------------------------

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chain Score Gauge
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Chain Health',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _report.chainScore / 100.0,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade200,
                          color: _rhythmColor(_report.overallState),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_report.chainScore}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text('/100',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    avatar: Text(_report.overallState.emoji),
                    label: Text(_report.overallState.label),
                    backgroundColor: _rhythmColor(_report.overallState).withOpacity(0.15),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange),
                        const SizedBox(height: 4),
                        Text('${_report.streakDays}',
                            style: Theme.of(context).textTheme.titleLarge),
                        Text('Day Streak',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Icon(Icons.warning, color: Colors.deepOrange),
                        const SizedBox(height: 4),
                        Text('${_report.disruptions.length}',
                            style: Theme.of(context).textTheme.titleLarge),
                        Text('Disruptions',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.amber),
                        const SizedBox(height: 4),
                        Text('${_report.adjustments.length}',
                            style: Theme.of(context).textTheme.titleLarge),
                        Text('Suggestions',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Today's Timeline
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Ritual Timeline",
                      style: Theme.of(context).textTheme.titleSmall),
                  const Divider(),
                  ..._buildTimeline(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeline() {
    final sorted = List<Ritual>.from(_report.rituals.where((r) => r.isActive))
      ..sort((a, b) => a.targetMinuteOfDay.compareTo(b.targetMinuteOfDay));

    return sorted.map((ritual) {
      final exec = _report.executions
          .where((e) => e.ritualId == ritual.id)
          .toList();

      Color dotColor;
      String status;
      if (exec.isNotEmpty) {
        final score = _service.computeTimingScore(ritual, exec.first);
        if (score >= 75) {
          dotColor = Colors.green;
          status = 'On time';
        } else if (score >= 50) {
          dotColor = Colors.amber;
          status = 'Late';
        } else {
          dotColor = Colors.red;
          status = 'Very late';
        }
      } else {
        final now = DateTime.now();
        final nowMin = now.hour * 60 + now.minute;
        if (ritual.targetMinuteOfDay > nowMin) {
          dotColor = Colors.grey.shade300;
          status = 'Upcoming';
        } else {
          dotColor = Colors.red;
          status = 'Missed';
        }
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(ritual.targetTimeStr,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(child: Text(ritual.name)),
            Text(status,
                style: TextStyle(
                    fontSize: 12, color: dotColor, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Rituals Tab
  // ---------------------------------------------------------------------------

  Widget _buildRitualsTab() {
    final sorted = List<Ritual>.from(_service.rituals.where((r) => r.isActive))
      ..sort((a, b) => a.targetMinuteOfDay.compareTo(b.targetMinuteOfDay));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) {
        final ritual = sorted[i];
        final state = _service.classifyRhythm(ritual.id);
        final history = _service.timingHistory(ritual.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ritual.category.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ritual.name,
                              style: Theme.of(ctx).textTheme.titleSmall),
                          Text('${ritual.targetTimeStr} • ${ritual.durationMinutes}min',
                              style: Theme.of(ctx).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Chip(
                      avatar: Text(state.emoji, style: const TextStyle(fontSize: 12)),
                      label: Text(state.label, style: const TextStyle(fontSize: 11)),
                      backgroundColor: _rhythmColor(state).withOpacity(0.15),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Timing history sparkline
                Row(
                  children: history.entries.map((entry) {
                    Color c;
                    if (entry.value < 0) {
                      c = Colors.red.shade100;
                    } else if (entry.value >= 80) {
                      c = Colors.green;
                    } else if (entry.value >= 55) {
                      c = Colors.amber;
                    } else {
                      c = Colors.red;
                    }
                    return Expanded(
                      child: Tooltip(
                        message: '${entry.key}: ${entry.value < 0 ? "Missed" : "${entry.value}%"}',
                        child: Container(
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
                Text('14-day timing history',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Disruptions Tab
  // ---------------------------------------------------------------------------

  Widget _buildDisruptionsTab() {
    final disruptions = _report.disruptions;
    if (disruptions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text('No disruptions detected!',
                style: TextStyle(fontSize: 16, color: Colors.green)),
            SizedBox(height: 4),
            Text('Your ritual chain is stable.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: disruptions.length,
      itemBuilder: (ctx, i) {
        final d = disruptions[i];
        final ritual = _service.rituals.firstWhere((r) => r.id == d.ritualId,
            orElse: () => _service.rituals.first);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _severityColor(d.severity).withOpacity(0.2),
              child: Text(d.type.emoji, style: const TextStyle(fontSize: 18)),
            ),
            title: Text(d.type.label),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Affects: ${ritual.name}',
                        style: const TextStyle(fontSize: 11)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _severityColor(d.severity).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Severity: ${d.severity}',
                          style: TextStyle(
                              fontSize: 11,
                              color: _severityColor(d.severity),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Adjustments Tab
  // ---------------------------------------------------------------------------

  Widget _buildAdjustmentsTab() {
    final adjustments = _report.adjustments;
    if (adjustments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.thumb_up, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text('No adjustments needed!',
                style: TextStyle(fontSize: 16, color: Colors.green)),
            SizedBox(height: 4),
            Text('Your rituals are well-optimized.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: adjustments.length,
      itemBuilder: (ctx, i) {
        final a = adjustments[i];
        final ritual = _service.rituals.firstWhere((r) => r.id == a.ritualId,
            orElse: () => _service.rituals.first);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(a.type.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a.type.label,
                          style: Theme.of(ctx).textTheme.titleSmall),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${a.confidence}% confidence',
                          style: const TextStyle(fontSize: 11, color: Colors.blue)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('For: ${ritual.name}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(a.reasoning),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward, size: 14, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a.suggestedChange,
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _service.applyAdjustment(a);
                      _refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Applied: ${a.type.label} for ${ritual.name}')),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Apply'),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
