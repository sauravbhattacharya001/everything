import 'dart:convert';
import '../../models/vehicle_entry.dart';

/// Alert for upcoming or overdue maintenance.
class MaintenanceAlert {
  final Vehicle vehicle;
  final MaintenanceCategory category;
  final bool overdue;
  final int? milesSinceLastService;
  final int? daysSinceLastService;
  final String message;

  const MaintenanceAlert({
    required this.vehicle,
    required this.category,
    required this.overdue,
    this.milesSinceLastService,
    this.daysSinceLastService,
    required this.message,
  });
}

/// Cost breakdown by category.
class MaintenanceCostBreakdown {
  final MaintenanceCategory category;
  final int count;
  final double totalCost;
  final double percentOfTotal;

  const MaintenanceCostBreakdown({
    required this.category,
    required this.count,
    required this.totalCost,
    required this.percentOfTotal,
  });
}

/// Summary of maintenance across all vehicles.
class MaintenanceSummary {
  final int totalVehicles;
  final int totalRecords;
  final double totalCost;
  final double averageCostPerService;
  final int alertCount;
  final int overdueCount;
  final List<MaintenanceCostBreakdown> costByCategory;
  final List<MaintenanceAlert> upcomingAlerts;

  const MaintenanceSummary({
    required this.totalVehicles,
    required this.totalRecords,
    required this.totalCost,
    required this.averageCostPerService,
    required this.alertCount,
    required this.overdueCount,
    required this.costByCategory,
    required this.upcomingAlerts,
  });
}

/// Service for managing vehicle maintenance tracking.
class VehicleMaintenanceService {
  final List<Vehicle> _vehicles = [];
  final List<MaintenanceRecord> _records = [];

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  List<MaintenanceRecord> get records => List.unmodifiable(_records);

  // ── Vehicle CRUD ──

  void addVehicle(Vehicle vehicle) {
    if (vehicle.id.isEmpty) throw ArgumentError('Vehicle id cannot be empty');
    if (vehicle.name.isEmpty) throw ArgumentError('Vehicle name cannot be empty');
    if (_vehicles.any((v) => v.id == vehicle.id)) {
      throw StateError('Vehicle with id "${vehicle.id}" already exists');
    }
    _vehicles.add(vehicle);
  }

  void updateVehicle(Vehicle vehicle) {
    final idx = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (idx >= 0) _vehicles[idx] = vehicle;
  }

  void removeVehicle(String id) {
    _vehicles.removeWhere((v) => v.id == id);
    _records.removeWhere((r) => r.vehicleId == id);
  }

