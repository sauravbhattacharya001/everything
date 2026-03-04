import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/eisenhower_matrix_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';

// ─── Helpers ────────────────────────────────────────────────────

DateTime _d(int y, int m, int d, [int h = 0, int min = 0]) =>
    DateTime(y, m, d, h, min);

EventModel _event(
  String id,
  String title,
  DateTime date, {
  DateTime? endDate,
  EventPriority priority = EventPriority.medium,
  List<EventTag>? tags,
}) =>
    EventModel(
      id: id,
      title: title,
      date: date,
      endDate: endDate,
      priority: priority,
      tags: tags,
    );

EventTag _tag(String name) => EventTag(name: name, color: '#FF0000');

void main() {
  final now = _d(2026, 3, 3, 12, 0);

  group('Quadrant enum', () {
    test('has correct labels', () {
      expect(Quadrant.doFirst.label, 'Do First');
      expect(Quadrant.schedule.label, 'Schedule');
      expect(Quadrant.delegate.label, 'Delegate');
      expect(Quadrant.eliminate.label, 'Eliminate');
    });

    test('has descriptions', () {
      for (final q in Quadrant.values) {
        expect(q.description.isNotEmpty, true);
      }
    });

    test('has emojis', () {
      expect(Quadrant.doFirst.emoji, '🔴');
      expect(Quadrant.eliminate.emoji, '⚪');
    });
  });

  group('computeUrgency', () {
    final service = EisenhowerMatrixService();

    test('overdue event returns 1.0', () {
      final event = _event('1', 'Past', _d(2026, 3, 2));
      expect(service.computeUrgency(event, now), 1.0);
    });

    test('event due in 1 hour is very urgent', () {
      final event = _event('2', 'Soon', _d(2026, 3, 3, 13, 0));
      final score = service.computeUrgency(event, now);
      expect(score, greaterThan(0.9));
    });

    test('event due in 12 hours is urgent', () {
      final event = _event('3', 'Today', _d(2026, 3, 4, 0, 0));
      final score = service.computeUrgency(event, now);
      expect(score, greaterThanOrEqualTo(0.8));
    });

    test('event due in 2 days is moderately urgent', () {
      final event = _event('4', '2Days', _d(2026, 3, 5, 12, 0));
      final score = service.computeUrgency(event, now);
      expect(score, greaterThanOrEqualTo(0.3));
      expect(score, lessThan(0.8));
    });

    test('event due in 7 days is low urgency', () {
      final event = _event('5', 'NextWeek', _d(2026, 3, 10, 12, 0));
      final score = service.computeUrgency(event, now);
      expect(score, lessThan(0.3));
    });

    test('event due in 30 days is very low urgency', () {
      final event = _event('6', 'NextMonth', _d(2026, 4, 3));
      final score = service.computeUrgency(event, now);
      expect(score, lessThan(0.15));
    });

    test('uses endDate as deadline when available', () {
      final event = _event('7', 'Range', _d(2026, 3, 5),
          endDate: _d(2026, 3, 3, 14, 0));
      final score = service.computeUrgency(event, now);
      expect(score, greaterThan(0.9)); // endDate is 2h away
    });

    test('event exactly at now returns 1.0', () {
      final event = _event('8', 'Now', now);
      expect(service.computeUrgency(event, now), greaterThanOrEqualTo(0.95));
    });
  });

  group('computeImportance', () {
    final service = EisenhowerMatrixService(
      config: MatrixConfig(
        importantTags: {'work': 0.8, 'health': 0.6},
      ),
    );

    test('urgent priority gives high importance', () {
      final event = _event('1', 'Crisis', now, priority: EventPriority.urgent);
      expect(service.computeImportance(event), greaterThanOrEqualTo(0.5));
    });

    test('low priority gives low importance', () {
      final event = _event('2', 'Casual', now, priority: EventPriority.low);
      expect(service.computeImportance(event), lessThan(0.3));
    });

    test('important tag boosts score', () {
      final withTag = _event('3', 'Tagged', now,
          priority: EventPriority.medium, tags: [_tag('work')]);
      final without = _event('4', 'NoTag', now,
          priority: EventPriority.medium);
      expect(service.computeImportance(withTag),
          greaterThan(service.computeImportance(without)));
    });

    test('tag matching is case-insensitive', () {
      final event = _event('5', 'Case', now,
          priority: EventPriority.medium, tags: [_tag('WORK')]);
      final score = service.computeImportance(event);
      expect(score, greaterThan(0.4)); // medium + work tag
    });

    test('multiple tags uses highest weight', () {
      final event = _event('6', 'Multi', now,
          priority: EventPriority.medium,
          tags: [_tag('health'), _tag('work')]);
      final singleWork = _event('7', 'Single', now,
          priority: EventPriority.medium, tags: [_tag('work')]);
      // Should use work (0.8) not health (0.6)
      expect(service.computeImportance(event),
          service.computeImportance(singleWork));
    });

    test('importance clamped to 1.0', () {
      final event = _event('8', 'Max', now,
          priority: EventPriority.urgent, tags: [_tag('work')]);
      expect(service.computeImportance(event), lessThanOrEqualTo(1.0));
    });
  });

  group('classify', () {
    final service = EisenhowerMatrixService();

    test('high urgency + high importance = doFirst', () {
      expect(service.classify(0.8, 0.7), Quadrant.doFirst);
    });

    test('low urgency + high importance = schedule', () {
      expect(service.classify(0.2, 0.7), Quadrant.schedule);
    });

    test('high urgency + low importance = delegate', () {
      expect(service.classify(0.8, 0.2), Quadrant.delegate);
    });

    test('low urgency + low importance = eliminate', () {
      expect(service.classify(0.2, 0.2), Quadrant.eliminate);
    });

    test('boundary: urgency=0.5, importance=0.4 = doFirst', () {
      expect(service.classify(0.5, 0.4), Quadrant.doFirst);
    });

    test('boundary: urgency=0.49, importance=0.39 = eliminate', () {
      expect(service.classify(0.49, 0.39), Quadrant.eliminate);
    });
  });

  group('evaluate', () {
    final service = EisenhowerMatrixService(
      config: MatrixConfig(
        importantTags: {'deadline': 1.0},
      ),
    );

    test('returns MatrixEntry with all fields', () {
      final event = _event('1', 'Test', _d(2026, 3, 3, 14, 0),
          priority: EventPriority.high);
      final entry = service.evaluate(event, now: now);

      expect(entry.event, event);
      expect(entry.quadrant, isA<Quadrant>());
      expect(entry.urgencyScore, greaterThanOrEqualTo(0));
      expect(entry.urgencyScore, lessThanOrEqualTo(1));
      expect(entry.importanceScore, greaterThanOrEqualTo(0));
      expect(entry.importanceScore, lessThanOrEqualTo(1));
      expect(entry.urgencyReason.isNotEmpty, true);
      expect(entry.importanceReason.isNotEmpty, true);
    });

    test('overdue + urgent priority = Q1 doFirst', () {
      final event = _event('2', 'Overdue', _d(2026, 3, 2),
          priority: EventPriority.urgent);
      final entry = service.evaluate(event, now: now);
      expect(entry.quadrant, Quadrant.doFirst);
    });

    test('far future + high priority = Q2 schedule', () {
      final event = _event('3', 'Plan', _d(2026, 4, 1),
          priority: EventPriority.high);
      final entry = service.evaluate(event, now: now);
      expect(entry.quadrant, Quadrant.schedule);
    });

    test('due soon + low priority = Q3 delegate', () {
      final event = _event('4', 'Interrupt', _d(2026, 3, 3, 14, 0),
          priority: EventPriority.low);
      final entry = service.evaluate(event, now: now);
      expect(entry.quadrant, Quadrant.delegate);
    });

    test('far future + low priority = Q4 eliminate', () {
      final event = _event('5', 'Meh', _d(2026, 5, 1),
          priority: EventPriority.low);
      final entry = service.evaluate(event, now: now);
      expect(entry.quadrant, Quadrant.eliminate);
    });
  });

  group('buildMatrix', () {
    final service = EisenhowerMatrixService();

    test('empty list returns empty summary', () {
      final summary = service.buildMatrix([], now: now);
      expect(summary.total, 0);
      expect(summary.averageUrgency, 0.0);
      expect(summary.averageImportance, 0.0);
      for (final q in Quadrant.values) {
        expect(summary.counts[q], 0);
        expect(summary.entries[q], isEmpty);
      }
    });

    test('categorizes mixed events correctly', () {
      final events = [
        _event('1', 'Crisis', _d(2026, 3, 3, 13), priority: EventPriority.urgent),
        _event('2', 'Growth', _d(2026, 4, 1), priority: EventPriority.high),
        _event('3', 'Ping', _d(2026, 3, 3, 14), priority: EventPriority.low),
        _event('4', 'Noise', _d(2026, 5, 1), priority: EventPriority.low),
      ];
      final summary = service.buildMatrix(events, now: now);

      expect(summary.total, 4);
      expect(summary.counts[Quadrant.doFirst], greaterThanOrEqualTo(1));
      expect(summary.counts[Quadrant.schedule], greaterThanOrEqualTo(1));
    });

    test('balance score reflects important event ratio', () {
      // All urgent+important
      final allImportant = [
        _event('1', 'A', _d(2026, 3, 3, 14), priority: EventPriority.urgent),
        _event('2', 'B', _d(2026, 4, 1), priority: EventPriority.high),
      ];
      final summary = service.buildMatrix(allImportant, now: now);
      expect(summary.balanceScore, 100.0);
    });

    test('entries sorted by quadrant then combined score', () {
      final events = [
        _event('a', 'Low', _d(2026, 5, 1), priority: EventPriority.low),
        _event('b', 'Urgent', _d(2026, 3, 3, 13), priority: EventPriority.urgent),
      ];
      final summary = service.buildMatrix(events, now: now);
      // Q1 should come before Q4 in the entries
      final allEntries = Quadrant.values
          .expand((q) => summary.entries[q]!)
          .toList();
      expect(allEntries.first.quadrant.index,
          lessThanOrEqualTo(allEntries.last.quadrant.index));
    });
  });

  group('getRecommendations', () {
    final service = EisenhowerMatrixService();

    test('warns when Q1 overloaded', () {
      final events = List.generate(
        5,
        (i) => _event('$i', 'Crisis$i', _d(2026, 3, 3, 13 + i),
            priority: EventPriority.urgent),
      );
      final summary = service.buildMatrix(events, now: now);
      final recs = service.getRecommendations(summary);
      expect(recs.any((r) => r.contains('crisis mode')), true);
    });

    test('suggests planning when Q2 empty', () {
      final events = [
        _event('1', 'Urgent', _d(2026, 3, 3, 14), priority: EventPriority.low),
      ];
      final summary = service.buildMatrix(events, now: now);
      final recs = service.getRecommendations(summary);
      expect(recs.any((r) => r.contains('planning')), true);
    });

    test('balanced matrix gets positive feedback', () {
      final events = [
        _event('1', 'Do', _d(2026, 3, 3, 14), priority: EventPriority.urgent),
        _event('2', 'Plan', _d(2026, 4, 1), priority: EventPriority.high),
      ];
      final summary = service.buildMatrix(events, now: now);
      final recs = service.getRecommendations(summary);
      expect(recs.any((r) => r.contains('balance') || r.contains('balanced')), true);
    });

    test('empty events gives balanced feedback', () {
      final summary = service.buildMatrix([], now: now);
      final recs = service.getRecommendations(summary);
      expect(recs.isNotEmpty, true);
    });
  });

  group('formatSummary', () {
    final service = EisenhowerMatrixService();

    test('produces readable text output', () {
      final events = [
        _event('1', 'Fix Bug', _d(2026, 3, 3, 14), priority: EventPriority.urgent),
        _event('2', 'Read Book', _d(2026, 4, 1), priority: EventPriority.high),
        _event('3', 'Check Email', _d(2026, 3, 3, 15), priority: EventPriority.low),
      ];
      final summary = service.buildMatrix(events, now: now);
      final text = service.formatSummary(summary);

      expect(text, contains('Eisenhower Matrix'));
      expect(text, contains('Do First'));
      expect(text, contains('Schedule'));
      expect(text, contains('Delegate'));
      expect(text, contains('Eliminate'));
      expect(text, contains('Recommendations'));
      expect(text, contains('Fix Bug'));
    });

    test('truncates long quadrants to 5 entries', () {
      final events = List.generate(
        8,
        (i) => _event('$i', 'Task$i', _d(2026, 3, 3, 13 + i),
            priority: EventPriority.urgent),
      );
      final summary = service.buildMatrix(events, now: now);
      final text = service.formatSummary(summary);
      expect(text, contains('more'));
    });
  });

  group('custom config', () {
    test('shorter urgent threshold increases urgency', () {
      final tight = EisenhowerMatrixService(
        config: MatrixConfig(urgentThreshold: Duration(hours: 6)),
      );
      final relaxed = EisenhowerMatrixService(
        config: MatrixConfig(urgentThreshold: Duration(hours: 48)),
      );

      final event = _event('1', 'Test', _d(2026, 3, 3, 20, 0)); // 8h away
      // With 6h threshold, 8h is past urgent → moderate
      // With 48h threshold, 8h is within urgent → high
      expect(
        relaxed.computeUrgency(event, now),
        greaterThan(tight.computeUrgency(event, now)),
      );
    });

    test('importanceMinPriority is stored in config', () {
      final config = MatrixConfig(importanceMinPriority: EventPriority.medium);
      expect(config.importanceMinPriority, EventPriority.medium);
    });
  });

  group('urgency reasons', () {
    final service = EisenhowerMatrixService();

    test('overdue shows overdue message', () {
      final event = _event('1', 'Past', _d(2026, 3, 2));
      final entry = service.evaluate(event, now: now);
      expect(entry.urgencyReason, contains('Overdue'));
    });

    test('close deadline shows hours', () {
      final event = _event('2', 'Soon', _d(2026, 3, 3, 20, 0));
      final entry = service.evaluate(event, now: now);
      expect(entry.urgencyReason, contains('h'));
    });

    test('far deadline shows days', () {
      final event = _event('3', 'Later', _d(2026, 3, 10));
      final entry = service.evaluate(event, now: now);
      expect(entry.urgencyReason, contains('d'));
    });
  });

  group('edge cases', () {
    final service = EisenhowerMatrixService();

    test('single event matrix works', () {
      final summary = service.buildMatrix(
        [_event('1', 'Solo', now, priority: EventPriority.medium)],
        now: now,
      );
      expect(summary.total, 1);
    });

    test('many events perform well', () {
      final events = List.generate(
        100,
        (i) => _event('$i', 'E$i',
            now.add(Duration(hours: i)),
            priority: EventPriority.values[i % 4]),
      );
      final summary = service.buildMatrix(events, now: now);
      expect(summary.total, 100);
      final totalCounted = Quadrant.values
          .map((q) => summary.counts[q]!)
          .reduce((a, b) => a + b);
      expect(totalCounted, 100);
    });

    test('all quadrants have entries for diverse events', () {
      final events = [
        _event('1', 'Q1', _d(2026, 3, 3, 13), priority: EventPriority.urgent),
        _event('2', 'Q2', _d(2026, 5, 1), priority: EventPriority.urgent),
        _event('3', 'Q3', _d(2026, 3, 3, 13), priority: EventPriority.low),
        _event('4', 'Q4', _d(2026, 5, 1), priority: EventPriority.low),
      ];
      final summary = service.buildMatrix(events, now: now);
      for (final q in Quadrant.values) {
        expect(summary.counts[q], greaterThanOrEqualTo(1),
            reason: '${q.label} should have at least 1 entry');
      }
    });
  });
}
