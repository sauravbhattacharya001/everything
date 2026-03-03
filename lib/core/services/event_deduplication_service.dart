import '../../models/event_model.dart';
import '../utils/date_utils.dart';
import 'dart:math' as math;

/// A pair of events suspected to be duplicates, with a similarity score
/// and a classification of why they were flagged.
class DuplicateMatch {
  /// The first event in the pair (typically the earlier one).
  final EventModel eventA;

  /// The second event in the pair.
  final EventModel eventB;

  /// Overall similarity score from 0.0 (unrelated) to 1.0 (identical).
  final double similarity;

  /// What kind of duplicate this appears to be.
  final DuplicateKind kind;

  /// Human-readable explanation of why these were flagged.
  final String reason;

  /// Suggested action to resolve the duplicate.
  final MergeAction suggestedAction;

  const DuplicateMatch({
    required this.eventA,
    required this.eventB,
    required this.similarity,
    required this.kind,
    required this.reason,
    required this.suggestedAction,
  });

  /// Whether this is a high-confidence duplicate (similarity >= 0.8).
  bool get isHighConfidence => similarity >= 0.8;

  /// Whether this is a medium-confidence duplicate (0.6 <= similarity < 0.8).
  bool get isMediumConfidence => similarity >= 0.6 && similarity < 0.8;

  @override
  String toString() =>
      'DuplicateMatch(${kind.label}: "${eventA.title}" ↔ "${eventB.title}", '
      'similarity=${(similarity * 100).toStringAsFixed(0)}%)';
}

/// Classification of why two events are considered duplicates.
enum DuplicateKind {
  /// Exact same title at the same or overlapping time.
  exactDuplicate,

  /// Very similar titles (typo/case variants) at nearby times.
  nearDuplicate,

  /// A manually-created event that overlaps with a generated recurrence.
  recurrenceOverlap,

  /// Same title at different times on the same day.
  sameDaySameTitle,

  /// Events with identical description and location at nearby times.
  contentDuplicate;

  /// Display label for the kind.
  String get label {
    switch (this) {
      case DuplicateKind.exactDuplicate:
        return 'Exact duplicate';
      case DuplicateKind.nearDuplicate:
        return 'Near duplicate';
      case DuplicateKind.recurrenceOverlap:
        return 'Recurrence overlap';
      case DuplicateKind.sameDaySameTitle:
        return 'Same-day repeat';
      case DuplicateKind.contentDuplicate:
        return 'Content duplicate';
    }
  }

  /// Icon suggestion for UI display.
  String get emoji {
    switch (this) {
      case DuplicateKind.exactDuplicate:
        return '🔴';
      case DuplicateKind.nearDuplicate:
        return '🟡';
      case DuplicateKind.recurrenceOverlap:
        return '🔁';
      case DuplicateKind.sameDaySameTitle:
        return '📅';
      case DuplicateKind.contentDuplicate:
        return '📝';
    }
  }
}

/// Suggested action for resolving a duplicate pair.
enum MergeAction {
  /// Keep the first event, delete the second.
  keepFirst,

  /// Keep the second event, delete the first.
  keepSecond,

  /// Merge both events (combine checklists, descriptions, etc.).
  merge,

  /// Mark as reviewed / not a duplicate.
  ignore;

  /// Display label for the action.
  String get label {
    switch (this) {
      case MergeAction.keepFirst:
        return 'Keep first';
      case MergeAction.keepSecond:
        return 'Keep second';
      case MergeAction.merge:
        return 'Merge events';
      case MergeAction.ignore:
        return 'Not a duplicate';
    }
  }
}

/// Configuration for how aggressive duplicate detection should be.
class DeduplicationConfig {
  /// Minimum title similarity (0.0 - 1.0) to flag near-duplicates.
  /// Default 0.7 catches common typos and abbreviations.
  final double titleSimilarityThreshold;

  /// Maximum time gap in minutes between events to consider them
  /// potential duplicates. Default 120 (2 hours).
  final int maxTimeGapMinutes;

