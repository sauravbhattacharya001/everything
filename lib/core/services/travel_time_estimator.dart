/// Travel Time Estimator — computes estimated travel times between
/// events based on geographic distance and transport mode, and
/// detects scheduling conflicts where consecutive events don't leave
/// enough travel time.
///
/// Uses Haversine straight-line distance with a detour factor (1.3×
/// for driving, 1.4× for transit, 1.2× for cycling, 1.5× for walking)
/// to approximate real-world travel distance, then divides by average
/// speed per mode.
///
/// This is a local heuristic — no external API calls required.

import '../../models/event_location.dart';
import '../../models/event_model.dart';

/// Mode of transport for travel time estimation.
enum TravelMode {
  /// Car/automobile — 40 km/h average urban, detour 1.3×.
  driving,

  /// Public transit — 25 km/h average urban, detour 1.4×.
  transit,

  /// Bicycle — 15 km/h average, detour 1.2×.
  cycling,

  /// Walking — 5 km/h average, detour 1.5×.
  walking;

  /// Human-readable label.
  String get label {
    switch (this) {
      case TravelMode.driving:
        return 'Driving';
      case TravelMode.transit:
        return 'Transit';
      case TravelMode.cycling:
        return 'Cycling';
      case TravelMode.walking:
        return 'Walking';
    }
  }

  /// Average speed in km/h for this mode.
  double get averageSpeedKmh {
    switch (this) {
      case TravelMode.driving:
        return 40.0;
      case TravelMode.transit:
        return 25.0;
      case TravelMode.cycling:
        return 15.0;
      case TravelMode.walking:
        return 5.0;
    }
  }

  /// Detour factor: multiplied against straight-line distance to
  /// approximate real road/path distance.
  double get detourFactor {
    switch (this) {
      case TravelMode.driving:
        return 1.3;
      case TravelMode.transit:
        return 1.4;
      case TravelMode.cycling:
        return 1.2;
      case TravelMode.walking:
        return 1.5;
    }
  }
}

/// Result of a travel time estimation between two events.
class TravelEstimate {
  /// The event being traveled from.
  final EventModel from;

  /// The event being traveled to.
  final EventModel to;

  /// Straight-line (Haversine) distance in kilometers.
  final double straightLineDistanceKm;

  /// Estimated actual travel distance in kilometers (with detour factor).
  final double estimatedDistanceKm;

  /// The transport mode used for estimation.
  final TravelMode mode;

  /// Estimated travel time.
  final Duration estimatedTravelTime;

  /// Available gap between the end of [from] and the start of [to].
  final Duration availableGap;

  /// Buffer time after subtracting estimated travel from available gap.
  /// Negative values indicate insufficient travel time.
  Duration get buffer => availableGap - estimatedTravelTime;

  /// Whether the available gap is sufficient for the estimated travel.
  bool get isFeasible => !buffer.isNegative;

  /// How short the gap is if infeasible (positive Duration), or
  /// Duration.zero if feasible.
  Duration get shortfall => isFeasible ? Duration.zero : -buffer;

  /// Human-readable summary.
  String get summary {
    final distStr = estimatedDistanceKm < 1.0
        ? '${(estimatedDistanceKm * 1000).round()}m'
        : '${estimatedDistanceKm.toStringAsFixed(1)}km';
    final timeStr = _formatDuration(estimatedTravelTime);
    final gapStr = _formatDuration(availableGap);

    if (isFeasible) {
      return '$distStr via ${mode.label} (~$timeStr), gap $gapStr — OK';
    }
    final shortStr = _formatDuration(shortfall);
    return '$distStr via ${mode.label} (~$timeStr), gap $gapStr — '
        'SHORT by $shortStr';
  }

  const TravelEstimate({
    required this.from,
    required this.to,
    required this.straightLineDistanceKm,
    required this.estimatedDistanceKm,
    required this.mode,
    required this.estimatedTravelTime,
    required this.availableGap,
  });

  @override
  String toString() => 'TravelEstimate(${from.title} → ${to.title}: $summary)';
}

/// A travel conflict: two consecutive events where travel time exceeds
/// the available gap.
class TravelConflict {
  /// The travel estimate that is infeasible.
  final TravelEstimate estimate;

  /// Severity based on shortfall relative to travel time.
  final TravelConflictSeverity severity;

  const TravelConflict({
    required this.estimate,
    required this.severity,
  });

  /// Human-readable description of the conflict.
  String get description =>
      '${estimate.from.title} → ${estimate.to.title}: '
      '${severity.label} — need ~${_formatDuration(estimate.estimatedTravelTime)} '
      'but only ${_formatDuration(estimate.availableGap)} available '
      '(short by ${_formatDuration(estimate.shortfall)})';

  @override
  String toString() => 'TravelConflict($description)';
}

/// Severity of a travel conflict.
enum TravelConflictSeverity {
  /// Tight but possibly manageable (shortfall < 15 min).
  tight,

