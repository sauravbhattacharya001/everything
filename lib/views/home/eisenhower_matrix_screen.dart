import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/eisenhower_matrix_service.dart';
import '../../models/event_model.dart';
import '../../state/providers/event_provider.dart';
import 'event_detail_screen.dart';

/// Eisenhower Matrix screen — visual 2×2 priority grid that classifies
/// events into four quadrants (Do First, Schedule, Delegate, Eliminate)
/// based on urgency and importance scoring.
class EisenhowerMatrixScreen extends StatefulWidget {
  const EisenhowerMatrixScreen({super.key});

  @override
  State<EisenhowerMatrixScreen> createState() => _EisenhowerMatrixScreenState();
}

class _EisenhowerMatrixScreenState extends State<EisenhowerMatrixScreen> {
  final EisenhowerMatrixService _service = EisenhowerMatrixService();
  bool _showRecommendations = false;
  Quadrant? _expandedQuadrant;

  static const _quadrantColors = {
    Quadrant.doFirst: Color(0xFFEF5350),   // Red
    Quadrant.schedule: Color(0xFF42A5F5),  // Blue
    Quadrant.delegate: Color(0xFFFFCA28),  // Amber
    Quadrant.eliminate: Color(0xFFBDBDBD), // Grey
  };

  static const _quadrantIcons = {
    Quadrant.doFirst: Icons.local_fire_department,
    Quadrant.schedule: Icons.calendar_today,
    Quadrant.delegate: Icons.people_outline,
    Quadrant.eliminate: Icons.delete_outline,
  };

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventProvider>().events;
    final now = DateTime.now();
    // Only include future/current events (not completed)
    final activeEvents = events.where((e) {
      final deadline = e.endDate ?? e.date;
      return deadline.isAfter(now.subtract(const Duration(days: 1)));
    }).toList();

