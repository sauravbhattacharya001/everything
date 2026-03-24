import 'package:everything/core/utils/date_utils.dart';

/// Model classes for the Packing List feature.

/// Category of packing item.
enum PackingCategory {
  clothing('Clothing', '👕'),
  toiletries('Toiletries', '🧴'),
  electronics('Electronics', '🔌'),
  documents('Documents', '📄'),
  medications('Medications', '💊'),
  food('Food & Snacks', '🍎'),
  accessories('Accessories', '🎒'),
  entertainment('Entertainment', '📚'),
  misc('Miscellaneous', '📦');

  final String label;
  final String emoji;
  const PackingCategory(this.label, this.emoji);
}

/// Priority of a packing item.
enum PackingPriority {
  essential('Essential', '🔴'),
  important('Important', '🟡'),
  optional('Optional', '🟢');

  final String label;
  final String emoji;
  const PackingPriority(this.label, this.emoji);
}

/// Preset template type.
enum PackingTemplateType {
  beach('Beach Vacation', '🏖️'),
  business('Business Trip', '💼'),
  camping('Camping', '⛺'),
  winter('Winter Holiday', '❄️'),
  backpacking('Backpacking', '🎒'),
  weekend('Weekend Getaway', '🌅'),
  family('Family Trip', '👨‍👩‍👧‍👦'),
  custom('Custom', '✏️');

  final String label;
  final String emoji;
  const PackingTemplateType(this.label, this.emoji);
}

/// A single item in a packing list.
class PackingItem {
  final String id;
  final String name;
  final PackingCategory category;
  final PackingPriority priority;
  final int quantity;
  final double? weightGrams;
  final bool isPacked;
  final String? notes;

  const PackingItem({
    required this.id,
    required this.name,
    required this.category,
    this.priority = PackingPriority.important,
    this.quantity = 1,
    this.weightGrams,
    this.isPacked = false,
    this.notes,
  });

  PackingItem copyWith({
    String? id,
    String? name,
    PackingCategory? category,
    PackingPriority? priority,
    int? quantity,
    double? weightGrams,
    bool? isPacked,
    String? notes,
  }) {
    return PackingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      quantity: quantity ?? this.quantity,
      weightGrams: weightGrams ?? this.weightGrams,
      isPacked: isPacked ?? this.isPacked,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'priority': priority.name,
        'quantity': quantity,
        'weightGrams': weightGrams,
        'isPacked': isPacked,
        'notes': notes,
      };

  factory PackingItem.fromJson(Map<String, dynamic> json) {
    return PackingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: PackingCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => PackingCategory.misc,
      ),
      priority: PackingPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => PackingPriority.important,
      ),
      quantity: json['quantity'] as int? ?? 1,
      weightGrams: (json['weightGrams'] as num?)?.toDouble(),
      isPacked: json['isPacked'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}

/// A packing list for a trip.
class PackingList {
  final String id;
  final String name;
  final PackingTemplateType templateType;
  final int tripDays;
  final DateTime createdAt;
  final DateTime? departureDate;
  final List<PackingItem> items;
  final bool isArchived;

  const PackingList({
    required this.id,
    required this.name,
    required this.templateType,
    this.tripDays = 1,
    required this.createdAt,
    this.departureDate,
    this.items = const [],
    this.isArchived = false,
  });

  PackingList copyWith({
    String? id,
    String? name,
    PackingTemplateType? templateType,
    int? tripDays,
    DateTime? createdAt,
    DateTime? departureDate,
    List<PackingItem>? items,
    bool? isArchived,
  }) {
    return PackingList(
      id: id ?? this.id,
      name: name ?? this.name,
      templateType: templateType ?? this.templateType,
      tripDays: tripDays ?? this.tripDays,
      createdAt: createdAt ?? this.createdAt,
      departureDate: departureDate ?? this.departureDate,
      items: items ?? this.items,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  int get totalItems => items.length;
  int get packedItems => items.where((i) => i.isPacked).length;
  int get unpackedItems => totalItems - packedItems;
  double get progressPercent =>
      totalItems == 0 ? 0 : (packedItems / totalItems) * 100;
  bool get isFullyPacked => totalItems > 0 && packedItems == totalItems;

  double get totalWeightGrams {
    double w = 0;
    for (final item in items) {
      if (item.weightGrams != null) {
        w += item.weightGrams! * item.quantity;
      }
    }
    return w;
  }

  double get totalWeightKg => totalWeightGrams / 1000;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'templateType': templateType.name,
        'tripDays': tripDays,
        'createdAt': createdAt.toIso8601String(),
        'departureDate': departureDate?.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
        'isArchived': isArchived,
      };

  factory PackingList.fromJson(Map<String, dynamic> json) {
    return PackingList(
      id: json['id'] as String,
      name: json['name'] as String,
      templateType: PackingTemplateType.values.firstWhere(
        (t) => t.name == json['templateType'],
        orElse: () => PackingTemplateType.custom,
      ),
      tripDays: json['tripDays'] as int? ?? 1,
      createdAt: AppDateUtils.safeParse(json['createdAt'] as String?),
      departureDate: AppDateUtils.safeParseNullable(json['departureDate'] as String?),
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => PackingItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }
}
