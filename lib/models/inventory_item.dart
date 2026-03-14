import 'dart:convert';

/// Room/location where an item is kept.
enum InventoryRoom {
  livingRoom,
  bedroom,
  kitchen,
  bathroom,
  garage,
  office,
  basement,
  attic,
  diningRoom,
  laundry,
  outdoor,
  storage,
  other;

  String get label {
    switch (this) {
      case InventoryRoom.livingRoom:
        return 'Living Room';
      case InventoryRoom.bedroom:
        return 'Bedroom';
      case InventoryRoom.kitchen:
        return 'Kitchen';
      case InventoryRoom.bathroom:
        return 'Bathroom';
      case InventoryRoom.garage:
        return 'Garage';
      case InventoryRoom.office:
        return 'Office';
      case InventoryRoom.basement:
        return 'Basement';
      case InventoryRoom.attic:
        return 'Attic';
      case InventoryRoom.diningRoom:
        return 'Dining Room';
      case InventoryRoom.laundry:
        return 'Laundry';
      case InventoryRoom.outdoor:
        return 'Outdoor';
      case InventoryRoom.storage:
        return 'Storage';
      case InventoryRoom.other:
        return 'Other';
    }
  }

  IconLabel get iconData {
    switch (this) {
      case InventoryRoom.livingRoom:
        return const IconLabel('🛋️', 'Living Room');
      case InventoryRoom.bedroom:
        return const IconLabel('🛏️', 'Bedroom');
      case InventoryRoom.kitchen:
        return const IconLabel('🍳', 'Kitchen');
      case InventoryRoom.bathroom:
        return const IconLabel('🚿', 'Bathroom');
      case InventoryRoom.garage:
        return const IconLabel('🚗', 'Garage');
      case InventoryRoom.office:
        return const IconLabel('💻', 'Office');
      case InventoryRoom.basement:
        return const IconLabel('🏚️', 'Basement');
      case InventoryRoom.attic:
        return const IconLabel('📦', 'Attic');
      case InventoryRoom.diningRoom:
        return const IconLabel('🍽️', 'Dining Room');
      case InventoryRoom.laundry:
        return const IconLabel('🧺', 'Laundry');
      case InventoryRoom.outdoor:
        return const IconLabel('🌿', 'Outdoor');
      case InventoryRoom.storage:
        return const IconLabel('🗄️', 'Storage');
      case InventoryRoom.other:
        return const IconLabel('📍', 'Other');
    }
  }
}

/// Simple helper for icon + label pairs.
class IconLabel {
  final String emoji;
  final String text;
  const IconLabel(this.emoji, this.text);
}

/// Condition rating for an inventory item.
enum ItemCondition {
  excellent,
  good,
  fair,
  poor,
  broken;

  String get label {
    switch (this) {
      case ItemCondition.excellent:
        return 'Excellent';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.poor:
        return 'Poor';
      case ItemCondition.broken:
        return 'Broken';
    }
  }

  double get depreciationFactor {
    switch (this) {
      case ItemCondition.excellent:
        return 1.0;
      case ItemCondition.good:
        return 0.8;
      case ItemCondition.fair:
        return 0.5;
      case ItemCondition.poor:
        return 0.25;
      case ItemCondition.broken:
        return 0.05;
    }
  }
}

/// Category of inventory item.
enum InventoryCategory {
  electronics,
  furniture,
  appliance,
  clothing,
  jewelry,
  art,
  collectible,
  sporting,
  tool,
  instrument,
  book,
  kitchenware,
  other;

  String get label {
    switch (this) {
      case InventoryCategory.electronics:
        return 'Electronics';
      case InventoryCategory.furniture:
        return 'Furniture';
      case InventoryCategory.appliance:
        return 'Appliance';
      case InventoryCategory.clothing:
        return 'Clothing';
      case InventoryCategory.jewelry:
        return 'Jewelry';
      case InventoryCategory.art:
        return 'Art';
      case InventoryCategory.collectible:
        return 'Collectible';
      case InventoryCategory.sporting:
        return 'Sporting';
      case InventoryCategory.tool:
        return 'Tool';
      case InventoryCategory.instrument:
        return 'Instrument';
      case InventoryCategory.book:
        return 'Book';
      case InventoryCategory.kitchenware:
        return 'Kitchenware';
      case InventoryCategory.other:
        return 'Other';
    }
  }
}

/// A single inventory item in the home.
class InventoryItem {
  final String id;
  final String name;
  final String? description;
  final InventoryRoom room;
  final InventoryCategory category;
  final ItemCondition condition;
  final double purchasePrice;
  final double? currentValue;
  final DateTime? purchaseDate;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final String? notes;
  final DateTime createdAt;

  InventoryItem({
    required this.id,
    required this.name,
    this.description,
    required this.room,
    required this.category,
    this.condition = ItemCondition.good,
    required this.purchasePrice,
    this.currentValue,
    this.purchaseDate,
    this.brand,
    this.model,
    this.serialNumber,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Estimated current value based on condition and age depreciation.
  double get estimatedValue {
    if (currentValue != null) return currentValue!;
    final ageFactor = purchaseDate != null
        ? _ageDepreciation(DateTime.now().difference(purchaseDate!).inDays)
        : 0.7;
    return purchasePrice * condition.depreciationFactor * ageFactor;
  }

  double _ageDepreciation(int daysOwned) {
    if (daysOwned < 30) return 1.0;
    if (daysOwned < 365) return 0.9;
    if (daysOwned < 730) return 0.75;
    if (daysOwned < 1825) return 0.5;
    return 0.3;
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? description,
    InventoryRoom? room,
    InventoryCategory? category,
    ItemCondition? condition,
    double? purchasePrice,
    double? currentValue,
    DateTime? purchaseDate,
    String? brand,
    String? model,
    String? serialNumber,
    String? notes,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      room: room ?? this.room,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentValue: currentValue ?? this.currentValue,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'room': room.index,
        'category': category.index,
        'condition': condition.index,
        'purchasePrice': purchasePrice,
        'currentValue': currentValue,
        'purchaseDate': purchaseDate?.toIso8601String(),
        'brand': brand,
        'model': model,
        'serialNumber': serialNumber,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        room: InventoryRoom.values[json['room'] as int],
        category: InventoryCategory.values[json['category'] as int],
        condition: ItemCondition.values[json['condition'] as int],
        purchasePrice: (json['purchasePrice'] as num).toDouble(),
        currentValue: json['currentValue'] != null
            ? (json['currentValue'] as num).toDouble()
            : null,
        purchaseDate: json['purchaseDate'] != null
            ? DateTime.parse(json['purchaseDate'] as String)
            : null,
        brand: json['brand'] as String?,
        model: json['model'] as String?,
        serialNumber: json['serialNumber'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String toJsonString() => jsonEncode(toJson());

  factory InventoryItem.fromJsonString(String source) =>
      InventoryItem.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
