import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/packing_list_service.dart';
import 'package:everything/models/packing_item.dart';

void main() {
  // ── Model Tests ─────────────────────────────────────────────────

  group('PackingItem model', () {
    test('creates with defaults', () {
      final item = PackingItem(id: '1', name: 'Shirt', category: PackingCategory.clothing);
      expect(item.name, 'Shirt');
      expect(item.priority, PackingPriority.important);
      expect(item.quantity, 1);
      expect(item.isPacked, false);
      expect(item.weightGrams, isNull);
      expect(item.notes, isNull);
    });

    test('serializes to/from JSON', () {
      final item = PackingItem(
        id: '1',
        name: 'Laptop',
        category: PackingCategory.electronics,
        priority: PackingPriority.essential,
        quantity: 1,
        weightGrams: 1500,
        isPacked: true,
        notes: 'Work laptop',
      );
      final json = item.toJson();
      final restored = PackingItem.fromJson(json);
      expect(restored.name, 'Laptop');
      expect(restored.category, PackingCategory.electronics);
      expect(restored.priority, PackingPriority.essential);
      expect(restored.weightGrams, 1500);
      expect(restored.isPacked, true);
      expect(restored.notes, 'Work laptop');
    });

    test('copyWith overrides fields', () {
      final item = PackingItem(id: '1', name: 'Shirt', category: PackingCategory.clothing);
      final packed = item.copyWith(isPacked: true, quantity: 3);
      expect(packed.isPacked, true);
      expect(packed.quantity, 3);
      expect(packed.name, 'Shirt'); // unchanged
    });

    test('fromJson handles missing optional fields', () {
      final item = PackingItem.fromJson({'id': '1', 'name': 'Pen', 'category': 'misc'});
      expect(item.priority, PackingPriority.important);
      expect(item.quantity, 1);
      expect(item.isPacked, false);
    });
  });

  group('PackingList model', () {
    test('computes progress correctly', () {
      final list = PackingList(
        id: '1',
        name: 'Test',
        templateType: PackingTemplateType.custom,
        createdAt: DateTime(2026, 3, 14),
        items: [
          PackingItem(id: 'a', name: 'A', category: PackingCategory.clothing, isPacked: true),
          PackingItem(id: 'b', name: 'B', category: PackingCategory.clothing, isPacked: false),
          PackingItem(id: 'c', name: 'C', category: PackingCategory.clothing, isPacked: true),
        ],
      );
      expect(list.totalItems, 3);
      expect(list.packedItems, 2);
      expect(list.unpackedItems, 1);
      expect(list.progressPercent, closeTo(66.67, 0.1));
      expect(list.isFullyPacked, false);
    });

    test('empty list has 0% progress', () {
      final list = PackingList(
        id: '1', name: 'Empty', templateType: PackingTemplateType.custom,
        createdAt: DateTime(2026, 3, 14),
      );
      expect(list.progressPercent, 0);
      expect(list.isFullyPacked, false);
    });

    test('fully packed list detected', () {
      final list = PackingList(
        id: '1', name: 'Done', templateType: PackingTemplateType.custom,
        createdAt: DateTime(2026, 3, 14),
        items: [
          PackingItem(id: 'a', name: 'A', category: PackingCategory.clothing, isPacked: true),
        ],
      );
      expect(list.isFullyPacked, true);
      expect(list.progressPercent, 100);
    });

    test('weight calculation accounts for quantity', () {
      final list = PackingList(
        id: '1', name: 'W', templateType: PackingTemplateType.custom,
        createdAt: DateTime(2026, 3, 14),
        items: [
          PackingItem(id: 'a', name: 'A', category: PackingCategory.clothing, weightGrams: 200, quantity: 3),
          PackingItem(id: 'b', name: 'B', category: PackingCategory.electronics, weightGrams: 1500),
        ],
      );
      expect(list.totalWeightGrams, 2100);
      expect(list.totalWeightKg, closeTo(2.1, 0.01));
    });

    test('serializes to/from JSON', () {
      final list = PackingList(
        id: '1', name: 'Trip', templateType: PackingTemplateType.beach,
        tripDays: 5,
        createdAt: DateTime(2026, 3, 14),
        departureDate: DateTime(2026, 4, 1),
        items: [PackingItem(id: 'a', name: 'Sunscreen', category: PackingCategory.toiletries)],
      );
      final json = list.toJson();
      final restored = PackingList.fromJson(json);
      expect(restored.name, 'Trip');
      expect(restored.templateType, PackingTemplateType.beach);
      expect(restored.tripDays, 5);
      expect(restored.items.length, 1);
      expect(restored.departureDate, isNotNull);
    });
  });

  // ── Service Tests ───────────────────────────────────────────────

  group('PackingListService', () {
    late PackingListService service;

    setUp(() {
      service = PackingListService();
    });

    // ── Create ────────────────────────────────────────────────

    test('createFromTemplate populates items', () {
      final list = service.createFromTemplate(
        name: 'Beach Trip',
        templateType: PackingTemplateType.beach,
        tripDays: 5,
      );
      expect(list.name, 'Beach Trip');
      expect(list.templateType, PackingTemplateType.beach);
      expect(list.tripDays, 5);
      expect(list.items.length, greaterThan(10)); // essentials + beach items
      expect(list.items.every((i) => !i.isPacked), true);
    });

    test('createFromTemplate scales clothing by trip days', () {
      final list = service.createFromTemplate(
        name: '7-day Trip',
        templateType: PackingTemplateType.weekend,
        tripDays: 7,
      );
      // Universal essentials like underwear/socks should have quantity=7
      final underwear = list.items.firstWhere((i) => i.name == 'Underwear');
      expect(underwear.quantity, 7);
      final socks = list.items.firstWhere((i) => i.name == 'Socks');
      expect(socks.quantity, 7);
    });

    test('createFromTemplate avoids duplicate items', () {
      final list = service.createFromTemplate(
        name: 'Backpacking',
        templateType: PackingTemplateType.backpacking,
      );
      final names = list.items.map((i) => i.name.toLowerCase()).toList();
      expect(names.toSet().length, names.length); // no dupes
    });

    test('createEmpty creates list with no items', () {
      final list = service.createEmpty(name: 'Custom');
      expect(list.items, isEmpty);
      expect(list.templateType, PackingTemplateType.custom);
    });

    test('all template types produce non-empty lists', () {
      for (final t in PackingTemplateType.values) {
        if (t == PackingTemplateType.custom) continue;
        final list = service.createFromTemplate(name: t.name, templateType: t);
        expect(list.items.isNotEmpty, true, reason: '${t.name} should have items');
      }
    });

    // ── CRUD ──────────────────────────────────────────────────

    test('getList returns list by ID', () {
      final created = service.createEmpty(name: 'Find Me');
      final found = service.getList(created.id);
      expect(found, isNotNull);
      expect(found!.name, 'Find Me');
    });

    test('getList returns null for unknown ID', () {
      expect(service.getList('nonexistent'), isNull);
    });

    test('archiveList marks list as archived', () {
      final list = service.createEmpty(name: 'Archive Me');
      final archived = service.archiveList(list.id);
      expect(archived!.isArchived, true);
      expect(service.activeLists, isEmpty);
      expect(service.archivedLists.length, 1);
    });

    test('unarchiveList restores list', () {
      final list = service.createEmpty(name: 'Restore');
      service.archiveList(list.id);
      final restored = service.unarchiveList(list.id);
      expect(restored!.isArchived, false);
      expect(service.activeLists.length, 1);
    });

    // ── Item Management ───────────────────────────────────────

    test('addItem adds item to list', () {
      final list = service.createEmpty(name: 'Trip');
      final item = service.addItem(list.id,
        name: 'Jacket',
        category: PackingCategory.clothing,
        weightGrams: 800,
      );
      expect(item, isNotNull);
      expect(item!.name, 'Jacket');
      expect(service.getList(list.id)!.items.length, 1);
    });

    test('addItem returns null for unknown list', () {
      expect(service.addItem('nope', name: 'X', category: PackingCategory.misc), isNull);
    });

    test('removeItem removes item from list', () {
      final list = service.createEmpty(name: 'Trip');
      final item = service.addItem(list.id, name: 'Sock', category: PackingCategory.clothing);
      expect(service.removeItem(list.id, item!.id), true);
      expect(service.getList(list.id)!.items, isEmpty);
    });

    test('removeItem returns false for unknown item', () {
      final list = service.createEmpty(name: 'Trip');
      expect(service.removeItem(list.id, 'nope'), false);
    });

    test('togglePacked toggles item status', () {
      final list = service.createEmpty(name: 'Trip');
      final item = service.addItem(list.id, name: 'Hat', category: PackingCategory.accessories);
      expect(item!.isPacked, false);

      final toggled = service.togglePacked(list.id, item.id);
      expect(toggled!.isPacked, true);

      final toggled2 = service.togglePacked(list.id, item.id);
      expect(toggled2!.isPacked, false);
    });

    test('packAll packs everything', () {
      final list = service.createFromTemplate(
        name: 'Pack All',
        templateType: PackingTemplateType.weekend,
      );
      final packed = service.packAll(list.id);
      expect(packed!.isFullyPacked, true);
      expect(packed.items.every((i) => i.isPacked), true);
    });

    test('unpackAll resets all items', () {
      final list = service.createFromTemplate(
        name: 'Unpack',
        templateType: PackingTemplateType.weekend,
      );
      service.packAll(list.id);
      final unpacked = service.unpackAll(list.id);
      expect(unpacked!.items.every((i) => !i.isPacked), true);
    });

    // ── Duplicate ─────────────────────────────────────────────

    test('duplicateList creates copy with all items unpacked', () {
      final orig = service.createFromTemplate(
        name: 'Original',
        templateType: PackingTemplateType.beach,
      );
      service.packAll(orig.id);

      final dupe = service.duplicateList(orig.id, newName: 'Copy');
      expect(dupe, isNotNull);
      expect(dupe!.name, 'Copy');
      expect(dupe.items.length, orig.items.length);
      expect(dupe.items.every((i) => !i.isPacked), true); // all unpacked
      expect(dupe.id, isNot(orig.id));
      expect(service.allLists.length, 2);
    });

    test('duplicateList returns null for unknown list', () {
      expect(service.duplicateList('nope', newName: 'X'), isNull);
    });

    // ── Weight Breakdown ──────────────────────────────────────

    test('weightBreakdown computes category weights', () {
      final list = service.createEmpty(name: 'Weight Test');
      service.addItem(list.id, name: 'Shirt', category: PackingCategory.clothing, weightGrams: 200);
      service.addItem(list.id, name: 'Laptop', category: PackingCategory.electronics, weightGrams: 1500);
      service.addItem(list.id, name: 'Charger', category: PackingCategory.electronics, weightGrams: 300);

      final wb = service.weightBreakdown(list.id);
      expect(wb, isNotNull);
      expect(wb!.totalWeightKg, closeTo(2.0, 0.01));
      expect(wb.byCategory[PackingCategory.electronics], closeTo(1.8, 0.01));
      expect(wb.byCategory[PackingCategory.clothing], closeTo(0.2, 0.01));
      expect(wb.heaviestItem, 'Laptop');
      expect(wb.heaviestItemWeightGrams, 1500);
    });

    test('weightBreakdown tracks items without weight', () {
      final list = service.createEmpty(name: 'No Weight');
      service.addItem(list.id, name: 'Mystery', category: PackingCategory.misc);
      service.addItem(list.id, name: 'Known', category: PackingCategory.misc, weightGrams: 100);

      final wb = service.weightBreakdown(list.id);
      expect(wb!.itemsWithoutWeight, 1);
    });

    test('weightBreakdown returns null for unknown list', () {
      expect(service.weightBreakdown('nope'), isNull);
    });

    // ── Readiness Check ───────────────────────────────────────

    test('readinessCheck identifies unpacked essentials', () {
      final list = service.createEmpty(name: 'Check');
      service.addItem(list.id, name: 'Passport', category: PackingCategory.documents,
        priority: PackingPriority.essential);
      service.addItem(list.id, name: 'Book', category: PackingCategory.entertainment,
        priority: PackingPriority.optional);

      final check = service.readinessCheck(list.id);
      expect(check, isNotNull);
      expect(check!.isReady, false);
      expect(check.essentialUnpacked.length, 1);
      expect(check.essentialUnpacked.first.name, 'Passport');
      expect(check.optionalUnpacked.length, 1);
    });

    test('readinessCheck reports ready when essentials packed', () {
      final list = service.createEmpty(name: 'Ready');
      final item = service.addItem(list.id, name: 'Passport',
        category: PackingCategory.documents, priority: PackingPriority.essential);
      service.togglePacked(list.id, item!.id);

      final check = service.readinessCheck(list.id);
      expect(check!.isReady, true);
      expect(check.essentialUnpacked, isEmpty);
    });

    test('readinessCheck computes days until departure', () {
      final departure = DateTime(2026, 4, 1);
      final list = service.createEmpty(name: 'Depart', departureDate: departure);
      final check = service.readinessCheck(list.id, now: DateTime(2026, 3, 28));
      expect(check!.daysUntilDeparture, 4);
    });

    test('readinessCheck returns -1 when no departure date', () {
      final list = service.createEmpty(name: 'No Date');
      final check = service.readinessCheck(list.id);
      expect(check!.daysUntilDeparture, -1);
    });

    // ── Summary ───────────────────────────────────────────────

    test('computeSummary aggregates across all lists', () {
      service.createFromTemplate(name: 'Trip 1', templateType: PackingTemplateType.beach);
      service.createFromTemplate(name: 'Trip 2', templateType: PackingTemplateType.weekend);

      final summary = service.computeSummary();
      expect(summary.totalLists, 2);
      expect(summary.activeLists, 2);
      expect(summary.totalItems, greaterThan(0));
      expect(summary.packedItems, 0);
      expect(summary.overallProgressPercent, 0);
    });

    test('computeSummary finds next departure', () {
      service.createEmpty(name: 'Far', departureDate: DateTime(2026, 6, 1));
      service.createEmpty(name: 'Soon', departureDate: DateTime(2026, 4, 1));
      service.createEmpty(name: 'Past', departureDate: DateTime(2026, 2, 1));

      final summary = service.computeSummary(now: DateTime(2026, 3, 15));
      expect(summary.nextDeparture, isNotNull);
      expect(summary.nextDeparture!.name, 'Soon');
    });

    test('computeSummary counts fully packed lists', () {
      final list = service.createFromTemplate(
        name: 'Done',
        templateType: PackingTemplateType.weekend,
      );
      service.packAll(list.id);

      final summary = service.computeSummary();
      expect(summary.fullyPackedLists, 1);
    });

    // ── Search ────────────────────────────────────────────────

    test('searchItems finds items across lists', () {
      final l1 = service.createEmpty(name: 'L1');
      final l2 = service.createEmpty(name: 'L2');
      service.addItem(l1.id, name: 'Sunscreen SPF 50', category: PackingCategory.toiletries);
      service.addItem(l2.id, name: 'Laptop', category: PackingCategory.electronics);
      service.addItem(l2.id, name: 'Sunglasses', category: PackingCategory.accessories);

      final results = service.searchItems('sun');
      expect(results.length, 2);
    });

    test('searchItems returns empty for no match', () {
      service.createEmpty(name: 'L1');
      expect(service.searchItems('xyz'), isEmpty);
    });

    // ── Items by Category ─────────────────────────────────────

    test('itemsByCategory groups correctly', () {
      final list = service.createEmpty(name: 'Cat');
      service.addItem(list.id, name: 'Shirt', category: PackingCategory.clothing);
      service.addItem(list.id, name: 'Pants', category: PackingCategory.clothing);
      service.addItem(list.id, name: 'Laptop', category: PackingCategory.electronics);

      final grouped = service.itemsByCategory(list.id);
      expect(grouped[PackingCategory.clothing]!.length, 2);
      expect(grouped[PackingCategory.electronics]!.length, 1);
    });

    // ── Templates ─────────────────────────────────────────────

    test('availableTemplates returns all types with counts', () {
      final templates = service.availableTemplates();
      expect(templates.length, greaterThanOrEqualTo(7));
      for (final t in templates) {
        expect(t.value, greaterThan(0));
      }
    });

    // ── Export / Import ───────────────────────────────────────

    test('export and import round-trips', () {
      service.createFromTemplate(name: 'Export Me', templateType: PackingTemplateType.camping);
      final json = service.exportJson();

      final service2 = PackingListService();
      final count = service2.importJson(json);
      expect(count, 1);
      expect(service2.allLists.first.name, 'Export Me');
      expect(service2.allLists.first.items.length, greaterThan(0));
    });

    test('importJson returns 0 for invalid json', () {
      expect(service.importJson('not json'), 0);
    });

    // ── Edge Cases ────────────────────────────────────────────

    test('operations on unknown lists return null/false', () {
      expect(service.archiveList('nope'), isNull);
      expect(service.unarchiveList('nope'), isNull);
      expect(service.togglePacked('nope', 'item'), isNull);
      expect(service.packAll('nope'), isNull);
      expect(service.unpackAll('nope'), isNull);
      expect(service.readinessCheck('nope'), isNull);
      expect(service.itemsByCategory('nope'), isEmpty);
    });
  });
}
