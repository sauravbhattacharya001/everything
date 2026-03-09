import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/pet_entry.dart';
import 'package:everything/core/services/pet_care_service.dart';

void main() {
  const service = PetCareService();

  final pet1 = Pet(
    id: 'p1', name: 'Buddy', type: PetType.dog,
    breed: 'Golden Retriever',
    birthday: DateTime.now().subtract(const Duration(days: 730)),
    weightKg: 30.0,
  );

  final pet2 = Pet(
    id: 'p2', name: 'Whiskers', type: PetType.cat,
    birthday: DateTime.now().subtract(const Duration(days: 365)),
  );

  group('Pet model', () {
    test('ageLabel formats months correctly', () {
      final young = Pet(
        id: 'y', name: 'Puppy', type: PetType.dog,
        birthday: DateTime.now().subtract(const Duration(days: 90)),
      );
      expect(young.ageLabel, contains('mo'));
    });

    test('ageLabel returns Unknown age when no birthday', () {
      const noBday = Pet(id: 'n', name: 'No Bday', type: PetType.fish);
      expect(noBday.ageLabel, 'Unknown age');
    });

    test('toJson/fromJson roundtrip', () {
      final json = pet1.toJson();
      final restored = Pet.fromJson(json);
      expect(restored.name, pet1.name);
      expect(restored.type, pet1.type);
      expect(restored.breed, pet1.breed);
      expect(restored.weightKg, pet1.weightKg);
    });

    test('PetType has emoji and label for all values', () {
      for (final t in PetType.values) {
        expect(t.emoji.isNotEmpty, true);
        expect(t.label.isNotEmpty, true);
      }
    });
  });

  group('CareEntry model', () {
    test('toJson/fromJson roundtrip', () {
      final entry = CareEntry(
        id: 'c1', petId: 'p1',
        timestamp: DateTime(2026, 3, 1, 10, 0),
        category: CareCategory.feeding,
        note: 'Morning meal',
        durationMinutes: 5,
        mood: PetMood.happy,
        cost: 2.50,
      );
      final json = entry.toJson();
      final restored = CareEntry.fromJson(json);
      expect(restored.category, CareCategory.feeding);
      expect(restored.mood, PetMood.happy);
      expect(restored.cost, 2.50);
      expect(restored.note, 'Morning meal');
    });

    test('CareCategory has emoji and label for all values', () {
      for (final c in CareCategory.values) {
        expect(c.emoji.isNotEmpty, true);
        expect(c.label.isNotEmpty, true);
      }
    });

    test('PetMood has emoji and label for all values', () {
      for (final m in PetMood.values) {
        expect(m.emoji.isNotEmpty, true);
        expect(m.label.isNotEmpty, true);
      }
    });
  });

  group('HealthRecord model', () {
    test('isOverdue detects past due dates', () {
      final overdue = HealthRecord(
        id: 'h1', petId: 'p1',
        date: DateTime.now().subtract(const Duration(days: 60)),
        type: CareCategory.vaccination,
        title: 'Rabies',
        nextDue: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(overdue.isOverdue, true);
      expect(overdue.isDueSoon, false);
    });

    test('isDueSoon detects upcoming due dates', () {
      final soon = HealthRecord(
        id: 'h2', petId: 'p1',
        date: DateTime.now().subtract(const Duration(days: 350)),
        type: CareCategory.vaccination,
        title: 'Distemper',
        nextDue: DateTime.now().add(const Duration(days: 7)),
      );
      expect(soon.isDueSoon, true);
      expect(soon.isOverdue, false);
    });

    test('toJson/fromJson roundtrip', () {
      final record = HealthRecord(
        id: 'h3', petId: 'p1',
        date: DateTime(2026, 1, 15),
        type: CareCategory.vetVisit,
        title: 'Annual checkup',
        description: 'All good',
        weightKg: 30.5,
        nextDue: DateTime(2027, 1, 15),
      );
      final json = record.toJson();
      final restored = HealthRecord.fromJson(json);
      expect(restored.title, 'Annual checkup');
      expect(restored.weightKg, 30.5);
    });
  });

  group('PetCareService', () {
    final now = DateTime.now();
    final entries = [
      CareEntry(id: 'c1', petId: 'p1', timestamp: now, category: CareCategory.feeding),
      CareEntry(id: 'c2', petId: 'p1', timestamp: now.subtract(const Duration(hours: 2)), category: CareCategory.walking, durationMinutes: 30),
      CareEntry(id: 'c3', petId: 'p1', timestamp: now.subtract(const Duration(days: 1)), category: CareCategory.feeding, cost: 3.0),
      CareEntry(id: 'c4', petId: 'p1', timestamp: now.subtract(const Duration(days: 2)), category: CareCategory.grooming, mood: PetMood.calm),
      CareEntry(id: 'c5', petId: 'p2', timestamp: now, category: CareCategory.feeding),
      CareEntry(id: 'c6', petId: 'p1', timestamp: now, category: CareCategory.play, mood: PetMood.happy, cost: 5.0),
    ];

    test('entriesForPet filters and sorts', () {
      final result = service.entriesForPet(entries, 'p1');
      expect(result.length, 5);
      expect(result.first.timestamp.isAfter(result.last.timestamp) ||
             result.first.timestamp.isAtSameMomentAs(result.last.timestamp), true);
    });

    test('todayEntries returns only today', () {
      final today = service.todayEntries(entries, 'p1');
      expect(today.length, 3); // c1, c2, c6
    });

    test('categoryBreakdown counts correctly', () {
      final breakdown = service.categoryBreakdown(entries, 'p1');
      expect(breakdown[CareCategory.feeding], 2);
      expect(breakdown[CareCategory.walking], 1);
      expect(breakdown[CareCategory.play], 1);
    });

    test('totalCost sums costs', () {
      final cost = service.totalCost(entries, 'p1');
      expect(cost, 8.0);
    });

    test('careStreak calculates consecutive days', () {
      final streak = service.careStreak(entries, 'p1');
      expect(streak, greaterThanOrEqualTo(2));
    });

    test('moodDistribution counts moods', () {
      final moods = service.moodDistribution(entries, 'p1');
      expect(moods[PetMood.calm], 1);
      expect(moods[PetMood.happy], 1);
    });

    test('lastFeeding returns most recent', () {
      final last = service.lastFeeding(entries, 'p1');
      expect(last, isNotNull);
      expect(last, now);
    });

    test('lastWalk returns most recent', () {
      final last = service.lastWalk(entries, 'p1');
      expect(last, isNotNull);
    });

    test('avgDailyCare returns reasonable average', () {
      final avg = service.avgDailyCare(entries, 'p1');
      expect(avg, greaterThan(0));
    });

    test('weeklySummary returns 7 values', () {
      final weekly = service.weeklySummary(entries, 'p1');
      expect(weekly.length, 7);
      expect(weekly.last, greaterThan(0)); // today has entries
    });

    test('healthForPet filters and sorts', () {
      final records = [
        HealthRecord(id: 'h1', petId: 'p1', date: DateTime(2026, 1, 1), type: CareCategory.vaccination, title: 'Rabies'),
        HealthRecord(id: 'h2', petId: 'p1', date: DateTime(2026, 3, 1), type: CareCategory.vetVisit, title: 'Checkup'),
        HealthRecord(id: 'h3', petId: 'p2', date: DateTime(2026, 2, 1), type: CareCategory.vetVisit, title: 'Cat checkup'),
      ];
      final result = service.healthForPet(records, 'p1');
      expect(result.length, 2);
      expect(result.first.title, 'Checkup');
    });

    test('overdueRecords returns only overdue', () {
      final records = [
        HealthRecord(id: 'h1', petId: 'p1', date: DateTime(2025, 1, 1), type: CareCategory.vaccination, title: 'Rabies', nextDue: DateTime(2026, 1, 1)),
        HealthRecord(id: 'h2', petId: 'p1', date: DateTime(2026, 1, 1), type: CareCategory.vetVisit, title: 'Checkup', nextDue: DateTime(2027, 1, 1)),
      ];
      final overdue = service.overdueRecords(records, 'p1');
      expect(overdue.length, 1);
      expect(overdue.first.title, 'Rabies');
    });

    test('upcomingRecords returns due soon', () {
      final records = [
        HealthRecord(id: 'h1', petId: 'p1', date: DateTime(2025, 1, 1), type: CareCategory.vaccination, title: 'Flea med', nextDue: DateTime.now().add(const Duration(days: 5))),
      ];
      final upcoming = service.upcomingRecords(records, 'p1');
      expect(upcoming.length, 1);
    });

    test('entriesForPet returns empty for unknown pet', () {
      expect(service.entriesForPet(entries, 'unknown'), isEmpty);
    });

    test('totalCost returns 0 for pet with no costs', () {
      expect(service.totalCost(entries, 'p2'), 0.0);
    });

    test('careStreak returns 0 for empty entries', () {
      expect(service.careStreak([], 'p1'), 0);
    });
  });
}
