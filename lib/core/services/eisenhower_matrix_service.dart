/// Eisenhower Matrix Service — categorizes events into four quadrants
/// based on urgency and importance for prioritization.
///
/// Quadrants:
///   Q1: Urgent & Important     → Do First (crises, deadlines)
///   Q2: Not Urgent & Important → Schedule (planning, growth)
///   Q3: Urgent & Not Important → Delegate (interruptions)
///   Q4: Neither                → Eliminate (time wasters)
///
/// Urgency is derived from proximity to deadline (configurable thresholds).
/// Importance is derived from event priority + tag weights.

import '../../models/event_model.dart';

/// The four Eisenhower quadrants.
enum Quadrant {
  doFirst,   // Q1: Urgent + Important
  schedule,  // Q2: Not Urgent + Important
  delegate,  // Q3: Urgent + Not Important
  eliminate; // Q4: Not Urgent + Not Important

  String get label {
    switch (this) {
      case Quadrant.doFirst:
        return 'Do First';
      case Quadrant.schedule:
        return 'Schedule';
      case Quadrant.delegate:
        return 'Delegate';
      case Quadrant.eliminate:
        return 'Eliminate';
    }
  }

  String get description {
    switch (this) {
      case Quadrant.doFirst:
        return 'Urgent and important — handle immediately';
      case Quadrant.schedule:
        return 'Important but not urgent — plan dedicated time';
      case Quadrant.delegate:
        return 'Urgent but not important — delegate if possible';
      case Quadrant.eliminate:
        return 'Neither urgent nor important — consider dropping';
    }
  }

  String get emoji {
    switch (this) {
      case Quadrant.doFirst:
        return '🔴';
      case Quadrant.schedule:
        return '🔵';
      case Quadrant.delegate:
        return '🟡';
      case Quadrant.eliminate:
        return '⚪';
    }
  }
}

/// A scored event with its quadrant classification.
class MatrixEntry {
  final EventModel event;
  final Quadrant quadrant;
  final double urgencyScore;    // 0.0–1.0
  final double importanceScore; // 0.0–1.0
  final String urgencyReason;
  final String importanceReason;

  const MatrixEntry({
    required this.event,
    required this.quadrant,
    required this.urgencyScore,
    required this.importanceScore,
    required this.urgencyReason,
    required this.importanceReason,
  });
}

/// Summary statistics for the matrix.
class MatrixSummary {
  final int total;
  final Map<Quadrant, int> counts;
  final Map<Quadrant, List<MatrixEntry>> entries;
  final double averageUrgency;
  final double averageImportance;
  final double balanceScore; // 0-100, higher = more time on Q1/Q2

  const MatrixSummary({
    required this.total,
    required this.counts,
    required this.entries,
    required this.averageUrgency,
    required this.averageImportance,
    required this.balanceScore,
  });
}

/// Configuration for urgency thresholds and importance weights.
class MatrixConfig {
  /// Events within this duration are considered urgent.
  final Duration urgentThreshold;

  /// Events within this duration get partial urgency score.
  final Duration soonThreshold;

  /// Tags that boost importance score (tag name → weight 0.0–1.0).
  final Map<String, double> importantTags;

  /// Minimum priority level considered "important" (inclusive).
  final EventPriority importanceMinPriority;

  const MatrixConfig({
    this.urgentThreshold = const Duration(hours: 24),
    this.soonThreshold = const Duration(days: 3),
    this.importantTags = const {},
    this.importanceMinPriority = EventPriority.high,
  });
}

/// Service for building and analyzing Eisenhower matrices.
class EisenhowerMatrixService {
  final MatrixConfig config;

  EisenhowerMatrixService({MatrixConfig? config})
      : config = config ?? const MatrixConfig();

