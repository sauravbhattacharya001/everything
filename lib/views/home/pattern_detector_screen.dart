import 'package:flutter/material.dart';
import '../../core/services/pattern_detector_service.dart';

/// Smart Pattern Detector — autonomous cross-tracker correlation discovery.
///
/// Analyses demo data across 12 health/productivity trackers, computes
/// Pearson correlations (same-day and lagged), and surfaces surprising
/// patterns with a heatmap matrix, predictability gauges, and insight feed.
///
/// 4 tabs: Discoveries · Matrix · Predictions · Lagged
class PatternDetectorScreen extends StatefulWidget {
  const PatternDetectorScreen({super.key});

  @override
  State<PatternDetectorScreen> createState() => _PatternDetectorScreenState();
}

class _PatternDetectorScreenState extends State<PatternDetectorScreen>
    with SingleTickerProviderStateMixin {
  final PatternDetectorService _service = PatternDetectorService();
  late TabController _tabController;

  late Map<String, List<double>> _data;
  late List<DiscoveredPattern> _patterns;
  late List<DiscoveredPattern> _laggedPatterns;
  late Map<String, Map<String, double>> _matrix;
  late List<PredictabilityInfo> _predictions;

  double _minStrength = 0.4;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scan();
  }

  void _scan() {
    _data = _service.generateDemoData().first;
    _patterns = _service.discoverPatterns(_data);
    _laggedPatterns = _service.discoverLaggedPatterns(_data);
    _matrix = _service.correlationMatrix(_data);
    _predictions = _service.predictability(_data);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Summary banner ──────────────────────────────────────────

  Widget _buildBanner() {
    final total = _patterns.length + _laggedPatterns.length;
    final strongest = _patterns.isNotEmpty ? _patterns.first : null;
    final mostPredictable = _predictions.isNotEmpty ? _predictions.first : null;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hub, size: 28),
                const SizedBox(width: 8),
                Text('Pattern Scan Results',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Re-scan',
                  onPressed: () => setState(_scan),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$total patterns discovered across ${PatternDetectorService.trackers.length} trackers'),
            if (strongest != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Strongest: ${strongest.trackerA} ↔ ${strongest.trackerB} '
                    '(r=${strongest.r.toStringAsFixed(2)})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            if (mostPredictable != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Most predictable: ${mostPredictable.tracker} '
                    '(score ${(mostPredictable.score * 100).round()}%)'),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Discoveries tab ─────────────────────────────────────────

  Widget _buildDiscoveries() {
    final filtered = _patterns.where((p) => p.r.abs() >= _minStrength).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Min strength:'),
              Expanded(
                child: Slider(
                  value: _minStrength,
                  min: 0.3,
                  max: 0.9,
                  divisions: 6,
                  label: _minStrength.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _minStrength = v),
                ),
              ),
              Text(_minStrength.toStringAsFixed(1)),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No patterns at this threshold'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _patternCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _patternCard(DiscoveredPattern p) {
    final color = p.r > 0 ? Colors.green : Colors.red;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text(p.r.abs() >= 0.6 ? '🔗' : '🔄', style: const TextStyle(fontSize: 18)),
        ),
        title: Text('${p.trackerA}  ↔  ${p.trackerB}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(p.insight, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: p.r.abs(),
              backgroundColor: Colors.grey[200],
              color: color,
            ),
          ],
        ),
        trailing: Text(p.r.toStringAsFixed(2),
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  // ─── Matrix tab ──────────────────────────────────────────────

  Widget _buildMatrix() {
    final keys = _matrix.keys.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const SizedBox(width: 90),
                ...keys.map((k) => SizedBox(
                      width: 56,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Text(k,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    )),
              ],
            ),
            // Data rows
            ...keys.map((rowKey) => Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(rowKey,
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis),
                    ),
                    ...keys.map((colKey) {
                      final r = _matrix[rowKey]![colKey]!;
                      return Container(
                        width: 56,
                        height: 40,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: _heatmapColor(r),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          rowKey == colKey ? '—' : r.toStringAsFixed(2),
                          style: TextStyle(
                              fontSize: 10,
                              color: r.abs() > 0.5 ? Colors.white : Colors.black87),
                        ),
                      );
                    }),
                  ],
                )),
            const SizedBox(height: 16),
            Row(
              children: [
                _legendBox(Colors.green[700]!, '-1.0'),
                const SizedBox(width: 2),
                _legendBox(Colors.green[300]!, '-0.5'),
                const SizedBox(width: 2),
                _legendBox(Colors.grey[200]!, '0'),
                const SizedBox(width: 2),
                _legendBox(Colors.red[300]!, '+0.5'),
                const SizedBox(width: 2),
                _legendBox(Colors.red[700]!, '+1.0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _heatmapColor(double r) {
    if (r > 0) return Color.lerp(Colors.grey[100]!, Colors.green[700]!, r.abs())!;
    if (r < 0) return Color.lerp(Colors.grey[100]!, Colors.red[700]!, r.abs())!;
    return Colors.grey[100]!;
  }

  Widget _legendBox(Color c, String label) {
    return Column(
      children: [
        Container(width: 28, height: 16, color: c),
        Text(label, style: const TextStyle(fontSize: 9)),
      ],
    );
  }

  // ─── Predictions tab ─────────────────────────────────────────

  Widget _buildPredictions() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _predictions.length,
      itemBuilder: (_, i) {
        final p = _predictions[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.tracker,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    Text('${(p.score * 100).round()}%',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: p.score > 0.5 ? Colors.green : Colors.orange)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: p.score,
                  backgroundColor: Colors.grey[200],
                  color: p.score > 0.5 ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 8),
                Text('Top predictors:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ...p.topPredictors.map((t) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text('• $t', style: const TextStyle(fontSize: 12)),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Lagged tab ──────────────────────────────────────────────

  Widget _buildLagged() {
    if (_laggedPatterns.isEmpty) {
      return const Center(child: Text('No significant lagged correlations found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _laggedPatterns.length,
      itemBuilder: (_, i) {
        final p = _laggedPatterns[i];
        final color = p.r > 0 ? Colors.green : Colors.red;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Yesterday', style: TextStyle(fontSize: 9)),
                const Icon(Icons.arrow_downward, size: 16),
                const Text('Today', style: TextStyle(fontSize: 9)),
              ],
            ),
            title: Text('${p.trackerA}  →  ${p.trackerB}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(p.insight, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: p.r.abs(),
                  backgroundColor: Colors.grey[200],
                  color: color,
                ),
              ],
            ),
            trailing: Text(p.r.toStringAsFixed(2),
                style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
        );
      },
    );
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pattern Detector'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Discoveries'),
            Tab(icon: Icon(Icons.grid_on), text: 'Matrix'),
            Tab(icon: Icon(Icons.speed), text: 'Predictions'),
            Tab(icon: Icon(Icons.timeline), text: 'Lagged'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoveries(),
                _buildMatrix(),
                _buildPredictions(),
                _buildLagged(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
