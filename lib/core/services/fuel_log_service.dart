import 'dart:convert';
import '../../models/fuel_entry.dart';

/// Statistics summary for the fuel log.
class FuelStats {
  final double avgMpg;
  final double avgPricePerGallon;
  final double avgCostPerMile;
  final double totalSpent;
  final double totalGallons;
  final double totalMiles;
  final int fillUpCount;

  const FuelStats({
    required this.avgMpg,
    required this.avgPricePerGallon,
    required this.avgCostPerMile,
    required this.totalSpent,
    required this.totalGallons,
    required this.totalMiles,
    required this.fillUpCount,
  });
}

/// Service for managing fuel log entries and computing stats.
class FuelLogService {
  final List<FuelEntry> _entries = [];

  List<FuelEntry> get entries => List.unmodifiable(_entries);

  void addEntry(FuelEntry entry) {
    _entries.add(entry);
    _entries.sort((a, b) => a.date.compareTo(b.date));
  }

  void removeEntry(int id) {
    _entries.removeWhere((e) => e.id == id);
  }

  /// Get entries for a specific vehicle, sorted by date.
  List<FuelEntry> entriesForVehicle(String vehicleName) {
    return _entries.where((e) => e.vehicleName == vehicleName).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Unique vehicle names in the log.
  List<String> get vehicleNames {
    final names = _entries.map((e) => e.vehicleName).toSet().toList();
    names.sort();
    return names;
  }

  /// Compute MPG for a specific entry (needs previous entry for same vehicle).
  double? mpgForEntry(FuelEntry entry) {
    final vehicleEntries = entriesForVehicle(entry.vehicleName);
    final idx = vehicleEntries.indexWhere((e) => e.id == entry.id);
    if (idx <= 0) return null;
    return entry.mpg(vehicleEntries[idx - 1]);
  }

  /// Overall stats, optionally filtered by vehicle.
  FuelStats stats({String? vehicleName}) {
    final list = vehicleName != null
        ? entriesForVehicle(vehicleName)
        : List<FuelEntry>.from(_entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (list.isEmpty) {
      return const FuelStats(
        avgMpg: 0,
        avgPricePerGallon: 0,
        avgCostPerMile: 0,
        totalSpent: 0,
        totalGallons: 0,
        totalMiles: 0,
        fillUpCount: 0,
      );
    }

    double totalSpent = 0;
    double totalGallons = 0;
    double totalMpgSum = 0;
    int mpgCount = 0;

    for (int i = 0; i < list.length; i++) {
      totalSpent += list[i].totalCost;
      totalGallons += list[i].gallons;
      if (i > 0 && list[i].fullTank) {
        final mpg = list[i].mpg(list[i - 1]);
        if (mpg != null) {
          totalMpgSum += mpg;
          mpgCount++;
        }
      }
    }

    final totalMiles = list.length >= 2
        ? list.last.odometer - list.first.odometer
        : 0.0;
    final avgMpg = mpgCount > 0 ? totalMpgSum / mpgCount : 0.0;
    final avgPrice = totalGallons > 0 ? totalSpent / totalGallons : 0.0;
    final costPerMile = totalMiles > 0 ? totalSpent / totalMiles : 0.0;

    return FuelStats(
      avgMpg: avgMpg,
      avgPricePerGallon: avgPrice,
      avgCostPerMile: costPerMile,
      totalSpent: totalSpent,
      totalGallons: totalGallons,
      totalMiles: totalMiles,
      fillUpCount: list.length,
    );
  }

  /// Monthly spending breakdown.
  Map<String, double> monthlySpending({String? vehicleName}) {
    final list = vehicleName != null ? entriesForVehicle(vehicleName) : _entries;
    final map = <String, double>{};
    for (final e in list) {
      final key =
          '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + e.totalCost;
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  String exportToJson() {
    return jsonEncode(_entries.map((e) => e.toJson()).toList());
  }

  void importFromJson(String json) {
    _entries.clear();
    final list = jsonDecode(json) as List;
    for (final item in list) {
      _entries.add(FuelEntry.fromJson(item as Map<String, dynamic>));
    }
    _entries.sort((a, b) => a.date.compareTo(b.date));
  }
}
