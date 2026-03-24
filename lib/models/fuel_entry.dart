/// Data models for the Fuel Log feature.

enum FuelType {
  regular,
  midGrade,
  premium,
  diesel,
  electric,
  other;

  String get label {
    switch (this) {
      case FuelType.regular:
        return 'Regular';
      case FuelType.midGrade:
        return 'Mid-Grade';
      case FuelType.premium:
        return 'Premium';
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.electric:
        return 'Electric (kWh)';
      case FuelType.other:
        return 'Other';
    }
  }
}

class FuelEntry {
  final int id;
  final String vehicleName;
  final DateTime date;
  final double odometer; // miles
  final double gallons; // or kWh for electric
  final double pricePerUnit;
  final double totalCost;
  final FuelType fuelType;
  final bool fullTank;
  final String? station;
  final String? notes;

  const FuelEntry({
    required this.id,
    required this.vehicleName,
    required this.date,
    required this.odometer,
    required this.gallons,
    required this.pricePerUnit,
    required this.totalCost,
    required this.fuelType,
    this.fullTank = true,
    this.station,
    this.notes,
  });

  double? mpg(FuelEntry? previous) {
    if (previous == null || !fullTank) return null;
    final miles = odometer - previous.odometer;
    if (miles <= 0 || gallons <= 0) return null;
    return miles / gallons;
  }

  double get costPerMile {
    // Can only be computed with mpg context; use service method instead.
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleName': vehicleName,
        'date': date.toIso8601String(),
        'odometer': odometer,
        'gallons': gallons,
        'pricePerUnit': pricePerUnit,
        'totalCost': totalCost,
        'fuelType': fuelType.index,
        'fullTank': fullTank,
        'station': station,
        'notes': notes,
      };

  factory FuelEntry.fromJson(Map<String, dynamic> json) => FuelEntry(
        id: json['id'] as int,
        vehicleName: json['vehicleName'] as String,
        date: DateTime.parse(json['date'] as String),
        odometer: (json['odometer'] as num).toDouble(),
        gallons: (json['gallons'] as num).toDouble(),
        pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
        totalCost: (json['totalCost'] as num).toDouble(),
        fuelType: FuelType.values[json['fuelType'] as int],
        fullTank: json['fullTank'] as bool? ?? true,
        station: json['station'] as String?,
        notes: json['notes'] as String?,
      );
}
