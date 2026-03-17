import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';

/// A banner widget that displays the next upcoming event with a live
/// countdown timer. Updates every second to show the time remaining
/// until the event starts.
///
/// If no upcoming events exist, the widget renders as [SizedBox.shrink].
class NextUpBanner extends StatefulWidget {
  /// All events to search through for the nearest upcoming one.
  final List<EventModel> events;

  /// Called when the user taps on the banner.
  final void Function(EventModel event)? onTap;

  const NextUpBanner({
    required this.events,
    this.onTap,
    super.key,
  });

  @override
  State<NextUpBanner> createState() => _NextUpBannerState();
}

class _NextUpBannerState extends State<NextUpBanner> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  /// Cached next event to avoid O(n) scan every second.
  /// Only recomputed when the event list identity changes.
  EventModel? _cachedNextEvent;
  List<EventModel>? _cachedEventList;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final now = DateTime.now();
        // If the cached next event has passed, invalidate the cache
        // so the next build picks up the new nearest event.
        if (_cachedNextEvent != null && _cachedNextEvent!.date.isBefore(now)) {
          _cachedEventList = null;
        }
        setState(() => _now = now);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Finds the nearest future event from the list.
  ///
  /// Caches the result and only rescans when the event list reference
  /// changes or the cached event has passed, avoiding an O(n) scan
  /// every second on the timer tick.
  EventModel? _findNextEvent() {
    if (identical(_cachedEventList, widget.events) && _cachedNextEvent != null) {
      return _cachedNextEvent;
    }
    _cachedEventList = widget.events;
    EventModel? nearest;
    for (final event in widget.events) {
      if (event.date.isAfter(_now)) {
        if (nearest == null || event.date.isBefore(nearest.date)) {
          nearest = event;
        }
      }
    }
    _cachedNextEvent = nearest;
    return nearest;
  }

  /// Formats a Duration into a human-readable countdown string.
  String _formatCountdown(Duration diff) {
    if (diff.inDays > 0) {
      final hours = diff.inHours % 24;
      return '${diff.inDays}d ${hours}h';
    }
    if (diff.inHours > 0) {
      final minutes = diff.inMinutes % 60;
      return '${diff.inHours}h ${minutes}m';
    }
    if (diff.inMinutes > 0) {
      final seconds = diff.inSeconds % 60;
      return '${diff.inMinutes}m ${seconds}s';
    }
    return '${diff.inSeconds}s';
  }

  /// Returns a contextual label like "Today", "Tomorrow", or the day name.
  String _dayLabel(DateTime date) {
    final today = DateTime(_now.year, _now.month, _now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    final diff = eventDay.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return DateFormat('EEEE').format(date);
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final nextEvent = _findNextEvent();
    if (nextEvent == null) return const SizedBox.shrink();

    final diff = nextEvent.date.difference(_now);
    final isUrgent = diff.inHours < 1;
    final isSoon = diff.inHours < 24;

    final Color bgColor;
    final Color textColor;
    final Color subtitleColor;
    final IconData icon;

    if (isUrgent) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
      subtitleColor = Colors.red.shade600;
      icon = Icons.alarm;
    } else if (isSoon) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      subtitleColor = Colors.orange.shade600;
      icon = Icons.schedule;
    } else {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade800;
      subtitleColor = Colors.blue.shade600;
      icon = Icons.upcoming;
    }

    return GestureDetector(
      onTap: widget.onTap != null ? () => widget.onTap!(nextEvent) : null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: textColor.withAlpha(40),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: textColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: textColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Event info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT UP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: subtitleColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextEvent.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_dayLabel(nextEvent.date)} · ${DateFormat('h:mm a').format(nextEvent.date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),

            // Countdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: textColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatCountdown(diff),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),

            // Chevron
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: subtitleColor, size: 20),
          ],
        ),
      ),
    );
  }
}