  /// Compute urgency score (0.0–1.0) for an event relative to [now].
  double computeUrgency(EventModel event, DateTime now) {
    final deadline = event.endDate ?? event.date;
    final remaining = deadline.difference(now);

    // Already past → maximum urgency
    if (remaining.isNegative) return 1.0;

    // Within urgent threshold → high urgency (0.8–1.0)
    if (remaining <= config.urgentThreshold) {
      final fraction = remaining.inMinutes / config.urgentThreshold.inMinutes;
      return 0.8 + 0.2 * (1.0 - fraction);
    }

    // Within soon threshold → moderate urgency (0.3–0.8)
    if (remaining <= config.soonThreshold) {
      final pastUrgent = remaining - config.urgentThreshold;
      final soonWindow = config.soonThreshold - config.urgentThreshold;
      final fraction = pastUrgent.inMinutes / soonWindow.inMinutes;
      return 0.3 + 0.5 * (1.0 - fraction);
    }

    // Far out → low urgency, decaying toward 0
    final daysOut = remaining.inHours / 24.0;
    final soonDays = config.soonThreshold.inHours / 24.0;
    final beyondSoon = daysOut - soonDays;
    return (0.3 * (1.0 / (1.0 + beyondSoon / 7.0))).clamp(0.0, 0.3);
  }

