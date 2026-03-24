import 'dart:convert';
import 'package:everything/core/utils/date_utils.dart';

/// Type of vehicle.
enum VehicleType {
  car,
  truck,
  suv,
  motorcycle,
  van,
  other;

  String get label {
    switch (this) {
      case VehicleType.car:
        return 'Car';
      case VehicleType.truck:
        return 'Truck';
      case VehicleType.suv:
        return 'SUV';
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.van:
        return 'Van';
      case VehicleType.other:
        return 'Other';
    }
  }
}

/// Category of maintenance task.
enum MaintenanceCategory {
  oilChange,
  tireRotation,
  brakes,
  battery,
  fluids,
  filters,
  belts,
  inspection,
  wipers,
  alignment,
  transmission,
  other;

  String get label {
    switch (this) {
      case MaintenanceCategory.oilChange:
        return 'Oil Change';
      case MaintenanceCategory.tireRotation:
        return 'Tire Rotation';
      case MaintenanceCategory.brakes:
        return 'Brakes';
      case MaintenanceCategory.battery:
        return 'Battery';
      case MaintenanceCategory.fluids:
        return 'Fluids';
      case MaintenanceCategory.filters:
        return 'Filters';
      case MaintenanceCategory.belts:
        return 'Belts';
      case MaintenanceCategory.inspection:
        return 'Inspection';
      case MaintenanceCategory.wipers:
        return 'Wipers';
      case MaintenanceCategory.alignment:
        return 'Alignment';
      case MaintenanceCategory.transmission:
        return 'Transmission';
      case MaintenanceCategory.other:
        return 'Other';
    }
  }

  /// Recommended interval in miles for this maintenance type.
  int get defaultIntervalMiles {
    switch (this) {
      case MaintenanceCategory.oilChange:
        return 5000;
      case MaintenanceCategory.tireRotation:
        return 7500;
      case MaintenanceCategory.brakes:
        return 30000;
      case MaintenanceCategory.battery:
        return 50000;
      case MaintenanceCategory.fluids:
        return 30000;
      case MaintenanceCategory.filters:
        return 15000;
      case MaintenanceCategory.belts:
        return 60000;
      case MaintenanceCategory.inspection:
        return 12000;
      case MaintenanceCategory.wipers:
        return 12000;
      case MaintenanceCategory.alignment:
        return 25000;
      case MaintenanceCategory.transmission:
        return 60000;
      case MaintenanceCategory.other:
        return 10000;
    }
  }

  /// Recommended interval in months.
  int get defaultIntervalMonths {
    switch (this) {
      case MaintenanceCategory.oilChange:
        return 6;
      case MaintenanceCategory.tireRotation:
        return 6;
      case MaintenanceCategory.brakes:
        return 24;
      case MaintenanceCategory.battery:
        return 48;
      case MaintenanceCategory.fluids:
        return 24;
      case MaintenanceCategory.filters:
        return 12;
      case MaintenanceCategory.belts:
        return 48;
      case MaintenanceCategory.inspection:
        return 12;
      case MaintenanceCategory.wipers:
        return 12;
      case MaintenanceCategory.alignment:
        return 24;
      case MaintenanceCategory.transmission:
        return 48;
      case MaintenanceCategory.other:
        return 12;
    }
  }
}

/// A vehicle being tracked.
class Vehicle {
  final String id;
  final String name;
  final VehicleType type;
  final int year;
  final String make;
  final String model;
  final int currentMileage;
  final DateTime addedAt;

  const Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.year,
    required this.make,
    required this.model,
    required this.currentMileage,
    required this.addedAt,
  });

  Vehicle copyWith({
    String? name,
    VehicleType? type,
    int? year,
    String? make,
    String? model,
    int? currentMileage,
  }) {
    return Vehicle(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      year: year ?? this.year,
      make: make ?? this.make,
      model: model ?? this.model,
      currentMileage: currentMileage ?? this.currentMileage,
      addedAt: addedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'year': year,
        'make': make,
        'model': model,
        'currentMileage': currentMileage,
        'addedAt': addedAt.toIso8601String(),
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      name: json['name'] as String,
      type: VehicleType.values.firstWhere(
        (v) => v.name == json['type'],
        orElse: () => VehicleType.other,
      ),
      year: json['year'] as int,
      make: json['make'] as String,
      model: json['model'] as String,
      currentMileage: json['currentMileage'] as int,
      addedAt: AppDateUtils.safeParse(json['addedAt'] as String?),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Vehicle.fromJsonString(String s) =>
      Vehicle.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

/// A completed maintenance record.
class MaintenanceRecord {
  final String id;
  final String vehicleId;
  final MaintenanceCategory category;
  final DateTime date;
  final int mileage;
  final double cost;
  final String? shop;
  final String? notes;

  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.category,
    required this.date,
    required this.mileage,
    required this.cost,
    this.shop,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'category': category.name,
        'date': date.toIso8601String(),
        'mileage': mileage,
        'cost': cost,
        'shop': shop,
        'notes': notes,
      };

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      category: MaintenanceCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => MaintenanceCategory.other,
      ),
      date: AppDateUtils.safeParse(json['date'] as String?),
      mileage: json['mileage'] as int,
      cost: (json['cost'] as num).toDouble(),
      shop: json['shop'] as String?,
      notes: json['notes'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory MaintenanceRecord.fromJsonString(String s) =>
      MaintenanceRecord.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
