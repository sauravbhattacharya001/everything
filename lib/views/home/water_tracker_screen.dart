import 'package:flutter/material.dart';
import 'dart:math' show pi;
import '../../core/services/water_tracker_service.dart';
import '../../models/water_entry.dart';

/// Water Tracker screen — log daily hydration, view history, and track
/// weekly trends, streaks, and pacing.
class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen>
    with SingleTickerProviderStateMixin {
  final WaterTrackerService _service = const WaterTrackerService();
  late TabController _tabController;
  final List<WaterEntry> _entries = [];
  DrinkType _selectedDrink = DrinkType.water;
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addEntry(int ml, ContainerSize size) {
    setState(() {
      _entries.add(WaterEntry(
        id: 'w${_nextId++}',
        timestamp: DateTime.now(),
        amountMl: ml,
        drinkType: _selectedDrink,
        containerSize: size,
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedDrink.emoji} +${ml}ml logged'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeEntry(int index) {
    final entry = _entries[index];
    setState(() => _entries.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${entry.amountMl}ml ${entry.drinkType.label}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _entries.insert(index, entry));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.water_drop), text: 'Log'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LogTab(
            service: _service,
            entries: _entries,
            selectedDrink: _selectedDrink,
            onDrinkChanged: (d) => setState(() => _selectedDrink = d),
            onAdd: _addEntry,
          ),
          _HistoryTab(entries: _entries, onRemove: _removeEntry),
          _InsightsTab(service: _service, entries: _entries),
        ],
      ),
    );
  }
}

// ── Log Tab ─────────────────────────────────────────────────────────

class _LogTab extends StatelessWidget {
  final WaterTrackerService service;
  final List<WaterEntry> entries;
  final DrinkType selectedDrink;
  final ValueChanged<DrinkType> onDrinkChanged;
  final void Function(int ml, ContainerSize size) onAdd;

