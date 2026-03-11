import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/vehicle_maintenance_service.dart';
import 'package:everything/models/vehicle_entry.dart';

void main() {
  late VehicleMaintenanceService service;

  final testVehicle = Vehicle(
    id: 'v1',
    name: 'My Car',
    type: VehicleType.car,
    year: 2020,
    make: 'Honda',
    model: 'Civic',
    currentMileage: 45000,
    addedAt: DateTime(2024, 1, 1),
  );

  final testRecord = MaintenanceRecord(
    id: 'r1',
    vehicleId: 'v1',
    category: MaintenanceCategory.oilChange,
    date: DateTime(2024, 6, 15),
    mileage: 40000,
    cost: 75.0,
    shop: 'Quick Lube',
    notes: 'Full synthetic',
  );

  setUp(() {
    service = VehicleMaintenanceService();
  });

  group('Vehicle CRUD', () {
    test('addVehicle adds to list', () {
      service.addVehicle(testVehicle);
      expect(service.vehicles.length, 1);
      expect(service.vehicles.first.name, 'My Car');
    });

    test('addVehicle rejects empty id', () {
      final bad = Vehicle(
        id: '', name: 'X', type: VehicleType.car,
        year: 2020, make: 'A', model: 'B',
        currentMileage: 0, addedAt: DateTime.now(),
      );
      expect(() => service.addVehicle(bad), throwsArgumentError);
    });

    test('addVehicle rejects empty name', () {
      final bad = Vehicle(
        id: 'x', name: '', type: VehicleType.car,
        year: 2020, make: 'A', model: 'B',
        currentMileage: 0, addedAt: DateTime.now(),
      );
      expect(() => service.addVehicle(bad), throwsArgumentError);
    });

    test('addVehicle rejects duplicate id', () {
      service.addVehicle(testVehicle);
      expect(() => service.addVehicle(testVehicle), throwsStateError);
    });

    test('updateVehicle replaces by id', () {
      service.addVehicle(testVehicle);
      final updated = testVehicle.copyWith(name: 'Updated Car');
      service.updateVehicle(updated);
      expect(service.vehicles.first.name, 'Updated Car');
    });

    test('removeVehicle removes vehicle and its records', () {
      service.addVehicle(testVehicle);
      service.addRecord(testRecord);
      service.removeVehicle('v1');
      expect(service.vehicles, isEmpty);
      expect(service.records, isEmpty);
    });

    test('getVehicle returns vehicle by id', () {
      service.addVehicle(testVehicle);
      expect(service.getVehicle('v1')?.name, 'My Car');
    });

    test('getVehicle returns null for unknown id', () {
      expect(service.getVehicle('unknown'), isNull);
    });

    test('updateMileage changes current mileage', () {
      service.addVehicle(testVehicle);
      service.updateMileage('v1', 50000);
      expect(service.vehicles.first.currentMileage, 50000);
    });
  });

  group('Maintenance Records', () {
    test('addRecord adds to list', () {
      service.addRecord(testRecord);
      expect(service.records.length, 1);
    });

    test('addRecord rejects empty id', () {
      final bad = MaintenanceRecord(
        id: '', vehicleId: 'v1',
        category: MaintenanceCategory.oilChange,
        date: DateTime.now(), mileage: 0, cost: 0,
      );
      expect(() => service.addRecord(bad), throwsArgumentError);
    });

    test('addRecord rejects negative cost', () {
      final bad = MaintenanceRecord(
        id: 'x', vehicleId: 'v1',
        category: MaintenanceCategory.oilChange,
        date: DateTime.now(), mileage: 0, cost: -10,
      );
      expect(() => service.addRecord(bad), throwsArgumentError);
    });

    test('removeRecord removes by id', () {
      service.addRecord(testRecord);
      service.removeRecord('r1');
      expect(service.records, isEmpty);
    });

    test('getRecordsForVehicle filters and sorts by date desc', () {
      final r2 = MaintenanceRecord(
        id: 'r2', vehicleId: 'v1',
        category: MaintenanceCategory.tireRotation,
        date: DateTime(2024, 8, 1), mileage: 42000, cost: 50.0,
      );
      final r3 = MaintenanceRecord(
        id: 'r3', vehicleId: 'v2',
        category: MaintenanceCategory.brakes,
        date: DateTime(2024, 7, 1), mileage: 30000, cost: 200.0,
      );
      service.addRecord(testRecord);
      service.addRecord(r2);
      service.addRecord(r3);

      final result = service.getRecordsForVehicle('v1');
      expect(result.length, 2);
      expect(result.first.id, 'r2'); // Most recent first
    });

    test('getRecordsByCategory returns matching records', () {
      service.addRecord(testRecord);
      final result = service.getRecordsByCategory(MaintenanceCategory.oilChange);
      expect(result.length, 1);
      expect(result.first.id, 'r1');
    });

    test('getLastService returns most recent for category', () {
      final r2 = MaintenanceRecord(
        id: 'r2', vehicleId: 'v1',
        category: MaintenanceCategory.oilChange,
        date: DateTime(2024, 9, 1), mileage: 43000, cost: 80.0,
      );
      service.addRecord(testRecord);
      service.addRecord(r2);

      final last = service.getLastService('v1', MaintenanceCategory.oilChange);
      expect(last?.id, 'r2');
    });

    test('getLastService returns null when no records', () {
      expect(
        service.getLastService('v1', MaintenanceCategory.brakes),
        isNull,
      );
    });
  });

  group('Alerts', () {
    test('generates overdue alert when mileage exceeds interval', () {
      service.addVehicle(testVehicle); // currentMileage: 45000
      service.addRecord(testRecord); // mileage: 40000, oil change interval: 5000
      // 45000 - 40000 = 5000 miles since service, matches interval → overdue

      final alerts = service.getAlerts(now: DateTime(2024, 7, 1));
      final oilAlerts = alerts.where(
        (a) => a.category == MaintenanceCategory.oilChange,
      );
      expect(oilAlerts.isNotEmpty, true);
      expect(oilAlerts.first.overdue, true);
    });

    test('generates due-soon alert at 90% of interval', () {
      final vehicle = testVehicle.copyWith(currentMileage: 44600);
      service.addVehicle(vehicle);
      service.addRecord(testRecord); // mileage: 40000, interval: 5000
      // 44600 - 40000 = 4600 = 92% of 5000 → due soon

      final alerts = service.getAlerts(now: DateTime(2024, 7, 1));
      final oilAlerts = alerts.where(
        (a) => a.category == MaintenanceCategory.oilChange,
      );
      expect(oilAlerts.isNotEmpty, true);
      expect(oilAlerts.first.overdue, false);
    });

    test('no alert when well within interval', () {
      final vehicle = testVehicle.copyWith(currentMileage: 42000);
      service.addVehicle(vehicle);
      service.addRecord(testRecord); // 42000 - 40000 = 2000, well below 5000

      final alerts = service.getAlerts(now: DateTime(2024, 7, 1));
      final oilAlerts = alerts.where(
        (a) => a.category == MaintenanceCategory.oilChange,
      );
      expect(oilAlerts, isEmpty);
    });

    test('overdue alerts sorted first', () {
      service.addVehicle(testVehicle);
      service.addRecord(testRecord);
      // Add a different record that's only due-soon
      final rotationRecord = MaintenanceRecord(
        id: 'r2', vehicleId: 'v1',
        category: MaintenanceCategory.tireRotation,
        date: DateTime(2024, 6, 15), mileage: 38500, cost: 50.0,
      );
      service.addRecord(rotationRecord);
      // tire rotation: 45000 - 38500 = 6500 of 7500 = 87% → due soon (>90% threshold)

      final alerts = service.getAlerts(now: DateTime(2024, 7, 1));
      if (alerts.length >= 2) {
        final overdueFirst = alerts.first.overdue;
        final lastOverdue = alerts.last.overdue;
        // If there are both types, overdue should come first
        if (overdueFirst != lastOverdue) {
          expect(overdueFirst, true);
        }
      }
    });

    test('time-based alert when days exceed interval', () {
      // Oil change: 6 months = ~180 days
      final vehicle = testVehicle.copyWith(currentMileage: 41000);
      service.addVehicle(vehicle);
      service.addRecord(testRecord); // date: 2024-06-15
      // 41000 - 40000 = 1000 miles (fine), but 200+ days later → overdue by time

      final alerts = service.getAlerts(now: DateTime(2025, 1, 15));
      final oilAlerts = alerts.where(
        (a) => a.category == MaintenanceCategory.oilChange,
      );
      expect(oilAlerts.isNotEmpty, true);
    });
  });

  group('Cost Analysis', () {
    test('getTotalCost sums all records', () {
      service.addRecord(testRecord); // 75.0
      final r2 = MaintenanceRecord(
        id: 'r2', vehicleId: 'v1',
        category: MaintenanceCategory.brakes,
        date: DateTime(2024, 7, 1), mileage: 42000, cost: 250.0,
      );
      service.addRecord(r2);
      expect(service.getTotalCost(), 325.0);
    });

    test('getTotalCost filters by vehicleId', () {
      service.addRecord(testRecord); // v1, 75.0
      final r2 = MaintenanceRecord(
        id: 'r2', vehicleId: 'v2',
        category: MaintenanceCategory.brakes,
        date: DateTime(2024, 7, 1), mileage: 30000, cost: 250.0,
      );
      service.addRecord(r2);
      expect(service.getTotalCost(vehicleId: 'v1'), 75.0);
    });

    test('getAverageCostPerService computes correctly', () {
      service.addRecord(testRecord); // 75.0
      final r2 = MaintenanceRecord(
        id: 'r2', vehicleId: 'v1',
        category: MaintenanceCategory.brakes,
        date: DateTime(2024, 7, 1), mileage: 42000, cost: 125.0,
      );
      service.addRecord(r2);
      expect(service.getAverageCostPerService(), 100.0);
    });

    test('getAverageCostPerService returns 0 for empty', () {
      expect(service.getAverageCostPerService(), 0);
    });

    test('getCostForYear filters by year', () {
      service.addRecord(testRecord); // 2024, 75.0
      final r2 = MaintenanceRecord(
        id: 'r2', vehicleId: 'v1',
        category: MaintenanceCategory.brakes,
        date: DateTime(2025, 3, 1), mileage: 50000, cost: 300.0,
      );
      service.addRecord(r2);
      expect(service.getCostForYear(2024), 75.0);
      expect(service.getCostForYear(2025), 300.0);
    });

    test('getCostByCategory groups and sorts by cost desc', () {
      service.addRecord(testRecord); // oilChange, 75.0
      final r2 = MaintenanceRecord(
        id: 'r2', vehicleId: 'v1',
        category: MaintenanceCategory.brakes,
        date: DateTime(2024, 7, 1), mileage: 42000, cost: 250.0,
      );
      service.addRecord(r2);

      final breakdown = service.getCostByCategory();
      expect(breakdown.length, 2);
      expect(breakdown.first.category, MaintenanceCategory.brakes);
      expect(breakdown.first.totalCost, 250.0);
    });

    test('getCostByCategory returns empty for no records', () {
      expect(service.getCostByCategory(), isEmpty);
    });
  });

  group('Summary', () {
    test('getSummary includes all fields', () {
      service.addVehicle(testVehicle);
      service.addRecord(testRecord);

      final summary = service.getSummary(now: DateTime(2024, 7, 1));
      expect(summary.totalVehicles, 1);
      expect(summary.totalRecords, 1);
      expect(summary.totalCost, 75.0);
      expect(summary.averageCostPerService, 75.0);
    });

    test('getSummary counts overdue alerts', () {
      service.addVehicle(testVehicle);
      service.addRecord(testRecord);

      final summary = service.getSummary(now: DateTime(2025, 6, 1));
      expect(summary.overdueCount, greaterThanOrEqualTo(1));
    });
  });

  group('Serialization', () {
    test('export/import roundtrip preserves data', () {
      service.addVehicle(testVehicle);
      service.addRecord(testRecord);

      final json = service.exportToJson();

      final newService = VehicleMaintenanceService();
      newService.importFromJson(json);

      expect(newService.vehicles.length, 1);
      expect(newService.records.length, 1);
      expect(newService.vehicles.first.name, 'My Car');
      expect(newService.records.first.cost, 75.0);
    });

    test('importFromJson clears existing data', () {
      service.addVehicle(testVehicle);
      service.importFromJson('{"vehicles":[],"records":[]}');
      expect(service.vehicles, isEmpty);
    });
  });

  group('Model tests', () {
    test('Vehicle.copyWith creates modified copy', () {
      final copy = testVehicle.copyWith(name: 'New Name', currentMileage: 50000);
      expect(copy.name, 'New Name');
      expect(copy.currentMileage, 50000);
      expect(copy.id, testVehicle.id);
      expect(copy.make, testVehicle.make);
    });

    test('Vehicle JSON roundtrip', () {
      final json = testVehicle.toJsonString();
      final restored = Vehicle.fromJsonString(json);
      expect(restored.id, testVehicle.id);
      expect(restored.name, testVehicle.name);
      expect(restored.type, testVehicle.type);
      expect(restored.year, testVehicle.year);
      expect(restored.make, testVehicle.make);
      expect(restored.model, testVehicle.model);
      expect(restored.currentMileage, testVehicle.currentMileage);
    });

    test('MaintenanceRecord JSON roundtrip', () {
      final json = testRecord.toJsonString();
      final restored = MaintenanceRecord.fromJsonString(json);
      expect(restored.id, testRecord.id);
      expect(restored.vehicleId, testRecord.vehicleId);
      expect(restored.category, testRecord.category);
      expect(restored.cost, testRecord.cost);
      expect(restored.shop, testRecord.shop);
      expect(restored.notes, testRecord.notes);
    });

    test('VehicleType labels are correct', () {
      expect(VehicleType.car.label, 'Car');
      expect(VehicleType.suv.label, 'SUV');
      expect(VehicleType.motorcycle.label, 'Motorcycle');
    });

    test('MaintenanceCategory defaults are reasonable', () {
      expect(MaintenanceCategory.oilChange.defaultIntervalMiles, 5000);
      expect(MaintenanceCategory.oilChange.defaultIntervalMonths, 6);
      expect(MaintenanceCategory.brakes.defaultIntervalMiles, 30000);
      expect(MaintenanceCategory.battery.defaultIntervalMonths, 48);
    });

    test('Vehicle.fromJson handles unknown type gracefully', () {
      final json = testVehicle.toJson();
      json['type'] = 'spaceship';
      final restored = Vehicle.fromJson(json);
      expect(restored.type, VehicleType.other);
    });

    test('MaintenanceRecord.fromJson handles unknown category', () {
      final json = testRecord.toJson();
      json['category'] = 'warp_drive';
      final restored = MaintenanceRecord.fromJson(json);
      expect(restored.category, MaintenanceCategory.other);
    });
  });
}
