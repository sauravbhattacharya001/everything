import 'package:flutter/material.dart';
import '../../models/event_model.dart';

class EventProvider extends ChangeNotifier {
  List<EventModel> _events = [];

  List<EventModel> get events => _events;

  void setEvents(List<EventModel> newEvents) {
    _events = newEvents;
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
    _events = [];
    notifyListeners();
  }
}
