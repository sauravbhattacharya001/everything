/// Daily Review Service - aggregates a day's events into a structured
/// end-of-day review with completion stats, mood/energy tracking,
/// highlights, and day-over-day comparison.
///
/// Answers: "How was my day?", "Did I accomplish what I planned?",
/// "How does today compare to yesterday?", "What patterns emerge
/// over time?"
///
/// Key concepts:
///   - **Completion Rate**: fraction of scheduled events that were
///     completed (have checklists or are past their time).
///   - **Day Rating**: user-provided 1-5 star rating for the day.
///   - **Mood & Energy**: simple 1-5 scales tracked alongside events.
///   - **Highlights / Lowlights**: user-selected notable moments.
///   - **Streak**: consecutive days with a review entry.

import 'dart:convert';
import '../../models/event_model.dart';
import '../utils/formatting_utils.dart';
import 'storage_backend.dart';

// ─── Data Classes ───────────────────────────────────────────────

/// A single daily review entry capturing the user's reflection.
class DailyReview {
  /// The date this review covers.
  final DateTime date;

  /// Star rating for the day (1-5).
  final int rating;

  /// Mood score (1-5): 1=terrible, 5=amazing.
  final int mood;

  /// Energy level (1-5): 1=exhausted, 5=energized.
  final int energy;

  /// Free-text notes for the day.
  final String notes;

  /// User-highlighted positive moments.
  final List<String> highlights;

  /// User-noted things that didn't go well.
  final List<String> lowlights;

  /// One thing to improve tomorrow.
  final String tomorrowFocus;

  /// When this review was created.
  final DateTime createdAt;

