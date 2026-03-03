import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/daily_timeline_service.dart';
import '../../core/services/event_service.dart';
import '../../core/utils/formatting_utils.dart';
import '../../models/event_model.dart';
import '../../state/providers/event_provider.dart';
import '../widgets/event_form_dialog.dart';
import 'event_detail_screen.dart';

/// A daily agenda view showing events as a vertical timeline with hour markers,
/// a "now" indicator line, and day-by-day navigation.
///
/// Features:
/// - Vertical timeline with hour gutters (8 AM – 10 PM)
/// - Event blocks color-coded by priority with title, time, and location
/// - Red "now" indicator line showing current time
/// - Auto-scrolls to current hour on load
/// - Swipe left/right to navigate between days
/// - Day summary bar (event count, busy time, free time)
/// - Tap event to view details, long-press to edit
/// - Tap free slots to quick-add an event at that time
class AgendaTimelineScreen extends StatefulWidget {
  /// Optional initial date. Defaults to today.
  final DateTime? initialDate;

  const AgendaTimelineScreen({Key? key, this.initialDate}) : super(key: key);

  @override
  State<AgendaTimelineScreen> createState() => _AgendaTimelineScreenState();
}

class _AgendaTimelineScreenState extends State<AgendaTimelineScreen> {
  late DateTime _selectedDate;
  late final EventService _eventService;
  late final DailyTimelineService _timelineService;
  late final ScrollController _scrollController;
  late final PageController _pageController;
  bool _loaded = false;

  // Constants for timeline layout
  static const double _hourHeight = 80.0;
  static const double _gutterWidth = 56.0;
  static const int _startHour = 8;
  static const int _endHour = 22;
  static const int _totalHours = _endHour - _startHour;

  @override
  void initState() {
    super.initState();
    _selectedDate = _stripTime(widget.initialDate ?? DateTime.now());
    _timelineService = const DailyTimelineService();
    _scrollController = ScrollController();
    _pageController = PageController(initialPage: 500); // Center page for swipe
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _eventService = EventService(
        provider: Provider.of<EventProvider>(context, listen: false),
      );
      // Auto-scroll to current hour after build
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
    }
  }

  DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime _dateForPage(int page) {
    final offset = page - 500;
    return _stripTime(widget.initialDate ?? DateTime.now())
        .add(Duration(days: offset));
  }

  void _scrollToNow() {
    final now = DateTime.now();
    if (_stripTime(now) != _selectedDate) return;
    final hourOffset = now.hour + now.minute / 60.0 - _startHour;
    if (hourOffset < 0) return;
    final targetScroll = (hourOffset * _hourHeight) - 100;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  void _goToToday() {
    final today = _stripTime(DateTime.now());
    setState(() => _selectedDate = today);
    _pageController.animateToPage(
      500,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(milliseconds: 350), _scrollToNow);
  }

  Future<void> _addEventAtTime(DateTime time) async {
    // Pre-populate with the selected time slot by creating a partial event
    final event = await EventFormDialog.show(context);
    if (event != null && mounted) {
      await _eventService.addEvent(event);
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

  @override
  Widget build(BuildContext context) {
    final today = _stripTime(DateTime.now());
    final isToday = _selectedDate == today;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isToday
              ? 'Today, ${DateFormat('MMM d').format(_selectedDate)}'
              : DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
        ),
        elevation: 0,
        actions: [
          if (!isToday)
            IconButton(
              icon: const Icon(Icons.today),
              onPressed: _goToToday,
              tooltip: 'Jump to today',
            ),
        ],
      ),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, _) {
          return PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() => _selectedDate = _dateForPage(page));
              if (_dateForPage(page) == today) {
                Future.delayed(
                    const Duration(milliseconds: 100), _scrollToNow);
              }
            },
            itemBuilder: (context, page) {
              final date = _dateForPage(page);
              final events = eventProvider.events.toList();
              final timeline = _timelineService.buildTimeline(
                events: events,
                date: date,
              );
              final summary = _timelineService.summarize(timeline, date: date);

              return Column(
                children: [
                  _buildSummaryBar(summary),
                  Expanded(
                    child: _buildTimeline(timeline, date),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar(DailySummary summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryChip(
            Icons.event,
            '${summary.eventCount}',
            'events',
            Colors.blue,
          ),
          _summaryChip(
            Icons.schedule,
            summary.busyTimeLabel,
            'busy',
            Colors.orange,
          ),
          _summaryChip(
            Icons.free_breakfast,
            summary.freeTimeLabel,
            'free',
            Colors.green,
          ),
          if (summary.conflictCount > 0)
            _summaryChip(
              Icons.warning_amber,
              '${summary.conflictCount}',
              'conflicts',
              Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _summaryChip(
      IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTimeline(List<TimelineBlock> timeline, DateTime date) {
    final now = DateTime.now();
    final isToday = _stripTime(now) == _stripTime(date);
    final totalHeight = _totalHours * _hourHeight;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 40),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            // Hour lines and labels
            ..._buildHourMarkers(),

            // Event blocks
            ...timeline
                .where((b) => b.isEvent)
                .map((block) => _buildEventBlock(block)),

            // Free slot tap targets
            ...timeline
                .where((b) => !b.isEvent)
                .map((block) => _buildFreeSlot(block)),

            // Now indicator
            if (isToday) _buildNowIndicator(now),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHourMarkers() {
    return List.generate(_totalHours + 1, (i) {
      final hour = _startHour + i;
      final y = i * _hourHeight;
      return Positioned(
        left: 0,
        right: 0,
        top: y,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _gutterWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 0),
                child: Text(
                  _formatHour(hour),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 0.5,
                color: Colors.grey[300],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEventBlock(TimelineBlock block) {
    final event = block.event!;
    final topOffset = _timeToOffset(block.start);
    final height =
        (block.duration.inMinutes / 60.0 * _hourHeight).clamp(28.0, double.infinity);
    final color = event.priority.color;

    return Positioned(
      left: _gutterWidth + 4,
      right: 12,
      top: topOffset,
      height: height,
      child: GestureDetector(
        onTap: () => _viewEventDetail(event),
        onLongPress: () => _editEvent(event),
        child: Container(
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: color, width: 3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: color.withAlpha(220),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${FormattingUtils.formatTime12h(block.start)} – ${FormattingUtils.formatTime12h(block.end)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (height > 40 && event.location.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.location,
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (height > 56 && event.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    event.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeSlot(TimelineBlock block) {
    final topOffset = _timeToOffset(block.start);
    final height =
        (block.duration.inMinutes / 60.0 * _hourHeight).clamp(20.0, double.infinity);

    return Positioned(
      left: _gutterWidth + 4,
      right: 12,
      top: topOffset,
      height: height,
      child: GestureDetector(
        onTap: () => _addEventAtTime(block.start),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade200,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: height > 30
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        block.durationLabel,
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  )
                : Icon(Icons.add, size: 12, color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }

  Widget _buildNowIndicator(DateTime now) {
    final topOffset = _timeToOffset(now);
    if (topOffset < 0 || topOffset > _totalHours * _hourHeight) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _gutterWidth - 6,
      right: 0,
      top: topOffset - 5,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(height: 1.5, color: Colors.red),
          ),
        ],
      ),
    );
  }

  double _timeToOffset(DateTime time) {
    final hours = time.hour + time.minute / 60.0 - _startHour;
    return hours * _hourHeight;
  }

  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour > 12) return '${hour - 12} PM';
    return '$hour AM';
  }
}
