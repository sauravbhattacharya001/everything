import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/event_model.dart';

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

/// Base class for all event-related states.
abstract class EventState {}

/// Initial state before any events have been loaded.
class EventInitial extends EventState {}

/// State containing a loaded list of events.
///
/// Emitted by [EventBloc.loadEvents], [EventBloc.addEvent], and
/// [EventBloc.removeEvent]. The list may be empty (e.g., after removing
/// the last event).
class EventLoaded extends EventState {
  /// The current list of events.
  final List<EventModel> events;

  EventLoaded(this.events);
}

/// Error state for event-related failures.
///
/// Reserved for future use — e.g., when loading events from a remote API.
class EventError extends EventState {
  /// Human-readable error description.
  final String message;

  EventError(this.message);
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

/// Manages event state using the BLoC pattern via [Cubit].
///
/// This provides an alternative to [EventProvider] for state management.
/// Both can coexist — use whichever pattern fits the widget's needs.
///
/// The bloc starts in [EventInitial] and transitions to [EventLoaded]
/// once [loadEvents] is called. [addEvent] and [removeEvent] only operate
/// on the [EventLoaded] state; they are no-ops in [EventInitial].
///
/// Example:
/// ```dart
/// final bloc = EventBloc();
/// bloc.loadEvents([event1, event2]);
/// bloc.addEvent(event3);
/// bloc.removeEvent('1');
/// ```
class EventBloc extends Cubit<EventState> {
  EventBloc() : super(EventInitial());

  /// Replaces the current state with [EventLoaded] containing [events].
  ///
  /// Can be called from any state.
  void loadEvents(List<EventModel> events) {
    emit(EventLoaded(events));
  }

  /// Appends [event] to the current list.
  ///
  /// Only operates when the current state is [EventLoaded].
  /// No-op in [EventInitial] or [EventError].
  void addEvent(EventModel event) {
    final current = state;
    if (current is EventLoaded) {
      emit(EventLoaded([...current.events, event]));
    }
  }

  /// Removes the event with the given [id] from the list.
  ///
  /// Only operates when the current state is [EventLoaded].
  /// No-op if the ID doesn't exist or the state isn't [EventLoaded].
  void removeEvent(String id) {
    final current = state;
    if (current is EventLoaded) {
      final updated = current.events.where((e) => e.id != id).toList();
      emit(EventLoaded(updated));
    }
  }
}
