import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/gratitude_journal_service.dart';
import 'package:everything/models/gratitude_entry.dart';

void main() {
  late GratitudeJournalService service;

  setUp(() {
    service = GratitudeJournalService();
  });

  group('GratitudeEntry model', () {
    test('creates entry with defaults', () {
      final e = GratitudeEntry(
        id: '1',
        timestamp: DateTime(2026, 3, 4),
        text: 'Sunny day',
      );
      expect(e.category, GratitudeCategory.general);
      expect(e.intensity, GratitudeIntensity.moderate);
      expect(e.tags, isEmpty);
      expect(e.isFavorite, false);
    });

    test('serializes and deserializes JSON', () {
      final e = GratitudeEntry(
        id: 'g1',
        timestamp: DateTime(2026, 3, 4, 10, 30),
        text: 'Good coffee',
        category: GratitudeCategory.experience,
        intensity: GratitudeIntensity.strong,
        tags: ['morning', 'coffee'],
        note: 'Best latte ever',
        isFavorite: true,
      );
      final json = e.toJson();
      final restored = GratitudeEntry.fromJson(json);
      expect(restored.id, e.id);
      expect(restored.text, e.text);
      expect(restored.category, e.category);
      expect(restored.intensity, e.intensity);
      expect(restored.tags, e.tags);
      expect(restored.note, e.note);
      expect(restored.isFavorite, true);
    });

    test('round-trips through JSON string', () {
      final e = GratitudeEntry(
        id: 'x',
        timestamp: DateTime(2026, 1, 1),
        text: 'Test',
      );
      final s = e.toJsonString();
      final r = GratitudeEntry.fromJsonString(s);
      expect(r.id, 'x');
    });

    test('copyWith preserves unchanged fields', () {
      final e = GratitudeEntry(
        id: '1',
        timestamp: DateTime(2026, 3, 4),
        text: 'Original',
        category: GratitudeCategory.people,
        intensity: GratitudeIntensity.profound,
        tags: ['tag1'],
        isFavorite: true,
      );
      final c = e.copyWith(text: 'Updated');
      expect(c.text, 'Updated');
      expect(c.category, GratitudeCategory.people);
      expect(c.intensity, GratitudeIntensity.profound);
      expect(c.isFavorite, true);
    });

    test('equality by id', () {
      final a = GratitudeEntry(id: '1', timestamp: DateTime.now(), text: 'A');
      final b = GratitudeEntry(id: '1', timestamp: DateTime.now(), text: 'B');
      expect(a, equals(b));
    });

    test('toString includes emoji and intensity', () {
      final e = GratitudeEntry(
        id: '1',
        timestamp: DateTime(2026, 3, 4),
        text: 'Walking',
        category: GratitudeCategory.nature,
        intensity: GratitudeIntensity.strong,
      );
      expect(e.toString(), contains('🌿'));
      expect(e.toString(), contains('Strong'));
    });
  });

  group('GratitudeCategory', () {
    test('all categories have labels', () {
      for (final c in GratitudeCategory.values) {
        expect(c.label.isNotEmpty, true);
      }
    });

    test('all categories have emojis', () {
      for (final c in GratitudeCategory.values) {
        expect(c.emoji.isNotEmpty, true);
      }
    });
  });

  group('GratitudeIntensity', () {
    test('values are 1-5', () {
      expect(GratitudeIntensity.slight.value, 1);
      expect(GratitudeIntensity.profound.value, 5);
    });

    test('fromValue clamps', () {
      expect(GratitudeIntensity.fromValue(0), GratitudeIntensity.slight);
      expect(GratitudeIntensity.fromValue(3), GratitudeIntensity.moderate);
      expect(GratitudeIntensity.fromValue(99), GratitudeIntensity.profound);
    });
  });

  group('CRUD', () {
    test('addEntry returns id and increments count', () {
      final id = service.addEntry(text: 'First entry');
      expect(id, startsWith('grat_'));
      expect(service.entryCount, 1);
    });

    test('addEntry trims whitespace', () {
      final id = service.addEntry(text: '  hello  ');
      expect(service.getEntry(id)!.text, 'hello');
    });

    test('addEntry rejects empty text', () {
      expect(() => service.addEntry(text: ''), throwsArgumentError);
      expect(() => service.addEntry(text: '   '), throwsArgumentError);
    });

    test('getEntry returns null for unknown id', () {
      expect(service.getEntry('nope'), isNull);
    });

    test('updateEntry modifies fields', () {
      final id = service.addEntry(text: 'Original');
      final ok = service.updateEntry(id,
          text: 'Updated', category: GratitudeCategory.health);
      expect(ok, true);
      expect(service.getEntry(id)!.text, 'Updated');
      expect(service.getEntry(id)!.category, GratitudeCategory.health);
    });

    test('updateEntry returns false for unknown id', () {
      expect(service.updateEntry('x', text: 'Y'), false);
    });

    test('deleteEntry removes entry', () {
      final id = service.addEntry(text: 'Gone');
      expect(service.deleteEntry(id), true);
      expect(service.entryCount, 0);
      expect(service.getEntry(id), isNull);
    });

    test('deleteEntry returns false for unknown id', () {
      expect(service.deleteEntry('x'), false);
    });

    test('toggleFavorite flips state', () {
      final id = service.addEntry(text: 'Star me');
      expect(service.getEntry(id)!.isFavorite, false);
      service.toggleFavorite(id);
      expect(service.getEntry(id)!.isFavorite, true);
      service.toggleFavorite(id);
      expect(service.getEntry(id)!.isFavorite, false);
    });

    test('toggleFavorite returns false for unknown id', () {
      expect(service.toggleFavorite('x'), false);
    });

    test('allEntries is unmodifiable copy', () {
      service.addEntry(text: 'Test');
      final list = service.allEntries;
      expect(() => (list as List).add(null), throwsA(anything));
    });
  });

  group('Filtering', () {
    setUp(() {
      service.addEntry(
        text: 'Morning walk',
        timestamp: DateTime(2026, 3, 1, 8),
        category: GratitudeCategory.nature,
        tags: ['morning', 'exercise'],
      );
      service.addEntry(
        text: 'Lunch with friends',
        timestamp: DateTime(2026, 3, 1, 12),
        category: GratitudeCategory.people,
        tags: ['social'],
      );
      service.addEntry(
        text: 'Good sleep',
        timestamp: DateTime(2026, 3, 2, 7),
        category: GratitudeCategory.health,
        tags: ['morning'],
      );
    });

    test('getEntriesForDate filters by day', () {
      final entries = service.getEntriesForDate(DateTime(2026, 3, 1));
      expect(entries.length, 2);
    });

    test('getEntriesInRange filters by date range', () {
      final entries = service.getEntriesInRange(
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 1, 23, 59),
      );
      expect(entries.length, 2);
    });

    test('getEntriesByCategory filters', () {
      expect(service.getEntriesByCategory(GratitudeCategory.nature).length, 1);
      expect(service.getEntriesByCategory(GratitudeCategory.achievement).length, 0);
    });

    test('getEntriesByTag is case-insensitive', () {
      expect(service.getEntriesByTag('Morning').length, 2);
    });

    test('getFavorites returns starred entries', () {
      final id = service.allEntries.first.id;
      service.toggleFavorite(id);
      expect(service.getFavorites().length, 1);
    });

    test('search finds in text, note, and tags', () {
      service.addEntry(text: 'Plain', note: 'Walk in park');
      expect(service.search('walk').length, 2); // text + note
      expect(service.search('social').length, 1); // tag
    });
  });

  group('Daily Summary', () {
    test('empty day returns zero summary', () {
      final s = service.getDailySummary(DateTime(2026, 3, 1));
      expect(s.entryCount, 0);
      expect(s.averageIntensity, 0.0);
    });

    test('computes summary correctly', () {
      service.addEntry(
        text: 'A',
        timestamp: DateTime(2026, 3, 1),
        intensity: GratitudeIntensity.strong,
        category: GratitudeCategory.people,
        tags: ['x'],
      );
      service.addEntry(
        text: 'B',
        timestamp: DateTime(2026, 3, 1, 20),
        intensity: GratitudeIntensity.slight,
        category: GratitudeCategory.people,
        tags: ['x', 'y'],
      );
      final s = service.getDailySummary(DateTime(2026, 3, 1));
      expect(s.entryCount, 2);
      expect(s.averageIntensity, 2.5); // (4+1)/2
      expect(s.categoryBreakdown[GratitudeCategory.people], 2);
      expect(s.topTags.first, 'x');
    });
  });

  group('Streaks', () {
    test('empty journal has 0 streaks', () {
      final s = service.getStreak(today: DateTime(2026, 3, 5));
      expect(s.currentStreak, 0);
      expect(s.longestStreak, 0);
      expect(s.lastEntryDate, isNull);
    });

    test('single day streak', () {
      service.addEntry(text: 'A', timestamp: DateTime(2026, 3, 5));
      final s = service.getStreak(today: DateTime(2026, 3, 5));
      expect(s.currentStreak, 1);
      expect(s.longestStreak, 1);
    });

    test('consecutive days build streak', () {
      service.addEntry(text: 'A', timestamp: DateTime(2026, 3, 3));
      service.addEntry(text: 'B', timestamp: DateTime(2026, 3, 4));
      service.addEntry(text: 'C', timestamp: DateTime(2026, 3, 5));
      final s = service.getStreak(today: DateTime(2026, 3, 5));
      expect(s.currentStreak, 3);
      expect(s.longestStreak, 3);
    });

    test('gap breaks current streak', () {
      service.addEntry(text: 'A', timestamp: DateTime(2026, 3, 1));
      service.addEntry(text: 'B', timestamp: DateTime(2026, 3, 2));
      // gap on 3rd
      service.addEntry(text: 'C', timestamp: DateTime(2026, 3, 4));
      service.addEntry(text: 'D', timestamp: DateTime(2026, 3, 5));
      final s = service.getStreak(today: DateTime(2026, 3, 5));
      expect(s.currentStreak, 2);
      expect(s.longestStreak, 2);
    });

    test('yesterday counts as current streak', () {
      service.addEntry(text: 'A', timestamp: DateTime(2026, 3, 4));
      final s = service.getStreak(today: DateTime(2026, 3, 5));
      expect(s.currentStreak, 1);
    });
  });

  group('Weekly Report', () {
    test('empty week returns F', () {
      final r = service.getWeeklyReport(DateTime(2026, 3, 1));
      expect(r.totalEntries, 0);
      expect(r.grade, 'F');
    });

    test('grades based on entries per day', () {
      // 21 entries in a week = 3/day = A
      for (int d = 0; d < 7; d++) {
        for (int i = 0; i < 3; i++) {
          service.addEntry(
            text: 'E$d$i',
            timestamp: DateTime(2026, 3, 1 + d, 8 + i),
          );
        }
      }
      final r = service.getWeeklyReport(DateTime(2026, 3, 1));
      expect(r.totalEntries, 21);
      expect(r.grade, 'A');
      expect(r.entriesPerDay, 3.0);
    });
  });

  group('Insights', () {
    test('empty journal gets start insight', () {
      final insights = service.getInsights();
      expect(insights.length, 1);
      expect(insights.first.type, 'start');
    });

    test('diverse categories generate diversity insight', () {
      final cats = GratitudeCategory.values.take(5);
      for (final c in cats) {
        service.addEntry(text: c.label, category: c);
      }
      final insights = service.getInsights();
      expect(insights.any((i) => i.type == 'diversity'), true);
    });

    test('high intensity generates insight', () {
      for (int i = 0; i < 5; i++) {
        service.addEntry(
            text: 'Deep $i', intensity: GratitudeIntensity.profound);
      }
      final insights = service.getInsights();
      expect(insights.any((i) => i.type == 'intensity'), true);
    });

    test('top category insight', () {
      for (int i = 0; i < 3; i++) {
        service.addEntry(text: 'P$i', category: GratitudeCategory.people);
      }
      final insights = service.getInsights();
      final topCat = insights.firstWhere((i) => i.type == 'topCategory');
      expect(topCat.message, contains('People'));
    });
  });

  group('Prompts', () {
    test('getRandomPrompt returns non-empty string', () {
      final p = service.getRandomPrompt(random: Random(42));
      expect(p.isNotEmpty, true);
    });

    test('getPrompt wraps around', () {
      final a = service.getPrompt(0);
      final b = service.getPrompt(service.promptCount);
      expect(a, b);
    });

    test('promptCount is 20', () {
      expect(service.promptCount, 20);
    });
  });

  group('Report', () {
    test('full report on populated journal', () {
      for (int d = 0; d < 5; d++) {
        service.addEntry(
          text: 'Entry $d',
          timestamp: DateTime(2026, 3, 1 + d),
          category: GratitudeCategory.values[d % 8],
          intensity: GratitudeIntensity.values[d % 5],
          tags: ['tag${d % 3}'],
        );
      }
      service.toggleFavorite(service.allEntries.first.id);

      final report = service.getReport(today: DateTime(2026, 3, 5));
      expect(report.totalEntries, 5);
      expect(report.favoriteCount, 1);
      expect(report.averageIntensity, greaterThan(0));
      expect(report.streak.currentStreak, 5);
      expect(report.textSummary, contains('Gratitude Journal Report'));
      expect(report.textSummary, contains('Total entries: 5'));
    });

    test('report on single entry', () {
      service.addEntry(text: 'Only one', timestamp: DateTime(2026, 3, 5));
      final report = service.getReport(today: DateTime(2026, 3, 5));
      expect(report.averageEntriesPerDay, 1.0);
    });
  });

  group('Persistence', () {
    test('export and import round-trips', () {
      service.addEntry(
        text: 'Hello',
        category: GratitudeCategory.health,
        intensity: GratitudeIntensity.strong,
        tags: ['test'],
        note: 'A note',
      );
      service.toggleFavorite(service.allEntries.first.id);
      service.addEntry(text: 'World');

      final json = service.exportToJson();
      final newService = GratitudeJournalService();
      newService.importFromJson(json);

      expect(newService.entryCount, 2);
      expect(newService.allEntries.first.text, 'Hello');
      expect(newService.allEntries.first.isFavorite, true);
      expect(newService.allEntries.first.category, GratitudeCategory.health);
      expect(newService.allEntries.last.text, 'World');
    });

    test('import resets id counter correctly', () {
      service.addEntry(text: 'A');
      service.addEntry(text: 'B');
      final json = service.exportToJson();

      final newService = GratitudeJournalService();
      newService.importFromJson(json);
      final newId = newService.addEntry(text: 'C');
      // Should not collide
      expect(newService.entryCount, 3);
      expect(newService.getEntry(newId)!.text, 'C');
    });
  });
}
