import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../state/providers/event_provider.dart';

/// Analytics dashboard showing event statistics and scheduling insights.
///
/// Displays:
/// - Overview cards (total, upcoming, past, today)
/// - Priority distribution with visual bars
/// - Busiest days of the week
/// - Monthly event timeline
/// - Streak & scheduling insights
class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final events = eventProvider.events.toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Event Analytics'),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: events.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOverviewCards(events),
                  const SizedBox(height: 20),
                  _buildPriorityDistribution(events),
                  const SizedBox(height: 20),
                  _buildWeekdayChart(events),
                  const SizedBox(height: 20),
                  _buildMonthlyTimeline(events),
                  const SizedBox(height: 20),
                  _buildInsights(events),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No events yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create some events to see your analytics',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ───────────────── Overview Cards ─────────────────

  Widget _buildOverviewCards(List<EventModel> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final upcoming = events.where((e) => e.date.isAfter(now)).length;
    final past = events.where((e) => e.date.isBefore(now)).length;
    final todayCount = events
        .where((e) =>
            e.date.isAfter(today) && e.date.isBefore(tomorrow))
        .length;
    final thisWeek = events
        .where((e) =>
            e.date.isAfter(now) &&
            e.date.isBefore(now.add(const Duration(days: 7))))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.dashboard, title: 'Overview'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total',
                value: '${events.length}',
                icon: Icons.event_note,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Upcoming',
                value: '$upcoming',
                icon: Icons.upcoming,
                color: Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Today',
                value: '$todayCount',
                icon: Icons.today,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'This Week',
                value: '$thisWeek',
                icon: Icons.date_range,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ───────────────── Priority Distribution ─────────────────

  Widget _buildPriorityDistribution(List<EventModel> events) {
    final counts = <EventPriority, int>{};
    for (final p in EventPriority.values) {
      counts[p] = events.where((e) => e.priority == p).length;
    }
    final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);

    return _SectionCard(
      title: 'Priority Distribution',
      icon: Icons.priority_high,
      child: Column(
        children: EventPriority.values.map((priority) {
          final count = counts[priority]!;
          final fraction = maxCount > 0 ? count / maxCount : 0.0;
          final percent = events.isNotEmpty
              ? (count / events.length * 100).round()
              : 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Row(
                    children: [
                      Icon(priority.icon, size: 14, color: priority.color),
                      const SizedBox(width: 4),
                      Text(
                        priority.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: priority.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 20,
                      backgroundColor: priority.color.withAlpha(25),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(priority.color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 50,
                  child: Text(
                    '$count ($percent%)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────── Weekday Chart ─────────────────

  Widget _buildWeekdayChart(List<EventModel> events) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayCounts = List.filled(7, 0);

    for (final event in events) {
      // DateTime.weekday: 1 = Monday, 7 = Sunday
      dayCounts[event.date.weekday - 1]++;
    }

    final maxDay = dayCounts.fold<int>(0, (a, b) => a > b ? a : b);
    final busiestIdx = dayCounts.indexOf(maxDay);

    return _SectionCard(
      title: 'Busiest Days',
      icon: Icons.calendar_view_week,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final fraction = maxDay > 0 ? dayCounts[i] / maxDay : 0.0;
              final isBusiest = i == busiestIdx && dayCounts[i] > 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Text(
                        '${dayCounts[i]}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isBusiest
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color:
                              isBusiest ? Colors.indigo : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 80 * fraction + 4,
                        decoration: BoxDecoration(
                          color: isBusiest
                              ? Colors.indigo
                              : Colors.indigo.withAlpha(100),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayNames[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isBusiest
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color:
                              isBusiest ? Colors.indigo : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          if (maxDay > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.indigo),
                  const SizedBox(width: 6),
                  Text(
                    'Your busiest day is ${dayNames[busiestIdx]} with $maxDay event${maxDay == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────── Monthly Timeline ─────────────────

  Widget _buildMonthlyTimeline(List<EventModel> events) {
    // Group events by year-month
    final monthCounts = <String, int>{};
    for (final event in events) {
      final key = DateFormat('yyyy-MM').format(event.date);
      monthCounts[key] = (monthCounts[key] ?? 0) + 1;
    }

    if (monthCounts.isEmpty) return const SizedBox.shrink();

    // Sort by date
    final sortedKeys = monthCounts.keys.toList()..sort();
    // Show at most the last 6 months
    final displayKeys = sortedKeys.length > 6
        ? sortedKeys.sublist(sortedKeys.length - 6)
        : sortedKeys;
    final maxMonth =
        monthCounts.values.fold<int>(0, (a, b) => a > b ? a : b);

    return _SectionCard(
      title: 'Monthly Timeline',
      icon: Icons.timeline,
      child: Column(
        children: displayKeys.map((key) {
          final count = monthCounts[key]!;
          final fraction = maxMonth > 0 ? count / maxMonth : 0.0;
          final date = DateTime.parse('$key-01');
          final label = DateFormat('MMM yyyy').format(date);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 18,
                      backgroundColor: Colors.indigo.withAlpha(20),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.indigo),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────── Insights ─────────────────

  Widget _buildInsights(List<EventModel> events) {
    final insights = <_Insight>[];
    final now = DateTime.now();

    // Upcoming urgents
    final urgentUpcoming = events
        .where((e) =>
            e.priority == EventPriority.urgent && e.date.isAfter(now))
        .length;
    if (urgentUpcoming > 0) {
      insights.add(_Insight(
        icon: Icons.warning_amber,
        color: Colors.red,
        text:
            'You have $urgentUpcoming urgent event${urgentUpcoming == 1 ? '' : 's'} coming up',
      ));
    }

    // Next event
    final upcomingEvents = events
        .where((e) => e.date.isAfter(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (upcomingEvents.isNotEmpty) {
      final next = upcomingEvents.first;
      final diff = next.date.difference(now);
      String timeStr;
      if (diff.inDays > 0) {
        timeStr = 'in ${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
      } else if (diff.inHours > 0) {
        timeStr = 'in ${diff.inHours} hour${diff.inHours == 1 ? '' : 's'}';
      } else {
        timeStr =
            'in ${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'}';
      }
      insights.add(_Insight(
        icon: Icons.next_plan,
        color: Colors.teal,
        text: 'Next event: "${next.title}" $timeStr',
      ));
    }

    // Average events per week
    if (events.length >= 2) {
      final sorted = events.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final span = sorted.last.date.difference(sorted.first.date).inDays;
      if (span > 0) {
        final weeks = span / 7;
        final perWeek = (events.length / weeks).toStringAsFixed(1);
        insights.add(_Insight(
          icon: Icons.speed,
          color: Colors.purple,
          text: 'You schedule ~$perWeek events per week on average',
        ));
      }
    }

    // Most common priority
    final priorityCounts = <EventPriority, int>{};
    for (final e in events) {
      priorityCounts[e.priority] = (priorityCounts[e.priority] ?? 0) + 1;
    }
    final topPriority = priorityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (topPriority.isNotEmpty) {
      final top = topPriority.first;
      final pct = (top.value / events.length * 100).round();
      insights.add(_Insight(
        icon: top.key.icon,
        color: top.key.color,
        text:
            'Most events are ${top.key.label} priority ($pct% of total)',
      ));
    }

    // Overdue (past high/urgent without completion — simplified)
    final overdueCount = events
        .where((e) =>
            e.date.isBefore(now) &&
            (e.priority == EventPriority.high ||
                e.priority == EventPriority.urgent))
        .length;
    if (overdueCount > 0) {
      insights.add(_Insight(
        icon: Icons.schedule,
        color: Colors.deepOrange,
        text:
            '$overdueCount high/urgent event${overdueCount == 1 ? '' : 's'} in the past — may need follow-up',
      ));
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Insights',
      icon: Icons.lightbulb_outline,
      child: Column(
        children: insights
            .map((insight) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: insight.color.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(insight.icon,
                            size: 16, color: insight.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          insight.text,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ───────────────── Helper Widgets ─────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _Insight {
  final IconData icon;
  final Color color;
  final String text;

  const _Insight({
    required this.icon,
    required this.color,
    required this.text,
  });
}
