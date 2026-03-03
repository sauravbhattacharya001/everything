import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/event_pattern_service.dart';
import 'package:everything/models/event_model.dart';

void main() {
  late EventPatternService service;

  setUp(() {
    service = const EventPatternService(minOccurrences: 3);
  });

  EventModel _event(String id, String title, DateTime date, {DateTime? endDate}) {
    return EventModel(id: id, title: title, date: date, endDate: endDate);
  }

  group('PatternCadence', () {
    test('labels are correct', () {
      expect(PatternCadence.daily.label, 'Daily');
      expect(PatternCadence.weekly.label, 'Weekly');
      expect(PatternCadence.biweekly.label, 'Biweekly');
      expect(PatternCadence.monthly.label, 'Monthly');
      expect(PatternCadence.irregular.label, 'Irregular');
    });
  });

  group('EventPattern', () {
    test('isSuggestionWorthy requires confidence >= 0.6, count >= 3, not recurring', () {
      final p = EventPattern(title: 'standup', cadence: PatternCadence.weekly,
        confidence: 0.8, occurrenceCount: 5, averageIntervalDays: 7.0,
        intervalStdDev: 0.5, occurrenceDates: []);
      expect(p.isSuggestionWorthy, true);
    });

    test('isSuggestionWorthy false when already recurring', () {
      final p = EventPattern(title: 'standup', cadence: PatternCadence.weekly,
        confidence: 0.8, occurrenceCount: 5, averageIntervalDays: 7.0,
        intervalStdDev: 0.5, occurrenceDates: [], alreadyRecurring: true);
      expect(p.isSuggestionWorthy, false);
    });

    test('isSuggestionWorthy false when low confidence', () {
      final p = EventPattern(title: 'standup', cadence: PatternCadence.weekly,
        confidence: 0.3, occurrenceCount: 5, averageIntervalDays: 7.0,
        intervalStdDev: 0.5, occurrenceDates: []);
      expect(p.isSuggestionWorthy, false);
    });

    test('isSuggestionWorthy false when too few occurrences', () {
      final p = EventPattern(title: 'standup', cadence: PatternCadence.weekly,
        confidence: 0.9, occurrenceCount: 2, averageIntervalDays: 7.0,
        intervalStdDev: 0.5, occurrenceDates: []);
      expect(p.isSuggestionWorthy, false);
    });

    test('equality by title and cadence', () {
      final p1 = EventPattern(title: 'standup', cadence: PatternCadence.weekly,
        confidence: 0.8, occurrenceCount: 5, averageIntervalDays: 7.0,
        intervalStdDev: 0.5, occurrenceDates: []);
      final p2 = EventPattern(title: 'standup', cadence: PatternCadence.weekly,
        confidence: 0.5, occurrenceCount: 3, averageIntervalDays: 7.2,
        intervalStdDev: 1.0, occurrenceDates: []);
      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });

    test('toString includes key info', () {
      final p = EventPattern(title: 'standup', cadence: PatternCadence.weekly,
        confidence: 0.85, occurrenceCount: 10, averageIntervalDays: 7.0,
        intervalStdDev: 0.3, occurrenceDates: []);
      expect(p.toString(), contains('standup'));
      expect(p.toString(), contains('Weekly'));
      expect(p.toString(), contains('85%'));
    });
  });

  group('detectPatterns', () {
    test('detects weekly pattern', () {
      final events = List.generate(6, (i) => _event(
        'e$i', 'Team Standup', DateTime(2026, 1, 6 + i * 7, 9, 0)));
      final patterns = service.detectPatterns(events);
      expect(patterns, isNotEmpty);
      expect(patterns.first.cadence, PatternCadence.weekly);
      expect(patterns.first.occurrenceCount, 6);
    });

    test('detects daily pattern', () {
      final events = List.generate(10, (i) => _event(
        'e$i', 'Daily Check-in', DateTime(2026, 1, 5 + i, 10, 0)));
      final patterns = service.detectPatterns(events);
      expect(patterns, isNotEmpty);
      expect(patterns.first.cadence, PatternCadence.daily);
    });

    test('detects biweekly pattern', () {
      final events = List.generate(5, (i) => _event(
        'e$i', 'Sprint Review', DateTime(2026, 1, 6 + i * 14, 14, 0)));
      final patterns = service.detectPatterns(events);
      expect(patterns, isNotEmpty);
      expect(patterns.first.cadence, PatternCadence.biweekly);
    });

    test('detects monthly pattern', () {
      final events = [
        _event('e0', 'Monthly Review', DateTime(2025, 10, 1, 10)),
        _event('e1', 'Monthly Review', DateTime(2025, 11, 1, 10)),
        _event('e2', 'Monthly Review', DateTime(2025, 12, 1, 10)),
        _event('e3', 'Monthly Review', DateTime(2026, 1, 1, 10)),
      ];
      final patterns = service.detectPatterns(events);
      expect(patterns, isNotEmpty);
      expect(patterns.first.cadence, PatternCadence.monthly);
    });

    test('ignores events below minOccurrences', () {
      final events = [
        _event('e0', 'Rare Event', DateTime(2026, 1, 5, 10)),
        _event('e1', 'Rare Event', DateTime(2026, 1, 12, 10)),
      ];
      expect(service.detectPatterns(events), isEmpty);
    });

    test('normalizes titles for grouping', () {
      final events = [
        _event('e0', 'Team Standup', DateTime(2026, 1, 6, 9)),
        _event('e1', '  team standup  ', DateTime(2026, 1, 13, 9)),
        _event('e2', 'TEAM STANDUP', DateTime(2026, 1, 20, 9)),
        _event('e3', 'team  standup', DateTime(2026, 1, 27, 9)),
      ];
      final patterns = service.detectPatterns(events);
      expect(patterns, isNotEmpty);
      expect(patterns.first.occurrenceCount, 4);
    });

    test('detects preferred day of week', () {
      final events = List.generate(5, (i) => _event(
        'e$i', 'Wednesday Sync', DateTime(2026, 1, 7 + i * 7, 14, 0)));
      expect(service.detectPatterns(events).first.preferredDayOfWeek, 3);
    });

    test('detects preferred hour', () {
      final events = List.generate(5, (i) => _event(
        'e$i', 'Morning Brief', DateTime(2026, 1, 5 + i, 8, 0)));
      expect(service.detectPatterns(events).first.preferredHour, 8);
    });

    test('handles empty events list', () {
      expect(service.detectPatterns([]), isEmpty);
    });

    test('multiple distinct patterns detected separately', () {
      final events = <EventModel>[];
      for (var i = 0; i < 5; i++) {
        events.add(_event('a$i', 'Standup', DateTime(2026, 1, 5 + i, 9)));
        events.add(_event('b$i', 'Lunch Walk', DateTime(2026, 1, 5 + i, 12)));
      }
      final patterns = service.detectPatterns(events);
      expect(patterns.length, 2);
      final titles = patterns.map((p) => p.title).toSet();
      expect(titles, contains('standup'));
      expect(titles, contains('lunch walk'));
    });

    test('strips trailing numbers from titles', () {
      final events = [
        _event('e0', 'Meeting #1', DateTime(2026, 1, 5, 10)),
        _event('e1', 'Meeting #2', DateTime(2026, 1, 12, 10)),
        _event('e2', 'Meeting #3', DateTime(2026, 1, 19, 10)),
        _event('e3', 'Meeting', DateTime(2026, 1, 26, 10)),
      ];
      final patterns = service.detectPatterns(events);
      expect(patterns, isNotEmpty);
      expect(patterns.first.occurrenceCount, 4);
    });
  });

  group('analyze habits', () {
    test('detects time-of-day preference', () {
      final events = List.generate(10, (i) => _event(
        'e$i', 'Task $i', DateTime(2026, 1, 5 + i, 9, 0)));
      final report = service.analyze(events);
      final timing = report.habits.where((h) => h.category == 'timing').toList();
      expect(timing, isNotEmpty);
      expect(timing.first.detail, contains('morning'));
    });

    test('detects busiest and quietest day', () {
      final events = <EventModel>[];
      for (var i = 0; i < 5; i++) events.add(_event('m$i', 'Monday Task $i', DateTime(2026, 1, 5, 9 + i)));
      events.add(_event('t0', 'Tuesday Task', DateTime(2026, 1, 6, 9)));
      final report = service.analyze(events);
      expect(report.habits.any((h) => h.description == 'Busiest day'), true);
    });

    test('detects event density', () {
      final events = List.generate(6, (i) => _event('e$i', 'Task $i', DateTime(2026, 1, 5, 9 + i)));
      final report = service.analyze(events);
      final freq = report.habits.where((h) => h.category == 'frequency').toList();
      expect(freq, isNotEmpty);
      expect(freq.first.value, 6.0);
    });

    test('detects priority preference', () {
      final events = List.generate(5, (i) => EventModel(
        id: 'e$i', title: 'High Priority $i',
        date: DateTime(2026, 1, 5 + i, 10), priority: EventPriority.high));
      final report = service.analyze(events);
      final pref = report.habits.where((h) => h.description == 'Priority preference').toList();
      expect(pref, isNotEmpty);
      expect(pref.first.detail, contains('High'));
    });

    test('detects weekend activity level', () {
      final events = [
        _event('e0', 'Weekend fun', DateTime(2026, 1, 3, 10)),
        _event('e1', 'Sunday rest', DateTime(2026, 1, 4, 10)),
        _event('e2', 'Monday work', DateTime(2026, 1, 5, 10)),
      ];
      final report = service.analyze(events);
      final habit = report.habits.firstWhere((h) => h.description == 'Weekend activity');
      expect(habit.value, closeTo(66.7, 1.0));
    });

    test('detects event duration habit', () {
      final events = List.generate(5, (i) => _event('e$i', 'Long Meeting $i',
        DateTime(2026, 1, 5 + i, 10), endDate: DateTime(2026, 1, 5 + i, 12)));
      final report = service.analyze(events);
      final dur = report.habits.where((h) => h.description == 'Event duration').toList();
      expect(dur, isNotEmpty);
      expect(dur.first.detail, contains('120'));
    });
  });

  group('predictions', () {
    test('generates predictions for weekly pattern', () {
      final events = List.generate(5, (i) => _event(
        'e$i', 'Weekly Sync', DateTime(2026, 1, 6 + i * 7, 10, 0)));
      final report = service.analyze(events, from: DateTime(2026, 1, 6), to: DateTime(2026, 2, 3));
      expect(report.predictions, isNotEmpty);
      for (final pred in report.predictions) {
        expect(pred.predictedDate.isAfter(DateTime(2026, 2, 3)), true);
      }
    });

    test('predictions have decaying confidence', () {
      final events = List.generate(5, (i) => _event(
        'e$i', 'Weekly Sync', DateTime(2026, 1, 6 + i * 7, 10, 0)));
      final patterns = service.detectPatterns(events);
      final predictions = service.predict(patterns, after: DateTime(2026, 2, 3), days: 60);
      if (predictions.length >= 2) {
        expect(predictions.first.confidence, greaterThanOrEqualTo(predictions.last.confidence));
      }
    });

    test('no predictions for irregular patterns', () {
      final events = [
        _event('e0', 'Random', DateTime(2026, 1, 1, 10)),
        _event('e1', 'Random', DateTime(2026, 1, 3, 10)),
        _event('e2', 'Random', DateTime(2026, 1, 20, 10)),
        _event('e3', 'Random', DateTime(2026, 1, 22, 10)),
        _event('e4', 'Random', DateTime(2026, 2, 15, 10)),
      ];
      final patterns = service.detectPatterns(events);
      final irregular = patterns.where((p) => p.cadence == PatternCadence.irregular).toList();
      expect(service.predict(irregular, after: DateTime(2026, 2, 15)), isEmpty);
    });

    test('predictions snap to preferred day and hour', () {
      final events = List.generate(5, (i) => _event(
        'e$i', 'Wed Meeting', DateTime(2026, 1, 7 + i * 7, 14, 0)));
      final report = service.analyze(events, from: DateTime(2026, 1, 7), to: DateTime(2026, 2, 4));
      if (report.predictions.isNotEmpty) {
        expect(report.predictions.first.predictedDate.weekday, 3);
        expect(report.predictions.first.predictedDate.hour, 14);
      }
    });
  });

  group('analyze', () {
    test('empty events returns empty report', () {
      final report = service.analyze([]);
      expect(report.eventsAnalyzed, 0);
      expect(report.patterns, isEmpty);
      expect(report.habits, isEmpty);
      expect(report.predictions, isEmpty);
    });

    test('full report with mixed patterns', () {
      final events = <EventModel>[];
      for (var i = 0; i < 6; i++) events.add(_event('s$i', 'Standup', DateTime(2026, 1, 5 + i * 7, 9, 0)));
      for (var i = 0; i < 10; i++) events.add(_event('c$i', 'Check-in', DateTime(2026, 1, 5 + i, 8, 0)));
      final report = service.analyze(events);
      expect(report.eventsAnalyzed, 16);
      expect(report.patterns.length, 2);
      expect(report.habits, isNotEmpty);
    });

    test('report summary is human-readable', () {
      final events = List.generate(5, (i) => _event(
        'e$i', 'Team Sync', DateTime(2026, 1, 6 + i * 7, 10, 0)));
      final summary = service.analyze(events).summary;
      expect(summary, contains('Event Pattern Report'));
      expect(summary, contains('Events analyzed'));
    });

    test('suggestions list unformalised patterns', () {
      final events = List.generate(6, (i) => _event(
        'e$i', 'Informal Weekly', DateTime(2026, 1, 6 + i * 7, 10, 0)));
      final report = service.analyze(events);
      expect(report.suggestions, isNotEmpty);
      expect(report.suggestions.first.alreadyRecurring, false);
    });

    test('respects from/to date range', () {
      final events = List.generate(10, (i) => _event(
        'e$i', 'Daily Task', DateTime(2026, 1, 5 + i, 9, 0)));
      final report = service.analyze(events, from: DateTime(2026, 1, 7), to: DateTime(2026, 1, 10));
      expect(report.eventsAnalyzed, 4);
    });

    test('report toString includes summary stats', () {
      final events = List.generate(5, (i) => _event(
        'e$i', 'Weekly Thing', DateTime(2026, 1, 6 + i * 7, 10, 0)));
      final str = service.analyze(events).toString();
      expect(str, contains('patterns'));
      expect(str, contains('suggestions'));
    });
  });

  group('edge cases', () {
    test('single event produces no patterns', () {
      expect(service.detectPatterns([_event('e0', 'Solo', DateTime(2026, 1, 5, 10))]), isEmpty);
    });

    test('all same-day events does not crash', () {
      final events = List.generate(5, (i) => _event('e$i', 'Same Day', DateTime(2026, 1, 5, 9 + i)));
      expect(service.detectPatterns(events), isA<List<EventPattern>>());
    });

    test('configurable minOccurrences', () {
      final strict = const EventPatternService(minOccurrences: 5);
      final events = List.generate(4, (i) => _event(
        'e$i', 'Almost Pattern', DateTime(2026, 1, 6 + i * 7, 10, 0)));
      expect(strict.detectPatterns(events), isEmpty);
    });

    test('configurable predictionDays', () {
      final short = const EventPatternService(predictionDays: 7);
      final events = List.generate(5, (i) => _event(
        'e$i', 'Weekly', DateTime(2026, 1, 6 + i * 7, 10, 0)));
      for (final pred in short.analyze(events).predictions) {
        expect(pred.predictedDate.difference(DateTime(2026, 2, 3)).inDays, lessThanOrEqualTo(7));
      }
    });

    test('SchedulingHabit toString', () {
      const h = SchedulingHabit(description: 'Test', category: 'timing', value: 42.0, detail: 'test detail');
      expect(h.toString(), contains('Test'));
      expect(h.toString(), contains('test detail'));
    });

    test('EventPrediction toString', () {
      final pred = EventPrediction(
        pattern: EventPattern(title: 'test', cadence: PatternCadence.weekly,
          confidence: 0.8, occurrenceCount: 5, averageIntervalDays: 7.0,
          intervalStdDev: 0.3, occurrenceDates: []),
        predictedDate: DateTime(2026, 3, 10), confidence: 0.75);
      expect(pred.toString(), contains('test'));
      expect(pred.toString(), contains('2026-03-10'));
    });
  });
}
