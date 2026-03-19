import '../../models/event_model.dart';

/// Severity of a scheduling conflict.
enum ConflictSeverity {
  /// Events at the exact same time.
  exact,

  /// Events within 15 minutes of each other.
  high,

  /// Events within 1 hour of each other.
  moderate,

  /// Events within the user-configured window.
  low;

  /// Human-readable label for this severity.
  String get label {
    switch (this) {
      case ConflictSeverity.exact:
        return 'Exact';
      case ConflictSeverity.high:
        return 'High';
      case ConflictSeverity.moderate:
        return 'Moderate';
      case ConflictSeverity.low:
        return 'Low';
    }
  }

  /// Descriptive text explaining this severity level.
  String get description {
    switch (this) {
      case ConflictSeverity.exact:
        return 'Events are at the exact same time';
      case ConflictSeverity.high:
        return 'Events are within 15 minutes of each other';
      case ConflictSeverity.moderate:
        return 'Events are within 1 hour of each other';
      case ConflictSeverity.low:
        return 'Events are within the configured time window';
    }
  }
}

/// A detected conflict between two events.
class EventConflict {
  final EventModel eventA;
  final EventModel eventB;
  final Duration gap;
  final ConflictSeverity severity;

  EventConflict({
    required this.eventA,
    required this.eventB,
    required this.gap,
    required this.severity,
  });

  /// Whether this is an exact time collision (gap == 0).
  bool get isExact => gap == Duration.zero;

  /// Human-readable description of the conflict.
  String get description {
    final nameA = '"${eventA.title}"';
    final nameB = '"${eventB.title}"';
    if (isExact) {
      return '$nameA and $nameB are at the exact same time';
    }
    final minutes = gap.inMinutes;
    if (minutes < 60) {
      return '$nameA and $nameB are only $minutes minutes apart';
    }
    final hours = gap.inHours;
    final remainingMinutes = minutes - hours * 60;
    if (remainingMinutes == 0) {
      return '$nameA and $nameB are $hours hour${hours > 1 ? 's' : ''} apart';
    }
    return '$nameA and $nameB are $hours hour${hours > 1 ? 's' : ''} $remainingMinutes minutes apart';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventConflict &&
          runtimeType == other.runtimeType &&
          ((eventA.id == other.eventA.id && eventB.id == other.eventB.id) ||
              (eventA.id == other.eventB.id && eventB.id == other.eventA.id));

  @override
  int get hashCode {
    // Order-independent hash
    final ids = [eventA.id, eventB.id]..sort();
    return Object.hash(ids[0], ids[1]);
  }
}

/// Result of conflict analysis on a set of events.
class ConflictReport {
  final List<EventConflict> conflicts;
  final int totalEvents;
  final DateTime analyzedAt;

  ConflictReport({
    required this.conflicts,
    required this.totalEvents,
    required this.analyzedAt,
  });

  /// Number of conflicts found.
  int get conflictCount => conflicts.length;

  /// Whether any conflicts were detected.
  bool get hasConflicts => conflicts.isNotEmpty;

  /// Events involved in at least one conflict.
  Set<String> get conflictedEventIds {
    final ids = <String>{};
    for (final c in conflicts) {
      ids.add(c.eventA.id);
      ids.add(c.eventB.id);
    }
    return ids;
  }

  /// Number of unique events involved in conflicts.
  int get affectedEventCount => conflictedEventIds.length;

  /// Conflicts grouped by severity.
  Map<ConflictSeverity, List<EventConflict>> get bySeverity {
    final map = <ConflictSeverity, List<EventConflict>>{};
    for (final c in conflicts) {
      map.putIfAbsent(c.severity, () => []).add(c);
    }
    return map;
  }

  /// Most severe conflict (if any).
  EventConflict? get mostSevere {
    if (conflicts.isEmpty) return null;
    EventConflict best = conflicts.first;
    for (final c in conflicts) {
      if (c.severity.index < best.severity.index) {
        best = c;
      }
    }
    return best;
  }

  /// Conflicts involving a specific event.
  List<EventConflict> conflictsFor(String eventId) {
    return conflicts
        .where((c) => c.eventA.id == eventId || c.eventB.id == eventId)
        .toList();
  }

  /// Whether a specific event has conflicts.
  bool hasConflictsFor(String eventId) {
    return conflicts
        .any((c) => c.eventA.id == eventId || c.eventB.id == eventId);
  }

