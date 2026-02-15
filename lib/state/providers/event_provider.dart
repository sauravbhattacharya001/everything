import 'dart:collection';

import 'package:flutter/material.dart';
import '../../models/event_model.dart';

/// Manages the in-memory list of events and notifies the widget tree
/// when the list changes.
///
/// This is the primary state holder for events in the UI layer.
/// Events are exposed as an [UnmodifiableListView] to prevent external
/// mutation — all changes must go through the provided methods to ensure
/// listeners are properly notified.
///
/// Maintains a secondary [Map] index (`_eventById`) for O(1) lookups
/// by ID, used by [removeEvent], [updateEvent], and [getEventById].
/// This avoids O(n) linear scans on every mutation or detail-screen
/// lookup — significant when the event list grows large.
///
/// For persistence, pair this with [EventRepository] to save/load events
/// from SQLite. See [HomeScreen._loadPersistedEvents] for the loading
/// pattern.
///
/// Usage:
/// ```dart
/// final provider = context.read<EventProvider>();
/// provider.addEvent(EventModel(id: '1', title: 'Meeting', date: DateTime.now()));
/// ```
class EventProvider extends ChangeNotifier {
  final List<EventModel> _events = [];

  /// O(1) lookup index: event ID → list index.
  /// Rebuilt on bulk operations; maintained incrementally on add/remove/update.
  final Map<String, int> _idIndex = {};

  /// Rebuilds the ID → index map from scratch.
  /// Called after bulk operations (setEvents, clearEvents) where
  /// incremental maintenance would be more complex than a rebuild.
  void _rebuildIndex() {
    _idIndex.clear();
    for (var i = 0; i < _events.length; i++) {
      _idIndex[_events[i].id] = i;
    }
  }

  /// Returns an unmodifiable view of the events list.
  ///
  /// All mutations must go through [addEvent], [removeEvent],
  /// [setEvents], or [clearEvents] to ensure listeners are notified.
  UnmodifiableListView<EventModel> get events =>
      UnmodifiableListView(_events);

  /// The number of events currently held.
  int get eventCount => _events.length;

  /// Whether there are no events.
  bool get isEmpty => _events.isEmpty;

  /// Returns the event with the given [id], or `null` if not found.
  ///
  /// Uses the O(1) index map instead of scanning the list.
  EventModel? getEventById(String id) {
    final index = _idIndex[id];
    return index != null ? _events[index] : null;
  }

  /// Replaces the entire event list with [newEvents].
  ///
  /// Typically used when loading persisted events from [EventRepository]
  /// on app startup.
  void setEvents(List<EventModel> newEvents) {
    _events
      ..clear()
      ..addAll(newEvents);
    _rebuildIndex();
    notifyListeners();
  }

  /// Adds a single event to the end of the list.
  void addEvent(EventModel event) {
    _idIndex[event.id] = _events.length;
    _events.add(event);
    notifyListeners();
  }

  /// Removes the event with the matching [id] in O(1) index lookup.
  ///
  /// No-op if no event with that ID exists. Rebuilds the index after
  /// removal since list indices shift.
  void removeEvent(String id) {
    final index = _idIndex[id];
    if (index == null) return;
    _events.removeAt(index);
    _rebuildIndex();
    notifyListeners();
  }

  /// Replaces the event with the same [id] as [updatedEvent] in O(1).
  ///
  /// No-op if no event with that ID exists.
  void updateEvent(EventModel updatedEvent) {
    final index = _idIndex[updatedEvent.id];
    if (index == null) return;
    _events[index] = updatedEvent;
    notifyListeners();
  }

  /// Removes all events from the list.
  void clearEvents() {
    _events.clear();
    _idIndex.clear();
    notifyListeners();
  }
}
