import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/conflict_detector.dart';
import 'package:everything/models/event_model.dart';

/// Helper to create a simple event with start and optional end.
EventModel _event(
  String id,
  DateTime start, {
  DateTime? end,
  String title = '',
}) {
  return EventModel(
    id: id,
    title: title.isEmpty ? 'Event $id' : title,
    date: start,
    endDate: end,
  );
}

void main() {
  group('ConflictSeverity', () {
    test('labels are non-empty', () {
      for (final s in ConflictSeverity.values) {
        expect(s.label.isNotEmpty, isTrue);
        expect(s.description.isNotEmpty, isTrue);
      }
    });
  });

  group('severityFromGap', () {
    test('zero gap is exact', () {
      expect(
        ConflictDetector.severityFromGap(Duration.zero),
        ConflictSeverity.exact,
      );
    });

    test('5 minutes is high', () {
      expect(
        ConflictDetector.severityFromGap(const Duration(minutes: 5)),
        ConflictSeverity.high,
      );
    });

    test('15 minutes is high', () {
      expect(
        ConflictDetector.severityFromGap(const Duration(minutes: 15)),
        ConflictSeverity.high,
      );
    });

    test('30 minutes is moderate', () {
      expect(
        ConflictDetector.severityFromGap(const Duration(minutes: 30)),
        ConflictSeverity.moderate,
      );
    });

    test('60 minutes is moderate', () {
      expect(
        ConflictDetector.severityFromGap(const Duration(minutes: 60)),
        ConflictSeverity.moderate,
      );
    });

    test('90 minutes is low', () {
      expect(
        ConflictDetector.severityFromGap(const Duration(minutes: 90)),
        ConflictSeverity.low,
      );
    });

    test('negative gap uses absolute value', () {
      expect(
        ConflictDetector.severityFromGap(const Duration(minutes: -10)),
        ConflictSeverity.high,
      );
    });
  });

  group('EventConflict', () {
    test('description for exact conflict', () {
      final a = _event('1', DateTime(2026, 3, 16, 10), title: 'Meeting');
      final b = _event('2', DateTime(2026, 3, 16, 10), title: 'Call');
      final c = EventConflict(
        eventA: a,
        eventB: b,
        gap: Duration.zero,
        severity: ConflictSeverity.exact,
      );
      expect(c.isExact, isTrue);
      expect(c.description, contains('exact same time'));
    });

    test('description for minute gap', () {
      final a = _event('1', DateTime(2026, 3, 16, 10), title: 'A');
      final b = _event('2', DateTime(2026, 3, 16, 10, 10), title: 'B');
      final c = EventConflict(
        eventA: a,
        eventB: b,
        gap: const Duration(minutes: 10),
        severity: ConflictSeverity.high,
      );
      expect(c.description, contains('10 minutes apart'));
    });

    test('description for hour gap', () {
      final a = _event('1', DateTime(2026, 3, 16, 10), title: 'A');
      final b = _event('2', DateTime(2026, 3, 16, 12), title: 'B');
      final c = EventConflict(
        eventA: a,
        eventB: b,
        gap: const Duration(hours: 2),
        severity: ConflictSeverity.low,
      );
      expect(c.description, contains('2 hours apart'));
    });

    test('equality is order-independent', () {
      final a = _event('1', DateTime(2026, 3, 16, 10));
      final b = _event('2', DateTime(2026, 3, 16, 10));
      final c1 = EventConflict(
        eventA: a, eventB: b,
        gap: Duration.zero, severity: ConflictSeverity.exact,
      );
      final c2 = EventConflict(
        eventA: b, eventB: a,
        gap: Duration.zero, severity: ConflictSeverity.exact,
      );
      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });
  });

  group('ConflictDetector.checkPair', () {
    test('returns conflict for same-time events', () {
      const detector = ConflictDetector();
      final a = _event('1', DateTime(2026, 3, 16, 10));
      final b = _event('2', DateTime(2026, 3, 16, 10));
      final result = detector.checkPair(a, b);
      expect(result, isNotNull);
      expect(result!.severity, ConflictSeverity.exact);
    });

    test('returns null for distant events', () {
      const detector = ConflictDetector();
      final a = _event('1', DateTime(2026, 3, 16, 10));
      final b = _event('2', DateTime(2026, 3, 16, 14));
      expect(detector.checkPair(a, b), isNull);
    });

    test('detects overlap via endDate', () {
      const detector = ConflictDetector();
      // Event A: 10:00–11:30, Event B: 11:00 (point-in-time)
      final a = _event('1', DateTime(2026, 3, 16, 10),
          end: DateTime(2026, 3, 16, 11, 30));
      final b = _event('2', DateTime(2026, 3, 16, 11));
      final result = detector.checkPair(a, b);
      expect(result, isNotNull);
      expect(result!.severity, ConflictSeverity.exact); // overlap = zero gap
    });

    test('no conflict when events are beyond window', () {
      const detector = ConflictDetector(window: Duration(minutes: 30));
      final a = _event('1', DateTime(2026, 3, 16, 10));
      final b = _event('2', DateTime(2026, 3, 16, 10, 45));
      expect(detector.checkPair(a, b), isNull);
    });

    test('respects custom window', () {
      const detector = ConflictDetector(window: Duration(hours: 2));
      final a = _event('1', DateTime(2026, 3, 16, 10));
      final b = _event('2', DateTime(2026, 3, 16, 11, 30));
      expect(detector.checkPair(a, b), isNotNull);
    });
  });

  group('ConflictDetector.analyze', () {
    test('no conflicts in empty list', () {
      const detector = ConflictDetector();
      final report = detector.analyze([], expandRecurring: false);
      expect(report.hasConflicts, isFalse);
      expect(report.conflictCount, 0);
      expect(report.totalEvents, 0);
    });

    test('finds exact conflict', () {
      const detector = ConflictDetector();
      final events = [
        _event('1', DateTime(2026, 3, 16, 10)),
        _event('2', DateTime(2026, 3, 16, 10)),
      ];
      final report = detector.analyze(events, expandRecurring: false);
      expect(report.hasConflicts, isTrue);
      expect(report.conflictCount, 1);
      expect(report.conflicts.first.severity, ConflictSeverity.exact);
    });

    test('reports correct affected events', () {
      const detector = ConflictDetector();
      final events = [
        _event('1', DateTime(2026, 3, 16, 10)),
        _event('2', DateTime(2026, 3, 16, 10)),
        _event('3', DateTime(2026, 3, 16, 20)), // no conflict
      ];
      final report = detector.analyze(events, expandRecurring: false);
      expect(report.affectedEventCount, 2);
      expect(report.conflictedEventIds, containsAll(['1', '2']));
      expect(report.conflictedEventIds, isNot(contains('3')));
    });

    test('mostSevere returns exact over moderate', () {
      const detector = ConflictDetector();
      final events = [
        _event('1', DateTime(2026, 3, 16, 10)),
        _event('2', DateTime(2026, 3, 16, 10)),     // exact with 1
        _event('3', DateTime(2026, 3, 16, 10, 30)), // moderate with 2
      ];
      final report = detector.analyze(events, expandRecurring: false);
      expect(report.mostSevere!.severity, ConflictSeverity.exact);
    });

    test('no conflicts among well-spaced events', () {
      const detector = ConflictDetector();
      final events = [
        _event('1', DateTime(2026, 3, 16, 8)),
        _event('2', DateTime(2026, 3, 16, 12)),
        _event('3', DateTime(2026, 3, 16, 16)),
      ];
      final report = detector.analyze(events, expandRecurring: false);
      expect(report.hasConflicts, isFalse);
    });
  });

  group('ConflictDetector.findConflictsFor', () {
    test('finds all conflicts for a target event', () {
      const detector = ConflictDetector();
      final target = _event('t', DateTime(2026, 3, 16, 10));
      final others = [
        _event('1', DateTime(2026, 3, 16, 10)),
        _event('2', DateTime(2026, 3, 16, 10, 20)),
        _event('3', DateTime(2026, 3, 16, 20)), // too far
      ];
      final conflicts = detector.findConflictsFor(target, others);
      expect(conflicts.length, 2);
    });

    test('skips self by id', () {
      const detector = ConflictDetector();
      final target = _event('t', DateTime(2026, 3, 16, 10));
      final others = [target]; // same id
      expect(detector.findConflictsFor(target, others), isEmpty);
    });
  });

  group('ConflictDetector.wouldConflict', () {
    test('returns true when conflicts exist', () {
      const detector = ConflictDetector();
      final newEvent = _event('new', DateTime(2026, 3, 16, 10));
      final existing = [_event('1', DateTime(2026, 3, 16, 10, 15))];
      expect(detector.wouldConflict(newEvent, existing), isTrue);
    });

    test('returns false when no conflicts', () {
      const detector = ConflictDetector();
      final newEvent = _event('new', DateTime(2026, 3, 16, 10));
      final existing = [_event('1', DateTime(2026, 3, 16, 14))];
      expect(detector.wouldConflict(newEvent, existing), isFalse);
    });
  });

  group('ConflictDetector.suggestAlternatives', () {
    test('returns requested number of alternatives', () {
      const detector = ConflictDetector();
      final event = _event('e', DateTime(2026, 3, 16, 10));
      final existing = [_event('1', DateTime(2026, 3, 16, 10))];
      final alts = detector.suggestAlternatives(event, existing, count: 3);
      expect(alts.length, 3);
      // None of the alternatives should conflict
      for (final alt in alts) {
        final shifted = event.copyWith(date: alt);
        expect(detector.wouldConflict(shifted, existing), isFalse);
      }
    });

    test('returns empty when no conflicts to avoid', () {
      const detector = ConflictDetector();
      final event = _event('e', DateTime(2026, 3, 16, 10));
      // Event already has no conflicts — first suggestion at +30min
      final alts = detector.suggestAlternatives(event, [], count: 2);
      expect(alts.length, 2);
    });
  });

  group('ConflictReport', () {
    test('summary for no conflicts', () {
      final report = ConflictReport(
        conflicts: [],
        totalEvents: 5,
        analyzedAt: DateTime(2026, 3, 16),
      );
      expect(report.summary, contains('No conflicts'));
      expect(report.busiestEventId, isNull);
    });

    test('bySeverity groups correctly', () {
      const detector = ConflictDetector();
      final events = [
        _event('1', DateTime(2026, 3, 16, 10)),
        _event('2', DateTime(2026, 3, 16, 10)),     // exact
        _event('3', DateTime(2026, 3, 16, 10, 30)), // moderate
      ];
      final report = detector.analyze(events, expandRecurring: false);
      final grouped = report.bySeverity;
      expect(grouped.containsKey(ConflictSeverity.exact), isTrue);
    });

    test('conflictsFor filters by event id', () {
      const detector = ConflictDetector();
      final events = [
        _event('1', DateTime(2026, 3, 16, 10)),
        _event('2', DateTime(2026, 3, 16, 10)),
        _event('3', DateTime(2026, 3, 16, 20)),
      ];
      final report = detector.analyze(events, expandRecurring: false);
      expect(report.conflictsFor('1').length, 1);
      expect(report.hasConflictsFor('3'), isFalse);
    });

    test('busiestEventId finds most conflicted event', () {
      const detector = ConflictDetector();
      final events = [
        _event('hub', DateTime(2026, 3, 16, 10)),
        _event('a', DateTime(2026, 3, 16, 10)),
        _event('b', DateTime(2026, 3, 16, 10, 10)),
      ];
      final report = detector.analyze(events, expandRecurring: false);
      // 'hub' conflicts with both 'a' and 'b'
      expect(report.busiestEventId, 'hub');
    });
  });

  group('_computeGap with endDate ranges', () {
    test('non-overlapping ranges compute correct gap', () {
      const detector = ConflictDetector(window: Duration(hours: 2));
      // A: 10:00–11:00, B: 11:30–12:30 → gap = 30 min
      final a = _event('1', DateTime(2026, 3, 16, 10),
          end: DateTime(2026, 3, 16, 11));
      final b = _event('2', DateTime(2026, 3, 16, 11, 30),
          end: DateTime(2026, 3, 16, 12, 30));
      final result = detector.checkPair(a, b);
      expect(result, isNotNull);
      expect(result!.gap, const Duration(minutes: 30));
    });

    test('overlapping ranges have zero gap', () {
      const detector = ConflictDetector();
      // A: 10:00–11:00, B: 10:30–11:30 → overlap
      final a = _event('1', DateTime(2026, 3, 16, 10),
          end: DateTime(2026, 3, 16, 11));
      final b = _event('2', DateTime(2026, 3, 16, 10, 30),
          end: DateTime(2026, 3, 16, 11, 30));
      final result = detector.checkPair(a, b);
      expect(result, isNotNull);
      expect(result!.gap, Duration.zero);
      expect(result.severity, ConflictSeverity.exact);
    });
  });
}
