import 'dart:convert';
import 'package:everything/core/utils/date_utils.dart';

/// Type of plant.
enum PlantType {
  succulent,
  tropical,
  herb,
  flowering,
  vine,
  fern,
  cactus,
  tree,
  vegetable,
  other;

  String get label {
    switch (this) {
      case PlantType.succulent: return 'Succulent';
      case PlantType.tropical: return 'Tropical';
      case PlantType.herb: return 'Herb';
      case PlantType.flowering: return 'Flowering';
      case PlantType.vine: return 'Vine';
      case PlantType.fern: return 'Fern';
      case PlantType.cactus: return 'Cactus';
      case PlantType.tree: return 'Tree';
      case PlantType.vegetable: return 'Vegetable';
      case PlantType.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case PlantType.succulent: return '🪴';
      case PlantType.tropical: return '🌴';
      case PlantType.herb: return '🌿';
      case PlantType.flowering: return '🌸';
      case PlantType.vine: return '🌱';
      case PlantType.fern: return '🍃';
      case PlantType.cactus: return '🌵';
      case PlantType.tree: return '🌳';
      case PlantType.vegetable: return '🥬';
      case PlantType.other: return '☘️';
    }
  }

  /// Default watering interval in days.
  int get defaultWateringDays {
    switch (this) {
      case PlantType.succulent: return 10;
      case PlantType.tropical: return 5;
      case PlantType.herb: return 3;
      case PlantType.flowering: return 4;
      case PlantType.vine: return 5;
      case PlantType.fern: return 4;
      case PlantType.cactus: return 14;
      case PlantType.tree: return 7;
      case PlantType.vegetable: return 2;
      case PlantType.other: return 7;
    }
  }
}

/// Sunlight requirement level.
enum SunlightLevel {
  fullSun,
  partialSun,
  shade,
  indirect;

  String get label {
    switch (this) {
      case SunlightLevel.fullSun: return 'Full Sun';
      case SunlightLevel.partialSun: return 'Partial Sun';
      case SunlightLevel.shade: return 'Shade';
      case SunlightLevel.indirect: return 'Indirect Light';
    }
  }

  String get emoji {
    switch (this) {
      case SunlightLevel.fullSun: return '☀️';
      case SunlightLevel.partialSun: return '⛅';
      case SunlightLevel.shade: return '🌑';
      case SunlightLevel.indirect: return '🌤️';
    }
  }
}

/// Type of care action performed.
enum PlantCareAction {
  watering,
  fertilizing,
  pruning,
  repotting,
  pestControl,
  rotating,
  misting,
  other;

  String get label {
    switch (this) {
      case PlantCareAction.watering: return 'Watering';
      case PlantCareAction.fertilizing: return 'Fertilizing';
      case PlantCareAction.pruning: return 'Pruning';
      case PlantCareAction.repotting: return 'Repotting';
      case PlantCareAction.pestControl: return 'Pest Control';
      case PlantCareAction.rotating: return 'Rotating';
      case PlantCareAction.misting: return 'Misting';
      case PlantCareAction.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case PlantCareAction.watering: return '💧';
      case PlantCareAction.fertilizing: return '🧪';
      case PlantCareAction.pruning: return '✂️';
      case PlantCareAction.repotting: return '🪴';
      case PlantCareAction.pestControl: return '🐛';
      case PlantCareAction.rotating: return '🔄';
      case PlantCareAction.misting: return '💨';
      case PlantCareAction.other: return '🌱';
    }
  }
}

/// Health status of a plant.
enum PlantHealth {
  thriving,
  healthy,
  fair,
  struggling,
  critical;

  String get label {
    switch (this) {
      case PlantHealth.thriving: return 'Thriving';
      case PlantHealth.healthy: return 'Healthy';
      case PlantHealth.fair: return 'Fair';
      case PlantHealth.struggling: return 'Struggling';
      case PlantHealth.critical: return 'Critical';
    }
  }

  String get emoji {
    switch (this) {
      case PlantHealth.thriving: return '🌟';
      case PlantHealth.healthy: return '💚';
      case PlantHealth.fair: return '💛';
      case PlantHealth.struggling: return '🟠';
      case PlantHealth.critical: return '🔴';
    }
  }
}

/// A plant profile.
class PlantProfile {
  final String id;
  final String name;
  final PlantType type;
  final SunlightLevel sunlight;
  final String location;
  final int wateringIntervalDays;
  final DateTime dateAdded;
  final String? notes;
  final bool isArchived;

  const PlantProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.sunlight,
    required this.location,
    required this.wateringIntervalDays,
    required this.dateAdded,
    this.notes,
    this.isArchived = false,
  });

  PlantProfile copyWith({
    String? name,
    PlantType? type,
    SunlightLevel? sunlight,
    String? location,
    int? wateringIntervalDays,
    String? notes,
    bool? isArchived,
  }) {
    return PlantProfile(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      sunlight: sunlight ?? this.sunlight,
      location: location ?? this.location,
      wateringIntervalDays: wateringIntervalDays ?? this.wateringIntervalDays,
      dateAdded: dateAdded,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'sunlight': sunlight.name,
        'location': location,
        'wateringIntervalDays': wateringIntervalDays,
        'dateAdded': dateAdded.toIso8601String(),
        'notes': notes,
        'isArchived': isArchived,
      };

  factory PlantProfile.fromJson(Map<String, dynamic> json) {
    return PlantProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PlantType.values.firstWhere((e) => e.name == json['type'],
          orElse: () => PlantType.other),
      sunlight: SunlightLevel.values.firstWhere(
          (e) => e.name == json['sunlight'],
          orElse: () => SunlightLevel.indirect),
      location: json['location'] as String? ?? '',
      wateringIntervalDays: json['wateringIntervalDays'] as int? ?? 7,
      dateAdded: AppDateUtils.safeParse(json['dateAdded'] as String?),
      notes: json['notes'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }
}

/// A care log entry for a plant.
class PlantCareEntry {
  final String id;
  final String plantId;
  final PlantCareAction action;
  final DateTime timestamp;
  final PlantHealth? healthObserved;
  final String? notes;

  const PlantCareEntry({
    required this.id,
    required this.plantId,
    required this.action,
    required this.timestamp,
    this.healthObserved,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'plantId': plantId,
        'action': action.name,
        'timestamp': timestamp.toIso8601String(),
        'healthObserved': healthObserved?.name,
        'notes': notes,
      };

  factory PlantCareEntry.fromJson(Map<String, dynamic> json) {
    return PlantCareEntry(
      id: json['id'] as String,
      plantId: json['plantId'] as String,
      action: PlantCareAction.values.firstWhere(
          (e) => e.name == json['action'],
          orElse: () => PlantCareAction.other),
      timestamp: AppDateUtils.safeParse(json['timestamp'] as String?),
      healthObserved: json['healthObserved'] != null
          ? PlantHealth.values.firstWhere(
              (e) => e.name == json['healthObserved'],
              orElse: () => PlantHealth.fair)
          : null,
      notes: json['notes'] as String?,
    );
  }
}
