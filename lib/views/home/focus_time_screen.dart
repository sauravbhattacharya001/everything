import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/focus_time_service.dart';
import '../../models/event_model.dart';
import '../../state/providers/event_provider.dart';

/// Focus Time screen — visualize deep-work availability, fragmentation,
/// recurring focus windows, and actionable suggestions.
///
/// 4 tabs: Today | Week | Windows | Insights
class FocusTimeScreen extends StatefulWidget {
  const FocusTimeScreen({super.key});

  @override
  State<FocusTimeScreen> createState() => _FocusTimeScreenState();
}

class _FocusTimeScreenState extends State<FocusTimeScreen>
    with SingleTickerProviderStateMixin {
  final FocusTimeService _service = const FocusTimeService();
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  int _analysisDays = 7;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<EventModel> get _events =>
      Provider.of<EventProvider>(context, listen: false).events;

  DayAnalysis get _todayAnalysis =>
      _service.analyzeDay(_selectedDate, _events);

  FocusTimeReport get _report => _service.analyzeRange(
        _events,
        from: DateTime.now().subtract(Duration(days: _analysisDays - 1)),
        to: DateTime.now(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Time'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.date_range), text: 'Week'),
            Tab(icon: Icon(Icons.window), text: 'Windows'),
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildWeekTab(),
          _buildWindowsTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  // ─── Today Tab ──────────────────────────────────────────────

  Widget _buildTodayTab() {
    final analysis = _todayAnalysis;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date selector
        _buildDateSelector(),
        const SizedBox(height: 16),

        // Score card
        _buildScoreCard(
          'Focus Score',
          _computeDayScore(analysis),
          _scoreColor(_computeDayScore(analysis)),
          Icons.center_focus_strong,
        ),
        const SizedBox(height: 12),

        // Stats row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Focus Time',
                '${analysis.focusMinutes} min',
                Icons.timer,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Meetings',
                '${analysis.meetingCount}',
                Icons.groups,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Switches',
                '${analysis.contextSwitches}',
                Icons.swap_horiz,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Fragmentation bar
        _buildFragmentationBar(analysis.fragmentationScore),
        const SizedBox(height: 16),

        // Timeline
        _buildDayTimeline(analysis),
        const SizedBox(height: 16),

        // Focus blocks list
        if (analysis.focusBlocks.isNotEmpty) ...[
          Text(
            'Available Focus Blocks',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...analysis.focusBlocks.map(_buildFocusBlockCard),
        ] else
          _buildEmptyState(
            Icons.event_busy,
            'No focus blocks available',
            'Your schedule is fully packed today.',
          ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() {
            _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          }),
        ),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Text(
            _formatDate(_selectedDate),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(() {
            _selectedDate = _selectedDate.add(const Duration(days: 1));
          }),
        ),
      ],
    );
  }

  // ─── Week Tab ───────────────────────────────────────────────

  Widget _buildWeekTab() {
    final report = _report;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period selector
        _buildPeriodSelector(),
        const SizedBox(height: 16),

        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg Focus',
                '${report.averageFocusMinutes.toStringAsFixed(0)} min',
                Icons.timer,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Avg Meetings',
                report.averageMeetings.toStringAsFixed(1),
                Icons.groups,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg Frag',
                '${report.averageFragmentation.toStringAsFixed(0)}/100',
                Icons.broken_image,
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Focus Score',
                '${report.focusScore.toStringAsFixed(0)}/100',
                Icons.center_focus_strong,
                _scoreColor(report.focusScore),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Daily bars
        Text(
          'Daily Focus Minutes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...report.days.map(_buildDayBar),

        if (report.days.isEmpty)
          _buildEmptyState(
            Icons.event_available,
            'No data for this period',
            'Add events to your calendar to see focus analysis.',
          ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 7, label: Text('7 days')),
        ButtonSegment(value: 14, label: Text('14 days')),
        ButtonSegment(value: 30, label: Text('30 days')),
      ],
      selected: {_analysisDays},
      onSelectionChanged: (val) => setState(() => _analysisDays = val.first),
    );
  }

  Widget _buildDayBar(DayAnalysis day) {
    final maxMins = 480.0; // 8 hours
    final focusRatio = (day.focusMinutes / maxMins).clamp(0.0, 1.0);
    final meetingRatio = (day.meetingMinutes / maxMins).clamp(0.0, 1.0);
    final dayName = _shortDayName(day.date);
    final dateStr = '${day.date.month}/${day.date.day}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                Text(dateStr,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                // Focus bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: focusRatio,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 2),
                // Meeting bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: meetingRatio,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.orange),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '${day.focusMinutes}m',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: day.focusMinutes >= 120 ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Windows Tab ────────────────────────────────────────────

  Widget _buildWindowsTab() {
    final report = _report;
    final windows = report.bestWindows;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPeriodSelector(),
        const SizedBox(height: 16),

        Text(
          'Best Recurring Focus Windows',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Time slots that are consistently free across your schedule.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 16),

        if (windows.isEmpty)
          _buildEmptyState(
            Icons.block,
            'No recurring windows found',
            'Your schedule varies too much to find consistent free slots.',
          )
        else
          ...windows.asMap().entries.map((e) =>
              _buildWindowCard(e.value, e.key + 1)),

        const SizedBox(height: 24),

        // Hour-by-hour heatmap
        Text(
          'Hourly Availability',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildHourlyHeatmap(report),
      ],
    );
  }

  Widget _buildWindowCard(FocusWindow window, int rank) {
    final startStr =
        '${window.startHour.toString().padLeft(2, '0')}:00';
    final endStr =
        '${window.endHour.toString().padLeft(2, '0')}:00';
    final pct = window.availabilityRate;
    final color = pct >= 80
        ? Colors.green
        : pct >= 60
            ? Colors.lightGreen
            : pct >= 40
                ? Colors.orange
                : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Text(
            '#$rank',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 14),
          ),
        ),
        title: Text(
          '$startStr – $endStr',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${window.hours}h window · Free ${window.freeDays}/${window.totalDays} days',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${pct.toStringAsFixed(0)}%',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyHeatmap(FocusTimeReport report) {
    if (report.days.isEmpty) {
      return const SizedBox.shrink();
    }

    // Count how many days each hour had a focus block covering it
    final hourFree = <int, int>{};
    for (var h = _service.workStartHour; h < _service.workEndHour; h++) {
      hourFree[h] = 0;
    }
    for (final day in report.days) {
      for (var h = _service.workStartHour; h < _service.workEndHour; h++) {
        final hourStart =
            DateTime(day.date.year, day.date.month, day.date.day, h);
        final hourEnd = hourStart.add(const Duration(hours: 1));
        final isFree = day.focusBlocks
            .any((b) => !b.start.isAfter(hourStart) && !b.end.isBefore(hourEnd));
        if (isFree) hourFree[h] = (hourFree[h] ?? 0) + 1;
      }
    }

    final totalDays = report.days.length;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(
        _service.workEndHour - _service.workStartHour,
        (i) {
          final hour = _service.workStartHour + i;
          final free = hourFree[hour] ?? 0;
          final ratio = totalDays > 0 ? free / totalDays : 0.0;
          final color = Color.lerp(Colors.red[100], Colors.green[400], ratio)!;
          return Tooltip(
            message:
                '${hour.toString().padLeft(2, '0')}:00 — free ${(ratio * 100).toStringAsFixed(0)}% of days',
            child: Container(
              width: 40,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${hour}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(ratio * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Insights Tab ───────────────────────────────────────────

  Widget _buildInsightsTab() {
    final report = _report;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPeriodSelector(),
        const SizedBox(height: 16),

        // Focus score gauge
        _buildScoreCard(
          'Overall Focus Score',
          report.focusScore,
          _scoreColor(report.focusScore),
          Icons.center_focus_strong,
        ),
        const SizedBox(height: 16),

        // Score breakdown
        Text(
          'Score Breakdown',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildBreakdownRow(
          'Low Fragmentation',
          ((100 - report.averageFragmentation) / 100).clamp(0, 1),
          Colors.blue,
        ),
        _buildBreakdownRow(
          'Focus Time',
          (report.averageFocusMinutes / 240).clamp(0, 1),
          Colors.green,
        ),
        _buildBreakdownRow(
          'Few Meetings',
          ((8 - report.averageMeetings) / 8).clamp(0, 1),
          Colors.orange,
        ),
        const SizedBox(height: 20),

        // Suggestions
        if (report.suggestions.isNotEmpty) ...[
          Text(
            'Suggestions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...report.suggestions.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.tips_and_updates,
                          color: Colors.amber[700], size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              )),
        ],

        if (report.suggestions.isEmpty && report.days.isNotEmpty)
          _buildEmptyState(
            Icons.check_circle_outline,
            'Looking great!',
            'No improvement suggestions — your schedule is focus-friendly.',
          ),

        if (report.days.isEmpty)
          _buildEmptyState(
            Icons.calendar_today,
            'No data yet',
            'Add events to your calendar to see focus insights.',
          ),
      ],
    );
  }

  // ─── Shared Widgets ─────────────────────────────────────────

  Widget _buildScoreCard(
      String label, double score, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              '${score.toStringAsFixed(0)}/100',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              _scoreLabel(score),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildFragmentationBar(double score) {
    final color = score >= 70
        ? Colors.red
        : score >= 40
            ? Colors.orange
            : Colors.green;
    final label = score >= 70
        ? 'Highly fragmented'
        : score >= 40
            ? 'Moderately fragmented'
            : 'Low fragmentation';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fragmentation',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${score.toStringAsFixed(0)}/100',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0, 1),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTimeline(DayAnalysis analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Day Timeline',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: CustomPaint(
                size: const Size(double.infinity, 40),
                painter: _TimelinePainter(
                  analysis: analysis,
                  workStartHour: _service.workStartHour,
                  workEndHour: _service.workEndHour,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_service.workStartHour}:00',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 10, height: 10, color: Colors.green[300]),
                    const SizedBox(width: 4),
                    Text('Focus',
                        style:
                            TextStyle(fontSize: 10, color: Colors.grey[600])),
                    const SizedBox(width: 12),
                    Container(
                        width: 10, height: 10, color: Colors.orange[300]),
                    const SizedBox(width: 4),
                    Text('Meeting',
                        style:
                            TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ],
                ),
                Text('${_service.workEndHour}:00',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusBlockCard(FocusBlock block) {
    final qualityColor = block.quality == 'excellent'
        ? Colors.green
        : block.quality == 'great'
            ? Colors.lightGreen
            : block.quality == 'good'
                ? Colors.blue
                : block.quality == 'fair'
                    ? Colors.orange
                    : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(Icons.check_circle, color: qualityColor),
        title: Text(
          '${_formatTime(block.start)} – ${_formatTime(block.end)}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('${block.minutes} minutes'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: qualityColor.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            block.quality,
            style: TextStyle(
              color: qualityColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double ratio, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${(ratio * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────

  double _computeDayScore(DayAnalysis day) {
    final fragComponent = ((100 - day.fragmentationScore) / 100) * 40;
    final focusComponent = (day.focusMinutes / 240).clamp(0.0, 1.0) * 40;
    final meetingComponent =
        ((8 - day.meetingCount) / 8).clamp(0.0, 1.0) * 20;
    return (fragComponent + focusComponent + meetingComponent).clamp(0, 100);
  }

  Color _scoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _scoreLabel(double score) {
    if (score >= 80) return 'Excellent focus environment';
    if (score >= 60) return 'Good — room for improvement';
    if (score >= 40) return 'Moderate — consider restructuring';
    return 'Low — too fragmented for deep work';
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _shortDayName(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }
}

// ─── Timeline Painter ─────────────────────────────────────────

class _TimelinePainter extends CustomPainter {
  final DayAnalysis analysis;
  final int workStartHour;
  final int workEndHour;

  _TimelinePainter({
    required this.analysis,
    required this.workStartHour,
    required this.workEndHour,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalMinutes = (workEndHour - workStartHour) * 60;
    if (totalMinutes <= 0) return;

    final dayStart = DateTime(
        analysis.date.year, analysis.date.month, analysis.date.day,
        workStartHour);

    // Background
    final bgPaint = Paint()..color = Colors.grey[200]!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(6)),
      bgPaint,
    );

    // Focus blocks (green)
    final focusPaint = Paint()..color = Colors.green[300]!;
    for (final block in analysis.focusBlocks) {
      final startMin = block.start.difference(dayStart).inMinutes;
      final endMin = block.end.difference(dayStart).inMinutes;
      final x1 = (startMin / totalMinutes) * size.width;
      final x2 = (endMin / totalMinutes) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x1, 2, x2 - x1, size.height - 4),
            const Radius.circular(3)),
        focusPaint,
      );
    }

    // We don't have direct meeting slots from DayAnalysis, but we can
    // infer them as non-focus gaps within working hours. Paint the
    // entire bar as orange, then overwrite with focus blocks for contrast.
    // Actually, let's just paint meetings as the gaps between focus blocks.
    final meetPaint = Paint()..color = Colors.orange[300]!;
    var cursor = 0.0;
    final sortedBlocks = List.of(analysis.focusBlocks)
      ..sort((a, b) => a.start.compareTo(b.start));
    for (final block in sortedBlocks) {
      final blockStart =
          (block.start.difference(dayStart).inMinutes / totalMinutes) *
              size.width;
      if (blockStart > cursor + 1) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(cursor, 2, blockStart - cursor, size.height - 4),
              const Radius.circular(3)),
          meetPaint,
        );
      }
      cursor = (block.end.difference(dayStart).inMinutes / totalMinutes) *
          size.width;
    }
    if (cursor < size.width - 1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cursor, 2, size.width - cursor, size.height - 4),
            const Radius.circular(3)),
        meetPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
