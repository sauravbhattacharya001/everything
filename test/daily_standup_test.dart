import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/daily_standup_service.dart';
import 'package:everything/models/standup_entry.dart';

void main() {
  group('StandupEntry', () {
    test('toJson/fromJson roundtrip', () {
      final entry = StandupEntry(
        id: '1',
        date: DateTime(2026, 3, 31),
        yesterday: 'Wrote tests',
        today: 'Deploy to prod',
        blockers: 'CI is slow',
        energy: 4,
        goalsCompleted: true,
      );
      final json = entry.toJson();
      final restored = StandupEntry.fromJson(json);
      expect(restored.id, '1');
      expect(restored.yesterday, 'Wrote tests');
      expect(restored.today, 'Deploy to prod');
      expect(restored.blockers, 'CI is slow');
      expect(restored.energy, 4);
      expect(restored.goalsCompleted, true);
    });

    test('hasBlockers returns true when blockers present', () {
      final entry = StandupEntry(id: '1', date: DateTime.now(), blockers: 'Blocked');
      expect(entry.hasBlockers, true);
    });

    test('hasBlockers returns false when empty', () {
      final entry = StandupEntry(id: '1', date: DateTime.now());
      expect(entry.hasBlockers, false);
    });

    test('isComplete requires content', () {
      final empty = StandupEntry(id: '1', date: DateTime.now());
      expect(empty.isComplete, false);

      final withContent = StandupEntry(
        id: '2',
        date: DateTime.now(),
        yesterday: 'Something',
      );
      expect(withContent.isComplete, true);
    });
  });

  group('DailyStandupService', () {
    late DailyStandupService service;

    setUp(() {
      service = DailyStandupService();
    });

    test('getOrCreateToday creates entry', () {
      final entry = service.getOrCreateToday();
      expect(entry, isNotNull);
      expect(service.entries.length, 1);
    });

    test('getOrCreateToday returns same entry on second call', () {
      final first = service.getOrCreateToday();
      final second = service.getOrCreateToday();
      expect(first.id, second.id);
      expect(service.entries.length, 1);
    });

    test('save updates entry', () {
      final entry = service.getOrCreateToday();
      entry.yesterday = 'Did stuff';
      service.save(entry);
      expect(service.entries.first.yesterday, 'Did stuff');
    });

    test('markGoalsCompleted works', () {
      final entry = service.getOrCreateToday();
      service.markGoalsCompleted(entry.id);
      expect(service.entries.first.goalsCompleted, true);
    });

    test('delete removes entry', () {
      final entry = service.getOrCreateToday();
      service.delete(entry.id);
      expect(service.entries, isEmpty);
    });

    test('currentStreak counts consecutive days', () {
      // Start with empty
      expect(service.currentStreak, 0);

      // Add today
      service.getOrCreateToday();
      expect(service.currentStreak, 1);
    });

    test('blockerCount counts entries with blockers', () {
      final entry = service.getOrCreateToday();
      entry.blockers = 'Something blocking';
      service.save(entry);
      expect(service.blockerCount(), 1);
    });

    test('toJsonString/loadFromJson roundtrip', () {
      final entry = service.getOrCreateToday();
      entry.yesterday = 'Test';
      entry.today = 'More test';
      service.save(entry);

      final json = service.toJsonString();
      final service2 = DailyStandupService();
      service2.loadFromJson(json);
      expect(service2.entries.length, 1);
      expect(service2.entries.first.yesterday, 'Test');
    });
  });
}
