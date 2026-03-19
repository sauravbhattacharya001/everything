/// Grocery List Service — manage multiple grocery lists with categorized items,
/// quantities, price estimates, and shopping history.

import 'dart:convert';
import '../../models/grocery_item.dart';

/// Summary statistics for grocery tracking.
class GrocerySummary {
  final int totalLists;
  final int activeLists;
  final int archivedLists;
  final int totalItems;
  final int checkedItems;
  final int remainingItems;
  final double estimatedTotal;
  final Map<GroceryCategory, int> itemsByCategory;

  const GrocerySummary({
    required this.totalLists,
    required this.activeLists,
    required this.archivedLists,
    required this.totalItems,
    required this.checkedItems,
    required this.remainingItems,
    required this.estimatedTotal,
    required this.itemsByCategory,
  });
}

/// Main service for grocery list management.
class GroceryListService {
  final List<GroceryList> _lists;

  GroceryListService({List<GroceryList>? lists}) : _lists = lists ?? [];

  List<GroceryList> get allLists => List.unmodifiable(_lists);
  List<GroceryList> get activeLists =>
      _lists.where((l) => !l.isArchived).toList();
  List<GroceryList> get archivedLists =>
      _lists.where((l) => l.isArchived).toList();

  /// Create a new grocery list.
  GroceryList createList(String name) {
    final list = GroceryList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    _lists.add(list);
    return list;
  }

  /// Get a list by ID.
  GroceryList? getList(String listId) {
    try {
      return _lists.firstWhere((l) => l.id == listId);
    } catch (_) {
      return null;
    }
  }

  /// Rename a list.
  GroceryList? renameList(String listId, String newName) {
    final index = _lists.indexWhere((l) => l.id == listId);
    if (index < 0) return null;
    _lists[index] = _lists[index].copyWith(name: newName);
    return _lists[index];
  }

  /// Archive/unarchive a list.
  GroceryList? toggleArchive(String listId) {
    final index = _lists.indexWhere((l) => l.id == listId);
    if (index < 0) return null;
    _lists[index] = _lists[index].copyWith(isArchived: !_lists[index].isArchived);
    return _lists[index];
  }

  /// Delete a list.
  bool deleteList(String listId) {
    final before = _lists.length;
    _lists.removeWhere((l) => l.id == listId);
    return _lists.length < before;
  }

  /// Add an item to a list.
  GroceryItem? addItem(
    String listId, {
    required String name,
    GroceryCategory category = GroceryCategory.other,
    double quantity = 1,
    GroceryUnit unit = GroceryUnit.piece,
    GroceryPriority priority = GroceryPriority.normal,
    String note = '',
    double? estimatedPrice,
  }) {
    final index = _lists.indexWhere((l) => l.id == listId);
    if (index < 0) return null;

    final item = GroceryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: category,
      quantity: quantity,
      unit: unit,
      priority: priority,
      note: note,
      createdAt: DateTime.now(),
      estimatedPrice: estimatedPrice,
    );