  Vehicle? getVehicle(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateMileage(String vehicleId, int mileage) {
    final idx = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (idx >= 0) {
      _vehicles[idx] = _vehicles[idx].copyWith(currentMileage: mileage);
    }
  }

  // ── Maintenance Records ──

  void addRecord(MaintenanceRecord record) {
    if (record.id.isEmpty) throw ArgumentError('Record id cannot be empty');
    if (record.cost < 0) throw ArgumentError('Cost cannot be negative');
    _records.add(record);
  }

  void removeRecord(String id) {
    _records.removeWhere((r) => r.id == id);
  }

  List<MaintenanceRecord> getRecordsForVehicle(String vehicleId) {
    return _records
        .where((r) => r.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<MaintenanceRecord> getRecordsByCategory(MaintenanceCategory category) {
    return _records
        .where((r) => r.category == category)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  MaintenanceRecord? getLastService(
      String vehicleId, MaintenanceCategory category) {
    final vehicleRecords = _records
        .where(
            (r) => r.vehicleId == vehicleId && r.category == category)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return vehicleRecords.isEmpty ? null : vehicleRecords.first;
  }

  // ── Alerts ──

  List<MaintenanceAlert> getAlerts({DateTime? now}) {
    now ??= DateTime.now();
    final alerts = <MaintenanceAlert>[];

    for (final vehicle in _vehicles) {
      for (final category in MaintenanceCategory.values) {
        final last = getLastService(vehicle.id, category);
        if (last == null) continue;

        final milesSince = vehicle.currentMileage - last.mileage;
        final daysSince = now.difference(last.date).inDays;
        final intervalMiles = category.defaultIntervalMiles;
        final intervalDays = category.defaultIntervalMonths * 30;

        final milesOverdue = milesSince >= intervalMiles;
        final daysOverdue = daysSince >= intervalDays;
        final milesDue = milesSince >= (intervalMiles * 0.9);
        final daysDue = daysSince >= (intervalDays * 0.9);

        if (milesOverdue || daysOverdue) {
          alerts.add(MaintenanceAlert(
            vehicle: vehicle,
            category: category,
            overdue: true,
            milesSinceLastService: milesSince,
            daysSinceLastService: daysSince,
            message:
                '${vehicle.name}: ${category.label} is overdue (${milesSince} mi / $daysSince days since last service)',
          ));
        } else if (milesDue || daysDue) {
          alerts.add(MaintenanceAlert(
            vehicle: vehicle,
            category: category,
            overdue: false,
            milesSinceLastService: milesSince,
            daysSinceLastService: daysSince,
            message:
                '${vehicle.name}: ${category.label} coming due (${milesSince} mi / $daysSince days since last service)',
          ));
        }
      }
    }

    // Sort: overdue first, then by miles since service
    alerts.sort((a, b) {
      if (a.overdue != b.overdue) return a.overdue ? -1 : 1;
      return (b.milesSinceLastService ?? 0)
          .compareTo(a.milesSinceLastService ?? 0);
    });

    return alerts;
  }

  // ── Cost Analysis ──

  double getTotalCost({String? vehicleId}) {
    final recs =
        vehicleId != null ? getRecordsForVehicle(vehicleId) : _records;
    return recs.fold(0.0, (sum, r) => sum + r.cost);
  }

  double getAverageCostPerService({String? vehicleId}) {
    final recs =
        vehicleId != null ? getRecordsForVehicle(vehicleId) : _records;
    if (recs.isEmpty) return 0;
    return getTotalCost(vehicleId: vehicleId) / recs.length;
  }

  double getCostForYear(int year, {String? vehicleId}) {
    return _records
        .where((r) =>
            r.date.year == year &&
            (vehicleId == null || r.vehicleId == vehicleId))
        .fold(0.0, (sum, r) => sum + r.cost);
  }

  List<MaintenanceCostBreakdown> getCostByCategory({String? vehicleId}) {
    final recs =
        vehicleId != null ? getRecordsForVehicle(vehicleId) : _records;
    final totalCost = recs.fold(0.0, (double sum, r) => sum + r.cost);
    if (totalCost == 0) return [];

    final grouped = <MaintenanceCategory, List<MaintenanceRecord>>{};
    for (final r in recs) {
      grouped.putIfAbsent(r.category, () => []).add(r);
    }

    return grouped.entries
        .map((e) {
          final catCost = e.value.fold(0.0, (double sum, r) => sum + r.cost);
          return MaintenanceCostBreakdown(
            category: e.key,
            count: e.value.length,
            totalCost: catCost,
            percentOfTotal: (catCost / totalCost * 100),
          );
        })
        .toList()
      ..sort((a, b) => b.totalCost.compareTo(a.totalCost));
  }

  // ── Summary ──

  MaintenanceSummary getSummary({DateTime? now}) {
    final alerts = getAlerts(now: now);
    final costBreakdown = getCostByCategory();
    final totalCost = getTotalCost();

    return MaintenanceSummary(
      totalVehicles: _vehicles.length,
      totalRecords: _records.length,
      totalCost: totalCost,
      averageCostPerService: getAverageCostPerService(),
      alertCount: alerts.length,
      overdueCount: alerts.where((a) => a.overdue).length,
      costByCategory: costBreakdown,
      upcomingAlerts: alerts,
    );
  }

  // ── Serialization ──

  String exportToJson() {
    return jsonEncode({
      'vehicles': _vehicles.map((v) => v.toJson()).toList(),
      'records': _records.map((r) => r.toJson()).toList(),
    });
  }

  /// Maximum number of vehicles or records allowed per import list.
  static const int maxImportEntries = 50000;

  /// Import vehicles and records from a JSON string, replacing current state.
  ///
  /// Throws [ArgumentError] if either list exceeds [maxImportEntries]
  /// to prevent memory exhaustion from untrusted input.
  void importFromJson(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    final vehicleList = data['vehicles'] as List<dynamic>? ?? [];
    final recordList = data['records'] as List<dynamic>? ?? [];

    if (vehicleList.length > maxImportEntries) {
      throw ArgumentError(
        'Vehicle import exceeds maximum of $maxImportEntries entries '
        '(got ${vehicleList.length}).',
      );
    }
    if (recordList.length > maxImportEntries) {
      throw ArgumentError(
        'Record import exceeds maximum of $maxImportEntries entries '
        '(got ${recordList.length}).',
      );
    }

    // Parse first, then clear — preserves existing data on parse failure.
    final parsedVehicles = vehicleList
        .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
        .toList();
    final parsedRecords = recordList
        .map((r) => MaintenanceRecord.fromJson(r as Map<String, dynamic>))
        .toList();

    _vehicles.clear();
    _records.clear();
    _vehicles.addAll(parsedVehicles);
    _records.addAll(parsedRecords);
  }
}