  const DailyReview({
    required this.date,
    this.rating = 3,
    this.mood = 3,
    this.energy = 3,
    this.notes = '',
    this.highlights = const [],
    this.lowlights = const [],
    this.tomorrowFocus = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? date;

  DailyReview copyWith({
    int? rating,
    int? mood,
    int? energy,
    String? notes,
    List<String>? highlights,
    List<String>? lowlights,
    String? tomorrowFocus,
  }) {
    return DailyReview(
      date: date,
      rating: rating ?? this.rating,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      notes: notes ?? this.notes,
      highlights: highlights ?? this.highlights,
      lowlights: lowlights ?? this.lowlights,
      tomorrowFocus: tomorrowFocus ?? this.tomorrowFocus,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyReview &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => Object.hash(date.year, date.month, date.day);

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'rating': rating,
        'mood': mood,
        'energy': energy,
        'notes': notes,
        'highlights': highlights,
        'lowlights': lowlights,
        'tomorrowFocus': tomorrowFocus,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DailyReview.fromJson(Map<String, dynamic> json) {
    return DailyReview(
      date: DateTime.parse(json['date'] as String),
      rating: json['rating'] as int? ?? 3,
      mood: json['mood'] as int? ?? 3,
      energy: json['energy'] as int? ?? 3,
      notes: json['notes'] as String? ?? '',
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      lowlights: (json['lowlights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tomorrowFocus: json['tomorrowFocus'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

/// Summary statistics for a single day's events.
class DaySummary {
  /// Total number of events scheduled for the day.
  final int totalEvents;

  /// Number of events that are past their end time (or date).
  final int completedEvents;

  /// Events grouped by priority.
  final Map<EventPriority, int> byPriority;

  /// Total number of checklist items across all events.
  final int totalChecklistItems;

  /// Number of checked-off checklist items.
  final int completedChecklistItems;

  /// Total scheduled duration in minutes.
  final int totalMinutesScheduled;

  /// Distinct tags used across the day's events.
  final Set<String> tagsUsed;

  /// The earliest event start time.
  final DateTime? firstEventTime;

  /// The latest event end time.
  final DateTime? lastEventTime;

  /// Completion rate as a percentage (0-100).
  double get completionRate =>
      totalEvents > 0 ? (completedEvents / totalEvents) * 100 : 0;

  /// Checklist completion rate as a percentage (0-100).
  double get checklistRate => totalChecklistItems > 0
      ? (completedChecklistItems / totalChecklistItems) * 100
      : 0;

  /// Active hours: difference between first and last event.
  int get activeMinutes {
    if (firstEventTime == null || lastEventTime == null) return 0;
    return lastEventTime!.difference(firstEventTime!).inMinutes;
  }

  /// Day productivity label based on completion rate.
  String get productivityLabel {
    if (completionRate >= 90) return 'Excellent';
    if (completionRate >= 75) return 'Great';
    if (completionRate >= 50) return 'Good';
    if (completionRate >= 25) return 'Fair';
    return 'Needs work';
  }

  const DaySummary({
    this.totalEvents = 0,
    this.completedEvents = 0,
    this.byPriority = const {},
    this.totalChecklistItems = 0,
    this.completedChecklistItems = 0,
    this.totalMinutesScheduled = 0,
    this.tagsUsed = const {},
    this.firstEventTime,
    this.lastEventTime,
  });
}

/// Comparison between two days.
class DayComparison {
  final DaySummary today;
  final DaySummary yesterday;

  const DayComparison({required this.today, required this.yesterday});

  int get eventDelta => today.totalEvents - yesterday.totalEvents;
  double get completionDelta =>
      today.completionRate - yesterday.completionRate;
  int get minutesDelta =>
      today.totalMinutesScheduled - yesterday.totalMinutesScheduled;

  String get trend {
    if (today.completionRate > yesterday.completionRate + 10) {
      return 'improving';
    } else if (today.completionRate < yesterday.completionRate - 10) {
      return 'declining';
    }
    return 'stable';
  }
}

/// Mood/energy trend over multiple days.
class ReviewTrend {
  final List<DailyReview> reviews;

  /// Aggregated averages computed in a single pass instead of 3.
  late final double avgRating;
  late final double avgMood;
  late final double avgEnergy;

  ReviewTrend({required this.reviews}) {
    if (reviews.isEmpty) {
      avgRating = 0;
      avgMood = 0;
      avgEnergy = 0;
    } else {
      int sumR = 0, sumM = 0, sumE = 0;
      for (final r in reviews) {
        sumR += r.rating;
        sumM += r.mood;
        sumE += r.energy;
      }
      final n = reviews.length;
      avgRating = sumR / n;
      avgMood = sumM / n;
      avgEnergy = sumE / n;
    }
  }

  int get currentStreak {
    if (reviews.isEmpty) return 0;
    final sorted = List<DailyReview>.from(reviews)
      ..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime expected = DateTime.now();
    for (final review in sorted) {
      if (FormattingUtils.sameDay(review.date, expected)) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else if (review.date.isBefore(expected)) {
        break;
      }
    }
    return streak;
  }

  int get longestStreak {
    if (reviews.isEmpty) return 0;
    final sorted = List<DailyReview>.from(reviews)
      ..sort((a, b) => a.date.compareTo(b.date));
    int longest = 1;
    int current = 1;
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].date.difference(sorted[i - 1].date).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (diff > 1) {
        current = 1;
      }
    }
    return longest;
  }
}

// ─── Service ────────────────────────────────────────────────────

/// Service that computes daily summaries and manages review entries.
class DailyReviewService {
  static const String _storageKey = 'daily_review_entries';
  final List<EventModel> events;
  final List<DailyReview> _reviews;
  bool _initialized = false;

  /// Pre-indexed events by date key (YYYYMMDD) for O(1) day lookups.
  /// Avoids O(N) linear scans per call to summarize(), compare(),
  /// topAccomplishments(), and tomorrowEvents().
  late final Map<int, List<EventModel>> _eventsByDate;

  DailyReviewService({
    required this.events,
    List<DailyReview>? reviews,
  }) : _reviews = reviews ?? [] {
    _eventsByDate = _indexByDate(events);
  }

  /// Build a date key → event list index in a single O(N) pass.
  static Map<int, List<EventModel>> _indexByDate(List<EventModel> events) {
    final index = <int, List<EventModel>>{};
    for (final e in events) {
      final key = e.date.year * 10000 + e.date.month * 100 + e.date.day;
      index.putIfAbsent(key, () => []).add(e);
    }
    return index;
  }

  /// O(1) event lookup for a given date.
  List<EventModel> _eventsForDay(DateTime date) {
    final key = date.year * 10000 + date.month * 100 + date.day;
    return _eventsByDate[key] ?? const [];
  }

  /// Initialize by loading persisted reviews.
  Future<void> init() async {
    if (_initialized) return;
    try {
      final data = await StorageBackend.read(_storageKey);
      if (data != null && data.isNotEmpty) {
        final list = jsonDecode(data) as List<dynamic>;
        for (final item in list) {
          final review = DailyReview.fromJson(item as Map<String, dynamic>);
          // Avoid duplicates if reviews were passed via constructor
          if (!_reviews.any((r) => FormattingUtils.sameDay(r.date, review.date))) {
            _reviews.add(review);
          }
        }
      }
    } catch (_) {}
    _initialized = true;
  }

  /// Persist reviews to SharedPreferences.
  Future<void> _save() async {
    try {
      await StorageBackend.write(
        _storageKey,
        jsonEncode(_reviews.map((r) => r.toJson()).toList()),
      );
    } catch (_) {}
  }

  /// Get all stored reviews.
  List<DailyReview> get reviews => List.unmodifiable(_reviews);

  /// Compute a summary for a specific date.
  DaySummary summarize(DateTime date) {
    final dayEvents = _eventsForDay(date);

    int completed = 0;
    int totalChecklist = 0;
    int completedChecklist = 0;
    int totalMinutes = 0;
    final priorities = <EventPriority, int>{};
    final tags = <String>{};
    DateTime? first;
    DateTime? last;

    for (final event in dayEvents) {
      // Count completed events (past their end time, or past date for all-day)
      final endTime = event.endDate ?? event.date;
      if (endTime.isBefore(DateTime.now())) {
        completed++;
      }

      // Checklist stats
      if (event.checklist != null && event.checklist!.items.isNotEmpty) {
        for (final item in event.checklist!.items) {
          totalChecklist++;
          if (item.isChecked) completedChecklist++;
        }
      }

      // Duration
      if (event.endDate != null) {
        totalMinutes += event.endDate!.difference(event.date).inMinutes;
      }

      // Priority counts
      priorities[event.priority] =
          (priorities[event.priority] ?? 0) + 1;

      // Tags
      for (final tag in event.tags) {
        tags.add(tag.name);
      }

      // Time range
      if (first == null || event.date.isBefore(first)) {
        first = event.date;
      }
      final end = event.endDate ?? event.date;
      if (last == null || end.isAfter(last)) {
        last = end;
      }
    }

    return DaySummary(
      totalEvents: dayEvents.length,
      completedEvents: completed,
      byPriority: priorities,
      totalChecklistItems: totalChecklist,
      completedChecklistItems: completedChecklist,
      totalMinutesScheduled: totalMinutes,
      tagsUsed: tags,
      firstEventTime: first,
      lastEventTime: last,
    );
  }

  /// Get comparison between today and yesterday.
  DayComparison compare(DateTime date) {
    final today = summarize(date);
    final yesterday =
        summarize(date.subtract(const Duration(days: 1)));
    return DayComparison(today: today, yesterday: yesterday);
  }

  /// Get the review for a specific date, or null if not yet reviewed.
  DailyReview? getReview(DateTime date) {
    for (final review in _reviews) {
      if (FormattingUtils.sameDay(review.date, date)) return review;
    }
    return null;
  }

  /// Save or update a review for a date.
  Future<void> saveReview(DailyReview review) async {
    _reviews.removeWhere((r) => FormattingUtils.sameDay(r.date, review.date));
    _reviews.add(review);
    await _save();
  }

  /// Get mood/energy trends for the last N days.
  ReviewTrend getTrend({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recent =
        _reviews.where((r) => r.date.isAfter(cutoff)).toList();
    return ReviewTrend(reviews: recent);
  }

  /// Get events for tomorrow (for the "focus for tomorrow" section).
  List<EventModel> tomorrowEvents(DateTime today) {
    final tomorrow = today.add(const Duration(days: 1));
    return _eventsForDay(tomorrow).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get today's top accomplishments (high priority completed events).
  List<EventModel> topAccomplishments(DateTime date) {
    final dayEvents = _eventsForDay(date);
    return dayEvents
        .where((e) {
          final endTime = e.endDate ?? e.date;
          return endTime.isBefore(DateTime.now());
        })
        .toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }
}