  /// Whether to detect recurrence overlaps (manual events that
  /// duplicate a recurring event's occurrence).
  final bool detectRecurrenceOverlaps;

  /// Whether to detect same-day same-title events as duplicates.
  final bool detectSameDayRepeats;

  /// Whether to detect content duplicates (same description+location
  /// even with different titles).
  final bool detectContentDuplicates;

  /// Minimum overall similarity score to include in results.
  final double minimumOverallScore;

  const DeduplicationConfig({
    this.titleSimilarityThreshold = 0.7,
    this.maxTimeGapMinutes = 120,
    this.detectRecurrenceOverlaps = true,
    this.detectSameDayRepeats = true,
    this.detectContentDuplicates = true,
    this.minimumOverallScore = 0.5,
  });

  /// Lenient config — catches more potential duplicates.
  static const lenient = DeduplicationConfig(
    titleSimilarityThreshold: 0.5,
    maxTimeGapMinutes: 240,
    minimumOverallScore: 0.4,
  );

  /// Strict config — only flags high-confidence duplicates.
  static const strict = DeduplicationConfig(
    titleSimilarityThreshold: 0.85,
    maxTimeGapMinutes: 60,
    minimumOverallScore: 0.75,
  );
}

/// Summary statistics from a deduplication scan.
class DeduplicationReport {
  /// Total events analyzed.
  final int totalEvents;

  /// Number of duplicate pairs found.
  final int duplicateCount;

  /// All duplicate matches, sorted by similarity (highest first).
  final List<DuplicateMatch> matches;

  /// Breakdown by duplicate kind.
  final Map<DuplicateKind, int> kindBreakdown;

  /// Estimated time savings from resolving duplicates (in minutes).
  /// Based on average event duration of duplicate pairs.
  final double estimatedTimeSavingsMinutes;

  /// Events that appear in multiple duplicate pairs (potential merge hubs).
  final List<String> frequentDuplicateIds;

  const DeduplicationReport({
    required this.totalEvents,
    required this.duplicateCount,
    required this.matches,
    required this.kindBreakdown,
    required this.estimatedTimeSavingsMinutes,
    required this.frequentDuplicateIds,
  });

  /// Whether any duplicates were found.
  bool get hasDuplicates => duplicateCount > 0;

  /// Number of high-confidence duplicates.
  int get highConfidenceCount =>
      matches.where((m) => m.isHighConfidence).length;

  /// Estimated hours saved by deduplication.
  double get estimatedTimeSavingsHours =>
      estimatedTimeSavingsMinutes / 60.0;

  /// Human-readable summary of the scan.
  String get summary {
    if (!hasDuplicates) {
      return '✅ No duplicates found among $totalEvents events.';
    }
    final buffer = StringBuffer();
    buffer.writeln(
        '⚠️ Found $duplicateCount duplicate pair${duplicateCount == 1 ? '' : 's'} '
        'among $totalEvents events.');
    if (highConfidenceCount > 0) {
      buffer.writeln(
          '🔴 $highConfidenceCount high-confidence match${highConfidenceCount == 1 ? '' : 'es'}.');
    }
    for (final entry in kindBreakdown.entries) {
      if (entry.value > 0) {
        buffer.writeln('  ${entry.key.emoji} ${entry.key.label}: ${entry.value}');
      }
    }
    if (estimatedTimeSavingsMinutes > 0) {
      buffer.writeln(
          '⏱️ Estimated ${estimatedTimeSavingsHours.toStringAsFixed(1)}h '
          'saved by resolving duplicates.');
    }
    return buffer.toString().trimRight();
  }

  @override
  String toString() => 'DeduplicationReport($duplicateCount duplicates '
      'from $totalEvents events)';
}