  /// Unlikely to make it (shortfall 15-60 min).
  unlikely,

  /// Impossible without canceling/rescheduling (shortfall > 60 min).
  impossible;

  String get label {
    switch (this) {
      case TravelConflictSeverity.tight:
        return 'Tight';
      case TravelConflictSeverity.unlikely:
        return 'Unlikely';
      case TravelConflictSeverity.impossible:
        return 'Impossible';
    }
  }

  /// Classifies severity from a [shortfall] duration.
  static TravelConflictSeverity fromShortfall(Duration shortfall) {
    if (shortfall.inMinutes < 15) return TravelConflictSeverity.tight;
    if (shortfall.inMinutes < 60) return TravelConflictSeverity.unlikely;
    return TravelConflictSeverity.impossible;
  }
}

/// Full analysis result for a day's travel schedule.
class TravelSchedule {
  /// All travel estimates for consecutive event pairs.
  final List<TravelEstimate> estimates;

  /// Events that had locations (used in analysis).
  final List<EventModel> eventsWithLocations;

  /// Events that lacked locations (skipped).
  final List<EventModel> eventsWithoutLocations;

  /// Travel conflicts detected.
  List<TravelConflict> get conflicts =>
      estimates.where((e) => !e.isFeasible).map((e) {
        return TravelConflict(
          estimate: e,
          severity: TravelConflictSeverity.fromShortfall(e.shortfall),
        );
      }).toList();

  /// Whether the schedule has any travel conflicts.
  bool get hasConflicts => estimates.any((e) => !e.isFeasible);

  /// Total estimated travel time for the day.
  Duration get totalTravelTime =>
      estimates.fold(Duration.zero, (sum, e) => sum + e.estimatedTravelTime);

  /// Total estimated travel distance in km.
  double get totalDistanceKm =>
      estimates.fold(0.0, (sum, e) => sum + e.estimatedDistanceKm);

  /// Number of trips (consecutive event pairs with locations).
  int get tripCount => estimates.length;

  /// Human-readable summary of the day's travel.
  String get summary {
    if (estimates.isEmpty) return 'No travel needed';
    final distStr = totalDistanceKm < 1.0
        ? '${(totalDistanceKm * 1000).round()}m'
        : '${totalDistanceKm.toStringAsFixed(1)}km';
    final timeStr = _formatDuration(totalTravelTime);
    final conflictCount = conflicts.length;
    final conflictStr =
        conflictCount == 0 ? 'no conflicts' : '$conflictCount conflict(s)';
    return '$tripCount trip(s), $distStr, ~$timeStr total — $conflictStr';
  }

  const TravelSchedule({
    required this.estimates,
    required this.eventsWithLocations,
    required this.eventsWithoutLocations,
  });

  @override
  String toString() => 'TravelSchedule($summary)';
}

/// Service that estimates travel times between events and detects
/// scheduling conflicts.
class TravelTimeEstimator {
  /// Default transport mode.
  final TravelMode defaultMode;

  /// Extra buffer time (e.g. parking, walking to entrance) added to
  /// each estimate.
  final Duration bufferTime;

  /// Per-event location assignments. Keys are event IDs.
  final Map<String, EventLocation> _locations;

  /// Creates a [TravelTimeEstimator].
  ///
  /// [defaultMode] sets the transport mode (default: driving).
  /// [bufferTime] adds a flat buffer per trip (default: 10 min).
  TravelTimeEstimator({
    this.defaultMode = TravelMode.driving,
    this.bufferTime = const Duration(minutes: 10),
    Map<String, EventLocation>? locations,
  }) : _locations = locations != null ? Map.of(locations) : {};

  // ── Location management ────────────────────────────────────────

  /// Associates a location with an event.
  void setLocation(String eventId, EventLocation location) {
    _locations[eventId] = location;
  }

  /// Removes a location association.
  void removeLocation(String eventId) {
    _locations.remove(eventId);
  }

  /// Gets the location for an event, or null.
  EventLocation? getLocation(String eventId) => _locations[eventId];

  /// Whether an event has a location set.
  bool hasLocation(String eventId) => _locations.containsKey(eventId);

  /// Returns all event IDs with locations.
  Set<String> get eventIdsWithLocations => Set.unmodifiable(_locations.keys.toSet());

  /// Total locations stored.
  int get locationCount => _locations.length;

  /// Clears all stored locations.
  void clearLocations() => _locations.clear();

  // ── Estimation ─────────────────────────────────────────────────

