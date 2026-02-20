import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/event_service.dart';
import '../../models/event_model.dart';
import '../../state/providers/event_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/event_form_dialog.dart';
import 'event_detail_screen.dart';

/// Calendar view screen showing events on a month-grid calendar.
///
/// Features:
/// - Month navigation with swipe gestures and arrow buttons
/// - Today button to jump back to current month
/// - Event dots on calendar days (color-coded by highest priority)
/// - Tap a day to see its events in a bottom sheet
/// - Event count badge on days with multiple events
/// - Current day highlight
/// - Selected day highlight
/// - Quick add event from calendar day
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  DateTime? _selectedDay;
  late final EventService _eventService;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _eventService = EventService(
        provider: Provider.of<EventProvider>(context, listen: false),
      );
    }
  }

  /// Groups events by their date (year-month-day) for O(1) lookup.
  Map<DateTime, List<EventModel>> _groupEventsByDay(List<EventModel> events) {
    final map = <DateTime, List<EventModel>>{};
    for (final event in events) {
      final key = DateTime(event.date.year, event.date.month, event.date.day);
      map.putIfAbsent(key, () => []).add(event);
    }
    // Sort each day's events by time
    for (final list in map.values) {
      list.sort((a, b) => a.date.compareTo(b.date));
    }
    return map;
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay = null;
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDay = null;
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  void _selectDay(DateTime day) {
    setState(() => _selectedDay = day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime day) {
    return _isSameDay(day, DateTime.now());
  }

  bool _isCurrentMonth(DateTime day) {
    return day.month == _currentMonth.month && day.year == _currentMonth.year;
  }

  /// Returns the highest priority among events for visual indicator.
  EventPriority _highestPriority(List<EventModel> events) {
    var highest = EventPriority.low;
    for (final e in events) {
      if (e.priority.index > highest.index) {
        highest = e.priority;
      }
    }
    return highest;
  }

  Future<void> _addEventForDay(DateTime day) async {
    final event = await EventFormDialog.show(context);
    if (event != null && mounted) {
      // Override the date to the selected day, keeping the chosen time
      final adjusted = event.copyWith(
        date: DateTime(
          day.year,
          day.month,
          day.day,
          event.date.hour,
          event.date.minute,
        ),
      );
      await _eventService.addEvent(adjusted);
    }
  }

  void _viewEventDetail(EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          event: event,
          eventService: _eventService,
        ),
      ),
    );
  }

  Future<void> _editEvent(EventModel event) async {
    final edited = await EventFormDialog.show(context, event: event);
    if (edited != null && mounted) {
      await _eventService.updateEvent(edited);
    }
  }

  void _showDayEvents(DateTime day, List<EventModel> dayEvents) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DayEventsSheet(
        day: day,
        events: dayEvents,
        onTap: (event) {
          Navigator.of(ctx).pop();
          _viewEventDetail(event);
        },
        onEdit: (event) {
          Navigator.of(ctx).pop();
          _editEvent(event);
        },
        onDelete: (event) {
          Navigator.of(ctx).pop();
          _eventService.deleteEvent(event.id);
        },
        onAdd: () {
          Navigator.of(ctx).pop();
          _addEventForDay(day);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final events = eventProvider.events.toList();
    final eventsByDay = _groupEventsByDay(events);
    final now = DateTime.now();
    final isCurrentMonth =
        _currentMonth.year == now.year && _currentMonth.month == now.month;

    // Get events for the selected day
    final selectedDayEvents = _selectedDay != null
        ? (eventsByDay[_selectedDay] ?? [])
        : <EventModel>[];

    // Count events this month
    final monthEventCount = events
        .where((e) =>
            e.date.year == _currentMonth.year &&
            e.date.month == _currentMonth.month)
        .length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Calendar'),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (!isCurrentMonth)
            TextButton.icon(
              onPressed: _goToToday,
              icon: const Icon(Icons.today, color: Colors.white70, size: 18),
              label: const Text(
                'Today',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Month header with navigation
          _buildMonthHeader(monthEventCount),

          // Weekday labels
          _buildWeekdayLabels(),

          // Calendar grid
          Expanded(
            child: Column(
              children: [
                _buildCalendarGrid(eventsByDay),

                // Selected day events list
                if (_selectedDay != null) ...[
                  const Divider(height: 1),
                  _buildSelectedDayHeader(selectedDayEvents),
                  Expanded(
                    child: selectedDayEvents.isEmpty
                        ? _buildEmptyDayState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: selectedDayEvents.length,
                            itemBuilder: (context, index) {
                              final event = selectedDayEvents[index];
                              return EventCard(
                                event: event,
                                onTap: () => _viewEventDetail(event),
                                onEdit: () => _editEvent(event),
                                onDelete: () =>
                                    _eventService.deleteEvent(event.id),
                              );
                            },
                          ),
                  ),
                ] else
                  Expanded(child: _buildNoSelectionState()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedDay != null) {
            _addEventForDay(_selectedDay!);
          } else {
            _addEventForDay(DateTime.now());
          }
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: _selectedDay != null
            ? 'Add event on ${DateFormat('MMM dd').format(_selectedDay!)}'
            : 'Add event today',
      ),
    );
  }

  Widget _buildMonthHeader(int monthEventCount) {
    return Container(
      color: Colors.indigo,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: _goToPreviousMonth,
            tooltip: 'Previous month',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (monthEventCount > 0)
                  Text(
                    '$monthEventCount event${monthEventCount == 1 ? '' : 's'} this month',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _goToNextMonth,
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: days.map((day) {
          final isWeekend = day == 'Sat' || day == 'Sun';
          return Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isWeekend ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, List<EventModel>> eventsByDay) {
    final days = _getCalendarDays();
    final rows = <List<DateTime>>[];

    for (var i = 0; i < days.length; i += 7) {
      rows.add(days.sublist(i, (i + 7).clamp(0, days.length)));
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: rows.map((week) {
          return Row(
            children: week.map((day) {
              return Expanded(
                child: _buildDayCell(day, eventsByDay),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayCell(
      DateTime day, Map<DateTime, List<EventModel>> eventsByDay) {
    final dayKey = DateTime(day.year, day.month, day.day);
    final dayEvents = eventsByDay[dayKey] ?? [];
    final isToday = _isToday(day);
    final isSelected = _selectedDay != null && _isSameDay(day, _selectedDay!);
    final isInMonth = _isCurrentMonth(day);
    final hasEvents = dayEvents.isNotEmpty;

    return GestureDetector(
      onTap: () {
        _selectDay(dayKey);
        if (hasEvents) {
          _showDayEvents(dayKey, dayEvents);
        }
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.indigo.withAlpha(20)
              : isToday
                  ? Colors.indigo.withAlpha(8)
                  : null,
          border: Border.all(
            color: isSelected
                ? Colors.indigo.withAlpha(60)
                : Colors.grey.withAlpha(20),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Day number
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: isToday
                      ? BoxDecoration(
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(14),
                        )
                      : null,
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isToday || hasEvents ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? Colors.white
                          : isInMonth
                              ? (hasEvents ? Colors.black87 : Colors.black54)
                              : Colors.grey[350],
                    ),
                  ),
                ),

                // Event indicators
                if (hasEvents && isInMonth)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: _buildEventDots(dayEvents),
                  ),
              ],
            ),

            // Event count badge (for 3+ events)
            if (dayEvents.length >= 3 && isInMonth)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _highestPriority(dayEvents).color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${dayEvents.length}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDots(List<EventModel> events) {
    // Show up to 3 dots, color-coded by priority
    final priorities = events
        .map((e) => e.priority)
        .toSet()
        .toList()
      ..sort((a, b) => b.index.compareTo(a.index)); // highest first

    final dotCount = priorities.length.clamp(1, 3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(dotCount, (i) {
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: priorities[i].color,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  /// Generates the list of days to display in the calendar grid.
  ///
  /// Includes leading days from the previous month and trailing days from
  /// the next month to fill complete weeks (Mon-Sun).
  List<DateTime> _getCalendarDays() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Monday = 1, Sunday = 7
    final startWeekday = firstDayOfMonth.weekday;
    final leadingDays = startWeekday - 1; // Days from previous month

    final endWeekday = lastDayOfMonth.weekday;
    final trailingDays = endWeekday == 7 ? 0 : 7 - endWeekday;

    final days = <DateTime>[];

    // Previous month's trailing days
    for (var i = leadingDays; i > 0; i--) {
      days.add(firstDayOfMonth.subtract(Duration(days: i)));
    }

    // Current month's days
    for (var i = 0; i < lastDayOfMonth.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i + 1));
    }

    // Next month's leading days
    for (var i = 1; i <= trailingDays; i++) {
      days.add(DateTime(
          lastDayOfMonth.year, lastDayOfMonth.month, lastDayOfMonth.day + i));
    }

    return days;
  }

  Widget _buildSelectedDayHeader(List<EventModel> events) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey[100],
      child: Row(
        children: [
          Icon(Icons.event, size: 18, color: Colors.indigo[400]),
          const SizedBox(width: 8),
          Text(
            DateFormat('EEEE, MMMM dd').format(_selectedDay!),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          Text(
            '${events.length} event${events.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No events on this day',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to add one',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSelectionState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Tap a date to see events',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet showing all events for a specific day.
class _DayEventsSheet extends StatelessWidget {
  final DateTime day;
  final List<EventModel> events;
  final ValueChanged<EventModel> onTap;
  final ValueChanged<EventModel> onEdit;
  final ValueChanged<EventModel> onDelete;
  final VoidCallback onAdd;

  const _DayEventsSheet({
    required this.day,
    required this.events,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(day),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(day),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Event list
          Flexible(
            child: events.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'No events',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _DayEventTile(
                        event: event,
                        onTap: () => onTap(event),
                        onEdit: () => onEdit(event),
                        onDelete: () => onDelete(event),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Compact event tile for the day events sheet.
class _DayEventTile extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DayEventTile({
    required this.event,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Priority color bar
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: event.priority.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Time
            SizedBox(
              width: 56,
              child: Text(
                DateFormat('h:mm a').format(event.date),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Title & tags
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: event.tags.take(3).map((tag) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: tag.color.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: tag.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

            // Priority badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: event.priority.color.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(event.priority.icon,
                      size: 12, color: event.priority.color),
                  const SizedBox(width: 2),
                  Text(
                    event.priority.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: event.priority.color,
                    ),
                  ),
                ],
              ),
            ),

            // Recurrence indicator
            if (event.isRecurring)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.repeat, size: 14, color: Colors.blue[300]),
              ),
          ],
        ),
      ),
    );
  }
}