  /// Compute importance score (0.0–1.0) for an event.
  double computeImportance(EventModel event) {
    double score = 0.0;

    // Priority contributes up to 0.6
    switch (event.priority) {
      case EventPriority.urgent:
        score += 0.6;
        break;
      case EventPriority.high:
        score += 0.45;
        break;
      case EventPriority.medium:
        score += 0.25;
        break;
      case EventPriority.low:
        score += 0.1;
        break;
    }

    // Tags contribute up to 0.3
    double tagBoost = 0.0;
    for (final tag in event.tags) {
      final weight = config.importantTags[tag.name.toLowerCase()];
      if (weight != null && weight > tagBoost) {
        tagBoost = weight;
      }
    }
    score += tagBoost * 0.3;

    // Has checklist items → slightly more important (structure = intentional)
    if (event.checklist.hasItems) {
      score += 0.05;
    }

    // Has attachments → slightly more important
    if (event.attachments.hasAttachments) {
      score += 0.05;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Classify an event into a quadrant.
  Quadrant classify(double urgency, double importance) {
    final isUrgent = urgency >= 0.5;
    final isImportant = importance >= 0.4;

    if (isUrgent && isImportant) return Quadrant.doFirst;
    if (!isUrgent && isImportant) return Quadrant.schedule;
    if (isUrgent && !isImportant) return Quadrant.delegate;
    return Quadrant.eliminate;
  }

  /// Build a reason string for the urgency score.
  String _urgencyReason(EventModel event, DateTime now, double score) {
    final deadline = event.endDate ?? event.date;
    final remaining = deadline.difference(now);

    if (remaining.isNegative) {
      return 'Overdue by ${-remaining.inHours}h';
    }
    if (remaining.inHours < 1) {
      return 'Due in ${remaining.inMinutes}m';
    }
    if (remaining.inHours < 48) {
      return 'Due in ${remaining.inHours}h';
    }
    return 'Due in ${remaining.inDays}d';
  }

  /// Build a reason string for the importance score.
  String _importanceReason(EventModel event, double score) {
    final parts = <String>[];
    parts.add('${event.priority.label} priority');

    final matchedTags = event.tags
        .where((t) => config.importantTags.containsKey(t.name.toLowerCase()))
        .map((t) => t.name)
        .toList();
    if (matchedTags.isNotEmpty) {
      parts.add('tags: ${matchedTags.join(", ")}');
    }

    return parts.join(', ');
  }

  /// Score and classify a single event.
  MatrixEntry evaluate(EventModel event, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final urgency = computeUrgency(event, reference);
    final importance = computeImportance(event);
    final quadrant = classify(urgency, importance);

    return MatrixEntry(
      event: event,
      quadrant: quadrant,
      urgencyScore: urgency,
      importanceScore: importance,
      urgencyReason: _urgencyReason(event, reference, urgency),
      importanceReason: _importanceReason(event, importance),
    );
  }

  /// Build the full matrix from a list of events.
  MatrixSummary buildMatrix(List<EventModel> events, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final allEntries = events.map((e) => evaluate(e, now: reference)).toList();

    // Sort within each quadrant: Q1 by urgency desc, Q2 by importance desc, etc.
    allEntries.sort((a, b) {
      if (a.quadrant != b.quadrant) {
        return a.quadrant.index.compareTo(b.quadrant.index);
      }
      // Within same quadrant, sort by combined score descending
      final aScore = a.urgencyScore + a.importanceScore;
      final bScore = b.urgencyScore + b.importanceScore;
      return bScore.compareTo(aScore);
    });

    final grouped = <Quadrant, List<MatrixEntry>>{};
    final counts = <Quadrant, int>{};
    for (final q in Quadrant.values) {
      grouped[q] = [];
      counts[q] = 0;
    }
    for (final entry in allEntries) {
      grouped[entry.quadrant]!.add(entry);
      counts[entry.quadrant] = counts[entry.quadrant]! + 1;
    }

    final totalUrgency = allEntries.fold<double>(0, (s, e) => s + e.urgencyScore);
    final totalImportance = allEntries.fold<double>(0, (s, e) => s + e.importanceScore);
    final n = allEntries.length;

    // Balance score: percentage of events in Q1+Q2 (important quadrants)
    final importantCount = (counts[Quadrant.doFirst]! + counts[Quadrant.schedule]!);
    final balance = n > 0 ? (importantCount / n * 100) : 0.0;

    return MatrixSummary(
      total: n,
      counts: counts,
      entries: grouped,
      averageUrgency: n > 0 ? totalUrgency / n : 0.0,
      averageImportance: n > 0 ? totalImportance / n : 0.0,
      balanceScore: balance,
    );
  }

  /// Get action recommendations based on the matrix distribution.
  List<String> getRecommendations(MatrixSummary summary) {
    final recs = <String>[];

    final q1 = summary.counts[Quadrant.doFirst] ?? 0;
    final q2 = summary.counts[Quadrant.schedule] ?? 0;
    final q3 = summary.counts[Quadrant.delegate] ?? 0;
    final q4 = summary.counts[Quadrant.eliminate] ?? 0;

    if (q1 > summary.total * 0.4) {
      recs.add('⚠️ Too many urgent+important items (${q1}). '
          'You may be in crisis mode — try planning ahead to move items to Q2.');
    }

    if (q2 == 0 && summary.total > 0) {
      recs.add('📅 No scheduled important tasks. '
          'Invest time in long-term planning and personal growth.');
    }

    if (q3 > q2) {
      recs.add('🔄 More delegate items ($q3) than scheduled items ($q2). '
          'Consider delegating or automating Q3 tasks to free up focus time.');
    }

    if (q4 > summary.total * 0.3) {
      recs.add('🗑️ ${q4} items are neither urgent nor important. '
          'Consider removing them to reduce cognitive load.');
    }

    if (summary.balanceScore >= 70) {
      recs.add('✅ Good balance — ${summary.balanceScore.toStringAsFixed(0)}% '
          'of your events are in important quadrants.');
    }

    if (recs.isEmpty) {
      recs.add('👍 Your task distribution looks balanced.');
    }

    return recs;
  }

  /// Generate a text summary of the matrix.
  String formatSummary(MatrixSummary summary) {
    final buf = StringBuffer();
    buf.writeln('═══ Eisenhower Matrix ═══');
    buf.writeln('Total events: ${summary.total}');
    buf.writeln();

    for (final q in Quadrant.values) {
      final count = summary.counts[q] ?? 0;
      final entries = summary.entries[q] ?? [];
      buf.writeln('${q.emoji} ${q.label} ($count)');
      buf.writeln('  ${q.description}');
      for (final e in entries.take(5)) {
        buf.writeln('  • ${e.event.title} '
            '(urgency: ${(e.urgencyScore * 100).toStringAsFixed(0)}%, '
            'importance: ${(e.importanceScore * 100).toStringAsFixed(0)}%)');
      }
      if (entries.length > 5) {
        buf.writeln('  ... and ${entries.length - 5} more');
      }
      buf.writeln();
    }

    buf.writeln('── Metrics ──');
    buf.writeln('Avg urgency: ${(summary.averageUrgency * 100).toStringAsFixed(1)}%');
    buf.writeln('Avg importance: ${(summary.averageImportance * 100).toStringAsFixed(1)}%');
    buf.writeln('Balance score: ${summary.balanceScore.toStringAsFixed(1)}%');
    buf.writeln();

    buf.writeln('── Recommendations ──');
    for (final rec in getRecommendations(summary)) {
      buf.writeln(rec);
    }

    return buf.toString();
  }
}
