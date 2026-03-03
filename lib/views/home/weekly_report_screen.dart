import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/weekly_report_service.dart';
import '../../models/event_model.dart';
import '../../state/providers/event_provider.dart';

/// A visual weekly report screen showing productivity stats, charts,
/// and week-over-week comparisons using the WeeklyReportService.
class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final WeeklyReportService _reportService = WeeklyReportService();
  late DateTime _selectedWeek;

  @override
  void initState() {
    super.initState();
    _selectedWeek = DateTime.now();
  }

  void _previousWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.add(const Duration(days: 7));
    });
  }

  void _goToCurrentWeek() {
    setState(() {
      _selectedWeek = DateTime.now();
    });
  }

  String _formatDate(DateTime d) =>
      '${_monthName(d.month)} ${d.day}';

  String _monthName(int month) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month];
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final allEvents = eventProvider.events.toList();
    final report = _reportService.generateReport(
      allEvents,
      referenceDate: _selectedWeek,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Report'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToCurrentWeek,
            tooltip: 'Current week',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week navigator
            _buildWeekNavigator(report),
            const SizedBox(height: 20),

            // Summary cards row
            _buildSummaryCards(report),
            const SizedBox(height: 20),

            // Daily distribution bar chart
            _buildDailyChart(report),
            const SizedBox(height: 20),

            // Priority breakdown
            _buildPriorityBreakdown(report),
            const SizedBox(height: 20),

            // Top tags
            if (report.topTags.isNotEmpty) ...[
              _buildTopTags(report),
              const SizedBox(height: 20),
            ],

            // Checklist completion
            if (report.checklistCompletionRate != null)
              _buildChecklistCard(report),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekNavigator(WeeklyReport report) {
    return Card(
      elevation: 0,
      color: Colors.blue.withAlpha(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousWeek,
            ),
            Column(
              children: [
                Text(
                  '${_formatDate(report.weekStart)} – ${_formatDate(report.weekEnd)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${report.weekStart.year}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextWeek,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(WeeklyReport report) {
    final change = report.weekOverWeekChange;
    final pct = report.weekOverWeekPercent;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.event,
            label: 'Events',
            value: '${report.totalEvents}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.star,
            label: 'Busiest Day',
            value: report.busiestDay,
            subtitle: '${report.busiestDayCount} events',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: change != null && change >= 0
                ? Icons.trending_up
                : Icons.trending_down,
            label: 'vs Last Week',
            value: change != null
                ? '${change >= 0 ? '+' : ''}$change'
                : 'N/A',
            subtitle: pct != null ? '${pct.toStringAsFixed(0)}%' : null,
            color: change != null && change >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChart(WeeklyReport report) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxCount = report.dailyBreakdown.values.fold<int>(
      1,
      (max, v) => v > max ? v : max,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final dow = i + 1; // 1=Mon
                  final count = report.dailyBreakdown[dow] ?? 0;
                  final fraction = count / maxCount;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            height: count == 0 ? 4 : (fraction * 100),
                            decoration: BoxDecoration(
                              color: count == 0
                                  ? Colors.grey[200]
                                  : Colors.blue.withAlpha(
                                      (100 + fraction * 155).toInt()),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dayLabels[i],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBreakdown(WeeklyReport report) {
    if (report.priorityBreakdown.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No events this week',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Priority Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...EventPriority.values.map((p) {
              final count = report.priorityBreakdown[p] ?? 0;
              final fraction = report.totalEvents > 0
                  ? count / report.totalEvents
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: p.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          backgroundColor: Colors.grey[100],
                          color: p.color,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTags(WeeklyReport report) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: report.topTags.map((entry) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  label: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 13),
                  ),
                  backgroundColor: Colors.blue.withAlpha(15),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard(WeeklyReport report) {
    final pct = (report.checklistCompletionRate! * 100).toInt();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: report.checklistCompletionRate!,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[200],
                    color: pct >= 75
                        ? Colors.green
                        : pct >= 50
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Checklist Completion',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pct >= 75
                      ? 'Great job staying on track! 🎉'
                      : pct >= 50
                          ? 'Making progress, keep going! 💪'
                          : 'Room for improvement 📋',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact summary stat card.
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
