import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/recurrence_rule.dart';
import 'package:everything/core/services/conflict_detector.dart';

EventModel _event(
  String id,
  DateTime date, {
  String title = 'Event',
  EventPriority priority = EventPriority.medium,
  DateTime? endDate,
}) {
  return EventModel(
    id: id,
    title: title.isEmpty ? 'Event $id' : title,
    date: date,
    endDate: endDate,
    priority: priority,
  );
}

void main() {
  // ============================================================
  // ConflictSeverity Tests
  // ============================================================

  group('ConflictSeverity', () {
    test('label and description are non-empty for all values', () {
      for (final severity in ConflictSeverity.values) {
        expect(severity.label, isNotEmpty);
        expect(severity.description, isNotEmpty);
      }
    });

    test('enum has 4 values', () {
      expect(ConflictSeverity.values.length, 4);
    });

    test('ordering: exact > high > moderate > low via index', () {
      expect(ConflictSeverity.exact.index, lessThan(ConflictSeverity.high.index));
      expect(ConflictSeverity.high.index, lessThan(ConflictSeverity.moderate.index));
      expect(ConflictSeverity.moderate.index, lessThan(ConflictSeverity.low.index));
    });

    test('severityFromGap static method', () {
      expect(
        ConflictDetector.severityFromGap(Duration.zero),
        ConflictSeverity.exact,
      );
      expect(
        ConflictDetector.severityFromGap(const Duration(minutes: 5)),
        ConflictSeverity.high,
      );
      expect(
        ConflictDetector.severityFromGap(const Duration(minutes: 15)),
        ConflictSeverity.high,
      );
      expect(
        ConflictDetector.severityFromGap(const Duration(minutes: 16)),
        ConflictSeverity.moderate,
      );
      expect(
        ConflictDetector.severityFromGap(const Duration(hours: 1)),
        ConflictSeverity.moderate,
      );
      expect(
        ConflictDetector.severityFromGap(const Duration(hours: 1, minutes: 1)),
        ConflictSeverity.low,
      );
    });
  });

  // ============================================================
  // EventConflict Tests
  // ============================================================

  group('EventConflict', () {
    final base = DateTime(2026, 3, 1, 10, 0);

    test('construction and field access', () {
      final a = _event('1', base, title: 'Meeting');
      final b = _event('2', base.add(const Duration(minutes: 10)), title: 'Standup');
      final conflict = EventConflict(
        eventA: a,
        eventB: b,
        gap: const Duration(minutes: 10),
        severity: ConflictSeverity.high,
      );
      expect(conflict.eventA.id, '1');
      expect(conflict.eventB.id, '2');
      expect(conflict.gap, const Duration(minutes: 10));
      expect(conflict.severity, ConflictSeverity.high);
    });

    test('isExact for zero gap', () {
      final a = _event('1', base);
      final b = _event('2', base);
      final conflict = EventConflict(
        eventA: a,
        eventB: b,
        gap: Duration.zero,
        severity: ConflictSeverity.exact,
      );
      expect(conflict.isExact, true);
    });

    test('isExact false for non-zero gap', () {
      final a = _event('1', base);
      final b = _event('2', base.add(const Duration(minutes: 5)));
      final conflict = EventConflict(
        eventA: a,
        eventB: b,
        gap: const Duration(minutes: 5),
        severity: ConflictSeverity.high,
      );
      expect(conflict.isExact, false);
    });

    test('description contains both event titles', () {
      final a = _event('1', base, title: 'Meeting');
      final b = _event('2', base.add(const Duration(minutes: 10)), title: 'Standup');
      final conflict = EventConflict(
        eventA: a,
        eventB: b,
        gap: const Duration(minutes: 10),
        severity: ConflictSeverity.high,
      );
      expect(conflict.description, contains('Meeting'));
      expect(conflict.description, contains('Standup'));
      expect(conflict.description, contains('10 minutes'));
    });

    test('description for exact conflict', () {
      final a = _event('1', base, title: 'Meeting');
      final b = _event('2', base, title: 'Standup');
      final conflict = EventConflict(
        eventA: a,
        eventB: b,
        gap: Duration.zero,
        severity: ConflictSeverity.exact,
      );
      expect(conflict.description, contains('exact same time'));
    });

    test('equality by event IDs', () {
      final a = _event('1', base);
      final b = _event('2', base);
      final c1 = EventConflict(
        eventA: a,
        eventB: b,
        gap: Duration.zero,
        severity: ConflictSeverity.exact,
      );
      final c2 = EventConflict(
        eventA: a,
        eventB: b,
        gap: Duration.zero,
        severity: ConflictSeverity.exact,
      );
      // Also order-independent
      final c3 = EventConflict(
        eventA: b,
        eventB: a,
        gap: Duration.zero,
        severity: ConflictSeverity.exact,
      );
      expect(c1, equals(c2));
      expect(c1, equals(c3));
    });

    test('hashCode consistency', () {
      final a = _event('1', base);
      final b = _event('2', base);
      final c1 = EventConflict(
        eventA: a,
        eventB: b,
        gap: Duration.zero,
        severity: ConflictSeverity.exact,
      );
      final c2 = EventConflict(
        eventA: b,
        eventB: a,
        gap: Duration.zero,
        severity: ConflictSeverity.exact,
      );
      expect(c1.hashCode, equals(c2.hashCode));
    });
  });

  // ============================================================
  // ConflictDetector - checkPair Tests
  // ============================================================

  group('ConflictDetector - checkPair', () {
    final detector = const ConflictDetector();
    final base = DateTime(2026, 3, 1, 10, 0);

    test('same time → exact conflict', () {
      final a = _event('1', base);
      final b = _event('2', base);
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.exact);
      expect(conflict.isExact, true);
    });

    test('10 min apart → high severity', () {
      final a = _event('1', base);
      final b = _event('2', base.add(const Duration(minutes: 10)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.high);
    });

    test('30 min apart → moderate severity', () {
      final a = _event('1', base);
      final b = _event('2', base.add(const Duration(minutes: 30)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.moderate);
    });

    test('59 min apart → moderate', () {
      final a = _event('1', base);
      final b = _event('2', base.add(const Duration(minutes: 59)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.moderate);
    });

    test('exactly 1 hour → still conflict (at boundary)', () {
      final a = _event('1', base);
      final b = _event('2', base.add(const Duration(hours: 1)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.moderate);
    });

    test('61 min apart with default window → null (no conflict)', () {
      final a = _event('1', base);
      final b = _event('2', base.add(const Duration(minutes: 61)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNull);
    });

    test('custom window (2 hours) catches 90-min gap', () {
      final customDetector = const ConflictDetector(
        window: Duration(hours: 2),
      );
      final a = _event('1', base);
      final b = _event('2', base.add(const Duration(minutes: 90)));
      final conflict = customDetector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.low);
    });

    test('reversed order gives same result', () {
      final a = _event('1', base);
      final b = _event('2', base.add(const Duration(minutes: 30)));
      final c1 = detector.checkPair(a, b);
      final c2 = detector.checkPair(b, a);
      expect(c1, isNotNull);
      expect(c2, isNotNull);
      expect(c1!.severity, c2!.severity);
    });
  });

  // ============================================================
  // ConflictDetector - analyze Tests
  // ============================================================

  group('ConflictDetector - analyze', () {
    final detector = const ConflictDetector();
    final base = DateTime(2026, 3, 1, 10, 0);

    test('empty list → no conflicts', () {
      final report = detector.analyze([]);
      expect(report.hasConflicts, false);
      expect(report.conflictCount, 0);
      expect(report.totalEvents, 0);
    });

    test('single event → no conflicts', () {
      final report = detector.analyze([_event('1', base)]);
      expect(report.hasConflicts, false);
      expect(report.conflictCount, 0);
    });

    test('two conflicting events → 1 conflict', () {
      final events = [
        _event('1', base),
        _event('2', base.add(const Duration(minutes: 30))),
      ];
      final report = detector.analyze(events);
      expect(report.conflictCount, 1);
      expect(report.hasConflicts, true);
    });

    test('two non-conflicting events → 0 conflicts', () {
      final events = [
        _event('1', base),
        _event('2', base.add(const Duration(hours: 2))),
      ];
      final report = detector.analyze(events);
      expect(report.conflictCount, 0);
    });

    test('three events, two conflict → 1 conflict', () {
      final events = [
        _event('1', base),
        _event('2', base.add(const Duration(minutes: 30))),
        _event('3', base.add(const Duration(hours: 5))),
      ];
      final report = detector.analyze(events);
      expect(report.conflictCount, 1);
    });

    test('chain of conflicts (A-B, B-C but not A-C)', () {
      final events = [
        _event('A', base),
        _event('B', base.add(const Duration(minutes: 50))),
        _event('C', base.add(const Duration(minutes: 100))),
      ];
      final report = detector.analyze(events);
      // A-B: 50 min → conflict, B-C: 50 min → conflict, A-C: 100 min → no
      expect(report.conflictCount, 2);
    });

    test('all at same time → n*(n-1)/2 conflicts', () {
      final events = [
        _event('1', base),
        _event('2', base),
        _event('3', base),
        _event('4', base),
      ];
      final report = detector.analyze(events);
      // 4 choose 2 = 6
      expect(report.conflictCount, 6);
    });

    test('report fields (totalEvents, analyzedAt, etc.)', () {
      final events = [
        _event('1', base),
        _event('2', base.add(const Duration(minutes: 10))),
      ];
      final before = DateTime.now();
      final report = detector.analyze(events);
      expect(report.totalEvents, 2);
      expect(report.analyzedAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
    });

    test('expanding recurring events finds future conflicts', () {
      final recurring = EventModel(
        id: 'r1',
        title: 'Daily',
        date: base,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        ),
      );
      // Place an event that conflicts with the second occurrence (next day same time)
      final other = _event('o1', base.add(const Duration(days: 1)));
      final report = detector.analyze(
        [recurring, other],
        expandRecurring: true,
        maxOccurrences: 5,
      );
      // recurring generates occurrences at day+1, day+2, etc.
      // o1 is at day+1 same time → exact conflict with occurrence r1_1
      expect(report.hasConflicts, true);
      final exactConflicts = report.bySeverity[ConflictSeverity.exact];
      expect(exactConflicts, isNotNull);
      expect(exactConflicts!.isNotEmpty, true);
    });

    test('expandRecurring=false skips recurrence expansion', () {
      final recurring = EventModel(
        id: 'r1',
        title: 'Daily',
        date: base,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        ),
      );
      // An event at day+1 — would conflict only with expanded occurrence
      final other = _event('o1', base.add(const Duration(days: 1)));
      final report = detector.analyze(
        [recurring, other],
        expandRecurring: false,
      );
      // Without expansion, r1 is at day 0, o1 at day 1 → no conflict
      expect(report.hasConflicts, false);
    });
  });

  // ============================================================
  // ConflictDetector - findConflictsFor Tests
  // ============================================================

  group('ConflictDetector - findConflictsFor', () {
    final detector = const ConflictDetector();
    final base = DateTime(2026, 3, 1, 10, 0);

    test('finds all conflicts for one event', () {
      final target = _event('t', base);
      final others = [
        _event('1', base.add(const Duration(minutes: 10))),
        _event('2', base.add(const Duration(minutes: 30))),
        _event('3', base.add(const Duration(hours: 3))),
      ];
      final conflicts = detector.findConflictsFor(target, others);
      expect(conflicts.length, 2);
    });

    test('returns empty for no conflicts', () {
      final target = _event('t', base);
      final others = [
        _event('1', base.add(const Duration(hours: 2))),
        _event('2', base.add(const Duration(hours: 5))),
      ];
      final conflicts = detector.findConflictsFor(target, others);
      expect(conflicts, isEmpty);
    });

    test('does not include self-comparison', () {
      final target = _event('t', base);
      final others = [
        _event('t', base), // Same ID
        _event('1', base.add(const Duration(minutes: 10))),
      ];
      final conflicts = detector.findConflictsFor(target, others);
      // Should skip the event with the same ID
      expect(conflicts.length, 1);
      expect(conflicts.first.eventB.id, '1');
    });

    test('correct severity for each', () {
      final target = _event('t', base);
      final others = [
        _event('1', base), // exact
        _event('2', base.add(const Duration(minutes: 10))), // high
        _event('3', base.add(const Duration(minutes: 45))), // moderate
      ];
      // Remove self from others since target has id 't'
      final conflicts = detector.findConflictsFor(target, others);
      expect(conflicts.length, 3);
      final severities = conflicts.map((c) => c.severity).toSet();
      expect(severities, contains(ConflictSeverity.exact));
      expect(severities, contains(ConflictSeverity.high));
      expect(severities, contains(ConflictSeverity.moderate));
    });

    test('handles empty others list', () {
      final target = _event('t', base);
      final conflicts = detector.findConflictsFor(target, []);
      expect(conflicts, isEmpty);
    });
  });

  // ============================================================
  // ConflictDetector - wouldConflict Tests
  // ============================================================

  group('ConflictDetector - wouldConflict', () {
    final detector = const ConflictDetector();
    final base = DateTime(2026, 3, 1, 10, 0);

    test('returns true when conflict exists', () {
      final newEvent = _event('new', base);
      final existing = [
        _event('1', base.add(const Duration(minutes: 30))),
      ];
      expect(detector.wouldConflict(newEvent, existing), true);
    });

    test('returns false when no conflict', () {
      final newEvent = _event('new', base);
      final existing = [
        _event('1', base.add(const Duration(hours: 2))),
      ];
      expect(detector.wouldConflict(newEvent, existing), false);
    });

    test('checks against all existing events', () {
      final newEvent = _event('new', base);
      final existing = [
        _event('1', base.add(const Duration(hours: 3))),
        _event('2', base.add(const Duration(hours: 5))),
        _event('3', base.add(const Duration(minutes: 45))), // This one conflicts
      ];
      expect(detector.wouldConflict(newEvent, existing), true);
    });

    test('custom window', () {
      final customDetector = const ConflictDetector(
        window: Duration(minutes: 15),
      );
      final newEvent = _event('new', base);
      final existing = [
        _event('1', base.add(const Duration(minutes: 30))),
      ];
      expect(customDetector.wouldConflict(newEvent, existing), false);

      final existing2 = [
        _event('2', base.add(const Duration(minutes: 10))),
      ];
      expect(customDetector.wouldConflict(newEvent, existing2), true);
    });
  });

  // ============================================================
  // ConflictReport Tests
  // ============================================================

  group('ConflictReport', () {
    final base = DateTime(2026, 3, 1, 10, 0);

    ConflictReport _makeReport(List<EventConflict> conflicts, int totalEvents) {
      return ConflictReport(
        conflicts: conflicts,
        totalEvents: totalEvents,
        analyzedAt: DateTime.now(),
      );
    }

    test('conflictCount', () {
      final a = _event('1', base);
      final b = _event('2', base);
      final conflict = EventConflict(
        eventA: a,
        eventB: b,
        gap: Duration.zero,
        severity: ConflictSeverity.exact,
      );
      final report = _makeReport([conflict], 2);
      expect(report.conflictCount, 1);
    });

    test('hasConflicts true', () {
      final conflict = EventConflict(
        eventA: _event('1', base),
        eventB: _event('2', base),
        gap: Duration.zero,
        severity: ConflictSeverity.exact,
      );
      expect(_makeReport([conflict], 2).hasConflicts, true);
    });

    test('hasConflicts false', () {
      expect(_makeReport([], 2).hasConflicts, false);
    });

    test('conflictedEventIds returns unique set', () {
      final a = _event('1', base);
      final b = _event('2', base);
      final c = _event('3', base.add(const Duration(minutes: 10)));
      final conflicts = [
        EventConflict(eventA: a, eventB: b, gap: Duration.zero, severity: ConflictSeverity.exact),
        EventConflict(eventA: a, eventB: c, gap: const Duration(minutes: 10), severity: ConflictSeverity.high),
      ];
      final report = _makeReport(conflicts, 3);
      expect(report.conflictedEventIds, {'1', '2', '3'});
    });

    test('affectedEventCount', () {
      final a = _event('1', base);
      final b = _event('2', base);
      final c = _event('3', base);
      final conflicts = [
        EventConflict(eventA: a, eventB: b, gap: Duration.zero, severity: ConflictSeverity.exact),
        EventConflict(eventA: b, eventB: c, gap: Duration.zero, severity: ConflictSeverity.exact),
      ];
      final report = _makeReport(conflicts, 5);
      expect(report.affectedEventCount, 3);
    });

    test('bySeverity grouping', () {
      final a = _event('1', base);
      final b = _event('2', base);
      final c = _event('3', base.add(const Duration(minutes: 30)));
      final conflicts = [
        EventConflict(eventA: a, eventB: b, gap: Duration.zero, severity: ConflictSeverity.exact),
        EventConflict(eventA: a, eventB: c, gap: const Duration(minutes: 30), severity: ConflictSeverity.moderate),
      ];
      final report = _makeReport(conflicts, 3);
      final grouped = report.bySeverity;
      expect(grouped[ConflictSeverity.exact]!.length, 1);
      expect(grouped[ConflictSeverity.moderate]!.length, 1);
      expect(grouped.containsKey(ConflictSeverity.high), false);
    });

    test('mostSevere returns highest severity', () {
      final conflicts = [
        EventConflict(
          eventA: _event('1', base),
          eventB: _event('2', base.add(const Duration(minutes: 30))),
          gap: const Duration(minutes: 30),
          severity: ConflictSeverity.moderate,
        ),
        EventConflict(
          eventA: _event('3', base),
          eventB: _event('4', base),
          gap: Duration.zero,
          severity: ConflictSeverity.exact,
        ),
      ];
      final report = _makeReport(conflicts, 4);
      expect(report.mostSevere!.severity, ConflictSeverity.exact);
    });

    test('mostSevere returns null for empty', () {
      expect(_makeReport([], 0).mostSevere, isNull);
    });

    test('conflictsFor specific event', () {
      final a = _event('1', base);
      final b = _event('2', base);
      final c = _event('3', base);
      final conflicts = [
        EventConflict(eventA: a, eventB: b, gap: Duration.zero, severity: ConflictSeverity.exact),
        EventConflict(eventA: b, eventB: c, gap: Duration.zero, severity: ConflictSeverity.exact),
      ];
      final report = _makeReport(conflicts, 3);
      expect(report.conflictsFor('1').length, 1);
      expect(report.conflictsFor('2').length, 2);
      expect(report.conflictsFor('4'), isEmpty);
    });

    test('hasConflictsFor', () {
      final conflicts = [
        EventConflict(
          eventA: _event('1', base),
          eventB: _event('2', base),
          gap: Duration.zero,
          severity: ConflictSeverity.exact,
        ),
      ];
      final report = _makeReport(conflicts, 3);
      expect(report.hasConflictsFor('1'), true);
      expect(report.hasConflictsFor('3'), false);
    });

    test('busiestEventId returns most-conflicted', () {
      final a = _event('A', base);
      final b = _event('B', base);
      final c = _event('C', base);
      final conflicts = [
        EventConflict(eventA: a, eventB: b, gap: Duration.zero, severity: ConflictSeverity.exact),
        EventConflict(eventA: a, eventB: c, gap: Duration.zero, severity: ConflictSeverity.exact),
        EventConflict(eventA: b, eventB: c, gap: Duration.zero, severity: ConflictSeverity.exact),
      ];
      final report = _makeReport(conflicts, 3);
      // A has 2 conflicts, B has 2, C has 2 — any could be busiest
      // Actually all 3 have 2 conflicts each, first encountered wins
      expect(report.busiestEventId, isNotNull);
    });

    test('busiestEventId with clear winner', () {
      final a = _event('A', base);
      final b = _event('B', base);
      final c = _event('C', base.add(const Duration(minutes: 5)));
      final d = _event('D', base.add(const Duration(minutes: 10)));
      final conflicts = [
        EventConflict(eventA: a, eventB: b, gap: Duration.zero, severity: ConflictSeverity.exact),
        EventConflict(eventA: a, eventB: c, gap: const Duration(minutes: 5), severity: ConflictSeverity.high),
        EventConflict(eventA: a, eventB: d, gap: const Duration(minutes: 10), severity: ConflictSeverity.high),
      ];
      final report = _makeReport(conflicts, 4);
      expect(report.busiestEventId, 'A');
    });

    test('busiestEventId returns null for empty', () {
      expect(_makeReport([], 0).busiestEventId, isNull);
    });

    test('summary string', () {
      final conflicts = [
        EventConflict(
          eventA: _event('1', base),
          eventB: _event('2', base),
          gap: Duration.zero,
          severity: ConflictSeverity.exact,
        ),
        EventConflict(
          eventA: _event('3', base),
          eventB: _event('4', base.add(const Duration(minutes: 30))),
          gap: const Duration(minutes: 30),
          severity: ConflictSeverity.moderate,
        ),
      ];
      final report = _makeReport(conflicts, 10);
      final summary = report.summary;
      expect(summary, contains('2 conflicts'));
      expect(summary, contains('10 events'));
      expect(summary, contains('exact'));
      expect(summary, contains('moderate'));
    });

    test('summary for no conflicts', () {
      final report = _makeReport([], 5);
      expect(report.summary, contains('No conflicts'));
    });
  });

  // ============================================================
  // suggestAlternatives Tests
  // ============================================================

  group('ConflictDetector - suggestAlternatives', () {
    final detector = const ConflictDetector();
    final base = DateTime(2026, 3, 1, 10, 0);

    test('returns requested count', () {
      final event = _event('new', base);
      final existing = [
        _event('1', base),
      ];
      final suggestions = detector.suggestAlternatives(event, existing, count: 3);
      expect(suggestions.length, 3);
    });

    test('all suggestions are conflict-free', () {
      final event = _event('new', base);
      final existing = [
        _event('1', base),
        _event('2', base.add(const Duration(hours: 2))),
      ];
      final suggestions = detector.suggestAlternatives(event, existing);
      for (final suggestion in suggestions) {
        final candidate = event.copyWith(date: suggestion);
        expect(detector.wouldConflict(candidate, existing), false);
      }
    });

    test('returns empty list if no alternatives found within reasonable range', () {
      // Create a wall of events at every 30-min slot for many hours
      // With a very tight layout, alternatives might be very limited
      final existing = <EventModel>[];
      for (var i = -1000; i <= 1000; i++) {
        existing.add(_event(
          'e$i',
          base.add(Duration(minutes: i * 30)),
        ));
      }
      // All 30-min slots covered → detector tries up to 1000 steps
      // With 1h window, events every 30 min means overlap everywhere
      final event = _event('new', base);
      final suggestions = detector.suggestAlternatives(event, existing, count: 5);
      // Should find nothing since every 30min slot is taken and window is 1h
      expect(suggestions, isEmpty);
    });

    test('includes both before and after times', () {
      final event = _event('new', base);
      final existing = [
        _event('1', base),
      ];
      final suggestions = detector.suggestAlternatives(
        event,
        existing,
        count: 4,
      );
      final hasBefore = suggestions.any((s) => s.isBefore(base));
      final hasAfter = suggestions.any((s) => s.isAfter(base));
      expect(hasBefore, true);
      expect(hasAfter, true);
    });

    test('respects step parameter', () {
      final event = _event('new', base);
      final existing = [
        _event('1', base),
      ];
      final step = const Duration(hours: 2);
      final suggestions = detector.suggestAlternatives(
        event,
        existing,
        count: 2,
        step: step,
      );
      // All suggestions should be multiples of 2h from base
      for (final s in suggestions) {
        final diff = s.difference(base).abs();
        expect(diff.inMinutes % 120, 0);
      }
    });
  });

  // ============================================================
  // Edge Cases Tests
  // ============================================================

  group('Edge cases', () {
    final detector = const ConflictDetector();

    test('events on different days (no conflict with 1h window)', () {
      final a = _event('1', DateTime(2026, 3, 1, 10, 0));
      final b = _event('2', DateTime(2026, 3, 2, 10, 0));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNull);
    });

    test('midnight boundary crossing', () {
      final a = _event('1', DateTime(2026, 3, 1, 23, 30));
      final b = _event('2', DateTime(2026, 3, 2, 0, 10));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.moderate);
      expect(conflict.gap, const Duration(minutes: 40));
    });

    test('events years apart', () {
      final a = _event('1', DateTime(2020, 1, 1));
      final b = _event('2', DateTime(2026, 1, 1));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNull);
    });

    test('duplicate events (same ID, same time)', () {
      final a = _event('dup', DateTime(2026, 3, 1, 10, 0));
      final b = _event('dup', DateTime(2026, 3, 1, 10, 0));
      // checkPair doesn't check IDs, it just checks time
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.exact);
    });

    test('very short window (1 minute)', () {
      final shortDetector = const ConflictDetector(
        window: Duration(minutes: 1),
      );
      final a = _event('1', DateTime(2026, 3, 1, 10, 0));
      final b = _event('2', DateTime(2026, 3, 1, 10, 1));
      final c = _event('3', DateTime(2026, 3, 1, 10, 2));
      expect(shortDetector.checkPair(a, b), isNotNull);
      expect(shortDetector.checkPair(a, c), isNull);
    });

    test('negative duration treated as absolute', () {
      // Event B is before event A
      final a = _event('1', DateTime(2026, 3, 1, 10, 30));
      final b = _event('2', DateTime(2026, 3, 1, 10, 0));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.gap, const Duration(minutes: 30));
    });

    test('description formats hours and minutes', () {
      final a = _event('1', DateTime(2026, 3, 1, 10, 0), title: 'A');
      final b = _event('2', DateTime(2026, 3, 1, 10, 45), title: 'B');
      final conflict = EventConflict(
        eventA: a,
        eventB: b,
        gap: const Duration(minutes: 45),
        severity: ConflictSeverity.moderate,
      );
      expect(conflict.description, contains('45 minutes'));
    });

    test('large gap description shows hours', () {
      final a = _event('1', DateTime(2026, 3, 1, 10, 0), title: 'A');
      final b = _event('2', DateTime(2026, 3, 1, 11, 30), title: 'B');
      final conflict = EventConflict(
        eventA: a,
        eventB: b,
        gap: const Duration(hours: 1, minutes: 30),
        severity: ConflictSeverity.low,
      );
      expect(conflict.description, contains('1 hour'));
      expect(conflict.description, contains('30 minutes'));
    });
  });

  // ============================================================
  // Time Range (endDate) Overlap Tests
  // ============================================================

  group('Time range (endDate) overlap detection', () {
    final detector = const ConflictDetector();
    final base = DateTime(2026, 3, 1, 10, 0);

    test('overlapping ranges detected as exact conflict', () {
      // Event A: 10:00–12:00, Event B: 11:00–13:00
      final a = _event('1', base,
          endDate: base.add(const Duration(hours: 2)));
      final b = _event('2', base.add(const Duration(hours: 1)),
          endDate: base.add(const Duration(hours: 3)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.exact);
    });

    test('long event overlaps later short event beyond window', () {
      // Event A: 10:00–14:00 (4h), Event B: 13:00–13:30
      // Start gap = 3h (missed by old logic), but ranges overlap
      final a = _event('1', base,
          endDate: base.add(const Duration(hours: 4)));
      final b = _event('2', base.add(const Duration(hours: 3)),
          endDate: base.add(const Duration(hours: 3, minutes: 30)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.exact);
    });

    test('non-overlapping ranges with gap within window', () {
      // Event A: 10:00–10:30, Event B: 11:00–11:30 (30 min gap)
      final a = _event('1', base,
          endDate: base.add(const Duration(minutes: 30)));
      final b = _event('2', base.add(const Duration(hours: 1)),
          endDate: base.add(const Duration(hours: 1, minutes: 30)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.moderate);
    });

    test('non-overlapping ranges with gap beyond window', () {
      // Event A: 10:00–10:30, Event B: 12:00–12:30 (1.5h gap)
      final a = _event('1', base,
          endDate: base.add(const Duration(minutes: 30)));
      final b = _event('2', base.add(const Duration(hours: 2)),
          endDate: base.add(const Duration(hours: 2, minutes: 30)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNull);
    });

    test('event B starts exactly when A ends (adjacent)', () {
      // Event A: 10:00–11:00, Event B: 11:00–12:00 (boundary overlap)
      final a = _event('1', base,
          endDate: base.add(const Duration(hours: 1)));
      final b = _event('2', base.add(const Duration(hours: 1)),
          endDate: base.add(const Duration(hours: 2)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.exact);
    });

    test('event B completely contained within A', () {
      // Event A: 10:00–14:00, Event B: 11:00–12:00
      final a = _event('1', base,
          endDate: base.add(const Duration(hours: 4)));
      final b = _event('2', base.add(const Duration(hours: 1)),
          endDate: base.add(const Duration(hours: 2)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.exact);
    });

    test('point event within a range event', () {
      // Event A: 10:00–14:00, Event B: 12:00 (no endDate)
      final a = _event('1', base,
          endDate: base.add(const Duration(hours: 4)));
      final b = _event('2', base.add(const Duration(hours: 2)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.exact);
    });

    test('point event after range ends with gap in window', () {
      // Event A: 10:00–11:00, Event B: 11:30 (point, 30 min gap)
      final a = _event('1', base,
          endDate: base.add(const Duration(hours: 1)));
      final b = _event('2', base.add(const Duration(hours: 1, minutes: 30)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.moderate);
    });

    test('analyze detects overlap in sorted events', () {
      // A: 10:00–14:00, B: 13:00–15:00, C: 16:00–17:00
      final events = [
        _event('A', base,
            endDate: base.add(const Duration(hours: 4))),
        _event('B', base.add(const Duration(hours: 3)),
            endDate: base.add(const Duration(hours: 5))),
        _event('C', base.add(const Duration(hours: 6)),
            endDate: base.add(const Duration(hours: 7))),
      ];
      final report = detector.analyze(events);
      expect(report.conflictCount, 2); // A-B overlap, B-C within window
    });

    test('wouldConflict with time ranges', () {
      final existing = [
        _event('1', base,
            endDate: base.add(const Duration(hours: 4))),
      ];
      final newEvent = _event('new', base.add(const Duration(hours: 3)));
      expect(detector.wouldConflict(newEvent, existing), true);
    });

    test('wouldConflict with time ranges no overlap', () {
      final existing = [
        _event('1', base,
            endDate: base.add(const Duration(hours: 1))),
      ];
      final newEvent = _event('new', base.add(const Duration(hours: 3)));
      expect(detector.wouldConflict(newEvent, existing), false);
    });

    test('findConflictsFor with time ranges', () {
      final target = _event('t', base.add(const Duration(hours: 2)),
          endDate: base.add(const Duration(hours: 4)));
      final others = [
        _event('A', base,
            endDate: base.add(const Duration(hours: 2, minutes: 30))),
        _event('B', base.add(const Duration(hours: 5)),
            endDate: base.add(const Duration(hours: 6))),
        _event('C', base.add(const Duration(hours: 7)),
            endDate: base.add(const Duration(hours: 8))),
      ];
      final conflicts = detector.findConflictsFor(target, others);
      expect(conflicts.length, 2); // A (overlap) and B (within window)
    });

    test('backward compatibility: point events behave identically', () {
      final a = _event('1', base);
      final b = _event('2', base.add(const Duration(minutes: 30)));
      final conflict = detector.checkPair(a, b);
      expect(conflict, isNotNull);
      expect(conflict!.severity, ConflictSeverity.moderate);
      expect(conflict.gap, const Duration(minutes: 30));
    });
  });
}
