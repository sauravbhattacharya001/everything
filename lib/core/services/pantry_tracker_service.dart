/// Pantry Tracker Service — manage pantry items with expiration tracking,
/// low-stock alerts, and category/location filtering.

import '../../models/pantry_item.dart';

/// Summary statistics for the pantry.
class PantrySummary {
  final int totalItems;
  final int expiredItems;
  final int expiringSoon; // within 7 days
  final int lowStockItems;
  final Map<PantryCategory, int> itemsByCategory;
  final Map<PantryLocation, int> itemsByLocation;
  final double totalValue;

  const PantrySummary({
    required this.totalItems,
    required this.expiredItems,
    required this.expiringSoon,
    required this.lowStockItems,
    required this.itemsByCategory,
    required this.itemsByLocation,
    required this.totalValue,
  });
}

/// Main service for pantry management.
class PantryTrackerService {
  final List<PantryItem> _items;

  PantryTrackerService({List<PantryItem>? items}) : _items = items ?? [];

  List<PantryItem> get allItems => List.unmodifiable(_items);

  /// Add a new item to the pantry.
  PantryItem addItem({
    required String name,
    required PantryCategory category,
    required PantryLocation location,
    required double quantity,
    required String unit,
    DateTime? expirationDate,
    String? notes,
    double? price,
    double? lowStockThreshold,
  }) {
    final item = PantryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: category,
      location: location,
      quantity: quantity,
      unit: unit,
      expirationDate: expirationDate,
      addedAt: DateTime.now(),
      notes: notes,
      price: price,
      lowStockThreshold: lowStockThreshold,
    );
    _items.add(item);
    return item;
  }

  /// Update an existing item.
  PantryItem? updateItem(String id, PantryItem updated) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return null;
    _items[idx] = updated;
    return updated;
  }

  /// Remove an item.
  bool removeItem(String id) => _items.removeWhere((i) => i.id == id) != null;

  /// Get item by ID.
  PantryItem? getItem(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all expired items.
  List<PantryItem> get expiredItems =>
      _items.where((i) => i.isExpired).toList();

  /// Get items expiring within N days (excluding already expired).
  List<PantryItem> expiringSoon({int days = 7}) => _items
      .where((i) =>
          !i.isExpired &&
          i.expiresWithin(days))
      .toList();

  /// Get items needing restock.
  List<PantryItem> get lowStockItems =>
      _items.where((i) => i.needsRestock).toList();

  /// Filter items by category.
  List<PantryItem> byCategory(PantryCategory category) =>
      _items.where((i) => i.category == category).toList();

  /// Filter items by location.
  List<PantryItem> byLocation(PantryLocation location) =>
      _items.where((i) => i.location == location).toList();

  /// Search items by name.
  List<PantryItem> search(String query) {
    final q = query.toLowerCase();
    return _items.where((i) => i.name.toLowerCase().contains(q)).toList();
  }

  /// Adjust quantity of an item (positive to add, negative to consume).
  PantryItem? adjustQuantity(String id, double delta) {
    final item = getItem(id);
    if (item == null) return null;
    final newQty = (item.quantity + delta).clamp(0.0, double.infinity);
    final updated = item.copyWith(quantity: newQty);
    return updateItem(id, updated);
  }

  /// Get summary statistics.
  PantrySummary getSummary() {
    final byCategory = <PantryCategory, int>{};
    final byLocation = <PantryLocation, int>{};
    double totalValue = 0;

    for (final item in _items) {
      byCategory[item.category] = (byCategory[item.category] ?? 0) + 1;
      byLocation[item.location] = (byLocation[item.location] ?? 0) + 1;
      if (item.price != null) totalValue += item.price! * item.quantity;
    }

    return PantrySummary(
      totalItems: _items.length,
      expiredItems: expiredItems.length,
      expiringSoon: expiringSoon().length,
      lowStockItems: lowStockItems.length,
      itemsByCategory: byCategory,
      itemsByLocation: byLocation,
      totalValue: totalValue,
    );
  }

  /// Sort items by expiration (soonest first, null last).
  List<PantryItem> get sortedByExpiration {
    final withDate =
        _items.where((i) => i.expirationDate != null).toList()
          ..sort((a, b) => a.expirationDate!.compareTo(b.expirationDate!));
    final withoutDate =
        _items.where((i) => i.expirationDate == null).toList();
    return [...withDate, ...withoutDate];
  }

  /// Serialization.
  String toJson() => PantryItem.listToJson(_items);

  factory PantryTrackerService.fromJson(String jsonStr) {
    return PantryTrackerService(items: PantryItem.listFromJson(jsonStr));
  }
}
