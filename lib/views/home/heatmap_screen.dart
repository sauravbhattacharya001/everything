import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/heatmap_service.dart';
import '../../core/utils/formatting_utils.dart';
import '../../models/event_model.dart';
import '../../state/providers/event_provider.dart';

/// A GitHub-style contribution heatmap showing event density per day.
///
/// Displays a full year at a glance with color-coded cells:
/// - Empty (no events) → grey
/// - Light (1–2 events) → light green
/// - Medium (3–4 events) → green
/// - Busy (5–7 events) → dark green
/// - Very busy (8+ events) → darkest green
///
/// Tapping a cell shows the events for that day. Includes summary
/// statistics and year navigation.
class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({Key? key}) : super(key: key);

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  final HeatmapService _service = HeatmapService();
  late int _selectedYear;
  HeatmapCell? _selectedCell;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final events = Provider.of<EventProvider>(context).events.toList();
    final data = _service.generate(events, year: _selectedYear);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Activity Heatmap'),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildYearSelector(),
            const SizedBox(height: 16),
            _buildStatsCards(data.stats),
            const SizedBox(height: 16),
            _buildHeatmapGrid(data),
            const SizedBox(height: 12),
            _buildLegend(data.thresholds),
            if (_selectedCell != null && _selectedCell!.hasEvents) ...[
              const SizedBox(height: 16),
              _buildDayDetail(_selectedCell!),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Year navigation with back/forward arrows.
  Widget _buildYearSelector() {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() {
            _selectedYear--;
            _selectedCell = null;
          }),
        ),
        Text(
          '$_selectedYear',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _selectedYear < now.year + 1
              ? () => setState(() {
                    _selectedYear++;
                    _selectedCell = null;
                  })
              : null,
        ),
      ],
    );
  }

  /// Summary statistics cards.
  Widget _buildStatsCards(HeatmapStats stats) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _statCard(
          'Total Events',
          '${stats.totalEvents}',
          Icons.event,
          Colors.indigo,
        ),
        _statCard(
          'Active Days',
          '${stats.activeDays}',
          Icons.calendar_today,
          Colors.green,
        ),
        _statCard(
          'Activity Rate',
          '${stats.activityRate.toStringAsFixed(0)}%',
          Icons.trending_up,
          Colors.orange,
        ),
        _statCard(
          'Longest Streak',
          '${stats.longestStreak}d',
          Icons.local_fire_department,
          Colors.deepOrange,
        ),
        if (stats.currentStreak > 0)
          _statCard(
            'Current Streak',
            '${stats.currentStreak}d',
            Icons.bolt,
            Colors.amber[700]!,
          ),
        _statCard(
          'Avg/Active Day',
          stats.avgEventsPerActiveDay.toStringAsFixed(1),
          Icons.speed,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// The main heatmap grid — horizontally scrollable.
  Widget _buildHeatmapGrid(HeatmapData data) {
    const cellSize = 14.0;
    const cellGap = 3.0;
    const dayLabelWidth = 28.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month labels row
          Padding(
            padding: const EdgeInsets.only(left: dayLabelWidth),
            child: SizedBox(
              height: 16,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildMonthLabels(data, cellSize + cellGap),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Grid with day labels
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day-of-week labels (Mon, Wed, Fri)
                Column(
                  children: List.generate(7, (i) {
                    final labels = ['', 'Mon', '', 'Wed', '', 'Fri', ''];
                    return SizedBox(
                      width: dayLabelWidth,
                      height: cellSize + cellGap,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                // Heatmap cells
                ...data.weeks.map((week) => Column(
                      children: week.cells.map((cell) {
                        return GestureDetector(
                          onTap: cell != null
                              ? () => setState(() => _selectedCell = cell)
                              : null,
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            margin: const EdgeInsets.all(cellGap / 2),
                            decoration: BoxDecoration(
                              color: _cellColor(cell),
                              borderRadius: BorderRadius.circular(2),
                              border: cell != null && cell.isToday
                                  ? Border.all(
                                      color: Colors.indigo,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds positioned month labels above the grid.
  List<Widget> _buildMonthLabels(HeatmapData data, double colWidth) {
    if (data.monthLabels.isEmpty) return [];

    final widgets = <Widget>[];
    int lastWeekIdx = 0;

    for (final entry in data.monthLabels) {
      final gap = entry.value - lastWeekIdx;
      if (gap > 0) {
        widgets.add(SizedBox(width: gap * colWidth));
      }
      widgets.add(Text(
        entry.key,
        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
      ));
      lastWeekIdx = entry.value + 1;
    }
    return widgets;
  }

  /// Maps a cell's intensity to a color.
  Color _cellColor(HeatmapCell? cell) {
    if (cell == null) return Colors.transparent;
    // Highlight cells with urgent events
    if (cell.hasUrgent && cell.intensity >= 2) {
      switch (cell.intensity) {
        case 2:
          return Colors.orange[300]!;
        case 3:
          return Colors.deepOrange[400]!;
        case 4:
          return Colors.red[600]!;
        default:
          return Colors.orange[200]!;
      }
    }
    switch (cell.intensity) {
      case 0:
        return Colors.grey[200]!;
      case 1:
        return Colors.green[200]!;
      case 2:
        return Colors.green[400]!;
      case 3:
        return Colors.green[600]!;
      case 4:
        return Colors.green[800]!;
      default:
        return Colors.grey[200]!;
    }
  }

  /// Color legend showing intensity levels.
  Widget _buildLegend(List<int> thresholds) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Less', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(width: 4),
        _legendCell(Colors.grey[200]!),
        _legendCell(Colors.green[200]!),
        _legendCell(Colors.green[400]!),
        _legendCell(Colors.green[600]!),
        _legendCell(Colors.green[800]!),
        const SizedBox(width: 4),
        Text('More', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(width: 16),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.orange[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Has urgent',
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _legendCell(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Detail panel showing events for the selected day.
  Widget _buildDayDetail(HeatmapCell cell) {
    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final dateStr =
        '${dayNames[cell.date.weekday - 1]}, ${monthNames[cell.date.month - 1]} ${cell.date.day}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cell.eventCount} event${cell.eventCount == 1 ? "" : "s"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.indigo[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...cell.events.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 32,
                      decoration: BoxDecoration(
                        color: event.priority.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _formatTime(event),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      event.priority.icon,
                      size: 16,
                      color: event.priority.color,
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// Formats the time portion of an event for display.
  String _formatTime(EventModel event) {
    if (event.endDate != null) {
      return FormattingUtils.formatTimeRange12h(event.date, event.endDate!);
    }
    return FormattingUtils.formatTime12h(event.date);
  }
}
