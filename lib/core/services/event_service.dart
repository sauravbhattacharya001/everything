import 'package:flutter/foundation.dart';
import '../../data/repositories/event_repository.dart';
import '../../models/event_model.dart';
import '../../state/providers/event_provider.dart';

/// Coordinates event persistence and in-memory state management.
///
/// This service eliminates the duplicated "update provider + persist to
/// repository" pattern that was scattered across [HomeScreen] and
/// [EventDetailScreen]. All event mutations now go through a single
/// point, ensuring consistency between the SQLite store and the
/// [EventProvider] state.
///
/// Usage:
/// ```dart
/// final service = EventService(
///   provider: context.read<EventProvider>(),
/// );
/// await service.addEvent(newEvent);
/// await service.deleteEvent(event.id);
/// ```
///
/// Persistence errors are caught and logged — they don't crash the UI.
/// The in-memory state is always updated first so the UI stays responsive
/// even if the disk write fails.
class EventService {
  final EventProvider _provider;
  final EventRepository _repository;

  EventService({
    required EventProvider provider,
    EventRepository? repository,
  })  : _provider = provider,
        _repository = repository ?? EventRepository();

  /// Loads persisted events from SQLite into the provider.
  ///
  /// Only populates the provider if it's currently empty, to avoid
  /// overwriting events added during the current session.
  Future<void> loadEvents() async {
    try {
      final rows = await _repository.getEvents();
      final events = rows.map((row) => EventModel.fromJson(row)).toList();
      if (_provider.isEmpty) {
        _provider.setEvents(events);
      }
    } catch (e) {
      debugPrint('EventService: Failed to load persisted events: $e');
    }
  }

  /// Adds an event to both the in-memory provider and SQLite.
  Future<void> addEvent(EventModel event) async {
    _provider.addEvent(event);
    await _persist(() => _repository.saveEvent(event.toJson()), 'add');
  }

  /// Updates an existing event in both the provider and SQLite.
  Future<void> updateEvent(EventModel event) async {
    _provider.updateEvent(event);
    await _persist(() => _repository.updateEvent(event.toJson()), 'update');
  }

  /// Removes an event by [id] from both the provider and SQLite.
  Future<void> deleteEvent(String id) async {
    _provider.removeEvent(id);
    await _persist(() => _repository.deleteEvent(id), 'delete');
  }

  /// Wraps a persistence operation with error handling.
  ///
  /// The in-memory state is already updated before this is called,
  /// so the UI stays responsive regardless of disk I/O outcome.
  Future<void> _persist(Future<void> Function() operation, String action) async {
    try {
      await operation();
    } catch (e) {
      debugPrint('EventService: Failed to $action event in storage: $e');
    }
  }
}