/// Detects likely duplicate or near-duplicate events and suggests
/// resolution actions.
///
/// The service analyzes events using multiple signals:
/// - **Title similarity** via Levenshtein distance (catches typos)
/// - **Time proximity** (events at nearby times are more suspect)
/// - **Content matching** (same description/location)
/// - **Recurrence overlap** (manual events duplicating auto-generated ones)
/// - **Same-day repeats** (identical titles on the same day)
///
/// Usage:
/// ```dart
/// final service = EventDeduplicationService();
/// final report = service.scan(events);
/// for (final match in report.matches) {
///   print('${match.kind.label}: ${match.eventA.title} ↔ ${match.eventB.title}');
///   print('  Similarity: ${(match.similarity * 100).toStringAsFixed(0)}%');
///   print('  Suggested: ${match.suggestedAction.label}');
/// }
/// ```
class EventDeduplicationService {
  /// The configuration for this scan.
  final DeduplicationConfig config;

  /// Creates a deduplication service with the given config.
  ///
  /// Uses [DeduplicationConfig] defaults if not specified.
  EventDeduplicationService({
    this.config = const DeduplicationConfig(),
  });

  /// Scans a list of events for duplicates.
  ///
  /// Returns a [DeduplicationReport] with all detected duplicate pairs,
  /// sorted by similarity (highest first). The scan is O(n²) in the
  /// number of events within each time window.
  DeduplicationReport scan(List<EventModel> events) {
    if (events.isEmpty) {
      return const DeduplicationReport(
        totalEvents: 0,
        duplicateCount: 0,
        matches: [],
        kindBreakdown: {},
        estimatedTimeSavingsMinutes: 0,
        frequentDuplicateIds: [],
      );
    }

    // Sort by date for efficient windowed comparison
    final sorted = List<EventModel>.from(events)
      ..sort((a, b) => a.date.compareTo(b.date));

    final matches = <DuplicateMatch>[];
    final seen = <String>{}; // Track pair IDs to avoid symmetric duplicates

    for (int i = 0; i < sorted.length; i++) {
      for (int j = i + 1; j < sorted.length; j++) {
        final a = sorted[i];
        final b = sorted[j];

        // Time window check — skip if too far apart
        final gapMinutes =
            b.date.difference(a.date).inMinutes.abs();
        if (gapMinutes > config.maxTimeGapMinutes &&
            !AppDateUtils.isSameDay(a.date, b.date)) {
          // If events are sorted by date and we're past the window,
          // we can skip remaining comparisons for this i (they'll be
          // even further away) — BUT same-day events may be far apart
          // in minutes (e.g., 9am vs 5pm = 480 min) so we only break
          // if also not same day.
          break;
        }

        // Skip self-referencing pairs
        if (a.id == b.id) continue;

        // Dedup pair tracking
        final pairKey = _pairKey(a.id, b.id);
        if (seen.contains(pairKey)) continue;

        final match = _compareEvents(a, b, gapMinutes);
        if (match != null && match.similarity >= config.minimumOverallScore) {
          matches.add(match);
          seen.add(pairKey);
        }
      }
    }

    // Sort by similarity descending
    matches.sort((a, b) => b.similarity.compareTo(a.similarity));

    // Build kind breakdown
    final kindBreakdown = <DuplicateKind, int>{};
    for (final kind in DuplicateKind.values) {
      final count = matches.where((m) => m.kind == kind).length;
      if (count > 0) kindBreakdown[kind] = count;
    }

    // Find frequent duplicate IDs
    final idCounts = <String, int>{};
    for (final match in matches) {
      idCounts[match.eventA.id] = (idCounts[match.eventA.id] ?? 0) + 1;
      idCounts[match.eventB.id] = (idCounts[match.eventB.id] ?? 0) + 1;
    }
    final frequentIds = idCounts.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => (idCounts[b] ?? 0).compareTo(idCounts[a] ?? 0));

    // Estimate time savings
    double timeSavings = 0;
    for (final match in matches) {
      final durA = match.eventA.duration?.inMinutes ?? 30;
      final durB = match.eventB.duration?.inMinutes ?? 30;
      timeSavings += math.min(durA, durB);
    }

