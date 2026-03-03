import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../state/providers/event_provider.dart';
import 'event_detail_screen.dart';
import '../../core/services/event_service.dart';

/// A screen that displays upcoming events with live countdown timers,
/// updating every second to show days, hours, minutes, and seconds
/// remaining until each event.
class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final now = DateTime.now();

    // Get future events sorted by date ascending (soonest first)
    final upcoming = eventProvider.events
        .where((e) => e.date.isAfter(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Countdowns'),
        elevation: 0,
      ),
      body: upcoming.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: upcoming.length,
              itemBuilder: (context, index) {
                return _CountdownCard(
                  event: upcoming[index],
                  now: now,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No upcoming events',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Future events will appear here with live countdowns',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final EventModel event;
  final DateTime now;

  const _CountdownCard({required this.event, required this.now});

  @override
  Widget build(BuildContext context) {
    final remaining = event.date.difference(now);
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    // Urgency color based on how soon the event is
    final Color urgencyColor;
    if (days == 0 && hours < 1) {
      urgencyColor = Colors.red;
    } else if (days == 0) {
      urgencyColor = Colors.orange;
    } else if (days <= 3) {
      urgencyColor = Colors.amber;
    } else {
      urgencyColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final eventService = EventService(
            provider: Provider.of<EventProvider>(context, listen: false),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(
                event: event,
                eventService: eventService,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event title and priority
              Row(
                children: [
                  Icon(event.priority.icon, size: 18, color: event.priority.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Event date
              Text(
                _formatDate(event.date),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              // Countdown digits
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TimeUnit(value: days, label: 'days', color: urgencyColor),
                  _TimeSeparator(color: urgencyColor),
                  _TimeUnit(value: hours, label: 'hrs', color: urgencyColor),
                  _TimeSeparator(color: urgencyColor),
                  _TimeUnit(value: minutes, label: 'min', color: urgencyColor),
                  _TimeSeparator(color: urgencyColor),
                  _TimeUnit(value: seconds, label: 'sec', color: urgencyColor),
                ],
              ),
              // Progress bar showing how close we are (within 30 days)
              if (days <= 30) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1.0 - (remaining.inMinutes / (30 * 24 * 60)).clamp(0.0, 1.0),
                    backgroundColor: urgencyColor.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation(urgencyColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year} at $h:$min $ampm';
  }
}

class _TimeUnit extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _TimeUnit({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  final Color color;

  const _TimeSeparator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color.withAlpha(100),
        ),
      ),
    );
  }
}
