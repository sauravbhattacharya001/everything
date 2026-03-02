import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/event_search_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';
import 'package:everything/models/event_checklist.dart';
import 'package:everything/models/event_attachment.dart';
import 'package:everything/models/recurrence_rule.dart';

void main() {
  const service = EventSearchService();

  EventModel _event({
    String id = '1',
    String title = 'Test',
    String description = '',
    String location = '',
    DateTime? date,
    EventPriority priority = EventPriority.medium,
    List<EventTag> tags = const [],
  }) {
    return EventModel(
      id: id,
      title: title,
      description: description,
      location: location,
      date: date ?? DateTime(2025, 6, 15),
      priority: priority,
      tags: tags,
    );
  }

  final events = [
    _event(id: '1', title: 'Team Meeting', description: 'Weekly sync', location: 'Room A', priority: EventPriority.high, tags: [const EventTag(name: 'work', color: Colors.blue)]),
    _event(id: '2', title: 'Dentist Appointment', location: 'Downtown Clinic', priority: EventPriority.medium),
    _event(id: '3', title: 'Birthday Party', description: 'Bring cake', priority: EventPriority.low, tags: [const EventTag(name: 'personal', color: Colors.green)]),
    _event(id: '4', title: 'Urgent Deadline', description: 'Submit proposal', priority: EventPriority.urgent, tags: [const EventTag(name: 'work', color: Colors.blue)]),
    _event(id: '5', title: 'Grocery Run', location: 'Whole Foods', priority: EventPriority.low),
  ];

  group('EventSearchService', () {
    group('text search', () {
      test('finds events by title', () {
        final results = service.search(events, query: 'meeting');
        expect(results, isNotEmpty);
        expect(results.first.event.id, '1');
      });

      test('finds events by description', () {
        final results = service.search(events, query: 'cake');
        expect(results, isNotEmpty);
        expect(results.first.event.id, '3');
      });

      test('finds events by location', () {
        final results = service.search(events, query: 'downtown');
        expect(results, isNotEmpty);
        expect(results.first.event.id, '2');
      });

      test('finds events by tag name', () {
        final results = service.search(events, query: 'work');
        expect(results.length, 2);
      });

      test('returns empty for no matches', () {
        final results = service.search(events, query: 'nonexistent');
        expect(results, isEmpty);
      });

      test('case insensitive', () {
        final results = service.search(events, query: 'MEETING');
        expect(results, isNotEmpty);
      });

      test('multi-term search', () {
        final results = service.search(events, query: 'team meeting');
        expect(results, isNotEmpty);
        expect(results.first.event.id, '1');
      });

      test('empty query returns all', () {
        final results = service.search(events);
        expect(results.length, events.length);
      });
    });

    group('filters', () {
      test('filter by priority', () {
        final results = service.search(events, filters: const SearchFilters(priorities: {EventPriority.urgent}));
        expect(results.length, 1);
        expect(results.first.event.id, '4');
      });

      test('filter by multiple priorities', () {
        final results = service.search(events, filters: const SearchFilters(priorities: {EventPriority.high, EventPriority.urgent}));
        expect(results.length, 2);
      });

      test('filter by date range', () {
        final rangeEvents = [
          _event(id: 'a', title: 'Early', date: DateTime(2025, 1, 1)),
          _event(id: 'b', title: 'Mid', date: DateTime(2025, 6, 15)),
          _event(id: 'c', title: 'Late', date: DateTime(2025, 12, 31)),
        ];
        final results = service.search(rangeEvents, filters: SearchFilters(dateRange: DateTimeRange(start: DateTime(2025, 5, 1), end: DateTime(2025, 7, 1))));
        expect(results.length, 1);
        expect(results.first.event.id, 'b');
      });

      test('filter by required tags', () {
        final results = service.search(events, filters: const SearchFilters(requiredTags: {'work'}));
        expect(results.length, 2);
      });

      test('filter by hasLocation', () {
        final results = service.search(events, filters: const SearchFilters(hasLocation: true));
        expect(results.length, 3);
      });

      test('combine query and filters', () {
        final results = service.search(events, query: 'meeting', filters: const SearchFilters(priorities: {EventPriority.high}));
        expect(results.length, 1);
        expect(results.first.event.id, '1');
      });
    });

    group('sorting', () {
      test('sort by priority descending', () {
        final results = service.search(events, sort: SearchSort.priorityDescending);
        expect(results.first.event.priority, EventPriority.urgent);
      });

      test('sort by title ascending', () {
        final results = service.search(events, sort: SearchSort.titleAscending);
        expect(results.first.event.title, 'Birthday Party');
      });
    });

    group('limit', () {
      test('limits results', () {
        final results = service.search(events, limit: 2);
        expect(results.length, 2);
      });
    });

    group('suggest', () {
      test('suggests matching terms', () {
        final suggestions = service.suggest(events, partial: 'meet');
        expect(suggestions, contains('Team Meeting'));
      });

      test('empty partial returns empty', () {
        final suggestions = service.suggest(events, partial: '');
        expect(suggestions, isEmpty);
      });
    });

    group('SearchResult', () {
      test('has matches with text search', () {
        final results = service.search(events, query: 'meeting');
        expect(results.first.matches, isNotEmpty);
      });

      test('score is between 0 and 1', () {
        for (final r in service.search(events, query: 'meeting')) {
          expect(r.score, greaterThanOrEqualTo(0.0));
          expect(r.score, lessThanOrEqualTo(1.0));
        }
      });
    });

    group('search field restriction', () {
      test('searchFields limits to title only', () {
        final results = service.search(events,
            query: 'cake',
            filters: const SearchFilters(
                searchFields: {SearchField.title}));
        // 'cake' is in description of event 3, not title
        expect(results, isEmpty);
      });

      test('searchFields limits to description only', () {
        final results = service.search(events,
            query: 'meeting',
            filters: const SearchFilters(
                searchFields: {SearchField.description}));
        // 'meeting' is in title, not description
        expect(results, isEmpty);
      });

      test('searchFields location finds location match', () {
        final results = service.search(events,
            query: 'downtown',
            filters: const SearchFilters(
                searchFields: {SearchField.location}));
        expect(results, isNotEmpty);
        expect(results.first.event.id, '2');
      });

      test('searchFields tags finds tag match', () {
        final results = service.search(events,
            query: 'personal',
            filters: const SearchFilters(
                searchFields: {SearchField.tags}));
        expect(results.length, 1);
        expect(results.first.event.id, '3');
      });
    });

    group('anyTags filter', () {
      test('matches events with any of the specified tags', () {
        final results = service.search(events,
            filters: const SearchFilters(
                anyTags: {'personal', 'nonexistent'}));
        expect(results.length, 1);
        expect(results.first.event.id, '3');
      });

      test('matches multiple events with any tags', () {
        final results = service.search(events,
            filters: const SearchFilters(anyTags: {'work'}));
        expect(results.length, 2);
      });

      test('returns empty when no tags match', () {
        final results = service.search(events,
            filters: const SearchFilters(
                anyTags: {'nonexistent'}));
        expect(results, isEmpty);
      });
    });

    group('isRecurring filter', () {
      test('filters recurring events', () {
        final recurringEvents = [
          _event(id: 'r1', title: 'Daily Standup'),
          EventModel(
            id: 'r2',
            title: 'Weekly Review',
            date: DateTime(2025, 6, 15),
            recurrence: const RecurrenceRule(
                frequency: RecurrenceFrequency.weekly),
          ),
        ];
        final results = service.search(recurringEvents,
            filters: const SearchFilters(isRecurring: true));
        expect(results.length, 1);
        expect(results.first.event.id, 'r2');
      });

      test('filters non-recurring events', () {
        final recurringEvents = [
          _event(id: 'r1', title: 'Daily Standup'),
          EventModel(
            id: 'r2',
            title: 'Weekly Review',
            date: DateTime(2025, 6, 15),
            recurrence: const RecurrenceRule(
                frequency: RecurrenceFrequency.weekly),
          ),
        ];
        final results = service.search(recurringEvents,
            filters: const SearchFilters(isRecurring: false));
        expect(results.length, 1);
        expect(results.first.event.id, 'r1');
      });
    });

    group('hasLocation false filter', () {
      test('filters events without location', () {
        final results = service.search(events,
            filters: const SearchFilters(hasLocation: false));
        // Events 3, 4 have no location
        expect(results.length, 2);
        final ids = results.map((r) => r.event.id).toSet();
        expect(ids, containsAll(['3', '4']));
      });
    });

    group('date sorting', () {
      test('dateAscending sorts earliest first', () {
        final dateEvents = [
          _event(id: 'a', title: 'Late', date: DateTime(2025, 12, 1)),
          _event(id: 'b', title: 'Early', date: DateTime(2025, 1, 1)),
          _event(id: 'c', title: 'Mid', date: DateTime(2025, 6, 15)),
        ];
        final results = service.search(dateEvents,
            sort: SearchSort.dateAscending);
        expect(results[0].event.id, 'b');
        expect(results[1].event.id, 'c');
        expect(results[2].event.id, 'a');
      });

      test('dateDescending sorts latest first', () {
        final dateEvents = [
          _event(id: 'a', title: 'Late', date: DateTime(2025, 12, 1)),
          _event(id: 'b', title: 'Early', date: DateTime(2025, 1, 1)),
          _event(id: 'c', title: 'Mid', date: DateTime(2025, 6, 15)),
        ];
        final results = service.search(dateEvents,
            sort: SearchSort.dateDescending);
        expect(results[0].event.id, 'a');
        expect(results[1].event.id, 'c');
        expect(results[2].event.id, 'b');
      });
    });

    group('relevance ranking', () {
      test('exact title match scores higher than partial', () {
        final rankEvents = [
          _event(id: '1', title: 'meeting'),
          _event(id: '2', title: 'Team meeting notes'),
        ];
        final results = service.search(rankEvents, query: 'meeting');
        expect(results.length, 2);
        expect(results[0].event.id, '1'); // exact match first
        expect(results[0].score, greaterThan(results[1].score));
      });

      test('title match scores higher than description match', () {
        final rankEvents = [
          _event(id: '1', title: 'Lunch', description: 'plan the meeting'),
          _event(id: '2', title: 'Meeting'),
        ];
        final results = service.search(rankEvents, query: 'meeting');
        // Title has weight 1.0, description 0.6
        expect(results[0].event.id, '2');
      });
    });

    group('SearchMatch details', () {
      test('match contains correct field', () {
        final results = service.search(events, query: 'downtown');
        final match = results.first.matches.firstWhere(
            (m) => m.field == SearchField.location);
        expect(match.snippet, contains('Downtown'));
        expect(match.length, 'downtown'.length);
      });
    });

    group('edge cases', () {
      test('empty events list returns empty results', () {
        final results = service.search([], query: 'test');
        expect(results, isEmpty);
      });

      test('whitespace-only query returns all events', () {
        final results = service.search(events, query: '   ');
        expect(results.length, events.length);
      });

      test('suggest with limit parameter', () {
        final suggestions =
            service.suggest(events, partial: 'e', limit: 2);
        expect(suggestions.length, lessThanOrEqual(2));
      });

      test('suggest does not include exact match', () {
        final suggestions =
            service.suggest(events, partial: 'Team Meeting');
        // Should not suggest the exact same text
        expect(
          suggestions.where((s) => s.toLowerCase() == 'team meeting'),
          isEmpty,
        );
      });

      test('empty filters return all events', () {
        final results = service.search(events,
            filters: const SearchFilters());
        expect(results.length, events.length);
      });
    });
  });
}