  const _LogTab({
    required this.service,
    required this.entries,
    required this.selectedDrink,
    required this.onDrinkChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final summary = service.dailySummary(entries, now);
    final pacing = service.pacing(entries, now);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Progress Ring ──
          _ProgressRing(summary: summary),
          const SizedBox(height: 8),
          // Pacing status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _pacingColor(pacing.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_pacingIcon(pacing.status),
                    size: 16, color: _pacingColor(pacing.status)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    pacing.recommendation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _pacingColor(pacing.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ── Drink Type Selector ──
          Text('Drink Type',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DrinkType.values.map((d) {
              final isSelected = d == selectedDrink;
              return ChoiceChip(
                label: Text('${d.emoji} ${d.label}'),
                selected: isSelected,
                onSelected: (_) => onDrinkChanged(d),
                selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // ── Quick-Add Buttons ──
          Text('Quick Add',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: ContainerSize.values
                .where((s) => s != ContainerSize.custom)
                .map((size) => _QuickAddButton(
                      size: size,
                      emoji: selectedDrink.emoji,
                      onTap: () => onAdd(size.defaultMl, size),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Custom amount button
          OutlinedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Custom Amount'),
            onPressed: () => _showCustomAmountDialog(context),
          ),
        ],
      ),
    );
  }

  void _showCustomAmountDialog(BuildContext context) {
    final controller = TextEditingController(text: '250');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (ml)',
            suffixText: 'ml',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final ml = int.tryParse(controller.text);
              if (ml != null && ml > 0 && ml <= 5000) {
                onAdd(ml, ContainerSize.custom);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Color _pacingColor(String status) {
    switch (status) {
      case 'ahead':
        return Colors.green;
      case 'on_track':
        return Colors.blue;
      case 'behind':
        return Colors.orange;
      case 'way_behind':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _pacingIcon(String status) {
    switch (status) {
      case 'ahead':
        return Icons.trending_up;
      case 'on_track':
        return Icons.check_circle_outline;
      case 'behind':
        return Icons.warning_amber;
      case 'way_behind':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }
}

// ── Progress Ring Widget ────────────────────────────────────────────

class _ProgressRing extends StatelessWidget {
  final DailySummary summary;
  const _ProgressRing({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (summary.progressPercent / 100).clamp(0.0, 1.0);
    final color = summary.goalMet
        ? Colors.green
        : progress > 0.6
            ? Colors.blue
            : progress > 0.3
                ? Colors.orange
                : Colors.red;

    return SizedBox(
      width: 180,
      height: 180,
      child: CustomPaint(
        painter: _RingPainter(progress: progress, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${summary.totalMl}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '/ ${summary.goalMl} ml',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
              if (summary.goalMet)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('✅ Goal met!',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 12.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ── Quick Add Button ────────────────────────────────────────────────

class _QuickAddButton extends StatelessWidget {
  final ContainerSize size;
  final String emoji;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.size,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(size.label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            Text('${size.defaultMl}ml',
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}

// ── History Tab ─────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final List<WaterEntry> entries;
  final void Function(int index) onRemove;

  const _HistoryTab({required this.entries, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    // Filter to today's entries, newest first
    final now = DateTime.now();
    final todayEntries = entries
        .asMap()
        .entries
        .where((e) {
          final t = e.value.timestamp;
          return t.year == now.year &&
              t.month == now.month &&
              t.day == now.day;
        })
        .toList()
        .reversed
        .toList();

    if (todayEntries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💧', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No entries yet today',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 4),
            Text('Tap the Log tab to start tracking!',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: todayEntries.length,
      itemBuilder: (context, index) {
        final mapEntry = todayEntries[index];
        final entry = mapEntry.value;
        final originalIndex = mapEntry.key;
        final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
            '${entry.timestamp.minute.toString().padLeft(2, '0')}';

        return Dismissible(
          key: ValueKey(entry.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          onDismissed: (_) => onRemove(originalIndex),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Text(entry.drinkType.emoji,
                  style: const TextStyle(fontSize: 28)),
              title: Text('${entry.amountMl}ml ${entry.drinkType.label}'),
              subtitle: Text(
                '$time · ${entry.containerSize.label} · '
                '${entry.effectiveHydrationMl.toStringAsFixed(0)}ml effective',
              ),
              trailing: Text(
                '+${entry.amountMl}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Insights Tab ────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final WaterTrackerService service;
  final List<WaterEntry> entries;

  const _InsightsTab({required this.service, required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final report = service.report(entries, now);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Streak Card ──
          _InsightCard(
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            title: 'Hydration Streak',
            children: [
              _StatRow('Current streak', '${report.streak.currentStreak} days'),
              _StatRow('Longest streak', '${report.streak.longestStreak} days'),
              if (report.streak.lastGoalMetDate != null)
                _StatRow(
                  'Last goal met',
                  _formatDate(report.streak.lastGoalMetDate!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Today's Breakdown ──
          _InsightCard(
            icon: Icons.pie_chart,
            iconColor: Colors.blue,
            title: 'Today\'s Breakdown',
            children: [
              _StatRow('Total', '${report.today.totalMl}ml'),
              _StatRow('Effective hydration',
                  '${report.today.effectiveHydrationMl.toStringAsFixed(0)}ml'),
              _StatRow('Entries', '${report.today.entryCount}'),
              _StatRow('Grade', report.today.grade),
              if (report.today.byDrinkType.isNotEmpty) ...[
                const Divider(height: 16),
                ...report.today.byDrinkType.entries.map((e) => _StatRow(
                      '${e.key.emoji} ${e.key.label}',
                      '${e.value}ml',
                    )),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // ── Weekly Trend ──
          if (report.weeklyTrend != null) ...[
            _InsightCard(
              icon: Icons.trending_up,
              iconColor: Colors.green,
              title: 'Weekly Trend',
              children: [
                _StatRow(
                    'Daily average',
                    '${report.weeklyTrend!.avgDailyMl.toStringAsFixed(0)}ml'),
                _StatRow(
                    'Goals met', '${report.weeklyTrend!.daysGoalMet}/7 days'),
                _StatRow(
                    'Consistency',
                    '${report.weeklyTrend!.consistency.toStringAsFixed(0)}%'),
                _StatRow('Most common drink',
                    '${report.weeklyTrend!.mostCommonDrink.emoji} ${report.weeklyTrend!.mostCommonDrink.label}'),
                _StatRow('Peak hour', '${report.weeklyTrend!.peakHour}:00'),
                const Divider(height: 16),
                // Mini bar chart of last 7 days
                SizedBox(
                  height: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: report.weeklyTrend!.days.map((d) {
                      final maxMl = report.weeklyTrend!.days
                          .fold<int>(1, (m, day) => day.totalMl > m ? day.totalMl : m);
                      final height = maxMl > 0 ? (d.totalMl / maxMl * 60) : 0.0;
                      final dayLabel = [
                        'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                      ][d.date.weekday - 1];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 28,
                            height: height.clamp(2.0, 60.0),
                            decoration: BoxDecoration(
                              color: d.goalMet
                                  ? Colors.green.withOpacity(0.7)
                                  : theme.colorScheme.primary.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(dayLabel,
                              style: const TextStyle(fontSize: 9)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // ── Tips ──
          if (report.tips.isNotEmpty)
            _InsightCard(
              icon: Icons.lightbulb_outline,
              iconColor: Colors.amber,
              title: 'Tips',
              children: report.tips
                  .map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Shared Insight Widgets ──────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
