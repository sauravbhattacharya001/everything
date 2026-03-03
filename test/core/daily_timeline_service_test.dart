import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/daily_timeline_service.dart';
import 'package:everything/models/event_model.dart';

void main() {
  late DailyTimelineService service;
  final testDate = DateTime(2026, 3, 2);

  setUp(() {
    service = const DailyTimelineService();
  });

  EventModel _makeEvent(
    String id,
    String title,
    int startHour,
    int startMin,
    int endHour,
    int endMin, {
    EventPriority priority = EventPriority.medium,
    String location = '',
  }) {
    return EventModel(
      id: id,
      title: title,
      date: DateTime(2026, 3, 2, startHour, startMin),
      endDate: DateTime(2026, 3, 2, endHour, endMin),
      priority: priority,
      location: location,
    );
  }

  group('DailyTimelineService', () {
    test('empty events produce single free block', () {
      final timeline = service.buildTimeline(events: [], date: testDate);
      expect(timeline.length, 1);
      expect(timeline.first.isEvent, false);
      expect(timeline.first.start.hour, 8);
      expect(timeline.first.end.hour, 22);
    });

    test('single event produces gap-event-gap', () {
      final events = [_makeEvent('1', 'Meeting', 10, 0, 11, 0)];
      final timeline = service.buildTimeline(events: events, date: testDate);

      expect(timeline.length, 3);
      expect(timeline[0].isEvent, false); // 8:00 - 10:00
      expect(timeline[1].isEvent, true); // 10:00 - 11:00
      expect(timeline[2].isEvent, false); // 11:00 - 22:00
    });

    test('back-to-back events have no gap', () {
      final events = [
        _makeEvent('1', 'A', 10, 0, 11, 0),
        _makeEvent('2', 'B', 11, 0, 12, 0),
      ];
      final timeline = service.buildTimeline(events: events, date: testDate);

      // gap + A + B + gap
      expect(timeline.length, 4);
      expect(timeline[0].isEvent, false);
      expect(timeline[1].isEvent, true);
      expect(timeline[1].event!.title, 'A');
      expect(timeline[2].isEvent, true);
      expect(timeline[2].event!.title, 'B');
      expect(timeline[3].isEvent, false);
    });

    test('detects conflicts', () {
      final events = [
        _makeEvent('1', 'A', 10, 0, 11, 30),
        _makeEvent('2', 'B', 11, 0, 12, 0),
      ];
      final timeline = service.buildTimeline(events: events, date: testDate);
      final conflicts = service.detectConflicts(timeline);

      expect(conflicts.length, 1);
      expect(conflicts[0].$1.event!.title, 'A');
      expect(conflicts[0].$2.event!.title, 'B');
    });

    test('summary computes correct stats', () {
      final events = [
        _makeEvent('1', 'A', 9, 0, 10, 0),
        _makeEvent('2', 'B', 14, 0, 15, 30),
      ];
      final timeline = service.buildTimeline(events: events, date: testDate);
      final summary = service.summarize(timeline, date: testDate);

      expect(summary.eventCount, 2);
      expect(summary.conflictCount, 0);
      expect(summary.busyTime.inMinutes, 150); // 60 + 90
      expect(summary.longestFreeBlock, isNotNull);
    });

    test('durationLabel formats correctly', () {
      final block = TimelineBlock(
        isEvent: false,
        start: DateTime(2026, 3, 2, 10, 0),
        end: DateTime(2026, 3, 2, 11, 30),
      );
      expect(block.durationLabel, '1h 30m');
    });

    test('formatAsText includes event details', () {
      final events = [
        _makeEvent('1', 'Standup', 9, 0, 9, 30,
            priority: EventPriority.high, location: 'Room 42'),
      ];
      final timeline = service.buildTimeline(events: events, date: testDate);
      final text = service.formatAsText(timeline);

      expect(text, contains('Standup'));
      expect(text, contains('[High]'));
      expect(text, contains('📍 Room 42'));
      expect(text, contains('Free'));
    });

    test('filters events to target date only', () {
      final events = [
        _makeEvent('1', 'Today', 10, 0, 11, 0),
        EventModel(
          id: '2',
          title: 'Tomorrow',
          date: DateTime(2026, 3, 3, 10, 0),
          endDate: DateTime(2026, 3, 3, 11, 0),
        ),
      ];
      final timeline = service.buildTimeline(events: events, date: testDate);
      final eventBlocks = timeline.where((b) => b.isEvent).toList();

      expect(eventBlocks.length, 1);
      expect(eventBlocks.first.event!.title, 'Today');
    });

    test('events without endDate get 30-minute default', () {
      final events = [
        EventModel(
          id: '1',
          title: 'Quick',
          date: DateTime(2026, 3, 2, 10, 0),
        ),
      ];
      final timeline = service.buildTimeline(events: events, date: testDate);
      final eventBlock = timeline.firstWhere((b) => b.isEvent);

      expect(eventBlock.duration.inMinutes, 30);
    });
  });
}
