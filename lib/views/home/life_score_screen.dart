import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/services/life_score_service.dart';

/// Life Score Dashboard — self-assessment across 8 life dimensions
/// with radar chart, trend tracking, and proactive focus recommendations.
class LifeScoreScreen extends StatefulWidget {
  const LifeScoreScreen({super.key});

  @override
  State<LifeScoreScreen> createState() => _LifeScoreScreenState();
}

class _LifeScoreScreenState extends State<LifeScoreScreen> {
  final _service = LifeScoreService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.load().then((_) => setState(() => _loading = false));
  }

  void _openNewAssessment() async {
    final entry = await showDialog<LifeScoreEntry>(
      context: context,
      builder: (_) => const _AssessmentDialog(),
    );
    if (entry != null) {
      await _service.addEntry(entry);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Life Score')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final entries = _service.entries;
    final latest = entries.isNotEmpty ? entries.last : null;
    final recs = _service.getRecommendations();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Score Dashboard'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'History',
              onPressed: () => _showHistory(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewAssessment,
        icon: const Icon(Icons.add),
        label: const Text('New Assessment'),
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.radar, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Rate yourself across 8 life dimensions',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to start your first assessment',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // Overall score card
                _OverallCard(entry: latest!),
                const SizedBox(height: 16),

                // Radar chart
                SizedBox(
                  height: 300,
                  child: _RadarChart(entry: latest),
                ),
                const SizedBox(height: 16),

                // Dimension breakdown
                _DimensionBreakdown(
                  entry: latest,
                  service: _service,
                ),
                const SizedBox(height: 16),

                // Focus recommendations
                if (recs.isNotEmpty) ...[
                  const Text(
                    '🎯 Focus Recommendations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...recs.map((r) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text('${r.priority}'),
                          ),
                          title: Text(
                              '${r.dimension.emoji} ${r.dimension.label}'),
                          subtitle: Text(r.reason),
                        ),
                      )),
                ],
              ],
            ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final entries = _service.entries.reversed.toList();
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Assessment History',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    final date =
                        '${e.date.month}/${e.date.day}/${e.date.year}';
                    return Dismissible(
                      key: ValueKey(e.date.toIso8601String()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child:
                            const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        final idx = _service.entries.indexOf(e);
                        _service.deleteEntry(idx);
                        setState(() {});
                      },
                      child: ListTile(
                        title: Text('$date — Score: ${e.overall.toStringAsFixed(1)}'),
                        subtitle: Text(
                          e.notes ?? 'No notes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _BalanceChip(imbalance: e.imbalance),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Shows overall score and balance indicator.
class _OverallCard extends StatelessWidget {
  final LifeScoreEntry entry;
  const _OverallCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final score = entry.overall;
    final color = score >= 7
        ? Colors.green
        : score >= 5
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Score circle
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: score / 10,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                  Center(
                    child: Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall Life Score',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  _BalanceChip(imbalance: entry.imbalance),
                  if (entry.strengths.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '💪 ${entry.strengths.map((d) => d.emoji).join(' ')}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  if (entry.weakSpots.isNotEmpty)
                    Text(
                      '⚠️ ${entry.weakSpots.map((d) => d.emoji).join(' ')}',
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  final double imbalance;
  const _BalanceChip({required this.imbalance});

  @override
  Widget build(BuildContext context) {
    final label = imbalance < 1.5
        ? 'Well Balanced'
        : imbalance < 2.5
            ? 'Slightly Uneven'
            : 'Needs Balance';
    final color = imbalance < 1.5
        ? Colors.green
        : imbalance < 2.5
            ? Colors.orange
            : Colors.red;
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Custom-painted radar chart for the 8 dimensions.
class _RadarChart extends StatelessWidget {
  final LifeScoreEntry entry;
  const _RadarChart({required this.entry});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarPainter(entry: entry),
      size: const Size(300, 300),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final LifeScoreEntry entry;
  _RadarPainter({required this.entry});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 30;
    final dims = LifeDimension.values;
    final n = dims.length;
    final angleStep = 2 * pi / n;

    // Draw grid rings
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int ring = 2; ring <= 10; ring += 2) {
      final r = radius * ring / 10;
      final path = Path();
      for (int i = 0; i <= n; i++) {
        final angle = -pi / 2 + angleStep * (i % n);
        final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // Draw axes
    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + angleStep * i;
      final end = Offset(
          center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      canvas.drawLine(center, end, gridPaint);

      // Labels
      final labelOffset = Offset(
          center.dx + (radius + 18) * cos(angle),
          center.dy + (radius + 18) * sin(angle));
      final tp = TextPainter(
        text: TextSpan(
          text: dims[i].emoji,
          style: const TextStyle(fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(labelOffset.dx - tp.width / 2, labelOffset.dy - tp.height / 2));
    }

    // Draw data polygon
    final dataPath = Path();
    final fillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i <= n; i++) {
      final dim = dims[i % n];
      final score = (entry.scores[dim] ?? 5).toDouble();
      final r = radius * score / 10;
      final angle = -pi / 2 + angleStep * (i % n);
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }

    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Draw data points
    final dotPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    for (int i = 0; i < n; i++) {
      final dim = dims[i];
      final score = (entry.scores[dim] ?? 5).toDouble();
      final r = radius * score / 10;
      final angle = -pi / 2 + angleStep * i;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      canvas.drawCircle(p, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.entry != entry;
}

/// Shows each dimension with score bar and trend arrow.
class _DimensionBreakdown extends StatelessWidget {
  final LifeScoreEntry entry;
  final LifeScoreService service;
  const _DimensionBreakdown({required this.entry, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dimension Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...LifeDimension.values.map((dim) {
          final score = entry.scores[dim] ?? 5;
          final t = service.trend(dim);
          final trendIcon = t > 0.2
              ? '📈'
              : t < -0.2
                  ? '📉'
                  : '➡️';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 32, child: Text(dim.emoji)),
                Expanded(
                  flex: 3,
                  child: Text(dim.label, style: const TextStyle(fontSize: 13)),
                ),
                SizedBox(
                  width: 24,
                  child: Text('$score',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score / 10,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        score >= 7
                            ? Colors.green
                            : score >= 4
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(trendIcon),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Dialog for creating a new life score assessment.
class _AssessmentDialog extends StatefulWidget {
  const _AssessmentDialog();

  @override
  State<_AssessmentDialog> createState() => _AssessmentDialogState();
}

class _AssessmentDialogState extends State<_AssessmentDialog> {
  final Map<LifeDimension, int> _scores = {
    for (final d in LifeDimension.values) d: 5,
  };
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avg =
        _scores.values.fold(0, (a, b) => a + b) / _scores.length;

    return AlertDialog(
      title: const Text('New Assessment'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Overall: ${avg.toStringAsFixed(1)} / 10',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ...LifeDimension.values.map((dim) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('${dim.emoji} ', style: const TextStyle(fontSize: 18)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dim.label,
                                style: const TextStyle(fontSize: 12)),
                            Slider(
                              value: _scores[dim]!.toDouble(),
                              min: 0,
                              max: 10,
                              divisions: 10,
                              label: '${_scores[dim]}',
                              onChanged: (v) =>
                                  setState(() => _scores[dim] = v.round()),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        child: Text('${_scores[dim]}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              LifeScoreEntry(
                date: DateTime.now(),
                scores: Map.from(_scores),
                notes: _notesController.text.isEmpty
                    ? null
                    : _notesController.text,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
