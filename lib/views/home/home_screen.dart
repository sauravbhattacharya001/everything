import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/event_repository.dart';
import '../../state/providers/event_provider.dart';
import '../../models/event_model.dart';
import '../widgets/event_card.dart';

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
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final event = EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Event',
      date: DateTime.now(),
    );
    eventProvider.addEvent(event);
    // Persist to local storage so events survive app restart
    try {
      await _eventRepository.saveEvent(event.toJson());
    } catch (e) {
      debugPrint('Failed to persist event: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: eventProvider.events.isEmpty
          ? const Center(
              child: Text(
                'No events yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: eventProvider.events.length,
              itemBuilder: (context, index) {
                return EventCard(
                  event: eventProvider.events[index],
                  onDelete: () async {
                    final event = eventProvider.events[index];
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