    final items = List<GroceryItem>.from(_lists[index].items)..add(item);
    _lists[index] = _lists[index].copyWith(items: items);
    return item;
  }

  /// Toggle an item's checked status.
  GroceryItem? toggleItem(String listId, String itemId) {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex < 0) return null;

    final items = List<GroceryItem>.from(_lists[listIndex].items);
    final itemIndex = items.indexWhere((i) => i.id == itemId);
    if (itemIndex < 0) return null;

    final item = items[itemIndex];
    items[itemIndex] = item.copyWith(
      isChecked: !item.isChecked,
      checkedAt: !item.isChecked ? DateTime.now() : null,
      clearCheckedAt: item.isChecked,
    );

    _lists[listIndex] = _lists[listIndex].copyWith(items: items);
    return items[itemIndex];
  }

  /// Update an existing item.
  GroceryItem? updateItem(String listId, String itemId, {
    String? name,
    GroceryCategory? category,
    double? quantity,
    GroceryUnit? unit,
    GroceryPriority? priority,
    String? note,
    double? estimatedPrice,
  }) {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex < 0) return null;

    final items = List<GroceryItem>.from(_lists[listIndex].items);
    final itemIndex = items.indexWhere((i) => i.id == itemId);
    if (itemIndex < 0) return null;

    items[itemIndex] = items[itemIndex].copyWith(
      name: name,
      category: category,
      quantity: quantity,
      unit: unit,
      priority: priority,
      note: note,
      estimatedPrice: estimatedPrice,
    );

    _lists[listIndex] = _lists[listIndex].copyWith(items: items);
    return items[itemIndex];
  }

  /// Remove an item from a list.
  bool removeItem(String listId, String itemId) {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex < 0) return false;

    final items = List<GroceryItem>.from(_lists[listIndex].items);
    final before = items.length;
    items.removeWhere((i) => i.id == itemId);
    _lists[listIndex] = _lists[listIndex].copyWith(items: items);
    return items.length < before;
  }

  /// Remove all checked items from a list.
  int clearChecked(String listId) {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex < 0) return 0;

    final items = List<GroceryItem>.from(_lists[listIndex].items);
    final before = items.length;
    items.removeWhere((i) => i.isChecked);
    _lists[listIndex] = _lists[listIndex].copyWith(items: items);
    return before - items.length;
  }

  /// Get items grouped by category.
  Map<GroceryCategory, List<GroceryItem>> getItemsByCategory(String listId) {
    final list = getList(listId);
    if (list == null) return {};

    final grouped = <GroceryCategory, List<GroceryItem>>{};
    for (final item in list.items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  /// Get items sorted by priority (urgent first).
  List<GroceryItem> getItemsByPriority(String listId) {
    final list = getList(listId);
    if (list == null) return [];

    final items = List<GroceryItem>.from(list.items);
    items.sort((a, b) {
      // Unchecked before checked
      if (a.isChecked != b.isChecked) return a.isChecked ? 1 : -1;
      // Then by priority (urgent first)
      return b.priority.index.compareTo(a.priority.index);
    });
    return items;
  }

  /// Search items across all lists.
  List<MapEntry<GroceryList, GroceryItem>> searchItems(String query) {
    final q = query.toLowerCase();
    final results = <MapEntry<GroceryList, GroceryItem>>[];
    for (final list in _lists) {
      for (final item in list.items) {
        if (item.name.toLowerCase().contains(q) ||
            item.note.toLowerCase().contains(q)) {
          results.add(MapEntry(list, item));
        }
      }
    }
    return results;
  }

  /// Get frequently purchased items (across all lists).
  List<MapEntry<String, int>> frequentItems({int limit = 20}) {
    final counts = <String, int>{};
    for (final list in _lists) {
      for (final item in list.items) {
        final key = item.name.toLowerCase();
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Get summary statistics.
  GrocerySummary getSummary() {
    int totalItems = 0;
    int checkedItems = 0;
    double estimatedTotal = 0;
    final byCategory = <GroceryCategory, int>{};

    for (final list in _lists) {
      totalItems += list.totalItems;
      checkedItems += list.checkedItems;
      estimatedTotal += list.estimatedTotal;

      for (final item in list.items) {
        byCategory[item.category] = (byCategory[item.category] ?? 0) + 1;
      }
    }

    return GrocerySummary(
      totalLists: _lists.length,
      activeLists: activeLists.length,
      archivedLists: archivedLists.length,
      totalItems: totalItems,
      checkedItems: checkedItems,
      remainingItems: totalItems - checkedItems,
      estimatedTotal: estimatedTotal,
      itemsByCategory: byCategory,
    );
  }

  /// Duplicate a list (creates a copy with all items unchecked).
  GroceryList? duplicateList(String listId, {String? newName}) {
    final source = getList(listId);
    if (source == null) return null;

    final newList = GroceryList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: newName ?? '${source.name} (copy)',
      createdAt: DateTime.now(),
      items: source.items
          .map((i) => GroceryItem(
                id: '${DateTime.now().millisecondsSinceEpoch}_${i.id}',
                name: i.name,
                category: i.category,
                quantity: i.quantity,
                unit: i.unit,
                priority: i.priority,
                note: i.note,
                createdAt: DateTime.now(),
                estimatedPrice: i.estimatedPrice,
              ))
          .toList(),
    );
    _lists.add(newList);
    return newList;
  }

  /// Export all lists to JSON.
  String exportToJson() {
    return jsonEncode(_lists.map((l) => l.toJson()).toList());
  }

  /// Import lists from JSON.
  /// Maximum entries allowed via [importFromJson] to prevent memory exhaustion.
  static const int maxImportEntries = 50000;

  int importFromJson(String json) {
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      if (decoded.length > maxImportEntries) {
        throw ArgumentError(
          'Import exceeds maximum of $maxImportEntries entries '
          '(got ${decoded.length}). This limit prevents memory exhaustion '
          'from corrupted or malicious data.',
        );
      }
      int count = 0;
      for (final item in decoded) {
        final list = GroceryList.fromJson(item as Map<String, dynamic>);
        _lists.add(list);
        count++;
      }
      return count;
    } on ArgumentError {
      rethrow;
    } catch (_) {
      return 0;
    }
  }
}