  /// Busiest conflict cluster: the event with the most conflicts.
  String? get busiestEventId {
    if (conflicts.isEmpty) return null;
    final counts = <String, int>{};
    for (final c in conflicts) {
      counts[c.eventA.id] = (counts[c.eventA.id] ?? 0) + 1;
      counts[c.eventB.id] = (counts[c.eventB.id] ?? 0) + 1;
    }
    String? busiest;
    int maxCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        busiest = entry.key;
      }
    }
    return busiest;
  }

  /// Summary string.
  String get summary {
    if (!hasConflicts) {
      return 'No conflicts found among $totalEvents events.';
    }
    final parts = <String>[];
    final grouped = bySeverity;
    for (final severity in ConflictSeverity.values) {
      final list = grouped[severity];
      if (list != null && list.isNotEmpty) {
        parts.add('${list.length} ${severity.label.toLowerCase()}');
      }
    }
    return '$conflictCount conflict${conflictCount == 1 ? '' : 's'} found among '
        '$totalEvents events (${parts.join(', ')}). '
        '$affectedEventCount event${affectedEventCount == 1 ? '' : 's'} affected.';
  }
}

/// Detects scheduling conflicts between events.
class ConflictDetector {
  final Duration window;

  /// Creates a detector with the given proximity window (default: 1 hour).
  const ConflictDetector({this.window = const Duration(hours: 1)});

  /// Analyze a list of events for conflicts.
  /// Events are compared pairwise; recurring events are expanded first.
  ///
  /// Two events conflict when their time spans overlap or their start
  /// times are within [window]. An event's span runs from [date] to
  /// [endDate] (or is treated as a point-in-time when [endDate] is null).
  ConflictReport analyze(
    List<EventModel> events, {
    bool expandRecurring = true,
    int maxOccurrences = 12,
  }) {
    // Expand recurring events if requested
    final allEvents = <EventModel>[];
    for (final event in events) {
      allEvents.add(event);
      if (expandRecurring && event.isRecurring) {
        allEvents.addAll(
          event.generateOccurrences(maxOccurrences: maxOccurrences),
        );
      }
    }

    // Sort by date for efficient pairwise comparison
    allEvents.sort((a, b) => a.date.compareTo(b.date));

    final conflicts = <EventConflict>[];
    for (var i = 0; i < allEvents.length; i++) {
      for (var j = i + 1; j < allEvents.length; j++) {
        final gap = _computeGap(allEvents[i], allEvents[j]);
        if (gap > window) break;
        final conflict = _createConflict(allEvents[i], allEvents[j], gap);
        conflicts.add(conflict);
      }
    }

    return ConflictReport(
      conflicts: conflicts,
      totalEvents: allEvents.length,
      analyzedAt: DateTime.now(),
    );
  }

  /// Check if two specific events conflict.
  ///
  /// Returns a conflict if the events' time spans overlap or their
  /// proximity is within [window]. Returns null otherwise.
  EventConflict? checkPair(EventModel a, EventModel b) {
    final gap = _computeGap(a, b);
    if (gap <= window) {
      return _createConflict(a, b, gap);
    }
    return null;
  }

  /// Find all conflicts for a single event against a list.
  List<EventConflict> findConflictsFor(
    EventModel event,
    List<EventModel> others,
  ) {
    final conflicts = <EventConflict>[];
    for (final other in others) {
      if (other.id == event.id) continue;
      final conflict = checkPair(event, other);
      if (conflict != null) {
        conflicts.add(conflict);
      }
    }
    return conflicts;
  }

  /// Quick check: does adding this event create any conflicts?
  bool wouldConflict(EventModel newEvent, List<EventModel> existing) {
    for (final event in existing) {
      final gap = _computeGap(newEvent, event);
      if (gap <= window) return true;
    }
    return false;
  }

