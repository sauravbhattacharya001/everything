import 'dart:convert';

/// Category for grocery items.
enum GroceryCategory {
  produce,
  dairy,
  meat,
  bakery,
  frozen,
  beverages,
  snacks,
  pantry,
  household,
  personal,
  other;

  String get label {
    switch (this) {
      case GroceryCategory.produce: return 'Produce';
      case GroceryCategory.dairy: return 'Dairy';
      case GroceryCategory.meat: return 'Meat & Seafood';
      case GroceryCategory.bakery: return 'Bakery';
      case GroceryCategory.frozen: return 'Frozen';
      case GroceryCategory.beverages: return 'Beverages';
      case GroceryCategory.snacks: return 'Snacks';
      case GroceryCategory.pantry: return 'Pantry';
      case GroceryCategory.household: return 'Household';
      case GroceryCategory.personal: return 'Personal Care';
      case GroceryCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case GroceryCategory.produce: return '🥬';
      case GroceryCategory.dairy: return '🧀';
      case GroceryCategory.meat: return '🥩';
      case GroceryCategory.bakery: return '🍞';
      case GroceryCategory.frozen: return '🧊';
      case GroceryCategory.beverages: return '🥤';
      case GroceryCategory.snacks: return '🍿';
      case GroceryCategory.pantry: return '🥫';
      case GroceryCategory.household: return '🧹';
      case GroceryCategory.personal: return '🧴';
      case GroceryCategory.other: return '📦';
    }
  }
}

/// Unit of measurement for grocery quantities.
enum GroceryUnit {
  piece,
  lb,
  oz,
  kg,
  g,
  liter,
  ml,
  gallon,
  dozen,
  pack,
  bag,
  box,
  can,
  bottle,
  bunch;

  String get label {
    switch (this) {
      case GroceryUnit.piece: return 'pc';
      case GroceryUnit.lb: return 'lb';
      case GroceryUnit.oz: return 'oz';
      case GroceryUnit.kg: return 'kg';
      case GroceryUnit.g: return 'g';
      case GroceryUnit.liter: return 'L';
      case GroceryUnit.ml: return 'mL';
      case GroceryUnit.gallon: return 'gal';
      case GroceryUnit.dozen: return 'doz';
      case GroceryUnit.pack: return 'pack';
      case GroceryUnit.bag: return 'bag';
      case GroceryUnit.box: return 'box';
      case GroceryUnit.can: return 'can';
      case GroceryUnit.bottle: return 'bottle';
      case GroceryUnit.bunch: return 'bunch';
    }
  }
}

/// Priority level for grocery items.
enum GroceryPriority {
  low,
  normal,
  high,
  urgent;

  String get label {
    switch (this) {
      case GroceryPriority.low: return 'Low';
      case GroceryPriority.normal: return 'Normal';
      case GroceryPriority.high: return 'High';
      case GroceryPriority.urgent: return 'Urgent';
    }
  }

  String get emoji {
    switch (this) {
      case GroceryPriority.low: return '🟢';
      case GroceryPriority.normal: return '🔵';
      case GroceryPriority.high: return '🟠';
      case GroceryPriority.urgent: return '🔴';
    }
  }
}

/// A single grocery item.
class GroceryItem {
  final String id;
  final String name;
  final GroceryCategory category;
  final double quantity;
  final GroceryUnit unit;
  final GroceryPriority priority;
  final String note;
  final bool isChecked;
  final DateTime createdAt;
  final DateTime? checkedAt;
  final double? estimatedPrice;

  const GroceryItem({
    required this.id,
    required this.name,
    this.category = GroceryCategory.other,
    this.quantity = 1,
    this.unit = GroceryUnit.piece,
    this.priority = GroceryPriority.normal,
    this.note = '',
    this.isChecked = false,
    required this.createdAt,
    this.checkedAt,
    this.estimatedPrice,
  });

  GroceryItem copyWith({
    String? name,
    GroceryCategory? category,
    double? quantity,
    GroceryUnit? unit,
    GroceryPriority? priority,
    String? note,
    bool? isChecked,
    DateTime? checkedAt,
    bool clearCheckedAt = false,
    double? estimatedPrice,
    bool clearEstimatedPrice = false,
  }) {
    return GroceryItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      priority: priority ?? this.priority,
      note: note ?? this.note,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt,
      checkedAt: clearCheckedAt ? null : (checkedAt ?? this.checkedAt),
      estimatedPrice: clearEstimatedPrice ? null : (estimatedPrice ?? this.estimatedPrice),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'quantity': quantity,
        'unit': unit.name,
        'priority': priority.name,
        'note': note,
        'isChecked': isChecked,
        'createdAt': createdAt.toIso8601String(),
        'checkedAt': checkedAt?.toIso8601String(),
        'estimatedPrice': estimatedPrice,
      };

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: GroceryCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => GroceryCategory.other,
        ),
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        unit: GroceryUnit.values.firstWhere(
          (u) => u.name == json['unit'],
          orElse: () => GroceryUnit.piece,
        ),
        priority: GroceryPriority.values.firstWhere(
          (p) => p.name == json['priority'],
          orElse: () => GroceryPriority.normal,
        ),
        note: (json['note'] as String?) ?? '',
        isChecked: json['isChecked'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        checkedAt: json['checkedAt'] != null
            ? DateTime.tryParse(json['checkedAt'] as String? ?? '')
            : null,
        estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble(),
      );
}

/// A grocery list (a named collection of items).
class GroceryList {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<GroceryItem> items;
  final bool isArchived;

  const GroceryList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.items = const [],
    this.isArchived = false,
  });

  int get totalItems => items.length;
  int get checkedItems => items.where((i) => i.isChecked).length;
  int get remainingItems => totalItems - checkedItems;
  double get progress => totalItems > 0 ? checkedItems / totalItems : 0;

  double get estimatedTotal {
    double total = 0;
    for (final item in items) {
      if (item.estimatedPrice != null) {
        total += item.estimatedPrice! * item.quantity;
      }
    }
    return total;
  }

  GroceryList copyWith({
    String? name,
    List<GroceryItem>? items,
    bool? isArchived,
  }) {
    return GroceryList(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      items: items ?? List.of(this.items),
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'items': jsonEncode(items.map((i) => i.toJson()).toList()),
        'isArchived': isArchived,
      };

  factory GroceryList.fromJson(Map<String, dynamic> json) {
    List<GroceryItem> parsedItems = [];
    final itemsRaw = json['items'];
    if (itemsRaw is String && itemsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(itemsRaw) as List<dynamic>;
        parsedItems = decoded
            .map((i) => GroceryItem.fromJson(i as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    } else if (itemsRaw is List) {
      parsedItems = itemsRaw
          .map((i) => GroceryItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return GroceryList(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      items: parsedItems,
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }
}
