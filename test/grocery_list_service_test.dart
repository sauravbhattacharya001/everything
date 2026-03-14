import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/grocery_list_service.dart';
import 'package:everything/models/grocery_item.dart';

void main() {
  group('GroceryItem model', () {
    test('creates with defaults', () {
      final item = GroceryItem(
        id: '1',
        name: 'Milk',
        createdAt: DateTime(2026, 3, 14),
      );
      expect(item.name, 'Milk');
      expect(item.category, GroceryCategory.other);
      expect(item.quantity, 1);
      expect(item.unit, GroceryUnit.piece);
      expect(item.priority, GroceryPriority.normal);
      expect(item.isChecked, false);
    });

    test('serializes to/from JSON', () {
      final item = GroceryItem(
        id: '1',
        name: 'Eggs',
        category: GroceryCategory.dairy,
        quantity: 2,
        unit: GroceryUnit.dozen,
        priority: GroceryPriority.high,
        note: 'Free range',
        createdAt: DateTime(2026, 3, 14),
        estimatedPrice: 5.99,
      );
      final json = item.toJson();
      final restored = GroceryItem.fromJson(json);
      expect(restored.name, 'Eggs');
      expect(restored.category, GroceryCategory.dairy);
      expect(restored.quantity, 2);
      expect(restored.unit, GroceryUnit.dozen);
      expect(restored.priority, GroceryPriority.high);
      expect(restored.note, 'Free range');
      expect(restored.estimatedPrice, 5.99);
    });

    test('copyWith works', () {
      final item = GroceryItem(
        id: '1',
        name: 'Bread',
        createdAt: DateTime(2026, 3, 14),
      );
      final checked = item.copyWith(isChecked: true, checkedAt: DateTime.now());
      expect(checked.isChecked, true);
      expect(checked.checkedAt, isNotNull);
      expect(checked.name, 'Bread');
    });
  });

  group('GroceryList model', () {
    test('computes progress', () {
      final list = GroceryList(
        id: '1',
        name: 'Weekly',
        createdAt: DateTime(2026, 3, 14),
        items: [
          GroceryItem(id: '1', name: 'A', createdAt: DateTime.now(), isChecked: true),
          GroceryItem(id: '2', name: 'B', createdAt: DateTime.now()),
          GroceryItem(id: '3', name: 'C', createdAt: DateTime.now()),
        ],
      );
      expect(list.totalItems, 3);
      expect(list.checkedItems, 1);
      expect(list.remainingItems, 2);
      expect(list.progress, closeTo(0.333, 0.01));
    });

    test('computes estimated total', () {
      final list = GroceryList(
        id: '1',
        name: 'Shop',
        createdAt: DateTime.now(),
        items: [
          GroceryItem(
              id: '1', name: 'Milk', createdAt: DateTime.now(),
              quantity: 2, estimatedPrice: 3.50),
          GroceryItem(
              id: '2', name: 'Bread', createdAt: DateTime.now(),
              estimatedPrice: 2.00),
        ],
      );
      expect(list.estimatedTotal, 9.0); // 2*3.50 + 1*2.00
    });

    test('serializes to/from JSON', () {
      final list = GroceryList(
        id: '1',
        name: 'Test',
        createdAt: DateTime(2026, 3, 14),
        items: [
          GroceryItem(id: 'a', name: 'Apple', createdAt: DateTime(2026, 3, 14)),
        ],
      );
      final json = list.toJson();
      final restored = GroceryList.fromJson(json);
      expect(restored.name, 'Test');
      expect(restored.items.length, 1);
      expect(restored.items.first.name, 'Apple');
    });
  });

  group('GroceryListService', () {
    late GroceryListService service;

    setUp(() {
      service = GroceryListService();
    });

    test('creates a list', () {
      final list = service.createList('Weekly Shop');
      expect(list.name, 'Weekly Shop');
      expect(service.allLists.length, 1);
      expect(service.activeLists.length, 1);
    });

    test('adds items to a list', () {
      final list = service.createList('Shop');
      final item = service.addItem(list.id, name: 'Bananas',
          category: GroceryCategory.produce, quantity: 6);
      expect(item, isNotNull);
      expect(item!.name, 'Bananas');
      expect(service.getList(list.id)!.totalItems, 1);
    });

    test('toggles item checked status', () {
      final list = service.createList('Shop');
      final item = service.addItem(list.id, name: 'Milk');
      final toggled = service.toggleItem(list.id, item!.id);
      expect(toggled!.isChecked, true);
      expect(toggled.checkedAt, isNotNull);

      final untoggled = service.toggleItem(list.id, item.id);
      expect(untoggled!.isChecked, false);
    });

    test('updates an item', () {
      final list = service.createList('Shop');
      final item = service.addItem(list.id, name: 'Cheese');
      final updated = service.updateItem(list.id, item!.id,
          name: 'Cheddar Cheese', quantity: 2);
      expect(updated!.name, 'Cheddar Cheese');
      expect(updated.quantity, 2);
    });

    test('removes an item', () {
      final list = service.createList('Shop');
      final item = service.addItem(list.id, name: 'X');
      service.removeItem(list.id, item!.id);
      expect(service.getList(list.id)!.totalItems, 0);
    });

    test('clears checked items', () {
      final list = service.createList('Shop');
      service.addItem(list.id, name: 'A');
      final b = service.addItem(list.id, name: 'B');
      service.toggleItem(list.id, b!.id);
      final cleared = service.clearChecked(list.id);
      expect(cleared, 1);
      expect(service.getList(list.id)!.totalItems, 1);
    });

    test('groups items by category', () {
      final list = service.createList('Shop');
      service.addItem(list.id, name: 'Apple', category: GroceryCategory.produce);
      service.addItem(list.id, name: 'Milk', category: GroceryCategory.dairy);
      service.addItem(list.id, name: 'Banana', category: GroceryCategory.produce);

      final grouped = service.getItemsByCategory(list.id);
      expect(grouped[GroceryCategory.produce]!.length, 2);
      expect(grouped[GroceryCategory.dairy]!.length, 1);
    });

    test('gets items by priority', () {
      final list = service.createList('Shop');
      service.addItem(list.id, name: 'Low', priority: GroceryPriority.low);
      service.addItem(list.id, name: 'Urgent', priority: GroceryPriority.urgent);
      service.addItem(list.id, name: 'Normal');

      final sorted = service.getItemsByPriority(list.id);
      expect(sorted.first.name, 'Urgent');
      expect(sorted.last.name, 'Low');
    });

    test('searches items across lists', () {
      final list1 = service.createList('A');
      final list2 = service.createList('B');
      service.addItem(list1.id, name: 'Organic Milk');
      service.addItem(list2.id, name: 'Almond Milk');
      service.addItem(list1.id, name: 'Bread');

      final results = service.searchItems('milk');
      expect(results.length, 2);
    });

    test('tracks frequent items', () {
      final l1 = service.createList('Week 1');
      final l2 = service.createList('Week 2');
      final l3 = service.createList('Week 3');
      service.addItem(l1.id, name: 'Milk');
      service.addItem(l2.id, name: 'Milk');
      service.addItem(l3.id, name: 'Milk');
      service.addItem(l1.id, name: 'Bread');

      final freq = service.frequentItems(limit: 5);
      expect(freq.first.key, 'milk');
      expect(freq.first.value, 3);
    });

    test('archives and unarchives lists', () {
      final list = service.createList('Old');
      service.toggleArchive(list.id);
      expect(service.activeLists.length, 0);
      expect(service.archivedLists.length, 1);

      service.toggleArchive(list.id);
      expect(service.activeLists.length, 1);
    });

    test('duplicates a list', () {
      final list = service.createList('Template');
      service.addItem(list.id, name: 'Rice');
      service.addItem(list.id, name: 'Beans');

      final dup = service.duplicateList(list.id, newName: 'This Week');
      expect(dup, isNotNull);
      expect(dup!.name, 'This Week');
      expect(dup.items.length, 2);
      expect(dup.items.every((i) => !i.isChecked), true);
    });

    test('renames a list', () {
      final list = service.createList('Old Name');
      service.renameList(list.id, 'New Name');
      expect(service.getList(list.id)!.name, 'New Name');
    });

    test('deletes a list', () {
      final list = service.createList('Temp');
      service.deleteList(list.id);
      expect(service.allLists.length, 0);
    });

    test('exports and imports JSON', () {
      final list = service.createList('Export Test');
      service.addItem(list.id, name: 'Tomatoes', category: GroceryCategory.produce);
      service.addItem(list.id, name: 'Cheese', category: GroceryCategory.dairy);

      final json = service.exportToJson();
      final service2 = GroceryListService();
      final imported = service2.importFromJson(json);
      expect(imported, 1);
      expect(service2.allLists.first.items.length, 2);
    });

    test('summary is correct', () {
      final list = service.createList('S1');
      service.addItem(list.id, name: 'A', estimatedPrice: 2.0, category: GroceryCategory.produce);
      service.addItem(list.id, name: 'B', estimatedPrice: 3.0, category: GroceryCategory.dairy);
      final c = service.addItem(list.id, name: 'C', category: GroceryCategory.produce);
      service.toggleItem(list.id, c!.id);

      final summary = service.getSummary();
      expect(summary.totalLists, 1);
      expect(summary.totalItems, 3);
      expect(summary.checkedItems, 1);
      expect(summary.remainingItems, 2);
      expect(summary.estimatedTotal, 5.0);
      expect(summary.itemsByCategory[GroceryCategory.produce], 2);
      expect(summary.itemsByCategory[GroceryCategory.dairy], 1);
    });

    test('returns null for invalid list operations', () {
      expect(service.getList('nonexistent'), isNull);
      expect(service.addItem('nonexistent', name: 'X'), isNull);
      expect(service.toggleItem('nonexistent', 'x'), isNull);
      expect(service.updateItem('nonexistent', 'x'), isNull);
    });

    test('category enums have labels and emojis', () {
      for (final cat in GroceryCategory.values) {
        expect(cat.label.isNotEmpty, true);
        expect(cat.emoji.isNotEmpty, true);
      }
    });

    test('unit enums have labels', () {
      for (final u in GroceryUnit.values) {
        expect(u.label.isNotEmpty, true);
      }
    });

    test('priority enums have labels and emojis', () {
      for (final p in GroceryPriority.values) {
        expect(p.label.isNotEmpty, true);
        expect(p.emoji.isNotEmpty, true);
      }
    });

    test('empty list has zero progress', () {
      final list = GroceryList(
        id: '1', name: 'Empty', createdAt: DateTime.now(),
      );
      expect(list.progress, 0);
      expect(list.estimatedTotal, 0);
    });
  });
}
