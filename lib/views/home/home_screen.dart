import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/event_repository.dart';
import '../../state/providers/event_provider.dart';
import '../../models/event_model.dart';
import '../widgets/event_card.dart';
import '../widgets/event_form_dialog.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventRepository _eventRepository = EventRepository();
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadPersistedEvents();
    }
  }

  /// Loads events from local SQLite storage and populates the provider.
  /// Without this, events saved via EventRepository are lost on app restart.
  Future<void> _loadPersistedEvents() async {
    try {
      final rows = await _eventRepository.getEvents();
      final events = rows.map((row) => EventModel.fromJson(row)).toList();
      if (mounted) {
        final provider = Provider.of<EventProvider>(context, listen: false);
        if (provider.events.isEmpty) {
          provider.setEvents(events);
        }
      }
    } catch (e) {
      debugPrint('Failed to load persisted events: $e');
    }
  }

  Future<void> _addEvent() async {
    final event = await EventFormDialog.show(context);
    if (event != null && mounted) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      eventProvider.addEvent(event);
      try {
        await _eventRepository.saveEvent(event.toJson());
      } catch (e) {
        debugPrint('Failed to persist event: $e');
      }
    }
  }

  Future<void> _editEvent(EventModel event) async {
    final edited = await EventFormDialog.show(context, event: event);
    if (edited != null && mounted) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      eventProvider.updateEvent(edited);
      try {
        await _eventRepository.updateEvent(edited.toJson());
      } catch (e) {
        debugPrint('Failed to persist edited event: $e');
      }
    }
  }

  void _viewEventDetail(EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        elevation: 0,
      ),
      body: eventProvider.events.isEmpty
          ? Center(
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
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: eventProvider.events.length,
              itemBuilder: (context, index) {
                final event = eventProvider.events[index];
                return EventCard(
                  event: event,
                  onTap: () => _viewEventDetail(event),
                  onEdit: () => _editEvent(event),
                  onDelete: () async {
                    eventProvider.removeEvent(event.id);
                    try {
                      await _eventRepository.deleteEvent(event.id);
                    } catch (e) {
                      debugPrint('Failed to delete persisted event: $e');
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEvent,
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
    );
  }
}
