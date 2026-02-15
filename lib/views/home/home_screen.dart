import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/event_service.dart';
import '../../state/providers/event_provider.dart';
import '../../models/event_model.dart';
import '../widgets/event_card.dart';
import '../widgets/event_form_dialog.dart';
import 'event_detail_screen.dart';
import 'stats_screen.dart';

/// Sort criteria for the event list.
enum EventSortBy {
  dateAsc,
  dateDesc,
  priorityHighFirst,
  priorityLowFirst,
  titleAZ,
  titleZA;

  String get label {
    switch (this) {
      case EventSortBy.dateAsc:
        return 'Date (earliest first)';
      case EventSortBy.dateDesc:
        return 'Date (latest first)';
      case EventSortBy.priorityHighFirst:
        return 'Priority (high → low)';
      case EventSortBy.priorityLowFirst:
        return 'Priority (low → high)';
      case EventSortBy.titleAZ:
        return 'Title (A → Z)';
      case EventSortBy.titleZA:
        return 'Title (Z → A)';
    }
  }

  IconData get icon {
    switch (this) {
      case EventSortBy.dateAsc:
        return Icons.arrow_upward;
      case EventSortBy.dateDesc:
        return Icons.arrow_downward;
      case EventSortBy.priorityHighFirst:
        return Icons.priority_high;
      case EventSortBy.priorityLowFirst:
        return Icons.low_priority;
      case EventSortBy.titleAZ:
        return Icons.sort_by_alpha;
      case EventSortBy.titleZA:
        return Icons.sort_by_alpha;
    }
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final EventService _eventService;
  bool _loaded = false;

  // Search & filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<EventPriority> _activePriorityFilters = {};
  EventSortBy _currentSort = EventSortBy.dateDesc;
  bool _showFilters = false;

  // Cached filtered results to avoid re-sorting on every build.
  // Invalidated when the event list identity, search query, filters,
  // or sort order change.
  List<EventModel>? _filteredCache;
  int _cachedEventHash = 0;
  String _cachedSearchQuery = '';
  Set<EventPriority> _cachedPriorityFilters = {};
  EventSortBy _cachedSort = EventSortBy.dateDesc;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _eventService = EventService(
        provider: Provider.of<EventProvider>(context, listen: false),
      );
      _eventService.loadEvents();
    }
  }

  /// Applies search query, priority filters, and sort order to the event list.
  ///
  /// Results are cached and only recomputed when the event list (by hashCode),
  /// search query, priority filters, or sort order change. This avoids an
  /// O(n log n) sort on every frame rebuild when the user scrolls or the
  /// widget tree rebuilds for unrelated reasons.
  List<EventModel> _getFilteredEvents(List<EventModel> events) {
    final eventHash = Object.hashAll(events);
    final filtersMatch = _cachedSearchQuery == _searchQuery &&
        _cachedPriorityFilters.length == _activePriorityFilters.length &&
        _cachedPriorityFilters.containsAll(_activePriorityFilters) &&
        _cachedSort == _currentSort &&
        _cachedEventHash == eventHash;

    if (filtersMatch && _filteredCache != null) {
      return _filteredCache!;
    }

    var filtered = events.toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(_searchQuery) ||
            event.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply priority filters
    if (_activePriorityFilters.isNotEmpty) {
      filtered = filtered
          .where((event) => _activePriorityFilters.contains(event.priority))
          .toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_currentSort) {
        case EventSortBy.dateAsc:
          return a.date.compareTo(b.date);
        case EventSortBy.dateDesc:
          return b.date.compareTo(a.date);
        case EventSortBy.priorityHighFirst:
          return b.priority.index.compareTo(a.priority.index);
        case EventSortBy.priorityLowFirst:
          return a.priority.index.compareTo(b.priority.index);
        case EventSortBy.titleAZ:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case EventSortBy.titleZA:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
      }
    });

    // Cache results
    _filteredCache = filtered;
    _cachedEventHash = eventHash;
    _cachedSearchQuery = _searchQuery;
    _cachedPriorityFilters = Set.of(_activePriorityFilters);
    _cachedSort = _currentSort;

    return filtered;
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _activePriorityFilters.isNotEmpty;

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _activePriorityFilters.clear();
      _currentSort = EventSortBy.dateDesc;
    });
  }

  Future<void> _addEvent() async {
    final event = await EventFormDialog.show(context);
    if (event != null && mounted) {
      await _eventService.addEvent(event);
    }
  }

  Future<void> _editEvent(EventModel event) async {
    final edited = await EventFormDialog.show(context, event: event);
    if (edited != null && mounted) {
      await _eventService.updateEvent(edited);
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

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sort Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...EventSortBy.values.map((sort) {
              final isSelected = _currentSort == sort;
              return ListTile(
                leading: Icon(
                  sort.icon,
                  color: isSelected ? Colors.blue : Colors.grey[600],
                ),
                title: Text(
                  sort.label,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.blue : null,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _currentSort = sort);
                  Navigator.of(ctx).pop();
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final allEvents = eventProvider.events;
    final filteredEvents = _getFilteredEvents(allEvents.toList());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        elevation: 0,
        actions: [
          // Analytics button
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
            tooltip: 'Event analytics',
          ),
          // Sort button
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: allEvents.isNotEmpty ? _showSortMenu : null,
            tooltip: 'Sort events',
          ),
          // Filter toggle
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: Icon(
                _showFilters
                    ? Icons.filter_list_off
                    : Icons.filter_list,
              ),
            ),
            onPressed: allEvents.isNotEmpty
                ? () => setState(() => _showFilters = !_showFilters)
                : null,
            tooltip: _showFilters ? 'Hide filters' : 'Show filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible search & filter bar
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _showFilters
                ? _buildFilterBar(allEvents)
                : const SizedBox.shrink(),
          ),

          // Results info bar (when filters active)
          if (_hasActiveFilters && allEvents.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withAlpha(15),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Showing ${filteredEvents.length} of ${allEvents.length} events',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearAllFilters,
                    child: Text(
                      'Clear all',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Event list
          Expanded(
            child: allEvents.isEmpty
                ? _buildEmptyState()
                : filteredEvents.isEmpty
                    ? _buildNoResultsState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          return EventCard(
                            event: event,
                            onTap: () => _viewEventDetail(event),
                            onEdit: () => _editEvent(event),
                            onDelete: () => _eventService.deleteEvent(event.id),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEvent,
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
    );
  }

  Widget _buildFilterBar(List<EventModel> allEvents) {
    // Count events per priority for the badges
    final priorityCounts = <EventPriority, int>{};
    for (final event in allEvents) {
      priorityCounts[event.priority] =
          (priorityCounts[event.priority] ?? 0) + 1;
    }

    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search events...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Priority filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Priority:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                ...EventPriority.values.map((priority) {
                  final isSelected =
                      _activePriorityFilters.contains(priority);
                  final count = priorityCounts[priority] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            priority.icon,
                            size: 14,
                            color: isSelected
                                ? Colors.white
                                : priority.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${priority.label} ($count)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : priority.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: priority.color,
                      backgroundColor: priority.color.withAlpha(20),
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _activePriorityFilters.add(priority);
                          } else {
                            _activePriorityFilters.remove(priority);
                          }
                        });
                      },
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No events yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first event',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No matching events',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search or filter',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _clearAllFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}