  /// Estimates travel time between two locations with the given mode.
  TravelEstimate estimateBetween(
    EventModel from,
    EventModel to, {
    required EventLocation fromLocation,
    required EventLocation toLocation,
    TravelMode? mode,
  }) {
    final m = mode ?? defaultMode;
    final straightLine = fromLocation.distanceTo(toLocation);
    final estimated = straightLine * m.detourFactor;
    final speedKmPerMin = m.averageSpeedKmh / 60.0;
    final travelMinutes =
        speedKmPerMin > 0 ? estimated / speedKmPerMin : 0.0;
    final travelDuration =
        Duration(seconds: (travelMinutes * 60).round()) + bufferTime;

    // Available gap: from end of 'from' to start of 'to'
    final fromEnd = from.endDate ?? from.date;
    final gap = to.date.difference(fromEnd);

    return TravelEstimate(
      from: from,
      to: to,
      straightLineDistanceKm: straightLine,
      estimatedDistanceKm: estimated,
      mode: m,
      estimatedTravelTime: travelDuration,
      availableGap: gap,
    );
  }

  /// Analyzes a list of events for travel feasibility.
  ///
  /// Events are sorted by start date, then consecutive pairs with
  /// locations are evaluated. Events without locations are skipped
  /// and tracked separately.
  TravelSchedule analyzeSchedule(
    List<EventModel> events, {
    TravelMode? mode,
  }) {
    if (events.isEmpty) {
      return const TravelSchedule(
        estimates: [],
        eventsWithLocations: [],
        eventsWithoutLocations: [],
      );
    }

    // Sort by start date
    final sorted = List.of(events)..sort((a, b) => a.date.compareTo(b.date));

    final withLoc = <EventModel>[];
    final withoutLoc = <EventModel>[];

    for (final event in sorted) {
      if (_locations.containsKey(event.id)) {
        withLoc.add(event);
      } else {
        withoutLoc.add(event);
      }
    }

    final estimates = <TravelEstimate>[];
    for (var i = 0; i < withLoc.length - 1; i++) {
      final from = withLoc[i];
      final to = withLoc[i + 1];
      final fromLoc = _locations[from.id]!;
      final toLoc = _locations[to.id]!;

      estimates.add(estimateBetween(
        from,
        to,
        fromLocation: fromLoc,
        toLocation: toLoc,
        mode: mode,
      ));
    }

    return TravelSchedule(
      estimates: estimates,
      eventsWithLocations: withLoc,
      eventsWithoutLocations: withoutLoc,
    );
  }

  /// Finds the best departure time for [to] given travel from [fromLocation].
  ///
  /// Returns the latest time you can leave [fromLocation] and still
  /// arrive at [toLocation] before [to.date].
  DateTime? latestDepartureTime(
    EventModel to, {
    required EventLocation fromLocation,
    required EventLocation toLocation,
    TravelMode? mode,
  }) {
    final m = mode ?? defaultMode;
    final straightLine = fromLocation.distanceTo(toLocation);
    final estimated = straightLine * m.detourFactor;
    final speedKmPerMin = m.averageSpeedKmh / 60.0;
    final travelMinutes =
        speedKmPerMin > 0 ? estimated / speedKmPerMin : 0.0;
    final travelDuration =
        Duration(seconds: (travelMinutes * 60).round()) + bufferTime;

    return to.date.subtract(travelDuration);
  }

  /// Suggests the fastest mode of transport to make a trip feasible.
  ///
  /// Returns the first mode (from fastest to slowest) that fits within
  /// the available gap, or null if none works.
  TravelMode? suggestFastestFeasibleMode(
    EventModel from,
    EventModel to, {
    required EventLocation fromLocation,
    required EventLocation toLocation,
  }) {
    const modes = [
      TravelMode.driving,
      TravelMode.cycling,
      TravelMode.transit,
      TravelMode.walking,
    ];

    for (final mode in modes) {
      final est = estimateBetween(
        from,
        to,
        fromLocation: fromLocation,
        toLocation: toLocation,
        mode: mode,
      );
      if (est.isFeasible) return mode;
    }
    return null;
  }

  /// Computes summary statistics across multiple days.
  Map<String, dynamic> getStats(List<TravelSchedule> schedules) {
    if (schedules.isEmpty) {
      return {
        'days': 0,
        'totalTrips': 0,
        'totalDistanceKm': 0.0,
        'totalTravelTime': Duration.zero,
        'totalConflicts': 0,
        'avgTripsPerDay': 0.0,
        'avgDistancePerDay': 0.0,
      };
    }

    var totalTrips = 0;
    var totalDist = 0.0;
    var totalTime = Duration.zero;
    var totalConflicts = 0;

    for (final s in schedules) {
      totalTrips += s.tripCount;
      totalDist += s.totalDistanceKm;
      totalTime += s.totalTravelTime;
      totalConflicts += s.conflicts.length;
    }

    return {
      'days': schedules.length,
      'totalTrips': totalTrips,
      'totalDistanceKm': totalDist,
      'totalTravelTime': totalTime,
      'totalConflicts': totalConflicts,
      'avgTripsPerDay': totalTrips / schedules.length,
      'avgDistancePerDay': totalDist / schedules.length,
    };
  }
}

/// Formats a Duration as a human-readable string.
String _formatDuration(Duration d) {
  if (d.isNegative) return '-${_formatDuration(-d)}';
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';
  return '${minutes}m';
}
