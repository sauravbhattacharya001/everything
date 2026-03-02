import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/weekly_report_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';
import 'package:everything/models/event_checklist.dart';

void main() {
  late WeeklyReportService service;

  setUp(() {
    service = WeeklyReportService();
  });

  EventModel _makeEvent(String id, DateTime date, {
    EventPriority priority = EventPriority.medium,
    List<EventTag>? tags,
    EventChecklist? checklist,
  }) {
    return EventModel(
      id: id,
      title: 'Event $id',
      date: date,
      priority: priority,
      tags: tags,
      checklist: checklist,
    );
  }

  group('WeeklyReportService', () {
    test('generates report for a week with events', () {
      // Monday March 2, 2026
      final monday = DateTime(2026, 3, 2);
      final events = [
        _makeEvent('1', monday, priority: EventPriority.high),
        _makeEvent('2', monday.add(const Duration(days: 1)), priority: EventPriority.low),
        _makeEvent('3', monday.add(const Duration(days: 2)),
          tags: [const EventTag(name: 'work', color: 'blue')]),
        _makeEvent('4', monday.add(const Duration(days: 2)),
          tags: [const EventTag(name: 'work', color: 'blue')]),
      ];

      final report = service.generateReport(events, referenceDate: monday);

      expect(report.totalEvents, 4);
      expect(report.priorityBreakdown[EventPriority.high], 1);
      expect(report.priorityBreakdown[EventPriority.low], 1);
      expect(report.priorityBreakdown[EventPriority.medium], 2);
      expect(report.busiestDay, 'Wednesday');
      expect(report.busiestDayCount, 2);
      expect(report.topTags.first.key, 'work');
      expect(report.topTags.first.value, 2);
    });

    test('returns empty report for week with no events', () {
      final monday = DateTime(2026, 3, 2);
      final report = service.generateReport([], referenceDate: monday);

      expect(report.totalEvents, 0);
      expect(report.priorityBreakdown, isEmpty);
      expect(report.busiestDay, 'None');
    });

    test('computes week-over-week change', () {
      final thisMonday = DateTime(2026, 3, 2);
      final lastMonday = DateTime(2026, 2, 23);
      final events = [
        _makeEvent('1', thisMonday),
        _makeEvent('2', thisMonday.add(const Duration(days: 1))),
        _makeEvent('3', thisMonday.add(const Duration(days: 2))),
        // Previous week
        _makeEvent('4', lastMonday),
        _makeEvent('5', lastMonday.add(const Duration(days: 1))),
      ];

      final report = service.generateReport(events, referenceDate: thisMonday);

      expect(report.totalEvents, 3);
      expect(report.previousWeekTotal, 2);
      expect(report.weekOverWeekChange, 1);
      expect(report.trending, true);
    });

    test('computes checklist completion rate', () {
      final monday = DateTime(2026, 3, 2);
      final events = [
        _makeEvent('1', monday, checklist: const EventChecklist(items: [
          ChecklistItem(text: 'A', isChecked: true),
          ChecklistItem(text: 'B', isChecked: false),
          ChecklistItem(text: 'C', isChecked: true),
        ])),
      ];

      final report = service.generateReport(events, referenceDate: monday);

      expect(report.checklistCompletionRate, closeTo(0.667, 0.01));
    });

    test('formatReport produces readable output', () {
      final monday = DateTime(2026, 3, 2);
      final events = [
        _makeEvent('1', monday, priority: EventPriority.urgent),
      ];

      final report = service.generateReport(events, referenceDate: monday);
      final text = service.formatReport(report);

      expect(text, contains('Weekly Report'));
      expect(text, contains('Total Events: 1'));
      expect(text, contains('Urgent: 1'));
      expect(text, contains('Monday'));
    });
  });
}