    final summary = _service.buildMatrix(activeEvents, now: now);
    final recommendations = _service.getRecommendations(summary);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eisenhower Matrix'),
        actions: [
          IconButton(
            icon: Icon(_showRecommendations
                ? Icons.lightbulb
                : Icons.lightbulb_outline),
            onPressed: () =>
                setState(() => _showRecommendations = !_showRecommendations),
            tooltip: 'Recommendations',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          _buildSummaryBar(summary),
          // Recommendations panel
          if (_showRecommendations) _buildRecommendations(recommendations),
          // Matrix grid
          Expanded(
            child: activeEvents.isEmpty
                ? _buildEmptyState()
                : _expandedQuadrant != null
                    ? _buildExpandedQuadrant(summary)
                    : _buildMatrixGrid(summary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(MatrixSummary summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          _buildMetricChip(
            'Total',
            '${summary.total}',
            Icons.assignment,
          ),
          const SizedBox(width: 12),
          _buildMetricChip(
            'Balance',
            '${summary.balanceScore.toStringAsFixed(0)}%',
            Icons.balance,
          ),
          const Spacer(),
          // Mini quadrant distribution
          ...Quadrant.values.map((q) {
            final count = summary.counts[q] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Chip(
                avatar: CircleAvatar(
                  backgroundColor: _quadrantColors[q],
                  radius: 8,
                  child: Text(
                    '$count',
                    style: const TextStyle(fontSize: 9, color: Colors.white),
                  ),
                ),
                label: Text(
                  q.label.split(' ').first,
                  style: const TextStyle(fontSize: 11),
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendations(List<String> recommendations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insights',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 4),
          ...recommendations.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(r, style: const TextStyle(fontSize: 13)),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.grid_view_rounded,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('No upcoming events to prioritize',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Add events from the home screen to see them here',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildMatrixGrid(MatrixSummary summary) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Axis label: URGENT →
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const Spacer(),
                Text('URGENT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 2,
                    )),
                const Icon(Icons.arrow_forward, size: 14),
                const Spacer(),
                Text('NOT URGENT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 2,
                    )),
                const Spacer(),
              ],
            ),
          ),
          // Top row: Q1 (Do First) | Q2 (Schedule)
          Expanded(
            child: Row(
              children: [
                // IMPORTANT label (vertical)
                RotatedBox(
                  quarterTurns: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('IMPORTANT ↑',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          letterSpacing: 2,
                        )),
                  ),
                ),
                Expanded(
                    child: _buildQuadrantCard(
                        Quadrant.doFirst, summary.entries[Quadrant.doFirst]!)),
                const SizedBox(width: 4),
                Expanded(
                    child: _buildQuadrantCard(
                        Quadrant.schedule, summary.entries[Quadrant.schedule]!)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Bottom row: Q3 (Delegate) | Q4 (Eliminate)
          Expanded(
            child: Row(
              children: [
                // Spacer for alignment with vertical label
                const SizedBox(width: 20),
                Expanded(
                    child: _buildQuadrantCard(
                        Quadrant.delegate, summary.entries[Quadrant.delegate]!)),
                const SizedBox(width: 4),
                Expanded(
                    child: _buildQuadrantCard(Quadrant.eliminate,
                        summary.entries[Quadrant.eliminate]!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuadrantCard(Quadrant quadrant, List<MatrixEntry> entries) {
    final color = _quadrantColors[quadrant]!;
    final icon = _quadrantIcons[quadrant]!;

    return GestureDetector(
      onTap: entries.isNotEmpty
          ? () => setState(() => _expandedQuadrant = quadrant)
          : null,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.08),
                color.withOpacity(0.02),
              ],
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${quadrant.emoji} ${quadrant.label}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color.withOpacity(0.9),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${entries.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                quadrant.description,
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Event list (compact)
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          'No items',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: entries.length,
                        itemBuilder: (ctx, i) =>
                            _buildCompactEventTile(entries[i], color),
                      ),
              ),
              if (entries.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Tap to expand',
                    style: TextStyle(
                      fontSize: 9,
                      color: color.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactEventTile(MatrixEntry entry, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _viewEvent(entry.event),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              // Priority dot
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _priorityColor(entry.event.priority),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.event.title,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Urgency indicator
              Text(
                entry.urgencyReason,
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedQuadrant(MatrixSummary summary) {
    final quadrant = _expandedQuadrant!;
    final entries = summary.entries[quadrant] ?? [];
    final color = _quadrantColors[quadrant]!;

    return Column(
      children: [
        // Back bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _expandedQuadrant = null),
                tooltip: 'Back to matrix',
              ),
              Icon(_quadrantIcons[quadrant]!, color: color),
              const SizedBox(width: 8),
              Text(
                '${quadrant.emoji} ${quadrant.label} (${entries.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
        // Detailed list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: entries.length,
            itemBuilder: (ctx, i) =>
                _buildDetailedEventCard(entries[i], color),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedEventCard(MatrixEntry entry, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _viewEvent(entry.event),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _priorityColor(entry.event.priority),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Score bars
              _buildScoreBar('Urgency', entry.urgencyScore, Colors.red),
              const SizedBox(height: 4),
              _buildScoreBar('Importance', entry.importanceScore, Colors.blue),
              const SizedBox(height: 6),
              // Reasons
              Row(
                children: [
                  Icon(Icons.schedule, size: 12, color: Colors.red.shade300),
                  const SizedBox(width: 4),
                  Text(entry.urgencyReason,
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                  const SizedBox(width: 12),
                  Icon(Icons.star, size: 12, color: Colors.blue.shade300),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(entry.importanceReason,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, double score, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 11)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color.withOpacity(0.7)),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${(score * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _priorityColor(EventPriority priority) {
    switch (priority) {
      case EventPriority.urgent:
        return Colors.red;
      case EventPriority.high:
        return Colors.orange;
      case EventPriority.medium:
        return Colors.blue;
      case EventPriority.low:
        return Colors.grey;
    }
  }

  void _viewEvent(EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: event),
      ),
    );
  }
}