    return DeduplicationReport(
      totalEvents: events.length,
      duplicateCount: matches.length,
      matches: matches,
      kindBreakdown: kindBreakdown,
      estimatedTimeSavingsMinutes: timeSavings,
      frequentDuplicateIds: frequentIds,
    );
  }

  /// Scans and returns only high-confidence duplicates.
  List<DuplicateMatch> scanHighConfidence(List<EventModel> events) {
    return scan(events).matches.where((m) => m.isHighConfidence).toList();
  }

  /// Checks if two specific events are likely duplicates.
  ///
  /// Returns a [DuplicateMatch] if they are, or null if not.
  DuplicateMatch? checkPair(EventModel a, EventModel b) {
    final gapMinutes = b.date.difference(a.date).inMinutes.abs();
    return _compareEvents(a, b, gapMinutes);
  }

  /// Finds all events that are duplicates of a given event.
  List<DuplicateMatch> findDuplicatesOf(
    EventModel target,
    List<EventModel> allEvents,
  ) {
    final matches = <DuplicateMatch>[];
    for (final other in allEvents) {
      if (other.id == target.id) continue;
      final gapMinutes =
          other.date.difference(target.date).inMinutes.abs();
      final match = _compareEvents(target, other, gapMinutes);
      if (match != null && match.similarity >= config.minimumOverallScore) {
        matches.add(match);
      }
    }
    matches.sort((a, b) => b.similarity.compareTo(a.similarity));
    return matches;
  }

  // ─── Internal comparison logic ────────────────────────────────

  /// Compares two events and returns a [DuplicateMatch] if they're
  /// suspected duplicates, or null if they're not.
  DuplicateMatch? _compareEvents(
    EventModel a,
    EventModel b,
    int gapMinutes,
  ) {
    final titleSim = _titleSimilarity(a.title, b.title);
    final timeSim = _timeSimilarity(gapMinutes);
    final contentSim = _contentSimilarity(a, b);
    final sameDay = AppDateUtils.isSameDay(a.date, b.date);

    // ── Exact duplicate: identical title + overlapping time ──
    if (titleSim >= 0.95 && _eventsOverlap(a, b)) {
      return DuplicateMatch(
        eventA: a,
        eventB: b,
        similarity: 0.95 + (contentSim * 0.05),
        kind: DuplicateKind.exactDuplicate,
        reason: 'Identical title "${a.title}" with overlapping time',
        suggestedAction: _suggestAction(a, b),
      );
    }

    // ── Recurrence overlap ──
    if (config.detectRecurrenceOverlaps) {
      final recurMatch = _checkRecurrenceOverlap(a, b, titleSim);
      if (recurMatch != null) return recurMatch;
    }

    // ── Same-day same-title ──
    if (config.detectSameDayRepeats && sameDay && titleSim >= 0.95) {
      return DuplicateMatch(
        eventA: a,
        eventB: b,
        similarity: 0.85 + (timeSim * 0.15),
        kind: DuplicateKind.sameDaySameTitle,
        reason: 'Same title "${a.title}" appears twice on '
            '${_formatDate(a.date)}',
        suggestedAction: MergeAction.merge,
      );
    }

    // ── Near duplicate: similar titles + close in time ──
    if (titleSim >= config.titleSimilarityThreshold &&
        gapMinutes <= config.maxTimeGapMinutes) {
      final overall = (titleSim * 0.5) + (timeSim * 0.3) + (contentSim * 0.2);
      if (overall >= config.minimumOverallScore) {
        return DuplicateMatch(
          eventA: a,
          eventB: b,
          similarity: overall,
          kind: DuplicateKind.nearDuplicate,
          reason: 'Similar titles ("${a.title}" ↔ "${b.title}") '
              '${gapMinutes}min apart',
          suggestedAction: _suggestAction(a, b),
        );
      }
    }

    // ── Content duplicate: different titles but same details ──
    if (config.detectContentDuplicates &&
        contentSim >= 0.8 &&
        gapMinutes <= config.maxTimeGapMinutes) {
      final overall = (contentSim * 0.5) + (timeSim * 0.3) + (titleSim * 0.2);
      if (overall >= config.minimumOverallScore) {
        return DuplicateMatch(
          eventA: a,
          eventB: b,
          similarity: overall,
          kind: DuplicateKind.contentDuplicate,
          reason: 'Same content/location with different titles',
          suggestedAction: MergeAction.merge,
        );
      }
    }

    return null;
  }

  /// Checks if one event is a manual duplicate of a recurring event's
  /// generated occurrence.
  DuplicateMatch? _checkRecurrenceOverlap(
    EventModel a,
    EventModel b,
    double titleSim,
  ) {
    // One must be recurring, the other not
    final EventModel recurring;
    final EventModel manual;
    if (a.recurrence != null && b.recurrence == null) {
      recurring = a;
      manual = b;
    } else if (b.recurrence != null && a.recurrence == null) {
      recurring = b;
      manual = a;
    } else {
      return null;
    }

    // Titles must be similar
    if (titleSim < config.titleSimilarityThreshold) return null;

    // Manual event must be on a day the recurring event would fire
    if (AppDateUtils.isSameDay(manual.date, recurring.date) ||
        _isRecurrenceDay(manual.date, recurring)) {
      final timeDiff =
          (manual.date.hour * 60 + manual.date.minute) -
          (recurring.date.hour * 60 + recurring.date.minute);
      if (timeDiff.abs() <= config.maxTimeGapMinutes) {
        return DuplicateMatch(
          eventA: recurring,
          eventB: manual,
          similarity: 0.90 + (titleSim * 0.10),
          kind: DuplicateKind.recurrenceOverlap,
          reason: '"${manual.title}" duplicates recurring '
              '"${recurring.title}" on ${_formatDate(manual.date)}',
          suggestedAction: MergeAction.keepFirst,
        );
      }
    }
    return null;
  }

  /// Rough check: would a recurring event fire on the given date?
  bool _isRecurrenceDay(DateTime date, EventModel recurring) {
    if (recurring.recurrence == null) return false;
    // Generate occurrences for a window around the date
    final windowStart = date.subtract(const Duration(days: 1));
    final windowEnd = date.add(const Duration(days: 1));
    final occurrences = recurring.generateOccurrences(windowStart, windowEnd);
    return occurrences.any((occ) => AppDateUtils.isSameDay(occ.date, date));
  }

  // ─── Similarity functions ────────────────────────────────────

  /// Title similarity using normalized Levenshtein distance.
  ///
  /// Case-insensitive, trims whitespace. Returns 1.0 for identical
  /// titles, 0.0 for completely different ones.
  double _titleSimilarity(String a, String b) {
    final na = a.trim().toLowerCase();
    final nb = b.trim().toLowerCase();
    if (na == nb) return 1.0;
    if (na.isEmpty || nb.isEmpty) return 0.0;

    final distance = _levenshteinDistance(na, nb);
    final maxLen = math.max(na.length, nb.length);
    return 1.0 - (distance / maxLen);
  }

  /// Levenshtein edit distance between two strings.
  int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    // Use two-row optimization for space efficiency
    var prev = List<int>.generate(b.length + 1, (i) => i);
    var curr = List<int>.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          prev[j] + 1,       // deletion
          curr[j - 1] + 1,   // insertion
          prev[j - 1] + cost, // substitution
        ].reduce(math.min);
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    return prev[b.length];
  }

  /// Time proximity score: 1.0 for overlapping/same time, decaying
  /// toward 0.0 as the gap increases.
  double _timeSimilarity(int gapMinutes) {
    if (gapMinutes <= 0) return 1.0;
    if (gapMinutes >= config.maxTimeGapMinutes) return 0.0;
    // Exponential decay
    return math.exp(-gapMinutes / (config.maxTimeGapMinutes / 3.0));
  }

  /// Token-based Jaccard similarity for longer text.
  ///
  /// More accurate than Levenshtein for strings longer than ~50 chars,
  /// and runs in O(n) time instead of O(n*m).
  double _tokenSimilarity(String a, String b) {
    final tokensA = a.trim().toLowerCase().split(RegExp(r'\s+')).toSet();
    final tokensB = b.trim().toLowerCase().split(RegExp(r'\s+')).toSet();
    if (tokensA.isEmpty && tokensB.isEmpty) return 1.0;
    if (tokensA.isEmpty || tokensB.isEmpty) return 0.0;
    final intersection = tokensA.intersection(tokensB).length;
    final union = tokensA.union(tokensB).length;
    return union > 0 ? intersection / union : 0.0;
  }

  /// Text similarity that picks the right algorithm based on length.
  ///
  /// Short text (≤50 chars): Levenshtein (good for typos).
  /// Longer text: Jaccard token overlap (O(n), handles additions/edits).
  double _textSimilarity(String a, String b) {
    if (a.length <= 50 && b.length <= 50) {
      return _titleSimilarity(a, b);
    }
    return _tokenSimilarity(a, b);
  }

  /// Content similarity based on description and location.
  double _contentSimilarity(EventModel a, EventModel b) {
    double score = 0.0;
    int factors = 0;

    // Description similarity — use token-based for long descriptions
    if (a.description.isNotEmpty && b.description.isNotEmpty) {
      score += _textSimilarity(a.description, b.description);
      factors++;
    } else if (a.description.isEmpty && b.description.isEmpty) {
      // Both empty — neutral, don't count
    } else {
      // One empty, one not — slight penalty
      factors++;
    }

    // Location similarity — use token-based for long locations
    if (a.location.isNotEmpty && b.location.isNotEmpty) {
      score += _textSimilarity(a.location, b.location);
      factors++;
    } else if (a.location.isEmpty && b.location.isEmpty) {
      // Both empty — neutral
    } else {
      factors++;
    }

    // Priority match
    if (a.priority == b.priority) {
      score += 0.5;
      factors++;
    } else {
      factors++;
    }

    // Tag overlap
    if (a.tags.isNotEmpty && b.tags.isNotEmpty) {
      final tagsA = a.tags.map((t) => t.name.toLowerCase()).toSet();
      final tagsB = b.tags.map((t) => t.name.toLowerCase()).toSet();
      final intersection = tagsA.intersection(tagsB).length;
      final union = tagsA.union(tagsB).length;
      score += union > 0 ? intersection / union : 0.0;
      factors++;
    }

    return factors > 0 ? score / factors : 0.0;
  }

  /// Do two events overlap in time?
  bool _eventsOverlap(EventModel a, EventModel b) {
    final aStart = a.date;
    final aEnd = a.endDate ?? a.date.add(const Duration(minutes: 30));
    final bStart = b.date;
    final bEnd = b.endDate ?? b.date.add(const Duration(minutes: 30));
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  /// Suggest which event to keep based on richness of data.
  MergeAction _suggestAction(EventModel a, EventModel b) {
    int scoreA = 0;
    int scoreB = 0;

    // Prefer the one with more description
    if (a.description.length > b.description.length) {
      scoreA++;
    } else if (b.description.length > a.description.length) {
      scoreB++;
    }

    // Prefer the one with checklist items
    if (a.checklist.items.isNotEmpty && b.checklist.items.isEmpty) {
      scoreA++;
    } else if (b.checklist.items.isNotEmpty && a.checklist.items.isEmpty) {
      scoreB++;
    }

    // Prefer the one with tags
    if (a.tags.isNotEmpty && b.tags.isEmpty) {
      scoreA++;
    } else if (b.tags.isNotEmpty && a.tags.isEmpty) {
      scoreB++;
    }

    // Prefer the one with location
    if (a.location.isNotEmpty && b.location.isEmpty) {
      scoreA++;
    } else if (b.location.isNotEmpty && a.location.isEmpty) {
      scoreB++;
    }

    // Prefer the one with attachments
    if (a.attachments.items.isNotEmpty && b.attachments.items.isEmpty) {
      scoreA++;
    } else if (b.attachments.items.isNotEmpty && a.attachments.items.isEmpty) {
      scoreB++;
    }

    if (scoreA > scoreB) return MergeAction.keepFirst;
    if (scoreB > scoreA) return MergeAction.keepSecond;

    // If tied, suggest merge to preserve both sets of data
    return MergeAction.merge;
  }

  /// Format a date for display in reason strings.
  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}
