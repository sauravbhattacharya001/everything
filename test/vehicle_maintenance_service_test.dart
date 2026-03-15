import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/vehicle_maintenance_service.dart';
import 'package:everything/models/vehicle_entry.dart';

void main() {
  late VehicleMaintenanceService service;

  setUp(() {
    service = VehicleMaintenanceService();
  });

  group('Vehicle CRUD', () {
    test('adds and retrieves vehicles', () {
      service.addVehicle(Vehicle(id: 'v1', name: 'Test Car', type: VehicleType.car, year: 2022, make: 'Toyota', model: 'Camry', currentMileage: 30000, addedAt: DateTime.now()));
      expect(service.vehicles.length, 1);
      expect(service.getVehicle('v1')?.name, 'Test Car');
    });

    test('rejects duplicate vehicle id', () {
      final v = Vehicle(id: 'v1', name: 'Car', type: VehicleType.car, year: 2022, make: 'A', model: 'B', currentMileage: 0, addedAt: DateTime.now());
      service.addVehicle(v);
      expect(() => service.addVehicle(v), throwsStateError);
    });

    test('rejects empty id', () {
      expect(() => service.addVehicle(Vehicle(id: '', name: 'Car', type: VehicleType.car, year: 2022, make: 'A', model: 'B', currentMileage: 0, addedAt: DateTime.now())), throwsArgumentError);
    });

    test('removes vehicle and its records', () {
      service.addVehicle(Vehicle(id: 'v1', name: 'Car', type: VehicleType.car, year: 2022, make: 'A', model: 'B', currentMileage: 10000, addedAt: DateTime.now()));
      service.addRecord(MaintenanceRecord(id: 'r1', vehicleId: 'v1', category: MaintenanceCategory.oilChange, date: DateTime.now(), mileage: 10000, cost: 50));
      service.removeVehicle('v1');
      expect(service.vehicles.isEmpty, true);
      expect(service.records.isEmpty, true);
    });

    test('updates mileage', () {
      service.addVehicle(Vehicle(id: 'v1', name: 'Car', type: VehicleType.car, year: 2022, make: 'A', model: 'B', currentMileage: 10000, addedAt: DateTime.now()));
      service.updateMileage('v1', 15000);
      expect(service.getVehicle('v1')!.currentMileage, 15000);
    });
  });

  group('Maintenance Records', () {
    setUp(() {
      service.addVehicle(Vehicle(id: 'v1', name: 'Car', type: VehicleType.car, year: 2022, make: 'A', model: 'B', currentMileage: 30000, addedAt: DateTime.now()));
    });

    test('adds and retrieves records', () {
      service.addRecord(MaintenanceRecord(id: 'r1', vehicleId: 'v1', category: MaintenanceCategory.oilChange, date: DateTime.now(), mileage: 30000, cost: 65));
      expect(service.records.length, 1);
      expect(service.getRecordsForVehicle('v1').length, 1);
    });

    test('rejects negative cost', () {
      expect(() => service.addRecord(MaintenanceRecord(id: 'r1', vehicleId: 'v1', category: MaintenanceCategory.oilChange, date: DateTime.now(), mileage: 30000, cost: -10)), throwsArgumentError);
    });

    test('getLastService returns most recent', () {
      service.addRecord(MaintenanceRecord(id: 'r1', vehicleId: 'v1', category: MaintenanceCategory.oilChange, date: DateTime(2025, 1, 1), mileage: 25000, cost: 50));
      service.addRecord(MaintenanceRecord(id: 'r2', vehicleId: 'v1', category: MaintenanceCategory.oilChange, date: DateTime(2025, 6, 1), mileage: 30000, cost: 65));
      expect(service.getLastService('v1', MaintenanceCategory.oilChange)?.id, 'r2');
    });
  });

  group('Cost Analysis', () {
    setUp(() {
      service.addVehicle(Vehicle(id: 'v1', name: 'Car', type: VehicleType.car, year: 2022, make: 'A', model: 'B', currentMileage: 30000, addedAt: DateTime.now()));
      service.addRecord(MaintenanceRecord(id: 'r1', vehicleId: 'v1', category: MaintenanceCategory.oilChange, date: DateTime.now(), mileage: 30000, cost: 65));
      service.addRecord(MaintenanceRecord(id: 'r2', vehicleId: 'v1', category: MaintenanceCategory.brakes, date: DateTime.now(), mileage: 30000, cost: 450));
    });

    test('totalCost sums all records', () => expect(service.getTotalCost(), 515));
    test('averageCostPerService', () => expect(service.getAverageCostPerService(), 257.5));
    test('costByCategory returns sorted breakdown', () {
      final b = service.getCostByCategory();
      expect(b.first.category, MaintenanceCategory.brakes);
      expect(b.first.totalCost, 450);
    });
  });

  group('Alerts', () {
    test('detects overdue maintenance', () {
      service.addVehicle(Vehicle(id: 'v1', name: 'Car', type: VehicleType.car, year: 2022, make: 'A', model: 'B', currentMileage: 40000, addedAt: DateTime(2024, 1, 1)));
      service.addRecord(MaintenanceRecord(id: 'r1', vehicleId: 'v1', category: MaintenanceCategory.oilChange, date: DateTime(2025, 8, 1), mileage: 34000, cost: 65));
      final alerts = service.getAlerts(now: DateTime(2026, 3, 15));
      expect(alerts.any((a) => a.category == MaintenanceCategory.oilChange && a.overdue), true);
    });
  });

  group('Serialization', () {
    test('export and import round-trips', () {
      service.addVehicle(Vehicle(id: 'v1', name: 'Car', type: VehicleType.car, year: 2022, make: 'A', model: 'B', currentMileage: 30000, addedAt: DateTime(2024, 1, 1)));
      service.addRecord(MaintenanceRecord(id: 'r1', vehicleId: 'v1', category: MaintenanceCategory.oilChange, date: DateTime(2025, 6, 1), mileage: 30000, cost: 65, shop: 'Jiffy Lube', notes: 'Synthetic'));
      final json = service.exportToJson();
      final s2 = VehicleMaintenanceService()..importFromJson(json);
      expect(s2.vehicles.length, 1);
      expect(s2.records.length, 1);
      expect(s2.getVehicle('v1')!.name, 'Car');
      expect(s2.records.first.shop, 'Jiffy Lube');
    });
  });

  group('Summary', () {
    test('returns complete summary', () {
      service.addVehicle(Vehicle(id: 'v1', name: 'Car', type: VehicleType.car, year: 2022, make: 'A', model: 'B', currentMileage: 30000, addedAt: DateTime.now()));
      service.addRecord(MaintenanceRecord(id: 'r1', vehicleId: 'v1', category: MaintenanceCategory.oilChange, date: DateTime.now(), mileage: 30000, cost: 65));
      final s = service.getSummary();
      expect(s.totalVehicles, 1);
      expect(s.totalRecords, 1);
      expect(s.totalCost, 65);
    });
  });
}
