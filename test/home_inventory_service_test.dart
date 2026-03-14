import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/inventory_item.dart';
import 'package:everything/core/services/home_inventory_service.dart';

void main() {
  late HomeInventoryService service;

  setUp(() {
    service = HomeInventoryService();
  });

  InventoryItem _makeItem({
    String id = 'i1',
    String name = 'Test Item',
    InventoryRoom room = InventoryRoom.livingRoom,
    InventoryCategory category = InventoryCategory.electronics,
    ItemCondition condition = ItemCondition.good,
    double purchasePrice = 100.0,
    DateTime? purchaseDate,
  }) {
    return InventoryItem(
      id: id,
      name: name,
      room: room,
      category: category,
      condition: condition,
      purchasePrice: purchasePrice,
      purchaseDate: purchaseDate ?? DateTime.now(),
    );
  }

  group('InventoryItem', () {
    test('estimatedValue uses condition depreciation', () {
      final item = _makeItem(
        purchasePrice: 1000.0,
        condition: ItemCondition.fair,
        purchaseDate: DateTime.now(),
      );
      // fair = 0.5, recent purchase = 1.0
      expect(item.estimatedValue, closeTo(500.0, 1.0));
    });

    test('estimatedValue uses currentValue override', () {
      final item = InventoryItem(
        id: 'x',
        name: 'X',
        room: InventoryRoom.office,
        category: InventoryCategory.electronics,
        purchasePrice: 1000.0,
        currentValue: 750.0,
      );
      expect(item.estimatedValue, 750.0);
    });

    test('estimatedValue depreciates with age', () {
      final old = _makeItem(
        purchasePrice: 1000.0,
        condition: ItemCondition.excellent,
        purchaseDate: DateTime.now().subtract(const Duration(days: 2000)),
      );
      // excellent=1.0, >1825 days = 0.3
      expect(old.estimatedValue, closeTo(300.0, 1.0));
    });

    test('toJson and fromJson roundtrip', () {
      final item = _makeItem(
        id: 'rt1',
        name: 'Roundtrip',
        purchasePrice: 555.55,
      );
      final json = item.toJson();
      final restored = InventoryItem.fromJson(json);
      expect(restored.id, item.id);
      expect(restored.name, item.name);
      expect(restored.purchasePrice, item.purchasePrice);
      expect(restored.room, item.room);
      expect(restored.category, item.category);
    });

    test('copyWith creates modified copy', () {
      final item = _makeItem();
      final copy = item.copyWith(name: 'Modified', room: InventoryRoom.kitchen);
      expect(copy.name, 'Modified');
      expect(copy.room, InventoryRoom.kitchen);
      expect(copy.id, item.id);
    });

    test('toJsonString and fromJsonString roundtrip', () {
      final item = _makeItem(name: 'String RT');
      final str = item.toJsonString();
      final restored = InventoryItem.fromJsonString(str);
      expect(restored.name, 'String RT');
    });
  });

  group('InventoryRoom', () {
    test('all rooms have labels', () {
      for (final r in InventoryRoom.values) {
        expect(r.label.isNotEmpty, isTrue);
      }
    });

    test('all rooms have icon data', () {
      for (final r in InventoryRoom.values) {
        expect(r.iconData.emoji.isNotEmpty, isTrue);
      }
    });
  });

  group('ItemCondition', () {
    test('depreciation factors are ordered', () {
      expect(ItemCondition.excellent.depreciationFactor, greaterThan(ItemCondition.good.depreciationFactor));
      expect(ItemCondition.good.depreciationFactor, greaterThan(ItemCondition.fair.depreciationFactor));
      expect(ItemCondition.fair.depreciationFactor, greaterThan(ItemCondition.poor.depreciationFactor));
      expect(ItemCondition.poor.depreciationFactor, greaterThan(ItemCondition.broken.depreciationFactor));
    });
  });

  group('HomeInventoryService', () {
    test('addItem and items', () {
      service.addItem(_makeItem());
      expect(service.items.length, 1);
    });

    test('removeItem', () {
      service.addItem(_makeItem(id: 'r1'));
      service.addItem(_makeItem(id: 'r2'));
      service.removeItem('r1');
      expect(service.items.length, 1);
      expect(service.items.first.id, 'r2');
    });

    test('updateItem', () {
      service.addItem(_makeItem(id: 'u1', name: 'Old'));
      service.updateItem(_makeItem(id: 'u1', name: 'New'));
      expect(service.getItem('u1')!.name, 'New');
    });

    test('getItem returns null for missing', () {
      expect(service.getItem('nope'), isNull);
    });

    test('getItemsByRoom', () {
      service.addItem(_makeItem(id: '1', room: InventoryRoom.kitchen));
      service.addItem(_makeItem(id: '2', room: InventoryRoom.office));
      service.addItem(_makeItem(id: '3', room: InventoryRoom.kitchen));
      expect(service.getItemsByRoom(InventoryRoom.kitchen).length, 2);
    });

    test('getItemsByCategory', () {
      service.addItem(_makeItem(id: '1', category: InventoryCategory.furniture));
      service.addItem(_makeItem(id: '2', category: InventoryCategory.electronics));
      expect(service.getItemsByCategory(InventoryCategory.furniture).length, 1);
    });

    test('getItemsByCondition', () {
      service.addItem(_makeItem(id: '1', condition: ItemCondition.broken));
      service.addItem(_makeItem(id: '2', condition: ItemCondition.good));
      expect(service.getItemsByCondition(ItemCondition.broken).length, 1);
    });

    test('search by name', () {
      service.addItem(_makeItem(id: '1', name: 'Samsung TV'));
      service.addItem(_makeItem(id: '2', name: 'Apple Watch'));
      expect(service.search('samsung').length, 1);
    });

    test('search is case-insensitive', () {
      service.addItem(_makeItem(id: '1', name: 'MacBook Pro'));
      expect(service.search('macbook').length, 1);
    });

    test('getHighValueItems returns sorted', () {
      service.addItem(_makeItem(id: '1', purchasePrice: 100));
      service.addItem(_makeItem(id: '2', purchasePrice: 500));
      service.addItem(_makeItem(id: '3', purchasePrice: 200));
      final top = service.getHighValueItems(limit: 2);
      expect(top.length, 2);
      expect(top.first.purchasePrice, 500);
    });

    test('getSummary empty', () {
      final s = service.getSummary();
      expect(s.totalItems, 0);
      expect(s.roomBreakdown, isEmpty);
    });

    test('getSummary with items', () {
      service.addItem(_makeItem(id: '1', room: InventoryRoom.kitchen, purchasePrice: 200));
      service.addItem(_makeItem(id: '2', room: InventoryRoom.office, purchasePrice: 800));
      final s = service.getSummary();
      expect(s.totalItems, 2);
      expect(s.totalPurchaseValue, 1000);
      expect(s.roomBreakdown.length, 2);
      expect(s.highValueItems.isNotEmpty, isTrue);
    });

    test('getSummary room percentages sum to ~100', () {
      service.addItem(_makeItem(id: '1', room: InventoryRoom.kitchen, purchasePrice: 300));
      service.addItem(_makeItem(id: '2', room: InventoryRoom.office, purchasePrice: 700));
      final s = service.getSummary();
      final totalPct = s.roomBreakdown.fold<double>(0, (sum, r) => sum + r.percentOfTotal);
      expect(totalPct, closeTo(100.0, 0.1));
    });

    test('exportToJson and importFromJson', () {
      service.addItem(_makeItem(id: 'e1', name: 'Export1'));
      service.addItem(_makeItem(id: 'e2', name: 'Export2'));
      final json = service.exportToJson();

      final service2 = HomeInventoryService();
      final count = service2.importFromJson(json);
      expect(count, 2);
      expect(service2.items.length, 2);
    });

    test('generateInsuranceReport contains key sections', () {
      service.addItem(_makeItem(id: '1', name: 'TV', purchasePrice: 999));
      final report = service.generateInsuranceReport();
      expect(report.contains('HOME INVENTORY INSURANCE REPORT'), isTrue);
      expect(report.contains('BREAKDOWN BY ROOM'), isTrue);
      expect(report.contains('HIGH VALUE ITEMS'), isTrue);
      expect(report.contains('TV'), isTrue);
    });

    test('summary depreciation is purchase minus estimated', () {
      service.addItem(_makeItem(
        id: '1',
        purchasePrice: 1000,
        condition: ItemCondition.fair,
        purchaseDate: DateTime.now(),
      ));
      final s = service.getSummary();
      expect(s.depreciationAmount, closeTo(s.totalPurchaseValue - s.totalEstimatedValue, 0.01));
    });

    test('highestValueRoom is set correctly', () {
      service.addItem(_makeItem(id: '1', room: InventoryRoom.kitchen, purchasePrice: 100));
      service.addItem(_makeItem(id: '2', room: InventoryRoom.office, purchasePrice: 900));
      final s = service.getSummary();
      expect(s.highestValueRoom, InventoryRoom.office);
    });

    test('highestValueCategory is set correctly', () {
      service.addItem(_makeItem(id: '1', category: InventoryCategory.furniture, purchasePrice: 100));
      service.addItem(_makeItem(id: '2', category: InventoryCategory.electronics, purchasePrice: 900));
      final s = service.getSummary();
      expect(s.highestValueCategory, InventoryCategory.electronics);
    });
  });

  group('InventoryCategory', () {
    test('all categories have labels', () {
      for (final c in InventoryCategory.values) {
        expect(c.label.isNotEmpty, isTrue);
      }
    });
  });
}
