import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/daily_review_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';
import 'package:everything/models/event_checklist.dart';

void main() {
  late DailyReviewService service;
  final today = DateTime(2026, 3, 3);
  final yesterday = DateTime(2026, 3, 2);
  final tomorrow = DateTime(2026, 3, 4);

  List<EventModel> sampleEvents() => [
        EventModel(
          id: 'e1',
          title: 'Morning Standup',
          description: 'Team sync',
          date: DateTime(2026, 3, 3, 9, 0),
          endDate: DateTime(2026, 3, 3, 9, 15),
          priority: EventPriority.medium,
          tags: [const EventTag(name: 'work', color: 0xFF2196F3)],
          checklist: EventChecklist(items: [
            EventChecklistItem(text: 'Status update', isChecked: true),
            EventChecklistItem(text: 'Blockers', isChecked: true),
          ]),
        ),
        EventModel(
          id: 'e2',
          title: 'Design Review',
          description: 'Review designs',
          date: DateTime(2026, 3, 3, 10, 0),
          endDate: DateTime(2026, 3, 3, 11, 0),
          priority: EventPriority.high,
          tags: [const EventTag(name: 'work', color: 0xFF2196F3)],
          checklist: EventChecklist(items: [
            EventChecklistItem(text: 'Prepare slides', isChecked: true),
            EventChecklistItem(text: 'Get feedback', isChecked: false),
          ]),
        ),
        EventModel(
          id: 'e3',
          title: 'Gym',
          description: 'Workout',
          date: DateTime(2026, 3, 3, 18, 0),
          endDate: DateTime(2026, 3, 3, 19, 0),
          priority: EventPriority.low,
          tags: [const EventTag(name: 'health', color: 0xFFE91E63)],
        ),
        // Yesterday
        EventModel(
          id: 'e4',
          title: 'Code Review',
          description: '',
          date: DateTime(2026, 3, 2, 10, 0),
          endDate: DateTime(2026, 3, 2, 11, 0),
          priority: EventPriority.medium,
          tags: [const EventTag(name: 'work', color: 0xFF2196F3)],
        ),
        // Tomorrow
        EventModel(
          id: 'e5',
          title: 'Product Demo',
          description: '',
          date: DateTime(2026, 3, 4, 14, 0),
          endDate: DateTime(2026, 3, 4, 15, 0),
          priority: EventPriority.urgent,
          tags: [const EventTag(name: 'work', color: 0xFF2196F3)],
        ),
      ];

  setUp(() {
    service = DailyReviewService(events: sampleEvents());
  });

  // ─── DaySummary tests ─────────────────────────────────────────

  group('DaySummary', () {
    test('counts total events for a day', () {
      final summary = service.summarize(today);
      expect(summary.totalEvents, 3);
    });

    test('counts yesterday events correctly', () {
      final summary = service.summarize(yesterday);
      expect(summary.totalEvents, 1);
    });

    test('returns zero for empty day', () {
      final summary = service.summarize(DateTime(2026, 6, 15));
      expect(summary.totalEvents, 0);
      expect(summary.completedEvents, 0);
      expect(summary.completionRate, 0);
    });

    test('counts checklist items', () {
      final summary = service.summarize(today);
      expect(summary.totalChecklistItems, 4);
      expect(summary.completedChecklistItems, 3);
    });

    test('calculates checklist rate', () {
      final summary = service.summarize(today);
      expect(summary.checklistRate, 75.0);
    });

    test('checklist rate is zero when no checklists', () {
      final summary = service.summarize(yesterday);
      expect(summary.totalChecklistItems, 0);
      expect(summary.checklistRate, 0);
    });

    test('calculates total scheduled minutes', () {
      final summary = service.summarize(today);
      // 15 + 60 + 60 = 135 minutes
      expect(summary.totalMinutesScheduled, 135);
    });

    test('collects distinct tags', () {
      final summary = service.summarize(today);
      expect(summary.tagsUsed, containsAll(['work', 'health']));
      expect(summary.tagsUsed.length, 2);
    });

    test('finds first and last event times', () {
      final summary = service.summarize(today);
      expect(summary.firstEventTime, DateTime(2026, 3, 3, 9, 0));
      expect(summary.lastEventTime, DateTime(2026, 3, 3, 19, 0));
    });

    test('null times for empty day', () {
      final summary = service.summarize(DateTime(2026, 6, 15));
      expect(summary.firstEventTime, isNull);
      expect(summary.lastEventTime, isNull);
    });

    test('active minutes calculated correctly', () {
      final summary = service.summarize(today);
      // 9:00 to 19:00 = 600 minutes
      expect(summary.activeMinutes, 600);
    });

    test('active minutes zero for empty day', () {
      final summary = service.summarize(DateTime(2026, 6, 15));
      expect(summary.activeMinutes, 0);
    });

    test('counts events by priority', () {
      final summary = service.summarize(today);
      expect(summary.byPriority[EventPriority.high], 1);
      expect(summary.byPriority[EventPriority.medium], 1);
      expect(summary.byPriority[EventPriority.low], 1);
    });

    test('productivity label matches rate', () {
      // With all events past, completionRate would be 100%
      // but since some events may be in the future, test the label logic
      final s1 = const DaySummary(totalEvents: 10, completedEvents: 10);
      expect(s1.productivityLabel, 'Excellent');
      expect(s1.completionRate, 100.0);

      final s2 = const DaySummary(totalEvents: 10, completedEvents: 8);
      expect(s2.productivityLabel, 'Great');

      final s3 = const DaySummary(totalEvents: 10, completedEvents: 5);
      expect(s3.productivityLabel, 'Good');

      final s4 = const DaySummary(totalEvents: 10, completedEvents: 3);
      expect(s4.productivityLabel, 'Fair');

      final s5 = const DaySummary(totalEvents: 10, completedEvents: 1);
      expect(s5.productivityLabel, 'Needs work');
    });
  });

  // ─── DayComparison tests ──────────────────────────────────────

  group('DayComparison', () {
    test('calculates event delta', () {
      final comp = service.compare(today);
      // today: 3 events, yesterday: 1
      expect(comp.eventDelta, 2);
    });

    test('calculates minutes delta', () {
      final comp = service.compare(today);
      // today: 135 min, yesterday: 60 min
      expect(comp.minutesDelta, 75);
    });

    test('trend is stable when similar', () {
      final comp = DayComparison(
        today: const DaySummary(totalEvents: 5, completedEvents: 4),
        yesterday: const DaySummary(totalEvents: 5, completedEvents: 4),
      );
      expect(comp.trend, 'stable');
    });

    test('trend is improving when rate up', () {
      final comp = DayComparison(
        today: const DaySummary(totalEvents: 5, completedEvents: 5),
        yesterday: const DaySummary(totalEvents: 5, completedEvents: 2),
      );
      expect(comp.trend, 'improving');
    });

    test('trend is declining when rate down', () {
      final comp = DayComparison(
        today: const DaySummary(totalEvents: 5, completedEvents: 1),
        yesterday: const DaySummary(totalEvents: 5, completedEvents: 5),
      );
      expect(comp.trend, 'declining');
    });
  });

  // ─── DailyReview CRUD tests ───────────────────────────────────

  group('DailyReview management', () {
    test('no review initially', () {
      expect(service.getReview(today), isNull);
    });

    test('save and retrieve review', () {
      final review = DailyReview(
        date: today,
        rating: 4,
        mood: 5,
        energy: 3,
        notes: 'Good day!',
        highlights: ['Shipped feature'],
        lowlights: ['Too many meetings'],
        tomorrowFocus: 'Write tests',
      );
      service.saveReview(review);
      final retrieved = service.getReview(today);
      expect(retrieved, isNotNull);
      expect(retrieved!.rating, 4);
      expect(retrieved.mood, 5);
      expect(retrieved.energy, 3);
      expect(retrieved.notes, 'Good day!');
      expect(retrieved.highlights, ['Shipped feature']);
      expect(retrieved.lowlights, ['Too many meetings']);
      expect(retrieved.tomorrowFocus, 'Write tests');
    });

    test('update replaces existing review', () {
      service.saveReview(DailyReview(date: today, rating: 3));
      service.saveReview(DailyReview(date: today, rating: 5));
      final retrieved = service.getReview(today);
      expect(retrieved!.rating, 5);
      expect(service.reviews.where((r) =>
          r.date.year == today.year &&
          r.date.month == today.month &&
          r.date.day == today.day).length, 1);
    });

    test('reviews for different days are independent', () {
      service.saveReview(DailyReview(date: today, rating: 5));
      service.saveReview(DailyReview(date: yesterday, rating: 2));
      expect(service.getReview(today)!.rating, 5);
      expect(service.getReview(yesterday)!.rating, 2);
    });

    test('copyWith preserves unchanged fields', () {
      final review = DailyReview(
        date: today,
        rating: 4,
        mood: 3,
        energy: 5,
        notes: 'test',
        highlights: ['h1'],
      );
      final updated = review.copyWith(rating: 5);
      expect(updated.rating, 5);
      expect(updated.mood, 3);
      expect(updated.energy, 5);
      expect(updated.notes, 'test');
      expect(updated.highlights, ['h1']);
    });

    test('equality is by date only', () {
      final r1 = DailyReview(date: today, rating: 1);
      final r2 = DailyReview(date: today, rating: 5);
      expect(r1, equals(r2));
    });

    test('different dates are not equal', () {
      final r1 = DailyReview(date: today);
      final r2 = DailyReview(date: yesterday);
      expect(r1, isNot(equals(r2)));
    });
  });

  // ─── ReviewTrend tests ────────────────────────────────────────

  group('ReviewTrend', () {
    test('empty trend has zero averages', () {
      final trend = const ReviewTrend(reviews: []);
      expect(trend.avgRating, 0);
      expect(trend.avgMood, 0);
      expect(trend.avgEnergy, 0);
      expect(trend.currentStreak, 0);
      expect(trend.longestStreak, 0);
    });

    test('single review averages equal the review', () {
      final trend = ReviewTrend(reviews: [
        DailyReview(date: today, rating: 4, mood: 5, energy: 3),
      ]);
      expect(trend.avgRating, 4);
      expect(trend.avgMood, 5);
      expect(trend.avgEnergy, 3);
    });

    test('computes correct averages', () {
      final trend = ReviewTrend(reviews: [
        DailyReview(date: today, rating: 4, mood: 3, energy: 5),
        DailyReview(date: yesterday, rating: 2, mood: 5, energy: 1),
      ]);
      expect(trend.avgRating, 3.0);
      expect(trend.avgMood, 4.0);
      expect(trend.avgEnergy, 3.0);
    });

    test('longest streak with gaps', () {
      final trend = ReviewTrend(reviews: [
        DailyReview(date: DateTime(2026, 3, 1)),
        DailyReview(date: DateTime(2026, 3, 2)),
        DailyReview(date: DateTime(2026, 3, 3)),
        // gap
        DailyReview(date: DateTime(2026, 3, 5)),
        DailyReview(date: DateTime(2026, 3, 6)),
      ]);
      expect(trend.longestStreak, 3);
    });

    test('longest streak with no gaps', () {
      final trend = ReviewTrend(reviews: [
        DailyReview(date: DateTime(2026, 3, 1)),
        DailyReview(date: DateTime(2026, 3, 2)),
        DailyReview(date: DateTime(2026, 3, 3)),
        DailyReview(date: DateTime(2026, 3, 4)),
      ]);
      expect(trend.longestStreak, 4);
    });

    test('getTrend filters by days', () {
      final svc = DailyReviewService(
        events: [],
        reviews: [
          DailyReview(date: DateTime.now()),
          DailyReview(date: DateTime.now().subtract(const Duration(days: 2))),
          DailyReview(date: DateTime.now().subtract(const Duration(days: 30))),
        ],
      );
      final trend = svc.getTrend(days: 7);
      expect(trend.reviews.length, 2);
    });
  });

  // ─── Tomorrow events ──────────────────────────────────────────

  group('Tomorrow events', () {
    test('finds tomorrow events', () {
      final events = service.tomorrowEvents(today);
      expect(events.length, 1);
      expect(events.first.title, 'Product Demo');
    });

    test('empty when no tomorrow events', () {
      final events = service.tomorrowEvents(tomorrow);
      expect(events, isEmpty);
    });

    test('sorted by time', () {
      final svc = DailyReviewService(events: [
        EventModel(
          id: 't1', title: 'Late',
          date: DateTime(2026, 3, 4, 16, 0),
          priority: EventPriority.low,
        ),
        EventModel(
          id: 't2', title: 'Early',
          date: DateTime(2026, 3, 4, 8, 0),
          priority: EventPriority.low,
        ),
      ]);
      final events = svc.tomorrowEvents(today);
      expect(events.first.title, 'Early');
      expect(events.last.title, 'Late');
    });
  });

  // ─── Top accomplishments ──────────────────────────────────────

  group('Top accomplishments', () {
    test('sorted by priority descending', () {
      final accomplishments = service.topAccomplishments(today);
      // Only events whose endDate is before now are included
      // Priority order: high > medium > low
      if (accomplishments.length >= 2) {
        expect(
          accomplishments.first.priority.index >=
              accomplishments.last.priority.index,
          isTrue,
        );
      }
    });
  });

  // ─── Edge cases ───────────────────────────────────────────────

  group('Edge cases', () {
    test('service with no events', () {
      final svc = DailyReviewService(events: []);
      final summary = svc.summarize(today);
      expect(summary.totalEvents, 0);
      expect(summary.completionRate, 0);
    });

    test('service with no reviews', () {
      final svc = DailyReviewService(events: []);
      expect(svc.reviews, isEmpty);
      expect(svc.getReview(today), isNull);
    });

    test('comparison with empty days', () {
      final svc = DailyReviewService(events: []);
      final comp = svc.compare(today);
      expect(comp.eventDelta, 0);
      expect(comp.completionDelta, 0);
      expect(comp.trend, 'stable');
    });

    test('events without endDate still counted', () {
      final svc = DailyReviewService(events: [
        EventModel(
          id: 'noend',
          title: 'All-day Event',
          date: today,
          priority: EventPriority.medium,
        ),
      ]);
      final summary = svc.summarize(today);
      expect(summary.totalEvents, 1);
      expect(summary.totalMinutesScheduled, 0);
    });

    test('events without tags produce empty tag set', () {
      final svc = DailyReviewService(events: [
        EventModel(
          id: 'notag',
          title: 'Untagged',
          date: today,
          priority: EventPriority.low,
        ),
      ]);
      final summary = svc.summarize(today);
      expect(summary.tagsUsed, isEmpty);
    });

    test('DaySummary defaults are zero', () {
      const s = DaySummary();
      expect(s.totalEvents, 0);
      expect(s.completedEvents, 0);
      expect(s.totalChecklistItems, 0);
      expect(s.completedChecklistItems, 0);
      expect(s.totalMinutesScheduled, 0);
      expect(s.completionRate, 0);
      expect(s.checklistRate, 0);
      expect(s.activeMinutes, 0);
    });
  });
}
