import 'dart:convert';
import '../../models/inventory_item.dart';

/// Room-level inventory summary.
class RoomSummary {
  final InventoryRoom room;
  final int itemCount;
  final double totalPurchaseValue;
  final double totalEstimatedValue;
  final double percentOfTotal;
  const RoomSummary({
    required this.room,
    required this.itemCount,
    required this.totalPurchaseValue,
    required this.totalEstimatedValue,
    required this.percentOfTotal,
  });
}

/// Category-level inventory summary.
class CategorySummary {
  final InventoryCategory category;
  final int itemCount;
  final double totalPurchaseValue;
  final double totalEstimatedValue;
  const CategorySummary({
    required this.category,
    required this.itemCount,
    required this.totalPurchaseValue,
    required this.totalEstimatedValue,
  });
}

/// Overall home inventory summary for insurance.
class InventorySummary {
  final int totalItems;
  final double totalPurchaseValue;
  final double totalEstimatedValue;
  final double depreciationAmount;
  final InventoryRoom? highestValueRoom;
  final InventoryCategory? highestValueCategory;
  final List<RoomSummary> roomBreakdown;
  final List<CategorySummary> categoryBreakdown;
  final List<InventoryItem> highValueItems;
  const InventorySummary({
    required this.totalItems,
    required this.totalPurchaseValue,
    required this.totalEstimatedValue,
    required this.depreciationAmount,
    this.highestValueRoom,
    this.highestValueCategory,
    required this.roomBreakdown,
    required this.categoryBreakdown,
    required this.highValueItems,
  });
}

/// Service for managing home inventory items.
class HomeInventoryService {
  final List<InventoryItem> _items = [];

  List<InventoryItem> get items => List.unmodifiable(_items);

  void addItem(InventoryItem item) {
    _items.add(item);
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
  }

  void updateItem(InventoryItem updated) {
    final idx = _items.indexWhere((i) => i.id == updated.id);
    if (idx >= 0) _items[idx] = updated;
  }

