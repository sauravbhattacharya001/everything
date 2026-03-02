import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/event_deduplication_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';
import 'package:everything/models/event_checklist.dart';
import 'package:everything/models/recurrence_rule.dart';

void main() {
  late EventDeduplicationService service;

  setUp(() {
    service = EventDeduplicationService();
  });

  /// Helper to create a simple event at a given time.
  EventModel _event(
    String id,
    String title,
    DateTime date, {
    DateTime? endDate,
    String description = '',
    String location = '',
    EventPriority priority = EventPriority.medium,
    List<EventTag>? tags,
    RecurrenceRule? recurrence,
    EventChecklist? checklist,
  }) {
    return EventModel(
      id: id,
      title: title,
      date: date,
      endDate: endDate,
      description: description,
      location: location,
      priority: priority,
      tags: tags,
      recurrence: recurrence,
      checklist: checklist,
    );
  }

  final monday = DateTime(2026, 3, 2, 9, 0);

  // ─── Empty / Single Event ────────────────────────────────────

  group('Edge cases', () {
    test('empty list returns empty report', () {
      final report = service.scan([]);
      expect(report.totalEvents, 0);
      expect(report.duplicateCount, 0);
      expect(report.hasDuplicates, false);
    });

    test('single event returns no duplicates', () {
      final report = service.scan([
        _event('1', 'Meeting', monday),
      ]);
      expect(report.totalEvents, 1);
      expect(report.duplicateCount, 0);
    });

    test('two unrelated events are not duplicates', () {
      final report = service.scan([
        _event('1', 'Team Standup', monday),
        _event('2', 'Grocery Shopping', monday.add(const Duration(hours: 3))),
      ]);
      expect(report.duplicateCount, 0);
    });
  });

  // ─── Exact Duplicates ────────────────────────────────────────

  group('Exact duplicates', () {
    test('identical title and overlapping time', () {
      final report = service.scan([
        _event('1', 'Team Meeting', monday,
            endDate: monday.add(const Duration(hours: 1))),
        _event('2', 'Team Meeting', monday,
            endDate: monday.add(const Duration(hours: 1))),
      ]);
      expect(report.duplicateCount, 1);
      expect(report.matches.first.kind, DuplicateKind.exactDuplicate);
      expect(report.matches.first.similarity, greaterThanOrEqualTo(0.95));
    });

    test('identical title with partial overlap', () {
      final report = service.scan([
        _event('1', 'Design Review', monday,
            endDate: monday.add(const Duration(hours: 1))),
        _event('2', 'Design Review',
            monday.add(const Duration(minutes: 30)),
            endDate: monday.add(const Duration(hours: 1, minutes: 30))),
      ]);
      expect(report.duplicateCount, 1);
      expect(report.matches.first.kind, DuplicateKind.exactDuplicate);
    });
  });

  // ─── Near Duplicates ─────────────────────────────────────────

  group('Near duplicates', () {
    test('similar titles with typo', () {
      final report = service.scan([
        _event('1', 'Team Meeting', monday),
        _event('2', 'Team Meating', monday.add(const Duration(minutes: 5))),
      ]);
      expect(report.duplicateCount, 1);
      final match = report.matches.first;
      expect(match.kind, DuplicateKind.nearDuplicate);
      expect(match.similarity, greaterThan(0.5));
    });

    test('case-insensitive title matching', () {
      final report = service.scan([
        _event('1', 'weekly standup', monday),
        _event('2', 'Weekly Standup', monday.add(const Duration(minutes: 10))),
      ]);
      expect(report.duplicateCount, 1);
      expect(report.matches.first.kind, DuplicateKind.exactDuplicate);
    });

    test('completely different titles are not matched', () {
      final report = service.scan([
        _event('1', 'Yoga Class', monday),
        _event('2', 'Budget Review', monday.add(const Duration(minutes: 30))),
      ]);
      expect(report.duplicateCount, 0);
    });

    test('similar titles but too far apart are not matched', () {
      final strict = EventDeduplicationService(
        config: const DeduplicationConfig(maxTimeGapMinutes: 60),
      );
      final report = strict.scan([
        _event('1', 'Meeting', monday),
        _event('2', 'Meeting',
            monday.add(const Duration(hours: 5))),
      ]);
      // Different day check might catch if same day, but with strict
      // time gap the score should be low
      // This tests that maxTimeGapMinutes is respected
      for (final match in report.matches) {
        expect(match.kind, isNot(DuplicateKind.nearDuplicate));
      }
    });
  });

  // ─── Same-Day Same-Title ─────────────────────────────────────

  group('Same-day same-title', () {
    test('same title at different times on same day', () {
      final report = service.scan([
        _event('1', 'Coffee Break', DateTime(2026, 3, 2, 10, 0)),
        _event('2', 'Coffee Break', DateTime(2026, 3, 2, 15, 0)),
      ]);
      expect(report.duplicateCount, 1);
      expect(report.matches.first.kind, DuplicateKind.sameDaySameTitle);
    });

    test('same title on different days is not same-day repeat', () {
      final report = service.scan([
        _event('1', 'Daily Standup', DateTime(2026, 3, 2, 9, 0)),
        _event('2', 'Daily Standup', DateTime(2026, 3, 3, 9, 0)),
      ]);
      // Should not be flagged as same-day repeat
      for (final match in report.matches) {
        expect(match.kind, isNot(DuplicateKind.sameDaySameTitle));
      }
    });
  });

  // ─── Content Duplicates ──────────────────────────────────────

  group('Content duplicates', () {
    test('different titles but same description and location', () {
      final report = service.scan([
        _event('1', 'Q1 Review', monday,
            description: 'Quarterly business review with all teams',
            location: 'Building C Room 301'),
        _event('2', 'Quarterly Review', monday.add(const Duration(minutes: 30)),
            description: 'Quarterly business review with all teams',
            location: 'Building C Room 301'),
      ]);
      expect(report.duplicateCount, greaterThanOrEqualTo(1));
    });

    test('empty descriptions do not trigger content duplicate', () {
      final report = service.scan([
        _event('1', 'Alpha', monday),
        _event('2', 'Beta', monday.add(const Duration(minutes: 15))),
      ]);
      // Different titles, empty descriptions — should not match
      expect(report.duplicateCount, 0);
    });
  });

  // ─── Recurrence Overlap ──────────────────────────────────────

  group('Recurrence overlap', () {
    test('manual event duplicating recurring event', () {
      final recurring = _event(
        'r1', 'Weekly Team Meeting', monday,
        endDate: monday.add(const Duration(hours: 1)),
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
        ),
      );
      final manual = _event(
        'm1', 'Weekly Team Meeting',
        monday, // Same day/time
        endDate: monday.add(const Duration(hours: 1)),
      );
      final report = service.scan([recurring, manual]);
      expect(report.duplicateCount, 1);
      expect(report.matches.first.kind, DuplicateKind.recurrenceOverlap);
    });

    test('no overlap when both are recurring', () {
      final a = _event(
        'r1', 'Standup', monday,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        ),
      );
      final b = _event(
        'r2', 'Standup', monday,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        ),
      );
      final report = service.scan([a, b]);
      // Both recurring — recurrence overlap detection skips
      for (final match in report.matches) {
        expect(match.kind, isNot(DuplicateKind.recurrenceOverlap));
      }
    });
  });

  // ─── Configuration ──────────────────────────────────────────

  group('Configuration', () {
    test('strict config catches fewer duplicates', () {
      final strict = EventDeduplicationService(
        config: DeduplicationConfig.strict,
      );
      final lenient = EventDeduplicationService(
        config: DeduplicationConfig.lenient,
      );
      final events = [
        _event('1', 'Team Sync', monday),
        _event('2', 'Team Synch', monday.add(const Duration(minutes: 90))),
        _event('3', 'Team sync meeting', monday.add(const Duration(minutes: 45))),
      ];
      final strictReport = strict.scan(events);
      final lenientReport = lenient.scan(events);
      expect(lenientReport.duplicateCount,
          greaterThanOrEqualTo(strictReport.duplicateCount));
    });

    test('disabled features are not detected', () {
      final noSameDay = EventDeduplicationService(
        config: const DeduplicationConfig(detectSameDayRepeats: false),
      );
      final report = noSameDay.scan([
        _event('1', 'Lunch', DateTime(2026, 3, 2, 12, 0)),
        _event('2', 'Lunch', DateTime(2026, 3, 2, 18, 0)),
      ]);
      for (final match in report.matches) {
        expect(match.kind, isNot(DuplicateKind.sameDaySameTitle));
      }
    });
  });

  // ─── Report ──────────────────────────────────────────────────

  group('Report', () {
    test('kind breakdown is accurate', () {
      final report = service.scan([
        _event('1', 'Meeting', monday,
            endDate: monday.add(const Duration(hours: 1))),
        _event('2', 'Meeting', monday,
            endDate: monday.add(const Duration(hours: 1))),
        _event('3', 'Coffee', DateTime(2026, 3, 2, 10, 0)),
        _event('4', 'Coffee', DateTime(2026, 3, 2, 15, 0)),
      ]);
      expect(report.duplicateCount, 2);
      expect(report.kindBreakdown.values.fold(0, (a, b) => a + b), 2);
    });

    test('summary string for no duplicates', () {
      final report = service.scan([
        _event('1', 'Unique Event', monday),
      ]);
      expect(report.summary, contains('No duplicates'));
    });

    test('summary string for duplicates found', () {
      final report = service.scan([
        _event('1', 'Meeting', monday,
            endDate: monday.add(const Duration(hours: 1))),
        _event('2', 'Meeting', monday,
            endDate: monday.add(const Duration(hours: 1))),
      ]);
      expect(report.summary, contains('duplicate'));
    });

    test('estimated time savings calculation', () {
      final report = service.scan([
        _event('1', 'Sync', monday,
            endDate: monday.add(const Duration(minutes: 60))),
        _event('2', 'Sync', monday.add(const Duration(minutes: 10)),
            endDate: monday.add(const Duration(minutes: 40))),
      ]);
      expect(report.estimatedTimeSavingsMinutes, greaterThan(0));
    });

    test('frequent duplicate IDs tracked', () {
      final report = service.scan([
        _event('hub', 'Status Update', monday,
            endDate: monday.add(const Duration(hours: 1))),
        _event('a', 'Status Update', monday,
            endDate: monday.add(const Duration(hours: 1))),
        _event('b', 'Status Update',
            monday.add(const Duration(minutes: 5)),
            endDate: monday.add(const Duration(hours: 1, minutes: 5))),
      ]);
      if (report.duplicateCount >= 2) {
        expect(report.frequentDuplicateIds, isNotEmpty);
      }
    });
  });

  // ─── Utility Methods ────────────────────────────────────────

  group('Utility methods', () {
    test('checkPair returns match for duplicates', () {
      final a = _event('1', 'Sprint Planning', monday);
      final b = _event('2', 'Sprint Planning',
          monday.add(const Duration(minutes: 5)));
      final match = service.checkPair(a, b);
      expect(match, isNotNull);
      expect(match!.similarity, greaterThan(0.5));
    });

    test('checkPair returns null for unrelated events', () {
      final a = _event('1', 'Yoga', monday);
      final b = _event('2', 'Dentist', monday.add(const Duration(hours: 5)));
      final match = service.checkPair(a, b);
      expect(match, isNull);
    });

    test('findDuplicatesOf returns matches for target', () {
      final target = _event('t', 'Team Retro', monday);
      final events = [
        target,
        _event('1', 'Team Retro', monday.add(const Duration(minutes: 30))),
        _event('2', 'Unrelated', monday.add(const Duration(hours: 1))),
        _event('3', 'Team Retrospective',
            monday.add(const Duration(minutes: 15))),
      ];
      final matches = service.findDuplicatesOf(target, events);
      expect(matches.length, greaterThanOrEqualTo(1));
      // Should not include self
      expect(matches.any((m) => m.eventB.id == 't'), false);
    });

    test('scanHighConfidence filters low-confidence matches', () {
      final events = [
        _event('1', 'Meeting', monday,
            endDate: monday.add(const Duration(hours: 1))),
        _event('2', 'Meeting', monday,
            endDate: monday.add(const Duration(hours: 1))),
      ];
      final highConf = service.scanHighConfidence(events);
      for (final match in highConf) {
        expect(match.similarity, greaterThanOrEqualTo(0.8));
      }
    });
  });

  // ─── Merge Suggestion ───────────────────────────────────────

  group('Merge action suggestion', () {
    test('prefers event with more description', () {
      final report = service.scan([
        _event('1', 'Planning', monday,
            endDate: monday.add(const Duration(hours: 1)),
            description: 'Detailed planning session for Q2 roadmap'),
        _event('2', 'Planning', monday,
            endDate: monday.add(const Duration(hours: 1))),
      ]);
      expect(report.duplicateCount, 1);
      expect(report.matches.first.suggestedAction, MergeAction.keepFirst);
    });

    test('prefers event with tags when other has none', () {
      final report = service.scan([
        _event('1', 'Review', monday,
            endDate: monday.add(const Duration(hours: 1))),
        _event('2', 'Review', monday,
            endDate: monday.add(const Duration(hours: 1)),
            tags: [const EventTag(name: 'Work', color: 'blue')]),
      ]);
      expect(report.duplicateCount, 1);
      expect(report.matches.first.suggestedAction, MergeAction.keepSecond);
    });

    test('suggests merge when events are equally rich', () {
      final report = service.scan([
        _event('1', 'Sync', monday,
            endDate: monday.add(const Duration(hours: 1)),
            description: 'Team sync'),
        _event('2', 'Sync', monday,
            endDate: monday.add(const Duration(hours: 1)),
            location: 'Room 4B'),
      ]);
      expect(report.duplicateCount, 1);
      // Both have one extra field — should suggest merge
      expect(report.matches.first.suggestedAction, MergeAction.merge);
    });
  });

  // ─── DuplicateKind ──────────────────────────────────────────

  group('DuplicateKind', () {
    test('labels are non-empty', () {
      for (final kind in DuplicateKind.values) {
        expect(kind.label, isNotEmpty);
        expect(kind.emoji, isNotEmpty);
      }
    });
  });

  // ─── MergeAction ────────────────────────────────────────────

  group('MergeAction', () {
    test('labels are non-empty', () {
      for (final action in MergeAction.values) {
        expect(action.label, isNotEmpty);
      }
    });
  });

  // ─── DuplicateMatch ─────────────────────────────────────────

  group('DuplicateMatch', () {
    test('confidence levels', () {
      final high = DuplicateMatch(
        eventA: _event('1', 'A', monday),
        eventB: _event('2', 'B', monday),
        similarity: 0.85,
        kind: DuplicateKind.exactDuplicate,
        reason: 'test',
        suggestedAction: MergeAction.merge,
      );
      expect(high.isHighConfidence, true);
      expect(high.isMediumConfidence, false);

      final medium = DuplicateMatch(
        eventA: _event('1', 'A', monday),
        eventB: _event('2', 'B', monday),
        similarity: 0.65,
        kind: DuplicateKind.nearDuplicate,
        reason: 'test',
        suggestedAction: MergeAction.merge,
      );
      expect(medium.isHighConfidence, false);
      expect(medium.isMediumConfidence, true);
    });

    test('toString is readable', () {
      final match = DuplicateMatch(
        eventA: _event('1', 'Sprint Planning', monday),
        eventB: _event('2', 'Sprint Planing', monday),
        similarity: 0.92,
        kind: DuplicateKind.nearDuplicate,
        reason: 'test',
        suggestedAction: MergeAction.keepFirst,
      );
      expect(match.toString(), contains('Sprint Planning'));
      expect(match.toString(), contains('92%'));
    });
  });

  // ─── Stress Test ────────────────────────────────────────────

  group('Performance', () {
    test('handles 100 events without error', () {
      final events = List.generate(100, (i) {
        final hour = (i % 10) + 8;
        final day = (i ~/ 10) + 1;
        return _event(
          'e$i',
          i % 5 == 0 ? 'Repeated Meeting' : 'Event $i',
          DateTime(2026, 3, day, hour, 0),
          endDate: DateTime(2026, 3, day, hour + 1, 0),
        );
      });
      final report = service.scan(events);
      expect(report.totalEvents, 100);
      // Should find some duplicates among the "Repeated Meeting" entries
      expect(report.duplicateCount, greaterThan(0));
    });
  });
}
