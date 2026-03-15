import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/packing_list_service.dart';
import 'package:everything/models/packing_item.dart';

void main() {
  late PackingListService service;

  setUp(() {
    service = PackingListService();
  });

  group('PackingListService', () {
    test('createFromTemplate populates items', () {
      final list = service.createFromTemplate(
        name: 'Beach Trip',
        templateType: PackingTemplateType.beach,
        tripDays: 3,
      );
      expect(list.name, 'Beach Trip');
      expect(list.items, isNotEmpty);
      expect(list.templateType, PackingTemplateType.beach);
      // Should have universal essentials + beach items
      expect(list.items.length, greaterThan(10));
    });

    test('createEmpty creates list with no items', () {
      final list = service.createEmpty(name: 'Custom');
      expect(list.items, isEmpty);
      expect(list.templateType, PackingTemplateType.custom);
    });

    test('togglePacked toggles item', () {
      final list = service.createFromTemplate(
        name: 'Test',
        templateType: PackingTemplateType.weekend,
      );
      final item = list.items.first;
      expect(item.isPacked, false);

      final toggled = service.togglePacked(list.id, item.id);
      expect(toggled?.isPacked, true);

      final toggled2 = service.togglePacked(list.id, item.id);
      expect(toggled2?.isPacked, false);
    });

    test('packAll marks all items packed', () {
      final list = service.createFromTemplate(
        name: 'Test',
        templateType: PackingTemplateType.weekend,
      );
      expect(list.isFullyPacked, false);

      final packed = service.packAll(list.id);
      expect(packed?.isFullyPacked, true);
    });

    test('addItem adds custom item', () {
      final list = service.createEmpty(name: 'Test');
      service.addItem(
        list.id,
        name: 'Custom Item',
        category: PackingCategory.misc,
        weightGrams: 500,
      );
      final updated = service.getList(list.id)!;
      expect(updated.items.length, 1);
      expect(updated.items.first.name, 'Custom Item');
    });

    test('removeItem removes item', () {
      final list = service.createFromTemplate(
        name: 'Test',
        templateType: PackingTemplateType.weekend,
      );
      final count = list.items.length;
      service.removeItem(list.id, list.items.first.id);
      expect(service.getList(list.id)!.items.length, count - 1);
    });

    test('deleteList removes list', () {
      final list = service.createEmpty(name: 'Test');
      expect(service.allLists.length, 1);
      service.deleteList(list.id);
      expect(service.allLists, isEmpty);
    });

    test('archiveList marks list archived', () {
      final list = service.createEmpty(name: 'Test');
      service.archiveList(list.id);
      expect(service.archivedLists.length, 1);
      expect(service.activeLists, isEmpty);
    });

    test('duplicateList creates copy with unpacked items', () {
      final list = service.createFromTemplate(
        name: 'Original',
        templateType: PackingTemplateType.camping,
      );
      service.packAll(list.id);
      final dup = service.duplicateList(list.id, newName: 'Copy');
      expect(dup, isNotNull);
      expect(dup!.name, 'Copy');
      expect(dup.items.every((i) => !i.isPacked), true);
    });

    test('readinessCheck reports essential items', () {
      final list = service.createFromTemplate(
        name: 'Test',
        templateType: PackingTemplateType.beach,
        departureDate: DateTime.now().add(const Duration(days: 3)),
      );
      final check = service.readinessCheck(list.id);
      expect(check, isNotNull);
      expect(check!.isReady, false);
      expect(check.essentialUnpacked, isNotEmpty);
      expect(check.daysUntilDeparture, greaterThanOrEqualTo(2));
    });

    test('weightBreakdown calculates correctly', () {
      final list = service.createFromTemplate(
        name: 'Test',
        templateType: PackingTemplateType.camping,
      );
      final wb = service.weightBreakdown(list.id);
      expect(wb, isNotNull);
      expect(wb!.totalWeightKg, greaterThan(0));
      expect(wb.byCategory, isNotEmpty);
    });

    test('computeSummary aggregates all lists', () {
      service.createFromTemplate(
        name: 'Trip 1',
        templateType: PackingTemplateType.beach,
      );
      service.createFromTemplate(
        name: 'Trip 2',
        templateType: PackingTemplateType.business,
      );
      final summary = service.computeSummary();
      expect(summary.totalLists, 2);
      expect(summary.totalItems, greaterThan(0));
    });

    test('exportJson and importJson roundtrip', () {
      service.createFromTemplate(
        name: 'Export Test',
        templateType: PackingTemplateType.winter,
      );
      final json = service.exportJson();

      final service2 = PackingListService();
      final count = service2.importJson(json);
      expect(count, 1);
      expect(service2.allLists.first.name, 'Export Test');
    });

    test('scaling clothing by trip days', () {
      final list = service.createFromTemplate(
        name: 'Long Trip',
        templateType: PackingTemplateType.weekend,
        tripDays: 5,
      );
      // Underwear should be scaled to 5
      final underwear =
          list.items.where((i) => i.name == 'Underwear').first;
      expect(underwear.quantity, 5);
    });
  });
}
