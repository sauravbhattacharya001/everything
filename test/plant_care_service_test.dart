import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/plant_care_service.dart';
import 'package:everything/models/plant_entry.dart';

void main() {
  late PlantCareService service;

  setUp(() {
    service = PlantCareService();
  });

  group('PlantType', () {
    test('all types have labels and emoji', () {
      for (final t in PlantType.values) {
        expect(t.label.isNotEmpty, true);
        expect(t.emoji.isNotEmpty, true);
        expect(t.defaultWateringDays, greaterThan(0));
      }
    });
  });

  group('SunlightLevel', () {
    test('all levels have labels and emoji', () {
      for (final s in SunlightLevel.values) {
        expect(s.label.isNotEmpty, true);
        expect(s.emoji.isNotEmpty, true);
      }
    });
  });

  group('PlantCareAction', () {
    test('all actions have labels and emoji', () {
      for (final a in PlantCareAction.values) {
        expect(a.label.isNotEmpty, true);
        expect(a.emoji.isNotEmpty, true);
      }
    });
  });

  group('PlantHealth', () {
    test('all health levels have labels and emoji', () {
      for (final h in PlantHealth.values) {
        expect(h.label.isNotEmpty, true);
        expect(h.emoji.isNotEmpty, true);
      }
    });
  });

  group('PlantProfile', () {
    test('serialization roundtrip', () {
      final plant = PlantProfile(
        id: 'p1',
        name: 'Aloe Vera',
        type: PlantType.succulent,
        sunlight: SunlightLevel.partialSun,
        location: 'Kitchen',
        wateringIntervalDays: 10,
        dateAdded: DateTime(2026, 1, 1),
        notes: 'Gift from mom',
      );
      final json = plant.toJson();
      final restored = PlantProfile.fromJson(json);
      expect(restored.id, plant.id);
      expect(restored.name, plant.name);
      expect(restored.type, plant.type);
      expect(restored.sunlight, plant.sunlight);
      expect(restored.location, plant.location);
      expect(restored.wateringIntervalDays, plant.wateringIntervalDays);
      expect(restored.notes, plant.notes);
      expect(restored.isArchived, false);
    });

    test('copyWith creates modified copy', () {
      final plant = PlantProfile(
        id: 'p1',
        name: 'Fern',
        type: PlantType.fern,
        sunlight: SunlightLevel.shade,
        location: 'Bathroom',
        wateringIntervalDays: 4,
        dateAdded: DateTime(2026, 1, 1),
      );
      final updated = plant.copyWith(name: 'Boston Fern', isArchived: true);
      expect(updated.name, 'Boston Fern');
      expect(updated.isArchived, true);
      expect(updated.id, plant.id);
      expect(updated.type, PlantType.fern);
    });
  });

  group('PlantCareEntry', () {
    test('serialization roundtrip', () {
      final entry = PlantCareEntry(
        id: 'c1',
        plantId: 'p1',
        action: PlantCareAction.watering,
        timestamp: DateTime(2026, 3, 1, 10, 30),
        healthObserved: PlantHealth.healthy,
        notes: 'Soil was dry',
      );
      final json = entry.toJson();
      final restored = PlantCareEntry.fromJson(json);
      expect(restored.id, entry.id);
      expect(restored.plantId, entry.plantId);
      expect(restored.action, PlantCareAction.watering);
      expect(restored.healthObserved, PlantHealth.healthy);
      expect(restored.notes, 'Soil was dry');
    });

    test('serialization with null health', () {
      final entry = PlantCareEntry(
        id: 'c2',
        plantId: 'p1',
        action: PlantCareAction.pruning,
        timestamp: DateTime(2026, 3, 1),
      );
      final json = entry.toJson();
      final restored = PlantCareEntry.fromJson(json);
      expect(restored.healthObserved, isNull);
      expect(restored.notes, isNull);
    });
  });

  group('Plant Management', () {
    test('add plant with defaults', () {
      final plant = service.addPlant(name: 'Cactus', type: PlantType.cactus);
      expect(plant.name, 'Cactus');
      expect(plant.type, PlantType.cactus);
      expect(plant.wateringIntervalDays, 14); // cactus default
      expect(service.plants.length, 1);
      expect(service.activePlants.length, 1);
    });

    test('add plant with custom interval', () {
      final plant = service.addPlant(
        name: 'Tomato',
        type: PlantType.vegetable,
        wateringIntervalDays: 1,
        location: 'Garden',
        sunlight: SunlightLevel.fullSun,
      );
      expect(plant.wateringIntervalDays, 1);
      expect(plant.location, 'Garden');
      expect(plant.sunlight, SunlightLevel.fullSun);
    });

    test('get plant by id', () {
      final plant = service.addPlant(name: 'Rose', type: PlantType.flowering);
      expect(service.getPlant(plant.id), isNotNull);
      expect(service.getPlant('nonexistent'), isNull);
    });

    test('update plant', () {
      final plant = service.addPlant(name: 'Fern', type: PlantType.fern);
      final updated = service.updatePlant(plant.id, name: 'Boston Fern');
      expect(updated?.name, 'Boston Fern');
      expect(updated?.type, PlantType.fern);
    });

    test('archive and unarchive', () {
      final plant = service.addPlant(name: 'Old Plant', type: PlantType.other);
      service.updatePlant(plant.id, isArchived: true);
      expect(service.activePlants.length, 0);
      expect(service.archivedPlants.length, 1);
      service.updatePlant(plant.id, isArchived: false);
      expect(service.activePlants.length, 1);
    });

    test('remove plant also removes care log', () {
      final plant = service.addPlant(name: 'Test', type: PlantType.herb);
      service.logCare(plantId: plant.id, action: PlantCareAction.watering);
      service.logCare(plantId: plant.id, action: PlantCareAction.pruning);
      expect(service.careLog.length, 2);
      service.removePlant(plant.id);
      expect(service.plants.length, 0);
      expect(service.careLog.length, 0);
    });
  });

  group('Care Logging', () {
    test('log care entry', () {
      final plant = service.addPlant(name: 'Basil', type: PlantType.herb);
      final entry = service.logCare(
        plantId: plant.id,
        action: PlantCareAction.watering,
        healthObserved: PlantHealth.thriving,
        notes: 'Looking great',
      );
      expect(entry.plantId, plant.id);
      expect(entry.action, PlantCareAction.watering);
      expect(entry.healthObserved, PlantHealth.thriving);
      expect(service.careLog.length, 1);
    });

    test('get care log for specific plant', () {
      final p1 = service.addPlant(name: 'A', type: PlantType.herb);
      final p2 = service.addPlant(name: 'B', type: PlantType.fern);
      service.logCare(plantId: p1.id, action: PlantCareAction.watering);
      service.logCare(plantId: p2.id, action: PlantCareAction.misting);
      service.logCare(plantId: p1.id, action: PlantCareAction.fertilizing);
      expect(service.getCareLog(p1.id).length, 2);
      expect(service.getCareLog(p2.id).length, 1);
    });

    test('care log respects limit', () {
      final plant = service.addPlant(name: 'X', type: PlantType.other);
      for (int i = 0; i < 10; i++) {
        service.logCare(plantId: plant.id, action: PlantCareAction.watering);
      }
      expect(service.getCareLog(plant.id, limit: 3).length, 3);
    });

    test('remove care entry', () {
      final plant = service.addPlant(name: 'Y', type: PlantType.cactus);
      final entry = service.logCare(
          plantId: plant.id, action: PlantCareAction.watering);
      expect(service.removeCareEntry(entry.id), true);
      expect(service.careLog.length, 0);
    });
  });

  group('Watering Schedule', () {
    test('last watered returns most recent watering', () {
      final plant = service.addPlant(name: 'Mint', type: PlantType.herb);
      expect(service.getLastWatered(plant.id), isNull);
      final t1 = DateTime(2026, 3, 1);
      final t2 = DateTime(2026, 3, 5);
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.watering,
          timestamp: t1);
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.watering,
          timestamp: t2);
      expect(service.getLastWatered(plant.id), t2);
    });

    test('next watering calculated from interval', () {
      final plant = service.addPlant(
          name: 'Cactus', type: PlantType.cactus); // 14 days
      final waterDate = DateTime(2026, 3, 1);
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.watering,
          timestamp: waterDate);
      final next = service.getNextWatering(plant.id);
      expect(next, DateTime(2026, 3, 15));
    });

    test('overdue detection', () {
      final plant = service.addPlant(
          name: 'Herb', type: PlantType.herb, wateringIntervalDays: 3);
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.watering,
          timestamp: DateTime(2026, 3, 1));
      expect(service.isOverdue(plant.id, now: DateTime(2026, 3, 3)), false);
      expect(service.isOverdue(plant.id, now: DateTime(2026, 3, 5)), true);
      expect(service.overdueDays(plant.id, now: DateTime(2026, 3, 7)), 3);
    });

    test('get overdue plants', () {
      final p1 = service.addPlant(
          name: 'A', type: PlantType.herb, wateringIntervalDays: 2);
      final p2 = service.addPlant(
          name: 'B', type: PlantType.cactus, wateringIntervalDays: 14);
      final now = DateTime(2026, 3, 10);
      service.logCare(
          plantId: p1.id,
          action: PlantCareAction.watering,
          timestamp: DateTime(2026, 3, 1));
      service.logCare(
          plantId: p2.id,
          action: PlantCareAction.watering,
          timestamp: DateTime(2026, 3, 1));
      final overdue = service.getOverduePlants(now: now);
      expect(overdue.length, 2); // both overdue by day 10
    });

    test('plants needing water soon', () {
      final plant = service.addPlant(
          name: 'Fern', type: PlantType.fern, wateringIntervalDays: 5);
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.watering,
          timestamp: DateTime(2026, 3, 1));
      // Next watering: March 6. On March 4, within 2 days.
      final soon =
          service.getPlantsNeedingWaterSoon(withinDays: 2, now: DateTime(2026, 3, 4));
      expect(soon.length, 1);
      // On March 2, not within 2 days.
      final notSoon =
          service.getPlantsNeedingWaterSoon(withinDays: 2, now: DateTime(2026, 3, 2));
      expect(notSoon.length, 0);
    });
  });

  group('Health Tracking', () {
    test('last health observation', () {
      final plant = service.addPlant(name: 'Rose', type: PlantType.flowering);
      expect(service.getLastHealth(plant.id), isNull);
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.watering,
          healthObserved: PlantHealth.healthy,
          timestamp: DateTime(2026, 3, 1));
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.pruning,
          healthObserved: PlantHealth.thriving,
          timestamp: DateTime(2026, 3, 5));
      expect(service.getLastHealth(plant.id), PlantHealth.thriving);
    });

    test('health history with limit', () {
      final plant = service.addPlant(name: 'Test', type: PlantType.other);
      final healthValues = [
        PlantHealth.fair,
        PlantHealth.healthy,
        PlantHealth.thriving,
      ];
      for (int i = 0; i < 3; i++) {
        service.logCare(
          plantId: plant.id,
          action: PlantCareAction.watering,
          healthObserved: healthValues[i],
          timestamp: DateTime(2026, 3, i + 1),
        );
      }
      expect(service.getHealthHistory(plant.id).length, 3);
      expect(service.getHealthHistory(plant.id, limit: 2).length, 2);
    });
  });

  group('Streaks', () {
    test('care streak counts consecutive days', () {
      final plant = service.addPlant(name: 'Daily', type: PlantType.herb);
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.watering,
          timestamp: DateTime(2026, 3, 8));
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.misting,
          timestamp: DateTime(2026, 3, 7));
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.watering,
          timestamp: DateTime(2026, 3, 6));
      expect(service.getCareStreak(plant.id, now: DateTime(2026, 3, 8)), 3);
    });

    test('garden care streak across all plants', () {
      final p1 = service.addPlant(name: 'A', type: PlantType.herb);
      final p2 = service.addPlant(name: 'B', type: PlantType.fern);
      service.logCare(
          plantId: p1.id,
          action: PlantCareAction.watering,
          timestamp: DateTime(2026, 3, 8));
      service.logCare(
          plantId: p2.id,
          action: PlantCareAction.misting,
          timestamp: DateTime(2026, 3, 7));
      expect(
          service.getGardenCareStreak(now: DateTime(2026, 3, 8)), 2);
    });
  });

  group('Plant Summary', () {
    test('generates correct summary', () {
      final plant = service.addPlant(
          name: 'Aloe', type: PlantType.succulent, wateringIntervalDays: 10);
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.watering,
          healthObserved: PlantHealth.healthy,
          timestamp: DateTime(2026, 3, 1));
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.pruning,
          timestamp: DateTime(2026, 3, 5));
      final summary =
          service.getPlantSummary(plant.id, now: DateTime(2026, 3, 8));
      expect(summary.plant.name, 'Aloe');
      expect(summary.totalCareActions, 2);
      expect(summary.lastHealth, PlantHealth.healthy);
      expect(summary.isOverdue, false); // due March 11
      expect(summary.actionCounts[PlantCareAction.watering], 1);
      expect(summary.actionCounts[PlantCareAction.pruning], 1);
    });

    test('throws for unknown plant', () {
      expect(() => service.getPlantSummary('nope'), throwsArgumentError);
    });
  });

  group('Garden Summary', () {
    test('aggregates across plants', () {
      service.addPlant(
          name: 'A', type: PlantType.herb, location: 'Kitchen');
      service.addPlant(
          name: 'B', type: PlantType.herb, location: 'Kitchen');
      service.addPlant(
          name: 'C', type: PlantType.cactus, location: 'Office');
      final summary = service.getGardenSummary();
      expect(summary.totalPlants, 3);
      expect(summary.activePlants, 3);
      expect(summary.byType[PlantType.herb], 2);
      expect(summary.byType[PlantType.cactus], 1);
      expect(summary.byLocation['Kitchen'], 2);
      expect(summary.byLocation['Office'], 1);
    });

    test('health grade from score', () {
      final plant = service.addPlant(name: 'X', type: PlantType.other);
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.watering,
          healthObserved: PlantHealth.thriving);
      final summary = service.getGardenSummary();
      expect(summary.healthGrade, 'A'); // 100
    });

    test('empty garden summary', () {
      final summary = service.getGardenSummary();
      expect(summary.totalPlants, 0);
      expect(summary.overallHealthScore, 0);
    });
  });

  group('Recommendations', () {
    test('warns about overdue plants', () {
      final plant = service.addPlant(
          name: 'Thirsty', type: PlantType.herb, wateringIntervalDays: 2);
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.watering,
          timestamp: DateTime(2026, 3, 1));
      final tips = service.getRecommendations(now: DateTime(2026, 3, 10));
      expect(tips.any((t) => t.contains('Thirsty')), true);
      expect(tips.any((t) => t.contains('overdue')), true);
    });

    test('warns about struggling plants', () {
      final plant = service.addPlant(name: 'Sick', type: PlantType.other);
      service.logCare(
          plantId: plant.id,
          action: PlantCareAction.watering,
          healthObserved: PlantHealth.critical);
      final tips = service.getRecommendations();
      expect(tips.any((t) => t.contains('Sick')), true);
    });

    test('encourages first care log', () {
      service.addPlant(name: 'New', type: PlantType.fern);
      final tips = service.getRecommendations();
      expect(tips.any((t) => t.contains('Start logging')), true);
    });
  });

  group('Serialization', () {
    test('export and import roundtrip', () {
      final p = service.addPlant(
        name: 'Mint',
        type: PlantType.herb,
        location: 'Window',
        sunlight: SunlightLevel.fullSun,
      );
      service.logCare(
        plantId: p.id,
        action: PlantCareAction.watering,
        healthObserved: PlantHealth.healthy,
      );
      service.logCare(
        plantId: p.id,
        action: PlantCareAction.fertilizing,
      );

      final exported = service.export();
      final newService = PlantCareService();
      newService.import(exported);

      expect(newService.plants.length, 1);
      expect(newService.plants.first.name, 'Mint');
      expect(newService.plants.first.location, 'Window');
      expect(newService.careLog.length, 2);
    });

    test('toJson and loadFromJson', () {
      service.addPlant(name: 'A', type: PlantType.cactus);
      service.addPlant(name: 'B', type: PlantType.fern);
      final json = service.toJson();
      final newService = PlantCareService();
      newService.loadFromJson(json);
      expect(newService.plants.length, 2);
    });
  });
}
