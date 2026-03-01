import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/event_search_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';

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
  });
}