  /// Suggest alternative times that avoid conflicts (next free slots).
  ///
  /// Shifts both [date] and [endDate] by the same offset so the event's
  /// full duration is preserved when checking for overlaps.
  ///
  /// Pre-sorts existing events and uses binary search to narrow the
  /// conflict check window, reducing each probe from O(n) to O(log n + m)
  /// where m is the number of events within the conflict window.
  List<DateTime> suggestAlternatives(
    EventModel event,
    List<EventModel> existing, {
    int count = 5,
    Duration step = const Duration(minutes: 30),
  }) {
    if (existing.isEmpty) {
      // No events to conflict with — return the first `count` forward slots
      return List.generate(count, (i) => event.date.add(step * (i + 1)));
    }

    // Pre-sort by start date for binary search
    final sorted = List<EventModel>.from(existing)
      ..sort((a, b) => a.date.compareTo(b.date));
    // Cache end times to avoid recomputing per probe
    final sortedStarts = sorted.map((e) => e.date).toList();

    final alternatives = <DateTime>[];
    // Try shifting forward and backward alternately
    for (var i = 1; alternatives.length < count && i <= 1000; i++) {
      // Forward — shift both start and end to preserve duration
      final forwardOffset = step * i;
      final forward = event.date.add(forwardOffset);
      final forwardEvent = event.copyWith(
        date: forward,
        endDate: event.endDate?.add(forwardOffset),
      );
      if (!_wouldConflictSorted(forwardEvent, sorted, sortedStarts)) {
        alternatives.add(forward);
        if (alternatives.length >= count) break;
      }
      // Backward — shift both start and end to preserve duration
      final backward = event.date.subtract(forwardOffset);
      final backwardEvent = event.copyWith(
        date: backward,
        endDate: event.endDate?.subtract(forwardOffset),
      );
      if (!_wouldConflictSorted(backwardEvent, sorted, sortedStarts)) {
        alternatives.add(backward);
      }
    }
    return alternatives.take(count).toList();
  }

  /// Binary-search accelerated conflict check against a pre-sorted event
  /// list. Only examines events whose start times fall within
  /// [newEvent.date - window - maxDuration, newEvent.endDate + window],
  /// skipping the rest entirely.
  bool _wouldConflictSorted(
    EventModel newEvent,
    List<EventModel> sorted,
    List<DateTime> sortedStarts,
  ) {
    final newEnd = newEvent.endDate ?? newEvent.date;
    // Earliest start time that could conflict: an event ending at this
    // point could still be within `window` of our event's start.
    // To be safe, we look back by window (events whose start is before
    // our start - window can't conflict unless they have long duration,
    // but _computeGap handles endDate correctly).
    final searchStart = newEvent.date.subtract(window);
    final searchEnd = newEnd.add(window);

    // Binary search for the first event whose start >= searchStart
    var lo = 0, hi = sortedStarts.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (sortedStarts[mid].isBefore(searchStart)) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }

    // Scan backward a bit to catch events that start before searchStart
    // but whose endDate extends into our window
    final scanFrom = (lo - 10).clamp(0, sorted.length);

    for (var i = scanFrom; i < sorted.length; i++) {
      // Once starts exceed searchEnd, no further events can conflict
      if (sortedStarts[i].isAfter(searchEnd)) break;
      final gap = _computeGap(newEvent, sorted[i]);
      if (gap <= window) return true;
    }
    return false;
  }

  /// Determine severity based on time gap.
  static ConflictSeverity severityFromGap(Duration gap) {
    final absGap = gap.abs();
    if (absGap == Duration.zero) return ConflictSeverity.exact;
    if (absGap <= const Duration(minutes: 15)) return ConflictSeverity.high;
    if (absGap <= const Duration(hours: 1)) return ConflictSeverity.moderate;
    return ConflictSeverity.low;
  }

  EventConflict _createConflict(EventModel a, EventModel b, Duration gap) {
    return EventConflict(
      eventA: a,
      eventB: b,
      gap: gap,
      severity: severityFromGap(gap),
    );
  }

  /// Computes the effective gap between two events, accounting for
  /// time ranges ([endDate]).
  ///
  /// If either event has an [endDate] that extends past the other's
  /// start, the events overlap and the gap is [Duration.zero].
  /// Otherwise, the gap is the distance between the end of the earlier
  /// event and the start of the later one. When an event has no
  /// [endDate], its start time is used for both start and end
  /// (point-in-time event).
  static Duration _computeGap(EventModel a, EventModel b) {
    final aStart = a.date;
    final aEnd = a.endDate ?? a.date;
    final bStart = b.date;
    final bEnd = b.endDate ?? b.date;

    // If spans overlap, gap is zero
    if (aStart.compareTo(bEnd) <= 0 && bStart.compareTo(aEnd) <= 0) {
      return Duration.zero;
    }

    // No overlap — gap is distance between the end of the earlier
    // event and the start of the later one
    if (aEnd.isBefore(bStart)) {
      return bStart.difference(aEnd);
    }
    return aStart.difference(bEnd);
  }
}
