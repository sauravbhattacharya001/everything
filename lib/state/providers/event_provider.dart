import 'dart:collection';

import 'package:flutter/material.dart';
import '../../models/event_model.dart';

class EventProvider extends ChangeNotifier {
  final List<EventModel> _events = [];

  /// Returns an unmodifiable view of the events list.
  /// All mutations must go through [addEvent], [removeEvent],
  /// [setEvents], or [clearEvents] to ensure listeners are notified.
  UnmodifiableListView<EventModel> get events =>
      UnmodifiableListView(_events);

  void setEvents(List<EventModel> newEvents) {
    _events
      ..clear()
      ..addAll(newEvents);
    notifyListeners();
  }

  void addEvent(EventModel event) {
    _events.add(event);
    notifyListeners();
  }

  void removeEvent(String id) {
    _events.removeWhere((event) => event.id == id);
    notifyListeners();
  }

  void clearEvents() {
    _events.clear();
    notifyListeners();
  }
}
