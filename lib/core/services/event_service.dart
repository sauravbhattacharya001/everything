import 'package:flutter/foundation.dart';
import '../../data/repositories/event_repository.dart';
import '../../models/event_model.dart';
import '../../state/providers/event_provider.dart';

/// Callback for persistence failures that the UI layer can handle
/// (e.g. showing a snackbar or marking an event as unsaved).
typedef PersistenceFailureCallback = void Function(
    String action, String? eventId, Object error);

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
///   onPersistenceFailure: (action, id, error) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text('Failed to $action event')),
///     );
///   },
/// );
/// await service.addEvent(newEvent);
/// await service.deleteEvent(event.id);
/// ```
///
/// Persistence errors are retried up to [maxRetries] times with
/// exponential backoff. If all retries fail, the [onPersistenceFailure]
/// callback is invoked (if provided) so the UI can notify the user.
/// The in-memory state is always updated first so the UI stays responsive
/// even if the disk write fails.
class EventService {
  final EventProvider _provider;
  final EventRepository _repository;
  final PersistenceFailureCallback? onPersistenceFailure;
  final int maxRetries;

  /// Base delay for exponential backoff (doubles on each retry).
  static const Duration _baseDelay = Duration(milliseconds: 200);

  EventService({
    required EventProvider provider,
    EventRepository? repository,
    this.onPersistenceFailure,
    this.maxRetries = 3,
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
    await _persist(
        () => _repository.saveEvent(event.toJson()), 'add', event.id);
  }

  /// Updates an existing event in both the provider and SQLite.
  Future<void> updateEvent(EventModel event) async {
    _provider.updateEvent(event);
    await _persist(
        () => _repository.updateEvent(event.toJson()), 'update', event.id);
  }

  /// Removes an event by [id] from both the provider and SQLite.
  Future<void> deleteEvent(String id) async {
    _provider.removeEvent(id);
    await _persist(() => _repository.deleteEvent(id), 'delete', id);
  }

  /// Wraps a persistence operation with retry logic and error handling.
  ///
  /// Retries up to [maxRetries] times with exponential backoff
  /// (200ms, 400ms, 800ms) for transient disk I/O failures.
  /// The in-memory state is already updated before this is called,
  /// so the UI stays responsive regardless of disk I/O outcome.
  /// On final failure, invokes [onPersistenceFailure] if set.
  Future<void> _persist(
      Future<void> Function() operation, String action, String? eventId) async {
    Object? lastError;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        await operation();
        return; // Success
      } catch (e) {
        lastError = e;
        debugPrint(
            'EventService: Failed to $action event (attempt ${attempt + 1}/${maxRetries + 1}): $e');
        if (attempt < maxRetries) {
          await Future<void>.delayed(_baseDelay * (1 << attempt));
        }
      }
    }
    // All retries exhausted — notify the UI layer
    if (onPersistenceFailure != null && lastError != null) {
      onPersistenceFailure!(action, eventId, lastError!);
    }
  }
}
