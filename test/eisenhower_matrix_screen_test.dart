import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/eisenhower_matrix_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';

void main() {
  group('EisenhowerMatrixScreen integration', () {
    late EisenhowerMatrixService service;

    setUp(() {
      service = EisenhowerMatrixService(
        config: const MatrixConfig(
          importantTags: {'work': 0.8, 'health': 0.7},
        ),
      );
    });

    EventModel _makeEvent({
      required String title,
      required DateTime date,
      DateTime? endDate,
      EventPriority priority = EventPriority.medium,
      List<String> tags = const [],
    }) {
      return EventModel(
        id: title.hashCode.toString(),
        title: title,
        date: date,
        endDate: endDate,
        priority: priority,
        tags: tags.map((t) => EventTag(name: t)).toList(),
      );
    }

    test('classifies urgent+important event as doFirst', () {
      final now = DateTime(2026, 3, 15, 12);
      final event = _makeEvent(
        title: 'Critical deadline',
        date: now.add(const Duration(hours: 6)),
        priority: EventPriority.urgent,
      );
      final entry = service.evaluate(event, now: now);
      expect(entry.quadrant, Quadrant.doFirst);
      expect(entry.urgencyScore, greaterThanOrEqualTo(0.5));
      expect(entry.importanceScore, greaterThanOrEqualTo(0.4));
    });

    test('classifies distant+important event as schedule', () {
      final now = DateTime(2026, 3, 15, 12);
      final event = _makeEvent(
        title: 'Plan project',
        date: now.add(const Duration(days: 14)),
        priority: EventPriority.high,
      );
      final entry = service.evaluate(event, now: now);
      expect(entry.quadrant, Quadrant.schedule);
    });

    test('classifies urgent+low-priority as delegate', () {
      final now = DateTime(2026, 3, 15, 12);
      final event = _makeEvent(
        title: 'Answer emails',
        date: now.add(const Duration(hours: 2)),
        priority: EventPriority.low,
      );
      final entry = service.evaluate(event, now: now);
      expect(entry.quadrant, Quadrant.delegate);
    });

    test('classifies far-out+low-priority as eliminate', () {
      final now = DateTime(2026, 3, 15, 12);
      final event = _makeEvent(
        title: 'Maybe someday',
        date: now.add(const Duration(days: 30)),
        priority: EventPriority.low,
      );
      final entry = service.evaluate(event, now: now);
      expect(entry.quadrant, Quadrant.eliminate);
    });

    test('buildMatrix groups events correctly', () {
      final now = DateTime(2026, 3, 15, 12);
      final events = [
        _makeEvent(
          title: 'Crisis',
          date: now.add(const Duration(hours: 3)),
          priority: EventPriority.urgent,
        ),
        _makeEvent(
          title: 'Long-term goal',
          date: now.add(const Duration(days: 20)),
          priority: EventPriority.high,
        ),
        _makeEvent(
          title: 'Routine task',
          date: now.add(const Duration(hours: 5)),
          priority: EventPriority.low,
        ),
        _makeEvent(
          title: 'Filler',
          date: now.add(const Duration(days: 60)),
          priority: EventPriority.low,
        ),
      ];
      final summary = service.buildMatrix(events, now: now);
      expect(summary.total, 4);
      expect(summary.counts[Quadrant.doFirst], greaterThanOrEqualTo(1));
      expect(summary.entries[Quadrant.doFirst]!.any((e) => e.event.title == 'Crisis'), isTrue);
    });

    test('overdue event has maximum urgency', () {
      final now = DateTime(2026, 3, 15, 12);
      final event = _makeEvent(
        title: 'Overdue!',
        date: now.subtract(const Duration(hours: 5)),
        priority: EventPriority.high,
      );
      final entry = service.evaluate(event, now: now);
      expect(entry.urgencyScore, 1.0);
      expect(entry.quadrant, Quadrant.doFirst);
    });

    test('tag weights boost importance', () {
      final now = DateTime(2026, 3, 15, 12);
      final event = _makeEvent(
        title: 'Exercise',
        date: now.add(const Duration(days: 10)),
        priority: EventPriority.medium,
        tags: ['health'],
      );
      final entry = service.evaluate(event, now: now);
      // medium priority (0.25) + health tag (0.7 * 0.3 = 0.21) = 0.46 >= 0.4
      expect(entry.importanceScore, greaterThanOrEqualTo(0.4));
    });

    test('recommendations warn about too many Q1 items', () {
      final now = DateTime(2026, 3, 15, 12);
      final events = List.generate(
        5,
        (i) => _makeEvent(
          title: 'Urgent $i',
          date: now.add(Duration(hours: i + 1)),
          priority: EventPriority.urgent,
        ),
      );
      final summary = service.buildMatrix(events, now: now);
      final recs = service.getRecommendations(summary);
      expect(recs.any((r) => r.contains('crisis mode')), isTrue);
    });

    test('empty events produce balanced recommendation', () {
      final summary = service.buildMatrix([], now: DateTime.now());
      final recs = service.getRecommendations(summary);
      expect(recs.any((r) => r.contains('balanced')), isTrue);
    });

    test('balance score reflects Q1+Q2 percentage', () {
      final now = DateTime(2026, 3, 15, 12);
      final events = [
        _makeEvent(
          title: 'Important 1',
          date: now.add(const Duration(hours: 2)),
          priority: EventPriority.urgent,
        ),
        _makeEvent(
          title: 'Important 2',
          date: now.add(const Duration(days: 10)),
          priority: EventPriority.high,
        ),
      ];
      final summary = service.buildMatrix(events, now: now);
      // Both should be in important quadrants → 100%
      expect(summary.balanceScore, 100.0);
    });

    test('formatSummary produces readable output', () {
      final now = DateTime(2026, 3, 15, 12);
      final events = [
        _makeEvent(
          title: 'Test Event',
          date: now.add(const Duration(hours: 6)),
          priority: EventPriority.high,
        ),
      ];
      final summary = service.buildMatrix(events, now: now);
      final text = service.formatSummary(summary);
      expect(text, contains('Eisenhower Matrix'));
      expect(text, contains('Test Event'));
      expect(text, contains('Recommendations'));
    });

    test('quadrant enum has correct labels and emojis', () {
      expect(Quadrant.doFirst.label, 'Do First');
      expect(Quadrant.doFirst.emoji, '🔴');
      expect(Quadrant.schedule.label, 'Schedule');
      expect(Quadrant.delegate.label, 'Delegate');
      expect(Quadrant.eliminate.label, 'Eliminate');
    });

    test('MatrixEntry contains valid scores', () {
      final now = DateTime(2026, 3, 15, 12);
      final event = _makeEvent(
        title: 'Score test',
        date: now.add(const Duration(hours: 12)),
        priority: EventPriority.medium,
      );
      final entry = service.evaluate(event, now: now);
      expect(entry.urgencyScore, inInclusiveRange(0.0, 1.0));
      expect(entry.importanceScore, inInclusiveRange(0.0, 1.0));
      expect(entry.urgencyReason, isNotEmpty);
      expect(entry.importanceReason, isNotEmpty);
    });

    test('events sorted by combined score within quadrant', () {
      final now = DateTime(2026, 3, 15, 12);
      final events = [
        _makeEvent(
          title: 'Less urgent crisis',
          date: now.add(const Duration(hours: 20)),
          priority: EventPriority.urgent,
        ),
        _makeEvent(
          title: 'More urgent crisis',
          date: now.add(const Duration(hours: 2)),
          priority: EventPriority.urgent,
        ),
      ];
      final summary = service.buildMatrix(events, now: now);
      final q1 = summary.entries[Quadrant.doFirst]!;
      if (q1.length >= 2) {
        final score0 = q1[0].urgencyScore + q1[0].importanceScore;
        final score1 = q1[1].urgencyScore + q1[1].importanceScore;
        expect(score0, greaterThanOrEqualTo(score1));
      }
    });

    test('no scheduled items triggers planning recommendation', () {
      final now = DateTime(2026, 3, 15, 12);
      final events = [
        _makeEvent(
          title: 'Urgent only',
          date: now.add(const Duration(hours: 1)),
          priority: EventPriority.low,
        ),
      ];
      final summary = service.buildMatrix(events, now: now);
      final recs = service.getRecommendations(summary);
      expect(recs.any((r) => r.contains('planning')), isTrue);
    });

    test('many Q4 items triggers cleanup recommendation', () {
      final now = DateTime(2026, 3, 15, 12);
      final events = List.generate(
        4,
        (i) => _makeEvent(
          title: 'Filler $i',
          date: now.add(Duration(days: 30 + i * 10)),
          priority: EventPriority.low,
        ),
      );
      final summary = service.buildMatrix(events, now: now);
      final recs = service.getRecommendations(summary);
      expect(recs.any((r) => r.contains('neither urgent nor important') || r.contains('removing')), isTrue);
    });
  });
}
