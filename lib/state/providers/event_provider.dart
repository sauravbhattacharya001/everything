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

  /// Replaces the entire event list with [newEvents].
  ///
  /// Typically used when loading persisted events from [EventRepository]
  /// on app startup.
  void setEvents(List<EventModel> newEvents) {
    _events
      ..clear()
      ..addAll(newEvents);
    notifyListeners();
  }

  /// Adds a single event to the end of the list.
  void addEvent(EventModel event) {
    _events.add(event);
    notifyListeners();
  }

  /// Removes the event with the matching [id].
  ///
  /// No-op if no event with that ID exists.
  void removeEvent(String id) {
    _events.removeWhere((event) => event.id == id);
    notifyListeners();
  }

  /// Replaces the event with the same [id] as [updatedEvent].
  ///
  /// No-op if no event with that ID exists.
  void updateEvent(EventModel updatedEvent) {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      notifyListeners();
    }
  }

  /// Removes all events from the list.
  void clearEvents() {
    _events.clear();
    notifyListeners();
  }
}
