import 'dart:convert';
import 'package:flutter/material.dart';

/// Storage location for pantry items.
enum PantryLocation {
  pantry('Pantry', '🗄️', Icons.kitchen),
  fridge('Fridge', '🧊', Icons.ac_unit),
  freezer('Freezer', '❄️', Icons.severe_cold),
  counter('Counter', '🍌', Icons.countertops),
  spiceRack('Spice Rack', '🌶️', Icons.spa),
  other('Other', '📦', Icons.inventory_2);

  final String label;
  final String emoji;
  final IconData icon;
  const PantryLocation(this.label, this.emoji, this.icon);
}

/// Category for pantry items.
enum PantryCategory {
  grains('Grains & Pasta', '🌾'),
  canned('Canned Goods', '🥫'),
  spices('Spices & Herbs', '🧂'),
  oils('Oils & Vinegars', '🫒'),
  baking('Baking', '🧁'),
  snacks('Snacks', '🍿'),
  dairy('Dairy', '🧀'),
  produce('Produce', '🥬'),
  meat('Meat & Seafood', '🥩'),
  frozen('Frozen', '🧊'),
  beverages('Beverages', '🥤'),
  condiments('Condiments & Sauces', '🍯'),
  other('Other', '📦');

  final String label;
  final String emoji;
  const PantryCategory(this.label, this.emoji);
}

/// A single item in the pantry.
class PantryItem {
  final String id;
  final String name;
  final PantryCategory category;
  final PantryLocation location;
  final double quantity;
  final String unit; // e.g. "lbs", "oz", "count", "cups"
  final DateTime? expirationDate;
  final DateTime addedAt;
  final String? notes;
  final double? price;
  final bool isLowStock;
  final double? lowStockThreshold;

  const PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.quantity,
    required this.unit,
    this.expirationDate,
    required this.addedAt,
    this.notes,
    this.price,
    this.isLowStock = false,
    this.lowStockThreshold,
  });

  /// Whether this item is expired.
  bool get isExpired =>
      expirationDate != null && expirationDate!.isBefore(DateTime.now());

  /// Whether this item expires within the given number of days.
  bool expiresWithin(int days) {
    if (expirationDate == null) return false;
    return expirationDate!
        .isBefore(DateTime.now().add(Duration(days: days)));
  }

  /// Days until expiration (negative if expired).
  int? get daysUntilExpiration {
    if (expirationDate == null) return null;
    return expirationDate!.difference(DateTime.now()).inDays;
  }

  /// Whether quantity is at or below the low stock threshold.
  bool get needsRestock =>
      lowStockThreshold != null && quantity <= lowStockThreshold!;

  PantryItem copyWith({
    String? name,
    PantryCategory? category,
    PantryLocation? location,
    double? quantity,
    String? unit,
    DateTime? expirationDate,
    bool clearExpiration = false,
    String? notes,
    bool clearNotes = false,
    double? price,
    bool clearPrice = false,
    bool? isLowStock,
    double? lowStockThreshold,
    bool clearLowStockThreshold = false,
  }) {
    return PantryItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expirationDate:
          clearExpiration ? null : (expirationDate ?? this.expirationDate),
      addedAt: addedAt,
      notes: clearNotes ? null : (notes ?? this.notes),
      price: clearPrice ? null : (price ?? this.price),
      isLowStock: isLowStock ?? this.isLowStock,
      lowStockThreshold: clearLowStockThreshold
          ? null
          : (lowStockThreshold ?? this.lowStockThreshold),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'location': location.name,
        'quantity': quantity,
        'unit': unit,
        'expirationDate': expirationDate?.toIso8601String(),
        'addedAt': addedAt.toIso8601String(),
        'notes': notes,
        'price': price,
        'isLowStock': isLowStock,
        'lowStockThreshold': lowStockThreshold,
      };

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: PantryCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => PantryCategory.other,
        ),
        location: PantryLocation.values.firstWhere(
          (l) => l.name == json['location'],
          orElse: () => PantryLocation.pantry,
        ),
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        expirationDate: json['expirationDate'] != null
            ? DateTime.parse(json['expirationDate'] as String)
            : null,
        addedAt: DateTime.parse(json['addedAt'] as String),
        notes: json['notes'] as String?,
        price: json['price'] != null ? (json['price'] as num).toDouble() : null,
        isLowStock: json['isLowStock'] as bool? ?? false,
        lowStockThreshold: json['lowStockThreshold'] != null
            ? (json['lowStockThreshold'] as num).toDouble()
            : null,
      );

  static List<PantryItem> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list
        .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<PantryItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());
}
