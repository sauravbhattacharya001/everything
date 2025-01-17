import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/event_model.dart';

abstract class EventState {}

class EventInitial extends EventState {}

class EventLoaded extends EventState {
  final List<EventModel> events;

  EventLoaded(this.events);
}

class EventError extends EventState {
  final String message;

  EventError(this.message);
}

class EventBloc extends Cubit<EventState> {
  EventBloc() : super(EventInitial());

  void loadEvents(List<EventModel> events) {
    emit(EventLoaded(events));
  }

  void addEvent(EventModel event, List<EventModel> existingEvents) {
    final updatedEvents = [...existingEvents, event];
    emit(EventLoaded(updatedEvents));
  }

  void removeEvent(String id, List<EventModel> existingEvents) {
    final updatedEvents = existingEvents.where((e) => e.id != id).toList();
    emit(EventLoaded(updatedEvents));
  }
}