  InventoryItem? getItem(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get items filtered by room.
  List<InventoryItem> getItemsByRoom(InventoryRoom room) =>
      _items.where((i) => i.room == room).toList();

  /// Get items filtered by category.
  List<InventoryItem> getItemsByCategory(InventoryCategory category) =>
      _items.where((i) => i.category == category).toList();

  /// Get items filtered by condition.
  List<InventoryItem> getItemsByCondition(ItemCondition condition) =>
      _items.where((i) => i.condition == condition).toList();

  /// Search items by name, brand, or description.
  List<InventoryItem> search(String query) {
    final q = query.toLowerCase();
    return _items.where((i) {
      return i.name.toLowerCase().contains(q) ||
          (i.brand?.toLowerCase().contains(q) ?? false) ||
          (i.description?.toLowerCase().contains(q) ?? false) ||
          (i.model?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  /// Get items sorted by estimated value (descending).
  List<InventoryItem> getHighValueItems({int limit = 10}) {
    final sorted = List<InventoryItem>.from(_items)
      ..sort((a, b) => b.estimatedValue.compareTo(a.estimatedValue));
    return sorted.take(limit).toList();
  }

  /// Generate a comprehensive inventory summary.
  InventorySummary getSummary() {
    if (_items.isEmpty) {
      return const InventorySummary(
        totalItems: 0,
        totalPurchaseValue: 0,
        totalEstimatedValue: 0,
        depreciationAmount: 0,
        roomBreakdown: [],
        categoryBreakdown: [],
        highValueItems: [],
      );
    }

    final totalPurchase =
        _items.fold<double>(0, (s, i) => s + i.purchasePrice);
    final totalEstimated =
        _items.fold<double>(0, (s, i) => s + i.estimatedValue);

    // Room breakdown
    final roomMap = <InventoryRoom, List<InventoryItem>>{};
    for (final item in _items) {
      roomMap.putIfAbsent(item.room, () => []).add(item);
    }
    final roomBreakdown = roomMap.entries.map((e) {
      final roomPurchase =
          e.value.fold<double>(0, (s, i) => s + i.purchasePrice);
      final roomEstimated =
          e.value.fold<double>(0, (s, i) => s + i.estimatedValue);
      return RoomSummary(
        room: e.key,
        itemCount: e.value.length,
        totalPurchaseValue: roomPurchase,
        totalEstimatedValue: roomEstimated,
        percentOfTotal:
            totalEstimated > 0 ? (roomEstimated / totalEstimated) * 100 : 0,
      );
    }).toList()
      ..sort((a, b) => b.totalEstimatedValue.compareTo(a.totalEstimatedValue));

    // Category breakdown
    final catMap = <InventoryCategory, List<InventoryItem>>{};
    for (final item in _items) {
      catMap.putIfAbsent(item.category, () => []).add(item);
    }
    final categoryBreakdown = catMap.entries.map((e) {
      final catPurchase =
          e.value.fold<double>(0, (s, i) => s + i.purchasePrice);
      final catEstimated =
          e.value.fold<double>(0, (s, i) => s + i.estimatedValue);
      return CategorySummary(
        category: e.key,
        itemCount: e.value.length,
        totalPurchaseValue: catPurchase,
        totalEstimatedValue: catEstimated,
      );
    }).toList()
      ..sort((a, b) => b.totalEstimatedValue.compareTo(a.totalEstimatedValue));

    return InventorySummary(
      totalItems: _items.length,
      totalPurchaseValue: totalPurchase,
      totalEstimatedValue: totalEstimated,
      depreciationAmount: totalPurchase - totalEstimated,
      highestValueRoom:
          roomBreakdown.isNotEmpty ? roomBreakdown.first.room : null,
      highestValueCategory:
          categoryBreakdown.isNotEmpty ? categoryBreakdown.first.category : null,
      roomBreakdown: roomBreakdown,
      categoryBreakdown: categoryBreakdown,
      highValueItems: getHighValueItems(limit: 5),
    );
  }

  /// Export inventory to JSON string.
  String exportToJson() {
    return jsonEncode(_items.map((i) => i.toJson()).toList());
  }

  /// Import inventory from JSON string (appends).
  int importFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    int count = 0;
    for (final item in list) {
      _items.add(InventoryItem.fromJson(item as Map<String, dynamic>));
      count++;
    }
    return count;
  }

  /// Generate a text report suitable for insurance documentation.
  String generateInsuranceReport() {
    final summary = getSummary();
    final buf = StringBuffer();
    buf.writeln('HOME INVENTORY INSURANCE REPORT');
    buf.writeln('=' * 40);
    buf.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buf.writeln('Total Items: ${summary.totalItems}');
    buf.writeln(
        'Total Purchase Value: \$${summary.totalPurchaseValue.toStringAsFixed(2)}');
    buf.writeln(
        'Total Estimated Value: \$${summary.totalEstimatedValue.toStringAsFixed(2)}');
    buf.writeln(
        'Total Depreciation: \$${summary.depreciationAmount.toStringAsFixed(2)}');
    buf.writeln();
    buf.writeln('BREAKDOWN BY ROOM');
    buf.writeln('-' * 30);
    for (final room in summary.roomBreakdown) {
      buf.writeln(
          '  ${room.room.label}: ${room.itemCount} items — \$${room.totalEstimatedValue.toStringAsFixed(2)} (${room.percentOfTotal.toStringAsFixed(1)}%)');
    }
    buf.writeln();
    buf.writeln('HIGH VALUE ITEMS');
    buf.writeln('-' * 30);
    for (final item in summary.highValueItems) {
      buf.writeln(
          '  ${item.name} (${item.room.label}): \$${item.estimatedValue.toStringAsFixed(2)}');
    }
    buf.writeln();
    buf.writeln('DETAILED ITEM LIST');
    buf.writeln('-' * 30);
    for (final item in _items) {
      buf.writeln('  ${item.name}');
      buf.writeln('    Room: ${item.room.label}');
      buf.writeln('    Category: ${item.category.label}');
      buf.writeln('    Condition: ${item.condition.label}');
      buf.writeln(
          '    Purchase Price: \$${item.purchasePrice.toStringAsFixed(2)}');
      buf.writeln(
          '    Estimated Value: \$${item.estimatedValue.toStringAsFixed(2)}');
      if (item.brand != null) buf.writeln('    Brand: ${item.brand}');
      if (item.serialNumber != null) {
        buf.writeln('    Serial: ${item.serialNumber}');
      }
      buf.writeln();
    }
    return buf.toString();
  }
}
