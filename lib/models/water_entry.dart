import 'dart:convert';

/// Common drink/container types for quick logging.
enum DrinkType {
  water,
  tea,
  coffee,
  juice,
  milk,
  smoothie,
  soda,
  sports,
  other;

  String get label {
    switch (this) {
      case DrinkType.water:
        return 'Water';
      case DrinkType.tea:
        return 'Tea';
      case DrinkType.coffee:
        return 'Coffee';
      case DrinkType.juice:
        return 'Juice';
      case DrinkType.milk:
        return 'Milk';
      case DrinkType.smoothie:
        return 'Smoothie';
      case DrinkType.soda:
        return 'Soda';
      case DrinkType.sports:
        return 'Sports Drink';
      case DrinkType.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case DrinkType.water:
        return '💧';
      case DrinkType.tea:
        return '🍵';
      case DrinkType.coffee:
        return '☕';
      case DrinkType.juice:
        return '🧃';
      case DrinkType.milk:
        return '🥛';
      case DrinkType.smoothie:
        return '🥤';
      case DrinkType.soda:
        return '🥫';
      case DrinkType.sports:
        return '⚡';
      case DrinkType.other:
        return '🫗';
    }
  }

  /// Hydration factor: 1.0 = fully hydrating, <1.0 = partially (caffeine/sugar).
  double get hydrationFactor {
    switch (this) {
      case DrinkType.water:
        return 1.0;
      case DrinkType.tea:
        return 0.9;
      case DrinkType.coffee:
        return 0.8;
      case DrinkType.juice:
        return 0.85;
      case DrinkType.milk:
        return 0.9;
      case DrinkType.smoothie:
        return 0.85;
      case DrinkType.soda:
        return 0.7;
      case DrinkType.sports:
        return 0.95;
      case DrinkType.other:
        return 0.8;
    }
  }
}

/// Standard container sizes in ml.
enum ContainerSize {
  sip,
  small,
  medium,
  large,
  bottle,
  custom;

  String get label {
    switch (this) {
      case ContainerSize.sip:
        return 'Sip';
      case ContainerSize.small:
        return 'Small Glass';
      case ContainerSize.medium:
        return 'Medium Glass';
      case ContainerSize.large:
        return 'Large Glass';
      case ContainerSize.bottle:
        return 'Bottle';
      case ContainerSize.custom:
        return 'Custom';
    }
  }

  /// Default ml for this container size.
  int get defaultMl {
    switch (this) {
      case ContainerSize.sip:
        return 50;
      case ContainerSize.small:
        return 200;
      case ContainerSize.medium:
        return 300;
      case ContainerSize.large:
        return 400;
      case ContainerSize.bottle:
        return 500;
      case ContainerSize.custom:
        return 250;
    }
  }
}

/// A single water/drink intake entry.
class WaterEntry {
  final String id;
  final DateTime timestamp;
  final int amountMl;
  final DrinkType drinkType;
  final ContainerSize containerSize;
  final String? note;

  const WaterEntry({
    required this.id,
    required this.timestamp,
    required this.amountMl,
    this.drinkType = DrinkType.water,
    this.containerSize = ContainerSize.medium,
    this.note,
  });

  /// Effective hydration in ml, adjusted by drink type.
  double get effectiveHydrationMl => amountMl * drinkType.hydrationFactor;

  WaterEntry copyWith({
    String? id,
    DateTime? timestamp,
    int? amountMl,
    DrinkType? drinkType,
    ContainerSize? containerSize,
    String? note,
  }) {
    return WaterEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      amountMl: amountMl ?? this.amountMl,
      drinkType: drinkType ?? this.drinkType,
      containerSize: containerSize ?? this.containerSize,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'amountMl': amountMl,
      'drinkType': drinkType.name,
      'containerSize': containerSize.name,
      'note': note,
    };
  }

  factory WaterEntry.fromJson(Map<String, dynamic> json) {
    return WaterEntry(
      id: json['id'] as String,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      amountMl: json['amountMl'] as int? ?? 250,
      drinkType: DrinkType.values.firstWhere(
        (v) => v.name == json['drinkType'],
        orElse: () => DrinkType.water,
      ),
      containerSize: ContainerSize.values.firstWhere(
        (v) => v.name == json['containerSize'],
        orElse: () => ContainerSize.medium,
      ),
      note: json['note'] as String?,
    );
  }

  static String encodeList(List<WaterEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<WaterEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => WaterEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
