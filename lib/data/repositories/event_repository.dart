import '../local_storage.dart';

/// Repository for persisting and retrieving events from local SQLite storage.
///
/// Acts as an abstraction over [LocalStorage], providing a domain-specific
/// API for event CRUD operations. This separation allows swapping the
/// underlying storage mechanism (e.g., to a remote API) without changing
/// the rest of the app.
///
/// Events are stored in the `events` table with columns: `id` (TEXT PK),
/// `title` (TEXT), `date` (TEXT, ISO-8601).
class EventRepository {
  /// Saves an event to local storage.
  ///
  /// Uses `ConflictAlgorithm.replace`, so calling this with an existing
  /// event ID will update (upsert) rather than fail.
  Future<void> saveEvent(Map<String, dynamic> event) async {
    await LocalStorage.insert('events', event);
  }

  /// Returns all persisted events as raw JSON maps.
  ///
  /// The caller is responsible for deserializing these into [EventModel]
  /// instances via `EventModel.fromJson`.
  Future<List<Map<String, dynamic>>> getEvents() async {
    return await LocalStorage.getAll('events');
  }

  /// Deletes the event with the given [id] from local storage.
  ///
  /// No-op if no event with that ID exists.
  Future<void> deleteEvent(String id) async {
    await LocalStorage.delete('events', id);
  }

  /// Updates an existing event in local storage.
  ///
  /// Uses insert with replace conflict algorithm, so this effectively
  /// upserts the event data.
  Future<void> updateEvent(Map<String, dynamic> event) async {
    await LocalStorage.insert('events', event);
  }
}
